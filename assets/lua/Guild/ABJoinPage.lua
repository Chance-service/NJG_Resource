
local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local NodeHelper = require("NodeHelper")
local GuildData = require("Guild.GuildData")
local GuildDataManager = require("Guild.GuildDataManager")
require("ABFightListPage")
local thisPageName = "ABJoinPage"
local HP_pb = require("HP_pb")
local opcodes = {
    ALLIANCE_BATTLE_ENTER_C = HP_pb.ALLIANCE_BATTLE_ENTER_C,
    ALLIANCE_TEAM_BASIC_INFO_C = HP_pb.ALLIANCE_TEAM_BASIC_INFO_C,
    ALLIANCE_TEAM_BASIC_INFO_S = HP_pb.ALLIANCE_TEAM_BASIC_INFO_S,
    ALLIANCE_TEAM_JOIN_INFO_C = HP_pb.ALLIANCE_TEAM_JOIN_INFO_C,
    ALLIANCE_TEAM_JOIN_INFO_S = HP_pb.ALLIANCE_TEAM_JOIN_INFO_S,
}

local option = {
	ccbiFile = "GuildChoiceBattlefieldPage.ccbi",
	handlerMap = {
		onReturnBtn = "onReturn",
		onHelp = "onHelp",
		onTeamInformation = "onTeamInformation",
		onJoinHighland = "onJoinHighland",
		onJoinJungle = "onJoinJungle",
		onJoinValley = "onJoinValley"
	},
	DataHelper = ABManager
}

local ABJoinPage = BasePage:new(option,thisPageName,nil,opcodes)

function ABJoinPage:getPageInfo(container)
	if Golb_Platform_Info.is_entermate_platform then
		NodeHelper:setNodesVisible(container,{mBT_ImageHelp_Node = false,mBT_Help_Node = false})
	end
    local AllianceBattle_pb = require("AllianceBattle_pb")
	local msg = AllianceBattle_pb.HPAllianceTeamEnter();
	common:sendPacket(opcodes.ALLIANCE_TEAM_BASIC_INFO_C, msg); 
   
    NodeHelper:setLabelOneByOne(container,"mPromptLabel","mABJoinHelpTex2",5,true)
end


function ABJoinPage:refreshPage(container)   
    local info = GuildData.allianceInfo.commonInfo
    if ABManager.teamJoinInfo~=nil and info~=nil then
        local perPeo = math.ceil(info.currentPop / 3)
        local labelStr = {
            mRegistrationNum1 = tostring(ABManager.teamJoinInfo.teamSize[1] or 0).."/"..tostring(perPeo),
            mRegistrationNum2 = tostring(ABManager.teamJoinInfo.teamSize[2] or 0).."/"..tostring(perPeo),
            mRegistrationNum3 = tostring(ABManager.teamJoinInfo.teamSize[3] or 0).."/"..tostring(perPeo),
            mSelectionPeriod = common:getLanguageString("@TournamentSelectionPeriod1")
        }
      
        local nodeVisible = {
            mSeal1 = false,
            mSeal2 = false,
            mSeal3 = false
        }
        if ABManager.teamJoinInfo.selfTeamIndex~=nil then
            nodeVisible["mSeal"..ABManager.teamJoinInfo.selfTeamIndex] = true
        end

        --战场附加属性
        local config = ABManager:getConfigDataByKey("Battlefield")
        local attrStr = nil
        for i=1,#config do
            if EquipManager:getAttrGrade(config[i].attrId) == Const_pb.GODLY_ATTR 
					    and not EquipManager:isGodlyAttrPureNum(config[i].attrId) then
					attrStr = string.format(" %+d%%", config[i].value);
				else
					attrStr = string.format(" %+d", config[i].value);
				end
                labelStr["mBattlefieldName"..i] = common:getLanguageString("@ABTeamTag",config[i].name)
				labelStr["mBattlefieldAttr"..i] = common:getLanguageString("@CanGet",common:getLanguageString("@AttrName_" .. config[i].attrId) .. attrStr);
				NodeHelper:setLabelOneByOne(container,"mJoinTex"..i,"mBattlefieldName"..i,5)
        end

        NodeHelper:setNodesVisible(container,nodeVisible)
        NodeHelper:setStringForLabel(container, labelStr);
    end
end

function ABJoinPage:onExecute(container)
	self:onTimer(container,"stageLeftTime","mFinishNum")

    ABManager:autoChangeState()
end

function ABJoinPage:onReceiveMessage(container)
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
function ABJoinPage:onReturn(container)
    PageManager.changePage("ABMainPage")
end

function ABJoinPage:onTeamInformation(container)
    setABTeamInfoCtrlBtn(true)
    PageManager.viewAllianceTeamInfo(GuildDataManager:getGuildId())
end

function ABJoinPage:onHelp(container)
    showABHelpPageAtIndex(1)
end

function ABJoinPage:onJoinHighland(container)
    ABJoinPage:onJoin(1)
end

function ABJoinPage:onJoinJungle(container)
    ABJoinPage:onJoin(2)
end

function ABJoinPage:onJoinValley(container)
    ABJoinPage:onJoin(3)
end

function ABJoinPage:onJoin(index)
    local AllianceBattle_pb = require("AllianceBattle_pb")
	local msg = AllianceBattle_pb.HPAllianceTeamJoin();
	msg.teamIndex = index
	common:sendPacket(opcodes.ALLIANCE_TEAM_JOIN_INFO_C, msg,false);
end
