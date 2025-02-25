NgBattleCharacterUtil = NgBattleCharacterUtil or {}

local CONST = require("Battle.NewBattleConst")
local LOG_UTIL = require("Battle.NgBattleLogUtil")
local BuffManager = require("Battle.NewBuff.BuffManager")
local SkillManager = require("Battle.NewSkill.SkillManager")
require("Battle.NewBattleUtil")
local ALFManager = require("Util.AsyncLoadFileManager")

-------------------------------------------------------
local ccbiFile = { "BattleLead.ccbi", "BattleBossEnemy.ccbi" }
local mainNode = {
    personHitOrBufCCB = { ccbi = "BattleHitOrBuff.ccbi", parentNode = "mPersonHitOrBufNode", tag = 1001, scaleX = true },
    normalNumCCB = { ccbi = "BattleNormalNum.ccbi", parentNode = "mPersonHitNumberNode", tag = 1002 },
    critsNumCCB = { ccbi = "BattleCritsNum.ccbi", parentNode = "mPersonHitNumberNode", tag = 1003 },
    dodgeNumCCB = { ccbi = "BattleDodgeNum.ccbi", parentNode = "mPersonHitNumberNode", tag = 1004 },
    healNumCCB = { ccbi = "BattleHealNum.ccbi", parentNode = "mPersonHitNumberNode", tag = 1005 },
    gainMPNumCCB = { ccbi = "BattleGainMPNum.ccbi", parentNode = "mPersonHitNumberNode", tag = 1006 },
    skillNameCCB = { ccbi = "BattleSkillNameAni.ccbi", parentNode = "mSkillAniNode", tag = 1007 },
}
local indexTab = {
    __index = function(t, k)
        if mainNode[k] then
            if rawget(t, k) ~= nil then
                return rawget(t, k)
            else
                local parentNode = t.chaCCB:getVarNode(mainNode[k].parentNode)
                local ccbfile = CCBManager:getInstance():createAndLoad2(mainNode[k].ccbi);
                if mainNode[k].scaleX then
                    if t.id % 2 == 1 then
                        ccbfile:setScaleX(-1);
                    else
                        ccbfile:setScaleX(1);
                    end
                end
                parentNode:addChild(ccbfile)
                t[k] = ccbfile
                return ccbfile
            end
        else
            return rawget(t, k)
        end
    end
}
-------------------------------------------------------
-- �إߨ���
function NgBattleCharacterUtil:new(o)
    o = o or { }
    o.allSpineTable = {}
    o.attackLogData = {}
    o.tarArray = {}
    -- �S��/�Ʀr��l��
    o.hurtEffect = {}
    o.hurtNum = nil
    o.hurtCriNum = nil
    o.missNum = nil
    o.healNum = nil
    -- �԰���ƪ�l��
    for i = 1, #CONST.DEFAULT_BATTLE_DATA do
        o.battleData[i] = o.battleData[i] or CONST.DEFAULT_BATTLE_DATA[i]
    end
    -- ��L��ƪ�l��
    for i = 1, #CONST.DEFAULT_OTHER_DATA do
        o.otherData[i] = o.otherData[i] or CONST.DEFAULT_OTHER_DATA[i]
    end
    -- ��q��l��
    --o.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] = NewBattleUtil:calMaxHp(self, nil)
    o.battleData[NewBattleConst.BATTLE_DATA.PRE_HP] = o.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    --o.battleData[NewBattleConst.BATTLE_DATA.HP] = o.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]

    self:createCcbiNode(o)
    self:createFloorFxNode(o)
    self:createSpineNode(o)
    self:preloadBattleNums(o)

    o.nowState = CONST.CHARACTER_STATE.INIT
    o.target = nil
    o.buffData = {}
    o.atkCD = 9999
    o.rebirthTimer = 0

    return o
end
-- ��l��UI�ɮ�
function NgBattleCharacterUtil:createCcbiNode(chaNode)
    local isMine = self:isMineCharacter(chaNode)
    chaNode.heroNode = setmetatable( { id = chaNode.idx }, indexTab)
    chaNode.heroNode.chaCCB = ScriptContentBase:create(isMine and ccbiFile[1] or ccbiFile[2], chaNode.idx)
    -- �����԰��ٲ��e���~�i�����q(��l��m�����q����)
    local posxOffset = NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK and 10 or CONST.BATTLE_INIT_DIS
    if chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.SPRITE then  -- ���F�_�l�Z���]�w
        posxOffset = CONST.BATTLE_ENEMY_INIT_DIS
    end
    if isMine then
        posxOffset = posxOffset * -1
    end
    -- �]�w��l�y��, �h��
    chaNode.heroNode.chaCCB:setPosition(ccp(chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X] + posxOffset, chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y]))
    chaNode.otherData[CONST.OTHER_DATA.Z_ORDER] = math.ceil(CONST.Z_ORDER_MASK - chaNode.heroNode.chaCCB:getPositionY())
    chaNode.heroNode.chaCCB:setZOrder(chaNode.otherData[CONST.OTHER_DATA.Z_ORDER])

    NodeHelper:setNodeVisible(chaNode.heroNode.chaCCB:getVarNode("mHeadcircle"), false) -- close test png 
    -- ��������ܦ��/���F����ܦ��
    local showBar = (NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK and chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] ~= CONST.CHARACTER_TYPE.SPRITE)
    NodeHelper:setNodeVisible(chaNode.heroNode.chaCCB:getVarNode("mHpmpbar"), showBar)
    -- hp, mp, shield�ݩ�icon�]�w
    self:setHp(chaNode, chaNode.battleData[NewBattleConst.BATTLE_DATA.HP], true)
    self:setMp(chaNode, chaNode.battleData[NewBattleConst.BATTLE_DATA.MP])
    self:setShield(chaNode, chaNode.battleData[NewBattleConst.BATTLE_DATA.SHIELD])
    NodeHelper:setSpriteImage(chaNode.heroNode.chaCCB, { mStatus = string.format("Attributes_Battle_%02d.png", chaNode.battleData[CONST.BATTLE_DATA.ELEMENT] + (isMine and 0 or 6)) })
    --for i = 1, 6 do
    --    NodeHelper:setNodeVisible(chaNode.heroNode.chaCCB:getVarNode("mStatus" .. i), i == chaNode.battleData[CONST.BATTLE_DATA.ELEMENT])
    --end

    chaNode.heroNode.allSpineNode = chaNode.heroNode.chaCCB:getVarNode("mAllSpine")
    chaNode.heroNode.buffNode = CCNode:create()
    chaNode.heroNode.chaCCB:getVarNode("mBuffNode"):addChild(chaNode.heroNode.buffNode)
    chaNode.heroNode.debuffNode = CCNode:create()
    chaNode.heroNode.chaCCB:getVarNode("mDebuffNode"):addChild(chaNode.heroNode.debuffNode)

    chaNode.parent:addChild(chaNode.heroNode.chaCCB)
    chaNode.heroNode.chaCCB:release()
end
-- ��l�Ʀa�O�S���I��
function NgBattleCharacterUtil:createFloorFxNode(chaNode)
    chaNode.floorNode = CCNode:create()
    chaNode.floorNode:setPosition(chaNode.heroNode.chaCCB:getPosition())
    chaNode.otherData[CONST.OTHER_DATA.Z_ORDER] = math.ceil(CONST.Z_ORDER_MASK - chaNode.heroNode.chaCCB:getPositionY())
    chaNode.floorNode:setZOrder(chaNode.otherData[CONST.OTHER_DATA.Z_ORDER] - CONST.FLOOR_Z_ORDER_MASK)

    chaNode.parent:addChild(chaNode.floorNode)
