----------------------------------------------------------------------------------
-- 美人计
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'LuckyMercenaryPage'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local MercenaryTouchSoundManager = require("MercenaryTouchSoundManager")
local LuckyMercenaryPage = { }

local LuckyMercenaryCfg = { }
local LuckyMercenaryBuffCfg = { }
local MercenaryCfg = { }

local PageInfo = {
    leftTime = 0,
    isTodayRewardGot = false,
    isLuckyMercenaryUser = false,
    roleInfos = { },
    timerName = "LuckyMercenaryPage",
}

local opcodes = {
    LUCK_MERCENARY_S = HP_pb.LUCK_MERCENARY_S,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
}

function LuckyMercenaryPage.onFunction(eventName, container)
    if eventName == "onCall" then
        LuckyMercenaryPage:onCall(container)
    end
end

function LuckyMercenaryPage:onEnter(ParentContainer)
    local container = ScriptContentBase:create("Act_TimeLimitLuckyMercenaryContent.ccbi")
    self.container = container

    local s9Bg = container:getVarScale9Sprite("mS9_1")
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)

    local scale = NodeHelper:getScaleProportion()
    local mSpriteNode = container:getVarSprite("mSpriteNode")
    if scale <= 1 then
        scale = scale - scale % 0.1
        mSpriteNode:setScale(scale)
    end
    NodeHelper:autoAdjustResetNodePosition(mSpriteNode, 0.5)

    self.container:registerFunctionHandler(LuckyMercenaryPage.onFunction)
    self:registerPacket(ParentContainer)
    self:getActivityInfo()

    -- NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    NodeHelper:setNodesVisible(container, { mMercenaryInfoTxt = true })
    NodeHelper:setStringForLabel(container, { mMercenaryInfoTxt = common:getLanguageString('@luckyBuffSpecia1Txt1') })
    LuckyMercenaryCfg = ConfigManager.getLuckyMercenaryCfg()
    LuckyMercenaryBuffCfg = ConfigManager.getLuckyMercenaryBuffCfg()
    MercenaryCfg = ConfigManager.getRoleCfg()

    --NodeHelper:setMenuItemEnabled(container , "mCallBtn" , false)
    NodeHelper:setNodeIsGray(container, { mBtnLabel = true })
    NodeHelper:setStringForLabel(container, { mBtnLabel = common:getLanguageString("@UrMeirenjiBtn1") })
    -- 已有副将

    NodeHelper:setNodesVisible(container, { mBtnCallNode = false, mHave = false, mNotHave = false })
    return self.container
end


function LuckyMercenaryPage:onCall(container)
    if PageInfo == nil or PageInfo.luckMercenaryItem == nil then
        return
    end

    local activityId = LuckyMercenaryCfg[PageInfo.luckMercenaryItem.mercenaryID].activityId
    for i, v in ipairs(ActivityInfo.allIds) do
        if activityId == v then
            local ActivityManager = require("Activity/ActivityManager")
            if ActivityManager.getActivityType() == ActivityType.Limit then
                LimitActivityPage_setPart(activityId)
                PageManager.refreshPage("LimitActivityPage", "changeActivity")
            elseif ActivityManager.getActivityType() == ActivityType.Gashapon then
                if activityId == 94 or activityId == 95 then
                    require("WelfarePage")
                    WelfarePage_setPart(activityId)
                    PageManager.pushPage("WelfarePage")
                else
                    GashaponPage_setPart(activityId)
                    PageManager.refreshPage("GashaponPage", "changeActivity")
                end
            end
            return
        end
    end
    MessageBoxPage:Msg_Box_Lan("@CurrentActivityIsClosed")
end


function LuckyMercenaryPage:getActivityInfo()
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    common:sendEmptyPacket(HP_pb.LUCK_MERCENARY_C, true)
end

function LuckyMercenaryPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == HP_pb.LUCK_MERCENARY_S then
        local msg = Activity2_pb.HPLuckyMercenaryInfoRet()
        msg:ParseFromString(msgBuff)
        PageInfo.leftTime = msg.leftTime
        if PageInfo.leftTime == -1 then
            PageInfo.leftTime = 0
        end
        PageInfo.luckMercenaryItem = msg.luckMercenaryItem[1]
        self:refreshPage(self.container);
        return
    end
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        PageInfo.roleInfos = msg.roleInfos
        if PageInfo.leftTime > 0 then
            self:refreshPage(self.container);
        end
        return
    end

end
function LuckyMercenaryPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function LuckyMercenaryPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function LuckyMercenaryPage:onExit(ParentContainer)
    -- local timerName = ExpeditionDataHelper.getPageTimerName()
    local spineNode = self.container:getVarNode("mSpine");
    if spineNode then
        spineNode:removeAllChildren();
    end
    PageInfo.leftTime = 0
    TimeCalculator:getInstance():removeTimeCalcultor(PageInfo.timerName)
    self:removePacket(ParentContainer)
    onUnload(thisPageName, self.container)
end

