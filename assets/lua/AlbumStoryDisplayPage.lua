local thisPageName = "AlbumStoryDisplayPage"
require("FlagData")
local TapDBManager = require("TapDBManager")
local json = require('json')
local opcodes = {
    }

local option = {
    ccbiFile = "AlbumStoryDisplay.ccbi",
    handlerMap = {
        onTutorialSkip = "onReturn",
        onNext = "onNext",
        onTouch = "onTouch",
        onHide = "onHide",
        onAuto = "onAuto",
        onLog = "onLog",
        onExitBook = "onExitBook",
        unHide="UnHide"
    },
}
local AlbumStoryDisplayBase = {}
local SpineData = {}
local SpineIdx = 1
local Spines = {}
local TxtSpine = {}
local spineNode = {}
local parentNode = nil
local parentNode2 = nil
local parentNode3 = nil
local selfContainer = nil
local isAlbum = false
local isAuto = false
local isHide = false
local isLog = false
local HealthWidth = 0
local TimeWidth = 0
local Gamepassed = false
local NeedTimes = 0
local FetterLogContent = {
    ccbi = "FetterGirlsDiaryDialogue_Flip.ccbi",
    logName = {},
    logTxt = {},
    logVoice = {},
}

local DiaryState = {SPINE = 1, HIDE = 2}
local DiaryTypeNew = {NONE = 0, SPINE = 1, TRANS = 2, FADEIN = 3, ANIMATION = 4, WAITLINE = 5,
    NEXTLINE = 6, VISIBLEUI = 7, HALFBODY = 8, SPINEFILE = 9, PARENT = 11, WAIT = 999, Loop = 12, notLoop = 13}

local nowState = DiaryState.SPINE
--全劇情文字
local lines = {}
--角色
local linesCharater = {}
--目前劇情編號
local nowLine = 1
--Log可顯示的劇情編號
local logTable = {}
--執行中的動作type
local nowActionType = DiaryTypeNew.NONE
--當前字串table
local nowLineTable
--當前顯示文字index
local lineIndex = 1
--文字播放計時器
local labelTimer = 0
--文字播放速度
local labelSpeed = 2
--文字是否撥放中
local isLabelPlaying = false
--是否等待劇情結束
local isEndLineAct = false
--當前BGM
local nowBgmName = ""
--是否讀取完畢
local isLoadEnd = false
--是否開始播放
local isStartPlay = false
--點擊次數
local TapTimes = 0
local GameTime = 0
local nowTime = 0
local GameIndex = 1

local TapDB_Data = { }


function FetterLogContent:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function AlbumStoryDisplayBase:onEnter(container)
    
    TapDB_Data["#game_id"] = tonumber (string.sub (SpineData[1].id,1,6))
    TapDB_Data["#uid"] = tostring(UserInfo.serverId*1000000+UserInfo.playerInfo.playerId)
    TapDB_Data["#game_result"] = isAlbum and 3 or 0
    TapDBManager.trackEvent("#event_game",json.encode(TapDB_Data))
    isAuto = false
    isLoadEnd = false
    isStartPlay = false
    logIndex = 1
    logTable = {}
    TapTimes = 0
    PageManager.setIsInGirlDiaryPage(true) 
    NodeHelper:setNodesVisible(container, {mLogNode = false})
    selfContainer = container
    SoundManager:getInstance():stopMusic()--關閉BGM
    self:setSpine(container)
    --AlbumStoryDisplayBase:initSetting(selfContainer)
    mSpineNode = container:getVarNode("mSpine3")
    mSpineNode:setRotation(90)
    mSpineNode:removeAllChildrenWithCleanup(true)
    self:setNextSpine(container)
    if isAlbum then
        NodeHelper:setNodesVisible(selfContainer, {mReturnBtn = true})
    end
    NodeHelper:setNodesVisible(container, {mSpine3 = false, mShadow = true})
    NodeHelper:setNodesVisible(container, {mMiniGame = false,mUnHide=false})
    NodeHelper:setStringForLabel(container, {mTxt = ""})
    --selfContainer:getVarNode("mShadow"):setScale(NodeHelper:getScaleProportion())
    local HealthBar = tolua.cast(container:getVarNode("mHealth"), "CCScale9Sprite")
    HealthWidth = HealthBar:getContentSize().width
    NodeHelper:setNodesVisible(container,{mHit=false,mEffect=false })
    local TimeBar = tolua.cast(container:getVarNode("mTime"), "CCScale9Sprite")
    TimeWidth = TimeBar:getContentSize().width
    Gamepassed = false
    for k, v in pairs(SpineData) do
        if v.Game ~= "" then
            GameIndex = k
        end
    end
    local layer = selfContainer:getVarNode("mNotTouch")
    if not layer then
        layer = CCLayer:create()
        layer:setTag(100001)
        selfContainer:addChild(layer)
        layer:setContentSize(CCEGLView:sharedOpenGLView():getDesignResolutionSize())
        layer:registerScriptTouchHandler( function(eventName, pTouch)
            if eventName == "began" then

            elseif eventName == "moved" then

            elseif eventName == "ended" then
                AlbumStoryDisplayBase:onGameTap()
            elseif eventName == "cancelled" then

            end
        end
        , false, -129, false)
        layer:setTouchEnabled(true)
        layer:setVisible(true)
    end
