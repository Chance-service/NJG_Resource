
local thisPageName = "FreeMonthCardPopUp"
local option = {
	ccbiFile = "FreeMonthCardPopUp.ccbi",
	handlerMap = {
        onConfirmation = "onConfirmation"
	}
}
local FreeMonthCardPageBase = {}
---------------------------------------------------------------------
function FreeMonthCardPageBase:onEnter( container )
end
function FreeMonthCardPageBase:rebuildAllItem(container)
end
function FreeMonthCardPageBase:clearAllItem(container)
end
function FreeMonthCardPageBase:buildItem(container)
end
function FreeMonthCardPageBase:onConfirmation( container )
	PageManager.popPage( thisPageName )
end
---------------------------------------------------------------------
local CommonPage = require("CommonPage")
FreeMonthCardPopUp = CommonPage.newSub(FreeMonthCardPageBase, thisPageName, option)