----------------------------------------------------------------------------------
-- 别人的副将
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'ViewPlayerMercenaryPage'
local Activity_pb = require("Activity_pb");
local EquipScriptData = require("EquipScriptData")
local HP_pb = require("HP_pb");
local Const_pb = require("Const_pb")
local PBHelper = require("PBHelper");
local RoleOpr_pb = require "RoleOpr_pb"
local UserMercenaryManager = require("UserMercenaryManager")
local SkillManager = require("Skill.SkillManager")
local ItemManager = require("Item.ItemManager");
local MercenaryTouchSoundManager = require("MercenaryTouchSoundManager")
local RelationshipManager = require("RelationshipManager")
local ViewPlayerMercenaryPage = {
    ccbiFile = "EquipmentPageOtherMercenaryContent.ccbi"
}
local opcodes = {
    ROLE_CARRY_SKILL_S = HP_pb.ROLE_CARRY_SKILL_S,
    ROLE_FIGHT_S = HP_pb.ROLE_FIGHT_S,
}

local EquipPartNames = {
    ["Chest"] = Const_pb.CUIRASS,
    ["Legs"] = Const_pb.LEGGUARD,
    ["MainHand"] = Const_pb.WEAPON1,
    ["OffHand"] = Const_pb.WEAPON2,
    ["Finger"] = Const_pb.RING,
    ["Helmet"] = Const_pb.HELMET,
};
local eventMap = { }
for equipName, _ in pairs(EquipPartNames) do
    eventMap["on" .. equipName] = "showEquipDetail";
end
eventMap["onBadge"] = "onBadgeBtn"
for i = 1, 4 do
    eventMap["onSkill" .. i] = "showSkill";
end
eventMap.onFetter = "onFetter"

eventMap.onRelationship = "onRelationship"

local _selfContainer = nil
local _curMercenaryId = 0
local _curMercenaryInfo = nil
local _fateWearsPage = nil

function ViewPlayerMercenaryPage.onFunction(eventName, container)
    if eventMap[eventName] then
        ViewPlayerMercenaryPage[eventMap[eventName]](ViewPlayerMercenaryPage, container, eventName);
    elseif eventName == "onExpedition" then
        ViewPlayerMercenaryPage:onExpedition(container)
    elseif eventName == "onState" then
        ViewPlayerMercenaryPage:onJoinBattle(container)
    elseif eventName == "onTrain" then
        if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.MERCENARY_TRAIN_LIMIT then
            MercenaryEnhancePage_setRoleId(_curMercenaryInfo.roleId);
            PageManager.pushPage("MercenaryEnhancePage");
        else
            MessageBoxPage:Msg_Box(common:getLanguageString('@MercenaryTrainLimit', GameConfig.MERCENARY_TRAIN_LIMIT))
        end

    elseif eventName == "onRisingStar" then
        if _curMercenaryInfo.isStage then
            -- 可进阶
            local MercenaryUpgradeStagePage = require("MercenaryUpgradeStagePage")
            MercenaryUpgradeStagePage:setMercenaryId(_curMercenaryInfo.roleId);
            PageManager.pushPage("MercenaryUpgradeStagePage");
        else
            -- 不可进阶
            local MercenaryUpgradeStarPage = require("MercenaryUpgradeStarPage")
            MercenaryUpgradeStarPage:setMercenaryId(_curMercenaryInfo.roleId);
            PageManager.pushPage("MercenaryUpgradeStarPage");
        end
    elseif eventName == "onAttributeDetail" then
        local PlayerAttributePage = require("PlayerAttributePage")
        PlayerAttributePage:setRoleInfo(_curMercenaryInfo);
        PageManager.pushPage("PlayerAttributePage")
    end
end
function ViewPlayerMercenaryPage:onFetter(container)
    local FetterManager = require("FetterManager")
    PageManager.pushPage("FetterPage")
end


