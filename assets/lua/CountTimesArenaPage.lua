local option = {
	ccbiFile = "ArenaAddChallengesPopUp.ccbi",
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
local thisPageName = "CountTimesArenaPage"
local CommonPage = require("CommonPage")
local decisionTitle = ""
local decisionMsg = ""
local decisionCB = nil
local autoClose = true
local maxCount = 100
local priceGetter = nil
local curCount = 1
local priceType = Const_pb.MONEY_GOLD
local isExchangeGoldBean = false
local mMultiple = 1
local NodeHelper = require("NodeHelper")
local CountTimesArenaPageBase = { }
local maxTxt = nil
local offset = 10
----------------------------------------------------------------------------------
--CountTimesPage页面中的事件处理
----------------------------------------------
function CountTimesArenaPageBase:onEnter(container)
    curCount = 1 * mMultiple
	self:refreshPage(container)
    self:refreshBtn(container)
	container:registerMessage(MSG_MAINFRAME_PUSHPAGE)
end

function CountTimesArenaPageBase:onExit(container)
	container:removeMessage(MSG_MAINFRAME_PUSHPAGE)
    maxTxt = nil
end

function CountTimesArenaPageBase:refreshPage(container)
	NodeHelper:setStringForLabel(container, {
		mTitle 			= decisionTitle,
		mDecisionTex 	= decisionMsg--common:stringAutoReturn(decisionMsg, 20),		--20: char per line
        --mReduceNum      = "<<",
        --mTopNum         = ">>"
	})
    self:refreshCountAndPrice(container)
end

function CountTimesArenaPageBase:refreshBtn(container)
    local canAdd = true
    local canAddTen = true
    local canMinus = true
    local canMinusTen = true
    local canConfirm = true
    if curCount >= maxCount then
        canAdd = false
        canAddTen = false
    end
    if curCount <= 1 * mMultiple then
        canMinus = false
        canMinusTen = false
    end
    local nextPrice = priceGetter(curCount + 1)
    local nowPrice = priceGetter(curCount)
    if priceType == Const_pb.MONEY_GOLD then
        if nextPrice > UserInfo.playerInfo.gold then
            canAdd = false
            canAddTen = false
        end
        if nowPrice > UserInfo.playerInfo.gold then
            canAdd = false
            canAddTen = false
            canConfirm = false
        end
    elseif priceType == Const_pb.MONEY_COIN then
        if nextPrice > UserInfo.playerInfo.coin then
            canAdd = false
            canAddTen = false
        end
        if nowPrice > UserInfo.playerInfo.coin then
            canAdd = false
            canAddTen = false
            canConfirm = false
        end
    end
    NodeHelper:setMenuItemsEnabled(container, { mAddBtn = canAdd, mAddTenBtn = canAddTen, 
                                                mReductionBtn = canMinus, mReductionTenBtn = canMinusTen,
                                                mConfirmationBtn = canConfirm })
end

function CountTimesArenaPageBase:refreshCountAndPrice(container)
    if curCount > maxCount then
        curCount = maxCount
    end
    if priceGetter == nil then
        NodeHelper:setNodesVisible(container, { mCostGoldLab = false, mCostGoldNum = false })
        NodeHelper:setStringForLabel(container, { mAddNum = curCount })
        return
    end
	local totalPrice = priceGetter(curCount)
    if priceType == Const_pb.MONEY_GOLD then
        if totalPrice > UserInfo.playerInfo.gold then
            for i = curCount - 1, 1, -1 do
                totalPrice = priceGetter(i)
                if totalPrice <= UserInfo.playerInfo.gold then
                    curCount = i
                    break
                end
            end
        end
    elseif priceType == Const_pb.MONEY_COIN then
        if totalPrice > UserInfo.playerInfo.coin then
            for i = curCount - 1, 1, -1 do
                totalPrice = priceGetter(i)
                if totalPrice <= UserInfo.playerInfo.coin then
                    curCount = i
                    break
                end
            end
        end
    end
    local priceMsg = ""
	local sprite2Img = {}
    if priceType == Const_pb.MONEY_GOLD then
        priceMsg = common:getLanguageString("@CostGold1")
		--sprite2Img["mIconPic"] = GameConfig.DiamondImage
    elseif priceType == Const_pb.MONEY_COIN then
        priceMsg = common:getLanguageString("@CostCoin1")
		--sprite2Img["mIconPic"] = GameConfig.GoldImage
    end

    --..priceMsg,mAddNum = curCount
	NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setStringForLabel(container, { mCostGoldLab = common:getLanguageString("@GemCostGold"), mCostGoldNum = totalPrice, mAddNum = curCount })
end

function CountTimesArenaPageBase:onNo(container)
	if decisionCB then
		decisionCB(false)
	end
	PageManager.popPage(thisPageName)
end

function CountTimesArenaPageBase:onYes(container)
	if decisionCB then
        if curCount > 0 then
		    decisionCB(true,curCount)
        end
	end
	if autoClose then
		PageManager.popPage(thisPageName)
	end
end	

function CountTimesArenaPageBase:onIncrease(container)
    if curCount == maxCount then
        MessageBoxPage:Msg_Box_Lan("@BuyCountLimit")
        return
    end
    curCount = curCount + 1 * mMultiple
    self:refreshCountAndPrice(container)
    self:refreshBtn(container)
end

function CountTimesArenaPageBase:onDecrease(container)
    if curCount <= 1 then
        return
    end
    curCount = curCount - 1 * mMultiple
    self:refreshCountAndPrice(container)
    self:refreshBtn(container)
end

function CountTimesArenaPageBase:onIncreaseTen(container)
    if curCount > (maxCount - offset * mMultiple) then
        if maxTxt then 
             MessageBoxPage:Msg_Box_Lan(maxTxt)
        else
            if isExchangeGoldBean then
                 MessageBoxPage:Msg_Box_Lan("@YaYaBuyCountLimit")
            else
                 MessageBoxPage:Msg_Box_Lan("@BuyCountLimit")
            end
        end
        curCount = maxCount
    else
        curCount = curCount + offset * mMultiple
    end
    self:refreshCountAndPrice(container)
    self:refreshBtn(container)
end

function CountTimesArenaPageBase:onDecreaseTen(container)
    if curCount <= offset * mMultiple then
        curCount = 1 * mMultiple
    else
        curCount = curCount - offset * mMultiple
    end
    self:refreshCountAndPrice(container)
    self:refreshBtn(container)
end

function CountTimesArenaPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_PUSHPAGE then
		local pageName = MsgMainFramePushPage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:refreshPage(container)
		end
	end
end
-------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local CountTimesArenaPage = CommonPage.newSub(CountTimesArenaPageBase, thisPageName, option)
-------------------------------------------------------------------------------
function CountTimesArenaPage_show(title, msg, max, priceFunc, priType, callback, auto, aIsExchangeGoldBean, _maxTxt, _offset)
    decisionTitle = title or common:getLanguageString("@BuyCountTitle")
    decisionMsg = msg or common:getLanguageString("@BuyCountMsg", 15, 100)
    priceGetter = priceFunc or nil
    maxCount = max or 100
    decisionCB = callback 
    priceType = priType or Const_pb.MONEY_GOLD
    autoClose = auto or true
    maxTxt = _maxTxt
    offset = _offset or 10
    PageManager.pushPage(thisPageName)
    if aIsExchangeGoldBean then
        isExchangeGoldBean = true
        option.ccbiFile = "GirlLiveRechargePopUp"    
        mMultiple = 10
    end
end