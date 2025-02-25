
local RelationshipManager = require("RelationshipManager")
local ConfigManager = require("ConfigManager")
local FormationManager = require("FormationManager")
local EquipManager = require("EquipManager")

local thisPageName = "EditMercenaryTeamRelationshipPopUp"
local EditMercenaryTeamRelationshipPopUpBase = {

}

local option = {
    ccbiFile = "EditMercenaryTeamRelationshipPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp",
    },
    opcodes =
    {
    }
}
local constWidth = 680
local constHeight = 120
local scale = 0.8
local _roleCfgData = nil
local _relationshipData = nil
local _teamRoleId = 0
local _container = nil
local _isRefresh = false
--------------------------------------------------------
local Item = {
    ccbiFile = "EditMercenaryTeamRelationshipItem.ccbi",
}

function Item:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local d = RelationshipManager:getRelationshipDataByRoleId(self.roleId)
    local htmlStr = EditMercenaryTeamRelationshipPopUpBase:getItemAttrMessage(d)
    local labelNode = container:getVarLabelTTF("mAttr")
    local size = CCSizeMake(constWidth, constHeight)
    local htmlLabel = NodeHelper:addHtmlLable(labelNode, htmlStr, GameConfig.Tag.HtmlLable, size)
    NodeHelper:setStringForLabel(container, { mAttr = "" })
    htmlLabel:setScale(scale)


    local htmlHeight = htmlLabel:getContentSize().height * scale
    local height = constHeight
    if htmlHeight + math.abs(-60) > constHeight then
        height = htmlHeight + math.abs(-60)
    else
        height = constHeight
    end

    -- container:setContentSize(CCSizeMake(self.width, self.height))
    -- container:setPosition(ccp(self.x, self.y))


    NodeHelper:setStringForLabel(container, { mName = _roleCfgData[self.roleId].name })

    local base = container:getVarNode("mInfoBase")
    base:setPosition(ccp(300, height))
end

-- 队伍中是否有对应的武将出战
function Item:getRoleIsFight(teamRoldId, roleId)
    for i = 1, #teamRoldId do
        if teamRoldId[i] == roleId then
            return roleId
        end
    end
    return 0
end

function Item:onHeadClick_1(container)

end

function Item:onHeadClick_2(container)

end

function Item:onHeadClick_3(container)

end

function Item:onHeadClick_4(container)

end

function Item:onPreLoad(ccbRoot)

end

function Item:onUnLoad(ccbRoot)

end

--------------------------------------------------------

function EditMercenaryTeamRelationshipPopUpBase:onEnter(container)
    _container = container
    self:initData()
    container.mScrollView = container:getVarScrollView("mContent")
    self:clearAndReBuildAllItem(container)
end

function EditMercenaryTeamRelationshipPopUpBase:initData()
    _relationshipData = { }
    for i = 1, #_teamRoleId do
        if RelationshipManager:getRelationshipDataByRoleId(_teamRoleId[i]) ~= nil then
            table.insert(_relationshipData, _teamRoleId[i])
        end
    end
    _roleCfgData = ConfigManager.getRoleCfg()
end

function EditMercenaryTeamRelationshipPopUpBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    if #_relationshipData <= 0 then
        return
    end

    -----------------------------------------------------------------
