local CONST = require("Battle.NewBattleConst")

NgBattleDataManager = NgBattleDataManager or { }

NgBattleDataManager.battleMineCharacter = { }
NgBattleDataManager.battleMineSprite = { }
NgBattleDataManager.battleEnemyCharacter = { }
NgBattleDataManager.battleEnemySprite = { }
-------------------------------------------------
-- ���Үɤ��M�������
NgBattleDataManager.battlePageContainer = nil   -- �԰��e��container
NgBattleDataManager.battleSpeed = 1.5           -- �԰������t��
NgBattleDataManager.battleIsAuto = true         -- �O�_auto
NgBattleDataManager.battleState = 0             -- �԰����A(��l��, �i����, �԰���...)
NgBattleDataManager.battleType = 0              -- �԰�����(����, �D��BOSS, PVP, �@��BOSS...)
NgBattleDataManager.battleMapId = 0             -- �a��ID
NgBattleDataManager.defenderRank = 0            -- PVP�D��rank
-------------------------------------------------
NgBattleDataManager.battleIsPause = false       -- �O�_�Ȱ�
NgBattleDataManager.battleId = 0                -- �԰�ID
NgBattleDataManager.battleTime = 0              -- �԰��ɶ�
NgBattleDataManager.battleResult = 0            -- �԰����G(0:�ӧQ 1:����)
NgBattleDataManager.battleLog = { }             -- �԰�log
NgBattleDataManager.battleTestLog = { }         -- �԰�����log
NgBattleDataManager.battleDetailData = { }      -- �԰��ԲӸ��
NgBattleDataManager.battleDetailDataTest = { }  -- �԰��ԲӸ��(���ե�)
NgBattleDataManager.isSkipInitChar = false      -- �O�_���L��l�ƨ���
NgBattleDataManager.isInitCharEnd = false       -- �O�_��l�ƨ��⵲��
NgBattleDataManager.nowInitCharPos = 1          -- ��e��l�ƨ����m

NgBattleDataManager.castSkillNode = nil         -- �I��j�ۤ�������

NgBattleDataManager.serverPlayerInfo = nil      -- server�^�Ǫ��a���
NgBattleDataManager.serverEnemyInfo = nil       -- server�^�ǼĤ���

NgBattleDataManager.isSendResault = false       -- �O�_���b�ǰe�԰����Glog
NgBattleDataManager.serverLogId = 1             -- �ݭn�ǰe��server��logId
NgBattleDataManager.sendingLogId = 0            -- ���b�ǰe����logId

NgBattleDataManager.playerMvpIndex = 1          -- ���aMVP Index
NgBattleDataManager.enemyMvpIndex = 1           -- �Ĥ�MVP Index

NgBattleDataManager.groupInfo = nil             -- ���a�s�����

NgBattleDataManager.arenaName = ""              -- �v�޳��ĤH�W��
NgBattleDataManager.arenaIcon = ""              -- �v�޳��ĤH�Y��

NgBattleDataManager.SingleBossScore = 0         -- ��H�j�Ĥ���
NgBattleDataManager.SingleBossBarPos = 0        -- ��H�j�Ķi�ױ���m
NgBattleDataManager.SingleBossBarIdx = 0        -- ��H�j�Ħ����ܩǪ�idx

NgBattleDataManager.dungeonId = 1               -- �a�U���a��id
NgBattleDataManager.PlayerLevel = 1             -- �ԫe����
NgBattleDataManager.TowerId = 1                 -- Act191 id
NgBattleDataManager.SingleBossId = 1            -- ��H�j��id
NgBattleDataManager.asyncLoadTasks = { }        -- �D�P�BŪ������

NgBattleDataManager.audioData = { }             -- �����ɮ׬���
NgBattleDataManager.audioIds = { }              -- �����ɮ�Id
-- ���եγ]�w
NgBattleDataManager.testFriendUpdate = true     -- ���վ԰��ڤ�O�_���
NgBattleDataManager.testEnemyUpdate = true      -- ���վ԰��Ĥ�O�_���
NgBattleDataManager.testFriendAttackRatio = 1   -- ���վ԰��ڤ�������v
NgBattleDataManager.testEnemyAttackRatio = 1    -- ���վ԰��Ĥ�������v
NgBattleDataManager.testFriendDefenseRatio = 1  -- ���վ԰��ڤ訾�m���v
NgBattleDataManager.testEnemyDefenseRatio = 1   -- ���վ԰��Ĥ訾�m���v
NgBattleDataManager.testFriendHpRatio = 1       -- ���վ԰��ڤ��q���v
NgBattleDataManager.testEnemyHpRatio = 1        -- ���վ԰��Ĥ��q���v
NgBattleDataManager.testBatteTime = 90000       -- ���վ԰��԰��ɶ�   
NgBattleDataManager.testCloseFx = false         -- ���վ԰������S��  
NgBattleDataManager.testCloseBuff = false       -- ���վ԰�����Buff 
NgBattleDataManager.testCloseHit = false        -- ���վ԰����������S�� 
NgBattleDataManager.testCloseSound = false      -- ���վ԰������������� 
NgBattleDataManager.testCloseNum = false        -- ���վ԰������Ʀr 
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

