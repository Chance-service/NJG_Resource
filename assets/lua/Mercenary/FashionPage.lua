local thisPageName = "FashionPage"
local FetterManager = require("FetterManager")
local UserInfo = require("PlayerInfo.UserInfo")
local RoleOpr_pb = require("RoleOpr_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local MercenaryTouchSoundManager = require("MercenaryTouchSoundManager")
local SkillManager = require("Skill.SkillManager")
local FashionPageBase = {
}

local option = {
    ccbiFile = "FashionPage.ccbi",
    handlerMap =
    {
        onReturnBtn = "onClose",
        onSkill = "onSkill",
        onHelp = "onHelp",
        onChange = "onChange",
        onWeapon = "onWeapon"
    },
    opcodes =
    {
        ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
        ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
        ROLE_EMPLOY_C = HP_pb.ROLE_EMPLOY_C,
        ROLE_EMPLOY_S = HP_pb.ROLE_EMPLOY_S,
        ROLE_CHANGE_SKIN_C = HP_pb.ROLE_CHANGE_SKIN_C,
        ROLE_CHANGE_SKIN_S = HP_pb.ROLE_CHANGE_SKIN_S,

    }
}
local _closeFunc = nil
local roleCfg = { }
local _curMercenaryInfo = { }
local FashionInfos = { }
local selecetIndex = 1
local FashionStatusInfos = { }
local CurContainer = nil
local spriteColor = { "23 213 254", "197 23 254", "252 254 114", "255 51 51" }

-- local spriteColor = { ccc3(0x34, 0xbe, 0xff), ccc3(0xdc, 0x84, 0xff), ccc3(0xff, 0xe2, 0x56), ccc3(0xff, 0x5a, 0x64) }

local originPos = nil

function FashionContent_onFunction(eventName, container)
    print("eventName ", eventName)
    if eventName == "luaOnAnimationDone" then

    elseif eventName == "onContentBtn" then
        local index = container.index
        if index then
            FashionPageBase:SwitchIndex(index)
        end
    end
end

function FashionPageBase:SwitchIndex(index)
    if selecetIndex == index then
        return
    end
    local statusInfo = FashionStatusInfos[index]
    print("statusInfo.roleStage = ", statusInfo.roleStage)
    if statusInfo and statusInfo.roleStage == 2 then
        local msg = RoleOpr_pb.HPRoleEmploy()
        msg.roleId = FashionStatusInfos[index].roleId
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.ROLE_EMPLOY_C, pb, #pb, true)
        return
    end
    local node = CurContainer:getVarNode("mContent_" .. selecetIndex)
    if node then
        local head = node:getChildByTag(10086)
        if head then
            head:runAnimation("close")
        end
    end
    node = CurContainer:getVarNode("mContent_" .. index)
    if node then
        local head = node:getChildByTag(10086)
        if head then
            head:runAnimation("open")
        end
    end
    selecetIndex = index
    FashionPageBase:refreshSelect(CurContainer)
end

-- function FashionPageBase:onHand(container,eventName)
--     print("FashionPageBase:onHand(container,eventName)")
--     local index = tonumber(string.sub(eventName,13,string.len(eventName)))
--     if selecetIndex == index then return end

--     if node then
--         local head = node:getChildByTag(10086)
--         if head then
--             head:runAnimation("close")
--         end
--     end
--     node = container:getVarNode("mContent_"..index)
--     if node then
--         local head = node:getChildByTag(10086)
--         if head then
--             head:runAnimation("open")
--         end
--     end
--     selecetIndex = index
--     FashionPageBase:refreshSelect( container )
-- end

function FashionPageBase:refreshSelect(container)
    -- local roleInfo = FashionInfos[selecetIndex]
    local statusInfo = FashionStatusInfos[selecetIndex]
    local itemId = statusInfo.itemId
    local visibleMap = { }
    visibleMap.mChangeBtn = itemId ~= _curMercenaryInfo.itemId
    visibleMap.mChangePic = itemId == _curMercenaryInfo.itemId
    NodeHelper:setMenuItemEnabled(container, "mChange", statusInfo.roleStage == 1)
    for i = 1, 3 do
        visibleMap["mCareer" .. i] = roleCfg[itemId].profession == i
    end
    NodeHelper:setNodesVisible(container, visibleMap)

    local heroNode = container:getVarNode("mSpineNode")
    local heroNodeParent = container:getVarNode("mSpineParent")
    local heroNodeBack = container:getVarNode("mSpineBGNode")
    if heroNode then
        local roleData = ConfigManager.getRoleCfg()[itemId]
        NodeHelper:setSpriteImage(container, { mBG = roleData.bgImg })
        local spinePath, spineName, animCCbi = unpack(common:split((roleData.spine), ","))
        spine = SpineContainer:create(spinePath, spineName)
        local spineNode = tolua.cast(spine, "CCNode")
        heroNodeBack:removeAllChildren()
        heroNode:removeAllChildren()
        if statusInfo.roleStage == 0 then
            NodeHelper:initGraySpineSprite(heroNodeBack, spine, heroNode, roleData)
        else
            heroNode:addChild(spineNode)
            spine:runAnimation(1, "Stand", -1)
            --MercenaryTouchSoundManager:initTouchButton(container, itemId)
            local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
            NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
            spineNode:setScale(roleData.spineScale)
        end
        -- TODO需要在适配一个缩放和偏移
    end

    FashionPageBase:refreshSkill(container)

    FashionPageBase:refreshWeaponNode(container)
end

function FashionPageBase:refreshWeaponNode(container)

    local statusInfo = FashionStatusInfos[selecetIndex]
    local itemId = statusInfo.itemId
    local suitInfo = EquipManager:getMercenaryOnlySuitByMercenaryId(itemId)
    --local suitInfo = EquipManager:getMercenarySuitByMercenaryId(_curMercenaryInfo.itemId)
    if suitInfo then
        NodeHelper:setNodesVisible(container, { mWeaponNode = true })
        local equipInfo = EquipManager:getEquipCfgById(suitInfo[1].equipId)
        NodeHelper:setStringForLabel(container, { mEquipName = equipInfo.name })
    else
        NodeHelper:setNodesVisible(container, { mWeaponNode = false })
    end
end

function FashionPageBase:refreshPage(container)

    --self:refreshWeaponNode(container)
    --    local suitInfo = EquipManager:getMercenarySuitByMercenaryId(_curMercenaryInfo.itemId)
    --    if suitInfo then
    --        NodeHelper:setNodesVisible(container, {mWeaponNode = true})
    --        local equipInfo = EquipManager:getEquipCfgById(suitInfo.equipId)
    --        NodeHelper:setStringForLabel(container, { mEquipName = equipInfo.name })
    --    else
    --       NodeHelper:setNodesVisible(container, {mWeaponNode = false})
    --    end

    local itemId = _curMercenaryInfo.itemId
    if roleCfg[itemId].modelId ~= 0 and roleCfg[roleCfg[itemId].modelId] then
        itemId = roleCfg[itemId].modelId
    end
    NodeHelper:setSpriteImage(container, { mNamePic = roleCfg[itemId].namePic })

    FashionPageBase:refreshSelect(container)
    local visibleMap = { }
    local node, head, statusInfo, colorSprite, cfgInfo
    for i, v in ipairs(FashionStatusInfos) do
        cfgInfo = roleCfg[v.itemId]
        if cfgInfo then
            node = container:getVarNode("mContent_" .. i)
            node:setVisible(true)
            head = ScriptContentBase:create("FashionContent.ccbi")
            head:setTag(10086)
            head:registerFunctionHandler(FashionContent_onFunction)
            head.index = i
            node:addChild(head)
            colorSprite = head:getVarSprite("mFrontColor")
            -- 设置背景
            local skinItemImgeData = ConfigManager.parseCfgWithComma(cfgInfo.avataBgPic)
            -- , mName = "Fashion_Font_" .. v.itemId .. ".png",
            NodeHelper:setSpriteImage(head, { mRoleBG = skinItemImgeData[1], mRole = skinItemImgeData[2] })

            local name = cfgInfo.avatarName

            --if name == "0" then
                NodeHelper:setStringForLabel(head, { mNameText_1 = "", mNameText_2 = cfgInfo.name })
                --NodeHelper:setStringForLabel(head, { mNameText_1 = cfgInfo.name, mNameText_2 = "" })
            --else
            --    NodeHelper:setStringForLabel(head, { mNameText_1 = cfgInfo.avatarName, mNameText_2 = cfgInfo.name })
            --end

            if colorSprite then
                local color = NodeHelper:_getColorFromSetting(spriteColor[cfgInfo.quality - 2])
                colorSprite:setColor(color)
                -- colorSprite:setColor(spriteColor[cfgInfo.quality - 2])
            end
            for i = 1, 4 do
                visibleMap["mQualityPic" .. i] = cfgInfo.quality - 2 == i
                visibleMap["mColor_" .. i] = cfgInfo.quality - 2 == i
            end
            statusInfo = FashionStatusInfos[i]
            if statusInfo then
                visibleMap.mIconNode = statusInfo.roleStage ~= 1
                visibleMap.mPoint = statusInfo.roleStage == 2
                if statusInfo.roleStage ~= 1 then
                    NodeHelper:setStringForLabel(head, { mIconNum = statusInfo.soulCount .. "/" .. statusInfo.costSoulCount })
                end
            end
            NodeHelper:setNodesVisible(head, visibleMap)
            if v.roleId == _curMercenaryInfo.roleId then
                head:runAnimation("choice")
            end
        end
    end
    container:runAnimation("open")
end

function FashionPageBase:refreshSkill(container)
    local roleInfo = FashionStatusInfos[selecetIndex]
    local _normalSkill = SkillManager:getMerAllSkillByRoleId(roleInfo.itemId)
    -- 获取本佣兵 ring.txt表内的 被动技能
    local _passiveSkill = SkillManager:getMerPassiveSkillByRoleId(roleInfo.itemId)
    local sprite2Img = { }
    local lb2Str = { }
    local visibleMap = { }

    for i = 1, 2 do
        if _normalSkill[i] then
            visibleMap["mSkillNode" .. i] = true
            sprite2Img["mSkill" .. i] = _normalSkill[i].icon
            lb2Str["mSkillName" .. i] = _normalSkill[i].name
        else
            visibleMap["mSkillNode" .. i] = false
        end
    end
    for i = 1, 2 do
        if _passiveSkill[i] then
            visibleMap["mSkillNode" ..(i + 2)] = true
            sprite2Img["mSkill" ..(i + 2)] = _passiveSkill[i].icon
            lb2Str["mSkillName" ..(i + 2)] = _passiveSkill[i].name
        else
            visibleMap["mSkillNode" ..(i + 2)] = false
        end
    end
    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img)
