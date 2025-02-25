

local HP_pb = require("HP_pb") -- 包含协议id文件
local thisPageName = "CommonRewardPageNew"
local curRewardStatus = false -- 不可领取状态
local title = ""
local GuideManager = require("Guide.GuideManager")

local rewadItems = { } -- 奖励物品 必须是读配置这种格式10000_1001_50 读出来的数组
local ItemManager = require("Item.ItemManager")
local mCallFun = nil

local timeStr = nil
local EXP = nil
local Coin = nil
local timeTxt = nil
local selfContianer = nil
----这里是协议的id
local opcodes = {

}

local option = {
    ccbiFile = "IdleRewardPopUp.ccbi",
    handlerMap =
    {
        onClose = "mDisChoose",
        onConfirmation = "mDisChoose",
    },
    opcode = opcodes
}

local rewardTypeToStr = { "@TLLoadTreasureRewardTxt", "@ACTTLTreasureRaiderRewardTxt" }

local CommonRewardPageNewBase = { }
local CommonRewardContent = { ccbiFile = "CommonRewardContent.ccbi" }
function CommonRewardContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local i = self.id
    local node = container:getVarNode("mItem")
    local itemNode = ScriptContentBase:create("GoodsItem.ccbi")
    local ResManager = require "ResManagerForLua"
    local resInfo = ResManager:getResInfoByTypeAndId(rewadItems[i] and rewadItems[i].type or 30000, rewadItems[i] and rewadItems[i].itemId or 104001, rewadItems[i] and rewadItems[i].count or 1)

    local numStr = ""
    if resInfo.count > 0 then
        numStr = "x" .. GameUtil:formatNumber(resInfo.count)
    end
    local lb2Str = {
        mNumber = numStr
    }
    local showName = ""
    if rewadItems[i] and rewadItems[i].type == 30000 then
        showName = ItemManager:getShowNameById(rewadItems[i].itemId)
    else
        showName = resInfo.name           
    end

    if rewadItems[i].type == 40000 then
        for i = 1, 6 do
            NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.star })
        end
    end
    NodeHelper:setNodesVisible(itemNode, { mStarNode = rewadItems[i].type == 40000 })
    
    NodeHelper:setStringForLabel(itemNode, lb2Str)
    NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = 1 })
    NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality })
    NodeHelper:setColorForLabel(itemNode, { mName = ConfigManager.getQualityColor()[resInfo.quality].textColor })
    NodeHelper:setNodesVisible(itemNode, { mName = false })

    node:addChild(itemNode)
    itemNode:registerFunctionHandler(CommonRewardPageNewBase.onFunction)
    itemNode.id = self.id
