GameUtil = { };

------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
------------local variable for font api--------------------------------------
local defaultfontcolor = 0xffffffff
local isFontLoad = false
local NodeHelper = require("NodeHelper");
local json = require('json')

--------------------------------------------------------------------------------
RechargePlatformNames = { };
function GameUtil:sendUserData(lv, chap)
    local userData = {
        level = tostring(lv),
        chapter = tostring(chap)
    }
    local userDataJson = json.encode(userData)
    libOS:getInstance():sendUserData(userDataJson)
end

-- 增加字体
function GameUtil:createFont()
    if isFontLoad then return end
    local bdSize24 = 24;
    FontFactory:instance():create_font_forLua("HelveticaBD24",
    get_system_default_fontfile(),
    defaultfontcolor,
    bdSize24);



    isFontLoad = true
end

function GameUtil:getTotalExpByLevelAndExp(level, currentExp)
    local expCfg = ConfigManager.getRoleLevelExpCfg()
    local totalExp = 0
    if level > 1 then
        for i = 1, level - 1 do
            totalExp = totalExp + expCfg[i].exp
        end
    end
    totalExp = totalExp + currentExp
    return totalExp
end

function GameUtil:getRechargeList()
    --local Recharge_pb = require("Recharge_pb");
    --local msg = Recharge_pb.HPFetchShopList()
    --msg.platform = libPlatformManager:getPlatform():getClientChannel()
    --CCLuaLog("PlatformName2:" .. msg.platform)
    --
    --local HP_pb = require("HP_pb");
    --common:sendPacket(HP_pb.FETCH_SHOP_LIST_C, msg);
end

function GameUtil:doRecharge(goodsId)
    local shopItem = g_RechargeItemList[goodsId];
    if shopItem == nil then return; end

    --if shopItem.productType == 1 then
    --    local HP_pb = require("HP_pb");
    --
    --    local Recharge_pb = require("Recharge_pb");
    --    local msg = Recharge_pb.HPFetchShopList()
    --    msg.platform = libPlatformManager:getPlatform():getClientChannel()
    --    CCLuaLog("PlatformName2:" .. msg.platform)
    --    common:sendPacket(HP_pb.FETCH_SHOP_LIST_C, msg,false);
    --end

    local buyInfo = BUYINFO:new_local();
    buyInfo.productType = shopItem.productType;
    buyInfo.name = shopItem.name;
    buyInfo.productCount = 1
    buyInfo.productName = shopItem.productName
    buyInfo.productId = shopItem.productId
    buyInfo.productPrice = shopItem.productPrice
    buyInfo.productOrignalPrice = shopItem.gold

    buyInfo.description = ""
    if itemInfo:HasField("description") then
        buyInfo.description = itemInfo.description
    end
    buyInfo.serverTime = GamePrecedure:getInstance():getServerTime()

    local _type = tostring(itemInfo.productType)
--    if Golb_Platform_Info.is_yougu_platform then
--        -- 悠谷平台需要转换 productType
--        local rechargeTypeCfg = ConfigManager.getRecharageTypeCfg()
--        if rechargeTypeCfg[itemInfo.productType] then
--            _type = tostring(rechargeTypeCfg[itemInfo.productType].type)
--        end
--    end

    local _ratio = tostring(itemInfo.ratio)
    local extrasTable = { productType = _type, name = itemInfo.name, ratio = _ratio }
    buyInfo.extras = json.encode(extrasTable)

    -- libPlatformManager:getPlatform():buyGoods(buyInfo)
    local BuyManager = require("BuyManager")
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end

function GameUtil:getSkillTipStr(skillId)
    local strTb = { }
    local strTtb = { }

    table.insert(strTb, "")
    table.insert(strTtb, common:fillHtmlStr("TipName_1", common:getLanguageString("@Skill_Name_" .. math.floor(skillId / 10))))
    local oriSkillHtml = FreeTypeConfig[skillId] and FreeTypeConfig[skillId].content or " ></font>"
    -- 移除技能說明FreeTypeFont html部分
    local skillDesc = ""
    local tempStr = common:split(oriSkillHtml, " >")
    tempStr = common:split(tempStr[2], "</font>")
    skillDesc = tempStr[1]
    table.insert(strTb, common:fillHtmlStr("TipName_1", skillDesc))

    return table.concat(strTb, '<br/>'), false, strTtb[1]
