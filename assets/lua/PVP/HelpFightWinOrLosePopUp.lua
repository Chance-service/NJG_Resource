
local thisPageName = "HelpFightWinOrLosePopUp"

local tostring = tostring
local basePage = require("BasePage")
local BattleDataHelper = require("Battle.BattleDataHelper")
local HelpFightDataManager = require("PVP.HelpFightDataManager")
local HelpFightGuideManager = require("PVP.HelpFightGuideManager")
local NodeHelper = require("NodeHelper")
local pageManager = require("PageManager")
local ConfigManager = require("ConfigManager")
local GameConfig = require("GameConfig")
local UserInfo = require("PlayerInfo.UserInfo")
local ResManager = require("ResManagerForLua");
local Const_pb = require("Const_pb");
local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")
local ElementManager = require("Element.ElementManager")
local common = require("common")
local ElementConfig = require("Element.ElementConfig")
local MultiEliteDataManger = require("Battle.MultiEliteDataManger")
local PVPBattleManager = require("Battle.PVPBattleManager")
local ClimbingDataManager = require("PVP.ClimbingDataManager")
local option = {
    ccbiFile = "BattleWinOrLosePopUp_2.ccbi",
    handlerMap =
    {
        onTunkScreenContinue = "onClose",
        onUpgradeEquipment = "onUpgradeEquipment",
        onMercenaryCulture = "onMercenaryCulture",
        onSkilladjust = "onSkilladjust",
        -- onRewardItemLeftArrow  = "onItemLeftArrow",
        -- onRewardItemRightArrow = "onItemRightArrow",
        onOpenItemLeftArrow = "onBoxLeftArrow",
        onOpenItemRightArrow = "onBoxRightArrow",
        onShopping = "onShopping",
        onClickGuide = "onClose",
        onDoubleReward = "onDoubleReward",
    }
}
local ItemContentUI = {
    ccbiFile = "GoodsItem.ccbi"
}
local HelpFightWinOrLosePopUp = basePage:new(option, thisPageName)
-- 战斗结果(胜利还是失败)
local nBattleResult = nil
-- 战斗掉落的物品
local nBattleResultData = nil
local isTouchItem = false -- 是否点击了物品详情

local oTotalItemInfo = { }

local oOpenBoxItem = { }
local oRewardItem = { }
local mRewardItemScrollView = nil
local mOpenBoxScrollView = nil
local mRewardLeftArrow = nil
local mRewardRightArrow = nil
local nCurBoxPage = 1
local nCurItemPage = 1
local nTotalItemPage = 1
local nTotalBoxPage = 1
local fOneIconWidth = 0
local fItemDistence = 7.5
local fBoxDistence = 15
local nTipTag = 0
local doubleRewardCost = 0

function HelpFightWinOrLosePopUp:resetData()

    nBattleResult = HelpFightDataManager.ChallengeData.challengeResult
    -- 战斗掉落的物品
    if nBattleResult == 1 then
        nBattleResultData = HelpFightDataManager.ChallengeData.randReward
    else
        nBattleResultData = {}
    end
    local oOpenBoxItem = { }
    local oRewardItem = { }
    local nCurBoxPage = 1
    local nCurItemPage = 1
    local nTotalItemPage = 1
    local nTotalBoxPage = 1
    oTotalItemInfo = {}
    nTipTag = 0
    local oTotalItemInfo = { }
    isTouchItem = false
end

