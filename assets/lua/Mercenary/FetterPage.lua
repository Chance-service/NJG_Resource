local thisPageName = "FetterPage"

local FetterManager = require("FetterManager")
local UserMercenaryManager = require("UserMercenaryManager")
local UserInfo = require("PlayerInfo.UserInfo")

local FetterPageBase = {
    curShowType = - 1,
    container = nil
}

local option = {
    ccbiFile = "FetterIllustratedPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onRole1 = "onRole1",
        onRole2 = "onRole2",
        onRole3 = "onRole3",
        onHelp = "onHelp",
        onAtt = "onAtt",
        onInfo = "onInfo"
    },
    opcodes =
    {
    }
}
local spritePoolList = {}
local WaitRefreshList = {}
local mItemRowCount = 5;
local IllContent = {
    ccbiFile = "FetterIllustratedContent.ccbi",
    originW = 518,
    originW2 = 508,
    originH = 195,
    originH2 = 130,
    originY = 0,
}

local IllLineContent = {
    ccbiFile = "FetterIllustratedListContent.ccbi"
}

local FetterContent = {
    ccbiFile = "FetterContent.ccbi",
}

local FetterContentBase = {
    curFetterId = 0,
    fetterAlbum = 0
}

local IllItemContent = {
    ccbiFile = "FetterIllustratedListContent.ccbi"
}

function IllItemContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    if not self.mShowItem then
        container:setVisible(false)
        return
    end
    container:setVisible(true)
    local lb2Color = { }
    local spriteParent = container:getVarNode("mPlayerSprite1")
    local roleData = FetterManager.getRoleCfg(self.data.roleId)
    local roleInfo = FetterManager.getIllData(self.data.roleId)
    --local visibleMap = {mMercenaryLock1 = false,mCoinNumNode1 = false}
    local visibleMap = {mCoinNumNode1 = false}
    if not roleInfo or not roleInfo.activated then
        --visibleMap.mMercenaryLock1 = true
        visibleMap.mCoinNumNode1 = true
    end
    local mName =  FetterManager.getIllCfgByRoleId(self.data.roleId).name or roleData.name
    local isShowRole = false----活动上线新佣兵不显示，特殊处理，Astor
    if spriteParent and roleData then
        local playerSprite = spritePoolList[self.data.roleId]
--        for k,v in pairs(ConfigManager.getAnniversaryJigsawPuzzleCfg()) do
--           --活动期间，并且是当前活动的佣兵
--            if v.items[1].itemId == self.data.roleId and ActivityInfo:getActivityValid(141) then
--                isShowRole = true
--                break
--            end
--        end
        if roleInfo and roleInfo.activated then----如果已经激活了，直接显
            isShowRole = false
        end
        if isShowRole then----活动期间显示问号，不显示佣兵
            --visibleMap.mMercenaryLock1 = false
            visibleMap.mCoinNumNode1 = false
            mName = "?"
        end
        if not playerSprite then
            if isShowRole then--��ڼ���ʾ�ʺţ�����ʾӶ��
                playerSprite = CCSprite:create("UI/Role/Mercenary_Portrait_Empty.png")
            else
                playerSprite = CCSprite:create(roleData.icon)
            end
            
            if isShowRole or not roleInfo or not roleInfo.activated then
                local graySprite = GraySprite:new()
                graySprite:initWithTexture(playerSprite:getTexture(),playerSprite:getTextureRect())
                playerSprite = graySprite
            else
                playerSprite:retain()
            end
            spritePoolList[self.data.roleId] = playerSprite
        end
        if playerSprite:getParent() then
            playerSprite:removeFromParentAndCleanup(false)
        end
        spriteParent:addChild(playerSprite)
    end
    
    NodeHelper:setStringForLabel(container,{
            mCoinNum1 = string.format("%d/%d",roleInfo and roleInfo.soulCount or 0,self.data.soulNumber),
            mMercenaryName1 = mName
        })

         local color = GameConfig.ColorMap.COLOR_WHITE
         if roleInfo then
               -- visibleMap["mCoinNumNode" .. i] = not roleInfo.activated
               -- lb2Str["mCoinNum" .. i] = string.format("%d/%d", roleInfo.soulCount, maxSoul)
                color =(roleInfo.soulCount > 0 or roleInfo.activated) and GameConfig.ColorMap.COLOR_RED or GameConfig.ColorMap.COLOR_FRIEND_OTHER
          end
        if roleData then
            color = ConfigManager.getQualityColor()[roleData.quality].textColor
        end
        lb2Color["mMercenaryName1"] = color

    NodeHelper:setSpriteImage(container,{mProtraitColour1 = GameConfig.MercenaryQualityImage[roleData.quality]})
    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setColorForLabel(container, lb2Color)

    --    NodeHelper:setNodesVisible(container, visibleMap)
