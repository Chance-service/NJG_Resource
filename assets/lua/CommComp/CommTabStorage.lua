----------------------------------------------------------------------------------
--[[
    name: 分頁列 頁面 (通用收納頁面)
    desc: 分頁 與 子頁面容器
    author: youzi
    description:
        
        -- 使用範例

        local CommTabStorage = require("CommTabStorage")

        -- 準備 分頁資訊
        local tabInfos = {
            {
                -- 類型 : 預設
                iconType = "default",
            },
            {
                -- 類型 : 
                iconType = "image",
                -- 一般
                icon_normal = "<img_path>",
                -- 選中 (若模式為"image"才有效)
                icon_selected = "<img_path>",
            },
        }

        
        -- 建立邏輯物件
        local storagePage = CommTabStorage:new()
        -- 初始化 與 產生UI容器
        local storagePageContainer = storagePage:init(tabInfos)

        -- 選中 第一項
        storagePage:selectTab(1)

        -- 註冊 選中行為 (nextIdx:當前選中分頁序號, lastIdx:前個選中分頁序號(若無則nil))
        storage.onTabSelect_fn = function(nextIdx, lastIdx)
            -- 自定義行為 (如依照序號顯示不同子頁面)
        end

        -- 設置 標題
        storagePage:setTitle("@FairTitle")

        -- 設置 貨幣顯示資訊
        storagePage:setCurrencyDatas(
            -- 從 最左側 開始
            {
                icon = "<img_path>",
                count = 8888, 
            },
            {
                icon = "<img_path>",
                count = 9999, 
            },
        })
--]]
----------------------------------------------------------------------------------

-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 


-- 模塊工具
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")

-- 分頁頁面
local CommTabStorage = {}
-- 分頁圖標 (於尾頁定義)
local TabContainer = {}

-- 貨幣資訊UI 數量
local CURRENCY_UI_COUNT = 2
-- 頁面設定
local CCBI_FILE = "CommonTabStorage.ccbi"
-- 對照 UI指定方法 : 函式名稱
local HANDLER_MAP = {
    onReturnBtn = "onCloseBtn",
    onHelp = "onHelp",
}

