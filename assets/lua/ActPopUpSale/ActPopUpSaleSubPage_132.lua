----------------------------------------------------------------------------------
--[[
	等级特惠礼包
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local TimeDateUtil = require("Util.TimeDateUtil")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity4_pb = require("Activity4_pb")
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local ResManager = require("ResManagerForLua")
local ItemManager = require("Item.ItemManager")

local _ConfigData = ConfigManager.getAct132Cfg()

-- local _buyId = 1
local _buyData = nil
local _freeConfigData = { }
local _diamondsConfigDta = { }
local ActPopUpSaleSubPage_132 = {
	rewardItems = {}
}

--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/ActPopUpSale.lang"] then
--    __lang_loaded["Lang/ActPopUpSale.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/ActPopUpSale.lang")
--end

local _serverData = nil
local _showData = nil

local CCBI_FILE = "Act_TimeLimit_132.ccbi"

local HANDLER_MAP = {
	onRecharge = "onRecharge",
	onReceive = "onReceive",
	onClose = "onClose",
	onFrame1 = "onClickItemFrame",
	onFrame2 = "onClickItemFrame",
	onFrame3 = "onClickItemFrame",
	onFrame4 = "onClickItemFrame",
}

local OPCODES = {
	ACTIVITY132_LEVEL_GIFT_BUY_C = HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_C,
	ACTIVITY132_LEVEL_GIFT_BUY_S = HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_S
}
-- local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")

function ActPopUpSaleSubPage_132:onEnter(parentContainer)
	local slf = self

	self.container = ScriptContentBase:create(CCBI_FILE)

	-- 註冊 呼叫 行為
	self.container:registerFunctionHandler(function (eventName, container)
		local funcName = HANDLER_MAP[eventName]
		local func = slf[funcName]
		if func then
			func(slf, container)
		end
	end)

	-- luaCreat_ActPopUpSaleSubPage_132(self.container)
	
	self:registerPacket(parentContainer)
	self:initData()
	self:initUi(self.container)

	self:getActivityInfo()

	return self.container
end


function ActPopUpSaleSubPage_132:initData()
	_buyData = ActPopUpSaleSubPage_132_getIsShowMainSceneIcon()
	--    UserInfo.sync()
	--    _ConfigData = ConfigManager.getAct132Cfg()
	--    _buyId = 1
	--    for i = 1, #_ConfigData do
	--        local data = _ConfigData[i]
	--        if UserInfo.roleInfo.level >= data.minLv and UserInfo.roleInfo.level <= data.maxLv then
	--            _buyId = i
	--            break
	--        end
	--    end
end

-- 
function ActPopUpSaleSubPage_132:initUi(container)

	local itemInfo = _ConfigData[_buyData.id]
	if not itemInfo then
		return
	end

	itemInfo.price=ActPopUpSalePage_getPrice(itemInfo.id)

	self.rewardItems = itemInfo.reward

	-- 初始化 獲得列表
	NodeHelper:initScrollView(container, "mContent", #self.rewardItems);

	self:updateItems()

	-- NodeHelper:setMenuItemEnabled(container, "mRechargeBtn", false)

	NodeHelper:setStringForLabel(container, { mRecharge = itemInfo.price })
	local bg = container:getVarSprite("mBg")
	bg:setScale(NodeHelper:getScaleProportion())

	if itemInfo.price <= 0 then
		NodeHelper:setNodesVisible(container, { mReceiveNode = true, mRechargeNode = false })
		--NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minLv .. "-" .. itemInfo.maxLv })

		NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minLv })

		NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", UserInfo.roleInfo.level >= itemInfo.minLv)
		NodeHelper:setNodeIsGray(container, { mReceiveText = not(UserInfo.roleInfo.level >= itemInfo.minLv) })

		NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString("@Receive") })
	else
		NodeHelper:setNodesVisible(container, { mReceiveNode = false, mRechargeNode = true })
		if itemInfo.minLv >= 100 then
			NodeHelper:setStringForLabel(container, { mLvLabel = "100+" })
		else
			NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minLv})
		end
		-- NodeHelper:setSpriteImage(container, { mBg = "BG/Activity_132/Act_132_Bg_1.png" }, { mBg = 1 })
	end

	NodeHelper:setSpriteImage(container, {mLvSprite = itemInfo.Banner ,mBg = "BG/UI/"..itemInfo.BG })
	NodeHelper:setStringForLabel(container,{mTxt=common:getLanguageString(itemInfo.title)})
