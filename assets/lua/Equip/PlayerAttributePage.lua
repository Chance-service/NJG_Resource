
----------------------------------------------------------------------------------
local Const_pb = require("Const_pb")
-- local UserInfo     = require("PlayerInfo.UserInfo")
local PBHelper = require("PBHelper")
local thisPageName = "PlayerAttributePage"
-- local GameConfig   = require("GameConfig") 
local NodeHelper = require("NodeHelper")
local HelpConfg = { }
local option = {
    ccbiFile = "AttributeDetailPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose"
    },
    opcode = opcodes
}

local PlayerAttributePage = { }
local AttributeClassifyContent = { }-- 基础属性，战斗属性，特殊属性
AttributeClassifyContent._attributeType = {
    FIGHT_ATTRIBUTE = 1,
    BASIC_ATTRIBUTE = 2,
}
AttributeClassifyContent._attributeInfo = {
    [AttributeClassifyContent._attributeType.BASIC_ATTRIBUTE] =
    {
        -- 基础属性
        ccbi = "AttributeBaseContent.ccbi",
        isHaveScrollView = false,
        -- 是否存在滚动条，exit时 要释放
        container = nil--
    },
    [AttributeClassifyContent._attributeType.FIGHT_ATTRIBUTE] =
    {
        -- 战斗属性
        ccbi = "AttributeBattleSingleContent.ccbi",
        isHaveScrollView = true,
        -- 是否存在滚动条，exit时 要释放
        container = nil
    }
}
local _curRoleInfo = nil
--------------------------------------------------------------

local function getBasicAttr(container)
    local TextMap = {
    }
    local basicAttrs = {
        [Const_pb.STRENGHT] = {  Const_pb.PHYDEF },
        [Const_pb.INTELLECT] = { Const_pb.MAGDEF },
        [Const_pb.AGILITY] = { Const_pb.DODGE },      
        [Const_pb.STAMINA] = { Const_pb.HP },
    }
    local prof2MainAttr = {
        [1] = Const_pb.STRENGHT,
        [2] = Const_pb.AGILITY,
        [3] = Const_pb.INTELLECT,
        [Const_pb.WARRIOR] = Const_pb.STRENGHT,
        [Const_pb.MAGICIAN] = Const_pb.INTELLECT,
        [Const_pb.ACOLYTE] = Const_pb.INTELLECT,
        [Const_pb.THIEF] = Const_pb.AGILITY,
        [Const_pb.ARCHER] = Const_pb.AGILITY,
    }
    local linkInfo = {
        [1] = "mW_",
        [2] = "mH_",
        [3] = "mM_",
        [Const_pb.WARRIOR] = "mW_",
        [Const_pb.MAGICIAN] = "mM_",
        [Const_pb.ACOLYTE] = "mM_",
        [Const_pb.THIEF] = "mH_",
        [Const_pb.ARCHER] = "mH_",
    }
   --NodeHelper:setNodesVisible(container, {
   --    mRole1 = _curRoleInfo.prof == 1 or _curRoleInfo.prof == Const_pb.WARRIOR,
   --    mRole2 = _curRoleInfo.prof == 2 or _curRoleInfo.prof == Const_pb.THIEF or _curRoleInfo.prof == Const_pb.ARCHER,
   --    mRole3 = _curRoleInfo.prof == 3 or _curRoleInfo.prof == Const_pb.MAGICIAN or _curRoleInfo.prof == Const_pb.ACOLYTE,
   --} )

    local tb = {
        FreeTypeConfig[24].content,
    }
    local mainAttrId = prof2MainAttr[_curRoleInfo.prof]
    local linkInfoItem = "mW_"
    local contentIdBase = 26
    for key, valuse in ipairs(basicAttrs) do
        
        local val = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, key)
        -- local addVal = PBHelper:getAttrById(_curRoleInfo.attribute.baptizeAttr, key) --加上佣兵洗练属性
        -- val = val + addVal
        TextMap[linkInfoItem .. key] = val
        if key == mainAttrId then
            local minRatio, maxRatio = 0.5, 1.0
            if key == Const_pb.INTELLECT then
                minRatio, maxRatio = 0.5, 1.0
            end
            -- TextMap[linkInfoItem .. "103"] = common:getLanguageString("@Basicattr_103", math.floor(val * minRatio))
            -- TextMap[linkInfoItem .. "104"] = common:getLanguageString("@Basicattr_104", math.floor(val * maxRatio))
        end
        
        if key == Const_pb.STRENGHT then
            TextMap[linkInfoItem .. valuse[1]] = common:getLanguageString("@Basicattr_" .. valuse[1], val)               
            --TextMap[linkInfoItem .. valuse[2]] = common:getLanguageString("@Basicattr_" .. valuse[2], math.floor(0.2 * val))
        elseif key == Const_pb.AGILITY then
            TextMap[linkInfoItem .. valuse[1]] = common:getLanguageString("@Basicattr_" .. valuse[1], math.floor(val * 0.6))               
            --TextMap[linkInfoItem .. valuse[2]] = common:getLanguageString("@Basicattr_" .. valuse[2], math.floor(0.5 * val))
        elseif key == Const_pb.INTELLECT then
            TextMap[linkInfoItem .. valuse[1]] = common:getLanguageString("@Basicattr_" .. valuse[1], val)
            -- TextMap[linkInfoItem .. valuse[2]] = common:getLanguageString("@Basicattr_" .. valuse[2], math.floor(math.sqrt(val) * 0.5))               
        elseif key == Const_pb.STAMINA then
            TextMap[linkInfoItem .. valuse[1]] = common:getLanguageString("@Basicattr_" .. valuse[1], val * 10)               
            --TextMap[linkInfoItem .. valuse[2]] = common:getLanguageString("@Basicattr_" .. valuse[2], math.floor(val * 0.2))
        end
        NodeHelper:setSpriteImage(container, { ["BasicIcon"..key] = "attri_" .. key .. ".png"})
    end
    NodeHelper:setStringForLabel(container, TextMap)


    --NodeHelper:setNodesVisible(container, { linkInfoItem103 = false })
   -- NodeHelper:setNodesVisible(container, { linkInfoItem104 = false })
