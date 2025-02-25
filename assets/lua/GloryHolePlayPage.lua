local thisPageName = "GloryHolePlayPage"
local TapDBManager = require("TapDBManager")
local json = require('json')
local NodeHelperUZ = require("Util.NodeHelperUZ")
local ResManager = require("ResManagerForLua")
local ItemManager = require("Item.ItemManager")

local opcodes = {
    }

local option = {
    ccbiFile = "GloryHole_Play.ccbi",
    handlerMap = {
        onPause = "onPause",
        onCancel = "onCancel",
        onConfirmation = "onConfirmation",
        --onTouch = "onGameTap",
        onResultConfirm = "onResultConfirm"
    },
}
local GloryHole_PlayBase = {}

local Animation_A_Data = {}
local Animation_B_Data = {}
local WholeTable = {}
local nowTableIdx

local BGM=""
local Eff={["A"]="",["B"]="",["D"]=""}


local AnimIdx = 0

local parentNode
local MainSpinePath = ""
local MainSpineName = ""
local Spine = nil
local spineNode = nil
local Bottom_PosY = -260
local Top_PosY = 180
local SelfContainer

local MoveTable = {}

local CanTap = true
local TotalScore = 0
local FeverActiveTimes=0
local PerfectTimes=0
local MaxCombo=0
local tmpScore
local nowMove = 0
local nowMovePassedTime = 0
local Moving = ""
local isPause = false

local FEVER_TIME_SCORE = GameConfig.GLOYHOLE.FEVER_TIME_SCORE
local FEVER_TIME_LONG = GameConfig.GLOYHOLE.FEVER_TIME_LONG
local FEVER_PERCENT= GameConfig.GLOYHOLE.FEVER_PERCENT
local scoreForFever = 0
local isFeverTime = false
local FeverPassedTime = 0


local AddPointParent
local AddPointCCB

local mClippingNode

local TOTAL_TIME = GameConfig.GLOYHOLE.GAME_TOTAL_TIME
local nowLeftTime

local ExplosionSpine
local ExplosionNode

local GetGrade = false
local Grade_Opacity = 100
local GradeScale = 1.5

local PlayMode = "Play"
local MaxScore = 0

local isCountingDown = false

local UsingItems = {}

local ComboCount = 0

local ComboInfo = GameConfig.GLOYHOLE.ComboInfo

local RankImg = GameConfig.GLOYHOLE.RankImg

local ItemIcon = GameConfig.GLOYHOLE.ItemIcon

local ItemCCB = GameConfig.GLOYHOLE.ItemCCB
local ItemParentNode = nil
local ChildNode = { }

local RankRule = GameConfig.GLOYHOLE.RankRule
local Scores = GameConfig.GLOYHOLE.Scores

local BarMode = 0

local SpineScale = 0.65

local ItemEffect = {PerfectCount = 50,
                    PerfectEffect = false,
                    FeverBarProgess = 0.3,
                    FeverBar = false,
                    DoubleGradeTime = 10,
                    DoubleGrade = false,
                    DoubleOriginHeight = 0,
                    DoubleOriginWidth = 0,
                    DoublePlayed = false}


function ResetData()
    FeverActiveTimes=0
    MaxCombo=0
    PerfectTimes=0
    tmpScore = 0
    TotalScore = 0
    ComboCount = 0
    nowMovePassedTime = 0
    FeverPassedTime = 0
    scoreForFever = 0
    nowLeftTime = TOTAL_TIME
    isFeverTime = false
end

local ResultRewardContent = { ccbiFile = "BackpackItem.ccbi" }

function GloryHole_PlayBase:onEnter(container)
    SelfContainer = container
    ResetData()
    parentNode = container:getVarNode("mSpine")
    ItemParentNode = container:getVarNode("mUsingItem")
    --container:runAnimation("Touch")
    GloryHole_PlayBase:setCountDownSpine(container)
    GloryHole_PlayBase:setOtherAnim(container)
    GloryHole_PlayBase:SetClipNode(container)
    GloryHole_PlayBase:InitExplosionSpine()
    GloryHole_PlayBase:SetItemEffect(container)
    if PlayMode ~= "Play" then       
        NodeHelper:setNodesVisible(container, {mHightScoreNode = false})

        local data = {} 
        data["#gloryhole_times"] = 0
        data["#gloryhole_type"] = 0

        local useItem = {["addbar"] = false,
                         ["offset"] = false,
                         ["addGain"] = false}

        local function setUseItem(flag)
            if flag == 1 then
                useItem["offset"] = true
            elseif flag == 2 then
                useItem["addbar"] = true
            elseif flag == 3 then
                useItem["addGain"] = true
            end
        end

        local function tableToString(tbl)
            local result = "{\n"  
            for k, v in pairs(tbl) do
                result = result .. "  " .. tostring(k) .. " = " .. tostring(v) .. ",\n"
            end
            result = result:sub(1, -3) .. "\n}"
            return result
        end
     
        for _,v in pairs (UsingItems) do
            setUseItem(v)
        end
       
        data["#gloryhole_useitem"] = tableToString(useItem)
        data["#gloryhole_score"] = 0
        TapDBManager.trackEvent("#event_gloryhole_pratice",json.encode(data))
    end
     --NodeHelper:setStringForLabel(container, {mHightScore = MaxScore})
     --NodeHelper:setNodesVisible(container, {mHightScoreNode = true, mResultBestScore = true})
    NodeHelper:setStringForLabel(container,{mDecisionTitle=common:getLanguageString("@Leave"),mDecisionTex=common:getLanguageString("@LeaveHint")})
    NodeHelper:setMenuItemImage(container,{ mPauseBtn = {normal = "Gloryhole_Bar_btn01.png"}})
    NodeHelper:setNodesVisible(SelfContainer,{mComboEvent=false})
    NodeHelper:setSpriteImage(container,{mFrontSprite = "BG/UI/GloryHole_001_A.jpg"})
     if string.find(MainSpineName,"A") then
         NodeHelper:setNodesVisible(container,{mFrontSprite = true , mBackSprite = false})
     else
         NodeHelper:setNodesVisible(container,{mFrontSprite = false , mBackSprite = true})
     end

    local layer = container:getVarNode("mNotTouch")
    if not layer then
        layer = CCLayer:create()
        layer:setTag(100001)
        container:addChild(layer)
        layer:setContentSize(CCEGLView:sharedOpenGLView():getDesignResolutionSize())
        layer:registerScriptTouchHandler( function(eventName, pTouch)
            if eventName == "began" then
                GloryHole_PlayBase:onGameTap()
            elseif eventName == "moved" then

            elseif eventName == "ended" then
              
            elseif eventName == "cancelled" then

            end
        end
        , false, -129, false)
        layer:setTouchEnabled(true)
        layer:setVisible(true)
    end
