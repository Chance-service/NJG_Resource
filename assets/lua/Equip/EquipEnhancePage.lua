
----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local EquipOpr_pb = require("EquipOpr_pb");
local HP_pb = require("HP_pb");
local UserInfo = require("PlayerInfo.UserInfo");
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local table = table;
--------------------------------------------------------------------------------

local thisPageName = "EquipEnhancePage";
local thisEquipId = 0;

local opcodes = {
    EQUIP_ENHANCE_S = HP_pb.EQUIP_ENHANCE_S
};

local option = {
    ccbiFile = "EquipmentEnhancePopUp.ccbi",
    handlerMap =
    {
        onHand1 = "onHand1",
        onHand2 = "onHand2",
        onHand3 = "onHand3",
        onHand4 = "onHand4",
        onEnhance = "onEnhance",
        onEnhanceTen = "onEnhanceTen",
        onHelp = "onHelp",
        onClose = "onClose"
    },
    opcode = opcodes
};

local EquipEnhancePageBase = { };

local NodeHelper = require("NodeHelper");
local PBHelper = require("PBHelper");
local EquipOprHelper = require("Equip.EquipOprHelper");
local UserItemManager = require("Item.UserItemManager");
local ItemManager = require("Item.ItemManager");
local NewbieGuideManager = require("NewbieGuideManager")

local lackInfo = { item = false, coin = false };

local itemCoinId = 1002;
local itemReoId = 1001;

local baseAttrInfo = {};
local mainAtrrs = {};
local curStr = 0;
local addStr = 0;
local itemCoin = 0;
local itemReo = 0;
local item1 = 0;
local item2 = 0;
local isShow = false;

--onRefreshContent
local EquipEnhanceItem = {
    ccbiFile = "EquipmentEnhanceContent.ccbi"
}

-----------------------------------------------
-- EquipEnhancePageBaseÒ³ÃæÖÐµÄÊÂ¼þ´¦Àí
----------------------------------------------
function EquipEnhancePageBase:onEnter(container)
    container.scrollview = container:getVarScrollView("mContent");    
    self:registerPacket(container);
    self:refreshPage(container);
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_ENHANCE)
end

function EquipEnhancePageBase:onExit(container)
    baseAttrInfo = {};
    mainAtrrs = {};
    curStr = 0;
    addStr = 0;
    itemCoin = 0;
    itemReo = 0;
    item1 = 0;
    item2 = 0;
    isShow = false;

    container.scrollview:removeAllCell();

    self:removePacket(container);
end
----------------------------------------------------------------

function EquipEnhanceItem:onRefreshContent(content)
    local container = content:getCCBFileNode();
    local contentId = self.id;

    NodeHelper:setNodesVisible(container, { ["mAtt_l"] = true, ["mAtt_l_num"] = true, ["mAtt_r"] = true, ["mAtt_r_num"] = true});
    local baseVal = math.ceil(mainAtrrs[contentId][2] * 10000 / (1 + curStr) / 10000)--math.floor(baseAttrInfo[mainAtrrs[contentId][3]].attrValMax *(1 + curStr));
    local curVal = math.floor(baseVal * (1 + curStr))
    local nextVal = math.floor(baseVal * (1 + addStr))--math.floor(baseAttrInfo[mainAtrrs[contentId][3]].attrValMax *(1 + addStr));
    local sprite2Img = { ["mPic_l"] = "attri_" .. mainAtrrs[contentId][3] .. ".png", ["mPic_r"] = "attri_" .. mainAtrrs[contentId][3].. ".png" };
    local scaleMap = { ["mPic_l"] = GameConfig.EquipmentAttrIconScale, ["mPic_r"] = GameConfig.EquipmentAttrIconScale };   

    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setStringForLabel(container, { ["mAtt_l"] = mainAtrrs[contentId][1], ["mAtt_r"] = mainAtrrs[contentId][1] , ["mAtt_l_num"] = curVal, ["mAtt_r_num"] = nextVal });
end

function EquipEnhancePageBase:refreshPage(container)
    self:showEquipInfo(container);
    self:showEnhanceInfo(container);
end

