--[[ 
    name: RedPointManager
    desc: 管理各頁面是否有紅點提示
    author: Hikaha
    update: 2024/9/20 18:15
--]]
local HP_pb = require("HP_pb")
local Activity4_pb = require("Activity4_pb")
local NodeHelper = require("NodeHelper")
local LockManager = require("Util.LockManager")
local ConfigManager = require("ConfigManager")

local RedPointCfg = ConfigManager.getRedPointSetting()
RedPointManager = RedPointManager or { tempData = { } }
-- 紅點刷新條件
RedPointManager.RefreshCondition = {
    ITEM = 1, LEVEL = 2, EQUIP = 3,
}
RedPointManager.PAGE_IDS = {
    --
    LOBBY_MAIN_BTN = 10101, 
    LOBBY_MAIL_BTN = 10201, LOBBY_SEVENDAY_BTN = 10202, LOBBY_PACKAGE_BTN = 10203, LOBBY_SHOP_BTN = 10204, LOBBY_FRIEND_BTN = 10205,
    LOBBY_FORGE_BTN = 10206, LOBBY_BOUNTY_BTN = 10207, LOBBY_QUEST_BTN = 10208, LOBBY_BAG_BTN = 10209,
    MAIL_NORMAL_TAB = 10301, MAIL_SYSTEM_TAB = 10302, SEVENDAY_MISSION_TAB = 10303, SEVENDAY_QUEST3_TAB = 10304, PACKAGE_GOODS_TAB = 10305,
    SHOP_MYSTERY_TAB = 10306, FRIEND_SENDPOINT_BTN = 10307, FRIEND_GETPOINT_BTN = 10308, FRIEND_APPLY_BTN = 10309, FORGE_EQUIP_TAB = 10310, 
    QUEST_TYPE_TAB = 10311, PACKAGE_AW_TAB = 10312,
    SEVENMISSION_DAY_TAB = 10401, SEVENMISSION_TREASURE_BTN = 10402, QUEST3_REWARD_BTN = 10403, GOODS_DAILY_TAB = 10404, MYSTERY_FREE_BTN = 10405,
    MYSTERY_REFRESH_BTN = 10406, EQUIP_WEAPON_TAB = 10407, QUEST_TREASURE_BTN = 10408, QUEST_REWARD_BTN = 10409, EQUIP_CHEST_TAB = 10410,
    EQUIP_RING_TAB = 10411, EQUIP_FOOT_TAB = 10412, GOODS_WEEKLY_TAB = 10413, GOODS_MONTHLY_TAB = 10414, PACKAGE_AW_ICON = 10415,
    SEVENMISSION_REWARD_BTN = 10501, WEAPON_ALL_BTN = 10502, WEAPON_ONE_ICON = 10503, CHEST_ALL_BTN = 10504, CHEST_ONE_ICON = 10505,
    RING_ALL_BTN = 10506, RING_ONE_ICON = 10507, FOOT_ALL_BTN = 10508, FOOT_ONE_ICON = 10509, DAILY_REWARD_BTN = 10510,
    WEEKLY_REWARD_BTN = 10511, MONTHLY_REWARD_BTN = 10512,
    --
    LOBBY2_MAIN_BTN = 20101,
    LOBBY2_RANKING_ENTRY = 20201, LOBBY2_DUNGEON_ENTRY = 20202, LOBBY2_GRAIL_ENTRY = 20203,
    RANKING_BP_ENTRY = 20301, RANKING_LV_ENTRY = 20302, RANKING_STAGE_ENTRY = 20303, RANKING_LIGHT_ENTRY = 20304,
    RANKING_DARK_ENTRY = 20305, RANKING_WATER_ENTRY = 20306, RANKING_FIRE_ENTRY = 20307, RANKING_WIND_ENTRY = 20308, 
    DUNGEON_CHALLANGE_BTN = 20309, DUNGEON_REWARD_BTN = 20310, GRAIL_HOLY_TAB = 20311, GRAIL_ELEMENT_TAB = 20312, GRAIL_CLASS_TAB = 20313,
    RANKING_BP_TREASURE = 20401, RANKING_LV_TREASURE = 20402, RANKING_STAGE_TREASURE = 20403, RANKING_LIGHT_TREASURE = 20404, 
    RANKING_DARK_TREASURE = 20405, RANKING_WATER_TREASURE = 20406, RANKING_FIRE_TREASURE = 20407, RANKING_WIND_TREASURE = 20408,
    GRAIL_HOLY_BTN = 20409, GRAIL_ELEMENT_BTN = 20410, GRAIL_CLASS_BTN = 20411,
    RANKING_BP_REWARD = 20501, RANKING_LV_REWARD = 20502, RANKING_STAGE_REWARD = 20503, RANKING_LIGHT_REWARD = 20504,
    RANKING_DARK_REWARD = 20505, RANKING_WATER_REWARD = 20506, RANKING_FIRE_REWARD = 20507, RANKING_WIND_REWARD = 20508,
    --
    BATTLE_MAIN_BTN = 30101,
    BATTLE_TREASURE_BTN = 30201, BATTLE_FAST_ENTRY = 30202, BATTLE_QUEST_ENTRY = 30203,
    BATTLE_FAST_BTN = 30301,
    --
    HERO_MAIN_BTN = 40101,
    HERO_CHAR_TAB = 40201, HERO_ILLUST_TAB = 40202, HERO_FETTER_TAB = 40203,
    HERO_CHAR_CARD = 40301, HERO_ILLUST_CARD = 40302, HERO_FETTER_BTN = 40303,
    CHAR_ATTR_TAB = 40401, CHAR_EQUIP_TAB = 40402, CHAR_RARITYUP_TAB = 40403, 
    CHAR_LEVELUP_BTN = 40501, CHAR_AUTOEQUIP_BTN = 40502, CHAR_RUNE1_SLOT = 40504, CHAR_RUNE2_SLOT = 40505, CHAR_RUNE3_SLOT = 40506, CHAR_RUNE4_SLOT = 40507, 
    CHAR_AW_SLOT = 40508, CHAR_RARITYUP_BTN = 40509, CHAR_INFO_BTN = 40510, CHAR_INFO_BTN2 = 40511,
    INFO_REWARD_BTN = 40601, INFO_REWARD_BTN2 = 40602, CHAR_EQUIP1_SLOT = 40603, CHAR_EQUIP2_SLOT = 40604, CHAR_EQUIP3_SLOT = 40605, CHAR_EQUIP4_SLOT = 40606,
    --
    SUMMON_MAIN_BTN = 50101, SUMMON_NORMAL_TAB = 50201, SUMMON_NORMAL_FREE = 50301,
}