end
function GloryHole_PlayBase:SetItemEffect(container)
    local VisibleMap = { }
    if UsingItems[1] == nil and UsingItems[2] == nil then
        VisibleMap["mUsingItem"] = false
    else
        VisibleMap["mUsingItem"] = true
    end
    ItemParentNode:removeAllChildren()
    VisibleMap["mDefendEvent"] = false
    VisibleMap["mDoubleEvent"] = false
    local idx = 1
    for k, v in pairs(UsingItems) do
        if v == 1 then
            ItemEffect.PerfectEffect = true
            ItemEffect.PerfectCount = 10
            VisibleMap["mDefendEvent"] = true
            NodeHelper:setStringForLabel(container, {mDefendCount = ItemEffect.PerfectCount})
        elseif v == 2 then
            ItemEffect.FeverBar = true
            scoreForFever = FEVER_TIME_SCORE * ItemEffect.FeverBarProgess
         
        elseif v == 3 then
            ItemEffect.DoubleGrade = true
            ItemEffect.DoubleGradeTime = 10
            --ItemEffect.DoubleOriginHeight = container:getVarNode("mDoubleEvent"):getContentSize().height
            --ItemEffect.DoubleOriginWidth = container:getVarNode("mDoubleEvent"):getContentSize().width
        end
       
        ChildNode[v] = ScriptContentBase:create(ItemCCB[v])
        ItemParentNode:addChild(ChildNode[v])

        local posX = (idx == 1) and -70 or 17
        ChildNode[v]:setPosition(ccp(posX, -5.9))

        idx = idx + 1
    end
     NodeHelper:setNodesVisible(container,VisibleMap)
end
function GloryHole_PlayBase:InitExplosionSpine()
    ExplosionNode = SelfContainer:getVarNode("mExplosion")
    local ExplosionSpineName = "GloryHole_UI_Click"
    ExplosionSpine = SpineContainer:create("Spine/Gloryhole", ExplosionSpineName)
    local ExplosionSpineNode = tolua.cast(ExplosionSpine, "CCNode")
    ExplosionSpineNode:setScale(0.5)
    ExplosionNode:addChild(ExplosionSpineNode)
    ExplosionSpine:runAnimation(1, "animation", 0)
end
function GloryHole_PlayBase:SetClipNode(container)
    mClippingNode = container:getVarNode("mSpineMask")
    if mClippingNode then
        mClippingNode = tolua.cast(mClippingNode, 'CCClippingNode')
    end
end
function GloryHole_PlayBase:setOtherAnim(container)
    --AddPointNode
    AddPointParent = container:getVarNode("mAddPoint")
    AddPointParent:setScale(0.8)
    AddPointCCB = ScriptContentBase:create("GloryHole_Play_AddPoint")
    AddPointParent:addChild(AddPointCCB)
    --FeverTimeNode
    local FeverBarParent = container:getVarNode("mFeverSpine")
    FeverBarParent:setPosition(ccp(-220, -20))
    local originX = FeverBarParent:getPositionX()
    local FeverSpineName = "NGUI_84_GloryHoleBar"
    local FeverSpine = SpineContainer:create("Spine/Gloryhole", FeverSpineName)
    local FeverSpineNode = tolua.cast(FeverSpine, "CCNode")
    FeverBarParent:addChild(FeverSpineNode)
    FeverSpine:runAnimation(1, "animation", -1)
    for i = 1, 12 do
        NodeHelper:setNodesVisible(container, {["mFeverBar" .. string.format("%02d", i)] = false})
    end
end
function GloryHole_PlayBase:setCountDownSpine(container)
    NodeHelper:setNodesVisible(SelfContainer, {mCountDown = true})
    local parent = container:getVarNode("mCountDownSpine")
    local SpineName2 = "GloryHole_UI_countdown"
    Spine = SpineContainer:create("Spine/Gloryhole", SpineName2)
    spineNode = tolua.cast(Spine, "CCNode")
    Spine:registerFunctionHandler("COMPLETE", GloryHole_PlayBase.onFunction)
    parent:addChild(spineNode)
    Spine:runAnimation(1, "animation", 0)
    local layer = container:getVarNode("mCountDownBlack")
    if layer then
        layer:setOpacity(255)  -- 初始透明度 255（完全不透明）
    
        --等待 2 秒
        local delay = CCDelayTime:create(2.0)
    
        -- 淡出，3 秒
        local fadeOut = CCFadeOut:create(3.0)
    
        local sequence = CCSequence:createWithTwoActions(delay, fadeOut)
    
        layer:runAction(sequence)
    end

