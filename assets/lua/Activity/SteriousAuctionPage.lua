----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'SteriousAuctionPage'
local HP = require("HP_pb");
require("SteriousShop");
require("Shop_pb");
local bCanAuction = true;--控制当前是否可以竞拍，竞拍后，必须等到服务器回包后 才可以竞拍下一次
local AuctionBase = {}


local MaxPrices = 999999999
local opcodes = 
{
	OPCODE_SHOP_AUCTION_C = HP.SHOP_AUCTION_C,
	OPCODE_SHOP_AUCTION_S = HP.SHOP_AUCTION_S,

}
local option = {
	ccbiFile = "AuctionPopUp.ccbi",
	handlerMap = {
		onCancel 		= 'onClose',
		onAuction 	= 'onAuction',
		onIDButton 		= 'onInput',
		luaInputboxEnter = 'onInputboxEnter',
        OnRefresh    = 'OnRefresh'
	},
    opcode = opcodes
}

local CurPricesText = ""
local DefPricesRate = 1.05;--默认的竞价比率 105%


function AuctionBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function AuctionBase:onEnter(container)
	container:registerLibOS()
	self:refreshPage(container)
    container:registerPacket(opcodes.OPCODE_SHOP_AUCTION_S)
end

function AuctionBase:onExit(container)
	CurPricesText = ""
	container:removeLibOS()
end
function AuctionBase:getIntPart(x)--取整
   if x <= 0 then
      return math.ceil(x);
   end
   if math.ceil(x) == x then
      x = math.ceil(x);
   else
     x = math.ceil(x) - 1;
   end
   return x;
end
function AuctionBase:refreshPage(container)
	local lb2Str = {
		mSearchTex = common:getLanguageString('@AuctionTip')
	}
	NodeHelper:setStringForLabel(container, lb2Str)
    
    CurPricesText = tostring(self:getIntPart(mAuctionInfo.mCurPrices * DefPricesRate));
	NodeHelper:setStringForTTFLabel(container, { mPrices = CurPricesText})
end

function AuctionBase:OnRefresh(container)
	--PageManager.popPage(thisPageName)

    self:SendMsgPro2Server(container,ShopAuctionType.TYPE_PRICES_REFRESH,0);
end
function AuctionBase:onClose(container)
self:SendMsgPro2Server(container,ShopAuctionType.TYPE_PRICES_REFRESH,0);
	PageManager.popPage(thisPageName)

    
end

function AuctionBase:onReceivePacket(container)

	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.OPCODE_SHOP_AUCTION_S then
		local msg = Shop_pb.AuctionInfoMsgRet()
		msg:ParseFromString(msgBuff)
        --[[	
        type = 1  S反馈：1,2,3,4,5
        type = 2  S反馈：1,3,4,5,6
        type = 3  S反馈：4,5
        required int32 type = 1;//1.初始化 2.参与竞拍 3.刷新价格
	    optional AuctionDrop drop = 2;//竞拍物品信息
	    optional int32 lefttimes = 3;//剩余时间
	    required int32 curprices = 4;//当前最高价格
	    required int32 myprices = 5;//我已竞拍价格
	    optional int32 issucceed = 6;//是否竞拍成功]]--
        CurPricesText = tostring(self:getIntPart(msg.curprices * DefPricesRate));
        NodeHelper:setStringForTTFLabel(container, { mPrices = CurPricesText})
        
        if msg.issucceed == 1 then
           MessageBoxPage:Msg_Box("@AuctionSuccess");
           PageManager.popPage(thisPageName)

        end
	end
end
function AuctionBase:onAuction(container)

	if UserInfo.playerInfo.gold < tonumber(CurPricesText) then
        MessageBoxPage:Msg_Box('@ErrorCode_AHCoin')
        return
	end

    local  strTips = common:getLanguageString("@AuctionConfirmation");
    PageManager.showConfirm("",strTips, function(isSure)
	    if isSure then
		     self:SendMsgPro2Server(container,ShopAuctionType.TYPE_TAKE_AUCTION,tonumber(CurPricesText));
        else
             self:SendMsgPro2Server(container,ShopAuctionType.TYPE_PRICES_REFRESH,0);
		end
	end);
    
end
function AuctionBase:SendMsgPro2Server(container,type,AuctionPrices)
    local msg = Shop_pb.AuctionInfoMsg();
	msg.type = type;
    msg.auctionprices = AuctionPrices;
	local pb_data = msg:SerializeToString();
	container:sendPakcet(opcodes.OPCODE_SHOP_AUCTION_C, pb_data, #pb_data, true);
end
function AuctionBase:onInput(container)
	libOS:getInstance():showInputbox(false,2,CurPricesText)--2 数字键盘
end
function AuctionBase:DisposeNum(container,content)--处理掉用户输入的  "00012356" 中打头的"000"
    local StrNum = content
    local temp;
    for i = 1, string.len(content) do
        temp = string.sub(content,i,i);
        if temp == "0" then
            StrNum = string.sub(content,i+1,string.len(content));
        else
            return StrNum;
        end
    end
    return "";
end
function AuctionBase:onInputboxEnter(container)
    if SteriousAuctionIsClose then--竞拍已关闭
         MessageBoxPage:Msg_Box('@BlackMarketClose') 
         return 
       --PageManager.popPage(thisPageName)
    end
	local content = container:getInputboxContent()
	content = self:DisposeNum(container,content);--处理掉用户输入的  "00012356" 中打头的"000"
	if (not tonumber(content)) then
		MessageBoxPage:Msg_Box('@ErrorCode_AHPrice')
		return 
	end

    if string.len(content) > 9 then --大于九位
        MessageBoxPage:Msg_Box('@AuctionAvaluableRange ') --不在输入范围内
		return 
    end
	local inputNumber = math.floor(tonumber(content))

	-- 检查合法性
	if common:trim(content) == '' then
		MessageBoxPage:Msg_Box('@ErrorCode_AHPrice')
		return
	elseif ( inputNumber < 0) or (inputNumber > MaxPrices) then
		MessageBoxPage:Msg_Box('@AuctionAvaluableRange ') -- --不在输入范围内
		return 
	end

	CurPricesText = tostring(inputNumber)
	NodeHelper:setStringForTTFLabel(container, { mPrices = CurPricesText})
end


local CommonPage = require('CommonPage')
local SteriousAuctionPage= CommonPage.newSub(AuctionBase, thisPageName, option)