end
function AlbumStoryDisplayBase:setSpine(container)
    Spines = {}
    spineNode = {}
    SpineIdx = 1
    parentNode = container:getVarNode("mSpine")
    parentNode2 = container:getVarNode("mSpine2")
    parentNode3 = container:getVarNode("mTxtSpine")
    parentNode:removeAllChildrenWithCleanup(true)
    parentNode2:removeAllChildrenWithCleanup(true)
    parentNode3:removeAllChildrenWithCleanup(true)
    
    for i = 1, #SpineData do
        local spinePath = "Spine/NG2DHCG/MiniGame"
        Spines[i] = SpineContainer:create(spinePath, SpineData[i].Spine)
        spineNode[i] = tolua.cast(Spines[i], "CCNode")
        Spines[i]:registerFunctionHandler("COMPLETE", AlbumStoryDisplayBase.onFunction)
    end
    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_77_Shady"
    local spine = SpineContainer:create(spinePath, spineName)
    local EnterNode = tolua.cast(spine, "CCNode")
    parentNode:setRotation(90)
    local array = CCArray:create()
     array:addObject(CCDelayTime:create(1.5))
     array:addObject(CCCallFunc:create(function()
         parentNode2:removeAllChildrenWithCleanup(true)
     end))
    local scale = NodeHelper:getScaleProportion()
    parentNode2:setScale(scale)
    parentNode:addChild(spineNode[1])
    parentNode2:addChild(EnterNode)
    spine:runAnimation(1, "Enter", 0)
    selfContainer:runAction(CCSequence:create(array))

    --if string.find(SpineData[1].anime, "animation") or string.find(SpineData[SpineIdx].anime, "A") then
    --    Spines[1]:runAnimation(1, SpineData[1].anime, 0)
    --else
    --    Spines[1]:runAnimation(1, SpineData[1].anime, -1)
    --end
    --AlbumStoryDisplayBase:initSetting(selfContainer)
    --
    --nowBgmName = SpineData[lineIndex].BGM
    --if nowBgmName~= "" then
    --    SoundManager:getInstance():playMusic(nowBgmName, false)
    --end
    isLoadEnd = true
end
function AlbumStoryDisplayBase:startPlayStory()
    if string.find(SpineData[1].anime, "animation") or string.find(SpineData[SpineIdx].anime, "A") then
        Spines[1]:runAnimation(1, SpineData[1].anime, 0)
    else
        Spines[1]:runAnimation(1, SpineData[1].anime, -1)
    end
    --txt
    local tmp = SpineData[1].Spine
    local spineName2 = GameMaths:replaceStringWithCharacterAll(tmp, "NGSceneA", "NGSceneB")
    local Head = common:split(spineName2, "_")[1]
    if Head == "NGSceneB" then
        local spine2 = SpineContainer:create("Spine/NG2DHCG/MiniGame", spineName2)
        local txtNode = tolua.cast(spine2, "CCNode")
        parentNode3:addChild(txtNode)
        spine2:runAnimation(1, SpineData[SpineIdx].anime, 0)
    end
    --AlbumStoryDisplayBase:initSetting(selfContainer)
    nowBgmName = SpineData[lineIndex].BGM
    if nowBgmName ~= "" then
        SoundManager:getInstance():playMusic(nowBgmName, false)
    end
    isStartPlay = true
