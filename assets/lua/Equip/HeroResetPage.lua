local HP_pb = require("HP_pb")
local MysticalDress_pb = require("Badge_pb")
local thisPageName = "HeroResetPage"
local PAGE_INFO = {
    COST_LEVEL_LIMIT = 100,
    PAGE_ROLE_LEVE = 0,
    PAGE_ROLE_ID = 0,
    PAGE_ITEM_ID = 0,
    SCROLLVIEW_VIEWWIDTH = 0,
    SCROLLVIEW_VIEWHEIGHT = 0,
    MAX_PART = 10,
}
local opcodes = {
    ROLE_LEVEL_RESET_C = HP_pb.ROLE_LEVEL_RESET_C,
    ROLE_LEVEL_RESET_S = HP_pb.ROLE_LEVEL_RESET_S,
    EQUIP_DRESS_S = HP_pb.EQUIP_DRESS_S,
    BADGE_DRESS_S = HP_pb.BADGE_DRESS_S,
}
local option = {
    ccbiFile = "HeroReset.ccbi",
    handlerMap =
    {
        onReset = "onReset",
        onClose = "onReturn",
    },
    opcode = opcodes
}

local HeroResetPage = { }
local levelCfg = ConfigManager.getHeroLevelCfg()
local itemTable = { }
local nowDisPart = 1
-----------------------------------
local HeroResetItem = {
    ccbiFile = "BackpackItem.ccbi",
}
-----------------------------------
function HeroResetPage:refreshItem(container, itemType, itemId, num)
    if container == nil then
        return 136, 136
    end
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemType, itemId, num)
    NodeHelper:setSpriteImage(container, { mFrameShade1 = NodeHelper:getImageBgByQuality(resInfo.quality) })
    NodeHelper:setSpriteImage(container, { mPic1 = resInfo.icon })
    NodeHelper:setNormalImages(container, { mHand1 = GameConfig.QualityImage[resInfo.quality] })
    NodeHelper:setStringForLabel(container, { mNumber1_1 = num })
    NodeHelper:setNodesVisible(container, { mName1 = false, mShader = false, mEquipLv = false, mNumber1 = false, mStarNode = false })
    return 136, 136
end

function HeroResetPage:onEnter(container)
    self:registerPacket(container)
    self:refreshUI(container)
    self:calculateResetItem(container)
    self:initScrollView(container)
    self:refreshScrollView(container)
end
-- 更新UI顯示
function HeroResetPage:refreshUI(container)
    NodeHelper:setStringForTTFLabel(container, { mTipTxt = common:getLanguageString("@ResetInfo", common:getLanguageString("@HeroName_" .. PAGE_INFO.PAGE_ITEM_ID)) })
    NodeHelper:setNodesVisible(container, { mBtn = (PAGE_INFO.PAGE_ROLE_LEVE > PAGE_INFO.COST_LEVEL_LIMIT),
                                            mBtnFree = (PAGE_INFO.PAGE_ROLE_LEVE <= PAGE_INFO.COST_LEVEL_LIMIT) })
end
-- 計算返還道具
function HeroResetPage:calculateResetItem(container)
    itemTable = { }
    for i = 1, PAGE_INFO.PAGE_ROLE_LEVE - 1 do
        local items = common:split(levelCfg[i].Cost, ",")
        for idx = 1, #items do
            local _type, _id, _num = unpack(common:split(items[idx], "_"))
            local key = _type .. "_" .. _id
            itemTable[key] = itemTable[key] or { }
            itemTable[key].type = tonumber(_type)
            itemTable[key].id = tonumber(_id)
            itemTable[key].num = itemTable[key].num and itemTable[key].num + tonumber(_num) or tonumber(_num)
        end
    end
end
-- ScrollView初始化
function HeroResetPage:initScrollView(container)
    NodeHelper:initScrollView(container, "mContent", 10)
    PAGE_INFO.SCROLLVIEW_VIEWWIDTH = container.mScrollView:getViewSize().width
    PAGE_INFO.SCROLLVIEW_VIEWHEIGHT = container.mScrollView:getViewSize().height
