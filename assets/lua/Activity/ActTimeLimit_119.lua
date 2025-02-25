-- -
-- 限定活动119  消費還元
-- -

local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper")
local thisPageName = "ActTimeLimit_119"
local thisActivityId = 119
local opcodes = {
    ACC_CONSUMEITEM_INFO_C = HP_pb.ACC_CONSUMEITEM_INFO_C,
    ACC_CONSUMEITEM_INFO_S = HP_pb.ACC_CONSUMEITEM_INFO_S,
    GET_ACC_CONSUMEITEM_AWARD_C = HP_pb.GET_ACC_CONSUMEITEM_AWARD_C,
    GET_ACC_CONSUMEITEM_AWARD_S = HP_pb.GET_ACC_CONSUMEITEM_AWARD_S
}
local option = {
    ccbiFile = "Act_TimeLimit_119_Content.ccbi",
    handlerMap =
    {
        -- onReturnButton	= "onBack",
        -- onRecharge		= "onRecharge",
        -- onHelp			= "onHelp"
    },
    opcode = opcodes
}

local Item = {
    ccbiFile = "Act_TimeLimit_119_ListContent.ccbi",
}

local ActTimeLimit_119 = {
    timerName = "ActTimeLimit_119",
    leftTime = 0,
}

local _ConfigData = { }

local _ServerData = nil

local _ItemTable = { }

function Item:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item:onRewardBtn(container)
    if self.isCanReward then
        local msg = Activity_pb.HPGetAccConsumeItemAward()
        msg.goodid = self.serverData.goodId
        common:sendPacket(HP_pb.GET_ACC_CONSUMEITEM_AWARD_C, msg, true)
    else
        MainFrame_onEquipmentPageBtn()

        --local PageJumpMange = require("PageJumpMange")
        --PageJumpMange.JumpPageById(25)
    end
end

function Item:onFrame1(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local data = _ConfigData[self.configData.id]

    if data and data.rewards[1] then
        GameUtil:showTip(container:getVarNode("mPic1"), data.rewards[1])
    end
end

function Item:onFrame2(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local data = _ConfigData[self.configData.id]

    if data and data.rewards[2] then
        GameUtil:showTip(container:getVarNode("mPic2"), data.rewards[2])
    end
end

function Item:onFrame3(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local data = _ConfigData[self.configData.id]

    if data and data.rewards[3] then
        GameUtil:showTip(container:getVarNode("mPic3"), data.rewards[3])
    end
end

function Item:onFrame4(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local data = _ConfigData[self.configData.id]

    if data and data.rewards[4] then
        GameUtil:showTip(container:getVarNode("mPic4"), data.rewards[4])
    end
end

function Item:refresh()

    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }
    local colorMap = { }

    local fntPath = GameConfig.FntPath.Bule
    local btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage

    local currentCount = math.abs(self.serverData.buyTime - self.serverData.prizeTime)
    local getCount = math.modf(self.serverData.prizeTime / self.configData.count)

    local btnTextStr = "@Receive"
    if currentCount >= self.configData.count then
        self.isCanReward = true
        btnTextStr = "@Receive"
        -- 领取用蓝色吧
        fntPath = GameConfig.FntPath.Bule
        btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
    else
        self.isCanReward = false
        btnTextStr = "@MissionDay7_GoTo"
        -- 移动用绿色吧
        fntPath = GameConfig.FntPath.Green
        btnNormalImage = GameConfig.CommonButtonImage.Green.NormalImage
    end

    NodeHelper:setMenuItemImage(self.container, { mRewardBtn = { normal = btnNormalImage } })
    NodeHelper:setBMFontFile(self.container, { mReceiveText = fntPath })

    lb2Str["mReceiveText"] = common:getLanguageString(btnTextStr)
    lb2Str["mRechargeRebateName"] = common:getLanguageString(self.configData.des, self.configData.count) .. "(" .. currentCount .. "/" .. self.configData.count .. ")"
    -- lb2Str["mGetCountText"] = common:getLanguageString("@AccConsumeItemRewardDesc2", getCount)
    lb2Str["mGetCountText"] = ""
    lb2Str["mReceiveText"] = common:getLanguageString(btnTextStr)
    local rewards = self.configData.rewards
    for i = 1, 4 do
        local reward = rewards[i]
        if reward then
            visibleMap["mRewardNode" .. i] = true
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(reward.type, reward.itemId, reward.count)

            sprite2Img["mPic" .. i] = resInfo.icon
            sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality)
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

    NodeHelper:setNodesVisible(self.container, visibleMap)
    NodeHelper:setStringForLabel(self.container, lb2Str)
    NodeHelper:setSpriteImage(self.container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(self.container, menu2Quality)
    NodeHelper:setColorForLabel(self.container, colorMap)
end

function Item:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh()
end

function ActTimeLimit_119.onFunction(eventName, container)
    if eventName == "onbuy" then

    end
end

function ActTimeLimit_119:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container

    self.container:registerFunctionHandler(ActTimeLimit_119.onFunction)
    self:registerPacket(ParentContainer)

    self:initData(container)
    self:initUi(container)

    -- 请求页面信息
    local msg = Activity_pb.HPAccConsumeItemInfo()
    common:sendEmptyPacket(HP_pb.ACC_CONSUMEITEM_INFO_C, true)

    return self.container
end

function ActTimeLimit_119:initData(container)
    _ItemTable = { }
    _ConfigData = ConfigManager.getaccConsumeItemRewardCfg()
end

function ActTimeLimit_119:initUi(container)
    NodeHelper:setNodesVisible(container, { mTexNode = false })

    container.scrollview = container:getVarScrollView("mContent")
    if container.scrollview ~= nil then
        NodeHelper:autoAdjustResizeScrollview(container.scrollview)
    end
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
    if mScale9Sprite ~= nil then
        NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite)
    end

    NodeHelper:initScrollView(container, "mContent", 3)

end

function ActTimeLimit_119:onExecute(container)
    if _ServerData == nil then
        return
    end

    local timeStr = "00:00:00"
    if TimeCalculator:getInstance():hasKey(ActTimeLimit_119.timerName) then
        _ServerData.surplusTime = TimeCalculator:getInstance():getTimeLeft(ActTimeLimit_119.timerName)
        if _ServerData.surplusTime > 0 then
            timeStr = common:second2DateString(_ServerData.surplusTime, false)
        end
        if _ServerData.surplusTime <= 0 then
            timeStr = common:getLanguageString("@ActivityEnd")
        end
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr })
    end
