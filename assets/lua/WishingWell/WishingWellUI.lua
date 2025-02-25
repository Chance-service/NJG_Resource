
--[[ 
    name: WishingWellUI
    desc: 許願輪UI
    author: youzi
    update: 2023/6/9 12:57
    description: 
--]]


-- 引用 --------------------

local HP_pb = require("HP_pb") -- 包含协议id文件


local TimeDateUtil = require("Util.TimeDateUtil")
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")

local CommItem = require("CommUnit.CommItem")

----------------------------


--[[ 字典 ]] -- (若有將WishingWell.lang轉寫入Language.lang中可移除此處與WishingWell.lang)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/WishingWell.lang"] then
--    __lang_loaded["Lang/WishingWell.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/WishingWell.lang")
--end

--[[ UI檔案 ]]
local CCBI_FILE = "WishingWell.ccbi"

--[[ 進度獎勵數 ]]
local REWARD_COUNT = 4

--[[ 物品數量 ]]
local ITEM_COUNT = 7

--[[ 最大稀有度 ]]
local RARE_MAX = 4

--[[ 里程碑 獎勵道具 UI 位置偏移 ]]
local PROGRESS_REWARD_ITEM_UI_POS_OFFSET = ccp(0, 10)

--[[ UI上的 獎項 顯示 的 百分比進度位置]]
-- 因為 獎項的位置不一定在百分比上 所以要以此作為實際顯示位置的判斷
local UI_REWARD_PROGRESS_PERCENT = {
    24, 49, 74, 100
}

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
    onRefreshBtn  = "onRefreshBtn",
    onSummonBtn   = "onSummonBtn",
    onSummon10Btn = "onSummon10Btn",
    -- onRewardClick_X 交由 registerFunctionHandler 處理
    onBlockBtn = "onBlockBtn",
}

--[[ 背景種類 ]]
local BG_TYPE = {
    1, 2, 3
}

--[[ 腳本主體 ]]
local WishingWellUI = {}

--[[ 
    text
        @WishingWell.refreshPayPriceText 付費刷新文字
        @WishingWell.refreshFreeCounter 免費刷新倒數文字

    var
        bg_1 ~ bg3 背景 1~3

        refreshBtn 刷新 按鈕
        
        refreshFreeNode 免費刷新 容器
        refreshFreeBtnText 免費刷新 按鈕文字

        refreshPayNode 付費刷新 容器
        refreshPayBtnText 付費刷新 按鈕文字
        refreshFreeCounterText 免費刷新 倒數文字

        summonBtn 單抽 按鈕
        summonBtnText 單抽 按鈕 文字
        summonPriceText 單抽價格文字
        summonPriceImg 單抽價格圖片
        summonFreeText 免費單抽 文字

        summon10Btn 十連抽 按鈕
        summon10BtnText 十連抽 按鈕 文字
        summon10PriceText 十連抽 價格 文字
        summon10PriceImg 十連抽 價格 圖片

        item_0~item_6 道具容器 0~6

        rewardImg_1 ~ rewardImg_4 里程獎勵 1~4
        rewardProgressText_1 ~ rewardProgressText_4 里程獎勵所需進度 文字 1~4
        rewardRedpoint_1 ~ rewardRedpoint_4 里程獎勵紅點 1~4

        progressBarNode 進度條 容器
        progressBar 進度條
        progressNumText 進度 數字
        progressDescText 進度 描述文字
    
    event
        onRewardClick_1 ~ onRewardClick_4 當 里程獎勵點選 1~4
        onRefreshBtn 當 刷新按鈕 按下
        onSummonBtn 當 單抽按鈕 按下
        onSummon10Btn 當 十連抽按鈕 按下

--]]