--    NodeHelper:setStringForLabel(container, lb2Str)
--    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
--    NodeHelper:setQualityFrames(container, menu2Quality)

--    NodeHelper:setColorForLabel(container, lb2Color)


--    if data then
--        for i = 1, FetterManager.illLineNumber do
--            local base = container:getVarNode(string.format("mMailPrizeNode%d", i))
--            local info = data[i]
--            base:setVisible(false)
--            if info then
--                local color = GameConfig.ColorMap.COLOR_WHITE

--                local maxSoul = info.soulNumber
--                lb2Str["mMercenaryName" .. i] = info.name

--                local quality = info._type % 10


--                -- sprite2Img["mProtraitColour" .. i] = GameConfig.MercenaryQualityImage[quality]

--                local roleData = ConfigManager.getRoleCfg()[info.roleId]
--                sprite2Img["mProtraitColour" .. i] = GameConfig.MercenaryQualityImage[roleData.quality]
--                if roleData then
--                    if not self.initHead[i] then
--                        -- local playerSprite = CCSprite:create(roleData.icon)
--                        local playerNode = container:getVarNode("mPlayerSprite" .. i)
--                        table.insert(initHeadQueue, {
--                            base = playerNode,
--                            icon = roleData.icon,
--                            node = base,
--                            fetterId = info.id,
--                            roleId = info.roleId,
--                            line = self,
--                            index = i,
--                            name = info.name
--                        } )
--                    else
--                        base:setVisible(true)
--                    end

--                end

--                local roleInfo = FetterManager.getIllData(info.roleId)
--                visibleMap["mMercenaryLock" .. i] =(not roleInfo.activated)
--                if roleInfo then
--                    visibleMap["mCoinNumNode" .. i] = not roleInfo.activated
--                    lb2Str["mCoinNum" .. i] = string.format("%d/%d", roleInfo.soulCount, maxSoul)
--                    color =(roleInfo.soulCount > 0 or roleInfo.activated) and GameConfig.ColorMap.COLOR_RED or GameConfig.ColorMap.COLOR_FRIEND_OTHER
--                else
--                    if roleData then
--                        visibleMap["mCoinNumNode" .. i] = true
--                        lb2Str["mCoinNum" .. i] = string.format("%d/%d", 0, maxSoul)
--                    end
--                end

--                -- lb2Color["mCoinNum" .. i] = color
--                if roleData then
--                    color = ConfigManager.getQualityColor()[roleData.quality].textColor
--                end
--                lb2Color["mMercenaryName" .. i] = color
--            end
--        end
--    end

--    NodeHelper:setNodesVisible(container, visibleMap)
--    NodeHelper:setStringForLabel(container, lb2Str)
--    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
--    NodeHelper:setQualityFrames(container, menu2Quality)

--    NodeHelper:setColorForLabel(container, lb2Color)
end

function IllItemContent:onPreLoad(ccbRoot)
end

function IllItemContent:onUnLoad(ccbRoot)
   -- CCLuaLog("IllItemContent:onUnLoad")
end

function IllItemContent:RefreshItem()
    if self.cell:isLoaded() then
        local container = self.cell:getCCBFileNode()
        if container then
            self.mShowItem = true
            self:onRefreshContent(self.cell)
            return true
        end
    end
    return false
end

function IllItemContent:onMercenary1(container)
    local roleInfo = FetterManager.getIllData(self.data.roleId)
--    local isShowRole = false---活动上线新佣兵不显示，特殊处理，Astor
--     for k,v in pairs(ConfigManager.getAnniversaryJigsawPuzzleCfg()) do
--         --活动期间，并且是当前活动的佣兵
--        if v.items[1].itemId == self.data.roleId and ActivityInfo:getActivityValid(141) then
--            isShowRole = true
--            break
--        end
--    end
    if roleInfo and roleInfo.activated then----如果已经激活了，直接显示
        isShowRole = false
    end
    if not isShowRole then
        FetterManager.setViewFetterId(self.data.id)
        PageManager.pushPage("FetterShowPage")
    end
