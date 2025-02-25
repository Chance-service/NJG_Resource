local CONST = require("Battle.NewBattleConst")
require("Battle.NgBattleDataManager")

local thisPageName = "NgBattlePausePage"
local option = {
    ccbiFile = "BattlePagePause.ccbi",
    handlerMap =
    {
        onExit = "onExitPage",
        onRestart = "onRestart",
        onContinue = "onContinue",

        onTestLog = "onTestLog",
        onTestDps = "onTestDps",
    }
}

local NgBattlePausePage = { }

function NgBattlePausePage:onEnter(container)
    container:registerLibOS()
    NodeHelper:setNodesVisible(container, { mTestDpsNode = libOS:getInstance():getIsDebug(), mTestLogNode = libOS:getInstance():getIsDebug() })
end

function NgBattlePausePage:onExitPage(container)
    NgBattleDataManager_setBattleIsPause(false)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        require("Battle.NgBattlePage")
        NgBattlePageInfo_restartAfk(NgBattleDataManager.battlePageContainer)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(48)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(21)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(45)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(49)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(51)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
        require("Battle.NgBattlePage")
        NgBattlePageInfo_restartAfk(NgBattleDataManager.battlePageContainer)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(52)
     elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(53)
    end
    PageManager.popPage(thisPageName)
end

function NgBattlePausePage:onRestart(container)
    NgBattleDataManager_setBattleIsPause(false)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
        require("SpineTouchEdit")
        PageManager.pushPage("SpineTouchEdit")
    else
        require("Battle.NgBattlePage")
        NgBattlePageInfo_onRestartBoss(container)
    end
    PageManager.popPage(thisPageName)
end

function NgBattlePausePage:onContinue(container)
    local sceneHelper = require("Battle.NgFightSceneHelper")
    NgBattleDataManager_setBattleIsPause(false)
    sceneHelper:setSceneSpeed(NgBattleDataManager.battleSpeed)
    PageManager.popPage(thisPageName)
end

function NgBattlePausePage:onTestLog()
    PageManager.pushPage("BattleLogPage")
end

function NgBattlePausePage:onTestDps()
    PageManager.pushPage("BattleLogDpsPage")
end

local CommonPage = require("CommonPage")
local PausePage = CommonPage.newSub(NgBattlePausePage, thisPageName, option)

return PausePage