----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local thisPageName = "GiftPage"
local hp = require("HP_pb")
local mission = require("Mission_pb")
local NewbieGuideManager = require("Guide.NewbieGuideManager")

local option = {
	ccbiFile = "GiftPopUp.ccbi",
	handlerMap = {
		onCDKExchange = "exchangeCDKey",
		onClose = "onClose",
		onHelp = "onHelp",
		onActivities = "onActivities",
		onLeftActivityBtn = "onLeftActivityBtn",
		onRightActivityBtn = "onRightActivityBtn",
	},
	opcode = opcodes
}

----------------- global data -----------------
-- 全局变量，用来接收服务器发来的礼包items
--GiftList = { }

-- 用于刚登陆的时候检查有没有收到礼包的数据
--GiftListReceived = false

function ResetGiftPage()
	GiftList = {}
	GiftListReceived = false
end

----------------- local data -----------------
local GiftPageBase = {}
local GiftCfg = ConfigManager.getGiftConfig() -- mission.txt
local NodeHelper = require("NodeHelper")

------------------------activity------------------------------
local totalSize = 0 -- 已开的全部活动
local nowActivityIndex = 1 -- 当前的活动Id
local activityTimeInterval = 3 -- 时间间隔
local activityTimeIntervalKey = "ActivityTimeIntervalKey" --计时器的key
local activityShowIds = nil -- 用来显示的活动
------------------------activity end--------------------------

------------------GiftItem content----------------------------
local GiftItem = {
	ccbiFile = "GiftContent.ccbi",
}

function GiftItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		GiftItem.onRefreshItemView(container)
	elseif eventName == "onRewardBtn" then
		GiftItem.onReceiveGift(container)
	end
end

function GiftItem.onRefreshItemView(container)
	local UserInfo = require("PlayerInfo.UserInfo")
	local index = container:getItemDate().mID
	local info = GiftList[index]
	if not info then return end

	local gift = GiftCfg[info.id]
	local lb2Str = {
		mGiftName = gift and gift.name or "",
		mNotReached = common:getLanguageString("@MissionNotDone")
	}
	-- rewards desc
	if gift and gift.reward then
		local rewardDesc = ""
		local rewards = {}
		-- type == 3 , 并且含有分号的奖励单独处理, 根据职业发奖
		if (gift.type == 2 or gift.type == 3 or gift.type == 5) and string.find(gift.reward, ";") then
			-- reward = 10000_1001_25;40000_1231_1_0,40000_1231_1_1,40000_1231_1_2
			rewards = Split(gift.reward, ";")
			if #rewards ~= 2 then
				rewardDesc = ""
			else
				-- basicReward =10000_1001_25
				local basicReward = rewards[1]
				local extraReward = rewards[2]
				reward1 = getResTable(basicReward)
				for i, r in ipairs(reward1) do
					local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(r.type), tonumber(r.itemId))
					if resInfo then
						rewardDesc = rewardDesc .. resInfo.name .. " x" .. tostring(r.count)
					end
				end
				--extraReward = 40000_1231_1_0,40000_1231_1_1,40000_1231_1_2
				reward2 = Split(extraReward, ",")
				-- r == 10000_999_3993_0
				for i, r in ipairs(reward2) do
					rew = Split(r, "_")
					if tonumber(rew[4]) and tonumber(rew[4]) == UserInfo.roleInfo.prof then
						local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(rew[1]), tonumber(rew[2]))
						if resInfo then
							--r2 gift list 物品奖励大于一个 增加逗号分割
							if Golb_Platform_Info.is_gNetop_platform then
								rewardDesc = rewardDesc .. "、" .. resInfo.name .. " x" .. tostring(rew[3])
							else
								rewardDesc = rewardDesc .. resInfo.name .. " x" .. tostring(rew[3])
							end
						end
						break
					end
				end
			end
		else
			-- 正常奖励，10000_1001_25 ...
			rewards = getResTable(gift.reward)
			for i, reward in ipairs(rewards) do
				local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(reward.type), tonumber(reward.itemId))
				if resInfo then
					if Golb_Platform_Info.is_gNetop_platform then
						if i > 1 then
							rewardDesc = rewardDesc .. "、" .. resInfo.name .. " x" .. tostring(reward.count)
						else
							rewardDesc = rewardDesc .. resInfo.name .. " x" .. tostring(reward.count)
						end
					else
						rewardDesc = rewardDesc .. resInfo.name .. " x" .. tostring(reward.count)
					end
				end
			end
		end
		
	--	local newStr =GameMaths:stringAutoReturnForLua(rewardDesc, 15, 0)
		lb2Str.mRewardTex = rewardDesc--newStr
	else
		lb2Str.mRewardTex = ""
	end
	local htmlNode = container:getVarLabelBMFont("mRewardTex")
	if htmlNode then
		local str = "<font color=\"#00E2FF\" face = \"HelveticaBD24\" >" .. lb2Str.mRewardTex .. "</font>"
        	local htmlLabel--泰语太长 修改htmlLabel的大小
        	if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
         		htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(380,96), str)
        	else
        		htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(380,96), str)
        	end
		
		htmlNode:setVisible(false)
		htmlLabel:setScale(htmlNode:getScale())
	end
	
	-- new feature: 显示 (第几天)
	if gift and (gift.type == 4 or gift.type == 3) then
		if gift.type == 4 and info.day == 8 then --8天及以上显示一个固定文本
			lb2Str.mGiftName = common:getLanguageString("@Lianxu_8", info.day)
		elseif info.day ~= 0 then
			lb2Str.mGiftName = gift.name .. common:getLanguageString("@MissionDay", info.day)
		end
	end
	NodeHelper:setStringForLabel(container, lb2Str)
	
	NodeHelper:setSpriteImage(container, {mRewardPic = gift and gift.icon or GameConfig.Image.DefaultGift})

	NodeHelper:setNodeVisible(container:getVarNode("mRewardBtnNode"), info.tag)

	NodeHelper:setNodeVisible(container:getVarLabelBMFont("mNotReached"), not info.tag)
