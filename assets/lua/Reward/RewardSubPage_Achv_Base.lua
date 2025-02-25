
--[[ 
    name: RewardSubPage_Achv_Base
    desc: 獎勵 子頁面 成就基底
    author: youzi
    update: 2023/7/10 11:18
    description: 
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件
local Quest_pb = require("Quest_pb")

local CommonPage = require('CommonPage')

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")

local RewardDataMgr = require("Reward.RewardDataMgr")

local AchvItem = require("Reward.Achv.AchvItem")

--[[ 測試資料模式 ]]
local IS_MOCK = false


--[[ 本體 ]]
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

--[[ UI檔案 ]]
Inst.ccbiFile = "BPAchievement.ccbi"
--[[ 
    text
    
    var 

    event
    
--]]


--[[ 事件 對應 函式 ]]
Inst.handlerMap = {}

--[[ 協定 ]]
Inst.opcodes = {
    QUEST_GET_ACTIVITY_LIST_S = HP_pb.QUEST_GET_ACTIVITY_LIST_S,
    QUEST_SINGLE_UPDATE_S = HP_pb.QUEST_SINGLE_UPDATE_S,
}

-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 


--[[ 父頁面 ]]
Inst.parentPage = nil

--[[ 容器 ]]
Inst.container = nil

--[[ 滾動容器 大小 ]]
Inst.scrollViewContainerSize = 10

--[[ 當 關閉 行為 ]]
Inst.onceClose_fn = nil

--[[ 子頁面資訊 ]]
Inst.subPageName = ""
Inst.subPageCfg = nil

--[[ 成就資料 ]]
Inst.achvDatas = {}

--[[ 請求冷卻幀數 ]]
Inst.requestCooldownFrame = 180
--[[ 請求冷卻剩餘 ]]
Inst.requestCooldownLeft = Inst.requestCooldownFrame


-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)
    
    if packet.opcode == HP_pb.QUEST_GET_ACTIVITY_LIST_S then
        
        local msg = Quest_pb.HPGetQuestListRet()
        msg:ParseFromString(packet.msgBuff)
        self:handle_QUEST_GET_ACTIVITY_LIST_S(msg)
    
    elseif packet.opcode == HP_pb.QUEST_SINGLE_UPDATE_S then

        local msg = Quest_pb.HPQuestUpdate()
        msg:ParseFromString(packet.msgBuff)
        self:handle_QUEST_SINGLE_UPDATE_S(msg)

    end
end

--[[ 建立 頁面 ]]
function Inst:createPage (parentPage)
    self.parentPage = parentPage
    self.container = ScriptContentBase:create(self.ccbiFile)
    return self.container
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (parentPage)

    local slf = self

    -- 註冊 呼叫行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = slf.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)


    -- 初始化 滾動視圖
    local scrollViewRef = self.container:getVarNode("scrollviewRef")

    local size = scrollViewRef:getContentSize()
    self.container:getVarScrollView("mContent"):setViewSize(size)
    self.container:getVarNode("mContent"):setContentSize(size)
    NodeHelperUZ:initScrollView(self.container, "mContent", self.scrollViewContainerSize)

    -- 註冊 協定
    self.parentPage:registerPacket(self.opcodes)

    -- 取得 子頁面 配置
    self.subPageCfg = RewardDataMgr:getSubPageCfg(self.subPageName)


    -------------------

    -- 請求初始資訊
    self:sendRequestInfo()

end

--[[ 當 頁面 執行 ]]
function Inst:onExecute()

end

--[[ 當 頁面 離開 ]]
function Inst:onExit()
    self.parentPage:removePacket(self.opcodes)
end

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 取得 活動ID ]]
function Inst:getActivityID()
    return self.subPageCfg.activityID
end

--[[ 排序 成就資料 ]]
function Inst:sortAchvDatas ()
    table.sort(self.achvDatas, function(a, b)
        if a.isFinished ~= b.isFinished then
            return not a.isFinished
        else
            return a.sort < b.sort
        end
    end)
end

--[[ 更新 所有項目成員 ]]
function Inst:updateItems ()
    self:clearItems()
    self:buildItems()
end

--[[ 清除 所有項目成員 ]]
function Inst:clearItems()
    NodeHelper:clearScrollView(self.container)
end

--[[ 組建 所有項目成員 ]]
function Inst:buildItems()
    local slf = self

    -- 在container上 以AchvItem為子元素 相關 ui(ccbi) 與 行為 設置 來 建立 滾動視圖ScrollView
    NodeHelperUZ:buildScrollViewVertical(
        self.container, #self.achvDatas,
        function (idx, funcHandler)
            local item = AchvItem:new()
            item.onFunction_fn = funcHandler
            local itemContainer = item:requestUI()
            itemContainer.item = item
            return itemContainer
        end,
        function (eventName, container)
            local contentId = container:getItemDate().mID
            
            if eventName ~= "luaRefreshItemView" then return end
            local achvData = slf.achvDatas[contentId]

            container.item:setProgress(UserInfo.roleInfo.level, achvData.progressMax, achvData.state == Const_pb.REWARD, "%s/%s")
            container.item:setRewards(achvData.rewards)
            container.item:setTitle(common:getLanguageString(achvData.desc, achvData.progressMax))

            -- 當 前往
            container.item.onGoto_fn = function (container)
                slf:onGoto(achvData)
            end

            -- 當 領取
            container.item.onClaim_fn = function (container)
                slf:sendClaim(achvData.id)
            end
        end,
        {
            isBounceable = false,
            interval = 10,
            paddingTop = 10, --magic number
            scrollViewSize = self.container:getVarNode("scrollviewRef"):getContentSize(),
            startOffsetAtItemIdx = 1,
        }
    )
