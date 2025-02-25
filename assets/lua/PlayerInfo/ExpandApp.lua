
----------------------------------------------------------------------------------

----------------local data--------------------------------
local thisPageName = 'ExpandApp'
local ExpandAppBase = {}

local option = {
	ccbiFile = "GameSetPopUp.ccbi",
	handlerMap = {
		onTanabata 	= "onTanabata",
		onCancel 		= "onClose",
		onClose 		= "onClose",
		onHelp  		= "onHelp",
	}
}
----------------local data end-----------------------------

function ExpandAppBase:onEnter( container )
	
end

function ExpandAppBase:onExit(container)
	
end

function ExpandAppBase:onClose( container )
	PageManager.popPage(thisPageName)
end

function ExpandAppBase:onTanabata( container )
	local lobiURL = "https://web.lobi.co/game/houchi_teikoku/group/d85c068cd49452ddeb2dba37323e430b8d2f1e41"
	if  BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2  then
		if string.sub(lobiURL,1,5) == "https" then
			libOS:getInstance():openURLHttps(lobiURL)
		else
			libOS:getInstance():openURL(lobiURL)
		end
	else
		libOS:getInstance():openURL(lobiURL)
	end
	PageManager.popPage(thisPageName)
end

function ExpandAppBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_TITLE)
end

local CommonPage = require('CommonPage')
local ExpandApp= CommonPage.newSub(ExpandAppBase, thisPageName, option)
