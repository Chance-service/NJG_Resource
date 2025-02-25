local thisPageName = "BattleLogPage"
local NodeHelper = require("NodeHelper")
local pageManager = require("PageManager")
local common = require("common")
local CONST = require("Battle.NewBattleConst")
local UserMercenaryManager = require("UserMercenaryManager")
local EventDataMgr = require("Event001DataMgr")
require("Battle.NgBattleDataManager")

BattleLogPage = BattleLogPage or { }
local option = {
    ccbiFile = "BattleLogPage.ccbi",
    handlerMap =
    {
        onSelectAll = "onSelectAll",
        onClose = "onClose",
    }
}
for i = 1, 5 do
    option.handlerMap["onSelect" .. i] = "onSelect"
end
for i = 11, 15 do
    option.handlerMap["onSelect" .. i] = "onSelect"
end
local LogContent = {
    ccbiFile = "BattleLogContent.ccbi"
}
BattleLogPage.SelectData = {
    [1] = true, [2] = true, [3] = true, [4] = true, [5] = true,
    [11] = true, [12] = true, [13] = true, [14] = true, [15] = true,
}
BattleLogPage.selectAll = true

------------------------------------------------
function LogContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end
function LogContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    -- Time
    local mSec = self.log.time % 1000
    local sec = math.floor(self.log.time / 1000)
    NodeHelper:setStringForLabel(container, { mTime = string.format("%02d", sec) .. ":" .. string.format("%03d", mSec) })
    -- Log
    local htmlParent = container:getVarNode("mTxtNode")
    htmlParent:removeAllChildrenWithCleanup(true)
    local sizeNode = htmlParent:getParent()
    local freeTypeId = LogContent:getFreeTypeId(self.log)
    if not freeTypeId then
        return
    end
    
    local str = LogContent:fillString(freeTypeId, self.log)
    local htmlLabel = CCHTMLLabel:createWithString(str, CCSizeMake(sizeNode:getContentSize().width, sizeNode:getContentSize().height), "Barlow-SemiBold")
    htmlLabel:setPosition(ccp(0, htmlLabel:getContentSize().height * 0.5))
    htmlLabel:setAnchorPoint(ccp(0, 1))
    htmlParent:addChild(htmlLabel)
end

function LogContent:getFreeTypeId(log)
    local LOG_UTIL = require("Battle.NgBattleLogUtil")
    if log.action == LOG_UTIL.TestLogType.CAST_SKILL then
        if log.attackerIdx < 10 then
            return 999901
        elseif log.attackerIdx > 10 then
            return 999902
        end
    elseif log.action == LOG_UTIL.TestLogType.NORMAL_ATTACK then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999903
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999904
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999905
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999906
        end
    elseif log.action == LOG_UTIL.TestLogType.SKILL_ATTACK then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999907
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999908
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999909
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999910
        end
    elseif log.action == LOG_UTIL.TestLogType.BUFF_ATTACK then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999911
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999912
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999913
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999914
        end
    elseif log.action == LOG_UTIL.TestLogType.LEECH_HEALTH then
        if log.attackerIdx < 10 then
            return 999915
        elseif log.attackerIdx > 10 then
            return 999916
        end
    elseif log.action == LOG_UTIL.TestLogType.SKILL_HEALTH then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999917
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999918
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999919
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999920
        end
    elseif log.action == LOG_UTIL.TestLogType.BUFF_HEALTH then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999921
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999922
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999923
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999924
        end
    elseif log.action == LOG_UTIL.TestLogType.GAIN_BUFF then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999925
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999926
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999927
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999928
        end
    elseif log.action == LOG_UTIL.TestLogType.REMOVE_BUFF then
        if log.attackerIdx < 10 then
            return 999929
        elseif log.attackerIdx > 10 then
            return 999930
        end
    elseif log.action == LOG_UTIL.TestLogType.ADD_SHIELD then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999931
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999932
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999933
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999934
        end
    elseif log.action == LOG_UTIL.TestLogType.ATTACK_MISS then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999935
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999936
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999937
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999938
        end
    elseif log.action == LOG_UTIL.TestLogType.SKILL_MISS then
        if log.attackerIdx < 10 and log.targetIdx > 10 then
            return 999939
        elseif log.attackerIdx > 10 and log.targetIdx < 10 then
            return 999940
        elseif log.attackerIdx < 10 and log.targetIdx < 10 then
            return 999941
        elseif log.attackerIdx > 10 and log.targetIdx > 10 then
            return 999942
        end
    elseif log.action == LOG_UTIL.TestLogType.ATTACK_ADD_MP then
        if log.attackerIdx < 10 then
            return 999943
        elseif log.attackerIdx > 10 then
            return 999944
        end
    elseif log.action == LOG_UTIL.TestLogType.SKILL_ADD_MP then
        if log.attackerIdx < 10 then
            return 999945
        elseif log.attackerIdx > 10 then
            return 999946
        end
    elseif log.action == LOG_UTIL.TestLogType.BEATTACK_ADD_MP then
        if log.attackerIdx < 10 then
            return 999947
        elseif log.attackerIdx > 10 then
            return 999948
        end
    elseif log.action == LOG_UTIL.TestLogType.LOSE_MP then
        if log.attackerIdx < 10 then
            return 999949
        elseif log.attackerIdx > 10 then
            return 999950
        end
    elseif log.action == LOG_UTIL.TestLogType.DEAD then
        if log.attackerIdx < 10 then
            return 999954
        elseif log.attackerIdx > 10 then
            return 999955
        end
    elseif log.action == LOG_UTIL.TestLogType.CAST_ATTACK then
        if log.attackerIdx < 10 then
            return 999956
        elseif log.attackerIdx > 10 then
            return 999957
        end
    end
    return nil
