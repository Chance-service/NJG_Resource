EcchiGamerSDK = {}

function EcchiGamerSDK:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	self.__onInitializeCallback = nil
	self.__onOpenLoginCallback = nil
	self.__onOpenLogoutCallback = nil
	self.__onOpenAccountBindGameCallback = nil
	self.__onPostAccountBindGameCallback = nil
    return o
end

function EcchiGamerSDK:getInstance()
    if self.m_pEcchiGamerSDK == nil then
        self.m_pEcchiGamerSDK = self:new()
    end

    return self.m_pEcchiGamerSDK
end

--#region [public function] ---
function EcchiGamerSDK:initialize(callback)
	EcchiGamerSDK:getInstance().__onInitializeCallback = callback

	-- 調用 cpp 函式
	ecchigamersdk_initialize()
end

function EcchiGamerSDK:openLogin(callback)
	EcchiGamerSDK:getInstance().__onOpenLoginCallback = callback
	
	-- 調用 cpp 函式
	ecchigamersdk_openlogin()
end

function EcchiGamerSDK:openLogout(callback)
	EcchiGamerSDK:getInstance().__onOpenLogoutCallback = callback
	
	-- 調用 cpp 函式
	ecchigamersdk_openlogout()
end

function EcchiGamerSDK:openPayment()
	-- 調用 cpp 函式
	ecchigamersdk_openpayment()
end

function EcchiGamerSDK:openAccountBindGame(game_account, callback)
	EcchiGamerSDK:getInstance().__onOpenAccountBindGameCallback = callback
	
	-- 調用 cpp 函式
	ecchigamersdk_openaccountbindgame(game_account)
end

function EcchiGamerSDK:postAccountBindGame(game_account, callback)
	EcchiGamerSDK:getInstance().__onPostAccountBindGameCallback = callback
	
	-- 調用 cpp 函式
	ecchigamersdk_postaccountbindgame(game_account)
end

function EcchiGamerSDK:getLoginUrl()
	-- 調用 cpp 函式
	return ecchigamersdk_get_login_url()
end

function EcchiGamerSDK:getToken()
	-- 調用 cpp 函式
	return ecchigamersdk_get_token()
end

--#endregion [public function] ---

-- cpp 通知，SDK 初始化結果
function _cpp_notify_initialize_callback(value)
	EcchiGamerSDK:getInstance().__onInitializeCallback(value)
end

-- cpp 通知，openLogin 結果
function _cpp_notify_openlogin_callback(isSuccess, exception, result, server_time, account, account_status, birthday, coins, country, free_coins, gender, hobbies, nickname, user_id)
	local profileResult = {}
	profileResult.isSuccess = isSuccess
	profileResult.exception = exception
	profileResult.result = result
	profileResult.server_time = server_time
	profileResult.account = account
	profileResult.account_status = account_status
	profileResult.birthday = birthday
	profileResult.coins = coins
	profileResult.country = country
	profileResult.free_coins = free_coins
	profileResult.gender = gender
	profileResult.hobbies = hobbies
	profileResult.nickname = nickname
	profileResult.user_id = user_id
	
    EcchiGamerSDK:getInstance().__onOpenLoginCallback(profileResult)
end

-- cpp 通知，openLogout 結果
function _cpp_notify_openlogout_callback(exception)
	local logoutResult = {}
	logoutResult.exception = exception
	
    EcchiGamerSDK:getInstance().__onOpenLogoutCallback(logoutResult)
end

-- cpp 通知，openLogin 結果
function _cpp_notify_openaccountbindgame_callback(isSuccess, exception, result, server_time, account, account_status, birthday, coins, country, free_coins, gender, hobbies, nickname, user_id)
	local profileResult = {}
	profileResult.isSuccess = isSuccess
	profileResult.exception = exception
	profileResult.result = result
	profileResult.server_time = server_time
	profileResult.account = account
	profileResult.account_status = account_status
	profileResult.birthday = birthday
	profileResult.coins = coins
	profileResult.country = country
	profileResult.free_coins = free_coins
	profileResult.gender = gender
	profileResult.hobbies = hobbies
	profileResult.nickname = nickname
	profileResult.user_id = user_id
	
    EcchiGamerSDK:getInstance().__onOpenAccountBindGameCallback(profileResult)
end

function _cpp_notify_postaccountbindgame_callback(isSuccess, exception, result, server_time, account, account_status, birthday, coins, country, free_coins, gender, hobbies, nickname, user_id)
	local profileResult = {}
	profileResult.isSuccess = isSuccess
	profileResult.exception = exception
	profileResult.result = result
	profileResult.server_time = server_time
	profileResult.account = account
	profileResult.account_status = account_status
	profileResult.birthday = birthday
	profileResult.coins = coins
	profileResult.country = country
	profileResult.free_coins = free_coins
	profileResult.gender = gender
	profileResult.hobbies = hobbies
	profileResult.nickname = nickname
	profileResult.user_id = user_id
	
    EcchiGamerSDK:getInstance().__onPostAccountBindGameCallback(profileResult)
end
