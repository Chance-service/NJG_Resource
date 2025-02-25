local ItemOprHelper = require("Item.ItemOprHelper");
local UserItemManager = require("Item.UserItemManager")
local ItemManager = require("Item.ItemManager");
local CommItemInfoConst = {}

-- ########  ######## ######## #### ##    ## ######## 
-- ##     ## ##       ##        ##  ###   ## ##       
-- ##     ## ##       ##        ##  ####  ## ##       
-- ##     ## ######   ######    ##  ## ## ## ######   
-- ##     ## ##       ##        ##  ##  #### ##       
-- ##     ## ##       ##        ##  ##   ### ##       
-- ########  ######## ##       #### ##    ## ######## 

--[[ 預先配置 ]]
CommItemInfoConst.Preset = {
    -- 自動選擇 依照 物品類型
    AUTO_ITEMTYPE = -1,

    -- 無效
    NONE = 0,

    -- 單選
    CLOSE = 1,
    USE = 2,
    COMPOUND = 3,

    -- 雙選
    OPEN10 = 11,
    
    
    -- 數量 + 單選
    
    OPEN_AMOUNT = 21,
    OPEN_AMOUNT_STEP2 = 22,

    SELL = 31,
    SELL_STEP2 = 32,
    --AFK寶箱
    AFK_Treasure = 33
}

--[[ 預設 UI顯示 ]]
CommItemInfoConst.DefaultUIVisible = {
    itemIconNode = true,
    itemNameTxt = true,
    itemDescTxt = false,
    itemAmountNode = false,
    oneBtnNode = false,
    twoBtnNode = false,
}

--  ######   ######## ##    ## ######## ########     ###    ######## ######## 
-- ##    ##  ##       ###   ## ##       ##     ##   ## ##      ##    ##       
-- ##        ##       ####  ## ##       ##     ##  ##   ##     ##    ##       
-- ##   #### ######   ## ## ## ######   ########  ##     ##    ##    ######   
-- ##    ##  ##       ##  #### ##       ##   ##   #########    ##    ##       
-- ##    ##  ##       ##   ### ##       ##    ##  ##     ##    ##    ##       
--  ######   ######## ##    ## ######## ##     ## ##     ##    ##    ######## 


function CommItemInfoConst:_mergeFuncs(funcs_exist, funcs_append)
    local funcs = {}
    for key, val in pairs(funcs_exist) do
        funcs[key] = val
    end
    for key, val in pairs(funcs_append) do
        funcs[key] = val
    end
    return funcs
end

function CommItemInfoConst:_generateItemAmountAndConfirmFuncs(options)
    options = options or {}

    local add = options["add"] or 1
    local sub = options["sub"] or 1
    local addMore = options["addMore"] or 10
    local subMore = options["subMore"] or 10
    local min = options["min"] or 1
    local max = options["max"] or 100 -- 超過 Server 定的 100 個可能會被 ban
    local onConfirm_fn = options["onConfirm_fn"] or function(page, amount) end

    local MaxUse = 30 -- 最大使用上限常量

    local function calculateMaxAmount(item, itemType)
        local maxAmount = math.min(item.count, max)
        if itemType == 12 then
            maxAmount = math.min(maxAmount, MaxUse)
        end
        return maxAmount
    end

    return {
        -- 確認按鈕點擊事件
        onOneBtnClick = function(page)
            local amount = page.inputData["amount"]
            onConfirm_fn(page, amount)
        end,

        -- 減少按鈕點擊事件
        onAmountBtnClick_sub = function(page)
            local amount = page.inputData["amount"] - sub
            page:setAmount(math.max(amount, min)) -- 確保不低於最小值
        end,

        -- 增加按鈕點擊事件
        onAmountBtnClick_add = function(page)
            local amount = page.inputData["amount"] + add
            local item = UserItemManager:getUserItemByItemId(page.itemInfo.itemId)
            if not item then return end

            local itemType = ItemManager:getTypeById(page.itemInfo.itemId)
            local maxAmount = calculateMaxAmount(item, itemType)

            page:setAmount(math.min(amount, maxAmount)) -- 設置最終數量
        end,

        -- 最小值按鈕點擊事件
        onAmountBtnClick_min = function(page)
            local item = UserItemManager:getUserItemByItemId(page.itemInfo.itemId)
            if not item then return end

            local amount = page.inputData["amount"] - math.ceil(page.inputData["amount"] / 2)
            page:setAmount(math.max(amount, min)) -- 確保不低於最小值
        end,

        -- 最大值按鈕點擊事件
        onAmountBtnClick_max = function(page)
            local item = UserItemManager:getUserItemByItemId(page.itemInfo.itemId)
            if not item then return end

            local itemType = ItemManager:getTypeById(page.itemInfo.itemId)
            local amount = page.inputData["amount"] + math.ceil(max / 2)

            if itemType == 12 and item.count >= MaxUse then
                amount = MaxUse
            end

            page:setAmount(math.min(amount, item.count, max)) -- 設置最終數量
        end,
    }
