local HP_pb = require("HP_pb")-- ¥]§t??id¤å¥ó
local thisPageName = "CommPop.TreasureChoosePage"
local ItemOpr_pb 	= require("ItemOpr_pb");
local ChooseItems = {}
local UseCount = 1
local ChoesnItem=0
local UsingItem=0
local MainContainer=nil
local nodes={}
local opcodes = {
    ITEM_USE_S = HP_pb.ITEM_USE_S,
    PLAYER_AWARD_S=HP_pb.PLAYER_AWARD_S
}

local option = {
    ccbiFile = "CommonItemInfoPage2.ccbi",
    handlerMap = {
        onClose = "onClose",
        onOneBtn = "onOneBtn",
    },
    opcode = opcodes
}

local TreasureChoose = {}

local ChooseContent = { ccbiFile = "GoodsItem.ccbi" }

function TreasureChoose:onEnter(container)
    self:registerPacket(container)
    MainContainer=container
    NodeHelper:setStringForLabel(container,{mContentTxt=""})
    TreasureChoose:BuildScrollview(container)
    NodeHelper:setMenuItemsEnabled(MainContainer,{oneBtn=false})
end

function TreasureChoose:BuildScrollview(container)

    local scrollview = container:getVarScrollView("mContent")

    scrollview:removeAllCell()
    for _,data in pairs (ChooseItems) do
       local cell = CCBFileCell:create()
       cell:setCCBFile(ChooseContent.ccbiFile)
       cell:setContentSize(CCSizeMake(130,150))
       cell:setScale(0.8)
       local panel = common:new( { rewardItems=data }, ChooseContent)
       cell:registerFunctionHandler(panel)
       scrollview:addCell(cell)
    end
    if #ChooseItems>5 then
        scrollview:setTouchEnabled(true)
    else
         scrollview:setTouchEnabled(false)
    end
    scrollview:orderCCBFileCells()
end

function TreasureChoose:onClose(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
    PageManager.popPage(thisPageName)
    nodes={ }
end

function TreasureChoose:onOneBtn()
    if ChoesnItem==0 then return end
    local msg = ItemOpr_pb.HPItemUse();
	msg.itemId = UsingItem;
	msg.itemCount = UseCount or 1; 
    msg.profId = ChoesnItem;
    common:sendPacket(HP_pb.ITEM_USE_C, msg);
end

function TreasureChoose:onReceivePacket(container)   
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if  opcode == HP_pb.ITEM_USE_S then
        PageManager.popPage(thisPageName)
    end
    if opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
end


function TreasureChoose:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function TreasureChoose:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
function TreasureChoose:setData(count,items,using)
    UseCount = count
    ChooseItems=items
    UsingItem=using
end

function ChooseContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    container:getVarNode("mNode"):setPosition(ccp(65,75))
    local ResManager = require "ResManagerForLua"
    local resInfo = ResManager:getResInfoByTypeAndId(self.rewardItems and self.rewardItems.type, self.rewardItems and self.rewardItems.itemId , UseCount)
    container.mId=self.rewardItems.itemId
    nodes[self.rewardItems.itemId]=container


    local numStr = ""
    if resInfo.count > 0 then
        numStr = "x" .. GameUtil:formatNumber(resInfo.count)
    end
    local lb2Str = {
        mNumber = numStr
    }
    local showName = ""
    if self.rewardItems and self.rewardItems.type == 30000 then
        showName = ItemManager:getShowNameById(self.rewardItems.itemId)
    else
        showName = resInfo.name           
    end

    if self.rewardItems.type == 40000 then
        for i = 1, 6 do
            NodeHelper:setNodesVisible(container, { ["mStar" .. i] = i == resInfo.star })
        end
    end
    NodeHelper:setNodesVisible(container, { mStarNode = self.rewardItems.type == 40000 })
    NodeHelper:setNodesVisible(container,{selectedNode=false})
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, { mPic = resInfo.icon }, { mPic = 1 })
    NodeHelper:setQualityFrames(container, { mHand = resInfo.quality })
    NodeHelper:setNodesVisible(container, { mName = false })
end
function ChooseContent:onHand(container)
    local id = self.rewardItems.itemId
    ChoesnItem = id
    GameUtil:showTip(container:getVarNode("mHand"),self.rewardItems)
    NodeHelper:setNodesVisible(nodes[self.rewardItems.itemId],{selectedNode=(id==ChoesnItem)})
   -- NodeHelper:setStringForLabel(MainContainer,{mContentTxt=UseCount})
    NodeHelper:setMenuItemsEnabled(MainContainer,{oneBtn=true})
    for k,v in pairs(nodes) do
        NodeHelper:setNodesVisible(v,{selectedNode=(v.mId==ChoesnItem)})
    end
end


local CommonPage = require("CommonPage")
local TreasureChoosePage = CommonPage.newSub(TreasureChoose, thisPageName, option)

return TreasureChoosePage