function WishingWellUI:new ()

    local inst = {}

    --[[ 容器 ]]
    inst.container = nil
    
    --[[ 抽抽價格相關 ]]
    inst.summonFreeQuota = 0
    inst.summonFreeQuotaMax = 0
    inst.summonCurrency = 0
    inst.summonPrice1 = 0
    inst.summonPrice10 = 0

    --[[ 物品 ]]
    inst.items = {}

    --[[ 獎勵UI ]]
    inst.rewardUIs = {}

    --[[ 獎勵 ]]
    inst.rewards = {}

    --[[ 當前進度 ]]
    inst.progress_forUI = 0

    --[[ 當 獎勵 點選 ]]
    inst.onRewardClick = function (rewardIdx) end
    --[[ 當 物品 點選 ]]
    inst.onItemClick = function (itemIdx, itemInfo, itemUI) end
    --[[ 當 單抽 點擊 ]]
    inst.onSummonBtn = function () end
    --[[ 當 十抽 點擊 ]]
    inst.onSummon10Btn = function () end
    --[[ 當 刷新 點擊 ]]
    inst.onRefreshBtn = function () end
    --[[ 當 擋板 點擊 ]]
    inst.onBlockBtn = function () end

    --[[ 創建頁面 ]]
    function inst:createPage ()

        local slf = self

        self.container = ScriptContentBase:create(CCBI_FILE)
        
        -- 註冊 呼叫 行為
        self.container:registerFunctionHandler(function (eventName, container)
            local funcName = HANDLER_MAP[eventName]
            local func = slf[funcName]
            if func then
                func(slf, container)
            elseif string.sub(eventName, 1, 14) == "onRewardClick_" then
                local idx = tonumber(string.sub(eventName, 15))
                slf.onRewardClick(idx)
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
                    slf.onRewardClick(rewardIdx)
                
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
            local parent = slf.container:getVarNode("rewardNode_"..tostring(idx))
            parent:addChild(container)
            container:setAnchorPoint(ccp(0.5, 0.5))
            container:setPosition(PROGRESS_REWARD_ITEM_UI_POS_OFFSET)

            slf.rewardUIs[idx] = commItem
        end

        self.container:getVarNode("blockMenu"):setVisible(false)

        -- 預設背景
        self:setBackground(BG_TYPE[1])

        return self.container
    end

    --[[ 設置背景 ]]
    function inst:setBackground (wishingWellType)
        local node2Visible = {}
        for idx = 1, #BG_TYPE do
            local bgType = BG_TYPE[idx]
            local nodeName = "bg_"..tostring(bgType)
            -- local visible = bgType == wishingWellType
            local visible = false
            node2Visible[nodeName] = visible
        end
        NodeHelper:setNodesVisible(self.container, node2Visible)
    end

    --[[ 設置 道具列表 ]]
    function inst:setItems (itemInfos)
        
        -- 稀有度顯示
        local rareBubbleVisibles = {}
        
        for idx = 1, ITEM_COUNT do 
            for rareIdx = 1, RARE_MAX do 
                local varName = string.format("itemBubble_%s_%s", tostring(idx-1), tostring(rareIdx))
                rareBubbleVisibles[varName] = rareIdx == 1
            end
        end

        for idx = 1, #itemInfos do while true do
            local idxStr = tostring(idx-1)

            local info = itemInfos[idx]
            if info == nil then break end -- continue
            
            local item = inst.items[idx]
            local itemContainer

            local isNew = item == nil

            if isNew then
                item = CommItem:new()
            end
            itemContainer = item:requestUI()

            self.items[idx] = item

            item:autoSetByItemInfo(info)
            item:setDisabled(info.isDisabled)

            local itemIdx = idx
            item.onClick_fn = function ()
                self.onItemClick(itemIdx, info, itemContainer)
            end

            -- 泡泡 稀有度
            local rare = info.rare

            if rare ~= 1 then
                local varName = string.format("itemBubble_%s_%s", idxStr, tostring(rare))
                rareBubbleVisibles[varName] = true
                local firstVarName = string.format("itemBubble_%s_1", idxStr)
                rareBubbleVisibles[firstVarName] = false
            end

            -- 關閉/開啟

            if isNew then
                -- 設置 至 容器
                local node = self.container:getVarNode("item_"..idxStr)
                if node ~= nil then
                    node:addChild(itemContainer)
                    itemContainer:setAnchorPoint(ccp(0.5, 0.5))
                    itemContainer:setPosition(ccp(0, 0))
                end
            end
        break end end

        -- dump(rareBubbleVisibles, "rareBubbleVisibles")
        NodeHelper:setNodesVisible(inst.container, rareBubbleVisibles)
        
        NodeHelper:setNodeIsGray(inst.container, node2Gray)

    end

    --[[ 設置 刷新價格 ]]
    function inst:setRefreshPrice (price, icon)
        
        NodeHelper:setStringForTTFLabel(inst.container, {
            refreshPayBtnText = common:getLanguageString("@WishingWell.refreshPayPriceText", price),
        })
        
        local refreshPayBtnTextNode = inst.container:getVarNode("refreshPayBtnText")
        local refreshPayPriceImg = inst.container:getVarSprite("refreshPayPriceImg")
        local textNodePosLeft = refreshPayBtnTextNode:getPositionX() - (refreshPayBtnTextNode:getContentSize().width * refreshPayBtnTextNode:getAnchorPoint().x)
        refreshPayPriceImg:setPositionX(textNodePosLeft)

        if icon ~= nil then
            refreshPayPriceImg:setTexture(icon)
        end
    end
    
    --[[ 設置 免費刷新 ]]
    -- countdown: nil:關閉, <0:同步中, 0:可免費刷, >0:倒數時間
    function inst:setRefreshFree (countdown)
        
        local isFreeCharged = countdown == 0
        local isFreeActive = countdown ~= nil

        if isFreeActive and not isFreeCharged then
            
            local countdownText
            if countdown < 0 then
                countdownText = common:getLanguageString("@WishingWell.syncing")
            else
                -- 剩餘時間 轉至 日期格式
                local leftTimeDate = TimeDateUtil:utcTime2Date(countdown)
                countdownText = string.format(common:getLanguageString("@WishingWell.refreshFreeCounter"), leftTimeDate.hour, leftTimeDate.min, leftTimeDate.sec)
            end
            
            NodeHelper:setStringForTTFLabel(inst.container, {
                refreshFreeCounterText = countdownText,
            })
        end

        NodeHelper:setNodesVisible(inst.container, {
            refreshPayNode = not isFreeCharged,
            refreshFreeNode = isFreeCharged,
            refreshFreeCounterText = isFreeActive,
        })
    end

    --[[ 設置 抽取價格 ]]
    function inst:setSummonPrice (currency, options)
        if options == nil then options = {} end

        if currency == nil then return end

        inst.summonCurrency = currency

        -- 價格 圖標
        local priceIcon = options["icon"]
        local priceIconScale = options["iconScale"]
        if priceIcon ~= nil then
            local scaleMap = {}
            if priceIconScale ~= nil then
                scaleMap.summonPriceImg = priceIconScale
                scaleMap.summon10PriceImg = priceIconScale
            end
            NodeHelper:setSpriteImage(inst.container, {
                summonPriceImg = priceIcon,
                summon10PriceImg = priceIcon,
            }, scaleMap)
        end

        -- 單抽價格
        local price1 = options["price1"]
        if price1 ~= nil then
            inst.summonPrice1 = price1
        end

        -- 十抽價格
        local price10 = options["price10"]
        if price10 ~= nil then
            inst.summonPrice10 = price10
        end

        -- 更新 價格相關
        inst:updateSummonPrice()
    end

    --[[ 設置 抽取免費次數 ]]
    function inst:setSummonFree (quota, quotaMax)
        inst.summonFreeQuota = quota
        if quotaMax ~= nil then
            inst.summonFreeQuotaMax = quotaMax
        end
        
        -- 更新 價格相關
        inst:updateSummonPrice()
    end

    --[[ 更新 抽取價格 相關 ]]
    function inst:updateSummonPrice ()
        local isFree = inst.summonFreeQuota > 0

        -- 若 有免費
        if isFree then
            
            -- 免費次數 文字標示
            local freeText = common:getLanguageString("@Shop.RefreshManual.FreeTimes", inst.summonFreeQuota, inst.summonFreeQuotaMax)
            NodeHelper:setStringForTTFLabel(inst.container, {
                summonFreeText = freeText
            })

        -- 若 無免費
        else
            -- 價格 文字標示
            local priceStr = string.format("%s", inst.summonPrice1)
            local price10Str = string.format("%s", inst.summonPrice10)
            NodeHelper:setStringForTTFLabel(inst.container, {
                summonPriceText = priceStr,
                summon10PriceText = price10Str,
            })
        end

        -- 依照是否有免費次數 切換 顯示
        NodeHelper:setNodesVisible(inst.container, {
            summonFreeText = isFree,
            summonPriceText = not isFree,
            summonPriceImg = not isFree,
        })

    end

    --[[ 設置 剩餘獎項 數量 ]]
    function inst:setRewardCounter (str) 
        NodeHelper:setStringForLabel(inst.container, {
            mRewardCountTxt = str
        })
    end

    --[[ 設置 進度 描述 ]]
    function inst:setProgressDesc (str) 
        NodeHelper:setStringForLabel(inst.container, {
            progressDescText = str
        })
    end
    
    --[[ 設置 自動刷新 倒數 ]]
    function inst:setAutoRefreshTime (str) 
        NodeHelper:setStringForLabel(inst.container, {
            mAutoRefreshTime = str
        })
    end

    --[[ 設置 進度 ]]
    function inst:setProgress (progress, progressMax)
        
        -- 紀錄並限制 UI用的 進度
        inst.progress_forUI = progress
        if inst.progress_forUI > progressMax then
            inst.progress_forUI = progressMax
        end

        -- 設置 進度數字
        NodeHelper:setStringForLabel(inst.container, {
            progressNumText = tostring(progress)
        })

        inst:updateProgressBar()
    end

    --[[ 更新 進度條 ]]
    function inst:updateProgressBar ()
        
        local progress = inst.progress_forUI
        local realPercent = 0

        local lastRewardProgress = 0
        for rewardIdx = 1, REWARD_COUNT do
            local reward = inst.rewards[rewardIdx]
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
        NodeHelperUZ:setProgressBar9Sprite(inst.container, "progressBar", realPercent / 100 )
    end

    --[[ 設置 進度獎勵 ]]
    function inst:setProgressRewards (rewardInfos)
        
        for idx = 1, REWARD_COUNT do while true do

            local commItem = inst.rewardUIs[idx]

            local reward = inst.rewards[idx]
            if reward == nil then 
                reward = {}
                inst.rewards[idx] = reward
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
                NodeHelper:setNodesVisible(inst.container, {
                    ["rewardNode_"..idxStr] = showType == 1,
                    ["rewardBoxNode_"..idxStr] = showType == 2,
                })
            end

            -- 圖標
            local icon = eachInfo["icon"]
            if icon ~= nil then
                NodeHelper:setSpriteImage(inst.container, {
                    ["rewardImg_"..idxStr] = icon
                })
            end

            -- 進度
            local progress = eachInfo["progress"]
            if progress ~= nil then
                NodeHelper:setStringForLabel(inst.container, {
                    ["rewardProgressText_"..idxStr] = tostring(progress)
                })
                reward["progress"] = progress
            end

            -- 是否 啟用
            local isDisabled = eachInfo["isDisabled"]
            if isDisabled ~= nil then    
                NodeHelper:setNodeIsGray(inst.container, {
                    ["rewardImg_"..idxStr] = isDisabled,
                })
                commItem:setDisabled(isDisabled)
            end

            -- 是否開啟紅點
            local isRedpoint = eachInfo["isRedpoint"]
            if isRedpoint ~= nil then
                NodeHelper:setNodesVisible(inst.container, {
                    ["rewardRedpoint_"..idxStr] = isRedpoint,
                })
                reward["isRedpoint"] = isRedpoint
            end
            
        break end end
    end

    --[[ 設置 擋板 ]]
    function inst:setBlock(isBlock)
        self.container:getVarNode("blockMenu"):setVisible(isBlock)
    end

    return inst
end

return WishingWellUI