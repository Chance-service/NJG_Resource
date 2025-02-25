local Battle_pb =  require "Battle_pb"
local Const_pb = require "Const_pb"


local thisPageName = "MercenaryHaloEnhancePage"
local NodeHelper = require("NodeHelper");
local MercenaryHaloManager = require("Mercenary.MercenaryHaloManager")
local ringCfg = ConfigManager.getMercenaryRingCfg();
local ringLvlCfg = ConfigManager.getRingLevelConfig()
local ItemManager = require("Item.ItemManager")

local PageInfo = {
	curMercenaryInfo = {},
	SoulStoneInfo = {},
	SoulStoneIds = {}, 
	SoulSelectedStone = {},
	curRingInfo = {},
    curExp = 0;
    curLevel = 0;
	starStoneTimes = 0,
	starStoneMaxTimes = 9,  --current is 3
}

local slotSize =3 


local option = {
	ccbiFile = "MercenaryHaloTopPopUp.ccbi",
	handlerMap = {
		onActivationHalo = "onActivationHalo",
		onHaloFeet01 = "onFeet01",
		onHaloFeet02 = "onFeet02",
		onHaloFeet03 = "onFeet03",
		onClose = "onClose",
		onHelp = "onHelp",
        onAKeyInto = "onOneKeyPutIn",
        onSynthesisBook = "onSynthesisBook",
        onUpgradeImmediately = "onUpgradeImmediately"
	}
}	

local MercenaryHaloEnhancePage = {}

local curIndex = 1
local groupMap = {}
----------------------------------------------------------------------------------

-----------------------------------------------
--MercenaryHaloEnhancePage
----------------------------------------------

function MercenaryHaloEnhancePage.onFunctionExt(eventName, container)
	if eventName:sub(1, 6) == "onFeet" then
		MercenaryHaloEnhancePage:onCancleGoods( eventName:sub(8) , container )
	elseif eventName:sub(1, 11) == "onStoneFeet" then
		MercenaryHaloEnhancePage:onSelectGoods( eventName:sub(13) , container )
	end
end


function MercenaryHaloEnhancePage:initSoulStoneInfo( container )
    local UserInfo = require("PlayerInfo.UserInfo");
    local ConfigManager = require("ConfigManager")
    local UserItemManager = require("Item.UserItemManager")
	PageInfo.SoulStoneIds = UserItemManager:getItemIdsByType(Const_pb.SOUL_STONE)
	table.sort( PageInfo.SoulStoneIds,function (e1, e2)
		if not e2 then return true end
		if not e1 then return false end
		if e1 > e2 then
			return true
		end
		return false
	end )
	PageInfo.SoulStoneInfo = {}
    PageInfo.SoulSelectedStone = {}
	for k,v in ipairs(PageInfo.SoulStoneIds) do
		if v ~= 90002 then
			--去掉训练书页
			userItemInfo = UserItemManager:getUserItemByItemId( v )
			
			PageInfo.SoulStoneInfo[v] = {} -- userItemInfo
			PageInfo.SoulStoneInfo[v].id = userItemInfo.id
			PageInfo.SoulStoneInfo[v].itemId = userItemInfo.itemId
			PageInfo.SoulStoneInfo[v].count = userItemInfo.count
			PageInfo.SoulStoneInfo[v].status = userItemInfo.status
		else
            table.remove(PageInfo.SoulStoneIds , k)	
		end
	end
	
	PageInfo.starStoneTimes = MercenaryHaloManager:getCurLvlUpTime()
    
	PageInfo.starStoneMaxTimes = 9
end

function MercenaryHaloEnhancePage:onCancleGoods( eventIndex , container )
	MercenaryHaloEnhancePage.cancelOneStone( eventIndex )
	self:refreshActivatePage( container )
end

