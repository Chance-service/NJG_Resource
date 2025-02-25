----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local MercenaryExpedition_pb = require("MercenaryExpedition_pb")
local Recharge_pb = require "Recharge_pb"
local UserInfo = require("PlayerInfo.UserInfo")
local UserMercenaryManager = require("UserMercenaryManager")
local NgHeadIconItem = require("NgHeadIconItem")
local thisPageName = "MercenaryExpeditionSendPageNew"
local MercenaryExpeditionSendPage = {}
local roleConfig = {}
local LevelLimit = 0
local rewardItem = {}
local SingleTask = {};
local mCurHeroElement = 0
local mCurHeroClass = 0
local DisPatchHero = {}
local _mercenaryInfos = {}
local limits = {}
local LimitComplete = {}
local option = {
    ccbiFile = "MercenaryExpeditionSendPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onHelp = "onHelp",
        onImmediatelyDekaron = "onClose",
        onExpeditionMenuBtn = "onExpeditionMenuBtn",
        onFilter = "onFilter",
        onAuto = "onAuto",
        onFrame1 = "onFrame1",
    },
    opcodes = {
    }
}
for i = 0, 5 do
    option.handlerMap["onElement" .. i] = "onElement"
end
for i = 0, 4 do
    option.handlerMap["onClass" .. i] = "onClass"
end
for i = 1, 3 do
    option.handlerMap["onHead" .. i] = "onHead"
end
local mercenaryHeadContent = {}
local HEAD_SCALE = 0.85
local headIconSize = CCSize(170 * HEAD_SCALE, 270 * HEAD_SCALE)
local FILTER_WIDTH = 500
local FILTER_OPEN_HEIGHT = 142
local FILTER_CLOSE_HEIGHT = 74
local filterOpenSize = CCSize(FILTER_WIDTH, FILTER_OPEN_HEIGHT)
local filterCloseSize = CCSize(FILTER_WIDTH, FILTER_CLOSE_HEIGHT)
local myMercenary = {}--当前的佣兵列表
local _mercenaryContainerInfo = {}
local TaskInfo = {
    taskId = 0,
    taskStatus = 0,
    taskRewards = nil,
    mercenaryId = 0,
    lastTimes = 0
}
function MercenaryExpeditionSendPage:onEnter(container)
    DisPatchHero = {}
    NgHeadIconItem_setPageType(GameConfig.NgHeadIconType.BOUNTY_PAGE)
    myContainer = container
    self.mAllHeroItem = {}
    NodeHelper:initScrollView(container, "mContent", 3);
    roleConfig = ConfigManager.getRoleCfg()
    nExpeditionCount = 0
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    filterBg:setContentSize(filterCloseSize)
    NodeHelper:setNodesVisible(container, {mClassNode = false})
    for i = 0, 4 do
        container:getVarSprite("mClass" .. i):setVisible(class == i)
    end
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    NodeHelper:setNodeIsGray(container, {mStarNum = true, mStarSprite = true, mElement = true, mClass = true, mExpeditionMenuBtn = true})
    --NodeHelper:setMenuItemsEnabled(container, {mExpeditionMenuBtn = false})
    self:refreshPage(container)
end
function MercenaryExpeditionSendPage:onFrame1(container)
    GameUtil:showTip(container:getVarNode("mFrame"), rewardItem[1])
end
function MercenaryExpeditionSendPage:refreshPage(container)
    _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
    QuestHeroFilter()
    local Rewards = rewardItem[1]
    local ResInfo = ResManagerForLua:getResInfoByTypeAndId(Rewards.type, Rewards.itemId, Rewards.count)
    local sprite2Img = {}
    sprite2Img["mPic"] = ResInfo.icon
    sprite2Img["mBg"] = NodeHelper:getImageBgByQuality(ResInfo.quality)
    sprite2Img["mElement"] = GameConfig.MercenaryElementImg[limits.Element]
    sprite2Img["mClass"] = GameConfig.MercenaryClassImg[limits.Class]
    NodeHelper:setQualityFrames(container, {mFrame = ResInfo.quality})
    NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setStringForLabel(container, {mStarNum = limits.Star, mNum = ResInfo.count})
    if _mercenaryInfos.roleInfos == nil then
        return
    end
    local roleInfos = _mercenaryInfos.roleInfos
    sortData(roleInfos)
    container.mScrollView:removeAllCell()
    self:buildHeroScrollView(container)
