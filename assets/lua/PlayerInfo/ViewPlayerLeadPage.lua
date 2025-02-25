
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'ViewPlayerLeadPage'
local Activity_pb = require("Activity_pb");
local EquipScriptData = require("EquipScriptData")
local HP_pb = require("HP_pb");
local Const_pb = require("Const_pb")
local PBHelper = require("PBHelper");
local ItemManager = require("Item.ItemManager");
local ViewPlayerLeadPage = {
    ccbiFile = "EquipmentPageOtherRoleContent.ccbi"
}
local opcodes = {
    ROLE_CARRY_SKILL_S = HP_pb.ROLE_CARRY_SKILL_S,
}

local EquipPartNames = {
    ["Helmet"] = Const_pb.HELMET,
    ["Neck"] = Const_pb.NECKLACE,
    ["Finger"] = Const_pb.RING,
    ["Wrist"] = Const_pb.GLOVE,
    ["Waist"] = Const_pb.BELT,
    ["Feet"] = Const_pb.SHOES,
    ["Chest"] = Const_pb.CUIRASS,
    ["Legs"] = Const_pb.LEGGUARD,
    ["MainHand"] = Const_pb.WEAPON1,
    ["OffHand"] = Const_pb.WEAPON2
};
local eventMap = { }
for equipName, _ in pairs(EquipPartNames) do
    eventMap["on" .. equipName] = "showEquipDetail";
end
for i = 1, 4 do
    eventMap["onSkill" .. i] = "showSkill";
end
eventMap["onAttributeDetail"] = "onAttributeDetail"
eventMap["onFetter"] = "onFetter"
local selfContainer = nil 
function ViewPlayerLeadPage.onFunction(eventName, container)
    if eventMap[eventName] then
        ViewPlayerLeadPage[eventMap[eventName]](ViewPlayerLeadPage, container, eventName);
    end
end

function ViewPlayerLeadPage:onFetter(container)
    local FetterManager = require("FetterManager")
    -- PageManager.pushPage("FetterPage")
    PageManager.changePage("FetterPage")
end


function ViewPlayerLeadPage:getSpineAttachNode()
    return self.mSpineAttachNode
end

function ViewPlayerLeadPage:onEnter(ParentContainer)
    self.ParentContainer = ParentContainer
    self.container = ScriptContentBase:create(ViewPlayerLeadPage.ccbiFile)
    self.container:registerFunctionHandler(ViewPlayerLeadPage.onFunction)
    self:registerPacket(ParentContainer)
    selfContainer = self.container

    --NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"), 0.5)
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mOtherName"), -0.5)
    NodeHelper:setNodesVisible(selfContainer, { mSkillNow = false, mSkillOther = true })
    self:refreshPage(selfContainer);

    return self.container
end
function ViewPlayerLeadPage:refreshPage(container)
    UserInfo.sync();
    self:showFightAttrInfo(container);
    self:showEquipInfo(container);
    self:showSkillInfo(container);
    self:showRoleSpine(container);
    self:showRedPoind(self.ParentContainer);

    local OSPVPManager = require("OSPVPManager")
    NodeHelper:setNodesVisible(container, { mFetterNode = not OSPVPManager.isWatchOSPlayer })
end

function ViewPlayerLeadPage:showRedPoind(container)
    -- local redPoint = UserEquipManager:getEquipLeadCount()
    NodeHelper:setNodesVisible(container, { mPlayerNew = false })
end
--- 添加主角Spine动画
function ViewPlayerLeadPage:showRoleSpine(container)
    local roleId = ViewPlayerInfo:getRoleInfo().itemId
    -- UserInfo.roleInfo.itemId;
    local heroNode = container:getVarNode("mSpine")
    if heroNode and heroNode:getChildByTag(10010) == nil then


        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width, height = visibleSize.width, visibleSize.height
        local rate = visibleSize.height / visibleSize.width
        local desighRate = GameConfig.ScreenSize.height / GameConfig.ScreenSize.width
        rate = rate / desighRate
        heroNode:removeAllChildren()

        local roleData = ConfigManager.getRoleCfg()[roleId]
        local spinePath, roleSpine = unpack(common:split((roleData.spine), ","))

        local spine = SpineContainer:create(spinePath, roleSpine)
        local spineNode = tolua.cast(spine, "CCNode")
        spineNode:setTag(10010)
        heroNode:addChild(spineNode)
        local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
        NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))

        heroNode:setScale(roleData.spineScale * rate)
        spine:runAnimation(1, "Stand", -1)
        local scale = NodeHelper:getAdjustBgScale(1)
        if scale < 1 then scale = 1 end
        NodeHelper:setSpriteImage(container, { mBGPic = roleData.bgImg }, { mBGPic = scale })

        self.mSpineAttachNode = heroNode
    end
