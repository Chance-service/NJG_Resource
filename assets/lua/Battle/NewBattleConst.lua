NewBattleConst = NewBattleConst or {}

--��������
NewBattleConst.CHARACTER_TYPE = {
    LEADER = 1,
	HERO = 2,
	MONSTER = 3,
	SPRITE = 4,
	WORLDBOSS = 5,
}
--���⪬�A
NewBattleConst.CHARACTER_STATE = {
    INIT = 0, --��l�Ƥ�
    WAIT = 1, --�ݾ����A
    MOVE = 2, --���ʤ�
    ATTACK = 3, --�����ʧ@��
    HURT = 4,    --�����ʧ@��
    DYING = 5,   --���`�ʧ@��
    DEATH = 6,    --�w���`
    REBIRTH = 7,    --���ͤ�
}
--�����ݩ�
NewBattleConst.ELEMENT = {
    NONE = 0, FIRE = 1, WATER = 2, NATURE = 3, LIGHT = 4, DARK = 5
}
--����¾�~
NewBattleConst.JOB = {
    NONE = 0, TANK = 1, WARRIOR = 2, MAGE = 3, SUPPORTER = 4
}
--�԰��������
NewBattleConst.BATTLE_DATA = {
    MAX_HP = 1, PRE_HP = 2, HP = 3, MAX_MP = 4, PRE_MP = 5, MP = 6, PRE_SHIELD = 7, SHIELD = 8, IS_PHY = 9, STR = 10, INT = 11, AGI = 12, STA = 13,
    PHY_PENETRATE = 14, MAG_PENETRATE = 15, RECOVER_HP = 16, CRI_DMG = 17, CRI_RESIST = 18,
    MOVE_SPD = 19, RUN_SPD = 20, WALK_SPD = 21, RANGE = 22, NEED_RUN = 23, COLD_DOWN = 24, ELEMENT = 25,
    ATK_MP = 26, DEF_MP = 27, CLASS_CORRECTION = 28, SKILL_MP = 29,
    PHY_ATK = 30, MAG_ATK = 31, PHY_DEF = 32, MAG_DEF = 33, CRI = 34, HIT = 35, DODGE = 36, IMMUNITY = 37,
}
--�԰�������ƹw�]��
NewBattleConst.DEFAULT_BATTLE_DATA = {
    [NewBattleConst.BATTLE_DATA.MAX_HP] = 100,
    [NewBattleConst.BATTLE_DATA.PRE_HP] = 100,
    [NewBattleConst.BATTLE_DATA.HP] = 100,
    [NewBattleConst.BATTLE_DATA.MAX_MP] = 100,
    [NewBattleConst.BATTLE_DATA.PRE_MP] = 0,
    [NewBattleConst.BATTLE_DATA.MP] = 0,
    [NewBattleConst.BATTLE_DATA.PRE_SHIELD] = 0,
    [NewBattleConst.BATTLE_DATA.SHIELD] = 0,
    [NewBattleConst.BATTLE_DATA.IS_PHY] = false,
    [NewBattleConst.BATTLE_DATA.STR] = 10,
    [NewBattleConst.BATTLE_DATA.INT] = 10,
    [NewBattleConst.BATTLE_DATA.AGI] = 10,
    [NewBattleConst.BATTLE_DATA.STA] = 10,
    [NewBattleConst.BATTLE_DATA.PHY_PENETRATE] = 0,
    [NewBattleConst.BATTLE_DATA.MAG_PENETRATE] = 0,
    [NewBattleConst.BATTLE_DATA.RECOVER_HP] = 0,
    [NewBattleConst.BATTLE_DATA.CRI_DMG] = 0.0,
    [NewBattleConst.BATTLE_DATA.CRI_RESIST] = 0.0,
    [NewBattleConst.BATTLE_DATA.MOVE_SPD] = 3,
    [NewBattleConst.BATTLE_DATA.RUN_SPD] = 3,
    [NewBattleConst.BATTLE_DATA.WALK_SPD] = 1,
    [NewBattleConst.BATTLE_DATA.RANGE] = 5,
    [NewBattleConst.BATTLE_DATA.NEED_RUN] = 100,
    [NewBattleConst.BATTLE_DATA.COLD_DOWN] = 3000,
    [NewBattleConst.BATTLE_DATA.ELEMENT] = NewBattleConst.ELEMENT.FIRE,
    [NewBattleConst.BATTLE_DATA.ATK_MP] = 5,
    [NewBattleConst.BATTLE_DATA.DEF_MP] = 3,
    [NewBattleConst.BATTLE_DATA.CLASS_CORRECTION] = 1,
    [NewBattleConst.BATTLE_DATA.SKILL_MP] = { [1] = 5 },
    --
    [NewBattleConst.BATTLE_DATA.PHY_ATK] = 10,
    [NewBattleConst.BATTLE_DATA.MAG_ATK] = 10,
    [NewBattleConst.BATTLE_DATA.PHY_DEF] = 10,
    [NewBattleConst.BATTLE_DATA.MAG_DEF] = 10,
    [NewBattleConst.BATTLE_DATA.CRI] = 0,
    [NewBattleConst.BATTLE_DATA.HIT] = 0,
    [NewBattleConst.BATTLE_DATA.DODGE] = 0,
    [NewBattleConst.BATTLE_DATA.IMMUNITY] = 0,
}
--�����T
NewBattleConst.OTHER_DATA = {
    SPINE_PATH = 1, SPINE_NAME = 2, SPINE_SKIN = 3,
    INIT_POS_X = 4, INIT_POS_Y = 5, Z_ORDER = 6, IS_LEADER = 7, IS_ENEMY = 8,
    SPINE_PATH_BACK_FX = 9, SPINE_NAME_BACK_FX = 10, SPINE_PATH_FRONT_FX = 11, SPINE_NAME_FRONT_FX = 12, 
    SPINE_PATH_FLOOR_FX = 13, SPINE_NAME_FLOOR_FX = 14, SPINE_PATH_BULLET = 15, 
    PLAYING_ANI_NAME = 16, CHA_RADIUS = 17, IS_FLIP = 18, CFG = 19, BULLET_SPINE_NAME = 20, CHARACTER_TYPE = 21, ITEM_ID = 22, CHARACTER_LEVEL = 23
}
--�����T�w�]��
NewBattleConst.DEFAULT_OTHER_DATA = {
    [NewBattleConst.OTHER_DATA.SPINE_PATH] = "Spine/CharacterSpine",
    [NewBattleConst.OTHER_DATA.SPINE_NAME] = "110",
    [NewBattleConst.OTHER_DATA.SPINE_SKIN] = 1,
    [NewBattleConst.OTHER_DATA.INIT_POS_X] = 0,
    [NewBattleConst.OTHER_DATA.INIT_POS_Y] = 0,
    [NewBattleConst.OTHER_DATA.Z_ORDER] = 0,
    [NewBattleConst.OTHER_DATA.IS_LEADER] = false,
    [NewBattleConst.OTHER_DATA.IS_ENEMY] = false,
    [NewBattleConst.OTHER_DATA.SPINE_PATH_BACK_FX] = "Spine/HeroFX",
    [NewBattleConst.OTHER_DATA.SPINE_NAME_BACK_FX] = "NG_010000_FX2",
    [NewBattleConst.OTHER_DATA.SPINE_PATH_FRONT_FX] = "Spine/HeroFX",
    [NewBattleConst.OTHER_DATA.SPINE_NAME_FRONT_FX] = "NG_010000_FX1",
    [NewBattleConst.OTHER_DATA.SPINE_PATH_FLOOR_FX] = "Spine/HeroFX",
    [NewBattleConst.OTHER_DATA.SPINE_NAME_FLOOR_FX] = "NG_010000_FX3",
    [NewBattleConst.OTHER_DATA.SPINE_PATH_BULLET] = "Spine/HeroBullet",
    [NewBattleConst.OTHER_DATA.PLAYING_ANI_NAME] = "",
    [NewBattleConst.OTHER_DATA.CHA_RADIUS] = 120, 
    [NewBattleConst.OTHER_DATA.IS_FLIP] = 0,
    [NewBattleConst.OTHER_DATA.CFG] = { },
    [NewBattleConst.OTHER_DATA.BULLET_SPINE_NAME] = "",
    [NewBattleConst.OTHER_DATA.CHARACTER_TYPE] = 1,
    [NewBattleConst.OTHER_DATA.ITEM_ID] = 0,
    [NewBattleConst.OTHER_DATA.CHARACTER_LEVEL] = 1,
}
--����ޯ��T
NewBattleConst.SKILL_DATA = {
    SKILL = 1, AUTO_SKILL = 2, PASSIVE_VALUE = 3, PASSIVE = 4,
}
--����ޯ��T�w�]��
NewBattleConst.DEFAULT_SKILL_DATA = {
    [NewBattleConst.SKILL_DATA.SKILL] = { },
    [NewBattleConst.SKILL_DATA.AUTO_SKILL] = { },
    [NewBattleConst.SKILL_DATA.PASSIVE] = { },
}
--�ޯ�����
NewBattleConst.SKILL_TYPE = {
    COST_MANA = 1, CONDITION = 2, PASSIVE = 3
}
--skill1�ޯ�Ĳ�o����
NewBattleConst.SKILL1_TRIGGER_TYPE = {
    NORMAL = 0, DODGE = 1, STEALTH_CLEAR = 2
}
--�Q�ʧޯ�Ĳ�o����
NewBattleConst.PASSIVE_TRIGGER_TYPE = {
    START_BATTLE = 0, HP = 1, MP = 2, CD = 3, 
    ATK_HIT = 4, SKILL_HIT = 5, HIT = 6, 
    CRI_ATK_HIT = 7, CRI_SKILL_HIT = 8, CRI_HIT = 9, 
    BE_ATK_HIT = 10, BE_SKILL_HIT = 11, BE_HIT = 12,
    BE_CRI_ATK_HIT = 13, BE_CRI_SKILL_HIT = 14, BE_CRI_HIT = 15,
    SKILL_ADD_EFFECT = 16, ELEMENT_RATIO = 17, FRIEND_DEAD = 18, ENEMY_DEAD = 19, IMMUNITY_BUFF = 20,
    FRIEND_INFERNO_REMOVE = 21, FRIEND_INFERNO_CLEAR = 22, ADD_UNREDUCT_DMG = 23, KILL_ENEMY = 24,
    ENEMY_CAST_ACTIVE_SKILL = 25, TARGET_BUFF_ADD_DMG = 26, CHANGE_HP = 27, ADD_EXECUTE_DMG = 28, ADD_EXECUTE_CRI_DMG = 29,
    FRIEND_CRI_HIT = 30, AE_ATK_HIT = 31, ENEMY_FRENZY_REMOVE = 32, GET_BUFF = 33, GET_DEBUFF = 34,
    AURA_SHIELD = 100, AURA_HEALTH = 101,
}
--�Q�ʧޯ���������ID
NewBattleConst.PASSIVE_TYPE_ID = {
    -- �}��Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE] = { 1013, 1032, 1043, 1083, 1092, 1103, 1163, 1172, 1173, 1182, 1213, 1242, 
                                                           50004,
                                                           999998 },
    -- ��q����Ĳ�o(�����ˬd)
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.HP] = { 1043, 1052, 1053 },
    -- �]�O����Ĳ�o(�����ˬd)
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.MP] = { },
    -- CDĲ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.CD] = { 1022, 1072, 1112, 1152, 1202, 1203, 1221, 1232, 50012 },
    -- ����R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.ATK_HIT] = { 1023, 1141, 1162, 1171, 10101, 50015 },
    -- �ˮ`�ޯ�R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.SKILL_HIT] = { },
    -- ����/�ˮ`�ޯ�R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.HIT] = { 1193 },
    -- ��������R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.CRI_ATK_HIT] = { },
    -- �ˮ`�ޯ������Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.CRI_SKILL_HIT] = { },
    -- ����/�ˮ`�ޯ������Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.CRI_HIT] = { },
    -- �Q����R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.BE_ATK_HIT] = { 1132 },
    -- �Q�ˮ`�ޯ�R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.BE_SKILL_HIT] = { },
    -- �Q����/�ˮ`�ޯ�R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.BE_HIT] = { 1093, 1201 },
    -- �Q��������R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.BE_CRI_ATK_HIT] = { },
    -- �Q�ˮ`�ޯ�����R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.BE_CRI_SKILL_HIT] = { },
    -- �Q����/�ˮ`�ޯ�����R����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.BE_CRI_HIT] = { 1223, 50002 },
    -- �ޯ���[�B�~�ĪG
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.SKILL_ADD_EFFECT] = { },
    -- �ݩ��B�~�W�ˮĪG
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.ELEMENT_RATIO] = { },
    -- �ͤ�ؼЦ��`��Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_DEAD] = { 1243 },
    -- �Ĥ�ؼЦ��`��Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.ENEMY_DEAD] = { },
    -- �K��BUFF
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.IMMUNITY_BUFF] = { 1102, 999999 },
    -- �ͤ�~��������Ĳ�o(�~���ۨ��ĪG�y��������)
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_REMOVE] = { 1062, 1063 },
    -- �ͤ�~���Q�X����Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR] = { 1062 },
    -- �Ĥ�g�ò�����Ĳ�o(�X��, �ɶ�����, etc.)
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.ENEMY_FRENZY_REMOVE] = { 11701 },
    -- �l�[�B�~�L����˶ˮ`
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.ADD_UNREDUCT_DMG] = { 1081 },
    -- �ۨ������Ĥ��Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.KILL_ENEMY] = { },
    -- �Ĥ�I��D�ʧޯ��Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.ENEMY_CAST_ACTIVE_SKILL] = { 1211 },
    -- ��S�wBuff/Debuff�ؼмW��
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.TARGET_BUFF_ADD_DMG] = { 1023 },
    -- ��q���ܮɱ���Ĳ�o(setHp�ˬd)
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.CHANGE_HP] = { 1042, 1073 },
    -- �ؼЧC��q�B�~�W��
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.ADD_EXECUTE_DMG] = { 1142 },
    -- �ؼЧC��q�B�~�z��
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.ADD_EXECUTE_CRI_DMG] = { 1233 },
    -- �ͤ贶��/�ˮ`�ޯ������Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_CRI_HIT] = { 50004 },
    -- �����q�g�P��ؼ�
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.AE_ATK_HIT] = { 50003 },
    -- ��oBuff��Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.GET_BUFF] = { },
    -- ��oDeBuff��Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.GET_DEBUFF] = { 50013 },
    --
    -- �����F��ĪG(�@��)
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.AURA_SHIELD] = { 50014 },
    -- �����F��ĪG(�v���q)
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.AURA_HEALTH] = { 50014 },
}
--�ťۧޯ���������ID
NewBattleConst.RUNE_PASSIVE_TYPE_ID = {
    -- �}��Ĳ�o
    [NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE] = { 3012, 3014, 3015, 3016, 3017, 3018, 3019, 3020, 3021, 3022, 3023, 3024,
                                                           3025, 3026, 3027, 3028, 3029, 3030, 3031, 3032, 3033 },
}
-- �Q�ʧޯ��֧ޯ�}��CD���
NewBattleConst.SP_FIRSTCD_DATA = {
    [1153] = { ["LV"] = 3, ["SKILL"] = 1151 }
}
-- �ޯ�ؼп�ܱ���
NewBattleConst.SKILL_TARGET_CONDITION = {
    HIGHEST_HP = 1, LOWEST_HP = 2, HIGHEST_MP = 3, LOWEST_MP = 4, WITHOUT_BUFF_TAUNT = 5, WITHOUT_SELF = 6,
}
-- �����ƥ�����
NewBattleConst.HURT_TYPE = {
    BEATTACK = 1, BEHEALTH = 2, DOT = 3, HOT = 4, MANA = 5
}
-- �u���Ʀr����
NewBattleConst.SHOW_NUM_TYPE = {
    PHY_ATTACK = 1, MAG_ATTACK = 2, CRI_ATTACK = 3, 
    ENEMY_PHY_ATTACK = 4, ENEMY_MAG_ATTACK = 5, ENEMY_CRI_ATTACK = 6,
    HEALTH = 7, DOT = 8, MISS = 9, MANA = 10
}
-- �R���ƥ�����
NewBattleConst.HIT_TYPE = {
    HIT = 1, DODGE = 2, GHOST = 3
}
--spine�ʧ@�W��
NewBattleConst.ANI_ACT = { 
    WAIT = "wait_0", 
    ATTACK = "attack_0", 
    WALK = "move_0", 
    RUN = "move_1", 
    HURT = "hurt_0",
    SKILL0 = "skill_0", 
    SKILL1 = "skill_1",
    SKILL2 = "skill_2", 
    VICTORY = "victory_0",
    DEATH = "death_0",   
}
--�ݩʹϤ����|
NewBattleConst.ELEMENT_PIC = {
    "Common_UI02/cardbg_elemet_01.png", "Common_UI02/cardbg_elemet_02.png", "Common_UI02/cardbg_elemet_03.png",
    "Common_UI02/cardbg_elemet_04.png", "Common_UI02/cardbg_elemet_05.png"
}
--%�˳̤j���v
NewBattleConst.PERCENT_DMG_MAX_RATIO = 5
--��¦�z�˼W�T
NewBattleConst.BASE_CRI_DAMAGE = 0.5
--��¦�z���v
NewBattleConst.BASE_CRI = 0.1
--��¦�R���v
NewBattleConst.BASE_HIT = 0.8
--�ޯ�B�nZ�b
NewBattleConst.SKILL_MASK_Z_ORDER = 9000
--����ޯ�t�XZ�b
NewBattleConst.SPINE_USE_SKILL_Z_ORDER = 9999
--Z�b�ƧǾB�n
NewBattleConst.Z_ORDER_MASK = 1000
--�a�O�S��Z�b�ƧǾB�n
NewBattleConst.FLOOR_Z_ORDER_MASK = 10000
--���a�ƶq
NewBattleConst.HERO_COUNT = 5
--�ĤH�ƶq
NewBattleConst.ENEMY_COUNT = 5
--���F�ƶq
NewBattleConst.SPRITE_COUNT = 4
--���F���@CD�ɶ�
NewBattleConst.SPRITE_PUBLIC_CD_TIME = 10000
--���FCD�ɶ�
NewBattleConst.SPRITE_PRIVATE_CD_TIME = 40000
--���ͮɶ�
NewBattleConst.REBIRTH_TIME = 0
--�԰����a�e��
NewBattleConst.BATTLE_FIELD_WIDTH = 520
--�԰����a����
NewBattleConst.BATTLE_FIELD_HEIGHT = 620
--�԰��_�l�Z��
NewBattleConst.BATTLE_INIT_DIS = 400
--���F�԰��_�l�Z��
NewBattleConst.BATTLE_ENEMY_INIT_DIS = 600
--�Ĥ�_�lIDX
NewBattleConst.ENEMY_BASE_IDX = 10
--�����԰��t��
NewBattleConst.AFK_BATTLE_SPEED = 1.5
--�s��оǾ԰��t��
NewBattleConst.GUIDE_BATTLE_SPEED = 1
--�԰��ɶ�����(�@��)
NewBattleConst.BATTLE_LIMIT_TIME = 90000
--�԰��˼�ĵ�i�ɶ�(�@��)
NewBattleConst.BATTLE_COUNT_DOWN_ALART_TIME = 10000
--FX4�I��TAG�_�l��
NewBattleConst.FX4_NODE_TAG_VALUE = 4000