end
function GloryHole_PlayBase:setCountDownSpine2(container)
    if isCountingDown then return end
    isCountingDown = true
    local array = CCArray:create()
    local parent = container:getVarNode("mCountDownSpine2")
    local SpineName3 = "GloryHole_UI_countdown"
    local EndSpine = SpineContainer:create("Spine/Gloryhole", SpineName3)
    local EndspineNode = tolua.cast(EndSpine, "CCNode")
    local Ani = CCCallFunc:create(function()
        parent:addChild(EndspineNode)
        EndSpine:runAnimation(1, "animation2", -1)
    end)
    local clear = CCCallFunc:create(function()
        parent:removeAllChildrenWithCleanup(true)
        container:stopAllActions()
    end)
    array:addObject(Ani)
    array:addObject(CCDelayTime:create(2))
    array:addObject(clear)
    container:runAction(CCSequence:create(array))
end
function GloryHole_PlayBase:setSpine(container)
    nowMovePassedTime = 0
    nowTableIdx = math.ceil(math.random(1, 5))
    MoveTable = common:split(WholeTable[nowTableIdx], ",")[AnimIdx]
    parentNode:removeAllChildrenWithCleanup(true)
    Spine = SpineContainer:create(MainSpinePath, MainSpineName)
    spineNode = tolua.cast(Spine, "CCNode")
    Spine:registerFunctionHandler("COMPLETE", GloryHole_PlayBase.onFunction)
    spineNode:setScale(SpineScale or 1)
    parentNode:addChild(spineNode)
    Spine:runAnimation(1, MoveTable, 0)

    GloryHole_PlayBase:PlayEffectTable(container,MoveTable)

    GloryHole_PlayBase:BarMoving(container)
end
function GloryHole_PlayBase:PlayEffectTable(container, MoveTable)
    local EffectTable = common:split(Eff[MoveTable], ";")  -- 分割音效列表
    local array = CCArray:create()  -- 建立一個統一的動作陣列

    -- 從音效檔名中提取秒數和檔案名稱
    local function getDurationAndNameFromFilename(name)
        local parts = common:split(name, ",")  -- 分割出時間和檔案名稱部分
        return tonumber(parts[1]) or 0, parts[2] or ""  -- 若解析失敗則回傳 0 秒和空字串
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

function GloryHole_PlayBase:BarMoving(container)
    local LittleBar = container:getVarNode("mLittleBar")
    local array = CCArray:create()
    local Tmptable = {}
    if MoveTable == "A" then
        Tmptable =  common:split(Animation_A_Data,",")
    elseif MoveTable == "B" then
        Tmptable =  common:split(Animation_B_Data,",")
    end
    for _, value in pairs(Tmptable) do
        local frame=common:split(value,"_")
        array:addObject(CCCallFunc:create(function()GloryHole_PlayBase:RandBarMode(container) end))
        array:addObject(CCCallFunc:create(function()
            CanTap = true
            NodeHelper:setNodesVisible(container, {mGray = false})
            nowMove = nowMove + 1
        end))
        array:addObject(CCMoveTo:create(tonumber(frame[1]) / 30 , ccp(-20, Top_PosY)))
        array:addObject(CCCallFunc:create(function()Moving = "Up" end))
        array:addObject(CCMoveTo:create(tonumber(frame[2]) / 30 , ccp(-20, Bottom_PosY)))
        array:addObject(CCCallFunc:create(function()Moving = "Down" end))
        array:addObject(CCCallFunc:create(function()nowMovePassedTime = 0 end))
    end
    LittleBar:runAction(CCSequence:create(array))
