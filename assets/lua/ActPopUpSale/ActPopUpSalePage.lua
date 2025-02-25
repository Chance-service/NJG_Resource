----------------------------------------------------------------------------------
--[[
    name: ActPopUpSalePage
    desc: 活動彈窗促銷
    author: youzi
    update: 2023/6/28 16:18
    description: 
        
        -- 彈跳禮包頁面
        local actPopupSalePage = require("ActPopUpSale.ActPopUpSalePage")

        -- 若要只顯示部分頁面則需要改寫ActPopUpSalePage.lua

        -- 設置 進入後初始頁面 名稱對應tabInfo
        actPopupSalePage:setEntryTab("151")

        -- 跳出頁面
        PageManager.pushPage("ActPopUpSale.ActPopUpSalePage")
--]]


--[[ 
    ccbi var

    Act_PopUpSale.ccbi :
        text
        
        var 
            contentNode : 內容容器
            tabsScrollView : 分頁滾動視圖

        event
            onClose : 當 關閉 按下
    
    Act_PopUpSaleContent.ccbi :
        text

        var 
            img : 圖標
            text : 文字
            btn : 按鈕

        event
    
--]]

----------------------------------------------------------------------------------

-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 


local IS_DEBUG = false

-- 模塊工具
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local Activity4_pb = require("Activity4_pb")

local thisPageName = "ActPopUpSale.ActPopUpSalePage"

-- 分頁頁面
local ActPopUpSalePage = {}

-- 分頁圖標 (於尾頁定義)
local TabContainer = {}


-- 頁面設定
local CCBI_FILE = "Act_PopupSale.ccbi"

-- UI指定方法 : 函式名稱 對照
local HANDLER_MAP = {
    onClose = "onCloseBtn",
}

-- 協定
local OPCODES = {
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    LAST_SHOP_ITEM_S = HP_pb.LAST_SHOP_ITEM_S,
}


local option = {
    ccbiFile = CCBI_FILE,
    handlerMap = HANDLER_MAP,
    opcode = OPCODES,
}