end




-- ########    ###    ########  ##       ######## 
--    ##      ## ##   ##     ## ##       ##       
--    ##     ##   ##  ##     ## ##       ##       
--    ##    ##     ## ########  ##       ######   
--    ##    ######### ##     ## ##       ##       
--    ##    ##     ## ##     ## ##       ##       
--    ##    ##     ## ########  ######## ######## 


--[[ 預先配置 設定 ]]
CommItemInfoConst.PresetSetting = {

    -- 單選 -----------

    -- 關閉
    [CommItemInfoConst.Preset.CLOSE] = {
        itemTypes = {0, 6, 35, 100},

        visibles = {
            itemDescTxt = true,
            oneBtnNode = true, 
        },
        texts = {
            titleTxt = "@GuideBTN",
            -- oneBtnTxt = "@Close",
            oneBtnTxt = "@Cancel",
        },
        functions = {
            onOneBtnClick = function (page)
                page:close()
            end
        },
    },
    -- 使用
    [CommItemInfoConst.Preset.USE] = {
        itemTypes = {7},

        visibles = {
            itemDescTxt = true,
            oneBtnNode = true, 
        },
        texts = {
            titleTxt = "@GuideBTN",
            oneBtnTxt = "@Use",
        },
        functions = {
            onOneBtnClick = function (page)
                page:useItem(1)
            end
        },
    },
    -- 合成
    [CommItemInfoConst.Preset.COMPOUND] = {
        itemTypes = {19},

        visibles = {
            itemDescTxt = true,
            oneBtnNode = true, 
        },
        texts = {
            titleTxt = "@GuideBTN",
            oneBtnTxt = "@Compound",
        },
        functions = {
            onOneBtnClick = function (page)
                require("Util.LockManager")
                if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.ANCIENT_WEAPON) then
                    MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.ANCIENT_WEAPON))
                    return
                end
                page:useItem(1)
            end
        },
        enableBtns = {
            oneBtn = function(itemId)
                if not itemId then
                    return true
                end
                local InfoAccesser = require("Util.InfoAccesser")
                if InfoAccesser:getExistAncientWeaponByPieceId(itemId) then
                    return false
                end
                return true
            end
        },
    },

    -- 雙選 -----------
    
    -- 開啟 1或10
    [CommItemInfoConst.Preset.OPEN10] = {
        itemTypes = {},

        visibles = {
            itemDescTxt = true,
            twoBtnNode = true,
        },
        texts = {
            titleTxt = "@GuideBTN",
            twoBtnTxt_1 = "@CommItemInfoPage.open10.open1",
            twoBtnTxt_2 = "@CommItemInfoPage.open10.open10",
        },
        functions = {
            onTwoBtnClick_1 = function (page)
                page:useItem(1)
            end,
            onTwoBtnClick_2 = function (page)
                page:useItem(10)
            end,
        },
    },
    -- 開啟 選數量
    [CommItemInfoConst.Preset.OPEN_AMOUNT] = {
        itemTypes = {11, 12, 14, 20, 28, 38, 39, 40, 41},

        visibles = {
            itemDescTxt = true,
            oneBtnNode = true, 
        },
        texts = {
            titleTxt = "@Mid-autumnPropChoiceTitle",
            oneBtnTxt = "@Use",
            -- oneBtnTxt = "@CommItemInfoPage.openAmount.btn1",
        },
        functions = {
            onOneBtnClick = function (page)
                local itemType = page.itemInfo.type
                if itemType == 39 or itemType == 40 or itemType == 41 then
                    page:setPreset(CommItemInfoConst.Preset.AFK_Treasure)
                    page:setAmount(1)
                else
                    page:setPreset(CommItemInfoConst.Preset.OPEN_AMOUNT_STEP2)
                    page:setAmount(1)
                end
            end
        },
    },
    [CommItemInfoConst.Preset.OPEN_AMOUNT_STEP2] = {
        itemTypes = {},

        visibles = {
            itemAmountNode = true,
            oneBtnNode = true, 
        },
        texts = {
            titleTxt = "@Mid-autumnPropChoiceTitle",
            oneBtnTxt = "@Use",
        },
        functions = CommItemInfoConst:_mergeFuncs(
            CommItemInfoConst:_generateItemAmountAndConfirmFuncs({
                onConfirm_fn = function(page, amount)
                    page:useItem(amount)
                end
            }),
            {}
        ),
    },
        [CommItemInfoConst.Preset.AFK_Treasure] = {
        itemTypes = {},

        visibles = {
            itemAmountNode = true,
            oneBtnNode = true, 
        },
        texts = {
            titleTxt = "@Mid-autumnPropChoiceTitle",
            oneBtnTxt = "@Use",
        },
        functions = CommItemInfoConst:_mergeFuncs(
            CommItemInfoConst:_generateItemAmountAndConfirmFuncs({
                onConfirm_fn = function(page, amount)
                    page:useItem(amount)
                end
            }),
            {}
        ),
    },
    
    -- 數量 + 單選 ----------

    -- 販售
    [CommItemInfoConst.Preset.SELL] = {
        itemTypes = {100},

        visibles = {
            itemDescTxt = true,
            oneBtnNode = true, 
        },
        texts = {
            titleTxt = "",
            oneBtnTxt = "@Sell",
        },
        functions = {
            onOneBtnClick = function (page)
                page:setPreset(CommItemInfoConst.Preset.SELL_STEP2)
                page:setAmount(1)
            end
        },
    },
    [CommItemInfoConst.Preset.SELL_STEP2] = {
        itemTypes = {},

        visibles = {
            itemAmountNode = true,
            oneBtnNode = true, 
        },
        texts = {
            titleTxt = "",
            oneBtnTxt = "@Confirm",
        },
        functions = CommItemInfoConst:_mergeFuncs(
            CommItemInfoConst:_generateItemAmountAndConfirmFuncs({
                onConfirm_fn = function(page, amount)
                    ItemOprHelper:sellItem(page.itemInfo.itemId, amount)
                end
            }),
            {}
        ),
    },
}


