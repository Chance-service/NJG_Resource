--排行榜面板
--点击主界面按钮显示

require "HP_pb"
require "ProfRank_pb"
local Const_pb = require("Const_pb")
local NewbieGuideManager = require("NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "ProfessionRankingPage"
local NodeHelper = require("NodeHelper")
local OSPVPManager = require("OSPVPManager")
local option = {
	ccbiFile = "FightingRankingPage.ccbi",
	handlerMap = {
        onRankAll               = "onRankAll",
        onWarrior					= "onWarrior",
        onHunter					= "onHunter",
        onMaster					= "onMaster",

		onHelp					= "onHelp",
		onReturnBtn			= "onReturn"
	},
	--opcode = opcodes
}
local ProfessionRankingPageBase = {buttonTable = {}}
local ProfessionRankingPageContent = {}
local titleManager = require("PlayerInfo.TitleManager")
local MonsterCfg = {}
local roleConfig = {}
local ProfessionType = {
	RANKALL = 1,
	WARRIOR = 2,
	HUNTER = 3,
	MASTER = 4,
}

local ProfessionName = {
	[ProfessionType.RANKALL] = "@RankAllTxt",
	[ProfessionType.WARRIOR] = "@ProfessionName_1",
	[ProfessionType.HUNTER] = "@ProfessionName_2",
	[ProfessionType.MASTER] = "@ProfessionName_3",
}

local PageInfo = {
	curProType = ProfessionType.RANKALL,--ProfessionType.WARRIOR,
	selfRank = "--",
	rankInfos = {},
	viewHolder = {}
	
}

local isFirstEnter = {
	[1] = true,
	[2] = true,
	[3] = true,
	[4] = true,
}


ProfessionRankingCacheInfo = {
	[1] = ProfRank_pb.HPProfRankingListRet(),
	[2] = ProfRank_pb.HPProfRankingListRet(),
	[3] = ProfRank_pb.HPProfRankingListRet(),
	[4] = ProfRank_pb.HPProfRankingListRet(),
}		
----------------------------------------------------
function ProfessionRankingPageContent:onRefreshContent( content )
	local container = content:getCCBFileNode()
	local contentId = self.id
	local itemInfo = PageInfo.rankInfos[contentId]
	
	local signature = ""
	signature = itemInfo.signature

	local prof = roleConfig[itemInfo.cfgItemId].profession  --职业
	 NodeHelper:setSpriteImage(container, { mProfession = GameConfig.ProfessionIcon[prof] })
	--NodeHelper:setNodesVisible(container,{ mProfession1 = prof==1, mProfession2 = prof==2, mProfession3 = prof==3, })
	
    --排名图片设置
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

	local lb2Str = {
		mLv 			= UserInfo.getOtherLevelStr(itemInfo.rebirthStage, itemInfo.level),
		mName			= itemInfo.name,
		mRankingNum		= common:getLanguageString("@Ranking") .. itemInfo.rank,
		mFightingNum	= common:getLanguageString("@Fighting") .. itemInfo.fightValue,
        mPicRankingNum  = itemInfo.rank,
		--mPersonalSignature		=  signature
	}
	NodeHelper:setBlurryString(container, "mPersonalSignature", signature, 400, 13)
	if itemInfo:HasField("allianceName") and itemInfo:HasField("allianceId") then
		lb2Str.mGuildName      = common:getLanguageString("@GuildLabel") .. itemInfo.allianceName .. "(ID " .. itemInfo.allianceId .. ")"   
		--NodeHelper:setColorForLabel(container,{mGuildName = "255 202 98"})
    else
        lb2Str.mGuildName      = common:getLanguageString("@GuildLabel") .. common:getLanguageString("@NoAlliance")
        --NodeHelper:setColorForLabel(container, { mGuildName = GameConfig.ColorMap.COLOR_RED })
	end
	NodeHelper:setStringForLabel(container, lb2Str)	

--[[    local showCfg = LeaderAvatarManager.getOthersShowCfg(itemInfo.avatarId)
	local icon = showCfg.icon[prof]]

	local  icon,bgIcon = common:getPlayeIcon(prof, itemInfo.headIcon)
	NodeHelper:setSpriteImage(container, { mPic = icon, mPicBg = bgIcon })
	
--[[	if itemInfo:HasField("roleItemId") then
        local merPic = nil
        --if itemInfo.level >= Const_pb.WINGS_OPEN_LEVEL then
	    --    merPic = roleConfig[itemInfo.roleItemId]["wingIcon"]
        --else
            merPic = roleConfig[itemInfo.roleItemId]["icon"]
        --end
	    NodeHelper:setSpriteImage(container, {mMerPic = merPic});
	end]]
	
   
	--NodeHelper:setSpriteImage(container, {mProfession = roleConfig[itemInfo.cfgItemId].proIcon});
	 local lb2StrNode = {
		mRankingTitle 			= "mRankingNum",
		mFightingTitle 				= "mFightingNum",
        mGuildLabel 				= "mGuildName"
	}

    NodeHelper:setLabelMapOneByOne(container, lb2StrNode, 5, true)
	--称号
	local nameNode = container:getVarLabelTTF("mName")
	local fontSize = VaribleManager:getInstance():getSetting("proRankTittleSize")
	titleManager:setBMFontLabelTittle(nameNode, itemInfo.title, fontSize, true)

    
    if itemInfo.cspvpRank and itemInfo.cspvpRank > 0 then
        local stage = OSPVPManager.checkStage(itemInfo.cspvpScore, itemInfo.cspvpRank)
        --NodeHelper:setNormalImages(container, { mHand = stage.stageIcon })
    else
        --NodeHelper:setNormalImages(container, { mHand = GameConfig.QualityImage[1] })
    end
end

function ProfessionRankingPageContent:onHand(container)
	local contentId = self.id
	local itemInfo = PageInfo.rankInfos[contentId]
	
	PageManager.viewPlayerInfo(itemInfo.playerId, true)
end

function ProfessionRankingPageBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
	for i = 0, 4 do
		isFirstEnter[i] = true
	end
	PageInfo.curProType = ProfessionType.RANKALL
	--NodeHelper:initScrollView( container,"mRankingBtnContent",4)
	ProfessionRankingPageBase.container = container
    ProfessionRankingPageBase.buttonTable = {}
    for i = 1, 4 do
        table.insert(ProfessionRankingPageBase.buttonTable, container:getVarMenuItemImage("mButton_" .. i))
	end

	self:initPage(container)
	self:selectTab(container, PageInfo.curProType)
	self:refreshPage(container)
	self:getPageInfo(container)
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_FIGHT_NUM)

    OSPVPManager.reqLocalPlayerInfo({ UserInfo.playerInfo.playerId })
end

function ProfessionRankingPageBase:initPage(container)
	self:registerPacket(container)
	UserInfo.sync()
	roleConfig = ConfigManager.getRoleCfg()
	container.scrollview = container:getVarScrollView("mRankingContent")
	NodeHelper:autoAdjustResizeScrollview(container.scrollview)
	--container.mScrollView:setBounceable(false)
	--self:buildScrollView(container)
	for i = 1, 2 do
		NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite" .. i))
	end
	--self:rebuildAllItem(container);
end

--构建标签页
function ProfessionRankingPageBase:buildScrollView(container)
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemWidth = 0
	local fOneItemHeight = 0
	local currentPos = 0
    
	for i = 1, #ProfessionName do
		local pItemData = CCReViSvItemData:new_local()		
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp((fOneItemWidth) * iCount, 0)
		
		if iCount < iMaxNode then
			ccbiFile = RankTypeContainer.ccbiFile
			local pItem = ScriptContentBase:create(ccbiFile)
			--pItem:release();
			pItem.id = iCount
			pItem:registerFunctionHandler(RankTypeContainer.onFunction)
			fOneItemHeight = pItem:getContentSize().height
			
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			currentPos = currentPos + fOneItemWidth
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end
	local size = CCSizeMake(fOneItemWidth * #ProfessionName, fOneItemHeight)
	container.mScrollView:setContentSize(size)
	container.mScrollView:setContentOffset(ccp(0, 0))
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
	container.mScrollView:forceRecaculateChildren()
	ScriptMathToLua:setSwallowsTouches(container.mScrollView)
	container.mScrollView:setTouchEnabled(false)
	container.mScrollView:setBounceable(false)
end

function ProfessionRankingPageBase:refreshPage(container)
	local lb2Str = {
         mName					= UserInfo.roleInfo.name,
		--mName					= UserInfo.getStageAndLevelStr() .. " " .. UserInfo.roleInfo.name,
        mLv = UserInfo.getStageAndLevelStr(),
		mRankingNum				= common:getLanguageString("@Ranking") .. PageInfo.selfRank,
		mFightingNum			= common:getLanguageString("@Fighting") .. UserInfo.roleInfo.marsterFight --UserInfo.roleInfo.fight
	}

	NodeHelper:setStringForLabel(container, lb2Str)
--[[    local showCfg = LeaderAvatarManager.getCurShowCfg()
	local headPic = showCfg.icon[UserInfo.roleInfo.prof]]
	local icon, bgIcon = common:getPlayeIcon(UserInfo.roleInfo.prof, GameConfig.headIconNew or UserInfo.playerInfo.headIcon)
	NodeHelper:setSpriteImage(container, { mPic = icon, mPicBg = bgIcon })

	--称号
	local nameNode = container:getVarLabelTTF("mName")
	local fontSize = VaribleManager:getInstance():getSetting("proRankMyTittleSize")
	titleManager:setBMFontLabelTittle(nameNode, titleManager.myNowTitleId, fontSize)

    if UserInfo.roleInfo.cspvpRank and UserInfo.roleInfo.cspvpRank > 0 then
        local stage = OSPVPManager.checkStage(UserInfo.roleInfo.cspvpScore, UserInfo.roleInfo.cspvpRank)
        --NodeHelper:setSpriteImage(container, { mHeadFrame = stage.stageIcon })
    else
        --NodeHelper:setSpriteImage(container, { mHeadFrame = GameConfig.QualityImage[1] })
    end
end

function ProfessionRankingPageBase:getPageInfo(container)
	if ProfessionRankingCacheInfo[PageInfo.curProType] ~= nil and #ProfessionRankingCacheInfo[PageInfo.curProType].rankInfo ~= 0 then
		self:onReceiveRankingInfo(container, ProfessionRankingCacheInfo[PageInfo.curProType])
		
		if isFirstEnter[PageInfo.curProType] == false then
			return
		end
	end	
	
	local msg = ProfRank_pb.HPProfRankingList()
	msg.profType = PageInfo.curProType - 1
	local pb_data = msg:SerializeToString()
	
	PacketManager:getInstance():sendPakcet(HP_pb.PROF_RANK_LIST_C, pb_data, #pb_data, true)
end

function ProfessionRankingPageBase:onExecute(container)
	
end

function ProfessionRankingPageBase:onExit(container)
	self:removePacket(container)
	NodeHelper:deleteScrollView(container)
end

function ProfessionRankingPageBase:onReturn(container)
	MainFrame_onMainPageBtn()
end

function ProfessionRankingPageBase:onWarrior(container, index)
	if PageInfo.curProType == ProfessionType.WARRIOR then
		ProfessionRankingPageBase:selectTab(container, index)
		return
	end
	PageInfo.curProType = ProfessionType.WARRIOR
	ProfessionRankingPageBase:selectTab(ProfessionRankingPageBase.container, ProfessionType.WARRIOR)
	ProfessionRankingPageBase:refreshPage(ProfessionRankingPageBase.container)
	ProfessionRankingPageBase:getPageInfo(ProfessionRankingPageBase.container)
	--self:rebuildAllItem(container)
end

function ProfessionRankingPageBase:onHunter(container, index)
	if PageInfo.curProType == ProfessionType.HUNTER then
		ProfessionRankingPageBase:selectTab(container, index)
		return
	end
	PageInfo.curProType = ProfessionType.HUNTER
	ProfessionRankingPageBase:selectTab(ProfessionRankingPageBase.container, ProfessionType.HUNTER)
	ProfessionRankingPageBase:refreshPage(ProfessionRankingPageBase.container)
	ProfessionRankingPageBase:getPageInfo(ProfessionRankingPageBase.container)
	--self:rebuildAllItem(container)
end

function ProfessionRankingPageBase:onMaster(container, index)
	if PageInfo.curProType == ProfessionType.MASTER then
		ProfessionRankingPageBase:selectTab(container, index)
		return
	end
	PageInfo.curProType = ProfessionType.MASTER
	ProfessionRankingPageBase:selectTab(ProfessionRankingPageBase.container, ProfessionType.MASTER)
	ProfessionRankingPageBase:refreshPage(ProfessionRankingPageBase.container)
	ProfessionRankingPageBase:getPageInfo(ProfessionRankingPageBase.container)
	--self:rebuildAllItem(container)
end

function ProfessionRankingPageBase:onRankAll(container, index)
	if PageInfo.curProType == ProfessionType.RANKALL then
		ProfessionRankingPageBase:selectTab(container, index)
		return
	end
	PageInfo.curProType = ProfessionType.RANKALL
	ProfessionRankingPageBase:selectTab(ProfessionRankingPageBase.container, ProfessionType.RANKALL)
	ProfessionRankingPageBase:refreshPage(ProfessionRankingPageBase.container)
	ProfessionRankingPageBase:getPageInfo(ProfessionRankingPageBase.container)
end

function ProfessionRankingPageBase:selectTab(container, index)
	
    for i = 1, #ProfessionRankingPageBase.buttonTable do
        if ProfessionRankingPageBase.buttonTable[i] then
            if index == i then
                ProfessionRankingPageBase.buttonTable[i]:setEnabled(false)
                --ProfessionRankingPageBase.buttonTable[i]:selected()
            else
                --ProfessionRankingPageBase.buttonTable[i]:unselected()
               ProfessionRankingPageBase.buttonTable[i]:setEnabled(true)
            end
        end
	end
    
    
--	for i = 1,#ProfessionName do
--		if RankTypeContainer.container[i] then
--			NodeHelper:setMenuItemSelected(RankTypeContainer.container[i], 
--				{ mRankBtn = i == index })
--		end
--	end

end

function ProfessionRankingPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_FIGHT_NUM)
end

function ProfessionRankingPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    
	if opcode == HP_pb.PROF_RANK_LIST_S then
		local msg = ProfRank_pb.HPProfRankingListRet()
		msg:ParseFromString(msgBuff)	
		ProfessionRankingCacheInfo[PageInfo.curProType] = msg
		isFirstEnter[PageInfo.curProType] = false
		self:onReceiveRankingInfo(container, msg)
		return
	end
end

function ProfessionRankingPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
		if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onLocalPlayerInfo then
                if container.scrollview then
                    container.scrollview:refreshAllCell()
                end
                self:refreshPage(container)
            end
		end
	end
end

function ProfessionRankingPageBase:onReceiveRankingInfo(container, msg)
	PageInfo.rankInfos = msg.rankInfo
	table.sort(PageInfo.rankInfos, function(p1, p2)
		if not p2 then return true end
		if not p1 then return false end
		
		return p1.rank > p2.rank
	end)
	
	if msg:HasField("selfRank") then
		if msg.selfRank == 0 then
            PageInfo.selfRank = common:getLanguageString("@NotInRanking")
        else
		    PageInfo.selfRank = msg.selfRank
        end
	else
		PageInfo.selfRank = "--"
	end
	local rank = ""
    if PageInfo.selfRank == 0 then
        rank = common:getLanguageString("@NotInRanking")
    else
		rank = PageInfo.selfRank
    end
	container:getVarLabelTTF("mRankingNum"):setString(common:getLanguageString("@Ranking") .. rank)
	
	self:rebuildAllItem(container)
	
    local playerIds = {}
    for i, v in ipairs(msg.rankInfo) do
        table.insert(playerIds, v.playerId)
    end
    OSPVPManager.reqLocalPlayerInfo(playerIds)
end

function ProfessionRankingPageBase:rebuildAllItem(container)
	self:clearAllItem(container)
	self:buildItem(container)
end

function ProfessionRankingPageBase:clearAllItem(container)
	local scrollview = container.scrollview
	scrollview:removeAllCell()
end

function ProfessionRankingPageBase:buildItem(container)
	local scrollview = container.scrollview
	local ccbiFile = "FightingRankingContent.ccbi"
	local totalSize = #PageInfo.rankInfos
	if totalSize == 0 then return end
	local spacing = 5
	local cell = nil	
	for i = 1, totalSize do
		cell = CCBFileCell:create()
		cell:setCCBFile(ccbiFile)
        local panel = common:new({ id = i }, ProfessionRankingPageContent)
		cell:registerFunctionHandler(panel)

		scrollview:addCell(cell)
		local pos = ccp(0, cell:getContentSize().height * (i - 1))
		cell:setPosition(pos)	
		
	end
	local size = CCSizeMake(cell:getContentSize().width, cell:getContentSize().height * totalSize)
	scrollview:setContentSize(size)
	scrollview:setContentOffset(ccp(0, scrollview:getViewSize().height - scrollview:getContentSize().height * scrollview:getScaleY()))
	scrollview:forceRecaculateChildren()
end

function ProfessionRankingPageBase:registerPacket(container)
	container:registerPacket(HP_pb.PROF_RANK_LIST_S)
end

function ProfessionRankingPageBase:removePacket(container)
	container:removePacket(HP_pb.PROF_RANK_LIST_S)
end

function ProfessionRankingPage_reset()
	ProfessionRankingCacheInfo = {}
end
----------------------------------------------------
local CommonPage = require("CommonPage")
ProfessionRankingPage = CommonPage.newSub(ProfessionRankingPageBase, thisPageName, option)
