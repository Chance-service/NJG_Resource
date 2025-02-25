----------------------------------------------------------------------------------
--[[
	百花美人
--]]
----------------------------------------------------------------------------------
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper")

local ActivityBasePage = require("Activity.ActivityBasePage")
local UserItemManager = require("Item.UserItemManager")
local UserInfo = require("PlayerInfo.UserInfo");
local UserMercenaryManager = require("UserMercenaryManager")
local RoleOpr_pb = require("RoleOpr_pb")
local thisPageName = "KingPowerPage"
local MercenaryRoleInfos = { }
local baseScaleHeight = 0
local baseScrollHeight = 0
local posYtmp = 0
local MercenaryCfg = nil
local opcodes = {
    SYNC_HAREM_C = HP_pb.SYNC_HAREM_C,
    SYNC_HAREM_S = HP_pb.SYNC_HAREM_S,
    HAREM_PANEL_INFO_C = HP_pb.HAREM_PANEL_INFO_C,
    HAREM_PANEL_INFO_S = HP_pb.HAREM_PANEL_INFO_S,
    HAREM_DRAW_S = HP_pb.HAREM_DRAW_S,
    HAREM_DRAW_C = HP_pb.HAREM_DRAW_C,
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    HAREM_EXCHANGE_C = HP_pb.HAREM_EXCHANGE_C,
    HAREM_EXCHANGE_S = HP_pb.HAREM_EXCHANGE_S,

};
local ConstExchaneItemId = 106011
local ConstExchaneCurrencyItemId = 299992

local KingPowerPage = { }
local option = {
    ccbiFile = "Act_TimeLimitKingPalaceContent.ccbi",
    handlerMap =
    {
        onChange_1 = "onChange_1",

        onPropIconClick_1 = "onPropIconClick_1",
        onPropIconClick_2 = "onPropIconClick_2",
        onPropIconClick_3 = "onPropIconClick_3",
        onPropIconClick_4 = "onPropIconClick_4",
        onJumpClick = "onJumpClick",
        onChange_2 = "onChange_2"
    },
    timerName = "Activity_KingPower",
    timerName2 = "Activity_KingPowerClose",
    timerName4 = "Activity_KingPowerClose_4",

    leftTimeData4 = nil,
    leftTimeContainer4 = nil,

};

local itemImageTable = {
    [1] = { s9Image = "BG/Activity/Activity_bg_17.png", titleImage = "Activity_common_title_1.png", messageBgImage = "common_s9_3.png", titleFntFile = "Lang/Activity_Title_blue.fnt", titleText = "@KingPalacePoolName1", spinePosOffset = "30,-40", spineScale = 0.8, propIcon = "common_ht_jinbi_img.png", spineId = 200 },
    -- 普通
    [2] = { s9Image = "BG/Activity/Activity_bg_16.png", titleImage = "Activity_common_title_3.png", messageBgImage = "common_s9_2.png", titleFntFile = "Lang/Activity_Title_yellow.fnt", titleText = "@KingPalacePoolName4", spinePosOffset = "0 , 30", spineScale = 1.2, propIcon = "Activity_common_quan_1.png", spineId = 185 },
    -- 中级
    [3] = { s9Image = "BG/Activity/Activity_bg_15.png", titleImage = "Activity_common_title_2.png", messageBgImage = "common_s9_1.png", titleFntFile = "Lang/Activity_Title_red.fnt", titleText = "@KingPalacePoolName2", spinePosOffset = "0,0", spineScale = 0.75, propIcon = "Activity_common_quan_2.png", spineId = 145 }
}   -- 高级
local freeTimesCDName = { "King_FreeTime1", "King_FreeTime2", "King_FreeTime3" }
local mItemView = { }
local containRef = { }
local FreeCdData = nil
local FreeCdContainer = nil
local leftTimeData = nil
local leftTimeContainer = nil
----------------- local data -----------------

local thisActivityInfo = {
    selectType = 0,
    gotAwardCfgId = { }
}
-----------------------------------------------
--------------------------Content--------------
local KingPowerContent = {
    ccbiFile = "Act_TimeLimitKingPalaceListContent.ccbi",
}

function KingPowerContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 是否弹出对话
function KingPowerPage:onShowDialog()
    local saveDialogStatus = UserInfo.playerInfo.playerId .. UserInfo.serverId .. "KingPowerPage";
    local dialogStatus = CCUserDefault:sharedUserDefault():getStringForKey(saveDialogStatus);
    -- 保存当前的阶段，判断是否更新
    if not dialogStatus or dialogStatus == "" then
        -- 如果没有弹出过，则弹出对话
        require("ActivityDialogConfigPage");
        ActivityDialogConfigBase_setAlreadySelItem(106);
        PageManager.pushPage("ActivityDialogConfigPage");
        CCUserDefault:sharedUserDefault():setStringForKey(saveDialogStatus, saveDialogStatus);
        CCUserDefault:sharedUserDefault():flush();
    end
end


