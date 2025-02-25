--[[ 
    name: InventoryPage
    desc: 背包 頁面 
    author: youzi
    update: 2023/8/22 14:08
    description: 
--]]

--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
-- __lang_loaded = __lang_loaded or {}
-- if not __lang_loaded["Lang/Inventory.lang"] then
--     __lang_loaded["Lang/Inventory.lang"] = true
--     Language:getInstance():addLanguageFile("Lang/Inventory.lang")
-- end

-- 引用 ------------------

local HP_pb = require("HP_pb") -- 包含协议id文件

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")
local ItemManager = require("Item.ItemManager");

local EquipOprHelper = require("Equip.EquipOprHelper")
local UserItemManager = require("Item.UserItemManager")

local CommItem = require("CommUnit.CommItem")
local ItemFate = require("Inventory.InventoryItem_Fate")
local ItemEquip = require("Inventory.InventoryItem_Equip")
local ItemDefault = require("Inventory.InventoryItem_Default")

-- 常數 ------------------

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ 頁面名稱 ]]
local PAGE_NAME = "Inventory.InventoryPage"

--[[ UI檔案 ]]
local CCBI_FILE = "BackpackPage.ccbi"

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
    onClose = "onCloseAreaClick",
    onTab1 = "onTabClick",
    onTab2 = "onTabClick",
    onTab3 = "onTabClick",
    onTab4 = "onTabClick",
}

--[[ 協定 ]]
local OPCODES = {
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
}

local TabType = {
    EQUIP = 1,
    ITEM = 2,
    SHARD = 3,
    RUNE = 4,
}

------------------------

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
        mNotItemTxt
        
    event
        onTab{1~4} 當分頁{1~4}按下

--]]



-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 


--[[ 容器 ]]
Inst.container = nil

--[[ 滾動視圖 ]]
Inst.scrollview = nil

--[[ 分頁數量 ]]
Inst.tabCount = 4

--[[ 每行欄位數 ]]
Inst.colCount = 5

--[[ 篩選器 ]]
Inst.filter = {}

--[[ 當前分頁 ]]
Inst.currentTabIdx = 0

-- 物品資料 -----

Inst.cellDatas = {}

Inst.Items = {}

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
function Inst:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.onReceivePlayerAward(msgBuff)
    end
end

--[[ 當收到訊息 ]]
function Inst:onReceiveMessage(container)
    local HP_pb = require("HP_pb")
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_SEVERINFO_UPDATE then
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode
        local opcodes = {
            HP_pb.EQUIP_INFO_SYNC_S,
            HP_pb.ITEM_INFO_SYNC_S,
            HP_pb.EQUIP_SELL_S
        }

        if common:table_hasValue(opcodes, opcode) then
            if opcode == HP_pb.ITEM_INFO_SYNC_S then
                PageInfo.itemSuitIds = UserItemManager:getUserItemSuitFragIds()
                NodeHelper:setNodesVisible(container, { mSuitBtnNode = false }) --#PageInfo.itemSuitIds ~= 0 or UserInfo.roleInfo.level >= GameConfig.SuitEquipLevelLimit
            end

            self:refreshPage()
        end
    elseif typeId == MSG_MAINFRAME_POPPAGE then
        local pageName = MsgMainFramePopPage:getTrueType(message).pageName
        if pageName == filterPage then
            self:refreshPage()
        end
    elseif typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == PAGE_NAME then
            self:refreshPage()
            if self.awDetailPage then
                self.awDetailPage:onReceiveMessage(container)
            end
        end
    elseif typeId == MSG_REFRESH_REDPOINT then
        NodeHelper:setNodesVisible(container, { mTabPoint3 = false--[[RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.PACKAGE_AW_TAB, 0)]] })
        if self.currentTabIdx == TabType.SHARD then
            for i = 1, #Inst.Items do
                Inst.Items[i].item.onFunction_fn("luaRefreshItemView", Inst.Items[i])
            end
        end
    end
