
----------------------------------------------------------------------------------

local option = {
	ccbiFile = "GVEBuffUpPopUp.ccbi",
	handlerMap = {
		onBtn1		= "onBtn1",
		onBtn2		= "onBtn2",
		onUpgrade 	= "onUpgrade",
        onClose         = "onClose"
	},
    opcode = {
        WORLD_BOSS_SEARCH_BUFF_C = HP_pb.WORLD_BOSS_SEARCH_BUFF_C,
        WORLD_BOSS_SEARCH_BUFF_S = HP_pb.WORLD_BOSS_SEARCH_BUFF_S,
        WORLD_BOSS_RANDOM_C = HP_pb.WORLD_BOSS_RANDOM_C,
        WORLD_BOSS_RANDOM_S = HP_pb.WORLD_BOSS_RANDOM_S,
        WORLD_BOSS_UPGRADE_C = HP_pb.WORLD_BOSS_UPGRADE_C,
        WORLD_BOSS_UPGRADE_S = HP_pb.WORLD_BOSS_UPGRADE_S,
        WORLD_BOSS_CONFIRM_BUFF_S = HP_pb.WORLD_BOSS_CONFIRM_BUFF_S,
        
    }	
};

local pageInfo = {
	buffRanTimes = 0,
	buffCfgId = 0,
	buffFreeTimes = 0,
	nextPrice = 0,
}

local thisPageName = "GVEBuffChoosePage";
local CommonPage = require("CommonPage");
local HP_pb = require("HP_pb");
local WorldBossManager = require("PVP.WorldBossManager");
local GVEBuffChoosePage = CommonPage.new("GVEBuffChoosePage", option);
local NodeHelper = require("NodeHelper");
local selectType = 0
local buffCfg = {}
----------------------------------------------------------------------------------
--GVEBuffChoosePage????????????
----------------------------------------------
function GVEBuffChoosePage.onEnter(container)
	GVEBuffChoosePage.registerPacket(container)
	local ConfigManager = require("ConfigManager")
	buffCfg = ConfigManager.getGVEBuffCfg()
	GVEBuffChoosePage.refreshPage(container)
end

function GVEBuffChoosePage.onExit(container)
	GVEBuffChoosePage.removePacket(container)
end

function GVEBuffChoosePage.refreshPage(container)
	if pageInfo.buffCfgId and pageInfo.buffRanTimes then
		local buffInfo = buffCfg[pageInfo.buffCfgId]
--		NodeHelper:setSpriteImage(container,{mPic = buffInfo.icon})
--		local normalImage = NodeHelper:getImageByQuality(pageInfo.buffCfgId);
--		NodeHelper:setNormalImages(container,{mHand = normalImage})
		NodeHelper:setStringForLabel(container,{mName = common:getLanguageString(buffInfo.name),
												mAttribute = common:getLanguageString(buffInfo.desc),
												mCostNum = buffInfo.price})
		local visible = {}
		for i = 1, 6 do
			--visible["mStar"..i] = i == buffInfo.star
		end
        NodeHelper:setSpriteImage(container,{mBuffImage = buffInfo.messageIcon})

		NodeHelper:setNodesVisible(container,visible)
		if pageInfo.buffFreeTimes > 0 then
			NodeHelper:setNodesVisible(container,{mCostNodeOnce = false, mFreeTxt = true , mOneBtnNode = true})
			NodeHelper:setStringForLabel(container,{mFreeTxt = common:getLanguageString("@GVEBuffUpFreeTxt", pageInfo.buffFreeTimes)})
		else
			NodeHelper:setNodesVisible(container,{mCostNodeOnce = true, mFreeTxt = false , mOneBtnNode = false})
			NodeHelper:setStringForLabel(container,{mCostNumOnce = pageInfo.nextPrice})
		end

		if pageInfo.buffCfgId == 6 then
			NodeHelper:setMenuItemEnabled(container,"mUpgrade", false)
			NodeHelper:setMenuItemEnabled(container,"mBtn1", false)
			NodeHelper:setNodesVisible(container,{mCostNodeOnce = false, mFreeTxt = false , mOneBtnNode = true})
           -- NodeHelper:setStringForLabel(container,{mFreeTxt = common:getLanguageString("@GVEBuffMax")})
			NodeHelper:setStringForLabel(container,{mBtnTxt1 = common:getLanguageString("@GVEBuffMax")})

            NodeHelper:setNodeIsGray(container , {mBtnTxt1 = true , mCostNumOnce = true , mCostNum = true})
		else
			NodeHelper:setMenuItemEnabled(container,"mUpgrade", true)
			NodeHelper:setMenuItemEnabled(container,"mBtn1", true)

            NodeHelper:setNodeIsGray(container , {mBtnTxt1 = false , mCostNumOnce = false , mCostNum = false})
		end
	end
end
function GVEBuffChoosePage.onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.WORLD_BOSS_SEARCH_BUFF_S then
        local msg = WorldBoss_pb.HPBossRandomBuffRes();
		msg:ParseFromString(msgBuff);
		pageInfo.buffCfgId = msg.buffCfgId
		pageInfo.buffRanTimes = msg.buffRanTimes
		pageInfo.buffFreeTimes = msg.buffFreeTimes
		pageInfo.nextPrice = msg.nextPrice
		GVEBuffSelectPage:refreshPage(container)
    elseif opcode == HP_pb.WORLD_BOSS_UPGRADE_S then
    	MessageBoxPage:Msg_Box_Lan("@GveUpgreSucc")
    	PageManager.changePage("WorldBossPage")
	elseif opcode == HP_pb.WORLD_BOSS_CONFIRM_BUFF_S then    	
		PageManager.changePage("WorldBossPage")
    end
end

---TODO ?????? ????????
function GVEBuffChoosePage.onBtn1(container)
	common:sendEmptyPacket(HP_pb.WORLD_BOSS_RANDOM_C, true)
	PageManager.popPage(thisPageName)
end
---TODO ?????? ????????
--TODO : ????  ---??????map
function GVEBuffChoosePage.onBtn2(container)
	common:sendEmptyPacket(HP_pb.WORLD_BOSS_CONFIRM_BUFF_C, true)
end	
function GVEBuffChoosePage.onClose(container)
    PageManager.popPage(thisPageName)
end	

function GVEBuffChoosePage.onUpgrade( container )
	common:sendEmptyPacket(HP_pb.WORLD_BOSS_UPGRADE_C, true)
end

function GVEBuffChoosePage_setPageInfo( info )
	pageInfo = info or {}
end