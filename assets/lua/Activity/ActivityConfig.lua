ACTIVITY_TYPE = {
    NEWPLAYER_LEVEL9 = 7,
    REWARD = 8,
    NEWPLAYER_LOGIN = 9,
    POPUP_SALE = 10,
}
ActivityConfig =
{
    -- 特典里面的活动类型
    SPECIAL_EDITION = 1,
    -- 新手里面的活动类型
    NOVICE = 4,
    -- 扭蛋里面的活动类型
    GASHAPON = 5,
    -- 限定里面的活动类型
    LIMIT = 6,
    -- 活躍度活動
    ACTIVE = 100,
    -- 大富翁活動
    MONOPOLY = 141,
    -- 海上尋寶
    PIRATE = 143,
    --------------------------------------------
    --沒有活動id
    -- 世界BOSS
    WORLD_BOSS = 997,
    -- 遠足
    EXPEDITION = 998,
    -- 修學旅行
    RAID = 999,


    -- 活动页面排列优先级order：福利活动1X，消耗活动2X，充值活动3X，开服活动4X
    [124] = {
        -- 猫みくじ
        -- openWay = "",
        image = "privilege_yueka_icon",
        -- page = "ActTimeLimit_124",
        -- order = 30,
        -- activityType = 1--
    },


    --    [133] =
    --    {
    --        -- 等级特惠礼包
    --        -- openWay = "",
    --        image = "privilege_yueka_icon",
    --    },

    [134] = {
        -- 周末福利
    },
    [83] = {
        -- 特典  ---- 月卡
        openWay = "",
        image = "privilege_yueka_icon",
        page = "MonthCardPage",
        order = 30,
        activityType = 1--
    },


    -------------------------------------------


    [129] = {
        -- 消耗型周卡
        openWay = "",
        image = "Activity_Icon_22",
        page = "MonthCardPage_130",
        order = 28,
        activityType = 1--
    },

    [130] = {
        -- 消耗型月卡
        openWay = "",
        image = "Activity_Icon_23",
        page = "MonthCardPage_130",
        order = 29,
        activityType = 1--
    },

    -------------------------------------------



    [84] = {
        -- 首充奖励
        openWay = "",
        image = "privilege_shouchongjiangli_icon",
        page = "FirstChargePage",
        order = 10,
        activityType = 1-- 是新的活动类型
    },
    [97] = {
        -- 成长基金
        openWay = "",
        image = "privilege_chengzhangjinjin_icon",
        page = "GrowthFundPage",
        order = 35,
        activityType = 1
    },
    [94] = {
        -- 福袋
        page = "DiscountGiftPage",
        -- image   = "UI/Common/Activity/Act_FT_Common/Act_FT_Act5",
        image = "privilege_yonghuayinyue_icon",

        -- image	= "UI/Activities/u_icoqyWeekCard",
        order = 10,
        activityType = 1,
    },

    [24] = {
        -- 周卡
        openWay = "",
        image = "privilege_zhouka_icon",
        page = "MonthCardPage",
        order = 30,
        activityType = 1--
    },
    [95] = {
        -- VIP礼包
        openWay = "",
        image = "privilege_viplibao_icon",
        -- image   = "UI/Common/Activity/Act_FT_Common/Act_FT_Act4",
        page = "VIPGiftPage",
        order = 40,
        activityType = 1-- 是新的活动类型
    },
    [23] = {
        -- VIP特权
        openWay = "push",
        image = "privilege_viptequan_icon",
        page = "VipWelfarePage",
        order = 50,
        dict = "@Act_VipWelfarePage_Title",
        activityType = 1,
    },

    [126] = {
        -- 新手天降元宝
        openWay = "",
        image = "Activity_Icon_20",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_1.png",
        page = "ActTimeLimit_126",
        bannerShowTime = 3,
        order = 39,
        activityType = 4--
    },
    [82] = {
        -- 新手打折 学割XXX
        openWay = "",
        image = "Activity_Icon_6",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_1.png",
        page = "RechargeDiscountPage",
        bannerShowTime = 3,
        order = 40,
        activityType = 4--
    },
    [115] = {
        -- 新手扭蛋
        openWay = "",
        image = "Activity_Icon_5",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_1.png",
        page = "NoviceGashaponPage",
        bannerShowTime = 3,
        order = 40,
        activityType = 4--
    },
    [3] = {
        -- 连续充值
        openWay = "change",
        image = "Activity_Icon_7",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_2.png",
        page = "ContinueRecharge",
        bannerShowTime = 3,
        order = 41,
        dict = "@Act_RechargeRebatePage_Title",
        activityType = 4,
        items = {
            -- *********fmt:	[id] = {d = 天数, r =	奖励id}*******
            [1] = { d = 1, r = 1 },
            [2] = { d = 2, r = 2 },
            [3] = { d = 3, r = 3 },
            [4] = { d = 4, r = 4 },
            [5] = { d = 5, r = 5 },
            [6] = { d = 6, r = 6 },
            [7] = { d = 7, r = 7 }
        }
    },
    [101] = {
        -- KingPower(百花美人)  魔法召唤
        page = "KingPowerPage",
        image = "Activity_common_baihuameiren_Icon",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_18.png",
        bannerShowTime = 10,
        order = 91,
        activityType = 5
    },
    [90] = {
        -- 射击游戏   制服卖场
        openWay = "push",
        image = "Activity_common_shejiyouxi_Icon",
        page = "ShootActitityPage",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_4.png",
        bannerShowTime = 20,
        order = 92,
        activityType = 5
    },

    [125] = {
        -- 武器屋  酒馆
        openWay = "push",
        image = "Activity_Icon_18",
        page = "ActTimeLimit_125",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_4.png",
        bannerShowTime = 20,
        order = 93,
        activityType = 5
    },

    [36] = {
        -- 西施的祝福   七福神
        page = "TreasureRaiderPage",
        order = 95,
        image = "Activity_common_xishizhufu_Icon",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        activityType = 5
    },

    [21] = {
        -- 单笔充值（充值领好礼）  每日xx    每日チャージ
        openWay = "change",
        page = "DailyOnceRecharge",
        order = 30,
        image = "Activity_Icon_9",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_8.png",
        bannerShowTime = 3,
        activityType = 6
    },
    [6] = {
        -- 消费有礼    奖学金
        openWay = "change",
        image = "Activity_Icon_4",
        page = "ExpendAddUpPage",
        order = 34,
        dict = "@Act_RechargeConsumptionPage_Title",
        items = {
            -- *********fmt:	[id] = {n = 数量, r =	奖励id}*******
            [1] = { n = 600, r = 60001 },
            [2] = { n = 2000, r = 60002 },
            [3] = { n = 5000, r = 60003 },
            [4] = { n = 10000, r = 60004 },
            [5] = { n = 20000, r = 60005 },
            [6] = { n = 50000, r = 60006 }
        },
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_15.png",
        bannerShowTime = 3,
        activityType = 6
    },

    [119] = {
        -- 消費還元
        page = "ActTimeLimit_119",
        --
        order = 25,
        image = "Activity_Icon_11",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        activityType = 6
    },


    [118] = {
        -- 累計チャージ
        page = "ActTimeLimit_118",
        --
        order = 31,
        image = "Activity_Icon_12",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        activityType = 6
    },


    [106] = {
        -- 天降元宝   心愿成就
        page = "WelfareGoldPage",
        image = "Activity_Icon_3",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_25.png",
        bannerShowTime = 10,
        order = 1,
        activityType = 6
    },



    [26] = {
        -- 超学园祭
        -- openWay = "change",
        page = "QiXiXianGou",
        -- "TimeLimitPurchasingPage",
        image = "Activity_Icon_15",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_5.png",
        bannerShowTime = 10,
        order = 33,
        activityType = 6
    },

    [127] = {
        --   武器召唤师
        page = "ActTimeLimit_127",
        --
        order = 16,
        image = "Activity_Icon_19",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        -- isTimeLimitLuckDrawCard = true,
        activityType = 5
    },

    ---------------------------------抽卡活动---------------------------------------------------
    [139] = {
        --   四个皮肤
        page = "ActTimeLimit_139",
        order = 13,
        image = "Activity_Icon_139",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },


    [128] = {
        --   癒し彼女   治愈彼女
        page = "ActTimeLimit_128",
        order = 13,
        image = "Activity_Icon_21",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },


    [111] = {
        -- 妄想彼女
        page = "GamblingMachine",
        image = "Activity_Icon_2",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_36.png",
        bannerShowTime = 10,
        order = 14,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },
    [116] = {
        --   レンタル彼女
        page = "ActTimeLimit_116",
        --
        order = 12,
        image = "Activity_Icon_13",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },

    [123] = {
        --   節慶彼女
        page = "ActTimeLimit_123",
        --
        order = 11,
        image = "Activity_Icon_17",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },

    [117] = {
        -- 抽皮肤    仮装パーティ
        page = "ActSkinDraw",
        --
        order = 15,
        image = "Activity_Icon_10",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },
    [99] = {
        -- 星占师
        page = "TreasureRaiderPageNew",
        image = "Activity_Icon_1",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_37.png",
        bannerShowTime = 10,
        order = 15,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },

    [135] = {
        -- 星占师 抽皮肤
        page = "ActTimeLimit_135",
        --
        order = 12,
        image = "Activity_Icon_1",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_12.png",
        bannerShowTime = 10,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },

    [98] = {
        -- 幸运副将    美人计   生徒手账
        page = "LuckyMercenaryPage",
        image = "Activity_Icon_8",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_14.png",
        bannerShowTime = 5,
        order = 17,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },
    [120] = {
        -- 予行恋習
        -- openWay = "change",
        page = "ActTimeLimit_120",
        -- "TimeLimitPurchasingPage",
        image = "Activity_Icon_14",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_5.png",
        bannerShowTime = 10,
        order = 6,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },

    [121] = {
        -- 束缚彼女
        page = "ActTimeLimit_121",
        image = "Activity_Icon_16",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_36.png",
        bannerShowTime = 10,
        order = 13,
        isTimeLimitLuckDrawCard = true,
        activityType = 5
    },
    ------------------------------------------------------------------------------------------





    ------------------------------------------

    [131] = {
        -- 累计连续充值活动
        openWay = "change",
        page = "ActTimeLimit_131",
        -- image = "Activity_Icon_21",
        image = "Activity_Icon_24",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_6.png",
        bannerShowTime = 3,
        order = 30,
        activityType = 6,
        items = {
            -- *********fmt:	[id] = {d = 天数, r =	奖励id}*******
            [1] = { d = 1, r = 13101 },
            [2] = { d = 2, r = 13102 },
            [3] = { d = 3, r = 13103 },
            [4] = { d = 4, r = 13104 },
            [5] = { d = 5, r = 13105 },
            [6] = { d = 6, r = 13106 },
            [7] = { d = 7, r = 13107 },
        }
    },

    [2] = {
        -- 每日返利（每日累计充值返利）  每日累計チャージ
        openWay = "change",
        page = "AccumulativeRecharge",
        -- image = "Activity_Icon_21",
        image = "Activity_Icon_25",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_6.png",
        bannerShowTime = 3,
        order = 31,
        activityType = 6,
        items = {
            -- *********fmt:	[id] = {c = 充值数量, r =	奖励id}*******
            [1] = { c = 60, r = 27 },
            [2] = { c = 480, r = 28 },
            [3] = { c = 1000, r = 29 },
            [4] = { c = 2000, r = 2901 },
            [5] = { c = 5000, r = 2902 },
            [6] = { c = 10000, r = 2903 },
        }
    },


    [20] = {
        -- 新手活动（新手8天专享翻倍活动）
        openWay = "change",
        image = "UI/Activities/u_icoqyNoviceActivities.png",
        page = "DailyLogin",
        order = 41,
        dict = "@Act_NoviceActivitiesPage_Title",
    },
    [22] = {
        -- 充值返利
        openWay = "change",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act3",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_3.png",
        page = "RechargeRebatePage",
        bannerShowTime = 3,
        order = 42,
    },
    [28] = {
        -- 充值返利2
        openWay = "change",
        image = "UI/Activities/u_icoqyRechargeReturnDiamond.png",
        page = "RechargeRebatePage",
        order = 24,
        dict = "@Act_RechargeReturnDiamondPage_Title",
    },

    [7] = {
        -- 中秋欢乐兑（兑字活动）
        openWay = "change",
        image = "UI/Activities/u_icoqyMid-autumn.png",
        page = "ExchangeActivity",
        order = 21,
        dict = "@Mid-autumnTitle",
        items = {
            -- *********fmt:	[id] = {c = 消耗id, r =	奖励id, t = 兑换次数}<<t = -1 表示无限制 >> *******
            [1] = { c = 1, r = 11, t = - 1 },
            [2] = { c = 2, r = 12, t = - 1 },
            [3] = { c = 3, r = 13, t = - 1 },
            [4] = { c = 4, r = 14, t = - 1 }
        }
    },
    [9] = {
        -- 限时翻倍（充值翻倍活动）
        openWay = "push",
        image = "UI/Activities/u_icoqyTimedDouble.png",
        page = "LargeRechargeRebate",
        order = 35,
        dict = "@Act_TimedDouble_Title",
    },
    [10] = {
        -- 假日秘宝（宝箱活动）
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act10",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_10.png",
        bannerShowTime = 10,
        page = "HolidayTreasure",
        order = 26,
        items = {
            -- [id] = 奖励id
            [1] = 31,
            [2] = 32
        }
    },
    [11] = {
        -- 新人福利（公测兑字及公共兑换码）
        openWay = "change",
        image = "UI/Activities/u_icoqyNewWelfare.png",
        page = "ExchangeBetaWord",
        order = 42,
        dict = "@Act_NewWelfarePage_Title",
    },

    -- [24] = { --周卡
    -- 	openWay = "change",
    -- 	image   = "UI/Common/Activity/Act_FT_Common/Act_FT_Act7",
    -- 	--image	= "privilege_zhouka_icon",
    -- 	page	= "WeeklyCardPage",
    -- 	order	= 36,
    -- 	dict	= "@Act_WeekCardPage_Title",
    -- 	items	= {
    -- 		--这是第一类周卡（10元）的奖励id  d是第几天，r是奖励id  下面是第二类
    -- 		[1] = {
    -- 			BuyRewardItem = {r = 24001},
    -- 			DailyRewardItem = {
    -- 				 [1] = {d = 1, 	r = 24001},
    -- 				 [2] = {d = 2, 	r = 24001},
    -- 				 [3] = {d = 3, 	r = 24001},
    -- 				 [4] = {d = 4, 	r = 24001},
    -- 				 [5] = {d = 5, 	r = 24001},
    -- 				 [6] = {d = 6, 	r = 24001},
    -- 				 [7] = {d = 7, 	r = 24001}
    -- 			}
    -- 		},
    -- 		--
    -- 		[2] = {
    -- 			BuyRewardItem = {r = 24002},
    -- 			DailyRewardItem = {
    -- 				 [1] = {d = 1, 	r = 24002},
    -- 				 [2] = {d = 2, 	r = 24002},
    -- 				 [3] = {d = 3, 	r = 24002},
    -- 				 [4] = {d = 4, 	r = 24002},
    -- 				 [5] = {d = 5, 	r = 24002},
    -- 				 [6] = {d = 6, 	r = 24002},
    -- 				 [7] = {d = 7, 	r = 24002}
    -- 			}
    -- 		}
    -- 	},




    [25] = {
        -- 远征
        openWay = "push",
        image = "UI/Activities/u_icoqyExpeditionMaterialsCollection.png",
        -- "Item/Welfare04.png",--
        page = "ExpeditionMaterialCollectionPage",
        -- "QiXiQiYuan",--
        order = 4,
        -- 1,--
        dict = "@Act_ExpeditionMaterialsCollectioge_Title",
        items = {
            -- [id] = 奖励id  r是奖励id号  q是达到多少贡献才能领取
            stageInfo = {
                [1] = { r = 41, q = 800, p = "UI/Activities/ExpeditionMaterialsCollection/u_ContinuousLandingBG04.png" },
                [2] = { r = 42, q = 1200, p = "UI/Activities/ExpeditionMaterialsCollection/u_ContinuousLandingBG05.png" },
                [3] = { r = 43, q = 1600, p = "UI/Activities/ExpeditionMaterialsCollection/u_ContinuousLandingBG06.png" },
                [4] = { r = 44, q = 2800, p = "UI/Activities/ExpeditionMaterialsCollection/u_ContinuousLandingBG07.png" }
            },
            -- 这是排行奖励配置，rankT和rankB是多少名到多少名  例如第一名 rankT = rankB = 1  4~10名奖励  rankT = 4 rankB = 10
            rankReward = {
                [1] = { rankT = 1, rankB = 1, r = 51 },
                [2] = { rankT = 2, rankB = 3, r = 52 },
                [3] = { rankT = 4, rankB = 10, r = 53 },
                [4] = { rankT = 11, rankB = 20, r = 54 },
                [5] = { rankT = 21, rankB = 50, r = 55 },
                [6] = { rankT = 51, rankB = 99, r = 56 }
            },
            -- 这是贡献道具配置，itemType是道具类型，item是道具id，reward是捐献一个获得多少贡献值
            donationItem = {
                [1] = { itemType = 30000, item = 11137, reward = 5 },
                [2] = { itemType = 30000, item = 11138, reward = 30 },
                [3] = { itemType = 30000, item = 11139, reward = 100 }
            },

            tabPicConfig = {
                notOpen = "UI/Activities/ExpeditionMaterialsCollection/u_ContinuousLandingContent0#v1#_3.png",
                open = "UI/Activities/ExpeditionMaterialsCollection/u_ContinuousLandingContent0#v1#_1.png",
                complete = "UI/Activities/ExpeditionMaterialsCollection/u_ContinuousLandingContent0#v1#_2.png"

            }
        },
        -- activityType	= 2	--是新的活动类型
    },


    [5] = {
        -- 微信分享
        openWay = "click",
        image = "UI/Activities/u_icoqyNewWelfare.png",
        page = "ExpeditionMaterialCollectionPage",
        order = 38,
        dict = "@Act_RechargeRebatePage_Title",b
    },


    -- [19] = { -- 全服快速战斗钻石减半

    -- },

    [27] = {
        -- 累计登陆
        openWay = "change",
        page = "CumulativeLoginPage",
        order = 10,
        dict = "@Act_CumulativeLandPage_Title",
        image = "UI/Common/Activity/Act_TL_Common/Activity_Icon_27",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_7.png",
        bannerShowTime = 10,
        activityType = 6
    },


    [29] = {
        -- 宝石工坊
        openWay = "push",
        image = "UI/Activities/u_icoqyGemWorkShop.png",
        page = "GemCompoundPage",
        order = 27,
        dict = "@Act_GemCompoundPage_Title",
    },

    [30] = {
        -- 疯狂转盘
        openWay = "push",
        image = "UI/Activities/u_icoqyInsaneTurntable.png",
        page = "RoulettePage",
        order = 34,
        dict = "@Act_RoulettePage_Title",
    },
    [31] = {
        -- 幸运宝箱
        openWay = "push",
        image = "UI/Activities/u_icoqyLuckyTreasure.png",
        page = "LuckyBoxPage",
        order = 11,
        dict = "@Act_LuckyBoxPage_Title",
    },
    [35] = {
        -- 寻宝大搜索
        openWay = "push",
        image = "UI/Activities/u_icoqySnowTreasureHunt.png",
        page = "SnowTreasurePage",
        order = 28,
        reward = {
            -- [index] = 奖励id 通关奖励
            [1] = 35101,
            [2] = 35102,
            [3] = 35103,
            [4] = 35104
        },
        exchangeId = {
            [1] = 10030,
            [2] = 10031,
            [3] = 10032,
            [4] = 10033
        },
        exchangeRewardId = 35301,
        dict = "@Act_SnowTreasurePage_Title",
    },

    [37] = {
        -- 部族的奖励
        openWay = "push",
        image = "UI/Activities/u_icoqyTribeAwards.png",
        page = "TribeAwardsPage",
        order = 11,
        dict = "@Act_TribeAwardsPage_Title",
    },
    [38] = {
        -- 财神献礼
        openWay = "push",
        image = "UI/Activities/u_icoqyMammonGift.png",
        page = "MammonGiftPage",
        order = 11,
        dict = "@Act_MammonGiftPage_Title",
    },
    [40] = {
        -- 银月酒吧
        page = "FindTreasurePage",
        order = 24,
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act13",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_13.png",
        bannerShowTime = 10,
    },
    [41] = {
        -- 财富俱乐部
        openWay = "push",
        image = "UI/Activities/u_icoqyWealthClub.png",
        page = "WealthClubPage",
        order = 11,
        dict = "@Act_WealthClubPage_Title",
    },
    [42] = {
        -- 一起抢红包
        openWay = "push",
        image = "UI/Activities/u_icoqyTogetherCompetingRedEnvelopes.png",
        page = "TogetherCompetingRedPage",
        order = 11,
        dict = "@Act_TogetherCompetingPage_Title",
    },
    [44] = {
        -- 排行献礼
        openWay = "change",
        image = "UI/Activities/u_icoqyRankingGift.png",
        page = "RankGiftPage",
        order = 11,
        dict = "@Act_RankingGiftPage_Title",
    },
    [45] = {
        -- 终身月卡
        openWay = "push",
        image = "UI/Activities/u_icoqyLifelongCard.png",
        page = "LifelongCardPage",
        orer = 39,
        dict = "@Act_RankingGiftPage_Title",
    },
    -- [88] = { -- 挂机英雄下载
    --     openWay = "push",
    --     image   = "UI/Activities/u_icoqyLifelongCard.png",
    --     page    = "GoDownGuaJiYingxiongPage",
    --     orer    = 1
    -- },
    [81] = {
        -- 黑市商人
        openWay = "change",
        image = "UI/Activities/u_icoqySteriousShop.png",
        page = "SteriousShop",
        orer = 39
    },





    --[[
	[85] = { -- 七夕限时限购
        openWay = "",
        image   = "Item/Welfare06.png",
        page    = "QiXiXianGou",
        order    = 3,
		activityType	= 2	--是新的活动类型
    },--]]
    [86] = {
        -- 神秘商店
        image = "Activity_Icon_26",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_11.png",
        bannerShowTime = 3,
        page = "GoodsExchangePage_86",
        -- 之前是QiXiDuiHuan
        order = 31,
        -- activityType = 6
    },
    [136] = {
        -- 交换所
        image = "Activity_Icon_26",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_11.png",
        bannerShowTime = 3,
        page = "GoodsExchangePage",
        -- 之前是QiXiDuiHuan
        order = 32,
        activityType = 6
    },

    [137] =
    {
        --        -- 神秘商店
        --        image = "Activity_Icon_26",
        --        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_11.png",
        --        bannerShowTime = 3,
        --        page = "GoodsExchangePage",
        --        -- 之前是QiXiDuiHuan
        --        order = 32,
        --        activityType = 6
    },

    [87] = {
        -- 每日签到
        openWay = "",
        image = "Item/Welfare07.png",
        page = "DailyQuest",
        order = 1,
        -- activityType = 3-- 是新的活动类型
    },
    [88] = {
        -- 鬼节捞鱼
        page = "CatchFish",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act33",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_33.png",
        bannerShowTime = 10,
        order = 12,
    },
    [89] = {
        -- 装备十连抽
        page = "GodEquipBuildPage",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act20",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_20.png",
        bannerShowTime = 10,
        order = 19,
    },

    [91] = {
        -- 新雪地大搜索，魔王
        openWay = "push",
        page = "NewSnowTreasurePage",
        image = "UI/Common/Activity/Act_TL_Common/Activity_Icon_10",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_9.png",
        bannerShowTime = 10,
        order = 12,
        activityType = 5
    },


    [96] = {
        -- 特典里面的  礼包
        openWay = "",
        -- image   = "UI/Common/Activity/Act_FT_Common/Act_FT_Act7",
        image = "privilege_libao_icon",
        page = "WeekCardPage",
        order = 20,
        -- activityType = 1-- 是新的活动类型activityType
    },



    [100] = {
        -- 聊天框皮肤购买
        page = "ChatSkinBuyPage",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act17",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_17.png",
        bannerShowTime = 3,
        order = 21,
    },

    [102] = {
        -- 新的碎片合成活动
        page = "TimeLimitFragmentExchangePage",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act21",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_21.png",
        bannerShowTime = 3,
        order = 22,
    },
    [103] = {
        -- 鲜花的兑换活动
        page = "TimeLimitFairyBlessPage",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act22",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_22.png",
        bannerShowTime = 3,
        order = 29,
    },
    [104] = {
        -- 美女信物活动
        page = "TimeLimitMaidenEncounterPage",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act23",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_23.png",
        bannerShowTime = 10,
        order = 13,
    },
    [105] = {
        -- 鬼节活动
        page = "ObonMainPage",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act24",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_24.png",
        bannerShowTime = 10,
        order = 11,
    },

    [107] = {
        -- UR活动
        page = "TreasureRaiderDiscountPage",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act35",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_35.png",
        bannerShowTime = 10,
        order = 11,
    },
    [108] = {
        -- 大转盘活动
        page = "TurntableMainPage",
        image = "UI/Common/Activity/Act_TL_Common/Act_TL_Act27",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_27.png",
        bannerShowTime = 10,
        order = 11,
    },
    [109] = {
        -- 万圣节活动
        page = "HalloweenMainPage",
        image = "Activity_Icon_28",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_28.png",
        bannerShowTime = 10,
        order = 11,
        activityType = 5
    },
    [141] = {
        page = "MonopolyGamePage",
        activityType = 141
    },
    [142] = {
        -- 交换所2New
        image = "Activity_Icon_142",
        mainSceneImage = "UI/Common/Activity/Act_TL_Common/Act_TL_ActBanner_11.png",
        bannerShowTime = 3,
        page = "GoodsExchangePage_New",
        -- 之前是QiXiDuiHuan
        order = 1,
        activityType = 6
    },
    [143] = {
        page = "ActTimeLimit_143Pirate",
        activityType = 143
    },
    [144] = {
        page = "ActTimeLimit_144LittleTest",
        activityType = 144
    },
    [997] = {
        activityType = 997
    },
    [998] = {
        activityType = 998
    },
    [999] = {
        activityType = 999
    },
    [99999] = {
        image = "UI/Activities/u_icoqyNotOpend.png",
        dict = "@ActivitiesContent_Title",
    },
--------------------------------------------------------------
-- Ninja Girl
--------------------------------------------------------------
    [Const_pb.ACCUMULATIVE_LOGIN_SEVEN] = {
        -- 七日任務
        activityType = ACTIVITY_TYPE.NEWPLAYER_LEVEL9,
        page = "MissionDay7Page",
        image = "SubBtn_7dayMission"
    },
   --[Const_pb.ACTIVITY148_MARRY_GAME] = {
   --    -- 小瑪莉
   --    activityType = ACTIVITY_TYPE.NEWPLAYER_LEVEL9,
   --    page = "ActTimeLimit_148LittleMary",
   --    image = "SubBtn_Lottery"
   --},
    --[Const_pb.ACTIVITY149_THREE_DAY] = {
    --    -- 三日任務
    --    activityType = ACTIVITY_TYPE.NEWPLAYER_LEVEL9,
    --    page = "ActTimeLimit_149ThreeQuest",
    --    image = "SubBtn_FreeHero"
    --},
    --[Const_pb.ACTIVITY150_LIMIT_GIFT] = {
    --    -- 新手禮包
    --    activityType = ACTIVITY_TYPE.NEWPLAYER_LEVEL9,
    --    page = "ActTimeLimit_150Gift",
    --    image = "SubBtn_Phantom"
    --},
    --- 彈跳禮包
    [Const_pb.ACTIVITY132_LEVEL_GIFT] = {
        -- 等級禮包
        activityType = ACTIVITY_TYPE.POPUP_SALE,
        page = "ActPopUpSale.ActPopUpSaleSubPage_132",
        isShowFn = function()
            require(ActivityConfig[Const_pb.ACTIVITY132_LEVEL_GIFT].page)
            local data = ActPopUpSaleSubPage_132_getIsShowMainSceneIcon()
            return data.isShowIcon
        end,
        isResident = true,
        isShowBattle = true,
    },
    [Const_pb.ACTIVITY151_STAGE_GIFT] = {
        -- 關卡禮包
        activityType = ACTIVITY_TYPE.POPUP_SALE,
        page = "ActPopUpSale.ActPopUpSaleSubPage_151",
        isShowFn = function()
            require(ActivityConfig[Const_pb.ACTIVITY151_STAGE_GIFT].page)
            local data = ActPopUpSaleSubPage_151_getIsShowMainSceneIcon()
            return data.isShowIcon
        end,
        isResident = true,
        isShowBattle = true,
    },
    --[Const_pb.ACTIVITY169_JumpGift] = {
    --    -- 新年禮包
    --    activityType = ACTIVITY_TYPE.POPUP_SALE,
    --    page = "ActPopUpSale.ActPopUpSaleSubPage_169",
    --    isShowFn = function()
    --        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
    --        local data = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(169)
    --        return data.isShowIcon
    --    end,
    --    isResident = false,
    --},
    --[Const_pb.ACTIVITY170_JumpGift] = {
    --    -- 情人節禮包
    --    activityType = ACTIVITY_TYPE.POPUP_SALE,
    --    page = "ActPopUpSale.ActPopUpSaleSubPage_170",
    --    isShowFn = function()
    --        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
    --        local data = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(170)
    --        return data.isShowIcon
    --    end,
    --    isResident = false,
    --},
    ----- 新手活動
    [Const_pb.ACTIVECOMPLIANCE] = {
        -- 新手8天登入
        activityType = ACTIVITY_TYPE.NEWPLAYER_LOGIN,
        page = "LivenessPage",
    },
    --- 福袋
    [Const_pb.ACCUMULATIVE_LOGIN_SIGNED] = {
        -- 30天登录
        activityType = ACTIVITY_TYPE.REWARD,
        page = RewardSubPage_DayLogin30,
    },
    [Const_pb.ACTIVITY155_ACHIEVE_LEVEL] = {
        -- 等級成就
        activityType = ACTIVITY_TYPE.REWARD,
        page = RewardSubPage_Achv_Level,
    },
    [Const_pb.ACTIVITY156_ACHIEVE_FIGHTVALUE] = {
        -- 戰力成就
        activityType = ACTIVITY_TYPE.REWARD,
        page = RewardSubPage_Achv_Power,
    },
    [Const_pb.ACTIVITY159_VIP_POINT] = {
        -- VIPPoint             
    },
    [Const_pb.ACTIVITY160_NP_CONTINUE_RECHARGE] = {
        --FirstRecgarge
    },
    [Const_pb.ACTIVITY161_SUPPORT_CALENDER] = {
        --SUPPORT_CALENDER
    },
    [Const_pb.ACTIVITY162_GROWTH_LV] = {
        --GrowthBundle
    },
    [Const_pb.ACTIVITY175_Glory_Hole] = {
        --GloryHole
    },
    [Const_pb.ACTIVITY177_Failed_Gift] = {
        -- 戰敗禮包
        activityType = ACTIVITY_TYPE.POPUP_SALE,
        page = "ActPopUpSale.ActPopUpSaleSubPage_177",
        isShowFn = function()
            require(ActivityConfig[Const_pb.ACTIVITY177_Failed_Gift].page)
            local data = ActPopUpSaleSubPage_177_getIsShowMainSceneIcon()
            return data.isShowIcon
        end,
        isResident = false,
        isShowBattle = true,
    },
   -- [Const_pb.ACTIVITY181_JumpGift] = {
   --    activityType = ACTIVITY_TYPE.POPUP_SALE,
   --    page = "ActPopUpSale.ActPopUpSaleSubPage_181",
   --    isShowFn = function()
   --        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
   --        local data = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(181)
   --        return data.isShowIcon
   --    end,
   --    isResident = false,
   --},
   --    [Const_pb.ACTIVITY182_JumpGift] = {
   --    activityType = ACTIVITY_TYPE.POPUP_SALE,
   --    page = "ActPopUpSale.ActPopUpSaleSubPage_182",
   --    isShowFn = function()
   --         require("ActPopUpSale.ActPopUpSaleSubPage_Content")
   --        local data = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(182)
   --        return data.isShowIcon
   --    end,
   --    isResident = false,
   --},
   --  [Const_pb.ACTIVITY183_JumpGift] = {
   --  activityType = ACTIVITY_TYPE.POPUP_SALE,
   --  page = "ActPopUpSale.ActPopUpSaleSubPage_183",
   --  isShowFn = function()
   --       require("ActPopUpSale.ActPopUpSaleSubPage_Content")
   --      local data = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(183)
   --      return data.isShowIcon
   --  end,
   --  isResident = false,
   --},
   --  [Const_pb.ACTIVITY184_JumpGift] = {
   --  activityType = ACTIVITY_TYPE.POPUP_SALE,
   --  isShowFn = function()
   --       require("ActPopUpSale.ActPopUpSaleSubPage_Content")
   --      local data = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(184)
   --      return data.isShowIcon
   --  end,
   --  isResident = false,
   --},
   --  [Const_pb.ACTIVITY185_JumpGift] = {
   --  activityType = ACTIVITY_TYPE.POPUP_SALE,
   --  isShowFn = function()
   --       require("ActPopUpSale.ActPopUpSaleSubPage_Content")
   --      local data = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(185)
   --      return data.isShowIcon
   --  end,
   --  isResident = false,
   --},
   -- [Const_pb.ACTIVITY186_JumpGift] = {
   --  activityType = ACTIVITY_TYPE.POPUP_SALE,
   --  isShowFn = function()
   --       require("ActPopUpSale.ActPopUpSaleSubPage_Content")
   --      local data = ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(186)
   --      return data.isShowIcon
   --  end,
   --  isResident = false,
   --},
     [Const_pb.ACTIVITY187_MaxJump] = {
      activityType = ACTIVITY_TYPE.POPUP_SALE,
      isShowFn = function()
        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
        return ActPopUpSaleSubPage_Content_isShow()
      end,
    },
    [Const_pb.ACTIVITY192_RechargeBounce] = {
        -- 戰力成就
        activityType = ACTIVITY_TYPE.REWARD,
        page = RewardSubPage_Recharge_Bonus,
    },
    [Const_pb.ACTIVITY193_SingleBoss] = {
        -- 單人強敵
    },
}