end

function ViewPlayerLeadPage:showSkillInfo(container)
    local SkillManager = require("Skill.SkillManager")
    local skillCfg = ConfigManager.getSkillEnhanceCfg();
    local skillOpenCfg = ConfigManager.getSkillOpenCfg()
    local showSkills = ViewPlayerInfo:getSKillInfo()
    -- SkillManager:getArenaSkillList()
    local skillSize = #showSkills
    local SkillPic = ""
    for i = 1, 4 do
        if i <= skillSize then
            -- 已经开启的Skill1
            local skillItemId = showSkills[i].itemId
            -- SkillManager:getSkillItemIdUsingId(showSkills[i])
            local level = showSkills[i].level
            -- SkillManager:getSkillLevelUsingId(showSkills[i])
            if skillItemId ~= 0 then
                level = level ~= 0 and level or 1
            end
            skillItemId = tonumber(string.format(tostring(skillItemId) .. "%0004d", level))
            if skillItemId > 0 and skillCfg[skillItemId] then
                SkillPic = skillCfg[skillItemId]["icon"]
                NodeHelper:setStringForLabel(container, { ["mSkillLv" .. i] = common:getLanguageString("@LevelStr", level) })
            else
                SkillPic = GameConfig.SkillStatus.EMPTY_SKILL
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
end
function ViewPlayerLeadPage:onAttributeDetail(container, eventName)
    local PlayerAttributePage = require("PlayerAttributePage")
    PlayerAttributePage:setRoleInfo(ViewPlayerInfo:getRoleInfo());
    PageManager.pushPage("PlayerAttributePage")
end

function ViewPlayerLeadPage:showSkill(container, eventName)
    PageManager.pushPage("ViewPlayerSkillPage")
    -- PageManager.changePage("SkillPage");
end

function ViewPlayerLeadPage:showEquipDetail(container, eventName)
    local UserInfo = require("PlayerInfo.UserInfo");
    local partName = string.sub(eventName, 3);
    local childNode = container:getVarMenuItemCCB("m" .. partName)
    childNode = childNode:getCCBFile()
    local part = EquipPartNames[partName];
    local isShowNotice = UserEquipManager:isPartNeedNotice(part)
    UserEquipManager:cancelNotice(part);
    self:showRedPoind(self.ParentContainer)
    NodeHelper:setNodesVisible(childNode, { mHelmetPoint = false });
    local roleEquip = ViewPlayerInfo:getRoleEquipByPart(part)
    -- UserInfo.getEquipByPart(part);

    if roleEquip then
        PageManager.viewEquipInfo(roleEquip.equipId);
    end
end	
function ViewPlayerLeadPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end
function ViewPlayerLeadPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end
function ViewPlayerLeadPage:showFightAttrInfo(container)
    local UserInfo = require("PlayerInfo.UserInfo");
    local lb2Str = {
        --mAttribute1 = common:getLanguageString("@EquipmentHPTxt",ViewPlayerInfo:getRoleAttrById(Const_pb.HP)),
        -- UserInfo.getRoleAttrById
        --mAttribute2 = common:getLanguageString("@EquipmentFightTxt",ViewPlayerInfo:getRoleInfo().fight),
        -- UserInfo.roleInfo.fight
        --mAttribute3 = common:getLanguageString("@EquipmentAttTxt",ViewPlayerInfo:getDamageString()),
        mFightPowerNum = common:getLanguageString("@EquipmentFightTxt",ViewPlayerInfo:getRoleInfo().fight),
        --mMercenaryName = ViewPlayerInfo:getRoleInfo().name .. " ( " .. common:getLanguageString(string.format("@ProfessionName_" ..  ViewPlayerInfo:getPlayerInfo().prof)) .." )",
        mMercenaryName = ViewPlayerInfo:getRoleInfo().name .. " " .. common:getLanguageString("@MyID1") .. ViewPlayerInfo:getPlayerInfo().playerId,
        -- UserInfo.getDamageString()
        --mRoleName = ViewPlayerInfo:getRoleInfo().name .. " " .. common:getLanguageString("@MyID1") .. ViewPlayerInfo:getPlayerInfo().playerId,
    };
    NodeHelper:setStringForLabel(container, lb2Str);
