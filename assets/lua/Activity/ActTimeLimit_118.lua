-- -
-- 限定活动118  累計チャージ
-- -

local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper")
local thisPageName = "ActTimeLimit_118"
local thisActivityId = 118
local opcodes = {
    CONTINUE_RECHARGEMONEY_INFO_C = HP_pb.CONTINUE_RECHARGEMONEY_INFO_C,
    CONTINUE_RECHARGEMONEY_INFO_S = HP_pb.CONTINUE_RECHARGEMONEY_INFO_S,
    GET_CONTINUE_RECHARGEMONEY_AWARD_C = HP_pb.GET_CONTINUE_RECHARGEMONEY_AWARD_C,
    GET_CONTINUE_RECHARGEMONEY_AWARD_S = HP_pb.GET_CONTINUE_RECHARGEMONEY_AWARD_S
}
local option = {
    ccbiFile = "Act_TimeLimit_118_Content.ccbi",
    handlerMap =
    {
        -- onReturnButton	= "onBack",
        -- onRecharge		= "onRecharge",
        -- onHelp			= "onHelp"
    },
    opcode = opcodes
}

local Item = {
    ccbiFile = "Act_TimeLimit_118_ListContent.ccbi",
}

local ItemType = {
    CanReceive = 1,
    --  可领取
    Ing = 2,
    -- 进行中  未达成
    Complete = 3,-- 已完成

}

local ActTimeLimit_118 = {
    timerName = "ActTimeLimit_118",
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

function Item:onPreLoad(ccbRoot)

end

function Item:onUnLoad(ccbRoot)

end

function Item:onRewardBtn(container)
    if self.type == ItemType.CanReceive then
        local msg = Activity_pb.HPGetContinueRechargeMoneyAward()
        msg.awardCfgId = self.configData.id
        common:sendPacket(HP_pb.GET_CONTINUE_RECHARGEMONEY_AWARD_C, msg, true)
    elseif self.type == ItemType.Ing then
        -- 跳转到充值
       require("Recharge.RechargePage")
        RechargePageBase_SetCloseFunc( function()
            local msg = Activity_pb.HPContinueRechargeMoneyInfo()
            common:sendEmptyPacket(HP_pb.CONTINUE_RECHARGEMONEY_INFO_C, true)
        end )
        PageManager.pushPage("RechargePage")
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

    local btnTextStr = "@Receive"
    local fntPath = GameConfig.FntPath.Bule
    local btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage

    local isEnabled = false
    if self.type == ItemType.CanReceive then
        -- 可以领取
        btnTextStr = "@Receive"
        isEnabled = true
        fntPath = GameConfig.FntPath.Bule
        btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
    elseif self.type == ItemType.Complete then
        -- 已完成
        btnTextStr = "@ReceiveDone"
        fntPath = GameConfig.FntPath.Bule
        btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
    else
        -- 进行中 未达成条件
        isEnabled = true
        btnTextStr = "@MissionDay7_GoTo"
        fntPath = GameConfig.FntPath.Green
        btnNormalImage = GameConfig.CommonButtonImage.Green.NormalImage
    end

    NodeHelper:setMenuItemImage(self.container, { mRewardBtn = { normal = btnNormalImage } })
    NodeHelper:setBMFontFile(self.container, { mReceiveText = fntPath })

    NodeHelper:setMenuItemsEnabled(self.container, { mRewardBtn = isEnabled })
    NodeHelper:setNodeIsGray(self.container, { mReceiveText = not isEnabled })

    if Golb_Platform_Info.is_h365 then
        lb2Str["mRechargeRebateName"] = common:getLanguageString("@continueRechargeMoneyDesc", GameUtil:CNYToPlatformPrice(self.configData.count, "H365"))
    elseif Golb_Platform_Info.is_r18 then
        lb2Str["mRechargeRebateName"] = common:getLanguageString("@continueRechargeMoneyDesc54647", GameUtil:CNYToPlatformPrice(self.configData.count, "EROR18"))
    elseif Golb_Platform_Info.is_jgg then
        lb2Str["mRechargeRebateName"] = common:getLanguageString("@continueRechargeMoneyDescJGG", GameUtil:CNYToPlatformPrice(self.configData.count, "JGG"))
    end
    
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
            lb2Str["mNum" .. i] = "x" .. tostring(reward.count)
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

function ActTimeLimit_118.onFunction(eventName, container)
    if eventName == "onbuy" then

    end
end

function ActTimeLimit_118:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container

    self.container:registerFunctionHandler(ActTimeLimit_118.onFunction)
    self:registerPacket(ParentContainer)

    self:initData(container)
    self:initUi(container)

    -- 请求页面信息
    local msg = Activity_pb.HPContinueRechargeMoneyInfo()
    common:sendEmptyPacket(HP_pb.CONTINUE_RECHARGEMONEY_INFO_C, true)

    return self.container
end

function ActTimeLimit_118:initData(container)
    _ServerData = { }
    _ItemTable = { }
    _ConfigData = ConfigManager.getcontinueRechargeMoneyCfg()
end

function ActTimeLimit_118:initUi(container)
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

function ActTimeLimit_118:onExecute(container)
    if _ServerData == nil then
        return
    end

    local timeStr = "00:00:00"
    if TimeCalculator:getInstance():hasKey(ActTimeLimit_118.timerName) then
        _ServerData.surplusTime = TimeCalculator:getInstance():getTimeLeft(ActTimeLimit_118.timerName)
        if _ServerData.surplusTime > 0 then
            timeStr = common:second2DateString(_ServerData.surplusTime, false)
        end
        if _ServerData.surplusTime <= 0 then
            timeStr = common:getLanguageString("@ActivityEnd")
        end
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr })
    end
