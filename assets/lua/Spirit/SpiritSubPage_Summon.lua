
--[[ 
    name: SpiritSubPage_Summon
    desc: 精靈 子頁面 召喚 
    author: youzi
    update: 2023/7/6 17:15
    description: 
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件
local Activity4_pb = require("Activity4_pb")

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local TimeDateUtil = require("Util.TimeDateUtil")
local InfoAccesser = require("Util.InfoAccesser")
local Async = require("Util.Async")

local SpiritDataMgr = require("Spirit.SpiritDataMgr")

local CommItem = require("CommUnit.CommItem")
local CommItemReceivePage = require("CommPop.CommItemReceivePage")

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ UI檔案 ]]
local CCBI_FILE = "SpiritSummon.ccbi"

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
    onBtnClick_1 = "onSummonBtn",
    onBtnClick_2 = "onSummon10Btn",
}

--[[ 協定 ]]
local OPCODES = {
    ACTIVITY154_S = HP_pb.ACTIVITY154_S,
}

--[[ 進度獎勵數 ]]
local REWARD_COUNT = 4

--[[ 里程碑 獎勵道具 UI 位置偏移 ]]
local PROGRESS_REWARD_ITEM_UI_POS_OFFSET = ccp(0, 10)

--[[ UI上的 獎項 顯示 的 百分比進度位置]]
-- 因為 獎項的位置不一定在百分比上 所以要以此作為實際顯示位置的判斷
local UI_REWARD_PROGRESS_PERCENT = {
    24, 49, 74, 100
}

local SUMMON_POPUP_CB = "summonDone"


--[[ 本體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 
    text
    
    var 

        progressBarNode 進度條 容器
        progressBar 進度條
        progressNumText 進度 數字
        progressDescText 進度 描述文字

        rewardImg_1 ~ rewardImg_4 里程獎勵 1~4
        rewardProgressText_1 ~ rewardProgressText_4 里程獎勵所需進度 文字 1~4
        rewardRedpoint_1 ~ rewardRedpoint_4 里程獎勵紅點 1~4

        summonPriceImg 單抽價格圖片
        summonFreeText 免費單抽 文字
        summonFreePriceImg 免費抽價格圖標
        freePriceText 免費抽 價格 文字 0

        summon10PriceText 十連抽 價格 文字
        summon10PriceImg 十連抽 價格 圖片

        summonPittyLeftDescText 保底描述 文字
        
        mCostTxt1 單抽付費 文字
        mFreeLabel  免費單抽 文字

        freeChargeDescText 免費抽 倒數 描述 文字
        freeChargeTimeText 免費抽 倒數 時間 文字
        
    event
    
--]]



-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

--[[ 父頁面 ]]
Inst.parentPage = nil

--[[ 容器 ]]
Inst.container = nil

--[[ 主要Spine ]]
Inst.spineEntry = nil
Inst.spineEntryNode = nil
--[[ 召喚Spine ]]
Inst.spineMain = nil
Inst.spineMainNode = nil


--[[ 當 關閉 行為 ]]
Inst.onceClose_fn = nil

--[[ 子頁面資訊 ]]
Inst.subPageName = "Summon"
Inst.subPageCfg = nil

--[[ 免費抽次數 ]]
Inst.summonFreeQuota = 0
--[[ 現有貨幣 ]]
Inst.summonCurrency = 0
--[[ 單抽價格 ]]
Inst.summonPrice1 = 0
--[[ 十抽價格 ]]
Inst.summonPrice10 = 0

--[[ 抽 所需價格 道具資訊 ]]
Inst.summonPriceStr = nil
Inst.summon10PriceStr = nil

--[[ 下次免費補充時間 ]]
Inst.nextFreeTime = -1

--[[ 獎勵UI ]]
Inst.rewardUIs = {}

--[[ 獎勵 ]]
Inst.rewards = {}

--[[ 請求冷卻幀數 ]]
Inst.requestCooldownFrame = 180
--[[ 請求冷卻剩餘 ]]
Inst.requestCooldownLeft = Inst.requestCooldownFrame


-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)
    local slf = self

    if packet.opcode == HP_pb.ACTIVITY154_S then
        
        if packet.msg == nil then
            local msg = Activity4_pb.CallOfSpriteResponse()
            msg:ParseFromString(packet.msgBuff)
            packet.msg = msg
        end

        self:handleResponseInfo(packet.msg)
    end
