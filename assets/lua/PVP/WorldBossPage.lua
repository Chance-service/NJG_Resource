----------------------------------------------------------------------------------
--[[
    世界boss
--]]
----------------------------------------------------------------------------------
local thisPageName = "WorldBossPage";
local NodeHelper = require("NodeHelper");
local WorldBossManager = require("PVP.WorldBossManager");
local UserInfo = require("PlayerInfo.UserInfo");
local HP = require("HP_pb");
local WorldBoss_pb = require("WorldBoss_pb");
local MercenaryTouchSoundManager = require("MercenaryTouchSoundManager")
local roleCfg = { }
local buffCfg = { }
local SpinePartInfo = { }
local allianceHarmBox = { }
local allianceHarmInfos = { }
local inAttack = false
local rankSelect = 1 -- 1为个人排行 2为 联盟排行
local showAllianceHarnTime = 0
local curAttackPos = ccp(0, 0)
local failingBuffCCb = nil
local failTimeCountCCb = nil
local BossKillCCb = nil
local BossBehitCCB = nil
local RebornBar = nil
local inSkill = false
local curAttackBossHp = 0
local barHeight = 0
local opcodes = {
    FETCH_WORLD_BOSS_INFO_C = HP.FETCH_WORLD_BOSS_INFO_C,
    FETCH_WORLD_BOSS_INFO_S = HP.FETCH_WORLD_BOSS_INFO_S,
    WORLD_BOSS_ATTACK_PUSH_S = HP.WORLD_BOSS_ATTACK_PUSH_S,
    WORLD_BOSS_REBIRTH_C = HP.WORLD_BOSS_REBIRTH_C,
    WORLD_BOSS_REBIRTH_S = HP.WORLD_BOSS_REBIRTH_S,
    WORLD_BOSS_RANK_C = HP.WORLD_BOSS_RANK_C,
    WORLD_BOSS_RANK_S = HP.WORLD_BOSS_RANK_S,
    WORLD_BOSS_FAILING_S = HP.WORLD_BOSS_FAILING_S,
};

local option = {
    ccbiFile = "GVEBattlePage.ccbi",
    ccbiFile_Sp = "WorldBossSpecialPage.ccbi",
    handlerMap =
    {
        onPerson = "onPerson",
        onGuild = "onGuild",
        onLive = "onLive",
        onBornOfFire = "onBornOfFire",
        onHelp = "onHelp",
        onReturnBtn = "onReturn"
    }
};

local WorldBossPageBase = { };
local TimerFunc = { };

WorldBossPageBase.CDTimeReBorn = "WorldBossCDTimeReBorn"
WorldBossPageBase.CDTimeReAttack = "WorldBossCDTimeReAttack"
WorldBossPageBase.CDTimeSendRefresh = "WorldBossCDTimeSendRefresh"
WorldBossPageBase.CDTimeBossStay = "WorldBossCDTimeBossStay"
WorldBossPageBase.CDTimeAttackAni = "WorldBossCDTimeAttackAni"
WorldBossPageBase.CDTimeFailing = "WorldBossCDTimeFailing"
WorldBossPageBase.Button_CoolTime_isShowing = false

local isFirstEnter = false

local HpAniCCB = nil

----------------------------------------------------------
function WorldBossPageBase:onEnter(container)
    CCLuaLog("WorldBossPageBase:onEnter")
    self.container = container

    local bgScale = NodeHelper:getAdjustBgScale(1)
    if bgScale < 1 then bgScale = 1 end
    NodeHelper:setNodeScale(container, "mBG", bgScale, bgScale)

    roleCfg = ConfigManager.getRoleCfg()
    buffCfg = ConfigManager.getGVEBuffCfg()
    WorldBossPageBase.container = container
    WorldBossPageBase:registerPacket(container);
    container.mScrollView = container:getVarScrollView("mContent");
    --container.mScrollView:setContentSize(CCSizeMake(682,120))
    NodeHelper:setNodesVisible(container, {
        mDamageListNode = true,
        mRightDamageNode = true,
        mBattleRoleNode = false,
        mResultNode = false,
    } )

    for i = 1, 5 do
        local t = { node = container:getVarNode("mD" .. i), index = i }

        -- allianceHarmBox[i].node = container:getVarNode("mD"..i)
        -- allianceHarmBox[i].index = i
        allianceHarmBox[i] = t
        if allianceHarmBox[i].node then
            allianceHarmBox[i].node:setVisible(false)
        end
    end
    WorldBossPageBase:sendMsgForWorldBossinfo(container);
    if WorldBossManager.WorldBossAttrInfo.roleItemId then
        -- SpinePartInfo = ConfigManager.getRoleTouchMusicCfg()[WorldBossManager.WorldBossAttrInfo.roleItemId]
        SpinePartInfo = getTouchConfig(WorldBossManager.WorldBossAttrInfo.roleItemId)
        WorldBossPageBase:initSpine(container)

    end
    local mLiveBar = container:getVarSprite("mLiveBar")
    mLiveBar:setVisible(false)
    local mLiveNode = container:getVarNode("mLiveNode")
    RebornBar = CCProgressTimer:create(mLiveBar)
    RebornBar:setType(kCCProgressTimerTypeBar)
    RebornBar:setMidpoint(CCPointMake(0, 0))
    -- RebornBar:setScale(1.3)
    -- RebornBar:setPosition(ccp())
    RebornBar:setBarChangeRate(CCPointMake(1, 0))
    mLiveNode:addChild(RebornBar)
    RebornBar:setPercentage(100)
    NodeHelper:setMenuItemEnabled(container, "mLiveBtn", false)
    NodeHelper:setNodeIsGray(container, { mLiveBtnText = true })

    NodeHelper:setNodesVisible(container, { mTempHp = CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 })
