
local ResManagerForLua = require("ResManagerForLua")
local Const = require("Const_pb")
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local EquipManager = require("Equip.EquipManager")
local InfoAccesser = require("Util.InfoAccesser")

local ItemLineContent = {}


function ItemLineContent.new()

    -- 商品 每行項目
    local Inst = {}

    -- 行UI
    Inst.ccbiFile = "FairContentItem.ccbi"
    
    -- 每項(列)UI
    Inst.itemCCBI = "FairContent.ccbi"

    -- 項列數量
    Inst.itemCount_perLine = 2

    Inst.onBuyBtn_fn = function () end
    Inst.onFeet_fn = function () end
    
    Inst.getItemInfoIndexById_fn = function(id) end
    Inst.getItemInfoAndData_fn = function(idx) end

    Inst.onBuy_fn = function (itemInfo, itemData) end

    --[[ 當 被呼叫 ]]
    function Inst:onFunction(eventName, container)
        -- 刷新視圖
        if eventName == "luaRefreshItemView" then
            self:onRefreshItemView(container)
        
        -- 按下 購買 按鈕
        elseif eventName == "onBuyBtn" then
            self.onBuyBtn_fn(container)
        
        -- 不知道幹嘛
        elseif eventName == "onFeet" then
            self.onFeet_fn(container)
        end
    end

    
    --[[ 填充 獎勵 物品 (單項) ]]
    function Inst.fillRewardItem(container, rewardCfg, params)
        local nodesVisible = {}
        local lb2Str = {}
        local sprite2Img = {}
        local menu2Quality = {}
        local btnSprite = {}

        local mainNode = params.mainNode
        local countNode = params.countNode
        local nameNode = params.nameNode
        local frameNode = params.frameNode
        local picNode = params.picNode

        -- 取得 設定
        local cfg = rewardCfg[1]
        -- 設 主節點 是否顯示 為 設定是否存在
        nodesVisible[mainNode] = cfg ~= nil
        -- 若 設定 存在
        if cfg ~= nil then
            -- 取得 資源資訊 (以 物品 的 類型,id,數量)
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
            -- 若 資源存在
            if resInfo ~= nil then
                sprite2Img[picNode] = resInfo.icon
                lb2Str[countNode] = "x" .. cfg.count
                lb2Str[nameNode] = resInfo.name
                menu2Quality[frameNode] = resInfo.quality
            else
                CCLuaLog("Error::***reward item not found!!")
            end
        end

        NodeHelper:setNodesVisible(container, nodesVisible)
        NodeHelper:setStringForLabel(container, lb2Str)
        NodeHelper:setSpriteImage(container, sprite2Img)
        NodeHelper:setQualityFrames(container, menu2Quality)
    end

    --[[ 顯示 提示 ]]
    function Inst:showTip(container)
        local index = container:getTag()
        local itemInfo = self.getItemInfoAndData_fn(index).info
        if itemInfo == nil then
            return
        end

        local stepLevel = EquipManager:getEquipStepById(itemInfo.itemId)

        GameUtil:showTip(
            container:getVarNode("FairContent_tipBtn"),
            {
                type = itemInfo.itemType,
                itemId = itemInfo.itemId,
                buyTip = true,
                starEquip = stepLevel == GameConfig.ShowStepStar
            }
        )
    end


    --购买单个道具
    function Inst:buy(container)
        local index = container:getTag()
        
        local itemInfoAndData = self.getItemInfoAndData_fn(index)
        if itemInfoAndData == nil then return end

        local itemInfo = itemInfoAndData.info
        local itemData = itemInfoAndData.data

        if itemInfo == nil then return end

        self.onBuy_fn(itemInfo, itemData)
    end

    --[[ 當 更新視圖 ]]
    function Inst:onRefreshItemView(container)
        local contentId = container:getItemDate().mID
        local beginIndex = (contentId - 1) * self.itemCount_perLine + 1
        local endIndex = contentId * self.itemCount_perLine

        for idx = beginIndex, endIndex, 1 do while true do
            local itemInfoAndData = self.getItemInfoAndData_fn(idx)
            if not itemInfoAndData then break end -- continue

            local itemInfo = itemInfoAndData.info
            local itemData = itemInfoAndData.data

            local tag = self.getItemInfoIndexById_fn(itemInfo.id)

            local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemInfo.itemType, itemInfo.itemId, itemInfo.count)

            -- 建立 單項商品
            local subContainer = ScriptContentBase:create(self.itemCCBI, tag)
            subContainer:registerFunctionHandler(self.onSubFunction)

            -- 設置 商品資料
            self:setShopItem(subContainer, itemInfo, itemData, resInfo, itemInfoAndData.shopType)

            -- print(string.format("%d %s %s", idx, tostring(itemInfo.id), resInfo.name))

            --add node
            local mainNodeName = "mPosition" .. tostring(idx - beginIndex + 1)
            local mainNode = container:getVarNode(mainNodeName)

            mainNode:removeAllChildren()
            mainNode:addChild(subContainer)
            subContainer:release()
        break end end
    end

    
    --[[ 當 每項(欄)物品 被呼叫 (接收UI呼叫) ]] 
    function Inst.onSubFunction(eventName, container)
        -- 顯示提示
        if eventName == "onTipBtn" then
            Inst:showTip(container)
        -- 購買
        elseif eventName == "onBuyBtn" then
            if container.canBuy then
                Inst:buy(container)
            end
        end
    end

    --[[ 設置 商品圖標 內容 ]]
    function Inst:setShopItem (itemContainer, shopItemInfo, itemData, resInfo, shopType)
            
        -- dump(itemData, "itemData")
        -- dump(shopItemInfo, "shopItemInfo")
        local totalCount = shopItemInfo.totalcount
        if totalCount == nil then totalCount = 0 end

        -- local leftCountText = string.format("Amount %s/%s", itemData.leftCount, totalCount)
        local leftCountText
        if itemData.levelRequire ~= nil then
            if UserInfo.roleInfo.level < itemData.levelRequire then
                leftCountText = common:getLanguageString("@Shop.Item.levelRequire", itemData.levelRequire)
            end
        end
        if leftCountText == nil then
            if totalCount > 0 --[[and shopType ~= 14 ]]then
                leftCountText = common:getLanguageString("@Shop.Item.leftAmount", itemData.leftCount, totalCount)
            else
                leftCountText = ""
            end
        end

        local discountText
        if shopItemInfo.discont == nil then
            discountText = nil
        elseif shopItemInfo.discont == 100 or shopItemInfo.discont == 0 then
            discountText = nil
        else
            -- discountText = string.format("%d%%", shopItemInfo.discont)
            discountText = common:getLanguageString("@Shop.Item.discount", shopItemInfo.discont)
        end

        local isLeftCountEnough = itemData.leftCount > 0 or totalCount == 0

        -- dump(shopItemInfo, "setShipItem shopItemInfo")
        -- dump(resInfo, "setShopItem resInfo")

        local price = tonumber(InfoAccesser:getItemInfoByStr(shopItemInfo.priceStr).count)
        local priceStr = (price == 0) and common:getLanguageString("@curFree") or GameUtil:formatDotNumber(price)
        --[[ 文字 ]]
        NodeHelper:setStringForLabel(itemContainer, {
            -- 名稱
            FairContent_nameText = tostring(resInfo.name),
            -- 數量
            mNumber = tostring(resInfo.count),
            -- 價格
            mCommodityNum = priceStr,
            -- 剩餘現貨
            FairContent_leftCountText = leftCountText,
            -- 折扣
            FairContent_discountText = discountText or "",
            -- VIP購買限制
            mLimitTxt = common:getLanguageString("@GrowthFundVIPBuyTxt", shopItemInfo.vip),
        })

        --[[ 圖片 ]]
        local imgScaleMap = {}

        local iconCfg = InfoAccesser:getItemIconCfg(resInfo.itemType, resInfo.itemId, "ShopItem")
        if iconCfg ~= nil then
            imgScaleMap.mPic = iconCfg.scale
        end

        local priceItemInfo = InfoAccesser:getItemInfoByStr(shopItemInfo.priceStr)
        local priceCfg = InfoAccesser:getItemIconCfg(priceItemInfo.type, priceItemInfo.id, "ShopPrice")
        if priceCfg ~= nil then
            imgScaleMap.mConsumptionType = priceCfg.scale
        end
        itemContainer.canBuy = (not shopItemInfo.vip) or (UserInfo.playerInfo.vipLevel >= shopItemInfo.vip)

        NodeHelper:setSpriteImage(itemContainer, {
            -- 背景
            mFrameShade = GameConfig.QualityImageBG[resInfo.quality],
            -- 物品框
            mFrame = GameConfig.QualityImageFrame[resInfo.quality],
            -- 圖標
            mPic = resInfo.icon,
            -- 貨幣
            mConsumptionType = priceItemInfo.icon,
        }, imgScaleMap)

        --[[ 顯示 ]]
        NodeHelper:setNodesVisible(itemContainer, {
            -- 商品中 物品數量
            FairContent_itemCountText = shopItemInfo.count,
            -- 折扣
            FairContent_discountImg = (discountText ~= nil and itemContainer.canBuy),
            FairContent_discountText = (discountText ~= nil and itemContainer.canBuy),
            -- 售完
            FairContent_soldout = not isLeftCountEnough,
            -- 剩餘現貨
            FairContent_leftCountText = totalCount > 0,
            -- 價格
            mCommodityNum = true, --itemContainer.canBuy,
            -- 購買限制遮罩
            mLimitMask = not itemContainer.canBuy,
            -- 星數
            mStarNode = (resInfo.mainType == Const_pb.EQUIP or resInfo.mainType == Const_pb.BADGE),
        })
        if (resInfo.mainType == Const_pb.EQUIP or resInfo.mainType == Const_pb.BADGE) then
            for i = 1, 6 do
                NodeHelper:setNodesVisible(itemContainer, { ["mStar" .. i] = (i == resInfo.star) })
            end
        end
    end

    return Inst
end

return ItemLineContent