end

function FashionPageBase:onEnter(container)
    CurContainer = container
    roleCfg = ConfigManager.getRoleCfg()
    self:registerPacket(container)

    local heroNode = container:getVarNode("mSpineNode")
    local x, y = heroNode:getPosition()
    originPos = ccp(x, y)

    local scale = NodeHelper:getAdjustBgScale(0)
    if scale >= 1 then
        local sp = container:getVarSprite("mBG")
        sp:setScale(scale)
    end

    if #UserMercenaryManager:getMercenaryStatusInfos() == 0 then
        self:getMercenaryStatus()
    else
        self:getFashionInfos()
        self:refreshPage(container)
    end
end

function FashionPageBase:getMercenaryStatus()
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
end

function FashionPageBase:getFashionInfos()
    local itemId = _curMercenaryInfo.itemId
    if itemId and roleCfg[itemId] then
        local modelId = itemId
        if roleCfg[itemId].modelId ~= 0 then
            modelId = roleCfg[itemId].modelId
        end
        if roleCfg[modelId].FashionInfos then
            FashionInfos = { }
            for i, v in ipairs(roleCfg[modelId].FashionInfos) do
                FashionInfos[i] = v
            end
        else
            FashionInfos = { modelId }
        end
    end
    for i, itemId in ipairs(FashionInfos) do
        if itemId == _curMercenaryInfo.itemId then
            selecetIndex = i
        end
        -- FashionInfos[i] = UserMercenaryManager:getUserMercenaryByItemId(itemId)
        FashionStatusInfos[i] = UserMercenaryManager:getMercenaryStatusByItemId(itemId)
    end

    -- table.sort( FashionInfos, function ( left, right )

    -- end )

