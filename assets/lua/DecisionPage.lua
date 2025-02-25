----------------------------------------------------------------------------------
--[[

--]]
----------------------------------------------------------------------------------

local option = {
    ccbiFile = "GeneralDecisionPopUp.ccbi",
    handlerMap =
    {
        onCancel = "onNo",
        onConfirmation = "onYes",
        onClose = "onClose"
    }
};

local thisPageName = "DecisionPage";
local CommonPage = require("CommonPage");
local DecisionPage = CommonPage.new("DecisionPage", option);
local decisionTitle = "";
local decisionMsg = "";
local decisionCB = nil;
local closeCallback = nil
local autoClose = true;
local showclose = false;
local canClose = true
local isClickBlankClose = true
local scaleX = 1
local decisionYes = "@Confirmation"
local decisionNo = "@Cancel"
local NodeHelper = require("NodeHelper");
local isBuyQues = false
----------------------------------------------------------------------------------
-- DecisionPage????????????
----------------------------------------------
function DecisionPage.onEnter(container)
    DecisionPage.refreshPage(container);
    container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["DecisionPage"] = container
    if GuideManager.isInGuide and GuideManager.getCurrentCfg() and GuideManager.getCurrentCfg().pageName == "DecisionPage" then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function DecisionPage.onExit(container)
    DecisionPage_setDecision("", "", nil);
    container:removeMessage(MSG_MAINFRAME_PUSHPAGE);
end
-- TODO : ????  ---??????map
function DecisionPage.refreshPage(container)
    -- TODO : ????  ---??????map
    --[[    if EFUNSHOWNEWBIE() and Newbie.step ~= 0 and Newbie.step ==  Newbie.getIdByTag("newbie_Battle_BtnLeftAlter") then
        Newbie.show(Newbie.getIdByTag("newbie_Battle_BtnLeftAlter"))
        NodeHelper:setNodeVisible(container:getVarNode("mNewbeeHintNode100"), true)
    end]]
    NodeHelper:setNodesVisible(container, { mBlankCloseNode = isClickBlankClose,mCoin = isBuyQues })

    NodeHelper:setStringForLabel(container, {
        mTitle = decisionTitle,
        -- mDecisionTex 	= common:stringAutoReturn(decisionMsg, 20),		--20: char per line
        mConfirmation = common:getLanguageString(decisionYes),
        mCancel = common:getLanguageString(decisionNo),
    } );
    NodeHelper:setNodeScale(container, "mTitle", scaleX, 1)

    --    local messageTextLabel = container:getVarLabelTTF("mDecisionTex")
    --    messageTextLabel:setString(decisionMsg)
    --    messageTextLabel:setColor(ccc3(149, 17, 20))


    local htmlNode = container:getVarLabelTTF("mDecisionTex")

    if htmlNode then
        local str = decisionMsg or ""
        NodeHelper:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(510, 96), str)
        htmlNode:setVisible(false)

        -- htmlNode:setString(str)
        -- htmlNode:setVisible(true)
    end

    -- local htmlNode = container:getVarLabelTTF("mDecisionTex")
    -- if htmlNode then
    -- 	local str = decisionMsg or ""
    -- 	NodeHelper:setCCHTMLLabelAutoFixPosition( htmlNode, CCSize(510,96),str )
    -- 	htmlNode:setVisible(false)
    -- end

    NodeHelper:setNodesVisible(container, { mButtonDoubleNode = showclose, mButtonMiddleNode = not showclose })
end
--- TODO ?????? ????????
function DecisionPage.onNo(container)
    if decisionCB then
        -- TODO : ????  ---??????map
        --[[        if EFUNSHOWNEWBIE() and Newbie.step ~= 0 and Newbie.step ==  Newbie.getIdByTag("newbie_Battle_BtnLeftAlter") then
            NodeHelper:setNodeVisible(container:getVarNode("mNewbeeHintNode100"), false)
            Newbie.next()
        end]]
        decisionCB(false);
    end
    PageManager.popPage(thisPageName)
end
--- TODO ?????? ????????
-- TODO : ????  ---??????map
function DecisionPage.onYes(container)
    if decisionCB then
        -- TODO : ????  ---??????map
        --[[        if EFUNSHOWNEWBIE() and Newbie.step ~= 0 and Newbie.step ==  Newbie.getIdByTag("newbie_Battle_BtnLeftAlter") then
            NodeHelper:setNodeVisible(container:getVarNode("mNewbeeHintNode100"), false)
            Newbie.next()
        end]]
        decisionCB(true);
    end
    if autoClose then
        PageManager.popPage(thisPageName)
    end
end	
function DecisionPage.onClose(container)
    if canClose then
        if closeCallback then
            closeCallback()
        end
        NodeHelper:setNodesVisible(container, { mBlankCloseNode = true })
        PageManager.popPage(thisPageName)
    end
end	

function DecisionPage.onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_MAINFRAME_PUSHPAGE then
        local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            DecisionPage.refreshPage(container);
        end
    end
end

-------------------------------------------------------------------------------
function DecisionPage_setDecision(title, msg, callback, auto, yes, no, isshowclose, isCanClose, ScaleX, CloseCallback, IsClickBlankClose,_isBuyQues)
    if string.find(title,"@") then
        decisionTitle = common:getLanguageString(title)
    else
        decisionTitle = title;
    end
    if string.find(msg,"@") then
        decisionMsg = common:getLanguageString(msg)
    else
        decisionMsg = msg;
    end
    decisionCB = callback;
    autoClose =(auto or auto == nil) and true or false;
    decisionYes = yes and yes or "@Confirmation"
    decisionNo = no and no or "@Cancel"
    showclose = isshowclose or false;
    canClose =(isCanClose or isCanClose == nil) and true or false;
    scaleX = ScaleX
    closeCallback = CloseCallback
    isClickBlankClose = IsClickBlankClose
    if type(isClickBlankClose) == "nil" then
        isClickBlankClose = true
    end
    isBuyQues = _isBuyQues
end

function DecisionPage_setHtmlDecision(title, htmlMsg, callback, auto, isshowclose, ScaleX)
    decisionTitle = title;
    decisionMsg = htmlMsg;
    decisionCB = callback;
    autoClose =(auto or auto == nil) and true or false;
    htmlTag = true
    scaleX = ScaleX or 1
    closeCallback = nil
    isClickBlankClose = true
end