local UserInfo = require("PlayerInfo.UserInfo");
local WorldBossManager = {}

WorldBossManager.showMainPageButton = nil
WorldBossManager.selfAttack = nil
WorldBossManager.selfAttacksTimes = nil
WorldBossManager.selfHarmRank = nil
WorldBossManager.selfAllianceRank = nil
WorldBossManager.selfAllianceHarm = {}
WorldBossManager.enterFinalPageFrom = 1 -- 1从PVPActivityPage 进入 2从 guildPage进入

WorldBossManager.StartTime = {}
WorldBossManager.isBossDead = nil
WorldBossManager.isShowHandAni = true    --是否显示过手触摸动画   默认为提示过  这个值在GVEBuffSelectPage onEnter里面设置为false
WorldBossManager.harm = nil
WorldBossManager.AllianceHarm = {}
WorldBossManager.AllianceHarmLen = 0
WorldBossManager.BossState = nil
WorldBossManager.selectBuff = 0
WorldBossManager.WorldBossAttrInfo = {
       npcId = nil,
       roleItemId = nil,
       monsterId = nil,
       name = nil,
       level = nil,
       maxHp = nil
   }
WorldBossManager.leftTime = nil
WorldBossManager.needRebirthCost = nil
WorldBossManager.rebirthLeftTime = nil
WorldBossManager.actionLeftTime = nil
WorldBossManager.autoJoinState = nil
WorldBossManager.currBossHp = nil
WorldBossManager.currBossFailingAttrInfo = nil
WorldBossManager.currBossFailingEndTime = 0
WorldBossManager.worldBossFailingType = nil
WorldBossManager.WorldBossFightClickPoint = nil
WorldBossManager.WorldBossFightIsFailing = nil
WorldBossManager.curRankList = {}
WorldBossManager.curAllianceRankList = {}
WorldBossManager.lastRankList = {}
WorldBossManager.lastKingInfo = nil
WorldBossManager.lastAllianceRankList = {}
WorldBossManager.curRank = nil
WorldBossManager.curAllianceRank = nil
WorldBossManager.challengTime = 0

--BossRankItem = {
--   playerName = nil,
--   harm = nil,
--   rewardInfo = nil,
--   rankIndex = nil,
--   item_type = nil
--}

function WorldBossManager.getBossType()
     if WorldBossManager.WorldBossAttrInfo.npcId ~=  nil then 
         if WorldBossManager.WorldBossAttrInfo.npcId ~= 0 then
               return "ActivityBoss"
         end
     end
    if WorldBossManager.WorldBossAttrInfo.roleItemId ~=  nil then 
         if WorldBossManager.WorldBossAttrInfo.roleItemId ~= 0 then
               return "player"
         end
     end
     if WorldBossManager.WorldBossAttrInfo.monsterId ~=  nil then 
         if WorldBossManager.WorldBossAttrInfo.monsterId ~= 0 then
               return "Monster"
         end
     end
end

function WorldBossManager.GetSpineConfig()
    if WorldBossManager.getBossType() == "ActivityBoss" then
        return GameConfig.WorldBoss[WorldBossManager.WorldBossAttrInfo.npcId].SpineAvatar
    end
    
    local roleId = -1
    if WorldBossManager.getBossType() == "player" then
       roleId = WorldBossManager.WorldBossAttrInfo.roleItemId
    end
    if WorldBossManager.getBossType() == "Monster" then
       local MonsterCfg = ConfigManager.getMonsterCfg()
       roleId = MonsterCfg[WorldBossManager.WorldBossAttrInfo.monsterId]["spineId"]
    end

    return ConfigManager.getRoleCfg()[roleId].spine
end

function WorldBossManager.GetNormalPic()
	local RoleManager = require("PlayerInfo.RoleManager")
    if WorldBossManager.getBossType() == "ActivityBoss" then
        return RoleManager:getPosterById(1)
    end
    if WorldBossManager.getBossType() == "player" then
       local roleId = WorldBossManager.WorldBossAttrInfo.roleItemId
       return RoleManager:getPosterById(roleId)
    end
    if WorldBossManager.getBossType() == "Monster" then
       local MonsterCfg = ConfigManager.getMonsterCfg()
       local roleId = MonsterCfg[WorldBossManager.WorldBossAttrInfo.monsterId]["spineId"]
       return RoleManager:getPosterById(1)
    end
end

function WorldBossManager.setBossState( openBoss )
    WorldBossManager.BossState = openBoss
end

function WorldBossManager.EnterPageByState()
	local state = WorldBossManager.BossState
    
    if state == 1 then
        
         if WorldBossManager.isBossDead == true then
            PageManager.changePage("WorldBossFinalpage");
         elseif WorldBossManager.isBossDead == false then   
            MessageBoxPage:Msg_Box_Lan("@WorldBossNotDie") 
         else
             MessageBoxPage:Msg_Box_Lan("@WorldBossFirstStar")
         end
    end
    if state == 2 then
         MessageBoxPage:Msg_Box_Lan("@WorldBoss30minBefore")
    end
    
    if state == 3 then
        print("WorldBossManager.selectBuff = ",WorldBossManager.selectBuff)
        if WorldBossManager.selectBuff ~= 0 then
            PageManager.changePage("WorldBossPage");
        else
            PageManager.changePage("GVEBuffSelectPage")
        end
    end
