local thisPageName = "FetterShowPage"
local FetterManager = require("FetterManager")
local UserInfo = require("PlayerInfo.UserInfo")
local UserMercenaryManager = require("UserMercenaryManager")
local MercenaryTouchSoundManager = require("MercenaryTouchSoundManager")
local RelationshipManager = require("RelationshipManager")
local FormationManager = require("FormationManager")
local FetterShowPageBase = {
}

local option = {
    ccbiFile = "FetterShowPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onSkill = "onSkill",
        onHide = "onHide",
        onGrow = "onGrow",
        onWeapon = "onWeapon",
        onAtt = "onGroup",
        onReturn = "onReturn",
        onSpineClick = "onSpineClick",
        onRelationship = "onRelationship",
        onAlbum = "onAlbum",
        onTouchPhoto1 = "onTouchPhoto1",
        onTouchPhoto2 = "onTouchPhoto2",
        onTouchPhoto3 = "onTouchPhoto3",
        onTouchPhoto4 = "onTouchPhoto4",
        onTouchSoft = "onTouchSoft",
        onTouchHard = "onTouchHard",
        onTouchRapid = "onTouchRapid",
        onDominance = "onDominance",
        onTouchArrow = "onTouchArrow",

        onDressOn = "onSetNude",
        onDressOff = "onSetNude",
    },
    opcodes =
    {
    }
}
local mIsHide = false
local mIsAlbum = false
local mIsDominance = false
local roleStageLevel = -1
local roleRareLevel
local HpMap
local touchType = 0
local timeCount = 0
local dominanceRoleID
local albumCfg
local bdsmCfg
local selectPhoto = 0
local effState = 0
local isOpenAlbum = false
local graySprite = nil
local roleSpine = { spine = nil, hSpine = nil }
local isDominanceEnd = false
local graySpriteTag = 650058
local tempContainer = nil
local hSpineBg = nil
local isShowingWindow = true

local aniName = {   --H1(色情圖編號)01(動作編號)01(有無汗水；除高潮外，1=無汗)
    "Stand", "Stop", "Stand_H", "Stop_H",   --相簿1: Stand 相簿2:Stand_H 未解鎖:Stop
    "Stand_H101", "Stand_H102",   --相簿3: StandH101 相簿3調教完畢:Stand_H102(UR+)
    "Stand_H201", "Stand_H202",   --相簿4: StandH201 相簿4調教完畢:Stand_H202(SSR+)
    [301] = "H10101", [302] = "H10201", [303] = "H10301",
    [304] = "H10102", [305] = "H10202", [306] = "H10302", [307] = "H10401",   --相簿3調教動畫
    [401] = "H20101", [402] = "H20201", [403] = "H20301",
    [404] = "H20102", [405] = "H20202", [406] = "H20302", [407] = "H20401",   --相簿4調教動畫
}

local FetterShowContent = {
    ccbiFile = "FetterShowContent.ccbi",
}

local initHeadQueue = { }

local photoVarList = { "mPhoto1", "mPhoto2", "mPhoto3", "mPhoto4" }

local isHSpineId = { 111, 112, 113, 162 }

function FetterShowContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function FetterShowContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }

    local data = FetterManager.getRelationCfgById(id)
    if data then
        lb2Str.mFetterNameTxt = data.name
        lb2Str.mFetterAtt = data.property

        local activeNum = 0
        for i = 1, 5 do
            local fetterId = data.team[i]
            local base = container:getVarNode(string.format("mMailPrizeNode%d", i))
            base:setVisible(false)
            if fetterId then
                local illInfo = FetterManager.getIllCfgById(fetterId)
                lb2Str["mMercenaryName" .. i] = illInfo.name
                local quality = illInfo._type % 10
                sprite2Img["mProtraitColour" .. i] = GameConfig.MercenaryQualityImage[quality]
                local curSoul = 0
                local maxSoul = illInfo.soulNumber
                local roleData = ConfigManager.getRoleCfg()[illInfo.roleId]
                if roleData == nil then
                    base:setVisible(false)
                end
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
            end
        end
        lb2Str.mMercenaryNum = string.format("%d/%d", activeNum, #data.team)
    end

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function FetterShowPageBase:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "Show" then
        -- container:runAnimation("Default Timeline")
        self:refreshPage(container)
    end
end

function FetterShowPageBase:refreshPage(container, initSpine)

    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)
    dominanceRoleID = data.roleId
    local suitInfo = EquipManager:getMercenaryOnlySuitByMercenaryId(data.roleId)
    if suitInfo == nil then
        NodeHelper:setNodesVisible(container, { mWeaponBtnNode = false })
    else
        NodeHelper:setNodesVisible(container, { mWeaponBtnNode = true })
    end


       NodeHelper:setNodesVisible(container, { mRelationshipNode = RelationshipManager:getRelationshipDataByRoleId(data.roleId) ~= nil })
  

    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        --NodeHelper:setNodesVisible(container, { mRelationshipNode = RelationshipManager:getRelationshipDataByRoleId(data.roleId) ~= nil })
    else
       -- NodeHelper:setNodesVisible(container, { mRelationshipNode = false })
    end


    local list = FetterManager.getAllRelationByFetterId(fetterId)
    if #list > 0 then
        NodeHelper:setNodesVisible(container, { mFetterBtnNode = true })
    else
        NodeHelper:setNodesVisible(container, { mFetterBtnNode = false })
    end

    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)



    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }



    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)
    if data and ConfigManager.getRoleCfg()[data.roleId] then
        local roleData = ConfigManager.getRoleCfg()[data.roleId]
        NodeHelper:setStringForLabel(container, { mAwakeLimit = roleData.maxRank })
        local avatarName = data.name
        if data._type > 10 then
            avatarName = roleData.avatarName
        end
        lb2Str.mBackDropTxt = data.story
        -- common:stringAutoReturn(data.story, 30 ,"\n")
        lb2Str.mMercenaryName = avatarName
        for i = 1, 4 do
            visibleMap["mQuality" .. i] = i ==(data._type % 10) -2
        end
        if roleData then
            lb2Str.mMercenaryProfess = string.format("(%s)", common:getLanguageString("@ProfessionName_" .. roleData.profession))
        end

        if initSpine then
            self:showRoleSpine(container, data.roleId)
        end

        local roleInfo = FetterManager.getIllData(data.roleId)
        -- visibleMap.mHideBtnNode = (roleInfo ~= nil and roleInfo.activated == true)
        visibleMap.mFashionState =(data._type > 10 and(not roleInfo or roleInfo.activated == false))
    end

    local _curMercenaryInfo = UserMercenaryManager:getUserMercenaryByItemId(data.roleId)

    if _curMercenaryInfo then
        if (_curMercenaryInfo.stageLevel == 2 ) then
            local GuideManager = require("Guide.GuideManager")
            GuideManager.PageContainerRef["FetterShowPageBase"] = container
            if GuideManager.IsNeedShowPage and GuideManager.getCurrentStep() == 177 then
                GuideManager.IsNeedShowPage = false
                PageManager.popPage("NewGuideEmptyPage")
                PageManager.pushPage("NewbieGuideForcedPage")
            end
        end
        roleStageLevel = _curMercenaryInfo.stageLevel
    end

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function FetterShowPageBase:showRoleSpine(container, roleId)
    local roleInfo = FetterManager.getIllData(roleId)
    local heroNode = container:getVarNode("mSpineNode")
    local heroNodeBack = container:getVarNode("mSpineBGNode")
    local effNode = container:getVarNode("mEff")
    if heroNode then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width, height = visibleSize.width, visibleSize.height
        local rate = visibleSize.height / visibleSize.width
        local desighRate = GameConfig.ScreenSize.height / GameConfig.ScreenSize.width
        rate = rate / desighRate

        -- modify
        local roleData = ConfigManager.getRoleCfg()[roleId]
        local spinePath, spineName, animCCbi = unpack(common:split((roleData.spine), ","))
        local graySpine = SpineContainer:create(spinePath, spineName)
        roleSpine.spine = SpineContainer:create(spinePath, spineName)

        local isHSpine = false  -- 角色spine更新完後拿掉
        roleSpine.hSpine = nil
        hSpineBg = nil
        --for i = 1, #isHSpineId do
        --    if roleId == isHSpineId[i] then
            local fileName = ""
            local isFileExist = false
            local writablePath = CCFileUtils:sharedFileUtils():getWritablePath()
            if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
                fileName = writablePath .. "/" .. spinePath .. "/" .. spineName .. "_H.json"
                isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(fileName)
            else
                fileName = writablePath .. "/assets/".. spinePath .. "/" .. spineName .. "_H.json"
                fileName2 = writablePath .. "/hotUpdate/".. spinePath .. "/" .. spineName .. "_H.json"
                isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(fileName) or CCFileUtils:sharedFileUtils():isFileExist(fileName2)
            end
            if isFileExist then
                --roleSpine.hSpine = SpineContainer:create(spinePath, spineName .. "_H")
                --isHSpine = true
            end
        --    end
        --end
        if not isHSpine then
            roleSpine.hSpine = SpineContainer:create(spinePath, spineName)
        else
            hSpineBg = CCSprite:create(roleData.hcgImg)
            hSpineBg:setPositionY(hSpineBg:getPositionY())
            hSpineBg:setScale(NodeHelper:getScaleProportion())
        end
        -- the end
        local spineNode = tolua.cast(roleSpine.spine, "CCNode")
        local hSpineNode = nil
        if roleSpine.hSpine then
            hSpineNode = tolua.cast(roleSpine.hSpine, "CCNode")
            --NodeHelper:autoAdjustResetNodePosition(hSpineNode, 1)
        end


        local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
        NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        -- spineNode:setScale(roleData.spineScale * GameConfig.ShowSpineRate.small)
        spineNode:setScale(roleData.spineScale)

        -- 	local avatarScale = GameConfig.AvatarSpineScale[roleId]
        --        if avatarScale then
        --            local scaleX = rate * avatarScale[1]
        --            local scaleY = rate * avatarScale[2]
        -- 	    heroNode:setScaleX(scaleX)
        --            heroNode:setScaleY(scaleY)
        --        else
        --            heroNode:setScale(rate)
        --        end
        heroNode:removeAllChildren()
        graySprite = nil
        if not roleInfo or not roleInfo.activated then
            NodeHelper:initGraySpineSpriteVisible(heroNodeBack, graySpine, heroNode, roleData, graySprite, true, graySpriteTag)
            spineNode:setVisible(false)
            heroNode:addChild(spineNode)
            if hSpineNode then
                if hSpineBg then
                    hSpineBg:setVisible(false)
                    heroNode:addChild(hSpineBg)
                end
                hSpineNode:setVisible(false)
                heroNode:addChild(hSpineNode)
            end
        else
            NodeHelper:initGraySpineSpriteVisible(heroNodeBack, graySpine, heroNode, roleData, graySprite, false, graySpriteTag)
            spineNode:setVisible(true)
            -- modify
            if animCCbi ~= nil then
                local eft = ScriptContentBase:create(animCCbi, 0);
                effNode:addChild(eft);
                eft:release();
                -- eft:setPosition(ccp(-640/2, -960/2))
                heroNode = eft:getVarNode("mSpine");


                local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
                NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
                spineNode:setScale(roleData.spineScale)

                -- scale
                --                if avatarScale then
                --                    local scaleX = rate * avatarScale[1]
                --                    local scaleY = rate * avatarScale[2]
                -- 	            heroNode:setScaleX(scaleX)
                --                    heroNode:setScaleY(scaleY)
                --                else
                --                    heroNode:setScale(rate)
                --                end

            end
            -- the end
            heroNode:addChild(spineNode)
            if hSpineNode then
                 if hSpineBg then
                    hSpineBg:setVisible(false)
                    heroNode:addChild(hSpineBg)
                end
                hSpineNode:setVisible(false)
                heroNode:addChild(hSpineNode)
            end
            local animationName = "Stand"
            if UserMercenaryManager:CanBeNude(roleId) then
                local isnudeKey = "Nuded_" .. UserInfo.serverId .."_".. UserInfo.playerInfo.playerId
                local isNude = CCUserDefault:sharedUserDefault():getBoolForKey(isnudeKey)
                if isNude == true then
                    animationName = "Stand_H"
                end 
            end 
            if GameConfig.MercenarySpineSpecialAction[roleId] then
                animationName = GameConfig.MercenarySpineSpecialAction[roleId]
            end
            roleSpine.spine:runAnimation(1, animationName, -1)
            -- MercenaryTouchSoundManager:initTouchButton(container, roleId)
        end
        local roleCfg = ConfigManager.getRoleCfg()
        local bgImg = roleCfg[roleId].bgImg
        local bgScale = NodeHelper:getAdjustBgScale(1)
        if bgScale < 1 then bgScale = 1 end
        NodeHelper:setSpriteImage(container, { mMercenaryBG = bgImg }, { mMercenaryBG = bgScale })
        local deviceHeight = CCDirector:sharedDirector():getWinSize().height
        if deviceHeight < 900 then
            -- ipad change spine position
            -- NodeHelper:autoAdjustResetNodePosition(spineNode, -0.3)
        end
    end
