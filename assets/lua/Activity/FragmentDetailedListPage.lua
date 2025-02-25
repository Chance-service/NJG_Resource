
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper");
local Const_pb      = require("Const_pb")
local thisPageName = "FragmentDetailedListPage"
local alreadySelItems = {}  --已经选择了的碎片
local showItems = {} --显示兑换碎片列表
local ITEM_COUNT_PER_LINE = 5
local ITEM_COUNT_PER_LINE = 5
local CountCol = 0 --计算多少列
local CountRow = 0 --计算多少行
local ConstCountCol = 5 --总共5列
local AllRoleInfoTable = {} --所有佣兵碎片列表
local SaveFilterRoleFragment = {} --保存符合条件的佣兵碎片

local option = {
    ccbiFile = "SuitPatchDecompositionChoosePopUp.ccbi",
    handlerMap = { --按钮点击事件
        onClose     = "onClose",
    },
    opcodes = {
        ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
        ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    }
}

local HPRoleStage = {
    notActive = 0,--未激活
    alreadyActive = 1,--已激活
    canActive = 2 --可激活
}

local FragmentDetailedListPage = {}
function FragmentDetailedListPage:onEnter(container)
	self:setShowItems(container)

	NodeHelper:initScrollView(container, "mContent", ITEM_COUNT_PER_LINE);
    --获取佣兵列表信息
     self:registerPacket(container)
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    local showTips = ""
    if 1 == tonumber(alreadySelItems.type) then
        showTips = common:getLanguageString("@MercenaryChipExplain1");
    else
        showTips = common:getLanguageString("@MercenaryChipExplain2");
    end

    NodeHelper:setStringForLabel(container, {mTitle = common:getLanguageString("@MercenaryChipTitle"),
                                            mSuitPatchChooseInfo = showTips});
	-- self:buildItem(container)
end

function FragmentDetailedListPage:setShowItems(container)

end

function FragmentDetailedListPage:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function FragmentDetailedListPage:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

--接收服务器回包
function FragmentDetailedListPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
		msg:ParseFromString(msgBuff);
        AllRoleInfoTable = msg.roleInfos
        self:filterRoleInfo(container)
    elseif opcode == HP_pb.ROLE_EMPLOY_S then
		local msg = RoleOpr_pb.HPRoleEmploy();
        msg:ParseFromString(msgBuff);
        local roleId = msg.roleId
        local roleInfo = UserMercenaryManager:getUserMercenaryById(roleId)
		if roleInfo then
			local curMercenaryCfg = ConfigManager.getRoleCfg()[roleInfo.itemId]
			if curMercenaryCfg then
				MessageBoxPage:Msg_Box(common:getLanguageString("@RoleReward",curMercenaryCfg.name))
			end
		end
    end
end

function FragmentDetailedListPage:filterRoleInfo(container)--筛选符合条件的佣兵碎片
    SaveFilterRoleFragment = {};
    local needCount = alreadySelItems.costFragment[1].count
    local UserMercenaryManager = require("UserMercenaryManager")
    --local userMercenary = nil;
    for i = 1,#AllRoleInfoTable do
        --userMercenary = UserMercenaryManager:getUserMercenaryById(AllRoleInfoTable[i].roleId)
        for j = 1,#alreadySelItems.costFragment do
            if AllRoleInfoTable[i].soulCount >= needCount and AllRoleInfoTable[i].itemId == alreadySelItems.costFragment[j].itemId 
                and  HPRoleStage.notActive == AllRoleInfoTable[i].roleStage then
                table.insert(SaveFilterRoleFragment, {
                    type    = tonumber(alreadySelItems.costFragment[j].type),
                    itemId  = tonumber(alreadySelItems.costFragment[j].itemId),
                    count   = tonumber(AllRoleInfoTable[i].soulCount),
                });
                break
            end
        end
    end
    self:buildItem(container)
end