end
function LogContent:fillString(id, log)
    local str = FreeTypeConfig[id].content
    if id >= 999901 and id <= 999902 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getSkillName(log.skillId))
    elseif id >= 999903 and id <= 999906 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getCharName(log.target, log.targetIdx), log.value) .. (log.cri and FreeTypeConfig[999951].content or "")
    elseif id >= 999907 and id <= 999910 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getSkillName(log.skillId), LogContent:getCharName(log.target, log.targetIdx), log.value) .. (log.cri and FreeTypeConfig[999951].content or "")
    elseif id >= 999911 and id <= 999914 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getBuffName(log.skillId), LogContent:getCharName(log.target, log.targetIdx), log.value)
    elseif id >= 999915 and id <= 999916 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), log.value)
    elseif id >= 999917 and id <= 999920 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getSkillName(log.skillId), LogContent:getCharName(log.target, log.targetIdx), log.value) .. (log.cri and FreeTypeConfig[999951].content or "")
    elseif id >= 999921 and id <= 999924 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getBuffName(log.skillId), LogContent:getCharName(log.target, log.targetIdx), log.value)
    elseif id >= 999925 and id <= 999928 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getCharName(log.target, log.targetIdx), LogContent:getBuffName(log.skillId))
    elseif id >= 999929 and id <= 999930 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getBuffName(log.skillId))
    elseif id >= 999931 and id <= 999934 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getCharName(log.target, log.targetIdx), log.value)
    elseif id >= 999935 and id <= 999938 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getCharName(log.target, log.targetIdx))
    elseif id >= 999939 and id <= 999942 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getSkillName(log.skillId), LogContent:getCharName(log.target, log.targetIdx))
    elseif id >= 999943 and id <= 999944 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), log.value)
    elseif id >= 999945 and id <= 999946 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), LogContent:getSkillName(log.skillId), log.value)
    elseif id >= 999947 and id <= 999948 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), log.value)
    elseif id >= 999949 and id <= 999950 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx), log.value)
    elseif id >= 999954 and id <= 999955 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx))
    elseif id >= 999956 and id <= 999957 then
        str = common:fill(str, LogContent:getCharName(log.attacker, log.attackerIdx))
    end
    return str
end
function LogContent:getCharName(char, idx)
    if not char then
        return ""
    end
    if char.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.HERO then
        return common:getLanguageString("@HeroName_" .. char.otherData[CONST.OTHER_DATA.ITEM_ID]) .. "[" .. idx .. "]"
    else
        --local cfg = ConfigManager.getNewMonsterCfg()[char.otherData[CONST.OTHER_DATA.ITEM_ID]]
        return char.otherData[CONST.OTHER_DATA.ITEM_ID] .. "[" .. idx .. "]"--common:getLanguageString(cfg.Name)
    end
