-- Author:Ranjinlan
-- Create Data: [2018-05-09 11:09:14]
-- 寻找命格界面
local FateFindPageBase = {}
local fateBuyCfg = ConfigManager.getFateBuyCfg()
local MysticalDress_pb = require("Badge_pb")
local HP_pb = require("HP_pb")
local FateDataManager = require("FateDataManager")
local UserItemManager = require("Item.UserItemManager")
local sendHuntingId = nil
local huntingLvUpEffect = nil
local mFromRoleId = roleId
local option = {
	ccbiFile = "PrivatePage.ccbi",
	handlerMap = {
        onReturnBtn                = "onReturn",
        onBackpackOpen             = "onBackpackOpen",
        onHelp                     = "onHelp",
	},
	opcode = {
        MYSTICAL_DRESS_ACTIVE_C	= HP_pb.MYSTICAL_DRESS_ACTIVE_C, --激活猎命
        MYSTICAL_DRESS_ACTIVE_S	= HP_pb.MYSTICAL_DRESS_ACTIVE_S,
        MYSTICAL_DRESS_HUNTING_C	= HP_pb.MYSTICAL_DRESS_HUNTING_C, --猎命
        MYSTICAL_DRESS_HUNTING_S	= HP_pb.MYSTICAL_DRESS_HUNTING_S,
        MYSTICAL_HUNTING_INFO_S     = HP_pb.MYSTICAL_HUNTING_INFO_S,
    },
}
local selfContainer,rewardContainer = nil,nil
for i = 1,GameConfig.FatePageConst.maxLightCount do
    option.handlerMap["onFrame" .. i ] = "onClickFateBtn"
    option.handlerMap["onClick" .. i ] = "onActiveFatBtn"
end

function FateFindPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcode) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function FateFindPageBase:removePacket(container)
	for key, opcode in pairs(option.opcode) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function FateFindPageBase:onEnter(container)
    sendHuntingId = nil
    selfContainer = container
    FateFindPageBase:registerPacket(container)
    local imgMap = {}
    for i = 1, GameConfig.FatePageConst.maxLightCount do
        imgMap["mPortrait" .. i] = GameConfig.FateImage[i].icon
    end
    NodeHelper:setSpriteImage(container,imgMap)
    self:refreshPage(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
end

function FateFindPageBase:onExit(container)
    if huntingLvUpEffect then
        huntingLvUpEffect:removeFromParentAndCleanup(true)
        huntingLvUpEffect = nil
    end
    sendHuntingId = nil
    FateFindPageBase:closeReward(container)
    selfContainer = nil
    FateFindPageBase:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
end

--刷新当前拥有道具数量
function FateFindPageBase:refreshCostNum(container)
    local activeCostHaveNum = UserItemManager:getCountByItemId(GameConfig.FatePageConst.activeCostType.itemId) or 0
    local lightCostHaveNum = UserItemManager:getCountByItemId(GameConfig.FatePageConst.lightCostType.itemId) or 0
    local bagSize = GameConfig.BuyDressBagCost.DefaultDressBagSize
    if UserInfo.stateInfo:HasField("currentDressBagSize") then
        bagSize = UserInfo.stateInfo.currentDressBagSize
    end
    local currentSize = FateDataManager:getPackageCount()
    local strMap = {
        mGold = activeCostHaveNum, --激活道具总数量
        mSoulLevelNum = lightCostHaveNum, --点亮道具总数量
        mBackpackNum = currentSize .. "/" .. bagSize,--背包仓库
    }
    local visibleMap = {mBackpackPagePoint = currentSize >= bagSize}
    NodeHelper:setNodesVisible(container, visibleMap)
    for i = 1,GameConfig.FatePageConst.maxLightCount do
        local conf = fateBuyCfg[i]
        local lightCount,activeCont = 0,0
        if conf then
            if conf.lightCost[1]  then
                lightCount = conf.lightCost[1].count or 0
            end
            if conf.activeBuyCost[1] then
                activeCont = conf.activeBuyCost[1].count or 0
            end
        end
        strMap["mCost" .. i] = "x" .. lightCount  --点亮花费数量
        strMap["mSpeicalCost" .. i] = activeCont  --激活花费数量
    end
    NodeHelper:setStringForLabel(container, strMap)
end

function FateFindPageBase:refreshLightState(container)
    local visibleMap = {}
    --所有命格都没点亮
    FateFindPageBase:setPicGray(container,1, true)
    for i = 2,GameConfig.FatePageConst.maxLightCount do
        visibleMap["mClickNode" .. i] = false --所有激活按钮都隐藏
        --所有命格都没点亮
        FateFindPageBase:setPicGray(container,i, true)
    end
    local currentHuntingIndex = FateDataManager.currentHuntingIndex
    if currentHuntingIndex == 1 then
        --显示激活按钮
        for i = 2,GameConfig.FatePageConst.maxLightCount do
            local conf = fateBuyCfg[i]
            if conf and conf.directBuy == 1 then
                visibleMap["mClickNode" .. i] = true --显示激活按钮
            end
        end
    end
    for i = 1,GameConfig.FatePageConst.maxLightCount do
        visibleMap["mPrivateEffect" .. i] = i == currentHuntingIndex
    end
    visibleMap["mPrivateEffect" .. 6] = currentHuntingIndex == GameConfig.FatePageConst.maxLightCount

    FateFindPageBase:setPicGray(container,currentHuntingIndex, false)--显示当前点亮的命格按钮
    NodeHelper:setNodesVisible(container, visibleMap)
end

function FateFindPageBase:setPicGray(container,index, bGray)
    local sprite = container:getVarSprite("mPortrait" .. index)
    if sprite ~= nil then
        sprite:removeAllChildren();
        if bGray then
            local graySprite = GraySprite:new()
	        local texture = sprite:getTexture()
	        local rect = sprite:getTextureRect()
	        graySprite:initWithTexture(texture,rect)
            graySprite:setAnchorPoint(ccp(0,0))
	        sprite:addChild(graySprite)  
        end 
    end 
    local menuItem = container:getVarMenuItemImage("mFrame" .. index)
    if menuItem then
        local sprite = CCSprite:create(GameConfig.FateImage[index].quality)
        if bGray then
            local graySprite = GraySprite:new()
            local texture = sprite:getTexture()
            local size = sprite:getContentSize()
            graySprite:initWithTexture(texture,CCRectMake(0,0,size.width,size.height))
            menuItem:setNormalImage(graySprite)
        else
            menuItem:setNormalImage(sprite)
        end
    end
end

function FateFindPageBase:refreshPage(container)
    FateFindPageBase:refreshCostNum(container)
    FateFindPageBase:refreshLightState(container)
end

--点亮命格
function FateFindPageBase:onClickFateBtn(container,eventName)
    local name = string.sub(eventName,-1)
    local index = tonumber(name)
    if not index then return end
    
    FateFindPageBase:closeReward(container)
    
    if index ~= FateDataManager.currentHuntingIndex then
        return
    end
    --如果背包满了，不让继续猎命
    local bagSize = GameConfig.BuyDressBagCost.DefaultDressBagSize
    if UserInfo.stateInfo:HasField("currentDressBagSize") then
        bagSize = UserInfo.stateInfo.currentDressBagSize
    end
    if FateDataManager:getPackageCount() >= bagSize then
        MessageBoxPage:Msg_Box_Lan("@DressTips_20");
        return
    end

    local conf = fateBuyCfg[FateDataManager.currentHuntingIndex]
    if not conf then
        return
    end
    for _,v in ipairs(conf.lightCost) do
        if v.itemId and v.count then
            local haveNum = UserItemManager:getCountByItemId(v.itemId) or 0
            if haveNum < v.count then
                --提示不够
                MessageBoxPage:Msg_Box_Lan("@DressTips_1");
                return
            end
        end
    end
    local msg = MysticalDress_pb.HPMysticalDressHuntingReq();
    msg.id = index
    common:sendPacket(option.opcode.MYSTICAL_DRESS_HUNTING_C, msg);
    sendHuntingId = index
end

--激活命格
function FateFindPageBase:onActiveFatBtn(container,eventName)
    FateFindPageBase:closeReward(container)
    --如果花费足够
    local name = string.sub(eventName,-1)
    local index = tonumber(name)
    if not index then return end
    
    local conf = fateBuyCfg[index]
    if not conf then
        return
    end
    for _,v in ipairs(conf.activeBuyCost) do
        if v.itemId and v.count then
            local haveNum = UserItemManager:getCountByItemId(v.itemId) or 0
            if haveNum < v.count then
                --提示不够
                MessageBoxPage:Msg_Box_Lan("@DressTips_2");
                return
            end
        end
    end
    local msg = MysticalDress_pb.HPMysticalDressActivateReq();
    msg.id = index
    common:sendPacket(option.opcode.MYSTICAL_DRESS_ACTIVE_C, msg);
    sendHuntingId = FateDataManager.currentHuntingIndex
end

function FateFindPageBase:onBackpackOpen(container)
    if mFromRoleId == GameConfig.FatePackageJumpFlag then
        PackagePage_showFateItems(GameConfig.FatePackageJumpFlag,true)
        PageManager.popPage("FateFindPage")
    else
        PackagePage_showFateItems(mFromRoleId,true)
    end
end

function FateFindPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_FATEFIND);
end

