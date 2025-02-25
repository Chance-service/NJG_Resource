----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local thisPageName = "CDKeyPage"
g_bIsEnterMateKey = false;
local bIsEnterMateKey = false;

local hp = require('HP_pb')
require("Cdk_pb")

local option = {
    ccbiFile = "CDKeyPopUp.ccbi",
    handlerMap =
    {
        onCancel = "onCancel",
        onInput = "onInput",
        onConfirmation = "onSave",
        luaInputboxEnter = "onInputboxEnter",
        luaonCloseKeyboard = "luaonCloseKeyboard",
        onClose = "onCancel",
    }
}

local CDKeyPageBase = { }
local cdkey = nil
local NodeHelper = require("NodeHelper");
--------------------------------------------------------------
local isSendCoupons = false
local   mSelfContainer = nil 
-- 平台回调
local libPlatformListener = { } 
function libPlatformListener:P2G_KR_COUPONS_BACK(listener)
    CCLuaLog(" libPlatformListener:onKrCouponsBack11111")
    isSendCoupons = false
    if not listener then CCLuaLog(" libPlatformListener nil") end

    local strResult = listener:getResultStr()
    local strTable = json.decode(strResult)
    local str = strTable.result
    CCLuaLog(" libPlatformListener:onKrCouponsBack2222")
    MessageBoxPage:Msg_Box(str)
    CCLuaLog(" libPlatformListener:onKrCouponsBack133333")
    CCLuaLog("str:" .. str)
    PageManager.popPage(thisPageName);
end
----------------------------------------------------------------------------------

-----------------------------------------------
-- CDKeyPageBase页面中的事件处理
----------------------------------------------
function CDKeyPageBase:onEnter(container)
    if Golb_Platform_Info.is_entermate_platform then
        CDKeyPageBase.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)
    end
    cdkey = nil
    mSelfContainer = container;
    bIsEnterMateKey = g_bIsEnterMateKey;
    g_bIsEnterMateKey = false;
    container:registerPacket(HP_pb.USE_CDK_S)
    container:registerPacket(HP_pb.PLAYER_AWARD_S)
    self:refreshPage(container);

    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
        CDKeyPageBase.editBox = NodeHelper:addEditBox(CCSize(470, 200), container:getVarNode("mCDKey"), function(eventType)
            if eventType == "began" then
                --NodeHelper:cursorNode(container, "mCDKey", true)
                NodeHelper:setStringForLabel(container, { mCDKeyHint = "" })
                -- triggered when an edit box gains focus after keyboard is shown
            elseif eventType == "ended" then
                CDKeyPageBase.onEditBoxReturn(container, CDKeyPageBase.editBox, CDKeyPageBase.editBox:getText())
                --NodeHelper:cursorNode(container, "mCDKey", true)
                -- CDKeyPageBase.onEditBoxReturn(container,CDKeyPageBase.editBox,CDKeyPageBase.editBox:getText())
                -- triggered when an edit box loses focus after keyboard is hidden.
            elseif eventType == "changed" then
                CDKeyPageBase.onEditBoxReturn(container, CDKeyPageBase.editBox, CDKeyPageBase.editBox:getText(), true)
                --NodeHelper:cursorNode(container, "mCDKey", true)
                -- CDKeyPageBase.onEditBoxReturn(container,CDKeyPageBase.editBox,CDKeyPageBase.editBox:getText())
                -- triggered when the edit box text was changed.
            elseif eventType == "return" then
                --NodeHelper:cursorNode(container, "mCDKey", true)
                CDKeyPageBase.onEditBoxReturn(container, CDKeyPageBase.editBox, CDKeyPageBase.editBox:getText())
                -- CDKeyPageBase.onEditBoxReturn(container,CDKeyPageBase.editBox,CDKeyPageBase.editBox:getText())
                -- triggered when the return button was pressed or the outside area of keyboard was touched.
            end
        end , ccp(-235, 0), common:getLanguageString('@InputCDKey'))
        -- container:getVarNode("mCDKey"):setPosition(ccp(0,46))
        container:getVarNode("mCDKey"):setAnchorPoint(ccp(0.5, 0.5))
        container:getVarNode("mCDKey"):setVisible(false)
        local color = StringConverter:parseColor3B("135 54 38")
        CDKeyPageBase.editBox:setFontColor(color)
        NodeHelper:setMenuItemEnabled(container, "mInput", false)
        -- container:getVarNode("mCDKeyHint"):setPosition(ccp(0,46))
        --container:getVarNode("mCDKeyHint"):setAnchorPoint(ccp(0.5, 0.5))
        container:getVarLabelTTF("mCDKeyHint"):setVisible(false)
    end
end

function CDKeyPageBase:onExecute(container)
end

function CDKeyPageBase:onExit(container)
    if CDKeyPageBase.libPlatformListener then
        CDKeyPageBase.libPlatformListener:delete()
    end
    container:removeLibOS()
    container:removePacket(HP_pb.USE_CDK_S)
    container:removePacket(HP_pb.PLAYER_AWARD_S)
end
----------------------------------------------------------------

function CDKeyPageBase:refreshPage(container)
    local str = { }
    if bIsEnterMateKey then
        -- 韩国的CDK弹框有两种形式
        str = {
            mTitle = common:getLanguageString("@CDKeyTitleKr"),
            mCDKey = common:getLanguageString("@InputCDKeyKr"),
        }
    else
        str = {
            mTitle = common:getLanguageString("@CDKeyTitle"),
            mCDKey = "",
        }
    end
    NodeHelper:setStringForLabel(container, str)
end

----------------click event------------------------

