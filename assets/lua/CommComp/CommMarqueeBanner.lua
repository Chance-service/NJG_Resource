----------------------------------------------------------------------------------
--[[
    name: 跑馬燈橫幅 元件
    desc: 
    author: youzi
    description:
        
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
local NodeHelperUZ = require("Util.NodeHelperUZ")
local ObjPool = require("Util.ObjPool")
local Invoker = require("Util.Invoker")
local GameTime = require("Util.GameTime")

local CommMarqueeBanner = {}

-- 頁面設定
local CCBI_FILE = "CommMarqueeBanner.ccbi"

-- 對照 UI指定方法 : 函式名稱
local HANDLER_MAP = {}

local BANNER_TAB_IMAGE_SELECTED = "Lobby_Page_A1.png"
local BANNER_TAB_IMAGE_UNSELECTED = "Lobby_Page_A0.png"
local BANNER_TAB_SPACING = 15

local INPUTBLOCK_ACTIVE = false

function CommMarqueeBanner:new ()
    local Inst = {}

    -- 是否已經初始化
    Inst._isInited = false

    -- 主容器
    Inst.container = nil

    -- 橫幅容器
    Inst.bannersNode = nil

    -- 項目腳本
    Inst.contentScript = nil

    -- 當前顯示位置
    Inst.curShowPos = 0

    -- 當前目標位置
    Inst.curGotoPos = 0

    -- 當前橫幅序號
    Inst.curBannerIdx = 0

    -- 當前長度
    Inst.length = 0
    
    -- 移動至目標的每秒百分比
    Inst.movePercentPerSec = 5

    -- 自動輪播時間
    Inst.autoNextTime = 4+0.5
    Inst._leftToNextTime = -1

    Inst.isTouching = false
    Inst.startTouchShowPos = nil

    -- 可視的橫幅數量
    Inst.displayBannerCount = 4

    -- 物件池大小
    Inst.objPoolSize = 4

    -- 橫幅資料
    Inst.bannerDatas = {}

    Inst.bannerTabs = {}
    Inst.bannerTabs_select = nil

    -- 橫幅UI
    Inst.bannerUIs = {}

    -- 橫幅物件池水
    Inst.bannerPool = nil


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

    --[[ 當 點選 ]]
    function Inst:onClick (container)
        
    end 

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 初始化 ]]
    function Inst:init (data) 
        if self._isInited then return self end
        
        if data == nil then data = {} end

        local slf = self

        -- 項目腳本
        if data.contentScript ~= nil then
            if type(data.contentScript) == "string" then
                self.contentScript = require(data.contentScript)
            else
                self.contentScript = data.contentScript
            end
        end

        if data.objPoolSize ~= nil then 
            self.objPoolSize = data.objPoolSize
        end

        if data.displayCount ~= nil then 
            self.displayBannerCount = data.displayCount
        end
        
        self:resetAutoNextTime()

        self.container = ScriptContentBase:create(CCBI_FILE)
        self.bannersNode = self.container:getVarNode("bannersNode")

        NodeHelper:setNodesVisible(self.container, {
           inputBlock = INPUTBLOCK_ACTIVE
        })

        -- 註冊 呼叫 行為
        self.container:registerFunctionHandler(function (eventName, container)
            local funcName = HANDLER_MAP[eventName]
            local func = self[funcName]
            if func then
                func(self, container)
            end
        end)

        -- 建立 物件池
        self.bannerPool = ObjPool:new():init({
            count = self.objPoolSize,
            onCreate = function (optData)
                
                local bannerContent = self.contentScript:new():init()
                local contentContainer = bannerContent:getContainer()
                self.bannersNode:addChild(contentContainer)
                contentContainer:setVisible(false)

                return {
                    script = bannerContent,
                    container = contentContainer,
                }
            end, 
            onInit = function (obj, data)
                obj.idx = data.idx
                obj.container:setVisible(true)
                obj.script:setData(data)
            end, 
            onUnInit = function (obj)
                obj.idx = nil
                obj.container:setVisible(false)
                obj.script:setData(nil)
            end, 
            onDestroy = function (obj)
                obj.container:getParent():removeChild(obj.container, true)
            end, 
        })


        -- 初始化 觸碰偵測相關
        local touchDownPos = nil
        local touchDownStartTime = nil
        local testLayer = tolua.cast(self.container:getVarNode("touchLayer"), "CCLayer")
        NodeHelperUZ:registerLayerTouchHandler(testLayer, {
            -- 當按下
            onTouchDown = function (evtData)
                slf.isTouching = true

                touchDownPos = evtData.locationInRect
                touchDownStartTime = GameTime:time()
                
                slf.startTouchShowPos = slf.curShowPos

            end,
            -- 當按下後彈起
            onTouchUp = function (evtData)
                slf.isTouching = false

                if touchDownPos == nil then return end
                
                local touchUpPos = evtData.locationInRect

                local touchTime = GameTime:time() - touchDownStartTime
                local dragDistanceX = touchUpPos.x - touchDownPos.x
                
                touchDownStartTime = nil
                touchDownPos = nil
                slf.startTouchShowPos = nil

                -- print(string.format("touchTime[%s] dragDis[%s]", tostring(touchTime), tostring(dragDistanceX)))
                if touchTime < 0.5 and math.abs(dragDistanceX) < 50 then
                   slf:enterBanner()
                else
                    slf:resetAutoNextTime()
                    if dragDistanceX < 0 then
                        slf:nextBanner()
                    elseif dragDistanceX > 0 then
                        slf:previousBanner()
                    end
                end

            end,
            onTouchMove = function (evtData)

            end,
            isNeedInRect = true,
            isLog = false,
            isSwallowTouches = false,
        })
        testLayer:setTouchEnabled(true)

        self.task = Invoker:update(function (dt)
            slf:onExecute(dt)
        end)


        -- 設 已初始化
        self._isInited = true

        if data.bannerInfos ~= nil then
            self:setBannerInfos(data.bannerInfos)
        end

        if data.length ~= nil then
            self.length = data.length
        end

        return self
    end

    --[[ 每幀 ]]
    function Inst:onExecute (dt)

        if not self.isTouching then

            if self.autoNextTime ~= -1 then
                self._leftToNextTime = self._leftToNextTime - dt
                if self._leftToNextTime < 0 then
                    self:resetAutoNextTime()
                    self:nextBanner()
                end
            end
        end

        -- 推進當前顯示位置
        local nextPos = self.curShowPos + ((self.curGotoPos - self.curShowPos) * self.movePercentPerSec * dt)

        if math.abs(self.curGotoPos - nextPos) < 1 then
            nextPos = self.curGotoPos
        end

        self.curShowPos = nextPos
       

        local tryTimesEachSide = math.floor(self.displayBannerCount / #self.bannerDatas) + 1
        if tryTimesEachSide < 1 then tryTimesEachSide = 1 end

        local curIdxPos = self.curShowPos

        -- 依照當前顯示位置 更新橫幅資料

        -- 將 每個資料 以 正向與反向 兩種顯示參考資料 填入 排序列表中
        local sortedShowRefList = {}
        local sortedShowRefList_idx = 1
        for rawIdx = 1, #self.bannerDatas do
            -- print(rawIdx)
            local data = self.bannerDatas[rawIdx]

            -- 軸內顯示資料
            local relPos = data.pos - curIdxPos
            local dis = math.abs(relPos)
            local show = {dis, relPos, rawIdx}
            sortedShowRefList[sortedShowRefList_idx] = show
            sortedShowRefList_idx = sortedShowRefList_idx + 1
            -- dump(show, "show")

            -- 正循環 與 負循環 N次 的顯示資料
            for tryTime = 1, tryTimesEachSide do
                local offset = self.length * tryTime

                local relPos_postive = relPos + offset
                local dis_postive = math.abs(relPos_postive)
                local show_postive = {dis_postive, relPos_postive, rawIdx}
                sortedShowRefList[sortedShowRefList_idx] = show_postive
                sortedShowRefList_idx = sortedShowRefList_idx + 1
                -- dump(show_postive, "show_pos")
    
                local relPos_negative = relPos - offset
                local dis_negative = math.abs(relPos_negative)
                local show_negative = {dis_negative, relPos_negative, rawIdx}
                sortedShowRefList[sortedShowRefList_idx] = show_negative
                sortedShowRefList_idx = sortedShowRefList_idx + 1
                -- dump(show_negative, "show_neg")
            end

        end
        -- 以 靠近距離 排序
        table.sort(sortedShowRefList, function(a, b)
            return a[1] < b[1]
        end)

        -- 建立 顯示資料
        local idx2ToShows = {}
        -- 由 近到遠
        for idx = 1, #sortedShowRefList do
            local val = sortedShowRefList[idx]
            local relPos = val[2]
            local rawIdx = val[3]
            local bannerData = self.bannerDatas[rawIdx]

            -- 若 超出可顯示數量 則 跳出
            if idx > self.displayBannerCount then break end
            
            -- 該 橫幅序號 的 顯示資料列表 (若無則建立)
            local toShows = idx2ToShows[rawIdx]
            if toShows == nil then toShows = {} end

            -- 加入 顯示資料列表
            toShows[#toShows+1] = {relPos, bannerData}

            idx2ToShows[rawIdx] = toShows
        end
        -- 統計 各個橫幅序號 要顯示的資料數量
        local idx2ToShowCount = {}
        for key, val in pairs(idx2ToShows) do
            idx2ToShowCount[key] = #val
        end
        
        -- 已存在UI的序號
        local idx2ExistUIs = {}
        
        -- 回收每個沒有用到的UI

        -- 每個 現有的橫幅UI
        local toRec = {}
        for idx = 1, #self.bannerUIs do
            local eachUI = self.bannerUIs[idx]
            
            -- 若 尚有需要顯示的數量
            local toShowCount = idx2ToShowCount[eachUI.idx]
            if toShowCount ~= nil and toShowCount > 0 then

                -- 扣除現有UI用量
                toShowCount = toShowCount - 1
                idx2ToShowCount[eachUI.idx] = toShowCount

                -- 加入現有UI
                local existUIs = idx2ExistUIs[eachUI.idx]
                if existUIs == nil then existUIs = {} end
                existUIs[#existUIs+1] = eachUI

                idx2ExistUIs[eachUI.idx] = existUIs

            -- 若 不再需要 則 回收
            else
                toRec[#toRec+1] = idx
            end
        end
        for idx = #toRec, 1, -1 do
            local toRecIdx = toRec[idx]
            local toRecUI = self.bannerUIs[toRecIdx]
            table.remove(self.bannerUIs, toRecIdx)
            self.bannerPool:recovery(toRecUI)
        end

        -- 建立UI給需要顯示的資料
        for rawIdx, toShows in pairs(idx2ToShows) do
            
            local existUIs = idx2ExistUIs[rawIdx]

            -- 每個 該橫幅序號 要顯示的資料
            for idx = 1, #toShows do
                local toShow = toShows[idx]
                local toShowPos = toShow[1]
                local toShowData = toShow[2]
                
                local uiObj
                -- 若 現有UI沒了 則 建立
                if existUIs == nil or #existUIs == 0 then
                    uiObj = self.bannerPool:reuse(toShowData)
                    self.bannerUIs[#self.bannerUIs+1] = uiObj
                -- 否則 取用
                else
                    uiObj = existUIs[#existUIs]
                    existUIs[#existUIs] = nil
                end

                uiObj.container:setPositionX(toShowPos)
            end
        end

        -- 個別UI的每幀更新
        for idx = 1, #self.bannerUIs do
            local each = self.bannerUIs[idx]
            each.script:execute(dt)
        end
    end


    --[[ 進入 橫幅 ]]
    function Inst:enterBanner ()
        print("enterBanner : "..tostring(self.curBannerIdx))
        local bannerData = self.bannerDatas[self.curBannerIdx]
        if bannerData.onEnter ~= nil then 
            bannerData.onEnter(bannerData.PageName)
        end
    end


    --[[ 上一個 橫幅]]
    function Inst:previousBanner ()
        if #self.bannerDatas == 0 then return end
        
        local bannerIdx = self.curBannerIdx - 1
        if bannerIdx < 1 then bannerIdx = #self.bannerDatas end
        
        self:selectBanner(bannerIdx)

        if self.curGotoPos > self.curShowPos then
            self.curShowPos = self.curShowPos + self.length
        end
        -- print(string.format("previousBanner : %s : %s", tostring(bannerIdx), tostring(self.curShowPos)))
        -- print("goto:"..tostring(self.curGotoPos))
    end


    --[[ 下一個 橫幅]]
    function Inst:nextBanner ()
        if #self.bannerDatas == 0 then return end

        local bannerIdx = self.curBannerIdx + 1
        if bannerIdx > #self.bannerDatas then bannerIdx = 1 end
        
        self:selectBanner(bannerIdx)
        
        if self.curGotoPos < self.curShowPos then
            self.curShowPos = self.curShowPos - self.length
        end
        -- print(string.format("nextBanner : %s : %s", tostring(bannerIdx), tostring(self.curShowPos)))
        -- print("goto:"..tostring(self.curGotoPos))
    end

    --[[ 選取橫幅 ]]
    function Inst:selectBanner (idx)        
        local bannerData = self.bannerDatas[idx]
        self.curBannerIdx = idx
        self.curGotoPos = bannerData.pos

        self:_updateTabs()
    end


    --[[ 設置 分頁資訊 ]]
    function Inst:setBannerInfos (bannerInfos, totalLength) 
        self.length = totalLength
        self.bannerDatas = {}
        for idx, info in ipairs(bannerInfos) do
            local data = {
                idx = idx,
                pos = info.pos,
                counter = info.counter,
                onEnter = info.onEnter,
                bg = info.bg,
                PageName = info.PageName or nil
            }
            self.bannerDatas[idx] = data
        end

        local tabsNode = self.container:getVarNode("tabsNode")
        
        for idx = #self.bannerTabs, #self.bannerDatas+1, -1 do
            local eachRm = table.remove(self.bannerTabs, idx)
            tabsNode:removeChild(eachRm, true)
        end

        if self.bannerTabs_select == nil then
            self.bannerTabs_select = CCSprite:create(BANNER_TAB_IMAGE_SELECTED)
            self.bannerTabs_select:setScale(0.6)
            tabsNode:addChild(self.bannerTabs_select)
        end

        for idx = #self.bannerTabs+1, #self.bannerDatas do
            local tab = CCSprite:create(BANNER_TAB_IMAGE_UNSELECTED)
            tabsNode:addChild(tab)
            tab:setScale(0.6)
            self.bannerTabs[idx] = tab
        end
        
        for idx = 1, #self.bannerTabs do
            local each = self.bannerTabs[idx]
            local PosX= BANNER_TAB_SPACING * #self.bannerTabs * (idx-1)/(#self.bannerTabs-1)
            each:setPositionX(PosX)
        end

        local containerWidth = BANNER_TAB_SPACING * #self.bannerTabs
        tabsNode:setContentSize(CCSizeMake(containerWidth, tabsNode:getContentSize().height))
        tabsNode:setPosition(ccp(340,10))
        local bannerCount = #self.bannerDatas
        if bannerCount > 0 then
            if self.curBannerIdx < 1 or bannerCount < self.curBannerIdx  then
                self:selectBanner(1)
            end
        end

    end

    --[[ 重置 ]]
    function Inst:clear ()
        if self.task then
            Invoker:cancel(self.task, false)
        end
    end

    --[[ 重置 ]]
    function Inst:resetAutoNextTime ()
        self._leftToNextTime = self.autoNextTime
    end

    function Inst:_updateTabs ()
        for idx = 1, #self.bannerTabs do
            local each = self.bannerTabs[idx]
            if idx == self.curBannerIdx then
                each:setVisible(false)
                self.bannerTabs_select:setPosition(ccp(each:getPositionX(), each:getPositionY()))
            else
                each:setVisible(true)
                each:setScale(0.6)
            end
        end
    end

    return Inst
end


---------------------------------------------------------------------------------





return CommMarqueeBanner