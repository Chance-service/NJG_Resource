registerScriptPage("LeaveMessageDetailPage")
local thisPageName = "HelpFightSelectRolePopUp"
local Mail_pb = require("Mail_pb")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local EighteenPrinces_pb = require "EighteenPrinces_pb"
local HelpFightDataManager = require("PVP.HelpFightDataManager")
local NodeHelper = require("NodeHelper")
local roleConfig = ConfigManager.getRoleCfg()
local NewbieGuideManager = require("NewbieGuideManager")

local UserInfo = require("PlayerInfo.UserInfo")
local opcodes =
{
    EIGHTEENPRINCES_HELP_LIST_S = HP_pb.EIGHTEENPRINCES_HELP_LIST_S,
    --EIGHTEENPRINCES_CHALLENGE_S = HP_pb.EIGHTEENPRINCES_CHALLENGE_S,
    EIGHTEENPRINCES_HELP_CHANGE_S = HP_pb.EIGHTEENPRINCES_HELP_CHANGE_S,
    EIGHTEENPRINCES_FORMATIONINFO_S = HP_pb.EIGHTEENPRINCES_FORMATIONINFO_S,

}

local option = {
    ccbiFile = "HelpFightSelectRolePopUp.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onClose = "onClose",
        onPurchaseTimes = "purchaseTimes",
        onConfirmSelect = "onConfirmSelect",    --选择协将
        onSkip = "onSkip", -- 跳过
        onChangeRoleSelect = "onChangeRoleSelect",
    },
    opcode = opcodes
}
local _surplusChallengeTimes = 0
local _arenaBuyTimesInitCost = ""
local _arenaAlreadyBuyTimes = nil
local _chanllengeContainer = nil
local _func = nil
local HelpFightSelectRolePopUp = { }
local myHelpFightListData = nil
local myChallengeData = nil

local curSelectIndex =  0
local lastSelectIndex = 0
local itemList = {}
-----------------------------------------------------------------
local SelectRoleItem = {}
local myContain = nil
local isBuy = false

function SelectRoleItem.onFunction(eventName, container)
   if eventName == "onRefreshContent" then
       SelectRoleItem:onRefreshContent(container)
    end
end

function SelectRoleItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    if container == nil then
        return
    end
    local index = self.id
    local isSecelct  = curSelectIndex == index
    local btn =  container:getVarMenuItem("mChocice")
    if isSecelct then
        btn:selected()
    else
        btn:unselected()
    end
    myHelpFightListData = myHelpFightListData or {}
    myHelpFightListData.infos = myHelpFightListData.infos or {}
    if myHelpFightListData.infos[index] then
        local libStr = {}
        libStr.mNameLabel = myHelpFightListData.infos[index].name
        libStr.mRoleLv = UserInfo.getOtherLevelStr( nil, myHelpFightListData.infos[index].level)
        libStr.mFightValue = common:getLanguageString("@FightingCapacity")  ..":"..myHelpFightListData.infos[index].fightValue
        if myHelpFightListData.infos[index].leftCount <= 5  then
            libStr.mLeftTimes = common:getLanguageString("@Eighteenbtncontent11")..myHelpFightListData.infos[index].leftCount
        else
            libStr.mLeftTimes = common:getLanguageString("@Eighteenbtncontent3",myHelpFightListData.infos[index].leftCount - 5)
        end
        NodeHelper:setStringForLabel(container, libStr)
        local icon = common:getPlayeIcon(1, myHelpFightListData.infos[index].roleItemId)
        NodeHelper:setSpriteImage(container, { mPic = icon},{mPic = 0.77})
        NodeHelper:setQualityFrames(container, {mEnemyFeet = roleConfig[myHelpFightListData.infos[index].roleItemId].quality});
    end

end


function SelectRoleItem:onEnemyFeet(container)

end

