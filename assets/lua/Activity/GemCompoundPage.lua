
local NodeHelper = require("NodeHelper")
local CommonPage = require("CommonPage")
local GemCompoundManager = require("Activity.GemCompoundManager")
local ItemManager = require("ItemManager")
local UserItemManager = require("UserItemManager")
local Const_pb = require("Const_pb")
local HP_pb = require("HP_pb")
local Activity_pb = require("Activity_pb")
local PageName = "GemCompoundPage"
local UserInfo = require("PlayerInfo.UserInfo")
local option = {
	ccbiFile = "Act_GemWorkshopPage.ccbi",
	handlerMap = {
		onChoiceFrame = "onOriGem",
		onPreviewFrame = "onGoalGem",
		onGemUpgrade = "onCompound",
		onReturnButton = "onBack",
		onHelp = "onHelp",
	},
	opcode = {
		GEM_COMPOUND_INFO_S = HP_pb.GEM_COMPOUND_INFO_S,
		GEM_COMPOUND_S = HP_pb.GEM_COMPOUND_S,
	},
}
for i=1,4 do
	option.handlerMap["onMaterialFrame" .. i] = "onMaterialGem"
end
local GemCompoundPage = CommonPage.new(PageName, option)

--活动基本信息
local thisActivityInfo = {
	id				= 29,
	remainTime 		= 0,
	gemCfg			= {},
}
local nowSelectMaterialGem = 0
thisActivityInfo.timerName = "Activity_" .. thisActivityInfo.id
-------------------------------logic methods------------------------------------
function GemCompoundPage.resetData()
	thisActivityInfo.gemCfg = {}
	nowSelectMaterialGem = 0
end

function GemCompoundPage.onTimer( container )
	local timerName = thisActivityInfo.timerName;
	if not TimeCalculator:getInstance():hasKey(timerName) then return; end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);

	thisActivityInfo.remainTime = math.max(remainTime, 0);
	local timeStr = common:second2DateString(thisActivityInfo.remainTime, false);
	NodeHelper:setStringForLabel(container, {mActivityDaysNum = timeStr})
end

function GemCompoundPage.setNodesVisible( container, hasGem )
	local nodesVisble = {}
	nodesVisble["mChoiceName"] = hasGem
	nodesVisble["mCostNum"] = hasGem
	nodesVisble["mPreviewName"] = hasGem
	NodeHelper:setNodesVisible(container, nodesVisble)
end

function GemCompoundPage.setDefaultPage( container )
	GemCompoundPage.setNodesVisible(container, false)
	local sprite2Img = {
		mChoicePic 		= GameConfig.Image.ChoicePic,
	--	mPreviewPic 	= GameConfig.Image.UpgradePreviewPic,
		mMaterialPic 	= GameConfig.Image.MaterialPic
	}
	-- 宝石品质框
	local defaultQualityFrames = {
		mChoiceFrame 		= GameConfig.Quality2AttrNum[1],
		mPreviewFrame 		= GameConfig.Quality2AttrNum[1],
		mMaterialFrame 		= GameConfig.Quality2AttrNum[1],
	}
	-- 宝石数量
	local gemCounts = {
	}
	for i=1,4 do
		sprite2Img["mMaterialPic"..i] =GameConfig.Image.MaterialPic
		defaultQualityFrames["mMaterialFrame"..i] = GameConfig.Quality2AttrNum[1]
		gemCounts["mMaterial"..i] = ""
	end
	NodeHelper:setStringForLabel(container, gemCounts)
	NodeHelper:setSpriteImage(container, sprite2Img)
	NodeHelper:setQualityFrames(container, defaultQualityFrames)
end

function GemCompoundPage.setDefaultMaterial(container)
	NodeHelper:setSpriteImage(container, {mMaterialPic=GameConfig.Image.MaterialPic})
	NodeHelper:setQualityFrames(container, {mMaterialFrame=GameConfig.Quality2AttrNum[1]})
	NodeHelper:setStringForLabel(container, {mCostNum=""})
end

