local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local CsBattle_pb = require "CsBattle_pb"
local thisPageName = 'CSRankingPage'
local CSRankingPageBase = {}
local RoleCfg = ConfigManager.getRoleCfg()
local RoleManager = require("PlayerInfo.RoleManager")

local option = {
	ccbiFile = "CrossServerWarRankingPopUp.ccbi",
	handlerMap = {
        onClose = "onClose",
        onCloseBtn = "onClose"
	}
}

local opcodes = {
    CS_16_INFO_C = HP_pb.CS_16_INFO_C,
    CS_16_INFO_S = HP_pb.CS_16_INFO_S,
    OPCODE_CS_BATTLEARRAY_INFO_C = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_C,
	OPCODE_CS_BATTLEARRAY_INFO_S = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_S
}

local PageInfo = {
    rankType = 0,
    rankInfo = {}
}
local rankGroup = {
    RANK_1 = 1,
    RANK_2 = 2,
    RANK_3_4 =3,
    RANK_5_8 = 5,
    RANK_9_16 = 9

}
local CSRankingPageItem = {}
----------------------------------------------------

function CSRankingPageItem.onFunction( eventName, container )
    if eventName == "luaRefreshItemView" then
		CSRankingPageItem.onRefreshItemView(container)
	elseif eventName == "onHand" then
		CSRankingPageItem.showPlayerInfo(container)
	end
end

function CSRankingPageItem.onRefreshItemView(container)
    local contentId = container:getItemDate().mID
	local itemInfo = PageInfo.rankInfo[contentId]
    container:getVarSprite("mTrophyPic"):setTexture( GameConfig.CSRankPic[5] )
    if itemInfo.index == rankGroup.RANK_1 then
        container:getVarSprite("mFirstPic"):setVisible( true )
        container:getVarSprite("mSecondPic"):setVisible( false )
        container:getVarLabelBMFont( "mRankingTitle" ):setVisible(false)
    elseif itemInfo.index == rankGroup.RANK_2 then
        container:getVarSprite("mFirstPic"):setVisible( false )
        container:getVarSprite("mSecondPic"):setVisible( true )
        container:getVarLabelBMFont( "mRankingTitle" ):setVisible(true)
        container:getVarLabelBMFont( "mRankingTitle" ):setString( common:getLanguageString("@CSRanking" .. itemInfo.index ) )
    elseif itemInfo.index == rankGroup.RANK_3_4 or itemInfo.index == rankGroup.RANK_5_8 or itemInfo.index == rankGroup.RANK_9_16 then
        container:getVarSprite("mFirstPic"):setVisible( false )
        container:getVarSprite("mSecondPic"):setVisible( false )
        container:getVarLabelBMFont( "mRankingTitle" ):setVisible(true)
        container:getVarLabelBMFont( "mRankingTitle" ):setString( common:getLanguageString("@CSRanking" .. itemInfo.index ) )
    end

    if itemInfo.index < rankGroup.RANK_5_8 then
        container:getVarSprite("mTrophyPic"):setTexture( GameConfig.CSRankPic[itemInfo.index] )
    else
        container:getVarSprite("mTrophyPic"):setTexture( GameConfig.CSRankPic[5] )
    end
            
    container:getVarLabelBMFont("mLv"):setString(common:getLanguageString("@MyLevel", itemInfo.playerLevel))
    container:getVarSprite("mPic"):setTexture( RoleCfg[itemInfo.roleItemId].icon )
    container:getVarSprite("mProfession"):setTexture( RoleManager:getOccupationIconById(itemInfo.roleItemId) )
    container:getVarLabelBMFont("mServerName"):setString( itemInfo.serverName )
    container:getVarLabelTTF("mName"):setString( itemInfo.playerName )
    container:getVarLabelBMFont("mFightingNum"):setString( itemInfo.fightValue )
end