function ViewPlayerMercenaryPage:onRelationship(container)
    local RelationshipPopUp = require("RelationshipPopUp")
    RelationshipPopUpBase_setRoleId(_curMercenaryInfo.itemId , ViewPlayerInfo:getMercenaryFightingId())
    PageManager.pushPage("RelationshipPopUp")
end

function ViewPlayerMercenaryPage:getSpineAttachNode()
    return self.mSpineAttachNode;
end

function ViewPlayerMercenaryPage:onEnter(ParentContainer)
    self.container = ScriptContentBase:create(ViewPlayerMercenaryPage.ccbiFile)
    self.container:registerFunctionHandler(ViewPlayerMercenaryPage.onFunction)
    self:registerPacket(ParentContainer)
    _selfContainer = self.container
    -- _curMercenaryInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryId)

    --NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"), 0.5)
    self:refreshPage(_selfContainer);
    MercenaryTouchSoundManager:initTouchButton(_selfContainer, _curMercenaryInfo.itemId)

    --NodeHelper:setNodesVisible(self.container, { mBtmNodeBtn = false })
     local FateDataManager = require("FateDataManager")
    --如果猎命系统开启，则显示猎命入口
--    NodeHelper:setNodesVisible(self.container,{
--        mPrivateNode = FateDataManager:getFateWearNum(_curMercenaryInfo.level) > 0 , 
--    })
    NodeHelper:setNodesVisible(self.container, { mPrivateBtnNode = GameConfig.isOpenBadge })
    ViewPlayerMercenaryPage:setShowFateSubPage(_showFateSubPage,true)


        NodeHelper:setNodesVisible(self.container, { mRelationshipNode = RelationshipManager:getRelationshipDataByRoleId(_curMercenaryInfo.itemId) ~= nil })
 


    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
       -- NodeHelper:setNodesVisible(self.container, { mRelationshipNode = RelationshipManager:getRelationshipDataByRoleId(_curMercenaryInfo.itemId) ~= nil })
    else
       -- NodeHelper:setNodesVisible(self.container, { mRelationshipNode = false })
    end
    --ViewPlayerInfo:getMercenaryFightingId()
    return self.container
end
--显示猎命界面
function ViewPlayerMercenaryPage:onBadgeBtn(container)
    --container:runAnimation("close")
    PageManager.refreshPage("ViewPlayerEquipmentPage","ShowFatePage")
end

function ViewPlayerMercenaryPage:onAnimationDone(container)
    local animationName=tostring(container:getCurAnimationDoneName())
	if animationName=="close" then
        PageManager.refreshPage("ViewPlayerEquipmentPage","ShowFatePage")
    end
end

function ViewPlayerMercenaryPage:setShowFateSubPage(showFateSubPage,isFirst)
    _showFateSubPage = showFateSubPage
    NodeHelper:setNodesVisible(_selfContainer,{mMervenaryEquipNode = not _showFateSubPage})
    NodeHelper:setNodesVisible(_selfContainer,{mMervenaryPrivateNode = _showFateSubPage})
    if _showFateSubPage and not _fateWearsPage then
        _fateWearsPage = require("FateWearsPage")
        _fateWearsPage:setFateInfo({mercenaryId = _curMercenaryInfo.roleId,isOthers = true,fateIdList = _curMercenaryInfo.dress,level = _curMercenaryInfo.level} )
        local subContainer = _fateWearsPage:onEnter(_selfContainer)
        _fateWearsPage.container = subContainer
        _fateWearsPage:registerPacket(_parentContainer)
        _selfContainer:getVarNode("mMervenaryPrivateNode"):addChild(subContainer)
        subContainer:release()
        --if not isFirst then
            --subContainer:runAnimation("open")
        --end
    elseif not _showFateSubPage and _fateWearsPage then
        _fateWearsPage:removePacket(_parentContainer)
        _fateWearsPage:onExit(_selfContainer)
        _fateWearsPage.container:removeFromParentAndCleanup(true)
        _fateWearsPage = nil
        --_selfContainer:runAnimation("open")
    end