end

local function getFightAttr()

 local function getGodlyAttrString(id, val, fmt)
      if val ~= 0 then
      local fmt = fmt or "%.1f%%"
      -- multi % for gsub()
      val = string.format(fmt, val / 100)
      end
        return val
      end
    -- 1 key 对应的values table[2]计算的百分比加成
    -- 2 table[2]计算的百分比 和 key 对应的属性计算效果
    -- 3 显示key对应的属性效果
    local fightAttrs = {

        [Const_pb.BUFF_AVOID_CONTROL]= { 6 },
        [Const_pb.BUFF_CRITICAL_DAMAGE] = { 4 },

        [Const_pb.CRITICAL] = { 3 },
        -- 暴击
        [Const_pb.BUFF_MAGDEF_PENETRATE] = { 3 },
        -- 魔抗穿透
        [Const_pb.BUFF_PHYDEF_PENETRATE] = { 3 },
        -- 物理穿透
        [Const_pb.HIT] = { 3 },
        -- 命中
        [Const_pb.DODGE] = { 3 },
        -- 闪避 
        [Const_pb.MAGDEF] = { 2, Const_pb.BUFF_MAGDEF_ADD },
        -- 法防
        [Const_pb.PHYDEF] = { 2, Const_pb.BUFF_PHYDEF_ADD },
        -- 物防
        [Const_pb.HP] = { 1, Const_pb.BUFF_MAX_HP },
        -- 101
         [Const_pb.MAGIC_attr] ={ 5 },
        --魔攻
        [Const_pb.ATTACK_attr] ={ 5 },
        --物攻
        [Const_pb.MP] = { 0 },
        -- 102
        [Const_pb.MINDMG] = { 1, Const_pb.BUFF_SKILL_DAMAGE_ADD },
        -- 103
        [Const_pb.MAXDMG] = { 1, Const_pb.BUFF_SKILL_DAMAGE_ADD },
        -- 104
        [Const_pb.ARMOR] = { 2, Const_pb.BUFF_ARMOR_ADD },
        -- 护甲   -- 105      
        [Const_pb.BUFF_AVOID_ARMOR] = { 3 },
        -- 护甲穿透
        [Const_pb.RESILIENCE] = { 3 },-- 强韧
        

    }
    local showSort = {
         
        Const_pb.BUFF_AVOID_CONTROL,
        Const_pb.BUFF_CRITICAL_DAMAGE,
        --Const_pb.BUFF_AVOID_ARMOR,
        Const_pb.BUFF_PHYDEF_PENETRATE,
        Const_pb.BUFF_MAGDEF_PENETRATE,
        Const_pb.CRITICAL,
        Const_pb.RESILIENCE,
        Const_pb.HIT,
        Const_pb.DODGE,
        Const_pb.PHYDEF,
        Const_pb.MAGDEF,
        Const_pb.ATTACK_attr,
        Const_pb.MAGIC_attr,
       -- Const_pb.BUFF_AVOID_ARMOR,
       -- Const_pb.ARMOR,
       -- Const_pb.MAXDMG,
       -- Const_pb.MINDMG,
       -- Const_pb.MP,
       -- Const_pb.HP
    }
    local TextMap = { }
    local tb = {
        FreeTypeConfig[25].content
    }
    for i = 1, #showSort do
        local key = showSort[i]
        local values = fightAttrs[showSort[i]]
        local curText = { }
        curText[1] = common:getLanguageString("@Combatattr_" .. key)
        local val = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, key)
        curText[2] = val
        if values[1] == 1 then
            local mapval = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, values[2])
            local valStr = EquipManager:getGodlyAttrString(values[2], mapval, "%.1f%%")
            if valStr == 0 then
                valStr = "0.0%"
            end
            curText[3] = "(" .. common:getLanguageString("@Combatattr_des_" .. key, valStr) .. ")"
        elseif values[1] == 2 then
            local mapval = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, values[2])
            local valStr = EquipManager:getGodlyAttrString(values[2], mapval, "%.1f%%")
            if valStr == 0 then
                valStr = "0.0%"
            end
            local valStr2 = EquipManager:getBattleAttrEffect(key, val, _curRoleInfo.level)
            curText[3] = "(" ..valStr2 .. "%)"--common:getLanguageString("@Combatattr_des_" .. key, valStr, valStr2)
            curText[4] = key
        elseif values[1] == 3 then
            local valStr = EquipManager:getBattleAttrEffect(key, val, _curRoleInfo.level)       
            if valStr == 0.0 then
               valStr = "0.0%"
            end
            curText[3] = "(" ..valStr .. "%)"
            curText[4] = key
        elseif values[1] == 4 then
            curText[1] = common:getLanguageString("@Specialattr_" .. key)
            local valStr = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, key)
            if key == Const_pb.BUFF_CRITICAL_DAMAGE or key == Const_pb.BUFF_MAGE then
                -- 物理暴击伤害 和 法术暴击伤害累加15000   15000为基础暴击伤害
                curText[2] = (valStr + 100) .. "%"
                valStr = valStr + 100
            end
            if valStr == 0 then
                valStr = "0.0%"
            else
                valStr = getGodlyAttrString(key, valStr, "%.1f%%")
            end
            curText[3] = nil
            curText[4] = key
        elseif values[1] == 5 then
            local valStr = EquipManager:getBattleAttrEffect(key, val, _curRoleInfo.level)
            curText[3] = nil
            curText[4] = key
        elseif values[1] == 6 then
            curText[1] = common:getLanguageString("@Specialattr_" .. key)
            local valStr = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, key) .. "%"
            --valStr = getGodlyAttrString(key, valStr, "%.1f%%")
            --if valStr == 0 then
            --valStr = "0.0%"
            --end
            curText[2] = valStr
            curText[3] = nil
            curText[4] = key
        end
        table.insert(TextMap, curText) 
    end
    return TextMap