end
function QuestHeroFilter()
    local TaskId = SingleTask.taskId
    local cfg = ConfigManager.getMercenaryExpeditionCfg()[TaskId]
    limits.Star = cfg.Starlimit
    limits.Class = cfg.Classlimit
    limits.Element = cfg.Elementlimit
    rewardItem = cfg.reward
end
function MercenaryExpeditionSendPage:buildHeroScrollView(container)
    local cell = nil
    local items = {}
    for i = 1, #_mercenaryInfos.roleInfos do
        local roleInfo =UserMercenaryManager:getUserMercenaryById(_mercenaryInfos.roleInfos[i].roleId)
        -- 已啟用的英雄
        if roleInfo and _mercenaryInfos.roleInfos[i].type ~= Const_pb.RETINUE and _mercenaryInfos.roleInfos[i].roleStage == Const_pb.IS_ACTIVITE then
            local iconItem = NgHeadIconItem:createCCBFileCell(_mercenaryInfos.roleInfos[i].roleId, i, container.mScrollView, GameConfig.NgHeadIconType.HERO_PAGE)
            NgHeadIconItem:setRoleData(iconItem)
            table.insert(items, iconItem --[[common:deepCopy(iconItem)]])
        end
    end
    self.mAllHeroItem = items
    
    if self.mAllHeroItem then
        for i = 1, #self.mAllHeroItem do
            self.mAllHeroItem[i].cell:setScale(0.85)
            self.mAllHeroItem[i].cell:setContentSize(headIconSize)

            --for j=1,#_mercenaryInfos.roleInfos do
            --   if  _mercenaryInfos.roleInfos[j].roleId==self.mAllHeroItem[i].handler.roleId then
            --        self.mAllHeroItem[i].cell:setContentSize(CCSize(0,0))
            --   end
            --end
        end
    end
    container.mScrollView:orderCCBFileCells()
end

function mercenaryHeadContent:onHead(id)
    if not id or id <= 0 then
        return
    end
   
    local mInfoSorts = UserMercenaryManager:getMercenaryStatusInfos()
    local info = mInfoSorts[id]
    local MercenaryId = info.roleId
    for j=1,#_mercenaryInfos.roleInfos do
        if  _mercenaryInfos.roleInfos[j].roleId==MercenaryId and (_mercenaryInfos.roleInfos[j].status==Const_pb.EXPEDITION or _mercenaryInfos.roleInfos[j].status==Const_pb.MIXTASK) then
            return
        end
    end
    local headNode = ScriptContentBase:create("EquipmentPage_new_Item.ccbi")
    local Count = 0
    for i = 1, 3 do
        if DisPatchHero[i] ~= nil then
            Count = Count + 1
        end
    end
    if Count < 3 then
        for i = 1, 3 do
            if (DisPatchHero[i] == MercenaryId and DisPatchHero[i] ~= nil) then
                return
            end
        end
        if DisPatchHero[1] == nil then
            DisPatchHero[1] = MercenaryId
            myContainer:getVarNode("mHeadNode1"):removeAllChildren()
            myContainer:getVarNode("mHeadNode1"):addChild(headNode)
        elseif DisPatchHero[2] == nil then
            DisPatchHero[2] = MercenaryId
            myContainer:getVarNode("mHeadNode2"):removeAllChildren()
            myContainer:getVarNode("mHeadNode2"):addChild(headNode)
        elseif DisPatchHero[3] == nil then
            table.insert(DisPatchHero, MercenaryId)
            myContainer:getVarNode("mHeadNode3"):removeAllChildren()
            myContainer:getVarNode("mHeadNode3"):addChild(headNode)
        end
    end
    local curRoleInfo = UserMercenaryManager:getUserMercenaryById(MercenaryId)
    headNode:setAnchorPoint(ccp(0.5, 0.5))
    headNode:setScale(0.7)
    headNode:setPositionX(headNode:getPositionX() - 1.2)
    headNode:setPositionY(headNode:getPositionY() - 0.5)
    headNode:release()
    if curRoleInfo then
        local itemId = curRoleInfo.itemId
        local heroCfg = ConfigManager.getNewHeroCfg()[itemId]
        local quality = (curRoleInfo.starLevel <= 5 and 4) or (curRoleInfo.starLevel >= 11 and 6) or 5
        NodeHelper:setStringForLabel(headNode, {mLv = "Lv." .. curRoleInfo.level,
            mBp = "BP " .. curRoleInfo.fight})
        NodeHelper:setSpriteImage(headNode, {mFrame = GameConfig.MercenaryRarityFrame[quality],
            mIcon = "UI/RoleShowCards/Hero_" .. string.format("%02d", itemId) .. string.format("%03d", curRoleInfo.skinId)..".png",
            mElement = GameConfig.MercenaryElementImg[heroCfg.Element],
            mClass=GameConfig.MercenaryClassImg[heroCfg.Job]})
        for i = 1, 13 do
            NodeHelper:setNodesVisible(headNode, {["mStar" .. i] = (i == curRoleInfo.starLevel)})
        end
        if curRoleInfo.starLevel <= 5 then
            NodeHelper:setNodesVisible(headNode,{mSr=true,mSsr=false,mUr=false})
        elseif curRoleInfo.starLevel > 5 and curRoleInfo.starLevel <= 10 then
            NodeHelper:setNodesVisible(headNode,{mSr=false,mSsr=true,mUr=false})
        else
            NodeHelper:setNodesVisible(headNode,{mSr=false,mSsr=false,mUr=true})
        end
       NodeHelper:setNodesVisible(headNode, { mInExpedition = (curRoleInfo.status == Const_pb.EXPEDITION or curRoleInfo.status == Const_pb.MIXTASK), 
                                                         mMaskNode=(curRoleInfo.status == Const_pb.EXPEDITION or curRoleInfo.status == Const_pb.MIXTASK),
                                                         mBarNode = false,
                                                         mInTeamImg=false,
                                                         mRedPoint = false })
    end
    TableSync()
