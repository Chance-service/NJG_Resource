local SingleBossDataMgr = require("SingleBoss.SingleBossDataMgr")
local CONST = require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")

local thisPageName = "SingleBoss.SingleBossPopResult"

local option = {
    ccbiFile = "SingleBoss_BattleResultPopup.ccbi",
    handlerMap =
    {
        onClose = "onClose",
    },
    opcode = { }
}

local SingleBossPopResult = { }

local data = SingleBossDataMgr:getPageData()
-----------------------------------
function SingleBossPopResult:onEnter(container)
    self:refreshPage(container)
end

function SingleBossPopResult:onClose(container)
    PageManager.popPage(thisPageName)
end

function SingleBossPopResult:refreshPage(container)
    NodeHelper:setStringForLabel(container, {
        mPointTxt = common:getLanguageString("@SingleBossPoint", GameUtil:formatDotNumber(NewBattleUtil:getSingleBossScore())),
    })
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS then
        NodeHelper:setStringForLabel(container, {
            mBestPointTxt = GameUtil:formatDotNumber(math.max(tonumber(NewBattleUtil:getSingleBossScore()), tonumber(data.maxScore)))
        })
        NodeHelper:setNodesVisible(container, { mTipTxt = false })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        NodeHelper:setStringForLabel(container, {
            mBestPointTxt = GameUtil:formatDotNumber(tonumber(data.maxScore))
        })
        NodeHelper:setNodesVisible(container, { mTipTxt = true })
    end
end

local CommonPage = require('CommonPage')
local SingleBossPopResult = CommonPage.newSub(SingleBossPopResult, thisPageName, option)
