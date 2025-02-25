----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
registerScriptPage("ReplaceSkillPage");



local NewbieGuideManager = require("Guide.NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = "SkillPage";
local NodeHelper = require("NodeHelper");

    local SkillExPage = require("Skill.SkillExPage")

local option = {
	ccbiFile = "SkillPage.ccbi",
	handlerMap = {
		onHelp				= "showHelp",
		onSkillspecialty	= "enhanceSkill",
		onReplaceSkill		= "replaceSkill",
		onFightSkill		= "onFightSkill",
		onArenaSkill		= "onArenaSkill",
		onDefenseSkill	 	= "onDefenseSkill",
		onReturnBtn			= "onReturn"
		
	},
	opcode = opcodes
}

local skillCfg = ConfigManager.getSkillEnhanceCfg();
local skillOpenCfg = ConfigManager.getSkillOpenCfg()

local SkillPageBase = {}
local SkillPageNormalContent = {}
local SkillPageEmptyContent = {}
local keyCount = 1
--------------------------------------------------------------
local SkillItem = {
	ccbiFile_empty 	= "SkillEmptyContent.ccbi",
	ccbiFile_close	 	= "SkillNotOpenContent.ccbi",
	ccbiFile_open	 	= "SkillOpenContent.ccbi",
}

local PageType = {
    FIGHT_SKILL = 1,
    ARENA_SKILL = 2,
	DEFENSE_SKILL = 3
}

local currPageType = PageType.ARENA_SKILL

----------------------------------------------------------------------------------

-----------------------------------------------
--SkillPageBase页面中的事件处理
----------------------------------------------
function SkillPageBase:onEnter(container)
	container:registerMessage(MSG_MAINFRAME_REFRESH)
	self:registerPackets(container)
	NodeHelper:initScrollView(container, "mContent", 3);
	container.scrollview=container:getVarScrollView("mContent");	
	
	if container.scrollview~=nil then
		container:autoAdjustResizeScrollview(container.scrollview);
	end		
	
	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
	self:selectTab(container)
	self:rebuildAllItem(container);
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_SKILL)

end

function SkillPageBase:onExecute(container)
end

function SkillPageBase:onExit(container)
	self:removePackets(container)
	container:removeMessage(MSG_MAINFRAME_REFRESH)
	NodeHelper:deleteScrollView(container);
end

function SkillPageBase:onReturn(container)
	--PageManager.changePage("MainScenePage")
    PageManager.popPage(thisPageName)
end

function SkillPageBase:selectTab( container )
	--if currPageType == PageType.FIGHT_SKILL then
	--	container:getVarMenuItem("mFightSkill"):selected()
	--	container:getVarMenuItem("mFightSkill"):setEnabled(false)
	--	container:getVarMenuItem("mArenaSkill"):unselected()
	--	container:getVarMenuItem("mArenaSkill"):setEnabled(true) 
	--	container:getVarMenuItem("mDefenseSkill"):unselected()
	--	container:getVarMenuItem("mDefenseSkill"):setEnabled(true)
	--	
	--	container:getVarNode("mExplain1"):setVisible(true)
	--	container:getVarNode("mExplain2"):setVisible(false)
	--	container:getVarNode("mExplain3"):setVisible(false)
	if currPageType == PageType.ARENA_SKILL then
		--container:getVarMenuItem("mFightSkill"):unselected()
		--container:getVarMenuItem("mFightSkill"):setEnabled(true)
		--container:getVarMenuItem("mArenaSkill"):selected() 
		--container:getVarMenuItem("mArenaSkill"):setEnabled(false)
		--container:getVarMenuItem("mDefenseSkill"):unselected()
		--container:getVarMenuItem("mDefenseSkill"):setEnabled(true)
		
		container:getVarNode("mExplain1"):setVisible(false)
		container:getVarNode("mExplain2"):setVisible(true)
		container:getVarNode("mExplain3"):setVisible(false)
	--else
	--	container:getVarMenuItem("mFightSkill"):unselected()
	--	container:getVarMenuItem("mFightSkill"):setEnabled(true)
	--	container:getVarMenuItem("mArenaSkill"):unselected() 
	--	container:getVarMenuItem("mArenaSkill"):setEnabled(true)
	--	container:getVarMenuItem("mDefenseSkill"):selected()
	--	container:getVarMenuItem("mDefenseSkill"):setEnabled(false)
	--	
	--	container:getVarNode("mExplain1"):setVisible(false)
	--	container:getVarNode("mExplain2"):setVisible(false)
	--	container:getVarNode("mExplain3"):setVisible(true)
	end
