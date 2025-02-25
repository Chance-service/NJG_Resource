local NodeHelper = require("NodeHelper")
local thisPageName = 'Event001BattlePage'
local InfoAccesser = require("Util.InfoAccesser")
local Event001Page = require "Event001Page"
local HP_pb = require("HP_pb")
local Dungeon_pb= require("Dungeon_pb")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local ResManager = require("ResManagerForLua")
local ItemManager = require("Item.ItemManager")
local EventDataMgr = require("Event001DataMgr")

local Event001BattleBase =  {}
local opcodes = {
    BATTLE_FORMATION_S = HP_pb.BATTLE_FORMATION_S,
    CYCLE_ONEKEY_CLEARANCE_S = HP_pb.CYCLE_ONEKEY_CLEARANCE_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S
}
local option = {
    ccbiFile = EventDataMgr[EventDataMgr.nowActivityId].BATTLEPAGE_CCB,
    handlerMap ={},
    opcodes = opcodes
}
--5555
local PageContent = {
    ccbiFile = EventDataMgr[EventDataMgr.nowActivityId].BATTLEPAGE_CONTENT_CCB,
}



local MainContainer = nil

local nowMode = 1 

local EasyStageCount = 0

local StageInfo = { }

local BuildTable = { }

local CountDown = {}

local ItemUsingCount = 1

local NowClickingId = 0

function Event001BattleBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function Event001BattleBase:onEnter(container)
    MainContainer = container
    self:registerPacket(container)
    container:registerFunctionHandler(Event001BattleBase.onFunction)
    StageInfo = Event001Page:getStageInfo()
    self:refresh(container)
    require("TransScenePopUp")
    TransScenePopUp_closePage()

    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getTargetScaleProportion(1600, 720))
end

function Event001BattleBase:refresh(container)
  Event001BattleBase:BuildScrollview(container)
  local Count_7003 = InfoAccesser:getUserItemInfo(Const_pb.TOOL, EventDataMgr[EventDataMgr.nowActivityId].CHALLANGE_ID).count or 0
  local stringTable = {}
  stringTable["mCount"] = common:getLanguageString("@activitystageCount",Count_7003)
  NodeHelper:setStringForLabel(container,stringTable)

  NodeHelper:setMenuItemsEnabled(container,{mNormalBtn = nowMode ~= 1,mHardBtn = nowMode ~= 2})

  --UseItemContent
  --NodeHelper:setNodesVisible(container,{mCountNode = false })
  container:runAnimation("Default Timeline")
  local stringTable = {}
  stringTable["mCost"] = common:getLanguageString("@SurplusSearchTimes")
  stringTable["mCostCount"] = Count_7003
  stringTable["mNum"] = ItemUsingCount
  stringTable["mTitle"] = common:getLanguageString("@FastSweep")
  stringTable["mContent"] = common:getLanguageString("@FastSweepDesc")
  stringTable["BtnTxt"] = common:getLanguageString("@FastSweep")
  NodeHelper:setStringForLabel(container,stringTable)
end

function Event001BattleBase.onFunction(eventName,container)
    if eventName == "luaLoad" then
        Event001BattleBase:onLoad(container)
    elseif eventName == "luaEnter" then
        Event001BattleBase:onEnter(container)
    elseif eventName =="onReturn" then
        local cfg = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG
        for k,v in pairs (cfg) do
            if CountDown[v.id] then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(CountDown[v.id])
                CountDown[v.id] = nil
            end
        end
        PageManager.popPage(thisPageName)
    elseif eventName == "onNormal" then
        nowMode =1
        Event001BattleBase:refresh(container)
    elseif eventName == "onHard" then
        if StageInfo.PassedId <EasyStageCount then
            MessageBoxPage:Msg_Box(common:getLanguageString("@activitystagetNotice04"))
            return
        end
        nowMode =2
        Event001BattleBase:refresh(container)
    elseif eventName =="luaReceivePacket" then
        Event001BattleBase:onReceivePacket(container)
    elseif eventName == "onClose" then
         NodeHelper:setNodesVisible(container,{mCountNode = false })
    elseif eventName == "onAmountBtn_add" then
        ItemUsingCount = ItemUsingCount + 1
        Event001BattleBase:setNum()
    elseif eventName == "onAmountBtn_sub" then
        ItemUsingCount = ItemUsingCount - 1
        Event001BattleBase:setNum()
    elseif eventName == "onAmountBtn_min" then
        ItemUsingCount = 1
        Event001BattleBase:setNum()
    elseif eventName == "onAmountBtn_max" then
        ItemUsingCount = InfoAccesser:getUserItemInfo(Const_pb.TOOL, EventDataMgr[EventDataMgr.nowActivityId].CHALLANGE_ID).count
        Event001BattleBase:setNum()
    elseif eventName == "onOneBtn" then
        NodeHelper:setNodesVisible(container,{mCountNode = false })
        local msg = Dungeon_pb.HPCycleStageOneKeyRet()
        msg.mapId = tonumber(NowClickingId)
        msg.count = ItemUsingCount
        common:sendPacket(HP_pb.CYCLE_ONEKEY_CLEARANCE_C, msg, false)
    end
