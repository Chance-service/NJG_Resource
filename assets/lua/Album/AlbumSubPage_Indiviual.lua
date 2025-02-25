local AlbumIndivualPage = {}
local AlbumIndivualItem = {}
local thisPageName = "AlbumIndivualPage"
local SecretMsg_pb = require("SecretMsg_pb")
local AlbumStoryDisplayPage_Vertical=require('AlbumStoryDisplayPage_Vertical')
require("Battle.NgBattleResultManager")
require("SecretMessage.SecretMessageManager")
local option = {
    ccbiFile = "AlbumIndvidual.ccbi",
    handlerMap =
    {
    },
}
local opcodes = {
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    SECRET_MESSAGE_ACTION_S = HP_pb.SECRET_MESSAGE_ACTION_S
}
local AlbumCfg = ConfigManager.getAlbumData()
local RoleId = 0
local PopUpCCB=nil
local mainContainer=nil
local NowClickPhoto=0
local PopUpRewardContent = { ccbiFile = "GoodsItem.ccbi" }
local hasPassedItem = false

local AutoClickId = 0
local isMsg = false

function AlbumIndivualPage:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)
    
    return container
end

function AlbumIndivualPage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


function AlbumIndivualPage:onEnter(Parentcontainer)
    mainContainer=Parentcontainer
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    parentPage:registerMessage(MSG_RECHARGE_SUCCESS)
    parentPage:registerPacket(opcodes)
    mainContainer:getVarNode("mBg"):setScale(NodeHelper:getScaleProportion())
    
  -- -- scrollview
  mainContainer.scrollview=mainContainer:getVarScrollView("mContent")
  NodeHelper:autoAdjustResizeScrollview(content)
  self:refresh(mainContainer)
end
function AlbumIndivualPage:getRoleTable()
    local RoleTable={}
    for k,data in pairs (AlbumCfg) do
        if data.itemId==RoleId then
            table.insert(RoleTable,data)
        end
    end
    table.sort(RoleTable, function(a, b)
            return a.id < b.id
    end)
    return RoleTable
end
function AlbumIndivualPage:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    elseif opcode == HP_pb.SECRET_MESSAGE_ACTION_S then
        local msg = SecretMsg_pb.secretMsgResponse()
        msg:ParseFromString(msgBuff)
        local syncMsg = msg.syncMsg
        SecretMessageManager_setServerData(syncMsg)
        AlbumIndivualPage:refresh()
    end
end
function AlbumIndivualPage:onExecute(container)
end
function AlbumIndivualPage:onExit(container)
end

function AlbumIndivualPage:refresh(container)
    local container=mainContainer
    if container==nil then return end
    local sprite2Image = {}
    local String = {}
    
    local flagDataBase = require("FlagData")
    local data=FlagDataBase_GetData()
    for key,v in pairs(data) do
        if tonumber(key) == flagDataBase.FlagId.SECRET_MESSAGE_PASS then
            hasPassedItem = true
        end
    end
    local Limit=SecretMessageManager_getAlbumData(RoleId).NowLimit
    local Point=SecretMessageManager_getAllHeroData()[RoleId] and SecretMessageManager_getAllHeroData()[RoleId].favorabilityPoint or 0
    String["mPoint"] = Point .. "/ ".. Limit 
    NodeHelper:setScale9SpriteBar(container,"mBar",Point,Limit,560)
    sprite2Image["mBanner"] = "UI/Common/Album/Banner/PhotoAlbum_banner" .. string.format("%02d", RoleId) .. ".jpg"
    mainContainer.scrollview:removeAllCell()
    local table = self.getRoleTable()
    local index=#table
    for i = 1, index do
        cell = CCBFileCell:create()
        cell:setCCBFile("AlbumIndvidualContent.ccbi")
        local panel = common:new({id = i,mID = table[i].id}, AlbumIndivualItem)
        cell:registerFunctionHandler(panel)
        mainContainer.scrollview:addCell(cell)
    end
    mainContainer.scrollview:setTouchEnabled(true)
    mainContainer.scrollview:orderCCBFileCells()
    local AlbumData=SecretMessageManager_getAlbumData(RoleId)
    String["mHeroLv"] = AlbumData.UnLockCount .. " / ".. index
    NodeHelper:setStringForLabel(container, String)
    NodeHelper:setSpriteImage(container, sprite2Image)
    --AutoClick
    if isMsg then
        AlbumIndivualItem:onHead(nil,AutoClickId)
        isMsg = false
    end