end

function ActPopUpSaleSubPage_132:updateItems()
	local size = #self.rewardItems
		
	local colMax = 4

	local options = {
		-- magic layout number 
		-- 因為CommonRewardContent尺寸異常，導致各使用處需要自行處理
		interval = ccp(0, 0),
		colMax = colMax,
		paddingTop = 0,
		paddingBottom = 0,
		originScrollViewSize = CCSizeMake(544, 272),
		isDisableTouchWhenNotFull = true
	}
	if size == 5 then 
		options.colMax = 3
		options.paddingLeft = 70
	end
	-- 未滿 1行 則 橫向置中
	if size < colMax then
		options.isAlignCenterHorizontal = true
	end
	
	-- 未達 2行 則 垂直置中
	if size <= colMax then
		options.isAlignCenterVertical = true
		options.startOffset = ccp(0, 0)
	-- 達到 2行 則 偏移在首項 並 偏移paddingTop
	else
		options.startOffsetAtItemIdx = 1
		options.startOffset = ccp(0, -options.paddingTop)
	end

	--[[ 滾動視圖 左上至右下 ]]
	NodeHelperUZ:buildScrollViewGrid_LT2RB(
		self.container,
		size,
		"CommonRewardContent.ccbi",
		function (eventName, container)
			self:onScrollViewFunction(eventName, container)
		end,
		options
	)
			
	-- 顯示/隱藏 列表 或 無獎勵提示
	NodeHelper:setNodesVisible(self.container, {
		mContent = size ~= 0
	})
	
	-- 若 數量 尚未超過 每行數量 的話
	if size <= colMax  then
		local node = self.container:getVarNode("mContent")
		node:setTouchEnabled(false)
	end
end
--[[ 滾動視圖 功能窗口 ]]
function ActPopUpSaleSubPage_132:onScrollViewFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		--- 每个子空间创建的时候会调用这个函数
		local contentId = container:getItemDate().mID;
		-- 获取到时第几行
		local idx = contentId
		-- 获取当前的index      i是每行的第几个 用来获取组件用的
		local node = container:getVarNode("mItem")
		local itemNode = ScriptContentBase:create('GoodsItem.ccbi')

		local itemData = self.rewardItems[idx]
		local resInfo = ResManager:getResInfoByTypeAndId(itemData and itemData.type or 30000, itemData and itemData.itemId or 104001, itemData and itemData.count or 1);
		--NodeHelper:setStringForLabel(itemNode, { mName = "" });
		local numStr = ""
		if resInfo.count > 0 then
			numStr = tostring(resInfo.count)
		end
		local lb2Str = {
			mNumber = numStr
		};
		local showName = "";
		if itemData and itemData.type == 30000 then
			showName = ItemManager:getShowNameById(itemData.itemId)
		else
			showName = resInfo.name           
		end
		NodeHelper:setNodesVisible(itemNode, { m2Percent = false, m5Percent = false });

		if itemData.type == 40000 then
			for i = 1, 6 do
				NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.quality })
			end
		end
		NodeHelper:setNodesVisible(itemNode, { mStarNode = itemData.type == 40000 })
		
		--NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.BlurryLineWidth - 10, 4)
		NodeHelper:setStringForLabel(itemNode, lb2Str);
		NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = 1 });
		NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality });
		NodeHelper:setColorForLabel(itemNode, { mName = ConfigManager.getQualityColor()[resInfo.quality].textColor })
		NodeHelper:setNodesVisible(itemNode, { mName = false})

		node:addChild(itemNode);
		itemNode:registerFunctionHandler(function (eventName, container)
			if eventName == "onHand" then
				local id = container.id
				GameUtil:showTip(container:getVarNode("mHand"), self.rewardItems[id])
			end  
		end)
		-- itemNode:setTouchEnabled(inst.container.mScrollView:isTouchEnabled())
		itemNode.id = contentId
	end
end