function GemCompoundPage.refreshPage( container )
    if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(thisActivityInfo.timerName, thisActivityInfo.remainTime)
	end
	UserInfo.sync()
	NodeHelper:setStringForLabel(container,{mGoldLable = UserInfo.playerInfo.gold})
	if common:table_isEmpty(thisActivityInfo.gemCfg) then 
		GemCompoundPage.setDefaultPage(container)
		return
	else
		-- 有宝石，显示数量
		GemCompoundPage.setNodesVisible(container, true)
		local gemCfg = thisActivityInfo.gemCfg	
		local redGemCount = UserItemManager:getCountByItemId(gemCfg.redGem[2].id)
		local greenGemCount =UserItemManager:getCountByItemId(gemCfg.greenGem[2].id)
		local blueGemCount = UserItemManager:getCountByItemId(gemCfg.blueGem[2].id)
		local yellowGemCount = UserItemManager:getCountByItemId(gemCfg.yellowGem[2].id)
		local redGem = ItemManager:getItemCfgById(gemCfg.redGem[2].id)
		local greenGem = ItemManager:getItemCfgById(gemCfg.greenGem[2].id)
		local blueGem = ItemManager:getItemCfgById(gemCfg.blueGem[2].id)
		local yellowGem = ItemManager:getItemCfgById(gemCfg.yellowGem[2].id)

		-- 需要升级的宝石和所选的宝石是一个
		if gemCfg.oriGem == gemCfg.redGem[2].id then
			redGemCount = math.max(redGemCount-1, 0)
		elseif gemCfg.oriGem == gemCfg.greenGem[2].id then
			greenGemCount = math.max(greenGemCount-1,0)
		elseif gemCfg.oriGem == gemCfg.blueGem[2].id then
			blueGemCount = math.max(blueGemCount-1,0)
		elseif gemCfg.oriGem == gemCfg.yellowGem[2].id then
			yellowGemCount = math.max(yellowGemCount-1,0)
		end
		-- 消耗金币/钻石 数量（如果选择宝石）
		if nowSelectMaterialGem ~= nil and nowSelectMaterialGem~=0 then
			local costInfo = {}
			local costStr = nil
			local chooseGemInfo = {}
			local hasMaterial = true
			if nowSelectMaterialGem == gemCfg.redGem[2].id then
				if gemCfg.redGem[1] ~= nil then
					chooseGemInfo = gemCfg.redGem
					-- 所选宝石数量为0
					if redGemCount == 0 then
						hasMaterial = false
					end
				end
			elseif nowSelectMaterialGem == gemCfg.greenGem[2].id then
				if gemCfg.greenGem[1] ~= nil then
					chooseGemInfo = gemCfg.greenGem
					
					if greenGemCount == 0 then
						hasMaterial = false
					end
				end
			elseif nowSelectMaterialGem == gemCfg.blueGem[2].id then
				if gemCfg.blueGem[1] ~= nil then
					chooseGemInfo = gemCfg.blueGem
					if blueGemCount == 0 then
						hasMaterial = false
					end
				end
			elseif nowSelectMaterialGem == gemCfg.yellowGem[2].id then
				if gemCfg.yellowGem[1] ~= nil then
					chooseGemInfo = gemCfg.yellowGem
					if yellowGemCount == 0 then
						hasMaterial = false
					end
				end
			else
				hasMaterial = false
			end
			costInfo = chooseGemInfo[1]
			if costInfo.id == Const_pb.COIN then
				costStr = common:getLanguageString("@GemCompoundGoldCost", costInfo.count)
			elseif costInfo.id == Const_pb.GOLD then
				costStr = common:getLanguageString("@GemCompoundCoinCost", costInfo.count)
			end
			if hasMaterial then
				NodeHelper:setSpriteImage(container, {mMaterialPic=ItemManager:getIconById(nowSelectMaterialGem)})
				NodeHelper:setStringForLabel(container, {mCostNum=costStr})
				NodeHelper:setQualityFrames(container, {
					mMaterialFrame=ItemManager:getQualityById(chooseGemInfo[2].id)})	
			else
			    nowSelectMaterialGem = 0
				GemCompoundPage.setDefaultMaterial(container)
			end
		end

		-- 宝石图片
		local gemImgs = {
			mChoicePic 			= ItemManager:getIconById(gemCfg.oriGem),
			mPreviewPic 		= ItemManager:getIconById(gemCfg.goalGem),
			mMaterialPic1 		= redGem.icon,
			mMaterialPic2 		= greenGem.icon,
			mMaterialPic3 		= blueGem.icon,
			mMaterialPic4 		= yellowGem.icon,
		}
		-- 宝石数量
		local gemCounts = {
			mMaterial1 			= redGemCount,
			mMaterial2 			= greenGemCount,
			mMaterial3 			= blueGemCount,
			mMaterial4 			= yellowGemCount,
		}
		-- 宝石描述
		local gemDes = {
			mChoiceName 		= ItemManager:getNameById(gemCfg.oriGem),
			mPreviewName 		= ItemManager:getNameById(gemCfg.goalGem),
		}
		-- 宝石品质框
		local gemQualityFrames = {
			mChoiceFrame 		= ItemManager:getQualityById(gemCfg.oriGem),
			mPreviewFrame 		= ItemManager:getQualityById(gemCfg.goalGem),
			mMaterialFrame1 	= redGem.quality,
			mMaterialFrame2 	= greenGem.quality,
			mMaterialFrame3 	= blueGem.quality,
			mMaterialFrame4 	= yellowGem.quality,
		}
		NodeHelper:setSpriteImage(container, gemImgs)
		NodeHelper:setStringForLabel(container, gemCounts)
		NodeHelper:setStringForLabel(container, gemDes)
		NodeHelper:setQualityFrames(container, gemQualityFrames)
	end
