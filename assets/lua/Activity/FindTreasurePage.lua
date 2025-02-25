local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "FindTreasurePage"
local Activity_pb = require("Activity_pb")
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")

local ItemManager = require "Item.ItemManager"
local FindTreasurePage = {}
local EquipCfg = {}
local GodEquipBuildCfg = {}

local ReqAnim = 
{
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = {}
}
local opcodes = {
    FIND_TREASURE_INFO_S = HP_pb.FIND_TREASURE_INFO_S,
    FIND_TREASURE_SEARCH_S = HP_pb.FIND_TREASURE_SEARCH_S,
}
local option = {
    ccbiFile = "Act_TimeLimitSilverMoonContent.ccbi",
    handlerMap = {
        onReturnButton = "onClose",
        onHelp      = "onHelp",
        onIllustatedOpen = "onIllustatedOpen",
        onBackpackOpen = "onBackpackOpen",
        onReceive   = "onReceive",
        onWishing =  "onWishing",
        onFree = "onFree",
        onDiamond = "onDiamond",
        onRewardPreview = "onRewardPreview"
    }
}
for i = 1, 10 do
    option.handlerMap["onHand" ..i] = "onHand"
end
for i = 1, 3 do
    option.handlerMap["onLevel" ..i] = "onLevel"
end
--当前页面信息
local PageInfo = {
    reward = {},
    cost = {},
    leftTime = 0,
    leftTimes = {},
    allEquip = { },
    timerName = "FindTreasurePage",
    shootType = 1,	--(1：初级,2:中级,3:高级)
}
local alreadyShowReward = {} --界面上已经显示的奖励
local needShowReward = {} --当前锻造的奖励
local COUNT_LIMIT = 10
local lasttime = 0 --用于计算时间差

function FindTreasurePage:GodEquipBuildEvent(container, isSingle)
    local count = 10
    if PageInfo.leftTimes[PageInfo.shootType] < 10 and PageInfo.leftTimes[PageInfo.shootType] > 0 then
    	count = PageInfo.leftTimes[PageInfo.shootType]
    end
    local needGold = PageInfo.cost[PageInfo.shootType] * count
    if isSingle then --一次  否则10次
    	needGold = PageInfo.cost[PageInfo.shootType]
    end
    if PageInfo.shootType ~= 1 and UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("TreasureRaiderBase")
        return
    elseif PageInfo.shootType == 1 and UserInfo.playerInfo.coin < needGold then 
        MessageBoxPage:Msg_Box_Lan("@CoinNotEnough")
        return
    end
    if ReqAnim.isAnimationRuning then
        return
    end
    if ReqAnim.isFirst then
        ReqAnim.isSingle = isSingle
        --container:runAnimation("ClickAni")
        ReqAnim.isFirst = false
        return 
    end
    UserInfo.sync()
    local bagSize = UserInfo.stateInfo.currentEquipBagSize or 40
    local count = UserEquipManager:countEquipAll()
    local needtips = count >= bagSize
    needtips = false-- 屏蔽掉提示

    if needtips then
        local title = common:getLanguageString("@EquipBagFullTitle")
        local msg = common:getLanguageString("@EquipBagFullMsg")
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
	        --PageManager.refreshPage("ActivityPage","GodEquipBuild")
                -- MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn" , nil)
                MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn" , nil)
                MainFrame_onBackpackPageBtn()
            end
        end)
        return 
    end

    local msg = Activity2_pb.HPFindTreasureLight()
    msg.type = PageInfo.shootType
    local shootCount = 1 --1,单抽 10,十连抽
    if not isSingle then	--十连抽
        shootCount = 10
        if PageInfo.leftTimes[PageInfo.shootType] < 10 and PageInfo.leftTimes[PageInfo.shootType] > 0 then
            shootCount = PageInfo.leftTimes[PageInfo.shootType]
        end
    else
        shootCount = 1
    end
    msg.times = shootCount
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.FIND_TREASURE_SEARCH_C, pb, #pb, true)
end
function FindTreasurePage:onHand(container, eventName)
    local index = tonumber(string.sub(eventName, 7, string.len(eventName)))
    local reward =  PageInfo.reward[PageInfo.shootType][alreadyShowReward[PageInfo.shootType][index]]
    GameUtil:showTip(container:getVarNode("mPic" .. index), reward)
