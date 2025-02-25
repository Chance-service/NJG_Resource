--[[ 
    name: RewardSubPage_Achv_Level
    desc: 獎勵 子頁面 成就 等級
    author: youzi
    update: 2023/7/11 17:21
    description:
         
--]]

-- 引用 ------------------

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local PathAccesser = require("Util.PathAccesser")
local InfoAccesser = require("Util.InfoAccesser")

--------------------------

--[[ 本體 ]]
local Inst = require("Reward.RewardSubPage_Achv_Base"):new()
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


--[[ 子頁面資訊 ]]
Inst.subPageName = "LevelAchv"

--[[ 事件 對應 函式 ]]
Inst.handlerMap["onHelp"] = "onHelp"

--[[ UI檔案 ]]
Inst.ccbiFile = "LevelAchievement.ccbi"

--[[ 活動ID ]]
Inst.activityID = 155

--[[ 處理 回傳 ]]
Inst._Base_handle_QUEST_GET_ACTIVITY_LIST_S = Inst.handle_QUEST_GET_ACTIVITY_LIST_S
function Inst:handle_QUEST_GET_ACTIVITY_LIST_S (msgInfo)

    local vipInfo = InfoAccesser:getVIPLevelInfo()
    self:setVipLevel(vipInfo)
    
    -- 進度
    self:setProgress(vipInfo.exp, vipInfo.expMax)

    -- 呼叫父類
    self._Base_handle_QUEST_GET_ACTIVITY_LIST_S(self, msgInfo)
end

function Inst:onHelp (container)
    self.parentPage:close()
    PageManager.pushPage("Recharge.RechargeVIPPage")
end


-- 設置 VIP等級
function Inst:setVipLevel(vipInfo)
    NodeHelper:setSpriteImage(self.container, {
        mVipBadgeImg = PathAccesser:getVIPIconPath(vipInfo.level)
    })
end

--[[ 設置 進度 ]]
function Inst:setProgress (progress, progress_max)

    -- 設置 進度數字
    NodeHelper:setStringForLabel(self.container, {
        mProgressText = common:getLanguageString("@Reward.LevelAchv.progressText", progress, progress_max)
    })

    -- 設置 進度條
    NodeHelperUZ:setProgressBar9Sprite(self.container, "mProgressBar", progress / progress_max )
end

return Inst