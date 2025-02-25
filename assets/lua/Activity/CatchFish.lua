
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'CatchFish'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local ItemManager = require "Item.ItemManager"
local CatchFish_pb = require("CatchFish_pb")
require("CatchFishRank")
local CatchFish = {}
local SCORE_ITEM = "30000_29999_"
local thisPageNameContainer = nil
local TempRewards = {}
local TempCurFishingScore = 0
local isCanTouchBtn = true
local NeedShowRewardPage = false;
local showScore = nil
local MercenaryCfg = nil
local MercenaryRoleInfos = nil
local beginIndex = 1 --播动画使用
local opcodes = {
	FISHING_INFO_C = HP_pb.FISHING_INFO_C,
	FISHING_INFO_S = HP_pb.FISHING_INFO_S,
    CATCH_FISH_C = HP_pb.CATCH_FISH_C,
    CATCH_FISH_S = HP_pb.CATCH_FISH_S,
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
}

--当前页面信息
local PageInfo = {
    freeTimes = 0,
    singleCost = 30,
    continuousCost = 300,
    myscore = 0,
	timerName = "CatchFish_TimeLimit",
	timeLeft = 0,
}
--奖励信息
local FishingRewards = {}

local alreadyShowReward = {}--界面上已经显示的奖励
local needShowReward = {}--当前锻造的奖励
local COUNT_LIMIT = 10
local _extraReward = nil
local lasttime = 0;--用于计算时间差

local ReqAnim = 
{
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = {}
}


function CatchFish.onFunction(eventName,container)
	if eventName == "onFree" then
		CatchFish:RequestFishingEvent(true);
	elseif eventName == "onDiamond" then
		CatchFish:RequestFishingEvent(false);
	elseif eventName == "onPreview" then
        require("CommonAwardPreviewListPage");
        CommonAwardPreviewBase_setConfigCfg(ConfigManager.getCatchFishCfg());
        PageManager.pushPage("CommonAwardPreviewListPage");
    elseif eventName == "onRankList" then
        CatchFishRank_setScoreInfo(PageInfo.myscore);
        PageManager.pushPage("CatchFishRank");
    elseif eventName == "luaOnAnimationDone" then
        --local animationName=tostring(container:getCurAnimationDoneName())
         --PageManager.pushPage("CatchFishReward");
        --local bNeedShowRarelyFish = false;

        -- if bNeedShowRarelyFish then
        --     PageManager.pushPage("ShowRarelyFish");
        --     bNeedShowRarelyFish = false
        --     NeedShowRewardPage = true
        -- else
        --     PageManager.pushPage("CatchFishReward");
        -- end
        -- isCanTouchBtn = true

        CatchFish:onAnimationDone(container)
    elseif eventName == "onHand1" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand2" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand3" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand4" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand5" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand6" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand7" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand8" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand9" then
        CatchFish:onHand(container,eventName)
    elseif eventName == "onHand10" then
        CatchFish:onHand(container,eventName)
	end
end

function CatchFish:onHand(container,eventName)
    local index = tonumber(string.sub(eventName,7,string.len(eventName)))
    local _type, _id, _count = unpack(common:split(alreadyShowReward[index], "_"));
    local items = {}
    table.insert(items, {
        type    = tonumber(_type),
        itemId  = tonumber(_id),
        count   = tonumber(_count)
    });
    GameUtil:showTip(container:getVarNode('mPic'..index), items[1])

end

