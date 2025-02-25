----------------------------------------------------------------------------------
--[[
首充奖励
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'FirstChargePageNew'
local Activity_pb = require("Activity5_pb");
local HP_pb = require("HP_pb");

local FirstGiftCfg = ConfigManager.getFirstGiftPack_New()


local FirstChargeBase = {}
local NewBattleMapItem = {}
local ReceivedItem = {}
local RechargedTotal = 0
local id = 1
local NeedMoney = 0
local GetReward = nil


local option = {
    ccbiFile = "FirstRecharge.ccbi",
    handlerMap =
    {
        --onRecharge = "onRecharge",
        onHand = "onHand",
        onExit = "onExit",
        onClaim = "onClaim",
        onBtn01 = "onBtn01",
        onBtn02 = "onBtn02",
        onBtn03 = "onBtn03",
        onClaim = "onClaim"
    },
}


local opcodes = {
    NP_CONTINUE_RECHARGE_MONEY_S = HP_pb.NP_CONTINUE_RECHARGE_MONEY_S
}
local DayLogin30ItemState = {
    Null = 0,
    HaveReceived = 1,
    Supplementary = 2,
    CanGet = 3,
}

function FirstChargeBase:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    self:registerPacket(ParentContainer)
    luaCreat_FirstChargePageNew(container)
    mItemWidth = 0
    self:getInfo(container)
    
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
function FirstChargeBase:refresh(container)
    local scrollview = nil
    local ItemCount, items, heroInfo, nMoney = self:getItemInfo(id)
    NeedMoney = nMoney
    local cellScale = 0
    local WidthOffset = 0
    local HeighOffset = 0
    if (#heroInfo ~= 0) then
        scrollview = container:getVarScrollView("mContent1")
        NodeHelper:setNodesVisible(container, {mItems1 = true, mItems2 = false})
        -----位置/大小/狀態調整----
        cellScale = 0.6
        HeighOffset = 40
        WidthOffset = -55
    else
        scrollview = container:getVarScrollView("mContent2")
        NodeHelper:setNodesVisible(container, {mItems1 = false, mItems2 = true})
        cellScale = 0.7
        HeighOffset = 45
        WidthOffset = -40
    end
    ------------------
    scrollview:removeAllCell()
    for i = 1, ItemCount do
        local itemData, itemId, itemNum = items[i].type, items[i].itemId, items[i].count
        cell = CCBFileCell:create()
        cell:setCCBFile("BackpackItem.ccbi")
        local panel = common:new({itemType = itemData, id = itemId, num = itemNum}, NewBattleMapItem)
        cell:registerFunctionHandler(panel)
        cell:setContentSize(CCSize(cell:getContentSize().width + WidthOffset, cell:getContentSize().height + HeighOffset))
        cell:setAnchorPoint(ccp(0.5, 1))
        cell:setPosition(ccp(0, 0))
        cell:setScale(cellScale)
        scrollview:addCell(cell)
    end
    scrollview:setTouchEnabled(false)
    scrollview:orderCCBFileCells()
    scrollview:setContentOffset(ccp(-5, 0))
    
    self:refreshPage(container, heroInfo)
end
function FirstChargeBase:refreshPage(container, heroInfo)
    local str=common:getLanguageString("@continueRechargeMoneyDesc",  RechargedTotal)
    NodeHelper:setStringForLabel(container, {mChargedNum = str})--RechargedTotal .. " / " .. NeedMoney
    NodeHelper:setNodesVisible(container, {mPic01 = (id == 1 or id == 2), mPic02 = (id == 3), mTitle1 = (id == 1 or id == 2), mTitle2 = (id == 3)})
    if(id==1)then
    NodeHelper:setMenuItemsEnabled(container, {onBtn01 = false,onBtn02=true,onBtn03=true})
    local str=common:getLanguageString("@FirsBuyNotic001");
    NodeHelper:setStringForLabel(container,{mTitleTxt=str})
    elseif(id==2) then
    NodeHelper:setMenuItemsEnabled(container, {onBtn01 = true,onBtn02=false,onBtn03=true})
     local str=common:getLanguageString("@FirsBuyNotic001");
    NodeHelper:setStringForLabel(container,{mTitleTxt=str})
    elseif(id==3)then
    NodeHelper:setMenuItemsEnabled(container, {onBtn01 = true,onBtn02=true,onBtn03=false})
     local str=common:getLanguageString("@FirsBuyNotic002");
    NodeHelper:setStringForLabel(container,{mTitleTxt=str})
    end
    if (#heroInfo ~= 0) then
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(heroInfo[1].type, heroInfo[1].itemId, heroInfo[1].count)
        local name= common:getLanguageString("@HeroName_8")
        NodeHelper:setStringForLabel(container, {mHeroName =name})
        --NodeHelper:setSpriteImage(container, {mHeroSprite = resInfo.icon})
        local isHero=true
        if heroInfo[1].type==20000 then isHero=false end
        self:SetAnim(container,isHero)
    end
    if (NeedMoney > RechargedTotal) then
        --NodeHelper:setMenuItemsEnabled(container, {mClaimBtn = false})
        NodeHelper:setStringForLabel(container, {mClaimLable = common:getLanguageString("@GoToRecharge")})
    else
        NodeHelper:setMenuItemsEnabled(container, {mClaimBtn = true})
    end
    if (#ReceivedItem ~= 0) then
        if (ReceivedItem[id] == id) then
            NodeHelper:setMenuItemsEnabled(container, {mClaimBtn = false})
            NodeHelper:setNodeVisible(container:getVarNode("mHeroMask"), true)
            NodeHelper:setStringForLabel(container, {mClaimLable = common:getLanguageString("@ReceiveDone")})
        else
            NodeHelper:setStringForLabel(container, {mClaimLable = common:getLanguageString("@Receive")})
            NodeHelper:setNodeVisible(container:getVarNode("mHeroMask"), false)
        end
    end
end
function FirstChargeBase:SetAnim(container,isHero)
    local spinePath = "Spine/CharacterSpine"
    local spineName=""
    if isHero then
        spineName = "NG_08000"
    else
        spineName = "NG_08008"
    end
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local parentNode = container:getVarNode("mSpine")
    parentNode:setPosition(ccp(10,-50))
    parentNode:setScale(0.8)
    parentNode:removeAllChildrenWithCleanup(true)
    
    local HeroAnim01 = CCCallFunc:create(function()
        parentNode:addChild(spineNode)
        spine:runAnimation(1,"wait_0", -1)
    end)
    
    local clear = CCCallFunc:create(function()
        parentNode:removeAllChildrenWithCleanup(true)
    end)
    
    local array = CCArray:create()
    
    array:addObject(CCDelayTime:create(0.2))
    array:addObject(HeroAnim01)
    parentNode:runAction(CCSequence:create(array))
end
function FirstChargeBase:getInfo(container)
    local msg = Activity_pb.NPContinueRechargeReq()
    msg.action = 0
    local pb_data = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.NP_CONTINUE_RECHARGE_MONEY_C, pb_data, #pb_data, true)
end



function FirstChargeBase:onRecharge(container)
-- if tGiftInfo.isFirstPayMoney then
--     common:sendEmptyPacket(NP_CONTINUE_RECHARGE_MONEY_C, true)
-- else
--     PageManager.pushPage("RechargePage")
-- end
end
function FirstChargeBase:onBtn01(container)
    id = 1
    self:refresh(container)
end
function FirstChargeBase:onBtn02(container)
    id = 2
    self:refresh(container)
end
function FirstChargeBase:onBtn03(container)
    id = 3
    self:refresh(container)
end
function FirstChargeBase:onHand(container)
    if id==2 then return end
    local rolePage = require("NgArchivePage")
    PageManager.pushPage("NgArchivePage")
    local a,b,HeroInfo,d=self:getItemInfo(id)
    local mID = HeroInfo[1].itemId--HeroId
    rolePage:setMercenaryId(mID)
    --if id==1 then
    --    NgArchivePage_setToSkin(false, 1)
    --elseif id==3 then
    --    NgArchivePage_setToSkin(true, 1)
    --    wait(0.5)
    --    NgArchivePage_setToSkin(true, 2)
    --end
end
function wait(seconds)
  local start = os.time()
  repeat until os.time() > start + seconds
end
function FirstChargeBase:onClaim(container)
    if (NeedMoney > RechargedTotal) then
         require("IAP.IAPPage"):setEntrySubPage("Diamond")
         PageManager.pushPage("IAP.IAPPage")
    else
        local msg = Activity_pb.NPContinueRechargeReq()
        msg.action = 1
        msg.awardCfgId = id
        local pb_data = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.NP_CONTINUE_RECHARGE_MONEY_C, pb_data, #pb_data, true)
        local award={}
        local a,b,c,d =self:getItemInfo(id)
        award=b
        local CommonRewardPage = require("CommPop.CommItemReceivePage")
        CommonRewardPage:setData(award, common:getLanguageString("@ItemObtainded"), nil)
        PageManager.pushPage("CommPop.CommItemReceivePage")
    end
end
function FirstChargeBase:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    local msg = Activity_pb.NPContinueRechargeRes()
    msg:ParseFromString(msgBuff)
    RechargedTotal = msg.rechargeTotal
    ReceivedItem = msg.gotAwardCfgId
    GetReward = msg.reward
    self:RewardTable()
    self:refresh(ParentContainer)
-- 是否为首次充值
end
function FirstChargeBase:RewardTable()
    local items={}
    for i=1,3 do
        items[i]=0
    end
    if ReceivedItem then
        for k,v in pairs(ReceivedItem) do
            items[v]=v
        end
    end
    for i=1,3 do
        if items[i]==0 then
            id=i
            break
        end
    end
end
function FirstChargeBase:registerPacket(ParentContainer)
    ParentContainer:registerPacket(HP_pb.NP_CONTINUE_RECHARGE_MONEY_S)
end

function FirstChargeBase:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function FirstChargeBase:onExit(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
    if container.scrollview then
        container.scrollview:removeAllCell()
        container.scrollview = nil
    end
    PageManager.popPage(thisPageName)
end
function FirstChargeBase:getItemInfo(i)
    local count = 0
    local itemInfo = FirstGiftCfg[i]
    if not itemInfo then return end
    local rewardItems = {}
    local heroInfo = {}
    local nTotal = 0
    if itemInfo.awards ~= nil then
        for _, item in ipairs(common:split(itemInfo.awards, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            if tonumber(_type) ~= 70000 and tonumber(_type) ~= 20000 then
                table.insert(rewardItems, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count),
                });
                count = count + 1
            else
                table.insert(heroInfo, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count),
                });
            end
        end
    end
    if itemInfo.nTotalMoney ~= nil then
        nTotal = tonumber(itemInfo.nTotalMoney)
    end
    return count, rewardItems, heroInfo, nTotal
end

local CommonPage = require('CommonPage')
FirstChargePage = CommonPage.newSub(FirstChargeBase, thisPageName, option)

return FirstChargePage
