local InfoAccesser = require("Util.InfoAccesser")
local ServerData = {}
local Inst = {}

-- 定義各類獎勵類型
Inst.RewardType = {
    HERO = 1,           -- type 7 英雄碎片
    AW_EQUIP = 2,       -- type 3 專武碎片
    ITEM = 3,           -- type 3 一般道具
    EQUIP = 4,          -- type 4 裝備
    PLAYER_ATTR = 5,    -- type 1 玩家屬性
    RUNE = 6,           -- type 9 符石
}

-- 完整的專武 需要多少碎片 
Inst.FULL_EQUIP_REWARD_PIECE_COUNT = 9999

-- 固定子頁面配置
Inst.SubPageCfgs = { }
--初始Table
Inst.OriginTable = {
    {
        subPageName = "Premium",
        scriptName = "Summon.SummonSubPage_Normal",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_SummonPremium.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_SummonPremium_On.png",
        title = "@Summon.Premium.title",
        currencyInfos = {
            { priceStr = "10000_1001_0" },
            { priceStr = "30000_6004_0" },
        },
        ccbiFile = "Summon_Premium.ccbi",
        spineSummon = "Spine/NGUI,NGUI_53_Gacha1Summon",
        spineBG = "Spine/NGUI,NGUI_53_Gacha1Summon_BG",
        spineAnimName_bg_idle = "wait",
        spineAnimName_bg_summon = "summon",
        spineAnimName_summon_idle = "wait",
        spineAnimName_summon_summon_list = {
            "summonN",
            "summonSR",
            "summonSSR",
        },
        isFreeSummonAble = true,
        Help = "HELP_NORMALSUMMON",
        summonBgm = "normal_summon_bgm.mp3",
        isRedOn = function() 
            return RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.SUMMON_NORMAL_TAB)
        end,
        activityID = 146,
    },
    {
        subPageName = "Arm",
        scriptName = "Summon.SummonSubPage_Arm",
        iconImg_normal = "SubBtn_SummonAWS.png",
        iconImg_selected = "SubBtn_SummonAWS_On.png",
        title = "@Summon.Weapon.title",
        currencyInfos = {
            { priceStr = "10000_1001_0" },
            { priceStr = "30000_6004_0" },
        },
        ccbiFile = "Summon_Memory.ccbi",
        spineSummon = "Spine/NGUI,NGUI_53_Gacha1Summon",
        spineBG = nil,
        spineAnimName_bg_idle = "",
        spineAnimName_bg_summon = "",
        spineAnimName_summon_idle = "wait",
        spineAnimName_summon_summon_list = {
            "summonMemory",
            "summonMemory",
            "summonMemory"
        },
        Help = "HELP_AW_SUMMON",
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.ANCIENT_WEAPON,
        summonBgm = "friend_summon_bgm.mp3",
        activityID = 178,
    },
    {
        subPageName = "Friend",
        scriptName = "Summon.SummonSubPage_Friend",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_FriendSummon.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_FriendSummon_On.png",
        title = "@Summon.Friend.title",
        currencyInfos = {
            { priceStr = "10000_1025_0" },
        },
        ccbiFile = "Summon_Friend.ccbi",
        spineSummon = "Spine/NGUI,NGUI_53_Gacha2Summon",
        spineBGs = {
            "Spine/Bg/LoginBG,LoginBG02",
            "Spine/Bg/LoginBG,LoginBG04",   
            "Spine/Bg/LoginBG,LoginBG05",
        },
        spineAnimName_bg_idle = "animation3",
        spineAnimName_bg_summon = "animation4",
        spineAnimName_summon_idle = "wait",
        spineAnimName_summon_summon = "sumon",
        Help = "HELP_FRIENDSUMMON",
        summonBgm = "friend_summon_bgm.mp3",
        activityID = 166,
    },
    {
        subPageName = "Faction",
        scriptName = "Summon.SummonSubPage_Faction",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_FactSummon.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_FactSummon_On.png",
        title = "@Summon.Faction.title",
        currencyInfos = {
            { priceStr = "30000_6003_0" },
        },
        ccbiFile = "Summon_Faction.ccbi",
        spineAnimName_idle = "wait",
        spineAnimName_select = "select",
        spineAnimName_summon = "summon",
        summonType2Times = {
            [1] = 1,
            [2] = 5,
        },
        summonType2Action = {
            [1] = 1,
            [2] = 2,
        },
        faction2PriceDatas = {
            [1] = {"30000_6003_1", "30000_6003_5"},
            [2] = {"30000_6003_1", "30000_6003_5"},
            [3] = {"30000_6003_1", "30000_6003_5"},
            [4] = {"30000_6003_1", "30000_6003_5"},
            [5] = {"30000_6003_1", "30000_6003_5"},
        },
        faction2Milestone = {
            [1] = 1000,
            [2] = 1000,
            [3] = 1000,
            [4] = 2000,
            [5] = 2000,
        },
        spineSummon = "Spine/NGUI,NGUI_53_Gacha3Summon",
        Help = "HELP_FACTIONSUMMON",
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.SUMMON_FACTION,
        summonBgm = "Faction_summon_bgm.mp3",
        activityID = 158,
    },
}
--------------------------------------------------------------------------------
-- 輔助函數：建立 PickUp 子頁面配置
--------------------------------------------------------------------------------
local function createPickUpConfig(openId, cfgData, actId)
    local ticket = ServerData[openId].ticket or ""
    local currencyInfos
    if ticket == "" then
        currencyInfos = { { priceStr = "10000_1001_0" } }
    else
        currencyInfos = { { priceStr = "10000_1001_0" }, { priceStr = ticket } }
    end

    return {
        subId = openId,
        _closePlusBtn = true,
        subPageName = "PickUp" .. openId,
        data = cfgData,
        scriptName = "Summon.SummonSubPage_PickUp",
        iconImg_normal = "Imagesetfile/i18n_Button/" .. cfgData.TabImg .. ".png",
        iconImg_selected = "Imagesetfile/i18n_Button/" .. cfgData.TabImg .. "_On.png",
        title = cfgData.Title,
        useItem = ticket,
        currencyInfos = currencyInfos,
        ccbiFile = "Summon_Pickup.ccbi",
        spineSummon = cfgData.summonSpine,
        spineBG =  cfgData.spine,
        spineAnimName_bg_idle = "animation",
        spineAnimName_bg_summon = "animation",
        spineAnimName_summon_idle = "wait",
        spineAnimName_summon_summon_list = { "summonN", "summonSR", "summonSSR" },
        isFreeSummonAble = true,
        Help = "HELP_PICKUPSUMMON",
        summonBgm = "pickup_summon_bgm.mp3",
        activityID = actId,
    }
