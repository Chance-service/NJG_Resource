local PageManager = { };
--------------------------------------------------------------
local confirmPageName = "DecisionPage";
--------------------------------------------------------------
local UserInfo = require("PlayerInfo.UserInfo");

local prePageName = "";

PageManager.changePage = function(pageName, popAll)
    local currPage = MainFrame:getInstance():getCurShowPageName();
    prePageName = currPage
    local msg = MsgMainFrameChangePage:new()
    registerScriptPage(pageName)
    msg.pageName = pageName
    msg.needPopAllPage = popAll == nil and true or popAll
    MessageManager:getInstance():sendMessageForScript(msg)
end

PageManager.changePrePage = function(popAll)
    if prePageName ~= "" then
        local msg = MsgMainFrameChangePage:new()
        registerScriptPage(prePageName)
        msg.pageName = prePageName
        msg.needPopAllPage = popAll == nil and true or popAll
        MessageManager:getInstance():sendMessageForScript(msg)
    end
end

PageManager.pushPage = function(pageName, noCheck)
    local msg = MsgMainFramePushPage:new()
    if noCheck == nil or noCheck == false then
        registerScriptPage(pageName)
    end
    msg.pageName = pageName
    MessageManager:getInstance():sendMessageForScript(msg)
end

PageManager.showFightPage = function(pageName)
    MainFrame:getInstance():showFightPage();
end

PageManager.popPage = function(pageName)
    local msg = MsgMainFramePopPage:new()
    msg.pageName = pageName
    MessageManager:getInstance():sendMessageForScript(msg)
end

PageManager.popAllPage = function()
    MainFrame:getInstance():popAllPage()
end

PageManager.refreshPage = function(pageName, extraParam)
    local msg = MsgMainFrameRefreshPage:new()
    msg.pageName = pageName
    msg.extraParam = extraParam == nil and "" or extraParam
    MessageManager:getInstance():sendMessageForScript(msg)
end

PageManager.viewBattlePage = function(battleData, name1, name2, addi1, addi2)
end

PageManager.viewAllianceTeamInfo = function(allianceId)
    if allianceId == nil or allianceId == 0 then return end
    local ABTeamInfoManager = require("Guild.ABTeamInfoManager")
    ABTeamInfoManager:sendPacketByAllianceId(allianceId)
end

PageManager.showCover = function(pageName)
    local msg = MsgMainFrameCoverShow:new()
    registerScriptPage(pageName)
    msg.pageName = pageName
    MessageManager:getInstance():sendMessageForScript(msg)
end

PageManager.hideCover = function(pageName)
    local msg = MsgMainFrameCoverHide:new()
    msg.pageName = pageName
    MessageManager:getInstance():sendMessageForScript(msg)
end

PageManager.removeAdventure = function(advenIndex)
    if advenIndex == nil then return end
    local msg = MsgAdventureRemoveItem:new()
    msg.index = tonumber(advenIndex)
    MessageManager:getInstance():sendMessageForScript(msg)
end

PageManager.showNotice = function(title, message, callBack, autoClose, canClose, ScaleX)
    ScaleX = ScaleX or 1
    RegisterLuaPage(confirmPageName);
    DecisionPage_setDecision(title, message, callBack, autoClose, yes, no, autoClose, canClose, ScaleX);
    PageManager.pushPage(confirmPageName);
    -- RegisterLuaPage("NoticePage");
    -- NoticePage_setNotice(title, message,callBack,autoClose);
    -- PageManager.pushPage("NoticePage");
end

-- @param autoClose: has default value [true]
PageManager.showConfirm = function(title, message, callback, autoClose, yes, no, showclose, ScaleX,isCanClose , closeCallback , IsClickBlankClose,isFlip,isBuyQues)
    ScaleX = ScaleX or 1
    if isFlip then confirmPageName="DecisionPage_Horizontal" else confirmPageName="DecisionPage" end
    RegisterLuaPage(confirmPageName);
    local _showclose = false
    if showclose == nil then
        _showclose = true
    else
        _showclose= showclose
    end
    if isCanClose == nil then
        isCanClose = true
    end
    if isBuyQues == nil  then
        isBuyQues = false
    end
    if isFlip then
        DecisionPage_Horizontal_setDecision(title, message, callback, autoClose, yes, no, _showclose, isCanClose, ScaleX , closeCallback , IsClickBlankClose)
    else
        DecisionPage_setDecision(title, message, callback, autoClose, yes, no, _showclose, isCanClose, ScaleX , closeCallback , IsClickBlankClose , isBuyQues)
    end
    PageManager.pushPage(confirmPageName);
    confirmPageName = "DecisionPage" -- 回復預設值 避免其他function開啟時是橫版ui