end

function SkillPageBase:onFightSkill( container )
	currPageType = PageType.FIGHT_SKILL
	self:selectTab( container )
	self:rebuildAllItem(container)
end

function SkillPageBase:onArenaSkill( container )
	currPageType = PageType.ARENA_SKILL
	self:selectTab( container )
	self:rebuildAllItem(container)
end

function SkillPageBase:onDefenseSkill( container )
	currPageType = PageType.DEFENSE_SKILL
	self:selectTab( container )
	self:rebuildAllItem( container )
end

----------------scrollview-------------------------
function SkillPageBase:rebuildAllItem(container)
    --小红点 
    local SEManager = require("Skill.SEManager")
    local SEConfig = require("Skill.SEConfig")
    local UserInfo = require("PlayerInfo.UserInfo")
    UserInfo.syncRoleInfo()
    local ConfigManager = require("ConfigManager")
    local RoleId = UserInfo.roleInfo.itemId
    local roleCfg = ConfigManager.getRoleCfg()
    local profession = roleCfg[RoleId]["profession"]
    if SEManager.HasOpen[profession]~=nil then
        local value = (not SEManager.HasOpen[profession]) and UserInfo.roleInfo.level>=SEConfig.OpenLevel
        NodeHelper:setNodesVisible(container,{mSkillPoint=value})
    else
		NodeHelper:setNodesVisible(container,{mSkillPoint=true})
	end

	self:clearAllItem(container);
	self:buildItem(container);
end

function SkillPageBase:clearAllItem(container)
	NodeHelper:clearScrollView(container);
end

