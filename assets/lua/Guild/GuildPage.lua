

registerScriptPage('GuildSearchPopPage')
-- registerScriptPage('GuildRankingPage')
registerScriptPage('GuildRankManage')
registerScriptPage('GuildCreatePage')
registerScriptPage('GuildShopPage')
registerScriptPage('GuildMembersPage')
registerScriptPage('GuildManagePage')
registerScriptPage('GuildBossHarmRankPage')
registerScriptPage('GuildOpenBossConfirmPage')

local alliance = require('Alliance_pb')
local hp = require('HP_pb')
local player = require('Player_pb')
local WorldBoss_pb = require("WorldBoss_pb")
local GVGManager = require("GVGManager")
local NodeHelper = require("NodeHelper")
local NewbieGuideManager = require("Guide.NewbieGuideManager")
local GuildDataManager = require("Guild.GuildDataManager")
local GuildData = require("Guild.GuildData")
local UserInfo = require("PlayerInfo.UserInfo");
local WorldBossManager = require("PVP.WorldBossManager");
local GVG_pb = require("GroupVsFunction_pb")
local ABRedPoint = true
local isRunMoveAction = false
local inBossPage = false
local refreshTab = { }	-- 存储公会列表中拒绝玩家加入的公会倒计时信息
local isChatJump = false  --是否是聊天跳转过来的
local isReturnChat = false
local option = {
    -- when i don't have a alliance
    ccbiFile = "GuildPage.ccbi",
    -- when i have a alliance
    ccbiWithAlliance = 'GuildPartakePage.ccbi',
    handlerMap =
    {
        -- basic event
        luaInit = "onInit",
        luaLoad = "onLoad",
        luaUnLoad = "onUnload",
        luaExecute = "onExecute",
        luaEnter = "onEnter",
        luaExit = "onExit",
        luaOnAnimationDone = "onAnimationDone",
        luaReceivePacket = "onReceivePacket",
        luaGameMessage = "onReceiveMessage",

        -- ccbi: GuildPage.ccbi ：未加入公会，搜索、创建、加入。
        onRefreshList = 'refreshJoinList',
        onSearchGuild = 'onSearchGuild',
        onEstablishGuild = 'onCreateGuild',
        onGuildContend = 'onGuildRanking',
        onRanking = 'onGuildRanking',
        onHelp = 'onHelp',

        -- ccbi: GuildPartakePage.ccbi ：已加入公会，签到、boss、成员、管理。
        onSignIn = "onSignIn",
        onIntrusion = "onIntrude",
        onContributionExchange = "exchangeContribution",
        onMembers = "showMembers",
        onManage = "onManage",
        onRank = "onRank",
        onReturnBtn = "onReturnBtn",
        onGuildChangeName = "onGuildChangeName",
        onShortList = "onShortList",
        onGVG = "onGVG",
        onGuildBossHurtRank = "onGuildBossHurtRank",
        onGuildBoss = "onGuildBoss",
        onJumpChat = "onJumpChat"  , --跳转聊天

    },
    bossHander =
    {
        onOpenBossIntrusion = "openBoss",
        onInspireIntrusion = 'onInspire',
        onAutoFight = "onAutoFight",
        onContributionRankingIntrusion = 'onContributionRanking',
        -- 魔兽元气图标说明
        onAttributeOpen = "onAttributeOpen"
    },
    BossSubHander =
    {
        onGuildBoss = "onGuildBoss",
        onGuildBossHurtRank = "onGuildBossHurtRank"
    },
    GVESubHander =
    {
        onLookup = "onLookup",
        onGoTo = 'onGoTo',
        onOpen = 'onOpen',
        onAuto = 'onAuto'
    },
    GVGSubHander =
    {
        onGVG = "onGVG",
    },
}
GuildData.GuildPage.IsRequestMsg = false
-----------------------------------------------



local winSize = CCDirector:sharedDirector():getWinSize()
local sizeWidth = winSize.width
local sizeHeight = winSize.height
local disX = sizeWidth / 4
local disY = sizeHeight / 10
local layerDisY = disY
local ccbTab = {
    { ccbiFile = "GVEChoicePageGuildBossContent.ccbi", handler = option.BossSubHander },
    -- {ccbiFile = "GVEChoicePageGVEContent.ccbi", handler =option.GVESubHander},
    { ccbiFile = "GVEChoicePageGVGContent.ccbi", handler = option.GVGSubHander }
}
local roleTable = { }
local PI = math.acos(-1)
local _angle = 0
local _unitAngle = 0
local moveTime = 0.2
local baseScale = 0.75
local _scale = 0.25
local function init()
    local rate = sizeHeight / sizeWidth
    if rate <= 1.333 then
        -- 768*1024
        disY = sizeHeight / 10
        baseScale = 0.6
        _scale = 0.2
        layerDisY = 0
    elseif rate <= 1.5 then
        -- 640*960
        disX = sizeWidth / 3
        disY = sizeHeight / 8
        baseScale = 0.6
        _scale = 0.2
        layerDisY = sizeHeight / 10
    else
        -- 640*1136
        layerDisY = disY
    end
