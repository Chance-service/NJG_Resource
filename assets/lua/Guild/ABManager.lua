----------------------------------------------------------------------------------
--[[
FILE:			ABManager.lua
ENCODING:		UTF-8, no-bomb
DESCRIPTION:	��������
--]]
local ABConfig = require("Guild.ABConfig")
local BaseDataHelper = require("BaseDataHelper")
local HP_pb = require("HP_pb")
local AllianceBattle_pb = require("AllianceBattle_pb")
local GuildDataManager = require("Guild.GuildDataManager")
local ABManager = BaseDataHelper:new(ABConfig) 

local AB_pb = require("AllianceBattle_pb")

-- �������Ϣ
ABManager.fightList = nil
ABManager.lastFightList = nil
ABManager.FightReport = {}

--����������
ABManager.selfInspireNum = -1   
ABManager.totalSelfInspireNum = -1

ABManager.waitPacket=false
ABManager.waitCount = 0
ABManager.waitMaxCount = 0

ABManager.isLookGuildFightFlag = false --�ж��Ƿ��ǲ鿴����ս������
--[[enum ABState
{
	// ׼���׶�
	PREPARE   = 0;

	FS32_16_WAIT = 101;
	FS32_16_FIGHTING = 102;
	FS16_8_WAIT = 103;
	FS16_8_FIGHTING = 104;
	FS8_4_WAIT = 105;
	FS8_4_FIGHTING = 106;
	FS4_2_WAIT = 107;
	FS4_2_FIGHTING = 108;
	FS2_1_WAIT = 109;
	FS2_1_FIGHTING = 110;
	// չʾ�׶�
	SHOW_TIME = 2;
}--]]

--ս��״̬��������ע��
ABManager.battleState = AB_pb.PREPARE

-- �׶�ʣ��ʱ��
ABManager.stageLeftTime = 0
ABManager.CurrentFightReportId = 0
ABManager.teamJoinInfo = {}
--Ϊ��ս��������ʾ�����BUFF
ABManager.ViewBattleAdditionMsg = {}
ABManager.refreshLeftTime = true

ABManager.hasBet = false
 
--�Զ���ת�ӿڣ�Ŀǰ��ABMainPagee,ABJoinPage,ABTeamFightPage,ABRewardPage�ĸ�ҳ���onExecute��ʹ��
function ABManager:autoChangeState()
    if ABManager.stageLeftTime <= 0 and ABManager.waitPacket==false then 
        ABManager.waitPacket = true
        local AllianceBattle_pb = require("AllianceBattle_pb")
	    local msg = AllianceBattle_pb.HPAFMainEnter();
	    common:sendPacket(HP_pb.ALLIANCE_BATTLE_ENTER_C, msg);
    end

    --�����������
    if ABManager.waitMaxCount==0 then
        local ClientSettingManager = require("ClientSettingManager")
        local hasKey = false
        local count = 0
        hasKey,count =  ClientSettingManager:findAndGetValueByKey("allianceBattleAutoRefresh") 
        if hasKey then
            ABManager.waitMaxCount = tonumber(count)
        end
        if ABManager.waitMaxCount<=0 then
            ABManager.waitMaxCount = 200
        end
    end


    --��������æ������ط�����
    if ABManager.waitPacket then
        ABManager.waitCount = ABManager.waitCount + 1

        if ABManager.waitCount>=ABManager.waitMaxCount then
            ABManager.waitCount = 0
            local AllianceBattle_pb = require("AllianceBattle_pb")
	        local msg = AllianceBattle_pb.HPAFMainEnter();
	        common:sendPacket(HP_pb.ALLIANCE_BATTLE_ENTER_C, msg);
        end
    end
