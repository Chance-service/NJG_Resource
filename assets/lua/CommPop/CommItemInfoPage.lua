--[[ 
    name: CommItemInfoPage
    desc: 使用物品彈出式視窗
    author: youzi
    update: 2023/9/7 16:35
    description:
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件

local UserItemManager = require("Item.UserItemManager");
local ItemManager = require("Item.ItemManager");

local Async = require("Util.Async")
local NodeHelper = require("NodeHelper")

local CommItem = require("CommUnit.CommItem")
local CommItemInfoConst = require("CommPop.CommItemInfoConst")

local PAGE_NAME = "CommPop.CommItemInfoPage"

local OPCODES = {
    ITEM_USE_S = HP_pb.ITEM_USE_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
}

local option = {
    ccbiFile = "CommonItemInfoPage.ccbi",
    handlerMap = {
        
        -- 數量選擇
        onAmountBtn_add = "onAmountBtnClick_add",
        onAmountBtn_sub = "onAmountBtnClick_sub",
        onAmountBtn_min = "onAmountBtnClick_min",
        onAmountBtn_max = "onAmountBtnClick_max",

        -- 按鈕
        onOneBtn = "onOneBtnClick",
        onTwoBtn_1 = "onTwoBtnClick_1",
        onTwoBtn_2 = "onTwoBtnClick_2",

        -- 點擊 離開
        onClose = "close",
    },
    opcode = OPCODES
}

-- 物品 名稱 寬度
local ITEM_NAME_WIDTH = 427
-- 物品 敘述 寬度
local ITEM_DESC_WIDTH = 427

--[[ 本體 ]]
local CommItemInfoPage = {}
function CommItemInfoPage:new ()

    local inst = {}

    --[[ 容器 ]]
    inst.container = nil

    --[[ 標題 ]]
    inst.title = nil

    --[[ 物品資訊 ]]
    inst.itemInfo = nil

    --[[ 通用物品 ]]
    inst.commItemUI = nil

    --[[ 顯示中的UI ]]
    inst.visibleUIs = {}

    --[[ 可點擊按鈕設置 ]]
    inst.enableBtns = {}

    --[[ 當 物品 執行動作 行為 ]]
    inst.onItemAction_fn = nil

    --[[ 當 關閉 行為 ]]
    inst.onceClose_fn = nil

    --[[ 是否動畫入場 ]]
    inst.isAnimOnShow = true

    --[[ 當動畫入場完成 ]]
    inst.onAnimOpenDoneTask = nil

    --[[ 是否已經顯示 ]]
    inst.isShow = false

    --[[ 其他呼叫行為 ]]
    inst.functions = {}

    --[[ 輸入資料 ]]
    inst.inputData = {}

    --[[ var 對應的 HTMLLabel ]]
    inst._var2htmlLabel = {}

    --[[ 配置類型 ]]
    inst.infoType = nil

    -- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
    --  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
    --  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
    --  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
    --  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
    --  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
    -- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 

    --[[ 當 收到訊息 ]]
    function inst:onReceiveMessage(container)
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
    function inst:onReceivePacket(container)
        local opcode = container:getRecPacketOpcode()
        local msgBuff = container:getRecPacketBuffer()

        -- 是否 為 物品使用回傳
        local isItemUse = opcode == OPCODES.ITEM_USE_S
        -- 是否 為 獲獎回傳
        local isItemAward = opcode == OPCODES.PLAYER_AWARD_S

        -- 若 為 其一 則
        if isItemUse or isItemAward then
            
            -- 若 物品已全消耗
            if UserItemManager:getCountByItemId(self.itemInfo.itemId) <= 0 then
                -- 關閉視窗
                self:close()
            -- 否則
            else
                -- 更新 物品資訊
                self:updateItemInfo()
                -- 設置 物品
                self:setItem(self.itemInfo)
                -- 設置 顯示UI
                self:setUIVisible(self.visibleUIs)
                self:setBtnEnable(self.enableBtns)
            end

            -- 若 為 物品使用回傳
            if isItemUse then
                -- 呼叫 當收到物品使用回傳
                local itemType = ItemManager:getTypeById(self.itemInfo.itemId)
                self:_receiveItemUse(itemType)
            end
            
            -- 若 有設置 當物品動作行為 則 呼叫
            if self.onItemAction_fn ~= nil then
                self.onItemAction_fn()
            end

            if isItemUse and self.infoType == CommItemInfoConst.Preset.COMPOUND then
                -- 專武合成後自動關閉視窗
                self:close()
            end
            if isItemUse and self.infoType == CommItemInfoConst.Preset.OPEN_AMOUNT then
                --自選後自動關閉視窗
                self:close()
            end
        end
    end
    
    --[[ 註冊 封包相關 ]]
    function inst:registerPacket(container)
        for key, opcode in pairs(OPCODES) do
            if string.sub(key, -1) == "S" then
                container:registerPacket(opcode)
            end
        end
    end
    --[[ 註銷 封包相關 ]]
    function inst:removePacket(container)
        for key, opcode in pairs(OPCODES) do
            if string.sub(key, -1) == "S" then
                container:removePacket(opcode);
            end
        end
    end

    --[[ 當 頁面 進入 ]]
    function inst:onEnter (container)
        self.container = container

        -- print("CommItemInfoPage.onEnter")
        
        -- 註冊 封包相關
        self:registerPacket(self.container)

        -- 文字
        self:setTexts(self.texts)

        -- 控制類型
        self:setUIVisible(self.visibleUIs)
        self:setBtnEnable(self.enableBtns)

        -- 物品
        self:setItem(self.itemInfo)

        -- 顯示視窗
        self:show()
    end

    --[[ 當 頁面 離開 ]]
    function inst:onExit(container)
        self:removePacket(container)
        
        self.isAnimOnShow = true
        self.onAnimOpenDoneTask = nil
        self.isShow = false
        
        self.onceClose_fn = nil
        self.onItemAction_fn = nil
        
        self.userItemID = nil
        self.itemInfo = nil
        
        self.commItemUI = nil
        self.infoType = nil
        
        self.visibleUIs = {}
        self.enableBtns = {}

        self.functions = {}

        self.inputData = {}

        self._var2htmlLabel = {}

        onUnload(PAGE_NAME, container)
    end

    --[[ 當動畫播放完畢 ]]
    function inst:onAnimationDone(container, eventName)
        if self.onAnimOpenDoneTask ~= nil then
            self.onAnimOpenDoneTask:next(1)
        end
        -- 新手教學
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["CommItemInfoPage"] = container
        if GuideManager.isInGuide then
            PageManager.pushPage("NewbieGuideForcedPage")
        end
    end

    --[[ 其他呼叫行為 ]]
    
    -- 批量建立 對此頁面的某func呼叫 轉呼叫至 此頁面的functions底下的func

    local _fns = {
        "onOneBtnClick", "onTwoBtnClick_1", "onTwoBtnClick_2",
        "onAmountBtnClick_sub", "onAmountBtnClick_add",
        "onAmountBtnClick_min", "onAmountBtnClick_max",
    }

    for idx, fnName in ipairs(_fns) do
        inst[fnName] = function (slf, container)
            local fn = slf.functions[fnName]
            if fn ~= nil then fn(slf) end
        end
    end

    -- function inst:onOneBtnClick (container)
    --     local fn = self.functions["onOneBtnClick"]
    --     if fn ~= nil then fn(self) end
    -- end
    -- function inst:onTwoBtnClick_1 (container)
    --     local fn = self.functions["onTwoBtnClick_1"]
    --     if fn ~= nil then fn(self) end
    -- end
    -- function inst:onTwoBtnClick_2 (container)
    --     local fn = self.functions["onTwoBtnClick_2"]
    --     if fn ~= nil then fn(self) end
    -- end
    

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 關閉 ]]
    function inst:close()

        -- 關閉 頁面
        PageManager.popPage(PAGE_NAME)
    
        -- 若 有關閉行為 則 呼叫
        if self.onceClose_fn then
            self.onceClose_fn()
            self.onceClose_fn = nil
        end
    end

    --[[ 顯示 ]]
    function inst:show(isAnim)
        -- 是否動畫中 為 動畫開啟完成任務是否存在
        local isAniming = self.onAnimOpenDoneTask ~= nil
        
        -- 若 顯示中 且 非動畫中 則 返回
        if self.isShow and not isAniming then return end
        
        -- 若 沒有指定 是否要以動畫顯示 則 取用預設
        if isAnim == nil then
            isAnim = self.isAnimOnShow 
        end

        -- 若 要以動畫顯示 且 顯示中 且 動畫中 則 返回
        if isAnim and self.isShow and isAniming then return end

        local slf = self

        -- 若要以動畫顯示
        if isAnim then
            -- 建立當動畫開啟完畢任務
            self.onAnimOpenDoneTask = Async:passtive({1}, function()
                -- 呼叫當顯示
                slf:_onShow()
            end)
            -- 播放 開啟動畫
            self.container:runAnimation("Open")
        else
            -- 直接呼叫當顯示
            slf:_onShow()
        end
    end


    --[[ 準備 ]]
    -- 此處不能對UI進行直接設置, 因為頁面可能尚未建立.
    -- 應事先準備, 直到頁面建立後取用相關資訊.
    function inst:prepare(options)

        -- 玩家持有物品ID
        local userItemID = options["userItemID"]
        if userItemID ~= nil then
            self.userItemID = userItemID
            -- 以此更新 當前物品資訊
            self:updateItemInfo()
        end

        -- 若 有指定 物品資訊
        local itemInfo = options["itemInfo"]
        if itemInfo ~= nil then
            self.itemInfo = itemInfo
        end

        -- 若 有指定 預先配置
        local preset = options["preset"]
        if preset ~= nil then
            -- 若 為 依照物品類型自動設定 且 物品資訊 存在 則
            if preset == CommItemInfoConst.Preset.AUTO_ITEMTYPE and self.itemInfo ~= nil then
                -- 取得 對應的 預先配置
                local itemType = ItemManager:getTypeById(self.itemInfo.itemId)
                preset = CommItemInfoConst:getPresetByItemType(itemType)
            end
            -- 取得 該預先配置 的 設定
            local presetOptions = CommItemInfoConst:getPresetSetting(preset)
            if presetOptions ~= nil then
                -- 覆寫 options
                for key, val in pairs(presetOptions) do
                    if options[key] == nil then
                        options[key] = val
                    end
                end
            end
            self.infoType = preset
        end

        -- 顯示的UI
        local visibleUIs = options["visibles"]
        if visibleUIs ~= nil then
            self.visibleUIs = visibleUIs
        end
        local enableBtns = options["enableBtns"]
        if enableBtns ~= nil then
            self.enableBtns = enableBtns
        end
        
        -- 文字設置
        local texts = options["texts"]
        if texts ~= nil then
            self.texts = texts
        end

        -- 當關閉行為
        local onceClose_fn = options["onceClose_fn"]
        if onceClose_fn ~= nil then
            self.onceClose_fn = onceClose_fn
        end

        -- 當物品動作行為
        local onItemAction_fn = options["onItemAction_fn"]
        if onItemAction_fn ~= nil then
            self.onItemAction_fn = onItemAction_fn
        end

        -- 其他呼叫行為
        local functions = options["functions"]
        if functions ~= nil then
            self.functions = functions
        end

    end

    --[[ 設置 文字 ]]
    function inst:setTexts(texts)
        self.texts = texts
        local translated = {}
        for key, val in pairs(self.texts) do
            translated[key] = common:getLanguageString(val)
        end
        NodeHelper:setStringForLabel(self.container, translated)
    end

    --[[ 設置 UI顯示 ]]
    function inst:setUIVisible(visibleMap)
        self.visibleUIs = visibleMap

        local totalVisibles = {}
        for key, val in pairs(CommItemInfoConst.DefaultUIVisible) do
            totalVisibles[key] = val
        end
        for key, val in pairs(self.visibleUIs) do
            totalVisibles[key] = val
        end

        -- 每個既存的htmlLabel
        for key, htmlLabel in pairs(self._var2htmlLabel) do
            -- 若 有指定 是否顯示
            local toVisible = totalVisibles[key]
            if toVisible ~= nil then
                -- 關閉原本UI顯示
                totalVisibles[key] = false
                -- 設置HTMLLabel顯示
                htmlLabel:setVisible(toVisible)
            end
        end
        
        NodeHelper:setNodesVisible(self.container, totalVisibles)
    end
    function inst:setBtnEnable(enableBtns)
        self.enableBtns = enableBtns

        for key, val in pairs(self.enableBtns) do
            NodeHelper:setMenuItemEnabled(self.container, key, val(self.itemInfo.itemId))
        end
    end

    --[[ 設置 預先配置 ]]
    function inst:setPreset(preset)
        local presetSetting = CommItemInfoConst.PresetSetting[preset]
        if presetSetting == nil then return end
        --特規處理
        if preset == CommItemInfoConst.Preset.AFK_Treasure then
            local Page = require "CommPop.AFKTreasureBoxPage"
            Page:setData(self)
            PageManager.pushPage("CommPop.AFKTreasureBoxPage")
            return
        end
        if presetSetting.visibles ~= nil then 
            self:setUIVisible(presetSetting.visibles)
        end

        if presetSetting.texts ~= nil then
            self:setTexts(presetSetting.texts)
        end

        if presetSetting.functions ~= nil then
            self.functions = presetSetting.functions
        end
    end

    --[[ 更新物品 ]]
    function inst:updateItemInfo ()
        local userItem = UserItemManager:getUserItemById(self.userItemID)

        if userItem == nil then return end
        
        local itemInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, userItem.itemId, 1)

        self.itemInfo = {}
        for key, val in pairs(itemInfo) do 
            self.itemInfo[key] = val
        end
        self.itemInfo.count = userItem.count
    end

    --[[ 設置 物品 ]]
    function inst:setItem (itemInfo)
        
        -- 通用物品圖示
        if self.commItemUI == nil then
            self.commItemUI = CommItem:new()
            local itemContainer = self.commItemUI:requestUI()
            itemContainer:setScale(CommItem.Scales.small)
            itemContainer:setAnchorPoint(ccp(0.5, 0.5))
    
            local parent = self.container:getVarNode("itemIconNode")
            parent:removeAllChildren()
            parent:addChild(itemContainer)
        end

        self.commItemUI:autoSetByItemInfo(self.itemInfo)

        local node2Text = {}

        -- 名稱
        node2Text["itemNameTxt"] = common:getLanguageString(self.itemInfo.name)

        -- 敘述 
        local itemDesc = common:getLanguageString(self.itemInfo.describe)
        itemDesc = "<font color=\"#625141\" face = \"Barlow-SemiBold20\" >" .. itemDesc .. "</font>"
        if self.itemInfo.describe2 then
            if self.itemInfo.describe2 ~= "" then
                local strTb = { }
                local str = itemDesc
                table.insert(strTb, str)
                table.insert(strTb, common:fillHtmlStr('ItemProduce', self.itemInfo.describe2))
                itemDesc = table.concat(strTb, '<br/>')
            end
        end
        node2Text["itemDescTxt"] = itemDesc

        node2Text["amountTotalNum"] = self.itemInfo.count

        -- 設置
        NodeHelper:setStringForLabel(self.container, node2Text)

        -- HTML
        local nameSize = self:_replaceSizeWidth(self.container:getVarNode("itemNameTxt"):getContentSize(), ITEM_NAME_WIDTH)
        local descSize = self:_replaceSizeWidth(self.container:getVarNode("itemDescTxt"):getContentSize(), ITEM_DESC_WIDTH)
        
        
        local nameLabel = self._var2htmlLabel["itemNameTxt"]
        if nameLabel ~= nil then
            nameLabel:getParent():removeChild(nameLabel, true)
        end
        nameLabel = NodeHelper:setCCHTMLLabel(self.container, "itemNameTxt", nameSize, node2Text["itemNameTxt"], true)
        nameLabel:setTag(-1) -- 避免後續 NodeHelper:setCCHTMLLabel 把 特定tag的既有HtmlLabel 移除
        self._var2htmlLabel["itemNameTxt"] = nameLabel
        
        local descLabel = self._var2htmlLabel["itemDescTxt"]
        if descLabel ~= nil then
            descLabel:getParent():removeChild(descLabel, true)
        end
        descLabel = NodeHelper:setCCHTMLLabel(self.container, "itemDescTxt", descSize, node2Text["itemDescTxt"], true)
        descLabel:setTag(-1) -- 避免後續 NodeHelper:setCCHTMLLabel 把 特定tag的既有HtmlLabel 移除
        self._var2htmlLabel["itemDescTxt"] = descLabel
    end

    
    --[[ 使用道具 ]]
    function inst:useItem (preferCount)
        local itemID = self.itemInfo.itemId 
        local itemType = ItemManager:getTypeById(itemID)

        -- 取得 該物品類型 所屬行為
        local behaviour = CommItemInfoConst:getItemTypeBehaviour(itemType)
        if behaviour ~= nil then
            -- 若 有指定 使用物品行為 則 採用該行為
            if behaviour.useItem ~= nil then
                behaviour.useItem(itemID, preferCount)
                return
            end
        end
        --if itemType == Const_pb.SUIT_FRAGMENT then
        --    local InfoAccesser = require("Util.InfoAccesser")
        --    if InfoAccesser:getExistAncientWeaponByPieceId(itemID) then
        --        MessageBoxPage:Msg_Box_Lan("@Synthesized")
        --        return
        --    end
        --end
        -- 否則 採用 預設使用物品行為
        CommItemInfoConst:commUseItem(itemID, preferCount)
    end

    --[[ 設置 數量選擇 ]]
    function inst:setAmount (amount) 
        NodeHelper:setStringForLabel(self.container, {
            ["amountNum"] = tostring(amount)
        })
        self.inputData["amount"] = tonumber(amount)
    end

    -- ########  ########  #### ##     ##    ###    ######## ######## 
    -- ##     ## ##     ##  ##  ##     ##   ## ##      ##    ##       
    -- ##     ## ##     ##  ##  ##     ##  ##   ##     ##    ##       
    -- ########  ########   ##  ##     ## ##     ##    ##    ######   
    -- ##        ##   ##    ##   ##   ##  #########    ##    ##       
    -- ##        ##    ##   ##    ## ##   ##     ##    ##    ##       
    -- ##        ##     ## ####    ###    ##     ##    ##    ######## 

    --[[ 當 頁面顯示 ]]
    function inst:_onShow()
        self.isShow = true
        
        self.onAnimOpenDoneTask = nil

        self.container:runAnimation("Default Timeline")
    end

    --[[ 覆蓋 寬度 ]]
    function inst:_replaceSizeWidth (size, maxWidth)
        return CCSizeMake(maxWidth, size.height)
    end

    --[[ 當 接收 物品使用回傳 ]]
    function inst:_receiveItemUse (itemType, msgBuff)
        -- 若 有 該物品類型 所屬行為
        local behaviour = CommItemInfoConst:getItemTypeBehaviour(itemType)
        if behaviour == nil then return end

        if behaviour.receiveItemUse ~= nil then
            behaviour.receiveItemUse(msgBuff, itemID)
        end
    end

    --  #######  ######## ##     ## ######## ########  
    -- ##     ##    ##    ##     ## ##       ##     ## 
    -- ##     ##    ##    ##     ## ##       ##     ## 
    -- ##     ##    ##    ######### ######   ########  
    -- ##     ##    ##    ##     ## ##       ##   ##   
    -- ##     ##    ##    ##     ## ##       ##    ##  
    --  #######     ##    ##     ## ######## ##     ## 
    

    return inst
end

local CommonPage = require('CommonPage')
return CommonPage.newSub(CommItemInfoPage:new(), PAGE_NAME, option)