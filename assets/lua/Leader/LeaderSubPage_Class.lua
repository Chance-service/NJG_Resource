local HP_pb = require("HP_pb")-- 包含协议id文件
local StarSoul_pb = require("StarSoul_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local UserItemManager = require("Item.UserItemManager")
local LeaderDataMgr = require("Leader.LeaderDataMgr")
local thisPageName = "LeaderSubPage_Class"
local starSoulCfg = ConfigManager.getClassSoulCfg()-- 星魂配置
local attrCfg = ConfigManager.getAttrPureCfg()-- 判断属性是显示数值还是百分比
local curGroup = 1 -- 当前星魂页
local nextStarId = nil
local mainContainer = nil
local curItemEnough = true
local isMaxLevel = false
local parentPage = nil
local effectSpineParent = nil    -- 特效spine父節點
local effectSpine = nil  -- 特效spine
----这里是协议的id
local opcodes = {
    SYNC_CLASS_SOUL_S = HP_pb.SYNC_CLASS_SOUL_S,
    ACTIVE_CLASS_SOUL_S = HP_pb.ACTIVE_CLASS_SOUL_S,
}

local option = {
    ccbiFile = "SoulStarPage_Class.ccbi",
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

        onHelp = "onHelp"
    
    },
    opcode = opcodes
}
local ItemIcon = {
    [1] = "I_5010.png",
    [2] = "I_5011.png",
    [3] = "I_5012.png",
    [4] = "I_5013.png",
}
local TitleKey = {
    [1] = "@leadertank",
    [2] = "@leadersward",
    [3] = "@leaderheal",
    [4] = "@leadermagic",
}

local ClassStarPageBase = { }
function ClassStarPageBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function ClassStarPageBase:createPage(_parentPage)
    
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
function ClassStarPageBase:onEnter(container)
    self.container = container
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    mainContainer = container
    curGroup = 1
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["SoulStarPage_Class"] = container
    if GuideManager.IsNeedShowPage then
        GuideManager.IsNeedShowPage = false
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    self.subPageCfg = LeaderDataMgr:getSubPageCfg(self.subPageName)

    --if self.subPageCfg.saveData and self.subPageCfg.saveData[curGroup] then
    --    self:onRefreshPage(self.container, self.subPageCfg.saveData[curGroup])
    --else
        self:onRefreshPage(self.container, 0)
    --end
    self:onSoulStar1(container)
    self:initSpine(container)

    -- 紅點
    parentPage:registerMessage(MSG_REFRESH_REDPOINT)
    self:refreshAllPoint(container)
end

function ClassStarPageBase:onExecute(container)

end

-- 建立升級特效spine
function ClassStarPageBase:initSpine(container)
    effectSpine = SpineContainer:create("Spine/NGUI", "NGUI_64_LeaderUpgrade")
    local spineNode = tolua.cast(effectSpine, "CCNode")
    spineNode:setScale(NodeHelper:getScaleProportion())
    effectSpineParent = container:getVarNode("mAnimationNode")
    effectSpineParent:removeAllChildrenWithCleanup(true)
    effectSpineParent:addChild(spineNode)
    effectSpine:runAnimation(1, curGroup .. "_wait", -1)
end

function ClassStarPageBase:getAttr(id)--抓圖/數值
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

