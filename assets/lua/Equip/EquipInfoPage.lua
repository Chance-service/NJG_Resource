----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local EquipOpr_pb = require("EquipOpr_pb");
local HP_pb = require("HP_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local EquipManager = require("EquipManager");
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local table = table;
--------------------------------------------------------------------------------
local enhancePage = "EquipEnhancePage";
-- registerScriptPage(enhancePage);
local baptizePage = "EquipBaptizePage";
-- registerScriptPage(baptizePage);
local embedPage = "EquipEmbedPage";
-- registerScriptPage(embedPage);
local swallowPage = "EquipSwallowPage";
-- registerScriptPage(swallowPage);
local extendPage = "EquipExtendPage";
-- registerScriptPage(extendPage);

local thisPageName = "EquipInfoPage";
local thisEquipId = 0;
local thisRoleId = 0;
local isEquipDressed = false;
local equipPart = 0;
local isViewingOther = false;
local isViewMercenary = false;
local isViewLeader = false
local isExchangePoint = false

local title1ID = 0;
local title2ID = 0;
local equipDataInfo = {};
local equipDataAttrIdInfo = {};

--onRefreshContent
local EquipmentInfoContent = {
    ccbiFile = "EquipmentInfoContent.ccbi"
}

local opcodes = {
    EQUIP_ENHANCE_C = HP_pb.EQUIP_ENHANCE_C,
    EQUIP_ENHANCE_S = HP_pb.EQUIP_ENHANCE_S,
    EQUIP_BAPTIZE_C = HP_pb.EQUIP_BAPTIZE_C,
    EQUIP_BAPTIZE_S = HP_pb.EQUIP_BAPTIZE_S,
    EQUIP_SWALLOW_C = HP_pb.EQUIP_SWALLOW_C,
    EQUIP_SWALLOW_S = HP_pb.EQUIP_SWALLOW_S,
    EQUIP_EXTEND_C = HP_pb.EQUIP_EXTEND_C,
    EQUIP_EXTEND_S = HP_pb.EQUIP_EXTEND_S,
    EQUIP_PUNCH_C = HP_pb.EQUIP_PUNCH_C,
    EQUIP_PUNCH_S = HP_pb.EQUIP_PUNCH_S,
    EQUIP_DRESS_S = HP_pb.EQUIP_DRESS_S
};

local EquipPartNames = {
    ["Helmet"] = Const_pb.HELMET,
    ["Neck"] = Const_pb.NECKLACE,
    ["Finger"] = Const_pb.RING,
    ["Wrist"] = Const_pb.GLOVE,
    ["Waist"] = Const_pb.BELT,
    ["Feet"] = Const_pb.SHOES,
    ["Chest"] = Const_pb.CUIRASS,
    ["Legs"] = Const_pb.LEGGUARD,
    ["MainHand"] = Const_pb.WEAPON1,
    ["OffHand"] = Const_pb.WEAPON2
};

local option = {
    ccbiFile = "EquipmentInfoPopUp.ccbi",
    handlerMap =
    {
        --onEnhance = "onEnhance",
        onRefinement = "onBaptize",
        -- 洗炼
        onTakeOff = "onTakeOff",
        onChange = "onChange",
        --onCameoIncrustation = "onEmbed",
        --onGobbleUp = "onSwallow",
        --onInherit = "onExtend",
        --onGodEquipmentFusion = "onCompound",
        onClose = "onClose",
        onSuitDecomposition = "onSuitDecomposition",
        --onEvolution = "onEvoution",
        onChangeSuit = "onChangeSuit"
    },
    opcode = opcodes
};

local EquipInfoPageBase = { };

local NodeHelper = require("NodeHelper");
local EquipOprHelper = require("Equip.EquipOprHelper");
local PBHelper = require("PBHelper");
local ItemManager = require("Item.ItemManager");
local GuideManager = require("Guide.GuideManager")

-- for suit fragment change
local RelatedItemId = 0
local RelatedItemPrice = 0
local RelatedShopId = 0
--
-----------------------------------------------
-- EquipInfoPageBase页面中的事件处理
----------------------------------------------
function EquipInfoPageBase:onEnter(container)
    if not isViewingOther then
        self:registerPacket(container);
        container:registerMessage(MSG_MAINFRAME_POPPAGE);
        isEquipDressed = UserEquipManager:isEquipDressed(thisEquipId);
    end
    container.scrollview = container:getVarScrollView("mContent");
    self:refreshPage(container);
    GuideManager.PageContainerRef["EquipInfoPage"] = container
    local relativeNode = container:getVarNode("mContentBg")
    GameUtil:clickOtherClosePage(relativeNode, function()
        self:onClose(container)
    end , container)

end

function EquipInfoPageBase:onExit(container)
    if not isViewingOther then
        self:removePacket(container);
        container:removeMessage(MSG_MAINFRAME_POPPAGE);
    end
    title1ID = 0;
    title2ID = 0;
    equipDataInfo = {};
    equipDataAttrIdInfo = {};
    container.scrollview:removeAllCell();
    debugPage[thisPageName] = true;
    onUnload(thisPageName, container);
end
----------------------------------------------------------------

function EquipmentInfoContent:onRefreshContent(content)
    local container = content:getCCBFileNode();
    local contentId = self.id;
   
    if(contentId == title1ID)
    then
        NodeHelper:setNodesVisible(container, { ["mTitleNode"] = true; });
        local str = common:getLanguageString("@EquipBasicProperties"); -- basic title
        NodeHelper:setStringForLabel(container, { ["mTitle"] = str; });
    elseif(contentId == title2ID)
    then
        NodeHelper:setNodesVisible(container, { ["mTitleNode"] = true; });
        local str = common:getLanguageString("@EquipAdditionalProperties"); -- additional title
        NodeHelper:setStringForLabel(container, { ["mTitle"] = str; });
    else
        NodeHelper:setNodesVisible(container, { ["mTitleNode"] = false; });
    end
  
    -- ex:
    -- [1] = {1_2, 6_6}
    -- [2] = {7_7, x_x} // x_x為空格
    -- [3] = {3_6, 5_8}
    -- [4] = {7_10,x_x}
    if(equipDataInfo[contentId] ~= nil)then   
        --local index = 1;
        local data=equipDataInfo[contentId];
        local dataList = {}
        local _name, _value = unpack(common:split(data, "_"));
		table.insert(dataList, {           		
			name	= _name,
			value 	= _value
		});
        for _, data in ipairs(dataList) do
            resetContentVisible(container);
            local name = data.name;
            local value = data.value;
            --print("dataList-> " .. "i = " .. contentId .. ", name : " .. name .. " , " .. "value : " .. value);
            if(name == "x")
            then
                NodeHelper:setNodesVisible(container, { ["mNode"] = false; });
            else
                --TODO: mPic
                NodeHelper:setStringForLabel(container, { ["mAttriName"] = name, ["mTxt"] = value; });
            end
        
            --index = index + 1;              
        end  
       
        data=equipDataAttrIdInfo[contentId]
        
       --"mPic" .. index
       local sprite2Img = { ["mPic"] = "attri_" .. data .. ".png" };
       local scaleMap = { ["mPic"] = GameConfig.EquipmentAttrIconScale };   

       NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);                             
    end
   
