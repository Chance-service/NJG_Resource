----------------------------------------------------------------------------------
--[[
	武器屋
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local Activity4_pb = require("Activity4_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "ActTimeLimit_125"
local ConfigManager = require("ConfigManager")
local mConstCount = 0       -- 必中多少碎片
local mCurrentType = 0
local R_CONST_COUNT = 5
local CONST_COUNT = 10
local QUALITY_COUNT = 3
local EquipType = {
    R = 1,
    SR = 2,
    SSR = 3
}
local ReqAnim = {
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = { }
}

local opcodes = {
    ACTIVITY125_WEAPON_INFO_C = HP_pb.ACTIVITY125_WEAPON_INFO_C,
    ACTIVITY125_WEAPON_INFO_S = HP_pb.ACTIVITY125_WEAPON_INFO_S,
    ACTIVITY125_WEAPON_START_C = HP_pb.ACTIVITY125_WEAPON_START_C,
    ACTIVITY125_WEAPON_START_S = HP_pb.ACTIVITY125_WEAPON_START_S
}

local option = {
    ccbiFile = "Act_TimeLimit_125.ccbi",
    handlerMap = {
        onReturnButton = "onClose",
        onSearchOnce = "onOnceSearch",
        onSearchTen = "onTenSearch",
        onRewardPreview = "onRewardPreview",
        onIllustatedOpen = "onIllustatedOpen",

        onSelectR = "onSelectR",
        onSelectSR = "onSelectSR",
        onSelectSSR = "onSelectSSR",
    }
}

local ActTimeLimit_125 = { }

ActTimeLimit_125.timerName = {
    [1] = "Activity_125_R_TimerName",
    [2] = "Activity_125_SR_TimerName",
    [3] = "Activity_125_SSR_TimerName",
}
local mServerData = nil
local bIsSearchBtn = false -- 点击按钮触发的动画,还是协议遇到宝箱触发的动画
local bIsMeetBox = false -- 是否遇到奇遇宝箱
local nSearchTimes = 1 -- 寻宝次数
-------------------------- logic method ------------------------------------------
function ActTimeLimit_125:onTimer(container)
    if mServerData == nil then
        return
    end
    if mCurrentType == 1 then
        return
    end

    local timeStr = "00:00:0"
    if TimeCalculator:getInstance():hasKey(ActTimeLimit_125.timerName[mCurrentType]) then
        mServerData[mCurrentType].freeTime = TimeCalculator:getInstance():getTimeLeft(ActTimeLimit_125.timerName[mCurrentType])
        if mServerData[mCurrentType].freeTime > 0 then
            timeStr = GameMaths:formatSecondsToTime(mServerData[mCurrentType].freeTime)
            NodeHelper:setStringForLabel(container, { mSuitFreeTime = common:getLanguageString("@SurplusTimeFishing") .. timeStr })
            NodeHelper:setNodesVisible(container, { mSuitFreeTime = true, mSuitFreeTimeNode = true })
        else
            NodeHelper:setNodesVisible(container, { mSuitFreeTime = false, mSuitFreeTimeNode = false, mCostNodeVar = false, mFreeText = true })
            -- self:getPageInfo(container)
        end
    else
        NodeHelper:setNodesVisible(container, { mSuitFreeTime = false, mSuitFreeTimeNode = false })
    end
end

-------------------------- state method -------------------------------------------
function ActTimeLimit_125:getPageInfo(container)
    common:sendEmptyPacket(HP_pb.ACTIVITY125_WEAPON_INFO_C, false)
end

function ActTimeLimit_125:onEnter(parentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container

    NodeHelper:setNodesVisible(container, { mSuitFreeTimeNode = false })
    NodeHelper:setStringForLabel(container, { mSuitFreeTime = "", mActDouble = "" })

    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mMidNode"))
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mS9_1"))

    NodeHelper:setNodesVisible(container, { mBtmNode = false })
    luaCreat_ActTimeLimit_125(container)
    self:registerPacket(parentContainer)
    self:initData(self.container)
    self:initUi()

    self:getPageInfo(parentContainer)

    return container
end

function ActTimeLimit_125:initData()
    mServerData = nil
    mCurrentType = EquipType.R
    ReqAnim = {
        isSingle = false,
        isFirst = false,
        isAnimationRuning = false,
        showNewReward = { }
    }
end

function ActTimeLimit_125:initUi(container)
    self:initSpine(container)
end

function ActTimeLimit_125:initSpine(container)
    local spineNode = self.container:getVarNode("mSpineNode")
    local spinePosOffset = "0,20"
    local spineScale = 0.8
    local roldData = ConfigManager.getRoleCfg()[176]
    if spineNode and roldData then
        spineNode:removeAllChildren()
        local dataSpine = common:split((roldData.spine), ",")
        local spinePath, spineName = dataSpine[1], dataSpine[2]
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode")
        spineToNode:setScale(spineScale)
        spineNode:addChild(spineToNode)
        spine:runAnimation(1, "Stand", -1)
        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))

        local y = NodeHelper:calcAdjustResolutionOffY()
        local scale = NodeHelper:getScaleProportion()

        if scale < 1 then
            -- 适配动画
            local spineScale = spineToNode:getScale() * scale
            local spineScale = spineToNode:getScale() - spineToNode:getScale() % 0.1
            -- spineToNode:setScale(spineScale)
            -- spineToNode:setPositionY(spineToNode:getPositionY() - y * 0.8)
            spineToNode:setPositionY(spineToNode:getPositionY() - spineToNode:getPositionY() * scale)
            -- (scale - 0.5))
        end
        if scale > 1 then
            -- 适配动画
            local spineScale = spineToNode:getScale() * scale
            -- local spineScale = spineToNode:getScale() + spineToNode:getScale() % 0.1
            spineToNode:setScale(spineScale)
            -- spineToNode:setPositionY(spineToNode:getPositionY() + y * 0.8)
            spineToNode:setPositionY(spineToNode:getPositionY() + spineToNode:getPositionY() *(scale + 0.5))
        end
    end
end

function ActTimeLimit_125:onIllustatedOpen(container)
    require("SuitDisplayPage")
    SuitDisplayPageBase_setEquipLv(100, EquipType.SSR, mCurrentType, false, true)
    PageManager.pushPage("SuitDisplayPage")
end

function ActTimeLimit_125:onSelectR(container)
    if mServerData == nil or #mServerData == 0 then
        return
    end
    self:setCurrentType(self.container, EquipType.R)
end

function ActTimeLimit_125:onSelectSR(container)
    if mServerData == nil or #mServerData == 0 then
        return
    end
    self:setCurrentType(self.container, EquipType.SR)
end

function ActTimeLimit_125:onSelectSSR(container)
    if mServerData == nil or #mServerData == 0 then
        return
    end
    self:setCurrentType(self.container, EquipType.SSR)
end

function ActTimeLimit_125:setCurrentType(container, type)
    if mServerData == nil or #mServerData == 0 then
        return
    end
    mCurrentType = type
    self:setBtnEnabled(container)
    self:setSprite(container)
    self:updateData(container)
end

function ActTimeLimit_125:setBtnEnabled(container)
    for i = 1, QUALITY_COUNT do
        NodeHelper:setMenuItemEnabled(container, "m_" .. i .. "_Btn", mCurrentType ~= i)
    end
end

function ActTimeLimit_125:setSprite(container)
    for i = 1, QUALITY_COUNT do
        if mCurrentType == i then
            NodeHelper:setSpriteImage(container, { ["m_" .. i .. "_Sprite"] = "BG/Activity_125/Acivity125_" .. i .. "_S_Image.png" })
        else
            NodeHelper:setSpriteImage(container, { ["m_" .. i .. "_Sprite"] = "BG/Activity_125/Acivity125_" .. i .. "_N_Image.png" })
        end
        NodeHelper:setNodesVisible(container, { ["m_" .. i .. "_Effect"] = mCurrentType == i })
    end

    NodeHelper:setSpriteImage(container, { mCurrentQualityImage = "BG/Activity_125/Acivity125_" .. mCurrentType .. "_TextImage.png" })
end

function ActTimeLimit_125:refreshPage(container)
    local data = mServerData[mCurrentType]

    if mCurrentType == EquipType.R then
        -- 金币抽奖  没有免费次数  五连抽
        NodeHelper:setNodesVisible(container, { mFreeTimeNode = true, mSuitFreeTime = false, mSuitFreeTimeNode = false })
        NodeHelper:setStringForLabel(container, { mFreeTime = common:getLanguageString("@MapChallengeTimes") .. data.leftCount })

        NodeHelper:setMenuItemEnabled(container, "mFree", data.leftCount > 0)
        NodeHelper:setMenuItemEnabled(container, "mDiamond", data.leftCount > 0)

        if data.leftCount <= 0 then
            -- 没有次数
            NodeHelper:setStringForLabel(container, { mFreeText = common:getLanguageString("@MultiEliteTimeNotEnoughTitle") })
            NodeHelper:setStringForLabel(container, { mFreeText_1 = common:getLanguageString("@MultiEliteTimeNotEnoughTitle") })
            NodeHelper:setNodeIsGray(container, { mFreeText = true, mFreeText_1 = true })
            NodeHelper:setNodesVisible(container, { mCostNodeVar = false, mTenNodeVar = false, mFreeText = true, mFreeText_1 = true })
        else
            -- 钻石图片设置成金币
            NodeHelper:setNodeIsGray(container, { mFreeText = false, mFreeText_1 = false })
            NodeHelper:setSpriteImage(container, { mPriceIconSprite_1 = "common_ht_jinbi_img.png", mPriceIconSprite_2 = "common_ht_jinbi_img.png" })
            NodeHelper:setNodesVisible(container, { mCostNodeVar = true, mTenNodeVar = true, mFreeText = false, mFreeText_1 = false })
            NodeHelper:setStringForLabel(container, { mCostTxt1 = common:getLanguageString("@TROneTime") })
            NodeHelper:setStringForLabel(container, { mCostNum = data.oneTimePrice })
            if data.leftCount >= R_CONST_COUNT then
                NodeHelper:setStringForLabel(container, { mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", R_CONST_COUNT) })
                NodeHelper:setStringForLabel(container, { mDiamondText = data.oneTimePrice * R_CONST_COUNT })
            else
                NodeHelper:setStringForLabel(container, { mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", data.leftCount) })
                NodeHelper:setStringForLabel(container, { mDiamondText = data.oneTimePrice * data.leftCount })
            end
        end
    else
        NodeHelper:setNodeIsGray(container, { mFreeText = false, mFreeText_1 = false })
        NodeHelper:setMenuItemEnabled(container, "mFree", true)
        NodeHelper:setMenuItemEnabled(container, "mDiamond", true)
        -- 钻石抽奖  有免费次数  十连抽
        NodeHelper:setNodesVisible(container, { mFreeTimeNode = false, mSuitFreeTime = false, mSuitFreeTimeNode = false })

        NodeHelper:setSpriteImage(container, { mPriceIconSprite_1 = "common_ht_zuanshi_img.png", mPriceIconSprite_2 = "common_ht_zuanshi_img.png" })
        NodeHelper:setNodesVisible(container, { mCostNodeVar = true, mTenNodeVar = true, mFreeText = false, mFreeText_1 = false })
        NodeHelper:setStringForLabel(container, { mCostTxt1 = common:getLanguageString("@TROneTime") })
        NodeHelper:setStringForLabel(container, { mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", 10) })
        NodeHelper:setStringForLabel(container, { mCostNum = data.oneTimePrice })
        NodeHelper:setStringForLabel(container, { mDiamondText = data.multiTimePrice })

        if data.freeTime <= 0 then
            -- 免费
            NodeHelper:setNodesVisible(container, { mFreeText = true, mCostNodeVar = false })
            NodeHelper:setStringForLabel(container, { mFreeText = common:getLanguageString("@GachaFreeTxt") })
        else
            NodeHelper:setNodesVisible(container, { mFreeText = false, mCostNodeVar = true })
            TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_125.timerName[data.type], data.freeTime)
        end
    end

    UserInfo.syncPlayerInfo()
    local label2Str = {
        mDiamondNum = UserInfo.playerInfo.gold,
        mCoinNum = GameUtil:formatNumber(UserInfo.playerInfo.coin)
        -- mActDouble = common:getLanguageString("@NeedXTimesGet",TreasureRaiderDataHelper.leftAwardTimes,MercenaryCfg[_MercenaryInfo.itemId].name,mConstCount)
    }
    NodeHelper:setStringForLabel(container, label2Str)

    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })
end

function ActTimeLimit_125:onExecute(parentContainer)
    self:onTimer(self.container)
end

-- 收包
function ActTimeLimit_125:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    if opcode == HP_pb.ACTIVITY125_WEAPON_INFO_S then
        local msg = Activity4_pb.Activity125WeaponInfoRes()
        msg:ParseFromString(msgBuff)

        mServerData = { }
        for i = 1, #msg.info do
            mServerData[msg.info[i].type] = msg.info[i]
        end
        self:setCurrentType(self.container, mCurrentType)
        -- self:updateData(self.container)
    elseif opcode == HP_pb.ACTIVITY125_WEAPON_START_S then
        local msg = Activity4_pb.Activity125WeaponStartRes()
        msg:ParseFromString(msgBuff)
        ReqAnim.showNewReward = { }

        ReqAnim.showNewReward = msg.reward
        mServerData[msg.info.type] = msg.info

        self:pushRewardPage()
        self:setCurrentType(self.container, mCurrentType)
        -- self:updateData(self.container)
        self:checkPageRedPoint(self.container)
    end
end

function ActTimeLimit_125:updateData(container, opcode, msg)
    if mServerData == nil or #mServerData == 0 then
        return
    end
    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })
    self:refreshPage(self.container)
    self:checkPoint(self.container)
end

function ActTimeLimit_125:checkPageRedPoint(container)
    if mServerData == nil then
        return
    end
    local bl = true
    for i = 1, #mServerData do
        if mServerData[i].freeTime then
            if i ~= 1 and mServerData[i].freeTime <= 0 then
                bl = false
            end
        end
    end
    if bl then
        ActivityInfo.changeActivityNotice(GameConfig.NowSelctActivityId)
    end

    self:checkPoint(container)
end

function ActTimeLimit_125:checkPoint(container)
    if mServerData == nil then
        return
    end
    if mServerData[2].freeTime == nil or mServerData[3].freeTime == nil then
        return
    end
    if mCurrentType == 1 then
        NodeHelper:setNodesVisible(container, { m_1_Point = false })
    end
    NodeHelper:setNodesVisible(container, { m_2_Point = mServerData[2].freeTime <= 0 })
    NodeHelper:setNodesVisible(container, { m_3_Point = mServerData[3].freeTime <= 0 })
end

function ActTimeLimit_125:pushRewardPage()
    local data = { }
    local serverData = mServerData[mCurrentType]
    data.oneGold = serverData.oneTimePrice
    data.tenGold = serverData.multiTimePrice
    data.reward = ReqAnim.showNewReward
    data.isFree = serverData.freeTime <= 0
    if serverData.type == 1 then
        data.isFree = false
    end
    data.freeCount = 0
    data.strDes = ""
    data.oneFunc = ActTimeLimit_125.onOnceSearch
    data.tenFunc = ActTimeLimit_125.onTenSearch
    data.aniEndCall = function()
        if #ReqAnim.showNewReward == 10 then
            -- 评价提示
            PageManager.showComment(true)
        end
    end
    -- data.onceDiscount = 0
    -- data.theDiscount = 0
    -- 钻石抽
    data.priceTyep = 1
    if mCurrentType == 1 then
        -- 金币抽
        data.priceTyep = 2
    end

    -- data.maxCount = nil
    -- data.lastCount = nil

    if mCurrentType == 1 then
        data.maxCount = R_CONST_COUNT
        data.lastCount = serverData.leftCount
    end

    local CommonRewardAniPage = require("CommonRewardAniPage")
    if not CommonRewardAniPage:isPop() then
        CommonRewardAniPage:setPageData(data, false)
        PageManager.pushPage("CommonRewardAniPage")
    else
        -- CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", true, ActTimeLimit_125.onOnceSearch, ActTimeLimit_125.onTenSearch, nil)
        CommonRewardAniPage:setPageData(data, true)
    end
end


function ActTimeLimit_125:onExit(parentContainer)
    for k, v in pairs(ActTimeLimit_125.timerName) do
        TimeCalculator:getInstance():removeTimeCalcultor(v)
    end
    local spineNode = self.container:getVarNode("mSpineNode")
    if spineNode then
        spineNode:removeAllChildren()
    end
    self:removePacket(parentContainer)
    onUnload(thisPageName, self.container)
end

----------------------------click client -------------------------------------------
function ActTimeLimit_125:onOnceSearch(container)
    UserInfo.syncPlayerInfo()

    if mCurrentType == 1 then
        if UserInfo.playerInfo.coin < mServerData[mCurrentType].oneTimePrice then
            PageManager.notifyLackCoin()
        else
            local msg = Activity4_pb.Activity125WeaponStartReq()
            msg.type = mCurrentType
            msg.freeType = false
            msg.count = 1
            common:sendPacket(opcodes.ACTIVITY125_WEAPON_START_C, msg)
        end
    else
        -- 当前拥有钻石小于消耗钻石
        if mServerData[mCurrentType].freeTime > 0 and UserInfo.playerInfo.gold < mServerData[mCurrentType].oneTimePrice then
            common:rechargePageFlag("ActTimeLimit_125ActvityId_" .. GameConfig.NowSelctActivityId)
            return
        end

        local msg = Activity4_pb.Activity125WeaponStartReq()
        msg.type = mCurrentType
        msg.freeType = mServerData[mCurrentType].freeTime <= 0
        msg.count = 1
        common:sendPacket(opcodes.ACTIVITY125_WEAPON_START_C, msg)
    end
end

function ActTimeLimit_125:onTenSearch(container)
    UserInfo.syncPlayerInfo()
    if mCurrentType == 1 then
        local count = R_CONST_COUNT
        local priceCount = R_CONST_COUNT * mServerData[mCurrentType].oneTimePrice
        if mServerData[mCurrentType].leftCount < count then
            count = mServerData[mCurrentType].leftCount
            priceCount = mServerData[mCurrentType].leftCount * mServerData[mCurrentType].oneTimePrice
        end
        if UserInfo.playerInfo.coin < priceCount then
            PageManager.notifyLackCoin()
        else
            local msg = Activity4_pb.Activity125WeaponStartReq()
            msg.type = mCurrentType
            msg.freeType = false
            msg.count = count
            common:sendPacket(opcodes.ACTIVITY125_WEAPON_START_C, msg)
        end
    else
        -- 当前拥有钻石小于消耗钻石
        if UserInfo.playerInfo.gold < mServerData[mCurrentType].multiTimePrice then
            common:rechargePageFlag("ActTimeLimit_125ActvityId_" .. GameConfig.NowSelctActivityId)
            return
        end
        local msg = Activity4_pb.Activity125WeaponStartReq()
        msg.type = mCurrentType
        msg.freeType = false
        msg.count = 10
        common:sendPacket(opcodes.ACTIVITY125_WEAPON_START_C, msg)
    end
end

function ActTimeLimit_125:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_125:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_125:onRewardPreview(container)
    RegisterLuaPage("GodEquipPreview")
    local previewCfg = ConfigManager.getShootPoolShow125Cfg()
    local showPreviewData = { }
    for k, v in pairs(previewCfg) do
        -- and v.stage == ActivityInfo.shootActivityRewardState
        if v.group == mCurrentType then
            showPreviewData[#showPreviewData + 1] = v
        end
    end

    local helpKey = ""
    if mCurrentType == EquipType.R then
        helpKey = GameConfig.HelpKey.HELP_ACT_125_1
    end

    if mCurrentType == EquipType.SR then
        helpKey = GameConfig.HelpKey.HELP_ACT_125_2
    end

    if mCurrentType == EquipType.SSR then
        helpKey = GameConfig.HelpKey.HELP_ACT_125_3
    end

    local isTenMust = ActTimeLimit_125:checkIsMust(showPreviewData)
    if isTenMust then
        require("NewSnowPreviewRewardPage")
        local commonRewardItems = { }
        local luckyRewardItems = { }
        if showPreviewData ~= nil then
            for _, item in ipairs(showPreviewData) do
                if item.tenMust == 1 then
                    table.insert(commonRewardItems, ConfigManager.parseItemOnlyWithUnderline(item.items))
                else
                    table.insert(luckyRewardItems, ConfigManager.parseItemOnlyWithUnderline(item.items))
                end
            end
        end
        NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt3", "@ACTTLNewTreasureRaiderInfoTxt2", helpKey, true)
        PageManager.pushPage("NewSnowPreviewRewardPage")
    else
        ShowEquipPreviewPage(showPreviewData, common:getLanguageString("@RewardPreviewTitle"), common:getLanguageString("@ForgingPoolShowMsg"), helpKey)
        PageManager.pushPage("GodEquipPreview");
    end
end

function ActTimeLimit_125:checkIsMust(itemInfo)
    for k, v in pairs(itemInfo) do
        if v.tenMust == 1 then
            return true
        end
    end
    return false
end

local CommonPage = require("CommonPage")
TreasureRaiderPageNew = CommonPage.newSub(ActTimeLimit_125, thisPageName, option)

return ActTimeLimit_125