----------------------------------------------------------------------------------
--[[
首充奖励
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'DailyBundlePage'
local Activity5_pb = require("Activity5_pb");
local HP_pb = require("HP_pb");
local InfoAccesser = require("Util.InfoAccesser")


local DailyBundleCfg = ConfigManager.getFirstGiftPack_New()
local DailyBundleData = require ("Activity.DailyBundleData")

local DailyBundleBase = {}
local NewBattleMapItem = {}
local ReceivedItem = {}
local RechargedTotal = 0
local id = 1
local NeedMoney = 0
local VIP_EXP = 0
local GetReward={}

local option = {
    ccbiFile = "DailyBundle.ccbi",
    handlerMap =
    {
        --onRecharge = "onRecharge",
        onHand = "onHand",
        onClose = "onClose",
        onClaim = "onClaim",
        onOffer = "onOffer",
        onGet = "onGet",
        onHelp = "onHelp",
    },
}
for i = 1, 3 do
    option.handlerMap["onTab" .. i] = "onTab"
end

local opcodes = {
    NP_CONTINUE_RECHARGE_MONEY_S=HP_pb.NP_CONTINUE_RECHARGE_MONEY_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S
}


function DailyBundleBase:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = ParentContainer
    self:registerPacket(ParentContainer)
    self:SetAnim(ParentContainer)
    self:getVipPointRequest()
end
function  DailyBundleBase:getVipPointRequest()
    local msg = Activity5_pb.NPContinueRechargeReq()
    msg.action = 0
    local pb_data = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.NP_CONTINUE_RECHARGE_MONEY_C, pb_data, #pb_data, true)
end
function DailyBundleBase:SetAnim(container)
    local spinePath = "Spine/NG2D"
    local spineName = "NG2D_14"
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local parentNode = container:getVarNode("mSpine")
    parentNode:setScaleX(-0.85)
    parentNode:setScaleY(0.85)
    parentNode:setPosition(ccp(0, -500))
    parentNode:removeAllChildrenWithCleanup(true)
    local Ani01 = CCCallFunc:create(function()
        parentNode:addChild(spineNode)
        spine:runAnimation(1, "animation2", -1)
    end)
    local array = CCArray:create()
    array:addObject(CCDelayTime:create(0.2))
    array:addObject(Ani01)
    array:addObject(CCDelayTime:create(2))
    parentNode:runAction(CCSequence:create(array))
end
function NewBattleMapItem:onHand1(container)
    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(tonumber(self.itemType), tonumber(self.id), tonumber(self.num))
    local items = {
        type = tonumber(self.itemType),
        itemId = tonumber(self.id),
        count = tonumber(self.num)
    };
    GameUtil:showTip(container:getVarNode("mHand1"), items)
end


function NewBattleMapItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.itemType, self.id, self.num)
    local lb2Str = {}
    
    lb2Str["mNumber" .. 1] = self.num
    
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, {["mPic" .. 1] = resInfo.icon}, {["mPic" .. 1] = resInfo.iconScale})
    NodeHelper:setQualityFrames(container, {["mHand" .. 1] = resInfo.quality})
    NodeHelper:setImgBgQualityFrames(container, {["mFrameShade" .. 1] = resInfo.quality})
    NodeHelper:setNodesVisible(container, {mShader = false, mName1 = false, mNumber1 = false, mMask = false})
    if #ReceivedItem ~= 0 then
        NodeHelper:setNodeVisible(container:getVarSprite("mMask"), (id == ReceivedItem[id]))
    end
    local contentWidth = content:getContentSize().width
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, {["mStar" .. i] = false})
    end
    -- for i =1,resInfo.quality do
    --     NodeHelper:setNodesVisible(container, {["mStar" .. i] = false})
    -- end
    NodeHelper:setNodesVisible(container, {mEquipLv = false})
    container:getVarLabelTTF("mNumber1_1"):setString(self.num)
end