end
function TableSync()
    LimitComplete.Star = false
    LimitComplete.Element = false
    LimitComplete.Class = false
    for i = 1, 3 do
        if DisPatchHero[i] ~= nil then
            local curRoleInfo = UserMercenaryManager:getUserMercenaryById(DisPatchHero[i])
            local Cfg = ConfigManager.getNewHeroCfg()[curRoleInfo.itemId]
            if (curRoleInfo.starLevel >= limits.Star) then
                LimitComplete.Star = true
                NodeHelper:setNodeIsGray(myContainer, {mStarNum = false, mStarSprite = false})
            end
            if (Cfg.Element == limits.Element) then
                LimitComplete.Element = true
                NodeHelper:setNodeIsGray(myContainer, {mElement = false})
            end
            if (Cfg.Job == limits.Class) then
                LimitComplete.Class = true
                NodeHelper:setNodeIsGray(myContainer, {mClass = false})
            end
            ----------------------------
            if (LimitComplete.Star == true and LimitComplete.Element == true and LimitComplete.Class == true) then
                NodeHelper:setMenuItemsEnabled(myContainer, {mExpeditionMenuBtn = true})
                NodeHelper:setNodeIsGray(myContainer, {mExpeditionMenuBtn = false})
            end
        end
    end
end

function sortData(info)
    if info == nil or #info == 0 then
        return
    end
    table.sort(info, function(info1, info2)
        if info1 == nil or info2 == nil then
            return false
        end
        local mInfo = UserMercenaryManager:getUserMercenaryInfos()
        local mInfo1 = mInfo[info1.roleId]
        local mInfo2 = mInfo[info2.roleId]
        if mInfo1 == nil then
            return false
        end
        if mInfo2 == nil then
            return true
        end
        if mInfo1.starLevel ~= mInfo2.starLevel then
            return mInfo1.starLevel > mInfo2.starLevel
        elseif mInfo1.level ~= mInfo2.level then
            return mInfo1.level > mInfo2.level
        elseif mInfo1.fight ~= mInfo2.fight then
            return mInfo1.fight > mInfo2.fight
        elseif mInfo1.singleElement ~= mInfo2.singleElement then
            return mInfo1.singleElement < mInfo2.singleElement
        end
        return false
    end)
    local t = {}
    local FormationManager = require("FormationManager")
    local info = FormationManager:getMainFormationInfo()
    for i = 1, #info.roleNumberList do
        if info.roleNumberList[i] > 0 then
            local index = MercenaryExpeditionSendPage:getMercenaryIndex(info.roleNumberList[i])
            if index > 0 then
                --local data = table.remove(_mercenaryInfos.roleInfos, index)
                --table.insert(t, data)
            end
        end
    end
    for k, v in pairs(_mercenaryInfos.roleInfos) do
        table.insert(t, v)
    end
    _mercenaryInfos.roleInfos = t
    return t
