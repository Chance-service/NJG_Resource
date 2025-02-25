
----------------------------------------------------------------------------------

local PageManager = require("PageManager")
local thisPageName = "EquipmentWingPage"

local option = {
	ccbiFile = isIpad and "EquipmentWingPage.ccbi" or "EquipmentWingPage.ccbi",
	handlerMap = {
		onHandbook       = "onHandbook",
		onAutoUpdate     = "onAutoUpdate",
		onAutoFilter     = "onAutoFilter",
        onReturn         = "onReturn",
		onMoreAttribute	 = "showMoreAttribute"
	},
	-- opcode = opcodes
};
local UserInfo = require("PlayerInfo.UserInfo");

local EquipmentWingPage = {};
local m_variableData = {}

local NodeHelper = require("NodeHelper");
local RoleManager = require("PlayerInfo.RoleManager");
local Const_pb = require("Const_pb");
local UserItemManager = require("Item.UserItemManager");
local GameConfig = require("GameConfig");

local featherId = 80001

-----------------------------------------------
--EquipmentWingPage
----------------------------------------------

function EquipmentWingPage:onEnter(container)
	local roleId = UserInfo.roleInfo.itemId;   

	-- 注册数据消息
    container:registerPacket(HP_pb.WING_LEVEL_UP_S)
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    -- 翅膀属性
	local profession = RoleManager:getAttrById(roleId, "profession")
    local WingAttrCfg = ConfigManager.getWingAttrCfg()

    m_variableData.curWingAttrData = WingAttrCfg[profession]
    UserInfo.winglevel = 0;
    if not UserInfo.wingLevel then
    	UserInfo.wingLevel = 0
    end
    if not UserInfo.wingLucky then
    	UserInfo.wingLucky = 0
    end

	m_variableData.isAutoUpdate = false
    --如果当前翅膀等级是0，服务器不在自动升一星
    --[[if UserInfo.wingLevel == 0 then
    	common:sendEmptyPacket(HP_pb.WING_LEVEL_UP_C)
    end--]]

	local mSprite41Scale = container:getVarScale9Sprite("mSprite41Scale")
	if mSprite41Scale ~= nil then
		container:autoAdjustResizeScale9Sprite( mSprite41Scale )
	end

	local mSprite03Scale = container:getVarScale9Sprite("mSprite03Scale")
	if mSprite03Scale ~= nil then
		container:autoAdjustResizeScale9Sprite( mSprite03Scale )
	end

    NodeHelper:initScrollView(container, "mStrengthAttribute")
    container:autoAdjustResizeScrollview(container.mScrollView)
    EquipmentWingPage:reBuildWingAttr(container)
    EquipmentWingPage:onWingStarAnimInit(container, UserInfo.wingLevel)
    --EquipmentWingPage:newbieGuide( container )
    container:getVarNode("mNewGuide"):setVisible( true )
end

function EquipmentWingPage:newbieGuide( container )
    --local  key = GamePrecedure:getInstance():getUin() .. "_" .. GamePrecedure:getInstance():getServerID() .. "GuideWing"
    local  key = UserInfo.playerInfo.playerId.."_"..GamePrecedure:getInstance():getServerID().."_" .."GuideWing"
    local hasKey = CCUserDefault:sharedUserDefault():getBoolForKey( key )

    if not hasKey then
        --container:getVarNode("mNewGuide"):setVisible( true )
        CCUserDefault:sharedUserDefault():setBoolForKey(key, true)
    else
       -- container:getVarNode("mNewGuide"):setVisible( false )
    end
end

function EquipmentWingPage:onExecute(container)
end

function EquipmentWingPage:onExit(container)
    container:removePacket(HP_pb.WING_LEVEL_UP_S)
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    EquipmentWingPage:stopAutoUpdate(container)
	NodeHelper:deleteScrollView(container)
	m_variableData.wingPicNode:removeAllChildren()
	if m_variableData.wingLight then
		m_variableData.wingLight:removeFromParentAndCleanup(true)
	end
	for key, star in pairs(m_variableData.starTable) do
		star:removeFromParentAndCleanup(true)
	end
    m_variableData = {}
