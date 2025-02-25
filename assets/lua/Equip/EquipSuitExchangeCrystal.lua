

local HP_pb = require("HP_pb") --包含协议id文件
local UserItemManager = require("Item.UserItemManager")
local ItemManager = require("ItemManager")
local ItemOpr_pb = require("ItemOpr_pb")
local thisPageName = "EquipSuitExchangeCrystal"
local thisItemId = nil --从背包进来的第一个装备id
local curItemDatas = {} --当前数据信息
local oneItemData = nil --一个数据itemData
local COUNT_EQUIPMENT_SOURCE_MAX = 8
local PageInfo = {
    selectIds = {},
    nodeParams = {
        picNode = "mRewardPic",
        qualityNode = "mMaterialFrame",
        num = "mReward"
    }
}

----这里是协议的id
local opcodes = {
    ITEM_EXCHANGE_C = HP_pb.ITEM_EXCHANGE_C,
    ITEM_EXCHANGE_S = HP_pb.ITEM_EXCHANGE_S
}

local option = {
    ccbiFile = "SuitPatchDecompositionPopUp.ccbi",
    handlerMap = { --按钮点击事件
        onSuitPatchAKeyInto	= "onAKeyInto",
		onPatchDecomposition = "onDecomposition",
		onClose = "onClose"
    },
    opcode = opcodes
}

for i = 1, COUNT_EQUIPMENT_SOURCE_MAX do
	option.handlerMap["onRewardFrame" .. i] = "goSelectEquip"
end

local EquipSuitExchangeCrystalBase = {}
function EquipSuitExchangeCrystalBase:onEnter(container)
    curItemDatas = {}
	container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:registerPacket(container)
    local relativeNode = container:getVarNode("mContentBg")
    GameUtil:clickOtherClosePage(relativeNode, function ()
        self:onClose(container)
    end,container)
end

function EquipSuitExchangeCrystalBase:onExecute(container)

end

function EquipSuitExchangeCrystalBase:onExit(container)
    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
end

function EquipSuitExchangeCrystalBase:onClose(container)
    GameUtil:hideClickOtherPage()
    PageManager.popPage(thisPageName)
    --PageManager.changePage("MainScenePage") 
    --PageManager.pushPage("PlayerInfoPage")
end

function EquipSuitExchangeCrystalBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.ITEM_EXCHANGE_S then
        local msg = ItemOpr_pb.HPItemExchangeRet()
        msg:ParseFromString( msgBuff )
        if msg.isSuccess then 
            curItemDatas = {}
            self:refreshPage( container )
        end
        return
    end     
end

function EquipSuitExchangeCrystalBase:refreshPage( container)
    local UserEquipManager = require("Equip.UserEquipManager")
    local EquipManager = require("Equip.EquipManager")
    local menu2Quality = {}
    local sprite2Img = {}
    local exchangeNum = 0
    for i = 1 ,COUNT_EQUIPMENT_SOURCE_MAX,1 do
        local itemInfo = curItemDatas[i] --PageInfo.selectIds[i]
        if itemInfo ~= nil then
            local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, itemInfo.itemId, itemInfo.count)
            menu2Quality[PageInfo.nodeParams.qualityNode .. i] = resInfo.quality
            sprite2Img[PageInfo.nodeParams.picNode .. i] = resInfo.icon
            NodeHelper:setStringForLabel(container, {[PageInfo.nodeParams.num .. i] = itemInfo.count})
            --NodeHelper:setColorForLabel(container,{[PageInfo.nodeParams.num .. i] = "32 29 0"})
            
            local cfg = ItemManager:getItemCfgById(itemInfo.itemId)
            local exchangeCrystalNum = cfg["exchangeCrystalNum"]
            if exchangeCrystalNum ~= 0 and #exchangeCrystalNum ~=0 then
                exchangeNum = exchangeNum + itemInfo.count * exchangeCrystalNum[1]["count"]
            end
        else
            menu2Quality[PageInfo.nodeParams.qualityNode .. i] = 1
            sprite2Img[PageInfo.nodeParams.picNode .. i] = GameConfig.Image.ChoicePic
            NodeHelper:setStringForLabel(container, {[PageInfo.nodeParams.num .. i] = ""})
        end
    end

    NodeHelper:setStringForLabel(container, {mSuitPatchGetNum = exchangeNum})
    NodeHelper:setSpriteImage(container, sprite2Img)
	NodeHelper:setQualityFrames(container, menu2Quality)
end

-------------------------------------------------click event--------------------------------------------------------------------------

function EquipSuitExchangeCrystalBase:onAKeyInto( container )
    local suits = UserItemManager:getItemsByType(Const_pb.SUIT_FRAGMENT)
    curItemDatas = {}
    for i=1, #suits do
        if i > 8 then break end 
        curItemDatas[#curItemDatas + 1] = suits[i]
    end

    if #curItemDatas == 0 then
        MessageBoxPage:Msg_Box_Lan("@suitDecompositionNotHave2") 
    end
    self:refreshPage( container)
end

function EquipSuitExchangeCrystalBase:onDecomposition( container )
    if table.maxn(curItemDatas) <= 0 then
        MessageBoxPage:Msg_Box_Lan("@suitDecompositionNotHave1")  
        return
    end

    local ItemOpr_pb = require("ItemOpr_pb")
    local msg = ItemOpr_pb.HPItemExchange()
    for k,v in pairs( curItemDatas ) do
        if v ~= nil then
            local data = msg.exchangeItem:add()
            data.itemId = v.itemId
            data.count = v.count
        end
    end
    common:sendPacket( opcodes.ITEM_EXCHANGE_C , msg ,false)
end

function EquipSuitExchangeCrystalBase:goSelectEquip( container ,eventName )
    local pos = tonumber(string.sub( eventName , -1 ))
    if curItemDatas[pos] then
        curItemDatas[pos] = nil 
        table.remove(curItemDatas, pos)
        self:refreshPage( container )
        return
    end

    require("EquipSuitCrystalSelectPage")
    EquipSuitCrystalSelectPageBase_setAlreadySelItem(curItemDatas)
    PageManager.pushPage("EquipSuitCrystalSelectPage")
end

function EquipSuitExchangeCrystal_setItemData(itemData)
	oneItemData = itemData
end

function EquipSuitExchangeCrystalBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam;
        --
        if pageName == thisPageName and extraParam == "selected" then --
            --local itemDatas = {}
            --itemDatas[1] = oneItemData
            --curItemDatas = itemDatas
            curItemDatas[#curItemDatas+1] = oneItemData

            self:refreshPage( container, itemDatas)
        end
    end
end

function EquipSuitExchangeCrystalBase:refreshOneItem(container)

end

function EquipSuitExchangeCrystalBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EquipSuitExchangeCrystalBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

local CommonPage = require('CommonPage')
local EquipSuitExchangeCrystal= CommonPage.newSub(EquipSuitExchangeCrystalBase, thisPageName, option)

function EquipSuitExchangeCrystal_setItemId(thisItemId)
	thisItemId = itemId;
end