end

--[[ 註冊 封包相關 ]]
function Inst:registerPacket(opcodes)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            self.container:registerPacket(opcode)
        end
    end
end


--[[ 註銷 封包相關 ]]
function Inst:removePacket(opcodes)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
			self.container:removePacket(opcode)
		end
    end
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (container)

    local slf = self

    self.container = container

    -- 註冊 協定
    self:registerPacket(OPCODES)
    container:registerMessage(MSG_REFRESH_REDPOINT)

    if IS_MOCK then


    end
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["BagPage"] = container
    local currPage = MainFrame:getInstance():getCurShowPageName()
    if GuideManager.isInGuide then  -- 新手教學中進入專武頁面
        PageManager.pushPage("NewbieGuideForcedPage")
        self:selectTab(3)
    elseif currPage == "EquipmentPage" then -- 英雄頁面中進入道具頁面
        self:selectTab(2)
    else
        self:selectTab(1)
    end

    NodeHelper:setNodesVisible(container, { mTabPoint3 = false--[[RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.PACKAGE_AW_TAB, 0)]] })
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(container)
    
end

--[[ 當 頁面 離開 ]]
function Inst:onExit(container)
    -- 註銷 協定相關
    self:removePacket(OPCODES)

    self.scrollview = nil

    self:reset()

    if self.awDetailPage then
        self.awDetailPage = nil
    end
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    container:removeMessage(MSG_REFRESH_REDPOINT)
end

function Inst:onCloseAreaClick()
    PageManager.popPage(PAGE_NAME)
end

function Inst:onTabClick(container, eventName)
    local tabNum = tonumber(string.sub(eventName, 6, -1))
    self:selectTab(tabNum)
end

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  


--[[ 重置 ]]
function Inst:reset ()
    self.filter = {
        mainClass = "All",
        subClass = 0,
    }
    
    self.container = nil
    self.currentTabIdx = 0
    self.cellDatas = {}
end

--[[ 設置 分頁 ]]
function Inst:selectTab(tabIdx)
    if tabIdx ~= self.currentTabIdx then
        self.currentTabIdx = tabIdx

        self:refreshPage() 

        self:setTabSelected(self.currentTabIdx)
    end
end

--[[ 設置 篩選 ]]
function Inst:setFilter(mainClass, subClass)
    self.filter = {
        mainClass = mainClass or "All",
        subClass = subClass or 0
    }
end


