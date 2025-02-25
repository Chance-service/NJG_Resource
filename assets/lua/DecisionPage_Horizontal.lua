----------------------------------------------------------------------------------
--[[

--]]
----------------------------------------------------------------------------------

local option = {
    ccbiFile = "GeneralDecisionPopUp_Horizontal.ccbi",
    handlerMap =
    {
        onCancel = "onNo",
        onConfirmation = "onYes",
        onClose = "onClose"
    }
};

local thisPageName = "DecisionPage_Horizontal";
local CommonPage = require("CommonPage");
local DecisionPageHorizontal = CommonPage.new("DecisionPage_Horizontal", option);
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
----------------------------------------------------------------------------------
-- DecisionPage????????????
----------------------------------------------
function DecisionPageHorizontal.onEnter(container)
    DecisionPageHorizontal.refreshPage(container);
    container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
end

function DecisionPageHorizontal.onExit(container)
    DecisionPage_Horizontal_setDecision("", "", nil);
    container:removeMessage(MSG_MAINFRAME_PUSHPAGE);
end
-- TODO : ????  ---??????map
function DecisionPageHorizontal.refreshPage(container)
    -- TODO : ????  ---??????map
    --[[    if EFUNSHOWNEWBIE() and Newbie.step ~= 0 and Newbie.step ==  Newbie.getIdByTag("newbie_Battle_BtnLeftAlter") then
        Newbie.show(Newbie.getIdByTag("newbie_Battle_BtnLeftAlter"))
        NodeHelper:setNodeVisible(container:getVarNode("mNewbeeHintNode100"), true)
    end]]
    NodeHelper:setNodesVisible(container, { mBlankCloseNode = isClickBlankClose })

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
function DecisionPageHorizontal.onNo(container)
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
function DecisionPageHorizontal.onYes(container)
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
function DecisionPageHorizontal.onClose(container)
    if canClose then
        if closeCallback then
            closeCallback()
        end
        NodeHelper:setNodesVisible(container, { mBlankCloseNode = true })
        PageManager.popPage(thisPageName)
    end
end	

function DecisionPageHorizontal.onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_MAINFRAME_PUSHPAGE then
        local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            DecisionPageHorizontal.refreshPage(container);
        end
    end
end

-------------------------------------------------------------------------------
function DecisionPage_Horizontal_setDecision(title, msg, callback, auto, yes, no, isshowclose, isCanClose, ScaleX, CloseCallback, IsClickBlankClose)
    decisionTitle = title;
    decisionMsg = msg;
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
end

function DecisionPage_Horizontal_setHtmlDecision(title, htmlMsg, callback, auto, isshowclose, ScaleX)
    decisionTitle = title;
    decisionMsg = htmlMsg;
    decisionCB = callback;
    autoClose =(auto or auto == nil) and true or false;
    htmlTag = true
    scaleX = ScaleX or 1
    closeCallback = nil
    isClickBlankClose = true
end