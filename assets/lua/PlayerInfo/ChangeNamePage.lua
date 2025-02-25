----------------------------------------------------------------------------------
-- �����������
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "ChangeNamePage"

local inputName = ""

local opcodes = {
    ROLE_CHANGE_NAME_C = HP_pb.ROLE_CHANGE_NAME_C,
    ROLE_CHANGE_NAME_S = HP_pb.ROLE_CHANGE_NAME_S
}

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
    opcode = opcodes
};

local ChangeNamePageBase = { }
----------------------------------------------------------------------------------

local idInput = ''

local isUseItem = false

function ChangeNamePageBase:onEnter(container)
    self:registerPacket(container)
    self:refreshPage(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    UserInfo.sync()

    CCLuaLog("ChangeNamePageBase ----")

    --[[
    container:getVarLabelBMFont("mConsumptionNum"):setString( GameConfig.ChangeNameCost )
    if UserInfo.playerInfo.gold < GameConfig.ChangeNameCost then
        container:getVarLabelBMFont("mConsumptionNum"):setColor(NodeHelper:_getColorFromSetting(GameConfig.ColorMap.COLOR_RED))
    else
        container:getVarLabelBMFont("mConsumptionNum"):setColor(NodeHelper:_getColorFromSetting(GameConfig.ColorMap.COLOR_GREEN))
    end--]]
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
        ChangeNamePageBase.editBox = NodeHelper:addEditBox(CCSize(470, 40), container:getVarNode("mDecisionTex"), function(eventType)
            if eventType == "began" then
                -- NodeHelper:cursorNode(container,"mDecisionTex",true)
                -- triggered when an edit box gains focus after keyboard is shown
            elseif eventType == "ended" then
                ChangeNamePageBase.onEditBoxReturn(container, ChangeNamePageBase.editBox, ChangeNamePageBase.editBox:getText())
                --                NodeHelper:cursorNode(container,"mDecisionTex",false)
                -- triggered when an edit box loses focus after keyboard is hidden.
            elseif eventType == "changed" then
                -- NodeHelper:cursorNode(container,"mDecisionTex",true)
                ChangeNamePageBase.onEditBoxReturn(container, ChangeNamePageBase.editBox, ChangeNamePageBase.editBox:getText(), true)
                -- NodeHelper:cursorNode(container,"mDecisionTex",true)
                -- NodeHelper:setNodesVisible(container, {mDecisionTexHint = false})
                -- triggered when the edit box text was changed.
            elseif eventType == "return" then
                ChangeNamePageBase.onEditBoxReturn(container, ChangeNamePageBase.editBox, ChangeNamePageBase.editBox:getText())
                -- triggered when the return button was pressed or the outside area of keyboard was touched.
            end
        end , ccp(-235, 0), "")
        container:getVarNode("mDecisionTex"):setVisible(false)
        container:getVarNode("mDecisionTexHint"):setVisible(false)
        container:getVarNode("mDecisionTex"):setPosition(ccp(0, -340))
        container:getVarNode("mDecisionTex"):setAnchorPoint(ccp(0.5, 0.5))
        NodeHelper:setStringForTTFLabel(container, { mDecisionTex = "" })

        local color = StringConverter:parseColor3B("135 54 38")
        ChangeNamePageBase.editBox:setFontColor(color)

        ChangeNamePageBase.editBox:setText("")
        ChangeNamePageBase.editBox:setMaxLength(GameConfig.WordSizeLimit.RoleNameLimit)
        NodeHelper:setMenuItemEnabled(container, "mInputBtn", true)
        NodeHelper:setNodesVisible(container, { mDecisionTexHint = true })
        CCLuaLog("ChangeNamePageBase ---step2-")
    else
        --[[NodeHelper:setStringForLabel(container,{
            mDecisionTexHint = UserInfo.roleInfo.name
        })  ]]
        --
    end
    -- inputName = UserInfo.roleInfo.name
    inputName = ""
end

function ChangeNamePageBase:refreshPage(container)
    local UserItemManager = require("Item.UserItemManager");
    local cardItem = UserItemManager:getUserItemByItemId(GameConfig.ChangeNameCardId)
    local num = cardItem and cardItem.count or 0
    local isShow = yuan3(num == 0,true,false )
    NodeHelper:setNodesVisible(container,{mTishiNode = isShow })
    NodeHelper:setNodesVisible(container, { mFriendSearch = false, mSearch = false })
    NodeHelper:setStringForLabel(container, {
        -- mCardNum = "x" .. num
        mCardNum = ""
    } )
end

function ChangeNamePageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "PackagePage" then
            self:refreshPage(container)
        end
    end
end

function ChangeNamePageBase:onExit(container)
    isUseItem = false
    idInput = ''
    container:removeLibOS()
    self:removePacket(container)
    debugPage[thisPageName] = true
    onUnload(thisPageName, container)
end
function ChangeNamePageBase.onEditBoxReturn(container, editBox, content, isChange)
    local length = GameMaths:calculateStringCharacters(content);
    if length > GameConfig.WordSizeLimit.RoleNameLimit then
        -- ��ʾ��������
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
    -- if not nameOK then
    -- 	MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
    -- 	content = nil
    -- 	return
    -- end

    inputName = content;

    if editBox ~= nil and not isChange then
        if not nameOK then
            MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
            content = nil
            inputName = nil
            return
        end
        editBox:setText(tostring(inputName))
    end
    NodeHelper:setStringForTTFLabel(container, { mDecisionTex = tostring(inputName) })
    NodeHelper:setNodesVisible(container, { mDecisionTexHint = false })
end
function ChangeNamePageBase:onInput(container)

    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then

    else
        container:registerLibOS()
        if inputName == "" then
            NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
        else
            NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
        end
        libOS:getInstance():showInputbox(false, inputName)
    end
    
    -- NodeHelper:cursorNode(container,"mDecisionTex",true)
end
function ChangeNamePageBase:onInputChange(container)
    local contentLabel = container:getVarLabelTTF("mDecisionTex");
    local content = container:getInputboxContent();


    inputName = content;
    if contentLabel ~= nil then
        contentLabel:setString(tostring(inputName));
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
    end

end
function ChangeNamePageBase:InputDone(container)
    local contentLabel = container:getVarLabelTTF("mDecisionTex");
    local content = container:getInputboxContent()

    if content == "" then
        inputName = ""
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
        contentLabel:setString("");
        return;
    end
    local length = GameMaths:calculateStringCharacters(content);
    if length > GameConfig.WordSizeLimit.RoleNameLimit then
        -- ��ʾ��������
        MessageBoxPage:Msg_Box_Lan("@NameExceedLimit");
        libOS:getInstance():setEditBoxText(idInput);
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
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        content = nil
        contentLabel:setString("");
        idInput = ""
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
        return
    end
    idInput = content
    inputName = content;
    if contentLabel ~= nil then
        contentLabel:setString(tostring(inputName));
        NodeHelper:setNodesVisible(container, { mDecisionTexHint = false })
        NodeHelper:setStringForLabel(container, { mDecisionTexHint = "" })
    end
end
function ChangeNamePageBase:onInputboxEnter(container)
    self:InputDone(container);
    NodeHelper:cursorNode(container, "mDecisionTex", true)
end
function ChangeNamePageBase:luaonCloseKeyboard(container)
    CCLuaLog(" ChangeNamePageBase:luaonCloseKeyboard")
    NodeHelper:cursorNode(container, "mDecisionTex", false)
end
function ChangeNamePageBase:onConfirmation(container)
    UserInfo.sync()
    if GameMaths:calculateStringCharacters(inputName) <= 0 then
        MessageBoxPage:Msg_Box_Lan("@NotInputName")
        return
    end

    if GameMaths:calculateStringCharacters(inputName) > GameConfig.WordSizeLimit.RoleNameLimit then
        MessageBoxPage:Msg_Box_Lan("@NameExceedLimit")
        return
    end

    if inputName == UserInfo.roleInfo.name then
        MessageBoxPage:Msg_Box_Lan("@NameRepeat")
        return
    end
    local UserItemManager = require("Item.UserItemManager");
    local cardItem = UserItemManager:getUserItemByItemId(101004)
    local num = cardItem and cardItem.count or 0
    if num <= 0 and UserInfo.playerInfo.gold < GameConfig.ChangeNameCost then
        --PageManager.showConfirm(common:getLanguageString("@HintTitle"),
        --common:getLanguageString("@LackGold"),
        --function(isOK)
        --    if isOK then
        --        PageManager.pushPage('RechargePage')
        --    end
        --end )
        MessageBoxPage:Msg_Box_Lan("@ERRORCODE_14")
        return
    else
        if num > 0 then
            PageManager.showConfirm(common:getLanguageString("@HintTitle"),
            common:getLanguageString("@ChangeNameCostCard"),
            function(isOK)
                if isOK then
                    local msg = Player_pb.HPChangeRoleName()
                    msg.name = inputName
                    common:sendPacket(opcodes.ROLE_CHANGE_NAME_C, msg)
                end
            end )
        else
            PageManager.showConfirm(common:getLanguageString("@HintTitle"),
            string.gsub(common:getLanguageString("@ChangeNameCost"), "#v1#", GameConfig.ChangeNameCost),
            function(isOK)
                if isOK then
                    local msg = Player_pb.HPChangeRoleName()
                    msg.name = inputName
                    common:sendPacket(opcodes.ROLE_CHANGE_NAME_C, msg)
                end
            end )
        end
    end


end

function ChangeNamePageBase:onCancel(container)
    PageManager.popPage(thisPageName)
end

function ChangeNamePageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.ROLE_CHANGE_NAME_S then
        UserInfo.sync()
        MessageBoxPage:Msg_Box_Lan("@ChangeNameSuccess")
        inputName = ""
        PageManager.refreshPage("PlayerInfoPage")
        PageManager.popPage(thisPageName)
    end

end

function ChangeNamePageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ChangeNamePageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ChangeNamePageBase_SetIsUseItem(isUse)
    isUseItem = isUse
end

----------------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local ChangeNamePage = CommonPage.newSub(ChangeNamePageBase, thisPageName, option);