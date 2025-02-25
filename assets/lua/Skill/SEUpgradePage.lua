----------------------------------------------------------------------------------
-- 技能强化
----------------------------------------------------------------------------------

local thisPageName = "SEUpgradePage"
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper");
local option = {
    ccbiFile = "SkillSpecialtyPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose"
    }
}

local SEUpgradePageBase = { }
local SkillItemId = 0
local Profession = 0
local SelectIndex = 0
local SEManager = require("Skill.SEManager")
local MaxItemSize = 3

local UpgradeType = {
    Attribute = 0,
    Replace = 1,
    NewSkill = 2
}

-- ÈýÌ×£¬ÏÂ½Ç±êÎª{1,2,3},{4,5},{6}
local ItemLabelName = {
    [1] =
    {
        pic = "mOneMaterialPic0",
        num = "mOneMaterialNum0",
        name = "mOneMaterialName0",
        btn = "mOneMaterialBtn0",
        selected = "mOneTexBg"
    },
    [2] =
    {
        pic = "mTwoMaterialPic0",
        num = "mTwoMaterialNum0",
        name = "mTwoMaterialName0",
        btn = "mTwoMaterialBtn0",
        selected = "mTwoTexBg"
    },
    [3] =
    {
        pic = "mThreeMaterialPic0",
        num = "mThreeMaterialNum0",
        name = "mThreeMaterialName0",
        btn = "mThreeMaterialBtn0",
        selected = "mThreeTexBg"
    }
}


----------------------------------------------------------------------------------
local SEUpgradeItem1 = {
    ccbiFile = "SkillSpecialtyUpgradeContent.ccbi"
}

function SEUpgradeItem1.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        SEUpgradeItem1.onRefreshItemView(container);
    end
end


function SEUpgradeItem1.onRefreshItemView(container)
    local labelStr = { }
    local spriteImg = { }
    local labelColor = { }

    local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    local tempLevel = SEManager:getTempLevel(SkillItemId)
    local skillTempInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId)
    local nextTempInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)

    level = SEManager:getOriginalLevelByItemId(SkillItemId)
    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    local UserInfo = require("PlayerInfo.UserInfo")
    if skillInfo ~= nil then
        spriteImg.mUpgradePic01 = skillInfo.icon
        labelStr.mUpgradeName = skillInfo.name

        -- Í·²¿
        spriteImg.mEvolutionPic01 = skillInfo.icon
        labelStr.mEvolutionName1 = skillInfo.name
        -- labelStr.mLevelNum1 = tostring(level)
        -- if tempLevel > 0 then labelStr.mTempLevel = "+" .. tempLevel end
        --    labelStr.mEvolutionTex = GameMaths:stringAutoReturnForLua(skillTempInfo.describe,17,0)
        local describe = skillTempInfo.describe
        describe = GameMaths:replaceStringWithCharacterAll(describe, "#v1#", skillTempInfo.param1)
        describe = GameMaths:replaceStringWithCharacterAll(describe, "#v2#", skillTempInfo.param2)
        describe = GameMaths:replaceStringWithCharacterAll(describe, "#v3#", skillTempInfo.param3)
        NodeHelper:setCCHTMLLabel(container, "mEvolutionTex", CCSize(600, 96), describe, true)
        labelStr.mCurrentMPNum1 = tostring(skillInfo.costMP)

        local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)
        if nextInfo ~= nil and(level + 1) <= SEManager:getConfigDataByKey("SEMaxUpLevel") then
            -- ÏÂÒ»µÈ¼¶ÐÅÏ¢
            -- labelStr.mNextLevelNum1 = tostring(level+1)
            -- if tempLevel > 0 then labelStr.mTempNextLevel = "+" .. tempLevel end
            labelStr.mMpConsumptionNum = tostring(nextInfo.costMP)
            -- ÒªÇóµÈ¼¶
            local color = UserInfo.roleInfo.level < skillInfo.openLevel and SEManager:getConfigDataByKey("Red") or SEManager:getConfigDataByKey("Normal")
            labelStr.mPlayerLevelNum = tostring(skillInfo.openLevel)
            --labelColor.mPlayerLevelNum = color
            -- ÒªÇó×¨¾«
            local color = SEManager.SELevel[Profession] < skillInfo.seLevel and SEManager:getConfigDataByKey("Red") or SEManager:getConfigDataByKey("Normal")
            labelStr.mSpecializationLevelNum = tostring(skillInfo.seLevel)
            --labelColor.mSpecializationLevelNum = color
            -- ÏÂÒ»¼¶¼¼ÄÜÃèÊö
            --    labelStr.mSkillDescription = GameMaths:stringAutoReturnForLua(nextTempInfo.describe,17,0)
            local nextDescribe = nextTempInfo.describe
            nextDescribe = GameMaths:replaceStringWithCharacterAll(nextDescribe, "#v1#", nextTempInfo.param1)
            nextDescribe = GameMaths:replaceStringWithCharacterAll(nextDescribe, "#v2#", nextTempInfo.param2)
            nextDescribe = GameMaths:replaceStringWithCharacterAll(nextDescribe, "#v3#", nextTempInfo.param3)
            NodeHelper:setCCHTMLLabel(container, "mSkillDescription", CCSize(600, 96), nextDescribe, true)
            -- NodeHelper:setLabelOneByOne(container,"mNextLevel","mNextLevelNum1",10)	
        else
            local NextLevel = {
                mEvolutionNode = false
            }
            NodeHelper:setNodesVisible(container, NextLevel);
        end



    end

    NodeHelper:setStringForLabel(container, labelStr)
    NodeHelper:setSpriteImage(container, spriteImg)
    NodeHelper:setColorForLabel(container, labelColor)
    -- NodeHelper:setLabelOneByOne(container,"mNextLevelNum1","mTempNextLevel",3)
