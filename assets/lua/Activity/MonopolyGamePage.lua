local thisPageName = "MonopolyGamePage" --"ActTimeLimit_141"
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local ConfigManager = require("ConfigManager")
local UserItemManager = require("Item.UserItemManager")


local MonopolyGameBase = {
    container = nil
}

local MonopolyMap = {
    ccbiFile = "Act_TimeLimit_141Content.ccbi",
    container = nil,
}

local option = {
    ccbiFile = "Act_TimeLimit_141Page.ccbi",
    handlerMap = {
        onReturnBtn = "onReturnBtn",
        ontouchDice = "ontouchDice",
        onHelp = "onHelp",
        onClick = "onClick"
    },
    opcodes = {
        ACTIVITY141_C = HP_pb.ACTIVITY141_C,
        ACTIVITY141_S = HP_pb.ACTIVITY141_S,
    }
}

local MAP_WIDTH, MAP_HEIGHT = 1500,1280

local MAP_SCALE = 1.15

local CenterPos = 25

local MinFlagPos = 1
local MaxFlagPos = 24

local DiceItemId = 7001   -- 更新時需換新id

local Dice_spine = nil

local flag_spine = nil

local isInAnimation = false

local RequestType = {
    syncInfo = 0,
    -- 0:同步
    reqData = 1
    -- 1：骰骰子
};

local DiceCount = 0

local MonopolyData = {
    Index = 0 ,
    finish = 0,
    free = 0,
    step = 0,
    reward = "",
    finishreward = ""
}

local itemInfo = nil

local MonopolyDoneItem = {
    container = nil,
    --ccbiFile = "DayLogin30Item.ccbi",
}

function MonopolyDoneItem:init()

end

--function MonopolyDoneItem:onRefreshContent(ccbRoot)
--    self:refresh(ccbRoot:getCCBFileNode())
--end

function MonopolyDoneItem:setState(state)
    self.mState = state
end

function MonopolyDoneItem:getStage()
    return self.mState
end

function MonopolyDoneItem.onFunction(eventName, container)
    if MonopolyDoneItem[eventName] and type(MonopolyDoneItem[eventName]) == "function" then
        MonopolyDoneItem[eventName](container)
    end
end

function MonopolyDoneItem:refresh(container)
    if container == nil then
        return
    end

    if (self.rewardData == nil) or (itemInfo ~= MonopolyData.finishreward[1])then
        local rewardItems = { }
        itemInfo = MonopolyData.finishreward[1]
        if itemInfo ~= nil then
            for _, item in ipairs(common:split(itemInfo, ",")) do
                local _type, _id, _count = unpack(common:split(item, "_"));
                table.insert(rewardItems, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count)
                } );
            end
        end
        self.rewardData = rewardItems[1]
    else
        return
    end

    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.rewardData.type, self.rewardData.itemId, self.rewardData.count)

    local iconBgSprite = NodeHelper:getImageBgByQuality(resInfo.quality)

    NodeHelper:setSpriteImage(container, { mIconSprite = resInfo.icon, mDiBan = iconBgSprite })
    -- NodeHelper:setColorForLabel(container, { mNumLabel = ConfigManager.getQualityColor()[resInfo.quality].textColor })
    NodeHelper:setQualityFrames(container, { mQuality = resInfo.quality })
    local icon = container:getVarSprite("mIconSprite")
    icon:setPosition(ccp(0, 0))


    local mSelectSprite = container:getVarSprite("mSelectSprite")

    local mIconSprite = container:getVarSprite("mIconSprite")

    local mNumLabel = container:getVarLabelBMFont("mNumLabel")
    if mNumLabel then
        -- mNumLabel:setString("x" .. resInfo.count)
    end
    NodeHelper:setStringForLabel(container, { mNumLabel = "x" .. resInfo.count })

    local mGetSprite = container:getVarSprite("mGetSprite")

    local mSupplementarySprite = container:getVarSprite("mSupplementarySprite")

    local mDayLabel = container:getVarLabelTTF("mDayLabel")
    mDayLabel:setVisible(false)

    local mColorNode = container:getVarNode("mColorNode")

    local mItemNode = container:getVarNode("mItemNode")

    if self.mState == 0 then
        --mColorNode:setVisible(false)
        --mSelectSprite:setVisible(false)
        mGetSprite:setVisible(false)
        --mSupplementarySprite:setVisible(false)
    end
