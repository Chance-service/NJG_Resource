local UserMercenaryManager = { };
--------------------------------------------------------------------------------

------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
local Player_pb = require("Player_pb");
local UserItemManager = require("UserItemManager")
local RoleManager = require("PlayerInfo.RoleManager");
local PBHelper = require("PBHelper");
local MercenaryInfos = { }
local mercenaryStatusInfos = { }
MercenaryEquipRedPoint = false

UserInfo = require("PlayerInfo.UserInfo")
UpGradeStepTable = { } -- Ó¶±øÉý½×-ÉýÐÇ ·ÖÀà±í


------------------------------------------------------------------
-- 注册副将信息消息，所有的副将信息 ， 碎片 、 状态.....
local mMercenaryStatusSubscriber = { }
function UserMercenaryManager:addSubscriber(key, func)
    mMercenaryStatusSubscriber[key] = func
end

function UserMercenaryManager:removeSubscriber(key)
    mMercenaryStatusSubscriber[key] = nil
end

function UserMercenaryManager:broadcast()
    for k, v in pairs(mMercenaryStatusSubscriber) do
        if v then
            v(UserMercenaryManager:getMercenaryStatusInfos())
        end
    end
end
------------------------------------------------------------------



------------------------------------------------------------------
-- 注册玩家已激活副将的信息监听
local mUserActiviteRoleIdSubscriber = { }
function UserMercenaryManager:addActiviteRoleIdSubscriber(key, func)
    mUserActiviteRoleIdSubscriber[key] = func
end

function UserMercenaryManager:removeActiviteRoleIdSubscriber(key)
    mUserActiviteRoleIdSubscriber[key] = nil
end

function UserMercenaryManager:broadcastActiviteRoleData()
    for k, v in pairs(mUserActiviteRoleIdSubscriber) do
        if v then
            v(MercenaryInfos)
        end
    end
end
------------------------------------------------------------------




-- MercenaryHaloEnhanceRedPoint = false
--------------------------------------------------------------------------------
function UserMercenaryManager:getMercenaryStatusById(roleId)
    for i, v in ipairs(mercenaryStatusInfos) do
        if v.roleId == roleId then
            return v
        end
    end
end

function UserMercenaryManager:getMercenaryStatusByItemId(itemId)
    for i, v in ipairs(mercenaryStatusInfos) do
        if v.itemId == itemId then
            return v
        end
    end
    -- end
end


function UserMercenaryManager:setMercenaryStatusInfos(statusInfo)
    mercenaryStatusInfos = { }
    for i, v in ipairs(statusInfo) do
        mercenaryStatusInfos[i] = {
            roleId = v.roleId,
            type = v.type,
            roleStage = v.roleStage,
            soulCount = v.soulCount,
            costSoulCount = v.costSoulCount,
            hide = v.hide,
            itemId = v.itemId,
            status = v.status,
            fight = v.fight,
        }
    end
    -- TODO
    -- UserMercenaryManager:broadcast()
end

function UserMercenaryManager:updateMercenaryStatusInfos(info)
    if mercenaryStatusInfos == nil then
        return
    end
    local bl = false
    for k, v in pairs(mercenaryStatusInfos) do
        if v.roleId == info.roleId then
            v.roleId = info.roleId
            v.roleStage = info.roleStage
            v.soulCount = info.soulCount
            v.costSoulCount = info.costSoulCount
            v.hide = info.hide
            v.itemId = info.itemId
            v.status = info.status
            v.fight = info.fight
            bl = true
            break
        end
    end
    if not bl then
        table.insert(mercenaryStatusInfos, {
            roleId = info.roleId,
            roleStage = info.roleStage,
            soulCount = info.soulCount,
            costSoulCount = info.costSoulCount,
            hide = info.hide,
            itemId = info.itemId,
            status = info.status,
            fight = info.fight,
        } )
    end

    UserMercenaryManager:broadcast()
end

function UserMercenaryManager:updateMercenaryStatus(args)

end

function UserMercenaryManager:getMercenaryStatusInfos()
    return mercenaryStatusInfos
end