end

function resetContentVisible(container)
    NodeHelper:setNodesVisible(container, { ["mNode"] = false; });
end

function EquipInfoPageBase:refreshPage(container)
    self:showEquipInfo(container); -- 顯示裝備數值
    self:showButtons(container); -- 顯示按鈕狀態
end

-- 显示装备详情
function EquipInfoPageBase:showEquipInfo(container)
    local userEquip = nil;

    if not isViewingOther then
        userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    else
        -- 查看别人阵容
        if isViewMercenary then
            local ViewMercenaryInfo = require("Mercenary.ViewMercenaryInfo")
            -- userEquip = ViewMercenaryInfo:getEquipById(thisEquipId);
            userEquip = ViewPlayerInfo:getEquipById(thisEquipId);
        else
            userEquip = ViewPlayerInfo:getEquipById(thisEquipId);
        end

    end

    if userEquip == nil or userEquip.id == nil then
        return;
    end
    local equipId = userEquip.equipId;
    local level = EquipManager:getLevelById(equipId);
    local name = EquipManager:getNameById(equipId);
    local quality = EquipManager:getQualityById(equipId);
    local star = EquipManager:getStarById(equipId)
    local strength = userEquip.strength + 1;
    local displayLevel, displayStrength;   
    if tonumber(level) > 100 then
        displayLevel = common:getLanguageString("@NewLevelStr", math.floor(level / 100), tonumber(level) -100)       
    else
        displayLevel = common:getLanguageString("@LevelStr", level)      
    end

    if tonumber(strength) > 100 then       
        displayStrength = common:getLanguageString("@NewLevelStr", math.floor(strength / 100), tonumber(strength) -100)
    else        
        displayStrength = common:getLanguageString("@LevelStr", strength)
    end

    local lb2Str = {
        -- mLv = displayLevel .. "\n" .. EquipManager:getPartNameById(equipId),
        mLv = "", -- displayLevel, 目前不需要顯示
        -- 等级、部位
        mLvNum = "",-- userEquip.strength == 0 and "" or displayStrength,
        mLvNUm_1 = displayStrength,-- userEquip.strength == 0 and "" or displayStrength,
        -- 强化等级
        mEquipmentName = "",
        -- 等级名字，用HtmlLabel
        mEquipmentInfoTex = "",
        mEquipmentInfoTex1 = ""-- 装备信息，用HtmlLabel
    };

    local sprite2Img = {
        mPic = EquipManager:getIconById(equipId)
    };
    local itemImg2Qulity = {
        mHand = quality
    };
    local scaleMap = { mPic = GameConfig.EquipmentIconScale };
    --- 设置 等级 部位颜色
    -- NodeHelper:setColorForLabel(container,{mLv = "53 17 0"})

    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == star) });
        NodeHelper:setNodeScale(container,"mStar" .. i,1.8,1.8)
    end
     NodeHelper:setNodesVisible(container, { mNFT = false,mShader =false,mLvNUm_1=false ,mLv=false})

    -- 装备图标上的宝石孔显示（最多４个）
    local nodesVisible = { };
    local gemVisible = false;
    local aniVisible = UserEquipManager:isEquipGodly(userEquip);
    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
    for i = 1, 4 do
        nodesVisible["mGemBG" .. i] = gemId ~= nil;
        local gemSprite = "mGem0" .. i;
        nodesVisible[gemSprite] = false;
        scaleMap[gemSprite] = 1
    end

    if table.maxn(gemInfo) > 0 then
        -- 是否有孔
        gemVisible = true;
        for i = 1, 4 do
            local gemId = gemInfo[i];
            nodesVisible["mGemBG" .. i] = gemId ~= nil;
            local gemSprite = "mGem0" .. i;
            nodesVisible[gemSprite] = false;
            if gemId ~= nil and gemId > 0 then
                -- 是否有宝石
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
    --nodesVisible["mNewEquipPoint"] = isExchangePoint;
    NodeHelper:setNodesVisible(container, nodesVisible);

    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, itemImg2Qulity);

    -- 装备名字显示，HtmlLabel
    local tag = GameConfig.Tag.HtmlLable;
    local nameStr = common:getLanguageString("@LevelName", name);
    nameStr = common:fillHtmlStr("Quality_" .. quality, nameStr);
    local nameNode = container:getVarNode("mEquipmentName");
    if IsThaiLanguage() then
        nameNode:setScale(0.8)
    end
    local _label = NodeHelper:addHtmlLable(nameNode, nameStr, tag, CCSizeMake(380, 30));
    local stepLevel = EquipManager:getEquipStepById(equipId)
    local starSprite = container:getVarSprite("mStar")
    starSprite:setVisible(false)
    local posX = _label:getContentSize().width * _label:getScaleX() + _label:getPositionX()
    local posY = _label:getPositionY() -(_label:getContentSize().height - starSprite:getContentSize().height) / 2
    EquipManager:setStarPosition(starSprite, false, posX, posY) -- EquipManager:setStarPosition(starSprite, stepLevel == GameConfig.ShowStepStar, posX, posY)

    -- 装备属性信息显示（装备限制、评分、主属性、副属性、神器属性、神器强化效果、宝石加成），HtmlLabel
    local equipOwnerRoleInfo = nil
    if isViewingOther then
        if isViewMercenary then
            local ViewMercenaryInfo = require("Mercenary.ViewMercenaryInfo")
            require("ViewPlayerMercenaryPage")
            equipOwnerRoleInfo = ViewPlayerMercenaryPage_curMercenaryInfo()
            -- ViewMercenaryInfo:getRoleInfo()
        else
            equipOwnerRoleInfo = ViewPlayerInfo:getRoleInfo()
        end
    elseif isViewMercenary then
        require("EquipLeadPage")
        equipOwnerRoleInfo = EquipLeadPage_getCurRoleInfo()
        -- MercenaryPage_getCurSelectMerRoleInfo()
    elseif isViewLeader then
        equipOwnerRoleInfo = UserInfo.roleInfo
    end
    local selectlist= false
    local basicInfoNode = container:getVarNode("mEquipmentInfoTex1")
    local str = UserEquipManager:getEquipDescBasicInfo(userEquip, true, isViewingOther, equipOwnerRoleInfo,selectlist)
    NodeHelper:addHtmlLable(basicInfoNode, str, tag + 1, CCSizeMake(380, 30))

    -- 修改为scrollview
    -- 要換另一種方式寫, 原本是一個大框(數值用html加入), 現在要改成條列式的數值
    -- str => [1] = 主屬性title
    --        [2] = 名稱_數值,名稱_數值...
    --        [3] = 副屬姓title
    --        [4] = 名稱_數值,名稱_數值...
    -- size => 總共要創多少個content
    -- additionalIndex => 第幾個content要顯示副屬性標題(0為不需要)
    -- str_attrId => [1] = 主屬性圖片代號
    --               [2] = 副屬性圖片代號
    local str, size, additionalIndex, str_attrId, OtherAttr = UserEquipManager:getDesciptionWithEquipInfo1_deep(userEquip, false, false, equipOwnerRoleInfo, 1)
    str = common:split(str[1], ",")
    str_attrId = common:split(str_attrId[1], ",")
    for i = 1, 4 do
        if str[i] then
            local BasicAttr = GameUtil:splitData(str[i])
            NodeHelper:setStringForLabel(container, { ["mAttrName".. i] = BasicAttr[1].name, ["mAttrNum" .. i] = BasicAttr[1].value })
            NodeHelper:setSpriteImage(container, { ["mAttrIcon" .. i] = "ability_" .. tonumber(str_attrId[i]) .. ".png" })
        end
        NodeHelper:setNodesVisible(container, { ["mAttrName" .. i] = (str[i] ~= nil),
                                                ["mAttrNum" .. i] = (str[i] ~= nil),
                                                ["mAttrIcon" .. i] = (str[i] ~= nil) })
    end
    for i = 1, 3 do
        if OtherAttr[i] then
            local htmlLabel = NodeHelper:setCCHTMLLabel(container, "mOtherAttrName" .. i, CCSize(300, 20), OtherAttr[i], false)
        end
        NodeHelper:setStringForLabel(container, { ["mOtherAttrName" .. i] = "" })
        NodeHelper:setNodesVisible(container, { ["mOtherAttrName" .. i] = (OtherAttr[i] ~= nil),
                                                ["mOtherAttrNum" .. i] = false,
                                                ["mOtherAttrIcon" .. i] = false })
    end

    --equipDataInfo = str;
  --if(#str == 2) -- 沒有副標題
  --then
  --    additionalIndex = 0;
  --end
  --equipDataInfo = EquipInfoPage_complexData(str[2], str[4]);    
  --equipDataAttrIdInfo = EquipInfoPage_complexData(str_attrId[1], str_attrId[2]);
  --
  ---- 寫一個scrollview自動生成item(cocos2d-x坐标是以左下角为原点)
  --local scrollview = container.scrollview; 
  --scrollview:removeAllCell();
  --local ccbiFile = EquipmentInfoContent.ccbiFile;
  --local totalSize = #equipDataInfo;
  --if totalSize == 0 then return end;
  --local maskOffsetY = 0;
  --local index = totalSize - additionalIndex + 2; --因為scrollview的創建是由下往上建置
  --title1ID = 1; --哪一個id顯示主標題
  --title2ID = additionalIndex; --哪一個id顯示副標題
  --if(index > totalSize)
  --then
  --    if(additionalIndex == 0)
  --    then
  --        index = 0;
  --    else
  --        index = totalSize;
  --    end        
  --end
  --
  --local offset_i = 0;   
  --local cell = nil;
  --for i = 1, totalSize do
  --    cell = CCBFileCell:create();
  --    cell:setCCBFile(ccbiFile);
  --
  --    local panel = common:new( { id = totalSize - i + 1 }, EquipmentInfoContent);
  --    cell:registerFunctionHandler(panel);
  --    scrollview:addCell(cell);
  --    if(i == 1)
  --    then
  --        offsetY = 0;          
  --    elseif(i == index)
  --    then
  --        offsetY = cell:getContentSize().height;            
  --    else
  --        offsetY = cell:getContentSize().height / 2.5;
  --        offset_i = offset_i + 1;
  --    end       
  --    local pos = ccp(0, maskOffsetY + offsetY);
  --    --cell:setPosition(pos);
  --    maskOffsetY = maskOffsetY + offsetY; 
  --end
  --   
  --local size = CCSizeMake(cell:getContentSize().width, cell:getContentSize().height * totalSize - (cell:getContentSize().height / 1.7) * offset_i);
  --scrollview:setContentSize(size);
  --scrollview:setContentOffset(ccp(0, scrollview:getViewSize().height - scrollview:getContentSize().height * scrollview:getScaleY()));
  --scrollview:forceRecaculateChildren();  

    --[[
    local mScrollView = container:getVarScrollView("mContent");
    local str = UserEquipManager:getDesciptionWithEquipInfo1(userEquip, true, isViewingOther, equipOwnerRoleInfo);
    local lbNode = container:getVarNode("mEquipmentInfoTex");
    local widthKey = isViewingOther and "EquipInfoFull" or "EquipInfo";
    local width = GameConfig.LineWidth[widthKey];
    local size = CCSizeMake(mScrollView:getViewSize().width, 200);
    mScrollView:getContainer():removeAllChildren();
    -- mScrollView:setViewSize(CCSizeMake(width, mScrollView:getViewSize().height));
    local htmlNode = NodeHelper:addHtmlLable(lbNode, str, tag + 2, size, mScrollView);
    
    local height = 0;
    ]]
    -- 宝石列表（有孔才显示）
    --[[
    local listNode = self:showGemList(userEquip, htmlNode:getParent());
    if listNode then
        listNode:setPosition(ccp(-5.0, 0));
        height = height + listNode:getContentSize().height;
    end
    htmlNode:setPosition(ccp(0, height));
    ]]
    -- 属性信息及宝石列表在同一个ScrollView中，设置大小及偏移
    --[[local size = htmlNode:getContentSize();
    height = height + size.height;
    mScrollView:setContentSize(CCSizeMake(size.width, height));
    mScrollView:setContentOffset(ccp(0, mScrollView:getViewSize().height - height * mScrollView:getScaleY()));
    ]]
    -- 神器特效显示（如果是神器，添加特效）
   -- NodeHelper:addEquipAni(container, "mAni", aniVisible, nil, userEquip);

    --職業限制icon顯示
    local profs = EquipManager:getAttrById(equipId, "profession") or {}
    for i = 1, 5 do
        if profs[i] then
            NodeHelper:setNodesVisible(container, { ["mClass" .. i] = true })
            NodeHelper:setSpriteImage(container, { ["mClass" .. i] = GameConfig.MercenaryClassImg[tonumber(profs[i])] })
        else
            NodeHelper:setNodesVisible(container, { ["mClass" .. i] = false })
        end
    end
    --可販售字串顯示
    NodeHelper:setNodesVisible(container, { ["mSellableTxt"] = EquipManager:getEquipCfgById(equipId).isNFT == 1 })

    equipPart = EquipManager:getPartById(equipId);

    --顯示裝備稀有度
    local rank = 1--UserEquipManager:calEquipRank(userEquip)
    for i = 1, 4 do
        NodeHelper:setNodesVisible(container, { ["mRairty" .. i] = i == rank })
    end

    -- if is shop can buy this suit
    NodeHelper:setMenuItemEnabled(container, "mChangeBtn", false)
end

function EquipInfoPageBase:showGemList(userEquip, parentNode)
    local tag = GameConfig.Tag.GemList;
    if parentNode:getChildByTag(tag) then
        parentNode:removeChildByTag(tag, true);
    end
    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
    if table.maxn(gemInfo) > 0 then
        --- 添加图片间隔
        -- local imgStr = UserEquipManager:getEquipSpaceImg()
        -- table.insert(strTb, imgStr);

        local listNode = ScriptContentBase:create("GemEquipmentItem.ccbi", tag);
        local nodesVisible = { };
        local sprite2Img = { };
        for i = 1, 4 do
            nodesVisible["mGemNode" .. i] = false;
        end
        local itemImg2Quality = { }
        local j = 1;
        for _, gemId in pairs(gemInfo) do
            nodesVisible["mGemNode" .. j] = true;
            sprite2Img["mGemPic" .. j] = GameConfig.Image.Empty;
            if gemId > 0 then
                local icon = ItemManager:getIconById(gemId);
                if icon ~= "" then
                    sprite2Img["mGemPic" .. j] = icon;
                end

            end
            itemImg2Quality["mGemFrame" .. j] = tonumber(ItemManager:getQualityById(gemId)) or GameConfig.Default.Quality;
            local gemLevel = tonumber(string.sub(gemId, -2))
            if gemLevel >= GameConfig.StoneAndEquipSpeLevel then
                NodeHelper:addStoneAni(listNode, "mGem" .. j .. "AniNode", true)
            end

            j = j + 1;

        end
        NodeHelper:setNodesVisible(listNode, nodesVisible);
        NodeHelper:setQualityFrames(listNode, itemImg2Quality);
        NodeHelper:setSpriteImage(listNode, sprite2Img);
        listNode:setAnchorPoint(ccp(0, 0));
        parentNode:addChild(listNode, tag);
        listNode:release();
        return listNode;
    end
    return nil;
end

function EquipInfoPageBase:showButtonContainer(container, isVisible)
    local node2Visible = {
        mLeftBtnNode = isVisible,
        mRightBtnNode = isVisible
    };
    NodeHelper:setNodesVisible(container, node2Visible);
end

function EquipInfoPageBase:showButtons(container)
    self:showButtonContainer(container, not isViewingOther);
    if isViewingOther then return; end

    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    --if GameConfig.TableIsImpty(userEquip) then
        local btnVisible = {
            mEnhanceNode = false, --強化
            mRefinementNode = false,
            mGodEquipmentInheritNode = false,
            mSuitDecompositionNode = false, --分解
            mEvolutionNode = false,
            mCameoIncrustationNode = false,
            mGodEquipmentGobbleUpNode = false,
            mGodEquipmentFusionNode = false,
        };
        NodeHelper:setNodesVisible(container, btnVisible);
    --    return;
    --end
    local quality = EquipManager:getQualityById(userEquip.equipId)
    local nextVal = EquipManager:getAttrAddVAl(quality, userEquip.strength + 1)
    local isEnable = nextVal and nextVal > 0
    NodeHelper:setMenuItemEnabled(container, "mEnhanceBtn", isEnable)
    if isEnable then
        NodeHelper:setBMFontFile(container, { mEnhanceTxt = "Lang/Font-HT-Button-Golden.fnt" })
    else
        NodeHelper:setBMFontFile(container, { mEnhanceTxt = "Lang/Font-HT-Button-White.fnt" })
    end

    local isGodly = UserEquipManager:isGodly(thisEquipId);
    local isInherit = UserEquipManager:getIsInherit(userEquip)
    local canBeEmbed = EquipManager:canBeEmbed(userEquip.equipId);
    local canBeBaptized = EquipManager:canBeBaptized(userEquip.equipId);
    local canCompound = UserEquipManager:canCompound(thisEquipId);
    local suitId = EquipManager:getSuitIdById(userEquip.equipId)
    local evolutionStuff = 0
    if EquipManager:getEquipCfgById(userEquip.equipId).upgradeId ~= 0 then
        evolutionStuff = EquipManager:getEquipCfgById(userEquip.equipId).upgradeId
    elseif EquipManager:getEquipCfgById(userEquip.equipId).evolutionId ~= 0 then
        evolutionStuff = EquipManager:getEquipCfgById(userEquip.equipId).evolutionId
    end
    --- 套装不能卖出
    local isUnloadNode = isEquipDressed
    if not isUnloadNode then
        isUnloadNode = suitId <= 0
    end

    local btnVisible = {
        mChangeNode = isEquipDressed,
        mCameoIncrustationNode = false,--canBeEmbed,
        mGodEquipmentGobbleUpNode = false,--isGodly,
        mGodEquipmentInheritNode = false,--isInherit,
        -- isGodly,
        mRefinementNode = not isEquipDressed,--canBeBaptized,
        mGodEquipmentFusionNode = false,--canCompound,
        mEvolutionNode = false,--evolutionStuff ~= 0,
        mSuitDecompositionNode = not isEquipDressed,--true,--suitId > 0, 
        mUnloadNode = isUnloadNode,
    };
    local lb2Str = {
        mUnloadTex = common:getLanguageString(isEquipDressed and "@TakeOff" or "@SellOut")
    };
    NodeHelper:setNodesVisible(container, btnVisible);
    NodeHelper:setStringForLabel(container, lb2Str);

    --- 不穿戴的时候，卖出按钮居中
    if not isEquipDressed then
        local node = container:getVarNode("mLeftBtnNode")
        local x = node:getPositionX()
        local unloadNode = container:getVarNode("mUnloadNode")
        unloadNode:setPositionX(x)
        unloadNode:setVisible(false)
    end
end
	
-- 規則適用於一排一個的排版, 因為scrollview的callback是由後往前, 不太符合人體工學, 故目前作法是先把資料接成畫面顯示的樣子
function EquipInfoPage_complexData(data1, data2)    
    local data = {};    

    --變成一組array
    if(data1 ~= nil)then    
        for _, dataTmp1 in ipairs(common:split(data1, ",")) do		
		    table.insert(data, dataTmp1);         
	    end    
    end
    if(data2 ~= nil)then
        for _, dataTmp2 in ipairs(common:split(data2, ",")) do				
            table.insert(data, dataTmp2);
	    end    
    end
	return data;
end

----------------click event------------------------
function EquipInfoPageBase:onEnhance(container)
    --    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    --    if userEquip.strength >= ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.equipStrengthLimit].level then
    --        MessageBoxPage:Msg_Box_Lan("@EquipStrengthLevelLimit");
    --        return
    --    end

    RegisterLuaPage(enhancePage);
    EquipEnhancePage_setEquipId(thisEquipId);
    -- self:onClose();
    PageManager.pushPage(enhancePage);