end

-- item??
function MonopolyDoneItem:onClick(container)

--    if self.mState == LivenessPageItemState.CanGet then
--        local msg = Activity4_pb.ActiveComplianceAwardReq()
--        msg.day = self.id
--        common:sendPacket(opcodes.ACTIVECOMPLIANCE_AWARD_C, msg, false)
--    else
        if self.rewardData ~= nil then
            GameUtil:showTip(container:getVarNode('mIconSprite'), self.rewardData)
        end
--    end
end

--------------------------------------------------------------------------------------

function MonopolyMap.init()
    
end

function MonopolyMap.onFunction(eventName, container)
    if MonopolyMap[eventName] and type(MonopolyMap[eventName]) == "function" then
        MonopolyMap[eventName](container)
    end
end

function MonopolyGameBase:onClick(container)
    MonopolyDoneItem:onClick(MonopolyDoneItem.container)
end;

function MonopolyGameBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)

    local scrollview = container:getVarScrollView("mContent");
	if scrollview~= nil then
		container:autoAdjustResizeScrollview(scrollview);
	end
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
    local mScale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
	if mScale9Sprite2 ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite2 )
	end
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mdoneNode"),-1)
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mdonecount"),-1)
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mdoubletitle"),-1)
    container.mScrollView = scrollview
    container.mScrollView:setBounceable(false)
    container.mScrollView:setContentSize(CCSizeMake(MAP_WIDTH * MAP_SCALE,MAP_HEIGHT * MAP_SCALE))

    local langType = CCUserDefault:sharedUserDefault():getIntegerForKey("LanguageType")
    local doubleNode = container:getVarNode("mdoubletitle");
    local spinePath ="Spine/NGUI"
    local spineName ="Spine_reward"
    local double_spine = SpineContainer:create(spinePath, spineName)
    double_spine:setSkin(langType)
    local stoNode = tolua.cast(double_spine, "CCNode");
    doubleNode:addChild(stoNode)
    double_spine:runAnimation(1,"animation_1",-1)
    doubleNode:setVisible(false)


    self:initMap(container)
    self:initDoneItem(container)

    local Mapcontainer = MonopolyMap.container
    local flagNode = Mapcontainer:getVarNode("mMainflag");
    spinePath ="Spine/NGUI"
    spineName ="Activity_141_flag"
    flag_spine = SpineContainer:create(spinePath, spineName)
    stoNode = tolua.cast(flag_spine, "CCNode");
    flagNode:addChild(stoNode)

    flag_spine:runAnimation(1, "animation_1", -1)
end

function MonopolyGameBase:onEnter(container)
    MonopolyGameBase.container = container
    self:registerPacket(container)

    self:moveToPos(CenterPos,true)

    self:requestServerData(RequestType.syncInfo)

    NodeHelper:setMenuItemsEnabled(container, {mDiceBtn = true})

end

function MonopolyGameBase:onExit(container)
    self:removePacket(container)
    MonopolyDoneItem.rewardData = nil
end

function MonopolyGameBase:setflagPos(pos)
    if not self:checkflagPos(pos) then return end
    local container = MonopolyMap.container
    if not container then return end
    local PosNode = container:getVarNode("mflag_" .. pos)
    local flagNode = container:getVarNode("mMainflag")
    local x,y = PosNode:getPosition()
    flagNode:setPosition(ccp(x,y))
    if pos > 6 and pos < 19 then   -- 萬聖版調整
        flagNode:setScaleX(-1)
    else
        flagNode:setScaleX(1)
    end
end

function MonopolyGameBase:setfinishCount(count)
    local container = MonopolyGameBase.container
    if not container then return end
     NodeHelper:setStringForLabel(container, { BmfDone = count })
end

