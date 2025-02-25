local thisPageName = "SecretMessage.SecertAVGPage"
local UserMercenaryManager = require("UserMercenaryManager")
local UserItemManager = require("Item.UserItemManager")
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

local SecertAVG = {}

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
	HSPINE = 17, WAIT = 999}
local PhotoSettingState = {isSilent = false, isAuto = false}
local nowState = DiaryState.SPINE

local diarySpine = nil
local diarySpineFade = nil

local fetterControlCfg = ConfigManager:getSecertControlCfg()
local fetterMovementCfg = ConfigManager:getSecertActionCfg()

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
local Limit

local MainId=0

local Reward = {}

local isBgMoving=false
-----------------------------------------------------------
--TEST PARA
--測試用行數
local testNowLine = 0
--測試用輸入Type
local mEditInputType = 0
--回傳0~3 0:client判斷第一張是否開啟 1~3:後三張是否開啟
--useitem: type傳奧義id
function SecertAVG:onLoad(container)
    if areaNum and areaNum == 99 and stageNum and stageNum == 5 then
        container:loadCcbiFile(option.ccbiFile2)
    else
        container:loadCcbiFile(option.ccbiFile)
    end
end

function SecertAVG:onEnter(container)
    NodeHelper:setNodesVisible(container, {mDiaryWindow = false, mFullScreen = true})
    nowOtherEffId = 0
    nowOtherEffName = ""
    SoundManager:getInstance():stopAllEffect()
    self:openMainScreen(container)

    --local TextHeight = NodeHelper:Add_9_16_Layer(container,"mLayer")
    --container:getVarNode("mStory"):setPositionY(TextHeight)

    ---
    fadeBgSprite = CCSprite:create("UI/Mask/Image_Empty.png")
    fadeBgSprite:setOpacity(0)
    local sprite = container:getVarSprite("mBg")
    sprite:getParent():addChild(fadeBgSprite)
    ---
    SecertAVG:registerPacket(container)
    --SecertAVG:refreshPage(container)
    NodeHelper:setNodesVisible(container, {mLogNode = false})
    --------------------------------------------------------------------
    --Debug
    if NodeHelper:isDebug() then
        NodeHelper:setNodesVisible(container, {mTestNode = false})
        NodeHelper:setStringForLabel(container, {mTestLine = ""})
        container:registerLibOS()
    else
        NodeHelper:setNodesVisible(container, {mTestNode = false})
    end
    --------------------------------------------------------------------
end
function SecertAVG:HSPINESync(container)
    local mID
    for line=1,99 do
        mID = tonumber( MainId .. string.format("%02d", line))
        if fetterControlCfg[mID] then
            for move=1,10 do
                mID=tonumber( MainId.. string.format("%02d", line).. string.format("%02d", move))
                if fetterMovementCfg[mID] and fetterMovementCfg[mID].actionType == 17 then
                    return line
                end
            end
        end
    end
end
function SecertAVG:onClose(container)
    if mSpineNode then
        mSpineNode:unscheduleUpdate()
        mSpineNode = nil
    end
    SecertAVG:stopVoice(container)
    -- 先跳結算畫面
    --if storyIdx == 2 then
    --    PageManager.pushPage("NgBattleResultPage")
    --end
  
    PageManager.setIsInGirlDiaryPage(false)
end

function SecertAVG:onExecute(container)
    if mSpineNode then
        mSpineNode:scheduleUpdateWithPriorityLua(function(dt)
            SecertAVG:update(dt, container)
        end, 0)
    end
end

function SecertAVG:update(dt, container)
    --FadeIn
    if Limit and nowLine<Limit then
        NodeHelper:setMenuItemEnabled(container,"mTutorialSkip",false)
    else
        NodeHelper:setMenuItemEnabled(container,"mTutorialSkip",true)
    end
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
            SecertAVG:onTouch(container)
            autoTimer = 0
        end
    else
        autoTimer = 0
    end
end

function SecertAVG:onReturn(container)
    SoundManager:getInstance():stopAllEffect() --關閉音效
    SoundManager:getInstance():playGeneralMusic()
    PageManager.popPage(thisPageName)
    --if Reward ~= nil then
    --    local CommonRewardPage = require("CommPop.CommItemReceivePage")
    --    CommonRewardPage:setData(Reward, common:getLanguageString("@ItemObtainded"), nil)
    --    PageManager.pushPage("CommPop.CommItemReceivePage")
    --end
    -- 新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        GuideManager.forceNextNewbieGuide()
    end
