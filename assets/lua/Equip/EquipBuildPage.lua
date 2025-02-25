----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb")
local EquipOpr_pb = require("EquipOpr_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local NodeHelper = require("NodeHelper")
local EquipOprHelper = require("Equip.EquipOprHelper")
local PBHelper = require("PBHelper")
local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")
require("Util.RedPointManager")
--------------------------------------------------------------------------------
local thisPageName = "EquipBuildPage"

local opcodes = {
    EQUIP_FORGE_C = HP_pb.EQUIP_FORGE_C,
    EQUIP_FORGE_S = HP_pb.EQUIP_FORGE_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
}

local option = {
    ccbiFile = "RefiningBuildingEquipmentPopUp_1.ccbi",
    handlerMap =
    {
        onForge = "onForge",
        onForgeAll = "onForgeAll",
        onAdd = "onAdd",
        onReduce = "onReduce",
        onRefresh = "onRefresh",
        onCreate = "onCreate",
        onHelp = "onHelp",
        onClose = "onClose",
        onEquip1 = "onEquip1",
        onEquip2 = "onEquip2",
    },
    opcode = opcodes
}
for i = 1, 4 do
    option.handlerMap["onPageBuild" .. i] = onPageBuild
end
local PAGE_TYPE = { WEAPON = Const_pb.WEAPON1, ARMOR = Const_pb.CUIRASS, ACCESSORY = Const_pb.RING, FOOTS = Const_pb.SHOES }
local idToPageType = {
    [RedPointManager.PAGE_IDS.WEAPON_ALL_BTN] = PAGE_TYPE.WEAPON,
    [RedPointManager.PAGE_IDS.CHEST_ALL_BTN] = PAGE_TYPE.ARMOR,
    [RedPointManager.PAGE_IDS.RING_ALL_BTN] = PAGE_TYPE.ACCESSORY,
    [RedPointManager.PAGE_IDS.FOOT_ALL_BTN] = PAGE_TYPE.FOOTS,
}
local typeToPointId = {
    [PAGE_TYPE.WEAPON] = RedPointManager.PAGE_IDS.WEAPON_ALL_BTN,
    [PAGE_TYPE.ARMOR] = RedPointManager.PAGE_IDS.CHEST_ALL_BTN,
    [PAGE_TYPE.ACCESSORY] = RedPointManager.PAGE_IDS.RING_ALL_BTN,
    [PAGE_TYPE.FOOTS] = RedPointManager.PAGE_IDS.FOOT_ALL_BTN,
}
local FORGE_TYPE = { ONE = 1, ALL = 2 }
local nowPageType = PAGE_TYPE.WEAPON

local mParentContainer = nil

local EquipBuildPageBase = { }
local equipTable = { }
local equipNode = { }
local equipListTable = { }
local forgeAllResult = { }
local sortTable = { }

local forgeType = 0     -- 選擇的鍛造類型(一件/全部)
local thisEquipId = 0   -- 製造裝備id
local costEquipId = 0   -- 消耗裝備id
local selfCostEquipNum = 0  -- 身上的消耗裝備數量
local coinCost = 0      -- 消耗金幣量(單件)
local equipCost = 0     -- 消耗裝備量(單件)
local forgeNum = 0      -- 目標製造數量
local maxForgeNum = 0   -- 最大製造數量
local BAR_MAX_WIDTH = 71
local FORGE_MAX_NUM = 99

local buildSpineParent = nil    -- 製造spine父節點
local buildSpine = nil  -- 製造spine
-------------------- scrollview item --------------------------------
local EquipBuildItem = {
    ccbiFile = "BackpackItem.ccbi",
}
function EquipBuildItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function EquipBuildItem:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh(self.container)
end

function EquipBuildItem:refreshSelectState(container)
    NodeHelper:setNodesVisible(self.container, { mMask = (self.cfg.id == thisEquipId) })
end

function EquipBuildItem:refresh(container)
    local iconBgSprite = NodeHelper:getImageBgByQuality(self.cfg.quality)
    NodeHelper:setSpriteImage(self.container, { mPic1 = self.cfg.icon, mFrameShade1 = iconBgSprite })
    NodeHelper:setQualityFrames(self.container, { mHand1 = self.cfg.quality })

    NodeHelper:setStringForLabel(self.container, { mNumber1_1 = "", mName1 = "", mNumber1 = "", mEquipLv = "" })
    NodeHelper:setNodesVisible(self.container, { mRedPoint = false, mMask = (self.cfg.id == thisEquipId) })

    for i = 1, 6 do
        NodeHelper:setNodesVisible(self.container, { ["mStar" .. i] = (i == self.cfg.stepLevel) })
    end
end

function EquipBuildItem:onHand1(container)
    if self.cfg ~= nil then
        EquipBuildPageBase:clearData(container)
        thisEquipId = self.cfg.id
        for i = 1, #equipListTable do
            equipListTable[i].panel:refreshSelectState(equipListTable[i].cell)
        end
        EquipBuildPageBase:refreshEquipIcon(container)

        -- 預設顯示最大數量
        forgeNum = EquipBuildPageBase:calMaxBuildNum(container)
        EquipBuildPageBase:refreshBuildInfo(container)
        EquipBuildPageBase:refreshBtnState(container)
    end
end
-------------------------------------------------------------
function EquipBuildPageBase:onEnter(ParentContainer)
    mParentContainer = ParentContainer

    self:clearData(container)
    nowPageType = PAGE_TYPE.WEAPON

    self.container = ScriptContentBase:create(option.ccbiFile)
    self.container:registerFunctionHandler(EquipBuildPageBase.onFunction)
    self.container.scrollview = self.container:getVarScrollView("mContent")

    self:initEquipTable(self.container)
    self:initEquipIcon(self.container)

    UserInfo.sync()
    self:registerPacket(mParentContainer)
    self:onPageBuild(self.container, "onPageBuild1")

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["EquipBuildPage"] = self.container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end

    return self.container
end

function EquipBuildPageBase:onExit(container) 
    buildSpine:unregisterFunctionHandler("COMPLETE")
    if buildSpineParent then
        buildSpineParent:removeAllChildrenWithCleanup(true)
    end
    buildSpineParent = nil
    buildSpine = nil
    self:clearData(container)
    self.container.scrollview:removeAllCell()
    self:removePacket(container)
end
----------------------------------------------------------------
function EquipBuildPageBase:refreshPage(container, isAll)
    self:clearData(container, isAll)
    self:initSpine(container)
    self:refreshScrollView(container, isAll)
    self:refreshEquipIcon(container)
    -- 預設顯示最大數量
    forgeNum = self:calMaxBuildNum(container)
    self:refreshBuildInfo(container)
    self:refreshUserInfo(container)
    self:refreshAllPoint(container)
    self:refreshBtnState(container)
end

function EquipBuildPageBase:clearData(container, isAll)
    if isAll then
        thisEquipId = 0
    end
    forgeType = 0
    forgeAllResult = { }
    coinCost = 0
    forgeNum = 0
    costEquipId = 0
    selfCostEquipNum = 0
    sortTable = { }
end

function EquipBuildPageBase:onSpineEvent(tag, eventName)
    if eventName == "COMPLETE" then
        if forgeType == FORGE_TYPE.ONE then
            local msg = EquipOpr_pb.EquipForgeReq()
            local msgForgeInfo = msg.Infos:add()
            msgForgeInfo.equipId = thisEquipId
            msgForgeInfo.count = forgeNum
            common:sendPacket(HP_pb.EQUIP_FORGE_C, msg, true)
        elseif forgeType == FORGE_TYPE.ALL then
            local msg = EquipOpr_pb.EquipForgeReq()
            for i = 1, #sortTable do
                local msgForgeInfo = msg.Infos:add()
                msgForgeInfo.equipId = sortTable[i].id
                msgForgeInfo.count = sortTable[i].count
            end
            common:sendPacket(HP_pb.EQUIP_FORGE_C, msg, true)
        end
    end
end

function EquipBuildPageBase:initSpine(container)
    buildSpine = SpineContainer:create("Spine/NGUI", "NGUI_03_Forge")
    buildSpine:registerFunctionHandler("COMPLETE", self.onSpineEvent)
    local spineNode = tolua.cast(buildSpine, "CCNode")
    buildSpineParent = container:getVarNode("mSpineNode")
    buildSpineParent:setVisible(false)
    buildSpineParent:addChild(spineNode)
end

function EquipBuildPageBase:playSpine(container)
    buildSpineParent:setVisible(true)
    buildSpine:runAnimation(1, "animation", 0)
end

function EquipBuildPageBase:initEquipTable(container)
    local cfg = ConfigManager:getEquipCfg()
    equipTable = { }
    for k, v in pairs(cfg) do
        if v.part == Const_pb.WEAPON1 or v.part == Const_pb.CUIRASS or
           v.part == Const_pb.RING or v.part == Const_pb.SHOES then
            if v.fixedMaterial[1].itemId then
                equipTable[v.part] = equipTable[v.part] or { }
                table.insert(equipTable[v.part], v)
            end
        end
    end
    for k, v in pairs(equipTable) do
        table.sort(v, function(info1, info2)
            if info1 == nil or info2 == nil then
                return false
            end
            if info1.id ~= info2.id then
                return info1.id < info2.id
            end
            return false
        end)
    end
end

function EquipBuildPageBase:initEquipIcon(container)
    for i = 1, 2 do
        local parent = container:getVarNode("mEquipNode" .. i)
        local itemNode = ScriptContentBase:create("BackpackItem.ccbi")
        itemNode:setAnchorPoint(ccp(0.5, 0.5))
        parent:addChild(itemNode)
        equipNode[i] = itemNode
        NodeHelper:setStringForLabel(itemNode, { mNumber1_1 = "", mName1 = "", mNumber1 = "", mEquipLv = "" })
        NodeHelper:setNodesVisible(itemNode, { mRedPoint = false, mMask = false })
    end
end
-- 刷新裝備列表
function EquipBuildPageBase:refreshScrollView(container, isAll)
    if isAll then
        container.mScrollView = container:getVarScrollView("mContent")

        container.mScrollView:setTouchEnabled(false)
        container.mScrollViewRootNode = container.mScrollView:getContainer()
        container.m_pScrollViewFacade = CCReViScrollViewFacade:new_local(container.mScrollView)
        container.m_pScrollViewFacade:init(0, 0)

        container.mScrollView:removeAllCell()
        equipListTable = { }
        local targetTable = equipTable[nowPageType]
        if targetTable then
            for i = 1, #targetTable do  -- 跳過最低階裝備
                if i == 1 then
                    thisEquipId = targetTable[i].id
                end
                local cell = CCBFileCell:create()
                local panel = EquipBuildItem:new({ id = i, ccbiFile = cell, mState = 0, cfg = targetTable[i] })
                cell:registerFunctionHandler(panel)
                cell:setCCBFile(EquipBuildItem.ccbiFile)
                container.mScrollView:addCellBack(cell)
                table.insert(equipListTable, { panel = panel, cell = cell })
            end
            container.mScrollView:orderCCBFileCells()
        end
    end
end
-- 刷新材料&製造裝備icon
function EquipBuildPageBase:refreshEquipIcon(container)
    for i = 1, 2 do
        local cfg = nil
        if i == 1 then
            local costEquipcfg = ConfigManager:getEquipCfg()[thisEquipId]
            for j = 1, #costEquipcfg.fixedMaterial do
                if tonumber(costEquipcfg.fixedMaterial[j].type) == 40000 then
                    costEquipId = tonumber(costEquipcfg.fixedMaterial[j].itemId)
                    equipCost = tonumber(costEquipcfg.fixedMaterial[j].count)
                    selfCostEquipNum = #UserEquipManager:getUserEquipByCfgId(costEquipId)
                    cfg = ConfigManager:getEquipCfg()[tonumber(costEquipId)]
                elseif tonumber(costEquipcfg.fixedMaterial[j].type) == 10000 and tonumber(costEquipcfg.fixedMaterial[j].itemId) == 1002 then  -- 金幣
                    coinCost = tonumber(costEquipcfg.fixedMaterial[j].count)
                end
            end
        elseif i == 2 then
            cfg = ConfigManager:getEquipCfg()[thisEquipId]
        end
        if cfg then
            local iconBgSprite = NodeHelper:getImageBgByQuality(cfg.quality)
            NodeHelper:setSpriteImage(equipNode[i], { mPic1 = cfg.icon, mFrameShade1 = iconBgSprite })
            NodeHelper:setQualityFrames(equipNode[i], { mHand1 = cfg.quality })

            NodeHelper:setStringForLabel(equipNode[i], { mNumber1_1 = "", mName1 = "", mNumber1 = "", mEquipLv = "" })
            NodeHelper:setNodesVisible(equipNode[i], { mRedPoint = false, mMask = false })

            for star = 1, 6 do
                NodeHelper:setNodesVisible(equipNode[i], { ["mStar" .. star] = (star == cfg.stepLevel) })
            end
        end
    end
end
-- 刷新按鈕狀態
function EquipBuildPageBase:refreshBtnState(container)
    NodeHelper:setMenuItemEnabled(self.container, "mAddBtn", forgeNum < maxForgeNum and forgeNum < FORGE_MAX_NUM)
    NodeHelper:setMenuItemEnabled(self.container, "mReduceBtn", forgeNum > 0)
end
-- 刷新數字&bar顯示
function EquipBuildPageBase:refreshBuildInfo(container)
    -- 顯示金幣消耗
    local coinLabel = self.container:getVarLabelTTF("mCoinNum")
    coinLabel:setString(coinCost * forgeNum)
    if coinCost * forgeNum > UserInfo.playerInfo.coin then
        coinLabel:setColor(ccc3(255, 0, 0))
    else
        coinLabel:setColor(ccc3(255, 255, 255))
    end
    -- 顯示身上裝備數量
    local equipNum1 = self.container:getVarLabelTTF("mEquipNum1")
    equipNum1:setString(selfCostEquipNum .. "/" .. equipCost)
    local bar1 = self.container:getVarScale9Sprite("mEquipBar1")
    bar1:setContentSize(CCSize(BAR_MAX_WIDTH * math.min(1, math.max(0, selfCostEquipNum / equipCost)), bar1:getContentSize().height))
    NodeHelper:setNodesVisible(self.container, { mEquipBar1 = (selfCostEquipNum > 0) })

    -- 顯示選擇裝備數量
    local selectNum = self.container:getVarLabelTTF("mSelectNum")
    selectNum:setString(forgeNum)
end
-- 刷新玩家金幣&鑽石數量
function EquipBuildPageBase:refreshUserInfo(container)
    local coinStr = GameUtil:formatNumber(UserInfo.playerInfo.coin)
    local diamondStr = GameUtil:formatNumber(UserInfo.playerInfo.gold)
    NodeHelper:setStringForLabel(mParentContainer, { mCoin = coinStr, mDiamond = diamondStr })
end
-- 計算Forge All結果
function EquipBuildPageBase:calForgeAllResult(container)
    forgeAllResult = { }
    local targetTable = equipTable[nowPageType]
    local userCoin = UserInfo.playerInfo.coin
    local totalCoin = 0
    if targetTable then
        for i = 1, #targetTable do  -- 跳過最低階裝備
            local buildEquipcfg = ConfigManager:getEquipCfg()[targetTable[i].id]
            local costId, costNum, costCoin = nil, nil, 0
            for j = 1, #buildEquipcfg.fixedMaterial do  -- 消耗的資源
                if tonumber(buildEquipcfg.fixedMaterial[j].type) == 40000 then
                    costId = tonumber(buildEquipcfg.fixedMaterial[j].itemId) -- 消耗裝備id(單件)
                    costNum = tonumber(buildEquipcfg.fixedMaterial[j].count) -- 消耗裝備數量(單件)
                elseif tonumber(buildEquipcfg.fixedMaterial[j].type) == 10000 and tonumber(buildEquipcfg.fixedMaterial[j].itemId) == 1002 then  -- 金幣
                    costCoin = tonumber(buildEquipcfg.fixedMaterial[j].count)    -- 消耗金幣(單件)
                end
            end
            if costId and costNum then
                userNum = #UserEquipManager:getUserEquipByCfgId(costId) + (forgeAllResult[costId] or 0)
                local buildMaxNum = math.max(0, math.min((costCoin == 0) and FORGE_MAX_NUM or math.floor((userCoin - totalCoin) / costCoin), math.floor(userNum / costNum)))
                if buildMaxNum > 0 then
                    totalCoin = totalCoin + buildMaxNum * costCoin
                    forgeAllResult[targetTable[i].id] = buildMaxNum
                end
            end
        end
        forgeAllResult.money = totalCoin
    end
end
----------------click event------------------------
function EquipBuildPageBase:onEquip1(container)
    local itemCfg = { type = 4 * 10000, itemId = costEquipId, count = 1 }  
    GameUtil:showTip(container:getVarNode("mEquipNode1"), itemCfg)
end
function EquipBuildPageBase:onEquip2(container)
    local itemCfg = { type = 4 * 10000, itemId = thisEquipId, count = 1 }  
    GameUtil:showTip(container:getVarNode("mEquipNode2"), itemCfg)
end
-- 選擇分類頁籤
function EquipBuildPageBase:onPageBuild(container, eventName)
    local page = tonumber(eventName:sub(-1))
    nowPageType = (page == 1 and PAGE_TYPE.WEAPON) or (page == 2 and PAGE_TYPE.ARMOR) or 
                  (page == 3 and PAGE_TYPE.ACCESSORY) or (page == 4 and PAGE_TYPE.FOOTS) or PAGE_TYPE.WEAPON
    for i = 1, 4 do
        local item = container:getVarMenuItemImage("mSelect" .. i)
        if page == i then
            item:selected()
        else
            item:unselected()
        end
        NodeHelper:setNodesVisible(container, { ["mImgOn" .. i] = (page == i) })
        NodeHelper:setColorForLabel(container, { ["mTxt" .. i] = ((page == i) and GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT) })
    end
    self:refreshPage(container, true)
end
-- 計算最大製造數量
function EquipBuildPageBase:calMaxBuildNum(container)
    local coinNum = coinCost == 0 and FORGE_MAX_NUM or math.floor(UserInfo.playerInfo.coin / coinCost)
    local equipNum = equipCost == 0 and FORGE_MAX_NUM or math.floor(selfCostEquipNum / equipCost)
    --maxForgeNum = math.min(FORGE_MAX_NUM, math.min(coinNum, equipNum))
    maxForgeNum = math.min(FORGE_MAX_NUM, equipNum)
    
    return maxForgeNum
end
-- 增加製造數量
function EquipBuildPageBase:onAdd(container)
    -- 檢查裝備&金幣數量
    local newForgeNum = math.min(FORGE_MAX_NUM, math.max(forgeNum + 1, 0))
    local totalCostCoin = coinCost * newForgeNum
    local totalCostEquip = equipCost * newForgeNum
    local playerCoin = UserInfo.playerInfo.coin
    local playerEquip = selfCostEquipNum
    if --[[playerCoin >= totalCostCoin and]] playerEquip >= totalCostEquip then
        forgeNum = newForgeNum
        self:refreshBuildInfo(container)
    end
    self:refreshBtnState(container)
end
-- 減少製造數量
function EquipBuildPageBase:onReduce(container)
    forgeNum = math.min(FORGE_MAX_NUM, math.max(forgeNum - 1, 0))
    self:refreshBuildInfo(container)
    self:refreshBtnState(container)
end
-- 製造
function EquipBuildPageBase:onForge(container)
    if forgeNum <= 0 or (coinCost * forgeNum > UserInfo.playerInfo.coin) then
        MessageBoxPage:Msg_Box_Lan("@LackItem")
        return
    end
    self:playSpine(container)
    forgeType = FORGE_TYPE.ONE
end
-- 製造全部
function EquipBuildPageBase:onForgeAll(container)
    self:calForgeAllResult(container)
    sortTable = { }
    for k, v in pairs(forgeAllResult) do
        if tonumber(k) then
            table.insert(sortTable, { id = k, count = v })
        end
    end
    table.sort(sortTable, function(info1, info2)
        if info1 == nil or info2 == nil then
            return false
        end
        if info1.id ~= info2.id then
            return info1.id < info2.id
        end
        return false
    end)
    if #sortTable <= 0 then
        MessageBoxPage:Msg_Box_Lan("@LackItem")
        return
    end
    self:playSpine(container)
    forgeType = FORGE_TYPE.ALL
end
-- 說明頁
function EquipBuildPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_SMELT)
end	
-- 離開頁面
function EquipBuildPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end
----------------packet------------------------
function EquipBuildPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if common:table_hasValue(opcodes, opcode) then
        if opcode == opcodes.EQUIP_FORGE_S then
            local msg = EquipOpr_pb.EquipForgeRes()
            msg:ParseFromString(msgBuff)
            if not msg.success then
                local aaa = 1
            end
            require("Util.RedPointManager")
            for page = RedPointManager.PAGE_IDS.WEAPON_ALL_BTN, RedPointManager.PAGE_IDS.FOOT_ONE_ICON do
                local RedPointCfg = ConfigManager.getRedPointSetting()
                local groupNum = RedPointCfg[page].groupNum
                for i = 1, groupNum do
                    RedPointManager_refreshPageShowPoint(page, i)
                    RedPointManager_setPageSyncDone(page, i)
                end
            end
            self:refreshPage(self.container, false)
        elseif opcode == HP_pb.PLAYER_AWARD_S then
            local PackageLogicForLua = require("PackageLogicForLua")
            PackageLogicForLua.onReceivePlayerAward(msgBuff)
        end
    end
