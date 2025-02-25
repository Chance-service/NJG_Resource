local GVGManager = require("GVGManager")
local thisPageName = "GVGRankPage"

local GVGRankPageBase = {
    rankType = 1
}
 
local option = {
    ccbiFile = "GVGSpiritRankingPage.ccbi",
    handlerMap = {
        onReturnBtn = "onReturnBtn",
        onRankTodayBtn = "onRankTodayBtn",
        onRankNowBtn = "onRankNowBtn",
        onRankYesterdayBtn = "onRankYesterdayBtn",
        onHelp = "onHelp"
    },
    opcodes = {
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGSpiritRankingContent.ccbi",
    rankList = {}
}

local GoodItemsNewMatch   = {
    [1]  = {
        ["info"] = {itemType = 1,itemId = 1001,count = 300}
    },
    [2]  = {
        ["info"] = {itemType = 1,itemId = 1001,count = 100}
    },
    [3]  = {
        ["info"] = {itemType = 1,itemId = 1001,count = 50}
    }
}

local GoodItemsLastMatch   = {
    [1]  = {
        ["info"] = {itemType = 3,itemId = 104101,count = 300}
    },
    [2]  = {
        ["info"] = {itemType = 3,itemId = 104101,count = 150}
    },
    [3]  = {
        ["info"] = {itemType = 3,itemId = 104101,count = 50}
    },
     [4]  = {
        ["info"] = {itemType = 3,itemId = 104101,count = 20}
    }, 
    [5]  = {
        ["info"] = {itemType = 3,itemId = 104101,count = 10}
    }
}

local GVGEveryDayRewardTab   = nil
local GVGMatchRewardTab   = nil
local GVGMatchRewardTabNow   = nil
local GVGMatchRewardTabLast   = nil
local mGVGCityMapCfg = nil 

local GVGEveryDayRewardTabNow  = nil
local obtainScoreLevel1,obtainScoreLevel2,obtainScoreLevel3


local ItemContentUI = {
      ccbiFile = "GoodsItem_3.ccbi"
}


function ItemContentUI:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function ItemContentUI:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local reward = GVGEveryDayRewardTab[index].rewards[1]
    local resInfo = nil
    if reward then
        resInfo = ResManagerForLua:getResInfoByTypeAndId(reward.type, reward.itemId, reward.count)
    end
	local nameStr = ""
	if resInfo.type == Const_pb.SUIT_DRAWING then
		nameStr = ItemManager:getShowNameById(resInfo.itemId)
	else
		nameStr = resInfo.name
	end

	local lb2Str = {
		mName 	= nameStr,
		mNumber	= "x" ..resInfo.count
	};
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, {mPic = resInfo.icon}  , {mPic = GameConfig.EquipmentIconScale});
	NodeHelper:setQualityFrames(container, {mHand = resInfo.quality});
	--NodeHelper:setColor3BForLabel(itemNode, {mName = common:getColorFromConfig("Own")})
	NodeHelper:setColorForLabel(container,{mName = "255 240 215"})

    local colorMap = {}

   colorMap.mName =  ConfigManager.getQualityColor()[resInfo.quality].textColor
   colorMap.mNumber =   ConfigManager.getQualityColor()[resInfo.quality].textColor

   NodeHelper:setColorForLabel( container, colorMap )
end




function GVGInfoContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function GVGInfoContent:onPreLoad(ccbRoot)
end

function GVGInfoContent:onUnLoad(ccbRoot)
end

function GVGInfoContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local data = GVGInfoContent.rankList[index]
    if data then
       if  GVGRankPageBase.rankType == GVGManager.TODAY_RANK then --参戦者名单
            lb2Str.mRankNum = data.rank
            lb2Str.mID = data.id
            lb2Str.mGuildLv = "Lv." .. data.level
            lb2Str.mGuildName = data.name
            lb2Str.mVitalityNum = data.value
       elseif GVGRankPageBase.rankType == GVGManager.YESTERDAY_RANK then   --昔日王者
            lb2Str.mRankNum = data.rank
            lb2Str.mID = data.id
            lb2Str.mGuildLv = "Lv." .. data.level
            lb2Str.mGuildName = data.name
            lb2Str.mVitalityNum = data.score
       elseif  GVGRankPageBase.rankType == GVGManager.NOW_RANK then 
           local todayRankList = GVGManager.getRankList(GVGManager.TODAY_RANK)
           local maxNumber = 15
           if todayRankList and  #todayRankList > 16 then
                maxNumber = #todayRankList 
           end
           if todayRankList  then
                for i = 1, maxNumber do
                    local v = todayRankList[i]
                    if v.id ==  data.id then
                        lb2Str.mGuildLv = "Lv." .. v.level
                    end
                end
            end
            lb2Str.mRankNum = index
            lb2Str.mID = data.id
            lb2Str.mGuildName = data.guildName
            lb2Str.mVitalityNum = data.level3 * obtainScoreLevel3  + data.level2 * obtainScoreLevel2 + data.level1 * obtainScoreLevel1 
       end
    end

    NodeHelper:setNodesVisible(container,{mRankingNum1 = false,mRankingNum2 = false,mRankingNum3 = false,
		mRankingNum4 = false})
	if index > 3 then
		NodeHelper:setNodesVisible(container,{mRankingNum4 = true})--math.mod(index,2) == 1})
	else
		NodeHelper:setNodesVisible(container,{[string.format("mRankingNum%d",index)] = true})
	end

    --visibleMap.mRankingNum4 = index % 2 == 0

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGInfoContent:onViewGuildInfo(container)
    local index = self.index
    local data = GVGInfoContent.rankList[index]
    if data then
        --PageManager.viewAllianceTeamInfo(data.id)
    end
end

function GVGRankPageBase:createItem(index, rewardsreward)
    local reward = rewardsreward.rewards[1]
    local resInfo = nil
    if reward then
        resInfo = ResManagerForLua:getResInfoByTypeAndId(reward.type, reward.itemId, reward.count)
    end


	local itemNode = ScriptContentBase:create(ItemContentUI.ccbiFile, index)
	local nameStr = ""
	if resInfo.type == Const_pb.SUIT_DRAWING then
		nameStr = ItemManager:getShowNameById(resInfo.itemId)
	else
		nameStr = resInfo.name
	end

	local lb2Str = {
		mName 	= nameStr,
		mNumber	= "x" ..resInfo.count
	};
	NodeHelper:setStringForLabel(itemNode, lb2Str);
	NodeHelper:setSpriteImage(itemNode, {mPic = resInfo.icon}  , {mPic = GameConfig.EquipmentIconScale});
	NodeHelper:setQualityFrames(itemNode, {mHand = resInfo.quality});
	--NodeHelper:setColor3BForLabel(itemNode, {mName = common:getColorFromConfig("Own")})
	NodeHelper:setColorForLabel(itemNode,{mName = "255 240 215"})

    local colorMap = {}

   colorMap.mName =  ConfigManager.getQualityColor()[resInfo.quality].textColor
   colorMap.mNumber =   ConfigManager.getQualityColor()[resInfo.quality].textColor

   NodeHelper:setColorForLabel( itemNode, colorMap )

	itemNode:release()
	return itemNode
end

function GVGRankPageBase:displayItems(container, mScrollView, GVGEveryDayRewardTab, itemPage , nPreRowNum, fDistence)
    nPreRowNum = 1
    mScrollView:getContainer():removeAllChildren()
    mScrollView:setPositionY(mScrollView:getPositionY() - 10)
    local node = CCNode:create()
    local bOnePage = false
    if itemPage == 1 then
		bOnePage = true
	else
		bOnePage = false
	end
    local itemNode = nil
    local fwidth   = 0
    local fPosXInPage = 0
    local fPosX = 0
    local index = 0
    for i = 1, #GVGEveryDayRewardTab do


    local titleCell = CCBFileCell:create()
    local panel = ItemContentUI:new({id = i, index = i})
    titleCell:registerFunctionHandler(panel)
    titleCell:setCCBFile(ItemContentUI.ccbiFile)
    mScrollView:addCellBack(titleCell)







