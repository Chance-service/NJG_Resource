local NgHeadIconItem = {
    roleId = "",
    pageType = 0,
}
require("NgHeroPageManager")
local NodeHelper = require("NodeHelper")
local UserMercenaryManager = require("UserMercenaryManager")
local mInfo = UserMercenaryManager:getUserMercenaryInfos()

function NgHeadIconItem:createByItemId(itemId, parentNode, pageType, optionData)
    local iconItem = { }
    iconItem.itemId = itemId
    iconItem.parentNode = parentNode
    iconItem.pageType = pageType
    iconItem.optionData = optionData
    self:initByItemId(iconItem)
    return iconItem
end

function NgHeadIconItem:initByItemId(iconItem)
    iconItem.container = ScriptContentBase:create("EquipmentPage_new_Item.ccbi")
    iconItem.container.itemId = iconItem.itemId
    iconItem.parentNode:addChild(iconItem.container)
    iconItem.container:registerFunctionHandler(NgHeadIconItem.onFunction)
    self:refreshByItemId(iconItem) 
end

function NgHeadIconItem:refreshByItemId(iconItem)
    local itemId = iconItem.itemId
    local heroCfg = ConfigManager.getNewHeroCfg()[itemId]

    if NgHeadIconItem.pageType == GameConfig.NgHeadIconType.GALLERY_PAGE then
        local quality = (heroCfg.Star <= 5 and 4) or (heroCfg.Star >= 11 and 6) or 5
        local roleStatus = UserMercenaryManager:getMercenaryStatusByItemId(itemId)
        NodeHelper:setSpriteImage(iconItem.container, { mFrame = GameConfig.MercenaryRarityFrame[quality],
                                                        mIcon = "UI/RoleShowCards/Hero_" .. string.format("%02d", itemId) .. "000.png",
                                                        mElement = GameConfig.MercenaryElementImg[heroCfg.Element],
                                                        mClass=GameConfig.MercenaryClassImg[heroCfg.Job]})
        NodeHelper:setNodesVisible(iconItem.container, { mInTeamImg = false, mLv = false, mBpNode = false, mStarNode = false, mMaskNode = false,
                                                         mInExpedition = false, mStarBg = false, mClass = true,
                                                         mBarNode = roleStatus.roleStage ~= Const_pb.IS_ACTIVITE,
                                                         mRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_ILLUST_CARD, itemId),
                                                         mTaskBar = roleStatus.soulCount > 0 })
        NodeHelper:setStringForLabel(iconItem.container, { mTaskTimes = roleStatus.soulCount .. "/" .. roleStatus.costSoulCount })
        local bar = iconItem.container:getVarScale9Sprite("mTaskBar")
        bar:setContentSize(CCSize(100 * math.min(1, math.max(0.14, roleStatus.soulCount / roleStatus.costSoulCount)), 21))
        for i = 1, 13 do
            NodeHelper:setNodesVisible(iconItem.container, { ["mStar" .. i] = (i == heroCfg.Star) })
        end
    elseif NgHeadIconItem.pageType == GameConfig.NgHeadIconType.COLLECTION_PAGE then
        local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(itemId)
        local star = roleInfo and roleInfo.starLevel or heroCfg.Star
        local quality = (star <= 5 and 4) or (star >= 11 and 6) or 5
        NodeHelper:setSpriteImage(iconItem.container, { mFrame = GameConfig.MercenaryRarityFrame[quality],
                                                        mIcon = "UI/RoleShowCards/Hero_" .. string.format("%02d", itemId) .. "000.png",
                                                        mElement = GameConfig.MercenaryElementImg[heroCfg.Element],
                                                        mClass=GameConfig.MercenaryClassImg[heroCfg.Job] })
        NodeHelper:setNodesVisible(iconItem.container, { mInTeamImg = false, mLv = false, mBpNode = false, mStarNode = true, mBarNode = false,
                                                         mRedPoint = false, mMaskNode = false, mInExpedition = false })
        for i = 1, 13 do
            NodeHelper:setNodesVisible(iconItem.container, { ["mStar" .. i] = (roleInfo and (i == roleInfo.starLevel) or (i == heroCfg.Star)) })
        end
        local star = roleInfo and roleInfo.starLevel or heroCfg.Star
        if star <= 5 then
            NodeHelper:setNodesVisible(iconItem.container,{mSr=true,mSsr=false,mUr=false})
        elseif star <= 10 then
            NodeHelper:setNodesVisible(iconItem.container,{mSr=false,mSsr=true,mUr=false})
        elseif star > 10 then
            NodeHelper:setNodesVisible(iconItem.container,{mSr=false,mSsr=false,mUr=true})
        else
            NodeHelper:setNodesVisible(iconItem.container,{mSr=false,mSsr=false,mUr=false})
        end
    elseif NgHeadIconItem.pageType == GameConfig.NgHeadIconType.RARITY_UP_PAGE then
        local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(itemId)
        local star = iconItem.optionData and iconItem.optionData.starLevel or roleInfo.starLevel
        local quality = (star <= 5 and 4) or (star >= 11 and 6) or 5
        NodeHelper:setSpriteImage(iconItem.container, { mFrame = GameConfig.MercenaryRarityFrame[quality],
                                                        mIcon = "UI/RoleShowCards/Hero_" .. string.format("%02d", itemId) .. "000.png",
                                                        mElement = GameConfig.MercenaryElementImg[heroCfg.Element],
                                                        mClass=GameConfig.MercenaryClassImg[heroCfg.Job] })
        NodeHelper:setNodesVisible(iconItem.container, { mInTeamImg = false, mLv = true, mBpNode = true, mStarNode = true, mBarNode = false,
                                                         mRedPoint = false, mMaskNode = false, mInExpedition = false })

        NodeHelper:setStringForLabel(iconItem.container, { mLv = "Lv." .. roleInfo.level, 
                                                           mBp = "BP " .. (iconItem.optionData and iconItem.optionData.fight or roleInfo.fight) })
        for i = 1, 13 do
            NodeHelper:setNodesVisible(iconItem.container, { ["mStar" .. i] = (i == star) })
        end
          if roleInfo and roleInfo.starLevel <= 5 then
            NodeHelper:setNodesVisible(iconItem.container,{mSr=true,mSsr=false,mUr=false})
        elseif roleInfo and roleInfo.starLevel > 5 and roleInfo.starLevel <= 10 then
            NodeHelper:setNodesVisible(iconItem.container,{mSr=false,mSsr=true,mUr=false})
        elseif roleInfo and roleInfo.starLevel > 10 then
            NodeHelper:setNodesVisible(iconItem.container,{mSr=false,mSsr=false,mUr=true})
        else
            NodeHelper:setNodesVisible(iconItem.container,{mSr=false,mSsr=false,mUr=false})
        end
    end

    self:setRoleDataByItemId(iconItem)
