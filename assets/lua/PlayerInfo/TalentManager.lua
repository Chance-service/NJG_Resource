

local TalentManager = {}
local HP_pb = require("HP_pb")
local Talent_pb = require("Talent_pb")
local TalentCfg = ConfigManager.getTalentCfg()
local Const_pb = require("Const_pb")

TalentManager.ElementTalentInfo = {}
TalentManager.curAttrId = 0

local ElementType = {
    ICE = 1,
    FIRE = 2,
    THUNDER = 3
}

local AttrType = {
    DEFENSE = 1,
    ATTACK = 2
}

function TalentManager:getTalentInfo(attrId)
    for i = 1 , 6 do 
        if TalentManager.ElementTalentInfo[i].attrId == attrId then
            return TalentManager.ElementTalentInfo[i]
        end
    end
end

-- 按照阶数，级数排序
function TalentManager.sortByStageAndLevel(tal1, tal2)
    if tal1 == nil then return true end
    if tal2 == nil then return false end

--    if tal1.attrStage ~= tal2.attrStage then
--        return tal1.attrStage > tal2.attrStage
--    else
--        if tal1.attrLevel ~= tal2.attrLevel then
--            return tal1.attrLevel > tal2.attrLevel
--        else
--            return tal1.attrId < tal2.attrId
--        end
--    end
    return tal1.attrId < tal2.attrId
end

function TalentManager:requestBasicInfo()
    common:sendEmptyPacket(HP_pb.TALENT_ELEMENT_INFO_C, true)
end

-- 点亮操作
function TalentManager:upgradeTalent(attrId, curLevel, targetLevel)
    local msg = Talent_pb.HPUpgradeTalent()
    msg.attrId = attrId
    msg.curLevel = curLevel
    msg.targetLevel = targetLevel
    common:sendPacket(HP_pb.TALENT_UPGRAGE_TALENT_C, msg, true)
end

-- 清空属性
function TalentManager:clearTalent(attrId)
    local msg = Talent_pb:HPClearTalent()
    msg.attrId = attrId
    common:sendPacket(HP_pb.TALENT_ELEMENT_CLEAR_C, msg, true)
end

function TalentManager:receiveTalentInfo(msg)
    TalentManager.ElementTalentInfo = msg.elementTalent
    table.sort(TalentManager.ElementTalentInfo, TalentManager.sortByStageAndLevel)
    TalentManager.curAttrId = TalentManager.ElementTalentInfo[1].attrId
end 

-- 点亮回包
function TalentManager:receiveUpgradeTalent(msg)
    for i=1, #TalentManager.ElementTalentInfo do
        if TalentManager.ElementTalentInfo[i].attrId == msg.upgradeTalent.attrId then
            TalentManager.ElementTalentInfo[i] = msg.upgradeTalent
            table.sort(TalentManager.ElementTalentInfo, TalentManager.sortByStageAndLevel)
        end
    end
end

-- 清空属性回包
function TalentManager:receiveClearTalent(msg)
    for i=1, #TalentManager.ElementTalentInfo do
        if TalentManager.ElementTalentInfo[i].attrId == msg.upgradeTalent.attrId then
            TalentManager.ElementTalentInfo[i] = msg.upgradeTalent
            table.sort(TalentManager.ElementTalentInfo, TalentManager.sortByStageAndLevel)
        end
    end
end

----------------------------- cfg ----------------------------------
-- 根据阶数等级计算id，为了读表
function TalentManager:getIdForCfg(stage, level)
    local id  = (stage - 1) * 50 + level
    return id
end