end


local SEUpgradeItem2 = {
    ccbiFile = "SkillSpecialtyEvolutionContent.ccbi"
}

function SEUpgradeItem2.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        SEUpgradeItem2.onRefreshItemView(container);
    end
end


function SEUpgradeItem2.onRefreshItemView(container)
    local labelStr = { }
    local spriteImg = { }
    local labelColor = { }

    local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    local tempLevel = SEManager:getTempLevel(SkillItemId)
    local skillTempInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId)
    local nextTempInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)
    level = SEManager:getOriginalLevelByItemId(SkillItemId)
    -- SkillItemId = SkillItemId - tempLevel
    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)
    local UserInfo = require("PlayerInfo.UserInfo")
    if skillInfo ~= nil then
        -- Í·²¿
        spriteImg.mEvolutionPic01 = skillTempInfo.icon
        labelStr.mEvolutionName1 = skillTempInfo.name
        NodeHelper:setStringForLabel(container, { ["mSkillLv1"] = common:getLanguageString("@LevelStr", level) })
        -- labelStr.mLevelNum1 = "Lv." .. tostring(level)
        -- if tempLevel > 0 then labelStr.mTempLevel = "+" .. tempLevel end
        labelStr.mCurrentMPNum1 = common:getLanguageString("@SkillEvolutionCostMPTxt", tostring(skillInfo.costMP))
        --    labelStr.mEvolutionTex = GameMaths:stringAutoReturnForLua(skillTempInfo.describe,23,0)
        local describe = skillTempInfo.describe
        describe = GameMaths:replaceStringWithCharacterAll(describe, "#v1#", skillTempInfo.param1)
        describe = GameMaths:replaceStringWithCharacterAll(describe, "#v2#", skillTempInfo.param2)
        describe = GameMaths:replaceStringWithCharacterAll(describe, "#v3#", skillTempInfo.param3)

        labelStr.mEvolutionTex = common:stringAutoReturn(describe, GameConfig.LabelCharMaxNumOneLine.SkillSpecialtyEvolutionContent)
        labelColor.mEvolutionTex = GameConfig.LabelSkillDescColor.SkillSpecialtyEvolutionContent
        -- NodeHelper:setCCHTMLLabel(container,"mEvolutionTex",CCSize(600,96),describe,true)	
        NodeHelper:setNodesVisible(container, { mNew = nextInfo ~= nil and(level + 1) <= SEManager:getConfigDataByKey("SEMaxUpLevel") })
        if nextInfo ~= nil and(level + 1) <= SEManager:getConfigDataByKey("SEMaxUpLevel") then
            -- ÏÂÒ»µÈ¼¶ÐÅÏ¢
            NodeHelper:setStringForLabel(container, { ["mSkillLv2"] = common:getLanguageString("@LevelStr", level + 1) })
            spriteImg.mEvolutionPic02 = nextInfo.icon
            labelStr.mEvolutionName2 = nextInfo.name
            labelStr.mLevelNum2 = tostring(level + 1)
            -- labelStr.mNextLevelNum1 = "Lv." .. tostring(level+1)
            -- if tempLevel > 0 then labelStr.mTempNextLevel = "+" .. tempLevel end
            labelStr.mMpConsumptionNum = common:getLanguageString("@SkillEvolutionCostMPTxt", tostring(nextInfo.costMP))
            -- ÒªÇóµÈ¼¶
            local color = UserInfo.roleInfo.level < nextInfo.openLevel and SEManager:getConfigDataByKey("Red") or SEManager:getConfigDataByKey("Normal")
            labelStr.mPlayerLevelNum = tostring(nextInfo.openLevel)
            --labelColor.mPlayerLevelNum = color
            -- ÒªÇó×¨¾«
            local color = SEManager.SELevel[Profession] < nextInfo.seLevel and SEManager:getConfigDataByKey("Red") or SEManager:getConfigDataByKey("Normal")
            labelStr.mSpecializationLevelNum = tostring(nextInfo.seLevel)
            --labelColor.mSpecializationLevelNum = color
            -- ÏÂÒ»¼¶¼¼ÄÜÃèÊö
            -- labelStr.mSkillDescription = GameMaths:stringAutoReturnForLua(nextTempInfo.describe,23,0)
            local nextDescribe = nextTempInfo.describe
            nextDescribe = GameMaths:replaceStringWithCharacterAll(nextDescribe, "#v1#", nextTempInfo.param1)
            nextDescribe = GameMaths:replaceStringWithCharacterAll(nextDescribe, "#v2#", nextTempInfo.param2)
            nextDescribe = GameMaths:replaceStringWithCharacterAll(nextDescribe, "#v3#", nextTempInfo.param3)
            labelColor.mSkillDescription = GameConfig.LabelSkillDescColor.SkillSpecialtyEvolutionContent
            labelStr.mSkillDescription = common:stringAutoReturn(nextDescribe, GameConfig.LabelCharMaxNumOneLine.SkillSpecialtyEvolutionContent)

            -- NodeHelper:setCCHTMLLabel(container,"mSkillDescription",CCSize(600,96),nextDescribe,true)		
            -- NodeHelper:setLabelOneByOne(container,"mNextLevel","mNextLevelNum1",10)
        else
            local NextLevel = {
                mEvolutionNode = false
            }
            NodeHelper:setNodesVisible(container, NextLevel);
        end
    end
    if skillInfo.type ~= UpgradeType.Replace then
        local skillsUpradingEffect = {
            mSkillsUpradingEffect = false
        }
        NodeHelper:setNodesVisible(container, skillsUpradingEffect)
    end
    NodeHelper:setStringForLabel(container, labelStr)
    NodeHelper:setSpriteImage(container, spriteImg)
    NodeHelper:setColorForLabel(container, labelColor)
    -- NodeHelper:setLabelOneByOne(container,"mLevelNum1","mTempLevel",3)
    -- NodeHelper:setLabelOneByOne(container,"mNextLevelNum1","mTempNextLevel",3)