end
local function createCCB(layer)
    for k, tab in ipairs(ccbTab) do
        local spriteContainter = ScriptContentBase:create(tab.ccbiFile)
        spriteContainter:setPosition(ccp(0, 0))
        -- spriteContainter:setScale(0.5)
        if tab.handler then
            spriteContainter:registerFunctionHandler( function(eventName, container)
                local funcName = tab.handler[eventName]
                if funcName and GuildData.GuildPage[funcName] then
                    GuildData.GuildPage[funcName](container, eventName)
                else
                    CCLuaLog('unknown eventName: ' .. tostring(eventName))
                end
            end )
        end
        spriteContainter:setAnchorPoint(ccp(0.5, 0.5))
        spriteContainter:setZOrder(1)
        layer:addChild(spriteContainter)
        roleTable[#roleTable + 1] = spriteContainter
    end
end
local function createFaceTo(moveTime, fadeTo)
    local array = CCArray:create()
    array:addObject(CCFadeTo:create(moveTime, fadeTo))
    return array
end
local function updatePosition(runAction)
    if runAction then
        for i, spriteContainter in ipairs(roleTable) do
            spriteContainter:stopAllActions()
        end
    end
    for i, spriteContainter in ipairs(roleTable) do
        local index = i - 1
        local x = disX * math.sin(index * _unitAngle + _angle)
        local y = 0 - disY * math.cos(index * _unitAngle + _angle)
        local fadeTo = 192 + 63 * math.cos(index * _unitAngle + _angle)
        local scaleTo = baseScale + _scale * math.cos(index * _unitAngle + _angle)
        local zordetTo = 0 - math.floor(y)
        if runAction then
            local array = CCArray:create()
            array:addObject(CCMoveTo:create(moveTime, ccp(x, y)))
            -- array:addObject(CCFadeTo:create(moveTime,fadeTo))
            spriteContainter:setOpacity(fadeTo)
            array:addObject(CCScaleTo:create(moveTime, scaleTo))
            spriteContainter:setZOrder(zordetTo)
            spriteContainter:runAction(CCSpawn:create(array))
        else
            spriteContainter:setPosition(ccp(x, y))
            spriteContainter:setZOrder(zordetTo)
            spriteContainter:setOpacity(fadeTo)
            spriteContainter:setScale(scaleTo)
        end
    end
end
local function resetAngle(forward)
    local angle = _angle

    if forward then
        angle = math.ceil(angle / _unitAngle - 0.1) * _unitAngle
    else
        angle = math.floor(angle / _unitAngle + 0.1) * _unitAngle
    end
    _angle = angle
end
local function disToAngle(dis)
    local width = sizeWidth / 2
    return dis / width * _unitAngle
end
local roleId = {
    [1] = 4,
    [2] = 5,
    [3] = 6
};
local function getIndex()
    local index = math.floor((2 * PI - _angle) / _unitAngle)
    index = math.fmod(index, #roleTable)
    -- selectedRoleName = mRoleName[g_RoleId]
    return index
end

function GuildData.GuildPage.addSubCCB(container)
    init()
    local layer = CCLayer:create()
    layer:setTag(51001)

    layer:setContentSize(CCSize(sizeWidth, sizeHeight))
    local x = GuildData.GuildPage.mSubNode:getPositionX()
    local y = GuildData.GuildPage.mSubNode:getPositionY() + layerDisY
    layer:setPosition(ccp(x, y))
    layer:setAnchorPoint(ccp(0.5, 0.5))

    layer:setTouchEnabled(true)

    -- createCCB(layer)
    -- _unitAngle = (2 * PI / #roleTable)

    -- updatePosition()
    -- getIndex()
    -- GuildData.GuildPage.showDescription(container,g_RoleId)

    local m_BegainX, m_BegainY = 0, 0
    layer:registerScriptTouchHandler( function(eventName, pTouch)
        if eventName == "began" then
            local point = pTouch:getLocation()
            -- point = layer:getParent():convertToNodeSpace(point)
            m_BegainX = point.x
            m_BegainY = point.y
        elseif eventName == "moved" then
            local angle = disToAngle(pTouch:getDelta().x)
            _angle = _angle + angle
            updatePosition()
        elseif eventName == "ended" then
            local point = pTouch:getLocation()
            local moveDisX = point.x - m_BegainX
            local moveDisY = point.y - m_BegainY
            print("moveDisX = ", moveDisX)
            resetAngle(moveDisX > 0)
            updatePosition(true)
            getIndex()
            -- GuildData.GuildPage.showDescription(container,g_RoleId)
        elseif eventName == "cancelled" then

        end
    end
    , false, 0, false)

    -- GuildData.GuildPage.mSubNode:addChild(layer)
end

function GuildData.GuildPage.refreshWorldBoss()
    if not GuildData.GuildPage.mSubNode then return end
    local container = roleTable[2]
    if container and #WorldBossManager.StartTime == 2 then
        -- 显示时间
        -- 秒转化成小时
        time1 = tonumber(WorldBossManager.StartTime[1]) / 1000
        time2 = tonumber(WorldBossManager.StartTime[2]) / 1000

        local timeStr1 = os.date("%H:%M", time1)
        local timeStr2 = os.date("%H:%M", time2)

        local TimeStr = common:getLanguageString("@GVEOpeningTimeTxt", timeStr1, timeStr2)

        local lb2Str = {
            mGVEOpenTime1 = TimeStr
        }
        NodeHelper:setStringForLabel(container, lb2Str);
        local state = WorldBossManager.BossState
        NodeHelper:setNodesVisible(container, {
            mAutoBtnNode = state == 1,
            mOpenBtnNode = state == 3,
            mGotoBtnNode = state == 3,
            mLookupBtnNode = state == 1,
        } )


    end
end

function GuildData.GuildPage.onLeft(container)
    _angle = _angle + _unitAngle
    resetAngle(1)
    updatePosition(true)
    getIndex()
    -- GuildData.GuildPage.showDescription(container,g_RoleId)
end

function GuildData.GuildPage.onRight(container)
    _angle = _angle - _unitAngle
    resetAngle(-1)
    updatePosition(true)
    getIndex()
    -- GuildData.GuildPage.showDescription(container,g_RoleId)
end

function GuildData.GuildPage.onGVG(container, eventName)
    --GVGManager.isGVGPageOpen = true
    GVGManager.setFromPage("GuildPage")
    GVGManager.reqGuildInfo()
    GVGManager.isGVGPageOpen = true
    -- PageManager.changePage("GVGMapPage")
    -- PageManager.refreshPage("GVGMapPage", "onMapInfo")
end


function GuildData.GuildPage.onGuildBoss(container, eventName)
    --GuildData.GuildPage.showBossPage(true)
    --NodeHelper:setNodesVisible(GuildData.allianceContainer,{mItemContentNode = false})
    require("GuildBossPage")
    GuildBossPage_setServerData(GuildData.allianceInfo.commonInfo)
    PageManager.pushPage("GuildBossPage")
end
 --跳转聊天
function GuildData.GuildPage.onJumpChat(container,eventName)
    hasNewMemberChatComing = false
    NodeHelper:setNodesVisible(GuildData.allianceContainer,{mNewPoint = hasNewMemberChatComing})
    require("Chat.ChatPage")
    PageManager.pushPage("ChatPage")
    resetMenu("mChatBtn", true)
    ChatPage_SetIsGuildJump(true,true)
end

function GuildPage_setIsJump(isJump,isRetCha)
    isChatJump  = isJump
    isReturnChat = isRetCha
end

function GuildData.GuildPage.onGuildBossHurtRank(container, eventName)
    local bossState = GuildData.allianceInfo.commonInfo.bossState or GuildData.BossPage.BossCanInspire
    if GuildData.BossPage.BossNotOpen == bossState then
        MessageBoxPage:Msg_Box('@GuildBossWaitToOpen')
    elseif GuildData.BossPage.BossCanJoin == bossState then
        MessageBoxPage:Msg_Box('@GuildBossPleaseJoin')
    elseif GuildData.BossPage.BossCanInspire == bossState then
        PageManager.pushPage('GuildBossHarmRankPage')
    end
end
function GuildData.GuildPage.onShortList()
    GVGManager.setIsFromRank(true)
    PageManager.pushPage("GVGRankPage")
end

function GuildData.GuildPage.onLookup(container, eventName)
    if WorldBossManager.BossState == 1 then
        if WorldBossManager.isBossDead == true then
            WorldBossManager.enterFinalPageFrom = 2
            PageManager.changePage("WorldBossFinalpage");
        elseif WorldBossManager.isBossDead == false then
            MessageBoxPage:Msg_Box_Lan("@WorldBossNotDie")
        else
            MessageBoxPage:Msg_Box_Lan("@WorldBossFirstStar")
        end
    end
end

function GuildData.GuildPage.onGoTo(container, eventName)
    do
        MessageBoxPage:Msg_Box(common:getLanguageString('@ERRORCODE_25022', GameConfig.WORLDBOSS_OPEN_LEVEL))
        return
    end

    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.WORLDBOSS_OPEN_LEVEL then
        common:sendEmptyPacket(hp.FETCH_WORLD_BOSS_INFO_C, true)
    else
        MessageBoxPage:Msg_Box(common:getLanguageString('@worldBossLimit', GameConfig.WORLDBOSS_OPEN_LEVEL))
    end
end

function GuildData.GuildPage.onOpen(container, eventName)
    MessageBoxPage:Msg_Box(common:getLanguageString("@GVEOpening"))
end



function GuildData.GuildPage.onAuto(container, eventName)
    PageManager.pushPage("GVEAutoFightSelectPage")
end

function GuildData.GuildPage.showBossPage(isShow)
    if GuildData.GuildPage.mSubNode then
        GuildData.GuildPage.mSubNode:setVisible(not isShow)
    end
    print("GuildData.GuildPage.bossNode = ", GuildData.GuildPage.bossNode)
    print("isShow = ", isShow)
    if GuildData.GuildPage.bossNode then
        GuildData.GuildPage.bossNode:setVisible(isShow)
        inBossPage = isShow
    end
end


-- GuildPage页面中的事件处理
----------------------------------------------
function GuildData.GuildPage.onReturnBtn(container)
    print("inBossPage = ", inBossPage)
    if inBossPage  then
        GuildData.GuildPage.showBossPage(false)
        NodeHelper:setNodesVisible(GuildData.allianceContainer,{mItemContentNode = true})
    else
        if isChatJump and isReturnChat  then
            isChatJump = false
            isReturnChat = false
            require("Chat.ChatPage")
            PageManager.pushPage("ChatPage")
            resetMenu("mChatBtn", true)
            ChatPage_SetIsGuildJump(true,false)
        else
            MainFrame_onMainPageBtn()
        end
    end
end

function GuildData.GuildPage.onFunction(eventName, container)
    local funcName = option.handlerMap[eventName]
    if funcName then
        if not GuildData.GuildPage[funcName] then
            GuildData.GuildPage[funcName] = function(container) end
        end
        GuildData.GuildPage[funcName](container, eventName)
    else
        CCLuaLog('In GuildData.GuildPage: unknown function name: ' .. eventName)
    end
end
function GuildData.GuildPage.onUnload(container)
end
function GuildData.GuildPage.onRank(container)
end
function GuildData.GuildPage.onAnimationDone(container)
end

function GuildData.GuildPage.onLoad(container)
    -- 主节点
    GuildData.mainContainer = container
   
    -- '有公会节点'
    GuildData.allianceContainer = ScriptContentBase:create(option.ccbiWithAlliance)
    GuildData.allianceContainer:registerFunctionHandler(GuildData.GuildPage.onFunction)

    GuildData.GuildPage.refreshGVGTime(GuildData.allianceContainer)

    local mScale9Sprite11 = GuildData.allianceContainer:getVarScale9Sprite("mScale9Sprite1")
    if mScale9Sprite11 then
        NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite11)
        -- GuildData.mainContainer:autoAdjustResizeScale9Sprite( mScale9Sprite11 )
    end

   

    local mScale9Sprite22 = GuildData.allianceContainer:getVarScale9Sprite("mScale9Sprite2")
    if mScale9Sprite22 then
--        NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite22)
--        local Height = mScale9Sprite22:getContentSize().height
--        local Width = mScale9Sprite22:getContentSize().width
--        mScale9Sprite22:setContentSize(CCSize(Width, Height + 15))
        NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite22)
        -- GuildData.mainContainer:autoAdjustResizeScale9Sprite( mScale9Sprite22 )
    end

     local mScale9Sprite33 = GuildData.allianceContainer:getVarScale9Sprite("mScale9Sprite3")
    if mScale9Sprite33 then
        NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite33)
        
    end

    local mItemContent = GuildData.allianceContainer:getVarScrollView("mItemContent")
    if mItemContent then
        NodeHelper:autoAdjustResizeScrollview(mItemContent)
        mItemContent:setContentOffset(mItemContent:minContainerOffset())
    end

   
    if NodeHelper:getAdjustBgScale(1) >1  then 
        --联盟界面GVG 九宫格
        local mScale9SpriteBoss = GuildData.allianceContainer:getVarScale9Sprite("mScale9SpriteBoss")
        if mScale9SpriteBoss then
            NodeHelper:autoAdjustResizeScale9Sprite(mScale9SpriteBoss)
            -- GuildData.mainContainer:autoAdjustResizeScale9Sprite( mScale9Sprite11 )
        end

        --联盟界面左边
        local mClippingNodeLeft =  GuildData.allianceContainer:getVarNode("mClippingNodeLeft")
        local offy =  NodeHelper:calcAdjustResolutionOffY()
        if mClippingNodeLeft then
               mClippingNodeLeft = tolua.cast(mClippingNodeLeft,'CCClippingNode')
               local nodeLeft = CCNode:create()
               local sprite = CCSprite:create('UI/Mask/u_MaakAlliance.png')
               local sizeH = sprite:getContentSize().height
               local scale = offy/sizeH
               sprite:setScaleY(1 + 2 * scale)
               --sprite:setContentSize(CCSizeMake(sizeW, offy + sizeH));
               nodeLeft:addChild(sprite)
               nodeLeft:setPosition(ccp(0,0))
               mClippingNodeLeft:setStencil(nodeLeft)
        end
         --联盟界面右边
        local mClippingNodeRight =  GuildData.allianceContainer:getVarNode("mClippingNodeRight")
        if mClippingNodeRight then
               mClippingNodeRight = tolua.cast(mClippingNodeRight,'CCClippingNode')
               local nodeRight = CCNode:create()
               local sprite = CCSprite:create('UI/Mask/u_MaakAlliance.png')
               local sizeH = sprite:getContentSize().height
               local scale = offy/sizeH
               sprite:setScaleY(1 + 2 * scale)
               --sprite:setContentSize(CCSizeMake(sizeW, offy + sizeH));
               nodeRight:addChild(sprite)
               nodeRight:setPosition(ccp(0,0))
               mClippingNodeRight:setStencil(nodeRight)
        end
        --联盟界面GVG 按钮栏
        NodeHelper:autoAdjustResetNodePosition(GuildData.allianceContainer:getVarNode("mAdjustGVG"))

    end

    -- 'boss节点', 嵌入在'有公会节点'
    local bossNode = GuildData.allianceContainer:getVarNode('mPartakeGuildBossIntrusionItem')
    if bossNode then
        GuildData.GuildPage.bossNode = bossNode
        GuildData.bossContainer = ScriptContentBase:create('GuildBossIntrusionItem.ccbi')

        if NodeHelper:getAdjustBgScale(1) >1  then 

            local mAdjustScale9 = GuildData.bossContainer:getVarScale9Sprite("mAdjustScale9")
            if mAdjustScale9 then
                NodeHelper:autoAdjustResizeScale9Sprite(mAdjustScale9)
                -- GuildData.mainContainer:autoAdjustResizeScale9Sprite( mScale9Sprite11 )
            end

            --联盟Boss
            local mClippingNodeCenter =  GuildData.bossContainer:getVarNode("mClippingNodeCenter")
            local offy =  NodeHelper:calcAdjustResolutionOffY()
            if mClippingNodeCenter then
                   mClippingNodeCenter = tolua.cast(mClippingNodeCenter,'CCClippingNode')
                   local nodeCenter = CCNode:create()
                   local sprite = CCSprite:create('UI/Mask/u_MaakAllianceBoss.png')
                   local sizeH = sprite:getContentSize().height
                   local scale = offy/sizeH
                   sprite:setScaleY(1 + 2 * scale)
                   --sprite:setContentSize(CCSizeMake(sizeW, offy + sizeH));
                   nodeCenter:addChild(sprite)
                   nodeCenter:setPosition(ccp(0,0))
                   mClippingNodeCenter:setStencil(nodeCenter)
            end
            local mInfoNode = GuildData.bossContainer:getVarNode("mInfoNode")
              --联盟界面BOSS 按钮栏
            NodeHelper:autoAdjustResetNodePosition(mInfoNode)
        end
        -- boss飘血动画节点, 嵌入在'boss节点'
        GuildData.bossHitContainer = ScriptContentBase:create('BattleNormalNum.ccbi')
        local bossAniNode = GuildData.bossContainer:getVarNode('mPersonHitNumberNode')
        bossAniNode:addChild(GuildData.bossHitContainer)
        GuildData.bossHitContainer:release();

        GuildData.bossContainer:registerFunctionHandler(GuildData.BossPage.onFunction)
        bossNode:addChild(GuildData.bossContainer)
        GuildData.bossContainer:release();
        bossNode:setVisible(false)
    end

    local mSubNode = GuildData.allianceContainer:getVarNode('mContentNode3')
    if mSubNode then
        GuildData.GuildPage.mSubNode = mSubNode
        GuildData.GuildPage:addSubCCB(container)
    end

    container:addChild(GuildData.allianceContainer)
    GuildData.allianceContainer:release();

    -- '无公会节点'
    GuildData.joinListContainer = ScriptContentBase:create(option.ccbiFile)
    GuildData.joinListContainer:registerFunctionHandler(GuildData.GuildPage.onFunction)

    NodeHelper:initScrollView(GuildData.joinListContainer, 'mContent', 10)

    GuildData.guildAnnouncementLabel = GuildData.allianceContainer:getVarLabelTTF("mPartakeGuildAnnouncements")
    GuildData.guildAnnouncementLabelOriPosX, GuildData.guildAnnouncementLabelOriPosY = GuildData.guildAnnouncementLabel:getPosition()
    -- -------------------- 适配 --------------------------------
    if GuildData.joinListContainer.mScrollView then
        GuildData.mainContainer:autoAdjustResizeScrollview(GuildData.joinListContainer.mScrollView)
    end

    local mScale9Sprite1 = GuildData.joinListContainer:getVarScale9Sprite("mScale9Sprite1")
    if mScale9Sprite1 then
        -- GuildData.mainContainer:autoAdjustResizeScale9Sprite( mScale9Sprite1 )
        NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite1)
    end

    local mScale9Sprite2 = GuildData.joinListContainer:getVarScale9Sprite("mScale9Sprite2")
    if mScale9Sprite2 then
        -- GuildData.joinListContainer:autoAdjustResizeScale9Sprite( mScale9Sprite2 )
        NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite2)
    end

    local mScale9Sprite3 = GuildData.joinListContainer:getVarScale9Sprite("mScale9Sprite3")
    if mScale9Sprite3 then
        -- GuildData.joinListContainer:autoAdjustResizeScale9Sprite( mScale9Sprite3 )
        NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite3)
    end
    -- -------------------- 适配 --------------------------------

    container:addChild(GuildData.joinListContainer)
    GuildData.joinListContainer:release();

    -- 根据是否有公会来控制显隐
    if GuildData.MyAllianceInfo then
        GuildData.joinListContainer:setVisible(not GuildData.MyAllianceInfo.hasAlliance)
        GuildData.allianceContainer:setVisible(not(not GuildData.MyAllianceInfo.hasAlliance))
    else
        GuildData.joinListContainer:setVisible(true)
        GuildData.allianceContainer:setVisible(false)
    end
