local thisPageName = "ActTimeLimit_150Gift"
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity4_pb")
local HP_pb = require("HP_pb")
local Recharge_pb = require("Recharge_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb")
local ConfigManager = require("ConfigManager")
local UserItemManager = require("Item.UserItemManager")
local MissionManager = require("MissionManager")
local NewPlayerBasePage = require("NewPlayerBasePage")
local CONST = require("Battle.NewBattleConst")
require("Activity.ActivityInfo")

local ActTimeLimit_150Gift = {
    container = nil,
}
--活動相關參數
local GIFT_PARAS = {
    ITEM_NUM = 4,
    GIFT_ID = 151,
    BG_SPINE_PATH = "Spine/Activity_143_sp_boxes",
    BG_SPINE_NAME = "Activity_143_sp_boxes",
    SHOW_ROLE_ID = 11,
}
-- 協定相關參數
local REQUEST_TYPE = {
    SHOP_ITEM = 0,
    DISCOUNT_GIFT = 1,
}
-- 遊戲狀態參數
local GAME_STATE = {
    ERROR = -1,
    SYNC_DATA = 0,
    STABLE = 1,
    REQUEST_REWARD = 2,
}
-- 購買狀態
local GIFT_STATUS =
{
    ALREADY_RECEIVE = 0, -- 已購買, 已領取
    CAN_BUY = 1, -- 可購買
    CAN_RECEIVE = 2, -- 可領取
}
-- 玩家當前遊戲資料
local nowData = {
    giftInfo = nil, -- 禮包資料
    shopItems = nil,-- 商品資訊
}

local option = {
    ccbiFile = "NewPlayer_gift.ccbi",
    handlerMap = {
        onClaim = "onClaim",
        onHelp = "onHelp",
        onHand = "onHand",
    },
    opcodes = {
        FETCH_SHOP_LIST_C = HP_pb.FETCH_SHOP_LIST_C,
        FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
        DISCOUNT_GIFT_INFO_C = HP_pb.DISCOUNT_GIFT_INFO_C,
        DISCOUNT_GIFT_INFO_S = HP_pb.DISCOUNT_GIFT_INFO_S,
        DISCOUNT_GIFT_BUY_SUCC_S = HP_pb.DISCOUNT_GIFT_BUY_SUCC_S,
        DISCOUNT_GIFT_GET_REWARD_C = HP_pb.DISCOUNT_GIFT_GET_REWARD_C,
        DISCOUNT_GIFT_GET_REWARD_S = HP_pb.DISCOUNT_GIFT_GET_REWARD_S, 
    }
}

local giftCfg = ConfigManager.getRechargeDiscountCfg()
local nowState = GAME_STATE.SYNC_DATA
local items = { }
-------------------- reward item --------------------------------
local Item = {
    ccbiFile = "BackpackItem.ccbi",
}
function Item:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh()
end

function Item:refresh()
    if not self.container then
        return
    end
    local reward = self.reward
    if reward then
        self.container:setVisible(true) 
        local rewardType, rewardId, rewardCount = unpack(common:split(reward, "_"))
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(rewardType), tonumber(rewardId), tonumber(rewardCount))
        local iconBgSprite = NodeHelper:getImageBgByQuality(resInfo.quality)
        NodeHelper:setSpriteImage(self.container, { mPic1 = resInfo.icon, mFrameShade1 = iconBgSprite })
        NodeHelper:setQualityFrames(self.container, { mHand1 = resInfo.quality })

        NodeHelper:setStringForLabel(self.container, { mNumber1_1 = rewardCount, mName1 = "", mNumber1 = "", mEquipLv = "" })
        NodeHelper:setNodesVisible(self.container, { mShader = false, mMask = false })

        for star = 1, 6 do
            NodeHelper:setNodesVisible(self.container, { ["mStar" .. star] = (star == resInfo.quality) and (tonumber(rewardType) == Const_pb.EQUIP * 10000) })
        end
    else
        self.container:setVisible(false) 
    end