end

function FashionPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_AVATAR)
end

function FashionPageBase:onExecute(container)
end

function FashionPageBase:onExit(container)
    CurContainer = nil
    FashionInfos = { }
    selecetIndex = 1
    originPos = nil
    self:removePacket(container)
    local heroNode = container:getVarNode("mSpineNode")
    if heroNode then
        heroNode:removeAllChildren()
    end
end

function FashionPageBase:onWeapon(container)

    local statusInfo = FashionStatusInfos[selecetIndex]
    local itemId = statusInfo.itemId
    local suitInfo = EquipManager:getMercenaryOnlySuitByMercenaryId(itemId)

--    local fetterId = FetterManager.getViewFetterId()
--    local data = FetterManager.getIllCfgById(fetterId)
    --local suitInfo = EquipManager:getMercenaryAllSuitByMercenaryId(data.roleId)
    if suitInfo == nil then
        -- 这个角色没有专属武器
        return
    end
    
    local fetterId =FetterManager.getFetterIdByRoleId(itemId)
    FetterManager.setViewFetterId(fetterId)
    local MercenarySpecialEquipPage = require("MercenarySpecialEquipPage")
    --MercenarySpecialEquipPage_setRoleId(itemId)
    PageManager.pushPage("MercenarySpecialEquipPage")