end

-----------------------------------------------
-- SEUpgradePageBaseÒ³ÃæÖÐµÄÊÂ¼þ´¦Àí
----------------------------------------------
function SEUpgradePageBase.onFunctionEx(eventName, container)
    if string.sub(eventName, 1, 17) == "onOneMaterialBtn0" then
        local index = tonumber(string.sub(eventName, 18, -1))
        SEUpgradePageBase:onSelectItem(container, index)
    elseif string.sub(eventName, 1, 17) == "onTwoMaterialBtn0" then
        local index = tonumber(string.sub(eventName, 18, -1))
        SEUpgradePageBase:onSelectItem(container, index)
    elseif string.sub(eventName, 1, 19) == "onThreeMaterialBtn0" then
        local index = tonumber(string.sub(eventName, 20, -1))
        SEUpgradePageBase:onSelectItem(container, index)
    elseif eventName == "onUpgrade" then
        SEUpgradePageBase:onUpgrade(container, 1)
    elseif eventName == "onUpgradeTen" then
        SEUpgradePageBase:onUpgrade(container, 10)
    end
end

function SEUpgradePageBase:onEnter(container)
    container:registerPacket(HP_pb.SKILL_LEVELUP_S)

    NodeHelper:initScrollView(container, "mContent", 3);
    self:refreshPage(container)
    self:rebuildAllItem(container)
