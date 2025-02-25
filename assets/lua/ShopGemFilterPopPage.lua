--[[/*=========================================================================
 *  author      : DuanGuangxiang 2019 02 20
 *  include     : ShopGemFilterPopPage.lua
 *  description : 宝石购买
 =========================================================================*/*]] --

local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")
local ShopDataManager = require("ShopDataManager")
local Const_pb = require("Const_pb")

local thisPageName = "ShopGemFilterPopPage"
local option = {
    ccbiFile = "FairGemGetPopUp.ccbi",
    handlerMap = {
        onHelp = "onHelp",
        onClose = "onClose",
        onReductionTen = "onReductionTen",
        onReduction = "onReduction",
        onAddTen = "onAddTen",
        onAdd = "onAdd",
        onGet = "onGet",
        onBtn1="onBtn1",
        onBtn2="onBtn2",
        onBtn3="onBtn3",
    },
    opcodes = {
    }
}

local ShopGemFilterPopPageBase = {}
local ItemId=104002
local mBuyItemIdx = 1
local mBuyNum = 0
 local mBuyItemInfo = {
                        costItem=0,
                        costItemNum={ },
                        costCoin={ },
                        BuyId={ },
                        id={ }
                        }
-------------------------------------------------------------------------------------------------------
local GemItem = { ccbiFile = "FairGemGetContent.ccbi" }
function GemItem:mChooseBtn(container)
    mBuyItemIdx = self.id
    ShopGemFilterPopPage:refreshPage()
end

function GemItem:refreshItem()
end

function GemItem:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    NodeHelper:setNodesVisible(container, { mChoosePic = (mBuyItemIdx == self.id) })
    NodeHelper:setStringForLabel(container, { mLevel = "LV." .. self.id })
end

-------------------------------------------------------------------------------------------------------

function ShopGemFilterPopPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function ShopGemFilterPopPageBase:onEnter(container)
    self.mContainer = container
    self.mScrollView = self.mContainer:getVarScrollView("mArenaContent")
    self:initPage()
    local strMap = { }
    local ItemMap = { mBuyItemInfo.BuyId[1], mBuyItemInfo.BuyId[2], mBuyItemInfo.BuyId[3] }
    for i = 1, #ItemMap do
        local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, ItemMap[i])
        local playerinfo = UserInfo.playerInfo
        NodeHelper:setQualityFrames(self.mContainer, { ["mHand" .. i] = resInfo.quality })
        NodeHelper:setSpriteImage(self.mContainer, { ["mPic"..i] = resInfo.icon }, { ["mPic" .. i] = resInfo.iconScale })
        --NodeHelper:setStringForLabel(self.mContainer,{ ["mGemAtt" .. i] = resInfo.name })
        local str='<p style="margin:10"><font color="#625141" face = "Barlow-SemiBold">'..resInfo.name..'</font></p>'
        local htmlLabel = NodeHelper:setCCHTMLLabel(self.mContainer, "mGemAtt" .. i, CCSize(GameConfig.LineWidth.ItemNameLength , 96), str, true)  
        htmlLabel:setScale(0.65)
    end
    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, mBuyItemInfo.costItem)
    NodeHelper:setSpriteImage(self.mContainer,{ mCostItem = resInfo.icon })
    container:registerPacket(HP_pb.SHOP_BUY_S)
end

function ShopGemFilterPopPageBase:onExit(container)
    container:removePacket(HP_pb.SHOP_BUY_S)
    mBuyItemInfo = {
                        costItem=0,
                        costItemNum={ },
                        costCoin={ },
                        BuyId={},
                        id={ }
                        }
    mBuyItemIdx = 1
    mBuyNum = 0
    self.mScrollView:removeAllCell()
end

function ShopGemFilterPopPageBase:onHelp(container)
    --PageManager.showHelp(GameConfig.HelpKey.HELP_SHOPGEMFILTER)
end

function ShopGemFilterPopPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end
function ShopGemFilterPopPageBase:onBtn1(container)
    mBuyItemIdx = 1
    NodeHelper:setNodesVisible(self.mContainer , { Select1 = true, Select2 = false, Select3 = false })
    mBuyNum = 0
    self:refreshPage()
end
function ShopGemFilterPopPageBase:onBtn2(container)
    mBuyItemIdx = 2
    NodeHelper:setNodesVisible(self.mContainer, { Select1 = false, Select2 = true, Select3 = false })
    mBuyNum = 0
    self:refreshPage()
end
function ShopGemFilterPopPageBase:onBtn3(container)
    mBuyItemIdx = 3
    NodeHelper:setNodesVisible(self.mContainer, { Select1 = false, Select2 = false, Select3 = true })
    mBuyNum = 0
    self:refreshPage()
end

function ShopGemFilterPopPageBase:onReductionTen(container)
    if mBuyItemInfo.BuyId[mBuyItemIdx] == 0 then
        return
    end
    mBuyNum = mBuyNum - 10
    if mBuyNum < 0 then
        mBuyNum = 0
    end
    self:refreshPage()
end