end

function FetterShowPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
    tempContainer = container
end

function FetterShowPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    self:clearAndReBuildAllItem(container)
    self:showAlbumMode(container, false)
    self:refreshPage(container, true)
    if isOpenAlbum then
        self:onAlbum(container)
    end
    self:createTouchLayer(container)
    self:playWindowArrow(container)
    self:ReSetSexyModeBtn(container)
end

function FetterShowPageBase:onExecute(container)
    if #initHeadQueue > 0 then
        local oneHead = table.remove(initHeadQueue, 1)
        local base = oneHead.base
        base:removeAllChildren()

        local node = oneHead.node
        local relationId = oneHead.relationId
        if relationId then
            local data = FetterManager.getRelationCfg(relationId)
            if data.team[oneHead.index] then
                local playerSprite = CCSprite:create(oneHead.icon)
                base:addChild(playerSprite)
                NodeHelper:setNodeVisible(node, true)
                -- node:setVisible(true)
            end
        end
    end
    -- 調教進度自動增減
    if mIsDominance then
        self:calculateBossHp(container)
        self:setDominanceAni(container)
    end
end

function FetterShowPageBase:onExit(container)
    self:removePacket(container)
    initHeadQueue = { }

    local heroNode = container:getVarNode("mSpineNode")
    if heroNode then
        heroNode:removeAllChildren()
    end
    PageManager.refreshPage("EquipMercenaryPage", "initTouchButton")
    onUnload(thisPageName, container)
end

function FetterShowPageBase:onClose(container)
    GameUtil:purgeCachedData()
    PageManager.popPage(thisPageName)
    isOpenAlbum = false
end

function FetterShowPageBase:onHide(container)
    if not mIsHide then
        mIsHide = true
        NodeHelper:setNodesVisible(container, { mBtnNode = false, mBtmNode = false, mBtmAlbum = false, mTouchLayer = true, mCloseNode = false, mReturnNode = false })
        -- container:runAnimation("Hide")
        self:refreshPage(container)
        --local RNode = container:getVarNode("mReturnNode")
        --RNode:setVisible(true)
    end
end

function FetterShowPageBase:onReturn(container)
    -- container:runAnimation("Show")

    if mIsDominance then    --調教介面 -> 相簿介面
        SoundManager:getInstance():playGeneralMusic()  --回復BGM
        SoundManager:getInstance():stopAllEffect() --關閉調教音效
        self:showDominanceMode(container, false)  
        self:clearDominanceData(container)  
        mIsDominance = false
        effState = 0
    elseif mIsAlbum then
        if mIsHide then --相機介面 -> 相簿介面
            mIsHide = false
            self:setAllBtnVistible(container, false)
            NodeHelper:setNodesVisible(container, { mBtnNode = true, mBtmAlbum = true })
        else
            self:setVisibleSpine(false)
            if not roleSpine.spine:isPlayingAnimation(aniName[1], 1) then
                roleSpine.spine:runAnimation(1, aniName[1], -1)
            end
            mIsAlbum = false    --相簿介面 -> 一般介面
            selectPhoto = 0
            if graySprite and roleStageLevel > 0 then
                graySprite:setVisible(false)
            end
            self:refreshPage(container)
            self:showAlbumMode(container, false)
            local RNode = container:getVarNode("mReturnNode")
            RNode:setVisible(false)
        end
    else    --相機介面 -> 一般介面
        self:setVisibleSpine(false)
        local animationName = "Stand"
        local fetterId = FetterManager.getViewFetterId()
        local data = FetterManager.getIllCfgById(fetterId)
        
        if UserMercenaryManager:CanBeNude(data.roleId) then
            local isnudeKey = "Nuded_" .. UserInfo.serverId .."_".. UserInfo.playerInfo.playerId
            local isNude = CCUserDefault:sharedUserDefault():getBoolForKey(isnudeKey)
            if isNude == true then
                animationName = "Stand_H"
            end 
        end
        if not roleSpine.spine:isPlayingAnimation(animationName, 1) then
            roleSpine.spine:runAnimation(1, animationName, -1)
        end
        mIsHide = false
        NodeHelper:setNodesVisible(container, { mBtnNode = true, mBtmNode = true })
        self:refreshPage(container)
        local RNode = container:getVarNode("mReturnNode")
        RNode:setVisible(false)
    end
end

function FetterShowPageBase:onSpineClick(container)
    --    local fetterId = FetterManager.getViewFetterId()
    --    local data = FetterManager.getIllCfgById(fetterId)
    --    local roleData = ConfigManager.getRoleCfg()[(data.roleId)]

    --    local gatherNode = container:getVarNode("mGatherNode")
    --    local roleInfo = FetterManager.getIllData(data.roleId)
    --    if roleInfo == nil or roleInfo.activated == true then
    --        return
    --    end

    --    local CNode = container:getVarNode("mCloseNode")
    --    CNode:setVisible(true)
    --    gatherNode:setVisible(true)
    --    local lb2Str = {mGatherTalk = roleData.gatherMeg}
    --    NodeHelper:setStringForLabel(container,lb2Str)
    --    container:runAnimation("GatherTips")
    --    mIsHide = false
end
function FetterShowPageBase:onGrow(container)


    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)
    local MercenarySpecialAwakeInfoShowPage = require("Mercenary.MercenarySpecialAwakeInfoShowPage")
    MercenarySpecialAwakeInfoShowPage_setRoleId(data.roleId)
    PageManager.pushPage("MercenarySpecialAwakeInfoShowPage");

end


function FetterShowPageBase:onRelationship(container)
    local RelationshipPopUp = require("RelationshipPopUp")
    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)
    RelationshipPopUpBase_setRoleId(data.roleId , FormationManager:getMainFormationInfo().roleNumberList)
    PageManager.pushPage("RelationshipPopUp")
end