function MercenaryHaloEnhancePage:onSelectGoods( eventIndex , container )
	if PageInfo.starStoneTimes >= PageInfo.starStoneMaxTimes then
		MessageBoxPage:Msg_Box_Lan("@HaloPromptTimesOut")
		return
	end
	if table.maxn( PageInfo.SoulSelectedStone ) >= slotSize then return end
	MercenaryHaloEnhancePage.addOneStone( eventIndex )
	self:refreshActivatePage(container)
end


function MercenaryHaloEnhancePage:showOwnStone( container )
	local i = 1		
	for _,itemId in pairs( PageInfo.SoulStoneIds ) do
		local userItemInfo = PageInfo.SoulStoneInfo[itemId]
		local itemInfo = ItemManager:getItemCfgById( itemId )	
		if userItemInfo and itemInfo then
			container:getVarSprite("mStonePic0" .. i):setTexture(itemInfo.icon)
			container:getVarLabelBMFont("mStoneName0" .. i):setVisible(true)
			container:getVarLabelBMFont("mStoneName0" .. i):setString( itemInfo.name )
			container:getVarLabelBMFont("mStoneNum0" .. i):setVisible(true)
			container:getVarLabelBMFont("mStoneNum0" .. i):setString( userItemInfo.count )
			local itemName = "mStoneFeet0" .. i
			NodeHelper:setMenuItemQuality( container , itemName ,itemInfo.quality  )
			i = i + 1
		end
	end		
	
	for j = i,4,1 do
	    container:getVarLabelBMFont("mStoneName0" .. j):setVisible(false)
	    container:getVarSprite( "mStonePic0" .. j ):setTexture(GameConfig.Image.DefaultSoulStone)
		container:getVarLabelBMFont("mStoneNum0" .. j):setVisible(false)
		local itemName = "mStoneFeet0" .. j
		NodeHelper:setMenuItemQuality( container , itemName ,GameConfig.Default.Quality  )
	end
			
end

function MercenaryHaloEnhancePage:showSelectedStone( container )
	local i = 1
	for _,itemInfo in pairs( PageInfo.SoulSelectedStone ) do
		container:getVarSprite( "mTextPic0" .. i ):setTexture(itemInfo.icon)
		
		local itemName = "mFeet0" .. i
		NodeHelper:setMenuItemQuality( container , itemName ,itemInfo.quality  )
		
		i = i + 1
	end
	
	for j = i,slotSize,1 do
	    
	    container:getVarSprite( "mTextPic0" .. j ):setTexture(GameConfig.Image.EmptySoulStone)
		local itemName = "mFeet0" .. j
		NodeHelper:setMenuItemQuality( container , itemName ,GameConfig.Default.Quality  )
	end
	
end



function MercenaryHaloEnhancePage:onOneKeyPutIn( container )
    if PageInfo.curLevel >= GameConfig.MerHaloMaxLevel then 
		MessageBoxPage:Msg_Box_Lan("@MaxHaloLevel") 
		return 
	end
	if #PageInfo.SoulSelectedStone >=slotSize then return end
	if PageInfo.starStoneTimes >= PageInfo.starStoneMaxTimes then
        
		MessageBoxPage:Msg_Box_Lan("@HaloPromptTimesOut")
		return
	end