end
-- ��l��SPINE�ɮ�
function NgBattleCharacterUtil:createSpineNode(chaNode)
    local scaleXFn = function()
        -- ��l����
        local isMine = self:isMineCharacter(chaNode)
        if isMine then
            if chaNode.otherData[CONST.OTHER_DATA.IS_FLIP] == 1 then
                local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
                self:setSpineScaleX(chaNode, math.abs(sToNode:getScaleX()) * -1)
            end
        else
            if chaNode.otherData[CONST.OTHER_DATA.IS_FLIP] == 0 then
                local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
                self:setSpineScaleX(chaNode, math.abs(sToNode:getScaleX()) * -1)
            end
        end
    end
    -- ���⥻��spine
    chaNode.heroNode.heroSpine = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH], chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME])
    table.insert(chaNode.allSpineTable, 1001, chaNode.heroNode.heroSpine)
    -- ����skin(�Ǫ���)
    if chaNode.otherData[CONST.OTHER_DATA.SPINE_SKIN] and chaNode.otherData[CONST.OTHER_DATA.IS_ENEMY] then
        chaNode.heroNode.heroSpine:setSkin("skin" .. string.format("%02d", chaNode.otherData[CONST.OTHER_DATA.SPINE_SKIN]))
    end
    if (NgBattleDataManager_getTestOpenFx()) then
        -- ������S��(FX2)
        if NodeHelper:isFileExist(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_BACK_FX] .. "/" .. chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_BACK_FX] .. ".skel") then
            local fn = function()
                chaNode.heroNode.heroBackFx = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_BACK_FX], chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_BACK_FX])
                table.insert(chaNode.allSpineTable, 1002, chaNode.heroNode.heroBackFx)
                local sToNodeBack = tolua.cast(chaNode.heroNode.heroBackFx, "CCNode")
                local spineNodeBack = chaNode.heroNode.chaCCB:getVarNode("mBackFX")
                spineNodeBack:addChild(sToNodeBack)
                self:setSpineFxVisible(chaNode, CONST.ANI_ACT.WAIT)
                scaleXFn()
                if BuffManager:isInCrowdControl(chaNode.buffData) then   -- �Q������
                    self:setTimeScale(chaNode, 0)
                else
                    self:resetTimeScale(chaNode)
                end
            end
            if chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.SPRITE then
                fn()
            else
                local task = ALFManager:loadSpineTask(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_BACK_FX] .. "/", chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_BACK_FX], 30, fn)
                NgBattleDataManager.asyncLoadTasks[chaNode.idx] = NgBattleDataManager.asyncLoadTasks[chaNode.idx] or { }
                table.insert(NgBattleDataManager.asyncLoadTasks[chaNode.idx], task)
            end
        end
        -- ����e��S��(FX1)
        if NodeHelper:isFileExist(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FRONT_FX] .. "/" .. chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FRONT_FX] .. ".skel") then
            local fn = function()
                chaNode.heroNode.heroFrontFx = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FRONT_FX], chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FRONT_FX])
                table.insert(chaNode.allSpineTable, 1003, chaNode.heroNode.heroFrontFx)
                local sToNodeFront = tolua.cast(chaNode.heroNode.heroFrontFx, "CCNode")
                local spineNodeFront = chaNode.heroNode.chaCCB:getVarNode("mFrontFX")
                spineNodeFront:addChild(sToNodeFront)
                self:setSpineFxVisible(chaNode, CONST.ANI_ACT.WAIT)
                scaleXFn()
                if BuffManager:isInCrowdControl(chaNode.buffData) then   -- �Q������
                    self:setTimeScale(chaNode, 0)
                else
                    self:resetTimeScale(chaNode)
                end
            end
            if chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.SPRITE then
                fn()
            else
                local task = ALFManager:loadSpineTask(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FRONT_FX] .. "/", chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FRONT_FX], 30, fn)
                NgBattleDataManager.asyncLoadTasks[chaNode.idx] = NgBattleDataManager.asyncLoadTasks[chaNode.idx] or { }
                table.insert(NgBattleDataManager.asyncLoadTasks[chaNode.idx], task)
            end
        end
        -- ����a�O�S��(FX3)
        if NodeHelper:isFileExist(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FLOOR_FX] .. "/" .. chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FLOOR_FX] .. ".skel") then
            local fn = function()
                chaNode.heroNode.heroFloorFx = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FLOOR_FX], chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FLOOR_FX])
                table.insert(chaNode.allSpineTable, 1004, chaNode.heroNode.heroFloorFx)
                local sToNodeFloor = tolua.cast(chaNode.heroNode.heroFloorFx, "CCNode")
                chaNode.floorNode:addChild(sToNodeFloor)
                self:setSpineFxVisible(chaNode, CONST.ANI_ACT.WAIT)
                scaleXFn()
                if BuffManager:isInCrowdControl(chaNode.buffData) then   -- �Q������
                    self:setTimeScale(chaNode, 0)
                else
                    self:resetTimeScale(chaNode)
                end
            end
            if chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.SPRITE then
                fn()
            else
                local task = ALFManager:loadSpineTask(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FLOOR_FX] .. "/", chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FLOOR_FX], 30, fn)
                NgBattleDataManager.asyncLoadTasks[chaNode.idx] = NgBattleDataManager.asyncLoadTasks[chaNode.idx] or { }
                table.insert(NgBattleDataManager.asyncLoadTasks[chaNode.idx], task)
            end
        end
    end
    self:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
    local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
    local spineNode = chaNode.heroNode.chaCCB:getVarNode("mMainSpine")
    spineNode:addChild(sToNode)
    sToNode:setTag(chaNode.heroNode.id)

    -- ��l����
    scaleXFn()
end
-- �w���԰��Ʀrccb
function NgBattleCharacterUtil:preloadBattleNums2(chaNode)
    local loadNum = CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 and 0 or 5
    local numNode = chaNode.heroNode.chaCCB:getVarNode("mNumNode")
    chaNode.HIT_NUM_POOL = chaNode.HIT_NUM_POOL or { } 
    for i = 1, 10 do
        chaNode.HIT_NUM_POOL[i] = chaNode.HIT_NUM_POOL[i] or { } 
        for num = 1, loadNum do
            local addAniCCB = nil
            if i == CONST.SHOW_NUM_TYPE.ENEMY_CRI_ATTACK then
                addAniCCB = ScriptContentBase:create("BattleCritsNum01")
            elseif i == CONST.SHOW_NUM_TYPE.CRI_ATTACK then
                addAniCCB = ScriptContentBase:create("BattleCritsNum02")
            elseif i == CONST.SHOW_NUM_TYPE.ENEMY_PHY_ATTACK then
                addAniCCB = ScriptContentBase:create("BattleNormalNum01")
            elseif i == CONST.SHOW_NUM_TYPE.ENEMY_MAG_ATTACK then
                addAniCCB = ScriptContentBase:create("BattleNormalNum02")
            elseif i == CONST.SHOW_NUM_TYPE.PHY_ATTACK then
                addAniCCB = ScriptContentBase:create("BattleNormalNum03")
            elseif i == CONST.SHOW_NUM_TYPE.MISS then
                addAniCCB = ScriptContentBase:create("BattleDodgeNum")
            elseif i == CONST.SHOW_NUM_TYPE.DOT then
                addAniCCB = ScriptContentBase:create("BattleHealNum02")
            elseif i == CONST.SHOW_NUM_TYPE.HEALTH then
                addAniCCB = ScriptContentBase:create("BattleHealNum")
            elseif i == CONST.SHOW_NUM_TYPE.MANA then
                addAniCCB = ScriptContentBase:create("BattleHealNum04")
            end
            if addAniCCB then
                addAniCCB.isDone = false
                table.insert(chaNode.HIT_NUM_POOL[i], addAniCCB)
                numNode:addChild(addAniCCB)
                addAniCCB:release() 
                addAniCCB:setVisible(false)
            end
        end
    end
