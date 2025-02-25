----------------------------------------------------------------------------------
------------local variable for system api--------------------------------------
local ceil = math.ceil
--------------------------------------------------------------------------------
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")

local thisPageName = "GemSelectPage"

local option = {
	ccbiFile = "EquipmentCameoIncrustationChoosePopUp.ccbi",
	handlerMap = {
		onHelp	= "onHelp",
		onClose	= "onClose"
	}
}

local GemSelectPageBase = {}

local NodeHelper = require("NodeHelper")
local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")
local EquipOprHelper = require("Equip.EquipOprHelper")

local PageInfo = {
	equipId = 0,
	pos = 1,
	gemPos2Id = {},
	optionIds = {}
}

local GEM_COUNT_PER_LINE = 2
--------------------------------------------------------------
local GemItemLine = {
	ccbiFile = "EquipmentCameoIncrustationChooseContent.ccbi",
	itemCcbi = "GoodsItem.ccbi"
}

function GemItemLine.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		GemItemLine.onRefreshItemView(container)
	elseif string.sub(eventName, 1, 6) == "onHand" then
		print("eventName", eventName)
		local index = tonumber(string.sub(eventName, 7, -1))
		local contentId = container:getItemDate().mID
		local baseIndex = (contentId - 1) * GEM_COUNT_PER_LINE
		index = index + baseIndex
		EquipOprHelper:embedEquip(PageInfo.equipId, PageInfo.pos, PageInfo.optionIds[index].itemId)
		PageManager.popPage(thisPageName)
	end
end

