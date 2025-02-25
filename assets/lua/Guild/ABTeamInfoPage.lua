

local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local ABTeamInfoManager = require("Guild.ABTeamInfoManager")
local thisPageName = "ABTeamInfoPage"
local NodeHelper = require("NodeHelper")
local roleConfig = ConfigManager.getRoleCfg()
local hasChangedFlag = false

local opcodes = {
}

local scrollViewList = {
[1] = {},
[2] = {},
[3] = {}
}

local scrollViewFacadeList = {
[1] = {},
[2] = {},
[3] = {}
}

local defaultOffset = nil

local scrollViewOffset = {
[1] = defaultOffset,
[2] = defaultOffset,
[3] = defaultOffset
}

local curSelected = {
index = 0,
pos = 0
}

local refreshAllFlag = false
local mCanCtrl = true

local option = {
ccbiFile = "GuildTeamInformationPopUp.ccbi",
handlerMap = {
onView = "onView",
onMoveUp = "onMoveUp",
onMoveDown = "onMoveDown",
onReplacement = "onReplacement",
onClose = "onClose",
onHelp = "onHelp"
},
DataHelper = ABManager
}
local GuildDataManager = require("Guild.GuildDataManager")

local ABTeamInfoContent = {
ccbiFile 	= "GuildTeamInformationItem.ccbi"
}

function ABTeamInfoContent.onRefreshItemView(container)
	local UserInfo = require("PlayerInfo.UserInfo")
	local mId = tonumber(container:getItemDate().mID)
	local index = math.floor( mId/100 )
	local pos = math.mod(mId,100)
	local ext =""
	local name = ABTeamInfoManager:getPlayerName(index,pos)
	local itemId = ABTeamInfoManager:getPlayerItemId(index,pos)
    local inspireNum = ABTeamInfoManager:getInspireNum(index,pos)    
	local merPic = roleConfig[itemId]["icon"]
    local merIcon = roleConfig[itemId]["proIcon"]
	NodeHelper:setSpriteImage(container, {mPic = merPic});
    NodeHelper:setSpriteImage(container, {mProPic = merIcon});
	
    if inspireNum~=nil and inspireNum>0 then
        ext = "("..inspireNum.."/5)"
    end
    NodeHelper:setStringForLabel(container, {
	mName = tostring(pos).."."..name,
    mLevel = UserInfo.getOtherLevelStr(ABTeamInfoManager:getRebirthStage(index, pos), ABTeamInfoManager:getPlayerLevel(index,pos)),
    mInspireNum = ext
	}) 
	NodeHelper:setNodeScale(container, "mLevel", 0.6, 0.8)
	--判断是否是自己
   
    local playerId = ABTeamInfoManager:getPlayerId(index,pos)
    if UserInfo.playerInfo~=nil then
        if playerId==UserInfo.playerInfo.playerId then
            NodeHelper:setQualityFrames(container, {mFrame = 4});
        end
    end

    --判断是否是会长或副会长
    local isNormal = ABTeamInfoManager:getPlayerFlag(index,pos)
    if isNormal~=0 then
        NodeHelper:setQualityFrames(container, {mFrame = 5});
    end
    

	--MessageBoxPage:Msg_Box("index is "..index.."pos is "..pos.."name is "..name)
	
	if curSelected.index == index and curSelected.pos == pos then
		NodeHelper:setNodesVisible(container,{mHandBG = true})
	else
		NodeHelper:setNodesVisible(container,{mHandBG = false})
	end
end

function ABTeamInfoContent.onSelect(container)
	local mId = tonumber(container:getItemDate().mID)
	local index = math.floor( mId/100 )
	local pos = math.mod(mId,100)
	--MessageBoxPage:Msg_Box("index is "..index.."pos is "..pos)
    local isNormal = GuildDataManager:isNormalMember()
	if isNormal or ABTeamInfoManager.allianceItemInfo.id~=GuildDataManager:getGuildId() or mCanCtrl==false then
		local playerId = ABTeamInfoManager:getPlayerId(index,pos)
		return PageManager.viewPlayerInfo(playerId)
	end
	if curSelected.index == index and curSelected.pos == pos then
		local playerId = ABTeamInfoManager:getPlayerId(index,pos)
		PageManager.viewPlayerInfo(playerId)
	else
		curSelected.index = index
		curSelected.pos = pos
		refreshAllFlag = true
	end
	