function MonopolyGameBase:setDiceCount(count)
    local container = MonopolyGameBase.container
    if not container then return end
     NodeHelper:setStringForLabel(container, { Bmfcount = count })
end

function MonopolyGameBase:initMap(container)
    MonopolyMap.init()
    local titleCell = ScriptContentBase:create(MonopolyMap.ccbiFile)
    titleCell:registerFunctionHandler(MonopolyMap.onFunction)
    titleCell:setScale(MAP_SCALE)
    container.mScrollView:addChild(titleCell)
    MonopolyMap.container = titleCell

    local spineNode = MonopolyMap.container:getVarNode("mdice");
    local spinePath ="Spine/NGUI"
    local spineName ="Spine_Dice"
    Dice_spine = SpineContainer:create(spinePath, spineName)
    local spineToNode = tolua.cast(Dice_spine, "CCNode");
    spineNode:addChild(spineToNode)

end

function MonopolyGameBase:initDoneItem(container)
    MonopolyDoneItem.init()
    local ccbNode = container:getVarMenuItemCCB("mDoneItemccb")
    MonopolyDoneItem.container = ccbNode:getCCBFile()
    --local childNode = tolua.cast(ccbNode, 'CCBFileNew');
    --childNode:registerFunctionHandler(MonopolyDoneItem.onFunction)
    local mDayLabel = MonopolyDoneItem.container:getVarLabelTTF("mDayLabel")
    mDayLabel:setVisible(false)
end

function MonopolyGameBase:rundice(step)
    Dice_spine:runAnimation(1,"Animation_"..step,0)
end

function MonopolyGameBase:moveToPos(PosId, noAnimated)
    local container = MonopolyMap.container
    if not container then return end
    PosId = PosId --or GVGManager:getTargetCityId()
    --local cfg = GVGManager.getCityCfg(cityId)
    local PosNode = container:getVarNode("mflag_" .. PosId)
    local scrollView = MonopolyGameBase.container.mScrollView
    local x,y = PosNode:getPosition()
    local nowOffset = scrollView:getContentOffset()
    local minOffSet = scrollView:minContainerOffset()
    local targetNode = PosNode:getParent()

    local rulerNode = MonopolyGameBase.container:getVarNode("mCityBtn")
    local rulerSize = rulerNode:getContentSize()
    local rulerPos = ccp(rulerSize.width/2, rulerSize.height/2)
    
    local targetPos = targetNode:convertToNodeSpace(rulerNode:convertToWorldSpace(rulerPos))
    local dx = targetPos.x - x
    local dy = targetPos.y - y
    local offsetX = math.min(0,math.max(minOffSet.x,nowOffset.x + dx))
    local offsetY = math.min(0,math.max(minOffSet.y,nowOffset.y + dy))
    if noAnimated then
        scrollView:setContentOffset(ccp(offsetX,offsetY))
    else
        scrollView:setContentOffsetInDuration(ccp(offsetX,offsetY),0.2)
    end
end

function MonopolyGameBase:moveFlagTotarget(msg)
    if not self:checkDiceNum(msg.step) then return end
    if not self:checkflagPos(MonopolyData.Index) then return end
    local container = MonopolyMap.container
    if not container then return end
    local Funjump = CCCallFunc:create( function()
                flag_spine:runAnimation(1,"animation_5",0)
            end)
    local flagNode = container:getVarNode("mMainflag")
    local array = CCArray:create()
    local flagPos = MonopolyData.Index
    for i = 1 , msg.step do
        flagPos =  flagPos+1
        if flagPos > MaxFlagPos then
            flagPos = MinFlagPos
        end  
        local PosNode = container:getVarNode("mflag_" .. flagPos)
        local stepPos = ccp(PosNode:getPosition())
        array:addObject(Funjump)
        array:addObject(CCDelayTime:create(0.1))
        array:addObject(CCMoveTo:create(0.5, stepPos))
        array:addObject(CCDelayTime:create(0.1))
        if flagPos > 6 and flagPos < 19 then   -- 萬聖版調整	    
            array:addObject(CCCallFunc:create(function()    
                flagNode:setScaleX(-1)
            end))
        else
            array:addObject(CCCallFunc:create(function()
                flagNode:setScaleX(1)
            end))
        end
    end
    local Funsyn = CCCallFunc:create( function()
                flag_spine:runAnimation(1, "animation_1", -1)
                self:analysisServerData(msg)
            end)
    array:addObject(Funsyn)
    flagNode:runAction(CCSequence:create(array))
