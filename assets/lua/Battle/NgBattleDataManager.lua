local CONST = require("Battle.NewBattleConst")

NgBattleDataManager = NgBattleDataManager or { }

NgBattleDataManager.battleMineCharacter = { }
NgBattleDataManager.battleMineSprite = { }
NgBattleDataManager.battleEnemyCharacter = { }
NgBattleDataManager.battleEnemySprite = { }
-------------------------------------------------
-- 重啟時不清除的資料
NgBattleDataManager.battlePageContainer = nil   -- 戰鬥畫面container
NgBattleDataManager.battleSpeed = 1.5           -- 戰鬥場景速度
NgBattleDataManager.battleIsAuto = true         -- 是否auto
NgBattleDataManager.battleState = 0             -- 戰鬥狀態(初始化, 進場中, 戰鬥中...)
NgBattleDataManager.battleType = 0              -- 戰鬥類型(掛機, 挑戰BOSS, PVP, 世界BOSS...)
NgBattleDataManager.battleMapId = 0             -- 地圖ID
NgBattleDataManager.defenderRank = 0            -- PVP挑戰rank
-------------------------------------------------
NgBattleDataManager.battleIsPause = false       -- 是否暫停
NgBattleDataManager.battleId = 0                -- 戰鬥ID
NgBattleDataManager.battleTime = 0              -- 戰鬥時間
NgBattleDataManager.battleResult = 0            -- 戰鬥結果(0:勝利 1:失敗)
NgBattleDataManager.battleLog = { }             -- 戰鬥log
NgBattleDataManager.battleTestLog = { }         -- 戰鬥測試log
NgBattleDataManager.battleDetailData = { }      -- 戰鬥詳細資料
NgBattleDataManager.battleDetailDataTest = { }  -- 戰鬥詳細資料(測試用)
NgBattleDataManager.isSkipInitChar = false      -- 是否跳過初始化角色
NgBattleDataManager.isInitCharEnd = false       -- 是否初始化角色結束
NgBattleDataManager.nowInitCharPos = 1          -- 當前初始化角色位置

NgBattleDataManager.castSkillNode = nil         -- 施放大招中的角色

NgBattleDataManager.serverPlayerInfo = nil      -- server回傳玩家資料
NgBattleDataManager.serverEnemyInfo = nil       -- server回傳敵方資料

NgBattleDataManager.isSendResault = false       -- 是否正在傳送戰鬥結果log
NgBattleDataManager.serverLogId = 1             -- 需要傳送給server的logId
NgBattleDataManager.sendingLogId = 0            -- 正在傳送中的logId

NgBattleDataManager.playerMvpIndex = 1          -- 玩家MVP Index
NgBattleDataManager.enemyMvpIndex = 1           -- 敵方MVP Index

NgBattleDataManager.groupInfo = nil             -- 玩家編隊資料

NgBattleDataManager.arenaName = ""              -- 競技場敵人名稱
NgBattleDataManager.arenaIcon = ""              -- 競技場敵人頭像

NgBattleDataManager.SingleBossScore = 0         -- 單人強敵分數
NgBattleDataManager.SingleBossBarPos = 0        -- 單人強敵進度條位置
NgBattleDataManager.SingleBossBarIdx = 0        -- 單人強敵血條顯示怪物idx

NgBattleDataManager.dungeonId = 1               -- 地下城地圖id
NgBattleDataManager.PlayerLevel = 1             -- 戰前等級
NgBattleDataManager.TowerId = 1                 -- Act191 id
NgBattleDataManager.SingleBossId = 1            -- 單人強敵id
NgBattleDataManager.asyncLoadTasks = { }        -- 非同步讀取任務

