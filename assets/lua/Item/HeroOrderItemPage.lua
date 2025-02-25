
local BasePage             = require("BasePage")
local common               = require("common")
local Const_pb             = require("Const_pb")
local HP_pb                = require("HP_pb")
local UserInfo             = require("PlayerInfo.UserInfo")
local HeroOrderItemManager = require("Item.HeroOrderItemManager")
local NodeHelper           = require("NodeHelper")
local ResManagerForLua     = require("ResManagerForLua")
local ItemOpr_pb 	       = require("ItemOpr_pb")
local ItemManager          = require("Item.ItemManager")
local PageManager          = require("PageManager")
local ItemOprHelper        = require("Item.ItemOprHelper")

local sThisPageName        = "HeroOrderItemPage"
local tostring             = tostring
local tonumber             = tonumber

local opcodes = {
	ITEM_USE_S	= HP_pb.ITEM_USE_S
};

local option = {
    ccbiFile   = "BackpackHeroPopUp1.ccbi",
    handlerMap = {
       onCompound  = "onCompound",
       onSell      = "onSale" ,
       onReceive   = "onRewardTask",
       onClose     = "onClose"       
    },
    opcode = opcodes
}

local mCurItemCfg = nil
local mLevelDesc  = nil
local mItemInfo   = nil
local mReceiveBtn = nil

local HeroOrderItemPage = BasePage:new(option, sThisPageName)

function HeroOrderItemPage:onEnter(container)
    container:registerPacket(HP_pb.ITEM_USE_S);
	local mBackpackHeroTitle  = container:getVarNode("mBackpackHeroTittle")
    local mContentLevelUp     = container:getVarNode("mContent01")
    local mContentLevelDown   = container:getVarNode("mContent02")
    mLevelDesc                = container:getVarLabelBMFont("mLevelDesc")
    local mBackpackHeroTittle = container:getVarLabelBMFont("mBackpackHeroTittle")
    local mSell       = container:getVarNode("mSell")
    local mCompound   = container:getVarNode("mCompound")
    local mReceive    = container:getVarNode("mReceive")
    mReceiveBtn = container:getVarMenuItemImage("mReceiveBtn")
    mContentLevelUp:setVisible(false)
    mContentLevelDown:setVisible(false)
	mLevelDesc:setScale(0.8)
    mItemInfo = HeroOrderItemManager:getCurSelectItemInfo()
    mCurItemCfg = ItemManager:getItemCfgById(mItemInfo.itemId)
    local leveLimit = HeroOrderItemManager:getHeroLevelLimit()

    if  UserInfo.roleInfo.level < leveLimit then
        mContentLevelDown:setVisible(true)
        HeroOrderItemPage:onLevelNotEnough(container)
        mReceiveBtn:setEnabled(false)
    else 
        mContentLevelUp:setVisible(true)
        HeroOrderItemPage:onLevelEnough(container)
        local mTaskFinishTimes = HeroOrderItemManager:getTaskFinishInfo();
        if mTaskFinishTimes.taskFinishLefttimes <= 0 or mTaskFinishTimes.taskFinishLefttimes > mTaskFinishTimes.taskFinishAlltimes then
            mReceiveBtn:setEnabled(false)
        else
            mReceiveBtn:setEnabled(true)
        end  
    end
    local mHeroOrder = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, mItemInfo.itemId, 1);
    mBackpackHeroTittle:setString(mHeroOrder.name)
    HeroOrderItemPage:showItemInfo(container)
	if Golb_Platform_Info.is_r2_platform then
		local label = container:getVarLabelBMFont("mReceiveTxt")
        local labelTxt = common:getLanguageString("@HeroActivate");
		if label then
			label:setString(labelTxt)
		end
	end
end

--等级低于道具等级5级以上
function HeroOrderItemPage:onLevelNotEnough(container)
     local message = common:getLanguageString("@HeroLevelDownDiscribe")
     mLevelDesc:setString(message)
end

