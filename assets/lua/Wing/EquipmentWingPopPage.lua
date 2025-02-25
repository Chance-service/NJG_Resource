----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local thisPageName = "EquipmentWingPopPage"
local PageManager  = require("PageManager")
local NodeHelper   = require("NodeHelper")
local UserInfo     = require("PlayerInfo.UserInfo")

roleConfig = ConfigManager.getRoleCfg()

local option = {
	ccbiFile ="EquipmentWingPopUp2.ccbi",
	handlerMap = {
		onHandbook     = "onHandbook",
		onRanking      = "onRanking",
		onWhiteStar    = "onWingStar1",
		onGreenStart   = "onWingStar2",
		onBlueStart    = "onWingStar3",
		on             = "onWingStar4",
		onRewardFeet05 = "onWingStar5",
        onClose        = "onClose"
	},
	-- opcode = opcodes
};
local EquipmentWingPopPage = {};
local m_data = {}
local WingPageTypeEnum = {
	handBook 	= 1,
	ranking 	= 2,
}
local mNoRanking = nil;
-----------------------------------------------
--EquipmentWingPopPage
----------------------------------------------
function EquipmentWingPopPage:onEnter(container)
	EquipmentWingPopPage:switchPage(container, WingPageTypeEnum.handBook)

	NodeHelper:initScrollView(container, "mRankScroll")
	-- EquipmentWingPopPage:reBuildWingRand(container)
	-- 注册数据消息
    container:registerPacket(HP_pb.WING_QUALITY_RANK_S)
    common:sendEmptyPacket(HP_pb.WING_QUALITY_RANK_C)


	local RoleManager = require("PlayerInfo.RoleManager")
	local roleId = UserInfo.roleInfo.itemId
	local profession = RoleManager:getAttrById(roleId, "profession")
    local WingAttrCfg = ConfigManager.getWingAttrCfg()

    m_data.curWingAttrData = WingAttrCfg[profession]

    m_data.curWingIndex = -1
    EquipmentWingPopPage:initGameRes(container)
    EquipmentWingPopPage:onTouchWingByIndex(container, 1)
    mNoRanking = container:getVarLabelBMFont("mNoRanking")
    mNoRanking:setVisible(false)
end

function EquipmentWingPopPage:onExecute(container)

end

function EquipmentWingPopPage:onExit(container)
	for key, node in pairs(m_data.wingAttrLableTable) do
		node:removeFromParentAndCleanup(true)
	end
	m_data = {}
	NodeHelper:deleteScrollView(container)
    container:removePacket(HP_pb.WING_QUALITY_RANK_S)
end

function EquipmentWingPopPage.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		local contentId = container:getItemDate().mID;
		local rankUserInfo = m_data.wingRank[m_data.curWingIndex][contentId]
		local guildName = rankUserInfo.allianceName ~= "no alliance" and rankUserInfo.allianceName or common:getLanguageString("@GuildNoRankList")
		local lb2str = {
			mName 			= (rankUserInfo.playerName or ""),
			mRankingAtt 	= UserInfo.getOtherLevelStr(rankUserInfo.rebirthStage, rankUserInfo.level),
			mGuildName 		= guildName,
			mTime			= common:second2DateString(rankUserInfo.useTime/1000, true),
			mServeName		= ""..(rankUserInfo.rankNum or "")
		}
		NodeHelper:setStringForLabel(container, lb2str)
        if Golb_Platform_Info.is_r2_platform then
            NodeHelper:setNodeScale(container, "mTime", 0.6, 0.6)
            NodeHelper:setLabelOneByOne(container,"mGuildTitle","mGuildName",10,true);
            NodeHelper:setLabelOneByOne(container,"mTimeTitle","mTime",10,true);
        end        
		local pictbl = {
			mWingPic = roleConfig[rankUserInfo.prof].icon
		}
		local strs = {"08", "09", "10"}
		if contentId <= 3 then
			container:getVarNode("mRankpic"):setVisible(true)
			pictbl["mRankpic"] = "UI/WingPage/u_WingPage"..strs[contentId]..".png"
		else
			container:getVarNode("mRankpic"):setVisible(false)
		end
		NodeHelper:setSpriteImage(container, pictbl)
	elseif eventName == "onWingPic" then
		local contentId = container:getItemDate().mID;
		local rankUserInfo = m_data.wingRank[m_data.curWingIndex][contentId]
		PageManager.viewPlayerInfo(rankUserInfo.playerId, true)
	end