NgBattleDataManager.audioData = { }             -- 音效檔案紀錄
NgBattleDataManager.audioIds = { }              -- 音效檔案Id
-- 測試用設定
NgBattleDataManager.testFriendUpdate = true     -- 測試戰鬥我方是否行動
NgBattleDataManager.testEnemyUpdate = true      -- 測試戰鬥敵方是否行動
NgBattleDataManager.testFriendAttackRatio = 1   -- 測試戰鬥我方攻擊倍率
NgBattleDataManager.testEnemyAttackRatio = 1    -- 測試戰鬥敵方攻擊倍率
NgBattleDataManager.testFriendDefenseRatio = 1  -- 測試戰鬥我方防禦倍率
NgBattleDataManager.testEnemyDefenseRatio = 1   -- 測試戰鬥敵方防禦倍率
NgBattleDataManager.testFriendHpRatio = 1       -- 測試戰鬥我方血量倍率
NgBattleDataManager.testEnemyHpRatio = 1        -- 測試戰鬥敵方血量倍率
NgBattleDataManager.testBatteTime = 90000       -- 測試戰鬥戰鬥時間   
NgBattleDataManager.testCloseFx = false         -- 測試戰鬥關閉特效  
NgBattleDataManager.testCloseBuff = false       -- 測試戰鬥關閉Buff 
NgBattleDataManager.testCloseHit = false        -- 測試戰鬥關閉受擊特效 
NgBattleDataManager.testCloseSound = false      -- 測試戰鬥關閉受擊音效 
NgBattleDataManager.testCloseNum = false        -- 測試戰鬥關閉數字 
function NgBattleDataManager_clearBattleData()
    NgBattleDataManager.battleMineCharacter = { }
    NgBattleDataManager.battleMineSprite = { }
    NgBattleDataManager.battleEnemyCharacter = { }
    NgBattleDataManager.battleEnemySprite = { }

    NgBattleDataManager.battleIsPause = false
    NgBattleDataManager.battleTime = 0
    NgBattleDataManager.battleResult = 0
    NgBattleDataManager.battleLog = { }
    NgBattleDataManager.battleTestLog = { }
    NgBattleDataManager.battleDetailData = { }
    NgBattleDataManager.serverPlayerInfo = nil
    NgBattleDataManager.serverEnemyInfo = nil
    NgBattleDataManager.castSkillNode = nil

    NgBattleDataManager.isSendResault = false
    NgBattleDataManager.serverLogId = 1
    NgBattleDataManager.sendingLogId = 0

    NgBattleDataManager.isSkipInitChar = false
    NgBattleDataManager.isInitCharEnd = false
    NgBattleDataManager.nowInitCharPos = 1

    NgBattleDataManager.battleDetailDataTest = { } 

    NgBattleDataManager.audioIds = { } 

    NgBattleDataManager.SingleBossScore = 0
    NgBattleDataManager.SingleBossBarPos = 0
end

-- 取得友方角色陣列
function NgBattleDataManager_getFriendList(chaNode)
    return chaNode.idx < CONST.ENEMY_BASE_IDX and NgBattleDataManager.battleMineCharacter or NgBattleDataManager.battleEnemyCharacter
end

-- 取得敵方角色陣列
function NgBattleDataManager_getEnemyList(chaNode)
    return chaNode.idx < CONST.ENEMY_BASE_IDX and NgBattleDataManager.battleEnemyCharacter or NgBattleDataManager.battleMineCharacter
end

-- 戰鬥場景container
function NgBattleDataManager_setBattlePageContainer(container)
    NgBattleDataManager.battlePageContainer = container
end
-- 我方戰鬥角色資料
function NgBattleDataManager_setBattleMineCharacter(characterList)
    NgBattleDataManager.battleMineCharacter = characterList
end
-- 我方戰鬥精靈資料
function NgBattleDataManager_setBattleMineSprite(spriteList)
    NgBattleDataManager.battleMineSprite = spriteList
end
-- 敵方戰鬥角色資料
function NgBattleDataManager_setBattleEnemyCharacter(characterList)
    NgBattleDataManager.battleEnemyCharacter = characterList
end
-- 敵方戰鬥精靈資料
function NgBattleDataManager_setBattleEnemySprite(spriteList)
    NgBattleDataManager.battleEnemySprite = spriteList
end
-- 戰鬥ID
function NgBattleDataManager_setBattleId(id)
    NgBattleDataManager.battleId = id
end
-- 戰鬥速度
function NgBattleDataManager_setBattleSpeed(speed)
    NgBattleDataManager.battleSpeed = speed
end
-- 是否自動戰鬥
function NgBattleDataManager_setBattleIsAuto(isAuto)
    NgBattleDataManager.battleIsAuto = isAuto
end
-- 是否暫停戰鬥
function NgBattleDataManager_setBattleIsPause(isPause)
    NgBattleDataManager.battleIsPause = isPause
