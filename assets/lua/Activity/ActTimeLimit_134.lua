----------------------------------------------------------------------------------
--[[
	周末福利
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity4_pb = require("Activity4_pb")
local thisPageName = 'ActTimeLimit_134'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local Const_pb = require("Const_pb")

local _ConfigData = nil
local _PriceConfigData = nil
local _leftTimeName = "ActTimeLimit_134_leftTime"
local _serverData = nil
local _currenConfgId = 1
local _maxRandCount = 30    -- 动画最大随机次数
local _currentRandCount = 0 -- 动画当前的次数
local _isRunAction = false  -- 是不是正在播放动画
local _currentMultiple = 0 -- 当前倍数
local _lastRandmoMultiple = 0-- 上一次随机的倍数
local _currentPrice = 0 -- 当前需要的价格
local _todayServerData = nil
local _otherDayServerData = nil
local _isFriday = false
local _leftTimer = 0
local _randomMultipleData = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
local ActTimeLimit_134 = { }
local option = {
    ccbiFile = "Act_TimeLimit_134.ccbi",
    handlerMap =
    {
        onReceive = "onReceive",
        onClose = "onClose",
        onFree = "onFree",
        onFrame1 = "onClickItemFrame",
        onFrame2 = "onClickItemFrame",
        onFrame3 = "onClickItemFrame",
        -- onFrame4 = "onClickItemFrame",
    },
}
local opcodes = {
    ACTIVITY134_WEEKEND_GIFT_INFO_C = HP_pb.ACTIVITY134_WEEKEND_GIFT_INFO_C,
    ACTIVITY134_WEEKEND_GIFT_INFO_S = HP_pb.ACTIVITY134_WEEKEND_GIFT_INFO_S,
    ACTIVITY134_WEEKEND_GIFT_LOTTERY_C = HP_pb.ACTIVITY134_WEEKEND_GIFT_LOTTERY_C,
    ACTIVITY134_WEEKEND_GIFT_LOTTERY_S = HP_pb.ACTIVITY134_WEEKEND_GIFT_LOTTERY_S,
    ACTIVITY134_WEEKEND_GIFT_GET_C = HP_pb.ACTIVITY134_WEEKEND_GIFT_GET_C,
    ACTIVITY134_WEEKEND_GIFT_GET_S = HP_pb.ACTIVITY134_WEEKEND_GIFT_GET_S
}


-----测试数据
function ActTimeLimit_134:testData()
    --    _serverData = { }
    --    _serverData.preOpenTime = 0
    --    _serverData.activityLefttime = 0
    --    _serverData.todayLeftTime = 0

    --    _serverData.items = { }
    --    _serverData.items[1] = { }
    --    _serverData.items[2] = { }
    --    _serverData.items[3] = { }

    --    _serverData.items[1].cfgId = 1
    --    _serverData.items[1].isToday = false
    --    _serverData.items[1].count = 0
    --    _serverData.items[1].isLottery = false
    --    _serverData.items[1].isGot = false

    --    _serverData.items[2].cfgId = 2
    --    _serverData.items[2].isToday = false
    --    _serverData.items[2].count = 0
    --    _serverData.items[2].isLottery = false
    --    _serverData.items[2].isGot = false

    --    _serverData.items[3].cfgId = 3
    --    _serverData.items[3].isToday = true
    --    _serverData.items[3].count = 0
    --    _serverData.items[3].isLottery = false
    --    _serverData.items[3].isGot = false


    --    -----测试数据
    --    _todayServerData, _otherDayServerData = self:getTodayAndOtherServerData(_serverData)
    --    self:refreshPage(self.container)
    --    self:refreshOtherDayItem(self.container)
end

function ActTimeLimit_134:onEnter(container)
    math.randomseed(os.time())
    -- local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    -- luaCreat_ActTimeLimit_134(container)
    self:registerPacket(container)
    self:initData()
    self:initUi(container)

    -- self:testData()
    self:getActivityInfo()
end


function ActTimeLimit_134:initData()

    _todayServerData = nil
    _otherDayServerData = nil
    _PriceConfigData = ConfigManager.getAct134CostCfg()
    _currentMultiple = 0
    _isRunAction = false
    _serverData = nil
    _ConfigData = ConfigManager.getAct134RewardCfg()
end

-- 返回当前和其他两天服务端数据  ， 其他两天的按照configid排序
function ActTimeLimit_134:getTodayAndOtherServerData(serverData)
    local data = nil
    local otherDayData = { }
    for i = 1, #serverData.items do
        otherDayData[serverData.items[i].cfgId] = serverData.items[i]
        if serverData.items[i].isToday then
            data = serverData.items[i]
        end
    end

    if data == nil then
        -- 周五的情况   用cfgId= 1 的
        for i = 1, #serverData.items do
            if serverData.items[i].cfgId == 1 then
                data = serverData.items[i]
            end
        end

        _isFriday = true
    else
        _isFriday = false
    end

    table.sort(otherDayData, function(data1, data2)
        if data1 and data2 then
            return data1.cfgId < data2.cfgId
        end
    end )

    _currenConfgId = data.cfgId

    return data, otherDayData
end

function ActTimeLimit_134:addLotteryCount(args)

end


function ActTimeLimit_134:refreshOtherDayItem(container)
    -- _otherDayServerData
    local index = 1
    for i = 1, #_ConfigData do
        if i ~= 1 then
            for k = 1, #_serverData.items do
                if _ConfigData[i].id == _serverData.items[k].cfgId then
                    -- NodeHelper:setNodesVisible(self.container, { ["mGetState_" .. index .. "_1"] = not _serverData.items[k].isGot, ["mGetState_" .. index .. "_2"] = _serverData.items[k].isGot })
                    index = index + 1
                end
            end
        end
    end

    --    for i = 1, #_otherDayServerData do
    --        NodeHelper:setNodesVisible(self.container, { ["mGetState_" .. i .. "_1"] = not _otherDayServerData[i].isGot, ["mGetState_" .. i .. "_2"] = _otherDayServerData[i].isGot })
    --        if _otherDayServerData[i].isGot then
    --            -- 已领取
    --            --NodeHelper:setNodesVisible(self.container, { ["mGetState_" .. i .. "_1"] = false, ["mGetState_" .. i .. "_2"] = true })
    --            --            NodeHelper:setBMFontFile(self.container, { ["mGetState_" .. i] = GameConfig.FntPath.Bule })
    --            --            NodeHelper:setStringForLabel(self.container, { ["mGetState_" .. i] = common:getLanguageString("@ReceiveDone") })
    --        else
    --            -- 未领取
    --            --NodeHelper:setNodesVisible(self.container, { ["mGetState_" .. i .. "_1"] = true, ["mGetState_" .. i .. "_2"] = false })
    --            --            NodeHelper:setBMFontFile(self.container, { ["mGetState_" .. i] = GameConfig.FntPath.Red })
    --            --            NodeHelper:setStringForLabel(self.container, { ["mGetState_" .. i] = common:getLanguageString("@NotAcceptYet") })
    --        end
    --        --NodeHelper:setStringForLabel(self.container, { ["mOtherDay_" .. i] = common:getLanguageString(_ConfigData[_otherDayServerData[i].cfgId].dayStrKey) })
    --        NodeHelper:setNodesVisible(self.container, { ["mOtherDay_" .. i] = false })
    --    end
end

function ActTimeLimit_134:refreshPage(container)
    -- local todayServerData, otherDayServerData = self:getTodayServerData(_serverData)
    NodeHelper:setNodesVisible(self.container, { mUINode = true })
    if _isFriday then
        _leftTimer = _serverData.preOpenTime
        self:setBtnIsEnabled(self.container, false)
    else
        _leftTimer = _serverData.todayLeftTime
        if _todayServerData.isGot then
            NodeHelper:setStringForLabel(self.container, { mReceiveText = common:getLanguageString("@ReceiveDone") })
            self:setBtnIsEnabled(self.container, false)
        else
            NodeHelper:setStringForLabel(self.container, { mReceiveText = common:getLanguageString("@Receive") })
            self:setBtnIsEnabled(self.container, true)
        end
    end



    if _leftTimer > 0 then
        if not TimeCalculator:getInstance():hasKey(_leftTimeName) then
            TimeCalculator:getInstance():createTimeCalcultor(_leftTimeName, _leftTimer)
        end
    else
        TimeCalculator:getInstance():removeTimeCalcultor(_leftTimeName)
    end

    self:setMultiple(self.container, _currentMultiple)

    self:updatePrice(container)

    local isFree = _todayServerData.count == 0
    NodeHelper:setNodesVisible(container, { mBtnPriceNode_1 = not isFree, mFreeLabel = isFree })
    NodeHelper:setNodesVisible(container, { mRandomBtnNode = true, mReceiveNode = true })

    _ConfigData = ConfigManager.getAct134RewardCfg()


    for i = 1, 3 do
        NodeHelper:setNodesVisible(self.container, { ["mDayImage_" .. i] = _todayServerData.cfgId == i })
    end

    local index = 0
    if _currenConfgId == 0 then
        -- 周五
        index = 0
    elseif _currenConfgId == 1 then
        -- 周六
        index = 0
    elseif _currenConfgId == 2 then
        -- 周日
        index = 1
    elseif _currenConfgId == 3 then
        -- 周一
        index = 2
    end

    local cfgConfig = { }
    local items = { }
    for i = 1, #_ConfigData do
        index = index + 1
        if index > 3 then
            index = 1
        end
        cfgConfig[i] = _ConfigData[index]
        items[i] = _otherDayServerData[index]
    end
    _ConfigData = cfgConfig


    local nodesVisible = { };
    local lb2Str = { };
    local sprite2Img = { };
    local scaleMap = { }
    local menu2Quality = { };
    local colorTabel = { }

    for i = 1, #_ConfigData do
        NodeHelper:setNodesVisible(self.container, { ["mGetState_" .. i .. "_1"] = not items[i].isGot, ["mGetState_" .. i .. "_2"] = items[i].isGot })
        -- NodeHelper:setStringForLabel(self.container, { ["mDay_" .. i] = common:getLanguageString(_ConfigData[i].dayStrKey) })

        NodeHelper:setStringForLabel(self.container, { ["mDay_" .. i] = "" })

        local itemInfo = _ConfigData[i]
        local rewardItems = { }
        if itemInfo.reward ~= nil then
            for _, item in ipairs(common:split(itemInfo.reward, ",")) do
                local _type, _id, _count = unpack(common:split(item, "_"));
                table.insert(rewardItems, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count),
                } );
            end
        end

        local cfg = rewardItems[1]
        nodesVisible["mRewardNode" .. i] = cfg ~= nil;
        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
            if resInfo ~= nil then
                sprite2Img["mPic" .. i] = resInfo.icon;
                lb2Str["mNum" .. i] = "x" .. GameUtil:formatNumber(cfg.count);
                lb2Str["mName" .. i] = resInfo.name;

                menu2Quality["mFrame" .. i] = resInfo.quality
                sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
                if resInfo.iconScale then
                    scaleMap["mPic" .. i] = 1
                end

                colorTabel["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                if isShowNum then
                    resInfo.count = resInfo.count or 0
                    lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count;
                end
            else
                CCLuaLog("Error::***reward item not found!!");
            end
        end
    end

    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setColorForLabel(container, colorTabel);

end

function ActTimeLimit_134:updatePrice(container)
    local price = 0

    local count = _todayServerData.count + 1
    if count >= #_PriceConfigData then
        price = _PriceConfigData[#_PriceConfigData].price
    else
        price = _PriceConfigData[count].price
    end
    --    if _todayServerData.count >= #_PriceConfigData then
    --        price = _PriceConfigData[#_PriceConfigData].price
    --    elseif _todayServerData.count == 0 then
    --        price = 0
    --    else
    --        price = _PriceConfigData[_todayServerData.count].price
    --    end
    _currentPrice = price
    NodeHelper:setStringForLabel(container, { mPrice = price .. "" })
end

function ActTimeLimit_134:setBtnIsEnabled(container, isEnable)
    NodeHelper:setNodeIsGray(container, { mReceiveText = not isEnable, mFreeLabel = not isEnable, mPrice = not isEnable, mDiamondsIcon = not isEnable })
    NodeHelper:setMenuItemEnabled(container, "mBtn_1", isEnable)
    NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", isEnable)
end

function ActTimeLimit_134:updateGoldCount(container)
    UserInfo.syncPlayerInfo()
    local label2Str = {
        mDiamondNum = UserInfo.playerInfo.gold,
    }
    NodeHelper:setStringForLabel(container, label2Str)
end

-- 
function ActTimeLimit_134:initUi(container)
    NodeHelper:setNodesVisible(self.container, { mUINode = false })
    -- self:initSpine(self.container)
    self:updateGoldCount(container)
    self:setBtnIsEnabled(self.container, false)
    NodeHelper:setStringForLabel(container, { mLeftTimeText = "" })

    local label2Str = {
        mFreelabel = common:getLanguageString("@SuitShootFree1Text"),
    }
    NodeHelper:setStringForLabel(container, label2Str)

    NodeHelper:setNodesVisible(container, { mRandomBtnNode = false, mReceiveNode = false })

    -- 设置倍数
    self:setMultiple(self.container)
end

function ActTimeLimit_134:setMultiple(container, lastTimeMultiple)
    local multiple = lastTimeMultiple or 0
    if multiple == 0 then
        NodeHelper:setNodesVisible(container, { mQuestionSprite = true, mMultipleLabel = false })
    else
        NodeHelper:setNodesVisible(container, { mQuestionSprite = false, mMultipleLabel = true })
        NodeHelper:setStringForLabel(container, { mMultipleLabel = "" .. multiple })
    end
end

function ActTimeLimit_134:initSpine(container)
    local spineNode = container:getVarNode("mSpineNode");
    if spineNode:getChildByTag(10086) == nil then
        spineNode:removeAllChildren()
        local roldData = ConfigManager.getRoleCfg()[173]

        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode")
        spineNode:addChild(spineToNode)
        spineToNode:setTag(10086)
        spine:runAnimation(1, "Stand", -1)

        local spinePosOffset = "0,70"
        local spineScale = 1
        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        spineToNode:setScale(spineScale)
    end
end

function ActTimeLimit_134:showAnimation()
    _isRunAction = true
    _randomMultipleData = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    _currentRandCount = 0
    NodeHelper:setNodesVisible(container, { mQuestionSprite = false, mMultipleLabel = true })
    _lastRandmoMultiple = self:removeRandomMultiple()
    self:setMultiple(self.container, _lastRandmoMultiple)
    local mMultipleLabel = self.container:getVarNode("mMultipleLabel")
    self:runAction(mMultipleLabel)
end

function ActTimeLimit_134:runAction(node)
    local delaytime = CCDelayTime:create(0.1)
    local CallFuncN = CCCallFuncN:create( function(node)
        if _currentRandCount == 10 then
            -- TODO
        end
        if _currentRandCount >= _maxRandCount then
            -- 结束
            node:stopAllActions()
            self:setMultiple(self.container, _currentMultiple)

            self:refreshPage(self.container)
            _isRunAction = false
        else
            _currentRandCount = _currentRandCount + 1
            local index = self:removeRandomMultiple()
            self:addrandomMultiple(_lastRandmoMultiple)
            _lastRandmoMultiple = index
            CCLuaLog("---------------------" .. index)
            self:setMultiple(self.container, index)
            self:runAction(node)
        end
    end )

    local Array = CCArray:create()
    Array:addObject(delaytime)
    Array:addObject(CallFuncN)
    local Sequence = CCSequence:create(Array)
    node:runAction(Sequence)
end

function ActTimeLimit_134:addrandomMultiple(multiple)
    local bl = false
    for i = 1, #_randomMultipleData do
        if _randomMultipleData[i] == multiple then
            bl = true
        end
    end
    if not bl then
        table.insert(_randomMultipleData, multiple)
    end
end

function ActTimeLimit_134:removeRandomMultiple()
    if #_randomMultipleData == 0 then
        _randomMultipleData = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    end
    local index = math.random(1, #_randomMultipleData)
    return table.remove(_randomMultipleData, index)
end


-- 点击物品显示tips
function ActTimeLimit_134:onClickItemFrame(container, eventName)
    local rewardIndex = tonumber(eventName:sub(8))
    local nodeIndex = rewardIndex;
    local itemInfo = _ConfigData[nodeIndex]
    if not itemInfo then return end
    local rewardItems = { }
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end
    GameUtil:showTip(container:getVarNode('mPic' .. nodeIndex), rewardItems[1])
end


function ActTimeLimit_134:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
    local maxSize = maxSize or 4;
    isShowNum = isShowNum or false
    local nodesVisible = { };
    local lb2Str = { };
    local sprite2Img = { };
    local scaleMap = { }
    local menu2Quality = { };
    local colorTabel = { }
    for i = 1, maxSize do
        local cfg = rewardCfg[i];
        nodesVisible["mRewardNode" .. i] = cfg ~= nil;
        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
            if resInfo ~= nil then
                sprite2Img["mPic" .. i] = resInfo.icon;
                lb2Str["mNum" .. i] = "x" .. GameUtil:formatNumber(cfg.count);
                lb2Str["mName" .. i] = resInfo.name;

                menu2Quality["mFrame" .. i] = resInfo.quality
                sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
                if resInfo.iconScale then
                    scaleMap["mPic" .. i] = 1
                end

                colorTabel["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                if isShowNum then
                    resInfo.count = resInfo.count or 0
                    lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count;
                end
            else
                CCLuaLog("Error::***reward item not found!!");
            end
        end
    end

    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setColorForLabel(container, colorTabel);
end


function ActTimeLimit_134:onClose(container)
    --    _currentMultiple = 5
    --    _todayServerData.isLottery = true
    --    _todayServerData.count = _todayServerData.count + 1

    --    self:showAnimation()
    PageManager.popPage(thisPageName)
end

function ActTimeLimit_134:onExit(container)
    self:removePacket(container)
    self.container = nil
    local spineNode = container:getVarNode("mSpineNode")
    if spineNode then
        spineNode:removeAllChildren()
    end
    TimeCalculator:getInstance():removeTimeCalcultor(_leftTimeName)
end

function ActTimeLimit_134:onReceive(container)
    if _isRunAction or _serverData == nil then
        return
    end

    if _currentMultiple <= 0 then
        -- TODO 先选择倍数
        MessageBoxPage:Msg_Box_Lan("@ReceiveRatioFirst")
        return
    end

    local msg = Activity4_pb.Activity134WeekendGiftGetReq()
    msg.cfgId = _todayServerData.cfgId
    common:sendPacket(HP_pb.ACTIVITY134_WEEKEND_GIFT_GET_C, msg, true)


end

function ActTimeLimit_134:onFree(container)
    if _isRunAction or _serverData == nil then
        return
    end

    UserInfo.syncPlayerInfo()
    if _todayServerData.count > 0 and UserInfo.playerInfo.gold < _currentPrice then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. Const_pb.ACTIVITY134_WEEKEND_GIFT)
        return
    end
    local msg = Activity4_pb.Activity134WeekendGiftLotteryReq()
    msg.cfgId = _todayServerData.cfgId
    common:sendPacket(HP_pb.ACTIVITY134_WEEKEND_GIFT_LOTTERY_C, msg, true)
end

function ActTimeLimit_134:onExecute(container)
    self:onTimer(self.container)
end

function ActTimeLimit_134:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(_leftTimeName) then
        return
    end
    local remainTime = TimeCalculator:getInstance():getTimeLeft(_leftTimeName)
    if remainTime + 1 > _leftTimer then
        return
    end

    local timeStr = common:second2DateString(remainTime, false)
    local langStr = "@SurplusTimeFishing"
    if _isFriday then
        langStr = "@StartTime"
    end
    NodeHelper:setStringForLabel(container, { mTanabataCD = common:getLanguageString(langStr) .. timeStr })

    if remainTime <= 0 then
        -- 请求info么？
        -- self:getActivityInfo()
        TimeCalculator:getInstance():removeTimeCalcultor(_leftTimeName)
        NodeHelper:setStringForLabel(container, { mTanabataCD = "" })
    end
end

function ActTimeLimit_134:getActivityInfo()
    common:sendEmptyPacket(HP_pb.ACTIVITY134_WEEKEND_GIFT_INFO_C, true)
end

function ActTimeLimit_134_INFO_C()
    common:sendEmptyPacket(HP_pb.ACTIVITY134_WEEKEND_GIFT_INFO_C, false)
end

function ActTimeLimit_134:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == opcodes.ACTIVITY134_WEEKEND_GIFT_INFO_S then
        -- info返回
        local msg = Activity4_pb.Activity134WeekendGiftInfoRes()
        msg:ParseFromString(msgBuff)
        _serverData = msg
        if _serverData == nil then
            return
        end
        _todayServerData, _otherDayServerData = self:getTodayAndOtherServerData(_serverData)
        _currentMultiple = _todayServerData.multipleNum
        self:refreshPage(self.container)
        -- self:refreshOtherDayItem(self.container)
    elseif opcode == opcodes.ACTIVITY134_WEEKEND_GIFT_LOTTERY_S then
        -- 获取倍数返回
        local msg = Activity4_pb.Activity134WeekendGiftLotteryRes()
        msg:ParseFromString(msgBuff)
        _todayServerData.multipleNum = msg.multipleNum
        _currentMultiple = _todayServerData.multipleNum
        _todayServerData.isLottery = true
        _todayServerData.count = _todayServerData.count + 1
        self:updateGoldCount(self.container)
        self:showAnimation()

    elseif opcode == opcodes.ACTIVITY134_WEEKEND_GIFT_GET_S then
        -- 领奖返回
        local msg = Activity4_pb.Activity134WeekendGiftGetRes()
        msg:ParseFromString(msgBuff)
        -- _todayServerData.multipleNum = 0
        -- _todayServerData.isLottery = false
        _todayServerData.isGot = true
        -- _currentMultiple = _todayServerData.multipleNum
        self:refreshPage(self.container)
        -- 取消红点
        if ActivityInfo.NoticeInfo.ids[Const_pb.ACTIVITY134_WEEKEND_GIFT] then
            -- ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY134_WEEKEND_GIFT)
        end
        ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY134_WEEKEND_GIFT)
    end
end

function ActTimeLimit_134:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_134:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

local CommonPage = require('CommonPage')
ActTimeLimit_134 = CommonPage.newSub(ActTimeLimit_134, thisPageName, option)

return ActTimeLimit_134
