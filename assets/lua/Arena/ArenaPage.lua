----------------------------------------------------------------------------------
-- 竞技排行界面
----------------------------------------------------------------------------------
require "Arena_pb"
require "HP_pb"
local UserInfo = require("PlayerInfo.UserInfo")
local ArenaData = require("Arena.ArenaData")
local titleManager = require("PlayerInfo.TitleManager")
ArenaRankCacheInfo = Arena_pb.HPArenaRankingListRet()
local ShopDataManager = require("ShopDataManager")
local ConfigManager = require("ConfigManager")
local OSPVPManager = require("OSPVPManager")
local NgHeadIconItem_Small = require("NgHeadIconItem_Small")
local thisPageName = "ArenaPage"
local CONST = require("Battle.NewBattleConst")

local ResManagerForlua = require("ResManagerForLua")
local option = {
    ccbiFile = "ArenaPage.ccbi",
    handlerMap =
    {
        onArena = "showArena",
        onRanking = "showRank",
        onPurchaseTimes = "purchaseTimes",
        onReplacement = "changeOpponet",
        onEditTeam = "onEditTeam",
        onHelp = "onHelp",
        onReturnBtn = "onReturn"
    },
    -- opcode = opcodes
}

local ArenaPageBase = { }

local NodeHelper = require("NodeHelper")
local GameConfig = require("GameConfig")
local _isReceiveBattleInfo = true
local PageType = {
    Arena = 1,
    Ranking = 2,
}

local PlayerType = {
    NPC = 1,
    Player = 2
}

local roleConfig = { }

local isGotoBattle = false
local challengeItemContainer = { }
local waitingTime = 0
local seasonCountDownKey = "seasonCountDownKey"

local nowRank = 1
local challangeRank = 1

ReadyToFightTeam = nil
--------------------------------------------------------------
local ArenaItem = {
    ccbiFile = "ArenaContent.ccbi"
}
local mercenaryHeadContent = {
    ccbiFile = "FormationTeamContent.ccbi"
}

local ArenaInfo = {
    pageType = PageType.Arena,
    SelfInfo = { },
    DefendersInfos = { },
    itemChangeName = "",
    rankingInfo = { },
    seasonTime = 0, -- 賽季倒數時間
}

local chanllengeContainer = nil

ArenaBuyTimesInitCost = ""
ArenaAlreadyBuyTimes = nil

local function toPurchaseTimes(boo, times)
    if boo then
        local msg = Arena_pb.HPBuyChallengeTimes()
        msg.times = times
        pb_data = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.BUY_CHALLENGE_TIMES_C, pb_data, #pb_data, true)
    end
end

local function setRankReward(container, str)
    local strName = FreeTypeConfig[62].content
    local infoTab = { }

    local tab = Split(str, ",")

    local rewardStr = ""
    for k, v in ipairs(tab) do
        local reward = ResManagerForlua:getResInfoByTypeAndId(tonumber(Split(v, "_")[1]), tonumber(Split(v, "_")[2]), tonumber(Split(v, "_")[3]))
        table.insert(infoTab, { count = reward.count, icon = reward.icon })
    end

    for i = 1, 2 do
        if infoTab[i] then
            NodeHelper:setStringForLabel(container, { ["mRewardNum" .. i] = infoTab[i].count })
            NodeHelper:setSpriteImage(container, { ["mRewardIcon" .. i] = infoTab[i].icon })
        end
        NodeHelper:setNodesVisible(container, { ["mRewardNode" .. i] = (infoTab[i] ~= nil) })
    end
end

function mercenaryHeadContent:onUnLoad(container)
end

function mercenaryHeadContent:refreshItem(container, isSelf, itemInfo)
    self.container = container
    UserInfo = require("PlayerInfo.UserInfo")
    local trueIcon = UserInfo.playerInfo.headIcon
    if isSelf then
        trueIcon = GameConfig.headIconNew or UserInfo.playerInfo.headIcon
    else
        if itemInfo.identityType == 2 then
            trueIcon = itemInfo.headIcon
        else
            trueIcon = 0
        end
    end
    local icon = common:getPlayeIcon(isSelf and UserInfo.roleInfo.prof or 1, trueIcon)
    if NodeHelper:isFileExist(icon) then
        NodeHelper:setSpriteImage(container, { mHead = icon })
    end

    NodeHelper:setStringForLabel(container, { mLv = (isSelf and UserInfo.roleInfo.level or itemInfo.level) })

    NodeHelper:setNodesVisible(container, { mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false, 
                                            mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false })
end

