local Battle_pb =  require "Battle_pb"
local Const_pb = require "Const_pb"


local thisPageName = "MercenaryHaloPage"
local NodeHelper = require("NodeHelper");
local MercenaryHaloManager = require("Mercenary.MercenaryHaloManager")
local ringCfg = ConfigManager.getMercenaryRingCfg();
local NewbieGuideManager = require("NewbieGuideManager")
local UserEquipManager = require("Equip.UserEquipManager")

local option = {
	ccbiFile = "MercenaryHaloPage.ccbi",
	handlerMap = {
		onActivationHalo = "onActivationHalo",
		onFeet01 = "onFeet01",
		onFeet02 = "onFeet02",
		onFeet03 = "onFeet03",
        onUpgradeHalo = "onUpgradeHalo",
		onClose = "onClose",
		onHelp = "onHelp"
	}
}	

local MercenaryHaloPage = {}

local curIndex = 1
local groupMap = {}
local selectedMercenary = {}
local thisContainer = nil
----------------------------------------------------------------------------------

-----------------------------------------------
--MercenaryHaloPage
----------------------------------------------

function MercenaryHaloPage:onFeet01(container)
	curIndex = 1
	MercenaryHaloPage:refreshPage(container)
end

function MercenaryHaloPage:onFeet02(container)
	curIndex = 2
	MercenaryHaloPage:refreshPage(container)
end

function MercenaryHaloPage:onFeet03(container)
	curIndex = 3
	MercenaryHaloPage:refreshPage(container)
end
function MercenaryHaloPage:onUpgradeHalo(container)
    RegisterLuaPage("MercenaryHaloEnhancePage")
	   -- MercenaryHaloEnhancePage_setSelectedMer(selectedMercenary)
	PageManager.pushPage("MercenaryHaloEnhancePage")
end
function MercenaryHaloPage.onFunction(eventName,container)
	if eventName == "onFeet03" then
		MercenaryHaloPage:onFeet03(container);
	elseif eventName == "onFeet02" then
		MercenaryHaloPage:onFeet02(container);
	elseif eventName == "onFeet01" then
	    MercenaryHaloPage:onFeet01(container);
    elseif eventName == "onActivationHalo" then
        MercenaryHaloPage:onActivationHalo(container);
    elseif eventName == "onUpgradeHalo" then
        MercenaryHaloPage:onUpgradeHalo(container);
	end
end

function MercenaryHaloPage:onEnter(container)
	--container:registerPacket(HP_pb.ROLE_RING_INFO_S)
    self.container = ScriptContentBase:create("MercenaryHaloPage.ccbi")
	self.container:registerFunctionHandler(MercenaryHaloPage.onFunction)
    thisContainer = self.container
    selectedMercenary = MercenaryPage_getCurSelectMerRoleInfo();
	--container:registerMessage(MSG_MAINFRAME_REFRESH)
	self:refreshPage(self.container);		
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_MERCENARYHALO)
    return self.container
end


function MercenaryHaloPage:onExecute(container)
	
end

function MercenaryHaloPage:onExit(container)
	curIndex = 1
	--container:removeMessage(MSG_MAINFRAME_REFRESH)
	container:removePacket(HP_pb.ROLE_RING_INFO_S)
end

----------------------------------------------------------------

function MercenaryHaloPage:showHaloAni(container,index,aniVisible)
	local aniNode = container:getVarNode("mAniNode"..index);
	if aniNode then
		aniNode:removeAllChildren();
		if aniVisible then
			local ccbiFile = GameConfig.GodlyEquipAni["Second"];
			local ani = CCBManager:getInstance():createAndLoad2(ccbiFile);
			ani:unregisterFunctionHandler();
			aniNode:addChild(ani);
		end
		aniNode:setVisible(aniVisible);
	end
end

function MercenaryHaloPage:showRedPoint(container,index,visible)
	local hintNode = container:getVarNode("mHintNode"..index);
	if hintNode then
		hintNode:setVisible(visible);
	end
end

