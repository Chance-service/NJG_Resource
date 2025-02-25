local thisPageName = "ActTimeLimit_144LittleTest" --"ActTimeLimit_144"
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local ConfigManager = require("ConfigManager")
local UserItemManager = require("Item.UserItemManager")
local UserMercenaryManager = require("UserMercenaryManager")
require("Activity.ActivityInfo")

local ActTimeLimit_144LittleTest = {
    container = nil
}
--���ʬ����Ѽ�
local LITTLE_TEST_PARAS = {
    MAX_LEVEL = 10,
    ANSWER_NUM = 4,
    RANDOM_COUNT = 10,
    INIT = true,
}
--��w�����Ѽ�
local REQUEST_TYPE = {
    SYNC = 0, -- 0.�P�B
    ANSWER = 1, -- 1.�^��
    RESULT = 2, -- 2.����
    REWARD = 3, -- 3.���
    START = 4, -- 4.�}��
    CLEAR = 5, -- 5.[���ե\��]�M�żƾ�
}
--�C�����A�Ѽ�
local GAME_STATE = {
    START_PAGE = 0,
    SELECTING_ANSWER = 1,
    FINAL_PAGE = 2,
    TEAMINFO_PAGE = 3,
    FIGHTING = 4,
}
--���a��e�C�����
local nowData = {
    level = 0, -- ��e�D��
    nowQuestion = 0, -- ��e�D��
    nextQuestion = 0, -- �U�@���D��
    trueQuestion = 0, -- �����D��
    reward = "", -- ������y
    score = "", -- �������
    selectAnswer = 0, -- ���a�^��
}
--���a������
local playerTeamInfo = {
    id = { [1] = 0, [2] = 0, [3] = 0 },
    nowHp = 0,
    maxHp = 0,
    attack = 0,
    speed = 0,
    buff = {},
    nowBuff = {},
    skillSF = { [0] = {}, [1] = {}, [2] = {}, [3] = {} },
    damage = 0,
}
--�W�q��q���
local buffInfo = {
    id = 0,
    buffId = 0,
    value = 0,
    round = 0,
}
--��^�XĲ�o�ޯ�
local nowBuffInfo = {
    id = 0,
    buffId = 0,
    value = 0,  --�v�T�ƭ�(ex.�ɦ�q)
    round = 0,
}
--BuffIcon���
local buffIconInfo = {
}
--Boss���
local bossInfo = {
    id = 0,
    nowHp = 0,
    maxHp = 0,
    speed = 0,
    buff = {},
    nowBuff = {},
    skillSF = { [0] = {}, [1] = {}, [2] = {}, [3] = {} },
    damage = 0,
    isDead = false,
}
local option = {
    ccbiFile = "Act_TimeLimit_144Page.ccbi",
    handlerMap = {
        onClose = "onClose",
        onStart = "onStart",
        onHelp = "onRule",
        --Final
        onReward = "onReward",
    },
    opcodes = {
        ACTIVITY144_C = HP_pb.ACTIVITY144_C,
        ACTIVITY144_S = HP_pb.ACTIVITY144_S,
    }
}
for i = 1, 4 do
    option.handlerMap["onAnswer" .. i] = "onAnswer"
end
for i = 1, 3 do
    option.handlerMap["onSelectRole" .. i] = "onSelectRole"
end

local nowState = GAME_STATE.START_PAGE
local answerStrList = {}    -- �ﶵ��ܶ���
local answerIndexList = { 1, 2, 3, 4 }  -- �ﶵ���index
local levelRange = { [0] = "F", [1] = "E", [2] = "E", [3] = "D", [4] = "D", [5] = "C", 
                     [6] = "C", [7] = "B", [8] = "B", [9] = "A", [10] = "S" }
local mSpineNode = nil
local roleCfg = ConfigManager:getRoleCfg()
local ltRoleCfg = ConfigManager:getLTRoleCfg()
local ltSkillCfg = ConfigManager:getLTSkillCfg()

local preTeamInfo = nil
local preBossInfo = nil

--TEST
local testIndex = 1

