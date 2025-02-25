-- -
-- 消费有礼    奖学金
-- -

local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper");
local thisPageName = "ExpendAddUpPage"

local opcodes = {
    ACC_CONSUME_INFO_C = HP_pb.ACC_CONSUME_INFO_C,
    ACC_CONSUME_INFO_S = HP_pb.ACC_CONSUME_INFO_S,
    GET_ACC_CONSUME_AWARD_C = HP_pb.GET_ACC_CONSUME_AWARD_C,
    GET_ACC_CONSUME_AWARD_S = HP_pb.GET_ACC_CONSUME_AWARD_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
};
local option = {
    ccbiFile = "Act_TimeLimitExpendAddUpContent.ccbi",
    handlerMap =
    {
        -- onReturnButton	= "onBack",
        -- onRecharge		= "onRecharge",
        -- onHelp			= "onHelp"
    },
    opcode = opcodes
};

local ExpendAddContent = {
    ccbiFile = "Act_TimeLimitExpendAddUpListContent.ccbi",
    rewardIds = { }
}

local ExpendAddUpPage = {
    timerName = "ExpendAddUpPage",
    leftTime = 0,
    leftTimes = { },
}

local ExpendConfig = { }

local removeNotice = true

local sendReward = false

local accInfo = { }

function ExpendAddContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- siq
function ExpendAddContent:onRewardBtn(container)
    if sendReward then return end
    sendReward = true
    local msg = Activity_pb.HPGetAccConsumeAward();
    msg.awardCfgId = self.id
    common:sendPacket(opcodes.GET_ACC_CONSUME_AWARD_C, msg, false);
end