function MercenaryHaloPage:refreshPage(container)
	
	if selectedMercenary.itemId == 7 then
		groupMap = MercenaryHaloManager.WGroup
	elseif selectedMercenary.itemId == 8 then
		groupMap = MercenaryHaloManager.HGroup
	elseif selectedMercenary.itemId == 9 then
		groupMap = MercenaryHaloManager.MGroup
	end		
	local starLevel = tonumber(selectedMercenary.starLevel)
	local picMap, nameMap,colorMap = {},{},{}	
	for i=1,#groupMap do
		local oneRing = groupMap[i]
		local ringId = oneRing["ringId"]			
		nameMap[string.format("mNum%d", i)]	= MercenaryHaloManager:getNameByRingId(ringId)
		picMap[string.format("mTextPic%02d", i)] = MercenaryHaloManager:getIconByRingId(ringId)	
		--判断是否被激活
		if starLevel>= tonumber(MercenaryHaloManager:getStarLimitByRingId(ringId)) then			
			if MercenaryHaloManager:checkActivedByItemId(selectedMercenary.roleId,ringId) then
				UserEquipManager:setRedPointNotice(selectedMercenary.roleId, true)
				self:showHaloAni(container,i,true)				
				self:showRedPoint(container,i,false)
			else
				self:showHaloAni(container,i,false)			
				self:showRedPoint(container,i,true)
			end	
		else
			self:showHaloAni(container,i,false)			
			self:showRedPoint(container,i,false)
		end
	end
	NodeHelper:setStringForLabel(container, nameMap);	
	NodeHelper:setSpriteImage(container, picMap);
	local ringItemId = groupMap[curIndex]["ringId"]
	local hasRing,ringInfo = MercenaryHaloManager:getRingInfoByItemIdNRoleId(ringItemId,selectedMercenary.roleId)
	local _haloEffect = ""
	if hasRing then
		local curLevel =  ringInfo.level or 1
		_haloEffect = MercenaryHaloManager:getDiscribeByItemItNLevel(ringInfo.itemId,curLevel)
	else	
		_haloEffect = MercenaryHaloManager:getDiscribeByRingId(ringItemId)
	end
	NodeHelper:setStringForLabel(container,{
		mActivationConditions = MercenaryHaloManager:getConditionByRingId(ringItemId),
		mHaloEffect = _haloEffect,
		mConsumptionGoldNumber = " ".. MercenaryHaloManager:getConsumeByRingId(ringItemId)
	})
	
	local htmlNode = container:getVarLabelBMFont("mHaloEffect")
	if htmlNode then
		local str = "<font color=\"#FFFFF\" face = \"HelveticaBD30\" ><p style=\"margin:10px\" >" .. _haloEffect .. "<br/>" .. Language:getInstance():getString("@Ring_Desc").. "</p></font>"
		local htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition( htmlNode, CCSize(600,96),str )
		htmlNode:setVisible(false)
		htmlLabel:setScale(htmlNode:getScale())
	end
	
	if curIndex ==1 then
		NodeHelper:setNodesVisible(container,{
			mHand1BG = true,
			mHand2BG = false,
			mHand3BG = false,
		})
	elseif curIndex ==2 then
		NodeHelper:setNodesVisible(container,{
			mHand1BG = false,
			mHand2BG = true,
			mHand3BG = false,
		})
	elseif curIndex ==3 then
		NodeHelper:setNodesVisible(container,{
			mHand1BG = false,
			mHand2BG = false,
			mHand3BG = true,
		})
	end
	
	local activeBtn = container:getVarMenuItemImage("mActivationHalo")
	local activeBtnNameMap = {}
	local isActivity = false
	NodeHelper:setNodesVisible(container, {mActivationHaloBtn = true})	
	if starLevel>= tonumber(MercenaryHaloManager:getStarLimitByRingId(ringItemId)) then	
		--已经被激活了
		if MercenaryHaloManager:checkActivedByItemId(selectedMercenary.roleId,ringItemId) then
			if activeBtn then activeBtn:setEnabled(false) end
			activeBtnNameMap["mActivationHaloLabel"] = common:getLanguageString("@HasActivationHalo")
			colorMap["mActivationConditions"] = GameConfig.ColorMap.COLOR_WHITE
			isActivity = true
			UserEquipManager:setRedPointNotice(selectedMercenary.roleId, true)
		else
			if activeBtn then activeBtn:setEnabled(true) end
			activeBtnNameMap["mActivationHaloLabel"] = common:getLanguageString("@ActivationHalo")
			colorMap["mActivationConditions"] = GameConfig.ColorMap.COLOR_WHITE
		end
	else
		if activeBtn then activeBtn:setEnabled(false) end			
		activeBtnNameMap["mActivationHaloLabel"] = common:getLanguageString("@NotActivationHalo")
		colorMap["mActivationConditions"] = GameConfig.ColorMap.COLOR_RED
	end
	NodeHelper:setStringForLabel(container, activeBtnNameMap);	
	NodeHelper:setColorForLabel(container,colorMap)

    --如果10星并且激活了，则可进入佣兵光环升级页面
    NodeHelper:setNodesVisible(container, {mUpgradeHaloBtn = false})	
    if isActivity and starLevel >= 10 then
    	NodeHelper:setNodesVisible(container, {mUpgradeHaloBtn = true})	
    	NodeHelper:setNodesVisible(container, {mActivationHaloBtn = false})		
        NodeHelper:setMenuItemEnabled(container,"mUpgradeHalo",true);
    else
        NodeHelper:setMenuItemEnabled(container,"mUpgradeHalo",false);
    end
end

----------------click event------------------------
function MercenaryHaloPage:onClose(container)
	PageManager.popPage(thisPageName)
end

function MercenaryHaloPage:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARYHALO)
end

function MercenaryHaloPage:onActivationHalo(container)
	local HP_pb = require("HP_pb")
	local Player_pb = require("Player_pb")
	local message = Player_pb.HPRoleRingActive()
	if message~=nil then
		message.roleId = selectedMercenary.roleId;
		local ringItemId = groupMap[curIndex]["ringId"]	
		message.itemId = 	ringItemId;										
		local pb_data = message:SerializeToString();
		PacketManager:getInstance():sendPakcet(HP_pb.ROLE_RING_ACTIVE_C,pb_data,#pb_data,false);
	end
end


function MercenaryHaloPage:onReceiveMessage(container)
    self:refreshPage(container)			
end


function MercenaryHaloPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()	
	
	if opcode == HP_pb.ROLE_RING_INFO_S then
		--self:refreshPage(container);
		
	end
end
function MercenaryHaloPage_getSelectedEnhanceIndex()
	return curIndex;
end
function MercenaryHaloPage_setSelectedMer(msg)
	selectedMercenary = msg
end
return MercenaryHaloPage
-------------------------------------------------------------------------
--local CommonPage = require("CommonPage");
--local MercenaryHaloPage = CommonPage.newSub(MercenaryHaloPage, thisPageName, option);