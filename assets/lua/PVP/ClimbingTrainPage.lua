
local HP_pb = require("HP_pb") -- 包含协议id文件
local StarSoul_pb = require("StarSoul_pb")
local UserInfo = require("PlayerInfo.UserInfo");
local UserItemManager = require("Item.UserItemManager");
local thisPageName = "ClimbingTrainPage"
local starSoulCfg = ConfigManager.getStarSoulCfg() -- 星魂配置
local attrCfg = ConfigManager.getAttrPureCfg() -- 判断属性是显示数值还是百分比
local curGroup = 1 -- 当前星魂页
local nextStarId = nil
local btnCCBs = { }
local mainContainer = nil
local curItemEnough = true
local isPlayAni = false
local isMaxLevel = false
local isPlayCloseAni = false
local _AnimationCCB = nil
----这里是协议的id
local opcodes = {
    SYNC_STAR_SOUL_S = HP_pb.SYNC_STAR_SOUL_S,
    -- 返回星魂信息
    ACTIVE_STAR_SOUL_S = HP_pb.ACTIVE_STAR_SOUL_S-- 激活星魂返回信息
}

local option = {
    ccbiFile = "ClimbingTrain.ccbi",
    handlerMap =
    {
        -- 按钮点击事件
        onReturnBtn = "closeAni",
        onImmediatelyDekaron = "onImmediatelyDekaron",
        onBtn1 = "onSoulStar1",
        onBtn2 = "onSoulStar2",

        onSoulStar1 = "onSoulStar1",
        onSoulStar2 = "onSoulStar2",
        onSoulStar3 = "onSoulStar3",
        onSoulStar4 = "onSoulStar4",
        onSoulStar5 = "onSoulStar5",
        onSoulStar6 = "onSoulStar6",
    },
    opcode = opcodes
}

-- local eventMap = { }
-- for i = 1, 6 do
--    eventMap["onSoulStar" .. i] = "onSoulStar" .. i
-- end

local ClimblingTrainPageBase = { }
local SoulStarBtn = { }
local btmContainer = nil -- 底框container

function ClimblingTrainPageBase:onEnter(container)
    isPlayAni = false
    isPlayCloseAni = false
    mainContainer = container
    -- NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"), 0.35)
    self:registerPacket(container)
    self:showRoleSpine(container)
    curGroup = 1
    self:onSoulStar(mainContainer, curGroup)
    -- self:sendSyncStarSoul()
    -- self:onRefreshPage(container, 1001)
    -- container:runAnimation("SoulStarOpen")
    -- container:runAnimation("Stand")

    --    for i = 1, 6 do
    --        local node = container:getVarNode("mCheckBox" .. i)
    --        local itemNode = ScriptContentBase:create("SoulStarBtn" .. i .. ".ccbi");
    --        itemNode:registerFunctionHandler(SoulStarBtn.onFunction)
    --        node:addChild(itemNode);
    --        if i == curGroup then
    --            itemNode:runAnimation("SoulStarTouchBegin")
    --        end
    --        btnCCBs[i] = itemNode
    --    end

    -- local childNode = container:getVarMenuItemCCB("mBtmInfoNode")
    -- childNode = childNode:getCCBFile()
    -- btmContainer = childNode
    btmContainer = container
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["SoulStarPage"] = container
    if GuideManager.IsNeedShowPage then
        GuideManager.IsNeedShowPage = false
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    -- NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mImmediatelyBtn"), 0.35)
    -- local node = container:getVarNode("mBtmLoadNode")
    -- local itemNode = ScriptContentBase:create('SoulStarBtmAni.ccbi');
    -- itemNode:registerFunctionHandler(SoulStarBtn.onFunction)
    -- node:addChild(itemNode);
    -- local node = container:getVarNode("mNodeBtn1")
    -- local itemNode = ScriptContentBase:create('SoulStarBtn1.ccbi');
    -- node:addChild(itemNode);
    -- itemNode:registerFunctionHandler(ClimblingTrainPageBase.onFunction)

    -- 添加升级动画
    local node = container:getVarNode("mAnimationNode")
    NodeHelper:setNodesVisible(container, { mAnimationNode = false })
    if node then
        _AnimationCCB = ScriptContentBase:create("eff_YangChengSuo_03.ccbi")
        if _AnimationCCB then
            node:addChild(_AnimationCCB)
            _AnimationCCB:registerFunctionHandler(AnimationFunction)
        end
    end
