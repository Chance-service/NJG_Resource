----------------------------------------------------------------------------------
--[[
每日儲值/累積儲值/累積消費
--]]
----------------------------------------------------------------------------------
local thisPageName = "IAPSubPage_RechargeBonus"
local NodeHelper = require("NodeHelper")
local Activity5_pb = require("Activity5_pb")
local HP_pb = require("HP_pb")

local RechargeBonusPage = { }
local RechargeBonusItem = { }
local RechargeBonusCfg = ConfigManager.getRechargeBonusCfg()

local opcodes = {
    ACTIVITY192_RECHARGE_BOUNCE_S = HP_pb.ACTIVITY192_RECHARGE_BOUNCE_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
}
-- CONST
local ACTION_TYPE = { SYNC = 0, GET_REWARD = 1 }
local PAGE_TYPE = { DAILY_RECHARGE = 2, TOTAL_RECHARGE = 1, TOTAL_CONSUME = 3 }
local BTN_TYPE = { NOT_COMPLETE = 1, COMPLETED = 2, RECEIVED = 3 }
-- 
local parentPage = nil
local nowPage = PAGE_TYPE.DAILY_RECHARGE
local serverData = { }
--------------------------------------------------------------------------------
local option = {
    ccbiFile = "RechargeBounce.ccbi",
    handlerMap = { 
        onTab1 = "onTab1",
        onTab2 = "onTab2",
        onTab3 = "onTab3",
    },
}

function RechargeBonusPage:createPage(_parentPage)
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)
    
    return container
end

function RechargeBonusPage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RechargeBonusPage:onExecute(container)
    if serverData.timeTable and serverData.timeTable[nowPage] then
        local leftTime = serverData.timeTable[nowPage].endTime - os.time()
        if leftTime < 0 then
            local str = common:getLanguageString("@ERRORCODE_80104")
            NodeHelper:setStringForLabel(container, { refreshAutoCountdownText = str })
        else
            local d = math.floor(leftTime / 86400)
            leftTime = leftTime - 86400 * d
            local h = math.floor(leftTime / 3600)
            leftTime = leftTime - 3600 * h
            local m = math.floor(leftTime / 60)
            leftTime = leftTime - 60 * m
            local s = leftTime
            local str = string.format(common:getLanguageString("@ActPopUpSale.LeftTimeText.dhm"), d, h, m, s)
            NodeHelper:setStringForLabel(container, { refreshAutoCountdownText = str })
        end
    else
        local str = string.format(common:getLanguageString("@ERRORCODE_80104"))
        NodeHelper:setStringForLabel(container, { refreshAutoCountdownText = str })
    end
end

function RechargeBonusPage:onEnter(container)
    self.container = container
    RechargeBonusPage.container = container
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)

    local bg = container:getVarSprite("mBgSprite")
    bg:setScale(NodeHelper:getTargetScaleProportion(1600, 720))

    nowPage = PAGE_TYPE.DAILY_RECHARGE
    NodeHelper:setStringForLabel(container, { refreshAutoCountdownText = "" })
    self:setTabImg(container)
    self:serverInfoRequest()
end

function RechargeBonusPage:onTab1(container)
    self:onTab(container, "onTab1")
end
function RechargeBonusPage:onTab2(container)
    self:onTab(container, "onTab2")
end
function RechargeBonusPage:onTab3(container)
    self:onTab(container, "onTab3")
end

function RechargeBonusPage:onTab(container, eventName)
    local tab = tonumber(string.sub(eventName, 6))

    nowPage = tab
    for i = 1, #PAGE_TYPE do
        local tabItem = container:getVarMenuItemImage("mTab" .. i)
        tabItem:setEnabled(i ~= nowPage)
    end
    self:refresh(container)
    self:setTabImg(container)
end

function RechargeBonusPage:setTabImg(container)
    NodeHelper:setMenuItemsEnabled(container, { mTab2 = (nowPage ~= PAGE_TYPE.DAILY_RECHARGE), 
                                                mTab1 = (nowPage ~= PAGE_TYPE.TOTAL_RECHARGE), 
                                                mTab3 = (nowPage ~= PAGE_TYPE.TOTAL_CONSUME) })
end

function RechargeBonusPage:serverInfoRequest()
    local msg = Activity5_pb.RechargeBounceReq()
    msg.action = ACTION_TYPE.SYNC
    common:sendPacket(HP_pb.ACTIVITY192_RECHARGE_BOUNCE_C, msg, true)
end

function RechargeBonusPage:refresh(container)
    parentPage:updateCurrency()
    local scrollview = container:getVarScrollView("mContent")
    scrollview:removeAllCell()
    local cfg = self:getSortedTable(RechargeBonusCfg)
    local num = 0
    for k, v in pairs(cfg) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("RechargeBounceItem.ccbi")
        local panel = common:new( { id = v.id }, RechargeBonusItem)
        cell:registerFunctionHandler(panel)
        scrollview:addCell(cell)  
        num = num + 1
    end

    scrollview:setTouchEnabled(num > 4)
    scrollview:orderCCBFileCells()