function HelpFightWinOrLosePopUp:onEnter(container)
    -- container:runAnimation("Untitled Timeline")
    HelpFightWinOrLosePopUp:resetData()
    local mExpNum = nil
    local mCoinNum = nil
    local mLevel = nil



    mRewardLeftArrow = container:getVarMenuItemImage("mRewardItemLeftArrow")
    mRewardRightArrow = container:getVarMenuItemImage("mRewardItemRightArrow")
    mRewardLeftArrow:setVisible(true)
    mRewardRightArrow:setVisible(true)
    if nBattleResult == 1 then
        -- 胜利
        HelpFightWinOrLosePopUp:onShowWinView(container)
        NodeHelper:setNodesVisible(container, {
            mWinNode = true,
            mLoseNode = false,
            mDoubleRewardNode = true,
        } )
        mExpNum = container:getVarLabelTTF("mRewardExpNum")
        mCoinNum = container:getVarLabelTTF("mRewardCoinNum")
        mLevel = container:getVarLabelTTF("mLevel")
        mExpNum:setString(common:getLanguageString("@RewardExp") .. tostring(nBattleResultData.exp or 0))
        mCoinNum:setString(common:getLanguageString("@RewardCoin") .. tostring(nBattleResultData.coin or 0))
        local mDoubleRewardTex = container:getVarLabelTTF("mDoubleRewardTex")
        if #oTotalItemInfo > 0 then
            local resInfo = ResManager:getResInfoByTypeAndId(oTotalItemInfo[1].type, oTotalItemInfo[1].itemId, oTotalItemInfo[1].count)
            local doubleReward = ConfigManager.getHelpFightBasicCfg()
            local cost = 0
            if doubleReward then
                local allCost = common:split(doubleReward[1].dropbuy, ",")
                cost = allCost[resInfo.quality - 1]
            end
            doubleRewardCost = tonumber(cost)
            mDoubleRewardTex:setString(cost or 0)
        end
        NodeHelper:playMusic("Offline login_04.mp3")
    else
        -- 失败
        HelpFightWinOrLosePopUp:onShowLoseView(container)
        NodeHelper:setNodesVisible(container, {
            mWinNode = false,
            mLoseNode = true,
            mDoubleRewardNode = false,
        } )
        mExpNum = container:getVarLabelTTF("mLoseRewardExpNum")
        mCoinNum = container:getVarLabelTTF("mLoseRewardCoinNum")
        mLevel = container:getVarLabelTTF("mLoseLevel")
        mExpNum:setString("")
        mCoinNum:setString("")
        NodeHelper:playMusic("Offline login_05.mp3")

    end
    if UserInfo.roleInfo.level < GameConfig.LevelLimit.MecenaryOpenLevel then
        NodeHelper:setNodesVisible(container, { mMercenaryIconNode = false })
        NodeHelper:SetNodePostion(container, "mFailIconNode", 75, 0)
    end


    -- mExpNum:setString(tostring(nBattleResultData.exp or 0))
    -- mCoinNum:setString(tostring(nBattleResultData.coin or 0))
    mLevel:setString(UserInfo.getStageAndLevelStr())
    HelpFightWinOrLosePopUp:updateExp(container)

    local guideNode = container:getVarNode("mGuideNode");
    NodeHelper:setNodeVisible(guideNode, false)

    HelpFightGuideManager.bieGuide()
end

function HelpFightWinOrLosePopUp:onShowWinView(container)
    if  nBattleResultData.showItems then
        for i = 1, #nBattleResultData.showItems do
            local tmpData = {
                type = nBattleResultData.showItems[i].itemType ,
                itemId = nBattleResultData.showItems[i].itemId ,
                count = nBattleResultData.showItems[i].itemCount,
            }
            table.insert(oTotalItemInfo,tmpData)
        end
    end
    oTotalItemInfo = oTotalItemInfo or {}
    HelpFightWinOrLosePopUp:onShowDropEquipItem(container)

end

