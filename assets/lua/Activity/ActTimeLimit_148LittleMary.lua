local thisPageName = "ActTimeLimit_148LittleMary"
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity4_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb")
local ConfigManager = require("ConfigManager")
local UserItemManager = require("Item.UserItemManager")
local NewPlayerBasePage = require("NewPlayerBasePage")
local CONST = require("Battle.NewBattleConst")
require("Activity.ActivityInfo")

local ActTimeLimit_148LittleMary = {
    container = nil,
    timerName = "Activity_148_timerName"
}
--活動相關參數
local MARY_PARAS = {
    ITEM_NUM = 9,
    BG_SPINE_PATH = "Spine/Activity_143_sp_boxes",
    BG_SPINE_NAME = "Activity_143_sp_boxes",
    NOW_FRAME_INDEX = 0,
    BASE_SHOW_NUM = 25,
    SHOW_ROLE_ID = 1,
}
-- 協定相關參數
local REQUEST_TYPE = {
    SYNC = 0, -- 0.同步
    OPEN = 1, -- 1.抽獎
}
-- 遊戲狀態參數
local GAME_STATE = {
    ERROR = -1,
    SYNC_DATA = 0,
    STABLE = 1,
    REQUEST_REWARD = 2,
    PLAYING_ANI = 3,
    SHOW_REWARD = 4,
}
-- 玩家當前遊戲資料
local nowData = {
    allReward = "", -- 當前所有獎勵
    getReward = { },-- 已獲得獎勵
    nowReward = "", -- 該次獲得獎勵
    nowRewardId = 0,  -- 該次獲得獎勵Index
    leftTime = 0,   -- 活動剩餘時間
    costItem = "",  -- 抽獎消耗物品 
}

local option = {
    ccbiFile = "NewPlayer_littleMari.ccbi",
    handlerMap = {
        onDraw = "onDraw",
        onHelp = "onHelp",
        onHand = "onHand",
    },
    opcodes = {
        ACTIVITY148_C = HP_pb.ACTIVITY148_C,
        ACTIVITY148_S = HP_pb.ACTIVITY148_S,
    }
}

local nowState = GAME_STATE.SYNC_DATA
local items = { }
-------------------- reward item --------------------------------
local RewardItem = {
    ccbiFile = "BackpackItem.ccbi",
}

function ActTimeLimit_148LittleMary:onHand1(container)
    if nowData.allReward[container.id] then
        local itemType, id, itemCount = unpack(common:split(nowData.allReward[container.id], "_"))
        GameUtil:showTip(container:getVarNode("mAni1"), { type = tonumber(itemType), itemId = tonumber(id), count = tonumber(itemCount) })
    end
end
-------------------------------------------------------------
--------------------------------------------------------------------------------------
function ActTimeLimit_148LittleMary:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function ActTimeLimit_148LittleMary:onEnter(container)
    if not self.container or tolua.isnull(self.container) then
        self.container = ScriptContentBase:create(option.ccbiFile)
    end
    self.container:registerFunctionHandler(ActTimeLimit_148LittleMary.onFunction)
    NodeHelper:setNodesVisible(self.container, { mInfoNode = false })
    self:setGameState(container, GAME_STATE.SYNC_DATA)
    self:registerPacket(container)
    self:initRewardItem(self.container)
    self:initSpine(self.container)
    self:requestServerData(REQUEST_TYPE.SYNC)
    return self.container
end

function ActTimeLimit_148LittleMary:onExit(container)
    self:removePacket(container)
end
------------------------------------- 按鈕 ---------------------------------------------
-- 開始遊戲
function ActTimeLimit_148LittleMary:onDraw(container)
    --self:playShowRewardTest(container)
    if nowState ~= GAME_STATE.STABLE then
        return
    end
    ActTimeLimit_148LittleMary:requestServerData(REQUEST_TYPE.OPEN)
    self:setGameState(container, GAME_STATE.REQUEST_REWARD)
    self:refreshUI(self.container)