end
function NgBattleCharacterUtil:preloadBattleNums(chaNode)
    local loadNum = CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 and 1 or 4
    local numNode = chaNode.heroNode.chaCCB:getVarNode("mNumNode")
    chaNode.HIT_NUM_POOL = chaNode.HIT_NUM_POOL or { } 
    for i = 1, 10 do
        chaNode.HIT_NUM_POOL[i] = chaNode.HIT_NUM_POOL[i] or { } 
        for num = 1, loadNum do
            local ccbFileName = nil
            local addAniCCB = nil
            if i == CONST.SHOW_NUM_TYPE.ENEMY_CRI_ATTACK then
                if chaNode.idx > 10 then
                    ccbFileName = "BattleCritsNum01"
                end
            elseif i == CONST.SHOW_NUM_TYPE.CRI_ATTACK then
                if chaNode.idx <= 10 then
                    ccbFileName = "BattleCritsNum02"
                end
            elseif i == CONST.SHOW_NUM_TYPE.ENEMY_PHY_ATTACK then
                if chaNode.idx > 10 then
                    ccbFileName = "BattleNormalNum01"
                end
            elseif i == CONST.SHOW_NUM_TYPE.ENEMY_MAG_ATTACK then
                if chaNode.idx > 10 then
                    ccbFileName = "BattleNormalNum02"
                end
            elseif i == CONST.SHOW_NUM_TYPE.PHY_ATTACK then
                if chaNode.idx <= 10 then
                    ccbFileName = "BattleNormalNum03"
                end
            elseif i == CONST.SHOW_NUM_TYPE.MISS then
                --ccbFileName = "BattleDodgeNum"
            elseif i == CONST.SHOW_NUM_TYPE.DOT then
                --ccbFileName = "BattleHealNum02"
            elseif i == CONST.SHOW_NUM_TYPE.HEALTH then
                ccbFileName = "BattleHealNum"
            elseif i == CONST.SHOW_NUM_TYPE.MANA then
                --ccbFileName = "BattleHealNum04"
            end
            if ccbFileName then
                local fn = function(data)
                    data.parent:addChild(data.ccb)
                    data.ccb:release()
                    data.ccb:setVisible(false)
                    data.ccb.isDone = true
                    table.insert(chaNode.HIT_NUM_POOL[data.type], data.ccb) 
                end
                local task = ALFManager:loadCcbTask(numNode, ccbFileName, i, fn)
                NgBattleDataManager.asyncLoadTasks[chaNode.idx] = NgBattleDataManager.asyncLoadTasks[chaNode.idx] or { }
                table.insert(NgBattleDataManager.asyncLoadTasks[chaNode.idx], task)
            end
        end
    end
end
-------------------------------------------------------
-- �]�wHP
function NgBattleCharacterUtil:setHp(chaNode, hp, isInit)
    chaNode.battleData[CONST.BATTLE_DATA.PRE_HP] = chaNode.battleData[CONST.BATTLE_DATA.HP]
    chaNode.battleData[CONST.BATTLE_DATA.HP] = hp
    local per = chaNode.battleData[CONST.BATTLE_DATA.HP] / chaNode.battleData[CONST.BATTLE_DATA.MAX_HP]
    per = math.max(0, math.min(1, per))
    chaNode.heroNode.chaCCB:getVarSprite("mHpBar"):setScaleX(per)
    -- ��s�d�PUI���
    NgBattlePageInfo_updateTargetCardHpInfo(chaNode.idx, chaNode.battleData[CONST.BATTLE_DATA.HP], chaNode.battleData[CONST.BATTLE_DATA.MAX_HP])
    if not isInit then
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.CHANGE_HP]) do -- ��q�ܤ�
            local resultTable = { }
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            if NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.CHANGE_HP) then
                LOG_UTIL:setPreLog(chaNode, resultTable)
                self:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
            end
        end
    end
end
-- �]�wMP
function NgBattleCharacterUtil:setMp(chaNode, mp, isSkipPre)
    if not isSkipPre then
        chaNode.battleData[CONST.BATTLE_DATA.PRE_MP] = chaNode.battleData[CONST.BATTLE_DATA.MP]
    end
    chaNode.battleData[CONST.BATTLE_DATA.MP] = mp
    local per = chaNode.battleData[CONST.BATTLE_DATA.MP] / chaNode.battleData[CONST.BATTLE_DATA.MAX_MP]
    per = math.max(0, math.min(1, per))
    chaNode.heroNode.chaCCB:getVarSprite("mMpBar"):setScaleX(per)
    -- ��s�d�PUI���
    NgBattlePageInfo_updateTargetCardMpInfo(chaNode.idx, chaNode.battleData[CONST.BATTLE_DATA.MP], chaNode.battleData[CONST.BATTLE_DATA.MAX_MP])
