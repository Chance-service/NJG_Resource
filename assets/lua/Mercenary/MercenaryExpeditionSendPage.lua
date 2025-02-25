
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local MercenaryExpedition_pb = require("MercenaryExpedition_pb")
local Recharge_pb = require "Recharge_pb"
local UserInfo = require("PlayerInfo.UserInfo")
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "MercenaryExpeditionSendPage"
local MercenaryExpeditionSendPage = {}
local nExpeditionCount = 0;--远征中的佣兵个数
local nExpeditionLimit = 2;
local roleConfig = {}
local LevelLimit = 0
local rewardItems = {}
local SingleTask = {};
local DisPatchHero=nil;

local option = {
	ccbiFile = "MercenaryExpeditionSendPopUp.ccbi",
	handlerMap = {
		onClose                 = "onClose",
        onHelp                  = "onHelp",
        onImmediatelyDekaron    = "onClose",
        onExpeditionMenuBtn     = "onExpeditionMenuBtn",
        onHead                  = "onHead",
        onHead1                 = "onHead1",
	},
    opcodes = {
	}
}
for i=1,5 do
    option.handlerMap["onFrame"..i] = "onFeet";
end
local StatusTips = 
{
    "@MercenaryStatus_Fight",
	"@MercenaryStatus_Fight",
    "@MercenaryStatus_Rest",
    "@MercenaryStatus_Expedition",
    "@MercenaryStatus_Fight"
}
local mercenaryHeadContent = {
    ccbiFile = "FormationTeamContent.ccbi"
}
local rewardPosX = {
    0, -50, -100
}
local HEAD_SCALE = 1.12
local headIconSize = CCSize(130 * HEAD_SCALE, 130 * HEAD_SCALE)
local myMercenary =  {}--当前的佣兵列表
local _mercenaryContainerInfo = { }
local TaskInfo = {
    taskId = 0,
    taskStatus = 0,
    taskRewards = nil,
    mercenaryId = 0,
    lastTimes = 0
}


function mercenaryHeadContent:onRefreshContent(ccbRoot)

    local container = ccbRoot:getCCBFileNode()
    self.container = container
    local index = self.id
    local mInfosSort={ }
    local mInfoSort, mInfosDisorder = MercenaryExpeditionSendPage:getMercenaryInfos();
    local mInfosortIndex = #mInfoSort
    for i = 1, mInfosortIndex do
        if mInfoSort[i].status ~= Const_pb.EXPEDITION then
            table.insert(mInfosSort, mInfoSort[i])
        end
    end
    local info = mInfosSort[self.id];
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local roleInfo = mInfo[info.roleId]
    local _mercenaryInfos = {}
    local roleTable = {}
        local MercenaryId = info.roleId
        if MercenaryId ~= 0 then
            _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
            for i = 1, #_mercenaryInfos.roleInfos do
                if tonumber(_mercenaryInfos.roleInfos[i].roleId) == MercenaryId then
                    roleTable=NodeHelper:getNewRoleTable(_mercenaryInfos.roleInfos[i].itemId)
                    break
                else 
                   roleTable = nil
                end
            end      
        else
            roleTable = nil
        end

    local savePath = NodeHelper:getWritablePath()
    if NodeHelper:isFileExist(roleTable.icon) then
        NodeHelper:setSpriteImage(container, { mHead = roleTable.icon })
    end

    NodeHelper:setSpriteImage(container, { mHeadFrame = GameConfig.MercenaryBloodFrame[roleTable.blood],
                                           mClass = GameConfig.MercenaryClassImg[roleTable.class],
                                           mElement = GameConfig.MercenaryElementImg[roleTable.element],
                                           mMask = roleInfo.starLevel > 0 and "UI/Mask/u_Mask_20_rise.png" or "UI/Mask/u_Mask_20.png",
                                           mStageImg = roleInfo.starLevel > 0 and "common_uio2_rise_" .. roleInfo.starLevel .. ".png" or "UI/Mask/Image_Empty.png" })
    NodeHelper:setStringForLabel(container, { mLv = roleInfo and roleInfo.level or 1 })
    local isSelling = info.activiteState == Const_pb.NOT_ACTIVITE
    NodeHelper:setNodesVisible(container, { mMarkFighting = info.status == Const_pb.FIGHTING and not isSelling, mMarkChoose = false, mMarkSelling = isSelling, mMask =false, mSelectFrame = false })
    for i = 1, 5 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (roleTable.star == i) })
    end
end

function MercenaryExpeditionSendPage:onEnter(container)
    myContainer=container
	myMercenary = common:deepCopy(UserInfo.activiteRoleId)
    if not myMercenary then return end

    NodeHelper:initScrollView(container, "mContent", 3);
    roleConfig = ConfigManager.getRoleCfg()	
    nExpeditionCount = 0
    for i = #myMercenary,1,-1 do
    --	// 出战中FIGHTING_1;// 休息中RESTTING;// 远征中EXPEDITION;
        local mercenaryInfo =  UserMercenaryManager:getUserMercenaryById(myMercenary[i])
        if mercenaryInfo.hide then
            table.remove(myMercenary,i)
        else
            if mercenaryInfo.status == Const_pb.EXPEDITION then
                nExpeditionCount = nExpeditionCount + 1
            end
        end
    end
    self:refreshPage(container);