--[[ 刷新頁面 ]]
function Inst:refreshPage ()
    local slf = self
    
    -- 依照類型 蒐集資料

    self.cellDatas = {}

    -- 道具
    if self.currentTabIdx == TabType.ITEM then
        local itemIDList = UserItemManager:getUserItemNotSuitFragIds()
        -- dump(itemIDList, "itemIDList")
        table.sort(itemIDList, self:_getHandlerByTabType(self.currentTabIdx).sort)
        for idx, val in ipairs(itemIDList) do
            self.cellDatas[idx] = {
                -- required
                type = Const_pb.TOOL,
                -- opt
                itemInfo = InfoAccesser:getUserItemInfo(Const_pb.TOOL, val),
            }
        end
    
    -- 裝備
    elseif self.currentTabIdx == TabType.EQUIP then
        local equipIDList = UserEquipManager:getEquipIdsByClass(self.filter.mainClass, self.filter.subClass)
        -- dump(equipIDList, "equipIDList")
        local equipItemIdList = { }
        for idx, val in ipairs(equipIDList) do
            local equip = UserEquipManager:getUserEquipById(val)
            equipItemIdList[equip.equipId] = equipItemIdList[equip.equipId] or { id = val, count = 0, itemId = equip.equipId }
            equipItemIdList[equip.equipId].count = equipItemIdList[equip.equipId].count + 1
        end
        local equipIdxList = { }
        for idx, data in pairs(equipItemIdList) do
            if data.itemId < 10000 then
                table.insert(equipIdxList, data)
            end
        end
        table.sort(equipIdxList, self:_getHandlerByTabType(self.currentTabIdx).sort)
        for idx, data in pairs(equipIdxList) do
            
            self.cellDatas[idx] = {
                -- required
                type = Const_pb.EQUIP,
                -- opt
                -- itemInfo = InfoAccesser:getUserEquipInfo(val),
                id = data.id,
                count = data.count,
            }
        end

    -- 碎片
    elseif self.currentTabIdx == TabType.SHARD then
        -- 裝備碎片
        local itemIDList = UserItemManager:getUserItemSuitFragIds()
        -- dump(itemIDList, "itemIDList")
        table.sort(itemIDList, self:_getHandlerByTabType(self.currentTabIdx).sort)
        for idx, val in ipairs(itemIDList) do
            self.cellDatas[idx] = {
                -- required
                type = Const_pb.TOOL,
                -- opt
                itemInfo = InfoAccesser:getUserItemInfo(Const_pb.TOOL, val),
            }
        end

    -- 符石
    elseif self.currentTabIdx == TabType.RUNE then
        local FateDataManager = require("FateDataManager")
        local temp = FateDataManager:getNotWearFateList()
        local dataList = {}
        for k, v in pairs(temp) do
            dataList[#dataList + 1] = v
        end
        -- dump(dataList, "dataList")
        table.sort(dataList, self:_getHandlerByTabType(self.currentTabIdx).sort)
        for idx, val in ipairs(dataList) do
            self.cellDatas[idx] = {
                -- required
                type = Const_pb.BADGE,
                -- opt
                fateData = val,
            }
        end
    end

    NodeHelper:setNodesVisible(self.container, {
        mNoItemTxt = #self.cellDatas == 0
    })

    self:rebuildItems()
end

--[[ 組建 項目列表 ]]
function Inst:rebuildItems ()
    local slf = self
    if not self.container then return end
    if self.scrollview ~= nil then
        NodeHelper:clearScrollView(self.container)
    else
        self.scrollview = self.container:getVarScrollView("mContent")
    end

    NodeHelper:initScrollView(self.container, "mContent", #self.cellDatas)

    Inst.Items = { }
    --[[ 滾動視圖 左上至右下 ]]
    NodeHelperUZ:buildScrollViewGrid_LT2RB(
        self.container,
        #self.cellDatas,
        
        function (idx, funcHandler)
            local item = CommItem:new()
            item.onFunction_fn = funcHandler
            local itemContainer = item:requestUI()
            itemContainer:setScale(CommItem.Scales.regular)
            itemContainer.item = item
            item.isInventory = true
            table.insert(Inst.Items, itemContainer)
            return itemContainer
        end,

        function (eventName, container)
            if eventName ~= "luaRefreshItemView" then return end

            local idx = container:getItemDate().mID
            local cellData = slf.cellDatas[idx]
            local commItem = container.item
            
            local handler = self:_getHandlerByConstType(cellData.type)

            handler:setUI(commItem, cellData)
            
            commItem.onClick_fn = function (item, container)
                handler:onClick(slf, cellData)
            end
        end,
        {
            -- magic layout number 
            -- 因為CommonRewardContent尺寸異常，導致各使用處需要自行處理
            interval = ccp(5, 5),
            colMax = slf.colCount,
            paddingTop = 0,
            paddingLeft = 0,
            originScrollViewSize = self.container:getVarNode("scrollViewRef"):getContentSize(),
            isDisableTouchWhenNotFull = true,
            startOffsetAtItemIdx = 1,
        }
    )
    self.scrollview:setContentOffset(ccp(0, math.min(0, self.scrollview:getViewSize().height - self.scrollview:getContentSize().height)))
end

--  #     # ###        
--  #     #  #   ####  
--  #     #  #  #      
--  #     #  #   ####  
--  #     #  #       # 
--  #     #  #  #    # 
--   #####  ###  ####  
--                     

--[[ 設置 分頁選取狀態 ]]
function Inst:setTabSelected(tabIdx)

    local node2MenuItemSelected = {}
    local node2MenuItemEnabled = {}
    local node2Visible = {}
    local node2Color = {}
    for idx = 1, self.tabCount do
        local idxStr = tostring(idx)
        local isSelected = idx == tabIdx
        
        local var_btn = "tabBtn"..idxStr
        node2MenuItemSelected[var_btn] = isSelected
        -- node2MenuItemEnabled[var_btn] = idx ~= tabIdx

        local var_iconOn = "tabIcon"..idxStr.."_ON"
        node2Visible[var_iconOn] = isSelected

        local var_node = "tabNode"..idxStr
        
        local textColor
        
        if isSelected then
            textColor = GameConfig.COMMON_TAB_COLOR.SELECT
            self.container:getVarNode(var_node):setZOrder(0)
        else
            textColor = GameConfig.COMMON_TAB_COLOR.UNSELECT
        end
        
        local var_tabText = "tabText"..idxStr
        node2Color[var_tabText] = textColor
        
    end

    NodeHelper:setMenuItemSelected(self.container, node2MenuItemSelected)
    -- NodeHelper:setMenuItemsEnabled(self.container, node2MenuItemEnabled)
    NodeHelper:setNodesVisible(self.container, node2Visible)
    NodeHelper:setColorForLabel(self.container, node2Color)
end

-- ########  ########  #### ##     ##    ###    ######## ######## 
-- ##     ## ##     ##  ##  ##     ##   ## ##      ##    ##       
-- ##     ## ##     ##  ##  ##     ##  ##   ##     ##    ##       
-- ########  ########   ##  ##     ## ##     ##    ##    ######   
-- ##        ##   ##    ##   ##   ##  #########    ##    ##       
-- ##        ##    ##   ##    ## ##   ##     ##    ##    ##       
-- ##        ##     ## ####    ###    ##     ##    ##    ######## 



--[[ 取得處理器 ]]
function Inst:_getHandlerByConstType (typ)
    if typ == Const_pb.EQUIP then
        return ItemEquip
    elseif typ == Const_pb.BADGE then
        return ItemFate
    else
        return ItemDefault
    end 
end

--[[ 取得處理器 ]]
function Inst:_getHandlerByTabType (typ)
    if typ == TabType.EQUIP then
        return ItemEquip
    elseif typ == TabType.RUNE then
        return ItemFate
    else
        return ItemDefault
    end 
end


--  ######  ########  ########  ######  ####    ###    ##       
-- ##    ## ##     ## ##       ##    ##  ##    ## ##   ##       
-- ##       ##     ## ##       ##        ##   ##   ##  ##       
--  ######  ########  ######   ##        ##  ##     ## ##       
--       ## ##        ##       ##        ##  ######### ##       
-- ##    ## ##        ##       ##    ##  ##  ##     ## ##       
--  ######  ##        ########  ######  #### ##     ## ######## 


--[[ 提供 高速扫荡卷 引导 使用 ]]
function Inst:Guide_HighSpeedSweetUse()
    local index = 1
    local itemId = Inst.itemIDList[index]
    local userItem = UserItemManager:getUserItemByItemId(itemId)
    PageManager.showItemInfo(userItem.id)
end


-- ######## #### ##    ##    ###    ##       
-- ##        ##  ###   ##   ## ##   ##       
-- ##        ##  ####  ##  ##   ##  ##       
-- ######    ##  ## ## ## ##     ## ##       
-- ##        ##  ##  #### ######### ##       
-- ##        ##  ##   ### ##     ## ##       
-- ##       #### ##    ## ##     ## ######## 

local CommonPage = require("CommonPage")
return CommonPage.newSub(Inst, PAGE_NAME, {
    ccbiFile = CCBI_FILE,
    handlerMap = HANDLER_MAP,
    opcode = OPCODES,
})