end

function GameUtil:showSkillTip(relativeNode, skillId, hideCallBackExt)
    if GameConfig.isIOSAuditVersion then
        return
    end

    local Const_pb = require("Const_pb")
    local tipStr, isEquip, nameLabel = self:getSkillTipStr(skillId)
    if tipStr == nil or tipStr == "" or relativeNode == nil then return end
    GameUtil:showTipStr(relativeNode, tipStr, isEquip, itemCfg, nameLabel, hideCallBackExt)
end

function GameUtil:getTipStr(itemCfg)
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemCfg.type, itemCfg.itemId, itemCfg.count or 1);
    local Const_pb = require("Const_pb");
    local strTb = { };
    local strTtb = { };
    local isEquip = false

    if resInfo.mainType == Const_pb.BADGE then
        -- 徽章
        local FateDataInfo = require("FateDataInfo")
        local fateData = FateDataInfo.new( { id = 0, equipId = resInfo.itemId, level = 1, exp = 0 })
        local configData = fateData:getConf()
        table.insert(strTb, common:fillHtmlStr('TipName_', configData.name .. common:getLanguageString("@Rune")));
        --table.insert(strTb, "");
        table.insert(strTtb, common:fillHtmlStr('TipName_' .. resInfo.quality, configData.name .. common:getLanguageString("@Rune")));
        -- 基础属性文字
        --table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@BadgeBasicAttrTxt")))
        local basicAttrList = fateData:getFateBasicAttr()
        -- 基础属性
        if #basicAttrList > 0 then
            for _, v in ipairs(basicAttrList) do
                local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
                local name = common:getLanguageString("@AttrName_" .. v.type);
                local str = common:fillHtmlStr("TipCommon", common:getLanguageString("@EquipAttrVal", name, valueStr))
                table.insert(strTb, str)
            end
        end

        if configData.starAttr then
            if #configData.starAttr > 0 then
                -- 星级属性文字
                table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@BadgeStarAttrTxt")))
                -- 星级属性
                for _, v in ipairs(configData.starAttr) do
                    local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
                    local name = common:getLanguageString("@AttrName_" .. v.type);
                    local str = common:fillHtmlStr("SecondaryAttr_" .. resInfo.quality, common:getLanguageString("@EquipAttrVal", name, valueStr))
                    table.insert(strTb, str)
                end
            end
        end
        --        local nextAddAttrList = fateData:getNextAddAttr()
        --        if #nextAddAttrList > 0 then
        --                -- 升级后属性文字
        --            table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@BadgeUpgradeAttrTxt")))
        --                --升级后属性
        --            for _, v in ipairs(nextAddAttrList) do
        --                local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
        --                local name = common:getLanguageString("@AttrName_" .. v.type);
        --                local str = common:fillHtmlStr("GreenFontColor", common:getLanguageString("@EquipAttrVal", name, valueStr))
        --                table.insert(strTb, str)
        --            end
        --        end
        return table.concat(strTb, '<br/>'), isEquip, strTtb[1]
    end

    if resInfo.mainType == Const_pb.PLAYER_ATTR and resInfo.itemId == 2001 then
        table.insert(strTb, common:fillHtmlStr('TipForGuild'));
        return table.concat(strTb, '<br/>'), isEquip, strTb[1];
    end

    if resInfo.mainType == Const_pb.TOOL or resInfo.mainType == Const_pb.PLAYER_ATTR or resInfo.mainType == Const_pb.ELEMENT or resInfo.mainType == Const_pb.SOUL then
--        table.insert(strTb, common:fillHtmlStr('TipName_' .. resInfo.quality, resInfo.name));
        table.insert(strTb, "");
        table.insert(strTtb, common:fillHtmlStr('TipName_' .. resInfo.quality, resInfo.name));
        -- CCHTMLLabel:createWithString(common:fillHtmlStr('TipName_' .. resInfo.quality, resInfo.name), size, "Helvetica")
        table.insert(strTb, common:fillHtmlStr('TipCommon', resInfo.describe));

        if resInfo.describe2 then
            if resInfo.describe2 ~= "" then
                table.insert(strTb, common:fillHtmlStr('ItemProduce', resInfo.describe2));
            end
        end

        if resInfo.type == Const_pb.GEM then
            local ItemManager = require("Item.ItemManager");
            local str = ItemManager:getNewGemAttrString(resInfo.itemId)

            -- table.insert(strTb, ItemManager:getNewGemAttrString(resInfo.itemId))
            table.insert(strTb, common:fillHtmlStr('GemDesAttrDes', str))
        end
    elseif resInfo.mainType == Const_pb.SOUL then