end
------------------------------------- 功能表
function SecertAVG:onHide(container) --隱藏視窗
    NodeHelper:setNodesVisible(container, {mReturn = false, mStory = false, mControlBtn = false})
    nowState = DiaryState.HIDE
    NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
    PhotoSettingState.isAuto = false
end

function SecertAVG:onAuto(container) --自動播放
    if PhotoSettingState.isAuto then
        NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
        PhotoSettingState.isAuto = false
    else
        NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_ON.png", press = "Fetter_Btn_Auto_OFF.png"}})
        PhotoSettingState.isAuto = true
    end
end


function SecertAVG:onTutorialSkip(container)
    if Limit and nowLine<Limit then
     --nowLine=Limit-1
     --self:onTouch(container)
     return
    end
    local title = common:getLanguageString("@SkipTitle")
    local msg = common:getLanguageString("@SkipStory")
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            SecertAVG:onReturn(container)
        end
    end, true, nil, nil, nil, 0.9);
end
function SecertAVG:onSilent(container) --靜音
    if PhotoSettingState.isSilent == true then
        NodeHelper:setMenuItemImage(container, { mVoiceBtn = { normal = "Fetter_Btn_Voice_ON.png", press = "Fetter_Btn_Voice_OFF.png" } })
        PhotoSettingState.isSilent = false
    else
        NodeHelper:setMenuItemImage(container, { mVoiceBtn = { normal = "Fetter_Btn_Voice_OFF.png", press = "Fetter_Btn_Voice_ON.png" } })
        PhotoSettingState.isSilent = true
        self:stopVoice(container)
    end
end

function SecertAVG:onLog(container) --開啟Log
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

function SecertAVG:onCloseLog(container) --關閉Log
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
    SecertAVG:playTargetVoice(container, self.id)
end

function FetterLogContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
     local parentNode = container:getVarLabelTTF("mDiaTxt")
     parentNode:setString("")
     parentNode:removeAllChildrenWithCleanup(true)
     local htmlModel = FreeTypeConfig[702].content
     local msgHtml = NodeHelper:addHtmlLable(parentNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", FetterLogContent.logTxt[self.id]), 0, CCSizeMake(680, 200))
     local htmlHeight = msgHtml:getContentSize().height
     local msgBgHeight = htmlHeight+90
     if FetterLogContent.logName[self.id]=="" then msgBgHeight=msgBgHeight-40 end
     local Bg = container:getVarScale9Sprite("mSprite")
     Bg:setContentSize(CCSize(Bg:getContentSize().width, msgBgHeight))
    NodeHelper:setStringForLabel(container, {
        mDiaName = FetterLogContent.logName[self.id],
        --mDiaTxt = FetterLogContent.logTxt[self.id],
    } );
    NodeHelper:setNodesVisible(container, {
        mRecallBtn = FetterLogContent.logVoice[self.id]
    } );
end

function SecertAVG:clearAndReBuildAllLog(container)
    local logScrollView = container:getVarScrollView("mLogScrollView")
    logScrollView:removeAllCell()
    for i = 1, #FetterLogContent.logTxt do
        if FetterLogContent.logTxt[i]~=" " then
            local logCell = CCBFileCell:create()
            local panel = FetterLogContent:new( { id = i })
            logCell:registerFunctionHandler(panel)
            logCell:setCCBFile(FetterLogContent.ccbi)
            logScrollView:addCellBack(logCell)
            local height=SecertAVG:calStringHeight(FetterLogContent.logTxt[i])+100
            if FetterLogContent.logName[i]=="" then height=height-40 end
            logCell:setContentSize(CCSizeMake(logCell:getContentSize().width,height))
        end
    end
    logScrollView:orderCCBFileCells()
    logScrollView:locateToByIndex(#FetterLogContent.logTxt - 1, CCBFileCell.LT_Bottom)
end
function SecertAVG:calStringHeight(msg)
    local tempNode = CCNode:create()
    local htmlModel = FreeTypeConfig[702].content
    local msgHtml = NodeHelper:addHtmlLable(tempNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", msg), 0, CCSizeMake(680, 200))
    local htmlHeight = msgHtml:getContentSize().height

    return htmlHeight
end
function SecertAVG:setAllLogContent(container)
    FetterLogContent.logName = { }
    FetterLogContent.logTxt = { }
    FetterLogContent.logVoice = { }
    for i = 1, logNowLine do
            --logTxt
            table.insert (FetterLogContent.logTxt,lines[i])
            FetterLogContent.logTxt[i] = lines[i]
            --logName
            local fetterCfgId = tonumber( MainId.. string.format("%02d", i))
            local roleId = fetterControlCfg[fetterCfgId].role
            if roleId then
                FetterLogContent.logName[i] = common:getLanguageString("@HeroName_" .. roleId)
            else
                FetterLogContent.logName[i] = ""
            end
            --logVoice
            --local voiceName = "Voice" .. MainId.. string.format("%02d", i) .. ".mp3"
            --local isFileExist = NodeHelper:isFileExist("/audio/" .. voiceName)
            --FetterLogContent.logVoice[i] = isFileExist
      end
end

------------------------------------- 功能表END

function SecertAVG:onTouch(container, eventName)
	if eventName == "onTouch" and PhotoSettingState.isAuto then
		NodeHelper:setMenuItemImage(container, { mAutoBtn = { normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png" } })
		PhotoSettingState.isAuto = false
		isLabelPlaying=true
	end
    if isBgMoving then return end
    NodeHelper:setNodesVisible(container,{mTouch=true})
    if nowState == DiaryState.SPINE then
        --演出
        if isLabelPlaying then
            isLabelPlaying = false
            if nowActionType == DiaryTypeNew.NONE then
                NodeHelper:setNodesVisible(container, { mTalkArrowNode = true })
            end
            return
        end
        if not isEndLineAct and (nowActionType == DiaryTypeNew.NONE or nowActionType == DiaryTypeNew.NEXTLINE or nowActionType == DiaryTypeNew.AUTOCLICK) then
            nowLine = nowLine + 1
            if nowLine > logNowLine then
                logNowLine = nowLine
            end
            -- 當前fetterControlId
            local nowControlId = SecertAVG:getNowControlId(container)
            -- 當前fetterControlCfg
            local nowControlCfg = fetterControlCfg[nowControlId]
            --關閉對話提示
            NodeHelper:setNodesVisible(container, { mTalkArrowNode = false })
            if not lines[nowLine] or string.find(lines[nowLine], "@") then --劇情結束
                nowLine = nowLine - 1
                logNowLine = nowLine
                self:onReturn(container)
                return
            end
            --切換BG
            local newBgName = nowControlCfg.bg
            if newBgName ~= nowBgName then
                local sprite = container:getVarSprite("mBg")
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
            SecertAVG:playVoice(container)
            --播放其他音效
            local newOtherEffName = nowControlCfg.eff
            isFileExist = newOtherEffName and NodeHelper:isFileExist("/audio/" .. newOtherEffName)
            if newOtherEffName ~= nowOtherEffName then
                if nowOtherEffId ~= 0 then
                    --SimpleAudioEngine:sharedEngine():stopEffect(nowOtherEffId)
                    SoundManager:getInstance():stopAllEffect()
                    nowOtherEffId = 0
                end
                if newOtherEffName ~= "" then
                    if isFileExist then
                        nowOtherEffId = SoundManager:getInstance():playEffectByName(newOtherEffName, false)
                    end
                end
                nowOtherEffName = newOtherEffName
            end
            --
            local roleId = nowControlCfg.role
            if roleId then
                NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@HeroName_" .. roleId) })
            else
                NodeHelper:setStringForLabel(container, { mTitle = "" })
            end
            nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
            labelTimer = 0
            lineIndex = 1
            NodeHelper:setStringForLabel(container, { mContent = "" })
            isLabelPlaying = true
            --播放動作
            SecertAVG:playActionsNew(container)
        elseif isEndLineAct then
            SecertAVG:playActionsNew(container)
        end
    elseif nowState == DiaryState.HIDE then
        NodeHelper:setNodesVisible(container, { mReturn = true, mStory = true, mControlBtn = true })
        nowState = DiaryState.SPINE 
    end
end

function SecertAVG.onFunction(eventName, container)
    if eventName ~= "luaExecute" then
    end
    if eventName == "luaInit" then
        SecertAVG:onInit(container)
    elseif eventName == "luaLoad" then
        SecertAVG:onLoad(container)
    elseif eventName == "luaEnter" then
        SecertAVG:onEnter(container)
    end
end

function SecertAVG:initSpine(container)
    mSpineNode = container:getVarNode("mSpine")
    mSpineNode:removeAllChildrenWithCleanup(true)
    mSpineFadeNode = container:getVarNode("mSpineFade")
    mSpineFadeNode:removeAllChildrenWithCleanup(true)
    local startId = tonumber( MainId.. "00")
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

    SecertAVG:showTargetSpine(container, spineFile)
    
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

function SecertAVG:initSetting(container)
    --end
    local langForward = "@albumstory"
    for i = 1, 99 do 
        local str = common:getLanguageString(langForward .. MainId.. string.format("%02d", i))
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
    local cfgId = tonumber( MainId.. "01")
    
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
    newOtherEffName = fetterControlCfg[cfgId].eff
    if newOtherEffName ~= nowOtherEffName then
        if nowOtherEffId ~= 0 then
            --SimpleAudioEngine:sharedEngine():stopEffect(nowOtherEffId)
            SoundManager:getInstance():stopAllEffect()
            nowOtherEffId = 0
        end
        if newOtherEffName ~= "" then
            local isFileExist = newOtherEffName and NodeHelper:isFileExist("/audio/" .. newOtherEffName)
            if isFileExist then
                nowOtherEffId = SoundManager:getInstance():playEffectByName(newOtherEffName, false)
            end
        end
        nowOtherEffName = newOtherEffName
    end
    --預設開啟黑幕
    container:runAnimation("F4")
    NodeHelper:setNodesVisible(container, {mTalkArrowNode = false})
    
    --SecertAVG:playVoice(container)
    Limit=SecertAVG:HSPINESync(container)
end

function SecertAVG:getMercenaryId(roleId)
    local roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
    for i = 1, #roleInfos do
        if roleInfos[i].itemId == roleId then
            return roleInfos[i].roleId
        end
    end
end

function SecertAVG:refreshPage(container)
end

function SecertAVG:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

-------------------------------------------------------------------------
--  NEW ACT FUNCTION
-------------------------------------------------------------------------
function SecertAVG:getMovementPara(container, id)
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

function SecertAVG:createAction(container, para, action, bgAction, chAction)
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
            nowSpines[define]:runAnimation(1, spine, -1)
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
	        SecertAVG:onTouch(container)
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
            local parentNode
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
            --SecertAVG:showTargetSpine(container, name)
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
                nowSpines[define].parent:removeAllChildrenWithCleanup(true)
                --nowSpines[define] = nil
            end)
            SpineAction:addObject(clear)
            spineNode:runAction(CCSequence:create(SpineAction))
            end))
    elseif actType==DiaryTypeNew.BGCHANGE then
            action:addObject(CCCallFunc:create(function()
            newBgName=para.spine
            if newBgName=="" then
              newBgName=nowBgName
            end
            local sprite = container:getVarSprite("mBg")
           -- sprite:setScale(NodeHelper:getScaleProportion())
            local px,py=0,0
            if pos and pos ~= "0" then
                px, py = unpack(common:split((pos), ","))
                px = tonumber(px)
                py = tonumber(py)
                sprite:setPosition(ccp(-px,-py))
            end
            if newBgName ~= nowBgName then
                if newBgName == "" then
                    sprite:setTexture("UI/Mask/Image_Empty.png")
                else
                    sprite:setTexture(newBgName)
                end
                nowBgName = newBgName
            end
            local BgAction = CCArray:create()
            local MovingState = CCArray:create()
            MovingState:addObject(CCCallFunc:create(function() isBgMoving=true end))
            MovingState:addObject(CCDelayTime:create(time))
            MovingState:addObject(CCCallFunc:create(function() isBgMoving=false end))
            if trans and trans ~= "0" then
                tx, ty = unpack(common:split((trans), ","))
                tx = tonumber(tx)
                ty = tonumber(ty)
            end
	     local moveSpeed = tonumber (para.define)
             local moveAction = CCMoveTo:create(time, ccp(-tx, -ty))
             if moveSpeed and moveSpeed > 0 then
               local easeAction = CCEaseIn:create(moveAction, moveSpeed)
               BgAction:addObject(easeAction)
             elseif moveSpeed and moveSpeed < 0 then
               local easeAction = CCEaseOut:create(moveAction, moveSpeed)
               BgAction:addObject(easeAction)
             else
                BgAction:addObject(moveAction)
             end
             BgAction:addObject(CCScaleTo:create(time, scale))           
             BgAction:addObject(CCRotateTo:create(time, rotate))
             sprite:runAction(CCSequence:create(BgAction))
             container:runAction(CCSequence:create(MovingState))
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

				-- 設置顏色
				colorNode:setColor(targetColor)

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
            if string.sub(ID,1,3)=="990" then
                local AlbumStoryDisplayPage=require('AlbumStoryDisplayPage')
	        local stagetype= string.sub(ID,5,6)
		local mID=tonumber(string.format("%02d", stagetype))
                local AlbumSideStory=require("Album.AlbumHCGPage")
                AlbumSideStory_StroyState(nil,mID)
                AlbumSideStory:onBtn(mID)
            else
                local AlbumStoryDisplayPage_Vertical_Story=require('AlbumStoryDisplayPage_Vertical_Story')
                AlbumStoryDisplayPage_Vertical_Story:setData(ID)
                PageManager.pushPage("AlbumStoryDisplayPage_Vertical_Story")
            end
        end))
    end
    return action, bgAction, chAction
end

function SecertAVG:getMovementActions(container, id)
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
            local para = SecertAVG:getMovementPara(container, i)
            if para == nil or not para.actionType then
                break
            end
            if para.spawnId then
                local spawnAction = CCArray:create()
                for j = controlCfg.startMovementId, para.spawnId do
                    local spawnPara = SecertAVG:getMovementPara(container, j)
                    spawnAction = SecertAVG:createAction(container, spawnPara, spawnAction)
                    i = i + 1
                    if not spawnPara.spawnId then
                        break
                    end
                end
                actionArr:addObject(CCSpawn:create(spawnAction))
            else
                actionArr, bgArrAct, chArrAct = SecertAVG:createAction(container, para, actionArr, bgArrAct, chArrAct)
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

function SecertAVG:playActionsNew(container)
    local seqAct, bgAct, chAct = SecertAVG:getMovementActions(container, self:getNowControlId(container))
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

function SecertAVG:getNowControlId(container)
    local id = tonumber(MainId.. string.format("%02d", nowLine))
    return id
end
-------------------------------------------------------------------------
--  TEST FUNCTION
function SecertAVG:onSetNowLine(container)
    -- 輸入行數
    mEditInputType = 1
    NodeHelper:setStringForLabel(container, { mTestLine = "" })
    NodeHelper:setNodesVisible(container, { mTouchLineBg = true })
    libOS:getInstance():showInputbox(false, "")
end
function SecertAVG:onTestHide(container)
    -- 開關測試介面
    local testInfoNode = container:getVarNode("mTestInfoNode")
    if testInfoNode:isVisible() then
        NodeHelper:setNodesVisible(container, { mTestInfoNode = false })
    else
        NodeHelper:setNodesVisible(container, { mTestInfoNode = true })
    end
end
function SecertAVG:setLineState(container)
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
    startId = tonumber( MainId.. "00")
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
    testId = tonumber( MainId.. string.format("%02d", testNowLine))
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
    SecertAVG:showTargetSpine(container, newSpineFile)
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
function SecertAVG:onInputboxEnter(container)
    local content = container:getInputboxContent()

    if mEditInputType == 1 then
        -- 輸入劇情行數
        if content then
            NodeHelper:setStringForLabel(container, { mTestLine = content })
        end
    end
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        SecertAVG:luaonCloseKeyboard(container)
    end
end
function SecertAVG:luaonCloseKeyboard(container)
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
        SecertAVG:setLineState(container)
    end
end

function SecertAVG:openMainScreen(container)
    NodeHelper:setNodesVisible(container, { mDiaryWindow = false, mFullScreen = true })
    NodeHelper:setSpriteImage(container, { mHalfbody = "UI/Mask/Image_Empty.png" })
    nowState = DiaryState.SPINE
    SecertAVG:initSpine(container)
    SecertAVG:initSetting(container)
    SecertAVG:playActionsNew(container)
end

function SecertAVG:showTargetSpine(container, name)
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

function SecertAVG_setPhotoRole(container, area, stage, Idx)
    areaNum = area
    stageNum = stage
    storyIdx = Idx or 1
end

function SecertAVG_restartPage(container)
    if mSpineNode then
        mSpineNode:unscheduleUpdate()
        mSpineNode = nil
    end
    SecertAVG:stopVoice(container)
    --SecertAVG:onLoad(container)
    SecertAVG:onEnter(container)
end
function SecertAVG:playVoice(container)
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

function SecertAVG:playTargetVoice(container, targetLine)
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

function SecertAVG:stopVoice(container)
    container:stopAllActions()
    isWaitingVoice = false
    if nowVoiceEffId ~= 0 then
        if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
            --SimpleAudioEngine:sharedEngine():stopEffect(nowVoiceEffId)
            SoundManager:getInstance():stopAllEffect()
        else
            SoundManager:getInstance():stopOtherMusic()
            nowVoiceEffId = 0
        end
    end
end

function SecertAVG:isPlayingVoice(container)
    CCLuaLog("--------isPlayingVoice-----------")
    local isPlaying = SimpleAudioEngine:sharedEngine():getEffectIsPlaying(nowVoiceEffId) or isWaitingVoice
    CCLuaLog("--------isPlayingVoice2-----------")
    return isPlaying
end

function SecertAVG:getContainer(container)
    return diaryContainer
end
function SecertAVG_setMainId(id,_Reward)
    MainId=id
    Reward = _Reward
end
-------------------------------------------------------------------------
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local SecertAVGPage = CommonPage.newSub(SecertAVG, thisPageName, option)

return SecertAVGPage