function DailyBundleBase:refresh(container)
    local Info = DailyBundleData:getData()
    VIP_EXP = Info.VIP_EXP
    ReceivedItem = Info.ReceivedItem

    local Cfg = DailyBundleCfg
    local EXP = tonumber(Cfg[id].NeedMoney)
    local buyBtnState = true
    local buyBtnText = common:getLanguageString("@Receive")

    -- 设置提示信息
    local txt = {
        [1] = common:getLanguageString("@DailyBundleNotice01"),
        [2] = common:getLanguageString("@DailyBundleNotice04"),
        [3] = common:getLanguageString("@DailyBundleNotice06")
    }
    local achievementText = txt[id] or ""

    -- 更新显示的经验值和提示信息
    NodeHelper:setStringForLabel(container, {
        mNumTxt = EXP,
        mAchiveTxt = achievementText
    })

    local node = container:getVarNode("mNumTxt")
    node:setPosition(ccp(12,40))
    node:setAnchorPoint(ccp(1,0.5))
    node:setScale(0.5)
    --SETBAR
    NodeHelper:setScale9SpriteBar(container,"mBar",VIP_EXP,EXP,500)
    NodeHelper:setStringForLabel(container,{mBarTxt = VIP_EXP.." / ".. EXP })
    -- 根据VIP经验值设置按钮状态和文本
    if VIP_EXP < EXP then
        buyBtnState = false
        buyBtnText = common:getLanguageString("@Underway")
    end

    -- 检查是否已经领取奖励
    local rewardReceived = false
    for _, v in ipairs(ReceivedItem) do
        if v == id then
            rewardReceived = true
            break
        end
    end

    if rewardReceived then
        buyBtnState = false
        NodeHelper:setNodeIsGray(container, {mBuyBtn = true})
        buyBtnText = common:getLanguageString("@ReceiveDone")
    end

    -- 更新按钮状态和文本
    NodeHelper:setMenuItemsEnabled(container, {mBuyBtn = buyBtnState})
    NodeHelper:setStringForLabel(container, {mBuyTxt = buyBtnText})

    -- 更新单元格和标签状态
    self:buildCell(container)

    for i = 1, 3 do
        NodeHelper:setMenuItemsEnabled(container, {["mTab"..i] = (i ~= id)})
        NodeHelper:setNodesVisible(container, {["mTabSelect"..i] = (i == id)})
    end
end

function DailyBundleBase:buildCell(container)
    local scrollview = container:getVarScrollView("mContent")
    local items = DailyBundleCfg[id].Rewards
    if items == nil then return end
    scrollview:removeAllCell()
    for i = #items, 1, -1 do
        local itemData, itemId, itemNum = items[i].type, items[i].itemId, items[i].count
        cell = CCBFileCell:create()
        cell:setCCBFile("BackpackItem.ccbi")
        local panel = common:new({itemType = itemData, id = itemId, num = itemNum}, NewBattleMapItem)
        cell:setScale(0.6)
        cell:setContentSize(CCSize(100, 90))
        cell:registerFunctionHandler(panel)
        scrollview:addCell(cell)
    end
    
    scrollview:setTouchEnabled(false)
    scrollview:orderCCBFileCells()
end
function DailyBundleBase:refreshPage(container)

end

function DailyBundleBase:onTab(container,eventName)
    id = tonumber ( string.sub (eventName,-1) ) 
    self:refresh(container)
end
function DailyBundleBase:onGet(container)
    local msg = Activity5_pb.NPContinueRechargeReq()
    msg.action = 1
    msg.awardCfgId = id
    local pb_data = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.NP_CONTINUE_RECHARGE_MONEY_C, pb_data, #pb_data, true)
end
function DailyBundleBase:onReceivePacket(packet)
    local opcode = packet:getRecPacketOpcode()
    local msgBuff = packet:getRecPacketBuffer()
    if opcode == HP_pb.NP_CONTINUE_RECHARGE_MONEY_S then
        local msg = Activity5_pb.NPContinueRechargeRes()
        msg:ParseFromString(msgBuff)
        local DailyBundleData = require ("Activity.DailyBundleData")
         DailyBundleBase_SetInfo(msg)
        self:refresh(self.container)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
        local DailyBundleData = require ("Activity.DailyBundleData")
        if DailyBundleData:isGetAll() then DailyBundleBase:onClose(self.container) end
    end
end


function DailyBundleBase:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function DailyBundleBase:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function DailyBundleBase:onClose(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
    PageManager.popPage(thisPageName)
end

-- 說明頁
function DailyBundleBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_DAILY_BUNDLE)
end

local CommonPage = require('CommonPage')
DailyBundlePage = CommonPage.newSub(DailyBundleBase, thisPageName, option)

return DailyBundlePage