end
function GloryHole_PlayBase.onFunction(tag, idx, eventName)
    if eventName == "COMPLETE" then
        --Anim
       AnimIdx = AnimIdx + 1
        if AnimIdx == 1 then
            if ChildNode[2] then
                GloryHole_PlayBase:PlayFeverAnim()
            end
            SoundManager:getInstance():playMusic(BGM, true)
            GloryHole_PlayBase:setSpine(SelfContainer)
            NodeHelper:setNodesVisible(SelfContainer, {mCountDown = false})
            SelfContainer:runAnimation("Fever Time")
            return
        end
        MoveTable = common:split(WholeTable[nowTableIdx], ",")[AnimIdx]
        if not MoveTable then
            if PlayMode == "Play" then
                NodeHelper:setNodesVisible(SelfContainer, {mResult = false,mResult2 = true})
            else
                NodeHelper:setNodesVisible(SelfContainer, {mResult = true , mResult2 = false})
            end
            local StringTable={}
            StringTable["mMaxCombo"]=MaxCombo
            StringTable["mPerfectCount"]=PerfectTimes
            StringTable["mFeverCount"]=FeverActiveTimes
            StringTable["mMaxCombo_Play"]=MaxCombo
            StringTable["mPerfectCount_Play"]=PerfectTimes
            StringTable["mFeverCount_Play"]=FeverActiveTimes
            if PlayMode~="Play" then
                StringTable["mResultBestScore"]="---"
            end
            NodeHelper:setStringForLabel(SelfContainer,StringTable)
            return
        end
        Spine:runAnimation(1, MoveTable, 0)
        GloryHole_PlayBase:PlayEffectTable(SelfContainer,MoveTable)
        --BarMove
        nowMove = 1
        if MoveTable == "D" then
            if PlayMode == "Play" and TotalScore>0 then
                local Activity5_pb = require("Activity5_pb")
                local msg = Activity5_pb.GloryHoleReq()
                msg.action = 4
                msg.newScore = TotalScore
                msg.gameStatus.fanatic=FeverActiveTimes
                msg.gameStatus.good=PerfectTimes
                common:sendPacket(HP_pb.ACTIVITY175_GLORY_HOLE_C, msg, true)
            end
            return
        end
        local LittleBar = SelfContainer:getVarNode("mLittleBar")
        local array = CCArray:create()
        local Tmptable = {}
        if MoveTable == "A" then
            Tmptable =  common:split(Animation_A_Data,",")
        elseif MoveTable == "B" then
            Tmptable =  common:split(Animation_B_Data,",")
        end

        for _, value in pairs(Tmptable) do
            local frame=common:split(value,"_")
            array:addObject(CCCallFunc:create(function() if CanTap then 
                                                            ComboCount = 0 
                                                            NodeHelper:setNodesVisible(SelfContainer,{mComboEvent=false})
                                                            NodeHelper:setStringForLabel(SelfContainer,{mComboCount=ComboCount})
                                                         end end))
            array:addObject(CCCallFunc:create(function()GloryHole_PlayBase:RandBarMode(SelfContainer) end))
            array:addObject(CCCallFunc:create(function()
                CanTap = true
                NodeHelper:setNodesVisible(SelfContainer, {mGray = false})
                nowMove = nowMove + 1
            end))
            array:addObject(CCCallFunc:create(function()Moving = "Up" end))
            array:addObject(CCMoveTo:create(tonumber(frame[1]) / 30, ccp(-20, Top_PosY)))
            array:addObject(CCCallFunc:create(function()Moving = "Down" end))
            array:addObject(CCMoveTo:create(tonumber(frame[2])  / 30, ccp(-20, Bottom_PosY)))
            array:addObject(CCCallFunc:create(function()nowMovePassedTime = 0 end))
        
        end
        LittleBar:runAction(CCSequence:create(array))
    end
end
function GloryHole_PlayBase:RandBarMode(container)
    local Num = math.random(1, 100)
    if Num <= 100 then
        BarMode = 1
        NodeHelper:setNodesVisible(container, {mBarMode1 = true, mBarMode2 = false, mBarMode3 = false})
    --elseif Num<=200 then
    --    BarMode=2
    --    NodeHelper:setNodesVisible(container,{ mBarMode1=false, mBarMode2=true, mBarMode3=false })
    --elseif Num<=300 then
    --    BarMode=3
    --    NodeHelper:setNodesVisible(container,{ mBarMode1=false, mBarMode2=false, mBarMode3=true })
    end
end
function GloryHole_PlayBase:onCancel(container)
    if PlayMode == "Play" then
        isPause = false
        NodeHelper:setNodesVisible(container, {mPause = false})
    else
        Spine:setTimeScale(1)
        isPause = false
        MoveTable = common:split(WholeTable[nowTableIdx], ",")[AnimIdx]
        if not MoveTable then return end
        --BarMove
        local LittleBar = SelfContainer:getVarNode("mLittleBar")
        local array = CCArray:create()
        local Tmptable = {}
        if MoveTable == "A" then
            Tmptable = common:split(Animation_A_Data,",")
        elseif MoveTable == "B" then
            Tmptable =  common:split(Animation_B_Data,",")
        end
        local isFirst = true
        for i = nowMove, #Tmptable do
            if not isFirst then
                array:addObject(CCCallFunc:create(function()
                    CanTap = true
                    NodeHelper:setNodesVisible(SelfContainer, {mGray = false})
                    nowMove = nowMove + 1
                end))
            end
            if Moving == "Down" and isFirst then
                isFirst = false
                local nowPos = LittleBar:getPositionY()
                array:addObject(CCMoveTo:create(tonumber(common:split(Tmptable[i],"_")[2] )/ 30 - nowMovePassedTime, ccp(-20, Bottom_PosY)))
                array:addObject(CCCallFunc:create(function()nowMovePassedTime = 0 end))
            else
                array:addObject(CCCallFunc:create(function()Moving = "Up" end))
                if isFirst then
                    array:addObject(CCMoveTo:create(tonumber(common:split(Tmptable[i],"_")[1] )/ 30 - nowMovePassedTime, ccp(-20, Top_PosY)))
                    isFirst = false
                else
                    array:addObject(CCMoveTo:create(tonumber(common:split(Tmptable[i],"_")[2] )/ 30, ccp(-20, Top_PosY)))
                end
                array:addObject(CCCallFunc:create(function()Moving = "Down" end))
                array:addObject(CCMoveTo:create(tonumber(common:split(Tmptable[i],"_")[1] )/ 30, ccp(-20, Bottom_PosY)))
                array:addObject(CCCallFunc:create(function()nowMovePassedTime = 0 end))
            end
        end
        if array then
            LittleBar:runAction(CCSequence:create(array))
        end
        NodeHelper:setNodesVisible(container, {mPause = false})
    end
end

function GloryHole_PlayBase:setData( mode, maxGrade, items, PlayData)
    local _Path,_Name= unpack(common:split(PlayData.Spine,","))
    MainSpinePath=_Path
    MainSpineName = _Name
    PlayMode = mode
    MaxScore = maxGrade or 0
    UsingItems = items
    Animation_A_Data={}
    Animation_B_Data={}
    WholeTable={}
   for _,data in pairs (common:split(PlayData.randomTable,"_")) do
       table.insert(WholeTable,data)
   end
    Animation_A_Data=PlayData.A_frame or {}
    Animation_B_Data=PlayData.B_frame or {}

    Eff["A"]=PlayData.A_Eff
    Eff["B"]=PlayData.B_Eff
    Eff["D"]=PlayData.D_Eff

    GloryHole_PlayBase:PreloadEffect("A")
    GloryHole_PlayBase:PreloadEffect("B")
    GloryHole_PlayBase:PreloadEffect("D")

    BGM=PlayData.BGM  
