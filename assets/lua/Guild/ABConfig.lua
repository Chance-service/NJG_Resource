local ABConfig = {
  --公会争霸图文帮助配置
  HelpConfig = {
    [1] = "UI/PitureHelp/Pic08.png",
    [2] = "UI/PitureHelp/Pic05.png",
    [3] = "UI/PitureHelp/Pic06.png",
    [4] = "UI/PitureHelp/Pic07.png",
    [5] = "UI/PitureHelp/Pic01.png",
    [6] = "UI/PitureHelp/Pic02.png",
    [7] = "UI/PitureHelp/Pic09.png",
    [8] = "UI/PitureHelp/Pic03.png",
    [9] = "UI/PitureHelp/Pic04.png"
  },
  BetConfig = ConfigManager.getABBetCfg(),
  QuarterFinalsReward = ConfigManager.getABRankRewardCfg(),
  AlliancePic = {
    -- left = "UI/MainScene/UI/u_Camp1.png",
    -- right = "UI/MainScene/UI/u_Camp2.png"
    left = "UI/Common/Image/Image_GuildBattle_Attack.png",
    right = "UI/Common/Image/Image_GuildBattle_Defence.png"
  },
  QuarterFace = {
	 [1] = "UI/Common/Image/Image_ArenaRank_1.png",
    [2] = "UI/Common/Image/Image_ArenaRank_2.png",
    [3] = "UI/Common/Image/Image_ArenaRank_3.png",
    [4] = "UI/Common/Image/Image_ArenaRank_4.png",
    [5] = "UI/Common/Image/Image_ArenaRank_4.png",
    [6] = "UI/Common/Image/Image_ArenaRank_4.png",
  },
  FightPic = {
    -- [1] = "UI/MainScene/UI/u_Camp1.png",
    -- [2] = "UI/MainScene/UI/u_Camp2.png",
    -- [3] = "UI/MainScene/UI/u_Camp3.png",
    -- [4] = "UI/MainScene/UI/u_Camp4.png",
    [1] = "UI/Common/Image/Image_GuildBattle_Attack.png",
    [2] = "UI/Common/Image/Image_GuildBattle_Defence.png",
    [3] = "UI/Common/Image/Image_GuildBattle_Attack_Grey.png",
    [4] = "UI/Common/Image/Image_GuildBattle_Defence_Grey.png",
  },
  Battlefield = {
    [1] = {
        name = common:getLanguageString("@ABTeamName1"),
        attrId = 2103,
        value = 30
    },
    [2] = {
        name = common:getLanguageString("@ABTeamName2"),
        attrId = 2104,
        value = 30
    },
    [3] = {
        name = common:getLanguageString("@ABTeamName3"),
        attrId = 2009,
        value = 15
    }
  },
  InspireCostDiamond = { -- 鼓舞次数对应消耗钻石
    [0] = 20,
    [1] = 20,
    [2] = 20,
    [3] = 20,
    [4] = 20
  },
  InspireBloodEnhancePercent = { -- 鼓舞次数对应血量加成，单位百分比
    [0] = 10,
    [1] = 20,
    [2] = 30,
    [3] = 40,
    [4] = 50
  },
  InspireAttactEnhancePercent = { -- 鼓舞次数对应攻击加成，单位百分比
    [0] = 10,
    [1] = 20,
    [2] = 30,
    [3] = 40,
    [4] = 50
  },
  InspireRewardPercent = { -- 鼓舞次数对应奖励显示，单位百分比
    [0] = 0,
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 6,
    [7] = 7,
    [8] = 8,
    [9] = 9,
    [10] = 10,
    [11] = 11,
    [12] = 12,
    [13] = 13,
    [14] = 14,
    [15] = 15,
    [16] = 16,
    [17] = 17,
    [18] = 18,
    [19] = 19,
    [20] = 20,
    [21] = 21,
    [22] = 22,
    [23] = 23,
    [24] = 24,
    [25] = 25
  },
  InspireRewardPerTime = 1,
  WinColor = "0 255 255",
  LoseColor =  "192 192 192",
  --主页文本配置
  TexSetting = {
      mSelectionPeriod = {
        [0] = {tex = common:getLanguageString("@ABMainSession1"),visible = true},
        [101] = {tex = common:getLanguageString("@ABMainSession1"),visible = true},
        [102] = {tex = common:getLanguageString("@ABMainSession8",32),visible = true},
        [103] = {tex = common:getLanguageString("@ABMainSession3"),visible = true},
        [104] = {tex = common:getLanguageString("@ABMainSession8",16),visible = true},
        [105] = {tex = common:getLanguageString("@ABMainSession4"),visible = true},
        [106] = {tex = common:getLanguageString("@ABMainSession8",8),visible = true},
        [107] = {tex = common:getLanguageString("@ABMainSession5"),visible = true},
        [108] = {tex = common:getLanguageString("@ABMainSession8",4),visible = true},
        [109] = {tex = common:getLanguageString("@ABMainSession6"),visible = true},
        [110] = {tex = common:getLanguageString("@ABMainSession9"),visible = true},
        [201] = {tex = common:getLanguageString("@ABMainSession7"),visible = true},
      },
      mPeriodAction = {
        [0] = {tex = common:getLanguageString("@"),visible = false},
        [101] = {tex = common:getLanguageString("@ABMainSessionAct1",32),visible = true},
        [102] = {tex = common:getLanguageString("@ABMainSessionAct3"),visible = true},
        [103] = {tex = common:getLanguageString("@ABMainSessionAct1",16),visible = true},
        [104] = {tex = common:getLanguageString("@ABMainSessionAct3"),visible = true},
        [105] = {tex = common:getLanguageString("@ABMainSessionAct1",8),visible = true},
        [106] = {tex = common:getLanguageString("@ABMainSessionAct3"),visible = true},
        [107] = {tex = common:getLanguageString("@ABMainSessionAct1",4),visible = true},
        [108] = {tex = common:getLanguageString("@ABMainSessionAct3"),visible = true},
        [109] = {tex = common:getLanguageString("@ABMainSessionAct2"),visible = true},
        [110] = {tex = common:getLanguageString("@ABMainSessionAct3"),visible = true},
        [201] = {tex = common:getLanguageString("@ABMainSessionAct4"),visible = true},
      },
      mAgainstGuild = {
        [0] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle"),visible = true},
        [101] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle2",32),visible = true},
        [102] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle4"),visible = true},
        [103] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle2",16),visible = true},
        [104] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle4"),visible = true},
        [105] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle2",8),visible = true},
        [106] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle4"),visible = true},
        [107] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle2",4),visible = true},
        [108] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle4"),visible = true},
        [109] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle3"),visible = true},
        [110] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle5"),visible = true},
        [201] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle6"),visible = true},
      },
      mRoundNum = {
        [0] = {tex = common:getLanguageString("@EstimateAgainstGuildTitle"),visible = false},
        [101] = {tex = common:getLanguageString("@ABFightRound",32),visible = true},
        [102] = {tex = common:getLanguageString("@ABFightRound",32),visible = true},
        [103] = {tex = common:getLanguageString("@ABFightRound",16),visible = true},
        [104] = {tex = common:getLanguageString("@ABFightRound",16),visible = true},
        [105] = {tex = common:getLanguageString("@ABFightRound",8),visible = true},
        [106] = {tex = common:getLanguageString("@ABFightRound",8),visible = true},
        [107] = {tex = common:getLanguageString("@ABFightRound2"),visible = true},
        [108] = {tex = common:getLanguageString("@ABFightRound2"),visible = true},
        [109] = {tex = common:getLanguageString("@ABFightRound3"),visible = true},
        [110] = {tex = common:getLanguageString("@ABFightRound3"),visible = true},
        [201] = {tex = common:getLanguageString("@ABFightRound4"),visible = true},
      },
  }
}

return ABConfig