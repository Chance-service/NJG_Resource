-- encoding UTF-8 without BOM
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

-- avoid memory leak
collectgarbage("setpause", 200)
collectgarbage("setstepmul", 100)

setmetatable(CCPoint.tolua_ubox, {__mode = "v"})
setmetatable(ccColor3B.tolua_ubox, {__mode = "v"})
setmetatable(CCRect.tolua_ubox, {__mode = "v"})
setmetatable(CCSize.tolua_ubox, {__mode = "v"})

local findedObjMap = nil   
function _G.findObject(obj, findDest)  
    if findDest == nil then  
        return false  
    end  
    if findedObjMap[findDest] ~= nil then  
        return false  
    end  
    findedObjMap[findDest] = true  
  
    local destType = type(findDest)  
    if destType == "table" then  
        if findDest == _G.CMemoryDebug then  
            return false  
        end 
        local metables = getmetatable(findDest)
        if metables and(metables.__mode == "k" or metables.__mode == "v" or metables.__mode == "kv") then
        	return false
        end
        for key, value in pairs(findDest) do  
            if key == obj or value == obj then  
                print("Finded Object")  
                return true  
            end  
            if findObject(obj, key) == true then  
                print("table key")  
                return true  
            end  
            if findObject(obj, value) == true then  
                print("key:["..tostring(key).."]")  
                return true  
            end  
        end  
    elseif destType == "function" then  
        local uvIndex = 1  
        while true do  
            local name, value = debug.getupvalue(findDest, uvIndex)  
            if name == nil then  
                break  
            end  
            if findObject(obj, value) == true then  
                print("upvalue name:["..tostring(name).."]")  
                return true  
            end  
            uvIndex = uvIndex + 1  
        end  
    end  
    return false  
end  
  
function _G.findObjectInGlobal(obj)  
    findedObjMap = {}  
    setmetatable(findedObjMap, {__mode = "k"})  
    _G.findObject(obj, _G)  
end  

-- 引入其他module，注意顺序有依赖
local dirs = {
	'include',
	'Activity','Arena','Battle','Chat','Equip',
	'Friend','Guide','Guild','Item','Mail',
	'Mercenary','PlayerInfo','PVP','Recharge','Skill','protobuf','Element',
	'Wing',"Mission"
}
local pathTB = { }
for _, dir in ipairs(dirs) do
	table.insert(pathTB, string.format(".\\lua\\%s\\?.lua", dir))
end
package.path = package.path .. ".\\lua\\?.lua;" .. table.concat(pathTB, ";")

Golb_Platform_Info = {
	is_r2_platform = false,
	is_efun_platform = false,
	is_entermate_platform = false,
	is_win32_platform = false,
	is_gNetop_platform = false,
	is_gNetop_amazon_platform = false,
	is_yougu_platform = true,
	is_longXiao_platform = false,
	is_Android = false, --android
	is_amz = false,
	is_google = false,
	is_h365 = false, --android_h365
	is_r18 = false, --android_hutuo
	is_jgg = false, --android_jgg
    	is_kuso = false, --android_kuso
}
local platformName = GamePrecedure:getInstance():getPlatformName()
local resourcePath = GamePrecedure:getInstance():getWin32ResourcePath()

if string.find(platformName, "r2") or string.find(platformName, "R2") then
	--Golb_Platform_Info.is_r2_platform = true
elseif string.find(platformName, "efun") then
	Golb_Platform_Info.is_efun_platform = true
elseif string.find(platformName, "entermate") then
	Golb_Platform_Info.is_entermate_platform = true
elseif string.find(platformName, "win32") then
	Golb_Platform_Info.is_win32_platform = true
	if resourcePath == "android_R2Game_en" then
		--Golb_Platform_Info.is_r2_platform = true
		Golb_Platform_Info.is_gNetop_platform = true
		CCLuaLog("getWin32ResourcePath = Golb_Platform_Info.is_r2_platform = true")
	elseif resourcePath == "android_gNetop" or resourcePath == "android_gNetop_japan" then
		Golb_Platform_Info.is_gNetop_platform = true
		CCLuaLog("getWin32ResourcePath = Golb_Platform_Info.is_gNetop_platform = true")
	elseif resourcePath == "android_Entermate" then
		CCLuaLog("getWin32ResourcePath = Golb_Platform_Info.android_Entermate = true")
		Golb_Platform_Info.is_entermate_platform = true
	end
