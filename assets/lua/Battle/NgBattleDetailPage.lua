local thisPageName = "NgBattleDetailPage"
local NodeHelper = require("NodeHelper")
local pageManager = require("PageManager")
local common = require("common")
local CONST = require("Battle.NewBattleConst")
local UserMercenaryManager = require("UserMercenaryManager")
require("Battle.NgBattleDataManager")
require("Battle.NgBattleDetailTestPage")

NgBattleDetailPage = NgBattleDetailPage or { }
local option = {
    ccbiFile = "CombatStats.ccbi",
    handlerMap =
    {
        onClose = "onClose",
    }
}
local DetailContent = {
    ccbiFile = "CombatStatsContent.ccbi"
}
local SCALE9_BASE_INSET = 13
local BAR_WIDTH = 163
local BAR_HEIGHT = 21
local isPlayerWin = true
NgBattleDetailPage.detailPageData = {
    [CONST.DETAIL_DATA_TYPE.DAMAGE] = 1, [CONST.DETAIL_DATA_TYPE.BEDAMAGE] = 1, [CONST.DETAIL_DATA_TYPE.HEALTH] = 1,
    [CONST.DETAIL_DATA_TYPE.DAMAGE + CONST.ENEMY_BASE_IDX] = 1, [CONST.DETAIL_DATA_TYPE.BEDAMAGE + CONST.ENEMY_BASE_IDX] = 1, [CONST.DETAIL_DATA_TYPE.HEALTH + CONST.ENEMY_BASE_IDX] = 1,
}