--        table.insert(strTb, common:fillHtmlStr('TipName_' .. resInfo.quality, resInfo.name));
        table.insert(strTb, "");
        table.insert(strTtb, common:fillHtmlStr('TipName_' .. resInfo.quality, resInfo.name));
        -- CCHTMLLabel:createWithString(common:fillHtmlStr('TipName_' .. resInfo.quality, resInfo.name), size, "Helvetica")
        table.insert(strTb, FreeTypeConfig[tonumber(resInfo.describe)].content);
    elseif resInfo.mainType == Const_pb.EQUIP then
        isEquip = true
        local equipId = resInfo.itemId;
        --local title = common:getLanguageString('@LevelAndName', EquipManager:getLevelById(equipId), resInfo.name);
        local title = common:getLanguageString('@LevelName', resInfo.name);
--        table.insert(strTb, common:fillHtmlStr('TipName_' .. resInfo.quality, title));
        table.insert(strTb, "");
        table.insert(strTtb, common:fillHtmlStr('TipName_' .. resInfo.quality, title));
        table.insert(strTb, common:fillHtmlStr('TipCommon', EquipManager:getPartNameById(equipId)));
        --local professionId = EquipManager:getProfessionById(equipId);
        --if professionId and professionId > 0 then
        --    local professionName = common:getLanguageString("@ProfessionName_" .. professionId);
        --    table.insert(strTb, common:fillHtmlStr("TipCondition", professionName));
        --end
        table.insert(strTb, common:fillHtmlStr('TipCommon', EquipManager:getInitAttr(equipId)));
        if itemCfg.buyTip then
            local attrNum = GameConfig.Quality2AttrNum[resInfo.quality or 1];
            if attrNum > 0 and itemCfg.hideBuyNum == nil then
                --table.insert(strTb, common:fillHtmlStr('TipBuyEquip', attrNum));
            end
            if itemCfg.starEquip then
                --table.insert(strTb, common:fillHtmlStr('TipStarEquip'));
            end
            --table.insert(strTb, common:fillHtmlStr('TipSmeltEquip'));
        end
    else
        return nil;
    end
    --return table.concat(strTb, '<br/>'), isEquip, strTb[1];
    return table.concat(strTb, '<br/>'), isEquip, strTtb[1];
end

function GameUtil:showTip(relativeNode, itemCfg, hideCallBackExt)
    if GameConfig.isIOSAuditVersion then
        return
    end

    -- TODO
    if itemCfg.type == 70000 and itemCfg.itemId == 204 then
        require("FashionShowCardPopUp")
        FashionShowCardPopUpBase_setRoleId(itemCfg.itemId)
        PageManager.pushPage("FashionShowCardPopUp")
        return
        --        if GameConfig.getRoleCfg()[itemCfg.itemId] and  GameConfig.getRoleCfg()[itemCfg.itemId].avatarName ~= "0" then

        --            return
        --        end
    end


    local Const_pb = require("Const_pb");
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemCfg.type, itemCfg.itemId, itemCfg.count or 1);
    if resInfo.type and resInfo.type == Const_pb.AVATAR_GIFT then
        --        local LeaderAvatarManager = require("LeaderAvatarManager")
        --        LeaderAvatarManager:setPreviewShop(itemCfg)
        --        PageManager.pushPage("LeaderAvatarShowPage")
        return
    end
    local tipStr, isEquip, nameLabel = self:getTipStr(itemCfg);
    if tipStr == nil or tipStr == '' or relativeNode == nil then return; end
    GameUtil:showTipStr(relativeNode, tipStr, isEquip, itemCfg, nameLabel, hideCallBackExt)
