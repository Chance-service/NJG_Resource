local thisPageName = "FetterGirlsDiary"
local UserMercenaryManager = require("UserMercenaryManager")
local UserItemManager = require("Item.UserItemManager")
local FetterPage = require("FetterPage")
local FetterManager = require("FetterManager")
local GuideManager = require("Guide.GuideManager")

local option = {
	ccbiFile = "FetterGirlsDiary.ccbi",
	ccbiFile2 = "FetterGirlsDiary2.ccbi",
	handlerMap =
	{
		onClose = "onClose",
		onHide = "onHide",
		onReturn = "onReturn",
		onTouch = "onTouch",
		onAuto = "onAuto",
		onVoice = "onSilent",
		onLog = "onLog",
		onCloseLog = "onCloseLog",
		--TEST FUNCTION
		onSetNowLine = "onSetNowLine",
		onTestHide = "onTestHide",
		luaonOpenKeyboard = "luaonOpenKeyboard",
		luaonCloseKeyboard = "luaonCloseKeyboard",
		luaInputboxEnter = "luaInputboxEnter",
		luaOnKeyboardHightChange = "luaOnKeyboardHightChange",
		luaMessageboxEnter = "luaMessageboxEnter",
		--TUTORIAL
		onTutorialSkip = "onTutorialSkip",
	},
	opcodes =
	{
		FETCH_ARCHIVE_INFO_C = HP_pb.FETCH_ARCHIVE_INFO_C,
		FETCH_ARCHIVE_INFO_S = HP_pb.FETCH_ARCHIVE_INFO_S,
		ITEM_USE_C = HP_pb.ITEM_USE_C,
		ITEM_USE_S = HP_pb.ITEM_USE_S,
	}
}
for i = 1, 4 do
	option.handlerMap["onTouchPhoto" .. i] = "onTouchPhoto"
end

local FetterGirlsDiary = {}

local FetterLogContent = {
	ccbi = "FetterGirlsDiaryDialogue.ccbi",
	logName = {},
	logTxt = {},
	logVoice = {},
}

local diaryContainer = nil

local DiaryState = {SPINE = 1, HIDE = 2}
local DiaryTypeNew = {NONE = 0, SPINE = 1, TRANS = 2, FADEIN = 3, ANIMATION = 4, WAITLINE = 5,
	NEXTLINE = 13, VISIBLEUI = 7, HALFBODY = 8, SPINEFILE = 9, DELSPINE = 10,
	SPINEMOVMENT = 11, BGCHANGE = 12, AUTOCLICK = 6, SETCOLOR = 14, SHAKE = 15, CHANGESPINE = 16,
	HSPINE = 17, PLAYVIDEO = 18 ,WAIT = 999}
local PhotoSettingState = {isSilent = false, isAuto = false}
local nowState = DiaryState.SPINE

local diarySpine = nil
local diarySpineFade = nil

local fetterControlCfg = ConfigManager:getFetterBDSMControlCfg()
local fetterMovementCfg = ConfigManager:getFetterBDSMActionCfg()

local mSpineNode = nil
local mSpineFadeNode = nil

--全劇情文字
local lines = {}
--目前劇情編號
local nowLine = 1
--Log可顯示的劇情編號
local logNowLine = 1
--目前地區編號(新手教學=99)
local areaNum = 0
--目前關卡編號
local stageNum = 0
--戰鬥前/後 1:前 2:後
local storyIdx = 1
--淡入次數
local fadeCount = 0
--淡入計時器
local fadeTimer = 0
--淡入時間
local fadeTime = nil
--淡入初始化設定
local fadeInitCfg = {}
--淡入動作
local fadeAction = ""
--執行中的動作type
local nowActionType = DiaryTypeNew.NONE
--當前字串table
local nowLineTable
--當前顯示文字index
local lineIndex = 1
--文字播放計時器
local labelTimer = 0
--文字播放速度
local labelSpeed = 4
--文字是否撥放中
local isLabelPlaying = false
--自動播放間隔
local autoTime = 2
--自動播放計時器
local autoTimer = 0
--是否等待劇情結束
local isEndLineAct = false
--劇情結束後的動作
local endLineAct = nil
--UI是否顯示
local isUiVisible = true
--當前BG
local nowBgName = ""
--淡入用bg
local fadeBgSprite = nil
--當前BGM
local nowBgmName = ""
--當前語音ID
local nowVoiceEffId = 0
--當前其他音效
local nowOtherEffName = ""
--當前其他音效ID
local nowOtherEffId = 0
--是否在等待播放語音
local isWaitingVoice = false
--預載Spine檔案
local spineFiles = {}
local spineKey = {}
local nowSpines = {}

local SHAKE_ACTION_TAG = 1000
local Limit = 0

local isBgMoving=false

local isSkipping = false

local libPlatformListener = { }
local mainContainer = nil
-----------------------------------------------------------
--TEST PARA
--測試用行數
local testNowLine = 0
--測試用輸入Type
local mEditInputType = 0
--回傳0~3 0:client判斷第一張是否開啟 1~3:後三張是否開啟
--useitem: type傳奧義id

function libPlatformListener:onPlayMovieEnd(listener)
    if not listener then return end
    GameUtil:setPlayMovieVisible(true)
    GamePrecedure:getInstance():closeMovie()
    local Container = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local backNode = Container:getCCNodeFromCCB("mNodeMid")
    backNode:setVisible(true)
    --libPlatformListener = { }
end

function FetterGirlsDiary:onLoad(container)
	if areaNum and areaNum == 99 and stageNum and stageNum == 5 then
		container:loadCcbiFile(option.ccbiFile2)
	else
		container:loadCcbiFile(option.ccbiFile)
	end
end
function FetterGirlsDiary:PlayBGM(container)
	SoundManager:getInstance():playMusic(nowBgmName)
end
function FetterGirlsDiary:onEnter(container)
    for i =1 ,3 do
        if nowSpines[i] then
            nowSpines[i] = nil
        end
    end
	NodeHelper:setNodesVisible(container, {mDiaryWindow = false, mFullScreen = true})
    FetterGirlsDiary:removeSpinesSafely()
	nowOtherEffId = 0
	nowOtherEffName = ""
	SoundManager:getInstance():stopAllEffect()
    self.container = container
    mainContainer = container
	self:openMainScreen(container)
	--NodeHelper:Add_9_16_Layer(container,"mLayer")
	--container:getVarNode("mStory"):setPositionY(TextHeight)
	---
	fadeBgSprite = CCSprite:create("UI/Mask/Image_Empty.png")
	fadeBgSprite:setOpacity(0)
	local sprite = container:getVarSprite("mBg")
	sprite:getParent():addChild(fadeBgSprite)
	---
	FetterGirlsDiary:registerPacket(container)
	--FetterGirlsDiary:refreshPage(container)
	NodeHelper:setNodesVisible(container, {mLogNode = false,mTouch = false})
	--------------------------------------------------------------------
	--Debug
	if NodeHelper:isDebug() then
		NodeHelper:setNodesVisible(container, {mTestNode = false})
		NodeHelper:setStringForLabel(container, {mTestLine = ""})
		container:registerLibOS()
	else
		NodeHelper:setNodesVisible(container, {mTestNode = false})
	end


    local layer = CCLayer:create()
    layer:setTag(100001)
    container:addChild(layer)
    layer:setContentSize(CCEGLView:sharedOpenGLView():getDesignResolutionSize())
    layer:registerScriptTouchHandler( function(eventName, pTouch)
        if eventName == "began" then
            self:onTouch(container,"onTouch")
        elseif eventName == "moved" then

        elseif eventName == "ended" then
          
        elseif eventName == "cancelled" then

        end
    end
    , false, -129, false)
    layer:setTouchEnabled(true)
    layer:setVisible(true)

	--------------------------------------------------------------------
	--Tutorial
	FetterGirlsDiary:setTutorialState(container)
	NodeHelper:setNodesVisible(container, {mBtn = false})
	--------------------------------------------------------------------
	diaryContainer = container
	GuideManager.PageContainerRef["FetterGirlsDiary"] = container
	PageManager.setIsInGirlDiaryPage(true) 
