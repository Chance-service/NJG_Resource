
local option = {
	ccbiFile = "ManyPeopleMapShopBuyPopUp.ccbi",
	handlerMap = {
        onClose         = "onNo",
		onCancel		= "onNo",
		onConfirmation 	= "onYes",
        onAdd      = "onIncrease",
        onAddTen      = "onIncreaseTen",
        onReduction      = "onDecrease",
        onReductionTen      = "onDecreaseTen",
	}
};
local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "CommonCountTimesPage";
local CommonPage = require("CommonPage");
local decisionTitle = "";
local decisionMsg = "";
local decisionCB = nil;
local autoClose = true;
local maxCount = 100;
local priceGetter = nil;
local curCount = 1;
local priceType = Const_pb.MONEY_GOLD
local isExchangeGoldBean = false
local mMultiple = 1
local NodeHelper = require("NodeHelper");
local CommonCountTimesPageBase = {}
local maxTxt = nil
local mIsShow = nil
----------------------------------------------------------------------------------
--CountTimesPage页面中的事件处理
----------------------------------------------
function CommonCountTimesPageBase:onEnter(container)
    curCount = 1*mMultiple;
	self:refreshPage(container);
	container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
end

function CommonCountTimesPageBase:onExit(container)
	container:removeMessage(MSG_MAINFRAME_PUSHPAGE);
    maxTxt = nil
end

function CommonCountTimesPageBase:refreshPage(container)
	NodeHelper:setStringForLabel(container, {
		mTitle 			= decisionTitle,
		mDecisionTex 	= common:stringAutoReturn(decisionMsg, 20),		--20: char per line
       -- mReduceNum      = "<<",
        --mTopNum         = ">>"
	});
    self:refreshCountAndPrice(container)
end

function CommonCountTimesPageBase:refreshCountAndPrice(container)
    if curCount > maxCount then
        local remainder = maxCount % mMultiple
        curCount = maxCount - remainder
    end
    if priceGetter==nil then
        NodeHelper:setNodesVisible(container,{mCostGoldLab=false ,mCostGoldNum = false})
        NodeHelper:setStringForLabel(container,{mAddNum = curCount})
        return
    end

	local totalPrice = priceGetter(curCount)
    local priceMsg = ""
	local sprite2Img = {}
    local priceColor = GameConfig.ColorMap.COLOR_WHITE
    if priceType == Const_pb.MONEY_GOLD then
        priceMsg = common:getLanguageString("@CostGold1")
        if totalPrice>UserInfo.playerInfo.gold then
            priceColor = GameConfig.ColorMap.COLOR_RED
        end
		sprite2Img["mIconPic"] = GameConfig.DiamondImage
    elseif priceType == Const_pb.MONEY_COIN then
        priceMsg = common:getLanguageString("@CostCoin1")
        if totalPrice>UserInfo.playerInfo.coin then
            priceColor = GameConfig.ColorMap.COLOR_RED
        end
		sprite2Img["mIconPic"] = GameConfig.GoldImage
    end
	
    if mIsShow then
        NodeHelper:setSpriteImage(container,sprite2Img)
        NodeHelper:setStringForLabel(container,{mCostGoldLab=common:getLanguageString("@GemCostGold") ,mCostGoldNum = totalPrice..priceMsg,mAddNum = curCount})
    else
        NodeHelper:setNodesVisible(container,{mCostGoldLab=false, mIconPic = false, mCostGoldNum = false})
        NodeHelper:setStringForLabel(container,{mAddNum = curCount})
    end
    --NodeHelper:setColorForLabel(container,{mCostGoldNum=priceColor})

end

function CommonCountTimesPageBase:setLabelVisible(container, strMap, isShow)
    for name, str in pairs(strMap) do
        local node = container:getVarLabelBMFont(name)
        if node then
            node:setVisible( isShow )
        else
            local nodeTTF=container:getVarLabelTTF(name)
            if nodeTTF then
                nodeTTF:setVisible( isShow )
            else
                -- CCLuaLog("NodeHelper:setStringForLabel====>" .. name)        
            end
            
        end
    end
end

function CommonCountTimesPageBase:onNo(container)
	if decisionCB then
		decisionCB(false);
	end
	PageManager.popPage(thisPageName)
end

function CommonCountTimesPageBase:onYes(container)
	if decisionCB then
        if curCount>0 then
		    decisionCB(true,curCount/mMultiple);
        end
	end
	if autoClose then
		PageManager.popPage(thisPageName)
	end
end	

function CommonCountTimesPageBase:onIncrease(container)
    self:onChangeCount(1,container);
end

function CommonCountTimesPageBase:onDecrease(container)
    self:onChangeCount(-1,container);
end

function CommonCountTimesPageBase:onIncreaseTen(container)
    self:onChangeCount(10,container);
end

function CommonCountTimesPageBase:onDecreaseTen(container)
    self:onChangeCount(-10,container);
end

function CommonCountTimesPageBase:onChangeCount(num,container)
    local remainder = maxCount % mMultiple
    curCount = curCount + num*mMultiple
    if curCount>maxCount then
        if maxTxt then 
             MessageBoxPage:Msg_Box_Lan(maxTxt)
        else
            if isExchangeGoldBean then
                 MessageBoxPage:Msg_Box_Lan("@YaYaBuyCountLimit")
            else
                 MessageBoxPage:Msg_Box_Lan("@BuyCountLimit")
            end
        end
        curCount = maxCount - remainder
    elseif curCount<1*mMultiple then
        curCount = 1*mMultiple
    end

    self:refreshCountAndPrice(container)
end


function CommonCountTimesPageBase:onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();
	if typeId == MSG_MAINFRAME_PUSHPAGE then
		local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			self:refreshPage(container);
		end
	end
end
-------------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local CommonCountTimesPage = CommonPage.newSub(CommonCountTimesPageBase, thisPageName, option);
-------------------------------------------------------------------------------
function CommonCountTimesPage_show(title,msg,max,priceFunc,priType,callback,auto ,aIsExchangeGoldBean, _maxTxt, multiple, isShow)
    decisionTitle = title or common:getLanguageString("@BuyCountTitle")
    decisionMsg   = msg or common:getLanguageString("@BuyCountMsg",15,100)
    priceGetter = priceFunc or nil
    maxCount = max or 100
    decisionCB = callback 
    priceType = priType or Const_pb.MONEY_GOLD
    autoClose = auto or true
    maxTxt = _maxTxt
    mIsShow = isShow
    if aIsExchangeGoldBean then
        isExchangeGoldBean = true
        option.ccbiFile = "GirlLiveRechargePopUp"    
    end
    if multiple and multiple > 0 then
        mMultiple = multiple
    end
    PageManager.pushPage(thisPageName);
end