end

local function getSpecialAttr()
    local function getGodlyAttrString(id, val, fmt)
        if val ~= 0 then
            local fmt = fmt or "%.1f%%"
            -- multi % for gsub()
            val = string.format(fmt, val / 100)
        end
        return val
    end
    local specalAttributeId = { }
    if _curRoleInfo.type == Const_pb.MAIN_ROLE then
        specalAttributeId = {
            Const_pb.BUFF_SUCK_BLOOD,
            Const_pb.BUFF_REVERSE_DAMAGE,
            Const_pb.BUFF_SUCK_BLOOD,
            Const_pb.BUFF_CRITICAL_DAMAGE,
            Const_pb.BUFF_MAGE,
            Const_pb.BUFF_EXP_DROP,
            Const_pb.BUFF_COIN_DROP,
            Const_pb.BUFF_EQUIP_DROP,
            -- 状态异常属性
            Const_pb.BUFF_AVOID_CONTROL
        }
    else
        -- 佣兵比主角少几个属性
        specalAttributeId = {
            Const_pb.BUFF_SUCK_BLOOD,
            Const_pb.BUFF_REVERSE_DAMAGE,
            Const_pb.BUFF_SUCK_BLOOD,
            Const_pb.BUFF_CRITICAL_DAMAGE,
            Const_pb.BUFF_MAGE,
            -- 状态异常属性
            Const_pb.BUFF_AVOID_CONTROL
        }
    end
    specalAttributeId = common:reverseArray(specalAttributeId, #specalAttributeId)
    local TextMap = { }
    for _, attrId in pairs(specalAttributeId) do
        local curText = { }
        curText[1] = common:getLanguageString("@Specialattr_" .. attrId)
        local val = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, attrId)
        if attrId == Const_pb.BUFF_CRITICAL_DAMAGE or attrId == Const_pb.BUFF_MAGE then
            -- 物理暴击伤害 和 法术暴击伤害累加15000   15000为基础暴击伤害
            local specalLevel = 0
            if _curRoleInfo.prof == Const_pb.MAGIC and attrId == Const_pb.BUFF_MAGE and _curRoleInfo.type == Const_pb.MAIN_ROLE then
                local SkillManager = require("Skill.SkillManager")
                local SEManager = require("Skill.SEManager")
                local StaticSkillCfg = SEManager:getSEStaticSkillByProfession(_curRoleInfo.prof)
                specalLevel = _curRoleInfo.skillSpecializeLevel or 0
                -- specalLevel = SkillManager:getSpecalSkillLevelByProfession( _curRoleInfo.itemId)
                if specalLevel and specalLevel > 0 then
                    specalLevel =(specalLevel * StaticSkillCfg.addAttr1) + StaticSkillCfg.baseAttr1
                    specalLevel = specalLevel * 100
                    -- 技能专精等级*成长 + 基础
                end
            end
            val = val + 15000 + specalLevel
        end
        local valStr = getGodlyAttrString(attrId, val, "%.1f%%")
        if valStr == 0 then
            valStr = "0.0%"
        end
        curText[2] = valStr
        table.insert(TextMap, curText)
    end
    return TextMap