end

--------------------------------------------------------------------------------
-- 根據活動狀態動態插入 PickUp 配置到子頁面列表前端
--------------------------------------------------------------------------------
function Inst:setSubPageConfigs()
    local newPickActId = 197
    if not ActivityInfo:getActivityIsOpenById(newPickActId) then
        return
    end
    Inst.SubPageCfgs = {}
    Inst.SubPageCfgs = common:deepCopy(Inst.OriginTable)
    require("Summon.SummonPickUpData")
    ServerData = SummonPickUpDataBase_getData()

    local openIds = {}
    for openId in pairs(ServerData) do
        table.insert(openIds, openId)
    end
    -- 如有需要，可對 openIds 進行排序：table.sort(openIds)

    local otherCfg = ConfigManager.getPickUpCfg_New()

    for index, openId in ipairs(openIds) do
    local cfgData = otherCfg[openId]
        if cfgData then
            local pickupCfg = createPickUpConfig(openId, cfgData, newPickActId)
            -- 檢查是否已存在相同 subPageName 的配置
            if not Inst:getSubPageCfg(pickupCfg.subPageName) then
                table.insert(Inst.SubPageCfgs, index, pickupCfg)
            end
        end
    end

end

--------------------------------------------------------------------------------
-- 根據子頁面名稱取得配置
--------------------------------------------------------------------------------
function Inst:getSubPageCfg(subPageName)
    for _, cfg in ipairs(Inst.SubPageCfgs) do
        if cfg.subPageName == subPageName then
            return cfg
        end
    end
    return nil
end

return Inst