end

function GloryHole_PlayBase:PreloadEffect(MoveTable)
    -- 透過 MoveTable 從 Eff 中取得音效字串並分割
    local EffectTable = common:split(Eff[MoveTable], ";")  -- 分割音效列表

    -- 從音效檔案名中提取秒數和檔案名稱
    local function getFilename(name)
        local parts = common:split(name, ",")  -- 分割時間和檔案名稱部分
        return parts[2] or ""  -- 回傳檔案名稱，若無則回傳空字串
    end

    -- 遍歷音效表進行預載
    for _, soundFile in ipairs(EffectTable) do
        local filename = getFilename(soundFile)

        if filename ~= "" and NodeHelper:isFileExist("/audio/" .. filename) then
            -- 預載音效進入內存
            print("預載音檔: " .. filename)
            SimpleAudioEngine:sharedEngine():preloadEffect(filename)
        else
            print("音檔不存在或無效: " .. (filename or "未知"))
        end
    end

    print("所有音效預載完成")
end

function GloryHole_PlayBase:onConfirmation(container,isDone)
    if PlayMode=="Play" and not isDone and TotalScore> 0 then
        local Activity5_pb = require("Activity5_pb")
        local msg = Activity5_pb.GloryHoleReq()
        msg.action = 4
        msg.newScore = TotalScore
        msg.gameStatus.fanatic=FeverActiveTimes
        msg.gameStatus.good=PerfectTimes
        common:sendPacket(HP_pb.ACTIVITY175_GLORY_HOLE_C, msg, true)
    end
    SoundManager:getInstance():stopAllEffect() --關閉音效
    SoundManager:getInstance():playGeneralMusic()
    FeverActiveTimes=0
    MaxCombo=0
    PerfectTimes=0
    AnimIdx = 0
    Spine = nil
    spineNode = nil
    SelfContainer = nil
    MoveTable = {}
    CanTap = true
    TotalScore = 0
    tmpScore = 0
    nowMove = 0
    nowMovePassedTime = 0
    scoreForFever = 0
    Moving = ""
    isPause = false
    isCountingDown = false
    ComboCount = 0
    isFeverTime = false
    ItemEffect = {PerfectCount = 10,
    PerfectEffect = false,
    FeverBarProgess = 0.3,
    FeverBar = false,
    DoubleGradeTime = 10,
    DoubleGrade = false}
    container:stopAllActions()
    local Activity5_pb = require("Activity5_pb")
    local msg = Activity5_pb.GloryHoleReq()
    msg.action = 0
    common:sendPacket(HP_pb.ACTIVITY175_GLORY_HOLE_C, msg, true)
    PageManager.popPage(thisPageName)
    require ("GloryHole.GloryHoleSubPage_MainScene")
    GloryHoleBase_refreshPage()
end
function GloryHole_PlayBase:onPause(container)
    if not isPause and PlayMode ~= "Play" then
        --Spine:setTimeScale(0)
        --isPause = true
        --local LittleBar = SelfContainer:getVarNode("mLittleBar")
        --LittleBar:stopAllActions()
        NodeHelper:setNodesVisible(container, {mPause = true})
    else
        isPause = true
        NodeHelper:setNodesVisible(container, {mPause = true})
    end
end
function GloryHole_PlayBase:onExecute(container)
    parentNode:scheduleUpdateWithPriorityLua(function(dt)
        GloryHole_PlayBase:update(dt, container)
    end, 0)
