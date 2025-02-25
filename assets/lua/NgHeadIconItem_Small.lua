local NgHeadIconItem_Small = { }
local NodeHelper = require("NodeHelper")
local UserMercenaryManager = require("UserMercenaryManager")
----------
function NgHeadIconItem_Small:createCCBFileCell(roleId, id, parent, pageType, _scale, callback, option)
    if pageType == GameConfig.NgHeadIconSmallType.ARENA_PAGE then
        local iconItem = { }
        iconItem.itemId = roleId
        iconItem.parentNode = parent
        iconItem.pageType = pageType
        iconItem.option = option
        iconItem.container = ScriptContentBase:create("RoleHeadIcon.ccbi")
        iconItem.container.itemId = iconItem.roleId
        iconItem.parentNode:addChild(iconItem.container)
        self:refreshItemData(iconItem)

        return iconItem
    else
        local scale = (_scale or 1)
        local cell = CCBFileCell:create()
        cell:setCCBFile("RoleHeadIcon.ccbi")
        local handler = common:new( { id = id, roleId = roleId, pageType = pageType, callback = callback, option = option }, NgHeadIconItem_Small)
        cell:registerFunctionHandler(handler)

        cell:setScale(scale)
        cell:setContentSize(CCSize(cell:getContentSize().width * scale, cell:getContentSize().height * scale))
        parent:addCell(cell)
        self:resetData(handler)

        return { cell = cell, handler = handler }
    end
end

function NgHeadIconItem_Small:resetData(handler)
    if self.pageType ~= GameConfig.NgHeadIconSmallType.ARENA_PAGE then
        local curRoleInfo = UserMercenaryManager:getUserMercenaryById(handler.roleId)
        if curRoleInfo then
            local itemId = curRoleInfo.itemId
            local heroCfg = ConfigManager.getNewHeroCfg()[itemId]
            handler.element = heroCfg.Element
            handler.class = heroCfg.Job
        end
    end
end

function NgHeadIconItem_Small:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    self:refreshCellData()
end

function NgHeadIconItem_Small:refreshCellData()
    if self.pageType ~= GameConfig.NgHeadIconSmallType.ARENA_PAGE then
        local curRoleInfo = UserMercenaryManager:getUserMercenaryById(self.roleId)
        if curRoleInfo then
            local itemId = curRoleInfo.itemId
            local heroCfg = ConfigManager.getNewHeroCfg()[itemId]
            local quality = (curRoleInfo.starLevel <= 5 and 4) or (curRoleInfo.starLevel >= 11 and 6) or 5

            self.element = heroCfg.Element
            self.class = heroCfg.Job

            NodeHelper:setStringForLabel(self.container, { mBp = "BP " .. curRoleInfo.fight })
            NodeHelper:setSpriteImage(self.container, { mFrame = GameConfig.QualityImage[quality],
                                                        mIcon = "UI/RoleIcon/Icon_" .. string.format("%02d", itemId) .. string.format("%03d", curRoleInfo.skinId) .. ".png",
                                                        mElement = GameConfig.MercenaryElementImg[self.element],
                                                        mRairtyTxt = GameConfig.QualityImageTxt[quality],
                                                        mClass = GameConfig.MercenaryClassImg[self.class] })
            if self.pageType == GameConfig.NgHeadIconSmallType.PLAYERINFO_PAGE then
                NodeHelper:setNodesVisible(self.container, { mChoose = false, mElement = false, mBP = false, mRairtyTxt = false, mClass = false })
            elseif self.pageType == GameConfig.NgHeadIconSmallType.BATTLE_EDITTEAM_PAGE then
                NodeHelper:setNodesVisible(self.container, { mChoose = self.isChoose or false })
            end
        end
    end
end

function NgHeadIconItem_Small:onHead(container)
    local index = self.id
    if self.pageType == GameConfig.NgHeadIconSmallType.PLAYERINFO_PAGE then
        if self.callback then
            self.callback(self)
        end
    elseif self.pageType == GameConfig.NgHeadIconSmallType.BATTLE_EDITTEAM_PAGE  then
        if self.callback then
            self.callback(self)
        end
    end
end

function NgHeadIconItem_Small:refreshItemData(iconItem)
    if iconItem.pageType == GameConfig.NgHeadIconSmallType.ARENA_PAGE then
        if iconItem.option then
            local fight = iconItem.option.fight or 0
            local quality = iconItem.option.quality or 4
            local itemId = iconItem.option.itemId or 1
            local skinId = iconItem.option.skinId or 1
            local element = iconItem.option.element or 1
            local cfg = iconItem.option.cfg
            NodeHelper:setStringForLabel(iconItem.container, { mBp = "Lv." .. fight })
            NodeHelper:setSpriteImage(iconItem.container, { mFrame = GameConfig.QualityImage[quality],
                                                        mElement = GameConfig.MercenaryElementImg[element],
                                                        mRairtyTxt = GameConfig.QualityImageTxt[quality],
                                                        mClass = GameConfig.MercenaryClassImg[cfg.Job] })
            if iconItem.option.type == 1 then
                NodeHelper:setSpriteImage(iconItem.container, { mIcon = cfg.Icon })
            else
                NodeHelper:setSpriteImage(iconItem.container, { mIcon = "UI/RoleIcon/Icon_" .. string.format("%02d", itemId) .. string.format("%03d", skinId) .. ".png" })
            end
            NodeHelper:setNodesVisible(iconItem.container, { mChoose = false })
        end
    end
end

function NgHeadIconItem_Small:setIsChoose(itemNode, isChoose)
    NodeHelper:setNodesVisible(itemNode.container, { mChoose = isChoose })
    itemNode.isChoose = isChoose
end

return NgHeadIconItem_Small