end
--���ù������ƺ�BUFF��Ϣ������17v17����
function ABManager:setBattleExtralParams(baseinfo,info)
    if baseinfo==nil or info==nil then return end
    --��ʾ�������ƺ�����
    local config = self:getConfigDataByKey("Battlefield")
    local attrStr1 = nil
    local attrStr2 = nil
    if EquipManager:getAttrGrade(config[info.leftTeamIndex].attrId) == Const_pb.GODLY_ATTR 
				and not EquipManager:isGodlyAttrPureNum(config[info.leftTeamIndex].attrId) then
		attrStr1 = string.format(" %+d%%", config[info.leftTeamIndex].value);
	else
		attrStr1 = string.format(" %+d", config[info.leftTeamIndex].value);
	end
    if EquipManager:getAttrGrade(config[info.rightTeamIndex].attrId) == Const_pb.GODLY_ATTR 
				and not EquipManager:isGodlyAttrPureNum(config[info.rightTeamIndex].attrId) then
		attrStr2 = string.format(" %+d%%", config[info.rightTeamIndex].value);
	else
		attrStr2 = string.format(" %+d", config[info.rightTeamIndex].value);
	end

    self.ViewBattleAdditionMsg.addi1 = common:getLanguageString("@AttrName_" .. config[info.leftTeamIndex].attrId) .. attrStr1
    self.ViewBattleAdditionMsg.addi2 = common:getLanguageString("@AttrName_" .. config[info.rightTeamIndex].attrId) .. attrStr2

    self.ViewBattleAdditionMsg.name1 = baseinfo.leftName
    self.ViewBattleAdditionMsg.name2 = baseinfo.rightName
    --
end
--���ս����Ϣ
function ABManager:getAFRoundById(id)
    if ABManager.fightList==nil or ABManager.fightList.round32_16 == nil then
        return nil
    end


    for i=1,#ABManager.fightList.round32_16 do
        if ABManager.fightList.round32_16[i].id == id then
            return 1
        end
    end

    for i=1,#ABManager.fightList.round16_8 do
        if ABManager.fightList.round16_8[i].id == id then
            return 2
        end
    end

    for i=1,#ABManager.fightList.round8_4 do
        if ABManager.fightList.round8_4[i].id == id then
            return 3
        end
    end

    for i=1,#ABManager.fightList.round4_2 do
        if ABManager.fightList.round4_2[i].id == id then
            return 4
        end
    end

    for i=1,#ABManager.fightList.round2_1 do
        if ABManager.fightList.round2_1[i].id == id then
            return 5
        end
    end
    return nil