function ExpendAddContent:onFrame1(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local id = self.id
    local index = self.index
    local data = ExpendConfig[index]

    if data and data.rewards[1] then
        GameUtil:showTip(container:getVarNode('mPic1'), data.rewards[1])
    end
end

function ExpendAddContent:onFrame2(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local id = self.id
    local index = self.index
    local data = ExpendConfig[index]

    if data and data.rewards[2] then
        GameUtil:showTip(container:getVarNode('mPic2'), data.rewards[2])
    end
end

function ExpendAddContent:onFrame3(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local id = self.id
    local index = self.index
    local data = ExpendConfig[index]

    if data and data.rewards[3] then
        GameUtil:showTip(container:getVarNode('mPic3'), data.rewards[3])
    end
end

function ExpendAddContent:onFrame4(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local id = self.id
    local index = self.index
    local data = ExpendConfig[index]

    if data and data.rewards[4] then
        GameUtil:showTip(container:getVarNode('mPic4'), data.rewards[4])
    end
end

function ExpendAddContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local data = ExpendConfig[index]

    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }
    local colorMap = { }
    if data then
        -- NodeHelper:fillRewardItem(container,data.rewards,1)
        lb2Str.mRechargeRebateName = common:getLanguageString("@ExpendAddUpName", data.cost)

        local colorStr = "124 67 5"
        --NodeHelper:setColorForLabel(container, { mRechargeRebateName = colorStr })


        local rewards = data.rewards
        for i = 1, 4 do
            local reward = rewards[i]
            if reward then
                visibleMap["mRewardNode" .. i] = true
                local resInfo = ResManagerForLua:getResInfoByTypeAndId(reward.type, reward.itemId, reward.count);

                sprite2Img["mPic" .. i] = resInfo.icon;
                sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
                menu2Quality["mFrame" .. i] = resInfo.quality
                lb2Str["mNum" .. i] = tostring(reward.count)
                lb2Str["mName" .. i] = resInfo.name

                -- colorMap["mNum" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                colorMap["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor

                if resInfo.iconScale then
                    scaleMap["mPic .. i"] = resInfo.iconScale
                end
            else
                visibleMap["mRewardNode" .. i] = false
            end
        end

        local fntPath = GameConfig.FntPath.Bule
        local btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage

        local visible = true
        -- visibleMap["mVIPBuyTxt"] = UserInfo.roleInfo.level < data.level
        if accInfo.accConsumeGold >= data.cost then
            if ExpendAddContent.rewardIds[self.id] then
                lb2Str["mReceiveText"] = common:getLanguageString("@AlreadyReceive")
                visible = false
                -- NodeHelper:setMenuItemEnabled(container, "mRewardBtn", false)
                -- NodeHelper:setNodeIsGray(container, { mReceiveText = true })

                fntPath = GameConfig.FntPath.Bule
                btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage

            else
                visible = true
                lb2Str["mReceiveText"] = common:getLanguageString("@CanReceive")
                -- NodeHelper:setMenuItemEnabled(container, "mRewardBtn", true)
                -- NodeHelper:setNodeIsGray(container, { mReceiveText = false })
                fntPath = GameConfig.FntPath.Bule
                btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
            end
        else
            visible = false
            lb2Str["mReceiveText"] = common:getLanguageString("@CanReceive")
            -- NodeHelper:setMenuItemEnabled(container, "mRewardBtn", false)
            -- NodeHelper:setNodeIsGray(container, { mReceiveText = true })
            fntPath = GameConfig.FntPath.Bule
            btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
        end

        NodeHelper:setMenuItemImage(container, { mRewardBtn = { normal = btnNormalImage } })
        NodeHelper:setBMFontFile(container, { mReceiveText = fntPath })

        NodeHelper:setMenuItemEnabled(container, "mRewardBtn", visible)
        NodeHelper:setNodeIsGray(container, { mReceiveText = not visible })

    end

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setColorForLabel(container, colorMap)
end

function ExpendAddUpPage.onFunction(eventName, container)
    if eventName == "onbuy" then

    end
end

function ExpendAddUpPage:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container

    NodeHelper:setNodesVisible(container, { mTexNode = false })

    ExpendConfig = ConfigManager.getExpendAddUpCfg()

    container.scrollview = container:getVarScrollView("mContent");
    if container.scrollview ~= nil then
        ParentContainer:autoAdjustResizeScrollview(container.scrollview);
    end
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
    if mScale9Sprite ~= nil then
        ParentContainer:autoAdjustResizeScale9Sprite(mScale9Sprite)
    end

    NodeHelper:initScrollView(container, "mContent", 3);

    self.container:registerFunctionHandler(ExpendAddUpPage.onFunction)
    self:registerPacket(ParentContainer)
    common:sendEmptyPacket(HP_pb.ACC_CONSUME_INFO_C, true)

    -- self:clearAndReBuildAllItem(container)

    return self.container
end

function ExpendAddUpPage:onExecute(container)
    local timeStr = '00:00:00'
    if TimeCalculator:getInstance():hasKey(ExpendAddUpPage.timerName) then
        ExpendAddUpPage.closeTimes = TimeCalculator:getInstance():getTimeLeft(ExpendAddUpPage.timerName)
        if ExpendAddUpPage.closeTimes > 0 then
            timeStr = common:second2DateString(ExpendAddUpPage.closeTimes, false)
        end
        if ExpendAddUpPage.closeTimes <= 0 then
            timeStr = common:getLanguageString("@ActivityEnd")
        end
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr })
    end
end

function ExpendAddUpPage:onExit(container)
    self:removePacket(container)
    ExpendAddUpPage.leftTime = 0
    sendReward = false
    removeNotice = true
    ExpendAddContent.rewardIds = { }
    accInfo = { }
    onUnload(thisPageName, container);
end

-- 回包处理
function ExpendAddUpPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == opcodes.ACC_CONSUME_INFO_S then
        local msg = Activity_pb.HPAccConsumeInfoRet()
        msg:ParseFromString(msgBuff)
        accInfo = msg

        ExpendAddContent.rewardIds = { }
        for i = 1, #msg.gotAwardCfgId do
            ExpendAddContent.rewardIds[msg.gotAwardCfgId[i]] = 1
        end

        table.sort(ExpendConfig, function(a, b)
            if not ExpendAddContent.rewardIds[a.id] then
                if not ExpendAddContent.rewardIds[b.id] then
                    return a.id < b.id
                else
                    return true
                end
            end
            if not ExpendAddContent.rewardIds[b.id] then return false end
            return a.id < b.id
        end )

        self:clearAndReBuildAllItem(self.container)

        removeNotice = true
        for i, v in ipairs(ExpendConfig) do
            if not ExpendAddContent.rewardIds[v.id] then
                if accInfo.accConsumeGold >= v.cost then
                    removeNotice = false
                    break
                end
            end
        end

        if removeNotice then
            ActivityInfo.changeActivityNotice(Const_pb.ACCUMULATIVE_CONSUME)
        end
        ExpendAddUpPage.leftTime = msg.surplusTime
        self:refreshPage(container)
    elseif opcode == opcodes.GET_ACC_CONSUME_AWARD_S then
        local msg = Activity_pb.HPGetAccConsumeAwardRet()
        msg:ParseFromString(msgBuff)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        if sendReward then
            sendReward = false
            common:sendEmptyPacket(HP_pb.ACC_CONSUME_INFO_C, true)
        end
    end
end

function ExpendAddUpPage:refreshPage(container)
    NodeHelper:setNodesVisible(self.container, { mTexNode = true })
    local lb2Str = { }
    if ExpendAddUpPage.leftTime > 0 then
        lasttime = ExpendAddUpPage.leftTime
        TimeCalculator:getInstance():createTimeCalcultor(ExpendAddUpPage.timerName, ExpendAddUpPage.leftTime);
    else
        lb2Str.mTanabataCD = common:getLanguageString("@ActivityEnd")
    end
    lb2Str.mExpendAddUpTxt = common:getLanguageString("@ExpendAddUpTxt", accInfo.accConsumeGold)

    NodeHelper:setStringForLabel(self.container, lb2Str)
end

function ExpendAddUpPage:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    for i, v in ipairs(ExpendConfig) do
        local titleCell = CCBFileCell:create()
        local panel = ExpendAddContent:new( { id = v.id, index = i })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(ExpendAddContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
end

function ExpendAddUpPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ExpendAddUpPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


return ExpendAddUpPage