end
function GameUtil:showTip2(relativeNode, itemCfg, hideCallBackExt)
    if GameConfig.isIOSAuditVersion then
        return
    end

    -- TODO
    if itemCfg.type == 70000 and itemCfg.itemId == 204 then
        require("FashionShowCardPopUp")
        FashionShowCardPopUpBase_setRoleId(itemCfg.itemId)
        PageManager.pushPage("FashionShowCardPopUp")
        return
        --        if GameConfig.getRoleCfg()[itemCfg.itemId] and  GameConfig.getRoleCfg()[itemCfg.itemId].avatarName ~= "0" then

        --            return
        --        end
    end


    local Const_pb = require("Const_pb");
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemCfg.type, itemCfg.itemId, itemCfg.count or 1);
    if resInfo.type and resInfo.type == Const_pb.AVATAR_GIFT then
        --        local LeaderAvatarManager = require("LeaderAvatarManager")
        --        LeaderAvatarManager:setPreviewShop(itemCfg)
        --        PageManager.pushPage("LeaderAvatarShowPage")
        return
    end
    local tipStr, isEquip, nameLabel = self:getTipStr(itemCfg);
    if tipStr == nil or tipStr == '' or relativeNode == nil then return; end
    GameUtil:showTipStr3(relativeNode, tipStr, isEquip, itemCfg, nameLabel, hideCallBackExt)
end

function GameUtil:showTipStr(relativeNode, tipStr, isEquip, itemCfg, nameLabel, hideCallBackExt)
    if GameConfig.isIOSAuditVersion then
        return
    end

    local layerTag = GameConfig.Tag.TipLayer;
    local winSize = CCDirector:sharedDirector():getWinSize();
    local mainFrame = tolua.cast(MainFrame:getInstance(), 'CCNode');
    local layer = mainFrame:getChildByTag(layerTag);

    if not layer then
        layer = CCLayer:create();
        layer:setTag(layerTag);
        mainFrame:addChild(layer);
        layer:setContentSize(winSize);

    end
    layer:registerScriptTouchHandler( function(eventName, pTouch)
        if eventName == "ended" then
            GameUtil:hideTip();
            if (hideCallBackExt ~= nil) then
                hideCallBackExt()
            end
            return true;
        end
    end
    , false, 0, false);
    layer:setTouchEnabled(true);
    layer:setVisible(true);

    local tipTag = layerTag + 1;
    if layer:getChildByTag(tipTag) then
        layer:removeChildByTag(tipTag, true);
    end

    local tipNode = ScriptContentBase:create('Tips.ccbi');
    tipNode:setAnchorPoint(ccp(0, 0));

    local tipWidth = GameConfig.LineWidth.Tip;

    local label = NodeHelper:addHtmlLable_Tips(tipNode:getVarNode('mTipsText'), tipStr, GameConfig.Tag.HtmlLable, CCSizeMake(tipWidth, 50), tipNode:getVarNode('mTipsText'));    
    local title_label = NodeHelper:addHtmlLable_Tips(tipNode:getVarNode('mTipsTitle'), nameLabel, GameConfig.Tag.HtmlLable , CCSizeMake(tipWidth , 50), tipNode:getVarNode('mTipsTitle'));
    
    -- mLine, mTipsText, mTipsTitle
    local mScale9Sprite = tipNode:getVarScale9Sprite('mScale9Sprite');
    local mTipsText = tipNode:getVarNode('mTipsText');
    local mTipsTitle = tipNode:getVarNode('mTipsTitle');
    --local mLine = tipNode:getVarNode('mLine');
    
    if mScale9Sprite then
        local scale9Width = tipWidth + 40
        local titleSize = title_label:getContentSize()
        local labelSize = label:getContentSize()
        local margin = 5
        mScale9Sprite:setContentSize(CCSizeMake(scale9Width, labelSize.height + titleSize.height + margin * 10))
        label:setPositionX(scale9Width / 2)
        label:setPositionY(20)
        --label:setPositionX(label:getPositionX() - margin * 4)      
        --label:setPositionY(label:getPositionY() + margin * 4)       
        title_label:setPositionX(scale9Width / 2)--(- margin * 4) -- title_label:getPositionX() - title_label:getPositionX() / 2
        title_label:setPositionY(0)--(margin)
        --mLine:setPositionX(label:getPositionX() + margin)
    end
    local tipHeight = mScale9Sprite:getContentSize().height
    local posX, posY = relativeNode:getPosition();
    local size = relativeNode:getContentSize();
    local pos = relativeNode:convertToWorldSpace(ccp(posX + size.width, posY));
    if pos.x + tipWidth >= winSize.width then
        pos = relativeNode:convertToWorldSpace(ccp(posX, posY));
        if pos.x >= winSize.width then
            pos.x = winSize.width
        end
        pos.x = pos.x - tipWidth - 50;
    end
    if pos.x < 0 then
        pos.x = 0 + tipWidth / 4
    end
    if pos.y - tipHeight < 0 then
        pos.y = tipHeight
    end
    local newPos = layer:convertToNodeSpace(pos);
    tipNode:setPosition(newPos);
    tipNode:setTag(tipTag);
    layer:addChild(tipNode);
    
    local _star = tipNode:getVarSprite("mStar")
    if isEquip then
        local _label = CCHTMLLabel:createWithString(nameLabel, tipNode:getVarNode('mTipsText'):getContentSize(), "Barlow-SemiBold")
        _star:setAnchorPoint(ccp(0, 1))
        local stepLevel = EquipManager:getEquipStepById(itemCfg.itemId)
        local posX = _label:getPositionX() + _label:getContentSize().width * _label:getScaleX()
        EquipManager:setStarPosition(_star, stepLevel == GameConfig.ShowStepStar, posX, posY - 15)
    else
        _star:setVisible(false)

    end
    tipNode:release();
