----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local UserInfo = require("PlayerInfo.UserInfo")
local option = {
	ccbiFile = "AutoTrainPopUp.ccbi",
	handlerMap = {
		onCheck01		= "onCheck01",
		onCheck02		= "onCheck02",
        onCheck03		= "onCheck03",
        onCheck04		= "onCheck04",
        onCheck05		= "onCheck05",
        onClose         = "onClose"
	}
}

local thisPageName = "AutoTrainPopUp"
local MercenaryEnhancePage = require("MercenaryEnhancePage")
local NodeHelper = require("NodeHelper")
local CommonPage = require("CommonPage")
local AutoTrainPopUp = CommonPage.new("AutoTrainPopUp", option)
local selectType = { 1, 1, 1, 1, 1 }
----------------------------------------------------------------------------------

----------------------------------------------
function AutoTrainPopUp.onEnter(container)
	AutoTrainPopUp.refreshPage(container)
end

function AutoTrainPopUp.refreshPage(container)
   	AutoTrainPopUp.loadPlayerSetting(container)
    NodeHelper:setNodesVisible(container, { mCheck01 = selectType[1] == 1,
                                            mCheck02 = selectType[2] == 1,
                                            mCheck03 = selectType[3] == 1,
                                            mCheck04 = selectType[4] == 1,
                                            mCheck05 = selectType[5] == 1, })
end

function AutoTrainPopUp.onCheck01(container)
	if selectType[1] == 1 then
		NodeHelper:setNodesVisible(container, { mCheck01 = false })
        selectType[1] = 0
   	else
   		NodeHelper:setNodesVisible(container, { mCheck01 = true })
        selectType[1] = 1
   	end
end

function AutoTrainPopUp.onCheck02(container)
	if selectType[2] == 1 then
		NodeHelper:setNodesVisible(container, { mCheck02 = false })
        selectType[2] = 0
   	else
   		NodeHelper:setNodesVisible(container, { mCheck02 = true })
        selectType[2] = 1
   	end
end

function AutoTrainPopUp.onCheck03(container)
	if selectType[3] == 1 then
		NodeHelper:setNodesVisible(container, { mCheck03 = false })
        selectType[3] = 0
   	else
   		NodeHelper:setNodesVisible(container, { mCheck03 = true })
        selectType[3] = 1
   	end
end

function AutoTrainPopUp.onCheck04(container)
	if selectType[4] == 1 then
		NodeHelper:setNodesVisible(container, { mCheck04 = false })
        selectType[4] = 0
   	else
   		NodeHelper:setNodesVisible(container, { mCheck04 = true })
        selectType[4] = 1
   	end
end

function AutoTrainPopUp.onCheck05(container)
	if selectType[5] == 1 then
		NodeHelper:setNodesVisible(container, { mCheck05 = false })
        selectType[5] = 0
   	else
   		NodeHelper:setNodesVisible(container, { mCheck05 = true })
        selectType[5] = 1
   	end
end

function AutoTrainPopUp.onClose(container)
    PageManager.popPage(thisPageName)
    CCUserDefault:sharedUserDefault():setStringForKey("EnhanceAutoSetting", selectType[1] .. "_" .. selectType[2] .. "_"
                                                     .. selectType[3] .. "_" .. selectType[4] .. "_" .. selectType[5])
end	

function AutoTrainPopUp.loadPlayerSetting(container)
    if not string.find(CCUserDefault:sharedUserDefault():getStringForKey("EnhanceAutoSetting"), "_") then
        for i = 1, 5 do
            selectType[i] = 1
        end
    else
        local localSelect = CCUserDefault:sharedUserDefault():getStringForKey("EnhanceAutoSetting")
        selectType = common:split((localSelect), "_")
        for i = 1, 5 do
            selectType[i] = tonumber(selectType[i])
        end
    end
    return selectType
end

-------------------------------------------------------------------------

return AutoTrainPopUp