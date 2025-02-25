----------------------------------------------------------------------------------
--[[
	射击游戏
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "ShootActitityPage"
local Activity_pb = require("Activity_pb")
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")

local ItemManager = require "Item.ItemManager"
local ShootActitityPage = { mShootItemTabel = nil }

local EquipCfg = { }
local GodEquipBuildCfg = { }
local ReqAnim = {
{
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = { }
}
local GodEquipContent = {
    AllContainer = { },
    ccbFile = "Act_SuitForgePageContent.ccbi"
}


local itemCCBFiel = "Act_ShootItem.ccbi"

local opcodes = {
    SHOOT_PANEL_C = HP_pb.SHOOT_PANEL_C,
    SHOOT_PANEL_S = HP_pb.SHOOT_PANEL_S,
    SHOOT_START_C = HP_pb.SHOOT_START_C,
    SHOOT_END_S = HP_pb.SHOOT_END_S,
}
local option = {
    ccbiFile = "Act_TimeLimitShootContent.ccbi",
    handlerMap = {
        onReturnButton = "onClose",
        onHelp = "onHelp",
        onIllustatedOpen = "onIllustatedOpen",
        onBackpackOpen = "onBackpackOpen",
        onReceive = "onReceive",
        onWishing = "onWishing",
        onFree = "onFree",
        onDiamond = "onDiamond",
        onRewardPreview = "onRewardPreview"
    },
}
for i = 1, 10 do
    option.handlerMap["onHand" .. i] = "onHand"
end
for i = 1, 3 do
    option.handlerMap["onLevel" .. i] = "onLevel"
end
-- 当前页面信息
local PageInfo = {
    singleCost = { 250, 300, 350 },
    tenCost = { 2500, 3000, 3500 },
    leftTime = 0,
    freeTimes = { },
    allEquip = { },
    freeTimesCDName = { "freeTime1", "freeTime2", "freeTime3" },
    timerName = "ShootActitityPage",
    shootType = 1,-- (1：初级,2:中级,3:高级)
}
local alreadyShowReward = { }-- 界面上已经显示的奖励
local needShowReward = { }-- 当前锻造的奖励
local COUNT_LIMIT = 10
local lasttime = 0 -- 用于计算时间差
local isReceiveData = false

local shootItemData = {
    [1] = { titleImage = "Activity_common_title_1.png", bgKuangImgae = "BG/Activity/Activity_bg_17.png", spineId = 121, titleText = "@SuitShootLevel1", titleFntFile = "Lang/Activity_Title_blue.fnt", spinePosOffset = "0,0", spineScale = 1.6 },
    [2] = { titleImage = "Activity_common_title_3.png", bgKuangImgae = "BG/Activity/Activity_bg_16.png", spineId = 129, titleText = "@SuitShootLevel2", titleFntFile = "Lang/Activity_Title_yellow.fnt", spinePosOffset = "0,-20", spineScale = 0.3 },
    [3] = { titleImage = "Activity_common_title_2.png", bgKuangImgae = "BG/Activity/Activity_bg_15.png", spineId = 999, titleText = "@SuitShootLevel3", titleFntFile = "Lang/Activity_Title_red.fnt", spinePosOffset = "0,30", spineScale = 1.8 }
}

-------------------------------------------
-- ShootItem
local ShootItem = { }
function ShootItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 免费抽
function ShootItem:onFree(container)
    PageInfo.shootType = self.id

    ShootActitityPage:HideRewardNode(self.shootActitityPageContainer)
    ReqAnim.showNewReward = { }
    ShootActitityPage:GodEquipBuildEvent(self.shootActitityPageContainer, true)
end

-- 钻石抽
function ShootItem:onDiamond(container)
    PageInfo.shootType = self.id

    ShootActitityPage:HideRewardNode(self.shootActitityPageContainer)
    ReqAnim.showNewReward = { }
    ShootActitityPage:GodEquipBuildEvent(self.shootActitityPageContainer, false)
end

-- 奖励预览
function ShootItem:onRewardPreview(container)
    PageInfo.shootType = self.id
    ShootActitityPage:onRewardPreview(self.shootActitityPageContainer)
end

function ShootItem:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
end

-- 更新
function ShootItem:onExecute()
    local timeStr = "00:00:0"
    local k = self.id
    local v = PageInfo.freeTimesCDName[self.id]

    if TimeCalculator:getInstance():hasKey(PageInfo.freeTimesCDName[k]) then
        PageInfo.freeTimes[k] = TimeCalculator:getInstance():getTimeLeft(PageInfo.freeTimesCDName[k])
        if PageInfo.freeTimes[k] > 0 then
            timeStr = GameMaths:formatSecondsToTime(PageInfo.freeTimes[k])
            NodeHelper:setNodesVisible(self.container, { mFreeText = false, mCostNodeVar = true, mFreeTime = true })
            -- NodeHelper:setStringForLabel(self.container, { mFreeTime = common:getLanguageString("@SuitFreeOneTime", "\n " .. timeStr) })
            NodeHelper:setStringForLabel(self.container, { mFreeTime = timeStr })
            NodeHelper:setNodesVisible(self.container, { mFreeTimeNode = true })
        else
            NodeHelper:setNodesVisible(self.container, { mFreeText = true, mCostNodeVar = false, mFreeTime = true })
            NodeHelper:setNodesVisible(self.container, { mFreeTimeNode = false })
        end
    end
end

function ShootItem:onFrame4(container)
    local index = self.id
    local itemInfo = thisActivityInfo.activityCfg[index]
    self:onShowItemInfo(container, itemInfo, 4)
end
-- 刷新活动是不是结束
function ShootItem:isEnd(bl)

    NodeHelper:setNodesVisible(self.container, { mFreeBtnNode = bl, mDiamondBtnNode = bl })
end

-- 刷新item
function ShootItem:refresh()
    local timeStr = "00:00:0"
    local k = self.id
    local data = PageInfo.freeTimes[self.id]
    if data then
        if data > 0 then
            -- 没有免费次数了
            TimeCalculator:getInstance():createTimeCalcultor(PageInfo.freeTimesCDName[self.id], data)
            timeStr = GameMaths:formatSecondsToTime(PageInfo.freeTimes[k])
            NodeHelper:setNodesVisible(self.container, { mFreeText = false, mCostNodeVar = true, mFreeTime = true })
            -- NodeHelper:setStringForLabel(self.container, { mFreeTime = common:getLanguageString("@SuitFreeOneTime", "\n      " .. timeStr) })
            NodeHelper:setStringForLabel(self.container, { mFreeTime = timeStr })
            NodeHelper:setNodesVisible(self.container, { mFreeTimeNode = true })
        else
            -- 有免费次数
            if TimeCalculator:getInstance():hasKey(PageInfo.freeTimesCDName[k]) then
                TimeCalculator:getInstance():removeTimeCalcultor(PageInfo.freeTimesCDName[self.id])
            end
            NodeHelper:setNodesVisible(self.container, { mFreeText = true, mCostNodeVar = false, mFreeTime = true })
            NodeHelper:setNodesVisible(self.container, { mFreeTimeNode = false })
        end
    end

    -- self:isEnd(PageInfo.leftTime > 0)
    self:isEnd(true)
    local titleText = self.container:getVarLabelBMFont("mDiscountTxt")

    titleText:setFntFile(shootItemData[self.id].titleFntFile)

    labelText = {
        mFreeText = common:getLanguageString("@SuitShootFree1Text"),
        mCostTxt1 = common:getLanguageString("@SuitOneTime"),
        mConstNum = PageInfo.singleCost[self.id],
        mSuitTenTimes = common:getLanguageString("@SuitTenTimes"),
        mDiamondText = PageInfo.tenCost[self.id],
        mFreeTime = "",
        mDiscountTxt = common:getLanguageString(shootItemData[self.id].titleText)
    }
    NodeHelper:setNodesVisible(self.container, { mFreeTimeNode = false })
    NodeHelper:setStringForLabel(self.container, labelText)

    local itemImageData = shootItemData[self.id]
    -- local mBG = self.container:getVarSprite("mBG")   --背景
    -- mBG:setTexture(itemImageData.bgImage)

    local titleImage = self.container:getVarSprite("mTitleImage")
    titleImage:setTexture(itemImageData.titleImage)

    local spineNode = self.container:getVarNode("mSpine")
    if spineNode:getChildByTag(10086) == nil then
        spineNode:removeAllChildren()
        local roldData = ConfigManager.getRoleCfg()[shootItemData[self.id].spineId]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        -- local spine = SpineContainer:create(spinePath, spineName)
        -- local spineToNode = tolua.cast(spine, "CCNode")
        -- spineNode:addChild(spineToNode)
        -- spineToNode:setTag(10086)
        -- spine:runAnimation(1, "Stand", -1)
        --
        -- local offset_X_Str, offset_Y_Str = unpack(common:split((itemImageData.spinePosOffset), ","))
        -- NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        -- spineToNode:setScale(itemImageData.spineScale)

        local scale = NodeHelper:getScaleProportion()
        if scale > 1 then
            -- 适配动画
            NodeHelper:autoAdjustResetNodePosition(spineToNode, 0.5)
            -- spineToNode:setScale(spineToNode:getScale() / scale + spineToNode:getScale() )
        end
    end

    if self.isAdjust == false then
        -- NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))

        local rect = CCRectMake(0, 0, 221, 695)
        local bgMap = {
            mBGKuang = {
                name = itemImageData.bgKuangImgae,
                rect = rect
            }
        }
        local capInsets = {
            left = 0,
            right = 0,
            top = 292,
            bottom = 341
        }
        NodeHelper:setScale9SpriteImage(self.container, bgMap, { mBGKuang = capInsets }, { mBGKuang = CCSizeMake(221, 755) })
        NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mBGKuang"))
        --NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
        -- NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mSpine"):getParent())
        self.isAdjust = true
    end

    local mBtmNode = self.container:getVarNode("mBtmNode")

    mBtmNode:setPositionY(-3)
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))

    local labelText = { }
    labelText.mDiamondText = tostring(PageInfo.tenCost[self.id])
    labelText.mCostNum = tostring(PageInfo.singleCost[self.id])
    NodeHelper:setStringForLabel(self.container, labelText)