--------------------------------------------------------------------------------------
function ActTimeLimit_144LittleTest:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function ActTimeLimit_144LittleTest:onEnter(container)
    ActTimeLimit_144LittleTest.container = container
    math.randomseed(os.time())
    nowData.selectAnswer = 0
    buffIconInfo = {}
    LITTLE_TEST_PARAS.INIT = true
    self:registerPacket(container)
    self:initBoss(container)
    self:calTeamInfo(container)
    self:requestServerData(REQUEST_TYPE.SYNC, 0, {})
    NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = false, mFinalPageNode = false })
    self:setGameState(container, GAME_STATE.START_PAGE)
    self:loadLocalTeamInfo(container)
end
-------------------------------------���s---------------------------------------------
--����UI
function ActTimeLimit_144LittleTest:onClose(container)
    PageManager.popPage(thisPageName)
end
--�}�l�C��
function ActTimeLimit_144LittleTest:onStart(container)
    if nowState ~= GAME_STATE.START_PAGE then
        return
    end   
    if playerTeamInfo.id[1] <= 0 and playerTeamInfo.id[2] <= 0 and playerTeamInfo.id[3] <= 0 then
        --TODO ���ܵ���
        return
    end
    ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.START, 0, playerTeamInfo.id)
    self:setGameState(container, GAME_STATE.SELECTING_ANSWER)
end
--�W�h����
function ActTimeLimit_144LittleTest:onRule(container)
    ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.CLEAR, 0, {})
	--PageManager.showHelp(GameConfig.HelpKey.HELP_LITTLE_TEST)
end
--�I����
function ActTimeLimit_144LittleTest:onAnswer(container, eventName)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL or nowData.level <= 0 then
        return
    end
    nowData.selectAnswer = tonumber(string.sub(eventName, -1))
    ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.ANSWER, answerIndexList[nowData.selectAnswer], {})
    self:setGameState(container, GAME_STATE.PLAYING_ANI)
end
--���
function ActTimeLimit_144LittleTest:onReward(container)
    if #nowData.reward <= 0 then
        return
    end
    ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.REWARD, 0, {})    
end
--��ܨ���(�s��)
function ActTimeLimit_144LittleTest:onSelectRole(container, eventName)
    --�}�ҽs������
    local editPage = require("ActTimeLimit_144EditTeam")
    local ids = {}
    for i = 1, 3 do
        table.insert(ids, playerTeamInfo.id[i])
        playerTeamInfo.id[i] = ids[i]
    end
    editPage:setTeamIds(ids)
    PageManager.pushPage("ActTimeLimit_144EditTeam")
end
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--�����ƭp��
function ActTimeLimit_144LittleTest:calTeamInfo(container)
    playerTeamInfo.maxHp = 0
    playerTeamInfo.attack = 0
    playerTeamInfo.speed = 0
    for i = 1, #playerTeamInfo.id do
        local roleId = playerTeamInfo.id[i]
        if ltRoleCfg[roleId] and ltSkillCfg[ltRoleCfg[roleId].SkillID] then
            playerTeamInfo.maxHp = playerTeamInfo.maxHp + ltRoleCfg[roleId].HP
            playerTeamInfo.attack = playerTeamInfo.attack + ltRoleCfg[roleId].ATK
            playerTeamInfo.speed = playerTeamInfo.speed + ltRoleCfg[roleId].Speed
            table.insert(playerTeamInfo.skillSF[ltSkillCfg[ltRoleCfg[roleId].SkillID].SF], roleId)
        end
    end
end
--Boss��l��
function ActTimeLimit_144LittleTest:initBoss(container)
    local ltCfg = ltRoleCfg[bossInfo.id]
    if ltCfg then
        mSpineNode = container:getVarNode("mSpineNode")
        local spinePath, spineName = unpack(common:split((ltCfg.Spine), ","))
        local bossSpine = SpineContainer:create(spinePath, spineName, 1)
        local bossSpineNode = tolua.cast(bossSpine, "CCNode")
        mSpineNode:removeAllChildren()
        mSpineNode:addChild(bossSpineNode)
        bossSpine:runAnimation(1, "Stand", -1)
    end