end

function EquipmentWingPage:onWingFrame(container, wingColor)
	local frameFrame = CCSprite:create("UI/MainScene/9Sprite/u_9Sprite"..tostring(51 - wingColor)..".png")
	local wingFrameNode = tolua.cast(container:getVarNode("mWingFrame"), "CCScale9Sprite")
	local wingFrameSize = wingFrameNode:getContentSize()
	wingFrameNode:setSpriteFrame(frameFrame:displayFrame())
	wingFrameNode:setContentSize(wingFrameSize)

	m_variableData.wingPicNode = container:getVarNode("mWingUpgrade01")
	m_variableData.wingPicNode:removeAllChildren()
	local wingFrame = CCSprite:create("UI/WingPage/u_WingPage0"..wingColor..".png")
	m_variableData.wingPicNode:addChild(wingFrame)
	wingFrame:setAnchorPoint(ccp(0.5, 1))
	
	m_variableData.wingPicNode = container:getVarNode("mWingUpgrade02")
	m_variableData.wingPicNode:removeAllChildren()
	local wingFrame = CCSprite:create("UI/WingPage/u_WingPage0"..wingColor..".png")
	m_variableData.wingPicNode:addChild(wingFrame)
	wingFrame:setAnchorPoint(ccp(0.5, 1))

end

function EquipmentWingPage:onWingStarAnimInit(container, curLevel)
	m_variableData.starTable = {}
   	for i = 1, 10 do
    	local baseNode = container:getVarNode("mWingStar"..i)
    	baseNode:removeAllChildren()
    	local ccbNode = ScriptContentBase:create("EquipmentWingStar.ccbi")
    	baseNode:addChild(ccbNode)
    	ccbNode:release()
    	m_variableData.starTable[i] = ccbNode
    end

	local wingColor = math.floor((curLevel-1)/10)
	local wingLevel = curLevel - wingColor*10
	if curLevel == 0 then
		wingLevel = 0
		wingColor = 0
	end
	wingColor = wingColor + 1
    for key, star in pairs(m_variableData.starTable) do
    	if key > wingLevel then
    		star:runAnimation("LoseStar")
    	else
    		star:runAnimation("WinStar")
    	end
    end
    EquipmentWingPage:onWingFrame(container, wingColor)

    if m_variableData.wingLight then
    	m_variableData.wingLight:setVisible(false)
    end
end

function EquipmentWingPage:onWingStarAnimRun(container, curLevel, isWin)
	-- if true then
	-- 	return
	-- end
	local wingColor = math.floor((curLevel-1)/10)
	local wingLevel = curLevel - wingColor*10
	wingColor = wingColor + 1
	if wingLevel == 1 and wingColor > 1 and isWin then
		-- 从十星升一星
		for i = 2, 10 do
			m_variableData.starTable[i]:runAnimation("LoseStar")
		end
		m_variableData.starTable[1]:runAnimation("AnimWinStar")

    	EquipmentWingPage:onWingFrame(container, wingColor)

		-- 翅膀变幻时的外框
    	if not m_variableData.wingLight then
    		local ccbNode = ScriptContentBase:create("EquipmentWingLight.ccbi")
    		local baseNode =  container:getVarNode("mWingLight")
			baseNode:addChild(ccbNode)
			ccbNode:release() 
			m_variableData.wingLight = ccbNode
    	end
    	m_variableData.wingLight:setVisible(true)
    	m_variableData.wingLight:runAnimation("Winglight0"..(wingColor - 1))
	else
		if isWin then
			m_variableData.starTable[wingLevel]:runAnimation("AnimWinStar")
            if not m_variableData.wingLight then
    		    local ccbNode = ScriptContentBase:create("EquipmentWingLight.ccbi")
    		    local baseNode =  container:getVarNode("mWingLight")
			    baseNode:addChild(ccbNode)
			    ccbNode:release()
			    m_variableData.wingLight = ccbNode
    	    end
    	    m_variableData.wingLight:setVisible(true)
    	    m_variableData.wingLight:runAnimation("Winglight0"..(wingColor + 4))
		else
			m_variableData.starTable[wingLevel]:runAnimation("AnimLoseStar")
		end
	end