end









local initHeadQueue = { }

local initLineQueue = { }

local headTemp = { }

local lineTemp = { }

local changePageTemp = nil

function IllLineContent:new(_type, line, maxLine)
    local illItem = { }
    setmetatable(illItem, self)
    self.__index = self

    illItem._type = _type
    illItem.line = line
    illItem:init(maxLine)
    illItem.initHead = { }
    return illItem
end

function IllLineContent:init(maxLine)
    local container = ScriptContentBase:create(self.ccbiFile)
    self.node = container
    container:setPosition(ccp(0, 120 *(maxLine - self.line)))
    container:registerFunctionHandler( function(eventName, container)
        if string.find(eventName, "onMercenary") then
            local index = tonumber(string.sub(eventName, -1))
            self:onMercenary(container, index)
        elseif self[eventName] and type(self[eventName]) == "function" then
            self[eventName](self, container)
        end
    end )
    -- self:refresh()
end

function IllLineContent:retain()
    if self.node then
        self.node:retain()
    end
end

function IllLineContent:release()
    if self.node then
        self.node:release()
    end
end

function IllLineContent:onMercenary(container, index)
    local id = self._type
    local line = self.line
    local data = FetterManager.getOneIllLine(id, line)
    local item = data[index]
    if item then
        FetterManager.setViewFetterId(item.id)
        PageManager.pushPage("FetterShowPage")
    end
end

function IllLineContent:refresh(parent)
    local container = self.node
    if container:getParent() then
        container:removeFromParentAndCleanup(true)
    end
    if parent then
        parent:addChild(container)
    end
    local id = self._type
    local index = self.line

    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local lb2Color = { }
    local visibleMap = { }

    local data = FetterManager.getOneIllLine(id, index)

--    local t = { }
--    for k, v in pairs(data) do
--        if v.isOpen == 1 then
--            table.insert(t, v)
--        end
--    end
--    data = t

    if data then
        for i = 1, FetterManager.illLineNumber do
            local base = container:getVarNode(string.format("mMailPrizeNode%d", i))
            local info = data[i]
            base:setVisible(false)
            if info then
                local color = GameConfig.ColorMap.COLOR_WHITE

                local maxSoul = info.soulNumber
                lb2Str["mMercenaryName" .. i] = info.name

                local quality = info._type % 10


                -- sprite2Img["mProtraitColour" .. i] = GameConfig.MercenaryQualityImage[quality]

                local roleData = ConfigManager.getRoleCfg()[info.roleId]
                sprite2Img["mProtraitColour" .. i] = GameConfig.MercenaryQualityImage[roleData.quality]
                if roleData then
                    if not self.initHead[i] then
                        -- local playerSprite = CCSprite:create(roleData.icon)
                        local playerNode = container:getVarNode("mPlayerSprite" .. i)
                        table.insert(initHeadQueue, {
                            base = playerNode,
                            icon = roleData.icon,
                            node = base,
                            fetterId = info.id,
                            roleId = info.roleId,
                            line = self,
                            index = i,
                            name = info.name
                        } )
                    else
                        base:setVisible(true)
                    end

                end

                local roleInfo = FetterManager.getIllData(info.roleId)
                visibleMap["mMercenaryLock" .. i] =(not roleInfo.activated)
                if roleInfo then
                    visibleMap["mCoinNumNode" .. i] = not roleInfo.activated
                    lb2Str["mCoinNum" .. i] = string.format("%d/%d", roleInfo.soulCount, maxSoul)
                    color =(roleInfo.soulCount > 0 or roleInfo.activated) and GameConfig.ColorMap.COLOR_RED or GameConfig.ColorMap.COLOR_FRIEND_OTHER
                else
                    if roleData then
                        visibleMap["mCoinNumNode" .. i] = true
                        lb2Str["mCoinNum" .. i] = string.format("%d/%d", 0, maxSoul)
                    end
                end

                -- lb2Color["mCoinNum" .. i] = color
                if roleData then
                    color = ConfigManager.getQualityColor()[roleData.quality].textColor
                end
                lb2Color["mMercenaryName" .. i] = color
            end
        end
    end

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)

    NodeHelper:setColorForLabel(container, lb2Color)