end
-- 刷新滾動層內容
function HeroResetPage:refreshScrollView(container)
    container.mScrollView:removeAllCell()
    container.m_pScrollViewFacade:clearAllItems()
    local nowHeight = 0
    local nowWidth = 0
    local nowPosX = 0
    local nowPosY = 0
    local itemCount = 0
    local itemWidth, itemHeight = 0, 0
    local items = { }
    -----------------------------------------
    -- ITEM
    for k, v in pairs(itemTable) do
        itemCount = itemCount + 1
        local pItemData = CCReViSvItemData:new_local()
        local pItem = ScriptContentBase:create(HeroResetItem.ccbiFile)
        pItem:registerFunctionHandler(HeroResetPage.onFunction)
        pItem.rewardData = { type = v.type, itemId = v.id, count = v.num }
        itemWidth, itemHeight = self:refreshItem(pItem, v.type, v.id, v.num)
        container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)

        table.insert(items, pItemData)
    end
    -----------------------------------------
    -- Reset Pos
    local lineCount = math.ceil((itemWidth * itemCount) / PAGE_INFO.SCROLLVIEW_VIEWWIDTH)
    nowPosY = (lineCount - 1) * itemHeight
    for k, v in pairs(items) do
        local isChangeLine = (nowPosX + itemWidth) > PAGE_INFO.SCROLLVIEW_VIEWWIDTH
        if isChangeLine then
            v.m_ptPosition = ccp(0, nowPosY - itemHeight)
        else
            v.m_ptPosition = ccp(nowPosX, nowPosY)
        end

        nowWidth = isChangeLine and nowWidth or math.max(nowWidth, nowPosX + itemWidth)
        nowHeight = (isChangeLine or nowHeight == 0) and nowHeight + itemHeight or nowHeight
        nowPosX = isChangeLine and 0 or (nowPosX + itemWidth)
        nowPosY = isChangeLine and nowPosY - itemHeight or nowPosY
    end
    -----------------------------------------
    local contentHeight = lineCount * itemHeight
    container.mScrollView:setContentSize(CCSize(nowWidth, contentHeight))
    container.mScrollView:setViewSize(CCSize(nowWidth, math.min(contentHeight, PAGE_INFO.SCROLLVIEW_VIEWHEIGHT)))
    container.mScrollView:setContentOffset(ccp(0, contentHeight >= PAGE_INFO.SCROLLVIEW_VIEWHEIGHT and PAGE_INFO.SCROLLVIEW_VIEWHEIGHT - contentHeight or 0))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(0)
    container.mScrollView:forceRecaculateChildren()
    container.mScrollView:setTouchEnabled(contentHeight > PAGE_INFO.SCROLLVIEW_VIEWHEIGHT)
end
-- 脫裝&脫符文
function HeroResetPage:onAllDisEquip(container)
    local UserMercenaryManager = require("UserMercenaryManager")
    local isEquip = false
    for i = nowDisPart, PAGE_INFO.MAX_PART do
        nowDisPart = nowDisPart + 1
        local roleEquip = UserMercenaryManager:getEquipByPart(PAGE_INFO.PAGE_ROLE_ID, i)
        local dressType = GameConfig.DressEquipType.Off
        if roleEquip then
            local EquipOprHelper = require("Equip.EquipOprHelper")
            EquipOprHelper:dressEquip(roleEquip.equipId, PAGE_INFO.PAGE_ROLE_ID, dressType)
            isEquip = true
            break
        end
    end
    if not isEquip then
        local curRoleInfo = UserMercenaryManager:getUserMercenaryById(PAGE_INFO.PAGE_ROLE_ID)
        local dressInfo = curRoleInfo.dress
        for i = 1, #dressInfo do
            local msg = MysticalDress_pb.HPMysticalDressChange()
            msg.roleId = PAGE_INFO.PAGE_ROLE_ID
            msg.loc = dressInfo[i].loc
            msg.type = 2 -- 1表示穿上 2表示卸下 3表示更换
            msg.offEquipId = dressInfo[i].id
            common:sendPacket(HP_pb.BADGE_DRESS_C, msg)

            isEquip = true
            break
        end
    end
    return isEquip
end

function HeroResetPage:onReset(container)
    if not HeroResetPage:onAllDisEquip(container) then
        nowDisPart = 1
        local HP_pb = require("HP_pb")
        local msg = RoleOpr_pb.HPHeroLevelResetReq()
        msg.id = PAGE_INFO.PAGE_ROLE_ID
        common:sendPacket(opcodes.ROLE_LEVEL_RESET_C, msg, false)
    end
end

function HeroResetPage:onReturn(container)
    self:removePacket(container)
    PageManager.popPage(thisPageName)
end

-- Server回傳
function HeroResetPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    
    if opcode == opcodes.ROLE_LEVEL_RESET_S then
        self:onReturn(container)
        return
    elseif opcode == opcodes.EQUIP_DRESS_S then
        self:onReset(container)
    elseif opcode == opcodes.BADGE_DRESS_S then
        self:onReset(container)
    end
end

function HeroResetPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function HeroResetPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function HeroResetPage.onFunction(eventName, container)
    if eventName == "onHand1" then
        if container.rewardData ~= nil then
            GameUtil:showTip(container:getVarNode("mPic1"), container.rewardData)
        end
    end
end

function HeroResetPage_setPageHeroInfo(roleId, itemId, level)
    PAGE_INFO.PAGE_ROLE_ID = roleId
    PAGE_INFO.PAGE_ITEM_ID = itemId
    PAGE_INFO.PAGE_ROLE_LEVE = level
end

local CommonPage = require('CommonPage')
local HeroResetPage = CommonPage.newSub(HeroResetPage, thisPageName, option)