function ArenaItem.onFunction(eventName, container)
    if eventName == "luaInitItemView" then
        ArenaItem.onRefreshItemView(container)
    elseif eventName == "mDekaron" then
        ArenaItem.doChanllenge(container)
    end
end

function ArenaItem.onRefreshItemView(container)
    if ArenaInfo.pageType == PageType.Arena then
        table.insert(challengeItemContainer, container)
    end
   --local layer=nil
   --if not layer then
   --    layer = CCLayer:create()
   --    layer:setTag(container.mID)
   --    container:addChild(layer)
   --    layer:registerScriptTouchHandler( function(eventName, pTouch)
   --        local point = pTouch:getLocation()
   --        local touchPoint = layer:convertToNodeSpace(pTouch:getLocation())
   --        local layerBoundingBox = {x=0,y=0,width=container:getContentSize().width,height=container:getContentSize().height}
   --        layer:setContentSize(CCSize(layerBoundingBox.width,layerBoundingBox.height))
   --        local canEnter = false
   --        if eventName == "began" then
   --            canEnter = true
   --        elseif eventName == "moved"  then
   --        elseif eventName == "ended" then
   --            if canEnter then
   --                ArenaItem.doChanllenge(container)
   --            end
   --        elseif eventName == "cancelled" then
   --            canEnter = false
   --        end
   --    end, false,0, false)
   --    layer:setTouchEnabled(true)
   --    layer:setVisible(true)
   --end

    local contentId = container.mID
    local itemInfo = ArenaInfo.DefendersInfos[contentId]

    setRankReward(container, itemInfo.rankAwardsStr)
    local lb2Str = {
        mArenaName = itemInfo.name,
        mRankingNum = --[[common:getLanguageString("@Ranking") .. ]]itemInfo.rank,
        mFightingNum = GameUtil:formatDotNumber(itemInfo.fightValue),
    }
    if itemInfo.rank>3 then
         NodeHelper:setNodesVisible(container,{mRankImg = false})
    else
         NodeHelper:setNodesVisible(container,{mRankImg = true})
         NodeHelper:setSpriteImage(container,{mRankImg = "Rank_bg_"..itemInfo.rank..".png"})
    end

    NodeHelper:setStringForLabel(container, lb2Str)

    local icon, bgIcon = ""
    local headPic = ""
    if itemInfo.identityType == PlayerType.Player then
        local prof = roleConfig[itemInfo.cfgItemId].profession
        icon, bgIcon = common:getPlayeIcon(prof, itemInfo.headIcon)
    else
        icon, bgIcon = common:getPlayeIcon(1, 0)
    end
    ArenaItem.refreshPlayerIcon(container, itemInfo)

    if itemInfo.identityType == PlayerType.NPC then
        NodeHelper:setStringForLabel(container, { mArenaName = Language:getInstance():getString("@Monster_" .. string.format("%04d", itemInfo.rank % 500 + 9000)) })
    end

    if itemInfo.identityType == PlayerType.Player then
        if itemInfo.cspvpRank and itemInfo.cspvpRank > 0 then
            local stage = OSPVPManager.checkStage(itemInfo.cspvpScore, itemInfo.cspvpRank)
            NodeHelper:setNormalImages(container, {
                mHand = stage.stageIcon
            } )
        end
    end

    if contentId ~= nil and contentId == 3 and itemInfo ~= nil then
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["ArenaItem"] = container
        if GuideManager.IsNeedShowPage then
            GuideManager.IsNeedShowPage = false
            PageManager.pushPage("NewbieGuideForcedPage")
        end
    end

    ArenaItem.refreshTeamIcon(container)
end	

function ArenaItem.refreshTeamIcon(container)
    local contentId = container.mID
    local itemInfo = ArenaInfo.DefendersInfos[contentId]
    local cfg = nil
    if itemInfo.identityType == PlayerType.NPC then
        cfg = ConfigManager.getNewMonsterCfg()
    else
        cfg = ConfigManager.getNewHeroCfg()
    end
    for i = 1, 5 do
        if itemInfo.roleItemInfo[i] and itemInfo.roleItemInfo[i].itemId > 0 then
            local option = {
                fight = itemInfo.roleItemInfo[i].level,
                itemId = itemInfo.roleItemInfo[i].itemId,
                quality = (itemInfo.identityType == PlayerType.NPC and 5) or (itemInfo.roleItemInfo[i].starLevel > 10 and 6) or (itemInfo.roleItemInfo[i].starLevel < 6 and 4) or 5,
                element = cfg[itemInfo.roleItemInfo[i].itemId].Element,
                skinId = (itemInfo.identityType == PlayerType.NPC) and cfg[itemInfo.roleItemInfo[i].itemId].Skin or itemInfo.roleItemInfo[i].skinId,
                type = itemInfo.identityType,
                cfg = cfg[itemInfo.roleItemInfo[i].itemId]
            }
            local parent = container:getVarNode("mHeadNode" .. i)
            NgHeadIconItem_Small:createCCBFileCell(option.itemId, i, parent, GameConfig.NgHeadIconSmallType.ARENA_PAGE, 1, nil, option)
        end
    end