end

function RechargeBonusPage:getSortedTable(Config)
    local cfg = { }
    -- 過濾資料
    for k, v  in pairs (Config) do
        local insert = false
        if v.type == nowPage and serverData.timeTable[nowPage] then 
            if (v.timeIndex == serverData.timeTable[nowPage].timeIndex) then
                if v.platform == 1 and Golb_Platform_Info.is_h365 then
                    insert = true
                elseif v.platform == 2 and Golb_Platform_Info.is_r18 then
                    insert = true
                elseif v.platform == 6 and Golb_Platform_Info.is_kuso then
                    insert = true
                elseif CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
                    insert = true
                end
            end
        end
        if insert then
            table.insert(cfg, v)
        end
    end
    -- 排序資料
    table.sort(cfg, function(data1, data2)
        if data1 and data2 then
            return data1.rank < data2.rank
        else
            return false
        end
    end)
    return cfg
end

function RechargeBonusPage:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff

    if opcode == HP_pb.ACTIVITY192_RECHARGE_BOUNCE_S then
        local msg = Activity5_pb.RechargeBounceResp()
        msg:ParseFromString(msgBuff)
        serverData = { }

        local action = msg.action

        serverData.deposit = msg.deposit
        serverData.consume = msg.consume

        local timeInfos = msg.timeInfo
        serverData.timeTable = { }
        for i = 1, #timeInfos do
            serverData.timeTable[timeInfos[i].type] = serverData.timeTable[timeInfos[i].type] or  { }
            serverData.timeTable[timeInfos[i].type].startTime = timeInfos[i].starTime and timeInfos[i].starTime / 1000 or 0
            serverData.timeTable[timeInfos[i].type].endTime = timeInfos[i].endTime and  timeInfos[i].endTime / 1000 or 0
            serverData.timeTable[timeInfos[i].type].timeIndex = timeInfos[i].timeIndex
        end

        local itemInfos = msg.itemInfo
        serverData.gotTable = { }
        for i = 1, #itemInfos do
            serverData.gotTable[itemInfos[i].cfgId] = (itemInfos[i].isGot == 1) and BTN_TYPE.RECEIVED or BTN_TYPE.COMPLETED
        end
        local countInfos = msg.singleInfo or { }
        serverData.countTable = { }
        for i = 1, #countInfos do
            serverData.countTable[countInfos[i].cfgId] = countInfos[i].left
        end
        self:refresh(self.container)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
end

function RechargeBonusPage:onExit(ParentContainer)
    parentPage:removePacket(opcodes)
    PageManager.refreshPage("MainScenePage", "refreshInfo")
end

function RechargeBonusItem:onFrame1(container)
    RechargeBonusItem:onShowItemInfo(container, self.id, 1)
end
function RechargeBonusItem:onFrame2(container)
    RechargeBonusItem:onShowItemInfo(container, self.id, 2)
end
function RechargeBonusItem:onFrame3(container)
    RechargeBonusItem:onShowItemInfo(container, self.id, 3)
end
function RechargeBonusItem:onFrame4(container)
    RechargeBonusItem:onShowItemInfo(container, self.id, 4)
end
function RechargeBonusItem:onFrame5(container)
    RechargeBonusItem:onShowItemInfo(container, self.id, 5)
end

function RechargeBonusItem:onShowItemInfo(container, index, goodIndex)
    if not RechargeBonusCfg[index] then return end
    local packetItem = common:split(RechargeBonusCfg[index].reward, ",")
    if packetItem[goodIndex] then
        local item = { }
        local _type, _itemId, _num = unpack(common:split(packetItem[goodIndex], "_"))
        item.type = tonumber(_type)
        item.itemId = tonumber(_itemId)
        item.count = tonumber(_num)
        GameUtil:showTip(container:getVarNode("mPic" .. goodIndex), item)
    end
end