end

-- 洗炼
function EquipInfoPageBase:onBaptize(container)

    MainFrame_onLeaderPageBtn()--toHeroEquip
    --RegisterLuaPage(baptizePage);
    --EquipBaptizePage_setEquipId(thisEquipId);
    ---- self:onClose();
    --PageManager.pushPage(baptizePage);
end	

-- 卸下/出售
function EquipInfoPageBase:onTakeOff(container)
    if isEquipDressed then
        local dressType = GameConfig.DressEquipType.Off;
        EquipOprHelper:dressEquip(thisEquipId, thisRoleId, dressType);
        -- self:onClose();
   -- else
   --     if UserEquipManager:isGodly(thisEquipId) then
   --         MessageBoxPage:Msg_Box_Lan("@CanNotSellGodly");
   --     elseif UserEquipManager:hasGem(thisEquipId) then
   --         MessageBoxPage:Msg_Box_Lan("@SelectedEquipHasGem");
   --     else
   --         EquipOprHelper:sellEquip(thisEquipId);
   --         self:onClose();
   --     end
    end
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    -- 佣兵脱掉装备发送协议供图鉴头像排序
end

function EquipInfoPageBase_onChange()
    if isEquipDressed then
        EquipSelectPage_setPart(equipPart, thisRoleId);
        PageManager.pushPage("EquipSelectPage");
    end