end

function ArenaItem.doChanllenge(container)
    if ArenaInfo.SelfInfo.surplusChallengeTimes <= 0 then
        MessageBoxPage:Msg_Box("@ERRORCODE_31201")
        return
    end
    ReadyToFightTeam = container
    local contentId = container.mID
    local itemInfo = ArenaInfo.DefendersInfos[contentId]

    local function sendChallengeDefender(rank)
        require("NewBattleConst")
        local msg = Battle_pb.NewBattleFormation()
        msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
        msg.battleType = NewBattleConst.SCENE_TYPE.PVP
        msg.defenderRank = rank
        nowRank = ArenaInfo.SelfInfo.rank
        challangeRank = rank
        common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)--true)
    end
    --require("NgBattleDataManager")
    if itemInfo.identityType == PlayerType.NPC then
        NgBattleDataManager_setArenaName(Language:getInstance():getString("@Monster_" .. string.format("%04d", itemInfo.rank % 500 + 9000)))
    else
        NgBattleDataManager_setArenaName(itemInfo.name) 
    end
    local icon = common:getPlayeIcon(isSelf and UserInfo.roleInfo.prof or 1, itemInfo.headIcon)
    NgBattleDataManager_setArenaIcon(icon)

    NgBattleDataManager_setDefenderRank(itemInfo.rank)
    sendChallengeDefender(itemInfo.rank)
end

function AreanItem_sendChallengeDefender(container)
    if type(container) ~= "userdata" then
        return
    end
    local contentId = container.mID
    local itemInfo = ArenaInfo.DefendersInfos[contentId]
    if itemInfo == nil then
        return
    end
    local msg = Arena_pb.HPChallengeDefender()
    if itemInfo.identityType == 1 then
        msg.monsterId = itemInfo.cfgItemId
    else
        msg.monsterId = 0
    end
    msg.defendeRank = itemInfo.rank
    pb_data = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.CHALLENGE_DEFENDER_C, pb_data, #pb_data, false)
    ArenaInfo.itemChangeName = itemInfo.name
    isGotoBattle = true
end

function ArenaItem.refreshPlayerIcon(container, itemInfo)
    local headNode = ScriptContentBase:create(mercenaryHeadContent.ccbiFile)
    local parentNode = container:getVarNode("mHeadNode")
    parentNode:removeAllChildren()
    mercenaryHeadContent:refreshItem(headNode, false, itemInfo)
    parentNode:addChild(headNode)
end

----------------------------------------------------------------------------------
local ArenaRankPageContent = { }
function ArenaRankPageContent:onMerHand(container)
    local contentId = self.id
    local itemInfo = ArenaInfo.rankingInfo[contentId]

    if itemInfo:HasField("mercenaryId") then
        local merId = itemInfo.mercenaryId
        PageManager.viewMercenaryInfo(itemInfo.playerId, merId)
    end
end

function ArenaRankPageContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local contentId = self.id
    local itemInfo = ArenaInfo.rankingInfo[contentId]

    local lb2Str = {
        mArenaName = itemInfo.name,
        mRankingNum = common:getLanguageString("@Ranking") .. GameUtil:formatDotNumber(itemInfo.rank),
        mFightingNum = GameUtil:formatDotNumber(itemInfo.fightValue),
        mPicRankingNum = itemInfo.rank,
    }

    NodeHelper:setStringForLabel(container, lb2Str)

    local pSprite = container:getVarSprite("mRankImage")
    if itemInfo.rank <= 3 then
        pSprite:setTexture(GameConfig.ArenaRankingIcon[itemInfo.rank])
        NodeHelper:setStringForLabel(container, { mRankText = itemInfo.rank })
        NodeHelper:setNodesVisible(container, { mRankText = false })
    else
        pSprite:setTexture(GameConfig.ArenaRankingIcon[4])
        NodeHelper:setStringForLabel(container, { mRankText = itemInfo.rank })
        NodeHelper:setNodesVisible(container, { mRankText = true })
    end

    self:refreshPlayerIcon(container, itemInfo)

    if itemInfo.identityType == PlayerType.NPC then
        NodeHelper:setStringForLabel(container, { mArenaName = Language:getInstance():getString("@Monster_" .. string.format("%04d", itemInfo.rank % 500 + 9000)) })
    end
