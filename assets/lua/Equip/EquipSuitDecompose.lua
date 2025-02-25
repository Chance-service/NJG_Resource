
local thisPageName = "EquipSuitDecompose"
local SuitDecomposeBase = {}
local NodeHelper = require("NodeHelper")
local PageInfo = {
    selectIds = {},
    nodeParams = {
        picNode = "mRewardPic",
        qualityNode = "mMaterialFrame",
        
    }
}

local opcodes = {
    EQUIP_DECOMPOSE_C = HP_pb.EQUIP_DECOMPOSE_C,
	EQUIP_DECOMPOSE_S = HP_pb.EQUIP_DECOMPOSE_S
}

local COUNT_EQUIPMENT_SOURCE_MAX = 8

local option = {
    ccbiFile = "SuitDecompositionPopUp.ccbi",
	handlerMap = {
		onAKeyInto				= "onAKeyInto",
		onDecomposition			= "onDecomposition",
		onClose = "onClose"
	},
	opcode = opcodes
}

for i = 1, COUNT_EQUIPMENT_SOURCE_MAX do
	option.handlerMap["onRewardFrame" .. i] = "goSelectEquip"
end
---------------------------------------------------------------------------------------------------------------------------
function SuitDecomposeBase:onEnter( container )
    self:registerPacket( container )
    self:refreshPage( container )
end

function SuitDecomposeBase:onExecute( container )

end

function SuitDecomposeBase:onExit( container )
    self:removePacket( container )
    PageInfo.selectIds = {}
end

--------------------------------------------------------------------------------------------------------------------------------------

function SuitDecomposeBase:refreshPage( container )
    --if PageInfo.selectIds == nil or #PageInfo.selectIds == 0 then return end
    local UserEquipManager = require("Equip.UserEquipManager")
    local EquipManager = require("Equip.EquipManager")
    local menu2Quality = {}
    local sprite2Img = {}
    local labels = {}
    for i = 1 ,COUNT_EQUIPMENT_SOURCE_MAX,1 do
        local userEquipId = PageInfo.selectIds[i]
        if userEquipId ~= nil then
            local userEquip = UserEquipManager:getUserEquipById(userEquipId)
            local itemId = userEquip.equipId
            local itemInfo = EquipManager:getEquipCfgById(itemId)

            --container:getVarMenuItemImage():
            menu2Quality[PageInfo.nodeParams.qualityNode .. i] = itemInfo.quality
            sprite2Img[PageInfo.nodeParams.picNode .. i] = itemInfo.icon
            labels["mDecNumber"..i] = userEquip.strength == 0 and "" or "+" .. userEquip.strength
            labels["mRewardName"..i] =  common:getLanguageString("@LevelStr", itemInfo.level)
        else
            menu2Quality[PageInfo.nodeParams.qualityNode .. i] = 1
            sprite2Img[PageInfo.nodeParams.picNode .. i] = "UI/Mask/Image_Empty.png"
            --sprite2Img[PageInfo.nodeParams.picNode .. i] = GameConfig.Image.ChoicePic
            labels["mDecNumber"..i] = ""
            labels["mRewardName"..i] = ""
        end
    end

    NodeHelper:setSpriteImage(container, sprite2Img)
	NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setStringForLabel(container, labels)
end

-------------------------------------------------click event--------------------------------------------------------------------------

function SuitDecomposeBase:onAKeyInto( container )
    local UserEquipManager = require("Equip.UserEquipManager")
    local ids = UserEquipManager:getCanDecomposeEquipTable()
    if ids == nil or #ids == 0 then
        MessageBoxPage:Msg_Box_Lan("@NoSuitCanDecomposition") 
    end
    PageInfo.selectIds = common:table_tail(ids, COUNT_EQUIPMENT_SOURCE_MAX)
    self:refreshPage( container )

end

local function sendOnDecomposition(container)
    local msg = EquipOpr_pb.HPEquipDecompose()
    for _,id in pairs( PageInfo.selectIds ) do
        if id ~= nil then
            msg.equipId:append(id)
        end
    end
    common:sendPacket( opcodes.EQUIP_DECOMPOSE_C , msg ,true)
end

function SuitDecomposeBase:onDecomposition( container )
    if table.maxn(PageInfo.selectIds) <= 0 then
        MessageBoxPage:Msg_Box_Lan("@NoSuitDecomposition")  
        return
    end

    local sendMark = true
    for _,id in pairs( PageInfo.selectIds ) do
        if id ~= nil then
            local userEquip = UserEquipManager:getUserEquipById(id)
            local itemId = userEquip.equipId
            local itemInfo = EquipManager:getEquipCfgById(itemId)
            if itemInfo.quality == 10 then
                sendMark = false
                break
            end
        end
    end

    if sendMark then
        sendOnDecomposition(container)
    else
        local titile = common:getLanguageString("@suitDecompositionNotHave4");
        local tipinfo = common:getLanguageString("@suitDecompositionNotHave5");
        PageManager.showConfirm(titile,tipinfo, function(isSure)
        if isSure then
                sendOnDecomposition(container)
            end
        end);
    end
end

function SuitDecomposeBase:goSelectEquip( container ,eventName )
    local pos = tonumber(string.sub( eventName , -1 ))
    if PageInfo.selectIds[pos] then
        PageInfo.selectIds[pos] = nil 
        self:refreshPage( container )
        return
    end

--    EquipSelectPage_multiSelect( selectedIds ,COUNT_EQUIPMENT_SOURCE_MAX ,function(ids)
--        PageInfo.selectIds = {}
--        for k,v in pairs(ids) do
--		    table.insert(PageInfo.selectIds, k)
--        end
--        self:refreshPage( container )
--	end ,nil,EquipFilterType.SuitDec )


    
    EquipSelectPage_multiSelect( PageInfo.selectIds ,COUNT_EQUIPMENT_SOURCE_MAX ,function(ids)
        PageInfo.selectIds = {}
        for k,v in pairs(ids) do
		    table.insert(PageInfo.selectIds, k)
        end
        self:refreshPage( container )
	end ,nil,EquipFilterType.SuitDec )


    PageManager.pushPage("EquipSelectPage")
end

function SuitDecomposeBase:onClose( container )
    PageManager.popPage( thisPageName )
end

---------------------------------------------------------------------------------------------------------------------------

function SuitDecomposeBase:onReceivePacket( container )
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.EQUIP_DECOMPOSE_S then
        PageInfo.selectIds = {}
        self:refreshPage( container )
	end
end

function SuitDecomposeBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function SuitDecomposeBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
EquipSuitDecompose = CommonPage.newSub(SuitDecomposeBase, thisPageName, option)