function CDKeyPageBase:onInput(container)

    container:registerLibOS()
    if not cdkey then
        libOS:getInstance():showInputbox(false, "");
    else
        libOS:getInstance():showInputbox(false, cdkey);
    end
    --NodeHelper:cursorNode(container, "mCDKey", true)
    --local mCdKey = container:getVarLabelTTF("mCDKey")
    --NodeHelper:addEditBoxBlinkTip(mCdKey)
end

function CDKeyPageBase.onEditBoxReturn(container, editBox, content, isChange)
    local nameOK = true
    if GameMaths:isStringHasUTF8mb4(content) then
        nameOK = false
    end
    if content == "" then
        cdkey = nil
        nameOK = false
        NodeHelper:setStringForLabel(container, { mCDKey = "" })
    end
    if not nameOK then
        -- MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        if editBox and not isChange then
            editBox:setText("")
        end
        return
    end
    cdkey = content;
    if editBox and not isChange then
        editBox:setText(tostring(cdkey))
    end
    -- editBox:setText(tostring(cdkey))
    NodeHelper:setStringForLabel(container, { mCDKey = cdkey })
    NodeHelper:setStringForLabel(container, { mCDKeyHint = "" })
end
function CDKeyPageBase:InputDone(container)
    local contentLabel = container:getVarLabelTTF("mCDKey");
    local content = container:getInputboxContent();
    if content == "" then
        container:getVarLabelTTF("mCDKeyHint"):setString(common:getLanguageString("@InputCDKey"))
        contentLabel:setString("")
        cdkey = nil
        return
    end
    local nameOK = true
    if GameMaths:isStringHasUTF8mb4(content) then
        nameOK = false
    end
    if not nameOK then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        cdkey = nil
        return
    end
    cdkey = content;
    if contentLabel ~= nil then
        --[[local length = GameMaths:calculateStringCharacters(content);
		if  length > 30 then
			--提示名字字数
			MessageBoxPage:Msg_Box_Lan("@NameExceedLimit");
			return;
		end	--]]
        container:getVarLabelTTF("mCDKeyHint"):setString("")
        contentLabel:setString(tostring(cdkey));
    end

    --local mCdKey = container:getVarLabelTTF("mCDKey")
    --NodeHelper:addEditBoxBlinkTip(mCdKey)

end
function CDKeyPageBase:luaonCloseKeyboard(container)
--    CCLuaLog("luaonCloseKeyboard====>")
--    local mCdKey = container:getVarLabelTTF("mCDKey")
--    if mCdKey and mCdKey:getChildByTag(10086) then 
--        CCLuaLog("luaonCloseKeyboard-----" .. "mTipAniSprite  is exsist")
--        local mTipAniSprite = mCdKey:getChildByTag(10086)
--        mTipAniSprite:stopAllActions()
--        mCdKey:removeChildByTag(10086,true)
--    end
    NodeHelper:cursorNode(container, "mCDKey", false)
end
function CDKeyPageBase:onInputboxEnter(container)
    self:InputDone(container)
    NodeHelper:cursorNode(container, "mCDKey", true)
end


function CDKeyPageBase:onCancel(container)
    if isSendCoupons then return end
    PageManager.popPage(thisPageName);
end

function CDKeyPageBase:onSave(container)

    if cdkey == nil then
        MessageBoxPage:Msg_Box_Lan("@PleaseEnterCDKFirst");
        return
    end
    if bIsEnterMateKey then
        bIsEnterMateKey = false;
        libOS:getInstance():OnEntermateCoupons(cdkey)
        isSendCoupons = true
    else
        CCLuaLog("CDKeyPageBase====>" .. cdkey)
        local msg = Cdk_pb.HPUseCdk()
        msg.cdkey = cdkey
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.USE_CDK_C, pb, #pb, false);
    end


    -- PageManager.popPage(thisPageName)
end

-- 回包处理

function CDKeyPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.USE_CDK_S then
        local msg = Cdk_pb.HPUseCdkRet()
        msg:ParseFromString(msgBuff)
        if msg.status == 0 and msg.reward then
        elseif msg.status == 1 then
        	MessageBoxPage:Msg_Box_Lan("@CDKeyNumNotExist");
        elseif msg.status == 2 then
        	MessageBoxPage:Msg_Box_Lan("@CDKeyNumNoOpenUse");
        elseif msg.status == 3 then
        	MessageBoxPage:Msg_Box_Lan("@CDKeyNumExpire");
        elseif msg.status == 4 then
        	MessageBoxPage:Msg_Box_Lan("@CDKeyNumAlreadyUse");
        elseif msg.status == 5 then
        	MessageBoxPage:Msg_Box_Lan("@CDKeyNumPlatformNotRight");
        elseif msg.status == 6 then
        	MessageBoxPage:Msg_Box_Lan("@CDKeyNumSameKeyUsed");
        else
            MessageBoxPage:Msg_Box_Lan("@CDKeyNumNotExist");
        end			
        return
    end
    if opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.onReceivePlayerAward(msgBuff)
    end
end


-- 继承此类的活动如果同时开，消息监听不能同时存在,通过tag来区分
--[[
function CDKeyPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == thisPageName then
			local posx = container.mScrollView:getContainer():getPositionX();
			local posy = container.mScrollView:getContainer():getPositionY();
			CDKeyPageBase:rebuildAllItem(container)
			container.mScrollView:getContainer():setPosition(ccp(posx,posy));
		end
	end
end
--]]

--[[
function CDKeyPageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function CDKeyPageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
--]]
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
CDKeyPage = CommonPage.newSub(CDKeyPageBase, thisPageName, option);