end

function GuildData.GuildPage.onInit(container)
end
function GuildData.GuildPage.onEnter(container)

    if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.hasAlliance then
        if not GuildData.MyAllianceInfo.myInfo.hasReported then
            GuildDataManager:onSignIn()
        end
        -- GuildData.BossPage.onAttributeOpen(GuildData.bossContainer)
    end
    isRunMoveAction = false
    inBossPage = false
    GuildData.GuildPage.container = container
    GuildDataManager:registerPackets()
    GuildDataManager:registerMessages()
    UserInfo.sync()
    -- 为了判断vip等级是否过3，自动战斗是否显示
    GuildData.allianceInfo.joinList = nil

    if GuildData.GuildPage.mSubNode then
        common:sendEmptyPacket(hp.FETCH_WORLD_BOSS_BANNER_C, true)
    end
    -- GuildData.GuildPage.refreshPage()

    -- request basic info
    GuildDataManager:requestBasicInfo()
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_ALLIANCE)
    local tmpCount = CCUserDefault:sharedUserDefault():getIntegerForKey("GuildPage"..UserInfo.playerInfo.playerId);
    if tmpCount == 0 then
        CCUserDefault:sharedUserDefault():setIntegerForKey("GuildPage"..UserInfo.playerInfo.playerId, 1);
    end
    GuildData.GuildPage.checkRedPoint()