end

function MonopolyGameBase:checkDiceNum(dice)
    return (dice >= 1)and(dice <= 6)
end

function MonopolyGameBase:analysisServerData(msg)
    self:SaveData(msg)
    self:setflagPos(msg.Index)
    self:setfinishCount(msg.finish)
    DiceCount =  UserItemManager:getCountByItemId(DiceItemId)
    self:setDiceCount(DiceCount);
    NodeHelper:setNodesVisible(MonopolyGameBase.container, {mdoubletitle = msg.double})
    NodeHelper:setMenuItemsEnabled(MonopolyGameBase.container, {mDiceBtn = true})
end

function MonopolyGameBase:SaveData(msg)
    MonopolyData.Index = msg.Index
    MonopolyData.finish = msg.finish
    MonopolyData.step = msg.step
    MonopolyData.free = msg.free
    MonopolyData.reward = msg.reward
    MonopolyData.finishreward = msg.finishreward
    self:refreshItem(MonopolyGameBase.container)
end

function MonopolyGameBase:onReturnBtn(container)
    GameUtil:purgeCachedData()
    MainFrame_onMainPageBtn()
end

function MonopolyGameBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_MONOPOLY)
end

function MonopolyGameBase:checkflagPos(pos)
    return (pos >= MinFlagPos)and(pos <=MaxFlagPos)
end

function MonopolyGameBase:ontouchDice(container)
    if DiceCount <= 0 then 
        MessageBoxPage:Msg_Box_Lan("@MonopolyFailed")
        return 
    end
    self:requestServerData(RequestType.reqData)
    NodeHelper:setMenuItemsEnabled(container, {mDiceBtn = false})
end

function MonopolyGameBase:PlayResult(msg)
    local flagpos = MonopolyData.Index
    local moveTime = msg.step * 0.7
    for i = 1 , msg.step do
        flagpos = flagpos+1
        if flagpos > MaxFlagPos then
            flagpos = MinFlagPos
        end
    end
    local array = CCArray:create()
    local funcrundice = CCCallFunc:create( function()
                self:rundice(msg.step)
            end)
    local funcmove = CCCallFunc:create( function()
                self:moveFlagTotarget(msg)
            end)
    local _extraReward ={}
    for i = 1, #msg.reward do
        _extraReward[i] = msg.reward[i]
    end
    local funreward =CCCallFunc:create( function()
            if #_extraReward > 0 then
                local rewardItems = {}
                for i = 1 , #_extraReward do
                    local reward = _extraReward[i];
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
           end)
    if flagpos == msg.Index then
        array:addObject(funcrundice)
        array:addObject(CCDelayTime:create(1))
        array:addObject(funcmove)
        array:addObject(CCDelayTime:create(moveTime))
        array:addObject(funreward)
        self.container:runAction(CCSequence:create(array))
    end
   
end

function MonopolyGameBase:refreshItem(container)
    MonopolyDoneItem:setState(0)
    MonopolyDoneItem:refresh(MonopolyDoneItem.container);
end

function MonopolyGameBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ACTIVITY141_S then
        local msg = Activity3_pb.Activity141RichManRep();
        msg:ParseFromString(msgBuff);
        if msg.type == RequestType.syncInfo  then
            self:analysisServerData(msg)
        else
            self:PlayResult(msg)
        end
    end
end

function MonopolyGameBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function MonopolyGameBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function MonopolyGameBase:requestServerData(type)
    local msg = Activity3_pb.Activity141RichManReq();
    msg.type = type;
    common:sendPacket(option.opcodes.ACTIVITY141_C, msg, true);
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGMapPage = CommonPage.newSub(MonopolyGameBase, thisPageName, option);