end
-- function WorldBossManager.ReceiveHPRebirthRet(msg)
--      --Ô¡»ðÖØÉúË¢ÐÂ×êÊ¯
--      if msg.type == 2 then
--           WorldBossManager.needRebirthCost = msg.needRebirthCost
--      end
-- end

function WorldBossManager.ReceiveHPBossHarmRank(msg, lastAttackTime)
     WorldBossManager.currBossHp = msg.currBossHp
     WorldBossManager.curRankList= msg.bossRankItem
     WorldBossManager.curAllianceRankList = msg.bossRankAllianceItem
     WorldBossManager.selfAttack = msg.selfHarm
     WorldBossManager.selfAttacksTimes = msg.selfAttacksTimes
     WorldBossManager.selfHarmRank = msg.selfHarmRank
     WorldBossManager.selfAllianceRank = msg.selfAllianceRank
     WorldBossManager.selfAllianceHarm = msg.selfAllianceHarm
    for i = 1, #msg.HPAllianceHarmInfo do
        if msg.HPAllianceHarmInfo[i].lastAttackTime > lastAttackTime then
            table.insert(WorldBossManager.AllianceHarm, msg.HPAllianceHarmInfo[i])
            WorldBossManager.AllianceHarmLen = #WorldBossManager.AllianceHarm
        end
    end
    table.sort(WorldBossManager.AllianceHarm , function ( left, right )
        return left.lastAttackTime < right.lastAttackTime
    end )

    table.sort(WorldBossManager.curRankList,function (bossRankItem1,bossRankItem2)
            if not bossRankItem1 then return true end
            if not bossRankItem2 then return false end
            return bossRankItem1.rankIndex  < bossRankItem2.rankIndex
    end )
    table.sort(WorldBossManager.curAllianceRankList,function (bossRankItem1,bossRankItem2)
            if not bossRankItem1 then return true end
            if not bossRankItem2 then return false end
            return bossRankItem1.rankIndex  < bossRankItem2.rankIndex
    end )
end

function WorldBossManager.ReceiveBossFailing(msg)
    if msg then
        WorldBossManager.currBossFailingAttrInfo = msg.attrInfo
        WorldBossManager.currBossFailingEndTime = msg.endTime / 1000
        WorldBossManager.worldBossFailingType = msg.worldBossFailingType
    else
        WorldBossManager.currBossFailingAttrInfo = nil
        WorldBossManager.currBossFailingEndTime = 0
        WorldBossManager.worldBossFailingType = nil
    end
end

function WorldBossManager.ReceiveHPRebirthRet( msg )
    WorldBossManager.rebirthLeftTime = msg.freeActionTime / 1000
    WorldBossManager.actionLeftTime = msg.goldActionTime / 1000
end

function WorldBossManager.ReceiveHPAttackPush(msg)
     WorldBossManager.currBossHp = msg.currBossHp
     WorldBossManager.fightInfo = msg.fightInfo
     WorldBossManager.selfAttack = msg.selfHarm
     WorldBossManager.selfAttacksTimes = msg.selfAttacksTimes
     WorldBossManager.WorldBossFightIsFailing = msg.isFailing
end

function WorldBossManager.ReceiveHPWorldBossBannerInfo(msg)
     WorldBossManager.autoJoinState = msg.autoJoinState
     WorldBossManager.StartTime = msg.startTime
     WorldBossManager.isBossDead = msg.lastBossDead
     WorldBossManager.BossState = msg.bossState
     if WorldBossManager.BossState == 2 then
        WorldBossManager.BossState = 1
     end
end

function WorldBossManager.ReceiveHPWorldBossInfo_InBanner(msg)
    WorldBossManager.BossState = msg.bossState
     if WorldBossManager.BossState == 2 then
        WorldBossManager.BossState = 1
     end    
    WorldBossManager.lastRankList = msg.lastBossInfo.bossRankItem
    WorldBossManager.lastAllianceRankList = msg.lastBossInfo.bossRankAllianceItem
    
    if msg.bossInfo.npcId ~= nil then
         if msg.bossInfo.npcId ~= 0 then 
         WorldBossManager.WorldBossAttrInfo.npcId = msg.bossInfo.npcId
         end
    end
    if msg.bossInfo.roleItemId ~= nil then
       if msg.bossInfo.roleItemId ~= 0 then 
       WorldBossManager.WorldBossAttrInfo.roleItemId = msg.bossInfo.roleItemId
       end
    end
    if msg.bossInfo.monsterId ~= nil then
        if msg.bossInfo.monsterId ~= 0 then
            WorldBossManager.WorldBossAttrInfo.monsterId = msg.bossInfo.monsterId
        end
    end
    if  msg:HasField("curBossBuffCfgId") then
        WorldBossManager.selectBuff = msg.curBossBuffCfgId
    end