end
function AlbumStoryDisplayBase:onFunction(tag, eventName)
    if eventName == "COMPLETE" then
        if not SpineData[SpineIdx] then
            return
        end
        if string.find(SpineData[SpineIdx].anime, "animation") or string.find(SpineData[SpineIdx].anime, "A") then
            AlbumStoryDisplayBase:onNext()
        --AlbumStoryDisplayBase:initSetting(selfContainer)
        end
    end
end
function AlbumStoryDisplayBase:setNextSpine(container)
    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_78_Next"
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local parentNode = container:getVarNode("mSpine3")
    parentNode:addChild(spineNode)
    spine:runAnimation(1, "animation", -1)
end
function AlbumStoryDisplayBase:onReturn(container)
    if nowTime>0 then return end
    isAuto = false
    if nowTime<=0 and SpineIdx>=GameIndex and not Gamepassed then
        self:onFaild(container)
        return
    end
    local title = common:getLanguageString("@SkipTitle")
    local msg = common:getLanguageString("@SkipStory")
    NodeHelper:setNodesVisible(container,{mControlBtnTop=true})
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            if nowTime>0 then return end
            if SpineIdx > GameIndex then
                spinePath = "Spine/NGUI"
                local spineName = "NGUI_77_Shady"
                local spine = SpineContainer:create(spinePath, spineName)
                local QuitNode = tolua.cast(spine, "CCNode")
                local Ani = CCCallFunc:create(function()
                    parentNode2:addChild(QuitNode)
                    spine:runAnimation(1, "quit", 0)
                end)
                local GuideManager = require("Guide.GuideManager")
                local clear = CCCallFunc:create(function()
                    parentNode2:removeAllChildrenWithCleanup(true)
                    SoundManager:getInstance():stopAllEffect()--關閉音效
                    nowBgmName = ""
                    if GuideManager.getCurrentCfg() and GuideManager.getCurrentCfg().showType ~= GameConfig.GUIDE_TYPE.PLAY_H_STORY then
                        require("Battle.NgBattleResultManager")
                        NgBattleResultManager_playNextResult()
                        local currPage = MainFrame:getInstance():getCurShowPageName()
                        if currPage == "NgBattlePage" then --回復BGM
                            local sceneHelper = require("Battle.NgFightSceneHelper")
                            sceneHelper:setGameBgm()
                        else
                            SoundManager:getInstance():playGeneralMusic()
                        end
                    elseif not GuideManager.isInGuide then
                        require("Battle.NgBattleResultManager")
                        NgBattleResultManager_playNextResult()
                    end
                    PageManager.popPage(thisPageName)
                end)
                
                local array = CCArray:create()
                array:addObject(CCDelayTime:create(0.2))
                array:addObject(Ani)
                array:addObject(CCDelayTime:create(2))
                array:addObject(clear)
                -- 新手教學
                if GuideManager.getCurrentCfg() and GuideManager.getCurrentCfg().showType == GameConfig.GUIDE_TYPE.PLAY_H_STORY then
                    array:addObject(CCCallFunc:create(function()
                        GuideManager.IsNeedShowPage = false
                        GuideManager.forceNextNewbieGuide()
                    end))
                end
                
                parentNode:runAction(CCSequence:create(array))
            else
                SpineIdx = GameIndex - 1
                if SpineIdx>=GameIndex then return end
                AlbumStoryDisplayBase:onNext(container)
            end
        end
    end, true, nil, nil, not Gamepassed, 0.9, nil, nil, nil, true);
end
function AlbumStoryDisplayBase:setContentScale(container, name, idx, MaxData, Width)
    local Scale = idx / tonumber(MaxData) or 0
    if Scale > 1 then return end
    local Bar = tolua.cast(container:getVarNode(name), "CCScale9Sprite")
    local ContentWidth = Bar:getContentSize().width
    Bar:setContentSize(CCSize(Width * Scale, Bar:getContentSize().height))
    if name=="mHealth" then
        container:getVarNode("mEffect2"):setPositionX(Width*Scale)
    end
    if idx <= 0 then
        NodeHelper:setNodesVisible(container, {[name] = false})
    else
        NodeHelper:setNodesVisible(container, {[name] = true})
    end