--		itemNode = GVGRankPageBase:createItem(i, GVGEveryDayRewardTab[i])
--        local reward = GVGEveryDayRewardTab[i].rewards[1]
--		itemNode:setTag(reward.itemId)
--		itemNode:registerFunctionHandler(GVGRankPageBase.onClickHandler)
--		local mHand = itemNode:getVarMenuItemImage("mHand")
--		fOneIconWidth = mHand:getContentSize().width
--		if bOnePage then
--			itemNode:setPosition(ccp(fOneIconWidth * (i - 1) + fOneIconWidth / 2 + (i - 1) * fDistence, 0))
--			fwidth = mHand:getContentSize().width * i + (i - 1) * fDistence
--			node:addChild(itemNode)
--		else
--			index = math.floor(i / nPreRowNum)
--			local resIndex = i - index * nPreRowNum
--			if i > (index * nPreRowNum) then
--				fPosXInPage = fOneIconWidth * (resIndex - 1) + fOneIconWidth / 2 + resIndex * fDistence
--				fPosX = fPosXInPage +  index * mScrollView:getViewSize().width
--			elseif i == index * nPreRowNum then
--				fPosXInPage = fOneIconWidth * (nPreRowNum - 1) + fOneIconWidth / 2 + nPreRowNum * fDistence
--				fPosX = (index - 1) * mScrollView:getViewSize().width + fPosXInPage
--			end
--			itemNode:setPosition(ccp(fPosX , fOneIconWidth / 2 + 45))
--			mScrollView:getContainer():addChild(itemNode)
--		end
    end
    mScrollView:orderCCBFileCells()
--    if bOnePage then
--        mScrollView:addChild(itemNode)
--        itemNode:setPosition(ccp(mScrollView:getViewSize().width / 2 - fwidth / 2, fOneIconWidth / 2 + 45))
--    else
--        local size = CCSizeMake(mScrollView:getViewSize().width * (itemPage - 1), mScrollView:getViewSize().height)
--	    mScrollView:setContentSize(size)
--    end
    mScrollView:setBounceable(true)
    if #GVGEveryDayRewardTab < 6 then
       mScrollView:setTouchEnabled(false)
    else
       mScrollView:setTouchEnabled(true)
    end
	
	--ScriptMathToLua:setSwallowsTouches(mScrollView)  
end

function GVGRankPageBase.onClickHandler(eventName, container)
   if eventName == "onHand" then
        local itemId = container:getTag()
        if itemId == nTipTag then
			GameUtil:hideTip()
			nTipTag = 0
			isTouchItem = true
			return
        end
        nTipTag = itemId
        for i = 1, #GVGEveryDayRewardTab do
        local reward = GVGEveryDayRewardTab[i].rewards[1]
            if reward.itemId == itemId then
				GameUtil:showTip(container:getVarMenuItemImage("mHand"), reward)
				isTouchItem = true
               break
            end
        end
    end
end
function GVGRankPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)

    local scrollview=container:getVarScrollView("mContent");
	if scrollview~=nil then
		--container:autoAdjustResizeScrollview(scrollview);
	end		
	
	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
	if mScale9Sprite ~= nil then
		--container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
	
	local mScale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
	if mScale9Sprite2 ~= nil then
		--container:autoAdjustResizeScale9Sprite( mScale9Sprite2 )
	end

    local mScale9Sprite3 = container:getVarScale9Sprite("mScale9Sprite3")
	if mScale9Sprite3 ~= nil then
		--container:autoAdjustResizeScale9Sprite( mScale9Sprite3 )
	end

end

function GVGRankPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    GVGManager.reqGVGConfig()
    --local scrollviewReward =container:getVarScrollView("mScrollviewReward");
	--if scrollviewReward~=nil then
		--container:autoAdjustResizeScrollview(scrollviewReward);
       --container.mScrollViewRootNode1 = scrollviewReward:getContainer();
	   --container.m_pScrollViewFacade1 = CCReViScrollViewFacade:new_local(scrollviewReward);
	   --container.m_pScrollViewFacade1:init(10, 3);
       --用于让每个item都有弹性，详见CCReViScrollViewFacade 
        --container.m_pScrollViewFacade1:setBouncedFlag(false);
	--end
    mGVGCityMapCfg = {} 
    mGVGCityMapCfg = ConfigManager.getGVGCfg()
    		
    local _mGVGEveryDayReward = ConfigManager.getGVGEveryDayRewardCfg();
    if GVGEveryDayRewardTab == nil  then
        GVGEveryDayRewardTab = {}
        for i= 1 ,#_mGVGEveryDayReward do
            GVGEveryDayRewardTab[i] = _mGVGEveryDayReward[i].rewards[1]
        end
    end

    local _mGVGMatchReward = ConfigManager.getGVGMatchRewardCfg();

    local serverTimeTab = os.date("!*t", localSeverTime - ServerOffset_UTCTime)

    local indexNow = 0 
    GVGMatchRewardTabNow   = nil
    GVGMatchRewardTabLast   = nil

     if GVGMatchRewardTabNow == nil and GVGMatchRewardTabLast == nil then
        GVGMatchRewardTabNow = {}
        GVGMatchRewardTabLast = {} 
        for i = 1 ,#_mGVGMatchReward do
             local dateTableStart,dateTableEnd = unpack(common:split(_mGVGMatchReward[i].date, ","));

             local dateStart,timeStart = unpack(common:split(dateTableStart, "_"));
             local yearStart,monthStart,dayStart = unpack(common:split(dateStart, "-"));
             local hourStart,minStart,secStart = unpack(common:split(timeStart, ":"));

             local dateEnd,timeEnd = unpack(common:split(dateTableEnd, "_"));
             local yearEnd,monthEnd,dayEnd = unpack(common:split(dateEnd, "-"));
             local hourEnd,minEnd,secEnd = unpack(common:split(timeEnd, ":"));


             yearStart,monthStart,dayStart,hourStart,minStart,secStart = tonumber(yearStart),tonumber(monthStart),tonumber(dayStart),tonumber(hourStart),tonumber(minStart),tonumber(secStart)
             yearEnd,monthEnd,dayEnd,hourEnd,minEnd,secEnd = tonumber(yearEnd),tonumber(monthEnd),tonumber(dayEnd),tonumber(hourEnd),tonumber(minEnd),tonumber(secEnd)

            local timeZone = os.difftime(os.time(), os.time(os.date("!*t", os.time())))
            local matchTimeStart = os.time({day=dayStart, month=monthStart, year = yearStart, hour=hourStart, min=minStart, sec=secStart}) -- 指定时间的时间戳
            matchTimeStart = matchTimeStart +  ServerOffset_UTCTime + timeZone 
            local matchTimeEnd = os.time({day=dayEnd, month=monthEnd, year = yearEnd, hour=hourEnd, min=minEnd, sec=secEnd}) -- 指定时间的时间戳
            matchTimeEnd = matchTimeEnd  +  ServerOffset_UTCTime + timeZone 

            if localSeverTime  > matchTimeStart and localSeverTime  <  matchTimeEnd then --当前赛季  上一个赛季
                indexNow = indexNow + 1  
                GVGMatchRewardTabNow[indexNow] = _mGVGMatchReward[i].rewards
                if i > 5  then
                    GVGMatchRewardTabLast[indexNow] = _mGVGMatchReward[i-5].rewards
                else 
                    GVGMatchRewardTabLast  = nil 
                end 
            end 
        end
    end


    local indexEveryDayNow = 0 
    GVGEveryDayRewardTabNow   = nil

     if GVGEveryDayRewardTabNow == nil then
        GVGEveryDayRewardTabNow = {}
        for i = 1 ,#_mGVGEveryDayReward do
             local dateTableStart,dateTableEnd = unpack(common:split(_mGVGEveryDayReward[i].date, ","));

             local dateStart,timeStart = unpack(common:split(dateTableStart, "_"));
             local yearStart,monthStart,dayStart = unpack(common:split(dateStart, "-"));
             local hourStart,minStart,secStart = unpack(common:split(timeStart, ":"));

             local dateEnd,timeEnd = unpack(common:split(dateTableEnd, "_"));
             local yearEnd,monthEnd,dayEnd = unpack(common:split(dateEnd, "-"));
             local hourEnd,minEnd,secEnd = unpack(common:split(timeEnd, ":"));


             yearStart,monthStart,dayStart,hourStart,minStart,secStart = tonumber(yearStart),tonumber(monthStart),tonumber(dayStart),tonumber(hourStart),tonumber(minStart),tonumber(secStart)
             yearEnd,monthEnd,dayEnd,hourEnd,minEnd,secEnd = tonumber(yearEnd),tonumber(monthEnd),tonumber(dayEnd),tonumber(hourEnd),tonumber(minEnd),tonumber(secEnd)

            local timeZone = os.difftime(os.time(), os.time(os.date("!*t", os.time())))
            local matchTimeStart = os.time({day=dayStart, month=monthStart, year = yearStart, hour=hourStart, min=minStart, sec=secStart}) -- 指定时间的时间戳
            matchTimeStart = matchTimeStart +  ServerOffset_UTCTime + timeZone 
            local matchTimeEnd = os.time({day=dayEnd, month=monthEnd, year = yearEnd, hour=hourEnd, min=minEnd, sec=secEnd}) -- 指定时间的时间戳
            matchTimeEnd = matchTimeEnd  +  ServerOffset_UTCTime + timeZone 

            if localSeverTime  > matchTimeStart and localSeverTime  <  matchTimeEnd then --当前赛季  上一个赛季
                indexEveryDayNow = indexEveryDayNow + 1  
                GVGEveryDayRewardTabNow[indexEveryDayNow] = _mGVGEveryDayReward[i].rewards
            end 
        end
    end


    --GVGRankPageBase:displayItems(container,scrollviewReward,GVGEveryDayRewardTab,1,1,20)
    if GVGManager.isGVGOpen then
        self:onRankTodayBtn(container)
    else
        GVGRankPageBase.rankType = GVGManager.TODAY_RANK
        self:refreshPage(container)
    end