end
function MercenaryExpeditionSendPage:onFeet(container,eventName)
    local index = tonumber(string.sub(eventName, 8));
    GameUtil:showTip(container:getVarNode('mPic' .. index), rewardItems[index])
end
function MercenaryExpeditionSendPage:refreshPage(container)
    rewardItems = {}
    for _, item in ipairs(common:split(SingleTask.taskRewards, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"));
        table.insert(rewardItems, {
            type 	= tonumber(_type),
            itemId	= tonumber(_id),
            count 	= tonumber(_count),
        });
    end
    NodeHelper:fillRewardItemWithParams(container, rewardItems, 5, { frameShade = "mBg" })
    for i = 1, 3 do
        container:getVarNode("mRewardNode" .. i):setPositionX(rewardPosX[#rewardItems] + 100 * (i - 1))
    end
    for i = 1, #rewardItems do
        NodeHelper:setNodeScale(container, "mFrame" .. i, 1, 1)
    end

    container.mScrollView = container:getVarScrollView("mContent")
    container.mScrollView:removeAllCell()
    self:buildScrollView(container)
end

function MercenaryExpeditionSendPage.setPageInfo(task, level)--设置页面数据信息
    SingleTask = task;
    LevelLimit = level
end

function MercenaryExpeditionSendPage:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function MercenaryExpeditionSendPage:onClose( container )
    PageManager.popPage(thisPageName)
end

function MercenaryExpeditionSendPage:onHelp( container )
    PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARY_EXPEDITIONPAGE_SEND)
end

function mercenaryHeadContent:onHead( container )
   
    if not self.id or self.id <= 0 then
        return
    end

    DisPatchHero = self.id
    local mInfosSort = {}
    local mInfoSort, mInfosDisorder = MercenaryExpeditionSendPage:getMercenaryInfos()
    local mInfosortIndex = #mInfoSort
    for i = 1, mInfosortIndex do
        if mInfoSort[i].status ~= Const_pb.EXPEDITION then
            table.insert(mInfosSort, mInfoSort[i])
        end
    end
    local info = mInfosSort[self.id]
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local roleInfo = mInfo[info.roleId]
    local _mercenaryInfos = {}
    local roleTable = {}
        local MercenaryId = info.roleId
        if MercenaryId ~= 0 then
            _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
            for i = 1, #_mercenaryInfos.roleInfos do
                if tonumber(_mercenaryInfos.roleInfos[i].roleId) == MercenaryId then
                    roleTable=NodeHelper:getNewRoleTable(_mercenaryInfos.roleInfos[i].itemId)
                    break
                else 
                   roleTable=nil
                end
            end      
        else
            roleTable=nil
        end
    local headNode = ScriptContentBase:create("FormationTeamContent.ccbi")
    myContainer:getVarNode("mHead1"):removeAllChildren();
    myContainer:getVarNode("mHead1"):addChild(headNode)
    headNode:setAnchorPoint(ccp(0,0))
    headNode:setScale(0.4)
    headNode:setPositionX(headNode:getPositionX()-1.2)
    headNode:setPositionY(headNode:getPositionY()-0.5)
    headNode:release()
    NodeHelper:setNodesVisible(headNode, { mHeadNode = true })
    if NodeHelper:isFileExist(roleTable.icon) then
        NodeHelper:setSpriteImage(headNode, { mHead =roleTable.icon })
    end
    NodeHelper:setSpriteImage(headNode, { mHeadFrame = GameConfig.MercenaryBloodFrame[roleTable.blood],
                                          mClass = GameConfig.MercenaryClassImg[roleTable.class],
                                          mElement = GameConfig.MercenaryElementImg[roleTable.element],
                                          mMask = roleInfo.starLevel > 0 and "UI/Mask/u_Mask_20_rise.png" or "UI/Mask/u_Mask_20.png",
                                          mStageImg = roleInfo.starLevel > 0 and "common_uio2_rise_" .. roleInfo.starLevel .. ".png" or "UI/Mask/Image_Empty.png" })
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    NodeHelper:setStringForLabel(headNode, { mLv = roleInfo and roleInfo.level or 1 })
    local isSelling = roleInfo.activiteState == Const_pb.NOT_ACTIVITE
    NodeHelper:setNodesVisible(headNode, { mMarkFighting = false, mMarkChoose = false, mMarkSelling = isSelling, mMask = (info.status==Const_pb.EXPEDITION) , mSelectFrame = false })
    for i = 1, 5 do
        NodeHelper:setNodesVisible(headNode, { ["mStar" .. i] = (roleTable.star == i) })
    end
  end

function MercenaryExpeditionSendPage:getMercenaryInfos()
     local infos = UserMercenaryManager:getMercenaryStatusInfos();
     local tblsort = { };
     local tbldisorder = { };
     local index = 1
     for k, v in pairs(infos) do
        --if v.roleStage == 1 and not v.hide then
            table.insert(tblsort, v);
            tbldisorder[v.roleId--[[v.itemId]]] = v;
            tbldisorder[v.roleId--[[v.itemId]]].index = index

            -- tbldisorder[v.roleId] = v;
            -- tbldisorder[v.roleId].index = index

            index = index + 1
        --end
    end

    if #tblsort > 0 then
        --table.sort(tblsort,
        --    function(d1, d2)
        --        return d1.fight > d2.fight;
        --    end
        --    );
        table.sort(tblsort, function(info1, info2)
            if info1 == nil or info2 == nil then
                return false
            end
            local mInfo = UserMercenaryManager:getUserMercenaryInfos()
            local roleTable1 = NodeHelper:getNewRoleTable(info1.itemId)
            local roleTable2 = NodeHelper:getNewRoleTable(info2.itemId)
            local mInfo1 = mInfo[info1.roleId]
            local mInfo2 = mInfo[info2.roleId]
            if mInfo1 == nil or mInfo2 == nil then
                return true
            end
            if mInfo1.level ~= mInfo2.level then
                return mInfo1.level > mInfo2.level
            elseif roleTable1.star ~= roleTable2.star then
                return roleTable1.star > roleTable2.star
            elseif roleTable1.blood ~= roleTable2.blood then
                return roleTable1.blood < roleTable2.blood
            elseif roleTable1.class ~= roleTable2.class then
                return roleTable1.class < roleTable2.class
            elseif roleTable1.element ~= roleTable2.element then
                return roleTable1.element < roleTable2.element
            elseif roleTable1.id ~= roleTable2.id then
                return roleTable1.id < roleTable2.id
            end
            return false
        end )
    end

    return tblsort, tbldisorder;
end

function MercenaryExpeditionSendPage:onExpeditionMenuBtn(container)
    local msg = MercenaryExpedition_pb.HPMercenaryDispatch()
    msg.taskId = SingleTask.taskId
    if DisPatchHero ~= nil then
        local mInfosSort = {}
        local mInfoSort, mInfosDisorder = MercenaryExpeditionSendPage:getMercenaryInfos();
        local mInfosortIndex = #mInfoSort
         for i = 1, mInfosortIndex do
             if mInfoSort[i].status ~= Const_pb.EXPEDITION then
                 table.insert(mInfosSort,mInfoSort[i])
             end
         end
        local info = mInfosSort[DisPatchHero];
        if not info or info.status == Const_pb.EXPEDITION then
           return
        end
        msg.mercenaryId = info.roleId
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.MERCENERY_DISPATCH_C, pb , #pb, true)
        local msg2 = RoleOpr_pb.HPRoleInfoRes();
        UserMercenaryManager:setMercenaryStatusInfos(msg2.roleInfos)
        PageManager.popPage(thisPageName)
        local MercenaryExpeditionPage=require("MercenaryExpeditionPage")
        MercenaryExpeditionPage:onReturn()
        PageManager.changePage("MercenaryExpeditionPage")
    end
end

-- 构建标签页
function MercenaryExpeditionSendPage:buildScrollView(container)

    local _mercenaryInfos = {}
    _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
    local count = 0
    for i = 1, #_mercenaryInfos.roleInfos do
        if _mercenaryInfos.roleInfos[i] and _mercenaryInfos.roleInfos[i].roleStage == 1 then
            count = count + 1
        end
    end
    count = #_mercenaryInfos.roleInfos

    if count <= 8 then
        container.mScrollView:setTouchEnabled(false)
    else
        container.mScrollView:setTouchEnabled(true)
    end

    local cell = nil
    local items = {}
    local mID = 1
    for i = 1, count, 1 do
        local dataInfo = _mercenaryInfos.roleInfos[i]
        if dataInfo.status ~= Const_pb.EXPEDITION then
            cell = CCBFileCell:create()
            cell:setCCBFile(mercenaryHeadContent.ccbiFile)
            local handler = common:new( { id = mID, roleTable = NodeHelper:getNewRoleTable(dataInfo.itemId) }, mercenaryHeadContent)
            mID = mID+1
            cell:registerFunctionHandler(handler)
            container.mScrollView:addCell(cell)
            table.insert(items, { cls = handler, node = cell })
            cell:setScale(HEAD_SCALE)
            cell:setContentSize(headIconSize)
        end
    end
    container.mScrollView:orderCCBFileCells()
end

local CommonPage = require('CommonPage')
local MercenaryExpeditionSendPageBase= CommonPage.newSub(MercenaryExpeditionSendPage, thisPageName, option)
return MercenaryExpeditionSendPage