end

function WorldBossPageBase:onLoad(container)
    CCLuaLog("WorldBossPageBase:onLoad")
    if WorldBossManager.getBossType() == "ActivityBoss" then
        -- container:loadCcbiFile(option.ccbiFile_Sp)
        container:loadCcbiFile(option.ccbiFile)
    else
        container:loadCcbiFile(option.ccbiFile)
    end
end

function WorldBossPageBase:onExecute(container)
    TimerFunc.updateCD(container)

    if not inAttack and WorldBossManager.AllianceHarmLen > 0 and #WorldBossManager.AllianceHarm > 0 then
        local dt = GamePrecedure:getInstance():getFrameTime() * 1000;
        showAllianceHarnTime = showAllianceHarnTime + dt
        if showAllianceHarnTime >= 5 / WorldBossManager.AllianceHarmLen then
            showAllianceHarnTime = 0
            WorldBossPageBase:addNewAllianceHarm(container, table.remove(WorldBossManager.AllianceHarm, 1))
        end
    end
end

function setBoxInfo(container, allianceHarm, boxIndex)
    CCLuaLog("WorldBossPageBase:setBoxInfo")
    local labelTb = { }
    local iconTb = { }
    local meuItemImage = { }
    -- dump(allianceHarm)
    labelTb["mMercenaryName" .. boxIndex] = allianceHarm.playerName
    labelTb["mDamageNum" .. boxIndex] = allianceHarm.harm
    -- iconTb["mPortrait" .. boxIndex] = roleCfg[allianceHarm.mainRoleItemId].icon
    iconTb["mPortrait" .. boxIndex] = roleCfg[allianceHarm.mainRoleItemId].chatIcon

    -- meuItemImage["mPicFrame"..boxIndex] = GameConfig.QualityImage[tonumber(roleCfg[allianceHarm.itmeId]["quality"])+16];
    NodeHelper:setStringForLabel(container, labelTb)
    NodeHelper:setSpriteImage(container, iconTb)
    -- NodeHelper:setNormalImages(container, meuItemImage)
end

function WorldBossPageBase:addNewAllianceHarm(container, allianceHarm)
    CCLuaLog("WorldBossPageBase:addNewAllianceHarm")

    for i, item in ipairs(allianceHarmBox) do
        item.node:stopAllActions()
        item.node:setPosition(ccp(-50, 120 - 70 * i + 70))
    end
    setBoxInfo(container, allianceHarm, allianceHarmBox[5].index)
    -- allianceHarmBox[5]:setVisible(true)
    table.insert(allianceHarmInfos, 1, allianceHarm)
    if #allianceHarmInfos > 4 then
        for i = 5, #allianceHarmInfos do
            table.remove(allianceHarmInfos, i)
        end
    end
    local box = table.remove(allianceHarmBox, 5)
    table.insert(allianceHarmBox, 1, box)
    box.node:setVisible(true)
    box.node:setPosition(ccp(-50, 320))
    -- box:setOpacity(0)
    local arr = CCArray:create()
    local array = CCArray:create()
    array:addObject(CCJumpBy:create(0.2, ccp(0, -200), 0, 1))
    array:addObject(CCFadeOut:create(0.2))

    arr:addObject(CCSpawn:create(array))
    local pFunc = CCCallFunc:create( function()
        allianceHarmBox[5].node:setVisible(false)
    end )
    arr:addObject(pFunc)
    box.node:runAction(CCSequence:create(arr));

    for i = 1, #allianceHarmInfos do
        if allianceHarmBox[i + 1] then
            allianceHarmBox[i + 1].node:runAction(CCJumpBy:create(0.2, ccp(0, -70), 0, 1))
        end
    end
end

function WorldBossPageBase:onExit(container)
    CCLuaLog("WorldBossPageBase:onExit")
    inAttack = false
    inSkill = false
    curAttackBossHp = 0
    WorldBossPageBase:removePacket(container)
    TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeSendRefresh);
    TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeReAttack);
    TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeReBorn);
    TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeBossStay);
    TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeAttackAni);
    NodeHelper:deleteScrollView(container);
    WorldBossManager.AllianceHarm = { }
    allianceHarmInfos = { }
    allianceHarmBox = { }
    if failingBuffCCb then
        failingBuffCCb:release()
        failingBuffCCb = nil
    end
    if failTimeCountCCb then
        failTimeCountCCb:release()
        failTimeCountCCb = nil
    end

    if BossBehitCCB then
        BossBehitCCB:release()
        BossBehitCCB = nil
    end

    BossKillCCb = nil
