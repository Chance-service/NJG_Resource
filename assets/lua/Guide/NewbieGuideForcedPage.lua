
local Guide_pb = require("Guide_pb")
local thisPageName = "NewbieGuideForcedPage"
local UserInfo = require("PlayerInfo.UserInfo")
local GuideManager = require("Guide.GuideManager")

local NewbieGuideForcedBase = { }
local opcodes = {
    RESET_GUIDE_INFO_C = HP_pb.RESET_GUIDE_INFO_C
}
local option = {
    ccbiFile = "NewBieGuide02.ccbi",
	handlerMap = {
		onNext = "onNext",
        onHit = "onHit",
        onTestSkip = "onTestSkip",
	},
	opcode = opcodes
}
local currStepIdx = nil
local currGuideType = nil
local currStepCfg = nil

local mStrShowIdx = 0
local mStrShowText = nil
local mHandler = nil
local mStrShowNode = nil
local mStrShowSpeed = 14
local mStrCountMax = 0

local touchLayer = nil
local touchStep = 0
local msgHandler = nil

local NewbieGuideCfg = ConfigManager.getNewbieGuideCfg()

newbieVoiceId = 0

function NewbieGuideForcedBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    GuideManager.PageContainerRef["NewbieGuideForcedBase"] = container
    self:refreshPage(container)
end

function NewbieGuideForcedBase:onExit(container)
    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    if mHandler ~= nil then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(mHandler)
        mHandler = nil
    end
    if touchLayer then
        touchLayer:removeFromParentAndCleanup(true)
        touchLayer = nil
    end
end

function NewbieGuideForcedBase.refreshTalkText()
    mStrShowIdx = mStrShowIdx + mStrShowSpeed * GamePrecedure:getInstance():getFrameTime()
    if mStrShowIdx >=  mStrCountMax then
        mStrShowIdx = mStrCountMax
        if mHandler ~= nil then
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(mHandler)
            mHandler = nil
        end
    end
    local srcIdx = mStrShowIdx
    if srcIdx ~= nil and srcIdx > 1 then
        local idx = math.floor(srcIdx)
        local strShow = GameMaths:getStringSubCharacters(mStrShowText, 0, idx)
        if mStrShowNode then
            mStrShowNode:getVarLabelTTF("mClickSpeaking"):setString(strShow)
        end
    end
end