end
function ViewPlayerMercenaryPage:onExpedition(container)
    local UserInfo = require("PlayerInfo.UserInfo");
    UserInfo.sync()
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.MERCENARY_EXPEDITION_LIMIT then
        PageManager.pushPage("MercenaryExpeditionPage")
    else
        MessageBoxPage:Msg_Box(common:getLanguageString('@MercenaryExpeditionOpenLimit', GameConfig.MERCENARY_EXPEDITION_LIMIT))
    end
end
function ViewPlayerMercenaryPage:onJoinBattle(container)

    local message = RoleOpr_pb.HPRoleFight();
    if message ~= nil then
        message.roleId = _curMercenaryInfo.roleId;
        local pb_data = message:SerializeToString();
        PacketManager:getInstance():sendPakcet(HP_pb.ROLE_FIGHT_C, pb_data, #pb_data, false);
    end

end
function ViewPlayerMercenaryPage:refreshPage(container)
    -- _curMercenaryInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryId)
    NodeHelper:setNodesVisible(container, { mTrainNode = false, mRisingStarNode = false, mExpeditionNode = false, mStateNode = false })
    self:showFightAttrInfo(container);
    self:showEquipInfo(container);
    self:showSkillInfo(container);
    self:showRoleSpine(container)

    local OSPVPManager = require("OSPVPManager")
    NodeHelper:setNodesVisible(container, { mFetterNode = not OSPVPManager.isWatchOSPlayer })
end

function ViewPlayerMercenaryPage:showRoleSpine(container)
--    local roleId = _curMercenaryInfo.itemId
--    local prof = _curMercenaryInfo.prof
--    local heroNode = container:getVarNode("mSpine")
--    local heroNodeParent = container:getVarNode("mSpineParent")
--    local effNode = container:getVarNode("mEff")
--    if heroNode then
--        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
--        local width, height = visibleSize.width, visibleSize.height
--        local rate = visibleSize.height / visibleSize.width
--        local desighRate = GameConfig.ScreenSize.height / GameConfig.ScreenSize.width
--        rate = rate / desighRate
--        heroNode:removeAllChildren()
--        local spine = nil

--        --
--        local roleData = ConfigManager.getRoleCfg()[roleId]
--        local spinePath, spineName = unpack(common:split((roleData.spine), ","))
--        spine = SpineContainer:create(spinePath, spineName)
--        if animCCbi ~= nil then
--            local eft = ScriptContentBase:create(animCCbi, 0);
--            effNode:addChild(eft);
--            eft:release();
--            heroNode = eft:getVarNode("mSpine");
--            local avatarScale = GameConfig.AvatarSpineScale[roleId]
--            if avatarScale then
--                local scaleX = rate * avatarScale[1]
--                local scaleY = rate * avatarScale[2]
--                heroNode:setScaleX(scaleX)
--                heroNode:setScaleY(scaleY)
--            else
--                heroNode:setScale(rate)
--            end
--        end

--        local spineNode = tolua.cast(spine, "CCNode")
--        heroNode:addChild(spineNode)
--        heroNode:setScale(roleData.spineScale)
--        local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
--        NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
--        local animationName = "Stand";
--        if GameConfig.MercenarySpineSpecialAction[roleId] then
--            -- animationName = GameConfig.MercenarySpineSpecialAction[roleId]
--        end
--        spine:runAnimation(1, animationName, -1)
--        local roleCfg = ConfigManager.getRoleCfg()
--        local bgImg = roleCfg[roleId].bgImg
--        local scale = NodeHelper:getAdjustBgScale(1)
--        if scale < 1 then scale = 1 end
--        NodeHelper:setSpriteImage(container, { mBGPic = bgImg }, { mBGPic = scale })
--    end

