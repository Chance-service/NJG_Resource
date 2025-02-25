
--[[ 
    name: SpiritSubPage_Collection
    desc: 精靈 子頁面 羈絆
    author: youzi
    update: 2023/8/15 12:58
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
local CCBI_FILE = "SpiritCollection.ccbi"

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
}

--[[ 協定 ]]
local OPCODES = {
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    OPEN_FETTER_S = HP_pb.OPEN_FETTER_S,
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
Inst.subPageName = "Collection"
Inst.subPageCfg = nil

--[[ 羈絆資料 ]]
Inst.collectionCfgs = {}

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
    elseif packet.opcode == HP_pb.OPEN_FETTER_S then
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

    self.relationShipCfgs = SpiritDataMgr:getSpiritRelationshipCfgs()

    -- dump(self.relationShipCfgs)

    -- 初始化 列表
    NodeHelper:initScrollView(self.container, "mScrollView", #self.relationShipCfgs);

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

    self.relationShipCfgs = SpiritDataMgr:getSpiritRelationshipCfgs()

    local options = {
        -- magic layout number 
        -- 因為CommonRewardContent尺寸異常，導致各使用處需要自行處理
        interval = 0,
        colMax = slf.colCount,
        paddingTop = 0,
        paddingBottom = 0,
        originScrollViewSize = slf.container:getVarNode("scrollViewContainer"):getContentSize(),
        isDisableTouchWhenNotFull = true,
        startOffsetAtItemIdx = 1,
    }

    --[[ 滾動視圖 ]]
    NodeHelperUZ:buildScrollViewVertical(
        slf.container,
        #self.relationShipCfgs,
        function (idx, funcHandler)
            local container = ScriptContentBase:create("SpiritCollectionContent.ccbi")
            container:registerFunctionHandler(funcHandler)
            return container
        end,
        function (eventName, container)
            slf:onScrollViewFunction(eventName, container)
        end,
        options
    )
end


--[[ 滾動視圖 功能窗口 ]]
function Inst:onScrollViewFunction(eventName, container)
    
    --- 每个子空间创建的时候会调用这个函数
    local contentId = container:getItemDate().mID;
    -- 获取到时第几行
    local idx = contentId

    -- 當 更新
    if eventName == "luaRefreshItemView" then
        local relationShipCfg = self.relationShipCfgs[idx]       

        local node2String = {}
        local node2Visible = {}
        local node2Image = {}
        
        -- 用戶目前的該羈絆狀態
        local relationshipStatusInfo = SpiritDataMgr:getSpiritRelationshipStatusInfo(relationShipCfg.id)

        -- 羈絆名稱
        node2String.name = common:getLanguageString(relationShipCfg.name)

        -- 羈絆成員 ---------
        local teamNode = container:getVarNode("roleContainer")
        local teamNodeSize = teamNode:getContentSize()
        local teamNodeCenter = ccp(teamNodeSize.width/2, teamNodeSize.height/2)

        -- 移除舊成員物件
        teamNode:removeAllChildren()
        -- 成員物件
        local memberNodes = {}
        -- 是否所有成員都已經解鎖
        local allMembersUnlock = true
        -- 成員中的最小星數
        local minStar = -1
        -- 成員中的最大稀有度
        local maxRare = 1
        -- 成員數中間序號 (用來計算位置)
        local halfTeamCount = #relationShipCfg.team / 2

        -- 每個 羈絆成員
        for memIdx = 1, #relationShipCfg.team do
            local member = relationShipCfg.team[memIdx]

            local spiritCfg = SpiritDataMgr:getSpiritCfg(member)
            if maxRare < spiritCfg.Job then
                maxRare = spiritCfg.Job
            end
            
            -- 取得 用戶持有的精靈資訊
            local spiritStatusInfo = SpiritDataMgr:getUserSpiritStatusInfo(member)
            -- 若 不存在 則 設 所有成員已解鎖 為 否
            if spiritStatusInfo == nil then
                allMembersUnlock = false
            -- 若 存在
            else
                -- 若 尚未設置最小星數 或 該成員的星數 更小 則 取代最小星數
                if minStar == -1 or spiritStatusInfo.star < minStar then
                    minStar = spiritStatusInfo.star
                end
            end

            -- 建立 成員UI
            local roleItem = self:createRoleItem(member)
            teamNode:addChild(roleItem)

            memberNodes[memIdx] = roleItem
            
            -- 設置位置
            local width = roleItem:getContentSize().width
            roleItem:setAnchorPoint(ccp(0.5, 0.5))
            -- 從容器中心點 + (寬度 * 成員序號-中心點成員數(對半)-自身寬度)
            roleItem:setPosition(ccp(teamNodeCenter.x + (width * (memIdx - halfTeamCount - 0.5)), teamNodeCenter.y))
        end

        
        -- 羈絆星數
        local relationshipStar = 0
        -- 若 已有羈絆資訊 (已解鎖)
        if relationshipStatusInfo ~= nil then
            -- 從 取得資訊中 設置
            -- relationshipStar = relationshipStatusInfo.star or relationshipStar
            -- 或者
            -- 以 成員中最小星數 為主
            relationshipStar = minStar
        end

        
        -- 羈絆 屬性說明
        -- TODO
        node2String.attrDesc = common:getLanguageString("")

        -- 屬性
        local attrs = InfoAccesser:getAttrInfosByStrs(relationShipCfg.property, {
            --mergeAttrs = {"atk", "def", "penetrate"}
        })
        if relationshipStar > 0 then
            local starDelta = relationshipStar - 1
            for idx, each in ipairs(attrs) do
                local val = each.val
                -- SR 數值公式
                if maxRare == 1 then
                    local lastVal = val
                    val = val + (val * starDelta)
                    -- print(string.format("%s = val[%s] + val[%s] * starDelta[%s]", val, lastVal, lastVal, starDelta))
                -- SSR 數值公式
                elseif maxRare == 2 then
                    val = val + (val * (starDelta * 2))
                -- UR 數值公式
                elseif maxRare == 3 then
                    val = val + (val * (starDelta + ((relationshipStar * 2) - 2)))
                end
                -- 取代
                attrs[idx].val = val
            end
        end

        if attrs ~= nil and #attrs >= 2 then
            -- 屬性圖標
            node2Image.attrIcon_1 = attrs[1].icon
            node2Image.attrIcon_2 = attrs[2].icon
            
            -- 屬性名稱
            local attrName_1 = common:getLanguageString(attrs[1].name)
            local attrName_2 = common:getLanguageString(attrs[2].name)
            
            -- 文本
            local formatStr = FreeTypeConfig[4003].content
            node2String.attrText_1 = common:getLanguageString(formatStr, attrName_1, self:_attrToAddtiveStr(attrs[1]))
            node2String.attrText_2 = common:getLanguageString(formatStr, attrName_2, self:_attrToAddtiveStr(attrs[2]))

            -- node2String.attrText_1 = common:getLanguageString("#v1# #v2#", attrName_1, self:_attrToAddtiveStr(attrs[1]))
            -- node2String.attrText_2 = common:getLanguageString("#v1# #v2#", attrName_2, self:_attrToAddtiveStr(attrs[2]))

            -- if relationshipStatusInfo ~= nil then
            --     print("relationshipStatusInfo.star "..tostring(relationshipStatusInfo.star))
            --     node2String.attrDesc = "star : "..tostring(relationshipStatusInfo.star)
            -- end
        end
        
        -- 按鈕文字
        local btnText = "@Unlock"
        -- 若 已有羈絆資訊 (已解鎖)
        if relationshipStatusInfo ~= nil then
            -- btnText = "@Upgrade"
            btnText = "@FetterBtnActivated"
        end
        node2String.btnText = common:getLanguageString(btnText)

        -- 按鈕狀態
        local isBtnActive = false
        
        -- 若 羈絆成員都解鎖 且 未升到當前上限
        if allMembersUnlock and relationshipStar < minStar then
            isBtnActive = true
        end
        
        NodeHelper:setStringForLabel(container, node2String)
        NodeHelper:setSpriteImage(container, node2Image)
        NodeHelper:setNodesVisible(container, node2Visible)
        NodeHelper:setMenuItemEnabled(container, "btnMenuItem", isBtnActive)
        -- 灰階
        -- NodeHelperUZ:setNodeIsGrayRecursive(container:getVarNode("btnNode"), not isBtnActive)

        
        
        if attrs ~= nil and #attrs >= 2 then
            -- 設置 屬性文字 為 HTML文字
            local size_1 = container:getVarNode("mAttrText1"):getContentSize()
            local size_2 = container:getVarNode("mAttrText2"):getContentSize()
            local htmlLabel_1 = NodeHelper:setCCHTMLLabel(container, "mAttrText1", size_1, node2String.attrText_1)
            htmlLabel_1:setTag(-1) -- 避免後續 NodeHelper:setCCHTMLLabel 把 特定tag的既有HtmlLabel 移除
            local htmlLabel_2 = NodeHelper:setCCHTMLLabel(container, "mAttrText2", size_2, node2String.attrText_2)
            htmlLabel_2:setTag(-1) -- 避免後續 NodeHelper:setCCHTMLLabel 把 特定tag的既有HtmlLabel 移除
        end

    
    -- 當 按鈕
    elseif eventName == "onBtn" then

        local relationShipCfg = self.relationShipCfgs[idx]  

        -- 送出解鎖請求
        FetterManager.reqFetterOpen(relationShipCfg.id)

        -- 送出升級請求?
    end
end

--[[ 建立 角色物件 ]]
function Inst:createRoleItem (spiritID)

    local spiritCfg = SpiritDataMgr:getSpiritCfg(spiritID)
    local spiritStatusInfo = SpiritDataMgr:getUserSpiritStatusInfo(spiritID)

    -- 建立UI
    local container = ScriptContentBase:create("SpiritGallery_RoleItem.ccbi")

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
    
    NodeHelper:setStringForLabel(container, node2String)
    NodeHelper:setSpriteImage(container, node2Image)
    NodeHelper:setNodesVisible(container, node2Visible)
    NodeHelperUZ:setNodeIsGrayRecursive(container, spiritStatusInfo == nil)


    -- TODO
    -- container:registerFunctionHandler(function(eventName, container)

    --     if eventName == "onHead" then

    --         -- 精靈細節 一般開啟
    --         SpiritDetailPage:commOpen(spiritID, function(isChanged)
    --             -- 若有資料更新 則 請求同步資訊(刷新列表資訊)
    --             if isChanged then 
    --                 slf:sendRequest_sync()
    --             end
    --         end)

    --     end
    
    -- end)

    return container
end

--[[ 轉換屬性為加成文字 ]]
function Inst:_attrToAddtiveStr (attrInfo)
    local val = attrInfo.val
    local fmtStr
    if attrInfo.type == 1--[[ 倍率 ]] then
        val = val * 0.01
        fmtStr = "%s%%"
    elseif attrInfo.type == 2--[[ 數值 ]] then
        fmtStr = "%s"
    else 
        fmtStr = "%s"
    end
    return string.format(fmtStr, val)
end

--[[ 送出請求 同步資訊 ]]
function Inst:sendRequest_sync ()
    
    -- 請求取得角色
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
end


return Inst