function FetterShowPageBase:onWeapon(container)
    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)
    local suitInfo = EquipManager:getMercenaryOnlySuitByMercenaryId(data.roleId)
    if suitInfo == nil then
        -- 这个角色没有专属武器
        return
    end

    local MercenarySpecialEquipPage = require("MercenarySpecialEquipPage")
    PageManager.pushPage("MercenarySpecialEquipPage")
end

function FetterShowPageBase:onGroup(container)

    local MercenarySpecialGroupPage = require("Mercenary.MercenarySpecialGroupPage")
    PageManager.pushPage("MercenarySpecialGroupPage");

end
function FetterShowPageBase:onSkill(container)
    local roleId = FetterManager.getRoleIdByFetterId(FetterManager.getViewFetterId())
    local MercenarySkillPreviewPage = require("MercenarySkillPreviewPage")
    local _curMercenaryInfo = nil
    local playerId = FetterManager.getPlayerId()
    if not playerId or playerId == UserInfo.playerInfo.playerId then
        if roleId > 0 then
            _curMercenaryInfo = UserMercenaryManager:getUserMercenaryByItemId(roleId)
        end
    else
        if roleId > 0 then
            _curMercenaryInfo = FetterManager.getCurOtherRoleByRoleId(roleId)
        end
    end
    if roleId > 0 and not _curMercenaryInfo then
        _curMercenaryInfo = {
            itemId = roleId,
            skills = { },
            ringId = { }
        }
    end
    if _curMercenaryInfo then
        MercenarySkillPreviewPage:setMercenaryInfo(_curMercenaryInfo);
        PageManager.pushPage("MercenarySkillPreviewPage");
    end
end

function FetterShowPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
end

function FetterShowPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam


    end
end

-- TODO Album touch events
function FetterShowPageBase:setOpenAlbum(container)
    isOpenAlbum = true
end

function FetterShowPageBase:onAlbum(container)
    --if NodeHelper:isDebug() then    --角色劇情演出完成後開放
        PageManager.pushPage("PhotoBDSMPopup")
    --else
    --    mIsAlbum = true
    --    self:refreshPage(container)
    --    self:showAlbumMode(container, true)
    --    NodeHelper:setNodesVisible(container, { mBtmNode = false })
    --    local RNode = container:getVarNode("mReturnNode")
    --    RNode:setVisible(true)
    --    self:initAlbumImgState(container)
    --end
end
function FetterShowPageBase:onTouchPhoto1(container)
    selectPhoto = 1
    self:setVisibleSpine(false)
    local trueSpine = roleSpine.spine
    local spineNode = tolua.cast(trueSpine, "CCNode")
    if graySprite then
        graySprite:setVisible(false)
    else
        local heroNode = container:getVarNode("mSpineNode")
        graySprite = heroNode:getChildByTag(graySpriteTag)
        if graySprite then
            graySprite:setVisible(false)
        end
    end
    if roleStageLevel > 0 then
        NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = false })
        if not trueSpine:isPlayingAnimation(aniName[1], 1) then
            trueSpine:runAnimation(1, aniName[1], -1)
        end
        spineNode:setVisible(true)
    else
        NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = true })
        NodeHelper:setStringForLabel(container, { mUnlockStr = common:getLanguageString("@Photounlock_0") })
        if graySprite then
            graySprite:setVisible(true)
        end
        spineNode:setVisible(false)
    end
end
function FetterShowPageBase:onTouchPhoto2(container)
    local archiveCfg = ConfigManager:getIllustrationCfg()
    local mercenaryInfo = UserMercenaryManager:getUserMercenaryByItemId(dominanceRoleID)
    local roleStageLevel2 = mercenaryInfo.stageLevel2
    local isSkin = archiveCfg[FetterManager.getFetterIdByRoleId(dominanceRoleID)].isSkin
    selectPhoto = 2
    self:setVisibleSpine(false)
    local trueSpine = roleSpine.spine
    local spineNode = tolua.cast(trueSpine, "CCNode")
    if graySprite then
        graySprite:setVisible(false)
    else
        local heroNode = container:getVarNode("mSpineNode")
        graySprite = heroNode:getChildByTag(graySpriteTag)
        if graySprite then
            graySprite:setVisible(false)
        end
    end
    if not trueSpine:isPlayingAnimation(aniName[3], 1) then
        trueSpine:runAnimation(1, aniName[3], -1)
    end
    if isSkin == 1 then
        if roleStageLevel2 > 0 then
            NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = false })
            spineNode:setVisible(true)
        else
            NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = true })
            NodeHelper:setStringForLabel(container, { mUnlockStr = common:getLanguageString("@OnDress") })
            if graySprite then
                graySprite:setVisible(true)
            end
            spineNode:setVisible(false)
        end
    else
        if roleStageLevel > 1 and roleRareLevel > 4 then
            NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = false })
            spineNode:setVisible(true)
        elseif roleStageLevel > 1 and roleRareLevel <= 4 then
            NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = false })
            spineNode:setVisible(true)
        else
            NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = true })
            NodeHelper:setStringForLabel(container, { mUnlockStr = common:getLanguageString("@Photounlock_1") })
            if graySprite then
                graySprite:setVisible(true)
            end
            spineNode:setVisible(false)
        end
    end
end
function FetterShowPageBase:onTouchPhoto3(container)
    selectPhoto = 3
    self:setVisibleSpine(true)
    local trueSpine = roleSpine.hSpine
    local cfgId = dominanceRoleID * 100 + selectPhoto
    local spineNode = tolua.cast(trueSpine, "CCNode")
    if graySprite then
        graySprite:setVisible(false)
    else
        local heroNode = container:getVarNode("mSpineNode")
        graySprite = heroNode:getChildByTag(graySpriteTag)
        if graySprite then
            graySprite:setVisible(false)
        end
    end
    if not CCUserDefault:sharedUserDefault():getBoolForKey("RoleDominance" .. cfgId) then -- 未調教完成
        if not trueSpine:isPlayingAnimation(aniName[5], 1) then
            trueSpine:runAnimation(1, aniName[5], -1)
        end
    else -- 已調教完成
        if not trueSpine:isPlayingAnimation(aniName[6], 1) then
            trueSpine:runAnimation(1, aniName[6], -1)
        end
    end
    
    if roleStageLevel > 2 and roleRareLevel > 4 then    --ssr以上才有調教按鈕 
        if dominanceRoleID == 124 or dominanceRoleID == 137 then --#特定SSR還沒補完調教
            NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = false })
            spineNode:setVisible(true)
        else
            self:setSituationWindow(container)
            NodeHelper:setNodesVisible(container, { mDominance = true, mWindow = true, mUnlock = false })
            spineNode:setVisible(true)
            if isShowingWindow then
                self:playWindowArrow(container)
            else
                self:playShowWindow(container, true)
            end
        end
    elseif roleStageLevel > 2 and roleRareLevel <= 4 then
        NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = false })
        spineNode:setVisible(true)
    else
        NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = true })
        NodeHelper:setStringForLabel(container, { mUnlockStr = common:getLanguageString("@Photounlock_2") })
        if graySprite then
            graySprite:setVisible(true)
        end
        if hSpineBg then
            hSpineBg:setVisible(false)
        end
        spineNode:setVisible(false)
    end