end

function Item:onHand1(ccbRoot)
    if self.reward then
        local itemType, id, itemCount = unpack(common:split(self.reward, "_"))
        GameUtil:showTip(self.container:getVarNode("mAni1"), { type = tonumber(itemType), itemId = tonumber(id), count = tonumber(itemCount) })
    end
end
-----------------------------------------------------------------
function ActTimeLimit_150Gift:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function ActTimeLimit_150Gift:onEnter(container)
    if not self.container or tolua.isnull(self.container) then
        self.container = ScriptContentBase:create(option.ccbiFile)
    end
    self.container:registerFunctionHandler(ActTimeLimit_150Gift.onFunction)
    NodeHelper:setNodesVisible(self.container, { mInfoNode = false })
    self:setGameState(container, GAME_STATE.SYNC_DATA)
    self:registerPacket(container)
    self:initRewardItem(self.container)
    self:initSpine(self.container)
    self:requestServerData(REQUEST_TYPE.SHOP_ITEM)
    return self.container
end

function ActTimeLimit_150Gift:onExit(container)
    self:removePacket(container)
end
------------------------------------- 按鈕 ---------------------------------------------
-- 購買/領獎按鈕
function ActTimeLimit_150Gift:onClaim(container)
    if nowState ~= GAME_STATE.STABLE then
        return
    end
    if nowData.giftInfo.status == GIFT_STATUS.CAN_BUY then  -- 購買
        self:buyGoods(GIFT_PARAS.GIFT_ID)
    elseif nowData.giftInfo.status == GIFT_STATUS.CAN_RECEIVE then  -- 領獎
        local msg = Activity2_pb.HPDiscountGetRewardReq()
        msg.goodsId = GIFT_PARAS.GIFT_ID
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.DISCOUNT_GIFT_GET_REWARD_C, pb, #pb, true)
    end
end
-- 規則說明
function ActTimeLimit_150Gift:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_THREEQUEST)
end
-- 角色點擊
function ActTimeLimit_150Gift:onHand(container)
    local rolePage = require("NgArchivePage")
    PageManager.pushPage("NgArchivePage")
    rolePage:setMercenaryId(GIFT_PARAS.SHOW_ROLE_ID)
    --NgArchivePage_setToSkin(true, 2)
end
----------------------------------------------------------------------------------
function ActTimeLimit_150Gift:onExecute(container)
    local remainTime = NewPlayerBasePage:getActivityTime()
    local timeStr = common:second2DateString5(remainTime, false)
    NodeHelper:setStringForLabel(self.container, { mTimerTxt = timeStr })
end
----------------------------------------------------------------------------------
-- 獎勵ccb初始化
function ActTimeLimit_150Gift:initRewardItem(container)
    self.mScrollView = container:getVarScrollView("mContent")
    self.mScrollView:setTouchEnabled(false)
    self.mScrollView:removeAllCell()
    items = { }
    for i = 1, GIFT_PARAS.ITEM_NUM do
        local cell = CCBFileCell:create()
        cell:setCCBFile(Item.ccbiFile)
        local handler = common:new( { id = i, reward = nil }, Item)
        cell:registerFunctionHandler(handler)
        cell:setContentSize(CCSize(86, 86))
        cell:setScale(0.63)
        self.mScrollView:addCell(cell)
        items[i] = { cls = handler, node = cell }
    end
    self.mScrollView:orderCCBFileCells()