end

function GameUtil:showTipStr3(relativeNode, tipStr, isEquip, itemCfg, nameLabel, hideCallBackExt)
    if GameConfig.isIOSAuditVersion then
        return
    end

    local layerTag = GameConfig.Tag.TipLayer;
    local winSize = CCDirector:sharedDirector():getWinSize();
    local mainFrame = tolua.cast(MainFrame:getInstance(), 'CCNode');
    local layer = mainFrame:getChildByTag(layerTag);

    if not layer then
        layer = CCLayer:create();
        layer:setTag(layerTag);
        mainFrame:addChild(layer);
        layer:setContentSize(winSize);

    end
    layer:registerScriptTouchHandler( function(eventName, pTouch)
        if eventName == "ended" then
            GameUtil:hideTip();
            if (hideCallBackExt ~= nil) then
                hideCallBackExt()
            end
            return true;
        end
    end
    , false, 0, false);
    layer:setTouchEnabled(true);
    layer:setVisible(true);

    local tipTag = layerTag + 1;
    if layer:getChildByTag(tipTag) then
        layer:removeChildByTag(tipTag, true);
    end

    local tipNode = ScriptContentBase:create('Tips.ccbi');
    tipNode:setAnchorPoint(ccp(0, 0));

    local tipWidth = GameConfig.LineWidth.Tip;

    local label = NodeHelper:addHtmlLable_Tips(tipNode:getVarNode('mTipsText'), tipStr, GameConfig.Tag.HtmlLable, CCSizeMake(tipWidth, 50));    
    local title_label = NodeHelper:addHtmlLable(tipNode:getVarNode('mTipsTitle'), nameLabel, GameConfig.Tag.HtmlLable , CCSizeMake(tipWidth , 50), tipNode:getVarNode('mTipsTitle'));
    
    -- mLine, mTipsText, mTipsTitle
    local mScale9Sprite = tipNode:getVarScale9Sprite('mScale9Sprite');
    local mTipsText = tipNode:getVarNode('mTipsText');
    local mTipsTitle = tipNode:getVarNode('mTipsTitle');
    --local mLine = tipNode:getVarNode('mLine');
    
    if mScale9Sprite then
        local labelSize = label:getContentSize();
        local margin = 15;
        --label:setPositionX(label:getPositionX() + margin)
        --label:setPositionY(label:getPositionY() - margin * 2)
        label:setPositionX(label:getPositionX() - margin * 4)      
        label:setPositionY(label:getPositionY() + margin * 4)       
        title_label:setPositionX(- margin * 4) -- title_label:getPositionX() - title_label:getPositionX() / 2
        title_label:setPositionY(margin)
        --mLine:setPositionX(label:getPositionX() + margin)
        mScale9Sprite:setContentSize(CCSizeMake(tipWidth + 15, labelSize.height + margin * 8));
    end
    local tipHeight = mScale9Sprite:getContentSize().height
    local posX, posY = relativeNode:getPosition();
    local size = relativeNode:getContentSize();
    local pos = relativeNode:convertToWorldSpace(ccp(posX + size.width, posY+50));
    if pos.x + tipWidth > winSize.width then
        pos = relativeNode:convertToWorldSpace(ccp(posX, posY));
        pos.x = pos.x - tipWidth - 15;
    end
    if pos.x < 0 then
        pos.x = 0 + tipWidth / 4
    end
    if pos.y - tipHeight < 0 then
        pos.y = tipHeight
    end
    local newPos = layer:convertToNodeSpace(pos);
    tipNode:setPosition(newPos);
    tipNode:setTag(tipTag);
    layer:addChild(tipNode);
    
    local _star = tipNode:getVarSprite("mStar")
    if isEquip then
        local _label = CCHTMLLabel:createWithString(nameLabel, tipNode:getVarNode('mTipsText'):getContentSize(), "Helvetica")
        _star:setAnchorPoint(ccp(0, 1))
        local stepLevel = EquipManager:getEquipStepById(itemCfg.itemId)
        local posX = _label:getPositionX() + _label:getContentSize().width * _label:getScaleX()
        EquipManager:setStarPosition(_star, stepLevel == GameConfig.ShowStepStar, posX, posY - 15)
    else
        _star:setVisible(false)

    end
    tipNode:release();