end
function FindTreasurePage:onLevel(container, eventName)
    local index = tonumber(string.sub(eventName, 8, string.len(eventName)))
    if index == PageInfo.shootType then return end
    if ReqAnim.isAnimationRuning then return end
    PageInfo.shootType = index
    self:HideRewardNode(container)
    ReqAnim.showNewReward = {}
    self:refreshPage(container)
end

function FindTreasurePage:onFree(container)
    if PageInfo.leftTimes[PageInfo.shootType] < 1 then
        MessageBoxPage:Msg_Box_Lan("@FindTreasureNotEnoughTimes")
        return
    end
    FindTreasurePage:GodEquipBuildEvent(container, true)
end
function FindTreasurePage:onDiamond(container)
    if PageInfo.leftTimes[PageInfo.shootType] < 1 then
        MessageBoxPage:Msg_Box_Lan("@FindTreasureNotEnoughTimes")
        return
    end
    FindTreasurePage:GodEquipBuildEvent(container, false)
end
function FindTreasurePage:onRewardPreview(container)
    RegisterLuaPage("GodEquipPreview")
    ShowEquipPreviewPage(PageInfo.reward[PageInfo.shootType], common:getLanguageString("@RewardPreviewTitle"), common:getLanguageString("@ForgingPoolShowMsg"))
    PageManager.pushPage("GodEquipPreview")
end

function FindTreasurePage:onIllustatedOpen(container)
    require("SuitDisplayPage")
    SuitDisplayPageBase_setEquip(12)
    PageManager.pushPage("SuitDisplayPage")
end
function FindTreasurePage:onBackpackOpen(container)
    PackagePage_showEquipItems()
    MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn", nil)
    MainFrame_onBackpackPageBtn()
end

-- FindTreasurePage.onFunction = function(eventName, container)
-- 	if option.handlerMap[eventName] ~= nil then
-- 		local funcName = option.handlerMap[eventName]			
-- 		xpcall(function()			
-- 		  if FindTreasurePage[funcName] then
-- 			FindTreasurePage[funcName]( container, eventName)
-- 		 end
-- 		end,CocoLog)
		
-- 	else
-- 		CCLuaLog("error===>unExpected event Name : " .. pageName .. "->" .. eventName)
-- 	end
-- end

function FindTreasurePage:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    luaCreat_FindTreasurePage(container)
    EquipCfg = ConfigManager.getEquipCfg()
    GodEquipBuildCfg = ConfigManager.getGodEquipBuildCfg()
    self:getRewardCfg()
    ReqAnim = {
        isSingle = false,
        isFirst = false,
        isAnimationRuning = false,
        showNewReward = {}
     }

    PageInfo.shootType = 1
    ---------------------------------------------隐藏奖励节点
    self:ClearALreadyShowReward(0)
    self:HideRewardNode(container)
    -- NodeHelper:setNodesVisible(container, {mBackpackPagePoint = false})--红点
    ---------------------------------------------隐藏奖励节点
    self:registerPacket(ParentContainer)
    self:getActivityInfo()
    local deviceHeight = CCDirector:sharedDirector():getWinSize().height
	if deviceHeight < 900 then --ipad 版本缩放
    	-- self.container:getVarNode("mMidNode"):setScale(0.7)
    end
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
	NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite1"))
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))    
    return container
end