end

function ViewPlayerLeadPage:showEquipInfo(container)
    local UserInfo = require("PlayerInfo.UserInfo");
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
        -- UserEquipManager:isPartNeedNotice(part);
        local childNode = container:getVarMenuItemCCB("m" .. equipName)
        childNode = childNode:getCCBFile()
        local roleEquip = ViewPlayerInfo:getRoleEquipByPart(part);
        -- UserInfo.getEquipByPart(part);
        local userEquip = nil
        if roleEquip then
            local equipId = roleEquip.equipItemId;
            levelStr = common:getR2LVL() .. EquipManager:getLevelById(equipId);
            enhanceLvStr = roleEquip.strength ~= 0 and "+" .. roleEquip.strength or "";
            icon = EquipManager:getIconById(equipId);
            quality = EquipManager:getQualityById(equipId);
            userEquip = ViewPlayerInfo:getEquipById(roleEquip.equipId)
            -- UserEquipManager:getUserEquipById(roleEquip.equipId);		
            aniVisible = UserEquipManager:isEquipGodly(userEquip);
            -- UserEquipManager:isGodly(roleEquip.equipId);

            local gemInfo = PBHelper:getGemInfo(roleEquip.gemInfo)
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
            sprite2Img["mHelmetPic"] = icon;
        else
            local showPic = GameConfig.defaultEquipImage["Helmet"];

            if equipName == "MainHand" or equipName == "OffHand" then
                showPic = GameConfig.defaultEquipImage[equipName .. "_" .. ViewPlayerInfo:getRoleInfo().prof];
            else
                showPic = GameConfig.defaultEquipImage[equipName];
            end
            sprite2Img["mHelmetPic"] = showPic;

        end

        lb2Str["mHelmetLv"] = levelStr;
        lb2Str["mHelmetLvNum"] = enhanceLvStr;

        --colorMap["mHelmetLv"] = "32 29 0"
        --colorMap["mHelmetLvNum"] = "32 29 0"

        sprite2Img["mPic"] = NodeHelper:getImageByQuality(quality);
        sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(quality);
        nodesVisible["mHelmetAni"] = aniVisible;
        nodesVisible["mHelmetGemNode"] = gemVisible;
        nodesVisible["mHelmetPoint"] = showNotice;

        if name == "mMainHand" then

            if EFUNSHOWNEWBIE() then
                --[[                --TODO： 新手引导  点击出现选择装备界面
                if (Newbie.step ~= 0 and (Newbie.step == Newbie.getIdByTag("newbie_MainEquip_ClickAdd") or
                        Newbie.step == Newbie.getIdByTag("newbie_MainEquip_AddShow")) ) then

--                       Newbie.show(Newbie.getIdByTag("newbie_MainEquip_AddShow"))

                   nodesVisible["mMainHandHintNode"] = true
                else
                   nodesVisible["mMainHandHintNode"] = false
                end]]
            else

                if UserInfo.roleInfo.level == 2 or showNotice == false then
                    nodesVisible["mMainHandHintNode"] = showNotice;
                end

            end

        end

        NodeHelper:addEquipAni(childNode, "mHelmetAni", aniVisible, nil, userEquip);
        NodeHelper:setStringForLabel(childNode, lb2Str);
        NodeHelper:setSpriteImage(childNode, sprite2Img, scaleMap);
        NodeHelper:setNodesVisible(childNode, nodesVisible);
        NodeHelper:setColorForLabel(childNode, colorMap)
    end


end
function ViewPlayerLeadPage:onReceiveMessage(ParentContainer)
    local message = ParentContainer:getMessage()
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;
        if opcode == HP_pb.ROLE_INFO_SYNC_S or opcode == HP_pb.EQUIP_INFO_SYNC_S then
            if UserEquipManager:hasInited() then
                self:refreshPage(selfContainer);
            end
        end
    elseif typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        if pageName == thisPageName and UserEquipManager:hasInited() then
            self:refreshPage(selfContainer);
        end
    end
end
function ViewPlayerLeadPage:getPacketInfo()

end
function ViewPlayerLeadPage:onExecute(ParentContainer)

end

function ViewPlayerLeadPage:getActivityInfo()

end
function ViewPlayerLeadPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.ROLE_CARRY_SKILL_S then
        self:showSkillInfo();
    end
end

function ViewPlayerLeadPage:removePacket(ParentContainer)

end

function ViewPlayerLeadPage:onExit(ParentContainer)

end

return ViewPlayerLeadPage