end
-- 5个计时器
function TimerFunc.updateCD(container)
    -- BossLeave
    local BossleaveString = '00 : 00 : 00'
    if TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeBossStay) then
        local timeleftBossStay = TimeCalculator:getInstance():getTimeLeft(WorldBossPageBase.CDTimeBossStay)
        if timeleftBossStay > 0 then
            BossleaveString = GameMaths:formatSecondsToTime(timeleftBossStay)
            NodeHelper:setStringForLabel(container, { mTime = BossleaveString })
        else
            TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeBossStay);
            WorldBossPageBase:sendMsgForWorldBossinfo(container)
        end
    end

    -- 重生
    local RebornString = '0'
    if TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeReBorn) then
        local timeleftReBorn = TimeCalculator:getInstance():getTimeLeft(WorldBossPageBase.CDTimeReBorn)
        if timeleftReBorn > 0 then
            RebornString = common:getLanguageString("@AttackCoolTime") .. "(" .. timeleftReBorn .. ")"
            NodeHelper:setStringForLabel(container, { mTimeDown = RebornString })
            -- 两个按钮不可点击
            -- 攻击
            if TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeReAttack) then
                local timeleftReAttack = TimeCalculator:getInstance():getTimeLeft(WorldBossPageBase.CDTimeReAttack)
                if timeleftReAttack <= 0 then
                    NodeHelper:setMenuItemEnabled(container, "mLiveBtn", true)
                    NodeHelper:setNodeIsGray(container, { mLiveBtnText = false })

                    TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeReAttack);
                end
            end
        else
            NodeHelper:setNodesVisible(container, { mLiveNode = false, mTimeDown = false, mClickSure = true })
            NodeHelper:setStringForLabel(container, { mTimeDown = "" })
            TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeReBorn);
        end
    end

    -- 每五秒发一次刷新请求
    if TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeSendRefresh) then
        local timeleftSendRefresh = TimeCalculator:getInstance():getTimeLeft(WorldBossPageBase.CDTimeSendRefresh)
        if timeleftSendRefresh <= 0 then
            WorldBossPageBase:sendMsgForRanklist(container)
            TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeSendRefresh);
            TimeCalculator:getInstance():createTimeCalcultor(WorldBossPageBase.CDTimeSendRefresh, 5)
        end
    end

    if TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeFailing) then
        local timeleftFailing = TimeCalculator:getInstance():getTimeLeft(WorldBossPageBase.CDTimeFailing)
        if timeleftFailing > 0 then
            if failTimeCountCCb then
                local failTime = GameMaths:formatSecondsToTime(timeleftFailing)
                local failStr = common:getLanguageString("@GVEFailCount", failTime)
                NodeHelper:setStringForLabel(failTimeCountCCb, { mPointTimeDown = failStr })
            end
        else
            TimeCalculator:getInstance():removeTimeCalcultor(WorldBossPageBase.CDTimeFailing);
            if failingBuffCCb then
                failingBuffCCb:stopAllActions()
                failingBuffCCb:removeFromParentAndCleanup(false)
            end
            if failTimeCountCCb then
                failTimeCountCCb:runAnimation("Fight")
                failTimeCountCCb:removeFromParentAndCleanup(false)
            end
        end
    end
end

function WorldBossPageBase:initSpine(container)
    CCLuaLog("WorldBossPageBase:initSpine")
    if GameConfig.ShowSpineAvatar then
        -- boss 骨骼动画
        local SpineConfig = WorldBossManager.GetSpineConfig()
        local bossNode = container:getVarNode("mSpine");
        local skillNode = container:getVarNode("mSkill")
        -- local mSpineParent = container:getVarNode("mSpineParent")
        local mSpineParent = container:getVarNode("mSpineParent")
        mSpineParent:setScale(1)

        -- WorldBossManager.WorldBossAttrInfo.roleItemId --这个是世界boss的id  目前对应的是role.txt

        local roleData = roleCfg[WorldBossManager.WorldBossAttrInfo.roleItemId]

        if bossNode then
            bossNode:removeAllChildren()
            local dataSpine = common:split((roleData.spine), ",")
            local spine = SpineContainer:create(dataSpine[1], dataSpine[2])
            local spineNode = tolua.cast(spine, "CCNode")
            bossNode:addChild(spineNode);
            spine:runAnimation(1, "Stand", -1)

            local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
            NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
            spineNode:setScale(roleData.spineScale)
        end

        if skillNode then
            BossKillCCb = ScriptContentBase:create("GVEBattleBossSkill.ccbi")
            skillNode:addChild(BossKillCCb)
        end
    else
        -- local sprite = WorldBossManager.GetNormalPic()
        -- NodeHelper:setSpriteImage(container,{ mHeroPic 	= sprite })
        -- NodeHelper:setNodesVisible(container, {
        -- 			mHeroPic = true})
    end
end