-- 点击物品显示tips
function ActPopUpSaleSubPage_132:onClickItemFrame(container, eventName)
	local rewardIndex = tonumber(eventName:sub(8))
	local nodeIndex = rewardIndex;
	local itemInfo = _ConfigData[_buyData.id]
	if not itemInfo then return end
	local rewardItems = { }
	if itemInfo.reward ~= nil then
		for _, item in ipairs(common:split(itemInfo.reward, ",")) do
			local _type, _id, _count = unpack(common:split(item, "_"));
			table.insert(rewardItems, {
				type = tonumber(_type),
				itemId = tonumber(_id),
				count = tonumber(_count)
			} );
		end
	end
	GameUtil:showTip(container:getVarNode('mPic' .. nodeIndex), rewardItems[rewardIndex])
end


-- function ActPopUpSaleSubPage_132:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
--     local maxSize = maxSize or 4;
--     isShowNum = isShowNum or false
--     local nodesVisible = { };
--     local lb2Str = { };
--     local sprite2Img = { };
--     local scaleMap = { }
--     local menu2Quality = { };
--     local colorTabel = { }
--     for i = 1, maxSize do
--         local cfg = rewardCfg[i];
--         nodesVisible["mRewardNode" .. i] = cfg ~= nil;
--         if cfg ~= nil then
--             local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
--             if resInfo ~= nil then
--                 sprite2Img["mPic" .. i] = resInfo.icon;
--                 lb2Str["mNum" .. i] = "x" .. GameUtil:formatNumber(cfg.count);
--                 --lb2Str["mName" .. i] = resInfo.name;

--                 NodeHelper:setBlurryString(container, "mName" .. i, resInfo.name, GameConfig.BlurryLineWidth, 5)


--                 menu2Quality["mFrame" .. i] = resInfo.quality
--                 sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
--                 if resInfo.iconScale then
--                     scaleMap["mPic" .. i] = 1
--                 end

--                 colorTabel["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
--                 if isShowNum then
--                     resInfo.count = resInfo.count or 0
--                     lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count;
--                 end
--             else
--                 CCLuaLog("Error::***reward item not found!!");
--             end
--         end
--     end

--     NodeHelper:setNodesVisible(container, nodesVisible);
--     NodeHelper:setStringForLabel(container, lb2Str);
--     NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
--     NodeHelper:setQualityFrames(container, menu2Quality);
--     NodeHelper:setColorForLabel(container, colorTabel);
-- end


function ActPopUpSaleSubPage_132:onClose(container)
	
end

function ActPopUpSaleSubPage_132:onExit(parentContainer)
	--    local timerName = ExpeditionDataHelper.getPageTimerName()
	--    TimeCalculator:getInstance():removeTimeCalcultor(timerName)
	   NodeHelper:clearScrollView(self.container)
	   self:removePacket(parentContainer)
end

function ActPopUpSaleSubPage_132:onRecharge(container)
	require ("ActPopUpSale.ActPopUpSalePage")
	ActPopUpSalePage_setReward(self.rewardItems)
	self:sendBuyRequest(container)
	--    if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
	--        common:rechargePageFlag("ActPopUpSaleSubPage_132")
	--        return
	--    end
	--    local msg = Activity4_pb.Activity132LevelGiftBuyReq()
	--    msg.cfgId = _buyData.id
	--    common:sendPacket(HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_C, msg, true)
end

function ActPopUpSaleSubPage_132:onReceive(container)
	self:sendBuyRequest(container)
	--    if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
	--        common:rechargePageFlag("ActPopUpSaleSubPage_132")
	--        return
	--    end
	--    local msg = Activity4_pb.Activity132LevelGiftBuyReq()
	--    msg.cfgId = _buyData.id
	--    common:sendPacket(HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_C, msg, true)
end

function ActPopUpSaleSubPage_132:sendBuyRequest(container)
	--if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
	--    common:rechargePageFlag("ActPopUpSaleSubPage_132")
	--    return
	--end
	local msg = Activity4_pb.Activity132LevelGiftBuyReq()
	msg.cfgId = _buyData.id
	common:sendPacket(HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_C, msg, false)
end


function ActPopUpSaleSubPage_132:onExecute(parentContainer)
	local isLeftTimeSeted = false
	if _serverData ~= nil and _serverData.limitDate ~= nil then
		local leftTime = _serverData.limitDate - os.time()
		if leftTime > 0 then
			-- 剩餘時間 轉至 日期格式
			local leftTimeDate = TimeDateUtil:utcTime2Date(leftTime)
			-- 重新進位
			leftTimeDate = TimeDateUtil:utcDateCarry(leftTimeDate)

			-- 原本是 日時分 所以字串定 dhm 可能改leftTime比較精確
			local SplitTime =  common:second2DateString4(leftTime,true)
			local text=string.format(common:getLanguageString("@ActPopUpSale.LeftTimeText.dhm"),SplitTime[1], SplitTime[2], SplitTime[3], SplitTime[4])            
			NodeHelper:setStringForTTFLabel(self.container, {
				leftTimeText = text
			})
			isLeftTimeSeted = true
		end
	end
	
	NodeHelper:setNodesVisible(self.container, {
		leftTimeText = isLeftTimeSeted
	});
	 local MainPage=require("ActPopUpSale.ActPopUpSalePage")
	if not isLeftTimeSeted then  MainPage:onCloseBtn(self.container)  end
end


function ActPopUpSaleSubPage_132:getActivityInfo()

end

function ActPopUpSaleSubPage_132:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
	if opcode == OPCODES.ACTIVITY132_LEVEL_GIFT_BUY_S then
		local msg = Activity4_pb.Activity132LevelGiftBuyRes()
		msg:ParseFromString(msgBuff)
		-- local Const_pb = require("Const_pb")
		-- ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY132_LEVEL_GIFT)
		-- local gotCfgId = msg.gotCfgId
	   
	end