end


function GameUtil:clickOtherClosePage(relativeNode, hideCallBackExt, contain, offsetX, offsetY)
    local GuideManager = require("Guide.GuideManager")

    if GuideManager.isInGuide then
        return
    end
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    contain = contain or nil
    if GameConfig.isIOSAuditVersion then
        return
    end
    local layerTag = GameConfig.Tag.ClosePage;
    local winSize = CCDirector:sharedDirector():getWinSize();
    local layer = nil
    local mainFrame = nil
    if contain == nil then
        mainFrame = tolua.cast(MainFrame:getInstance(), 'CCNode');
    else
        mainFrame = tolua.cast(contain, 'CCNode');
    end
    layer = mainFrame:getChildByTag(layerTag);
    if not layer then
        layer = CCLayer:create();
        layer:setTag(layerTag);
        mainFrame:addChild(layer);
        layer:setContentSize(winSize);
    end

    layer:registerScriptTouchHandler( function(eventName, pTouch)
        if eventName == "began" then
            if GameUtil:isClickOther(relativeNode, pTouch, offsetX, offsetY) then
                if (hideCallBackExt ~= nil) then
                    hideCallBackExt()
                end
                return true;
            end
        end
    end
    , false, 0, false);
    layer:setTouchEnabled(true);
    layer:setVisible(true);

end

function GameUtil:isClickOther(relativeNode, pTouch, offsetX, offsetY)
    local isClickOther = false
    local pTouchPos = pTouch:getLocation()
    local a = type(relativeNode)
    if relativeNode ~= nil and type(relativeNode) == "userdata" then
        local posX, posY = relativeNode:getPosition()
        local relativeNodeWorldPos = relativeNode:getParent():convertToWorldSpace(ccp(posX, posY));
        local relativeNodeWorldPosX = relativeNodeWorldPos.x
        local relativeNodeWorldPosY = relativeNodeWorldPos.y
        local archoPoint = relativeNode:getAnchorPoint()
        local relativeNodeSize = relativeNode:getContentSize()
        local sizeWidth = relativeNodeSize.width + offsetX
        local sizeHight = relativeNodeSize.height + offsetY
        if (relativeNodeWorldPosX - sizeWidth * archoPoint.x) < pTouchPos.x and
            pTouchPos.x <(relativeNodeWorldPosX + sizeWidth *(1 - archoPoint.x)) and
            (relativeNodeWorldPosY - sizeHight * archoPoint.y) < pTouchPos.y and
            pTouchPos.y <(relativeNodeWorldPosY + sizeHight *(1 - archoPoint.y)) then
        else
            isClickOther = true
        end
    else
        GameUtil:hideClickOtherPage()
    end
    return isClickOther
end

function GameUtil:hideClickOtherPage()
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        return
    end
    local layerTag = GameConfig.Tag.ClosePage;
    local mainFrame = tolua.cast(MainFrame:getInstance(), 'CCNode');
    local layer = mainFrame:getChildByTag(layerTag);
    if layer then
        layer:setVisible(false);
    end
end

function GameUtil:hideTip()
    local layerTag = GameConfig.Tag.TipLayer;
    local mainFrame = tolua.cast(MainFrame:getInstance(), 'CCNode');
    local layer = mainFrame:getChildByTag(layerTag);
    if layer then
        layer:setVisible(false);
    end
