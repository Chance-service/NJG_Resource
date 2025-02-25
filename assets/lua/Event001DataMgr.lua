local Const = require('Const_pb')
local Event001DataMgr =  { 
    [Const_pb.ACTIVITY191_CycleStage] = {
        MAINPAGE_CCB = "NGEvent_001_Main.ccbi",
        BATTLEPAGE_CCB = "NGEvent_001_Page.ccbi",
        BATTLEPAGE_CONTENT_CCB = "NGEvent_001_PageContent.ccbi",
        MISSION_CONTENT_CCB = "NGEvent_001_EventMissionContent.ccbi",   -- 共用
        MISSION_TREASURE_CONTENT_NAME = "NGEvent_001_DailyContent",
        REWARD_POPUP_CCB = "NGEvent_002_Main_Card.ccbi",    -- event001沒有
        BATTLE_BG_IMG = "BG/NGEvent_001/Event001_Img02_02.png",
        STORY_BG_IMG = "BG/NGEvent_001/AlbumReview_001_Event.png",
        MAIN_ENTRY_IMG = "Lobby_BannerE001.png",
        TOKEN_ID = 7002,  -- 循環活動2代幣ID
        CHALLANGE_ID = 7003,  -- 循環活動2挑戰體力ID
        STAGE_CFG = ConfigManager:get191StageCfg(),
        FETTER_CONTROL_CFG = ConfigManager:getEvent001ControlCfg(),
        FETTER_MOVEMENT_CFG = ConfigManager:getEvent001ActionCfg(),
        MAIN_SPINE = "NGEvent_01_E001Title",
        REWARD_EQUIP_ID = 12501,
        REWARD_EQUIP_IMG = "BG/NGEvent_001/Event001_mission_img10.png",
        --
        openTouchLayer = false,
    },
    [Const_pb.ACTIVITY196_CycleStage_Part2] = {
        MAINPAGE_CCB = "NGEvent_002_Main.ccbi",
        BATTLEPAGE_CCB = "NGEvent_002_Page.ccbi",
        BATTLEPAGE_CONTENT_CCB = "NGEvent_002_PageContent.ccbi",
        MISSION_CONTENT_CCB = "NGEvent_001_EventMissionContent.ccbi",   -- 共用
        MISSION_TREASURE_CONTENT_NAME = "NGEvent_002_DailyContent",
        REWARD_POPUP_CCB = "NGEvent_002_Main_Card.ccbi",
        BATTLE_BG_IMG = "BG/NGEvent_002/Event002_Img02_02.png",
        STORY_BG_IMG = "BG/NGEvent_002/AlbumReview_002_Event.png",
        MAIN_ENTRY_IMG = "Lobby_BannerE002.png",
        TOKEN_ID = 6999,  -- 循環活動代幣ID
        CHALLANGE_ID = 7000,  -- 循環活動挑戰體力ID
        STAGE_CFG = ConfigManager:get196StageCfg(),
        FETTER_CONTROL_CFG = ConfigManager:getEvent001Control196Cfg(),
        FETTER_MOVEMENT_CFG = ConfigManager:getEvent001Action196Cfg(),
        MAIN_SPINE = "NGEvent_02_E002Title",
        REWARD_EQUIP_ID = 10101,
        REWARD_EQUIP_IMG = "BG/NGEvent_002/Event002_Img06.png",
        --
        openTouchLayer = true,
    }
}
Event001DataMgr.nowActivityId = 0

return Event001DataMgr