end


function ShootItem:onShowItemInfo(container, itemInfo, rewardIndex)
    local rewardItems = { }
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } )
        end
    end
    GameUtil:showTip(container:getVarNode("mFrame" .. rewardIndex), rewardItems[rewardIndex])
end

function ShootItem:onRewardBtn(container)
    local index = self.id
    if thisActivityInfo.gotAwardCfgId[index] then
        MessageBoxPage:Msg_Box_Lan("@VipWelfareAlreadyReceive")
        return
    end
    local msg = Activity_pb.HPAccLoginAwards()
    msg.rewwardDay = index
    common:sendPacket(opcodes.ACC_LOGIN_AWARDS_C, msg)
end
-------------------------------------------

function ShootActitityPage:GodEquipBuildEvent(container, isSingle)
    if ReqAnim.isAnimationRuning then
        return
    end
    --    if ReqAnim.isFirst then
    --        ReqAnim.isSingle = isSingle;

    --        ReqAnim.isFirst = false
    --        return
    --    end
    UserInfo.sync()
    local bagSize = UserInfo.stateInfo.currentEquipBagSize or 40
    local count = UserEquipManager:countEquipAll()
    local needtips = count >= bagSize
    needtips = false
    -- 屏蔽掉提示
    --[[local willgetCount = 10;
    if isSingle then
        willgetCount = 1
    end
    if bagSize - count < willgetCount then
        needtips = true
    end]]
    --
    if needtips then
        local title = common:getLanguageString("@EquipBagFullTitle")
        local msg = common:getLanguageString("@EquipBagFullMsg")
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                -- PageManager.refreshPage("ActivityPage","GodEquipBuild")
                -- MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn" , nil)
                MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn", nil)
                MainFrame_onBackpackPageBtn();
            end
        end )
        return
    end
    local msg = Activity2_pb.HPShootStartReq()
    msg.shootType = PageInfo.shootType
    local freeType = 1
    -- 1,免费 2,钻石
    local shootCount = 1
    -- 1,单抽 10,十连抽
    local needGold = PageInfo.tenCost[PageInfo.shootType]
    if not isSingle then
        -- 十连抽
        freeType = 2
        shootCount = 10
    else
        shootCount = 1
        needGold = PageInfo.singleCost[PageInfo.shootType]
        if PageInfo.freeTimes and PageInfo.freeTimes[PageInfo.shootType] > 0 then
            -- 免费次数在倒计时中
            freeType = 2
        end
    end
    if (isSingle and(PageInfo.freeTimes and PageInfo.freeTimes[PageInfo.shootType] > 0) and UserInfo.playerInfo.gold < needGold) or(not isSingle and UserInfo.playerInfo.gold < needGold) then
        common:rechargePageFlag("ShootActitityPage")
        return
    end
    msg.freeType = freeType
    msg.shootCount = shootCount
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.SHOOT_START_C, pb, #pb, true)
end
function ShootActitityPage:onHand(container, eventName)
    local index = tonumber(string.sub(eventName, 7, string.len(eventName)))
    local _type, _id, _count = unpack(common:split(alreadyShowReward[PageInfo.shootType][index], "_"))
    local items = { }
    table.insert(items, {
        type = tonumber(_type),
        itemId = tonumber(_id),
        count = tonumber(_count)
    } )
    GameUtil:showTip(container:getVarNode("mPic" .. index), items[1])