function WorldBossPageBase:refreshPage(container)
    CCLuaLog("WorldBossPageBase:refreshPage")
    -- 战斗结束
    if WorldBossManager.BossState == 1 then
        PageManager.changePage("PVPActivityPage")
        WorldBossManager.EnterPageByState()
        return
    end

    -- 战斗前30分钟
    if WorldBossManager.BossState == 2 then
        -- 弹框列出错误
        MessageBoxPage:Msg_Box_Lan("@WorldBoss30minBefore")
        PageManager.changePage("PVPActivityPage")
        return
    end

    -- 介绍boss
    local roleId = WorldBossManager.WorldBossAttrInfo.roleItemId
    local roleInfo = roleCfg[WorldBossManager.WorldBossAttrInfo.roleItemId]
    NodeHelper:setStringForLabel(container, {
        mMercenaryName = roleInfo.name,
        mCostNum = WorldBossManager.needRebirthCost
    } )
    -- NodeHelper:setStringForLabel(container, { mWoldBossLeverNum = WorldBossManager.WorldBossAttrInfo.level })
    -- NodeHelper:setLabelOneByOne(container, "mWoldBossLeverTitle","WoldBossLeverNum",5,true);

    self:refreshHP(container, WorldBossManager.currBossHp)
    self:setSelectButton(container)
    self:refreshFailing(container, true)
    -- 进入后就有弱点不显示出现效果
    -- 显示boss剩余时间读秒
    if not TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeBossStay) then
        TimeCalculator:getInstance():createTimeCalcultor(WorldBossPageBase.CDTimeBossStay, WorldBossManager.leftTime)
    end

    -- 显示复活读秒
    if not TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeReBorn) and WorldBossManager.rebirthLeftTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(WorldBossPageBase.CDTimeReBorn, WorldBossManager.rebirthLeftTime)
        NodeHelper:setNodesVisible(container, { mLiveNode = true, mTimeDown = true, mClickSure = false })
        -- 显示攻击读秒
        RebornBar:setPercentage(0)
        NodeHelper:setMenuItemEnabled(container, "mLiveBtn", true)
        NodeHelper:setNodeIsGray(container, { mLiveBtnText = false })
        if not TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeReAttack) and WorldBossManager.actionLeftTime > 0 then
            TimeCalculator:getInstance():createTimeCalcultor(WorldBossPageBase.CDTimeReAttack, WorldBossManager.actionLeftTime)
            -- NodeHelper:setNodesVisible(container, { mLiveNode = false })
            NodeHelper:setMenuItemEnabled(container, "mLiveBtn", false)
            NodeHelper:setNodeIsGray(container, { mLiveBtnText = true })
            RebornBar:runAction(CCProgressTo:create(WorldBossManager.actionLeftTime, 0))
        end
    else
        NodeHelper:setNodesVisible(container, { mLiveNode = false, mTimeDown = false, mClickSure = true })
    end

    if not TimeCalculator:getInstance():hasKey(WorldBossPageBase.CDTimeSendRefresh) then
        TimeCalculator:getInstance():createTimeCalcultor(WorldBossPageBase.CDTimeSendRefresh, 5)
    end

    -- 伤害排行
    WorldBossPageBase:rebuildAllItem(container)
    WorldBossPageBase:refreshMyContent(container)

end