end

--[[ 建立 頁面 ]]
function Inst:createPage (parentPage)
    self.parentPage = parentPage
    self.container = ScriptContentBase:create(CCBI_FILE)
    return self.container
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (selfContainer, parentPage)
    local slf = self

    -- 註冊 呼叫行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = HANDLER_MAP[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        elseif string.sub(eventName, 1, 8) == "onGetBox" then
            local idx = tonumber(string.sub(eventName, 9))
            slf:sendClaimReward(idx)
        end
    end)

    -- 所有里程獎勵
    for idx = 1, REWARD_COUNT do 
        -- 建立 通用道具UI
        local commItem = CommItem:new()
        local container = commItem:requestUI()
        container:setScale(CommItem.Scales.icon)
        
        commItem:setShowType(CommItem.ShowType.NORMAL)

        local rewardIdx = idx

        commItem.onClick_fn = function ()
            local reward = slf.rewards[rewardIdx]
            -- 若 紅點有開啟 則 視為 領取獎勵
            if reward.isRedpoint == true then
                slf:sendClaimReward(rewardIdx)
            
            -- 否則 僅顯示提示
            else
                GameUtil:showTip(
                    container,
                    {
                        type = reward.itemInfo.mainType,
                        itemId = reward.itemInfo.itemId,
                    }
                )
            end
        end
        
        -- 放入 UI容器
        local parent = self.container:getVarNode("rewardNode_"..tostring(idx))
        parent:addChild(container)
        container:setAnchorPoint(ccp(0.5, 0.5))
        container:setPosition(PROGRESS_REWARD_ITEM_UI_POS_OFFSET)

        self.rewardUIs[idx] = commItem
    end

    -- 註冊 協定
    self.parentPage:registerPacket(OPCODES)

    -- 取得 子頁面 配置
    self.subPageCfg = SpiritDataMgr:getSubPageCfg(self.subPageName)

    -- 設置 進度 獎勵列
    local progressInfo = SpiritDataMgr:getProgressInfo(self.subPageName)
    for idx = 1, #progressInfo.progressRewards do
        progressInfo.progressRewards[idx].showType = 1 --[[ 單個 ]]
    end
    self:setProgressRewards(progressInfo.progressRewards)

    -- 進度描述文字 (目前沒有要設置內容)
    self:setProgressDesc("")

    -- 設置 Spine動畫
    self.spineMain = SpineContainer:create("Spine/NGUI", "NGUI_61_SpiritSummom")
    self.spineMain:registerFunctionHandler("SELF_EVENT", function(unknownArg, tag, eventName)
        if eventName == "popup" then
            CommItemReceivePage:show()
        end
    end)
    self.spineMainNode = tolua.cast(self.spineMain, "CCNode")
    NodeHelperUZ:fitBGSpine(self.spineMainNode, {
        -- 目標中心點
        pivot = ccp(0.5, 0),
        -- 尺寸
        size = CCSizeMake(720, 1280),
        -- 偏移 
        offset = ccp(0, 0),
    })
    self.spineMain:setToSetupPose()
    self.spineMain:runAnimation(1, "animation2", 0)
    
    self.container:getVarNode("mBGSpineNode"):addChild(self.spineMainNode)

    -- 若 尚未顯示 進入動畫
    if self.parentPage.isShowEntryAnim == false then

        self.spineEntry = SpineContainer:create("Spine/NGUI", "NGUI_62_SpiritSumTra")

        self.spineEntry:registerFunctionHandler("SELF_EVENT", function(unknownArg, tag, eventName)
            if eventName == "ready" then
                -- self.spineEntry:setToSetupPose()
                self.spineEntry:runAnimation(1, "animation", 0)
                self.container:runAnimation("Enter")
            elseif eventName == "end" then
                self.spineEntry:stopAllAnimations()
                self.spineEntryNode:setVisible(false)
            end
        end)
        -- self.spineEntry:setTimeScale(0.1) -- test
        self.spineEntryNode = tolua.cast(self.spineEntry, "CCNode")
        NodeHelperUZ:fitBGSpine(self.spineEntryNode, {
            -- 目標中心點
            pivot = ccp(0.5, 0.05),
            -- 尺寸
            size = CCSizeMake(792, 1267),
            -- 偏移 
            offset = ccp(0, 74),
        })
        self.spineEntry:setToSetupPose()
        self.spineEntry:runAnimation(1, "prepare", 0)
        
        self.container:runAnimation("Enter")
        self.container:stopAllActions()
        -- self.parentPage.tabStorage:anim_In()
        self.container:getVarNode("mBGSpineNode"):addChild(self.spineEntryNode)

        self.parentPage.isShowEntryAnim = true
    end

    -- 預設 關閉 免費刷新
    self:setFreeCooldown(nil)

    -------------------

    -- 請求初始資訊
    self:sendRequestInfo(false)