end
function CommonRewardPageNewBase:onEnter(container)
    UserInfo.syncRoleInfo()
    selfContianer = container

    self:registerPacket(container)
    NodeHelper:initScrollView(container, "mContent", #rewadItems)
    if curRewardStatus then
        NodeHelper:setNodesVisible(container, { mGetPic = false, mSurePic = true })
    else
        NodeHelper:setNodesVisible(container, { mGetPic = true, mSurePic = false })
    end
    local mapCfg = ConfigManager.getNewMapCfg()[UserInfo.stateInfo.curBattleMap]
    local chapter = mapCfg.Chapter
    local level = mapCfg.Level
    local txt = common:getLanguageString("@MapFlag" .. chapter) .. level
    NodeHelper:setStringForLabel(container, { mTitle = txt })
    self:showRewardItems(container)

    if not GuideManager.isInGuide then
        container:runAction(
        CCSequence:createWithTwoActions(
        CCDelayTime:create(1.5),
        CCCallFunc:create( function()
            --- 弹出评论界面
            PageManager.showCommentPage(rewadItems)
        end )
        )
        )
    end

    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["CommonRewardPageNew"] = container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    --    local nodeTest = container:getVarNode("mNodeTest")
    --    CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfo("Reward_animation/Reward_animation.ExportJson")
    --    local armatureBird  = CCArmature:create("Reward_animation")
    --    nodeTest:addChild(armatureBird)
    --    armatureBird:getAnimation():playWithIndex(1)

end

function CommonRewardPageNewBase:showRewardItems(container)  
    local mapCfg = ConfigManager.getNewMapCfg()[UserInfo.stateInfo.curBattleMap]
    local vipCfg = ConfigManager.getVipCfg()[UserInfo.playerInfo.vipLevel]
    NodeHelper:setStringForLabel(container, {
        mEmpty = timeStr,
        CoinTxt = "+" .. GameUtil:formatNumber(mapCfg.SkyCoin * vipCfg.idleRatio) .. "/m",
        ExpTxt = "+" .. GameUtil:formatNumber(mapCfg.EXP * vipCfg.idleRatio) .. "/m",
        potionTxt = "+" .. GameUtil:formatNumber(mapCfg.Potion * vipCfg.idleRatio) .. "/m",
    })
    NodeHelper:clearScrollView(container)
    local size = #rewadItems
    
    local mScrollView = container:getVarScrollView("mContent")
    for i = 1, size do
        local cell = CCBFileCell:create()
        cell:setCCBFile(CommonRewardContent.ccbiFile)
        local panel = common:new( { id = i }, CommonRewardContent)
        cell:registerFunctionHandler(panel)
        cell:setScale(0.779)
        cell:setContentSize(CCSize(cell:getContentSize().width * 0.779, cell:getContentSize().height * 0.779))
        mScrollView:addCell(cell)
    end
    mScrollView:orderCCBFileCells()
    NodeHelper:setNodesVisible(container, { mContent = size ~= 0 , mNoRewardNode = size == 0})

    if size <= 10  then
        local node = container:getVarNode("mContent")
        node:setTouchEnabled(false)
    end
    if GuideManager.IsNeedShowPage == true then
        GuideManager.IsNeedShowPage = false
        GuideManager.PageContainerRef["CommonReward"] = container
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function CommonRewardPageNewBase.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        --- 每个子空间创建的时候会调用这个函数
        local contentId = container:getItemDate().mID
        -- 获取到时第几行
        local i = contentId
        -- 获取当前的index      i是每行的第几个 用来获取组件用的
        local node = container:getVarNode("mItem")
        local itemNode = ScriptContentBase:create('GoodsItem.ccbi')
        local ResManager = require "ResManagerForLua"
        local resInfo = ResManager:getResInfoByTypeAndId(rewadItems[i] and rewadItems[i].type or 30000, rewadItems[i] and rewadItems[i].itemId or 104001, rewadItems[i] and rewadItems[i].count or 1)

        local numStr = ""
        if resInfo.count > 0 then
            numStr = "x" .. GameUtil:formatNumber(resInfo.count)
        end
        local lb2Str = {
            mNumber = numStr
        }
        local showName = ""
        if rewadItems[i] and rewadItems[i].type == 30000 then
            showName = ItemManager:getShowNameById(rewadItems[i].itemId)
        else
            showName = resInfo.name           
        end

        if rewadItems[i].type == 40000 then
            for i = 1, 6 do
                NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.quality })
            end
        end
        NodeHelper:setNodesVisible(itemNode, { mStarNode = rewadItems[i].type == 40000 })
        
        NodeHelper:setStringForLabel(itemNode, lb2Str)
        NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = 1 })
        NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality })
        NodeHelper:setColorForLabel(itemNode, { mName = ConfigManager.getQualityColor()[resInfo.quality].textColor })
        NodeHelper:setNodesVisible(itemNode, { mName = false})

        node:addChild(itemNode)
        itemNode:registerFunctionHandler(CommonRewardPageNewBase.onFunction)
        itemNode.id = contentId
        -- end
    elseif eventName == "onHand" then
        local id = container.id
        GameUtil:showTip(container:getVarNode("mHand"), rewadItems[id])
    end  
end

function CommonRewardPageNewBase:onExecute(container)
  
  

end

function CommonRewardPageNewBase:setSTR(time)
     timeStr = time
end

function CommonRewardPageNewBase:updateTimeStr(time)
    if selfContianer and #rewadItems <= 0 then
        NodeHelper:setStringForLabel(selfContianer, { mEmpty = time })
    end
end

function CommonRewardPageNewBase:ClearItem()
     rewadItems = {}
end