end

function AlbumIndivualItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local cfg = AlbumIndivualPage:getRoleTable()[self.id]
    local filename = "UI/Common/Album/" .. cfg.FileName .. ".jpg"
   NodeHelper:setNodesVisible(container,{mCostLock = not hasPassedItem})
    -- 設置Banner圖標
    if NodeHelper:isFileExist(filename) then
        NodeHelper:setSpriteImage(container, {mIcon = filename})
    end
    NodeHelper:setStringForLabel(container, {mName = common:getLanguageString("@" .. cfg.FileName .. "_title")})
    -- 處理資源圖標與數量顯示
    local sprite2ImgStuff = {}
    for i, label in ipairs({"mFreeCount", "mCostCount"}) do
        local rewardType = cfg[i == 1 and "reward" or "CostReward"]
        if not next(rewardType[1]) then
            NodeHelper:setNodesVisible(container, {["mItem" .. i] = false})
        else
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(rewardType[1].type, rewardType[1].itemId, rewardType[1].count)
            self[i == 1 and "FreeReward" or "CostReward"] = rewardType[1]
            NodeHelper:setStringForLabel(container, {[label] = "x" .. resInfo.count})
            sprite2ImgStuff["mPic" .. i], sprite2ImgStuff["mFrameShade" .. i] = resInfo.icon, NodeHelper:getImageBgByQuality(resInfo.quality)
            NodeHelper:setNodesVisible(container, {["mItem" .. i] = true})
        end
    end
    NodeHelper:setSpriteImage(container, sprite2ImgStuff)

    -- 設置星星或心形圖示
    local isMaxId = (self.id == #AlbumIndivualPage:getRoleTable())
    NodeHelper:setNodesVisible(container, {mVidIcon = false, mRedPoint = false, mHeartNode = not isMaxId, mStarNode = isMaxId})
    if isMaxId then
        for i = 1, 13 do
            NodeHelper:setNodesVisible(container, {["mStar" .. i] = (i == cfg.Score)})
        end
        local rarityNode = (cfg.Score <= 5 and "mSr") or (cfg.Score <= 10 and "mSsr") or "mUr"
        NodeHelper:setNodesVisible(container, {mSr = rarityNode == "mSr", mSsr = rarityNode == "mSsr", mUr = rarityNode == "mUr"})
    else
        NodeHelper:setStringForLabel(container, {mHeartTxt = cfg.Score})
    end

    -- 解鎖和獎勵狀態的處理
    local HeroData = SecretMessageManager_getAllHeroData()[RoleId] or {}
    if next(HeroData) then
        self.Lock = not isMaxId  and not HeroData.Unlock[self.id]
    else
        self.Lock = true
    end
    local lockVisible = self.Lock or (isMaxId and SecretMessageManager_LevelAchiveCount(RoleId)==0)

    NodeHelper:setNodesVisible(container, {
        mLock = lockVisible, mIcon2 = false,
        selectedNode1 = HeroData.Free and HeroData.Free[self.id] or false,
        selectedNode2 = HeroData.Cost and HeroData.Cost[self.id] or false
    })
end

function AlbumIndivualItem:onHead(container,_id)
    local popUpNode = mainContainer:getVarNode("mPopUpNode")
    local children= popUpNode:getChildren()
    if _id then 
        self.id = _id
        self.Lock = true
    end
    -- 如果已有子節點則退出
    if children and children:count()>0 then return end
    local cfg = AlbumIndivualPage:getRoleTable()[self.id]
    if self.id == #AlbumIndivualPage:getRoleTable() then
        self.Lock = SecretMessageManager_LevelAchiveCount(RoleId)==0
    end
    if self.Lock then
        PopUpCCB = ScriptContentBase:create("AlbumIndvidualPopoutContent")
        popUpNode:addChild(PopUpCCB)
        SetPopupPage(PopUpCCB, cfg)
        PopUpCCB.cfg = cfg
        PopUpCCB:registerFunctionHandler(PopUpCCBFun)
        -- 新手教學
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["AlbumIndvidualPopup"] = PopUpCCB
        if GuideManager.isInGuide then
            GuideManager.forceNextNewbieGuide()
        end
    else
        if self.id == #AlbumIndivualPage:getRoleTable() then
            NgBattleResultManager.showAlbum = true
            AlbumStoryDisplayPage_Vertical:setData(RoleId, false)
            PageManager.pushPage("AlbumStoryDisplayPage_Vertical")
        else
            require("SecretMessage.SecertAVGPage")
            SecertAVG_setMainId(cfg.StroyId)
            PageManager.pushPage("SecretMessage.SecertAVGPage")
        end
    end

    require("Album.AlbumMainPage"):onRefreshPage()
end
function AlbumIndivualItem:onHand1(container)
    AlbumIndivualPage:getReward(self.id,self.mID,1)
end
function AlbumIndivualItem:onHand2(container)
    AlbumIndivualPage:getReward(self.id,self.mID,2)
end
function AlbumIndivualPage:isFromMsg(msg,_id)
    --AlbumIndivualItem:onHead(nil,_id)
    AutoClickId = _id
    isMsg = msg
end
function SetPopupPage(container,cfg)
    NodeHelper:setSpriteImage(container, {mIcon = "UI/Common/Album/" .. cfg.FileName .. ".jpg"}, {mIcon = 1.5})
    local name = common:getLanguageString("@" .. cfg.FileName .. "_title")
    NodeHelper:setNodesVisible(container,{mVidIcon=false,mStarNode=false,mHeartNode=false,mRedPoint=false,mIcon2=false})
    if cfg.id>1000 then
         NodeHelper:setNodesVisible(container,{mStarNode=false,mHeartNode=false})
          for i = 1, 13 do
            NodeHelper:setNodesVisible(container, {["mStar" .. i] = (i == cfg.Score)})
          end
          if cfg.Score <= 5 then
              NodeHelper:setNodesVisible(container,{mSr=true,mSsr=false,mUr=false})
          elseif cfg.Score > 5 and cfg.Score <= 10 then
              NodeHelper:setNodesVisible(container,{mSr=false,mSsr=true,mUr=false})
          else
              NodeHelper:setNodesVisible(container,{mSr=false,mSsr=false,mUr=true})
          end
    end
    local txt=""
    if cfg.id<1000 then
        txt=common:getLanguageString("@AlbumunlockHint1",cfg.Score)
    else
         txt=common:getLanguageString("@AlbumunlockHint2",cfg.Score)
    end
    NodeHelper:setStringForLabel(container,{mHeartTxt=cfg.Score,mName = name,mLockTxt=txt})
    local mScrollView = container:getVarScrollView("mItemContent")
    mScrollView:removeAllCell()
    if cfg.id<1000 then
        for key,value in pairs (cfg.reward) do
            local cell = CCBFileCell:create()
            cell:setCCBFile(PopUpRewardContent.ccbiFile)
            cell:setScale(0.9)
            cell:setContentSize(CCSizeMake(134,134))
            local panel = common:new( { rewadItems=value}, PopUpRewardContent)
            cell:registerFunctionHandler(panel)
            mScrollView:addCell(cell)
        end
         mScrollView:orderCCBFileCells()
         if #cfg.reward > 4 then
            mScrollView:setTouchEnabled(true)
         else
            mScrollView:setTouchEnabled(false)
         end
    end
end
function PopUpRewardContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    container:getVarNode("mNode"):setPosition(ccp(67,67))
    local ResManager = require "ResManagerForLua"
    local resInfo = ResManager:getResInfoByTypeAndId(self.rewadItems and self.rewadItems.type, self.rewadItems and self.rewadItems.itemId , self.rewadItems and self.rewadItems.count or 1)

    local numStr = ""
    if resInfo.count > 0 then
        numStr = "x" .. GameUtil:formatNumber(resInfo.count)
    end
    local lb2Str = {
        mNumber = numStr
    }
    local showName = ""
    if self.rewadItems and self.rewadItems.type == 30000 then
        showName = ItemManager:getShowNameById(self.rewadItems.itemId)
    else
        showName = resInfo.name           
    end

    if self.rewadItems.type == 40000 then
        for i = 1, 6 do
            NodeHelper:setNodesVisible(container, { ["mStar" .. i] = i == resInfo.star })
        end
    end
    NodeHelper:setNodesVisible(container, { mStarNode = self.rewadItems.type == 40000 })
    
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, { mPic = resInfo.icon }, { mPic = 1 })
    NodeHelper:setQualityFrames(container, { mHand = resInfo.quality })
    NodeHelper:setNodesVisible(container, { mName = false })