function CSRankingPageItem.showPlayerInfo(container) 
    local contentId = container:getItemDate().mID;
	local itemInfo = PageInfo.rankInfo[contentId]
    local msg = CsBattle_pb.OPCSBattleArrayInfo();
	msg.version = 1;
	msg.viewIdentify = itemInfo.playerIdentify;
		
	local pb_data = msg:SerializeToString();
	PacketManager:getInstance():sendPakcet(opcodes.OPCODE_CS_BATTLEARRAY_INFO_C,pb_data,#pb_data,true);

end

function CSRankingPageBase:onEnter( container )
    self:registerPacket( container )
    NodeHelper:initScrollView( container ,"mContent" ,6 )
    
    if PageInfo.rankType == 1 then
        container:getVarNode("mKingTitlePic"):setVisible(true)
        container:getVarNode("mRebornTitlePic"):setVisible(false)
    else
        container:getVarNode("mKingTitlePic"):setVisible(false)
        container:getVarNode("mRebornTitlePic"):setVisible(true)
    end

    local CSManager = require("PVP.CSManager")
    local msg = CsBattle_pb.HPCS16PlayerInfo();
    msg.type = PageInfo.rankType
    msg.battleId = CSManager.WarStateCache.closeState.battleId - 1
    msg.playerIdentify = CSManager.WarStateCache.playerIdentify
	common:sendPacket(opcodes.CS_16_INFO_C, msg);
end

function CSRankingPageBase:onExecute( container )
    
end

function CSRankingPageBase:onExit( container )
    self:removePacket( container )
    NodeHelper:deleteScrollView(container)
end

function CSRankingPageBase:onClose( container )
    PageManager.popPage( thisPageName )
end

function CSRankingPageBase:refreshPage( container )
    NodeHelper:clearScrollView(container)
    self:buildItem( container )  
end

function CSRankingPageBase:buildItem( container )
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fItemHeight = 0
    local fOneItemHeight = 0
	local fOneItemWidth = 0

	for i= #PageInfo.rankInfo, 1, -1 do
		local pItemData = CCReViSvItemData:new_local()
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp(0, fItemHeight)

		if iCount < iMaxNode then
            local itemInfo = PageInfo.rankInfo[i]
            local ccbiFile = ""
            if itemInfo.index ~= rankGroup.RANK_1 and itemInfo.index ~= rankGroup.RANK_2 and itemInfo.index ~= rankGroup.RANK_3_4 and itemInfo.index ~= rankGroup.RANK_5_8 and itemInfo.index ~= rankGroup.RANK_9_16 then
                ccbiFile = "CrossServerWarRankingContent2"
            else
                ccbiFile = "CrossServerWarRankingContent1"
            end  
			local pItem = ScriptContentBase:create(ccbiFile)
			pItem.id = iCount
			pItem:registerFunctionHandler( CSRankingPageItem.onFunction )
			if fOneItemHeight ~= pItem:getContentSize().height then
				fOneItemHeight = pItem:getContentSize().height
			end

			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
        fItemHeight = fItemHeight + fOneItemHeight
	end

	local size = CCSizeMake(fOneItemWidth, fItemHeight)
	container.mScrollView:setContentSize(size)
	container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView:forceRecaculateChildren();
	ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end

function CSRankingPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == opcodes.CS_16_INFO_S then
		local msg = CsBattle_pb.HPCS16PlayerInfoRet()
        msg:ParseFromString( msgBuff )
        PageInfo.rankInfo = msg.players
        table.sort( PageInfo.rankInfo ,function(p1 ,p2)
            if p1.index > p2.index then
                return false
            end
            return true
        end )
        self:refreshPage( container )
		return
    elseif opcode == opcodes.OPCODE_CS_BATTLEARRAY_INFO_S then
        local msg = CsBattle_pb.OPCSBattleArrayInfoRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		if msg.resultOK then
			--MessageBoxPage:Msg_Box("@CSGetBattleInfoSuccess");
		else
			MessageBoxPage:Msg_Box("@CSGetBattleInfoFailed");
		end
        --
        if msg:HasField("playerInfo") then
            PageManager.viewCSPlayerInfo( msg.playerInfo )
        end
	end
end

function CSRankingPageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function CSRankingPageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

----------------------------------------------------
function CSRankingPageBase_setType( rankType )
    PageInfo.rankType = rankType
end

local CommonPage = require('CommonPage')
local CSRankingPage= CommonPage.newSub(CSRankingPageBase, thisPageName, option)
