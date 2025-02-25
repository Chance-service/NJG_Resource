----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local thisPageName = "MercenaryEnhancePage"

local HP_pb = require("HP_pb");
local RoleOpr_pb = require("RoleOpr_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local EquipScriptData = require("EquipScriptData")
local UserItemManager = require("Item.UserItemManager")
local opcodes = {
	ROLE_BAPTIZE_C = HP_pb.ROLE_BAPTIZE_C,
	ROLE_BAPTIZE_S = HP_pb.ROLE_BAPTIZE_S,
	ROLE_REPLACE_C = HP_pb.ROLE_REPLACE_C,
	ROLE_REPLACE_S = HP_pb.ROLE_REPLACE_S,
    ROLE_BAPTIZE_MAX_C = HP_pb.ROLE_BAPTIZE_MAX_C,
    ROLE_BAPTIZE_MAX_S = HP_pb.ROLE_BAPTIZE_MAX_S,
    ROLE_SENIORBAPTIZE_C = HP_pb.ROLE_SENIORBAPTIZE_C,  --高级自动育成
    ROLE_SENIORBAPTIZE_S = HP_pb.ROLE_SENIORBAPTIZE_S   --高级自动育成
};

local mGrowBtnStr = 
{
   mBtnStr1 = "@Trainee",
   mBtnStr2 = "@Normal",
   mBtnStr3 = "@Pro",
   mBtnStr4 = "Master"
}
local option = {
	ccbiFile = "MercenaryEnhancePopUp.ccbi",
	handlerMap = {
		onCancel		= "onCancel",
		onClose			= "onClose",
		onConfirm		= "onSave",
		onTrainee		= "onCommonTrain",
		onNormal		= "onGoldTrainNormal",
		onAutomaticJoin = "onAutomaticJoin",
        onAutomaticJoinSingle = "onAutomaticJoinSingle",
        onAutomaticJoinTen = "onAutomaticJoinTen",
		onPro			= "onGoldTrainMedium",
		onMaster		= "onGoldTrainSenior",
		onHelp			= "onHelp",
        onAutoSetting   = "onAutoSetting", 
	},
	opcode = opcodes
};

local TrainType = {
	Coin 		= 1,
	GoldNormal	= 2,
	GoldMedium	= 3,
	GoldSenior	= 4
};
local attr2Index = {
	mStrengthNum 		= 1,
	mDexterityNum		= 2,
	mIntelligenceNum	= 3,		
	mStaminaNum			= 4
};

local OneKeyEnable = false
local MultiEnable = false  --是否选中高级自动育成
local MultiSuccessTimes = 0
local MultiMinSendTime = -1  --网络太好了延迟发送
local MultiNoticeGoods = {{},{},{},{}} -- 高速自动育成育成丹提示是否提示过了
local MultiNoticeMoney = {} -- 高速自动育成钱提示是否提示过了
local BeginCheckAutoTime = false
local BeginAuto = false
local firstConfirm = false
local autoSave = false
local OneKeyType = 1
local OneKeyCostType = 1 -- 1,货币 2,培养丹

local btnStr = {"@Trainee", "@Normal", "@Pro", "@Master"}

local MercenaryEnhancePageBase = {}
local PBHelper = require("PBHelper");
local NodeHelper = require("NodeHelper");
local UserMercenaryManager = require("UserMercenaryManager");
--------------------------------------------------------------

local roleCfg = ConfigManager:getRoleCfg();

--确定，取消按钮
local enhanceNode = {}
--普通、钻石等按钮
local beforeEnhanceNode = {};

local thisRoleId = 0;
local userMercenary = {};
local currentAttrs = {};
local vipTab = {}
local _maxAttributeInfos = {}--当前佣兵的属性 最大值
--如果是至尊培养
local mIsAfterSenior = false
local thisContainer = nil
----------------------------------------------------------------------------------

-----------------------------------------------
--MercenaryEnhancePageBase页面中的事件处理
----------------------------------------------
function MercenaryEnhancePageBase:onEnter(container)
    thisContainer = container
	OneKeyEnable = false
    MultiEnable = false
	BeginAuto = false
	autoSave = false
    MultiMinSendTime = -1
    MultiSuccessTimes = 0
    BeginCheckAutoTime = false
    _maxAttributeInfos = {}
	self:registerPacket(container)
    self:getMaxAttribute()
	UserInfo.sync()
	vipTab = ConfigManager.getVipCfg()
	beforeEnhanceNode = container:getVarNode("mBeforeEnhanceBtn")
	enhanceNode = container:getVarNode("mEnhanceBtn");	
	
	self:showTrainConfirm(false);
	self:refreshBasicPage(container);
    local tempVipLevel = UserInfo.playerInfo.vipLevel
    --VIP7出自动十次育成
    NodeHelper:setNodesVisible(container, { mBtnOpen2 =  tempVipLevel >= GameConfig.Cost.RoleTrain.GoldSeniorVip,
                                            mAutoGrow1 = tempVipLevel <  GameConfig.Cost.RoleTrain.MultiTrainVip,--只有一个自动育成选项
                                            mAutoGrow2 = tempVipLevel >= GameConfig.Cost.RoleTrain.MultiTrainVip,--有两个自动育成选项 VIP8
                                            mBtnOpen1 =  tempVipLevel >= GameConfig.Cost.RoleTrain.GoldMediumVip,
                                            mChoice02 = OneKeyEnable,
                                            mChoiceSingle2 = OneKeyEnable,
                                            mChoiceTen2 = MultiEnable});
    if tempVipLevel < GameConfig.Cost.RoleTrain.GoldSeniorVip or tempVipLevel < GameConfig.Cost.RoleTrain.GoldSeniorVip then
        NodeHelper:setNodesVisible(container, { mBtnInfo = true});
    else
        NodeHelper:setNodesVisible(container, { mBtnInfo = false});
    end
    
end

function MercenaryEnhancePageBase:showTrainConfirm(doShow,successTimes)
    successTimes = tonumber(successTimes)
    if successTimes then
        NodeHelper:setNodesVisible(thisContainer, {mEnhanceStopTxt = true})
        NodeHelper:setStringForLabel(thisContainer,{mEnhanceStopTxt = common:getLanguageString("@MercenaryEnhanceOKTimes",successTimes,successTimes + 1)})
    else
        NodeHelper:setNodesVisible(thisContainer, {mEnhanceStopTxt = false})
    end
	beforeEnhanceNode:setVisible(not doShow);
	enhanceNode:setVisible(doShow);
end

function MercenaryEnhancePageBase:showCost(container)
	local coinCost = tonumber(GameConfig.Cost.RoleTrain.Common) * userMercenary.level;
	local goldStr = common:getLanguageString("@Gold")
	local lb2Str = {
		mCostCoin 	= GameUtil:formatNumber(coinCost),
		mCostGold1	= GameConfig.Cost.RoleTrain.GoldNormal ,
		mCostGold2	= GameConfig.Cost.RoleTrain.GoldMedium ,
		mCostGold3	= GameConfig.Cost.RoleTrain.GoldSenior 
	};
	NodeHelper:setStringForLabel(container, lb2Str);
end
function MercenaryEnhancePageBase:showMaxAttribute(container)
    if #_maxAttributeInfos ~= 4 then return end
	local lb2Str = {
		mStrengthNumMax1 	= "(" .. _maxAttributeInfos[1] .. ")",
		mDexterityNumMax1	= "(" .. _maxAttributeInfos[2] .. ")",
		mIntelligenceNumMax1	= "(" .. _maxAttributeInfos[3] .. ")",
		mStaminaNumMax1	= "(" .. _maxAttributeInfos[4] .. ")"
	};
	NodeHelper:setStringForLabel(container, lb2Str);
	for i = 1, 4 do
		if currentAttrs[i] > _maxAttributeInfos[i] then
			for j = 1, 4 do
				NodeHelper:setMenuItemEnabled(container, "mCostBtn"..j, false)
                NodeHelper:setNodeIsGray(container, {["mBtnText_" .. j] = true})
			end
			break
		end
	end
end
function MercenaryEnhancePageBase:onExecute(container)
    if BeginAuto and MultiEnable and MultiMinSendTime > 0 then
        MultiMinSendTime = MultiMinSendTime - GamePrecedure:getInstance():getFrameTime()
        if BeginCheckAutoTime and MultiMinSendTime <= 0 then
            self:autoTrain(container)
            BeginCheckAutoTime = false
        end
    end
end
function MercenaryEnhancePageBase:onExit(container)
	self:removePacket(container);
	beforeEnhanceNode = nil;
	enhanceNode = nil;
end
----------------------------------------------------------------
function MercenaryEnhancePageBase:refreshLeftPanel(container)
	userMercenary = UserMercenaryManager:getUserMercenaryById(thisRoleId);
    
	currentAttrs = {
        ----加上佣兵洗练属性
		PBHelper:getAttrById(userMercenary.baseAttr.attribute, Const_pb.STRENGHT)+PBHelper:getAttrById(userMercenary.baptizeAttr.attribute , Const_pb.STRENGHT),
		PBHelper:getAttrById(userMercenary.baseAttr.attribute, Const_pb.AGILITY)+PBHelper:getAttrById(userMercenary.baptizeAttr.attribute , Const_pb.AGILITY),
		PBHelper:getAttrById(userMercenary.baseAttr.attribute, Const_pb.INTELLECT)+PBHelper:getAttrById(userMercenary.baptizeAttr.attribute, Const_pb.INTELLECT),
		PBHelper:getAttrById(userMercenary.baseAttr.attribute, Const_pb.STAMINA)+PBHelper:getAttrById(userMercenary.baptizeAttr.attribute, Const_pb.STAMINA)
	};
--    CCLuaLog("MercenaryEnhancePageBase--STRENGHT--base-------------------")
--    CCLuaLog("MercenaryEnhancePageBase--STRENGHT--base-----------------"..PBHelper:getAttrById(userMercenary.baseAttr.attribute , Const_pb.STRENGHT))
--    CCLuaLog("MercenaryEnhancePageBase--AGILITY-base-----------------------"..PBHelper:getAttrById(userMercenary.baseAttr.attribute , Const_pb.AGILITY))
--    CCLuaLog("MercenaryEnhancePageBase--INTELLECT-base------------------------"..PBHelper:getAttrById(userMercenary.baseAttr.attribute , Const_pb.INTELLECT))
--    CCLuaLog("MercenaryEnhancePageBase--STAMINA-base--------------------"..PBHelper:getAttrById(userMercenary.baseAttr.attribute , Const_pb.STAMINA))

--    CCLuaLog("MercenaryEnhancePageBase--STRENGHT--------------"..PBHelper:getAttrById(userMercenary.baptizeAttr.attribute , Const_pb.STRENGHT))
--    CCLuaLog("MercenaryEnhancePageBase--AGILITY---------------"..PBHelper:getAttrById(userMercenary.baptizeAttr.attribute , Const_pb.AGILITY))
--    CCLuaLog("MercenaryEnhancePageBase--INTELLECT-----------------"..PBHelper:getAttrById(userMercenary.baptizeAttr.attribute , Const_pb.INTELLECT))
--    CCLuaLog("MercenaryEnhancePageBase--STAMINA--------------"..PBHelper:getAttrById(userMercenary.baptizeAttr.attribute , Const_pb.STAMINA))

	local lb2Str = {};
	for name, index in pairs(attr2Index) do
		lb2Str[name .. "1"] = currentAttrs[index];
	end
	NodeHelper:setStringForLabel(container, lb2Str);
end
function MercenaryEnhancePageBase:refreshItemCount(container)
    local lb2Str = {}
    local coinCost = tonumber(GameConfig.Cost.RoleTrain.Common) * userMercenary.level;
    --local goldStr = common:getLanguageString("@Gold")
    local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.CommonItem)
    if itemInfo then
	    if itemInfo.count >= 1 then--显示培养丹
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(30000, GameConfig.Cost.RoleTrain.CommonItem, 1)
            NodeHelper:setNodesVisible(container, { mIcon1 = false,mItem1 = true});
            lb2Str["mCostCoin"] = "x" ..itemInfo.count
		else
            NodeHelper:setNodesVisible(container, { mIcon1 = true,mItem1 = false});
            lb2Str["mCostCoin"] = GameUtil:formatNumber(coinCost)
	    end
    else
        NodeHelper:setNodesVisible(container, { mIcon1 = true,mItem1 = false});
        lb2Str["mCostCoin"] = GameUtil:formatNumber(coinCost)
    end
    itemInfo = nil
    itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.NormalItem)
    if itemInfo then
	    if itemInfo.count >= 1 then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(30000, GameConfig.Cost.RoleTrain.NormalItem, 1)
            NodeHelper:setNodesVisible(container, { mIcon2 = false,mItem2 = true});
            lb2Str["mCostGold1"] = "x" ..itemInfo.count
		else
            lb2Str["mCostGold1"] = GameConfig.Cost.RoleTrain.GoldNormal
            NodeHelper:setNodesVisible(container, { mIcon2 = true,mItem2 = false});
	    end
    else
        NodeHelper:setNodesVisible(container, { mIcon2 = true,mItem2 = false});
        lb2Str["mCostGold1"] = GameConfig.Cost.RoleTrain.GoldNormal
    end
    itemInfo = nil
    itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.HighAItem)
    if itemInfo then
	    if itemInfo.count >= 1 then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(30000, GameConfig.Cost.RoleTrain.HighAItem, 1)
            NodeHelper:setNodesVisible(container, { mIcon3 = false,mItem3 = true});
            lb2Str["mCostGold2"] = "x" ..itemInfo.count
		else
            lb2Str["mCostGold2"] = GameConfig.Cost.RoleTrain.GoldMedium
            NodeHelper:setNodesVisible(container, { mIcon3 = true,mItem3 = false});
	    end
    else
        NodeHelper:setNodesVisible(container, { mIcon3 = true,mItem3 = false});
        lb2Str["mCostGold2"] = GameConfig.Cost.RoleTrain.GoldMedium
    end

    NodeHelper:setStringForLabel(container, lb2Str);
