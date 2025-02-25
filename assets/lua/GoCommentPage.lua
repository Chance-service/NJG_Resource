----------------------------------------------------------------------------------
--[[
	
--]]
----------------------------------------------------------------------------------

local option = {
	ccbiFile = "GeneralDecisionPopUp.ccbi",
	handlerMap = {
		onCancel		= "onNo",
		onConfirmation 	= "onYes",
        onClose         = "onClose"
	}
};

local thisPageName = "GoCommentPage";
local CommonPage = require("CommonPage");
local GoCommentPage = CommonPage.new("GoCommentPage", option);
local decisionTitle = "";
local decisionMsg = "";
local decisionCB = nil;
local autoClose = true;
local showclose = false;
local titleScale = 1
local decisionYes = "@Confirmation"
local decisionNo = "@Cancel"
local NodeHelper = require("NodeHelper");
----可以跳转到评论的奖励配置
local goCommentReward = {
	"30000_110305_1",
	"30000_110605_1",
	"30000_110306_1",
	"30000_110606_1",
	"70000_107_8",
}
local rewardItems = {}
----------------------------------------------------------------------------------

----------------------------------------------
function GoCommentPage.onEnter(container)
	GoCommentPage.refreshPage(container);
	container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
end

function GoCommentPage.onExit(container)
	GoCommentPage_setDecision("", "", nil);
	container:removeMessage(MSG_MAINFRAME_PUSHPAGE);
	rewardItems = {}
end

function GoCommentPage.refreshPage(container)

	NodeHelper:setStringForLabel(container, {
		mTitle 			= decisionTitle,
		mDecisionTex 	= decisionMsg,		--20: char per line
		mConfirmation	= common:getLanguageString(decisionYes),
		mCancel			= common:getLanguageString(decisionNo),
	});
    local mTitle = container:getVarNode("mTitle")
    if mTitle then
       local scale = titleScale or 1
       mTitle:setScale(titleScale)
    end
   	NodeHelper:setNodesVisible(container, {mButtonDoubleNode = showclose, mButtonMiddleNode = not showclose})
end

function GoCommentPage.onNo(container)
	if decisionCB then

		decisionCB(false);
	end
	PageManager.popPage(thisPageName)
end


function GoCommentPage.onYes(container)
	if decisionCB then
		decisionCB(true);
	end
	if autoClose then
		PageManager.popPage(thisPageName)
        titleScale = 1
	end
end	
function GoCommentPage.onClose(container)
	if decisionCB then
		decisionCB(false);	
	end
    PageManager.popPage(thisPageName)
    titleScale = 1
end	

function GoCommentPage.onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();
	if typeId == MSG_MAINFRAME_PUSHPAGE then
		local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			GoCommentPage.refreshPage(container);
		end
	end
end


function GoCommentPage_setComment()
	decisionTitle	= common:getLanguageString("@GameDiscussTitle")--title;
	decisionMsg 	= common:getLanguageString("@GameDiscussInfoTxt")
	decisionCB		=  function(_mrak)
		if _mrak then
            local UserInfo = require("PlayerInfo.UserInfo");
            UserInfo.setIsComment(true)
			local commentURL = ""   
			if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then ---ios的跳转地址
				commentURL = "https://itunes.apple.com/jp/app/id1450614902?mt=8&action=write-review"
			else	---android的跳转地址
				commentURL = "https://play.google.com/store/apps/details?id=jp.co.school.battle"
			end
			common:openURL(commentURL)
		end
	end
	autoClose		= (auto or auto == nil) and true or false;
	decisionYes		= yes and yes or "@Confirmation"
	decisionNo		= no and no or "@Cancel"
    showclose       = true  
    titleScale = 0.8
end


-------------------------------------------------------------------------------
function GoCommentPage_setDecision(allrewardsStr)
	if #rewardItems == 0 then
		for i = 1,#goCommentReward do
	        local _type, _id, _count = unpack(common:split(goCommentReward[i], "_"));
	        table.insert(rewardItems, {
	            itemType 	= tonumber(_type),
	            itemId	= tonumber(_id),
	            itemCount 	= tonumber(_count)
	        });
	    end
	end

	local isReward = false
	for i=1, #allrewardsStr do
		for j=1,#rewardItems do
			if (allrewardsStr[i].itemType == rewardItems[j].itemType and allrewardsStr[i].itemId == rewardItems[j].itemId) or (allrewardsStr[i].type == rewardItems[j].itemType and allrewardsStr[i].itemId == rewardItems[j].itemId) then 
				isReward = true
				break
			end
		end
	end

    if isReward or not isReward then
       return false
    end

	--不是相应的奖励退出
	if not isReward then 
		return isReward
	end

	decisionTitle	= common:getLanguageString("@GameDiscussTitle")--title;
	decisionMsg 	= common:getLanguageString("@GameDiscussInfoTxt")
	decisionCB		=  function(_mrak)
		local tabTime = os.date("*t")
	    tabTime.hour = 0;
	    tabTime.min = 0;
	    tabTime.sec = 0;
	    local time = os.time(tabTime);
	    CCUserDefault:sharedUserDefault():setStringForKey("GoCommentTime",time)

		if _mrak then
			local commentURL = ""   
			if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then ---ios的跳转地址
				commentURL = "https://itunes.apple.com/jp/app/id1450614902?mt=8&action=write-review"
			else	---android的跳转地址
				commentURL = "https://play.google.com/store/apps/details?id=jp.co.school.battle"
			end
			common:openURL(commentURL)
		end
	end--callback;
	autoClose		= (auto or auto == nil) and true or false;
	decisionYes		= yes and yes or "@Confirmation"
	decisionNo		= no and no or "@Cancel"
    showclose       = true

    return isReward
end

function GoCommentPage_setHtmlDecision(title, htmlMsg, callback, auto, isshowclose)
	decisionTitle	= title;
	decisionMsg 	= htmlMsg;
	decisionCB		= callback;
	autoClose		= (auto or auto == nil) and true or false;
	htmlTag			= true
end