function KingPowerContent:initUi()
    if self.container == nil then
        return
    end
    local container = self.container
    NodeHelper:setNodesVisible(container, { mBtmNode = false })

    NodeHelper:setNodesVisible(container, { mCoinNumNode = false })
    NodeHelper:setNodesVisible(container, { mExtraRewardNode = false, mDoubleNode = false })
    local haremCfg = thisActivityInfo.activityCfg[self.id]
    local itemImageData = itemImageTable[self.id]

    local titleImage = container:getVarSprite("mTitleImage")
    titleImage:setTexture(itemImageData.titleImage)

    -- 设置title
    local titleText = container:getVarLabelBMFont("mDiscountTxt")
    titleText:setFntFile(itemImageData.titleFntFile)
    titleText:setString(haremCfg.name)

    self.isExecute = false
    if self.isAdjust == false then

        local rect = CCRectMake(0, 0, 221, 695)
        local bgMap = {
            mBGKuang =
            {
                name = itemImageData.s9Image,
                rect = rect
            }
        }
        local capInsets = {
            left = 0,
            right = 0,
            top = 292,
            bottom = 341
        }
        NodeHelper:setScale9SpriteImage(container, bgMap, { mBGKuang = capInsets }, { mBGKuang = CCSizeMake(221, 726) })
        NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mBGKuang"))
        container:getVarNode("mBtmNode"):setPositionY(0)
        NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
        NodeHelper:setSpriteImage(container, { mMessageSprite_1 = itemImageData.messageBgImage, mMessageSprite_2 = itemImageData.messageBgImage })



        local rect = CCRectMake(0, 0, 22, 31)
        local bgMap = {
            mMessageSprite_1 =
            {
                name = itemImageData.messageBgImage,
                rect = rect
            }
        }
        local capInsets = {
            left = 10,
            right = 10,
            top = 15,
            bottom = 15
        }
        NodeHelper:setScale9SpriteImage(container, bgMap, { mMessageSprite_1 = capInsets }, { mMessageSprite_1 = CCSizeMake(21, 400) })

        local rect = CCRectMake(0, 0, 22, 31)
        local bgMap = {
            mMessageSprite_2 =
            {
                name = itemImageData.messageBgImage,
                rect = rect
            }
        }
        local capInsets = {
            left = 10,
            right = 10,
            top = 15,
            bottom = 15
        }

        NodeHelper:setScale9SpriteImage(container, bgMap, { mMessageSprite_2 = capInsets }, { mMessageSprite_2 = CCSizeMake(21, 400) })

        self.isAdjust = true
    end

    -- 添加spine
    local spineNode = container:getVarNode("mSpine");
    if spineNode and spineNode:getChildByTag(10086) == nil then
        spineNode:removeAllChildren()
        -- local roldData = ConfigManager.getRoleCfg()[haremCfg.spineId]
        local roldData = ConfigManager.getRoleCfg()[itemImageData.spineId]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
       --local spine = SpineContainer:create(spinePath, spineName)
       --local spineToNode = tolua.cast(spine, "CCNode")
       --spineToNode:setTag(10086)
       ---- self.spineId = haremCfg.spineIdm
       --
       --spineNode:addChild(spineToNode);
       --spine:runAnimation(1, "Stand", -1);
       --local offset_X_Str, offset_Y_Str = unpack(common:split((itemImageData.spinePosOffset), ","))
       --NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
       --spineToNode:setScale(itemImageData.spineScale)
       --spineNode:setPositionX(0)
       --spineNode:setPositionY(0)


        local scale = NodeHelper:getScaleProportion()
        if scale > 1 then
            -- 适配动画
            NodeHelper:autoAdjustResetNodePosition(spineToNode, 0.5)
        end
    end

    NodeHelper:setColorForLabel(container, { mFreeTime = "255 255 255" })
    NodeHelper:setColorForLabel(container, { mTimeDown = "255 255 255" })

end