RedPointManager.AllPageData = RedPointManager.AllPageData or { }

--[[ 初始化 AllPageData ]]
function RedPointManager_initAllPageData()
    if RedPointManager.initDone then
        return
    end
    RedPointManager.initDone = true
    for k, v in pairs(RedPointManager.PAGE_IDS) do
        local groupNum = RedPointCfg[v].groupNum
        RedPointManager.AllPageData[v] = { }
        for i = 1, groupNum do
            local defaultTable = {
                show = false,
                syncDone = false,
                options = { },
            }
            RedPointManager.AllPageData[v][i] = defaultTable
        end
    end
end
RedPointManager_initAllPageData()
--[[ 發送 全部頁面 同步協定(唯一一次) ]]
function RedPointManager_initSyncAllPageData()
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.DAILY_REWARD_BTN].unlock) then -- 禮包
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.DAILY_REWARD_BTN][1].syncDone
        if not isDone then
            local msg = Activity2_pb.DiscountInfoReq()
            msg.actId = Const_pb.DISCOUNT_GIFT
            common:sendPacket(HP_pb.DISCOUNT_GIFT_INFO_C, msg, false)
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.MYSTERY_REFRESH_BTN].unlock) then -- 神秘商店
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.MYSTERY_REFRESH_BTN][1].syncDone
        if not isDone then
            local Shop_pb = require("Shop_pb")
            local msg = Shop_pb.ShopItemInfoRequest()
            msg.type = Const_pb.INIT_TYPE
            msg.shopType = Const_pb.MYSTERY_MARKET
            common:sendPacket(HP_pb.SHOP_ITEM_C, msg, false)
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.GRAIL_HOLY_BTN].unlock) then -- 忍之聖所
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.GRAIL_HOLY_BTN][1].syncDone
        if not isDone then
            local msg = StarSoul_pb.SyncStarSoul()
            msg.group = 1
            common:sendPacket(HP_pb.SYNC_STAR_SOUL_C, msg, false)
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.GRAIL_ELEMENT_BTN].unlock) then -- 屬性聖所
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.GRAIL_ELEMENT_BTN][1].syncDone
        if not isDone then
            for i = 1, 5 do
                local msg = StarSoul_pb.SyncStarSoul()
                msg.group = i
                common:sendPacket(HP_pb.SYNC_ELEMENT_SOUL_C, msg, false)
            end
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.GRAIL_CLASS_BTN].unlock) then -- 職業聖所
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.GRAIL_CLASS_BTN][1].syncDone
        if not isDone then
            for i = 1, 4 do
                local msg = StarSoul_pb.SyncStarSoul()
                msg.group = i
                common:sendPacket(HP_pb.SYNC_CLASS_SOUL_C, msg, false)
            end
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.DUNGEON_REWARD_BTN].unlock) then -- 地下城資料
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.DUNGEON_REWARD_BTN][1].syncDone
        if not isDone then
            common:sendEmptyPacket(HP_pb.MULTIELITE_LIST_INFO_C, false)
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.RANKING_BP_REWARD].unlock) then -- 排行榜獎勵
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.RANKING_BP_REWARD][1].syncDone
        if not isDone then
            local msg = Activity4_pb.RankGiftReq()
            msg.action = 0
            common:sendPacket(HP_pb.ACTIVITY153_C, msg, false)
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.HERO_FETTER_BTN].unlock) then -- 忍娘羈絆
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.HERO_FETTER_BTN][1].syncDone
        if not isDone then
            common:sendEmptyPacket(HP_pb.FETCH_ARCHIVE_INFO_C, false)
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.INFO_REWARD_BTN].unlock) then -- 忍娘資訊
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.INFO_REWARD_BTN][1].syncDone
        if not isDone then
            local msg = Activity4_pb.HeroDramaReq()
            msg.action = 0
            common:sendPacket(HP_pb.ACTIVITY152_C, msg, false)
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[RedPointManager.PAGE_IDS.SUMMON_NORMAL_FREE].unlock) then -- 一般召喚
        local isDone = RedPointManager.AllPageData[RedPointManager.PAGE_IDS.SUMMON_NORMAL_FREE][1].syncDone
        if not isDone then
            common:sendEmptyPacket(HP_pb.ACTIVITY146_CHOSEN_INFO_C, false)
        end
    end