local TABINFOS = {
    {
        name = "132",
        subPage = "ActPopUpSale.ActPopUpSaleSubPage_132",
        Cfg=ConfigManager.getAct132Cfg(),
        sort = 1,
        isShowFn = function (self)
            if IS_DEBUG then return true end
            require(self.subPage)
            local data = ActPopUpSaleSubPage_132_getIsShowMainSceneIcon()
            -- { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
            return data.isShowIcon
        end,
    },
    {
        name = "151",
        subPage = "ActPopUpSale.ActPopUpSaleSubPage_151",
        Cfg=ConfigManager.getAct151Cfg(),
        sort = 1 ,
        isShowFn = function (self)
            if IS_DEBUG then return true end
            require(self.subPage)
            local data = ActPopUpSaleSubPage_151_getIsShowMainSceneIcon()
            -- { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
            return data.isShowIcon
        end,
    },
   {
       name = "177",
       subPage = "ActPopUpSale.ActPopUpSaleSubPage_177",
       sort = 1,
       isShowFn = function (self)
           if IS_DEBUG then return true end
           require(self.subPage)
           local data = ActPopUpSaleSubPage_177_getIsShowMainSceneIcon()
           -- { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
           return data.isShowIcon
       end,
   },
}

-- 子頁面對應

function ActPopUpSalePage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 是否已經初始化
ActPopUpSalePage._isInited = false

-- 主容器
ActPopUpSalePage.container = nil

-- 內容容器
ActPopUpSalePage.contentNode = nil

-- 子頁面
ActPopUpSalePage.subPage = nil
ActPopUpSalePage.subPageContainer = nil

-- 分頁資訊
ActPopUpSalePage.tabInfos = {}

-- 分頁資料 (內部存取)
ActPopUpSalePage._tabDatas = {}

-- 圖標列 排版選項覆蓋
ActPopUpSalePage.scrollViewOverrideOptions = nil

-- 上次選中
ActPopUpSalePage.lastSelectIdx = nil

-- 初始 滾動視圖 尺寸
ActPopUpSalePage._originScrollViewSize = nil

-- 初始進入頁面
ActPopUpSalePage.entryTab = nil

-- 購買資料請求中
ActPopUpSalePage.requestingLastShop = false

--獎勵
local TmpReward = { }

local serverData={}
-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到訊息 ]]
function ActPopUpSalePage:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_RECHARGE_SUCCESS then
        if ActPopUpSalePage.requestingLastShop then
            return
        end
        ActPopUpSalePage.requestingLastShop = true
        --popUp資料要求
        require("ActPopUpSale.ActPopUpSaleSubPage_132")
        require("ActPopUpSale.ActPopUpSaleSubPage_177")
        ActPopUpSaleSubPage_132_sendInfoRequest()
        ActPopUpSaleSubPage_177_sendInfoRequest()      
        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
        ActPopUpSaleSubPage_Content_sendInfoRequest()
        CCLuaLog(">>>>>>onReceiveMessage ActPopUpSalePage")
        common:sendEmptyPacket(HP_pb.LAST_SHOP_ITEM_C, true)
    end
 
end
function ActPopUpSalePage_setReward(data)
   TmpReward = data
end
--[[ 當 收到封包 ]]
function ActPopUpSalePage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.PLAYER_AWARD_S then
        --local PackageLogicForLua = require("PackageLogicForLua")
        --PackageLogicForLua.PopUpReward(msgBuff)
        --PageManager.popPage(thisPageName)
    elseif opcode == HP_pb.LAST_SHOP_ITEM_S then
        ActPopUpSalePage.requestingLastShop = false
        local Recharge_pb = require("Recharge_pb")
        local msg = Recharge_pb.LastGoodsItem()
        msg:ParseFromString(msgBuff)
        if msg.Items == "" then return end
        local Items = common:parseItemWithComma(msg.Items)
        if next(Items) then
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            CommonRewardPage:setData(Items, common:getLanguageString("@ItemObtainded"), nil)
            PageManager.pushPage("CommPop.CommItemReceivePage")
            PageManager.popPage(thisPageName)
            common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
            -- 同步解鎖4倍速戰鬥標籤
            FlagDataBase_ReqStatus()
        end
    end
end

--[[ 註冊 封包相關 ]]
function ActPopUpSalePage:registerPacket(container)
    for key, opcode in pairs(OPCODES) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
--[[ 註銷 封包相關 ]]
function ActPopUpSalePage:removePacket(container)
    for key, opcode in pairs(OPCODES) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end
--[[取得 時間資料]]
function ActPopUpSalePage:setTime(idx,limitDate,Got,NowID)
    serverData[idx]={time=limitDate,isGot=Got,id=NowID}
end

function ActPopUpSalePage:onExecute(container)
    if self.subPage ~= nil then
        if self.subPage.onExecute ~= nil then
            self.subPage:onExecute(self.container)
        end
    end
end	

--[[ 當 頁面 進入 ]]
function ActPopUpSalePage:onEnter (container)
    local slf = self
    self.container = container
    container:registerMessage(MSG_RECHARGE_SUCCESS)
    -- print("CommItemReceivePage.onEnter")
    
    -- 註冊 封包相關
    self:registerPacket(container)
    -- print("ActPopUpSalePage : createPage : "..tostring(self.container ~= nil))

    -- 紀錄 初始 滾動視圖尺寸
    self._originScrollViewSize = CCSizeMake(650, 160)
    -- self._originScrollViewSize = self.container:getVarNode("tabsScrollView"):getContentSize()
    -- 若從現有node取尺寸，會取到(0,0)，不確定原因

    -- 內容容器
    self.contentNode = self.container:getVarNode("contentNode")

    -- 設置 分頁資訊
    self:setTabInfos(self:getAvaliableActs())

    -- 預設 顯示所有未選取
    self:setTabSelected(-1)

    -- 設 已初始化
    self._isInited = true
    
    ActPopUpSalePage.requestingLastShop = false

    if #self.tabInfos > 0 then
        if self.entryTab ~= nil then
            local typ = type(self.entryTab)
            if typ == "string" then        
                self:selectTabByName(self.entryTab)
            else
                self:selectTab(self.entryTab)
            end
            self.entryTab = nil
        else
            self:selectTab(1)
        end
    end
    --local msg = Recharge_pb.HPFetchShopList()
    --msg.platform = GameConfig.win32Platform
    --CCLuaLog("PlatformName2:" .. msg.platform)
    --pb_data = msg:SerializeToString()
    --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, false)

    -- 播放開啟頁面特效
    if self.subPage ~= nil then
        if self.subPage.onPlayEnterSpine ~= nil then
            self.subPage:onPlayEnterSpine(self.subPageContainer)
        end
    end

    PageManager.setIsInPopSalePage(true)
