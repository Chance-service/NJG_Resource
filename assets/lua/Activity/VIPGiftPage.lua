--[[
    特权里面的VIP礼包
--]]
require "Activity2_pb"
local UserInfo = require("PlayerInfo.UserInfo");
local CommonPage = require("CommonPage")
local NewbieGuideManager = require("NewbieGuideManager")
local option = {
    ccbiFile = "Act_FixedTimeVIPGiftContent.ccbi",
    handlerMap =
    {
        onReturnButton = "onBack",
        onRechargeBtn = "onRecharge",
        onReceiveBtn = "onReceiveReward",
        onHelp = "onHelp"
    }
}
local NodeHelper = require("NodeHelper");
local VIPGiftPageBase = { }
local containerRef = { }

local VipWelfareItem = {
    ccbiFile = "Act_FixedTimeVIPGiftListContent.ccbi",
}

function VipWelfareItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

local PageInfo = {
    vipGiftCfg = { },
    rewardState = false
}

local thisPageName = "VIPGiftPage"
---------------------------------------------------------------

function VipWelfareItem:onFrame1(container)
    local index = self.index
    local itemInfo = PageInfo.vipGiftCfg[index]
    self:onShowItemInfo(container, itemInfo, 1)
end

function VipWelfareItem:onFrame2(container)
    local index = self.index
    local itemInfo = PageInfo.vipGiftCfg[index]
    self:onShowItemInfo(container, itemInfo, 2)
end

function VipWelfareItem:onFrame3(container)
    local index = self.index
    local itemInfo = PageInfo.vipGiftCfg[index]
    self:onShowItemInfo(container, itemInfo, 3)
end


function VipWelfareItem:onFrame4(container)
    local index = self.index
    local itemInfo = PageInfo.vipGiftCfg[index]
    self:onShowItemInfo(container, itemInfo, 4)
end


function VipWelfareItem:onShowItemInfo(container, itemInfo, rewardIndex)
    local rewardItems = { }
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end

    GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), rewardItems[rewardIndex])
end

