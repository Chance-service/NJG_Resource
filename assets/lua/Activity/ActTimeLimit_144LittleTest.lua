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
--活動相關參數
local LITTLE_TEST_PARAS = {
    MAX_LEVEL = 10,
    ANSWER_NUM = 4,
    RANDOM_COUNT = 10,
    INIT = true,
}
--協定相關參數
local REQUEST_TYPE = {
    SYNC = 0, -- 0.同步
    ANSWER = 1, -- 1.回答
    RESULT = 2, -- 2.結算
    REWARD = 3, -- 3.領獎
    START = 4, -- 4.開局
    CLEAR = 5, -- 5.[測試功能]清空數據
}
--遊戲狀態參數
local GAME_STATE = {
    START_PAGE = 0,
    SELECTING_ANSWER = 1,
    FINAL_PAGE = 2,
    TEAMINFO_PAGE = 3,
    FIGHTING = 4,
}
--玩家當前遊戲資料
local nowData = {
    level = 0, -- 當前題數
    nowQuestion = 0, -- 當前題目
    nextQuestion = 0, -- 下一個題目
    trueQuestion = 0, -- 答對題數
    reward = "", -- 結算獎勵
    score = "", -- 結算分數
    selectAnswer = 0, -- 玩家回答
}
--玩家隊伍資料
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
--增益減益資料
local buffInfo = {
    id = 0,
    buffId = 0,
    value = 0,
    round = 0,
}
--當回合觸發技能
local nowBuffInfo = {
    id = 0,
    buffId = 0,
    value = 0,  --影響數值(ex.補血量)
    round = 0,
}
--BuffIcon資料
local buffIconInfo = {
}
--Boss資料
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
local answerStrList = {}    -- 選項顯示順序
local answerIndexList = { 1, 2, 3, 4 }  -- 選項實際index
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
-------------------------------------按鈕---------------------------------------------
--關閉UI
function ActTimeLimit_144LittleTest:onClose(container)
    PageManager.popPage(thisPageName)
end
--開始遊戲
function ActTimeLimit_144LittleTest:onStart(container)
    if nowState ~= GAME_STATE.START_PAGE then
        return
    end   
    if playerTeamInfo.id[1] <= 0 and playerTeamInfo.id[2] <= 0 and playerTeamInfo.id[3] <= 0 then
        --TODO 提示視窗
        return
    end
    ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.START, 0, playerTeamInfo.id)
    self:setGameState(container, GAME_STATE.SELECTING_ANSWER)
end
--規則說明
function ActTimeLimit_144LittleTest:onRule(container)
    ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.CLEAR, 0, {})
	--PageManager.showHelp(GameConfig.HelpKey.HELP_LITTLE_TEST)
end
--點答案
function ActTimeLimit_144LittleTest:onAnswer(container, eventName)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL or nowData.level <= 0 then
        return
    end
    nowData.selectAnswer = tonumber(string.sub(eventName, -1))
    ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.ANSWER, answerIndexList[nowData.selectAnswer], {})
    self:setGameState(container, GAME_STATE.PLAYING_ANI)
end
--領獎
function ActTimeLimit_144LittleTest:onReward(container)
    if #nowData.reward <= 0 then
        return
    end
    ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.REWARD, 0, {})    
end
--選擇角色(編隊)
function ActTimeLimit_144LittleTest:onSelectRole(container, eventName)
    --開啟編隊介面
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
--隊伍資料計算
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
--Boss初始化
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
--題目初始化
function ActTimeLimit_144LittleTest:initQuestion(container)
    if nowData.level <= LITTLE_TEST_PARAS.MAX_LEVEL then
        NodeHelper:setStringForLabel(container, { ["mQuestionTxt"] = common:getLanguageString("@littleTest" .. GameUtil:formatFixedLenNumber(nowData.nowQuestion, 3)  .. "00" ) })
    end
end
--答案選項初始化
function ActTimeLimit_144LittleTest:initAnswer(container)
    self:randomAnswerIndex(container)
    for i = 1, LITTLE_TEST_PARAS.ANSWER_NUM do
        answerStrList[i] = common:getLanguageString("@littleTest" .. GameUtil:formatFixedLenNumber(nowData.nowQuestion, 3)  .. GameUtil:formatFixedLenNumber(answerIndexList[i], 2))
        NodeHelper:setStringForLabel(container, { ["mAnswerTxt" .. i] = answerStrList[i] })
    end
end
--答案選項隨機排序
function ActTimeLimit_144LittleTest:randomAnswerIndex(container)
    for i = 1, LITTLE_TEST_PARAS.RANDOM_COUNT do
        local rIndex1 = math.random(1, LITTLE_TEST_PARAS.ANSWER_NUM)
        local rIndex2 = math.random(1, LITTLE_TEST_PARAS.ANSWER_NUM)
        local temp = answerIndexList[rIndex1]
        answerIndexList[rIndex1] = answerIndexList[rIndex2]
        answerIndexList[rIndex2] = temp
    end