--	local max = 0
--	if PageInfo.starStoneMaxTimes - PageInfo.starStoneTimes > slotSize then
--		max = slotSize
--	else
--		max = PageInfo.starStoneMaxTimes - PageInfo.starStoneTimes
--	end
	local _num = #PageInfo.SoulSelectedStone
	for i = 1, _num , 1 do
		MercenaryHaloEnhancePage.cancelOneStone( "1" )
	end
    local max = PageInfo.starStoneMaxTimes - PageInfo.starStoneTimes
    if PageInfo.starStoneMaxTimes - PageInfo.starStoneTimes > slotSize then
    	max = slotSize
    end
	local removeIds = {}
	for k,v in pairs( PageInfo.SoulStoneIds ) do
		local num = PageInfo.SoulStoneInfo[v].count
		for i = 1, num ,1 do
			local index = #PageInfo.SoulSelectedStone + 1
			--table.insert(PageInfo.SoulSelectedStone , ItemManager:getItemCfgById( v ) )
			PageInfo.SoulStoneInfo[v].count = PageInfo.SoulStoneInfo[v].count - 1
			if PageInfo.SoulStoneInfo[v].count == 0 then
			    table.insert( removeIds , k - #removeIds ) --??remove?± ??remove?????? ???ó?????á?°??
				--table.remove( PageInfo.SoulStoneInfo , v )
			end
			table.insert( PageInfo.SoulSelectedStone , ItemManager:getItemCfgById( v ) )
			local totExp = MercenaryHaloManager:getExpByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel)

			PageInfo.curExp = PageInfo.curExp + ItemManager:getItemCfgById( v ).soulStoneExp
			while PageInfo.curExp >= tonumber(totExp) do		
				PageInfo.curLevel = PageInfo.curLevel+1
				PageInfo.curExp = PageInfo.curExp -totExp
				if PageInfo.curLevel >= GameConfig.MerHaloMaxLevel then 
                    --totExp = stoneItemInfo[9].exp
                    --PageInfo.curMercenaryInfo.starExp = tonumber( totExp )
                    break
                end	
                totExp = MercenaryHaloManager:getExpByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel)
			end	
			PageInfo.SoulSelectedStone[index] = ItemManager:getItemCfgById( v )
			PageInfo.starStoneTimes = PageInfo.starStoneTimes + 1
			if PageInfo.curLevel >= GameConfig.MerHaloMaxLevel then break	end
			if #PageInfo.SoulSelectedStone >= max then break end
		end
		if PageInfo.curLevel >= GameConfig.MerHaloMaxLevel then break	end
		if #PageInfo.SoulSelectedStone >= max then break end
	end
	for k,v in ipairs( removeIds ) do
	    table.remove( PageInfo.SoulStoneIds ,v)
	end
	self:refreshActivatePage( container )
	
end

function MercenaryHaloEnhancePage:onSynthesisBook( container )
    local soulStone = 90002
	ItemManager:setNowSelectItem(soulStone)
	PageManager.pushPage("SoulStoneUpgradePage")
end

function MercenaryHaloEnhancePage:onUpgradeImmediately( container )
    if common:table_size_raw(PageInfo.SoulSelectedStone) == 0 then 
        return 
    end 
	local msg = Player_pb.HPRoleRingIncExp()
	msg.roleId = PageInfo.curMercenaryInfo.roleId	
    msg.ringItemId = PageInfo.curRingInfo.itemId
	for _,v in pairs( PageInfo.SoulSelectedStone ) do
		msg.itemId:append( v.id )
	end
	common:sendPacket(HP_pb.ROLE_RING_INC_EXP_C, msg ,false)
    PageInfo.SoulSelectedStone={}
end


--data handler


function MercenaryHaloEnhancePage.addOneStone( eventIndex )
    if PageInfo.curLevel >= GameConfig.MerHaloMaxLevel then 
        
		MessageBoxPage:Msg_Box_Lan("@MaxStar") 
		return 
	end
	if #PageInfo.SoulSelectedStone >=slotSize then return end
	local id = PageInfo.SoulStoneIds[tonumber(eventIndex)]	
    if PageInfo.SoulStoneInfo[id] == nil then
        return
    end	
	PageInfo.SoulStoneInfo[id].count = PageInfo.SoulStoneInfo[id].count - 1
	if PageInfo.SoulStoneInfo[id].count == 0 then
		table.remove(PageInfo.SoulStoneIds , tonumber(eventIndex) )
		--table.remove( PageInfo.SoulStoneInfo , id )
	end
	table.insert( PageInfo.SoulSelectedStone , ItemManager:getItemCfgById( id ) )

    local totExp = MercenaryHaloManager:getExpByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel)

	PageInfo.curExp = PageInfo.curExp + ItemManager:getItemCfgById( id ).soulStoneExp
	while PageInfo.curExp >= tonumber(totExp) do
		PageInfo.curLevel = PageInfo.curLevel +1
		PageInfo.isNeedRefreshAttr = true
		PageInfo.curExp = PageInfo.curExp -totExp
		totExp = MercenaryHaloManager:getExpByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel)
		if PageInfo.curLevel >= GameConfig.MerHaloMaxLevel then 
            break
        end	
	end
	PageInfo.starStoneTimes = PageInfo.starStoneTimes + 1
