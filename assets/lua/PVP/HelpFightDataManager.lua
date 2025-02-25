local HP_pb = require("HP_pb")
local EighteenPrinces_pb = require("EighteenPrinces_pb")

local HelpFightMapCfg = ConfigManager.getHelpFightMapCfg()
local multiMonsterCfg = ConfigManager.getMultiMonsterCfg()
local skillCfg = ConfigManager.getSkillCfg()
local UserInfo = require("PlayerInfo.UserInfo")
local OSPVPManager = require("OSPVPManager")

local HelpFightDataManager = {
    UseMedicalResult = nil ,
    FormationResult = nil,
    myHelpMercenary = nil , --自己的协战武将
    myMedicalItem = nil ,
    ChallengeData = {},
    HistoryInfo = {},
    FightHelpList = {},  -- 协战列表
    myFormationInfo = nil,
    myHelpFightBattleItem = {},
    isChallenge = false,
    helpFightMapCfg = nil,
    LayerInfo = nil,
    isJumpSelectRolePage = false , --跳转更换协战武将界面
    mChallengeLayer = 0,
    isNotice = false ,
}

function HelpFightDataManager:getHelpFightMapConfig()
    HelpFightDataManager.helpFightMapCfg = HelpFightMapCfg
    return HelpFightMapCfg
end

--协战历史请求
function HelpFightDataManager:sendEighteenPrincesHistoryReq()
    local msg = EighteenPrinces_pb.HPEighteenPrincesHelpHistoryReq()
    common:sendPacket(HP_pb.EIGHTEENPRINCES_HELP_HISTORY_C , msg ,false)
end

--协战历史返回
function HelpFightDataManager:EighteenPrincesHistoryFun(msg)
   local tmpData = {}
    tmpData.todayCount = msg.todayCount
    tmpData.historyInfos = msg.historyInfos
    HelpFightDataManager.HistoryInfo = tmpData
    table.sort(HelpFightDataManager.HistoryInfo.historyInfos, function(v1,v2)
        if v1.isGet == v2.isGet then
            return tonumber(v1.helpTime) > tonumber(v2.helpTime)
        else
            return v1.isGet < v2.isGet
        end
    end)
    return HelpFightDataManager.HistoryInfo
end

--协战奖励请求
function HelpFightDataManager:sendEighteenPrincesHelpRewardReq(historyId)
    local msg = EighteenPrinces_pb.HPEighteenPrincesHelpRewardReq()
    msg.historyId = historyId
    common:sendPacket(HP_pb.EIGHTEENPRINCES_HELP_REWARD_C , msg ,false)
end

function HelpFightDataManager:sendEighteenPrincesHelpAllRewardReq()
    local msg = EighteenPrinces_pb.HPEighteenPrincesOneKeyAwardReq()
    common:sendPacket(HP_pb.EIGHTEENPRINCES_HELP_ONEKEYAWARD_C , msg ,false)
end

--协战奖励返回
function HelpFightDataManager:EighteenPrincesHelpRewardFun(msg)
    for i = 1, #msg.historyId do
        for j = 1, #HelpFightDataManager.HistoryInfo.historyInfos do
            if HelpFightDataManager.HistoryInfo.historyInfos[j].historyId == msg.historyId[i] then
                HelpFightDataManager.HistoryInfo.historyInfos[j].isGet = 1
                break
            end
        end
    end
    table.sort(HelpFightDataManager.HistoryInfo.historyInfos, function(v1,v2)
        if v1.isGet == v2.isGet then
            return tonumber(v1.helpTime) < tonumber(v2.helpTime)
        else
            return v1.isGet < v2.isGet
        end
    end)
    return HelpFightDataManager.HistoryInfo
end

--修改协战武将请求
function HelpFightDataManager:sendHPEighteenPrincesChangeHelpReq(friendId)
    local msg = EighteenPrinces_pb.HPEighteenPrincesChangeHelpReq()
    msg.friendId = friendId
    common:sendPacket(HP_pb.EIGHTEENPRINCES_HELP_CHANGE_C , msg ,false)
end
--修改协战武将返回
function HelpFightDataManager:HPEighteenPrincesChangeHelpFun(msg)
    local msg = EighteenPrinces_pb.HPEighteenPrincesChangeHelpRet()
    common:sendPacket(HP_pb.EIGHTEENPRINCES_HELP_CHANGE_S , msg ,false)
end

--协战列表请求
function HelpFightDataManager:sendEighteenPrincesHelpListReq()
    local msg = EighteenPrinces_pb.HPEighteenPrincesHelpListReq()
    common:sendPacket(HP_pb.EIGHTEENPRINCES_HELP_LIST_C , msg ,false)
end

--协战列表返回
function HelpFightDataManager:EighteenPrincesHelpListFun(msg)
    local tmpData = {}
    tmpData.infos = msg.infos
    tmpData.playerId = msg.playerId
    HelpFightDataManager.FightHelpList = tmpData
    return HelpFightDataManager.FightHelpList