end
function AlbumStoryDisplayBase:onFaild(container)
    local title = common:getLanguageString("@Rechallenge_title")
    local msg = common:getLanguageString("@Rechallenge_content")
    NodeHelper:setNodesVisible(container,{mControlBtnTop=true})
   local tmp = string.sub(SpineData[1].id, 5, 6)
    if tmp == "41" then
        --msg = common:getLanguageString("@Challenge_fail")
        AlbumStoryDisplayBase:Exit(container)
    else
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                AlbumStoryDisplayBase:Exit(container)
            end
        end, true, nil, nil, false, 0.9, nil, nil, nil, true);
    end
end
function AlbumStoryDisplayBase:Exit(container)
    if SpineIdx > GameIndex then
        if nowTime>0 then return end
        spinePath = "Spine/NGUI"
        local spineName = "NGUI_77_Shady"
        local spine = SpineContainer:create(spinePath, spineName)
        local QuitNode = tolua.cast(spine, "CCNode")
        local Ani = CCCallFunc:create(function()
            parentNode2:addChild(QuitNode)
            spine:runAnimation(1, "quit", 0)
        end)
        local GuideManager = require("Guide.GuideManager")
        local clear = CCCallFunc:create(function()
            parentNode2:removeAllChildrenWithCleanup(true)
            SoundManager:getInstance():stopAllEffect()--關閉音效
            nowBgmName = ""
            if GuideManager.getCurrentCfg() and GuideManager.getCurrentCfg().showType ~= GameConfig.GUIDE_TYPE.PLAY_H_STORY then
                require("Battle.NgBattleResultManager")
                NgBattleResultManager_playNextResult()
                local currPage = MainFrame:getInstance():getCurShowPageName()
                if currPage == "NgBattlePage" then --回復BGM
                    local sceneHelper = require("Battle.NgFightSceneHelper")
                    sceneHelper:setGameBgm()
                else
                    SoundManager:getInstance():playGeneralMusic()
                end
            elseif not GuideManager.isInGuide then
                require("Battle.NgBattleResultManager")
                NgBattleResultManager_playNextResult()
            end
            
            if isAlbum then 
                PageManager.popPage(thisPageName)
            else
                local currPage = MainFrame:getInstance():getCurShowPageName()
                MainFrame_onBattlePageBtn()
                if currPage == "NgBattlePage" then
                    NgBattlePageInfo_refreshMinigame()
                end
            end
            PageManager.setIsInGirlDiaryPage(false) 
        end)
        
        local array = CCArray:create()
        array:addObject(CCDelayTime:create(0.2))
        array:addObject(Ani)
        array:addObject(CCDelayTime:create(2))
        array:addObject(clear)
        -- 新手教學
        if GuideManager.getCurrentCfg() and GuideManager.getCurrentCfg().showType == GameConfig.GUIDE_TYPE.PLAY_H_STORY then
            array:addObject(CCCallFunc:create(function()
                GuideManager.IsNeedShowPage = false
                GuideManager.forceNextNewbieGuide()
            end))
        end
        parentNode:runAction(CCSequence:create(array))
    end
