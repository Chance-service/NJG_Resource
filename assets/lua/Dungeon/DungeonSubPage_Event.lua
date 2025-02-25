local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "DungeonSubPage_Event"
local HP_pb = require("HP_pb")
require("MainScenePage")
require("NewBattleConst")

local DungeonPageBase = { }
DungeonPageData = DungeonPageData or { isDirty = true }
DungeonPageData.CanGetCount = {}
DungeonPageData.Stars={}
local RewardItems={}

local option = {
    ccbiFile = "Dungeon.ccbi",
    handlerMap={
        onHelp="onHelp"
        }
}
local DungeonItem={
     ccbiFile = "DungeonItem.ccbi",
}
local DungeonItems = { }
local parentPage = nil

local supplementaryCountTable = {}

local MultiEliteCfg=ConfigManager.getMultiEliteCfg()
local MapInfo={
                type1={},
                type2={},
                type3={},
                type4={}
                }

local opcodes = {
    MULTI_BATTLE_AWARD_S = HP_pb.MULTI_BATTLE_AWARD_S,
    MULTIELITE_LIST_INFO_S = HP_pb.MULTIELITE_LIST_INFO_S,
    BATTLE_FORMATION_S = HP_pb.BATTLE_FORMATION_S,
}
local REFRESH_TIME = {12,24}
function DungeonPageBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 建立頁面UI ]]
function DungeonPageBase:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container,eventName)
        end
    end)
    
    return container
end

function DungeonPageBase:onEnter(container)
    self.container = container
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())
    local scrollView = container:getVarScrollView("mContent")
    --NodeHelper:autoAdjustResizeScrollview(scrollView)
    
    self:TableSort(container)
    if not DungeonPageData.isDirty then
        self:BuildScrollview(self.container)
    else
        self:InfoReq()
    end
    self:refreshAllPoint(container)

    parentPage:registerMessage(MSG_REFRESH_REDPOINT)
    require("TransScenePopUp")
    TransScenePopUp_closePage()
    --local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    --local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    --mainButtons:setVisible(true)
 end

function DungeonPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_DUNGEON);
end	

 function DungeonPageBase:TableSort(container)
    local cfg=MultiEliteCfg
    MapInfo={}
    for k, v in pairs(cfg) do
        local Type = v.eventType
        if not MapInfo[Type] then
            MapInfo[Type]={}
        end
        table.insert(MapInfo[Type], v)
    end

 end
function DungeonPageBase:onExit(container)
end
function DungeonPageBase:BuildScrollview(container)
    local scrollView = container:getVarScrollView("mContent")
    --NodeHelper:autoAdjustResizeScrollview(scrollView)
    scrollView:removeAllCell()
    local guideItem = nil
    DungeonItems = { }
    for i=1,#MapInfo do
        local cell=CCBFileCell:create()
        cell:setCCBFile(DungeonItem.ccbiFile)
        local panel = common:new( { id = i }, DungeonItem)
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
        if i == 1 then
            guideItem = cell
        end
        table.insert(DungeonItems, cell)
    end
    scrollView:orderCCBFileCells()
    -- 新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["DungeonItem_cell"] = guideItem
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end
function DungeonItem:refreshPoint(container, id)
    NodeHelper:setNodesVisible(container, { mBattlePoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.DUNGEON_CHALLANGE_BTN, id) })
    if DungeonPageData.Stars[id] and (DungeonPageData.Stars[id] == 1) then
        NodeHelper:setNodesVisible(container, { mRewardPoint = false })
    else
        NodeHelper:setNodesVisible(container, { mRewardPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.DUNGEON_REWARD_BTN, id) })
    end
end

