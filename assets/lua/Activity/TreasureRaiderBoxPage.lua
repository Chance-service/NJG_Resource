

local TreasureRaiderDataHelper = require("Activity.TreasureRaiderDataHelper")
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper")
local CommonPage = require("CommonPage")
local TreasureRaiderBoxPageBase = {}
local option = {
	ccbiFile = "Act_TreasureRaidersRewardAchievePopUp.ccbi",
	handlerMap = {
		onClose = "onClose",
		onCancel = "onClose",
		onFeet = "showTip",	
	}
}
local SelectIndex = 0
--三套，下角标为{1,2,3},{4,5},{6}
local ItemLabelName = {
    [1] = {
        pic = "mOneMaterialPic0",
        num = "mOneMaterialNum0",
        name = "mOneMaterialName0",
        btn = "mOneMaterialBtn0",
        selected = "mOneTexBg"
    },
    [2] = {
        pic = "mTwoMaterialPic0",
        num = "mTwoMaterialNum0",
        name = "mTwoMaterialName0",
        btn = "mTwoMaterialBtn0",
        selected = "mTwoTexBg"
    },
    [3] = {
        pic = "mThreeMaterialPic0",
        num = "mThreeMaterialNum0",
        name = "mThreeMaterialName0",
        btn = "mThreeMaterialBtn0",
        selected = "mThreeTexBg"
    }
}

local PageName = "TreasureRaiderBoxPage"

function TreasureRaiderBoxPageBase:parseItem( itemCfg )
	if itemCfg==nil then return end

	local items = {}
	local _type, _itemId, _count = unpack(common:split(itemCfg, "_"))
	if _type==nil or _itemId==nil or _count==nil then
		assert(false, "ConfigManager.parseItemOnlyWithUnderline is wrong")
	else
		items["type"]		= tonumber(_type)
		items["itemId"]		= tonumber(_itemId)
		items["count"]		= tonumber(_count)
	end
    return items
end
function TreasureRaiderBoxPageBase.onFunctionEx(eventName ,container)
    if string.sub(eventName,1,17)=="onOneMaterialBtn0" then
        local index = tonumber(string.sub(eventName,18,-1))
        TreasureRaiderBoxPageBase:onSelectItem(container,index)
    elseif string.sub(eventName,1,17)=="onTwoMaterialBtn0" then
        local index = tonumber(string.sub(eventName,18,-1))
        TreasureRaiderBoxPageBase:onSelectItem(container,index)
    elseif string.sub(eventName,1,19)=="onThreeMaterialBtn0" then
        local index = tonumber(string.sub(eventName,20,-1))
        TreasureRaiderBoxPageBase:onSelectItem(container,index)
    end
end
function TreasureRaiderBoxPageBase:onSelectItem(container,index)
    if type(index)=="number" then
        self:showTip(container,index)
    end
end
function TreasureRaiderBoxPageBase:showTip(container,index)
    local itemCfg = common:parseItemWithComma(TreasureRaiderDataHelper.showItems)
	if itemCfg==nil or #itemCfg<=0 then return end
	local size = #itemCfg
	local item = itemCfg[index]

    if ItemLabelName[size]==nil then 
        CCLuaLog("TreasureRaiderBoxPageBase:showTip ERROR:items not correct!")
        return
    end
    local node =  container:getVarNode(ItemLabelName[size].btn..index)
    if item~=nil and node~=nil then
		GameUtil:showTip(node,item)
    end
end

function TreasureRaiderBoxPageBase:onEnter( container )
	local itemCfg = common:parseItemWithComma(TreasureRaiderDataHelper.showItems)
	if itemCfg==nil or #itemCfg<=0 then return end
	local size = #itemCfg
	local lb2Str = {}
	local sprite2Img = {}
	local menu2Quality = {}

	if size>#ItemLabelName then
        CCLuaLog("TreasureRaiderBoxPageBase:onEnter ERROR:items not correct!")
        return
    end
    for i=1,#ItemLabelName do
        NodeHelper:setNodesVisible(container,{
            ["mSkillNode"..i] = size==i 
        })
    end
    for i=1,size do
        local item = itemCfg[i]
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(item.type, item.itemId, item.count)
        if resInfo~=nil then
            sprite2Img[ItemLabelName[size].pic .. i] 		= resInfo.icon
	        lb2Str[ItemLabelName[size].num .. i]			= "x" .. resInfo.count
	    --    lb2Str[ItemLabelName[size].name .. i]			= resInfo.name
	        menu2Quality[ItemLabelName[size].btn .. i]		= resInfo.quality
			NodeHelper:setCCHTMLLabel(container,ItemLabelName[size].name .. i,CCSize(130,96),resInfo.name,true)
        end
    end
    NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img);
	NodeHelper:setQualityFrames(container, menu2Quality);
end

function TreasureRaiderBoxPageBase:onClose( container )
	common:sendEmptyPacket(HP_pb.TREASURE_RAIDER_CONFIRM_C)
	PageManager.popPage(PageName)
end

function TreasureRaiderBoxPageBase:onReceivePacket( container )
    if opcode == HP_pb.TREASURE_RAIDER_CONFIRM_S then
    end
end
-------------------------------------------------------------------
local CommonPage = require("CommonPage");
local TreasureRaiderBoxPage = CommonPage.newSub(TreasureRaiderBoxPageBase, PageName, option,TreasureRaiderBoxPageBase.onFunctionEx);