function FindTreasurePage:getRewardCfg()
    for i = 1, 3 do
        PageInfo.reward[i] = {}
    end
    table.foreachi(ConfigManager.getFindTreasureCfg(), function(k, v)
        table.insert(PageInfo.reward[v.type], v.reward)
        if PageInfo.cost[v.type] == nil then
            PageInfo.cost[v.type] = v.cost
        end
    end)
end

function FindTreasurePage:setShootTypeButton(container,shootType)
    local selectedMap =  {
        mLevel1 = shootType == 1,
        mLevel2 = shootType == 2,
        mLevel3 = shootType == 3,
    }
	
    NodeHelper:setMenuItemSelected(container, selectedMap)
    for i = 1, 3 do
        NodeHelper:setMenuItemEnabled(container, "mLevel" .. i, shootType ~= i)
    end
    local visibleMap = {}
    visibleMap["mSuiticonLevel1"] = shootType == 1
    visibleMap["mSuiticonLevel2"] = shootType == 2
    visibleMap["mSuiticonLevel3"] = shootType == 3
    NodeHelper:setNodesVisible(container, visibleMap)
end

function FindTreasurePage:HideRewardNode(container)
    local visibleMap = {}
    for i = 1, 10 do
        visibleMap["mRewardNode" .. i] = false
    end
	
    local aniShadeVisible = false
    if alreadyShowReward[PageInfo.shootType] and #alreadyShowReward[PageInfo.shootType] > 0 then
    --[[
        ReqAnim.isAnimationRuning = true
        NodeHelper:setNodesVisible(container, { mBackpackbtn = false, mIllustatedbtn = false, mRewardBtn = false})
        NodeHelper:setMenuItemEnabled( container, "mDiamond", false)
        NodeHelper:setMenuItemEnabled( container, "mFree", false)
        self:refreshRewardNode(container, 1)
    --]]
        for i = 1, #alreadyShowReward[PageInfo.shootType] do
            visibleMap["mRewardNode"..i] = true
            local rewardItems =  PageInfo.reward[PageInfo.shootType][alreadyShowReward[PageInfo.shootType][i]]
            NodeHelper:fillRewardItemWithParams(container, rewardItems, 1, { startIndex = i ,frameNode = "mHand",countNode = "mNumber" })
        end
        aniShadeVisible = true
        -- container:runAnimation("ShowItem")
    end    
    NodeHelper:setNodesVisible(container, visibleMap)
    if not aniShadeVisible then
        -- container:runAnimation("StandAni")
    end
    --NodeHelper:setNodeVisible(container:getVarNode("mAniShade"), aniShadeVisible)
end

function FindTreasurePage:setTypeMenuEnabled(container, enable)
    for i = 1, 3 do 
        if i ~= PageInfo.shootType then
            NodeHelper:setMenuItemEnabled(container, "mLevel" .. i, enable)
        end
    end
end

function FindTreasurePage:ClearALreadyShowReward(hideType)
    if hideType == 0 then
        alreadyShowReward = { [1] = {}, [2] = {}, [3] = {} }
    else
        alreadyShowReward[hideType] = {}
    end
end

function FindTreasurePage:onAnimationDone(container)
    local animationName=tostring(container:getCurAnimationDoneName())
    if string.sub(animationName, 1, 8) == "ItemAni_" then
        local index = tonumber(string.sub(animationName, -2))
        if index < #alreadyShowReward[PageInfo.shootType] then
            self:refreshRewardNode(container, index + 1)
        else
            --播放完毕
            NodeHelper:setNodesVisible(container, { mBackpackbtn = true, mIllustatedbtn = true, mRewardBtn = true})
            NodeHelper:setMenuItemEnabled(container, "mDiamond", true)
            NodeHelper:setMenuItemEnabled(container, "mFree", true)
            --
            local rewardItems = {}
            if #ReqAnim.showNewReward > 0 then
                for i = 1,#ReqAnim.showNewReward do
                    local reward =  PageInfo.reward[PageInfo.shootType][ReqAnim.showNewReward[i]]
                    table.insert(rewardItems, {
                        itemType 	= reward.type,
                        itemId	= reward.itemId,
                        itemCount 	= reward.count
                    })                    
                end
            end
            NodeHelper:showRewardText(container, rewardItems)
            --ReqAnim.showNewReward = {}
            ReqAnim.isAnimationRuning = false
            if #ReqAnim.showNewReward > 0 then
                self:getActivityInfo()
            end
            ---弹出评论界面
            PageManager.showCommentPage(rewardItems)
        end
    end
    --if animationName == "ClickAni" then
    --    FindTreasurePage:GodEquipBuildEvent(container, ReqAnim.isSingle)
    --end
