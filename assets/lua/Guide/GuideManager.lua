----------------------------------------------------------------------------------
local GuideManager = { }
local UserInfo = require("PlayerInfo.UserInfo")
local Guide_pb = require("Guide_pb")
require("MainFrameScript")
require("Battle.NgBattleDataManager")
GuideManager.currGuide = { }
GuideManager.guideType = {
    NEWBIE_GUIDE = 1,
    AUTO_SKILL = 2,
    EDIT_TEAM_17 = 3,
    DUNGEON = 4,
    --RARITY_UP = 5,
    MISSION = 6,
    SUMMON = 7,
    RUNE = 8,
    ARENA = 9,
    BOUNTY = 10,
    FUSION = 11,
    GRAIL = 12,
    DUNGEON_2 = 13,
    ANCIENT_WEAPON = 14,
    SECRET_MESSAGE = 15,
    FAST_BATTLE = 16,
    GLORY_HOLE = 17,
    --
    MAX_NUM = 17,
}

GuideManager.PageContainerRef = { }
GuideManager.PageInstRef = { }
GuideManager.IsNeedShowPage = false     -- 開啟某頁面中,頁面回應後關閉
GuideManager.isInGuide = false           -- 是不是正在新手引导   true = 是   false = 不是 ,會檢查是否需要導引
GuideManager.currGuideType = 0

GuideManager.stepBaseIdx = 10000

GuideManager.tempMsg = { }

local NewbieGuideCfg = ConfigManager.getNewbieGuideCfg()
-----------------------------------------------------------------------------
function GuideManager.getCurrentStep()
    return GuideManager.currGuide[GuideManager.currGuideType]
end

function GuideManager.getCurrentCfg()
    return NewbieGuideCfg[GuideManager.getCurrentStep()]
end

function GuideManager.getStepCfgByIndex(guideType, idx)
    return GuideManager.getCurrentCfg()
end
-- 設定下一步驟
function GuideManager.setNextNewbieGuide()
    CCLuaLog("----setNextNewbieGuide : " .. GuideManager.currGuide[GuideManager.currGuideType])
    local cfg = NewbieGuideCfg[GuideManager.currGuide[GuideManager.currGuideType]]
    if cfg then
        GuideManager.currGuide[GuideManager.currGuideType] = cfg.nextStep
        CCLuaLog("----setNextNewbieGuide Next : " .. cfg.nextStep)
    else
        GuideManager.currGuide[GuideManager.currGuideType] = 0
    end
end
-- 傳送教學進度
function GuideManager:setStepPacket(typeId, step)
    local msg = Guide_pb.HPResetGuideInfo()
    msg.guideInfoBean.guideId = typeId
    msg.guideInfoBean.step = step
    common:sendPacket(HP_pb.RESET_GUIDE_INFO_C, msg, false)