end
function MercenaryEnhancePageBase:refreshRightPanel(container, vals)
	local lb2Str = {}
	local colorMap = {}
	for name, index in pairs(attr2Index) do
		lb2Str[name .. "2"] = string.format("%d(%+d)", vals[index] + currentAttrs[index], vals[index]);
		if vals[index] < 0 then
		    colorMap[name .. "2"] = GameConfig.ColorMap.COLOR_RED
		elseif vals[index] > 0 then
		    colorMap[name .. "2"] = GameConfig.ColorMap.COLOR_GREEN
		else
		    colorMap[name .. "2"] = GameConfig.ColorMap.COLOR_WHITE
		end
		
	end
	NodeHelper:setStringForLabel(container, lb2Str)
	NodeHelper:setColorForLabel( container, colorMap )
end

function MercenaryEnhancePageBase:resetRightPanel(container)
	local lb2Str = {};
	for name, index in pairs(attr2Index) do
		lb2Str[name .. "2"] = "";
	end
	NodeHelper:setStringForLabel(container, lb2Str);
end

function MercenaryEnhancePageBase:refreshBasicPage(container)
	userMercenary = UserMercenaryManager:getUserMercenaryById(thisRoleId);
	--获取富文本中的职业、主属性等字段，将来方便颜色扩展
    --local itemCfg = ConfigManager.getRoleCfg()[userMercenary.itemId]
	local professionStr = FreeTypeConfig[11].content;
    local mainAttribute = FreeTypeConfig[17].content;
	--if itemCfg.profession == 1 then
	--	professionStr = FreeTypeConfig[11].content;
    --    mainAttribute = FreeTypeConfig[17].content;
	--elseif itemCfg.profession == 2 then
	--	professionStr = FreeTypeConfig[12].content;
    --    mainAttribute = FreeTypeConfig[18].content;
	--elseif itemCfg.profession == 3 then
	--	professionStr = FreeTypeConfig[13].content;	
    --    mainAttribute = FreeTypeConfig[19].content;			
	--end
	local lb2Str = {
		mLv 					= UserInfo.getStageAndLevelStr(),
		mMercenaryLv 			= UserInfo.getStageAndLevelStr(),
		--mMercenaryName 			= roleCfg[userMercenary.itemId]["name"],
		mOccupation				= professionStr,
		mMainAttribute			= mainAttribute
	};
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setLabelOneByOne(container,"mMercenaryName","mMercenaryLv",5)
    NodeHelper:setQualityFrames(container, {
        mHand = 1--itemCfg.quality or 1
    },nil,true)
	
	local sprite2Img = {};
	--sprite2Img["mPic"] 	= roleCfg[userMercenary.itemId]["icon"];	
	NodeHelper:setSpriteImage(container, sprite2Img);
	
	self:showCost(container);
	self:refreshLeftPanel(container);
	self:resetRightPanel(container);
    self:refreshItemCount(container)