end

function ABTeamInfoContent.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		ABTeamInfoContent.onRefreshItemView(container)
	elseif eventName == "onFrame" then
		ABTeamInfoContent.onSelect(container)
	end
end

local ABTeamInfoPage = BasePage:new(option,thisPageName,nil,opcodes)


function ABTeamInfoPage:getPageInfo(container)
	
end

function ABTeamInfoPage:onEnter(container)
	if Golb_Platform_Info.is_entermate_platform then
		NodeHelper:setNodesVisible(container,{mBT_Help_Node = false})
	end
	scrollViewList[1] = container:getVarScrollView("mContent1")
	scrollViewList[2] = container:getVarScrollView("mContent2")
	scrollViewList[3] = container:getVarScrollView("mContent3")
	
	assert(scrollViewList[3]~=nil and scrollViewList[2]~=nil and scrollViewList[1]~=nil, "Error in scrollView name")
	scrollViewFacadeList[1] = CCReViScrollViewFacade:new_local(scrollViewList[1]);
	scrollViewFacadeList[1]:init(6, 3);
    scrollViewFacadeList[1]:setBouncedFlag(true)
	scrollViewFacadeList[2] = CCReViScrollViewFacade:new_local(scrollViewList[2]);
	scrollViewFacadeList[2]:init(6, 3);
    scrollViewFacadeList[2]:setBouncedFlag(true)
	scrollViewFacadeList[3] = CCReViScrollViewFacade:new_local(scrollViewList[3]);
	scrollViewFacadeList[3]:init(6, 3);
    scrollViewFacadeList[3]:setBouncedFlag(true)
	self:rebuildAllItem(container)
	self:refreshPage(container);
    hasChangedFlag = false
end

function ABTeamInfoPage:rebuildAllItem(container)
	for i=1,3 do
		self:rebuildAllItemByIndex(container,i)
	end
end

function ABTeamInfoPage:refreshAllItems(container)
	for i=1,3 do
		--if is curSelected index, set and refresh item into specific index, else just refresh
        if i == curSelected.index then
            local size = ABTeamInfoManager:getTeamSizeByIndex(i)
            local itemIndex = size - curSelected.pos + 3
            scrollViewFacadeList[i]:setAndRefreshItemsByIndex(itemIndex)
        else

            scrollViewFacadeList[i]:refreshDynamicScrollView();
        end
	end
end

function ABTeamInfoPage:rebuildAllItemByIndex(container,index,recordFlag)
    if index == nil or index < 1 or index > 3 then return end
    if recordFlag~=nil and recordFlag then
        scrollViewOffset[index] = scrollViewList[index]:getContentOffset()
    end
	self:clearAllItemByIndex(container,index);
	self:buildItemByIndex(container,index);
end

function ABTeamInfoPage:buildItemByIndex(container,index)
	local ccbiFile = ABTeamInfoContent.ccbiFile
	local size = ABTeamInfoManager:getTeamSizeByIndex(index)
	if size == 0 or ccbiFile == nil or ccbiFile == ''then return end
	local iMaxNode = scrollViewFacadeList[index]:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
	local fOneItemWidth = 0
	local currentPos = 0
	
	local totalSize = size
	for i= totalSize, 1,-1 do
		local pItemData = CCReViSvItemData:new_local()
		pItemData.mID = i + index*100
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp(0, currentPos)
		
		if iCount < iMaxNode then
			ccbiFile = ABTeamInfoContent.ccbiFile
			--local pItem = CCBManager:getInstance():createAndLoad2(ccbiFile)
            local pItem =  ScriptContentBase:create(ccbiFile)
            --local pItem = CCBManager:getInstance():createAndLoad2(ccbiFile)
			--pItem:release();
			pItem.id = iCount
			pItem:registerFunctionHandler(ABTeamInfoContent.onFunction)
			fOneItemHeight = pItem:getContentSize().height
			
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			currentPos = currentPos + fOneItemHeight
			scrollViewFacadeList[index]:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			scrollViewFacadeList[index]:addItem(pItemData)
		end
		iCount = iCount + 1
	end
	
	local contentSize = CCSizeMake(fOneItemWidth, currentPos)
	scrollViewList[index]:setContentSize(contentSize)
	
	if scrollViewOffset[index] == nil then
		local newOffset = ccp(0, scrollViewList[index]:getViewSize().height -
		scrollViewList[index]:getContentSize().height * scrollViewList[index]:getScaleY())
		
	    --if totalSize < 4 then
		--    scrollViewList[index]:setContentOffset(ccp(0, 0))
	    --else
		scrollViewList[index]:setContentOffset(newOffset)
	    --end

	    --scrollViewList[index]:setContentOffset(newOffset)
	    scrollViewFacadeList[index]:setDynamicItemsStartPosition(iCount - 1);
	    scrollViewList[index]:forceRecaculateChildren();
		scrollViewOffset[index] = newOffset
	else
		NodeHelper:setScrollViewStartOffsetEx(scrollViewList[index],scrollViewFacadeList[index],scrollViewOffset[index])
	end