function SelectRoleItem:onChocice1(container)
    local index = self.id
    local  isSecelct = self.id == curSelectIndex
    local btn =  container:getVarMenuItem("mChocice")
    if isSecelct then
        btn:unselected()
        curSelectIndex = 0
        HelpFightDataManager:sendHPEighteenPrincesChangeHelpReq(0)
    else
        if myHelpFightListData.infos[index].isCanUse == 0 then
            if myHelpFightListData.infos[index].leftCount <= 0 then
                MessageBoxPage:Msg_Box(common:getLanguageString("@Eighteentip1"))
                return
            elseif myHelpFightListData.infos[index].leftCount <= 5 and myHelpFightListData.infos[index].leftCount > 0 then
                HelpFightSelectRolePopUp:onBuyUseTimes(index)
                return
            end
        end
        btn:selected()
        curSelectIndex = index
        myHelpFightListData = myHelpFightListData or {}
        if myHelpFightListData.infos  and myHelpFightListData.infos[index] then
            isBuy = false
            HelpFightDataManager:sendHPEighteenPrincesChangeHelpReq(myHelpFightListData.infos[index].playerId)
        end
    end
    lastSelectIndex = curSelectIndex
    HelpFightSelectRolePopUp:refreshBtnGroup(myContain)
    for i = 1, #itemList do
        local item = itemList[i];
        if item then
            local item = itemList[i];
            if item then
                item.cls:onRefreshItem(item.node:getCCBFileNode());
            end
        end
    end
end

function SelectRoleItem:onRefreshItem(container)
    if container == nil then
        return
    end
    local index = self.id
    local isSecelct  = curSelectIndex == index
    local btn =  container:getVarMenuItem("mChocice")
    if isSecelct then
        btn:selected()
    else
        btn:unselected()
    end
end


function HelpFightSelectRolePopUp:onBuyUseTimes(index)
    local cost =ConfigManager.getHelpFightBasicCfg()[1].helpcosume or 100
    if UserInfo.playerInfo.gold < cost then
        MessageBoxPage:Msg_Box_Lan("@GoldNotEnough")
        return
    end
    curSelectIndex = index
    HelpFightSelectRolePopUp:refreshBtnGroup(myContain)
    for i = 1, #itemList do
        local item = itemList[i];
        if item then
            local item = itemList[i];
            if item then
                item.cls:onRefreshItem(item.node:getCCBFileNode());
            end
        end
    end
    local title = common:getLanguageString("@Eighteentitle8")
    local msg = common:getLanguageString("@Eighteenbtncontent12",cost)
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            myHelpFightListData = myHelpFightListData or {}
            if myHelpFightListData.infos  and myHelpFightListData.infos[index] then
                isBuy = true
                HelpFightDataManager:sendHPEighteenPrincesChangeHelpReq(myHelpFightListData.infos[index].playerId)
            end
        else
            curSelectIndex = 0
            HelpFightSelectRolePopUp:refreshBtnGroup(myContain)
            for i = 1, #itemList do
                local item = itemList[i];
                if item then
                    local item = itemList[i];
                    if item then
                        item.cls:onRefreshItem(item.node:getCCBFileNode());
                    end
                end
            end
        end
    end , true, "@ActivityTimeLimitGift2111381" ,"@Return", true,nil,nil, function()
        curSelectIndex = 0
        HelpFightSelectRolePopUp:refreshBtnGroup(myContain)
        for i = 1, #itemList do
            local item = itemList[i];
            if item then
                local item = itemList[i];
                if item then
                    item.cls:onRefreshItem(item.node:getCCBFileNode());
                end
            end
        end
    end);
end

function HelpFightSelectRolePopUp:onEnter(container)
    myContain = container
    local messageText = container:getVarLabelTTF("mMessage")
    messageText:setString("")

    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container.mScrollView = container:getVarScrollView("mContent");
    self:initUi(container)
    self:registerPacket(container)
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_HELPFIGHTSELECTROLE)
    --self:rebuildAllItem(container)
    if HelpFightDataManager .myFormationInfo == nil then
        HelpFightDataManager:sendEighteenPrincesFormationInfoReq()
    end
    HelpFightDataManager:sendEighteenPrincesHelpListReq()
end

function HelpFightSelectRolePopUp:initData(container)
    myHelpFightListData = nil
    myChallengeData = nil