end

function Event001BattleBase:setNum()
    local Count_7003 = InfoAccesser:getUserItemInfo(Const_pb.TOOL, EventDataMgr[EventDataMgr.nowActivityId].CHALLANGE_ID).count or 0
    if ItemUsingCount < 1 then
        ItemUsingCount = 1
    elseif ItemUsingCount > Count_7003 then
        ItemUsingCount = Count_7003
    end
    NodeHelper:setStringForLabel(MainContainer,{ mNum = ItemUsingCount })
end

function Event001BattleBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            local battlePage = require("NgBattlePage")
            resetMenu("mBattlePageBtn", true)
            require("NgBattleDataManager")
            NgBattleDataManager_setDungeonId(tonumber(msg.mapId))
            PageManager.changePage("NgBattlePage")
            battlePage:onCycle(self.container, msg.resultInfo, msg.battleId, msg.battleType, tonumber(msg.mapId))
        end
    end
    if opcode == HP_pb.CYCLE_ONEKEY_CLEARANCE_S then
        common:sendEmptyPacket(HP_pb.CYCLE_LIST_INFO_C,false)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)    
    end
end

function PageContent:onFast()
     --local SliderHelper = require("SliderHelper")
     --local sliderOption = {
     --    bgFile = "CombatStats_bar1.png",                    -- �I���Ϥ�
     --    progressFile = "CombatStats_bar3.png",              -- �i�ױ��Ϥ�
     --    thumbFile = "Icon_Hcoin.png",                       -- �ƶ��Ϥ�
     --    position = ccp(360, 160),                           -- �ƶ���m
     --    minValue = 1,                                       -- �̤p��
     --    maxValue = 100,                                     -- �̤j��
     --    initialValue = 1,                                  -- ��l��
     --    parentNode = MainContainer:getVarNode("mCountNode"), -- ���`�I
     --    step = 10,                                           -- �B��
     --}
     --local slider = SliderHelper:createSlider(sliderOption)
     --
     ---- �ʺA�ʱ��ƶ����ܤ�
     --SliderHelper:monitorSliderValue(slider, function(currentValue)
     --    print(string.format("Slider Value: %.2f", currentValue))
     --end)

     local itemCount = InfoAccesser:getUserItemInfo(Const_pb.TOOL, EventDataMgr[EventDataMgr.nowActivityId].CHALLANGE_ID).count or 0
     if itemCount < 1 then
         MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_25015"))
         return
     end

     --NodeHelper:setNodesVisible(MainContainer,{mCountNode = true }) 
     MainContainer:runAnimation("WindowPopout")
     NowClickingId = self.Info.id 
    Event001BattleBase.rewardItems = self.Info.dropItems
     NodeHelper:initScrollView(MainContainer, "mFastScrollview", #Event001BattleBase.rewardItems);
     Event001BattleBase:updateItems()
end
function Event001BattleBase:updateItems()
	local size = #self.rewardItems
		
	local colMax = 3

	local options = {
		-- magic layout number 
		-- �]��CommonRewardContent�ؤo���`�A�ɭP�U�ϥγB�ݭn�ۦ�B�z
		interval = ccp(0, 0),
		colMax = colMax,
		paddingTop = 0,
		paddingBottom = 0,
		originScrollViewSize = CCSizeMake(550, 100),
		isDisableTouchWhenNotFull = true,
        ItemScale = 0.7
	}

	-- ���� 1�� �h ��V�m��
	if size < colMax then
		options.isAlignCenterHorizontal = true
	end
	
	-- ���F 2�� �h �����m��
	if size <= colMax then
		options.isAlignCenterVertical = true
		options.startOffset = ccp(0, 0)
	-- �F�� 2�� �h �����b���� �� ����paddingTop
	else
		options.startOffsetAtItemIdx = 1
		options.startOffset = ccp(0, -options.paddingTop)
	end

	--[[ �u�ʵ��� ���W�ܥk�U ]]
	NodeHelperUZ:buildScrollViewGrid_LT2RB(
		MainContainer,
		size,
		"CommonRewardContent.ccbi",
		function (eventName, container)
			self:onScrollViewFunction(eventName, container)
		end,
		options
	)
			
	-- ���/���� �C�� �� �L���y����
	NodeHelper:setNodesVisible(SelfContainer, {
		mContent = size ~= 0
	})
	
	-- �Y �ƶq �|���W�L �C��ƶq ����
	if size <= colMax  then
		local node = MainContainer:getVarNode("mFastScrollview")
		node:setTouchEnabled(false)
	end
