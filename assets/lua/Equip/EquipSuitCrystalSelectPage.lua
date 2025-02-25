

local HP_pb = require("HP_pb") --包含协议id文件
local thisPageName = "EquipSuitCrystalSelectPage"
local UserItemManager = require("Item.UserItemManager")
local Const_pb 		= require("Const_pb")
local suitItems = {}  --装备碎片
local alreadySelItems = {}  --已经选择了的装备碎片
local showItems = {} --显示的装备碎片
local ITEM_COUNT_PER_LINE = 5

----这里是协议的id
local opcodes = {
    EQUIP_RESONANCE_INFO_C = HP_pb.EQUIP_RESONANCE_INFO_C,
    HEAD_FRAME_STATE_INFO_S = HP_pb.HEAD_FRAME_STATE_INFO_S
}

local option = {
    ccbiFile = "SuitPatchDecompositionChoosePopUp.ccbi",
    handlerMap = { --按钮点击事件
        onClose     = "onClose",
    },
    opcode = opcodes
}

local EquipSuitCrystalSelectPageBase = {}
function EquipSuitCrystalSelectPageBase:onEnter(container)
	self:setShowItems(container)

	container:registerMessage(MSG_MAINFRAME_REFRESH)
	NodeHelper:initScrollView(container, "mContent", ITEM_COUNT_PER_LINE);

	self:buildItem(container)
    self:registerPacket(container)
    local relativeNode = container:getVarNode("mContentBg")
    GameUtil:clickOtherClosePage(relativeNode, function ()
        self:onClose(container)
    end,container)
end

function EquipSuitCrystalSelectPageBase:setShowItems(container)
    local function createItem(data)
        local temp = {}
        temp.id = data.id
        temp.itemId = data.itemId
        temp.count = data.count
        temp.status = data.status
        temp.exp = data.exp
        return temp
    end

    suitItems = {}
    showItems = {}
    --获取当前套装碎片
    suitItems = UserItemManager:getItemsByType(Const_pb.SUIT_FRAGMENT)
    local temps = {}
    --把已经选中的碎片相同的id 数量合并到一起
    for k,v in pairs(alreadySelItems) do
        if temps[v.id] then
            temps[v.id].count = temps[v.id].count + v.count
        else
            local xx = createItem(v)
            temps[v.id] = xx
        end
    end

    ---已选中与全部的碎片比较 求出要显示的个数
    for k,v in pairs(suitItems) do
        if temps[v.id] then 
            local xx = createItem(v)--common:deepCopy(v) --这里本来可以用深拷贝 但是是proto的数据 所以拷贝不了

            showItems[#showItems+1] = v 
            showItems[#showItems].count = v.count - temps[v.id].count
        else
            local xx = createItem(v)
            showItems[#showItems+1] = v
        end
    end

    ---去掉显示中的碎片 <=0 的碎片
    local i = 1
    while i <= #showItems do
        if showItems[i].count<= 0 then
            table.remove( showItems, i )
        else
            i = i + 1
        end
    end
end

function EquipSuitCrystalSelectPageBase:buildItem(container)
    NodeHelper:clearScrollView(container)  ---这里是清空滚动层
    local size = #showItems --  BackpackItem.ccbi
    if size == 0 then
        NodeHelper:setStringForLabel(container, {mSuitPatchChooseInfo = tostring(Language:getInstance():getString("@suitDecompositionNotHave2"))})
        NodeHelper:setColorForLabel( container, {mSuitPatchChooseInfo = GameConfig.ColorMap.COLOR_GRAY} )
        return
    else
        NodeHelper:setStringForLabel(container, {mSuitPatchChooseInfo = tostring(Language:getInstance():getString("@suitDecompositionNotHave3"))})
        NodeHelper:setColorForLabel( container, {mSuitPatchChooseInfo = GameConfig.ColorMap.COLOR_GREEN} )
    end
    size = math.ceil(size / ITEM_COUNT_PER_LINE) --
    NodeHelper:buildScrollView(container, size, "SuitPatchDecompositionChooseContent.ccbi", EquipSuitCrystalSelectPageBase.onFunction) --
end

function EquipSuitCrystalSelectPageBase.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then   ---每个子空间创建的时候会调用这个函数
        EquipSuitCrystalSelectPageBase.onRefreshItemView(container);
    elseif string.sub(eventName,1,6)=="onHand" then  --点击每个子空间的时候会调用函数
        local index = string.sub(eventName,7,-1)
        index = tonumber(index)
        local contentId = container:getItemDate().mID;
        local baseIndex = (contentId - 1) * ITEM_COUNT_PER_LINE;
        index = index + baseIndex 
        local data = showItems[index]

        require("SuitPatchNumberPopUpPage")
        SuitPatchNumberPopUpPageBase_setCurItemData(data)
        PageManager.pushPage("SuitPatchNumberPopUpPage")
    end
end

function EquipSuitCrystalSelectPageBase.onRefreshItemView(container)
    local NodeHelper = require("NodeHelper");

    local contentId = container:getItemDate().mID;  --获取到时第几行
    local baseIndex = (contentId - 1) * ITEM_COUNT_PER_LINE; --
	
    for i = 1, ITEM_COUNT_PER_LINE do
        local index = baseIndex + i;   --获取当前的index      i是每行的第几个 用来获取组件用的
        local data = showItems[index]
   
        NodeHelper:setNodesVisible(container, {["mPosition"..i] = false})	
        if data then 
        	NodeHelper:setNodesVisible(container, {["mPosition"..i] = true})	
        	local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, data.itemId, data.count);
			local lb2Str = {
				["mNumber"..i]	= "x" .. data.count
			}
--[[            local lbStr = {
                ["mNumber"..i]	= "32 29 0"
            }]]
			NodeHelper:setStringForLabel(container, lb2Str);
            NodeHelper:setBlurryString(container,"mName"..i , resInfo.name, GameConfig.LineWidth.ItemNameLength - 80,5)
			NodeHelper:setSpriteImage(container, {["mPic"..i] = resInfo.icon});
			NodeHelper:setQualityFrames(container, {["mHand"..i] = resInfo.quality});
			NodeHelper:setColor3BForLabel(container, {["mName"..i] = common:getColorFromConfig("Own")});
            NodeHelper:setColorForLabel(container,{["mName"..i] = ConfigManager.getQualityColor()[resInfo.quality].textColor})
        end  
    end
end

function EquipSuitCrystalSelectPageBase:onExecute(container)

end

function EquipSuitCrystalSelectPageBase:onExit(container)
    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
end


function EquipSuitCrystalSelectPageBase:onClose(container)
    GameUtil:hideClickOtherPage()
    PageManager.popPage(thisPageName)
    --PageManager.changePage("MainScenePage") 
    --PageManager.pushPage("PlayerInfoPage")
end

function EquipSuitCrystalSelectPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then
        local msg = HeadFrame_pb.HPHeadFrameStateRet()
        msg:ParseFromString(msgBuff)
        protoDatas = msg

        --self:rebuildItem(container)
        return
    end     
end

function EquipSuitCrystalSelectPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam;
        --
        if pageName == thisPageName and extraParam == "selected" then --
            self:onClose(container)
        end
    end
end

function EquipSuitCrystalSelectPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EquipSuitCrystalSelectPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

function EquipSuitCrystalSelectPageBase_setAlreadySelItem(_alreadySelItems)
    alreadySelItems = _alreadySelItems
end

local CommonPage = require('CommonPage')
local EquipSuitCrystalSelectPage= CommonPage.newSub(EquipSuitCrystalSelectPageBase, thisPageName, option)