function DungeonItem:checkBtnState(id)
    if not MapInfo[id] then
        return 0
    end
    local ItemInfo = MapInfo[id][math.min(DungeonPageData.Stars[id], #MapInfo[id])]
    local mapCfg = ConfigManager.getNewMapCfg()
    local mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or 
                  (mapCfg[UserInfo.stateInfo.passMapId] and UserInfo.stateInfo.passMapId or UserInfo.stateInfo.curBattleMap - 1)
    --[[1:關卡未達成, BP未達成;
        2:關卡達成,BP未達成;
        3:關卡未達成,BP達成;
        4:關卡達成,BP達成]]
    local BtnState = 1 
    if not UserInfo.roleInfo.marsterFight then return BtnState end
    if mapId > ItemInfo.stageLimit then
        if UserInfo.roleInfo.marsterFight < ItemInfo.powerLimit then
           BtnState = 2
        else
           BtnState = 4
        end
    else
        if UserInfo.roleInfo.marsterFight < ItemInfo.powerLimit then
           BtnState = 1
        else
           BtnState = 3
        end
    end
    return BtnState
end

function DungeonItem:onRefreshContent(content)
    local container=content:getCCBFileNode()
    local id=self.id
    local ItemInfo=MapInfo[id][math.min(DungeonPageData.Stars[id], #MapInfo[id])]
    local reward=ItemInfo.reward or {}
    
    --mapInfo
    UserInfo.sync()
    local mapCfg = ConfigManager.getNewMapCfg()
    local mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or 
                  (mapCfg[UserInfo.stateInfo.passMapId] and UserInfo.stateInfo.passMapId or UserInfo.stateInfo.curBattleMap - 1)

    --Sprite
    NodeHelper:setSpriteImage(container,{mSprite=ItemInfo.bgImg,mTitle=ItemInfo.TitleName})
    --Level
    NodeHelper:setStringForLabel(container,{mLevelTxt="Lv".. DungeonPageData.Stars[id]})
    --LockTxt
    if not MapInfo[id][DungeonPageData.Stars[id]+1] then
        NodeHelper:setStringForLabel(container,{mFightLimit=common:getLanguageString("@MultiStageMax")})
    elseif mapId > ItemInfo.stageLimit then
        NodeHelper:setStringForLabel(container,{mFightLimit=common:getLanguageString("@MultiBPUnlock",ItemInfo.powerLimit)})
    else
        local stageLimitCfg=mapCfg[ItemInfo.stageLimit]
        local txt=stageLimitCfg.Chapter.."-"..stageLimitCfg.Level
        NodeHelper:setStringForLabel(container,{mFightLimit=common:getLanguageString("@MultiStageUnlock",txt)})
    end
    --Reward
    for i=1,2 do
        local item=reward[i]
        if item then
            NodeHelper:setNodesVisible(container,{["mItem"..i]=true})
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(item.type, item.itemId, item.count)
            NodeHelper:setSpriteImage(container,{["mPic"..i]=resInfo.icon,["mFrame"..i] = NodeHelper:getImageBgByQuality(resInfo.quality)})
            NodeHelper:setStringForLabel(container,{["mNum"..i]=item.count})
            NodeHelper:setQualityFrames(container,{["mHand"..i]=resInfo.quality})
        else
            NodeHelper:setNodesVisible(container,{["mItem"..i]=false})
        end
    end 

    --BtnState
    local BtnState = self:checkBtnState(id)
    --[[1:關卡未達成, BP未達成;
        2:關卡達成,BP未達成;
        3:關卡未達成,BP達成;
        4:關卡達成,BP達成]]

    if BtnState==4 then
        NodeHelper:setNodesVisible(container,{mFightLimit=false,mFightTxt=true})
        NodeHelper:setMenuItemsEnabled(container,{mFightBtn=true})
    else
        NodeHelper:setNodesVisible(container,{mFightLimit=true,mFightTxt=false})
        NodeHelper:setMenuItemsEnabled(container,{mFightBtn=false})
    end

    self:refreshPoint(container, self.id)
    --一等關領取
    if DungeonPageData.Stars[id]==1 then
        NodeHelper:setNodesVisible(container,{mReceiveTxt=false,mReceiveBtn=false})
        return
    else
        NodeHelper:setNodesVisible(container,{mReceiveTxt=true,mReceiveBtn=true})
    end

    if DungeonPageData.CanGetCount[id]>0 then
        NodeHelper:setMenuItemsEnabled(container,{mReceiveBtn=true})
         NodeHelper:setStringForLabel(container,{mReceiveTxt=common:getLanguageString("@CanReceive")})
    else
         NodeHelper:setMenuItemsEnabled(container,{mReceiveBtn=false})
         DungeonPageBase:setRefreshTime(container)
         --NodeHelper:setStringForLabel(container,{mReceiveTxt=common:getLanguageString("@AlreadyReceive")})
    end
end
function DungeonPageBase:setRefreshTime(container)
    -- 獲取伺服器當前時間
    local curTime = common:getServerTimeByUpdate()
    local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
    local currentHour = curServerTime.hour

    -- 初始化變數
    local leftTime = 0
    local day_start = curTime - (curTime % 86400) - 3600*8  -- 當天起始時間戳
    local timestamp_next = 0

    -- 遍歷刷新時間，計算下一個刷新時間戳
    for i, v in ipairs(REFRESH_TIME) do
        if currentHour <= v then
            -- 如果是剛好到刷新點，跳過到下一個刷新時間
            if currentHour == v then
                v = REFRESH_TIME[(i % #REFRESH_TIME) + 1]  -- 下一個刷新時間
                day_start = day_start + (v == 0 and 86400 or 0)  -- 若跳到明天 0 點
            end

            timestamp_next = day_start + v * 3600
            leftTime = timestamp_next - curTime  -- 剩餘時間
            container.RefreshTime = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                -- 刷新處理邏輯
                leftTime = leftTime-1
                local txt = common:dateFormat2String(leftTime, true)
                NodeHelper:setStringForLabel(container,{ mReceiveTxt = txt })
                if leftTime <= 0 then
                     CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(container.RefreshTime)
                     container.RefreshTime = nil
                     DungeonPageBase:InfoReq()
                end
            end, 1, false)
            break
        end
    end
       -- Debug 打印下一次刷新時間
    --print("Next refresh time:", os.date("!*t", timestamp_next).hour, "Left time (s):", leftTime)
end
function DungeonPageBase:onExecute(container)

end
function DungeonItem:onHand1(container, eventName)
    local idx=self.id
    local reward= MapInfo[idx][DungeonPageData.Stars[idx]].reward[1]
    GameUtil:showTip(container:getVarNode('mPic1'), reward)
end
function DungeonItem:onHand2(container, eventName)
    local idx=self.id
    local reward= MapInfo[idx][DungeonPageData.Stars[idx]].reward[2]
    GameUtil:showTip(container:getVarNode('mPic2'), reward)
end
function DungeonItem:onFight(container)
    local idx = self.id
    local msg = Battle_pb.NewBattleFormation()
    msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
    msg.battleType = NewBattleConst.SCENE_TYPE.MULTI
    msg.mapId = tostring(MapInfo[idx][DungeonPageData.Stars[idx]].id)
    -- 紀錄紅點狀態
    CCUserDefault:sharedUserDefault():setIntegerForKey("DUNGEON_TYPE_" .. idx .. "_STAR_" .. UserInfo.playerInfo.playerId, DungeonPageData.Stars[idx])
    RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.DUNGEON_CHALLANGE_BTN, idx)

    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)--true)
end
function DungeonItem:onReceive(container)
   local idx=self.id
   local msg=MultiElite_pb.HPMultiEliteGetAwardReq()
   msg.type=idx
   local pb = msg:SerializeToString()
   PacketManager:getInstance():sendPakcet(HP_pb.MULTI_BATTLE_AWARD_C, pb, #pb, true)
end
function DungeonPageBase:InfoReq()
    common:sendEmptyPacket(HP_pb.MULTIELITE_LIST_INFO_C, false)
end
function DungeonPageBase:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode==HP_pb.MULTI_BATTLE_AWARD_S then
         local msg = MultiElite_pb.HPMultiEliteGetAwardRes()
         msg:ParseFromString(msgBuff)
         local rewards=msg.reward
         local rewardItems = {}
         for _, item in ipairs(common:split(rewards, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
             table.insert(rewardItems, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count),
                });
         end
         local CommonRewardPage = require("CommPop.CommItemReceivePage")
        CommonRewardPage:setData(rewardItems, common:getLanguageString("@ItemObtainded"), nil)
        PageManager.pushPage("CommPop.CommItemReceivePage")
        self:InfoReq()
    elseif opcode==HP_pb.MULTIELITE_LIST_INFO_S then
        DungeonPageData.CanGetCount={}
        local msg = MultiElite_pb.HPMultiEliteListInfoRet()
        msg:ParseFromString(msgBuff)
        for i=1,#MapInfo do
            DungeonPageData.CanGetCount[i]=msg.multiEliteInfo[i].LeftTimes
            DungeonPageData.Stars[i]=msg.multiEliteInfo[i].star
        end     
        DungeonPageBase:BuildScrollview(self.container)
        require("TransScenePopUp")
        TransScenePopUp_closePage()
    elseif opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            local battlePage = require("NgBattlePage")
            resetMenu("mBattlePageBtn", true)
            require("NgBattleDataManager")
            --NgBattleDataManager_setBattleType(NewBattleConst.SCENE_TYPE.MULTI)
            NgBattleDataManager_setDungeonId(tonumber(msg.mapId))
            PageManager.changePage("NgBattlePage")
	        --battlePage:requestTeamInfo(container)
            battlePage:onMultiBoss(self.container, msg.resultInfo, msg.battleId, msg.battleType, tonumber(msg.mapId))
        end
    end
end

function DungeonPageBase:refreshAllPoint(container)
    for i = 1, #DungeonItems do
        DungeonItem:refreshPoint(DungeonItems[i]:getCCBFileNode(), i)
    end
end

function DungeonPageBase:onReceiveMessage(message)
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(container)
    end
end

function DungeonPageBase_setDungeonData(msgBuff)
    DungeonPageData.CanGetCount = { }
    DungeonPageData.Stars = { }
    DungeonPageData.isDirty = false
    local msg = MultiElite_pb.HPMultiEliteListInfoRet()
    msg:ParseFromString(msgBuff)
    DungeonPageBase:TableSort(container)
    for i = 1, #MapInfo do
        DungeonPageData.CanGetCount[i] = msg.multiEliteInfo[i].LeftTimes
        DungeonPageData.Stars[i] = msg.multiEliteInfo[i].star
    end
end  

function DungeonPageBase_setDungeonDataDirty(isDirty)
    DungeonPageData = DungeonPageData or { }
    DungeonPageData.isDirty = isDirty
end

function DungeonPageBase_calCanReward(idx)
    local star = DungeonPageData.Stars[idx] and DungeonPageData.Stars[idx] or 0
    local getCount = DungeonPageData.CanGetCount[idx] and DungeonPageData.CanGetCount[idx] or 0
    return star > 1 and getCount > 0
end

function DungeonPageBase_calCanChallange(idx)
    if not DungeonPageData.Stars[idx] then
        return false
    end
    local state = DungeonItem:checkBtnState(idx)
    local star = CCUserDefault:sharedUserDefault():getIntegerForKey("DUNGEON_TYPE_" .. idx .. "_STAR_" .. UserInfo.playerInfo.playerId)

    return (state == 4) and (DungeonPageData.Stars[idx] ~= star)
end

return DungeonPageBase