end
function FetterShowPageBase:onTouchPhoto4(container)
    selectPhoto = 4
    self:setVisibleSpine(true)
    local trueSpine = roleSpine.hSpine
    local cfgId = dominanceRoleID * 100 + selectPhoto
    local spineNode = tolua.cast(trueSpine, "CCNode")
    if graySprite then
        graySprite:setVisible(false)
    else
        local heroNode = container:getVarNode("mSpineNode")
        graySprite = heroNode:getChildByTag(graySpriteTag)
        if graySprite then
            graySprite:setVisible(false)
        end
    end
    if not CCUserDefault:sharedUserDefault():getBoolForKey("RoleDominance" .. cfgId) then -- 未調教完成
        if not trueSpine:isPlayingAnimation(aniName[7], 1) then
            trueSpine:runAnimation(1, aniName[7], -1)
        end
    else -- 已調教完成
        if not trueSpine:isPlayingAnimation(aniName[8], 1) then
            trueSpine:runAnimation(1, aniName[8], -1)
        end
    end

    if roleStageLevel > 3 and roleRareLevel > 4 then
        self:setSituationWindow(container)
        NodeHelper:setNodesVisible(container, { mDominance = true, mWindow = true, mUnlock = false })
        spineNode:setVisible(true)
        if isShowingWindow then
            self:playWindowArrow(container)
        else
            self:playShowWindow(container, true)
        end
    elseif roleStageLevel > 3 and roleRareLevel <= 4 then
        NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = false })
        spineNode:setVisible(true)
    else
        NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = true })
        NodeHelper:setStringForLabel(container, { mUnlockStr = common:getLanguageString("@Photounlock_3") })
        if graySprite then
            graySprite:setVisible(true)
        end
        if hSpineBg then
            hSpineBg:setVisible(false)
        end
        spineNode:setVisible(false)
    end
end
function FetterShowPageBase:onTouchSoft(container)
    touchType = 1
    self:setDominanceBtnState(container, touchType)
end
function FetterShowPageBase:onTouchHard(container)
    touchType = 2
    self:setDominanceBtnState(container, touchType)
end
function FetterShowPageBase:onTouchRapid(container)
    touchType = 3
    self:setDominanceBtnState(container, touchType)
end
function FetterShowPageBase:calculateBossHp(container)
    if touchType == 0 or math.floor(HpMap:getScaleY() * 100 + 0.5) == 100 then
        timeCount = 0
        return
    end
    timeCount = timeCount + GamePrecedure:getInstance():getFrameTime() * 1000
    if timeCount < 1000 then
        return
    end
    timeCount = timeCount - 1000
    local addNum = 0
    local hpPer = math.modf(math.floor(HpMap:getScaleY() * 100 + 0.5))
    local cfgId = dominanceRoleID * 100 + selectPhoto
    if bdsmCfg[cfgId] then
        if bdsmCfg[cfgId].Q1 <= hpPer and bdsmCfg[cfgId].Q2 > hpPer then
            if effState ~= 1 then
                effState = 1
                SoundManager:getInstance():stopAllEffect()
                SoundManager:getInstance():playEffectByName(bdsmCfg[cfgId].Audio1, true)
            end
            if touchType == 1 then
                addNum = bdsmCfg[cfgId].Soft1
            elseif touchType == 2 then
                addNum = bdsmCfg[cfgId].Hard1
            elseif touchType == 3 then
                addNum = bdsmCfg[cfgId].Rapid1
            end
            if math.modf(math.floor(HpMap:getScaleY() * 100 + 0.5)) + addNum < bdsmCfg[cfgId].Q1 then    --不會倒退回前一階段
                addNum = 0
            end
        elseif bdsmCfg[cfgId].Q2 <= hpPer and bdsmCfg[cfgId].Q3 > hpPer then
            if effState ~= 2 then
                effState = 2
                SoundManager:getInstance():stopAllEffect()
                SoundManager:getInstance():playEffectByName(bdsmCfg[cfgId].Audio2, true)
            end
            if touchType == 1 then
                addNum = bdsmCfg[cfgId].Soft2
            elseif touchType == 2 then
                addNum = bdsmCfg[cfgId].Hard2
            elseif touchType == 3 then
                addNum = bdsmCfg[cfgId].Rapid2
            end
            if math.modf(math.floor(HpMap:getScaleY() * 100 + 0.5)) + addNum < bdsmCfg[cfgId].Q2 then    --不會倒退回前一階段
                addNum = 0
            end
        elseif bdsmCfg[cfgId].Q3 <= hpPer and bdsmCfg[cfgId].Q4 > hpPer then
            if effState ~= 3 then
                effState = 3
                SoundManager:getInstance():stopAllEffect()
                SoundManager:getInstance():playEffectByName(bdsmCfg[cfgId].Audio3, true)
            end
            if touchType == 1 then
                addNum = bdsmCfg[cfgId].Soft3
            elseif touchType == 2 then
                addNum = bdsmCfg[cfgId].Hard3
            elseif touchType == 3 then
                addNum = bdsmCfg[cfgId].Rapid3
            end
            if math.modf(math.floor(HpMap:getScaleY() * 100 + 0.5)) + addNum < bdsmCfg[cfgId].Q3 then    --不會倒退回前一階段
                addNum = 0
            end
        else
            if effState ~= 4 then
                effState = 4
                SoundManager:getInstance():stopAllEffect()
                SoundManager:getInstance():playEffectByName(bdsmCfg[cfgId].Audio4, true)
            end
            if touchType == 1 then
                addNum = bdsmCfg[cfgId].Soft4
            elseif touchType == 2 then
                addNum = bdsmCfg[cfgId].Hard4
            elseif touchType == 3 then
                addNum = bdsmCfg[cfgId].Rapid4
            end
            if math.modf(math.floor(HpMap:getScaleY() * 100 + 0.5)) + addNum < bdsmCfg[cfgId].Q4 then    --不會倒退回前一階段
                addNum = 0
            end
        end
    else
        return
    end
    HpMap:setScaleY(math.max(0, math.min((HpMap:getScaleY() + addNum / 100), 1)))
    NodeHelper:setStringForLabel(container, { mHP = math.modf(math.floor(HpMap:getScaleY() * 100 + 0.5)) .. "%" })
