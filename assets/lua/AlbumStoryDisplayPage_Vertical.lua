local thisPageName = "AlbumStoryDisplayPage_Vertical"

local opcodes = {
    
    }

local option = {
    ccbiFile = "AlbumStoryDisplay_vertical.ccbi",
    handlerMap = {
        onTutorialSkip = "onReturn",
        --onNext="onNext"
        onTouch = "onTouch",
        onHide = "onHide",
        onAuto = "onAuto",
        onLog = "onLog",
        onExitBook = "onExitBook"
    },
}
local AlbumStoryDisplayBase_Vertical = {}
local SpineData = {}
local SpineIdx = 1
local Spines = {}
local spineNode = {}
local parentNode = nil
local parentNode2 = nil
local selfContainer = nil
local isAlbum = false
local isAuto = false
local isHide = false
local isLog = false
local soundTable = {}

local FetterLogContent = {
    ccbi = "FetterGirlsDiaryDialogue.ccbi",
    logName = {},
    logTxt = {},
    logVoice = {},
}

local DiaryState = {SPINE = 1, HIDE = 2}
local DiaryTypeNew = {NONE = 0, SPINE = 1, TRANS = 2, FADEIN = 3, ANIMATION = 4, WAITLINE = 5,
    NEXTLINE = 6, VISIBLEUI = 7, HALFBODY = 8, SPINEFILE = 9, PARENT = 11, WAIT = 999, Loop = 12, notLoop = 13}

local nowState = DiaryState.SPINE
--全劇情文字
local lines = { }
--角色
local linesCharater={}
--目前劇情編號
local nowLine = 1
--Log可顯示的劇情編號
local logTable={}
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
--是否等待劇情結束
local isEndLineAct = false
--當前BGM
local nowBgmName = ""
--當前語音ID
local nowVoiceEffId = 0
--當前其他音效
local nowOtherEffName = ""
--當前其他音效ID
local nowOtherEffId = 0
local TouchCD = false
local voiceTable = {}

--動畫資料
function AlbumStoryDisplayBase_Vertical:setData(mID)
    local Tmptable = {}
    local cfg = ConfigManager.getStoryData_Vertical()
    --local id = "1" .. string.format("%02d", mID)
    local id = mID .. string.format("%02d", 1)
    for i = 1, 99 do
        local tmpId = tonumber(id .. string.format("%02d", i))
        if cfg[tmpId] then
            table.insert(Tmptable, cfg[tmpId])
        end
    end
    SpineData = Tmptable

    soundTable = {}
    for _,data in pairs (SpineData) do
        local nameTable = common:split(data.EFF,",")
        for _,v in ipairs (nameTable) do
            local filename = common:split(v,"_")[2] 
            table.insert(soundTable,filename)
        end     
    end
    AlbumStoryDisplayBase_Vertical:preloadAudioEffects(soundTable,3)
