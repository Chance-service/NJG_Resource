----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--require "ExploreEnergyCore_pb"
local HP = require("HP_pb");
local GameConfig = require("GameConfig");
local player_pb = require("Player_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local NodeHelper = require("NodeHelper");
local NewbieGuideManager = require("Guide.NewbieGuideManager")
local thisPageName = "SignaturePage"
local SignaturePageBase = {};
local SIGNATURE_VIEW_COUNT = 18;

local opcodes = {
	ROLE_CHANGE_SIGNATURE_C = HP.ROLE_CHANGE_SIGNATURE_C;
	ROLE_CHANGE_SIGNATURE_S = HP.ROLE_CHANGE_SIGNATURE_S;
}

local singnatureLenLimit = 23
local signatureStr = ""
local curPagecontainer = nil
local option = {
	ccbiFile = "ChangeSignaturePopUp.ccbi",
	handlerMap = {
		onContentBtn = "showInputBox",
		onConfirmation = "onChangeSignature",
		onCancel = "onClose",
		onClose = "onClose",
		onHelp = "onHelp"
	},
	opcode = opcodes
};

--------------------------------------------------------------
--显示签名输入框
function SignaturePageBase:showInputBox( container )
	container:registerLibOS();
	libOS:getInstance():showInputbox(false,"");
end

----------------------------------------------
function SignaturePageBase:onEnter(container)
	CCLuaLog("SignaturePageBase onEnter")
	self:registerPacket(container)
	curPagecontainer  =  container
	--container:registerMessage(MSG_SEVERINFO_UPDATE)
	signatureStr = UserInfo.playerInfo.signature;
	--NodeHelper:initScrollView(container, "mContent", 1)
		
	platformInfo = PlatformRoleTableManager:getInstance():getPlatformRoleByName(GamePrecedure:getInstance():getPlatformName());
	if platformInfo and platformInfo ~= nil then
        --singnatureLenLimit = platformInfo.nSingnatureLenLimit
	end

	--NewbieGuideManager.showHelpPage(GameConfig.HelpKey.SIGNATURE_PAGE_HELP)
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
        if  container == nil then  return ; end
		SignaturePageBase.editBox = NodeHelper:addEditBox(CCSize(500,150),container:getVarNode("mLabelTex"),function(eventType)

                CCLuaLog("SignaturePageBase eventType:"..tostring(eventType).. "     length:"..tostring(singnatureLenLimit))
				if eventType == "began" then
				 -- triggered when an edit box gains focus after keyboard is shown
				elseif eventType == "ended" then
				 -- triggered when an edit box loses focus after keyboard is hidden.
				elseif eventType == "changed" then
                    --if GameMaths:calculateStringCharacters(SignaturePageBase.editBox:getText()) > 15 then
                    --    SignaturePageBase.editBox:setFontSize(18)
                    --else
                        SignaturePageBase.editBox:setFontSize(26)
                    --end
				 -- triggered when the edit box text was changed.
				elseif eventType == "return" then
					SignaturePageBase.onEditBoxReturn(SignaturePageBase.editBox,SignaturePageBase.editBox:getText())
				 -- triggered when the return button was pressed or the outside area of keyboard was touched.
				end
            end,nil,common:getLanguageString("@SingTip"))
		SignaturePageBase.editBox:setMaxLength(23)
		local color = StringConverter:parseColor3B("255 255 255")
		SignaturePageBase.editBox:setFontColor(color)
		SignaturePageBase.editBox:setPlaceholderFontColor(color)
		NodeHelper:setMenuItemEnabled(container,"mContentBtn",false)
	end
	self:refreshPage(container);
end

function SignaturePageBase:onExecute(container)
end

function SignaturePageBase:onExit(container)
	container:removeLibOS();
	NodeHelper:clearScrollView(container);
	self:removePacket(container)
	--container:removeMessage(MSG_SEVERINFO_UPDATE)	
end
----------------------------------------------------------------

function SignaturePageBase:refreshPage(container)
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
		local colorStr
		if string.len(signatureStr) > 0 then
			local length = GameMaths:calculateStringCharacters(signatureStr);
			if length > SIGNATURE_VIEW_COUNT then 
				str = common:stringAutoReturn(signatureStr,SIGNATURE_VIEW_COUNT,0)
			else
				str = GameMaths:getStringSubCharacters(signatureStr,0,SIGNATURE_VIEW_COUNT)
			end
			colorStr = GameConfig.ColorMap.COLOR_WHITE
			SignaturePageBase.editBox:setText(str)
			--SignaturePageBase.editBox:setFontColor(NodeHelper:_getColorFromSetting(colorStr))
		else
			colorStr = GameConfig.ColorMap.COLOR_GREEN
			SignaturePageBase.editBox:setPlaceHolder(common:getLanguageString("@SignatureInput"))
			--SignaturePageBase.editBox:setPlaceholderFontColor(NodeHelper:_getColorFromSetting(colorStr))
		end
	else
		self:changeSignatureInfo(container);
	end
end

--根据输入信息，刷新签名页面
function SignaturePageBase:changeSignatureInfo(container)

	local str = "";
	local colorStr = "";
	if string.len(signatureStr) > 0 then
	    local length = GameMaths:calculateStringCharacters(signatureStr);
	    if length > SIGNATURE_VIEW_COUNT then 
	        str = common:stringAutoReturn(signatureStr,SIGNATURE_VIEW_COUNT,0)
	    else
		    str = GameMaths:getStringSubCharacters(signatureStr,0,SIGNATURE_VIEW_COUNT)
		end
		colorStr = GameConfig.ColorMap.COLOR_WHITE;
		
		local labelNode = container:getVarLabelTTF("mLabelTex")
	else
		local labelNode = container:getVarLabelTTF("mLabelTex")
		NodeHelper:setNodeVisible(labelNode,true)
		str = Language:getInstance():getString("@SignatureInput");
		colorStr = GameConfig.ColorMap.COLOR_GREEN;
	end

	--NodeHelper:setColorForLabel( container, {mLabelTex = colorStr} );
	NodeHelper:setStringForLabel( container, {mLabelTex = str} );
	
end
local SignatureItem = {
	
}
function SignatureItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		SignatureItem.onRefreshItemView(container)		
	end
end
function SignatureItem.onRefreshItemView(container)

end
function SignaturePageBase:buildItem(container,str)
--	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
--	local iCount = 0
--	local fOneItemHeight = 0
--	local fOneItemWidth = 0

--		local i = 1
--		local pItemData = CCReViSvItemData:new_local()
--		pItemData.mID = i
--		pItemData.m_iIdx = i
--		pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)