end

function IllContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function IllContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }

    --local data = FetterManager.getIllMapByType(id)
    local data = nil
    if FetterPageBase.curShowType == FetterManager.CurShowType.Illustration then
        data = FetterManager.getIllMapByType_New(id)
    elseif FetterPageBase.curShowType == FetterManager.CurShowType.skin then

        data = FetterManager.getSkinMapByType(id)
    end
    
    -- -- 过滤没开启的副将
--    local t = { }
--    for k, v in pairs(data) do
--        if v.isOpen == 1 then
--            table.insert(t, v)
--        end
--    end
--    data = t
    if data then
        local lines = math.ceil(#data / mItemRowCount)
        local offsetH = 120 *(lines - 1)
        local bg1 = container:getVarScale9Sprite("mContentBg")
        bg1:setContentSize(CCSizeMake(IllContent.originW, IllContent.originH + offsetH))
        local bg2 = container:getVarScale9Sprite("mContentBg2")
        bg2:setContentSize(CCSizeMake(IllContent.originW2, IllContent.originH2 + offsetH))
        local base = container:getVarNode("mInfoBase")
        base:setPosition(ccp(0, IllContent.originY + offsetH))

        local content = container:getVarNode("mPosition")
        content:removeAllChildren()
        for i = 1, lines do
            table.insert(initLineQueue, {
                id = id,
                index = i,
                lines = lines,
                base = content,
                content = self
            } )
        end

        local activeNum = 0
        for k, v in pairs(data) do
            local roleInfo = FetterManager.getIllData(v.roleId)
            if roleInfo then
                if roleInfo.activated then
                    activeNum = activeNum + 1
                end
            end
        end
        lb2Str.mMercenaryNum = "( " .. activeNum .. "/" .. #data .. " )"
        -- lb2Str.mMercenaryNum = string.format("%d/%d",activeNum,#data)

        sprite2Img.mQuality1 = FetterManager.getRoleQualityImage(id)
        visibleMap.mQuality1 = true
        --        if id < 10 then
        --            for i = 1, 4 do
        --                visibleMap["mQuality" .. i] = i == id - 2
        --            end
        --            visibleMap.mQuality5 = false
        --        else
        --            for i = 1, 4 do
        --                visibleMap["mQuality" .. i] = false
        --            end
        --            visibleMap.mQuality5 = true
        --            local img = FetterManager.getAvatarTitle(id)
        --            if img then
        --                sprite2Img.mQuality5 = img
        --            end
        --        end
    end

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function FetterContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function FetterContent:onRefreshContent(ccbRoot)
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
            local roleData = nil
            -- TODO
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
                roleData = ConfigManager.getRoleCfg()[illInfo.roleId]
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

                -- lb2Color["mCoinNum" .. i] = color
                if roleData then
                    color = ConfigManager.getQualityColor()[roleData.quality].textColor
                end

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
            -- lb2Str.mFetterBtnTxt = common:getLanguageString("@FetterBtnActivated")
            --sprite2Img["mAwakeTitle"] = GameConfig.MercenaryAwakeImage[2]       ---已开
            lb2Str.mAwakeLabel = common:getLanguageString("@FetterActivateUsed")
            NodeHelper:setNodeIsGray(container, {mAwakeLabel = true})
            -- labelColorMap.mFetterNameTxt = GameConfig.ColorMap.COLOR_BLUE
            -- labelColorMap.mMercenaryNum = GameConfig.ColorMap.COLOR_GREEN
            -- labelColorMap.mFetterAtt = GameConfig.ColorMap.COLOR_GREEN
        else
            -- lb2Str.mFetterBtnTxt = common:getLanguageString("@FetterBtnTxt")
            --sprite2Img["mAwakeTitle"] = GameConfig.MercenaryAwakeImage[1]           ---没开
            lb2Str.mAwakeLabel = common:getLanguageString("@FetterActivateNotReady")
            NodeHelper:setNodeIsGray(container, {mAwakeLabel = true})
            -- labelColorMap.mFetterNameTxt = GameConfig.ColorMap.COLOR_WHITE
            -- labelColorMap.mMercenaryNum = GameConfig.ColorMap.COLOR_WHITE
            -- labelColorMap.mFetterAtt = GameConfig.ColorMap.COLOR_WHITE
            
        end
        NodeHelper:setMenuItemEnabled(container, "mDiaryBtn", isOpen and data.diaryNum > 0--[[false]])
        NodeHelper:setNodeIsGray(container, {mDiaryLabel = not isOpen or data.diaryNum == 0--[[true]]})

        if enable then     
            --sprite2Img["mAwakeTitle"] = GameConfig.MercenaryAwakeImage[3]       --可以开
            lb2Str.mAwakeLabel = common:getLanguageString("@FetterActivateReady")
            NodeHelper:setNodeIsGray(container, {mAwakeLabel = false})
        end
    end

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setColorForLabel(container, labelColorMap)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)

    NodeHelper:setColorForLabel(container, lb2Color)
end

function FetterContent:onOpen(container)
    local id = self.id
    if id and id > 0 then
        FetterManager.reqFetterOpen(id)
        -- FetterManager.setOpenRelation(id)
        -- PageManager.pushPage("FetterAttrPage")
    end
end

function FetterContent:onDiary(container)
    local id = self.id
    if id and id > 0 then
        local diaryPage = require("FetterGirlsDiary")
        diaryPage:setIsPhoto(container, false)
        FetterContentBase.curFetterId = id
        FetterContentBase.fetterAlbum = FetterManager.getAlbumIdByFetterId(id)
        PageManager.pushPage("FetterGirlsDiary")
    end
end

function FetterContent:onMercenary(container, index)
    local id = self.id
    local data = FetterManager.getRelationCfgById(id)
    assert(data, "invalid fetter data with id:" .. id)
    local fetterId = data.team[index]
    local item = FetterManager.getIllCfgById(fetterId)
    if item and item.roleId > 0 then
        FetterManager.setViewFetterId(item.id)
        PageManager.pushPage("FetterShowPage")
    end
end

function FetterContent:onMercenary1(container)
    self:onMercenary(container, 1)
end

function FetterContent:onMercenary2(container)
    self:onMercenary(container, 2)
end

function FetterContent:onMercenary3(container)
    self:onMercenary(container, 3)
end

function FetterContent:onMercenary4(container)
    self:onMercenary(container, 4)
end

function FetterContent:onMercenary5(container)
    self:onMercenary(container, 5)
end

function FetterPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function FetterPageBase:onEnter(container)
    FetterManager.sortIllMap_New()
    FetterManager.sortRelationCfg()
    FetterManager.sortSkinMap()
    
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);

    FetterPageBase.container = container

    NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite1"))
    NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite2"))
    NodeHelper:autoAdjustResizeScrollview(container.mScrollView);

    local playerId = FetterManager:getPlayerId()
  --if not playerId or playerId == UserInfo.playerInfo.playerId then
    if not ViewPlayerInfo.isSeeSelfInfoFlag and (not playerId or playerId == UserInfo.playerInfo.playerId) then
        FetterPageBase.curShowType = FetterManager.CurShowType.Illustration
       -- FetterManager.reqFetterInfo()
       self:refreshPage(container,true)
    else
        FetterPageBase.curShowType = -1
        self:onRole1(container)
    end