end

-- 领取奖励
function GiftItem.onReceiveGift(container)
	local index = container:getItemDate().mID
	local info = GiftList[index]
	if not info then return end

	local msg = mission.HPMissionBonusC()
	msg.id = info.id
	local pb = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(hp.MISSION_BONUS_C, pb, #pb, false)
end

-----------------------------------------------
--GiftPageBase页面中的事件处理
----------------------------------------------
function GiftPageBase:onEnter(container)
	container:registerMessage(MSG_MAINFRAME_REFRESH)
	NodeHelper:initScrollView(container, "mContent", 4)

	activityShowIds = common:table_removeFromArray(ActivityInfo.ids, 99999) -- 未开活动干掉
	activityShowIds = common:table_removeFromArray(activityShowIds, 19)		-- 没有图片的活动干掉
	table.sort(activityShowIds, function(e1,e2) return e1 < e2 end)
	totalSize = #activityShowIds
	TimeCalculator:getInstance():createTimeCalcultor(activityTimeIntervalKey, activityTimeInterval)
	
	local visible = false
--[[	local platformInfo = PlatformRoleTableManager:getInstance():getPlatformRoleByName(GamePrecedure:getInstance():getPlatformName());
	local switch = GameConfig.platformSwitch[GamePrecedure:getInstance():getPlatformName()]	
	
	if switch and not switch.GiftCDK then
		visible = false
	else
		visible = true
	end--]]
	local pCDKNode = container:getVarNode("mCDkKey")
	if pCDKNode ~= nil then
		pCDKNode:setVisible(visible)
	end
	self:showActivityByIndex(container, nowActivityIndex)

	if GiftListReceived == false then
		self:requestMissionList(container)
	end
	self:refreshPage(container)
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_GIFT)
end

function GiftPageBase:onExecute(container)
	if TimeCalculator:getInstance():hasKey(activityTimeIntervalKey) and
	   tonumber(TimeCalculator:getInstance():getTimeLeft(activityTimeIntervalKey)) <= 0 then
		TimeCalculator:getInstance():createTimeCalcultor(activityTimeIntervalKey, activityTimeInterval)
		self:onRightActivityBtn(container)
	end