end

function FetterShowPageBase:setDominanceAni(container)
    local cfgId = dominanceRoleID * 100 + selectPhoto
    if not bdsmCfg[cfgId] then
        return
    end
    local hpPer = math.modf(math.floor(HpMap:getScaleY() * 100 + 0.5))
    if bdsmCfg[cfgId].Q1 <= hpPer and bdsmCfg[cfgId].Q3 > hpPer then    --前兩階段使用無汗水的動畫
        if touchType == 1 then
            if not roleSpine.hSpine:isPlayingAnimation(aniName[selectPhoto * 100 + 1], 1) then
                roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 100 + 1], -1, 0.2)
            end
        elseif touchType == 2 then
            if not roleSpine.hSpine:isPlayingAnimation(aniName[selectPhoto * 100 + 2], 1) then
                roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 100 + 2], -1, 0.2)
            end
        elseif touchType == 3 then
            if not roleSpine.hSpine:isPlayingAnimation(aniName[selectPhoto * 100 + 3], 1) then
                roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 100 + 3], -1, 0.2)
            end
        end
    elseif bdsmCfg[cfgId].Q3 <= hpPer and 100 > hpPer then    --後兩階段使用有汗水的動畫
        if touchType == 1 then
            if not roleSpine.hSpine:isPlayingAnimation(aniName[selectPhoto * 100 + 4], 1) then
                roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 100 + 4], -1, 0.2)
            end
        elseif touchType == 2 then
            if not roleSpine.hSpine:isPlayingAnimation(aniName[selectPhoto * 100 + 5], 1) then
                roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 100 + 5], -1, 0.2)
            end
        elseif touchType == 3 then
            if not roleSpine.hSpine:isPlayingAnimation(aniName[selectPhoto * 100 + 6], 1) then
                roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 100 + 6], -1, 0.2)
            end
        end
    else
        if not isDominanceEnd then
            roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 100 + 7], 0)
            SoundManager:getInstance():stopAllEffect()
            SoundManager:getInstance():playEffectByName(bdsmCfg[cfgId].Audio5, false)   --更換成高潮用音效
            isDominanceEnd = true
            if not CCUserDefault:sharedUserDefault():getBoolForKey("RoleDominance" .. cfgId) then
                CCUserDefault:sharedUserDefault():setBoolForKey("RoleDominance" .. cfgId, true)
            end
            self:showDominanceEnd(container)
        end
    end
    if not isDominanceEnd then
        --TEST 
        --isDominanceEnd = true
        --self:showDominanceEnd(container)
    end
end

function FetterShowPageBase:showDominanceEnd(container)
    local cfgId = dominanceRoleID * 100 + selectPhoto
    local actionCfg = ConfigManager:getViewWaveCfg()[cfgId]
    if actionCfg == nil or actionCfg.Wait3 == nil then
        return
    end 
    local x1, y1 = unpack(common:split((actionCfg.X1Y1), ","))
    local x2, y2 = unpack(common:split((actionCfg.X2Y2), ","))
    local x3, y3 = unpack(common:split((actionCfg.X3Y3), ","))
    local action = CCArray:create()
    local spineNode = tolua.cast(roleSpine.hSpine, "CCNode")
    action:addObject(CCDelayTime:create(actionCfg.Wait3))
    local spawnAction = CCArray:create()
    spawnAction:addObject(CCMoveBy:create(actionCfg.Time1, ccp(x1, y1)))
    spawnAction:addObject(CCScaleTo:create(actionCfg.Time1, actionCfg.Scale))
    action:addObject(CCSpawn:create(spawnAction))
    action:addObject(CCDelayTime:create(actionCfg.Wait1))
    action:addObject(CCMoveBy:create(actionCfg.Time2, ccp(x2, y2)))
    action:addObject(CCDelayTime:create(actionCfg.Wait2))
    --action:addObject(CCMoveBy:create(actionCfg.Time3, ccp(X3, Y3)))
    --action:addObject(CCDelayTime:create(actionCfg.Wait3))
    local spawnAction2 = CCArray:create()
    spawnAction2:addObject(CCMoveBy:create(actionCfg.Time3, ccp(x3, y3)))
    spawnAction2:addObject(CCScaleTo:create(actionCfg.Time3, 1.0))
    action:addObject(CCSpawn:create(spawnAction2))

    local seqAction = CCSequence:create(action)
    spineNode:runAction(seqAction)
end

function FetterShowPageBase:onDominance(container)
    mIsDominance = true
    SoundManager:getInstance():stopMusic()  --關閉BGM
    SoundManager:getInstance():playMusic("BDSM_BG.mp3")
    self:showDominanceMode(container, true)
    self:initDominance(container)

    -- 設定spine為初始動作
    roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 2 - 1], -1)
end

function FetterShowPageBase:onTouchArrow(container)
    self:playShowWindow(container, not isShowingWindow)
end

function FetterShowPageBase:playWindowArrow(container)
    if isShowingWindow then
        container:runAnimation("story_on")
    else
        container:runAnimation("story_0ff")
    end
end

function FetterShowPageBase:playShowWindow(container, isShow)
    if isShow then
        container:runAnimation("window_appear")
    else
        container:runAnimation("window_disappear")
    end
    isShowingWindow = isShow
end