end

function ActTimeLimit_118:onExit(container)
    self:removePacket(container)
    ActTimeLimit_118.leftTime = 0
    _ServerData = { }
    onUnload(thisPageName, container)
end

-- 回包处理
function ActTimeLimit_118:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.CONTINUE_RECHARGEMONEY_INFO_S then
        local msg = Activity_pb.HPContinueRechargeMoneyInfoRet()
        msg:ParseFromString(msgBuff)
        _ServerData.continueRechargeTotal = msg.continueRechargeTotal or 0

        _ServerData.gotAwardCfgId = { }
        if msg.gotAwardCfgId then
            for i = 1, #msg.gotAwardCfgId do
                _ServerData.gotAwardCfgId[i] = msg.gotAwardCfgId[i]
            end
        end

        _ServerData.surplusTime = msg.surplusTime or 0
        self:clearAndReBuildAllItem(self.container)
        self:refreshPage(container)
    elseif opcode == opcodes.GET_CONTINUE_RECHARGEMONEY_AWARD_S then
        local msg = Activity_pb.HPGetContinueRechargeMoneyAwardRet()
        msg:ParseFromString(msgBuff)

        table.insert(_ServerData.gotAwardCfgId, msg.gotAwardCfgId)
        -- _ServerData.surplusTime = msg.surplusTime
        self:clearAndReBuildAllItem(self.container)
        self:refreshPage(container)
    end
end

function ActTimeLimit_118:refreshPage(container)

    NodeHelper:setNodesVisible(self.container, { mTexNode = true })
    local lb2Str = { }

    if _ServerData.surplusTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_118.timerName, _ServerData.surplusTime)
    else
        lb2Str.mTanabataCD = common:getLanguageString("@ActivityEnd")
    end

    lb2Str.mTxt1 = common:getLanguageString("@continueRechargeMoneyDescTop2")

    local count = _ServerData.continueRechargeTotal or 0
    if Golb_Platform_Info.is_h365 then
        lb2Str.mExpendAddUpTxt = common:getLanguageString("@continueRechargeMoneyDesc", GameUtil:CNYToPlatformPrice(count, "H365"))
    elseif Golb_Platform_Info.is_r18 then
        lb2Str.mExpendAddUpTxt = common:getLanguageString("@continueRechargeMoneyDesc54647", GameUtil:CNYToPlatformPrice(count, "EROR18"))
    elseif Golb_Platform_Info.is_jgg then
        lb2Str.mExpendAddUpTxt = common:getLanguageString("@continueRechargeMoneyDescJGG", GameUtil:CNYToPlatformPrice(count, "JGG"))
    end

    NodeHelper:setStringForLabel(self.container, lb2Str)
end

function ActTimeLimit_118:clearAndReBuildAllItem(container)
    -- TODO  后面改
    container.mScrollView:removeAllCell()
    local t = { }
    -- 可领取
    local t1 = { }
    -- 未达成
    local t2 = { }
    -- 已领取

    for k, v in pairs(_ConfigData) do
        local itemType = self:getItemType(v)
        if itemType == ItemType.CanReceive then
            -- 可领取
            table.insert(t, { type = itemType, configData = v })
        elseif itemType == ItemType.Ing then
            -- 未达成
            table.insert(t1, { type = itemType, configData = v })
        else
            -- 已经领取
            table.insert(t2, { type = itemType, configData = v })
        end
    end

    for i, v in pairs(t) do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { type = v.type, configData = v.configData })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end

    for i, v in pairs(t1) do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { type = v.type, configData = v.configData })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end

    for i, v in pairs(t2) do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { type = v.type, configData = v.configData })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end

    if #t == 0 then
        ActivityInfo.changeActivityNotice(thisActivityId)
    end

    container.mScrollView:orderCCBFileCells()
end

function ActTimeLimit_118:getItemType(data)
    local itemType = ItemType.Complete
    if _ServerData.continueRechargeTotal >= data.count and not self:isContainId(data.id) then
        -- 可领取
        itemType = ItemType.CanReceive
    elseif _ServerData.continueRechargeTotal < data.count and not self:isContainId(data.id) then
        -- 未达成
        itemType = ItemType.Ing
    else
        -- 已经领取  已完成
        itemType = ItemType.Complete
    end

    return itemType
end

function ActTimeLimit_118:isContainId(id)
    local bl = false
    for i = 1, #_ServerData.gotAwardCfgId do
        if _ServerData.gotAwardCfgId[i] == id then
            bl = true
        end
    end

    return bl
end

function ActTimeLimit_118:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_118:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

return ActTimeLimit_118