function SkillPageBase:buildItem(container)
    local SkillManager = require("Skill.SkillManager")
	local iCount = 0
	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local fOneItemHeight = 0
	local fOneItemWidth = 0
	
	--人物挂上技能的清单在RoleInfo里面的RoleSkill数组中
	UserInfo.sync()
	local assignedSkills
	if currPageType == PageType.FIGHT_SKILL then
		--assignedSkills = SkillManager:getFightSkillList()
	elseif currPageType == PageType.ARENA_SKILL then
		--assignedSkills = SkillManager:getArenaSkillList()
	elseif currPageType == PageType.DEFENSE_SKILL then
		assignedSkills = SkillManager:getDefenseSkillList()
	end
	
	if assignedSkills == nil then
		CCLuaLog("ERROR  in assignedSkills == null");
		return
	end
	
	--这里传过来几个表示开启了多少个，如果传过来的skillid = 0表示该位置没有放技能
	--如人物30级，开启了3个技能孔，但只有2个技能上阵
	--skillId是数据库的id
	--则传过来的是  {1001,1002,0}，skillId =0 对应  ccbiFile_empty
	--另外一个没开启的技能孔用ccbiFile_close

	local skillSize = #assignedSkills
	
    local oneHeight = 0
	--肯定为4个位置		
	for i=4, 1, -1 do
		local pItemData = CCReViSvItemData:new_local()
		pItemData.mID = i
		pItemData.m_iIdx = i
		--pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)
        pItemData.m_ptPosition = ccp(0, oneHeight)

		local pItem = {}
		if i<= skillSize then
			local skillItemId = SkillManager:getSkillItemIdUsingId(assignedSkills[i])
            local level = SkillManager:getSkillLevelUsingId(assignedSkills[i])
            if skillItemId~=0 then
                level = level~=0 and level or 1
            end
            local skillItemId = tonumber(string.format(tostring(skillItemId).."%0004d",level))
			-- create pItem
			if skillItemId > 0 then
				-- carried
				local ccbiFile = SkillItem.ccbiFile_open
				pItem = ScriptContentBase:create(ccbiFile)
			--	local newStr =GameMaths:stringAutoReturnForLua(skillCfg[skillItemId]["describe"], common:getSkillDetailLength(), 0)
				local lb2Str = {
					mSkillName 		= skillCfg[skillItemId]["name"],
					mConsumptionMp 	= skillCfg[skillItemId]["costMP"],
				--	mSkillTex 		= skillCfg[skillItemId]["describe"],
				--	mNumber			= tostring(i)
				}
				NodeHelper:setStringForLabel(pItem, lb2Str);	
                NodeHelper:setSpriteImage(pItem, { mNumber_1 = "mercenary_skill_" .. i .. ".png" })	
	
				local param = {skillCfg[skillItemId].param1,skillCfg[skillItemId].param2}	
				NodeHelper:setCCHTMLLabel(pItem,"mSkillTex",CCSize(570,96),common:fill(skillCfg[skillItemId]["describe"],unpack(param)),true)				
				local sprite2Img = {
					mChestPic = skillCfg[skillItemId]["icon"],
				}
				NodeHelper:setSpriteImage(pItem, sprite2Img);
				if i == 1 then
					pItem:getVarMenuItemImage("mMobile"):setEnabled(false)
					NodeHelper:setStringForLabel(pItem, {mTex = common:getLanguageString("@FirstRelease")})
				else
					NodeHelper:setStringForLabel(pItem, {mTex = common:getLanguageString("@SkillNotOpenContent_ButtonName")})
				end
				pItem:registerFunctionHandler(SkillPageNormalContent.onFunction)
			else
				-- empty 
				--显示已开启
				local ccbiFile = SkillItem.ccbiFile_empty;
				pItem = ScriptContentBase:create(ccbiFile);
				pItem:registerFunctionHandler(SkillPageEmptyContent.onFunction)
			end
		else -- not open skills
			local ccbiFile = SkillItem.ccbiFile_close;
			pItem = ScriptContentBase:create(ccbiFile);
			local label = pItem:getVarLabelTTF('mOpenLevel')
			if label then
				local openLevel = skillOpenCfg[i] and skillOpenCfg[i].openLevel or 0
				label:setString(common:getLanguageString('@OpenLevel', openLevel))
			end
		end

		if fOneItemHeight < pItem:getContentSize().height then
			fOneItemHeight = pItem:getContentSize().height
		end
        oneHeight = oneHeight + pItem:getContentSize().height
		if fOneItemWidth < pItem:getContentSize().width then
			fOneItemWidth = pItem:getContentSize().width
		end

		if iCount < iMaxNode then
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end

	local size = CCSizeMake(fOneItemWidth, oneHeight)
	container.mScrollView:setContentSize(size)
	container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView:forceRecaculateChildren();
end

----------------click event------------------------
function SkillPageBase:showHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_SKILL)
end

--技能专精，暂未开放
function SkillPageBase:enhanceSkill(container)
	--MessageBoxPage:Msg_Box('@CommingSoon')
    local SEManager = require("Skill.SEManager")
    SEManager:EnterSEPage()
end

function SkillPageBase:replaceSkill(container)
	ReplaceSkillPage_setBagId(currPageType)
	PageManager.pushPage("ReplaceSkillPage")
end

-- ----------------------- empty content----------------------- 
function SkillPageEmptyContent.onFunction(eventName,container)
	if eventName == "luaRefreshItemView" then
		SkillPageEmptyContent.refreshItemView(container)
	elseif eventName == "mSkillBtn" then
	    ReplaceSkillPage_setBagId(currPageType)
		PageManager.pushPage("ReplaceSkillPage")
	end
	
end