function ShopGemFilterPopPageBase:onReduction(container)
    if mBuyItemInfo.BuyId[mBuyItemIdx] == 0 then
        return
    end
    mBuyNum = mBuyNum - 1
    if mBuyNum < 0 then
        mBuyNum = 0
    end
    self:refreshPage()
end

function ShopGemFilterPopPageBase:onAddTen(container)
    if mBuyItemInfo.BuyId[mBuyItemIdx] == 0 then
        return
    end
    local buyNum = mBuyNum + 10
    if self:isEnought(buyNum) then
        mBuyNum = buyNum
        self:refreshPage()
    else
        local oriBuyNum = mBuyNum
        mBuyNum = self:calcOptimal()
        if oriBuyNum == mBuyNum then
            MessageBoxPage:Msg_Box_Lan("@DiamondTicketAndCoin_NotEnought")
        end
        self:refreshPage()
    end
end

function ShopGemFilterPopPageBase:onAdd(container)
    if mBuyItemInfo.BuyId[mBuyItemIdx] == 0 then
        return
    end
    local buyNum = mBuyNum + 1
    if self:isEnought(buyNum) then
        mBuyNum = buyNum
        self:refreshPage()
    else
        MessageBoxPage:Msg_Box_Lan("@DiamondTicketAndCoin_NotEnought")
        mBuyNum = self:calcOptimal()
        self:refreshPage()
    end
end

function ShopGemFilterPopPageBase:CheckItemId(container, ItemNum)
    if ItemNum == 104003 then
        self.onBtn2(container)
    elseif ItemNum == 104004 then
        self.onBtn2(container)
    else
        self.onBtn1(container)
    end
end

function ShopGemFilterPopPageBase:isEnought(buyNum)
    GemItemsNewCfgData = {}
    GemItemsNewCfgData = ItemManager:getNewGemMarketItems(UserInfo.playerInfo.vipLevel)
 -- local index = container:getTag()
 -- local item = GemItemsCfgData[index]
 -- local itemsCfg = GemItemsNewCfgData[index]
    local costItemInfo = mBuyItemInfo.costItem
    local costCoinInfo = mBuyItemInfo.costCoin[mBuyItemIdx]

    local costItemCount = mBuyItemInfo.costItemNum[mBuyItemIdx] * buyNum
    local costCoinCount = costCoinInfo * buyNum
    local StoneCount = UserItemManager:getCountByItemId(costItemInfo)
    
    return StoneCount >= costItemCount and UserInfo.playerInfo.coin >= costCoinCount--true
end

function ShopGemFilterPopPageBase:onGet(container)
    if mBuyNum == 0 then
        PageManager.popPage(thisPageName)
        return
    end

    local costItemInfo = mBuyItemInfo.costItem
    local costCoinInfo = mBuyItemInfo.costCoin[mBuyItemIdx]

    local costItemCount = mBuyItemInfo.costItemNum[mBuyItemIdx] * mBuyNum
    local costCoinCount = costCoinInfo * mBuyNum
    local StoneCount = UserItemManager:getCountByItemId(costItemInfo)

    if costItemCount > StoneCount and costCoinCount > UserInfo.playerInfo.coin then
        MessageBoxPage:Msg_Box_Lan("@DiamondTicketAndCoin_NotEnought")
        return
    else
        if costItemCount > StoneCount then
            MessageBoxPage:Msg_Box_Lan("@DiamondTicketNotEnought")
            return
        end

        if costCoinCount > UserInfo.playerInfo.coin then
            MessageBoxPage:Msg_Box_Lan("@ERRORCODE_25")
            return
        end
    end

    if mBuyNum > 100 then
        MessageBoxPage:Msg_Box_Lan("@BuyNumOutRange")
        return
    end

    ShopDataManager.buyShopItemsRequest(ShopDataManager._buyType.BUY_SINGLE, Const_pb.GEM_MARKET, mBuyItemInfo.Id[mBuyItemIdx], mBuyNum, 2)
end

function ShopGemFilterPopPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.SHOP_BUY_S then
        PageManager.popPage(thisPageName)
    end
end