function NewbieGuideForcedBase:refreshPage( container )
    NodeHelper:setNodesVisible(container, { mTestNode = false })
    if EFUNSHOWNEWBIE() == false  then
        PageManager.popPage("NewbieGuideForcedPage")
        return
    end
    if GuideManager.currGuideType == nil or GuideManager.currGuideType == 0 then
        GuideManager.currGuideType = GuideManager.guideType.NEWBIE_GUIDE
    end
    PageManager.popPage("NewGuideEmptyPage")

    touchStep = 0
    currGuideType = GuideManager.currGuideType
    currStepIdx = GuideManager.currGuide[GuideManager.currGuideType]
    currStepCfg = GuideManager.getStepCfgByIndex(GuideManager.currGuideType, currStepIdx)

    if currStepCfg == nil then
        PageManager.popPage(thisPageName)
        GuideManager.isInGuide = false
        GuideManager.IsNeedShowPage = false
        currStepIdx = 0
        GuideManager.currGuide[GuideManager.currGuideType] = 0
        self:setStepPacket(container, currGuideType, currStepIdx)
        CCLuaLog(">>NewbieGuideForcedBase currStepCfg == nil")
        return 
    end
    CCLuaLog("GuideType: " .. GuideManager.currGuideType .. ", GuideStep: " .. currStepIdx)
    CCLuaLog("GuideShowType: " .. currStepCfg.showType)

    if currStepIdx <= 10000 then
        --第一步一定要记录下，如果不记录，玩家在创建完角色后直接退出游戏，下次再进入就不再触发新手部分的引导
        self:setStepPacket(container, currGuideType, 10001)
    end

    ------------------------------------------------------------------------------------------------------
    -- add & modify 
    NodeHelper:setNodesVisible(container, { mNextBtn = false, mHintNode = false, mTalkingNode = false, mMaskNode = false })
    NodeHelper:setNodesVisible(container, { mTestNode = libOS:getInstance():getIsDebug() })
    local btnClickNode = container:getVarMenuItem("mHitNode")
    btnClickNode:setEnabled(false)
    local touchLayer = tolua.cast(container:getChildByTag(100230), "CCLayer")
    touchLayer:setTouchEnabled(true)
    -- 0. 新手H劇情
    if currStepCfg.showType == GameConfig.GUIDE_TYPE.PLAY_H_STORY then
        GuideManager.IsNeedShowPage = true
        require("Album.AlbumHCGPage")
        local AlbumStoryDisplayPage = require("AlbumStoryDisplayPage")
        local table = AlbumSideStory_GuideStroyState(container, 1)
        AlbumStoryDisplayPage:setData(table, true)
        PageManager.pushPage("AlbumStoryDisplayPage_Flip")
    -- 1. 劇情對話
    elseif currStepCfg.showType == GameConfig.GUIDE_TYPE.TALK  then
        NodeHelper:setNodesVisible(container, { mNextBtn = true, mTalkingNode = true })
        local talkLayer = ScriptContentBase:create("NavigationTalkingPopUp02.ccbi", 0)
        local talkingNode = container:getVarNode("mTalkingNode")
        talkingNode:removeAllChildrenWithCleanup(true)
        talkingNode:addChild(talkLayer)
        talkLayer:release()

        if currStepCfg.leftNpc then
            NodeHelper:setSpriteImage(talkLayer, { mLeftPic = currStepCfg.leftNpc })
            NodeHelper:setStringForLabel(talkLayer, { mNewGuideRightName = common:getLanguageString(currStepCfg.showName) })
        end
        if currStepCfg.voice and currStepCfg.voice ~= "" then
            newbieVoiceId = SoundManager:getInstance():playEffectByName(currStepCfg.voice .. ".mp3", false)
        end

        mStrShowIdx = 0
        mStrShowText = common:getLanguageString(currStepCfg.str, UserInfo.roleInfo.name)
        mStrShowNode = talkLayer
        mStrShowNode:getVarLabelTTF("mClickSpeaking"):setString("")
        mStrShowNode:getVarLabelTTF("mClickSpeaking"):setDimensions(CCSize(570, 130))
        mStrCountMax = GameMaths:calculateStringCharacters(mStrShowText)
        if mHandler ~= nil then
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(mHandler)
            mHandler = nil
        end
        mHandler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(NewbieGuideForcedBase.refreshTalkText, 0, false)
    -- 2. 按鈕點擊
    -- 12,22.2-7教學專用按鈕點擊
    elseif currStepCfg.showType == GameConfig.GUIDE_TYPE.TOUCH_HINT or
           currStepCfg.showType == GameConfig.GUIDE_TYPE.TOUCH_HINT_2 or
           currStepCfg.showType == GameConfig.GUIDE_TYPE.TOUCH_HINT_3 then
        touchStep = currStepIdx
        NodeHelper:setNodesVisible(container, { mHintNode = true })
        btnClickNode:setEnabled(true)   -- 開啟按鈕點擊
        touchLayer:setTouchEnabled(false)   -- 關閉pushPage預設layer
        -- 取得對應page的container
        local containerRef = GuideManager.PageContainerRef[currStepCfg.pageName]
        if containerRef and string.find(currStepCfg.pageName, "_cell") then
            containerRef = containerRef:getCCBFileNode()
        end
        if containerRef == nil then
            PageManager.popPage(thisPageName)
            GuideManager.isInGuide = false
            GuideManager.IsNeedShowPage = false
            CCLuaLog(">>NewbieGuideForcedBase containerRef == nil")
            if GuideManager.currGuideType > GuideManager.guideType.NEWBIE_GUIDE then
                -- 非一開始教學出現錯誤 > 強制結束教學
                currStepIdx = 0
                GuideManager.currGuide[GuideManager.currGuideType] = 0
                self:setStepPacket(container, currGuideType, currStepIdx)
            end
            return
        end
        -- 點擊目標node
        local targetClickNode = containerRef:getVarNode(currStepCfg.ownerVar)
        if currStepCfg.showType == GameConfig.GUIDE_TYPE.TOUCH_HINT_2 then
            require("NgBattleEditTeamPage")
            targetClickNode = containerRef:getVarNode(currStepCfg.ownerVar .. NgBattleEditTeamPage_getFirstTeamEmptyPosDesc())
        elseif currStepCfg.showType == GameConfig.GUIDE_TYPE.TOUCH_HINT_3 then
            require("NgBattleEditTeamPage")
            targetClickNode = containerRef:getVarNode(currStepCfg.ownerVar .. NgBattleEditTeamPage_getWind5TeamPosDesc())
        end
        if targetClickNode == nil then
            PageManager.popPage(thisPageName)
            GuideManager.isInGuide = false
            GuideManager.IsNeedShowPage = false
            CCLuaLog(">>NewbieGuideForcedBase ClickNode == nil")
            if GuideManager.currGuideType > GuideManager.guideType.NEWBIE_GUIDE then
                -- 非一開始教學出現錯誤 > 強制結束教學
                currStepIdx = 0
                GuideManager.currGuide[GuideManager.currGuideType] = 0
                self:setStepPacket(container, currGuideType, currStepIdx)
            end
            return
        end
        -- 光圈/手指parent
        local circleNode = container:getVarNode("mCircleNode")
        -- 取得世界座標
        local worldPos = targetClickNode:getParent():convertToWorldSpace(ccp(targetClickNode:getPositionX(), targetClickNode:getPositionY()))
        local posFinal = circleNode:convertToNodeSpace(worldPos)
        -- 綁定光圈/手指UI
        local eftLs = common:split(currStepCfg.selectEffect, "|")
        circleNode:removeAllChildren()
        for idx = 1,  #eftLs do
            local eft = eftLs[idx]
            if eft ~= nill then
                local eftNode = ScriptContentBase:create(eft, 0)
                circleNode:addChild(eftNode)
                eftNode:release()
            end
        end
        -- 移動座標
        local hintNode = container:getVarNode("mHintNode")
        hintNode:setPosition(posFinal)
        -- 註冊layer點擊事件
        self:registLayerEvent(container)
    -- 3. 開頭影片
    elseif currStepCfg.showType == GameConfig.GUIDE_TYPE.PLAY_OP_MOVIE then
        local params = common:split(currStepCfg.funcParam, ",")
        require("Guide.GuideStoryPage")
        require("Guide.GuideStoryManager")
        GuideStoryManager_setStoryIdx(tonumber(params[1]))
        PageManager.pushPage("GuideStoryPage")
    -- 4. 開啟遮罩(禁止點擊)
    -- 14.開啟遮罩(等待戰鬥角色移動至定位)
    -- 24.開啟遮罩(等待戰鬥角色動作結束)
    elseif currStepCfg.showType == GameConfig.GUIDE_TYPE.OPEN_MASK or
           currStepCfg.showType == GameConfig.GUIDE_TYPE.OPEN_MASK_WAIT_BATTLE_INIT or
           currStepCfg.showType == GameConfig.GUIDE_TYPE.OPEN_MASK_WAIT_BATTLE_ANI then
        NodeHelper:setNodesVisible(container, { mMaskNode = true })
    -- 5. 關閉教學ui(自由操作 銜接教學流程用)
    elseif currStepCfg.showType == GameConfig.GUIDE_TYPE.POP_NEWBIE_PAGE then
        touchLayer:setTouchEnabled(false)
        NodeHelper:setNodesVisible(container, { mTestNode = false })
        --PageManager.popPage(thisPageName)
    -- 6. 無作用 直接進行下一步
    elseif currStepCfg.showType == GameConfig.GUIDE_TYPE.NEXT_NEWBIE_STEP then
        GuideManager.forceNextNewbieGuide()
    -- 7. 執行function
    elseif currStepCfg.showType == GameConfig.GUIDE_TYPE.CALL_FUNC then
        GuideManager.callFunc(container, currGuideType, currStepIdx)
        GuideManager.setNextNewbieGuide()
    elseif currStepCfg.showType == 10 then -- 關閉教學ui(全自由操作用)
        PageManager.popPage(thisPageName)
    end 