--    local id = GameConfig.FreeTypeId.Relationship_1_1_Close
--    local cfg = FreeTypeConfig[id]
--    local tempHtmlLabel = CCHTMLLabel:createWithString(common:fill_1(cfg.content, { }), CCSizeMake(constWidth, constHeight), "Helvetica")
--    local tempHeight = tempHtmlLabel:getContentSize().height
    -----------------------------------------------------------------
    local offsetY = 0
    local titleCell = nil
    local allHeigth = 0

    for i = 1, #_relationshipData do
        titleCell = CCBFileCell:create()

        titleCell:setCCBFile(Item.ccbiFile)

        local d = RelationshipManager:getRelationshipDataByRoleId(_relationshipData[i])
        local htmlLabel = CCHTMLLabel:createWithString(EditMercenaryTeamRelationshipPopUpBase:getItemAttrMessage(d), CCSizeMake(constWidth, constHeight), "Helvetica")
        local htmlHeight = htmlLabel:getContentSize().height * scale
        local height = constHeight
        if htmlHeight + math.abs(-60) > constHeight then
            height = htmlHeight + math.abs(-60)
        else
            height = constHeight
        end
        titleCell:setContentSize(CCSizeMake(titleCell:getContentSize().width, height))

        allHeigth = allHeigth + height

        local panel = Item:new( { id = i, roleId = _relationshipData[i], x = 0, y = offsetY, width = titleCell:getContentSize().width, height = height })
        titleCell:registerFunctionHandler(panel)

        container.mScrollView:addCellBack(titleCell)

        titleCell:setPosition(ccp(0, offsetY))
        offsetY = offsetY + titleCell:getContentSize().height

    end



    --    for i = #_relationshipData, 1, -1 do
    --        titleCell = CCBFileCell:create()

    --        titleCell:setCCBFile(Item.ccbiFile)

    --        local d = RelationshipManager:getRelationshipDataByRoleId(_relationshipData[i])
    --        local htmlLabel = CCHTMLLabel:createWithString(EditMercenaryTeamRelationshipPopUpBase:getItemAttrMessage(d), CCSizeMake(680, constHeight), "Helvetica")
    --        local htmlHeight = htmlLabel:getContentSize().height * scale
    --        local height = constHeight
    --        if htmlHeight + math.abs(-60) > constHeight then
    --            height = htmlHeight + math.abs(-60)
    --        else
    --            height = constHeight
    --        end
    --        titleCell:setContentSize(CCSizeMake(titleCell:getContentSize().width, height))

    --        allHeigth = allHeigth + height

    --        local panel = Item:new( { id = i, roleId = _relationshipData[i], x = 0, y = offsetY, width = titleCell:getContentSize().width, height = height })
    --        titleCell:registerFunctionHandler(panel)

    --        container.mScrollView:addCellBack(titleCell)

    --        titleCell:setPosition(ccp(0, offsetY))
    --        offsetY = offsetY + titleCell:getContentSize().height

    --    end

    local viewSize = container.mScrollView:getViewSize()
    --- titleCell:getContentSize().height
    local size = CCSizeMake(viewSize.width, offsetY)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, viewSize.height - size.height));
    container.mScrollView:orderCCBFileCells()
end

function EditMercenaryTeamRelationshipPopUpBase:getItemAttrMessage(data)
    local returnStr = ""
    for k, v in pairs(data) do
        local nameTb = { }
        local attrTb = { }
        -- 属性加成
        -- 与XXX出战,最大攻击力+10000
        local t = { }
        for i = 1, #v.relationshipRoleId do
            local str = _roleCfgData[v.relationshipRoleId[i]].name
            table.insert(nameTb, str)
        end

        local nameStr = nameTb[1]
        if #nameTb > 1 then
            nameStr = table.concat(nameTb, "、")
        end
        table.insert(t, nameStr)

        for i = 1, #v.attr do
            local attrData = v.attr[i]
            local name = common:getLanguageString("@AttrName_" .. attrData.type);
            local str = EquipManager:getGodlyAttrString(attrData.type, attrData.value)

            if attrData.value ~= 0 then
                if not EquipManager:isGodlyAttrPureNum(attrData.type) then
                    local fmt = "%0.1f"
                    str = string.format(fmt, tostring(attrData.value) / 100)
                    str = str .. "%%"
                end
            end

            table.insert(attrTb, name .. "+" .. str)

        end

        local attrStr = attrTb[1]
        if #attrTb > 1 then
            attrStr = table.concat(attrTb, "、")
        end
        table.insert(t, attrStr)

        local isActivation = RelationshipManager:getIsActivation(v, _teamRoleId)
        --local isActivation = RelationshipManager:getIsActivation(v.relationshipRoleId, _teamRoleId)
        local id = nil
        if isActivation then
            id = GameConfig.FreeTypeId.Relationship_Open
        else
            id = GameConfig.FreeTypeId.Relationship_Close
        end
        if id then
            local cfg = FreeTypeConfig[id]
            returnStr = returnStr .. common:fill_1(cfg.content, t) .. "<br/>" .. "<br/>"
        end
    end
    return returnStr
end

function EditMercenaryTeamRelationshipPopUpBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function EditMercenaryTeamRelationshipPopUpBase:onHelp(container)

end

function EditMercenaryTeamRelationshipPopUpBase:onExit(container)
    _container = nil
end

function EditMercenaryTeamRelationshipPopUpBase_setTeamRoleId(teamRoleId)
    _teamRoleId = teamRoleId
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local EditMercenaryTeamRelationshipPopUp = CommonPage.newSub(EditMercenaryTeamRelationshipPopUpBase, thisPageName, option)