end

function FashionPageBase:onClose(container)
    if _closeFunc ~= nil then
        _closeFunc()
    else
        EquipPageBase_selectMercenary(_curMercenaryInfo.roleId)
        PageManager.changePage("EquipmentPage")
    end
end

function FashionPageBase:onSkill(container)
    if FashionStatusInfos[selecetIndex] then
        local MercenarySkillPreviewPage = require("MercenarySkillPreviewPage")
        local curMercenary = UserMercenaryManager:getUserMercenaryById(FashionStatusInfos[selecetIndex].roleId)
        if FashionStatusInfos[selecetIndex].itemId > 0 and not curMercenary then
            curMercenary = {
                itemId = FashionStatusInfos[selecetIndex].itemId,
                skills = { },
                ringId = { }
            }
        end
        MercenarySkillPreviewPage:setMercenaryInfo(curMercenary);
        PageManager.pushPage("MercenarySkillPreviewPage");
    end
end

function FashionPageBase:onChange(container)
    local msg = RoleOpr_pb.HPChangeMercenarySkinReq()
    msg.fromRoleId = _curMercenaryInfo.roleId
    msg.toRoleId = FashionStatusInfos[selecetIndex].roleId
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.ROLE_CHANGE_SKIN_C, pb, #pb, true)
end


function FashionPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        UserMercenaryManager:setMercenaryStatusInfos(msg.roleInfos)
        self:getFashionInfos()
        self:refreshPage(container)
    elseif opcode == HP_pb.ROLE_CHANGE_SKIN_S then
        local msg = RoleOpr_pb.HPChangeMercenarySkinRes();
        msg:ParseFromString(msgBuff);
        for i, v in ipairs(FashionStatusInfos) do
            if v.roleId == msg.toRoleId then
                _curMercenaryInfo = v
                break;
            end
        end
        FashionPageBase:refreshSelect(container)
        UserEquipManager:updateMercenaryRedPointNotice(_curMercenaryInfo.roleId)
        --self:refreshWeaponNode(container)
    elseif opcode == HP_pb.ROLE_EMPLOY_S then
        local msg = RoleOpr_pb.HPRoleEmploy();
        msg:ParseFromString(msgBuff);
        -- FashionStatusInfos[msg.roleId].roleStage = 1
        local index = 1
        for i, v in ipairs(FashionStatusInfos) do
            if v.roleId == msg.roleId then
                index = i
                v.roleStage = 1;
                break;
            end
        end

        local node = CurContainer:getVarNode("mContent_" .. index)
        if node then
            local head = node:getChildByTag(10086)
            if head then
                NodeHelper:setNodesVisible(head, { mIconNode = false, mPoint = false })
            end
        end
        FashionPageBase:SwitchIndex(index)
        UserEquipManager:checkAllEquipNotice()
    end
end

function FashionPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
    end
end


function FashionPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end



-- function FashionPageBase:onAnimationDone( container )
-- end

function FashionPageBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function FashionPageBase_setCurMercenaryInfo(mercenaryInfo, closeFunc)
    _curMercenaryInfo = mercenaryInfo
    _closeFunc = closeFunc
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local FashionPage = CommonPage.newSub(FashionPageBase, thisPageName, option);