end

--[[ 當 頁面 離開 ]]
function ActPopUpSalePage:onExit(container)
    self:removePacket(container)
    self:clear()
    onUnload(thisPageName, container)
    container:removeMessage(MSG_RECHARGE_SUCCESS)
    PageManager.setIsInPopSalePage(false)
end
    
--  #     # ### 
--  #     #  #  
--  #     #  #  
--  #     #  #  
--  #     #  #  
--  #     #  #  
--   #####  ### 
--              

--[[ 當 關閉按鈕 點選 ]]
function ActPopUpSalePage:onCloseBtn (container)
    print("ActPopUpSalePage onCloseBtn")
    PageManager.popPage(thisPageName)
end

--[[ 當 分頁按鈕 點選 ]]
function ActPopUpSalePage:onTabBtn (container, index)
    self:selectTab(index)
end

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 設置 初始進入頁 ]]
function ActPopUpSalePage:setEntryTab(nameOrIdx)
    self.entryTab = nameOrIdx
end

function ActPopUpSalePage_getPrice(id)
    if #RechargeCfg==0 then
        return 99999
    end
    local Info = nil
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == id then
            Info = RechargeCfg[i]
            break
        end
    end
    return Info.productPrice
end

--[[ 取得 可用的活動數量 ]]
function ActPopUpSalePage:getAvaliableActs()
    local Table = common:deepCopy(TABINFOS)
    --local cfg = ConfigManager.getPopUpCfg()
    
    -- 過濾與插入活動資料
    --for _, data in pairs(cfg) do
    --    if data.activityId ~= 132 and data.activityId ~= 177 then
    --        table.insert(Table, {
    --            name = tostring(data.activityId),
    --            subPage = "ActPopUpSale.ActPopUpSaleSubPage_Content",
    --            isShowFn = function(self)
    --                if IS_DEBUG then return true end
    --                require(self.subPage)
    --                local result = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(data.activityId)
    --                return result.isShowIcon
    --            end,
    --        })
    --    end
    --end

    local cfg = ConfigManager.getPopUpCfg2()
    for _, data in pairs(cfg) do
       table.insert(Table, {
           name = tostring(data.GiftId),
           sort = data.Sort + 1 ,--空出戰敗或等級
           subPage = "ActPopUpSale.ActPopUpSaleSubPage_Content",
           isShowFn = function(self)
               if IS_DEBUG then return true end
               require(self.subPage)
               local result = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(data.GiftId)
               return result.isShowIcon
           end,
       })
    end

    local Infos = self:mergeServerData(Table)
    self:removeExpiredAndBoughtActivities(Infos)
   table.sort(Infos, function(a, b)
        if (a.sort or 0) == (b.sort or 0) then
            return (a.time or 0) < (b.time or 0)
        else
            return (a.sort or 0) < (b.sort or 0)
        end
    end)


    return self:filterVisibleActivities(Infos)
end

function ActPopUpSalePage:mergeServerData(Table)
    local Infos = {}
    for _, v in pairs(Table) do
        local serverInfo = serverData[tonumber(v.name)]
        if serverInfo then
            v.time, v.isGot, v.id = serverInfo.time, serverInfo.isGot, serverInfo.id
        end
        table.insert(Infos, v)
    end
    return Infos
end

function ActPopUpSalePage:removeExpiredAndBoughtActivities(Infos)
    local currentTime = os.time()
    for i = #Infos, 1, -1 do
        local v = Infos[i]
        if (v.time and v.time <= currentTime) or v.isGot then
            table.remove(Infos, i)
        end
    end
end

function ActPopUpSalePage:filterVisibleActivities(Infos)
    local avaliableActs = {}
    for _, info in ipairs(Infos) do
        if not info.isShowFn or info:isShowFn() then
            table.insert(avaliableActs, info)
        end
    end
    return avaliableActs
end


--[[ 設置 覆寫排版選項 ]]
function ActPopUpSalePage:setScrollViewOverrideOptions (overrideOptions)
    self.scrollViewOverrideOptions = overrideOptions
end

