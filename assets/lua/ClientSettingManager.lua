----------------------------------------------------------------------------------
--[[
	FILE:			ClientSettingManager.lua
	ENCODING:		UTF-8, no-bomb
	
	
					add notes
--]]

local ClientSettingManager = {}

ClientSettingManager.params = {}


--return found flag and data 
function ClientSettingManager:findAndGetValueByKey(key)
    for i=1,#ClientSettingManager.params do
        if ClientSettingManager.params[i].key == key then
            return true,ClientSettingManager.params[i].value
        end
    end

    return false,nil
    --[[
	if ClientSettingManager.params[key] ~= nil then 
		return true,ClientSettingManager.params[key]
	else
		return false,nil
	end
    --]]
end

function ClientSettingManager:onReceivePacket(msg)
	ClientSettingManager.params = msg.params
end

return ClientSettingManager 