end


--协战布阵请求
function HelpFightDataManager:sendEighteenPrincesHelpFormationReq(msg)
    common:sendPacket(HP_pb.EIGHTEENPRINCES_FORMATION_C , msg ,false)
end

--协战布阵返回
function HelpFightDataManager:EighteenPrincesHelpFormationFun(msg)
--[[    local msg = EighteenPrinces_pb.HPEighteenPrincesFormationReq()
    msg.roleItemId = roleItemId
    common:sendPacket(HP_pb.EIGHTEENPRINCES_HELP_CHANGE_C , msg ,false)]]
end

--协战关卡信息请求
function HelpFightDataManager:sendEighteenPrincesLayerInfoReq()
    local msg = EighteenPrinces_pb.HPEighteenPrincesLayerInfoReq()
    common:sendPacket(HP_pb.EIGHTEENPRINCES_LAYER_INFO_C , msg ,false)
end

--协战关卡信息返回
function HelpFightDataManager:EighteenPrincesLayerInfoFun(msg)
   local tmpData = {}
    tmpData.layerId = msg.layerId
    tmpData.layerStatus = msg.layerStatus
    HelpFightDataManager.LayerInfo = msg
    return HelpFightDataManager.LayerInfo
end


--协战使用物品请求
function HelpFightDataManager:sendEighteenPrincesUseMedicalReq(type,count)
    local msg = EighteenPrinces_pb.HPEighteenPrincesUseMedicalReq()
    msg.type = type
    msg.count = count
    common:sendPacket(HP_pb.EIGHTEENPRINCES_USE_MEDICAL_C , msg ,false)
end

--使用物品返回
function HelpFightDataManager:EighteenPrincesUseMedicalFun(msg)
     HelpFightDataManager.UseMedicalResult = msg.result
     return HelpFightDataManager.UseMedicalResult
end

--协战关卡挑战请求
function HelpFightDataManager:sendEighteenPrincesChallengeReq(challengeLayer)
    HelpFightDataManager.LayerInfo.isFirstBattle = 1
    local msg = EighteenPrinces_pb.EighteenPrincesChallengeReq()
    msg.challengeLayer = challengeLayer + 1
    HelpFightDataManager.mChallengeLayer = challengeLayer + 1
    common:sendPacket(HP_pb.EIGHTEENPRINCES_CHALLENGE_C , msg ,false)
end

--挑战返回
function HelpFightDataManager:EighteenPrincesChallengeFun(msg)
    HelpFightDataManager.ChallengeData = msg
    return HelpFightDataManager.ChallengeData
end

--阵型请求
function HelpFightDataManager:sendEighteenPrincesFormationInfoReq()
    local msg = EighteenPrinces_pb.HPEighteenPrincesFormationInfoReq()
    common:sendPacket(HP_pb.EIGHTEENPRINCES_FORMATIONINFO_C , msg ,false)
end
--阵型返回
function HelpFightDataManager:EighteenPrincesFormationInfoFun(msg)
    HelpFightDataManager.myFormationInfo = msg
    for i = 1, #HelpFightDataManager.myFormationInfo.roleItem do
         HelpFightDataManager.myHelpFightBattleItem[HelpFightDataManager.myFormationInfo.roleItem[i].itemId] = HelpFightDataManager.myFormationInfo.roleItem[i]
    end
    for i = 1, #HelpFightDataManager.myFormationInfo.historyItem do
        HelpFightDataManager.myHelpFightBattleItem[HelpFightDataManager.myFormationInfo.historyItem[i].itemId] = HelpFightDataManager.myFormationInfo.historyItem[i]
    end
    return HelpFightDataManager.myFormationInfo
end

function HelpFightDataManager:isHaveHelpFightRole()
--[[    local count = 0
    for i = 1, #HelpFightDataManager.myFormationInfo.helpItem do
        count = count + 1
    end
    return count > 0]]
    local isHave = false
    if HelpFightDataManager.ChallengeData.helpItem and HelpFightDataManager.ChallengeData.helpItem.playerId then
        isHave = true
    end
    return isHave
end


--挑战返回
function HelpFightDataManager:EighteenPrincesChallengeFun(msg)
    local tmpData = {}
    tmpData.challengeResult = msg.challengeResult
    tmpData.battleInfo = msg.battleInfo
    tmpData.curLayer = msg.curLayer
    tmpData.reward = msg.reward
    HelpFightDataManager.ChallengeData = msg
    return HelpFightDataManager.ChallengeData
end

function HelpFightDataManager:isOpen()
    local isOpen = false
    if UserInfo.roleInfo.level >= 39 and HelpFightDataManager.myHelpMercenary then
        isOpen = true
    end
    return isOpen
end



function HelpFightDataManager:returnNotice()
    return HelpFightDataManager.isNotice
end



return HelpFightDataManager