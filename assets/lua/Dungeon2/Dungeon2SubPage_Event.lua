local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "Dungeon2.Dungeon2SubPage_Event"
local HP_pb = require("HP_pb")
local Dungeon_pb= require("Dungeon_pb")
local TimeDateUtil = require("Util.TimeDateUtil")
require("MainScenePage")
require("NewBattleConst")

local DungeonPageBase = {}
local DungeonInfos={ }
local option = {
    ccbiFile = "AttributesDungeons.ccbi",
    handlerMap={
        onHelp="onHelp"
        }
}
for i=1 ,5 do
    option.handlerMap["onFast"..i] = "onFast"
    option.handlerMap["onFight"..i] = "onFight"
end
local parentPage = nil

local VIPLIMIT=3

local MultiElite2Cfg=ConfigManager.getMultiElite2Cfg()
local MapInfo={
                type1={},
                type2={},
                type3={},
                type4={}
                }

local opcodes = {
    DUNGEON_LIST_INFO_S = HP_pb.DUNGEON_LIST_INFO_S,
    DUNGEON_ONEKEY_CLEARANCE_S = HP_pb.DUNGEON_ONEKEY_CLEARANCE_S,
    DUNGEON_BATTLE_LOG_S = HP_pb.DUNGEON_BATTLE_LOG_S,
    BATTLE_FORMATION_S = HP_pb.BATTLE_FORMATION_S,
}
local Stars={}
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
    --local scrollView = container:getVarScrollView("mContent")
    --NodeHelper:autoAdjustResizeScrollview(scrollView)
    --scrollView:resetContainer()
    ---- 初始化
    --for i = 1, 4 do
    --    NodeHelper:setNodesVisible(container, { ["mTxt" .. i] = false,["mPopBanner_"..i+2]=false} )
    --    NodeHelper:setStringForLabel(container,{["mReceiveTxt" .. i]=common:getLanguageString("@function_14")})
    --    if UserInfo.playerInfo.vipLevel>VIPLIMIT then
    --        NodeHelper:setMenuItemsEnabled(container,{["mReceiveBtn" .. i]=true})
    --    else
    --         NodeHelper:setMenuItemsEnabled(container,{["mReceiveBtn" .. i]=false})
    --    end
    --end
    --
    DungeonInfos={}
    self:TableSort(container)
    self:InfoReq()
    self:refresh(container)
    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(true)
    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())

    -- 新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
 end

function DungeonPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_DUNGEON_ELEMENT);
end	
function DungeonPageBase:TableSort(container)
    local cfg = MultiElite2Cfg
    MapInfo={}
    for k,v in pairs (cfg) do
        local dungeonType = tonumber(v.DungeonType)
        if not MapInfo[dungeonType] then
            MapInfo[dungeonType]={}
        end
        table.insert(MapInfo[dungeonType],v)
    end
end

 function DungeonPageBase:ShowItem(container,idx,event)
    --[[
        mFrame,mPic,mNum,mHand
    ]]
    local sprite2Img={}
    local lb2Str={}
    local menu2Quality={}
    local items=event.reward
    --道具個數顯示
    for i=1 ,2 do
        if #items < i then
            NodeHelper:setNodesVisible(container,{["mItem_"..event.DungeonType+2 .."_"..i ]=false})
        end
    end
    for i=1,#items do
        local item=items[i]
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(item.type, item.itemId, item.count)
        if resInfo ~= nil then
            sprite2Img["mPic" .. i + idx-1] = resInfo.icon
            lb2Str["mNum" .. i + idx-1] = "x" .. GameUtil:formatNumber(item.count)
            menu2Quality["mHand" .. i + idx-1] = resInfo.quality
            sprite2Img["mFrame".. i + idx-1] = NodeHelper:getImageBgByQuality(resInfo.quality)
            RewardItems[i + idx-1]=items[i]
        else
            CCLuaLog("Error::***reward item not found!!")
        end
    end
    lb2Str["mLevelTxt" .. event.DungeonType] = common:getLanguageString("@LevelStr", event.star)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setQualityFrames(container, menu2Quality)
 end
