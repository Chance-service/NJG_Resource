
--[[ 
    name: CommTabStoragePage
    desc: 通用 分頁列 容器 頁面
    author: youzi
    update: 2023/7/11 12:04
    description: 
        具有分頁列的容器父頁面.
        不具特定子頁, 由繼承後的腳本來決定.
        為避免多餘CommonPage使用，子頁面的packet註冊由本頁處理。
--]]


-- 引用 --------------------

local HP_pb = require("HP_pb") -- 包含协议id文件

local InfoAccesser = require("Util.InfoAccesser")
local CommTabStorage = require("CommComp.CommTabStorage")
local SecretPage=require("SecretMessage.SecretMessagePage")
require("Util.LockManager")
----------------------------

--[[ UI檔案 ]]
local CCBI_FILE = "EmptyPage.ccbi"
--[[ 
    text
    
    var 
        underNode 最底層 容器
        contentNode 內容 容器
        topNode 最上層 容器

    event

--]]

--[[ 腳本主體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--  ######  ######## ######## ######## #### ##    ##  ######   
-- ##    ## ##          ##       ##     ##  ###   ## ##    ##  
-- ##       ##          ##       ##     ##  ####  ## ##        
--  ######  ######      ##       ##     ##  ## ## ## ##   #### 
--       ## ##          ##       ##     ##  ##  #### ##    ##  
-- ##    ## ##          ##       ##     ##  ##   ### ##    ##  
--  ######  ########    ##       ##    #### ##    ##  ######   

--[[ 頁面名稱 ]]
Inst.pageName = ""

--[[ 事件 對應 函式 ]]
Inst.handlerMap = {}

--[[ 協定 ]]
Inst.opcodes = {}

--[[ 取得 初始化 子頁面設定檔 ]]
Inst._getInitSubPageCfgs = function() end

-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

--[[ 容器 ]]
Inst.container = nil

--[[ 分頁列 ]]
Inst.tabStorage = nil

--[[ 當前子頁面資料 ]]
Inst.currentSubPageData = nil

--[[ 子頁面資料 ]]
Inst.subPageDatas = {}

--[[ 添加過的協定 ]]
Inst.addedOpcodes = {}

--[[ 當 關閉 行為 ]]
Inst.onceClose_fn = nil

--[[ 分頁列節點(容器) ]]
Inst.tabStorageNode = nil

--[[ 子頁面節點(容器) ]]
Inst.subPageNode = nil

--[[ 進入時的分頁 ]]
Inst.entryTabOnce = 0

--[[ 是否顯示說明扭 ]]
Inst.showHelpBtn = false

--[[ 當 進入 ]]
Inst.onceEntry_fn = function () end

--全域ID
HELP_ActId = 0

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--  ######                                    
--  #     #   ##    ####  #    # ###### ##### 
--  #     #  #  #  #    # #   #  #        #   
--  ######  #    # #      ####   #####    #   
--  #       ###### #      #  #   #        #   
--  #       #    # #    # #   #  #        #   
--  #       #    #  ####  #    # ######   #   
--                                            

--[[ 當 收到訊息 ]]
function Inst:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();

    -- 分發 至 當前子頁面
    if self.currentSubPageData.subPage.onReceiveMessage ~= nil then
        self.currentSubPageData.subPage:onReceiveMessage(message)
    end
    if typeId == MSG_REFRESH_REDPOINT then
        self.tabStorage:refreshRedPoint()
    end
end

--[[ 當 收到封包 ]]
function Inst:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    local packet = {
        opcode = opcode,
        msgBuff = msgBuff,
    }
    -- 分發 至 當前子頁面
    if self.currentSubPageData.subPage.onReceivePacket ~= nil then
        self.currentSubPageData.subPage:onReceivePacket(packet)
    end
end

--[[ 註冊 訊息相關 ]]
function Inst:registerMessage(msgID)
    self.container:registerMessage(msgID)
end

--[[ 註冊 封包相關 ]]
function Inst:registerPacket(opcodes)
    -- dump(opcodes, "register opcodes")

    for key, opcode in pairs(opcodes) do
        
        if string.sub(key, -1) ~= "S" then
            print("WARNING: registerPacket["..key.."] but last character is not \"S\"")
        end
        local addedCount = self.addedOpcodes[opcode]
        if addedCount == nil then
            self.container:registerPacket(opcode)
            -- print("registerPacket:"..tostring(opcode))
            addedCount = 0
        end
        self.addedOpcodes[opcode] = addedCount + 1
    end
end

--[[ 註銷 封包相關 ]]
function Inst:removePacket(opcodes)
    for key, opcode in pairs(opcodes) do
        local addedCount = self.addedOpcodes[opcode]
        if addedCount ~= nil then
            addedCount = addedCount - 1
            if addedCount <= 0 then
                self.container:removePacket(opcode);
            end
            self.addedOpcodes[opcode] = nil
        end
    end
end

--  ######                       
--  #     #   ##    ####  ###### 
--  #     #  #  #  #    # #      
--  ######  #    # #      #####  
--  #       ###### #  ### #      
--  #       #    # #    # #      
--  #       #    #  ####  ###### 
--                               

--[[ 當 頁面 進入 ]]
function Inst:onEnter (container)
    local slf = self

    self.container = container

    self.tabStorageNode = self.container:getVarNode("topNode")
    self.subPageNode = self.container:getVarNode("contentNode")
    
    -- 註冊 封包相關
    self:registerPacket(self.opcodes)

    -- 準備分頁資訊
    local tabInfos = {}
    self.subPageDatas = {}

    local initSubPageCfgs= {}
    local AllSubPage = self._getInitSubPageCfgs()

    for idx,subPageCfg in ipairs (AllSubPage) do
        local cfg=Inst:CfgSync (subPageCfg)
        if cfg ~= nil then
            table.insert (initSubPageCfgs,cfg)
        end
    end

    for idx, subPageCfg in ipairs(initSubPageCfgs) do
        
        local tabInfo = {
            iconType = "default",
            icon_normal = subPageCfg.iconImg_normal,
            icon_selected = subPageCfg.iconImg_selected,
            icon_lock = (subPageCfg.LOCK_KEY and LockManager_getShowLockByPageName(subPageCfg.LOCK_KEY) or false),
            redpoint = subPageCfg.isRedOn and subPageCfg.isRedOn or function() return false end,
            closePlus = subPageCfg._closePlusBtn
        }
        if tabInfo.icon_selected ~= nil then
            tabInfo.iconType = "image"
        end

        tabInfo.isHide = subPageCfg.isHide -- 是否關閉顯示
        tabInfo.subPageName = subPageCfg.subPageName

        table.insert(tabInfos, tabInfo)

        -- print("subPageCfg.type : "..tostring(subPageCfg.type))
        table.insert(self.subPageDatas, {
            scriptPath = subPageCfg.scriptName,
            subPageName = subPageCfg.subPageName,
            title = subPageCfg.title,
            currencyInfos = subPageCfg.currencyInfos,
            TopisVisible=subPageCfg.TopisVisible,
            Help=subPageCfg.Help,
            subPage = nil,
            container = nil,
            LOCK_KEY = subPageCfg.LOCK_KEY
        })

    end

    -- 建立 分頁UI ----------------------------

    -- 初始化
    self.tabStorage = CommTabStorage:new()

    local tabStorageContainer = self.tabStorage:init(tabInfos, self.pageName)

    -- 分頁列間隔
    self.tabStorage:setScrollViewOverrideOptions({
        interval = 20
    })

    -- 設置 當 選中分頁
    self.tabStorage.onTabSelect_fn = function (nextTabIdx, lastTabIdx)
        
        -- print("onTabSelect_fn : "..tostring(nextTabIdx)..", "..tostring(lastTabIdx))
        -- dump(slf.subPageDatas, "slf.subPageDatas")

        -- 目標 子頁面資料
        local nextSubPageData = slf.subPageDatas[nextTabIdx]
        if nextSubPageData == nil then return end

        if nextSubPageData.LOCK_KEY then
            if LockManager_getShowLockByPageName(nextSubPageData.LOCK_KEY) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(nextSubPageData.LOCK_KEY))
                return false
            end
        end
        
        -- 標題
        slf.tabStorage:setTitle(common:getLanguageString(nextSubPageData.title))
        if nextSubPageData.TopisVisible~=nil then
            slf.tabStorage:setTopVisible(nextSubPageData.TopisVisible)
        else
            slf.tabStorage:setTopVisible(true)
        end
        -- 貨幣資料
        local currencyDatas = {}
        for idx, info in ipairs(nextSubPageData.currencyInfos) do
            local itemInfo = InfoAccesser:getItemInfoByStr(info.priceStr)
            local itemIconCfg = InfoAccesser:getItemIconCfg(itemInfo.type, itemInfo.id, "CommTabStorage.currency")
            currencyDatas[#currencyDatas+1] = {
                icon = itemInfo.icon,
                iconScale = itemIconCfg.scale,
                count = InfoAccesser:getUserItemCount(itemInfo.type, itemInfo.id),
                itemInfo = itemInfo,
            }
        end
        slf.currencyDatas = {}
        slf.tabStorage:setCurrencyDatas(currencyDatas, true)
        
        -- 上一個 子頁面資料
        local lastSubPageData = slf.currentSubPageData
        if lastSubPageData ~= nil then

            -- 移除 子頁面
            if lastSubPageData.container ~= nil then
                slf.subPageNode:removeChild(lastSubPageData.container, true)
            end
            
            -- 呼叫 當 離開 子頁面
            lastSubPageData.subPage:onExit(lastSubPageData.container, slf)
        end

        -- 建立 下個 子頁面資料
        -- 若要改以緩存方式，可以從這邊改

        -- 建立 子頁面
        local nextSubPage = require(nextSubPageData.scriptPath):new({
            subPageName = nextSubPageData.subPageName
        })
        nextSubPageData.subPage = nextSubPage

        -- 建立 子頁面UI
        nextSubPageData.container = nextSubPage:createPage(slf)
        if nextSubPageData.container ~= nil then
            slf.subPageNode:addChild(nextSubPageData.container)
        end

        slf.currentSubPageData = nextSubPageData

        -- 呼叫 當 進入 子頁面
        nextSubPage:onEnter(nextSubPageData.container, slf)
    end

    -- 設置 當 關閉
    self.tabStorage.onClose_fn = function ()
        slf:close()
    end

    -- 設置 當 點選貨幣
    self.tabStorage.onCurrencyBtn_fn = function (idx, itemInfo)
        slf:onCurrencyBtn(idx, itemInfo);
    end

    -- 設置 當 點選說明
    self.tabStorage.onHelpBtn_fn = function (idx)
        local data = slf.subPageDatas[idx]
        if string.sub (data.scriptPath,1,6) == "Summon" then
            local actId = data.subPage.subPageCfg.activityID
            local subId = data.subPage.subPageCfg.subId or 0
            if actId == 158 then
                slf:onHelpBtn(data.Help)
                return
            end
            local HelpPage = require "Summon.SummonHelpPage"
            HELP_ActId = actId.."_"..subId
            PageManager.pushPage("SummonHelpPage")
        else
            slf:onHelpBtn(data.Help);
        end
    end

    -- 加入UI
    self.tabStorageNode:addChild(tabStorageContainer)

    -- 預設 選取首個分頁
    if self.entryTabOnce ~= 0 then
        local entryTab = self.entryTabOnce
        self.entryTabOnce = 0
        self:selectSubPage(entryTab)
    else
        self:selectSubPage(1)
    end

    -- 開關說明按鈕
    --if self.showHelpBtn then
    --    NodeHelper:setNodesVisible(tabStorageContainer, { mHelpNode = true })
    --else
    --    NodeHelper:setNodesVisible(tabStorageContainer, { mHelpNode = false })
    --end

    -- 呼叫 當進入
    if self.onceEntry_fn ~= nil then
        local fn = self.onceEntry_fn
        self.onceEntry_fn = nil
        fn(self)
    end
    
    -- 完成 分頁UI ----------------------------
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute (container)
    if self.currentSubPageData ~= nil then
        self.currentSubPageData.subPage:onExecute(self.currentSubPageData.container, self)
    end
end

--[[ 當 頁面 離開 ]]
function Inst:onExit(container)
    if self.currentSubPageData ~= nil then
        require("SecretMessage.SecretMessagePage")
        local state=SecretMessagePage_getState()      

        self.currentSubPageData.subPage:onExit(self.currentSubPageData.container, self)

        local pickUpPage = require "Summon.SummonSubPage_PickUp"
        pickUpPage:ClearCount()

        ----特殊處理
        if self.currentSubPageData.subPageName=="Message"  then     
            if state==GameConfig.SECRET_PAGE_TYPE.CHAT_PAGE then
                return
            end
        end
        ---
    end
    local opcodes = {}
    for opcode, val in pairs(self.addedOpcodes) do
        opcodes[#opcodes+1] = opcode
    end
    self:removePacket(opcodes)

    if self.currentSubPageData ~= nil then
        self.currentSubPageData.subPage:onExit(self.currentSubPageData.container, self)
    end

    self.subPageNode:removeAllChildren()

    self.tabStorage:clear()
    self.tabStorage = nil

    self.currentSubPageData = nil
    self.subPageDatas = {}
    self.addedOpcodes = {}

    self.tabStorageNode = nil
    self.subPageNode = nil

    self.container = nil
    self.entryTabOnce = 0

    self.showHelpBtn = false

    onUnload(self.pageName, container)
end



-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  


--[[ 關閉 ]]
function Inst:close ()
    
    -- 關閉 頁面
    if self.pageName=="SecretMessage.SecretPage" then
        require("SecretMessage.SecretMessagePage")
        local state=SecretMessagePage_getState()   
        self.currentSubPageData.subPage:onExit(self.currentSubPageData.container, self)
        if state==GameConfig.SECRET_PAGE_TYPE.CHAT_PAGE then
            return
        else
             PageManager.popPage(self.pageName)
        end
    elseif self.pageName == "GloryHole.GloryHolePage" then
        local GloryHole = require ("GloryHole.GloryHoleSubPage_MainScene")
        GloryHole:onClose()
    end
    if self.currentSubPageData and self.currentSubPageData.container then
        self.currentSubPageData.container:unregisterFunctionHandler()
    end
    PageManager.popPage(self.pageName)

    -- 若 有關閉行為 則 呼叫
    if self.onceClose_fn then
        self.onceClose_fn()
        self.onceClose_fn = nil
    end

end

--[[ 更新 貨幣 ]]
function Inst:updateCurrency ()
    
    -- 依照 當前 子頁面資料(由初始化設定設置) 更新 貨幣資訊
    local currencyDatas = {}
    for idx, info in ipairs(self.currentSubPageData.currencyInfos) do
        currencyDatas[idx] = {
            count = InfoAccesser:getUserItemCountByStr(info.priceStr)
        }
    end

    self.tabStorage:setCurrencyDatas(currencyDatas)

    return currencyDatas
end

--[[ 當點選貨幣 ]]
function Inst:onCurrencyBtn (idx, itemInfo)
    -- 鑽石
    if itemInfo.type == 1 and itemInfo.id == 1001 then
        -- 準備開啟頁面後的行為
        require("IAP.IAPPage"):setEntrySubPage("Diamond")
        -- 開啟頁面
        PageManager.pushPage("IAP.IAPPage")

    -- 金幣
    elseif itemInfo.type == 1 and itemInfo.id == 1002 then
        -- 開啟頁面
        --PageManager.pushPage("MoneyCollectionPage")
    
    -- 友情點數
    elseif itemInfo.type == 1 and itemInfo.id == 1025 then
        -- 開啟頁面
        PageManager.pushPage("FriendPage")

    -- 種族召喚券
    elseif itemInfo.type == 3 and itemInfo.id == 6003 then
        if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.DAILY_BUNDLE) then
            MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.DAILY_BUNDLE))
        else
            -- 準備開啟頁面後的行為
            require("IAP.IAPPage"):setEntrySubPage("Recharge")
            -- 開啟頁面
            PageManager.pushPage("IAP.IAPPage")
        end
    -- 英雄召喚券
    elseif itemInfo.type == 3 and itemInfo.id == 6004 then
        if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.DAILY_BUNDLE) then
            MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.DAILY_BUNDLE))
        else
            -- 準備開啟頁面後的行為
            local IAPPage = require("IAP.IAPPage")
            IAPPage:setEntrySubPage("Recharge")
            IAPPage:setOnceEntry(function()
                -- TODO : 切換到 Recharge分頁的Week分頁
                -- IAPPage.currentSubPageData.subPage:onWeek()
            end)
            -- 開啟頁面
            PageManager.pushPage("IAP.IAPPage")
        end
    -- 勇者凭证
    elseif itemInfo.type == 3 and itemInfo.id == 6009 then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(50)
    -- 待新增

    -- elseif itemInfo.type == 1 and itemInfo.id == 1002 then
    
    
    end