end

function GuildData.GuildPage.checkRedPoint()
    NodeHelper:setNodesVisible(GuildData.allianceContainer,{mNewPoint = hasNewMemberChatComing})
end

function GuildData.GuildPage.onExecute(container)
    if GuildData.BossPage
        and GuildData.allianceInfo.commonInfo
        and(GuildData.allianceInfo.commonInfo.bossState == GuildData.BossPage.BossCanInspire) then
        -- 更新boss击退倒计时
        GuildData.BossPage.updateCD(GuildData.bossContainer)
    end

    -- 进入活动片刻后，预加载商店、成员列表、boss排行、公会排行等数据
    local dt = GamePrecedure:getInstance():getFrameTime() * 1000
    GuildData.enterPageTime = GuildData.enterPageTime + dt

    GuildDataManager:requestData(GuildData.enterPageTime)

    GuildData.GuildPage.refreshRefuseGuildTime()

    if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.myInfo then
        if GuildData.MyAllianceInfo.myInfo.hasReported then
            NoticePointState.GUILD_SIGNIN = false
        end
    end

    NodeHelper:mainFrameSetPointVisible(
    {
        --mGuildPagePoint = NoticePointState.GUILD_SIGNIN or NoticePointState.ALLIANCE_BOSS_OPEN or GVGManager.needShowRewardNotice(),
        mGuildPagePoint = NoticePointState.GUILD_SIGNIN or NoticePointState.ALLIANCE_BOSS_OPEN,
    }
    )
    NodeHelper:setNodesVisible(GuildData.allianceContainer, { mSignInPoint = GVGManager.needShowRewardNotice() })
end

function GuildData.GuildPage.refreshRefuseGuildTime()
    for guildId, info in pairs(refreshTab) do
        if TimeCalculator:getInstance():hasKey("guild" .. guildId) then
            if info.container then
                local leftTime = TimeCalculator:getInstance():getTimeLeft("guild" .. guildId)
                if leftTime > 0 then
                    NodeHelper:setStringForLabel(info.container, { mBtnTxt = GameMaths:formatSecondsToTime(leftTime) })
                else
                    NodeHelper:setStringForLabel(info.container, { mBtnTxt = common:getLanguageString("@Application") })
                    NodeHelper:setMenuItemEnabled(info.container, "mPartakeBtn", true)
                    TimeCalculator:getInstance():removeTimeCalcultor("guild" .. guildId)
                end
            end
        end
    end
end

function GuildData.GuildPage.clearRefuseGuildTime()
    for guildId, info in pairs(refreshTab) do
        TimeCalculator:getInstance():removeTimeCalcultor("guild" .. guildId)
    end
    refreshTab = { }
end

function GuildData.GuildPage.onExit(container)
    isChatJump = false
    isReturnChat = false
    GuildData.nowRefreshPageNum = 1
    roleTable = { }
    GuildDataManager:notifyMainPageRedPoint()
    GuildDataManager:removePackets()
    GuildDataManager:removeMessages()
    if GuildData.joinListContainer then
        NodeHelper:deleteScrollView(GuildData.joinListContainer)
    end
    if GuildData.guildAnnouncementLabel then
        GuildData.guildAnnouncementLabel:stopAllActions()
    end
    GuildData.GuildPage.clearRefuseGuildTime()
    GameUtil:purgeCachedData()
end
--------------------------------- boss page --------------------------------
function GuildData.BossPage.onFunction(eventName, container)
    local funcName = option.bossHander[eventName]
    if funcName then
        GuildData.BossPage[funcName](container, eventName)
    else
        CCLuaLog('unknown eventName: ' .. tostring(eventName))
    end
end

function GuildData.BossPage.openBoss(container, eventName)
    GuildDataManager:openBoss(container, eventName)
end

function GuildData.BossPage.refreshPage(container)
    if not container then return end

    -- titles
    local lb2Str = {
        mBossIntrusionLevel = common:getLanguageString('','@BossLevelName',0),
        mBossIntrusionExpNum = 0
    }

    local info = GuildData.allianceInfo.commonInfo
    if info then
        local cfg = GuildDataManager:getBossCfgByBossId(info.bossId)
        if cfg then
            lb2Str.mBossIntrusionLevel = common:getLanguageString(cfg.bossName, '@BossLevelName', cfg.level)
            lb2Str.mBossIntrusionExpNum = common:getLanguageString('@BossExp') .. cfg.bossExp
            lb2Str.mBossVitalityNum = common:getLanguageString('@BossVitality') .. info.curBossVitality .. '/' .. info.openBossVitality
            -- 开启boss需要消耗的元气值
        end
    end
    NodeHelper:setStringForLabel(container, lb2Str)

    -- content
    if not info then
        GuildData.BossPage.showOpenBossView(container)
    elseif info.bossState == GuildData.BossPage.BossNotOpen then
        -- not open
        GuildData.BossPage.showOpenBossView(container)
    elseif info.bossState == GuildData.BossPage.BossCanJoin then
        -- battle
        GuildData.BossPage.showBossJoinView(container)
    elseif info.bossState == GuildData.BossPage.BossCanInspire then
        -- can inspire
        GuildData.BossPage.showBossBattleView(container)
    end
end