end
function GloryHole_PlayBase:update(dt, container)
    if PlayMode=="Play" then
        nowMovePassedTime = nowMovePassedTime + dt     
    end
     if not isPause and PlayMode~="Play" then
        nowMovePassedTime = nowMovePassedTime + dt
      end
    if tmpScore < TotalScore then
        tmpScore = tmpScore + math.random(1, 100)
    elseif tmpScore > TotalScore then
        tmpScore = TotalScore
    end
    local score = math.floor(tmpScore)
    NodeHelper:setStringForLabel(container, {mScore = score, mResultTxt = score,mResultTxt_Play = score})
    if PlayMode=="Play" then
        if TotalScore > MaxScore  then
            NodeHelper:setStringForLabel(container, {mHightScore = tmpScore, mResultBestScore_Play = tmpScore})
        else
            NodeHelper:setStringForLabel(container, {mHightScore = MaxScore, mResultBestScore_Play = MaxScore})
        end
    end
    if scoreForFever >= FEVER_TIME_SCORE then
        isFeverTime = true
        FeverActiveTimes=FeverActiveTimes+1
        NodeHelper:setNodesVisible(container, {mFeverSpine = true, mFeverSprite = true, mNormalSprite = false, mFeverEv = true})
    end
    if isFeverTime then
        if PlayMode=="Play" then
            FeverPassedTime = FeverPassedTime + dt
        end
        if not isPause and PlayMode~="Play" then
            FeverPassedTime = FeverPassedTime + dt
        end
        scoreForFever = 0
        NodeHelper:setNodesVisible(container, {mFeverSpine = true})
        for i = 1, 12 do
            NodeHelper:setNodesVisible(container, {["mFeverBar" .. string.format("%02d", i)] = false})
        end
    else
        NodeHelper:setNodesVisible(container, {mFeverSpine = false, mFeverSprite = false, mNormalSprite = true, mFeverEv = false})
    end
    if FeverPassedTime >= FEVER_TIME_LONG then
        isFeverTime = false
        scoreForFever = 0
        FeverPassedTime = 0
    end
    if PlayMode=="Play" and AnimIdx > 0 then
        nowLeftTime = nowLeftTime - dt
    end
    if PlayMode~="Play" and not isPause and AnimIdx > 0 then
        nowLeftTime = nowLeftTime - dt
    end
    if nowLeftTime < 0 then
        nowLeftTime = 0
        local LittleBar = SelfContainer:getVarNode("mLittleBar")
        LittleBar:stopAllActions()
        LittleBar:setPositionY(-260)
        NodeHelper:setNodesVisible(container,{mTouchBar = false,mGradeBar=false,mFeverEv = false})
    end
    local str = math.floor(nowLeftTime)
    if nowLeftTime <= 0 and not isCountingDown then
        GloryHole_PlayBase:setCountDownSpine2(SelfContainer)
    end
    NodeHelper:setStringForLabel(container, {mTime = str})
    if PlayMode=="Play" and isFeverTime then
        local nodeCenter = CCNode:create()
        local sprite = CCSprite:create('Gloryhole_Bar_mask.png')
        local passed = FeverPassedTime / FEVER_TIME_LONG
        sprite:setAnchorPoint(ccp(0, 0.5))
        sprite:setScaleX(1 - passed)
        sprite:setPositionX(-220)
        nodeCenter:addChild(sprite)
        nodeCenter:setPosition(ccp(0, 0))
        mClippingNode:setStencil(nodeCenter)
    end
    if PlayMode~="Play" and not isPause and isFeverTime then
        local nodeCenter = CCNode:create()
        local sprite = CCSprite:create('Gloryhole_Bar_mask.png')
        local passed = FeverPassedTime / FEVER_TIME_LONG
        sprite:setAnchorPoint(ccp(0, 0.5))
        sprite:setScaleX(1 - passed)
        sprite:setPositionX(-220)
        nodeCenter:addChild(sprite)
        nodeCenter:setPosition(ccp(0, 0))
        mClippingNode:setStencil(nodeCenter)
    end
    --GradeAnim
    if GetGrade then
        Grade_Opacity = Grade_Opacity + dt * 5
        GradeScale = GradeScale + dt * 5
        if GradeScale > 2.5 or Grade_Opacity >= 255 or tmpScore == TotalScore then
            GetGrade = false
            GradeScale = 1.5
            Grade_Opacity = 100
            container:getVarNode("mScore"):setScale(1.5)
            container:getVarNode("mScore"):setOpacity(255)
            return
        end
        container:getVarNode("mScore"):setScale(GradeScale)
        container:getVarNode("mScore"):setOpacity(Grade_Opacity)
    end
    --DoubleGradeSprite
    if nowLeftTime <= ItemEffect.DoubleGradeTime and ItemEffect.DoubleGrade then
        --NodeHelper:setNodesVisible(container, {mDoubleEvent = true})
        --local scale = nowLeftTime / ItemEffect.DoubleGradeTime or 1
        --if scale > 1 then scale = 1 end
        --local Bar = tolua.cast(container:getVarNode("mDoubleEvent"), "CCScale9Sprite")
        --Bar:setContentSize(CCSize(ItemEffect.DoubleOriginWidth, ItemEffect.DoubleOriginHeight * scale))
        --if nowLeftTime <= 0 then
        --    NodeHelper:setNodesVisible(container, {mDoubleEvent = false})
        --else
        --    NodeHelper:setNodesVisible(container, {mDoubleEvent = true})
        --end
        if not ItemEffect.DoublePlayed then
            ItemEffect.DoublePlayed = true
            GloryHole_PlayBase:PlayDoubleAnim()
        end
         GloryHole_PlayBase:refreshRound(container)
    end
end
function GloryHole_PlayBase:onResultConfirm()
    GloryHole_PlayBase:onConfirmation(SelfContainer,true)
