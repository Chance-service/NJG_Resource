

local HP_pb = require("HP_pb") -- 包含协议id文件
local thisPageName = "CommonRewardPage"
local curRewardStatus = false -- 不可领取状态
local title = ""
local GuideManager = require("Guide.GuideManager")

local rewadItems = { } -- 奖励物品 必须是读配置这种格式10000_1001_50 读出来的数组
local ItemManager = require("Item.ItemManager")
local mCallFun = nil

----这里是协议的id
local opcodes = {

}

local option = {
    ccbiFile = "CommonRewardPopUp.ccbi",
    handlerMap =
    {
        -- 按钮点击事件
        onExit = "onClose",

    },
    opcode = opcodes
}

local rewardTypeToStr = { "@TLLoadTreasureRewardTxt", "@ACTTLTreasureRaiderRewardTxt" }

local CommonRewardPageBase = { }
function CommonRewardPageBase:onEnter(container)
     self:registerPacket(container)
     local spinePath = "Spine/leveup"
     local spineName = "leveup"
     local spine = SpineContainer:create(spinePath, spineName)
    
     
     local spineNode = tolua.cast(spine, "CCNode")
     local parentNode = container:getVarNode("mSpine")
     parentNode:setPositionY(parentNode:getPositionY() + 50)
     parentNode:removeAllChildrenWithCleanup(true)
     parentNode:addChild(spineNode)  
     local array = CCArray:create()
     array:addObject(CCDelayTime:create(0))
     array:addObject(CCCallFunc:create(function()
        spine:runAnimation(1, "animation03", 0)
        spine:addAnimation(1, "animation04", true)
     end))
     parentNode:runAction(CCSequence:create(array))

     local ItemObtain = container:getVarNode("mItemObtained")
     ItemObtain:setPositionY(ItemObtain:getPositionY() + 20)
     local AnyWhereToExit = container:getVarNode("mAnyWhereToExit")
     AnyWhereToExit:setPositionY(AnyWhereToExit:getPositionY() + 20)
     local mContent = container:getVarNode("mContent")
     mContent:setPositionY(mContent:getPositionY() + 20)
     mContent:setPositionX(mContent:getPositionX() + 5)

      
    NodeHelper:initScrollView(container, "mContent", #rewadItems);
    if curRewardStatus then
        NodeHelper:setNodesVisible(container, { mGetPic = false, mSurePic = true })
    else
        NodeHelper:setNodesVisible(container, { mGetPic = true, mSurePic = false })
    end
    NodeHelper:setNodesVisible(container, { mActivityTxt = true })
    NodeHelper:setStringForLabel(container, { mActivityTxt = title })
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
        );
    end


    --    local nodeTest = container:getVarNode("mNodeTest")
    --    CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfo("Reward_animation/Reward_animation.ExportJson")
    --    local armatureBird  = CCArmature:create("Reward_animation")
    --    nodeTest:addChild(armatureBird)
    --    armatureBird:getAnimation():playWithIndex(1)

end