function ClassStarPageBase:onRefreshPage(container, id, isActive)
    local cfg = starSoulCfg[id]
    local lb2StrStuff = { }
    local lb2StrColor = { }
    local sp2AttrIcon = { }
    local VisableMap = { }
    local tmpIndex = 0
    if starSoulCfg[id].level == 0 then
        tmpIndex = id + 1
    else 
        tmpIndex = id
    end
    local hasCount1 = UserItemManager:getCountByItemId(starSoulCfg[tmpIndex].costItems[1].itemId)
    local hasCount2 = UserInfo.playerInfo.gold
    local attrName, attrValue, a, attrIcon = self:getAttr(id)
    local nextAttrName, nextAttrValue, b, attrIcon = self:getAttr(id + 1)
    lb2StrStuff["mSoulLevelNum"] = tostring(cfg.level) .. "/" .. ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.starSoulLevelLimit].level
    lb2StrStuff["mCostText3"] = hasCount1
    lb2StrStuff["mReo"] = GameUtil:formatDotNumber(hasCount2)
    lb2StrStuff["mAttrTitle"] = common:getLanguageString("@leadertitle", common:getLanguageString(TitleKey[curGroup]))
     for i = 1, 2 do
        VisableMap["mAttriOriginName" .. i] = false
        VisableMap["mAttriOrigin" .. i] = false
        VisableMap["mAttriOriginSprite" .. i] = false
        VisableMap["mAttrPlus" .. i] = false
        VisableMap["mMaxAttriName" .. i] = false
        VisableMap["mMaxAttribute" .. i] = false
        VisableMap["mMaxAttriSprite" .. i] = false
    end
    
    curItemEnough = true
    nextStarId = id + 1
    
    NodeHelper:setMenuItemEnabled(container, "mMidBtn", true)
    
    if cfg.level == ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.starSoulLevelLimit].level then -- 最后一级
        lb2StrStuff["mCostText2"] = "-"
        for i = 1, #attrName do
            lb2StrStuff["mMaxAttriName" .. i] = attrName[i]
            lb2StrStuff["mMaxAttribute" .. i] = "+" .. attrValue[i]
            sp2AttrIcon["mMaxAttriSprite" .. i] = attrIcon[i]
            VisableMap["mMaxAttriName" .. i] = true
            VisableMap["mMaxAttribute" .. i] = true
        end
        self:changeSoulStarType(container)
        NodeHelper:setStringForLabel(container, lb2StrStuff)
        
        NodeHelper:setMenuItemEnabled(container, "mMidBtn", false)
        isMaxLevel = true
        NodeHelper:setNodesVisible(container, { mDoubleAttNode = false, mLevelMaxNode = true })
        
    else
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
        NodeHelper:setNodesVisible(container, {mDoubleAttNode = true, mLevelMaxNode = false})

        if cfg.level == 0 then
            --- 第一级特殊处理为0
            local attrName, attrValue, a, attrIcon = self:getAttr(nextStarId)
            
            for i = 1, #attrName do
                lb2StrStuff["mAttriOriginName" .. i] = attrName[i]
                lb2StrStuff["mAttriOrigin" .. i] = "+" .. 0
                lb2StrStuff["mAttrPlus" .. i] = "(+" .. nextAttrValue[i] .. ")"
                VisableMap["mAttriOriginName" .. i] = true
                VisableMap["mAttriOrigin" .. i] = true
                VisableMap["mAttriOriginSprite" .. i] = true
                sp2AttrIcon["mAttriOriginSprite" .. i] = attrIcon[i]
            end
        else
            -- 中间等级
            NodeHelper:setNodesVisible(container, {
                mImmediatelyBtn = true,
            })
            if cfg.level == 1 and isActive then
                NodeHelper:setNodesVisible(container, {mNew = false})
            end
            
            ----------升級前後的數值--------------
            for i = 1, #attrName do
                local temp = nextAttrValue[i] - attrValue[i]
                lb2StrStuff["mAttriOriginName" .. i] = attrName[i]
                lb2StrStuff["mAttriOrigin" .. i] = "+" .. attrValue[i]
                lb2StrStuff["mAttrPlus" .. i] = "(+" .. temp .. ")"
                VisableMap["mAttriOriginName" .. i] = true
                VisableMap["mAttriOrigin" .. i] = true
                VisableMap["mAttriOriginSprite" .. i] = true
                --Icon設定
                sp2AttrIcon["mAttriOriginSprite" .. i] = attrIcon[i]
            end
        end
        
        self:changeSoulStarType(container)
        NodeHelper:setNodesVisible(container,VisableMap)
        NodeHelper:setStringForLabel(container, lb2StrStuff)
        NodeHelper:setSpriteImage(container, sp2AttrIcon)
        NodeHelper:setColorForLabel(container, lb2StrColor)
    end
end

function ClassStarPageBase:changeSoulStarType(container)
    local imgName = ItemIcon[curGroup]
    NodeHelper:setSpriteImage(container, { mIcon = imgName, mIconColour2 = imgName })
end

function ClassStarPageBase:onExit(container)
    parentPage:removePacket(opcodes)
    mainContainer = nil
end

function ClassStarPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_LEADER_CLASS)
end

function ClassStarPageBase:closeAni(container)
    PageManager.changePage("EquipLeadPage")
end