end


PageManager.showComment = function(isTenLuckDraw)
    if not GameConfig.isShoComment then
        -- 不开启评论
        return
    end

    if GameConfig.isIOSAuditVersion then
        -- ios审核
        return
    end

    if Golb_Platform_Info.is_amz then
        -- 亚马逊
        return
    end

    -- 關閉評論視窗
    --[[
    local UserInfo = require("PlayerInfo.UserInfo")
    local isPop = false
    if UserInfo.getIsComment() then
        return
    end
    if isTenLuckDraw ~= nil and isTenLuckDraw then
        isPop = not UserInfo.getIsCommentForTenLuckDraw()
        if isPop then
            UserInfo.setIsCommentForTenLuckDraw(true)
        end
    else
        isPop = not UserInfo.getIsComment()
    end

    if isPop then
        -- 评论
        RegisterLuaPage("GoCommentPage")
        GoCommentPage_setComment()
        PageManager.pushPage("GoCommentPage")
    end]]
end


PageManager.showCommentPage = function(allrewardsStr)
    --[[if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
        -- return
    end
    RegisterLuaPage("GoCommentPage");
    local lastDate = tonumber(CCUserDefault:sharedUserDefault():getStringForKey("GoCommentTime"))
    -- 时间戳
    local tabTime = os.date("*t")
    local time = tonumber(os.time(tabTime));
    -- 当前的时间戳
    if lastDate ~= nil then
        if time - lastDate >= 60 * 60 * 24 * 3 then
            local isReward = GoCommentPage_setDecision(allrewardsStr);
            if isReward then
                PageManager.pushPage("GoCommentPage");
            end
        end
    else
        local isReward = GoCommentPage_setDecision(allrewardsStr);
        if isReward then
            PageManager.pushPage("GoCommentPage");
        end
    end]]--
end

PageManager.showConfirmMoreLine = function(title, message, callback, autoClose)
    local confirmPageName = "DecisionMoreLinePage"
    RegisterLuaPage(confirmPageName);
    DecisionMoreLinePage_setDecision(title, message, callback, autoClose);
    PageManager.pushPage(confirmPageName);
end

PageManager.showHtmlConfirm = function(title, message, callback, autoClose,scaleX)
    RegisterLuaPage(confirmPageName);
    local isshowclose = true
    DecisionPage_setHtmlDecision(title, message, callback, autoClose, isshowclose,scaleX);
    PageManager.pushPage(confirmPageName);
end

PageManager.closeConfirmPage = function()
    PageManager.popPage(confirmPageName);
end

PageManager.confirmUseItem = function(title, message, itemId)
    -- RegisterLuaPage("ConfirmUseItemPage");
    -- local callback = function(isSure)
    -- 	if isSure then
    -- 		local ItemOprHelper = require("Item.ItemOprHelper");
    -- 		ItemOprHelper:useItem(itemId);
    -- 	end
    -- end;
    -- ConfirmUseItemPage_setDecision(title, message , callback);
    -- PageManager.pushPage("ConfirmUseItemPage");

    local callback = function(isSure)
        if isSure then
            local ItemOprHelper = require("Item.ItemOprHelper");
            ItemOprHelper:useItem(itemId);
        end
    end;
    RegisterLuaPage(confirmPageName);
    DecisionPage_setDecision(title, message, callback, autoClose, "@Use", no, true);
    PageManager.pushPage(confirmPageName);
end

-- show info of equip from user self
PageManager.showEquipInfo = function(equipId, roleId, isShowExchangePoint)
    RegisterLuaPage("EquipInfoPage");
    EquipInfoPage_setEquipId(equipId, roleId, isShowExchangePoint);
    PageManager.pushPage("EquipInfoPage");
end

PageManager.viewPlayerInfo = function(playerId, flagShowButton, flagKakaoFriend, playerName)
    RegisterLuaPage("ViewPlayMenuPage")
    ViewPlayMenuPageBase_setPlayerId(playerId, flagShowButton, flagKakaoFriend, playerName);
    ViewPlayerInfo:getInfo(playerId, playerName);
    -- RegisterLuaPage("ViewPlayerInfoPage")
    -- ViewPlayerInfoPage_setPlayerId(playerId, flagShowButton,flagKakaoFriend,playerName);
    -- ViewPlayerInfo:getInfo(playerId,playerName);
