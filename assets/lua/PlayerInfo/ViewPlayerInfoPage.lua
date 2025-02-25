----------------------------------------------------------------------------------
--[[

--]]
----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local HP_pb = require("HP_pb");
local Snapshot_pb = require("Snapshot_pb");
local Friend_pb = require("Friend_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local NodeHelper = require("NodeHelper");
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local titleManager = require("PlayerInfo.TitleManager")
local GameConfig   = require("GameConfig")
--------------------------------------------------------------------------------

local thisPageName = "ViewPlayerInfoPage";

local opcodes = {
-- FRIEND_ADD_S = HP_pb.FRIEND_ADD_S,
-- FRIEND_DELETE_S = HP_pb.FRIEND_DELETE_S,
-- MESSAGE_CANCEL_SHIELD_S = HP_pb.MESSAGE_CANCEL_SHIELD_S,
-- MESSAGE_SHIELD_S = HP_pb.MESSAGE_SHIELD_S
};

local EquipPartNames = {
["Helmet"] 		= Const_pb.HELMET,
["Neck"]		= Const_pb.NECKLACE,
["Finger"]		= Const_pb.RING,
["Wrist"]		= Const_pb.GLOVE,
["Waist"]		= Const_pb.BELT,
["Feet"]		= Const_pb.SHOES,
["Chest"]		= Const_pb.CUIRASS,
["Legs"]		= Const_pb.LEGGUARD,
["MainHand"]	= Const_pb.WEAPON1,
["OffHand"]		= Const_pb.WEAPON2
};

local option = {
ccbiFile = "ArenaViewEquipmentPopUp.ccbi",
ccbiPadFile = "ArenaViewEquipmentPopUp_ipad.ccbi",
handlerMap = {
onClose			= "onClose",
onShieldMessage = "onShieldMessage", --第三个 屏蔽  解除屏蔽
onSendMessage = "onSendMessage", --第二个 
onAddFriend = "onAddFriend"  ---第四个 
},
opcode = opcodes
};
for equipName, _ in pairs(EquipPartNames) do
	option.handlerMap["on" .. equipName] = "showEquipDetail";
end

local ViewPlayerInfoPageBase = {};

local PBHelper	= require("PBHelper");

local ItemManager = require("Item.ItemManager");

local thisPlayerId = 0;
local thisPlayerName = ""
local playerInfo = {};
local thisFlagShowButton = false
local isKakaoFriend = false
-----------------------------------------------
--EquipPageBase页面中的事件处理
----------------------------------------------

function ViewPlayerInfoPageBase:onLoad(container)
	local height = CCDirector:sharedDirector():getWinSize().height
	if height<900 then
		container:loadCcbiFile(option.ccbiPadFile);
	else
		container:loadCcbiFile(option.ccbiFile);
	end	
end

function ViewPlayerInfoPageBase:onEnter(container)
	self:setSelectTxtDisappear(container)
	if thisPlayerId == nil then
        thisFlagShowButton = false
    else
        thisFlagShowButton = not (UserInfo.playerInfo.playerId == thisPlayerId)
    end
	
	NodeHelper:setNodesVisible(container,
	{
	mAddFriendNode = thisFlagShowButton,
	mSendMessageNode = thisFlagShowButton,
	mShieldMessageNode = thisFlagShowButton
	})

	UserInfo.sync()
	self:refreshPage(container);
	self:registerPacket(container);
    if Golb_Platform_Info.is_r2_platform then
        NodeHelper:setNodeScale(container, "mName", 0.8, 0.8);
    end
	--self:getPlayerInfo();
end

function ViewPlayerInfoPageBase:setSelectTxtDisappear( container )
	container:getVarSprite("mHelmetPic"):setVisible(false)
	
	container:getVarSprite("mFingerPic"):setVisible(false)
	container:getVarSprite("mWaistPic"):setVisible(false)
	container:getVarSprite("mChestPic"):setVisible(false)
	container:getVarSprite("mMainHandPic"):setVisible(false)
	container:getVarSprite("mOffHandPic"):setVisible(false)
	container:getVarSprite("mLegsPic"):setVisible(false)
	container:getVarSprite("mFeetPic"):setVisible(false)
	container:getVarSprite("mWristPic"):setVisible(false)
	container:getVarSprite("mNeckPic"):setVisible(false)
end

function ViewPlayerInfoPageBase:onExit(container)
	self:removePacket(container);
	ViewPlayerInfo:clearInfo();
	--清除纹理缓存
	GameUtil:purgeCachedData();
end
----------------------------------------------------------------
function ViewPlayerInfoPageBase:getPlayerInfo()
	ViewPlayerInfo:getInfo(thisPlayerId,thisPlayerName);
end

function ViewPlayerInfoPageBase:refreshPage(container)
	self:showPlayerInfo(container);
	self:showFightAttrInfo(container);
	self:showEquipInfo(container);
	self:showFunctionButtonInfo(container)
end

function ViewPlayerInfoPageBase:showFunctionButtonInfo(container)
	local lb2Str = {
	mShieldMessage 			= ViewPlayerInfo:isShieldLabelStr(),
	mSendMessage 				= ViewPlayerInfo:isSendAllowLabelStr(),
	mAddFriend			= ViewPlayerInfo:isFriendLabelStr(),	
	};
	NodeHelper:setStringForLabel(container, lb2Str);
end


function ViewPlayerInfoPageBase:showPlayerInfo(container)
	local level = ViewPlayerInfo:getRoleInfo().level;
	local lb2Str = {
	mHpNum 					= ViewPlayerInfo:getRoleAttrById(Const_pb.HP),
	mMpNum 					= ViewPlayerInfo:getRoleAttrById(Const_pb.MP),
	mLV						= common:getR2LVL() .. ViewPlayerInfo:getRoleInfo().level,
	mName				 	= UserInfo.getOtherLevelStr(ViewPlayerInfo:getRoleInfo().rebirthStage, ViewPlayerInfo:getRoleInfo().level).. " " ..  ViewPlayerInfo:getRoleInfo().name,
	mFightingCapacityNum 	= ViewPlayerInfo:getRoleInfo().fight,
	mPlayerId 				= "ID: " .. ViewPlayerInfo:getPlayerInfo().playerId,
	mOccupationName			= ViewPlayerInfo:getProfessionName()
	};
	NodeHelper:setStringForLabel(container, lb2Str);

	-- 称号
	local titleNode = container:getVarLabelBMFont("mPlayerTitle")
	local titleSprite = container:getVarSprite("mPlayerTitleSprite")
	titleManager:setLabelTitleWithBG(titleNode,ViewPlayerInfo:getTittleInfo().titleId)
	titleManager:setTitleBG(titleSprite,ViewPlayerInfo:getTittleInfo().titleId)

	local roleId = ViewPlayerInfo:getRoleInfo().itemId;
	local RoleManager = require("PlayerInfo.RoleManager");
	NodeHelper:setSpriteImage(container, {
		mOccupation = RoleManager:getOccupationIconById(roleId)
	});
	--local switch = GameConfig.platformSwitch[GamePrecedure:getInstance():getPlatformName()]		
	if GameConfig.ShowSpineAvatar == false then 
		NodeHelper:setSpriteImage(container, {
		mHeroPic 	= RoleManager:getPosterById(roleId)
	});
	NodeHelper:setNodesVisible(container, {
							mHeroPic = true})
	else
		local heroNode = container:getVarNode("mHero");
		if heroNode then
			local heroSprite = container:getVarSprite("mHeroPic")
			if heroSprite then
				heroSprite:setVisible(false)
			end	
			heroNode:removeAllChildren()
			local spineCCBI = ScriptContentBase:create(GameConfig.SpineCCBI[roleId])
			heroNode:addChild(spineCCBI)
			local spineContainer = spineCCBI:getVarNode("mSpineNode");
			if spineContainer then
				spineContainer:removeAllChildren();
                local spine = nil
                local spineNode = nil
                local roleData = ConfigManager.getRoleCfg()[roleId]
                local spinePath, spineName = unpack(common:split((roleData.spine), ","))
				spine = SpineContainer:create(spinePath, spineName)
				spineNode = tolua.cast(spine, "CCNode");
                spineNode:setScale(roleData.spineScale)
				--spineNode:setScale(0.8)
                --end
				spineContainer:addChild(spineNode);
                local offset_X_Str  , offset_Y_Str = unpack(common:split((roleData.offset), ","))
    NodeHelper:setNodeOffset(spineNode , tonumber(offset_X_Str) , tonumber(offset_Y_Str))
				spine:runAnimation(1, "Stand", -1);
			end
			spineCCBI:release()
		end	
	end
end

function ViewPlayerInfoPageBase:showFightAttrInfo(container)
	local lb2Str = {
	mStrengthNum 			= ViewPlayerInfo:getRoleAttrById(Const_pb.STRENGHT),
	mDamageNum 				= ViewPlayerInfo:getDamageString(),
	mDexterityNum			= ViewPlayerInfo:getRoleAttrById(Const_pb.AGILITY),
	mArmorNum				= ViewPlayerInfo:getRoleAttrById(Const_pb.ARMOR),
	mCritRatingNum			= ViewPlayerInfo:getRoleAttrById(Const_pb.CRITICAL),
	mIntelligenceNum	 	= ViewPlayerInfo:getRoleAttrById(Const_pb.INTELLECT),
	mCreateRoleNum			= ViewPlayerInfo:getRoleAttrById(Const_pb.MAGDEF),
	mDodgeNum				= ViewPlayerInfo:getRoleAttrById(Const_pb.DODGE),
	mStaminaNum				= ViewPlayerInfo:getRoleAttrById(Const_pb.STAMINA),
	mHitRatingNum			= ViewPlayerInfo:getRoleAttrById(Const_pb.HIT),
	mTenacityNum 			= ViewPlayerInfo:getRoleAttrById(Const_pb.RESILIENCE)
	};
	NodeHelper:setStringForLabel(container, lb2Str);
end

function ViewPlayerInfoPageBase:showEquipInfo(container)
	local lb2Str = {};
	local sprite2Img = {};
	local itemImg2Qulity = {};
	local scaleMap = {};
	local nodesVisible = {};
	
	for equipName, part in pairs(EquipPartNames) do
		local levelStr = "";
		local enhanceLvStr = "";
		local icon = GameConfig.Image.ClickToSelect;
		local quality = GameConfig.Default.Quality;
		local aniVisible = false;
		local gemVisible = false;
		
		local name 	= "m" .. equipName;
		local roleEquip = ViewPlayerInfo:getRoleEquipByPart(part);
		local userEquip = nil;
		if roleEquip then
			local equipId = roleEquip.equipItemId;
			levelStr = common:getR2LVL() .. EquipManager:getLevelById(equipId);
			enhanceLvStr = "+" .. roleEquip.strength;
			icon = EquipManager:getIconById(equipId);
			quality = EquipManager:getQualityById(equipId);
			container:getVarSprite("m" .. equipName .. "Pic"):setVisible(true)
			
			userEquip = ViewPlayerInfo:getEquipById(roleEquip.equipId);
			aniVisible = UserEquipManager:isEquipGodly(userEquip);
			local gemInfo = PBHelper:getGemInfo(roleEquip.gemInfo);
			if table.maxn(gemInfo) > 0 then
				gemVisible = true;
				for i = 1, 4 do
					local gemId = gemInfo[i];
					nodesVisible[name .. "GemBG" .. i] = gemId ~= nil;
					local gemSprite = name .. "Gem0" .. i;
					nodesVisible[gemSprite] = false;
					if gemId ~= nil and gemId > 0 then
						local icon = ItemManager:getGemSmallIcon(gemId);
						if icon then
							nodesVisible[gemSprite] = true;
							sprite2Img[gemSprite] = icon;
						end
					end
				end
			end
		end
		
		lb2Str[name .. "Lv"] 			= levelStr;
		lb2Str[name .. "LvNum"]			= enhanceLvStr;
		sprite2Img[name .. "Pic"] 		= icon;
		itemImg2Qulity[name] 			= quality;
		scaleMap[name .. "Pic"] 		= 1.0;
		nodesVisible[name .. "Ani"]		= aniVisible;
		nodesVisible[name .. "GemNode"]	= gemVisible;
		nodesVisible[name .. "Point"] 	= false;
		
		NodeHelper:addEquipAni(container, name .. "Ani", aniVisible, nil, userEquip);
	end
	
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, itemImg2Qulity);
	NodeHelper:setNodesVisible(container, nodesVisible);