-- 显示‘开启boss’界面
function GuildData.BossPage.showOpenBossView(container)
    -- container:getVarNode("mInfoNode"):setPosition(ccp(0,-30))
    container:getVarNode("mInfoNode"):setVisible(true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite1'), true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite2'), false)
    -- 自动战斗,如果是vip3以下隐藏
    print("GuildData.MyAllianceInfo.myInfo.autoFight = ", GuildData.MyAllianceInfo.myInfo.autoFight)
    NodeHelper:setNodeVisible(GuildData.bossContainer:getVarNode("mAutoFightNode"), UserInfo.playerInfo.vipLevel >= GameConfig.GuildBossAutoFightLimit)

    NodeHelper:setNodeVisible(GuildData.bossContainer:getVarSprite("mAutoFightSprite"), GuildData.MyAllianceInfo.myInfo.autoFight == 1)
    CCLuaLog("mAutoFightSprite showOpenBossView = " .. tostring(GuildData.MyAllianceInfo.myInfo.autoFight == 1))
    NodeHelper:setNodeVisible(container:getVarNode('mOpenBossNode'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusion'), true)
    -- NodeHelper:setNodeVisible(container:getVarNode('mBossOpenNoticeNode'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusionBattle'), false)
     NodeHelper:setNodeVisible(container:getVarNode('mGrayBgBig'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgSmall'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mCDIntrusionNode'), false)
    local leftCount = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.bossFunRemSize or 0
    NodeHelper:setStringForLabel(container, { mOpenBossIntrusion = common:getLanguageString('@OpenBoss', leftCount) })
end

-- 显示‘加入战斗’界面
function GuildData.BossPage.showBossJoinView(container)
    --container:getVarNode("mInfoNode"):setPosition(ccp(0, -30))
    container:getVarNode("mInfoNode"):setVisible(true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite1'), true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite2'), false)
    -- 自动战斗,如果是vip3以下隐藏
    print("GuildData.MyAllianceInfo.myInfo.autoFight = ", GuildData.MyAllianceInfo.myInfo.autoFight)
    NodeHelper:setNodeVisible(GuildData.bossContainer:getVarNode("mAutoFightNode"), UserInfo.playerInfo.vipLevel >= GameConfig.GuildBossAutoFightLimit)
    NodeHelper:setNodeVisible(GuildData.bossContainer:getVarSprite("mAutoFightSprite"), GuildData.MyAllianceInfo.myInfo.autoFight == 1)
    CCLuaLog("mAutoFightSprite showBossJoinView = " .. tostring(GuildData.MyAllianceInfo.myInfo.autoFight == 1))
    NodeHelper:setNodeVisible(container:getVarNode('mOpenBossNode'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusion'), false)
    -- NodeHelper:setNodeVisible(container:getVarNode('mBossOpenNoticeNode'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusionBattle'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgBig'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgSmall'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mCDIntrusionNode'), false)
    NodeHelper:setStringForLabel(container, { mOpenBossIntrusion = common:getLanguageString('@GuildBossJoin') })
end

-- 显示‘战斗’界面
function GuildData.BossPage.showBossBattleView(container)
    --container:getVarNode("mInfoNode"):setPosition(ccp(0, 58))
    container:getVarNode("mInfoNode"):setVisible(true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite1'), false)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite2'), true)
    NodeHelper:setNodeVisible(GuildData.bossContainer:getVarNode("mAutoFightNode"), false)

    NodeHelper:setNodeVisible(container:getVarNode('mOpenBossNode'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusion'), false)
    -- NodeHelper:setNodeVisible(container:getVarNode('mBossOpenNoticeNode'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusionBattle'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgBig'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgSmall'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mCDIntrusionNode'), true)
    local info = GuildData.allianceInfo.commonInfo
    local lb2Str = { }
    local totalBlood = 0
    if info then
        local cfg = GuildDataManager:getBossCfgByBossId(info.bossId)
        if cfg then
            totalBlood = cfg.bossBlood
        end
        lb2Str.mBossIntrusionHpNum = tostring(GuildData.BossPage.bossBloodLeft) .. '/' .. tostring(totalBlood)
        lb2Str.mInspireIntrusionNum = common:getLanguageString('@GuildBossInspireRatio', info.bossPropAdd)
    else
        lb2Str.mBossIntrusionHpNum = '0/0'
        lb2Str.mInspireIntrusionNum = common:getLanguageString('@GuildBossInspireRatio', info.bossPropAdd)
    end
    -- inspire desc
    lb2Str.mEncouragePromptTex = common:getLanguageString('@GuildInspirePreview', GuildData.BossPage.InspirePercent, GuildData.BossPage.InspireCost)

    NodeHelper:setStringForLabel(container, lb2Str)



    local expProgressTimer = nil
    local expBarParentNode = container:getVarNode("mIntrusionExpBg")
    if expBarParentNode then
        expProgressTimer = expBarParentNode:getChildByTag(10086)
        if expProgressTimer == nil then
            local expSprite = CCSprite:createWithSpriteFrameName("Alliance_BossHpBar.png")
            expProgressTimer = CCProgressTimer:create(expSprite)
            expBarParentNode:addChild(expProgressTimer)
            expProgressTimer:setTag(10086)
            expProgressTimer:setAnchorPoint(ccp(0.5, 0.5))
            expProgressTimer:setPosition(ccp(expBarParentNode:getContentSize().width / 2, expBarParentNode:getContentSize().height / 2))
            expProgressTimer:setType(kCCProgressTimerTypeBar)
            expProgressTimer:setMidpoint(ccp(0, 0.5))
            expProgressTimer:setBarChangeRate(ccp(1, 0))
        end
    end
   

    -- progress bar
    local scale = 0.0
    if totalBlood ~= 0 then
        scale = GuildData.BossPage.bossBloodLeft / totalBlood
        -- * 1.09
        if scale < 0 then scale = 0.0 end
    end

--    local expBar = container:getVarScale9Sprite('mIntrusionExp')
--    if expBar then
--        expBar:setScaleX(scale)
--    end

    local n = math.abs(scale * 100)
    expProgressTimer:setPercentage(n)


end

function GuildData.BossPage.updateCD(container)
    if not container then return end

    local cdString = '00:00:00'
    if TimeCalculator:getInstance():hasKey(GuildData.BossPage.CDTimeKey) then
        local timeleft = TimeCalculator:getInstance():getTimeLeft(GuildData.BossPage.CDTimeKey)
        if timeleft > 0 then
            cdString = GameMaths:formatSecondsToTime(timeleft)
        else
            -- boss 倒计时结束，判断打没打死
            TimeCalculator:getInstance():removeTimeCalcultor(GuildData.BossPage.CDTimeKey)
            GuildDataManager:requestBasicInfo()
        end
    end
    NodeHelper:setStringForLabel(container, { mCD = common:getLanguageString("@BossRetreatCountDown") .. cdString })
end

-- 鼓舞
function GuildData.BossPage.onInspire(container, eventName)
    if UserInfo.isGoldEnough(GuildData.BossPage.InspireCost, "GuildBoss_Inspire_enter_rechargePage") then
        GuildDataManager:doInspire()
    end
end

function GuildData.BossPage.onContributionRanking(container, eventName)
    PageManager.pushPage('GuildBossHarmRankPage')
end
--------------------------------- end boss page --------------------------------

--------------------------ui function--------------------------------------

-- view when you have an alliance
function GuildData.GuildPage.showAllianceView()
    GuildData.joinListContainer:setVisible(false)
    GuildData.allianceContainer:setVisible(true)

    -- alliance info
    GuildData.GuildPage.showAllianceInfo()

    -- refresh boss
    GuildData.BossPage.refreshPage(GuildData.bossContainer)
    -- AB red point
    NodeHelper:setNodesVisible(GuildData.allianceContainer, { mIntrusionPoint = ABRedPoint })
end

-- view when you don't have an alliance
function GuildData.GuildPage.showJoinListView()
    GuildData.joinListContainer:setVisible(true)
    GuildData.allianceContainer:setVisible(false)
    GuildData.GuildPage.clearRefuseGuildTime()
    if GuildData.joinListContainer.mScrollView
        and GuildData.joinListContainer.m_pScrollViewFacade
        and GuildData.allianceInfo.joinList then
        -- 显示刷新页数
        -- NodeHelper:setStringForLabel(GuildData.joinListContainer,
        -- {mPageNum =common:getLanguageString("@GuildRecommendListPage") .. GuildData.allianceInfo.curPage .. '/' .. GuildData.allianceInfo.maxPage})
        NodeHelper:setNodeVisible(GuildData.joinListContainer:getVarNode("mPageNum"), false)
        GuildData.GuildPage.rebuildAllItem()
    end
    NodeHelper:setNodesVisible(GuildData.joinListContainer, { mGuildContendPoint = ABRedPoint })
end

function GuildData.GuildPage.refreshPage()
    if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.hasAlliance then
        -- if i have a alliance
        GuildData.GuildPage.showAllianceView()
    else
        -- i don't belong to any alliance
        GuildData.GuildPage.showJoinListView()
    end
end
-- 未加入公会、已加入公会&未签到 都需显示红点 
function GuildData.GuildPage.CheckShowNoticePoint()
    if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.hasAlliance then
        if GuildData.MyAllianceInfo.myInfo and GuildData.MyAllianceInfo.myInfo.hasReported then
            return false;
        else
            return true;
        end
    else
        return true;
    end
end

local function runMoveAction()
    if not GuildData.guildAnnouncementLabel then return end
    local labelPosX, labelPosY = GuildData.guildAnnouncementLabel:getPosition()
    local width = GuildData.guildAnnouncementLabel:getContentSize().width
    if width >= 580 then
        if not isRunMoveAction then
            local endPosX = -280 - width
            local moveDis = math.abs(endPosX - labelPosX)
            local moveTime = moveDis / 80
            labelPosX = 280
            isRunMoveAction = true
            local array = CCArray:create()
            -- array:addObject(CCDelayTime:create(2))
            array:addObject(CCMoveTo:create(moveTime, ccp(endPosX, labelPosY)))
            local function resetPos()
                GuildData.guildAnnouncementLabel:setPosition(ccp(labelPosX, labelPosY))
                isRunMoveAction = false
            end
            array:addObject(CCCallFunc:create(resetPos))
            array:addObject(CCCallFunc:create(runMoveAction))
            GuildData.guildAnnouncementLabel:runAction(CCSequence:create(array))
        end
    end
end

function GuildData.GuildPage.showAllianceInfo(container)
    local lb2Str = {
        mPartakeLV = '0',
        mGuildName = '',
        mPartakeGuildID = common:getLanguageString("@GuildID",'NO'),
        mNumberPeople = 'NO / NO',
        mPartakeGuildExp = 'NO / NO',
        mPartakeGuildAnnouncements = common:getLanguageString('@GuildAnnoucementDefault'),
        mPartakeNumberPeople = 0,
    }
    local visibleMap = {
        mChangeGuildName = false
    }

    -- UserInfo.playerInfo.playerId

    --    local memberList = GuildData.memberList
    --    local memberSelfInfo = nil
    --    for i = 1, #memberList do
    --        if UserInfo.playerInfo.playerId == memberList[i].id  then
    --           memberSelfInfo = memberList[i]
    --        end
    --    end
    -- exp bar zoom scale
    local scale = 0.0
    local info = GuildData.allianceInfo.commonInfo
    if info then
        lb2Str.mPartakeLV = info.level
        lb2Str.mGuildName = info.name
        lb2Str.mPartakeGuildID = info.id
        lb2Str.mPartakeNumberPeople = info.currentPop .. ' / ' .. info.maxPop
        lb2Str.mPartakeGuildExp = info.currentExp .. ' / ' .. info.nextExp
        lb2Str.mPartakeGuildAnnouncements = common:getLanguageString("@GuildAnnoucementDefault")
        if GuildData.MyAllianceInfo  then
           lb2Str.mSelfContribution = GuildData.MyAllianceInfo.myInfo.contribution
        else
           lb2Str.mSelfContribution = 0 
        end
        -- 个人贡献度
        lb2Str.mPartakeHonor = GuildData.allianceInfo.commonInfo.curBossVitality
        -- 联盟声望
        if info.nextExp ~= 0 then
            scale = info.currentExp / info.nextExp
        end

        if info.annoucement and common:trim(info.annoucement) ~= '' then
            -- 如果公告太长，取前20个字
            local length = GameMaths:calculateStringCharacters(info.annoucement)
            -- if length > 20 then
            -- lb2Str.mPartakeGuildAnnouncements = GameMaths:getStringSubCharacters(info.annoucement, 0, 20)
            -- else
            -- lb2Str.mPartakeGuildAnnouncements = info.annoucement

            lb2Str.mPartakeGuildAnnouncements = info.annoucement --common:getLanguageString("@GuildAnnoucementDefault")
            -- end
        end

        visibleMap.mChangeGuildName = info.canChangeName
    end

    NodeHelper:setStringForLabel(GuildData.allianceContainer, lb2Str)

    GuildData.guildAnnouncementLabel:stopAllActions()
    GuildData.guildAnnouncementLabel:setPosition(ccp(GuildData.guildAnnouncementLabelOriPosX, GuildData.guildAnnouncementLabelOriPosY))
    isRunMoveAction = false
    local array = CCArray:create()
    array:addObject(CCDelayTime:create(3))
    array:addObject(CCCallFunc:create(runMoveAction))
    GuildData.guildAnnouncementLabel:runAction(CCSequence:create(array))

    -- exp bar
    local expBar = GuildData.allianceContainer:getVarScale9Sprite('mPartakeExp')
    if expBar then
        expBar:setScaleX(scale)
    end
    -- local visible = GuildData.GuildPage.CheckShowNoticePoint()
    -- if visible ~= NoticePointState.GUILD_SIGNIN then
    -- PageManager.showRedNotice("Guild", visible)
    -- NoticePointState.GUILD_SIGNIN = visible
    -- end

    NodeHelper:setNodesVisible(GuildData.allianceContainer, visibleMap)

end

----------------scrollview item of 可加入公会列表 -------------------------
local JoinListItem = {
    ccbiFile = 'GuildRecommendContent.ccbi',
}

function JoinListItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        JoinListItem.onRefreshItemView(container)
    elseif eventName == "onPartake" then
        JoinListItem.joinAlliance(container)
    end
end

function JoinListItem.onRefreshItemView(container)
    local index = container:getItemDate().mID
    local info = GuildData.allianceInfo.joinList[index]
    local allianceState = GuildData.allianceInfo.allianceState
    if not info then return end
    local lb2Str = {
        mGuildLv = common:getLanguageString("@MyLevel",info.level),
        mGuildName = info.name,
        mGuildNum = info.currnetPop .. ' / ' .. info.maxPoj
    }
    local isMenuEnabled = true
    if info.hasCheckButton == 1 then
        lb2Str["mBtnTxt"] = common:getLanguageString("@Application")
        -- 申请
        NodeHelper:setNodeScale(container, "mBtnTxt", 1, 1)
    else
        lb2Str["mBtnTxt"] = common:getLanguageString("@Partake")
        -- 参加
        NodeHelper:setNodeScale(container, "mBtnTxt", 1, 1)
    end
    if allianceState then
        for k, msg in pairs(allianceState) do
            local guildId = info.id
            local allianceId = msg.allianceId
            if guildId == allianceId then
                local state = msg.state
                -- 申请的公会状态  1.待审核. 2.失败拒绝加入
                local refusedJoinTime = msg.refusedJoinTime
                local serverTime = GamePrecedure:getInstance():getServerTime()
                local remainTime = math.floor(refusedJoinTime / 1000) - serverTime
                if state == 1 then
                    lb2Str["mBtnTxt"] = common:getLanguageString("@Approve")
                    -- 待审批
                    isMenuEnabled = false
                    NodeHelper:setNodeScale(container, "mBtnTxt", 1, 1)
                elseif state == 2 then
                    lb2Str["mBtnTxt"] = GameMaths:formatSecondsToTime(remainTime)
                    -- 被拒绝
                    isMenuEnabled = false
                    NodeHelper:setNodeScale(container, "mBtnTxt", 0.7, 0.7)
                    local info = { }
                    info.container = container
                    info.remainTime = TimeCalculator:getInstance():createTimeCalcultor("guild" .. guildId, remainTime)
                    refreshTab[guildId] = info
                end
                break
            end
        end
    end
    NodeHelper:setNodeIsGray(container, {mBtnTxt = not isMenuEnabled})
    NodeHelper:setMenuItemEnabled(container, "mPartakeBtn", isMenuEnabled)
    NodeHelper:setStringForLabel(container, lb2Str)
end	

-- 加入公会
function JoinListItem.joinAlliance(container)
    local index = container:getItemDate().mID
    local info = GuildData.allianceInfo.joinList[index]
    if not info then return end
    if info.hasCheckButton == 1 then
        -- 申请加入公会
        GuildDataManager:sendApplyAlliancePacket(info.id)
    else
        GuildDataManager:sendJoinAlliancePacket(info.id)
    end
end

----------------scrollview-------------------------
function GuildData.GuildPage.rebuildAllItem()
    GuildData.GuildPage.clearAllItem(GuildData.joinListContainer)
    GuildData.GuildPage.buildItem()
end

function GuildData.GuildPage.clearAllItem()
    NodeHelper:clearScrollView(GuildData.joinListContainer)
end

function GuildData.GuildPage.buildItem()
    NodeHelper:buildScrollView(GuildData.joinListContainer, #GuildData.allianceInfo.joinList, JoinListItem.ccbiFile, JoinListItem.onFunction);
end

----------------click event------------------------
function GuildData.GuildPage.onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ALLIANCE)
end

function GuildData.GuildPage.refreshGVGTime(container)
    local time1 = GVGManager.getDeclareStartTime()
    local time2 = GVGManager.getDeclareEndTime()
    local time3 = GVGManager.getFightingStartTime()
    local time4 = GVGManager.getFightingEndTime()
    if time1 == "00:00" then 
       time1 = "08:00"
       time2 = "20:30"
       time3 = "21:00"
       time4 = "21:45"
    end 
    local TimeStr = common:getLanguageString("@GVGDeclareTime", time1, time2) .. "\n" .. common:getLanguageString("@GVGFightingTime", time3, time4)

    local lb2Str = {
        mGVGOpeningTime = TimeStr
    }
    NodeHelper:setStringForLabel(container, lb2Str);
end

function GuildData.GuildPage.refreshJoinList(container)
    GuildDataManager:sendRefreshGuildListPacket()
end

-- 搜索公会
function GuildData.GuildPage.onSearchGuild(container)
    PageManager.pushPage('GuildSearchPopPage')
end

-- 创建公会
function GuildData.GuildPage.onCreateGuild(container)
    UserInfo.sync()
    if UserInfo.roleInfo.level < GuildData.CreateAllianceOpenLevel then
        MessageBoxPage:Msg_Box(common:getLanguageString('@GuildCreateLevel', GuildData.CreateAllianceOpenLevel))
        return
    end
    PageManager.pushPage('GuildCreatePage')
end

function GuildData.GuildPage.onGuildBattle(container)
    -- MessageBoxPage:Msg_Box('@CommingSoon')
    -- PageManager.changePage("ABMainPage")

    local AllianceBattle_pb = require("AllianceBattle_pb")
    local msg = AllianceBattle_pb.HPAFMainEnter();
    common:sendPacket(hp.ALLIANCE_BATTLE_ENTER_C, msg);
    ABRedPoint = false
end

function GuildData.GuildPage.onGuildRanking(container)
    -- PageManager.pushPage('GuildRankingPage')
    PageManager.pushPage('GuildRankManage')
end

-- 签到
function GuildData.GuildPage.onSignIn(container)
    GVGManager.reqRewardInfo()
    --
end

function GuildData.GuildPage.onGuildChangeName(container)
    PageManager.pushPage("GuildChangePage")
    --PageManager.pushPage("GeneralChangeNamePage");
    --SetInputBoxInfo(common:getLanguageString("@ChangeGroupName"), common:getLanguageString("@ChangeGroupName_Desc"), "", inputBoxCallback , 0.8);
end

-- 下面一排按钮里面的boss入侵，显示‘boss伤害排行榜'
function GuildData.GuildPage.onIntrude(container)
    --[[
	local bossState = GuildData.allianceInfo.commonInfo.bossState or GuildData.BossPage.BossCanInspire
	if GuildData.BossPage.BossNotOpen == bossState then
		MessageBoxPage:Msg_Box('@GuildBossWaitToOpen')
	elseif GuildData.BossPage.BossCanJoin == bossState then
		MessageBoxPage:Msg_Box('@GuildBossPleaseJoin')
	elseif GuildData.BossPage.BossCanInspire == bossState then
		PageManager.pushPage('GuildBossHarmRankPage')
	end
--]]
    -- PageManager.pushPage("GuildBattleBallot")
    local AllianceBattle_pb = require("AllianceBattle_pb")
    local msg = AllianceBattle_pb.HPAFMainEnter();
    common:sendPacket(hp.ALLIANCE_BATTLE_ENTER_C, msg);
    ABRedPoint = false
end

-- 贡献兑换
function GuildData.GuildPage.exchangeContribution(container)
    -- listening this packet in the pop page
    GuildDataManager:removeOnePacket(hp.ALLIANCE_ENTER_S)
    PageManager.pushPage('GuildShopPage')
end

function GuildData.GuildPage.showMembers(container)
    PageManager.pushPage('GuildMembersPage')
end

function GuildData.GuildPage.onManage(container, eventName)
    -- listening this packet in the pop page
    GuildDataManager:removeOnePacket(hp.ALLIANCE_CREATE_S)
    PageManager.pushPage('GuildManagePage')
end

------------------魔兽元气tip显示-------------------------------------
local attributeOpenState = false
function GuildData.BossPage.onHideTipHandler()
    attributeOpenState = false
    GuildData.bossContainer:getVarMenuItemImage("mAttributeBtn"):setEnabled(true)
end
function GuildData.BossPage.onAttributeOpen(container)
    attributeOpenState = true
    local node = container:getVarMenuItem("mAttributeBtn")
    if node ~= nil then
        node:setEnabled(false)
        GameUtil:showTip(node, GuildData.vitalityCfg, GuildData.BossPage.onHideTipHandler)
    end
end
--
-- 自动战斗
function GuildData.BossPage.onAutoFight(container)
    -- 如果是开启状态，点击取消勾选
    if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.myInfo.autoFight == 1 then
        GuildData.GuildPage.sendAutoFightPacket(container)
    else
        local autoFightCost = VaribleManager:getInstance():getSetting("autoAllianceFightCost")
        local title = common:getLanguageString('@AllianceAutoFightTitle')
        local message = common:getLanguageString('@AllianceAutoFightDesc', autoFightCost)
        PageManager.showConfirm(title, message,
        function(agree)
            if agree and UserInfo.isGoldEnough(autoFightCost) then
                GuildData.GuildPage.sendAutoFightPacket(container)
            end
        end
        )
    end
end
function GuildData.GuildPage.sendAutoFightPacket(container)
    common:sendEmptyPacket(HP_pb.ALLIANCE_AUTO_FIGHT_C, false);
    CCLuaLog("mAutoFightSprite sendEmptyPacket ALLIANCE_AUTO_FIGHT_C")
end

function GuildData.GuildPage.removeMessages(container)
    GuildData.mainContainer:removeMessage(MSG_MAINFRAME_POPPAGE)
    GuildData.mainContainer:removeMessage(MSG_MAINFRAME_REFRESH)
end

-- 继承此类的活动如果同时开，消息监听不能同时存在,通过tag来区分
function GuildData.GuildPage.onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_POPPAGE then
        local pageName = MsgMainFramePopPage:getTrueType(message).pageName
        --local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "GuildShopPage" then
            GuildData.mainContainer:registerPacket(hp.ALLIANCE_ENTER_S)
        elseif pageName == 'GuildManagePage' then
            GuildData.mainContainer:registerPacket(hp.ALLIANCE_CREATE_S)
            GuildData.GuildPage.refreshPage()
        elseif pageName == 'GuildOpenBossConfirmPage' then
            GuildData.mainContainer:registerPacket(hp.ALLIANCE_CREATE_S)
        end
    elseif typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == 'GuildPage' then
            if extraParam =="refreshPoint" then
                GuildData.GuildPage.checkRedPoint()
                return
            end
            -- request new alliance info and refresh page
            GuildDataManager:requestBasicInfo()


        elseif pageName == 'GuildPage_Refresh_Right_Now' then
            GuildData.GuildPage.refreshPage()
        elseif pageName == "GuildPage_Refresh_GuildData.BossPage" then
            GuildData.BossPage.refreshPage(GuildData.bossContainer)
        elseif pageName == "GuildPage_Refresh_WorldBoss" then
            GuildData.GuildPage.refreshWorldBoss()
        elseif pageName == GVGManager.moduleName then
            local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
            if extraParam == GVGManager.onRewardInfo then
                local rewardInfo = GVGManager.getRewardInfo()
                if rewardInfo.reward and rewardInfo.reward ~= "-1" then
                    -- PageManager.changePage("GVGRewardPage")
                else
                    MessageBoxPage:Msg_Box("@ERRORCODE_33008")
                end
            elseif extraParam == GVGManager.onMapInfo then
                --if GVGManager.isGVGPageOpen then
               -- local gvgStatus = GVGManager.getGVGStatus()
                --or gvgStatus == GVG_pb.GVG_STATUS_WAITING
                if GVGManager.isGVGOpen  then 
                   PageManager.changePage("GVGMapPage")
                end
                --end
            end
        end
    end
end


function GuildData.GuildPage.onReceiveAllianceEnterInfo(container, msg)
    -- check if need change interface(change ccbi)
    GuildData.MyAllianceInfo = msg

    -- request joinlist
    if GuildData.MyAllianceInfo and  not GuildData.MyAllianceInfo.hasAlliance then
        GuildDataManager:getGuildListPacket()
    end

    if not container then
        container = GuildData.GuildPage.container
    end
end

function GuildData.GuildPage.doBossOperation(container, operType)
    local msg = alliance.HPAllianceBossFunOpenC()
    msg.operType = operType
    local pb = msg:SerializeToString()
    GuildData.mainContainer:sendPakcet(hp.ALLIANCE_BOSSFUNOPEN_C, pb, #pb, true)
end

function GuildData.GuildPage.onReceiveBossHarm(container, msg)
    GuildData.BossPage.bossBloodLeft = tonumber(GuildData.BossPage.bossBloodLeft - msg.value)
    local harm = common:getLanguageString('@GuildBossHarmValue', tostring(msg.value))
    -- MessageBoxPage:Msg_Box(harm)
    if GuildData.bossHitContainer then
        NodeHelper:setStringForLabel(GuildData.bossHitContainer, { mNumLabel = harm })
        GuildData.bossHitContainer:runAnimation('showNum')
    end

    if GuildData.BossPage.bossBloodLeft <= 0 then
        -- if boss is over, reset page
        GuildDataManager:requestBasicInfo()
    end
end

-- create result
function GuildData.GuildPage.onReceiveAllianceInfo(container, msg)
    GuildData.allianceInfo.commonInfo = msg

    -- adjust blood left
    if msg:HasField('bossHp') then
        GuildData.BossPage.bossBloodLeft = msg.bossHp
    end

    -- 校正boss倒计时
    if msg:HasField('bossTime') then
        local bossTime = tonumber(msg.bossTime) and tonumber(msg.bossTime) or 600
        TimeCalculator:getInstance():createTimeCalcultor(GuildData.BossPage.CDTimeKey, bossTime)
        if bossTime <= 0 and(msg.bossState ~= GuildData.BossPage.BossNotOpen) then
            -- boss is over, reset page
            GuildDataManager:requestBasicInfo()
        end
    end

    if GuildData.BossPage.bossJoinFlag then
        -- 收到了加入战斗的回包
        GuildData.BossPage.bossJoinFlag = false
        local bossTime = tonumber(msg.bossTime) and tonumber(msg.bossTime) or 600
        TimeCalculator:getInstance():createTimeCalcultor(GuildData.BossPage.CDTimeKey, bossTime)
    end
end

function GuildData.GuildPage.requestRankingList()
    GuildDataManager:requestRankingList()
end

function GuildData.GuildPage.onReceiveRankingList(msg)
    GuildData.rankInfoInited = true
    GuildDataManager:removeOnePacket(hp.ALLIANCE_RANKING_S)
    if msg.showTag then
        GuildDataManager:setRankInfo(msg.rankings)
    else
        GuildDataManager:setRankInfo( { })
    end
end


function GuildData.GuildPage.requestRankingFightingList()
    GuildDataManager:requestRankingFightingList()
end

function GuildData.GuildPage.onReceiveRankingFightingList(msg)
    GuildData.rankFightingInfoInited = true
    GuildDataManager:removeOnePacket(hp.ALLIANCE_SCORE_RANK_S)
    if msg.showTag then
        GuildDataManager:setRankFightingInfo(msg.rankings)
    else
        GuildDataManager:setRankFightingInfo( { })
    end
end


function GuildData.GuildPage.onReceiveMembers(msg)
    GuildData.memberInfoInited = true
    GuildDataManager:removeOnePacket(hp.ALLIANCE_MEMBER_S)
    GuildDataManager:setGuildMemberList(msg.memberList)
end

function GuildData.GuildPage.onReceiveHarmRank(msg)
    GuildData.bossRankInited = true
    GuildDataManager:removeOnePacket(hp.ALLIANCE_HARMSORT_S)
    if msg.showTag then
        GuildDataManager:setHarmRank(msg.harms)
    else
        GuildDataManager:setHarmRank( { })
    end
end

function GuildData.GuildPage.onReceivePacket(container)
    local opcode = GuildData.mainContainer:getRecPacketOpcode()
    local msgBuff = GuildData.mainContainer:getRecPacketBuffer()

    if opcode == hp.ALLIANCE_ENTER_S then
        -- alliance enter
        local msg = alliance.HPAllianceEnterS()
        msg:ParseFromString(msgBuff)
        GVGManager.needCheckGuildPoint = true 
        -- 在PackageLogicForLua中更新和相应的红点信息
        GuildData.GuildPage.onReceiveAllianceEnterInfo(container, msg)
        GuildData.GuildPage.refreshPage()
        GuildData.GuildPage.setGuildBattleBallot(msg)
        return
    end
    if opcode == hp.FETCH_WORLD_BOSS_BANNER_S then
        local msg = WorldBoss_pb.HPWorldBossBannerInfo();
        msg:ParseFromString(msgBuff)
        WorldBossManager.ReceiveHPWorldBossBannerInfo(msg)
        GuildData.GuildPage.refreshWorldBoss()
        return
    end
    if opcode == hp.FETCH_WORLD_BOSS_INFO_S then
        local msg = WorldBoss_pb.HPWorldBossInfo();
        msg:ParseFromString(msgBuff)
        WorldBossManager.enterFinalPageFrom = 2
        WorldBossManager.ReceiveHPWorldBossInfo_InBanner(msg)
        WorldBossManager.EnterPageByState()
        return
    end


    if opcode == hp.ALLIANCE_CREATE_S then
        -- create alliance
        local msg = alliance.HPAllianceInfoS()
        msg:ParseFromString(msgBuff)
        GuildData.GuildPage.onReceiveAllianceInfo(container, msg)
        GuildData.GuildPage.refreshPage()
        if UserInfo.hasAlliance ~= nil and not UserInfo.hasAlliance then
            PageManager.showComment()
            GVGManager.needCheckGuildPoint = true 
            -- 评价提示
        end
        return
    end

    if opcode == hp.ALLIANCE_HARMSORT_S then
        local msg = alliance.HPAllianceHarmSortS()
        msg:ParseFromString(msgBuff)
        GuildData.GuildPage.onReceiveHarmRank(msg)
        return
    end

    if opcode == hp.ALLIANCE_JOIN_LIST_S then
        -- alliance join list.
        local msg = alliance.HPAllianceJoinListS()
        msg:ParseFromString(msgBuff)
        GuildDataManager:onReceiveJoinList(msg)
        GuildData.GuildPage.refreshPage()
        return
    end

    if opcode == hp.ALLIANCE_BOSSHARM_S then
        -- alliance join list.
        local msg = alliance.HPAllianceBossHarmS()
        msg:ParseFromString(msgBuff)
        GuildData.GuildPage.onReceiveBossHarm(container, msg)
        GuildData.BossPage.refreshPage(GuildData.bossContainer)
        return
    end

    if opcode == hp.ALLIANCE_RANKING_S then
        local msg = alliance.HPAllianceRankingS()

        msg:ParseFromString(msgBuff)
        GuildData.GuildPage.onReceiveRankingList(msg)
        return
    end

    if opcode == hp.ALLIANCE_SCORE_RANK_S then
        local msg = alliance.AllianceScoreRankingS()
        msg:ParseFromString(msgBuff)
        GuildData.GuildPage.onReceiveRankingFightingList(msg)
        return
    end

    if opcode == hp.ALLIANCE_MEMBER_S then
        local msg = alliance.HPAllianceMemberS()
        msg:ParseFromString(msgBuff)
        GuildData.GuildPage.onReceiveMembers(msg)
        return
    end

    if opcode == hp.APPLY_INTO_ALLIANCE_S then
        local msg = alliance.HPApplyIntoAllianceS()
        msg:ParseFromString(msgBuff)
        GuildData.allianceInfo.allianceState = msg.allianceState
        GuildData.GuildPage.refreshPage()
        return
    end
end

function GuildData.GuildPage.setGuildBattleBallot(msg)
    local state = false
    GuildData.GuildBattleBallot = false
    if msg.hasAlliance and msg.isInBattle and msg.myInfo.postion == 2 then
        state = true
    end
    GuildData.GuildBattleBallot = state
end

function luaCreat_GuildPage(container)
    container:registerFunctionHandler(GuildData.GuildPage.onFunction)
end	