end

function ABTeamInfoPage:clearAllItemByIndex(container,index)
	if scrollViewFacadeList[index] then
		scrollViewFacadeList[index]:clearAllItems();
	end
	if scrollViewList[index]:getContainer() then
		scrollViewList[index]:getContainer():removeAllChildren();
	end
end

function ABTeamInfoPage:onExecute(container)
	if refreshAllFlag then
		self:refreshAllItems(container)
		refreshAllFlag = false
	end
end	

function ABTeamInfoPage:onMoveUp(container)
	local isNormal = GuildDataManager:isNormalMember()
	if isNormal or ABTeamInfoManager.allianceItemInfo.id~=GuildDataManager:getGuildId() or mCanCtrl==false then
		MessageBoxPage:Msg_Box_Lan("@NormalMemberNoRightToChange")
		return 
	end
	if curSelected.index == 0 then
		MessageBoxPage:Msg_Box_Lan("@PleaseSelectOnePersonFirst")
		return 
	else
		curSelected.index,curSelected.pos = ABTeamInfoManager:onUpstair(curSelected.index,curSelected.pos)
        hasChangedFlag = true
        return self:refreshAllItems();
	end
end

function ABTeamInfoPage:onMoveDown(container)
	local isNormal = GuildDataManager:isNormalMember()
	if isNormal or ABTeamInfoManager.allianceItemInfo.id~=GuildDataManager:getGuildId() or mCanCtrl==false then
		MessageBoxPage:Msg_Box_Lan("@NormalMemberNoRightToChange")
		return 
	end
	if curSelected.index == 0 then
		MessageBoxPage:Msg_Box_Lan("@PleaseSelectOnePersonFirst")
		return 
	else
		curSelected.index,curSelected.pos = ABTeamInfoManager:onDownstair(curSelected.index,curSelected.pos)
        hasChangedFlag = true
        return self:refreshAllItems();
	end
end

--保存数据，如果已经保存，点击关闭，则直接关掉
function ABTeamInfoPage:onView(container)
    if hasChangedFlag then
        MessageBoxPage:Msg_Box_Lan("@ABTeamAlreadySaved")
        hasChangedFlag = false
		return ABTeamInfoManager:saveChanges()
    end


    --	if curSelected.index == 0 then
    --		MessageBoxPage:Msg_Box_Lan("@PleaseSelectOnePersonFirst")
    --		return 
    --	else
    --		local playerId = ABTeamInfoManager:getPlayerId(curSelected.index,curSelected.pos)
    --		PageManager.viewPlayerInfo(playerId)
    --	end
end

function ABTeamInfoPage:onClose(container)
	local isNormal = GuildDataManager:isNormalMember()
	if isNormal or ABTeamInfoManager.allianceItemInfo.id~=GuildDataManager:getGuildId() or mCanCtrl==false then
		return PageManager.popPage(thisPageName);
	end
	
    if hasChangedFlag == false then
        return PageManager.popPage(thisPageName);
    end

	local title = common:getLanguageString("@ABTeamInfoSave_Title");
	local msg = common:getLanguageString("@ABTeamInfoSave_Msg");
	PageManager.showConfirm(title, msg, function(isSure)
		if isSure then
            MessageBoxPage:Msg_Box_Lan("@ABTeamAlreadySaved")
			ABTeamInfoManager:saveChanges()
			return PageManager.popPage(thisPageName);
		else
			return PageManager.popPage(thisPageName);
		end
	end);
end

