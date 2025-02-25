-- 戰鬥角色管理

local NodeHelper = require("NodeHelper")
local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
local UserMercenaryManager = require("UserMercenaryManager")
local PBHelper = require("PBHelper")
local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
local DEBUG_UTIL = require("Battle.NgBattleDebugUtil")
require("Battle.NgBattleDataManager")
local CONST = require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.SpriteManager")
local ALFManager = require("Util.AsyncLoadFileManager")
--------------------------------------------------------------------------------
local NgCharacterManager = { }

local mapCfg = ConfigManager.getNewMapCfg()
local skillCfg = ConfigManager:getSkillCfg()

function NgCharacterManager:initAllChaNode()
    local heroList = {}
    for i = 1, CONST.HERO_COUNT do
        NgBattlePageInfo_updateTargetCardInfo(i, character)
    end
    for i = 1, CONST.HERO_COUNT do
        local time1 = os.clock()
        CCLuaLog(">>>>>newCharacter Start Time : " .. time1)
        local character, posId = NgCharacterManager:newCharacter(i, true)
        local time2 = os.clock()
        CCLuaLog(">>>>>newCharacter End Time : " .. time2)
        CCLuaLog(">>>>>newCharacter Cost Time : " .. (time2 - time1))
        if character then
            if posId then
                heroList[posId] = character
                NgBattlePageInfo_updateTargetCardInfo(posId, character)
                NgBattlePageInfo_updateTargetCardHpInfo(posId, character.battleData[CONST.BATTLE_DATA.HP], character.battleData[CONST.BATTLE_DATA.MAX_HP])
                NgBattlePageInfo_updateTargetCardMpInfo(posId, character.battleData[CONST.BATTLE_DATA.MP], character.battleData[CONST.BATTLE_DATA.MAX_MP]) 
                NgBattlePageInfo_updateTargetCardShieldInfo(posId, 0, character.battleData[CONST.BATTLE_DATA.MAX_HP]) 
                local time3 = os.clock()
                CCLuaLog(">>>>>preloadAllEffect Start Time : " .. time3)
                self:preloadAllEffect(character)
                local time4 = os.clock()
                CCLuaLog(">>>>>preloadAllEffect End Time : " .. time4)
                CCLuaLog(">>>>>preloadAllEffect Cost Time : " .. (time4 - time3))
            end
        end
    end
    NgBattleDataManager_setBattleMineCharacter(heroList)
    local enemyList = {}
    for i = 1, CONST.ENEMY_COUNT do
        local time1 = os.clock()
        CCLuaLog(">>>>>newEnemy Start Time : " .. time1)
        local character, posId = NgCharacterManager:newCharacter(i, false)
        enemyList[(posId or i) - 10] = character
        --self:preloadAllEffect(character.otherData[CONST.OTHER_DATA.ITEM_ID])
        local time2 = os.clock()
        CCLuaLog(">>>>>newEnemy End Time : " .. time2)
        CCLuaLog(">>>>>newEnemy Cost Time : " .. (time2 - time1))
    end
    NgBattleDataManager_setBattleEnemyCharacter(enemyList)
    NgBattlePageInfo_resetCardPos(NgBattleDataManager.battlePageContainer)
    -- 精靈
    SpriteManager:initSpriteData(NgBattleDataManager.battleType, NgBattleDataManager.serverPlayerInfo, NgBattleDataManager.serverEnemyInfo)
    -- 精靈卡片初始化
    NgBattlePageInfo_initSpriteCard(NgBattleDataManager.battlePageContainer)
    -- 預載受擊特效
    local time1 = os.clock()
    CCLuaLog(">>>>>preloadAllHitEffect Start Time : " .. time1)
    self:preloadAllHitEffect(heroList, enemyList)
    local time2 = os.clock()
    CCLuaLog(">>>>>preloadAllHitEffect End Time : " .. time2)
    CCLuaLog(">>>>>preloadAllHitEffect Cost Time : " .. (time2 - time1))
end