elseif string.find(platformName, "sanguo") then
	Golb_Platform_Info.is_gNetop_platform = true
elseif string.find(platformName, "amazon") then
	Golb_Platform_Info.is_gNetop_platform = true
	Golb_Platform_Info.is_gNetop_amazon_platform = true
elseif string.find(platformName, "ryuk") then
	Golb_Platform_Info.is_gNetop_platform = true
end

if string.find(platformName, "android_r18") then  --工口
    Golb_Platform_Info.is_Android = true
    Golb_Platform_Info.is_google = true
    Golb_Platform_Info.is_r18 = true
end

if string.find(platformName, "android_h365") then  --h365
    Golb_Platform_Info.is_Android = true
    Golb_Platform_Info.is_google = true
    Golb_Platform_Info.is_h365 = true
end

if string.find(platformName, "android_jgg") then  --jgg
    Golb_Platform_Info.is_Android = true
    Golb_Platform_Info.is_google = true
    Golb_Platform_Info.is_jgg = true
end

if string.find(platformName, "android_kuso") then  --kuso
    Golb_Platform_Info.is_Android = true
    Golb_Platform_Info.is_google = true
    Golb_Platform_Info.is_kuso = true
end

if string.find(platformName, "ios_r18") then  --工口
    Golb_Platform_Info.is_r18 = true
end

if string.find(platformName, "ios_h365") then  --h365
    Golb_Platform_Info.is_h365 = true
end

if string.find(platformName, "aws_r18") then      --亚马逊
    Golb_Platform_Info.is_Android = true
end

if string.find(platformName, "aws_r18") then
    Golb_Platform_Info.is_amz = true
end

Golb_Platform_Info.is_gNetop_platform = true

-- TODO: 日本iOS免費送月卡
GnetopFreeMonthIsOpen = false-- 1:活动开启,0:活动关闭
--东八区(台灣)时间偏移 如果接收不到服务器的时区差 用东八区的时间
ServerOffset_UTCTime = -8 * 3600

-- 初始化
common = require("common");

HeartBeatMaxCount = 5 --5秒额外发送一次心跳包

local OpenCoroutine = VaribleManager:getInstance():getSetting("OpenCoroutine")
if tonumber(OpenCoroutine) == 1 then
--	local PageInit = require("PageInit")
--	PageInit:requirePagesRun()
--	PageInit:registerPagesRun()
 --强制 加载部分 （移除全部 加载 ）  glj 2019
    require "Login_pb"

	require("GameUtil");
	require("PackageLogicForLua");
	require("IncPbCommon");
	require("ListenMessage");
	require("IncScriptPage");
else
	require "Login_pb"

	require("GameUtil");
	require("PackageLogicForLua");
	require("IncPbCommon");
	require("ListenMessage");
	require("IncScriptPage");
	
end
--主页响应处理
require("MainFrameScript")
--TODO :新手引导部分
require("Guide.AppConfig");

--------------------------------------------------------------------------------
-- 本module导出的全局变量
-- Variables
-- json = require('json')
--------------------------------------------------------------------------------
-- 本module内部的局部变量、函数

-- Variables
local isFirstUpdate = true
local isNeedRestart = false
local NeedRestartKey = "NeedRestartKey"
local NeedRestartTime = 10
-- 当前的playerId serverId,用于判断是否需要reset，如果是同样的id,不用reset数据，如果不同需要reset
-- g_curPlayerId = 0
-- g_curServerId = 0

local resVersion = "1.0.0"

-- updateHandler can be removed after big version update
local updateHandler = { }