end
-- �]�w�@��
function NgBattleCharacterUtil:setShield(chaNode, shield)
    chaNode.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = chaNode.battleData[CONST.BATTLE_DATA.SHIELD]
    chaNode.battleData[CONST.BATTLE_DATA.SHIELD] = shield
    local per = math.min(chaNode.battleData[CONST.BATTLE_DATA.SHIELD] / chaNode.battleData[CONST.BATTLE_DATA.MAX_HP], 1)
    per = math.max(0, math.min(1, per))
    chaNode.heroNode.chaCCB:getVarSprite("mShieldBar"):setScaleX(per)
    if chaNode.battleData[CONST.BATTLE_DATA.PRE_SHIELD] > 0 and chaNode.battleData[CONST.BATTLE_DATA.SHIELD] <= 0 then    --�@�ޮ���
        chaNode.heroNode.chaCCB:getVarSprite("mShieldBar"):setVisible(false)
        self:clearSkillTimer(chaNode.skillData, CONST.ADD_BUFF_COUNT_EVENT.SHIELD_CLEAR)    --�@�ޮ����ɲM�ůS�wskill�p��
        BuffManager:clearBuffTimer(chaNode, chaNode.buffData, CONST.ADD_BUFF_COUNT_EVENT.SHIELD_CLEAR)    --�@�ޮ����ɲM�ůS�wbuff�p��
        BuffManager:addBuffCount(chaNode, chaNode.buffData, CONST.ADD_BUFF_COUNT_EVENT.SHIELD_CLEAR)   --�@�ޮ����ɼW�[buff�h��
        local triggerBuffList = BuffManager:specialBuffEffect(chaNode.buffData, CONST.ADD_BUFF_COUNT_EVENT.SHIELD_CLEAR, node, nil, nil)   --�@�ޮ�����Ĳ�obuff�ĪG
    else
        chaNode.heroNode.chaCCB:getVarSprite("mShieldBar"):setVisible(true)
    end
    -- ��s�d�PUI���
    NgBattlePageInfo_updateTargetCardShieldInfo(chaNode.idx, chaNode.battleData[CONST.BATTLE_DATA.SHIELD], chaNode.battleData[CONST.BATTLE_DATA.MAX_HP])
end
--�W�[�@�ޭ�(�ޯ��)
function NgBattleCharacterUtil:addShield(chaNode, target, shieldNum)
    if target then
        local ratio = NewBattleUtil:calAuraSkillRatio(target, CONST.PASSIVE_TRIGGER_TYPE.AURA_SHIELD)  -- �@�ޥ���
        local auraShield = NewBattleUtil:calRoundValue(shieldNum * ratio, 1)
        self:setShield(target, target.battleData[CONST.BATTLE_DATA.SHIELD] + auraShield)   --�W�[�@��
        LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.ADD_SHIELD, chaNode, target, 0, false, false, auraShield)
        --local sceneHelper = require("Battle.NgFightSceneHelper")
        --sceneHelper:addBattleResult(CONST.DETAIL_DATA_TYPE.HEALTH, chaNode.idx, shieldNum, 0, false, shieldNum)   -- ���p�ⷸ��
    end
end
--���m�ޯ�CD(�ޯ��)
function NgBattleCharacterUtil:resetSkillCd(chaNode, skillBaseId)
    if chaNode then
        for _type, _allTypeSkill in pairs(chaNode.skillData) do
            for _skillId, _skillData in pairs(_allTypeSkill) do
                if math.floor(_skillId / 10) == skillBaseId then
                    _skillData["CD"] = 0
                    return
                end
            end
        end
    end
end
-- ����spine�ʵe
function NgBattleCharacterUtil:setSpineAnimation(chaNode, ani, loop)
    --�ˬd�J�ت��A
    if not BuffManager:isInTaunt(chaNode.buffData) then
        BuffManager:clearTauntTarget(chaNode)
    end
    if not chaNode.heroNode.heroSpine then return end
    if chaNode.heroNode.heroSpine:isPlayingAnimation(ani, 1) then return end
    chaNode.heroNode.heroSpine:setToSetupPose()
    local loopIndex = loop and -1 or 0
    self:initAttackParams(chaNode)
    chaNode.ATTACK_PARAMS["play_spine_time"] = NgBattleDataManager.battleTime
    --if chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME] and chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME] ~= "" then
    --    chaNode.heroNode.heroSpine:setMix(chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME], ani, 0.1)
    --end
    chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME] = ani
    chaNode.heroNode.heroSpine:runAnimation(1, ani, loopIndex)
    if chaNode.heroNode.heroBackFx then
        chaNode.heroNode.heroBackFx:setToSetupPose()
        chaNode.heroNode.heroBackFx:runAnimation(1, ani, loopIndex)
    end
    if chaNode.heroNode.heroFrontFx then
        chaNode.heroNode.heroFrontFx:setToSetupPose()
        chaNode.heroNode.heroFrontFx:runAnimation(1, ani, loopIndex)
    end
    if chaNode.heroNode.heroFloorFx then
        chaNode.heroNode.heroFloorFx:setToSetupPose()
        chaNode.heroNode.heroFloorFx:runAnimation(1, ani, loopIndex)
    end
    if ani == CONST.ANI_ACT.ATTACK or
       ani == CONST.ANI_ACT.SKILL0 or
       ani == CONST.ANI_ACT.SKILL1 or
       ani == CONST.ANI_ACT.SKILL2 then -- ��������log�ɶ�
        if chaNode.battleData[CONST.BATTLE_DATA.PRE_HP] <= 0 then  -- �w���`
            chaNode.heroNode.heroSpine:unregisterFunctionHandler("SELF_EVENT")
        elseif BuffManager:isInCrowdControl(chaNode.buffData) then  -- ����
            self:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
        else
            chaNode.onPlaySpineAnimation()
        end
    end
        
    self:setSpineFxVisible(chaNode, ani)
end
-- �]�wSpine�S�İʵe���
function NgBattleCharacterUtil:setSpineFxVisible(chaNode, ani)
    if chaNode and chaNode.heroNode.heroBackFx then
        local sToNodeBack = tolua.cast(chaNode.heroNode.heroBackFx, "CCNode")
        if ani == CONST.ANI_ACT.ATTACK or ani == CONST.ANI_ACT.SKILL0 or ani == CONST.ANI_ACT.SKILL1 or ani == CONST.ANI_ACT.SKILL2 then
            sToNodeBack:setVisible(true)
        else
            sToNodeBack:setVisible(false)
        end
    end
    if chaNode and chaNode.heroNode.heroFrontFx then
        local sToNodeFront = tolua.cast(chaNode.heroNode.heroFrontFx, "CCNode")
        if ani == CONST.ANI_ACT.ATTACK or ani == CONST.ANI_ACT.SKILL0 or ani == CONST.ANI_ACT.SKILL1 or ani == CONST.ANI_ACT.SKILL2 then
            sToNodeFront:setVisible(true)
        else
            sToNodeFront:setVisible(false)
        end
    end
    if chaNode and chaNode.heroNode.heroFloorFx then
        local sToNodeFloor = tolua.cast(chaNode.heroNode.heroFloorFx, "CCNode")
        if ani == CONST.ANI_ACT.ATTACK or ani == CONST.ANI_ACT.SKILL0 or ani == CONST.ANI_ACT.SKILL1 or ani == CONST.ANI_ACT.SKILL2 then
            sToNodeFloor:setVisible(true)
        else
            sToNodeFloor:setVisible(false)
        end
    end
end
-- �]�wSpine Scale X
function NgBattleCharacterUtil:setSpineScaleX(chaNode, scaleX)
    local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
    sToNode:setScaleX(scaleX)
    if chaNode and chaNode.heroNode.heroBackFx then
        local sToNodeBack = tolua.cast(chaNode.heroNode.heroBackFx, "CCNode")
        sToNodeBack:setScaleX(scaleX)
    end
    if chaNode and chaNode.heroNode.heroFrontFx then
        local sToNodeFront = tolua.cast(chaNode.heroNode.heroFrontFx, "CCNode")
        sToNodeFront:setScaleX(scaleX)
    end
    if chaNode and chaNode.heroNode.heroFloorFx then
        local sToNodeFloor = tolua.cast(chaNode.heroNode.heroFloorFx, "CCNode")
        sToNodeFloor:setScaleX(scaleX)
    end
    for k, v in pairs(chaNode.allSpineTable) do
        if v and tonumber(k) and k > NewBattleConst.BUFF_ID_FX1_OFFSET then
            local buffNode = tolua.cast(chaNode.allSpineTable[k], "CCNode")
            if buffNode then
                buffNode:setScaleX(scaleX)
            end
        end
    end
end
-- ���ʦܥؼЦ�m
function NgBattleCharacterUtil:moveToTargetPos(chaNode, posX, posY)
    local oriX = chaNode.heroNode.chaCCB:getPositionX()
    local oriY = chaNode.heroNode.chaCCB:getPositionY()
    chaNode.heroNode.chaCCB:setPositionX(posX)
    chaNode.heroNode.chaCCB:setPositionY(posY)
    if self:getPos(chaNode).x < 0 and oriX >= 0 then    -- �W�X�Գ��d��
        chaNode.heroNode.chaCCB:setPositionX(0)
    end
    if self:getPos(chaNode).x > CONST.BATTLE_FIELD_WIDTH and oriX <= CONST.BATTLE_FIELD_WIDTH then    -- �W�X�Գ��d��
        chaNode.heroNode.chaCCB:setPositionX(CONST.BATTLE_FIELD_WIDTH)
    end
    if self:getPos(chaNode).y < 0 and oriY >= 0 then    -- �W�X�Գ��d��
        chaNode.heroNode.chaCCB:setPositionY(0)
    end
    if self:getPos(chaNode).y > CONST.BATTLE_FIELD_HEIGHT and oriY <= CONST.BATTLE_FIELD_HEIGHT then    -- �W�X�Գ��d��
        chaNode.heroNode.chaCCB:setPositionY(CONST.BATTLE_FIELD_HEIGHT)
    end
    chaNode.floorNode:setPosition(ccpAdd(ccp(chaNode.heroNode.chaCCB:getPosition()), ccp(chaNode.heroNode.chaCCB:getVarNode("mHitFrontNode"):getPosition())))     --�a�O�S���I��
    --�]�wZ Order
    chaNode.heroNode.chaCCB:setZOrder(CONST.Z_ORDER_MASK - chaNode.heroNode.chaCCB:getPositionY())
    chaNode.floorNode:setZOrder(chaNode.otherData[CONST.OTHER_DATA.Z_ORDER] - CONST.FLOOR_Z_ORDER_MASK)    --�a�O�S���I��
end
-- �վ㨤�⭱�V
function NgBattleCharacterUtil:setChaDir(chaNode, target)
    if not chaNode or not target then
        return
    end
    --�]�w����
    local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
    --½��S�wBOSS
    if chaNode.otherData[CONST.OTHER_DATA.IS_FLIP] == 1 then
        -- �b�ؼХk�� > scalex�p��0
        if self:getPos(target).x < self:getPos(chaNode).x and sToNode:getScaleX() < 0 then
            self:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
        -- �b�ؼХ��� > scalex�j��0
        elseif self:getPos(target).x > self:getPos(chaNode).x and sToNode:getScaleX() > 0 then
            self:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
        end
    else
        -- �b�ؼХk�� > scalex�j��0
        if self:getPos(target).x < self:getPos(chaNode).x and sToNode:getScaleX() > 0 then
            self:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
        -- �b�ؼХ��� > scalex�p��0
        elseif self:getPos(target).x > self:getPos(chaNode).x and sToNode:getScaleX() < 0 then
            self:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
        end
    end
end
-- �O�_½������S��
function NgBattleCharacterUtil:calIsFlipHitEffect(attacker, target)
    return self:getPos(attacker).x > self:getPos(target).x
end
-- 
function NgBattleCharacterUtil:checkPassiveSkill(chaNode, isSkipHit)
    --if chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.SKILL0, 1) or
    --   chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.SKILL1, 1) or
    --   chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.SKILL2, 1) then   --���ݧ����ʧ@����
    --    return false
    --end
    --if chaNode.battleData[CONST.BATTLE_DATA.HP] > 0 and    -- ����S�����`
    --   not BuffManager:isInCrowdControl(chaNode.buffData) then -- �S���Q����
    --    local passiveIds = { 1002, 9902, 600103, 600203, 600503,    -- hp����
    --                         2, 22, 42, 1202, 2202, 2402, 600102, 600202,     -- mp����
    --                         3002, 3102, 3202,                   -- �R������
    --                         2002, 2102, 600502                   -- CD����
    --                       }           
    --    local hitIds = { [3002] = true, [3102] = true, [3202] = true }
    --    for i = 1, #passiveIds do
    --        if not hitIds[passiveIds[i]] or not isSkipHit then
    --            if NewBattleUtil:castAutoSkill(passiveIds[i], node) then
    --                return true
    --            end
    --        end
    --    end
    --end
    --return false