function LuckyMercenaryPage:refreshPage()
    local timerName = PageInfo.timerName
    local remainTime = PageInfo.leftTime
    local container = self.container
    if remainTime > 0 and not TimeCalculator:getInstance():hasKey(timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(timerName, remainTime);
    end
    local name = MercenaryCfg[PageInfo.luckMercenaryItem.mercenaryID].name
    local UserMercenaryManager = require("UserMercenaryManager")
    local MercenaryInfos = UserMercenaryManager:getUserMercenaryByItemId(PageInfo.luckMercenaryItem.mercenaryID)
    local hasRole = false
    if MercenaryInfos and MercenaryInfos.roleId then
        for i, v in ipairs(PageInfo.roleInfos) do
            if v.roleId == MercenaryInfos.roleId then
                hasRole = v.roleStage == 1
                break
            end
        end
    end

    -- NodeHelper:setMenuItemEnabled(container , "mCallBtn" , not hasRole)
    -- NodeHelper:setNodeIsGray(container, {mBtnLabel = hasRole} )
    NodeHelper:setNodesVisible(container, { mBtnCallNode = not hasRole, mNotHave = not hasRole, mHave = hasRole })
    if hasRole then
        NodeHelper:setStringForLabel(container, { mBtnLabel = common:getLanguageString("@UrMeirenjiBtn2") })
        -- 已有副将
    else
        NodeHelper:setStringForLabel(container, { mBtnLabel = common:getLanguageString("@UrMeirenjiBtn1") })
        -- 条件确认
    end

    -- NodeHelper:setNodesVisible(container, {mBtnCallNode = not hasRole, mClose = hasRole})
    -- NodeHelper:setMenuItemEnabled(container,"mCallBtn",not hasRole)

    CCLuaLog("PageInfo.luckMercenaryItem.mercenaryID:" .. tostring(PageInfo.luckMercenaryItem.mercenaryID))

    -- NodeHelper:setSpriteImage(container,{mNamePic = LuckyMercenaryCfg[PageInfo.luckMercenaryItem.mercenaryID].namePic})

    -- local speekLabel = container:getVarLabelTTF("mSpeakTxt")
    -- speekLabel:setAlignment(kCCTextAlignmentCenter)
    -- local str = GameMaths:stringAutoReturnForLua(common:getLanguageString("@LuckyMercenarySpeakTxt"),9,0)
    -- speekLabel:setString(str)

    local str = GameMaths:stringAutoReturnForLua(common:getLanguageString("@LuckyMercenaryInfoTxt", name), 25, 0)
    -- local act = container:getVarLabelBMFont("mActInfo")
    -- act:setAlignment(kCCTextAlignmentCenter)
    -- act:setString(str)

    ----------------------
    -- NodeHelper:setStringForLabel(container, {mActInfo = str})
    -- local buffInfo = self.container:getVarLabelBMFont("mActInfo")
    -- buffInfo:setString("")
    -- local str = FreeTypeConfig[100].content
    -- str = common:fill(str,name)
    -- NodeHelper:addHtmlLable(buffInfo, str ,10086, CCSize(300,32))

    local strTable = { mAtt1 = "", mAtt2 = "", mAtt3 = "" }
    for i, v in ipairs(PageInfo.luckMercenaryItem.id) do
        if LuckyMercenaryBuffCfg[v] and LuckyMercenaryBuffCfg[v].desc then
            strTable["mAtt" .. i] = i .. "、" .. common:getLanguageString(LuckyMercenaryBuffCfg[v].desc)
        end
    end

    NodeHelper:setStringForLabel(container, strTable)

    --    local spineNode = container:getVarNode("mSpine");
    --    local heroNodeParent = container:getVarNode("mSpineParent")

    --    local roldData = ConfigManager.getRoleCfg()[PageInfo.luckMercenaryItem.mercenaryID]
    --    local spinePath, spineName = unpack(common:split((roldData.spine), ","))

    --    if spineNode and roldData then
    --        spineNode:removeAllChildren()

    --         local spinePosOffset = "0,0"
    --         local spineScale = 0.95

    --        local spine = SpineContainer:create(spinePath, spineName);
    --        local spineToNode = tolua.cast(spine, "CCNode");
    --        heroNodeParent:setScale(spineScale)
    --        spineNode:addChild(spineToNode);
    --        spine:runAnimation(1, "Stand", -1);
    --        local offset_X_Str  , offset_Y_Str = unpack(common:split((spinePosOffset), ","))
    --        NodeHelper:setNodeOffset(spineToNode , tonumber(offset_X_Str) , tonumber(offset_Y_Str))
    --    end
    -- MercenaryTouchSoundManager:initTouchButton(container,PageInfo.luckMercenaryItem.mercenaryID)
end

function LuckyMercenaryPage:onExecute(ParentContainer)
    if TimeCalculator:getInstance():hasKey(PageInfo.timerName) then
        PageInfo.leftTime = TimeCalculator:getInstance():getTimeLeft(PageInfo.timerName)
        if PageInfo.leftTime > 0 then
            timeStr = common:second2DateString(PageInfo.leftTime, false)
        end
        if PageInfo.leftTime <= 0 then
            timeStr = common:getLanguageString("@ActivityEnd")
        end
        NodeHelper:setStringForLabel(self.container, { mCloseTime = common:getLanguageString("@LuckyMercenaryCloseTime", timeStr) })
    end
end

return LuckyMercenaryPage
