----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local PageInit = {}

-- 需要声明的全部lua
PageInit.pageRequire = {
	"Login_pb",
	"GameUtil",
	"PackageLogicForLua",
	"IncPbCommon",
	"ListenMessage",
	"HP_pb",
	"Player_pb",
	"Reward_pb",
	"Notice_pb",
	"MessageFlowPopPage",
	"Chat_pb",
	"SysProtocol_pb",
	"Battle_pb",
	"Friend_pb",
	"Consume_pb",
	"Const_pb",
	"Mission_pb",
	"Alliance_pb",
	"Shop_pb",
	"Item_pb",
	"GameConfig",
	"Equip.EquipOprHelper",
	"Chat.ChatManager",
	"Skill.SkillManager",
	"NodeHelper",
	"ConfigManager",
	"PageManager",
	"Equip.EquipManager",
	"Activity.ActivityInfo",
	"PlayerInfo.ViewPlayerInfo",
	"Equip.UserEquipManager",
	"ResManagerForLua",
	"Battle.VoiceChatManager",
}

-- 需要注册的全部页面
PageInit.pageRegisterAll = {
	"MainScenePage",
	"PromptPage",
	"ChooseRolePage",
	"EquipmentPage",
	"PackagePage",
	"SkillPage",
	"MarketPage",
	"PlayerInfoPage",
	"EquipSelectPage",
	"RegimentWarPage",
	"ArenaPage",
	"GiftPage",
	"MailPage",
	"RechargePage",
	"HelpPage",
	"MeltPage",
	"GuildPage",
	"ActivityPage",
	--"MercenaryUpStepPage",
}

--适配iphone，只注册所需的一小部分页面，其余部分进入页面的时候再注册
PageInit.pageRegisterIphone = {
	"MainScenePage",
	"PromptPage",
	"ChooseRolePage",
	"EquipmentPage",
	"PackagePage",
	"SkillPage",
	"MarketPage",
	"PlayerInfoPage",
	"EquipSelectPage",
	"RegimentWarPage",
}

--------------------------------------- judge phone ----------------------------
-- 用来区分iphone设备，http://en.wikipedia.org/wiki/List_of_iOS_devices
local deviceTable = {
	"iPhone3,1",	-- iphone4
	"iPhone3,2",	-- iphone4
	"iPhone3,3",	-- iphone4
	"iPhone4,1",	-- iphone4s
}
local platformInfo = libOS:getInstance():getPlatformInfo()
local posOfFirstUnderline = string.find(platformInfo, "#") or 1
local iosDeviceName = string.sub(platformInfo,1,posOfFirstUnderline-1)
local bIsLowDevice = false 

table.foreach(deviceTable, function(i, v)
	if iosDeviceName == v then
		bIsLowDevice = true
	else
		bIsLowDevice = false
	end
end)
-------------------------------------- register & require pages ------------------
-- require 全部page
local coRequirePages = {}
-- 建立协同方法，将需要require的页面都放入协同方法
function PageInit:requirePagesCoCreate()
	for i=1, #PageInit.pageRequire do
		local co = coroutine.create(function()
			require(PageInit.pageRequire[i])
		end)
		table.insert(coRequirePages, co)
	end
end
-- require全部的页面
function PageInit:requirePagesRun()
	self:requirePagesCoCreate()
	for i=1,#coRequirePages do
		coroutine.resume(coRequirePages[i])
	end
end

-- 建立协同方法，将需要register的页面都放入协同方法。全部的page
local coRegisterPages = {}
function PageInit:registerPagesCoCreate()
	for i=1, #PageInit.pageRegisterAll do
		local co = coroutine.create(function()
			registerScriptPage(PageInit.pageRegisterAll[i])
		end)
		table.insert(coRegisterPages, co)
	end
end
-- 建立协同方法，将需要register的页面都放入协同方法。针对iphone的
function PageInit:registerIphonePagesCoCreate()
	for i=1, #PageInit.pageRegisterIphone do
		local co = coroutine.create(function()
			registerScriptPage(PageInit.pageRegisterIphone[i])
		end)
		table.insert(coRegisterPages, co)
	end
end

-- 是否做iphone适配的开关，在variable.txt里配置
local OpenForIphone = VaribleManager:getInstance():getSetting("OpenForIphone")
-- register页面
function PageInit:registerPagesRun()
	if bIsLowDevice == true and 
		tonumber(OpenForIphone) == 1 then
		self:registerIphonePagesCoCreate()
	else
		--self:registerPagesCoCreate()
        self:registerIphonePagesCoCreate()
	end
	for i=1,#coRegisterPages do
		coroutine.resume(coRegisterPages[i])
	end
end

return PageInit