end

-- �������A
function NgBattleCharacterUtil:setState(chaNode, state)
    chaNode.nowState = state
end
-- ���o���A
function NgBattleCharacterUtil:getState(chaNode)
    return chaNode.nowState
end
-- ���o�y��
function NgBattleCharacterUtil:getPos(chaNode)
    local posX, posY = chaNode.heroNode.chaCCB:getPosition()
    return { x = posX, y = posY }
end

-- ��l�Ƨ����Ѽ�
function NgBattleCharacterUtil:initAttackParams(chaNode)
    chaNode.ATTACK_PARAMS = { }
    chaNode.ATTACK_PARAMS["hit_num"] = 0 
    chaNode.ATTACK_PARAMS["shoot_count"] = 0
    chaNode.ATTACK_PARAMS["hit_count"] = 0
    chaNode.ATTACK_PARAMS["play_spine_time"] = 0
    chaNode.ATTACK_PARAMS["cast_attacker"] = nil
    chaNode.ATTACK_PARAMS["skill_target"] = nil
end
-- �O�_�b�԰��ϰ줺
function NgBattleCharacterUtil:isInBattleField(chaNode)
    if self:getPos(chaNode).x >= 0 and self:getPos(chaNode).x <= CONST.BATTLE_FIELD_WIDTH and
       self:getPos(chaNode).y >= 0 and self:getPos(chaNode).y <= CONST.BATTLE_FIELD_HEIGHT then
        return true
    end
    return false
end
-- �O�_�O�ڤ訤��
function NgBattleCharacterUtil:isMineCharacter(chaNode)
    return chaNode.idx < 10
end
-- �ؼЬO�_�b�i���������A
function NgBattleCharacterUtil:isTargetCanAttackState(chaNode)
    local isAttackState = false
    if not chaNode.target then
        return isAttackState
    end
    if self:getState(chaNode.target) == CONST.CHARACTER_STATE.WAIT or self:getState(chaNode.target) == CONST.CHARACTER_STATE.MOVE or
       self:getState(chaNode.target) == CONST.CHARACTER_STATE.ATTACK or self:getState(chaNode.target) == CONST.CHARACTER_STATE.HURT then
        isAttackState = true
    end
    return isAttackState
end
-- �O�_�b���ʰʧ@��
function NgBattleCharacterUtil:isInMoveAni(chaNode)
    local inMove = false
    if chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.RUN, 1) or
       chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.WALK, 1) then   -- �b���ʰʧ@��
        inMove = true
    end
    return inMove
end
-- �O�_�b�����ʧ@��
function NgBattleCharacterUtil:isInAttackAni(chaNode)
    local inAttack = false
    if chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.ATTACK, 1) or
       chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.SKILL0, 1) or
       chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.SKILL1, 1) or
       chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.SKILL2, 1) then   -- �b�����ʧ@��
        inAttack = true
    end
    return inAttack
end
-- �O�_�b�j�۰ʧ@��
function NgBattleCharacterUtil:isInSkill0Ani(chaNode)
    local inAttack = false
    if chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.SKILL0, 1) then   -- �b�����ʧ@��
        inAttack = true
    end
    return inAttack
end
-- �O�_�i�H����
function NgBattleCharacterUtil:isCanNormalAttack(chaNode)
    local canAttack = false
    if self:isTargetInAttackRange(chaNode) and                  -- �b�����Z����
       not BuffManager:isInCrowdControl(chaNode.buffData) and   -- ���b�������A
       not self:isInAttackAni(chaNode) and                      -- ���b�����ʧ@��
       self:isAttackCdEnd(chaNode) then                         -- ����CD�৹
        canAttack = true
    end
    return canAttack
end
-- ����CD�O�_�৹
function NgBattleCharacterUtil:isAttackCdEnd(chaNode)
    local isCdEnd = false
    if chaNode.atkCD >= NewBattleUtil:calAttackCD(chaNode, chaNode.target) then
        isCdEnd = true
    end
    return isCdEnd
end
-- �ؼЬO�_�b����d��
function NgBattleCharacterUtil:isTargetInAttackRange(chaNode)
    local inRange = false
    local atkRange = chaNode.battleData[CONST.BATTLE_DATA.RANGE]                -- �ڤ訤������Z��
    local atkRangeBuff = BuffManager:checkAtkRangeValue(chaNode.buffData)
    atkRange = atkRange + atkRangeBuff
    local chaW = chaNode.otherData[CONST.OTHER_DATA.CFG].CenterOffsetX          -- �ڤ訤����x��V�b�b��
    local chaH = chaNode.otherData[CONST.OTHER_DATA.CFG].CenterOffsetY          -- �ڤ訤����y��V�b�b��
    local chaX, chaY = self:getPos(chaNode).x, self:getPos(chaNode).y + chaH          -- �ڤ訤�⤤�߮y��
    local tarW = chaNode.target.otherData[CONST.OTHER_DATA.CFG].CenterOffsetX         -- �Ĥ訤����x��V�b�b��
    local tarH = chaNode.target.otherData[CONST.OTHER_DATA.CFG].CenterOffsetY         -- �Ĥ訤����y��V�b�b��
    local tarX, tarY = self:getPos(chaNode.target).x, self:getPos(chaNode.target).y + tarH   -- �Ĥ訤�⤤�߮y��

    local result = (((tarX - chaX) * (tarX - chaX)) / ((chaW + atkRange + tarW) * (chaW + atkRange + tarW))) + 
                   (((tarY - chaY) * (tarY - chaY)) / ((chaH + atkRange * 0.1 + tarH) * (chaH + atkRange * 0.5 + tarH)))
    return result <= 1
end
-- �O�_�i�H�I��j��
function NgBattleCharacterUtil:isCanSkill(chaNode, isAuto)
    local canSkill = false
    if chaNode.battleData[CONST.BATTLE_DATA.MP] >= 100 and      -- ��100�IMP
       chaNode.skillData[CONST.SKILL_DATA.SKILL] and            -- ���j��
       not BuffManager:isInSilene(chaNode.buffData) and         -- ���b�I�q���A
       not BuffManager:isInFrenzy(chaNode.buffData) and         -- ���b�g�ê��A
       not BuffManager:isInCrowdControl(chaNode.buffData) and   -- ���b�������A
       not (isAuto and self:isInAttackAni(chaNode)) then        -- ���b�����ʧ@��(��ʬI��ɤ��ˬd)
        canSkill = true
    end
    return canSkill
