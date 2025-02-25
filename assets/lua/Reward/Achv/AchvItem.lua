
local CommItem = require("CommUnit.CommItem")
local InfoAccesser = require("Util.InfoAccesser")
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")

--[[ 本體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


--[[ UI檔案 ]]
Inst.CCBI_FILE = "AchievementItem.ccbi"

--[[ 事件 對應 函式 ]]
Inst.HANDLER_MAP = {
    onClaimBtnClick = "onClaimBtn",
    onGotoBtnClick = "onGotoBtn",
}

--[[ UI ]]
Inst.container = nil

--[[ 進度是否達成 ]]
Inst.isFinished = false

--[[ 獎勵 節點容器 ]]
Inst.rewardNodes = {}
Inst.rewardCommItems = {}

--[[ 當 前往 ]]
Inst.onGoto_fn = nil

--[[ 當 領取 ]]
Inst.onClaim_fn = function (container) end

--[[ 當 額外呼叫 ]]
Inst.onFunction_fn = nil

--[[ 當 領取按鈕 按下 ]]
function Inst:onClaimBtn(container)
    if self.isFinished then
        self.onClaim_fn(container)
    end
end

--[[ 當 前往按鈕 按下 ]]
function Inst:onGotoBtn(container)
    if self.onGoto_fn ~= nil then
        self.onGoto_fn(container)
    end
end


--[[ 請求 UI ]]
function Inst:requestUI()
    if self.container ~= nil then
        return self.container
    end

    local slf = self

    self.container = ScriptContentBase:create(self.CCBI_FILE)

    -- 註冊 呼叫 行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = slf.HANDLER_MAP[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end

        -- 額外呼叫
        if slf.onFunction_fn ~= nil then
            slf.onFunction_fn(eventName, container)
        end
    end)

    -- 初始化 table成員 (避免錯誤繼承)
    self.rewardCommItems = {}
    self.rewardNodes = {}

    -- 取得 獎勵節點容器
    for idx = 1, 4 do
        self.rewardNodes[idx] = self.container:getVarNode("mRewardItemNode"..tostring(idx))
    end

    return self.container
end

--[[ 設置 標題 ]]
function Inst:setTitle(str)
    NodeHelper:setStringForTTFLabel(self.container, {
        mMessageLabel = str
    })
end

--[[ 設置 獎勵 ]]
function Inst:setRewards(rewardsStr)
    -- 分割 獎勵列表字串
    local rewardStrs = common:split(rewardsStr, ",")

    -- 取 最少數量
    local min = #self.rewardNodes
    if #rewardStrs < min then min = #rewardStrs end

    -- 在 最少數量內
    for idx = 1, min do
        
        -- 每個獎勵字串
        local rewardStr = rewardStrs[idx]
        -- 獎勵UI節點
        local rewardNode = self.rewardNodes[idx]

        -- 獎勵UI節點 啟用
        rewardNode:setVisible(true)

        -- 獎勵 通用道具UI
        local rewardCommItem = self.rewardCommItems[idx]
        -- 若 不存在 則 建立
        if rewardCommItem == nil then
            
            rewardCommItem = CommItem:new()
            self.rewardCommItems[idx] = rewardCommItem
            
            local commItemUI = rewardCommItem:requestUI()
            -- commItemUI:setScale(CommItem.Scales.large)
            commItemUI:setAnchorPoint(ccp(0.5, 0.5))
            commItemUI:setPosition(ccp(0, 0))
            rewardNode:addChild(commItemUI)

            rewardCommItem.onClick_fn = function()
                local itemInfo = InfoAccesser:getItemInfoByStr(rewardStr)
                GameUtil:showTip(
                    commItemUI,
                    {
                        type = itemInfo.mainType,
                        itemId = itemInfo.itemId,
                    }
                )
            end

        end
        
        rewardCommItem:autoSetByItemStr(rewardStr)
        
    end

    -- 關閉 沒有用到的 獎勵UI節點
    for idx = min+1, #self.rewardNodes do
        local rewardNode = self.rewardNodes[idx]
        rewardNode:setVisible(false)
    end
end

--[[ 設置 進度相關 ]]
function Inst:setProgress(progress, progressMax, isClaimed, descStr)

    -- 是否達成
    local isFinished = progress >= progressMax
    -- 是否顯示 前往 (未完成 且 有前往方法)
    local isShowGoto = not isFinished and self.onGoto_fn ~= nil

    -- 顯示/隱藏
    NodeHelper:setNodesVisible(self.container, {
        mGotoBtnNode = isShowGoto,
        mClaimBtnNode = isFinished or (not isShowGoto),
    })
    
    -- 灰階/解除 領取按鈕
    local claimBtnNode = self.container:getVarNode("mClaimBtnNode")
    -- 若 未完成 或 已領取 則 灰階
    NodeHelperUZ:setNodeIsGrayRecursive(claimBtnNode, not isFinished or isClaimed)

    -- 若 已完成 且 未領取 則 可用
    NodeHelper:setMenuEnabled(self.container:getVarMenuItem("mClaimBtn"), isFinished and not isClaimed)

    -- 設置 進度描述
    NodeHelper:setStringForTTFLabel(self.container, {
        mProgressDescText = string.format(common:getLanguageString(descStr), progress, progressMax),
    })
    
    -- 設置 領取按鈕文字
    local btnText
    -- 已領取 : 已領取
    if isClaimed then
        btnText = "@ActDailyMissionBtn_Finish"
    -- 未領取 已達成 : 領取 
    elseif isFinished then
        btnText = "@Receive"
    -- 未領取 未達成 : 進行中
    else 
        btnText = "@inProgress"
    end
    NodeHelper:setStringForLabel(self.container, {
        mClaimBtnLabel = common:getLanguageString(btnText),
    })

    self.isFinished = isFinished
end


return Inst