local NodeHelper = require("NodeHelper")
local thisPageName = "SingleBossSubPage_Main"
local HP_pb = require("HP_pb")
local Battle_pb = require("Battle_pb")
local Activity5_pb = require("Activity5_pb")
local SingleBossDataMgr = require("SingleBoss.SingleBossDataMgr")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local CommItem = require("CommUnit.CommItem")
require("NewBattleConst")

local SingleBossPageBase = { }

local RewardItems = { }

local option = {
    ccbiFile = "SingleBoss.ccbi",
    handlerMap = {
        onSimulator = "onSimulator",
        onChallange = "onChallange",
        onHelp = "onHelp",
        onQuest = "onQuest",
        onShop = "onShop",
        onRewardDetail = "onRewardDetail",
    }
}
for i = 1, 8 do
    option.handlerMap["onStage" .. i] = "onStage"
end
for i = 1, 3 do
    option.handlerMap["onSkill" .. i] = "onSkill"
end

local parentPage = nil
local nowStage = 0
local singleBossCfg = ConfigManager.getSingleBoss()
local data = SingleBossDataMgr:getPageData()
local SKILL_BG_WIDTH = 292
local SKILL_BG_HEIGHT = 88
local SKILL_ICON_DIS = 95

local opcodes = {
    ACTIVITY193_SINGLE_BOSS_S = HP_pb.ACTIVITY193_SINGLE_BOSS_S,
    BATTLE_FORMATION_S = HP_pb.BATTLE_FORMATION_S,
}
-------------------- scrollview item --------------------------------
local SingleBossRewardContent = {
    ccbiFile = "CommItem.ccbi",
}

function SingleBossRewardContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function SingleBossRewardContent:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh(self.container)
end

function SingleBossRewardContent:refresh(container)
    if container == nil then
        return
    end
    -- 獎勵道具
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.reward.type, self.reward.itemId, self.reward.count)
    local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
    local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
    NodeHelper:setMenuItemImage(container, { mHand1 = { normal = normalImage } })
    NodeHelper:setSpriteImage(container, { mPic1 = resInfo.icon, mFrameShade1 = iconBg })
    NodeHelper:setStringForLabel(container, { mNumber1_1 = self.reward.count })
    NodeHelper:setNodesVisible(container, { selectedNode = false, mPoint = false, nameBelowNode = false, mStarNode = false, mAncientStarNode = false })
end

function SingleBossRewardContent:onHand1(container)
    GameUtil:showTip(container:getVarNode("mPic1"), self.reward)
end
--
function SingleBossPageBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 建立頁面UI ]]
function SingleBossPageBase:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container,eventName)
        end
    end)
    
    return container
end

function SingleBossPageBase:onEnter(container)
    self.container = container
    parentPage:registerPacket(opcodes)
    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())
    local GuideManager = require("Guide.GuideManager")
    if not GuideManager.isInGuide then
       container:runAnimation("OpenAni")
    end
    -- 背景Spine
    local bgParent = self.container:getVarNode("mBgNode")
    bgParent:removeAllChildrenWithCleanup(true)
    local bgSpine = SpineContainer:create("Spine/NGUI", "NGUI_94_soloenemy")
    local bgSpineNode = tolua.cast(bgSpine, "CCNode")
    bgParent:addChild(bgSpineNode)
    bgSpine:setToSetupPose()
    bgSpine:runAnimation(1, "animation2", -1)
    bgSpineNode:setScale(NodeHelper:getTargetScaleProportion(1600, 720))

    NodeHelper:setNodesVisible(container, { mSkillNode = false, mBossNameTxt = false, mChallangeTimeTxt = false, 
                                            mTimeTxt = false, mHpTxt = false  })
    if data.dataDirtyBase then
        nowStage = 0
        self:InfoReq()
    else
        if nowStage <= 0 then
            nowStage = data.maxStage
        end
        self:refreshPage(self.container)
        self:initBoss(self.container)
        require("TransScenePopUp")
        TransScenePopUp_closePage(0.25)
    end
    local PageJumpMange = require("PageJumpMange")
    if PageJumpMange._IsPageJump then
        PageJumpMange._IsPageJump = false
    end
end

function SingleBossPageBase:onSimulator(container)
    local msg = Battle_pb.NewBattleFormation()
    msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
    msg.battleType = NewBattleConst.SCENE_TYPE.SINGLE_BOSS_SIM
    msg.mapId = tostring(nowStage)

    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
end