function HelpFightWinOrLosePopUp:onDealWithDropBox(container)
    --[[
    local mBattleRewardBox = container:getVarNode("mBattleRewardOpenbox")
    local mNoRewardboxtext = container:getVarLabelBMFont("mNoRewardboxtext")
    mBattleRewardBox:setVisible(true)--]]
    local drop = nBattleResultData.drop
    if drop == nil or #drop.treasure == 0 then
        --[[
		mBattleRewardBox:setVisible(false)
		mNoRewardboxtext:setString(common:getLanguageString("@NoRewardbox"))
		local resInfo = ResManager:getResInfoByMainTypeAndId(Const_pb.TOOL, 40001, 0);
			NodeHelper:setSpriteImage(container, {["mNoRewarBoxPic"] = resInfo.icon});--]]
        return
    end
    oOpenBoxItem = { }
    for i = 1, #drop.treasure do
        local oneBox = drop.treasure[i]
        if oneBox.state == Battle_pb.TREASURE_DISCARD then
            --[[
            mBattleRewardBox:setVisible(false)
            local nType = oneBox.itemId % 10
            mNoRewardboxtext:setString(common:getLanguageString("@OpenBoxNeedKey"..tostring(nType)))
            local resInfo = ResManager:getResInfoByMainTypeAndId(Const_pb.TOOL, oneBox.itemId, 0);
            NodeHelper:setSpriteImage(container, {["mNoRewarBoxPic"] = resInfo.icon});
            return--]]
            break
        elseif oneBox.state == Battle_pb.TREASURE_LUCKY_OPEN then
            -- 幸运宝箱额外掉落
            for i = 1, #oneBox.item do
                local oneBoxItem = oneBox.item[i]
                local resInfo = ResManager:getResInfoByTypeAndId(oneBoxItem.itemType, oneBoxItem.itemId, oneBoxItem.itemCount);
                table.insert(oOpenBoxItem, resInfo)
                table.insert(oTotalItemInfo, { type = oneBoxItem.itemType, itemId = oneBoxItem.itemId, count = oneBoxItem.itemCount, info = resInfo })
            end
            for i = 1, #oneBox.luckItem do
                local oneBoxLuckItem = oneBox.luckItem[i]
                local resInfo = ResManager:getResInfoByTypeAndId(oneBoxLuckItem.itemType, oneBoxLuckItem.itemId, oneBoxLuckItem.itemCount)
                table.insert(oOpenBoxItem, resInfo)
                table.insert(oTotalItemInfo, { type = oneBoxLuckItem.itemType, itemId = oneBoxLuckItem.itemId, count = oneBoxLuckItem.itemCount, info = resInfo })
            end
        else
            -- 如果有钥匙
            for i = 1, #oneBox.item do
                local oneBoxItem = oneBox.item[i]
                local resInfo = ResManager:getResInfoByTypeAndId(oneBoxItem.itemType, oneBoxItem.itemId, oneBoxItem.itemCount)
                table.insert(oOpenBoxItem, resInfo)
                table.insert(oTotalItemInfo, { type = oneBoxItem.itemType, itemId = oneBoxItem.itemId, count = oneBoxItem.itemCount, info = resInfo })
            end
        end
    end
    -- HelpFightWinOrLosePopUp:onShowBoxItem(container)
end