end

function EquipmentWingPopPage:reBuildWingRand(container)
	local size = 0
	if m_data.wingRank then
		size = #m_data.wingRank[m_data.curWingIndex]
	end
    if size == 0 then
        local str = common:getLanguageString("@WingNoRanking");
        mNoRanking:setVisible(true)
        mNoRanking:setString(str)
    else
        mNoRanking:setVisible(false)
    end
	NodeHelper:clearScrollView(container)
	NodeHelper:buildScrollView(container, size, "EquipmentWingPopUpContent.ccbi", EquipmentWingPopPage.onFunction);
end

function EquipmentWingPopPage:initGameRes(container)
	-- body
    m_data.wingAttrNode = container:getVarNode("mAttrBaseNode")
    m_data.wingAttrNodeSize = container:getVarNode("mScale9Sprite1"):getContentSize()
    m_data.wingAttrLableTable = {}
end

function EquipmentWingPopPage:reBuildWingBook(container)
	local curAttrTbl = {}
	local sortTbl = {}
	local size = 0
	for key, attr in pairs(m_data.curWingAttrData[m_data.curWingIndex*10].attrs) do
		if curAttrTbl[attr.type] == nil then
			curAttrTbl[attr.type] = 0
			size = size + 1
			sortTbl[#sortTbl+1] = attr.type
		end
		curAttrTbl[attr.type] = curAttrTbl[attr.type] + attr.count
	end
	table.sort(sortTbl)

	for key, node in pairs(m_data.wingAttrLableTable) do
		node:setVisible(false)
	end

	local AttrCount = #sortTbl
	local height = m_data.wingAttrNodeSize.height/math.ceil(AttrCount*0.5)
	if height > 30 then
		height = 30
	end
	local width = m_data.wingAttrNodeSize.width*0.5
	local x = 0
	local y = -height*0.5

	for index, key in pairs(sortTbl) do
		if m_data.wingAttrLableTable[index] == nil then
			local node = CCNode:create()
			local nameLabel = CCLabelBMFont:create("","Lang/heiOutline24.fnt")
			nameLabel:setScale(0.8)
			-- local nameLabel = NodeHelper:setCCHTMLLabel( nil , CCSize(200,30) , "这个lable显示翅膀等级")
			nameLabel:setColor(ccc3(255, 255, 255))
			nameLabel:setPosition(ccp(18, 0))
			nameLabel:setTag(1)
			nameLabel:setAnchorPoint(ccp(0, 0.5))
			node:addChild(nameLabel)

			local valueLabel = CCLabelBMFont:create("","Lang/heiOutline24.fnt")
			valueLabel:setScale(0.8)
			valueLabel:setColor(ccc3(0, 255, 255))
			valueLabel:setPosition(ccp(120, 0))
			valueLabel:setAnchorPoint(ccp(0, 0.5))
			valueLabel:setTag(2)
			node:addChild(valueLabel)

			m_data.wingAttrNode:addChild(node)
			m_data.wingAttrLableTable[index] = node
		end

		local baseNode = m_data.wingAttrLableTable[index]
		baseNode:setVisible(true)
		baseNode:setPosition(ccp(x, y))
		if x == 0 then
			x = width
		else
			x = 0
			y = y - height
		end

		local name
		if key == 2103 or key == 2104 then
			name = common:getLanguageString("@AttrName_" .. key.."_1")
		else
			name = common:getLanguageString("@AttrName_" .. key)
		end
		local value = curAttrTbl[key]
		baseNode:getChildByTag(1):setString(name)
		baseNode:getChildByTag(2):setString(tostring(value))
	end
end

function EquipmentWingPopPage:switchPage(container, pageIndex)
	if m_data.layerType ~= pageIndex then
		m_data.layerType = pageIndex
		local isBookSelected = pageIndex == WingPageTypeEnum.handBook
		local buttonVisible = {}
		buttonVisible["mToRanking"] = not isBookSelected
		buttonVisible["mToHandbook"] = isBookSelected
		NodeHelper:setNodesVisible(container, buttonVisible)

		NodeHelper:setMenuItemSelected(container, {
			mHandbook	= isBookSelected,
			mRanking	= not isBookSelected
		})
	end
end

function EquipmentWingPopPage:onHandbook(container)
	EquipmentWingPopPage:switchPage(container, WingPageTypeEnum.handBook)
end

function EquipmentWingPopPage:onRanking(container)
	EquipmentWingPopPage:switchPage(container, WingPageTypeEnum.ranking)
end

function EquipmentWingPopPage:onWingStar1(container)
	EquipmentWingPopPage:onTouchWingByIndex(container, 1)
end
function EquipmentWingPopPage:onWingStar2(container)
	EquipmentWingPopPage:onTouchWingByIndex(container, 2)
end
function EquipmentWingPopPage:onWingStar3(container)
	EquipmentWingPopPage:onTouchWingByIndex(container, 3)
end
function EquipmentWingPopPage:onWingStar4(container)
	EquipmentWingPopPage:onTouchWingByIndex(container, 4)
end
function EquipmentWingPopPage:onWingStar5(container)
	EquipmentWingPopPage:onTouchWingByIndex(container, 5)
end
function EquipmentWingPopPage:onClose(container)
	PageManager.popPage(thisPageName);
end

function EquipmentWingPopPage:onTouchWingByIndex(container, index)
	if m_data.curWingIndex == index then
		return
	end
	m_data.curWingIndex = index
	-- 排行
	if m_data.wingRank then
		EquipmentWingPopPage:reBuildWingRand(container)
	end

	EquipmentWingPopPage:reBuildWingBook(container)

	-- 翅膀及外框
	local frameFrame = CCSprite:create("UI/MainScene/9Sprite/u_9Sprite"..tostring(51 - index)..".png")
	local wingFrameNode = tolua.cast(container:getVarNode("mWingFrame"), "CCScale9Sprite")
	local wingFrameSize = wingFrameNode:getContentSize()
	wingFrameNode:setSpriteFrame(frameFrame:displayFrame())
	wingFrameNode:setContentSize(wingFrameSize)

	m_data.wingPicNode = container:getVarNode("mWingUpgrade01")
	m_data.wingPicNode:removeAllChildren()
	local wingFrame = CCSprite:create("UI/WingPage/u_WingPage0"..index..".png")
	m_data.wingPicNode:addChild(wingFrame)
	wingFrame:setAnchorPoint(ccp(0.5, 1))
	

	-- 按钮高亮
	for i = 1, 5 do
		container:getVarNode("mPic"..i):setVisible(i == index)
	end
end




function EquipmentWingPopPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    local wings_pb = require("Wings_pb")
    if opcode == HP_pb.WING_QUALITY_RANK_S then
    	-- 升级返回
    	local msg = wings_pb.HPWingQualityRankRet();
		msg:ParseFromString(msgBuff)
		local keyTable = {"playerName","level", "allianceName", "useTime", "rankNum", "prof", "playerId", "rebirthStage"}
		local function gotWingRankTable(msgWing)
			local wingData = {}
			if msgWing then
				for wingKey, wingValue in pairs(msgWing) do
					local data = {}
					for key, value in pairs(keyTable) do
						data[value] = wingValue[value] -- msgWing["playerName"]
					end
					if _G.next(data) then
						wingData[#wingData+1] = data
					else
						CCLuaLog("data is nil ~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
					end
				end
			end
			return wingData
		end

		local wingRank = {}
		wingRank[#wingRank+1] = gotWingRankTable(msg.whiteWing)
		wingRank[#wingRank+1] = gotWingRankTable(msg.greenWing)
		wingRank[#wingRank+1] = gotWingRankTable(msg.blueWing)
		wingRank[#wingRank+1] = gotWingRankTable(msg.purpleWing)
		wingRank[#wingRank+1] = gotWingRankTable(msg.originWing)
		m_data.wingRank = wingRank

		EquipmentWingPopPage:reBuildWingRand(container)
		EquipmentWingPopPage:reBuildWingBook(container)
    end
end

local CommonPage = require("CommonPage");
local EquipmentWingPopPageData = CommonPage.newSub(EquipmentWingPopPage, thisPageName, option);