------------------------------------------------
function DetailContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end
function DetailContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local dmgBar = container:getVarScale9Sprite("mDmgBar")
    local beDmgBar = container:getVarScale9Sprite("mBeDmgBar")
    local healthBar = container:getVarScale9Sprite("mHealthBar")

    local maxDmg = (self.id < CONST.ENEMY_BASE_IDX) and NgBattleDetailPage.detailPageData[CONST.DETAIL_DATA_TYPE.DAMAGE]
                                                  or NgBattleDetailPage.detailPageData[CONST.DETAIL_DATA_TYPE.DAMAGE + CONST.ENEMY_BASE_IDX]
    local maxBeDmg = (self.id < CONST.ENEMY_BASE_IDX) and NgBattleDetailPage.detailPageData[CONST.DETAIL_DATA_TYPE.BEDAMAGE]
                                                    or NgBattleDetailPage.detailPageData[CONST.DETAIL_DATA_TYPE.BEDAMAGE + CONST.ENEMY_BASE_IDX]
    local maxHealth = (self.id < CONST.ENEMY_BASE_IDX) and NgBattleDetailPage.detailPageData[CONST.DETAIL_DATA_TYPE.HEALTH]
                                                     or NgBattleDetailPage.detailPageData[CONST.DETAIL_DATA_TYPE.HEALTH + CONST.ENEMY_BASE_IDX]

    local dmg = NgBattleDataManager.battleDetailData[self.id] and NgBattleDataManager.battleDetailData[self.id][CONST.DETAIL_DATA_TYPE.DAMAGE] or 0
    local beDmg = NgBattleDataManager.battleDetailData[self.id] and NgBattleDataManager.battleDetailData[self.id][CONST.DETAIL_DATA_TYPE.BEDAMAGE] or 0
    local health = NgBattleDataManager.battleDetailData[self.id] and NgBattleDataManager.battleDetailData[self.id][CONST.DETAIL_DATA_TYPE.HEALTH] or 0
    -- 數值文字設定
    NodeHelper:setStringForLabel(container, { mDmgTxt = dmg, mBeDmgTxt = beDmg, mHealthTxt = health })
    -- 進度條比例計算
    local dmgPer = math.max(0, math.min(1, dmg / maxDmg))
    local beDmgPer = math.max(0, math.min(1, beDmg / maxBeDmg))
    local healthPer = math.max(0, math.min(1, health / maxHealth))
    -- 重設9宮格點位(避免數值太小時變形)
    dmgBar:setInsetLeft((dmgPer * BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (dmgPer * BAR_WIDTH / 2))
    dmgBar:setInsetRight((dmgPer * BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (dmgPer * BAR_WIDTH / 2))
    beDmgBar:setInsetLeft((beDmgPer * BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (beDmgPer * BAR_WIDTH / 2))
    beDmgBar:setInsetRight((beDmgPer * BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (beDmgPer * BAR_WIDTH / 2))
    healthBar:setInsetLeft((healthPer * BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (healthPer * BAR_WIDTH / 2))
    healthBar:setInsetRight((healthPer * BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (healthPer * BAR_WIDTH / 2))
    -- BAR長度設定PLAYER_MVP_IDX
    dmgBar:setContentSize(CCSize(dmgPer * BAR_WIDTH, BAR_HEIGHT))
    beDmgBar:setContentSize(CCSize(beDmgPer * BAR_WIDTH, BAR_HEIGHT))
    healthBar:setContentSize(CCSize(healthPer * BAR_WIDTH, BAR_HEIGHT))
    dmgBar:setVisible(dmgPer > 0)
    beDmgBar:setVisible(beDmgPer > 0)
    healthBar:setVisible(healthPer > 0)
    -- MVP/SVP設定
    if self.id < CONST.ENEMY_BASE_IDX then -- 玩家
        NodeHelper:setNodesVisible(container, { mMvp = (isPlayerWin) and (self.id == NgBattleDataManager.playerMvpIndex),
                                                mSvp = (not isPlayerWin) and (self.id == NgBattleDataManager.playerMvpIndex)
        })
    else    -- 敵方(PVP才顯示MVP/SVP)
        NodeHelper:setNodesVisible(container, { mMvp = (not isPlayerWin) and (self.id == NgBattleDataManager.enemyMvpIndex) and (NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK),
                                                mSvp = (isPlayerWin) and (self.id == NgBattleDataManager.enemyMvpIndex) and (NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK)
        })
    end
    -- 頭像設定
    if self.itemId then
        if self.roleType == CONST.CHARACTER_TYPE.HERO then
            if self.id < CONST.ENEMY_BASE_IDX then -- 玩家
                local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(self.itemId)
                NodeHelper:setSpriteImage(container, { mHeadIcon = "UI/Role/Portrait_" .. string.format("%02d", self.itemId) .. string.format("%03d", roleInfo.skinId) .. ".png" })
            else    -- 敵方
                local skinId = NgBattleDataManager.battleEnemyCharacter[self.id - CONST.ENEMY_BASE_IDX].otherData[CONST.OTHER_DATA.SPINE_SKIN]
                NodeHelper:setSpriteImage(container, { mHeadIcon = "UI/Role/Portrait_" .. string.format("%02d", self.itemId) .. string.format("%03d", skinId) .. ".png" })
            end
        elseif self.roleType == CONST.CHARACTER_TYPE.MONSTER or self.roleType == CONST.CHARACTER_TYPE.WORLDBOSS then
            local cfg = ConfigManager.getNewMonsterCfg()[self.itemId]
            NodeHelper:setSpriteImage(container, { mHeadIcon = cfg.Icon })
        elseif self.roleType == CONST.CHARACTER_TYPE.SPRITE then
            NodeHelper:setSpriteImage(container, { mHeadIcon = "UI/Role/Portrait_" .. self.itemId .. ".png" })
        end
    end
    ---
    local testData = NgBattleDataManager.battleDetailDataTest
end

function DetailContent:onDetail1(container)
    if libOS:getInstance():getIsDebug() then
        --NgBattleDetailTestPage_setUiType(1, self.id)
        --PageManager.pushPage("NgBattleDetailTestPage")
    end
end
function DetailContent:onDetail2(container)
    if libOS:getInstance():getIsDebug() then
        --NgBattleDetailTestPage_setUiType(2, self.id)
        --PageManager.pushPage("NgBattleDetailTestPage")
    end
end
function DetailContent:onDetail3(container)
    if libOS:getInstance():getIsDebug() then
        --NgBattleDetailTestPage_setUiType(3, self.id)
        --PageManager.pushPage("NgBattleDetailTestPage")
    end
end
------------------------------------------------

function NgBattleDetailPage:onEnter(container)
    self:initUI(container)
    self:calculateMaxData(container)
    self:initScroll(container)
end

function NgBattleDetailPage:initUI(container)
    -- 背景/勝利失敗文字設定
    isPlayerWin = (NgBattleDataManager.battleResult == CONST.FIGHT_RESULT.WIN) or (NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS)
    NodeHelper:setSpriteImage(container, { mPlayerBg = isPlayerWin and "BG/UI/CombatStats_bgVictory.png" or "BG/UI/CombatStats_bgLost.png",
                                           mPlayerResult = isPlayerWin and "CombatStats_Victory.png" or "CombatStats_Lost.png",
                                           mEnemyBg = isPlayerWin and "BG/UI/CombatStats_bgLost.png" or "BG/UI/CombatStats_bgVictory.png",
                                           mEnemyResult = isPlayerWin and "CombatStats_Lost.png" or "CombatStats_Victory.png",
    })
    -- 玩家頭像/名稱設定
    local roleIcon = ConfigManager.getRoleIconCfg()
    local trueIcon = GameConfig.headIconNew or UserInfo.playerInfo.headIcon
    local icon, bgIcon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)

    if not roleIcon[trueIcon] then
        local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
        if NodeHelper:isFileExist(icon) then
            NodeHelper:setSpriteImage(container, { mPlayerIcon = icon })
        end
    else
        NodeHelper:setSpriteImage(container, { mPlayerIcon = roleIcon[trueIcon].MainPageIcon })
    end
    NodeHelper:setStringForLabel(container, { mPlayerName = UserInfo.roleInfo.name })
    -- 敵人頭像/名稱設定
    local mapId = NgBattleDataManager.battleMapId
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK or NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        local mapCfg = ConfigManager.getNewMapCfg()
        local chapter = mapCfg[mapId].Chapter
        local level = mapCfg[mapId].Level
        --local mainCh, childCh = unpack(common:split(chapter, "-"))
        local txt = common:getLanguageString("@MapFlag" .. chapter) .. level
        NodeHelper:setStringForLabel(container, { mEnemyName = txt })
        NodeHelper:setSpriteImage(container, { mEnemyIcon = "monster/Monster_" .. mapCfg[mapId].Portrait .. ".png" })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local cfg = ConfigManager:getMultiEliteCfg()
        NodeHelper:setStringForLabel(container, { mEnemyName = cfg[NgBattleDataManager.dungeonId].name })
        NodeHelper:setSpriteImage(container, { mEnemyIcon = "monster/Monster_" .. cfg[NgBattleDataManager.dungeonId].monsterId .. ".png" })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        NodeHelper:setStringForLabel(container, { mEnemyName = NgBattleDataManager.arenaName })
        NodeHelper:setSpriteImage(container, { mEnemyIcon = NgBattleDataManager.arenaIcon })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local cfg = ConfigManager.getMultiElite2Cfg()
        NodeHelper:setStringForLabel(container, { mEnemyName = cfg[NgBattleDataManager.dungeonId].name })
        NodeHelper:setSpriteImage(container, { mEnemyIcon = "monster/Monster_" .. cfg[NgBattleDataManager.dungeonId].monsterId .. ".png" })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
    end
end

function NgBattleDetailPage:initScroll(container)
    container.mPlayerScrollView = container:getVarScrollView("mPlayerContent")
    container.mPlayerScrollView:removeAllCell()
    local num = 0
    for i = 1, CONST.HERO_COUNT + CONST.SPRITE_COUNT do
        local chaNode = NgBattleDataManager.battleMineCharacter[i] or NgBattleDataManager.battleMineSprite[i]
        if chaNode then
            local cell = CCBFileCell:create()
            cell:setCCBFile(DetailContent.ccbiFile)
            local handler = common:new({ id = chaNode.idx, itemId = chaNode.otherData[CONST.OTHER_DATA.ITEM_ID],
                                         roleType = chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] }, DetailContent)
            cell:registerFunctionHandler(handler)
            container.mPlayerScrollView:addCell(cell)
            num = num + 1
        end
    end
    container.mPlayerScrollView:setTouchEnabled(num > 5)
    container.mPlayerScrollView:orderCCBFileCells()

    container.mEnemyScrollView = container:getVarScrollView("mEnemyContent")
    container.mEnemyScrollView:removeAllCell()
    num = 0
    for i = 1, CONST.ENEMY_COUNT + CONST.SPRITE_COUNT do
        local chaNode = NgBattleDataManager.battleEnemyCharacter[i] or NgBattleDataManager.battleEnemySprite[i]
        if chaNode then
            local cell = CCBFileCell:create()
            cell:setCCBFile(DetailContent.ccbiFile)
            local handler = common:new({ id = chaNode.idx, itemId = chaNode.otherData[CONST.OTHER_DATA.ITEM_ID],
                                         roleType = chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] }, DetailContent)
            cell:registerFunctionHandler(handler)
            container.mEnemyScrollView:addCell(cell)
            num = num + 1
        end
    end
    container.mEnemyScrollView:setTouchEnabled(num > 5)
    container.mEnemyScrollView:orderCCBFileCells()
end

function NgBattleDetailPage:calculateMaxData(container)
    for k, v in pairs(NgBattleDataManager.battleDetailData) do
        if k < CONST.ENEMY_BASE_IDX then
            for _type = 1, 3 do
                NgBattleDetailPage.detailPageData[_type] = math.max(NgBattleDetailPage.detailPageData[_type] or 0, v[_type] or 0)
            end
        else
            for _type = 1, 3 do
                NgBattleDetailPage.detailPageData[_type + CONST.ENEMY_BASE_IDX] = math.max(NgBattleDetailPage.detailPageData[_type + CONST.ENEMY_BASE_IDX] or 0, v[_type] or 0)
            end
        end
    end
end

function NgBattleDetailPage_calculateMvp(container)
    local playerBestScore = -1
    local enemyBestScore = -1
    for k, v in pairs(NgBattleDataManager.battleDetailData) do
        if k < CONST.ENEMY_BASE_IDX then
            local score = (v[CONST.DETAIL_DATA_TYPE.DAMAGE] or 0) * 1.5 + (v[CONST.DETAIL_DATA_TYPE.BEDAMAGE] or 0) * 1 + (v[CONST.DETAIL_DATA_TYPE.HEALTH] or 0) * 1
            NgBattleDataManager.playerMvpIndex = (score > playerBestScore) and k or NgBattleDataManager.playerMvpIndex
            playerBestScore = math.max(score, playerBestScore)
        else
            local score = (v[CONST.DETAIL_DATA_TYPE.DAMAGE] or 0) * 1.5 + (v[CONST.DETAIL_DATA_TYPE.BEDAMAGE] or 0) * 1 + (v[CONST.DETAIL_DATA_TYPE.HEALTH] or 0) * 1
            NgBattleDataManager.enemyMvpIndex = (score > enemyBestScore) and k or NgBattleDataManager.enemyMvpIndex
            enemyBestScore = math.max(score, enemyBestScore)
        end
    end
end

function NgBattleDetailPage_formatLogString(result)
    local resultStr = result
    local resultAtkStr = ""
    local resultDefStr = ""
    for k, v in pairs(NgBattleDataManager.battleDetailData) do
        local newStr = ""
        local dmg = v[CONST.DETAIL_DATA_TYPE.DAMAGE] or 0
        local beDmg = v[CONST.DETAIL_DATA_TYPE.BEDAMAGE] or 0
        local health = v[CONST.DETAIL_DATA_TYPE.HEALTH] or 0
        newStr = k .. ":[D:" .. dmg .. ",T:" .. beDmg .. ",H:" .. health .. "],"
        if k < 10 then
            resultAtkStr = resultAtkStr .. newStr
        else
            resultDefStr = resultDefStr .. newStr
        end
    end
    local str = resultStr .. "#" .. resultAtkStr .. "#" .. resultDefStr
    return str
end

function NgBattleDetailPage:resetData(container)
    for k, v in pairs(NgBattleDetailPage.detailPageData) do
        NgBattleDetailPage.detailPageData[k] = 1
    end
    isPlayerWin = true
end

function NgBattleDetailPage:onClose(container)
    self:resetData(container)
    PageManager.popPage(thisPageName)
end

local CommonPage = require("CommonPage")
NgBattleDetailPage = CommonPage.newSub(NgBattleDetailPage, thisPageName, option)

return NgBattleDetailPage