function DungeonPageBase:refresh(container)
  for i=1,5 do
    NodeHelper:setNodesVisible(self.container,{["mMask"..i]=true,["mProgess"..i]=false,["mOpenDay"..i]=true,["mFastNode"..i]=false})
    NodeHelper:setMenuItemsEnabled(container,{["mFast"..i]=false})
    if DungeonPageBase:Finish(container,i) then
        NodeHelper:setStringForLabel(container,{["mOpenDay"..i]=common:getLanguageString("@Accomplish")})
        require("TransScenePopUp")
        TransScenePopUp_closePage()
    end
  end
  for i=1 ,5 do
    NodeHelper:setStringForLabel(container,{["mFightTimes"..i]=common:getLanguageString("@ActivityNotOpen")})
  end
  for k,value in pairs (DungeonInfos) do
    local idx=value.Type
    NodeHelper:setNodesVisible(container,{["mMask"..idx]=false,["mProgess"..idx]=true,["mFightTimes"..idx]=true,["mOpenDay"..idx]=false,["mFastNode"..idx]=true})
    local canFast = false
    if value.Star<=value.maxStar and value.maxStar>3 and value.onekey==0 then
        canFast=true
    end
    local FastNum = math.max(tonumber(value.maxStar) - 3, 0)
    local text  = common:getLanguageString("@SkipStage",FastNum)
    NodeHelper:setMenuItemsEnabled(container,{["mFast"..idx]=canFast})
    NodeHelper:setStringForLabel(container,{["mProgess"..idx]=common:getLanguageString("@AttributesDungeonsTxt01",value.Star),
                                            ["mFastTxt"..idx]=text,
                                            ["mFightTimes"..idx]=common:getLanguageString("@AttributesDungeonsTxt02", math.max(0, value.leftTimes), 1)})
  end
end
function DungeonPageBase:onExit(container)
  
end
function DungeonPageBase:Finish(container,mID)
    if not DungeonInfos[mID] and MapInfo[mID][1] then
        local wday = (TimeDateUtil:utcTime2LocalDate(os.time()).wday - 1 + 7) % 7
        local OpenDays = common:split(MapInfo[mID][1].openedDay, ",")
        for _, value in ipairs(OpenDays) do
            if tonumber(value) == wday then
                return true
            end
        end
    end
    return false
end
function DungeonPageBase:onExecute(container)

end
function DungeonPageBase:onHand(container, eventName)
    local idx=tonumber(eventName:sub(-1))
    GameUtil:showTip(container:getVarNode('mPic' .. idx), RewardItems[idx])
end
function DungeonPageBase:onFight(container, eventName)
    local idx = tonumber(eventName:sub(-1))
    local msg = Battle_pb.NewBattleFormation()
    local mapId=0
    for k,v in pairs (DungeonInfos) do
        if v.Type==idx then
            if v.leftTimes <= 0 then
                MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_25015"))
                return
            end
            mapId=v.MapId
        end
    end
    if mapId==0 then
        local isfinish = DungeonPageBase:Finish(container,idx)
        if isfinish  then
           MessageBoxPage:Msg_Box(common:getLanguageString("@Accomplish"))
        else
            MessageBoxPage:Msg_Box(common:getLanguageString("@AttributesDungeons0"..idx))
        end
        return 
    end
    msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
    msg.battleType = NewBattleConst.SCENE_TYPE.DUNGEON
    msg.mapId = tostring(mapId)
    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, true)
end
function DungeonPageBase:InfoReq()
    common:sendEmptyPacket(HP_pb.DUNGEON_LIST_INFO_C, false)
end
function DungeonPageBase:onFast(container, eventName)
    local idx = tonumber(eventName:sub(-1))
    local msg = Dungeon_pb.HPDungeonOneKeyRet()
    msg.type=idx
    common:sendPacket(HP_pb.DUNGEON_ONEKEY_CLEARANCE_C, msg, false)--true)
end
function DungeonPageBase_setData(msg)
    DungeonInfos={}
    for i=1,#msg.dungeonInfo do
        local DungeonType=tonumber(msg.dungeonInfo[i].dungeonType)
        DungeonInfos[DungeonType]={
                                    MapId=msg.dungeonInfo[i].dungeonMapId,
                                    Type=msg.dungeonInfo[i].dungeonType,
                                    leftTimes=msg.dungeonInfo[i].leftTimes,
                                    Star=msg.dungeonInfo[i].star,
                                    maxStar=msg.dungeonInfo[i].maxstar,
                                    onekey=msg.dungeonInfo[i].onekey
                                    }
        Stars[i]=msg.dungeonInfo[i].star
    end
end
function DungeonPageBase:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode==HP_pb.DUNGEON_ONEKEY_CLEARANCE_S then
         local msg = Dungeon_pb.HPDungeonOneKeyRes()
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
    elseif opcode==HP_pb.DUNGEON_LIST_INFO_S then
        local msg = Dungeon_pb.HPDungeonListInfoRet()
        msg:ParseFromString(msgBuff)
        DungeonPageBase_setData(msg)
        self:refresh(self.container)
    elseif opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            local battlePage = require("NgBattlePage")
            resetMenu("mBattlePageBtn", true)
            require("NgBattleDataManager")
            NgBattleDataManager_setDungeonId(tonumber(msg.mapId))
            PageManager.changePage("NgBattlePage")
            battlePage:onDungeon(self.container, msg.resultInfo, msg.battleId, msg.battleType, tonumber(msg.mapId))
        end
    end
end
return DungeonPageBase
