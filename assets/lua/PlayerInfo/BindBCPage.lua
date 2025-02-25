local NodeHelper = require("NodeHelper")
require "HttpBridge"
local thisPageName = "BindBCPage"
local BindBCPageInfo = { container = nil }       -- all ui information
local InputTag ={
    INPUT_EMAIL = 1,
    INPUT_CODE = 2
}
local mInputType = -1
local USER_LEN_LIMIT = 255
local PWD_LEN_LIMIT = 12
local newAccount = ""

local option = {
    ccbiFile = "LoginReturnPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onSendCode = "onSendCode",
        onBindBC = "onBindBC",
        onEMailContent = "onEMailContent",
        onCodeContent = "onCodeContent",
        luaInputboxEnter = 'onInputboxEnter',
        luaonCloseKeyboard = "luaonCloseKeyboard"
    },
    opcodes = {
        ACCOUNT_BOUND_REWARD_C = HP_pb.ACCOUNT_BOUND_REWARD_C,
        ACCOUNT_BOUND_REWARD_S = HP_pb.ACCOUNT_BOUND_REWARD_S
 --       SYNC_LEVEL_INFO_C = HP_pb.SYNC_LEVEL_INFO_C,
 --       SYNC_LEVEL_INFO_S = HP_pb.SYNC_LEVEL_INFO_S,
 --      TAKE_FIGHT_AWARD_C = HP_pb.TAKE_FIGHT_AWARD_C,
 --       TAKE_FIGHT_AWARD_S = HP_pb.TAKE_FIGHT_AWARD_S,
    }
}

local mStrEmail = ""
local mStrCode = ""
local EMT_SendCode = "EMT_SendCode"
local EMT_BindGame = "EMT_BindGame"

function BindBCPageInfo:onEnter(container)
    self:registerPacket(container)
    BindBCPageInfo.container = container
    NodeHelper:setStringForLabel(container,{mBCBmfTitle = common:getLanguageString("@GoogleSignOut")})
    NodeHelper:setNodesVisible(container,{mStartGame = false , mBindBC = true})
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
            BindBCPageInfo.editEmailBox = NodeHelper:addEditBox(CCSize(470, 40), container:getVarNode("mEmailLabel"), function(eventType)
            if eventType == "began" then
                --NodeHelper:cursorNode(container, "mDecisionTex", true)
                -- triggered when an edit box gains focus after keyboard is shown
            elseif eventType == "ended" then
                BindBCPageInfo.onEditBoxReturn(container, BindBCPageInfo.editEmailBox, BindBCPageInfo.editEmailBox:getText())
                --NodeHelper:cursorNode(container, "mDecisionTex", false)
                -- triggered when an edit box loses focus after keyboard is hidden.
            elseif eventType == "changed" then
                BindBCPageInfo.onEditBoxReturn(container, BindBCPageInfo.editEmailBox, BindBCPageInfo.editEmailBox:getText(), true)
                --NodeHelper:cursorNode(container, "mDecisionTex", true)
                -- triggered when the edit box text was changed.
            elseif eventType == "return" then
                BindBCPageInfo.onEditBoxReturn(container, BindBCPageInfo.editEmailBox, BindBCPageInfo.editEmailBox:getText())
                -- triggered when the return button was pressed or the outside area of keyboard was touched.
            end
        end , ccp(-235, -0), "")
            BindBCPageInfo.editCodeBox = NodeHelper:addEditBox(CCSize(470, 40), container:getVarNode("mCodeLabel"), function(eventType)
            if eventType == "began" then
                --NodeHelper:cursorNode(container, "mDecisionTex", true)
                -- triggered when an edit box gains focus after keyboard is shown
            elseif eventType == "ended" then
                BindBCPageInfo.onEditBoxReturn(container, BindBCPageInfo.editCodeBox, BindBCPageInfo.editCodeBox:getText())
                --NodeHelper:cursorNode(container, "mDecisionTex", false)
                -- triggered when an edit box loses focus after keyboard is hidden.
            elseif eventType == "changed" then
                BindBCPageInfo.onEditBoxReturn(container, BindBCPageInfo.editCodeBox, BindBCPageInfo.editCodeBox:getText(), true)
                --NodeHelper:cursorNode(container, "mDecisionTex", true)
                -- triggered when the edit box text was changed.
            elseif eventType == "return" then
                BindBCPageInfo.onEditBoxReturn(container, BindBCPageInfo.editEmailBox, BindBCPageInfo.editCodeBox:getText())
                -- triggered when the return button was pressed or the outside area of keyboard was touched.
            end
        end , ccp(-235, -0), "")
        BindBCPageInfo.editEmailBox:setTag(InputTag.INPUT_EMAIL)
        BindBCPageInfo.editCodeBox:setTag(InputTag.INPUT_CODE)
        container:getVarNode("mEmailLabel"):setVisible(false)
        container:getVarNode("mCodeLabel"):setVisible(false)
                
        NodeHelper:setStringForTTFLabel(container, { mEmailLabel = "",mCodeLabel = "" })

        BindBCPageInfo.editEmailBox:setText("")
        BindBCPageInfo.editCodeBox:setText("")
    end