end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(selfContainer, parentPage)
    
    local clientTime = os.time()

    -- 免費補充剩餘時間
    local nextFreeLeftTime = nil

    -- 若 免費次數 已用完
    if self.summonFreeQuota == 0 then
        -- 若 存在 下次補充時間
        if self.nextFreeTime ~= -1 then
            -- 計算剩餘時間
            nextFreeLeftTime = self.nextFreeTime - clientTime
            -- 小於0 視為 0
            if nextFreeLeftTime < 0 then nextFreeLeftTime = 0 end
        end
    end

    -- 設置 免費補充剩餘時間
    self:setFreeCooldown(nextFreeLeftTime)

    -- 若 仍在冷卻 則 冷卻
    if self.requestCooldownLeft > 0 then
        self.requestCooldownLeft = self.requestCooldownLeft - 1
    end

    local isNeedRequestInfo = false

    if self.nextFreeTime ~= -1 then
        if clientTime > self.nextFreeTime then
            isNeedRequestInfo = true
        end
    end

    if isNeedRequestInfo then
        -- 若 已結束冷卻
        if self.requestCooldownLeft <= 0 then
            -- 開始冷卻
            self.requestCooldownLeft = self.requestCooldownFrame
            -- 請求 被動刷新
            self:sendRequestInfo()
        end
    end
            
end

--[[ 當 頁面 離開 ]]
function Inst:onExit(selfContainer, parentPage)
    self.parentPage:removePacket(OPCODES)
    
    self.spineEntry = nil
    self.spineEntryNode = nil
    self.spineMain = nil
    self.spineMainNode = nil
end

--[[ 當 單抽 按下 ]]
function Inst:onSummonBtn()
    
    -- 若要檢查數量
    -- local summonPrice_itemInfo = InfoAccesser:getItemInfoByStr(self.summonPriceStr)
    -- if summonPrice_itemInfo ~= nil then
    --     if self.summonFreeQuota <= 0 then
    --         local playerHasCount = InfoAccesser:getUserItemCountByStr(self.summonPriceStr)
    --         if playerHasCount < summonPrice_itemInfo.count then 
    --             return
    --         end
    --     end
    -- end

    self:sendSummon1()
end

--[[ 當 十抽 按下 ]]
function Inst:onSummon10Btn()

    -- 若要檢查數量
    -- local summon10Price_itemInfo = InfoAccesser:getItemInfoByStr(self.summon10PriceStr)
    -- if summon10Price_itemInfo == nil then return end
    -- 
    -- local playerHasCount = InfoAccesser:getUserItemCountByStr(self.summon10PriceStr)
    -- if playerHasCount < summon10Price_itemInfo.count then 
    --     return
    -- end

    self:sendSummon10()
end


-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 設置 抽取價格 ]]
function Inst:setSummonPrice (currency, options)
    if options == nil then options = {} end

    if currency == nil then return end

    self.summonCurrency = currency

    -- 價格 圖標
    local node2Sprite = {}
    local node2SpriteScale = {}

    local priceIcon = options["icon"]
    local priceIconScale = options["iconScale"]
    if priceIcon ~= nil then
        node2Sprite["summonPriceImg"] = priceIcon
        node2Sprite["summonFreePriceImg"] = priceIcon
    end
    if priceIconScale ~= nil then
        node2SpriteScale["summonPriceImg"] = priceIconScale
        node2SpriteScale["summonFreePriceImg"] = priceIconScale
    end

    local priceIcon10 = options["icon10"]
    local priceIconScale10 = options["iconScale10"]
    if priceIcon10 ~= nil then
        node2Sprite["summon10PriceImg"] = priceIcon10
    end
    if priceIconScale10 ~= nil then
        node2SpriteScale["summon10PriceImg"] = priceIconScale10
    end

    NodeHelper:setSpriteImage(self.container, node2Sprite, node2SpriteScale)

    -- 單抽價格
    local price1 = options["price1"]
    if price1 ~= nil then
        self.summonPrice1 = price1
    end

    -- 十抽價格
    local price10 = options["price10"]
    if price10 ~= nil then
        self.summonPrice10 = price10
    end

    -- 更新 價格相關
    self:updateSummonPrice()