function KingPowerContent:refresh()
    if thisActivityInfo.haremInfo == nil or #thisActivityInfo.haremInfo == 0 then
        return
    end
    local haremData = thisActivityInfo.haremInfo[self.id]
    if self.container == nil or haremData == nil then
        return
    end

    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    local itemImageData = itemImageTable[haremData.haremType]
    local container = self.container
    -- containRef[self.id] = container
    self.countDown = 0
    self.isExecute = false
    if self.id == 3 then
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            GuideManager.PageContainerRef["KingPowerListPage"] = container
            if GuideManager.getCurrentStep() == 28 then
                PageManager.pushPage("NewbieGuideForcedPage")
                PageManager.popPage("NewGuideEmptyPage")
                GuideManager.IsNeedShowPage = false
            end
        end
    end


    NodeHelper:setStringForLabel(container, { mFreeText = common:getLanguageString("@KingPalaceFree1Text") })
    NodeHelper:setNodesVisible(container, { mExtraRewardNode = haremData.haremType ~= 1, mDoubleNode ~= 1 })

    NodeHelper:setNodesVisible(container, { mExtraRewardNode = haremCfg.LuckDesc == "0" })
    NodeHelper:setNodesVisible(container, { mExtraRewardNode = haremCfg.LuckDesc == "0" })

    -- haremCfg.LuckDesc左边的
    -- haremCfg.desc右边的

    if haremCfg.LuckDesc == "0" then
        NodeHelper:setNodesVisible(container, { mExtraRewardNode = false })
    else
        NodeHelper:setNodesVisible(container, { mExtraRewardNode = true })
        NodeHelper:setStringForLabel(container, { mRewardTxt = common:getLanguageString(haremCfg.LuckDesc, haremData.luckyTime, MercenaryCfg[haremCfg.spineId].name) })
        container:getVarLabelTTF("mRewardTxt"):setDimensions(CCSizeMake(25, 800))
    end

    if haremCfg.desc == "0" then
        NodeHelper:setNodesVisible(container, { mDoubleNode = false })
    else
        NodeHelper:setNodesVisible(container, { mDoubleNode = true })
        NodeHelper:setStringForLabel(container, { mRewardInfo = common:getLanguageString(haremCfg.desc) })
        container:getVarLabelTTF("mRewardInfo"):setDimensions(CCSizeMake(25, 800))
    end

    -- 设置title
    local titleText = container:getVarLabelBMFont("mDiscountTxt")
    titleText:setFntFile(itemImageData.titleFntFile)
    titleText:setString(haremCfg.name)
    -- 设置价格   tile
    NodeHelper:setStringForLabel(container, { mCostNum = haremCfg.onceGold, mDiamondText = haremCfg.tenGold })
    NodeHelper:setStringForLabel(container, { mTimeDown = "" })
    -- 不打折
    local mDiamond1 = container:getVarSprite("mDiamond1")
    local mDiamond2 = container:getVarSprite("mDiamond2")

    NodeHelper:setStringForLabel(container, { mCostTxt1 = common:getLanguageString("@SilverMoonTenTimes", 1) })
    NodeHelper:setStringForLabel(container, { mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", 10) })
    NodeHelper:setNodesVisible(container, { mFreeTimeNode = false })

    -- TODO
    if haremData.haremType == 1 then
        NodeHelper:setNodesVisible(self.container, { mTimeDownNode = false })
        -- 初级        用金币抽奖  没有免费次数   每天抽奖次数有限制
        mDiamond1:setTexture("common_ht_jinbi_img.png")
        mDiamond2:setTexture("common_ht_jinbi_img.png")

        mDiamond1:setScale(0.8)
        mDiamond2:setScale(0.8)

        NodeHelper:setNodesVisible(container, { mFreeTimeNode = true })
        NodeHelper:setStringForLabel(container, { mFreeTime = common:getLanguageString("@SilverMoonLimitTime", haremData.dayLeftTimes) })
        NodeHelper:setNodesVisible(container, { mExtraRewardNode = false, mDoubleNode = false })
        if haremData.dayLeftTimes > 0 then
            -- 还有次数
            NodeHelper:setMenuItemEnabled(container, "mFree", true)
            NodeHelper:setMenuItemEnabled(container, "mDiamond", true)
            NodeHelper:setNodeIsGray(container, { mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false })

            local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
            if isFree then
                NodeHelper:setNodesVisible(container, { mCostNodeVar = false, mTenNodeVar = true, mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false, mFreeText = true })
            else
                NodeHelper:setNodesVisible(container, { mCostNodeVar = true, mTenNodeVar = true, mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false, mFreeText = false })
                NodeHelper:setStringForLabel(container, { mCostNum = haremCfg.onceGold })
                if haremData.dayLeftTimes > 10 then
                    NodeHelper:setStringForLabel(container, { mDiamondText = haremCfg.onceGold * 10, mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", 10) })
                else
                    NodeHelper:setStringForLabel(container, { mDiamondText = haremCfg.onceGold * haremData.dayLeftTimes, mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", haremData.dayLeftTimes) })
                end
            end
        else
            -- 没有次数
            NodeHelper:setNodesVisible(container, { mHuiShuBuZu_1 = true, mHuiShuBuZu_2 = true, mCostNodeVar = false, mTenNodeVar = false, mFreeText = false })

            NodeHelper:setMenuItemEnabled(container, "mFree", false)
            NodeHelper:setMenuItemEnabled(container, "mDiamond", false)
            NodeHelper:setNodeIsGray(container, { mHuiShuBuZu_1 = true, mHuiShuBuZu_2 = true })
        end
    elseif haremData.haremType == 2 then

        NodeHelper:setNodesVisible(self.container, { mTimeDownNode = false })
        -- 中级    用钻石或者抽奖券抽奖
        mDiamond1:setTexture("common_ht_zuanshi_img.png")
        mDiamond2:setTexture("common_ht_zuanshi_img.png")
        mDiamond1:setScale(0.8)
        mDiamond2:setScale(0.8)

        local LuckDrawPropCount = UserItemManager:getCountByItemId(haremCfg.items.itemId)
        -- 当前玩家抽奖券的剩余数量

        local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
        NodeHelper:setNodesVisible(container, { mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false })
        NodeHelper:setNodesVisible(container, { mFreeText = isFree, mCostNodeVar = not isFree })

        NodeHelper:setStringForLabel(container, { mTimeDown = "" })
        if haremData.freeChance > 0 and haremData.freeCd > 0 then
            -- CD倒计时
            self.countDown = haremData.freeCd
            local countDownTimerKey = freeTimesCDName[haremData.haremType]
            TimeCalculator:getInstance():createTimeCalcultor(countDownTimerKey, self.countDown)
            NodeHelper:setNodesVisible(self.container, { mTimeDownNode = true })
            self.isExecute = true
        end

        if LuckDrawPropCount >= 1 then
            -- 更改抽一次消耗道具图标
            mDiamond1:setTexture(itemImageData.propIcon)
            mDiamond1:setScale(0.6)
            -- 设置抽奖消耗数量
            NodeHelper:setStringForLabel(container, { mCostNum = 1 })
        end
        if LuckDrawPropCount >= 10 then
            -- 更改抽十次消耗道具图标
            mDiamond2:setTexture(itemImageData.propIcon)
            mDiamond2:setScale(0.6)
            -- 设置抽奖消耗数量
            NodeHelper:setStringForLabel(container, { mDiamondText = 10 })
        end

        NodeHelper:setNodesVisible(container, { mCoinNumNode = false })
    elseif haremData.haremType == 3 then
        NodeHelper:setNodesVisible(self.container, { mTimeDownNode = false })
        -- 高级
        mDiamond1:setTexture("common_ht_zuanshi_img.png")
        mDiamond2:setTexture("common_ht_zuanshi_img.png")
        mDiamond1:setScale(0.8)
        mDiamond2:setScale(0.8)
        local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
        NodeHelper:setNodesVisible(container, { mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false })
        NodeHelper:setNodesVisible(container, { mFreeText = isFree, mCostNodeVar = not isFree })

        NodeHelper:setStringForLabel(container, { mTimeDown = "" })
        if haremData.freeChance > 0 and haremData.freeCd > 0 then
            -- TODO CD倒计时

        end
        local LuckDrawPropCount = UserItemManager:getCountByItemId(haremCfg.items.itemId)
        -- 当前玩家抽奖券的剩余数量
        if LuckDrawPropCount >= 1 then
            -- 更改抽一次消耗道具图标
            mDiamond1:setTexture(itemImageData.propIcon)
            mDiamond1:setScale(0.6)

            -- 设置抽奖消耗数量
            NodeHelper:setStringForLabel(container, { mCostNum = 1 })
        end
        if LuckDrawPropCount >= 10 then
            -- 更改抽十次消耗道具图标
            mDiamond2:setTexture(itemImageData.propIcon)
            mDiamond2:setScale(0.6)
            -- 设置抽奖消耗数量
            NodeHelper:setStringForLabel(container, { mDiamondText = 10 })
        end

        KingPowerPage:updateMercenaryNumber(haremCfg.spineId, container)
        NodeHelper:setNodesVisible(container, { mCoinNumNode = false })
    end

    NodeHelper:setNodesVisible(container, { mCoinNumNode = false })
    NodeHelper:setNodesVisible(container, { mBtmNode = true })

    --[[    if self.id == 3 then
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.IsNeedShowPage then
            GuideManager.PageContainerRef["KingPowerListPage"] = container
            if GuideManager.getCurrentStep() == 31 then
                PageManager.pushPage("NewbieGuideForcedPage")
                PageManager.popPage("NewGuideEmptyPage")
                GuideManager.IsNeedShowPage = false
            end
        end
    end]]
end

function KingPowerContent:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
end

function KingPowerContent:onExecute()
    if self.isExecute then
        if thisActivityInfo.haremInfo == nil or #thisActivityInfo.haremInfo == 0 then
            return
        end

        local haremData = thisActivityInfo.haremInfo[self.id]
        if haremData == nil then
            return
        end
        local timeStr = '00:00:0'
        local countDownTimerKey = freeTimesCDName[haremData.haremType]
        local timer = 0
        if not TimeCalculator:getInstance():hasKey(countDownTimerKey) then
            TimeCalculator:getInstance():createTimeCalcultor(countDownTimerKey, self.countDown)
        end
        self.countDown = TimeCalculator:getInstance():getTimeLeft(countDownTimerKey)
        if self.countDown > 0 then
            NodeHelper:setNodesVisible(self.container, { mTimeDownNode = true })
            NodeHelper:setStringForLabel(self.container, { mTimeDown = common:getLanguageString("@SuitFreeOneTime", GameMaths:formatSecondsToTime(self.countDown)) })
        else
            self.isExecute = false
            NodeHelper:setNodesVisible(self.container, { mTimeDownNode = false })
            TimeCalculator:getInstance():removeTimeCalcultor(countDownTimerKey)
            -- 倒计时结束请求数据
            local msg = Activity2_pb.HPSyncHarem()
            msg.haremType:append(haremData.haremType)
            common:sendPacket(opcodes.SYNC_HAREM_C, msg)
        end
    end
end

function KingPowerContent_onFree3()
    if thisActivityInfo.haremInfo == nil or #thisActivityInfo.haremInfo == 0 then
        return
    end
    local haremData = thisActivityInfo.haremInfo[3]
    if haremData == nil then
        return
    end
    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
    local itemId = haremCfg.items.itemId
    local num = 0;
    if itemId ~= 0 then
        num = UserItemManager:getCountByItemId(itemId)
    end
    if num <= 0 and not isFree then
        local GuideManager = require("Guide.GuideManager")
        GuideManager.IsNeedShowPage = false
        GuideManager.currGuide[GuideManager.currGuideType] = GuideManager.currGuide[GuideManager.currGuideType] + 1
        PageManager.pushPage("NewbieGuideForcedPage")
    else
        local index = 3
        local itemInfo = thisActivityInfo.activityCfg[index]
        thisActivityInfo.selectType = index;
        local msg = Activity2_pb.HPHaremDraw();
        msg.type = thisActivityInfo.haremInfo[index].haremType;
        msg.times = 1
        common:sendPacket(opcodes.HAREM_DRAW_C, msg);
        -- thisActivityInfo.totalOffset = KingPowerPage.container.mScrollView:getContentOffset()
    end
end

function KingPowerContent:onFree(container)

    if thisActivityInfo.haremInfo == nil or #thisActivityInfo.haremInfo == 0 then
        return
    end

    local haremData = thisActivityInfo.haremInfo[self.id]

    if haremData == nil then
        return
    end

    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
    local itemId = haremCfg.items.itemId
    local num = 0;

    if haremData.haremType == 1 then
        if UserInfo.playerInfo.coin < haremCfg.onceGold and not isFree then
            PageManager.notifyLackCoin()
            -- common:rechargePageFlag("KingPowerContent")
        else
            local index = self.id
            local itemInfo = thisActivityInfo.activityCfg[index]
            thisActivityInfo.selectType = index;
            local msg = Activity2_pb.HPHaremDraw();
            msg.type = thisActivityInfo.haremInfo[self.id].haremType;
            msg.times = 1
            common:sendPacket(opcodes.HAREM_DRAW_C, msg);
            -- thisActivityInfo.totalOffset = KingPowerPage.container.mScrollView:getContentOffset()
        end
    else
        if itemId ~= 0 then
            num = UserItemManager:getCountByItemId(itemId)
        end
        if num <= 0 and not isFree and UserInfo.playerInfo.gold < haremCfg.onceGold then
            common:rechargePageFlag("KingPowerContent")
        else
            local index = self.id
            local itemInfo = thisActivityInfo.activityCfg[index]
            thisActivityInfo.selectType = index;
            local msg = Activity2_pb.HPHaremDraw();
            msg.type = thisActivityInfo.haremInfo[self.id].haremType;
            msg.times = 1
            common:sendPacket(opcodes.HAREM_DRAW_C, msg);
            -- thisActivityInfo.totalOffset = KingPowerPage.container.mScrollView:getContentOffset()
        end
    end
end

function KingPowerContent:onDiamond(container)

    if thisActivityInfo.haremInfo == nil or #thisActivityInfo.haremInfo == 0 then
        return
    end
    local haremData = thisActivityInfo.haremInfo[self.id]

    if haremData == nil then
        return
    end

    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    local num = 0;
    local itemId = haremCfg.items.itemId

    if haremData.haremType == 1 then
        if thisActivityInfo.haremInfo[self.id].dayLeftTimes >= 10 then
            -- 剩余次数大于10次的情况
            if UserInfo.playerInfo.coin < haremCfg.tenGold then
                PageManager.notifyLackCoin()
            else
                thisActivityInfo.selectType = self.id
                local msg = Activity2_pb.HPHaremDraw();
                msg.type = thisActivityInfo.haremInfo[self.id].haremType
                msg.times = 10
                common:sendPacket(opcodes.HAREM_DRAW_C, msg)
                -- thisActivityInfo.totalOffset = KingPowerPage.container.mScrollView:getContentOffset()
            end
        else
            -- 剩余次数小于10次的情况
            if UserInfo.playerInfo.coin < haremCfg.onceGold * thisActivityInfo.haremInfo[self.id].dayLeftTimes then
                PageManager.notifyLackCoin()
            else
                thisActivityInfo.selectType = self.id
                local msg = Activity2_pb.HPHaremDraw();
                msg.type = thisActivityInfo.haremInfo[self.id].haremType
                msg.times = thisActivityInfo.haremInfo[self.id].dayLeftTimes
                common:sendPacket(opcodes.HAREM_DRAW_C, msg);
                -- thisActivityInfo.totalOffset = KingPowerPage.container.mScrollView:getContentOffset()
            end
        end
    else
        if itemId ~= 0 then
            num = UserItemManager:getCountByItemId(itemId)
        end
        if num < 10 and UserInfo.playerInfo.gold < haremCfg.tenGold then
            common:rechargePageFlag("KingPowerContent")
        else
            local index = self.id
            local itemInfo = thisActivityInfo.activityCfg[index]
            thisActivityInfo.selectType = index;
            local msg = Activity2_pb.HPHaremDraw();
            msg.type = thisActivityInfo.haremInfo[self.id].haremType;
            msg.times = 10
            common:sendPacket(opcodes.HAREM_DRAW_C, msg);
            -- thisActivityInfo.totalOffset = KingPowerPage.container.mScrollView:getContentOffset()
        end
    end
end

function KingPowerContent:onRewardPreview(container)
    CCLuaLog("KingPowerContent:onRewardPreview")
    local index = self.id
    if thisActivityInfo.haremInfo == nil or #thisActivityInfo.haremInfo == 0 then
        return
    end

    if thisActivityInfo.haremInfo[index] == nil then
        return
    end

    local type = thisActivityInfo.haremInfo[index].haremType;

    RegisterLuaPage("GodEquipPreview")
    local helpKey = ""
    if index == 1 then
        helpKey = GameConfig.HelpKey.HELP_CHUJIIUDAN
    elseif index == 2 then
        helpKey = GameConfig.HelpKey.HELP_ZHONGJINIUDAN
    elseif index == 3 then
        helpKey = GameConfig.HelpKey.HELP_GAOJINIUDAN
    end

    local itemInfo = thisActivityInfo.rewardCfg[type]

    local isMust = self:checkIsMust(itemInfo)
    if isMust then

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
        NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", helpKey)
        PageManager.pushPage("NewSnowPreviewRewardPage")
    else
        local commonRewardItems = { }
        if itemInfo ~= nil then
            for _, item in ipairs(itemInfo) do
                table.insert(commonRewardItems, {
                    type = tonumber(item.rewardData.type),
                    itemId = tonumber(item.rewardData.itemId),
                    count = tonumber(item.rewardData.count)
                } );
            end
        end


        ShowEquipPreviewPage(commonRewardItems, common:getLanguageString("@RewardPreviewTitle"), common:getLanguageString("@RewardPreviewTitleTxt"), helpKey)
        PageManager.pushPage("GodEquipPreview");
    end

end

function KingPowerContent:checkIsMust(itemInfo)
    for k, v in pairs(itemInfo) do
        if v.tenMust == 1 then
            return true
        end
    end
    return false
end

function KingPowerContent:onFrame4(container)
    local index = self.id
    local itemInfo = thisActivityInfo.activityCfg[index]
    self:onShowItemInfo(container, itemInfo, 4)
end


function KingPowerContent:onShowItemInfo(container, itemInfo, rewardIndex)
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

    GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), rewardItems[rewardIndex])

end

function KingPowerContent:onRewardBtn(container)
    local index = self.id;
    if thisActivityInfo.gotAwardCfgId[index] then
        MessageBoxPage:Msg_Box_Lan("@VipWelfareAlreadyReceive");
        return
    end
    local msg = Activity_pb.HPAccLoginAwards();
    msg.rewwardDay = index;
    common:sendPacket(opcodes.ACC_LOGIN_AWARDS_C, msg);
end
-----------------------end Content------------

---------------------------------------------------------------


function KingPowerPage:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    self.container:registerFunctionHandler(self.onFunction)
    self.ParentContainer = ParentContainer
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mScale9Sprite1"))
    NodeHelper:autoAdjustResizeScrollview(self.container:getVarScrollView("mContent"))
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    NodeHelper:setNodesVisible(self.container, { mBtmNode = false })
    self.mScrollView = container:getVarScrollView("mContent")
    self.mScrollView:setTouchEnabled(false)
    self:registerPacket(self.ParentContainer)
    self:getPageInfo(self.container)
    --引导剧情
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.currGuide[GuideManager.guideType.NIUDAN_GUIDE] ~= 0 then
        if GuideManager.isInGuide == false then
            GuideManager.currGuideType = GuideManager.guideType.NIUDAN_GUIDE
            GuideManager.newbieGuide()
        end
    end
    return container
end


function KingPowerPage.onFunction(eventName, container)
    if eventName == "onChange_1" then
        KingPowerPage:onChange_1(container)
    end
end

function KingPowerPage_onChange()
    local KingPowerScoreExchangePage = require("KingPowerScoreExchangePage")
    KingPowerScoreExchangePage:onloadCcbiFile(1)
    PageManager.pushPage("KingPowerScoreExchangePage")
end

function KingPowerPage:onChange_1(container)
    local KingPowerScoreExchangePage = require("KingPowerScoreExchangePage")
    KingPowerScoreExchangePage:onloadCcbiFile(1)
    PageManager.pushPage("KingPowerScoreExchangePage")
end

function KingPowerPage:onChange_2(container)
    if thisActivityInfo.score == nil then
        return
    end
    require("KingScoreExchangePopUp")
    local data = { }
    local scoreCount = thisActivityInfo.score
    data.currentCount = scoreCount
    data.consumeCount = 40
    data.maxCount = math.modf(scoreCount / data.consumeCount)
    if data.maxCount > 99 then
        -- 最大兑换99个
        data.maxCount = 99
    end
    data.targetItemData = { type = 30000, itemId = 299992, count = 1 }
    data.titleStr = "@LoadTreasureTableTitle"
    data.errorMessage = "@ERRORCODE_155"
    data.callBack = KingPowerPage.ScoreCallBack

    KingScoreExchangePopUp_setData(data)
    PageManager.pushPage("KingScoreExchangePopUp")
end

function KingPowerPage.ScoreCallBack(bl, count)
    -- TODO
    if bl then
        local msg = Activity2_pb.HPHaremExchangeReq()
        msg.times = count;
        msg.id = 27
        common:sendPacket(HP_pb.HAREM_EXCHANGE_C, msg, true)
    end
end

function KingPowerPage:onJumpClick(container)

    ActivityInfo.jumpToActivityById(136)

--    require("LimitActivityPage")
--    LimitActivityPage_setPart(136)
--    LimitActivityPage_setIds(ActivityInfo.LimitPageIds)
--    LimitActivityPage_setCurrentPageType(1)
--    LimitActivityPage_setTitleStr("@FixedTimeActTitle")
--    PageManager.changePage("LimitActivityPage")
end

function KingPowerPage:onPropIconClick_1(container)
    -- 中级抽奖券
    local data = { type = 30000, itemId = 106101, count = 1 }
    GameUtil:showTip(container:getVarNode("mPropIcon_1"), data)
end

function KingPowerPage:onPropIconClick_2(container)
    -- 高级抽奖券
    local data = { type = 30000, itemId = 106102, count = 1 }
    GameUtil:showTip(container:getVarNode("mPropIcon_2"), data)
end

function KingPowerPage:onPropIconClick_3(container)
    -- 引换券
    local data = { type = 30000, itemId = 106011, count = 1 }
    GameUtil:showTip(container:getVarNode("mPropIcon_3"), data)
end

function KingPowerPage:onPropIconClick_4(container)
    -- 引换币
    local data = { type = 30000, itemId = 299992, count = 1 }
    GameUtil:showTip(container:getVarNode("mPropIcon_4"), data)
end

function KingPowerPage:getPageInfo(container)
    containRef = { }

    self:initData()

    self:initUi(container)

    local msg = Activity2_pb.HPSyncHarem()
    msg.haremType:append(1)
    -- 初级扭蛋
    msg.haremType:append(2)
    -- 中级扭蛋
    msg.haremType:append(3)
    -- 高级扭蛋
    common:sendPacket(opcodes.SYNC_HAREM_C, msg, false)

end

function KingPowerPage:initData()
    thisActivityInfo.selectType = 0
    thisActivityInfo.haremInfo = { }
    thisActivityInfo.activityCfg = ConfigManager.getKingPowerCfg()
    thisActivityInfo.rewardCfg = ConfigManager.getKingPowerRewardCfg()
    MercenaryCfg = ConfigManager.getRoleCfg()
end

function KingPowerPage:initUi(container)

    NodeHelper:setNodesVisible(self.container, { mBtmNode = false })

    self:refreshNum(container)

--    local itemId1 = thisActivityInfo.activityCfg[2].items.itemId
--    local itemId2 = thisActivityInfo.activityCfg[3].items.itemId
--    local num1 = UserItemManager:getCountByItemId(itemId1)
--    local num2 = UserItemManager:getCountByItemId(itemId2)
--    local num3 = UserItemManager:getCountByItemId(ConstExchaneItemId)
--    local score = common:getLanguageString("@KingPalaceScoreTxt", thisActivityInfo.score)
--    local diamoudNum = UserInfo.playerInfo.gold
--    NodeHelper:setStringForLabel(container, { mNum1 = num1, mNum2 = num2, mNum3 = num3, mScore = score, mDiamondNum = diamoudNum })


    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })
    mItemView = { }
    self.mScrollView:removeAllCell()
    for i = 1, 3 do
        local titleCell = CCBFileCell:create()
        local panel = KingPowerContent:new( { id = i, ccbRoot = titleCell, isAdjust = false })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(KingPowerContent.ccbiFile)
        self.mScrollView:addCellBack(titleCell)
        table.insert(mItemView, i, panel)
        mItemView[i] = panel
    end
    self.mScrollView:orderCCBFileCells()
    for k, v in pairs(mItemView) do
        v:initUi()
    end
end

function KingPowerPage:refreshPage(container)

    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["KingPowerPage"] = container
    if GuideManager.isInGuide and GuideManager.getCurrentStep() == 30 and GuideManager.isLoginAgain then
        GuideManager.isLoginAgain = false
        PageManager.popPage("NewGuideEmptyPage")
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    FreeCdData = nil
    FreeCdContainer = nil
    leftTimeData = nil
    leftTimeContainer = nil
    option.leftTimeData4 = nil
    option.leftTimeContainer4 = nil
    self:refreshNum(container)

--    local itemId1 = thisActivityInfo.activityCfg[2].items.itemId
--    local itemId2 = thisActivityInfo.activityCfg[3].items.itemId
--    local num1 = UserItemManager:getCountByItemId(itemId1)
--    local num2 = UserItemManager:getCountByItemId(itemId2)
--    local num3 = UserItemManager:getCountByItemId(ConstExchaneItemId)
--    local score = common:getLanguageString("@KingPalaceScoreTxt", thisActivityInfo.score)
--    local diamoudNum = UserInfo.playerInfo.gold
--    NodeHelper:setStringForLabel(container, { mNum1 = num1, mNum2 = num2, mNum3 = num3, mScore = score, mDiamondNum = diamoudNum })

    self:rebuildAllItem(container)
end


function KingPowerPage:refreshNum(container)
    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })
    local itemId1 = thisActivityInfo.activityCfg[2].items.itemId
    local itemId2 = thisActivityInfo.activityCfg[3].items.itemId
    local num1 = UserItemManager:getCountByItemId(itemId1)
    local num2 = UserItemManager:getCountByItemId(itemId2)
    local num3 = UserItemManager:getCountByItemId(ConstExchaneItemId)
    --local num4 = UserItemManager:getCountByItemId(ConstExchaneCurrencyItemId)
    local num4 = 0
    local score = common:getLanguageString("@KingPalaceScoreTxt", thisActivityInfo.score)
    if thisActivityInfo.score == nil then
       score = ""
    end
    local diamoudNum = UserInfo.playerInfo.gold
    NodeHelper:setStringForLabel(container, { mNum1 = num1, mNum2 = num2, mNum3 = num3, mScore = score, mDiamondNum = diamoudNum, mNum4 = num4 })