function requestPackages()
	-- if isFirstUpdate then
	if string.find(GamePrecedure:getInstance():getPlatformName(), "entermate") then
		local UserInfo = require("PlayerInfo.UserInfo")
		UserInfo.serverId = GamePrecedure:getInstance():getServerID()
		if UserInfo.roleInfo and UserInfo.roleInfo.level and UserInfo.roleInfo.level > 0 then
			libOS:getInstance():OnUserInfoChange(UserInfo.playerInfo.playerId, UserInfo.roleInfo.name, UserInfo.serverId, UserInfo.roleInfo.level, UserInfo.roleInfo.exp, UserInfo.playerInfo.vipLevel, UserInfo.playerInfo.gold)
		end
		libPlatformManager:getPlatform():OnKrLoginGames()
	end

	if Golb_Platform_Info.is_r2_platform then
		-- 发送评分 请求
		require("HP_pb")
		require("Player_pb")
		local msg = Player_pb.HPCommentMsg()
		msg.type = 3
		local pb_data = msg:SerializeToString()
		PacketManager:getInstance():sendPakcet(HP_pb.ROLE_GAME_COMMENT_C, pb_data, #pb_data, false)
	end
	-- checkVersionState()
	-- add by huangke require severtime off set of UTC time	
	local HP_pb = require "HP_pb"
	local Time_pb = require "SysProtocol_pb"
	local msg = Time_pb.HPTimeZone()
	msg.id = 1
	local pb_data = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(HP_pb.TIME_ZONE_C, pb_data, #pb_data, false)
	-- end
end

-- 本module导出的全局变量
-- Functions
function RegisterUpdateHandler(name, func)
	updateHandler[name] = func
end

function RemoveUpdateHandler(name)
	if name == nil then return end
	updateHandler[name] = nil
end

function getLeftTime(hourNum, minNum, secNum)
	local todayDate = os.date("*t")
	min = minNum or 0
	sec = secNum or 0
	local needShowTime = { year = 1970, month = 1, day = 1, hour = hourNum, min = min, sec = sec }
	if todayDate.hour < hourNum or (todayDate.hour == hourNum and todayDate.min < minNum ) then
		needShowTime.year = todayDate.year
		needShowTime.month = todayDate.month
		needShowTime.day = todayDate.day
	else
		local tomorrowDate = os.date("*t", os.time() + 86400)
		needShowTime.year = tomorrowDate.year
		needShowTime.month = tomorrowDate.month
		needShowTime.day = tomorrowDate.day
	end
	return os.time(needShowTime) - os.time()
end

function GamePrecedure_preEnterMainMenu()
	GameUtil:createFont()
	CCLuaLog("GamePrecedure_preEnterMainMenu")
    
	-- 已经登录成功后，刷新最新的playerId和serverid
	-- g_curPlayerId = ServerDateManager:getInstance().mLoginInfo.m_iPlayerID
	-- g_curServerId = GamePrecedure:getInstance():getServerID()
end
--
function GamePrecedure_enterBackGround()
	CCLuaLog("GamePrecedure_enterBackGround")
	--refreshTimeCalculator()
	--MainFrame_refreshTimeCalculator()
    MainFrame_createTimeCalculator();
end

function GamePrecedure_enterForeground()

	--CCLuaLog("GamePrecedure_enterForeground")
    --checkServerVersion()

	-- 韩国关闭推送
	-- if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
	-- libOS:getInstance():clearNotification()
	-- end
	-- 清理离线24h的推送通知
	-- libPlatformManager:getPlatform():sendMessageG2P("G2P_CLEAN_NOTIFICATION_ONCE","")
	-- libOS:getInstance():addNotification(Language:getInstance():getString("@Notification24hours"),24*60*60,false)
	-- 游戏切回前台，检测版本是否有更新
	-- if not isFirstUpdate then

	-- end
    --MainFrame_createTimeCalculator();
	--createTimeCalculator()

	-- createTimeCalculator()
    require("MercenaryEnhancePage"):resetMercenaryEnhancePageData()

end


local lua_DownloadListener = nil
local lua_DownloadHandle = {}
local lua_DownloadSchedulerId = nil
local lua_DownloadFilePath = ""
function lua_DownloadHandle:onDownLoaded(listener)

    local filename = listener:getFileName();
    if string.find(filename,"dynamic") then
        if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
            return
        end
        local fileInfo = io.input(filename)
        local fileInfostr=io.read("*a")
        fileInfo:close()
        local isFind = string.find(fileInfostr,"addressIp");
        if not isFind then
            
            return 
        end
        CCLuaLog("checkPacketInfo....onDownLoaded "..filename)
        libOS:getInstance():requestRestart()
        return 
    end
    if lua_DownloadFilePath ~= filename then
        CCLuaLog("checkServerVersion DownloadFilePath ~= filename return")
        return
    end
    local fileurl = listener:getUrl();
    local keyVersion = 0
    -- 以只读方式打开文件
    local file1 = io.open(filename, "r")
    if not file1 then
        CCLuaLog("lua_DownloadListener....file1 = nil...")
        return
    end
    local fileStr = file1:read("*a")
    file1:close()
    local isFind = string.find(fileStr,"versionResource");
    if not isFind then
        -- checkServerVersion();
        return 
    end


    local strTable = json.decode(fileStr)
    if not strTable or not strTable.versionResource then
        CCLuaLog("checkServerVersion lua_DownloadListener... strTable or strTable.keyVersion = nil...")
        return
    end
     local keyVersion = strTable.versionResource

    CCLuaLog("checkServerVersion lua_DownloadListener....strTable.keyVersion = "..keyVersion)

    if keyVersion and resVersion ~= keyVersion then
        local title = common:getLanguageString("@HintTitle")
        local des = common:getLanguageString("@VersionRestartNotice")
        PageManager.showNotice(title, des, function()
                libOS:getInstance():requestRestart()
        end,false,false)
    end


end
function lua_DownloadHandle:onDownLoadFailed(listener)
    local filename = listener:getFileName();
    if string.find(filename,"dynamic") then
         CCLuaLog("checkPacketInfo....onDownLoadFailed "..filename)
        --checkPacketInfo();
        return 
    end
    CCLuaLog("checkServerVersion....Failed")
end






local function requestHttpURL(url)
    local http=require("socket.http")
	http.TIMEOUT = 5
	local cfg, code, response_headers = http.request(url)

    return cfg, code, response_headers
end


function checkServerVersion()


CCLuaLog("checkServerVersion....")
	if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
		return
	end
   
    if not lua_DownloadListener then
        lua_DownloadListener = CurlDownloadScriptListener:new(lua_DownloadHandle)
        CCLuaLog("checkServerVersion....CurlDownloadScriptListener:new")
    end



    --读取本地文件同时获得CDN地址
    local localVersion = ""
    local localVerPath = CCFileUtils:sharedFileUtils():getWritablePath().. "/version/version.manifest"


    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_ANDROID then
        local isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(localVerPath)
		if isFileExist == false then
			localVerPath =CCFileUtils:sharedFileUtils():getWritablePath().. "/version/versionTmp.manifest"
            local isFileExist1 =  CCFileUtils:sharedFileUtils():isFileExist(localVerPath)
            if isFileExist1 == false then
                --localVerPath = CCFileUtils:sharedFileUtils():getWritablePath().. "/version.manifest"
                return
            end
		end


		--AdditionalSearchPath = "assets/"
	else
        local isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(localVerPath)
		if isFileExist == false then
			localVerPath =CCFileUtils:sharedFileUtils():getWritablePath().. "/version/versionTmp.manifest"
            local isFileExist1 =  CCFileUtils:sharedFileUtils():isFileExist(localVerPath)
            if isFileExist1 == false then
                --localVerPath = CCFileUtils:sharedFileUtils():getWritablePath().. "/version.manifest"
                return
            end
		end
		--AdditionalSearchPath = "_additionalSearchPath/"
	end

    local localfile = io.open(localVerPath, "r")
    if not localfile then
        CCLuaLog("lua_DownloadListener....file1 = nil...")
        return
    end
    local localfileStr = localfile:read("*a")
    localfile:close()
    local isFindLocal = string.find(localfileStr,"versionResource");
    if not isFindLocal then
        -- checkServerVersion();
        return 
    end


    local strTableLocal = json.decode(localfileStr)
    if not strTableLocal or not strTableLocal.versionResource then
        CCLuaLog(" m lua_DownloadListener... strTable or strTableLocal.keyVersion = nil...")
        return
    end

    resVersion = strTableLocal.versionResource
--    local resVersionArray = common:split(localversionResource, "%.")
--    if resVersionArray[3] then
--        resVersion = tonumber(resVersionArray[1]..resVersionArray[2]..resVersionArray[3])
--    end

    local localremoteVersionUrl = strTableLocal.remoteVersionUrl

--   local severCfg = ""
--	if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_ANDROID then
--    --+ "?" + "time=" + _time->m_sString;
--		severCfg = localremoteVersionUrl.."/version.manifest?time="..tostring(os.time())
--	else
--		severCfg = localremoteVersionUrl.."/version.manifest?time="..tostring(os.time())
--	end


--    local cfg, code, response_headers = requestHttpURL(severCfg)
--     if code ~= 200 then
--            return
--     end



--     local strTableServer = json.decode(cfg)
--    if not strTableServer or not strTableServer.versionResource then
--        CCLuaLog("checkServerVersion lua_DownloadListener... strTable or strTable.keyVersion = nil...")
--        return
--    end
--     local keyVersion = strTableServer.versionResource



--    if keyVersion and resVersion ~= keyVersion then
--        local title = common:getLanguageString("@HintTitle")
--        local des = common:getLanguageString("@VersionRestartNotice")
--        PageManager.showNotice(title, des, function()
--                libOS:getInstance():requestRestart()
--        end,false,false)
--    end




--    libPlatformManager:getPlatform():sendMessageG2P("G2P_ACCOUNT_LOGIN", "false")
--    --libPlatformManager::getPlatform()->sendMessageG2P("G2P_ACCOUNT_LOGIN", "false");
--    --获得线上版本版本
	local severCfg = ""
	if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_ANDROID then
    --+ "?" + "time=" + _time->m_sString;
		severCfg = localremoteVersionUrl.."/checkver.manifest?time="..tostring(os.time())
	else
		severCfg = localremoteVersionUrl.."/checkver.manifest?time="..tostring(os.time())
	end
    local savePath = CCFileUtils:sharedFileUtils():getWritablePath()
    lua_DownloadFilePath = savePath.."/keyVersion.cfg"
    CurlDownload:getInstance():downloadFile(severCfg,lua_DownloadFilePath);
    if not lua_DownloadSchedulerId then
        CCLuaLog("checkServerVersion....scheduleScriptFunc:new")
        lua_DownloadSchedulerId = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function(dt)
            CurlDownload:getInstance():update(0.2);
        end, 0.2, false)
    end





end






local function compareVersion()

end

local function checkVersionState()
	if CC_TARGET_PLATFORM_LUA ~= nil then
		if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
			return 
		end
	end
	--日本平台
	if Golb_Platform_Info.is_gNetop_platform then
		--根据包名获取渠道
		local channelName = common:getChannelName()
		--日本2015-06-02安全包
		if channelName and channelName ~= "" and GameConfig.ChannelConfig[channelName] and GameConfig.ChannelConfig[channelName] ~= "" then
			local config = GameConfig.ChannelConfig[channelName]
			local configArray = common:split(config, ",")
			local tipSwitch = tonumber(configArray[1])
			local openUrl = tostring(configArray[2])
			local versionLimit = tostring(configArray[4])
			if tipSwitch == nil or openUrl == nil or versionLimit == nil then 
				return
			end
			-- body
			local instance	= GamePrecedure:getInstance();	-- body
			local localVersonLimit = ""
			--判断函数是否存在
			if type(instance.getLocalVersionToLua) ~= "function" then
				--只适应于  日本因ip下架 和临时出的一个第三方支付出的包 2.153.0 和2.153.4
				if CC_TARGET_PLATFORM_LUA ~= common.platform.CC_PLATFORM_ANDROID then
					return;
				end
				local fileName = "version_android_local.cfg"
				local isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(fileName)
				if isFileExist == false then
					return;
				end
				local path = CCFileUtils:sharedFileUtils():fullPathForFilename(fileName)
				if string.sub(path,0,1) ~= "/"  then 
					local writablePath = CCFileUtils:sharedFileUtils():getWritablePath()
					path = writablePath..path
				end
				file = io.open(path,"r")
				if file == nil then
					return;
				end
				local str = "";
				for line in file:lines() do
					 str = str..tostring(line);
				end
				file:close()
				local json = require('json')
				local temp = json.decode(str)
				if temp == nil then
					return;
				end
				localVersonLimit = temp.localVerson
			else
				--存在则处理换包逻辑
				localVersonLimit =  GamePrecedure:getInstance():getLocalVersionToLua()
			end
			local versionLimitArray = common:split(versionLimit, "%.")
			local localLimitArray = common:split(localVersonLimit, "%.")

			local versionLimitNum = tonumber(versionLimitArray[3]);
			local localVersonNum = tonumber(localLimitArray[3]);
	
			--版本号限制 指定版本号之上(含指定版本)	没有关闭提示功能		
			if localVersonNum >= versionLimitNum then
				tipSwitch = 0
			end
			local channelConfigTitle = common:getLanguageString("@ChannelConfigTitle")
			local channelConfigDes = common:getLanguageString("@ChannelConfigDes")
			if tipSwitch == 1 then
				PageManager.showConfirm(channelConfigTitle, channelConfigDes, function(isSure)
					if isSure then
						libOS:getInstance():openURL(openUrl);
					end
				end,false)
			elseif tipSwitch == 2 then 
				PageManager.showNotice(channelConfigTitle, channelConfigDes,function() 
					libOS:getInstance():openURL(openUrl);
					end,false,false)
			end
		end
	end
end

local heartBeatCount = 0
local dt = 0

function GamePrecedure_update(gameprecedure)
    
    dt = GamePrecedure:getInstance():getFrameTime();
    heartBeatCount = heartBeatCount + dt
    if heartBeatCount > HeartBeatMaxCount then
        heartBeatCount = 0
        local HP_pb = require "HP_pb"
        local SysProtocol_pb = require "SysProtocol_pb"
        local heartBeat = SysProtocol_pb.HPHeartBeat()
        heartBeat.timeStamp = os.time()
        common:sendPacket(HP_pb.HEART_BEAT,heartBeat,false)        
    end

	if isFirstUpdate then
		requestPackages()
		resetMenu("mMainPageBtn", true)
		MainFrame_createTimeCalculator()
		-- reset MainFrame_onMainPageBtn
		isFirstUpdate = false
        --SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(0.6);
	end
	-- CCLuaLog("GamePrecedure_update")
	for name, func in pairs(updateHandler) do
		func()
	end
end

--------------------------------------------------------------------------------
-- 本module的执行代码主体

CCLuaLog("main.lua excute");

--------------------------------------------------------------------------------

-- 重置lua页面及数据，为重登陆做准备
-- different player id login, reset all data
function resetAllLuaDataAndScene()
    localSeverTime  = nil 
	local needReset = true
	if needReset then
		UserEquipManager:reset()
		PackagePage_reset()
		BattlePage_Reset()
		registerScriptPage("ArenaPage")
		ArenaPage_Reset()
		ChatList_Reset()-- 切换账号登陆，删除聊天记录
		require("Guild.ABManager")
		ABManager_reset()-- 切换账号清除公会争霸记录
		if LeaveMessagePage_reset then
			LeaveMessagePage_reset()
		end
		if LeaveMessageDetailPage_reset then
			LeaveMessageDetailPage_reset()
		end
		GuildDataManager = require("Guild.GuildDataManager")
		GuildDataManager:resetTwoPage()
        require("GiftPage")
		ResetGiftPage()
		RESETINFO_MARKET()

		registerScriptPage("MailPage")
		RESETINFO_MAILS()-- 引入
		RESETINFO_TEAMBATTLE()
		RESETINFO_NOTICE_STATE()	
		local UserInfo = require("PlayerInfo.UserInfo");	
		UserInfo.reset();
        require("Equip.MeltPage")
		MeltPage_reset();
		SkillManager_Reset()		
		isFirstUpdate = true;
		if ProfessionRankingPage_reset then
			ProfessionRankingPage_reset()
		end
		ChatManager_reset()
		require("Battle.VoiceChatManager")
		VoiceChatManager_resetData()
		Reset_crossServerData()
		local MercenaryHaloManager = require("MercenaryHaloManager")
		MercenaryHaloManager:resetData()

		local AchievementManager = require("PlayerInfo.AchievementManager")
		AchievementManager:reset()
		MainScenePageInfo_resetFirstClick()
        require("MercenaryEnhancePage"):resetMercenaryEnhancePageData()
		require("Element.ElementManager")
		ElementManager_reset()
		local TalentManager = require("PlayerInfo.TalentManager")
		TalentManager_reset()
	end
end

-- same player id login, reset some data 
function reloginScene()
    localSeverTime  = nil 
	UserEquipManager:reset()
	ChatList_Reset()
	ChatManager_reset()

	MainScenePageInfo_resetFirstClick()
end
--
function theOnLogOutConfirm(flag)
	if flag then
		CCLuaLog("ReEnter")
		-- UserEquipManager:setUninited();
		-- 
		GamePrecedure:getInstance():reEnterLoading();
		--
	end
end
-- 安卓机，返回键调用此模式对话框

function askLogoutFromMainFrameToLoadingFrame()
	local title = Language:getInstance():getString("@LogOffTitle")
	local message = Language:getInstance():getString("@LogOffMSG")
	--
	PageManager.showConfirm(title, message, theOnLogOutConfirm)
end
--

local debugStrTable = {}
function __G__TRACKBACK__(msg)

	local debugStr = "LUA ERROR: " .. tostring(msg) .. "\n" .. debug.traceback()
   --bugly  lua  glj 2019
    -- record the message
    local message = msg;
    -- auto genretated
    local msg = debug.traceback(msg, 3)
    print(msg)
    -- report lua exception
    buglyReportLuaException(tostring(message), debug.traceback())

	if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
		CCMessageBox(debugStr, "LUA ERROR")
	end
	for i,v in ipairs(debugStrTable) do
		if v == debugStr then
			return
		end
	end

	table.insert(debugStrTable, debugStr)
--	local postTable = {}
--	postTable.localVersion = SeverConsts:getInstance():getServerVersion()
--	postTable.platform = "null"
--	for k,v in pairs(common.platform) do
--		if CC_TARGET_PLATFORM_LUA == v then
--			postTable.platform = k
--		end
--	end
--	postTable.time = os.date()
--	postTable.param = "123"
--	postTable.debugStr = debugStr
--	postTable.puid = CCUserDefault:sharedUserDefault():getStringForKey("LastLoginPUID")
--	postTable.serverId = GamePrecedure:getInstance():getServerID()
--	local httpPost = ""
--	for k,v in pairs(postTable) do
--		if httpPost == "" then
--			httpPost = httpPost.. k.."="..v
--		else
--			httpPost = httpPost.. "&" .. k.."="..v
--		end
--	end
--	local socket = require "socket"
--	local http=require("socket.http")
--	http.TIMEOUT = 5
--	local res, code, response_headers = http.request("https://1jdata.tigerto.com/game_errorinfo",httpPost)
end
-- __G__TRACKBACK__ = nil
