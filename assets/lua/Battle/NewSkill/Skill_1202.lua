Skill_1202 = Skill_1202 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
�ᤩ�ۨ��ζ���C�����ݩʭ^��"�y�]�HA��"(params1)4/5/6��(params2)
]]--
-------------------------------------------------------
function Skill_1202:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1202:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1202:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    local lightTar = self:getLightElementTar(chaNode, skillId)
    
    table.insert(lightTar, chaNode)
    for i = 1, #lightTar do
        local target = lightTar[i]
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

function Skill_1202:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1202:getLightElementTar(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    local aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    local lightTar = { }
    for i = 1, #aliveIdTable do
        if (friendList[aliveIdTable[i]].battleData[NewBattleConst.BATTLE_DATA.ELEMENT] == NewBattleConst.ELEMENT.LIGHT) and
           (chaNode.idx ~= friendList[aliveIdTable[i]].idx) then
            table.insert(lightTar, friendList[aliveIdTable[i]])
        end
    end
    return lightTar
end

return Skill_1202