end
------------------------------- state methods -----------------------------------
function GemCompoundPage.onEnter(container)
	GemCompoundPage.registerPacket(container)
	container:registerMessage(MSG_MAINFRAME_REFRESH)
	GemCompoundPage.resetData()
	common:sendEmptyPacket(HP_pb.GEM_COMPOUND_INFO_C)
	GemCompoundPage.refreshPage(container)
end

function GemCompoundPage.onExit(container)
    TimeCalculator:getInstance():removeTimeCalcultor(thisActivityInfo.timerName)
    GemCompoundPage.resetData()
	GemCompoundPage.removePacket(container)
	container:removeMessage(MSG_MAINFRAME_REFRESH)
end

function GemCompoundPage.onExecute( container )
	GemCompoundPage.onTimer(container)
end
--------------------------------click methods------------------------------------
function GemCompoundPage.onOriGem( container )
	PageManager.pushPage("ItemListPage")
end

function GemCompoundPage.onGoalGem( container )
	if thisActivityInfo.gemCfg.goalGem~=nil then
		local goalGemGfg = {
			type 		= Const_pb.TOOL*10000,
			itemId 		= thisActivityInfo.gemCfg.goalGem,
			count 		= tonumber(1),
		}
		GameUtil:showTip(container:getVarNode('mPreviewFrame'), goalGemGfg)
	end
end

function GemCompoundPage.onMaterialGem(container, eventName)
	local index = tonumber(string.sub(eventName,-1))
	if thisActivityInfo.gemCfg.redGem == nil then return end

	if index == 1 then 
		nowSelectMaterialGem = thisActivityInfo.gemCfg.redGem[2].id
	elseif index == 2 then
		nowSelectMaterialGem = thisActivityInfo.gemCfg.greenGem[2].id
	elseif index == 3 then
		nowSelectMaterialGem = thisActivityInfo.gemCfg.blueGem[2].id
	elseif index == 4 then
		nowSelectMaterialGem = thisActivityInfo.gemCfg.yellowGem[2].id
	end
	GemCompoundPage.refreshPage(container)
end

function GemCompoundPage.onCompound(container )
	if thisActivityInfo.gemCfg.oriGem==nil then
		MessageBoxPage:Msg_Box_Lan("@GemCompoundNoOriGem")
		return
	elseif nowSelectMaterialGem==0 then
		MessageBoxPage:Msg_Box_Lan("@GemCompoundNoMaterialGem")
		return
	end
	if thisActivityInfo.gemCfg.oriGem~=nil and thisActivityInfo.gemCfg.goalGem~=nil then
		local msg = Activity_pb.HPGemCompound();
		msg.levelUpGemItemId = tonumber(thisActivityInfo.gemCfg.oriGem)
		msg.costGemItemId = nowSelectMaterialGem or 0
		common:sendPacket(HP_pb.GEM_COMPOUND_C, msg)
	end
end

function GemCompoundPage.onBack( container )
	PageManager.popPage(PageName)
end

function GemCompoundPage.onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.HELP_GEMCOMPOUND)
end
--------------------------------packet ------------------------------------------
function GemCompoundPage.onReceivePacket( container )
	local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
    if opcode == option.opcode.GEM_COMPOUND_INFO_S then
    	local msg = Activity_pb.HPGemCompoundInfoRet();
		msg:ParseFromString(msgBuff);
    	thisActivityInfo.remainTime = msg.leftTime
    	GemCompoundPage.refreshPage(container)
    end
    if opcode == option.opcode.GEM_COMPOUND_S then
    	local msg = Activity_pb.HPGemCompoundRet();
		msg:ParseFromString(msgBuff);
		thisActivityInfo.remainTime = msg.leftTime
		-- 9级宝石合成成功，回复页面初始状态
		if GemCompoundManager:isHighest(thisActivityInfo.gemCfg.oriGem) then
			GemCompoundPage.resetData()
		else
			-- 宝石变成下一个等级
			thisActivityInfo.gemCfg = GemCompoundManager:getPageData(thisActivityInfo.gemCfg.oriGem)
		end
    	GemCompoundPage.refreshPage(container)
    end
end

-------------------------------- message ------------------------------------------
function GemCompoundPage.onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();	
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == PageName then
			local gemId = GemCompoundManager.nowSelectGem
			nowSelectMaterialGem = 0
			assert(gemId, "gemId is not exist")
			thisActivityInfo.gemCfg = GemCompoundManager:getPageData(gemId)
			GemCompoundPage.setDefaultMaterial(container)
			GemCompoundPage.refreshPage(container)
		end
	end
end