function VipWelfareItem:onRefreshContent(ccbRoot)

    local container = ccbRoot:getCCBFileNode()
    local index = self.index
    local itemInfo = PageInfo.vipGiftCfg[index]


    containerRef[index] = container
    container:getVarLabelTTF("mVIPLvNum"):setString("VIP" .. tostring(itemInfo.vipLevel))
    local rewardItems = { }
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end
    local topTextFnt = "Activity_Title_blue.fnt"
    local bgNode = nil
    bgNode = CCSprite:create("Imagesetfile/ActivityCommon_3/Activity_common_title_1.png")
    if rewardItems[1] ~= nil and rewardItems[1].type == 70000 then
        if itemInfo.vipLevel == 3 then
            bgNode = CCSprite:create("Imagesetfile/ActivityCommon_3/Activity_common_title_3.png")
            topTextFnt = "Activity_Title_yellow.fnt"
        elseif itemInfo.vipLevel == 6 or itemInfo.vipLevel == 9 then
            bgNode = CCSprite:create("Imagesetfile/ActivityCommon_3/Activity_common_title_2.png")
            topTextFnt = "Activity_Title_red.fnt"
        end
    end
    local vipTitleBg = tolua.cast(container:getVarNode("mTopBg"), "CCScale9Sprite")

    if vipTitleBg then
        local vipTitleBgSize = vipTitleBg:getContentSize()
        vipTitleBg:setSpriteFrame(bgNode:displayFrame())
        vipTitleBg:setContentSize(vipTitleBgSize)
        NodeHelper:setBMFontFile(container, { mDiscountTxt = topTextFnt })
    end
    -- NodeHelper:fillRewardItem(container, rewardItems)
    NodeHelper:fillRewardItem(container, rewardItems, 4)
    local lb2Str =
    {
        mValueNum = itemInfo.formerPrice,
        -- 原始商品价格
        mCostNum = itemInfo.nowPrice,
        -- mDiscountTxt = common:getLanguageString("@vippackagename",tostring(itemInfo.vipLevel))

        mDiscountTxt = common:getLanguageString(itemInfo.name,tostring(itemInfo.vipLevel))
    }

    NodeHelper:setStringForLabel(container, lb2Str);

    local node = container:getVarLabelBMFont("mDiscountTxt")
    if node then
        node:setScale(0.8)
    end

    self.state = 0
    -- self.enable = true
    local btnStr = common:getLanguageString("@ActFTVIPGiftBtnTxt")

    local fntPath = GameConfig.FntPath.Bule
    local btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage

    if UserInfo.playerInfo.vipLevel < itemInfo.vipLevel then
        -- 等级不够
        fntPath = GameConfig.FntPath.Bule
        btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
        btnStr = common:getLanguageString("@GoToRecharge")
        NodeHelper:setNodesVisible(container, { mBtnTxt = true, mNumNode = false })
        NodeHelper:setMenuItemImage(container, { mBtn = { normal = btnNormalImage } })
        NodeHelper:setBMFontFile(container, { mBtnTxt = fntPath })
        NodeHelper:setMenuItemsEnabled(container, { mBtn = true })
        NodeHelper:setNodeIsGray(container, { mBtnTxt = false })
        self.state = 1
        -- self.enable = false
    else
        local hasBuy = false
        for i = 1, #PageInfo.buyList do
            if itemInfo.id == PageInfo.buyList[i] then
                hasBuy = true
                break
            end
        end

        if hasBuy then
            -- 已购买
            -- self.enable = false
            btnStr = common:getLanguageString("@HasBuy")
            fntPath = GameConfig.FntPath.Golden
            btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
            NodeHelper:setNodesVisible(container, { mBtnTxt = true, mNumNode = false })
            NodeHelper:setMenuItemImage(container, { mBtn = { normal = btnNormalImage } })
            NodeHelper:setBMFontFile(container, { mBtnTxt = fntPath })
            NodeHelper:setMenuItemsEnabled(container, { mBtn = false })
            NodeHelper:setNodeIsGray(container, { mBtnTxt = true })
        else
            -- 还没购买
            fntPath = GameConfig.FntPath.Golden
            btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
            NodeHelper:setNodesVisible(container, { mBtnTxt = false, mNumNode = true })
            NodeHelper:setMenuItemImage(container, { mBtn = { normal = btnNormalImage } })
            NodeHelper:setBMFontFile(container, { mBtnTxt = fntPath })
            NodeHelper:setMenuItemsEnabled(container, { mBtn = true })
            NodeHelper:setNodeIsGray(container, { mBtnTxt = false })
            self.state = 2
        end
    end
    NodeHelper:setStringForLabel(container, { mBtnTxt = btnStr })
end

function VipWelfareItem:onBtn(container)
    if self.state == 1 then
        -- 充值
        -- MainFrame:getInstance():popAllPage()
        PageManager.pushPage("RechargePage")
        PageManager.popPage("WelfarePage")
        -- 关闭特典

        --        RegisterLuaPage("RechargePage")
        --        RechargePage_showPage();
    elseif self.state == 2 then
        -- 购买
        local index = self.index
        local itemInfo = PageInfo.vipGiftCfg[index]

        if UserInfo.isGoldEnough(itemInfo.nowPrice) then
            local msg = Activity2_pb.GetVipPackageAward()
            msg.vipPackageId = itemInfo.id;
            local pb = msg:SerializeToString()
            PacketManager:getInstance():sendPakcet(HP_pb.VIP_PACKETAGE_GET_AWARD_C, pb, #pb, true)
        end
    end
end

function VIPGiftPageBase:onEnter(parentContainer)

    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    NodeHelper:initScrollView(container, "mContent", 5);

    self:registerPacket(parentContainer)
    PageInfo.vipGiftCfg = ConfigManager.getVipGiftCfg()

    self:getActivityInfo()

    containerRef = { }
    -- if container.mScrollView ~=nil then
    -- container:autoAdjustResizeScrollview(container.mScrollView);
    -- end
    -- self:rebuildAllItems( container )
    -- self:getRewardStatue( container )
    -- NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_VIPWELFARE)
    -- VIP0红点
    if registDay <=11 and ActivityInfo.NoticeInfo.OtherPageids[95] then
        CCUserDefault:sharedUserDefault():setIntegerForKey("VIPGiftPage"..UserInfo.serverId..UserInfo.playerInfo.playerId..registDay,1)
    end
    return container
