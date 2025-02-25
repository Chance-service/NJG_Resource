local HP_pb = require("HP_pb")-- 包含协议id文件
local StarSoul_pb = require("StarSoul_pb")
local UserInfo = require("PlayerInfo.UserInfo");
local UserItemManager = require("Item.UserItemManager");
local thisPageName = "LeaderSubPage_SoulStar"
local starSoulCfg = ConfigManager.getLeaderSoulCfg()-- 星魂配置
local attrCfg = ConfigManager.getAttrPureCfg()-- 判断属性是显示数值还是百分比
local curGroup = 1 -- 当前星魂页
local nextStarId = nil
local btnCCBs = {}
local mainContainer = nil
local curItemEnough = true
local isPlayAni = false
local isMaxLevel = false
local isPlayCloseAni = false
local _AnimationCCB = nil
local parentPage = nil
local effectSpineParent = nil    -- 特效spine父節點
local effectSpine = nil  -- 特效spine
----这里是协议的id
local opcodes = {
    --SYNC_STAR_SOUL_S = HP_pb.SYNC_STAR_SOUL_S,
    SYNC_LEADER_SOUL_S = HP_pb.SYNC_LEADER_SOUL_S,
    ACTIVE_LEADER_SOUL_S=HP_pb.ACTIVE_LEADER_SOUL_S,
    -- 返回星魂信息
    --ACTIVE_STAR_SOUL_S = HP_pb.ACTIVE_STAR_SOUL_S -- 激活星魂返回信息
}

local option = {
    ccbiFile = "SoulStarPage.ccbi",
    handlerMap =
    {
        -- 按钮点击事件
        onReturnBtn = "closeAni",
        onImmediatelyDekaron = "onImmediatelyDekaron",
        onStatus = "onStatus",
        
        onSoulStar1 = "onSoulStar1",
        onSoulStar2 = "onSoulStar2",
        onSoulStar3 = "onSoulStar3",
        onSoulStar4 = "onSoulStar4",
        onSoulStar5 = "onSoulStar5",
        onSoulStar6 = "onSoulStar6",

        onHelp="onHelp"
    
    },
    opcode = opcodes
}
local ItemIcon={
      [1]="I_5003.png",
      [2]="I_5004.png",
      [3]="I_5005.png",
      [4]="I_5006.png",
      [5]="I_5007.png",
      [6]="I_5008.png",      
}

local SoulStarPageBase = {}
local SoulStarBtn = {}
local btmContainer = nil -- 底框container
function SoulStarPageBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function SoulStarPageBase:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)
    
    return container
end
function SoulStarPageBase:onEnter(container)
    self.container = container
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    isPlayAni = false
    isPlayCloseAni = false
    mainContainer = container
    curGroup = 1
    SoulStarPageBase:sendSyncStarSoul()
    btmContainer = container
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["SoulStarPage"] = container
    if GuideManager.IsNeedShowPage then
        GuideManager.IsNeedShowPage = false
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    local bg=container:getVarSprite("mBG")
    bg:setScale(NodeHelper:getScaleProportion())
    
    ---- 添加升级动画
    --local node = container:getVarNode("mAnimationNode")
    --NodeHelper:setNodesVisible(container, {mAnimationNode = false})
    --if node then
    --    _AnimationCCB = ScriptContentBase:create("eff_YangChengSuo_03.ccbi")
    --    if _AnimationCCB then
    --        node:addChild(_AnimationCCB)
    --        _AnimationCCB:registerFunctionHandler(AnimationFunction)
    --    end
    --end
    self:onSoulStar1(container)
    --self:showRoleSpine(container)
    self:initSpine(container)
end

-- 建立升級特效spine
function SoulStarPageBase:initSpine(container)
    effectSpine = SpineContainer:create("Spine/NGUI", "NGUI_64_LeaderUpgrade")
    local spineNode = tolua.cast(effectSpine, "CCNode")
    spineNode:setScale(NodeHelper:getScaleProportion())
    effectSpineParent = container:getVarNode("mAnimationNode")
    effectSpineParent:removeAllChildrenWithCleanup(true)
    effectSpineParent:addChild(spineNode)
end
--- 添加主角Spine动画
function SoulStarPageBase:showRoleSpine(container)
    --local roleId = UserInfo.roleInfo.itemId;
    --local heroNode = container:getVarNode("mSpine")
    --if heroNode then
    --    heroNode:removeAllChildren()
    --    local spine = SpineContainer:create("Spine/King", roleId)
    --    local spineNode = tolua.cast(spine, "CCNode")
    --    heroNode:addChild(spineNode)
    --    spine:runAnimation(1, "animation", -1)
    --end