end

function NewbieGuideForcedBase:onNext(container) -- 點擊對話 進行下一步
    if newbieVoiceId > 0 then
        SimpleAudioEngine:sharedEngine():stopEffect(newbieVoiceId)
        newbieVoiceId = 0
    end

    if mHandler ~= nil then -- 對話未顯示完 顯示完整對話
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(mHandler)
        mHandler = nil
        mStrShowNode:getVarLabelTTF("mClickSpeaking"):setString(mStrShowText)
        return
    end
    
    GuideManager.isInGuide = true
    if not NewbieGuideCfg[GuideManager.currGuide[GuideManager.currGuideType]] then
        PageManager.popPage(thisPageName)
        GuideManager.currGuide[GuideManager.currGuideType] = 0
        self:setStepPacket(container,GuideManager.currGuideType, 0)
        GuideManager.isInGuide = false
    end

    if GuideManager.currGuide[GuideManager.currGuideType] == 0 then 
        PageManager.popPage(thisPageName)
        GuideManager.isInGuide = false
        return 
    end

    GuideManager.setNextNewbieGuide()

    if not NewbieGuideCfg[GuideManager.currGuide[GuideManager.currGuideType]] then
        GuideManager.currGuide[GuideManager.currGuideType] = 0
        GuideManager.isInGuide = false
    end
    self:setStepPacket(container, GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
    self:refreshPage(container)
end

function NewbieGuideForcedBase:registLayerEvent(container) -- 點擊手指提示 執行對應function 設定為下一步(沒有直接執行)
    msgHandler = MessageScriptHandler:new(function(eventName, gameMsg)
    	if gameMsg:getTypeId() == MSG_BUTTON_PRESSED then
            if touchStep == 0 then
                return
            end
            local ccb = MsgButtonPressed:getTrueType(gameMsg).ccb
            local func = MsgButtonPressed:getTrueType(gameMsg).func
            if ccb == "NewBieGuide02.ccbi" then
                return
            end
    		local isAuto = (NewbieGuideCfg[touchStep].autoNext == 1)
            local str = ccb .. "_" .. func
            local checkStr = NewbieGuideCfg[touchStep].touchCheck
            --CCLuaLog("GUIDE CHECK STEP : " .. touchStep)
            --CCLuaLog("GUIDE CHECK STR : " .. str)
            if str ~= checkStr then
                NewbieGuideForcedBase:setStepPacket(container, GuideManager.currGuideType, 0)
                PageManager.popPage(thisPageName) 
                return
            end
            if isAuto then
                GuideManager.forceNextNewbieGuide()
                touchStep = 0
            else
                GuideManager.setNextNewbieGuide()
            
                if not NewbieGuideCfg[touchStep] then
                    GuideManager.currGuide[GuideManager.currGuideType] = 0
                    GuideManager.isInGuide = false
                end
                NewbieGuideForcedBase:setStepPacket(container, GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
                PageManager.popPage(thisPageName) 
                touchStep = 0
            end
            if msgHandler then
                MessageManager:getInstance():removeMessageHandler(msgHandler)
            end
    	end
    end)
    MessageManager:getInstance():regisiterMessageHandler(MSG_BUTTON_PRESSED, msgHandler)
    --local parent = container:getVarNode("mHintParent")
    --parent:removeAllChildrenWithCleanup(true)
    --touchLayer = CCLayer:create()
    --touchLayer:setContentSize(CCSize(150, 150))
    --touchLayer:setPosition(ccp(-37.5, -37.5))
    --touchLayer:registerScriptTouchHandler( function(eventName, pTouch)
    --    if eventName == "ended" then
    --        local rect = GameConst:getInstance():boundingBox(touchLayer)
    --        local point = touchLayer:convertToNodeSpace(pTouch:getLocation())
    --        if GameConst:getInstance():isContainsPoint(rect, point) then
    --            local isAuto = (NewbieGuideCfg[GuideManager.currGuide[GuideManager.currGuideType]].autoNext == 1)
    --            if isAuto then
    --                GuideManager.forceNextNewbieGuide()
    --            else
    --                GuideManager.setNextNewbieGuide()
    --            
    --                if not NewbieGuideCfg[GuideManager.currGuide[GuideManager.currGuideType]] then
    --                    GuideManager.currGuide[GuideManager.currGuideType] = 0
    --                    GuideManager.isInGuide = false
    --                end
    --            
    --                NewbieGuideForcedBase:setStepPacket(container, GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
    --                PageManager.popPage(thisPageName)
    --            end
    --        end
    --    end
    --end
    --, false, -129, false)
    --touchLayer:setTouchEnabled(true)
    --parent:addChild(touchLayer)
end

local connectMsgHandler = MessageScriptHandler:new(function(eventName, gameMsg)
	if gameMsg:getTypeId() == MSG_SEND_PACKAGE_FAILED then
        local opcode = MsgSendPackageFailed:getTrueType(gameMsg).opcode
        CCLuaLog("GUIDE CONNECT FAILED : " .. opcode)
        if not GuideManager.currGuideType then
            return
        end
        if GuideManager.currGuide[GuideManager.currGuideType] == 0 then
            return
        end
        local waitOpcode = NewbieGuideCfg[GuideManager.currGuide[GuideManager.currGuideType]].waitOpcode
        if waitOpcode == (opcode - 1) and GuideManager.tempMsg[waitOpcode] then
            common:sendPacket(waitOpcode, GuideManager.tempMsg[waitOpcode])
        end
	end
end)
MessageManager:getInstance():regisiterMessageHandler(MSG_SEND_PACKAGE_FAILED, connectMsgHandler)

function NewbieGuideForcedBase:setStepPacket(container, typeId, step)
    local msg = Guide_pb.HPResetGuideInfo()
    msg.guideInfoBean.guideId = typeId
    msg.guideInfoBean.step = step
    common:sendPacket(HP_pb.RESET_GUIDE_INFO_C, msg, false)
end

function NewbieGuideForcedBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:refreshPage(container)
		end
	end
end

function NewbieGuideForcedBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function NewbieGuideForcedBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function NewbieGuideForcedBase:onTestSkip(container)
    GuideManager.isInGuide = false
    GuideManager.IsNeedShowPage = false
    currStepIdx = 0
    GuideManager.currGuide[GuideManager.currGuideType] = 0
    self:setStepPacket(container, currGuideType, currStepIdx)
    PageManager.popPage(thisPageName)
    require("Battle.NgBattleDataManager")
    local CONST = require("Battle.NewBattleConst")
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE then
        MainFrame_onMainPageBtn()
    end
end

-----------------------------------------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
NewbieGuideForcedPage = CommonPage.newSub(NewbieGuideForcedBase, thisPageName, option)

return NewbieGuideForcedPage