end 

function VIPGiftPageBase:getActivityInfo()
    common:sendEmptyPacket(HP_pb.VIP_PACKAGE_INFO_C)
end

function VIPGiftPageBase:refreshPage(container)
    if PageInfo.rewardState then
        container:getVarMenuItemImage("mReceiveBtn"):selected()
    else
        container:getVarMenuItemImage("mReceiveBtn"):unselected()
    end
end

function VIPGiftPageBase:rebuildAllItems(container)
    self.container.mScrollView:removeAllCell()
    self:clearAllItems(container)
    self:buildAllItems(container)
    -- self:setCurVipReward( container )
end

function VIPGiftPageBase:setCurVipReward(container)
    local totalOffset = container.mScrollView:getContentOffset()
    if UserInfo.playerInfo.vipLevel == 0 or UserInfo.playerInfo.vipLevel == 1 then
        return
    end

    local curY = totalOffset.y + container.mScrollView:getContentSize().height *(UserInfo.playerInfo.vipLevel - 1) / 15

    if curY > 0 then
        curY = 0
    end

    local curOffset = CCPointMake(totalOffset.x, curY)
    container.mScrollView:setContentOffset(curOffset)
end

function VIPGiftPageBase:isContain(n)

    for i = 1, #PageInfo.buyList do
        if PageInfo.buyList[i] == n then
            return true
        end
    end

    return false
end

function VIPGiftPageBase:clearAllItems(container)
    NodeHelper:clearScrollView(container)
end


function VIPGiftPageBase:buildAllItems(container)

    local t = { }
    -- 可以购买
    local t1 = { }
    -- 已购买
    local t2 = { }
    -- 不能购买
    local sortCfg = { }
    for k, v in pairs(PageInfo.vipGiftCfg) do
        table.insert(sortCfg, v);
    end
    table.sort(sortCfg,
        function(d1, d2)
            return d1.order < d2.order;
        end
    );
    for k, v in pairs(sortCfg) do
        if self:isContain(v.id) then
            table.insert(t1, v)
            -- 已购买
        else
            if UserInfo.playerInfo.vipLevel < v.vipLevel then
                table.insert(t2, v)
                -- 不能购买
            else
                table.insert(t, v)
                -- 可以购买
            end
        end
    end


    local idx = 0
    local cell, panel
    for i, v in pairs(t) do
        cell = CCBFileCell:create()
        panel = VipWelfareItem:new( { id = idx + 1, index = v.id })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(VipWelfareItem.ccbiFile)
        container.mScrollView:addCell(cell, idx)
        idx = idx + 1
    end

    for i, v in pairs(t2) do
        cell = CCBFileCell:create()
        panel = VipWelfareItem:new( { id = idx + 1, index = v.id })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(VipWelfareItem.ccbiFile)
        container.mScrollView:addCell(cell, idx)

        idx = idx + 1
    end

    for i, v in pairs(t1) do
        cell = CCBFileCell:create()
        panel = VipWelfareItem:new( { id = idx + 1, index = v.id })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(VipWelfareItem.ccbiFile)
        container.mScrollView:addCell(cell, idx)

        idx = idx + 1
    end

    --    local cell, panel
    --    for i, v in ipairs(PageInfo.vipGiftCfg) do
    --        cell = CCBFileCell:create()
    --        panel = VipWelfareItem:new( { id = i })
    --        cell:registerFunctionHandler(panel)
    --        cell:setCCBFile(VipWelfareItem.ccbiFile)
    --        container.mScrollView:addCellBack(cell)
    --    end
    container.mScrollView:orderCCBFileCells()
    -- NodeHelper:buildScrollView(container, #PageInfo.vipGiftCfg, VipWelfareItem.ccbiFile, VipWelfareItem.onFunction)
end

function VIPGiftPageBase:onExecute(container)

end

function VIPGiftPageBase:onExit(parentContainer)
    self:removePacket(parentContainer)
    containerRef = { }
    self.container.mScrollView:removeAllCell()
end

function VIPGiftPageBase:onBack(container)
    PageManager.popPage(thisPageName)
    PageManager.refreshPage("ActivityPage");
end

function VIPGiftPageBase:onRecharge(container)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "VIPPerks_enter_rechargePage")
    PageManager.pushPage("RechargePage")