end
-- �O�_�i�H�I��p��
function NgBattleCharacterUtil:isCanLittleSkill(chaNode, triggerType)
    local canSkill = false
    if chaNode.skillData[CONST.SKILL_DATA.AUTO_SKILL] and            -- ���p��
       not BuffManager:isInSilene(chaNode.buffData) and         -- ���b�I�q���A
       not BuffManager:isInFrenzy(chaNode.buffData) and         -- ���b�g�ê��A
       not BuffManager:isInCrowdControl(chaNode.buffData) then   -- ���b�������A
        if triggerType == CONST.SKILL1_TRIGGER_TYPE.NORMAL then
            if not self:isInAttackAni(chaNode) then                     -- ���b�����ʧ@��
                canSkill = true
            end
        elseif triggerType == CONST.SKILL1_TRIGGER_TYPE.DODGE then
            if not self:isInSkill0Ani(chaNode) then
                canSkill = true
            end
        elseif triggerType == CONST.SKILL1_TRIGGER_TYPE.STEALTH_CLEAR then
            if not self:isInSkill0Ani(chaNode) then
                canSkill = true
            end
        end
    end
    return canSkill
end
-- �ˬd����p��Ĳ�o����(�^��Ĳ�oskillId)
function NgBattleCharacterUtil:getTriggerLittleSkill(chaNode, triggerType)
    if not chaNode.skillData[CONST.SKILL_DATA.AUTO_SKILL] then
        return nil
    end
    for k, v in pairs(chaNode.skillData[CONST.SKILL_DATA.AUTO_SKILL]) do
        if SkillManager:isSkillUsable(chaNode, CONST.SKILL_DATA.AUTO_SKILL, k, triggerType) then
            return k
        end
    end
    return nil
end
-- �M�ťؼЧޯ�p�ɾ�
function NgBattleCharacterUtil:clearSkillTimer(skill, event)
    if skill then
        if event == CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK then
        elseif event == CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE then
            if skill[CONST.SKILL_DATA.PASSIVE] and skill[CONST.SKILL_DATA.PASSIVE][90012] then
                skill[CONST.SKILL_DATA.PASSIVE][90012]["TIMER"] = 0
            end
        elseif event == CONST.ADD_BUFF_COUNT_EVENT.SHIELD_CLEAR then
        end
    end
end
--���]timeScale
function NgBattleCharacterUtil:resetTimeScale(chaNode)
    NgBattleCharacterUtil:setTimeScale(chaNode, NgBattleDataManager.battleSpeed)
end
--�]�wtimeScale
function NgBattleCharacterUtil:setTimeScale(chaNode, speed)
    -- ����
    chaNode.heroNode.heroSpine:setTimeScale(speed)
    if chaNode.heroNode.heroBackFx then
        -- �����h�S��
        chaNode.heroNode.heroBackFx:setTimeScale(speed)
    end
    if chaNode.heroNode.heroFrontFx then
        -- ����e�h�S��
        chaNode.heroNode.heroFrontFx:setTimeScale(speed)
    end
    if chaNode.heroNode.heroFloorFx then
        -- ���⩳�h�S��
        chaNode.heroNode.heroFloorFx:setTimeScale(speed)
    end
end

-- �إߴ��𵲪Gtable
function NgBattleCharacterUtil:createAttackResultTable(chaNode, params)
    --�p���¦�ˮ`, �O�_�g��
    local dmg, weakType = NewBattleUtil:calBaseDamage(chaNode, chaNode.target)
    chaNode.ATTACK_PARAMS["base_dmg"] = dmg
    chaNode.ATTACK_PARAMS["weak_type"] = weakType or 0
    --�p��Chit�ˮ`, �Chit�O�_�z��
    local hit_num = math.max(params and params["hit_num"] or chaNode.ATTACK_PARAMS["hit_num"], 1)
    --�̲׵��Gtable
    local resultTable = NewBattleUtil:calNormalAtkResult(chaNode, chaNode.target, hit_num)
    return resultTable
end
-- �B�z����table
function NgBattleCharacterUtil:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    self:calculateDmgTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    self:calculateHealTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    self:calculateBuffTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    self:calculateSpGainMpTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    self:calculateSpFunctionTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
end
-- �B�zdamage table
function NgBattleCharacterUtil:calculateDmgTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    local targetTable = resultTable[NewBattleConst.LogDataType.DMG_TAR]
    local dmgTable = resultTable[NewBattleConst.LogDataType.DMG]
    local isCriTable = resultTable[NewBattleConst.LogDataType.DMG_CRI]
    local weakTypeTable = resultTable[NewBattleConst.LogDataType.DMG_WEAK]

    if not targetTable or #targetTable <= 0 then
        return
    end
    -- �ޯ�Z������ (�P�@hit���u���@��)
    local sceneHelper = require("Battle.NgFightSceneHelper")
    if skillId then
        local skillBaseId = math.floor(skillId / 10)
        sceneHelper:playSoundEffect("skill_" .. skillBaseId .. ".mp3", chaNode)
    else
        -- ����Z������  
        sceneHelper:playSoundEffect("Weapon_" .. chaNode.otherData[CONST.OTHER_DATA.ITEM_ID] .. ".mp3", chaNode)
    end
    for i = 1, #targetTable do  --�ˮ`�B�z
        if targetTable[i] and self:getState(targetTable[i]) ~= CONST.CHARACTER_STATE.DYING and 
           self:getState(targetTable[i]) ~= CONST.CHARACTER_STATE.DEATH and
           self:getState(targetTable[i]) ~= CONST.CHARACTER_STATE.REBIRTH then
            --����
            if targetTable[i].beAttack then
                targetTable[i].beAttack(chaNode, targetTable[i], dmgTable[i], isCriTable[i], 
                                        isSkipCal, weakTypeTable[i], skillId, resultTable, allPassiveTable)
            end
            if dmgTable[i] > 0 then --�R��
                if skillId then
                    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.SKILL_ATTACK, chaNode, targetTable[i], skillId, weakTypeTable[i], isCriTable[i], dmgTable[i])
                else
                    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.NORMAL_ATTACK, chaNode, targetTable[i], 0, weakTypeTable[i], isCriTable[i], dmgTable[i])
                end
                if chaNode.onHit then
                    chaNode.onHit(chaNode, skillId, resultTable, allPassiveTable, targetTable[i], isCriTable[i])
                end
                table.insert(actionResultTable, isCriTable[i] and CONST.LogActionResultType.CRITICAL or CONST.LogActionResultType.HIT)
            else
                if skillId then
                    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.SKILL_MISS, chaNode, targetTable[i], skillId, false, 0, 0)
                else
                    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.ATTACK_MISS, chaNode, targetTable[i], 0, false, 0, 0)
                end
                if chaNode.onMiss then
                    chaNode.onMiss(chaNode, skillId, resultTable, allPassiveTable, targetTable[i], isCriTable[i])
                end
                table.insert(actionResultTable, CONST.LogActionResultType.MISS)   
            end
            NewBattleUtil:insertLogTarget(allTargetTable, targetTable[i])
        end
    end