end

function SoulStarBtn.onFunction(eventName, container)
    if eventName == "onSoulStar1" then
        SoulStarBtn:onSoulStar1(container)
    elseif eventName == "onSoulStar2" then
        SoulStarBtn:onSoulStar2(container)
    elseif eventName == "onSoulStar3" then
        SoulStarBtn:onSoulStar3(container)
    elseif eventName == "onSoulStar4" then
        SoulStarBtn:onSoulStar4(container)
    elseif eventName == "onSoulStar5" then
        SoulStarBtn:onSoulStar5(container)
    elseif eventName == "onSoulStar6" then
        SoulStarBtn:onSoulStar6(container)
    end
end

--- 添加主角Spine动画
function ClimblingTrainPageBase:showRoleSpine(container)
    local roleId = UserInfo.roleInfo.itemId;
    local roleData = ConfigManager.getRoleCfg()[roleId]
    local heroNode = container:getVarNode("mSpine")
    if heroNode and heroNode:getChildByTag(10010) == nil then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width, height = visibleSize.width, visibleSize.height
        local rate = visibleSize.height / visibleSize.width
        local desighRate = 1280 / 720
        rate = rate / desighRate
        heroNode:removeAllChildren()
        local spine = nil
        local showCfg = LeaderAvatarManager.getCurShowCfg()
        spine = SpineContainer:create(unpack(showCfg.spine[UserInfo.roleInfo.prof]))

        local spineNode = tolua.cast(spine, "CCNode")

        local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
        NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        spineNode:setScale(roleData.spineScale)
        -- spineNode:setTag(10010)
        heroNode:addChild(spineNode)
        -- heroNode:setScale(rate)
        spine:runAnimation(1, "Stand", -1)

        local bgScale = NodeHelper:getAdjustBgScale(0)
        if bgScale < 1 then bgScale = 1 end

        NodeHelper:setSpriteImage(container, { mRoleBG = "BG/SoulStar/SoulStar_Bg_" .. roleData.profession .. ".png" }, { mRoleBG = bgScale })




    end
end

function ClimblingTrainPageBase:getAttr(id)
    local cfg = starSoulCfg[id]
    local attrValue = { }
    local attrName = { }
    local attrValueNum = { }
    for i = 1, #cfg["attrs"] do
        local attr = common:split(cfg["attrs"][i], "_")
        attrName[i] = common:getLanguageString("@AttrName_" .. attr[1])
        local attrId = tonumber(attr[1])
        attrValue[i] = attr[2]
        attrValueNum[i] = attr[2]
        if attrCfg[attrId] and tonumber(attrCfg[attrId]["attrType"]) == 1 then
            attrValue[i] =(tonumber(attr[2]) / 100) .. "%"
        end
    end

    return attrName, attrValue, attrValueNum
end