end

-- 页签点击事件
function ShootActitityPage:onLevel(container, eventName)
    local index = tonumber(string.sub(eventName, 8, string.len(eventName)))
    if index == PageInfo.shootType then return end
    if ReqAnim.isAnimationRuning then return end
    PageInfo.shootType = index
    self:HideRewardNode(container)
    ReqAnim.showNewReward = { }
    self:refreshPage(container)
end

-- 免费一次
function ShootActitityPage:onFree(container)
    ShootActitityPage:GodEquipBuildEvent(container, true)
end

-- 钻石抽奖
function ShootActitityPage:onDiamond(container)
    ShootActitityPage:GodEquipBuildEvent(container, false)
end

-- 奖励预览
function ShootActitityPage:onRewardPreview(container)
    RegisterLuaPage("GodEquipPreview")
    local previewCfg = ConfigManager.getShootEquipPreviewCfg()
    local showPreviewData = { }
    for k, v in pairs(previewCfg) do
        if v.group == PageInfo.shootType and v.stage == ActivityInfo.shootActivityRewardState then
            showPreviewData[#showPreviewData + 1] = v
        end
    end

    local helpKey = ""
    if PageInfo.shootType == 1 and ActivityInfo.shootActivityRewardState == 1 then
        helpKey = GameConfig.HelpKey.HELP_SHEJI_A_DIJI
    end

    if PageInfo.shootType == 1 and ActivityInfo.shootActivityRewardState == 2 then
        helpKey = GameConfig.HelpKey.HELP_SHEJI_B_DIJI
    end

    if PageInfo.shootType == 2 and ActivityInfo.shootActivityRewardState == 1 then
        helpKey = GameConfig.HelpKey.HELP_SHEJI_A_ZHONGJI
    end

    if PageInfo.shootType == 2 and ActivityInfo.shootActivityRewardState == 2 then
        helpKey = GameConfig.HelpKey.HELP_SHEJI_B_ZHONGJI
    end

    if PageInfo.shootType == 3 and ActivityInfo.shootActivityRewardState == 1 then
        helpKey = GameConfig.HelpKey.HELP_SHEJI_A_GAOJI
    end

    if PageInfo.shootType == 3 and ActivityInfo.shootActivityRewardState == 2 then
        helpKey = GameConfig.HelpKey.HELP_SHEJI_B_GAOJI
    end

    local isTenMust = ShootActitityPage:checkIsMust(showPreviewData)
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
        PageManager.pushPage("GodEquipPreview")
    end
end

function ShootActitityPage:checkIsMust(itemInfo)
    for k, v in pairs(itemInfo) do
        if v.tenMust == 1 then
            return true
        end
    end
    return false
end

function ShootActitityPage:onIllustatedOpen(container)
    PageManager.pushPage("SuitDisplayPage")
end
function ShootActitityPage:onBackpackOpen(container)
    PackagePage_showEquipItems()
    PackagePage_setAct(90)
    MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn", nil)
    MainFrame_onBackpackPageBtn()
end

-- ShootActitityPage.onFunction = function(eventName, container)
-- 	if option.handlerMap[eventName] ~= nil then
-- 		local funcName = option.handlerMap[eventName]
-- 		xpcall(function()
-- 		  if ShootActitityPage[funcName] then
-- 			ShootActitityPage[funcName]( container, eventName)
-- 		 end
-- 		end,CocoLog)

-- 	else
-- 		CCLuaLog("error===>unExpected event Name : " .. pageName .. "->" .. eventName)
-- 	end
-- end

function ShootActitityPage:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container

    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mScale9Sprite2"))
    NodeHelper:autoAdjustResizeScrollview(self.container:getVarScrollView("mContent"))
    luaCreat_ShootActitityPage(container)
    GodEquipContent.AllContainer = { }
    EquipCfg = ConfigManager.getEquipCfg()
    GodEquipBuildCfg = ConfigManager.getGodEquipBuildCfg()

    ReqAnim = {
        isSingle = false,
        isFirst = false,
        isAnimationRuning = false,
        showNewReward = { }
    }
    ShootActitityPage.mShootItemTabel = { }
    PageInfo.shootType = 1
    NodeHelper:setNodesVisible(container, { mCDNode = false })
    NodeHelper:setNodesVisible(container, { mDoubleNode = false })
    ---------------------------------------------隐藏奖励节点
    self:ClearALreadyShowReward(0)
    self:HideRewardNode(container)
    -- NodeHelper:setNodesVisible(container, {mBackpackPagePoint = false})--红点
    ---------------------------------------------隐藏奖励节点
    self:registerPacket(ParentContainer)
    isReceiveData = false
    self:getActivityInfo()

    local deviceHeight = CCDirector:sharedDirector():getWinSize().height
    if deviceHeight < 900 then
        -- ipad 版本缩放
        self.container:getVarNode("mMidNode"):setScale(0.7)
    end
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"), 0.5)
    -- NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite1"))
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))

    self.mScrollView = container:getVarScrollView("mContent")
    self.mScrollView:setTouchEnabled(false)
    self:refreshPage(container)
    self:setItemBtnIsShow(false)

    if GameConfig.isIOSAuditVersion then
        NodeHelper:setNodesVisible(container, { mIllustatedbtn = false })
    end

    return container
