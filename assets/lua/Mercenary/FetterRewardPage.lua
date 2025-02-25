local thisPageName = "FetterRewardPage"
local FetterManager = require("FetterManager")
local UserMercenaryManager = require("UserMercenaryManager")
local ConfigManager = require("ConfigManager")

local FetterRewardPageBase = {
}
 
local option = {
    ccbiFile = "FetterRewardReviewPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onFrame1 = "onFrame1",
        onFrame2 = "onFrame2"
    },
    opcodes = {
    }
}

local rewardCfg = {}

local FetterRewardContent = {
    ccbiFile = "FetterRewardReviewContent.ccbi",
}

function FetterRewardContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function FetterRewardContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local data = rewardCfg[index]
    if data then
        lb2Str.mContentTitle = data.showName

        for i = 1, 5 do
            if i > data.roleNum then
                visibleMap["mMailPrizeNode" .. i] = false
                visibleMap["mEmpty" .. i] = true
            else
                visibleMap["mMailPrizeNode" .. i] = true
                visibleMap["mEmpty" .. i] = false

                local icon = "UI/Role/Mercenary_Portrait_Empty.png"
                local playerNode = container:getVarNode("mPlayerSprite" .. i)
                playerNode:removeAllChildren()
                local playerSprite = CCSprite:create(icon)
                playerNode:addChild(playerSprite)
            end
            visibleMap["mProtraitColour" .. i] = false
            local colorNode = container:getVarSprite("mProtraitColour" .. i)
            local colorParent = colorNode:getParent()
            local z = colorNode:getZOrder()
            local x,y = colorNode:getPosition()
            local texture = colorNode:getTexture()
            local newColorNode = GraySprite:new()
		    newColorNode:initWithTexture(texture,colorNode:getTextureRect())
            newColorNode:setPosition(ccp(x,y))
            newColorNode:setZOrder(z)
		    colorParent:addChild(newColorNode)
        end

        for i = 1, 2 do
            local reward = data.rewards[i]
            visibleMap["mRewardNode" .. i] = reward ~= nil
            if reward then
                local resInfo = ResManagerForLua:getResInfoByTypeAndId(reward.type, reward.itemId, reward.count)
                sprite2Img["mPic" .. i] = resInfo.icon
                sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
                menu2Quality["mFrame" .. i] = resInfo.quality
                lb2Str["mNumber" .. i] = "x" .. reward.count
            end
        end
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function FetterRewardContent:onFrame1(container)
    --local rewardIndex = tonumber(eventName:sub(8))--数字
    local index = self.index
    local data = rewardCfg[index]
    local rewards = data.rewards
    if rewards and rewards[1] then
        GameUtil:showTip(container:getVarNode('mPic1'), rewards[1])
    end
end

function FetterRewardContent:onFrame2(container)
    --local rewardIndex = tonumber(eventName:sub(8))--数字
    local index = self.index
    local data = rewardCfg[index]
    local rewards = data.rewards
    if rewards and rewards[2] then
        GameUtil:showTip(container:getVarNode('mPic2'), rewards[2])
    end
end

function FetterRewardPageBase:refreshPage(container)
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

function FetterRewardPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function FetterRewardPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    local _cfg = ConfigManager.getRelationshipRewardCfg()
    rewardCfg = {}
    for k,v in pairs(_cfg) do
        table.insert(rewardCfg,v)
    end
    table.sort(rewardCfg,function(a,b)
        return a.roleNum > b.roleNum
    end)
    NodeHelper:initScrollView(container, "mContent", 10);
    self:clearAndReBuildAllItem(container)
    self:refreshPage(container)
end

function FetterRewardPageBase:onExecute(container)
end

function FetterRewardPageBase:onExit(container)
    self:removePacket(container)
    rewardCfg = {}
    onUnload(thisPageName,container)
end

function FetterRewardPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function FetterRewardPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function FetterRewardPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        
	end
end

function FetterRewardPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    for i,v in ipairs(rewardCfg) do
        local titleCell = CCBFileCell:create()
        local panel = FetterRewardContent:new({id = v.roleNum, index = i})
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(FetterRewardContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
end

function FetterRewardPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function FetterRewardPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local FetterRewardPage = CommonPage.newSub(FetterRewardPageBase, thisPageName, option);