end

function KingPowerPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function KingPowerPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end


-- 更新佣兵碎片数量
function KingPowerPage:updateMercenaryNumber(itemId, container)
    for i = 1, #MercenaryRoleInfos do
        -- local curMercenary = UserMercenaryManager:getUserMercenaryById(MercenaryRoleInfos[i].roleId)
        if itemId == MercenaryRoleInfos[i].itemId then
            NodeHelper:setStringForLabel(container, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt", MercenaryCfg[itemId].name) .. MercenaryRoleInfos[i].soulCount .. "/" .. MercenaryRoleInfos[i].costSoulCount });
            NodeHelper:setNodesVisible(container, { mCoinNumNode = false })
            break;
        end
    end
end

function KingPowerPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == thisPageName then
            local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
            thisActivityInfo.score = tonumber(extraParam)
            KingPowerPage:refreshPage(self.container)
        end
    end
end

function KingPowerPage:onReceivePacket(ParentContainer)
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
                        v.dayLeftTimes = v2.dayLeftTimes
                    end
                end
            end
        end
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        self:refreshPage(self.container)
        KingPowerPage:clearNotice()
    elseif opcode == opcodes.HAREM_DRAW_S then
        local msg = Activity2_pb.HPHaremDrawRet();
        msg:ParseFromString(msgBuff);
        local KingPowerAniPage = require("KingPowerAniPage")
        if not KingPowerAniPage:isPop() then
            local t = { }

            for i = 1, #msg.reward do
                table.insert(t, msg.reward[i])
            end

            KingPowerAniPage_setFirst(thisActivityInfo.score, t, thisActivityInfo.haremInfo[thisActivityInfo.selectType])
            PageManager.pushPage("KingPowerAniPage")
        end
    elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        UserMercenaryManager:setMercenaryStatusInfos(msg.roleInfos)
        self:refreshPage(self.container)
        KingPowerPage:clearNotice()

    elseif opcode == HP_pb.HAREM_EXCHANGE_S then
        local msg = Activity2_pb.HPHaremScorePanelRes()
        msg:ParseFromString(msgBuff)
        thisActivityInfo.score = msg.score
        self:refreshNum(self.container)
    end
end

function KingPowerPage:clearNotice()
    -- 红点消除
    local hasNotice = false

    for i, v in ipairs(thisActivityInfo.haremInfo) do
        if v.freeChance > 0 and v.freeCd == 0 then
            hasNotice = true
            break
        end
    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.HAREM);
    end
