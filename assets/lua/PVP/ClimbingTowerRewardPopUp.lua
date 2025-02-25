

local  ClimbingTowerRewardPopUp = {}

local thisPageName = "ClimbingTowerRewardPopUp"
local HP = require("HP_pb")
local NodeHelper = require("NodeHelper")
local common = require("common")
local ClimbingDataManager = require("PVP.ClimbingDataManager")
local ItemManager = require("Item.ItemManager");
local opcodes =
{
--[[    OPCODE_MAIL_INFO_C = HP.MAIL_INFO_C,
    OPCODE_MAIL_GET_C = HP.MAIL_GET_C,
    OPCODE_MAIL_GET_S = HP.MAIL_GET_S,
    OPCODE_MAIL_SEE_ARENA_REPORT_C = HP.MAIL_SEE_ARENA_REPORT_C,
    OPCODE_MAIL_SEE_ARENA_REPORT_S = HP.MAIL_SEE_ARENA_REPORT_S,
    MAIL_SEE_MULTIELITE_BATTLE_REPORT_S = HP.MAIL_SEE_MULTIELITE_BATTLE_REPORT_S,
    APPROVAL_REFUSED_OPER_S = HP.APPROVAL_REFUSED_OPER_S,]]
}

local option = {
    ccbiFile = "ClimbingTowerRewardPopUpNew.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onKeyReceive = "onRewardAll",
        onAllDelete = "onDeleteAll",
        onOrdinary = "onOrdinary",
        onSystem = "onSystem"
    },
    opcode = opcodes
};

local rewardMapData = nil

local RewardItem = {
    ccbiFile = "ClimbingTowerRewardContentNew.ccbi"
}

local PageTab = {
    FirseDrop = 1,
    NormalDrop = 2,
}
local PageType = PageTab.FirseDrop
local mainContainer = nil;

------------------创建content回掉----------------------
function RewardItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        RewardItem.onRefreshItemView(container);
    elseif eventName == "onView" then
        RewardItem:onView(container);
    end
end

function RewardItem:onView(container)

end

function RewardItem:onHand1(container)
    local index = self.id
    self:onHand(index,1,container)
end
function RewardItem:onHand2(container)
    local index = self.id
    self:onHand(index,2,container)
end
function RewardItem:onHand3(container)
    local index = self.id
    self:onHand(index,3,container)
end
function RewardItem:onHand4(container)
    local index = self.id
    self:onHand(index,4,container)
end
function RewardItem:onHand5(container)
    local index = self.id
    self:onHand(index,5,container)
end

function RewardItem:onHand(index ,id,container )
    local selfData = nil
    if PageType == PageTab.NormalDrop then
        selfData = rewardMapData[index].reward.firstDrop[id]
    else
        selfData = rewardMapData[index].reward.normalDrop[id]
    end
    if selfData ~= nil then
        GameUtil:showTip(container:getVarNode("mHand"..id), selfData)
    end
end


function RewardItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local index = self.id
    local selfData
    if PageType == PageTab.NormalDrop then
        selfData = rewardMapData[index].reward.firstDrop
    else
        selfData = rewardMapData[index].reward.normalDrop
    end
    local lb2Str = { }
    local spriteImg = {}
    local scaleMap = {}
    local qualityMap = {}
    local qualityBgMap = {}
    local colorMap = {}
    local visible = {}
    lb2Str["mPassLayer"] = rewardMapData[index].id
    for i = 1, 5 do
        if selfData[i] == nil then
            visible["mPosition"..i] = false
        else
            visible["mPosition"..i] = true
            local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, selfData[i].itemId, selfData[i].count);
            lb2Str["mNumber" .. i] = selfData[i].count
            spriteImg["mPic" .. i] = resInfo.icon
            scaleMap["mPic" .. i] = resInfo.iconScale
            qualityMap["mHand" .. i] = resInfo.quality
            qualityBgMap["mFrameShade" .. i] = resInfo.quality
            local textColor = ConfigManager.getQualityColor()[resInfo.quality].textColor
            colorMap["mName" .. i] = textColor
            local str = ItemManager:getShowNameById(selfData[i].itemId)
            NodeHelper:setBlurryString(container, "mName" .. i, str, GameConfig.BlurryLineWidth, 5)
        end
    end
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, spriteImg, scaleMap);
    NodeHelper:setQualityFrames(container, qualityMap);
    NodeHelper:setImgBgQualityFrames(container, qualityBgMap);
    NodeHelper:setColorForLabel(container, colorMap)
    NodeHelper:setNodesVisible(container,visible)


end

function ClimbingTowerRewardPopUp:onInit(container)
end

function ClimbingTowerRewardPopUp:onLoad(container)
    container:loadCcbiFile(option.ccbiFile);
    NodeHelper:initScrollView(container, "mContent", 4);
end

function ClimbingTowerRewardPopUp:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:registerPacket(container)
    mainContainer = container;
    container.scrollview = container:getVarScrollView("mContent")
    rewardMapData = ClimbingDataManager:getClimbingTowerRewardData()
    self:rebuildAllItem(container)
    self:refreshPage(container);
    PageType = PageTab.FirseDrop
    -- self:rebuildAllItem(container);