end

function ShootActitityPage:setItemBtnIsShow(bl)
    for k, v in ipairs(ShootActitityPage.mShootItemTabel) do
        if v then
            v:isEnd(bl)
        end
    end
end

-- 绑定item节点
function ShootActitityPage:rebuildAllItem(container)
    if ShootActitityPage.mShootItemTabel == nil or #ShootActitityPage.mShootItemTabel == 0 then
        ShootActitityPage.mShootItemTabel = { }
        self.mScrollView:removeAllCell()
        for i = 1, 3 do
            local titleCell = CCBFileCell:create()
            local panel = ShootItem:new( { id = i, shootActitityPageContainer = self.container, isAdjust = false })
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(itemCCBFiel)
            self.mScrollView:addCellBack(titleCell)
            ShootActitityPage.mShootItemTabel[i] = panel
        end
        self.mScrollView:orderCCBFileCells()
    end
end

function ShootActitityPage:setShootTypeButton(container, shootType)
    local selectedMap = {
        mLevel1 = shootType == 1,
        mLevel2 = shootType == 2,
        mLevel3 = shootType == 3,
    }

    NodeHelper:setMenuItemSelected(container, selectedMap)
    for i = 1, 3 do
        NodeHelper:setMenuItemEnabled(container, "mLevel" .. i, shootType ~= i)
    end
    local visibleMap = { }
    visibleMap["mSuiticonLevel1"] = shootType == 1
    visibleMap["mSuiticonLevel2"] = shootType == 2
    visibleMap["mSuiticonLevel3"] = shootType == 3
    NodeHelper:setNodesVisible(container, visibleMap)
