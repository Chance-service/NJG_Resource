----------------------------------------------------------------------------------
--[[
	英雄阵容
--]]
----------------------------------------------------------------------------------
require("NgHeroPageManager")
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local FormationManager = require("FormationManager")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local RoleOpr_pb = require("RoleOpr_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local NgHeadIconItem = require("NgHeadIconItem")
local EquipPageBase = { }
local CONST = require("Battle.NewBattleConst")

local option = {
    ccbiFile = "EquipmentPage_new.ccbi",
    handlerMap =
    {
        onFilter = "onFilter",
        onHero = "onHero",
        onGallery = "onGallery",
        onCollection = "onCollection",
        onTeam = "onTeam",
        onViewExp = "onViewExp",
        onPersonalConfidence = "onPersonalConfidence",
        onRecharge = "onRecharge",
        onBuyGold = "onBuyGold",
    },
    opcodes =
    {
        ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
        ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
        ROLE_EMPLOY_C = HP_pb.ROLE_EMPLOY_C,
        ROLE_EMPLOY_S = HP_pb.ROLE_EMPLOY_S,
        ROLE_UPGRADE_STAGE_S = HP_pb.ROLE_UPGRADE_STAGE_S,
        ACTIVITY152_S = HP_pb.ACTIVITY152_S,
        FETCH_ARCHIVE_INFO_C = HP_pb.FETCH_ARCHIVE_INFO_C,
        FETCH_ARCHIVE_INFO_S = HP_pb.FETCH_ARCHIVE_INFO_S,
        OPEN_FETTER_C = HP_pb.OPEN_FETTER_C,
        OPEN_FETTER_S = HP_pb.OPEN_FETTER_S,
    }
}
for i = 0, 5 do
    option.handlerMap["onElement" .. i] = "onElement"
end
for i = 0, 4 do
    option.handlerMap["onClass" .. i] = "onClass"
end

local thisPageName = "EquipmentPage"
local thisPageContainer = nil

local _mercenaryInfos = { }-- 佣兵数据表
_mercenaryInfos.roleInfos=UserMercenaryManager:getMercenaryStatusInfos()
local CARD_WIDTH = 170
local CARD_HEIGHT = 270
local headIconSize = CCSize(CARD_WIDTH, CARD_HEIGHT)

local FILTER_WIDTH = 500
local FILTER_OPEN_HEIGHT = 142
local FILTER_CLOSE_HEIGHT = 74
local filterOpenSize = CCSize(FILTER_WIDTH, FILTER_OPEN_HEIGHT)
local filterCloseSize = CCSize(FILTER_WIDTH, FILTER_CLOSE_HEIGHT)

--------------------------------------------------------------------
local mCurHeroElement = 0
local mCurHeroClass = 0
local mCurGalleryElement = 0
local mCurGalleryClass = 0

EquipPageBase.PAGE_TYPE = {
    NONE = -1,
    HERO_PAGE = 1,
    GALLERY_PAGE = 2,
    COLLECTION_PAGE = 3,
}
local pageType = EquipPageBase.PAGE_TYPE.NONE

EquipPageBase.INIT_TABLE = {
    HERO_PAGE = true,
    GALLERY_PAGE = true,
    COLLECTION_PAGE = true,
}

--------------------------------------------------------------------
local GalleryItem = {
    ccbiFile = "EquipmentPage_new_content.ccbi",
}

local GalleryDatas = { }
local GalleryItems = { }
local GalleryCardItems = { }

function GalleryItem:onRefreshContent(ccbRoot)
    if self.init then
        self.container = ccbRoot:getCCBFileNode()
        local countTable = { }
        local archiveCfg = ConfigManager.getIllustrationCfg()
        -- 創建卡牌
        for i = 1, #archiveCfg do
            local _type = archiveCfg[i]._type
            GalleryCardItems[_type] = GalleryCardItems[_type] or { }
            local parentNode = self.container:getVarNode("mCardNode" .. _type)
            local item = NgHeadIconItem:createByItemId(archiveCfg[i].roleId, parentNode, GameConfig.NgHeadIconType.GALLERY_PAGE)
            table.insert(GalleryCardItems[_type], item)
            --
            local merStatus = UserMercenaryManager:getMercenaryStatusByItemId(archiveCfg[i].roleId)
            if merStatus.roleStage == Const_pb.IS_ACTIVITE then
                countTable[_type] = countTable[_type] and countTable[_type] + 1 or 1
            else
                NodeHelper:setNodeIsGray(item.container, { mIcon = true, mFrame = true, mElement = true })
            end
        end
        -- 計算位置
        local totalHeight = 0
        for i = 1, #GalleryCardItems do
            local contentHeight = math.ceil(#GalleryCardItems[i] / 4) * CARD_HEIGHT
            local addHeight = contentHeight + 74
            local qualityNode = self.container:getVarNode("mNode" .. i)
            qualityNode:setPositionY(totalHeight)
            totalHeight = totalHeight + addHeight
            qualityNode:setContentSize(CCSize(qualityNode:getContentSize().width, addHeight))
            local qualityContent = self.container:getVarNode("mCardNode" .. i)
            qualityContent:setContentSize(CCSize(qualityContent:getContentSize().width, contentHeight))
            local qualityTitle = self.container:getVarNode("mTitleNode" .. i)
            qualityTitle:setPositionY(contentHeight)
            for card = 1, #GalleryCardItems[i] do
                local posX = (((card % 4 == 0) and 4 or card % 4) - 1) * CARD_WIDTH
                local posY = contentHeight - math.floor((card - 1) / 4) * CARD_HEIGHT - CARD_HEIGHT
                GalleryCardItems[i][card].container:setPosition(ccp(posX, posY))
            end
        end
        GalleryItems[1].node:setContentSize(CCSize(GalleryItems[1].node:getContentSize().width, totalHeight))
        --
        for i = 1, 2 do
            NodeHelper:setStringForLabel(self.container, { ["mNumTxt" .. i] = (countTable[i] or 0) .. "/" .. #GalleryCardItems[i] })
        end
        self.init = false
    end
end

function GalleryItem:onRefreshGalleryScrollView(element, class)
    -- 計算顯示數量
    local showNum = { }
    local haveNum = { }
    for i = #GalleryCardItems, 1, -1 do
        showNum[i] = 0
        for card = 1, #GalleryCardItems[i] do
            if (GalleryCardItems[i][card].roleData.element == element or element == 0) and 
               (GalleryCardItems[i][card].roleData.class == class or class == 0) then
                showNum[i] = showNum[i] + 1
            end
        end
    end
    -- 計算位置
    local totalHeight = 0
    for i = 1, #GalleryCardItems do
        local contentHeight = math.ceil(showNum[i] / 4) * CARD_HEIGHT
        local addHeight = contentHeight + 74
        local qualityNode = GalleryItems[1].cls.container:getVarNode("mNode" .. i)
        qualityNode:setPositionY(totalHeight)
        totalHeight = totalHeight + addHeight
        qualityNode:setContentSize(CCSize(qualityNode:getContentSize().width, addHeight))
        local qualityContent = GalleryItems[1].cls.container:getVarNode("mCardNode" .. i)
        qualityContent:setContentSize(CCSize(qualityContent:getContentSize().width, contentHeight))
        local qualityTitle = GalleryItems[1].cls.container:getVarNode("mTitleNode" .. i)
        qualityTitle:setPositionY(contentHeight)

        local visibleCardIdx = 1
        haveNum[i] = 0
        for card = 1, #GalleryCardItems[i] do
            if (GalleryCardItems[i][card].roleData.element == element or element == 0) and 
               (GalleryCardItems[i][card].roleData.class == class or class == 0) then
                GalleryCardItems[i][card].container:setVisible(true)
                local posX = (((visibleCardIdx % 4 == 0) and 4 or visibleCardIdx % 4) - 1) * CARD_WIDTH
                local posY = contentHeight - math.floor((visibleCardIdx - 1) / 4) * CARD_HEIGHT - CARD_HEIGHT
                GalleryCardItems[i][card].container:setPosition(ccp(posX, posY))
                visibleCardIdx = visibleCardIdx + 1
                --
                local merStatus = UserMercenaryManager:getMercenaryStatusByItemId(GalleryCardItems[i][card].itemId)
                if merStatus.roleStage == Const_pb.IS_ACTIVITE then
                    haveNum[i] = haveNum[i] + 1
                end
            else
                GalleryCardItems[i][card].container:setVisible(false)
            end
        end
    end
    GalleryItems[1].node:setContentSize(CCSize(GalleryItems[1].node:getContentSize().width, totalHeight))
    --
    for i = 1, 2 do
        NodeHelper:setStringForLabel(GalleryItems[1].cls.container, { ["mNumTxt" .. i] = haveNum[i] .. "/" .. showNum[i] })
    end
end
--------------------------------------------------------------------
local CollectionItem = {
    ccbiFile = "EquipmentPage_new_content2.ccbi",
}
local CollectionBtnState = {
    LOCK = 1,
    CAN_UNLOCK = 2,
    UNLOCK = 3,
}
local CollectionItems = { }
local CollectionCardItems = { }

function CollectionItem:onRefreshContent(ccbRoot) 
    local container = ccbRoot:getCCBFileNode()
    local haveCount = 0
    local fetterCfg = ConfigManager.getRelationshipCfg()
    local isInit = true
    local containerId = self.id
    for i = 1, #CollectionItems do
        if container == CollectionItems[i].cls.container then
            isInit = false
            containerId = i
            break
        end
    end
    self.showContainer = container
    --CollectionItems[self.id].cls.containerId = containerId
    local itemIds = fetterCfg[self.id].team
    if isInit then
        self.container = container
        -- 創建卡牌
        CollectionItems[self.id] = CollectionItems[self.id] or { }
        local parentNode = self.container:getVarNode("mCollectionContent")
        CollectionCardItems[self.id] = { }
        for card = 1, #itemIds do
            local item = NgHeadIconItem:createByItemId(tonumber(itemIds[card]), parentNode, GameConfig.NgHeadIconType.COLLECTION_PAGE)
            table.insert(CollectionCardItems[self.id], item)
            item.container:setPositionX(CARD_WIDTH * (card - 1))
            --
            local merStatus = UserMercenaryManager:getMercenaryStatusByItemId(itemIds[card])
            if merStatus.roleStage ~= Const_pb.IS_ACTIVITE then
                NodeHelper:setNodeIsGray(item.container, { mIcon = true, mFrame = true, mElement = true })
                for i = 1, 13 do
                    local childNum = item.container:getChildrenCount()
                    for j = 1, childNum do
                        NodeHelper:setNodeIsGray(item.container, { ["mStar" .. i .. "_" .. j] = true })
                    end
                end
            else
                haveCount = haveCount + 1
            end
        end
    else
        for card = 1, #CollectionCardItems[containerId] do
            CollectionCardItems[containerId][card].itemId = itemIds[card]
            CollectionCardItems[containerId][card].container.itemId = itemIds[card]
            NgHeadIconItem:refreshByItemId(CollectionCardItems[containerId][card])
            -- 設定灰階圖片
            local merStatus = UserMercenaryManager:getMercenaryStatusByItemId(CollectionCardItems[containerId][card].itemId)
            if merStatus.roleStage ~= Const_pb.IS_ACTIVITE then
                NodeHelper:setNodeIsGray(CollectionCardItems[containerId][card].container, { mIcon = true, mFrame = true, mElement = true })
                for i = 1, 13 do
                    local childNum = CollectionCardItems[containerId][card].container:getChildrenCount()
                    for j = 1, childNum do
                        NodeHelper:setNodeIsGray(CollectionCardItems[containerId][card].container, { ["mStar" .. i .. "_" .. j] = true })
                    end
                end
            else
                NodeHelper:setNodeIsGray(CollectionCardItems[containerId][card].container, { mIcon = false, mFrame = false, mElement = false })
                for i = 1, 13 do
                    local childNum = CollectionCardItems[containerId][card].container:getChildrenCount()
                    for j = 1, childNum do
                        NodeHelper:setNodeIsGray(CollectionCardItems[containerId][card].container, { ["mStar" .. i .. "_" .. j] = false })
                    end
                end
                haveCount = haveCount + 1
            end
        end
    end
    NodeHelper:setStringForLabel(self.showContainer, { ["mCollectionNum"] = haveCount .. "/" .. #itemIds,
                                              ["mCollectionTitle"] = common:getLanguageString(fetterCfg[self.id].name) })
    self:refreshAttrLabel()
    self:refreshBtnState()
end

function CollectionItem:refreshAttrLabel()
    local fetterCfg = ConfigManager.getRelationshipCfg()
    local formulaType = fetterCfg[self.id].formula
    local attrs = fetterCfg[self.id].property
    for i = 1, 3 do
        if attrs[i] then
            local attrData = common:split(attrs[i], "_")
            local attrValue = NgHeroPageManager_calFetterAttrValue(formulaType, attrData[2], attrData[3], self.id)
            NodeHelper:setNodesVisible(self.showContainer, { ["mAttrNode" .. i] = true })
            NodeHelper:setSpriteImage(self.showContainer, { ["mAttrImg" .. i] = "attri_" .. attrData[1] .. ".png" })
            local parentNode = self.showContainer:getVarNode("mAttrTxtNode" .. i)
            parentNode:removeAllChildrenWithCleanup(true)
            local str1 = common:getLanguageString("@AttrName_" .. attrData[1])
            local str2 = attrValue .. (tonumber(attrData[2]) == 1 and "%" or "")
            local htmlLabel = CCHTMLLabel:createWithString(common:fill(FreeTypeConfig[4003].content, str1, str2), CCSizeMake(250, 50), "Barlow-SemiBold")
            local htmlSize = htmlLabel:getContentSize()
            htmlLabel:setPosition(ccp(0, 0))
            htmlLabel:setAnchorPoint(ccp(0.0, 0.5))
            parentNode:addChild(htmlLabel)
        else
            NodeHelper:setNodesVisible(self.showContainer, { ["mAttrNode" .. i] = false })
        end
    end
end

function CollectionItem:refreshBtnState()
    EquipPageBase:setCollectionBtnState(self.showContainer, NgHeroPageManager_getIsUnlockFetter(self.id) and CollectionBtnState.UNLOCK or
                                                   NgHeroPageManager_getIsShowFetterRedPoint(self.id) and CollectionBtnState.CAN_UNLOCK or
                                                   CollectionBtnState.LOCK, self.id)
end

function CollectionItem:onCollectionUnlock(container)
    local msg = RoleOpr_pb.HPOpenFetterReq()
    msg.fetterId = self.id
    common:sendPacket(HP_pb.OPEN_FETTER_C, msg, true)
end

function CollectionItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end
--------------------------------------------------------------------
function EquipPageBase:subscriberCallFun(data)
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
end
function EquipPageBase:onEnter(container)
    thisPageContainer = container
    ----------------------
    FormationManager:addSubscriber(thisPageName, EquipPageBase.subscriberCallFun)
    ----------------------

    container:registerMessage(MSG_SEVERINFO_UPDATE)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container:registerMessage(MSG_MAINFRAME_POPPAGE)
    container:registerMessage(MSG_REFRESH_REDPOINT)

    container.mScrollView = container:getVarScrollView("mHeroContent")
    container.mGalleryScrollView = container:getVarScrollView("mGalleryContent")
    container.mCollectionScrollView = container:getVarScrollView("mCollectionContent")

    self:registerPacket(container)

    -- 設定玩家頭像, 資料
    self:setPlayerIcon(container)
    self:setPlayerInfo(container)
    self:RefreshExpBar(container)
    NodeHelper:setNodesVisible(container, { mExp = false, mPlayerNew = false })
    -- scrollview, 背景自適應
    local scale9Sprite = container:getVarScale9Sprite("mScale9Bg")
    NodeHelper:autoAdjustResizeScale9Sprite(scale9Sprite)
    NodeHelper:autoAdjustResizeScrollview(container.mScrollView)
    NodeHelper:autoAdjustResizeScrollview(container.mGalleryScrollView)
    NodeHelper:autoAdjustResizeScrollview(container.mCollectionScrollView)
    -- 設定過濾按鈕
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    filterBg:setContentSize(filterCloseSize)
    NodeHelper:setNodesVisible(container, { mClassNode = false })
    -- 預設開啟英雄列表
    self:onHero(container)

    self:checkActivityHero(container)

    common:sendEmptyPacket(HP_pb.FETCH_ARCHIVE_INFO_C, false)

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["EquipPageBase"] = container
    GuideManager.PageInstRef["EquipPageBase"] = self

    -- 刷新紅點顯示
    self:refreshAllPoint(container)
end


function EquipPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function EquipPageBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
---------------------------------------------------------------------------------
-- 英雄列表
function EquipPageBase:refreshHeroItems(container) 
    -- 更新全部角色資訊
    _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
    if _mercenaryInfos.roleInfos == nil then
        return
    end
    -- 角色排序
    local roleInfos = _mercenaryInfos.roleInfos
    self:sortData(roleInfos)
    -- 重新建立scrollview
    self:rebuildHeroItem(container)
end
function EquipPageBase:rebuildHeroItem(container)
    self:clearHeroItem(container)
    self:buildHeroScrollView(container)
end
function EquipPageBase:clearHeroItem(container)
    container.mScrollView:removeAllCell()
end
function EquipPageBase:buildHeroScrollView(container)
    local cell = nil
    EquipPageBase.mAllHeroItem = { }
    for i = 1, #_mercenaryInfos.roleInfos do
        local roleInfo = UserMercenaryManager:getUserMercenaryById(_mercenaryInfos.roleInfos[i].roleId)
        -- 已啟用的英雄
        if roleInfo and _mercenaryInfos.roleInfos[i].type ~= Const_pb.RETINUE and _mercenaryInfos.roleInfos[i].roleStage == Const_pb.IS_ACTIVITE then 
            local iconItem = NgHeadIconItem:createCCBFileCell(_mercenaryInfos.roleInfos[i].roleId, i, container.mScrollView, GameConfig.NgHeadIconType.HERO_PAGE)
            NgHeadIconItem:setRoleData(iconItem)
            table.insert(self.mAllHeroItem, iconItem--[[common:deepCopy(iconItem)]])
            local GuideManager = require("Guide.GuideManager")
            if roleInfo.itemId == 1 then
                GuideManager.PageContainerRef["EquipmentPageFire1_cell"] = iconItem.cell
            end
        end
    end
    container.mScrollView:orderCCBFileCells()
    --EquipPageBase.mAllHeroItem = items

    if not self.mAllHeroItem then
        self.mAllHeroItem = { }
    end
end
---------------------------------------------------------------------------------
-- 英雄圖鑑
function EquipPageBase:refreshGalleryItems(container)
    self:rebuildGalleryItem(container)
end
function EquipPageBase:rebuildGalleryItem(container)
    self:clearGalleryItem(container)
    self:buildGalleryScrollView(container)
end
function EquipPageBase:clearGalleryItem(container)
    container.mGalleryScrollView:removeAllCell()
    GalleryDatas = { }
    GalleryItems = { }
    GalleryCardItems = { }
end
function EquipPageBase:buildGalleryScrollView(container)
    local archiveCfg = ConfigManager.getIllustrationCfg()
    for i = 1, #archiveCfg do
        GalleryDatas[archiveCfg[i]._type] = GalleryDatas[archiveCfg[i]._type] or { }
        table.insert(GalleryDatas[archiveCfg[i]._type], archiveCfg[i])
    end
    require("NgArchivePage")
    NgArchivePage_setData(GalleryDatas)
    local cell = CCBFileCell:create()
    cell:setCCBFile(GalleryItem.ccbiFile)
    local handler = common:new( { init = true }, GalleryItem)
    cell:registerFunctionHandler(handler)
    container.mGalleryScrollView:addCell(cell)
    GalleryItems[1] = { cls = handler, node = cell }

    container.mGalleryScrollView:orderCCBFileCells()
end
function EquipPageBase:refreshCardGray(container)
    for _type = 1, #GalleryCardItems do
        for card = 1, #GalleryCardItems[_type] do
            local merStatus = UserMercenaryManager:getMercenaryStatusByItemId(GalleryCardItems[_type][card].roleData.itemId)
            if merStatus.roleStage == Const_pb.IS_ACTIVITE then
                NodeHelper:setNodeIsGray(GalleryCardItems[_type][card].container, { mIcon = false, mFrame = false, mElement = false })
            else
                NodeHelper:setNodeIsGray(GalleryCardItems[_type][card].container, { mIcon = true, mFrame = true, mElement = true })
            end
        end
    end
end
---------------------------------------------------------------------------------
-- 英雄羈絆
function EquipPageBase:refreshCollectionItems(container)
    self:rebuildCollectionItem(container)
end
function EquipPageBase:rebuildCollectionItem(container)
    self:clearCollectionItem(container)
    self:buildCollectionScrollView(container)
end
function EquipPageBase:clearCollectionItem(container)
    container.mCollectionScrollView:removeAllCell()
    --GalleryDatas = { }
    CollectionItems = { }
    CollectionCardItems = { }
end
function EquipPageBase:buildCollectionScrollView(container)
    local fetterCfg = ConfigManager.getRelationshipCfg()
    for i = 1, #fetterCfg do
        if math.floor(fetterCfg[i].order / 1000) == 1 then
            local cell = CCBFileCell:create()
            cell:setCCBFile(CollectionItem.ccbiFile)
            local handler = common:new( { id = i, isInit = true }, CollectionItem)
            cell:registerFunctionHandler(handler)
            container.mCollectionScrollView:addCell(cell)
            CollectionItems[i] = { cls = handler, node = cell }

            container.mCollectionScrollView:orderCCBFileCells()
        end
    end
end
function EquipPageBase:setCollectionBtnState(container, state, fetterId)
    NodeHelper:setNodesVisible(container, { mRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_FETTER_BTN, fetterId) })
    NodeHelper:setMenuItemEnabled(container, "mUnlockBtn", state == CollectionBtnState.CAN_UNLOCK)
    NodeHelper:setStringForLabel(container, { mUnlockTxt = (state == CollectionBtnState.CAN_UNLOCK) and common:getLanguageString("@Activated") or
                                                           (state == CollectionBtnState.LOCK) and common:getLanguageString("@Unactivated") or
                                                           (state == CollectionBtnState.UNLOCK) and common:getLanguageString("@LevelStr", NgHeroPageManager_getFetterShowLevel(fetterId))--[[common:getLanguageString("@FetterBtnActivated")]]  })
end
---------------------------------------------------------------------------------
function EquipPageBase:refreshPage(container)

end

function EquipPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    local opcode = container:getRecPacketOpcode()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName then
            if extraParam == "refreshIcon" then
                self:setPlayerIcon(container)
            end
            if extraParam == "refreshScrollView" then
                if pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE then
                    self:refreshHeroItems(container)
                    self:onElement(container, "onElement" .. mCurHeroElement)
                    self:onClass(container, "onClass" .. mCurHeroClass)
                end
            end
        end
        self:setPlayerInfo(container)
    elseif typeId == MSG_MAINFRAME_POPPAGE then
        NgHeadIconItem_setPageType(pageType)
        container.mScrollView:refreshAllCell()
        if pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE then
            self:refreshCardGray(container)
        end
    elseif typeId == MSG_REFRESH_REDPOINT then
        -- 刷新紅點顯示
        self:refreshAllPoint(container)
    end
end

function EquipPageBase:sortData(info)
    _mercenaryInfos.roleInfos = info
    if info == nil or #info == 0 then
        return
    end

    table.sort(info, function(info1, info2)
        if info1 == nil or info2 == nil then
            return false
        end
        local mInfo = UserMercenaryManager:getUserMercenaryInfos()
        local mInfo1 = mInfo[info1.roleId]
        local mInfo2 = mInfo[info2.roleId]
        if mInfo1 == nil then
            return false
        end
        if mInfo2 == nil then
            return true
        end
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then  -- 新手教學中火1強制放最前面
            if info1.itemId == 1 then
                return true
            end
            if info2.itemId == 1 then
                return false
            end
        end
        if (info1.status == Const_pb.FIGHTING) and (info2.status ~= Const_pb.FIGHTING) then
            return true
        elseif (info1.status ~= Const_pb.FIGHTING) and (info2.status == Const_pb.FIGHTING) then
            return false
        elseif mInfo1.level ~= mInfo2.level then
            return mInfo1.level > mInfo2.level
        elseif mInfo1.starLevel ~= mInfo2.starLevel then
            return mInfo1.starLevel > mInfo2.starLevel
        elseif mInfo1.fight ~= mInfo2.fight then
            return mInfo1.fight > mInfo2.fight
        elseif mInfo1.singleElement ~= mInfo2.singleElement then
            return mInfo1.singleElement < mInfo2.singleElement
        end
        return false
    end )

    local t = { }
    local info = FormationManager:getMainFormationInfo()

    for i = 1, #info.roleNumberList do
        if info.roleNumberList[i] > 0 then
            local index = EquipPageBase:getMercenaryIndex(info.roleNumberList[i])
            if index > 0 then
                --local data = table.remove(_mercenaryInfos.roleInfos, index)
                --table.insert(t, data)
            end
        end
    end

    for k, v in pairs(_mercenaryInfos.roleInfos) do
        table.insert(t, v)
    end
    _mercenaryInfos.roleInfos = t

    return t
end

function EquipPageBase:getMercenaryIndex(roleId)
    local index = 0
    for i = 1, #_mercenaryInfos.roleInfos do
        if _mercenaryInfos.roleInfos[i].itemId == roleId then
            index = i
            break
        end
    end
    return index
end

-- 接收服务器回包
function EquipPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(msgBuff)
        UserMercenaryManager:setMercenaryStatusInfos(msg.roleInfos)
        _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
        EquipPageBase:refreshHeroItems(thisPageContainer)
        PageManager.setAllNotice()
    elseif opcode == HP_pb.ROLE_UPGRADE_STAGE_S or opcode == HP_pb.ROLE_EMPLOY_S then
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    elseif opcode == HP_pb.FETCH_ARCHIVE_INFO_S then
        local msg = RoleOpr_pb.HPArchiveInfoRes()
        local msgbuff = container:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        NgHeroPageManager_setServerFetterData(msg)
        PageManager.setAllNotice()

        require("TransScenePopUp")
        TransScenePopUp_closePage()
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            PageManager.pushPage("NewbieGuideForcedPage")
        end
    elseif opcode == HP_pb.OPEN_FETTER_S then
        local msg = RoleOpr_pb.HPOpenFetterRes()
        local msgbuff = container:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        NgHeroPageManager_openFetter(msg)
        local containerId = CollectionItems[msg.fetterId].cls.containerId
        if CollectionItems[msg.fetterId].cls.showContainer then
            CollectionItems[msg.fetterId].cls:refreshBtnState()
        end
        common:sendEmptyPacket(HP_pb.FETCH_ARCHIVE_INFO_C, false)
        MessageBoxPage:Msg_Box(common:getLanguageString("@HasActivationHalo"))
    end
end

function EquipPageBase:onExit(container)
    pageType = EquipPageBase.PAGE_TYPE.NONE
    mCurHeroElement = 0
    mCurHeroClass = 0
    mCurGalleryElement = 0
    mCurGalleryClass = 0
    --------------
    FormationManager:removeSubscriber(thisPageName)
    --------------
    container:removeMessage(MSG_SEVERINFO_UPDATE)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container:removeMessage(MSG_MAINFRAME_POPPAGE)
    container:removeMessage(MSG_REFRESH_REDPOINT)

    container.mScrollView:removeAllCell()
    container.mGalleryScrollView:removeAllCell()
    container.mCollectionScrollView:removeAllCell()
    self:removePacket(container)

    for k, v in pairs(EquipPageBase.INIT_TABLE) do
        EquipPageBase.INIT_TABLE[k] = true
    end

    onUnload(thisPageName, container)
    GameUtil:purgeCachedData()
end

function EquipPageBase:setTabState(container)
    NodeHelper:setMenuItemSelected(container, {
        mHeroTab = pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE,
        mGalleryTab = pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE,
        mCollectionTab = pageType == EquipPageBase.PAGE_TYPE.COLLECTION_PAGE,
    })
    NodeHelper:setNodesVisible(container, {
        mHeroOnImg = pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE,
        mGalleryOnImg = pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE,
        mCollectionOnImg = pageType == EquipPageBase.PAGE_TYPE.COLLECTION_PAGE,
    })
    NodeHelper:setColorForLabel(container, { 
        mHeroTxt = pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE and GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT,
        mGalleryTxt = pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE and GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT,
        mCollectionTxt = pageType == EquipPageBase.PAGE_TYPE.COLLECTION_PAGE and GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT,
    })
end

function EquipPageBase:setPageState(container)
    NodeHelper:setNodesVisible(container, {
        mHeroPageNode = pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE,
        mGalleryPageNode = pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE,
        mCollectionPageNode = pageType == EquipPageBase.PAGE_TYPE.COLLECTION_PAGE,
        --
        mElementNode = pageType ~= EquipPageBase.PAGE_TYPE.COLLECTION_PAGE,
    })
end

function EquipPageBase:onHero(container)
    if pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE then  
        self:setTabState(container)
        return
    end
    local GuideManager = require("Guide.GuideManager")
    if not GuideManager.isInGuide then
        container:runAnimation("OpenAni_Hero")
    end
    pageType = EquipPageBase.PAGE_TYPE.HERO_PAGE
    NgHeadIconItem_setPageType(GameConfig.NgHeadIconType.HERO_PAGE)
    self:setTabState(container)
    self:setPageState(container)
    if EquipPageBase.INIT_TABLE.HERO_PAGE then
        self:refreshHeroItems(container)
        EquipPageBase.INIT_TABLE.HERO_PAGE = false
    end
    self:closeFilter(container)
    self:onElement(container, "onElement0") 
    self:onClass(container, "onClass0") 
end

function EquipPageBase:onGallery(container)
    if pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE then  
        self:setTabState(container)
        return
    end
    local GuideManager = require("Guide.GuideManager")
    if not GuideManager.isInGuide then
        container:runAnimation("OpenAni_Gallery")
    end
    pageType = EquipPageBase.PAGE_TYPE.GALLERY_PAGE
    NgHeadIconItem_setPageType(GameConfig.NgHeadIconType.GALLERY_PAGE)
    self:setTabState(container)
    self:setPageState(container)
    if EquipPageBase.INIT_TABLE.GALLERY_PAGE then
        self:refreshGalleryItems(container)
        EquipPageBase.INIT_TABLE.GALLERY_PAGE = false
    else
        self:refreshCardGray(container)
    end
    self:closeFilter(container)
    self:onElement(container, "onElement0")
    self:onClass(container, "onClass0") 
end

function EquipPageBase:onCollection(container)
    if pageType == EquipPageBase.PAGE_TYPE.COLLECTION_PAGE then  
        self:setTabState(container)
        return
    end
    local GuideManager = require("Guide.GuideManager")
    if not GuideManager.isInGuide then
        container:runAnimation("OpenAni_Collection")
    end
    pageType = EquipPageBase.PAGE_TYPE.COLLECTION_PAGE
    NgHeadIconItem_setPageType(GameConfig.NgHeadIconType.COLLECTION_PAGE)
    self:setTabState(container)
    self:setPageState(container)
    --if EquipPageBase.INIT_TABLE.COLLECTION_PAGE then
        self:refreshCollectionItems(container)
    --    EquipPageBase.INIT_TABLE.COLLECTION_PAGE = false
    --end
end

function EquipPageBase:onTeam(container)
    require("NgBattleDataManager")
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.EDIT_FIGHT_TEAM)
    --PageManager.pushPage("EditMercenaryTeamPage")
    PageManager.pushPage("NgBattleEditTeamPage")
end

function EquipPageBase:onFilter(container)
    local isShowClass = container:getVarNode("mClassNode"):isVisible()
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    if isShowClass then
        filterBg:setContentSize(filterCloseSize)
        NodeHelper:setNodesVisible(container, { mClassNode = false })
    else
        filterBg:setContentSize(filterOpenSize)
        NodeHelper:setNodesVisible(container, { mClassNode = true })
    end
end

function EquipPageBase:closeFilter(container)
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    filterBg:setContentSize(filterCloseSize)
    NodeHelper:setNodesVisible(container, { mClassNode = false })
end

function EquipPageBase:onElement(container, eventName)
    local element = tonumber(eventName:sub(-1))
    if pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE then
        mCurHeroElement = element
    elseif pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE then
        mCurGalleryElement = element
    end
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    if pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE then
        container.mScrollView:orderCCBFileCells()
    elseif pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE then
        container.mGalleryScrollView:orderCCBFileCells()
    end
end

function EquipPageBase:onClass(container, eventName)
    local class = tonumber(eventName:sub(-1))
    if pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE then
        mCurHeroClass = class
    elseif pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE then
        mCurGalleryClass = class
    end
    self:setFilterVisible(container)
    for i = 0, 4 do
        container:getVarSprite("mClass" .. i):setVisible(class == i)
    end
    if pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE then
        container.mScrollView:orderCCBFileCells()
    elseif pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE then
        container.mGalleryScrollView:orderCCBFileCells()
    end
end

function EquipPageBase:setFilterVisible(container)
    if pageType == EquipPageBase.PAGE_TYPE.HERO_PAGE then
        if self.mAllHeroItem then
            for i = 1, #self.mAllHeroItem do
                local isVisible = (mCurHeroElement == self.mAllHeroItem[i].roleData.element or mCurHeroElement == 0) and
                                  (mCurHeroClass == self.mAllHeroItem[i].roleData.class or mCurHeroClass == 0)
                self.mAllHeroItem[i].cell:setVisible(isVisible)
                self.mAllHeroItem[i].cell:setContentSize(isVisible and headIconSize or CCSize(0, 0))
            end
        end
    elseif pageType == EquipPageBase.PAGE_TYPE.GALLERY_PAGE then
        GalleryItem:onRefreshGalleryScrollView(mCurGalleryElement, mCurGalleryClass)
    end
end

function EquipPageBase:checkActivityHero(container)
    local allHeroState = UserMercenaryManager:getMercenaryStatusInfos()
    for i = 1, #allHeroState do
        if allHeroState[i].roleStage == Const_pb.CAN_ACTIVITE then
            local msg = RoleOpr_pb.HPRoleEmploy()
            msg.roleId = allHeroState[i].roleId
            local pb = msg:SerializeToString()
            PacketManager:getInstance():sendPakcet(HP_pb.ROLE_EMPLOY_C, pb, #pb, true)
        end
    end
end
----------------------------------------------------------
-- 玩家資訊
function EquipPageBase:setPlayerIcon(container)
    local roleIcon = ConfigManager.getRoleIconCfg()
    local trueIcon = GameConfig.headIconNew or UserInfo.playerInfo.headIcon
    local icon, bgIcon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)

    if not roleIcon[trueIcon] then
        local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
        if NodeHelper:isFileExist(icon) then
            NodeHelper:setSpriteImage(container, { mPlayerSprite = icon })
        end
    else
        NodeHelper:setSpriteImage(container, { mPlayerSprite = roleIcon[trueIcon].MainPageIcon })
    end
end

function EquipPageBase:setPlayerInfo(container)
    local lb2Str = {
        mName = UserInfo.roleInfo.name,
        mGold = GameUtil:formatNumber(UserInfo.playerInfo.coin),
        mDiamond = GameUtil:formatNumber(UserInfo.playerInfo.gold),
        mLV = UserInfo.getStageAndLevelStr(),
        mFightPoint = UserInfo.roleInfo.marsterFight
    }
    NodeHelper:setStringForLabel(container, lb2Str)
end

function EquipPageBase:RefreshExpBar(container)
    local currentExp = UserInfo.roleInfo.exp
    local roleExpCfg = ConfigManager.getRoleLevelExpCfg()

    if currentExp ~= nil and roleExpCfg ~= nil then
        local barImg = container:getVarSprite("mExpSprite")
        if barImg then
            local nextLevelExp = currentExp
            if UserInfo.roleInfo.level >= ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.roleLevelLimit].level then
                barImg:setScaleX(1)
            else
                if UserInfo.roleInfo and roleExpCfg[UserInfo.roleInfo.level] then
                    nextLevelExp = roleExpCfg[UserInfo.roleInfo.level]["exp"]
                    assert(nextLevelExp ~= nil, "MainFrame_RefreshExpBar roleExpCfg nextLevelExp is nil")
                    local percent = math.min(currentExp / nextLevelExp, 1)
                    if percent >= 0 then
                        barImg:setScaleX(percent)
                    end
                end
            end
        end
    end
end

function EquipPageBase:onViewExp(container)
    local ExpNode = container:getVarNode("mExp")
    local roleExpCfg = ConfigManager.getRoleLevelExpCfg()
    local nextLevel = math.min(UserInfo.roleInfo.level, ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.roleLevelLimit].level)
    local nextLevelExp = roleExpCfg[nextLevel] and roleExpCfg[nextLevel]["exp"] or UserInfo.roleInfo.exp
    local mExpTxt = GameUtil:formatNumber(UserInfo.roleInfo.exp) .. "/" .. GameUtil:formatNumber(nextLevelExp)
    NodeHelper:setStringForLabel(container, { mExp = mExpTxt })
    if ExpNode:isVisible() == true then
        ExpNode:setVisible(false)
    else
        ExpNode:setVisible(true)
    end
