----------------------------------------------------------------------------------
--[[
	特典里面的 礼包
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = 'WeekCardPage'
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local json = require('json')

local WeekCardPage = {}

local WeekCardCfg = {}
local mWeekContainerRef = {}



local WeekContent = {
    ccbiFile    = "Act_FixedTimeWeekCardListContent.ccbi",
    weekList = {},
    curOffset = nil,
}

function WeekContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

local opcodes = {
	NEW_WEEK_CARD_INFO_S 		= HP_pb.NEW_WEEK_CARD_INFO_S,
	NEW_WEEK_CARD_GET_AWARD_S		= HP_pb.NEW_WEEK_CARD_GET_AWARD_S
}
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local CurrentStageId = 1
function WeekContent.onFunction(eventName,container)
    xpcall(function()   
        if eventName == "luaUnLoad" then
            onUnload(pageName, container)
        end
        if eventName == "luaRefreshItemView" then
            WeekContent.onRefreshItemView(container);
        elseif eventName == "onBtn" then
            WeekContent.onReceiveReward(container);
        elseif eventName:sub(1, 7) == "onFrame" then
            --WeekContent.showItemInfo(container, eventName);    
        end     
    end,function ( ... )
        debugPage[pageName] = WeekCardPage.container
        CocoLog(...)
    end)    

end


function WeekContent:onBtn(container)
    local index = self.id
    local id = WeekContent.weekList[index].weekCardId
    local alreadyBuy = WeekContent.weekList[index].activateFlag
    local alreadyReceive = WeekContent.weekList[index].isTodayTakeAward
    if alreadyBuy and alreadyReceive == false then
        --领取
        local msg = Activity2_pb.HPGetNewWeekCardReward()
        msg.newWeekCardId = id;
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.NEW_WEEK_CARD_GET_AWARD_C, pb, #pb, true)
        WeekContent.curOffset = WeekCardPage.container.mScrollView:getContentOffset()
    elseif alreadyBuy == false then

        WeekCardPage:buyGoods(container,id);
        WeekContent.curOffset = WeekCardPage.container.mScrollView:getContentOffset()
        
    end
end

function WeekCardPage:buyGoods(container,id)
    local itemInfo = nil
    for i = 1,#RechargeCfg do
        CCLuaLog('buyGoods: productName=' .. RechargeCfg[i].productName.."id="..id)
        if tonumber(RechargeCfg[i].productId) == tonumber(id) then
            itemInfo = RechargeCfg[i];
            break
        end
    end
    if itemInfo == nil then return end
     CCLuaLog('buyGoods: productId=' .. itemInfo.productId.."id="..id)
    local buyInfo = BUYINFO:new()  
    buyInfo.productType         = itemInfo.productType;  
    buyInfo.name                = itemInfo.name;       
    buyInfo.productCount = 1
    buyInfo.productName = itemInfo.productName
    buyInfo.productId = itemInfo.productId
    buyInfo.productPrice = itemInfo.productPrice
    buyInfo.productOrignalPrice = itemInfo.gold
    buyInfo.description = ""
    if itemInfo:HasField("description") then
        buyInfo.description = itemInfo.description
    end
    buyInfo.serverTime = GamePrecedure:getInstance():getServerTime()
    
    local _type = tostring(itemInfo.productType)
--    if Golb_Platform_Info.is_yougu_platform then   -- 悠谷平台需要转换 productType
--        local rechargeTypeCfg = ConfigManager.getRecharageTypeCfg()
--        if rechargeTypeCfg[itemInfo.productType] then
--            _type = tostring(rechargeTypeCfg[itemInfo.productType].type)
--        end
--    end
    
    local _ratio = tostring(itemInfo.ratio)
    local extrasTable = {productType = _type, name = itemInfo.name, ratio = _ratio}
    buyInfo.extras = json.encode(extrasTable)

    --libPlatformManager:getPlatform():buyGoods(buyInfo)
    local BuyManager = require("BuyManager")
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end
function WeekContent.onFrame1(handle, container)
    WeekContent.showItemInfo(container, "onFrame1",handle.id)
end
function WeekContent.onFrame2(handle, container)
    WeekContent.showItemInfo(container, "onFrame2",handle.id)
end
function WeekContent.onFrame3(handle, container)
    WeekContent.showItemInfo(container, "onFrame3",handle.id)
end
function WeekContent.onFrame4(handle, container)
    WeekContent.showItemInfo(container, "onFrame4",handle.id)
end

function WeekContent.onFrame5(handle, container)
    WeekContent.showItemInfo(container, "onFrame5",handle.id)
end


function WeekContent.showItemInfo(container, eventName,mID)
    local index = tonumber(eventName:sub(-1))
    --local mID = tonumber(container:getItemDate().mID)
    local id = WeekContent.weekList[mID].weekCardId
    local packetItem = WeekCardCfg[id].rewards;
    local rewardItems = {}
     for _, item in ipairs(common:split(packetItem, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"));
        table.insert(rewardItems, {
            type    = tonumber(_type),
            itemId  = tonumber(_id),
            count   = tonumber(_count)
        });
    end
    GameUtil:showTip(container:getVarNode('mPic' .. index), rewardItems[index])
end

function WeekContent:onRefreshContent( ccbRoot )
    local index = self.id
    local id = WeekContent.weekList[index].weekCardId

    local container = ccbRoot:getCCBFileNode()
    
    mWeekContainerRef[id] = container;

    if WeekContent.weekList[index] then
        local packetItem = WeekCardCfg[id].rewards;
        local libStr = {
                    mWeekCardName = common:getLanguageString(WeekCardCfg[id].name),
                    }
        NodeHelper:setStringForLabel(container, libStr);                    
        local mWeekCardRate = container:getVarLabelBMFont("mWeekCardRate")
        if WeekCardCfg[id].freeTypeId ~= 0 then
            NodeHelper:setNodesVisible(container,{mVIPLimitNode = true})
            mWeekCardRate:setString("")
            local str = FreeTypeConfig[WeekCardCfg[id].freeTypeId].content
            str = common:fill(str,tostring(WeekCardCfg[id].param))
            NodeHelper:addHtmlLable(mWeekCardRate, str ,10086, CCSize(300,32))
        else
            NodeHelper:setNodesVisible(container,{mVIPLimitNode = false})
        end
    
        if packetItem ~= nil then
            local rewardItems = {}
            for _, item in ipairs(common:split(packetItem, ",")) do
                local _type, _id, _count = unpack(common:split(item, "_"));
                table.insert(rewardItems, {
                    type    = tonumber(_type),
                    itemId  = tonumber(_id),
                    count   = tonumber(_count),
                });
            end
            NodeHelper:fillRewardItem(container,rewardItems,4)
        end

        local SalePrice = 0
        for i = 1,#RechargeCfg do
            if tonumber(RechargeCfg[i].productId) == tonumber(id) then
                SalePrice = RechargeCfg[i].productPrice;
                break
            end
        end

        local enabledBtn = true;
        local ShowText = "";
        local alreadyBuy = WeekContent.weekList[index].activateFlag
        local alreadyReceive = WeekContent.weekList[index].isTodayTakeAward
        if alreadyBuy and alreadyReceive then
            enabledBtn = false
            ShowText = common:getLanguageString('@AlreadyReceive')
        elseif alreadyBuy and alreadyReceive == false then
            ShowText = common:getLanguageString('@CanReceive')
        elseif alreadyBuy == false then
            ShowText = common:getLanguageString("@RMB")..tostring(SalePrice)
        end

        if alreadyBuy then
            NodeHelper:setStringForLabel(container,{mWeekCardTime = common:getLanguageString('@RebateLeftDays',WeekContent.weekList[index].leftDays)});
        elseif WeekContent.weekList[index].showTime >3600000*24*365*5 then
            NodeHelper:setStringForLabel(container,{mWeekCardTime = ""});
        else
            NodeHelper:setStringForLabel(container,{mWeekCardTime = common:getLanguageString('@weekcardtips',math.ceil(WeekContent.weekList[index].showTime/24/3600000))});
        end
        -- NodeHelper:setStringForLabel(container,{mChatBtnTxt1 = common:getLanguageString('@RechargeLimit',SalepacketCfg[id].minLevel,SalepacketCfg[id].maxLevel)});
        NodeHelper:setStringForLabel(container,{mBtnTxt = ShowText});
        NodeHelper:setMenuItemEnabled(container,"mBtn",enabledBtn);

    end    
end

function WeekCardPage:onEnter(ParentContainer)

	local container = ScriptContentBase:create("Act_FixedTimeWeekCardContent.ccbi")
	self.container = container
    NodeHelper:initScrollView(container, "mContent", 5);
	self:registerPacket(ParentContainer)

	self:getActivityInfo()

	WeekCardCfg = ConfigManager.getWeekCardCfg()

	return self.container
end

	

--点击物品显示tips
function WeekCardPage:onClickItemFrame(container,eventName)
    local rewardIndex = tonumber(eventName:sub(8))--数字
    local nodeIndex  = rewardIndex;
    local itemInfo = nil;
    if rewardIndex > 3 then
        rewardIndex = rewardIndex-3;
        itemInfo = WeekCardCfg[30]
    else
        itemInfo = tGiftInfo.itemInfo
    end
    if not itemInfo then return end
    local rewardItems = {}
    if itemInfo.giftpack ~= nil then
        for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type 	= tonumber(_type),
                itemId	= tonumber(_id),
                count 	= tonumber(_count)
            });
        end
    end
    GameUtil:showTip(container:getVarNode('mPic' .. nodeIndex), rewardItems[rewardIndex])
end

--领取月卡
function WeekCardPage:onReceive(container)
    if tWeekCardInfo.isWeekCardUser then
    	--领取月卡
    	common:sendEmptyPacket( HP_pb.WeekCARD_AWARD_C , true )
    else
    --内购购买月卡
        WeekCardPage:buyGoods(container,30);
    end
end

function WeekCardPage:onExecute(ParentContainer)

end


function WeekCardPage:getActivityInfo()
    common:sendEmptyPacket( HP_pb.NEW_WEEK_CARD_INFO_C , true )
end

function WeekCardPage:clearAndReBuildAllItem(container)
    mWeekContainerRef = {}
    container.mScrollView:removeAllCell()
    for i,v in ipairs(WeekContent.weekList) do
        local titleCell = CCBFileCell:create()
        local panel = WeekContent:new({id = i})
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(WeekContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
end

function WeekCardPage:sortGiftOrder(tablename)--排序
    --增加显示顺序字段，可领取时显示顺序提到最前，多个可领取时再根据顺序排序，已领取时显示顺序放到最后，
    --多个已领取时再根据顺序排序，放到最后的逻辑在领取时即时生效即可
    local function sortfunction (left, right)
        if left.activateFlag ~= right.activateFlag then
            if left.activateFlag and left.isTodayTakeAward == false then
                return true
            elseif left.activateFlag and left.isTodayTakeAward then
                return false
            elseif right.activateFlag and right.isTodayTakeAward == false then
                return false
            elseif right.activateFlag and right.isTodayTakeAward then
                return true
            end
        end
        if left.isTodayTakeAward ~= right.isTodayTakeAward then
            if left.isTodayTakeAward then
                return false
            else
                return true
            end
        end
        return  WeekCardCfg[left.weekCardId].index <  WeekCardCfg[right.weekCardId].index
    end
    table.sort( tablename, sortfunction )
end

function WeekCardPage:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode();
	local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == HP_pb.NEW_WEEK_CARD_INFO_S then
		local msg = Activity2_pb.HPGetNewWeekCardInfo()
		msg:ParseFromString(msgBuff)
        WeekContent.weekList = {}
        for i = 1, #msg.newWeekCardInfoList do
            WeekContent.weekList[i] = msg.newWeekCardInfoList[i]
        end
        WeekCardPage:sortGiftOrder(WeekContent.weekList);
        self:clearAndReBuildAllItem(self.container)
		return
	end
    if opcode == HP_pb.NEW_WEEK_CARD_GET_AWARD_S then
		local msg = Activity2_pb.NewWeekCard()
		msg:ParseFromString(msgBuff)
        for i,v in ipairs(WeekContent.weekList) do
            if v.weekCardId == msg.weekCardId then
                WeekContent.weekList[i] = msg
                break
            end
        end
        WeekCardPage:sortGiftOrder(WeekContent.weekList);
        self:clearAndReBuildAllItem(self.container)
        -- NodeHelper:setMenuItemEnabled(mWeekContainerRef[msg.weekCardId],"mBtn",false)
        -- NodeHelper:setStringForLabel(mWeekContainerRef[msg.weekCardId],{mBtnTxt = common:getLanguageString('@AlreadyReceive')});
		--红点消除
        local hasNotice = false
        for i,v in ipairs(WeekContent.weekList) do
            if v.activateFlag and not v.isTodayTakeAward then
                hasNotice = true
                break
            end
        end
        if not hasNotice then
            ActivityInfo.changeActivityNotice(Const_pb.NEW_WEEK_CARD);
        end
        return
	end
end
function WeekCardPage:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function WeekCardPage:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

-- function WeekCardPage:onReceiveMessage(ParentContainer)
--     local message = ParentContainer:getMessage();
--     local typeId = message:getTypeId();
--     if typeId == MSG_MAINFRAME_REFRESH then --
--         local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
--         if pageName == thisPageName then

--         end
--     end    
-- end

function WeekCardPage:onExit(ParentContainer)
	self:removePacket(ParentContainer)
    mWeekContainerRef = {}
    WeekContent.curOffset = nil
    self.container.mScrollView:removeAllCell()
    onUnload(thisPageName, self.container)    
end

return WeekCardPage