end

function ShootActitityPage:HideRewardNode(container)
    local visibleMap = { }
    for i = 1, 10 do
        visibleMap["mRewardNode" .. i] = false
    end

    local aniShadeVisible = false
    if alreadyShowReward[PageInfo.shootType] and #alreadyShowReward[PageInfo.shootType] > 0 then
        --[[
		ReqAnim.isAnimationRuning = true
		NodeHelper:setNodesVisible(container, { mBackpackbtn = false,mIllustatedbtn = false,mRewardBtn = false})
        NodeHelper:setMenuItemEnabled( container, "mDiamond", false);
        NodeHelper:setMenuItemEnabled( container, "mFree", false);
		self:refreshRewardNode(container,1)
	--]]
        for i = 1, #alreadyShowReward[PageInfo.shootType] do
            visibleMap["mRewardNode" .. i] = true
            local reward = alreadyShowReward[PageInfo.shootType][i]
            local rewardItems = { }
            local _type, _id, _count = unpack(common:split(reward, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count),
            } );
            NodeHelper:fillRewardItemWithParams(container, rewardItems, 1, { startIndex = i, frameNode = "mHand", countNode = "mNumber" })
        end
        aniShadeVisible = true
        -- container:runAnimation("ShowItem")
    end
    NodeHelper:setNodesVisible(container, visibleMap)
    if not aniShadeVisible then
        -- container:runAnimation("StandAni")
    end
    -- NodeHelper:setNodeVisible(container:getVarNode("mAniShade"),aniShadeVisible)
