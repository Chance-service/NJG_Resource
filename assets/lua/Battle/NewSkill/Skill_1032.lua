Skill_1032 = Skill_1032 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = {}
-------------------------------------------------------
--[[ NEW
�}���ɬI��"���II/���II�h�vII/���II�h�vII���RII"����(params1)�A
��ۨ���1033�ޯ�ɡAlv1���ɺ��II�ܺ��III�Blv2�B�~���ɬh�vII�ܬh�vIII�Blv3�B�~���ɹ��RII�ܹ��RIII
]]--
--[[ OLD
�����]�t�ۨ��H�ζ���Ҧ��^�������B���m�B�z���B�R���B�{�סB�����^�_5%/7%/10%(params1)
**�ӾUI/�ӾUII/�ӾUIII
]]--
-------------------------------------------------------
function Skill_1032:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1032:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1032:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(fList)
    -- �B�~�ĪG�ޯ�id
    local passiveId = nil
    if chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE] then
        for k, v in pairs(chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE]) do
            if math.floor(k / 10) == 1033 then  -- ��1033�ޯ��Ĳ�o�B�~�ĪG
                passiveId = k
            end
        end
    end
    --Get Buff
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    for i = 1, #params do
        local auraId = tonumber(params[i])
        if passiveId then
            local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
            local params2 = common:split(skillCfg2.values, ",")
            auraId = tonumber(params2[i]) or auraId
        end
        local buffConfig = ConfigManager:getNewBuffCfg()
        local buffId = tonumber(buffConfig[auraId].values)
        table.insert(buffTable, auraId)
        table.insert(buffTarTable, chaNode)
        table.insert(buffTimeTable, 999000 * 1000)
        table.insert(buffCountTable, 1)
        for i = 1, #aliveIdTable do
            table.insert(buffTable, buffId)
            table.insert(buffTarTable, fList[aliveIdTable[i]])
            table.insert(buffTimeTable, 999000 * 1000)
            table.insert(buffCountTable, 1)
        end
    end
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    return resultTable
end

function Skill_1032:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["COUNT"] or chaNode.skillData[skillType][skillId]["COUNT"] > 0 then
        return false
    end
    return true
end

return Skill_1032