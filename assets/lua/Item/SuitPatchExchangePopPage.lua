
local UserItemManager = require("Item.UserItemManager");
local ItemManager = require("Item.ItemManager");
local HP_pb = require("HP_pb");

local thisPageName = "SuitPatchExchangePopPage"
local option = {
    ccbiFile = "SuitPatchExchangePopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onReductionTen = "onReductionTen",
        onReduction = "onReduction",
        onAddTen = "onAddTen",
        onAdd = "onAdd",
        onPatchDecomposition = "onPatchDecomposition",
    },
    opcodes =
    {
    }
}

local SuitPatchExchangePopPageBase = { }

local mSellNum = 1;
local mUserItemId = 0;
local mUserItemData = nil;

function SuitPatchExchangePopPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function SuitPatchExchangePopPageBase:onEnter(container)
    self.container = container
    self.container:registerPacket(HP_pb.ITEM_EXCHANGE_S);

    NodeHelper:setStringForLabel(self.container , {mTitle = common:getLanguageString("@SuitPatchDecompositionTitle") , mDecisionTex = common:getLanguageString("@SuitPatchChooseInfo") , mBtnText = common:getLanguageString("@SuitDecompositionOn")})

    self:refreshPage();
end

function SuitPatchExchangePopPageBase:onExit(container)
    container:removePacket(HP_pb.ITEM_EXCHANGE_S);
    mSellNum = 1;
    mUserItemId = 0;
    mUserItemData = nil;
end

function SuitPatchExchangePopPageBase:onClose(container)
    PageManager.popPage(thisPageName);
end

function SuitPatchExchangePopPageBase:onReductionTen(container)
    mSellNum = mSellNum - 10;
    if mSellNum < 1 then
        mSellNum = 1;
    end
    self:refreshPage();
end

function SuitPatchExchangePopPageBase:onReduction(container)
    mSellNum = mSellNum - 1;
    if mSellNum < 1 then
        mSellNum = 1;
    end
    self:refreshPage();
end

function SuitPatchExchangePopPageBase:onAddTen(container)
    mSellNum = mSellNum + 10;
    if mSellNum > mUserItemData.count then
        mSellNum = mUserItemData.count;
    end
    self:refreshPage();
end

function SuitPatchExchangePopPageBase:onAdd(container)
    mSellNum = mSellNum + 1;
    if mSellNum > mUserItemData.count then
        mSellNum = mUserItemData.count;
    end
    self:refreshPage();
end

function SuitPatchExchangePopPageBase:onPatchDecomposition(container)
    local ItemOpr_pb = require("ItemOpr_pb")
    local msg = ItemOpr_pb.HPItemExchange()
    local data = msg.exchangeItem:add()
    data.itemId = mUserItemData.itemId;
    data.count = mSellNum;
    common:sendPacket(HP_pb.ITEM_EXCHANGE_C, msg, false);
end

function SuitPatchExchangePopPageBase:refreshPage()
    local exchangeNum = 10;
    local cfg = ItemManager:getItemCfgById(mUserItemData.itemId);
    local exchangeCrystalNum = cfg["exchangeCrystalNum"];
    if exchangeCrystalNum ~= 0 and #exchangeCrystalNum ~= 0 then
        exchangeNum = exchangeCrystalNum[1]["count"];
    end

    local totalPrice = mSellNum * exchangeNum;
    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, mUserItemData.itemId, mUserItemData.count);
    local info = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.PLAYER_ATTR, 1020, totalPrice);

    NodeHelper:setQualityFrames(self.container, { mHand = resInfo.quality, mHand1 = info.quality });
    NodeHelper:setSpriteImage(self.container, { mPic = resInfo.icon, mPic1 = info.icon }, { mPic = resInfo.iconScale, mPic1 = info.iconScale });
    NodeHelper:setStringForLabel(self.container, { mName = "", mNumber = mSellNum .. "/" .. mUserItemData.count, mAddNum = mSellNum, mNumber1 = totalPrice });

    NodeHelper:setSpriteImage(self.container, { mItemBg = NodeHelper:getImageBgByQuality(resInfo.quality), mItemBg1 = NodeHelper:getImageBgByQuality(info.quality) });

end

function SuitPatchExchangePopPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.ITEM_EXCHANGE_S then
        local msg = ItemOpr_pb.HPItemExchangeRet()
        msg:ParseFromString(msgBuff)
        if msg.isSuccess then
            PageManager.popPage(thisPageName);
        end
    end
end

function SuitPatchExchangePopPage_setSellInfo(userItemId)
    mUserItemData = UserItemManager:getUserItemById(userItemId);
    mUserItemId = userItemId;
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local SuitPatchExchangePopPage = CommonPage.newSub(SuitPatchExchangePopPageBase, thisPageName, option);