end

function EquipBuildPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            mParentContainer:registerPacket(opcode)
        end
    end
end

function EquipBuildPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            mParentContainer:removePacket(opcode)
        end
    end
end

function EquipBuildPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(container)
    end
end
function EquipBuildPageBase:refreshAllPoint(container)
    -- 分頁紅點
    for k, v in pairs(PAGE_TYPE) do
        NodeHelper:setNodesVisible(container, { ["mTabPoint" .. v] = RedPointManager_getShowRedPoint(typeToPointId[v]) })
    end
    NodeHelper:setNodesVisible(container, { mForgeAllPoint = RedPointManager_getShowRedPoint(typeToPointId[nowPageType]) })
    -- Icon紅點
    local targetTable = equipTable[nowPageType]
    for i = 1, #targetTable do  -- 跳過最低階裝備
        NodeHelper:setNodesVisible(equipListTable[i].panel.container, { mRedPoint = RedPointManager_getShowRedPoint(typeToPointId[nowPageType] + 1, i) })
    end
end
-------------------------------------------------------------------------

function EquipBuildPageBase.onFunction(eventName, container)
    if eventName == option.handlerMap.onRefresh then
        EquipBuildPageBase:onRefresh(container)
    elseif eventName == option.handlerMap.onCreate then
        EquipBuildPageBase:onBuild(container)
    elseif eventName == option.handlerMap.onForge then
        EquipBuildPageBase:onForge(container)
    elseif eventName == option.handlerMap.onForgeAll then
        EquipBuildPageBase:onForgeAll(container)
    elseif eventName == option.handlerMap.onAdd then
        EquipBuildPageBase:onAdd(container)
    elseif eventName == option.handlerMap.onReduce then
        EquipBuildPageBase:onReduce(container)
    elseif eventName == option.handlerMap.onEquip1 then
        EquipBuildPageBase:onEquip1(container)
    elseif eventName == option.handlerMap.onEquip2 then
        EquipBuildPageBase:onEquip2(container)
    elseif string.find(eventName, "onPageBuild") then
        EquipBuildPageBase:onPageBuild(container, eventName)
    end