end

function EquipmentWingPage.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		local contentId = container:getItemDate().mID;
		local curLevel = UserInfo.wingLevel
		local nextLevel = curLevel + 1
		local attrId = m_variableData.attrIndexTbl[contentId]
		local nextValue = ""
		if m_variableData.nextAttrTbl[attrId] then
			if m_variableData.nextAttrTbl[attrId] > 0 then
				nextValue = "+"..m_variableData.nextAttrTbl[attrId]
				NodeHelper:setColorForLabel(container,{attrPlus = GameConfig.ColorMap.COLOR_GREEN })
			else
				nextValue = "-"..math.abs(m_variableData.nextAttrTbl[attrId])
				NodeHelper:setColorForLabel(container,{attrPlus = GameConfig.ColorMap.COLOR_RED })
			end
		end
		local lb2Str = {
	        attrName = common:getLanguageString("@AttrName_" .. attrId),
	        attrValue = m_variableData.curAttrTbl[attrId],
	        attrPlus = nextValue,
	    }

	    NodeHelper:setStringForLabel(container ,lb2Str)
    end
end

function EquipmentWingPage:onReceiveMessage(container)
    EquipmentWingPage.onGameMessage(container);
end

function EquipmentWingPage.onGameMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
     if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "EquipmentWingPage" then
            EquipmentWingPage:refreshUserInfo(container)
        end
    end
end