end
function AlbumStoryDisplayBase:onNext()
    SpineIdx = SpineIdx + 1
    if SpineIdx <= #Spines then
        local tmp = string.sub(SpineData[SpineIdx].id, 5, 6)
        if SpineIdx >= #Spines and not Gamepassed and tmp~="41"then
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(1))
            array:addObject(CCCallFunc:create(function()
                        --self:onFaild(selfContainer)
                         AlbumStoryDisplayBase:Exit(selfContainer)
                    end))
            selfContainer:runAction(CCSequence:create(array))
            return
        end
        parentNode:removeAllChildrenWithCleanup(true)
        parentNode:addChild(spineNode[SpineIdx])
        if string.find(SpineData[SpineIdx].anime, "animation") or string.find(SpineData[SpineIdx].anime, "A") then
            CCLuaLog(">>>>>>>>>onNext(): " .. SpineData[SpineIdx].anime)
            Spines[SpineIdx]:runAnimation(1, SpineData[SpineIdx].anime, 0)
        else
            Spines[SpineIdx]:runAnimation(1, SpineData[SpineIdx].anime, -1)
        end
        if SpineData[SpineIdx].Game ~= "" then
            NodeHelper:setNodesVisible(selfContainer, {mMiniGame = true})
            --MiniGame
            GameTime = tonumber(SpineData[SpineIdx].Game)
            nowTime = GameTime
            
            local parentNode = selfContainer:getVarNode("mTouchSpine")
            local spinePath = "Spine/NGUI"
            local spineName = "NGUI_87_touchscreen"
            local spine = SpineContainer:create(spinePath, spineName)
            local TouchNode = tolua.cast(spine, "CCNode")
            parentNode:addChild(TouchNode)
            parentNode:setScale(0.5)
            spine:runAnimation(1, "animation", -1)
        end
        --txt
        local spinePath = "Spine/NG2DHCG/MiniGame"
        local tmp = SpineData[SpineIdx].Spine
        local spineName2 = GameMaths:replaceStringWithCharacterAll(tmp, "NGSceneA", "NGSceneB")
        local Head = common:split(spineName2, "_")[1]
        local isFileExist = NodeHelper:isFileExist("Spine/NG2DHCG/MiniGame/" .. spineName2 .. ".png")
        if Head == "NGSceneB" and isFileExist then
            local spine2 = SpineContainer:create(spinePath, spineName2)
            local txtNode = tolua.cast(spine2, "CCNode")
            parentNode3:removeAllChildrenWithCleanup(true)
            parentNode3:addChild(txtNode)
            spine2:runAnimation(1, SpineData[SpineIdx].anime, 0)
        end
    else
        --PageManager.popPage(thisPageName)
       -- NodeHelper:setNodesVisible(selfContainer, {mReturnBtn = true})
        AlbumStoryDisplayBase:Exit(selfContainer)
        --AlbumStoryDisplayBase:onReturn(selfContainer)
    end
    --切換BGM
    local newBgmName = SpineData[SpineIdx] and SpineData[SpineIdx].BGM or ""
    if newBgmName ~= nowBgmName then
        if newBgmName == "" then
            SoundManager:getInstance():stopMusic()--關閉BGM
        else
            SoundManager:getInstance():playMusic(newBgmName, false)
        end
        nowBgmName = newBgmName
    end
--NodeHelper:setStringForLabel(selfContainer, { mTitle = SpineData[SpineIdx] and SpineData[SpineIdx].anime }))
end
function AlbumStoryDisplayBase:initSetting(container)
    lines = {}
    linesCharater = {}
    nowLineTable = {}
    NodeHelper:setStringForLabel(container, {mTxt = ""})
    NodeHelper:setNodesVisible(container, {mSpine3 = false})
    local langForward = "@girlstory"
    local splitStr = nil
    for i = 1, 99 do
        local str = SpineData[SpineIdx] and common:getLanguageString(langForward .. SpineData[SpineIdx].id .. string.format("%02d", i)) or ""
        if string.find(str, "_") then
            splitStr = common:split(str, "_")
            linesCharater[i] = splitStr[1]
            lines[i] = splitStr[2]
            splitStr = common:split(str, "_")
        else
            lines[i] = str
            if not string.find(str, "@") then
                linesCharater[i] = ""
            --NodeHelper:setStringForLabel(container, {mTitle = ""})
            end
        end
        if string.find(lines[i], langForward) then
            table.remove(lines, i)
            break
        end
    end
    nowLine = 1
    if lines[nowLine] and SpineData[SpineIdx] then
        nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
        NodeHelper:setStringForLabel(container, {mTitle = linesCharater[nowLine]})
        table.insert(logTable, {
            Txt = lines[nowLine],
            Name = linesCharater[nowLine]
        });
    end
    isLabelPlaying = true
    lineIndex = 1
    labelTimer = 0
    nowActionType = DiaryTypeNew.NONE
end
function AlbumStoryDisplayBase:setData(data, onAlbum)
    SpineData = data
    isAlbum = onAlbum
end
function AlbumStoryDisplayBase:onExecute(container)
    if mSpineNode then
        mSpineNode:scheduleUpdateWithPriorityLua(function(dt)
            AlbumStoryDisplayBase:update(dt, container)
        end, 0)
    end
