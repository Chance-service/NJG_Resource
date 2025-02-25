
----------------------------------------------------------------------------------
--require "ExploreEnergyCore_pb"
local HP = require("HP_pb");
local GameConfig = require("GameConfig");
local player_pb = require("Player_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local NodeHelper = require("NodeHelper");
local thisPageName = "DataTransferPage"
local DataTransferPage = {};
local SIGNATURE_VIEW_COUNT = 15;
local bgNodeDefaultPosX, bgNodeDefaultPosY = 0, 0
local strPassWord = "";
local strPwdMinLimit = 4
local strPwdMaxLimit = 30
local curPagecontainer = nil
local option = {
	ccbiFile = "DataTransferSetPassWordPopUp.ccbi",
	handlerMap = {
		onInPutPassword = "showInputBox",
		onConfirmation = "onConfirmation",
		onCancel = "onClose",
		onClose = "onClose",
		onHelp = "onHelp",
        onCopy = "onCopy",
        luaInputboxEnter = "onInputboxEnter",
        luaonCloseKeyboard = "luaonCloseKeyboard",
        luaOnKeyboardHightChange = "UpBgNode",
	},
	opcode = opcodes
};
local libPlatformListener = {}

function libPlatformListener:P2G_CHANGE_PWD(listener)
	if not listener then return end
    local strResult = listener:getResultStr()
    local strTable = json.decode(strResult)
    if tonumber(strTable.result) == 1 then
        --改密码成功 strTable.pwd 密码
        local DataTransferSucceedPage = require("DataTransferSucceedPage")
        DataTransferSucceedPage:setPwd(strTable.pwd);
        PageManager.pushPage("DataTransferSucceedPage");
    elseif tonumber(strTable.result) == 0 then
        --改密码失败
        --strTable.code 代表原因 1参数确实或者密码长度问题 2 没有找到该accode对应的账号记录
        local code = tonumber(strTable.code)
        if code == 1 then
            MessageBoxPage:Msg_Box_Lan("@DataTransferPasswordTooShort");
        elseif code == 2 then
            MessageBoxPage:Msg_Box_Lan("@DataTransferWasWrong");
        end
    end
end


--------------------------------------------------------------
--显示签名输入框
function DataTransferPage:showInputBox( container )
	container:registerLibOS();
	libOS:getInstance():showInputbox(false,0,strPwdMaxLimit,strPassWord);
end

----------------------------------------------
function DataTransferPage:onEnter(container)
    curPagecontainer = container
    DataTransferPage.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
		DataTransferPage.editBox = NodeHelper:addEditBox(CCSize(270,100),container:getVarNode("mPasswordTxt"),function(eventType)
				if eventType == "began" then
				    NodeHelper:setNodesVisible(container, { mPasswordChoose = true})
				elseif eventType == "ended" then
				    DataTransferPage.onEditBoxReturn(DataTransferPage.editBox,DataTransferPage.editBox:getText())
                    --NodeHelper:cursorNode(container,"mPasswordTxt",false)
                    NodeHelper:setNodesVisible(container, { mPasswordChoose = false})
				elseif eventType == "changed" then

                    NodeHelper:setNodesVisible(container, { mPasswordHint = false })
				    DataTransferPage.onEditBoxReturn(DataTransferPage.editBox,DataTransferPage.editBox:getText())
                    --NodeHelper:cursorNode(container,"mPasswordTxt",true)
				elseif eventType == "return" then
					DataTransferPage.onEditBoxReturn(DataTransferPage.editBox,DataTransferPage.editBox:getText())
				end
			end,ccp(-110,0),common:getLanguageString("@DataSetPasswordHint"))
		DataTransferPage.editBox:setMaxLength(strPwdMaxLimit)

        local color = StringConverter:parseColor3B("0 0 0")
        DataTransferPage.editBox:setFontColor(color)
        DataTransferPage.editBox:setFontSize(20)
		DataTransferPage.editBox:setInputFlag(kEditBoxInputFlagPassword)
        --NodeHelper:setNodesVisible(container, { mPasswordTxt = true })
        NodeHelper:setNodesVisible(container, { mPasswordHint = false })
		NodeHelper:setMenuItemEnabled(container,"mInPutBtn",false)
    else 
    local MiddleFrameNode = container:getVarNode("mFullNode")
        if MiddleFrameNode then
            bgNodeDefaultPosX, bgNodeDefaultPosY = MiddleFrameNode:getPosition()
        end
	end

	self:refreshPage(container);
end

function DataTransferPage:onExecute(container)
end

function DataTransferPage:onExit(container)
	container:removeLibOS();
    if DataTransferPage.libPlatformListener then
		DataTransferPage.libPlatformListener:delete()
	end
end
----------------------------------------------------------------

function DataTransferPage:refreshPage(container)
    strPassWord = "";
    local code = GamePrecedure:getInstance():getLoginCode()
    NodeHelper:setStringForLabel( container, {mDataTxt = code} );
    NodeHelper:setNodesVisible(container, { mPasswordChoose = false})
end


----------------click event------------------------
function DataTransferPage:onClose(container)
	PageManager.popPage(thisPageName);
end


function DataTransferPage:onConfirmation(container)
    if string.len(strPassWord) < strPwdMinLimit or string.len(strPassWord) > strPwdMaxLimit then
        MessageBoxPage:Msg_Box_Lan("@DataTransferPasswordTooShort");
        return 
    end
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
		libOS:getInstance():setWaiting(true)
	end
     local strtable = {
            pwd = strPassWord,
       }
     local JsMsg  = cjson.encode(strtable)
	libPlatformManager:getPlatform():sendMessageG2P("G2P_CHANGE_PWD",JsMsg)
end

function DataTransferPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

end

function DataTransferPage.onEditBoxReturn(editBox,content)
	
    local contentLabel = curPagecontainer:getVarLabelTTF("mPasswordTxt");
    if  contentLabel == nil then return; end
    if common:trim(content) == "" then
        contentLabel:setString("");
        editBox:setText("")
        --NodeHelper:setNodesVisible(curPagecontainer, { mPasswordHint = true })
        strPassWord = ""
        return 
    end
	if not GameMaths:isPassWordAllow(content) then
        --提示不合法
        MessageBoxPage:Msg_Box_Lan("@Invalidpassword");
        local showPwd = common:changeStringToPwdStyle(strPassWord)
        contentLabel:setString(showPwd)
        editBox:setText(strPassWord)
        
        return
    else
        strPassWord = content;
    end
	
	if editBox ~= nil then
		local length = GameMaths:calculateStringCharacters(strPassWord);
		if  length > strPwdMaxLimit then 
		    strPassWord = GameMaths:getStringSubCharacters(strPassWord,0,strPwdMaxLimit)
		end
        local showPwd = common:changeStringToPwdStyle(strPassWord)
		contentLabel:setString(showPwd)
        editBox:setText(strPassWord)
        NodeHelper:setNodesVisible(curPagecontainer, { mPasswordHint = false })
	end
end
function DataTransferPage:UpBgNode(container)
 if container:getKeyboardHight() < 300 then return end
    CCLuaLog("move mBg UpBgNode  ")
    local MiddleFrameNode = container:getVarNode("mFullNode")
    if MiddleFrameNode == nil then return end
    local hight = container:getKeyboardHight()
    -- 相对于屏幕分辨率 键盘的高度，要转换为游戏逻辑高度
    hight = hight / CCEGLView:sharedOpenGLView():getScaleY();
    if hight == nil then
        return
    end

    local convertPos = MiddleFrameNode:getParent():convertToNodeSpace(ccp(0, hight));
    if convertPos.y == nil and MiddleFrameNode:getPositionY() == convertPos.y then
        return
    end
    local actionArr = CCArray:create();
    -- actionArr:addObject(CCDelayTime:create(0.1))
    actionArr:addObject(CCMoveTo:create(0.3, ccp(bgNodeDefaultPosX, convertPos.y)))
    MiddleFrameNode:stopAllActions();
    MiddleFrameNode:runAction(CCSequence:create(actionArr));
end
function DataTransferPage:luaonCloseKeyboard(container)
     CCLuaLog(" ChangeNamePageBase:luaonCloseKeyboard")
     NodeHelper:cursorNode(container,"mPasswordTxt",false)
     NodeHelper:setNodesVisible(container, { mPasswordChoose = false})

    local MiddleFrameNode = container:getVarNode("mFullNode")
    if MiddleFrameNode == nil then return end
    local actionArr = CCArray:create();
    if MiddleFrameNode:getPositionY() == bgNodeDefaultPosY then
        return
    end
    -- actionArr:addObject(CCDelayTime:create(0.1))
    actionArr:addObject(CCMoveTo:create(0.2, ccp(bgNodeDefaultPosX, bgNodeDefaultPosY)))
    MiddleFrameNode:stopAllActions();
    MiddleFrameNode:runAction(CCSequence:create(actionArr));


end
--输入框输入完成
function DataTransferPage:onInputboxEnter(container)
    self:onInputChange(container);
    NodeHelper:cursorNode(container,"mPasswordTxt",true)
    NodeHelper:setNodesVisible(container, { mPasswordChoose = true})
end
--输入框输入完成
function DataTransferPage:onInputChange(container)
    local contentLabel = container:getVarLabelTTF("mPasswordTxt");
	local content = container:getInputboxContent()

    if common:trim(content) == "" then
        contentLabel:setString(tostring(""));
        NodeHelper:setNodesVisible(container, { mPasswordHint = true })
        strPassWord = ""
        return 
    end
	if not GameMaths:isPassWordAllow(content) then
        --提示不合法
        MessageBoxPage:Msg_Box_Lan("@Invalidpassword");
        local showPwd = common:changeStringToPwdStyle(strPassWord)
        contentLabel:setString(showPwd)
        libOS:getInstance():setEditBoxText(strPassWord);
        return
    else
        strPassWord = content;
    end
	
	local length = GameMaths:calculateStringCharacters(strPassWord);
	if  length > strPwdMaxLimit then 
		strPassWord = GameMaths:getStringSubCharacters(strPassWord,0,strPwdMaxLimit)
	end
    local showPwd = common:changeStringToPwdStyle(strPassWord)
	contentLabel:setString(showPwd)
    NodeHelper:setNodesVisible(container, { mPasswordHint = false })
end

function DataTransferPage:registerPacket(container)
	
end

function DataTransferPage:onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.SIGNATURE_PAGE_HELP);
end
function DataTransferPage:onCopy( container )
    local code = GamePrecedure:getInstance():getLoginCode()
	libOS:getInstance():setClipboardText(code)
    MessageBoxPage:Msg_Box_Lan("@DataTransferCopySuccessful");
end

function DataTransferPage:removePacket(container)
	
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local DataTransferPage = CommonPage.newSub(DataTransferPage, thisPageName, option);