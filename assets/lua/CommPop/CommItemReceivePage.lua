
--[[ 
    name: CommItemReceivePage
    desc: 獲得物品彈出式視窗
    author: youzi
    update: 2023/8/31 11:45
    description: 從 CommonRewardPage.lua 改製.
      呼叫方式範例:
        if opcode == HP_pb.PLAYER_AWARD_S then
            -- 取得 封包
            local msg = Reward_pb.HPPlayerReward()
            msg:ParseFromString(msgBuff)
            -- 請求頁面
            local itemReceivePage = require("CommPop.CommItemReceivePage")
            -- 準備頁面
            itemReceivePage:prepare({
                title = common:getLanguageString("XXXXXXXXX"),
                itemInfos = {xxxx, xxxxx ...},
                onceClose_fn = function()
                   print("AAAAAAAAA") 
                end,
            })
            -- 推送顯示
            PageManager.pushPage("CommPop.CommItemReceivePage")
        end
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件

local Async = require("Util.Async")
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")

local ResManager = require "ResManagerForLua"
local ItemManager = require("Item.ItemManager")
local InfoAccesser = require("Util.InfoAccesser")

local CommItem = require("CommUnit.CommItem")

local thisPageName = "CommPop.CommItemReceivePage"

--[[ Flag對應標題 ]]
local flag2Title = {
    "@RewardItem2",
}

--[[ 取得標題 ]]
local function getTitle (flag)
    local title = flag2Title[flag]
    
    if title == nil then
        -- print("ItemReceivePage missing title with flag : "..tostring(flag))
        return ""
    end

    return common:getLanguageString(title)
end

----这里是协议的id
local opcodes = {

}

local option = {
    ccbiFile = "CommonRewardPopUp.ccbi",
    handlerMap =
    {
        -- 點擊 跳過
        onSkip = "onSkipClick",
        -- 點擊 離開
        onExit = "onExitClick",
        -- 當動畫播放完畢
        onAnimationDone = "onAnimationDone",
    },
    opcode = opcodes
}

local CommItemReceivePage = {}
function CommItemReceivePage:new ()

    local inst = {}

    --[[ 容器 ]]
    inst.container = nil

    --[[ 標題 ]]
    inst.title = nil

    --[[ 物品列表 ]]
    inst.itemList = {} -- 奖励物品 必须是读配置这种格式10000_1001_50 读出来的数组

    --[[ 當 關閉 行為 ]]
    inst.onceClose_fn = nil

    --[[ 當 顯示 行為 ]]
    inst.onceShow_fn = nil

    --[[ 當 跳過 行為 ]]
    inst.onceSkip_fn = nil

    --[[ 是否動畫入場 ]]
    inst.isAnimOnShow = true

    --[[ 當動畫入場完成 ]]
    inst.onAnimOpenDoneTask = nil

    --[[ 是否手動顯示 ]]
    inst.isShowManual = false

    --[[ 是否已經顯示 ]]
    inst.isShow = false

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

        -- if opcode == HP_pb.XXXXXXXX then
        --     local msg = XXXXXXXXXX
        --     msg:ParseFromString(msgBuff)
        
        --     return
        -- end
    end
    
    --[[ 註冊 封包相關 ]]
    function inst:registerPacket(container)
        for key, opcode in pairs(opcodes) do
            if string.sub(key, -1) == "S" then
                container:registerPacket(opcode)
            end
        end
    end
    --[[ 註銷 封包相關 ]]
    function inst:removePacket(container)
        for key, opcode in pairs(opcodes) do
            if string.sub(key, -1) == "S" then
                container:removePacket(opcode);
            end
        end
    end

    --[[ 當 頁面 進入 ]]
    function inst:onEnter (container)
        self.container = container

        -- print("CommItemReceivePage.onEnter")
        
        -- 註冊 封包相關
        self:registerPacket(container)

        -- 初始化 獲得列表
        NodeHelper:initScrollView(container, "mContent", #self.itemList);

        -- 顯示
        NodeHelper:setNodesVisible(container, { mActivityTxt = true })

        local node2String = {}
        if self.title ~= nil then
            node2String.mActivityTxt = common:getLanguageString(self.title)
        end
        NodeHelper:setStringForLabel(container, node2String)


        -- 刷新物品顯示
        self:updateItems()

        -- 若 為 手動顯示
        if self.isShowManual then
            -- 先 關閉 顯示節點 / 開啟 跳過節點
            self.container:getVarNode("showNode"):setVisible(false)
            self.container:getVarNode("skipNode"):setVisible(true)
        -- 若 為 自動顯示 則 顯示
        else
            self:show()
        end

        -- 增加特效
        local effectParent = self.container:getVarNode("mEffectNode")
        effectParent:removeAllChildrenWithCleanup(true)
        local effect = SpineContainer:create("Spine/NGUI", "NGUI_01_GetItem")
        local effectNode = tolua.cast(effect, "CCNode")
        effectParent:addChild(effectNode)
        effect:setToSetupPose()
        effect:runAnimation(1, "animation", 0)
    end

    --[[ 當 頁面 離開 ]]
    function inst:onExit(container)
        self:removePacket(container)

        self.onceClose_fn = nil
        self.onceShow_fn = nil
        self.onceSkip_fn = nil
        self.isAnimOnShow = true
        self.onAnimOpenDoneTask = nil
        self.isShowManual = false
        self.isShow = false
        self.itemList = {}

        onUnload(thisPageName, container)
        -- 新手教學
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            GuideManager.forceNextNewbieGuide()
        end
    end

    --[[ 當動畫播放完畢 ]]
    function inst:onAnimationDone(container, eventName)
        if self.onAnimOpenDoneTask ~= nil then
            self.onAnimOpenDoneTask:next(1)
        end
    end

    --[[ 當 跳過 按下 ]]
    function inst:onSkipClick(container, eventName)
        if self.onceSkip_fn ~= nil then
            self.onceSkip_fn()
        end
    end
    
    --[[ 當 關閉 按下 ]]
    function inst:onExitClick(container, eventName)
        -- 清理列表
        NodeHelper:clearScrollView(self.container)
        -- 關閉 頁面
        PageManager.popPage(thisPageName)
        -- 檢查角色是否能解放
        local EquipPageBase = require("EquipmentPage")
        EquipPageBase:checkActivityHero()
    
        -- 若 有關閉行為 則 呼叫
        if self.onceClose_fn then
            self.onceClose_fn()
            self.onceClose_fn = nil
        end
    end

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

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

        -- 開啟顯示節點 / 關閉跳過節點
        self.container:getVarNode("showNode"):setVisible(true)
        self.container:getVarNode("skipNode"):setVisible(false)

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

    --[[ 刷新 物品顯示 ]]
    function inst:updateItems()
        local slf = self
        
        local size = #self.itemList
        
        local colMax = 4

        local options = { -- magic layout number
            interval = ccp(0, 0),
            colMax = colMax,
            paddingTop = 0,
            paddingBottom = 0,
            paddingLeft = 0,
            originScrollViewSize = CCSizeMake(468, 235),
        }
        
        -- 只有1行 則 橫向置中
        if size < colMax then
            options.isAlignCenterHorizontal = true
        end
        
        -- 未達 2行 則 垂直置中
        if size < colMax * 2 then
            options.isAlignCenterVertical = true
            options.startOffset = ccp(0, -74)
        -- 超過3行 則 顯示首項 並 偏移paddingTop
        else
            options.startOffsetAtItemIdx = 1
            options.startOffset = ccp(0, -options.paddingTop)
        end

        --[[ 滾動視圖 左上至右下 ]]
        NodeHelperUZ:buildScrollViewGrid_LT2RB(
            self.container,
            size,
            function(idx, funcHandler)
                local item = CommItem:new()
                item.onFunction_fn = funcHandler
                local itemContainer = item:requestUI()
                itemContainer:setScale(CommItem.Scales.regular)
                itemContainer.item = item
                return itemContainer
            end,
            function (eventName, container)
                local itemIdx = container:getItemDate().mID
                
                if eventName ~= "luaRefreshItemView" then return end

                local itemData = slf.itemList[itemIdx]
                if itemData == nil then 
                    print("itemData at "..tostring(itemIdx).." is not exist")
                    return
                end
                local itemInfo = InfoAccesser:getItemInfo(itemData.type or 30000, itemData.id, itemData.count or 1)
                if itemInfo == nil then 
                    dump(itemData, "itemInfo is not exist with data")
                    return
                end

                container.item:autoSetByItemInfo(itemInfo)
                
                container.item.onClick_fn = function()
                    GameUtil:showTip(
                        container,
                        {
                            type = itemInfo.type,
                            itemId = itemInfo.id,
                        }
                    )
                end
            end,
            options
        )
                
        -- 顯示/隱藏 列表 或 無獎勵提示
        NodeHelper:setNodesVisible(self.container, {
            mContent = size ~= 0 ,
            NoReward = size == 0
        })
        
        -- 若 數量 尚未超過 每行數量 的話
        if size <= colMax * 2  then
            local node = self.container:getVarNode("mContent")
            node:setTouchEnabled(false)
        end
    end

    --[[ 準備 ]]
    function inst:prepare(options)
        local isShowManual = options["isShowManual"]
        if isShowManual ~= nil then
            self.isShowManual = isShowManual
        end

        local itemsStr = options["itemsStr"]
        if itemsStr ~= nil then
            self:setItemsStr(itemsStr)
        end

        local itemInfos = options["itemInfos"]
        if itemInfos ~= nil then
            self:setItemInfos(itemInfos)
        end
        
        local itemDatas = options["itemDatas"]
        if itemDatas ~= nil then
            self:setItemDatas(itemDatas)
        end

        local onceClose_fn = options["onceClose_fn"]
        if onceClose_fn ~= nil then
            self.onceClose_fn = onceClose_fn
        end

        local onceSkip_fn = options["onceSkip_fn"]
        if onceSkip_fn ~= nil then
            self.onceSkip_fn = onceSkip_fn
        end
        
    end

    --[[ 設置 以 道具字串]]
    function inst:setItemsStr (itemsStr)
        local itemInfos = InfoAccesser:getItemInfosByStr(itemsStr)
        self:setItemInfos(itemInfos)
    end

    --[[ 設置 以 道具訊息ItemInfo ]]
    function inst:setItemInfos (itemInfos)
        local itemDatas = {}

        for idx, val in ipairs(itemInfos) do
            itemDatas[#itemDatas+1] = {
                id = val.itemId,
                type = val.type,
                count = val.count,
            }
        end
        
        self:setItemDatas(itemDatas)
    end

    
    --[[ 設置 以 道具資料 ]]
    function inst:setItemDatas (itemDatas)
        -- 材料
        local t1 = {}
        -- 装备
        local t2 = {}
        -- 道具
        local t3 = {}
        
        -- 清空道具
        self.itemList = {}

        -- dump(itemDatas, "setItemDatas")

        -- 分類
        for i = 1, #itemDatas do
            local data = itemDatas[i]
            local itemConfig = ConfigManager.getItemCfg()[data.id]
            if itemConfig and itemConfig.type == 36 then
                table.insert(t1, data)
            elseif itemConfig then
                table.insert(t3, data)
            else 
                table.insert(t2, data)
            end
        end

        -- 以品質排序
        table.sort(t3, function(item_1, item_2)
            local itemCfg_1 = ConfigManager.getItemCfg()[item_1.id]
            local itemCfg_2 = ConfigManager.getItemCfg()[item_2.id]
            if itemCfg_1 and itemCfg_2 then
                return itemCfg_1.quality < itemCfg_2.quality
            else
                return false
            end
        end)

        -- 重新加總
        for i = 1, #t3 do
            table.insert(self.itemList, t3[i])
        end
        for i = 1, #t2 do
            table.insert(self.itemList, t2[i])
        end
        for i = 1, #t1 do
            table.insert(self.itemList, t1[i])
        end

    end

    --[[ 設置 常用資料 (舊的用法) ]]
    function inst:setData(itemDatas, title, onceClose_fn)
        -- 防呆轉換
        itemDatas = self:_safeConvertItemDatas(itemDatas)
        self:setItemDatas(itemDatas)
        
        -- 標題
        self.title = title
        
        -- 設置 當關閉
        if onceClose_fn ~= nil then
            self.onceClose_fn = onceClose_fn
        end
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

        if self.onceShow_fn ~= nil then
            self.onceShow_fn()
            self.onceShow_fn = nil
        end
    end

    --[[ 安全檢查與轉換物品資料 ]]
    function inst:_safeConvertItemDatas (itemDatas)
        if itemDatas == nil then return {} end
        local convertedDatas = {}
        for idx, data in ipairs(itemDatas) do
            local convertedData = {}
            convertedData.id = data.id or data.itemId or data.itemID
            convertedData.type = data.type or data.itemType
            convertedData.count = data.count or data.itemCount
            convertedDatas[idx] = convertedData
        end
        return convertedDatas
    end


    return inst
end

local CommonPage = require('CommonPage')
return CommonPage.newSub(CommItemReceivePage:new(), thisPageName, option)