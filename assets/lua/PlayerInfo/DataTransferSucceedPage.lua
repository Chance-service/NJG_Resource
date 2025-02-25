
----------------------------------------------------------------------------------
--require "ExploreEnergyCore_pb"
local HP = require("HP_pb");
local GameConfig = require("GameConfig");
local player_pb = require("Player_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local NodeHelper = require("NodeHelper");
local thisPageName = "DataTransferSucceedPage"
local DataTransferSucceedPage = {}
local _password =  ""
local option = {
	ccbiFile = "DataTransferCompletePopUp.ccbi",
	handlerMap = {
		onConfirmation = "onClose",
		onCancel = "onClose",
		onClose = "onClose",
	},
	opcode = opcodes
};
----------------------------------------------
function DataTransferSucceedPage:onEnter(container)
   self:refreshPage(container)
end

function DataTransferSucceedPage:onExecute(container)
end

function DataTransferSucceedPage:onExit(container)
	
end
----------------------------------------------------------------

function DataTransferSucceedPage:refreshPage(container)
    strPassWord = "";
    local code = GamePrecedure:getInstance():getLoginCode()
    NodeHelper:setStringForLabel( container, {mDataTxt = code ,mPasswordTxt = _password} );

end

----------------click event------------------------
function DataTransferSucceedPage:onClose(container)
	PageManager.popPage(thisPageName);
end
function DataTransferSucceedPage:setPwd(pwd)
	_password = pwd;
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local DataTransferSucceedPage1 = CommonPage.newSub(DataTransferSucceedPage, thisPageName, option);
return DataTransferSucceedPage