function FateFindPageBase:onReturn(container)
    PageManager.popPage("FateFindPage")
end

function FateFindPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
		if pageName == "FateFindPage" then
            if extraParam == "closeReward" then
                FateFindPageBase:closeReward(container)
            elseif extraParam == "closeEffectUp" then
                if huntingLvUpEffect then
                    huntingLvUpEffect:removeFromParentAndCleanup(true)
                    huntingLvUpEffect = nil
                end
            end
        end
    end
    FateFindPageBase:refreshCostNum(container)
end

function FateFindPageBase:closeReward(container)
    local rewardNode = container:getVarNode("mGetNode")
    if rewardNode then
        rewardNode:removeAllChildren()
    end
    rewardContainer = nil
end

function FateFindPageBase:showReward()
    if selfContainer then
        local rewardNode = selfContainer:getVarNode("mGetNode")
        if rewardNode then
            rewardNode:removeAllChildren()
            local FateRewardPage = require("FateRewardPage")
            rewardContainer = FateRewardPage:onEnter(selfContainer)
            rewardNode:addChild(rewardContainer)
            rewardContainer:release();
        end
    end
end

function FateFindPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == option.opcode.MYSTICAL_HUNTING_INFO_S then
        local msg = MysticalDress_pb.HPMysticalHunting();
        msg:ParseFromString(msgBuff)
        FateDataManager.currentHuntingIndex = msg.id
        FateFindPageBase:refreshLightState(container)
    elseif opcode == option.opcode.MYSTICAL_DRESS_HUNTING_S 
    or opcode == option.opcode.MYSTICAL_DRESS_ACTIVE_S then
        if sendHuntingId and sendHuntingId < FateDataManager.currentHuntingIndex then
            local effectParent = container:getVarNode("mMidNode")
            if effectParent then
                if huntingLvUpEffect then
                    huntingLvUpEffect:runAnimation("Default Timeline")
                else
                    huntingLvUpEffect = ScriptContentBase:create("PrivatePage_EffectUP.ccbi")
                    huntingLvUpEffect:registerFunctionHandler(function(eventName, container)
                        if eventName == "luaOnAnimationDone" then
                            PageManager.refreshPage("FateFindPage","closeEffectUp")   
                        end
                    end)
                    effectParent:addChild(huntingLvUpEffect)
                    huntingLvUpEffect:release()
                end
                local sprite = huntingLvUpEffect:getVarSprite("mPrivateFont")
                if sprite then
                    sprite:setTexture("UI/Common/Font/Font_Private_" .. FateDataManager.currentHuntingIndex .. ".png")
                end
                PageManager.PlayEffect("FateFindLvUp")
            end
            sendHuntingId = nil
        end
    end
end

function FateFindPage_setFromRoleId(roleId)
    mFromRoleId = roleId
end

local CommonPage = require("CommonPage");
FateFindPage = CommonPage.newSub(FateFindPageBase, "FateFindPage", option);

return FateFindPage