end

--[[ 當點選說明 ]]
function Inst:onHelpBtn (key)
    local file=GameConfig.HelpKey[key]
    PageManager.showHelp(file)
end

--[[ 設置 進入頁面(單次) ]]
function Inst:setEntrySubPage(subPageNameOrIdx)
    self.entryTabOnce = subPageNameOrIdx
end

--[[ 設置 當進入 ]]
function Inst:setOnceEntry(onceEntry_fn)
    self.onceEntry_fn = onceEntry_fn
end

--[[ 選取子頁面 ]]
function Inst:selectSubPage (subPageNameOrIdx)
    local typ = type(subPageNameOrIdx)
    if typ == "number" then
        self.tabStorage:selectTab(subPageNameOrIdx)
    elseif typ == "string" then
        for idx = 1, #self.subPageDatas do
            if self.subPageDatas[idx].subPageName == subPageNameOrIdx then
                self.tabStorage:selectTab(idx)
            end
        end
    end
end

--[[ 產生 通用頁面 ]]
function Inst:generateCommPage(pageName, handlerMap, opcodes, initSubPageCfgs_or_func)
    local CommonPage = require('CommonPage')

    local newOne = self:new()

    newOne.pageName = pageName

    local initSubPageCfgsType = type(initSubPageCfgs_or_func)
    if initSubPageCfgsType == "table" then
        newOne._getInitSubPageCfgs = function()
            return initSubPageCfgs_or_func
        end
    elseif initSubPageCfgsType == "function" then
        newOne._getInitSubPageCfgs = initSubPageCfgs_or_func
    else 
        return
    end

    if handlerMap ~= nil then
        newOne.handlerMap = handlerMap
    end

    if opcodes ~= nil then
        newOne.opcodes = opcodes
    end

    return CommonPage.newSub(newOne, newOne.pageName, {
        ccbiFile = CCBI_FILE,
        handlerMap = newOne.handlerMap,
        opcode = newOne.opcodes,
    })