function GemItemLine.onRefreshItemView(container)
	local contentId = container:getItemDate().mID
	local baseIndex = (contentId - 1) * GEM_COUNT_PER_LINE

	local itemCfg = ConfigManager.getItemCfg()

	for i = 1, 2 do
		local nodeContainer = container:getVarNode(string.format("mPosition%d", i))
		NodeHelper:setNodeVisible(nodeContainer, false)

		local index = baseIndex + i
		local item = PageInfo.optionIds[index]
		if item then
			local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, item.itemId, item.count)
			local attr = itemCfg[item.itemId].attr
			if attr then
				local attrVisible = {}

				attrVisible["mAttNode" .. (i * 2 - 1)] = #attr == 1
				attrVisible["mAttNode" .. (i * 2)] = #attr == 2

				local attrTex = {}
				if #attr == 1 then
					local name = common:getAttrName(attr[1][1])
					attrTex["mAttribute" .. i] = common:getLanguageString("@EquipAttrVal", name, attr[1][2])
				elseif #attr == 2 then
					local name = common:getAttrName(attr[1][1])
					attrTex["mAttribute" .. (i * 3 - 1)] = common:getLanguageString("@EquipAttrVal", name, attr[1][2])

					name = common:getAttrName(attr[2][1])
					attrTex["mAttribute" .. (i * 3)] = common:getLanguageString("@EquipAttrVal", name, attr[2][2])
				end
				-- dump(attrVisible)
				-- dump(attrTex)
				NodeHelper:setStringForLabel(container, attrTex)
				NodeHelper:setNodesVisible(container, attrVisible)
			end

			local lb2Str = {}
			lb2Str["mNumber" .. i] = "x" .. item.count
			local lbStr = {}
			--lbStr["mNumber"..i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
			NodeHelper:setColorForLabel(container, lbStr)
			NodeHelper:setStringForLabel(container, lb2Str)

			if i == 1 then
				NodeHelper:setNodesVisible(container, { mName1 = true })
				NodeHelper:setStringForLabel(container, { mName1 = resInfo.name })
				NodeHelper:setSpriteImage(container, { mPic1 = resInfo.icon })
				NodeHelper:setQualityFrames(container, { mHand1 = resInfo.quality })
			else
				NodeHelper:setNodesVisible(container, { mName2 = true })
				NodeHelper:setStringForLabel(container, { mName2 = resInfo.name })
				NodeHelper:setSpriteImage(container, { mPic2 = resInfo.icon })
				NodeHelper:setQualityFrames(container, { mHand2 = resInfo.quality })
			end
			
			NodeHelper:setNodeVisible(nodeContainer, true)
		end
	end
end

function GemItemLine.newGemItem(item, resInfo)
	local itemNode = ScriptContentBase:create(GemItemLine.itemCcbi, item.itemId)
	itemNode:setScale(0.8)
	NodeHelper:setNodesVisible(itemNode, {mName = false})
	itemNode:registerFunctionHandler(GemItemOnFunction)

	local lb2Str = {
		mNumber = "x" .. item.count
	}
	NodeHelper:setStringForLabel(itemNode, lb2Str)
	NodeHelper:setSpriteImage(itemNode, {mPic = resInfo.icon})
	NodeHelper:setQualityFrames(itemNode, {mHand = resInfo.quality})

	itemNode:release()
	return itemNode
end
----------------------------------------------------------------------------------

-----------------------------------------------
--GemSelectPageBase页面中的事件处理
----------------------------------------------
function GemSelectPageBase:onEnter(container)
	NodeHelper:setStringForLabel(container, { mExplain = common:getLanguageString("@SelectGemToEmbed") })
	self:setOptionIds()
	NodeHelper:initScrollView(container, "mContent", 3)

	self:rebuildAllItem(container)
end

function GemSelectPageBase:onExit(container)
	NodeHelper:deleteScrollView(container)
	PageInfo.gemPos2Id = {}
end
----------------------------------------------------------------
function GemSelectPageBase:setOptionIds()
	local items = UserItemManager:getItemsByType(Const_pb.GEM)
	PageInfo.optionIds = {}
	local itemCfg = ConfigManager.getItemCfg()
	local userEquip = UserEquipManager:getUserEquipById(PageInfo.equipId)
	local part = EquipManager:getPartById(userEquip.equipId)

	local hasType = false
	local canInsert

	for i, v in ipairs(items) do
		if itemCfg[v.itemId] then
			canInsert = itemCfg[v.itemId].isNewStone == 1
			print("canInsert", canInsert)
			if not canInsert then
				for j, v1 in ipairs(itemCfg[v.itemId].location) do
					if v1 == part then
						canInsert = true
						break
					end
				end
			end
			if canInsert then
				hasType = false
				for pos, id in pairs(PageInfo.gemPos2Id) do
					if itemCfg[id] and itemCfg[id].stoneType == itemCfg[v.itemId].stoneType then
						hasType = true
					end
				end
				if not hasType then
					table.insert(PageInfo.optionIds, v)
				end
			end
		end
	end
	table.sort( PageInfo.optionIds, function (left, right)
		if itemCfg[left.itemId].isNewStone == 2 and itemCfg[right.itemId].isNewStone == 2 then
			if #itemCfg[left.itemId].attr == #itemCfg[right.itemId].attr then
				if itemCfg[left.itemId].stoneLevel == itemCfg[right.itemId].stoneLevel then
					if left.count == right.count then
						return itemCfg[left.itemId].stoneType > itemCfg[right.itemId].stoneType
					end
					return left.count > right.count

				end
				return itemCfg[left.itemId].stoneLevel > itemCfg[right.itemId].stoneLevel
			end
			
			return #itemCfg[left].attr > #itemCfg[right].attr
		end

		return itemCfg[left.itemId].isNewStone > itemCfg[right.itemId].isNewStone
	end )
end

----------------scrollview-------------------------
function GemSelectPageBase:rebuildAllItem(container)
	self:clearAllItem(container)
	if #PageInfo.optionIds > 0 then
		self:buildItem(container)
	end
end

function GemSelectPageBase:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end

function GemSelectPageBase:buildItem(container)
	local size = math.ceil(#PageInfo.optionIds / GEM_COUNT_PER_LINE)
	NodeHelper:buildScrollView(container, size, GemItemLine.ccbiFile, GemItemLine.onFunction)
end

----------------click event------------------------
function GemSelectPageBase:onClose(container)
	PageManager.popPage(thisPageName)
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
GemSelectPage = CommonPage.newSub(GemSelectPageBase, thisPageName, option)

function GemSelectPage_setEquipIdAndPos(equipId, pos, gemPos2Id)
	PageInfo.equipId = equipId
	PageInfo.pos = pos
	PageInfo.gemPos2Id = gemPos2Id
end