function SingleBossPageBase:onChallange(container)
    local msg = Battle_pb.NewBattleFormation()
    msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
    msg.battleType = NewBattleConst.SCENE_TYPE.SINGLE_BOSS
    msg.mapId = tostring(nowStage)

    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
end

function SingleBossPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_SINGLE_BOSS)
end	

function SingleBossPageBase:onRewardDetail(container)
    data.popType = SingleBossDataMgr.PopPageType.STAGE_REWARD
    data.popStage = nowStage
    PageManager.pushPage("SingleBoss.SingleBossPopPage")
end	

function SingleBossPageBase:onQuest(container)
    data.popType = SingleBossDataMgr.PopPageType.MISSION
    data.popStage = nowStage
    PageManager.pushPage("SingleBoss.SingleBossPopPage")
end	

function SingleBossPageBase:onShop(container)
	PageManager.pushPage("ShopControlPage")
end	

function SingleBossPageBase:onExit(container)

end
function SingleBossPageBase:onExecute(container)
    if data.activityEndTime then
        local leftTime = data.activityEndTime - os.time()
        if leftTime < 0 then
            local str = common:getLanguageString("@ERRORCODE_80104")
            NodeHelper:setStringForLabel(container, { mTimeTxt = str })
        else
            local d = math.floor(leftTime / 86400)
            leftTime = leftTime - 86400 * d
            local h = math.floor(leftTime / 3600)
            leftTime = leftTime - 3600 * h
            local m = math.floor(leftTime / 60)
            leftTime = leftTime - 60 * m
            local s = leftTime
            local time = common:getLanguageString("@CountdownTime1", d, h, m)
            local str = common:getLanguageString("@SingleBossEndTime", time)
            NodeHelper:setStringForLabel(container, { mTimeTxt = str })
        end
    else
        local str = common:getLanguageString("@ERRORCODE_80104")
        NodeHelper:setStringForLabel(container, { mTimeTxt = str })
    end
end

function SingleBossPageBase:onStage(container, eventName)
    local idx = string.sub(eventName, -1)
    idx = (tonumber(idx) == 8) and 999 or tonumber(idx)
    if nowStage == tonumber(idx) then
        return
    end
    if tonumber(idx) > data.maxStage then
        MessageBoxPage:Msg_Box(common:getLanguageString("@SevenDayQuestDay2Desc"))
        return
    end
	nowStage = idx
    self:refreshPage(container)
end	


function SingleBossPageBase:onSkill(container, eventName)
    local cfg = singleBossCfg[nowStage]
    if not cfg then
        return
    end
    local idx = string.sub(eventName, -1)
    local skillId = cfg["skill" .. string.format("%02d", tonumber(idx))]
    if skillId and skillId > 0 then
        GameUtil:showSkillTip(container:getVarNode("mSkillBtn" .. idx), skillId)
    end
end	

function SingleBossPageBase:initBoss(container)
    local spineParent = container:getVarNode("mBossNode")
    spineParent:removeAllChildrenWithCleanup(true)
    local cfg = singleBossCfg[nowStage]
    if not cfg then
        return
    end
    local spinePath, spineFile = unpack(common:split(cfg.BossSpine, ","))
    local x, y, scale = unpack(common:split(cfg.Trans, ","))
    local spine = SpineContainer:create(spinePath, spineFile)
    local spineNode = tolua.cast(spine, "CCNode")
    spineNode:setPosition(ccp(tonumber(x), tonumber(y)))
    spineNode:setScale(tonumber(scale))
    spineParent:addChild(spineNode)
    spine:runAnimation(1, "wait_0", -1)

    local monsterIds = common:split(cfg.monsterIds, ",")
    for i = 1, #monsterIds do
        if cfg.BossId == tonumber(monsterIds[i]) then
            NgBattleDataManager.SingleBossBarIdx = i - 1
            break
        end
    end
end

