local UserInfo = require("PlayerInfo.UserInfo");
local NewbieGuideManager = {}
------------------------------------------------------------------------------------------

function NewbieGuideManager.showHelpPage(key)
	if not key then return end
	local platformName = GamePrecedure:getInstance():getPlatformName()
	if Golb_Platform_Info.is_entermate_platform then
		UserInfo.syncPlayerInfo()
		local privateKey = string.format(key .. "help_%d_%d", UserInfo.serverId, UserInfo.playerInfo.playerId)
		local hasTip = CCUserDefault:sharedUserDefault():getBoolForKey( privateKey )
		if not hasTip then
			--PageManager.showHelp(GameConfig.HelpKey.HELP_ACTIVE)
			PageManager.showHelp(key)
			CCUserDefault:sharedUserDefault():setBoolForKey(privateKey, true)
			CCUserDefault:sharedUserDefault():flush()
		end
	end
end
function NewbieGuideManager.rebirthGuide(key)
    local hasTip, privateKey = NewbieGuideManager.hasTip(key)
	if not hasTip then
        CCUserDefault:sharedUserDefault():setBoolForKey(privateKey, true)
		CCUserDefault:sharedUserDefault():flush()
    end
end

function NewbieGuideManager.hasTip(key)
    UserInfo.syncPlayerInfo()
	local privateKey = string.format(key .. "_%d_%d", UserInfo.serverId, UserInfo.playerInfo.playerId)
    local hasTip = CCUserDefault:sharedUserDefault():getBoolForKey( privateKey )
    return hasTip, privateKey
end


function NewbieGuideManager.getWingReplacePromptAnimationStatus()
    UserInfo.syncPlayerInfo()
    local sKey    = string.format("_%d_%d".."_WingRepace", UserInfo.serverId, UserInfo.playerInfo.playerId)
    local bStatus = false;
    bStatus = CCUserDefault:sharedUserDefault():getBoolForKey( sKey )
    return bStatus
end

function NewbieGuideManager.saveWingReplacePromptAnimationStatus(bValue)
    UserInfo.syncPlayerInfo()
    local sKey    = string.format("_%d_%d".."_WingRepace", UserInfo.serverId, UserInfo.playerInfo.playerId)
    CCUserDefault:sharedUserDefault():setBoolForKey(sKey, true)
    CCUserDefault:sharedUserDefault():flush()
end
------------------------------------------------------------------------------------------
return NewbieGuideManager