end
------------------------activity------------------------------
function GiftPageBase:showActivityByIndex(container, index)
	local activityId = activityShowIds[index]
	NodeHelper:setNodeVisible(container:getVarNode("mActivityNode"), totalSize ~= 0)
	if totalSize == 0 then
		self:showPicByIndex(container, 99999)
	else
		self:showPicByIndex(container, activityId)
	end
end

function GiftPageBase:showPicByIndex(container, index)
	if index ~= nil and ActivityConfig[index].image ~= nil then -- 增加对空判断，个别情况会出现为空，暂时找不到原因，添加一层判断
		require("Activity.ActivityConfig")
	end
	if not index then
		index = 99999
	end
	CCLuaLog("activity index = " .. index)
	if index == Const_pb.SHOOT_ACTIVITY then --气枪打靶
		local image = ActivityInfo.shootActivityRewardState == 1 and "UI/Activities/u_icoqySuitShoot.png" or "UI/Activities/u_icoqySuitShootNew.png"
		NodeHelper:setSpriteImage(container, { mActivityPic = image })
	else
		NodeHelper:setSpriteImage(container, { mActivityPic = ActivityConfig[index].image })
	end
--[[	if not Golb_Platform_Info.is_entermate_platform then
		NodeHelper:setStringForLabel(container,{
			mSelectText		= Language:getInstance():getString(ActivityConfig[index].dict)})
	else
		NodeHelper:setStringForLabel(container,{
			mSelectText		= ""})
	end--]]
end

function GiftPageBase:onLeftActivityBtn(container)
	nowActivityIndex = nowActivityIndex - 1
	if nowActivityIndex <= 0 then nowActivityIndex = totalSize end
	TimeCalculator:getInstance():createTimeCalcultor(activityTimeIntervalKey, activityTimeInterval)
	self:showActivityByIndex(container, nowActivityIndex)
end

function GiftPageBase:onRightActivityBtn(container)
	nowActivityIndex = math.max((nowActivityIndex + 1) % (totalSize + 1), 1)
	TimeCalculator:getInstance():createTimeCalcultor(activityTimeIntervalKey, activityTimeInterval)
	self:showActivityByIndex(container, nowActivityIndex)
end
------------------------activity end------------------------------
function GiftPageBase:onExit(container)
	GiftListReceived = false
	container:removeMessage(MSG_MAINFRAME_REFRESH)
	TimeCalculator:getInstance():removeTimeCalcultor(activityTimeIntervalKey)
	NodeHelper:deleteScrollView(container)
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_MAIN)
end

function GiftPageBase:onActivities(container)
	local activityId = activityShowIds[nowActivityIndex]
	PageManager.showActivity(activityId)
end
----------------------------------------------------------------

function GiftPageBase:refreshPage(container)
	--titles
	NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@GiftEverydayReward") })
	--scrollview
	if GiftList then
		self:rebuildAllItem(container)
	end
end
----------------scrollview-------------------------
function GiftPageBase:rebuildAllItem(container)
	self:clearAllItem(container)
	self:buildItem(container)
end

function GiftPageBase:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end

function GiftPageBase:buildItem(container)
	NodeHelper:buildScrollView(container, #GiftList, GiftItem.ccbiFile, GiftItem.onFunction)
end
	
----------------click event------------------------
function GiftPageBase:exchangeCDKey(container)
	PageManager.pushPage("CDKeyPage")
end

function GiftPageBase:onClose(container)
	PageManager.popPage(thisPageName)
    --TODO 主界面Boss礼包  弹出框 分享提示框Melt
--[[    if EFUNSHOWNEWBIE() and  Newbie.step ~= 0 and  Newbie.step ==  Newbie.getIdByTag("newbie_MainMelt") then
        Newbie.show(Newbie.getIdByTag("newbie_MainMelt"))
    end]]
end

function GiftPageBase:requestMissionList(container)
	local msg = mission.HPMissionListC()
	-- 0: 礼包数据
	-- 1: 充值数据
	msg.type = 0
	local pb = msg:SerializeToString()
	container:sendPakcet(hp.MISSION_LIST_C, pb, #pb, true)
end

function GiftPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == "GiftPage" then
			self:refreshPage(container)
		end
	end
end

function GiftPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_GIFT)
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
GiftPage = CommonPage.newSub(GiftPageBase, thisPageName, option)