end	

function MercenaryEnhancePageBase:onAutomaticJoin( container )
	OneKeyEnable = not OneKeyEnable
    MultiEnable = false 
	NodeHelper:setNodesVisible(container,{mChoice02 = OneKeyEnable})
end
function MercenaryEnhancePageBase:onAutomaticJoinSingle( container )
    if BeginAuto then return end
    OneKeyEnable = not OneKeyEnable
    MultiEnable = false 
    NodeHelper:setNodesVisible(container,{mChoiceSingle2 = OneKeyEnable})
    NodeHelper:setNodesVisible(container,{mChoiceTen2 = MultiEnable})
end

function MercenaryEnhancePageBase:onAutomaticJoinTen( container )
    if BeginAuto then return end
	MultiEnable = not MultiEnable
    OneKeyEnable = false 
	NodeHelper:setNodesVisible(container,{mChoiceTen2 = MultiEnable})
    NodeHelper:setNodesVisible(container,{mChoiceSingle2 = OneKeyEnable})
end
function MercenaryEnhancePageBase:tryTrain(trainType, container, useGoods)
	if OneKeyEnable then
		if not firstConfirm then
			local titile = common:getLanguageString("@BeginAuto")
			local tipinfo = common:getLanguageString("@AotuEnhanceDesc")
		    PageManager.showConfirm(titile,tipinfo, function(isSure)
		    	if isSure then
		    		firstConfirm = true
		    		MercenaryEnhancePageBase:beginAutoEnhance(trainType, container,useGoods)
			    end
		    end);
		else
			MercenaryEnhancePageBase:beginAutoEnhance(trainType, container,useGoods)
		end
	elseif MultiEnable then 
       local confirmFunc = function(isSure)
		    if isSure then
                if useGoods == true then
                    MultiNoticeGoods[trainType][userMercenary.itemId] = true
                elseif trainType == TrainType.Coin then
                    MultiNoticeMoney[userMercenary.itemId] = true
                end
		    	MercenaryEnhancePageBase:beginAutoEnhance(trainType, container,useGoods,true)
			end
        end
        local titile = common:getLanguageString("@MultiTrainNoticeTitle")
        local tipinfo = ""
        if useGoods == true then
            tipinfo = common:fillHtmlStr('MultiTrainUseTools') 
            if MultiNoticeGoods[trainType][userMercenary.itemId] then
                confirmFunc(true)
            else
                PageManager.showHtmlConfirm(titile,tipinfo, confirmFunc,nil,0.9);
            end
        elseif trainType == TrainType.Coin then
            local coinCost = tonumber(GameConfig.Cost.RoleTrain.Common) * userMercenary.level;
            coinCost = coinCost * 10 / 10000
            tipinfo = common:fillHtmlStr('MultiTrainUseLv' .. trainType,coinCost)
            
            if MultiNoticeMoney[userMercenary.itemId] then
                confirmFunc(true)
            else
                PageManager.showHtmlConfirm(titile,tipinfo, confirmFunc,nil,0.9);
            end
        else
            tipinfo = common:fillHtmlStr('MultiTrainUseLv' .. trainType)
            PageManager.showHtmlConfirm(titile,tipinfo, confirmFunc,nil,0.9);
        end
    else
	    self:sendTrain(trainType, useGoods)
    end