end

--[[ 當 前往 ]]
function Inst:onGoto (achvData)
    print("onGoto : "..tostring(achvData.gotoKey))

    if achvData.gotoKey == "NULL" then return end
    
    -- if achvData.gotoKey == XXXXXXXXXXX then
    -- elseif achvData.gotoKey == XXXXXXXXXXX then
    -- end 
end

--[[ 更新 貨幣 ]]
function Inst:updateCurrency ()
    
    -- 更新 父頁面 貨幣資訊
    local currencyDatas = {}
    for idx, info in ipairs(self.subPageCfg.currencyInfos) do
        currencyDatas[idx] = {
            count = InfoAccesser:getUserItemCountByStr(info.priceStr)
        }
    end
    self.parentPage.tabStorage:setCurrencyDatas(currencyDatas)
end

--[[ 處理 回傳 ]]

function Inst:handle_QUEST_SINGLE_UPDATE_S (msgInfo)
    local quest = msgInfo.quest
    
    for idx, val in ipairs(self.achvDatas) do
        if val.id == quest.id then
            val.state = quest.questState
            val.isFinished = quest.questState == Const_pb.FINISHED or quest.questState == Const_pb.REWARD
        end
    end

    -- 請求獲得道具頁面
    local itemReceivePage = require("CommPop.CommItemReceivePage")
    -- 設置道具
    itemReceivePage:setItemsStr(quest.taskRewards)
    -- 推送顯示
    PageManager.pushPage("CommPop.CommItemReceivePage")

    -- 排序 成就資料
    self:sortAchvDatas()
    -- 更新 列表項目
    self:updateItems()
    self:updateCurrency()
    self:UpdateVIPData()
end

function Inst:handle_QUEST_GET_ACTIVITY_LIST_S (msgInfo)

    local finishedQuestList = msgInfo.finishedQuestList
    local finishedQuest = {}
    for idx = 1, #finishedQuestList do 
        local id = finishedQuestList[idx]
        finishedQuest[id] = true
    end

    self.achvDatas = {}
    
    local questCfgs = ConfigManager.getQuestCfg()
    
    for idx = 1, #msgInfo.questList do while true do
        local quest = msgInfo.questList[idx]
        local questCfg = questCfgs[quest.id]
        if questCfg == nil then
            CCLuaLog(string.format("quest.id[%s] config is not exist", quest.id))
            break -- continue
        end
        
        local achvData = {}

        -- 資訊
        achvData.id = quest.id
        achvData.state = quest.questState
        achvData.isFinished = finishedQuest[quest.id] ~= nil
        -- 描述
        achvData.name = questCfg.name
        achvData.desc = questCfg.content
        -- 排序
        achvData.sort = questCfg.sortId
        -- 進度
        achvData.progress = quest.finishedCount 
        if achvData.progress==0 then achvData.progress=1 end
        achvData.progressMax = questCfg.targetCount
        -- 跳轉
        if questCfg.isJump then
            achvData.gotoKey = questCfg.jumpValue
        end
        -- 獎勵
        achvData.rewards = quest.taskRewards
    
        self.achvDatas[idx] = achvData
    break end end

    -- dump(self.achvDatas, string.format("%s ActivityID[%s] datas", self.subPageCfg.subPageName, self:getActivityID()))

    -- 排序 成就資料
    self:sortAchvDatas()

    -- 更新 成員項目
    self:updateItems()

    -- 更新 玩家持有貨幣資訊
    self:updateCurrency()
end

function Inst:UpdateVIPData()
    local vipInfo = InfoAccesser:getVIPLevelInfo()
    local PathAccesser = require("Util.PathAccesser")
     NodeHelper:setSpriteImage(self.container, {
        mVipBadgeImg = PathAccesser:getVIPIconPath(vipInfo.level)
    })
       -- 設置 進度數字
    NodeHelper:setStringForLabel(self.container, {
        mProgressText = common:getLanguageString("@Reward.LevelAchv.progressText", vipInfo.exp, vipInfo.expMax)
    })

    -- 設置 進度條
    NodeHelperUZ:setProgressBar9Sprite(self.container, "mProgressBar", vipInfo.exp / vipInfo.expMax )
end

--[[ 送出 請求資訊 ]]
function Inst:sendRequestInfo ()
    if IS_MOCK then
        self:onReceivePacket({
            opcode = HP_pb.QUEST_GET_ACTIVITY_LIST_S,
            msg = {
                questList = {
                    { id = 1001001, questState = 1, finishedCount = 11, taskRewards = "10000_1001_1,10000_1002_1",},
                    { id = 1001002, questState = 1, finishedCount = 11, taskRewards = "10000_1001_1,10000_1002_1",},
                    -- { id = 1001001, questState = 1, finishedCount = 11, taskRewards = "10000_1001_1,10000_1002_1",},
                    -- { id = 1001002, questState = 1, finishedCount = 11, taskRewards = "10000_1001_1,10000_1002_1",},
                },
                finishedQuestList = {
                    1001001, -- questID
                },
                leftTime = 52100,
                activityId = 1,
            }
        })
        return
    end
    local msg = Quest_pb.HPGetQuestList()
    local activityId = self:getActivityID()
    if activityId == nil then return end
    msg.activityId = activityId
    common:sendPacket(HP_pb.QUEST_GET_ACTIVITY_LIST_C, msg, true)
end

--[[ 送出 領取 ]]
function Inst:sendClaim (questID)
    local msg = Quest_pb.HPGetSingeQuestReward()
    msg.questId = questID
    common:sendPacket(HP_pb.QUEST_GET_SINGLE_QUEST_REWARD_C, msg, true)
end


return Inst