function EquipEnhancePageBase:showEquipInfo(container)
    local scrollview = container.scrollview;
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    if userEquip == nil or userEquip.id == nil then
        return;
    end
    UserInfo.sync();
    local equipId = userEquip.equipId;
    local level = EquipManager:getLevelById(equipId);
    local name = EquipManager:getNameById(equipId);
    local quality = EquipManager:getQualityById(equipId);
    local strength, displayStrength;
    local strength = userEquip.strength + 1;
    if tonumber(strength) > 100 then        
        displayStrength = common:getLanguageString("@NewLevelStr", math.floor(strength / 100), tonumber(strength) -100)
    else       
        displayStrength = common:getLanguageString("@LevelStr", strength)
    end

    local lb2Str = {
        mLv = "", --common:getLanguageString("@LevelStr", level),
        -- .. "\n" .. EquipManager:getPartNameById(equipId),
        mLvNum = "",-- userEquip.strength == 0 and "" or displayStrength,
        mLvNUm_1 = displayStrength,-- userEquip.strength == 0 and "" or displayStrength,
        mEquipmentName = "",
        -- common:getLanguageString("@LevelName", level, name),
        mEquipmentTex = "",
        -- UserEquipManager:getEquipInfoString(thisEquipId)
        mRate1 = "+" .. userEquip.strength,
        mRate2 = "+" .. userEquip.strength + 1,
        -- mAtt1			= UserEquipManager:getMainAttrStrAndNum(userEquip)
    };

    if(isShow == false)
    then
        local mLv_node = container:getVarNode("mLv");
        local y = mLv_node:getPositionY();
        mLv_node:setPositionY(y + 120); -- 移動位置   
        isShow = true;    
    end

    NodeHelper:setNodesVisible(container, { ["mRate1"] = false; });

    local quality = EquipManager:getQualityById(userEquip.equipId);
    --if quality > 5 then
        -- qilong 品质大于5的按5来处理
    --    quality = 5;
    --end
    local currVal = EquipManager:getAttrAddVAl(quality, userEquip.strength) or 0;
    local nextVal = EquipManager:getAttrAddVAl(quality, userEquip.strength + 1)-- or currVal;
    -- 沒有下一階強化 -> 跳出頁面
    if not nextVal or nextVal <= 0 then
        MessageBoxPage:Msg_Box(common:getLanguageString("@RefreshSucc"))
        PageManager.popPage(thisPageName)
        return
    end
    --local baseAttrInfo = EquipManager:getInitAttrInfo(userEquip.equipId)
    baseAttrInfo =  EquipManager:getInitAttrInfoNew(userEquip.equipId);
    curStr = currVal / 10000;
    addStr = nextVal / 10000;
    mainAtrrs = UserEquipManager:getMainAttrStrAndNum(userEquip);

    --for i = 1, 2 do
    --    NodeHelper:setNodesVisible(container, { ["mAtt" .. i] = false, ["mAttLast" .. i] = false, ["mArrow" .. i] = false, ["mAttNew" .. i] = false })
    --end

    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == quality) })
    end
    NodeHelper:setNodesVisible(container, { ["mNFT"] = EquipManager:getEquipCfgById(userEquip.equipId).isNFT == 1 })

    -- 寫一個scrollview自動生成item 
    container.scrollview:removeAllCell();
    local ccbiFile = EquipEnhanceItem.ccbiFile;
    local totalSize = #mainAtrrs;
    if totalSize == 0 then return end;
    local cell = nil;
    for i = 1, totalSize do
        cell = CCBFileCell:create();
        cell:setCCBFile(ccbiFile);

        local panel = common:new( { id = totalSize - i + 1 }, EquipEnhanceItem);
        cell:registerFunctionHandler(panel);
        scrollview:addCell(cell);
        local pos = ccp(0, cell:getContentSize().height *(i - 1));
        cell:setPosition(pos);
    end
    local size = CCSizeMake(cell:getContentSize().width, cell:getContentSize().height * totalSize);
    scrollview:setContentSize(size);
    scrollview:setContentOffset(ccp(0, scrollview:getViewSize().height - scrollview:getContentSize().height * scrollview:getScaleY()));   
    scrollview:forceRecaculateChildren();    