end

local function getElementAttr()
    local elementAttrs = {
        Const_pb.ICE_ATTACK,
        Const_pb.FIRE_ATTACK,
        Const_pb.THUNDER_ATTACK,
        Const_pb.ICE_DEFENCE,
        Const_pb.FIRE_DEFENCE,
        Const_pb.THUNDER_DENFENCE
    }
    local elementAttrsRatio = {
        Const_pb.ICE_ATTACK_RATIO,
        Const_pb.FIRE_ATTACK_RATIO,
        Const_pb.THUNDER_ATTACK_RATIO,
        Const_pb.ICE_DEFENCE_RATIO,
        Const_pb.FIRE_DEFENCE_RATIO,
        Const_pb.THUNDER_DENFENCE_RATIO
    }
    local tb = {
        FreeTypeConfig[250].content
    }
    local contentIdBase = 250
    for i, attrId in pairs(elementAttrs) do
        local contentId = contentIdBase + i
        local val = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, attrId)
        if val ~= 0 then
            local str = FreeTypeConfig[contentId].content
            local valRaito = PBHelper:getAttrById(_curRoleInfo.attribute.attribute, elementAttrsRatio[i])
            if valRaito ~= 0 then
                local valRatioStr = "(+" ..(valRaito / 100) .. "%" .. ")"
                str = common:fill(str, val, valRatioStr)
            else
                str = common:fill(str, val, "")
            end
            table.insert(tb, str)
        end
    end
    return table.concat(tb, "<br/>")