-- 目标等级信息
function TalentManager:getUpgradeInfo(attrId, curLevel, targetLevel, stage)
    local info = {
        attrValue = 0,
        addCost = 0,
        levelLimit = 0,
        nAddCost = 0,
        nLevelLimit = 0,
    }
    local curId = curLevel --TalentManager:getIdForCfg(stage,curLevel)
    local targetId = targetLevel -- TalentManager:getIdForCfg(stage,targetLevel)

    if attrId == Const_pb.ICE_ATTACK then
        if targetId <= #TalentCfg then 
            info.attrValue  = common:getLanguageString("@TalentAttackText", TalentCfg[targetId].iceAttackNumTotal - TalentCfg[curId].iceAttackNumTotal)
            info.addCost    = common:getLanguageString("@TalentAddCost", TalentCfg[targetId].iceAttackCostTotal - TalentCfg[curId].iceAttackCostTotal)
            info.levelLimit = common:getLanguageString("@TalentAddLevelLimit", 1, targetLevel)
            info.nAddCost = TalentCfg[targetId].iceAttackCostTotal - TalentCfg[curId].iceAttackCostTotal
        end
        info.ElementType = ElementType.ICE
        info.AttrType   = AttrType.ATTACK
    elseif attrId == Const_pb.ICE_DEFENCE then
        if targetId <= #TalentCfg then
            info.attrValue  = common:getLanguageString("@TalentDefenseText", TalentCfg[targetId].iceDefenseNumTotal - TalentCfg[curId].iceDefenseNumTotal)
            info.addCost    = common:getLanguageString("@TalentAddCost", TalentCfg[targetId].iceDefenseCostTotal - TalentCfg[curId].iceDefenseCostTotal)
            info.levelLimit = common:getLanguageString("@TalentAddLevelLimit", 1, targetLevel)
            info.nAddCost = TalentCfg[targetId].iceDefenseCostTotal - TalentCfg[curId].iceDefenseCostTotal
        end
        info.ElementType = ElementType.ICE
        info.AttrType   = AttrType.DEFENSE
    elseif attrId == Const_pb.FIRE_ATTACK then
        if targetId <= #TalentCfg then
            info.attrValue  = common:getLanguageString("@TalentAttackText", TalentCfg[targetId].fireAttackNumTotal - TalentCfg[curId].fireAttackNumTotal)
            info.addCost    = common:getLanguageString("@TalentAddCost", TalentCfg[targetId].fireAttackCostTotal - TalentCfg[curId].fireAttackCostTotal)
            info.levelLimit = common:getLanguageString("@TalentAddLevelLimit", 1, targetLevel)
            info.nAddCost = TalentCfg[targetId].fireAttackCostTotal - TalentCfg[curId].fireAttackCostTotal
        end
        info.ElementType    = ElementType.FIRE
        info.AttrType   = AttrType.ATTACK
    elseif attrId == Const_pb.FIRE_DEFENCE then
        if targetId <= #TalentCfg then
            info.attrValue  = common:getLanguageString("@TalentDefenseText", TalentCfg[targetId].fireDefenseNumTotal - TalentCfg[curId].fireDefenseNumTotal)
            info.addCost    = common:getLanguageString("@TalentAddCost", TalentCfg[targetId].fireDefenseCostTotal - TalentCfg[curId].fireDefenseCostTotal)
            info.levelLimit = common:getLanguageString("@TalentAddLevelLimit", 1, targetLevel)
            info.nAddCost = TalentCfg[targetId].fireDefenseCostTotal - TalentCfg[curId].fireDefenseCostTotal
        end
        info.ElementType    = ElementType.FIRE
        info.AttrType   = AttrType.DEFENSE
    elseif attrId == Const_pb.THUNDER_ATTACK then
        if targetId <= #TalentCfg then
            info.attrValue  = common:getLanguageString("@TalentAttackText", TalentCfg[targetId].thunderAttackNumTotal - TalentCfg[curId].thunderAttackNumTotal)
            info.addCost    = common:getLanguageString("@TalentAddCost", TalentCfg[targetId].thunderAttackCostTotal - TalentCfg[curId].thunderAttackCostTotal)
            info.levelLimit = common:getLanguageString("@TalentAddLevelLimit", 1, targetLevel)
            info.nAddCost = TalentCfg[targetId].thunderAttackCostTotal - TalentCfg[curId].thunderAttackCostTotal
        end
        info.ElementType    = ElementType.THUNDER
        info.AttrType   = AttrType.ATTACK
    elseif attrId == Const_pb.THUNDER_DENFENCE then
        if targetId <= #TalentCfg then
            info.attrValue  = common:getLanguageString("@TalentDefenseText", TalentCfg[targetId].thunderDefenseNumTotal - TalentCfg[curId].thunderDefenseNumTotal)
            info.addCost    = common:getLanguageString("@TalentAddCost", TalentCfg[targetId].thunderDefenseCostTotal - TalentCfg[curId].thunderDefenseCostTotal)
            info.levelLimit = common:getLanguageString("@TalentAddLevelLimit", 1, targetLevel)
            info.nAddCost = TalentCfg[targetId].thunderDefenseCostTotal - TalentCfg[curId].thunderDefenseCostTotal
        end
        info.ElementType    = ElementType.THUNDER
        info.AttrType   = AttrType.DEFENSE
    end
     
    return info
end

----------------------------- cfg end ------------------------------
----------------------------- label content -------------------------
-- sv显示文字
function TalentManager:getAttrNameByIdForSV(attrId, stage, value)
    local str1 = ""
    if attrId == Const_pb.ICE_ATTACK then
        str1 = common:getLanguageString("@IceAttackText")
    elseif attrId == Const_pb.ICE_DEFENCE then
        str1 = common:getLanguageString("@IceDefenseText")
    elseif attrId == Const_pb.FIRE_ATTACK then
        str1 = common:getLanguageString("@FireAttackText")
    elseif attrId == Const_pb.FIRE_DEFENCE then
        str1 = common:getLanguageString("@FireDefenseText")
    elseif attrId == Const_pb.THUNDER_ATTACK then
        str1 = common:getLanguageString("@ThunderAttackText")
    elseif attrId == Const_pb.THUNDER_DENFENCE then
        str1 = common:getLanguageString("@ThunderDefenseText")
    end
    return str1
end

function TalentManager:getAttrNameById(attrId)
    local str = ""
    str = common:getLanguageString("@AttrName_".. tostring(attrId))
    return str
end

function TalentManager:getAttrAddContent(talentInfo)
    local str = ""
    str = common:getLanguageString("@TalentAttrContent", talentInfo.attrStage, talentInfo.attrLevel, TalentManager:getAttrNameById(talentInfo.attrId), talentInfo.attrValue)
    return str
end
--------------------------- label content end ---------------------
-- 清空数据
function TalentManager_reset()
    TalentManager.ElementTalentInfo = {}
    TalentManager.curAttrId = 0
end

return TalentManager