--		if iCount < iMaxNode then
--			local pItem = ScriptContentBase:create("GeneralHelpContent.ccbi")

--            pItem.id = iCount
--			pItem:registerFunctionHandler(SignatureItem.onFunction)

--			local itemHeight = 0

--			local nameNode = pItem:getVarLabelBMFont("mLabel")
--			local cSize = NodeHelper:setCCHTMLLabelDefaultPos( nameNode , CCSize(420,75) , str  ):getContentSize()

--			if fOneItemHeight < cSize.height then
--				fOneItemHeight = cSize.height 
--			end

--			if fOneItemWidth < pItem:getContentSize().width then
--				fOneItemWidth = pItem:getContentSize().width
--			end
--			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
--		else
--			container.m_pScrollViewFacade:addItem(pItemData)
--		end
--		iCount = iCount + 1

--	local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount )
--	container.mScrollView:setContentSize(size)
--	container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
--	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
--	container.mScrollView:forceRecaculateChildren()
--	ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end
----------------click event------------------------
function SignaturePageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

--检查是否符合签名条件，若符合请求服务端修改签名
function SignaturePageBase:onChangeSignature(container)
	local length = GameMaths:calculateStringCharacters(signatureStr);
	--[[if  length > singnatureLenLimit then 

		MessageBoxPage:Msg_Box_Lan("@SignatureCountLimit");
		return;
	end--]]

	if string.len(signatureStr) >= 0 then
		local msg = player_pb.HPChangeSignature();
		
		local length = GameMaths:calculateStringCharacters(signatureStr);
		if length>singnatureLenLimit then
		    signatureStr = GameMaths:getStringSubCharacters(signatureStr,0,singnatureLenLimit)
		end
		
        signatureStr = common:deleteNTR(signatureStr)
		msg.signature = signatureStr;
		local pb_data = msg:SerializeToString();
		PacketManager:getInstance():sendPakcet(opcodes.ROLE_CHANGE_SIGNATURE_C, pb_data, #pb_data, true);
	else
		MessageBoxPage:Msg_Box("@SignatureISNull");
	end
end




function SignaturePageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == opcodes.ROLE_CHANGE_SIGNATURE_S then
		PageManager.refreshPage("PlayerInfoPage");
		self:onClose();
	end

end
function SignaturePageBase.onEditBoxReturn(editBox,content)
	local nameOK = true
	--if content == "" then
		--nameOK = false
    --end
	if not nameOK then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        content = nil
        return
    end
	if GameConfig.isIOSAuditVersion then 
	    signatureStr = content -- RestrictedWord:getInstance():filterWordSentence(content);
    else
        signatureStr = RestrictedWord:getInstance():filterWordSentence(content);
    end
	
	if editBox ~= nil then
		local length = GameMaths:calculateStringCharacters(signatureStr);
		if  length > singnatureLenLimit then 
		    signatureStr = GameMaths:getStringSubCharacters(signatureStr,0,singnatureLenLimit)
		end
		--signatureStr = content;
		local viewStr = signatureStr;
		if length > SIGNATURE_VIEW_COUNT then
			viewStr = common:stringAutoReturn(viewStr,SIGNATURE_VIEW_COUNT,0)
		end

		-- if  curPagecontainer == nil then  return ; end
  --       local contentLabel = curPagecontainer:getVarLabelTTF("mLabelTex");
  --       if  contentLabel == nil then  return ; end
  --       contentLabel:setString(viewStr)
		editBox:setText(signatureStr)
	end
end
--输入框输入完成回掉，刷新签名信息
function SignaturePageBase:onInputboxEnter(container)
	local contentLabel = container:getVarLabelTTF("mLabelTex");
	local content = container:getInputboxContent();

	signatureStr = RestrictedWord:getInstance():filterWordSentence(content);
	
	if contentLabel ~= nil then
		local length = GameMaths:calculateStringCharacters(signatureStr);
		if  length > singnatureLenLimit then 
		    signatureStr = GameMaths:getStringSubCharacters(signatureStr,0,singnatureLenLimit)
		end
		--signatureStr = content;
		local viewStr = signatureStr;
		if length > SIGNATURE_VIEW_COUNT then
			viewStr = common:stringAutoReturn(viewStr,SIGNATURE_VIEW_COUNT,0)
		end

		--contentLabel:setString(tostring(viewStr));
		contentLabel:setString(viewStr)
		--NodeHelper:clearScrollView(container);
		--SignaturePageBase:buildItem(container,tostring(viewStr))
	end
end

function SignaturePageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function SignaturePageBase:onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.SIGNATURE_PAGE_HELP);
end

function SignaturePageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local SignaturePage = CommonPage.newSub(SignaturePageBase, thisPageName, option);