end
function MercenaryHaloEnhancePage.cancelOneStone( eventIndex )
	local itemInfo = PageInfo.SoulSelectedStone[tonumber(eventIndex)]
	if itemInfo == nil then return end
	local hasStone = false
	table.foreachi(PageInfo.SoulStoneIds, function(i, v)
			if v == itemInfo.id then
				hasStone = true
			end
		end)
	
	if not hasStone then
		table.insert( PageInfo.SoulStoneIds , itemInfo.id )
		table.sort( PageInfo.SoulStoneIds ,  function (e1, e2)
			if not e2 then return true end
			if not e1 then return false end
			if e1 > e2 then return true	end
			return false
		end)
	end	
	
	PageInfo.SoulStoneInfo[itemInfo.id].count = PageInfo.SoulStoneInfo[itemInfo.id].count + 1
		 
	local totExp = MercenaryHaloManager:getExpByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel)

	PageInfo.curExp = PageInfo.curExp - ItemManager:getItemCfgById( itemInfo.id ).soulStoneExp
	while PageInfo.curExp < 0  do
		PageInfo.curLevel = PageInfo.curLevel -1
		
		totExp = MercenaryHaloManager:getExpByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel)
		PageInfo.curExp = PageInfo.curExp + totExp
	end
	
	table.remove( PageInfo.SoulSelectedStone , tonumber(eventIndex) )
	PageInfo.starStoneTimes = PageInfo.starStoneTimes - 1
end


function MercenaryHaloEnhancePage:onFeet01(container)
	curIndex = 1
	self:refreshPage(container)
end

function MercenaryHaloEnhancePage:onFeet02(container)
	curIndex = 2
	self:refreshPage(container)
end

function MercenaryHaloEnhancePage:onFeet03(container)
	curIndex = 3
	self:refreshPage(container)
end


function MercenaryHaloEnhancePage:onEnter(container)
    PageInfo.curMercenaryInfo = MercenaryPage_getCurSelectMerRoleInfo();
	container:registerPacket(HP_pb.ITEM_INFO_SYNC_S)
	container:registerMessage(MSG_MAINFRAME_REFRESH)
    curIndex = MercenaryHaloPage_getSelectedEnhanceIndex()
    --judge whether has halo and not yet activate
	self:refreshPage(container);		
end


function MercenaryHaloEnhancePage:onExecute(container)
	
end

function MercenaryHaloEnhancePage:onExit(container)
	curIndex = 1
	container:removeMessage(MSG_MAINFRAME_REFRESH)
	container:removePacket(HP_pb.ITEM_INFO_SYNC_S)
end

----------------------------------------------------------------

function MercenaryHaloEnhancePage:showHaloAni(container,index,aniVisible)
	local aniNode = container:getVarNode("mHaloAniNode"..index);
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

function MercenaryHaloEnhancePage:showRedPoint(container,index,visible)
	local hintNode = container:getVarNode("mHaloHintNode"..index);
	if hintNode then
		hintNode:setVisible(visible);
	end
end

