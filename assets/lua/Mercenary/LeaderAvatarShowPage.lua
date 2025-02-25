local thisPageName = "LeaderAvatarShowPage"
local LeaderAvatarManager = require("LeaderAvatarManager")
local ConfigManager = require("ConfigManager")
local UserInfo = require("PlayerInfo.UserInfo")
local ItemOprHelper   = require("Item.ItemOprHelper");
local HP_pb = require("HP_pb")
local ItemOpr_pb = require("ItemOpr_pb")

local LeaderAvatarShowPageBase = {
}
 
local option = {
    ccbiFile = "FashionRoleShowPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onGet = "onGet"
    },
    opcodes = {
        ITEM_USE_S = HP_pb.ITEM_USE_S
    }
}

local itemCfg = ConfigManager.getItemCfg();

local FetterShowContent = {
    ccbiFile = "FetterShowContent.ccbi",
}

function FetterShowContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function FetterShowContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

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

function LeaderAvatarShowPageBase:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local previewItem = LeaderAvatarManager:getPreviewItem()
    if not previewItem then 
        visibleMap.mGetNode = false
        previewItem = LeaderAvatarManager:getPreviewShop()
    end
    if previewItem then
        local item = itemCfg[previewItem.itemId]
        if item then
            local insideItem = common:parseItemWithComma(item.containItem)[1]
            if insideItem then
                local avatarCfg = LeaderAvatarManager.getAvatarCfg(insideItem.itemId)

                lb2Str.mTitle = avatarCfg.name
                lb2Str.mAtt = string.format("%s\n%s\n%s\n%s\n%s\n%s",
                    avatarCfg.prop1,avatarCfg.prop2,avatarCfg.prop3,
                    avatarCfg.prop4,avatarCfg.prop5,avatarCfg.prop6)

                lb2Str.mTime = common:getLanguageString("@FashionRoleUseTime", common:secondToDateXX(avatarCfg.maxDay * 24 * 60 * 60))

                visibleMap.mRole1 = true
                visibleMap.mRole2 = false
                visibleMap.mRole3 = false

                local showCfg = GameConfig.LeaderAvatarInfo[insideItem.itemId]
                sprite2Img.mRole1 = showCfg.staticImg[UserInfo.roleInfo.prof]
            end
        end
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function LeaderAvatarShowPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function LeaderAvatarShowPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    --self:clearAndReBuildAllItem(container)
    self:refreshPage(container)
end

function LeaderAvatarShowPageBase:onExecute(container)
    
end

function LeaderAvatarShowPageBase:onExit(container)
    self:removePacket(container)
    onUnload(thisPageName,container)
end

function LeaderAvatarShowPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function LeaderAvatarShowPageBase:onGet(container)
     local previewItem = LeaderAvatarManager:getPreviewItem()
    if not previewItem then 
        previewItem = LeaderAvatarManager:getPreviewShop()
    end
    if previewItem then
        ItemOprHelper:useItem(previewItem.itemId, 1)
    end
end

function LeaderAvatarShowPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ITEM_USE_S then
        PageManager.popPage(thisPageName)
    end
end

function LeaderAvatarShowPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        
	end
end

function LeaderAvatarShowPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function LeaderAvatarShowPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local LeaderAvatarShowPage = CommonPage.newSub(LeaderAvatarShowPageBase, thisPageName, option);