end
function FetterGirlsDiary:HSPINESync(container)
	local mID
	for line=1,99 do
		mID = tonumber( string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", line))
		if fetterControlCfg[mID] then
			for move=1,10 do
				mID = tonumber( string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", line).. string.format("%02d", move))
				if fetterMovementCfg[mID] and fetterMovementCfg[mID].actionType == DiaryTypeNew.HSPINE then
					return line
				end
			end
		end
	end
end
function FetterGirlsDiary:onClose(container)
	if mSpineNode then
		mSpineNode:unscheduleUpdate()
		mSpineNode = nil
	end
	FetterGirlsDiary:stopVoice(container)
    FetterGirlsDiary:removeSpinesSafely()
	PageManager.popPage(thisPageName)
	PageManager.setIsInGirlDiaryPage(false)
    for i =1 ,3 do
        if nowSpines[i] then
            nowSpines[i] = nil
        end
    end
end

function FetterGirlsDiary:onExecute(container)
	if mSpineNode then
		mSpineNode:scheduleUpdateWithPriorityLua(function(dt)
			FetterGirlsDiary:update(dt, container)
		end, 0)
	end
end

function FetterGirlsDiary:update(dt, container)
	--FadeIn
	--if Limit and nowLine<Limit then
	--    NodeHelper:setMenuItemEnabled(container,"mTutorialSkip",false)
	--else
	--    NodeHelper:setMenuItemEnabled(container,"mTutorialSkip",true)
	--end
	if fadeTime then
		if fadeInitCfg["isInit"] then
			fadeInitCfg["isInit"] = false
			diarySpineFade:runAnimation(1, fadeAction, -1)
			mSpineFadeNode:setPosition(ccp((fadeInitCfg["tx"] - container:getVarNode("mAllSpineNode"):getPositionX()) / container:getVarNode("mAllSpineNode"):getScale(), (fadeInitCfg["ty"] - container:getVarNode("mAllSpineNode"):getPositionY()) / container:getVarNode("mAllSpineNode"):getScale()))
			mSpineFadeNode:setScale(fadeInitCfg["scale"] / container:getVarNode("mAllSpineNode"):getScale())
			mSpineFadeNode:setRotation(fadeInitCfg["rotate"] - container:getVarNode("mAllSpineNode"):getRotation())
		end
		fadeTimer = fadeTimer + dt
		if fadeTimer * 255 / fadeTime < 255 then
			mSpineNode:setOpacity(255 - (fadeTimer * 255 / fadeTime))
			mSpineFadeNode:setOpacity(fadeTimer * 255 / fadeTime)
		else
			local tempNode = mSpineNode
			mSpineNode = mSpineFadeNode
			mSpineFadeNode = tempNode
			mSpineNode:setOpacity(255)
			mSpineFadeNode:setOpacity(0)
			local tempSpine = diarySpine
			diarySpine = diarySpineFade
			diarySpineFade = tempSpine
			fadeTimer = 0
			fadeTime = nil
			fadeCount = fadeCount + 1
			fadeAction = ""
			local allSpineNode = container:getVarNode("mAllSpineNode")
			local truePos = ccp(mSpineNode:getPositionX() * allSpineNode:getScale() + allSpineNode:getPositionX(), mSpineNode:getPositionY() * allSpineNode:getScale() + allSpineNode:getPositionY())
			local trueScale = mSpineNode:getScale() * allSpineNode:getScale()
			local trueRotate = mSpineNode:getRotation() + allSpineNode:getRotation()
			mSpineNode:setPosition(ccp(0, 0))
			mSpineNode:setScale(1)
			mSpineNode:setRotation(0)
			allSpineNode:setPosition(truePos)
			allSpineNode:setScale(trueScale)
			allSpineNode:setRotation(trueRotate)
		end
	end
	--播放文字
	if nowLineTable and nowLineTable[lineIndex] then
		if not isLabelPlaying then
			NodeHelper:setStringForLabel(container, {mContent = lines[nowLine]})
			return
		end
		if labelTimer >= labelSpeed then
			local mLabel = container:getVarLabelTTF("mContent")
			mLabel:setDimensions(CCSizeMake(580, 200))
			local showLabel = mLabel:getString() .. nowLineTable[lineIndex].char
			mLabel:setString(showLabel)
			lineIndex = lineIndex + 1
			labelTimer = 0
		end
		if not nowLineTable[lineIndex] then
			isLabelPlaying = false
			if nowActionType == DiaryTypeNew.NONE then
				NodeHelper:setNodesVisible(container, {mTalkArrowNode = true})
			end
		--if lines[nowLine]==" " then
		--    self:onTouch(container)
		--end
		end
		labelTimer = labelTimer + 1
	end
	--Auto處理
	if PhotoSettingState.isAuto then
		if not isLabelPlaying and (nowActionType == DiaryTypeNew.NONE or nowActionType == DiaryTypeNew.FLASH) and not self:isPlayingVoice(container) then
			autoTimer = autoTimer + dt
		else
			autoTimer = 0
		end
		if autoTimer >= autoTime then
			FetterGirlsDiary:onTouch(container)
			autoTimer = 0
		end
	else
		autoTimer = 0
	end
end

function FetterGirlsDiary:onReturn(container)
	require("Battle.NgBattleResultManager")
	NgBattleResultManager.showMainStory = false
	NgBattleResultManager.showAlbum = false
	SoundManager:getInstance():stopAllEffect() --關閉音效
	self:onClose(container)
	if GuideManager.isInGuide then
		if storyIdx == 1 then
			GuideManager.forceNextNewbieGuide()
		end
	end
	if storyIdx == 2 then
		require("Battle.NgBattleResultManager")
		NgBattleResultManager_playNextResult()
	else
		local currPage = MainFrame:getInstance():getCurShowPageName()
		if currPage == "NgBattlePage" then  --回復BGM
			local sceneHelper = require("Battle.NgFightSceneHelper")
			sceneHelper:setGameBgm()
		else
			SoundManager:getInstance():playGeneralMusic()
		end
	end
end
--跳過新手影片
function FetterGirlsDiary:onTutorialSkip(container)
   local CanJump = false
   if Limit and Limit>0 and nowLine<Limit then
		CanJump = true
   end
	local title = common:getLanguageString("@SkipTitle")
	local msg = common:getLanguageString("@SkipStory")
	PageManager.showConfirm(title, msg, function(isSure)
		if isSure then
			if CanJump then
				FetterGirlsDiary:skipStory(container)
			else
				FetterGirlsDiary:onReturn(container)
			end
		end
	end, true, nil, nil, nil, 0.9);
end

function FetterGirlsDiary:removeSpinesSafely()
   local fetterCfgId = tonumber( string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx)
   if fetterCfgId == 1052 then return end --1-5避免閃退不刪除
   for i = 1, 3 do
       local spine = nowSpines[i]
       if spine and not tolua.isnull(spine) then
           local parent = spine.parent
           if parent and not tolua.isnull(parent) then
               local success, err = pcall(function()
                   
                   parent:removeAllChildrenWithCleanup(true)
                   parent = nil
               end)
               if not success then
                   print(string.format("Error replacing parent for spine %d: %s", i, err))
               end
           else
               CCLuaLog(string.format("Parent node of spine %d is invalid.", i))
           end
           nowSpines[i] = nil
       else
           CCLuaLog(string.format("Spine %d is already nil or invalid.", i))
       end
    end
end

function FetterGirlsDiary:skipStory(container)

    -- 安全建立並加入新的 spine
    local function createAndAddNewSpine()
        local parentNode = container:getVarNode("mChangeSpine")
        if parentNode and not tolua.isnull(parentNode) then
            local spinePath = "Spine/NGUI"
            local spineName = "NGUI_77_Shady"
            local success, spine = pcall(SpineContainer.create, SpineContainer, spinePath, spineName)
            if success and spine then
                parentNode:addChild(tolua.cast(spine, "CCNode"))
                spine:runAnimation(1, "quit", 0)
            else
                CCLuaLog("Failed to create spine: " .. (spine or "Unknown error"))
            end
        else
            CCLuaLog("Parent node for new spine is invalid.")
        end
    end

    -- 處理跳過動畫後的回呼
    local function onSkipComplete()
        isSkipping = false
        nowLine = Limit - 1
        local success, err = pcall(function()
            self:onTouch(container)
            SoundManager:getInstance():stopMusic()
        end)
        if not success then
            CCLuaLog("Error during onTouch: " .. err)
        end
    end

    -- 防止 container 無效情況，並建立動畫序列
    if container and not tolua.isnull(container) then
        local array = CCArray:create()
        array:addObject(CCCallFunc:create(function()
            isSkipping = true
            createAndAddNewSpine()  -- 建立並加入新的 spine
        end))
        array:addObject(CCDelayTime:create(2))  -- 延遲 2 秒
        array:addObject(CCCallFunc:create(onSkipComplete))
        array:addObject(CCCallFunc:create(function()
            FetterGirlsDiary:removeSpinesSafely()
        end))

        local success, err = pcall(function()
            container:runAction(CCSequence:create(array))
        end)
        if not success then
            CCLuaLog("Error running container action: " .. err)
        end
    else
        CCLuaLog("Container is invalid or already nil.")
    end
end

------------------------------------- 功能表
function FetterGirlsDiary:onHide(container) --隱藏視窗
	--if areaNum == 99 then    --新手教學
	--    MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
	--    return
	--end
	NodeHelper:setNodesVisible(container, {mReturn = false, mStory = false, mControlBtn = false})
	nowState = DiaryState.HIDE
	NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
	PhotoSettingState.isAuto = false
end

function FetterGirlsDiary:onAuto(container) --自動播放
	--if areaNum == 99 then    --新手教學
	--    MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
	--    return
	--end
	if PhotoSettingState.isAuto then
		NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
		PhotoSettingState.isAuto = false
	else
		NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_ON.png", press = "Fetter_Btn_Auto_OFF.png"}})
		PhotoSettingState.isAuto = true
	end
end

function FetterGirlsDiary:onSilent(container) --靜音
	--if areaNum == 99 then    --新手教學
	--    MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
	--    return
	--end
	if PhotoSettingState.isSilent == true then
		NodeHelper:setMenuItemImage(container, { mVoiceBtn = { normal = "Fetter_Btn_Voice_ON.png", press = "Fetter_Btn_Voice_OFF.png" } })
		PhotoSettingState.isSilent = false
	else
		NodeHelper:setMenuItemImage(container, { mVoiceBtn = { normal = "Fetter_Btn_Voice_OFF.png", press = "Fetter_Btn_Voice_ON.png" } })
		PhotoSettingState.isSilent = true
		self:stopVoice(container)
	end
end

function FetterGirlsDiary:onLog(container) --開啟Log
	--if areaNum == 99 then    --新手教學
	--    MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
	--    return
	--end
	self:stopVoice(container)
	self:setAllLogContent(container)
	self:clearAndReBuildAllLog(container)
	NodeHelper:setNodesVisible(container, { mLogNode = true })
	NodeHelper:setMenuItemImage(container, { mLogBtn = { normal = "Fetter_Btn_Log_ON.png", press = "Fetter_Btn_Log_OFF.png" } })
	if PhotoSettingState.isAuto then
		NodeHelper:setMenuItemImage(container, { mAutoBtn = { normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png" } })
		PhotoSettingState.isAuto = false
	end
end

function FetterGirlsDiary:onCloseLog(container) --關閉Log
	--if areaNum == 99 then    --新手教學
	--    MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
	--    return
	--end
	NodeHelper:setNodesVisible(container, { mLogNode = false })
	NodeHelper:setMenuItemImage(container, { mLogBtn = { normal = "Fetter_Btn_Log_OFF.png", press = "Fetter_Btn_Log_ON.png" } })
end

function FetterLogContent:new(o)
	o = o or { }
	setmetatable(o, self)
	self.__index = self
	return o
end

function FetterLogContent:onRecall(container)
	if areaNum == 99 then    --新手教學
		MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
		return
	end
	FetterGirlsDiary:playTargetVoice(container, self.id)
end

function FetterLogContent:onJump(container)
	if areaNum == 99 then    --新手教學
		MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
		return
	end
	testNowLine = self.id
	FetterGirlsDiary:setLineState(FetterGirlsDiary:getContainer())
	FetterGirlsDiary:onCloseLog(FetterGirlsDiary:getContainer())
end

function FetterLogContent:onRefreshContent(ccbRoot)
	local container = ccbRoot:getCCBFileNode()
	 local parentNode = container:getVarLabelTTF("mDiaTxt")
	 parentNode:setString("")
	 parentNode:removeAllChildrenWithCleanup(true)
	 local htmlModel = FreeTypeConfig[702].content
	 local msgHtml = NodeHelper:addHtmlLable(parentNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", FetterLogContent.logTxt[self.id]), 0, CCSizeMake(580, 200))
	 local htmlHeight = msgHtml:getContentSize().height
	 local msgBgHeight = htmlHeight+90
	 if FetterLogContent.logName[self.id]=="" then msgBgHeight=msgBgHeight-40 end
	 local Bg = container:getVarScale9Sprite("mSprite")
	 Bg:setContentSize(CCSize(Bg:getContentSize().width, msgBgHeight))
		NodeHelper:setStringForLabel(container, {
		mDiaName = FetterLogContent.logName[self.id],
		--mDiaTxt = FetterLogContent.logTxt[self.id],
	} );
	container:getVarNode("mDiaName"):setPositionY(msgBgHeight-30)
	NodeHelper:setNodesVisible(container, {
		mRecallBtn = FetterLogContent.logVoice[self.id]
	} );
end

function FetterGirlsDiary:clearAndReBuildAllLog(container)
	local logScrollView = container:getVarScrollView("mLogScrollView")
	logScrollView:removeAllCell()
	for i = 1, #FetterLogContent.logTxt do
		if FetterLogContent.logTxt[i]~=" " then
			local logCell = CCBFileCell:create()
			local panel = FetterLogContent:new( { id = i })
			logCell:registerFunctionHandler(panel)
			logCell:setCCBFile(FetterLogContent.ccbi)
			logScrollView:addCellBack(logCell)
			local height=FetterGirlsDiary:calStringHeight(FetterLogContent.logTxt[i])+100
			if FetterLogContent.logName[i]=="" then height=height-40 end
			logCell:setContentSize(CCSizeMake(logCell:getContentSize().width,height))
		end
	end
	logScrollView:orderCCBFileCells()
	logScrollView:locateToByIndex(#FetterLogContent.logTxt - 1, CCBFileCell.LT_Bottom)
end
function FetterGirlsDiary:calStringHeight(msg)
	local tempNode = CCNode:create()
	local htmlModel = FreeTypeConfig[702].content
	local msgHtml = NodeHelper:addHtmlLable(tempNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", msg), 0, CCSizeMake(680, 200))
	local htmlHeight = msgHtml:getContentSize().height

	return htmlHeight
end
function FetterGirlsDiary:setAllLogContent(container)
	FetterLogContent.logName = { }
	FetterLogContent.logTxt = { }
	FetterLogContent.logVoice = { }
	for i = 1, logNowLine do
			--logTxt
			table.insert (FetterLogContent.logTxt,lines[i])
			FetterLogContent.logTxt[i] = lines[i]
			--logName
			local fetterCfgId = tonumber( string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", i))
			local roleId = fetterControlCfg[fetterCfgId].role
			if roleId then
				FetterLogContent.logName[i] = common:getLanguageString("@HeroName_" .. roleId)
			else
				FetterLogContent.logName[i] = ""
			end
			--logVoice
			--local voiceName = "Voice" .. string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", i) .. ".mp3"
			--local isFileExist = NodeHelper:isFileExist("/audio/" .. voiceName)
			--FetterLogContent.logVoice[i] = isFileExist
	  end
end

------------------------------------- 功能表END

function FetterGirlsDiary:onTouch(container, eventName)
	--if areaNum == 99 and eventName == "onTouch" then    --新手教學
	--    MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
	--    return
	--end
    if not container then container = self.container end
    if Limit and nowLine == Limit then
        local parentNode = container:getVarNode("mChangeSpine")
        if parentNode then
            parentNode:removeAllChildren() 
        end
    end
	if isSkipping then return end
	if eventName == "onTouch" and PhotoSettingState.isAuto then
		NodeHelper:setMenuItemImage(container, { mAutoBtn = { normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png" } })
		PhotoSettingState.isAuto = false
		isLabelPlaying=true
	end
	if isBgMoving then return end
	if nowState == DiaryState.SPINE then
		--演出
		if isLabelPlaying then
			isLabelPlaying = false
			if nowActionType == DiaryTypeNew.NONE then
				NodeHelper:setNodesVisible(diaryContainer , { mTalkArrowNode = true })
			end
			return
		end
		if not isEndLineAct and (nowActionType == DiaryTypeNew.NONE or nowActionType == DiaryTypeNew.NEXTLINE or nowActionType == DiaryTypeNew.AUTOCLICK) then
			nowLine = nowLine + 1
			if nowLine > logNowLine then
				logNowLine = nowLine
			end
			-- 當前fetterControlId
			local nowControlId = FetterGirlsDiary:getNowControlId(diaryContainer )
			-- 當前fetterControlCfg
			local nowControlCfg = fetterControlCfg[nowControlId]
			--關閉對話提示
			NodeHelper:setNodesVisible(diaryContainer , { mTalkArrowNode = false })
			if string.find(lines[nowLine], "@") then --劇情結束
				nowLine = nowLine - 1
				logNowLine = nowLine
				self:onReturn(diaryContainer )
				return
			end
			--顯示當前行數(Debug功能)
			if NodeHelper:isDebug() then
				NodeHelper:setStringForLabel(diaryContainer , { mTestNowLine = "NowLine: " .. nowLine })
				NodeHelper:setStringForLabel(diaryContainer , { mTestNowAction = "NowAction:" })
			end
			--切換BG
			local newBgName = nowControlCfg.bg
			if newBgName ~= nowBgName then
				local sprite = diaryContainer :getVarSprite("mBg")
				if newBgName == "" then
					sprite:setTexture("UI/Mask/Image_Empty.png")
				else
					sprite:setTexture(newBgName)
				end
				nowBgName = newBgName
			end
			--切換BGM
			local newBgmName = nowControlCfg.bgm
			if newBgmName ~= nowBgmName then
				if newBgmName == "" then
					SoundManager:getInstance():stopMusic()  --關閉BGM
				else
					SoundManager:getInstance():playMusic(newBgmName)
				end
				nowBgmName = newBgmName
			end
			--播放語音
			--FetterGirlsDiary:playVoice(diaryContainer )
			--播放其他音效
            autoTime = nowControlCfg.AutoWait or 2
            if autoTime == 0 then autoTime = 2 end

           FetterGirlsDiary:PlayEffectTable(container, nowControlCfg.eff)
			--
			local roleId = nowControlCfg.role
			if roleId then
				NodeHelper:setStringForLabel(diaryContainer , { mTitle = common:getLanguageString("@HeroName_" .. roleId) })
			else
				NodeHelper:setStringForLabel(diaryContainer , { mTitle = "" })
			end
			nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
			labelTimer = 0
			lineIndex = 1
			NodeHelper:setStringForLabel(diaryContainer , { mContent = "" })
			isLabelPlaying = true
			--播放動作
			FetterGirlsDiary:playActionsNew(diaryContainer )
		elseif isEndLineAct then
			FetterGirlsDiary:playActionsNew(diaryContainer )
		end
	elseif nowState == DiaryState.HIDE then
		NodeHelper:setNodesVisible(diaryContainer , { mReturn = true, mStory = true, mControlBtn = true })
		nowState = DiaryState.SPINE 
	end
end
function FetterGirlsDiary:PlayEffectTable(container, soundTxt)
    SoundManager:getInstance():stopAllEffect()
    local EffectTable = common:split(soundTxt, ";")  -- 分割音效列表
    local array = CCArray:create()  -- 建立一個統一的動作陣列

    -- 從音效檔名中提取秒數和檔案名稱
    local function getDurationAndNameFromFilename(name)
        local parts = common:split(name, ",")  -- 分割出時間和檔案名稱部分
        
        if not parts[2] then
            return 0,parts[1]
        else
            return tonumber(parts[1]) or 0, parts[2] or ""
        end
    end

    -- 當前時間的基準（絕對時間從序列的開始計算）
    local previousTime = 0  

    -- 遍歷音效表，構建播放邏輯
    for _, soundFile in ipairs(EffectTable) do
        local delayTime, filename = getDurationAndNameFromFilename(soundFile)

        if filename ~= "" and NodeHelper:isFileExist("/audio/" .. filename) then
            -- 計算相對於序列起始點的延遲
            local relativeDelay = delayTime - previousTime
            previousTime = delayTime  -- 更新基準時間

            -- 添加延遲動作（若相對延遲大於 0 才執行）
            if relativeDelay > 0 then
                array:addObject(CCDelayTime:create(relativeDelay))
            end

            -- 添加播放音效的動作
            array:addObject(CCCallFunc:create(function()
                print("播放音檔: " .. filename)
                SoundManager:getInstance():playEffectByName(filename, false)
            end))
        else
            print("音檔不存在或無效: " .. (filename or "未知"))
        end
    end

    -- 添加一個結束回呼（可選）
    array:addObject(CCCallFunc:create(function()
        print("所有音檔播放完畢")
    end))

    -- 執行動作序列
    container:runAction(CCSequence:create(array))
end
function FetterGirlsDiary.onFunction(eventName, container)
	if eventName ~= "luaExecute" then
	end
	if eventName == "luaInit" then
		FetterGirlsDiary:onInit(container)
	elseif eventName == "luaLoad" then
		FetterGirlsDiary:onLoad(container)
	elseif eventName == "luaEnter" then
		FetterGirlsDiary:onEnter(container)
	end
end

function FetterGirlsDiary:initSpine(container)
	mSpineNode = container:getVarNode("mSpine")
	mSpineNode:removeAllChildrenWithCleanup(true)
	mSpineFadeNode = container:getVarNode("mSpineFade")
	mSpineFadeNode:removeAllChildrenWithCleanup(true)
	local startId = tonumber( string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. "00")
	local cfg = fetterMovementCfg[tonumber(startId .. "01")]
	if not cfg then
		return
	end
	local aniName, spinePath, spineFile = unpack(common:split((cfg.spine), ","))
	if not aniName or not spinePath or not spineFile then
		return
	end
	local path, roleName = unpack(common:split((spinePath), "/"))

	--預載Spine
	spineFiles = { }
	spineKey = { }
	spineKey[spineFile] = 1
	spineKey[spineFile .. "Fade"] = 2
	spineFiles[spineKey[spineFile]] = SpineContainer:create(spinePath, spineFile, 1)
	spineFiles[spineKey[spineFile .. "Fade"]] = SpineContainer:create(spinePath, spineFile, 1)
	--local spineNode = tolua.cast(spineFiles[spineKey[spineFile]], "CCNode")
	--local spineFadeNode = tolua.cast(spineFiles[spineKey[spineFile .. "Fade"]], "CCNode")
	--mSpineNode:addChild(spineNode)
	--mSpineFadeNode:addChild(spineFadeNode)

	FetterGirlsDiary:showTargetSpine(container, spineFile)
	
	diarySpine = spineFiles[spineKey[spineFile]]
	diarySpineFade = spineFiles[spineKey[spineFile .. "Fade"]]
	
	spineNode = container:getVarNode("mAllSpineNode")
	
	diarySpine:runAnimation(1, aniName, -1)
	diarySpineFade:runAnimation(1, aniName, -1)

	local trans = common:split(cfg.transform, "_")
	local tx, ty = unpack(common:split((trans[1]), ","))
	local rotate = common:split(cfg.rotate, ",")
	local scale = common:split(cfg.scale, ",")

	spineNode:setPosition(ccp(tonumber(tx), tonumber(ty)))
	spineNode:setScale(tonumber(scale[1]))
	spineNode:setRotation(tonumber(rotate[1]))
	
	mSpineFadeNode:setOpacity(0)
end

function FetterGirlsDiary:initSetting(container)
	--end
	local langForward = "@ChapterStory"
	for i = 1, 99 do 
		local str = common:getLanguageString(langForward .. string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", i))
		--local str=NodeHelper:FunSetLinefeed(tmp,63)
		if str == "#blank#" then
			str=" "
		end
		lines[i] = str
		if string.find(lines[i], langForward) then
			break
		end
	end
	---------------------------------------------------------------------------------
	--
	nowLine = 1
	logNowLine = 1
	NodeHelper:setStringForLabel(container, { mTestNowLine = "NowLine: " .. nowLine })
	nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
	isLabelPlaying = true
	lineIndex = 1
	labelTimer = 0
	PhotoSettingState.isAuto = false
	PhotoSettingState.isSilent = false
	fadeAction = ""
	fadeCount = 0
	fadeTimer = 0
	fadeTime = nil
	fadeInitCfg = { }
	isEndLineAct = false
	nowActionType = DiaryTypeNew.NONE
	NodeHelper:setStringForLabel(container, { mContent = "" })
	NodeHelper:setMenuItemImage(container, { mAutoBtn = { normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png" } })
	NodeHelper:setMenuItemImage(container, { mVoiceBtn = { normal = "Fetter_Btn_Voice_ON.png", press = "Fetter_Btn_Voice_OFF.png" } })
	NodeHelper:setMenuItemImage(container, { mLogBtn = { normal = "Fetter_Btn_Log_OFF.png", press = "Fetter_Btn_Log_ON.png" } })
	local cfgId = tonumber( string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. "01")
	
	local roleId = fetterControlCfg[cfgId].role
	if roleId then   --少東
		NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@HeroName_" .. roleId) })
	else
		NodeHelper:setStringForLabel(container, { mTitle = "" })
	end
	nowBgName = fetterControlCfg[cfgId].bg
	local sprite = container:getVarSprite("mBg")
	if nowBgName == "" then
		sprite:setTexture("UI/Mask/Image_Empty.png")
	else
		sprite:setTexture(nowBgName)
	end
	sprite:setScale(sprite:getScale())
	SoundManager:getInstance():stopMusic()  --關閉BGM
	SoundManager:getInstance():playMusic(fetterControlCfg[cfgId].bgm)
	nowBgmName = fetterControlCfg[cfgId].bgm
	autoTime = fetterControlCfg[cfgId].AutoWait or 2
    	if autoTime == 0 then autoTime = 2 end
    	FetterGirlsDiary:PlayEffectTable(container, fetterControlCfg[cfgId].eff)
	--預設開啟黑幕
	container:runAnimation("F4")
	NodeHelper:setNodesVisible(container, {mTalkArrowNode = false})
	
	--FetterGirlsDiary:playVoice(container)
	Limit=FetterGirlsDiary:HSPINESync(container)
end

function FetterGirlsDiary:getMercenaryId(roleId)
	local roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
	for i = 1, #roleInfos do
		if roleInfos[i].itemId == roleId then
			return roleInfos[i].roleId
		end
	end
end

function FetterGirlsDiary:refreshPage(container)
end

function FetterGirlsDiary:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function FetterGirlsDiary:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	if opcode == HP_pb.ITEM_USE_S then
		FetterManager.reqFetterInfo()
	elseif opcode == HP_pb.FETCH_ARCHIVE_INFO_S then
		local msg = RoleOpr_pb.HPArchiveInfoRes()
		local msgbuff = container:getRecPacketBuffer()
		msg:ParseFromString(msgbuff)
		FetterManager.initFetter(msg)
		FetterGirlsDiary:refreshPage(container)
	end
end

-------------------------------------------------------------------------
--  NEW ACT FUNCTION
-------------------------------------------------------------------------
function FetterGirlsDiary:getMovementPara(container, id)
	local movementCfg = fetterMovementCfg[id]
	if not movementCfg then
		return
	end
	local para = {}
	para.actionType = tonumber(movementCfg.actionType)
	para.spine = movementCfg.spine
	para.wait = movementCfg.wait
	para.transform = movementCfg.transform
	para.rotate = movementCfg.rotate
	para.scale = movementCfg.scale
	para.time = movementCfg.time
	para.define=movementCfg.define
	para.position=movementCfg.position
	para.spawnId = tonumber(movementCfg.spawnId)
	return para
end

function FetterGirlsDiary:createAction(container, para, action, bgAction, chAction)
	local actType = para.actionType
	local spine =  para.spine
	local wait =  tonumber(para.wait)
	local trans =  para.transform
	local pos=para.position or "0,0"
	local define=para.define
	local rotate =  tonumber(para.rotate)
	local scale =  tonumber(para.scale)
	local time =  tonumber(para.time)
	local parent = tonumber(para.parent)
	local tx = 0 
	local ty = 0
	if wait and wait > 0 then
		action:addObject(CCCallFunc:create(function()
			nowActionType = DiaryTypeNew.WAIT
		end))
		action:addObject(CCDelayTime:create(wait))
		bgAction:addObject(CCDelayTime:create(wait))
		chAction:addObject(CCDelayTime:create(wait))
	end
	--if NodeHelper:isDebug() then
	--    if not para.wait then
	--        para.wait = "nil"
	--    end
	--end
	action:addObject(CCCallFunc:create(function()
		nowActionType = actType
	end))
	if actType == DiaryTypeNew.SPINE then   --切換spine animation
		action:addObject(CCCallFunc:create(function()
			--顯示當前動作(Debug功能)
			if NodeHelper:isDebug() then
				local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
				NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 1(Spine Ani), Wait: " .. para.wait ..
																							   ", Ani: " .. para.spine })
			end
			if nowSpines[define] then
				nowSpines[define]:runAnimation(1, spine, -1)
			end
		end))
	elseif actType == DiaryTypeNew.TRANS then   --切換向量
		if trans and trans ~= "" then
			tx, ty = unpack(common:split((trans), ","))
			tx = tonumber(tx)
			ty = tonumber(ty)
		end
		local spawnAction = CCArray:create()
		--顯示當前動作(Debug功能)
		if NodeHelper:isDebug() then
			local bgStr = ""
			if tonumber(spine) == 1 then
				bgStr = ", BgAct: TRUE"
			else
				bgStr = ", BgAct: FALSE"
			end
			action:addObject(CCCallFunc:create(function()
				local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
				NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 2(Vector), Wait: " .. para.wait .. 
																								 ", Time: " .. para.time .. 
																								 ", MoveTo: (" .. para.transform .. ")" ..
																								 ", \n              ScaleTo: " .. para.scale .. 
																								 ", RotateTo: " .. para.rotate .. 
																								 bgStr })
			end))
		end
		spawnAction:addObject(CCMoveTo:create(time, ccp(tx, ty)))
		spawnAction:addObject(CCScaleTo:create(time, scale))
		spawnAction:addObject(CCRotateTo:create(time, rotate))
		action:addObject(CCSpawn:create(spawnAction))
		if tonumber(spine) == 1 then
			local spawnBgAction = CCArray:create()
			spawnBgAction:addObject(CCMoveTo:create(time, ccp(tx, ty)))
			spawnBgAction:addObject(CCScaleTo:create(time, scale))
			spawnBgAction:addObject(CCRotateTo:create(time, rotate))
			bgAction:addObject(CCSpawn:create(spawnBgAction))
		end
		if parent == 1 then
			local spawnChAction = CCArray:create()
			spawnChAction:addObject(CCMoveTo:create(time, ccp(tx, ty)))
			spawnChAction:addObject(CCScaleTo:create(time, scale))
			spawnChAction:addObject(CCRotateTo:create(time, rotate))
			chAction:addObject(CCSpawn:create(spawnChAction))
		end
	elseif actType == DiaryTypeNew.FADEIN then  --淡入效果
		if trans and trans ~= "" then
			tx, ty = unpack(common:split((trans), ","))
			tx = tonumber(tx)
			ty = tonumber(ty)
		end
		local ani, isBgAct = unpack(common:split(spine, ","))
		--diarySpineFade:runAnimation(1, ani, -1)
		fadeInitCfg["isInit"] = true
		fadeInitCfg["tx"] = tx
		fadeInitCfg["ty"] = ty
		fadeInitCfg["scale"] = scale
		fadeInitCfg["rotate"] = rotate
		fadeAction = spine
		action:addObject(CCCallFunc:create(function()
			--顯示當前動作(Debug功能)
			if NodeHelper:isDebug() then
				local bgStr = ""
				if tonumber(isBgAct) == 1 then
					bgStr = ", BgAct: TRUE"
				else
					bgStr = ", BgAct: FALSE"
				end
				local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
				NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 3(FadeIn), Wait: " .. para.wait .. 
																								 ", Time: " .. para.time .. 
																								 ", MoveTo: (" .. para.transform .. ")" ..
																								 ", \n              ScaleTo: " .. para.scale .. 
																								 ", RotateTo: " .. para.rotate .. 
																								 ", Ani: " .. para.spine ..
																								 bgStr })
			end
			fadeTime = time
		end))
		if tonumber(isBgAct) == 1 then
			local spawnBgAction = CCArray:create()
			action:addObject(CCCallFunc:create(function()
				if nowBgName == "" then
				   fadeBgSprite:setTexture("UI/Mask/Image_Empty.png")
				else
				   fadeBgSprite:setTexture(nowBgName)
				end
				fadeBgSprite:setOpacity(0)
				fadeBgSprite:setPosition(ccp(tx, ty))
				fadeBgSprite:setScale(scale)
				fadeBgSprite:setRotation(rotate)
				local fadeBgAction = CCArray:create()
				fadeBgAction:addObject(CCFadeIn:create(time + 0.1))
				fadeBgAction:addObject(CCFadeOut:create(0))
				fadeBgSprite:runAction(CCSequence:create(fadeBgAction))
			end))
			bgAction:addObject(CCDelayTime:create(time))
			bgAction:addObject(CCCallFunc:create(function()
				local sprite = container:getVarSprite("mBg")
				sprite:setPosition(ccp(tx, ty))
				sprite:setScale(scale)
				sprite:setRotation(rotate)
			end))
		end
	elseif actType == DiaryTypeNew.ANIMATION then   --UI animation
		action:addObject(CCCallFunc:create(function()
			--顯示當前動作(Debug功能)
			if NodeHelper:isDebug() then
				local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
				NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 4(UI Ani), Wait: " .. para.wait ..
																								 ", Ani: " .. para.spine })
			end
			container:runAnimation(spine)
		end))
	elseif actType == DiaryTypeNew.WAITLINE then   --標記對話結束後點擊進行動作
		if isEndLineAct then
			isEndLineAct = false
		else
			isEndLineAct = true
			--顯示當前動作(Debug功能)
			if NodeHelper:isDebug() then
				local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
				NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 5(End Act)" })
			end
		end
	elseif actType == DiaryTypeNew.NEXTLINE then   --切換下一段劇情
		action:addObject(CCCallFunc:create(function()
			--顯示當前動作(Debug功能)
			if NodeHelper:isDebug() then
				local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
				NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 6(Next Line), Wait: " .. para.wait })
			end
			isLabelPlaying=false
			FetterGirlsDiary:onTouch(container)
		end))
	elseif actType == DiaryTypeNew.VISIBLEUI then   --開關UI顯示
		if isUiVisible == true then
			action:addObject(CCCallFunc:create(function()
				--顯示當前動作(Debug功能)
				if NodeHelper:isDebug() then
					local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
					NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 7(Close UI), Wait: " .. para.wait })
				end
				NodeHelper:setNodesVisible(container, { mReturn = false, mStory = false, mControlBtn = false })
			end))
			if not isEndLineAct then
				isUiVisible = false
			end
		else
			action:addObject(CCCallFunc:create(function()
				--顯示當前動作(Debug功能)
				if NodeHelper:isDebug() then
					local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
					NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 7(Open UI), Wait: " .. para.wait })
				end
				NodeHelper:setNodesVisible(container, { mReturn = true, mStory = true, mControlBtn = true })
			end))
			if not isEndLineAct then
				isUiVisible = true
			end
		end
	elseif actType == DiaryTypeNew.HALFBODY then    --半身像顯示
		action:addObject(CCCallFunc:create(function()
			--顯示當前動作(Debug功能)
			if NodeHelper:isDebug() then
				local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
				NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 8(Halfbody), Wait: " .. para.wait ..
																								 ", Img: " .. para.spine })
			end
			if spine == "" then
				NodeHelper:setSpriteImage(container, { mHalfbody = "UI/Mask/Image_Empty.png" })
			else
				NodeHelper:setSpriteImage(container, { mHalfbody = spine })
			end
		end))
	elseif actType == DiaryTypeNew.SPINEFILE then    --切換SPINE檔案
        action:addObject(CCDelayTime:create(para.wait))
		action:addObject(CCCallFunc:create(function()
			--顯示當前動作(Debug功能)
			if NodeHelper:isDebug() then
				local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
				NodeHelper:setStringForLabel(container, { mTestNowAction = testActionStr .. "\n" .. "Type 9(Change Spine), Wait: " .. para.wait ..
																								 ", MoveTo: (" .. para.transform .. ")" ..
																								 ", \n              ScaleTo: " .. para.scale .. 
																								 ", RotateTo: " .. para.rotate ..
																								 ", \n              Spine: " .. para.spine
																								  })
			end
			local ani, path, name = unpack(common:split((para.spine), ","))
			local diarySpine = SpineContainer:create(path, name, 1)
			local parentNode = nil
			if define==1 then
				parentNode=container:getVarNode("mSpineL")
			elseif define==2 then
				parentNode=container:getVarNode("mSpineR")
			else
				parentNode=container:getVarNode("mSpineC")
			end
			parentNode:setPositionX(0)
			nowSpines[define]=diarySpine
			nowSpines[define].parent=parentNode
			spineNode = tolua.cast(diarySpine, "CCNodeRGBA")
			spineNode:setColor(ccc3(128,128,128))
			--spineFadeNode = tolua.cast(diarySpineFade, "CCNode")
			--FetterGirlsDiary:showTargetSpine(container, name)
			local px,py=0,0
			if pos and pos ~= "0,0" then
				px, py = unpack(common:split((pos), ","))
				px = tonumber(px)
				py = tonumber(py)
			end
			spineNode:setPosition(ccp(px, py))
			spineNode:setScaleX(tonumber(scale))
			spineNode:setRotation(rotate)
			diarySpine:runAnimation(1, ani, -1)
			parentNode:addChild(spineNode)
			spineNode:setOpacity(0)
			local SpineAction = CCArray:create()
			SpineAction:addObject(CCFadeIn:create(0.5)) 
			spineNode:runAction(CCSequence:create(SpineAction))
		end))
	elseif actType == DiaryTypeNew.SPINEMOVMENT then
		action:addObject(CCCallFunc:create(function()
			local SpineAction = CCArray:create()
				if trans and trans ~= "0" then
				tx, ty = unpack(common:split((trans), ","))
				tx = tonumber(tx)
				ty = tonumber(ty)
			end
			SpineAction:addObject(CCMoveTo:create(time, ccp(tx, ty)))
			SpineAction:addObject(CCScaleTo:create(time, scale ,1 ))
			SpineAction:addObject(CCRotateTo:create(time, rotate))
			nowSpines[define].parent:runAction(CCSequence:create(SpineAction))
			end))
	elseif actType == DiaryTypeNew.DELSPINE then
		action:addObject(CCCallFunc:create(function()
			spineNode = tolua.cast(nowSpines[define], "CCNode")
			local SpineAction = CCArray:create()
			SpineAction:addObject(CCFadeOut:create(0.1))
			SpineAction:addObject(CCDelayTime:create(0.1))
			local clear = CCCallFunc:create(function()
                if nowSpines[define] then
				    nowSpines[define].parent:removeAllChildrenWithCleanup(true)
				    nowSpines[define] = nil
                end
			end)
			SpineAction:addObject(clear)
			spineNode:runAction(CCSequence:create(SpineAction))
			end))
	elseif actType == DiaryTypeNew.BGCHANGE then
        action:addObject(CCCallFunc:create(function()
            -- 設定新的背景名稱
            local newBgName = para.spine
            if newBgName == "" then
                newBgName = nowBgName
            end
            local sprite = container:getVarSprite("mBg")

            -- 更新背景位置（如果有 pos 參數）
            if pos and pos ~= "0" then
                local px, py = unpack(common:split(pos, ","))
                px = tonumber(px)
                py = tonumber(py)
                sprite:setPosition(ccp(-px, -py))
            end

            -- 如果背景發生變化，更新背景紋理
            if newBgName ~= nowBgName then
                if newBgName == "" then
                    sprite:setTexture("UI/Mask/Image_Empty.png")
                else
                    sprite:setTexture(newBgName)
                end
                nowBgName = newBgName
            end

            -- 動作容器
            local BgAction = CCArray:create()

            -- 設定背景移動狀態標誌
            BgAction:addObject(CCCallFunc:create(function() isBgMoving = true end))

            -- 緩動效果函數
            local function applyEase(action, speed)
                if speed > 0 then
                    return CCEaseIn:create(action, speed)
                elseif speed < 0 then
                    return CCEaseOut:create(action, math.abs(speed))
                end
                return action
            end

            -- 添加移動動作（如果有 trans 參數）
            if trans and trans ~= "0" then
                local tx, ty = unpack(common:split(trans, ","))
                tx = tonumber(tx)
                ty = tonumber(ty)
                local moveAction = CCMoveTo:create(time, ccp(-tx, -ty))
                local moveSpeed = para.define
                moveAction = applyEase(moveAction, moveSpeed)
                BgAction:addObject(moveAction)
            end

            -- 添加縮放動作
            BgAction:addObject(CCScaleTo:create(time, scale))

            -- 添加旋轉動作
            BgAction:addObject(CCRotateTo:create(time, rotate))

            -- 將所有動作並行執行
            if BgAction:count() > 0 then
                local spawnAction = CCSpawn:create(BgAction)
                BgAction:removeAllObjects()
                BgAction:addObject(spawnAction)
            end

            -- 動作結束後回調，重置移動標誌
            BgAction:addObject(CCCallFunc:create(function() isBgMoving = false end))

            -- 執行背景動畫動作序列
            sprite:runAction(CCSequence:create(BgAction))
        end))
	elseif actType==DiaryTypeNew.SHAKE then
		  action:addObject(CCCallFunc:create(function()
			local ShakeNodeOriPosX=diaryContainer:getVarNode("mShakeNode"):getPositionX()
			local totalShakeTime 
			if time>0 then
				totalShakeTime=para.time/10
			elseif time==0 then
				totalShakeTime=0.1
			end
			local singleShakeTime = 0.05 
			local repeatCount = math.floor(totalShakeTime / (singleShakeTime * 2))  
			 for i = 1, 2 do
				 local shakeNode = diaryContainer:getVarNode(i == 1 and "mShakeNode" or "mBg")
				 if not shakeNode:getActionByTag(SHAKE_ACTION_TAG + i) then
					 shakeNode:stopActionByTag(SHAKE_ACTION_TAG + i)
					 local array = CCArray:create()
					 local direction = 1
					 for j = 1, repeatCount do
						array:addObject(CCMoveBy:create(singleShakeTime, ccp(10 *direction* math.tan(math.deg(18)), -10)))
						array:addObject(CCMoveBy:create(singleShakeTime, ccp(10 *direction* math.atan(math.deg(54)), 10)))
						direction = -direction
					 end
					 if i==1 then
						 array:addObject(CCMoveTo:create(0.05, ccp(ShakeNodeOriPosX, 0)))
					 else
						array:addObject(CCMoveTo:create(0.05, ccp(0, 0)))
					end
					local action = CCSequence:create(array)
					action:setTag(SHAKE_ACTION_TAG + i)
					shakeNode:runAction(action)
				end
			end
		end))
	elseif actType == DiaryTypeNew.SETCOLOR then
		action:addObject(CCCallFunc:create(function()
			if nowSpines[define] then
				-- 將 nowSpines[define] 轉換為 CCNodeRGBA
				local colorNode = tolua.cast(nowSpines[define], "CCNodeRGBA")
				local spineNode = tolua.cast(nowSpines[define], "CCNode")
				local originPosX = spineNode:getPositionX()
                local originScaleY = spineNode:getScaleY()
                local originScaleX = spineNode:getScaleX()
                if originScaleX>0 then originScaleX = 1 else originScaleX = -1 end
				-- 根據 spine 值決定動作參數
				local isInactive = tonumber(spine) == 0
				local inactiveColor = ccc3(128, 128, 128)
				local activeColor = ccc3(255, 255, 255)
				local targetColor = isInactive and inactiveColor or activeColor
				local moveOffsetStart = isInactive and -1 or 30
				local moveOffsetEnd = isInactive and 0 or 20
                local scaleOffsetStart = isInactive and 0.99 or 1.06
                local scaleOffsetEnd = isInactive and 1 or 1.05
                local zOrder = isInactive and 1 or 2

				-- 設置顏色
				colorNode:setColor(targetColor)
                nowSpines[define].parent:setZOrder(zOrder)
				-- 創建 Spine 動作序列
				local spineActions = CCArray:create()
				spineActions:addObject(CCMoveTo:create(0.1, ccp(originPosX,  moveOffsetStart)))
				spineActions:addObject(CCScaleTo:create(0.1, scaleOffsetStart*originScaleX,scaleOffsetStart))
				spineActions:addObject(CCDelayTime:create(0.05))
				spineActions:addObject(CCMoveTo:create(0.05, ccp(originPosX, moveOffsetEnd)))
				spineActions:addObject(CCScaleTo:create(0.05, scaleOffsetEnd*originScaleX,scaleOffsetEnd))
				-- 執行動作
				spineNode:runAction(CCSequence:create(spineActions))
			end

		end))
	elseif actType == DiaryTypeNew.CHANGESPINE then
		action:addObject(CCCallFunc:create(function()
			local parentNode = container:getVarNode("mChangeSpine")
			local spinePath = "Spine/NGUI"
			local spineName = "NGUI_90_blacktransition"
			if para.spine == "F1" then
				spineName = "NGUI_90_blacktransition"
			elseif para.spine == "F2" then
				spineName = "NGUI_89_slash"
				local ShakeNodeOriPosX = diaryContainer:getVarNode("mShakeNode"):getPositionX()
				for i = 1, 2 do
					local shakeNode = diaryContainer:getVarNode(i == 1 and "mShakeNode" or "mBg")
					if not shakeNode:getActionByTag(SHAKE_ACTION_TAG + i) then
						shakeNode:stopActionByTag(SHAKE_ACTION_TAG + i)
						local array = CCArray:create()
						array:addObject(CCMoveBy:create(0.05, ccp(10 * math.tan(math.deg(18)), -10)))
						array:addObject(CCMoveBy:create(0.05, ccp(10 * math.atan(math.deg(54)), 10)))
						if i == 1 then
							array:addObject(CCMoveTo:create(0.05, ccp(ShakeNodeOriPosX, 0)))
						else
							array:addObject(CCMoveTo:create(0.05, ccp(0, 0)))
						end
						local action = CCSequence:create(array)
						action:setTag(SHAKE_ACTION_TAG + i)
						shakeNode:runAction(action)
					end
				end
			end
			local spine = SpineContainer:create(spinePath, spineName)
			local ChangeNode = tolua.cast(spine, "CCNode")
			parentNode:addChild(ChangeNode)
			--parentNode:setScale(NodeHelper:getScaleProportion())
			spine:runAnimation(1, "animation", 0)
		end))
	elseif actType == DiaryTypeNew.HSPINE then
		action:addObject(CCCallFunc:create(function()
			NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
			PhotoSettingState.isAuto = false
			local ID=para.spine
            isLabelPlaying = false
			if string.sub(ID,1,3)=="990" then
				local AlbumStoryDisplayPage=require('AlbumStoryDisplayPage')
				local stagetype= string.sub(ID,5,6)
				local mID=tonumber(string.format("%02d", stagetype))
				local AlbumSideStory=require("Album.AlbumHCGPage")
				AlbumSideStory_StroyState(nil,mID)
				AlbumSideStory:onBtn(mID)
			else
				local AlbumStoryDisplayPage_Vertical_Story=require('AlbumStoryDisplayPage_Vertical_Story')
				AlbumStoryDisplayPage_Vertical_Story:setData(ID,true)
				require("Battle.NgBattleResultManager")
				NgBattleResultManager.showMainHStory = true
				if not GuideManager.isInGuide then
					NgBattleResultManager.showAlbum = true
				end
				PageManager.pushPage("AlbumStoryDisplayPage_Vertical_Story")
			end
		end))
    elseif  actType == DiaryTypeNew.PLAYVIDEO then
         action:addObject(CCCallFunc:create(function()
			 if para.spine ~=""  then
                --libPlatformListener = {}
                --NodeHelper:setNodesVisible(diaryContainer,{mTouch = false})       
                LibPlatformScriptListener:new(libPlatformListener)
                GamePrecedure:getInstance():playMovie(para.spine, 0, 0)
                GameUtil:setPlayMovieVisible(false)
                 local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
                 local backNode = mainContainer:getCCNodeFromCCB("mNodeMid")
                 backNode:setVisible(false)
                --FetterGirlsDiary:setPlayMoiveVisible(container,false)
            end
		end))         
	end
	return action, bgAction, chAction
end
function FetterGirlsDiary:setPlayMoiveVisible(container,isVisible)
    NodeHelper:setNodesVisible(container,{mLayerColor = isVisible,mFullScreen = isVisible})
    SoundManager:getInstance():stopMusic()
    local StoryLog = require "Album.StoryLog"
    local AlbumStoryPage = require "Album.AlbumStoryPage"
    local CommTabStorage = require "CommComp.CommTabStorage"
    StoryLog:setMovieVisible(isVisible)
    AlbumStoryPage:setMovieVisible(isVisible)
    --CommTabStorage:setMovieVisible(isVisible)
end
function FetterGirlsDiary:getMovementActions(container, id)
	local controlCfg = fetterControlCfg[id]
	local actionArr = CCArray:create()
	local bgArrAct = CCArray:create()
	local chArrAct = CCArray:create()
	local EndId
	for i=1,10 do
		EndId=controlCfg.startMovementId+i
		if not fetterMovementCfg[EndId] then break end
	end
	if controlCfg.startMovementId and EndId then
		for i = controlCfg.startMovementId, EndId do
			local para = FetterGirlsDiary:getMovementPara(container, i)
			if para == nil or not para.actionType then
				break
			end
			if para.spawnId then
				local spawnAction = CCArray:create()
				for j = controlCfg.startMovementId, para.spawnId do
					local spawnPara = FetterGirlsDiary:getMovementPara(container, j)
					spawnAction = FetterGirlsDiary:createAction(container, spawnPara, spawnAction)
					i = i + 1
					if not spawnPara.spawnId then
						break
					end
				end
				actionArr:addObject(CCSpawn:create(spawnAction))
			else
				actionArr, bgArrAct, chArrAct = FetterGirlsDiary:createAction(container, para, actionArr, bgArrAct, chArrAct)
			end
		end
		actionArr:addObject(CCCallFunc:create(function()
			nowActionType = DiaryTypeNew.NONE
			if not isLabelPlaying then
				NodeHelper:setNodesVisible(container, { mTalkArrowNode = true })
			end
		end))
		return CCSequence:create(actionArr), CCSequence:create(bgArrAct), CCSequence:create(chArrAct)
	else
		return nil
	end
end

function FetterGirlsDiary:playActionsNew(container)
	local seqAct, bgAct, chAct = FetterGirlsDiary:getMovementActions(container, self:getNowControlId(container))
	local spineNode = container:getVarNode("mAllSpineNode")--tolua.cast(diarySpine, "CCNode")
	local pos = spineNode:getPosition()
	if seqAct then
		if not isEndLineAct then
			spineNode:runAction(seqAct)
		end
	end
	local sprite = container:getVarSprite("mBg")
	if bgAct then
		if not isEndLineAct then
			sprite:runAction(bgAct)
		end
	end
	
	NodeHelper:setNodesVisible(container, {mTalkArrowNode = false})
end

function FetterGirlsDiary:getNowControlId(container)
	local id = tonumber(string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", nowLine))
	return id
end
-------------------------------------------------------------------------
--  TEST FUNCTION
function FetterGirlsDiary:onSetNowLine(container)
	-- 輸入行數
	mEditInputType = 1
	NodeHelper:setStringForLabel(container, { mTestLine = "" })
	NodeHelper:setNodesVisible(container, { mTouchLineBg = true })
	libOS:getInstance():showInputbox(false, "")
end
function FetterGirlsDiary:onTestHide(container)
	-- 開關測試介面
	local testInfoNode = container:getVarNode("mTestInfoNode")
	if testInfoNode:isVisible() then
		NodeHelper:setNodesVisible(container, { mTestInfoNode = false })
	else
		NodeHelper:setNodesVisible(container, { mTestInfoNode = true })
	end
end
function FetterGirlsDiary:setLineState(container)
	local startId, testId
	local newSpineAni, newUiAni, newTrans, newRotate, newScale, newHalfImg, newSpinePath, newSpineFile, bgTrans, bgRotate, bgScale
	local isVisibleUi = true
	-- 清空當前動作
	local nowSpineNode = container:getVarNode("mAllSpineNode")--tolua.cast(diarySpine, "CCNode")
	nowSpineNode:stopAllActions()
	self:stopVoice(container)
	isEndLineAct = false
	nowActionType = DiaryTypeNew.NONE
	NodeHelper:setNodesVisible(container, { mTalkArrowNode = true })
	-- 計算cfgId
	startId = tonumber( string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. "00")
	if isPhoto then
		local cfg = fetterMovementCfg[tonumber(startId .. "01")]
		local aniName, spinePath, spineFile = unpack(common:split((cfg.spine), ","))
		newTrans = cfg.transform
		newRotate = cfg.rotate
		newScale = cfg.scale
		newSpinePath = spinePath
		newSpineFile = spineFile
		bgTrans = "0,0"
		bgRotate = 0
		bgScale = 1
	end
	newSpineAni = fetterMovementCfg[tonumber(startId .. "01")].spine
	newUiAni = "F4"
	testId = tonumber( string.format("%02d", areaNum) .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", testNowLine))
	--超過劇情行數
	if not fetterControlCfg[testId] then
		return
	end
	--紀錄演出最後狀態
	for i = startId, testId do
		for j = tonumber(i .. "01"), tonumber(i .. "99") do
			local cfg = fetterMovementCfg[j]
			if not cfg then
				break
			end
			if cfg.actionType == DiaryTypeNew.WAITLINE and i == testId then
				isEndLineAct = true
				break
			end
			if cfg.actionType == DiaryTypeNew.SPINE or cfg.actionType == DiaryTypeNew.FADEIN then
				local ani, isBg = unpack(common:split((cfg.spine), ","))
				newSpineAni = ani
			end
			if cfg.actionType == DiaryTypeNew.TRANS or cfg.actionType == DiaryTypeNew.FADEIN or cfg.actionType == DiaryTypeNew.SPINEFILE then
				local ani, isBg = unpack(common:split((cfg.spine), ","))
				newTrans = cfg.transform
				newRotate = cfg.rotate
				newScale = cfg.scale
				if tonumber(ani) == 1 or tonumber(isBg) == 1 then
					bgTrans = cfg.transform
					bgRotate = cfg.rotate
					bgScale = cfg.scale
				end
			end
			if cfg.actionType == DiaryTypeNew.ANIMATION then
				newUiAni = cfg.spine
			end
			if cfg.actionType == DiaryTypeNew.VISIBLEUI then
				isVisibleUi = not isVisiblUi
			end
			if cfg.actionType == DiaryTypeNew.HALFBODY then
				newHalfImg = cfg.spine
			end
			if cfg.actionType == DiaryTypeNew.SPINEFILE then
				newSpineAni, newSpinePath, newSpineFile = unpack(common:split((cfg.spine), ","))
			end
		end
	end
	-- 設定Spine檔案
	FetterGirlsDiary:showTargetSpine(container, newSpineFile)
	if newSpinePath and newSpinePath ~= "" then
		if spineKey[newSpineFile] then
			diarySpine = spineFiles[spineKey[newSpineFile]]
			diarySpineFade = spineFiles[spineKey[newSpineFile .. "Fade"]]
		else
			diarySpine = SpineContainer:create(newSpinePath, newSpineFile, 1)
			diarySpineFade = SpineContainer:create(newSpinePath, newSpineFile, 1)
		end
		diarySpine:runAnimation(1, newSpineAni, -1)
		diarySpineFade:runAnimation(1, newSpineAni, -1)
		mSpineNode:setOpacity(255)
		mSpineFadeNode:setOpacity(0)
	end
	-- 設定Spine播放動畫
	if newSpineAni and newSpineAni ~= "" then
		local noLoop = false
		if noLoop then
			diarySpine:runAnimation(1, newSpineAni, 0)
			diarySpineFade:runAnimation(1, newSpineAni, 0)
		else
			diarySpine:runAnimation(1, newSpineAni, -1)
			diarySpineFade:runAnimation(1, newSpineAni, -1)
		end
	end
	-- spine座標歸零
	nowSpineNode:setPosition(ccp(0, 0))
	mSpineNode:setPosition(ccp(0, 0))
	mSpineFadeNode:setPosition(ccp(0, 0))
	-- 設定座標旋轉縮放
	if newTrans and newRotate and newScale and newTrans ~= "" and newRotate ~= "" and newScale ~= "" then
		local tx, ty
		tx, ty = unpack(common:split((newTrans), ","))
		tx = tonumber(tx)
		ty = tonumber(ty)
		nowSpineNode:setPosition(ccp(tx, ty))
		nowSpineNode:setScale(newScale)
		nowSpineNode:setRotation(newRotate)
		local sprite = container:getVarSprite("mBg")
		sprite:setPosition(ccp(tx, ty))
		sprite:setScale(newScale)
		sprite:setRotation(newRotate)
	end
	-- 設定背景座標旋轉縮放
	if bgTrans and bgRotate and bgScale and bgTrans ~= "" and bgRotate ~= "" and bgScale ~= "" then
		local tx, ty
		tx, ty = unpack(common:split((bgTrans), ","))
		tx = tonumber(tx)
		ty = tonumber(ty)
		local sprite = container:getVarSprite("mBg")
		sprite:setPosition(ccp(tx, ty))
		sprite:setScale(bgScale)
		sprite:setRotation(bgRotate)
	end
	-- 設定UI播放動畫
	if newUiAni and newUiAni ~= "" then
		container:runAnimation(newUiAni)
	end
	-- 設定UI顯示狀態
	NodeHelper:setNodesVisible(container, { mReturn = isVisibleUi, mStory = isVisibleUi, mControlBtn = isVisibleUi })
	-- 設定半身像顯示狀態
	if not newHalfImg or newHalfImg == "" then
		NodeHelper:setSpriteImage(container, { mHalfbody = "UI/Mask/Image_Empty.png" })
	else
		NodeHelper:setSpriteImage(container, { mHalfbody = newHalfImg })
	end
	-- 設定劇情文字顯示
	isLabelPlaying = false
	NodeHelper:setStringForLabel(container, { mContent = lines[testNowLine] })
	-- 設定角色名顯示
	local roleId = fetterControlCfg[testId].role
	if roleId then
		NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@HeroName_" .. roleId) })
	else
		NodeHelper:setStringForLabel(container, { mTitle = "" })
	end
	-- 設定背景顯示
	local bgImg = fetterControlCfg[testId].bg
	local sprite = container:getVarSprite("mBg")
	if bgImg == "" then
		sprite:setTexture("UI/Mask/Image_Empty.png")
	else
		sprite:setTexture(bgImg)
	end
	nowBgName = bgImg
	nowLine = testNowLine
	NodeHelper:setStringForLabel(container, { mTestNowLine = "NowLine: " .. nowLine })
end
function FetterGirlsDiary:onInputboxEnter(container)
	local content = container:getInputboxContent()

	if mEditInputType == 1 then
		-- 輸入劇情行數
		if content then
			NodeHelper:setStringForLabel(container, { mTestLine = content })
		end
	end
	if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
		FetterGirlsDiary:luaonCloseKeyboard(container)
	end
end
function FetterGirlsDiary:luaonCloseKeyboard(container)
	NodeHelper:setNodesVisible(container, { mTouchLineBg = false })
	local content = container:getInputboxContent()
	if content == nil or content == "" then
		return
	end
	if mEditInputType == 1 then
		--顯示當前動作(Debug功能)
		if NodeHelper:isDebug() then
			local testActionStr = container:getVarLabelTTF("mTestNowAction"):getString()
			NodeHelper:setStringForLabel(container, { mTestNowAction = "NowAction:" })
		end
		-- 輸入劇情行數
		testNowLine = tonumber(content)
		FetterGirlsDiary:setLineState(container)
	end
end

function FetterGirlsDiary:openMainScreen(container)
	NodeHelper:setNodesVisible(container, { mDiaryWindow = false, mFullScreen = true })
	NodeHelper:setSpriteImage(container, { mHalfbody = "UI/Mask/Image_Empty.png" })
	nowState = DiaryState.SPINE
	FetterGirlsDiary:initSpine(container)
	FetterGirlsDiary:initSetting(container)
	FetterGirlsDiary:playActionsNew(container)
end

function FetterGirlsDiary:showTargetSpine(container, name)
	if not name then
		return
	end
	for i = 1, #spineFiles do 
		local spineNode = tolua.cast(spineFiles[i], "CCNode")
		if spineNode then
			spineNode:setVisible(false)
		end
	end
	local targetNode = tolua.cast(spineFiles[spineKey[name]], "CCNode")
	targetNode:setVisible(true)
	local fadeNode = tolua.cast(spineFiles[spineKey[name .. "Fade"]], "CCNode")
	fadeNode:setVisible(true)
end

function FetterGirlsDiary_setPhotoRole(container, area, stage, Idx)
	areaNum = area
	stageNum = stage
	storyIdx = Idx or 1
end

function FetterGirlsDiary_restartPage(container)
	if mSpineNode then
		mSpineNode:unscheduleUpdate()
		mSpineNode = nil
	end
	FetterGirlsDiary:stopVoice(container)
	--FetterGirlsDiary:onLoad(container)
	FetterGirlsDiary:onEnter(container)
end
function FetterGirlsDiary:playVoice(container)
	self:stopVoice(container)
	if PhotoSettingState.isSilent == true then
		return
	end
	local voiceName = "FetterLog" .. areaNum .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", nowLine) .. ".mp3"

	local isFileExist = NodeHelper:isFileExist("/audio/" .. voiceName)
	if isFileExist then
		local wait = fetterControlCfg[self:getNowControlId(container)].voiceWait
		local actionArr = CCArray:create()
		actionArr:addObject(CCCallFunc:create(function()
			isWaitingVoice = true
		end))
		if wait then
			actionArr:addObject(CCDelayTime:create(wait))
		end
		actionArr:addObject(CCCallFunc:create(function()
			isWaitingVoice = false
			if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
				nowVoiceEffId = SoundManager:getInstance():playEffectByName(voiceName, false)
			else
				CCLuaLog("--------playVoice-----------")
				SoundManager:getInstance():playOtherMusic(voiceName)
				CCLuaLog("--------playVoice2-----------")
				nowVoiceEffId = 1
			end
		end))
		container:runAction(CCSequence:create(actionArr))
	end
end

function FetterGirlsDiary:playTargetVoice(container, targetLine)
	self:stopVoice(container)
	local voiceName = "FetterLog" .. areaNum .. string.format("%02d", stageNum) .. storyIdx .. string.format("%02d", targetLine) .. ".mp3"
	local isFileExist = NodeHelper:isFileExist("/audio/" .. voiceName)
	if isFileExist then
		isWaitingVoice = false
		if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
			nowVoiceEffId = SoundManager:getInstance():playEffectByName(voiceName, false)
		else
			SoundManager:getInstance():playOtherMusic(voiceName)
			nowVoiceEffId = 1
		end
	end
end

function FetterGirlsDiary:stopVoice(container)
	container:stopAllActions()
	isWaitingVoice = false
	if nowVoiceEffId ~= 0 then
		if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
			SoundManager:getInstance():stopAllEffect()
		else
			SoundManager:getInstance():stopOtherMusic()
			nowVoiceEffId = 0
		end
	end
end

function FetterGirlsDiary:isPlayingVoice(container)
	CCLuaLog("--------isPlayingVoice-----------")
	local isPlaying = SimpleAudioEngine:sharedEngine():getEffectIsPlaying(nowVoiceEffId) or isWaitingVoice
	CCLuaLog("--------isPlayingVoice2-----------")
	return isPlaying
end

function FetterGirlsDiary:getContainer(container)
	return diaryContainer
end
-------------------------------------------------------------------------
--Tutorial
function FetterGirlsDiary:setTutorialState(container)
	--if areaNum ~= 99 then
	NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
	PhotoSettingState.isAuto = false
--else
--    NodeHelper:setMenuItemImage(container, { mAutoBtn = { normal = "Fetter_Btn_Auto_ON.png", press = "Fetter_Btn_Auto_OFF.png" } })
--    PhotoSettingState.isAuto = true
--end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local FetterGirlsDiaryPage = CommonPage.newSub(FetterGirlsDiary, thisPageName, option)

return FetterGirlsDiaryPage