end

--[[ 設置 是否顯示說明按鈕(單次) ]]
function Inst:setShowHelpBtn(show)
    self.showHelpBtn = show
end

function Inst:CfgSync (cfg)
    if cfg.isClose then
        return nil
    end
    if not cfg.activityID and not cfg.SummonReward then
        return cfg
    end
    local id = cfg.activityID
    if id==167 then
        local FreeSummonPage=require("Reward.RewardSubPage_FreeSummon")
        if FreeSummonPage:AllSigned() then
            return nil
        end
    elseif id==175 then
        local GloryHoleDataBase = require("GloryHole.GloryHolePageData")
        local TeamId = GloryHoleDataBase:getData().teamId
        if TeamId==0 then return nil end
    elseif id == 179 then
        local StepBundle =  require ("IAP.IAPSubPage_StepBundle")
        if StepBundle:isBuyAll() then return nil end
    elseif id == 180 then
        local FreeSummonPage2=require("Reward.RewardSubPage_FreeSummon2")
        if FreeSummonPage2:AllSigned() then
            return nil
        end
    end
    local SummonRewardId = cfg.SummonReward
   if SummonRewardId == 1901 then
        local CostSummon1=require("Reward.RewardSubPage_CostSummon1")
        if CostSummon1:AllSigned() then
            return nil
        end
    elseif SummonRewardId == 1902 then
        local CostSummon2=require("Reward.RewardSubPage_CostSummon2")
        if CostSummon2:AllSigned() then
            return nil
        end
    elseif SummonRewardId == 1903 then
         local CostSummon3=require("Reward.RewardSubPage_CostSummon3")
         if CostSummon3:AllSigned() then
            return nil
        end
    end
    return cfg
end

return Inst