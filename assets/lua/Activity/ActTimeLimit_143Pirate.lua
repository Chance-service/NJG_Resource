local thisPageName = "ActTimeLimit_143Pirate" --"ActTimeLimit_143"
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local ConfigManager = require("ConfigManager")
local UserItemManager = require("Item.UserItemManager")
require("Activity.ActivityInfo")

local ActTimeLimit_143Pirate = {
    container = nil
}
--活動相關參數
local PIRATE_PARAS = {
    MAX_LEVEL = 20,
    ONLY_GEM_LEVEL = 15,
    TICKET_ID = 300000,
    BOX_NUM = 3,
    BOX_SPINE_PATH = "Spine/Activity_143_sp_boxes",
    BOX_SPINE_NAME = "Activity_143_sp_boxes",
    BOX_PLAY_TIME = 2,
}
--協定相關參數
local REQUEST_TYPE = {
    SYNC = 0, -- 0.同步
    OPEN = 1, -- 1.開箱
    REWARD = 2, -- 2.領獎
    GIVEUP = 3, -- 3.放棄
}
local REQUEST_RANSOM = {
    FREE = 0, -- 0.免費
    GOLD = 1, -- 1.金幣
    DIAMOND = 2, -- 2.鑽石
}
--遊戲狀態參數
local GAME_STATE = {
    START_PAGE = 0,
    SELECTING_BOX = 1,
    PLAYING_ANI = 2,
    SUCCESS_PAGE = 3,
    FAIL_PAGE = 4,
}
--玩家當前遊戲資料
local nowData = {
    level = 0,  -- 當前關卡
    free = 0,   -- 免費次數
    isFail = false, --是否失敗
    isReNew = false,    --是否為繼續
    allReward = "", --當前所有獎勵
    oneReward = "", --當前關卡獎勵
}

local option = {
    ccbiFile = "Act_TimeLimit_143Page.ccbi",
    handlerMap = {
        onClose = "onClose",
        onStart = "onStart",
        onRule = "onRule",
        onHelp = "onRule",
        onAdd = "onAdd",
        --Content
        onCloseAndGet = "onCloseAndGet",
        --Pop1
        onContinue = "onContinue",
        --Pop2
        onCostMoney = "onCostMoney",
        onCostGem = "onCostGem",
        onGiveUp = "onGiveUp",
    },
    opcodes = {
        ACTIVITY143_C = HP_pb.ACTIVITY143_C,
        ACTIVITY143_S = HP_pb.ACTIVITY143_S,
    }
}
for i = 1, 3 do
    option.handlerMap["onTreasure" .. i] = "onTreasure"
end

local nowState = GAME_STATE.START_PAGE
local selectBox = 0
local pirateCfg = ConfigManager.getPirateBoxDropCfg()
local boxSpine = {}
local mSpineNode = nil
local spineTimer = 0
local targetSpine = 0

--------------------------------------------------------------------------------------
function ActTimeLimit_143Pirate:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function ActTimeLimit_143Pirate:onEnter(container)
    nowState = GAME_STATE.START_PAGE
    selectBox = 0
    mSpineNode = container:getVarNode("mSpineNode")
    self:registerPacket(container)
    self:requestServerData(REQUEST_TYPE.SYNC, REQUEST_RANSOM.FREE)
    NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = false, mSuccessPopNode = false, mFailPopNode = false})
    NodeHelper:setStringForLabel(container, { mChallengeTxt = common:getLanguageString("@TodaySurpluseNum") })
    self:setGameState(container, GAME_STATE.START_PAGE)
    self:initTreasure(container)
end

function ActTimeLimit_143Pirate:onExecute(container)
    if mSpineNode then
	    mSpineNode:scheduleUpdateWithPriorityLua(function(dt)
	    	self:update(dt, container)
	    	end, 0)
    end
end

function ActTimeLimit_143Pirate:update(dt, container)
    if nowState ~= GAME_STATE.SELECTING_BOX then
        return
    end
    spineTimer = spineTimer + dt
    if spineTimer >= 2 then
        spineTimer = 0
        targetSpine = targetSpine + 1
        if targetSpine > #boxSpine then
            targetSpine = 1
        end
        self:playTreasure(container, targetSpine, 0, "spine_02")
    end
end
-------------------------------------按鈕---------------------------------------------
--關閉UI
function ActTimeLimit_143Pirate:onClose(container)
    --if nowState == GAME_STATE.PLAYING_ANI then
    --    return
    --end
    if mSpineNode then
        mSpineNode:unscheduleUpdate()
        mSpineNode = nil
    end
    PageManager.popPage(thisPageName)