end		

function ArenaRankPageContent:refreshPlayerIcon(container, itemInfo)
    local headNode = ScriptContentBase:create(mercenaryHeadContent.ccbiFile)
    local parentNode = container:getVarNode("mHeadNode")
    parentNode:removeAllChildren()
    mercenaryHeadContent:refreshItem(headNode, false, itemInfo)
    parentNode:addChild(headNode)
end	
	
-----------------------------------------------
-- ArenaPageBase页面中的事件处理
----------------------------------------------
function ArenaPageBase:onEnter(container)
    -- container:registerMessage(MSG_SEVERINFO_UPDATE)
    ArenaInfo.pageType = PageType.Arena
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container.scrollviewArenaContent = container:getVarScrollView("mArenaContent")
    container.mScrollViewRanking = container:getVarScrollView("mRankingContent")
    require("TransScenePopUp")
    TransScenePopUp_closePage()
    UserInfo.sync()
    roleConfig = ConfigManager.getRoleCfg()

    _isReceiveBattleInfo = true

    self:registerPacket(container)

    self:initArenaScrollView(container)

    self:selecetTab(container)

    if ArenaInfo.pageType == PageType.Arena then
        self:getInfo(container)
    elseif ArenaInfo.pageType == PageType.Ranking then
        self:showRank(container)
    end

    local PageJumpMange = require("PageJumpMange")
    if PageJumpMange._IsPageJump then
        if PageJumpMange._CurJumpCfgInfo._SecondFunc ~= "" then
            ArenaPageBase[PageJumpMange._CurJumpCfgInfo._SecondFunc](self, container)
        end
        if PageJumpMange._CurJumpCfgInfo._ThirdFunc == "" then
            PageJumpMange._IsPageJump = false
        end
    end

    OSPVPManager.reqLocalPlayerInfo( { UserInfo.playerInfo.playerId })

    local tmpCount = CCUserDefault:sharedUserDefault():getIntegerForKey("ArenaPage" .. UserInfo.playerInfo.playerId)
    if tmpCount == 0 then
        CCUserDefault:sharedUserDefault():setIntegerForKey("ArenaPage" .. UserInfo.playerInfo.playerId, 1)
    end

    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())

    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(true)

    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function ArenaPageBase:initPage(container)
    local rankingNum = ""
    local rewardStr = ""
    local fightNum = ""
    if ArenaDataPageInfo ~= nil then
        rankingNum = ArenaDataPageInfo.self.rank
        setRankReward(container, ArenaInfo.SelfInfo.rankAwardsStr)
    end

    local lb2Str = {
        mArenaName = UserInfo.roleInfo.name,
        mRankingNum = common:getLanguageString("@Ranking") .. GameUtil:formatDotNumber(rankingNum),
        mFightingNum = GameUtil:formatDotNumber(ArenaInfo.SelfInfo.fightValue),
        mRemainingChallengesNum = common:getLanguageString("@TodayTheNumberOfRemainingChallenges") .. ArenaInfo.SelfInfo.surplusChallengeTimes
    }
    NodeHelper:setStringForLabel(container, lb2Str)

    local icon, bgIcon = common:getPlayeIcon(UserInfo.roleInfo.prof, GameConfig.headIconNew or UserInfo.playerInfo.headIcon)
    NodeHelper:setSpriteImage(container, { mArenaPic = icon, mPicBg = bgIcon })

    if UserInfo.roleInfo.cspvpRank and UserInfo.roleInfo.cspvpRank > 0 then
        local stage = OSPVPManager.checkStage(UserInfo.roleInfo.cspvpScore, UserInfo.roleInfo.cspvpRank)
        NodeHelper:setSpriteImage(container, { mHeadFrame = stage.stageIcon })
    else
        NodeHelper:setSpriteImage(container, { mHeadFrame = GameConfig.QualityImage[1] })
    end
end

function ArenaPageBase:initArenaScrollView(container)
    container.mScrollViewArena = container:getVarScrollView("mArenaContent")
    container.mScrollViewRootNodeArena = container.mScrollViewArena:getContainer()
end