end

--[[ 設置 抽取免費次數 ]]
function Inst:setSummonFree (quota)
    self.summonFreeQuota = quota
    
    -- 更新 價格相關
    self:updateSummonPrice()
end

--[[ 設置 免費補充時間 ]]
-- countdown: nil:關閉, <0:同步中, 0:可免費刷, >0:倒數時間
function Inst:setFreeCooldown (countdown)
    
    local isFreeCharged = countdown == 0
    local isFreeActive = countdown ~= nil
    if isFreeActive and not isFreeCharged then
        
        local countdownText
        if countdown < 0 then
            countdownText = common:getLanguageString("@syncing")
        else
            -- 剩餘時間 轉至 日期格式
            local leftTimeDate = TimeDateUtil:utcTime2Date(countdown)
            countdownText = string.format(common:getLanguageString("@Spirit.Summon.nextFreeCounter"), leftTimeDate.hour, leftTimeDate.min, leftTimeDate.sec)
        end
        
        NodeHelper:setStringForTTFLabel(self.container, {
            freeChargeTimeText = countdownText,
        })
    end

    NodeHelper:setNodesVisible(self.container, {
        freeChargeDescText = isFreeActive,
        freeChargeTimeText = isFreeActive,
    })
end


--[[ 設置 進度 描述 ]]
function Inst:setProgressDesc (str) 
    NodeHelper:setStringForLabel(self.container, {
        progressDescText = str
    })
end

--[[ 設置 進度 ]]
function Inst:setProgress (progress, progressMax)
    
    -- 紀錄並限制 UI用的 進度
    self.progress_forUI = progress
    if self.progress_forUI > progressMax then
        self.progress_forUI = progressMax
    end

    -- 設置 進度數字
    NodeHelper:setStringForLabel(self.container, {
        progressNumText = tostring(progress)
    })

    self:updateProgressBar()
end

--[[ 更新 進度條 ]]
function Inst:updateProgressBar ()
    
    local progress = self.progress_forUI
    local realPercent = 0

    local lastRewardProgress = 0
    for rewardIdx = 1, REWARD_COUNT do
        local reward = self.rewards[rewardIdx]
        local eachProgressLength = reward.progress - lastRewardProgress
        local ui_percent = UI_REWARD_PROGRESS_PERCENT[rewardIdx]
        if progress >= eachProgressLength then
            progress = progress - eachProgressLength
            realPercent = ui_percent
        else
            local nextRealPercent = ui_percent
            local eachPercent = progress / eachProgressLength
            local addPercent = (nextRealPercent - realPercent) * eachPercent
            realPercent = realPercent + addPercent
            break
        end
        lastRewardProgress = reward.progress
    end

    -- 設置 進度條
    NodeHelperUZ:setProgressBar9Sprite(self.container, "progressBar", realPercent / 100 )
end

--[[ 設置 進度獎勵 ]]
function Inst:setProgressRewards (rewardInfos)
        
    for idx = 1, REWARD_COUNT do while true do

        local commItem = self.rewardUIs[idx]

        local reward = self.rewards[idx]
        if reward == nil then 
            reward = {}
            self.rewards[idx] = reward
        end

        local eachInfo = rewardInfos[idx]

        if eachInfo == nil then break end -- continue

        local idxStr = tostring(idx)

        -- 獎勵
        local itemInfo = eachInfo["itemInfo"]
        if itemInfo ~= nil then
            commItem:autoSetByItemInfo(itemInfo, false)
            reward["itemInfo"] = itemInfo
        end

        -- 顯示類型
        local showType = eachInfo["showType"]
        if showType ~= nil then
            NodeHelper:setNodesVisible(self.container, {
                ["rewardNode_"..idxStr] = showType == 1,
                ["rewardBoxNode_"..idxStr] = showType == 2,
            })
        end

        -- 圖標
        local icon = eachInfo["icon"]
        if icon ~= nil then
            NodeHelper:setSpriteImage(self.container, {
                ["rewardImg_"..idxStr] = icon
            })
        end

        -- 進度
        local progress = eachInfo["progress"]
        if progress ~= nil then
            NodeHelper:setStringForLabel(self.container, {
                ["rewardProgressText_"..idxStr] = tostring(progress)
            })
            reward["progress"] = progress
        end

        -- 是否 啟用
        local isDisabled = eachInfo["isDisabled"]
        if isDisabled ~= nil then    
            NodeHelper:setNodeIsGray(self.container, {
                ["rewardImg_"..idxStr] = isDisabled,
            })
            commItem:setDisabled(isDisabled)
        end

        -- 是否開啟紅點
        local isRedpoint = eachInfo["isRedpoint"]
        if isRedpoint ~= nil then
            NodeHelper:setNodesVisible(self.container, {
                ["rewardRedpoint_"..idxStr] = isRedpoint,
            })
            reward["isRedpoint"] = isRedpoint
        end
        
    break end end
