-- 成长基金
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "GrowthFundPage"
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")

local GrowthFundPage = {
    bought = false
}

local GrowthFundContent = {
    ccbiFile = "Act_FixedTimeGrowthFundListContent.ccbi",
    rewardIds = { }
}

local opcodes = {
    GROWTH_FUND_INFO_S = HP_pb.GROWTH_FUND_INFO_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    GROWTH_FUND_GET_REWARD_C = HP_pb.GROWTH_FUND_GET_REWARD_C,
    GROWTH_FUND_BUY_S = HP_pb.GROWTH_FUND_BUY_S
}

local growthFundCfg = { }

local removeNotice = true

local sendReward = false

function GrowthFundContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- siq
function GrowthFundContent:onbuy(container)
    if sendReward then
        return
    end
    sendReward = true
    local msg = Activity2_pb.HPGetGrowthFundRewardReq()
    msg.rewardId = self.id
    common:sendPacket(opcodes.GROWTH_FUND_GET_REWARD_C, msg, false)
end

function GrowthFundContent:onHand(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local id = self.id
    local data = growthFundCfg[id]

    if data then
        GameUtil:showTip(container:getVarNode("mPic"), data.rewards[1])
    end
end

function GrowthFundContent:onPreLoad(ccbRoot)

end

function GrowthFundContent:onUnLoad(ccbRoot)

end

function GrowthFundContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local data = growthFundCfg[index]

    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }
    local colorMap = { }

    if data then
        -- NodeHelper:fillRewardItem(container,data.rewards,1)
        local rewards = data.rewards[1]
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(rewards.type, rewards.itemId, rewards.count)

        sprite2Img["mPic"] = resInfo.icon
        sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(resInfo.quality)
        menu2Quality["mHand"] = resInfo.quality
        lb2Str["mNumber"] = tostring(rewards.count)
        lb2Str["mVIPBuyTxt"] = common:getLanguageString("@GrowthFundGetLimitTxt", data.level)

        --colorMap["mNumber"] = ConfigManager.getQualityColor()[resInfo.quality].textColor
        colorMap["mVIPBuyTxt"] = ConfigManager.getQualityColor()[resInfo.quality].textColor

        -- visibleMap["mVIPBuyTxt"] = UserInfo.roleInfo.level < data.level
        if GrowthFundPage.bought then
            if UserInfo.roleInfo.level < data.level then
                NodeHelper:setMenuItemEnabled(container, "mGetBtn", false)
                NodeHelper:setNodeIsGray(container, { mVIPBuy = true })
                lb2Str["mVIPBuy"] = common:getLanguageString("@CanReceive")
            else
                if GrowthFundContent.rewardIds[self.id] then
                    lb2Str["mVIPBuy"] = common:getLanguageString("@AlreadyReceive")
                    NodeHelper:setMenuItemEnabled(container, "mGetBtn", false)
                    NodeHelper:setNodeIsGray(container, { mVIPBuy = true })
                else
                    lb2Str["mVIPBuy"] = common:getLanguageString("@CanReceive")
                    NodeHelper:setMenuItemEnabled(container, "mGetBtn", true)
                    NodeHelper:setNodeIsGray(container, { mVIPBuy = false })
                end
            end
        else
            lb2Str["mVIPBuy"] = common:getLanguageString("@CanReceive")
            NodeHelper:setMenuItemEnabled(container, "mGetBtn", false)
            NodeHelper:setNodeIsGray(container, { mVIPBuy = true })
        end

        if resInfo.iconScale then
            scaleMap["mPic"] = resInfo.iconScale
        end
    end
    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setColorForLabel(container, colorMap)
end

function GrowthFundPage.onFunction(eventName, container)
    if eventName == "onbuy" then
        if GrowthFundPage.bought then return end
        if not UserInfo.isVIPEnough(GameConfig.growthVipLevel, "GrowthFundBuy_enter_rechargePage") then return end
        if not UserInfo.isGoldEnough(GameConfig.growthNeedGold, "GrowthFundBuy_enter_rechargePage") then return end

        GrowthFundPage:onBuy(container)
    end
end