function UserMercenaryManager:getUserMercenaryInfos()
    return MercenaryInfos;
end

function UserMercenaryManager:getFightMercenaryIndex()
    local fightMercenary = 1
    local realfightMercenary = nil
    if MercenaryInfos then
        for k, data in pairs(MercenaryInfos) do
            if data.status == Const_pb.FIGHTING then
                fightMercenary = i
                realfightMercenary = i
            end
        end
    end

    return fightMercenary, realfightMercenary
end

function UserMercenaryManager:getUserMercenaryById(roleId)
    -- 此函数"只能"用于获取已激活的佣兵数据
    if MercenaryInfos then
        return MercenaryInfos[roleId]
    end
end

function UserMercenaryManager:getUserMercenaryByItemId(itemId)
    for k, info in pairs(MercenaryInfos) do
        if info.itemId == itemId then
            return info
        end
    end
    return nil
end

function UserMercenaryManager:isEquipDressed(userEquipId)
    if MercenaryInfos then
        for k, userMercenary in pairs(MercenaryInfos) do
            for _, roleEquip in ipairs(userMercenary.equips) do
                if roleEquip and roleEquip.equipId == userEquipId then
                    return true;
                end
            end
        end
    end
    return false
end

function UserMercenaryManager:CanBeNude(itemId)
    for k, info in pairs(MercenaryInfos) do
        if info.itemId == itemId then
            if (FetterManager.getIllCfgByRoleId(itemId).isSkin == 1) then
                return (info.stageLevel2 >= 1)
            else
                return (info.stageLevel >= 2)
            end
        end
    end
    return false
end

function UserMercenaryManager:getEquipDressedBy(userEquipId)
    if MercenaryInfos then
        for k, userMercenary in pairs(MercenaryInfos) do
            for _, roleEquip in ipairs(userMercenary.equips) do
                if roleEquip and roleEquip.equipId == userEquipId then
                    return RoleManager:getOccupationById(userMercenary.itemId);
                end
            end
        end
    end
    return "";
end

function UserMercenaryManager:getUpGradeStepTable()
    if #UpGradeStepTable > 0 then
        return UpGradeStepTable
    end
    local cfg = ConfigManager.getMercenaryUpStepTable()
    UpGradeStepTable = { }
    for i = 1, #cfg do
        if UpGradeStepTable[cfg[i].roleId] == nil then
            UpGradeStepTable[cfg[i].roleId] = { }
        end
        if UpGradeStepTable[cfg[i].roleId][cfg[i].stageLevel] == nil then
            UpGradeStepTable[cfg[i].roleId][cfg[i].stageLevel] = { }
        end
        UpGradeStepTable[cfg[i].roleId][cfg[i].stageLevel][cfg[i].starLevel] = cfg[i]
    end
    return UpGradeStepTable
end

function UserMercenaryManager:getEquipByPart(roleId, part)
    local userMercenary = self:getUserMercenaryById(roleId);
    return PBHelper:getRoleEquipByPart(userMercenary.equips, part);
end	

function UserMercenaryManager:getProfessioinIdByPart(roleId, part)
    local userMercenary = self:getUserMercenaryById(roleId);
    return userMercenary.prof;
end	
-- mercenary halo
function UserMercenaryManager:initMercenaryHaloStatus(mercenaryInfo)
    local myMercenary = UserInfo.activiteRoleId
    if mercenaryInfo ~= nil and myMercenary ~= nil then
        MercenaryInfos[mercenaryInfo.roleId] = mercenaryInfo

        ----------------test
        ConfigManager.getMercenaryRingCfg()
        local itemId = mercenaryInfo.itemId
        local status = mercenaryInfo.status
        local c = 0
        ----------------
        for i = 1, #myMercenary do
            if myMercenary[i] == mercenaryInfo.roleId then
                UserEquipManager:setRedPointNotice(mercenaryInfo.roleId, true)
            end
        end

        --UserMercenaryManager:broadcastActiviteRoleData()
    end
end