end

function MercenaryEnhancePageBase:beginAutoEnhance( trainType, container ,useGoods, isMulti)
	BeginAuto = true
    --autoSave = true 
    if not isMulti then 
	  autoSave = true
    else
      MultiSuccessTimes = 0
    end
	OneKeyType = trainType
	OneKeyCostType = 1
    OneKeyCostType = useGoods and 2 or 1
--	if trainType == TrainType.Coin then
--		local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.CommonItem)
--		if itemInfo and itemInfo.count > 0 then
--			OneKeyCostType = 2
--		end
--	elseif trainType == TrainType.GoldNormal then
--		local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.NormalItem)
--		if itemInfo and itemInfo.count > 0 then
--			OneKeyCostType = 2
--		end
--	elseif trainType == TrainType.GoldMedium then
--		local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.HighAItem)
--		if itemInfo and itemInfo.count > 0 then
--			OneKeyCostType = 2
--		end		
--	end
	local strTable = {}
	strTable["mCostTxt"..OneKeyType] = common:getLanguageString("@Cancel")
	NodeHelper:setStringForLabel(container,strTable)
	for i = 1, 4 do
		NodeHelper:setMenuItemEnabled(container, "mCostBtn"..i, i == OneKeyType)
        NodeHelper:setNodeIsGray(container, {["mBtnText_" .. i] = not i == OneKeyType })
	end
    local strTable = {}
	strTable["mBtnText_"..trainType] = common:getLanguageString("@Cancel")
    NodeHelper:setStringForLabel(container, strTable)
	self:sendTrain(trainType, OneKeyCostType == 2,nil , isMulti)