end

function GVGRankPageBase:onExecute(container)

end

function GVGRankPageBase:onExit(container)
    self:removePacket(container)
end

function GVGRankPageBase:onRankTodayBtn(container)
    if GVGManager.isGVGOpen then
        GVGManager.reqVitalityRank()
    end
    if GVGRankPageBase.rankType == GVGManager.YESTERDAY_RANK or GVGRankPageBase.rankType == GVGManager.TODAY_RANK then
       container.mScrollView:removeAllCell()
    end
    GVGRankPageBase.rankType = GVGManager.TODAY_RANK
    self:refreshPage(container)
end

function GVGRankPageBase:onRankNowBtn(container)
    for k,v in pairs(mGVGCityMapCfg) do 
            if v.level == 1  then
            obtainScoreLevel1 = v.obtainScore
            elseif  v.level == 2 then
            obtainScoreLevel2 = v.obtainScore
            elseif v.level == 3 then 
            obtainScoreLevel3 = v.obtainScore
            end
    end
    local todayRankList = GVGManager.getRankList(GVGManager.TODAY_RANK)
    if GVGManager.isGVGOpen and todayRankList   then --没有参战名单的时候 不发请求直接显示天子奉戴未开启
        GVGManager.isFromRankReqMap = true 
        GVGManager.reqMapInfo()
    end
    if GVGRankPageBase.rankType == GVGManager.TODAY_RANK  or GVGRankPageBase.rankType == GVGManager.YESTERDAY_RANK then
       container.mScrollView:removeAllCell()
    end
    GVGRankPageBase.rankType = GVGManager.NOW_RANK
    self:refreshPage(container)
end

function GVGRankPageBase:onRankYesterdayBtn(container)
    --PageManager.pushPage("GVGMatchOverPage")
    GVGManager.reqYesterdayVitalityRank()
    if GVGRankPageBase.rankType == GVGManager.TODAY_RANK or GVGRankPageBase.rankType == GVGManager.TODAY_RANK then
       container.mScrollView:removeAllCell()
    end
    GVGRankPageBase.rankType = GVGManager.YESTERDAY_RANK
    self:refreshPage(container)
end