end

function KingPowerPage:onTimer(container)
    local timerName = option.timerName;
    local timerName2 = option.timerName2;
    local timerName4 = option.timerName4;
    if TimeCalculator:getInstance():hasKey(timerName) and FreeCdData and FreeCdContainer then

        local RemainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
        if RemainTime + 1 > FreeCdData.freeCd then
            return;
        end

        FreeCdData.freeCd = math.max(RemainTime, 0);
        if FreeCdData.freeCd <= 0 then
            TimeCalculator:getInstance():removeTimeCalcultor(timerName)
            container.mScrollView:refreshAllCell()
            return
        end
        local timeStr = common:second2DateString(FreeCdData.freeCd);
        NodeHelper:setStringForLabel(FreeCdContainer, { mFreeTime = "" });

        -- NodeHelper:setStringForLabel(FreeCdContainer, {mFreeTime = common:getLanguageString("@KingPowerTimeLeft" , timeStr)});
    end

    if TimeCalculator:getInstance():hasKey(timerName2) and leftTimeData and leftTimeContainer then

        local RemainTime = TimeCalculator:getInstance():getTimeLeft(timerName2);
        if RemainTime + 1 > leftTimeData.leftTime then
            return;
        end

        leftTimeData.leftTime = math.max(RemainTime, 0);
        if leftTimeData.leftTime <= 0 then
            TimeCalculator:getInstance():removeTimeCalcultor(timerName2)
            local msg = Activity2_pb.HPSyncHarem()
            msg.haremType:append(leftTimeData.haremType)
            common:sendPacket(opcodes.SYNC_HAREM_C, msg);
            return
        end
        local timeStr = common:second2DateString(leftTimeData.leftTime, false);
        NodeHelper:setStringForLabel(leftTimeContainer, { mTimeDown = common:getLanguageString("@KingPowerTimeLeft", timeStr) });
    end

    if TimeCalculator:getInstance():hasKey(timerName4) and option.leftTimeData4 and option.leftTimeContainer4 then

        local RemainTime = TimeCalculator:getInstance():getTimeLeft(timerName4);
        if RemainTime + 1 > option.leftTimeData4.leftTime then
            return;
        end

        option.leftTimeData4.leftTime = math.max(RemainTime, 0);
        if option.leftTimeData4.leftTime <= 0 then
            TimeCalculator:getInstance():removeTimeCalcultor(timerName4)
            thisActivityInfo.haremInfo = { }
            local msg = Activity2_pb.HPSyncHarem()
            msg.haremType:append(1)
            msg.haremType:append(2)
            msg.haremType:append(3)
            common:sendPacket(opcodes.SYNC_HAREM_C, msg);
            return
        end
        local timeStr = common:second2DateString(option.leftTimeData4.leftTime, false);
        NodeHelper:setStringForLabel(option.leftTimeContainer4, { mTimeDown = common:getLanguageString("@KingPowerTimeLeft", timeStr) });
    end