function CommonRewardPageNewBase:onExit(container)
    selfContianer = nil
    self:removePacket(container)
    onUnload(thisPageName, container)

    local isLevelUp = UserInfo.checkLevelUp()
    if GuideManager.isInGuide then
        if isLevelUp then
            PageManager.popPage("NewbieGuideForcedPage")
            PageManager.pushPage("NewbieGuideForcedPage")
        else
            GuideManager.forceNextNewbieGuide()   -- 沒有升級畫面 多跳一步驟
        end
    end
end

function CommonRewardPageNewBase_mDisChoose(container)
    NodeHelper:clearScrollView(container)
    timeStr = nil
    Coin = nil
    EXP = nil
    PageManager.popPage(thisPageName)
end

function CommonRewardPageNewBase:mDisChoose(container)
    NodeHelper:clearScrollView(container)
    if next(rewadItems) then
        local CommonRewardPage = require("CommPop.CommItemReceivePage")
        CommonRewardPage:setData(rewadItems, common:getLanguageString("@ItemObtainded"), nil)
        --CommonRewardPageBase_setPageParm(showReward, true, msg.rewardType)
        PageManager.pushPage("CommPop.CommItemReceivePage")
    end
    timeStr = nil
    Coin = nil
    EXP = nil
    PageManager.popPage(thisPageName)

    if mCallFun then
        mCallFun()
    end
    --PageManager.changePage("MainScenePage")
    -- PageManager.pushPage("PlayerInfoPage")
end

function CommonRewardPageNewBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then
        local msg = HeadFrame_pb.HPHeadFrameStateRet()
        msg:ParseFromString(msgBuff)
        protoDatas = msg

        -- self:rebuildItem(container)
        return
    end
end

function CommonRewardPageNewBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_SEVERINFO_UPDATE then
        -- 这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode

        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then

        end
    end
end

function CommonRewardPageNewBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function CommonRewardPageNewBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end 

function CommonRewardPageNewBase_setPageParm(_rewadItems, _curRewardStatus, rewardType, call)

    -- 材料
    local t1 = { }
    -- 装备
    local t2 = { }
    -- 道具
    local t3 = { }
    rewadItems = { }
    for i = 1, #_rewadItems do
        local data = _rewadItems[i]
        local itemConfig = ConfigManager.getItemCfg()[data.itemId]
        if itemConfig and itemConfig.type == 36 then
            table.insert(t1, _rewadItems[i])
        elseif itemConfig then
            table.insert(t3, _rewadItems[i])
        else 
            table.insert(t2, _rewadItems[i])
        end
    end



    table.sort(t3, function(itemId_1, itemId_2)
        local itemInf_1 = ConfigManager.getItemCfg()[itemId_1.itemId]
        local itemInf_2 = ConfigManager.getItemCfg()[itemId_2.itemId]
        if itemInf_1 and itemInf_2 then
            return itemInf_1.quality < itemInf_2.quality
        else
            return false
        end
    end )
    for i = 1, #t3 do
        table.insert(rewadItems, t3[i])
    end

    --    table.sort(t2, function(equip_1, equip_1)
    --        local equipInfo_1 = ConfigManager.getEquipCfg()[equip_1.itemId]
    --        local equipInfo_2 = ConfigManager.getEquipCfg()[equip_1.itemId]
    --        if equipInfo_1 and equipInfo_2 then
    --            return equipInfo_1.quality > equipInfo_2.quality
    --        else
    --            return false
    --        end
    --    end )

    for i = 1, #t2 do
        table.insert(rewadItems, t2[i])
    end

    


    for i = 1, #t1 do
        table.insert(rewadItems, t1[i])
    end


    -- rewadItems = common:table_tail(_rewadItems, #_rewadItems)

    curRewardStatus = _curRewardStatus
    title = ""
    rewardType = tonumber(rewardType)
    if rewardType and rewardTypeToStr[rewardType] then
        -- title = common:getLanguageString(rewardTypeToStr[rewardType])
    end
    mCallFun = call or nil
end

local CommonPage = require('CommonPage')
local CommonRewardPageNew = CommonPage.newSub(CommonRewardPageNewBase, thisPageName, option)

return CommonRewardPageNew