--    for i = 1, #mainAtrrs do
--        NodeHelper:setNodesVisible(container, { ["mAtt" .. i] = true, ["mAttLast" .. i] = true, ["mArrow" .. i] = false, ["mAttNew" .. i] = true })
--        local curVal = math.floor(baseAttrInfo[mainAtrrs[i][3]].attrValMax *(1 + curStr))
--        local nextVal = math.floor(baseAttrInfo[mainAtrrs[i][3]].attrValMax *(1 + addStr))
        -- common:numberRounding(string.format("%d", mainAtrrs[i][2] * addStr) + mainAtrrs[i][2]) --
--        NodeHelper:setStringForLabel(container, { ["mAtt" .. i] = mainAtrrs[i][1], ["mAtt1" .. i] = mainAtrrs[i][1] , ["mAttLast" .. i] = curVal, ["mAttNew" .. i] = nextVal });
--    end

    local sprite2Img = {
        mPic = EquipManager:getIconById(equipId);
    };
    local quality = EquipManager:getQualityById(userEquip.equipId);
    local itemImg2Qulity = {
        mHand = quality;
    };
    local scaleMap = { mPic = GameConfig.EquipmentIconScale };

    local nodesVisible = { };
    local gemVisible = false;
    local aniVisible = false--UserEquipManager:isEquipGodly(userEquip);
    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
    if table.maxn(gemInfo) > 0 then
        gemVisible = true;
        for i = 1, 4 do
            local gemId = gemInfo[i];
            nodesVisible["mGemBG" .. i] = gemId ~= nil;
            local gemSprite = "mGem0" .. i;
            nodesVisible[gemSprite] = false;
            if gemId ~= nil and gemId > 0 then
                local icon = ItemManager:getGemSmallIcon(gemId);
                if icon then
                    nodesVisible[gemSprite] = true;
                    sprite2Img[gemSprite] = icon;
					scaleMap[gemSprite] = 1
                end
            end
        end
    end
    nodesVisible["mAni"] = aniVisible;
    nodesVisible["mGemNode"] = gemVisible;
    NodeHelper:setNodesVisible(container, nodesVisible);

    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, itemImg2Qulity);  

    local tag = GameConfig.Tag.HtmlLable;
    local nameStr = common:getLanguageString("@LevelName", name);
    nameStr = common:fillHtmlStr("Quality_deep_" .. quality, nameStr);
    local nameNode = container:getVarNode("mEquipmentName");

    local _label = NodeHelper:addHtmlLable(nameNode, nameStr, tag, CCSizeMake(300, 60));
    --local stepLevel = EquipManager:getEquipStepById(equipId)
    --local starSprite = container:getVarSprite("mStar")
    --local posX = _label:getContentSize().width * _label:getScaleX() + _label:getPositionX()
    --local posY = _label:getPositionY() -(_label:getContentSize().height - starSprite:getContentSize().height) / 2
    --EquipManager:setStarPosition(starSprite, stepLevel == GameConfig.ShowStepStar, posX, posY)


    local needCoin = UserEquipManager:getEnhanceCoinCost(thisEquipId);
    local needReo = UserEquipManager:getEnhanceReoCost(thisEquipId);
    -- UserEquipManager:getEnhanceCoinCost(userEquip.equipId, needItem);
    local costItem1, itemId1 = UserEquipManager:getEnhanceItem1(thisEquipId);
    -- Ç¿»¯Ê¯Í·
    local costItem2, itemId2 = UserEquipManager:getEnhanceItem2(thisEquipId);
    -- Ç¿»¯¾«»ª
    local hasCount1 = UserItemManager:getCountByItemId(itemId1);
    local hasCount2 = UserItemManager:getCountByItemId(itemId2);

    -- NodeHelper:addItemIsEnoughHtmlLab(container, "mGold", needCoin, UserInfo.playerInfo.coin, tag+1)
    -- NodeHelper:addItemIsEnoughHtmlLab(container, "mGold", UserInfo.playerInfo.coin, needCoin, tag+1)

    --local strMap = { }

    --if costItem1 == 0 then
    --    NodeHelper:setNodesVisible(container, { mStoneNode = false })
    --else
    --    NodeHelper:setNodesVisible(container, { mStoneNode = true })

        -- NodeHelper:addItemIsEnoughHtmlLab(container, "mStone", costItem1, hasCount1, tag+2)
        -- NodeHelper:addItemIsEnoughHtmlLab(container, "mStone",  hasCount1, costItem1, tag+2)
    --end

    --if costItem2 == 0 then
    --    NodeHelper:setNodesVisible(container, { mCrystalNode = false })
    --else
    --    NodeHelper:setNodesVisible(container, { mCrystalNode = true })
        -- NodeHelper:addItemIsEnoughHtmlLab(container, "mCrystal", costItem2, hasCount2, tag+3)
        -- NodeHelper:addItemIsEnoughHtmlLab(container, "mCrystal", hasCount2, costItem2, tag+3)
    --end