function ArenaPageBase:onExecute(container)
    if isGotoBattle then
        isGotoBattle = false
        ArenaInfo.itemChangeName = ""
    end

    if TimeCalculator:getInstance():hasKey(seasonCountDownKey) then
        local timer = TimeCalculator:getInstance():getTimeLeft(seasonCountDownKey)
        if timer > 0 then
            local day = math.floor(timer / 86400)
            timer = timer - day * 86400
            local hour = math.floor(timer / 3600)
            timer = timer - hour * 3600
            local min = math.floor(timer / 60)
            local timeStr = day .. common:getLanguageString("@Day") .. 
                            string.format("%02d", hour) .. common:getLanguageString("@Hour") .. 
                            string.format("%02d", min) .. common:getLanguageString("@Minute")
            NodeHelper:setStringForLabel(container, { mTime = common:getLanguageString("@LuckyMercenaryCloseTime", timeStr) })
        else
            NodeHelper:setStringForLabel(container, { mTime = (common:getLanguageString("@Day", 0) .. 
                                                               common:getLanguageString("@Hour", 0) .. 
                                                               common:getLanguageString("@Minute", 0)) })
        end
    end
end

function ArenaPageBase:onExit(container)
    challengeItemContainer = { }

    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    self:deleteScrollViewArena(container)
    self:deleteScrollViewRanking(container)
end

function ArenaPageBase:onReturn(container)
    PageManager.popPage(thisPageName)
end
----------------------------------------------------------------

function ArenaPageBase:deleteScrollViewArena(container)
    self:clearAllItem(container)
    container.mScrollViewRootNodeArena = nil
    container.mScrollViewArena = nil
end

function ArenaPageBase:deleteScrollViewRanking(container)
    self:clearAllRankingItem(container)
end

function ArenaPageBase:refreshPage(container)
    self:showPlayerInfo(container)
end

function ArenaPageBase:showPlayerInfo(container)
    setRankReward(container, ArenaInfo.SelfInfo.rankAwardsStr)
    local lb2Str = {
        mArenaName = UserInfo.roleInfo.name,
        mRankingNum = common:getLanguageString("@Ranking") .. GameUtil:formatDotNumber(ArenaInfo.SelfInfo.rank),
        mFightingNum = GameUtil:formatDotNumber(ArenaInfo.SelfInfo.fightValue),
        mRemainingChallengesNum = common:getLanguageString("@TodayTheNumberOfRemainingChallenges") .. ArenaInfo.SelfInfo.surplusChallengeTimes
    }

    NodeHelper:setStringForLabel(container, lb2Str)

    self:refreshPlayerIcon(container)
    self:refreshTeamIcon(container)

    if UserInfo.roleInfo.cspvpRank and UserInfo.roleInfo.cspvpRank > 0 then
        local stage = OSPVPManager.checkStage(UserInfo.roleInfo.cspvpScore, UserInfo.roleInfo.cspvpRank)
        NodeHelper:setSpriteImage(container, { mHeadFrame = stage.stageIcon })
    else
        NodeHelper:setSpriteImage(container, { mHeadFrame = GameConfig.QualityImage[1] })
    end
end		

function ArenaPageBase:refreshPlayerIcon(container)
    local headNode = ScriptContentBase:create(mercenaryHeadContent.ccbiFile)
    local parentNode = container:getVarNode("mHeadNode")
    parentNode:removeAllChildren()
    mercenaryHeadContent:refreshItem(headNode, true)
    parentNode:addChild(headNode)
end

function ArenaPageBase:refreshTeamIcon(container)
    local heroCfg = ConfigManager.getNewHeroCfg()
    for i = 1, 5 do
        local parent = container:getVarNode("mHeadNode" .. i)
        parent:removeAllChildrenWithCleanup(true)
        if ArenaInfo.SelfInfo.roleItemInfo[i] and ArenaInfo.SelfInfo.roleItemInfo[i].itemId > 0 then
            local option = {
                fight = ArenaInfo.SelfInfo.roleItemInfo[i].level,
                itemId = ArenaInfo.SelfInfo.roleItemInfo[i].itemId,
                quality = (ArenaInfo.SelfInfo.roleItemInfo[i].starLevel > 10 and 6) or (ArenaInfo.SelfInfo.roleItemInfo[i].starLevel < 6 and 4) or 5,
                element = heroCfg[ArenaInfo.SelfInfo.roleItemInfo[i].itemId].Element,
                skinId = ArenaInfo.SelfInfo.roleItemInfo[i].skinId,
                type = PlayerType.Player,
                cfg = heroCfg[ArenaInfo.SelfInfo.roleItemInfo[i].itemId]
            }
            NgHeadIconItem_Small:createCCBFileCell(option.itemId, i, parent, GameConfig.NgHeadIconSmallType.ARENA_PAGE, 1, nil, option)
        end
    end
end