end
function MercenaryExpeditionSendPage:getMercenaryIndex(roleId)
    local index = 0
    for i = 1, #_mercenaryInfos.roleInfos do
        if _mercenaryInfos.roleInfos[i].itemId == roleId then
            index = i
            break
        end
    end
    return index
end
function MercenaryExpeditionSendPage:onAuto(container)
    --clear
    DisPatchHero = {}
    for i = 1, 3 do
        myContainer:getVarNode("mHeadNode" .. i):removeAllChildren()
    end
    --
    local heros = {}
    for i=1,#self.mAllHeroItem do
        for j=1,#_mercenaryInfos.roleInfos do
             if  _mercenaryInfos.roleInfos[j].roleId==self.mAllHeroItem[i].handler.roleId and  _mercenaryInfos.roleInfos[j].status~=Const_pb.EXPEDITION and _mercenaryInfos.roleInfos[j].status~=Const_pb.MIXTASK then
                  table.insert(heros,self.mAllHeroItem[i])
             end
        end
    end
    local gotStar = false
    local gotClass = false
    local gotElement = false
    table.sort(heros, function(hero1, hero2)
        return hero1.roleData.star < hero2.roleData.star
    end)
    local index = #heros
    for i = 1, index do
        --完全符合
        if heros[i].roleData.star >= limits.Star and
            heros[i].roleData.class == limits.Class and
            heros[i].roleData.element == limits.Element then
            mercenaryHeadContent:onHead(heros[i].handler.id)
            return
        end
    end
    for i = 1, index do
        --星數符合&職業符合
        if heros[i].roleData.star >= limits.Star and
            heros[i].roleData.class == limits.Class and
            not gotStar and not gotClass then
            mercenaryHeadContent:onHead(heros[i].handler.id)
            gotStar = true
            gotClass = true
            break
        end
    end
    for i = 1, index do
        --星數符合&屬性符合
        if heros[i].roleData.star >= limits.Star and heros[i].roleData.element == limits.Element
            and not gotStar and not gotElement then
            gotClass = true
            gotElement = true
            mercenaryHeadContent:onHead(heros[i].handler.id)
            break
        end
    end
    for i = 1, index do
        --職業符合&屬性符合
        if heros[i].roleData.class == limits.Class and heros[i].roleData.element == limits.Element
            and not gotClass and not gotElement then
            gotClass = true
            gotElement = true
            mercenaryHeadContent:onHead(heros[i].handler.id)
            break
        end
    end
    for i = 1, index do
        --星數符合
        if heros[i].roleData.star >= limits.Star and not gotStar then
            mercenaryHeadContent:onHead(heros[i].handler.id)
            gotStar = true
            break
        end
    end
    for i = 1, index do
        --職業符合
        if heros[i].roleData.class == limits.Class and not gotClass then
            gotClass = true
            mercenaryHeadContent:onHead(heros[i].handler.id)
            break
        end
    end
    for i = 1, index do
        --屬性符合
        if heros[i].roleData.element == limits.Element and not gotElement then
            gotElement = true
            mercenaryHeadContent:onHead(heros[i].handler.id)
            break
        end
    end
end
function MercenaryExpeditionSendPage:onFilter(container)
    local isShowClass = container:getVarNode("mClassNode"):isVisible()
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    if isShowClass then
        filterBg:setContentSize(filterCloseSize)
        NodeHelper:setNodesVisible(container, {mClassNode = false})
    else
        filterBg:setContentSize(filterOpenSize)
        NodeHelper:setNodesVisible(container, {mClassNode = true})
    end