end
-- 更换
function EquipInfoPageBase:onChange(container)
    if isEquipDressed then
        EquipSelectPage_setPart(equipPart, thisRoleId);
        PageManager.pushPage("EquipSelectPage");
    end
    -- self:onClose();
end

-- 镶嵌
function EquipInfoPageBase:onEmbed(container)
    RegisterLuaPage(embedPage);
    EquipEmbedPage_setEquipId(thisEquipId);
    -- self:onClose();
    PageManager.pushPage(embedPage);
end

-- 吞噬
function EquipInfoPageBase:onSwallow(container)
    if not(UserEquipManager:canSwallow(thisEquipId)) then
        MessageBoxPage:Msg_Box_Lan("@EquipmentStarLevelHighest");
        return;
    end
    RegisterLuaPage(swallowPage);
    EquipSwallowPage_setEquipId(thisEquipId);
    -- self:onClose();
    PageManager.pushPage(swallowPage);
end

-- 传承
function EquipInfoPageBase:onExtend(container)
    RegisterLuaPage(extendPage);
    EquipExtendPage_setEquipId(thisEquipId);
    -- self:onClose();
    PageManager.pushPage(extendPage);
end

-- 神器融合
function EquipInfoPageBase_onCompound()
    PageManager.pushPage("EquipCompoundPage");
    UserInfo.sync()
    local compoundPage = "EquipCompoundPage";
    RegisterLuaPage(compoundPage);
    EquipCompoundPage_setEquipId(thisEquipId);
    PageManager.pushPage(compoundPage);
    --[[	UserInfo.sync()
	if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.MELT_SPECIAL_OPEN_LEVEL then
		local compoundPage = "EquipCompoundPage";
		RegisterLuaPage(compoundPage);
		EquipCompoundPage_setEquipId(thisEquipId);
		PageManager.pushPage(compoundPage);
	else
		MessageBoxPage:Msg_Box(common:getLanguageString('@EquipCompoundLevelNotReached', GameConfig.MELT_SPECIAL_OPEN_LEVEL))
	end]]