end

function KingPowerPage:rebuildAllItem(container)
    if mItemView == nil or #mItemView == 0 then

    else
        for k, v in pairs(mItemView) do
            v:refresh()
        end
    end

    --    local t = { }

    --    for i, v in ipairs(thisActivityInfo.haremInfo) do
    --        if v.haremType == 1 then
    --            t[1] = v
    --        end
    --        if v.haremType == 2 then
    --            t[2] = v
    --        end
    --        if v.haremType == 3 then
    --            t[3] = v
    --        end
    --    end

    --    thisActivityInfo.haremInfo = t
    --    if mItemView == nil or #mItemView == 0 then
    --        mItemView = { }
    --        self.mScrollView:removeAllCell()
    --        for i, v in ipairs(thisActivityInfo.haremInfo) do
    --            local titleCell = CCBFileCell:create()
    --            local panel = KingPowerContent:new( { id = i, ccbRoot = titleCell, isAdjust = false })
    --            titleCell:registerFunctionHandler(panel)
    --            titleCell:setCCBFile(KingPowerContent.ccbiFile)
    --            self.mScrollView:addCellBack(titleCell)
    --            table.insert(mItemView, i, panel)
    --            mItemView[i] = panel
    --        end
    --        self.mScrollView:orderCCBFileCells()
    --    end

    --    for k, v in pairs(mItemView) do
    --        v:refresh()
    --    end