function HelpFightWinOrLosePopUp:onShowBoxItem(container)
    if #oOpenBoxItem == 0 then return end
    nTotalBoxPage = HelpFightWinOrLosePopUp:countPage(#oOpenBoxItem, 3)
    if nTotalBoxPage > 1 then mBoxRightArrow:setVisible(true) end
    nCurBoxPage = 1
    mOpenBoxScrollView = container:getVarScrollView("mBattleOpenBox")
    HelpFightWinOrLosePopUp:initScroll(container)
    -- HelpFightWinOrLosePopUp:displayItems(container, mOpenBoxScrollView, oOpenBoxItem, nTotalBoxPage, 210, 3, fBoxDistence)
end

function HelpFightWinOrLosePopUp.onClickHandler(eventName, container)
    if eventName == "onHand" then
        local itemId = container:getTag()
        if itemId == nTipTag then
            GameUtil:hideTip()
            nTipTag = 0
            isTouchItem = true
            return
        end
        nTipTag = itemId
        for i = 1, #oTotalItemInfo do
            if oTotalItemInfo[i].itemId == itemId then
                GameUtil:showTip(container:getVarMenuItemImage("mHand"), oTotalItemInfo[i])
                isTouchItem = true
                break
            end
        end
    end
end

function HelpFightWinOrLosePopUp:initScroll(container)
    NodeHelper:initScrollView(container, "mBattleRewardItem", #oTotalItemInfo);
    container.scrollview = container:getVarScrollView("mBattleRewardItem");
    NodeHelper:clearScrollView(container)
    --- 这里是清空滚动层
    local size = #oTotalItemInfo
    --  BackpackItem.ccbi
    NodeHelper:buildScrollViewHorizontal(container, size, "CommonRewardContent.ccbi", HelpFightWinOrLosePopUp.onFunctionCall, 0)

    if size <= 5 then
        local node = container:getVarNode("mBattleRewardItem")
        local x = node:getPositionX()
        node:setPositionX(x +(530 - size * 106) / 2);
        node:setTouchEnabled(false)
        NodeHelper:setNodesVisible(container, { mRewardItemLeftArrow = false, mRewardItemRightArrow = false })
    end
    ScriptMathToLua:setSwallowsTouches(scrollview)
end

function HelpFightWinOrLosePopUp.onFunctionCall(eventName, container)
    if eventName == "luaRefreshItemView" then
        --- 每个子空间创建的时候会调用这个函数
        local contentId = container:getItemDate().mID;
        -- 获取到时第几行
        local i = contentId
        -- 获取当前的index      i是每行的第几个 用来获取组件用的
        local node = container:getVarNode("mItem")
        local itemNode = ScriptContentBase:create('GoodsItem.ccbi');
        local ResManager = require "ResManagerForLua"
        local resInfo = ResManager:getResInfoByTypeAndId(oTotalItemInfo[i].type, oTotalItemInfo[i].itemId, oTotalItemInfo[i].count);
        NodeHelper:setStringForLabel(itemNode, { mName = "" });
        local lb2Str = {
            mNumber = "x" .. resInfo.count
        };
        local showName = "";
        if oTotalItemInfo[i].type == 30000 then
            showName = ItemManager:getShowNameById(oTotalItemInfo[i].itemId)
        else
            showName = resInfo.name
        end
        NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.LineWidth.ItemNameLength - 80, 5)
        NodeHelper:setStringForLabel(itemNode, lb2Str);
        -- NodeHelper:setSpriteImage(itemNode, {mPic = resInfo.icon}, {mPic = resInfo.iconScale});
        NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = GameConfig.EquipmentIconScale });
        NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality });

        local colorMap = { }

        colorMap.mName = ConfigManager.getQualityColor()[resInfo.quality].textColor
        -- colorMap.mNumber = ConfigManager.getQualityColor()[resInfo.quality].textColor
        colorMap.mNumber = "255 255 255"

        NodeHelper:setColorForLabel(itemNode, colorMap)

        node:addChild(itemNode);
        itemNode:registerFunctionHandler(HelpFightWinOrLosePopUp.onFunctionCall)
        itemNode.id = contentId
        itemNode:release();
        -- PlayerFramePageBase.onRefreshItemView(container);
    elseif eventName == "onHand" then
        -- 点击每个子空间的时候会调用函数
        local id = container.id
        GameUtil:showTip(container:getVarNode("mHand"), oTotalItemInfo[id])
        return
    end
end

