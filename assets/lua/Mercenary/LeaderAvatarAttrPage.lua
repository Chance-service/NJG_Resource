local thisPageName = "LeaderAvatarAttrPage"
local LeaderAvatarManager = require("LeaderAvatarManager")

local LeaderAvatarAttrPageBase = {
}
 
local option = {
    ccbiFile = "FashionAttributePopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
    },
    opcodes = {
    }
}

local LeaderAvatarContent = {
    ccbiFile = "FashionAttributeContent.ccbi",
}

local initHeadQueue = {}

function LeaderAvatarContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function LeaderAvatarContent:onRefreshContent(ccbRoot)
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local id = LeaderAvatarManager:getNowStaticId()
    local cfg = LeaderAvatarManager.getAvatarCfg(id)
    local props = cfg["prop" .. index]
    lb2Str.mAtt1 = props
    visibleMap.mAtt3 = false
    visibleMap.mAttBG = index % 2 == 1

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function LeaderAvatarAttrPageBase:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function LeaderAvatarAttrPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function LeaderAvatarAttrPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    self:clearAndReBuildAllItem(container)
    --self:refreshPage(container)
end

function LeaderAvatarAttrPageBase:onExecute(container)
    
end

function LeaderAvatarAttrPageBase:onExit(container)
    self:removePacket(container)
    onUnload(thisPageName,container)
end

function LeaderAvatarAttrPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function LeaderAvatarAttrPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function LeaderAvatarAttrPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        
	end
end

function LeaderAvatarAttrPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local id = LeaderAvatarManager:getNowStaticId()
    local cfg = LeaderAvatarManager.getAvatarCfg(id)
    local list = {}
    for i = 1, 6 do
        if cfg["prop" .. i] ~= "" then
            table.insert(list, cfg["prop" .. i])
        end
    end
    if #list >= 1 then
        for i,v in ipairs(list) do
            local titleCell = CCBFileCell:create()
            local panel = LeaderAvatarContent:new({index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(LeaderAvatarContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
end

function LeaderAvatarAttrPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function LeaderAvatarAttrPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local LeaderAvatarAttrPage = CommonPage.newSub(LeaderAvatarAttrPageBase, thisPageName, option);