end

----------------click event------------------------
function ViewPlayerInfoPageBase:showEquipDetail(container, eventName)
	local part = EquipPartNames[string.sub(eventName, 3)];
	local roleEquip = ViewPlayerInfo:getRoleEquipByPart(part);
	if roleEquip then
		PageManager.viewEquipInfo(roleEquip.equipId);
	end
end

function ViewPlayerInfoPageBase:onClose()
	PageManager.popPage(thisPageName);
end

--留言
function ViewPlayerInfoPageBase:onLeaveMessage(container)
	if ViewPlayerInfo:getPlayerInfo().playerId == UserInfo.playerInfo.playerId then
		MessageBoxPage:Msg_Box("@MessageToSelfErro")
		return
	end
	
	LeaveMsgDetail_setPlayId( ViewPlayerInfo:getPlayerInfo().playerId , ViewPlayerInfo:getRoleInfo().name)
	PageManager.pushPage("LeaveMessageDetailPage")
end

--屏蔽消息
function ViewPlayerInfoPageBase:onShieldMessage(container)
	if ViewPlayerInfo.isShield then
		--解除屏蔽 1 屏蔽 2 取消屏蔽
		local msg = Friend_pb.HPMsgShield();
		msg.playerId = ViewPlayerInfo:getPlayerInfo().playerId;
		msg.type = 2
		common:sendPacket(HP_pb.MESSAGE_CANCEL_SHIELD_C, msg);
	else
		--屏蔽
		local msg = Friend_pb.HPMsgShield();
		msg.playerId = ViewPlayerInfo:getPlayerInfo().playerId;
		msg.type = 1
		common:sendPacket(HP_pb.MESSAGE_SHIELD_C, msg);
	end