function FetterShowPageBase:clearAndReBuildAllItem(container)
    --    container.mScrollView:removeAllCell()
    --    local fetterId = FetterManager.getViewFetterId()
    --    local list = FetterManager.getAllRelationByFetterId(fetterId)
    --    if #list >= 1 then
    --        for i,v in ipairs(list) do
    --            local titleCell = CCBFileCell:create()
    --            local panel = FetterShowContent:new({id = v.id, index = i})
    --            titleCell:registerFunctionHandler(panel)
    --            titleCell:setCCBFile(FetterShowContent.ccbiFile)
    --            container.mScrollView:addCellBack(titleCell)
    --        end
    --        container.mScrollView:orderCCBFileCells()
    --    end
    --    NodeHelper:setNodesVisible(container,{mEmptyFetterTxt = #list < 1})
end

function FetterShowPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function FetterShowPageBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function FetterShowPageBase:initAlbumImgState(container)
    albumCfg = ConfigManager:getAlbumCfg()
    local roleId = FetterManager.getRoleIdByFetterId(FetterManager.getViewFetterId())
    local mercenaryInfo = UserMercenaryManager:getUserMercenaryByItemId(roleId)
    for i = 1, #photoVarList, 1 do
        container:getVarNode(photoVarList[i]):setVisible(albumCfg[roleId].Photo >= i)
    end
    if mercenaryInfo == nil or mercenaryInfo.activiteState ~= 1 then
        roleStageLevel = -1
        roleRareLevel = 0
        NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = true })
        for i = 1, #photoVarList, 1 do
            container:getVarMenuItemImage(photoVarList[i]):setNormalImage(CCSprite:create("photo_off.png"))
        end
        return
    end
    NodeHelper:setNodesVisible(container, { mDominance = false, mWindow = false, mUnlock = false })
    roleStageLevel = mercenaryInfo.stageLevel
    local roleStageLevel2 = mercenaryInfo.stageLevel2
    local archiveCfg = ConfigManager:getIllustrationCfg()
    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)
    local roleCfg = ConfigManager.getRoleCfg()
    if roleCfg[data.roleId] then
        roleRareLevel = roleCfg[data.roleId].quality
    end
    for i = 1, #photoVarList, 1 do
        if archiveCfg[FetterManager.getFetterIdByRoleId(data.roleId)].isSkin == 1 then
            if roleStageLevel2 + 1 >= i and roleStageLevel >= i then
                local photoName = "Photo_" .. data.roleId .. "0" .. i .. ".png"
                local truePhoto = CCSprite:create(photoName)
                if truePhoto then
                    container:getVarMenuItemImage(photoVarList[i]):setNormalImage(truePhoto)
                else
                    container:getVarMenuItemImage(photoVarList[i]):setNormalImage(CCSprite:create("photo_off.png"))
                end
            else
                container:getVarMenuItemImage(photoVarList[i]):setNormalImage(CCSprite:create("photo_off.png"))
            end
        else 
            if roleStageLevel >= i then
                local photoName = "Photo_" .. data.roleId .. "0" .. i .. ".png"
                local truePhoto = CCSprite:create(photoName)
                if truePhoto then
                    container:getVarMenuItemImage(photoVarList[i]):setNormalImage(truePhoto)
                else
                    container:getVarMenuItemImage(photoVarList[i]):setNormalImage(CCSprite:create("photo_off.png"))
                end
            else
                container:getVarMenuItemImage(photoVarList[i]):setNormalImage(CCSprite:create("photo_off.png"))
            end
        end
    end
end

function FetterShowPageBase:initDominance(container)
    HpMap = container:getVarSprite("mBar")
    HpMap:setScaleY(0)
    NodeHelper:setStringForLabel(container, { mHP = "0%" })
    bdsmCfg = ConfigManager:getBdsmCfg()
    isDominanceEnd = false
end

function FetterShowPageBase:clearDominanceData(container)
    --dominanceRoleID = 0
    touchType = 0
    timeCount = 0
    isDominanceEnd = false
    self:setDominanceBtnState(container, touchType)

    --selectPhoto = 3
    local cfgId = dominanceRoleID * 100 + selectPhoto
    if not CCUserDefault:sharedUserDefault():getBoolForKey("RoleDominance" .. cfgId) then -- 未調教完成
        if not roleSpine.hSpine:isPlayingAnimation(aniName[selectPhoto * 2 - 1], 1) then
            roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 2 - 1], -1)
        end
    else -- 已調教完成
        if not roleSpine.hSpine:isPlayingAnimation(aniName[selectPhoto * 2], 1) then
            roleSpine.hSpine:runAnimation(1, aniName[selectPhoto * 2], -1)
        end
    end
end

function FetterShowPageBase:showAlbumMode(container, isShow)
    if isShow then
        self:setAllBtnVistible(container, false)
        NodeHelper:setNodesVisible(container, { mBtnNode = true, mBtmNode = false, mBtmAlbum = true, mBossHpNode = false, mNodeTempo = false, mNodePhoto = true, mDominance = false })
    else
        self:setAllBtnVistible(container, true)
        NodeHelper:setNodesVisible(container, { mBtmNode = true, mBtmAlbum = false, mBossHpNode = false, mNodeTempo = false, mNodePhoto = false })
    end
end

function FetterShowPageBase:showDominanceMode(container, isShow)
    if isShow then
        NodeHelper:setNodesVisible(container, { mBossHpNode = true, mNodeTempo = true, mDominance = false, mWindow = false, mNodePhoto = false, mHideBtnNode = false }) --調教中不顯示照相機
    else
        NodeHelper:setNodesVisible(container, { mBossHpNode = false, mNodeTempo = false, mDominance = true, mWindow = true, mNodePhoto = true, mHideBtnNode = true })
        self:setSituationWindow(container)
        if isShowingWindow then
            self:playWindowArrow(container)
        else
            self:playShowWindow(container, true)
        end
    end
end

function FetterShowPageBase:setAllBtnVistible(container, isShow)
    --照相機一般狀態永遠顯示
    NodeHelper:setNodesVisible(container, { mAlbumBtnNode = isShow, mWeaponBtnNode = isShow, mGrowBtnNode = isShow, mSkillBtnNode = isShow, 
                                            mFetterBtnNode = isShow, mRelationshipNode = isShow, mHideBtnNode = true })
end

function FetterShowPageBase:getContainer()
    return tempContainer
end

