----------------------------------------------------------------------------------
--[[
	新手扭蛋
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
-- local NoviceGashaponDataHelper = require("Activity.NoviceGashaponDataHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local UserItemManager = require("Item.UserItemManager")
local thisPageName = "NoviceGashaponPage"
local typeIndex = 1
local thisActivityId = 115
local thisType = 5              --新手扭蛋 对应类型 = 
local thisActivityInfo = {
    selectType = 0,
    gotAwardCfgId = { }
}

local MercenaryCfg = nil

local opcodes = {
    SYNC_HAREM_C = HP_pb.SYNC_HAREM_C,
    SYNC_HAREM_S = HP_pb.SYNC_HAREM_S,
    HAREM_PANEL_INFO_C = HP_pb.HAREM_PANEL_INFO_C,
    HAREM_PANEL_INFO_S = HP_pb.HAREM_PANEL_INFO_S,
    HAREM_DRAW_S = HP_pb.HAREM_DRAW_S,
    HAREM_DRAW_C = HP_pb.HAREM_DRAW_C,
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S
}


local option = {
    ccbiFile = "Act_NoviceGashapon.ccbi",
    handlerMap =
    {
        onReturnButton = "onClose",
        onHelp = "onHelp",
        onSearchOnce = "onOnceSearch",
        onSearchTen = "onTenSearch",
        onRewardPreview = "onRewardPreview",
        onIllustatedOpen = "onIllustatedOpen",
        onBoxPreview = "onBoxPreview",
    },
}
for i = 1, 10 do
    option.handlerMap["onHand" .. i] = "onHand";
end

local NoviceGashaponPage = {

    mfreeCDTimeText = nil,-- 下次免费抽奖时间
}
NoviceGashaponPage.timerName = "Activity_NoviceGashapon"
NoviceGashaponPage.timerLabel = "mTanabataCD"
local bIsSearchBtn = false -- 点击按钮触发的动画,还是协议遇到宝箱触发的动画
local bIsMeetBox = false -- 是否遇到奇遇宝箱
local nSearchTimes = 1 -- 寻宝次数
local FreeCdData = nil
-------------------------- logic method ------------------------------------------
function NoviceGashaponPage:onTimer(container)

    -- 活动剩余时间
    if FreeCdData then
        if FreeCdData.leftTime > 0 then
            local timeStr = common:second2DateString(FreeCdData.leftTime, false)
            NodeHelper:setStringForLabel(container, { mTanabataCD = common:getLanguageString("@SurplusTimeFishing") .. timeStr })
        else
            NodeHelper:setStringForLabel(container, { mTanabataCD = common:getLanguageString("@ActivityEnd") })
        end
    end

    -- 这个东西先不显示了
    if NoviceGashaponPage.mfreeCDTimeText then
       NoviceGashaponPage.mfreeCDTimeText:setString("")
    end
    -- 下面先注释
    --    --下次可以免费抽奖的时间
    --    if TimeCalculator:getInstance():hasKey(self.timerName) and FreeCdData then

    -- 	local RemainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName)
    -- 	if RemainTime + 1 > FreeCdData.freeCd then
    -- 		return
    -- 	end

    -- 	FreeCdData.freeCd = math.max(RemainTime, 0)
    -- 	if FreeCdData.freeCd <= 0 then
    -- 		TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    -- 		container.mScrollView:refreshAllCell()
    -- 		return
    -- 	end
    -- 	local timeStr = common:second2DateString(FreeCdData.freeCd)
    -- 	NodeHelper:setStringForLabel(container, {mSuitFreeTime = common:getLanguageString("@KingPowerTimeLeft" , timeStr)})
    -- end

end

-------------------------- state method -------------------------------------------

function NoviceGashaponPage:initData()
    thisActivityInfo.selectType = 0
    thisActivityInfo.haremInfo = { }
    thisActivityInfo.activityCfg = ConfigManager.getKingPowerCfg()
    thisActivityInfo.rewardCfg = ConfigManager.getKingPowerRewardCfg()
    MercenaryCfg = ConfigManager.getRoleCfg()


end

function NoviceGashaponPage:initUi(container)
    local mScale9Sprite = self.container:getVarScale9Sprite("mScale9Sprite1")
    if mScale9Sprite then
        baseScaleHeight = mScale9Sprite:getContentSize().height
    end
    if container.mScrollView then
        baseScrollHeight = self.container.mScrollView:getViewSize().height
    end
    self:initSpine(self.container)
    local roleId = thisActivityInfo.activityCfg[thisType].spineId
    NodeHelper:setSpriteImage(self.container, { mRoleQualitySprite = GameConfig.ActivityRoleQualityImage[MercenaryCfg[roleId].quality] })
    NodeHelper:setSpriteImage(self.container, { mRoleIcon = MercenaryCfg[roleId].icon })
    NodeHelper:setSpriteImage(self.container, { mQuality = MercenaryCfg[roleId].quality })

    NoviceGashaponPage.mfreeCDTimeText = container:getVarLabelTTF("mSuitFreeTime")

    local haremCfg = thisActivityInfo.activityCfg[thisType]
    local label2Str = {
        mDiamondNum = UserInfo.playerInfo.gold,
        mItemNum = UserItemManager:getCountByItemId(haremCfg.items.itemId),
    }
    NodeHelper:setStringForLabel(self.container, label2Str)

end

function NoviceGashaponPage:getPageInfo(container)

    containRef = { }
    self:initData()
    self:initUi(self.container)
    local msg = Activity2_pb.HPSyncHarem()
    msg.haremType:append(5)
    -- 新手扭蛋
    common:sendPacket(opcodes.SYNC_HAREM_C, msg)


end

function NoviceGashaponPage:onEnter(parentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container


    NodeHelper:setNodesVisible(self.container, { mBtmNode = false })

    luaCreat_NoviceGashaponPage(container)
    self:registerPacket(parentContainer)
    self:getPageInfo(parentContainer)



    NodeHelper:setNodesVisible(container, { mDoubleNode = true })

    -- NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"), 0.5)
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mS9_1"))

    NodeHelper:setStringForLabel(container, {
        mCostTxt1 = common:getLanguageString("@TROneTime"),
        mCostTxt2 = common:getLanguageString("@TRTenTimes")
    } )

    -- self:initSpine(self.container)

    
    --
    return container
end

function NoviceGashaponPage:initSpine(container)
    local haremData = thisActivityInfo.haremInfo[typeIndex]
    local haremCfg = thisActivityInfo.activityCfg[thisType]

    local spineNode = container:getVarNode("mSpineNode");
    if spineNode:getChildByTag(10086) == nil then
        spineNode:removeAllChildren()
        local roldData = ConfigManager.getRoleCfg()[haremCfg.spineId]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode")
        spineNode:addChild(spineToNode)
        spineToNode:setTag(10086)
        spine:runAnimation(1, "Stand", -1)

        local spinePosOffset = roldData.offset
        local spineScale = roldData.spineScale
        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        spineToNode:setScale(spineScale)
    end
end

function NoviceGashaponPage:onIllustatedOpen(container)
    require("SuitDisplayPage")
    SuitDisplayPageBase_setMercenaryEquip(3)
    PageManager.pushPage("SuitDisplayPage");
end

function NoviceGashaponPage:refreshPage(container)
    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })
    local haremData = thisActivityInfo.haremInfo[typeIndex]
    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    FreeCdData = haremData

    local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
    NodeHelper:setNodesVisible(container, { mCostNodeVar = not isFree, mFreeText = isFree, mSuitFreeTime = not isFree })

    if not isFree then
        ActivityInfo.changeActivityNotice(thisActivityId)
    end

    TimeCalculator:getInstance():createTimeCalcultor(self.timerName, haremData.leftTime)

    UserInfo.syncPlayerInfo()
    local xxx = UserInfo.playerInfo.gold
    local label2Str = {
        mCostNum = haremCfg.onceGold,
        -- 抽一次的价格
        mDiamondText = haremCfg.tenGold,
        -- 抽十次的价格
        -- mSuitFreeTime 			= freeTimesStr, --剩余免费时间  先注释
        mDiamondNum = UserInfo.playerInfo.gold,

        mItemNum = UserItemManager:getCountByItemId(haremCfg.items.itemId),

        -- 玩家的钻石数量
        mFreeText = common:getLanguageString("@TreasureRaiderFreeText"),
        -- 免费一次文字


        mMessateText = ""
    }

    NodeHelper:setStringForLabel(container, label2Str)

    if haremCfg.LuckDesc ~= "0" then
        NodeHelper:setStringForLabel(container, { mMessateText = common:getLanguageString(haremCfg.LuckDesc, haremData.luckyTime, MercenaryCfg[haremCfg.spineId].name) })
    end

    local LuckDrawPropCount = UserItemManager:getCountByItemId(haremCfg.items.itemId)
    local mDiamond1 = container:getVarSprite("mDiamond1")
    local mDiamond2 = container:getVarSprite("mDiamond2")

    mDiamond1:setTexture("common_ht_zuanshi_img.png")
    mDiamond2:setTexture("common_ht_zuanshi_img.png")
    mDiamond1:setScale(1)
    mDiamond2:setScale(1)
    if LuckDrawPropCount >= 1 then
        -- 更改抽一次消耗道具图标
        mDiamond1:setTexture("Activity_common_quan_2.png")
        mDiamond1:setScale(0.6)
        -- 设置抽奖消耗数量
        NodeHelper:setStringForLabel(container, { mCostNum = 1 })
    end
    if LuckDrawPropCount >= 10 then
        -- 更改抽十次消耗道具图标
        mDiamond2:setTexture("Activity_common_quan_2.png")
        mDiamond2:setScale(0.6)

        -- 设置抽奖消耗数量
        NodeHelper:setStringForLabel(container, { mDiamondText = 10 })
    end

    -- mQuality      --品质

    -- 刷新碎片数量
    local itemId = haremCfg.spineId
    for i = 1, #MercenaryRoleInfos do
        if itemId == MercenaryRoleInfos[i].itemId then
            -- ,MercenaryCfg[itemId].name
            -- common:getLanguageString("@RoleFragmentNumberTxt") ..
            NodeHelper:setStringForLabel(container, { mFragmentCountText = MercenaryRoleInfos[i].soulCount .. "/" .. MercenaryRoleInfos[i].costSoulCount })
            -- NodeHelper:setSpriteImage(container, { mRoleIcon = MercenaryCfg[itemId].icon })
            break;
        end
    end

    -- self:initSpine(self.container)

end

function NoviceGashaponPage:onExecute(parentContainer)
    self:onTimer(self.container)
end

-- 收包
function NoviceGashaponPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.SYNC_HAREM_S then
        local msg = Activity2_pb.HPSyncHaremRet();
        msg:ParseFromString(msgBuff);

        thisActivityInfo.score = msg.score
        if #thisActivityInfo.haremInfo == 0 then
            thisActivityInfo.haremInfo = msg.haremInfo
        else
            for i, v in ipairs(thisActivityInfo.haremInfo) do
                for j, v2 in ipairs(msg.haremInfo) do
                    if v.haremType == v2.haremType then
                        v.leftTime = v2.leftTime
                        v.freeChance = v2.freeChance
                        v.freeCd = v2.freeCd
                        v.luckyTime = v2.luckyTime
                    end
                end
            end
        end
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    elseif opcode == opcodes.HAREM_DRAW_S then
        local msg = Activity2_pb.HPHaremDrawRet();
        msg:ParseFromString(msgBuff);
        local KingPowerAniPage = require("KingPowerAniPage")
        if not KingPowerAniPage:isPop() then
            KingPowerAniPage_setFirst(thisActivityInfo.score, msg.reward, thisActivityInfo.haremInfo[thisActivityInfo.selectType])
            PageManager.pushPage("KingPowerAniPage")
        end
    elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        self:refreshPage(self.container)
    end
end

function NoviceGashaponPage:onExit(parentContainer)
    thisActivityInfo.totalOffset = nil
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    self:removePacket(parentContainer)
    MercenaryCfg = nil
    onUnload(thisPageName, self.container)
end

----------------------------click client -------------------------------------------
-- 抽一次
function NoviceGashaponPage:onOnceSearch(container)
    local haremData = thisActivityInfo.haremInfo[typeIndex]
    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
    local itemId = haremCfg.items.itemId
    local num = 0
    if itemId ~= 0 then
        num = UserItemManager:getCountByItemId(itemId)
    end
    if num <= 0 and not isFree and UserInfo.playerInfo.gold < haremCfg.onceGold then
        common:rechargePageFlag("KingPowerContent")
    else
        local index = 1
        local itemInfo = thisActivityInfo.activityCfg[index]
        thisActivityInfo.selectType = index;
        local msg = Activity2_pb.HPHaremDraw();
        msg.type = thisActivityInfo.haremInfo[typeIndex].haremType;
        msg.times = 1
        common:sendPacket(opcodes.HAREM_DRAW_C, msg);
        -- thisActivityInfo.totalOffset = KingPowerPage.container.mScrollView:getContentOffset()
    end
end

-- 抽十次
function NoviceGashaponPage:onTenSearch(container)
    local haremData = thisActivityInfo.haremInfo[typeIndex]
    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    local num = 0;
    local itemId = haremCfg.items.itemId
    if itemId ~= 0 then
        num = UserItemManager:getCountByItemId(itemId)
    end
    if num < 10 and UserInfo.playerInfo.gold < haremCfg.tenGold then
        common:rechargePageFlag("KingPowerContent")
    else
        local index = 1
        local itemInfo = thisActivityInfo.activityCfg[index]
        thisActivityInfo.selectType = index;
        local msg = Activity2_pb.HPHaremDraw();
        msg.type = thisActivityInfo.haremInfo[typeIndex].haremType;
        msg.times = 10
        common:sendPacket(opcodes.HAREM_DRAW_C, msg);
        -- thisActivityInfo.totalOffset = KingPowerPage.container.mScrollView:getContentOffset()
    end
end

function NoviceGashaponPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function NoviceGashaponPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function NoviceGashaponPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_TREASURERAIDER);
end