function HeroOrderItemPage:onLevelEnough(container)
    local mHintContent   = container:getVarLabelBMFont("mHintContent")  
    local mRewardContent = container:getVarLabelBMFont("mRewardContent")
    local mGoalsContent  = container:getVarLabelBMFont("mGoalsContent")
    local mCurTaskInfo   = HeroOrderItemManager:getTaskCfgByTaskId(mCurItemCfg.heroTaskId)
	local mResInfo       = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, mCurTaskInfo.rewardItem.itemId, mCurTaskInfo.rewardItem.count);
   -- local strTaskProgress = HeroOrderItemManager:getTaskNum() .."/"..HeroOrderItemManager:getTaskTotalNum()
   local mTaskFinishTimes = HeroOrderItemManager:getTaskFinishInfo();
   local strTaskProgress = HeroOrderItemManager:getTaskNum() .."/"..mTaskFinishTimes.taskFinishAlltimes
   
	mHintContent:setScale(0.7)
    local mHintStr   = common:fillHtmlStr("HeroOrderItemHelpStr" ,tostring(strTaskProgress) , tostring(mResInfo.name))
    NodeHelper:addHtmlLable(mHintContent, mHintStr, GameConfig.Tag.HtmlLable, CCSizeMake(700,100));
	
	mRewardContent:setScale(0.8)
    local mRewardStr = common:fillHtmlStr("HeroOrderItemRewardStr", tostring(mResInfo.name) , tostring(mResInfo.count))
    NodeHelper:addHtmlLable(mRewardContent, mRewardStr, GameConfig.Tag.HtmlLable + 1, CCSizeMake(700,100));
	
	mGoalsContent:setScale(0.7)
    local mGoalStr   = common:fillHtmlStr("HeroOrderItemGoalStr", tostring(mCurTaskInfo.monsterNumNeedKill), tostring(mCurTaskInfo.levelLimit))
    NodeHelper:addHtmlLable(mGoalsContent, mGoalStr, GameConfig.Tag.HtmlLable + 2, CCSizeMake(700,100));
end

function HeroOrderItemPage:showItemInfo(container)
	local mHeroOrder = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, mItemInfo.itemId, mItemInfo.count);
	local lb2Str = {
		["mName"] 	= mHeroOrder.name,
		["mNumber"]	= "x" .. mItemInfo.count
	};
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, {["mPic"] = mHeroOrder.icon});
	NodeHelper:setQualityFrames(container, {["mHand"] = mHeroOrder.quality});
	NodeHelper:setColor3BForLabel(container, {["mName"] = common:getColorFromConfig("Own")});
end

function HeroOrderItemPage:onExit( container )
	container:removePacket(HP_pb.ITEM_USE_S);
end

function HeroOrderItemPage:onCompound(container)
    ItemManager:setNowSelectItem(mItemInfo.itemId)
	PageManager.pushPage("HeroOrderUpgradePage")
    PageManager.popPage(sThisPageName) 
end

function HeroOrderItemPage:onSale(container)
    local title = common:getLanguageString("@Sell");
	local msg = common:getLanguageString("@HeroOrderSellDesc");
	PageManager.showConfirm(title, msg, function(isSure)
		if isSure then
			ItemOprHelper:sellItem(mItemInfo.itemId, 1)
            PageManager.popPage(sThisPageName) 
		end
	end, true)
end

function HeroOrderItemPage:onRewardTask(container)
    ItemOprHelper:getHeroOrderTask(mItemInfo.itemId)
end

function HeroOrderItemPage:updatePage(container)
     local mTaskFinishTimes = HeroOrderItemManager:getTaskFinishInfo();
     if mTaskFinishTimes.taskFinishLefttimes <= 0 or mTaskFinishTimes.taskFinishLefttimes > mTaskFinishTimes.taskFinishAlltimes then
        mReceiveBtn:setEnabled(false)
     else
        mReceiveBtn:setEnabled(true)
     end
     if mItemInfo == nil then
        HeroOrderItemPage:onClose(container)
        return
     end
     HeroOrderItemPage:onLevelEnough(container)
     HeroOrderItemPage:showItemInfo(container)
end

--回包处理
function HeroOrderItemPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    local msg = ItemOpr_pb.HPItemUseRet()
    if opcode == opcodes.ITEM_USE_S then
        msg:ParseFromString(msgBuff);
        mItemInfo = HeroOrderItemManager:getCurSelectItemInfo()
        if msg.msgType == Const_pb.GET_TASK then
           local content = common:getLanguageString("@HeroOrderAwardTaskSuccess")
           MessageBoxPage:Msg_Box("@HeroOrderAwardTaskSuccess")
           HeroOrderItemManager:addTaskNum(1)
	       HeroOrderItemPage:updatePage(container)
        elseif msg.msgType == Const_pb.CONSUME_ITEM then
        end
	end
end
 

function HeroOrderItemPage:onClose(container)
    PageManager.popPage(sThisPageName)
end

--endregion