function FetterShowPageBase:setVisibleSpine(isHSpine)
    local spineNode = tolua.cast(roleSpine.spine, "CCNode")
    local hSpineNode = nil
    -- 設定顯示一般spine/h spine
    if roleStageLevel > 0 then --有獲得角色
        spineNode:setVisible(not isHSpine)
        if roleSpine.hSpine then
            hSpineNode = tolua.cast(roleSpine.hSpine, "CCNode")
            hSpineNode:setVisible(isHSpine)
            if hSpineBg then
                hSpineBg:setVisible(isHSpine)
            end
        end
        if graySprite then
            graySprite:setVisible(false)
        end
    else --未解鎖
        spineNode:setVisible(false)
        if roleSpine.hSpine then
            hSpineNode = tolua.cast(roleSpine.hSpine, "CCNode")
            hSpineNode:setVisible(false)
            if hSpineBg then
                hSpineBg:setVisible(false)
            end
        end
        if graySprite then
            graySprite:setVisible(true)
        end
    end
end

function FetterShowPageBase:createTouchLayer(container)
    local touchLayer = tolua.cast(container:getVarNode("mTouchLayer"), "CCLayer");

    touchLayer:setVisible(false);
    touchLayer:setTouchEnabled(true)
    touchLayer:setTouchMode(kCCTouchesOneByOne);
    touchLayer:registerScriptTouchHandler( function(eventType, touchLayer)
        if eventType == "began" then
        elseif eventType == "moved" then
        elseif eventType == "ended" then
            return self:onLayerTouchEnded(container, touchLayer)
        end
        return true
    end );
end

function FetterShowPageBase:onLayerTouchEnded(container, touch)
    NodeHelper:setNodesVisible(container, { mTouchLayer = false, mCloseNode = true, mReturnNode = true })
    self:onReturn(container)
    return true
end

function FetterShowPageBase:setDominanceBtnState(container, state)
    if state == 1 then
        NodeHelper:setNormalImages(container, { mBtnSoft = "btn_gentle_S.png", mBtnHard = "btn_hard.png", mBtnRapid = "btn_fast.png" })
    elseif state == 2 then
        NodeHelper:setNormalImages(container, { mBtnSoft = "btn_gentle.png", mBtnHard = "btn_hard_S.png", mBtnRapid = "btn_fast.png" })
    elseif state == 3 then
        NodeHelper:setNormalImages(container, { mBtnSoft = "btn_gentle.png", mBtnHard = "btn_hard.png", mBtnRapid = "btn_fast_S.png" })
    else
        NodeHelper:setNormalImages(container, { mBtnSoft = "btn_gentle.png", mBtnHard = "btn_hard.png", mBtnRapid = "btn_fast.png" })
    end
end

function FetterShowPageBase:setSituationWindow(container)
    local cfgId = dominanceRoleID * 100 + selectPhoto
    local titleKey = "@Situation" .. cfgId
    local textKey = "@Dialogue" .. cfgId
    -- 關閉scrollbar顯示
    NodeHelper:setNodesVisible(container, { mScrollBar = false })
    -- 設定標題
    NodeHelper:setStringForLabel(container, { mWindowTitle = common:getLanguageString(titleKey) })
    -- 設定內文
    local textTTFLabel = CCLabelTTF:create(common:getLanguageString(textKey), "Barlow-SemiBold.ttf", 21)
	textTTFLabel:setPosition(ccp(0, 0))
    textTTFLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
    textTTFLabel:setColor(NodeHelper:_getColorFromSetting("0 0 0"))
    local windowScrollView = container:getVarScrollView("mWindowScrollView")
    windowScrollView:removeAllCell()
    windowScrollView:setContentSize(CCSizeMake(450.0, textTTFLabel:getContentSize().height))
    windowScrollView:getContainer():setPosition(ccp(0, windowScrollView:getViewSize().height - textTTFLabel:getContentSize().height))
    windowScrollView:addChild(textTTFLabel)
end

function FetterShowPageBase:ReSetSexyModeBtn(container)
    local isnudeKey = "Nuded_" .. UserInfo.serverId .."_".. UserInfo.playerInfo.playerId
    local isShow = CCUserDefault:sharedUserDefault():getBoolForKey(isnudeKey)
    NodeHelper:setNodesVisible(container, { mdressOff = not isShow, mdressOn = isShow })
end
function FetterShowPageBase:onSetNude(container)

    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)

    local isnudeKey = "Nuded_" .. UserInfo.serverId .."_".. UserInfo.playerInfo.playerId
    local isNude = CCUserDefault:sharedUserDefault():getBoolForKey(isnudeKey)
    local AniName = "Stand"
    if roleSpine.spine then
        local MainRoleSpineID = data.roleId
        local roleId = UserInfo.roleInfo.itemId
        if MainRoleSpineID ~= 0 and MainRoleSpineID ~= UserInfo.roleInfo.itemId then -- other Role
            local tmpRoleData = ConfigManager.getRoleCfg()[MainRoleSpineID]
            if tmpRoleData ~= nil then
                roleId = MainRoleSpineID
                if UserMercenaryManager:CanBeNude(roleId) then
                    if not isNude then
                        AniName = "Stand_H"
                    end
                end
            end
            roleSpine.spine:runAnimation(1, AniName, -1)
        end 
    end
    if isNude then
        MessageBoxPage:Msg_Box_Lan("@OffDress")
    else
        MessageBoxPage:Msg_Box_Lan("@OnDress")
    end
    CCUserDefault:sharedUserDefault():setBoolForKey(isnudeKey, not isNude)
    self:ReSetSexyModeBtn(container) 
   
    if (FetterManager.getIllCfgByRoleId(data.roleId).isSkin == 1) then
        local skininfo = UserMercenaryManager:getUserMercenaryByItemId(data.roleId)
        local roleCfg = ConfigManager.getRoleCfg()
        local maininfo = nil
        for i, v in ipairs(roleCfg[data.roleId].FashionInfos) do
            if v ~= data.roleId then        
                maininfo = UserMercenaryManager:getUserMercenaryByItemId(v)
                break    
            end
        end
        if (maininfo)and(maininfo.stageLevel < 2) then
            MessageBoxPage:Msg_Box_Lan("@OnDress")
            return
        end

        if(skininfo) and(skininfo.stageLevel2 <= 0) then
            local FashionLockPopUp = require('FashionLockPopUp')
            FashionLockPopUp:setUnlockItemId(data.roleId)
            PageManager.pushPage("FashionLockPopUp")
        end
    end
end

function FetterShowPageBase:getcontainer()
    return tempContainer
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local FetterShowPage = CommonPage.newSub(FetterShowPageBase, thisPageName, option);

return FetterShowPage