end

function KingPowerPage:onExecute(ParentContainer)
    if mItemView and #mItemView ~= 0 then
        for k, v in pairs(mItemView) do
            v:onExecute()
        end
    end
end


function KingPowerPage:onExit(ParentContainer)
    thisActivityInfo.totalOffset = nil

    for k, v in ipairs(freeTimesCDName) do
        TimeCalculator:getInstance():removeTimeCalcultor(v)
    end

    TimeCalculator:getInstance():removeTimeCalcultor(option.timerName);
    TimeCalculator:getInstance():removeTimeCalcultor(option.timerName2);
    TimeCalculator:getInstance():removeTimeCalcultor(option.timerName4);
    self:removePacket(ParentContainer)
    -- if self.container.mScrollView then
    --     self.container.mScrollView:removeAllCell()
    -- end
    mItemView = { }
    MercenaryCfg = nil
    option.leftTimeData4 = nil
    option.leftTimeContainer4 = nil
    onUnload(thisPageName, self.container)
    --if not GameConfig.isReBackVer28 then
    if self.mScrollView then
        self.mScrollView:removeAllCell()
        self.mScrollView = nil
    end
    --end
end
local CommonPage = require('CommonPage')
KingPowerPage = CommonPage.newSub(KingPowerPage, thisPageName, option)

return KingPowerPage

----------------click event------------------------	

-------------------------------------------------------------------------