end
-- spine初始化
function ActTimeLimit_150Gift:initSpine(container)
    local heroCfg = ConfigManager.getNewHeroCfg()[GIFT_PARAS.SHOW_ROLE_ID]
    if heroCfg then
        local parentNode = container:getVarNode("mSpineNode")
        parentNode:removeAllChildrenWithCleanup(true)
        local spineFolder, spineName = unpack(common:split(heroCfg.Spine, ","))
        if not NodeHelper:isFileExist(spineFolder .. "/" .. spineName .. string.format("%03d", GIFT_PARAS.SHOW_ROLE_ID) .. ".skel") then
            return
        end
        local spine = SpineContainer:create(spineFolder, spineName .. string.format("%03d", GIFT_PARAS.SHOW_ROLE_ID))
        local spineNode = tolua.cast(spine, "CCNode")
        spine:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
        parentNode:addChild(spineNode)
    end
    -- BG
    local bg = self.container:getVarNode("mBg")
    local spineBg = SpineContainer:create("NG2D", "NG2D_" .. string.format("%02d", GIFT_PARAS.SHOW_ROLE_ID) .. string.format("%03d", GIFT_PARAS.SHOW_ROLE_ID))
    local spineNodeBg = tolua.cast(spineBg, "CCNode")
    spineNodeBg:setScale(NodeHelper:getScaleProportion())
    spineBg:runAnimation(1, "animation", -1)
    bg:addChild(spineNodeBg)
end
-- 同步資料
function ActTimeLimit_150Gift:syncServerData(msg)
    nowData.giftInfo = nil
    if msg.info[1] then
        GIFT_PARAS.GIFT_ID = msg.info[1].goodsId
        nowData.giftInfo = msg.info[1]
        if giftCfg[GIFT_PARAS.GIFT_ID] then
            local rewards = common:split(giftCfg[GIFT_PARAS.GIFT_ID].salepacket, ",")
            for j = 1, #items do
                items[j].cls.reward = rewards[j]
            end
        end
    end
end
function ActTimeLimit_150Gift:syncShopItem(msg)
    nowData.shopItems = { }
    for i = 1, #msg.shopItems do
        table.insert(nowData.shopItems, msg.shopItems[i].productId, msg.shopItems[i])
        --nowData.shopItems[msg.shopItems[i].productId] = msg.shopItems[i]
    end
end
-- 設定狀態
function ActTimeLimit_150Gift:setGameState(container, state)
    nowState = state
end
-- 刷新獎勵顯示
function ActTimeLimit_150Gift:refreshItem(container)
    for i = 1, #items do
        items[i].cls:refresh()
    end
end
-- 刷新介面顯示
function ActTimeLimit_150Gift:refreshUI(container)
    NodeHelper:setNodesVisible(self.container, { mInfoNode = true })
    local txt = self.container:getVarLabelTTF("mTxt1")
    txt:setHorizontalAlignment(kCCTextAlignmentCenter)
    if nowData.giftInfo.status == GIFT_STATUS.ALREADY_RECEIVE then
        NodeHelper:setMenuItemEnabled(container, "mClaimBtn", false)
        NodeHelper:setStringForLabel(container, { mClaimTxt = common:getLanguageString("@AlreadyReceive") })
    elseif nowData.giftInfo.status == GIFT_STATUS.CAN_BUY then
        local price = GameUtil:CNYToPlatformPrice(giftCfg[GIFT_PARAS.GIFT_ID].formerPrice, "H365")
        NodeHelper:setMenuItemEnabled(container, "mClaimBtn", true)
        NodeHelper:setStringForLabel(container, { mClaimTxt = price })
    elseif nowData.giftInfo.status == GIFT_STATUS.CAN_RECEIVE then
        NodeHelper:setMenuItemEnabled(container, "mClaimBtn", true)
        NodeHelper:setStringForLabel(container, { mClaimTxt = common:getLanguageString("@CanReceive") })
    end
end
-- 購買商品
function ActTimeLimit_150Gift:buyGoods(id)
    local itemInfo = nowData.shopItems[id]--giftCfg[id]
    if itemInfo == nil then return end

    local buyInfo = BUYINFO:new()
    buyInfo.productType = itemInfo.productType;
    buyInfo.name = itemInfo.name;
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
    local _ratio = tostring(itemInfo.ratio)
    local extrasTable = { productType = _type, name = itemInfo.name, ratio = _ratio }
    buyInfo.extras = json.encode(extrasTable)

    local BuyManager = require("BuyManager")
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end
----------------------------------------------------------------------------------

