

local thisPageName = "AchievementRewardPage"
local NodeHelper = require("NodeHelper")
local AchievementManager = require("PlayerInfo.AchievementManager")
local AchievementStepRewardCfg = ConfigManager.getAchievementStepRewardCfg()
local AchievementRewardPageBase = {}

local option ={
    ccbiFile = "NewPeopleTeakReceiveRewardPopUp.ccbi",
    handlerMap = {
        onTheAward = "onReward",
        onClose = "onClose",
        onFrame1 = "showTips",
        onFrame2 = "showTips",
        onFrame3 = "showTips"
    }
}

local rewardItem = {}

function AchievementRewardPageBase:onEnter(container)
    rewardItem = AchievementStepRewardCfg[AchievementManager.AchievementState]
    if rewardItem == nil or rewardItem == {} then return end
    self:refreshPage(container)
end

function AchievementRewardPageBase:refreshPage(container)
    local progressNum = AchievementManager:calCurFinishedNum()
    NodeHelper:setMenuItemEnabled(container,"mTheAward",progressNum == #AchievementManager.QuestList)
    local num = #rewardItem.reward 
    local nodesVisiable = {}
    for i = 1, 3 do
        nodesVisiable["mRewardNode"..i] = i == num
    end
    
    local param = {}
    param.mainNode = "mReward" .. num .. "-" 
    param.countNode = "mNum" .. num .. "-" 
    param.nameNode = "mName" .. num .. "-" 
    param.frameNode = "mFrame" .. num .. "-"
    param.picNode = "mPic" .. num .. "-" 

    NodeHelper:fillRewardItemWithParams(container, rewardItem.reward, num, param)
    NodeHelper:setNodesVisible(container, nodesVisiable)
end


function AchievementRewardPageBase:onReward(container)
    AchievementManager:stepReward()
    PageManager.popPage(thisPageName)
end

function AchievementRewardPageBase:showTips(container, eventName)
    local index = string.sub(eventName, -1)
    local num = #rewardItem.reward 
    GameUtil:showTip(container:getVarNode('mFrame'..num.."-"..index),rewardItem.reward[tonumber(index)])
end

function AchievementRewardPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

----------------------------------------------------------------
local CommonPage = require("CommonPage");
local AchievementRewardPage = CommonPage.newSub(AchievementRewardPageBase, thisPageName, option);