end
-- 規則說明
function ActTimeLimit_148LittleMary:onHelp(container)
    if nowState == GAME_STATE.PLAYING_ANI then
        return
    end
	PageManager.showHelp(GameConfig.HelpKey.HELP_LITTLEMARY)
end
-- 角色點擊
function ActTimeLimit_148LittleMary:onHand(container)
    local rolePage = require("NgArchivePage")
    PageManager.pushPage("NgArchivePage")
    rolePage:setMercenaryId(1)
    --NgArchivePage_setToSkin(false, 1)
end
----------------------------------------------------------------------------------
function ActTimeLimit_148LittleMary:onExecute(container)
    local remainTime = NewPlayerBasePage:getActivityTime()
    local timeStr = common:second2DateString5(remainTime, false)
    NodeHelper:setStringForLabel(self.container, { mTimerTxt = timeStr })
end
----------------------------------------------------------------------------------
-- spine初始化
function ActTimeLimit_148LittleMary:initSpine(container)
    local heroCfg = ConfigManager.getNewHeroCfg()[MARY_PARAS.SHOW_ROLE_ID]
    if heroCfg then
        local parentNode = container:getVarNode("mSpineNode")
        parentNode:removeAllChildrenWithCleanup(true)
        local spineFolder, spineName = unpack(common:split(heroCfg.Spine, ","))
        if not NodeHelper:isFileExist(spineFolder .. "/" .. spineName .. "000.skel") then
            return
        end
        local spine = SpineContainer:create(spineFolder, spineName .. "000")
        local spineNode = tolua.cast(spine, "CCNode")
        spine:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
        parentNode:addChild(spineNode)
    end
    -- BG
    local bg = self.container:getVarNode("mBg")
    local spineBg = SpineContainer:create("NG2D", "NG2D_01")
    local spineNodeBg = tolua.cast(spineBg, "CCNode")
    spineNodeBg:setScale(NodeHelper:getScaleProportion())
    spineBg:runAnimation(1, "animation", -1)
    bg:addChild(spineNodeBg)
end
-- 獎勵ccb初始化
function ActTimeLimit_148LittleMary:initRewardItem(container)
    items = { }
    for i = 1, MARY_PARAS.ITEM_NUM do
        local itemParentNode = container:getVarNode("mItem" .. i)
        itemParentNode:removeAllChildren()

        local itemCCB = ScriptContentBase:create(RewardItem.ccbiFile)
        if itemCCB then
            itemCCB:registerFunctionHandler(ActTimeLimit_148LittleMary.onFunction)
            itemCCB.id = i
            itemCCB:setAnchorPoint(ccp(0.5, 0.5))
            itemParentNode:addChild(itemCCB)
            table.insert(items, itemCCB)
        end
    end