end
--清除全部Buff資料
function ActTimeLimit_144LittleTest:clearAllBuffInfo(container)
    playerTeamInfo.buff = {}
    playerTeamInfo.nowBuff = {}
    bossInfo.buff = {}
    bossInfo.nowBuff = {}
end
--同步資料
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
    if msg.level ~= 0 then  --已開始遊戲->接server的隊伍資料(未開始時使用本地編隊資料)
        if msg.TeamInfo then
            --紀錄上一回合狀態
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
            --紀錄上一回合狀態
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
--設定結算顯示
function ActTimeLimit_144LittleTest:initFinalPage(container)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL then
        NodeHelper:setStringForLabel(container, { ["mFinalScoreTxt1"] = common:getLanguageString("@LTScore1", nowData.score), ["mFinalScoreTxt2"] = common:getLanguageString("@LTScore2", nowData.trueQuestion), ["mFinalScoreTxt6"] = levelRange[nowData.trueQuestion] })
    end
end
--刷新UI顯示
function ActTimeLimit_144LittleTest:refreshPage(container)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL then  -- 已完成作答
        self:initFinalPage(container)
        NodeHelper:setNodesVisible(container, { mStartPageNode = false, mContentPageNode = false, mFinalPageNode = true })
    elseif nowData.level <= 0 then   -- 未開始作答
        NodeHelper:setNodesVisible(container, { mStartPageNode = true, mContentPageNode = false, mFinalPageNode = false })
    else    -- 作答中
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
--設定狀態
function ActTimeLimit_144LittleTest:setGameState(container, state)
    nowState = state
end
--刷新當前題數文字
function ActTimeLimit_144LittleTest:refreshRoundTxt(container)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL then
        NodeHelper:setStringForLabel(container, { mLevelTxt = LITTLE_TEST_PARAS.MAX_LEVEL .. "/" .. LITTLE_TEST_PARAS.MAX_LEVEL })
    else
        NodeHelper:setStringForLabel(container, { mLevelTxt = nowData.level .. "/" .. LITTLE_TEST_PARAS.MAX_LEVEL })
    end
end
--刷新領獎按鈕
function ActTimeLimit_144LittleTest:refreshRewardBtn(container)
    if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL and nowData.reward ~= "" then
        NodeHelper:setNodesVisible(container, { mRewardBtn = true })
    else
        NodeHelper:setNodesVisible(container, { mRewardBtn = false })
    end
end
--刷新角色頭像
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
--刷新角色戰力
function ActTimeLimit_144LittleTest:refreshBattleInfo(container)
    container:getVarLabelBMFont("mHp"):setString(playerTeamInfo.maxHp)
    container:getVarLabelBMFont("mAtk"):setString(playerTeamInfo.attack)
    container:getVarLabelBMFont("mSpd"):setString(playerTeamInfo.speed)
end
--刷新玩家血量
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
--刷新Boss血量
function ActTimeLimit_144LittleTest:refreshBossHp(container, targetHp)
    if targetHp then
        container:getVarSprite("mBossHpBar"):setScaleX(targetHp / bossInfo.maxHp)
        container:getVarLabelTTF("mBossHpTxt"):setString(targetHp .. "/" .. bossInfo.maxHp)
    else
        container:getVarSprite("mBossHpBar"):setScaleX(bossInfo.nowHp / bossInfo.maxHp)
        container:getVarLabelTTF("mBossHpTxt"):setString(bossInfo.nowHp .. "/" .. bossInfo.maxHp)
    end
end
--刷新Buff(技能觸發時)
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
--刷新全部Buff(同步資料or回合結束時)
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
--跳出最終獎勵
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
--接收編隊回傳
function ActTimeLimit_144LittleTest:setPlayerInfo(ids)
    for i = 1, 3 do
        playerTeamInfo.id[i] = ids[i]
    end
    self:calTeamInfo(ActTimeLimit_144LittleTest.container)
    self:refreshRoleHead(ActTimeLimit_144LittleTest.container)
    self:refreshBattleInfo(ActTimeLimit_144LittleTest.container)
end
--讀取本地編隊紀錄
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