end

function GameUtil:showLevelUpAni()
    local LevelUpPageBase=require("LevelUpPage")
    PageManager.pushPage("LevelUpPage")
end
function GameUtil:removeLevelUpAni()
    local mainFrame = tolua.cast(MainFrame:getInstance(), 'CCNode');
    if mainFrame == nil or(GamePrecedure:getInstance():isInLoadingScene()) then
        return
    end
    local levelupTag = GameConfig.Tag.TipLevelUp;
    local levelUpNode = mainFrame:getChildByTag(levelupTag);
    if levelUpNode then
        levelUpNode:removeAllChildren()
    end
end

function GameUtil:showWingGuidAnimation()
    local mainFrame = tolua.cast(MainFrame:getInstance(), 'CCNode');
    if mainFrame == nil or(GamePrecedure:getInstance():isInLoadingScene()) then
        return
    end
    local levelupTag = GameConfig.Tag.TipLevelUp;
    local levelUpNode = mainFrame:getChildByTag(levelupTag);
    if not levelUpNode then
        levelUpNode = CCNode:create();
        levelUpNode:setTag(levelupTag);
        local winSize = CCDirector:sharedDirector():getWinSize();
        local posX = winSize.width / 2
        local posY = winSize.height / 2
        levelUpNode:setPosition(posX, posY)
        mainFrame:addChild(levelUpNode);
    end
    levelUpNode:removeAllChildren()
    local WingGuidCCB = ScriptContentBase:create('A_WingGuild.ccbi');
    WingGuidCCB:runAnimation("Default Timeline");
    levelUpNode:addChild(WingGuidCCB);
    WingGuidCCB:release();
end

-- 清楚纹理内存相关	
function GameUtil:purgeCachedDataOnlyTexture()
    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFramesPerFrame();
    CCTextureCache:sharedTextureCache():removeUnusedTexturesPerFrame();
end
-- 清楚纹理内存相关	以及CCBI
function GameUtil:purgeCachedData()
    CCBFileNew:purgeCachedData()
    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFramesPerFrame();
    CCTextureCache:sharedTextureCache():removeUnusedTexturesPerFrame();
end

-- 数字位数过多，变为亿，万 -added
function GameUtil:formatNumber(bigNumber)
    local showNumber = 100
    local tera = 1000000000000
    local giga = 1000000000
    local mega = 1000000
    local kilo = 1000

    local tempNumber = tonumber(bigNumber)

    if tempNumber >= tera * showNumber then
        tempNumber = math.floor(tempNumber / tera) .. "T"
    elseif tempNumber >= giga * showNumber and tempNumber < tera * showNumber then
        tempNumber = math.floor(tempNumber / giga) .. "G"
    elseif tempNumber >= mega * showNumber and tempNumber < giga * showNumber then
        tempNumber = math.floor(tempNumber / mega) .. "M"
    elseif tempNumber >= kilo * showNumber and tempNumber < mega * showNumber then
        tempNumber = math.floor(tempNumber / kilo) .. "K"
    else
        tempNumber = tempNumber .. ""
    end
    return tempNumber
end

function GameUtil:formatDotNumber(bigNumber)
    local tempNumber = tonumber(bigNumber)
    if not tempNumber then
        return bigNumber
    end
    if tempNumber >= 1000000000 then
        local b = math.floor(tempNumber / 1000000000)
        local m = string.format("%03d", math.floor((tempNumber % 1000000000) / 1000000))
        local k = string.format("%03d", math.floor((tempNumber % 1000000) / 1000))
        local h = string.format("%03d", tonumber(tempNumber % 1000))
        tempNumber = b .. "," .. m  .. ","  .. k  .. "," .. h
    elseif tempNumber >= 1000000 then
        local m = math.floor((tempNumber % 1000000000) / 1000000)
        local k = string.format("%03d", math.floor((tempNumber % 1000000) / 1000))
        local h = string.format("%03d", tonumber(tempNumber % 1000))
        tempNumber = m  .. ","  .. k  .. "," .. h
    elseif tempNumber >= 1000 then
        local k = math.floor((tempNumber % 1000000) / 1000)
        local h = string.format("%03d", tonumber(tempNumber % 1000))
        tempNumber = k  .. "," .. h
    end
    
    return tempNumber