end
--開始遊戲
function ActTimeLimit_143Pirate:onStart(container)
    if nowState ~= GAME_STATE.START_PAGE then
        return
    end
    ActTimeLimit_143Pirate:requestServerData(REQUEST_TYPE.OPEN, REQUEST_RANSOM.FREE)
    self:setGameState(container, GAME_STATE.SELECTING_BOX)
end
--規則說明
function ActTimeLimit_143Pirate:onRule(container)
    if nowState == GAME_STATE.PLAYING_ANI then
        return
    end
	PageManager.showHelp(GameConfig.HelpKey.HELP_PIRATE)
end
--跳禮包頁面
function ActTimeLimit_143Pirate:onAdd(container)
    if nowState ~= GAME_STATE.START_PAGE then
        return
    end
    require("WelfarePage")
    local checkAct = false
    for i = 1, #ActivityInfo.OtherPageids do
        if ActivityInfo.OtherPageids[i] == 94 then
            checkAct = true
            break
        end
    end
    if not checkAct then -- not openAct
        CCLuaLog("特典活?未開啟")
        return
    end
    WelfarePage_setPart(94)
    self:onClose(container)
    PageManager.pushPage("WelfarePage")
end
--點寶箱
function ActTimeLimit_143Pirate:onTreasure(container, eventName)
    if nowState == GAME_STATE.PLAYING_ANI then
        return
    end
    selectBox = tonumber(string.sub(eventName, -1))
    ActTimeLimit_143Pirate:requestServerData(REQUEST_TYPE.OPEN, REQUEST_RANSOM.FREE)
    self:setGameState(container, GAME_STATE.PLAYING_ANI)
end
--領獎
function ActTimeLimit_143Pirate:onCloseAndGet(container)
    if nowState == GAME_STATE.PLAYING_ANI or #nowData.allReward <= 0 then
        return
    end
    if nowState == GAME_STATE.SUCCESS_PAGE or nowData.level == PIRATE_PARAS.MAX_LEVEL + 1 then  --二次確認or通關強制領獎
        for i = 1, #boxSpine do
            self:playTreasure(container, i, 0, "stop")
        end
        ActTimeLimit_143Pirate:requestServerData(REQUEST_TYPE.REWARD, REQUEST_RANSOM.FREE)
    else    --第一次確認
        self:setGameState(container, GAME_STATE.SUCCESS_PAGE)
        NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = true, mSuccessPopNode = true, mFailPopNode = false})
    end
    
end
--繼續遊戲
function ActTimeLimit_143Pirate:onContinue(container)
    if nowState == GAME_STATE.PLAYING_ANI then
        return
    end
    if nowData.level == PIRATE_PARAS.MAX_LEVEL + 1 then --全部通關強制領獎
        self:onCloseAndGet(container)
    else
        self:setGameState(container, GAME_STATE.SELECTING_BOX)
        NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = true, mSuccessPopNode = false, mFailPopNode = false})
    end 
end
--花費金錢繼續
function ActTimeLimit_143Pirate:onCostMoney(container)
    if nowState == GAME_STATE.PLAYING_ANI then
        return
    end
    if UserInfo.playerInfo.coin < pirateCfg[nowData.level].CoinConsume then
        PageManager.notifyLackCoin()
    end
    ActTimeLimit_143Pirate:requestServerData(REQUEST_TYPE.OPEN, REQUEST_RANSOM.GOLD)
end
--花費鑽石繼續
function ActTimeLimit_143Pirate:onCostGem(container)
    if nowState == GAME_STATE.PLAYING_ANI then
        return
    end
    if not UserInfo.isGoldEnough(pirateCfg[nowData.level].DiamondConsume, "ShopRefresh_enter_rechargePage") then
        return
    end
    ActTimeLimit_143Pirate:requestServerData(REQUEST_TYPE.OPEN, REQUEST_RANSOM.DIAMOND)
end
--放棄獎勵
function ActTimeLimit_143Pirate:onGiveUp(container)
    if nowState == GAME_STATE.PLAYING_ANI then
        return
    end
    ActTimeLimit_143Pirate:requestServerData(REQUEST_TYPE.GIVEUP, REQUEST_RANSOM.FREE)