-------------------------------------戰鬥相關--------------------------------------
-- TODO
function ActTimeLimit_144LittleTest:doFight(container)
    --[[玩家死亡後直接進入結算畫面 BOSS死亡不影響玩家技能演出 下一回合才會切換BOSS]]--
    --已知當前狀態&回合結束後狀態
    --根據速度判斷玩家orBoss先攻(相等時玩家先攻)
    --檢查觸發技能
    --SF=0 > 回合開始時演出(刷新buff icon, 雙方血量資訊)
    local fightAction = CCArray:create()
    self:addBuffAction(container, fightAction, playerTeamInfo, 0)
    self:addBuffAction(container, fightAction, bossInfo, 0)
    --檢查先攻是否存活
    --SF=1 > 先攻攻擊前演出(刷新buff icon, 雙方血量資訊)
    --檢查雙方是否存活
    -------------先攻攻擊(刷新雙方血量資訊)
    --檢查雙方是否存活
    --SF=2 > 先攻攻擊後演出(刷新buff icon, 雙方血量資訊)
    --檢查雙方是否存活
    --(先攻回血演出 id=4)
    --SF=1 > 後攻攻擊前演出(刷新buff icon, 雙方血量資訊)
    --檢查雙方是否存活
    -------------後攻攻擊(刷新雙方血量資訊)
    --檢查雙方是否存活
    --SF=2 > 後攻攻擊後演出(刷新buff icon, 雙方血量資訊)
    --檢查雙方是否存活
    --(後攻回血演出 id=4)
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
    --SF=3 > 回合開始後演出(刷新buff icon, 雙方血量資訊)
    --(雙方HOT回血演出 id=?)
    --刷新buff icon
    self:addBuffAction(container, fightAction, playerTeamInfo, 3)
    self:addBuffAction(container, fightAction, bossInfo, 3)
    container:getVarNode("mSpineNode"):runAction(CCSequence:create(fightAction))
end
--增加Buff演出Action
function ActTimeLimit_144LittleTest:addBuffAction(container, action, info, SF)
    if #info.skillSF[SF] > 0 then
        for i = 1, #info.skillSF[SF] do
            for nowIdx = 1, #info.nowBuff do
                if info.nowBuff[nowIdx].id == info.skillSF[SF][i] then --檢查SF0的角色是否觸發技能
                    -- TODO 技能發動演出動畫
                    action:addObject(CCDelayTime:create(0.5))
                    break
                end
            end
        end
        for i = 1, #info.skillSF[SF] do
            for nowIdx = 1, #info.nowBuff do
                if info.nowBuff[nowIdx].id == info.skillSF[SF][i] then --檢查SF0的角色是否觸發技能
                    -- TODO BUFF刷新演出動畫
                    action:addObject(CCDelayTime:create(0.3))
                    -- 刷新BUFF
                    action:addObject(CCCallFunc:create(refreshBuff(container, info.nowBuff[nowIdx].id, info.nowBuff[nowIdx].buffId)))
                end
            end
        end
    end
end
--增加攻擊演出Action
function ActTimeLimit_144LittleTest:addAttackAction(container, action, isPlayer)
    local dmg = self:calDamage(container, not isPlayer)
    action:addObject(CCDelayTime:create(0.5))
    if isPlayer then
        -- TODO 玩家攻擊動畫
        action:addObject(CCCallFunc:create(self:refreshPlayerHp(container, bossInfo.nowHp - dmg)))
        boss.nowHp = boss.nextHp
    else
        --TODO BOSS攻擊動畫
        action:addObject(CCCallFunc:create(self:refreshPlayerHp(container, playerTeamInfo.nowHp - dmg)))
        playerTeamInfo.nowHp = playerTeamInfo.nextHp
    end
    action:addObject(CCCallFunc:create(refreshBuff(container, info.nowBuff[nowIdx].id, info.nowBuff[nowIdx].buffId)))
end
--計算承受傷害
function ActTimeLimit_144LittleTest:calDamage(container, isPlayer)
    local dmg = 0
    if isPlayer then
        dmg = playerTeamInfo.diffHp
        for i = 1, #playerTeamInfo.nowBuff do
            if playerTeamInfo.nowBuff[i].buffId == 4 then   --回血
                dmg = dmg - playerTeamInfo.nowBuff[i].value
            end
        end
    else
        dmg = bossInfo.diffHp
        for i = 1, #bossInfo.nowBuff do
            if bossInfo.nowBuff[i].buffId == 4 then   --回血
                dmg = dmg - bossInfo.nowBuff[i].value
            end
        end
    end
    return dmg
end
----------------------------------------------------------------------------------

-------------------------------------協定相關--------------------------------------
function ActTimeLimit_144LittleTest:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ACTIVITY144_S then
        local msg = Activity3_pb.Activity144Little_testRep()
        msg:ParseFromString(msgBuff) 
        if msg.type == REQUEST_TYPE.REWARD then -- 先跳獎勵,同步資料後會清除
            self:popAllReward(container)
        end
        self:syncServerData(msg, msgType)
        if msg.type == REQUEST_TYPE.ANSWER then
            if nowData.level > LITTLE_TEST_PARAS.MAX_LEVEL then
                ActTimeLimit_144LittleTest:requestServerData(REQUEST_TYPE.RESULT, 0, {})   -- 回答完題目要結算
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