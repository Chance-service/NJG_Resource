--TDOO 目前只支持看 不支持解锁  功能还没做完
local HP_pb = require("HP_pb") -- 包含协议id文件
local ItemManager = require("ItemManager")
local EquipManager = require("EquipManager")
local curItemData = nil -- 当前物品数据
local curCount = 1 -- 当前数量
local mMultiple = 1
----这里是协议的id
local opcodes = {
    EQUIP_RESONANCE_INFO_C = HP_pb.EQUIP_RESONANCE_INFO_C,
    HEAD_FRAME_STATE_INFO_S = HP_pb.HEAD_FRAME_STATE_INFO_S
}

local option = {
    ccbiFile = "MercenarySpecialGroup.ccbi",
    handlerMap =
    {
        onClose = "onNo",
    }
}
local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "MercenarySpecialGroupPage";
local CommonPage = require("CommonPage");

local NodeHelper = require("NodeHelper");
local MercenarySpecialGroupPage = { }



local FetterShowContent = {
    ccbiFile = "FetterShowContent.ccbi",
}

local initHeadQueue = { }

function FetterShowContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function FetterShowContent:onRefreshContent(ccbRoot)
    CCLuaLog("FetterContent:onRefreshContent")
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local lb2Color = { }
    local visibleMap = { }
    local labelColorMap = { }
    local baseNodeWidth = container:getVarNode("mProtraitColour1"):getContentSize().width

    local initBaseNodePosX = 40
    local baseDistance = container:getVarNode("mMailPrizeNode2"):getPositionX() - container:getVarNode("mMailPrizeNode1"):getPositionX()

    local data = FetterManager.getRelationCfgById(id)
    if data then
        lb2Str.mFetterAtt = data.property

        local activeNum = 0
        for i = 1, 5 do
            local fetterId = data.team[i]
            local base = container:getVarNode(string.format("mMailPrizeNode%d", i))
            base:setVisible(false)

            local color = GameConfig.ColorMap.COLOR_WHITE
            if fetterId then
                base:setVisible(true)

                local num = #data.team
                local baseX = base:getPositionX()
                local x =(5 - #data.team) * baseDistance / 2 + initBaseNodePosX +(baseDistance *(i - 1))

                base:setPosition(ccp(x, base:getPositionY()))
                local illInfo = FetterManager.getIllCfgById(fetterId)
                lb2Str["mMercenaryName" .. i] = illInfo.name
                local quality = illInfo._type % 10
                sprite2Img["mProtraitColour" .. i] = GameConfig.MercenaryQualityImage[quality]
                local curSoul = 0
                local maxSoul = illInfo.soulNumber
                local roleData = ConfigManager.getRoleCfg()[illInfo.roleId]
                local playerNode = container:getVarNode("mPlayerSprite" .. i)
                playerNode:removeAllChildren()
                local icon = "UI/Role/Mercenary_Portrait_Empty.png"
                if roleData then
                    icon = roleData.icon
                    -- local playerSprite = CCSprite:create(roleData.icon)
                else
                    visibleMap["mCoinNumNode" .. i] = false
                end

                local roleInfo = FetterManager.getIllData(illInfo.roleId)
                if roleInfo then
                    visibleMap["mCoinNumNode" .. i] = not roleInfo.activated
                    lb2Str["mCoinNum" .. i] = string.format("%d/%d", roleInfo.soulCount, maxSoul)

                    color =(roleInfo.soulCount > 0 or roleInfo.activated) and GameConfig.ColorMap.COLOR_RED or GameConfig.ColorMap.COLOR_WHITE
                    visibleMap["mMercenaryLock" .. i] =(not roleInfo.activated)
                    if roleInfo.activated then
                        activeNum = activeNum + 1
                        local playerSprite = CCSprite:create(icon)
                        playerNode:addChild(playerSprite)
                    else
                        if roleData then
                            local graySprite = GraySprite:new()
                            local playerSprite = CCSprite:create(icon)
                            local texture = playerSprite:getTexture()
                            graySprite:initWithTexture(texture, playerSprite:getTextureRect())
                            playerNode:addChild(graySprite)
                        else
                            local playerSprite = CCSprite:create(icon)
                            playerNode:addChild(playerSprite)
                        end
                    end
                else
                    if roleData then
                        visibleMap["mCoinNumNode" .. i] = true
                        lb2Str["mCoinNum" .. i] = string.format("%d/%d", 0, maxSoul)
                        local graySprite = GraySprite:new()
                        local playerSprite = CCSprite:create(icon)
                        local texture = playerSprite:getTexture()
                        graySprite:initWithTexture(texture, playerSprite:getTextureRect())
                        playerNode:addChild(graySprite)
                    else
                        local playerSprite = CCSprite:create(icon)
                        playerNode:addChild(playerSprite)
                    end
                end
                if roleData then
                    color = ConfigManager.getQualityColor()[roleData.quality].textColor
                end
                -- lb2Color["mCoinNum" .. i] = color
                lb2Color["mMercenaryName" .. i] = color
            end
        end

        lb2Str.mFetterNameTxt = data.name
        lb2Str.mMercenaryNum = string.format("(%s)", string.format("%d/%d", activeNum, #data.team))

        local isOpen = FetterManager.isRelationOpen(id)
        local enable = activeNum == #data.team and not isOpen
        NodeHelper:setMenuItemEnabled(container, "mOpenBtn", enable)
        visibleMap.mFetterOpenPoint = enable

        if isOpen then
            sprite2Img["mAwakeTitle"] = GameConfig.MercenaryAwakeImage[2]
        else
            sprite2Img["mAwakeTitle"] = GameConfig.MercenaryAwakeImage[1]
        end

        if enable then
            sprite2Img["mAwakeTitle"] = GameConfig.MercenaryAwakeImage[3]
        end
    end

    visibleMap["mOpenBtnNode"] = false

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setColorForLabel(container, labelColorMap)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)

    NodeHelper:setColorForLabel(container, lb2Color)
end

----------------------------------------------------------------------------------
-- CountTimesWithIconPage页面中的事件处理
----------------------------------------------
function MercenarySpecialGroupPage:onEnter(container)
    self:registerPacket(container)
    self:refreshPage(container);
    NodeHelper:initScrollView(container, "mContent", 10);
    self:clearAndReBuildAllItem(container)
    -- container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
end

function MercenarySpecialGroupPage:onExecute(container)

end


-- 标签页
function MercenarySpecialGroupPage:onExit(container)
    self:removePacket(container)
end

function MercenarySpecialGroupPage:onNo(container)
    PageManager.popPage(thisPageName)
end

function MercenarySpecialGroupPage:refreshPage(container)
    --    local sprite2Img = {}
    --    local scaleMap = {}
    --    if  fetterId == 0 then
    --        fetterId = FetterManager.getViewFetterId()
    --        data = FetterManager.getIllCfgById(fetterId)
    --        if data then
    --            suitInfo = EquipManager:getMercenaryAllSuitByMercenaryId(data.roleId)
    --        end
    --    end
    --    local suitInfoTmp = {}
    --    if #suitInfo > 0 then
    --        suitInfoTmp = suitInfo[1]
    --    end

    --    local illInfo = FetterManager.getIllCfgById(fetterId)
    --    local roleData = ConfigManager.getRoleCfg()[illInfo.roleId]

    --    sprite2Img = {
    -- 		mEquipPic = EquipManager:getIconById(suitInfoTmp["equipId"]),
    --            mRolePic = roleData.icon
    -- 	}
    --   name = common:getLanguageString("@ExchangeExclusiveTxt",illInfo.name)

    --   NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)

    --   NodeHelper:setStringForLabel(container,{
    --        mCostGoldLab = common:getLanguageString("@SuitGetLab"),
    --        mTitle = common:getLanguageString("@SuitPatchNumberTitle"),
    --        mDecisionTex = name,
    --        mAddNum = curCount
    --    })
end


function MercenarySpecialGroupPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then
        local msg = HeadFrame_pb.HPHeadFrameStateRet()
        msg:ParseFromString(msgBuff)
        protoDatas = msg

        -- self:rebuildItem(container)
        return
    end
end

function MercenarySpecialGroupPage:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then
        -- 这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;

        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then

        end
    end
end

function MercenarySpecialGroupPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function MercenarySpecialGroupPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

function MercenarySpecialGroupPage:refreshCountAndPrice(container)
    if curCount > maxCount then
        curCount = maxCount
    end
    resEnough = true
    NodeHelper:setStringForLabel(container, { mAddNum = curCount })
    NodeHelper:setStringForLabel(container, { mFinalNum = curCount * 2 })
end

function MercenarySpecialGroupPage:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local fetterId = FetterManager.getViewFetterId()
    local list = FetterManager.getAllRelationByFetterId(fetterId)
    if #list >= 1 then
        for i, v in ipairs(list) do
            local titleCell = CCBFileCell:create()
            local panel = FetterShowContent:new( { id = v.id, index = i })
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(FetterShowContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
    NodeHelper:setNodesVisible(container, { mEmptyFetterTxt = #list < 1 })
end

function MercenarySpecialGroupPage:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_MAINFRAME_PUSHPAGE then
        local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            self:refreshPage(container);
        end
    end
end
-------------------------------------------------------------------------------

local CommonPage = require('CommonPage')
MercenarySpecialGroupPage = CommonPage.newSub(MercenarySpecialGroupPage, thisPageName, option)

return MercenarySpecialGroupPage