function CatchFish:onAnimationDone(container)
    local animationName=tostring(container:getCurAnimationDoneName())
    if animationName == "AllAni10" or string.sub(animationName,1,8)=="ItemAni_" then
        local index = tonumber(string.sub(animationName,-2))
        if animationName == "AllAni10"  or index >= #alreadyShowReward then  -- and index ~= 10 
            ReqAnim.isAnimationRuning = false
            isCanTouchBtn = true
            if index == 10 then
                CatchFish:refreshRewardNode(container,index+1)
            end
            --播放完毕
            -- NodeHelper:setNodesVisible(container, { mBackpackbtn = true,mIllustatedbtn = true,mRewardBtn = true})
            -- NodeHelper:setMenuItemEnabled( container, "mDiamond", true);
            -- NodeHelper:setMenuItemEnabled( container, "mFree", true);
            --飘字去掉
            -- local rewardItems = {}
            -- if #FishingRewards > 0 then
            --     for i = 1,#FishingRewards do
            --         local _type, _id, _count = unpack(common:split(FishingRewards[i], "_"));
            --         table.insert(rewardItems, {
            --             itemType    = tonumber(_type),
            --             itemId  = tonumber(_id),
            --             itemCount   = tonumber(_count)
            --         });
            --     end
            -- end
            -- NodeHelper:showRewardText(container, rewardItems)
            if #_extraReward > 0 then
                local rewardItems = {}
                for i = 1 , #_extraReward do
                    local reward = _extraReward[i].reward;
                    local _type, _id, _count = unpack(common:split(reward, "_"));
                    table.insert(rewardItems, {
                        type    = tonumber(_type),
                        itemId  = tonumber(_id),
                        count   = tonumber(_count),
                        });
                end
                local CommonRewardPage = require("CommonRewardPage")
                CommonRewardPageBase_setPageParm(rewardItems, true)
                PageManager.pushPage("CommonRewardPage")
            end
            CatchFish:getActivityInfo()
        else
            CatchFish:refreshRewardNode(container,index+1)
            
        end
    end

    ---捡贝壳活动播完
    if animationName == "Start" then
        ReqAnim.isAnimationRuning = true
        CatchFish:refreshRewardNode(container,beginIndex); 
    elseif animationName == "Start10" then 
        for i=1,#FishingRewards do
            CatchFish:refreshRewardNode10(self.container,i)
        end
        self.container:runAnimation("AllAni10")    
    end
end

function CatchFish:onEnter(ParentContainer)
	self.container = ScriptContentBase:create("Act_TimeLimitFishingContent.ccbi")
	self.container:registerFunctionHandler(CatchFish.onFunction)
	self:registerPacket(ParentContainer)
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    thisPageNameContainer = self.container
	self:getActivityInfo()

    isCanTouchBtn = true
    local heroNode = self.container:getVarNode("mSpine")
    if heroNode and heroNode:getChildByTag(10010) == nil then
        spine = nil
        spine = SpineContainer:create("Spine/laoyuhaitan", "laoyuhaitan")
        local spineNode = tolua.cast(spine, "CCNode")
        spineNode:setTag(10010)
        heroNode:addChild(spineNode)
        --heroNode:setScale(1)
        spine:runAnimation(1, "Stand", -1) --Srand
    end
    NodeHelper:setStringForLabel(self.container, { mMercenaryInfoTxt = common:getLanguageString("@GoldFishSpecia1Txt1")})
    CatchFish:showRoleSpine()
	return self.container
end

--添加SPINE动画
function CatchFish:showRoleSpine()
    local spineId = ConfigManager.getCatchFishCfg()[1].rewards[1].itemId
    local heroNode = self.container:getVarNode("mRoleSpine")
    local m_NowSpine = nil
    if heroNode then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width,height =  visibleSize.width ,visibleSize.height
        local rate = visibleSize.height/visibleSize.width
        local desighRate = 960/640
        rate = rate / desighRate
        heroNode:removeAllChildren()
 
        local roldData = ConfigManager.getRoleCfg()[spineId]
        m_NowSpine = SpineContainer:create(unpack(common:split((roldData.spine), ",")))
        local spineNode = tolua.cast(m_NowSpine, "CCNode")  
        heroNode:addChild(spineNode)
        m_NowSpine:runAnimation(1, "Stand", -1)
        --heroNode:setScale(rate)
        -- local deviceHeight = CCDirector:sharedDirector():getWinSize().height
        -- if deviceHeight < 900 then --ipad change spine position
        --     NodeHelper:autoAdjustResetNodePosition(spineNode,-0.3)  
        -- end
    end
end

function CatchFish:refreshPage(container)
    UserInfo.sync();
    local labelText = {}
	if PageInfo.timeLeft > 0 then
	    TimeCalculator:getInstance():createTimeCalcultor(PageInfo.timerName, PageInfo.timeLeft);
    else
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = common:getLanguageString("@ActivityEnd")})
        NodeHelper:setMenuItemEnabled( container, "mDiamond", false);
        NodeHelper:setMenuItemEnabled( container, "mFree", false);
	end
    if PageInfo.freeTimes > 0 then
        labelText.mFreeText = common:getLanguageString("@FishingFree",PageInfo.freeTimes)
        NodeHelper:setNodesVisible(container, {mCostNodeVar = false ,mFreeText = true ,})
    else
        labelText.mCostNum = tostring(PageInfo.singleCost)--ommon:getLanguageString("",PageInfo.freeTimes)
        NodeHelper:setNodesVisible(container, {mCostNodeVar = true ,mFreeText = false ,})
        ---处理消失红点
        ActivityInfo.changeActivityNotice(Const_pb.GOLD_FISH)
    end
    labelText.mDiamondText = tostring(PageInfo.continuousCost)
    labelText.mDiamondNum = UserInfo.playerInfo.gold
    labelText.mMyPoints = PageInfo.myscore;
    NodeHelper:setStringForLabel(container, labelText);