end

--[[ 取得 特定UI 是否有紅點 ]]
function RedPointManager_getShowRedPoint(pageId, _type)
    if not RedPointCfg[pageId] then
        return false
    end
    local childIds = common:split(RedPointCfg[pageId].child, ", ")
    _type = _type or 0
    for i = 1, #childIds do
        if RedPointManager_getShowRedPoint(tonumber(childIds[i]), _type) then
            return true
        end
    end
    if RedPointManager.AllPageData[pageId] then
        if _type == 0 then
            --for i = 1, #RedPointManager.AllPageData[pageId] do
            for k, v in pairs(RedPointManager.AllPageData[pageId]) do
                if v.show then
                    return true
                end
            end
        else
            if RedPointManager.AllPageData[pageId][_type] then
                return RedPointManager.AllPageData[pageId][_type].show
            end
        end
    end
    return false
end

--[[ 設定 特定UI 額外資料 ]]
function RedPointManager_setOptionData(pageName, _type, data)
    RedPointManager.AllPageData[pageName][_type].options = data
end

--[[ 刷新 紅點 根據不同條件 ]]
function RedPointManager_refreshRedPointByCondition(condition)
    for pageName, pageData in pairs(RedPointManager.AllPageData) do
        --for k, v in pairs(pageData.condition) do
        --    if v == condition then
        --        pageData.refreshFn(pageData.options)
        --    end
        --end
    end
    -- 刷新主要button紅點
    MainFrame_refreshAllRedPoint()
end

--[[ 設定 紅點 資訊同步完成 ]]
function RedPointManager_setPageSyncDone(pageId, group)
    --RedPointManager_setOptionData(pageId, group, { })
    RedPointManager.AllPageData[pageId][group].syncDone = true
end