end
--�D�ت�l��
function ActTimeLimit_144LittleTest:initQuestion(container)
    if nowData.level <= LITTLE_TEST_PARAS.MAX_LEVEL then
        NodeHelper:setStringForLabel(container, { ["mQuestionTxt"] = common:getLanguageString("@littleTest" .. GameUtil:formatFixedLenNumber(nowData.nowQuestion, 3)  .. "00" ) })
    end
end
--���׿ﶵ��l��
function ActTimeLimit_144LittleTest:initAnswer(container)
    self:randomAnswerIndex(container)
    for i = 1, LITTLE_TEST_PARAS.ANSWER_NUM do
        answerStrList[i] = common:getLanguageString("@littleTest" .. GameUtil:formatFixedLenNumber(nowData.nowQuestion, 3)  .. GameUtil:formatFixedLenNumber(answerIndexList[i], 2))
        NodeHelper:setStringForLabel(container, { ["mAnswerTxt" .. i] = answerStrList[i] })
    end
end
--���׿ﶵ�H���Ƨ�
function ActTimeLimit_144LittleTest:randomAnswerIndex(container)
    for i = 1, LITTLE_TEST_PARAS.RANDOM_COUNT do
        local rIndex1 = math.random(1, LITTLE_TEST_PARAS.ANSWER_NUM)
        local rIndex2 = math.random(1, LITTLE_TEST_PARAS.ANSWER_NUM)
        local temp = answerIndexList[rIndex1]
        answerIndexList[rIndex1] = answerIndexList[rIndex2]
        answerIndexList[rIndex2] = temp
    end
end
--�M������Buff���
function ActTimeLimit_144LittleTest:clearAllBuffInfo(container)
    playerTeamInfo.buff = {}
    playerTeamInfo.nowBuff = {}
    bossInfo.buff = {}
    bossInfo.nowBuff = {}
end
--�P�B���
function ActTimeLimit_144LittleTest:syncServerData(msg, msgType)
    self:clearAllBuffInfo(container)
    nowData.level = msg.level
    nowData.trueQuestion = msg.binbom
    nowData.nowQuestion = msg.queid
    nowData.nextQuestion = msg.nextid
    nowData.score = msg.score
    if not nowData.score then
        nowData.score = 0
    end
    nowData.reward = msg.reward
    if not nowData.reward then
        nowData.reward = ""
    end
    if msg.level ~= 0 then  --�w�}�l�C��->��server��������(���}�l�ɨϥΥ��a�s�����)
        if msg.TeamInfo then
            --�����W�@�^�X���A
            preTeamInfo = playerTeamInfo
            --
            for i = 1, #msg.TeamInfo.Roleid do
                playerTeamInfo.id[i] = msg.TeamInfo.Roleid[i]
                if LITTLE_TEST_PARAS.INIT then
                    table.insert(playerTeamInfo.skillSF[ltSkillCfg[ltRoleCfg[playerTeamInfo.id[i]].SkillID].SF], playerTeamInfo.id[i])
                end
            end
            playerTeamInfo.nowHp = msg.TeamInfo.NowHp
            playerTeamInfo.damage = msg.TeamInfo.damage
            playerTeamInfo.maxHp = msg.TeamInfo.MaxHp
            playerTeamInfo.speed = msg.TeamInfo.TeamSpeed   
            for i = 1, #msg.TeamInfo.Buff do
                buffInfo.id = msg.TeamInfo.Buff[i].userid
                buffInfo.buffId = msg.TeamInfo.Buff[i].buffid
                buffInfo.value = msg.TeamInfo.Buff[i].value
                buffInfo.round = msg.TeamInfo.Buff[i].times
                playerTeamInfo.buff[i] = buffInfo
            end
            for i = 1, #msg.TeamInfo.NowBuff do
                nowBuffInfo.id = msg.TeamInfo.NowBuff[i].userid
                nowBuffInfo.buffId = msg.TeamInfo.NowBuff[i].buffid
                nowBuffInfo.value = msg.TeamInfo.NowBuff[i].value
                nowBuffInfo.round = msg.TeamInfo.NowBuff[i].times
                playerTeamInfo.nowBuff[i] = nowBuffInfo
            end
        end
        if msg.BossInfo then
            --�����W�@�^�X���A
            preBossInfo = bossInfo
            --
            bossInfo.id = msg.BossInfo.Bossid
            if LITTLE_TEST_PARAS.INIT then
                table.insert(bossInfo.skillSF[ltSkillCfg[ltRoleCfg[bossInfo.id].SkillID].SF], bossInfo.id)
            end
            bossInfo.nowHp = msg.BossInfo.BossNowHp
            bossInfo.damage = msg.BossInfo.damage
            bossInfo.maxHp = msg.BossInfo.BossMaxHp
            bossInfo.speed = msg.BossInfo.BossSpeed
            for i = 1, #msg.BossInfo.Buff do
                buffInfo.id = msg.BossInfo.Buff.userid
                buffInfo.buffId = msg.BossInfo.Buff.buffid
                buffInfo.value = msg.BossInfo.Buff.value
                buffInfo.round = msg.BossInfo.Buff.times
                bossInfo.buff[i] = buffInfo
            end
            for i = 1, #msg.BossInfo.NowBuff do
                nowBuffInfo.id = msg.BossInfo.NowBuff.userid
                nowBuffInfo.buffId = msg.BossInfo.NowBuff.buffid
                nowBuffInfo.value = msg.BossInfo.NowBuff.value
                nowBuffInfo.round = msg.BossInfo.NowBuff.times
                bossInfo.buff[i] = nowBuffInfo
            end
        end
        if LITTLE_TEST_PARAS.INIT then
            self:initBoss(ActTimeLimit_144LittleTest.container)
            self:refreshAllBuff(ActTimeLimit_144LittleTest.container, true)
            LITTLE_TEST_PARAS.INIT = false
        end
    end