end
function Event001BattleBase:onScrollViewFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		--- �C?�l��??�ت�?��??��??��?
		local contentId = container:getItemDate().mID;
		-- ?����?�ĤL��
		local idx = contentId
		-- ?��?�e��index      i�O�C�檺�ĤL? ��??��?��Ϊ�
		local node = container:getVarNode("mItem")
		local itemNode = ScriptContentBase:create('GoodsItem.ccbi')

		local itemData = self.rewardItems[idx]
		local resInfo = ResManager:getResInfoByTypeAndId(itemData and itemData.type or 30000, itemData and itemData.itemId or 104001, itemData and itemData.count or 1);
		--NodeHelper:setStringForLabel(itemNode, { mName = "" });
		local numStr = ""
		if resInfo.count > 0 then
			numStr = tostring(resInfo.count)
		end
		local lb2Str = {
			mNumber = numStr
		};
		local showName = "";
		if itemData and itemData.type == 30000 then
			showName = ItemManager:getShowNameById(itemData.itemId)
		else
			showName = resInfo.name           
		end
		NodeHelper:setNodesVisible(itemNode, { m2Percent = false, m5Percent = false });

		if itemData.type == 40000 then
			for i = 1, 6 do
				NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.quality })
			end
		end
		NodeHelper:setNodesVisible(itemNode, { mStarNode = itemData.type == 40000 })
		
		--NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.BlurryLineWidth - 10, 4)
		NodeHelper:setStringForLabel(itemNode, lb2Str);
		NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = 1 });
		NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality });
		NodeHelper:setColorForLabel(itemNode, { mName = ConfigManager.getQualityColor()[resInfo.quality].textColor })
		NodeHelper:setNodesVisible(itemNode, { mName = false})

		node:addChild(itemNode);
		itemNode:registerFunctionHandler(function (eventName, container)
			if eventName == "onHand" then
				local id = container.id
				GameUtil:showTip(container:getVarNode("mHand"), self.rewardItems[id])
			end  
		end)
		itemNode.id = contentId
	end
end
function PageContent:onFight()
    -- �����ˬd�G�O�_����
    local nextId = 1
    if StageInfo.PassedId ~=0 then
         nextId = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG[StageInfo.PassedId].nextId
    end
    if nextId == 0 then
        nextId = StageInfo.PassedId
    end
    if nextId < self.Info.id then
        MessageBoxPage:Msg_Box(common:getLanguageString("@activitystagetNotice02"))
        return
    end

    -- �ˬd�O�_�w�q���B���i���ƬD��
    if StageInfo.PassedId >= self.Info.id then
        if self.Info.replay == 0 then -- ���] replay=0 �N���i���ƬD��
            MessageBoxPage:Msg_Box(common:getLanguageString("@activitystagetNotice01"))
            return
        end
    end

    -- �ˬd�D�ԹD��Φ��ƬO�_����

     local itemCount = InfoAccesser:getUserItemInfo(Const_pb.TOOL, EventDataMgr[EventDataMgr.nowActivityId].CHALLANGE_ID).count or 0
     if itemCount < 1 then
         MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_25015"))
         return
     end

    -- �ˬd�O�_�F�����ɶ�
    if self.Info.unlockTime then
        local unlockTimestamp = StageInfo.startTime + self.Info.unlockTime * 3600
        local currentTime = os.time()
        if currentTime < unlockTimestamp then
            local timeRemaining = unlockTimestamp - currentTime
            local formattedTime = common:dateFormat2String(timeRemaining, true)
            MessageBoxPage:Msg_Box(common:getLanguageString("@activitystagetNotice03", formattedTime))
            return
        end
    end

    local fetterControlCfg = EventDataMgr[EventDataMgr.nowActivityId].FETTER_CONTROL_CFG
    local chapter = self.Info.type
    local level = self.Info.star
    local id = tonumber(chapter..string.format("%02d",level).."101")
    NgBattleDataManager.battleMapId = self.Info.id
    --if fetterControlCfg[id] then
    --    if StageInfo.PassedId < self.Info.id then
    --        require("Event001AVG")
    --        Event001AVG_setPhotoRole(nil, chapter, level, 1 )
    --        PageManager.pushPage("Event001AVG")
    --    end
    --end
    -- �p�G�Ҧ����󳣲ŦX�A�o�e�D�ԫʥ]
    local msg = Battle_pb.NewBattleFormation()
    msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
    msg.battleType = NewBattleConst.SCENE_TYPE.CYCLE_TOWER
    msg.mapId = tostring(self.Info.id)
    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, true)