function NoviceGashaponPage:onRewardPreview(container)
    local index = typeIndex
    local type = thisActivityInfo.haremInfo[index].haremType;
    local itemInfo = thisActivityInfo.rewardCfg[type]

    local isTenMust = NoviceGashaponPage:checkIsMust(itemInfo)
    if isTenMust then
        require("NewSnowPreviewRewardPage")
        local commonRewardItems = { }
        local luckyRewardItems = { }
        if itemInfo ~= nil then
            for _, item in ipairs(itemInfo) do
                if item.tenMust == 1 then
                    table.insert(commonRewardItems, {
                        type = tonumber(item.rewardData.type),
                        itemId = tonumber(item.rewardData.itemId),
                        count = tonumber(item.rewardData.count)
                    } );
                else
                    table.insert(luckyRewardItems, {
                        type = tonumber(item.rewardData.type),
                        itemId = tonumber(item.rewardData.itemId),
                        count = tonumber(item.rewardData.count)
                    } );
                end
            end
        end
        NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", GameConfig.HelpKey.HELP_XINSHOUNIUDAN)
        PageManager.pushPage("NewSnowPreviewRewardPage")
    else
        RegisterLuaPage("GodEquipPreview")
        ShowEquipPreviewPage(itemInfo, common:getLanguageString("@RewardPreviewTitle"), common:getLanguageString("@RewardPreviewTitleTxt"), GameConfig.HelpKey.HELP_XINSHOUNIUDAN)
        PageManager.pushPage("GodEquipPreview");
    end
end

function NoviceGashaponPage:checkIsMust(itemInfo)
    for k, v in pairs(itemInfo) do
        if v.tenMust == 1 then
            return true
        end
    end
    return false
end

local CommonPage = require('CommonPage')
NoviceGashaponPage = CommonPage.newSub(NoviceGashaponPage, thisPageName, option)

return NoviceGashaponPage