--[[ 設置 分頁資訊 ]]
function ActPopUpSalePage:setTabInfos (tabInfos) 
    self.tabInfos = common:deepCopy(tabInfos)
    for idx, val in ipairs(tabInfos) do
        self._tabDatas[idx] = {}
    end
    -- dump(tabInfos, "ActPopUpSalePage : tabInfos")
    self:rebuildTabs()
end

--[[ 重置 ]]
function ActPopUpSalePage:clear ()
    self.tabInfos = {}
    self._tabDatas = {}
    self.lastSelectIdx = nil
    self:clearSubPage()
    self:rebuildTabs()
end

--[[ 重新建立 分頁列 ]]
function ActPopUpSalePage:rebuildTabs ()
    if self.container == nil then return end
    -- print("ActPopUpSalePage : rebuildTabs"..tostring(self.container ~= nil))
    -- dump(self.container, "ActPopUpSalePage.container")


    -- 初始化 分頁圖標 列表
    NodeHelperUZ:initScrollView(self.container, "tabsScrollView", #self.tabInfos)

    -- 預設選項
    local options = {
        paddingLeft = 0,
        scrollViewSize = self._originScrollViewSize,
        isDisableTouchWhenNotFull = true,
    }

    -- 若 有覆寫排版選項 則 覆寫
    if self.scrollViewOverrideOptions ~= nil then
        for key, val in pairs(self.scrollViewOverrideOptions) do
            options[key] = val
        end
    end

    -- 建立 分頁圖標 列表
    local slf = self
    NodeHelperUZ:buildScrollViewHorizontal(self.container, #self.tabInfos,
        TabContainer.ccbiFile, 
        function (eventName, itemContainer)
            TabContainer:onFunction(slf, eventName, itemContainer)
        end, 
        options
    )
end

--[[ 刷新 分頁圖標 ]]
function ActPopUpSalePage:refreshTab(tabIdx, tabInfo_overrite) 
    
    if tabInfo_overrite ~= nil then
        local tabInfo = self.tabInfos[tabIdx]
        if tabInfo ~= nil then
            for key, val in pairs(tabInfo_overrite) do
                tabInfo[key] = val
            end
        end
    end

    local tabData = self._tabDatas[tabIdx]
    if tabData.itemContainer == nil then return end
    
    TabContainer:onRefreshItemView(self, tabData.itemContainer)
end

--[[ 選擇 分頁 ]]
function ActPopUpSalePage:selectTabByName (name)
    local tabIdx = nil
    for idx = 1, #self.tabInfos do 
        local tabInfo = self.tabInfos[idx]
        if tabInfo.name == name then
            tabIdx = idx
            break
        end
    end
    if tabIdx ~= nil then 
        self:selectTab(tabIdx)
    else
        self:selectTab(1)
    end
end

--[[ 選擇 分頁 ]]
function ActPopUpSalePage:selectTab (tabIdx)
    if tabIdx <= 0 or tabIdx > #self.tabInfos then return end

    -- 設置 圖標 選中 狀態
    self:setTabSelected(tabIdx)

    local lastIdx = self.lastSelectIdx
    -- print("self.onTabSelect : "..tostring(index).."/"..tostring(lastIdx))

    if lastIdx ~= tabIdx then    
        self.lastSelectIdx = tabIdx
        -- 呼叫 當分頁選中 行為
        self:onTabSelect(tabIdx, lastIdx)
    end
end

--[[ 設置 分頁 狀態 ]]
function ActPopUpSalePage:setTabSelected (tabIdx)
    for idx, tabInfo in ipairs(self.tabInfos) do
        local tabData = self._tabDatas[idx]
        tabData.itemContainer:getVarMenuItemImage("btn"):setEnabled(idx ~= tabIdx)
    end
end

function ActPopUpSalePage:clearSubPage () 
    if self.subPage ~= nil then
        self.subPage:onExit(self.container)
        self.subPage = nil
    end
    if self.subPageContainer ~= nil then
        self.contentNode:removeChild(self.subPageContainer, true)
        self.subPageContainer = nil
    end
end

function ActPopUpSalePage:onTabSelect (nextTab, lastTab)
    local tabInfo = self.tabInfos[nextTab]
    local subPageName = tabInfo.subPage
    
    self:clearSubPage()
    
    self.subPage = require(subPageName)

    ActPopUpSaleSubPage_setGiftId(tonumber(tabInfo.name))
    self.subPageContainer = self.subPage:onEnter(self.container)

    if self.subPageContainer ~= nil then
        self.contentNode:addChild(self.subPageContainer)
    end
end

---------------------------------------------------------------------------------

-- ########    ###    ########       ######   #######  ##    ## ########    ###    #### ##    ## ######## ########  
--    ##      ## ##   ##     ##     ##    ## ##     ## ###   ##    ##      ## ##    ##  ###   ## ##       ##     ## 
--    ##     ##   ##  ##     ##     ##       ##     ## ####  ##    ##     ##   ##   ##  ####  ## ##       ##     ## 
--    ##    ##     ## ########      ##       ##     ## ## ## ##    ##    ##     ##  ##  ## ## ## ######   ########  
--    ##    ######### ##     ##     ##       ##     ## ##  ####    ##    #########  ##  ##  #### ##       ##   ##   
--    ##    ##     ## ##     ##     ##    ## ##     ## ##   ###    ##    ##     ##  ##  ##   ### ##       ##    ##  
--    ##    ##     ## ########       ######   #######  ##    ##    ##    ##     ## #### ##    ## ######## ##     ## 

-- 設定
TabContainer = {
    ccbiFile = "Act_PopupSaleContent.ccbi"
}

function TabContainer:onFunction (inst, eventName, itemContainer)
    if eventName == "luaRefreshItemView" then
        TabContainer:onRefreshItemView(inst, itemContainer)
    elseif eventName == "onBtn" then
        TabContainer:onBtn(inst, itemContainer)
    end
end

--[[ 當 按下 ]]
function TabContainer:onBtn(inst, itemContainer)
    local itemIdx = tonumber(itemContainer:getItemDate().mID)
    local tabIdx = itemIdx
    inst:onTabBtn(itemContainer, tabIdx)
end

--[[ 當 刷新視圖 ]]
function TabContainer:onRefreshItemView(inst, itemContainer)
    local itemIdx = tonumber(itemContainer:getItemDate().mID)
    local tabIdx = itemIdx
    
    local tabInfo = inst.tabInfos[tabIdx]
    local tabData = inst._tabDatas[tabIdx]

    -- 設置 圖標容器 至 分頁資料
    tabData.itemContainer = itemContainer

    -- 設置 圖標圖片 
     local ImgData = common:getPopUpData(tonumber(tabInfo.name))
     if ImgData then
        local Img ,Text = ImgData.Icon , ImgData.Title
        if Img ~= nil then
            NodeHelper:setSpriteImage(tabData.itemContainer, {
                img = Img
            })
        end
    
        ---- 設置 圖標文字
        if Text ~= nil then
            NodeHelper:setStringForLabel(tabData.itemContainer, {
                text = common:getLanguageString(Text)
            })
        end   
    elseif tonumber (tabInfo.name) == 132 then
        NodeHelper:setSpriteImage(tabData.itemContainer, {
           img = "popsale_151_icon.png"
        })
            NodeHelper:setStringForLabel(tabData.itemContainer, {
                text = common:getLanguageString("@popsale_132_title")
            })
    elseif tonumber (tabInfo.name) == 177 then
        NodeHelper:setSpriteImage(tabData.itemContainer, {
           img = "popsale_151_icon.png"
        })
        NodeHelper:setStringForLabel(tabData.itemContainer, {
            text = common:getLanguageString("@popsale_177_title")
        })
    end
    -- 設置 圖標數字
    if tabInfo.id ~= nil and tabInfo.Cfg~=nil then
        local string=tabInfo.Cfg[tabInfo.id].minLv or tabInfo.Cfg[tabInfo.id].minStage
        NodeHelper:setStringForLabel(tabData.itemContainer, {
            mTxt = string
        })
    else
        NodeHelper:setNodesVisible(tabData.itemContainer,{mTxt=false})
    end

    -- 透過 tabInfo / tabData 進行 其他設置行為 ------------

    -- 設置 圖標紅點
    local isRedpointShow = false
    if tabInfo.redpoint ~= nil then
        isRedpointShow = tabInfo.redpoint
    end
    NodeHelper:setNodesVisible(itemContainer, {
        redpoint = isRedpointShow
    })

end

---------------------------------------------------------------------------------

local CommonPage = require('CommonPage')
local ActPopUpSalePageInst = CommonPage.newSub(ActPopUpSalePage, thisPageName, option)

return ActPopUpSalePage