function ShopGemFilterPopPageBase:initPage()
    self.mScrollView:removeAllCell()
   --NodeHelper:buildCellScrollView(self.mScrollView, #mBuyItemInfo, GemItem.ccbiFile, GemItem);
    self:refreshPage()
end

function ShopGemFilterPopPageBase:refreshPage()
    self.mScrollView:refreshAllCell()
    self:refreshCostInfo()
end

function ShopGemFilterPopPageBase:calcOptimal()
    
    local costItemInfo = mBuyItemInfo.costItem
    local costCoinInfo = mBuyItemInfo.costCoin[mBuyItemIdx]
    local costItemNum = mBuyItemInfo.costItemNum[mBuyItemIdx]

    local ticketCount = UserItemManager:getCountByItemId(costItemInfo)
    local buyNum1 = math.floor(UserInfo.playerInfo.coin / costCoinInfo)
    local buyNum2 = math.floor(ticketCount / costItemNum)

    local nNum = math.max(0, math.min(buyNum1, buyNum2))
    if nNum > 100 then
        nNum = 100
    end
    return nNum
end

function ShopGemFilterPopPageBase:refreshCostInfo()
    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, mBuyItemInfo.costItem)
    --local gemAtt = ItemManager:getNewGemAttrString(mBuyItemInfo[mBuyItemIdx].itemId);
    local playerinfo = UserInfo.playerInfo
    NodeHelper:setQualityFrames(self.mContainer, { mHand = resInfo.quality })
    NodeHelper:setSpriteImage(self.mContainer, { mPic = resInfo.icon }, { mPic = resInfo.iconScale })
   --
    local costItemInfo = mBuyItemInfo.costItem
    local costCoinInfo = mBuyItemInfo.costCoin[mBuyItemIdx]

    local costItemCount = mBuyItemInfo.costItemNum[mBuyItemIdx] * mBuyNum
    local costCoinCount = costCoinInfo * mBuyNum
    local StoneCount = UserItemManager:getCountByItemId(mBuyItemInfo.costItem)
    local a = GameUtil:formatNumber(costCoinCount)
   --
    NodeHelper:setStringForLabel(self.mContainer, { mAddNum=mBuyNum, mCostDiamondNum=GameUtil:formatDotNumber(costItemCount), mCostCoinNum = GameUtil:formatDotNumber(costCoinCount) })

--[[    local textSize = self.mContainer:getVarNode("mGemAtt"):getContentSize()
    local frameSize = self.mContainer:getVarNode("mAttTxtFrame"):getContentSize()
    frameSize.width = textSize.width - #gemAtt*0.35
    if #gemAtt > 12 then
        frameSize.width = textSize.width - #gemAtt * 1.15
    end
    self.mContainer:getVarNode("mAttTxtFrame"):setContentSize(frameSize)]]

    local costDiamondNumColor = GameConfig.ColorMap.COLOR_BROWN
    local costCoinNumColor = GameConfig.ColorMap.COLOR_BROWN
    local mAddNumColor = GameConfig.ColorMap.COLOR_BROWN

  --if costItemCount > ticketCount and costCoinCount > UserInfo.playerInfo.coin then
  --    MessageBoxPage:Msg_Box_Lan("@DiamondTicketAndCoin_NotEnought")
  --    costCoinNumColor = GameConfig.ColorMap.COLOR_RED
  --    costDiamondNumColor = GameConfig.ColorMap.COLOR_RED
  --else
  --    if costItemCount > ticketCount then
  --        MessageBoxPage:Msg_Box_Lan("@DiamondTicketNotEnought")
  --        costDiamondNumColor = GameConfig.ColorMap.COLOR_RED
  --    end
  --
  --    if costCoinCount > UserInfo.playerInfo.coin then
  --        MessageBoxPage:Msg_Box_Lan("@ERRORCODE_25")
  --        costCoinNumColor = GameConfig.ColorMap.COLOR_RED
  --    end
  --end
  --
   -- if mBuyNum > 100 then
   --     MessageBoxPage:Msg_Box_Lan("@BuyNumOutRange")
   -- end
   --
   -- NodeHelper:setColorForLabel(self.mContainer, { mAddNum = mAddNumColor, mCostDiamondNum = costDiamondNumColor, mCostCoinNum = costCoinNumColor })
end

function ShopGemFilterPopPage_setItemInfo(itemInfo)
    local costItems = { }
    local costCoins = { } 
    local BuyId = { }
    local Idd = 0
    mBuyItemInfo = {
                        costItem=0,
                        costItemNum={ },
                        costCoin={ },
                        BuyId={ },
                        Id={ }
                        }
    local GemItemsNewCfgData = ConfigManager:getNewGemMarketCfg()
    for k = 1, (#GemItemsNewCfgData) do
        local mID = { }
        mID = common:split(GemItemsNewCfgData[k].costItems, "_")
        if tonumber(mID[2]) == itemInfo then
            costItems = common:split(GemItemsNewCfgData[k].costItems, "_")
            costCoins = common:split(GemItemsNewCfgData[k].costCoin, "_")
            BuyId = GemItemsNewCfgData[k].itemId
            Idd = GemItemsNewCfgData[k].id
            table.insert(mBuyItemInfo.Id, tonumber(Idd))
            table.insert(mBuyItemInfo.BuyId, tonumber(BuyId))
            mBuyItemInfo.costItem = tonumber(costItems[2])
            table.insert(mBuyItemInfo.costItemNum, tonumber(costItems[3]))
            table.insert(mBuyItemInfo.costCoin, tonumber(costCoins[3]))
            --mBuyItemInfo.BuyId = tonumber(BuyId)
            --mBuyItemInfo.costItem = tonumber(costItems[2])
            --mBuyItemInfo.costItemNum = tonumber(costItems[3])
            --mBuyItemInfo.costCoin = tonumber(costCoins[3])
           
                           
        end
    end 
end

function ShopGemFilterPopPage_setItemIndex(itemIndex)
    mBuyItemIdx = itemIndex
end

-------------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
ShopGemFilterPopPage = CommonPage.newSub(ShopGemFilterPopPageBase, thisPageName, option)