end
function FindTreasurePage:refreshRewardNode(container, index)
    local visibleMap = {}
    visibleMap["mRewardNode" .. index] = true
    local reward = PageInfo.reward[PageInfo.shootType][alreadyShowReward[PageInfo.shootType][index]]
    NodeHelper:fillRewardItemWithParams(container, { reward }, 1, { startIndex = index, frameNode = "mHand", countNode = "mNumber" })
    NodeHelper:setNodesVisible(container, visibleMap)
    local Aniname = tostring(index)
    if index < 10 then
        Aniname = "0" .. Aniname
    end
    
    container:runAnimation("ItemAni_" .. Aniname)
end
function FindTreasurePage:refreshPage(container)
    UserInfo.sync()
	
    self:setShootTypeButton(container,PageInfo.shootType)
    local labelText = {}
    if PageInfo.leftTime > 0 then
        lasttime = PageInfo.leftTime
        TimeCalculator:getInstance():createTimeCalcultor(PageInfo.timerName, PageInfo.leftTime)
    else
        labelText.mTanabataCD = common:getLanguageString("@ActivityEnd")
    end

    -- NodeHelper:setSpriteImage(container, {mShootBG = "UI/Common/BG/Act_TL_Shoot_BG_"..PageInfo.shootType..".png"})

    local tipVisible = --标签上红点显示 
    {
        mBtnPoint1 = false,
        mBtnPoint2 = false,
        mBtnPoint3 = false,
    }

    labelText.mDiamondNum = UserInfo.playerInfo.gold

    if PageInfo.leftTimes[PageInfo.shootType] < 1 then
    	tipVisible.mCostNodeVar = false
    	tipVisible.mCostNodeTen = false
    	tipVisible.mFreeText = true
    	tipVisible.mCloseText = true
    	NodeHelper:setMenuItemsEnabled(container, { mFree = false, mDiamond = false })
    else
    	NodeHelper:setMenuItemsEnabled(container, { mFree = true, mDiamond = true })
    	tipVisible.mCostNodeVar = true
    	tipVisible.mCostNodeTen = true
    	tipVisible.mFreeText = false
    	tipVisible.mCloseText = false    	
        local count = 10
        if PageInfo.leftTimes[PageInfo.shootType] < 10 and PageInfo.leftTimes[PageInfo.shootType] > 0 then
            count = PageInfo.leftTimes[PageInfo.shootType]
        end
        labelText.mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", count)
        labelText.mDiamondText = tostring(GameUtil:formatNumber(PageInfo.cost[PageInfo.shootType] * count))
        labelText.mCostNum = tostring(GameUtil:formatNumber(PageInfo.cost[PageInfo.shootType]))

        NodeHelper:setNodesVisible(container, { mGold1 = PageInfo.shootType ~= 1,
                                                mGold2 = PageInfo.shootType ~= 1,
                                                mCoin1 = PageInfo.shootType == 1,
                                                mCoin2 = PageInfo.shootType == 1
        })	    
    end
    labelText.mLimetTimes = ""
    if PageInfo.leftTimes[PageInfo.shootType] < 1000 then
    	labelText.mLimetTimes = common:getLanguageString("@SilverMoonLimitTime",PageInfo.leftTimes[PageInfo.shootType])
    end	
    NodeHelper:setStringForLabel(container,labelText)
    NodeHelper:setNodesVisible(container,tipVisible)

    self:refreshEquipBagInfo(container)