end
--�]�w�������
function ActTimeLimit_144LittleTest:initFinalPage(container)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL then
        NodeHelper:setStringForLabel(container, { ["mFinalScoreTxt1"] = common:getLanguageString("@LTScore1", nowData.score), ["mFinalScoreTxt2"] = common:getLanguageString("@LTScore2", nowData.trueQuestion), ["mFinalScoreTxt6"] = levelRange[nowData.trueQuestion] })
    end
end
--��sUI���
function ActTimeLimit_144LittleTest:refreshPage(container)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL then  -- �w�����@��
        self:initFinalPage(container)
        NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = false, mFinalPageNode = true })
    elseif nowData.level <= 0 then   -- ���}�l�@��
        NodeHelper:setNodesVisible(container, { mStartPageNode = true, mContentPageNode = false, mFinalPageNode = false })
    else    -- �@����
        NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = true, mFinalPageNode = false })
        self:initQuestion(container)
        self:initAnswer(container)
    end
    self:refreshRoundTxt(container)
    self:refreshRewardBtn(container)
    self:refreshRoleHead(container)
    self:refreshBattleInfo(container)
    self:refreshPlayerHp(container, false)
    self:refreshBossHp(container, false)
end
--�]�w���A
function ActTimeLimit_144LittleTest:setGameState(container, state)
    nowState = state
end
--��s��e�D�Ƥ�r
function ActTimeLimit_144LittleTest:refreshRoundTxt(container)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL then
        NodeHelper:setStringForLabel(container, { mLevelTxt = LITTLE_TEST_PARAS.MAX_LEVEL .. "/" .. LITTLE_TEST_PARAS.MAX_LEVEL })
    else
        NodeHelper:setStringForLabel(container, { mLevelTxt = nowData.level .. "/" .. LITTLE_TEST_PARAS.MAX_LEVEL })
    end
end
--��s������s
function ActTimeLimit_144LittleTest:refreshRewardBtn(container)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL and nowData.reward ~= "" then
        NodeHelper:setNodesVisible(container, { mRewardBtn = true })
    else
        NodeHelper:setNodesVisible(container, { mRewardBtn = false })
    end