end
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--寶箱spine初始化
function ActTimeLimit_143Pirate:initTreasure(container)
    for i = 1, PIRATE_PARAS.BOX_NUM do
        boxSpine[i] = SpineContainer:create(PIRATE_PARAS.BOX_SPINE_PATH, PIRATE_PARAS.BOX_SPINE_NAME, 1)
        local boxSpineNode = tolua.cast(boxSpine[i], "CCNode")
        boxSpineNode:setScale(2)
        local boxParentNode = container:getVarNode("mSpineNode" .. i)
        boxParentNode:removeAllChildren()
        boxParentNode:addChild(boxSpineNode)
        self:playTreasure(container, i, 0, "stop")
    end
end
--寶箱演出
function ActTimeLimit_143Pirate:playTreasure(container, index, loop, ani)    --loop:true=-1, false=0
    if index < 1 or index > #boxSpine then
        return
    end
    boxSpine[index]:runAnimation(1, ani, loop)
end
--同步資料
function ActTimeLimit_143Pirate:syncServerData(msg)
    nowData.level = msg.level
    nowData.free = UserItemManager:getCountByItemId(PIRATE_PARAS.TICKET_ID)
    nowData.isFail = msg.isfail
    nowData.isReNew = msg.renew
    nowData.allReward = msg.ownreward
    nowData.oneReward = msg.reward
end
--刷新UI顯示
function ActTimeLimit_143Pirate:refreshPage(container)
    --進度條, 剩餘次數, 介面顯示切換, 狀態設定
    if #nowData.allReward <= 0 then
        NodeHelper:setMenuItemsEnabled(container, { mCloseAndGetImg = false })
        NodeHelper:setNodeIsGray(container, { mCloseAndGetTxt = true })
    else
        NodeHelper:setMenuItemsEnabled(container, { mCloseAndGetImg = true })
        NodeHelper:setNodeIsGray(container, { mCloseAndGetTxt = false })
    end
    if nowData.level < 1 or nowData.level > PIRATE_PARAS.MAX_LEVEL + 1 then
        NodeHelper:setStringForLabel(container, { mChallengeTxt = common:getLanguageString("@RaidMapTimesTxt", nowData.free) })
        
        NodeHelper:setNodesVisible(container, { mStartPageNode = true, mContentPageNode = false, mSuccessPopNode = false, mFailPopNode = false})
        self:setGameState(container, GAME_STATE.START_PAGE)
    else
        if nowData.isFail then
            NodeHelper:setMenuItemEnabled(container, "mCostMoneyBtn", nowData.level <= PIRATE_PARAS.ONLY_GEM_LEVEL)
            local action = CCArray:create()
            action:addObject(CCDelayTime:create(PIRATE_PARAS.BOX_PLAY_TIME))
            action:addObject(CCCallFunc:create(function()
                self:setGameState(container, GAME_STATE.FAIL_PAGE)
                NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = true, mSuccessPopNode = false, mFailPopNode = true})
            end))
            container:runAction(CCSequence:create(action))
        else
            if nowData.level == 1 then
                self:setGameState(container, GAME_STATE.SELECTING_BOX)
                self:refreshRoundTxt(container)
                self:refreshBox(container)
                self:refreshReward(container)
                NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = true, mSuccessPopNode = false, mFailPopNode = false})
            else
                local action = CCArray:create()
                if nowState == GAME_STATE.PLAYING_ANI then
                    action:addObject(CCDelayTime:create(PIRATE_PARAS.BOX_PLAY_TIME))
                end
                action:addObject(CCCallFunc:create(function()
                    self:refreshRoundTxt(container)
                    self:refreshTipTxt(container)
                    self:popOneReward(container)
                    self:setGameState(container, GAME_STATE.SELECTING_BOX)
                    self:refreshBox(container)
                    self:refreshReward(container)
                    if nowData.level == PIRATE_PARAS.MAX_LEVEL + 1 then --全部通關強制領獎
                        self:onCloseAndGet(container)
                    else
                        for i = 1, #boxSpine do
                            self:playTreasure(container, i, 0, "stop")
                        end
                        NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = true, mSuccessPopNode = false, mFailPopNode = false})
                    end
                end))
                container:runAction(CCSequence:create(action))
            end
        end
    end
