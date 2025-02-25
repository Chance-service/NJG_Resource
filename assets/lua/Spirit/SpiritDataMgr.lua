--[[ 
    name: SpiritDataMgr
    desc: 精靈頁面 資料管理
    author: youzi
    update: 2023/7/6 17:15
    description: 
--]]

local UserMercenaryManager = require("UserMercenaryManager")
local InfoAccesser = require("Util.InfoAccesser")

--[[ 本體 ]]
local Inst = {}

Inst.JobTypeCfg = {
    [1] = {
        rareStr = "SR"
    },
    [2] = {
        rareStr = "SSR"
    },
    [3] = {
        rareStr = "UR"
    },
}

--[[ 等級對應設定 ]]
Inst._level2Cfg = nil

--[[ ID對應精靈 ]]
Inst._id2SpiritCfg = nil
Inst._spiritCfgs = nil

--[[ 裝載中 欄位數量 (棄用) ]]
-- Inst.LoadoutSlotCount = 4

--[[ 當前精靈裝載 (棄用) ]]
-- Inst._spiritLoadout = nil

--[[ ID對應玩家的精靈資訊 ]]
Inst._id2SpiritStatusInfo = {}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {
    {
        -- 子頁面名稱 : 召喚
        subPageName = "Summon",

        -- 分頁 相關
        scriptName = "Spirit.SpiritSubPage_Summon",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_Summon.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_Summon_On.png",
        
        -- 標題
        title = "@Spirit.Summon.title",

        -- 貨幣資訊 
        currencyInfos = {
            { priceStr = "30000_6001_0" },
        },
        
        -- 其他子頁資訊 ----------

        -- 進度條 標註
        progressDesc = "ProgressTest",
    },

    {
        -- 子頁面名稱 : 裝載
        subPageName = "Loadout",

        -- 分頁 相關
        scriptName = "Spirit.SpiritSubPage_Loadout",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_Island.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_Island_On.png",
        
        -- 標題
        title = "@Spirit.Loadout.title",

        -- 貨幣資訊 
        currencyInfos = {
            { priceStr = "30000_5002_0" },
        },
        
        -- 其他子頁資訊 ----------

    },

    {
        -- 子頁面名稱 : 圖鑑
        subPageName = "Gallery",

        -- 分頁 相關
        scriptName = "Spirit.SpiritSubPage_Gallery",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_Gallery.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_Gallery_On.png",
        
        -- 標題
        title = "@Spirit.Gallery.title",

        -- 貨幣資訊 
        currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "10000_1001_0" },
        },
        
        -- 其他子頁資訊 ----------

    },

    {
        -- 子頁面名稱 : 羈絆
        subPageName = "Collection",

        -- 分頁 相關
        scriptName = "Spirit.SpiritSubPage_Collection",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_Bondage.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_Bondage_On.png",
        
        -- 標題
        title = "@Spirit.Collection.title",

        -- 貨幣資訊 
        currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "10000_1001_0" },
        },
        
        -- 其他子頁資訊 ----------

    },
}

--[[ 取得 子頁面 配置 ]]
function Inst:getSubPageCfg (subPageName)
    for idx, cfg in ipairs(Inst.SubPageCfgs) do
        if cfg.subPageName == subPageName then return cfg end
    end
    return nil
end