function HelpFightWinOrLosePopUp:displayItems(container, mScrollView, ItemsArr, itemPage, fHeight, nPreRowNum, fDistence)
    mScrollView:getContainer():removeAllChildren()
    mScrollView:setPositionY(mScrollView:getPositionY() -10)
    local node = CCNode:create()
    local bOnePage = false
    if itemPage == 1 then
        bOnePage = true
    else
        bOnePage = false
    end
    local itemNode = nil
    local fwidth = 0
    local fPosXInPage = 0
    local fPosX = 0
    local index = 0
    for i = 1, #ItemsArr do
        itemNode = HelpFightWinOrLosePopUp:createItem(i, ItemsArr)
        itemNode:setTag(ItemsArr[i].itemId)
        itemNode:registerFunctionHandler(HelpFightWinOrLosePopUp.onClickHandler)
        local mHand = itemNode:getVarMenuItemImage("mHand")
        fOneIconWidth = mHand:getContentSize().width
        if bOnePage then
            itemNode:setPosition(ccp(fOneIconWidth *(i - 1) + fOneIconWidth / 2 +(i - 1) * fDistence, 0))
            fwidth = mHand:getContentSize().width * i +(i - 1) * fDistence
            node:addChild(itemNode)
        else
            index = math.floor(i / nPreRowNum)
            local resIndex = i - index * nPreRowNum
            if i >(index * nPreRowNum) then
                fPosXInPage = fOneIconWidth *(resIndex - 1) + fOneIconWidth / 2 + resIndex * fDistence
                fPosX = fPosXInPage + index * mScrollView:getViewSize().width
            elseif i == index * nPreRowNum then
                fPosXInPage = fOneIconWidth *(nPreRowNum - 1) + fOneIconWidth / 2 + nPreRowNum * fDistence
                fPosX =(index - 1) * mScrollView:getViewSize().width + fPosXInPage
            end
            itemNode:setPosition(ccp(fPosX, fOneIconWidth / 2 + 45))
            mScrollView:getContainer():addChild(itemNode)
        end
    end
    if bOnePage then
        mScrollView:getContainer():addChild(node)
        node:setPosition(ccp(mScrollView:getViewSize().width / 2 - fwidth / 2, fOneIconWidth / 2 + 45))
    else
        local size = CCSizeMake(mScrollView:getViewSize().width *(itemPage - 1), mScrollView:getViewSize().height)
        mScrollView:setContentSize(size)
    end
    mScrollView:setTouchEnabled(false)
    ScriptMathToLua:setSwallowsTouches(scrollview)
end