--[[ 計算 紅點 是否顯示 ]]
function RedPointManager_refreshPageShowPoint(pageId, group, option)
    local isShow = false
    local lock = { }
    if pageId == RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT or pageId == RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT or
       pageId == RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT or pageId == RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT then -- 符文特殊上鎖檢查
        local UserMercenaryManager = require("UserMercenaryManager")
        local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(group)
        if roleInfo then
            lock = { hero_level = roleInfo.level, hero_star = roleInfo.starLevel }
        end
    end
    if not LockManager_getShowLockByPageName(RedPointCfg[pageId].unlock, lock) then
        if pageId == RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN then -- 升級
            require("EquipLeadPage")
            isShow = EquipLeadPage_calCanLevelUp(group)
        elseif pageId == RedPointManager.PAGE_IDS.CHAR_RARITYUP_BTN then    -- 升星
            require("EquipLeadPage")
            isShow = EquipLeadPage_calCanRarityUp(group)
        elseif pageId == RedPointManager.PAGE_IDS.CHAR_EQUIP1_SLOT or pageId == RedPointManager.PAGE_IDS.CHAR_EQUIP2_SLOT or
               pageId == RedPointManager.PAGE_IDS.CHAR_EQUIP3_SLOT or pageId == RedPointManager.PAGE_IDS.CHAR_EQUIP4_SLOT or
               pageId == RedPointManager.PAGE_IDS.CHAR_AW_SLOT then -- 裝備/專武
            require("EquipLeadPage")
            isShow = EquipLeadPage_calEquipShowPoint(pageId, group)
        elseif pageId == RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT or pageId == RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT or
               pageId == RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT or pageId == RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT then -- 符文
            require("EquipLeadPage")
            isShow = EquipLeadPage_calRuneShowPoint(pageId, group)
        elseif pageId == RedPointManager.PAGE_IDS.SUMMON_NORMAL_FREE then   -- 免費召喚
            require("Summon.SummonSubPage_Normal")
            local _isShow, _group = SummonPageNormal_calIsShowRedPoint(option)
            isShow = _isShow
            group = _group
        elseif pageId == RedPointManager.PAGE_IDS.INFO_REWARD_BTN or
               pageId == RedPointManager.PAGE_IDS.INFO_REWARD_BTN2 then -- 圖鑑獎勵
            require("HeroBioPage")
            isShow = HeroBioPage_calIsShowRedPoint(group)
        elseif pageId == RedPointManager.PAGE_IDS.HERO_FETTER_BTN then -- 羈絆解鎖
            require("NgHeroPageManager")
            isShow = NgHeroPageManager_calIsShowRedPoint(group)
        elseif pageId == RedPointManager.PAGE_IDS.BATTLE_TREASURE_BTN then -- 掛機寶箱
            require("NgBattlePage")
            isShow = NgBattlePageInfo_calIsShowRedPoint(option)
        elseif pageId == RedPointManager.PAGE_IDS.BATTLE_FAST_BTN then -- 快速戰鬥
            require("NgBattleExpressPage")
            isShow = NgBattleExpressPage_calIsShowRedPoint()
        elseif pageId == RedPointManager.PAGE_IDS.DUNGEON_REWARD_BTN then -- 地下城領獎
            require("Dungeon.DungeonSubPage_Event")
            isShow = DungeonPageBase_calCanReward(group)
        elseif pageId == RedPointManager.PAGE_IDS.DUNGEON_CHALLANGE_BTN then -- 地下城挑戰
            require("Dungeon.DungeonSubPage_Event")
            isShow = DungeonPageBase_calCanChallange(group)
        elseif pageId == RedPointManager.PAGE_IDS.GRAIL_HOLY_BTN then -- 忍之聖所
            require("Leader.LeaderSubPage_HolyGrail")
            RedPointManager.tempData[pageId] = RedPointManager.tempData[pageId] or { }
            RedPointManager.tempData[pageId][1] = option or RedPointManager.tempData[pageId][1]
            local _isShow, _group = HolyGrailPageBase_calIsShowRedPoint(RedPointManager.tempData[pageId][1])
            isShow = _isShow
            group = 1
        elseif pageId == RedPointManager.PAGE_IDS.GRAIL_ELEMENT_BTN then -- 屬性聖所
            require("Leader.LeaderSubPage_Element")
            local _isShow, _group = false, nil
            RedPointManager.tempData[pageId] = RedPointManager.tempData[pageId] or { }
            if group then   -- 非初始化
                _isShow, _group = ElementStarPageBase_calIsShowRedPoint(RedPointManager.tempData[pageId][group])
            else
                _isShow, _group = ElementStarPageBase_calIsShowRedPoint(option)
                RedPointManager.tempData[pageId][_group] = option
            end
            isShow = _isShow
            group = _group
        elseif pageId == RedPointManager.PAGE_IDS.GRAIL_CLASS_BTN then -- 職業聖所
            require("Leader.LeaderSubPage_Class")
            local _isShow, _group = false, nil
            RedPointManager.tempData[pageId] = RedPointManager.tempData[pageId] or { }
            if group then   -- 非初始化
                _isShow, _group = ClassStarPageBase_calIsShowRedPoint(RedPointManager.tempData[pageId][group])
            else
                _isShow, _group = ClassStarPageBase_calIsShowRedPoint(option)
                RedPointManager.tempData[pageId][_group] = option
            end
            isShow = _isShow
            group = _group
        elseif pageId == RedPointManager.PAGE_IDS.WEAPON_ALL_BTN or
               pageId == RedPointManager.PAGE_IDS.CHEST_ALL_BTN or
               pageId == RedPointManager.PAGE_IDS.RING_ALL_BTN or
               pageId == RedPointManager.PAGE_IDS.FOOT_ALL_BTN then -- 一鍵鍛造
            require("EquipBuildPage")
            isShow = EquipBuildPage_calIsShowTypeRedPoint(pageId, group)
        elseif pageId == RedPointManager.PAGE_IDS.WEAPON_ONE_ICON or
               pageId == RedPointManager.PAGE_IDS.CHEST_ONE_ICON or
               pageId == RedPointManager.PAGE_IDS.RING_ONE_ICON or
               pageId == RedPointManager.PAGE_IDS.FOOT_ONE_ICON then -- 裝備Icon
            require("EquipBuildPage")
            isShow = EquipBuildPage_calIsShowIconRedPoint(pageId - 1, group)
        elseif pageId == RedPointManager.PAGE_IDS.MYSTERY_FREE_BTN or -- 神秘商店免費商品
               pageId == RedPointManager.PAGE_IDS.MYSTERY_REFRESH_BTN then -- 神秘商店免費刷新
            require("Shop.ShopSubPage_Mystery")
            isShow = ShopSubPage_Mestrey_calIsShowRedPoint(pageId, option)
        elseif pageId == RedPointManager.PAGE_IDS.DAILY_REWARD_BTN or -- 每日禮包
               pageId == RedPointManager.PAGE_IDS.WEEKLY_REWARD_BTN or -- 每周禮包
               pageId == RedPointManager.PAGE_IDS.MONTHLY_REWARD_BTN then -- 每月禮包
            require("IAP.IAPSubPage_Recharge")
            isShow = DiscountGiftPage_calIsShowRedPoint(pageId, option)
        elseif pageId == RedPointManager.PAGE_IDS.PACKAGE_AW_ICON then -- 專武碎片
            local UserItemManager = require("Item.UserItemManager")
            local InfoAccesser = require("Util.InfoAccesser")
            local itemIds = UserItemManager:getItemIdsByType(19)
            for i = 1, #itemIds do
                local _isShow, _group = false, nil
                _isShow = InfoAccesser:getAncientPieceCanFusion(itemIds[i])
                _group = itemIds[i]
                RedPointManager_setShowRedPoint(pageId, _group, _isShow)
            end
            return
        end
    end
    RedPointManager_setShowRedPoint(pageId, group, isShow)
end

--[[ 設定 特定UI 是否有紅點 ]]
function RedPointManager_setShowRedPoint(pageId, _type, isShow)
    if not tonumber(pageId) then
        return
    end
    RedPointManager.AllPageData[pageId][_type] = RedPointManager.AllPageData[pageId][_type] or { }
    local isChange = (RedPointManager.AllPageData[pageId][_type].show  ~= isShow)
    RedPointManager.AllPageData[pageId][_type].show = isShow
    if isChange then
        -- 發送刷新紅點訊息
        local msg = MsgRefreshRedPoint:new()
	    MessageManager:getInstance():sendMessageForScript(msg)
        -- 刷新主按鈕紅點
        MainFrame_refreshAllRedPoint()
    end
end

return RedPointManager