end

function MercenaryEnhancePageBase:CancleAutoTrain( container )
	local strTable = {}
	strTable["mCostTxt"..OneKeyType] = common:getLanguageString(btnStr[OneKeyType])
	for i = 1, 4 do
		NodeHelper:setMenuItemEnabled(container, "mCostBtn"..i, true)
        NodeHelper:setNodeIsGray(container, {["mBtnText_" .. i] = false})
        strTable["mBtnText_"..i] = common:getLanguageString(btnStr[i])
	end
    NodeHelper:setStringForLabel(container,strTable)

	BeginAuto = false
	OneKeyType = 0
	OneKeyCostType = 1			
end

function MercenaryEnhancePageBase:autoTrain( container )
	if OneKeyType <= 0 then return end
	if OneKeyType == TrainType.Coin then
		if OneKeyCostType == 2 then
			local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.CommonItem)
			if not itemInfo or itemInfo.count <= 0 then
				self:CancleAutoTrain(container)
				return
			end
		else
			local coinCost = tonumber(GameConfig.Cost.RoleTrain.Common) * userMercenary.level;
			if not UserInfo.isCoinEnough(coinCost) then
				self:CancleAutoTrain(container)
				return
			end
		end
	elseif OneKeyType == TrainType.GoldNormal then
		if OneKeyCostType == 2 then
			local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.NormalItem)
			if not itemInfo or itemInfo.count <= 0 then
				self:CancleAutoTrain(container)
				return
			end
		else
			local gold = tonumber(GameConfig.Cost.RoleTrain.GoldNormal);
			if not UserInfo.isGoldEnough(gold,"onGoldTrain_enter_rechargePage") then
				self:CancleAutoTrain(container)
				return
			end			
		end
	elseif OneKeyType == TrainType.GoldMedium then
		if OneKeyCostType == 2 then
			local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.HighAItem)
			if not itemInfo or itemInfo.count <= 0 then
				self:CancleAutoTrain(container)
				return
			end
		else
			local gold = tonumber(GameConfig.Cost.RoleTrain.GoldMedium);
			if not UserInfo.isGoldEnough(gold,"onGoldTrain_enter_rechargePage") then
				self:CancleAutoTrain(container)
				return
			end			
		end		
	elseif OneKeyType == TrainType.GoldSenior then
		local gold = tonumber(GameConfig.Cost.RoleTrain.GoldSenior);
		if not UserInfo.isGoldEnough(gold,"onGoldTrain_enter_rechargePage") then
			self:CancleAutoTrain(container)
			return
		end	
	end
	self:sendTrain( OneKeyType, OneKeyCostType == 2, true,MultiEnable )