function ArenaPageBase:selecetTab(container)
    if ArenaInfo.pageType == PageType.Arena then
        container:getVarMenuItemImage("mArena"):selected()
        container:getVarMenuItemImage("mRanking"):unselected()
        --self:clearAllRankingItem(container)
    elseif ArenaInfo.pageType == PageType.Ranking then
        container:getVarMenuItemImage("mArena"):unselected()
        container:getVarMenuItemImage("mRanking"):selected()
    end
    container:getVarScrollView("mArenaContent"):setVisible(ArenaInfo.pageType == PageType.Arena)
    container:getVarNode("mArenaContentNode"):setVisible(ArenaInfo.pageType == PageType.Arena)
    container:getVarNode("mArenaBtnNode"):setVisible(ArenaInfo.pageType == PageType.Arena)
    container.mScrollViewRanking:setVisible(ArenaInfo.pageType == PageType.Ranking)
    container:getVarNode("mRankingContentNode"):setVisible(ArenaInfo.pageType == PageType.Ranking)
    NodeHelper:setNodesVisible(container, { mSelectEffect1 = (ArenaInfo.pageType == PageType.Arena),
                                            mSelectEffect2 = (ArenaInfo.pageType == PageType.Ranking) })
end

function ArenaPageBase:getInfo(container)
    --
    CCLuaLog("ArenaPage:--------------getInfo")
    CCLuaLog("ArenaPage:--getInfo--getHPArenaDefenderListSyncSForLua")
    local isRequire = self:checkRequireData()
    if ArenaDataPageInfo == nil or ArenaDataPageInfo.self == nil or isRequire then
        container:registerPacket(HP_pb.ARENA_DEFENDER_LIST_SYNC_S)
        local msg = Arena_pb.HPArenaDefenderList()
        msg.playerId = UserInfo.playerInfo.playerId
        pb_data = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.ARENA_DEFENDER_LIST_C, pb_data, #pb_data, true)
    else
        self:onReceiveArenaInfo(container, ArenaDataPageInfo)
    end
end

function ArenaPageBase:checkRequireData()
    if TimeCalculator:getInstance():hasKey(seasonCountDownKey) then
        local timer = TimeCalculator:getInstance():getTimeLeft(seasonCountDownKey)
        local day1 = math.floor(timer / 86400)
        local day2 = math.floor(ArenaInfo.seasonTime / 86400)
        return day1 < 1 and day2 >= 1
    end
    return ArenaInfo.seasonTime <= 0
end

----------------scrollview-------------------------
function ArenaPageBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function ArenaPageBase:clearAllItem(container)
    if container.mScrollViewRootNodeArena then
        container.mScrollViewRootNodeArena:removeAllChildren()
    end
end