function CommonRewardPageBase:showRewardItems(container)
    NodeHelper:clearScrollView(container)
    --- 这里是清空滚动层
    local size = #rewadItems
    --  BackpackItem.ccbi
    NodeHelper:buildScrollViewHorizontal(container, size, "CommonRewardContent.ccbi", CommonRewardPageBase.onFunction, 6)

    if size <= 4 then
        local node = container:getVarNode("mContent")
        local x = node:getPositionX()
        node:setPositionX(x +(440 - size * 106) / 2);
        node:setTouchEnabled(false)
        NodeHelper:setNodesVisible(container, { mLiftArrow = false, mRightArrow = false })
    end
    if GuideManager.IsNeedShowPage == true then
        GuideManager.IsNeedShowPage = false
        GuideManager.PageContainerRef["CommonReward"] = container
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function CommonRewardPageBase.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        --- 每个子空间创建的时候会调用这个函数
        local contentId = container:getItemDate().mID;
        -- 获取到时第几行
        local i = contentId
        -- 获取当前的index      i是每行的第几个 用来获取组件用的
        local node = container:getVarNode("mItem")
        local itemNode = ScriptContentBase:create('GoodsItem.ccbi');
        local ResManager = require "ResManagerForLua"
        local resInfo = ResManager:getResInfoByTypeAndId(rewadItems[i].type, rewadItems[i].itemId, rewadItems[i].count);
        NodeHelper:setStringForLabel(itemNode, { mName = "" });
        local numStr = ""
        if resInfo.count > 0 then
            numStr = "x" .. resInfo.count
        end
        local lb2Str = {
            mNumber = numStr
        };
        local showName = "";
        if rewadItems[i].type == 30000 then
            showName = ItemManager:getShowNameById(rewadItems[i].itemId)
        else
            showName = resInfo.name
        end
        --NodeHelper:setNodesVisible(itemNode, { m2Percent = false, m5Percent = false });
        
        if rewadItems[i].type == 40000 then
            for i = 1, 6 do
                NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.quality })
            end
        end
        NodeHelper:setNodesVisible(itemNode, { mStarNode = rewadItems[i].type == 40000 })
        NodeHelper:setNodesVisible(itemNode, { ["mNFT"] = false })

        if rewadItems[i].multiple and rewadItems[i].multiple == 2 then
            -- 两倍
            NodeHelper:setNodesVisible(itemNode, { m2Percent = true });
        elseif rewadItems[i].multiple and rewadItems[i].multiple == 5 then
            -- 5倍奖励
            NodeHelper:setNodesVisible(itemNode, { m5Percent = true });
        end
        -- NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.BlurryLineWidth + 1000, 4)
        --NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.BlurryLineWidth - 10, 4)
        NodeHelper:setStringForLabel(itemNode, lb2Str);
        NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = 1 });
        NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality });
        NodeHelper:setColorForLabel(itemNode, { mName = ConfigManager.getQualityColor()[resInfo.quality].textColor })
        node:setScale(1.4)
        -- NodeHelper:setColor3BForLabel(itemNode, {mName = common:getColorFromConfig("Own")});
        ----是否是神器  现在强制为第一种神器
        if rewadItems[i].isGodly then
            local aniNode = itemNode:getVarNode("mAni");
            local ccbiFile = GameConfig.GodlyEquipAni.First
            local ani = ScriptContentBase:create(ccbiFile);
            ani:release()
            ani:unregisterFunctionHandler();
            aniNode:addChild(ani);
        end
        node:addChild(itemNode);
        itemNode:registerFunctionHandler(CommonRewardPageBase.onFunction)
        itemNode.id = contentId
        itemNode:release();
        -- end
    elseif eventName == "onHand" then
        local id = container.id
        GameUtil:showTip(container:getVarNode("mHand"), rewadItems[id])
    end
end

function CommonRewardPageBase:onExecute(container)

end

function CommonRewardPageBase:onExit(container)
    self:removePacket(container)
    onUnload(thisPageName, container);
    local isLevelUp = UserInfo.checkLevelUp()
    if not isLevelUp then
        if GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] ~= 0 then
            local guideCfg = GuideManager.getStepCfgByIndex(GuideManager.currGuideType, GuideManager.getCurrentStep())
            if guideCfg and guideCfg.showType == 8 then
                GuideManager.forceNextNewbieGuide()
            end
        end
    end
end

function CommonRewardPageBase_onClose()
    PageManager.popPage(thisPageName)
end

function CommonRewardPageBase:onClose(container)
    PageManager.popPage(thisPageName)

    if mCallFun then
        mCallFun()
    end
    -- PageManager.changePage("MainScenePage")
    -- PageManager.pushPage("PlayerInfoPage")
    if GuideManager.IsNeedShowPage == true then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function CommonRewardPageBase:onReceivePacket(container)
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

function CommonRewardPageBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then
        -- 这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;

        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then

        end
    end
end

function CommonRewardPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function CommonRewardPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

function CommonRewardPageBase_setPageParm(_rewadItems, _curRewardStatus, rewardType, call)

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
    title = "Item Obtained"
    rewardType = tonumber(rewardType)
    if rewardType and rewardTypeToStr[rewardType] then
        -- title = common:getLanguageString(rewardTypeToStr[rewardType])
    end
    mCallFun = call or nil
end

local CommonPage = require('CommonPage')
local CommonRewardPage = CommonPage.newSub(CommonRewardPageBase, thisPageName, option)