function GVGRankPageBase:onReturnBtn(container)
    --PageManager.changePage("GVGMapPage")
    GVGMatchRewardTabNow   = nil
    GVGMatchRewardTabLast   = nil
    GVGMatchRewardTabLast = nil 
    PageManager.popPage(thisPageName)
end

function GVGRankPageBase:onHelp(container)
    --PageManager.changePage("GVGMapPage")
    PageManager.showHelp(GameConfig.HelpKey.HELP_GVGLIST_INTRO);
end
function GVGRankPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGRankPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onTodayRank then
                if GVGRankPageBase.rankType == GVGManager.TODAY_RANK then
                    local mGVGOpenTxt = container:getVarLabelTTF("mGVGOpenTxt")
                     if mGVGOpenTxt then  mGVGOpenTxt:setVisible(false) end 
                     local mGVGLastMatchRankTxt = container:getVarLabelTTF("mGVGLastMatchTxt")
                     if mGVGLastMatchRankTxt then  mGVGLastMatchRankTxt:setVisible(false) end 
                    self:clearAndReBuildAllItem(container)
                end
            elseif extraParam == GVGManager.onYesterdayRank then
                if GVGRankPageBase.rankType == GVGManager.YESTERDAY_RANK then

                     local mGVGOpenTxt = container:getVarLabelTTF("mGVGOpenTxt")
                     if mGVGOpenTxt then  mGVGOpenTxt:setVisible(false) end 
                     local mGVGLastMatchRankTxt = container:getVarLabelTTF("mGVGLastMatchTxt")
                     if mGVGLastMatchRankTxt then  mGVGLastMatchRankTxt:setVisible(false) end 
                     self:clearAndReBuildAllItem(container)

                end
            end
        elseif pageName == thisPageName  then 
            if extraParam == GVGManager.onMapInfo then
                if GVGRankPageBase.rankType == GVGManager.NOW_RANK then

                    local mGVGOpenTxt = container:getVarLabelTTF("mGVGOpenTxt")
                    if mGVGOpenTxt then  mGVGOpenTxt:setVisible(false) end 
                    local mGVGLastMatchRankTxt = container:getVarLabelTTF("mGVGLastMatchTxt")
                    if mGVGLastMatchRankTxt then  mGVGLastMatchRankTxt:setVisible(false) end 
                    self:clearAndReBuildAllItem(container)

                end
            end
        end
	end
end