end

function HelpFightSelectRolePopUp:initUi(container)
    local lb2Str = {
        mRemainingChallengesNum = common:getLanguageString("@Eighteenbtncontent6") ,
        mTitle = common:getLanguageString("@Eighteentitle4"),
        mLeftBtnContent = common:getLanguageString("@Eighteenbtn2"),
        mRightBtnContent = common:getLanguageString("@Eighteenbtn3"),
        mRightChangeBtnContent = common:getLanguageString("@Eighteenbtn4"),
    }
    local showBtn = {}
    if HelpFightDataManager.isJumpSelectRolePage then
        showBtn.mFastSweepNode = false
        showBtn.mChangeRoleNode = true
        showBtn.mMiddleBtnGroup = true
    else
        showBtn.mFastSweepNode = true
        showBtn.mChangeRoleNode = false
        showBtn.mMiddleBtnGroup = false
    end
    showBtn.mAddNode = false

    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setNodesVisible(container,showBtn)
end

--选择协将
function HelpFightSelectRolePopUp:onConfirmSelect(container)
    myHelpFightListData = myHelpFightListData or {}
    myHelpFightListData.infos = myHelpFightListData.infos or {}
    local maxSize = #myHelpFightListData.infos
--[[    if maxSize == 0 then
        PageManager.popPage(thisPageName)
        local title = common:getLanguageString("@Eighteentitle8")
        local msg = common:getLanguageString("@Eighteentip4")
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                --跳转添加好友界面
                PageManager.changePage("FriendPage");
            else
                --直接进入战斗界面
                HelpFightDataManager.LayerInfo = HelpFightDataManager.LayerInfo or {}
                HelpFightDataManager.LayerInfo.layerId = HelpFightDataManager.LayerInfo.layerId or 0
                HelpFightDataManager:sendEighteenPrincesChallengeReq(HelpFightDataManager.LayerInfo.layerId)
            end
        end , true, "@MercenaryExpeditionFinishButton", "@MercenaryExpeditionGiveUpBtn", true);
    else
        if curSelectIndex == 0 then
            MessageBoxPage:Msg_Box(common:getLanguageString("@Eighteentip3"));
        else
            --直接进入战斗界面
            HelpFightDataManager.LayerInfo = HelpFightDataManager.LayerInfo or {}
            HelpFightDataManager.LayerInfo.layerId = HelpFightDataManager.LayerInfo.layerId or 0
            HelpFightDataManager:sendEighteenPrincesChallengeReq(HelpFightDataManager.LayerInfo.layerId)
        end
    end]]
    if  maxSize == 0 or curSelectIndex == 0 then
        MessageBoxPage:Msg_Box(common:getLanguageString("@Eighteentip3"));
    else
        --直接进入战斗界面
        HelpFightDataManager.LayerInfo = HelpFightDataManager.LayerInfo or {}
        HelpFightDataManager.LayerInfo.layerId = HelpFightDataManager.LayerInfo.layerId or 0
        HelpFightDataManager:sendEighteenPrincesChallengeReq(HelpFightDataManager.LayerInfo.layerId)
    end
end

--跳过
function HelpFightSelectRolePopUp:onSkip(container)

    local title = common:getLanguageString("@Eighteentitle8")
    local msg = common:getLanguageString("@Eighteentip4")
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then

            --PageManager.pushPage("HelpFightSelectRolePopUp")
        else
            --直接进入战斗界面
            PageManager.popPage(thisPageName)
            HelpFightDataManager.LayerInfo = HelpFightDataManager.LayerInfo or {}
            HelpFightDataManager.LayerInfo.layerId = HelpFightDataManager.LayerInfo.layerId or 0
            HelpFightDataManager:sendEighteenPrincesChallengeReq(HelpFightDataManager.LayerInfo.layerId)
        end
    end , true, "@Return", "@ActivityTimeLimitGift2111381", true);
end

function HelpFightSelectRolePopUp:onChangeRoleSelect(container)
    if curSelectIndex == 0 then
        MessageBoxPage:Msg_Box(common:getLanguageString("@Eighteentip3"));
    else
        PageManager.popPage(thisPageName)
       PageManager.pushPage("HelpFightChangeReadyPopUp")
    end