-------------------------------------協定相關--------------------------------------
function ActTimeLimit_150Gift:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.DISCOUNT_GIFT_INFO_S then
        local msg = Activity2_pb.HPDiscountInfoRet()
        msg:ParseFromString(msgBuff)
        self:setGameState(container, GAME_STATE.STABLE)
        self:syncServerData(msg)
        self:refreshItem(container)
        self:refreshUI(self.container)
    elseif opcode == HP_pb.FETCH_SHOP_LIST_S then
        local msg = Recharge_pb.HPShopListSync()
        msg:ParseFromString(msgBuff)
        --RechargeCfg = msg.shopItems
        --CCLuaLog("Recharge ShopItemNum :" .. #msg.shopItems)
        self:syncShopItem(msg)
        self:requestServerData(REQUEST_TYPE.DISCOUNT_GIFT)
    elseif opcode == HP_pb.DISCOUNT_GIFT_BUY_SUCC_S then
        local msg = Activity2_pb.HPDiscountBuySuccRet()
        msg:ParseFromString(msgBuff)
        if msg.goodsId == nowData.giftInfo.goodsId then
            nowData.giftInfo.status = GIFT_STATUS.CAN_RECEIVE
        end
        self:setGameState(container, GAME_STATE.STABLE)
        self:refreshItem(container)
        self:refreshUI(self.container)
    elseif opcode == HP_pb.DISCOUNT_GIFT_GET_REWARD_S then
        local msg = Activity2_pb.HPDiscountGetRewardRes()
        msg:ParseFromString(msgBuff)
        if msg.goodsId == nowData.giftInfo.goodsId then
            nowData.giftInfo.status = GIFT_STATUS.ALREADY_RECEIVE
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            local rewards = common:split(giftCfg[nowData.giftInfo.goodsId].salepacket, ",")
            local parseReward = { }
            for i = 1, #rewards do
                table.insert(parseReward, ConfigManager.parseItemOnlyWithUnderline(rewards[i]))
            end
            CommonRewardPage:setData(parseReward, common:getLanguageString("@ItemObtainded"), nil)
            PageManager.pushPage("CommPop.CommItemReceivePage")
        end
        self:setGameState(container, GAME_STATE.STABLE)
        self:refreshItem(container)
        self:refreshUI(self.container)
    end
end
function ActTimeLimit_150Gift:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function ActTimeLimit_150Gift:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function ActTimeLimit_150Gift:requestServerData(type)
    if type == REQUEST_TYPE.SHOP_ITEM then
       --local msg = Recharge_pb.HPFetchShopList()
       --msg.platform = libPlatformManager:getPlatform():getClientChannel()
       --if Golb_Platform_Info.is_win32_platform then
       --    msg.platform = GameConfig.win32Platform
       --end
       --pb_data = msg:SerializeToString()
       --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, false)
    elseif type == REQUEST_TYPE.DISCOUNT_GIFT then
        local msg = Activity2_pb.DiscountInfoReq()
        msg.actId = Const_pb.ACTIVITY150_LIMIT_GIFT
        common:sendPacket(HP_pb.DISCOUNT_GIFT_INFO_C, msg, true)
    end
end

function ActTimeLimit_150Gift.onFunction(eventName, container)
    if eventName == option.handlerMap.onClaim then
        ActTimeLimit_150Gift:onClaim(container)
    elseif eventName == option.handlerMap.onHelp then
        ActTimeLimit_150Gift:onHelp(container)
    elseif eventName == option.handlerMap.onHand then
        ActTimeLimit_150Gift:onHand(container)
    end
end
----------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local ActPage = CommonPage.newSub(ActTimeLimit_150Gift, thisPageName, option)

return ActTimeLimit_150Gift