-- ���o�ͤ訤��}�C
function NgBattleDataManager_getFriendList(chaNode)
    return chaNode.idx < CONST.ENEMY_BASE_IDX and NgBattleDataManager.battleMineCharacter or NgBattleDataManager.battleEnemyCharacter
end

-- ���o�Ĥ訤��}�C
function NgBattleDataManager_getEnemyList(chaNode)
    return chaNode.idx < CONST.ENEMY_BASE_IDX and NgBattleDataManager.battleEnemyCharacter or NgBattleDataManager.battleMineCharacter
end

-- �԰�����container
function NgBattleDataManager_setBattlePageContainer(container)
    NgBattleDataManager.battlePageContainer = container
end
-- �ڤ�԰�������
function NgBattleDataManager_setBattleMineCharacter(characterList)
    NgBattleDataManager.battleMineCharacter = characterList
end
-- �ڤ�԰����F���
function NgBattleDataManager_setBattleMineSprite(spriteList)
    NgBattleDataManager.battleMineSprite = spriteList
end
-- �Ĥ�԰�������
function NgBattleDataManager_setBattleEnemyCharacter(characterList)
    NgBattleDataManager.battleEnemyCharacter = characterList
end
-- �Ĥ�԰����F���
function NgBattleDataManager_setBattleEnemySprite(spriteList)
    NgBattleDataManager.battleEnemySprite = spriteList
end
-- �԰�ID
function NgBattleDataManager_setBattleId(id)
    NgBattleDataManager.battleId = id
end
-- �԰��t��
function NgBattleDataManager_setBattleSpeed(speed)
    NgBattleDataManager.battleSpeed = speed
end
-- �O�_�۰ʾ԰�
function NgBattleDataManager_setBattleIsAuto(isAuto)
    NgBattleDataManager.battleIsAuto = isAuto
end
-- �O�_�Ȱ��԰�
function NgBattleDataManager_setBattleIsPause(isPause)
    NgBattleDataManager.battleIsPause = isPause
end
-- �԰��ɶ�
function NgBattleDataManager_setBattleTime(time)
    NgBattleDataManager.battleTime = time
end
-- �԰����A(�s����, ��l��, �԰���...)
function NgBattleDataManager_setBattleState(state)
    NgBattleDataManager.battleState = state
end
-- �԰�����(����, boss, �v�޳�...)
function NgBattleDataManager_setBattleType(_type)
    NgBattleDataManager.battleType = _type
end
-- �԰����G(�ӧQ, ����)
function NgBattleDataManager_setBattleResult(result)
    NgBattleDataManager.battleResult = result
end
-- �a��ID
function NgBattleDataManager_setBattleMapId(mapId)
    NgBattleDataManager.battleMapId = mapId
end
-- PVP�D��rank
function NgBattleDataManager_setDefenderRank(rank)
    NgBattleDataManager.defenderRank = rank
end
-- �O�_�ݭn��l�ƨ���
function NgBattleDataManager_setIsSkipInitChar(isSkip)
    NgBattleDataManager.isSkipInitChar = isSkip
end
-- �O�_��l�ƨ��⵲��
function NgBattleDataManager_setIsInitCharEnd(isEnd)
    NgBattleDataManager.isInitCharEnd = isEnd
end
-- ��e��l�ƨ����m
function NgBattleDataManager_setNowInitCharPos(pos)
    NgBattleDataManager.nowInitCharPos = pos
end
-- �I��j�ۤ�������
function NgBattleDataManager_setCastSkillNode(chaNode)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        NgBattleDataManager.castSkillNode = nil
        return
    end
    NgBattleDataManager.castSkillNode = chaNode
end
-- �԰�����
function NgBattleDataManager_setBattleLog(log)
    NgBattleDataManager.battleLog = log
end
-- �԰����լ���
function NgBattleDataManager_setBattleTestLog(log)
    NgBattleDataManager.battleTestLog = log
end

-- Server�ڤ���
function NgBattleDataManager_setServerPlayerInfo(info)
    -- ���s��z���
    local newData = { }
    for i = 1, #info do
        newData[info[i].posId] = info[i]
    end
    NgBattleDataManager.serverPlayerInfo = newData
end
-- Server�ĤH���
function NgBattleDataManager_setServerEnemyInfo(info)
    -- ���s��z���
    local newData = { }
    for i = 1, #info do
        newData[info[i].posId - CONST.ENEMY_BASE_IDX] = info[i]
    end
    NgBattleDataManager.serverEnemyInfo = newData
end

-- �s�����
function NgBattleDataManager_setServerGroupInfo(groupInfo)
    NgBattleDataManager.groupInfo = groupInfo
end

-- �v�޳��ĤH�W��
function NgBattleDataManager_setArenaName(name)
    NgBattleDataManager.arenaName = name
end
-- �v�޳��ĤH�Y��
function NgBattleDataManager_setArenaIcon(icon)
    NgBattleDataManager.arenaIcon = icon
end

-- �a�U���a��id
function NgBattleDataManager_setDungeonId(id)
    NgBattleDataManager.dungeonId = id
end
-- �a�U���a��id
function NgBattleDataManager_setSingleBossId(id)
    NgBattleDataManager.SingleBossId = id
end

-- �ԫe����
function NgBattleDataManager_setPlayerLevel(level)
    NgBattleDataManager.PlayerLevel = level
end
-- Debug�\��
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