end
function LogContent:getSkillName(id)
    if not id then
        return ""
    end
    local skillBaseId = math.floor(id / 10)
    if skillBaseId == 50010 then
        return skillBaseId
    else
        return common:getLanguageString("@Skill_Name_" .. skillBaseId)
    end
end
function LogContent:getBuffName(id)
    if not id then
        return ""
    end
    return common:getLanguageString("@Buff_" .. id)
end

function LogContent:onDetail(container)
    require("Battle.BattleLogDetailPage")
    BattleLogDetailPage_setData(self.log.attacker, self.log.target)
    PageManager.pushPage("BattleLogDetailPage")
end
------------------------------------------------

function BattleLogPage:onEnter(container)
    self:initUI(container)
    self:initSelect(container)
    self:initScroll(container)
end

function BattleLogPage:initUI(container)
    -- 標題名稱設定
    local mapId = NgBattleDataManager.battleMapId
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK or NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        local mapCfg = ConfigManager.getNewMapCfg()
        local chapter = mapCfg[mapId].Chapter
        local level = mapCfg[mapId].Level
        local txt = common:getLanguageString("@MapFlag" .. chapter) .. level
        NodeHelper:setStringForLabel(container, { mTitle = txt })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local cfg = ConfigManager:getMultiEliteCfg()
        NodeHelper:setStringForLabel(container, { mTitle = cfg[NgBattleDataManager.dungeonId].name })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        NodeHelper:setStringForLabel(container, { mTitle = NgBattleDataManager.arenaName })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local cfg = ConfigManager.getMultiElite2Cfg()
        NodeHelper:setStringForLabel(container, { mTitle = cfg[NgBattleDataManager.dungeonId].name })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local cfg = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG
        NodeHelper:setStringForLabel(container, { mTitle = cfg[NgBattleDataManager.dungeonId].StageName })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local cfg = ConfigManager.getTowerData()
        NodeHelper:setStringForLabel(container, { mTitle = cfg[NgBattleDataManager.dungeonId].StageName })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
    end
    -- 隊伍頭像設定
    local fList = NgBattleDataManager.battleMineCharacter
    local eList = NgBattleDataManager.battleEnemyCharacter
    for i = 1, 5 do
        local fData = fList[i]
        local eData = eList[i]
        if fData then
            local itemId = fData.otherData[CONST.OTHER_DATA.ITEM_ID]
            local roleType = fData.otherData[CONST.OTHER_DATA.CHARACTER_TYPE]
            local quality = 1
            local element = fData.battleData[CONST.BATTLE_DATA.ELEMENT]
            if roleType == CONST.CHARACTER_TYPE.HERO then
                local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(itemId)
                quality = (roleInfo.starLevel > 10 and 6) or (roleInfo.starLevel < 6 and 4) or 5
                NodeHelper:setSpriteImage(container, { ["mHeadIcon" .. fData.idx] = "UI/RoleIcon/Icon_" .. string.format("%02d", itemId) .. string.format("%03d", roleInfo.skinId) .. ".png" })
            elseif roleType == CONST.CHARACTER_TYPE.MONSTER or roleType == CONST.CHARACTER_TYPE.WORLDBOSS then
                local cfg = ConfigManager.getNewMonsterCfg()[itemId]
                NodeHelper:setSpriteImage(container, { ["mHeadIcon" .. fData.idx] = cfg.Icon })
            end
            NodeHelper:setSpriteImage(container, { ["mHeadFrame" .. fData.idx] = GameConfig.MercenaryQualityImage[quality],
                                                   ["mHeadBg" .. fData.idx] = NodeHelper:getImageBgByQuality(quality), 
                                                   ["mHeadElement" .. fData.idx] = string.format("Attributes_elemet_%02d.png", element) })
        end
        if eData then
            local itemId = eData.otherData[CONST.OTHER_DATA.ITEM_ID]
            local roleType = eData.otherData[CONST.OTHER_DATA.CHARACTER_TYPE]
            local quality = 1
            local element = eData.battleData[CONST.BATTLE_DATA.ELEMENT]
            if roleType == CONST.CHARACTER_TYPE.HERO then
                local skinId = eData.otherData[CONST.OTHER_DATA.SPINE_SKIN]
                NodeHelper:setSpriteImage(container, { ["mHeadIcon" .. eData.idx] = "UI/RoleIcon/Icon_" .. string.format("%02d", itemId) .. string.format("%03d", skinId) .. ".png" })
            elseif roleType == CONST.CHARACTER_TYPE.MONSTER or roleType == CONST.CHARACTER_TYPE.WORLDBOSS then
                local cfg = ConfigManager.getNewMonsterCfg()[itemId]
                NodeHelper:setSpriteImage(container, { ["mHeadIcon" .. eData.idx] = cfg.Icon })
            end
            NodeHelper:setSpriteImage(container, { ["mHeadFrame" .. eData.idx] = GameConfig.MercenaryQualityImage[quality],
                                                   ["mHeadBg" .. eData.idx] = NodeHelper:getImageBgByQuality(quality), 
                                                   ["mHeadElement" .. eData.idx] = string.format("Attributes_elemet_%02d.png", element) })
        end
    end
