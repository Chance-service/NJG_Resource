
local AB_pb = require("AllianceBattle_pb")
local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local NodeHelper = require("NodeHelper")
local thisPageName = "ABHelpPage"
local opcodes = {
}

local option = {
	ccbiFile = "GuildPictureHelpPage.ccbi",
	handlerMap = {
		onReturnBtn = "onReturn",
		onFrontPage = "onFrontPage",
		onNextPage = "onNextPage",
		onChoiceBattlefield = "onChoiceBattlefield"
	},
	DataHelper = ABManager
}

local pageIndex = 1;

local ABHelpPage = BasePage:new(option,thisPageName,nil,opcodes)


function ABHelpPage:getPageInfo(container)
    self:refreshPage(container)
end


function ABHelpPage:refreshPage(container)    
    
    local spriteImg = {
        mPicHelp = ABManager:getConfigDataByKeyAndIndex("HelpConfig",pageIndex)
    }
    
    NodeHelper:setSpriteImage(container, spriteImg);
end

function ABHelpPage:onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();
	if typeId == MSG_SEVERINFO_UPDATE then
		self:onUpdateServerInfo(container)	
	elseif typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == self.pageName then
			self:onRefreshPage(container);
        elseif pageName == "ABManager" then
            PageManager.changePage("GuildPage")
		end
	end
end
--------------Click Event--------------------------------------
function ABHelpPage:onFrontPage(container)
    pageIndex = pageIndex - 1
    if pageIndex < 1 then
        pageIndex = 1
    end
    self:refreshPage(container)
end

function ABHelpPage:onNextPage(container)
    pageIndex = pageIndex + 1
    if pageIndex > (#(ABManager:getConfigDataByKey("HelpConfig"))) then
        pageIndex = #(ABManager:getConfigDataByKey("HelpConfig"))
    end
    self:refreshPage(container)
end

function ABHelpPage:onReturn(container)
    if ABManager.rankList~=nil then 
        ABManager.rankList.hasJoined = true
    end
    if ABManager.battleState == AB_pb.SHOW_TIME then
        PageManager.changePage("ABRewardPage")
    else
        PageManager.changePage("ABMainPage")
    end
end

function ABHelpPage:onChoiceBattlefield(container)
    if ABManager.rankList~=nil then 
        ABManager.rankList.hasJoined = true
    end
    if ABManager.battleState == AB_pb.PREPARE and AllianceOpen then
        PageManager.changePage("ABJoinPage")
    elseif ABManager.battleState == AB_pb.SHOW_TIME then
        PageManager.changePage("ABRewardPage")
    else
        PageManager.changePage("ABMainPage")
    end
end
--------------Call Function----------------------------------------
function showABHelpPageAtIndex(index)
    pageIndex = index or 1
	if not Golb_Platform_Info.is_entermate_platform then
		PageManager.changePage(thisPageName)
	end
end