--    self.mSpineAttachNode = tolua.cast(heroNode, "CCNode");

    local roleId = _curMercenaryInfo.itemId
    if newRoleId then
        roleId = newRoleId
    end
    local prof = _curMercenaryInfo.prof
    local heroNode = container:getVarNode("mSpine")
    local heroNodeParent = container:getVarNode("mSpineParent")
    local effNode = container:getVarNode("mEff")
    if effNode then
        effNode:removeAllChildren()
    end

    if not heroNode then
        return
    end

    local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local width, height = visibleSize.width, visibleSize.height
    local rate = visibleSize.height / visibleSize.width
    local desighRate = 1280 / 720
    rate = rate / desighRate
    heroNode:removeAllChildren()
    local spine = nil
    -- modify
    local roleData = ConfigManager.getRoleCfg()[roleId]

    local dataSpine = common:split((roleData.spine), ",")
    local spinePath, spineName, animCCbi = dataSpine[1], dataSpine[2], nil
    spine = SpineContainer:create(spinePath, spineName)
    if animCCbi ~= nil then
        local eft = ScriptContentBase:create(animCCbi, 0)
        effNode:addChild(eft)
        eft:release()
        -- eft:setPosition(ccp(-640/2, -960/2))
        heroNode = eft:getVarNode("mSpine")

        -- scale
        local avatarScale = GameConfig.AvatarSpineScale[roleId]
        if avatarScale then
            local scaleX = rate * avatarScale[1]
            local scaleY = rate * avatarScale[2]
            -- heroNode:setScaleX(scaleX)
            -- heroNode:setScaleY(scaleY)
        else
            -- heroNode:setScale(rate)
        end

    end
    -- the end

    local spineNode = tolua.cast(spine, "CCNode")
    spineNode:setScale(roleData.spineScale)
    heroNode:addChild(spineNode)
    local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
    NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))

    local scale = NodeHelper:getScaleProportion()
    if scale > 1 then
        -- spineNode:setScale(roleData.spineScale +(roleData.spineScale - roleData.spineScale / scale))
    end

    local avatarScale = GameConfig.AvatarSpineScale[roleId]
    if avatarScale then
        local scaleX = rate * avatarScale[1]
        local scaleY = rate * avatarScale[2]
        -- heroNodeParent:setScaleX(scaleX)
        -- heroNodeParent:setScaleY(scaleY)
    else
        -- heroNodeParent:setScale(rate)
    end
    local animationName = "Stand";
    if GameConfig.MercenarySpineSpecialAction[roleId] then
        animationName = GameConfig.MercenarySpineSpecialAction[roleId]
    end
    spine:runAnimation(1, animationName, -1)
    local roleCfg = ConfigManager.getRoleCfg()
    local bgImg = roleCfg[roleId].bgImg
    local bgScale = NodeHelper:getAdjustBgScale(0)
    if bgScale < 1 then bgScale = 1 end
    NodeHelper:setSpriteImage(container, { mBGPic = bgImg }, { mBGPic = bgScale })
    local deviceHeight = CCDirector:sharedDirector():getWinSize().height
    if deviceHeight < 900 then
        -- ipad change spine position
        -- NodeHelper:autoAdjustResetNodePosition(spineNode, -0.3)
    end

    self.mSpineAttachNode = tolua.cast(heroNode, "CCNode");


end