end

function MercenaryEnhancePageBase:sendTrain( trainType, useGoods, notNeedWaiting ,isMulti)
	local msg = RoleOpr_pb.HPRoleBaptize();
	msg.roleId = thisRoleId;
	msg.type = trainType;
	msg.isUseGoods = useGoods == true

	local pb_data = msg:SerializeToString();
    if isMulti == true then
        MultiMinSendTime = 1
        PacketManager:getInstance():sendPakcet(opcodes.ROLE_SENIORBAPTIZE_C, pb_data, #pb_data, not notNeedWaiting);
    else
	    PacketManager:getInstance():sendPakcet(opcodes.ROLE_BAPTIZE_C, pb_data, #pb_data, not notNeedWaiting);
    end
end

function MercenaryEnhancePageBase:saveTrain()
	local msg = RoleOpr_pb.HPRoleAttrReplace()
	msg.roleId = thisRoleId
	local pb_data = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(opcodes.ROLE_REPLACE_C, pb_data, #pb_data, not BeginAuto)		
	--common:sendPacket(opcodes.ROLE_REPLACE_C, msg);	
end
function MercenaryEnhancePageBase:getMaxAttribute()
	local msg = RoleOpr_pb.HPRoleMaxAttribute()
	msg.roleId = thisRoleId
	local pb_data = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(opcodes.ROLE_BAPTIZE_MAX_C, pb_data, #pb_data, false)		
	--common:sendPacket(opcodes.ROLE_REPLACE_C, msg);	
end
----------------click event------------------------
function MercenaryEnhancePageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

function MercenaryEnhancePageBase:onCancel(container)
	self:resetRightPanel(container);
	self:showTrainConfirm(false);
end

function MercenaryEnhancePageBase:onSave(container)
	self:saveTrain();
end	

function MercenaryEnhancePageBase:onCommonTrain(container)
	if BeginAuto then
		self:CancleAutoTrain(container)
		return
	end	
	local coinCost = tonumber(GameConfig.Cost.RoleTrain.Common) * userMercenary.level;
    local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.CommonItem)
    if itemInfo then
	    if itemInfo.count >= 1 then--显示培养丹	
	    	   self:tryTrain(TrainType.Coin, container, true);
	    else
			if UserInfo.isCoinEnough(coinCost) then
				self:tryTrain(TrainType.Coin, container);
			end
		end
	else
		if UserInfo.isCoinEnough(coinCost) then
			self:tryTrain(TrainType.Coin, container);
		end		
	end
end

function MercenaryEnhancePageBase:onGoldTrainNormal(container)
    --[[local vipLevelLimit = self:getVipLimitLevel(1)
	if UserInfo.playerInfo.vipLevel < vipLevelLimit then
		MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@TranVipLimit", vipLevelLimit, common:getLanguageString("@Normal")))
		return
	end]]--
	if BeginAuto then
		self:CancleAutoTrain(container)
		return
	end
	local gold = tonumber(GameConfig.Cost.RoleTrain.GoldNormal);
    local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.NormalItem)
    if itemInfo then
	    if itemInfo.count >= 1 then--显示培养丹	
	    	self:tryTrain(TrainType.GoldNormal, container, true);
	    else
			if UserInfo.isGoldEnough(gold,"onGoldTrain_enter_rechargePage") then
				self:tryTrain(TrainType.GoldNormal, container);
			end
		end
	else
		if UserInfo.isGoldEnough(gold,"onGoldTrain_enter_rechargePage") then
			self:tryTrain(TrainType.GoldNormal, container);
		end		
	end
end

function MercenaryEnhancePageBase:onGoldTrainMedium(container)
	if BeginAuto then
		self:CancleAutoTrain(container)
		return
	end
	local gold = tonumber(GameConfig.Cost.RoleTrain.GoldMedium);
    local itemInfo = UserItemManager:getUserItemByItemId(GameConfig.Cost.RoleTrain.HighAItem)
    if itemInfo then
	    if itemInfo.count >= 1 then--显示培养丹	
	    	self:tryTrain(TrainType.GoldMedium, container, true);
	    else
			if UserInfo.isGoldEnough(gold,"onGoldTrain_enter_rechargePage") then
				self:tryTrain(TrainType.GoldMedium, container);
			end
		end
	else
		if UserInfo.isGoldEnough(gold,"onGoldTrain_enter_rechargePage") then
			self:tryTrain(TrainType.GoldMedium, container);
		end		
	end
end

function MercenaryEnhancePageBase:onGoldTrainSenior(container)
	--[[local vipLevelLimit = self:getVipLimitLevel(3)
	if UserInfo.playerInfo.vipLevel < vipLevelLimit then
		MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@TranVipLimit", vipLevelLimit, common:getLanguageString("@Master")))
		return
	end]]--
	self:onGoldTrain(GameConfig.Cost.RoleTrain.GoldSenior, TrainType.GoldSenior, container);
end

function MercenaryEnhancePageBase:onGoldTrain(gold, trainType, container)
	if BeginAuto then
		self:CancleAutoTrain(container)
		return
	end	
	if UserInfo.isGoldEnough(gold,"onGoldTrain_enter_rechargePage") then
	    if trainType == TrainType.GoldSenior then
	        mIsAfterSenior = true
	    end
		self:tryTrain(trainType, container);
	end
end

function MercenaryEnhancePageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARY_TRAIN)
end	

--回包处理
function MercenaryEnhancePageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	
	if opcode == opcodes.ROLE_BAPTIZE_S then
		local msg = RoleOpr_pb.HPRoleBaptizeRet();
		msg:ParseFromString(msgBuff);
		local vals = {};
		for _, val in ipairs(msg.values) do
			table.insert(vals, val);
		end
		if autoSave then
			local toSave = true
            local autoTrainPopUp = require("AutoTrainPopUp")
            local autoSetting = autoTrainPopUp.loadPlayerSetting(container)
            --新增條件判斷
            if autoSetting[1] == 1 and vals[1] < 0 then
                toSave = false
            end
            if autoSetting[2] == 1 and vals[2] < 0 then
                toSave = false
            end
            if autoSetting[3] == 1 and vals[3] < 0 then
                toSave = false
            end
            if autoSetting[4] == 1 and vals[4] < 0 then
                toSave = false
            end
            if autoSetting[5] == 1 and vals[1] + vals[2] + vals[3] + vals[4] < 0 then
                toSave = false
            end
            --[[
            if autoSetting[1] == 0 and autoSetting[2] == 0 and autoSetting[3] == 0 and autoSetting[4] == 0 and autoSetting[5] == 0 then
			    for i,v in ipairs(vals) do
			    	if v < 0 then
			    		toSave = false
			    	end
			    end
            end]]--
			if toSave then
				self:refreshItemCount(container)
				self:saveTrain()
				return
			else
				autoSave = false
				if BeginAuto then
					self:CancleAutoTrain(container)
				end
			end
		end
		self:refreshRightPanel(container, vals);
		if mIsAfterSenior then
		    self:saveTrain()
		    return
		end
		self:showTrainConfirm(true);
        self:refreshItemCount(container)
	elseif opcode == opcodes.ROLE_REPLACE_S then
		self:refreshLeftPanel(container);
		if not mIsAfterSenior then
		    self:resetRightPanel(container);
		end
		self:showTrainConfirm(false);
		mIsAfterSenior = false
		if BeginAuto then
			self:autoTrain(container)
		else
			autoSave = false
		end
    elseif opcode == opcodes.ROLE_BAPTIZE_MAX_S then
        local msg = RoleOpr_pb.HPRoleMaxAttributeRet();
		msg:ParseFromString(msgBuff);
        _maxAttributeInfos = msg.values
        self:showMaxAttribute(container)
	elseif opcode == opcodes.ROLE_SENIORBAPTIZE_S then
        local msg = RoleOpr_pb.HPRoleBaptizeRet();
		msg:ParseFromString(msgBuff);
		local vals = {};
        local toSave = true
        local toNewSave = false
        local autoTrainPopUp = require("AutoTrainPopUp")
        local autoSetting = autoTrainPopUp.loadPlayerSetting(container)
        for _, val in ipairs(msg.values) do
			table.insert(vals, val);
            if val < 0 then 
                toNewSave = true
            end
		end
        --新增條件判斷
        if autoSetting[1] == 1 and vals[1] < 0 and toSave == true then
            toSave = false
        end
        if autoSetting[2] == 1 and vals[2] < 0 and toSave == true then
            toSave = false
        end
        if autoSetting[3] == 1 and vals[3] < 0 and toSave == true then
            toSave = false
        end
        if autoSetting[4] == 1 and vals[4] < 0 and toSave == true then
            toSave = false
        end
        if autoSetting[5] == 1 and vals[1] + vals[2] + vals[3] + vals[4] < 0 and toSave == false then
            toSave = false
        end
        --self:saveTrain()
        self:refreshLeftPanel(container);
        MultiSuccessTimes = MultiSuccessTimes + msg.sucessTimes
        if not toNewSave then
            self:resetRightPanel(container)
            --self:refreshRightPanel(container, vals)
            --self:saveTrain()
        elseif toNewSave and toSave then
            self:resetRightPanel(container)
            --self:refreshRightPanel(container, vals)
            self:saveTrain()
        else
            self:refreshRightPanel(container, vals);
            if BeginAuto then
                self:CancleAutoTrain(container)
            end	
            self:showTrainConfirm(true, MultiSuccessTimes);
        end
        self:refreshItemCount(container)
        if BeginAuto then
            if MultiMinSendTime <= 0 then
                self:autoTrain(container)
            else
                BeginCheckAutoTime = true
            end
        end
    end
end

function MercenaryEnhancePageBase:onAutoSetting(container)
	PageManager.pushPage("AutoTrainPopUp")
end

function MercenaryEnhancePageBase:getVipLimitLevel( typeId )
	for i = 0,#vipTab,1 do
		if vipTab[i].maxMercenaryTime == typeId then
			return i
		end
	end
end

function MercenaryEnhancePageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function MercenaryEnhancePageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end


function MercenaryEnhancePageBase:resetMercenaryEnhancePageData()
    firstConfirm = false
    if not thisContainer then return end
    OneKeyEnable = false
    MultiEnable = false
    autoSave = false
    MultiMinSendTime = -1
    BeginCheckAutoTime = false
    NodeHelper:setNodesVisible(thisContainer,{mChoice02 = OneKeyEnable})
	NodeHelper:setNodesVisible(thisContainer,{ mChoiceTen2 = MultiEnable})
    NodeHelper:setNodesVisible(thisContainer,{ mChoiceSingle2 = OneKeyEnable})
    if BeginAuto then
        self:CancleAutoTrain(thisContainer)
    end
    MultiNoticeGoods = {{},{},{},{}}
    MultiNoticeMoney = {}
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local MercenaryEnhancePage = CommonPage.newSub(MercenaryEnhancePageBase, thisPageName, option);

function MercenaryEnhancePage_setRoleId(roleId)
	thisRoleId = roleId;
end

return MercenaryEnhancePage