function GrowthFundPage:onEnter(ParentContainer)
    local container = ScriptContentBase:create("Act_FixedTimeGrowthFundContent.ccbi")
    self.container = container

    growthFundCfg = ConfigManager.getGrowthFundCfg()

    NodeHelper:initScrollView(container, "mContent", 3)

    NodeHelper:setStringForLabel(container, {
        mVIPLimitTxt = common:getLanguageString("@GrowthFundVIPBuyTxt",GameConfig.growthVipLevel),
        mBuyNum = GameConfig.growthNeedGold,
        mCompleteTxt = common:getLanguageString("@HasBuy"),
    } )

    self.container:registerFunctionHandler(GrowthFundPage.onFunction)
    self:registerPacket(ParentContainer)
    common:sendEmptyPacket(HP_pb.GROWTH_FUND_INFO_C, true)

    -- self:clearAndReBuildAllItem(container)

    -- self:initSpine(container)

    return self.container
end

function GrowthFundPage:initSpine(container)
    local spineNode = container:getVarNode("mSpineNode")
    if spineNode and spineNode:getChildByTag(10010) == nil then
        spineNode:removeAllChildren()
        local roldData = ConfigManager.getRoleCfg()[104]
        local spine = SpineContainer:create(unpack(common:split((roldData.spine), ",")))
        local spineToNode = tolua.cast(spine, "CCNode")
        spineNode:addChild(spineToNode)
        spine:runAnimation(1, "Stand", -1)
        local offset_X_Str, offset_Y_Str = unpack(common:split(("-200,40"), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        spineToNode:setScale(0.7)
    end
end

function GrowthFundPage:onExecute(container)

end

function GrowthFundPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == HP_pb.GROWTH_FUND_INFO_S then
        local msg = Activity2_pb.HPGetGrowthFundInfoRes()
        msg:ParseFromString(msgBuff)
        GrowthFundContent.rewardIds = { }
        for i = 1, #msg.rewardId do
            GrowthFundContent.rewardIds[msg.rewardId[i]] = 1
        end
        GrowthFundPage.bought = msg.bought
        NodeHelper:setMenuItemEnabled(self.container, "mBuyBtn", not msg.bought)
        NodeHelper:setNodeIsGray(self.container, { mCompleteTxt = true })

        removeNotice = true

        table.sort(growthFundCfg, function(a, b)
            if not GrowthFundContent.rewardIds[a.id] then
                if not GrowthFundContent.rewardIds[b.id] then
                    return a.id < b.id
                else
                    return true
                end
            end
            if not GrowthFundContent.rewardIds[b.id] then return false end
            return a.id < b.id
        end )

        self:clearAndReBuildAllItem(self.container)

        if msg.bought then
            for i, v in ipairs(growthFundCfg) do
                if not GrowthFundContent.rewardIds[v.id] then
                    if UserInfo.roleInfo.level >= v.level then
                        removeNotice = false
                        break
                    end
                end
            end
        end
        if UserInfo.playerInfo.vipLevel >= GameConfig.growthVipLevel and removeNotice then
            removeNotice = msg.bought
        end

        if removeNotice then
            ActivityInfo.changeActivityNotice(Const_pb.GROWTH_FUND)
        end

        local visibleMap = {
            mCompleteTxt = msg.bought,
            mCostNode = not msg.bought
        }
        NodeHelper:setNodesVisible(self.container, visibleMap)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        if sendReward then
            sendReward = false
            common:sendEmptyPacket(HP_pb.GROWTH_FUND_INFO_C, true)
        end
    elseif opcode == HP_pb.GROWTH_FUND_BUY_S then
        local msg = Activity2_pb.HPBuyGrowthFundSuccRes()
        msg:ParseFromString(msgBuff)
        if msg.succ == 0 then
            MessageBoxPage:Msg_Box_Lan("@GrowthFundHasBuy")
            common:sendEmptyPacket(HP_pb.GROWTH_FUND_INFO_C, true)
        end
    end
end

function GrowthFundPage:onBuy(container)
    common:sendEmptyPacket(HP_pb.GROWTH_FUND_BUY_C, true)
end

function GrowthFundPage:onExit(container)
    self:removePacket(container)
    growthFundCfg = { }
    GrowthFundPage.bought = false
    removeNotice = true
    sendReward = false
    self.container.mScrollView:removeAllCell()
end

function GrowthFundPage:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    for i, v in ipairs(growthFundCfg) do
        local titleCell = CCBFileCell:create()
        local panel = GrowthFundContent:new( { id = v.id, index = i })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(GrowthFundContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
end

function GrowthFundPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function GrowthFundPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

return GrowthFundPage