end

function ShootActitityPage:setTypeMenuEnabled(container, enable)
    for i = 1, 3 do
        if i ~= PageInfo.shootType then
            NodeHelper:setMenuItemEnabled(container, "mLevel" .. i, enable)
        end
    end
end

function ShootActitityPage:ClearALreadyShowReward(hideType)
    if hideType == 0 then
        alreadyShowReward = { [1] = { }, [2] = { }, [3] = { } }
    else
        alreadyShowReward[hideType] = { }
    end
end

function ShootActitityPage:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if string.sub(animationName, 1, 8) == "ItemAni_" then
        local index = tonumber(string.sub(animationName, -2))
        if index < #alreadyShowReward[PageInfo.shootType] then
            self:refreshRewardNode(container, index + 1)
        else
            -- 播放完毕
            NodeHelper:setNodesVisible(container, { mBackpackbtn = true, mIllustatedbtn = true, mRewardBtn = true })
            NodeHelper:setMenuItemEnabled(container, "mDiamond", true)
            NodeHelper:setMenuItemEnabled(container, "mFree", true)
            --
            local rewardItems = { }
            if #ReqAnim.showNewReward > 0 then
                for i = 1, #ReqAnim.showNewReward do
                    local _type, _id, _count = unpack(common:split(ReqAnim.showNewReward[i], "_"));
                    table.insert(rewardItems, {
                        itemType = tonumber(_type),
                        itemId = tonumber(_id),
                        itemCount = tonumber(_count)
                    } )
                end
            end
            NodeHelper:showRewardText(container, rewardItems)
            -- ReqAnim.showNewReward = {}
            ReqAnim.isAnimationRuning = false
            if #ReqAnim.showNewReward > 0 then
                self:getActivityInfo()
            end

            if #rewardItems == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
        end
    end
    -- if animationName == "ClickAni" then
    --    ShootActitityPage:GodEquipBuildEvent(container,ReqAnim.isSingle);
    -- end
end
function ShootActitityPage:refreshRewardNode(container, index)
    local visibleMap = { }
    visibleMap["mRewardNode" .. index] = true

    local reward = alreadyShowReward[PageInfo.shootType][index]
    local rewardItems = { }
    local _type, _id, _count = unpack(common:split(reward, "_"))
    table.insert(rewardItems, {
        type = tonumber(_type),
        itemId = tonumber(_id),
        count = tonumber(_count),
    } )
    NodeHelper:fillRewardItemWithParams(container, rewardItems, 1, { startIndex = index, frameNode = "mHand", countNode = "mNumber" })
    NodeHelper:setNodesVisible(container, visibleMap)
    local Aniname = tostring(index)
    if index < 10 then
        Aniname = "0" .. Aniname
    end

    container:runAnimation("ItemAni_" .. Aniname)