end

function CatchFish:onExecute(ParentContainer)
	if TimeCalculator:getInstance():hasKey(PageInfo.timerName) then
        local timeStr = '00:00:00'
		PageInfo.timeLeft = TimeCalculator:getInstance():getTimeLeft(PageInfo.timerName)
		if PageInfo.timeLeft > 0 then
			 timeStr = common:second2DateString(PageInfo.timeLeft , false)
        else
            TimeCalculator:getInstance():removeTimeCalcultor(PageInfo.timerName)
            timeStr = common:getLanguageString("@ActivityEnd")
            NodeHelper:setMenuItemEnabled( container, "mDiamond", false);
            NodeHelper:setMenuItemEnabled( container, "mFree", false);
		end
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr})
	end
end
function CatchFish:getActivityInfo()
    MercenaryRoleInfos = {}
    MercenaryCfg = ConfigManager.getRoleCfg()
    common:sendEmptyPacket(opcodes.FISHING_INFO_C , true)
end
function CatchFish:RequestFishingEvent(isSingle)
    if not isCanTouchBtn then
        return
    end
    local msg = CatchFish_pb.CatchFishRequest()
    msg.isSingle = isSingle
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.CATCH_FISH_C, pb , #pb, true)
end
--更新佣兵碎片数量
function CatchFish:updateMercenaryNumber()
    local itemId = ConfigManager.getCatchFishCfg()[1].rewards[1].itemId
    for i = 1,#MercenaryRoleInfos do
        --local curMercenary = UserMercenaryManager:getUserMercenaryById(MercenaryRoleInfos[i].roleId)
        if itemId == MercenaryRoleInfos[i].itemId then
            NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt",MercenaryCfg[itemId].name) .. MercenaryRoleInfos[i].soulCount.."/"..MercenaryRoleInfos[i].costSoulCount});
            break;
        end
    end