end

--[[ 更新 抽取價格 相關 ]]
function Inst:updateSummonPrice ()
    local isFree = self.summonFreeQuota > 0

    -- 若 有免費
    if isFree then
        
        -- 免費次數 文字標示
        -- local freeText = common:getLanguageString("free #v1#/#v2#", self.summonFreeQuota, FREE_QUOTA_MAX)
        -- NodeHelper:setStringForTTFLabel(self.container, {
        --     summonFreeText = freeText
        -- })

    -- 若 無免費
    else
        -- 價格 文字標示
        local priceStr = string.format("%s", self.summonPrice1)
        local price10Str = string.format("%s", self.summonPrice10)
        NodeHelper:setStringForTTFLabel(self.container, {
            summonPriceText = priceStr,
            summon10PriceText = price10Str,
        })
    end

    -- 依照是否有免費次數 切換 顯示
    NodeHelper:setNodesVisible(self.container, {
        summonFreeText = isFree,
        freePriceText = isFree,
        summonPriceText = not isFree,
        summonPriceImg = not isFree,
        mCostTxt1 = not isFree,
        mFreeLabel = isFree,
    })

end

--[[ 更新 貨幣 ]]
function Inst:updateCurrency ()
    
    -- 更新 父頁面 貨幣資訊 並 取得該次結果
    local currencyDatas = self.parentPage:updateCurrency()
    
    local summonPriceUserHas = 0
    if #currencyDatas > 0 then
        summonPriceUserHas = currencyDatas[1].count
    end
    self:setSummonPrice(summonPriceUserHas)
end