end

function SoulStarPageBase:getAttr(id)--抓圖/數值
    local cfg = starSoulCfg[id]
    local attrValue = {}
    local attrName = {}
    local attrValueNum = {}
    local attrIcon = {}
    for i = 1, #cfg["attrs"] do
        local attr = common:split(cfg["attrs"][i], "_")
        attrName[i] = common:getLanguageString("@AttrName_" .. attr[1])
        attrIcon[i] = "attri_" .. attr[1] .. ".png"
        local attrId = tonumber(attr[1])
        attrValue[i] = tonumber(attr[2])
        attrValueNum[i] = attr[2]
        if attrCfg[attrId] and tonumber(attrCfg[attrId]["attrType"]) == 1 then
            attrValue[i] = (tonumber(attr[2]) / 100)
        end
    end
    
    return attrName, attrValue, attrValueNum, attrIcon
end

function SoulStarPageBase:onRefreshPage(container, id, isActive)
    local cfg = starSoulCfg[id]
    local lb2StrStuff = {}
    local lb2StrColor = {}
    local sp2AttrIcon = {}
    local VisableMap = {}
    local tmpIndex=0
    if starSoulCfg[id].level==0 then
        tmpIndex=id+1
    else 
        tmpIndex=id
    end
    local hasCount1 = UserItemManager:getCountByItemId(starSoulCfg[tmpIndex].costItems[1].itemId)
    local hasCount2 = UserInfo.playerInfo.gold
    local attrName, attrValue, a, attrIcon = self:getAttr(id)
    local nextAttrName, nextAttrValue, b, attrIcon = self:getAttr(id + 1)
    lb2StrStuff["mSoulLevelNum"] = tostring(cfg.level) .. "/" .. ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.starSoulLevelLimit].level
    lb2StrStuff["mCostText3"] = hasCount1
    lb2StrStuff["mReo"] = GameUtil:formatDotNumber(hasCount2)
     for i = 1, 4 do
        VisableMap["mAttriOriginName" .. i] = false
        VisableMap["mAttriOrigin" .. i] = false
        VisableMap["mAttriNextName" .. i] = false
        VisableMap["mAttriNext" .. i] = false
        VisableMap["mAttriOriginSprite" .. i] = false
        VisableMap["mAttriNextSprite" .. i] = false
    end
    
    curItemEnough = true
    nextStarId = id + 1
    if isActive then
        if _AnimationCCB then
            NodeHelper:setNodesVisible(container, {mAnimationNode = true})
            _AnimationCCB:runAnimation("SoulStarLevelUpAni")
        end
    end
    
    NodeHelper:setMenuItemEnabled(container, "mMidBtn", true)
    
    if cfg.level == ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.starSoulLevelLimit].level then -- 最后一级
        lb2StrStuff["mCostText2"] = ""
        -- "x"..cfg.costItems[1].count
        for i = 1, #attrName do
            --lb2StrStuff["mMaxAttriName" .. i] = attrName[i]
            lb2StrStuff["mAttriNext" .. i] = "+" .. attrValue[i]
        end
        self:changeSoulStarType(container)
        NodeHelper:setStringForLabel(container, lb2StrStuff)
        --NodeHelper:setStringForLabel(btmContainer, lb2StrStuff)
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
        })
        
        NodeHelper:setMenuItemEnabled(container, "mMidBtn", false)
        isMaxLevel = true
        NodeHelper:setNodesVisible(btmContainer, {mDoubleAttNode = false, mLevelMaxNode = true})
        return
    end
    --文字顏色/數值
    local nextCfg = starSoulCfg[id + 1]
    lb2StrStuff["mCostText2"] = nextCfg.costItems[1].count
    
    --处理道具不足 颜色显示
    if hasCount1 < nextCfg.costItems[1].count then
        lb2StrColor["mCostText3"] = "255 0 23"
        curItemEnough = false
    else
        lb2StrColor["mCostText3"] = "65 43 35"
    end
    NodeHelper:setNodesVisible(btmContainer, {mDoubleAttNode = true, mLevelMaxNode = false})

    if cfg.level == 0 then
        --- 第一级特殊处理为0
        local attrName, attrValue, a, attrIcon = self:getAttr(nextStarId)
        
        for i = 1, #attrName do
            lb2StrStuff["mAttriOriginName" .. i] = attrName[i]
            lb2StrStuff["mAttriOrigin" .. i] = "+" .. 0
            lb2StrStuff["mAttriNextName" .. i] = attrName[i]
            lb2StrStuff["mAttriNext" .. i] = "+" .. attrValue[i]
            VisableMap["mAttriOriginName" .. i] = true
            VisableMap["mAttriOrigin" .. i] = true
            VisableMap["mAttriNextName" .. i] = true
            VisableMap["mAttriNext" .. i] = true
        end
        for i = 1, #attrName do
            sp2AttrIcon["mAttriOriginSprite" .. i] = attrIcon[i]
            sp2AttrIcon["mAttriNextSprite" .. i] = attrIcon[i]
            VisableMap["mAttriOriginSprite" .. i] = true
            VisableMap["mAttriNextSprite" .. i] = true
        end
        NodeHelper:setNodesVisible(container, {
            mNew = false,
            mLastBack = true,
            mLastOne = true,
            mImmediatelyBtn = true,
            mMidGrey = true,
            mMidLight = false,
            mStandLightIcon = false,
            mLastRight = true,
        })
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
        })
        if cfg.level == 1 and isActive then
            NodeHelper:setNodesVisible(container, {mNew = false})
        end
        
        ----------升級前後的數值--------------
        for i = 1, #attrName do
             local temp = nextAttrValue[i] - attrValue[i]
             lb2StrStuff["mAttriOriginName" .. i] = attrName[i]
             lb2StrStuff["mAttriOrigin" .. i] = attrValue[i]
             lb2StrStuff["mAttriNextName" .. i] = attrName[i]
             lb2StrStuff["mAttriNext" .. i] =nextAttrValue[i] .. " (+" .. temp .. ")"
             VisableMap["mAttriOriginName" .. i] = true
             VisableMap["mAttriOrigin" .. i] = true
             VisableMap["mAttriNextName" .. i] = true
             VisableMap["mAttriNext" .. i] = true
             VisableMap["mAttriOriginSprite" .. i] = true
            VisableMap["mAttriNextSprite" .. i] = true
        end
    ----------------------------------------
    --Icon設定
     for i = 1, #attrName do
           sp2AttrIcon["mAttriOriginSprite" .. i] = attrIcon[i]
           sp2AttrIcon["mAttriNextSprite" .. i] = attrIcon[i]
     end
    end
    
    self:changeSoulStarType(container)
    NodeHelper:setNodesVisible(container,VisableMap)
    NodeHelper:setStringForLabel(container, lb2StrStuff)
    NodeHelper:setStringForLabel(btmContainer, lb2StrStuff)
    NodeHelper:setSpriteImage(container, sp2AttrIcon)
    NodeHelper:setColorForLabel(container, lb2StrColor)
    NodeHelper:setColorForLabel(btmContainer, lb2StrColor)

    -- 紅點
    local isShow, group = SoulStarPageBase_calIsShowRedPoint(id)
    RedPointManager_setShowRedPoint(thisPageName, group, isShow)
    RedPointManager_setOptionData(thisPageName, group, { id = id })
    SoulStarPageBase_setRedPoint()