end

function BindBCPageInfo:onExecute(container)
    if (TimeCalculator:getInstance():hasKey("SendCodeTime")) then
	    if (TimeCalculator:getInstance():getTimeLeft("SendCodeTime") <= 0) then
		    TimeCalculator:getInstance():removeTimeCalcultor("SendCodeTime");
		    self:showSendCode(true);
	    else
		    self:showSendCode(false);
	    end
    end
end

function BindBCPageInfo:onEditBoxReturn(container, editBox, content, isChange)
    local checkOK = true
    if (editBox:getTag() == InputTag.INPUT_EMAIL) then
        if not GamePrecedure:getInstance():CheckMailRule(content) then
            checkOK = false
        end

        if not checkOK then
            MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
            editBox:setText(tostring(mStrEmail))
            content = mStrEmail
        end

        mStrEmail = content;

         if editBox ~= nil and not isChange then
            editBox:setText(tostring(mStrEmail))
         end
        NodeHelper:setStringForTTFLabel(container, { mEmailLabel = tostring(mStrEmail) })

    elseif (editBox:getTag() == InputTag.INPUT_CODE) then
--        if not checkOK then
--            MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
--            editBox:setText(tostring(mStrCode))
--            content = mStrCode
--        end

--        mStrCode = content;

--         if editBox ~= nil and not isChange then
--            editBox:setText(tostring(mStrCode))
--         end
        NodeHelper:setStringForTTFLabel(container, { mCodeLabel = tostring(mStrCode) })
    end
end

function BindBCPageInfo:onEMailContent(container)
    container:registerLibOS()
    mInputType = InputTag.INPUT_EMAIL;
    libOS:getInstance():showInputbox(false,0, USER_LEN_LIMIT,mStrEmail)
    CCLuaLog(" BindBCPageInfo:InputTag == 1")
end

function BindBCPageInfo:onCodeContent(container)
    container:registerLibOS()
	mInputType = InputTag.INPUT_CODE;
    libOS:getInstance():showInputbox(false,0, PWD_LEN_LIMIT,mStrCode)
    CCLuaLog(" BindBCPageInfo:InputTag == 2")
end

function BindBCPageInfo:InputDone(container)
    local contentLabel = nil
    local content = container:getInputboxContent();
    if mInputType == InputTag.INPUT_EMAIL then
        contentLabel = container:getVarLabelTTF("mEmailLabel");
        content = common:trimAll(content);
        if content == "" then
            mStrEmail = ""
            contentLabel:setString("");
            return;
        end

        mStrEmail = content;
        if contentLabel ~= nil then
            contentLabel:setString(tostring(mStrEmail));
        end
    end

    if mInputType == InputTag.INPUT_CODE then
        contentLabel = container:getVarLabelTTF("mCodeLabel");
        content = common:trimAll(content);
        if content == "" then
            mStrCode = ""
            contentLabel:setString("");
            return;
        end

        mStrCode = content;
        if contentLabel ~= nil then
            contentLabel:setString(tostring(mStrCode));
        end
    end
end

function BindBCPageInfo:onInputboxEnter(container)
    CCLuaLog(" BindBCPageInfo:onInputboxEnter")
    self:InputDone(container);
    if mInputType == InputTag.INPUT_EMAIL then
        NodeHelper:cursorNode(container, "mEmailLabel", true)
    elseif mInputType == InputTag.INPUT_CODE then
        NodeHelper:cursorNode(container, "mCodeLabel", true)
    end
end

function BindBCPageInfo:luaonCloseKeyboard(container)
    CCLuaLog(" BindBCPageInfo:luaonCloseKeyboard")
   if mInputType == InputTag.INPUT_EMAIL then
        NodeHelper:cursorNode(container, "mEmailLabel", false)
    elseif mInputType == InputTag.INPUT_CODE then
        NodeHelper:cursorNode(container, "mCodeLabel", false)
    end
end

function BindBCPageInfo:onClose(container)
    PageManager.popPage(thisPageName);
end

function BindBCPageInfo:onExit(container)
	container:removeLibOS()
    onUnload(thisPageName, container);
end