function ViewPlayerMercenaryPage:showSkillInfo(container)
    -- _curMercenaryInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryId)
    local skillList = _curMercenaryInfo.skills
    -- message RoleSkill
    local ringList = _curMercenaryInfo.ringId
    --

    local SkillPic = ""
    -- 技能
    local skillCfg = ConfigManager.getSkillCfg()
    for i = 1, 2 do
        if i <= #skillList then
            -- 已经开启的Skill1
            if skillList[i].skillId > 0 then
                local slillId = skillList[i].itemId
                local itemInfo = skillCfg[slillId]
                SkillPic = itemInfo.icon
            else
                SkillPic = GameConfig.SkillStatus.LOCK_SKILL
            end
        else
            -- 未开启的技能
            SkillPic = GameConfig.SkillStatus.LOCK_SKILL
        end
        local sprite2Img = {
            ["mSkill" .. i] = SkillPic,
        }
        NodeHelper:setSpriteImage(container, sprite2Img);
    end
    -- 光环
    SkillPic = ""
    local ringCfg = ConfigManager.getMercenaryRingCfg()
    for i = 1, 2 do
        if i <= #ringList then
            if ringList[i] > 0 then
                local itemInfo = ringCfg[ringList[i]]
                SkillPic = itemInfo.icon
            else
                SkillPic = GameConfig.SkillStatus.LOCK_SKILL
            end
        else
            -- 未开启的技能
            SkillPic = GameConfig.SkillStatus.LOCK_SKILL
        end
        local sprite2Img = {
            ["mSkill" ..(i + 2)] = SkillPic,
        }
        NodeHelper:setSpriteImage(container, sprite2Img);
    end
end

function ViewPlayerMercenaryPage:showSkill(container, eventName)

    local MercenarySkillPreviewPage = require("MercenarySkillPreviewPage")
    MercenarySkillPreviewPage:setMercenaryInfo(_curMercenaryInfo);
    PageManager.pushPage("MercenarySkillPreviewPage");

end
function ViewPlayerMercenaryPage:showEquipDetail(container, eventName)
    local UserInfo = require("PlayerInfo.UserInfo");
    local partName = string.sub(eventName, 3);
    -- _curMercenaryInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryId)
    local childNode = container:getVarMenuItemCCB("m" .. partName)
    childNode = childNode:getCCBFile()
    local part = EquipPartNames[partName];
    local isShowNotice = false
    -- UserEquipManager:isPartNeedNotice(part,_curMercenaryInfo.roleId)
    -- UserEquipManager:cancelNotice(part,_curMercenaryInfo.roleId);
    NodeHelper:setNodesVisible(childNode, { mHelmetPoint = false });
    local roleEquip = ViewPlayerInfo:getMercenaryEquipByPart(part, _curMercenaryInfo);
    -- UserMercenaryManager:getEquipByPart(_curMercenaryInfo.roleId, part);
    if roleEquip then
        PageManager.viewEquipInfo(roleEquip.equipId, true);
        -- PageManager.showEquipInfo(roleEquip.equipId, _curMercenaryInfo.roleId, isShowNotice);
        -- else
        --        EquipSelectPage_setPart(part, _curMercenaryInfo.roleId);
        -- 	PageManager.pushPage("EquipSelectPage");

    end