end
-- 強制到下一步驟
function GuideManager.forceNextNewbieGuide()
    GuideManager.setNextNewbieGuide()
    GuideManager:setStepPacket(GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
    PageManager.popPage("NewbieGuideForcedPage")
    PageManager.pushPage("NewbieGuideForcedPage")
end
-- 檢查新手戰鬥進入下一步驟
function GuideManager.checkGuideBattleCanNextStep(tag)
    local cfg = NewbieGuideCfg[GuideManager.currGuide[GuideManager.currGuideType]]
    if not cfg then
        return false
    end
    if (cfg.showType == GameConfig.GUIDE_TYPE.OPEN_MASK_WAIT_BATTLE_ANI) and 
       (tonumber(cfg.funcParam) == tag) then
        return true
    end
end
-- 新手引导
function GuideManager.newbieGuide()
    if EFUNSHOWNEWBIE() == false then
        return
    end

    if GuideManager.isInGuide == true then return end

    -- step為0時表示已跑完該type
    local currStepIdx = GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE]
    if currStepIdx == 0 then
        -- 測試用
        --GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] = 11751
        --currStepIdx = 11751
        GuideManager.openOtherGuideFun()
        return
    end
    if currStepIdx ~= 0 then
        if currStepIdx == nil or NewbieGuideCfg[currStepIdx].guideType ~= GuideManager.guideType.NEWBIE_GUIDE then
            GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] = GuideManager.guideType.NEWBIE_GUIDE * GuideManager.stepBaseIdx + 1
        else
            GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] = NewbieGuideCfg[currStepIdx].interruptStep
        end
        GuideManager.currGuideType = GuideManager.guideType.NEWBIE_GUIDE
        GuideManager.isInGuide = true
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    CCLuaLog("currGuideType : " .. GuideManager.guideType.NEWBIE_GUIDE .. ", currStepIdx : " .. GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE])
end
---------------------------------------------------------------------------------------------------
-- 非新帳號教學檢查
function GuideManager.openOtherGuideFun(triggerType, isEnterMainScene)
    if EFUNSHOWNEWBIE() == false then
        return
    end
    if GuideManager.isInGuide then
        return
    end
    if not triggerType or triggerType == GuideManager.guideType.NEWBIE_GUIDE then
        return
    end
    if not NewbieGuideCfg[triggerType] then
        return
    end
    if NewbieGuideCfg[triggerType].guideType ~= 0 then  -- 不是解鎖條件設定
        return
    end
    local unlockMap = NewbieGuideCfg[triggerType].nextStep  -- 解鎖關卡
    local isMainScene = NewbieGuideCfg[triggerType].interruptStep   -- 是否從大廳強制引導

    if isMainScene ~= 1 and isEnterMainScene then   -- 不需從大廳開始引導
        return
    end

    if triggerType == GuideManager.guideType.ANCIENT_WEAPON then
        if UserInfo.serverId == 1 or UserInfo.serverId == 2 then    -- 舊server玩家特殊處理
            GuideManager.currGuide[GuideManager.guideType.ANCIENT_WEAPON] = 0
            GuideManager:setStepPacket(GuideManager.guideType.ANCIENT_WEAPON, 0)
            return
        end
    end

    -- 測試用
    --if triggerType == GuideManager.guideType.ANCIENT_WEAPON then
    --    GuideManager.currGuide[triggerType] = 140051
    --end

    if UserInfo.stateInfo.passMapId >= unlockMap and GuideManager.currGuide[triggerType] ~= 0 then
        local step = GuideManager.currGuide[triggerType]
        if step == nil then -- 還沒有記錄過
            GuideManager.currGuide[triggerType] = triggerType * GuideManager.stepBaseIdx + 1   -- 從第一步開始
        elseif NewbieGuideCfg[step] == nil or -- 紀錄的step跟表格type不相符/表格沒有設定
               NewbieGuideCfg[step].guideType ~= triggerType then
            GuideManager.currGuide[triggerType] = 0 -- 紀錄教學已完成
        else
            GuideManager.currGuide[triggerType] = NewbieGuideCfg[step].interruptStep    -- 從中斷的步驟開始
        end
        if GuideManager.currGuide[triggerType] ~= 0 then
            GuideManager.currGuideType = triggerType
            GuideManager.isInGuide = true
            PageManager.pushPage("NewbieGuideForcedPage")
            return
        end
    end
end
------------------------------------------------------------------------------
-- 新手教學type7使用function
function GuideManager.callFunc(container, currentType, currentStep)
    local cfg = GuideManager.getStepCfgByIndex(currentType, currentStep)
    if GuideManager[cfg.func] then
        local func = GuideManager[cfg.func];
        if cfg.funcParam then
            GuideManager[cfg.func](GuideManager, container, tonumber(cfg.funcParam))
        else
            GuideManager[cfg.func](GuideManager, container)
        end
    end
end
function GuideManager:onGuideFight(container)
    resetMenu("mBattlePageBtn", true)
    UserInfo.sync()
    require("NewBattleConst")
    require("NgBattleDataManager")
    NgBattleDataManager_setBattleType(NewBattleConst.SCENE_TYPE.GUIDE)
    PageManager.changePage("NgBattlePage")
end
function GuideManager:onGuideBossSkill(container)
    require("NgBattlePage")
    NgBattlePageInfo_useCardSkill(14)
end
function GuideManager:onGuideMainScene(container)
    MainFrame_onMainPageBtn(false)
end

return GuideManager