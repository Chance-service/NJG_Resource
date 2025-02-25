local HP_pb = require("HP_pb")
local Activity5_pb = require("Activity5_pb")
local NodeHelper = require("NodeHelper")
local thisPageName = "BuyActivityItemPage"

local buyCount = 1
local ActivityId=1
local itemId=1
local ItemType=10000
local ItemInfoTable={}

local CostDiamond=0
local exChangeId=0

local opcodes = {
    ACTIVITY176_ACTIVITY_EXCHANGE_S = HP_pb.ACTIVITY176_ACTIVITY_EXCHANGE_S,
}

local option = {
    ccbiFile = "CommonItemInfoPage.ccbi",
    handlerMap = {
        onClose = "onClose",
        onTwoBtn_2="onClose",
        onTwoBtn_1 = "onBuy",
        onAmountBtn_max="onMax",
        onAmountBtn_min="onMin",
        onAmountBtn_add="onAdd",
        onAmountBtn_sub="onSub",
        onHand1="onHand1",
        onHelp="onHelp"
    },
    opcode = opcodes
}

local BuyActivityItemBase = {}
function BuyActivityItemBase:onEnter(container)
    self:registerPacket(container)
    self.container=container
    self:setItemInfo(container)
    self:Init(container)
end
function BuyActivityItemBase:Init(container)
    local StringTable={}
    local VisableTable={}
    local menuItemTable={}
    local SpriteImgTable={}

    local resInfo = ResManagerForLua:getResInfoByTypeAndId(ItemType, itemId, 1)
    local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
    local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)

    menuItemTable["mHand1"]={normal = normalImage}
    --GloryHole
    if ActivityId ==175 then
        menuItemTable["twoBtn_1"]={normal = "GloryHole_btn05_N.png", press = "GloryHole_btn05_S.png", disabled= "GloryHole_btn05_G.png" }
        menuItemTable["twoBtn_2"]={normal = "GloryHole_btn05_N.png", press = "GloryHole_btn05_S.png", disabled= "GloryHole_btn05_G.png" }
    end

    StringTable["titleTxt"]=common:getLanguageString("@BuyLimit")
    StringTable["itemNameTxt"]=common:getLanguageString("@Item_"..itemId)
    StringTable["twoBtnTxt_1"]=common:getLanguageString("@BuyLimit")
    StringTable["twoBtnTxt_2"]=common:getLanguageString("@CancleTeam")
    StringTable["amountNum"]=buyCount
    StringTable["mAmountTxt"]=common:getLanguageString("@CostGold")
    StringTable["amountTotalNum"]=buyCount*CostDiamond
    StringTable["mCost"]=common:getLanguageString("@GemCostGold")
    if ActivityId == 175 then
        StringTable["itemPrice"]=100
    end

    VisableTable["oneBtnNode"]=false
    VisableTable["itemDescTxt"]=false
    VisableTable["mItemNode"]=true
    VisableTable["mStarNode"]=false
    VisableTable["selectedNode"]=false
    VisableTable["nameBelowNode"]=false
    VisableTable["mNumber1_1"]=false
    if ActivityId==175 then
        VisableTable["mPrice"]=true
        StringTable["itemPrice"]=GameConfig.GLOYHOLE.itemPrice[itemId]
    end
    SpriteImgTable["mFrameShade1"]=iconBg
    SpriteImgTable["mPic1"]=resInfo.icon

    if ActivityId ==175 then
        --GloryHole
        NodeHelper:setScale9SpriteImage2(container, {mBackGround="ItemSelection_GH_bg.png"})
    end

    NodeHelper:setMenuItemImage(container,menuItemTable)
    NodeHelper:setSpriteImage(container, SpriteImgTable)
    NodeHelper:setNodesVisible(container,VisableTable)
    NodeHelper:setStringForLabel(container,StringTable)
end
function BuyActivityItemBase:setItemInfo(container)
    local Cost=ItemInfoTable[tostring(itemId)].Cost
    exChangeId=ItemInfoTable[tostring(itemId)].mID
    CostDiamond=tonumber(common:split(Cost,"_")[3])
    GameConfig.GLOYHOLE.itemPrice[itemId] = CostDiamond
end
function BuyActivityItemBase:onHand1(container)
    local _itemId=itemId
    local cfg= {
                    type = ItemType,
                    itemId = _itemId,
                    count = 1};
    GameUtil:showTip(container:getVarNode('mPic1'), cfg)
end
function BuyActivityItemBase:onMax(container)
    buyCount=99
    NodeHelper:setStringForLabel(container,{amountNum=buyCount,amountTotalNum=buyCount*CostDiamond})
end
function BuyActivityItemBase:onMin(container)
    buyCount=1
    NodeHelper:setStringForLabel(container,{amountNum=buyCount,amountTotalNum=buyCount*CostDiamond})
end
function BuyActivityItemBase:onAdd(container)
    if buyCount==99 then return end
    buyCount=buyCount+1
   NodeHelper:setStringForLabel(container,{amountNum=buyCount,amountTotalNum=buyCount*CostDiamond})
end
function BuyActivityItemBase:onSub(container)
    if buyCount==1 then return end
    buyCount=buyCount-1
    NodeHelper:setStringForLabel(container,{amountNum=buyCount,amountTotalNum=buyCount*CostDiamond})
end
function BuyActivityItemBase:onClose(container)
    CostDiamond=0
    buyCount=1
    exChangeId=0
    BuyActivityItemBase:removePacket(container)
    PageManager.popPage(thisPageName)
end
function BuyActivityItemBase:onBuy()
   local msg=Activity5_pb.ActivityExchangeReq()
   msg.action=1
   msg.activityId=ActivityId
   msg.exchangeObj.exchangeId=exChangeId
   msg.exchangeObj.exchangeTimes=buyCount
   common:sendPacket(HP_pb.ACTIVITY176_ACTIVITY_EXCHANGE_C, msg, true)
end

function BuyActivityItemBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ACTIVITY176_ACTIVITY_EXCHANGE_S then
        local msg = Activity5_pb.ActivityExchangeResp()
        msg:ParseFromString(msgBuff)
        if msg.action==1 then
            --MessageBoxPage:Msg_Box(common:getLanguageString('@BuySuccess',buyCount))
            buyCount=0
            ActivityId=1
            itemId=1
            PageManager.popPage(thisPageName)
            require("GloryHole.GloryHoleSubPage_MainScene")
            GloryHoleBase_refreshItem()
        end
    end
end
function BuyActivityItemBase_setData(actId,mID,Type,infotable)
    ActivityId=actId
    itemId=mID
    ItemType=Type
    ItemInfoTable=infotable
end
function BuyActivityItemBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function BuyActivityItemBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function BuyActivityItemBase:onHelp(container)
     PageManager.showHelp(GameConfig.HelpKey.HELP_MONEYCOLLECTION)
end

local CommonPage = require("CommonPage")
local BuyActivityItemPage = CommonPage.newSub(BuyActivityItemBase, thisPageName, option)

return BuyActivityItemPage