end

function SoulStarPageBase:changeSoulStarType(container)
    local imgName =ItemIcon[curGroup]
    NodeHelper:setSpriteImage(container, {mIcon = imgName, mIconColour2 = imgName})
end

function SoulStarPageBase:onExecute(container)
    --NodeHelper:setStringForLabel(container, {mReo = GameUtil:formatDotNumber(UserInfo.playerInfo.gold)})
end

function SoulStarPageBase:onExit(container)
    parentPage:removePacket(opcodes)
    for i = 1, 6 do
        local childNode = btnCCBs[i]
    end
    btnCCBs = {}
    mainContainer = nil
end
function SoulStarPageBase:onExecute(container)

end

function SoulStarPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_SOULSTAR);
end

function SoulStarPageBase:closeAni(container)
    PageManager.changePage("EquipLeadPage")
end

function AnimationFunction(eventName, container)
    if eventName == "luaOnAnimationDone" then
        local animationName = tostring(container:getCurAnimationDoneName())
        if animationName == "SoulStarLevelUpAni" then
            NodeHelper:setNodesVisible(container, {mAnimationNode = false})
            isPlayAni = false
        end
    
    end
end

function SoulStarPageBase:onStatus(container)
    local PlayerAttributePage = require("PlayerAttributePage")
    PlayerAttributePage:setRoleInfo(UserInfo.roleInfo);
    PageManager.pushPage("PlayerAttributePage")
end

function SoulStarPageBase:onAnimationDone(container)
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
            NodeHelper:setNodesVisible(container, {mStandLightIcon = true, mLastRight = false, mMidGrey = true})
        else
            NodeHelper:setMenuItemEnabled(container, "mMidBtn", true)
        end
        NodeHelper:setNodesVisible(container, {mNew = true})
        isPlayAni = false
    elseif animationName == "ChangeStar" then
        container:runAnimation("Stand")
    end