end
--��s�����Y��
function ActTimeLimit_144LittleTest:refreshRoleHead(container)
    for i = 1, #playerTeamInfo.id do
        local cfg = roleCfg[playerTeamInfo.id[i]]
        local ltCfg = ltRoleCfg[playerTeamInfo.id[i]]
        if cfg and ltCfg then
            NodeHelper:setSpriteImage(container, { ["mRoleImg" .. i] = cfg.icon, ["mRoleColor" .. i] = GameConfig.QualityImage[cfg.quality] })
            NodeHelper:setImgBgQualityFrames(container, { ["mRoleBg" .. i] = GameConfig.QualityImageBG[cfg.quality] })
            NodeHelper:setSpriteImage(container, { ["mRoleType" .. i] = "Activity_144_job_" .. ltCfg.Type .. ".png" })
            NodeHelper:setSpriteImage(container, { ["mRoleImg" .. i .. "Content"] = cfg.icon, ["mRoleColor" .. i .. "Content"] = GameConfig.QualityImage[cfg.quality] })
            NodeHelper:setImgBgQualityFrames(container, { ["mRoleBg" .. i .. "Content"] = GameConfig.QualityImageBG[cfg.quality] })
            NodeHelper:setSpriteImage(container, { ["mRoleType" .. i .. "Content"] = "Activity_144_job_" .. ltCfg.Type .. ".png" })
            NodeHelper:setSpriteImage(container, { ["mRoleImg" .. i .. "Reward"] = cfg.icon, ["mRoleColor" .. i .. "Reward"] = GameConfig.QualityImage[cfg.quality] })
            NodeHelper:setImgBgQualityFrames(container, { ["mRoleBg" .. i .. "Reward"] = GameConfig.QualityImageBG[cfg.quality] })
            NodeHelper:setSpriteImage(container, { ["mRoleType" .. i .. "Reward"] = "Activity_144_job_" .. ltCfg.Type .. ".png" })
        else
            NodeHelper:setSpriteImage(container, { ["mRoleImg" .. i] = "UI/Mask/Image_Empty.png", ["mRoleColor" .. i] = GameConfig.QualityImage[1] })
            NodeHelper:setImgBgQualityFrames(container, { ["mRoleBg" .. i] = GameConfig.QualityImageBG[1] })
            NodeHelper:setSpriteImage(container, { ["mRoleType" .. i] = "UI/Mask/Image_Empty.png" })
            NodeHelper:setSpriteImage(container, { ["mRoleImg" .. i .. "Content"] = "UI/Mask/Image_Empty.png", ["mRoleColor" .. i .. "Content"] = GameConfig.QualityImage[1] })
            NodeHelper:setImgBgQualityFrames(container, { ["mRoleBg" .. i .. "Content"] = GameConfig.QualityImageBG[1] })
            NodeHelper:setSpriteImage(container, { ["mRoleType" .. i .. "Content"] = "UI/Mask/Image_Empty.png" })
            NodeHelper:setSpriteImage(container, { ["mRoleImg" .. i .. "Reward"] = "UI/Mask/Image_Empty.png", ["mRoleColor" .. i .. "Reward"] = GameConfig.QualityImage[1] })
            NodeHelper:setImgBgQualityFrames(container, { ["mRoleBg" .. i .. "Reward"] = GameConfig.QualityImageBG[1] })
            NodeHelper:setSpriteImage(container, { ["mRoleType" .. i .. "Reward"] = "UI/Mask/Image_Empty.png" })
        end
    end
end
--��s����ԤO
function ActTimeLimit_144LittleTest:refreshBattleInfo(container)
    container:getVarLabelBMFont("mHp"):setString(playerTeamInfo.maxHp)
    container:getVarLabelBMFont("mAtk"):setString(playerTeamInfo.attack)
    container:getVarLabelBMFont("mSpd"):setString(playerTeamInfo.speed)
end
--��s���a��q
function ActTimeLimit_144LittleTest:refreshPlayerHp(container, targetHp)
    local sprite = container:getVarScale9Sprite("mPlayerHpBar")
    if targetHp then
        sprite:setScaleX(targetHp / playerTeamInfo.maxHp)
        container:getVarLabelTTF("mPlayerHpTxt"):setString(targetHp .. "/" .. playerTeamInfo.maxHp)
    else 
        sprite:setScaleX(playerTeamInfo.nowHp / playerTeamInfo.maxHp)
        container:getVarLabelTTF("mPlayerHpTxt"):setString(playerTeamInfo.nowHp .. "/" .. playerTeamInfo.maxHp)
    end
