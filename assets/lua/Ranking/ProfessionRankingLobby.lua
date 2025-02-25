local thisPageName = "Ranking.ProfessionRankingLobby"
require "HP_pb"
local Activity4_pb = require("Activity4_pb")
local Ranks_pb = require("Ranks_pb")
local Const_pb = require("Const_pb")
require("Util.RedPointManager")
local RankingEXPage=require("Ranking.ProfessionRankingEXPage")
local RankRewardData=require("Ranking.ProfessionRankingRewardData")

local opcodes =
    {
        ACTIVITY153_S=HP_pb.ACTIVITY153_S,
        RANKING_LIST_S=HP_pb.RANKING_LIST_S
    }
local option = {
    ccbiFile = "FightingRankingLobby.ccbi",
    handlerMap = {
        onBP="onBP",
        onLv="onLv",
        onStage="onStage",
        onLight="onLight",
        onDark="onDark",
        onFire="onFire",
        onWater="onWater",
        onWind="onWind",
        ---------------
        onHelp="onHelp",
        onReturn="onReturn"
    },
    opcode = opcodes,
};
local RankingLobby = {}
local RankType = {
    -- �ԤO�Ʀ�]
    [1] = { [1] = Const_pb.SCORE_ALL_RANK, [2] = Const_pb.SCORE_PROFJS_RANK, [3] = Const_pb.SCORE_PROFGS_RANK, [4] = Const_pb.SCORE_PROFCS_RANK },
    -- ���űƦ�] ?�X��?    ?�h��?    �}�ⵥ?    ���h��?
    [2] = { [1] = Const_pb.LEVEL_ALL_RANK, [2] = Const_pb.LEVEL_PROFJS_RANK, [3] = Const_pb.LEVEL_PROFGS_RANK, [4] = Const_pb.LEVEL_PROFCS_RANK },
    -- ���d�Ʀ�  ���q?�d ??��
    [3] = { [1] = Const_pb.CUSTOMPASS_BOSS_RANK, [2] = Const_pb.CUSTOMPASS_TRAINING_RANK },
    -- �u?�Ʀ� ��?  ���W�� �n�P��
    [4] = { [1] = Const_pb.ALLIANCE_LEVEL_RANK, [2] = Const_pb.ALLIANCE_VITALITY_RANK, [3] = Const_pb.ALLIANCE_BOSSHARM_RANK },
    --�ݩʱƦ�   ��,��,��,��,�t
    [5] = { [1] = Const_pb.HERO_FIRE_RANK, [2] = Const_pb.HERO_WATER_RANK, [3] = Const_pb.HERO_WIND_RANK, [4] = Const_pb.HERO_LIGHT_RANK, [5]=Const_pb.HERO_DARK_RANK  }
}
local SubBtnText = {
    -- ?�O�Ʀ�]
    [1] = { [1] = "@RankAllTxt", [2] = "@ProfessionName_1", [3] = "@ProfessionName_2", [4] = "@ProfessionName_3" },
    -- ��?�Ʀ�] ?�X��?    ?�h��?    �}�ⵥ?    ���h��?
    [2] = { [1] = "@RankAllTxt", [2] = "@ProfessionName_1", [3] = "@ProfessionName_2", [4] = "@ProfessionName_3" },
    -- ?�d�Ʀ�  ���q?�d    ??��
    [3] = { [1] = "@FightingRankinglable5", [2] = "@FightingRankinglable6" },
    -- �u?�Ʀ�
    [4] = { [1] = "@FightingRankinglable7", [2] = "@FightingRankinglable8", [3] = "@FightingRankinglable9" }
}

local RankInfoMessage = {
    -- �ԤO�Ʀ�]
    [1] = { [1] = "", [2] = "", [3] = "", [4] = "" },
    -- ���űƦ�] ?�X��?    ?�h��?    �}�ⵥ?    ���h��?
    [2] = { [1] = "Lv.", [2] = "Lv.", [3] = "Lv.", [4] = "Lv." },
    -- ���d�Ʀ�  ���q?�d    ??��
    [3] = { [1] = "", [2] = "" },
    -- �u?�Ʀ�
    [4] = { [1] = "Lv.", [2] = "", [3] = "" }
}
local ProfessionType = {
    --�ԤO
    [1] = { [1] = 1 },
    -- ����
    [2] = { [1] = 2 },
    -- ���d
    [3] = { [1] = 3 },
    -- �u�|
    [4] = { [1] = 9 },
    --�ݩ�  ��,��,��,��,�t
    [5] = { [1] = 7, [2] = 6, [3] = 8, [4] = 4, [5] = 5  }
}
 ProfessionRankingEXCacheInfo = {
        [1] = { [1] = { },[2] = { },[3] = { },[4] = { } },
        [2] = { [1] = { },[2] = { },[3] = { },[4] = { } },
        [3] = { [1] = { },[2] = { },[3] = { },[4] = { } },
        [4] = { [1] = { },[2] = { },[3] = { },[4] = { } },
        [5] = { [1] = { },[2] = { },[3] = { },[4] = { },[5] = { } },
    }