end
function MercenaryExpeditionSendPage:onClass(container, eventName)
    local class = tonumber(eventName:sub(-1))
    mCurHeroClass = class
    self:setFilterVisible(container)
    for i = 0, 4 do
        container:getVarSprite("mClass" .. i):setVisible(class == i)
    end
    container.mScrollView:orderCCBFileCells()
end
function MercenaryExpeditionSendPage:onElement(container, eventName)
    local element = tonumber(eventName:sub(-1))
    mCurHeroElement = element
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    container.mScrollView:orderCCBFileCells()
end
function MercenaryExpeditionSendPage:setFilterVisible(container)
    if self.mAllHeroItem then
        for i = 1, #self.mAllHeroItem do
            local isVisible = (mCurHeroElement == self.mAllHeroItem[i].roleData.element or mCurHeroElement == 0) and
                (mCurHeroClass == self.mAllHeroItem[i].roleData.class or mCurHeroClass == 0) 
            self.mAllHeroItem[i].cell:setVisible(isVisible)
            self.mAllHeroItem[i].cell:setContentSize(isVisible and headIconSize or CCSize(0, 0))
            --for j=1,#_mercenaryInfos.roleInfos do
            --   if  _mercenaryInfos.roleInfos[j].roleId==self.mAllHeroItem[i].handler.roleId then
            --        self.mAllHeroItem[i].cell:setContentSize(CCSize(0,0))
            --   end
            --end
        end
    end
end
function MercenaryExpeditionSendPage:onHead(container, eventName)
    local index = tonumber(eventName:sub(-1))
    myContainer:getVarNode("mHeadNode" .. index):removeAllChildren()
    DisPatchHero[index] = nil
    LimitComplete.Star = false
    LimitComplete.Element = false
    LimitComplete.Class = false
    NodeHelper:setNodeIsGray(container, {mStarNum = true, mStarSprite = true, mElement = true, mClass = true, mExpeditionMenuBtn = true})
    NodeHelper:setStringForLabel(container, {mStarNum = limits.Star})
    --NodeHelper:setMenuItemsEnabled(container, {mExpeditionMenuBtn = false})
    TableSync()
end
function MercenaryExpeditionSendPage_onHead(id)
    mercenaryHeadContent:onHead(id)
end
function MercenaryExpeditionSendPage:onClose(container)
    DisPatchHero = {}
    _mercenaryInfos = {}
    PageManager.popPage(thisPageName)
end
function MercenaryExpeditionSendPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARY_EXPEDITIONPAGE)
end
function MercenaryExpeditionSendPage.setPageInfo(task, level)--设置页面数据信息
    SingleTask = task;
    LevelLimit = level
end
function MercenaryExpeditionSendPage:onExpeditionMenuBtn(container)
    if (LimitComplete.Star == false or LimitComplete.Element == false or LimitComplete.Class == false) then
        MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_80202"))
        return
    end
    local msg = MercenaryExpedition_pb.HPMercenaryDispatch()
    msg.taskId = SingleTask.taskId
    if DisPatchHero ~= nil then
        local mInfoSorts = UserMercenaryManager:getMercenaryStatusInfos()
        local mInfosSort = {}
        local mInfosortIndex = #mInfoSorts
        for i = 1, mInfosortIndex do
            if mInfoSorts[i].status ~= Const_pb.EXPEDITION then
                table.insert(mInfosSort, mInfoSorts[i])
            end
        end
        local SendTeam={}
        for i=1,3 do
            if DisPatchHero[i]~=nil then
                table.insert(SendTeam,DisPatchHero[i])
            end
        end
        for  i=1,#SendTeam do
            msg.mercenaryId:append(SendTeam[i])
        end
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.MERCENERY_DISPATCH_C, pb, #pb, true)
        PageManager.popPage(thisPageName)
        container:registerPacket(HP_pb.ROLE_PANEL_INFOS_S)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    end
end
local CommonPage = require('CommonPage')
local MercenaryExpeditionSendPageBase = CommonPage.newSub(MercenaryExpeditionSendPage, thisPageName, option)
return MercenaryExpeditionSendPage