end


function SEUpgradePageBase:onExecute(container)

end

function SEUpgradePageBase:onExit(container)
    container:removePacket(HP_pb.SKILL_LEVELUP_S)

    NodeHelper:deleteScrollView(container);
    SelectIndex = 0
end
----------------------------------------------------------------

function SEUpgradePageBase:refreshPage(container)
    local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    local tempLevel = SEManager:getTempLevel(SkillItemId)
    -- local skillTempInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId , level)
    -- local nextTempInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId,level+1)
    level = SEManager:getOriginalLevelByItemId(SkillItemId)
    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)
    local exp = SEManager:getSkillExpByItemId(SkillItemId)
    local labelStr = { }
    local expline = ""
    -- ¾­ÑéÌõ
    local scale = 1
    if nextInfo ~= nil and nextInfo.exp ~= 0 then
        scale = exp / nextInfo.exp
        scale = math.min(1, scale)
        expline = exp .. "/" .. nextInfo.exp
    else
        local maxStr = common:getLanguageString("@SESkillFullLevel")
        expline = maxStr or ""
    end


    local expBar = container:getVarScale9Sprite("mVipExp")
    if expBar ~= nil then
        expBar:setScaleX(scale)
    end
    labelStr.mExperienceNum = expline
    NodeHelper:setStringForLabel(container, labelStr)
    -- ¸üÐÂ°´Å¥ÎÄ±¾
    -- local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    if level == 0 then
        NodeHelper:setStringForLabel(container, { mIgnoreAll = common:getLanguageString("@SELearn") })
    else
        NodeHelper:setStringForLabel(container, { mIgnoreAll = common:getLanguageString("@SEUpgrade") })
    end

    -- Èç¹ûÊÇÌæ»»¸ü»»±êÌâ
    if skillInfo.type == UpgradeType.Replace then
        local lb2Str = {
            mTitle = common:getLanguageString("@SEReplaceTitle")
        };
        NodeHelper:setStringForLabel(container, lb2Str);

    end



    self:refreshCostItem(container)
end

function SEUpgradePageBase:rebuildAllItem(container)
    NodeHelper:clearScrollView(container);
    local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    local tempLevel = SEManager:getTempLevel(SkillItemId)
    level = SEManager:getOriginalLevelByItemId(SkillItemId)
    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    if skillInfo.type == UpgradeType.Attribute then
        NodeHelper:buildScrollView(container, 1, SEUpgradeItem2.ccbiFile, SEUpgradeItem2.onFunction)
    elseif skillInfo.type == UpgradeType.Replace then
        NodeHelper:buildScrollView(container, 1, SEUpgradeItem2.ccbiFile, SEUpgradeItem2.onFunction)
    elseif skillInfo.type == UpgradeType.NewSkill then
        -- ÐÂ¼¼ÄÜÔ¤ÁôÎ»ÖÃ
    end
end

