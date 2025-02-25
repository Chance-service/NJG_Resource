----------------------------------------------------------------------------------
--[[
	奖励预览
--]]
----------------------------------------------------------------------------------

local thisPageName = "NewSnowPreviewRewardPage"
local NewSnowPreviewRewardPageBase = { }
local NewSnowPreviewRewardCommonItem = { }
local NewSnowPreviewRewardluckyItem = { }

local option = {
    ccbiFile = "Act_LoadTreasureRewardPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp"
    }
}

local NodeHelper = require("NodeHelper");
-- local NewSnowInfoData = require("Activity.NewSnowInfoData")
local subTitle1 = ""
local subTitle2 = ""

local commonRewardItems = { }
local luckyRewardItems = { }
local helpKey = ""
local closeHelp = false
local NewSnowPreviewRewardItemCCBI = {
    ccbiFile = "Act_LoadTreasureRewardItem.ccbi"
}

function NewSnowPreviewRewardPageBase:onEnter(container)

    -- 初始化当前排名ScrollView
    NodeHelper:initScrollView(container, "mContent1", 4)

    container.mScrollView2 = container:getVarScrollView("mContent2");
    if container.mScrollView2 ~= nil then
        -- 初始化scrollview
        container.mScrollViewRootNode2 = container.mScrollView2:getContainer();
        container.m_pScrollViewFacade2 = CCReViScrollViewFacade:new_local(container.mScrollView2);
        container.m_pScrollViewFacade2:init(8, 3);
    end
    self:refreshPreviewPage(container);
    local relativeNode = container:getVarNode("mContentBg")
    GameUtil:clickOtherClosePage(relativeNode, function()
        self:onClose(container)
    end , container)

    NodeHelper:setNodesVisible(container, { mHelpBtn = not closeHelp })
end

function NewSnowPreviewRewardPageBase:refreshPreviewPage(container)
    NodeHelper:setStringForLabel(container, {
        mCommonTxt = subTitle2,
        mLuckyTxt = subTitle1
    } )
    self:rebuildAllItem(container)
end

function NewSnowPreviewRewardPageBase:rebuildAllItem(container)
    self:clearAllItem(container);
    self:buildItem(container);
end

function NewSnowPreviewRewardPageBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
    if container.m_pScrollViewFacade2 then
        container.m_pScrollViewFacade2:clearAllItems();
    end
    if container.mScrollViewRootNode2 then
        container.mScrollViewRootNode2:removeAllChildren();
    end
end

function NewSnowPreviewRewardPageBase:buildItem(container)
    local size1 = #commonRewardItems
    local rewardNum = math.ceil(size1 / 4)
    NodeHelper:buildScrollView(container, rewardNum, NewSnowPreviewRewardItemCCBI.ccbiFile, NewSnowPreviewRewardCommonItem.onFunction)

    local size2 = #luckyRewardItems
    local rewardNum2 = math.ceil(size2 / 4)
    NodeHelper:buildScrollView2(container, rewardNum2, NewSnowPreviewRewardItemCCBI.ccbiFile, NewSnowPreviewRewardluckyItem.onFunction)
end

function NewSnowPreviewRewardPageBase:onClose(container)
    helpKey = ""
    commonRewardItems = { }
    luckyRewardItems = { }
    PageManager.popPage(thisPageName);
end

function NewSnowPreviewRewardPageBase:onHelp(container)

    if helpKey ~= "" then
        PageManager.showHelp(helpKey)
        -- helpKey = ""
    end
    if GameConfig.isIOSAuditVersion then

    end
end

function NewSnowPreviewRewardCommonItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        NewSnowPreviewRewardCommonItem.onRefreshItemView(container);
    elseif eventName:sub(1, 7) == "onFrame" then
        local index = container:getItemDate().mID
        local rewardIndex = tonumber(string.sub(eventName, -1))

        GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), commonRewardItems[(index * 4 - 4) + rewardIndex])

--        if index == 1 then
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), commonRewardItems[rewardIndex])
--        else
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), commonRewardItems[4 + rewardIndex])
--        end
    end
end

function NewSnowPreviewRewardluckyItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        NewSnowPreviewRewardluckyItem.onRefreshItemView(container);
    elseif eventName:sub(1, 7) == "onFrame" then
        local index = container:getItemDate().mID
        local rewardIndex = tonumber(string.sub(eventName, -1))
       
        GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), luckyRewardItems[(index * 4 - 4) + rewardIndex])

--        if index == 1 then
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), luckyRewardItems[rewardIndex])
--        elseif index == 2 then
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), luckyRewardItems[4 + rewardIndex])
--        elseif index == 3 then
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), luckyRewardItems[8 + rewardIndex])
--        elseif index == 4 then
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), luckyRewardItems[12 + rewardIndex])
--        elseif index == 5 then
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), luckyRewardItems[16 + rewardIndex])
--        elseif index == 6 then
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), luckyRewardItems[20 + rewardIndex])
--        elseif index == 7 then
--            GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), luckyRewardItems[24 + rewardIndex])
--        end
    end
end

function NewSnowPreviewRewardCommonItem.onRefreshItemView(container)
    local contentId = container:getItemDate().mID
    local commonRewardItems1 = { }
    local beginIndex = contentId * 4 - 4 + 1
    for i = beginIndex, beginIndex + 3 do
        table.insert(commonRewardItems1, commonRewardItems[i])
    end
    NodeHelper:fillRewardItem(container, commonRewardItems1)
end

function NewSnowPreviewRewardluckyItem.onRefreshItemView(container)
    local contentId = container:getItemDate().mID
    local beginIndex = contentId * 4 - 4 + 1
    local luckyRewardItems1 = { }
    for i = beginIndex, beginIndex + 3 do
        table.insert(luckyRewardItems1, luckyRewardItems[i])
    end
    NodeHelper:fillRewardItem(container, luckyRewardItems1)
end


-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
NewSnowPreviewRewardPage = CommonPage.newSub(NewSnowPreviewRewardPageBase, thisPageName, option)

function NewSnowPreviewRewardPage_SetConfig(reward1, reward2, titleStr1, titleStr2, key, isUseBigPage, isCloseHelp)
    helpKey = key or ""
    commonRewardItems = reward1
    luckyRewardItems = reward2
    closeHelp = isCloseHelp or false
    
    subTitle1 = common:getLanguageString(titleStr1 or "")
    subTitle2 = common:getLanguageString(titleStr2 or "")

    if #commonRewardItems > 4 or #luckyRewardItems > 4 then
        if isUseBigPage then
            option.ccbiFile = "Act_LoadTreasureRewardPopUp_New.ccbi"
        else
            option.ccbiFile = "Act_LoadTreasureRewardPopUp.ccbi"
        end
        NewSnowPreviewRewardItemCCBI.ccbiFile = "Act_LoadTreasureRewardItem.ccbi"
    else
        option.ccbiFile = "RaidRewardLookUpPopUp.ccbi"
        NewSnowPreviewRewardItemCCBI.ccbiFile = "Act_LoadTreasureRewardItem2.ccbi"
    end
end