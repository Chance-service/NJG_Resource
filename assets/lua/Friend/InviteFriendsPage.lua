
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local json = require('json')
local NoticePage = require('NoticePage')

local thisPageName = 'InviteFriendsPage'
local InviteFriendsBase ={}
local option = {
	ccbiFile = "InviteFriendsPage.ccbi",
	handlerMap = {
		onCancel 					= 'onClose',
		onUnInvitedFriendsTab 	= 'onUnInvitedFriendsTab',
		onInvitedFriendsGiftTab 	= 'onInvitedFriendsGiftTab',
		onHelp						= "onHelp",
	}
}
local TabType = {
	INVITE = 1,
	GIFT = 2,
}
local PageInfo = {
	currentTab = TabType.INVITE,
	inviteTable = {},
	inviteCount = 0,
	inviteGiftDict = {	{num = 1,dict = "@InviteFriendsToUnlock1",pic ="Item/InviteReward01.png"},
						{num = 5,dict = "@InviteFriendsToUnlock5",pic ="Item/InviteReward04.png"},
						{num = 10,dict = "@InviteFriendsToUnlock10",pic ="Item/InviteReward02.png"},
						{num = 20,dict = "@InviteFriendsToUnlock20",pic ="Item/InviteReward05.png"},
						{num = 30,dict = "@InviteFriendsToUnlock30",pic ="Item/InviteReward06.png"},
						{num = 40,dict = "@InviteFriendsToUnlock40",pic ="Item/InviteReward03.png"},						
	},
}
local KakaoPicTab = {}
local isInviteFriend = false
---=============================================================================
--平台回调
local libPlatformListener = {}
--已经邀请的个数
function libPlatformListener:P2G_KR_GET_INVITE_COUNT(listener)

    if not listener then return end
    local strResult  = listener:getResultStr();
    local ResultTable = json.decode(strResult)
    PageInfo.inviteCount = ResultTable.count
    libPlatformManager:getPlatform():OnKrgetInviteLists()