end
--刷新獎勵顯示
function ActTimeLimit_143Pirate:refreshReward(container)
    local allReward = {}
    if nowData.allReward[1] then
        allReward = common:split(nowData.allReward[1], ",")
    end
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mRewardNode" .. i] = #allReward >= i })
        NodeHelper:setNodesVisible(container, { ["mPopRewardNode" .. i] = #allReward >= i })
        NodeHelper:setNodesVisible(container, { ["mPop2RewardNode" .. i] = #allReward >= i })
        if #allReward >= i then
            local _type, _id, _count = unpack(common:split(allReward[i], "_"))
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_count))
            NodeHelper:setStringForLabel(container, { ["mStoneNum0" .. i] = _count })
            NodeHelper:setSpriteImage(container, { ["mStonePic0" .. i] = resInfo.icon }, { ["mStonePic0" .. i] = resInfo.iconScale })
            NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. i] = resInfo.quality })
            local quality = container:getVarMenuItemImage("mStoneFeet0" .. i)
            local img = NodeHelper:getImageByQuality(resInfo.quality)
            quality:setNormalImage(CCSprite:create(img))
            NodeHelper:setImgQualityFrames(container, { ["mStoneFeet0" .. i] = resInfo.quality })
            NodeHelper:setBlurryString(container, "mStoneName0" .. i, resInfo.name, GameConfig.BlurryLineWidth, 5)
            local textColor = ConfigManager.getQualityColor()[resInfo.quality].textColor
            NodeHelper:setColorForLabel(container, { ["mStoneName0" .. i] = textColor })
            --Pop1
            NodeHelper:setStringForLabel(container, { ["mPopStoneNum0" .. i] = _count })
            NodeHelper:setSpriteImage(container, { ["mPopStonePic0" .. i] = resInfo.icon }, { ["mPopStonePic0" .. i] = resInfo.iconScale })
            NodeHelper:setImgBgQualityFrames(container, { ["mPopFrameShade" .. i] = resInfo.quality })
            local popQuality = container:getVarMenuItemImage("mPopStoneFeet0" .. i)
            local popImg = NodeHelper:getImageByQuality(resInfo.quality)
            popQuality:setNormalImage(CCSprite:create(popImg))
            NodeHelper:setBlurryString(container, "mPopStoneName0" .. i, resInfo.name, GameConfig.BlurryLineWidth, 5)
            NodeHelper:setColorForLabel(container, { ["mPopStoneName0" .. i] = textColor })
            --Pop2
            NodeHelper:setStringForLabel(container, { ["mPop2StoneNum0" .. i] = _count })
            NodeHelper:setSpriteImage(container, { ["mPop2StonePic0" .. i] = resInfo.icon }, { ["mPop2StonePic0" .. i] = resInfo.iconScale })
            NodeHelper:setImgBgQualityFrames(container, { ["mPop2FrameShade" .. i] = resInfo.quality })
            local pop2Quality = container:getVarMenuItemImage("mPop2StoneFeet0" .. i)
            local pop2Img = NodeHelper:getImageByQuality(resInfo.quality)
            pop2Quality:setNormalImage(CCSprite:create(pop2Img))
            NodeHelper:setBlurryString(container, "mPop2StoneName0" .. i, resInfo.name, GameConfig.BlurryLineWidth, 5)
            NodeHelper:setColorForLabel(container, { ["mPop2StoneName0" .. i] = textColor })
        end
    end
end
--設定狀態
function ActTimeLimit_143Pirate:setGameState(container, state)
    nowState = state
end
--刷新寶相顯示
function ActTimeLimit_143Pirate:refreshBox(container)
    local mBoxBar = container:getVarSprite("mBoxBar")
    if nowData.level > PIRATE_PARAS.MAX_LEVEL then
        mBoxBar:setScaleX(1)
    elseif nowData.level < 1 then
        mBoxBar:setScaleX(0 / PIRATE_PARAS.MAX_LEVEL)
    else
        mBoxBar:setScaleX(nowData.level / PIRATE_PARAS.MAX_LEVEL)
    end
    NodeHelper:setNodesVisible(container, { mBoxClose1 = nowData.level <= PIRATE_PARAS.MAX_LEVEL * 0.25, mBoxClose2 = nowData.level <= PIRATE_PARAS.MAX_LEVEL * 0.5, mBoxClose3 = nowData.level <= PIRATE_PARAS.MAX_LEVEL * 0.75, mBoxClose4 = nowData.level <= PIRATE_PARAS.MAX_LEVEL})
    NodeHelper:setNodesVisible(container, { mBoxOpen1 = nowData.level > PIRATE_PARAS.MAX_LEVEL * 0.25, mBoxOpen2 = nowData.level > PIRATE_PARAS.MAX_LEVEL * 0.5, mBoxOpen3 = nowData.level > PIRATE_PARAS.MAX_LEVEL * 0.75, mBoxOpen4 = nowData.level > PIRATE_PARAS.MAX_LEVEL})