function ArenaPageBase:buildItem(container)
    challengeItemContainer = { }
    --ArenaPageBase:ScrollviewReSize(container)
    NodeHelper:buildVerticalScrollView(container.mScrollViewArena,
    container, #ArenaInfo.DefendersInfos, ArenaItem.ccbiFile, ArenaItem.onFunction)
    container.mScrollViewArena:setTouchEnabled(true)
end
function ArenaPageBase:ScrollviewReSize(container)
    container.mScrollViewArena:setViewSize(CCSizeMake(800, 900))
    container.mScrollViewArena:setPositionX(50)
end
----------------click event------------------------
function ArenaPageBase:showArena(container)
    if ArenaInfo.pageType == PageType.Arena then
        self:selecetTab(container)
        return
    end
    ArenaInfo.pageType = PageType.Arena
    self:selecetTab(container)
    self:getInfo(container)
end

function ArenaPageBase:showRank(container)
    if ArenaInfo.pageType == PageType.Ranking then
        self:selecetTab(container)
        return
    end
    ArenaInfo.pageType = PageType.Ranking
    self:selecetTab(container)
    self:getRankInfo(container)
end

function ArenaPageBase:purchaseTimes(container)
    ArenaPage_BuyTimes()
end


function ArenaPageBase:changeOpponet(container)
    local msg = Arena_pb.HPReplaceDefenderList()
    msg.playerId = UserInfo.playerInfo.playerId
    pb_data = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.REPLACE_DEFENDER_LIST_C, pb_data, #pb_data, true)
end	

function ArenaPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.ARENA_DEFENDER_LIST_SYNC_S then
        local msg = Arena_pb.HPArenaDefenderListSyncS()
        msg:ParseFromString(msgBuff)
        self:onReceiveArenaInfo(container, msg)
        self:initPage(container)

        local playerIds = { }
        for k = 1, #msg.defender, 1 do
            local defender = msg.defender[k]
            if defender.identityType == 2 then
                table.insert(playerIds, defender.playerId)
            end
        end
        if #playerIds > 0 then
            OSPVPManager.reqLocalPlayerInfo(playerIds)
        end
        return
    end

    if opcode == HP_pb.REPLACE_DEFENDER_LIST_S then
        local msg = Arena_pb.HPReplaceDefenderListRet()
        msg:ParseFromString(msgBuff)
        self:onReplaceDefenders(container, msg)
        return
    end

    if opcode == HP_pb.BUY_CHALLENGE_TIMES_S then
        local msg = Arena_pb.HPBuyChallengeTimesRet()
        msg:ParseFromString(msgBuff)
        self:buyTimesRet(container, msg)
        if chanllengeContainer ~= nil then
            ArenaItem.doChanllenge(chanllengeContainer)
            chanllengeContainer = nil
        end
        return
    end

    if container:getRecPacketOpcode() == HP_pb.ARENA_RANKING_LIST_S then
        local msg = Arena_pb.HPArenaRankingListRet()
        local msgBuff = container:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        ArenaRankCacheInfo = msg
        self:onReceiveRankInfo(container, msg)
        return
    end

    if opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            local battlePage = require("NgBattlePage")
            resetMenu("mBattlePageBtn", true)
            require("NewBattleConst")
            --require("NgBattleDataManager")
            PageManager.changePage("NgBattlePage")
            battlePage:onPvpChallange(container, msg.resultInfo, msg.battleId, msg.battleType, tonumber(msg.defenderRank))
        end
    end

    if opcode == HP_pb.CHALLENGE_DEFENDER_S then
        return
    end
end

function ArenaPageBase:onReceiveArenaInfo(container, msg)
    ArenaInfo.SelfInfo = msg.self
    -- arena buyed times
    ArenaAlreadyBuyTimes = msg.self.alreadyBuyTimes
    ArenaInfo.seasonTime = msg.leftTime
    if not TimeCalculator:getInstance():hasKey(seasonCountDownKey) then
        TimeCalculator:getInstance():createTimeCalcultor(seasonCountDownKey, ArenaInfo.seasonTime)
    end
    --
    for k = 1, #msg.defender, 1 do
        local defender = msg.defender[k]
        ArenaInfo.DefendersInfos[k] = defender
    end
    table.sort(ArenaInfo.DefendersInfos,
    function(e1, e2)
        if not e2 then return true end
        if not e1 then return false end

        return e1.rank < e2.rank
    end
    )
    ArenaBuyTimesInitCost = msg.self.nextBuyPrice
    self:refreshPage(container)
    self:rebuildAllItem(container)
end

function ArenaPageBase:onReceiveRankInfo(container, msg)
    if msg == nil or #msg.rankInfo == 0 then return end

    ArenaInfo.rankingInfo = msg.rankInfo
    ArenaInfo.SelfInfo = msg.self
    ArenaBuyTimesInitCost = msg.self.nextBuyPrice
    self:refreshPage(container)
    self:rebuildAllRankingItem(container)

    local playerIds = { }
    for i, v in ipairs(msg.rankInfo) do
        if v.identityType == 2 then
            table.insert(playerIds, v.playerId)
        end
    end
    if #playerIds > 0 then
        OSPVPManager.reqLocalPlayerInfo(playerIds)
    end
end

function ArenaPageBase:rebuildAllRankingItem(container)
    self:clearAllRankingItem(container)
    self:buildRankingItem(container)
end

function ArenaPageBase:clearAllRankingItem(container)
    container.mScrollViewRanking:removeAllCell()
end

function ArenaPageBase:buildRankingItem(container)
    local totalSize = #ArenaInfo.rankingInfo
    local items = NodeHelper:buildCellScrollView(container.mScrollViewRanking, totalSize, "ArenaRankingContent.ccbi", ArenaRankPageContent)
end

--------------------------------------------------------------

function ArenaPageBase:onReplaceDefenders(container, msg)
    local playerIds = { }
    for k = 1, #msg.defender, 1 do
        local defender = msg.defender[k]
        ArenaInfo.DefendersInfos[k] = defender
        ArenaDataPageInfo.defender[k] = defender
        if defender.identityType == 2 then
            table.insert(playerIds, defender.playerId)
        end
    end
    table.sort(ArenaInfo.DefendersInfos,
    function(e1, e2)
        if not e2 then return true end
        if not e1 then return false end

        return e1.rank < e2.rank
    end
    )
    self:rebuildAllItem(container)

    if #playerIds > 0 then
        OSPVPManager.reqLocalPlayerInfo(playerIds)
    end
end

function ArenaPageBase:buyTimesRet(container, msg)
    ArenaInfo.SelfInfo.surplusChallengeTimes = msg.surplusChallengeTimes
    container:getVarLabelTTF("mRemainingChallengesNum"):setString(common:getLanguageString("@TodayTheNumberOfRemainingChallenges") .. ArenaInfo.SelfInfo.surplusChallengeTimes)
    ArenaInfo.SelfInfo.nextBuyPrice = msg.nextBuyPrice
    ArenaBuyTimesInitCost = msg.nextBuyPrice
    ArenaDataPageInfo.self.surplusChallengeTimes = msg.surplusChallengeTimes
    ArenaDataPageInfo.self.alreadyBuyTimes = msg.alreadyBuyTimes
    -- arena buyed times
    ArenaAlreadyBuyTimes = msg.alreadyBuyTimes
end	

function ArenaPageBase:registerPacket(container)
    container:registerPacket(HP_pb.BATTLE_FORMATION_S)
    container:registerPacket(HP_pb.ARENA_DEFENDER_LIST_SYNC_S)
    container:registerPacket(HP_pb.REPLACE_DEFENDER_LIST_S)
    container:registerPacket(HP_pb.BUY_CHALLENGE_TIMES_S)
    container:registerPacket(HP_pb.ARENA_RANKING_LIST_S)
    container:registerPacket(HP_pb.ARENA_RANKING_LIST_S)
    container:registerPacket(HP_pb.CHALLENGE_DEFENDER_S)
end

function ArenaPageBase:removePacket(container)
    container:removePacket(HP_pb.BATTLE_FORMATION_S)
    container:removePacket(HP_pb.REPLACE_DEFENDER_LIST_S)
    container:removePacket(HP_pb.BUY_CHALLENGE_TIMES_S)
    container:removePacket(HP_pb.ARENA_RANKING_LIST_S)
    container:removePacket(HP_pb.ARENA_RANKING_LIST_S)

    container:removePacket(HP_pb.CHALLENGE_DEFENDER_S)
    container:removePacket(HP_pb.ARENA_DEFENDER_LIST_SYNC_S)
end

function ArenaPageBase:getRankInfo(container)
    local msg = Arena_pb.HPArenaRankingList()
    local pb_data = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.ARENA_RANKING_LIST_C, pb_data, #pb_data, true)
end

function ArenaPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == thisPageName then
            local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
            if extraParam == "EditTeam" then
                self:getInfo(container)
            else
                self:onReceiveArenaInfo(container, ArenaDataPageInfo)
            end
        elseif pageName == OSPVPManager.moduleName then
            local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
            if extraParam == OSPVPManager.onLocalPlayerInfo then
                if ArenaInfo.pageType == PageType.Arena then
                    self:getInfo(container)
                elseif ArenaInfo.pageType == PageType.Ranking then
                    if container.mScrollViewRanking then
                        container.mScrollViewRanking:refreshAllCell()
                    end
                end
                self:initPage(container)
            end
        end
    end
end

function ArenaPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_PVP)
end