end

function Event001BattleBase:BuildScrollview(container)
   local cfg = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG
   local EasyTable = {}
   local HardTable = {}
   for _,v in pairs(cfg) do
        if v.type == 1 then
            table.insert(EasyTable,v)
        elseif v.type ==2 then
            table.insert(HardTable,v)
        end
   end

   EasyStageCount = #EasyTable

   local Scrollview = container:getVarScrollView("mContnet")
   if not Scrollview then
        return
   end
    Scrollview:removeAllCell()
   local BuildTable = (nowMode == 1) and EasyTable or HardTable

   for _,value in pairs (BuildTable) do
        local cell = CCBFileCell:create()
        cell:setCCBFile(PageContent.ccbiFile)
        local panel = common:new( { Info=value}, PageContent)
        cell:registerFunctionHandler(panel)
        Scrollview:addCell(cell)
   end
   Scrollview:orderCCBFileCells()
end

function Event001BattleBase:sendQuest(_action,_id)
   
end


function PageContent:onRefreshContent(ccbRoot)
    -- ����`�I�e��
    local container = ccbRoot:getCCBFileNode()
    local data = self.Info
    local item = data.dropItems[1]
    local countdownTime = 0

    -- �]�m�`�I���i����
    local function setLockState(isLocked)
        NodeHelper:setNodesVisible(container, { mLock = isLocked })
    end

    local function setBannerState(isClose)
        if isClose then
            NodeHelper:setScale9SpriteImage2(container,{ mBg = EventDataMgr[EventDataMgr.nowActivityId].BATTLE_BG_IMG })
        else
            NodeHelper:setScale9SpriteImage2(container,{mBg = data.Banner})
        end
    end

    -- �]�m���d�W��
    NodeHelper:setStringForLabel(container, { mName = data.StageName })
    NodeHelper:setNodesVisible(container,{ mFast = false,mCheckBox = false})

    -- �p��˭p�ɮɶ�
    if data.unlockTime then
        local unlockTimestamp = StageInfo.startTime + data.unlockTime * 3600
        local currentTime = os.time()
        if currentTime < unlockTimestamp then
            countdownTime = unlockTimestamp - currentTime
        end
    end


    -- �ھڳq�L�����dID�M�˭p�ɮɶ��]�m��w���A
    local nextId = 1
    if StageInfo.PassedId ~= 0 then 
        nextId = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG[StageInfo.PassedId].nextId
    end
    if nextId == data.id then
        if countdownTime > 0 then
            local formattedTime = common:dateFormat2String(countdownTime, true)
            local noticeText = common:getLanguageString("@activitystagetNotice03", formattedTime)
            self.TimeTxt = noticeText
            setLockState(true) -- �����w
            setBannerState(true) 
        else
            setLockState(false) -- ����
            setBannerState(false)
            NodeHelper:setNodesVisible(container,{ mFast = false})
        end
    elseif StageInfo.PassedId >= data.id then
        setLockState(false) -- ����
        setBannerState(false)
        NodeHelper:setNodesVisible(container,{ mCheckBox = true})       
        if data.replay == 1 then
             NodeHelper:setNodesVisible(container,{ mFast = true})
        elseif data.replay == 0 then
             NodeHelper:setNodesVisible(container,{ mFast = false})
        end
    else
        setLockState(true) -- �����w
        setBannerState(true)
        NodeHelper:setNodesVisible(container,{ mFast = false})
    end
end


function PageContent:onBtn()
   
end

function Event001BattleBase:SetStageInfo(msg)
    StageInfo.PassedId = msg.passId
    StageInfo.startTime = msg.starTime/1000
    StageInfo.leftTime = msg.leftTime
    StageInfo.useItem = msg.item
    if MainContainer then
        self:refresh(MainContainer)
    end

    local Event001Page = require "Event001Page"
    Event001Page:refresh()
end

function PageContent:onHand1(container)
    
end

function Event001BattleBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function Event001BattleBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

function Event001BattleBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_GLORY_HOLE)
end

local CommonPage = require('CommonPage')
local Event001Page = CommonPage.newSub(Event001BattleBase, thisPageName, option)

return Event001Page
