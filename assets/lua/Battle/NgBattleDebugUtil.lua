NgBattleDebugUtil = NgBattleDebugUtil or {}

local CONST = require("Battle.NewBattleConst")
local PBHelper = require("PBHelper")
require("Battle.NewBattleUtil")

-------------------------------------------------------
-- ÀË¬d¨¤¦âÄÝ©Ê
function NgBattleDebugUtil:testMessage(chaNode, attrs, id)
    local msg = ""
    if attrs then
        --HP
        if PBHelper:getAttrById(attrs, Const_pb.HP) ~= NewBattleUtil:calMaxHp(chaNode) then
            msg = msg .. "Server HP: " .. PBHelper:getAttrById(attrs, Const_pb.HP) .. ", Client HP: " .. NewBattleUtil:calMaxHp(chaNode) .. "\n"
        end
        --Phy Atk
        if PBHelper:getAttrById(attrs, Const_pb.ATTACK_attr) ~= NewBattleUtil:calPhyAtk(chaNode, nil) then
            msg = msg .. "Server Phy Atk: " .. PBHelper:getAttrById(attrs, Const_pb.ATTACK_attr) .. ", Client Phy Atk: " .. NewBattleUtil:calPhyAtk(chaNode, nil) .. "\n"
        end
        --Mag Atk
        if PBHelper:getAttrById(attrs, Const_pb.MAGIC_attr) ~= NewBattleUtil:calMagAtk(chaNode, nil) then
            msg = msg .. "Server Mag Atk: " .. PBHelper:getAttrById(attrs, Const_pb.MAGIC_attr) .. ", Client Mag Atk: " .. NewBattleUtil:calMagAtk(chaNode, nil) .. "\n"
        end
        --Phy Def
        if PBHelper:getAttrById(attrs, Const_pb.PHYDEF) ~= NewBattleUtil:calBaseDef(nil, chaNode, true) then
            msg = msg .. "Server Phy Def: " .. PBHelper:getAttrById(attrs, Const_pb.PHYDEF) .. ", Client Phy Def: " .. NewBattleUtil:calBaseDef(nil, chaNode, true) .. "\n"
        end
        --Mag Def
        if PBHelper:getAttrById(attrs, Const_pb.MAGDEF) ~= NewBattleUtil:calBaseDef(nil, chaNode, false) then
            msg = msg .. "Server Mag Def: " .. PBHelper:getAttrById(attrs, Const_pb.MAGDEF) .. ", Client Mag Def: " .. NewBattleUtil:calBaseDef(nil, chaNode, false) .. "\n"
        end
        --Cri
        if PBHelper:getAttrById(attrs, Const_pb.CRITICAL) ~= NewBattleUtil:calCriValue(chaNode.battleData[CONST.BATTLE_DATA.AGI]) then
            msg = msg .. "Server Cri: " .. PBHelper:getAttrById(attrs, Const_pb.CRITICAL) .. ", Client Cri: " .. NewBattleUtil:calCriValue(chaNode.battleData[CONST.BATTLE_DATA.AGI]) .. "\n"
        end
        --Hit
        if PBHelper:getAttrById(attrs, Const_pb.HIT) ~= NewBattleUtil:calHitValue(chaNode.battleData[CONST.BATTLE_DATA.STR], chaNode.battleData[CONST.BATTLE_DATA.INT], 
                                      chaNode.battleData[CONST.BATTLE_DATA.AGI]) then
            msg = msg .. "Server Hit: " .. PBHelper:getAttrById(attrs, Const_pb.HIT) .. ", Client Hit: " .. NewBattleUtil:calHitValue(chaNode.battleData[CONST.BATTLE_DATA.STR], chaNode.battleData[CONST.BATTLE_DATA.INT], 
                                      chaNode.battleData[CONST.BATTLE_DATA.AGI]) .. "\n"
        end
        --Dodge
        if PBHelper:getAttrById(attrs, Const_pb.DODGE) ~= NewBattleUtil:calDodgeValue(chaNode.battleData[CONST.BATTLE_DATA.STR], chaNode.battleData[CONST.BATTLE_DATA.INT], 
                                          chaNode.battleData[CONST.BATTLE_DATA.AGI], chaNode.battleData[CONST.BATTLE_DATA.STA]) then
            msg = msg .. "Server Dodge: " .. PBHelper:getAttrById(attrs, Const_pb.DODGE) .. ", Client Dodge: " .. NewBattleUtil:calDodgeValue(chaNode.battleData[CONST.BATTLE_DATA.STR], chaNode.battleData[CONST.BATTLE_DATA.INT], 
                                          chaNode.battleData[CONST.BATTLE_DATA.AGI], chaNode.battleData[CONST.BATTLE_DATA.STA]) .. "\n"
        end
        if msg ~= "" then
            --CCLuaLog("configId:" .. id .. ", posId: " .. chaNode.idx .. "\n" .. msg)
            --MessageBoxPage:Msg_Box("configId:" .. id .. ", posId: " .. chaNode.idx .. "\n" .. msg)
        end
    end   
end


return NgBattleDebugUtil