end

-- 設定需要道具item, 左至右顯示 (錢幣, 鑽石, 道具1, 道具2)
function EquipEnhancePage_setNeedResource(container, content1)

end

function EquipEnhancePage_showRequirementInfo(container, infoIndex, itemId, resMainType)    
    local itemCfg = {
			type 		= resMainType * 10000, -- getResInfoByTypeAndId 的 type, 判斷上是用type * 10000去判斷的
			itemId 		= itemId,
			count 		= tonumber(1),
		}      
    GameUtil:showTip(container:getVarNode("mPic" .. infoIndex), itemCfg)
end

function EquipBuildPage_calIsShowIconRedPoint(parentId, group)
    --if group <= 1 then
    --    return false
    --end
    local pageType = idToPageType[parentId]
    if not pageType then
        return false
    end
    EquipBuildPageBase:initEquipTable(container)
    if not equipTable or #equipTable <= 0 then
        EquipBuildPageBase:initEquipTable(container)
    end

    local userCoin = UserInfo.playerInfo.coin or 0
    local targetTable = equipTable[pageType]
    if not targetTable[group] then
        return false
    end

    local buildEquipcfg = ConfigManager:getEquipCfg()[targetTable[group].id]
    local costId, costNum, costCoin = nil, nil, 0
    for j = 1, #buildEquipcfg.fixedMaterial do  -- 消耗的資源
        if tonumber(buildEquipcfg.fixedMaterial[j].type) == 40000 then
            costId = tonumber(buildEquipcfg.fixedMaterial[j].itemId) -- 消耗裝備id(單件)
            costNum = tonumber(buildEquipcfg.fixedMaterial[j].count) -- 消耗裝備數量(單件)
        elseif tonumber(buildEquipcfg.fixedMaterial[j].type) == 10000 and tonumber(buildEquipcfg.fixedMaterial[j].itemId) == 1002 then  -- 金幣
            costCoin = tonumber(buildEquipcfg.fixedMaterial[j].count)    -- 消耗金幣(單件)
        end
    end
    if costId and costNum then
        userNum = #UserEquipManager:getUserEquipByCfgId(costId)-- + (forgeAllResult[costId] or 0)
        if userNum >= costNum and userCoin >= costCoin then
            return true
        end
    end
    return false
end

function EquipBuildPage_calIsShowTypeRedPoint(parentId)
    local pageType = idToPageType[parentId]
    if not pageType then
        return false
    end
    if not equipTable or #equipTable <= 0 then
        EquipBuildPageBase:initEquipTable(container)
    end
    local targetTable = equipTable[pageType]
    for i = 1, #targetTable do  -- 跳過最低階裝備
        local show = EquipBuildPage_calIsShowIconRedPoint(parentId, i)
        if show then
            return true
        end
    end
    return false
end

return EquipBuildPageBase