function MercenaryHaloEnhancePage:refreshUpperIcon(container)
    --selection state
    if curIndex ==1 then
		NodeHelper:setNodesVisible(container,{
			mHaloHand1BG = true,
			mHaloHand2BG = false,
			mHaloHand3BG = false,
		})
	elseif curIndex ==2 then
		NodeHelper:setNodesVisible(container,{
			mHaloHand1BG = false,
			mHaloHand2BG = true,
			mHaloHand3BG = false,
		})
	elseif curIndex ==3 then
		NodeHelper:setNodesVisible(container,{
			mHaloHand1BG = false,
			mHaloHand2BG = false,
			mHaloHand3BG = true,
		})
	end

    local starLevel = tonumber(PageInfo.curMercenaryInfo.starLevel)
	local picMap, nameMap,colorMap = {},{},{}	
	for i=1,#groupMap do
		local oneRing = groupMap[i]
		local ringId = oneRing["ringId"]			
		nameMap[string.format("mHaloNum%d", i)]	= MercenaryHaloManager:getNameByRingId(ringId)
		picMap[string.format("mHaloTextPic%02d", i)] = MercenaryHaloManager:getIconByRingId(ringId)	
		
		--判断是否被激活
		if starLevel>= tonumber(MercenaryHaloManager:getStarLimitByRingId(ringId)) then			
			if MercenaryHaloManager:checkActivedByItemId(PageInfo.curMercenaryInfo.roleId,ringId) then
				local UserEquipManager = require("Equip.UserEquipManager")
				UserEquipManager:setRedPointNotice(PageInfo.curMercenaryInfo.roleId, true)
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
end

function MercenaryHaloEnhancePage:refreshPage(container)
    --step.1 render the upper three icon and effect since it's not correspond to the data
    if PageInfo.curMercenaryInfo.itemId == 7 then
		groupMap = MercenaryHaloManager.WGroup
	elseif PageInfo.curMercenaryInfo.itemId == 8 then
		groupMap = MercenaryHaloManager.HGroup
	elseif PageInfo.curMercenaryInfo.itemId == 9 then
		groupMap = MercenaryHaloManager.MGroup
	end	
	if groupMap == nil then 
		return
	end
    self:refreshUpperIcon(container)
    --step.2 get the ringItemId and get the correspond level info
	
    local ringItemId = groupMap[curIndex]["ringId"]	
    local hasRing,ringInfo = MercenaryHaloManager:getRingInfoByItemIdNRoleId(ringItemId,PageInfo.curMercenaryInfo.roleId)
    
    if hasRing then
        --如果已经激活，
        PageInfo.curRingInfo = ringInfo or nil
        PageInfo.curExp =  ringInfo.exp or 1
        PageInfo.curLevel =  ringInfo.level or 1
		if  PageInfo.curLevel == 0 then
			 PageInfo.curLevel = 1
		end
        --init soul stone info
        self:initSoulStoneInfo( container )
        NodeHelper:setNodesVisible(container,{
			mNotActivationNode = false,
			mActivationNode = true
		})
        self:refreshActivatePage(container)
        self:showLvlWord(container)
    else
        NodeHelper:setNodesVisible(container,{
			mNotActivationNode = true,
			mActivationNode = false
		})
        self:refreshNonActivatePage(container)
    end
end

function MercenaryHaloEnhancePage:refreshActivatePage(container)
    self:showOwnStone(container)   
    self:showSelectedStone(container)
    self:showTimeAnd9Scale(container)
end

function MercenaryHaloEnhancePage:showTimeAnd9Scale(container)
    --exp and bar
    local curExp = PageInfo.curExp
	local totExp = 0
		
    if PageInfo.curLevel >= GameConfig.MerHaloMaxLevel then 
        container:getVarScale9Sprite("mBar"):setScaleX( 1 )
		container:getVarLabelBMFont("mExperienceValue"):setString( common:getLanguageString( "@MaxHaloLevel" ) )
	else
		totExp = MercenaryHaloManager:getExpByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel)
		container:getVarLabelBMFont("mExperienceValue"):setString( curExp .. "/" .. totExp )
        container:getVarScale9Sprite("mBar"):setScaleX( PageInfo.curExp/totExp )
	end
	--surplus num per day
	local _str = common:getLanguageString("@TodaySurplusNum", PageInfo.starStoneMaxTimes - PageInfo.starStoneTimes, PageInfo.starStoneMaxTimes)
	container:getVarLabelBMFont("mTodaySurplusNum"):setString(_str)
    
end