--[[ 處理 回傳 ]]
function Inst:handleResponseInfo (msgInfo, onReceiveDone)
    local slf = self

    -- 取得 自己類型 的 進度(里程)資訊
    local progressInfo = SpiritDataMgr:getProgressInfo(self.subPageName)

    -- 進度 (幸運值)
    self:setProgress(msgInfo.lucky, progressInfo.progressMax)
    
    -- 設置 單/十抽 價格
    self.summonPriceStr = msgInfo.singleItem
    self.summon10PriceStr = msgInfo.tenItem

    local summonPrice_itemInfo = InfoAccesser:getItemInfoByStr(self.summonPriceStr)
    local summon10Price_itemInfo = InfoAccesser:getItemInfoByStr(self.summon10PriceStr)
    local summonPrice_itemIconCfg = InfoAccesser:getItemIconCfg(summonPrice_itemInfo.type, summonPrice_itemInfo.id, "SummonPrice")
    local summon10Price_itemIconCfg = InfoAccesser:getItemIconCfg(summon10Price_itemInfo.type, summonPrice_itemInfo.id, "SummonPrice")

    local options = {
        icon = summonPrice_itemInfo.icon,
        icon10 = summon10Price_itemInfo.icon,
        price1 = summonPrice_itemInfo.count,
        price10 = summon10Price_itemInfo.count,
    }
    
    if summonPrice_itemIconCfg ~= nil then
        options.iconScale = summonPrice_itemIconCfg.scale
    end
    if summon10Price_itemIconCfg ~= nil then
        options.iconScale10 = summon10Price_itemIconCfg.scale
    end

    self:setSummonPrice(0, options)
    

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
    self:setProgressRewards(rewards)

    -- 免費抽次數
    self.summonFreeQuota = msgInfo.free
    if self.summonFreeQuota == nil then self.summonFreeQuota = 0 end
    self:setSummonFree(self.summonFreeQuota)
    
    -- 設置 下次免費補充時間
    self.nextFreeTime = TimeDateUtil:getNextDayUTCTime(8)

    -- 保底
    -- NodeHelper:setStringForTTFLabel(self.container, {
    --     summonPittyLeftDescText = common:getLanguageString("@Spirit.Summon.pittyDesc", msgInfo.pitty)
    -- })

    -- 若有收到獎勵
    if msgInfo.reward and msgInfo.reward ~= "" then

        local onReceiveItemDone = nil
        local onReceiveItemSkip = nil

        -- 若 為
        -- 1.單抽 2.十抽 3.免費抽
        local act = msgInfo.action
        local isSummon = act == 1 or act == 2 or act == 3 
        if isSummon then
            
            -- 設置 當 召喚動畫結束
            -- 處理 回應 (且 當獲得物品視窗關閉後)
            onReceiveItemDone = function()
                -- 召喚動畫 回復為 背景
                slf.spineMain:setToSetupPose()
                slf.spineMain:runAnimation(1, "animation2", 0)
                -- UI返場 
                slf.container:runAnimation("SummonIn")
                -- 分頁列返場 
                slf.parentPage.tabStorage:anim_In()
            end

            onReceiveItemSkip = function()
                slf.spineMain:stopAllAnimations()
                CommItemReceivePage:show(true)
            end
            
            -- 召喚 動畫
            self.spineMain:setToSetupPose()
            self.spineMain:runAnimation(1, "animation", 0)
            -- 召喚時UI退場
            self.container:runAnimation("SummonOut")
            -- 分頁列UI退場
            self.parentPage.tabStorage:anim_Out()
        end

        -- 設置資料
        local itemStrs = common:split(msgInfo.reward, ",")

        -- dump(itemStrs, "summon msgInfo.reward")

        local totalInfos = {}
        for idx, itemStr in ipairs(itemStrs) do
            local itemInfo = InfoAccesser:getItemInfoByStr(itemStr)
            totalInfos[#totalInfos+1] = itemInfo
        end
        CommItemReceivePage:prepare({
            title = common:getLanguageString("@RewardItem2"),
            isShowManual = isSummon,
            itemInfos = totalInfos,
            onceClose_fn = onReceiveItemDone,
            onceSkip_fn = onReceiveItemSkip,
        })
        
        -- 推送顯示
        PageManager.pushPage("CommPop.CommItemReceivePage")
    end


    -- 更新 玩家持有貨幣資訊
    self:updateCurrency()

end

--[[ 送出 請求資訊 ]]
function Inst:sendRequestInfo (isShowLoading)
    if isShowLoading == nil then isShowLoading = true end
    if IS_MOCK then
        self:onReceivePacket({
            opcode = HP_pb.ACTIVITY154_S,
            msg = {
                lucky = 32,
                take = 2,
                free = 0,
                singleItem = "10000_1001_120",
                tenItem = "10000_1001_1200",
            }
        })
        return
    end
    local msg = Activity4_pb.CallOfSpriteRequest()
    msg.action = 0 -- 0.同步資訊 1.單抽 2.十抽 3.免費抽 4.領取哩程獎勵
    common:sendPacket(HP_pb.ACTIVITY154_C, msg, isShowLoading)
end

--[[ 送出 單抽 ]]
function Inst:sendSummon1 ()
    local msg = Activity4_pb.CallOfSpriteRequest()
    if self.summonFreeQuota > 0 then
        msg.action = 3 -- 0.同步資訊 1.單抽 2.十抽 3.免費抽 4.領取哩程獎勵
    else 
        msg.action = 1 -- 0.同步資訊 1.單抽 2.十抽 3.免費抽 4.領取哩程獎勵
    end
    common:sendPacket(HP_pb.ACTIVITY154_C, msg, true)
end

--[[ 送出 十抽 ]]
function Inst:sendSummon10 ()
    local msg = Activity4_pb.CallOfSpriteRequest()
    msg.action = 2 -- 0.同步資訊 1.單抽 2.十抽 3.免費抽 4.領取哩程獎勵
    common:sendPacket(HP_pb.ACTIVITY154_C, msg, true)
end

--[[ 送出 領取 ]]
function Inst:sendClaimReward (idx)
    local msg = Activity4_pb.CallOfSpriteRequest()
    msg.action = 4 -- 0.同步資訊 1.單抽 2.十抽 3.免費抽 4.領取哩程獎勵
    common:sendPacket(HP_pb.ACTIVITY154_C, msg, true)
end


return Inst