end
function FindTreasurePage:refreshEquipBagInfo(container)
    UserInfo.sync()
    local bagSize = UserInfo.stateInfo.currentEquipBagSize or 40
    local count = UserEquipManager:countEquipAll()
    NodeHelper:setNodesVisible(container, { mBackpackPagePoint = count >= bagSize })--红点
    NodeHelper:setStringForLabel(container, { mBackpackNum = count.."/"..bagSize })
end
function FindTreasurePage:onExecute(ParentContainer)
    local timeStr = "00:00:00"
    if TimeCalculator:getInstance():hasKey(PageInfo.timerName) then
        PageInfo.leftTime = TimeCalculator:getInstance():getTimeLeft(PageInfo.timerName)
        if PageInfo.leftTime > 0 then
            timeStr = common:second2DateString(PageInfo.leftTime, false)
        end
        if PageInfo.leftTime <= 0 then
            timeStr = common:getLanguageString("@ActivityEnd")
        end
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr })
        if (lasttime - PageInfo.leftTime) >= 2 then --N秒刷新背包信息一次
            lasttime = PageInfo.leftTime
            self:refreshEquipBagInfo(self.container)
        end
    end
end
function FindTreasurePage:getActivityInfo()
    common:sendEmptyPacket(HP_pb.FIND_TREASURE_INFO_C)
end
function FindTreasurePage:RequestFishingEvent(isSingle)
    
end
function FindTreasurePage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == opcodes.FIND_TREASURE_INFO_S then
        local msg = Activity2_pb.HPFindTreasureInfoRet()
        msg:ParseFromString(msgBuff)
        PageInfo.leftTime = msg.leftTime
        for k, v in ipairs(msg.leftSearchTimes) do 
            PageInfo.leftTimes[k] = v
        end		
        self:refreshPage(self.container)
    elseif opcode == opcodes.FIND_TREASURE_SEARCH_S then
        local msg = Activity2_pb.HPFindTreasureLightRet()
        msg:ParseFromString(msgBuff)
        PageInfo.shootType = msg.type
        PageInfo.leftTimes[msg.type] = msg.leftSearchTimes
        ReqAnim.showNewReward = msg.rewardId
        local reward = msg.rewardId
        local beginIndex = 1
        if (#alreadyShowReward[PageInfo.shootType] + #reward) > COUNT_LIMIT then
            self:HideRewardNode(self.container)
            self:ClearALreadyShowReward(PageInfo.shootType)
        else
            beginIndex = #alreadyShowReward[PageInfo.shootType] + 1
        end
        for i = 1, #reward do
            alreadyShowReward[PageInfo.shootType][#alreadyShowReward[PageInfo.shootType]+1] = reward[i]
        end

        NodeHelper:setNodesVisible(self.container, { mBackpackbtn = false,mIllustatedbtn = false,mRewardBtn = false })
        NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false)
        NodeHelper:setMenuItemEnabled(self.container, "mFree", false)
        ReqAnim.isAnimationRuning = true
        -- self:setTitlePage(self.container)
        self:refreshRewardNode(self.container, beginIndex)
    end
end

function FindTreasurePage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function FindTreasurePage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end
function FindTreasurePage:onExit(ParentContainer)
    self:removePacket(ParentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(PageInfo.timerName)
    onUnload(thisPageName, self.container)
    self.container = nil
end
function FindTreasurePage:onHelp(container, name)
    PageManager.showHelp(GameConfig.HelpKey.HELP_SHOOTACTIVITY)
end
local CommonPage = require("CommonPage")
local FindTreasurePageSub = CommonPage.newSub(FindTreasurePage, thisPageName, option)

return FindTreasurePageSub