function HelpFightWinOrLosePopUp:onShowDropEquipItem(container)
    if #oTotalItemInfo == 0 then return end
    nTotalItemPage = HelpFightWinOrLosePopUp:countPage(#oTotalItemInfo, 5)
    if nTotalItemPage > 1 then mRewardRightArrow:setVisible(true) end
    nCurItemPage = 1
    mRewardItemScrollView = container:getVarScrollView("mBattleRewardItem")
    HelpFightWinOrLosePopUp:initScroll(container)
    -- HelpFightWinOrLosePopUp:displayItems(container, mRewardItemScrollView, oTotalItemInfo, nTotalItemPage, 400, 5, fItemDistence)
end

function HelpFightWinOrLosePopUp:onDealWithDropEqiup(container)
    oRewardItem = { }
    local drop = nBattleResultData.drop
    if drop ~= nil then
        -- 详细装备掉落情况
        for i = 1, #drop.detailEquip do
            local oneEquip = drop.detailEquip[i]
            local resInfo = ResManager:getResInfoByTypeAndId(40000, oneEquip.itemId, oneEquip.count)
            table.insert(oRewardItem, resInfo)
            table.insert(oTotalItemInfo, { type = 40000, itemId = oneEquip.itemId, count = oneEquip.count, info = resInfo })
        end
        -- 物品掉落情况
        for i = 1, #drop.item do
            local oneEquip = drop.item[i]
            local resInfo = ResManager:getResInfoByTypeAndId(oneEquip.itemType, oneEquip.itemId, oneEquip.itemCount)
            table.insert(oRewardItem, resInfo)
            table.insert(oTotalItemInfo, { type = oneEquip.itemType, itemId = oneEquip.itemId, count = oneEquip.itemCount, info = resInfo })
        end
        for i = 1, #drop.detailElement do
            local oneElement = drop.detailElement[i]
            local resInfo = ResManager:getResInfoByMainTypeAndId(Const_pb.ELEMENT, oneElement.itemId, oneElement.count)
            local icon = ElementConfig.ElementCfg[oneElement.itemId].icon
            resInfo.icon = icon
            table.insert(oRewardItem, resInfo)
            -- table.insert(oTotalItemInfo, {type = Const_pb.ELEMENT, itemId = oneElement.itemId, count = oneElement.count})
        end
    end
    -- HelpFightWinOrLosePopUp:onShowDropEquipItem(container)
end

function HelpFightWinOrLosePopUp:onShowLoseView(container)

end

function HelpFightWinOrLosePopUp:onUpgradeEquipment()
    registerScriptPage("EquipIntegrationPage")
    EquipIntegrationPage_CloseHandler(MainFrame_onMainPageBtn())
    EquipIntegrationPage_SetCurrentPageIndex(true)
    PageManager.changePage("EquipIntegrationPage")

    -- PageManager.setJumpTo("MeltPage")
    -- PageManager.pushPage("MeltPage");
    PageManager.popPage(thisPageName)
end
function HelpFightWinOrLosePopUp:onShopping()
    pageManager.changePage("ShopControlPage")
    PageManager.popPage(thisPageName)
end
function HelpFightWinOrLosePopUp:onMercenaryCulture()
    if UserInfo.roleInfo.level < GameConfig.LevelLimit.MecenaryOpenLevel then
        MessageBoxPage:Msg_Box("@MercenaryLevelNotEnough")
        return
    else
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange._IsPageJump = true
        PageJumpMange._CurJumpCfgInfo = PageJumpMange._JumpCfg[25];
        PageManager.changePage("EquipmentPage");
    end
    pageManager.popPage(thisPageName)
end

function HelpFightWinOrLosePopUp:onSkilladjust()
    pageManager.changePage("SkillPage")
    pageManager.popPage(thisPageName)
end

function HelpFightWinOrLosePopUp:updateExp(container)
    local mExpBar = nil
    if nBattleResult == 1 then
        mExpBar = container:getVarNode("mExp")
    else
        mExpBar = container:getVarNode("mLoseExp")
    end
    if mExpBar then
        mExpBar:removeAllChildren()
        local currentExp = UserInfo.roleInfo.exp
        local roleExpCfg = ConfigManager.getRoleLevelExpCfg()
        local percent = 0
        local scaleBegin = 0
        local scaleEnd = 0
        local addExp = nBattleResultData.exp or 0
        if currentExp ~= nil and roleExpCfg ~= nil then
            if UserInfo.roleInfo.level >= ConfigManager.getLevelLimitCfg()[GameConfig.LevelLimitCfgKey.roleLevelLimit].level then
                percent = 1.0
                scaleBegin = percent
                scaleEnd = percent
            else
                local nextLevelExp = roleExpCfg[UserInfo.roleInfo.level]["exp"]
                percent = currentExp / nextLevelExp
                if percent >= 1 then
                    percent = 1.0
                end
                scaleEnd = percent
                if nBattleResult == 1 then
                    local beginExp = currentExp - addExp
                    if beginExp < 0 then
                        beginExp = 0
                        scaleBegin = 0
                    else
                        scaleBegin = beginExp / nextLevelExp
                    end
                else
                    scaleBegin = scaleEnd
                end
            end
            -- if percent >= 1 then
            -- scaleEnd = 1.0
            -- else
            -- scaleEnd = percent
            -- end
        end

        local expBarBg = CCSprite:create("Bar_WinRate.png")
        expBarBg:setAnchorPoint(ccp(0, 0.5))
        mExpBar:addChild(expBarBg)

        local sprite = CCSprite:create("Bar_WinRate_Top.png")
        local _ProgressTimerNode = CCProgressTimer:create(sprite)
        _ProgressTimerNode:setType(kCCProgressTimerTypeBar)
        _ProgressTimerNode:setMidpoint(CCPointMake(0, 0))
        _ProgressTimerNode:setBarChangeRate(CCPointMake(1, 0))
        _ProgressTimerNode:setAnchorPoint(ccp(0, 0.5))
        mExpBar:addChild(_ProgressTimerNode)
        -- 	if nBattleResult == 1 then
        -- 		local actionTo = CCProgressFromTo:create(0.8,scaleBegin*100,scaleEnd*100)
        -- 		_ProgressTimerNode:runAction(actionTo)
        -- 	else
        -- 		_ProgressTimerNode:setPercentage(scaleEnd*100)
        -- 	end

        _ProgressTimerNode:setPercentage(scaleEnd * 100)


    end
end

function HelpFightWinOrLosePopUp:onClose()
    if isTouchItem then
        isTouchItem = false
        return
    end
    pageManager.popPage(thisPageName)
    local title = common:getLanguageString("@Eighteentitle8")
    local msg = common:getLanguageString("@Eighteenbtncontent7")
    if nBattleResult == 1 then
        if HelpFightDataManager.LayerInfo.layerId == 18 then
            PageManager.changePage("HelpFightMapPage")
            PageManager.refreshPage("HelpFightMapPage","refresh");
            return
        end
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                --直接进入战斗界面
                --PageManager.popPage(thisPageName)
                PageManager.popPage("ViewBattlePage")
                HelpFightDataManager.LayerInfo = HelpFightDataManager.LayerInfo or {}
                HelpFightDataManager.LayerInfo.layerId = HelpFightDataManager.LayerInfo.layerId or 0
                HelpFightDataManager:sendEighteenPrincesChallengeReq(HelpFightDataManager.LayerInfo.layerId)
            else
                --pageManager.popPage(thisPageName)
                pageManager.changePage("HelpFightMapPage")
                PageManager.refreshPage("HelpFightMapPage","refresh");
            end
        end , true, "@Eighteenbtn7", "@Back", true,nil,true , function ()
                pageManager.changePage("HelpFightMapPage")
                PageManager.refreshPage("HelpFightMapPage","refresh");
             end , false);
    else
        --PageManager.popPage(thisPageName)
        PageManager.changePage("HelpFightMapPage")
        PageManager.refreshPage("HelpFightMapPage","refresh");
    end


