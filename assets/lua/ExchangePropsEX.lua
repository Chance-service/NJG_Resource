
local option = {
    ccbiFile = "ManyPeopleMapShopBuyWithIconPopUp.ccbi",
    handlerMap =
    {
        onClose = "onNo",
        -- onCancel = "onNo",
        onConfirmation = "onYes",
        onAdd = "onIncrease",
        onAddTen = "onIncreaseTen",
        onReduction = "onDecrease",
        onReductionTen = "onDecreaseTen",
        onHand_1 = "onHand_1",
        onHand_2 = "onHand_2",
    }
}
local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "ExchangePropsEX";
local CommonPage = require("CommonPage")
local NodeHelper = require("NodeHelper")
local _pageData = nil
local _currentCount = 1

local ExchangePropsEXBase = { }
----------------------------------------------------------------------------------
-- ExchangePropsEX页面中的事件处理
----------------------------------------------
function ExchangePropsEXBase:onEnter(container)
    self.container = container
    self:initUi(container)
    self:refreshPage(container);
end

function ExchangePropsEXBase:onExit(container)
    container:removeMessage(MSG_MAINFRAME_PUSHPAGE)
    onUnload(thisPageName, container)
end

function ExchangePropsEXBase:refreshPage(container)
    NodeHelper:setStringForLabel(container, {
        mTitle = common:getLanguageString(titleStr),
    } )
    -- self:refreshResNameIcon(container)
    self:refreshCountAndPrice(container, 0)
end

function ExchangePropsEXBase:initUi(container)
    --   _pageData.maxCount = data.maxCount or 99
    --    _pageData.currentItemData = data.currentItemData
    --    _pageData.targetItemData = data.targetItemData
    --    _pageData.titleStr = data.titleStr or ""
    --    _pageData.errorCode = data.errorCode or ""
    --    _pageData.callBack = data.callBack or nil
    --    _pageData.consumeCount = data.consumeCount or 1
    --    _pageData.exchangeCount = data.exchangeCount or 1

    local resInfo = ResManagerForLua:getResInfoByTypeAndId(_pageData.currentItemData.type, _pageData.currentItemData.itemId, _pageData.currentItemData.count, true)
    NodeHelper:setStringForLabel(container, { mItemCount = resInfo.count })
    NodeHelper:setSpriteImage(container, { mItemIcon = resInfo.icon, mConsumeIcon = resInfo.icon })
    -- , { mItemIcon = 1 }


    self:setItemData(container, _pageData.currentItemData, 1)
    self:setItemData(container, _pageData.targetItemData, 2)
end