end

function ActTimeLimit_119:onExit(container)
    self:removePacket(container)
    ActTimeLimit_119.leftTime = 0
    _ServerData = { }
    onUnload(thisPageName, container)
end

-- 回包处理
function ActTimeLimit_119:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.ACC_CONSUMEITEM_INFO_S then
        local msg = Activity_pb.HPAccConsumeItemInfoRet()
        msg:ParseFromString(msgBuff)
        _ServerData = msg

        self:clearAndReBuildAllItem(self.container)
        self:refreshPage(container)
    elseif opcode == opcodes.GET_ACC_CONSUMEITEM_AWARD_S then
        local msg = Activity_pb.HPGetAccConsumeItemAwardRet()
        msg:ParseFromString(msgBuff)

        if msg.state == 1 then
            for k, v in pairs(_ServerData.item) do
                if v.goodId == msg.item.goodId then
                    v.goodId = msg.item.goodId
                    v.buyTime = msg.item.buyTime
                    v.prizeTime = msg.item.prizeTime
                    break
                end
            end
            self:clearAndReBuildAllItem(self.container)
        end
    end
end

function ActTimeLimit_119:refreshPage(container)
    NodeHelper:setNodesVisible(self.container, { mTexNode = true })
    local lb2Str = { }

    if _ServerData.surplusTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_119.timerName, _ServerData.surplusTime)
    else
        lb2Str.mTanabataCD = common:getLanguageString("@ActivityEnd")
    end

    lb2Str.mExpendAddUpTxt = ""

    lb2Str.mTxt1 = common:getLanguageString("@AccConsumeItemRewardDesc")

    NodeHelper:setStringForLabel(self.container, lb2Str)
end

function ActTimeLimit_119:clearAndReBuildAllItem(container)
    -- TODO  后面改成直接重新复制刷新
    container.mScrollView:removeAllCell()
    local t = { }
    local t1 = { }
    for i, v in pairs(_ConfigData) do
        local sData = self:getServerItemDataById(v.id)

        local currentCount = math.abs(sData.buyTime - sData.prizeTime)
        -- local getCount = math.modf(sData.prizeTime / v.count)

        if currentCount >= v.count then
            -- 可以领取
            table.insert(t, { configData = v, serverData = sData })
        else
            -- 不能领取
            table.insert(t1, { configData = v, serverData = sData })
        end
    end

    table.sort(t, function(data1, data2)
        if data1 and data2 then
            return data1.configData.id < data2.configData.id
        else
            return false
        end
    end )

    table.sort(t1, function(data1, data2)
        if data1 and data2 then
            return data1.configData.id < data2.configData.id
        else
            return false
        end
    end )


    for i, v in pairs(t) do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { configData = v.configData, serverData = v.serverData })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end

    for i, v in pairs(t1) do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { configData = v.configData, serverData = v.serverData })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end

    if #t == 0 then
        ActivityInfo.changeActivityNotice(thisActivityId)
    end
    --    _ItemTable = { }
    --    container.mScrollView:removeAllCell()
    --    for i, v in pairs(_ConfigData) do
    --        local titleCell = CCBFileCell:create()
    --        local panel = Item:new( { configData = v, serverData = self:getServerItemDataById(v.id) })
    --        titleCell:registerFunctionHandler(panel)
    --        titleCell:setCCBFile(Item.ccbiFile)
    --        container.mScrollView:addCellBack(titleCell)
    --        _ItemTable[v.id] = panel
    --    end
    container.mScrollView:orderCCBFileCells()

    --    if _ItemTable == nil or common:getTableLen(_ItemTable) == 0 then
    --        container.mScrollView:removeAllCell()
    --        for i, v in pairs(_ConfigData) do
    --            local titleCell = CCBFileCell:create()
    --            local panel = Item:new( { configData = v, serverData = self:getServerItemDataById(v.id) })
    --            titleCell:registerFunctionHandler(panel)
    --            titleCell:setCCBFile(Item.ccbiFile)
    --            container.mScrollView:addCellBack(titleCell)

    --            table.insert(_ItemTable, v.id, panel)
    --        end
    --        container.mScrollView:orderCCBFileCells()
    --    end

    --    for var in list do

    --    end
end

function ActTimeLimit_119:getServerItemDataById(id)
    for i = 1, #_ServerData.item do
        if _ServerData.item[i].goodId == id then
            local a = _ServerData.item[i].goodId
            local b = _ServerData.item[i].buyTime
            local c = _ServerData.item[i].prizeTime
            return _ServerData.item[i]
        end
    end
end

function ActTimeLimit_119:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_119:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

return ActTimeLimit_119