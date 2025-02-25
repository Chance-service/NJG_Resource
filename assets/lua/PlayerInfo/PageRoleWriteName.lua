--======================================================================================
-- new page for create role
--======================================================================================

local HP          = require("HP_pb")
local NodeHelper  = require("NodeHelper")
local PageManager = require("PageManager")
local common      = require("common")
local Player_pb   = require("Player_pb");

local PageRoleWriteName = {};

local _PageContainer  = nil;
local _InputRoleName  = nil;
local nameOK = false
local _WaitAnimNode   = nil;
local _InputNodeDefaultPosX = nil;
local _InputNodeDefaultPosY = nil;

local _NormalNameColor = ccc3(53, 17, 0);
local _NoCharNameColor = ccc3(53, 28, 0);

local mStrTitle = "";
local mStrDesc = "";
local mStrDefaultTxt = "";
local mTtileScale = 1;
local mCallbackFunc = nil;
local inputName = "";
local mType = 0;
local thisPageName=PageRoleWriteName
local option = {
    ccbiFile = "ChoiceRoleWriteName.ccbi",
    }

function luaCreat_PageRoleWriteName(container)
	container:registerFunctionHandler(PageRoleWriteName.onFunction);
end

function PageRoleWriteName.onFunction(eventName, container)
    
    if eventName == "luaLoad" then
        PageRoleWriteName.onLoad(container)
    elseif eventName == "luaUnLoad" then
        PageRoleWriteName.onUnLoad(container)
    elseif eventName == "luaEnter" then
        PageRoleWriteName.onEnter();
    elseif eventName == "luaExit" then
		PageRoleWriteName.onExit();
    elseif eventName == "onUserNameBtn" then
        _PageContainer:registerLibOS()
        PageRoleWriteName.resetInputPosition()
		if _InputRoleName == nil then
		    libOS:getInstance():showInputbox(false, "")
		else
		    libOS:getInstance():showInputbox(false, _InputRoleName)
		end
        NodeHelper:cursorNode(_PageContainer,"mName",true)
    elseif eventName == "luaInputboxEnter" then
		PageRoleWriteName.onInputboxEnter();
    elseif eventName == "onReturn" then
        local currPage = MainFrame:getInstance():getCurShowPageName()
        if currPage ~= "" then -- 創角頁面不可離開
            PageManager.popPage("PageRoleWriteName")
            container:setVisible(false)
        end
    elseif eventName == "onCreateRole" then
        PageRoleWriteName.onSendCreateRolePacket()
    elseif eventName == "luaonCloseKeyboard" then
        PageRoleWriteName.DownChatNode()
    elseif eventName == "luaOnKeyboardHightChange" then
        if container:getKeyboardHight() >=300 then
            PageRoleWriteName.UpChatNode()
        end
    end
end


function PageRoleWriteName.onLoad(container)
    _PageContainer = container;
	container:loadCcbiFile("ChoiceRoleWriteName.ccbi", false);
    -- 主动调用一下
    PageRoleWriteName.onEnter();
end

function PageRoleWriteName.onUnLoad(container)
end

function PageRoleWriteName.onEnter()
    _PageContainer:setVisible(true)
    local middleFrameNode = _PageContainer:getVarNode("mNameNode")
    if middleFrameNode then
        _InputNodeDefaultPosX,_InputNodeDefaultPosY = middleFrameNode:getPosition();
    end
    PageRoleWriteName.resetInputPosition();
    local layerColorVar = _PageContainer:getVarNode("mMask")
    layerColorVar:setScale(NodeHelper:getScaleProportion())

    if(mType == 1)then
        _PageContainer:getVarLabelTTF("mNameHint"):setString("");
        NodeHelper:setStringForLabel(_PageContainer, { mName = common:getLanguageString("@ChangeNameTex") })
    end
    if not editBox or editBox:getText() == "" then
        _PageContainer:getVarNode("mNameHint"):setVisible(true)
        _PageContainer:getVarLabelTTF("mNameHint"):setString(common:getLanguageString(""))
    end
end