end
function ShootActitityPage:refreshPage(container)
    self:rebuildAllItem(container)

    UserInfo.sync()

    self:setShootTypeButton(container, PageInfo.shootType)
    NodeHelper:setNodesVisible(container, { mDoubleNode = true })
    local labelText = { }
    if PageInfo.leftTime > 0 then
        lasttime = PageInfo.leftTime
        TimeCalculator:getInstance():createTimeCalcultor(PageInfo.timerName, PageInfo.leftTime)
    else
        labelText.mTanabataCD = common:getLanguageString("@ActivityEnd")
    end

    -- NodeHelper:setSpriteImage(container, { mShootBG = "UI/Common/BG/Act_TL_Shoot_BG_" .. PageInfo.shootType .. ".png" })

    local tipVisible =
    -- 标签上红点显示
    {
        mBtnPoint1 = false,
        mBtnPoint2 = false,
        mBtnPoint3 = false,
    }
    local showNotice = false
    -- for k,v in ipairs(PageInfo.freeTimes)do
    -- 	if v > 0 then
    -- 		TimeCalculator:getInstance():createTimeCalcultor(PageInfo.freeTimesCDName[k], v)
    -- 	elseif PageInfo.shootType == k then
    -- 		NodeHelper:setNodesVisible(container, {mFreeText = true,mCostNodeVar = false,mSuitFreeTime = false})
    -- 	end
    -- 	if v <= 0 then
    -- 		tipVisible["mBtnPoint"..k] = true
    -- 		showNotice = true
    -- 	end
    -- end

    --    for k, v in ipairs(PageInfo.freeTimes) do
    --        if v > 0 then
    --           showNotice = false
    --        else
    --           showNotice = true
    --        end
    --    end

    for k, v in ipairs(PageInfo.freeTimes) do
        if v <= 0 then
            showNotice = true
            break
        end
    end

    if not showNotice and isReceiveData then
        ActivityInfo.changeActivityNotice(Const_pb.SHOOT_ACTIVITY)
    end

    labelText.mDiamondNum = UserInfo.playerInfo.gold
    labelText.mDiamondText = tostring(PageInfo.tenCost[PageInfo.shootType])
    labelText.mCostNum = tostring(PageInfo.singleCost[PageInfo.shootType])
    NodeHelper:setStringForLabel(container, labelText)
    NodeHelper:setNodesVisible(container, tipVisible)
    NodeHelper:setNodesVisible(container, { mFreeBtnNode = true, mDiamondBtnNode = true })

    self:refreshEquipBagInfo(container)

    for k, v in ipairs(ShootActitityPage.mShootItemTabel) do
        if v then
            v:refresh()
        end
    end

    -- ShootActitityPage.mShootItemTabel[PageInfo.shootType]:refresh()
end
function ShootActitityPage:refreshEquipBagInfo(container)
    UserInfo.sync()
    local bagSize = UserInfo.stateInfo.currentEquipBagSize or 40
    local count = UserEquipManager:countEquipAll()
    NodeHelper:setNodesVisible(container, { mBackpackPagePoint = count >= bagSize })
    -- 红点
    NodeHelper:setStringForLabel(container, { mBackpackNum = count .. "/" .. bagSize })

end
function ShootActitityPage:onExecute(ParentContainer)
    --    local timeStr = '00:00:00'
    --    if TimeCalculator:getInstance():hasKey(PageInfo.timerName) then
    --        PageInfo.leftTime = TimeCalculator:getInstance():getTimeLeft(PageInfo.timerName)
    --        if PageInfo.leftTime > 0 then
    --            timeStr = common:second2DateString(PageInfo.leftTime, false)
    --        end
    --        if PageInfo.leftTime <= 0 then
    --            timeStr = common:getLanguageString("@ActivityEnd")
    --        end
    --        -- common:getLanguageString("@SurplusTimeFishing") ..
    --        NodeHelper:setStringForLabel(self.container, { mTanabataCD = common:getLanguageString("@ShootPoolTip") .. timeStr })
    --        if (lasttime - PageInfo.leftTime) >= 2 then
    --            -- N秒刷新背包信息一次
    --            lasttime = PageInfo.leftTime
    --            self:refreshEquipBagInfo(self.container);
    --        end
    --    end

    -------------------------------------------------
    -- timeStr = '00:00:00'
    -- for k,v in ipairs( PageInfo.freeTimesCDName ) do
    -- 	if TimeCalculator:getInstance():hasKey(PageInfo.freeTimesCDName[k]) then
    -- 		PageInfo.freeTimes[k] = TimeCalculator:getInstance():getTimeLeft(PageInfo.freeTimesCDName[k])
    -- 		if k == PageInfo.shootType then
    -- 			if PageInfo.freeTimes[k] > 0 then
    -- 				timeStr = GameMaths:formatSecondsToTime(PageInfo.freeTimes[k])
    -- 				NodeHelper:setNodesVisible(self.container, {mFreeText = false,mCostNodeVar = true,mSuitFreeTime = true})
    -- 				NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = common:getLanguageString('@SuitFreeOneTime',timeStr)})
    -- 			else
    -- 				NodeHelper:setNodesVisible(self.container, {mFreeText = true,mCostNodeVar = false,mSuitFreeTime = false})
    -- 			end
    -- 		end
    -- 		if PageInfo.freeTimes[k] <= 0 then
    -- 			local tipVisible = {}--标签上红点显示
    -- 			tipVisible["mBtnPoint"..k] = true
    -- 			NodeHelper:setNodesVisible(self.container,tipVisible)
    -- 		end
    -- 	end
    -- end
    -------------------------------------------------
    if ShootActitityPage.mShootItemTabel then
        for k, v in ipairs(ShootActitityPage.mShootItemTabel) do
            v:onExecute()
        end
    end
