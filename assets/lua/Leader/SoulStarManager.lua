local HP_pb = require("HP_pb") -- 包含协议id文件
local UserInfo = require("PlayerInfo.UserInfo");
local StarSoul_pb = require("StarSoul_pb")
local ConfigManager = require("ConfigManager")
local UserItemManager = require("Item.UserItemManager")
local starSoulCfg = ConfigManager.getStarSoulCfg() -- 星魂配置
SoulStarManager = {isUpgradable = false  }
--
local isInitSoulStarProto = false
function SoulStarManager:requestProto()
    if isInitSoulStarProto and SoulStarManager[1] ~= nil then
        return
    end
    if UserInfo.roleInfo.level >= GameConfig.SOULSTAR_LEVEL_LIMIT then
        for i = 1, 1 do
            local HP_pb = require("HP_pb")
            local msg = StarSoul_pb.SyncStarSoul()
            msg.group = i
            common:sendPacket(HP_pb.SYNC_STAR_SOUL_C, msg, false)
        end
    end

end

--- 专门用来做红点逻辑的 原来的协议还在page里面接收
function SoulStarManager:onReceivePacketInit(msg)
    isInitSoulStarProto = true
    local id = msg.id
    local cfg = starSoulCfg[id]
    if cfg.level == ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.starSoulLevelLimit].level then
        local starType = cfg["starType"]
        SoulStarManager[starType] = nil
        self:showRedPoint()
        return
    end

    local nextId = msg.id + 1
    -- 应该是下一级的消耗
    local nextCfg = starSoulCfg[nextId]
    if nextCfg then
        local starType = nextCfg["starType"]
        SoulStarManager[starType] = nextCfg
    end

    self:showRedPoint()
end

function SoulStarManager:showRedPoint(curPage)
    local curPageName = MainFrame:getInstance():getCurShowPageName()
    if (curPageName == "EquipmentPage" or curPageName == "SoulStarPage" or curPage == "EquipLeadPage" or "MainScenePage") then
        local marks, allMark = SoulStarManager:getAllRedVisible()
        CCLuaLog("### getCurShowPageName = " .. tostring(MainFrame:getInstance():getCurShowPageName()))
        if curPageName == "EquipmentPage" or curPage == "EquipLeadPage" then
            --EquipLeadPage_setSoulStarRedPoint(allMark)
        elseif curPageName == "SoulStarPage" then
            --SoulStarPageBase_setRedPoint(marks)
        elseif curPageName == "MainScenePage" then
           --PageManager.showRedNotice("SoulStar", allMark)
        end
        PageManager.setAllNotice()
    end
end

-- 获取红点是否要显示
function SoulStarManager:getRedVisible(group)
    if not SoulStarManager[group] then
        return false
    end

    local cfg = SoulStarManager[group]
    if not cfg then
        return false
    end

    if cfg.costItems[1].type == 0 then
        return false
    end

    local hasCount = UserItemManager:getCountByItemId(cfg.costItems[1].itemId);
    if hasCount >= cfg.costItems[1].count then
        return true
    end

    return false
end

--- 获取所有红点的显示信息 id是group   对应bool值
function SoulStarManager:getAllRedVisible()
    if UserInfo.roleInfo.level < GameConfig.SOULSTAR_LEVEL_LIMIT then
        return {}, false
    end
    local marks = { }
    local allMark = false
    for i = 1, 6 do
        local mark = SoulStarManager:getRedVisible(i)
        marks[i] = mark

        if mark then
            allMark = true
        end
    end
    SoulStarManager.isUpgradable = allMark
    return marks, allMark
end

return SoulStarManager