end
-- �B�zheal table
function NgBattleCharacterUtil:calculateHealTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    local healTargetTable = nil
    local healTable = nil
    local healIsCriTable = nil

    healTargetTable = resultTable[NewBattleConst.LogDataType.HEAL_TAR]
    healTable = resultTable[NewBattleConst.LogDataType.HEAL]
    healIsCriTable = resultTable[NewBattleConst.LogDataType.HEAL_CRI]

    if not healTargetTable or #healTargetTable <= 0 then
        return
    end
    local ratio = NewBattleUtil:calAuraSkillRatio(chaNode, CONST.PASSIVE_TRIGGER_TYPE.AURA_HEALTH)  -- �v���q����
    for i = 1, #healTargetTable do  --�v���B�z
        if healTargetTable[i] and self:getState(healTargetTable[i]) ~= CONST.CHARACTER_STATE.DYING and 
           self:getState(healTargetTable[i]) ~= CONST.CHARACTER_STATE.DEATH and
           self:getState(healTargetTable[i]) ~= CONST.CHARACTER_STATE.REBIRTH then
            --�����v��
            if healTargetTable[i].beHealth then
                local auraHealth = NewBattleUtil:calRoundValue(healTable[i] * ratio, 1)
                healTargetTable[i].beHealth(chaNode, healTargetTable[i], auraHealth, healIsCriTable[i], isSkipCal, skillId, resultTable, allPassiveTable)
                if skillId then
                    local buffConfig = ConfigManager:getNewBuffCfg()
                    if (skillId < 10000) then skillId = skillId * 10 end
                    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.SKILL_HEALTH, chaNode, healTargetTable[i], skillId, false, healIsCriTable[i], auraHealth)
                else
                    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.LEECH_HEALTH, chaNode, healTargetTable[i], 0, false, healIsCriTable[i], auraHealth)
                end
            end
            if not NewBattleUtil:insertLogTarget(allTargetTable, healTargetTable[i]) then
                --�ˮ`&�v��target��������
                table.insert(actionResultTable, healIsCriTable[i] and CONST.LogActionResultType.CRITICAL or CONST.LogActionResultType.HIT)
            end
        end
    end
end
-- �B�zbuff table
function NgBattleCharacterUtil:calculateBuffTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    local buffTargetTable = nil
    local buffTable = nil
    local buffTimeTable = nil
    local buffCountTable = nil

    buffTargetTable = resultTable[NewBattleConst.LogDataType.BUFF_TAR]
    buffTable = resultTable[NewBattleConst.LogDataType.BUFF]
    buffTimeTable = resultTable[NewBattleConst.LogDataType.BUFF_TIME]
    buffCountTable = resultTable[NewBattleConst.LogDataType.BUFF_COUNT]

    if not buffTargetTable or #buffTargetTable <= 0 then
        return
    end
    for i = 1, #buffTargetTable do  --buff�B�z
        local success = true
        if buffTargetTable[i] and self:getState(buffTargetTable[i]) ~= CONST.CHARACTER_STATE.DYING and 
           self:getState(buffTargetTable[i]) ~= CONST.CHARACTER_STATE.DEATH and
           self:getState(buffTargetTable[i]) ~= CONST.CHARACTER_STATE.REBIRTH then
            if buffTable[i] > 0 then 
                --��obuff
                success = BuffManager:getBuff(chaNode, buffTargetTable[i], buffTable[i], buffTimeTable[i], buffCountTable[i])
            else
                --����buff
                self:forceClearTargetBuff(buffTargetTable[i], NgBattleDataManager_getFriendList(buffTargetTable[i]), 
                                          NgBattleDataManager_getEnemyList(buffTargetTable[i]), buffTable[i] * -1)  
            end
            if not NewBattleUtil:insertLogTarget(allTargetTable, buffTargetTable[i]) and success then
                --���b�ˮ`�Ϊv����target�� -> �¤Wbuff(�S���R���z�����O)
                table.insert(actionResultTable, CONST.LogActionResultType.HIT)
            end
        end
    end
end
-- �B�zsp gain mp table
function NgBattleCharacterUtil:calculateSpGainMpTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    local spGainMpTable = nil
    local mpTable = nil

    spGainMpTable = resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR]
    mpTable = resultTable[NewBattleConst.LogDataType.SP_GAIN_MP]

    if not spGainMpTable or #spGainMpTable <= 0 then
        return
    end
    for i = 1, #spGainMpTable do  --�S�w�ޯ���oMP
        if spGainMpTable[i] and self:getState(spGainMpTable[i]) ~= CONST.CHARACTER_STATE.DYING and 
           self:getState(spGainMpTable[i]) ~= CONST.CHARACTER_STATE.DEATH and
           self:getState(spGainMpTable[i]) ~= CONST.CHARACTER_STATE.REBIRTH then
            if spGainMpTable[i] then
                spGainMpTable[i].beDrainMana(chaNode, spGainMpTable[i], mpTable[i], true, skillId, resultTable, allPassiveTable)
            end
            if not NewBattleUtil:insertLogTarget(allTargetTable, spGainMpTable[i]) then
                --���b�ˮ`�Ϊv����BUFF��target�� -> �¦^MP(�S���R���z�����O)
                table.insert(actionResultTable, CONST.LogActionResultType.HIT)
            end
        end
    end
end
-- �B�z�S��function
function NgBattleCharacterUtil:calculateSpFunctionTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)
    local spClassNameTable = nil
    local spFunctionTable = nil
    local spParamsTable = nil
    local spTargetTable = nil

    spClassNameTable = resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS]
    spFunctionTable = resultTable[NewBattleConst.LogDataType.SP_FUN_NAME]
    spParamsTable = resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM]
    spTargetTable = resultTable[NewBattleConst.LogDataType.SP_FUN_TAR]

    if not spClassNameTable or not spFunctionTable or not spParamsTable or not spTargetTable then
        return
    end
    for i = 1, #spTargetTable do  --Class name
        if spClassNameTable[i] == NewBattleConst.FunClassType.BUFF_MANAGER then
            local fun = BuffManager[spFunctionTable[i]]
            local params = spParamsTable[i]
            fun(BuffManager, params[1], params[2], params[3], params[4], params[5])
        elseif spClassNameTable[i] == NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL then
            local fun = self[spFunctionTable[i]]
            local params = spParamsTable[i]
            fun(self, params[1], params[2], params[3], params[4], params[5])
        end
        if not NewBattleUtil:insertLogTarget(allTargetTable, spTargetTable[i]) then
            --���b�ˮ`�Ϊv����BUFF��target��
            table.insert(actionResultTable, CONST.LogActionResultType.HIT)
        end
    end
end
-- �j��M�ťؼ�buff/debuff
function NgBattleCharacterUtil:forceClearTargetBuff(chaNode, fList, eList, buffId, isPlayEnd)  
    if chaNode.buffData[buffId] then
        NewBattleUtil:removeBuff(chaNode, buffId, isPlayEnd)
        if chaNode.heroNode.buffNode:getChildByTag(buffId) then
            chaNode.heroNode.buffNode:removeChildByTag(buffId, true)
        end
        if chaNode.heroNode.debuffNode:getChildByTag(buffId) then
            chaNode.heroNode.debuffNode:removeChildByTag(buffId, true)
        end
        local buffCfg = ConfigManager:getNewBuffCfg()
        if buffCfg[buffId].buffType == CONST.BUFF_TYPE.AURA then
            -- �M���������ͪ�buff
            BuffManager:clearAuraBuff(buffId, fList, eList)
        end
    end
end