end

--发送消息
function ViewPlayerInfoPageBase:onSendMessage(container)
	if ViewPlayerInfo.isSendAllow then
		--跳转到个人聊天页面
		local ChatManager = require("Chat.ChatManager")
		local Friend_pb = require("Friend_pb")
		--add playerinfo into msgbox
		local chatUnit = Friend_pb.MsgBoxUnit()
		chatUnit.playerId = ViewPlayerInfo:getPlayerInfo().playerId
		chatUnit.name = ViewPlayerInfo:getRoleInfo().name
		chatUnit.level = ViewPlayerInfo:getRoleInfo().level
		chatUnit.roleItemId = ViewPlayerInfo:getRoleInfo().itemId
        chatUnit.avatarId = ViewPlayerInfo:getRoleInfo().avatarId
		--私聊聊天记录修改
		if isSaveChatHistory then
			ChatManager.insertSortChatPrivate(chatUnit.playerId)
		end
		ChatManager.insertPrivateMsg(ViewPlayerInfo:getPlayerInfo().playerId,chatUnit,nil, false,false)
		ChatManager.setCurrentChatPerson(ViewPlayerInfo:getPlayerInfo().playerId)
		if MainFrame:getInstance():getCurShowPageName() == "ChatPage" then
			PageManager.popAllPage()	
			PageManager.refreshPage("ChatPage","PrivateChat")
		else
			PageManager.popAllPage()
			
		end
	else
		MessageBoxPage:Msg_Box("@PrivateChatLimitInvoke")
	end