function WorldBossPageBase:refreshHP(container, hp)
    CCLuaLog("WorldBossPageBase:refreshHP")
    if WorldBossManager.WorldBossAttrInfo.maxHp == nil then
        return
    end

    if hp <= 0 then
        if not inAttack then
            WorldBossPageBase:sendMsgForWorldBossinfo(container);
            return
        else
            hp = 0
        end
    end

    -- hp = 当前血量    WorldBossManager.WorldBossAttrInfo.maxHp = boss的最大血量
    -- 这里做血条增加处理   当前好感度 == boss的最大血量  boss死亡
    -- WorldBossManager.WorldBossAttrInfo.maxHp - 当前血量 = 增加的好感度
    local currentDisposition = tonumber(WorldBossManager.WorldBossAttrInfo.maxHp) - tonumber(hp)
    local NumString = tostring(hp) .. "/" .. tostring(WorldBossManager.WorldBossAttrInfo.maxHp)

    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        local mTempHp = container:getVarLabelTTF("mTempHp")
        mTempHp:setString(NumString)
    end

    local HpMap = container:getVarSprite("mBar")
    -- HpMap:setScaleX(hp / WorldBossManager.WorldBossAttrInfo.maxHp)
    -- NodeHelper:setStringForLabel(container,{mHP = NumString})
    local proportion = currentDisposition / WorldBossManager.WorldBossAttrInfo.maxHp
    HpMap:setScaleY(proportion)
    local hpPercentage = currentDisposition / tonumber(WorldBossManager.WorldBossAttrInfo.maxHp) * 100

    local hpInteger = math.modf(hpPercentage)
    NodeHelper:setStringForLabel(container, { mHP = hpInteger .. "%" })

    -- 刷新血量图标位置
    local mBarBg = container:getVarSprite("mBarBg")

    local mHpLabelNode = container:getVarNode("mHpLabelNode")
    if mBarBg then
        local hpProgressTimer = mBarBg:getChildByTag(10086)
        if hpProgressTimer == nil then
            local barSprite = CCSprite:createWithSpriteFrameName("WorldBossBattle_Bar.png")
            barHeight = barSprite:getContentSize().height
            hpProgressTimer = CCProgressTimer:create(barSprite)
            mBarBg:addChild(hpProgressTimer)
            hpProgressTimer:setTag(10086)
            hpProgressTimer:setAnchorPoint(ccp(0.5, 0.5))
            hpProgressTimer:setPosition(ccp(mBarBg:getContentSize().width / 2, mBarBg:getContentSize().height / 2))
            hpProgressTimer:setType(kCCProgressTimerTypeBar)
            hpProgressTimer:setMidpoint(ccp(0, 0))
            hpProgressTimer:setBarChangeRate(ccp(0, 1))
        end

        hpProgressTimer:setPercentage(hpInteger)

        if barHeight == nil or barHeight <= 0 then
            barSprite = CCSprite:createWithSpriteFrameName("WorldBossBattle_Bar.png")
            barHeight = barSprite:getContentSize().height
        end
        local positionY = barHeight * hpInteger / 100
        mHpLabelNode:setPositionY(positionY + 20)
    end

    -- if HpAniCCB then
    --     local HpNum = HpAniCCB:getVarLabelBMFont("mwoldBossHpNum")

    --     local HpMap = HpAniCCB:getVarScale9Sprite("mBar")
    --     local HpMapAni = HpAniCCB:getVarScale9Sprite("mWoldBossHpAni")
    --     if hp / WorldBossManager.WorldBossAttrInfo.maxHp > 0.1 then
    --         HpMap:setVisible(true)
    --         -- 血量图
    --         HpMap:setScaleX(hp / WorldBossManager.WorldBossAttrInfo.maxHp)
    --         HpMapAni:setVisible(false)
    --         local NumString = tostring(hp) .. "/" .. tostring(WorldBossManager.WorldBossAttrInfo.maxHp)
    --         NodeHelper:setStringForLabel(HpAniCCB, { mwoldBossHpNum = NumString })
    --     else
    --         -- 血条闪动 + 隐藏
    --         -- 血量动画
    --         HpMapAni:setScaleX(hp / WorldBossManager.WorldBossAttrInfo.maxHp)
    --         NodeHelper:setStringForLabel(HpAniCCB, { mwoldBossHpNum = "???? /" .. tostring(WorldBossManager.WorldBossAttrInfo.maxHp) })
    --         HpMap:setVisible(false)
    --         HpMapAni:setVisible(true)
    --         HpAniCCB:runAnimation("Default Timeline");
    --     end
    -- end
end

function WorldBossPageBase:refreshRebirth(container)
    CCLuaLog("WorldBossPageBase:refreshRebirth")
    TimeCalculator:getInstance():createTimeCalcultor(WorldBossPageBase.CDTimeReBorn, WorldBossManager.rebirthLeftTime)
    RebornBar:setPercentage(100)
    NodeHelper:setMenuItemEnabled(container, "mLiveBtn", false)
    NodeHelper:setNodeIsGray(container, { mLiveBtnText = true })
    RebornBar:runAction(CCProgressFromTo:create(WorldBossManager.actionLeftTime, 100, 0))
    NodeHelper:setNodesVisible(container, { mLiveNode = true, mClickSure = false, mTimeDown = true })
    TimeCalculator:getInstance():createTimeCalcultor(WorldBossPageBase.CDTimeReAttack, WorldBossManager.actionLeftTime)
end

function WorldBossPageBase:refreshRankList(container)
    CCLuaLog("WorldBossPageBase:refreshRankList")
    WorldBossPageBase:rebuildAllItem(container)
    if not inAttack then
        WorldBossPageBase:refreshHP(container, WorldBossManager.currBossHp)
    end
    -- 刷新我的伤害以及伤害次数
    NodeHelper:setStringForLabel(container, { mMyHurtNum = tostring(WorldBossManager.selfAttack) })
    NodeHelper:setStringForLabel(container, { mAttacksTimes = tostring(WorldBossManager.selfAttacksTimes) })
    NodeHelper:setLabelOneByOne(container, "mMyHurtLable", "mMyHurtNum")
end