function SEUpgradePageBase:refreshCostItem(container)
    local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    local tempLevel = SEManager:getTempLevel(SkillItemId)
    level = SEManager:getOriginalLevelByItemId(SkillItemId)

    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)

    local lb2Str = { };
    local sprite2Img = { };
    local menu2Quality = { };
    -- Ìî³äµÀ¾ßÐÅÏ¢

    local CostItems = nil
    -- skillInfo.costItem
    if nextInfo then
        CostItems = nextInfo.costItem
    else
        CostItems = skillInfo.costItem
    end

    local size = #CostItems

    if size > #ItemLabelName then
        CCLuaLog("SEUpgradePageBase:refreshCostItem ERROR:skillEnhance.txt not correct!")
        return
    end

    for i = 1, #ItemLabelName do
        NodeHelper:setNodesVisible(container, {
            ["mSkillNode" .. i] = size == i
        } )
    end

    for i = 1, size do
        local item = CostItems[i]
        local UserItemManager = require("Item.UserItemManager")
        local ResManagerForLua = require("ResManagerForLua")
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(item.type, item.id, 1);
        local itemInfo = UserItemManager:getUserItemByItemId(item.id)
        local count = itemInfo and itemInfo.count or 0
        if resInfo ~= nil then
            sprite2Img[ItemLabelName[size].pic .. i] = resInfo.icon;
            lb2Str[ItemLabelName[size].num .. i] = "x" .. count;
            lb2Str[ItemLabelName[size].name .. i] = resInfo.name;
            menu2Quality[ItemLabelName[size].btn .. i] = resInfo.quality;
            if SelectIndex == 0 and count > 0 then
                SelectIndex = i
            end
        end
    end

    if SelectIndex == 0 or SelectIndex > size then
        SelectIndex = 1
    end

    -- Ë¢ÐÂÑ¡Ôñ¿ò
    self:refreshSelectEffect(container)

    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setQualityFrames(container, menu2Quality);
end
-- Ë¢ÐÂÑ¡Ôñ¿ò
function SEUpgradePageBase:refreshSelectEffect(container)
    local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    local tempLevel = SEManager:getTempLevel(SkillItemId)
    level = SEManager:getOriginalLevelByItemId(SkillItemId)

    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)
    local nodeVisible = { }

    local CostItems = nil
    -- skillInfo.costItem
    if nextInfo then
        CostItems = nextInfo.costItem
    else
        CostItems = skillInfo.costItem
    end
    local size = #CostItems
    for i = 1, size do
        if ItemLabelName[size] ~= nil then
            nodeVisible[ItemLabelName[size].selected .. i] = SelectIndex == i
            local selectSprite = container:getVarSprite(ItemLabelName[size].selected .. i)
            if selectSprite then
                selectSprite:setScale(1)
                local action1 = CCScaleTo:create(0.3, 1.05)
                local action2 = CCScaleTo:create(0.3, 1)
                if SelectIndex == i then
                    selectSprite:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(action1, action2)))
                else
                    selectSprite:stopAllActions()
                end
            end

        end
    end
    -- Ë¢ÐÂ°´Å¥ÎÄ±¾
    NodeHelper:setStringForLabel(container, { mIgnoreTen = common:getLanguageString("@SEUpgradeTen") })
    local UserItemManager = require("Item.UserItemManager")
    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)
    local CostItems = nil
    -- skillInfo.costItem
    if nextInfo then
        CostItems = nextInfo.costItem
    else
        CostItems = skillInfo.costItem
    end
    local item = CostItems[SelectIndex]
    local itemInfo = UserItemManager:getUserItemByItemId(item.id)
    if itemInfo == nil or itemInfo.count < 10 then
        NodeHelper:setStringForLabel(container, { mIgnoreTen = common:getLanguageString("@SEUpgradeAll") })
    end
    --
    NodeHelper:setNodesVisible(container, nodeVisible)
end
----------------click event------------------------
function SEUpgradePageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function SEUpgradePageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_SKILLENHANCE)
end	

function SEUpgradePageBase:onSelectItem(container, index)
    if SelectIndex == index then
        self:showTip(container, index)
        return
    end
    SelectIndex = index
    self:refreshSelectEffect(container)
end