function PageRoleWriteName.resetInputPosition()
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
	    editBox = NodeHelper:addEditBox(CCSize(4000,40),_PageContainer:getVarNode("mName"),function(eventType)
		    if eventType == "began" then
                _PageContainer:getVarNode("mNameHint"):setVisible(false)
                _PageContainer:getVarLabelTTF("mNameHint"):setString("")
                --NodeHelper:cursorNode(_PageContainer,"mName",true)
                --PageRoleWriteName.onEditBoxReturn(editBox,editBox:getText(),true)
			    --NodeHelper:cursorNode(_PageContainer,"mName",true)
			    -- triggered when an edit box gains focus after keyboard is shown
		    elseif eventType == "ended" then
			    -- PageRoleWriteName.onEditBoxReturn(editBox,editBox:getText(),true)
			    -- NodeHelper:cursorNode(_PageContainer,"mName",true)
			    -- triggered when an edit box loses focus after keyboard is hidden.
                NodeHelper:setNodesVisible(_PageContainer, { mName = false })
		    elseif eventType == "changed" then
                _PageContainer:getVarNode("mNameHint"):setVisible(false)
                _PageContainer:getVarLabelTTF("mNameHint"):setString("")
			    PageRoleWriteName.onEditBoxReturn(editBox,editBox:getText(),true)
			    --NodeHelper:cursorNode(_PageContainer,"mName",true)
                NodeHelper:setNodesVisible(_PageContainer, { mName = false })
			    -- triggered when the edit box text was changed.
		    elseif eventType == "return" then
                if editBox:getText() == "" then
                   _PageContainer:getVarNode("mNameHint"):setVisible(true)
                   _PageContainer:getVarLabelTTF("mNameHint"):setString(common:getLanguageString(""))
               end
			    PageRoleWriteName.onEditBoxReturn(editBox,editBox:getText())
                --NodeHelper:cursorNode(_PageContainer,"mName",false)
			    -- triggered when the return button was pressed or the outside area of keyboard was touched.
		    end
	    end, ccp(20,0), "")

        --common:getLanguageString("@UserNamePrompt")
	    NodeHelper:setMenuItemEnabled(_PageContainer,"mUserNameBtn",false)
	    editBox:setMaxLength(GameConfig.WordSizeLimit.RoleNameLimit)
        editBox:setFontColor(_NormalNameColor)
        editBox:setPlaceholderFontColor(_NormalNameColor)
	    _PageContainer:getVarNode("mName"):setVisible(false)
        _PageContainer:getVarNode("mNameHint"):setVisible(false)
	    --NodeHelper:setStringForLabel(_PageContainer, { mName = common:getLanguageString("@ChangeNameTex") })
        local nameLabel = _PageContainer:getVarLabelTTF("mName");
        nameLabel:setColor(_NoCharNameColor);
    end
end

function PageRoleWriteName.onExit()
    _PageContainer:removeLibOS()    
end

function PageRoleWriteName.onInputboxEnter() 
    local contentLabel = _PageContainer:getVarLabelTTF("mName")
    local content = _PageContainer:getInputboxContent()
    
    _InputRoleName = content
    if content == "" then
        contentLabel:setString("");
        contentLabel:setColor(_NoCharNameColor);
        _PageContainer:getVarNode("mNameHint"):setVisible(true)
        _PageContainer:getVarLabelTTF("mNameHint"):setString(common:getLanguageString(""))
    else
        contentLabel:setString(tostring(_InputRoleName))
        contentLabel:setColor(_NormalNameColor)
        _PageContainer:getVarNode("mNameHint"):setVisible(false)
        _PageContainer:getVarLabelTTF("mNameHint"):setString("")
    end
    
    --[[
	local contentLabel = _PageContainer:getVarLabelTTF("mName");
	local content = _PageContainer:getInputboxContent();
    
    if content == "" then
        contentLabel:setString(common:getLanguageString("@ChangeNameTex"));
        contentLabel:setColor(_NoCharNameColor);
        _InputRoleName = nil;
        return
    end

    
    local nLen = GameMaths:calculateStringCharacters(content);
	if  nLen > GameConfig.WordSizeLimit.RoleNameLimit then 
		MessageBoxPage:Msg_Box_Lan("@NameExceedLimit");
        libOS:getInstance():setEditBoxText(_InputRoleName)
		return;
	end	
    --
	
    if GameMaths:isStringHasUTF8mb4(content) then
		nameOK = false
    end
	if not RestrictedWord:getInstance():isStringOK(content) then
		nameOK = false
	end
    if content == "" then
		nameOK = false
    end
	if not nameOK then
        contentLabel:setString("");
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
    end

	_InputRoleName = content;
	if contentLabel ~= nil then
		contentLabel:setString(tostring(_InputRoleName));
	end
    contentLabel:setColor(_NormalNameColor);
    ]]
    inputName = content;
    NodeHelper:cursorNode(_PageContainer,"mName",true)
end

function PageRoleWriteName.onEditBoxReturn(editBox, content, isChange)
    local contentLabel = _PageContainer:getVarLabelTTF("mName")
    
    _InputRoleName = content
    if content == "" then
        --_PageContainer:getVarNode("mNameHint"):setVisible(true)
        --NodeHelper:cursorNode(_PageContainer,"mName",false)
        contentLabel:setString("");
        contentLabel:setColor(_NoCharNameColor)
    else
        contentLabel:setString(tostring(_InputRoleName))
        contentLabel:setColor(_NormalNameColor)
    end

    --[[

    local nameLabel = _PageContainer:getVarLabelTTF("mName");
	if common:trim(content) == "" then
        nameLabel:setString(common:getLanguageString("@ChangeNameTex") );
        nameLabel:setColor(_NoCharNameColor);
        _InputRoleName = nil;
        if editBox and not isChange then
            editBox:setText("")
        end
        return
    end
	local nLen = GameMaths:calculateStringCharacters(content);
	if  nLen > GameConfig.WordSizeLimit.RoleNameLimit then 
		MessageBoxPage:Msg_Box_Lan("@NameExceedLimit");
		return;
	end	
    --
	nameOK = true
    if GameMaths:isStringHasUTF8mb4(content) then
		nameOK = false
    end
	if not RestrictedWord:getInstance():isStringOK(content) then
		nameOK = false
	end
    if content == "" then
		nameOK = false
    end

	_InputRoleName = content;

	if editBox ~= nil and not isChange then
        if not nameOK then
            MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        else
            editBox:setText(tostring(_InputRoleName))
        end
		--editBox:setText(tostring(_InputRoleName))
	end
    NodeHelper:setStringForTTFLabel(_PageContainer, { mName = tostring(_InputRoleName) })
	--NodeHelper:setStringForLabel(_PageContainer, { mName = _InputRoleName })
    nameLabel:setColor(_NormalNameColor);
    ]]