end
-----------------------------------------------
-- PlayerAttributePage页面中的事件处理
----------------------------------------------
function PlayerAttributePage:onEnter(container)
    NodeHelper:initScrollView(container, "mContent", 3)
    container.mScrollView:setTouchEnabled(false)

    self:refreshPage(container)
end
function PlayerAttributePage:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildScrollView(container)
end
function PlayerAttributePage:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end
-- 基础属性
function PlayerAttributePage.showBasicAttribute(container)
    getBasicAttr(container)
end
function initChildScrollViewData(container, showInfos, varName)
    NodeHelper:initScrollView(container, varName, 10)
    container.mScrollView:setTouchEnabled(false)
    --------------------------------------------------------------------------------------------
    local fOneItemWidth = 0
    local fOneItemHeight = 0
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local currentPos = 0
    local size = #showInfos
    local oneLineCount = 0
    local scrollviewWidth = container.mScrollView:getViewSize().width
    for i = 1, size do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        if iCount < iMaxNode then
            local pItem = ScriptContentBase:create("AttributeBattleContent.ccbi")
            pItem.id = iCount

            ----------------------
            local nodesVisible = { }
            local strMap = { }
            local singleInfo = showInfos[i]
            for i = 1, 3 do
                if singleInfo[i] == nil then
                    nodesVisible["mAtt" .. i] = false
                else
                    nodesVisible["mAtt" .. i] = true
                    strMap["mAtt" .. i] = singleInfo[i]
                end
            end
            NodeHelper:setStringForLabel(pItem, strMap)
            NodeHelper:setNodesVisible(pItem, nodesVisible)
            --if showInfos[i][4] == 106 then  showInfos[i][4] = 105 end
            --if showInfos[i][4] == 111 then  showInfos[i][4] = 106 end
            --if showInfos[i][4] == 1010 then  showInfos[i][4] = 108 end
            NodeHelper:setSpriteImage(pItem, { FightIcon = "attri_" .. showInfos[i][4] .. ".png" })
            
            ----------------------

            fOneItemHeight = pItem:getContentSize().height
            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width
            end
            if oneLineCount == 0 then
                oneLineCount = math.floor(scrollviewWidth / fOneItemWidth)
            end
            local iCount2 = i - (size % oneLineCount)
            currentPos = currentPos + ((iCount < (size % oneLineCount)) and 0 or (iCount2 % oneLineCount == 1 and fOneItemHeight or 0))
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        pItemData.m_ptPosition = ccp((iCount % oneLineCount) * fOneItemWidth, currentPos)

        iCount = iCount + 1
    end
    local size = CCSizeMake(scrollviewWidth, currentPos + fOneItemHeight)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setViewSize(size)
    container.mScrollView:setContentOffset(ccp(0, 0))
    -- container.mScrollView:setContentOffset(ccp(fOneItemWidth * (-1), 0))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollView:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)

    --    local scale9Sprite1 = container:getVarScale9Sprite("mScale9Sprite1")
    --    local scale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
    --    setScale9SpriteSize(scale9Sprite1,currentPos - fOneItemHeight)
    --    setScale9SpriteSize(scale9Sprite2,currentPos - fOneItemHeight)


    --local scale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
    --setScale9SpriteSize(scale9Sprite, currentPos - fOneItemHeight)
    --
    --local scale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
    --setScale9SpriteSize(scale9Sprite2, currentPos - fOneItemHeight)

    NodeHelper:SetNodePostion(container, "mBaseNode", 0, currentPos - fOneItemHeight)
    return currentPos - fOneItemHeight
    --------------------------------------------------------------------------------------------
end
function setScale9SpriteSize(scale9Sprite, addNum)
    local oldSize = scale9Sprite:getContentSize()
    oldSize.height = oldSize.height + addNum
    scale9Sprite:setContentSize(oldSize)