end
function AlbumStoryDisplayBase_Vertical:preloadAudioEffects(files, batchSize)
    for i = 1, #files, batchSize do
        local endIndex = math.min(i + batchSize - 1, #files)
        for j = i, endIndex do
            SimpleAudioEngine:sharedEngine():preloadEffect(files[j])
        end
         os.execute("sleep 0.1")
    end
end
function AlbumStoryDisplayBase_Vertical:onEnter(container)
    isAuto = false
    TouchCD = false
    logIndex = 1
    logTable = {}
    SoundManager:getInstance():stopMusic()
    NodeHelper:setNodesVisible(container, {mLogNode = false,mBlack = false})
    selfContainer = container
    self:setSpine(container)
    --AlbumStoryDisplayBase_Vertical:initSetting(selfContainer)

    --local TextHeight = NodeHelper:Add_9_16_Layer(container,"mLayer")
    --container:getVarNode("mStory"):setPositionY(TextHeight)

    mSpineNode = container:getVarNode("mSpine3")
    mSpineNode:removeAllChildrenWithCleanup(true)
    self:SetNextSpine(container)
    if isAlbum then
        NodeHelper:setNodesVisible(selfContainer, {mReturnBtn = true})
    end
    NodeHelper:setStringForLabel(container, {mTxt = ""})
    container:getVarLabelTTF("mTxt"):setDimensions(CCSizeMake(650, 200))
	--selfContainer:getVarNode("mShadow"):setScale(NodeHelper:getScaleProportion())
end
--首次spine
function AlbumStoryDisplayBase_Vertical:setSpine(container)
    Spines = {}
    spineNode = {}
    SpineIdx = 1
    local spinePath = "Spine/NG2DHCG/HScene"
    parentNode = container:getVarNode("mSpine")
    parentNode2 = container:getVarNode("mSpine2")
    parentNode:removeAllChildrenWithCleanup(true)
    parentNode2:removeAllChildrenWithCleanup(true)
    
    for i = 1, #SpineData do
        Spines[i] = SpineContainer:create(spinePath, SpineData[i].Spine)
        spineNode[i] = tolua.cast(Spines[i], "CCNode")
        Spines[i]:registerFunctionHandler("COMPLETE", AlbumStoryDisplayBase_Vertical.onFunction)
    end
    spinePath = "Spine/NGUI"
    local spineName = "NGUI_77_Shady"
    local spine = SpineContainer:create(spinePath, spineName)
    local EnterNode = tolua.cast(spine, "CCNode")
    local scale = NodeHelper:getScaleProportion()
    parentNode2:setScale(scale)
    parentNode:addChild(spineNode[1])
    parentNode2:addChild(EnterNode)
    spine:runAnimation(1, "Enter", 0)
    if SpineData[1].type == 0 then
        Spines[1]:runAnimation(1, SpineData[1].anime, 0)
    else
        Spines[1]:runAnimation(1, SpineData[1].anime, -1)
    end
    AlbumStoryDisplayBase_Vertical:initSetting(selfContainer)
    nowBgmName = SpineData[lineIndex].BGM
end
function AlbumStoryDisplayBase_Vertical:SetNextSpine(container)
    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_78_Next"
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local parentNode = container:getVarNode("mSpine3")
    parentNode:addChild(spineNode)
    spine:runAnimation(1, "animation", -1)
end
--第一次進動畫
function AlbumStoryDisplayBase_Vertical:initSetting(container)
    lines = {}
    linesCharater = {}
    nowLineTable = {}
    NodeHelper:setStringForLabel(container, {mTxt = ""})
    NodeHelper:setNodesVisible(container, {mSpine3 = false})
    local langForward = "@girlstory"
    local splitStr = nil
    local Voicecfg=SpineData[SpineIdx].Voice
    local EffCfg=SpineData[SpineIdx].EFF
    voiceTable = {}
    EffTable={}
    --配音資料
    for _, voice in ipairs(common:split(Voicecfg , ",")) do
            local _id, _delay, _name = unpack(common:split(voice, "_"))
            table.insert(voiceTable, {
                id = tonumber(_id),
                delay = tonumber(_delay),
                name = _name
            } )
     end
     --音效資料
      for _, eff in ipairs(common:split(EffCfg , ",")) do
            local _delay , _name = unpack(common:split(eff, "_"))
            table.insert(EffTable, {
                delay = tonumber(_delay),
                name = _name
            } )
     end
     --文字資料
    for i = 1, 99 do
        local str = SpineData[SpineIdx] and common:getLanguageString(langForward .. SpineData[SpineIdx].id .. string.format("%02d", i)) or ""
        if string.find(str, "_") then
            splitStr = common:split(str, "_")
            splitStr[1] = GameMaths:replaceStringWithCharacterAll(splitStr[1], "#Name#", UserInfo.roleInfo.name)
            splitStr[2] = GameMaths:replaceStringWithCharacterAll(splitStr[2], "#Name#", UserInfo.roleInfo.name)
            linesCharater[i] = splitStr[1]
            lines[i] = splitStr[2]
            splitStr = common:split(str, "_")
        else
            str = GameMaths:replaceStringWithCharacterAll(str, "#Name#", UserInfo.roleInfo.name)
            lines[i] = str
            linesCharater[i] = ""
        end
        if string.find(lines[i], langForward) then
            table.remove(lines, i)
            table.remove(linesCharater, i)
            break
        end
    end
    --初始化
    nowLine = 1
    isLabelPlaying = true
    lineIndex = 1
    labelTimer = 0
    nowActionType = DiaryTypeNew.NONE
    --LOG資料
    if lines[nowLine] then
        nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
        NodeHelper:setStringForLabel(container, {mTitle = linesCharater[nowLine]})
        table.insert(logTable, {
            Txt = lines[nowLine],
            Name = linesCharater[nowLine]
        });
    end
    --首次播BGM
    local newBgmName = SpineData[SpineIdx] and SpineData[SpineIdx].BGM
    if newBgmName ~= nowBgmName and newBgmName~=""then
        SoundManager:getInstance():playMusic(newBgmName, true)
        nowBgmName = newBgmName
    end
    --首次播配音
    AlbumStoryDisplayBase_Vertical:playVoice(container)
    --首次播音效
    for _,value in pairs (EffTable) do
        --SoundManager:getInstance():stopAllEffect()
        local newOtherEffName=value.name

       if newOtherEffName~=nowEff and NodeHelper:isFileExist("/audio/" .. newOtherEffName) then
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(value.delay))
            array:addObject(CCCallFunc:create(function()
                    SoundManager:getInstance():playEffectByName(newOtherEffName,SpineData[SpineIdx].type == 1)
            end))
            container:runAction(CCSequence:create(array))
        end
    end