--[[    strMap = {
        mGold = GameUtil:formatNumber(UserInfo.playerInfo.coin) .. "/" .. GameUtil:formatNumber(needCoin),
        --mStone = GameUtil:formatNumber(hasCount1) .. "/" .. GameUtil:formatNumber(costItem1),
        mCrystal = GameUtil:formatNumber(hasCount2) .. "/" .. GameUtil:formatNumber(costItem2)


    }]]

--    EquipEnhancePage_refreshNeedResource(container);

    NodeHelper:addNewItemIsEnoughHtmlLab(container,"mGold",UserInfo.playerInfo.coin,needCoin);
    NodeHelper:addNewItemIsEnoughHtmlLab(container,"mStone",UserInfo.playerInfo.gold,needReo);
    NodeHelper:setNodesVisible(container, { mCrystal = false, mCrystal2 = false })
    local htmlLabel = container:getVarLabelTTF("mCrystal"):getParent():getChildByTag(GameConfig.Tag.HtmlLable)
    if htmlLabel then
        container:getVarLabelTTF("mCrystal"):getParent():removeChild(htmlLabel, true)
    end
    if(costItem1 > 0) then
        NodeHelper:addNewItemIsEnoughHtmlLab(container,"mCrystal",hasCount1,costItem1)
    end
    local htmlLabel2 = container:getVarLabelTTF("mCrystal2"):getParent():getChildByTag(GameConfig.Tag.HtmlLable)
    if htmlLabel2 then
        container:getVarLabelTTF("mCrystal2"):getParent():removeChild(htmlLabel2, true)
    end
    if(costItem2 > 0) then
        NodeHelper:addNewItemIsEnoughHtmlLab(container,"mCrystal2",hasCount2,costItem2)
    end
    --NodeHelper:addNewItemIsEnoughHtmlLab(container,"mCrystal",hasCount1,costItem1);
    --NodeHelper:addNewItemIsEnoughHtmlLab(container,"mCrystal2",hasCount2,costItem2);

    local addNum = 0;
    if(costItem2 > 0)
    then
        addNum = 2;
    elseif (costItem1 > 0)
    then
        addNum = 1;
    end

    local showDataNumber = 2 + addNum; --需要顯示的強化道具數量
    if(showDataNumber == 2)
    then
        container:getVarMenuItem("mHand3"):setEnabled(false);       
        container:getVarMenuItem("mHand4"):setEnabled(false);        
    elseif(showDataNumber == 3)
    then
        container:getVarMenuItem("mHand4"):setEnabled(false); 
    end

    EquipEnhancePage_setNeedResource(container, showDataNumber, itemCoinId, itemReoId, itemId1, itemId2); -- 最多四個item

    --NodeHelper:setStringForLabel(container, strMap)
    --    local  colorMap =
    --    {
    --        mGold = GameConfig.ColorMap.COLOR_RED_NORMALFONT,
    --        mCrystal = GameConfig.ColorMap.COLOR_RED_NORMALFONT,
    --        mStone = GameConfig.ColorMap.COLOR_RED_NORMALFONT,
    --    }
    --    NodeHelper:setColorForLabel(container, colorMap);

    NodeHelper:addEquipAni(container, "mAni", aniVisible, thisEquipId);
end

-- 重製需要道具item
function EquipEnhancePage_refreshNeedResource(container)
    -- 最多只有4個所以寫死四個欄位 mPic, mHand, mAni
    for i = 1, 4 do
                
    end
