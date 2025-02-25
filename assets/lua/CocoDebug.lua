--require("smtplog")

function CocoLog(msg)
	msg = "CocosLuaError in " .. os.date("%Y-%m-%d-%H-%M-%S") .. "\n" ..msg.."\n"..debug.traceback()
	
	if CC_TARGET_PLATFORM_LUA ~= nil then 
        if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then		
			CCMessageBox(msg,"Debug info")
			local enableSendMsg = true
			if enableSendMsg then
				--sendmailtext(msg,"platform is "..CC_TARGET_PLATFORM_LUA)
			end
		end
    elseif libOS:getInstance():getIsDebug() then
        local debugPage = require("DebugPage")
        debugPage:setMessage(msg)
        PageManager.pushPage("DebugPage")	
    end
end