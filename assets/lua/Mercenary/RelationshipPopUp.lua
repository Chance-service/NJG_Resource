
local RelationshipManager = require("RelationshipManager")
local ConfigManager = require("ConfigManager")
local FormationManager = require("FormationManager")
local EquipManager = require("EquipManager")

local thisPageName = "RelationshipPopUp"
local RelationshipPopUpBase = {

}

local option = {
    ccbiFile = "RelationshipPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp",
    },
    opcodes =
    {
    }
}

local _roleCfgData = nil
local _relationshipData = nil
local _roleId = 0
local _teamList = {}
local _container = nil
local _isRefresh = false
--------------------------------------------------------
local Item = {
    ccbiFile = "RelationshipItem.ccbi",
}

function Item:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    --local teamList = FormationManager:getMainFormationInfo().roleNumberList

    local teamList = _teamList
    -- self.id
    -- self.data
    self.roleIdList = { }
    table.insert(self.roleIdList, self.data.targetRoleId)
    for i = 1, #self.data.relationshipRoleId do
        table.insert(self.roleIdList, self.data.relationshipRoleId[i])
    end

    for i = 1, 5 do
        if self.roleIdList[i] == nil then
            NodeHelper:setNodesVisible(container, { ["mHeadNode_" .. i] = false })
        else
            local roleData = _roleCfgData[self.roleIdList[i]]
            NodeHelper:setSpriteImage(container, { ["mPic_" .. i] = roleData.icon })
            NodeHelper:setStringForLabel(container, { ["mName_" .. i] = roleData.name })
            NodeHelper:setQualityFrames(container, { ["mQuality_" .. i] = roleData.quality })
            -- 是不是出战
            if _roleId == self.roleIdList[i] then
                NodeHelper:setNodeIsGray(container, { ["mPic_" .. i] = false })
            else
                local isFight = self:getRoleIsFight(teamList, self.roleIdList[i]) > 0
                NodeHelper:setNodeIsGray(container, { ["mPic_" .. i] = not isFight })
            end

            NodeHelper:setNodesVisible(container, { ["mName_" .. i] = false })
        end
    end

    -- 当前缘分是不是被激活
    local isActivation = RelationshipManager:getIsActivation(self.data, teamList)
    --local isActivation = RelationshipManager:getIsActivation(self.data.relationshipRoleId, teamList)
    NodeHelper:setNodesVisible(container, { mActivationStateNode = true })
    NodeHelper:setNodesVisible(container, { mState_1 = isActivation, mState_2 = not isActivation })


    -- 属性加成
    -- 与XXX出战,最大攻击力+10000
    local nameTb = { }
    local attrTb = { }
    local t = { }
    local s = ""
    for i = 1, #self.data.relationshipRoleId do
        local str = _roleCfgData[self.data.relationshipRoleId[i]].name
        table.insert(nameTb, str)
    end

    local nameStr = nameTb[1]
    if #nameTb > 1 then
        nameStr = table.concat(nameTb, "、")
    end
    table.insert(t, nameStr)

    s = s .. nameStr .. ","

    for i = 1, #self.data.attr do
        local attrData = self.data.attr[i]
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
    s = s .. attrStr

    NodeHelper:setStringForLabel(container, { mAttrMessage = s })

    local labelNode = container:getVarLabelTTF("mAttrMessage")
    local size = CCSizeMake(700, 60)
    --local size = CCSizeMake(550, labelNode:getContentSize().height)
    local htmlStr = ""
    local id = nil
    if isActivation then
        id = GameConfig.FreeTypeId.Relationship_Open
    else
        id = GameConfig.FreeTypeId.Relationship_Close
    end

    if id then
        local cfg = FreeTypeConfig[id]
        htmlStr = common:fill_1(cfg.content, t)
        local htmlLabel = NodeHelper:addHtmlLable(labelNode, htmlStr, GameConfig.Tag.HtmlLable, size)
        htmlLabel:setScale(0.8)
        NodeHelper:setStringForLabel(container, { mAttrMessage = "" })
    end
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

function RelationshipPopUpBase:onEnter(container)
    _container = container
    self:initData()
    container.mScrollView = container:getVarScrollView("mContent")
    self:clearAndReBuildAllItem(container)
end

function RelationshipPopUpBase:initData()
    _relationshipData = RelationshipManager:getRelationshipDataByRoleId(_roleId)
    _roleCfgData = ConfigManager.getRoleCfg()
end

function RelationshipPopUpBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local len = #_relationshipData
    for i, v in pairs(_relationshipData) do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { id = i, data = v })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
end

function RelationshipPopUpBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function RelationshipPopUpBase:onHelp(container)

end

function RelationshipPopUpBase:onExit(container)
    _container = nil
end

function RelationshipPopUpBase_setRoleId(roleId , teamList)
    _roleId = roleId

    _teamList = teamList
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local RelationshipPopUp = CommonPage.newSub(RelationshipPopUpBase, thisPageName, option)