end

function WorldBossManager.ReceiveHPWorldBossInfo(msg)
	WorldBossManager.BossState = msg.bossState
    if WorldBossManager.BossState == 2 then
        WorldBossManager.BossState = 1
    end
    WorldBossManager.lastRankList = msg.lastBossInfo.bossRankItem 
    WorldBossManager.lastAllianceRankList = msg.lastBossInfo.bossRankAllianceItem

    if msg.bossInfo.npcId ~= nil then
        if msg.bossInfo.npcId ~= 0 then 
            WorldBossManager.WorldBossAttrInfo.npcId = msg.bossInfo.npcId
            local cfg = ConfigManager:getNewMonsterCfg()
            WorldBossManager.WorldBossAttrInfo.name =  cfg[WorldBossManager.WorldBossAttrInfo.npcId].Name
            WorldBossManager.WorldBossAttrInfo.level  = cfg[WorldBossManager.WorldBossAttrInfo.npcId].Level
        end
    end
    if msg.bossInfo.roleItemId ~= nil then
        if msg.bossInfo.roleItemId ~= 0 then 
            WorldBossManager.WorldBossAttrInfo.roleItemId = msg.bossInfo.roleItemId
            WorldBossManager.WorldBossAttrInfo.name = common:getLanguageString("@DemonReform") .. msg.bossInfo.name
            WorldBossManager.WorldBossAttrInfo.level = msg.bossInfo.level
        end
    end

    if  msg:HasField("curBossBuffCfgId") then
        WorldBossManager.selectBuff = msg.curBossBuffCfgId
    end

    if msg:HasField("bossFailingInfo") then
        WorldBossManager.ReceiveBossFailing(msg.bossFailingInfo)
    else
        WorldBossManager.ReceiveBossFailing()
    end
    if msg:HasField("curRank") then
        WorldBossManager.curRank = msg.curRank
    else
        WorldBossManager.curRank = nil
    end
    if msg:HasField("curAllianceRank") then
        WorldBossManager.curAllianceRank = msg.curAllianceRank
    else
        WorldBossManager.curAllianceRank = nil
    end    
    if msg.bossInfo.monsterId ~= nil then
        if msg.bossInfo.monsterId ~= 0 then
            WorldBossManager.WorldBossAttrInfo.monsterId = msg.bossInfo.monsterId
            local MonsterCfg = ConfigManager.getMonsterCfg()
            WorldBossManager.WorldBossAttrInfo.name =common:getLanguageString("@DemonReform")..MonsterCfg[WorldBossManager.WorldBossAttrInfo.monsterId]["name"]
            WorldBossManager.WorldBossAttrInfo.level  = MonsterCfg[WorldBossManager.WorldBossAttrInfo.monsterId]["level"]

            if  GamePrecedure:getInstance():getI18nSrcPath() == "Spanish" then
                 WorldBossManager.WorldBossAttrInfo.name = MonsterCfg[WorldBossManager.WorldBossAttrInfo.monsterId]["name"]..common:getLanguageString("@DemonReform")
            end
        end
    end
    WorldBossManager.WorldBossAttrInfo.currBossHp = msg.bossInfo.hp
    WorldBossManager.WorldBossAttrInfo.maxHp = msg.bossInfo.maxHp

    WorldBossManager.leftTime = msg.leftTime / 1000
    WorldBossManager.needRebirthCost = msg.needRebirthCost
    WorldBossManager.rebirthLeftTime = msg.rebirthLeftTime / 1000
    WorldBossManager.actionLeftTime = msg.actionLeftTime / 1000
    WorldBossManager.autoJoinState = msg.autoJoinState
    WorldBossManager.curRankList = msg.curRankItemInfo.bossRankItem
    WorldBossManager.curAllianceRankList = msg.curRankItemInfo.bossRankAllianceItem
    WorldBossManager.currBossHp = msg.curRankItemInfo.currBossHp
    WorldBossManager.selfAttack = msg.curRankItemInfo.selfHarm
    WorldBossManager.selfAttacksTimes = msg.curRankItemInfo.selfAttacksTimes
    WorldBossManager.challengTime = msg.challengTime

    WorldBossManager.lastKingInfo = nil

    for i,v in ipairs(WorldBossManager.lastRankList) do
        if v.type == 2 then
            WorldBossManager.lastKingInfo = v
            table.remove(WorldBossManager.lastRankList, i)
            break;
        end
    end

    if WorldBossManager.currBossHp <= 0 then
       WorldBossManager.isBossDead = true
    end

    table.sort(WorldBossManager.lastRankList,function (bossRankItem1,bossRankItem2)
        if not bossRankItem1 then return true end
	    if not bossRankItem2 then return false end
        return bossRankItem1.rankIndex  < bossRankItem2.rankIndex
    end )
    table.sort(WorldBossManager.lastAllianceRankList,function (bossRankItem1,bossRankItem2)
        if not bossRankItem1 then return true end
        if not bossRankItem2 then return false end
        return bossRankItem1.rankIndex  < bossRankItem2.rankIndex
    end )    
end

return WorldBossManager