function NgCharacterManager:initTarChaNode(pos)
    if pos < NewBattleConst.ENEMY_BASE_IDX then
        local heroList = NgBattleDataManager.battleMineCharacter or { }
        local character, posId = NgCharacterManager:newCharacter(pos, true)
        if character and posId then
            heroList[posId] = character
            NgBattlePageInfo_updateTargetCardInfo(posId, character)
            NgBattlePageInfo_updateTargetCardHpInfo(posId, character.battleData[CONST.BATTLE_DATA.HP], character.battleData[CONST.BATTLE_DATA.MAX_HP])
            NgBattlePageInfo_updateTargetCardMpInfo(posId, character.battleData[CONST.BATTLE_DATA.MP], character.battleData[CONST.BATTLE_DATA.MAX_MP]) 
            NgBattlePageInfo_updateTargetCardShieldInfo(posId, 0, character.battleData[CONST.BATTLE_DATA.MAX_HP]) 
        end
        NgBattleDataManager_setBattleMineCharacter(heroList)
        NgBattlePageInfo_resetCardPos(NgBattleDataManager.battlePageContainer)
    else
        local enemyIdx = pos - NewBattleConst.ENEMY_BASE_IDX
        if enemyIdx <= CONST.ENEMY_COUNT then
            local enemyList = NgBattleDataManager.battleEnemyCharacter or { }
            local character, posId = NgCharacterManager:newCharacter(enemyIdx, false)
            if character and posId then
                enemyList[(posId or i) - NewBattleConst.ENEMY_BASE_IDX] = character
                NgBattleDataManager_setBattleEnemyCharacter(enemyList)
            end
        end
    end
    -- 精靈
    SpriteManager:initTarSpriteData(NgBattleDataManager.battleType, NgBattleDataManager.serverPlayerInfo, NgBattleDataManager.serverEnemyInfo)
    -- 精靈卡片初始化
    NgBattlePageInfo_initSpriteCard(NgBattleDataManager.battlePageContainer)
    
    NgBattleDataManager.nowInitCharPos = NgBattleDataManager.nowInitCharPos + 1
    
end