function GVGRankPageBase:refreshPage(container)
    local todayBtn = container:getVarMenuItem("mRankTodayBtn")
    local yesterdayBtn = container:getVarMenuItem("mRankYesterdayBtn")
    local nowBtn = container:getVarMenuItem("mRankNowBtn")

    if GVGRankPageBase.rankType == GVGManager.TODAY_RANK then
        local libStr = {}
        local spriteImg = {}
        local scaleMap = {}
        for i = 1 ,#GVGEveryDayRewardTabNow  do
            for j = 1 , #GVGEveryDayRewardTabNow[i]  do 
                local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGEveryDayRewardTabNow[i][j].type/10000,GVGEveryDayRewardTabNow[i][j].itemId,GVGEveryDayRewardTabNow[i][j].count)
                libStr['mGVGAwardNum'..i] = 'X'..resInfo.count
                spriteImg['mAwardPic'..i] = resInfo.icon
                scaleMap['mAwardPic'..i] = 0.6
            end
        end
        local  str   = common:getLanguageString("@GVGListIntro")
        libStr["mGVGListIntro"] = common:stringAutoReturn(str,26)
        NodeHelper:setSpriteImage(container,spriteImg,scaleMap)

        NodeHelper:setStringForLabel(container,libStr)
        NodeHelper:setNodesVisible(container,{mGVGOpenTxt = true,mGVGLastMatchTxt =false ,mTodayRankingTitle = true,mYesterRankingTitle = false,mTodayIntro = true,mYesterIntro = false,mNowIntro = false })
        todayBtn:selected()
        yesterdayBtn:unselected()
        nowBtn:unselected()
    elseif GVGRankPageBase.rankType == GVGManager.YESTERDAY_RANK then
        local libStr = {}
        local spriteImg = {}
        local scaleMap = {}
        if GVGMatchRewardTabLast then 
            for i = 1 ,#GVGMatchRewardTabLast  do
                  local str = nil
                  if #GVGMatchRewardTabLast[i] > 1 then 
                     str = FreeTypeConfig[10096].content;
                  else
                     str = FreeTypeConfig[10095].content;
                  end
                --local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTab[i].type/10000,GVGMatchRewardTab[i].itemId,GVGMatchRewardTab[i].count)
                    for j = 1 , #GVGMatchRewardTabLast[i]  do 
                        local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabLast[i][j].type/10000,GVGMatchRewardTabLast[i][j].itemId,GVGMatchRewardTabLast[i][j].count)
                        if  j > 1 then 
                           --libStr['mLastRewardName'..i] = libStr['mLastRewardName'..i] ..","..resInfo.name.."X"..resInfo.count
                           str = GameMaths:replaceStringWithCharacterAll(str, "#v3#", ","..resInfo.name.."X");
                           str = GameMaths:replaceStringWithCharacterAll(str, "#v4#", resInfo.count);
                        else 
                           str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", resInfo.name.."X");
                           str = GameMaths:replaceStringWithCharacterAll(str, "#v2#", resInfo.count);
                      
                       
                           --libStr['mLastRewardName'..i] =  resInfo.name.."X"..resInfo.count
                        end
                        --libStr['mOneMatchRewardNum'..i] = ''
                        --spriteImg['mOneMatchRewardPic'..i] = "UI/Mask/Image_Empty.png"
                        --scaleMap['mOneMatchRewardPic'..i] = 0.0
                    end
                    --NodeHelper:setNodesVisible(container,{['mLastRewardName'..i] = false})
                    local mLastRewardName = container:getVarLabelTTF('mLastRewardName'..i)
                    if mLastRewardName then
                         NodeHelper:addHtmlLable(mLastRewardName, str, 1001, CCSizeMake(500,20))
                    end
    --            else
    --                local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabLast[i][1].type/10000,GVGMatchRewardTabLast[i][1].itemId,GVGMatchRewardTabLast[i][1].count)
    --                libStr['mLastRewardName'..i] =  resInfo.name.."X"..resInfo.count
    --                libStr['mLastRewardName'..i] = resInfo.name
    --                libStr['mOneMatchRewardNum'..i] = 'X'..resInfo.count
    --                spriteImg['mOneMatchRewardPic'..i] = resInfo.icon
    --                scaleMap['mOneMatchRewardPic'..i] = 0.5
    --           end 
            end
        end 
        --[[for i= 0 , 5 do
            libStr['mOneMatchRewardNum'..i] = ''
            spriteImg['mOneMatchRewardPic'..i] = "UI/Mask/Image_Empty.png"
            scaleMap['mOneMatchRewardPic'..i] = 0.0
            NodeHelper:setNodesVisible(container,{['mLastRewardName'..i] = false})
        end]]--
        local  str   = common:getLanguageString("@GVGMatchListIntro")
        libStr["mOneMatchGVGListIntro"] = common:stringAutoReturn(str,30)
        NodeHelper:setSpriteImage(container,spriteImg,scaleMap)
        NodeHelper:setStringForLabel(container,libStr)
        NodeHelper:setNodesVisible(container,{mGVGOpenTxt = false,mGVGLastMatchTxt =true ,mTodayRankingTitle = false,mYesterRankingTitle = true,mTodayIntro = false,mYesterIntro = true,mNowIntro = false})
        todayBtn:unselected()
        yesterdayBtn:selected()
        nowBtn:unselected()
    elseif GVGRankPageBase.rankType == GVGManager.NOW_RANK then 
        local libStr = {}
        local spriteImg = {}
        local scaleMap = {}
       for i = 1 ,#GVGMatchRewardTabNow  do
            --if #GVGMatchRewardTabNow[i] > 1 then 
              local str = nil
              if #GVGMatchRewardTabNow[i] > 1 then 
                 str = FreeTypeConfig[10096].content;
              else
                 str = FreeTypeConfig[10095].content;
              end
            --local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTab[i].type/10000,GVGMatchRewardTab[i].itemId,GVGMatchRewardTab[i].count)
                for j = 1 , #GVGMatchRewardTabNow[i]  do 
                    local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabNow[i][j].type/10000,GVGMatchRewardTabNow[i][j].itemId,GVGMatchRewardTabNow[i][j].count)
                    if  j > 1 then 
                       --libStr['mLastRewardName'..i] = libStr['mLastRewardName'..i] ..","..resInfo.name.."X"..resInfo.count
                       str = GameMaths:replaceStringWithCharacterAll(str, "#v3#", ","..resInfo.name.."X");
                       str = GameMaths:replaceStringWithCharacterAll(str, "#v4#", resInfo.count);
                    else 
                       str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", resInfo.name.."X");
                       str = GameMaths:replaceStringWithCharacterAll(str, "#v2#", resInfo.count);
                    end
                    libStr['mNowMatchRewardNum'..i] = ''
                    spriteImg['mNowMatchRewardPic'..i] = "UI/Mask/Image_Empty.png"
                    scaleMap['mNowMatchRewardPic'..i] = 0.0
                end

                NodeHelper:setNodesVisible(container,{['mNowRewardName'..i] = false})
                local mNowRewardName = container:getVarLabelTTF('mNowRewardName'..i)
                if mNowRewardName then
                     NodeHelper:addHtmlLable(mNowRewardName, str, 1001, CCSizeMake(500,20))
                end
            --else