function ArenaPageBase:onEditTeam(container)
    --require("EditMercenaryTeamPage")
    --EditMercenaryTeamBase_setOpenGroupIdx(8)
    --PageManager.pushPage("EditMercenaryTeamPage")
    require("NgBattleDataManager")
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.EDIT_DEFEND_TEAM)
    PageManager.pushPage("NgBattleEditTeamPage")
end

ArenaRankCacheInfo = Arena_pb.HPArenaRankingListRet()

function ArenaPage_Reset()
    ArenaRankCacheInfo = nil
    ArenaDataPageInfo = nil
end

function ArenaPage_getRank()
    return nowRank, challangeRank
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
ArenaPage = CommonPage.newSub(ArenaPageBase, thisPageName, option)


function ArenaPage_BuyTimes()
    -- 根据vip等级,判断剩余购买次数
    UserInfo.syncPlayerInfo()
    local costCfg = ConfigManager.getBuyCostCfg()
    local vipLevel = UserInfo.playerInfo.vipLevel

    local leftTime = 999
    local title = common:getLanguageString("@BuyTimesTitle")
    local message = common:getLanguageString("@BuyTimesArenaMsg")
    local buyedTimes = ArenaAlreadyBuyTimes or 0

    PageManager.showCountTimesArenaPage(title, message, leftTime,
    function(times)
        local totalPrice = 0

        for i = buyedTimes + 1, buyedTimes + times do
            local index = i
            if i > #costCfg then
                index = #costCfg
            end

            local costInfo = costCfg[index]
            if costInfo ~= nil then
                totalPrice = totalPrice + costInfo.arenaTimes
            end
        end

        return totalPrice
    end
    , Const_pb.MONEY_GOLD, toPurchaseTimes)
end

return ArenaPage
