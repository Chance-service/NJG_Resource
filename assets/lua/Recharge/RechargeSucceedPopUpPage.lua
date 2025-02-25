----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local thisPageName = 'RechargeSucceedPopUpPage'
local RechargePopBase = {}

local option = {
	ccbiFile = "A_Recharge.ccbi",
	handlerMap = {
	}
}

function RechargePopBase.onAnimationDone(container)
	PageManager.popPage(thisPageName)
end

local CommonPage = require('CommonPage')
local RechargeSucceedPopUpPage= CommonPage.newSub(RechargePopBase, thisPageName, option)