--                local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabNow[i][1].type/10000,GVGMatchRewardTabNow[i][1].itemId,GVGMatchRewardTabNow[i][1].count)
--                libStr['mNowRewardName'..i] =  resInfo.name.."X"..resInfo.count
--                libStr['mNowRewardName'..i] = resInfo.name
--                libStr['mNowMatchRewardNum'..i] = 'X'..resInfo.count
--                spriteImg['mNowMatchRewardPic'..i] = resInfo.icon
--                scaleMap['mNowMatchRewardPic'..i] = 0.5
--            end
        end

        local  str   = common:getLanguageString("@GVGMatchListIntro")
        libStr["mNowMatchGVGListIntro"] = common:stringAutoReturn(str,30)
        NodeHelper:setSpriteImage(container,spriteImg,scaleMap)
        NodeHelper:setStringForLabel(container,libStr)
        NodeHelper:setNodesVisible(container,{mGVGOpenTxt = true,mGVGLastMatchTxt =false ,mTodayRankingTitle = false,mYesterRankingTitle = true,mTodayIntro = false,mYesterIntro = false,mNowIntro = true})
        todayBtn:unselected()
        yesterdayBtn:unselected()
        nowBtn:selected()
    end
end

function GVGRankPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local rankList = {} 
    if  GVGRankPageBase.rankType == GVGManager.NOW_RANK then
        rankList  = GVGManager.getGuildCityMap()
    else
        rankList = GVGManager.getRankList(GVGRankPageBase.rankType)
        table.sort(rankList, function(a,b)
            return a.rank < b.rank
        end)
    end

    GVGInfoContent.rankList = rankList

    local maxNumber = 15
    if rankList and  #rankList > 16 then
        maxNumber = #rankList 
    end

    if #rankList > 1 then
        for i,v in ipairs(rankList) do
            if i<= maxNumber then
                local titleCell = CCBFileCell:create()
                local panel = GVGInfoContent:new({id = v.rank, index = i})
                titleCell:registerFunctionHandler(panel)
                titleCell:setCCBFile(GVGInfoContent.ccbiFile)
                container.mScrollView:addCellBack(titleCell)
            end
        end
        container.mScrollView:orderCCBFileCells()
    else
        if  GVGRankPageBase.rankType == GVGManager.YESTERDAY_RANK then 
             local mGVGLastMatchRankTxt = container:getVarLabelTTF("mGVGLastMatchTxt");
             mGVGLastMatchRankTxt:setVisible(true);
        end
    end
end

function GVGRankPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGRankPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGRankPage = CommonPage.newSub(GVGRankPageBase, thisPageName, option);