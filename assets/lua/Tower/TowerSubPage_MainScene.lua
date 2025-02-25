----------------------------------------------
-- 模塊引入與全局局部變數定義
----------------------------------------------
local NodeHelper      = require("NodeHelper")
local Activity6_pb    = require("Activity6_pb")
local HP_pb           = require("HP_pb")
local CONST           = require("Battle.NewBattleConst")
local TimeDateUtil    = require("Util.TimeDateUtil")
local TowerRankPage   = require("Tower.TowerSubPage_Rank")

local TowerBase       = {}
local parentPage      = nil
local selfContainer   = nil
local TOWER_CELL_HEIGHT = 252  -- 每層高度
local countdownScheduler = nil
local isTowerMoving   = false

local TowerContent    = { ccbiFile = "Tower_Content.ccbi" }
local RewardContent   = { ccbiFile = "Tower_PopupContent.ccbi" }
local RewardPopCCB    = nil
local PageInfo        = {}

----------------------------------------------
-- 頁面選項
----------------------------------------------
local pageOption = {
    ccbiFile   = "Tower.ccbi",
    handlerMap = {
        onBack   = "onBack",
        onHelp   = "onHelp",  -- 爬塔說明
        onReward = "onReward",
        onEffect = "onEffect"
    },
}

local opcodes = {
    ACTIVITY194_SEASON_TOWER_C = HP_pb.ACTIVITY194_SEASON_TOWER_C,
    ACTIVITY194_SEASON_TOWER_S = HP_pb.ACTIVITY194_SEASON_TOWER_S,
    BATTLE_FORMATION_S         = HP_pb.BATTLE_FORMATION_S,
}
----------------------------------------------
-- local function 
----------------------------------------------

-- RewardPopFunction：用於彈窗內容處理
local function RewardPopFunction(eventName, container)
    if eventName == "onClose" then
        local parentNode = selfContainer:getVarNode("mPopUpNode")
        if parentNode then
            parentNode:removeAllChildren()
        end
    end
end

----------------------------------------------
-- TowerBase 方法定義
----------------------------------------------

function TowerBase:createPage(_parentPage)
    local selfObj = self
    parentPage = _parentPage
    local container = ScriptContentBase:create(pageOption.ccbiFile)
    
    container:registerFunctionHandler(function(eventName, container)
        local funcName = pageOption.handlerMap[eventName]
        local func = selfObj[funcName]
        if func then
            func(selfObj, container)
        end
    end)
    
    return container
end

function TowerBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function TowerBase:onEffect(container)
    local skillId = ConfigManager.getTowerData()[1].BuffId
    if skillId and skillId > 0 then
        GameUtil:showSkillTip(container:getVarNode("mEffectSprite"), skillId)
    end
end

function TowerBase:onBack(container)
    self:scrollToLevel(container.mScrollview, #PageInfo.takedId, PageInfo.totalLevels, nil)
end

function TowerBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_CLIMB_TOWER)
end

function TowerBase:onReward(container)
    local parentNode = container:getVarNode("mPopUpNode")
    if parentNode then 
        parentNode:removeAllChildren()
        RewardPopCCB = ScriptContentBase:create("Tower_Popup")
        parentNode:addChild(RewardPopCCB)
        RewardPopCCB:registerFunctionHandler(RewardPopFunction)
        RewardPopCCB:setAnchorPoint(ccp(0.5, 0.5))
        TowerBase:setRewardPopCCB(RewardPopCCB)
    end
end