end
--刷新復活消費
function ActTimeLimit_143Pirate:refreshCostTxt(container)
    if nowData.level < 1 or nowData.level > PIRATE_PARAS.MAX_LEVEL then
        return
    end
    NodeHelper:setStringForLabel(container, { mCostMoney = pirateCfg[nowData.level].CoinConsume, mCostGem = pirateCfg[nowData.level].DiamondConsume })
end
--刷新成功頁面文字
function ActTimeLimit_143Pirate:refreshTipTxt(container)
    NodeHelper:setStringForLabel(container, { mRoundTxt = common:getLanguageString("@PirateboxRound", PIRATE_PARAS.MAX_LEVEL - nowData.level + 1) })
end
--刷新關卡頁面文字
function ActTimeLimit_143Pirate:refreshRoundTxt(container)
    if nowData.level > PIRATE_PARAS.MAX_LEVEL then
        NodeHelper:setStringForLabel(container, { mNewRoundTxt = common:getLanguageString("@Round", PIRATE_PARAS.MAX_LEVEL) })
    else
        NodeHelper:setStringForLabel(container, { mNewRoundTxt = common:getLanguageString("@Round", nowData.level) })
    end
end
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--跳出單次獎勵
function ActTimeLimit_143Pirate:popOneReward(container)
    if not nowData.oneReward[1] or nowData.isFail then
        return
    end
    local _type, _id, _count = unpack(common:split(nowData.oneReward[1], "_"))
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_count))
    local textColor = ConfigManager.getQualityColor()[resInfo.quality].textColor
    insertMessageFlow( { [1] = resInfo.name .. "x" .. resInfo.count}, { [1] = textColor })
end
--跳出最終獎勵
function ActTimeLimit_143Pirate:popAllReward(container)
    if nowData.isFail then
        return
    end
    local rewardItems = {}
    local allReward = {}
    if nowData.allReward[1] then
        allReward = common:split(nowData.allReward[1], ",")
    end
    for i = 1, #allReward do
        local _type, _id, _count = unpack(common:split(allReward[i], "_"))
        table.insert(rewardItems, {
                type    = tonumber(_type),
                itemId  = tonumber(_id),
                count   = tonumber(_count),
        })
    end
    local CommonRewardPage = require("CommonRewardPage")
    CommonRewardPageBase_setPageParm(rewardItems, true)
    PageManager.pushPage("CommonRewardPage")
end
----------------------------------------------------------------------------------

-------------------------------------協定相關--------------------------------------
function ActTimeLimit_143Pirate:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ACTIVITY143_S then
        local msg = Activity3_pb.Activity143PirateRep()
        msg:ParseFromString(msgBuff) 
        if msg.type == REQUEST_TYPE.SYNC then
            self:syncServerData(msg)
            self:refreshBox(container)
            self:refreshReward(container)
        elseif msg.type == REQUEST_TYPE.OPEN then   --開始, 開寶箱, 接關
            self:syncServerData(msg)    --***先後順序不可換
            if nowState == GAME_STATE.PLAYING_ANI then
                if nowData.isFail then
                    self:playTreasure(container, selectBox, 0, "spine_03_B")
                else
                    self:playTreasure(container, selectBox, 0, "spine_03_A")
                end
            elseif nowState == GAME_STATE.FAIL_PAGE then
                self:playTreasure(container, selectBox, 0, "stop")
            end
        elseif msg.type == REQUEST_TYPE.REWARD then
            self:popAllReward(container)
            self:syncServerData(msg)    --***先後順序不可換(領獎時先同步會清空全部獎勵)
        elseif msg.type == REQUEST_TYPE.GIVEUP then
            self:syncServerData(msg)
            --if nowState == GAME_STATE.FAIL_PAGE then
                self:playTreasure(container, selectBox, 0, "stop")
            --end
        end
        self:refreshCostTxt(container)
        self:refreshPage(container)
    end
end
function ActTimeLimit_143Pirate:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function ActTimeLimit_143Pirate:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function ActTimeLimit_143Pirate:requestServerData(type, ransom)
    local msg = Activity3_pb.Activity143PirateReq()
    msg.type = type
    msg.ransom = ransom
    common:sendPacket(option.opcodes.ACTIVITY143_C, msg, true)
end
----------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local ActPage = CommonPage.newSub(ActTimeLimit_143Pirate, thisPageName, option)

return ActPage