end	
function ViewPlayerMercenaryPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end
function ViewPlayerMercenaryPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end
function ViewPlayerMercenaryPage:showFightAttrInfo(container)
    local curMercenaryCfg = ConfigManager.getRoleCfg()[_curMercenaryInfo.itemId]
    local visibleMap = { }
    local statusImage = GameConfig.MercenaryBattleState.status_free;
    local status = _curMercenaryInfo.status;

    if status == Const_pb.FIGHTING then
        statusImage = GameConfig.MercenaryBattleState.status_fight
    elseif status == Const_pb.RESTTING then
        statusImage = GameConfig.MercenaryBattleState.status_free
    elseif status == Const_pb.EXPEDITION then
        statusImage = GameConfig.MercenaryBattleState.status_expedition
    end
    local showStageLevel = _curMercenaryInfo.stageLevel - 1
    if showStageLevel == 0 then
        showStageLevel = ""
    else
        showStageLevel = " +" .. showStageLevel
    end
    local lb2Str = {
        --mAttribute1 = common:getLanguageString("@EquipmentHPTxt",PBHelper:getAttrById(_curMercenaryInfo.attribute.attribute,Const_pb.HP)),
        --mAttribute2 = common:getLanguageString("@EquipmentFightTxt",_curMercenaryInfo.fight),
        --mAttribute3 = common:getLanguageString("@EquipmentAttTxt",PBHelper:getAttrById(_curMercenaryInfo.attribute.attribute,Const_pb.MINDMG) .. "-" .. PBHelper:getAttrById(_curMercenaryInfo.attribute.attribute,Const_pb.MAXDMG)),
        --mMercenaryName = curMercenaryCfg.name .. showStageLevel,

        mFightPowerNum = common:getLanguageString("@EquipmentFightTxt",_curMercenaryInfo.fight),
        --mMercenaryName = ViewPlayerInfo:getRoleInfo().name .. " ( " .. common:getLanguageString(string.format("@ProfessionName_" ..  ViewPlayerInfo:getPlayerInfo().prof)) .." )",
        mMercenaryName = curMercenaryCfg.name .. showStageLevel,
    };
    visibleMap["mCareer1"] = curMercenaryCfg.profession == 1
    visibleMap["mCareer2"] = curMercenaryCfg.profession == 2
    visibleMap["mCareer3"] = curMercenaryCfg.profession == 3
    NodeHelper:setNodesVisible(container, visibleMap)
    -- NodeHelper:setSpriteImage(container,{ mCareer = curMercenaryCfg.smallIcon})
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setNormalImage(container, "mState", statusImage)
end

function ViewPlayerMercenaryPage:showEquipInfo(container)
    local lb2Str = { };
    local sprite2Img = { };
    local scaleMap = { };
    local nodesVisible = { };
    local colorMap = { }
    for equipName, part in pairs(EquipPartNames) do
        local levelStr = "";
        local enhanceLvStr = "";
        local icon = GameConfig.Image.ClickToSelect;
        local quality = GameConfig.Default.Quality;
        local aniVisible = false;
        local gemVisible = false;

        local showNotice = false
        -- UserEquipManager:isPartNeedNotice(part, _curMercenaryInfo.roleId);
        local childNode = container:getVarMenuItemCCB("m" .. equipName)
        childNode = childNode:getCCBFile()
        local roleEquip = ViewPlayerInfo:getMercenaryEquipByPart(part, _curMercenaryInfo);
        -- PBHelper:getRoleEquipByPart(_curMercenaryInfo.equips, part);
        local userEquip = nil
        if roleEquip then
            local equipId = roleEquip.equipItemId;
            levelStr = common:getR2LVL() .. EquipManager:getLevelById(equipId);
            enhanceLvStr = roleEquip.strength ~= 0 and "+" .. roleEquip.strength or "";
            icon = EquipManager:getIconById(equipId);
            quality = EquipManager:getQualityById(equipId);
            -- aniVisible = UserEquipManager:isGodly(roleEquip.equipId);
            userEquip = ViewPlayerInfo:getEquipById(roleEquip.equipId)
            -- UserEquipManager:getUserEquipById(roleEquip.equipId);
            aniVisible = UserEquipManager:isEquipGodly(userEquip);
            ----现在发送的协议里面有装备的全部信息	
            if userEquip then
                local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
                if table.maxn(gemInfo) > 0 then
                    gemVisible = true;
                    for i = 1, 4 do
                        local gemId = gemInfo[i];
                        nodesVisible["mHelmetGemBG" .. i] = gemId ~= nil;
                        local gemSprite = "mHelmetGem0" .. i;
                        nodesVisible[gemSprite] = false;
                        if gemId ~= nil and gemId > 0 then
                            local icon = ItemManager:getGemSmallIcon(gemId);
                            if icon then
                                nodesVisible[gemSprite] = true;
                                sprite2Img[gemSprite] = icon;
                                scaleMap[gemSprite] = 1
                            end
                        end
                    end
                end
            end
            sprite2Img["mHelmetPic"] = icon;
        else
            local showPic = GameConfig.defaultEquipImage["Helmet"];

            if equipName == "MainHand" or equipName == "OffHand" then
                showPic = GameConfig.defaultEquipImage[equipName .. "_" .. _curMercenaryInfo.prof];
            else
                showPic = GameConfig.defaultEquipImage[equipName];
            end
            sprite2Img["mHelmetPic"] = showPic;
        end

        lb2Str["mHelmetLv"] = levelStr;
        lb2Str["mHelmetLvNum"] = enhanceLvStr;

        --colorMap["mHelmetLv"] = "32 29 0"
        --colorMap["mHelmetLvNum"] = "32 29 0"


        sprite2Img["mPic"] = NodeHelper:getImageByQuality(quality)
        sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(quality)
        nodesVisible["mHelmetAni"] = aniVisible;
        nodesVisible["mHelmetGemNode"] = gemVisible;
        nodesVisible["mHelmetPoint"] = showNotice;

        NodeHelper:addEquipAni(childNode, "mHelmetAni", aniVisible, nil, userEquip);
        NodeHelper:setStringForLabel(childNode, lb2Str);
        NodeHelper:setSpriteImage(childNode, sprite2Img, scaleMap);
        NodeHelper:setNodesVisible(childNode, nodesVisible);
        NodeHelper:setColorForLabel(childNode, colorMap)
    end