end

function FetterPageBase:onExecute(container)
    if changePageTemp and type(changePageTemp) == "function" then
        changePageTemp()
        changePageTemp = nil
    end

        if #WaitRefreshList > 0 then
        for i,v in ipairs(WaitRefreshList) do
            if v.cell:isLoaded() then
                if v:RefreshItem() then
                    table.remove(WaitRefreshList,i)
                end
                break
            end
        end
    end
--    if #initLineQueue > 0 then
--        local oneLine = table.remove(initLineQueue, 1)
--        local base = oneLine.base
--        local content = oneLine.content
--        local index = oneLine.index
--        local id = oneLine.id
--        if not lineTemp[id] then
--            lineTemp[id] = { }
--        end
--        local line = lineTemp[id][index]
--        if not line then
--            line = IllLineContent:new(oneLine.id, index, oneLine.lines)
--            line:retain()
--            lineTemp[id][index] = line
--            --line:refresh(base)
--        end
--        line:refresh(base)
--    end
--    if #initHeadQueue > 0 then
--        local oneHead = table.remove(initHeadQueue, 1)

--        local base = oneHead.base
--        local node = oneHead.node
--        local line = oneHead.line

--        CCLuaLog("FetterPage : name:" ..(oneHead.name) .. "     icon:" ..(oneHead.icon))
--        -- base:removeAllChildren()
--        if FetterPageBase.curShowType == FetterManager.CurShowType.Illustration then
--            local playerSprite = headTemp[oneHead.fetterId]
--            if not playerSprite then
--                local roleId = oneHead.roleId
--                local roleInfo = FetterManager.getIllData(roleId)
--                if roleInfo and roleInfo.activated then
--                    playerSprite = CCSprite:create(oneHead.icon)
--                    playerSprite:retain()
--                else
--                    local tempSprite = CCSprite:create(oneHead.icon)
--                    playerSprite = GraySprite:new()
--                    local texture = tempSprite:getTexture()
--                    playerSprite:initWithTexture(texture, tempSprite:getTextureRect())
--                    playerSprite:retain()
--                end
--                headTemp[oneHead.fetterId] = playerSprite
--            end
--            if playerSprite:getParent() then
--                playerSprite:removeFromParentAndCleanup(true)
--            end
--            line.initHead[oneHead.index] = 1
--            base:addChild(playerSprite)
--            node:setVisible(true)
--        end
--    end
end

