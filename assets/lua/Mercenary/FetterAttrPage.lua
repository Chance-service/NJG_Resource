local thisPageName = "FetterAttrPage"
local FetterManager = require("FetterManager")
local UserMercenaryManager = require("UserMercenaryManager")

local FetterAttrPageBase = {
}
 -----sdfsdf
local option = {
    ccbiFile = "FetterRewardAni.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHand1 = "onHand1",
        onHand2 = "onHand2"
    },
    opcodes =
    {
    }
}

local FetterAttrContent = {
    ccbiFile = "FetterAttributeContent.ccbi",
}

function FetterAttrContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function FetterAttrContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }



    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function FetterAttrPageBase:refreshPage(container)
    -- container:runAnimation("Gacha")
    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }


    NodeHelper:setNodesVisible(container, { mInfo1 = false })

    local relationId = FetterManager.getOpenRealtion()
    if relationId and relationId > 0 then
        local cfg = FetterManager.getRelationCfgById(relationId)
        if cfg then
            lb2Str.mFetterName = cfg.name
            lb2Str.mAtt = cfg.property
            for i = 1, 2 do
                local rewards = cfg.reward[i]
                visibleMap["mRewardNode" .. i] = rewards ~= nil
                if rewards then
                    local resInfo = ResManagerForLua:getResInfoByTypeAndId(rewards.type, rewards.itemId, rewards.count)
                    sprite2Img["mPic" .. i] = resInfo.icon
                    sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
                    menu2Quality["mHand" .. i] = resInfo.quality
                    lb2Str["mNumber" .. i] = "x" .. rewards.count
                end
            end
        end
    end

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function FetterAttrPageBase:onHand1(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local relationId = FetterManager.getOpenRealtion()
    if relationId and relationId > 0 then
        local cfg = FetterManager.getRelationCfgById(relationId)
        if cfg then
            if cfg.reward and cfg.reward[1] then
                GameUtil:showTip(container:getVarNode('mPic1'), cfg.reward[1])
            end
        end
    end
end

function FetterAttrPageBase:onHand2(container)
    -- local rewardIndex = tonumber(eventName:sub(8))--数字
    local relationId = FetterManager.getOpenRealtion()
    if relationId and relationId > 0 then
        local cfg = FetterManager.getRelationCfgById(relationId)
        if cfg then
            if cfg.reward and cfg.reward[2] then
                GameUtil:showTip(container:getVarNode('mPic2'), cfg.reward[2])
            end
        end
    end
end

function FetterAttrPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function FetterAttrPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    -- self:clearAndReBuildAllItem(container)
    self:refreshPage(container)
end

function FetterAttrPageBase:onExecute(container)
end

function FetterAttrPageBase:onExit(container)
    self:removePacket(container)
    FetterManager.clearOpenRelation()
    onUnload(thisPageName, container)
end

function FetterAttrPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function FetterAttrPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
end

function FetterAttrPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam

    end
end

function FetterAttrPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local fetterId = FetterManager.getViewFetterId()
    local list = FetterManager.getAllRelationByFetterId(fetterId)
    if #list >= 1 then
        for i, v in ipairs(list) do
            local titleCell = CCBFileCell:create()
            local panel = FetterAttrContent:new( { id = v.id, index = i })
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(FetterAttrContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
end

function FetterAttrPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function FetterAttrPageBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local FetterAttrPage = CommonPage.newSub(FetterAttrPageBase, thisPageName, option);