local PageInfo = {
    curProType = 1,
    subType = 1,
    -- ProfessionType.WARRIOR,
    selfRank = "--",
    selfRankInfo = { },
    rankInfos = { },
    viewHolder = { },
    -- ���a�Ʀ�?�u
    playerItemInfo = nil,
    -- ??�Ʀ�?�u
    allianceItemInfo = nil,
    -- �ۤv���Ʀ�?�u
    mySelf = nil,
    -- �ۤv??�Ʀ�?�u
    mySelfAlliance = nil,
    itemContainer = { }
}

local RewardDataInfo={}

function RankingLobby:onEnter(container)
    self.container = container
    self:registerPacket(container)
    local Bg=container:getVarNode("mBg")
    Bg:setScale(NodeHelper:getScaleProportion())

     for i=1,5 do 
         for j=1,5 do
             if RewardDataInfo[i][j] and RewardDataInfo[i][j]["Count"]>0 then
                  NodeHelper:setNodesVisible(self.container,{["mRedNode"..i.."_"..j]=true})
             else
                  NodeHelper:setNodesVisible(self.container,{["mRedNode"..i.."_"..j]=false})
             end
         end
     end
     container:registerMessage(MSG_REFRESH_REDPOINT)
end

function RankingLobby:getPageInfo()--�I���@����s�@��
    --Rank
     local msg = Ranks_pb.HPTopRankListGet()
     msg.rankType = RankType[PageInfo.curProType][PageInfo.subType]
     common:sendPacket(HP_pb.RANKING_LIST_C, msg, true)

     local Data=RewardDataInfo[PageInfo.curProType][PageInfo.subType]
     RankingEXPage:SetRewardInfo(Data["CanGetTable"],Data["AchiveTable"],Data["PageTable"],Data["PlayerInfo"])
end
function RankingLobby:onBP()
    PageInfo.curProType=1
    PageInfo.subType=1
    RankingLobby:getPageInfo()
end
function RankingLobby:onLv()
    PageInfo.curProType=2
    PageInfo.subType=1
    RankingLobby:getPageInfo()
end
function RankingLobby:onStage()
    PageInfo.curProType=3
    PageInfo.subType=1
    RankingLobby:getPageInfo()
end
function RankingLobby:onFire()
    PageInfo.curProType=5
    PageInfo.subType=1
    RankingLobby:getPageInfo()
end
function RankingLobby:onWater()
    PageInfo.curProType=5
    PageInfo.subType=2
    RankingLobby:getPageInfo()
end
function RankingLobby:onWind()
    PageInfo.curProType=5
    PageInfo.subType=3
    RankingLobby:getPageInfo()
end
function RankingLobby:onLight()
    PageInfo.curProType=5
    PageInfo.subType=4
    RankingLobby:getPageInfo()
end
function RankingLobby:onDark()
    PageInfo.curProType=5
    PageInfo.subType=5
    RankingLobby:getPageInfo()
end

function RankingLobby:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_PLAYER_RANKING)
end
function RankingLobby:onReturn(container)
    --MainFrame_onMainPageBtn()
    container:removeMessage(MSG_REFRESH_REDPOINT)
    PageManager.popPage(thisPageName)
    HasRedNode=false
end

function RankingLobby:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.RANKING_LIST_S then
        local msg = Ranks_pb.HPTopRankListRet()
        if PageInfo.curProType==5 then
            msg=Ranks_pb.HeroTopRankListRet()
        end
        msg:ParseFromString(msgBuff)
        ProfessionRankingEXCacheInfo[PageInfo.curProType][PageInfo.subType] = msg
        RankingEXPage:SetInfo(PageInfo.curProType,PageInfo.subType,RankType[PageInfo.curProType][PageInfo.subType])
        PageManager.pushPage("Ranking.ProfessionRankingEXPage")

    
        return
    end
end
function RankingLobby:refreshData()
    RewardDataInfo=RankRewardData:GetInfo()
    self:refreshAllPoint(container)
    local Data=RewardDataInfo[PageInfo.curProType][PageInfo.subType]
    RankingEXPage:SetRewardInfo(Data["CanGetTable"],Data["AchiveTable"],Data["PageTable"],Data["PlayerInfo"])
end

function RankingLobby:GetReward(data)
     local msg =Activity4_pb.RankGiftReq()
     msg.action=1
     for key,val in pairs (data) do
        msg.cfgId:append(tonumber(key))
     end
     common:sendPacket(HP_pb.ACTIVITY153_C, msg, true)
end
function RankingLobby:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function RankingLobby:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(container)
    end
end
function RankingLobby:refreshAllPoint(container)
    for i = 1, 5 do 
        for j = 1, 5 do
            if RewardDataInfo[i][j] then
                local pageId = math.floor(RedPointManager.PAGE_IDS.RANKING_BP_ENTRY / 10) * 10 + ProfessionType[i][j]
                NodeHelper:setNodesVisible(self.container, { ["mRedNode"..i.."_"..j] = RedPointManager_getShowRedPoint(pageId) })
            end
        end
    end
end
function RankingLobby:getTrueType(curProType, subType)
    if ProfessionType[curProType] and ProfessionType[curProType][subType] then
        return ProfessionType[curProType][subType]
    end
    return 0
end

local CommonPage = require('CommonPage')
RankingLobby = CommonPage.newSub(RankingLobby, thisPageName, option)

return RankingLobby