function BindBCPageInfo:onSendCode(container)

    if not GamePrecedure:getInstance():CheckMailRule(mStrEmail) then
        MessageBoxPage:Msg_Box("@Logintxt11");
        return    
    end

    local urlParam = "/sendcodeingame.php"

    local datatable = {}
    datatable.api_id = "skyark_ingame_api"
    datatable.api_token = "3C2D36F79AFB3D5374A49BE767A17C6A3AEF91635BF7A3FB25CEA8D4DD"
    datatable.user_email = mStrEmail

    self:setrequest(urlParam,EMT_SendCode,datatable)


end

function BindBCPageInfo:onBindBC(container)

    if not GamePrecedure:getInstance():CheckMailRule(mStrEmail) then
        MessageBoxPage:Msg_Box("@Logintxt11");
        return    
    end

    local length = string.len(mStrCode)
	if (length < 6) and (length > PWD_LEN_LIMIT) then
		MessageBoxPage:Msg_Box("@Logintxt13")
		return
	end

	--檢查字串除了英數,有無他字元

    local urlParam = "/verifyuservodeingame.php"
    local datatable = {}
    datatable.api_id = "skyark_ingame_api"
    datatable.api_token = "3C2D36F79AFB3D5374A49BE767A17C6A3AEF91635BF7A3FB25CEA8D4DD"
    datatable.vcode = mStrCode
    datatable.uEmail = mStrEmail

    self:setrequest(urlParam,EMT_BindGame,datatable)
end

function BindBCPageInfo:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    CCLuaLog("OPCODE: " .. opcode)
    if opcode == HP_pb.ACCOUNT_BOUND_REWARD_S then
        CCLuaLog("----------Bind Success--------------")
        MessageBoxPage:Msg_Box_Lan("@SDK12")
        CCUserDefault:sharedUserDefault():setStringForKey("LoginGuestID", "")
        libPlatformManager:getPlatform():setIsGuest(0)
--        local oldId = GamePrecedure:getInstance():getUin()
        GamePrecedure:getInstance():setUin(newAccount)
        CCLuaLog("----------Bind End--------------")
--        self:refreshPage(container)
        self:onClose(container)
    end
end

function BindBCPageInfo:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function BindBCPageInfo:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function BindBCPageInfo:setrequest(urlParam,tag,datatable)

     local bcurl = VaribleManager:getInstance():getSetting("BCUrl")
     bcurl = bcurl..urlParam

     local reqbody = ""
     for k,v in pairs(datatable) do
		if reqbody == "" then
			reqbody = reqbody.. k.."="..v
		else
			reqbody = reqbody.. "&" .. k.."="..v
		end
	end

    local onHttpCallback = function (httpResult)
        CCLuaLog("onHttpCallback tag =" .. httpResult.tag)
        CCLuaLog("isError = " .. tostring(httpResult.isError))
        CCLuaLog("result: " .. httpResult.responseData)
        
        if not httpResult.isError then
            local jtable = cjson.decode(httpResult.responseData)
            if jtable.err ~= 0 then
                local msgkey = ""
                if (jtable.err == 1) then
                    msgkey = "@Logintxt11"
                elseif (jtable.err == 3) then
                    msgkey = "@CSSignUpFailed"
                elseif (jtable.err == 9) then
                    msgkey = "@ERRORCODE_28"
                end
                if (msgkey ~= "") then
                    --MessageBoxPage:Msg_Box(common:getLanguageString(msgkey))
                    MessageHintPage:Msg_Hint(common:getLanguageString(msgkey),0)
                else
                    --MessageBoxPage:Msg_Box(jtable.msg)
                    MessageHintPage:Msg_Hint(jtable.msg,0)
                end
                return
            end
            if (httpResult.tag == EMT_SendCode) then
                TimeCalculator:getInstance():createTimeCalcultor("SendCodeTime",60) --60秒不能再送
                self:showSendCode(false)
                --MessageBoxPage:Msg_Box(common:getLanguageString("@Logintxt17"))
                MessageHintPage:Msg_Hint(common:getLanguageString("@Logintxt17"),0)
            end
            if (httpResult.tag == EMT_BindGame) then
                local AccountBound_pb = require("AccountBound_pb")
                local msg = AccountBound_pb.HPAccountBoundConfirm()
                msg.userId = jtable.account
                msg.wallet = jtable.msg
                newAccount = jtable.account
                common:sendPacket(HP_pb.ACCOUNT_BOUND_REWARD_C, msg, false)
            end
        end
    end
    HttpBridge:WebRequest_Post(bcurl,tag,reqbody,onHttpCallback)
end

function BindBCPageInfo:showSendCode(isShow)
    NodeHelper:setMenuItemsEnabled(self.container, { mSendCodeBtn = isShow })
    NodeHelper:setNodeIsGray(self.container, { mSendCodeBmf = not isShow })
end


local CommonPage = require("CommonPage");
local BindBC = CommonPage.newSub(BindBCPageInfo, thisPageName, option);

return BindBC