end
----------
function NgHeadIconItem:createCCBFileCell(roleId, id, scrollView, pageType)
    local cell = CCBFileCell:create()
    cell:setCCBFile("EquipmentPage_new_Item.ccbi")
    local handler = common:new( { id = id, roleId = roleId, pageType = pageType }, NgHeadIconItem)
    cell:registerFunctionHandler(handler)
    scrollView:addCell(cell)

    return { cell = cell, handler = handler }
end

function NgHeadIconItem:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    self:refreshCellData()
end

function NgHeadIconItem:refreshCellData()
    local curRoleInfo = UserMercenaryManager:getUserMercenaryById(self.roleId)
    if curRoleInfo then
        local itemId = curRoleInfo.itemId
        local statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(itemId)
        local heroCfg = ConfigManager.getNewHeroCfg()[itemId]
        local quality = (curRoleInfo.starLevel <= 5 and 4) or (curRoleInfo.starLevel >= 11 and 6) or 5

        NodeHelper:setStringForLabel(self.container, { mLv = "Lv." .. curRoleInfo.level, 
                                                       mBp = "BP " .. curRoleInfo.fight })
        NodeHelper:setSpriteImage(self.container, { mFrame = GameConfig.MercenaryRarityFrame[quality],
                                                    mIcon = "UI/RoleShowCards/Hero_" .. string.format("%02d", itemId) .. string.format("%03d", curRoleInfo.skinId) .. ".png",
                                                    mElement = GameConfig.MercenaryElementImg[heroCfg.Element],
                                                    mClass=GameConfig.MercenaryClassImg[heroCfg.Job]})
        for i = 1, 13 do
            NodeHelper:setNodesVisible(self.container, { ["mStar" .. i] = (i == curRoleInfo.starLevel) })
        end
        if curRoleInfo.starLevel <= 5 then
            NodeHelper:setNodesVisible(self.container,{mSr=true,mSsr=false,mUr=false})
        elseif curRoleInfo.starLevel > 5 and curRoleInfo.starLevel <= 10 then
            NodeHelper:setNodesVisible(self.container,{mSr=false,mSsr=true,mUr=false})
        else
            NodeHelper:setNodesVisible(self.container,{mSr=false,mSsr=false,mUr=true})
        end
        if NgHeadIconItem.pageType == GameConfig.NgHeadIconType.HERO_PAGE then
            NodeHelper:setNodesVisible(self.container, { mInTeamImg = (statusInfo.status == Const_pb.FIGHTING or statusInfo.status == Const_pb.MIXTASK),  mBarNode = false,
                                                         -- 卡片紅點僅顯示第一隊
                                                         mRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_CHAR_CARD, itemId) and (statusInfo.status == Const_pb.FIGHTING or statusInfo.status == Const_pb.MIXTASK), 
                                                         mMaskNode = false, mInExpedition = false,
                                                         mBpNode = false, mClass = true, mStarBg = true })
        elseif NgHeadIconItem.pageType == GameConfig.NgHeadIconType.EDIT_TEAM_PAGE then
            local teamPage = require("EditMercenaryTeamPage")
            local isInTeam = EditMercenaryTeamBase_isInTeam(self.roleId)
            NodeHelper:setNodesVisible(self.container, { mInTeamImg = isInTeam, mRedPoint = false, mBarNode = false, mMaskNode = false, mInExpedition = false })
            NodeHelper:setNodesVisible(self.container,{mSr=false,mSsr=false,mUr=false,mBpNode=true,mClass=true,mStarBg=false})
            for i = 1, 13 do
                NodeHelper:setNodesVisible(self.container, { ["mStar" .. i] = false })
            end
        elseif NgHeadIconItem.pageType == GameConfig.NgHeadIconType.BOUNTY_PAGE then
            NodeHelper:setNodesVisible(self.container, { mInExpedition = (statusInfo.status == Const_pb.EXPEDITION or statusInfo.status == Const_pb.MIXTASK), 
                                                         mMaskNode = (statusInfo.status == Const_pb.EXPEDITION or statusInfo.status == Const_pb.MIXTASK),
                                                         mBarNode = false,
                                                         mInTeamImg = false,
                                                         mRedPoint = false })
        end
    end