function FetterPageBase:onExit(container)
    self:removePacket(container)
    initHeadQueue = { }
    -- FetterManager.clear()
--    for k, v in pairs(headTemp) do
--        v:release()
--    end
--    for k, lines in pairs(lineTemp) do
--        for _, v in pairs(lines) do
--            v:release()
--        end
--    end

    if next(spritePoolList) then
        for k, v in pairs(spritePoolList) do
            if v:getParent() then
                v:removeFromParentAndCleanup(false)
            end
            v:release()
        end
        spritePoolList = {}
    end
    headTemp = { }
    lineTemp = { }
    container.mScrollView:removeAllCell()
    -- package.loaded["FetterManager"] = nil
    onUnload(thisPageName, container)
    FetterPageBase.curShowType = -1
end

function FetterPageBase:onClose(container)
    -- PageManager.popPage(thisPageName)
    -- MainFrame_onEquipmentPageBtn()
    PageManager.changePrePage()
end

function FetterPageBase:onHelp(container)
    container.mScrollView:refreshAllCell()
end

function FetterPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
end

function FetterPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == FetterManager.moduleName then
            if extraParam == FetterManager.onFetterInfo then
                self:refreshPage(container, true)
            elseif extraParam == FetterManager.onRelationOpen then
                self:refreshPage(container, true)
                PageManager.pushPage("FetterAttrPage")
            end
        end
    end
end

function FetterPageBase:onRole1(container)
    local needRefresh = true
    if FetterPageBase.curShowType == FetterManager.CurShowType.Illustration then
        needRefresh = false
    end
    FetterPageBase.curShowType = FetterManager.CurShowType.Illustration
    self:refreshPage(container, needRefresh)
end

function FetterPageBase:onRole2(container)
    local needRefresh = true
    if FetterPageBase.curShowType == FetterManager.CurShowType.Relationship then
        needRefresh = false
    end
    FetterPageBase.curShowType = FetterManager.CurShowType.Relationship
    self:refreshPage(container, needRefresh)
end

function FetterPageBase:onRole3(container)
    local needRefresh = true
    if FetterPageBase.curShowType == FetterManager.CurShowType.skin then
        needRefresh = false
    end
    FetterPageBase.curShowType = FetterManager.CurShowType.skin
    self:refreshPage(container, needRefresh)
end

function FetterPageBase:onAtt(container)
    PageManager.pushPage("FetterAttrPage")
end

function FetterPageBase:onInfo(container)
    PageManager.pushPage("FetterRewardPage")
end