-- ���]�Ǫ����
function NgBattleCharacterUtil:resetMonsterInfo(chaNode)
    local monsterCfg = ConfigManager.getNewMonsterCfg()
    local mapCfg = ConfigManager.getNewMapCfg()
    local mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or 
                  (mapCfg[UserInfo.stateInfo.passMapId] and UserInfo.stateInfo.passMapId or UserInfo.stateInfo.curBattleMap - 1)
    local monsterIds = common:split(mapCfg[mapId].MonsterID, ",")
    local randIdx = math.random(1, #monsterIds)
    local mId = tonumber(monsterIds[randIdx])
    if monsterCfg[mId] then
        chaNode.battleData[NewBattleConst.BATTLE_DATA.IS_PHY] = monsterCfg[mId].IsMag == 0 and true or false
        chaNode.battleData[NewBattleConst.BATTLE_DATA.STR] = monsterCfg[mId].Str
        chaNode.battleData[NewBattleConst.BATTLE_DATA.INT] = monsterCfg[mId].Int
        chaNode.battleData[NewBattleConst.BATTLE_DATA.AGI] = monsterCfg[mId].Agi
        chaNode.battleData[NewBattleConst.BATTLE_DATA.STA] = monsterCfg[mId].Sta
        chaNode.battleData[NewBattleConst.BATTLE_DATA.PHY_PENETRATE] = monsterCfg[mId].PhyPenetrate / 100
        chaNode.battleData[NewBattleConst.BATTLE_DATA.MAG_PENETRATE] = monsterCfg[mId].MagPenetrate / 100
        chaNode.battleData[NewBattleConst.BATTLE_DATA.RECOVER_HP] = monsterCfg[mId].RecoverHp / 100
        chaNode.battleData[NewBattleConst.BATTLE_DATA.CRI_DMG] = monsterCfg[mId].CriDmg / 100
        chaNode.battleData[NewBattleConst.BATTLE_DATA.RUN_SPD] = monsterCfg[mId].RunSpd
        chaNode.battleData[NewBattleConst.BATTLE_DATA.WALK_SPD] = monsterCfg[mId].WalkSpd
        chaNode.battleData[NewBattleConst.BATTLE_DATA.RANGE] = monsterCfg[mId].AtkRng
        chaNode.battleData[NewBattleConst.BATTLE_DATA.COLD_DOWN] = monsterCfg[mId].AtkSpd
        chaNode.battleData[NewBattleConst.BATTLE_DATA.ELEMENT] = monsterCfg[mId].Element
        chaNode.battleData[NewBattleConst.BATTLE_DATA.ATK_MP] = monsterCfg[mId].AtkMp
        chaNode.battleData[NewBattleConst.BATTLE_DATA.DEF_MP] = monsterCfg[mId].DefMp
        chaNode.battleData[NewBattleConst.BATTLE_DATA.CLASS_CORRECTION] = monsterCfg[mId].ClassCorrection
        chaNode.battleData[NewBattleConst.BATTLE_DATA.SKILL_MP] = monsterCfg[mId].SkillMp
        --
        chaNode.battleData[NewBattleConst.BATTLE_DATA.PHY_ATK] = monsterCfg[mId].Atk
        chaNode.battleData[NewBattleConst.BATTLE_DATA.MAG_ATK] = monsterCfg[mId].Mag
        chaNode.battleData[NewBattleConst.BATTLE_DATA.PHY_DEF] = monsterCfg[mId].PhyDef
        chaNode.battleData[NewBattleConst.BATTLE_DATA.MAG_DEF] = monsterCfg[mId].MagDef
        chaNode.battleData[NewBattleConst.BATTLE_DATA.CRI] = monsterCfg[mId].Cri
        chaNode.battleData[NewBattleConst.BATTLE_DATA.HIT] = monsterCfg[mId].Hit
        chaNode.battleData[NewBattleConst.BATTLE_DATA.DODGE] = monsterCfg[mId].Dodge
        chaNode.battleData[NewBattleConst.BATTLE_DATA.IMMUNITY] = monsterCfg[mId].Immunity
        local spinePath, spineName = unpack(common:split(monsterCfg[mId].Spine, ","))
        chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH] = spinePath
        chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME] = spineName
        chaNode.otherData[CONST.OTHER_DATA.SPINE_SKIN] = monsterCfg[mId].Skin
        chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_BACK_FX] = "Spine/CharacterFX"
        chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_BACK_FX] = monsterCfg[mId].CharFxName .. "_FX2"
        chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FRONT_FX] = "Spine/CharacterFX"
        chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FRONT_FX] = monsterCfg[mId].CharFxName .. "_FX1"
        chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FLOOR_FX] = "Spine/CharacterFX"
        chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FLOOR_FX] = monsterCfg[mId].CharFxName .. "_FX3"
        chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_BULLET] = "Spine/CharacterBullet"
        chaNode.otherData[CONST.OTHER_DATA.IS_FLIP] = monsterCfg[mId].Reflect
        chaNode.otherData[CONST.OTHER_DATA.CFG] = monsterCfg[mId]
        chaNode.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME] = monsterCfg[mId].BulletName
        chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] = roleType
        chaNode.otherData[CONST.OTHER_DATA.ITEM_ID] = mId
        chaNode.otherData[CONST.OTHER_DATA.CHARACTER_LEVEL] = monsterCfg[mId].Level
    end
    chaNode.battleData[CONST.BATTLE_DATA.MAX_HP] = monsterCfg[mId].Hp
    chaNode.battleData[CONST.BATTLE_DATA.HP] = chaNode.battleData[CONST.BATTLE_DATA.MAX_HP]
    chaNode.battleData[CONST.BATTLE_DATA.PRE_HP] = chaNode.battleData[CONST.BATTLE_DATA.MAX_HP]
    chaNode.battleData[CONST.BATTLE_DATA.MP] = 0
    chaNode.battleData[CONST.BATTLE_DATA.PRE_MP] = 0
    chaNode.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = 0
    chaNode.battleData[CONST.BATTLE_DATA.SHIELD] = 0
    local numNode = chaNode.heroNode.chaCCB:getVarNode("mNumNode")
    numNode:removeAllChildrenWithCleanup(true)
    chaNode.HIT_NUM_POOL = nil
    --
    local skillCfg = ConfigManager:getSkillCfg()
    local skills = common:split(monsterCfg[mId].Skills, ",")
    chaNode.skillData = {}
    for i = 1, #skills do
        local skillId = tonumber(skills[i])
        if skillCfg[skillId] then
            local skillType = skillCfg[skillId].skillType or NewBattleConst.SKILL_DATA.PASSIVE
            chaNode.skillData[skillType] = chaNode.skillData[skillType] or { }
            local skillBaseId = math.floor(skillId / 10)
            local skillLevel = skillId % 10
            table.insert(chaNode.skillData[skillType], skillId, 
                         { ["COUNT"] = 0, ["CD"] = 0, ["ACTION"] = skillCfg[tonumber(skills[i])].actionName,
                           ["TIMER"] = 0, ["LEVEL"] = skillLevel,  })
        end
    end
    --
    self:setHp(chaNode, chaNode.battleData[NewBattleConst.BATTLE_DATA.HP], true)
    self:setMp(chaNode, chaNode.battleData[NewBattleConst.BATTLE_DATA.MP])
    NodeHelper:setNodeVisible(chaNode.heroNode.chaCCB:getVarNode("mHpmpbar"), NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK)
    chaNode.atkCD = 9999
end


--���񱼸������ʵe
function NgBattleCharacterUtil:playAwardAction(chaNode)
    local parentNode = chaNode.heroNode.chaCCB:getVarNode("mGoldNode")
    parentNode:removeAllChildrenWithCleanup(true)
    local rewardCount = math.random(3, 5)   --�Q�X���������ƶq
    -- �]�w�ɶ��t
    local timeOffset = { 0, 5, 10, 15, 20 }
    for i = 1, rewardCount do
        local randIdx = math.random(1, rewardCount)
        local temp = timeOffset[i]
        timeOffset[i] = timeOffset[randIdx]
        timeOffset[randIdx] = temp
    end
    -- �]�w���y�����t�X
    for i = 1, rewardCount do
        local parentNode = chaNode.heroNode.chaCCB:getVarNode("mGoldNode")
        local goldSpine = nil
        local spinePath, spineName = unpack(common:split(NewBattleConst.SceneSpinePath["Gold"], ","))
        goldSpine = SpineContainer:create(spinePath, spineName)
        
        local goldNode = tolua.cast(goldSpine, "CCNode")
        local fixScale = i % 2 == 0 and -1 or 1
        goldNode:setScaleX(fixScale)
        goldNode:setVisible(false)
        parentNode:addChild(goldNode)
        if goldSpine then
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(timeOffset[i] / 30))
            array:addObject(CCCallFunc:create(function()
                local goldNode = tolua.cast(goldSpine, "CCNode")
                goldNode:setVisible(true)
                goldSpine:runAnimation(1, "animation0" .. i, 0)
                goldSpine:setAttachmentForLua("G_2_5", "gold0" .. math.random(1, 5))
            end))
            array:addObject(CCDelayTime:create(34 / 30))
            local offsetX, offsetY = unpack(common:split(NewBattleConst.AfkDropOffset[i], ","))
            local posX = 20 - parentNode:getPositionX() - chaNode.heroNode.chaCCB:getPositionX() + tonumber(offsetX) * fixScale * -1
            local posY = -100 - parentNode:getPositionY() - chaNode.heroNode.chaCCB:getPositionY() + tonumber(offsetY) * -1
            if timeOffset[i] == 0 then
                array:addObject(CCCallFunc:create(function()
                    NgBattlePageInfo_playTreasureAni("animation01")
                end))
            end
            array:addObject(CCJumpTo:create(7 / 30, ccp(posX, posY), 50, 1))
            array:addObject(CCDelayTime:create((13 / 30) + (math.ceil(rewardCount * 0.5) / 3)))

            goldNode:runAction(CCSequence:create(array))
        end
    end
end
---------

return NgBattleCharacterUtil