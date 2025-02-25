

local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local thisPageName = "GuildBossPage"
local ConfigManager = require("ConfigManager")
local GuildDataManager = require("Guild.GuildDataManager")
local GuildData = require("Guild.GuildData")
local alliance = require('Alliance_pb')
local GuildBossPage = {
}

local option = {
    ccbiFile = "GuildBossIntrusionItem_1.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onInspireIntrusion = "onInspire",
        onContributionRankingIntrusion = "onContributionRanking",
        onOpenBossIntrusion = "openBoss",
        onAutoFight = "onAutoFight"
    },
}

local opcodes = {
    ALLIANCE_CREATE_S = HP_pb.ALLIANCE_CREATE_S,
    ALLIANCE_ENTER_S = HP_pb.ALLIANCE_ENTER_S,
    ALLIANCE_BOSSHARM_S = HP_pb.ALLIANCE_BOSSHARM_S
}
local mServerData = nil
local bossHitContainer = nil
function GuildBossPage:onEnter(container)
    self.container = container
    self:registerPacket(container)
    self:initUi(container)
    self:refreshPage(container)
end

function GuildBossPage:initData()

end

function GuildBossPage:initUi(container)
    bossHitContainer = ScriptContentBase:create('BattleNormalNum.ccbi')
    local bossAniNode = container:getVarNode('mPersonHitNumberNode')
    bossAniNode:addChild(bossHitContainer)
    bossHitContainer:release();
end


function GuildBossPage:getPageInfo(container)

end

function GuildBossPage:onAutoFight(container)
    -- 如果是开启状态，点击取消勾选
    if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.myInfo.autoFight == 1 then
        GuildData.GuildPage.sendAutoFightPacket(container)
    else
        local autoFightCost = VaribleManager:getInstance():getSetting("autoAllianceFightCost")
        local title = common:getLanguageString('@AllianceAutoFightTitle')
        local message = common:getLanguageString('@AllianceAutoFightDesc', autoFightCost)
        PageManager.showConfirm(title, message,
        function(agree)
            if agree and UserInfo.isGoldEnough(autoFightCost) then
                GuildData.GuildPage.sendAutoFightPacket(container)
            end
        end
        )
    end
end

function GuildBossPage:onClose(container)
    PageManager.popPage(thisPageName)
end

function GuildBossPage:openBoss(container, eventName)
    GuildDataManager:openBoss(container, eventName)
end

function GuildBossPage:refreshPage(container)
    if not container then return end

    -- titles
    local lb2Str = {
        mBossIntrusionLevel = common:getLanguageString('','@BossLevelName',0),
        mBossIntrusionExpNum = 0
    }

    local info = mServerData
    if info then
        local cfg = GuildDataManager:getBossCfgByBossId(info.bossId)
        if cfg then
            lb2Str.mBossIntrusionLevel = common:getLanguageString(cfg.bossName, '@BossLevelName', cfg.level)
            lb2Str.mBossIntrusionExpNum = common:getLanguageString('@BossExp') .. cfg.bossExp
            lb2Str.mBossVitalityNum = common:getLanguageString('@BossVitality') .. info.curBossVitality .. '/' .. info.openBossVitality
            -- 开启boss需要消耗的元气值
        end
    end
    NodeHelper:setStringForLabel(container, lb2Str)

    -- content
    if not info then
        self:showOpenBossView(container)
    elseif info.bossState == GuildData.BossPage.BossNotOpen then
        -- not open
        self:showOpenBossView(container)
    elseif info.bossState == GuildData.BossPage.BossCanJoin then
        -- battle
        self:showBossJoinView(container)
    elseif info.bossState == GuildData.BossPage.BossCanInspire then
        -- can inspire
        self:showBossBattleView(container)
    end
end