end
function GloryHole_PlayBase:onGameTap()
    if not CanTap or isPause or nowLeftTime <= 0 then return end
    CanTap = false
    NodeHelper:setNodesVisible(SelfContainer, {mGray = true})
    local LittleBar = SelfContainer:getVarNode("mLittleBar")
    local nowBarPos = LittleBar:getPositionY()
    local LocatePercentage = (nowBarPos - Bottom_PosY) / (Top_PosY - Bottom_PosY)
    local ScoreWeighted = isFeverTime and FEVER_PERCENT or 1
    ExplosionNode:setPosition(LittleBar:getPosition())
    ExplosionSpine:runAnimation(1, "animation", 0)
    function updateScore(scoreType, isTransfer)
        local _isTrans = false
        local ComboValue=0
        if scoreType == "Perfect" then
            ComboCount = ComboCount + 1
            PerfectTimes=PerfectTimes+1
            if ComboCount>MaxCombo then
                MaxCombo=ComboCount
            end
            for key,value in pairs (ComboInfo) do
                if ComboCount>=tonumber(key) then
                    ComboValue=value
                end
            end
        else
            ComboCount = 0
        end
        if ComboCount > 1 then
            NodeHelper:setNodesVisible(SelfContainer, {mComboEvent = true})
            NodeHelper:setStringForLabel(SelfContainer, {mComboCount = ComboCount})
        else
            NodeHelper:setNodesVisible(SelfContainer, {mComboEvent = false})
        end
        if isTransfer ~= nil then _isTrans = isTransfer end
        local DoubleGrade = 1
        local isDouble = false
        if nowLeftTime <= ItemEffect.DoubleGradeTime and ItemEffect.DoubleGrade then
            DoubleGrade = 2
            isDouble = true
        end
        TotalScore = TotalScore + (Scores[scoreType]+ComboValue)* ScoreWeighted * DoubleGrade
        scoreForFever = scoreForFever + Scores[scoreType] * DoubleGrade
        local visibility = {mPerfect = false, mGreat = false, mGood = false, mNumLabel = true, mDouble = isDouble,mItem4=isDouble, mTransfer = _isTrans,mItem1 = _isTrans }
        if isDouble then
            GloryHole_PlayBase:PlayDoubleAnim()
        end
        if _isTrans then
            GloryHole_PlayBase:PlayDefendAnim()
        end
        visibility["m" .. scoreType] = true
        NodeHelper:setNodesVisible(AddPointCCB, visibility)
        NodeHelper:setStringForLabel(AddPointCCB, {mNumLabel = "+" .. (Scores[scoreType]+ComboValue) * ScoreWeighted})
        AddPointCCB:runAnimation("showNum_Add")
        GetGrade = true
    end
    
    if BarMode == 1 then
        if LocatePercentage <= 0.4 then
            if ItemEffect.PerfectEffect and ItemEffect.PerfectCount > 0 then
                updateScore("Perfect", true)
                ItemEffect.PerfectCount = ItemEffect.PerfectCount - 1
            else
                updateScore("Good")
            end
        elseif LocatePercentage <= 0.7 then
            if ItemEffect.PerfectEffect and ItemEffect.PerfectCount > 0 then
                updateScore("Perfect", true)
                ItemEffect.PerfectCount = ItemEffect.PerfectCount - 1
            else
                updateScore("Great")
            end
        else
            updateScore("Perfect")
        end
    
    --elseif BarMode == 2 then
    --    if LocatePercentage <= 0.15 then
    --        updateScore("Good")
    --    elseif LocatePercentage <= 0.35 then
    --        updateScore("Great")
    --    elseif LocatePercentage <= 0.65 then
    --        updateScore("Perfect")
    --    elseif LocatePercentage <= 0.85 then
    --        updateScore("Great")
    --    else
    --        updateScore("Good")
    --    end
    --elseif BarMode == 3 then
    --    if LocatePercentage <= 0.4 then
    --        updateScore("Perfect")
    --    elseif LocatePercentage <= 0.7 then
    --        updateScore("Great")
    --    else
    --        updateScore("Good")
    --    end
    end
    NodeHelper:setStringForLabel(SelfContainer, {mDefendCount = ItemEffect.PerfectCount})
    if ItemEffect.PerfectCount <= 0 then
        NodeHelper:setNodesVisible(SelfContainer, {mDefendEvent = false})
    end
    for i = 1, 12 do
        NodeHelper:setNodesVisible(SelfContainer, {["mFeverBar" .. string.format("%02d", i)] = scoreForFever >= (FEVER_TIME_SCORE / 12) * i})
    end
    if TotalScore < RankRule.C then
        NodeHelper:setSpriteImage(SelfContainer, {mBarRank = RankImg.C, mResultRank = RankImg.C,mResultRank_Play = RankImg.C})
    elseif TotalScore < RankRule.B then
        NodeHelper:setSpriteImage(SelfContainer, {mBarRank = RankImg.B, mResultRank = RankImg.B, mResultRank_Play = RankImg.B})
    elseif TotalScore < RankRule.A then
        NodeHelper:setSpriteImage(SelfContainer, {mBarRank = RankImg.A, mResultRank = RankImg.A, mResultRank_Play = RankImg.A})
    else
        NodeHelper:setSpriteImage(SelfContainer, {mBarRank = RankImg.S, mResultRank = RankImg.S, mResultRank_Play = RankImg.S})
    end
end
function GloryHole_PlayBase:PlayDefendAnim()
    if not ChildNode[1] then return end
    local Array = CCArray:create() 
    local TurnOn = CCCallFuncN:create( function()
         ChildNode[1]:runAnimation("TurnOn")
    end )
    local TurnOff = CCCallFuncN:create( function()
         ChildNode[1]:runAnimation("TurnOff")
    end )
    if ItemEffect.PerfectCount >0  then
        Array:addObject(TurnOn)
    else
        Array:addObject(TurnOff)
    end
    SelfContainer:runAction(CCSequence:create(Array))
end
function GloryHole_PlayBase:PlayFeverAnim()
    local Array = CCArray:create() 
    local TurnOn = CCCallFuncN:create( function()
         ChildNode[2]:runAnimation("TurnOn")
    end )
    local TurnOff = CCCallFuncN:create( function()
         ChildNode[2]:runAnimation("TurnOff")
    end )
    Array:addObject(TurnOn)
    Array:addObject(CCDelayTime:create(0.1))
    for i = 1, 12 do
        local Fun = CCCallFuncN:create( function()
            NodeHelper:setNodesVisible(SelfContainer, {["mFeverBar" .. string.format("%02d", i)] = scoreForFever >= (FEVER_TIME_SCORE / 12) * i})
        end )
        Array:addObject(Fun)
        Array:addObject(CCDelayTime:create(0.1))
    end
    Array:addObject(TurnOff)
    local FeverSequence = CCSequence:create(Array)
    SelfContainer:runAction(FeverSequence)
