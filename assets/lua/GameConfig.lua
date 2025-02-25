GameConfig = {
    -- 从背包跳转到私装界面
    FatePackageJumpFlag = "FateFindPageFlag",
    -- 高速战斗券每天使用最大数量
    FastFightingTicketMaxCount = 5,
    -- 高速战斗券ID,
    BackpackFightTicket = { 103101, 103102, 103103, 103104, 103105 },
    -- 宝石一键合成限制等级
    GemCompoundLevelLimit = 10,
    -- 快速融合等级限制
    FastMeltLevelLimit = 1,
    -- 副将碎片
    MercenaryTypeId = 70000,
    -- 背景图路径
    BGPath = {
        Battle = { [1] = "BG/Battle/battle_bg_01.png", [2] = "BG/Battle/battle_bg_02.png", [3] = "BG/Battle/battle_bg_01.png" },
        Main = { [1] = "BG/Main/main_bg_01.png", [2] = "BG/Main/main_bg_02.png", [3] = "BG/Main/main_bg_03.png" },
        DayLogin30 = { [1] = "BG/DayLogin30/DayLogin30.png" },
        DayLogin7 = { [1] = "BG/DayLogin7/DayLogin7.png" },
        Role = { [1] = "BG/Role/role_bg_01.png", [2] = "BG/Role/role_bg_02.png", [3] = "BG/Role/role_bg_03.png" }
    },
    ShopEventType = {
        JumpSubPage_1 = 1,
        JumpSubPage_2 = 2,
        JumpSubPage_3 = 3,
    },
    LevelLimitCfgKey = {
        -- 人物等级上限
        roleLevelLimit = "roleLevelLimit",
        -- 装备强化等级上限
        equipStrengthLimit = "equipStrengthLimit",
        -- 养成所等级上限
        starSoulLevelLimit = "starSoulLevelLimit"
    },
    server = {
        serverIp = "47.74.7.86",
        serverPort = 1001,
        buyPort = 5132,
    },
    NowSelctActivityId = 0,
    FBAskObjectId = "698777460251953",
    ProfessionIcon = {
        [1] = "UI/Program/common_ht_IcoWarrior.png",
        [2] = "UI/Program/common_ht_IcoHunter.png",
        [3] = "UI/Program/common_ht_IcoMaster.png",
        [1001] = "UI/Program/common_ht_IcoWarrior.png",
        [1002] = "UI/Program/common_ht_IcoHunter.png",
        [1003] = "UI/Program/common_ht_IcoMaster.png"
    },
    ArenaRankingIcon = {
        -- 竞技场排名图片   前三名用123  从第四名开始用4
        [1] = "Rank_bg_1.png",
        [2] = "Rank_bg_2.png",
        [3] = "Rank_bg_3.png",
        [4] = "Rank_bg_4.png",
    },
    ActivityRoleQualityImage = {
        [3] = "Activity_common_R.png",
        [4] = "Activity_common_SR.png",
        [5] = "Activity_common_SSR.png",
        [6] = "Activity_common_UR.png",
    },
    QualityImage = {
        [1] = "Common_UI02/common_ht_propK_bai.png",
        -- white
        [2] = "Common_UI02/common_ht_propK_green.png",
        -- green
        [3] = "Common_UI02/common_ht_propK_blue.png",
        -- blue
        [4] = "Common_UI02/common_ht_propK_purple.png",
        -- purple
        [5] = "Common_UI02/common_ht_propK_orange.png",
        -- orange
        [6] = "Common_UI02/common_ht_propK_red.png",
        -- red
        [7] = "Common_UI02/common_ht_propK_R.png",
        -- suit R
        [8] = "Common_UI02/common_ht_propK_SR.png",
        -- suit SR
        [9] = "Common_UI02/common_ht_propK_SSR.png",
        -- suit SSR
        [10] = "Common_UI02/common_ht_propK_UR.png",
        -- suit UR
        [11] = "Common_UI02/common_ht_suit_R.png",
        -- suit R Frag
        [12] = "Common_UI02/common_ht_suit_SR.png",
        -- suit SR Frag
        [13] = "Common_UI02/common_ht_suit_SSR.png",
        -- suit SSR Frag
        [14] = "Common_UI02/common_ht_suit_UR.png",
        -- suit UR  Frag
        [15] = "Common_UI02/common_ht_mercenary_R.png",
        -- 蓝色佣兵碎片
        [16] = "Common_UI02/common_ht_mercenary_SR.png",
        -- 紫色佣兵碎片
        [17] = "Common_UI02/common_ht_mercenary_SSR.png",
        -- 橙色佣兵碎片
        [18] = "Common_UI02/common_ht_mercenary_UR.png",
        -- 红色佣兵碎片
        [19] = "Common_UI02/Image_ItemFrame_19.png",
        -- 蓝色佣兵框
        [20] = "Common_UI02/Image_ItemFrame_20.png",
        -- 紫色佣兵框
        [21] = "UI/Common/Image/Image_ItemFrame_21.png",
        -- 橙色佣兵框
        [22] = "UI/Common/Image/Image_ItemFrame_22.png",
        -- 红色佣兵框
    },
    QualityImageTxt = {
        [4] = "Resource/Imagesetfile/Common_UI02/Hero_card_SR_2.png",
        -- purple
        [5] = "Resource/Imagesetfile/Common_UI02/Hero_card_SSR_2.png",
        -- orange
        [6] = "Resource/Imagesetfile/Common_UI02/Hero_card_UR_2.png",
        -- red
    },
    QualityImageFrame = {
        [1] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_bai.png",
        -- white
        [2] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_green.png",
        -- green
        [3] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_blue.png",
        -- blue
        [4] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_purple.png",
        -- purple
        [5] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_orange.png",
        -- orange
        [6] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_red.png",
        -- red

        [7] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_orange.png",
        [8] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_orange.png",
        [9] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_red.png",
        [10] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_red.png",
        [11] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_orange.png",
        [12] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_orange.png",
        [13] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_red.png",
        [14] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_red.png",
        [15] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_blue.png",
        [16] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_purple.png",
        [17] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_orange.png",
        [18] = "Resource/Imagesetfile/Common_UI02/common_ht_propK_red.png",
    },
    QualityImageBG = {
        [1] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade1.png",
        -- white
        [2] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade2.png",
        -- green
        [3] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade3.png",
        -- blue
        [4] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade4.png",
        -- purple
        [5] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade5.png",
        -- orange
        [6] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade6.png",
        -- red

        [7] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade5.png",
        [8] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade5.png",
        [9] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade6.png",
        [10] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade6.png",
        [11] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade5.png",
        [12] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade5.png",
        [13] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade6.png",
        [14] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade6.png",
        [15] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade3.png",
        [16] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade4.png",
        [17] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade5.png",
        [18] = "Resource/Imagesetfile/Common_UI02/common_ht_ItemFrameShade6.png",
    },
    --    MercenaryQualityImage =
    --    {
    --        [3] = "GroupPage/mercenary_frame_R.png",
    --        -- white
    --        [4] = "GroupPage/mercenary_frame_SR.png",
    --        -- green
    --        [5] = "GroupPage/mercenary_frame_SSR.png",
    --        -- blue
    --        [6] = "GroupPage/mercenary_frame_UR.png",-- red
    --    },
    ExpeditionLevel={
        [1]="Bounty_Level1.png",
        [2]="Bounty_Level2.png",
        [3]="Bounty_Level3.png",
        [4]="Bounty_Level4.png",
        [5]="Bounty_Level5.png",
        [6]="Bounty_Level6.png",
    },
    MercenaryQualityImage = {
        [1] = "common_ht_propK_bai.png",
        [2] = "common_ht_propK_green.png",
        [3] = "common_ht_propK_blue.png",
        -- white
        [4] = "common_ht_propK_purple.png",
        -- green
        [5] = "common_ht_propK_orange.png",
        -- blue
        [6] = "common_ht_propK_red.png",-- red
    },
    MercenaryBloodId = {
        ["ROYAL"] = 1,
        ["NOBEL"] = 2,
        ["COMMONER"] = 3,
    },
    MercenaryBloodFrame = {
        "mercenary_royal.png",
        "mercenary_noble.png",
        "mercenary_commoner.png",
    },
    MercenaryRarityFrame = {
        [4] = "Hero_card_SR.png",
        [5] = "Hero_card_SSR.png",
        [6] = "Hero_card_UR.png",
    },
    MercenaryClass = 
    {
        TANK = 1, WARRIOR = 2, HEALER = 3,  MAGE = 4,
    },
    MercenaryClassImg = {
        [0] = "jobicon_common.png",
        [1] = "Occupation_1.png",
        [2] = "Occupation_2.png",
        [3] = "Occupation_3.png",
        [4] = "Occupation_4.png",
    },
    MercenaryElementImg = {
        "Attributes_elemet_11.png",
        "Attributes_elemet_12.png",
        "Attributes_elemet_13.png",
        "Attributes_elemet_14.png",
        "Attributes_elemet_15.png",
        "Attributes_elemet_06.png",
    },
    MercenaryElementBg = {
        "mercenary_bg1.png",
        "mercenary_bg2.png",
        "mercenary_bg3.png",
        "mercenary_bg4.png",
        "mercenary_bg5.png",
        "mercenary_bg6.png",
    },
    MercenaryQualityTxt = {
        [3] = "R",
        [4] = "SR",
        [5] = "SSR",
        [6] = "UR",
    },
    ElementQualityImage = {
        [1] = "UI/MainScene/UI/u_IcoRoundbg01.png",
        -- white
        [2] = "UI/MainScene/UI/u_IcoRoundbg02.png",
        -- green
        [3] = "UI/MainScene/UI/u_IcoRoundbg03.png",
        -- blue
        [4] = "UI/MainScene/UI/u_IcoRoundbg04.png",
        -- purple
        [5] = "UI/MainScene/UI/u_IcoRoundbg05.png"-- orange
    },
    Scale9SpriteImage = {
        [1] = "u_9Sprite38.png"
    },
    QualityColor = {
        [1] = "255 255 255",
        -- white
        [2] = "0 255 0",
        -- green
        [3] = "14 157 213",
        -- blue
        [4] = "255 0 255",
        -- purple
        [5] = "255 125 0",
        -- orange
        [6] = "255 0 0",
        -- red
        [7] = "255 125 0",
        -- orange
        [8] = "255 125 0",
        -- orange
        [9] = "255 125 0",
        -- orange
        [10] = "255 0 0",-- red
    },
    QualityColor_deep = {
        [1] = "255 240 215",
        -- white
        [2] = "36 178 62",
        -- green
        [3] = "37 202 191",
        -- blue
        [4] = "204 32 220",
        -- purple
        [5] = "215 139 32",
        -- orange
        [6] = "220 31 31",
        -- red
        [7] = "215 139 32",
        -- orange
        [8] = "215 139 32",
        -- orange
        [9] = "215 139 32",
        -- orange
        [10] = "220 31 31",-- red
    },
    Default = {
        ArenaOpenLvLimit = 1,
        Quality = 1,
        ProfessionId = 1,
        ArenaBuyTimes = 20,
        LeaveMessageLenCount = 17,
        LeaveMessageLen = 2,
        LeaveMsgDetailLenCount = 15,
        NewMsgKey = "NewMessageKey",
        LeaveMsgCount = 40,
        LeaveMsgConfirmCount = 16,
        ChatCoolTime = 4,
        MailBattleTeamNameCount = 7,
        ShopItemNum = 6,
        OSPVPOpenLvLimit = 50,
        WHITEFRAME = 100, --米色背景框
    },
    -- 勋章系统
    FatePageConst = {
        MaxStarNum = 3,
        -- 最高星级定义
        maxLightCount = 5,
        -- 最多点亮数量
        activeCostType = { type = 30000, itemId = 101011 },
        -- 激活花费类型
        lightCostType = { type = 30000, itemId = 101012 },
        -- 点亮花费类型
        NoticeQuality = 4,
        -- 升级吞噬有大于该品质的，弹提示
        MaxWearNum = 6,
        -- 最多穿几件私装
        MaxSwallowNum = 6,
        -- 最大一次吸收的数量

        rewardDefaultLabelHeight = 64.8,
        -- 奖励界面默认文本高度
        selectItemDefaultLabelHeight = 54,
        -- 选择界面默认文本高度
        selectItemMaxLabelWidth = 455,
        -- 选择界面最大文本宽度
        selectNowItemDefaultLabelHeight = 118,
        -- 选择界面当前私装的默认文本高度
        selectNowItemMaxLabelWidth = 494,-- 选择界面当前私装的最大文本宽度
    },
    -- 勋章系统开启等级条件
    FateLevelLimit = {
        [1] = 50,
        [2] = 50,
        [3] = 60,
        [4] = 70,
        [5] = 80,
        [6] = 90,
    },
    FateImage = {
        [1] = {
            spine = "tonghuasunshangxiang",
            -- 童话孙尚香
            offsetX = 100,
            offsetY = 0,
            scale = - 1,
            icon = "UI/Role/Mercenary_Portrait_TongHuaSunShangXiang.png",
            quality = "UI/Common/Image/Image_Private_Frame_1.png"
        },
        [2] = {
            spine = "jkdingfeng",
            -- JK丁奉
            offsetX = 0,
            offsetY = 0,
            scale = 0.9,
            icon = "UI/Role/Mercenary_Portrait_JKDingFeng.png",
            quality = "UI/Common/Image/Image_Private_Frame_2.png"
        },
        [3] = {
            spine = "huiguniangpangde",
            -- 童话庞德
            offsetX = 0,
            offsetY = 0,
            scale = 1,
            icon = "UI/Role/Mercenary_Portrait_TongHuaPangDe.png",
            quality = "UI/Common/Image/Image_Private_Frame_3.png"
        },
        [4] = {
            spine = "yinghuazhonghui",
            -- 樱花钟会
            offsetX = 0,
            offsetY = -40,
            scale = 1.1,
            icon = "UI/Role/Mercenary_Portrait_YingHuaZhongHui.png",
            quality = "UI/Common/Image/Image_Private_Frame_4.png"
        },
        [5] = {
            spine = "tonghuabulianshi",
            -- 童话步练师
            offsetX = 0,
            offsetY = 0,
            scale = 1,
            icon = "UI/Role/Mercenary_Portrait_TongHuaBuLianShi.png",
            quality = "UI/Common/Image/Image_Private_Frame_5.png"
        },
    },
    LevelLimit = {
        MecenaryOpenLevel = 8,
        MecenaryLvLimit = 15,
        PlayerLevel = 200,
        EquipDress = 15,
        -- EnhanceLevelMax	= 20,
        GodlyLevelMax = 40
    },
    HeroTokenLimit = {
        LevelLimit = 40,
        TaskLimit = 5
    },
    FightLimit = {
        CampWarLimit = 2000
    },
    DressEquipType = {
        On = 1,
        Off = 2,
        Change = 3
    },
    BuyPackage = {
        Count = 10,
        -- 一次购买背包个数
        Cost = { 50, 50, 100, 100, 150, 150, 200, 200, 250, 250 }-- 一次购买背包所需钻石数
    },
    BuyDressBagCost = {
        -- 索引为剩余次数 num为购买背包个数 cost为花费元宝数量
        DefaultDressBagSize = 50,
        -- 默认背包大小
        [1] = { num = 10, cost = 300 },
        [2] = { num = 10, cost = 300 },
        [3] = { num = 10, cost = 300 },
        [4] = { num = 10, cost = 300 },
        [5] = { num = 10, cost = 300 },
        [6] = { num = 10, cost = 250 },
        [7] = { num = 10, cost = 250 },
        [8] = { num = 10, cost = 200 },
        [9] = { num = 10, cost = 200 },
        [10] = { num = 10, cost = 150 },
        [11] = { num = 10, cost = 150 },
        [12] = { num = 10, cost = 100 },
        [13] = { num = 10, cost = 100 },
        [14] = { num = 10, cost = 50 },
        [15] = { num = 10, cost = 50 },
    },
    -- 徽章开启等级
    BadgeLevelLimit = 39,
    OpenLevel = {
        GemPunch = 0,
        -- 钻石打孔
        EmbedGem = 0,
        -- 镶嵌 10
        Baptize = 0
    },
    Image = {
        -- ClickToSelect = "UI/MainScene/Font/u_Font07.png",
        ClickToSelect = "mercenary_spilt_addPic.png",
        -- 点击选择图片
        BackQualityImg = "common_ht_propK_diban.png",
        -- BackQualityImg = "UI/Common/Image/Image_ItemFrame_Shade.png",
        PunchSlot = "Item/42.png",
        -- 钻孔图片
        Empty = "UI/Mask/Image_Empty.png",
        -- 图片
        GemIcon = {
            "u_Gem01.png",
            "u_Gem02.png",
            "u_Gem03.png",
            "u_Gem04.png"
        },
        newGemIcon = {
            "Image_GemIcon_1.png",
            "Image_GemIcon_2.png",
            "Image_GemIcon_3.png",
            "Image_GemIcon_4.png",
            "Image_GemIcon_5.png",
            "Image_GemIcon_6.png",
            "Image_GemIcon_7.png",
            "Image_GemIcon_8.png",
            "Image_GemIcon_9.png",
            "Image_GemIcon_10.png",
            "Image_GemIcon_11.png",
            "Image_GemIcon_12.png",
            "Image_GemIcon_13.png",
            "Image_GemIcon_14.png",
            "Image_GemIcon_15.png",
        },
        Vip = "UI/MainScene/Font/u_vip%d.png",
        Diamond = "Item/2.png",
        MonthCard = "Item/5.png",
        DefaultGift = "Item/gift1.png",
        FriendBtn_1 = "UI/MainPage/u_MainPageBtn06.png",
        FriendBtn_2 = "UI/MainPage/u_MainPageBtn09.png",
        SkillDisable = "UI/MainScene/UI/u_Equipmentbg11.png",
        DefaultSoulStone = "UI/MainScene/UI/u_Item01.png",
        EmptySoulStone = "UI/MainScene/UI/u_ico000.png",
        MaterialPic = "UI/MainScene/Font/u_Font20.png",
        ChoicePic = "UI/MainScene/Font/u_Font07.png",
        UpgradePreviewPic = "UI/MainScene/Font/u_Font21.png",
        FullEmpty = "UI/MainScene/UI/u_empty.png",-- 图片
    },
    Cost = {
        RefreshBuildingEquip = 20,
        -- 打造刷新
        RoleTrain = {
            Common = 5000,
            GoldNormal = 20,
            GoldMedium = 60,
            GoldSenior = 200,
            GoldMediumVip = 3,
            -- 白金培养vip限制
            GoldSeniorVip = 7,
            -- 至尊培养vip限制
            MultiTrainVip = 8,
            -- --快速培养
            CommonItem = 104211,
            -- 普通培养丹itemId
            NormalItem = 104212,
            -- 高级培养丹itemId
            HighAItem = 104213,-- 高级A培养丹itemId
        },
        BuildGodlyEquip = 5000,
        SpecialBuild = 20000,
        CreateRegimentTeam = 50,
        -- 团战创建队伍	
        CreateAlliance = 300,
        -- 创建公会
        CompoundEquip = 2000,
        -- 神器融合消耗声望
        CampInspire = 20-- 阵营战鼓舞
    },
    -- 游戏帮助
    HelpKey = {
        -- 平台條款
        HELP_AGREEMENT = "HelpServiceAnnounce",
        HELP_AGREEMENT_R18 = "HelpServiceAnnounceECCHI ",
        HELP_AGREEMENT_KUSO = "HelpServiceAnnounce24",
        -------- 大廳 --------
        -- 工坊
        HELP_SMELT = "HelpSmelt",
        -- 派遣
        HELP_MERCENARY_EXPEDITIONPAGE = "HelpMercenaryExpedition",
        -- 占星
        HELP_WISHINGWHELL = "HelpWishingWheel",
        -- 秘密信條
        HELP_SECRETMSG = "HelpSecretMessage",
        -- 每日特惠
        HELP_DAILY_BUNDLE = "HelpDailySpecials",
        -- 點金(金銀寶山)
        HELP_MONEYCOLLECTION = "HelpTreasureMountain",
        -------- 冒險 --------
        -- 競技場
        HELP_PVP = "HelpPVP",
        -- 地下城
        HELP_DUNGEON = "HelpDungeon",
        -- 屬性迴廊
        HELP_DUNGEON_ELEMENT = "HelpElementDungeon",
        -- 世界Boss
        HELP_WORLD_BOSS = "HelpWorldBoss",
        -- 排行榜
        HELP_PLAYER_RANKING = "HelpRanking",
        -- 光之聖所
        HELP_HOLYGRILL = "HelpTemple",
        -- 職業聖所
        HELP_LEADER_CLASS = "HelpClassSoul",
        -- 屬性聖所
        HELP_LEADER_ELEMENT = "HelpElementSoul",
        -------- 戰鬥 --------
        -- 快速戰鬥
        HELP_FASTFIGHT = "HelpFightQuickly",
        -------- 忍娘 --------
        -- 忍娘資訊
        HELP_HEROHELP = "HelpHero",
        -------- 召喚 --------
        -- 普通召喚
        HELP_NORMALSUMMON = "HelpHeroRewardRate",
        --忍娘召喚
        HELP_GIRLSUMMON = "Help173RewardRate",
        -- 友情召喚
        HELP_FRIENDSUMMON = "HelpfdRewardRate",
        -- PickUp召喚
        HELP_PICKUPSUMMON = "Help172RewardRate",
        -- 屬性召喚
        HELP_FACTIONSUMMON = "Help158RewardRate", 
        -- 專武召喚
        HELP_AW_SUMMON = "HelpWeaponRewardRate",       
        -------- 其他 --------
        -- 專武強化
        HELP_AW_LEVELUP = "HelpUniqueStrength",
        -------- 活動 --------
        -- 壁尻
        HELP_GLORY_HOLE = "HelpGloryHole175",
        -- 壁尻排行榜
        HELP_GLORY_HOLE_RANKING = "HelpGloryHoleRanking",
        -- 單人強敵
        HELP_SINGLE_BOSS = "HelpSingleBoss",
        --爬塔
        HELP_CLIMB_TOWER = "HelpSeasonTower"
    },
    ItemId = {
        EnhanceElite = 101001,
        -- 强化精华
        ChallengeTicket = 103001,
        -- Boss挑战券
        MultiTicket = 103003,
        --花嫁挑戰券
        GodlyEquipStone = 90002-- 注灵之石
    },
    ColorMap = {
        COLOR_WHITE = "255 255 255",
        COLOR_GREEN = "2 247 142",
        COLOR_RED = "255 75 150",
        COLOR_YELLOW = "239 224 53",
        COLOR_QING = "0 255 255",
        COLOR_BLUE = "27 222 239",
        COLOR_PURPLE = "255 0 255",
        COLOR_ORANGE = "231 101 26",
        COLOR_GRAY = "127 127 127",
        COLOR_FRIEND_OWN = "2 253 32",
        COLOR_FRIEND_OTHER = "254 212 73",
        COLOR_DESCRIPTION_ORANGE = "255 192 0",
        COLOR_TITLE_PURPLE = "247 159 255",
        COLOR_DESCRIPTION_PURPLE = "238 47 255",
        COLOR_TITLE_BLUE = "114 220 255",
        COLOR_DESCRIPTION_BLUE = "0 192 255",
        COLOR_LIGHT_GRAY = "214 214 214",
        COLOR_RED_NORMALFONT = "135  54  38",
        COLOR_BROWN = "73,48,0"
    },
    LineWidth = {
        GodlyAttr = 6,
        EquipInfo = 280,
        EquipInfoFull = 400,
        BuildEquip = 13,
        MoreAttribute = 610,
        -- 更多属性
        ItemDescribe = 18,
        SecondaryAttrNum = 8,
        MailContent = 400,
        -- 邮件内容
        BattleChat = 18,
        ArenaRecordContent = 270,
        PlayerTitle = 200,
        -- 人物称号
        PlayerTitleDescribe = 380,
        -- 称号描述
        Tip = 371,--350, -- 275
        -- Tip内容宽度
        MercenaryHaloDescribe = 18,
        -- 佣兵光环描述
        ItemNameLength = 130,
        -- 物品名称显示的宽度
        AchievementContent = 16,
        -- 未完成任务描述,
        AchievementCompleteContent = 21,-- 已完成任务描述
    },
    EquipPartWeight = {
        2,2,0,1,1,
        3,4,4,2,3
    },
    PartOrder = common:table_flip( {
        2,10,9,8,7,3,4,1,6,5
    } ),
    Tag = {
        GemList = 20101,
        HtmlLable = 20102,
        EquipAni = 30000,
        TipLayer = 40000,
        TipLevelUp = 50000,
        FriendBtn = 1,
        VoiceChatLayer = 60000,
        ClosePage = 60000,
    },
    NewPointType = {
        ACHIEVEMENT_POINT_CLOSE = -9,
        TYPE_FIRST_GIFTPACK_CLOSE = -8,
        -- 首充礼包关闭
        MULTI_ELITE_CLOSE = -7,
        TYPE_ARENA_RECORD_CLOSE = -6,
        TYPE_RegimentWar_NEW_CLOSE = -5,
        TYPE_ALLIANCE_NEW_CLOSE = -4,
        TYPE_GIFT_NEW_CLOSE = -3,
        TYPE_CHAT_MESSAGE_CLOSE = -2,
        TYPE_MAIL_CLOSE = -1
    },
    TeamBattleLimit = 1500,
    -- 战斗日志的间距，以像素为单位
    FightLogSlotWidth = 10,
    -- 离线战斗行间距，以像素为单位
    OfflineSlotWidth = 10,
    bossWipeSlotWidth = 5,
    FreeTypeId = {
        GemDesAttrDes = 181,
        Quality_1 = 43,
        Quality_2 = 44,
        Quality_3 = 45,
        Quality_4 = 46,
        Quality_5 = 61, --  47, 因為freeTypeFont上使用置中字元, 故這裡改成61
        Quality_6 = 120, -- 119, 因為freeTypeFont上使用置中字元, 故這裡改成120
        Quality_7 = 47,
        Quality_8 = 47,
        Quality_9 = 47,
        Quality_10 = 119,
        Quality_11 = 47,
        Quality_12 = 47,
        Quality_13 = 47,
        Quality_14 = 119,
        Quality_15 = 45,
        Quality_16 = 46,
        Quality_17 = 47,
        Quality_18 = 119,
        Quality_19 = 45,
        Quality_20 = 46,
        Quality_21 = 47,
        Quality_22 = 119,
        Quality_deep_1 = 162,
        Quality_deep_2 = 163,
        Quality_deep_3 = 164,
        Quality_deep_4 = 165,
        Quality_deep_5 = 166,
        Quality_deep_6 = 167,
        Quality_deep_7 = 166,
        Quality_deep_8 = 166,
        Quality_deep_9 = 166,
        Quality_deep_10 = 167,
        Quality_deep_11 = 166,
        Quality_deep_12 = 166,
        Quality_deep_13 = 166,
        Quality_deep_14 = 167,
        Quality_deep_15 = 164,
        Quality_deep_16 = 165,
        Quality_deep_17 = 166,
        Quality_deep_18 = 167,
        Quality_deep_19 = 164,
        Quality_deep_20 = 165,
        Quality_deep_21 = 166,
        Quality_deep_22 = 167,
        EquipCondition = 48,
        EquipCondition_deep = 151,
        EquipCondition_F = 800,
        EquipCondition_deep_F = 800,
        EquipGrade = 49,
        EquipGrade_deep = 152,
        MainAttr = 50,
        GodlyAttr = 51,
        GodlyAttr_deep = 157,
        GodlyActiveAttr = 52,
        GodlyActiveAttr_deep = 158,
        GodlyUnactiveAttr = 53,
        GodlyUnactiveAttr_deep = 159,
        GemInfo = 54,
        GemInfo_deep = 161,
        SecondaryAttr_1 = 57,
        SecondaryAttr_2 = 58,
        SecondaryAttr_3 = 59,
        SecondaryAttr_4 = 60,
        SecondaryAttr_5 = 61,
        SecondaryAttr_6 = 120,
        SecondaryAttr_7 = 61,
        SecondaryAttr_8 = 61,
        SecondaryAttr_9 = 61,
        SecondaryAttr_10 = 120,
        equipAttrColor = 122,
        equipAttrColor_deep = 153,
        LvNameProf = 63,
        EquipInfoWrap = 64,
        FullGodlyAttr = 65,
        EquipCondition_1 = 66,
        EquipCondition_1_F = 801,
        EquipGrade_1 = 67,
        MainAttr_1 = 68,
        GodlyAttr_1 = 69,
        SecondaryAttr_1_1 = 70,
        SecondaryAttr_2_1 = 71,
        SecondaryAttr_3_1 = 72,
        SecondaryAttr_4_1 = 73,
        SecondaryAttr_5_1 = 74,
        SecondaryAttr_6_1 = 121,
        SecondaryAttr_7_1 = 74,
        SecondaryAttr_8_1 = 74,
        SecondaryAttr_9_1 = 74,
        SecondaryAttr_10_1 = 121,
        GodlyNextStarAttr = 75,
        GodlyNextStarAttr_deep = 160,
        FullGodlyAttr_1 = 76,
        EquipGradeMax = 78,
        EquipSuitName = 79,
        -- 套装名称
        EquipSuitName_deep = 150,
        EquipSuitAttrs1 = 803,
        -- 80, --套装属性（激活）
        EquipSuitAttrs2 = 803,
        -- 套装属性（激活）
        EquipSuitAttrs3 = 803,
        -- 804, --套装属性（激活）
        EquipSuitAttrs4 = 803,
        -- 805, --套装属性（激活）
        EquipSuitAttrs5 = 803,
        -- 806, --套装属性（激活）
        EquipSuitAttrs_deep1 = 155,
        -- 80, --套装属性（激活）
        EquipSuitAttrs_deep2 = 155,
        -- 套装属性（激活）
        EquipSuitAttrs_deep3 = 155,
        -- 804, --套装属性（激活）
        EquipSuitAttrs_deep4 = 155,
        -- 805, --套装属性（激活）
        EquipSuitAttrs_deep5 = 155,
        -- 806, --套装属性（激活）
        EvoMain1 = 807,
        -- 套装属性（激活）
        EvoMain2 = 808,
        -- 套装属性（激活）
        EquipSuitAttrsF = 81,
        -- 套装属性（未激活）
        EquipSuitAttrsF_deep = 156,
        -- 套装属性（未激活）
        EquipSuitAttrs = 82,
        -- 套装
        EquipSuitAttrs_deep = 154,
        -- 套装
        QMGJ_CDK = 84,
        -- Tips 相关 begin
        TipCommon = 85,
        TipBuyEquip = 86,
        TipCondition = 87,
        TipName_1 = 93,
        TipName_2 = 94,
        TipName_3 = 95,
        TipName_4 = 96,
        TipName_5 = 97,
        TipName_6 = 119,
        TipName_7 = 97,
        TipName_8 = 97,
        TipName_9 = 97,
        TipName_10 = 119,
        TipName_11 = 47,
        TipName_12 = 47,
        TipName_13 = 47,
        TipName_14 = 119,
        TipName_15 = 95,
        TipName_16 = 96,
        TipName_17 = 97,
        TipName_18 = 119,
        TipName_19 = 95,
        TipName_20 = 96,
        TipName_21 = 97,
        TipName_22 = 119,
        TipSmeltEquip = 98,
        TipStarEquip = 102,
        TipForGuild = 601,
        -- Tips 相关 end
        -- 周卡
        WeekCardRemainTime = 100,
        -- 美女主播充值
        GirlRechargeLabel = 105,
        -- 远征
        ExpeditionLimit = 101,
        MecenaryUpStepFormat = 103,
        MecenaryUpStepFormat1 = 104,
        MecenaryUpgradeStageFormat = 106,
        MecenaryUpgradeStageFormat1 = 108,
        MecenaryUpgradeStageFormat2 = 109,
        MecenaryLevelUpFormat = 124,
        ExpeditionContribute = 501,
        -- BOSS挑战券使用提示框
        BOSSFightTip = 107,
        -- 花嫁道場挑戰券使用提示框
        MultiFightTip = 123,
        -- 宝石合成提示框
        gemCompoundTip1 = 333,
        gemCompoundTip2 = 334,
        gemCompoundTip3 = 335,
        gemCompoundTip4 = 336,
        -- 活动_疯狂转盘
        ActRoulette = 401,
        -- 公会争霸查看对手信息
        AB_ViewBattleInfo = 1001,
        -- 男女语音名字，称号，位置
        VoiceChatMan = 703,
        VoiceChatWoman = 704,
        HeroOrderItemHelpStr = 113,
        HeroOrderItemRewardStr = 112,
        HeroOrderItemGoalStr = 111,
        HeroOrderTaskGoalStr = 114,
        HeroOrderTaskProgressStr = 115,
        --- 物品不足红色字
        ItemNotEnough = 168,
        ItemEnough = 169,
        MorEnhanceInfo = 172,
        WhiteFreeType = 93,
        RedFreeType = 173,
        RedFreeTypeFont = 174,
        GodlyStr1 = 175,
        GodlyStr1_deep = 175,
        GodlyStr2 = 176,
        GodlyStr2_deep = 176,
        GreenFontColor = 177,
        GrayFontColor = 178,
        GreenFontColor_deep = 179,
        GrayFontColor_deep = 180,
        OtherItemNotEnough = 182,
        OtherItemEnough = 183,
        ItemProduce = 809,
        -----高级育成----------------
        MultiTrainUseTools = 10090,
        MultiTrainUseLv1 = 10091,
        MultiTrainUseLv2 = 10092,
        MultiTrainUseLv3 = 10093,
        MultiTrainUseLv4 = 10094,
        -------缘分------------------
        -- 1个人的缘分， 1条属性  激活
        Relationship_1_1 = 994,
        -- 2个人的缘分， 1条属性  激活
        Relationship_2_1 = 995,
        -- 1个人的缘分， 1条属性  未激活
        Relationship_1_1_Close = 996,
        -- 2个人的缘分， 1条属性  未激活
        Relationship_2_1_Close = 997,
        Relationship_Open = 992,
        Relationship_Close = 993,
    },
    Color = {
        Lack = {246, 54, 69},
        Own = {53, 17, 0},
        Grey = {185, 185, 185},
        LackRed = {255, 0, 0},
        White = {255, 255, 255},
        Green = {0, 255, 0}
    },
    Count = {
        PieceToMerge = 10,
        PartTotal = 10,
        MinActivity = 5
    },
    Margin = {
        EquipInfo = 10,
        EquipSelect = 5,
        EquipSelectBottom = 0
    },
    WordSizeLimit = {
        RoleNameLimit = 12
    },
    NEWPLAYER_ACTIVITY_OPEN_LEVEL = 9,
    ALLIANCE_OPEN_LEVEL = 12,
    ELITEMAP_OPEN_LEVEL = 30,
    MELT_SPECIAL_OPEN_LEVEL = 1,
    MELT_All_OPEN_LEVEL = 11,
    WORLDBOSS_OPEN_LEVEL = 12,
    ARENA_OPEN_LEVEL = 1,
    MERCENARY_EXPEDITION_LIMIT = 35,
    MERCENARY_TRAIN_LIMIT = 1,
    MERCENARY_UPGRADESTAR_LIMIT = 1,
    CSPVP_OPEN_LEVEL = 50,
    SOULSTAR_LEVEL_LIMIT = 10,--45,
    -- 主页面广播持续时间--单位毫秒，1秒为1000
    BroadcastLastTime = 10000,
    BroadcastMoveSpeed = 40,
    -- 广播滚动的速度
    WordExchangeConsume = {
        10002,10003,10004,10005,10006,10007
    },
    WordExchangeReward = {
        ----[id] = {d = 天数, r = 奖励id}----
        [1] = { d = 1, r = 16 },
        [2] = { d = 3, r = 17 },
        [3] = { d = 5, r = 18 },
        [4] = { d = 7, r = 19 },
        [5] = { d = 9, r = 20 },
        [6] = { d = 11, r = 21 },
        [7] = { d = 13, r = 22 },
        [8] = { d = 15, r = 23 },
        [9] = { d = 17, r = 24 },
        [10] = { d = 19, r = 25 },
        [11] = { d = 20, r = 26 }
    },
    ChatMsgMaxSize = 50,
    -- 世界、工会聊天最多存储msg大小
    MsgBoxMaxSize = 20,
    CampAutoRegisterVip = 4,
    -- 阵营战自动挂机VIP限制
    WordRecycleRewardId = 15,
    -- "公测"字回收奖励id
    Part2GodlyAttr_1 = {
        106,108,101,105,104,
        1007,107,110,2103,2104
    },
    Part2GodlyAttr_2 = {
        2001,1010,1004,1009,2009,
        1008,2002,2008,1001,1006
    },
    GodlyAttrPureNum = 21,
    -- 神器属性>2100的为纯数值加成，而非百分比加成
    GodlyEquipAni = {
        First = "EquipAni01.ccbi",
        Second = "EquipAni02.ccbi",
        Double = "EquipAni03.ccbi",
        -- TenStar = "EquipAni04.ccbi",
    },
    MercenarySpineSpecialAction =  {
        -- [161] = "Standef"
    },
    MercenarySkillScale = {
        [145] = {
            [2451] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [149] = {
            [2491] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [154] = {
            [2541] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            },
            [2542] = {
                -- 技能2
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [156] = {
            [2561] = {
                -- 技能1
                lineCharCount = 30,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            },
            [2562] = {
                -- 技能2
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例	
            },
        },
        [157] = {
            [2571] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            },
            [2572] = {
                -- 技能2
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例	
            },
        },
        [158] = {
            [2581] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [159] = {
            [2591] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 0.55,-- 缩放比例
            }
        },
        [161] = {
            [2611] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 0.54,-- 缩放比例
            },
            [2612] = {
                -- 技能2
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例	
            }
        },
        [160] = {
            [2601] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [165] = {
            [2651] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [166] = {
            [2661] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            },
            [2662] = {
                -- 技能2
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例	
            },
        },
        [167] = {
            [2671] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [168] = {
            [2681] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            },
            [2682] = {
                -- 技能2
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例	
            },
        },
        [169] = {
            [2691] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            },
            [2692] = {
                -- 技能2
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例	
            },
        },
        [171] = {
            [2711] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [172] = {
            [2721] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            },
            [2722] = {
                -- 技能2
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
        [173] = {
            [2731] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            },
            [2732] = {
                -- 技能1
                lineCharCount = 26,
                -- 一行显示的字符个数
                scale = 1.0,-- 缩放比例
            }
        },
    },
    SpineCCBI = {
        [1] = "HeroWarrior_Man.ccbi",
        [2] = "HeroHunter_Man.ccbi",
        [3] = "HeroMaster_Man.ccbi",
        [4] = "HeroWarrior_Woman.ccbi",
        [5] = "HeroHunter_Woman.ccbi",
        [6] = "HeroMaster_Woman.ccbi",
    },
    CampWar = {
        basicRep = 10,
        basicCoin = 30,
        reportMax = 30,
        GapSecond = 3000
    },
    UnlockEditTeamLv = 50,
    UnlockMercenaryLv = { 0, 0, 0, 0, 0, 999, 999, 999, 999, 999, 999 },
    UnlockHelpFightMercenaryLv = { 0, 0, 0, 0, 0, 0, 999, 999, 999, 999, 999, 999 },
    ShowSpineAvatar = true,
    ShowNorMalPic = false,
    -- 控制显示非性感图片
    CurrentOpenMaxAllMap = 110,
    -- 所有最大的副本
    CurrentOpenMaxMap = 65,
    -- 转生前最大的副本
    CurrentChangeLevel = 100,
    -- 当前转生等级
    CurrentOpenMaxMultiMap = 15,
    -- 当前最大多人副本地图
    NewOpenMaxMap = 30,
    -- 转生后新副本最大地图
    ReincarnationLevel = 100,
    -- 可进行转生等级
    NewMapBaseId = 66,
    -- 转生后新地图 id 66开始
    NewbieGuide = {
        FirstFight = "newbieGuide_firstFight",
        -- 战斗	
        FirstFailBoss = "newbieGuide_firstFailBoss",
        -- 打boss失败
        FirstSmelt = "newbieGuide_firstSmelt",
        -- 熔炼
        FirstSkill = "newbieGuide_firstSkill",
        -- 技能
        FirstFightBoss = "newbieGuide_firstFightBoss",
        -- 挑战boss	
        FirstEquip = "newbieGuide_firstEquip",
        -- 装备
        FirstBattleMap = "newbieGuide_firstBattleMap",
        -- 关卡页面	
        FirstCanRebirthBattle = "newbieGuide_FirstCanRebirthBattle",
        -- 达到转生条件时 战斗按钮的红点
        FirstCanRebirthMap = "newbieGuide_FirstCanRebirthMap",
        -- 达到转生条件时 地图按钮的红点
        FirstCanRebirthChallenge = "newbieGuide_FirstCanRebirthChallenge",
        -- 达到转生条件时 新大陆地图按钮的提示小手
        FirstTalentUpdate = "newbieGuide_FirstTalentUpdate"-- 转生后 星魂系统点亮按钮提示小手
    },
    Quality2AttrNum = {
        -- 白绿蓝紫橙　对应副属性个数
        0,1,2,3,4,4,4,4,4,4
    },
    MercenaryBackgroundPic = {
        [7] = "UI/Program/MercenaryWarrior_2.png",
        [8] = "UI/Program/MercenaryHunter_2.png",
        [9] = "UI/Program/MercenaryMaster_2.png"
    },
    MercenarySkillState = {
        -- 技能状态
        forbidden = "UI/MainScene/UI/u_Equipmentbg11.png",
        canSelect = "UI/MainScene/Font/u_Font07.png"
    },
    -- 副将出站状态图片
    MercenaryBattleState = {
        -- 出战状态
        -- status_fight = "UI/Common/Button/Btn_MercenaryState_OnTeam.png",
        -- status_free = "UI/Common/Button/Btn_MercenaryState_Standby.png",
        status_fight = "mercenary_canzhanzhongBtn.png",
        -- 可以出战
        status_free = "mercenary_FightWait.png",
        -- 远足
        status_expedition = "mercenary_travling.png",
        -- 可以出战
        status_canFight = "mercenary_FightWait.png",
        -- 休息中
        status_substitutes = "mercenary_Fight_ShowBtn.png",
        -- 应援中
        status_replace = "mercenaryState_Subing.png",
        -- 可以应援
        status_canReplace = "mercenaryState_CanSub.png",
    },
    MercenaryMaxStar = 10,
    MerHaloMaxLevel = 10,
    -- 佣兵光环升级最大等级
    BattleResultGap = 25,
    -- 战斗结果页面显示间隔
    ShowStepStar = 1,
    SoulStoneIds = {
        -- 进阶之书Id
        90002, 90003, 90004, 90005, 90006,
    },
    RuneStonesIds = {
        -- 进阶之书Id
        104201, 104202, 104203,
    },
    HeroOrderBaseIds = {
        81000, 82000, 83000, 84000, 85000,
    },
    GemUpgradeLevelLimit = {
        -- 宝石工坊等级限制
        lowLevelLimit = 4,
        highLevelLimit = 7,
    },
    Act_RouletteVariable = {
        -- 疯狂转盘活动
        lotteryTimes = 50,
        -- 每日抽奖上限次数
        goldForOnceLottery = 100,
        -- 一次抽奖消耗钻石数
        delayTime = 6.5,
        -- 动画播放时间（用作延迟发协议）
        rotateRate = 3,-- 转盘的转动速率
    },
    VoiceChat = {
        -- 语音聊天
        minMillseconds = 1000,
        maxMillseconds = 15000,
        rootPath = "audio",
        faceSign = "/%d+/",
        lineNum = 18
    },
    SystemId = 999999,
    --- 聊天界面系统发言 系统的id

    ChatFace = {
        [1] = "UI/Animation/Expression/Expression_01.png",
        -- 敲	
        [2] = "UI/Animation/Expression/Expression_02.png",
        -- 疑问
        [3] = "UI/Animation/Expression/Expression_03.png",
        -- 流汗
        [4] = "UI/Animation/Expression/Expression_04.png",
        -- 阴险
        [5] = "UI/Animation/Expression/Expression_05.png",
        -- 再见
        [6] = "UI/Animation/Expression/Expression_06.png",
        -- 晕
        [7] = "UI/Animation/Expression/Expression_07.png",
        -- 白眼
        [8] = "UI/Animation/Expression/Expression_08.png",
        -- 抠鼻
        [9] = "UI/Animation/Expression/Expression_09.png",
        -- 衰
        [10] = "UI/Animation/Expression/Expression_10.png",
        -- 憨笑
        [11] = "UI/Animation/Expression/Expression_11.png",
        -- 困
        [12] = "UI/Animation/Expression/Expression_12.png",
        -- 擦汗
        [13] = "UI/Animation/Expression/Expression_13.png",
        -- 流泪
        [14] = "UI/Animation/Expression/Expression_14.png",
        -- 偷笑
        [15] = "UI/Animation/Expression/Expression_15.png",
        -- 吐
        [16] = "UI/Animation/Expression/Expression_16.png",
        -- 傲慢
        [17] = "UI/Animation/Expression/Expression_17.png",
        -- 酷
        [18] = "UI/Animation/Expression/Expression_18.png",
        -- 难过
        [19] = "UI/Animation/Expression/Expression_19.png",
        -- 惊讶
        [20] = "UI/Animation/Expression/Expression_20.png",
        -- 抓狂

        [21] = "UI/Animation/Expression/Expression_21.png",-- 抓狂
    },
    ChatBigFace = {
        [1] = "UI/Animation/ExpressionBig/Expression_01.png",
        -- 敲
        [2] = "UI/Animation/ExpressionBig/Expression_02.png",
        -- 疑问
        [3] = "UI/Animation/ExpressionBig/Expression_03.png",
        -- 流汗
        [4] = "UI/Animation/ExpressionBig/Expression_04.png",
        -- 阴险
        [5] = "UI/Animation/ExpressionBig/Expression_05.png",
        -- 再见
        [6] = "UI/Animation/ExpressionBig/Expression_06.png",
        -- 晕
        [7] = "UI/Animation/ExpressionBig/Expression_07.png",
        -- 白眼
        [8] = "UI/Animation/ExpressionBig/Expression_08.png",
        -- 抠鼻
        [9] = "UI/Animation/ExpressionBig/Expression_09.png",
        -- 衰
        [10] = "UI/Animation/ExpressionBig/Expression_10.png",
        -- 憨笑
        [11] = "UI/Animation/ExpressionBig/Expression_11.png",
        -- 困
        [12] = "UI/Animation/ExpressionBig/Expression_12.png",
        -- 擦汗
        [13] = "UI/Animation/ExpressionBig/Expression_13.png",
        -- 流泪
        [14] = "UI/Animation/ExpressionBig/Expression_14.png",
        -- 偷笑
        [15] = "UI/Animation/ExpressionBig/Expression_15.png",
        -- 吐
        [16] = "UI/Animation/ExpressionBig/Expression_16.png",
        -- 傲慢
        [17] = "UI/Animation/ExpressionBig/Expression_17.png",
        -- 酷
        [18] = "UI/Animation/ExpressionBig/Expression_18.png",
        -- 难过
        [19] = "UI/Animation/ExpressionBig/Expression_19.png",
        -- 惊讶
        [20] = "UI/Animation/ExpressionBig/Expression_20.png",
        -- 抓狂

        [21] = "UI/Animation/ExpressionBig/Expression_21.png",-- 抓狂
    },
    titleColor = {
        -- 公会聊天称号颜色
        "#0964fa",
        "#fa09f2",
        "#fed205",
    },
    GoldCostForBaptize = {
        [0] = 10,
        [1] = 15,
        [2] = 20,
    },
    FriendNameLenLimit = {
        strLen = 5
    },
    StoneAndEquipSpeLevel = 10,
    ABGuildBufferInfo = {
        [1] = {
            type = 10000,
            count = 0,
            itemId = 2002
        },
        [2] = {
            type = 10000,
            count = 0,
            itemId = 2003
        },
        [3] = {
            type = 10000,
            count = 0,
            itemId = 2004
        },
        [4] = {
            type = 10000,
            count = 0,
            itemId = 2005
        },
        [5] = {
            type = 10000,
            count = 0,
            itemId = 2006
        }
    },
    WelfarePageIds = { 84, 82, 83 },
    -- WelfarePage页面所有的活动id 顺序：首冲礼包、新手折扣、月卡
    ABGuildBackgroundImg = {
        DefaultRight = "UI/MainScene/Button/b_Blue06.png",
        DefaultLeft = "UI/MainScene/Button/b_Pink04.png",
        Mine = "UI/Common/Button/Btn_GuildBattle_Mine.png"
    },
    MultiEliteResult = {
        [1] = "UI/MainScene/Font/u_EnglishAlphabetC.png",
        [2] = "UI/MainScene/Font/u_EnglishAlphabetB.png",
        [3] = "UI/MainScene/Font/u_EnglishAlphabetA.png",
        [4] = "UI/MainScene/Font/u_EnglishAlphabetS.png",
    },
    MultiEliteLimitLevel = 1,
    WorldBoss = {
        -- SpineID 就是SpineAvatar 和 SpineCCBI 的id
        [5001] = { name = "年兽", level = "888", SpineAvatar = { "Spine/MonsterSpine", "WorldBoss_01" } },
        [5002] = { name = "年兽", level = "888", SpineAvatar = { "Spine/MonsterSpine", "WorldBoss_01" } },
        [5003] = { name = "年兽", level = "888", SpineAvatar = { "Spine/MonsterSpine", "WorldBoss_01" } },
        [5004] = { name = "年兽", level = "888", SpineAvatar = { "Spine/MonsterSpine", "WorldBoss_01" } },
        [5005] = { name = "年兽", level = "888", SpineAvatar = { "Spine/MonsterSpine", "WorldBoss_01" } }
    },
    WorldBossPic = {
        normal = "UI/MainScene/Button/u_MainPageBtn11.png",
        beast = "UI/MainScene/Button/u_MainPageBtn12.png"
    },
    -- 世界boss 按钮消耗钻石
    WorldBossCostNormal = 2,
    -- 换装界面，当前装备的高度
    EquipSelectCurContentHeight = 150,
    StarPicPath = "UI/MainScene/UI/u_Decoration12.png",
    EquipEvolutionMaterial = {
        Enough = { 255, 255, 255 },
        Short = { 255, 60, 74 }
    },
    -- 改名消耗钻石数量
    ChangeNameCost = 270,
    COUNT_MERCENARY = 3,
    TalentNumPerLevel = 5000,
    ClearTalentCost = 100,
    -- 天赋系统 清空属性消耗
    ElementMaxLevel = 100,
    -- 元素最大等级
    SuitShopLevelLimit = 45,
    -- 水晶商店开启等级
    SuitEquipLevelLimit = 0,
    -- 套装碎片背包开启等级
    BattleTextSizeConfig = {
        Min = 1,
        -- 20号字体
        Middle = 2,
        -- 32号字体(默认)
        Max = 3-- 40号字体
    },
    platformSwitch = {
        win32 = {
            ShowNorMalPic = false,
            -- 控制显示非性感图片
            ShowSpineAvatar = true,
            GiftCDK = false,
            -- 礼包界面CDK兑换是否显示
            notShowLogOut = false,
            -- 不显示注销按钮
            showBattleBlink = false,
            -- 快速战斗闪光不显示
            showAds = false,
            -- 送审的时候 需要显示广告，审核完之后，记得改为false
            mvpRechargeURL = "",
            -- r2 mvp recharge url v1 server;v2 puid;v3 lang
            mvpRechargeIsOpen = false,
            -- r2 mvp recharge is open
            mvpRechargeLvlLimit = 10,
            -- r2 mvp recharge lvl limit (>=)
            mvpRechargeVip = 1,
            -- r2 mvp recharge vip limit  (>=)
            isShowLangSwitch = true,-- 显示语言切换按钮
        },
        ios_r2_en = {
            ShowNorMalPic = false,
            -- 控制显示非性感图片
            ShowSpineAvatar = true,
            GiftCDK = false,
            -- 礼包界面CDK兑换是否显示
            notShowLogOut = true,
            -- 不显示注销按钮
            showBattleBlink = false,
            -- 快速战斗闪光不显示
            showAds = false,
            -- 送审的时候 需要显示广告，审核完之后，记得改为false
            mvpRechargeURL = "",
            -- r2 mvp recharge url v1 server;v2 puid;v3 lang
            mvpRechargeIsOpen = false,
            -- r2 mvp recharge is open
            mvpRechargeLvlLimit = 10,
            -- r2 mvp recharge lvl limit (>=)
            mvpRechargeVip = 1,
            -- r2 mvp recharge vip limit  (>=)
            isShowLangSwitch = true,-- 显示语言切换按钮
        },
        google_R2_en = {
            ShowNorMalPic = false,
            -- 控制显示非性感图片
            ShowSpineAvatar = true,
            GiftCDK = true,
            -- 礼包界面CDK兑换是否显示
            notShowLogOut = true,
            -- 不显示注销按钮
            showBattleBlink = false,
            -- 快速战斗闪光不显示
            mvpRechargeURL = "",
            -- r2 mvp recharge url v1 server;v2 puid;v3 lang
            mvpRechargeIsOpen = false,
            -- r2 mvp recharge is open					
            mvpRechargeLvlLimit = 10,
            -- r2 mvp recharge lvl limit (>=)
            mvpRechargeVip = 1,
            -- r2 mvp recharge vip limit  (>=)
            isShowLangSwitch = true,-- 显示语言切换按钮
        },
        google_R2_cy = {
            ShowNorMalPic = false,
            -- 控制显示非性感图片
            ShowSpineAvatar = true,
            GiftCDK = true,
            -- 礼包界面CDK兑换是否显示
            notShowLogOut = true,
            -- 不显示注销按钮
            showBattleBlink = false,
            -- 快速战斗闪光不显示
            mvpRechargeURL = "",
            -- r2 mvp recharge url v1 server;v2 puid;v3 lang
            mvpRechargeIsOpen = false,
            -- r2 mvp recharge is open					
            mvpRechargeLvlLimit = 10,
            -- r2 mvp recharge lvl limit (>=)
            mvpRechargeVip = 1,
            -- r2 mvp recharge vip limit  (>=)
            isShowLangSwitch = true,-- 显示语言切换按钮
        },
        google_R2_yd = {
            ShowNorMalPic = false,
            -- 控制显示非性感图片
            ShowSpineAvatar = true,
            GiftCDK = true,
            -- 礼包界面CDK兑换是否显示
            notShowLogOut = true,
            -- 不显示注销按钮
            showBattleBlink = false,
            -- 快速战斗闪光不显示
            mvpRechargeURL = "",
            -- r2 mvp recharge url v1 server;v2 puid;v3 lang
            mvpRechargeIsOpen = false,
            -- r2 mvp recharge is open					
            mvpRechargeLvlLimit = 10,
            -- r2 mvp recharge lvl limit (>=)
            mvpRechargeVip = 1,
            -- r2 mvp recharge vip limit  (>=)
            isShowLangSwitch = true,-- 显示语言切换按钮
        },
        ios_efun_en = {
            ShowNorMalPic = true,
            -- 控制显示非性感图片
            ShowSpineAvatar = false,
            GiftCDK = false,-- 礼包界面CDK兑换是否显示
        },
        ios_gnetop_jp = {
            ShowNorMalPic = false,
            -- 控制显示非性感图片
            ShowSpineAvatar = true,
            notShowLogOut = false,
            -- 不显示注销按钮
            showAds = false,-- 送审的时候 需要显示广告，审核完之后，记得改为false
        },
        ios_gnetopSpecial_jp = {
            ShowNorMalPic = false,
            -- 控制显示非性感图片
            ShowSpineAvatar = true,
            notShowLogOut = false,
            -- 不显示注销按钮
            showAds = false,-- 送审的时候 需要显示广告，审核完之后，记得改为false
        },
        ios_entermate_kr = {
            ShowNorMalPic = true,
            -- 控制显示非性感图片
            ShowSpineAvatar = false,
            showAds = false,-- 送审的时候 需要显示广告，审核完之后，记得改为false
        },
        ios_ryuk_jp = {
            ShowNorMalPic = false,
            -- 控制显示非性感图片
            ShowSpineAvatar = true,
            notShowLogOut = false,
            -- 不显示注销按钮
            showAds = false,-- 送审的时候 需要显示广告，审核完之后，记得改为false
        },
    },
    buyBossFightPrice = {
        [0] = 50,
        [1] = 100,
        [2] = 100,
        [3] = 150,
        [4] = 150,
        size = 5,
        price = 200,
    },
    buyEliteMapBossFightPrice = {
        [0] = 60,
        [1] = 120,
        [2] = 180,
        size = 3,
        price = 200,
    },
    buyFastFightPrice = "0,50,100,200,300,500",
    -- 渠道配置   是否强制提示 0 关闭 1正常提示 2强制提示     网址     第三方支付开启  0关闭  1开启
    -- 第四个参数 是判断同包名 不同版本号判断第一个参数是否生效  s
    ChannelConfig = {
        gameJP = "0,http://bit.ly/1GqZBgd,0,2.153.13",
        laobaojp = "0,,1,2.153.21",
        qmgj = "0,,0,2.162.0",
        -- ios
        qmgj01 = "0,,1,2.162.0",
        -- ios
        gjabd160216 = "0,,1,2.162.9",
        -- ios 20160216
        autogames = "0,,0,2.158.1",
        -- android正式
        gjabd16021 = "0,,1,2.158.1",
        -- android推广
        gjabd160411 = "0,,0,2.162.18",
        -- ios 20160411
        gjabd160503 = "0,,0,2.162.24",
        -- ios 20160503
        leave = "0,,0,2.162.28",
    },
    CommentUrl = {
        AndroidUrl = "",
        IosUrl = "",
    },
    LifelongCardGems = 150,
    -- 终身卡每日 返钻数量
    shopRedPoint = false,
    adPicName = "UI/MainPage/MainPage_TitleAdvertising_Btn.png",
    -- 广告图片名字
    SkillStatus = {
        EMPTY_SKILL = "UI/Mask/Image_Empty.png",
        LOCK_SKILL = "UI/Common/Image/Image_Mercenary_Lock.png",
    },
    win32Platform = "android_h365",
    GuildBossAutoFightLimit = 2,
    -- 公会boss自动参战VIP等级限制
    defaultEquipImage = {
        ["Helmet"] = "UI/Common_UI02/common_ht_equipGray_Helmet.png",
        ["Neck"] = "UI/Common_UI02/common_ht_equipGray_Neck.png",
        ["Finger"] = "common_ht_equipGray_Legs.png",
        ["Wrist"] = "UI/Common_UI02/common_ht_equipGray_Wrist.png",
        ["Waist"] = "UI/Common_UI02/common_ht_equipGray_Waist.png",
        ["Feet"] = "common_ht_equipGray_Feet.png",
        ["Chest"] = "common_ht_equipGray_Helmet.png",
        ["Legs"] = "UI/Common_UI02/common_ht_equipGray_Legs.png",
        ["MainHand"] = "common_ht_equipGray_MainHand1.png",
        ["MainHand_1"] = "UI/Common_UI02/common_ht_equipGray_MainHand1.png",
        ["MainHand_2"] = "UI/Common_UI02/common_ht_equipGray_MainHand3.png",
        ["MainHand_3"] = "UI/Common_UI02/common_ht_equipGray_MainHand3.png",
        ["MainHand_4"] = "UI/Common_UI02/common_ht_equipGray_MainHand1.png",
        ["MainHand_5"] = "UI/Common_UI02/common_ht_equipGray_MainHand2.png",
        ["MainHand_99"] = "UI/Common_UI02/common_ht_equipGray_MainHand1.png",
        ["OffHand"] = "UI/Common_UI02/common_ht_equipGray_OffHand1.png",
        ["OffHand_1"] = "UI/Common_UI02/common_ht_equipGray_OffHand1.png",
        ["OffHand_2"] = "UI/Common_UI02/common_ht_equipGray_OffHand3.png",
        ["OffHand_3"] = "UI/Common_UI02/common_ht_equipGray_OffHand3.png",
        ["OffHand_4"] = "UI/Common_UI02/common_ht_equipGray_OffHand1.png",
        ["OffHand_5"] = "UI/Common_UI02/common_ht_equipGray_OffHand2.png",
        ["OffHand_99"] = "UI/Common_UI02/common_ht_equipGray_OffHand1.png",
    },
    BlurryLineWidth = 110,
    dailyTaskLevelPoint = {
        [1] = { level = 14, point = 100 },
        [1] = { level = 29, point = 120 },
        [1] = { level = 34, point = 130 },
        [1] = { level = 200, point = 155 },
    },
    growthVipLevel = 2,
    -- 成长基金VIP最小开放购买等级
    growthNeedGold = 1000,
    -- 成长基金购买所需元宝

    _MercenaryInfo = {
        itemId = 129,
        pic = "UI/Common/Activity/Act_TL_LuckyMercenary/Act_TL_LuckyMercenary_Font_JiaXu.png",
    },
    design_width = 720,
    design_height = 1280,
    GVEAutoFightVipLowLimit = 2,
    GVEAutoFightVipHightLimit = 4,
    GVEAutoFightPrice = 400,
    ShowSpineRate = {
        small = 1.15
    },
    ----佣兵骨骼缩放
    AvatarSpineScale = {
        [157] = { 1.15, 1.15 },
        [161] = { 1, 1 },
        [173] = { 0.9, 0.9 },
    },
    ----时装界面佣兵骨骼缩放和中心点偏移值
    AvatarFashionCfg = {
        [161] = {
            x = 0,
            y = 0,
            scale = { 0.9, 0.9 }
        },
        [157] = {
            x = 0,
            y = 0,
            scale = { 1.15, 1.15 }
        }
    },

    ----主角皮肤骨骼图标
    LeaderAvatarInfo = {
        default = {
            spine = {
                -- 骨骼
                [1] = { "Spine/Woman_Warrior", "Woman_Warrior" },
                [2] = { "Spine/Woman_Hunter", "Woman_Hunter" },
                [3] = { "Spine/Woman_Master", "Woman_Master" },
            },
            --             spine = {--骨骼
            --                [1] = {"Spine/Woman_Warrior", "Woman_Warrior"},
            -- 	        [2] = {"Spine/Woman_Hunter", "Woman_Hunter"},
            -- 	        [3] = {"Spine/Woman_Master", "Woman_Master"},
            --            },
            icon = {
                -- 道具图标
                [1] = "UI/NewPlayeIcon/MainPageIcon/Role/Player_Portrait_Warrior.png",
                [2] = "UI/NewPlayeIcon/MainPageIcon/Role/Player_Portrait_Hunter.png",
                [3] = "UI/NewPlayeIcon/MainPageIcon/Role/Player_Portrait_Master.png"
            },
            staticImg = {
                -- 预览立绘
                [1] = "UI/Common/BG/BG_MainRole_Warrior.png",
                [2] = "UI/Common/BG/BG_MainRole_Hunter.png",
                [3] = "UI/Common/BG/BG_MainRole_Master.png"
            },
            mainImg = {
                -- 主页立绘
                [1] = "UI/Common/BG/BG_MainRole_Warrior.png",
                [2] = "UI/Common/BG/BG_MainRole_Hunter.png",
                [3] = "UI/Common/BG/BG_MainRole_Master.png"
            },
            banshenxiang = {
                -- 半身像
                [1] = "HalfBody/role/SSRhuanggai.png",
                [2] = "HalfBody/role/SSRhuanggai.png",
                [3] = "HalfBody/role/SSRhuanggai.png"
            },
        },
        [1] = {
            spine = {
                [1] = {"Spine/zhanshinh", "zhanshinh"},
                -- 战
                [2] = { "Spine/gongshounh", "gongshounh" },
                -- 弓
                [3] = { "Spine/fashinh", "fashinh" },-- 法
            },
            icon = {
                [1] = "UI/NewPlayeIcon/MainPageIcon/Role/Player_Portrait_Warrior_1.png",
                [2] = "UI/NewPlayeIcon/MainPageIcon/Role/Player_Portrait_Hunter_1.png",
                [3] = "UI/NewPlayeIcon/MainPageIcon/Role/Player_Portrait_Master_1.png"
            },
            staticImg = {
                -- 预览立绘
                [1] = "UI/Common/BG/BG_FashionShow_Role_1.png",
                [2] = "UI/Common/BG/BG_FashionShow_Role_2.png",
                [3] = "UI/Common/BG/BG_FashionShow_Role_3.png"
            },
            mainImg = {
                -- 主页立绘
                [1] = "UI/Common/BG/BG_MainRole_Warrior_1.png",
                [2] = "UI/Common/BG/BG_MainRole_Hunter_1.png",
                [3] = "UI/Common/BG/BG_MainRole_Master_1.png"
            }
        }
    },

    ChangeNameCardId = 101004,-----改名卡道具ID

    --工口
    eroCoinImg = "",
    eroPriceRatio = 10,
    --JGG
    jggCoinImg = "",
    jggPriceRatio = 50,
}

local meta = getmetatable(GameConfig.LeaderAvatarInfo) or { }
meta.__index = function(t, k)
    return t.default
end
setmetatable(GameConfig.LeaderAvatarInfo, meta)

-- 韩国版数据修改
if Golb_Platform_Info.is_entermate_platform then
    GameConfig.buyFastFightPrice = "10,12,12,22,22,30,30,36,36"

    GameConfig.buyBossFightPrice = {
        [0] = 12,
        [1] = 24,
        [2] = 24,
        size = 3,
        price = 48,
    }

    GameConfig.BuyPackage = {
        Count = 10,
        -- 一次购买背包个数
        Cost = { 50, 50, 100, 100, 150, 150, 200, 200, 250, 250, 300, 300, 300, 300, 300 }-- 一次购买背包所需钻石数
    }

    GameConfig.Cost = {
        RefreshBuildingEquip = 20,
        -- 打造刷新
        RoleTrain = {
            Common = 500,
            GoldNormal = 10,
            GoldMedium = 25,
            GoldSenior = 50
        },
        BuildGodlyEquip = 5000,
        SpecialBuild = 20000,
        CreateRegimentTeam = 20,
        -- 团战创建队伍	
        CreateAlliance = 70,
        -- 创建公会
        CompoundEquip = 2000,
        -- 神器融合消耗声望
        CampInspire = 10-- 阵营战鼓舞
    }

    GameConfig.ChangeNameCost = 100
    -- 改名花费
end
GameConfig.SaveingTime = 8
-- R2数据修改
if Golb_Platform_Info.is_r2_platform then
    GameConfig.ChangeNameCost = 2000
    -- 改名花费
end

-- 游戏内按钮  红蓝绿金
GameConfig.CommonButtonImage = {
    Bule = {
        NormalImage = "common_ht_btn_blue_N_1.png",
        SelectedImage = "common_ht_btn_blue_S_1.png.png",
        DisabledImage = "common_ht_btn_gray.png"
    },
    Red = {
        NormalImage = "common_ht_btn_rad_N_1.png",
        SelectedImage = "common_ht_btn_rad_S_1.png",
        DisabledImage = "common_ht_btn_gray.png"
    },
    Green = {
        NormalImage = "common_ht_btn_Green_N_1.png",
        SelectedImage = "common_ht_btn_Green_N_1.png",
        DisabledImage = "common_ht_btn_gray.png"
    },
    Golden = {
        NormalImage = "NG1_Golden_N.png",
        SelectedImage = "NG1_Golden_S.png",
        DisabledImage = "NG1_Grey.png"
    }
}

-- 游戏内按钮上的字体路径
GameConfig.FntPath = {
    Bule = "Lang/Font-HT-Button-Blue.fnt",
    Red = "Lang/Font-HT-Button-red.fnt",
    Green = "Lang/Font-HT-Button-Green.fnt",
    Golden = "Lang/Font-HT-Button-Golden.fnt"
}

GameConfig.ScreenSize = { width = 720, height = 1280 }

GameConfig.EquipmentIconScale = 1   -- 装备icon缩放比例
GameConfig.EquipmentAttrIconScale = 0.75 -- 裝備屬性icon縮放比例
GameConfig.SkillIconScale = 1   -- 技能icon缩放比例
GameConfig.MercenaryFightintMaxCount = 5 -- 副将出战最大数量
GameConfig.isIOSAuditVersion = false    -- 是不是IOS审核版本------------
GameConfig.isIOSDemoVersion = true    -- 是不是DEMO版本------------
-- 应援替补 飞出 飞入的时间(秒)
GameConfig.ReplaceMercenary_MoveOutTime = 0.3
GameConfig.ReplaceMercenary_MoveInTime = 0.3
GameConfig.isJumpMercenaryPage = false  -- 是否跳到佣兵界面

GameConfig.isShoComment = true     -- 是否开启诱导评论

GameConfig.Act_126 = {
    needGold = 0,
    canPlay = true,
}
GameConfig.LabelCharMaxNumOneLine = {
    SkillContent = 24,
    SkillOpenContent = 24,
    SkillSpecialtyContent = 24,
    MercenarySkillPage = 24,
    MercenaryUpgradeDegreePopUp = 24,
    SkillSpecialtyEvolutionContent = 24
}
GameConfig.LabelSkillDescColor = {
    SkillContent = "237  28  36",
    -- 主将技能变更技能展示界面
    SkillOpenContent = "237  28  36",
    -- 主将技能展示已经开启的技能界面
    SkillSpecialtyContent = "237  28  36",
    -- 主将技能强化展示页面
    MercenarySkillPage = "237  28  36",
    -- 副将技能展示页面
    MercenaryUpgradeDegreePopUp = "237  28  36",
    -- 副将训练觉醒界面觉醒技能的介绍展示
    SkillSpecialtyEvolutionContent = "237  28  36",-- 主将技能单个技能强化界面
}
GameConfig.MercenaryAwakeImage = {
    [1] = "GroupPage/mercenary_role_awakeBtnTit_gray.png",
    -- no awake
    [2] = "GroupPage/mercenary_role_awakeTit_gray.png",
    -- finish awake
    [3] = "GroupPage/mercenary_role_awakeBtnTit.png",-- awaking click
}
GameConfig.MercenarySkillTypeTitleImage = {
    [1] = "GroupPage/merc_skill_normaltitle.png",
    -- special title
    [2] = "GroupPage/merc_skill_specialtitle.png",
    -- defend  title
    [3] = "GroupPage/merc_skill_defendtitle.png",-- normal title
}
GameConfig.ShopPageSpineSet = {
    roleID = 138,
    scale = 1,
    offest_x = 0,
    offest_y = - 50
}
GameConfig.VIPHaveRoleId = { 3, 9 }

GameConfig.GoldImage = "common_ht_jinbi_img.png"
GameConfig.DiamondImage = "common_ht_zuanshi_img.png"
GameConfig.SuitImage = "Icon_Suit_S.png"
GameConfig.ArenaRecordImage = "Arena_Icon_1.png"
GameConfig.ALLIANCEImage = "Alliance_ShopPage_icon.png"
-- Arena_Icon_1

GameConfig.loginTimeStamp = nil
GameConfig.isJump30DayPage = nil
GameConfig.headIconNew = nil
GameConfig.isRigistInput = false
GameConfig.guildJumpChat = { isGuildJump = false, isRetuGuild = false }
GameConfig.isOpenBadge = true
GameConfig.TableIsImpty = function(t)
    return _G.next(t) == nil
end

GameConfig.RuneInfoPageType = {
    EQUIPPED = 1,
    NON_EQUIPPED = 2,
    FUSION = 3,
}

GameConfig.COMMON_TAB_COLOR = {
    SELECT = "142 75 54",
    UNSELECT = "72 70 70",
}

GameConfig.ITEM_NUM_COLOR = {
    ENOUGH = "48 29 9",
    NOT_ENOUGH = "255 38 0",
}

GameConfig.ATTR_CHANGE_COLOR = {
    PLUS = "0 210 255",
    MINUS = "255 0 85",
}

GameConfig.RARITY_COLOR = {
    STAR_1 = "51 16 0",
    STAR_2 = "19 105 17",
    STAR_3 = "32 79 217",
    STAR_4 = "203 31 219",
    STAR_5 = "230 96 0",
    STAR_6 = "219 31 31",
}


GameConfig.NgHeadIconType = {
    HERO_PAGE = 1,
    GALLERY_PAGE = 2,
    COLLECTION_PAGE = 3,
    EDIT_TEAM_PAGE = 4,
    RARITY_UP_PAGE = 5,
    BOUNTY_PAGE=6,
}

GameConfig.NgHeadIconSmallType = {
    PLAYERINFO_PAGE = 1,
    BATTLE_EDITTEAM_PAGE = 2,
    ARENA_PAGE = 3,
}

GameConfig.SECRET_PAGE_TYPE = {
    MAIN_PAGE = 1,
    CHAT_PAGE = 2,
}

GameConfig.MAX_HERO_STAR = 13

GameConfig.AW_RESET_COST = 1000

GameConfig.LOCK_PAGE_KEY = {
    -- LOBBY
    WISHING_WELL = 1, SECRET_MESSAGE = 2, QUEST = 3, FORGE = 4, GUILD = 5, SPRITE = 6, SHOP = 7, BOUNTY = 8,
    -- LOBBY2
    HOLY_GRAIL = 101, ARENA = 102, DUNGEON = 103, GOLD_MINE = 104, EVENT = 105, WORLD_BOSS = 106,TOWER= 107, RANKING = 108,
    -- 福袋
    SUMMON_900 = 201, SKIN_SHOP = 202, SEVENDAY_QUEST = 203, POPUP_SALE = 206, DAILY_BUNDLE = 207, GROWTH_BUNDLE = 208, MONTHLY_CARD = 209, SUBSCIPTON = 210, CALENDAR = 211,STEPBUNDLE=214, 
    DAILY_RECHARGE = 212, FIRST_RECHARGE = 213, GLORY_HOLE = 215, Event001 = 216, SINGLE_BOSS = 217,
    -- 工房
    RUNE_BUILD = 301,
    -- 商店
    SHOP_DAILY = 401, SHOP_ARENA = 402, SHOP_MYSTERY = 403, SHOP_RACE = 404,
    -- 召喚
    SUMMON_FACTION = 501,
    -- 主按鈕
    SUMMON = 601,
    -- 聊天發話
    CHAT_SEND_MESSAGE = 701,
    -- 角色裝備
    ANCIENT_WEAPON = 801, RUNE_1 = 802, RUNE_2 = 803, RUNE_3 = 804, RUNE_4 = 805,
    -- 戰鬥
    FAST_BATTLE = 901, AUTO_BATTLE = 902,
    --公告
    ANNOUCEMENT = 9,
}

GameConfig.GLOYHOLE = {
    GAME_TOTAL_TIME = 60,
    FEVER_TIME_SCORE = 20000,
    FEVER_TIME_LONG = 10,
    FEVER_PERCENT=1.5,
    ComboInfo={[10]=1000,[30]=2000,[60]=3000},
    RankRule = {C = 20000, B = 40000, A = 60000},
    Scores = {Perfect = 1000, Great = 800, Good = 600},
    
    RankImg = {C = "Gloryhole_Bar_Img_C.png",
               B = "Gloryhole_Bar_Img_B.png",
               A = "Gloryhole_Bar_Img_A.png",
               S = "Gloryhole_Bar_Img_S.png"},
  
    ItemIcon = {[1] = "GloryHole_btn02_03.png",
                [2] = "GloryHole_btn02_04.png", 
                [3] = "GloryHole_btn02_06.png",
                [4] = "GloryHole_btn02_05.png"},
    ItemCCB = { [1] = "GloryHole_Play_item1.ccbi",
                [2] = "GloryHole_Play_item2.ccbi", 
                [3] = "GloryHole_Play_item3.ccbi"},
    itemPrice={[20001]=100,
               [20002]=100,
               [20004]=100,}
}
GameConfig.GUIDE_TYPE = {
    PLAY_H_STORY = 0,
    TALK = 1,
    TOUCH_HINT = 2,
    PLAY_OP_MOVIE = 3,
    OPEN_MASK = 4,
    POP_NEWBIE_PAGE = 5,
    NEXT_NEWBIE_STEP = 6,
    CALL_FUNC = 7,
    TOUCH_HINT_2 = 12,  -- 2-7編隊專用 需要判斷隊伍空位
    TOUCH_HINT_3 = 22,  -- 2-7編隊專用 需要判斷風5位置
    OPEN_MASK_WAIT_BATTLE_INIT = 14,
    OPEN_MASK_WAIT_BATTLE_ANI = 24,
}


GameConfig.summonPieceImg = {
    [1] = "SummonResult_PieceImg1.png",
    [2] = "SummonResult_PieceImg1.png",
    [3] = "SummonResult_PieceImg1.png",
    [4] = "SummonResult_PieceImg1.png",
    [5] = "SummonResult_PieceImg2.png",
    [6] = "SummonResult_PieceImg2.png",
}
GameConfig.summonTreasureImg = {
    [1] = "SummonResult_ItemImg1.png",
    [2] = "SummonResult_ItemImg1.png",
    [3] = "SummonResult_ItemImg1.png",
    [4] = "SummonResult_ItemImg1.png",
    [5] = "SummonResult_ItemImg2.png",
    [6] = "SummonResult_ItemImg3.png",
}
return GameConfig