end
--��õ�ǰ����
function ABManager:getCurrentRound()
    if ABManager.fightList==nil or ABManager.fightList.round32_16 == nil then
        return 0
    end

    local round = 1
    if (#ABManager.fightList.round16_8) > 0 then
        round = 2
    end
    if (#ABManager.fightList.round8_4) > 0 then
        round = 3
    end
    if (#ABManager.fightList.round4_2) > 0 then
        round = 4
    end
    if (#ABManager.fightList.round2_1) > 0 then
        round = 5
    end

    return round
end
--��õ�ǰս����ս��
function ABManager:getAFUnitById(id)
    if ABManager.fightList==nil or ABManager.fightList.round32_16 == nil then
        return nil
    end


    for i=1,#ABManager.fightList.round32_16 do
        if ABManager.fightList.round32_16[i].id == id then
            return ABManager.fightList.round32_16[i]
        end
    end

    for i=1,#ABManager.fightList.round16_8 do
        if ABManager.fightList.round16_8[i].id == id then
            return ABManager.fightList.round16_8[i]
        end
    end

    for i=1,#ABManager.fightList.round8_4 do
        if ABManager.fightList.round8_4[i].id == id then
            return ABManager.fightList.round8_4[i]
        end
    end

    for i=1,#ABManager.fightList.round4_2 do
        if ABManager.fightList.round4_2[i].id == id then
            return ABManager.fightList.round4_2[i]
        end
    end

    for i=1,#ABManager.fightList.round2_1 do
        if ABManager.fightList.round2_1[i].id == id then
            return ABManager.fightList.round2_1[i]
        end
    end
    return nil
end
--ˢ�¶�ע��Ϣ
function ABManager:refreshBetInfo(id)
    if ABManager.fightList==nil or ABManager.fightList.round32_16 == nil then
        ABManager.hasBet = false
        return 
    end


    for i=1,#ABManager.fightList.round32_16 do
        if ABManager.fightList.round32_16[i]:HasField("investedId") and ABManager.fightList.round32_16[i].state==AllianceBattle_pb.AF_NONE then
            ABManager.hasBet = true
            return
        end
    end

    for i=1,#ABManager.fightList.round16_8 do
        if ABManager.fightList.round16_8[i]:HasField("investedId") and ABManager.fightList.round16_8[i].state==AllianceBattle_pb.AF_NONE then
            ABManager.hasBet = true
            return
        end
    end

    for i=1,#ABManager.fightList.round8_4 do
        if ABManager.fightList.round8_4[i]:HasField("investedId") and ABManager.fightList.round8_4[i].state==AllianceBattle_pb.AF_NONE then
            ABManager.hasBet = true
            return
        end
    end

    for i=1,#ABManager.fightList.round4_2 do
        if ABManager.fightList.round4_2[i]:HasField("investedId") and ABManager.fightList.round4_2[i].state==AllianceBattle_pb.AF_NONE then
            ABManager.hasBet = true
            return
        end
    end

    for i=1,#ABManager.fightList.round2_1 do
        if ABManager.fightList.round2_1[i]:HasField("investedId") and ABManager.fightList.round2_1[i].state==AllianceBattle_pb.AF_NONE then
            ABManager.hasBet = true
            return
        end
    end

    ABManager.hasBet = false
end
--����Ͻ�ս���е�ս��
function ABManager:getLastAFUnitById(id)
    if ABManager.lastFightList==nil or ABManager.lastFightList.round32_16 == nil then
        return nil
    end


    for i=1,#ABManager.lastFightList.round32_16 do
        if ABManager.lastFightList.round32_16[i].id == id then
            return ABManager.lastFightList.round32_16[i]
        end
    end

    for i=1,#ABManager.lastFightList.round16_8 do
        if ABManager.lastFightList.round16_8[i].id == id then
            return ABManager.lastFightList.round16_8[i]
        end
    end

    for i=1,#ABManager.lastFightList.round8_4 do
        if ABManager.lastFightList.round8_4[i].id == id then
            return ABManager.lastFightList.round8_4[i]
        end
    end

    for i=1,#ABManager.lastFightList.round4_2 do
        if ABManager.lastFightList.round4_2[i].id == id then
            return ABManager.lastFightList.round4_2[i]
        end
    end

    for i=1,#ABManager.lastFightList.round2_1 do
        if ABManager.lastFightList.round2_1[i].id == id then
            return ABManager.lastFightList.round2_1[i]
        end
    end
    return nil
end

function ABManager:onReceivePacket(container,page)
    local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
    if opcode == HP_pb.ALLIANCE_TEAM_BASIC_INFO_S then
        local msg = AllianceBattle_pb.HPAllianceTeamEnterRet();
		msg:ParseFromString(msgBuff);
		
		ABManager.teamJoinInfo.teamSize = msg.teamSize
		ABManager.teamJoinInfo.selfTeamIndex = msg.selfTeamIndex
		
		page:refreshPage(container)
    elseif opcode == HP_pb.ALLIANCE_BATTLE_TEAM_FIGHT_INFO_S then
		local msg = AllianceBattle_pb.HPAllianceTeamFightRet();
		msg:ParseFromString(msgBuff);

        if msg.isSelfCurBattle==false then
            ABManager.FightReport[ABManager.CurrentFightReportId] = msg
            page:refreshPage(container)
        else
            ABManager.FightReport.CurrentFight = msg
            page:refreshPage(container)
            page:rebuildAllItem(container)
        end
    elseif opcode == HP_pb.ALLIANCE_BATTLE_FIGHT_BET_S then
        local msg = AllianceBattle_pb.HPInvestRet();
		msg:ParseFromString(msgBuff);

        local info = self:getAFUnitById(msg.versusId)
        info.investedId = msg.allianceId

        self:refreshBetInfo()

        page:refreshPage(container)   
        PageManager.refreshPage("ABFightListPage") 
        PageManager.refreshPage("ABMainPage")
	elseif opcode == HP_pb.ALLIANCE_BATTLE_FIGHT_REPORT_S then
	    local msg = AllianceBattle_pb.HPAllianceTeamFightReportRet();
		msg:ParseFromString(msgBuff);
	    
	    PageManager.viewBattlePage(msg.battleInfo,self.ViewBattleAdditionMsg.name1,self.ViewBattleAdditionMsg.name2,
                                                    self.ViewBattleAdditionMsg.addi1,self.ViewBattleAdditionMsg.addi2)
    elseif opcode == HP_pb.ALLIANCE_BATTLE_LAST_STAGE_FIGHT_INFO_S then
	    local msg = AllianceBattle_pb.HPLastBattleFightInfoRet();
		msg:ParseFromString(msgBuff);
	    
        if msg:HasField("fightList") then 
            self.lastFightList = msg.fightList
            PageManager.pushPage("ABLastSessionPage")
        else
            --���Ͻ�ս��������˷��ش��������������ʲô
        end
    elseif opcode == HP_pb.ALLIANCE_BATTLE_INSPIRE_S then
        --�������
        local msg = AllianceBattle_pb.HPInspireRet();
		msg:ParseFromString(msgBuff);
	    MessageBoxPage:Msg_Box_Lan("@ABFightListInspireSuccess")
        
        ABManager.selfInspireNum = msg.inspireTimes   
        ABManager.totalSelfInspireNum = msg.totalInspireTimes

        if ABManager.selfInspireNum >=5 then 
           local totalInspirePer = ABManager:getConfigDataByKeyAndIndex("InspireRewardPercent",ABManager.totalSelfInspireNum)
           local message = common:getLanguageString("@ABFightListInspireReachLimitMsg",totalInspirePer).."1"
           PageManager.refreshPage("DecisionMoreLinePage",message);
        else       
            local costDiamond = ABManager:getConfigDataByKeyAndIndex("InspireCostDiamond",ABManager.selfInspireNum)
            assert(costDiamond~=nil,"Error in costDiamond~=nil")
            local bloodPer = ABManager:getConfigDataByKeyAndIndex("InspireBloodEnhancePercent",ABManager.selfInspireNum)
            assert(bloodPer~=nil,"Error in bloodPer~=nil")
            local attactPer = ABManager:getConfigDataByKeyAndIndex("InspireAttactEnhancePercent",ABManager.selfInspireNum)
            assert(attactPer~=nil,"Error in attactPer~=nil")
            local totalInspirePer = ABManager:getConfigDataByKeyAndIndex("InspireRewardPercent",ABManager.totalSelfInspireNum)
            assert(totalInspirePer~=nil,"Error in totalInspirePer~=nil")
            local rewardPerTime = ABManager:getConfigDataByKey("InspireRewardPerTime")

	        local decisionMsg = common:getLanguageString("@ABFightListInspireMsg",costDiamond,
            bloodPer,attactPer,totalInspirePer,ABManager.selfInspireNum,ABManager.totalSelfInspireNum)
            PageManager.refreshPage("DecisionMoreLinePage",decisionMsg);
        end
	end
end

--receive the enter packet
function ABManager:onReceiveEnterPacket(msg)  
	ABManager.battleState  = msg.battleState	
	ABManager.stageLeftTime = msg.leftTime

    if ABManager.stageLeftTime>0 then
        ABManager.waitPacket=false
    end
	--������Ϣ
	if msg:HasField("fightList") then
		ABManager.fightList = msg.fightList;
        ABManager:refreshBetInfo(id)
	end
    if msg:HasField("rankList") then
		ABManager.rankList = msg.rankList;
	end	
	
	if msg:HasField("teamFight") then
        ABManager.FightReport.CurrentFight = msg.teamFight
    end

    if msg:HasField("selfInspireNum") then
        ABManager.selfInspireNum = msg.selfInspireNum
    end

    if msg:HasField("totalSelfInspireNum") then
        ABManager.totalSelfInspireNum = msg.totalSelfInspireNum
    end

    ABManager.hasDraw = false
	if msg:HasField("hasDraw") then
        ABManager.hasDraw = msg.hasDraw
    end
	self:enterMainOrTeamFightPage()
end

function ABManager:getHasDraw()
    return ABManager.hasDraw
end

function ABManager:setHasDraw(_bool)
    ABManager.hasDraw = _bool
end

function ABManager:enterMainPage() 
	local currPage = MainFrame:getInstance():getCurShowPageName();
	local pageName = "ABMainPage"
	--ˢ�»����л�ҳ��
	if currPage == pageName then 		
		PageManager.refreshPage(pageName); 
	else
		PageManager.changePage(pageName)
	end		
end


--��鹫���Ƿ���ĳ��ս���ִ�
function ABManager:checkGuildInRound(guildId,roundInfo)  
	local size = #roundInfo
	if size == 0 then
		return false		
	end
	for i=1,size do
		local unitInfo = roundInfo[i]
		if unitInfo.leftId == guildId or unitInfo.rightId == guildId then
			return true
		end
	end
	return false
end

--��鹫���Ƿ�����ս��
function ABManager:checkGuildInFightList(guildId)  
    if guildId == nil then
        guildId = GuildDataManager:getGuildId()	
    end
	if guildId == nil or ABManager.fightList == nil then return false end; 
	local roundInfo = {}
	if ABManager.battleState == AB_pb.FS32_16_FIGHTING then
		roundInfo = ABManager.fightList.round32_16		
	elseif ABManager.battleState == AB_pb.FS16_8_FIGHTING then 
		roundInfo = ABManager.fightList.round16_8	
	elseif ABManager.battleState == AB_pb.FS8_4_FIGHTING then
		roundInfo = ABManager.fightList.round8_4	
	elseif ABManager.battleState == AB_pb.FS4_2_FIGHTING then
		roundInfo = ABManager.fightList.round4_2	
	elseif ABManager.battleState == AB_pb.FS2_1_FIGHTING then
		roundInfo = ABManager.fightList.round2_1	
	end
	return self:checkGuildInRound(guildId,roundInfo)
end
--�ж��Ƿ�������ս���׶�
function ABManager:checkIsFightingState()  
	if ABManager.battleState == AB_pb.FS32_16_FIGHTING 
	or ABManager.battleState == AB_pb.FS16_8_FIGHTING  
	or ABManager.battleState == AB_pb.FS8_4_FIGHTING 
	or ABManager.battleState == AB_pb.FS4_2_FIGHTING 
	or ABManager.battleState == AB_pb.FS2_1_FIGHTING then
		return true	
	end
	return false
end

function ABManager:enterMainOrTeamFightPage()  
	--û�н��빤�ᣬֱ�ӽ�����ҳ��
	local curGuildId = GuildDataManager:getGuildId()	
	if AllianceOpen==false or curGuildId==nil then
        if ABManager.battleState == AB_pb.SHOW_TIME then
            return PageManager.changePage("ABRewardPage")
        end
        return self:enterMainPage()
	end	
    --�����������
	if not Golb_Platform_Info.is_entermate_platform then
		if AllianceOpen and ABManager.battleState == AB_pb.PREPARE and 
			ABManager.rankList~=nil and ABManager.rankList.hasJoined==false then
			require("ABHelpPage")
			return showABHelpPageAtIndex()
		end
	end

	if ABManager.battleState <100 or ABManager.battleState>200 then
        if ABManager.battleState == AB_pb.SHOW_TIME then
            return PageManager.changePage("ABRewardPage")
        end
        return self:enterMainPage()
	else		
		local isEven = common:numberIsEven(ABManager.battleState)
		--ֻ��״̬>100��������ս��״̬�������Լ��Ĺ�����ս���������棬�Ž������ս��ҳ��
		if isEven then
			if self:checkGuildInFightList(curGuildId) == true and ABManager.FightReport.CurrentFight~=nil then
				return PageManager.changePage("ABTeamFightPage")
			else
				return self:enterMainPage()
			end				
		else
			return self:enterMainPage()
		end
	end				
end


function ABManager_reset()  
	-- �������Ϣ
    ABManager.fightList = nil
    ABManager.lastFightList = nil
    ABManager.FightReport = {}
    ABManager.waitPacket=false
    ABManager.waitCount = 0
    ABManager.waitMaxCount = 0
    
    --ս��״̬��������ע��
    ABManager.battleState = AB_pb.PREPARE

    -- �׶�ʣ��ʱ��
    ABManager.stageLeftTime = 0
    ABManager.CurrentFightReportId = 0
    ABManager.teamJoinInfo = {}
    --Ϊ��ս��������ʾ�����BUFF
    ABManager.ViewBattleAdditionMsg = {}
    ABManager.refreshLeftTime = true
    ABManager.selfInspireNum = -1   
    ABManager.totalSelfInspireNum = -1
    ABManager.hasBet = false
end

function ABManager_ResetForAssembly()
    PageManager.refreshPage("ABManager","reset")
end

return ABManager 