end
function CatchFish:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode();
	local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        self:updateMercenaryNumber();
    elseif opcode == opcodes.FISHING_INFO_S then
		local msg = CatchFish_pb.FishingInfoResponse()
		msg:ParseFromString(msgBuff)
        PageInfo.freeTimes = msg.freeTimes;
        PageInfo.myscore = msg.score;
        PageInfo.singleCost = msg.singleCost;
        PageInfo.continuousCost = msg.continuousCost;
        PageInfo.timeLeft = msg.closetimes;
        self:refreshPage(self.container)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    elseif opcode == opcodes.CATCH_FISH_S then
        local msg = CatchFish_pb.CatchFishResponse()
		msg:ParseFromString(msgBuff)
        FishingRewards = msg.rewards
        _extraReward = msg.extraReward--额外的奖励

        local reward = msg.rewards
        beginIndex = 1;
        if (#alreadyShowReward + #reward) > COUNT_LIMIT then
            self:HideRewardNode(self.container);
            self:ClearALreadyShowReward()
        else
            beginIndex = #alreadyShowReward + 1;
        end

        local bNeedShowRarelyFish = false;
        showScore = 0
        --收集所需信息
        local temp = {}
        for i = 1,#FishingRewards do
            showScore = showScore + tonumber(FishingRewards[i].score)
            if FishingRewards[i].fishId == 1 then--稀有鱼
                bNeedShowRarelyFish = true
            end
            if FishingRewards[i].reward ~=nil and FishingRewards[i].reward ~="" then
                table.insert(alreadyShowReward,FishingRewards[i].reward)
                table.insert(temp,FishingRewards[i].reward)
            else
                table.insert(alreadyShowReward,SCORE_ITEM..FishingRewards[i].score)
                table.insert(temp, SCORE_ITEM..FishingRewards[i].score)
            end
        end
        FishingRewards = temp
        -- for i = 1,#reward do
        --     alreadyShowReward[#alreadyShowReward+1] = reward[i]
        -- end
        ReqAnim.isAnimationRuning = true
        if beginIndex == 1 then
            if #FishingRewards == 1 then 
                self.container:runAnimation("Start")
            else
                self.container:runAnimation("Start10") 
            end
        else
            CatchFish:refreshRewardNode(self.container,beginIndex);  
        end
        -- thisPageNameContainer:runAnimation("Anim2")
         isCanTouchBtn = false
         --self:getActivityInfo()
	end
end


function CatchFish:HideRewardNode(container)
    local visibleMap = {}
    for i = 1 ,10 do
        visibleMap["mRewardNode"..i] = false
    end
    
    local aniShadeVisible = false
    if alreadyShowReward and #alreadyShowReward > 0 then
    --[[
        ReqAnim.isAnimationRuning = true
        NodeHelper:setNodesVisible(container, { mBackpackbtn = false,mIllustatedbtn = false,mRewardBtn = false})
        NodeHelper:setMenuItemEnabled( container, "mDiamond", false);
        NodeHelper:setMenuItemEnabled( container, "mFree", false);
        self:refreshRewardNode(container,1)
    --]]
        for i = 1 , #alreadyShowReward do
            visibleMap["mRewardNode"..i] = true
            local reward = alreadyShowReward[i];
            local rewardItems = {}
            local _type, _id, _count = unpack(common:split(reward, "_"));
            table.insert(rewardItems, {
                type    = tonumber(_type),
                itemId  = tonumber(_id),
                count   = tonumber(_count),
                });
            NodeHelper:fillRewardItemWithParams(container, rewardItems,1,{startIndex = i ,frameNode = "mHand",countNode = "mNumber"})
        end
        aniShadeVisible = true
        -- container:runAnimation("ShowItem")
    end    
    NodeHelper:setNodesVisible(container, visibleMap)
    if not aniShadeVisible then
        -- container:runAnimation("StandAni")
    end
    --NodeHelper:setNodeVisible(container:getVarNode("mAniShade"),aniShadeVisible)
end

function CatchFish:ClearALreadyShowReward(hideType)
    alreadyShowReward = {}
end

function CatchFish:refreshRewardNode(container,index)
    local visibleMap = {}
    visibleMap["mRewardNode"..index] = true
    local reward = alreadyShowReward[index];
    if not reward then 
        return
    end 
    local rewardItems = {}
    local _type, _id, _count = unpack(common:split(reward, "_"));
    table.insert(rewardItems, {
        type    = tonumber(_type),
        itemId  = tonumber(_id),
        count   = tonumber(_count),
        });

    if index > 10 then 
        local CommonRewardPage = require("CommonRewardPage")
        CommonRewardPageBase_setPageParm(rewardItems, true) --, msg.rewardType
        PageManager.pushPage("CommonRewardPage")
    else
        NodeHelper:fillRewardItemWithParams(container, rewardItems,1,{startIndex = index ,frameNode = "mHand",countNode = "mNumber"})
        NodeHelper:setNodesVisible(container, visibleMap )
        local Aniname = tostring(index)
        if index < 10 then
           Aniname = "0"..Aniname
        end
        container:runAnimation("ItemAni_"..Aniname)
    end
    -- local reward = alreadyShowReward[index];
    -- local rewardItems = {}
    -- local _type, _id, _count = unpack(common:split(reward, "_"));
    -- table.insert(rewardItems, {
    --     type    = tonumber(_type),
    --     itemId  = tonumber(_id),
    --     count   = tonumber(_count),
    --     });
   
end

function CatchFish:refreshRewardNode10(container,index)
    local visibleMap = {}
    visibleMap["mRewardNode"..index] = true
    local reward = alreadyShowReward[index];
    if not reward then 
        return
    end 
    local rewardItems = {}
    local _type, _id, _count = unpack(common:split(reward, "_"));
    table.insert(rewardItems, {
        type    = tonumber(_type),
        itemId  = tonumber(_id),
        count   = tonumber(_count),
        });

    -- if index > 10 then 
    --     local CommonRewardPage = require("CommonRewardPage")
    --     CommonRewardPageBase_setPageParm(rewardItems, true) --, msg.rewardType
    --     PageManager.pushPage("CommonRewardPage")
    -- else
        NodeHelper:fillRewardItemWithParams(container, rewardItems,1,{startIndex = index ,frameNode = "mHand",countNode = "mNumber"})
        NodeHelper:setNodesVisible(container, visibleMap )
        -- local Aniname = tostring(index)
        -- if index < 10 then
        --     Aniname = "0"..Aniname
        -- end
    --end
end

function CatchFish:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function CatchFish:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end
function getFishingPackageInfo()
    return FishingRewards;
end
function getNeedShowRewardPage()
    return NeedShowRewardPage;
end
function setNeedShowRewardPage()
    NeedShowRewardPage = false
end
function CatchFish:onExit(ParentContainer)
    self:ClearALreadyShowReward(hideType)
	TimeCalculator:getInstance():removeTimeCalcultor(PageInfo.timerName)
	self:removePacket(ParentContainer)
    onUnload(thisPageName, self.container)
end

return CatchFish