function ABTeamInfoPage:onReplacement(container)
	local isNormal = GuildDataManager:isNormalMember()
	if isNormal or ABTeamInfoManager.allianceItemInfo.id~=GuildDataManager:getGuildId() or mCanCtrl==false then
		MessageBoxPage:Msg_Box_Lan("@NormalMemberNoRightToChange")
	end
	if curSelected.index == 0 then
		MessageBoxPage:Msg_Box_Lan("@PleaseSelectOnePersonFirst")
	else
		local oldIndex = tonumber(curSelected.index)
		local oldPos = tonumber(curSelected.pos)
        local isAddToLast = true
		isAddToLast,curSelected.index,curSelected.pos = ABTeamInfoManager:changeTeamIndex(curSelected.index,curSelected.pos)
        if isAddToLast then 
            --if is add to last pos of list, then scroll to the last pos of the new list and top pos of old list
            scrollViewOffset[curSelected.index] =  ccp(0,0)
            self:rebuildAllItemByIndex(container,curSelected.index)
            scrollViewOffset[oldIndex] =  nil
            self:rebuildAllItemByIndex(container,oldIndex)
        else
            self:rebuildAllItemByIndex(container,curSelected.index,true)
            self:rebuildAllItemByIndex(container,oldIndex,true)
            scrollViewFacadeList[curSelected.index]:refreshDynamicScrollView()
            scrollViewFacadeList[oldIndex]:refreshDynamicScrollView()
        end
        hasChangedFlag = true
        CCLuaLog("curIndex is "..curSelected.index.."old index is "..oldIndex)
	end
end

function ABTeamInfoPage:onExit(container)
	self:removePacket(container)
	scrollViewList = {
	[1] = {},
	[2] = {},
	[3] = {}
	}
	
	scrollViewFacadeList = {
	[1] = {},
	[2] = {},
	[3] = {}
	}
	
	defaultOffset = nil
	
	scrollViewOffset = {
	[1] = defaultOffset,
	[2] = defaultOffset,
	[3] = defaultOffset
	}
	
	curSelected = {
	index = 0,
	pos = 0
	}	
	refreshAllFlag = false
    hasChangedFlag = false
end

function ABTeamInfoPage:refreshPage(container)
	local GuildDataManager = require("Guild.GuildDataManager")
	local isNormal = GuildDataManager:isNormalMember() 
    NodeHelper:setLabelOneByOne(container,"mTeamInforTex","mTeamInforTex2",5)
	if isNormal or ABTeamInfoManager.allianceItemInfo.id~=GuildDataManager:getGuildId() then
		NodeHelper:setNodesVisible(container,{
			mTeamBtnNode1 = false,
            mTeamBtnNode2 = true,
		})
        if ABTeamInfoManager.allianceItemInfo.name ~=nil then
            local str = common:fillHtmlStr('AB_ViewBattleInfo', ABTeamInfoManager.allianceItemInfo.name,
            ABTeamInfoManager.allianceItemInfo.level, ABTeamInfoManager.allianceItemInfo.memSize);
	        NodeHelper:addHtmlLable(container:getVarNode('mTeamCloseTex'),
             str, GameConfig.Tag.HtmlLable,CCSize(600,100))
        end
	else
        if mCanCtrl then
		    NodeHelper:setNodesVisible(container,{
			    mTeamBtnNode1 = true,
                mTeamBtnNode2 = false,
		    })
        else
            NodeHelper:setNodesVisible(container,{
			    mTeamBtnNode1 = false,
                mTeamBtnNode2 = true,
		    })
            if ABTeamInfoManager.allianceItemInfo.name ~=nil then
                local str = common:fillHtmlStr('AB_ViewBattleInfo', ABTeamInfoManager.allianceItemInfo.name,
                ABTeamInfoManager.allianceItemInfo.level, ABTeamInfoManager.allianceItemInfo.memSize);
	            NodeHelper:addHtmlLable(container:getVarNode('mTeamCloseTex'),
                 str, GameConfig.Tag.HtmlLable,CCSize(600,100))
            end
        end
	end
end
--------------Click Event--------------------------------------
function ABTeamInfoPage:onHelp(container)
	require("ABHelpPage")
	showABHelpPageAtIndex(1)
end

function setABTeamInfoCtrlBtn(isCtrlBtn)
	mCanCtrl = isCtrlBtn 
end