function ClimblingTrainPageBase:onRefreshPage(container, id, isActive)
    local cfg = starSoulCfg[id]
    local lb2StrStuff = { }
    local lb2StrColor = { }
    nextStarId = id + 1

    if isActive then
        if _AnimationCCB then
             NodeHelper:setNodesVisible(container, { mAnimationNode = true })
            _AnimationCCB:runAnimation("SoulStarLevelUpAni")
        end
    end

    NodeHelper:setMenuItemEnabled(container, "mMidBtn", true)

    if cfg.level == 100 then
        -- 最后一级  or cfg.level == 21
        lb2StrStuff["mCostText"] = ""
        -- "x"..cfg.costItems[1].count
        lb2StrStuff["mSoulLevelNum"] = tostring(cfg.level) .. "/" .. "100"
        local hasCount1 = UserItemManager:getCountByItemId(cfg.costItems[1].itemId);
        lb2StrStuff["mGold"] = hasCount1
        local attrName, attrValue = self:getAttr(id)
        local nextAttrName, nextAttrValue = self:getAttr(id + 1)
        -- CCLuaLog("###attrName = "..tostring(#attrName))

        for i = 1, 3 do
            -- lb2StrStuff["mMaxAttribute" .. i] = ""
            -- lb2StrStuff["mAttribute" .. i] = ""
            if i <= #attrName then
                -- lb2StrStuff["mMaxAttribute" .. i] = attrName[i] .. "+" .. attrValue[i]
                -- lb2StrStuff["mAttribute" .. i] = attrName[i] .. "+" .. attrValue[i]
            end
        end

        local currentAttrStr = ""
        local nextAttrStr = ""
        for i = 1, #attrName do
            if i ~= #attrName then
                currentAttrStr = currentAttrStr .. attrName[i] .. "+" .. attrValue[i] .. "\n"
                nextAttrStr = nextAttrStr .. attrName[i] .. "+" .. attrValue[i] .. "\n"
            else
                currentAttrStr = currentAttrStr .. attrName[i] .. "+" .. attrValue[i]
                nextAttrStr = nextAttrStr .. attrName[i] .. "+" .. attrValue[i]
            end
        end
        lb2StrStuff["mAttribute2"] = currentAttrStr
        lb2StrStuff["mMaxAttribute2"] = nextAttrStr
        lb2StrColor["mAttribute2"] = "255 84 0"
        lb2StrColor["mMaxAttribute2"] = "255 84 0"
        self:changeSoulStarType(container)
        NodeHelper:setStringForLabel(container, lb2StrStuff)
        NodeHelper:setStringForLabel(btmContainer, lb2StrStuff)
        NodeHelper:setNodesVisible(container, {
            mLastBack = false,
            mLastOne = false,
            mNew = true,
            mImmediatelyBtn = true,
            mMidGrey = false,
            mMidLight = false,
            mStandLightIcon = true,
            mLastRight = false,
            mIconColour = false
        } )
        -- mMidLight = true,

        NodeHelper:setMenuItemEnabled(container, "mMidBtn", false)
        isMaxLevel = true
        NodeHelper:setNodesVisible(btmContainer, { mDoubleAttNode = false, mLevelMaxNode = true })
        --        if isActive then
        --            NodeHelper:setNodesVisible(btmContainer, { mDoubleAttNode = true, mLevelMaxNode = false })
        --            NodeHelper:setNodesVisible(container, { mStandLightIcon = false, mLastRight = true, mMidGrey = true })
        --            isMaxLevel = true
        --            -- btmContainer:runAnimation("SoulStarUpMaxAni")
        --        else
        --            -- btmContainer:runAnimation("SoulStarNormal")
        --            NodeHelper:setNodesVisible(btmContainer, { mDoubleAttNode = false, mLevelMaxNode = true })
        --        end
        return
    end

    local nextCfg = starSoulCfg[id + 1]
    lb2StrStuff["mSoulLevelNum"] = tostring(cfg.level) .. "/" .. "100"

    if nextCfg.costItems[1].count <= 0 then
        lb2StrStuff["mCostText"] = common:getLanguageString("@SuitShootFree1Text")
    else
        lb2StrStuff["mCostText"] = "x" .. nextCfg.costItems[1].count
    end


    local hasCount1 = UserItemManager:getCountByItemId(nextCfg.costItems[1].itemId);
    lb2StrStuff["mGold"] = hasCount1
    --- 处理道具不足 颜色显示
    curItemEnough = true
    lb2StrColor["mCostText"] = "255 56 209"
    if hasCount1 < nextCfg.costItems[1].count then
        lb2StrColor["mCostText"] = "255 0 23"
        curItemEnough = false
    end
    NodeHelper:setNodesVisible(btmContainer, { mDoubleAttNode = true, mLevelMaxNode = false })
    -- btmContainer:runAnimation("SoulStarNormal")


    -- NodeHelper:setMenuItemEnabled( container, "mMidBtn", true )
    if cfg.level == 0 then
        --- 第一级特殊处理为0
        local attrName, attrValue = self:getAttr(nextStarId)


        for i = 1, 3 do
            -- lb2StrStuff["mAttribute" .. i] = ""
            -- lb2StrStuff["mNexAttribute" .. i] = ""
            if i <= #attrName then
                -- lb2StrStuff["mAttribute" .. i] = attrName[i] .. "+" .. 0
                -- lb2StrStuff["mNexAttribute" .. i] = attrName[i] .. "+" .. attrValue[i]
                -- lb2StrColor["mAttribute" .. i] = "226 203 163"
                -- lb2StrColor["mNexAttribute" .. i] = "4 234 101"
            else
                -- lb2StrStuff["mAttribute" .. i] = ""
                -- lb2StrStuff["mNexAttribute" .. i] = ""
            end
        end

        local currentAttrStr = ""
        local nextAttrStr = ""
        for i = 1, #attrName do
            if i ~= #attrName then
                currentAttrStr = currentAttrStr .. attrName[i] .. "+" .. 0 .. "\n"
                nextAttrStr = nextAttrStr .. attrName[i] .. "+" .. attrValue[i] .. "\n"
            else
                currentAttrStr = currentAttrStr .. attrName[i] .. "+" .. 0
                nextAttrStr = nextAttrStr .. attrName[i] .. "+" .. attrValue[i]
            end
        end
        lb2StrStuff["mAttribute2"] = currentAttrStr
        lb2StrStuff["mNexAttribute2"] = nextAttrStr
        lb2StrColor["mAttribute2"] = "255 84 0"
        lb2StrColor["mNexAttribute2"] = "255 0 23"

        NodeHelper:setNodesVisible(container, {
            mNew = false,
            mLastBack = true,
            mLastOne = true,
            mImmediatelyBtn = true,
            mMidGrey = true,
            mMidLight = false,
            mStandLightIcon = false,
            mLastRight = true,
            mIconColour = true
        } )
    else
        -- 中间等级
        NodeHelper:setNodesVisible(container, {
            mNew = true,
            mLastBack = true,
            mLastOne = true,
            mImmediatelyBtn = true,
            mMidGrey = true,
            mMidLight = false,
            mStandLightIcon = false,
            mLastRight = true,
            mIconColour = true
        } )
        if cfg.level == 1 and isActive then
            NodeHelper:setNodesVisible(container, { mNew = false })
        end

        local attrName, attrValue, attrValueNum = self:getAttr(id)
        local nextAttrName, nextAttrValue, nextValueNum = self:getAttr(id + 1)
        -- CCLuaLog("###attrName = "..tostring(#attrName))

        for i = 1, 3 do
            -- lb2StrStuff["mAttribute" .. i] = ""
            -- lb2StrStuff["mNexAttribute" .. i] = ""
            if i <= #attrName then
                -- lb2StrStuff["mAttribute" .. i] = attrName[i] .. "+" .. attrValue[i]
                -- lb2StrStuff["mNexAttribute" .. i] = nextAttrName[i] .. "+" .. nextAttrValue[i]
                -- lb2StrColor["mAttribute" .. i] = "226 203 163"
                -- lb2StrColor["mNexAttribute" .. i] = "226 203 163"
                if tonumber(nextValueNum[i]) > tonumber(attrValueNum[i]) then
                    -- lb2StrColor["mNexAttribute" .. i] = "4 234 101"
                end
            else
                -- lb2StrStuff["mAttribute" .. i] = ""
                -- lb2StrStuff["mNexAttribute" .. i] = ""
            end
        end


        local currentAttrStr = ""
        local nextAttrStr = ""
        for i = 1, #attrName do
            if i ~= #attrName then
                currentAttrStr = currentAttrStr .. attrName[i] .. "+" .. attrValue[i] .. "\n"
                nextAttrStr = nextAttrStr .. nextAttrName[i] .. "+" .. nextAttrValue[i] .. "\n"
            else
                currentAttrStr = currentAttrStr .. attrName[i] .. "+" .. attrValue[i]
                nextAttrStr = nextAttrStr .. nextAttrName[i] .. "+" .. nextAttrValue[i]
            end
        end
        lb2StrStuff["mAttribute2"] = currentAttrStr
        lb2StrStuff["mNexAttribute2"] = nextAttrStr
        lb2StrColor["mAttribute2"] = "255 84 0"
        lb2StrColor["mNexAttribute2"] = "255 0 23"
    end

    self:changeSoulStarType(container)
    NodeHelper:setStringForLabel(container, lb2StrStuff)
    NodeHelper:setStringForLabel(btmContainer, lb2StrStuff)
    NodeHelper:setColorForLabel(container, lb2StrColor)
    NodeHelper:setColorForLabel(btmContainer, lb2StrColor)
end

function ClimblingTrainPageBase:changeSoulStarType(container)
    local imgName = "UI/Common/Image/Image_SoulIcon_" .. tostring(curGroup) .. ".png"
    NodeHelper:setSpriteImage(container, { mIcon = imgName, mIconColour = imgName })
end

function ClimblingTrainPageBase:onExecute(container)

end

function ClimblingTrainPageBase:onExit(container)
    self:removePacket(container)
    for i = 1, 6 do
        local childNode = btnCCBs[i]
        -- childNode:unregisterFunctionHandler()
    end
    btnCCBs = { }
    mainContainer = nil
end

function ClimblingTrainPageBase:closeAni(container)
    PageManager.changePage("EquipmentPage")
    --    if isPlayCloseAni then
    --        return
    --    end
    --    isPlayCloseAni = true
    --    container:runAnimation("SoulStarClose")
end

function AnimationFunction(eventName, container)
    if eventName == "luaOnAnimationDone" then
        local animationName = tostring(container:getCurAnimationDoneName())
        if animationName == "SoulStarLevelUpAni" then
            -- NodeHelper:setMenuItemEnabled(container, "mMidBtn", true)
            NodeHelper:setNodesVisible(container, { mAnimationNode = false })
            isPlayAni = false
        end

    end
end

function ClimblingTrainPageBase:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "SoulStarClose" then
        self:onClose(container)
    elseif animationName == "SoulStarOpen" then
        container:runAnimation("Stand")
    elseif animationName == "Activate" then
        container:runAnimation("Rotation")
    elseif animationName == "Rotation" then
        container:runAnimation("Stand")
        if isMaxLevel then
            -- 最大等级兼容动画做的处理
            NodeHelper:setNodesVisible(container, { mStandLightIcon = true, mLastRight = false, mMidGrey = true })
        else
            NodeHelper:setMenuItemEnabled(container, "mMidBtn", true)
        end
        NodeHelper:setNodesVisible(container, { mNew = true })
        isPlayAni = false
    elseif animationName == "ChangeStar" then
        container:runAnimation("Stand")
    end
end

function ClimblingTrainPageBase:onClose(container)
    EquipPageBase_playSoulStarCloseAni(true)
    EquipLeadPage_playSoulStarCloseAni(true)
    PageManager.setAllNotice()
    PageManager.changePage("EquipmentPage")
    -- PageManager.changePage("MainScenePage")
    -- PageManager.pushPage("PlayerInfoPage")
end

function ClimblingTrainPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.SYNC_STAR_SOUL_S then
        isMaxLevel = false
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        -- 当前id
        self:onRefreshPage(container, id)
        -- self:rebuildItem(container)
        return
    elseif opcode == HP_pb.ACTIVE_STAR_SOUL_S then
        isMaxLevel = false
        local msg = StarSoul_pb.ActiveStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        -- 当前id
        self:onRefreshPage(container, id, true)
        return
    end
end

function ClimblingTrainPageBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then
        -- 这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;

        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then

        end
    end
end

function ClimblingTrainPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ClimblingTrainPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

-- 请求同步
function ClimblingTrainPageBase:sendSyncStarSoul()
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.SyncStarSoul()
    msg.group = curGroup
    common:sendPacket(HP_pb.SYNC_STAR_SOUL_C, msg, false)
end

-- 激活星魂
function ClimblingTrainPageBase:sendActiveStarSoul(id)
    if not curItemEnough then
        local str = Language:getInstance():getString("@SoulNotEnoughTxt")
        MessageBoxPage:Msg_Box(str)
        return
    end
    -- 正在播放动画
    if isPlayAni then
        return
    end
    isPlayAni = true
    NodeHelper:setMenuItemEnabled(mainContainer, "mMidBtn", false)
    -- mainContainer:runAnimation("Activate")
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.ActiveStarSoul()
    msg.id = id
    common:sendPacket(HP_pb.ACTIVE_STAR_SOUL_C, msg, false)
end
-- 新手引导用
function ClimblingTrainPageBase_sendActiveStarSoul()
    id = nextStarId
    if not curItemEnough then
        local str = Language:getInstance():getString("@SoulNotEnoughTxt")
        MessageBoxPage:Msg_Box(str)
        return
    end
    -- 正在播放动画
    if isPlayAni or id == nil then
        return
    end
    isPlayAni = true
    -- mainContainer:runAnimation("Activate")
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.ActiveStarSoul()
    msg.id = id
    common:sendPacket(HP_pb.ACTIVE_STAR_SOUL_C, msg, false)
end

function ClimblingTrainPageBase:onImmediatelyDekaron(container)
    self:sendActiveStarSoul(nextStarId)
end

function ClimblingTrainPageBase:onSoulStar1(container)
    self:onSoulStar(container, 1)
end

function ClimblingTrainPageBase:onSoulStar2(container)
    self:onSoulStar(container, 2)
end

function ClimblingTrainPageBase:onSoulStar3(container)
    self:onSoulStar(container, 3)
end

function ClimblingTrainPageBase:onSoulStar4(container)
    self:onSoulStar(container, 4)
end

function ClimblingTrainPageBase:onSoulStar5(container)
    self:onSoulStar(container, 5)
end

function ClimblingTrainPageBase:onSoulStar6(container)
    self:onSoulStar(container, 6)
end

function ClimblingTrainPageBase:onSoulStar(container, groupId)

    for i = 1, 6 do
        NodeHelper:setMenuItemEnabled(mainContainer, "mSoulStarBtn" .. i, not(groupId == i))
        NodeHelper:setNodesVisible(container, { ["mSelectBtn_" .. i] = groupId == i })
    end
    curGroup = groupId
    --    btnCCBs[groupId]:runAnimation("SoulStarTouchBegin")
    --    for i = 1, 6 do
    --        if groupId ~= i then
    --            btnCCBs[i]:runAnimation("SoulStarNormal")
    --        end
    --    end
    --    mainContainer:runAnimation("ChangeStar")
    ClimblingTrainPageBase:sendSyncStarSoul()

end

function ClimblingTrainPageBase_setRedPoint(marks)
    --    for i = 1, 6 do
    --        if btnCCBs[i] then
    --            NodeHelper:setNodesVisible(btnCCBs[i], { ["mPoint" .. i] = marks[i] })
    --        end
    --    end

    for i = 1, 6 do
        if mainContainer then
            NodeHelper:setNodesVisible(mainContainer, { ["mPoint" .. i] = marks[i] })
        end
    end

end

local CommonPage = require('CommonPage')
local SoulStarPage = CommonPage.newSub(ClimblingTrainPageBase, thisPageName, option)