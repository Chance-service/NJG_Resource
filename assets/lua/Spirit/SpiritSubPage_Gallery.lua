
--[[ 
    name: SpiritSubPage_Gallery
    desc: 精靈 子頁面 圖鑑
    author: youzi
    update: 2023/8/14 12:43
    description: 
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")

local SpiritDataMgr = require("Spirit.SpiritDataMgr")

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ UI檔案 ]]
local CCBI_FILE = "SpiritGallery.ccbi"

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
}

--[[ 協定 ]]
local OPCODES = {
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
}


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
        
    event
    
--]]



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

--[[ 當 關閉 行為 ]]
Inst.onceClose_fn = nil

--[[ 子頁面資訊 ]]
Inst.subPageName = "Gallery"
Inst.subPageCfg = nil

Inst.colCount = 4

Inst.spiritCfgs = {}

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)
    -- 更新 角色(精靈)資訊
    if packet.opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(packet.msgBuff)
        SpiritDataMgr:updateUserSpiritStatusInfosByRoleInfos(msg.roleInfos)
        self:refreshPage()
    end
end

--[[ 建立 頁面 ]]
function Inst:createPage (parentPage)
    self.parentPage = parentPage
    self.container = ScriptContentBase:create(CCBI_FILE)
    return self.container
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (selfContainer, parentPage)
    local slf = self

    -- 註冊 呼叫行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = HANDLER_MAP[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)

    -- 背景適應
    NodeHelperUZ:fitBGNode(self.container:getVarNode("bgImg"), {
        pivot = ccp(0.5, 0),
        anchorPoint = ccp(0.5, 0),
        ratioSizeFix = CCSizeMake(0, 140),
    })

    self.spiritCfgs = SpiritDataMgr:getSpiritCfgs()

    -- 初始化 列表
    NodeHelper:initScrollView(self.container, "mScrollView", #self.spiritCfgs);

    -- 註冊 協定
    self.parentPage:registerPacket(OPCODES)

    -- 取得 子頁面 配置
    self.subPageCfg = SpiritDataMgr:getSubPageCfg(self.subPageName)

    -------------------

    -- 請求初始 同步資訊
    self:sendRequest_sync()

end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(selfContainer, parentPage)

end

--[[ 當 頁面 離開 ]]
function Inst:onExit(selfContainer, parentPage)
    self.parentPage:removePacket(OPCODES)
end


-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 刷新頁面 ]]
function Inst:refreshPage ()

    local slf = self

    local spiritCfgs = SpiritDataMgr:getSpiritCfgs()
    self.spiritCfgs = {}
    for idx = 1, #spiritCfgs do
        self.spiritCfgs[idx] = spiritCfgs[idx]
    end

    -- Test
    -- for ii = 1, 2 do
    --     for idx = 1, #spiritCfgs do
    --         self.spiritCfgs[#self.spiritCfgs+1] = spiritCfgs[idx]
    --     end
    -- end

    -- 依照 稀有度Job 與 ID 排序
    table.sort(self.spiritCfgs, function(a, b)
        if not a or not b then return false end
        
        if a.Job ~= b.Job then
            return a.Job > b.Job
        end

        if a.ID ~= b.ID then
            return a.ID < b.ID
        end

        return false
    end)

    local options = {
        -- magic layout number 
        -- 因為CommonRewardContent尺寸異常，導致各使用處需要自行處理
        interval = ccp(0, 0),
        colMax = slf.colCount,
        paddingTop = 0,
        paddingBottom = 0,
        originScrollViewSize = slf.container:getVarNode("scrollViewContainer"):getContentSize(),
        isDisableTouchWhenNotFull = true,
        startOffsetAtItemIdx = 1,
    }

    --[[ 滾動視圖 左上至右下 ]]
    NodeHelperUZ:buildScrollViewGrid_LT2RB(
        slf.container,
        #self.spiritCfgs,
        "SpiritGallery_RoleItem.ccbi",
        function (eventName, container)
            slf:onScrollViewFunction(eventName, container)
        end,
        options
    )
end


--[[ 滾動視圖 功能窗口 ]]
function Inst:onScrollViewFunction(eventName, container)
    local slf = self

    --- 每个子空间创建的时候会调用这个函数
    local contentId = container:getItemDate().mID;
    -- 获取到时第几行
    local idx = contentId

    -- 當 更新
    if eventName == "luaRefreshItemView" then

        local spiritCfg = self.spiritCfgs[idx]
        local spiritID = spiritCfg.ID
        local spiritStatusInfo = SpiritDataMgr:getUserSpiritStatusInfo(spiritID)
        -- dump(spiritStatusInfo, "spiritStatusInfo")

        local node2String = {}
        local node2Visible = {}
        local node2Image = {}

        -- 精靈名稱
        node2String.mName = common:getLanguageString(SpiritDataMgr:getSpiritName(spiritID))

        -- 精靈圖像與外框圖像
        local galleryIconInfo = SpiritDataMgr:getSpiritGalleryIconInfo(spiritID)
        node2Image.mIcon = galleryIconInfo.head or ""
        node2Image.mFrame = galleryIconInfo.frame or ""
        
        -- 稀有度級別 與 星級 --
        -- 以5為每稀有度級別基準 (SR:基準0 起始1 SSR:基準5 起始6 UR:基準10 起始11)
        local jobBaseStar = (5 * (spiritCfg.Job - 1))
        -- 
        local star = jobBaseStar
        -- 若 玩家持有精靈資訊 存在
        if spiritStatusInfo ~= nil then
            -- 設置 星級
            star = star + spiritStatusInfo.star
        -- 若 不存在
        else
            -- 設置 預設5星
            star = star + 5
        end
        -- 輪詢所有UI 稀有度與星數相同的開啟 不同的隱藏
        for idx = 1, 15 do
            node2Visible["mStar"..tostring(idx)] = idx == star
        end

        -- 隱藏紅點，目前還不確定有無作用
        -- TODO
        node2Visible.mRedPoint = false
        -- 隱藏星數
        node2Visible.mStarNode = false
        -- 隱藏名字
        node2Visible.mName = false
        
        NodeHelper:setStringForLabel(container, node2String)
        NodeHelper:setSpriteImage(container, node2Image)
        NodeHelper:setNodesVisible(container, node2Visible)
        NodeHelperUZ:setNodeIsGrayRecursive(container, spiritStatusInfo == nil)

    -- 當 點擊
    elseif eventName == "onHead" then

        local spiritCfg = self.spiritCfgs[idx]
        local spiritID = spiritCfg.ID
        
        local SpiritDetailPage = require("Spirit.SpiritDetailPage")
        -- 精靈細節 一般開啟
        SpiritDetailPage:commOpen(spiritID, function(isChanged)
            -- 若有資料更新 則 請求同步資訊(刷新列表資訊)
            if isChanged then 
                slf:sendRequest_sync()
            end
        end)
    end
end

--[[ 送出請求 同步資訊 ]]
function Inst:sendRequest_sync ()
    
    -- 請求取得角色
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
end


return Inst