end

function BattleLogPage:initSelect(container)
    local isAll = true
    for k, v in pairs(BattleLogPage.SelectData) do
        NodeHelper:setNodesVisible(container, { ["mSelectImg" .. k] = v })
        if v == false then
            isAll = false
        end
    end
    BattleLogPage.selectAll = isAll
    NodeHelper:setNodesVisible(container, { ["mSelectImgAll"] = isAll })
end

function BattleLogPage:initScroll(container)
    container.mScrollView = container:getVarScrollView("mContent")
    container.mScrollView:removeAllCell()
    self:sort(NgBattleDataManager.battleTestLog)
    for i = 1, #NgBattleDataManager.battleTestLog do
        local attIdx = NgBattleDataManager.battleTestLog[i].attacker and NgBattleDataManager.battleTestLog[i].attackerIdx or 0
        local tarIdx = NgBattleDataManager.battleTestLog[i].target and NgBattleDataManager.battleTestLog[i].targetIdx or 0
        if BattleLogPage.SelectData[attIdx] or BattleLogPage.SelectData[tarIdx] then
            local cell = CCBFileCell:create()
            cell:setCCBFile(LogContent.ccbiFile)
            local handler = common:new({ id = i, log = NgBattleDataManager.battleTestLog[i] }, LogContent)
            cell:registerFunctionHandler(handler)
            container.mScrollView:addCell(cell)
        end
    end
    container.mScrollView:orderCCBFileCells()
end

function BattleLogPage:onSelect(container, eventName)
    local index = tonumber( string.sub(eventName, 9, -1) )
    BattleLogPage.SelectData[index] = not BattleLogPage.SelectData[index]
    self:initSelect(container)
    self:initScroll(container)
end

function BattleLogPage:onSelectAll(container)
    local selectAll = not BattleLogPage.selectAll
    for k, v in pairs(BattleLogPage.SelectData) do
        BattleLogPage.SelectData[k] = selectAll
    end
    self:initSelect(container)
    self:initScroll(container)
end

function BattleLogPage:resetSelectData(container)
    BattleLogPage.selectAll = true
    for k, v in pairs(BattleLogPage.SelectData) do
        BattleLogPage.SelectData[k] = true
    end
end

function BattleLogPage:onClose(container)
    self:resetSelectData(container)
    PageManager.popPage(thisPageName)
end

function BattleLogPage:sort(tb)
    table.sort(tb, function(info1, info2)
        if info1 == nil or info2 == nil then
            return false
        end
        if info1.time ~= info2.time then
            return info1.time < info2.time
        elseif info1.action ~= info2.action then
            return info1.action < info2.action
        elseif info1.idx ~= info2.idx then
            return info1.idx < info2.idx
        end
        return false
    end )
end

local CommonPage = require("CommonPage")
BattleLogPage = CommonPage.newSub(BattleLogPage, thisPageName, option)

return BattleLogPage