end
-- 战斗属性
function PlayerAttributePage.showFightAttribute(container)
    -- container.mScrollView:setViewSize(CCSize(640, currentPos))
    local TEST = {
        [1] = { "HP1", "111", "XXXXX1" },
        [2] = { "HP2", "222" },
        [3] = { "HP3", "333", "XXXXX3" },
        [4] = { "HP4", "444" },
        [5] = { "HP5", "555", "XXXXX5" },
        [6] = { "HP6", "666", "XXXXX6" },
    }
    local showData = getFightAttr()
    local changeH = initChildScrollViewData(container, showData, "mContent1")
    NodeHelper:setNodesVisible(container, {
        mSpecialTitle = false,
        mBattleTitle = true,
    } )
    --local BattleTitle=container:getVarNode("mBattleTitle")
    --NodeHelper:setStringForTTFLabel(container, { mBattleTitle = "Combat Attributes" })
    --BattleTitle:setPositionY(BattleTitle:getPositionY() - 2)
    return changeH
end
-- 特殊属性
function PlayerAttributePage.showSpecialAttribute(container)
    local TEST = {
        [1] = { "MP1", "111" },
        [2] = { "MP2", "222" },
        [3] = { "MP3", "333", "555555" },
        [4] = { "MP4", "444" },
        [5] = { "MP5", "555" },
    }
    local showdata = getSpecialAttr()
    local changeH = initChildScrollViewData(container, showdata, "mContent1")
    NodeHelper:setNodesVisible(container, {
        mSpecialTitle = true,
        mBattleTitle = false,
    } )

    return changeH
end
-- 构建标签页
function PlayerAttributePage:buildScrollView(container)
    local fOneItemWidth = 0
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local currentPos = 0
    local interval = 0
    for i = 1, #AttributeClassifyContent._attributeInfo do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp(0, currentPos)

        if iCount < iMaxNode then
            ccbiFile = AttributeClassifyContent._attributeInfo[i].ccbi
            local pItem = ScriptContentBase:create(ccbiFile)
            -- pItem:release()
            pItem.id = iCount
            local changeSizeH = 0
            if i == AttributeClassifyContent._attributeType.BASIC_ATTRIBUTE then
                -- 基础属性
                PlayerAttributePage.showBasicAttribute(pItem)
            elseif i == AttributeClassifyContent._attributeType.FIGHT_ATTRIBUTE then
                -- 战斗属性
                changeSizeH = PlayerAttributePage.showFightAttribute(pItem)
            end

            local oldSize = pItem:getContentSize()
            oldSize.height = oldSize.height + changeSizeH
            pItem:setContentSize(oldSize)

            fOneItemHeight = pItem:getContentSize().height

            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width
            end
            currentPos = currentPos + fOneItemHeight
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
            AttributeClassifyContent._attributeInfo[i].container = pItem
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        iCount = iCount + 1
    end
    local size = CCSizeMake(fOneItemWidth, currentPos)
    container.mScrollView:setContentSize(size)
    local viewSizeHeight = container.mScrollView:getViewSize().height
    local scaleHeight = container.mScrollView:getScaleY()
    container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
    -- container.mScrollView:setContentOffset(ccp(fOneItemWidth * (-1), 0))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollView:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end
function PlayerAttributePage:onExit(container)
    for i = 1, #AttributeClassifyContent._attributeInfo do
        if AttributeClassifyContent._attributeInfo[i].isHaveScrollView then
            NodeHelper:deleteScrollView(AttributeClassifyContent._attributeInfo[i].container)
        end
    end
    NodeHelper:deleteScrollView(container)
end
----------------------------------------------------------------

function PlayerAttributePage:refreshPage(container)
    self:rebuildAllItem(container)
end

----------------click event------------------------
function PlayerAttributePage:onClose(container)
    PageManager.popPage(thisPageName)
end
function PlayerAttributePage:setRoleInfo(roleInfo)
    _curRoleInfo = roleInfo
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
PlayerAttributePage = CommonPage.newSub(PlayerAttributePage, thisPageName, option)
return PlayerAttributePage