function UserMercenaryManager:changeMercenarysStateRest(itemId)
    if MercenaryInfos == nil then
        return
    end
    local Const_pb = require("Const_pb")
    for k, v in pairs(MercenaryInfos) do
        if v.itemId == itemId then
            v.status = Const_pb.RESTTING
        end
    end
end

function UserMercenaryManager:changeMercenarysStateBattle(itemId)
    if MercenaryInfos == nil then
        return
    end
    local Const_pb = require("Const_pb")
    for k, v in pairs(MercenaryInfos) do
        if v.itemId == itemId then
            v.status = Const_pb.FIGHTING
        end
    end
end

function UserMercenaryManager:addMercenaryStateBattleByRoleId(roleId)
    if MercenaryInfos[roleId] == nil then
        return
    end
    local Const_pb = require("Const_pb")
    MercenaryInfos[roleId].status = math.min(MercenaryInfos[roleId].status + Const_pb.FIGHTING, Const_pb.MIXTASK)
end

function UserMercenaryManager:removeMercenaryStateBattleByRoleId(roleId)
    if MercenaryInfos[roleId] == nil then
        return
    end
    local Const_pb = require("Const_pb")
    MercenaryInfos[roleId].status = math.max(MercenaryInfos[roleId].status - Const_pb.FIGHTING, Const_pb.RESTTING)
end

function UserMercenaryManager:getRoleCanLevelUp(roleId)
    local result = false
    local info = self:getUserMercenaryById(roleId)
    if info then
        local heroStarCfg = ConfigManager.getHeroStarCfg()
        local starCfg = nil
        for i = 1, #heroStarCfg do
            if info.itemId == heroStarCfg[i].RoleId and info.starLevel == heroStarCfg[i].Star then
                starCfg = heroStarCfg[i]
                break
            end
        end
        if not starCfg then
            return result
        end
        if info.level < starCfg.LimitLevel then  -- 未達等級上限
            local heroLevelCfg = ConfigManager.getHeroLevelCfg()
            local levelCfg = heroLevelCfg[info.level]
            local levelCost = common:split(levelCfg.Cost, ",")
            local moneyNum = UserInfo.playerInfo.coin or 0
            local expNum = levelCost[2] and UserItemManager:getCountByItemId(tonumber(common:split(levelCost[2], "_")[2])) or 0
            local stoneNum = levelCost[3] and UserItemManager:getCountByItemId(tonumber(common:split(levelCost[3], "_")[2])) or 0
            local moneyCost = tonumber(levelCost[1] and common:split(levelCost[1], "_")[3] or 0)
            local expCost = tonumber(levelCost[2] and common:split(levelCost[2], "_")[3] or 0)
            local stoneCost = tonumber(levelCost[3] and common:split(levelCost[3], "_")[3] or 0)
            if moneyNum >= moneyCost and expNum >= expCost and stoneNum >= stoneCost then
                result = true
            end
        end
    end
    return result
end

function UserMercenaryManager:getRoleCanUpgrade(roleId)
    local info = self:getUserMercenaryById(roleId)
    if info then
        local heroStarCfg = ConfigManager.getHeroStarCfg()
        local starCfg = nil
        for i = 1, #heroStarCfg do
            if info.itemId == heroStarCfg[i].RoleId and info.starLevel == heroStarCfg[i].Star then
                starCfg = heroStarCfg[i]
                break
            end
        end
        if not starCfg then
            return false
        end
        local costItems = common:split(starCfg.Cost, ",")
        for i = 1, 3 do
            if costItems[i] and costItems[i] ~= "" then
                local _type, _itemId, _num = unpack(common:split(costItems[i], "_"))
                local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_itemId), tonumber(_num))
                local userNum = 0
                if tonumber(_type) == Const_pb.SOUL * 10000 then
                    userNum = self:getMercenaryStatusByItemId(info.itemId).soulCount
                elseif tonumber(_type) == Const_pb.TOOL * 10000 then
                    userNum = UserItemManager:getCountByItemId(tonumber(_itemId))
                end
                if userNum < tonumber(_num) then
                    return false
                end
            end
        end
    end
    return true
end
--------------------------------------------------------------------------------
return UserMercenaryManager