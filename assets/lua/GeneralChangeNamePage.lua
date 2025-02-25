
local NodeHelper = require("NodeHelper")
local thisPageName = "GeneralChangeNamePage"

local inputName = ""
local option = {
    ccbiFile = "ChangeNamePopUp.ccbi",
    handlerMap =
    {
        onCancel = "onCancel",
        onClose = "onCancel",
        onConfirmation = "onConfirmation",
        onInPutBtn = "onInput",
        luaInputboxEnter = 'onInputboxEnter',
        luaonCloseKeyboard = "luaonCloseKeyboard"
    },
    opcode = { }
};

local GeneralChangeNamePage = { }
local mStrTitle = "";
local mStrDesc = "";
local mStrDefaultTxt = "";
local mCallbackFunc = nil;
----------------------------------------------------------------------------------
function GeneralChangeNamePage:onEnter(container)
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
        GeneralChangeNamePage.editBox = NodeHelper:addEditBox(CCSize(470, 40), container:getVarNode("mDecisionTex"), function(eventType)
            if eventType == "began" then
                --NodeHelper:cursorNode(container, "mDecisionTex", true)
                -- triggered when an edit box gains focus after keyboard is shown
            elseif eventType == "ended" then
                GeneralChangeNamePage.onEditBoxReturn(container, GeneralChangeNamePage.editBox, GeneralChangeNamePage.editBox:getText())
                --NodeHelper:cursorNode(container, "mDecisionTex", false)
                -- triggered when an edit box loses focus after keyboard is hidden.
            elseif eventType == "changed" then
                GeneralChangeNamePage.onEditBoxReturn(container, GeneralChangeNamePage.editBox, GeneralChangeNamePage.editBox:getText(), true)
                --NodeHelper:cursorNode(container, "mDecisionTex", true)
                -- triggered when the edit box text was changed.
            elseif eventType == "return" then
                GeneralChangeNamePage.onEditBoxReturn(container, GeneralChangeNamePage.editBox, GeneralChangeNamePage.editBox:getText())
                -- triggered when the return button was pressed or the outside area of keyboard was touched.
            end
        end , ccp(-235, -0), common:getLanguageString("@ChangeNameTex"))
        container:getVarNode("mDecisionTex"):setVisible(false)
        container:getVarNode("mDecisionTexHint"):setVisible(false)
        container:getVarNode("mDecisionTex"):setPosition(ccp(0, -171))
        container:getVarNode("mDecisionTex"):setAnchorPoint(ccp(0.5, 0.5))
        local color = StringConverter:parseColor3B("135 54 38")
        GeneralChangeNamePage.editBox:setFontColor(color)
        GeneralChangeNamePage.editBox:setText("")

        NodeHelper:setStringForTTFLabel(container, { mDecisionTex = "" })
        GeneralChangeNamePage.editBox:setText("")
        GeneralChangeNamePage.editBox:setMaxLength(GameConfig.WordSizeLimit.RoleNameLimit)
        NodeHelper:setMenuItemEnabled(container, "mInputBtn", true)
        NodeHelper:setNodesVisible(container, { mDecisionTexHint = false })
    end


    inputName = mStrDefaultTxt;
    self:refreshPage(container);
end

function GeneralChangeNamePage:refreshPage(container)
    NodeHelper:setNodesVisible(container, { mFriendSearch = false, mSearch = false })
    NodeHelper:setNodesVisible(container, { mChangeNameNode = false, mTxt = false });
    NodeHelper:setStringForLabel(container, { mTitle = mStrTitle, mDes = mStrDesc, mDecisionTex = mStrDefaultTxt });
    NodeHelper:setNodeScale(container, "mTitle", mTtileScale, mTtileScale)
end


function GeneralChangeNamePage:onExit(container)
    container:removeLibOS();
    onUnload(thisPageName, container);
    mStrTitle = "";
    mStrDesc = "";
    mStrDefaultTxt = "";
    mCallbackFunc = nil;
    mTtileScale = 1
end

function GeneralChangeNamePage.onEditBoxReturn(container, editBox, content, isChange)
    local length = GameMaths:calculateStringCharacters(content);
    if length > GameConfig.WordSizeLimit.RoleNameLimit then
        -- 提示名字字数
        MessageBoxPage:Msg_Box_Lan("@NameExceedLimit");
        return;
    end

    local nameOK = true
    if GameMaths:isStringHasUTF8mb4(content) then
        nameOK = false
    end
    if not RestrictedWord:getInstance():isStringOK(content) then
        nameOK = false
    end
    -- if content == "" then
    -- nameOK = false
    -- end
    if not nameOK then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        editBox:setText(tostring(inputName))
        content = inputName
        -- return
    end

    inputName = content;

    if editBox ~= nil and not isChange then
        editBox:setText(tostring(inputName))
    end
    NodeHelper:setStringForTTFLabel(container, { mDecisionTex = tostring(inputName) })
end

function GeneralChangeNamePage:onInput(container)
    container:registerLibOS()
    if inputName == "" then
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
    else
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
    end
    libOS:getInstance():showInputbox(false, inputName)
end

function GeneralChangeNamePage:InputDone(container)
    local contentLabel = container:getVarLabelTTF("mDecisionTex");
    local content = container:getInputboxContent();
    content = common:trimAll(content);
    if content == "" then
        inputName = ""
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
        contentLabel:setString("");
        return;
    end
    local length = GameMaths:calculateStringCharacters(content);
    if length > GameConfig.WordSizeLimit.RoleNameLimit then
        -- 提示名字字数
        MessageBoxPage:Msg_Box_Lan("@NameExceedLimit");
        libOS:getInstance():setEditBoxText(inputName)
        return;
    end
    local nameOK = true
    if GameMaths:isStringHasUTF8mb4(content) then
        nameOK = false
    end
    if not RestrictedWord:getInstance():isStringOK(content) then
        nameOK = false
    end
    if not nameOK then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar");
        libOS:getInstance():setEditBoxText(inputName)
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
        content = inputName
    end

    inputName = content;
    if contentLabel ~= nil then
        contentLabel:setString(tostring(inputName));
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
    end
end

function GeneralChangeNamePage:onInputboxEnter(container)
    CCLuaLog(" GeneralChangeNamePage:onInputboxEnter")
    self:InputDone(container);
    NodeHelper:cursorNode(container, "mDecisionTex", true)
end

function GeneralChangeNamePage:luaonCloseKeyboard(container)
    CCLuaLog(" GeneralChangeNamePage:luaonCloseKeyboard")
    NodeHelper:cursorNode(container, "mDecisionTex", false)
end

function GeneralChangeNamePage:onConfirmation(container)
    if mCallbackFunc then
        mCallbackFunc(inputName);
    end
    PageManager.popPage(thisPageName)
end

function GeneralChangeNamePage:onCancel(container)
    PageManager.popPage(thisPageName)
end

function SetInputBoxInfo(title, desc, defaultTxt, callbackfunc , titleScale)
    mStrTitle = title or "";
    mStrDesc = desc or "";
    mStrDefaultTxt = defaultTxt or "";
    mCallbackFunc = callbackfunc;
    mTtileScale = titleScale or 1
end

----------------------------------------------------------------------------------
local CommonPage = require("CommonPage");
GeneralChangeNamePage = CommonPage.newSub(GeneralChangeNamePage, thisPageName, option);