end
-- 戰鬥時間
function NgBattleDataManager_setBattleTime(time)
    NgBattleDataManager.battleTime = time
end
-- 戰鬥狀態(編隊中, 初始化, 戰鬥中...)
function NgBattleDataManager_setBattleState(state)
    NgBattleDataManager.battleState = state
end
-- 戰鬥類型(掛機, boss, 競技場...)
function NgBattleDataManager_setBattleType(_type)
    NgBattleDataManager.battleType = _type
end
-- 戰鬥結果(勝利, 失敗)
function NgBattleDataManager_setBattleResult(result)
    NgBattleDataManager.battleResult = result
end
-- 地圖ID
function NgBattleDataManager_setBattleMapId(mapId)
    NgBattleDataManager.battleMapId = mapId
end
-- PVP挑戰rank
function NgBattleDataManager_setDefenderRank(rank)
    NgBattleDataManager.defenderRank = rank
end
-- 是否需要初始化角色
function NgBattleDataManager_setIsSkipInitChar(isSkip)
    NgBattleDataManager.isSkipInitChar = isSkip
end
-- 是否初始化角色結束
function NgBattleDataManager_setIsInitCharEnd(isEnd)
    NgBattleDataManager.isInitCharEnd = isEnd
end
-- 當前初始化角色位置
function NgBattleDataManager_setNowInitCharPos(pos)
    NgBattleDataManager.nowInitCharPos = pos
end
-- 施放大招中的角色
function NgBattleDataManager_setCastSkillNode(chaNode)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        NgBattleDataManager.castSkillNode = nil
        return
    end
    NgBattleDataManager.castSkillNode = chaNode
end
-- 戰鬥紀錄
function NgBattleDataManager_setBattleLog(log)
    NgBattleDataManager.battleLog = log
end
-- 戰鬥測試紀錄
function NgBattleDataManager_setBattleTestLog(log)
    NgBattleDataManager.battleTestLog = log
end

-- Server我方資料
function NgBattleDataManager_setServerPlayerInfo(info)
    -- 重新整理資料
    local newData = { }
    for i = 1, #info do
        newData[info[i].posId] = info[i]
    end
    NgBattleDataManager.serverPlayerInfo = newData
end
-- Server敵人資料
function NgBattleDataManager_setServerEnemyInfo(info)
    -- 重新整理資料
    local newData = { }
    for i = 1, #info do
        newData[info[i].posId - CONST.ENEMY_BASE_IDX] = info[i]
    end
    NgBattleDataManager.serverEnemyInfo = newData
end

-- 編隊資料
function NgBattleDataManager_setServerGroupInfo(groupInfo)
    NgBattleDataManager.groupInfo = groupInfo
end

-- 競技場敵人名稱
function NgBattleDataManager_setArenaName(name)
    NgBattleDataManager.arenaName = name
end
-- 競技場敵人頭像
function NgBattleDataManager_setArenaIcon(icon)
    NgBattleDataManager.arenaIcon = icon
end

-- 地下城地圖id
function NgBattleDataManager_setDungeonId(id)
    NgBattleDataManager.dungeonId = id
end
-- 地下城地圖id
function NgBattleDataManager_setSingleBossId(id)
    NgBattleDataManager.SingleBossId = id
end

-- 戰前等級
function NgBattleDataManager_setPlayerLevel(level)
    NgBattleDataManager.PlayerLevel = level
end
-- Debug功能
function NgBattleDataManager_getTestOpenFx()
    return (not libOS:getInstance():getIsDebug() or not NgBattleDataManager.testCloseFx)
end
function NgBattleDataManager_getTestOpenBuff()
    return (not libOS:getInstance():getIsDebug() or not NgBattleDataManager.testCloseBuff)
end
function NgBattleDataManager_getTestOpenHit()
    return (not libOS:getInstance():getIsDebug() or not NgBattleDataManager.testCloseHit)
end
function NgBattleDataManager_getTestOpenSound()
    --return (not libOS:getInstance():getIsDebug() or not NgBattleDataManager.testCloseSound)
    return false
end
function NgBattleDataManager_getTestOpenNum()
    return (not libOS:getInstance():getIsDebug() or not NgBattleDataManager.testCloseNum)
end