
local Const_pb = require("Const_pb")
local ElementConfig = {
    OpenLeveL = 70,
    ElementLevelRatioCfg = ConfigManager.getElementLevelRatioCfg(),
    LevelAttrRatioCfg = ConfigManager.getLevelAttrRatioCfg(),
    ElementAscendCfg = ConfigManager.getElementAscendCfg(),
    ElementLevelCfg = ConfigManager.getElementLevelCfg(),
    ElementSlotCfg = ConfigManager.getElementSlotCfg(),
    ElementsCfg = ConfigManager.getElementsCfg(),
    ElementCfg = ConfigManager.getElementCfg(),
    BuyPackageCount = 10,       -- 一次购买背包个数
    BuyPackageCost = 100,       -- 一次购买背包所需钻石数
    BuyPackageMaxSize = 200,    -- 最大数量
    AttrName = {
        [Const_pb.ICE_ATTACK] = "iceAttack",
        [Const_pb.ICE_DEFENCE] = "iceDefense",
        [Const_pb.FIRE_ATTACK] = "fireAttack",
        [Const_pb.FIRE_DEFENCE] = "fireDefense",
        [Const_pb.THUNDER_ATTACK] = "thunderAttack",
        [Const_pb.THUNDER_DENFENCE] = "thunderDefense",
        [Const_pb.ICE_ATTACK_RATIO] = "iceAttackRadio",
        [Const_pb.ICE_DEFENCE_RATIO] = "iceDefenseRadio",
        [Const_pb.FIRE_ATTACK_RATIO] = "fireAttackRadio",
        [Const_pb.FIRE_DEFENCE_RATIO] = "fireDefenseRadio",
        [Const_pb.THUNDER_ATTACK_RATIO] = "thunderAttackRadio",
        [Const_pb.THUNDER_DENFENCE_RATIO] = "thunderDefenseRadio",
        [Const_pb.STRENGHT] = "strenght",
        [Const_pb.AGILITY] = "agility",
        [Const_pb.INTELLECT] = "intellect",
        [Const_pb.STAMINA] = "stamina"

    }
}
return ElementConfig