end

function GameUtil:formatNumberMinBillion(bigNumber)
 
    local tempNumber = tonumber(bigNumber)
    if tempNumber >= 100000000 then
        local nMillion = tempNumber
        tempNumber = math.floor(nMillion / 100000000) .. common:getLanguageString("@HundredMillionUnit")
        if math.floor((nMillion % 100000000) / 10000) > 0 then
            tempNumber = tempNumber .. math.floor((nMillion % 100000000) / 10000) .. common:getLanguageString("@TenThousandUnit")
        end
    end

    return tempNumber
end


-- 最高到亿
function GameUtil:formatNumberMaxBillion(bigNumber)
    local tempNumber = tonumber(bigNumber)
    if tempNumber >= 100000000 then
        local nMillion = tempNumber
        tempNumber = math.floor(nMillion / 100000000) .. common:getLanguageString("@HundredMillionUnit")
        if math.floor((nMillion % 100000000) / 10000) > 0 then
            -- tempNumber = tempNumber .. math.floor((nMillion % 100000000) / 10000) .. common:getLanguageString("@TenThousandUnit")
        end
    elseif tempNumber >= 10000 then
        local nMillion = tempNumber
        tempNumber = math.floor(nMillion / 10000) .. common:getLanguageString("@TenThousandUnit")
    end
    return tempNumber
end

function GameUtil:formatFixedLenNumber(number, len)
    if string.len(number) >= len or number < 0 then
        return number
    end
    local newNumber = number
    while (string.len(newNumber) < len) do
        newNumber = "0" .. newNumber
    end
    return newNumber
end

function GameUtil:CNYToPlatformPrice(cny, platform)
    local usd = (cny / 7) - (cny / 7) % 0.1
    if platform == nil or platform == "" then
        return usd
    elseif platform == "H365" then 
        return cny
    elseif platform == "EROR18" then 
        return cny * GameConfig.eroPriceRatio
    elseif platform == "JGG" then 
        return usd * GameConfig.jggPriceRatio
    else
        return cny
    end
end

-- 裝備濾掉不必要顯示的key
function GameUtil:checkEquipKeyNeed(equipKey)
    local isNeed = false;
    
    if(tonumber(equipKey) == 104)
    then
        isNeed = false;
    else
        isNeed = true;
    end

    return isNeed;
end

-- 拆解[名稱_數值]
function GameUtil:splitData(dataInfo)
    local data = {}
	for _, dataTmp in ipairs(common:split(dataInfo, ",")) do
		local _name, _value = unpack(common:split(dataTmp, "_"));
		table.insert(data, {           		
			name	= _name,
			value 	= _value
		});
	end
	return data;
end

function GameUtil:deepCopy(tb, layer)
    if tb == nil then
        return nil
    end
    layer = layer or 1
    if layer >= 4 then
        return
    end
    local copy = {}
    for k, v in pairs(tb) do
        if type(v) == 'table' then
            copy[k] = GameUtil:deepCopy(v, layer + 1)
        else
            copy[k] = v
        end
    end
    return copy
end

function GameUtil:pairsByKeys(t)      
    local a = { }      
    for n in pairs(t) do          
        a[#a+1] = n      
    end      
    table.sort(a)      
    local i = 0      
    return function()          
        i = i + 1          
        return a[i], t[a[i]]      
    end  
end

function GameUtil:setMainNodeVisible(visible)      
    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local backNode = mainContainer:getCCNodeFromCCB("mNodeBack")
    backNode:setVisible(visible) 
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(visible)
end

function GameUtil:setPlayMovieVisible(visible)      
    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local backNode = mainContainer:getCCNodeFromCCB("mNodeBack")
    backNode:setVisible(visible) 
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(visible)
    if visible then
        MainFrame:getInstance():setBackgroundColor(0, 0, 0, 1)
    else
        MainFrame:getInstance():setBackgroundColor(0, 0, 0, 0)
    end
end

function GameUtil:shuffleTable(table)      
    if type(table) ~= "table" then
        return
    end
    local tempTable = { }
    for i = 1, #table do
        tempTable[i] = table[i]
    end
    for i = 1, #tempTable do
        local rand = math.random(1, #tempTable)
        tempTable[i], tempTable[rand] = tempTable[rand], tempTable[i]
    end
    return tempTable
end