end
function AlbumStoryDisplayBase:update(dt, container)
    if not isLoadEnd then
        return
    end
    if not isStartPlay then
        self:startPlayStory()
    end
    if SpineIdx>=GameIndex and SpineData[SpineIdx] and nowTime>0 then
        NodeHelper:setNodesVisible(container,{mControlBtnTop=false})         
    end
    if SpineIdx >= GameIndex and nowTime > 0 then
        if labelTimer >= labelSpeed then
            NeedTimes = SpineData[GameIndex].TypeTimes*6
            NodeHelper:setNodesVisible(container,{mHit=true})
            nowTime = nowTime - 0.03
            if TapTimes > 0 then
                TapTimes = TapTimes - 0.3
            else
                TapTimes = 0
            end
            if TapTimes > 0 and GameTime-nowTime>5 then
                NodeHelper:setNodesVisible(container,{mTouchSpine=false})
            end
            if nowTime <= 0 then
                if TapTimes < NeedTimes*0.8 then
                    local parentNode = selfContainer:getVarNode("mResultSpine")
                    parentNode:removeAllChildrenWithCleanup(true)
                    local spinePath = "Spine/NGUI"
                    local spineName = "NGUI_86_minigame_result"
                    local spine = SpineContainer:create(spinePath, spineName)
                    local ResultNode = tolua.cast(spine, "CCNode")
                    parentNode:addChild(ResultNode)
                    local array = CCArray:create()
                    array:addObject(CCCallFunc:create(function()
                        spine:runAnimation(1, "animation2", 0)
                    end))
                    array:addObject(CCDelayTime:create(2))
                    array:addObject(CCCallFunc:create(function()
                        NodeHelper:setNodesVisible(container, {mMiniGame = false})
                    end))
                    selfContainer:runAction(CCSequence:create(array))
                     TapDB_Data["#game_result"] = isAlbum and 5 or 2 
                     TapDBManager.trackEvent("#event_game",json.encode(TapDB_Data))
                    return
               elseif not Gamepassed then                    
                    Gamepassed = true
                    local parentNode = selfContainer:getVarNode("mResultSpine")
                    parentNode:removeAllChildrenWithCleanup(true)
                    local spinePath = "Spine/NGUI"
                    local spineName = "NGUI_86_minigame_result"
                    local spine = SpineContainer:create(spinePath, spineName)
                    local ResultNode = tolua.cast(spine, "CCNode")
                    parentNode:addChild(ResultNode)
                    local array = CCArray:create()
                    array:addObject(CCCallFunc:create(function()
                        spine:runAnimation(1, "animation", 0)
                        local tmp = tonumber (string.sub(SpineData[1].id, 5, 6))
                        FlagDataBase_DataChange(tmp,true)
                        TapDB_Data["#game_result"] = isAlbum and 4  or 1 
                        TapDBManager.trackEvent("#event_game",json.encode(TapDB_Data))
                    end))
                    array:addObject(CCDelayTime:create(1))
                    array:addObject(CCCallFunc:create(function()
                        NodeHelper:setNodesVisible(selfContainer, {mMiniGame = false})
                    end))  
                    selfContainer:runAction(CCSequence:create(array))
                    end
             end
            AlbumStoryDisplayBase:setContentScale(selfContainer, "mTime", nowTime, GameTime, TimeWidth)
            if TapTimes >= 0 then
                AlbumStoryDisplayBase:setContentScale(selfContainer, "mHealth", TapTimes, NeedTimes, HealthWidth)
            end
            --print(nowTime)
            labelTimer = 0
        end
        labelTimer = labelTimer + 1
    end
--播放文字
--if nowLineTable and nowLineTable[lineIndex] then
--    if not isLabelPlaying then
--        NodeHelper:setStringForLabel(container, {mTxt = lines[nowLine]})
--        return
--    end
--    if labelTimer >= labelSpeed then
--        local mLabel = container:getVarLabelTTF("mTxt")
--        local showLabel = mLabel:getString() .. nowLineTable[lineIndex].char
--        mLabel:setString(showLabel)
--        lineIndex = lineIndex + 1
--        labelTimer = 0
--
--    end
--    if not nowLineTable[lineIndex] then
--        isLabelPlaying = false
--        if string.find(SpineData[SpineIdx].anime, "animation") or string.find(SpineData[SpineIdx].anime, "A") then
--            NodeHelper:setNodesVisible(container, {mSpine3 = false})
--        else
--            if not isHide then
--                NodeHelper:setNodesVisible(container, {mSpine3 = true})
--            end
--        end
--    end
--    labelTimer = labelTimer + 1
--end
--if string.find(lines[nowLine], "@") then --劇情結束
--    nowLine = nowLine - 1
--    return
--end
end

function AlbumStoryDisplayBase:onAuto(container)
    if isAuto then
        isAuto = false
        NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
    else
        isAuto = true
        NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_ON.png", press = "Fetter_Btn_Auto_OFF.png"}})
        AlbumStoryDisplayBase:SelfTouch(container)
    end