end

function NgHeadIconItem:onHead(container)
    local index = self.id
    if NgHeadIconItem.pageType == GameConfig.NgHeadIconType.HERO_PAGE then
        local rolePage = require("EquipLeadPage")
        PageManager.pushPage("EquipLeadPage")
        rolePage:setMercenaryId(self.roleId)
    elseif NgHeadIconItem.pageType == GameConfig.NgHeadIconType.GALLERY_PAGE or 
           NgHeadIconItem.pageType == GameConfig.NgHeadIconType.COLLECTION_PAGE then
        local rolePage = require("NgArchivePage")
        PageManager.pushPage("NgArchivePage")
        rolePage:setMercenaryId(container.itemId)
    elseif NgHeadIconItem.pageType == GameConfig.NgHeadIconType.EDIT_TEAM_PAGE then
        local teamPage = require("EditMercenaryTeamPage")
        EditMercenaryTeamBase_onHead(index)
    elseif NgHeadIconItem.pageType==GameConfig.NgHeadIconType.BOUNTY_PAGE then
       MercenaryExpeditionSendPage_onHead(index)
    end
end

function NgHeadIconItem:resetIcon(roleId)
    self.roleId = roleId
    self:refresh()
end

function NgHeadIconItem:visibleIconInfo(visibleMap)
    NodeHelper:setNodesVisible(self.container, visibleMap)
end

function NgHeadIconItem:visibleInTeam(visible)
    NodeHelper:setNodesVisible(self.container, { mInTeamImg = visible })
end

function NgHeadIconItem:removeFromParentAndCleanup()
    if self.container then
        self.container:removeFromParentAndCleanup(true)
        self.container:release()
    end
end

function NgHeadIconItem:registerClick(callback)
    self.container:registerFunctionHandler(callback)
end

function NgHeadIconItem:setRoleData(iconItem)
    iconItem.roleData = iconItem.roleData or { }
    local curRoleInfo = UserMercenaryManager:getUserMercenaryById(iconItem.handler.roleId)
    local heroCfg = ConfigManager.getNewHeroCfg()[curRoleInfo.itemId]
    iconItem.roleData.element = heroCfg.Element
    iconItem.roleData.star = curRoleInfo.starLevel
    iconItem.roleData.level = curRoleInfo.level
    iconItem.roleData.class = heroCfg.Job
    iconItem.roleData.itemId = curRoleInfo.itemId
end

function NgHeadIconItem:setRoleDataByItemId(iconItem)
    iconItem.roleData = iconItem.roleData or { }
    local heroCfg = ConfigManager.getNewHeroCfg()[iconItem.itemId]
    iconItem.roleData.element = heroCfg.Element
    iconItem.roleData.star = heroCfg.Star
    iconItem.roleData.level = 0
    iconItem.roleData.class = heroCfg.Job
    iconItem.roleData.itemId = iconItem.itemId
end

function NgHeadIconItem.onFunction(eventName, container)
    if eventName == "onHead" then
        NgHeadIconItem:onHead(container)
    end
end

function NgHeadIconItem_setPageType(_pageType)
    NgHeadIconItem.pageType = _pageType
end

return NgHeadIconItem