end

function HelpFightWinOrLosePopUp:onDoubleReward()
    if isTouchItem then
        isTouchItem = false
        return
    end
    if UserInfo.playerInfo.gold < doubleRewardCost then
        MessageBoxPage:Msg_Box_Lan("@GoldNotEnough")
    else
        --发送协议
        local EighteenPrinces_pb = require("EighteenPrinces_pb")
        local msg = EighteenPrinces_pb.HPEighteenPrincesDoubleBuyReq()
        common:sendPacket(HP_pb.EIGHTEENPRINCES_HELP_DOUBLEBUY_C , msg ,false)
    end
    pageManager.popPage(thisPageName)
    local title = common:getLanguageString("@Eighteentitle8")
    local msg = common:getLanguageString("@Eighteenbtncontent7")
    if nBattleResult == 1 then
        if HelpFightDataManager.LayerInfo.layerId == 18 then
            PageManager.changePage("HelpFightMapPage")
            PageManager.refreshPage("HelpFightMapPage","refresh");
            return
        end
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                --直接进入战斗界面
                --PageManager.popPage(thisPageName)
                PageManager.popPage("ViewBattlePage")
                HelpFightDataManager.LayerInfo = HelpFightDataManager.LayerInfo or {}
                HelpFightDataManager.LayerInfo.layerId = HelpFightDataManager.LayerInfo.layerId or 0
                HelpFightDataManager:sendEighteenPrincesChallengeReq(HelpFightDataManager.LayerInfo.layerId)
            else
                --pageManager.popPage(thisPageName)
                pageManager.changePage("HelpFightMapPage")
                PageManager.refreshPage("HelpFightMapPage","refresh");
            end
        end , true, "@Eighteenbtn7", "@Back", true,nil,true , function ()
            pageManager.changePage("HelpFightMapPage")
            PageManager.refreshPage("HelpFightMapPage","refresh");
        end , false);
    else
        --PageManager.popPage(thisPageName)
        PageManager.changePage("HelpFightMapPage")
        PageManager.refreshPage("HelpFightMapPage","refresh");
    end