-- 显示‘开启boss’界面
function GuildBossPage:showOpenBossView(container)
    -- container:getVarNode("mInfoNode"):setPosition(ccp(0,-30))
    container:getVarNode("mInfoNode"):setVisible(true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite1'), true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite2'), false)
    -- 自动战斗,如果是vip3以下隐藏
    print("GuildData.MyAllianceInfo.myInfo.autoFight = ", GuildData.MyAllianceInfo.myInfo.autoFight)
    NodeHelper:setNodeVisible(container:getVarNode("mAutoFightNode"), UserInfo.playerInfo.vipLevel >= GameConfig.GuildBossAutoFightLimit)

    NodeHelper:setNodeVisible(container:getVarSprite("mAutoFightSprite"), GuildData.MyAllianceInfo.myInfo.autoFight == 1)
    CCLuaLog("mAutoFightSprite showOpenBossView = " .. tostring(GuildData.MyAllianceInfo.myInfo.autoFight == 1))
    NodeHelper:setNodeVisible(container:getVarNode('mOpenBossNode'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusion'), true)
    -- NodeHelper:setNodeVisible(container:getVarNode('mBossOpenNoticeNode'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusionBattle'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgBig'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgSmall'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mCDIntrusionNode'), false)
    local leftCount = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.bossFunRemSize or 0
    NodeHelper:setStringForLabel(container, { mOpenBossIntrusion = common:getLanguageString('@OpenBoss', leftCount) })
end

-- 显示‘加入战斗’界面
function GuildBossPage:showBossJoinView(container)
    -- container:getVarNode("mInfoNode"):setPosition(ccp(0, -30))
    container:getVarNode("mInfoNode"):setVisible(true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite1'), true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite2'), false)
    -- 自动战斗,如果是vip3以下隐藏
    print("GuildData.MyAllianceInfo.myInfo.autoFight = ", GuildData.MyAllianceInfo.myInfo.autoFight)
    NodeHelper:setNodeVisible(container:getVarNode("mAutoFightNode"), UserInfo.playerInfo.vipLevel >= GameConfig.GuildBossAutoFightLimit)
    NodeHelper:setNodeVisible(container:getVarSprite("mAutoFightSprite"), GuildData.MyAllianceInfo.myInfo.autoFight == 1)
    CCLuaLog("mAutoFightSprite showBossJoinView = " .. tostring(GuildData.MyAllianceInfo.myInfo.autoFight == 1))
    NodeHelper:setNodeVisible(container:getVarNode('mOpenBossNode'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusion'), false)
    -- NodeHelper:setNodeVisible(container:getVarNode('mBossOpenNoticeNode'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusionBattle'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgBig'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgSmall'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mCDIntrusionNode'), false)
    NodeHelper:setStringForLabel(container, { mOpenBossIntrusion = common:getLanguageString('@GuildBossJoin') })
end

-- 显示‘战斗’界面
function GuildBossPage:showBossBattleView(container)
    -- container:getVarNode("mInfoNode"):setPosition(ccp(0, 58))
    container:getVarNode("mInfoNode"):setVisible(true)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite1'), false)
    NodeHelper:setNodeVisible(container:getVarNode('m9Sprite2'), true)
    NodeHelper:setNodeVisible(container:getVarNode("mAutoFightNode"), false)

    NodeHelper:setNodeVisible(container:getVarNode('mOpenBossNode'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusion'), false)
    -- NodeHelper:setNodeVisible(container:getVarNode('mBossOpenNoticeNode'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mBossIntrusionBattle'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgBig'), true)
    NodeHelper:setNodeVisible(container:getVarNode('mGrayBgSmall'), false)
    NodeHelper:setNodeVisible(container:getVarNode('mCDIntrusionNode'), true)
    local info = GuildData.allianceInfo.commonInfo
    local lb2Str = { }
    local totalBlood = 0
    if info then
        local cfg = GuildDataManager:getBossCfgByBossId(info.bossId)
        if cfg then
            totalBlood = cfg.bossBlood
        end
        lb2Str.mBossIntrusionHpNum = tostring(GuildData.BossPage.bossBloodLeft) .. '/' .. tostring(totalBlood)
        lb2Str.mInspireIntrusionNum = common:getLanguageString('@GuildBossInspireRatio', info.bossPropAdd)
    else
        lb2Str.mBossIntrusionHpNum = '0/0'
        lb2Str.mInspireIntrusionNum = common:getLanguageString('@GuildBossInspireRatio', info.bossPropAdd)
    end
    -- inspire desc
    lb2Str.mEncouragePromptTex = common:getLanguageString('@GuildInspirePreview', GuildData.BossPage.InspirePercent, GuildData.BossPage.InspireCost)

    NodeHelper:setStringForLabel(container, lb2Str)



    local expProgressTimer = nil
    local expBarParentNode = container:getVarNode("mIntrusionExpBg")
    if expBarParentNode then
        expProgressTimer = expBarParentNode:getChildByTag(10086)
        if expProgressTimer == nil then
            local expSprite = CCSprite:createWithSpriteFrameName("Alliance_BossHpBar.png")
            expProgressTimer = CCProgressTimer:create(expSprite)
            expBarParentNode:addChild(expProgressTimer)
            expProgressTimer:setTag(10086)
            expProgressTimer:setAnchorPoint(ccp(0.5, 0.5))
            expProgressTimer:setPosition(ccp(expBarParentNode:getContentSize().width / 2, expBarParentNode:getContentSize().height / 2))
            expProgressTimer:setType(kCCProgressTimerTypeBar)
            expProgressTimer:setMidpoint(ccp(0, 0.5))
            expProgressTimer:setBarChangeRate(ccp(1, 0))
        end
    end


    -- progress bar
    local scale = 0.0
    if totalBlood ~= 0 then
        scale = GuildData.BossPage.bossBloodLeft / totalBlood
        -- * 1.09
        if scale < 0 then scale = 0.0 end
    end

    --    local expBar = container:getVarScale9Sprite('mIntrusionExp')
    --    if expBar then
    --        expBar:setScaleX(scale)
    --    end

    local n = math.abs(scale * 100)
    expProgressTimer:setPercentage(n)


end

function GuildBossPage:updateCD(container)
    if not container then return end

    local cdString = '00:00:00'
    if TimeCalculator:getInstance():hasKey(GuildData.BossPage.CDTimeKey) then
        local timeleft = TimeCalculator:getInstance():getTimeLeft(GuildData.BossPage.CDTimeKey)
        if timeleft > 0 then
            cdString = GameMaths:formatSecondsToTime(timeleft)
        else
            -- boss 倒计时结束，判断打没打死
            TimeCalculator:getInstance():removeTimeCalcultor(GuildData.BossPage.CDTimeKey)
            GuildDataManager:requestBasicInfo()
        end
    end
    NodeHelper:setStringForLabel(container, { mCD = common:getLanguageString("@BossRetreatCountDown") .. cdString })
end

-- 鼓舞
function GuildBossPage:onInspire(container, eventName)
    if UserInfo.isGoldEnough(GuildData.BossPage.InspireCost, "GuildBoss_Inspire_enter_rechargePage") then
        GuildDataManager:doInspire()
    end
end

function GuildBossPage:onContributionRanking(container, eventName)
    PageManager.pushPage('GuildBossHarmRankPage')
end

function GuildBossPage:onReceiveAllianceInfo(container, msg)
    GuildData.allianceInfo.commonInfo = msg
    mServerData = msg
    -- adjust blood left
    if msg:HasField('bossHp') then
        GuildData.BossPage.bossBloodLeft = msg.bossHp
    end

    -- 校正boss倒计时
    if msg:HasField('bossTime') then
        local bossTime = tonumber(msg.bossTime) and tonumber(msg.bossTime) or 600
        TimeCalculator:getInstance():createTimeCalcultor(GuildData.BossPage.CDTimeKey, bossTime)
        if bossTime <= 0 and(msg.bossState ~= GuildData.BossPage.BossNotOpen) then
            -- boss is over, reset page
            GuildDataManager:requestBasicInfo()
        end
    end

    if GuildData.BossPage.bossJoinFlag then
        -- 收到了加入战斗的回包
        GuildData.BossPage.bossJoinFlag = false
        local bossTime = tonumber(msg.bossTime) and tonumber(msg.bossTime) or 600
        TimeCalculator:getInstance():createTimeCalcultor(GuildData.BossPage.CDTimeKey, bossTime)
    end
end

function GuildBossPage:onReceiveBossHarm(container, msg)
    GuildData.BossPage.bossBloodLeft = tonumber(GuildData.BossPage.bossBloodLeft - msg.value)
    local harm = common:getLanguageString('@GuildBossHarmValue', tostring(msg.value))
    if bossHitContainer then
        NodeHelper:setStringForLabel(container, { mNumLabel = harm })
        bossHitContainer:runAnimation('showNum')
    end

    if GuildData.BossPage.bossBloodLeft <= 0 then
        GuildDataManager:requestBasicInfo()
    end
end

function GuildBossPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ALLIANCE_CREATE_S then
        local msg = alliance.HPAllianceInfoS()
        msg:ParseFromString(msgBuff)
        self:onReceiveAllianceInfo(container, msg)

        self:refreshPage(container)
    elseif opcode == HP_pb.ALLIANCE_ENTER_S then
        local msg = alliance.HPAllianceEnterS()
        msg:ParseFromString(msgBuff)
        GuildData.MyAllianceInfo = msg
        self:refreshPage(container)
    elseif opcode == HP_pb.ALLIANCE_BOSSHARM_S then
        local msg = alliance.HPAllianceBossHarmS()
        msg:ParseFromString(msgBuff)
        GuildBossPage:onReceiveBossHarm(container, msg)
        self:refreshPage(container)
    end
end

function GuildBossPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function GuildBossPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function GuildBossPage:onExecute(container)
    self:onTimer(self.container)
end

function GuildBossPage:onTimer(container)
    self:updateCD(container)
end

function GuildBossPage:onExit(container)
    if bossHitContainer then
        bossHitContainer:removeFromParentAndCleanup(true)
    end
    self:removePacket(container)
end

function GuildBossPage_setServerData(msg)
    mServerData = msg
end

local CommonPage = require('CommonPage')
GuildBoss = CommonPage.newSub(GuildBossPage, thisPageName, option)

return GuildBossPage