end
function ViewPlayerMercenaryPage:onReceiveMessage(ParentContainer)
    local message = ParentContainer:getMessage()
    local typeId = message:getTypeId();
     if _fateWearsPage then
        _fateWearsPage:onReceiveMessage(message,typeId)
    end
    if typeId == MSG_SEVERINFO_UPDATE then
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;
        if opcode == HP_pb.ROLE_INFO_SYNC_S or opcode == HP_pb.EQUIP_INFO_SYNC_S then
            if UserEquipManager:hasInited() then
                self:refreshPage(_selfContainer);
            end
        end
    elseif typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "MercenaryPage_RefreshSkill" then
            self:showSkillInfo(container)
        elseif pageName == thisPageName then
            self:refreshPage(_selfContainer);
        elseif pageName == "EquipMercenaryPage" and extraParam == "initTouchButton" then
            MercenaryTouchSoundManager:initTouchButton(_selfContainer, _curMercenaryInfo.itemId)
        end
    end
end
function ViewPlayerMercenaryPage:getPacketInfo()

end
function ViewPlayerMercenaryPage:onExecute(ParentContainer)
    if _fateWearsPage then
        _fateWearsPage:onExecute(_selfContainer)
    end
end

function ViewPlayerMercenaryPage:getActivityInfo()

end
function ViewPlayerMercenaryPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
     if _fateWearsPage then
        _fateWearsPage:onReceivePacket(opcode,msgBuff)
    end
    if opcode == opcodes.ROLE_CARRY_SKILL_S then
        self:showSkillInfo();
    elseif opcode == opcodes.ROLE_FIGHT_S then
        self:refreshPage(_selfContainer);
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    end

end

function ViewPlayerMercenaryPage:setMercenaryId(mercenaryInfo,showFateSubPage)
    --_curMercenaryId = mercenaryInfo
    _curMercenaryInfo = mercenaryInfo
    _showFateSubPage = showFateSubPage
end
function ViewPlayerMercenaryPage:removePacket(ParentContainer)

end

function ViewPlayerMercenaryPage:onExit(ParentContainer)
    if _fateWearsPage then
        _fateWearsPage:removePacket(ParentContainer)
        _fateWearsPage:onExit(_selfContainer)
        _fateWearsPage.container:removeFromParentAndCleanup(true)
        _fateWearsPage = nil
    end
end

function ViewPlayerMercenaryPage_curMercenaryInfo()
    return _curMercenaryInfo
end

return ViewPlayerMercenaryPage