end

PageManager.viewCSPlayerInfo = function(playerInfo, flagShowButton, playerId)
    RegisterLuaPage("ViewPlayerInfoPage")
    ViewPlayerInfoPage_setPlayerId(playerId, flagShowButton);
    ViewPlayerInfo:setCSInfo(playerInfo)
    PageManager.pushPage("ViewPlayerInfoPage")
end

PageManager.viewMercenaryInfo = function(playerId, mercenaryId)
    RegisterLuaPage("ViewMercenaryInfoPage")
    local ViewMercenaryInfo = require("Mercenary.ViewMercenaryInfo")
    ViewMercenaryInfo:getInfo(playerId, mercenaryId)
end

-- show info of equip from other user
PageManager.viewEquipInfo = function(equipId, isMercenary)
    RegisterLuaPage("EquipInfoPage");
    EquipInfoPage_viewEquipId(equipId, isMercenary);
    PageManager.pushPage("EquipInfoPage");
end

PageManager.showItemInfo = function(userItemID, options)
    -- 原本是: ItemInfoPage
    RegisterLuaPage("CommPop.CommItemInfoPage");
    local page = require("CommPop.CommItemInfoPage")
    local const = require("CommPop.CommItemInfoConst")
    if options == nil then options = {} end
    if options.userItemID == nil then
        options.userItemID = userItemID
    end
    options.preset = const.Preset.AUTO_ITEMTYPE
    page:prepare(options)
    PageManager.pushPage("CommPop.CommItemInfoPage");
end

PageManager.showGemInfo = function(itemId)
    RegisterLuaPage("GemInfoPage");
    GemInfoPage_setItemId(itemId);
    PageManager.pushPage("GemInfoPage");
end


PageManager.showResInfo = function(itemType, itemId, itemCount)
    local mainType = ResManagerForLua:getResMainType(itemType);
    local Const_pb = require("Const_pb");
    local ItemManager = require("Item.ItemManager");
    if mainType == Const_pb.TOOL and ItemManager:getContainCfg(itemId) then
        PageManager.showGiftPackage(itemId);
        return;
    end
    RegisterLuaPage("ResInfoPage");
    ResInfoPage_setItemInfo(itemType, itemId, itemCount);
    PageManager.pushPage("ResInfoPage");
end

PageManager.showGiftPackage = function(itemId, callback)
    local ItemManager = require("Item.ItemManager");
    local cfg = ItemManager:getContainCfg(itemId);
    if cfg ~= nil and #cfg > 0 then
        RegisterLuaPage("ResListPage");
        ResListPage_setList(cfg, callback);
        PageManager.pushPage("ResListPage");
    end
end

PageManager.showHelp = function(key, title, flag, content)
    if not key then
        return
    end
    if flag then
        RegisterLuaPage("HelpPageSpecial")
        Help_SetHelpConfigSpecial(key, title)
        PageManager.pushPage("HelpPageSpecial")
    else
        RegisterLuaPage("HelpPage")
        Help_SetHelpConfig(key, title, content)
        PageManager.pushPage("HelpPage")
    end

end

-- »î¶¯Ìø×ª
PageManager.showActivity = function(id)
    ActivityPage_goActivity(id);
end

-- ÌáÊ¾È±ÉÙ½ð±Ò
PageManager.notifyLackCoin = function()
    local title = common:getLanguageString("@HintTitle");
    local msg = common:getLanguageString("@LackCoin");
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            -- 		local ShopDataManager = require("ShopDataManager")
            -- 		 ShopDataManager.setCurrentShopIndex(ShopDataManager._shopType.STATE_COINS)
            --             PageManager.changePage("ShopControlPage")
            -- 		PageManager.popPage(confirmPageName);

            PageManager.changePage("ShopControlPage")
            local message = MsgMainFrameGetNewInfo:new()
            message.type = GameConfig.ShopEventType.JumpSubPage_2
            MessageManager:getInstance():sendMessageForScript(message)

        end
    end , false);
end