function SkillPageEmptyContent.refreshItemView(container)
    local index = container:getItemDate().mID
    local SkillManager = require("Skill.SkillManager")
    local fightList = SkillManager:getFightSkillList()
    local arenaList = SkillManager:getArenaSkillList()
    local defenceList = SkillManager:getDefenseSkillList()
    if index == 1 then
        --local  key = GamePrecedure:getInstance():getUin() .. "_" .. GamePrecedure:getInstance():getServerID() .. "GuideSkill" .. keyCount
        local key = UserInfo.playerInfo.playerId.."_"..GamePrecedure:getInstance():getServerID().."_" .."GuideSkill" .. keyCount
        keyCount = keyCount + 1
        local hasKey = CCUserDefault:sharedUserDefault():getBoolForKey( key )
        UserInfo.sync()
        if fightList[1] == 0 and arenaList[1] == 0 and defenceList[1] == 0 and not hasKey then
            if container:getVarNode("mNewGuide") then 
                container:getVarNode("mNewGuide"):setVisible( true )
            end 
            CCUserDefault:sharedUserDefault():setBoolForKey(key, true)
        else
            container:getVarNode("mNewGuide"):setVisible( false )
        end
    end 
    
end
-- ----------------------- open content----------------------- 
function SkillPageNormalContent.onFunction(eventName,container)
	if eventName == "luaRefreshItemView" then
	elseif eventName == "onMobile" then
		SkillPageNormalContent.onMobile(container);
	end
end

function SkillPageNormalContent.onMobile(container)
    local SkillManager = require("Skill.SkillManager")
    local skillPb = require("Skill_pb")
    local hp = require('HP_pb')
	local index = container:getItemDate().mID
	UserInfo.sync()
	local assignedSkills
	if currPageType == PageType.FIGHT_SKILL then
		assignedSkills = SkillManager:getFightSkillList()
	elseif currPageType == PageType.ARENA_SKILL then
		assignedSkills = SkillManager:getArenaSkillList()
	elseif currPageType == PageType.DEFENSE_SKILL then
		assignedSkills = SkillManager:getDefenseSkillList()
	end
	local msg = skillPb.HPSkillChangeOrder()
	msg.roleId = UserInfo.roleInfo.roleId
	msg.skillId = assignedSkills[index]
	if index < 2 then MessageBoxPage:Msg_Box('@error index in skill reorder') return end
	msg.srcOrder = index - 1
	msg.dstOrder = index - 2
	msg.skillBagId = currPageType
	local pb = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(hp.SKILL_CHANGE_ORDER_C, pb, #pb, true)
end
------------------------------- packet function -----------------------------------------

function SkillPageBase:registerPackets(container)
    local hp = require('HP_pb')
	container:registerPacket(hp.ROLE_CARRY_SKILL_S)
	container:registerPacket(hp.SKILL_CHANGE_ORDER_S)
end

function SkillPageBase:removePackets(container)
    local hp = require('HP_pb')
	container:removePacket(hp.ROLE_CARRY_SKILL_S)
	container:removePacket(hp.SKILL_CHANGE_ORDER_S)
end

function SkillPageBase:onReceivePacket(container)
    local hp = require('HP_pb')
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == hp.SKILL_CHANGE_ORDER_S then
		self:rebuildAllItem(container)
		return
	end

	if opcode == hp.ROLE_CARRY_SKILL_S then
		self:rebuildAllItem(container)
		return
	end
end

function SkillPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			self:rebuildAllItem(container)
		end
	end
end

-------------------------------------------------------------------------
------------------------------------------页面开关
local ClientSettingManager = require("ClientSettingManager")
local hasKey = false
local isUseScrollTab = 0
hasKey,isUseScrollTab =  ClientSettingManager:findAndGetValueByKey("IsUseNewSkillPage") 
if isUseScrollTab~=nil and hasKey==true then
    isUseScrollTab = tonumber(isUseScrollTab)
else
    isUseScrollTab = 0
end


--------------------------------------------------
local CommonPage = require("CommonPage");
if isUseScrollTab == 0 then
    SkillPage = CommonPage.newSub(SkillPageBase, thisPageName, option)
else  
    SkillPage = CommonPage.newSub(SkillExPage, thisPageName, option)
end