end

function ClimbingTowerRewardPopUp:onExecute(container)

end

function ClimbingTowerRewardPopUp:onExit(container)

    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container.scrollview:removeAllCell()
    onUnload(thisPageName, container)
end
----------------------------------------------------------------

function ClimbingTowerRewardPopUp:refreshPage(container)
    self:setTabSelected(container)
--[[    local rewardCount = self:getCurrentRewardCount();
    local mailNoticeStr = common:getLanguageString("@MailNotice", rewardCount);

    if PageType == PageTab.CommonMail then
        MailDataHelper.newCommonMail = false
    else
        MailDataHelper.newSystemMail = false
    end

    local nodeVisible = {
        mOrdinaryPoint = MailDataHelper.newCommonMail,
        mMailSystemPoint = MailDataHelper.newSystemMail
    }

    if rewardCount <= 0 then
        mailNoticeStr = common:getLanguageString("@MailNoticeNo");
    end

    NodeHelper:setNodesVisible(container, nodeVisible)
    NodeHelper:setStringForLabel(container, { mMailPromptTex = mailNoticeStr });
    self:setTabSelected(container)]]
end
----------------scrollview-------------------------
function ClimbingTowerRewardPopUp:rebuildAllItem(container)
    self:clearAllItem(container);
    self:buildItem(container);
end

function ClimbingTowerRewardPopUp:clearAllItem(container)
    local scrollview = container.scrollview
    scrollview:removeAllCell();
end

function ClimbingTowerRewardPopUp:buildItem(container)

    local maxSize = #rewardMapData
    local scrollview = container.scrollview
    local ccbiFile = RewardItem.ccbiFile
    local totalSize = maxSize
    if totalSize == 0 then return end
    local cell = nil
    for i = 1, totalSize do
        cell = CCBFileCell:create()
        cell:setCCBFile(ccbiFile)

        local panel = common:new( { id = totalSize - i + 1 }, RewardItem)
        cell:registerFunctionHandler(panel)

        scrollview:addCell(cell)
        local pos = ccp(0, cell:getContentSize().height *(i - 1))
        cell:setPosition(pos)
    end
    local size = CCSizeMake(cell:getContentSize().width, cell:getContentSize().height * totalSize)
    scrollview:setContentSize(size)
    scrollview:setContentOffset(ccp(0, scrollview:getViewSize().height - scrollview:getContentSize().height * scrollview:getScaleY()))
    scrollview:forceRecaculateChildren()
end

--首次掉落
function ClimbingTowerRewardPopUp:onOrdinary(container)
    if PageType == PageTab.FirseDrop then
        self:setTabSelected(container)
        return
    end

    PageType = PageTab.FirseDrop
    self:rebuildAllItem(container);
    self:refreshPage(container);
end

--日常掉落
function ClimbingTowerRewardPopUp:onSystem(container)
    if PageType == PageTab.NormalDrop then
        self:setTabSelected(container)
        return
    end

    PageType = PageTab.NormalDrop
    self:rebuildAllItem(container);
    self:refreshPage(container);
end

function ClimbingTowerRewardPopUp:setTabSelected(container)
    local isCommonTab = PageType == PageTab.FirseDrop
    NodeHelper:setMenuItemSelected(container, {
        mOrdinaryBtn = isCommonTab,
        mMailSystemBtn = not isCommonTab
    } )
end
----------------click event------------------------
function ClimbingTowerRewardPopUp:onClose(container)
    PageManager.popPage(thisPageName);
end


---------------------------------------------------
function ClimbingTowerRewardPopUp:onReceivePacket(container)
    local Arena_pb = require "Arena_pb"
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
--[[    if opcode == opcodes.APPROVAL_REFUSED_OPER_S then
        local alliance = require('Alliance_pb')
        local msg = alliance.HPApprovalRefusedOperS()
        msg:ParseFromString(msgBuff)
        local state = msg.state
        -- 0.拒绝 1.批准
        if state == 0 then
            -- MessageBoxPage:Msg_Box_Lan("@AllianceRefuseOK")
        elseif state == 1 then
            -- MessageBoxPage:Msg_Box_Lan("@AllianceApplyOk")
        end
        MailDataHelper:removeMailById(msg.emailId)
        self:rebuildAllItem(container);
        self:refreshPage(container)
        return
    end]]

end


function ClimbingTowerRewardPopUp:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ClimbingTowerRewardPopUp:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ClimbingTowerRewardPopUp:getCurrentRewardCount()
    local count = 0;
    return count;
end



function ClimbingTowerRewardPopUp:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
--[[    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName then
            self:rebuildAllItem(container);
            self:refreshPage(container);
        elseif pageName == GVGManager.moduleName then

        end
    end]]
end

local CommonPage = require("CommonPage");
local ClimbingTowerRewardPopUp = CommonPage.newSub(ClimbingTowerRewardPopUp, thisPageName, option);


