----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb")
local Shop_pb = require("Shop_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local HP_pb = require("HP_pb")
local PageJumpMange = {
    _IsPageJump = false;-- 控制跳转二级页面
    _CurJumpCfgInfo = nil
}
PageJumpMange._JumpCfg = {
    [1] =
    {
        _Id = 1;-- 阵容界面（主角页签）
        _ToPage = "MainFrame_onLeaderPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },

    [2] =
    {
        _Id = 2;-- 关卡界面（普通关卡页签）
        _ToPage = "PageManager.changePage(\"MapControlPage\")",
        _SecondFunc = "onStage1",
        _ThirdFunc = "",
    },
    [3] =
    {
        _Id = 3;-- 佣兵训练界面
        _ToPage = "MainFrame_onEquipmentPageBtn()",
        _SecondFunc = "JumpToMercenary",
        _ThirdFunc = "",
    },
    [4] =
    {
        _Id = 4;-- 背包界面（道具页签）
        _ToPage = "MainFrame_onBackpackPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [5] =
    {
        _Id = 5;-- 技能专精界面
        _ToPage = "PageManager.changePage(\"SkillPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [6] =
    {
        _Id = 6;-- 神器吸收界面
        _ToPage = "MainFrame_onEquipmentPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [7] =
    {
        _Id = 7;-- 裝備鍛造
        _ToPage = "PageManager.pushPage(\"EquipIntegrationPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.FORGE,
    },
    [8] =
    {
        _Id = 8;-- 佣兵养成界面（即佣兵培养）
        _ToPage = "MainFrame_onEquipmentPageBtn()",
        _SecondFunc = "JumpToMercenary",
        _ThirdFunc = "",
    },
    [9] =
    {
        _Id = 9;-- 派遣
        _ToPage = "PageManager.pushPage(\"MercenaryExpeditionPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.BOUNTY,
    },
    [10] =
    {
        _Id = 10;-- 装备打造界面
        _ToPage = "PageManager.pushPage(\"MeltPage\")",
        _SecondFunc = "onBuild",
        _ThirdFunc = "",
    },
    [11] =
    {
        _Id = 11;-- 名声打造界面
        _ToPage = "PageManager.pushPage(\"MeltPage\")",
        _SecondFunc = "onSpecialBuild",
        _ThirdFunc = "",
    },
    [12] =
    {
        _Id = 12;-- 装备洗练界面
        _ToPage = "MainFrame_onEquipmentPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [13] =
    {
        _Id = 13;-- 神器融合界面
        _ToPage = "MainFrame_onEquipmentPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [14] =
    {
        _Id = 14;-- 神器传承界面
        _ToPage = "MainFrame_onEquipmentPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [15] =
    {
        _Id = 15;-- 公会主界面
        _ToPage = "MainFrame_onGuildPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [16] =
    {
        _Id = 16;-- 普通商店界面
        _ToPage = "PageManager.changePage(\"ShopControlPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.SHOP,
    },
    [17] =
    {
        _Id = 1;-- 套装碎片界面
        _ToPage = "MainFrame_onBackpackPageBtn()",
        _SecondFunc = "showSuits",
        _ThirdFunc = "",
    },
    [18] =
    {
        _Id = 18;-- 套装碎片界面（交换水晶窗口）
        _ToPage = "MainFrame_onBackpackPageBtn()",
        _SecondFunc = "showSuits",
        _ThirdFunc = "",
    },
    [19] =
    {
        _Id = 19;-- 修改签名窗口
        _ToPage = "PageManager.pushPage(\"PlayerInfoPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [20] =
    {
        _Id = 20;-- 聊天界面（世界聊天频道）
        _ToPage = "MainFrame_onChatBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [21] =
    {
        _Id = 21;-- 竞技场界面
        _ToPage = "MainFrame_onEquipmentPageBtn(true)",
        _SecondFunc = "onArena",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.ARENA,
    },
    [22] =
    {
        _Id = 22;-- 战斗界面
        _ToPage = "MainFrame_onBattlePageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [23] =
    {
        _Id = 23;-- 训练所
        _ToPage = "PageManager.changePage(\"MapControlPage\")",
        _SecondFunc = "onStage2",
        _ThirdFunc = "",
    },
    [24] =
    {
        _Id = 24;-- 充值界面
        _ToPage = "PageManager.pushPage(\"IAP.IAPPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [25] =
    {
        _Id = 25;-- 阵容界面（佣兵页签）
        _ToPage = "MainFrame_onEquipmentPageBtn()",
        _SecondFunc = "JumpToMercenary",
        _ThirdFunc = "",
    },
    [26] =
    {
        _Id = 26;-- 跳转到新活动界面（首冲页签）_SecondFunc_Param 来指定哪个活动页签
        _ToPage = "PageManager.pushPage(\"FirstChargePageNew\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [27] =
    {
        _Id = 27;-- 竞技场界面(荣誉兑换)
        _ToPage = "PageManager.changePage(\"ArenaPage\")",
        _SecondFunc = "showExchange",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.ARENA,
    },
    [28] =
    {
        _Id = 28;-- 跳转到新活动界面（月卡页签）_SecondFunc_Param 来指定哪个活动页签
        _ToPage = "PageManager.pushPage(\"WelfarePage\")",
        _SecondFunc = "changeToActivityPageById",
        _ThirdFunc = "",
        _SecondFunc_Param = Const_pb.MONTH_CARD,
    },
    [29] =
    {
        _Id = 29;-- 战场 关卡
        _ToPage = "BattlePageToMap()",
        _SecondFunc = "",
        _ThirdFunc = "",
        -- _SecondFunc_Param = nil,
    },
    [30] =
    {
        _Id = 30;-- 战场
        _ToPage = "MainFrame_onBattlePageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
        -- _SecondFunc_Param = nil,
    },
    [31] =
    {
        _Id = 31;-- 竞技  离线pvp
        _ToPage = "PVPActivityPage_onArena()",
        _SecondFunc = "",
        _ThirdFunc = "",
        -- _SecondFunc_Param = nil,
    },
    [32] =
    {
        _Id = 32;-- 竞技界面
        _ToPage = "PageManager.changePage(\"PVPActivityPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
        -- _SecondFunc_Param = nil,
    },
    [33] =
    {
        _Id = 33;-- 装备铸造
        _ToPage = "PageManager.changePage(\"EquipIntegrationPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
        -- _SecondFunc_Param = nil,
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.FORGE,
    },
    [99] =
    {
        -- 此类型弹出MessageBoxPage:Msg_Box_Lan
        _Id = 25;-- 阵容界面（佣兵页签）
        _ToPage = "",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [34] =
    {
        _Id = 34;--
        _ToPage = "PageManager.changePage(\"EquipIntegrationPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.FORGE,
    },
    [35] =
    {
        _Id = 35;-- 快速戰鬥
        _ToPage = "MainFrame_onBattlePageBtn()",
        _SecondFunc = "onExpress",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.FAST_BATTLE,
    },
    [36] =
    {
        _Id = 36;-- 英雄召喚
        _ToPage = "PageManager.pushPage(\"Summon.SummonPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.SUMMON,
    },
    [37] =
    {
        _Id = 37;-- 限定活动 兑换所
        _ToPage = "",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [38] =
    {
        _Id = 38;-- 十八路诸侯
        _ToPage = "PageManager.changePage(\"HelpFightMapPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [39] =
    {
        _Id = 39;-- 活跃赏金
        _ToPage = "PageManager.pushPage(\"LivenessPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [40] =
    {
        _Id = 40;-- 新手连续充值
        _ToPage = "",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [41] =
    {
        _Id = 41;-- 七日
        _ToPage = "PageManager.changePage(\"HelpFightMapPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [42] =
    {
        _Id = 42; -- 好友
        _ToPage = "PageManager.pushPage(\"FriendPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [43] =
    {
        _Id = 43; -- 點金
        _ToPage = "PageManager.pushPage(\"MoneyCollectionPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [44] =
    {
        _Id = 44; -- 符文合成
        _ToPage = "PageManager.pushPage(\"EquipIntegrationPage\")",
        _SecondFunc = "",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.RUNE_BUILD,
    },
    [45] =
    {
        _Id = 45;-- 世界boss
        _ToPage = "MainFrame_onEquipmentPageBtn(true)",
        _SecondFunc = "onWorldBoss",
        _ThirdFunc = "",
    },
    [46] =
    {
        _Id = 46;-- 大廳
        _ToPage = "MainFrame_onMainPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [47] =
    {
        _Id = 47;-- 大廳2
        _ToPage = "MainFrame_onEquipmentPageBtn()",
        _SecondFunc = "",
        _ThirdFunc = "",
    },
    [48] =
    {
        _Id = 48;-- 地下城
        _ToPage = "MainFrame_onEquipmentPageBtn(true)",
        _SecondFunc = "onBounty",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.DUNGEON,
    },
    [49] =
    {
        _Id = 49;-- 屬性地下城
        _ToPage = "MainFrame_onEquipmentPageBtn(true)",
        _SecondFunc = "onEvent",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.DUNGEON,
    },
    [50] =
    {
        _Id = 50;-- 競技場
        _ToPage = "MainFrame_onEquipmentPageBtn(true)",
        _SecondFunc = "onArena",
        _ThirdFunc = "",
        _Lock_Key = GameConfig.LOCK_PAGE_KEY.ARENA,
    },
    [51] =
    {
        _Id = 51;-- CycleTower
        _ToPage = "MainFrame_onMainPageBtn(true,true)",
        _SecondFunc = "onActivity",
        _ThirdFunc = "onBattle",
    },
    [52] =
    {
        _Id = 52;-- SingleBoss
        _ToPage = "MainFrame_onMainPageBtn(true,true)",
        _SecondFunc = "onSingleBoss",
        _act = Const_pb.ACTIVITY193_SingleBoss
    },
    [53] =
    {
        _Id = 53;-- Season_Tower 
        _ToPage = "MainFrame_onEquipmentPageBtn(true)",
        _SecondFunc = "onTower",
        _act = Const_pb.ACTIVITY194_SeasonTower
    },
}

function PageJumpMange.JumpPageById(id)
    if PageJumpMange._JumpCfg[id]._Lock_Key then
        require("Util.LockManager")
        if LockManager_getShowLockByPageName(PageJumpMange._JumpCfg[id]._Lock_Key) then
            MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(PageJumpMange._JumpCfg[id]._Lock_Key))
            return
        end
    end
    if PageJumpMange._JumpCfg[id]._act then
        require("Activity.ActivityInfo")
        if not ActivityInfo:getActivityIsOpenById(PageJumpMange._JumpCfg[id]._act) then
            MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_80104"))
            return
        end
    end
    if id == 24 then
        require("IAP.IAPPage"):setEntrySubPage("Diamond")
    end
    if id == 34 then
        PageJumpMange._IsPageJump = false
        registerScriptPage("EquipIntegrationPage")
        EquipIntegrationPage_CloseHandler(MainFrame_onMainPageBtn())
        EquipIntegrationPage_SetCurrentPageIndex(true)
        PageManager.changePage("EquipIntegrationPage")
        return
    end
    if id == 37 then
        PageJumpMange._IsPageJump = false
        require("LimitActivityPage")
        LimitActivityPage_setPart(136)
        LimitActivityPage_setCurrentPageType(1)
        LimitActivityPage_setIds(ActivityInfo.LimitPageIds)
        LimitActivityPage_setTitleStr("@FixedTimeActTitle")
        PageManager.changePage("LimitActivityPage")
        return
    end
    if id == 40 then
        PageJumpMange._IsPageJump = false
        ActivityInfo.jumpToActivityById(3)
        return
    end
    if id == 44 then    -- 符文合成
        require("EquipIntegrationPage")
        EquipIntegrationPage_SetCurrentPageIndex(1)
    end
    if id == 52 then    -- 單人強敵
        local SingleBossDataMgr = require("SingleBoss.SingleBossDataMgr")
        local data = SingleBossDataMgr:getPageData()
        data.dataDirtyBase = true
    end
    PageJumpMange._CurJumpCfgInfo = PageJumpMange._JumpCfg[id];
    if PageJumpMange._CurJumpCfgInfo == nil then return end
    PageJumpMange._IsPageJump = true
    if PageJumpMange._CurJumpCfgInfo._SecondFunc == "" then
        PageJumpMange._IsPageJump = false
    end
    local call_function = loadstring(PageJumpMange._CurJumpCfgInfo._ToPage)
    call_function()
end
----------packet msg--------------------------
return PageJumpMange