end
function AlbumStoryDisplayBase:onGameTap()
    if nowTime<=0 then return end
    local Bar = tolua.cast(selfContainer:getVarNode("mHealth"), "CCScale9Sprite")
    Bar:setColor(ccc3(255, 0, 255))
    local ColorC = CCArray:create()
    ColorC:addObject(CCDelayTime:create(0.1))
    ColorC:addObject(CCCallFunc:create(function()
        Bar:setColor(ccc3(255, 255, 255))
    end))
    selfContainer:runAnimation("HitAni")
    selfContainer:runAction(CCSequence:create(ColorC))
    local tmp = string.sub(SpineData[SpineIdx].id, 5, 6)
    if TapTimes >= NeedTimes*0.78 then
        NodeHelper:setNodesVisible(selfContainer,{mEffect=true})
        if tmp == "41" then
            return
        end
    end
    TapTimes = TapTimes + 4
end
function AlbumStoryDisplayBase:onHide(container)
    if nowTime>0 then return end
    NodeHelper:setNodesVisible(container, {mHideBtn = false, mLogBtn = false, mAutoBtn = false, mSkipBtn = false, mStory = false,mNextBtn = false,mUnHide=true})
    isHide = true
end
function AlbumStoryDisplayBase:UnHide(container)
    NodeHelper:setNodesVisible(container, {mHideBtn = true, mLogBtn = false, mAutoBtn = false, mSkipBtn = true, mStory = true,mNextBtn = true,mUnHide=false})
    isHide = false
end
function AlbumStoryDisplayBase:onLog(container)--開啟Log
    isLog = true
    --container:getVarNode("mLogNode"):setRotation(90)
    self:setAllFetterLogContent(container)
    self:clearAndReBuildAllLog(container)
    NodeHelper:setNodesVisible(container, {mLogNode = true, mTouch = false})
    NodeHelper:setMenuItemImage(container, {mLogBtn = {normal = "Fetter_Btn_Log_ON.png", press = "Fetter_Btn_Log_OFF.png"}})
    if isAuto then
        NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
        isAuto = false
    end
end

function FetterLogContent:onRecall(container)
--if areaNum == 99 then    --新手教學
--    MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
--    return
--end
--FetterGirlsDiary:playTargetVoice(container, self.id)
end
function FetterLogContent:onPreLoad(container)
end
function FetterLogContent:onUnLoad(container)
end
function FetterLogContent:onJump(container)
--if areaNum == 99 then    --新手教學
--    MessageBoxPage:Msg_Box_Lan("@NewbieGuideStr152")
--    return
--end
--testNowLine = self.id
--FetterGirlsDiary:setLineState(FetterGirlsDiary:getContainer())
--FetterGirlsDiary:onCloseLog(FetterGirlsDiary:getContainer())
end


function FetterLogContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local parentNode = container:getVarLabelTTF("mDiaTxt")
    parentNode:setString("")
    parentNode:removeAllChildrenWithCleanup(true)
    local htmlModel = FreeTypeConfig[702].content
    local msgHtml = NodeHelper:addHtmlLable(parentNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", FetterLogContent.logTxt[self.id]), 0, CCSizeMake(680, 200))
    local htmlHeight = msgHtml:getContentSize().height
    local msgBgHeight = htmlHeight + 90
    if FetterLogContent.logName[self.id] == "" then msgBgHeight = msgBgHeight - 40 end
    local Bg = container:getVarScale9Sprite("mSprite")
    Bg:setContentSize(CCSize(820, msgBgHeight))
    NodeHelper:setStringForLabel(container, {
        mDiaName = FetterLogContent.logName[self.id]
    });
end

function AlbumStoryDisplayBase:clearAndReBuildAllLog(container)
    local logScrollView = container:getVarScrollView("mLogScrollView")
    logScrollView:removeAllCell()
    for i = #FetterLogContent.logTxt, 1, -1 do
        local logCell = CCBFileCell:create()
        local panel = FetterLogContent:new({id = i})
        logCell:registerFunctionHandler(panel)
        logCell:setCCBFile(FetterLogContent.ccbi)
        logScrollView:addCellBack(logCell)
        local height = AlbumStoryDisplayBase:calStringHeight(FetterLogContent.logTxt[i]) + 100
        if FetterLogContent.logName[i] == "" then height = height - 40 end
        logCell:setContentSize(CCSizeMake(height, 850))
    end
    logScrollView:orderCCBFileCells()
    logScrollView:locateToByIndex(0, CCBFileCell.LT_Bottom)
end

function AlbumStoryDisplayBase:calStringHeight(msg)
    local tempNode = CCNode:create()
    local htmlModel = FreeTypeConfig[702].content
    local msgHtml = NodeHelper:addHtmlLable(tempNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", msg), 0, CCSizeMake(680, 200))
    local htmlHeight = msgHtml:getContentSize().height
    
    return htmlHeight
end

function AlbumStoryDisplayBase:setAllFetterLogContent(container)
    FetterLogContent.logName = {}
    FetterLogContent.logTxt = {}
    for i = 1, #logTable do
        --logTxt
        FetterLogContent.logTxt[i] = logTable[i].Txt
        --logName
        FetterLogContent.logName[i] = logTable[i].Name
    end
end
function AlbumStoryDisplayBase:onExitBook(container)
    isLog = false
    NodeHelper:setNodesVisible(container, {mLogNode = false, mTouch = true})
    NodeHelper:setMenuItemImage(container, {mLogBtn = {normal = "Fetter_Btn_Log_OFF.png", press = "Fetter_Btn_Log_ON.png"}})
end
function AlbumStoryDisplayBase:SelfTouch(container, eventName)
    if nowState == DiaryState.SPINE then
        if isLabelPlaying then
            isLabelPlaying = false
            if nowActionType == DiaryTypeNew.NONE then
                NodeHelper:setNodesVisible(container, {mSpine3 = true})
            end
            return
        end
        if SpineData[SpineIdx] and SpineData[SpineIdx].txtCount <= nowLine and not nowLineTable[lineIndex] and SpineData[SpineIdx].anime == "loop" then
            self:onNext(container)
            --self:initSetting(selfContainer)
            return
        end
        if not isEndLineAct and (nowActionType == DiaryTypeNew.NONE or nowActionType == DiaryTypeNew.NEXTLINE) and SpineData[SpineIdx].anime == "loop" then
            nowLine = nowLine + 1
            --關閉對話提示
            NodeHelper:setNodesVisible(container, {mSpine3 = false})
            if lines[nowLine] then
                nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
            end
            NodeHelper:setStringForLabel(container, {mTitle = linesCharater[nowLine]})
            table.insert(logTable, {
                Txt = lines[nowLine],
                Name = linesCharater[nowLine]
            });
            labelTimer = 0
            lineIndex = 1
            NodeHelper:setStringForLabel(container, {mTxt = ""})
            isLabelPlaying = true
        end
    end

end

function AlbumStoryDisplayBase:onTouch(container, eventName)
    NodeHelper:setNodesVisible(container, {mHideBtn = true, mLogBtn = true, mAutoBtn = true, mSkipBtn = true, mTxtSpine = true})
    isHide = false
--if isAuto or isLog then return end
--if nowState == DiaryState.SPINE then
--    if isLabelPlaying then
--        isLabelPlaying = false
--        if nowActionType == DiaryTypeNew.NONE and not isHide then
--           -- NodeHelper:setNodesVisible(container, {mSpine3 = true})
--        end
--        return
--    end
--    if not SpineData[SpineIdx] then
--        return
--    end
--    if SpineData[SpineIdx].txtCount <= nowLine and SpineData[SpineIdx].anime == "loop" then
--        self:onNext(container)
--        --self:initSetting(selfContainer)
--        return
--    end
--    if not isEndLineAct and (nowActionType == DiaryTypeNew.NONE or nowActionType == DiaryTypeNew.NEXTLINE) and SpineData[SpineIdx].anime == "loop" then
--        nowLine = nowLine + 1
--        NodeHelper:setNodesVisible(container, {mSpine3 = false})
--        if lines[nowLine] then
--            nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
--        end
--        NodeHelper:setStringForLabel(container,{mTitle=linesCharater[nowLine] })
--      table.insert(logTable,{
--                            Txt=lines[nowLine],
--                            Name=linesCharater[nowLine]
--                          });
--        labelTimer = 0
--        lineIndex = 1
--        NodeHelper:setStringForLabel(container, {mTxt = ""})
--        isLabelPlaying = true
--    end
--end
--
end --
local CommonPage = require("CommonPage")
local AlbumStoryDisplayPage = CommonPage.newSub(AlbumStoryDisplayBase, thisPageName, option)

return AlbumStoryDisplayPage