end

function VIPGiftPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_VIPWELFARE)
end

function VIPGiftPageBase:onReceiveReward(container)
    if PageInfo.rewardState then
        MessageBoxPage:Msg_Box_Lan("@VipWelfareAlreadyReceive")
        self:refreshPage(container)
    else
        UserInfo.sync()
        if UserInfo.playerInfo.vipLevel > 0 then
            common:sendEmptyPacket(HP_pb.VIP_WELFARE_AWARD_C, true)
        else
            MessageBoxPage:Msg_Box_Lan("@VipLevelNotEnough")
        end
    end
end 

function VIPGiftPageBase:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode();
    local msgBuff = parentContainer:getRecPacketBuffer();
    if opcode == HP_pb.VIP_PACKETAGE_INFO_S then
        local msg = Activity2_pb.HPVipPackageInfoRet()
        msg:ParseFromString(msgBuff)
        PageInfo.buyList = { }
        for i = 1, #msg.vipPackageList do
            PageInfo.buyList[i] = tonumber(msg.vipPackageList[i])
        end
        self:rebuildAllItems(self.container)
        return;
    end
    if opcode == HP_pb.VIP_PACKETAGE_GET_AWARD_S then
        local msg = Activity2_pb.HPGetVipPackageAward()
        msg:ParseFromString(msgBuff)
        local vipId = msg.vipPackageId
        PageInfo.buyList[#PageInfo.buyList + 1] = msg.vipPackageId
        --        if containerRef[msg.vipPackageId] then
        --            NodeHelper:setMenuItemsEnabled(containerRef[msg.vipPackageId], { mBtn = false })
        --            NodeHelper:setNodeIsGray(containerRef[msg.vipPackageId], { mBtnTxt = true })
        --            NodeHelper:setStringForLabel(containerRef[msg.vipPackageId], { mBtnTxt = common:getLanguageString("@HasBuy") });
        --        end


        self:rebuildAllItems(self.container)

        VIPGiftPageBase:clearNotice()
        if vipId ~= nil then
            if vipId == 4 or vipId == 11 then
                PageManager.showRedNotice("Equipment", true)
            end
        end
        return;
    end
end

function VIPGiftPageBase:clearNotice()
    -- 红点消除
    local hasNotice = false
    local hasBuy
    for i, itemInfo in ipairs(PageInfo.vipGiftCfg) do
        if UserInfo.playerInfo.vipLevel >= itemInfo.vipLevel then
            hasBuy = false
            for i = 1, #PageInfo.buyList do
                if itemInfo.id == PageInfo.buyList[i] then
                    hasBuy = true
                    break
                end
            end
            if not hasBuy then
                hasNotice = true
                break
            end
        end

    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.VIP_PACKAGE);
    end
end

function VIPGiftPageBase:registerPacket(parentContainer)
    parentContainer:registerPacket(HP_pb.VIP_PACKETAGE_INFO_S)
    parentContainer:registerPacket(HP_pb.VIP_PACKETAGE_GET_AWARD_S)
end

function VIPGiftPageBase:removePacket(parentContainer)
    parentContainer:removePacket(HP_pb.VIP_PACKETAGE_INFO_S)
    parentContainer:removePacket(HP_pb.VIP_PACKETAGE_GET_AWARD_S)
end
---------------------------------------------------------------
VIPGiftPage = CommonPage.newSub(VIPGiftPageBase, thisPageName, option);

return VIPGiftPage