function RechargeBonusItem:onRefreshContent(ccbRoot)
    local id = self.id
    local container = ccbRoot:getCCBFileNode()
    local selfCfg = RechargeBonusCfg[id]
    if not selfCfg then
        return
    end
    local packetItem = common:split(selfCfg.reward, ",")

    -- 領取狀態
    if not serverData.gotTable[id] then
        self.btnType = BTN_TYPE.NOT_COMPLETE
        NodeHelper:setStringForLabel(container, { mBtnLabel = common:getLanguageString("@Goto") })
    else
        if serverData.gotTable[id] == BTN_TYPE.RECEIVED then
            self.btnType = BTN_TYPE.RECEIVED
            NodeHelper:setStringForLabel(container, { mBtnLabel = common:getLanguageString("@ReceiveDone") })
        elseif serverData.gotTable[id] == BTN_TYPE.COMPLETED then
            self.btnType = BTN_TYPE.COMPLETED
            NodeHelper:setStringForLabel(container, { mBtnLabel = common:getLanguageString("@Receive") })
        else
            self.btnType = BTN_TYPE.NOT_COMPLETE
            NodeHelper:setStringForLabel(container, { mBtnLabel = common:getLanguageString("@Goto") })
        end
    end
    NodeHelper:setNodesVisible(container, { mMask = (self.btnType == BTN_TYPE.RECEIVED) })
    local btn = container:getVarMenuItemImage("mBtn")
    btn:setEnabled(self.btnType ~= BTN_TYPE.RECEIVED)

    -- 說明文字
    local v1 = selfCfg.needCount
    local v2 = (nowPage == PAGE_TYPE.TOTAL_CONSUME and serverData.consume) or (nowPage == PAGE_TYPE.TOTAL_RECHARGE and serverData.deposit) or 0
    local v3 = selfCfg.needCount
    local v4 = selfCfg.count
    NodeHelper:setStringForLabel(container, { mStepTxt = "" })
    if nowPage == PAGE_TYPE.TOTAL_RECHARGE then
        NodeHelper:setStringForLabel(container, { mTxt1 = common:getLanguageString("@RechargeBounce_title") })
        if Golb_Platform_Info.is_h365 then
            NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Total_RECHARGE", v1) })
        elseif Golb_Platform_Info.is_r18 then
            NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Total_RECHARGE", v1) })
        elseif Golb_Platform_Info.is_kuso then
            NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Total_RECHARGE69", v1) })
        else
            NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Total_RECHARGE", v1) })
        end
        NodeHelper:setStringForLabel(container, { mTxt3 = common:getLanguageString("@Total_RECHARGE_2", 0, v2, v3) })
    elseif nowPage == PAGE_TYPE.DAILY_RECHARGE then
        NodeHelper:setStringForLabel(container, { mTxt1 = common:getLanguageString("@Single_RECHARGE") })
        if Golb_Platform_Info.is_h365 then
            NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Total_RECHARGE", v1) })
        elseif Golb_Platform_Info.is_r18 then
            NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Total_RECHARGE", v1) })
        elseif Golb_Platform_Info.is_kuso then
            NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Total_RECHARGE69", v1) })
        else
            NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Total_RECHARGE", v1) })
        end
        local leftCount = serverData.countTable[id] and math.max(v4 - serverData.countTable[id], 0) or v4
        NodeHelper:setStringForLabel(container, { mTxt3 = common:getLanguageString("@Total_RECHARGE_2", 0, leftCount, v4) })
    elseif nowPage == PAGE_TYPE.TOTAL_CONSUME then
        NodeHelper:setStringForLabel(container, { mTxt1 = common:getLanguageString("@Diamond_Consum") })
        NodeHelper:setStringForLabel(container, { mTxt2 = common:getLanguageString("@Diamond_Consum_2", v1) })
        NodeHelper:setStringForLabel(container, { mTxt3 = common:getLanguageString("@Total_RECHARGE_2", 0, v2, v3) })
    else
        NodeHelper:setStringForLabel(container, { mLeftCount = "" })
    end

    -- 獎勵圖示
    for i = 1, 5 do
        NodeHelper:setNodesVisible(container, { ["mRewardNode" .. i] = packetItem[i] and true or false })
        if packetItem[i] then
            local _type, _itemId, _num = unpack(common:split(packetItem[i], "_"))
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_itemId), tonumber(_num))
            if resInfo ~= nil then
                NodeHelper:setSpriteImage(container, { ["mPic" .. i] = resInfo.icon })
                NodeHelper:setStringForLabel(container, { ["mNum" .. i] = GameUtil:formatNumber(_num) })
                NodeHelper:setImgBgQualityFrames(container, { ["mFrame" .. i] = resInfo.quality })
                NodeHelper:setQualityFrames(container, { ["mHand" .. i] = resInfo.quality })
            end
            NodeHelper:setNodesVisible(container, { ["mReceived" .. i] = (self.btnType == BTN_TYPE.RECEIVED) })
        end
    end
end

function RechargeBonusItem:onBtnClick(container)
    if self.btnType == BTN_TYPE.NOT_COMPLETE then
        -- 前往每日禮包
        local pageIdx = 1
        for i = 1, #parentPage.subPageDatas do
            if parentPage.subPageDatas[i].subPageName == "Recharge" then
                pageIdx = i
            end
        end
        parentPage.tabStorage:onTabBtn(parentPage.tabStorage.container, pageIdx)
    elseif self.btnType == BTN_TYPE.COMPLETED then
        -- 領獎
        local msg = Activity5_pb.RechargeBounceReq()
        msg.action = ACTION_TYPE.GET_REWARD
        msg.cfgId = self.id
        common:sendPacket(HP_pb.ACTIVITY192_RECHARGE_BOUNCE_C, msg, true)
    end
end

return RechargeBonusPage