end
--邀请列表
function libPlatformListener:P2G_KR_GET_INVITE_LIST(listener)
	if not listener then return end

    local strResult = listener:getResultStr()
    local strTable = json.decode(strResult)
	local inviteList = strTable.invitelist
	CCLuaLog("onKrgetInviteLists ============ lua info")
    --排除iOS平台错误
    if Golb_Platform_Info.is_entermate_platform and BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
        PageInfo.inviteTable = inviteList
    else
        PageInfo.inviteTable = json.decode(inviteList)
    end

	if isInviteFriend then
		CCLuaLog("onKrgetInviteLists ============after invite size = " .. #PageInfo.inviteTable)
		InviteFriendsBase:refreshPage(InviteFriendsBase.container,true)
	else
		CCLuaLog("onKrgetInviteLists ============after refresh size = " .. #PageInfo.inviteTable)
		InviteFriendsBase:refreshPage(InviteFriendsBase.container)
	end
	isInviteFriend = false
end
--发送邀请
function libPlatformListener:P2G_KR_SEND_INVITE(listener)

	if not listener then return end

    local strResult = listener:getResultStr()
    local strTable = json.decode(strResult)
	local resultStr = strTable.result
    --排除iOS平台错误
    if Golb_Platform_Info.is_entermate_platform and BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA ~= 2 then
        resultStr = json.decode(resultStr)
    end

	local str = ""
	local isSuccess = false
	if tonumber(resultStr.result) == 1000 then
		str = tostring(resultStr.error)
		isSuccess = true
	else
		str = tostring(resultStr.error)
	end

	if isSuccess then
		if InviteFriendsBase.inviteId and InviteFriendsBase.inviteContainer then
			
			PageInfo.inviteTable[InviteFriendsBase.inviteId].is_visible = "0"
			InviteFriendsBase.inviteContainer:getVarMenuItemImage("mInviteFriend"):setEnabled(false)
			PageInfo.inviteCount = PageInfo.inviteCount + 1
			InviteFriendsBase.container:getVarLabelTTF("mHadInvitedFriendsNum"):setString(common:getLanguageString("@HadInviteFriendsNum",PageInfo.inviteCount))
			PageManager.showNotice("",str,function() 
				
			end)
		end
	else
		PageManager.showNotice("",str,function() 

		end)
	end
	--[[
	PageManager.showNotice(common:getLanguageString("@InviteFriendTitle"),str
		,function() 
			libPlatformManager:getPlatform():OnKrGetInviteCount()
			--libPlatformManager:getPlatform():OnKrgetInviteLists()
		end)--]]
	CCLuaLog("libPlatformListener:onKrsendInvite resultStr")
	InviteFriendsBase.inviteId = nil
	InviteFriendsBase.inviteContainer = nil
	PageManager.popPage("DecisionPage")
end
--平台回调 end
---=============================================================================
function InviteFriendsBase.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		InviteFriendsBase.onRefreshItemView(container)
	elseif eventName == "luaHttpImgCompleted" then
		InviteFriendsBase.onHttpImgCompleted(container)	
	elseif eventName == "onInviteFriend" then
		InviteFriendsBase.onInviteFriend(container)		
	end
end

function InviteFriendsBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function InviteFriendsBase:onEnter(container)
	PageInfo.inviteTable = {}
	PageInfo.inviteCount = 0
	KakaoPicTab = {}
	isInviteFriend = false
	
	InviteFriendsBase.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)	
	libPlatformManager:getPlatform():OnKrGetInviteCount()
	InviteFriendsBase.container = container
	
	NodeHelper:initScrollView(container, "mContent", 10);
	self:selectTab(container)
	container:getVarLabelTTF("mHadInvitedFriendsNum"):setString(common:getLanguageString("@HadInviteFriendsNum",PageInfo.inviteCount))
	--test
	if Golb_Platform_Info.is_win32_platform then
		PageInfo.inviteTable =	{{
		is_visible=1,				
		hashed_talk_user_id="A973-vr33gM",
		nickname="공진배 cctv",		
		user_id_string="-89161778149670867",
		profile_image_url=""
		},
		{is_visible=0,				
		hashed_talk_user_id="A973-vr33gM",
		nickname="공진배",		
		user_id_string="-89161778149670867",		
		profile_image_url="",
		},}
		--[[
		PageInfo.inviteTable = json.decode("[{\"is_visible\":\"1\",\"supported_device\":true,\"nickname\":\"H지영\",\
		\"message_blocked\":false,\"hashed_talk_user_id\":\"AFEiyMgiUQA\",\"user_id\":\"-88300572241583040\",\"friend_nickname\":\"\",\"profile_image_url\":\"http:\/\/th-p.talk.kakao.co.kr\/th\/talkp\/wkihhAZT5e\/qRAeykBfcvilRC31Bn9AB0\/y3g0aq_110x110_c.jpg\"},\
		{\"is_visible\":\"1\",\"supported_device\":true,\"nickname\":\"June\",\"message_blocked\":false,\"hashed_talk_user_id\":\"AJcmNjYmlwA\",\
		\"user_id\":\"-88300572241358202\",\"friend_nickname\":\"\",\"profile_image_url\":\"http:\/\/th-p.talk.kakao.co.kr\/th\/talkp\/wkiHUSOZK8\/5ZCbB6qAm0632QHE51Jc7K\/t9ilgr_110x110_c.jpg\"}\
		\]")--]]
		self:refreshPage(container)
	end
	--test end
end

function InviteFriendsBase:selectTab(container)
	local menuSelect = {
		mUnInvitedFriendsTab = (PageInfo.currentTab == TabType.INVITE),
		mInvitedFriendsGiftTab = (PageInfo.currentTab == TabType.GIFT),
	}
	NodeHelper:setMenuItemSelected(container,menuSelect)
end

function InviteFriendsBase:onUnInvitedFriendsTab(container)
	if PageInfo.currentTab == TabType.INVITE then return end
	PageInfo.currentTab = TabType.INVITE
	self:selectTab(container)
	self:refreshPage(container)
end

function InviteFriendsBase:onInvitedFriendsGiftTab(container)
	if PageInfo.currentTab == TabType.GIFT then return end
	PageInfo.currentTab = TabType.GIFT
	self:selectTab(container)
	self:refreshPage(container)
end

function InviteFriendsBase.onInviteFriend(container)	
	local contentId = container:getItemDate().mID
	InviteFriendsBase.inviteId = contentId
	InviteFriendsBase.inviteContainer = container
	local inviteInfo = PageInfo.inviteTable[contentId]
	local nickname = inviteInfo.nickname
	local title = common:getLanguageString("@InviteFriendTitle")
	local msg = common:getLanguageString("@InviteFriendConfirmation",nickname)
	local user_id = inviteInfo.user_id_string
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 and Golb_Platform_Info.is_entermate_platform then
        user_id = inviteInfo.user_id
    end
	local serverId = GamePrecedure:getInstance():getServerID()
	CCLuaLog("InviteFriendsBase.onInviteFriend user_id:" .. user_id)
	CCLuaLog("InviteFriendsBase.onInviteFriend serverId:" .. serverId)
	PageManager.showConfirm(title,msg,function(confirm)
		if confirm then
			libPlatformManager:getPlatform():OnKrsendInvite(tostring(user_id),tostring(serverId))
			if Golb_Platform_Info.is_win32_platform then
				PageManager.showNotice(common:getLanguageString("@InviteFriendTitle"),"test",function() 
					libPlatformManager:getPlatform():OnKrGetInviteCount()
					--libPlatformManager:getPlatform():OnKrgetInviteLists()
					PageInfo.inviteTable[contentId].is_visible = 0
					InviteFriendsBase:refreshPage(InviteFriendsBase.container,true)
					PageManager.popPage("DecisionPage")
				end)
			end
		end
	end,false)
	isInviteFriend = true
end

function InviteFriendsBase:onExit(container)
	NodeHelper:deleteScrollView(container);
	if InviteFriendsBase.libPlatformListener then
		InviteFriendsBase.libPlatformListener:delete()
	end
end

function InviteFriendsBase:refreshPage(container,isRefreshInvite)
	if isRefreshInvite then
		container.m_pScrollViewFacade:refreshDynamicScrollView()
	else
		self:rebuildAllItem(container)
	end
	container:getVarLabelTTF("mHadInvitedFriendsNum"):setString(common:getLanguageString("@HadInviteFriendsNum",PageInfo.inviteCount))
end
function InviteFriendsBase:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function InviteFriendsBase:clearAllItem(container)
	container.m_pScrollViewFacade:clearAllItems();
	container.mScrollViewRootNode:removeAllChildren();
end

function InviteFriendsBase.onHttpImgCompleted(container)
	local contentId = container:getItemDate().mID
	local imgName = container:getHttpImgName()
	CCLuaLog("Get Inamge !!!!!!!!!onHttpImgCompleted!!!!!!!!!!"..imgName .. "contentId " .. contentId);
	if KakaoPicTab[contentId] and KakaoPicTab[contentId].fileName == imgName then
		NodeHelper:setHeadIcon(container,"mPic","httpImg/" .. imgName,88)
	end
end
function InviteFriendsBase.onRefreshItemView(container)
	local contentId = container:getItemDate().mID
	if PageInfo.currentTab == TabType.INVITE then
		local inviteInfo = PageInfo.inviteTable[contentId]
		local nickname = inviteInfo.nickname
		local imageUrl = inviteInfo.profile_image_url
		local is_visible = tonumber(inviteInfo.is_visible)
		
		local fileName = common:getHtmlImgName(imageUrl)
		KakaoPicTab[contentId] = {}
		KakaoPicTab[contentId].fileName = fileName
		KakaoPicTab[contentId].nickname = nickname
		if fileName == "" then
			NodeHelper:setHeadIcon(container,"mPic","UI/default_user.png",88)
		else
			if common:isKakaoImgExist(fileName) then
				NodeHelper:setHeadIcon(container,"mPic","httpImg/" .. fileName,88)
			else
				NodeHelper:setHeadIcon(container,"mPic","UI/default_user.png",88)
				container:addToHttpImgListener(fileName);
				HttpImg:getInstance():getHttpImg(imageUrl,fileName)
			end
		end
		container:getVarLabelTTF("mText1"):setString(nickname)

		container:getVarMenuItemImage("mInviteFriend"):setEnabled((is_visible == 1) and true or false)

	elseif PageInfo.currentTab == TabType.GIFT then
		local dictInfo = PageInfo.inviteGiftDict[contentId]
		if Golb_Platform_Info.is_win32_platform then
			PageInfo.inviteCount = 5
		end
		if PageInfo.inviteCount < dictInfo.num then
			container:getVarNode("mLock"):setVisible(true)
			container:getVarNode("mSeal"):setVisible(false)
		else
			container:getVarNode("mLock"):setVisible(false)
			container:getVarNode("mSeal"):setVisible(true)
		end
		NodeHelper:setSpriteImage(container,{mPic = dictInfo.pic})
		container:getVarLabelTTF("mText1"):setString(tostring(Language:getInstance():getString(dictInfo.dict)))
	end
end

function InviteFriendsBase:buildItem(container)
	local ccbFile = ""
	local size = 0
	if PageInfo.currentTab == TabType.INVITE then
		ccbFile = "InviteFriendsContent1.ccbi"
		size = #PageInfo.inviteTable
	elseif PageInfo.currentTab == TabType.GIFT then
		ccbFile = "InviteFriendsContent2.ccbi"
		size = #PageInfo.inviteGiftDict
	end
	
	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
	local fOneItemWidth = 0	
	--totolSize = 6
	for i=size, 1,-1 do
		local pItemData = CCReViSvItemData:new_local()		
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)
		
		if iCount < iMaxNode then
			local pItem = ScriptContentBase:create(ccbFile)			
			pItem.id = iCount
			pItem:registerFunctionHandler(InviteFriendsBase.onFunction)
			if fOneItemHeight < pItem:getContentSize().height then
				fOneItemHeight = pItem:getContentSize().height
			end
			
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end
	
	local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount)
	container.mScrollView:setContentSize(size)	
	container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))	
	
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView:forceRecaculateChildren();
end

function InviteFriendsBase:onClose(container)
	PageManager.popPage(thisPageName)
end

function InviteFriendsBase:onHelp(container)

end
local CommonPage = require('CommonPage')
local InviteFriendsPage= CommonPage.newSub(InviteFriendsBase, thisPageName, option)
