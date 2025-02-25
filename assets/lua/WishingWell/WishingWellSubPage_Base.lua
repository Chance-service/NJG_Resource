
--[[ 
    name: WishingWellSubPage_Base
    desc: 許願輪 子頁面 基本
    author: youzi
    update: 2023/6/12 10:36
    description: 
--]]

local HP_pb = require("HP_pb") -- 包含协议id文件
local Activity4_pb = require("Activity4_pb")

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local TimeDateUtil = require("Util.TimeDateUtil")
local InfoAccesser = require("Util.InfoAccesser")
local PacketAgent = require("Util.PacketAgent")
local Event = require("Util.Event")
local ALFManager = require("Util.AsyncLoadFileManager")

local WishingWellDataMgr = require("WishingWell.WishingWellDataMgr")

local CommItem = require("CommUnit.CommItem")
local CommItemReceivePage = require("CommPop.CommItemReceivePage")

local thisPageName = "WishingWellSubPage_Base"

local WishingWellSubPage_Base = {}

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ 是否可以跳過 ]]
local IS_SKIPABLE = true

--[[ 
    text
    
    var 
        
    event
    
--]]


--[[ 本體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


--[[ 父頁面 ]]
Inst.parentPage = nil

--[[ 許願輪UI ]]
Inst.wishingWellUI = nil

--[[ 當 關閉 行為 ]]
Inst.onceClose_fn = nil

--[[ 類型 ]]
Inst.wishingWellType = nil

--[[ 子頁面資訊 ]]
Inst.subPageName = ""
Inst.subPageCfg = nil

--[[ 免費抽次數 ]]
Inst.freeQuota = 0

--[[ 下次手動刷新充能時間 ]]
Inst.refreshFreeNextTime = -1

--[[ 下次自動刷新時間 ]]
Inst.refreshAutoNextTime = -1

--[[ 請求冷卻幀數 ]]
Inst.requestCooldownFrame = 180
--[[ 請求冷卻剩餘 ]]
Inst.requestCooldownLeft = Inst.requestCooldownFrame

--[[ 背景動畫 ]]
Inst.bgSpine = nil
Inst.bgSpineNode = nil

--[[ 抽取動畫 ]]
Inst.gachaSpine = nil
Inst.gachaSpineNode = nil

--[[ 當抽取動畫事件 ]]
Inst.onGachaSpineAnim = nil

--[[ 當 收到訊息 ]]
function Inst:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    -- if typeId == XXXXXXXXXX then
    --     local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;
    --     if opcode == HP_pb.XXXXXXX then
    --         
    --     end
    -- end
end

--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)
    -- if packet.opcode == HP_pb.ACTIVITY147_WISHING_INFO_S or
    --     packet.opcode == HP_pb.ACTIVITY147_WISHING_DRAW_S then
    --     local msg = Activity4_pb.WishingWellInfo()
    --     msg:ParseFromString(packet.msgBuff)
        
    --     self:handleInfo(msg)
    -- end
end

--[[ 建立 頁面 ]]
function Inst:createPage (parentPage)
    self.wishingWellUI = parentPage:requestWishingWellUI()

    -- 取得 子頁面 配置
    self.subPageCfg = WishingWellDataMgr:getSubPageCfg(self.subPageName)
    self.wishingWellType = self.subPageCfg.type
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (selfContainer, parentPage)
    CCLuaLog(">>>>>>>>wishingWell onEnter1")
    local slf = self

    self.parentPage = parentPage

    parentPage.tabStorage:setHelpBtn(true)
    -- 協定收發代理器
    local packetAgent = PacketAgent:inst()
    packetAgent:bindOpcodeMsg(HP_pb.ACTIVITY147_WISHING_INFO_S, Activity4_pb.WishingWellInfo)
    packetAgent:bindOpcodeMsg(HP_pb.ACTIVITY147_WISHING_DRAW_S, Activity4_pb.WishingWellInfo)
    local onPacket = function (packet)
        slf:handleInfo(packet.msg)
    end
    packetAgent:on(HP_pb.ACTIVITY147_WISHING_INFO_S, onPacket):tag(self)
    packetAgent:on(HP_pb.ACTIVITY147_WISHING_DRAW_S, onPacket):tag(self)
    CCLuaLog(">>>>>>>>wishingWell onEnter2")
    -- 許願輪UI -----------

    -- 註冊 行為
    self.wishingWellUI.onRewardClick = function (rewardIdx)
        -- print("WishingWellSubPage_Base : self.wishingWellUI.onRewardClick")
        slf:sendClaimReward()
    end
    self.wishingWellUI.onSummonBtn = function ()
        -- print("WishingWellSubPage_Base : self.wishingWellUI.onSummonBtn")
        slf:sendSummon1()
    end
    self.wishingWellUI.onSummon10Btn = function ()
        -- print("WishingWellSubPage_Base : self.wishingWellUI.onSummon10Btn")
        slf:sendSummon10()
    end
    self.wishingWellUI.onRefreshBtn = function ()
        -- print("WishingWellSubPage_Base : self.wishingWellUI.onRefreshBtn")
        slf:sendManualRefresh()
    end
    self.wishingWellUI.onItemClick = function (itemIdx, itemInfo, itemUI)
        -- print("WishingWellSubPage_Base : self.wishingWellUI.onRefreshBtn")
        GameUtil:showTip(
            itemUI,
            {
                type = itemInfo.type,
                itemId = itemInfo.id,
            }
        )
    end
    CCLuaLog(">>>>>>>>wishingWell onEnter3")
    -- 設置 刷新 價格
    local refreshPrice_itemInfo = InfoAccesser:getItemInfoByStr(self.subPageCfg.refreshPriceStr)
    self.wishingWellUI:setRefreshPrice(refreshPrice_itemInfo.count, refreshPrice_itemInfo.icon)

    -- 設置 單/十抽 價格
    local summonPrice_itemInfo = InfoAccesser:getItemInfoByStr(self.subPageCfg.summonPriceStr)
    local summonPrice_itemIconCfg = InfoAccesser:getItemIconCfg(summonPrice_itemInfo.type, summonPrice_itemInfo.id, "SummonPrice")
    self.wishingWellUI:setSummonPrice(0, {
        icon = summonPrice_itemInfo.icon,
        iconScale = summonPrice_itemIconCfg.scale,
        price1 = summonPrice_itemInfo.count,
        price10 = summonPrice_itemInfo.count * 10,
    })
    
    -- 設置 進度 獎勵列
    local progressInfo = WishingWellDataMgr:getProgressInfo(self.wishingWellType)
    for idx = 1, #progressInfo.progressRewards do
        progressInfo.progressRewards[idx].showType = 1 --[[ 單個 ]]
    end

    self.wishingWellUI:setProgressRewards(progressInfo.progressRewards)

    -- 預設 關閉 免費刷新
    self.wishingWellUI:setRefreshFree(nil)
    CCLuaLog(">>>>>>>>wishingWell onEnter4")
    -------- SPINE ---------

    -- 取得 Spine動畫 設置
    local bgSpineCfg = self.subPageCfg.bgSpine
    --local gachaSpineCfg = self.subPageCfg.gachaSpine
    CCLuaLog(">>>>>>>>wishingWell onEnter5")
    -- 建立 Spine
    self.bgSpine = SpineContainer:create(bgSpineCfg[1], bgSpineCfg[2])
    CCLuaLog(">>>>>>>>wishingWell onEnter6")
    self.bgSpineNode = tolua.cast(self.bgSpine, "CCNode")
    --self.gachaSpine = SpineContainer:create(gachaSpineCfg[1], gachaSpineCfg[2])
    --self.gachaSpineNode = tolua.cast(self.gachaSpine, "CCNode")
    
    self.wishingWellUI.container:getVarNode("bgSpineNode"):addChild(self.bgSpineNode)
    --self.wishingWellUI.container:getVarNode("gachaSpineNode"):addChild(self.gachaSpineNode)

    ---- 建立抽取動畫事件
    self.onGachaSpineAnim = Event:new()
    --
    ---- 註冊 Spine動畫事件
    --self.gachaSpine:registerFunctionHandler("SELF_EVENT", function(unknownArg, tag, eventName)
    --    slf.onGachaSpineAnim:emit(eventName)
    --end)
    --
    -- 播放
    self.bgSpine:runAnimation(1, bgSpineCfg[3], -1)
    --
    ---- 固定 當特定時機時 隱藏/顯示 獎池泡泡
    --self.onGachaSpineAnim:on(function(ctrlr)
    --    local eventName = ctrlr.data
    --    if eventName == "hideBubble" then
    --        slf.wishingWellUI.container:getVarNode("itemBubbleNode"):setVisible(false)
    --    elseif eventName == "showBubble" then
    --        slf.wishingWellUI.container:getVarNode("itemBubbleNode"):setVisible(true)
    --    end
    --end)

    -------------------

    -- 自適應
    local fitResult = NodeHelperUZ:fitBGNode(self.wishingWellUI.container:getVarNode("bgNode"), {
        -- 原始比例
        originalScale = 1,
        -- 縮放比例修正
        ratioSizeFix = CCSizeMake(0, -213),
        -- 螢幕縮放比例修正
        ratioSizeFixFrame = CCSizeMake(0, 0),
    })
    --self.gachaSpineNode:setScale(fitResult.scale)
    -- NodeHelperUZ:fitBGSpine(self.gachaSpineNode) -- 需要以背景縮放值為準, 才能對齊球特效
    -- NodeHelperUZ:fitBGSpine(self.bgSpineNode) -- 包含在bgNode中, 此處不處理


    -- 更新 自動刷新時間
    self:updateRefreshAutoTime()

    -- 請求初始資訊
    self:sendRequestInfo()

    SoundManager:getInstance():playMusic("wishingwell_bgm.mp3")
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute()
    
    local clientTime = os.time()

    ---- 免費刷新剩餘時間
    --local refreshFreeLeftTime = 0
    --if self.refreshFreeNextTime ~= -1 then
    --    -- 計算剩餘時間
    --    refreshFreeLeftTime = self.refreshFreeNextTime - clientTime
    --    -- 小於0 視為 0
    --    if refreshFreeLeftTime < 0 then refreshFreeLeftTime = 0 end
    --end
    ---- 設置 免費刷新剩餘時間
    --self.wishingWellUI:setRefreshFree(refreshFreeLeftTime)
    --
    ---- 若 仍在冷卻 則 冷卻
    --if self.requestCooldownLeft > 0 then
    --    self.requestCooldownLeft = self.requestCooldownLeft - 1
    --end

    local isNeedRequestInfo = false

    -- TODO 跨日類改為踢出頁面
    if self.refreshAutoNextTime ~= -1 then
        -- print(string.format("clientTime:%s > self.refreshAutoNextTime:%s ?", os.date("%X", clientTime), os.date("%X", self.refreshAutoNextTime)))
        if clientTime > self.refreshAutoNextTime then
            isNeedRequestInfo = true
        end
    end

    if self.refreshFreeNextTime ~= -1 then
        if clientTime > self.refreshFreeNextTime then
            isNeedRequestInfo = true
        end
    end

    local timeDiff = math.max(0, self.refreshAutoNextTime - clientTime)
    if timeDiff == 0 then
        self.wishingWellUI:setAutoRefreshTime(common:getLanguageString("@WishingWell.refreshAuto") .. "00:00:00")
    else
        local hour = string.format("%02d", math.floor(timeDiff / 3600))
        timeDiff = timeDiff - hour * 3600
        local min = string.format("%02d", math.floor(timeDiff / 60))
        timeDiff = timeDiff - min * 60
        local sec = string.format("%02d", timeDiff)
        self.wishingWellUI:setAutoRefreshTime(common:getLanguageString("@WishingWell.refreshAuto") .. hour .. ":" .. min .. ":" .. sec)
    end
    

    if isNeedRequestInfo then
        -- 若 已結束冷卻
        if self.requestCooldownLeft <= 0 then
            -- 開始冷卻
            self.requestCooldownLeft = self.requestCooldownFrame
            -- print("sendRequestInfo")
            -- 請求 被動刷新
            self:sendRequestInfo()
            
        end
    end
            
end

--[[ 當 頁面 離開 ]]
function Inst:onExit(parentPage)
    self.gachaSpine = nil
    self.gachaSpineNode = nil
    self.onGachaSpineAnim = nil
    self.isSummoning = false
    
    -- 協定收發代理器
    local packetAgent = PacketAgent:inst()
    packetAgent:offAllTag(self)

    if self.task then
        ALFManager:cancel(self.task)
        self.task = nil
    end
end

--[[ 載入 召喚Spine ]]
function Inst:loadSummonSpine ()
    -- 設置 Spine動畫
    if self.gachaSpine == nil and self.subPageCfg.gachaSpine ~= nil then
        local gachaSpineCfg = self.subPageCfg.gachaSpine
        -- 建立 Spine
        self.gachaSpine = SpineContainer:create(gachaSpineCfg[1], gachaSpineCfg[2])
        self.gachaSpineNode = tolua.cast(self.gachaSpine, "CCNode")
        self.wishingWellUI.container:getVarNode("gachaSpineNode"):addChild(self.gachaSpineNode)
        -- 建立抽取動畫事件
        --self.onGachaSpineAnim = Event:new()

        -- 註冊 Spine動畫事件
        self.gachaSpine:registerFunctionHandler("SELF_EVENT", function(unknownArg, tag, eventName)
            self.onGachaSpineAnim:emit(eventName)
        end)

        -- 固定 當特定時機時 隱藏/顯示 獎池泡泡
        self.onGachaSpineAnim:on(function(ctrlr)
            local eventName = ctrlr.data
            if eventName == "hideBubble" then
                self.wishingWellUI.container:getVarNode("itemBubbleNode"):setVisible(false)
            elseif eventName == "showBubble" then
                self.wishingWellUI.container:getVarNode("itemBubbleNode"):setVisible(true)
            end
        end)
        -- 自適應
        local fitResult = NodeHelperUZ:fitBGNode(self.wishingWellUI.container:getVarNode("bgNode"), {
            -- 原始比例
            originalScale = 1,
            -- 縮放比例修正
            ratioSizeFix = CCSizeMake(0, -213),
            -- 螢幕縮放比例修正
            ratioSizeFixFrame = CCSizeMake(0, 0),
        })
        self.gachaSpineNode:setScale(fitResult.scale)
    end
end

function Inst:handleInfo (msgInfo)

    local slf = self

    -- 是否為 抽取
    -- 1.單抽 2.十抽 6.免費抽       
    local isGacha = msgInfo.action == 1 or msgInfo.action == 2 or msgInfo.action == 6

    -- 是否為 刷新
    -- 4.免費刷新 5.收費刷新
    local isRefresh = msgInfo.action == 4 or msgInfo.action == 5

    -- dump(msgInfo, "WishingWell:handleInfo")

    -- 取得 自己類型 的 進度(里程)資訊
    local progressInfo = WishingWellDataMgr:getProgressInfo(self.wishingWellType)

    -- 進度 (幸運值)
    self.wishingWellUI:setProgress(msgInfo.lucky, progressInfo.progressMax)

    -- 進度 獎勵列
    local rewards = {}
    for idx, rewardCfg in ipairs(progressInfo.progressRewards) do 
        local isTaken = msgInfo.take >= idx
        local reward = {
            isDisabled = isTaken,
            isRedpoint = (not isTaken) and msgInfo.lucky >= rewardCfg.progress,
        }
        rewards[idx] = reward
    end
    self.wishingWellUI:setProgressRewards(rewards)

    -- 背景
    self.wishingWellUI:setBackground(self.wishingWellType)

    -- 免費抽次數
    self.freeQuota = msgInfo.freeDraw
    if self.freeQuota == nil then self.freeQuota = 0 end
    self.wishingWellUI:setSummonFree(self.freeQuota, self.subPageCfg.refreshFreeQuota)

    -- 剩餘獎項數/最大獎項數
    self.nowReward = msgInfo.nowReward
    self.maxReward = msgInfo.maxReward
    self.wishingWellUI:setRewardCounter(common:getLanguageString("@WishingWell.count") .. self.nowReward .. "/" .. self.maxReward)

    -- 免費刷新倒數
    local clientTime = os.time()
    local refreshFreeNextTime = msgInfo.lastFreeTime + self.subPageCfg.refreshFreeCooldown_sec
    -- print("WishingWell handleInfo : msgInfo.lastFreeTime "..tostring(msgInfo.lastFreeTime).." / "..tostring(os.date("%X", msgInfo.lastFreeTime)))
    -- 若 尚未達到 下次可免費刷新時間
    if clientTime < refreshFreeNextTime then
        -- 設置 剩餘時間
        self.refreshFreeNextTime = refreshFreeNextTime
        -- print("WishingWell handleInfo : refreshFreeNextTime "..tostring(refreshFreeNextTime).." / "..tostring(os.date("%X", refreshFreeNextTime)))
    -- 若 已可免費刷新
    else
        self.refreshFreeNextTime = -1
    end
    
    -- print("msgInfo.lastFreeTime : "..tostring(os.date("%X", msgInfo.lastFreeTime)))
    -- print("clientTime : "..tostring(os.date("%X", clientTime)))
    -- print("chargedTime : "..tostring(chargedTime))
    -- print("refreshFreeNextTime : "..tostring(os.date("%X", self.refreshFreeNextTime)))

    -- 獎池列表
    local items = {}
    for idx, msgItem in ipairs(msgInfo.displayItem) do
        local msgItem = msgInfo.displayItem[idx]
        
        local itemInfo = {}

        local _itemInfo = InfoAccesser:getItemInfoByStr(msgItem.itemStr)
        for key, val in pairs(_itemInfo) do
            itemInfo[key] = val
        end

        local isGiven = msgItem.given

        -- -- 若尚未抽到
        if not isGiven then                
            -- 設置 獎項稀有度 (泡泡底色)
            itemInfo.rare = self.subPageCfg.itemIdx2bubbleRare[idx]
        else
            itemInfo.rare = 1
        end

        itemInfo.isDisabled = isGiven

        items[idx] = itemInfo
    end
    
    local isShowItemsImmediate = true
    local isDoGachaAnim = false
    
    -- 清除所有抽取或刷新
    self.onGachaSpineAnim:offTag("wishOrRefresh")

    -- 若有收到獎勵
    if msgInfo.reward and msgInfo.reward ~= "" then

        local onItemReceiveClose = nil
        local onItemReceiveSkip = nil

        -- 若為刷新
        if isGacha then
            
            -- 當 物品獲得頁面 跳過
            onItemReceiveSkip = function()
                if not IS_SKIPABLE then return end
                -- 停止動畫
                slf.gachaSpine:stopAllAnimations()
                -- 送出 跳窗 事件
                slf.onGachaSpineAnim:emit("popup")
            end

            -- 當 物品獲得頁面 關閉
            onItemReceiveClose = function()
                -- 停止動畫
                slf.gachaSpine:stopAllAnimations()
                -- 顯示獎池泡泡
                slf.wishingWellUI.container:getVarNode("itemBubbleNode"):setVisible(true)
                -- 送出 動畫完畢 事件
                slf.onGachaSpineAnim:emit("animFinished")
            end
            
            -- 播放 抽取動畫
            self.gachaSpineNode:setVisible(true)
            self.gachaSpine:setToSetupPose()
            self.gachaSpine:runAnimation(1, "WishOneTen", 0)
            isDoGachaAnim = true

            -- 播放 抽卡演出音樂
            if self.subPageCfg.summonBgm then
                SoundManager:getInstance():playMusic(self.subPageCfg.summonBgm, false)
            end

            -- 當 抽取動畫
            self.onGachaSpineAnim:on(function(ctrlr)
                local eventName = ctrlr.data
                -- 跳窗
                if eventName == "popup" then
                    -- 顯示 物品獲得頁面
                    CommItemReceivePage:show(true)
                    SoundManager:getInstance():playMusic("wishingwell_bgm.mp3")
                end

            end):tag("wishOrRefresh")

            isShowItemsImmediate = false -- 不立即顯示道具
        end

        -- 設置資料
        local itemStrs = common:split(msgInfo.reward, ",")

        -- dump(itemStrs, "wishingWell msgInfo.reward")

        local totalInfos = {}
        for idx, itemStr in ipairs(itemStrs) do
            local itemInfo = InfoAccesser:getItemInfoByStr(itemStr)
            totalInfos[#totalInfos+1] = itemInfo
        end
        CommItemReceivePage:prepare({
            title = common:getLanguageString("@RewardItem2"),
            isShowManual = isGacha,
            itemInfos = totalInfos,
            onceClose_fn = onItemReceiveClose,
            onceSkip_fn = onItemReceiveSkip,
        })
        
        -- 推送顯示
        PageManager.pushPage("CommPop.CommItemReceivePage")
    end

    -- 若 為 刷新
    if isRefresh then
        self.gachaSpineNode:setVisible(true)
        self.parentPage.tabStorage:lockInput(true)
        self.wishingWellUI:setBlock(true)
        self.wishingWellUI.onBlockBtn = function()
            if not IS_SKIPABLE then return end
            slf.gachaSpine:stopAllAnimations()
            slf.onGachaSpineAnim:emit("showBubble")
            slf.onGachaSpineAnim:emit("end")
        end
        
        -- 當 抽取動畫(刷新)
        self.onGachaSpineAnim:on(function(ctrlr)
            local eventName = ctrlr.data

            if eventName == "end" then
                slf.parentPage.tabStorage:lockInput(false)
                slf.wishingWellUI.onBlockBtn = nil
                slf.wishingWellUI:setBlock(false)
                -- 隱藏 抽取動畫
                slf.gachaSpineNode:setVisible(false)
                -- 送出 動畫完結
                slf.onGachaSpineAnim:emit("animFinished")
            end
        end):tag("WishRefresh")
        self.gachaSpine:setToSetupPose()
        self.gachaSpine:runAnimation(1, "WishRefresh", 0)
        isDoGachaAnim = true
        isShowItemsImmediate = false -- 不立即顯示道具
    end

    -- 若要 立即顯示道具
    if isShowItemsImmediate then
        self.wishingWellUI:setItems(items)
    -- 否則 
    else
        -- 當 抽取動畫
        self.onGachaSpineAnim:on(function(ctrlr)
            local eventName = ctrlr.data
            -- 隱藏獎勵 或 跳過動畫 時
            if eventName == "hideBubble" or eventName == "animFinished" then
                slf.wishingWellUI:setItems(items)
                -- 移除所有顯示道具相關
                slf.onGachaSpineAnim:offTag("showItems")
            end
        end):tag("showItems", "wishOrRefresh")
    end

    -- 若有播放 抽取動畫
    if isDoGachaAnim then
        -- 當 抽取動畫結束
        self.onGachaSpineAnim:on(function(ctrlr)
            local eventName = ctrlr.data
            if eventName == "animFinished" then
                -- 隱藏Spine
                slf.gachaSpineNode:setVisible(false)
                -- 移除所有抽取相關
                slf.onGachaSpineAnim:offTag("wishOrRefresh")
                -- 移除自身
                slf.onGachaSpineAnim:offTag("onAnimFinished")
            end
        end):tag("onAnimFinished"):pri(-999)
        self.onGachaSpineAnim:sort()
    end


    -- 更新 玩家持有貨幣資訊
    self:updateCurrency()

    -- 得到的物品，應該是走通用協定，不由此處理
    -- if msgInfo.reward ~= nil then
    --     -- 請求頁面
    --     local itemReceivePage = require("CommPop.CommPop_ItemReceivePage")
    --     -- 設置資料
    --     itemReceivePage:
    --     -- 推送顯示
    --     PageManager.pushPage("CommPop.CommPop_ItemReceivePage")
    -- end

    -- 紅點
    --local isShow, group = WishingWellPageBase_calIsShowRedPoint(msgInfo)
    --RedPointManager_setShowRedPoint(thisPageName, group, isShow)
    --RedPointManager_setOptionData(thisPageName, group, { })
    --WishingWellPageBase_setRedPoint(self.wishingWellUI.container, group)
end

--[[ 更新 貨幣 ]]
function Inst:updateCurrency ()
    -- 更新 父頁面 貨幣資訊 並 取得該次結果
    local currencyDatas = self.parentPage:updateCurrency()
    
    local userHasCount = InfoAccesser:getUserItemCountByStr(self.subPageCfg.summonPriceStr)
    self.wishingWellUI:setSummonPrice(userHasCount)
end

--[[ 送出 請求資訊 ]]
function Inst:sendRequestInfo ()
    if IS_MOCK then
        self:onReceivePacket(nil, {
            opcode = HP_pb.ACTIVITY147_WISHING_INFO_S,
            msg = {
                lucky = 32,
                displayItem = {
                    { itemStr = "10000_1001_100", given = false },
                    { itemStr = "40000_1013_1", given = true },
                    { itemStr = "40000_1014_1", given = false },
                    { itemStr = "10000_1001_100", given = false },
                }
            }
        })
        return
    end
    local msg = Activity4_pb.WishingRequestInfo()
    msg.kind = self.wishingWellType
    common:sendPacket(HP_pb.ACTIVITY147_WISHING_INFO_C, msg, true)
end

--[[ 送出 單抽 ]]
function Inst:sendSummon1 ()
    if self.isSummoning then
        return
    end
    self.isSummoning = true
    -- 載入 召喚Spine
    local gachaSpineCfg = self.subPageCfg.gachaSpine
    local texNum = self.gachaSpine and 0 or 30
    self.task = ALFManager:loadSpineTask(gachaSpineCfg[1] .. "/", gachaSpineCfg[2], texNum, function() 
        self:loadSummonSpine()

        local msg = Activity4_pb.WishingWellDraw()
        msg.kind = self.wishingWellType
        if self.freeQuota > 0 then
            msg.action = 6 -- 1.單抽 2.十抽 3.領幸運獎 4.免費刷新 5.付費刷新 6.星輪免費抽
        else 
            msg.action = 1 -- 1.單抽 2.十抽 3.領幸運獎 4.免費刷新 5.付費刷新 6.星輪免費抽
        end
        common:sendPacket(HP_pb.ACTIVITY147_WISHING_DRAW_C, msg, true)

        self.isSummoning = false
    end)
end

--[[ 送出 十抽 ]]
function Inst:sendSummon10 ()
    if self.isSummoning then
        return
    end
    self.isSummoning = true
    -- 載入 召喚Spine
    local gachaSpineCfg = self.subPageCfg.gachaSpine
    local texNum = self.gachaSpine and 0 or 30
    self.task = ALFManager:loadSpineTask(gachaSpineCfg[1] .. "/", gachaSpineCfg[2], texNum, function() 
        self:loadSummonSpine()

        local msg = Activity4_pb.WishingWellDraw()
        msg.kind = self.wishingWellType
        msg.action = 2 -- 1.單抽 2.十抽 3.領幸運獎 4.免費刷新 5.付費刷新 6.星輪免費抽
        common:sendPacket(HP_pb.ACTIVITY147_WISHING_DRAW_C, msg, true)

        self.isSummoning = false
    end)
end

--[[ 送出 領取 ]]
function Inst:sendClaimReward ()
    local msg = Activity4_pb.WishingWellDraw()
    msg.kind = self.wishingWellType
    msg.action = 3 -- 1.單抽 2.十抽 3.領幸運獎 4.免費刷新 5.付費刷新 6.星輪免費抽
    common:sendPacket(HP_pb.ACTIVITY147_WISHING_DRAW_C, msg, true)
end

--[[ 送出 手動刷新 ]]
function Inst:sendManualRefresh ()
    --if self.isSummoning then
    --    return
    --end
    --self.isSummoning = true
    ---- 載入 召喚Spine
    --local gachaSpineCfg = self.subPageCfg.gachaSpine
    --local texNum = self.gachaSpine and 0 or 30
    --self.task = ALFManager:loadSpineTask(gachaSpineCfg[1] .. "/", gachaSpineCfg[2], texNum, function() 
    --    self:loadSummonSpine()
    --
    --    local msg = Activity4_pb.WishingWellDraw()
    --    msg.kind = self.wishingWellType
    --
    --    -- 若 免費刷新沒有倒數中 則 免費刷新
    --    if self.refreshFreeNextTime == -1 then
    --        msg.action = 4 -- 1.單抽 2.十抽 3.領幸運獎 4.免費刷新 5.付費刷新 6.星輪免費抽
    --    else
    --        msg.action = 5
    --    end
    --    common:sendPacket(HP_pb.ACTIVITY147_WISHING_DRAW_C, msg, true)
    --
    --    self.isSummoning = false
    --end)
end


--[[ 更新 自動刷新 時間 ]]
function Inst:updateRefreshAutoTime(lastRefreshTime)

    local nextTime

    -- 若 存在 上次刷新時間 則
    if lastRefreshTime ~= nil and lastRefreshTime > 0 then
        
        nextTime = lastRefreshTime + 86400 --[[ 1天 ]]

    -- 否則 以目前時間推算
    else
        -- Client安全時間 (不差Server時間太多)
        local clientSafeTime = TimeDateUtil:getClientSafeTime()

        -- 刷新日期 先設為 本地日期
        local nextDate = TimeDateUtil:utcTime2LocalDate(clientSafeTime)
        
        -- 調整 刷新日期 為 以UTC+8而言 的 明天00h:00m
        nextDate.day = nextDate.day + 1
        nextDate.hour = 0
        -- nextDate.min = nextDate.min + 1 -- test
        nextDate.min = 0
        nextDate.sec = 0
        -- 調整 刷新日期 校正回UTC+0
        nextDate.hour = nextDate.hour - 8

        nextTime = TimeDateUtil:utcDate2Time(nextDate)

    end

    -- 設置 自動刷新 下次時間
    self.refreshAutoNextTime = nextTime
    -- print("set self.refreshAutoNextTime to "..os.date("%X", nextTime))
end

function WishingWellPageBase_calIsShowRedPoint(msg)
    --if not msg then
    --    return false
    --end
    --local freeDraw = msg.freeDraw or 0
    --local group = msg.kind
    --
    --return freeDraw > 0, group
end

function WishingWellPageBase_setRedPoint(container, group)
    require("Util.RedPointManager")
    --NodeHelper:setNodesVisible(container, {["mRedPoint"] = RedPointManager_getShowRedPoint(thisPageName, group)})
end

return Inst