function EquipmentWingPage:reBuildWingAttr(container)
	-- 物品数据更新
	UserInfo.syncRoleInfo()
    EquipmentWingPage:refreshUserInfo(container)

	NodeHelper:clearScrollView(container)
	local curLevel = UserInfo.wingLevel
	local maxLevel = #m_variableData.curWingAttrData
	if curLevel < 0 or curLevel > maxLevel then
		return false
	end
	local nextLevel = curLevel + 1

	-- 整理所有属性之和
	local curAttrTbl = {}
	local nextAttrTbl = {}
	for key, attr in pairs(m_variableData.curWingAttrData[curLevel].attrs) do
		if curAttrTbl[attr.type] == nil then
			curAttrTbl[attr.type] = 0
		end
		curAttrTbl[attr.type] = curAttrTbl[attr.type] + attr.count
	end

	if nextLevel <= maxLevel then
		for key, attr in pairs(m_variableData.curWingAttrData[nextLevel].attrs) do
			if curAttrTbl[attr.type] == nil then
				curAttrTbl[attr.type] = 0
			end
			if nextAttrTbl[attr.type] == nil then
				nextAttrTbl[attr.type] = 0
			end
			nextAttrTbl[attr.type] = nextAttrTbl[attr.type] + attr.count
		end

		for key, count in pairs(curAttrTbl) do
			if not nextAttrTbl[key] then
				nextAttrTbl[key] = 0
			end
			nextAttrTbl[key] = nextAttrTbl[key] - count
		end
	end

	local attrIndexTbl = {}
	local size = 0
	for k, v in pairs(curAttrTbl) do
		size = size+1
		attrIndexTbl[#attrIndexTbl+1] = k
	end
	table.sort(attrIndexTbl)

	m_variableData.attrValueCount = size
	m_variableData.curAttrTbl = curAttrTbl
	m_variableData.nextAttrTbl = nextAttrTbl
	m_variableData.attrIndexTbl = attrIndexTbl
	NodeHelper:buildScrollView(container, size, "AttrValuePlus.ccbi", EquipmentWingPage.onFunction);
end

function EquipmentWingPage:refreshUserInfo(container)
    UserInfo.syncPlayerInfo();
    local lb2Str = {
    	-- 血量
		mhpnum 					= UserInfo.getRoleAttrById(Const_pb.HP),	
		-- 魔法值
		mMpNum 					= UserInfo.getRoleAttrById(Const_pb.MP),
		-- 战力
		mFightingCapacityNum 	= UserInfo.roleInfo.fight,
		-- 职业名称
		mOccupationName			= UserInfo.getProfessionName(),
		-- 力量
		mStrengthNum 			= UserInfo.getRoleAttrById(Const_pb.STRENGHT),
		-- 伤害
		mDamageNum 				= UserInfo.getDamageString(),
		-- 敏捷
		mDexterityNum			= UserInfo.getRoleAttrById(Const_pb.AGILITY),
		-- 护甲
		-- mArmorNum				= UserInfo.getRoleAttrById(Const_pb.ARMOR),
		-- 暴击
		-- mCritRatingNum			= UserInfo.getRoleAttrById(Const_pb.CRITICAL),
		-- 智力
		mIntelligenceNum	 	= UserInfo.getRoleAttrById(Const_pb.INTELLECT),

		-- mCreateRoleNum			= UserInfo.getRoleAttrById(Const_pb.MAGDEF),
		-- 闪避
		-- mDodgeNum				= UserInfo.getRoleAttrById(Const_pb.DODGE),
		-- 耐力
		mStaminaNum				= UserInfo.getRoleAttrById(Const_pb.STAMINA),
		-- 命中
		-- mHitRatingNum			= UserInfo.getRoleAttrById(Const_pb.HIT),
		-- 韧性
		-- mTenacityNum 			= UserInfo.getRoleAttrById(Const_pb.RESILIENCE)
	};

	---------------------------- 幸运值部分 ----------------------------
    local Const_pb = require("Const_pb")
    lb2Str["mGoodLuckRate"] = tostring(UserInfo.wingLucky.. "/"..Const_pb.MAX_LUCKY_NUM)
	--[[if container:getVarNode("mExperienceNum") then
		container:getVarNode("mExperienceNum"):setVisible(false)
	end--]]
    container:getVarNode("mVipExp"):setScaleX(UserInfo.wingLucky/Const_pb.MAX_LUCKY_NUM)

	---------------------------- 翅膀属性及消耗 ----------------------------
	local newLevel = UserInfo.wingLevel
	local cost1Enough = true
	local cost2Enough = true
	lb2Str["mWingCost1Name"] = common:getLanguageString("@FeatherName")
	local userItem = UserItemManager:getUserItemByItemId(featherId)
	local featherGotCount = userItem and userItem.count or 0
	lb2Str["mWingCost1Got"] = featherGotCount.."/"

	if newLevel >= #m_variableData.curWingAttrData then
		lb2Str["mWingCost1Cost"] = "0"
		lb2Str["mWingCost2Cost"] = "0"
		lb2Str["mWingCost2Got"] = GameUtil:formatNumber(UserInfo.playerInfo.gold).."/"
		-- lb2Str["mWingCost2Name"] = common:getLanguageString("@Gold")
		container:getVarNode("mGoldPic"):setVisible(true)
		container:getVarNode("mCoinPic"):setVisible(false)
	else
		local costData = m_variableData.curWingAttrData[newLevel]["updateCost"]
        local gotCount
		for key, cost in pairs(costData) do

			if cost.type == Const_pb.TOOL * 10000 then
				-- 获取羽毛数据
				lb2Str["mWingCost1Cost"] = tostring(cost.count)
				if cost.count > featherGotCount then
					cost1Enough = false
				end
				lb2Str["mWingCost1Cost"] = tostring(cost.count)
			elseif cost.type == Const_pb.PLAYER_ATTR * 10000 and newLevel > 0 then
				-- 金币或钻石消耗
				if cost.itemId == Const_pb.COIN then
					gotCount =  UserInfo.playerInfo.coin
					container:getVarNode("mGoldPic"):setVisible(false)
					container:getVarNode("mCoinPic"):setVisible(true)
                    lb2Str["mWingCost2Got"] = GameUtil:formatNumber(gotCount).."/"
				    lb2Str["mWingCost2Cost"] = GameUtil:formatNumber(cost.count) --tostring(cost.count)
				elseif cost.itemId == Const_pb.GOLD then
					gotCount =  UserInfo.playerInfo.gold
					container:getVarNode("mGoldPic"):setVisible(true)
					container:getVarNode("mCoinPic"):setVisible(false)
                    lb2Str["mWingCost2Got"] = tostring(gotCount).."/"
				    lb2Str["mWingCost2Cost"] = GameUtil:formatNumber(cost.count) --tostring(cost.count)
				end
			
				if gotCount < cost.count then
					cost2Enough = false
				end  
			end
		end
	end
    if newLevel == 0 then
	    container:getVarNode("mGoldPic"):setVisible(false)
	    container:getVarNode("mCoinPic"):setVisible(true)
        lb2Str["mWingCost2Got"] = GameUtil:formatNumber(UserInfo.playerInfo.coin).."/"
	    lb2Str["mWingCost2Cost"] = "0" --tostring(cost.count)
	    if UserInfo.playerInfo.coin < 0 then
		    cost2Enough = false
	    end  
    end
	NodeHelper:setStringForLabel(container, lb2Str)
	NodeHelper:setColorForLabel(container,{
		mWingCost1Got = cost1Enough and GameConfig.ColorMap.COLOR_GREEN or GameConfig.ColorMap.COLOR_RED,
		mWingCost1Cost = cost1Enough and GameConfig.ColorMap.COLOR_GREEN or GameConfig.ColorMap.COLOR_RED,
		mWingCost2Got = cost2Enough and GameConfig.ColorMap.COLOR_GREEN or GameConfig.ColorMap.COLOR_RED,
		mWingCost2Cost = cost2Enough and GameConfig.ColorMap.COLOR_GREEN or GameConfig.ColorMap.COLOR_RED
		})
end

function EquipmentWingPage:onReturn(container)
	if not m_variableData.isAutoUpdate then
		PageManager.changePage("EquipmentPage")
	else
		EquipmentWingPage:stopAutoUpdate(container)
	end
end

function EquipmentWingPage:showMoreAttribute(container)
	if not m_variableData.isAutoUpdate then
	    local fullAttributePage = "FullAttributePage";
		RegisterLuaPage(fullAttributePage);
		PageManager.pushPage(fullAttributePage);
	end
end

function EquipmentWingPage:checkResEnough()
	local tips = ""
	local newLevel = UserInfo.wingLevel
	if newLevel >= #m_variableData.curWingAttrData then
		return false, "@MaxLevelLimit"
	end

	local costData = m_variableData.curWingAttrData[newLevel]["updateCost"]
	for key, cost in pairs(costData) do
		-- TODO
		if cost.type == Const_pb.TOOL * 10000 then
			local userItem = UserItemManager:getUserItemByItemId(cost.itemId);
			if not userItem or cost.count > userItem.count then
				return false, "@FeatherNotEnoughTitle"
			end
		elseif cost.type == Const_pb.PLAYER_ATTR * 10000 then

			if (cost.itemId == Const_pb.COIN and UserInfo.playerInfo.coin < cost.count) then
				return false, "@CoinNotEnough"

			elseif (cost.itemId == Const_pb.GOLD and UserInfo.playerInfo.gold < cost.count) then
				return false, "@GoldNotEnough"
			end
		end
	end

	return true
end

-- 图鉴
function EquipmentWingPage:onHandbook(container)
	if not m_variableData.isAutoUpdate then
	    local fullAttributePage = "EquipmentWingPopPage";
		RegisterLuaPage(fullAttributePage);
		PageManager.pushPage(fullAttributePage);
	end
end

function EquipmentWingPage:startAutoUpdate(container)
	m_variableData.isAutoUpdate = true
	m_variableData.autoUpdateTargetlevel = (math.ceil(UserInfo.wingLevel/10))*10+1
	if m_variableData.autoUpdateTargetlevel > #m_variableData.curWingAttrData then
		m_variableData.autoUpdateTargetlevel = #m_variableData.curWingAttrData
	end
	NodeHelper:setStringForLabel(container,{mAutoUpdateAndStop = common:getLanguageString("@StopAutoUpdate")})

	common:sendEmptyPacket(HP_pb.WING_LEVEL_UP_C)
end
function EquipmentWingPage:stopAutoUpdate(container)
	m_variableData.isAutoUpdate = false
	NodeHelper:setStringForLabel(container,{mAutoUpdateAndStop = common:getLanguageString("@AutoUpdate")})
	container:stopAllActions()
end

function EquipmentWingPage:checkShouldAutoUpdate(container)
	local array = CCArray:create()
    local autoFunc = CCCallFunc:create(function( )
    	-- 目标已达成
        if UserInfo.wingLevel >= m_variableData.autoUpdateTargetlevel then
             if UserInfo.wingLevel == 1  then
                m_variableData.autoUpdateTargetlevel = (math.ceil(UserInfo.wingLevel/10))*10+1
            else
                MessageBoxPage:Msg_Box(common:getLanguageString("@WingAutoUpdateGot"))
                EquipmentWingPage:stopAutoUpdate(container)
                return
            end
        end

        -- 资源不足
        local result, tips = EquipmentWingPage:checkResEnough()
		if not result then
			MessageBoxPage:Msg_Box(tips)
        	EquipmentWingPage:stopAutoUpdate(container)
			return
		end
		common:sendEmptyPacket(HP_pb.WING_LEVEL_UP_C)

    end)
    array:addObject(CCDelayTime:create(2))
    array:addObject(autoFunc)
    local seq = CCSequence:create(array)
    container:stopAllActions()
    container:runAction(seq)
end

-- 自动十星
function EquipmentWingPage:onAutoUpdate(container)
	if not m_variableData.isAutoUpdate then
		-- 先检查资源是否够升一级
		local result, tips = EquipmentWingPage:checkResEnough()
		if not result then
			MessageBoxPage:Msg_Box(tips)
			return
		end

		PageManager.showConfirm( common:getLanguageString("@AutoUpdate"),
			common:getLanguageString("@WingAutoUpdateTips"), 
			function(isSure)
				if isSure then
					EquipmentWingPage:startAutoUpdate(container)
				end
			end)
	else
		EquipmentWingPage:stopAutoUpdate(container)
	end
end

-- 升级
function EquipmentWingPage:onAutoFilter(container)
    --EquipmentWingPage:newbieGuide( container )
	if not m_variableData.isAutoUpdate then
		-- EquipmentWingPage:checkUpdate()
		local result, tips = EquipmentWingPage:checkResEnough()
		if result then
			common:sendEmptyPacket(HP_pb.WING_LEVEL_UP_C)
		else
			MessageBoxPage:Msg_Box(tips);
		end
	end
end


function EquipmentWingPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    local wings_pb = require("Wings_pb")
    if opcode == HP_pb.WING_LEVEL_UP_S then
    	-- 升级返回
    	local msg = wings_pb.HPWingLevelupRet();
		msg:ParseFromString(msgBuff);

		if msg.isLevelup and msg.level == 1 then
			-- 首次开启翅膀系统
    		MessageBoxPage:Msg_Box("@WingFuncOpen")
            EquipmentWingPage:onWingStarAnimRun(container, msg.level, true)
		else
			-- TODO 临时提示，待界面TA完成最后处理
			if msg.isLevelup then
				MessageBoxPage:Msg_Box("@UpgradeGemSuccess");
				EquipmentWingPage:onWingStarAnimRun(container, msg.level, true)
			elseif msg.level < UserInfo.wingLevel then
				MessageBoxPage:Msg_Box("@UpgradeLevelDown");
				EquipmentWingPage:onWingStarAnimRun(container, msg.level+1, false)
			else
				MessageBoxPage:Msg_Box("@UpgradeGemFail");
			end
		end

		UserInfo.wingLevel = msg.level
		UserInfo.wingLucky = msg.luckyNum
		EquipmentWingPage:reBuildWingAttr(container)

		if m_variableData.isAutoUpdate then
		    EquipmentWingPage:checkShouldAutoUpdate(container)
		end
    end
end

local CommonPage = require("CommonPage");
local EquipmentWingPageData = CommonPage.newSub(EquipmentWingPage, thisPageName, option);