-- ÌáÊ¾È±ÉÙ×êÊ¯
PageManager.notifyLackGold = function(event)
    local title = common:getLanguageString("@HintTitle");
    local msg = common:getLanguageString("@LackGold");
    MessageBoxPage:Msg_Box_Lan("@GoldNotEnough")
   -- PageManager.showConfirm(title, msg, function(isSure)
   --     if isSure then
   --         --RegisterLuaPage("RechargePage");
   --         --RechargePage_showPage();
   --         if event ~= nil then
   --             libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", event)
   --         end
   --         --PageManager.popPage(confirmPageName);
   --     end
   -- end , false);
end

--- vip等级不足
PageManager.notifyLackVIP = function(event)
    local title = common:getLanguageString("@HintTitle");
    local msg = common:getLanguageString("@LackVip");
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            RegisterLuaPage("RechargePage");
            RechargePage_showPage();
            if event ~= nil then
                libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", event)
            end
            PageManager.popPage(confirmPageName);
        end
    end , false);
end
-------------------------------------------------------------
local redNoticeCache = {
    Package = false,
    Equipment = false,
    -- Mercenary 	= false,
    Skill = false
};
local key2Node = {
    Package = "mBackpackPagePoint",
    Leader = "mLeaderPagePoint",
    Battle = "mBattlePagePoint",
    Equipment = "mEquipmentPagePoint",
    Mercenary = "mEquipmentPagePoint",
    Skill = "mSkillPagePoint",
    Guild = "mGuildPagePoint",
};

PageManager.showRedNotice = function(key, visible)
    --local nodeName = key2Node[key];
    --if nodeName then
    --    if key == "Equipment" then
    --        MainFrame:getInstance():setChildVisible(nodeName, visible);
    --        redNoticeCache["Equipment"] = visible;
    --    elseif key == "Mercenary" then
    --    elseif key == "Skill" then
    --        MainFrame:getInstance():setChildVisible(nodeName, visible);
    --        if UserInfo.skillUnlock.hasNew then
    --            local key = string.format("Skill_%d_%d_%d", UserInfo.serverId, UserInfo.playerInfo.playerId, UserInfo.skillUnlock.level);
    --            CCUserDefault:sharedUserDefault():setBoolForKey(key, true);
    --            CCUserDefault:sharedUserDefault():flush();
    --            UserInfo.skillUnlock.hasNew = false;
    --        end
    --        redNoticeCache[key] = visible;
    --    --elseif key == "Package" then
    --    --    MainFrame:getInstance():setChildVisible(nodeName, visible);
    --    --    redNoticeCache[key] = visible;
    --
    --    elseif key == "Guild" then
    --
    --    elseif key == "Leader" then
    --        MainFrame:getInstance():setChildVisible(nodeName, visible);
    --        redNoticeCache[key] = visible;
    --    elseif key == "Battle" then
    --        MainFrame:getInstance():setChildVisible(nodeName, visible);
    --        redNoticeCache[key] = visible;
    --    end
    --end
end

PageManager.refreshRedNotice = function()
    for key, visible in pairs(redNoticeCache) do
        MainFrame:getInstance():setChildVisible(key2Node[key], visible);
    end
end

-- 显示MainFrameBottom中装备红点
PageManager.setAllNotice = function()
end

--显示MainFrameBottom中佣兵红点
local DelayHandler = nil
PageManager.setAllMercenaryNotice = function()
    if DelayHandler == nil then
        DelayHandler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function(dt)
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(DelayHandler)
            DelayHandler = nil
            if UserEquipManager:getEquipNoticeCounts() > 0 then
                --显示MainFrameBottom中佣兵红点
                PageManager.showRedNotice("Equipment", true);
                PageManager.refreshPage("EquipMercenaryPage","Equip_RedPoint");
            else
                --取消MainFrameBottom中佣兵红点
                PageManager.showRedNotice("Equipment", false);
                PageManager.refreshPage("EquipMercenaryPage","Equip_RedPoint");
            end
        end, 0.5, false)
    end
end

PageManager.showCoinNotEnough = function(title, message)
    -- RegisterLuaPage("ConfirmUseItemPage");
    -- local callback = function(isSure)
    -- 	if isSure then
    -- 		local ItemOprHelper = require("Item.ItemOprHelper");
    -- 		ItemOprHelper:useItem(itemId);
    -- 	end
    -- end;
    -- ConfirmUseItemPage_setDecision(title, message , callback);
    -- PageManager.pushPage("ConfirmUseItemPage");
    local callback = function(isSure)
        if isSure then
            local ItemOprHelper = require("Item.ItemOprHelper");
            ItemOprHelper:useItem(itemId);
        end
    end;
    RegisterLuaPage(confirmPageName);
    DecisionPage_setDecision(title, message, callback, autoClose, "@Use", no, true);
    PageManager.pushPage(confirmPageName);
