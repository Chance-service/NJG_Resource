----------------------------------------------------------------------------------
local GameConfig = require("GameConfig")

local option = {
	ccbiFile = "BattleSpeechChatExpressionItem.ccbi",
	handlerMap = {
		onClose					= "onClose"
	},

}

local ChatFaceBase = {}
local ChatFaceLineBase = {}
local PageInfo = {
	ONE_LINE_COUNT = 7,
	chatFace
}
-----------------------------------------------------------------------------------
function ChatFaceLineBase.onFunction( eventName, container )
	if eventName == "luaRefreshItemView" then
		ChatFaceLineBase.onRefreshItemView( container )
	end
end

function ChatFaceLineBase.onRefreshItemView( container )
	local contentId = container:getItemDate().mID
	local baseIndex = (contentId - 1) * PageInfo.ONE_LINE_COUNT
	
	for i = 1, PageInfo.ONE_LINE_COUNT do
		local nodeContainer = container:getVarNode("mExpressionNode" .. i)
		NodeHelper:setNodeVisible(nodeContainer, false)
		nodeContainer:removeAllChildren()
		
		local itemNode = nil
		local index = baseIndex + i
		
		if index <= #GameConfig.ChatFace then
			itemNode = ChatFaceLineBase.newLineItem(index)
		end
		
		if itemNode then
			nodeContainer:addChild(itemNode)
			NodeHelper:setNodeVisible(nodeContainer, true)
		end
	end
	
end

function ChatFaceLineBase.newLineItem(index)
	local itemNode = ScriptContentBase:create("BattleSpeechChatExpressionContent.ccbi", index)
	itemNode:registerFunctionHandler(ChatFaceLineBase.HeadItemFunction)

	local  picPath = GameConfig.ChatBigFace[index]
	
	NodeHelper:setSpriteImage(itemNode, {mExpression = picPath})
		
	itemNode:release()
	
	return itemNode
end

function ChatFaceLineBase.HeadItemFunction(eventName, container)
	if eventName == "onExpression" then
		ChatFaceLineBase.onExpression( container )	
	end
end

function ChatFaceLineBase.onExpression( container )
	local index = container:getTag()
	PageInfo.chatFace = "/" .. index .. "/"
	if ChatFaceBase.owner then
		ChatFaceBase.owner:addFaceToInputContent(PageInfo.chatFace)
	end
end

function ChatFaceBase:init( container, owner)
	ChatFaceBase.owner = owner
	NodeHelper:initScrollView(container, "mExpressionContent", 2)
	self:rebuildAllItem( container )
end

function ChatFaceBase:rebuildAllItem( container )
	self:clearAllItem( container )
	self:buildItem( container )
end

function ChatFaceBase:clearAllItem( container )
	NodeHelper:clearScrollView(container)
end

function ChatFaceBase:buildItem( container )
	
	local size = math.ceil(#GameConfig.ChatFace / PageInfo.ONE_LINE_COUNT)
	
	NodeHelper:buildScrollView(container, size, "BattleSpeechChatExpressionItem2.ccbi", ChatFaceLineBase.onFunction)

end

return ChatFaceBase