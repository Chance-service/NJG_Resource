local Activity2_pb = require("Activity2_pb")
local Const_pb = require("Const_pb")
local HP_pb = require("HP_pb")
local thisPageName = "ChatSkinPage"
local UserInfo = require("PlayerInfo.UserInfo");
local NodeHelper = require("NodeHelper");

local option = {
	ccbiFile = "ChatFrameChangePopUp.ccbi",
	handlerMap = {
        onClose = "onClose"
	},
	opcodes = {
        --CHAT_SKIN_OWNED_INFO_S = HP_pb.CHAT_SKIN_OWNED_INFO_S,
        CHAT_SKIN_CHANGE_S = HP_pb.CHAT_SKIN_CHANGE_S
	}
}

local ChatSkinPageBase = {}

local ChatSkinContent = {
    ccbiFile = "ChatFrameChangeContent.ccbi"
}

local skinActCfg = {}

local skinData = {}

function ChatSkinContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function ChatSkinContent:onChoiceBtn(container)
    local id = self.id
    if id == curSkinId then  
        local msg = Activity2_pb.HPChatSkinChange();
        msg.skinId = 0
	    common:sendPacket(HP_pb.CHAT_SKIN_CHANGE_C, msg, true);
    else
        local msg = Activity2_pb.HPChatSkinChange();
        msg.skinId = self.id
	    common:sendPacket(HP_pb.CHAT_SKIN_CHANGE_C, msg, true);
    end
end

function ChatSkinContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local data

    for i,v in ipairs(skinActCfg) do
        if v.skinId == id then
            data = v
            break
        end
    end
    local skinInfo = skinData[index]

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local scale9Img = {}
    local scale9Size = {}
    local capInsets = {}

    if data then
        local rect = CCRectMake(0,0,85,61)
        if data.skinRes:find("u_ChatBG") then
            rect = CCRectMake(0,0,143,61)
        end
        scale9Img.mChatBG = {
            name = data.skinRes,
            rect = rect
        }
        scale9Size.mChatBG = CCSizeMake(320,65)
        capInsets.mChatBG = {
            left = 47,
            right = 37,
            top = 30,
            bottom = 30
        }

        lb2Str.mDiscountTxt = common:getLanguageString(data.skinName)
        lb2Str.mTime = Language:getInstance():getString("@ActivityDays") .. skinInfo.remainTime  .. Language:getInstance():getString("@Days")
        visibleMap.mTime = skinInfo.remainTime ~= -1

        visibleMap.mSelected = id == curSkinId
    end
    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setScale9SpriteImage(container,scale9Img, capInsets ,scale9Size)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function ChatSkinPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function ChatSkinPageBase:onEnter(container)
    skinActCfg = ConfigManager.getChatSkinCfg()

    NodeHelper:initScrollView(container, "mContent", 3);

	self:registerPacket(container)

    self:clearAndReBuildAllItem(container)
end

function ChatSkinPageBase:onExecute(container)

end

function ChatSkinPageBase:onExit(container)
    skinActCfg = {}
    skinData = {}
    self:removePacket(container)
end

function ChatSkinPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function ChatSkinPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	if opcode == HP_pb.CHAT_SKIN_CHANGE_S then
        local msg = Activity2_pb.HPChatSkinChange();
		msg:ParseFromString(msgBuff)

        curSkinId = msg.skinId
        self:clearAndReBuildAllItem(container)
	end
end

function ChatSkinPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function ChatSkinPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function ChatSkinPageBase:clearAndReBuildAllItem(container)
    table.sort(skinData, function(a,b)
        return a.skinId > b.skinId
    end)
    container.mScrollView:removeAllCell()
    for i,v in ipairs(skinData) do
        local titleCell = CCBFileCell:create()
        local panel = ChatSkinContent:new({id = v.skinId, index = i})
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(ChatSkinContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
end

function ChatSkinPage_initData(data)
    skinData = data.skins
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local ChatSkinPage = CommonPage.newSub(ChatSkinPageBase, thisPageName, option);