end



---------------------------------------------------
function HelpFightSelectRolePopUp:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.EIGHTEENPRINCES_HELP_LIST_S then
        local msg = EighteenPrinces_pb.HPEighteenPrincesHelpListRet()
        msg:ParseFromString(msgBuff)
        myHelpFightListData = HelpFightDataManager:EighteenPrincesHelpListFun(msg)
        self:rebuildAllItem(container)
    elseif opcode == HP_pb.EIGHTEENPRINCES_HELP_CHANGE_S then
        local msg = EighteenPrinces_pb.HPEighteenPrincesChangeHelpRet()
        msg:ParseFromString(msgBuff)
        if msg.result == 1 then
            if isBuy then
                if HelpFightDataManager.isJumpSelectRolePage then
                    HelpFightSelectRolePopUp:onChangeRoleSelect(container)
                else
                    HelpFightSelectRolePopUp:onConfirmSelect(container)
                end
            end
        else
            curSelectIndex = lastSelectIndex
            HelpFightSelectRolePopUp:refreshBtnGroup(myContain)
            for i = 1, #itemList do
                local item = itemList[i];
                if item then
                    local item = itemList[i];
                    if item then
                        item.cls:onRefreshItem(item.node:getCCBFileNode());
                    end
                end
            end
        end
    elseif opcode == HP_pb.EIGHTEENPRINCES_FORMATIONINFO_S then
        local msg = EighteenPrinces_pb.HPEighteenPrincesFormationInfoRet()
        msg:ParseFromString(msgBuff)
        HelpFightDataManager:EighteenPrincesFormationInfoFun(msg)
    end
end

function HelpFightSelectRolePopUp:buyTimesRet(container, msg)
    _surplusChallengeTimes = msg.surplusChallengeTimes
    container:getVarLabelTTF("mRemainingChallengesNum"):setString(common:getLanguageString("@TodayTheNumberOfRemainingChallenges") .. _surplusChallengeTimes)
    _arenaBuyTimesInitCost = msg.nextBuyPrice
    _arenaAlreadyBuyTimes = msg.alreadyBuyTimes
end

function HelpFightSelectRolePopUp:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function HelpFightSelectRolePopUp:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function HelpFightSelectRolePopUp:onExecute(container)

end

function HelpFightSelectRolePopUp:onExit(container)
    HelpFightDataManager.isJumpSelectRolePage = false
    NodeHelper:deleteScrollView(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container:removePacket(HP_pb.REPLACE_DEFENDER_LIST_S)
    self:removePacket(container)
    onUnload(thisPageName, container);

    if _func then
        _func()
        _func = nil
    end

end

function HelpFightSelectRolePopUp:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_HELPFIGHTSELECTROLE)
end

function HelpFightSelectRolePopUp:purchaseTimes(container)
    HelpFightSelectRolePopUp_BuyTimes()
end

function HelpFightSelectRolePopUp:onClose(container)

    PageManager.popPage(thisPageName)
    if HelpFightDataManager.isJumpSelectRolePage then
        PageManager.pushPage("HelpFightChangeReadyPopUp")
    end
    HelpFightDataManager.isJumpSelectRolePage = false
end

function HelpFightSelectRolePopUp:onReceiveMessage(container)
--[[    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == thisPageName then
            self:rebuildAllItem(container)
        end
    end]]
end