function FetterPageBase:refreshPage(container, needRefresh)
    CCLuaLog("FetterPageBase:refreshPage_______begin")
    local btn1 = container:getVarMenuItem("mRole1")
    local btn2 = container:getVarMenuItem("mRole2")
    local btn3 = container:getVarMenuItem("mRole3")
    local visibleMap = { }
    local playerId = FetterManager.getPlayerId()
    if not playerId or playerId == UserInfo.playerInfo.playerId then
        visibleMap.mRoleBtn2 = true
        visibleMap.mRoleBtn3 = true
        visibleMap.mFetterNode = false
        if FetterPageBase.curShowType == FetterManager.CurShowType.Illustration then
            btn1:selected()
            btn2:unselected()
            btn3:unselected()
            visibleMap.mFetterNode = false
        elseif FetterPageBase.curShowType == FetterManager.CurShowType.Relationship then
            btn1:unselected()
            btn2:selected()
            btn3:unselected()
            visibleMap.mFetterNode = false
        elseif FetterPageBase.curShowType == FetterManager.CurShowType.skin then
            btn1:unselected()
            btn2:unselected()
            btn3:selected()
        end
    else
        FetterPageBase.curShowType = FetterManager.CurShowType.Illustration
        btn1:selected()
        visibleMap.mRoleBtn2 = false
        visibleMap.mRoleBtn3 = false
        visibleMap.mFetterNode = false
    end
    local flag = FetterManager.checkAvailableRelations()
    NodeHelper:setNodesVisible(container, { mFetterPoint2 = flag })
--    if needRefresh then
--        changePageTemp = function()
--            initLineQueue = { }
--            initHeadQueue = { }
--            for k, lines in pairs(lineTemp) do
--                for _, v in pairs(lines) do
--                    if v.node then
--                        v.node:removeFromParentAndCleanup(true)
--                    end
--                end
--            end
--            self:clearAndReBuildAllItem(container)
--        end
--    end
    if needRefresh then
        changePageTemp = function()
            self:clearAndReBuildAllItem(container)
        end
    end

    NodeHelper:setNodesVisible(container, visibleMap)
    CCLuaLog("FetterPageBase:refreshPage_______end")
end