end
function GloryHole_PlayBase:PlayDoubleAnim()
    if not ChildNode[3] then return end
    local Array = CCArray:create() 
    local TurnOn = CCCallFuncN:create( function()
         ChildNode[3]:runAnimation("TurnOn")
    end )
    local TurnOff = CCCallFuncN:create( function()
         ChildNode[3]:runAnimation("TurnOff")
    end )
    if nowLeftTime <= ItemEffect.DoubleGradeTime and ItemEffect.DoubleGrade then
       Array:addObject(TurnOn)
    end
    if nowLeftTime <=0.3 then
         Array:addObject(TurnOff)
    end
    if nowLeftTime <= ItemEffect.DoubleGradeTime and ItemEffect.DoubleGrade then
        SelfContainer:runAction(CCSequence:create(Array))
    end
end
function GloryHole_PlayBase:refreshRound(container)
    local barNode = ChildNode[3]:getVarNode("mRoundNode")

    if not barNode:getChildByTag(999) then
        local bg = CCSprite:create("GloryHole_img_25_02.png")
        local bar = CCProgressTimer:create(bg)
        bar:setTag(999) 
        barNode:addChild(bar)
        bar:setPosition(ccp(0, 0))
        bar:setType(kCCProgressTimerTypeRadial)
        bar:setMidpoint(ccp(0.5, 0.5))
        bar:setReverseDirection(true) 
    end

    -- 更新?度?百分比
    local bar = barNode:getChildByTag(999)
    local scale = (nowLeftTime / ItemEffect.DoubleGradeTime) or 0
    bar:setPercentage(scale * 100)
    
    -- 如果有??持??少，?持?更新?度?
    if nowLeftTime < 0 then
        barNode:removeAllChildren()
    end
end

function GloryHole_PlayBase:setRewardData(data)
    self.rewardItems = data
    NodeHelper:initScrollView(SelfContainer, "mReward_Play", #self.rewardItems);
    self:updateItems()
end

function GloryHole_PlayBase:updateItems()
	local size = #self.rewardItems
		
	local colMax = 3

	local options = {
		-- magic layout number 
		-- 因為CommonRewardContent尺寸異常，導致各使用處需要自行處理
		interval = ccp(0, 0),
		colMax = colMax,
		paddingTop = 0,
		paddingBottom = 0,
		originScrollViewSize = CCSizeMake(500, 150),
		isDisableTouchWhenNotFull = true
	}

	-- 未滿 1行 則 橫向置中
	if size < colMax then
		options.isAlignCenterHorizontal = true
	end
	
	-- 未達 2行 則 垂直置中
	if size <= colMax then
		options.isAlignCenterVertical = true
		options.startOffset = ccp(0, 0)
	-- 達到 2行 則 偏移在首項 並 偏移paddingTop
	else
		options.startOffsetAtItemIdx = 1
		options.startOffset = ccp(0, -options.paddingTop)
	end

	--[[ 滾動視圖 左上至右下 ]]
	NodeHelperUZ:buildScrollViewGrid_LT2RB(
		SelfContainer,
		size,
		"CommonRewardContent.ccbi",
		function (eventName, container)
			self:onScrollViewFunction(eventName, container)
		end,
		options
	)
			
	-- 顯示/隱藏 列表 或 無獎勵提示
	NodeHelper:setNodesVisible(SelfContainer, {
		mContent = size ~= 0
	})
	
	-- 若 數量 尚未超過 每行數量 的話
	if size <= colMax  then
		local node = SelfContainer:getVarNode("mReward_Play")
		node:setTouchEnabled(false)
	end
end

--[[ 滾動視圖 功能窗口 ]]
function GloryHole_PlayBase:onScrollViewFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		--- 每?子空??建的?候??用??函?
		local contentId = container:getItemDate().mID;
		-- ?取到?第几行
		local idx = contentId
		-- ?取?前的index      i是每行的第几? 用??取?件用的
		local node = container:getVarNode("mItem")
		local itemNode = ScriptContentBase:create('GoodsItem.ccbi')

		local itemData = self.rewardItems[idx]
		local resInfo = ResManager:getResInfoByTypeAndId(itemData and itemData.type or 30000, itemData and itemData.itemId or 104001, itemData and itemData.count or 1);
		--NodeHelper:setStringForLabel(itemNode, { mName = "" });
		local numStr = ""
		if resInfo.count > 0 then
			numStr = tostring(resInfo.count)
		end
		local lb2Str = {
			mNumber = numStr
		};
		local showName = "";
		if itemData and itemData.type == 30000 then
			showName = ItemManager:getShowNameById(itemData.itemId)
		else
			showName = resInfo.name           
		end
		NodeHelper:setNodesVisible(itemNode, { m2Percent = false, m5Percent = false });

		if itemData.type == 40000 then
			for i = 1, 6 do
				NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.quality })
			end
		end
		NodeHelper:setNodesVisible(itemNode, { mStarNode = itemData.type == 40000 })
		
		--NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.BlurryLineWidth - 10, 4)
		NodeHelper:setStringForLabel(itemNode, lb2Str);
		NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = 1 });
		NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality });
		NodeHelper:setColorForLabel(itemNode, { mName = ConfigManager.getQualityColor()[resInfo.quality].textColor })
		NodeHelper:setNodesVisible(itemNode, { mName = false})

		node:addChild(itemNode);
		itemNode:registerFunctionHandler(function (eventName, container)
			if eventName == "onHand" then
				local id = container.id
				GameUtil:showTip(container:getVarNode("mHand"), self.rewardItems[id])
			end  
		end)
		itemNode.id = contentId
	end
end

local CommonPage = require("CommonPage")
local GloryHole_PlayPage = CommonPage.newSub(GloryHole_PlayBase, thisPageName, option)

return GloryHole_PlayPage