function TowerBase:setRewardPopCCB(container)
    local scrollview = container:getVarScrollView("mContent")
    if not scrollview then
        print("Error: container 沒有 mContent scroll view")
        return
    end
    local cfg = ConfigManager.getTowerData()
    for k, value in pairs(cfg) do
        local cell = CCBFileCell:create()
        cell:setCCBFile(RewardContent.ccbiFile)
        local panel = common:new({ data = value }, RewardContent)
        cell:registerFunctionHandler(panel)
        scrollview:addCell(cell)
    end
    NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@SeasonTowerReward") })
    scrollview:orderCCBFileCells()
    scrollview:setTouchEnabled(true)
    if #PageInfo.takedId > 1 then
        local options = { height = 146, durationPerLevel = 0 }
        local floor = math.max(#PageInfo.takedId - 1, 1)
        TowerBase:scrollToLevel(scrollview, floor, PageInfo.totalLevels, nil, options)
    end
end


function TowerBase:onEnter(container)
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    self.container = container
    
    require("TransScenePopUp")
    TransScenePopUp_closePage()
    
    local PageJumpMange = require("PageJumpMange")
    PageJumpMange._IsPageJump = false
    
    selfContainer = container
    container:getVarNode("mBg"):setScale(NodeHelper:getScaleProportion())
    container.mScrollview = container:getVarScrollView("mContent")
    container.mScrollview:setBounceable(true)
    
    local TowerDataBase = require "Tower.TowerPageData"
    PageInfo = TowerDataBase:getData()
    
    local towerEnterKey = "TOWER_" .. UserInfo.playerInfo.playerId
    local TowerEnter = CCUserDefault:sharedUserDefault():getStringForKey(towerEnterKey) or ""
    PageInfo.isFirstEnter = (TowerEnter ~= self:getCurrentDateString())
    
    local towerPassKey = "TOWERPASS_" .. UserInfo.playerInfo.playerId
    local TowerPass = CCUserDefault:sharedUserDefault():getIntegerForKey(towerPassKey) or 0
    PageInfo.isPassLevel = (TowerPass ~= #PageInfo.takedId)
    
    self:buildScrollview(container)
    self:setPage(container)
end

function TowerBase:getCurrentDateString()
    local dateTable = os.date("*t")
    local year  = dateTable.year
    local month = string.format("%02d", dateTable.month)
    local day   = string.format("%02d", dateTable.day)
    return year .. "_" .. month .. "_" .. day
end

function TowerBase:setPage(container)
    local cfg = ConfigManager.getTowerData()
    local skillId = cfg[1].BuffId
    local img = "S_" .. math.floor(skillId / 10) .. ".png"
    NodeHelper:setSpriteImage(container, { mEffectSprite = img })
    
    local endTimeSec = math.floor(PageInfo.endTime / 1000)
    local clientSafeTime = TimeDateUtil:getClientSafeTime()
    local leftTime = endTimeSec - clientSafeTime
    
    countdownScheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        leftTime = leftTime - 1
        local timeStr = common:second2DateString5(leftTime, false)
        NodeHelper:setStringForLabel(container, { mCountDown = common:getLanguageString("@SeasonTowerEndTime", timeStr) })
        TowerRankPage:setTime(timeStr)
    end, 1, false)
end

function TowerBase:setReward(container)
    -- 如有獎勵邏輯，可在此處補充
    local cfg = ConfigManager.getTowerData()
end

function TowerBase:buildScrollview(container)
    local scrollView = container.mScrollview
    scrollView:removeAllCell()
    local cfg = ConfigManager.getTowerData()
    PageInfo.totalLevels = #cfg
    PageInfo.Items = {}
    
    for i = #cfg, 1, -1 do
        local cell = CCBFileCell:create()
        cell:setCCBFile(TowerContent.ccbiFile)
        local panel = common:new({ data = cfg[i] }, TowerContent)
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
    end
    
    scrollView:setTouchEnabled(true)
    scrollView:orderCCBFileCells()
    
    if PageInfo.isFirstEnter then
        scrollView:setContentOffset(ccp(0, 0))
        local actionArray = CCArray:create()
        actionArray:addObject(CCDelayTime:create(0.1))
        actionArray:addObject(CCCallFunc:create(function()
            self:initScrollToCurrentLevel(scrollView)
        end))
        container:runAction(CCSequence:create(actionArray))
    else
        local options = { durationPerLevel = 0 }
        self:initScrollToCurrentLevel(scrollView)
    end
end

function TowerBase:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.ACTIVITY194_SEASON_TOWER_S then
        -- 處理爬塔服務器回應（如有需要）
    elseif opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            local battlePage = require("NgBattlePage")
            resetMenu("mBattlePageBtn", true)
            require("NgBattleDataManager")
            NgBattleDataManager_setDungeonId(tonumber(msg.mapId))
            PageManager.changePage("NgBattlePage")
            battlePage:onSeasonTower(selfContainer, msg.resultInfo, msg.battleId, msg.battleType, tonumber(msg.mapId))
        end
    end
end

function TowerBase:onClose(container)
    parentPage:removePacket(opcodes)
    if countdownScheduler then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(countdownScheduler)
        countdownScheduler = nil
    end
end

function TowerBase:onExecute(container)
    -- 如有額外執行邏輯，在此處補充
end

-- 滾動到指定層級
function TowerBase:scrollToLevel(scrollView, level, totalLevels, callback, options)
    options = options or {}
    local cellHeight = options.height or TOWER_CELL_HEIGHT
    if options.height then
        level = totalLevels - level - 2
    end
    if level < 1 or level > totalLevels then
        print(string.format("無效的層級：%d（範圍：1-%d）", level, totalLevels))
        return
    end
    local viewHeight    = scrollView:getViewSize().height
    local contentHeight = totalLevels * cellHeight
    local centerOffset  = options.centerOffset or 0
    local targetY       = (level - 1) * cellHeight - (viewHeight / 2) + centerOffset
    targetY = math.max(0, math.min(contentHeight - viewHeight, targetY))
    
    local currentOffset = math.abs(scrollView:getContentOffset().y)
    local currentLevel  = math.floor(currentOffset / cellHeight) + 1
    local levelDiff     = math.abs(level - currentLevel)
    local duration      = math.min(levelDiff * (options.durationPerLevel or 0.1), 2)
    
    print(string.format("滾動到層級：%d，當前層級：%d，層級差距：%d，目標偏移：%.2f，持續時間：%.2f",
          level, currentLevel, levelDiff, targetY, duration))
    
    if duration > 0 then
        scrollView:setContentOffsetInDuration(ccp(0, -targetY), duration)
    else
        scrollView:setContentOffset(ccp(0, -targetY))
    end
    
    local actionArray = CCArray:create()
    actionArray:addObject(CCCallFunc:create(function()
        isTowerMoving = true
        scrollView:setTouchEnabled(false)
    end))
    actionArray:addObject(CCDelayTime:create(duration))
    actionArray:addObject(CCCallFunc:create(function()
        isTowerMoving = false
        scrollView:setTouchEnabled(true)
        if callback and type(callback) == "function" then
            callback()
        end
    end))
    scrollView:runAction(CCSequence:create(actionArray))
end

-- 初始化滾動邏輯
function TowerBase:initScrollToCurrentLevel(scrollView)
    if PageInfo.isFirstEnter then
        local key = "TOWER_" .. UserInfo.playerInfo.playerId
        CCUserDefault:sharedUserDefault():setStringForKey(key, self:getCurrentDateString())
        self:scrollToLevel(scrollView, #PageInfo.takedId, PageInfo.totalLevels)
    elseif PageInfo.isPassLevel then
        local options = { durationPerLevel = 0 }
        local actionArray = CCArray:create()
        actionArray:addObject(CCCallFunc:create(function()
            self:scrollToLevel(scrollView, #PageInfo.takedId - 1, PageInfo.totalLevels, nil, options)
        end))
        actionArray:addObject(CCDelayTime:create(0.5))
        actionArray:addObject(CCCallFunc:create(function()
            options.durationPerLevel = 0.2
            self:scrollToLevel(scrollView, #PageInfo.takedId, PageInfo.totalLevels, nil, options)
            local passKey = "TOWERPASS_" .. UserInfo.playerInfo.playerId
            CCUserDefault:sharedUserDefault():setIntegerForKey(passKey, #PageInfo.takedId)
        end))
        selfContainer:runAction(CCSequence:create(actionArray))
    else
        local options = { durationPerLevel = 0 }
        self:scrollToLevel(scrollView, #PageInfo.takedId, PageInfo.totalLevels, nil, options)
    end
end

function TowerBase:passLevel(scrollView)
    if #PageInfo.takedId < PageInfo.totalLevels then
        -- 播放當前層通關動畫（如有需要）
        self:scrollToLevel(scrollView, #PageInfo.takedId, PageInfo.totalLevels, function()
            -- 此處可加入解鎖下一層動畫
        end)
    else
        print("All levels cleared!")
    end
end

function TowerBase:isLevelVisible(scrollView, level, totalLevels)
    if level < 1 or level > totalLevels then
        print("無效的層級：", level)
        return "invalid"
    end
    local viewHeight         = scrollView:getViewSize().height
    local totalContentHeight = totalLevels * TOWER_CELL_HEIGHT
    local offsetY            = math.abs(scrollView:getContentOffset().y)
    local visibleStartY      = offsetY
    local visibleEndY        = offsetY + viewHeight
    local levelStartY        = (level - 1) * TOWER_CELL_HEIGHT
    local levelEndY          = levelStartY + TOWER_CELL_HEIGHT
    
    if levelEndY < visibleStartY then
        return "above"
    elseif levelStartY > visibleEndY then
        return "below"
    else
        return "visible"
    end
end

----------------------------------------------
-- TowerContent 相關方法
----------------------------------------------
function TowerContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local data = self.data
    
    if data.id == 1 then
        NodeHelper:setNodesVisible(container, { mBase = true })
    else
        NodeHelper:setNodesVisible(container, { mBase = false })
    end
    PageInfo.Items[data.id] = container
    NodeHelper:setStringForLabel(container, { mStage = data.id })
    NodeHelper:setScale9SpriteImage2(container, { mBg = data.stageBg, mBg2 = data.stageBg })
    
    if data.id <= #PageInfo.takedId then
        NodeHelper:setNodesVisible(container, { PassImg = true, mNowStage = false })
        if string.find(data.stageBg, "Tower_img1") then
            NodeHelper:setScale9SpriteImage2(container, { mBg = "BG/UI/Tower_img1_1.png", mBg2 = "BG/UI/Tower_img1_1.png" })
        elseif string.find(data.stageBg, "Tower_img2") then
            NodeHelper:setScale9SpriteImage2(container, { mBg = "BG/UI/Tower_img2_1.png", mBg2 = "BG/UI/Tower_img2_1.png" })
        end
        local parentNode = container:getVarNode("mSpine")
        if parentNode then
            parentNode:removeAllChildren()
        end
    elseif data.id == PageInfo.MaxFloor + 1 then 
        NodeHelper:setNodesVisible(container, { PassImg = false, mNowStage = true })
        self:addSpine(container, data.Spine)
    else
        NodeHelper:setNodesVisible(container, { PassImg = false, mNowStage = false })
        self:addSpine(container, data.Spine)
    end
    
    local status = TowerBase:isLevelVisible(selfContainer.mScrollview, #PageInfo.takedId, PageInfo.totalLevels)
    if status == "above" or status == "below" then
        NodeHelper:setNodesVisible(selfContainer, { mUpperArrow = false, mLowerArrow = false, mBack = true })
    else
        NodeHelper:setNodesVisible(selfContainer, { mUpperArrow = false, mLowerArrow = false, mBack = false })
    end
end

function TowerContent:onFight(container)
    if isTowerMoving then return end
    if self.data.id - 1 > PageInfo.MaxFloor then
        MessageBoxPage:Msg_Box(common:getLanguageString("@activitystagetNotice02"))
        return 
    end
    container:runAnimation("onFight")
    local msg = Battle_pb.NewBattleFormation()
    msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
    msg.battleType = NewBattleConst.SCENE_TYPE.SEASON_TOWER
    msg.mapId = tostring(self.data.id)
    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, true)
end

function TowerContent:addSpine(container, spine)
    local spinePath, spineName = unpack(common:split(spine, ","))
    local spineObj = SpineContainer:create(spinePath, spineName)
    spineObj:runAnimation(1, CONST.ANI_ACT.WAIT, -1)
    local sNode = tolua.cast(spineObj, "CCNode")
    local parentNode = container:getVarNode("mSpine")
    if parentNode then
        parentNode:removeAllChildren()
        parentNode:addChild(sNode)
    end
end

----------------------------------------------
-- RewardContent 相關方法
----------------------------------------------
function RewardContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local titleStr = common:getLanguageString("@SeasonTowerXstage", self.data.id)
    NodeHelper:setStringForLabel(container, { mTitleTxt = titleStr })
    local items = self.data.reward
    if (self.data.id <= #PageInfo.takedId ) then
        NodeHelper:setNodesVisible(container, { mPassed = true })
    else
        NodeHelper:setNodesVisible(container, { mPassed = false })
    end
    for i = 1, 4 do
        local parentNode = container:getVarNode("mPosition" .. i)
        parentNode:removeAllChildren()
        if items[i] then
            local itemNode = ScriptContentBase:create("CommItem")
            itemNode:setScale(0.8)
            itemNode.Reward = items[i]
            NodeHelper:setNodesVisible(itemNode, { selectedNode = false, mStarNode = false, nameBelowNode = false, mPoint = false })
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(items[i].type, items[i].itemId, items[i].count)
            local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
            local iconBg      = NodeHelper:getImageBgByQuality(resInfo.quality)
            NodeHelper:setMenuItemImage(itemNode, { mHand1 = { normal = normalImage } })
            NodeHelper:setSpriteImage(itemNode, { mPic1 = resInfo.icon, mFrameShade1 = iconBg })
            NodeHelper:setStringForLabel(itemNode, { mNumber1_1 = items[i].count })
            parentNode:addChild(itemNode)
        end
    end
end

----------------------------------------------
-- 返回新子頁面
----------------------------------------------
local CommonPage = require('CommonPage')
return CommonPage.newSub(TowerBase, "TowerSubPage_MainScene", pageOption)