end

function PageRoleWriteName.onSendCreateRolePacket()
    if(mCallbackFunc) then
        if(mType == 1) then
            mCallbackFunc(inputName);
            PageManager.popPage("PageRoleWriteName");
        elseif(mType == 2) then
            mCallbackFunc(inputName);
        end
        return;
    end

    local contentLabel = _PageContainer:getVarLabelTTF("mName")
    if _InputRoleName == nil or string.len(_InputRoleName) <= 0 then
        MessageBoxPage:Msg_Box_Lan("@PleaseEnterNameFirst")
        contentLabel:setString("");
        contentLabel:setColor(_NoCharNameColor);
        return
    end
    
    contentLabel:setString(tostring(_InputRoleName))
    contentLabel:setColor(_NormalNameColor)
    
    local nLen = GameMaths:calculateStringCharacters(_InputRoleName);
    if  nLen > GameConfig.WordSizeLimit.RoleNameLimit then 
        MessageBoxPage:Msg_Box_Lan("@NameExceedLimit");
        return;
    end
    
    nameOK = true
    if GameMaths:isStringHasUTF8mb4(_InputRoleName) then
        nameOK = false
    end
    if not RestrictedWord:getInstance():isStringOK(_InputRoleName) then
        nameOK = false
    end

    if not nameOK then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        return
    end

	local message = Player_pb.HPRoleCreate();
	if message ~= nil then	
		message.roleItemId = _Gs_CreateRoleId;	
		message.roleName   = _InputRoleName;				
		local pb_data = message:SerializeToString();
		PacketManager:getInstance():sendPakcet(HP.ROLE_CREATE_C, pb_data, #pb_data, false);
        _Gs_ShowAnimFunc(true)	
	end
end

function PageRoleWriteName.UpChatNode()
    local middleFrameNode = _PageContainer:getVarNode("mNameNode")
    if middleFrameNode == nil then return end
    local hight = _PageContainer:getKeyboardHight()--相对于屏幕分辨率 键盘的高度，要转换为游戏逻辑高度
    hight = hight/CCEGLView:sharedOpenGLView():getScaleY();
    local convertPos = middleFrameNode:getParent():convertToNodeSpace(ccp(0,hight));
    if middleFrameNode:getPositionY() == convertPos.y then
        return 
    end
    local actionArr = CCArray:create();
    actionArr:addObject(CCMoveTo:create(0.3,ccp(_InputNodeDefaultPosX,convertPos.y)))
    middleFrameNode:stopAllActions();
    middleFrameNode:runAction(CCSequence:create(actionArr));
end

function PageRoleWriteName.DownChatNode()
    NodeHelper:cursorNode(_PageContainer,"mName",false)
    if _InputRoleName == ""  then 
        _PageContainer:getVarNode("mNameHint"):setVisible(true)
        _PageContainer:getVarLabelTTF("mNameHint"):setString(common:getLanguageString(""))
    end
    local middleFrameNode = _PageContainer:getVarNode("mNameNode")
    if middleFrameNode == nil then return end
    local actionArr = CCArray:create();
     if middleFrameNode:getPositionY() == _InputNodeDefaultPosY then
        return 
    end
    actionArr:addObject(CCMoveTo:create(0.2,ccp(_InputNodeDefaultPosX,_InputNodeDefaultPosY)))
    middleFrameNode:stopAllActions();
    middleFrameNode:runAction(CCSequence:create(actionArr));
end

-- mType : 1 為隊伍改名, 2 為大廳頭像角色改名, 沒有callback為登入創角
function SetInputBoxInfo2(title, desc, defaultTxt, callbackfunc , titleScale, typeNum)
    mStrTitle = title or "";
    mStrDesc = desc or "";
    mStrDefaultTxt = defaultTxt or "";
    mCallbackFunc = callbackfunc;
    mTtileScale = titleScale or 1;
    mType = typeNum;
end
----------------------------------------------------------------------------------------
local CommonPage = require('CommonPage')
return  CommonPage.newSub(PageRoleWriteName, thisPageName,nil)