end
function PopUpRewardContent:onHand(container)
    GameUtil:showTip(container:getVarNode("mHand"), self.rewadItems)
end
function PopUpCCBFun(eventName,container)
    if eventName=="onClose" then
        mainContainer:getVarNode("mPopUpNode"):removeAllChildren()
    elseif eventName=="onConfirm" then
        local cfg=container.cfg
        local AlbumData=SecretMessageManager_getAlbumData(RoleId)
        local Point=SecretMessageManager_getAllHeroData()[RoleId].favorabilityPoint
        if Point>=AlbumData.NowLimit and cfg.id<1000 and Point >= cfg.Score then
            AlbumIndivualPage:sendUnLock(cfg.id)
            mainContainer:getVarNode("mPopUpNode"):removeAllChildren()
            return
        end
        if cfg.id>1000 then
            MessageBoxPage:Msg_Box(common:getLanguageString("@AlbumMessage_04",cfg.Score))
        elseif Point<AlbumData.NowLimit then
            MessageBoxPage:Msg_Box(common:getLanguageString("@AlbumMessage_02",cfg.Score))
        elseif Point < cfg.Score then
            MessageBoxPage:Msg_Box(common:getLanguageString("@AlbumMessage_02",cfg.Score))
        end
    end
end
function AlbumIndivualPage:sendUnLock(id)
    NowClickPhoto=id
    local msg = SecretMsg_pb.secretMsgRequest()
    msg.action = 2
    msg.unlockPic = id
    common:sendPacket(HP_pb.SECRET_MESSAGE_ACTION_C, msg, true)