function ExchangePropsEXBase:setItemData(container, itemData, index)
    local nodesVisible = { };
    local lb2Str = { };
    local sprite2Img = { };
    local menu2Quality = { };
    local btnSprite = { };
    local scaleMap = { }
    local colorMap = { }

    local countNode = "mNumber"
    local nameNode = "mName"
    local frameNode = "mHand"
    local picNode = "mPic"
    local frameShade = "mFrameShade"
    local showHtml = false
    local i = index
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemData.type, itemData.itemId, itemData.count)
    if resInfo ~= nil then
        sprite2Img[picNode .. i] = resInfo.icon;
        sprite2Img[frameShade .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
        lb2Str[countNode .. i] = "x" .. GameUtil:formatNumber(cfg.count);
        scaleMap[picNode .. i] = 1
        if showHtml then
            NodeHelper:setCCHTMLLabel(container, nameNode .. i, CCSize(130, 96), resInfo.name, true)
        else
            lb2Str[nameNode .. i] = resInfo.name;
        end
        menu2Quality[frameNode .. i] = resInfo.quality;

        colorMap[nameNode .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
    else

    end
    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setColorForLabel(container, colorMap)
end


function ExchangePropsEXBase:refreshCountAndPrice(container, num)
    if _currentCount > _pageData.maxCount then
        _currentCount = _pageData.maxCount
    end
    NodeHelper:setStringForLabel(container, { mConsumeCount = _currentCount * _pageData.consumeCount })
end

function ExchangePropsEXBase:onNo(container)
    if _pageData.callBack then
        _pageData.callBack(false)
    end
    GameUtil:hideClickOtherPage()
    PageManager.popPage(thisPageName)
end

function ExchangePropsEXBase:onYes(container)
    if _pageData.callBack then
        if _currentCount > 0 then
            _pageData.callBack(true, _currentCount)
        end
    end
    if _pageData.autoClose then
        PageManager.popPage(thisPageName)
    end
end	


function ExchangePropsEXBase:onIncrease(container)
    if _currentCount > 0 then
        if _currentCount == _pageData.maxCount then
            MessageBoxPage:Msg_Box_Lan(_pageData.errorMessage)
            return
        end
        _currentCount = _currentCount + 1
        self:refreshCountAndPrice(container, 1)
    end
end


function ExchangePropsEXBase:onDecrease(container)
    if _currentCount <= 1 then
        return
    end
    _currentCount = _currentCount - 1
    self:refreshCountAndPrice(container, -1)
end


function ExchangePropsEXBase:onIncreaseTen(container)
    if _currentCount > 0 then
        if _currentCount >(_pageData.maxCount - 10) then
            MessageBoxPage:Msg_Box_Lan(_pageData.errorMessage)
            _currentCount = _pageData.maxCount
        else
            _currentCount = _currentCount + 10
        end
        self:refreshCountAndPrice(container, 10)
    end
end


function ExchangePropsEXBase:onDecreaseTen(container)
    if _currentCount < 10 then
        _currentCount = 1
    else
        _currentCount = _currentCount - 10
    end
    self:refreshCountAndPrice(container, -10)
end


function ExchangePropsEXBase:onHand_1(container)
    local itemInfo = _pageData.currentItemData
    if not itemInfo then return end
    local rewardItems = { { type = itemInfo.itemInfo, itemId = itemInfo.itemId, count = itemInfo.count } }
    GameUtil:showTip(container:getVarNode('mPic1'), rewardItems)
end

function ExchangePropsEXBase:onHand_2(container)
    local itemInfo = _pageData.targetItemData
    if not itemInfo then return end
    local rewardItems = { { type = itemInfo.itemInfo, itemId = itemInfo.itemId, count = itemInfo.count } }
    GameUtil:showTip(container:getVarNode('mPic2'), rewardItems)
end


function ExchangePropsEXBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_MAINFRAME_PUSHPAGE then
        local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            -- self:refreshPage(container);
        end
    end
end
-------------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local ExchangePropsEX = CommonPage.newSub(ExchangePropsEXBase, thisPageName, option);
-------------------------------------------------------------------------------
function ExchangePropsEX_show(type, id, currencyType, priceFunc, callback, auto, max, title, notEnoughStr, totalRes, desc)
    resType = type >= 10000 and math.floor(type / 10000) or type
    resId = id
    priceType = currencyType or ConsumeMoneyType.MONEY_GOLD
    priceGetter = priceFunc or nil
    decisionCB = callback
    autoClose = auto or true
    maxCount = max or 999
    itemType = 0
    totalResNum = totalRes or -1
    titleStr = title or "@ExchangeCountTitle";
    errorMessage = notEnoughStr or "@ERRORCODE_155"
    titleDesc = desc or common:getLanguageString("@DecisionTex")
    PageManager.pushPage(thisPageName);
end

function ExchangePropsEX_setData(data)
    _currentCount = 1

    _pageData.maxCount = data.maxCount or 99
    _pageData.currentItemData = data.currentItemData
    _pageData.targetItemData = data.targetItemData
    _pageData.titleStr = data.titleStr or ""
    _pageData.errorMessage = data.errorMessage or ""
    _pageData.callBack = data.callBack or nil
    _pageData.consumeCount = data.consumeCount or 1
    _pageData.exchangeCount = data.exchangeCount or 1
    _pageData.autoClose = data.autoClose or true
    PageManager.pushPage(thisPageName)
end

