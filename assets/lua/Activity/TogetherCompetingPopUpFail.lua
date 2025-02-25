
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local HP_pb = require("HP_pb")
local thisPageName = "TogetherCompetingPopUpFail"
local option = {
    ccbiFile = "Act_TogetherCompetingRedEnvelopesPopUp2.ccbi",
    handlerMap ={
        onCancel               = "onCancel",
        onRecharge             = "onRecharge",
        onClose                = "onClose",
    },
}
local TogetherCompetingPopUpFail = BasePage:new(option,thisPageName,nil,nil)

-------------------------- logic method ------------------------------------------

-------------------------- state method -------------------------------------------

----------------------------click method -------------------------------------------
function TogetherCompetingPopUpFail:onCancel(container)
    PageManager.popPage(thisPageName)
end
function TogetherCompetingPopUpFail:onClose( container )
    PageManager.popPage(thisPageName)
end
function TogetherCompetingPopUpFail:onRecharge(container)
    PageManager.popPage(thisPageName)
	libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","SnatchRedpacket_enter_rechargePage")
    PageManager.pushPage("RechargePage")
end
----------------------------packet method -------------------------------------------

---------------------------- end  ----------------------------------------------------