function SEUpgradePageBase:showTip(container, index)
    local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    local tempLevel = SEManager:getTempLevel(SkillItemId)
    level = SEManager:getOriginalLevelByItemId(SkillItemId)
    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    local CostItems = nil
    -- skillInfo.costItem

    local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)
    if nextInfo then
        CostItems = nextInfo.costItem
    else
        CostItems = skillInfo.costItem
    end

    local item = CostItems[index]
    local size = #CostItems
    if ItemLabelName[size] == nil then
        CCLuaLog("SEUpgradePageBase:showTip ERROR:skillEnhance.txt not correct!")
        return
    end
    local node = container:getVarNode(ItemLabelName[size].btn .. index)
    if item ~= nil and node ~= nil then
        local cfg = {
            type = item.type,
            itemId = item.id
        }
        if cfg.type ~= nil and cfg.itemId ~= nil then
            GameUtil:showTip(node, cfg)
        end
    end

end

function SEUpgradePageBase:onUpgrade(container, count)
    local UserItemManager = require("Item.UserItemManager")
    local ConfigManager = require("ConfigManager")
    local level = SEManager:getSkillLevelInfoByItemId(SkillItemId)
    local tempLevel = SEManager:getTempLevel(SkillItemId)
    level = SEManager:getOriginalLevelByItemId(SkillItemId)
    local skillInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level)
    local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)

    local UserInfo = require("PlayerInfo.UserInfo")
    local CostItems = nil
    -- skillInfo.costItem
    if nextInfo then
        CostItems = nextInfo.costItem
    else
        CostItems = skillInfo.costItem
    end
    local item = CostItems[SelectIndex]
    local itemInfo = UserItemManager:getUserItemByItemId(item.id)
    local resInfo = ConfigManager.getItemCfg()[item.id];
    -- ÊÇ·ñ´ïµ½×î¸ßµÈ¼¶
    local nextInfo = SEManager:getSkillCfgInfoByItemId(SkillItemId, level + 1)
    if nextInfo == nil or(level + 1) > SEManager:getConfigDataByKey("SEMaxUpLevel") then
        MessageBoxPage:Msg_Box_Lan("@SEMaxLevelLimit");
        return
    end
    -- µÈ¼¶²»×ã
    -- if UserInfo.roleInfo.level<skillInfo.openLevel then
    if UserInfo.roleInfo.level < nextInfo.openLevel then
        MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@SELevelNotEnough", nextInfo.openLevel));
        return
    end
    -- ×¨¾«²»×ã
    -- if SEManager.SELevel[Profession]<skillInfo.seLevel then
    if SEManager.SELevel[Profession] < nextInfo.seLevel then
        MessageBoxPage:Msg_Box_Lan("@SESkillLevelNotEnough");
        return
    end
    -- µÀ¾ß²»×ã
    if itemInfo == nil or itemInfo.count <= 0 then
        MessageBoxPage:Msg_Box_Lan("@SEItemNotEnough");
        return
    end
    -- ÅäÖÃ±íÅÐ¶ÏÊÇ·ñ´íÎó
    if resInfo == nil then
        CCLuaLog("SEUpgradePageBase:onUpgrade,item cfg not find:Item.txt is error!")
        return
    end
    -- È·¶¨Ê¹ÓÃµÀ¾ßÊýÁ¿
    count = math.min(count, itemInfo.count)
    local exp = SEManager:getSkillExpByItemId(SkillItemId)
    -- local maxCount = math.ceil((skillInfo.exp - exp)/resInfo.skillExp)
    local maxCount = math.ceil((nextInfo.exp - exp) / resInfo.skillExp)
    -- ÊÇ·ñÊÇÌæ»»¼¼ÄÜ£¬¸øÍæ¼ÒÌáÊ¾
    if skillInfo.type == UpgradeType.Replace and count >= maxCount then
        local title = common:getLanguageString("@SEReplaceTitle")
        local message = common:getLanguageString("@SEReplaceMsg", nextInfo.name, skillInfo.name)
        PageManager.showConfirm(title, message, function(isSure)
            if isSure then
                -- ÔÙÅÐ¶ÏÊ¹ÓÃµÀ¾ßÊýÁ¿ÏÞÖÆ
                if count > maxCount then
                    count = maxCount
                    local title = common:getLanguageString("@SEUpgradeTitle")
                    local message = common:getLanguageString("@SELimitCountMsg", maxCount, maxCount)
                    local array = CCArray:create();
                    array:addObject(CCDelayTime:create(0.2));
                    local functionAction = CCCallFunc:create( function()
                        PageManager.showConfirm(title, message,
                        function(isSure)
                            if isSure then
                                -- Âú×ãÌõ¼þ£¬·¢ËÍÐ­Òé
                                local SkillEnhance_pb = require("SkillEnhance_pb")
                                local msg = SkillEnhance_pb.HPSkillLevelup()
                                msg.skillId = SkillItemId
                                msg.itemId = item.id
                                msg.itemCount = count
                                common:sendPacket(HP_pb.SKILL_LEVELUP_C, msg);
                            end
                        end )
                    end )
                    array:addObject(functionAction);
                    local seq = CCSequence:create(array);
                    container:runAction(seq)
                    return
                end
                -- Âú×ãÌõ¼þ£¬·¢ËÍÐ­Òé
                local SkillEnhance_pb = require("SkillEnhance_pb")
                local msg = SkillEnhance_pb.HPSkillLevelup()
                msg.skillId = SkillItemId
                msg.itemId = item.id
                msg.itemCount = count
                common:sendPacket(HP_pb.SKILL_LEVELUP_C, msg);
            end
        end );
        return
    end
    -- ÅÐ¶ÏÊÇ·ñÔ½¼¶,ÏÈÅÐ¶ÏÏÂÒ»¼¶ÊÇ·ñÄÜÊ¹ÓÃ¸ÃÎïÆ·Éý¼¶£¬ÔÙÅÐ¶ÏÉý¼¶ÊýÁ¿ÊÇ·ñ³¬±ê
    if count > maxCount then
        count = maxCount
        local title = common:getLanguageString("@SEUpgradeTitle")
        local message = common:getLanguageString("@SELimitCountMsg", maxCount, maxCount)
        PageManager.showConfirm(title, message, function(isSure)
            if isSure then
                -- Âú×ãÌõ¼þ£¬·¢ËÍÐ­Òé
                local SkillEnhance_pb = require("SkillEnhance_pb")
                local msg = SkillEnhance_pb.HPSkillLevelup()
                msg.skillId = SkillItemId
                msg.itemId = item.id
                msg.itemCount = count
                common:sendPacket(HP_pb.SKILL_LEVELUP_C, msg);
            end
        end );
        return
    end
    -- Âú×ãÌõ¼þ£¬·¢ËÍÐ­Òé
    local SkillEnhance_pb = require("SkillEnhance_pb")
    local msg = SkillEnhance_pb.HPSkillLevelup()
    msg.skillId = SkillItemId
    msg.itemId = item.id
    msg.itemCount = count
    common:sendPacket(HP_pb.SKILL_LEVELUP_C, msg);
end


------------------------Packet-------------------------------------------
function SEUpgradePageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    local SkillEnhance_pb = require("SkillEnhance_pb")

    if opcode == HP_pb.SKILL_LEVELUP_S then
        local msg = SkillEnhance_pb.HPSkillLevelupRet()
        msg:ParseFromString(msgBuff)

        if msg.isLevelup then
            PageManager.refreshPage("SEMainPage")
            SEManager.SELevel[Profession] = SEManager.SELevel[Profession] + 1
            self:refreshPage(container)
            self:rebuildAllItem(container)
        else
            self:refreshPage(container)
        end
    end
end

-------------------------------------------------------------------------
function SEUpgradePage_ShowSEUpgradeByItemId(skillId, profession)
    Profession = profession
    SkillItemId = skillId
    PageManager.pushPage("SEUpgradePage")
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local SEUpgradePage = CommonPage.newSub(SEUpgradePageBase, thisPageName, option, SEUpgradePageBase.onFunctionEx);