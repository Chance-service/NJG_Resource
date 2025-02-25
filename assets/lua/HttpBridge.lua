HttpBridge = {}

function HttpBridge:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	self.__onHttpCallback = nil
    return o
end

function HttpBridge:getInstance()
    if self.m_HttpBridge == nil then
        self.m_HttpBridge = self:new()
    end

    return self.m_HttpBridge
end

--#region [public function] ---
function HttpBridge:WebRequest_Post(url,tag,data,callback)
	HttpBridge:getInstance().__onHttpCallback = callback

	-- 調用 cpp 函式
	WebRequest_Post_Cpp(url,tag,data)
end

-- cpp 通知，HttpRespons 結果
function _cpp_notify_Http_callback(isError,responseData,tag,code)
    local httpResult = {}
    httpResult.isError = isError;
    httpResult.responseData = responseData;
    httpResult.tag = tag;
    httpResult.code = code;
    HttpBridge:getInstance().__onHttpCallback(httpResult)

end