end
--��sBoss��q
function ActTimeLimit_144LittleTest:refreshBossHp(container, targetHp)
    if targetHp then
        container:getVarSprite("mBossHpBar"):setScaleX(targetHp / bossInfo.maxHp)
        container:getVarLabelTTF("mBossHpTxt"):setString(targetHp .. "/" .. bossInfo.maxHp)
    else
        container:getVarSprite("mBossHpBar"):setScaleX(bossInfo.nowHp / bossInfo.maxHp)
        container:getVarLabelTTF("mBossHpTxt"):setString(bossInfo.nowHp .. "/" .. bossInfo.maxHp)
    end
end
--��sBuff(�ޯ�Ĳ�o��)
function refreshBuff(container, id, buffId)
    local isExist = false
    for i = 1, #buffIconInfo do
        if buffIconInfo[i].roleId == id and buffIconInfo[i].buffId == buffId then
            isExist = true
            break
        end
    end
    if not isExist then
        buffIconInfo[#buffIconInfo + 1] = { roleId = id, buffId = buffId }
    end
    ActTimeLimit_144LittleTest:sortBuff(container)
    ActTimeLimit_144LittleTest:refreshAllBuff(container, false)
end
function ActTimeLimit_144LittleTest:sortBuff(container)
    if #buffIconInfo > 0 then
        table.sort(buffIconInfo,
        function(d1, d2)
            return (d1.roleId < d2.roleId) or (d1.roleId == d2.roleId and d1.buffId < d2.buffId);
        end
        );
    end
end
--��s����Buff(�P�B���or�^�X������)
function ActTimeLimit_144LittleTest:refreshAllBuff(container, isClean)
    local targetBuff = buffIconInfo
    for i = 1, 3 do
        NodeHelper:setSpriteImage(container, { ["mBuff" .. i] = "UI/Mask/Image_Empty.png" })
    end
    if isClean then
        buffIconInfo = {}
        targetBuff = playerTeamInfo.buff
    end
    for i = 1, #targetBuff do
        if isClean then
            buffIconInfo[i] = { roleId = playerTeamInfo.buff[i].id, buffId = playerTeamInfo.buff[i].buffId }
        end
        if buffIconInfo[i].roleId < 500 then
            if buffIconInfo[i].buffId < 100 then
                NodeHelper:setSpriteImage(container, { ["mBuff" .. i] = "Activity_144_buff_" .. buffIconInfo[i].buffId .. ".png" })
            else
                NodeHelper:setSpriteImage(container, { ["mDebuff" .. i] = "Activity_144_debuff_" .. buffIconInfo[i].buffId .. ".png" })
            end
        end
    end
    if isClean then
        for i = 1, #bossInfo.buff do
            buffIconInfo[i + #buffIconInfo] = { roleId = bossInfo.buff[i].id, buffId = bossInfo.buff[i].buffId }
            if buffIconInfo[i + #buffIconInfo].roleId >= 500 then
                if buffIconInfo[i + #buffIconInfo].buffId < 100 then
                    NodeHelper:setSpriteImage(container, { ["mBossBuff" .. i] = "Activity_144_buff_" .. buffIconInfo[i + #buffIconInfo].buffId .. ".png" })
                else
                    NodeHelper:setSpriteImage(container, { ["mBossDebuff" .. i] = "Activity_144_debuff_" .. buffIconInfo[i + #buffIconInfo].buffId .. ".png" })
                end
            end
        end
    end
end
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--���X�̲׼��y
function ActTimeLimit_144LittleTest:popAllReward(container)
    if nowData.isFail then
        return
    end
    local rewardItems = {}
    local allReward = {}
    if nowData.reward then
        allReward = common:split(nowData.reward, ",")
    end
    for i = 1, #allReward do
        local _type, _id, _count = unpack(common:split(allReward[i], "_"))
        table.insert(rewardItems, {
                type    = tonumber(_type),
                itemId  = tonumber(_id),
                count   = tonumber(_count),
        })
    end
    local CommonRewardPage = require("CommonRewardPage")
    CommonRewardPageBase_setPageParm(rewardItems, true)
    PageManager.pushPage("CommonRewardPage")
end
--�����s���^��
function ActTimeLimit_144LittleTest:setPlayerInfo(ids)
    for i = 1, 3 do
        playerTeamInfo.id[i] = ids[i]
    end
    self:calTeamInfo(ActTimeLimit_144LittleTest.container)
    self:refreshRoleHead(ActTimeLimit_144LittleTest.container)
    self:refreshBattleInfo(ActTimeLimit_144LittleTest.container)
end
--Ū�����a�s������
function ActTimeLimit_144LittleTest:loadLocalTeamInfo(container)
    local ltInfoKey = "LT_TEAM_ID"
    local ltInfo = CCUserDefault:sharedUserDefault():getStringForKey(ltInfoKey)
    local ids = {}
    if ltInfo ~= "" then
        local info = common:split(ltInfo, "_")
        for i = 1, 3 do
            table.insert(ids, tonumber(info[i]))
        end
    else
        for i = 1, 3 do
            table.insert(ids, 0)
        end
    end
    ActTimeLimit_144LittleTest:setPlayerInfo(ids)
end
----------------------------------------------------------------------------------

-------------------------------------�԰�����--------------------------------------
-- TODO
function ActTimeLimit_144LittleTest:doFight(container)
    --[[���a���`�᪽���i�J����e�� BOSS���`���v�T���a�ޯ�t�X �U�@�^�X�~�|����BOSS]]--
    --�w����e���A&�^�X�����᪬�A
    --�ھڳt�קP�_���aorBoss����(�۵��ɪ��a����)
    --�ˬdĲ�o�ޯ�
    --SF=0 > �^�X�}�l�ɺt�X(��sbuff icon, �����q��T)
    local fightAction = CCArray:create()
    self:addBuffAction(container, fightAction, playerTeamInfo, 0)
    self:addBuffAction(container, fightAction, bossInfo, 0)
    --�ˬd����O�_�s��
    --SF=1 > ��������e�t�X(��sbuff icon, �����q��T)
    --�ˬd����O�_�s��
    -------------�������(��s�����q��T)
    --�ˬd����O�_�s��
    --SF=2 > ���������t�X(��sbuff icon, �����q��T)
    --�ˬd����O�_�s��
    --(����^��t�X id=4)
    --SF=1 > �������e�t�X(��sbuff icon, �����q��T)
    --�ˬd����O�_�s��
    -------------������(��s�����q��T)
    --�ˬd����O�_�s��
    --SF=2 > ��������t�X(��sbuff icon, �����q��T)
    --�ˬd����O�_�s��
    --(���^��t�X id=4)
    if playerTeamInfo.speed >= bossInfo.speed then
        self:addBuffAction(container, fightAction, playerTeamInfo, 1)
        self:addAttackAction(container, fightAction, true)
        self:addBuffAction(container, fightAction, playerTeamInfo, 2)
        self:addBuffAction(container, fightAction, bossInfo, 1)
        self:addAttackAction(container, fightAction, false)
        self:addBuffAction(container, fightAction, bossInfo, 2)
    else
        self:addBuffAction(container, fightAction, bossInfo, 1)
        self:addAttackAction(container, fightAction, false)
        self:addBuffAction(container, fightAction, bossInfo, 2)
        self:addBuffAction(container, fightAction, playerTeamInfo, 1)
        self:addAttackAction(container, fightAction, true)
        self:addBuffAction(container, fightAction, playerTeamInfo, 2)
    end
    --SF=3 > �^�X�}�l��t�X(��sbuff icon, �����q��T)
    --(����HOT�^��t�X id=?)
    --��sbuff icon
    self:addBuffAction(container, fightAction, playerTeamInfo, 3)
    self:addBuffAction(container, fightAction, bossInfo, 3)
    container:getVarNode("mSpineNode"):runAction(CCSequence:create(fightAction))
end
--�W�[Buff�t�XAction
function ActTimeLimit_144LittleTest:addBuffAction(container, action, info, SF)
    if #info.skillSF[SF] > 0 then
        for i = 1, #info.skillSF[SF] do
            for nowIdx = 1, #info.nowBuff do
                if info.nowBuff[nowIdx].id == info.skillSF[SF][i] then --�ˬdSF0������O�_Ĳ�o�ޯ�
                    -- TODO �ޯ�o�ʺt�X�ʵe
                    action:addObject(CCDelayTime:create(0.5))
                    break
                end
            end
        end
        for i = 1, #info.skillSF[SF] do
            for nowIdx = 1, #info.nowBuff do
                if info.nowBuff[nowIdx].id == info.skillSF[SF][i] then --�ˬdSF0������O�_Ĳ�o�ޯ�
                    -- TODO BUFF��s�t�X�ʵe
                    action:addObject(CCDelayTime:create(0.3))
                    -- ��sBUFF
                    action:addObject(CCCallFunc:create(refreshBuff(container, info.nowBuff[nowIdx].id, info.nowBuff[nowIdx].buffId)))
                end
            end
        end
    end
end
--�W�[�����t�XAction
function ActTimeLimit_144LittleTest:addAttackAction(container, action, isPlayer)
    local dmg = self:calDamage(container, not isPlayer)
    action:addObject(CCDelayTime:create(0.5))
    if isPlayer then
        -- TODO ���a�����ʵe
        action:addObject(CCCallFunc:create(self:refreshPlayerHp(container, bossInfo.nowHp - dmg)))
        boss.nowHp = boss.nextHp
    else
        --TODO BOSS�����ʵe
        action:addObject(CCCallFunc:create(self:refreshPlayerHp(container, playerTeamInfo.nowHp - dmg)))
        playerTeamInfo.nowHp = playerTeamInfo.nextHp
    end
    action:addObject(CCCallFunc:create(refreshBuff(container, info.nowBuff[nowIdx].id, info.nowBuff[nowIdx].buffId)))
end
--�p��Ө��ˮ`
function ActTimeLimit_144LittleTest:calDamage(container, isPlayer)
    local dmg = 0
    if isPlayer then
        dmg = playerTeamInfo.diffHp
        for i = 1, #playerTeamInfo.nowBuff do
            if playerTeamInfo.nowBuff[i].buffId == 4 then   --�^��
                dmg = dmg - playerTeamInfo.nowBuff[i].value
            end
        end
    else
        dmg = bossInfo.diffHp
        for i = 1, #bossInfo.nowBuff do
            if bossInfo.nowBuff[i].buffId == 4 then   --�^��
                dmg = dmg - bossInfo.nowBuff[i].value
            end
        end
    end
    return dmg
end
----------------------------------------------------------------------------------

-------------------------------------��w����--------------------------------------
function ActTimeLimit_144LittleTest:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ACTIVITY144_S then
        local msg = Activity3_pb.Activity144Little_testRep()
        msg:ParseFromString(msgBuff) 
        if msg.type == REQUEST_TYPE.REWARD then -- �������y,�P�B��ƫ�|�M��
            self:popAllReward(container)
        end
        self:syncServerData(msg, msgType)
        if msg.type == REQUEST_TYPE.ANSWER then
            if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL then
                ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.RESULT, 0, {})   -- �^�����D�حn����
            end
        end
        if msg.type == REQUEST_TYPE.CLEAR then
            self:calTeamInfo(container)
            self:setGameState(container, GAME_STATE.START_PAGE)
        end
        if msg.type ~= REQUEST_TYPE.ANSWER then
            self:refreshPage(container)
        else
            self:doFight(container)
        end
    end
end
function ActTimeLimit_144LittleTest:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function ActTimeLimit_144LittleTest:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function ActTimeLimit_144LittleTest:requestServerData(type, answer, roleId)
    local msg = Activity3_pb.Activity144Little_testReq()
    msg.type = type
    msg.Answers = answer
    for i = 1, #roleId do
        msg.Roleid:append(roleId[i])
    end
    common:sendPacket(option.opcodes.ACTIVITY144_C, msg, true)
end
----------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local ActPage = CommonPage.newSub(ActTimeLimit_144LittleTest, thisPageName, option)

return ActPage