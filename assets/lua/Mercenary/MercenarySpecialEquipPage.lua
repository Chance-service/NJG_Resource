

local HP_pb = require("HP_pb") -- 包含协议id文件
local EquipManager = require("EquipManager")
local SuitShowManage = require("Battle.MultiEliteSuitShowManage")
local curItemData = nil -- 当前物品数据
local curCount = 1 -- 当前数量
local mMultiple = 1
----这里是协议的id
local opcodes = {
    DO_EXCHANGE_C = HP_pb.DO_EXCHANGE_C,
    DO_EXCHANGE_S = HP_pb.DO_EXCHANGE_S,
}

local EquipItemContent = {

    ccbiFile = "GoodsItem_2.ccbi"
};

local option = {
    ccbiFile = "MercenarySpecialEquip.ccbi",
    handlerMap =
    {
        onClose = "onNo",
        onConfirmation = "onYes",
        onAdd = "onIncrease",
        onAddTen = "onIncreaseTen",
        onReduction = "onDecrease",
        onReductionTen = "onDecreaseTen",
    }
}
local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "MercenarySpecialEquipPage";
local CommonPage = require("CommonPage");
local MultiEliteDataManger = require("Battle.MultiEliteDataManger")


local mItemSelfCount = 0
local resId = 0;
local maxCount = 99;
local priceGetter = nil;
local curCount = 1;
local resEnough = true;
local errorMessage = "@NotEnoughDuanZaoStone"
local ExchangeActivityCfg = { }
local MercenaryCfg = { }
local ExchangeActivityItemId = { }-- 道具类型

local NodeHelper = require("NodeHelper");
local MercenarySpecialEquipPage = { }
local mPropItemId = 299993
local fetterId = 0;
local data = nil;
local suitInfo = { }
local mRoldData = { }
----------------------------------------------------------------------------------
-- CountTimesWithIconPage页面中的事件处理
----------------------------------------------
function MercenarySpecialEquipPage:onEnter(container)
    local UserItemManager = require("Item.UserItemManager")
    curCount = 1
    container.mScrollView = container:getVarScrollView("mContent")
    mItemSelfCount = UserItemManager:getCountByItemId(mPropItemId)

    container.mScrollView:setTouchEnabled(false)
    self:getPageInfo()
    self:addEquipItem(container)
    self:registerPacket(container)
    self:refreshPage(container);

    -- container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
end

function MercenarySpecialEquipPage:onExecute(container)

end

function EquipItemContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end
function EquipItemContent:onHand(content)
    local id = self.id
    if fetterId == 0 then
        fetterId = FetterManager.getViewFetterId()
        data = FetterManager.getIllCfgById(fetterId)
        if data then
            suitInfo = EquipManager:getMercenaryAllSuitByMercenaryId(data.roleId)
        end
    end

    local suitInfoTmp = { }
    suitInfoTmp = suitInfo[id]

    local equipID = suitInfoTmp["equipId"]

    -- PageManager.viewEquipInfo(equipID,true)
    SuitShowManage.EquipId = tonumber(equipID)
    PageManager.pushPage("MultiEliteSuitShowDetailPage")
    -- PageManager.showEquipInfo(equipID,0,false);
end
function EquipItemContent:onRefreshContent(ccbRoot)
    local id = self.id
    if fetterId == 0 then
        fetterId = FetterManager.getViewFetterId()
        data = FetterManager.getIllCfgById(fetterId)
        if data then
            suitInfo = EquipManager:getMercenaryAllSuitByMercenaryId(data.roleId)
        end
    end

    local suitInfoTmp = { }
    suitInfoTmp = suitInfo[id]

    local container = ccbRoot:getCCBFileNode()
    local equipId = suitInfoTmp["equipId"]
    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }
    local colorMap = { }
    local quality = EquipManager:getQualityById(equipId)
    -- 品质

    sprite2Img = {
        mPic = EquipManager:getIconById(equipId),
        -- icon
        mFrameShade = NodeHelper:getImageBgByQuality(quality)
    }
    lb2Str = {
        mLv = common:getLanguageString("@MyLevel",EquipManager:getLevelById(equipId))
    }

    colorMap = {
        mLv = ConfigManager.getQualityColor()[quality].textColor
    }

    menu2Quality = { mHand = quality }

    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setColorForLabel(container, colorMap)