function WorldBossPageBase:refreshFailing(container, isRefreshPage)
    CCLuaLog("WorldBossPageBase:refreshFailing")
    if WorldBossManager.currBossFailingEndTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(WorldBossPageBase.CDTimeFailing, WorldBossManager.currBossFailingEndTime)
        if failingBuffCCb == nil then
            failingBuffCCb = ScriptContentBase:create("GVEBattleMiaozhun.ccbi")
            failingBuffCCb:retain()
        else
            failingBuffCCb:stopAllActions()
            failingBuffCCb:removeFromParentAndCleanup(false)
        end
        if failTimeCountCCb == nil then
            failTimeCountCCb = ScriptContentBase:create("GVETimeDownAni.ccbi")
            failTimeCountCCb:retain()
        else
            failTimeCountCCb:stopAllActions()
            failTimeCountCCb:removeFromParentAndCleanup(false)
        end


        if WorldBossManager.worldBossFailingType then
            local spineNode = container:getVarNode("mSpineParent")
            spineNode:addChild(failingBuffCCb, 10086)
            local timeCountNode = container:getVarNode("mTimeDownNode")
            timeCountNode:setVisible(true)
            timeCountNode:addChild(failTimeCountCCb, 10086)
            failTimeCountCCb:runAnimation("TimeDown")
            local locationPos
            if WorldBossManager.worldBossFailingType == 1 then
                locationPos = SpinePartInfo._head.pos1
            elseif WorldBossManager.worldBossFailingType == 2 then
                locationPos = SpinePartInfo._heart.pos1
            else
                locationPos = SpinePartInfo._ass.pos1
            end
            if isRefreshPage then
                failingBuffCCb:setPosition(ccp(locationPos.x, locationPos.y))
                failingBuffCCb:runAnimation("Idel")
            else
                failingBuffCCb:setPosition(ccp(SpinePartInfo._head.pos1.x, SpinePartInfo._head.pos1.y))
                local array = CCArray:create()
                -- array:addObject(CCMoveTo:create(0.1, ccp(SpinePartInfo._head.pos1.x,SpinePartInfo._head.pos1.y)))
                array:addObject(CCMoveTo:create(0.2, ccp(SpinePartInfo._heart.pos1.x, SpinePartInfo._heart.pos1.y)))
                array:addObject(CCMoveTo:create(0.2, ccp(SpinePartInfo._ass.pos1.x, SpinePartInfo._ass.pos1.y)))
                array:addObject(CCMoveTo:create(0.2, ccp(SpinePartInfo._head.pos1.x, SpinePartInfo._head.pos1.y)))
                array:addObject(CCMoveTo:create(0.2, ccp(SpinePartInfo._heart.pos1.x, SpinePartInfo._heart.pos1.y)))
                array:addObject(CCMoveTo:create(0.2, ccp(SpinePartInfo._ass.pos1.x, SpinePartInfo._ass.pos1.y)))

                array:addObject(CCMoveTo:create(0.2, ccp(locationPos.x, locationPos.y)))
                array:addObject(CCCallFunc:create( function()
                    failingBuffCCb:runAnimation("Idel")
                end ))
                failingBuffCCb:runAction(CCSequence:create(array))
                failingBuffCCb:runAnimation("Born")
            end
        end



        --        if WorldBossManager.worldBossFailingType then
        --            local spineNode = container:getVarNode("mSpineParent")
        --            spineNode:addChild(failingBuffCCb, 10086)
        --            local timeCountNode = container:getVarNode("mTimeDownNode")
        --            timeCountNode:setVisible(true)
        --            timeCountNode:addChild(failTimeCountCCb, 10086)
        --            failTimeCountCCb:runAnimation("TimeDown")
        --            local locationPos
        --            if WorldBossManager.worldBossFailingType == 1 then
        --                locationPos = SpinePartInfo._head.pos1
        --            elseif WorldBossManager.worldBossFailingType == 2 then
        --                locationPos = SpinePartInfo._heart.pos1
        --            else
        --                locationPos = SpinePartInfo._ass.pos1
        --            end
        --            if isRefreshPage then
        --                failingBuffCCb:setPosition(ccp(locationPos.x,locationPos.y))
        --                failingBuffCCb:runAnimation("Idel")
        --            else
        --                failingBuffCCb:setPosition(ccp(SpinePartInfo._head.pos1.x,SpinePartInfo._head.pos1.y))
        --                local array = CCArray:create()
        --                -- array:addObject(CCMoveTo:create(0.1, ccp(SpinePartInfo._head.pos1.x,SpinePartInfo._head.pos1.y)))
        --                array:addObject(CCMoveTo:create(1, ccp(SpinePartInfo._heart.pos1.x,SpinePartInfo._heart.pos1.y)))
        --                array:addObject(CCMoveTo:create(1, ccp(SpinePartInfo._ass.pos1.x,SpinePartInfo._ass.pos1.y)))
        --                array:addObject(CCMoveTo:create(1, ccp(SpinePartInfo._head.pos1.x,SpinePartInfo._head.pos1.y)))
        --                array:addObject(CCMoveTo:create(1, ccp(SpinePartInfo._heart.pos1.x,SpinePartInfo._heart.pos1.y)))
        --                array:addObject(CCMoveTo:create(1, ccp(SpinePartInfo._ass.pos1.x,SpinePartInfo._ass.pos1.y)))

        --                array:addObject(CCMoveTo:create(1, ccp(locationPos.x, locationPos.y)))
        --                array:addObject(CCCallFunc:create(function (  )
        --                    failingBuffCCb:runAnimation("Idel")
        --                end))
        --                failingBuffCCb:runAction(CCSequence:create(array))
        --                failingBuffCCb:runAnimation("Born")
        --            end
        --        end
    end
end
----------------scrollview item-------------------------
local RankListItem = {
    ccbiFile = 'GVEBattleDamageContent.ccbi'
}

