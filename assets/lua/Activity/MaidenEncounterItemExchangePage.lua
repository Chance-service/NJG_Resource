
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper");
local Const_pb      = require("Const_pb");
local UserItemManager = require("Item.UserItemManager");
local thisPageName = "MaidenEncounterItemExchangePage"
local ExchangeListCfg = {}  --兑换配置列表
local SaveServerData = {}  --兑换配置列表
local ITEM_COUNT_PER_LINE = 5
local SelctIndex = 0 --选择的index

local MaidenEncounterItemExchangeBase = {}
local option = {
    ccbiFile = "Act_TimeLimitGirlsMeetScoreContent.ccbi",
    handlerMap = { --按钮点击事件
        onClose     = "onClose",
        onHelp     = "onHelp"
    }
}

local MaidenEncounterExchangeContent = 
{
    ccbiFile = "Act_TimeLimitGirlsMeetScoreListContent.ccbi"
}

local opcodes = {
    SYNC_MAIDEN_ENCOUNTER_EXCHANGE_C = HP_pb.SYNC_MAIDEN_ENCOUNTER_EXCHANGE_C,
    SYNC_MAIDEN_ENCOUNTER_EXCHANGE_S = HP_pb.SYNC_MAIDEN_ENCOUNTER_EXCHANGE_S,
    MAIDEN_ENCOUNTER_EXCHANGE_C = HP_pb.MAIDEN_ENCOUNTER_EXCHANGE_C,
};
-----------------MaidenEncounterExchangeContent-----------------------------

function MaidenEncounterExchangeContent:onReceive(container)
    SelctIndex = self.id
    local ItemInfo = ExchangeListCfg[SelctIndex]
    local multiple = 0
    local haveNum = UserItemManager:getCountByItemId(ItemInfo.consumeItems[1].itemId);
    local max = math.floor( haveNum / ItemInfo.consumeItems[1].count );--取最多能兑换几个
    for j = 1, #ItemInfo.consumeItems do
        haveNum = UserItemManager:getCountByItemId(ItemInfo.consumeItems[j].itemId);
        if haveNum == nil then haveNum = 0 end
        multiple = math.floor( haveNum / ItemInfo.consumeItems[j].count )
        if multiple < max then --取最小能兑换的个数
            max = multiple;
        end
    end
    MaidenEncounterItemExchangeBase:onBuyTimes(container,max)
end

function MaidenEncounterExchangeContent:onFeet1(container)
    local index = self.id
    local ItemInfo = ExchangeListCfg[index];
    GameUtil:showTip(container:getVarNode("mRewardPic1"), ItemInfo.getItems[1])
end


function MaidenEncounterExchangeContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()  
    local index = self.id
    local ItemInfo = ExchangeListCfg[index];
    local isExchange = true;
    for i = 1, 4 do
        if i == (#ItemInfo.consumeItems) then
            NodeHelper:setNodeVisible(container:getVarNode("mScoreNode"..i),true);
            for j = 1, #ItemInfo.consumeItems do
                local resInfo = ResManagerForLua:getResInfoByTypeAndId(ItemInfo.consumeItems[j].type, ItemInfo.consumeItems[j].itemId, ItemInfo.consumeItems[j].count);
                NodeHelper:setStringForLabel(container,{["mScoreNum"..i..j] = "x"..ItemInfo.consumeItems[j].count});
                NodeHelper:setSpriteImage(container, {["mIcon"..i..j] = resInfo.icon});
                NodeHelper:setNodeScale(container, "mIcon"..i..j, 0.35, 0.35)
                local haveNum = UserItemManager:getCountByItemId(ItemInfo.consumeItems[j].itemId);
                if haveNum == nil or ItemInfo.consumeItems[j].count > haveNum then
                    NodeHelper:setMenuItemEnabled(container, "mReceive", false )
                    NodeHelper:setColorForLabel(container,{["mScoreNum"..i..j]=GameConfig.ColorMap.COLOR_RED})
                    isExchange = false;
                else
                    NodeHelper:setMenuItemEnabled(container, "mReceive", true )
                    NodeHelper:setColorForLabel(container,{["mScoreNum"..i..j]=GameConfig.ColorMap.COLOR_WHITE})
                end
            end
        else
            NodeHelper:setNodeVisible(container:getVarNode("mScoreNode"..i),false);
        end
    end
    local times = MaidenEncounterItemExchangeBase:getEveryDayTimes(ItemInfo.id);
    NodeHelper:setStringForLabel(container,{mLimitNum = times.."/"..ItemInfo.times});
    if times <= 0 or isExchange == false then--次数不足 或 数量不够
        NodeHelper:setMenuItemEnabled(container, "mReceive", false )
    end
    local lb2Str = {};
    local sprite2Img = {};
    local menu2Quality = {}
    local rewardResInfo = ResManagerForLua:getResInfoByTypeAndId(ItemInfo.getItems[1].type, ItemInfo.getItems[1].itemId, ItemInfo.getItems[1].count);
    sprite2Img["mRewardPic1"] = rewardResInfo.icon;
    sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(rewardResInfo.quality);
    lb2Str["mNum1"]           = "x" .. GameUtil:formatNumber( rewardResInfo.count );
    lb2Str["mName1"]          = rewardResInfo.name;
    menu2Quality["mFeet1"]    = rewardResInfo.quality
    if string.sub(rewardResInfo.icon, 1, 7) == "UI/Role" then 
        NodeHelper:setNodeScale(container, "mRewardPic1", 0.84, 0.84)
    else
        NodeHelper:setNodeScale(container, "mRewardPic1", 1, 1)
    end
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setQualityFrames(container, menu2Quality);
end

--判断每日次数时候足够
function MaidenEncounterItemExchangeBase:getEveryDayTimes(id)
    for i = 1, #SaveServerData do
        if SaveServerData[i].id == id then
            return SaveServerData[i].remainderTimes;
        end
    end
    return nil;
end

function MaidenEncounterItemExchangeBase:onEnter(container)
    self:getReadTxtInfo();
	NodeHelper:initScrollView(container, "mContent", ITEM_COUNT_PER_LINE);
    --获取佣兵列表信息
    NodeHelper:setStringForLabel(container, {mSuitPatchChooseInfo = common:getLanguageString("@MercenaryChipExplain")});
    self:registerPacket(container);
    common:sendEmptyPacket(opcodes.SYNC_MAIDEN_ENCOUNTER_EXCHANGE_C , true)
end


function MaidenEncounterItemExchangeBase:updateData(container,data)
    SaveServerData = {}
    SaveServerData = data
    self:changeItemInfo(container)
    self:buildItem(container)
end

--修改上面的道具信息
function MaidenEncounterItemExchangeBase:changeItemInfo(container)
    local maidenEncounter = ConfigManager.getMaidenEncountCfg()
    for i = 1,4 do
        local ItemInfo = maidenEncounter[i].exclusiveReward[1]
        local haveNum = UserItemManager:getCountByItemId(ItemInfo.itemId);
        if haveNum == nil then haveNum = 0 end
        NodeHelper:setStringForLabel(container, {["mScoreNum"..i] = haveNum});
    end
end

--读取配置文件信息
function MaidenEncounterItemExchangeBase:getReadTxtInfo()
    ExchangeListCfg = ConfigManager.getMaidenEncountExchangeCfg()
end

--接收服务器回包
function MaidenEncounterItemExchangeBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.SYNC_MAIDEN_ENCOUNTER_EXCHANGE_S then
        local msg = Activity2_pb.SyncMaidenEncounterExchangeRes();
		msg:ParseFromString(msgBuff);
        MaidenEncounterItemExchangeBase:updateData(container,msg.info);
    end
end

function MaidenEncounterItemExchangeBase:buildItem(container)
    container.mScrollView:removeAllCell()  ---这里是清空滚动层
    NodeHelper:buildCellScrollView(container.mScrollView, #ExchangeListCfg, MaidenEncounterExchangeContent.ccbiFile, MaidenEncounterExchangeContent) --
end

function MaidenEncounterItemExchangeBase:onExecute(container)

end

function MaidenEncounterItemExchangeBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function MaidenEncounterItemExchangeBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function MaidenEncounterItemExchangeBase:onExit(container)
    NodeHelper:deleteScrollView(container);
    -- self:removePacket();
    onUnload(thisPageName, container);
end

function MaidenEncounterItemExchangeBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function MaidenEncounterItemExchangeBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_RECHARGEREBATE)
end

function MaidenEncounterItemExchangeBase_onSelectCallback(flag,count)
    if flag then
        MaidenEncounterItemExchangeBase:requestServerData(count);
    end
end


function MaidenEncounterItemExchangeBase:requestServerData(count)
    local msg = Activity2_pb.MaidenEncounterExchangeReq();
    msg.id = ExchangeListCfg[SelctIndex].id;
    msg.multiple = count;
    common:sendPacket(opcodes.MAIDEN_ENCOUNTER_EXCHANGE_C, msg, false);
end

function MaidenEncounterItemExchangeBase:onBuyTimes(container,max)
    -- local max = 10 --999
    local title = common:getLanguageString("@ManyPeopleShopGiftTitle")
    local message = common:getLanguageString("@ManyPeopleShopGiftInfoTxt")
    local multiple = 1--倍数限制
    local isShow = false;--是否显示最下面一行

    PageManager.showCommonCountTimesPage(title,message,max,
        function(times)
            local totalTimes = 100*times
            return totalTimes
        end
    ,Const_pb.MONEY_GOLD, MaidenEncounterItemExchangeBase_onSelectCallback, nil, nil, "@ERRORCODE_3002", multiple, isShow)
end

local CommonPage = require('CommonPage')
local MaidenEncounterItemExchangePage = CommonPage.newSub(MaidenEncounterItemExchangeBase, thisPageName, option)