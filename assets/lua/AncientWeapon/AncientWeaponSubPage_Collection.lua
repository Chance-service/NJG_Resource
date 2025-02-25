
--[[ 
    name: AncientWeaponCollection
    desc: 專武 子頁面 升級
    author: youzi
    update: 2023/12/1 17:31
    description: 

--]]


local HP_pb = require("HP_pb") -- 包含协议id文件

local Async = require("Util.Async")
local PacketAgent = require("Util.PacketAgent")
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local PathAccesser = require("Util.PathAccesser")
local InfoAccesser = require("Util.InfoAccesser")
local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ UI檔案 ]]
local CCBI_FILE = "AWCollection.ccbi"
local CCBI_FILE_CONTENT = "AWCollectionContent.ccbi"
local CCBI_FILE_CONTENT_CONTENT = "WeaponContent.ccbi"

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
    
}

-- 羈絆項目 腳本
local CollectionItem = {}

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

--[[ 子頁面資訊 ]]
Inst.subPageName = "Collection"
Inst.subPageCfg = nil

--[[ 羈絆資料 ]]
Inst.relationshipCfgs = {}

--[[ 協定 ]]
Inst.opcodes = {}
Inst.opcodes["FETCH_OPEN_MUTUAL_INFO_S"] = HP_pb.FETCH_OPEN_MUTUAL_INFO_S
Inst.opcodes["EQUIP_OPEN_MUTUAL_S"] = HP_pb.EQUIP_OPEN_MUTUAL_S

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 建立 頁面 ]]
function Inst:createPage (parentPage)
    self.parentPage = parentPage
    self.container = ScriptContentBase:create(CCBI_FILE)
    return self.container
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (selfContainer, parentPage)
    local slf = self
    
    self.relationshipCfgs = AncientWeaponDataMgr:getRelationshipCfgs()

    -- 綁定 協定與訊息
    self.parentPage:registerPacket(self.opcodes)
    --local packetAgent = PacketAgent:inst()
    --packetAgent:bindOpcodeMsg(HP_pb.FETCH_OPEN_MUTUAL_INFO_S, EquipOpr_pb.OpenMutuaInfolResp)
    --packetAgent:bindOpcodeMsg(HP_pb.EQUIP_OPEN_MUTUAL_S, EquipOpr_pb.EquipOpenMutualResp)

    -- 註冊 呼叫行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = HANDLER_MAP[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)

    -- 取得 子頁面 配置
    self.subPageCfg = AncientWeaponDataMgr:getSubPageCfg(self.subPageName)

    -- 背景自適應
    NodeHelperUZ:fitBGNode(self.container:getVarNode("bgImg"))

    -- 初始化 列表
    NodeHelper:initScrollView(self.container, "scrollView", #self.relationshipCfgs)

    -------------------
    self:sendRequest_syncAwInfo(function(packet)
        local fetterIds = packet.msg.mutualId
        local fetterStars = packet.msg.minstar
        if #fetterIds ~= #fetterStars then return end
        self:refreshPage()
    end)
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(selfContainer, parentPage)

end

--[[ 當 頁面 離開 ]]
function Inst:onExit(selfContainer, parentPage)
    self.parentPage:removePacket(self.opcodes)
end

--[[ 當 點擊 重置  ]]
function Inst:onReset (container)
    
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

    local scrollViewRef = self.container:getVarNode("scrollViewRef")

    -- 滾動視圖
    NodeHelperUZ:buildScrollViewVertical(
        self.container,
        #self.relationshipCfgs,
        function (idx, funcHandler)
            local collectionItem = CollectionItem:new()
            local container = collectionItem.container
            container.item = collectionItem
            container:registerFunctionHandler(funcHandler)
            return container
        end,
        function (eventName, container)
            if eventName ~= "luaRefreshItemView" then return end
            
            --- 每个子空间创建的时候会调用这个函数
            local contentId = container:getItemDate().mID;
            -- 获取到时第几行
            local idx = contentId
            local relationshipCfg = slf.relationshipCfgs[idx]

            container.item:setRelationship(relationshipCfg)
            container.item:refresh()
        end,
        {
            interval = 0,
            paddingTop = 0,
            paddingBottom = 0,
            originScrollViewSize = scrollViewRef:getContentSize(),
            isDisableTouchWhenNotFull = true,
            startOffsetAtItemIdx = 1,
        }
    )
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



function CollectionItem:new ()
    local inst = {}

    inst.container = ScriptContentBase:create(CCBI_FILE_CONTENT)

    inst.relationShipCfg = nil

    inst.equipIDs = {}


    function inst:_init() 
        -- 初始化 列表
        -- NodeHelper:initScrollView(self.container, "scrollView", 3)
    end

    function inst:setRelationship(relationShipCfg)
        self.relationShipCfg = relationShipCfg
        
        local heroCfgs = ConfigManager.getNewHeroCfg()

        self.equipIDs = {}
        for idx = 1, #relationShipCfg.team do
            local hero = relationShipCfg.team[idx]
            local star = relationShipCfg.star
            local equipID = tonumber(string.format("%03d%02d", hero, star))
            self.equipIDs[idx] = equipID
        end
    end

    function inst:refresh ()
        local slf = self

        -- local scrollViewRef = self.container:getVarNode("scrollViewRef")

        local equipCfgs = ConfigManager.getEquipCfg()
        local userEquips = UserEquipManager:getEquipIdsByClass()
        local equipSeriesExist = {}
        for idx = 1, #userEquips do
            local userEquip = UserEquipManager:getUserEquipById(userEquips[idx])
            local parsedEquip = InfoAccesser:parseAWEquipStr(userEquip.equipId)
            if parsedEquip ~= nil then
                equipSeriesExist[parsedEquip.series] = {
                    userEquip = userEquip,
                    parsedEquip = parsedEquip,
                }
            end
        end
        local dressEquips = UserEquipManager:getEquipDress()
        for idx = 1, #dressEquips do
            local dressEquip = UserEquipManager:getUserEquipById(dressEquips[idx])
            local parsedEquip = InfoAccesser:parseAWEquipStr(dressEquip.equipId)
            if parsedEquip ~= nil then
                equipSeriesExist[parsedEquip.series] = {
                    userEquip = dressEquip,
                    parsedEquip = parsedEquip,
                }
            end
        end

        local txtMap = {}
        txtMap.titleTxt = self.relationShipCfg.name

        local itemsNode = self.container:getVarNode("itemsNode")
        local itemsNodeMidPos = itemsNode:getContentSize().width / 2

        -- 左右間隔
        local intervalX = 10
        -- 中位序號
        local halfCount = (#self.equipIDs + 1) / 2

        local formula = self.relationShipCfg.formula
        local relationshipStar = nil

        -- 羈絆成員
        for idx = 1, #self.equipIDs do
            local equipID = self.equipIDs[idx]

            local imgMap = {}
            local img9Map = {}
            local txtMap = {}

            local eachEquipUI = ScriptContentBase:create(CCBI_FILE_CONTENT_CONTENT)
            itemsNode:addChild(eachEquipUI)
            
            local offsetIdx = idx - halfCount
            local width = eachEquipUI:getContentSize().width
            local offsetX = (width + intervalX) * offsetIdx
            eachEquipUI:setPositionX(itemsNodeMidPos - (width/2) + offsetX)

            local equipCfg = equipCfgs[equipID]
            if equipCfg == nil then
                print("equipCfg not found : "..tostring(equipID))
            else 
                imgMap.img = equipCfg.icon
                txtMap.nameTxt = common:getLanguageString(equipCfg.name)
            end
            
            
            local parsedEquip = InfoAccesser:parseAWEquipStr(equipID)

            local exist = equipSeriesExist[parsedEquip.series]
            if exist ~= nil then
                local equipStar = parsedEquip.star

                -- 最小星數
                if relationshipStar == nil or equipStar < relationshipStar then
                    relationshipStar = equipStar
                end

                -- TODO 若有要做其他顯示
                local equipRare = exist.parsedEquip.star
                -- 背景框
                local awEquipFrameAndBGPath = PathAccesser:getAWEquipFrameAndBGPath(equipRare)
                imgMap.frameImg = awEquipFrameAndBGPath.frame
                imgMap.bgImg = awEquipFrameAndBGPath.bg
            else
                local equipRare = parsedEquip.rare
                -- 背景框
                local awEquipFrameAndBGPath = PathAccesser:getAWEquipFrameAndBGPath(equipRare)
                imgMap.frameImg = awEquipFrameAndBGPath.frame
                imgMap.bgImg = awEquipFrameAndBGPath.bg
            end

            NodeHelper:setSpriteImage(eachEquipUI, imgMap)
            NodeHelper:setStringForLabel(eachEquipUI, txtMap)
            -- 設 灰階 為 是否擁有
            NodeHelperUZ:setNodeIsGrayRecursive(eachEquipUI, exist == nil)
        end

        -- 屬性計算
        local attrs = InfoAccesser:getAttrInfosByStrs(self.relationShipCfg.property, { --[[mergeAttrs = {"atk", "def", "penetrate"}]] })

        if relationshipStar ~= nil and relationshipStar > 0 then
            local starDelta = relationshipStar - 1
            for idx, each in ipairs(attrs) do
                local val = each.val
                if tonumber(formula) == 1 then
                    finalValue = val + val * starDelta
                elseif tonumber(formula) == 2 then
                    finalValue = val + val * 3 * (relationshipStar - 6) + (val * relationshipStar / 4)
                elseif tonumber(formula) == 3 then
                    finalValue = val + val * (starDelta * 2)
                elseif tonumber(formula) == 4 then
                    finalValue = val + val * (starDelta + (relationshipStar * 2 - 2))
                end
                -- 取代
                attrs[idx].val = val
            end
        end


        local attrName_1 = common:getLanguageString(attrs[1].name)
        local attrName_2 = common:getLanguageString(attrs[2].name)

        local formatStr = FreeTypeConfig[4003].content
        txtMap.attrTxt_1 = common:getLanguageString(formatStr, attrName_1, Inst:_attrToAddtiveStr(attrs[1]))
        txtMap.attrTxt_2 = common:getLanguageString(formatStr, attrName_2, Inst:_attrToAddtiveStr(attrs[2]))

        NodeHelper:setStringForLabel(self.container, txtMap)

        if attrs ~= nil and #attrs >= 2 then
            -- 設置 屬性文字 為 HTML文字
            local size_1 = self.container:getVarNode("attrTxt_1"):getContentSize()
            local size_2 = self.container:getVarNode("attrTxt_2"):getContentSize()
            local htmlLabel_1 = NodeHelper:setCCHTMLLabel(self.container, "attrTxt_1", size_1, txtMap.attrTxt_1)
            local htmlLabel_tag = htmlLabel_1:getTag()
            htmlLabel_1:setTag(-1) -- 避免後續 NodeHelper:setCCHTMLLabel 把 特定tag的既有HtmlLabel 移除
            local htmlLabel_2 = NodeHelper:setCCHTMLLabel(self.container, "attrTxt_2", size_2, txtMap.attrTxt_2)
            htmlLabel_1:setTag(htmlLabel_tag)
        end
    end

    return inst
end

--[[ 送出請求 資訊 ]]
function Inst:sendRequest_syncAwInfo (onReceive)
    --local packetAgent = PacketAgent:inst()
    --local res = nil
    ---- 非同步 平行執行
    --Async:parallel({
    --    function (ctrlr)
    --        -- 當 送出並回傳 同步
    --        packetAgent:send(HP_pb.FETCH_OPEN_MUTUAL_INFO_C, nil, HP_pb.FETCH_OPEN_MUTUAL_INFO_S, function(packet)
    --            res = packet
    --            ctrlr.next()
    --        end, { isWait = false })
    --    end,
    --},
    ---- 全部都完成後
    --function()
    --    onReceive(res)
    --end)
    common:sendEmptyPacket(HP_pb.FETCH_OPEN_MUTUAL_INFO_C)
end

--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.FETCH_OPEN_MUTUAL_INFO_S then
        local msg = Battle_pb.NewBattleLevelInfo()
        msg:ParseFromString(msgBuff)
    end
end

return Inst