--[[ 物品類型 與 行為 ]]
CommItemInfoConst.ItemTypeBehaviour = {
    [Const_pb.TIME_LIMIT_PURCHASE] = {
        receiveItemUse = function(msgBuff)
            local msg = ItemOpr_pb.HPItemUseRet();
            msg:ParseFromString(msgBuff);
            if msg ~= nil then
            else
            end
        end
    },
}

-- ########  #######   #######  ##       
--    ##    ##     ## ##     ## ##       
--    ##    ##     ## ##     ## ##       
--    ##    ##     ## ##     ## ##       
--    ##    ##     ## ##     ## ##       
--    ##    ##     ## ##     ## ##       
--    ##     #######   #######  ######## 

--[[ 取得 物品類型行為 ]]
function CommItemInfoConst:getItemTypeBehaviour (itemType)
    return self.ItemTypeBehaviour[itemType]
end

--[[ 通用使用物品 ]]
function CommItemInfoConst:commUseItem (itemID, count)

    -- XXX 使用超過數量的物品可能會導致 帳號跟IP 被 Ban黑名單

    -- 若 可以檢查 則 檢查數量並調整使用數量
    local item = UserItemManager:getUserItemByItemId(itemID)
    if item ~= nil and item.count < count then
        count = item.count
    end

    -- 保險
    if count > 100 then count = 100 end

    ItemOprHelper:useItem(itemID, count)
end

--[[ 取得 預先設置 (以物品類型) ]]
function CommItemInfoConst:getPresetByItemType (typ)
    for key, val in pairs(self.PresetSetting) do
        for idx = 1, #val.itemTypes do
            if val.itemTypes[idx] == typ then
                return key
            end
        end
    end
    return self.Preset.NONE
end

--[[ 取得 預先設置 設定 ]]
function CommItemInfoConst:getPresetSetting (preset)
    return self.PresetSetting[preset]
end


return CommItemInfoConst