end

PageManager.showCountTimesArenaPage = function(title, message, max, priceFunc, priceType, callback, auto, aIsExchangeGoldBean, _maxTxt, offset)
    require("CountTimesArenaPage")
    if max <= 0 then
        if aIsExchangeGoldBean then
            MessageBoxPage:Msg_Box_Lan("@YaYaShopCountLimit")
        else
            MessageBoxPage:Msg_Box_Lan("@ShopCountLimit")
        end
        return
    end
    CountTimesArenaPage_show(title, message, max, priceFunc, priceType, callback, auto, aIsExchangeGoldBean, _maxTxt, offset)
end

PageManager.showCountTimesPage = function(title, message, max, priceFunc, priceType, callback, auto, aIsExchangeGoldBean, _maxTxt, offset)
    require("CountTimesPage")
    if max <= 0 then
        if aIsExchangeGoldBean then
            MessageBoxPage:Msg_Box_Lan("@YaYaShopCountLimit")
        else
            MessageBoxPage:Msg_Box_Lan("@ShopCountLimit")
        end
        return
    end
    CountTimesPage_show(title, message, max, priceFunc, priceType, callback, auto, aIsExchangeGoldBean, _maxTxt, offset)
end

PageManager.showCommonCountTimesPage = function(title, message, max, priceFunc, priceType, callback, auto, aIsExchangeGoldBean, _maxTxt, multiple, isShow)
    require("CommonCountTimesPage")
    if max <= 0 then
        if aIsExchangeGoldBean then
            MessageBoxPage:Msg_Box_Lan("@YaYaShopCountLimit")
        else
            MessageBoxPage:Msg_Box_Lan("@ShopCountLimit")
        end
        return
    end
    CommonCountTimesPage_show(title, message, max, priceFunc, priceType, callback, auto, aIsExchangeGoldBean, _maxTxt, multiple, isShow)
end

PageManager.showCountTimesWithIconPage = function(type, id, currencyType, priceFunc, callback, auto, max, title, notEnoughStr, totalRes, desc)
    require("CountTimesWithIconPage")
    CountTimesWithIconPage_show(type, id, currencyType, priceFunc, callback, auto, max, title, notEnoughStr, totalRes, desc)
end
PageManager.isJumpTo = { }

PageManager.setJumpTo = function(pageName, param)
    if param then
        PageManager.isJumpTo[pageName] = param
    else
        PageManager.isJumpTo[pageName] = true
    end
end
PageManager.getJumpTo = function(pageName)
    return PageManager.isJumpTo[pageName]
end
PageManager.clearJumpTo = function(pageName)
    if PageManager.isJumpTo[pageName] then
        PageManager.isJumpTo[pageName] = false
        PageManager.isJumpTo[pageName] = nil
    end
end

local isInBattlePage = false
PageManager.setIsInBattlePage = function(isIn)
    isInBattlePage = isIn
end
PageManager.getIsInBattlePage = function()
    return isInBattlePage
end

local isInSummonPage = false
PageManager.setIsInSummonPage = function(isIn)
    isInSummonPage = isIn
end
PageManager.getIsInSummonPage = function()
    return isInSummonPage
end

local isInPopSalePage = false
PageManager.setIsInPopSalePage = function(isIn)
    isInPopSalePage = isIn
end
PageManager.getIsInPopSalePage = function()
    return isInPopSalePage
end

local isInGirlDiaryPage = false
PageManager.setIsInGirlDiaryPage = function(isIn)
    isInGirlDiaryPage = isIn
end
PageManager.getIsInGirlDiaryPage = function()
    return isInGirlDiaryPage
end

local isInLevelUpPage = false
PageManager.setIsInLevelUpPage = function(isIn)
    isInLevelUpPage = isIn
end
PageManager.getIsInLevelUpPage = function()
    return isInLevelUpPage
end

PageManager.BuyActivityItem = function(ActivityId,itemId,itemType,table)
    local _type=30000
    if itemType then
        _type=itemType
    end
    require("BuyActivityItemPage")
    BuyActivityItemBase_setData(ActivityId,itemId,_type,table)
    PageManager.pushPage("BuyActivityItemPage")
end
--------------------------------------------------------------

return PageManager;