--[[ 更新 資料 ]]
function Inst:updateCfgs(isForce)


    -- 精靈 設置
    if isForce or self._id2SpiritCfg == nil then
    
        self._id2SpiritCfg = {}
        self._spiritCfgs = {}
        
        local newHeroCfgs = ConfigManager.getNewHeroCfg()
        for key, cfg in pairs(newHeroCfgs) do
            if cfg.ID > 500 then
                local newCfg = {}
                for cfg_key, cfg_val in pairs(cfg) do
                    newCfg[cfg_key] = cfg_val
                end
                self._id2SpiritCfg[cfg.ID] = newCfg
                self._spiritCfgs[#self._spiritCfgs+1] = newCfg
            end
        end
        
    end
    
    if isForce or self._level2Cfg == nil or self._group2Cfg == nil then

        -- 精靈島 等級 設置
        self._level2Cfg = {}

        local levelCfgs_raw = ConfigManager.getSpiritLevelCfg()

        local levelCfgs = {}
        for key, val in pairs(levelCfgs_raw) do
            levelCfgs[#levelCfgs+1] = val
        end
        table.sort(levelCfgs, function(a, b)
            return a.level < b.level
        end)

        -- 精靈島 階層 設置
        self._group2Cfg = {}

        local currentGroup = 0
        local lastCfg = nil
        for idx, cfg in ipairs(levelCfgs) do

            if cfg.group > currentGroup then
                local lastGroupCfg = self._group2Cfg[cfg.group-1]
                if lastGroupCfg ~= nil then
                    lastGroupCfg["endLevel"] = lastCfg.level
                end
                
                local groupCfg = {
                    startLevel = cfg.level
                }

                self._group2Cfg[cfg.group] = groupCfg
                currentGroup = cfg.group
            end

            lastCfg = cfg

            self._level2Cfg[cfg.level] = cfg
        end
    end
end

--[[ 取得 精靈島 等級資料 ]]
function Inst:getLevelCfg (level)
    self:updateCfgs(false)
    return self._level2Cfg[level]
end

--[[ 取得 精靈島 階層資料 ]]
function Inst:getGroupCfg (group)
    self:updateCfgs(false)
    return self._group2Cfg[group]
end

--[[ 取得精靈資料 ]]
function Inst:getSpiritCfg (spiritID)
    self:updateCfgs(false)
    return self._id2SpiritCfg[spiritID]
end

function Inst:getSpiritCfgs ()
    self:updateCfgs(false)
    return self._spiritCfgs
end

--[[ 取得精靈升星資料 ]]
function Inst:getSpiritStarCfg (spiritID, star)
    local heroStarCfgs = ConfigManager.getHeroStarCfg()
    for idx, cfg in ipairs(heroStarCfgs) do 
        if cfg.RoleId == spiritID and cfg.Star == star then
            return cfg
        end
    end
end

--[[ 取得 精靈羈絆設定 ]]
function Inst:getSpiritRelationshipCfgs ()
    local relationShipCfgs = FetterManager.getRelationCfg()
    local list = {}
    local len = 1
    for idx, cfg in ipairs(relationShipCfgs) do
        if cfg.order > 2000 then
            local copy = common:deepCopy(cfg)
            list[len] = copy
            len = len + 1
        end
    end
    return list
end

--[[ 取得精靈羈絆狀態 ]]
function Inst:getSpiritRelationshipStatusInfo (relationshipID)
    if FetterManager.isRelationOpen(relationshipID) ~= true then
        return nil
    end

    local info = {
        star = FetterManager.getAlbumIdByFetterId(relationshipID),
    }
    return info
end

--[[ 取得 當前精靈裝載 (棄用) ]]
-- function Inst:getLoadoutSpirits (isReload)
--     if isReload == nil then isReload = false end
    
--     if not isReload and self._spiritLoadout ~= nil then
--         return self._spiritLoadout
--     end
    
--     self._spiritLoadout = {}
--     for idx = 1, self.LoadoutSlotCount do
--         local spirit = CCUserDefault:sharedUserDefault():getIntegerForKey("Spirit.Loadout.slot."..tostring(idx))
--         if spirit == 0 then spirit = nil end
--         self._spiritLoadout[#self._spiritLoadout+1] = spirit
--     end
--     return self._spiritLoadout
-- end

--[[ 設置 當前精靈裝載 指定欄位 (棄用) ]]
-- function Inst:setLoadoutSpirit (idx, spiritID, isSave, isSaveFlush)
--     if isSave == nil then isSave = true end
--     if isSaveFlush == nil then isSaveFlush = true end
--     if self._spiritLoadout == nil then
--         self:getSpiritLoadout()
--     end
--     self._spiritLoadout[idx] = spiritID

--     if isSave then
--         local msg = Formation_pb.HPFormationEditReq()
--         msg.index = nGroupIdx

--         -- 檢查隊伍是否是全空
--         local teamCount = 0
--         for i = 1, 5 do
--             if roleIds[i] then
--                 msg.roleIds:append(roleIds[i])
--                 if roleIds[i] ~= 0 then
--                     teamCount = teamCount + 1
--                 end
--             else
--                 msg.roleIds:append(0)
--             end
--         end
--         if teamCount <= 0 then
--             MessageBoxPage:Msg_Box_Lan("@OrgTeamNumLimit")
--         end
--         common:sendPacket(HP_pb.EDIT_FORMATION_C, msg, false)
--     end
-- end

--[[ 更新 玩家持有的精靈資訊 ]]
function Inst:updateUserSpiritStatusInfosByRoleInfos (roleInfos) 
    for idx, roleInfo in ipairs(roleInfos) do
        self:updateUserSpiritStatusInfoByRoleInfo(roleInfo)
    end
end

--[[ 以RoleInfo 更新 玩家精靈角色資料 ]]
function Inst:updateUserSpiritStatusInfoByRoleInfo (roleInfo)
    if roleInfo.type ~= 4 --[[ Spirit ]] then return end
    local spiritID = roleInfo.itemId
    
    -- 轉換 RoleInfo 為 自定義使用的 StatusInfo 
    local spiritStatusInfo = self._id2SpiritStatusInfo[spiritID] or {}
    
    -- 辨識ID
    spiritStatusInfo.spiritID = spiritID
    spiritStatusInfo.roleID = roleInfo.roleId

    -- 若 尚未啟用 則 忽略
    if roleInfo.activiteState ~= Const_pb.IS_ACTIVITE then return end

    -- 選項 不強制覆蓋 ----

    if roleInfo.starLevel ~= nil then
        spiritStatusInfo.star = roleInfo.starLevel
    end
    
    if roleInfo.attribute  ~= nil then
        local attrs = {}
        local roleAttrs = roleInfo.attribute.attribute
        for idx, val in ipairs(roleAttrs) do
            attrs[idx] = {
                ["attr"] = val.attrId,
                ["val"] = val.attrValue,
            }
        end
        spiritStatusInfo.attrs = attrs
    end
    
    if roleInfo.skills ~= nil then
        local skill = nil
        if #roleInfo.skills > 0 then
            local skill1 = roleInfo.skills[1]
            skill = {
                -- ["id"] = skill1.skillId, -- 這樣用是錯的??
                ["id"] = skill1.itemId,
                -- ["level"] = skill1.level -- 好像不能用這邊的level,
                ["level"] = tonumber(string.sub(tostring(skill1.itemId), -2, -1)),
            }
        end
        spiritStatusInfo.skill = skill
        -- dump(skill, string.format("spirit[%s] skill", spiritID))
    end

    -- 待新增其他...

    
    -- dump(spiritStatusInfo, "spirit status : "..tostring(spiritID))

    self._id2SpiritStatusInfo[spiritID] = spiritStatusInfo
end

--[[ 取得玩家有的各精靈的狀態 (從角色(傭兵)狀態中取得) ]]
function Inst:getUserSpiritStatusInfos ()
    local infos = {}
    local idx = 1
    for id, info in pairs(self._id2SpiritStatusInfo) do
        infos[idx] = info
        idx = idx + 1
    end
    return infos
end

--[[ 取得玩家有的精靈的狀態 (從角色(傭兵)狀態中取得) ]]
function Inst:getUserSpiritStatusInfo (spiritID)
    return self._id2SpiritStatusInfo[spiritID]
end

--[[ 取得玩家有的精靈的狀態 (以roleID) ]]
function Inst:getUserSpiritStatusInfoByRoleID (roleID)
    for spiritID, statusInfo in pairs(self._id2SpiritStatusInfo) do
        if statusInfo.roleID == roleID then return statusInfo end
    end
    return nil
end

--[[ 取得 里程相關資訊 ]]
function Inst:getProgressInfo (subPageName)
    local subPageCfg = self:getSubPageCfg(subPageName)

    -- 里程配置
    local milestoneCfgs = ConfigManager.getSpiritSummonMilestoneCfg()
    local milestoneCfg = milestoneCfgs[1] -- id: 1號

    -- 進度資訊
    local info = {
        -- 進度描述
        progressDesc = subPageCfg.progressDesc,
        -- 進度最大值
        progressMax = milestoneCfg.points[#milestoneCfg.points],
    }


    -- 獎勵列表
    local rewards = {}
    local pointCount = #milestoneCfg.points

    -- 在數量內
    for idx = 1, pointCount do
        -- 每個里程獎勵
        local reward = {
            -- 進度
            progress = milestoneCfg.points[idx],
            -- 物品資訊
            itemInfo = milestoneCfg.reward[idx],
        }
        rewards[idx] = reward
    end
    -- 進度獎勵
    info.progressRewards = rewards

    return info
end

--[[ 取得 精靈名稱 ]]
function Inst:getSpiritName (spiritID)
    return "@SpiritName_"..tostring(spiritID)
end

--[[ 取得 精靈裝載圖像 ]]
function Inst:getSpiritLoadoutImgPath (spiritID)
    return "UI/SpiritCard/SpiritCard_"..tostring(spiritID)..".png"
end

--[[ 取得 精靈圖像 ]]
function Inst:getSpiritIconPath (spiritID)
    return "UI/RoleIcon/Icon_" .. tostring(spiritID) .. ".png"
end

--[[ 取得 精靈圖鑑 圖像 ]]
function Inst:getSpiritGalleryIconInfo (spiritID)
    -- TODO 目前為暫代

    local iconInfo = {}
    iconInfo.head = "UI/RoleShowCards/spirits_"..tostring(spiritID)..".png"

    local spiritCfg = self._id2SpiritCfg[spiritID]
    local jobCfg = self.JobTypeCfg[spiritCfg.Job]
    if jobCfg then
        iconInfo.frame = "Imagesetfile/Common_UI02/Hero_card_"..jobCfg.rareStr..".png"
    end

    return iconInfo
end

--[[ 取得 精靈技能資訊 ]]
function Inst:getSpiritSkillInfo (spiritID)
    local spiritCfg = self:getSpiritCfg(spiritID)
    if spiritCfg == nil then return nil end

    local skillList = common:split(spiritCfg.Skills, ",")

    local skillID = tonumber(skillList[1])
    local skillInfo = InfoAccesser:getSkillInfo(skillID, nil)

    return skillInfo
end

return Inst