end

function SoulStarPageBase:onClose(container)
    EquipPageBase_playSoulStarCloseAni(true)
    EquipLeadPage_playSoulStarCloseAni(true)
    PageManager.setAllNotice()
    PageManager.changePage("EquipmentPage")
end

function SoulStarPageBase:onReceivePacket(packet)--資料取得
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.SYNC_LEADER_SOUL_S then
        isMaxLevel = false
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        self:onRefreshPage(self.container, id)
        return
    elseif opcode == HP_pb.ACTIVE_LEADER_SOUL_S then
        effectSpine:runAnimation(1, "animation", 0)
        isMaxLevel = false
        local msg = StarSoul_pb.ActiveStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        self:onRefreshPage(self.container, id, true)
        return
    end
end

--[[這裡好像沒用到了
function SoulStarPageBase:onReceiveMessage(container)
local message = container:getMessage();
local typeId = message:getTypeId();
if typeId == MSG_SEVERINFO_UPDATE then
-- 这里有好多消息类型
local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;

if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then end
end
end
]]
function SoulStarPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function SoulStarPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end

-- 请求同步
function SoulStarPageBase:sendSyncStarSoul()
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.SyncStarSoul()
    msg.group = curGroup
    common:sendPacket(HP_pb.SYNC_LEADER_SOUL_C, msg, false)
end

-- 激活星魂
function SoulStarPageBase:sendActiveStarSoul(id)
    if not curItemEnough then
        local str = Language:getInstance():getString("@SoulNotEnoughTxt")
        MessageBoxPage:Msg_Box(str)
        return
    end
    -- 正在播放动画
    if isPlayAni then
        return
    end
    --isPlayAni = true
    NodeHelper:setMenuItemEnabled(mainContainer, "mMidBtn", false)
    
    
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.ActiveStarSoul()
    msg.id = id
    common:sendPacket(HP_pb.ACTIVE_LEADER_SOUL_C, msg, false)
end
-- 新手引导用
function SoulStarPageBase_sendActiveStarSoul()
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
    --isPlayAni = true
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.ActiveStarSoul()
    msg.id = id
    common:sendPacket(HP_pb.ACTIVE_STAR_SOUL_C, msg, false)
end

function SoulStarPageBase:onImmediatelyDekaron(container)--Train按鈕
    self:sendActiveStarSoul(nextStarId)
end

function SoulStarPageBase:onSoulStar1(container)
    self:onSoulStar(container, 1)
end

function SoulStarPageBase:onSoulStar2(container)
    self:onSoulStar(container, 2)
end

function SoulStarPageBase:onSoulStar3(container)
    self:onSoulStar(container, 3)
end

function SoulStarPageBase:onSoulStar4(container)
    self:onSoulStar(container, 4)
end

function SoulStarPageBase:onSoulStar5(container)
    self:onSoulStar(container, 5)
end

function SoulStarPageBase:onSoulStar6(container)
    self:onSoulStar(container, 6)
end

function SoulStarPageBase:onSoulStar(container, groupId)
    for i = 1, 6 do
        NodeHelper:setMenuItemEnabled(mainContainer, "mSoulStarBtn" .. i, not (groupId == i))
        NodeHelper:setNodesVisible(container, {["mSelectBtn_" .. i] = groupId == i})
    end
    
    curGroup = groupId
    SoulStarPageBase:sendSyncStarSoul()

end

function SoulStarPageBase_setRedPoint()
    require("Util.RedPointManager")
    for i = 1, 6 do
        if mainContainer then
            NodeHelper:setNodesVisible(mainContainer, {["mPoint" .. i] = RedPointManager_getShowRedPoint(thisPageName, i)})
        end
    end
end

function SoulStarPageBase_calIsShowRedPoint(id)
    if not id then
        return false, 1
    end
    local cfg = starSoulCfg[id]
    local group = math.ceil((id + 1) / 201)--starSoulCfg[id].group

    local curItemEnough = true
    local nextStarId = id + 1
    -- 消耗
    local cost = starSoulCfg[nextStarId].costItems[1].count
    local hasCount = 0
    if starSoulCfg[nextStarId].costItems[1].type == 30000 then
        hasCount = UserItemManager:getCountByItemId(starSoulCfg[nextStarId].costItems[1].itemId)
    end
    if hasCount < cost then
        curItemEnough = false
    else
        curItemEnough = true
    end
    return curItemEnough, group
end

return SoulStarPageBase