function HelpFightSelectRolePopUp:rebuildAllItem(container)
    table.sort(myHelpFightListData.infos, function(v1,v2)
        if v1.leftCount > 0 and v2.leftCount > 0 then
            return v1.fightValue > v2.fightValue
        elseif v1.leftCount > 0 and v2.leftCount <= 0  then
            return true
        elseif v1.leftCount <= 0 and v2.leftCount > 0  then
            return false
        else
            return v1.fightValue > v2.fightValue
        end
    end)
    self:refreshUI(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function HelpFightSelectRolePopUp:refreshUI(container)
    local showBtn = {}
    if HelpFightDataManager.isJumpSelectRolePage then
        showBtn.mFastSweepNode = false
        showBtn.mChangeRoleNode = true
    else
        showBtn.mFastSweepNode = true
        showBtn.mChangeRoleNode = false
    end
    showBtn.mMiddleBtnGroup = true
    NodeHelper:setNodesVisible(container,showBtn)

    curSelectIndex = 0
    lastSelectIndex = 0

    if myHelpFightListData.infos then
        if #myHelpFightListData.playerId ~= 0 then
            for i = 1, #myHelpFightListData.infos do
                if myHelpFightListData.infos[i].playerId == myHelpFightListData.playerId[1] then
                    curSelectIndex = i
                end
            end
        end
    end
    lastSelectIndex = curSelectIndex
    self:refreshBtnGroup(container)
end

function HelpFightSelectRolePopUp:refreshBtnGroup(container)
    if container == nil then
        return
    end
    local mSelectBtn = container:getVarMenuItemImage("mSelectBtn")
    local mChangeBtn  = container:getVarMenuItemImage("mChangeBtn")

    if curSelectIndex == 0 then
        local sprite = CCSprite:create(GameConfig.CommonButtonImage.Bule.DisabledImage)
        mSelectBtn:setNormalImage(sprite)
        local changeSprite = CCSprite:create(GameConfig.CommonButtonImage.Bule.DisabledImage)
        mChangeBtn:setNormalImage(changeSprite)
        NodeHelper:setNodeIsGray(container,{mRightBtnContent = true ,mRightChangeBtnContent = true })
    else
        local sprite = CCSprite:create(GameConfig.CommonButtonImage.Bule.NormalImage)
        local changeSprite = CCSprite:create(GameConfig.CommonButtonImage.Bule.NormalImage)
        mSelectBtn:setNormalImage(sprite)
        mChangeBtn:setNormalImage(changeSprite)
        NodeHelper:setNodeIsGray(container,{mRightBtnContent = false ,mRightChangeBtnContent = false })
    end
end

function HelpFightSelectRolePopUp:clearAllItem(container)
    container.mScrollView:removeAllCell()
end

function HelpFightSelectRolePopUp:buildItem(container)
    myHelpFightListData = myHelpFightListData or {}
    myHelpFightListData.infos = myHelpFightListData.infos or {}

    local maxSize = #myHelpFightListData.infos
    if maxSize == 0 then
        NodeHelper:setStringForLabel(container,{mMessage = common:getLanguageString("@Eighteentip2")})
        NodeHelper:setNodesVisible(container,{mMessage = true})
    else
        NodeHelper:setNodesVisible(container,{mMessage = false})
        itemList =  NodeHelper:buildCellScrollView(container.mScrollView, maxSize, "HelpFightSelectRoleContent.ccbi", SelectRoleItem);
    end
end



function HelpFightSelectRolePopUp_BuyTimes()
    -- 根据vip等级,判断剩余购买次数
    UserInfo.syncPlayerInfo()
    local costCfg = ConfigManager.getBuyCostCfg()
    local vipLevel = UserInfo.playerInfo.vipLevel

    local leftTime = 999
    local title = common:getLanguageString("@BuyTimesTitle")
    local message = common:getLanguageString("@BuyTimesArenaMsg")
    local buyedTimes = _arenaAlreadyBuyTimes or 0

    PageManager.showCountTimesPage(title, message, leftTime,
            function(times)
                local totalPrice = 0

                for i = buyedTimes + 1, buyedTimes + times do
                    local index = i;
                    if i > #costCfg then
                        index = #costCfg
                    end

                    local costInfo = costCfg[index]
                    if costInfo ~= nil then
                        totalPrice = totalPrice + costInfo.arenaTimes
                    end
                end

                return totalPrice
            end
    , Const_pb.MONEY_GOLD, toPurchaseTimes)
end

-----------------------------------------------------------------
local CommonPage = require("CommonPage")
HelpFightSelectRolePopUp = CommonPage.newSub(HelpFightSelectRolePopUp, thisPageName, option)