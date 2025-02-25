
----------------------------------------------------------------------------------

local thisPageName = 'GameCommentPage'
require("HP_pb");
require("Player_pb");
local GameCommentBase = {};
local option = {
	ccbiFile = "GeneralDecisionPopUp7.ccbi",
	handlerMap = {
		onCancel 		= "onCancel",
		onRemindLater 	= "onRemindLater",
        onConfirmation = "onConfirmation"
	}
}
local RequestType = 
{
	TYPE_CANCEL = 0,
	TYPE_OK = 1,
    TYPE_LATER = 2,
}
function GameCommentBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GameCommentBase:onEnter(container)
	--[[玩家满足条件后url评论
	ROLE_GAME_COMMENT_C = 6015;
	ROLE_GAME_COMMENT_S = 6016;]]--
end

function GameCommentBase:onExit(container)
	
end
function GameCommentBase:onConfirmation(container)
	self:Send2ServerMsg(container,RequestType.TYPE_OK);
    
	if  BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2  then
        local strUrl = GameConfig.CommentUrl.IosUrl
		if string.sub(strUrl,1,5) == "https" then
			libOS:getInstance():openURLHttps(GameConfig.CommentUrl.IosUrl);
			else
			libOS:getInstance():openURL(GameConfig.CommentUrl.IosUrl);
		end
	else
		libOS:getInstance():openURL(GameConfig.CommentUrl.AndroidUrl);
	end
end
function GameCommentBase:onRemindLater(container)
	self:Send2ServerMsg(container,RequestType.TYPE_LATER);
end
function GameCommentBase:onCancel(container)
	self:Send2ServerMsg(container,RequestType.TYPE_CANCEL);
end
function GameCommentBase:Send2ServerMsg(container,type)
    local msg = Player_pb.HPCommentMsg();
	msg.type = type;
	local pb_data = msg:SerializeToString();
	container:sendPakcet(HP_pb.ROLE_GAME_COMMENT_C, pb_data, #pb_data, false);
    PageManager.popPage(thisPageName)
end

local CommonPage = require('CommonPage')

local GameCommentPage= CommonPage.newSub(GameCommentBase, thisPageName, option)