end

--添加或删除消息
function ViewPlayerInfoPageBase:onAddFriend(container)
	if Golb_Platform_Info.is_entermate_platform and isKakaoFriend then
	
	else
		if ViewPlayerInfo.isFriend then
			--删除好友
			local msg = Friend_pb.HPFriendDel();
			msg.targetId = ViewPlayerInfo:getPlayerInfo().playerId;
			common:sendPacket(HP_pb.FRIEND_DELETE_C, msg);
		else
			--添加好友
			local msg = Friend_pb.HPFriendAdd();
			msg.targetId = ViewPlayerInfo:getPlayerInfo().playerId;
			common:sendPacket(HP_pb.FRIEND_ADD_C, msg);
		end
	end
end

--------------------------------------------------------

--回包处理

function ViewPlayerInfoPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	
	if opcode == opcodes.FRIEND_ADD_S then
		ViewPlayerInfo:setIsFriend(true)
		MessageBoxPage:Msg_Box("@AddFriendSuccess")
		self:showFunctionButtonInfo(container)
		PageManager.refreshPage("FriendPage");
	end
	
	if opcode == opcodes.FRIEND_DELETE_S then
		ViewPlayerInfo:setIsFriend(false)
		MessageBoxPage:Msg_Box("@DelFriendSuccess")
		self:showFunctionButtonInfo(container)
		PageManager.refreshPage("FriendPage");
	end
	
	if opcode == opcodes.MESSAGE_SHIELD_S then
		ViewPlayerInfo:setIsShield(true)
		MessageBoxPage:Msg_Box("@SheMsgSuccess")
		self:showFunctionButtonInfo(container)
		local ChatManager = require("Chat.ChatManager")
		ChatManager.addShieldList(ViewPlayerInfo:getPlayerInfo().playerId)
	end
	
	if opcode == opcodes.MESSAGE_CANCEL_SHIELD_S then
		ViewPlayerInfo:setIsShield(false)
		MessageBoxPage:Msg_Box("@UnSheMsgSuccess")
		self:showFunctionButtonInfo(container)
		local ChatManager = require("Chat.ChatManager")
		ChatManager.removeShieldList(ViewPlayerInfo:getPlayerInfo().playerId)
	end

end


function ViewPlayerInfoPageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function ViewPlayerInfoPageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local ViewPlayerInfoPage = CommonPage.newSub(ViewPlayerInfoPageBase, thisPageName, option);

function ViewPlayerInfoPage_setPlayerId(playerId ,flagShowButton,flagKakaoFriend,playerName)
	thisPlayerId = tonumber(playerId)
	if flagShowButton == nil then
		thisFlagShowButton = true
	else
		thisFlagShowButton = flagShowButton
	end
	isKakaoFriend = flagKakaoFriend
	thisPlayerName =tostring( playerName)
end