function MercenaryHaloEnhancePage:getNextLvlWord()
    if PageInfo.curLevel >= GameConfig.MerHaloMaxLevel then
        return common:getLanguageString("@MaxHaloLevel")
    else
        local nextDiscribe = common:stringAutoReturn(
        MercenaryHaloManager:getDiscribeByItemItNLevel(PageInfo.curRingInfo.itemId, PageInfo.curLevel + 1),
        25)

        if Golb_Platform_Info.is_r2_platform then
        	nextDiscribe = MercenaryHaloManager:getDiscribeByItemItNLevel(PageInfo.curRingInfo.itemId, PageInfo.curLevel + 1)
        end
        return nextDiscribe
    end

end

function MercenaryHaloEnhancePage:showLvlWord(container)
    --cur level and next level effect
    local discripe = common:stringAutoReturn(
    MercenaryHaloManager:getDiscribeByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel), 
    25 )
    local nextDis = self:getNextLvlWord();
            
    if Golb_Platform_Info.is_r2_platform then
    	discripe = MercenaryHaloManager:getDiscribeByItemItNLevel(PageInfo.curRingInfo.itemId,PageInfo.curLevel)
    end

    NodeHelper:setStringForLabel(container, {
        mNowConditions = discripe,
        mUpgradeConditions = nextDis,
        mNowConsumptionGoldNumber = PageInfo.curLevel
    });

    if Golb_Platform_Info.is_r2_platform then
    	local htmlNode1 = container:getVarLabelTTF("mNowConditions")
		if htmlNode1 then
			local str = discripe or ""
			NodeHelper:addHtmlLable(container:getVarNode('mNowConditions'), str, GameConfig.Tag.HtmlLable);
			htmlNode1:setVisible(false)
		end

		local htmlNode2 = container:getVarLabelTTF("mUpgradeConditions")
		if htmlNode2 then
			local str = nextDis or ""
			NodeHelper:addHtmlLable(container:getVarNode('mUpgradeConditions'), str, GameConfig.Tag.HtmlLable + 1);
			htmlNode2:setVisible(false)
		end
    end
end

function MercenaryHaloEnhancePage:refreshNonActivatePage(container)
    local ringItemId = groupMap[curIndex]["ringId"]
    local _haloEffect = common:stringAutoReturn( MercenaryHaloManager:getDiscribeByRingId(ringItemId), 25 )
	NodeHelper:setStringForLabel(container,{
		mActivationConditions = MercenaryHaloManager:getConditionByRingId(ringItemId),
		mHaloEffect = _haloEffect,
		mConsumptionGoldNumber = MercenaryHaloManager:getConsumeByRingId(ringItemId)
	})
end


----------------click event------------------------
function MercenaryHaloEnhancePage:onClose(container)
	PageManager.popPage(thisPageName)
end

function MercenaryHaloEnhancePage:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARYHALO)
end

function MercenaryHaloEnhancePage:onActivationHalo(container)
	local HP_pb = require("HP_pb")
	local Player_pb = require("Player_pb")
	local message = Player_pb.HPRoleRingActive()
	if message~=nil then
		message.roleId = PageInfo.curMercenaryInfo.roleId;
		local ringItemId = groupMap[curIndex]["ringId"]	
		message.itemId = 	ringItemId;										
		local pb_data = message:SerializeToString();
		PacketManager:getInstance():sendPakcet(HP_pb.ROLE_RING_ACTIVE_C,pb_data,#pb_data,false);
	end
end


function MercenaryHaloEnhancePage:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == thisPageName then		
			self:refreshPage(container)			
		end
	end
end


function MercenaryHaloEnhancePage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()	
	
    --用于合成时，刷新下方显示逻辑
	if opcode == HP_pb.ITEM_INFO_SYNC_S then
		self:refreshPage(container)
	end
end

function MercenaryHaloEnhancePage_setSelectedMer(msg)
	PageInfo.curMercenaryInfo = msg
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local MercenaryHaloEnhancePage = CommonPage.newSub(MercenaryHaloEnhancePage, thisPageName, option,MercenaryHaloEnhancePage.onFunctionExt);