end
-- 神器融合
function EquipInfoPageBase:onCompound(container)
    UserInfo.sync()
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.MELT_SPECIAL_OPEN_LEVEL then
        local compoundPage = "EquipCompoundPage";
        RegisterLuaPage(compoundPage);
        EquipCompoundPage_setEquipId(thisEquipId);
        PageManager.pushPage(compoundPage);
    else
        MessageBoxPage:Msg_Box(common:getLanguageString('@EquipCompoundLevelNotReached', GameConfig.MELT_SPECIAL_OPEN_LEVEL))
    end
end

function EquipInfoPageBase:onClose(container)
    GameUtil:hideClickOtherPage()
    PageManager.popPage(thisPageName);
end

-- 装备分解
function EquipInfoPageBase:onSuitDecomposition(container)
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.FORGE) then
            MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.FORGE))
    else
            MainFrame_onForge()
    end
    --PageManager.pushPage("EquipSuitDecompose"); 
    PageManager.popPage(thisPageName);

    -- 連到forge介面
    --MainFrame_onForge()
end

-- 装备进化
function EquipInfoPageBase:onEvoution(container)
    -- RegisterLuaPage("EquipEvolutionPage")
    -- EquipEvolutionPage_setItemId( thisEquipId )
    -- PageManager.pushPage( "EquipEvolutionPage" )
    local curEquipInfo = UserEquipManager:getUserEquipById(thisEquipId)
    local curItemInfo = EquipManager:getEquipCfgById(curEquipInfo.equipId)

    if curItemInfo.upgradeId == 0 and curItemInfo.evolutionId == 0 then
        MessageBoxPage:Msg_Box("@suitDecompositionNotHave7")
    elseif curItemInfo.upgradeId ~= 0 then
        RegisterLuaPage("EquipUpgradePage")
        EquipUpgradePage_setItemId(thisEquipId)
        PageManager.pushPage("EquipUpgradePage")
    elseif curItemInfo.evolutionId ~= 0 then
        RegisterLuaPage("EquipEvolutionPage")
        EquipEvolutionPage_setItemId(thisEquipId)
        PageManager.pushPage("EquipEvolutionPage")
    end