NewBattleConst.SCENE_TYPE = { 
    TEST_BATTLE = 0, -- ���վ԰�
    BOSS = 1,   -- BOSS
    MULTI = 2,  -- �C�����d
    PVP = 3,    -- PVP 
    WORLD_BOSS = 4, -- �@��BOSS
    DUNGEON = 5, -- �a��
    CYCLE_TOWER = 6, --�`������
    SINGLE_BOSS = 7, --��H�j��
    SINGLE_BOSS_SIM = 8, --��H�j�ļ���
    SEASON_TOWER = 9,
    GUIDE = 998, -- �s��о�
    AFK = 999,    -- ����
    EDIT_FIGHT_TEAM = 900,--�԰��s��
    EDIT_DEFEND_TEAM = 901,--���m�s��
}

NewBattleConst.TARGET_TYPE = {
	ORI_TARGET = 1,
	FRENZY_TARGET = 2,  -- �g�åؼ�
	TAUNT_TARGET = 3,   -- �J�إؼ�
}

NewBattleConst.FIGHT_STATE = {
    EDIT_TEAM = 1,      -- �ԫe�s��
    INIT = 2,           -- ��l��
    START_CHALLANGE = 3,-- ���d�D�Զ}�l�t�X
    BOSS_CUTIN = 4,     -- BOSS�S��t�X
    MOVING = 5,         -- ����i��
    FIGHTING = 6,       -- �԰���
    PLAY_SKILL = 7,     -- �ޯ�t�X
    SEND_RESULT = 8,    -- �ǰe�԰����G
    SHOW_RESULT = 9,    -- ����e��
    RESTART_AFK = 10,   -- ���ұ����԰�
    RESULT_ERROR = 11,  -- LOG���~
}

NewBattleConst.FIGHT_RESULT = {
    WIN = 0,
    LOSE = 1,
    ERROR = 2,
    NEXT_LOG = 3,
}
-- �԰��ݩ�%�ƤW�U��
NewBattleConst.MAX_DEF_PER = 0.15
NewBattleConst.MAX_CRI_PER = 0.95
NewBattleConst.MIN_CRI_PER = 0.05
NewBattleConst.MAX_HIT_PER = 0.95
NewBattleConst.MIN_HIT_PER = 0.05
-------------------------------------
-- Scene Spine Path
-------------------------------------
NewBattleConst.SceneSpinePath = {
    ["Challange"] = "Spine/NGUI,NGUI_19_IdleChest",
    ["Treasure"] = "Spine/NGUI,NGUI_20_ChestGet",
    ["Gold"] = "Spine/NGUI,hoh_gold",
    ["CardSkill_Front"] = "Spine/NGUI,cardwater_FX1",
    ["CardSkill_Back"] = "Spine/NGUI,cardwater_FX2",
    ["COUNT_DOWN"] = "Spine/NGUI,NGUI_76_overtime",
    ["MiniGame"]="Spine/NGUI,NGUI_89_IdleGirl",
}
NewBattleConst.AfkDropOffset = {
    "116.36,-71.28",
    "112.55,-71.28",
    "78.1,-71.28",
    "112.99,-46.7",
    "89.14,-46.7",
}
-------------------------------------
-- Buff
-------------------------------------
NewBattleConst.BUFF = {
    --BUFF(_A:��������, _B:�����ĪG)
    STABLE = 1, RAGE = 2, PIOUS = 3, PETAL = 4, OUROBOROS = 5, DEFENSE_CHAIN_A = 6, DEFENSE_CHAIN_B = 7, CONCENTRATION = 8, APOLLO = 9, MOONLIGHT = 10,
    REBIRTH = 11, FORCE = 12, BRUTAL = 13, IMMUNITY = 14, GUARD = 15, ASSAULT_A = 16, ASSAULT_B = 17, POWER = 18, RAPID_A = 19, RAPID_B = 20,
    UNDEAD = 21, ARCANE_A = 22, ARCANE_B = 23, ENLIGHTENMENT = 24, MANA_OVERFLOW = 25, CHASE = 26, BOOST_A = 27, BOOST_B = 28, SHADOW_A = 29, SHADOW_B = 30, 
    PRECISION = 31, RECOVERY = 32, WINDFURY = 33, BERSERKER = 34, STEALTH = 35, MAGIC_SHIELD_A = 36, MAGIC_SHIELD_B = 37, GHOST = 38, SINISTER = 39, PUNCTURE = 40,
    INFERNO = 41, KEEN_A = 42, KEEN_B = 43, EROSION = 44, DESTROY = 45, NATURE = 46, STONE = 47, TACTICAL_VISOR = 48, DEPENDENTS = 49, FRENZY = 50, 
    FREEZE = 51, WEAK = 52, COLLAPSE = 53, SILENCE = 54, BLIND = 55, MAGIC_LOCK = 56, DIZZY = 57, POSITION = 58, FROSTBITE = 59, TAUNT = 60,
    LEECH_SEED = 61, EXPLODE_SEED = 62, MALICIOUS = 63, BLEED = 64, FURY = 65, INJURY = 66, INVINCIBLE = 67, ICE_HEART = 68, WIND_WHISPER = 69, STORM = 70,
    JEALOUS = 71, PARALYSIS = 72, ELECTROMAGNETIC_FIELD = 73, STATIC = 74, CONDUCTOR = 75, WITCHER_I = 76, WITCHER_II = 77, WITCHER_III = 78, ANTI_HEAL = 79, SHADOW_HUNTER = 80,
    SEAL = 81, BRILLIANCE = 82, FALSE_GOD = 83, OFFERINGS = 84, BLOOD_SACRIFICE = 85, UNSTOPPABLE = 86, CURSE = 87, HAZE = 88, BURN = 89, ACCURACY_A = 90, 
    ACCURACY_B = 91, FEAR = 92, EMBER = 93, ICE_WALL = 94, TWINE = 95, BROKEN = 96, EXHAUST = 97, SOUL_OF_POSION = 98, TOXIN_OF_POSION = 99, SNAKE_OF_POSION = 100,
    HEADWIND = 101, TAILWIND = 102, DODGE = 103, AVOID = 104, RESIST_A = 105, RESIST_B = 106, HOLY_A = 107, HOLY_B = 108, UNRIVALED = 109, PIERCING_ICE = 110,
    MAGICIAN = 111, LIGHT_CHARGE = 112, DARK_THUNDER = 113, FORCE_FIELD = 114, THORNS = 115, DEFNESE_HEART_A = 116, DEFENSE_HEART_B = 117, FRAGILE = 118,
    -- �ť�
    RUNE_ATK_RANGE_1 = 3012, 
    RUNE_TODMG_FIRE1 = 3014, RUNE_TODMG_WATER1 = 3015, RUNE_TODMG_WIND1 = 3016, RUNE_TODMG_LIGHT1 = 3017, RUNE_TODMG_DARK1 = 3018, 
    RUNE_TODMG_FIRE_WATER1 = 3019, RUNE_TODMG_WATER_WIND1 = 3020, RUNE_TODMG_FIRE_WIND1 = 3021, RUNE_TODMG_LIGHT_DARK1 = 3022, 
    RUNE_BEDMG_FIRE1 = 3023, RUNE_BEDMG_WATER1 = 3024, RUNE_BEDMG_WIND1 = 3025, RUNE_BEDMG_LIGHT1 = 3026, RUNE_BEDMG_DARK1 = 3027, 
    RUNE_BEDMG_FIRE_WATER1 = 3028, RUNE_BEDMG_WATER_WIND1 = 3029, RUNE_BEDMG_FIRE_WIND1 = 3030, RUNE_BEDMG_LIGHT_DARK1 = 3031, 
    RUNE_HEALTH = 3032, RUNE_BEHEALTH = 3033,
}
NewBattleConst.BUFF_COLOR = {
    [NewBattleConst.BUFF.EROSION] = { ["RED"] = 220, ["GREEN"] = 100, ["BLUE"] = 210, ["ALPHA"] = 255 },
    [NewBattleConst.BUFF.STONE] = { ["RED"] = 130, ["GREEN"] = 130, ["BLUE"] = 130, ["ALPHA"] = 255 },
    [NewBattleConst.BUFF.BLIND] = { ["RED"] = 110, ["GREEN"] = 110, ["BLUE"] = 110, ["ALPHA"] = 255 },
    [NewBattleConst.BUFF.FREEZE] = { ["RED"] = 100, ["GREEN"] = 120, ["BLUE"] = 220, ["ALPHA"] = 255 },
    [NewBattleConst.BUFF.FROSTBITE] = { ["RED"] = 100, ["GREEN"] = 120, ["BLUE"] = 220, ["ALPHA"] = 255 },
    [NewBattleConst.BUFF.POSITION] = { ["RED"] = 168, ["GREEN"] = 29, ["BLUE"] = 180, ["ALPHA"] = 255 },
    [NewBattleConst.BUFF.STEALTH] = { ["RED"] = 255, ["GREEN"] = 255, ["BLUE"] = 255, ["ALPHA"] = 127 },
    [NewBattleConst.BUFF.BURN] = { ["RED"] = 220, ["GREEN"] = 100, ["BLUE"] = 100, ["ALPHA"] = 255 },
}
NewBattleConst.BUFF_SPINE_TYPE = {
    FULL = 1, LAYER = 2, NORMAL = 3, REMOVE = 4
}
NewBattleConst.BUFF_SPINE_TYPE_DATA = {
    [NewBattleConst.BUFF.RAGE] = NewBattleConst.BUFF_SPINE_TYPE.FULL,
    [NewBattleConst.BUFF.PETAL] = NewBattleConst.BUFF_SPINE_TYPE.LAYER,
    [NewBattleConst.BUFF.OUROBOROS] = NewBattleConst.BUFF_SPINE_TYPE.FULL,
    [NewBattleConst.BUFF.REBIRTH] = NewBattleConst.BUFF_SPINE_TYPE.REMOVE,
    [NewBattleConst.BUFF.INFERNO] = NewBattleConst.BUFF_SPINE_TYPE.LAYER,
    [NewBattleConst.BUFF.FRENZY] = NewBattleConst.BUFF_SPINE_TYPE.FULL,
    [NewBattleConst.BUFF.JEALOUS] = NewBattleConst.BUFF_SPINE_TYPE.LAYER,
    [NewBattleConst.BUFF.BURN] = NewBattleConst.BUFF_SPINE_TYPE.LAYER,
    [NewBattleConst.BUFF.DODGE] = NewBattleConst.BUFF_SPINE_TYPE.LAYER,
}
NewBattleConst.BUFF_TYPE = {
    NORMAL_BUFF = 1, AURA_BUFF = 2, MARK = 3, AURA = 4
}
NewBattleConst.BUFF_POSITION_TYPE = {
    BUTTOM = 1, CENTER = 2, HEAD = 3
}
NewBattleConst.BUFF_DATA = {
    TIME = 1,   --�Ѿl�ɶ�
    COUNT = 2,  --�h��
    TIMER = 3,  --�p�ɾ�
    TIMER2 = 4,  --�p�ɾ�2
    UPDATE_TIME = 5,  --�e��Buff��s�ɶ�
    CASTER = 6, --BUFF�I���
    USING = 7, --�ĪGĲ�o��(���y��)
    COUNTER = 8, --�p�ƾ�
}
NewBattleConst.ADD_BUFF_COUNT_EVENT = {
    NORMAL_ATTACK = 1,   --����
    BEDAMAGE = 2,  --����ˮ`
    SHIELD_CLEAR = 3,   --�@�ޮ���
    SKILL = 4,  --�ޯ�
    CAST_ATTACK = 5,    --�I�񴶧�
    CAST_SKILL = 6, --�I��ޯ�
    DODGE = 7, --�{��
}
NewBattleConst.BUFF_ICON_SIZE = 43
NewBattleConst.BUFF_SPINE_PATH = "Spine/Buff"
NewBattleConst.BUFF_SPINE_ANI_NAME = {
    BEGIN = "begin",
    WAIT = "wait_0",
    END = "end"
}
NewBattleConst.EYE_BEGIN_SKILL_ID = 100000
NewBattleConst.BUFF_ID_FX1_OFFSET = 10000000
NewBattleConst.BUFF_ID_FX2_OFFSET = 20000000
NewBattleConst.BUFF_ID_FX3_OFFSET = 30000000
NewBattleConst.BUFF_ID_FX4_OFFSET = 40000000
NewBattleConst.BUFF_ID_FX4_COUNT_OFFSET = 1000000
-------------------------------------
-- Battle Log
-------------------------------------
NewBattleConst.LogActionType = {
    ATTACK = 1,
    SKILL = 2,
    BUFF = 3,
    CAST_ATTACK = 4,
    CAST_SKILL = 5,
}
NewBattleConst.LogActionResultType = {
    HIT = 1,
    CRITICAL = 2,
    MISS = 3,
}
NewBattleConst.LogDataType = {
    DMG = 1,
    DMG_TAR = 2,
    DMG_CRI = 3,
    DMG_WEAK = 4,
    HEAL = 5,
    HEAL_TAR = 6,
    HEAL_CRI = 7,
    BUFF = 8,
    BUFF_TAR = 9,
    BUFF_TIME = 10,
    BUFF_COUNT = 11,
    SP_GAIN_MP = 12,
    SP_GAIN_MP_TAR = 13,
    SP_FUN_CLASS = 14,
    SP_FUN_NAME = 15,
    SP_FUN_PARAM = 16,
    SP_FUN_TAR = 17,
}
NewBattleConst.FunClassType = {
    BUFF_MANAGER = 1,
    NG_BATTLE_CHARACTER_UTIL = 2,
}
NewBattleConst.PassiveLogType = {
    SKILL = 1,
    BUFF = 2,
}
NewBattleConst.LOG_LENGTH = 30

NewBattleConst.DETAIL_DATA_TYPE = {
    DAMAGE = 1,
    BEDAMAGE = 2,
    HEALTH = 3,
}
-------------------------------------
-- FLYITEM TYPE
-------------------------------------
NewBattleConst.FLYITEM_TYPE = {
    SHOOT = 1,
    TARGET = 2,
}
-------------------------------------
-- PROTO TYPE
-------------------------------------
NewBattleConst.FORMATION_PROTO_TYPE = {
    REQUEST_ENEMY = 0,
    RESPONSE_PLAYER = 1,
}
NewBattleConst.BATTLE_PROTO_TYPE = {
    STORY = 1,
    MULTI = 2,
    PVP = 3,
    WORLD_BOSS = 4,
}

return NewBattleConst