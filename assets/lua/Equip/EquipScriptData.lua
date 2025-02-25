----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb")
local Shop_pb = require("Shop_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local HP_pb = require("HP_pb") --包含协议id文件
local EquipScriptData = {
}
EquipScriptData._roleType = {
    ROLE_LEAD = 1,--主角类型
    ROLE_MERCENARY = 2,--佣兵
}

--由类型 区分开的数据可配置在这里
EquipScriptData._TypeData =
{
    [EquipScriptData._roleType.ROLE_LEAD] = 
        {
            scriptName = "Equip.EquipLeadPage",
            helpFile = "HelpEquip",
        },
    [EquipScriptData._roleType.ROLE_MERCENARY] = 
        {
            scriptName = "EquipMercenaryPage",
            helpFile = "HelpMercenary",
        }
}
--当前选择的角色类型 默认是玩家
EquipScriptData._curRoleType = EquipScriptData._roleType.ROLE_LEAD

EquipScriptData.totalFightNum = 0--当前出战佣兵总数
EquipScriptData.maxFightNum = 2--最大出战佣兵总数
----------packet msg--------------------------
return EquipScriptData