end

-- 套装碎片兑换
function EquipInfoPageBase.toPurchaseItems(flag, times)
    if flag and RelatedShopId ~= nil then
        local MultiElite_pb = require("MultiElite_pb")
        local message = MultiElite_pb.HPMultiEliteShopBuy()
        if message ~= nil then
            message.amount = times;
            message.buyId = RelatedShopId
            local pb_data = message:SerializeToString();
            PacketManager:getInstance():sendPakcet(HP_pb.MULTIELITE_SHOP_BUY_C, pb_data, #pb_data, true);
        end
    end
end
function EquipInfoPageBase:onChangeSuit(container)
    if RelatedItemId ~= nil and RelatedItemPrice ~= nil then
        PageManager.showCountTimesWithIconPage(Const_pb.TOOL, RelatedItemId, 3,
        function(count)
            return count * RelatedItemPrice
        end ,
        EquipInfoPageBase.toPurchaseItems, true, nil)
    end
end

-- 回包处理
function EquipInfoPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.EQUIP_ENHANCE_S then
        self:refreshPage(container);
        return;
    end

    if opcode == opcodes.EQUIP_DRESS_S then
        -- self:refreshPage(container);
        self:onClose();
        return;
    end
end

function EquipInfoPageBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_MAINFRAME_POPPAGE then
        local pageName = MsgMainFramePopPage:getTrueType(message).pageName;
        if pageName ~= thisPageName then
            self:refreshPage(container);
        end
    end
end
-- 註冊封包
function EquipInfoPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EquipInfoPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
EquipInfoPage = CommonPage.newSub(EquipInfoPageBase, thisPageName, option);

function EquipInfoPage_setEquipId(equipId, roleId, isShowExchangePoint)
    isExchangePoint = isShowExchangePoint ~= nil and isShowExchangePoint or false
    thisEquipId = equipId;
    thisRoleId = roleId
    isViewingOther = false;
    if not roleId then
        isViewMercenary = false
        isViewLeader = false
    elseif thisRoleId ~= UserInfo.roleInfo.roleId then
        isViewMercenary = true
        isViewLeader = false
    else
        isViewMercenary = false
        isViewLeader = true
    end
end

function EquipInfoPage_viewEquipId(equipId, isMercenary)
    thisEquipId = equipId;
    isViewingOther = true;
    isViewMercenary = isMercenary or false
    isViewLeader = false
end