end

function EquipPageBase:onPersonalConfidence(container)
    PageManager.pushPage("PlayerInfoPage")
end
function EquipPageBase:onRecharge(container)
    require("IAP.IAPPage"):setEntrySubPage("Diamond")
    PageManager.pushPage("IAP.IAPPage")
end
function EquipPageBase:onBuyGold(container)
    --PageManager.pushPage("MoneyCollectionPage")
end

function EquipPageBase:refreshAllPoint(container)
    NodeHelper:setNodesVisible(container, { mHeroRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_CHAR_TAB) })
    NodeHelper:setNodesVisible(container, { mGalleryRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_ILLUST_TAB) })
    NodeHelper:setNodesVisible(container, { mCollectionRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_FETTER_TAB) })
    for _type = 1, #GalleryCardItems do
        for idx = 1, #GalleryCardItems[_type] do
            NgHeadIconItem:refreshByItemId(GalleryCardItems[_type][idx])
        end
    end
    --for i = 1, #CollectionItems do
    --    if CollectionItems[i].cls.showContainer then
    --        NodeHelper:setNodesVisible(CollectionItems[i].cls.showContainer, { mRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_FETTER_BTN, i) })
    --    end
    --end
end

local CommonPage = require('CommonPage')
EquipPageBase = CommonPage.newSub(EquipPageBase, thisPageName, option)
return EquipPageBase