function SingleBossPageBase:refreshPage(container)
    local cfg = singleBossCfg[nowStage]
    local monsterCfg = ConfigManager.getNewMonsterCfg()[cfg.BossId]
    local visible = { }
    local str = { }
    -- 難度按鈕狀態
    for i = 1, 8 do
        visible["mStageNode" .. i] = (i <= data.maxStage)
        visible["mStageSelect" .. i] = (i == 8) and (nowStage == 999) or (nowStage == i)
    end
    -- 活動資訊
    if nowStage == 999 then
        str["mHpTxt"] = "∞"
    else
        local hp = monsterCfg and GameUtil:formatDotNumber(monsterCfg.Hp) or 0
        str["mHpTxt"] = hp .. "/" .. hp
    end
    str["mBossNameTxt"] = common:getLanguageString(cfg.BossName)
    str["mChallangeTimeTxt"] = common:getLanguageString("@SingleBosscount", data.challangeTime)
    -- 技能icon
    local skillNum = 0
    for i = 1, 3 do
        local skillId = cfg["skill" .. string.format("%02d", tonumber(i))]
        if skillId and skillId > 0 then
            visible["mSkillBtn" .. i] = true
            skillNum = skillNum + 1
            NodeHelper:setNormalImage(container, "mSkillImg" .. i, "S_" .. math.floor(skillId / 10) .. ".png")
        else
            visible["mSkillBtn" .. i] = false
        end
    end
    visible["mSkillBg"] = (skillNum > 0)
    local skillBg = container:getVarScale9Sprite("mSkillBg")
    skillBg:setContentSize(CCSize(SKILL_BG_WIDTH - (3 - skillNum) * SKILL_ICON_DIS, SKILL_BG_HEIGHT))
    -- 獎勵預覽
    local Scrollview = container:getVarScrollView("mContent")
    Scrollview:removeAllCell()
    local rewards = { }
    for i = 1, 99 do
        if not cfg["stageReward" .. i] then
            break
        end
        rewards = common:split(cfg["stageReward" .. i], ",")
    end
    local sHeight = Scrollview:getViewSize().height
    local sWidth = Scrollview:getViewSize().width
    for i = 1, #rewards do
        local cell = CCBFileCell:create()
        local handler = common:new({ id = i, reward = common:parseItemWithComma(rewards[i])[1] }, SingleBossRewardContent)
        cell:registerFunctionHandler(handler)
        cell:setCCBFile(SingleBossRewardContent.ccbiFile)
        local cHeight = cell:getContentSize().height
        local scale = sHeight / cHeight
        cell:setContentSize(CCSize(cHeight * scale, cHeight * scale))
        cell:setScale(scale)
        Scrollview:addCellBack(cell)
    end
    Scrollview:orderCCBFileCells()
    Scrollview:setTouchEnabled(#rewards > math.floor(sWidth / sHeight))
    --
    visible["mSkillNode"] = true
    visible["mBossNameTxt"] = true
    visible["mChallangeTimeTxt"] = true
    visible["mTimeTxt"] = true
    visible["mHpTxt"] = true
    --
    NodeHelper:setNodesVisible(container, visible)
    NodeHelper:setStringForLabel(container, str)
end

function SingleBossPageBase:InfoReq()
    local msg = Activity5_pb.SingleBossReq()
    msg.action = SingleBossDataMgr.ProtoAction.SYNC_INFO
    common:sendPacket(HP_pb.ACTIVITY193_SINGLE_BOSS_C, msg, true)
end

function SingleBossPageBase:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.ACTIVITY193_SINGLE_BOSS_S then
        data.dataDirtyBase = false
        --
        local msg = Activity5_pb.SingleBossResp()
        msg:ParseFromString(msgBuff)
        if msg.action == SingleBossDataMgr.ProtoAction.SYNC_INFO then
            local baseInfo = msg.baseInfo
            if baseInfo then
                data.maxStage = baseInfo.maxClearStage
                data.maxScore = baseInfo.maxScore
                data.activityEndTime = baseInfo.endTime / 1000
                data.challangeTime = baseInfo.count
            end
            SingleBossData.questData = msg.questInfo
            if nowStage <= 0 then
                nowStage = data.maxStage
            end
            self:refreshPage(self.container)
            self:initBoss(self.container)
            require("TransScenePopUp")
            TransScenePopUp_closePage()
        end
    elseif opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            local battlePage = require("NgBattlePage")
            resetMenu("mBattlePageBtn", true)
            require("NgBattleDataManager")
            PageManager.changePage("NgBattlePage")
            if msg.battleType == NewBattleConst.SCENE_TYPE.SINGLE_BOSS then
                battlePage:onSingleBoss(self.container, msg.resultInfo, msg.battleId, msg.battleType, tonumber(msg.mapId))
            elseif msg.battleType == NewBattleConst.SCENE_TYPE.SINGLE_BOSS_SIM then
                battlePage:onSingleBossSim(self.container, msg.resultInfo, msg.battleId, msg.battleType, nowStage)
            end
        end
    end
end

function SingleBossPageBase:onReceiveMessage(message)
    local typeId = message:getTypeId()
end

return SingleBossPageBase