end
-- 設定需要道具item, 左至右顯示 (錢幣, 鑽石, 道具1, 道具2)
function EquipEnhancePage_setNeedResource(container, num, content1, content2, content3, content4)
    if (tonumber(num) == 0)
    then
        return
    end
       
    for i = 1, 4--[[num]] do
        local resMainType = 0;
        local itemId = 0;     
        if (i == 1)
        then
            itemId = content1;
            itemCoin = content1;
            resMainType = Const_pb.PLAYER_ATTR;
        elseif (i == 2)
        then
            itemId = content2;
            itemReo = content2;
            resMainType = Const_pb.PLAYER_ATTR;
        elseif (i == 3)
        then
            itemId = content3;
            item1 = content3;
            resMainType = Const_pb.TOOL;
        elseif (i == 4)
        then
            itemId = content4;
            item2 = content4;
            resMainType = Const_pb.TOOL;
        end
        
        local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(resMainType, itemId, 1); --道具資訊
        if i <= num then
            NodeHelper:setSpriteImage(container, { ["mPic" .. i] = resInfo.icon }, { ["mPic" .. i] = resInfo.iconScale })
            NodeHelper:setQualityFrames(container, { ["mHand" .. i] = resInfo.quality })
            NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. i] = resInfo.quality })
        else
            NodeHelper:setSpriteImage(container, { ["mPic" .. i] = "UI/Mask/Image_Empty.png" }, { ["mPic" .. i] = resInfo.iconScale })
            NodeHelper:setQualityFrames(container, { ["mHand" .. i] = 0 })
            NodeHelper:setSpriteImage(container, { ["mFrameShade" .. i] = "common_ht_propK_diban.png" })
        end
    end
end

function EquipEnhancePage_showRequirementInfo(container, infoIndex, itemId, resMainType)    
    local itemCfg = {
			type 		= resMainType * 10000, -- getResInfoByTypeAndId 的 type, 判斷上是用type * 10000去判斷的
			itemId 		= itemId,
			count 		= tonumber(1),
		}      
    GameUtil:showTip(container:getVarNode("mPic" .. infoIndex), itemCfg);
end

function EquipEnhancePageBase:showEnhanceInfo(container)

end

----------------click event------------------------

-- 顯示金幣說明
function EquipEnhancePageBase:onHand1(container)
    if (tonumber(itemCoin) > 0)
    then
        EquipEnhancePage_showRequirementInfo(container, 1, itemCoin, Const_pb.PLAYER_ATTR);
    end   
end
-- 顯示鑽石說明
function EquipEnhancePageBase:onHand2(container)
    if (tonumber(itemReo) > 0)
    then
        EquipEnhancePage_showRequirementInfo(container, 2, itemReo, Const_pb.PLAYER_ATTR);
    end  
end
-- 顯示道具1說明
function EquipEnhancePageBase:onHand3(container)
    if (tonumber(item1) > 0)
    then
        EquipEnhancePage_showRequirementInfo(container, 3, item1, Const_pb.TOOL);
    end  
end
-- 顯示道具2說明
function EquipEnhancePageBase:onHand4(container)
    if (tonumber(item2) > 0)
    then
        EquipEnhancePage_showRequirementInfo(container, 4, item2, Const_pb.TOOL);
    end  
end

function EquipEnhancePageBase:onEnhance(container)
    EquipOprHelper:enhanceEquip(thisEquipId, Const_pb.EQUIP_ONCE);
end

function EquipEnhancePageBase:onEnhanceTen(container)
    EquipOprHelper:enhanceEquip(thisEquipId, Const_pb.EQUIP_TEN_TIMES);
end

function EquipEnhancePageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ENHANCE);
end	

function EquipEnhancePageBase:onClose(container)
    PageManager.popPage(thisPageName);
end

-- »Ø°ü´¦Àí
function EquipEnhancePageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();

    if opcode == opcodes.EQUIP_ENHANCE_S then
        self:refreshPage(container);
        return
    end
end

function EquipEnhancePageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode);
        end
    end
end

function EquipEnhancePageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
EquipEnhancePage = CommonPage.newSub(EquipEnhancePageBase, thisPageName, option);

function EquipEnhancePage_setEquipId(equipId)
    thisEquipId = equipId;
end