end
--動畫完成一次播放
function AlbumStoryDisplayBase_Vertical:onFunction(tag, eventName)
    if eventName == "COMPLETE" then
        if not SpineData[SpineIdx] then
            return
        end
        --自動模式下 loop延遲 ; 非loop切下一段
        if isAuto and SpineData[SpineIdx].type == 1 and not TouchCD then
            TouchCD = true
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(3))
            array:addObject(CCCallFunc:create(function()
                AlbumStoryDisplayBase_Vertical:SelfTouch(selfContainer)
                TouchCD = false
            end))
            selfContainer:runAction(CCSequence:create(array))
        elseif SpineData[SpineIdx] and SpineData[SpineIdx].type == 0 then
                AlbumStoryDisplayBase_Vertical:onNext()
                if SpineData[SpineIdx] then
                    AlbumStoryDisplayBase_Vertical:initSetting(selfContainer)
                end
        end
        --撥放音效
      --if SpineData[SpineIdx] and SpineData[SpineIdx].type == 1 then
      --    for _,value in pairs (EffTable) do
      --        local newOtherEffName=value.name or nil
      --        if newOtherEffName and NodeHelper:isFileExist("/audio/" .. newOtherEffName) then
      --            local array = CCArray:create()
      --            array:addObject(CCDelayTime:create(value.delay or 0))
      --            array:addObject(CCCallFunc:create(function()
      --                SoundManager:getInstance():playEffectByName(newOtherEffName,true)
      --            end))
      --            selfContainer:runAction(CCSequence:create(array))
      --        end
      --    end
      --end
    end
end
--玩家點擊
function AlbumStoryDisplayBase_Vertical:onTouch(container, eventName)
    NodeHelper:setNodesVisible(container, {mHideBtn = true, mLogBtn = true, mAutoBtn = true, mSkipBtn = true, mStory = true})
    if isHide then 
        isHide= false
        return
    end
    if isAuto or isLog then return end
    if nowState == DiaryState.SPINE then
        if isLabelPlaying then
            isLabelPlaying = false
            if nowActionType == DiaryTypeNew.NONE and not isHide then
                NodeHelper:setNodesVisible(container, {mSpine3 = true})
            end
            return
        end
        if not SpineData[SpineIdx] then
            return
        end
        --loop狀態 文字播完
        if SpineData[SpineIdx].txtCount <= nowLine and (not lines[nowLine + 1]) and SpineData[SpineIdx].type == 1 then
            self:onNext(container)
            self:initSetting(selfContainer)
            return
        end
        --loop狀態 文字未播完
        if not isEndLineAct and (nowActionType == DiaryTypeNew.NONE or nowActionType == DiaryTypeNew.NEXTLINE) and SpineData[SpineIdx].type == 1 then
            nowLine = nowLine + 1
            NodeHelper:setNodesVisible(container, {mSpine3 = false})
            if lines[nowLine] then
                nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
            end
            NodeHelper:setStringForLabel(container, {mTitle = linesCharater[nowLine]})
            --紀錄LOG
            if lines[nowLine] then
                table.insert(logTable, {
                    Txt = lines[nowLine],
                    Name = linesCharater[nowLine]
                });
            end
            --復原
            labelTimer = 0
            lineIndex = 1
            NodeHelper:setStringForLabel(container, {mTxt = ""})
            isLabelPlaying = true
        end
    end