function WorldBossPageBase:refreshMyContent(container)
    --NodeHelper:setNodeVisible(container:getVarNode("mMyDamage"),false)
    local index = 0
    local info = nil
    --if not info then return end
    if rankSelect == 1 then
        info = {}
        index = WorldBossManager.selfHarmRank
        info.playerName = UserInfo.roleName
        info.harm = WorldBossManager.selfAttack
        info.attacksTimes = WorldBossManager.selfAttacksTimes
    else
--[[        if UserInfo.guildName == nil or UserInfo.guildName == "" then
            for i = 1, #WorldBossManager.curRankList do
                if WorldBossManager.curRankList[i].playerName == UserInfo.roleName then
                    info = WorldBossManager.curRankList[i]
                    index = i
                    break
                end
            end
        else
            for i = 1, #WorldBossManager.curAllianceRankList do
                if WorldBossManager.curAllianceRankList[i].playerName == UserInfo.guildName then
                    info = WorldBossManager.curAllianceRankList[i]
                    index = i
                    break
                end
            end
        end]]

        local allianceHarm = WorldBossManager.selfAllianceHarm
--[[        for i = 1, #WorldBossManager.selfAllianceHarm do
            allianceHarm = allianceHarm + WorldBossManager.selfAllianceHarm[i].harm
        end]]

        info = {}
        index = WorldBossManager.selfAllianceRank
        info.playerName = UserInfo.guildName
        info.harm = allianceHarm
    end
    if not info then return end
    local lb2Str = {
        mRankLabel_1 = index,
        mGuildName_1 = info.playerName,
        mDamage_1 = info.harm,
        mTimes_1 = rankSelect == 1 and common:getLanguageString("@GVEBattleTimes",info.attacksTimes) or ""
    }
    local bgNode = CCSprite:create("Imagesetfile/WorldBoss/WorldBossWeapon_myDiban.png")
    local vipTitleBg = tolua.cast(container:getVarNode("mMyBG1"), "CCScale9Sprite")
    local vipTitleBgSize = vipTitleBg:getContentSize()
    vipTitleBg:setSpriteFrame(bgNode:displayFrame())
    vipTitleBg:setContentSize(vipTitleBgSize)
    if index == nil then
        index = 1
    end
    local visible = { }
    visible.mRankLabel_1 = index >= 4
    visible.mRankImage_1 = index < 4

    if index > 0 and index < 4 then
        NodeHelper:setSpriteImage(container, { mRankImage_1 = "WorldBossBattle_Rank_Image_" .. index .. ".png" })
    elseif index > 2000 then
        index = ">2000"
        lb2Str.mRankLabel = index
    end
    NodeHelper:setNodesVisible(container, visible)
    NodeHelper:setColorForLabel(container, { mGuildName_1 = "255 216 0", mTimes_1 = "255 216 0", mDamage_1 = "255 216 0" })
    NodeHelper:setStringForLabel(container, lb2Str)
end

function RankListItem:onRefreshContent(ccbRoot)
    CCLuaLog("WorldBossPageBase:RankListItem:onRefreshContent")
    local container = ccbRoot:getCCBFileNode()
    local index = self.id
    local info
    if rankSelect == 1 then
        info = WorldBossManager.curRankList[index]
    else
        info = WorldBossManager.curAllianceRankList[index]
    end

    if not info then return end
    local lb2Str = {
        mRankLabel = index,
        mGuildName = info.playerName,
        mDamage = info.harm,
        mTimes = rankSelect == 1 and common:getLanguageString("@GVEBattleTimes",info.attacksTimes) or ""
    }

    NodeHelper:setNodesVisible(container, { mBG = index % 2 == 1 })

    local visible = { }
    visible.mRankLabel = index >= 4
    visible.mRankImage = index < 4

    if index > 0 and index < 4 then
        NodeHelper:setSpriteImage(container, { mRankImage = "WorldBossBattle_Rank_Image_" .. index .. ".png" })
    end

    --    local visible = {}
    --    visible.mBG = index%2 == 1
    --    for i = 1, 3 do
    --        visible["mRankingNum"..i] = false
    --    end
    --    visible.mRanking = true
    --    if info.rankIndex < 4 then
    --        visible["mRankingNum"..info.rankIndex] = true
    --        visible.mRanking = false
    --    end
    NodeHelper:setNodesVisible(container, visible)
    NodeHelper:setStringForLabel(container, lb2Str)
end	

function WorldBossPageBase:setSelectButton(container)
    CCLuaLog("WorldBossPageBase:WorldBossPageBase:setSelectButton")
    local selectedMap =
    {
        mLeftNode = rankSelect == 1,
        mRightNode = rankSelect == 2,
    }

    NodeHelper:setNodesVisible(container, selectedMap)
    if rankSelect == 1 then
        -- NodeHelper:setMenuItemEnabled(container,"mPerson",true)
        -- NodeHelper:setMenuItemEnabled(container,"mGuild",false)
        NodeHelper:setNodesVisible(container, { mPersonRankSclectSprite = true, mGuildRankSclectSprite = false })

    else
        -- NodeHelper:setMenuItemEnabled(container,"mPerson",false)
        -- NodeHelper:setMenuItemEnabled(container,"mGuild",true)
        NodeHelper:setNodesVisible(container, { mPersonRankSclectSprite = false, mGuildRankSclectSprite = true })
    end