function NgCharacterManager:newCharacter(idx, isMine)
    local fightNode = NgBattleDataManager.battlePageContainer:getVarNode("mContent")

    local cfg = nil
    local effectCfg = nil 
    local itemId = nil
    local basePosIdx = isMine and 0 or CONST.ENEMY_BASE_IDX   -- 敵方角色位置id從10開始
    local isAFK = (NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK)
    local isGuide = (NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE)
    local isAFKMonster = (isAFK and not isMine) -- 是否是掛機怪物
    local serverCharacterInfo = nil -- player.proto CLIchaeckInfo
    local roleInfo = nil

    if isMine then  -- 我方角色(掛機時抓本地資料 非掛機時抓server資料 新手教學時抓表格資料)
        cfg = ConfigManager.getNewHeroCfg()
        if isGuide then
            local heroIds = { 99, 98, 97, 96 }
            if not heroIds[idx] then
                return nil
            end
            itemId = tonumber(heroIds[idx])
        elseif isAFK then
            local defaultGroup = NgBattleDataManager.groupInfo
            local statusInfo = UserMercenaryManager:getMercenaryStatusById(defaultGroup and defaultGroup.roleIds[idx] or 0)
            roleInfo = statusInfo and UserMercenaryManager:getUserMercenaryById(statusInfo.roleId)  -- player.proto RoleInfo
            if not roleInfo then
                return nil
            end
            itemId = roleInfo.itemId
        else
            serverCharacterInfo = NgBattleDataManager.serverPlayerInfo and NgBattleDataManager.serverPlayerInfo[idx]
            roleInfo = serverCharacterInfo
            if not roleInfo then
                return nil
            end
            itemId = serverCharacterInfo.itemId
        end
    else
        cfg = ConfigManager.getNewMonsterCfg()
        if isGuide then
            local monsterIds = common:split(mapCfg[9999].BossID, ",")
            itemId = tonumber(monsterIds[idx])
            if not cfg[itemId] then
                return nil
            end
        elseif isAFKMonster then   -- 掛機敵人(沒有server資料 抓表格)
            local monsterIds = common:split(mapCfg[NgBattleDataManager.battleMapId].MonsterID, ",")
            local randIdx = math.random(1, #monsterIds)
            itemId = tonumber(monsterIds[randIdx])
        else    -- 敵方角色(非掛機)
            serverCharacterInfo = NgBattleDataManager.serverEnemyInfo and NgBattleDataManager.serverEnemyInfo[idx]
            roleInfo = serverCharacterInfo
            if not roleInfo then
                return nil
            end
            if serverCharacterInfo.type == Const_pb.MERCENARY or   -- Hero
               serverCharacterInfo.type == Const_pb.RETINUE then   -- Free Hero
                itemId = serverCharacterInfo.itemId
                cfg = ConfigManager.getNewHeroCfg()
            else
                itemId = serverCharacterInfo.roleId
            end
        end
    end

    if not itemId then
        return nil
    end
    local posId = roleInfo and roleInfo.posId or (idx + basePosIdx)    -- 戰鬥場景座標id
    if posId == 0 then  -- 過濾舊的leader資料
        return
    end
    effectCfg = ConfigManager.getHeroEffectPathCfg()
    local attrs = roleInfo and roleInfo.attribute.attribute -- 角色屬性
    local skills = roleInfo and roleInfo.skills or common:split(cfg[itemId].Skills, ",") -- 角色技能
    local level = roleInfo and (roleInfo.level or roleInfo.lv) or cfg[itemId].Level or 1 -- 角色等級
    level = math.max(level, 1)
    local isPhy = roleInfo and roleInfo.isPhy or (cfg[itemId].IsMag == 1 and 0 or 1)  -- 物理/魔法角色
    local roleType = roleInfo and roleInfo.type or (isMine and CONST.CHARACTER_TYPE.HERO or CONST.CHARACTER_TYPE.MONSTER) -- 角色類型(英雄, 怪物, 世界boss...)
    if roleType == CONST.CHARACTER_TYPE.SPRITE then    -- 跳過精靈
        return
    end
    local initHp = nil  -- 是否需要強制設定初始血量(世界boss用)
    if roleType == CONST.CHARACTER_TYPE.WORLDBOSS then
        initHp = roleInfo.initHp
    end

    local bData = {
        [CONST.BATTLE_DATA.MAX_HP] = (isAFKMonster or isGuide) and cfg[itemId].Hp or PBHelper:getAttrById(attrs, Const_pb.HP),
        [CONST.BATTLE_DATA.HP] = ((isGuide and isMine) and cfg[itemId].Hp * 0.7) or initHp or ((isAFKMonster or isGuide) and cfg[itemId].Hp or PBHelper:getAttrById(attrs, Const_pb.HP)),
        [CONST.BATTLE_DATA.MP] = (isGuide and isMine) and 100 or 0,
        [CONST.BATTLE_DATA.IS_PHY] = (isPhy == 1) and true or false,
        [CONST.BATTLE_DATA.STR] = (isAFKMonster or isGuide) and cfg[itemId].Str or PBHelper:getAttrById(attrs, Const_pb.STRENGHT),
        [CONST.BATTLE_DATA.INT] = (isAFKMonster or isGuide) and cfg[itemId].Int or PBHelper:getAttrById(attrs, Const_pb.INTELLECT),
        [CONST.BATTLE_DATA.AGI] = (isAFKMonster or isGuide) and cfg[itemId].Agi or PBHelper:getAttrById(attrs, Const_pb.AGILITY),
        [CONST.BATTLE_DATA.STA] = (isAFKMonster or isGuide) and cfg[itemId].Sta or PBHelper:getAttrById(attrs, Const_pb.STAMINA),
        [CONST.BATTLE_DATA.PHY_PENETRATE] = (isAFKMonster or isGuide) and cfg[itemId].PhyPenetrate or PBHelper:getAttrById(attrs, Const_pb.BUFF_PHYDEF_PENETRATE) / 100,
        [CONST.BATTLE_DATA.MAG_PENETRATE] = (isAFKMonster or isGuide) and cfg[itemId].MagPenetrate or PBHelper:getAttrById(attrs, Const_pb.BUFF_MAGDEF_PENETRATE) / 100,
        [CONST.BATTLE_DATA.RECOVER_HP] = (isAFKMonster or isGuide) and cfg[itemId].RecoverHp or PBHelper:getAttrById(attrs, Const_pb.BUFF_RETURN_BLOOD) / 100,
        [CONST.BATTLE_DATA.CRI_DMG] = (isAFKMonster or isGuide) and cfg[itemId].CriDmg or PBHelper:getAttrById(attrs, Const_pb.BUFF_CRITICAL_DAMAGE) / 100,
        [CONST.BATTLE_DATA.CRI_RESIST] = (isAFKMonster or isGuide) and 0 or PBHelper:getAttrById(attrs, Const_pb.RESILIENCE),
        [CONST.BATTLE_DATA.RUN_SPD] = cfg[itemId].RunSpd,
        [CONST.BATTLE_DATA.WALK_SPD] = cfg[itemId].WalkSpd,
        [CONST.BATTLE_DATA.RANGE] = cfg[itemId].AtkRng,
        [CONST.BATTLE_DATA.COLD_DOWN] = roleInfo and roleInfo.atkSpeed or cfg[itemId].AtkSpd,
        [CONST.BATTLE_DATA.ATK_MP] = (roleInfo and roleInfo.atkMp or cfg[itemId].AtkMp),
        [CONST.BATTLE_DATA.DEF_MP] = (roleInfo and roleInfo.defMp or cfg[itemId].DefMp),
        [CONST.BATTLE_DATA.CLASS_CORRECTION] = roleInfo and roleInfo.ClassCorrection or cfg[itemId].ClassCorrection,
        [CONST.BATTLE_DATA.SKILL_MP] = roleInfo and common:split(roleInfo.skillMp, ",") or common:split(cfg[itemId].SkillMp, ","),
        --
        [CONST.BATTLE_DATA.ELEMENT] =  roleInfo and roleInfo.elements or cfg[itemId].Element,
        --
        [CONST.BATTLE_DATA.PHY_ATK] = (isAFKMonster or isGuide) and cfg[itemId].Atk or PBHelper:getAttrById(attrs, Const_pb.ATTACK_attr),
        [CONST.BATTLE_DATA.MAG_ATK] = (isAFKMonster or isGuide) and cfg[itemId].Mag or PBHelper:getAttrById(attrs, Const_pb.MAGIC_attr),
        [CONST.BATTLE_DATA.PHY_DEF] = (isAFKMonster or isGuide) and cfg[itemId].PhyDef or PBHelper:getAttrById(attrs, Const_pb.PHYDEF),
        [CONST.BATTLE_DATA.MAG_DEF] = (isAFKMonster or isGuide) and cfg[itemId].MagDef or PBHelper:getAttrById(attrs, Const_pb.MAGDEF),
        [CONST.BATTLE_DATA.CRI] = (isAFKMonster or isGuide) and cfg[itemId].Cri or PBHelper:getAttrById(attrs, Const_pb.CRITICAL),
        [CONST.BATTLE_DATA.HIT] = (isAFKMonster or isGuide) and cfg[itemId].Hit or PBHelper:getAttrById(attrs, Const_pb.HIT),
        [CONST.BATTLE_DATA.DODGE] = (isAFKMonster or isGuide) and cfg[itemId].Dodge or PBHelper:getAttrById(attrs, Const_pb.DODGE),
        [CONST.BATTLE_DATA.IMMUNITY] = (isAFKMonster or isGuide) and cfg[itemId].Immunity or PBHelper:getAttrById(attrs, Const_pb.BUFF_AVOID_CONTROL),
    }
    
    local spinePath, spineName = unpack(common:split(cfg[itemId].Spine, ","))
    local isHero = (roleType == CONST.CHARACTER_TYPE.LEADER or 
                    roleType == CONST.CHARACTER_TYPE.HERO)
    local oData = {
        [CONST.OTHER_DATA.SPINE_PATH] = spinePath,
        [CONST.OTHER_DATA.SPINE_NAME] = isHero and spineName .. string.format("%03d", roleInfo and roleInfo.skinId or 0) or spineName,
        [CONST.OTHER_DATA.SPINE_SKIN] = isHero and (roleInfo and roleInfo.skinId or 0) or cfg[itemId].Skin,
        [CONST.OTHER_DATA.INIT_POS_X] = NgBattleDataManager.battlePageContainer:getVarNode("mPos" .. posId):getPositionX(),
        [CONST.OTHER_DATA.INIT_POS_Y] = NgBattleDataManager.battlePageContainer:getVarNode("mPos" .. posId):getPositionY(),
        [CONST.OTHER_DATA.IS_LEADER] = (roleType == Const_pb.MAIN_ROLE),
        [CONST.OTHER_DATA.IS_ENEMY] = not isMine,
        [CONST.OTHER_DATA.SPINE_PATH_BACK_FX] = "Spine/CharacterFX",
        [CONST.OTHER_DATA.SPINE_NAME_BACK_FX] = isHero and effectCfg[tonumber(string.format("%02d", itemId) .. string.format("%03d", roleInfo and roleInfo.skinId or 0))].HeroFx .. "_FX2" or cfg[itemId].CharFxName .. "_FX2",
        [CONST.OTHER_DATA.SPINE_PATH_FRONT_FX] = "Spine/CharacterFX",
        [CONST.OTHER_DATA.SPINE_NAME_FRONT_FX] = isHero and effectCfg[tonumber(string.format("%02d", itemId) .. string.format("%03d", roleInfo and roleInfo.skinId or 0))].HeroFx .. "_FX1" or cfg[itemId].CharFxName .. "_FX1",
        [CONST.OTHER_DATA.SPINE_PATH_FLOOR_FX] = "Spine/CharacterFX",
        [CONST.OTHER_DATA.SPINE_NAME_FLOOR_FX] = isHero and effectCfg[tonumber(string.format("%02d", itemId) .. string.format("%03d", roleInfo and roleInfo.skinId or 0))].HeroFx .. "_FX3" or cfg[itemId].CharFxName .. "_FX3",
        [CONST.OTHER_DATA.SPINE_PATH_BULLET] = "Spine/CharacterBullet",
        [CONST.OTHER_DATA.IS_FLIP] = cfg[itemId].Reflect,
        [CONST.OTHER_DATA.CFG] = cfg[itemId],
        [CONST.OTHER_DATA.BULLET_SPINE_NAME] = isHero and effectCfg[tonumber(string.format("%02d", itemId) .. string.format("%03d", roleInfo and roleInfo.skinId or 0))].Bullet or cfg[itemId].BulletName,
        [CONST.OTHER_DATA.CHARACTER_TYPE] = roleType,
        [CONST.OTHER_DATA.ITEM_ID] = itemId,
        [CONST.OTHER_DATA.CHARACTER_LEVEL] = level,
    }
    -- 測試戰鬥
    if (NgBattleDataManager.battleType == NewBattleConst.SCENE_TYPE.TEST_BATTLE) then
        if oData[CONST.OTHER_DATA.IS_ENEMY] then
            bData[CONST.BATTLE_DATA.MAX_HP] = bData[CONST.BATTLE_DATA.MAX_HP] * NgBattleDataManager.testEnemyHpRatio
            bData[CONST.BATTLE_DATA.HP] = bData[CONST.BATTLE_DATA.HP] * NgBattleDataManager.testEnemyHpRatio
        else
            bData[CONST.BATTLE_DATA.MAX_HP] = bData[CONST.BATTLE_DATA.MAX_HP] * NgBattleDataManager.testFriendHpRatio
            bData[CONST.BATTLE_DATA.HP] = bData[CONST.BATTLE_DATA.HP] * NgBattleDataManager.testFriendHpRatio
        end
    end
    
    local sData = { }
    local spFirstCDData = { }
    for i = 1, #skills do
        local skillId = tonumber(skills[i]) or tonumber(skills[i].itemId)
        if skillCfg[skillId] and (skillId > 40000 or skillId < 30000) then
            local skillType = skillCfg[skillId].skillType or CONST.SKILL_DATA.PASSIVE
            sData[skillType] = sData[skillType] or { }
            local skillBaseId = math.floor(skillId / 10)
            local skillLevel = skillId % 10
            table.insert(sData[skillType], skillId, 
                         { ["COUNT"] = 0, ["CD"] = skillCfg[skillId].firstCD, ["ACTION"] = skillCfg[skillId].actionName,
                           ["TIMER"] = 0, ["LEVEL"] = skillLevel })
            -- 重設FirstCD
            if CONST.SP_FIRSTCD_DATA[skillBaseId] and skillLevel >= CONST.SP_FIRSTCD_DATA[skillBaseId]["LV"] then
                spFirstCDData[CONST.SP_FIRSTCD_DATA[skillBaseId]["SKILL"]] = skillId
            end
        end
    end
    -- 重設FirstCD
    for skillType, skillTypeData in pairs(sData) do
        for skillId, skillIdData in pairs(skillTypeData) do
            local skillBaseId = math.floor(skillId / 10)
            if spFirstCDData[skillBaseId] then
                local skillCfg = ConfigManager:getSkillCfg()[spFirstCDData[skillBaseId]]
                local params = common:split(skillCfg.values, ",")
                skillIdData["CD"] = skillCfg.firstCD
            end
        end
    end
    local rData = { }
    local runeSkills = roleInfo and roleInfo.dress or { } -- 符石技能
    for i = 1, #runeSkills do
        local skillId = tonumber(runeSkills[i]) or tonumber(runeSkills[i].skillId)
        if skillCfg[skillId] then
            local skillType = skillCfg[skillId].skillType or CONST.SKILL_DATA.PASSIVE
            rData[skillType] = rData[skillType] or { }
            local skillBaseId = math.floor(skillId / 10)
            local skillLevel = skillId % 10
            if rData[skillType][skillBaseId] then
                rData[skillType][skillBaseId]["NUM"] = rData[skillType][skillBaseId]["NUM"] + 1
            else
                table.insert(rData[skillType], skillBaseId, 
                            { ["COUNT"] = 0, ["CD"] = skillCfg[skillId].firstCD, ["ACTION"] = skillCfg[skillId].actionName,
                              ["TIMER"] = 0, ["LEVEL"] = skillLevel, ["NUM"] = 1 })
            end
        end
    end
    local character = CHAR_UTIL:new({ parent = fightNode, idx = posId, battleData = bData, otherData = oData, skillData = sData, runeData = rData })
    NgBattleCharacterBase:registSpineEventFunction(character)
    NgBattleCharacterBase:registCallBackFunction(character)
    NgBattleCharacterBase:setOnAnimationFunction(character)

    DEBUG_UTIL:testMessage(character, attrs, id)    
    
    return character, posId
end

function NgCharacterManager:newSprite(roleInfo, posIdx)
    local fightNode = NgBattleDataManager.battlePageContainer:getVarNode("mContent")

    local cfg = ConfigManager.getNewHeroCfg()
    local effectCfg = ConfigManager.getHeroEffectPathCfg()
    if not roleInfo then
         return nil
    end
    local itemId = roleInfo.itemId
    local posId = (posIdx < CONST.ENEMY_BASE_IDX) and 4 or 14   -- 戰鬥場景座標id

    local attrs = roleInfo.attribute.attribute -- 角色屬性
    local skills = roleInfo.skills
    local level = roleInfo.level
    local isPhy = roleInfo.isPhy
    local roleType = roleInfo.type -- 角色類型(英雄, 怪物, 世界boss...)
    if roleType ~= CONST.CHARACTER_TYPE.SPRITE then    -- 跳過精靈以外的
        return
    end
    local bData = {
        [CONST.BATTLE_DATA.MAX_HP] = PBHelper:getAttrById(attrs, Const_pb.HP),
        [CONST.BATTLE_DATA.HP] = PBHelper:getAttrById(attrs, Const_pb.HP),
        [CONST.BATTLE_DATA.IS_PHY] = (isPhy == 1) and true or false,
        [CONST.BATTLE_DATA.STR] = PBHelper:getAttrById(attrs, Const_pb.STRENGHT),
        [CONST.BATTLE_DATA.INT] = PBHelper:getAttrById(attrs, Const_pb.INTELLECT),
        [CONST.BATTLE_DATA.AGI] = PBHelper:getAttrById(attrs, Const_pb.AGILITY),
        [CONST.BATTLE_DATA.STA] = PBHelper:getAttrById(attrs, Const_pb.STAMINA),
        [CONST.BATTLE_DATA.PHY_PENETRATE] = PBHelper:getAttrById(attrs, Const_pb.BUFF_PHYDEF_PENETRATE) / 100,
        [CONST.BATTLE_DATA.MAG_PENETRATE] = PBHelper:getAttrById(attrs, Const_pb.BUFF_MAGDEF_PENETRATE) / 100,
        [CONST.BATTLE_DATA.RECOVER_HP] = PBHelper:getAttrById(attrs, Const_pb.BUFF_RETURN_BLOOD) / 100,
        [CONST.BATTLE_DATA.CRI_DMG] = PBHelper:getAttrById(attrs, Const_pb.BUFF_CRITICAL_DAMAGE) / 100,
        [CONST.BATTLE_DATA.CRI_RESIST] = PBHelper:getAttrById(attrs, Const_pb.RESILIENCE),
        [CONST.BATTLE_DATA.RUN_SPD] = cfg[itemId].RunSpd,
        [CONST.BATTLE_DATA.WALK_SPD] = cfg[itemId].WalkSpd,
        [CONST.BATTLE_DATA.RANGE] = cfg[itemId].AtkRng,
        [CONST.BATTLE_DATA.COLD_DOWN] = roleInfo.atkSpeed,
        [CONST.BATTLE_DATA.ATK_MP] = roleInfo.atkMp,
        [CONST.BATTLE_DATA.DEF_MP] = roleInfo.defMp,
        [CONST.BATTLE_DATA.CLASS_CORRECTION] = roleInfo.ClassCorrection,
        [CONST.BATTLE_DATA.SKILL_MP] = roleInfo and common:split(roleInfo.skillMp, ",") or common:split(cfg[itemId].SkillMp, ","),
        --
        [CONST.BATTLE_DATA.ELEMENT] =  roleInfo.elements,
        --
        [CONST.BATTLE_DATA.PHY_ATK] = PBHelper:getAttrById(attrs, Const_pb.ATTACK_attr),
        [CONST.BATTLE_DATA.MAG_ATK] = PBHelper:getAttrById(attrs, Const_pb.MAGIC_attr),
        [CONST.BATTLE_DATA.PHY_DEF] = PBHelper:getAttrById(attrs, Const_pb.PHYDEF),
        [CONST.BATTLE_DATA.MAG_DEF] = PBHelper:getAttrById(attrs, Const_pb.MAGDEF),
        [CONST.BATTLE_DATA.CRI] = PBHelper:getAttrById(attrs, Const_pb.CRITICAL),
        [CONST.BATTLE_DATA.HIT] = PBHelper:getAttrById(attrs, Const_pb.HIT),
        [CONST.BATTLE_DATA.DODGE] = PBHelper:getAttrById(attrs, Const_pb.DODGE),
        [CONST.BATTLE_DATA.IMMUNITY] = PBHelper:getAttrById(attrs, Const_pb.BUFF_AVOID_CONTROL),
    }
    
    local spinePath, spineName = unpack(common:split(cfg[itemId].Spine, ","))
    local oData = {
        [CONST.OTHER_DATA.SPINE_PATH] = spinePath,
        [CONST.OTHER_DATA.SPINE_NAME] = spineName,
        [CONST.OTHER_DATA.SPINE_SKIN] = cfg[itemId].Skin,
        [CONST.OTHER_DATA.INIT_POS_X] = NgBattleDataManager.battlePageContainer:getVarNode("mPos" .. posId):getPositionX(),
        [CONST.OTHER_DATA.INIT_POS_Y] = NgBattleDataManager.battlePageContainer:getVarNode("mPos" .. posId):getPositionY(),
        [CONST.OTHER_DATA.IS_LEADER] = false,
        [CONST.OTHER_DATA.IS_ENEMY] = (posIdx >= CONST.ENEMY_BASE_IDX),
        [CONST.OTHER_DATA.SPINE_PATH_BACK_FX] = "Spine/CharacterFX",
        [CONST.OTHER_DATA.SPINE_NAME_BACK_FX] = effectCfg[tonumber(itemId .. "000")].HeroFx .. "_FX2",
        [CONST.OTHER_DATA.SPINE_PATH_FRONT_FX] = "Spine/CharacterFX",
        [CONST.OTHER_DATA.SPINE_NAME_FRONT_FX] = effectCfg[tonumber(itemId .. "000")].HeroFx .. "_FX1",
        [CONST.OTHER_DATA.SPINE_PATH_FLOOR_FX] = "Spine/CharacterFX",
        [CONST.OTHER_DATA.SPINE_NAME_FLOOR_FX] = effectCfg[tonumber(itemId .. "000")].HeroFx .. "_FX3",
        [CONST.OTHER_DATA.SPINE_PATH_BULLET] = "Spine/CharacterBullet",
        [CONST.OTHER_DATA.IS_FLIP] = cfg[itemId].Reflect,
        [CONST.OTHER_DATA.CFG] = cfg[itemId],
        [CONST.OTHER_DATA.BULLET_SPINE_NAME] = cfg[itemId].BulletName,
        [CONST.OTHER_DATA.CHARACTER_TYPE] = roleType,
        [CONST.OTHER_DATA.ITEM_ID] = itemId,
        [CONST.OTHER_DATA.CHARACTER_LEVEL] = level or 1,
    }
    
    local sData = { }
    local spFirstCDData = { }
    for i = 1, #skills do
        local skillId = tonumber(skills[i]) or tonumber(skills[i].itemId)
        if skillCfg[skillId] then
            local skillType = skillCfg[skillId].skillType or CONST.SKILL_DATA.PASSIVE
            sData[skillType] = sData[skillType] or { }
            local skillBaseId = math.floor(skillId / 10)
            local skillLevel = skillId % 10
            table.insert(sData[skillType], skillId, 
                         { ["COUNT"] = 0, ["CD"] = skillCfg[skillId].firstCD, ["ACTION"] = skillCfg[skillId].actionName,
                           ["TIMER"] = 0, ["LEVEL"] = skillLevel })
            -- 重設FirstCD
            if CONST.SP_FIRSTCD_DATA[skillBaseId] and skillLevel >= CONST.SP_FIRSTCD_DATA[skillBaseId]["LV"] then
                spFirstCDData[CONST.SP_FIRSTCD_DATA[skillBaseId]["SKILL"]] = skillId
            end
        end
    end
    -- 重設FirstCD
    for skillType, skillTypeData in pairs(sData) do
        for skillId, skillIdData in pairs(skillTypeData) do
            local skillBaseId = math.floor(skillId / 10)
            if spFirstCDData[skillBaseId] then
                local skillCfg = ConfigManager:getSkillCfg()[spFirstCDData[skillBaseId]]
                local params = common:split(skillCfg.values, ",")
                skillIdData["CD"] = skillCfg.firstCD
            end
        end
    end
    local rData = { }
    local runeSkills = roleInfo and roleInfo.dress or { } -- 符石技能
    for i = 1, #runeSkills do
        local skillId = tonumber(runeSkills[i]) or tonumber(runeSkills[i].skillId)
        if skillCfg[skillId] then
            local skillType = skillCfg[skillId].skillType or CONST.SKILL_DATA.PASSIVE
            rData[skillType] = rData[skillType] or { }
            local skillBaseId = math.floor(skillId / 10)
            local skillLevel = skillId % 10
            if rData[skillType][skillBaseId] then
                rData[skillType][skillBaseId]["NUM"] = rData[skillType][skillBaseId]["NUM"] + 1
            else
                table.insert(rData[skillType], skillBaseId, 
                            { ["COUNT"] = 0, ["CD"] = skillCfg[skillId].firstCD, ["ACTION"] = skillCfg[skillId].actionName,
                              ["TIMER"] = 0, ["LEVEL"] = skillLevel, ["NUM"] = 1 })
            end
        end
    end
    local character = CHAR_UTIL:new({ parent = fightNode, idx = posIdx, battleData = bData, otherData = oData, skillData = sData, runeData = rData })
    NgBattleCharacterBase:registSpineEventFunction(character)
    NgBattleCharacterBase:setOnAnimationFunction(character)

    return character, posIdx
end

function NgCharacterManager:preloadAllEffect(chaNode)
    local itemId = chaNode.otherData[CONST.OTHER_DATA.ITEM_ID]
    local effCfg = ConfigManager.getBattleEffCfg()
    if effCfg[itemId] then
        local list = common:split(effCfg[itemId].effList, ",")
        local fn = function()
            for i = 1, #list do
                SimpleAudioEngine:sharedEngine():preloadEffect(list[i] .. ".mp3")
            end
        end
        local task = ALFManager:loadNormalTask(fn, nil)
        NgBattleDataManager.asyncLoadTasks[chaNode.idx] = NgBattleDataManager.asyncLoadTasks[chaNode.idx] or { }
        table.insert(NgBattleDataManager.asyncLoadTasks[chaNode.idx], task)
    end
end

function NgCharacterManager:preloadAllHitEffect(fList, eList)
    if (NgBattleDataManager.battleType == NewBattleConst.SCENE_TYPE.TEST_BATTLE) then
        return
    end
    ALFManager:loadSpineTask("Spine/hit/", "heal01_FX1", 1, function() end)
    ALFManager:loadSpineTask("Spine/Buff/", "Buff_82_FX1", 1, function() end)
    for f = 1, CONST.HERO_COUNT do
        if fList[f] then
            for e = 1, CONST.ENEMY_COUNT do
                if eList[e] then
                    local isHero = (eList[e].otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.LEADER or 
                                    eList[e].otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.HERO or 
                                    eList[e].otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.SPRITE)
                    if isHero then   --Hero
                        local effectCfg = ConfigManager.getHeroEffectPathCfg()
                        local idx = tonumber(eList[e].otherData[CONST.OTHER_DATA.ITEM_ID] .. string.format("%03d", eList[e].otherData[CONST.OTHER_DATA.SPINE_SKIN]))
                        if effectCfg[idx] then
                            if effectCfg[idx].AttackHit then
                                fileNames = common:split(effectCfg[idx].AttackHit, ",")
                            end
                        end
                    else    --Monster
                        local monsterCfg = eList[e].otherData[CONST.OTHER_DATA.CFG]
                        if monsterCfg then
                            if monsterCfg.HitEffectPath then
                                fileNames = common:split(monsterCfg.HitEffectPath, ",")
                            end
                        end
                    end
                    fList[f].hurtEffect = fList[f].hurtEffect or { }
                    for i = 1, #fileNames do 
                        ALFManager:loadSpineTask("Spine/hit/", fileNames[i], 1, function() end)
                    end
                end
            end
        end
    end
    for e = 1, CONST.ENEMY_COUNT do
        if eList[e] then
            for f = 1, CONST.HERO_COUNT do
                if fList[f] then
                    local isHero = (fList[f].otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.LEADER or 
                                    fList[f].otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.HERO or 
                                    fList[f].otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.SPRITE)
                    if isHero then   --Hero
                        local effectCfg = ConfigManager.getHeroEffectPathCfg()
                        local idx = tonumber(fList[f].otherData[CONST.OTHER_DATA.ITEM_ID] .. string.format("%03d", fList[f].otherData[CONST.OTHER_DATA.SPINE_SKIN]))
                        if effectCfg[idx] then
                            if effectCfg[idx].AttackHit then
                                fileNames = common:split(effectCfg[idx].AttackHit, ",")
                            end
                        end
                    else    --Monster
                        local monsterCfg = fList[f].otherData[CONST.OTHER_DATA.CFG]
                        if monsterCfg then
                            if monsterCfg.HitEffectPath then
                                fileNames = common:split(monsterCfg.HitEffectPath, ",")
                            end
                        end
                    end
                    eList[e].hurtEffect = eList[e].hurtEffect or { }
                    for i = 1, #fileNames do 
                        ALFManager:loadSpineTask("Spine/hit/", fileNames[i], 1, function() end)
                    end
                end
            end
        end
    end
end

return NgCharacterManager