end
--配音播放
function AlbumStoryDisplayBase_Vertical:playVoice(container)
    self:stopVoice(container)
    local voicename=""
    local delay=0
    local nowId=tonumber(SpineData[SpineIdx].id .. string.format("%02d", nowLine))
    for _,v in pairs (voiceTable) do
        if v.id== nowId then
            voicename=v.name or ""
            delay=v.delay or 0
        end
    end
    local isFileExist = NodeHelper:isFileExist("/audio/" .. voicename) and voicename~=""
    if isFileExist then
        local actionArr = CCArray:create()
        actionArr:addObject(CCDelayTime:create(delay))
        actionArr:addObject(CCCallFunc:create(function()
            SoundManager:getInstance():playEffectByName(voicename,false)
        end))
        container:runAction(CCSequence:create(actionArr))
    end
end
--停止音效
function AlbumStoryDisplayBase_Vertical:stopVoice(container)
    SoundManager:getInstance():stopAllEffect()
    if nowVoiceEffId ~= 0 then
        if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
            SimpleAudioEngine:sharedEngine():stopEffect(nowVoiceEffId)
        else
            SoundManager:getInstance():stopOtherMusic()
            nowVoiceEffId = 0
        end
    end
end
--退出
function AlbumStoryDisplayBase_Vertical:onReturn(container,Finish)
    isAuto = false
    if Finish == true then
         AlbumStoryDisplayBase_Vertical:Quit()
    else
        local title = common:getLanguageString("@SkipTitle")
        local msg = common:getLanguageString("@SkipStory")
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                AlbumStoryDisplayBase_Vertical:Quit()
            end
        end, true, nil, "@Back", nil, 0.9);
    end