function FragmentDetailedListPage:buildItem(container)
    NodeHelper:clearScrollView(container)  ---这里是清空滚动层
    local maxSize = #SaveFilterRoleFragment
    CountRow = math.ceil(maxSize/ConstCountCol);--每行5个itms,计算多少行
    CountCol = maxSize%ConstCountCol;
    NodeHelper:buildScrollView(container, CountRow, "SuitPatchDecompositionChooseContent.ccbi", FragmentDetailedListPage.onFunction) --
end

function FragmentDetailedListPage.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then   ---每个子空间创建的时候会调用这个函数
        FragmentDetailedListPage.onRefreshItemView(container);
    elseif string.sub(eventName,1,6)=="onHand" then  --点击每个子空间的时候会调用函数
        local index = string.sub(eventName,7,-1)
        index = tonumber(index)
        FragmentDetailedListPage:onClickHand(index, container);
    end
end

--点击头像选择个数
function FragmentDetailedListPage:onClickHand(eventName, container)
    local index = container:getItemDate().mID;
    local idx = ConstCountCol*(index - 1) + eventName
    local cfg = SaveFilterRoleFragment[idx]
    cfg.needCount = alreadySelItems.costFragment[1].count;
    TimeLimitFragmentExchangePage_onSelectData(cfg);
    FragmentDetailedListPage:onBuyTimes(container,cfg);
end

function FragmentDetailedListPage.onRefreshItemView(container)
    local index = container:getItemDate().mID;
    local cfg = {};
    local lb2Str = {};
    local sprite2Img = {};
    local scaleMap = {}
    local menu2Quality = {};
    local idx = 0;--所有的ID下标索引
    --mFrameShade1 mPic1 mHand1 mName1 mNumber1 mGoodsAni1 
    for col = 1, ConstCountCol do
        idx = ConstCountCol*(index - 1) + col
        cfg = SaveFilterRoleFragment[idx]
        if cfg then--改变数据
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
            sprite2Img["mPic" .. col]         = resInfo.icon;
            sprite2Img["mFrameShade".. col]   = NodeHelper:getImageBgByQuality(resInfo.quality);
            lb2Str["mNumber" .. col]          = "x" .. GameUtil:formatNumber( cfg.count );
            lb2Str["mName" .. col]            = resInfo.name;
            menu2Quality["mHand" .. col]     = resInfo.quality
            NodeHelper:setSpriteImage(container, sprite2Img);
            NodeHelper:setQualityFrames(container, menu2Quality);
            NodeHelper:setStringForLabel(container, lb2Str);
            if string.sub(resInfo.icon, 1, 7) == "UI/Role" then 
                NodeHelper:setNodeScale(container, "mPic" .. col, 0.84, 0.84)
            else
                NodeHelper:setNodeScale(container, "mPic" .. col, 1, 1)
            end
        else--隐藏多余的
            container:getVarNode("mPosition" .. col):setVisible( false )
        end
    end
end

function FragmentDetailedListPage:onExecute(container)

end

function FragmentDetailedListPage:onExit(container)
    NodeHelper:deleteScrollView(container);
	self:removePacket(container)
end

function FragmentDetailedListPage:onClose(container)
    PageManager.popPage(thisPageName)
end

function FragmentDetailedListPage:onBuyTimes(container,cfg)
    local max = cfg.count --999
    local title = common:getLanguageString("@ManyPeopleShopGiftTitle")
    local message = common:getLanguageString("@ManyPeopleShopGiftInfoTxt")
    local multiple = alreadySelItems.costFragment[1].count--倍数限制
    local isShow = false;--是否显示最下面一行

    PageManager.showCommonCountTimesPage(title,message,max,
        function(times)
            local totalTimes = 100*times
            return totalTimes
        end
    ,Const_pb.MONEY_GOLD, TimeLimitFragmentExchangePage_onCallbackCurCount, nil, nil, "@ERRORCODE_80401", multiple, isShow)
end

function FragmentDetailedListPage_setAlreadySelItem(_alreadySelItems)
    alreadySelItems = _alreadySelItems
end

local CommonPage = require('CommonPage')
local FragmentDetailedListPage = CommonPage.newSub(FragmentDetailedListPage, thisPageName, option)