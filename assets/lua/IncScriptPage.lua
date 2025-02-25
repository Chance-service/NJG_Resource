local pageMap = {};

function RegisterLuaPage(pageName)
	if pageMap[pageName] == nil then
		registerScriptPage(pageName);
		pageMap[pageName] = 1;
	end
end

local deviceTable = {
	"iPhone3,1",
	"iPhone3,2",
	"iPhone3,3",
	"iPhone4,1",
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

local tPages = {}
local function registerInCoroutine( luaPage )
	local co = coroutine.create(function(  )
		registerScriptPage(luaPage)
	end)
	table.insert(tPages,co)
end
function dispatch()
	for i=1,#tPages do
		coroutine.resume(tPages[i])
	end
end

local OpenForIphone = VaribleManager:getInstance():getSetting("OpenForIphone")
--if bIsLowDevice==true and tonumber(OpenForIphone) == 1 then
if tonumber(OpenForIphone) == 1 then
	--主页面
	registerInCoroutine("MainScenePage")
	--战斗、聊天页面
	--registerInCoroutine("BattlePage")
	--选角色时提示
	registerInCoroutine("PromptPage");
	--选人页面
	registerInCoroutine("ChooseRolePage")
	--装备页面
	registerInCoroutine("EquipmentPage");
	--背包页面
	registerInCoroutine("PackagePage");
	--技能页面
	registerInCoroutine("SkillPage");
	--商城页面
	 registerInCoroutine("MarketPage");
	--佣兵页面
	registerInCoroutine("EquipMercenaryPage");
	--个人信息页面
	registerInCoroutine("PlayerInfoPage");
	--装备选择页面
	registerInCoroutine("EquipSelectPage");
	--多人团战页面
	registerInCoroutine("RegimentWarPage");
    --公会页面
	registerScriptPage("GuildPage");
	dispatch()
else
	--主页面
	registerScriptPage("MainScenePage")
	--战斗、聊天页面
	--registerScriptPage("BattlePage")
	--选角色时提示
	registerScriptPage("PromptPage");
	--选人页面
	registerScriptPage("ChooseRolePage")
	--装备页面
	registerScriptPage("EquipmentPage");
	--背包页面
	registerScriptPage("PackagePage");
	--技能页面
	registerScriptPage("SkillPage");
	--商城页面
	 registerScriptPage("MarketPage");
	--佣兵页面
	registerScriptPage("EquipMercenaryPage");
	--个人信息页面
	registerScriptPage("PlayerInfoPage");
	--装备选择页面
	registerScriptPage("EquipSelectPage");
	--多人团战页面
	registerScriptPage("RegimentWarPage");
	--竞技场页面
	registerScriptPage("ArenaPage");
	--礼包页面
	registerScriptPage("GiftPage");
	--邮件页面
	registerScriptPage("MailPage");
	--充值页面
	registerScriptPage("RechargePage");
	--帮助页面
	registerScriptPage("HelpPage");
	--熔炼页面
	registerScriptPage("MeltPage");
	--活动
	registerScriptPage("ActivityPage");
	registerScriptPage("LimitActivityPage");
	--registerScriptPage("MercenaryUpStepPage")
end
--语音聊天页面
registerInCoroutine("VoiceChatManager");