end
function AlbumIndivualPage:getReward(IndexId, PhotoId, BtnIdx)
    local HeroData = SecretMessageManager_getAllHeroData()[RoleId]
    if not HeroData or not HeroData.Unlock[IndexId] then
        AlbumIndivualItem:onHead(nil,IndexId)
        return 
    end

    if (BtnIdx == 1 and HeroData.Free[IndexId]) or (BtnIdx == 2 and HeroData.Cost[IndexId]) then
        return
    end
    if BtnIdx == 2 and not hasPassedItem then
        PageManager.showConfirm(common:getLanguageString("@Activate"), common:getLanguageString("@BuySecertPassed"), function(isSure)
            if isSure then BuyItem(700) end
        end,true,AlbumIndivualPage_getPrice(700),nil,nil,nil,nil,nil,nil,nil,true)
        return
    end

    local msg = SecretMsg_pb.secretMsgRequest()
    msg.action = 4
    msg.unlockPic = PhotoId
    common:sendPacket(HP_pb.SECRET_MESSAGE_ACTION_C, msg, true)
end

function AlbumIndivualPage_getPrice(id)
    if #RechargeCfg==0 then
        return 99999
    end
    local Info = nil
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == id then
            Info = RechargeCfg[i]
            break
        end
    end
    return Info.productPrice
end

function AlbumIndivualPage:SetId(id)
    RoleId = id
end
function AlbumIndivualPage_refresh()
     AlbumIndivualPage:refresh()
     if mainContainer then
        mainContainer:getVarNode("mPopUpNode"):removeAllChildren()
     end
     -- 新手教學
     local GuideManager = require("Guide.GuideManager")
     if GuideManager.isInGuide then
         GuideManager.forceNextNewbieGuide()
     end
     require("SecretMessage.SecertAVGPage")
     SecertAVG_setMainId(AlbumCfg[NowClickPhoto].StroyId,AlbumCfg[NowClickPhoto].reward)
     PageManager.pushPage("SecretMessage.SecertAVGPage")
end
function AlbumIndivualPage:onReceiveMessage(message)
	local typeId = message:getTypeId()
	if typeId == MSG_RECHARGE_SUCCESS then
        CCLuaLog(">>>>>>onReceiveMessage RechargeSubPage_Diamond")
        require("FlagData")
        FlagDataBase_ReqStatus()
	end
end

return AlbumIndivualPage