end

function HelpFightWinOrLosePopUp:onExit(container)
    HelpFightWinOrLosePopUp:resetData()
end


function HelpFightWinOrLosePopUp:createItem(index, itemsArr)
    local resInfo = itemsArr[index].info
    local itemNode = ScriptContentBase:create(ItemContentUI.ccbiFile, index)
    local nameStr = ""
    if itemsArr[index].type == Const_pb.SUIT_DRAWING then
        nameStr = ItemManager:getShowNameById(resInfo.itemId)
    else
        nameStr = resInfo.name
    end

    local lb2Str = {
        mName = nameStr,
        mNumber = "x" .. resInfo.count
    };
    NodeHelper:setStringForLabel(itemNode, lb2Str);
    NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = GameConfig.EquipmentIconScale });
    NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality });
    -- NodeHelper:setColor3BForLabel(itemNode, {mName = common:getColorFromConfig("Own")})
    NodeHelper:setColorForLabel(itemNode, { mName = "255 240 215" })

    local colorMap = { }

    colorMap.mName = ConfigManager.getQualityColor()[resInfo.quality].textColor
    -- colorMap.mNumber = ConfigManager.getQualityColor()[resInfo.quality].textColor
    colorMap.mNumber = "255 255 255"
    NodeHelper:setColorForLabel(itemNode, colorMap)

    itemNode:release()
    return itemNode
end

function HelpFightWinOrLosePopUp:onItemLeftArrow()
    nCurItemPage = nCurItemPage - 1
    if nCurItemPage == 1 then
        mRewardLeftArrow:setVisible(false)
    end
    mRewardRightArrow:setVisible(true)
    HelpFightWinOrLosePopUp:moveToPage(nCurItemPage, 5, mRewardItemScrollView, fItemDistence)
end

function HelpFightWinOrLosePopUp:onItemRightArrow()
    nCurItemPage = nCurItemPage + 1
    if nCurItemPage == nTotalItemPage then
        mRewardRightArrow:setVisible(false)
    end
    mRewardLeftArrow:setVisible(true)
    HelpFightWinOrLosePopUp:moveToPage(nCurItemPage, 5, mRewardItemScrollView, fItemDistence)
end

function HelpFightWinOrLosePopUp:onBoxLeftArrow()
    nCurBoxPage = nCurBoxPage - 1
    HelpFightWinOrLosePopUp:moveToPage(nCurBoxPage, 3, mOpenBoxScrollView, fBoxDistence)
end

function HelpFightWinOrLosePopUp:onBoxRightArrow()
    nCurBoxPage = nCurBoxPage + 1
    HelpFightWinOrLosePopUp:moveToPage(nCurBoxPage, 3, mOpenBoxScrollView, fBoxDistence)
end

function HelpFightWinOrLosePopUp:countPage(nLength, nPreRowCount)
    return math.ceil(nLength / nPreRowCount)
end

function HelpFightWinOrLosePopUp:moveToPage(nPage, nPreRowNum, mScorllView, fDistence)
    local array = CCArray:create();
    local newPosX = - mScorllView:getViewSize().width *(nPage - 1)
    array:addObject(CCDelayTime:create(0.1));
    array:addObject(CCMoveTo:create(0.2, ccp(newPosX, mScorllView:getContentOffset().y)))
    mScorllView:getContainer():stopAllActions()
    local seq = CCSequence:create(array);
    mScorllView:getContainer():runAction(seq)
end