end

----------------scrollview-------------------------
function WorldBossPageBase:rebuildAllItem(container)
    CCLuaLog("WorldBossPageBase:WorldBossPageBase:rebuildAllItem")
    local size = 0
    if rankSelect == 1 then
        size = #WorldBossManager.curRankList
    else
        size = #WorldBossManager.curAllianceRankList
    end
    container.mScrollView:removeAllCell()
    NodeHelper:buildCellScrollView(container.mScrollView, size, RankListItem.ccbiFile, RankListItem)
end
----------------click event------------------------
function WorldBossPageBase:onGuild(container)
    CCLuaLog("WorldBossPageBase:onGuild")
    if rankSelect == 1 then
        rankSelect = 2
        self:setSelectButton(container)
        self:rebuildAllItem(container)
        self:refreshMyContent(container)
    end
end

function WorldBossPageBase:onLive(container)
    CCLuaLog("WorldBossPageBase:onLive")
    print("onLive")
    local message = WorldBoss_pb.HPRebirth();
    message.worldBossIsFree = 2;
    message.worldBossFailingType = 0
    local pb_data = message:SerializeToString();
    PacketManager:getInstance():sendPakcet(opcodes.WORLD_BOSS_REBIRTH_C, pb_data, #pb_data, true);
end

function WorldBossPageBase:onPerson(container)
    CCLuaLog("WorldBossPageBase:onPerson")
    if rankSelect == 2 then
        rankSelect = 1
        self:setSelectButton(container)
        self:rebuildAllItem(container)
        self:refreshMyContent(container)


    end
end

-- function WorldBossPageBase:onBornOfFire(container)
--     -- 发2表示强力复活
--     if UserInfo.playerInfo.gold >= WorldBossManager.needRebirthCost  then
--        WorldBossPageBase:sendMsgForRebirth(container, 2)
--        WorldBossPageBase:SetButtonActive(container)
--     else
--        MessageBoxPage:Msg_Box_Lan("@GoldNotEnough")
--     end
-- end

function WorldBossPageBase:SetButtonActive(container)
    CCLuaLog("WorldBossPageBase:SetButtonActive")
    NodeHelper:setMenuItemEnabled(container, "mImmediatelyResurrection", false);
    NodeHelper:setMenuItemEnabled(container, "mBornOfFire", false);
end

function WorldBossPageBase:onHelp(container)
    CCLuaLog("WorldBossPageBase:onHelp")
    PageManager.showHelp(GameConfig.HelpKey.HELP_GVE)
end

function WorldBossPageBase:onReturn(container)
    if WorldBossManager.enterFinalPageFrom == 1 then
        PageManager.changePage("PVPActivityPage")
    else
        PageManager.changePage("GuildPage")
    end
    WorldBossManager.enterFinalPageFrom = 0
end
----------------------------------------------------------------
function WorldBossPageBase:sendMsgForWorldBossinfo(container)
    common:sendEmptyPacket(opcodes.FETCH_WORLD_BOSS_INFO_C, true)
end

function WorldBossPageBase:sendMsgForRanklist(container)
    common:sendEmptyPacket(opcodes.WORLD_BOSS_RANK_C, true)
end

function WorldBossPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.FETCH_WORLD_BOSS_INFO_S then
        local msg = WorldBoss_pb.HPWorldBossInfo();
        msg:ParseFromString(msgBuff)
        WorldBossManager.ReceiveHPWorldBossInfo(msg)
        self:refreshPage(container)
        return
    end

    if opcode == opcodes.WORLD_BOSS_RANK_S then
        local msg = WorldBoss_pb.HPBossHarmRank();
        msg:ParseFromString(msgBuff)
        local lastTime = 0
        if #allianceHarmInfos > 0 then
            lastTime = allianceHarmInfos[1].lastAttackTime
        end
        WorldBossManager.ReceiveHPBossHarmRank(msg, lastTime)

        self:refreshRankList(container)
        self:refreshMyContent(container)
        return
    end
    if opcode == opcodes.WORLD_BOSS_FAILING_S then
        local msg = WorldBoss_pb.HPBossFailingInfoRes();
        msg:ParseFromString(msgBuff)
        WorldBossManager.ReceiveBossFailing(msg)
        self:refreshFailing(container)
        return
    end

    if opcode == opcodes.WORLD_BOSS_REBIRTH_S then
        local msg = WorldBoss_pb.HPRebirthRet();
        msg:ParseFromString(msgBuff)
        WorldBossManager.ReceiveHPRebirthRet(msg)
        self:refreshRebirth(container)
        return
    end
end

function WorldBossPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function WorldBossPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local WorldBossPage = CommonPage.newSub(WorldBossPageBase, thisPageName, option)
return WorldBossPage