end
function MercenarySpecialEquipPage.onUnLoad(container)
    CCLuaLog("Z#:MercenarySpecialEquipPage.onUnLoad!");
end

function MercenarySpecialEquipPage:addEquipItem(container)

    container.mScrollView:removeAllCell()

    fetterId = FetterManager.getViewFetterId()
    data = FetterManager.getIllCfgById(fetterId)
    if data then
        -- local roleData = ConfigManager.getRoleCfg()[data.roleId]
        -- local list = FetterManager.getAllRelationByFetterId(fetterId)
        suitInfo = EquipManager:getMercenaryOnlySuitByMercenaryId(data.roleId)
        if #suitInfo >= 1 then

            table.sort(suitInfo, function(info1, info2)
                local equip_1 = ConfigManager.getEquipCfg()[info1.equipId]
                local equip_2 = ConfigManager.getEquipCfg()[info2.equipId]
                return tonumber(equip_1.level) < tonumber(equip_2.level)
            end )

            NodeHelper:buildCellScrollView(container.mScrollView, #suitInfo, EquipItemContent.ccbiFile, EquipItemContent)
            container.mScrollView:setBounceable(true)
            local children = container.mScrollView:getChildren()
            if children then
                for i = 1, children:count(), 1 do
                    if children:objectAtIndex(i - 1) then
                        local node = tolua.cast(children:objectAtIndex(i - 1), "CCNode")
                        fOneItemWidth = node:getContentSize().width /(#suitInfo)
                    end
                end
            end
        end
    end
end

-- 构建标签页
function MercenarySpecialEquipPage:buildScrollView(container)
    NodeHelper:buildCellScrollView(container.mScrollView, #_mercenaryInfos.roleInfos, mercenaryHeadContent.ccbiFile, mercenaryHeadContent)
    if _curSelectId ~= 0 then
        local index = 1
        for i, v in ipairs(_mercenaryInfos.roleInfos) do
            if v.roleId == _curSelectId then
                index = i
                break
            end
        end
        container.mScrollView:locateToByIndex(index - 1)
    end

    local children = container.mScrollView:getChildren()
    if children then
        for i = 1, children:count(), 1 do
            if children:objectAtIndex(i - 1) then
                local node = tolua.cast(children:objectAtIndex(i - 1), "CCNode")
                fOneItemWidth = node:getContentSize().width /(#(_mercenaryInfos.roleInfos))
            end
        end
    end
end
-- 标签页
function MercenarySpecialEquipPage:onExit(container)
    self:removePacket(container)
end

function MercenarySpecialEquipPage:onNo(container)
    PageManager.popPage(thisPageName)
end

function MercenarySpecialEquipPage:refreshPage(container)
    local sprite2Img = { }
    local scaleMap = { }
    if fetterId == 0 then
        fetterId = FetterManager.getViewFetterId()
        data = FetterManager.getIllCfgById(fetterId)
        if data then
            suitInfo = EquipManager:getMercenaryAllSuitByMercenaryId(data.roleId)
        end
    end
    local suitInfoTmp = { }
    if #suitInfo > 0 then
        suitInfoTmp = suitInfo[1]
    end

    local illInfo = FetterManager.getIllCfgById(fetterId)
    mRoldData = ConfigManager.getRoleCfg()[illInfo.roleId]

    -- 得到装备碎片的品质
    local fragmentItemId = ConfigManager.getEquipCfg()[suitInfoTmp["equipId"]].fixedMaterial[1].itemId
    local fragmentQuality = ConfigManager.getItemCfg()[fragmentItemId].quality
    sprite2Img = {
        mEquipPic = EquipManager:getIconById(suitInfoTmp["equipId"]),
        mRolePic = mRoldData.icon,
        mItemQualityBg = NodeHelper:getImageBgByQuality(ConfigManager.getItemCfg()[mPropItemId].quality),
    }
    name = common:getLanguageString("@ExchangeExclusiveTxt", illInfo.name)

    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)


    NodeHelper:setQualityFrames(container, { mEquipQuality = fragmentQuality })

    NodeHelper:setStringForLabel(container, {
        mCostGoldLab = common:getLanguageString("@SuitGetLab"),
        mTitle = common:getLanguageString("@SuitPatchNumberTitle"),
        mDecisionTex = name,
        mAddNum = curCount,
        mItemSelfNum = mItemSelfCount,
        mFinalNum = curCount * 2
    } )

    local colorMap = {
        -- mItemNum = ConfigManager.getQualityColor()[ConfigManager.getItemCfg()[mPropItemId].quality].textColor,
        -- mEuipNum =
    }
    NodeHelper:setColorForLabel(container, colorMap)

    local titleNode = container:getVarNode("mTitle")
    titleNode:setScale(0.8)
end

-- 收包
function MercenarySpecialEquipPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.DO_EXCHANGE_S then
        local UserItemManager = require("Item.UserItemManager")
        mItemSelfCount = UserItemManager:getCountByItemId(mPropItemId)
        NodeHelper:setStringForLabel(container, { mItemSelfNum = mItemSelfCount })
        return
    end
end

function MercenarySpecialEquipPage:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then
        -- 这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;
    end
end

function MercenarySpecialEquipPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function MercenarySpecialEquipPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

function MercenarySpecialEquipPage:refreshCountAndPrice(container, num)
    if curCount > maxCount then
        curCount = maxCount
    end
    resEnough = true
    if curCount * 2 > mItemSelfCount then
        resEnough = false
        local tmp2 = 0
        if num == 10 then
            curCount, tmp2 = math.modf(mItemSelfCount / 2)
        else
            curCount = curCount - num
        end
        mFinalNum = curCount * 2
        errorMessage = "@resNotEnough"
        if not resEnough then
            resEnough = true
            MessageBoxPage:Msg_Box_Lan(errorMessage)
        end
    end

    NodeHelper:setStringForLabel(container, { mAddNum = curCount })
    NodeHelper:setStringForLabel(container, { mFinalNum = curCount * 2 })
end

-- 套装碎片兑换
function MercenarySpecialEquipPage:toPurchaseItems(itemId, count)
    --    local MultiElite_pb = require("MultiElite_pb")
    -- local message = MultiElite_pb.HPMultiEliteShopBuy()
    -- if message~=nil then
    -- 	message.amount = count;
    --        message.buyId = itemId
    -- 	local pb_data = message:SerializeToString();
    -- 	PacketManager:getInstance():sendPakcet(HP_pb.MULTIELITE_SHOP_BUY_C,pb_data,#pb_data,true);
    -- end
end

function MercenarySpecialEquipPage:getWeaponId(roleId)
    local id = 0
    local t = ExchangeActivityCfg["type_" .. mPropItemId]
    for i = 1, #t do
        if t[i].roleId == roleId then
            id = t[i].id
            break
        end
    end
    return id
end

function MercenarySpecialEquipPage:onYes(container)
    if curCount > 0 then
        if mItemSelfCount > curCount then
            local Activity2_pb = require("Activity2_pb")
            local msg = Activity2_pb.DoExchange()
            msg.exchangeId = tostring(self:getWeaponId(mRoldData.id))
            msg.exchangeTimes = curCount
            common:sendPacket(opcodes.DO_EXCHANGE_C, msg, false)
        else
            MessageBoxPage:Msg_Box_Lan(errorMessage)
        end
    end
end	

function MercenarySpecialEquipPage:getPageInfo()
    ExchangeActivityCfg = { }
    ExchangeActivityCfg.cfg = ConfigManager.getExchangeActivityItem()
    MercenaryCfg = ConfigManager.getRoleCfg()
    ExchangeActivityItemId = { }
    -- 道具类型

    for k, v in pairs(ExchangeActivityCfg.cfg) do
        local itemInfo = v
        local consumeCfg = self:splitTiem(itemInfo.consumeInfo)[1]
        if ExchangeActivityCfg["type_" .. consumeCfg.itemId] == nil then
            ExchangeActivityCfg["type_" .. consumeCfg.itemId] = { }
            table.insert(ExchangeActivityItemId, consumeCfg.itemId);
        end
        table.insert(ExchangeActivityCfg["type_" .. consumeCfg.itemId], itemInfo);
    end


    --    for i = 1, #ExchangeActivityCfg.cfg do
    --        local itemInfo = ExchangeActivityCfg.cfg[i]
    --        local consumeCfg = self:splitTiem(itemInfo.consumeInfo)[1]
    --        if ExchangeActivityCfg["type_" .. consumeCfg.itemId] == nil then
    --            ExchangeActivityCfg["type_" .. consumeCfg.itemId] = { }
    --            table.insert(ExchangeActivityItemId, consumeCfg.itemId);
    --        end
    --        table.insert(ExchangeActivityCfg["type_" .. consumeCfg.itemId], itemInfo);
    --    end
end

function MercenarySpecialEquipPage:splitTiem(itemInfo)
    local items = { }
    for _, item in ipairs(common:split(itemInfo, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"));

        table.insert(items, {
            type = tonumber(_type),
            itemId = tonumber(_id),
            count = tonumber(_count)
        } );
    end
    return items;
end


function MercenarySpecialEquipPage:onIncrease(container)
    if curCount > 0 then
        if curCount == maxCount then
            -- MessageBoxPage:Msg_Box_Lan("@NoGemBuyCount")
            MessageBoxPage:Msg_Box_Lan("@ERRORCODE_155")
            curCount = maxCount
        else
            curCount = curCount + 1
        end
        self:refreshCountAndPrice(container, 1)

        --        if  not resEnough then
        -- 	    MessageBoxPage:Msg_Box_Lan(errorMessage)
        --        end
    end
end


function MercenarySpecialEquipPage:onDecrease(container)
    if curCount <= 1 then
        return
    end
    curCount = curCount - 1
    self:refreshCountAndPrice(container, -1)
end


function MercenarySpecialEquipPage:onIncreaseTen(container)
    if curCount > 0 then
        if curCount >(maxCount - 10) then
            -- MessageBoxPage:Msg_Box_Lan("@NoGemBuyCount")
            MessageBoxPage:Msg_Box_Lan("@ERRORCODE_155")
            curCount = maxCount
        else
            curCount = curCount + 10
        end
        self:refreshCountAndPrice(container, 10)
        --        if  not resEnough then
        -- 	    MessageBoxPage:Msg_Box_Lan(errorMessage)
        --        end
    end
end


function MercenarySpecialEquipPage:onDecreaseTen(container)
    if curCount < 10 then
        curCount = 1
    else
        curCount = curCount - 10
    end
    self:refreshCountAndPrice(container, -10)
end



function MercenarySpecialEquipPage:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_MAINFRAME_PUSHPAGE then
        local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            self:refreshPage(container);
        end
    end
end
-------------------------------------------------------------------------------

function MercenarySpecialEquipPage_ItemData(itemData)
    curItemData = itemData
end

local CommonPage = require('CommonPage')
MercenarySpecialEquipPage = CommonPage.newSub(MercenarySpecialEquipPage, thisPageName, option)

return MercenarySpecialEquipPage