end
-- 獲得獎勵演出
function ActTimeLimit_148LittleMary:playShowReward(container)
    if nowData.nowRewardId == 0 then
        self:refreshItem(container)
        self:refreshUI(self.container)
        self:setGameState(container, GAME_STATE.STABLE)
        return
    end
    local frameNode = self.container:getVarNode("mFrameNode")
    MARY_PARAS.NOW_FRAME_INDEX = 0
    local showArray = { }
    local delayTimeArray = { }
    local targetIndex = 0
    for i = 1, MARY_PARAS.ITEM_NUM do
        local isGet = false
        for j = 1, #nowData.getReward do
            if (i == nowData.getReward[j]) and (i ~= nowData.nowRewardId) then  -- 非當次獲得的獎項
                isGet = true
            end
        end
        if not isGet then
            table.insert(showArray, i)
            if i == nowData.nowRewardId then
                targetIndex = #showArray
            end
        end
    end
    local finalShowNum = MARY_PARAS.BASE_SHOW_NUM
    local baseIndex = (MARY_PARAS.BASE_SHOW_NUM % #showArray == 0) and #showArray or MARY_PARAS.BASE_SHOW_NUM % #showArray  -- 基礎次數轉到的index
    -- 基礎轉輪次數 + 需要再轉幾次可以到目標位置
    if baseIndex > targetIndex then    -- 需要到下一圈才能到目標位置
        finalShowNum = MARY_PARAS.BASE_SHOW_NUM + (#showArray - baseIndex + targetIndex)
    elseif baseIndex < targetIndex then
        finalShowNum = MARY_PARAS.BASE_SHOW_NUM + (targetIndex - baseIndex)
    end
    for i = 1, finalShowNum do
        if i == 1 then
            table.insert(delayTimeArray, 0)
        elseif i < MARY_PARAS.BASE_SHOW_NUM / 2 then
            table.insert(delayTimeArray, math.max(0.7 - i * 0.07, 0.1))
        else
            table.insert(delayTimeArray, math.max(0.1 + (7 - (finalShowNum - i)) * 0.07, 0.1))
        end
    end
    local action = CCArray:create()
    frameNode:stopAllActions()
    for i = 1, finalShowNum do
        action:addObject(CCDelayTime:create(delayTimeArray[i]))
        action:addObject(CCCallFunc:create(function()
                             NodeHelper:playEffect("click_2.mp3")
                             MARY_PARAS.NOW_FRAME_INDEX = MARY_PARAS.NOW_FRAME_INDEX + 1 > #showArray and 1 or MARY_PARAS.NOW_FRAME_INDEX + 1
                             for i = 1, MARY_PARAS.ITEM_NUM do
                                 NodeHelper:setNodesVisible(self.container, { ["mFrame" .. i] = (i == showArray[MARY_PARAS.NOW_FRAME_INDEX]) })
                             end
				         end))
    end
    action:addObject(CCDelayTime:create(1.0))
    action:addObject(CCCallFunc:create(function()
                         local CommonRewardPage = require("CommPop.CommItemReceivePage")
                         CommonRewardPage:setData(nowData.nowReward, common:getLanguageString("@ItemObtainded"), nil)
                         PageManager.pushPage("CommPop.CommItemReceivePage")
                         self:setGameState(container, GAME_STATE.STABLE)
                         self:refreshItem(container)
                         self:refreshUI(self.container)
                     end))
    action:addObject(CCCallFunc:create(function()
                         for i = 1, MARY_PARAS.ITEM_NUM do
                             NodeHelper:setNodesVisible(self.container, { ["mFrame" .. i] = false })
                         end
				     end))
    frameNode:runAction(CCSequence:create(action))
end
-- 獲得獎勵演出測試
function ActTimeLimit_148LittleMary:playShowRewardTest(container)
    local frameNode = self.container:getVarNode("mFrameNode")
    MARY_PARAS.NOW_FRAME_INDEX = 0
    local showArray = { }
    local delayTimeArray = { }
    local targetIndex = 0
    for i = 1, MARY_PARAS.ITEM_NUM do
        local isGet = false
        for j = 1, #nowData.getReward do
            if (i == nowData.getReward[j]) and (i ~= 9) then
                isGet = true
            end
        end
        if not isGet then
            table.insert(showArray, i)
            if i == 9 then
                targetIndex = #showArray
            end
        end
    end
    local finalShowNum = MARY_PARAS.BASE_SHOW_NUM
    local baseIndex = (MARY_PARAS.BASE_SHOW_NUM % #showArray == 0) and #showArray or MARY_PARAS.BASE_SHOW_NUM % #showArray  -- 基礎次數轉到的index
    -- 基礎轉輪次數 + 需要再轉幾次可以到目標位置
    if baseIndex > targetIndex then    -- 需要到下一圈才能到目標位置
        finalShowNum = MARY_PARAS.BASE_SHOW_NUM + (#showArray - baseIndex + targetIndex)
    elseif baseIndex < targetIndex then
        finalShowNum = MARY_PARAS.BASE_SHOW_NUM + (targetIndex - baseIndex)
    end
    for i = 1, finalShowNum do
        if i == 1 then
            table.insert(delayTimeArray, 0)
        elseif i < MARY_PARAS.BASE_SHOW_NUM / 2 then
            table.insert(delayTimeArray, math.max(0.7 - i * 0.07, 0.1))
        else
            table.insert(delayTimeArray, math.max(0.1 + (7 - (finalShowNum - i)) * 0.07, 0.1))
        end
    end
    local action = CCArray:create()
    frameNode:stopAllActions()
    for i = 1, finalShowNum do
        action:addObject(CCDelayTime:create(delayTimeArray[i]))
        action:addObject(CCCallFunc:create(function()
                             MARY_PARAS.NOW_FRAME_INDEX = MARY_PARAS.NOW_FRAME_INDEX + 1 > #showArray and 1 or MARY_PARAS.NOW_FRAME_INDEX + 1
                             for i = 1, MARY_PARAS.ITEM_NUM do
                                 NodeHelper:setNodesVisible(self.container, { ["mFrame" .. i] = (i == showArray[MARY_PARAS.NOW_FRAME_INDEX]) })
                             end
				         end))
    end
    action:addObject(CCDelayTime:create(1.0))
    action:addObject(CCCallFunc:create(function()
                         local CommonRewardPage = require("CommonRewardPage")
                         CommonRewardPageBase_setPageParm(ConfigManager.parseItemOnlyWithUnderline("30000_104001_10"), true, nil, nil)
                         PageManager.pushPage("CommonRewardPage")
                         self:setGameState(container, GAME_STATE.STABLE)
                         self:refreshItem(container)
                         self:refreshUI(self.container)
                     end))
    action:addObject(CCCallFunc:create(function()
                         for i = 1, MARY_PARAS.ITEM_NUM do
                             NodeHelper:setNodesVisible(self.container, { ["mFrame" .. i] = false })
                         end
				     end))
    frameNode:runAction(CCSequence:create(action))
end
-- 同步資料
function ActTimeLimit_148LittleMary:syncServerData(msg)
    -- 計算該次獲得獎勵id
    nowData.nowRewardId = 0
    if #msg.gotIndex == 1 then
        nowData.nowRewardId = msg.gotIndex[1]
    else
        for i = 1, #msg.gotIndex do
            for j = 1, #nowData.getReward do
                if msg.gotIndex[i] == nowData.getReward[j] then
                    break
                end
                if j == #nowData.getReward then
                    nowData.nowRewardId = msg.gotIndex[i] > MARY_PARAS.ITEM_NUM and nowData.nowRewardId or msg.gotIndex[i]    -- 不計算最終獎勵
                end
            end
        end
    end
    nowData.allReward = msg.rewards
    nowData.getReward = msg.gotIndex
    local rewards = common:split(msg.reward, ",")
    nowData.nowReward = { }
    for i = 1, #rewards do
        local _type, _itemId, _count = unpack(common:split(rewards[i], "_"))
        table.insert(nowData.nowReward, { type = tonumber(_type), itemId = tonumber(_itemId), count = tonumber(_count) })
    end
    nowData.leftTime = msg.leftTime
    nowData.costItem = msg.costItem
    NewPlayerBasePage:setActivityTime(nowData.leftTime)
end
-- 設定狀態
function ActTimeLimit_148LittleMary:setGameState(container, state)
    nowState = state
end
-- 刷新獎勵顯示
function ActTimeLimit_148LittleMary:refreshItem(container)
    for i = 1, #items do
        local reward = nowData.allReward[i]
        local rewardType, rewardId, rewardCount = unpack(common:split(reward, "_"))
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(rewardType), tonumber(rewardId), tonumber(rewardCount))
        local iconBgSprite = NodeHelper:getImageBgByQuality(resInfo.quality)
        NodeHelper:setSpriteImage(items[i], { mPic1 = resInfo.icon, mFrameShade1 = iconBgSprite })
        NodeHelper:setQualityFrames(items[i], { mHand1 = resInfo.quality })

        NodeHelper:setStringForLabel(items[i], { mNumber1_1 = rewardCount, mName1 = "", mNumber1 = "", mEquipLv = "" })
        NodeHelper:setNodesVisible(items[i], { mShader = false, mMask = self:isGetReward(i) })

        for star = 1, 6 do
            NodeHelper:setNodesVisible(items[i], { ["mStar" .. star] = (star == resInfo.quality) and (tonumber(rewardType) == Const_pb.EQUIP * 10000) })
        end
    end
end
-- 刷新介面顯示
function ActTimeLimit_148LittleMary:refreshUI(container)
    local costType, costId, costCount = unpack(common:split(nowData.costItem, "_"))
    local userCount = 0
    if tonumber(costType) == Const_pb.TOOL * 10000 and tonumber(costId) then
        userCount = UserItemManager:getCountByItemId(tonumber(costId))
    elseif tonumber(costType) == Const_pb.PLAYER_ATTR * 10000 then
        if tonumber(costId) == Const_pb.COIN then
            userCount = UserInfo.playerInfo.coin
        elseif tonumber(costId) == Const_pb.GOLD then
            userCount = UserInfo.playerInfo.gold
        end
    end
    NodeHelper:setNodesVisible(self.container, { mInfoNode = true, mCostTxt = (costCount and tonumber(costCount) >= 0) })
    NodeHelper:setStringForLabel(container, { mCostTxt = costCount and GameUtil:formatNumber(costCount) or 0, mCoinTxt = GameUtil:formatNumber(userCount),
                                              mTxt1 = common:getLanguageString("@NewPlayDraw", math.max(0, MARY_PARAS.ITEM_NUM - #nowData.getReward)) })
    local isEnable = (nowState == GAME_STATE.STABLE) and (#nowData.getReward < MARY_PARAS.ITEM_NUM) and (userCount >= tonumber(costCount))
    NodeHelper:setMenuItemEnabled(container, "mDrawBtn", isEnable)
    NodeHelper:setNodeIsGray(self.container, { mCostImg = not isEnable })
end
-- 檢查獎勵是否已獲得
function ActTimeLimit_148LittleMary:isGetReward(index)
    for i = 1, #nowData.getReward do
        if nowData.getReward[i] == index then
            return true
        end
    end
    return false
end
----------------------------------------------------------------------------------

-------------------------------------協定相關--------------------------------------
function ActTimeLimit_148LittleMary:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ACTIVITY148_S then
        local msg = Activity4_pb.MarrayResponse()
        msg:ParseFromString(msgBuff) 
        if msg.action == REQUEST_TYPE.SYNC then
            self:syncServerData(msg)
            self:setGameState(container, GAME_STATE.STABLE)
            self:refreshItem(container)
            self:refreshUI(self.container)
        elseif msg.action == REQUEST_TYPE.OPEN then   -- 抽獎
            self:syncServerData(msg)
            self:setGameState(container, GAME_STATE.PLAYING_ANI)
            self:refreshUI(self.container)
            self:playShowReward(container)
        end
    end
end
function ActTimeLimit_148LittleMary:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function ActTimeLimit_148LittleMary:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function ActTimeLimit_148LittleMary:requestServerData(type)
    local msg = Activity4_pb.MarrayRequest()
    msg.action = type
    common:sendPacket(option.opcodes.ACTIVITY148_C, msg, true)
end

function ActTimeLimit_148LittleMary.onFunction(eventName, container)
    if eventName == option.handlerMap.onDraw then
        ActTimeLimit_148LittleMary:onDraw(container)
    elseif eventName == option.handlerMap.onHelp then
        ActTimeLimit_148LittleMary:onHelp(container)
    elseif eventName == "onHand1" then
        ActTimeLimit_148LittleMary:onHand1(container)
    elseif eventName == option.handlerMap.onHand then
        ActTimeLimit_148LittleMary:onHand(container)
    end
end
----------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local ActPage = CommonPage.newSub(ActTimeLimit_148LittleMary, thisPageName, option)

return ActTimeLimit_148LittleMary