function ClassStarPageBase:onStatus(container)
    local PlayerAttributePage = require("PlayerAttributePage")
    PlayerAttributePage:setRoleInfo(UserInfo.roleInfo)
    PageManager.pushPage("PlayerAttributePage")
end

function ClassStarPageBase:onClose(container)
    EquipPageBase_playSoulStarCloseAni(true)
    EquipLeadPage_playSoulStarCloseAni(true)
    PageManager.setAllNotice()
    PageManager.changePage("EquipmentPage")
end

function ClassStarPageBase:onReceivePacket(packet)--資料取得
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.SYNC_CLASS_SOUL_S then
        isMaxLevel = false
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        self:onRefreshPage(self.container, id)

        --self.subPageCfg.saveData = self.subPageCfg.saveData or { }
        --self.subPageCfg.saveData[curGroup] = id
        return
    elseif opcode == HP_pb.ACTIVE_CLASS_SOUL_S then
        effectSpine:runAnimation(1, curGroup .. "_play", 0)
        effectSpine:addAnimation(1, curGroup .. "_wait", true)
        isMaxLevel = false
        local msg = StarSoul_pb.ActiveStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        self:onRefreshPage(self.container, id, true)

        --self.subPageCfg.saveData = self.subPageCfg.saveData or { }
        --self.subPageCfg.saveData[curGroup] = id

        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.GRAIL_CLASS_BTN
        RedPointManager_refreshPageShowPoint(pageId, nil, id)
        return
    end
end

function ClassStarPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ClassStarPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

-- 请求同步
function ClassStarPageBase:sendSyncStarSoul()
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.SyncStarSoul()
    msg.group = curGroup
    common:sendPacket(HP_pb.SYNC_CLASS_SOUL_C, msg, false)
end

-- 激活星魂
function ClassStarPageBase:sendActiveStarSoul(id)
    if not curItemEnough then
        local str = Language:getInstance():getString("@SoulNotEnoughTxt")
        MessageBoxPage:Msg_Box(str)
        return
    end
    NodeHelper:setMenuItemEnabled(mainContainer, "mMidBtn", false)
    
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.ActiveStarSoul()
    msg.id = id
    common:sendPacket(HP_pb.ACTIVE_CLASS_SOUL_C, msg, false)
end
-- 新手引导用
function ClassStarPageBase_sendActiveStarSoul()
    id = nextStarId
    if not curItemEnough then
        local str = Language:getInstance():getString("@SoulNotEnoughTxt")
        MessageBoxPage:Msg_Box(str)
        return
    end

    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.ActiveStarSoul()
    msg.id = id
    common:sendPacket(HP_pb.ACTIVE_CLASS_SOUL_C, msg, false)
end

function ClassStarPageBase:onImmediatelyDekaron(container)--Train按鈕
    self:sendActiveStarSoul(nextStarId)
end

function ClassStarPageBase:onSoulStar1(container)
    self:onSoulStar(container, 1)
end

function ClassStarPageBase:onSoulStar2(container)
    self:onSoulStar(container, 2)
end

function ClassStarPageBase:onSoulStar3(container)
    self:onSoulStar(container, 3)
end

function ClassStarPageBase:onSoulStar4(container)
    self:onSoulStar(container, 4)
end

function ClassStarPageBase:onSoulStar(container, groupId)
    for i = 1, 4 do
        NodeHelper:setMenuItemEnabled(mainContainer, "mSoulStarBtn" .. i, not (groupId == i))
    end
    
    curGroup = groupId
    ClassStarPageBase:sendSyncStarSoul()
    if effectSpine then
        effectSpine:runAnimation(1, curGroup .. "_wait", -1)
    end
end

function ClassStarPageBase:refreshAllPoint(container)
    require("Util.RedPointManager")
    for i = 1, 4 do
        NodeHelper:setNodesVisible(container, {["mPoint" .. i] = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.GRAIL_CLASS_BTN, i)})
    end
end

function ClassStarPageBase:onReceiveMessage(message)
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(mainContainer)
    end
end

function ClassStarPageBase_calIsShowRedPoint(id)
    if not id then
        return false, 1
    end
    local cfg = starSoulCfg[id]
    local group = math.ceil((id + 1) / 201)--starSoulCfg[id].group

    local curItemEnough = true
    local nextStarId = id + 1
    local nextGroup = math.ceil((nextStarId + 1) / 201)
    if group ~= nextGroup then
        return false, group
    end
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

return ClassStarPageBase