end
function ShootActitityPage:getActivityInfo()
    common:sendEmptyPacket(opcodes.SHOOT_PANEL_C, false)
end
function ShootActitityPage:RequestFishingEvent(isSingle)

end
function ShootActitityPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == opcodes.SHOOT_PANEL_S then
        local msg = Activity2_pb.HPShootPanelInfoRes()
        msg:ParseFromString(msgBuff)
        isReceiveData = true
        PageInfo.leftTime = msg.leftTime or 0
        local rewardStateId = msg.rewardStateId
        ActivityInfo.shootActivityRewardState = rewardStateId == 1 and 1 or 2
        for k, v in ipairs(msg.freeTime) do
            PageInfo.freeTimes[k] = v
        end
        PageInfo.singleCost = { 250, 300, 350 }
        PageInfo.tenCost = { 2500, 3000, 3500 }
        for k, v in ipairs(msg.shootPriceInfo) do
            PageInfo.singleCost[k] = v.oneTimePrice
            PageInfo.tenCost[k] = v.tenTimePrice
        end
        self:refreshPage(self.container)
    elseif opcode == opcodes.SHOOT_END_S then
        local msg = Activity2_pb.HPShootEndInfo()
        msg:ParseFromString(msgBuff)
        ReqAnim.showNewReward = { }
        ReqAnim.showNewReward = msg.reward

        ------------------------------------------
        self:pushRewardPage()
        self:getActivityInfo()
        ------------------------------------------

        --        local reward = msg.reward
        --        local beginIndex = 1;
        --        if (#alreadyShowReward[PageInfo.shootType] + #reward) > COUNT_LIMIT then
        --            self:HideRewardNode(self.container);
        --            self:ClearALreadyShowReward(PageInfo.shootType)
        --        else
        --            beginIndex = #alreadyShowReward[PageInfo.shootType] + 1;
        --        end
        --        for i = 1, #reward do
        --            alreadyShowReward[PageInfo.shootType][#alreadyShowReward[PageInfo.shootType] + 1] = reward[i]
        --        end

        --        NodeHelper:setNodesVisible(self.container, { mBackpackbtn = false, mIllustatedbtn = false, mRewardBtn = false })
        --        NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false);
        --        NodeHelper:setMenuItemEnabled(self.container, "mFree", false);
        --        ReqAnim.isAnimationRuning = true
        --        -- self:setTitlePage(self.container)
        --        self:refreshRewardNode(self.container, beginIndex);
    end
end

function ShootActitityPage:pushRewardPage()
    local onceGold = PageInfo.singleCost[PageInfo.shootType]
    local tenGold = PageInfo.tenCost[PageInfo.shootType]
    local reward = ReqAnim.showNewReward
    local isFree = PageInfo.freeTimes[PageInfo.shootType] <= 0
    isFree = false
    local freeCount = 0
    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", false, ShootActitityPage.onFree, ShootActitityPage.onDiamond, function()
            if #ReqAnim.showNewReward == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
            self:getActivityInfo()
        end )
    else
        CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", true, ShootActitityPage.onFree, ShootActitityPage.onDiamond, nil)
    end
end

function ShootActitityPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function ShootActitityPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end
function ShootActitityPage:onExit(ParentContainer)
    self:removePacket(ParentContainer)

    for k, v in ipairs(PageInfo.freeTimesCDName) do
        TimeCalculator:getInstance():removeTimeCalcultor(v)
    end
    TimeCalculator:getInstance():removeTimeCalcultor(PageInfo.timerName)
    onUnload(thisPageName, self.container)
    --if not GameConfig.isReBackVer28 then 
    if self.mScrollView then
        self.mScrollView:removeAllCell()
        self.mScrollView = nil
    end
    --end
    self.container = nil
end
function ShootActitityPage:onClose(container, name)
    PageManager.refreshPage("ActivityPage")
    PageManager.popPage(thisPageName)
end
function ShootActitityPage:onHelp(container, name)
    PageManager.showHelp(GameConfig.HelpKey.HELP_SHOOTACTIVITY)
end
local CommonPage = require("CommonPage")
ShootActitityPage = CommonPage.newSub(ShootActitityPage, thisPageName, option)

return ShootActitityPage