end
function AlbumStoryDisplayBase_Vertical:unloadAudioEffects(files, batchSize)
    for i = 1, #files, batchSize do
        local endIndex = math.min(i + batchSize - 1, #files)
        for j = i, endIndex do
            SimpleAudioEngine:sharedEngine():unloadEffect(files[j])
        end
         os.execute("sleep 0.1")
    end
end
function AlbumStoryDisplayBase_Vertical:Quit()
   AlbumStoryDisplayBase_Vertical:unloadAudioEffects(soundTable, 5)
   local spinePath = "Spine/NGUI"
   local spineName = "NGUI_77_Shady"
   local spine = SpineContainer:create(spinePath, spineName)
   local QuitNode = tolua.cast(spine, "CCNode")
   local Ani = CCCallFunc:create(function()
       SoundManager:getInstance():stopAllEffect() --關閉音效
       --SoundManager:getInstance():playEffectByName("",false)
       SoundManager:getInstance():playGeneralMusic()
       parentNode2:addChild(QuitNode)
       spine:runAnimation(1, "quit", 0)
   end)
   local clear = CCCallFunc:create(function()
       parentNode2:removeAllChildrenWithCleanup(true)
       nowBgmName=""
       PageManager.popPage(thisPageName)
   end)
   
   local array = CCArray:create()
   array:addObject(CCDelayTime:create(0.2))
   array:addObject(Ani)
   array:addObject(CCDelayTime:create(2))
   array:addObject(clear)
   
   parentNode:runAction(CCSequence:create(array))
end
--下一個Spine
function AlbumStoryDisplayBase_Vertical:onNext()
    SpineIdx = SpineIdx + 1
    if SpineIdx <= #Spines then
        parentNode:removeAllChildrenWithCleanup(true)
        parentNode:addChild(spineNode[SpineIdx])
        if SpineData[SpineIdx].type == 0 then
            Spines[SpineIdx]:runAnimation(1, SpineData[SpineIdx].anime, 0)
        else
            Spines[SpineIdx]:runAnimation(1, SpineData[SpineIdx].anime, -1)
        end
    else
        AlbumStoryDisplayBase_Vertical:Quit()
        NodeHelper:setNodesVisible(selfContainer, {mReturnBtn = true})
        --AlbumStoryDisplayBase_Vertical:onReturn(selfContainer)
    end
end
function AlbumStoryDisplayBase_Vertical:onExecute(container)
    if mSpineNode then
        mSpineNode:scheduleUpdateWithPriorityLua(function(dt)
            AlbumStoryDisplayBase_Vertical:update(dt, container)
        end, 0)
    end
end
--播放文字
function AlbumStoryDisplayBase_Vertical:update(dt, container)
    if nowLineTable and nowLineTable[lineIndex] then
        if not isLabelPlaying then
            NodeHelper:setStringForLabel(container, {mTxt = lines[nowLine]})
            return
        end
        
        if labelTimer >= labelSpeed then
            local mLabel = container:getVarLabelTTF("mTxt")
            mLabel:setDimensions(CCSizeMake(550, 200))
            local showLabel = mLabel:getString() .. nowLineTable[lineIndex].char
            mLabel:setString(showLabel)
            lineIndex = lineIndex + 1
            labelTimer = 0
        end
        
        if not nowLineTable[lineIndex] then
            isLabelPlaying = false
            if SpineData[SpineIdx].type == 0 then
                NodeHelper:setNodesVisible(container, {mSpine3 = false})
            else
                if not isHide then
                    NodeHelper:setNodesVisible(container, {mSpine3 = true})
                end
            end
        end
        labelTimer = labelTimer + 1
    end
   --if string.find(lines[nowLine], "@") then --劇情結束
   --    nowLine = nowLine - 1
   --    return
   --end
end
----AUTO
function AlbumStoryDisplayBase_Vertical:onAuto(container)
    if isAuto then
        isAuto = false
        TouchCD = false
        NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_OFF.png", press = "Fetter_Btn_Auto_ON.png"}})
    else
        isAuto = true
        NodeHelper:setMenuItemImage(container, {mAutoBtn = {normal = "Fetter_Btn_Auto_ON.png", press = "Fetter_Btn_Auto_OFF.png"}})
    end
end
function AlbumStoryDisplayBase_Vertical:SelfTouch(container, eventName)
    if nowState == DiaryState.SPINE then
        if isLabelPlaying then
            isLabelPlaying = false
            if nowActionType == DiaryTypeNew.NONE then
                NodeHelper:setNodesVisible(container, {mSpine3 = true})
            end
            return
        end
        if SpineData[SpineIdx] and SpineData[SpineIdx].txtCount <= nowLine and (not lines[nowLine + 1]) then
            self:onNext(container)
            self:initSetting(selfContainer)
            return
        end
        if not isEndLineAct and (nowActionType == DiaryTypeNew.NONE or nowActionType == DiaryTypeNew.NEXTLINE) and SpineData[SpineIdx].type == 1 then
            nowLine = nowLine + 1
        --關閉對話提示
            NodeHelper:setNodesVisible(container, {mSpine3 = false})
            if lines[nowLine] then
                nowLineTable = NodeHelper:utf8tochars(lines[nowLine])
            end
            NodeHelper:setStringForLabel(container, {mTitle = linesCharater[nowLine]})
            if lines[nowLine] then
                table.insert(logTable, {
                    Txt = lines[nowLine],
                    Name = linesCharater[nowLine]
                });
            end
            labelTimer = 0
            lineIndex = 1
            NodeHelper:setStringForLabel(container, {mTxt = ""})
            isLabelPlaying = true
        end
    end
     --新BGM
    local newBgmName = SpineData[SpineIdx] and SpineData[SpineIdx].BGM
    if newBgmName ~= nowBgmName and newBgmName~="" then
        SoundManager:getInstance():playMusic(newBgmName, true)
        nowBgmName = newBgmName
    end
    if SpineData[SpineIdx].type == 1 then
        --撥放配音
        AlbumStoryDisplayBase_Vertical:playVoice(container)
    end
end
--HIDE
function AlbumStoryDisplayBase_Vertical:onHide(container)
    NodeHelper:setNodesVisible(container, {mHideBtn = false, mLogBtn = false, mAutoBtn = false, mSkipBtn = false, mStory = false,mSpine3=false})
    isHide = true
end
----------LOG--------
function AlbumStoryDisplayBase_Vertical:onLog(container) --開啟Log
    isLog=true
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
function FetterLogContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local parentNode = container:getVarLabelTTF("mDiaTxt")
    parentNode:setString("")
    parentNode:removeAllChildrenWithCleanup(true)
    local htmlModel = FreeTypeConfig[702].content
    local msgHtml = NodeHelper:addHtmlLable(parentNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", FetterLogContent.logTxt[self.id]), 0, CCSizeMake(550, 200))
    local htmlHeight = msgHtml:getContentSize().height
    local msgBgHeight = htmlHeight + 90
    if FetterLogContent.logName[self.id] == "" then msgBgHeight = msgBgHeight - 40 end
    local Bg = container:getVarScale9Sprite("mSprite")
    Bg:setContentSize(CCSize(Bg:getContentSize().width, msgBgHeight))
    NodeHelper:setStringForLabel(container, {
        mDiaName = FetterLogContent.logName[self.id]
    });
end
function AlbumStoryDisplayBase_Vertical:clearAndReBuildAllLog(container)
    local logScrollView = container:getVarScrollView("mLogScrollView")
    logScrollView:removeAllCell()
    for i = 1, #FetterLogContent.logTxt do
        local logCell = CCBFileCell:create()
        local panel = FetterLogContent:new({id = i})
        logCell:registerFunctionHandler(panel)
        logCell:setCCBFile(FetterLogContent.ccbi)
        logScrollView:addCellBack(logCell)
        local height = AlbumStoryDisplayBase_Vertical:calStringHeight(FetterLogContent.logTxt[i]) + 100
        if FetterLogContent.logName[i] == "" then height = height - 40 end
        logCell:setContentSize(CCSizeMake(logCell:getContentSize().width, height))
    end
    logScrollView:orderCCBFileCells()
    logScrollView:locateToByIndex(#FetterLogContent.logTxt - 1, CCBFileCell.LT_Bottom)
end
function AlbumStoryDisplayBase_Vertical:calStringHeight(msg)
    local tempNode = CCNode:create()
    local htmlModel = FreeTypeConfig[702].content
    local msgHtml = NodeHelper:addHtmlLable(tempNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", msg), 0, CCSizeMake(550, 200))
    local htmlHeight = msgHtml:getContentSize().height
    
    return htmlHeight
end
function AlbumStoryDisplayBase_Vertical:setAllFetterLogContent(container)
    FetterLogContent.logName = {}
    FetterLogContent.logTxt = {}
    for i = 1, #logTable do
        --logTxt
        FetterLogContent.logTxt[i] = logTable[i].Txt
        --logName
        FetterLogContent.logName[i] = logTable[i].Name
    end
end
function AlbumStoryDisplayBase_Vertical:onExitBook(container)
    isLog = false
    NodeHelper:setNodesVisible(container, {mLogNode = false, mTouch = true})
    NodeHelper:setMenuItemImage(container, {mLogBtn = {normal = "Fetter_Btn_Log_OFF.png", press = "Fetter_Btn_Log_ON.png"}})
end
function FetterLogContent:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
----------------------
local CommonPage = require("CommonPage")
local AlbumStoryDisplayPage_Flip = CommonPage.newSub(AlbumStoryDisplayBase_Vertical, thisPageName, option)

return AlbumStoryDisplayPage_Flip