end

function ActPopUpSaleSubPage_132:BuySucc(msg)
		ActPopUpSaleSubPage_132_setServerData(msg)
		_buyData = ActPopUpSaleSubPage_132_getIsShowMainSceneIcon()
		PageManager.refreshPage("MainScenePage", "isShowActivity132Icon")
		-- 检查小红点
		if not _buyData.isShowRedPoint then
			ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY132_LEVEL_GIFT)
		end
		if not _buyData.isShowIcon then
			self:onClose()
		else
			self:initUi(self.container)
		end
end

function ActPopUpSaleSubPage_132:chakeRedPoint()
	local isShowRedPoint = false



	if not isShowRedPoint then

	end
end


function ActPopUpSaleSubPage_132:onPlayEnterSpine(container)
	local parentNode = container:getVarNode("mEffectSpineNode")
	local spine = SpineContainer:create("NGUI", "NGUI_11_PopGift")
	local spineNode = tolua.cast(spine, "CCNode")
	parentNode:addChild(spineNode)
	spine:runAnimation(1, "animation", 0)
end

function ActPopUpSaleSubPage_132:registerPacket(container)
	for key, opcode in pairs(OPCODES) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function ActPopUpSaleSubPage_132:removePacket(container)
	for key, opcode in pairs(OPCODES) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end


function ActPopUpSaleSubPage_132_sendInfoRequest()
	common:sendEmptyPacket(HP_pb.ACTIVITY132_LEVEL_GIFT_INFO_C, false)
end

function ActPopUpSaleSubPage_132_getShowData()
	return _showData
end

function ActPopUpSaleSubPage_132_getServerData()
	return _serverData
end

function ActPopUpSaleSubPage_132_setServerData(msg)
	_serverData = msg
	if _serverData == nil then
		_serverData = { }
		return
	end
	_serverData = { }
	for i = 1, #msg.info do
		local imteData = msg.info[i]
		_serverData[imteData.cfgId] = { id = imteData.cfgId, isGot = imteData.isGot }
	end

	if msg.limitDate ~= nil then
		_serverData.limitDate = os.time() +msg.limitDate
		local PopUpPage=require("ActPopUpSale.ActPopUpSalePage")
		_buyData=ActPopUpSaleSubPage_132_getIsShowMainSceneIcon()
		PopUpPage:setTime(132, _serverData.limitDate,_serverData[1].isGot,_buyData.id)
	end
end

function ActPopUpSaleSubPage_132_getIsShowMainSceneIcon()
	if _serverData == nil then
		print("serverData is null 132")
		_showData = { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
		return _showData
	end

	if _serverData.limitDate ~= nil and os.time() >= _serverData.limitDate then
		_showData = { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
		return _showData
	end

	_ConfigData = ConfigManager.getAct132Cfg()

	for k, v in pairs(_ConfigData) do
		if _serverData[v.id-300] and not _serverData[v.id-300].isGot then
			_showData = { isShowIcon = true, id = v.id-300, isFree = true, isShowRedPoint = false }
			return _showData
		end
	end
	_showData = { isShowIcon = false, id = 0, isFree = false, isShowRedPoint = false }
	return _showData
end

return ActPopUpSaleSubPage_132