function FetterPageBase:clearAndReBuildAllItem(container)
    CCLuaLog("FetterPageBase:clearAndReBuildAllItem_______begin")
    FetterPageBase.container.mScrollView:removeAllCell()
    --container.mScrollView:removeAllCell()
    WaitRefreshList = {}
    if FetterPageBase.curShowType == FetterManager.CurShowType.Illustration then
        --local illMap = FetterManager.getIllMap()
        local illMap = FetterManager.getIllMap_New()
        local groupIndex = 0  --从下往上数的组的索引
        local offsetY = 15     --从下往上当前的偏移 偏移15像素

        --for i, v in ipairs(illMap) do
        for i = #illMap, 1, -1 do
            groupIndex = groupIndex + 1
            local v = illMap[i]
            local titleCell = CCBFileCell:create()
            local panel = IllContent:new( { id = v._type, index = i, cell = titleCell })
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(IllContent.ccbiFile)
            local size = titleCell:getContentSize()
            local lines = math.ceil(#v.map / mItemRowCount)
            local height = size.height +(lines - 1) * 120
            titleCell:setContentSize(CCSizeMake(size.width, height))
            container.mScrollView:addCellBack(titleCell)

            titleCell:setPosition(ccp(0,offsetY - 15))
            for j = 1, #v.map, 1 do
                local cell = CCBFileCell:create()
                cell:setCCBFile(IllItemContent.ccbiFile)
                local panel = common:new({data = v.map[j],index = j,mShowItem = false},IllItemContent)
                cell:registerFunctionHandler(panel)
                container.mScrollView:addCell(cell)
                local posx = 7 + ((j-1) % mItemRowCount) * 124 --偏移7像素，宽94像素
                local lineIndex = math.ceil( (lines * mItemRowCount - j + 1) / mItemRowCount) -- --从下往上数改物品在当前分组的行数ǰ���������
                local posy = offsetY + (lineIndex - 1) * 120 -- -- 高120像素, 每组增高85像素

                -- CCLuaLog("_________"..lineIndex.."posx"..posx)
                cell:setPosition(ccp(posx,posy))
                panel.cell = cell
                table.insert(WaitRefreshList,j,panel)
            end

            --             for h = 1, lines do
            --                if not lineTemp[v._type] then
            --                    lineTemp[v._type] = { }
            --                end
            --                local line = lineTemp[v._type][h]
            --                if not line then
            --                    line = IllLineContent:new(v._type, h, lines)
            --                    line:retain()
            --                    line:refresh(base)
            --                    --for h = 1, lines do
            --                     lineTemp[v._type][h] = line
            --                   -- end
            --                end
            --            end

            -- if #initLineQueue > 0 then
            --               for j = 1, #v.map, 1 do

            --                                    local oneLine = initLineQueue[j]--table.remove(initLineQueue, 1)
            --                                    local base = oneLine.base
            --                                    local content = oneLine.content
            --                                    local index = oneLine.index
            --                                    local id = oneLine.id
            --                                    if not lineTemp[id] then
            --                                        lineTemp[id] = { }
            --                                    end
            --                                    local line = lineTemp[id][index]
            --                                    if not line then
            --                                        line = IllLineContent:new(oneLine.id, index, oneLine.lines)
            --                                        line:retain()
            --                                        lineTemp[id][index] = line
            --                                    end
            --                                    line:refresh(base)
            --                  end



            --end
            offsetY = offsetY + 85 + lines * 120
        end
        --container.mScrollView:orderCCBFileCells()
        local viewSize = container.mScrollView:getViewSize()
        local size = CCSizeMake(viewSize.width,offsetY - 15)
        container.mScrollView:setContentSize(size)
        container.mScrollView:setContentOffset(ccp(0,viewSize.height-size.height));
        container.mScrollView:forceRecaculateChildren()
    elseif FetterPageBase.curShowType == FetterManager.CurShowType.skin then
        local skinMap = FetterManager.getSkinMap()
        local groupIndex = 0  --�������������������
        local offsetY = 15     --�������ϵ�ǰ��ƫ�� ƫ��15����
        for i = #skinMap, 1, -1 do
            groupIndex = groupIndex + 1
            local v = skinMap[i]
            local titleCell = CCBFileCell:create()
            local panel = IllContent:new( { id = v._type, index = i, cell = titleCell })
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(IllContent.ccbiFile)
            local size = titleCell:getContentSize()
            local lines = math.ceil(#v.map / mItemRowCount)
            local height = size.height +(lines - 1) * 120
            titleCell:setContentSize(CCSizeMake(size.width, height))
            container.mScrollView:addCellBack(titleCell)

            titleCell:setPosition(ccp(0,offsetY - 15))
            for j = 1, #v.map, 1 do
                local cell = CCBFileCell:create()
                cell:setCCBFile(IllItemContent.ccbiFile)
                local panel = common:new({data = v.map[j],index = j,mShowItem = false},IllItemContent)
                cell:registerFunctionHandler(panel)
                container.mScrollView:addCell(cell)
                local posx = 7 + ((j-1) % mItemRowCount) * 124 --ƫ��7���أ���94����
                local lineIndex = math.ceil( (lines * mItemRowCount - j + 1) / mItemRowCount) --��������������Ʒ�ڵ�ǰ���������
                local posy = offsetY + (lineIndex - 1) * 120 -- ��120����, ÿ������85����
                cell:setPosition(ccp(posx,posy))
                panel.cell = cell
                table.insert(WaitRefreshList,j,panel)
            end

            offsetY = offsetY + 85 + lines * 120
        end
        --container.mScrollView:orderCCBFileCells()
        local viewSize = container.mScrollView:getViewSize()
        local size = CCSizeMake(viewSize.width,offsetY - 15)
        container.mScrollView:setContentSize(size)
        container.mScrollView:setContentOffset(ccp(0,viewSize.height-size.height));
        container.mScrollView:forceRecaculateChildren()
    elseif FetterPageBase.curShowType == FetterManager.CurShowType.Relationship then
        local relationCfg = FetterManager.getRelationCfg()

    -- sortRelationCfg




    for i, v in ipairs(relationCfg) do
    local titleCell = CCBFileCell:create()
    local panel = FetterContent:new( { id = v.id, index = i })
    titleCell:registerFunctionHandler(panel)
    titleCell:setCCBFile(FetterContent.ccbiFile)
    container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
    end
    container.mScrollView:registerScriptHandler(self, 0)
    container.mScrollView:registerScriptHandler(self, 2)

        CCLuaLog("FetterPageBase:clearAndReBuildAllItem_______end")
end

function FetterPageBase:scrollViewDidDeaccelerateStop(scrollView)
    -- scrollView:refreshAllCell()
end

function FetterPageBase:scrollViewDidScroll(scrollView)
    --print()
end

function FetterPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function FetterPageBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function FetterPageBase:getFetterId()
    return FetterContentBase.curFetterId
end

function FetterPageBase:getUnlockState()
    return FetterManager.getAlbumIdByFetterId(FetterContentBase.curFetterId)
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local FetterPage = CommonPage.newSub(FetterPageBase, thisPageName, option);

return FetterPageBase