function CommTabStorage:new ()
    local Inst = {}

    -- 是否已經初始化
    Inst._isInited = false

    -- 主容器
    Inst.container = nil

    -- 分頁資訊
    Inst.tabInfos = {}

    -- 分頁資料 (內部存取)
    Inst._tabDatas = {}

    -- 是否鎖住操作
    Inst.isLockedInput = false

    -- 圖標列 排版選項覆蓋
    Inst.scrollViewOverrideOptions = nil

    -- 上次選中
    Inst.lastSelectIdx = nil

    -- 初始 滾動視圖 尺寸
    Inst._originScrollViewSize = nil

    -- 貨幣資料
    Inst.currencyDatas = nil

    -- 當 關閉 行為
    Inst.onClose_fn = function () MainFrame_onMainPageBtn() end

    -- 當 選擇分頁 行為
    Inst.onTabSelect_fn = function (nextTab, lastTab) end

    -- 當 點選貨幣 行為
    Inst.onCurrencyBtn_fn = function (idx, itemInfo) end

    -- 當 點選貨幣 行為
    Inst.onHelpBtn_fn = function (idx) end

    -- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
    --  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
    --  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
    --  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
    --  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
    --  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
    -- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


        
    --  #     # ### 
    --  #     #  #  
    --  #     #  #  
    --  #     #  #  
    --  #     #  #  
    --  #     #  #  
    --   #####  ### 
    --              

    --[[ 當 關閉按鈕 點選 ]]
    function Inst:onCloseBtn (container)
        -- 新手教學中 自由操作時(type8)跳出
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            local guideCfg = GuideManager.getStepCfgByIndex(GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
            if guideCfg and guideCfg.showType == GameConfig.GUIDE_TYPE.POP_NEWBIE_PAGE then
                MessageBoxPage:Msg_Box(common:getLanguageString("@TutorialError"))
                return
            elseif guideCfg and guideCfg.showType == 10 then
                GuideManager.forceNextNewbieGuide()
            end
        end
        if self.isLockedInput then return end
        self.onClose_fn()
    end

    --[[ 當 分頁按鈕 點選 ]]
    function Inst:onTabBtn (container, index)
        -- 新手教學中 自由操作時(type8)跳出
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            local guideCfg = GuideManager.getStepCfgByIndex(GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
            if guideCfg and guideCfg.showType == GameConfig.GUIDE_TYPE.POP_NEWBIE_PAGE then
                MessageBoxPage:Msg_Box(common:getLanguageString("@TutorialError"))
                return
            end
        end
        if self.isLockedInput then return end
        self:selectTab(index)
    end
    
    function Inst:onCurrencyBtn (idx)
        if self.isLockedInput then return end

        local itemInfo
        local currencyData = self.currencyDatas[idx]
        if currencyData ~= nil then
            itemInfo = currencyData.itemInfo or currencyData
        end
        self.onCurrencyBtn_fn(idx, itemInfo)
    end

    function Inst:onHelp ()
        self.onHelpBtn_fn(self.lastSelectIdx)
    end

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 初始化 ]]
    function Inst:init(tabInfos, pageName) 
        if self._isInited then return end
        
        self.currencyDatas = {}
        
        self.container = ScriptContentBase:create(CCBI_FILE)
        -- print("CommTabStorage : createPage : "..tostring(self.container ~= nil))

        -- 紀錄 初始 滾動視圖尺寸
        
        self._originScrollViewSize = CCSizeMake(600, 115)
        
        -- self._originScrollViewSize = self.container:getVarNode("tabsScrollView"):getContentSize()
        -- 若從現有node取尺寸，會取到(0,0)，不確定原因


        -- 註冊 呼叫 行為
        self.container:registerFunctionHandler(function (eventName, container)
            local funcName = HANDLER_MAP[eventName]
            local func = self[funcName]
            if func then
                func(self, container)
            elseif string.sub(eventName, 1, 14) == "onCurrencyBtn_" then
                local idx = tonumber(string.sub(eventName, 15))
                self:onCurrencyBtn(CommTabStorage:_getRevertIdx(idx, #self.currencyDatas))
            end
        end)

        -- 設置 分頁資訊
        self:setTabInfos(tabInfos)

        -- 預設 顯示所有未選取
        self:setTabSelected(-1)

        -- 設 已初始化
        self._isInited = true

        if pageName =="GloryHole.GloryHolePage" then
            local GloryHole = require ("GloryHole.GloryHoleSubPage_MainScene")
            if not GloryHole:getOpenAni() then
                self.container:runAnimation("GloryHole")
                GloryHole:setOpenAni(true)
            end
        elseif pageName =="SecretMessage.SecretPage" then
              self.container:runAnimation("SecretMessage")
        end

        local GuideManager = require("Guide.GuideManager")
        if pageName then
            GuideManager.PageContainerRef["CommonTabStorage_" .. pageName] = self.container
            GuideManager.PageInstRef["CommonTabStorage_" .. pageName] = self
        end

        return self.container
    end

    --[[ 設置 覆寫排版選項 ]]
    function Inst:setScrollViewOverrideOptions (overrideOptions)
        self.scrollViewOverrideOptions = overrideOptions
    end

    --[[ 設置 分頁資訊 ]]
    function Inst:setTabInfos (tabInfos) 
        self.tabInfos = common:deepCopy(tabInfos)
        for idx, val in ipairs(tabInfos) do
            self._tabDatas[idx] = {}
        end
        -- dump(tabInfos, "CommTabStorage : tabInfos")
        self:rebuildTabs()
    end

    --[[ 重置 ]]
    function Inst:clear ()
        self.tabInfos = {}
        self._tabDatas = {}
        self.currencyDatas = {}
        Inst:rebuildTabs()
    end

    --[[ 重新建立 分頁列 ]]
    function Inst:rebuildTabs ()
        local slf = self

        if self.container == nil then return end
        -- print("CommTabStorage : rebuildTabs"..tostring(self.container ~= nil))
        -- dump(self.container, "CommTabStorage.container")

        -- 初始化 分頁圖標 列表
        NodeHelperUZ:initScrollView(self.container, "tabsScrollView", #self.tabInfos)

        -- 預設選項
        local options = {
            paddingLeft = 0,
            scrollViewSize = self._originScrollViewSize,
            isAlignReverse = true,
            isDisableTouchWhenNotFull = true,
        }

        -- 若 有覆寫排版選項 則 覆寫
        if self.scrollViewOverrideOptions ~= nil then
            for key, val in pairs(self.scrollViewOverrideOptions) do
                options[key] = val
            end
        end

        -- 建立 分頁圖標 列表
        NodeHelperUZ:buildScrollViewHorizontal(self.container, #self.tabInfos,
            TabContainer.ccbiFile, 
            function (eventName, itemContainer)
                TabContainer:onFunction(slf, eventName, itemContainer)
            end, 
            options
        )
    end

    --[[ 刷新 分頁紅點 ]]
    function Inst:refreshRedPoint(tabIdx) 
        if tabIdx then
            local tabInfo = self.tabInfos[tabIdx]
            local isRedpointShow = false
            if tabInfo.redpoint ~= nil then
                isRedpointShow = tabInfo.redpoint()
            end
            NodeHelper:setNodesVisible(self._tabDatas[tabIdx].itemContainer, {
                redpoint = isRedpointShow,
            })
        else
            for i = 1, #self._tabDatas do
                local tabInfo = self.tabInfos[i]
                local isRedpointShow = false
                if tabInfo.redpoint ~= nil then
                    isRedpointShow = tabInfo.redpoint()
                end
                NodeHelper:setNodesVisible(self._tabDatas[i].itemContainer, {
                    redpoint = isRedpointShow,
                })
            end
        end
    end

    --[[ 刷新 分頁圖標 ]]
    function Inst:refreshTab(tabIdx, tabInfo_overrite) 
        
        if tabInfo_overrite ~= nil then
            local tabInfo = self.tabInfos[tabIdx]
            if tabInfo ~= nil then
                for key, val in pairs(tabInfo_overrite) do
                    tabInfo[key] = val
                end
            end
            self.tabInfos=tabInfo
        end

        local tabData = self._tabDatas[tabIdx]
        if tabData.itemContainer == nil then return end
        
        TabContainer:onRefreshItemView(self, tabData.itemContainer)
    end
    function Inst:refreshTab2(page,tabIdx, tabInfo_overrite) 
        
        if tabInfo_overrite ~= nil then
            local tabInfo = page.tabStorage.tabInfos[tabIdx]
            if tabInfo ~= nil then
                for key, val in pairs(tabInfo_overrite) do
                    tabInfo[key] = val
                end
            end
            page.tabStorage.tabInfos[tabIdx]=tabInfo
        end

        local tabData = page.tabStorage._tabDatas[tabIdx]
        if tabData.itemContainer == nil then return end
        page._tabDatas=page.tabStorage._tabDatas
        page.tabInfos=page.tabStorage.tabInfos
        TabContainer:onRefreshItemView(page.tabStorage, tabData.itemContainer)
    end

    --[[ 選擇 分頁 ]]
    function Inst:selectTab (tabIdx)
        if tabIdx <= 0 or tabIdx > #self.tabInfos then return end

        local lastIdx = self.lastSelectIdx
        -- print("self.onTabSelect_fn : "..tostring(index).."/"..tostring(lastIdx))

        if lastIdx ~= tabIdx then    

            self.lastSelectIdx = tabIdx

            -- 呼叫 當分頁選中 行為
            local isSelect = self.onTabSelect_fn(tabIdx, lastIdx)

            -- 預設 成功
            if isSelect == nil then isSelect = true end

            -- 若成功選取 則
            if isSelect then
                -- 設置 圖標 選中 狀態
                self:setTabSelected(tabIdx)
            -- 否則 復原
            else    
                self.lastSelectIdx = lastIdx
            end
            
        end
    end

    --[[ 設置 分頁 狀態 ]]
    function Inst:setTabSelected (tabIdx)
        for idx, tabInfo in ipairs(self.tabInfos) do
            local tabData = self._tabDatas[idx]

            if tabInfo.iconType == "image" then
                local img
                if idx == tabIdx then
                    img = tabInfo.icon_selected
                else
                    img = tabInfo.icon_normal
                end
                NodeHelper:setNormalImage(tabData.itemContainer, "btnImg", img)
            else 
                tabData.itemContainer:getVarMenuItemImage("btnImg"):setEnabled(idx ~= tabIdx)
            end
            NodeHelper:setNodesVisible(tabData.itemContainer, { mSelectEffect = (idx == tabIdx) })
        end
    end

    --[[ 設置 標題 ]]
    function Inst:setTitle (titleStr)
        NodeHelper:setStringForLabel(self.container, {
            topTitleText = common:getLanguageString(titleStr)
        })
    end
    
    --[[ 設置 上半部可見 ]]
    function Inst:setTopVisible (isVisible)
         NodeHelper:setNodesVisible(self.container, {
            CommonTop = isVisible
        })
    end

    --[[ 設置 helpBtn可見 ]]
    function Inst:setHelpBtn (isVisible)
         NodeHelper:setNodesVisible(self.container, {
            mHelpNode = isVisible
        })
    end
    
    --[[ 設置 標題 可見 ]]
    function Inst:setTitleVisible (isVisible)
        NodeHelper:setNodesVisible(self.container, {
            titleNode = isVisible
        })
    end
    --[[ 設置 貨幣 資料 ]]
    function Inst:setCurrencyDatas (currencyDatas, isClearLast)
        
        local nodeImage = {}
        local nodeText = {}
        local nodeVisble = {}
        local nodeImageScale = {}

        if isClearLast == true then 
            self.currencyDatas = {}
        end

        -- 準備 設置UI
        -- ui設置上因為考量擴充性，由右至左
        -- 傳入資料因為直覺性，所以由左至右
        -- 在此處做序號反轉
        for idx, currencyData in ipairs(currencyDatas) do
            local revertIdxStr = tostring(CommTabStorage:_getRevertIdx(idx, #currencyDatas))
            
            if currencyData.icon ~= nil then
                nodeImage["currencyImg_"..revertIdxStr] = currencyData.icon
                nodeImageScale["currencyImg_"..revertIdxStr] = currencyData.iconScale
            end

            if currencyData.count ~= nil then
                nodeText["currencyText_"..revertIdxStr] = GameUtil:formatNumber(currencyData.count)
            end

            local exist = self.currencyDatas[idx]
            if exist == nil then
                exist = {}
                self.currencyDatas[idx] = exist
            end

            for key, val in pairs(currencyData) do
                exist[key] = val
            end
        end

        -- 準備 顯示/隱藏
        for idx = 1, CURRENCY_UI_COUNT do
            nodeVisble["currency_"..tostring(idx)] = idx <= #currencyDatas
        end
        --加號 顯示/隱藏
        --if currencyDatas[1] and (currencyDatas[1].id == 7002 or (self.currencyDatas[1].itemInfo and self.currencyDatas[1].itemInfo.itemId == 6005)) then  -- TODO 改讀DataMgr設定
        if self.lastSelectIdx and self.tabInfos[self.lastSelectIdx] then
            if self.tabInfos[self.lastSelectIdx].closePlus then
                nodeVisble["mBtn"] = false
            else
                nodeVisble["mBtn"] = true
            end
        else
            nodeVisble["mBtn"] = true
        end
        
        -- dump(nodeText, "CommonTabStorage nodeText")
        -- dump(nodeImage, "CommonTabStorage nodeImage")
        NodeHelper:setSpriteImage(self.container, nodeImage, nodeImageScale)
        NodeHelper:setNodesVisible(self.container, nodeVisble)
        NodeHelper:setStringForLabel(self.container, nodeText)

    end

    --[[ 鎖住操作 ]]
    function Inst:lockInput(isLock)
        self.isLockedInput = isLock
    end

    function Inst:anim_Default()
        self.container:runAnimation("Default Timeline")
    end

    function Inst:anim_Out()
        self.container:runAnimation("Out")
    end

    function Inst:anim_In()
        self.container:runAnimation("In")
    end

    return Inst
end

--[[ 倒轉序號 (為了使 排版邏輯是從右至左 但 成員取用是從左至右) ]]
function CommTabStorage:_getRevertIdx (idx, count) 
    return (count+1) - idx
end

---------------------------------------------------------------------------------

-- ########    ###    ########       ######   #######  ##    ## ########    ###    #### ##    ## ######## ########  
--    ##      ## ##   ##     ##     ##    ## ##     ## ###   ##    ##      ## ##    ##  ###   ## ##       ##     ## 
--    ##     ##   ##  ##     ##     ##       ##     ## ####  ##    ##     ##   ##   ##  ####  ## ##       ##     ## 
--    ##    ##     ## ########      ##       ##     ## ## ## ##    ##    ##     ##  ##  ## ## ## ######   ########  
--    ##    ######### ##     ##     ##       ##     ## ##  ####    ##    #########  ##  ##  #### ##       ##   ##   
--    ##    ##     ## ##     ##     ##    ## ##     ## ##   ###    ##    ##     ##  ##  ##   ### ##       ##    ##  
--    ##    ##     ## ########       ######   #######  ##    ##    ##    ##     ## #### ##    ## ######## ##     ## 

--[[ 
    分頁 按鈕
--]]

-- 設定
TabContainer = {
    ccbiFile = "CommonTabStorageItem.ccbi"
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
    local infoIdx=#inst.tabInfos
    local tabIdx = CommTabStorage:_getRevertIdx(itemIdx, infoIdx)
    inst:onTabBtn(itemContainer, tabIdx)
end

--[[ 當 刷新視圖 ]]
function TabContainer:onRefreshItemView(inst, itemContainer)
    local itemIdx = tonumber(itemContainer:getItemDate().mID)
    local infoIdx= #inst.tabInfos
    local tabIdx = CommTabStorage:_getRevertIdx(itemIdx,infoIdx)
    
    local tabInfo = inst.tabInfos[tabIdx]
    local tabData = inst._tabDatas[tabIdx]

    -- 設置 圖標容器 至 分頁資料
    tabData.itemContainer = itemContainer

    -- 設置 圖標圖片 
    if tabInfo.iconType == "image" then
        -- 改由 setTabSelected 來設置 (為了正確的選中狀態)
    else
        local img = tabInfo.icon_normal
        NodeHelper:setMenuItemImage(tabData.itemContainer, {
            btnImg = {
                normal = img,
                press = img,
                disabled = nil,
            }
        })
    end


    -- 透過 tabInfo / tabData 進行 其他設置行為 ------------

    -- 設置 圖標紅點
    local isRedpointShow = false
    if tabInfo.redpoint ~= nil then
        isRedpointShow = tabInfo.redpoint()
    end
    NodeHelper:setNodesVisible(itemContainer, {
        redpoint = isRedpointShow,
        mItemNode = not tabInfo.isHide,
    })

    -- 設置 圖標上鎖
    NodeHelper:setNodesVisible(itemContainer, {
        mLock = tabInfo.icon_lock
    })

    -- 設置 圖標名稱
    -- NodeHelper:setStringForLabel(itemContainer, {
    --     btnText = common:getLanguageString(tabInfo._iconName)
    -- })

    local GuideManager = require("Guide.GuideManager")
    if tabInfo.subPageName then
        GuideManager.PageContainerRef["CommonTabItem_" .. tabInfo.subPageName] = itemContainer
        GuideManager.PageInstRef["CommonTabItem_" .. tabInfo.subPageName] = inst
    end
end

---------------------------------------------------------------------------------

return CommTabStorage