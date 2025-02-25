Skill_1203 = Skill_1203 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
�ᤩ�ۨ��ζ���C���t�ݩʭ^��"�y�]�HB��"(params1)4/5/6��(params2)
]]--
--[[ OLD
�ͩR�C��30%/50%/50%(params1)���]�O����50%(params2)�ɽᤩ�ۨ�"�t�v�y��I/�t�v�y��I/"�t�v�y��II(params3)�A�Ϥ��h������Buff�C
�����ݩ�(params4)�ؼ��B�~�W��20%(params5)
]]--
-------------------------------------------------------
function Skill_1203:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1203:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1203:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    local darkTar = self:getDarkElementTar(chaNode, skillId)
    
    table.insert(darkTar, chaNode)
    for i = 1, #darkTar do
        local target = darkTar[i]
        -- ���[Buff
        if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[1]))
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[2]) * 1000)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
        else
            resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[1]) }
            resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
            resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[2]) * 1000 }
            resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
        end
    end

    return resultTable
end

function Skill_1203:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1203:getDarkElementTar(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    local aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    local darkTar = { }
    for i = 1, #aliveIdTable do
        if (friendList[aliveIdTable[i]].battleData[NewBattleConst.BATTLE_DATA.ELEMENT] == NewBattleConst.ELEMENT.DARK) and
           (chaNode.idx ~= friendList[aliveIdTable[i]].idx) then
            table.insert(darkTar, friendList[aliveIdTable[i]])
        end
    end
    return darkTar
end

return Skill_1203