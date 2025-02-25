----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "EquipLeadPage"
local EquipScriptData = require("EquipScriptData")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local PBHelper = require("PBHelper")
local UserMercenaryManager = require("UserMercenaryManager")
local EquipOprHelper = require("Equip.EquipOprHelper")
local UserItemManager = require("UserItemManager")
local CONST = require("Battle.NewBattleConst")
local GuideManager = require("Guide.GuideManager")
local FateDataManager = require("FateDataManager")
require "Equip.AWTSelectPage"
local thisPageContainer = nil
local EquipLeadPage = {
    ccbiFile = "EquipmentPageRoleContent.ccbi"
}

local EquipPartNames = {
    ["Chest"] = Const_pb.CUIRASS,
    ["Feet"] = Const_pb.SHOES,
    ["MainHand"] = Const_pb.WEAPON1,
    ["Finger"] = Const_pb.RING,
    ["AncientWeapon"] = Const_pb.NECKLACE,
}
local pageToPart = {
    [RedPointManager.PAGE_IDS.CHAR_EQUIP1_SLOT] = Const_pb.WEAPON1,
    [RedPointManager.PAGE_IDS.CHAR_EQUIP2_SLOT] = Const_pb.CUIRASS,
    [RedPointManager.PAGE_IDS.CHAR_EQUIP3_SLOT] = Const_pb.RING,
    [RedPointManager.PAGE_IDS.CHAR_EQUIP4_SLOT] = Const_pb.SHOES,
    [RedPointManager.PAGE_IDS.CHAR_AW_SLOT] = Const_pb.NECKLACE,
}
local partToPage = {
    [Const_pb.WEAPON1] = RedPointManager.PAGE_IDS.CHAR_EQUIP1_SLOT,
    [Const_pb.CUIRASS] = RedPointManager.PAGE_IDS.CHAR_EQUIP2_SLOT,
    [Const_pb.RING] = RedPointManager.PAGE_IDS.CHAR_EQUIP3_SLOT,
    [Const_pb.SHOES] = RedPointManager.PAGE_IDS.CHAR_EQUIP4_SLOT,
    [Const_pb.NECKLACE] = RedPointManager.PAGE_IDS.CHAR_AW_SLOT,
}

local option = {
    ccbiFile = "EquipmentPageRoleContent_new.ccbi",
    handlerMap =
    {
        -- main page
        onHelp = "onHelp",
        onReturn = "onReturn",
        onLock = "onLock",              -- 鎖定
        onStory = "onStory",            -- 故事
        onRebirth = "onRebirth",        -- 重生
        onSetMainHero = "onSetMainHero",-- 設定主頁英雄
        onInfoPage = "onInfoPage",      -- 切換基礎資訊頁面
        onEquipPage = "onEquipPage",    -- 切換裝備頁面
        onUpgradePage = "onUpgradePage",-- 切換升星頁面
        onSkinPage = "onSkinPage",      -- 切換皮膚頁面
        -- info page
        onTrain = "onTrain",            -- 升級
        onDetail = "onAttributeDetail", -- 詳細屬性
        onMaxLv = "onMaxLv",            -- MaxLv
        -- equip page
        onAllEquip = "onAllEquip",      -- 自動穿裝
        onAllDisEquip = "onAllDisEquip",-- 自動脫裝
        -- upgrade page
        onUpgrade = "onUpgrade",        -- 升星
        -- skin page
        onChangeSkin = "onChangeSkin",  -- 更換皮膚
        onCostumeShop = "onCostumeShop",-- 皮膚商店
        onPlus = "onPlus",               --切換角色
        onMinus = "onMinus",              --切換角色
        onHide= "onHide",
        onExitHide="onExitHide",
    },
    opcodes = {
        ROLE_INFO_SYNC_S = HP_pb.ROLE_INFO_SYNC_S,
        EQUIP_DRESS_S = HP_pb.EQUIP_DRESS_S,
        EQUIP_ONEKEY_DRESS_S = HP_pb.EQUIP_ONEKEY_DRESS_S,
        BADGE_DRESS_S = HP_pb.BADGE_DRESS_S,
        -- 升等       
        ROLE_UP_LEVEL_C = HP_pb.ROLE_UP_LEVEL_C,
	    ROLE_UP_LEVEL_S = HP_pb.ROLE_UP_LEVEL_S,
        ROLE_LEVEL_MAX_S = HP_pb.ROLE_LEVEL_MAX_S,
        ROLE_LEVEL_MAX_C = HP_pb.ROLE_LEVEL_MAX_C,
        -- 升星
        ROLE_UPGRADE_STAR_C = HP_pb.ROLE_UPGRADE_STAR_C,
        ROLE_UPGRADE_STAR_S = HP_pb.ROLE_UPGRADE_STAR_S,
        -- 切換皮膚
        ROLE_CHANGE_SKIN_C = HP_pb.ROLE_CHANGE_SKIN_C,
        ROLE_CHANGE_SKIN_S = HP_pb.ROLE_CHANGE_SKIN_S,
        -- 同步羈絆資料
        FETCH_ARCHIVE_INFO_C = HP_pb.FETCH_ARCHIVE_INFO_C,
        FETCH_ARCHIVE_INFO_S = HP_pb.FETCH_ARCHIVE_INFO_S,
    }
}
for equipName, _ in pairs(EquipPartNames) do
    option.handlerMap["on" .. equipName] = "showEquipDetail"
end
for i = 1, 4 do
    option.handlerMap["onRune" .. i] = "onRune"
end
for i = 1, 4 do
    option.handlerMap["onSkill" .. i] = "showSkill"
end

local BTN_IMG = {
    [1] = { normal = "SubBtn_Stats.png", press = "SubBtn_Stats_On.png" },
    [2] = { normal = "SubBtn_Equip.png", press = "SubBtn_Equip_On.png" },
    [3] = { normal = "SubBtn_RairtyUP.png", press = "SubBtn_RairtyUP_On.png" },
    [4] = { normal = "SubBtn_Custome.png", press = "SubBtn_Custome_On.png" },
}

local selfContainer = nil
local trainTouchLayer = nil
local myProfessionSkillCfg = { }
local roleId = nil
local itemId = nil
local curRoleInfo = nil

local PAGE_TYPE = { BASE_INFO = 1, EQUIPMENT = 2, UPGRADE = 3, SKIN = 4 }
local nowPageType = PAGE_TYPE.BASE_INFO
local nowSpineName = ""
local nowChibiSkin = -1

local heroCfg = nil
local heroLevelCfg = ConfigManager.getHeroLevelCfg()
local heroStarCfg = ConfigManager.getHeroStarCfg()

local effectSpineParent = nil    -- 特效spine父節點
local effectSpine = nil  -- 特效spine

local awDetailPage = nil


local ITEM_NUM_COLOR = {
    ENOUGH = ccc3(48, 29, 9),
    NOT_ENOUGH = ccc3(255, 38, 0),
}
local LEVEL_UP_DATA = {
    COST_MONEY = 0,
    COST_EXP = 0,
    COST_STONE = 0,
    EXP_NUM = 0,
    STONE_NUM = 0,
    TOUCH_TIMECOUNT = 0,
    TOUCH_TIMEINTERVAL = 1,
    TOUCH_MAX_TIMEINTERVAL = 5,
    IS_TOUCHING = false,
}
local STAR_UP_DATA = {
    IS_ITEM_ENOUGH = true,
    STAR_UP_TABLE = { },
}
local STAR_IMG = {
    SR = "common_star_4.png",
    SSR = "common_star_2.png",
    UR = "common_star_3.png",
}
local COSTUME_DATA = {
    NOW_SKIN = 0,
    ALL_SKIN = { },
    OWN_SKIN = { },
    ORDER_MASK = 99,
    COSTUME_ITEMS = { },
    NOW_COSTUME_ID = 0,
    MOVE_TIME = 0.1,
    IS_MOVEING = false,
}

local mercenaryInfos = nil
local HeroTable={}
local nowRoleId_Idx=0

local AttributeContent = { }
local AttributeSetting = {
    { Const_pb.BUFF_CRITICAL_DAMAGE, 4 },
    { Const_pb.BUFF_AVOID_CONTROL, 6 },
    { Const_pb.BUFF_MAGDEF_PENETRATE, 3 },
    { Const_pb.BUFF_PHYDEF_PENETRATE, 3 },
    { Const_pb.RESILIENCE, 3 },
    { Const_pb.CRITICAL, 3 },
    { Const_pb.DODGE, 3 },
    { Const_pb.HIT, 3 },
    { Const_pb.MAGDEF, 2 },
    { Const_pb.PHYDEF, 2 },
    { Const_pb.HP, 5 },
    { Const_pb.MAGIC_attr, 5 },
    { Const_pb.ATTACK_attr, 5 },
}
function AttributeContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local key = AttributeSetting[self.id][1]
    local value = PBHelper:getAttrById(curRoleInfo.attribute.attribute, key)
    if AttributeSetting[self.id][2] == 4 or AttributeSetting[self.id][2] == 6 then
        NodeHelper:setStringForLabel(container, { mAtt1 = common:getLanguageString("@Specialattr_" .. key) })
    else
        NodeHelper:setStringForLabel(container, { mAtt1 = common:getLanguageString("@Combatattr_" .. key) })
    end
    if AttributeSetting[self.id][2] == 4 then
        value = (value + 100) .. "%"
    end
    if AttributeSetting[self.id][2] == 6 then
        value = value .. "%"
    end
    NodeHelper:setStringForLabel(container, { mAtt2 = value })
    if AttributeSetting[self.id][2] == 2 or AttributeSetting[self.id][2] == 3 then
        NodeHelper:setNodesVisible(container, { mAttr3 = true })
        NodeHelper:setStringForLabel(container, { mAtt3 = "(" .. EquipManager:getBattleAttrEffect(key, value, curRoleInfo.level) .. "%)" })
    else
        NodeHelper:setNodesVisible(container, { mAtt3 = false })
    end
    NodeHelper:setSpriteImage(container, { FightIcon = "attri_" .. key .. ".png" })
end
-----------------------------------------------------------------------------------------------------
function EquipLeadPage.onFunction(eventName, container)
    if option.handlerMap[eventName] then
        EquipLeadPage[option.handlerMap[eventName]](EquipLeadPage, container, eventName)
    end
end

function EquipLeadPage:onEnter(container)
    mercenaryInfos = UserMercenaryManager:getMercenaryStatusInfos()

    self.container = container

    if not self.container or tolua.isnull(self.container) then
        self.container = ScriptContentBase:create(EquipLeadPage.ccbiFile)
        thisPageContainer = self.container
    end
    self.container:registerFunctionHandler(EquipLeadPage.onFunction)
    self:registerPacket(self.container)
    selfContainer = self.container

    container:registerMessage(MSG_SEVERINFO_UPDATE)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container:registerMessage(MSG_MAINFRAME_POPPAGE)
    container:registerMessage(MSG_REFRESH_REDPOINT)

    curRoleInfo = UserMercenaryManager:getUserMercenaryById(roleId)
    itemId = curRoleInfo.itemId
    heroCfg = ConfigManager.getNewHeroCfg()[itemId]

    nowSpineName = ""
    nowChibiSkin = -1
    self:initRoleTable()
    self:initRoleStarTable(selfContainer)
    --self:initTrainTouchLayer(selfContainer)
    self:initSkinData(selfContainer)
    self:initSkinItem(selfContainer)
    self:initSpine(selfContainer)

    nowPageType = PAGE_TYPE.BASE_INFO
    self:refreshMainButton(container)
    self:refreshPage(selfContainer)
    self:showRoleSpine(selfContainer)

    if not GuideManager.isInGuide then
        container:runAnimation("SoulStarOpen")
    end
    ----------------------------------------------------------
    --新手教學
    GuideManager.PageContainerRef["EquipLeadPage"] = self.container
    PageManager.pushPage("NewbieGuideForcedPage")
    return self.container
end
-- 主頁面資訊更新
function EquipLeadPage:showMainPageInfo(container)
    -- 名稱顯示
    NodeHelper:setStringForLabel(container, { mLeaderName = common:getLanguageString("@HeroName_" .. itemId) })
    -- 星級顯示
    NodeHelper:setNodesVisible(container, { ["mStarSrNode"] = (curRoleInfo.starLevel <= 5), 
                                            ["mStarSsrNode"] = (curRoleInfo.starLevel > 5 and curRoleInfo.starLevel <= 10), 
                                            ["mStarUrNode"] = (curRoleInfo.starLevel > 10) })
    for i = 1, 5 do
        NodeHelper:setNodesVisible(container, { ["mStarSr" .. i] = (curRoleInfo.starLevel == i) })
        NodeHelper:setNodesVisible(container, { ["mStarSsr" .. i] = (curRoleInfo.starLevel - 5 == i) })
        NodeHelper:setNodesVisible(container, { ["mStarUr" .. i] = (curRoleInfo.starLevel - 10 == i) })
    end
    -- 屬性, 職業顯示
    NodeHelper:setSpriteImage(container, { mClassIcon = GameConfig.MercenaryClassImg[heroCfg.Job],
                                           mElementIcon = GameConfig.MercenaryElementImg[heroCfg.Element] })
    -- 等級, 戰力顯示
    local starCfg = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel]
    NodeHelper:setStringForLabel(container, { mLvTxtHero = curRoleInfo.level ,
                                              mLvMaxHero="/" .. starCfg.LimitLevel,
                                              mBpTxt = GameUtil:formatDotNumber(curRoleInfo.fight) })
    -- 星數到上限
    local isCanStarUp = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel + 1] and true or false
    NodeHelper:setMenuItemEnabled(container, "mBtn3", isCanStarUp )
    -- 重生按鈕顯示
    NodeHelper:setNodesVisible(container, { mResetNode = (curRoleInfo.level > 1) })
end
-- 刷新頁面
function EquipLeadPage:refreshPage(container)
    UserInfo.sync()
    curRoleInfo = UserMercenaryManager:getUserMercenaryById(roleId)
    self:setShowPage(container)
    self:showMainPageInfo(container)
    if nowPageType == PAGE_TYPE.BASE_INFO then
        self:showLevelUpInfo(container)
        self:showFightAttrInfo(container)
        self:showSkillInfo(container)
    elseif nowPageType == PAGE_TYPE.EQUIPMENT then
        self:showEquipInfo(container)
        self:showRuneInfo(container)
        self:showAllAttrInfo(container)
    elseif nowPageType == PAGE_TYPE.UPGRADE then
        self:showUpgradeInfo(container)
    elseif nowPageType == PAGE_TYPE.SKIN then
        self:refreshSkinUI(container)
    end
    self:refreshAllPoint(container)
end
-- UI顯示切換
function EquipLeadPage:setShowPage(container)
    -- 故事/服裝按鈕切換
    NodeHelper:setNodesVisible(container, { mTopBtnNormal = (nowPageType ~= PAGE_TYPE.SKIN), mTopBtnCostume = (nowPageType == PAGE_TYPE.SKIN) })
    -- 主UI切換
    NodeHelper:setNodesVisible(container, { mNormalUiNode = (nowPageType ~= PAGE_TYPE.SKIN), mCostumeUiNode = (nowPageType == PAGE_TYPE.SKIN) })
    -- 子UI切換
    NodeHelper:setNodesVisible(container, { mLevelUpPage = (nowPageType == PAGE_TYPE.BASE_INFO),
                                            mEquipmentPage = (nowPageType == PAGE_TYPE.EQUIPMENT),
                                            mUpgradePage = (nowPageType == PAGE_TYPE.UPGRADE) })
end
-- 
function EquipLeadPage:showRoleSpine(container, _spineName, _skinId)
    self:showTachieSpine(container, _spineName)
    self:showChibiSpine(container, _skinId)
end 
-- 設定立繪spine
function EquipLeadPage:showTachieSpine(container, _spineName) 
    local spineName = _spineName or ((COSTUME_DATA.NOW_SKIN == 0) and "NG2D_" .. string.format("%02d", itemId) or 
                                                                      "NG2D_" .. string.format("%02d", itemId) .. string.format("%03d", COSTUME_DATA.NOW_SKIN))
    if nowSpineName == spineName and not _spineName then
        return
    end
    local parentNode = container:getVarNode("mSpine")
    parentNode:removeAllChildrenWithCleanup(true)

    local spine = SpineContainer:create("NG2D", spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    spine:runAnimation(1, "animation", -1)
    spineNode:setScale(NodeHelper:getScaleProportion())
    parentNode:addChild(spineNode)

    nowSpineName = spineName
end
-- 設定小人spine
function EquipLeadPage:showChibiSpine(container, _skinId)
    local skinId = _skinId or COSTUME_DATA.NOW_SKIN
    if nowChibiSkin == skinId then
        return
    end
    nowChibiSkin = skinId
    local parentNode = container:getVarNode("mSpineLittle")
    parentNode:removeAllChildrenWithCleanup(true)
    local spineFolder, spineName = unpack(common:split(heroCfg.Spine, ","))
    spineName = spineName .. string.format("%03d", nowChibiSkin)

    local spine = SpineContainer:create(spineFolder, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    spine:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
    parentNode:addChild(spineNode)
    --
    local skinParentNode = container:getVarNode("mCostumeSpineNode")
    skinParentNode:removeAllChildrenWithCleanup(true)
    local skinSpine = SpineContainer:create(spineFolder, spineName)
    local skinSpineNode = tolua.cast(skinSpine, "CCNode")
    skinSpine:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
    skinParentNode:addChild(skinSpineNode)
end
-- 整理角色升星表格
function EquipLeadPage:initRoleStarTable(container)
    STAR_UP_DATA.STAR_UP_TABLE = { }
    for i = 1, #heroStarCfg do
        local heroId = heroStarCfg[i].RoleId
        STAR_UP_DATA.STAR_UP_TABLE[heroId] = STAR_UP_DATA.STAR_UP_TABLE[heroId] or { }
        table.insert(STAR_UP_DATA.STAR_UP_TABLE[heroId], heroStarCfg[i])
    end
end
--生成可切換的英雄表格
function EquipLeadPage:initRoleTable()
    HeroTable={}
    local EquipPage= require("Equip.EquipmentPage")
    local sortInfo = EquipPage:sortData(mercenaryInfos)
    for k,v in pairs (sortInfo) do
        if v.itemId<=24 and v.roleStage == Const_pb.IS_ACTIVITE then
            table.insert(HeroTable, sortInfo[k])
        end
    end
end
-- 建立升級按鈕的TouchLayer
function EquipLeadPage:initTrainTouchLayer(container)
    local layer = CCLayer:create()
    local trainBtn = container:getVarMenuItemImage("mTrainBtn")
    trainBtn:addChild(layer)
    local size = trainBtn:getContentSize()
    layer:setContentSize(size);
    layer:registerScriptTouchHandler(function(eventName, pTouch)
        if eventName == "began" then
            return EquipLeadPage:onTouchBegin(container, eventName, pTouch)
        elseif eventName == "moved" then
            return EquipLeadPage:onTouchMove(container, eventName, pTouch)
        elseif eventName == "ended" then
            return EquipLeadPage:onTouchEnd(container, eventName, pTouch)
        elseif eventName == "cancelled" then
            return EquipLeadPage:onTouchCancel(container, eventName, pTouch)
        end
    end
    , false, 0, false)
    layer:setTouchEnabled(true)
    trainTouchLayer = layer
end
-- 初始化皮膚資料
function EquipLeadPage:initSkinData(container)
    local allSkinData = common:split(heroCfg.Skin, ",")
    COSTUME_DATA.ALL_SKIN = { }
    COSTUME_DATA.OWN_SKIN = { }
    COSTUME_DATA.NOW_SKIN = 0
    table.insert(COSTUME_DATA.ALL_SKIN, 0)
    for i = 1, #allSkinData do
        if tonumber(allSkinData[i]) > 0 then
            table.insert(COSTUME_DATA.ALL_SKIN, tonumber(allSkinData[i]))
        end
    end
    COSTUME_DATA.OWN_SKIN[0] = true
    for i = 1, #curRoleInfo.ownSkin do
        COSTUME_DATA.OWN_SKIN[tonumber(curRoleInfo.ownSkin[i])] = true
    end
    COSTUME_DATA.NOW_SKIN = curRoleInfo.skinId
end
-- 返回初始skin卡片
function EquipLeadPage:returnToNowSkinItem(container)
    local changeId = 0
    for i = 1, #COSTUME_DATA.COSTUME_ITEMS do
        if COSTUME_DATA.COSTUME_ITEMS[i].skinId == COSTUME_DATA.NOW_SKIN then
            changeId = i
            break
        end
    end
    self:changeCostumeItem(container, COSTUME_DATA.NOW_COSTUME_ID, changeId, false)
end
-- 建立升級特效spine
function EquipLeadPage:initSpine(container)
    effectSpine = SpineContainer:create("Spine/NGUI", "NGUI_02_HLevelUp")
    local spineNode = tolua.cast(effectSpine, "CCNode")
    effectSpineParent = container:getVarNode("mSpineNode")
    effectSpineParent:removeAllChildrenWithCleanup(true)
    effectSpineParent:addChild(spineNode)
end
------------------------------------------------------------------------------------------
-- Main Page Button
------------------------------------------------------------------------------------------
function EquipLeadPage:onReturn(container)
    PageManager.refreshPage("EquipmentPage", "refreshScrollView")
    --PageManager.refreshPage("EquipmentPage", "refreshRedPoint")
    PageManager.popPage(thisPageName)
end

function EquipLeadPage:onInfoPage(container)
    if nowPageType == PAGE_TYPE.BASE_INFO then
        return
    end
    if not GuideManager.isInGuide then
        container:runAnimation("SoulStarOpen")
    end
    nowPageType = PAGE_TYPE.BASE_INFO
    self:refreshMainButton(container)
    self:returnToNowSkinItem(container)
    self:refreshPage(container)
    self:showRoleSpine(container)
end

function EquipLeadPage:onEquipPage(container)
    if nowPageType == PAGE_TYPE.EQUIPMENT then
        return
    end
    if not GuideManager.isInGuide then
        container:runAnimation("SoulStarOpen")
    end
    nowPageType = PAGE_TYPE.EQUIPMENT
    self:refreshMainButton(container)
    self:returnToNowSkinItem(container)
    self:refreshPage(container)
    self:showRoleSpine(container)
end

function EquipLeadPage:onUpgradePage(container)
    if nowPageType == PAGE_TYPE.UPGRADE then
        return
    end
    if not GuideManager.isInGuide then
        container:runAnimation("SoulStarOpen")
    end
    nowPageType = PAGE_TYPE.UPGRADE
    self:refreshMainButton(container)
    self:returnToNowSkinItem(container)
    self:refreshPage(container)
    self:showRoleSpine(container)
end

function EquipLeadPage:onSkinPage(container)
    if nowPageType == PAGE_TYPE.SKIN then
        return
    end
    nowPageType = PAGE_TYPE.SKIN
    self:refreshMainButton(container)
    self:returnToNowSkinItem(container)
    self:refreshPage(container)
    self:showRoleSpine(container)
end

function EquipLeadPage:onRebirth(container)
    require("HeroResetPage")
    HeroResetPage_setPageHeroInfo(roleId, itemId, curRoleInfo.level)
    PageManager.pushPage("HeroResetPage")
end

function EquipLeadPage:onSetMainHero(container)
    if itemId and COSTUME_DATA.NOW_SKIN then
        CCUserDefault:sharedUserDefault():setIntegerForKey("MAIN_HERO_" .. UserInfo.playerInfo.playerId, itemId .. string.format("%03d", COSTUME_DATA.ALL_SKIN[COSTUME_DATA.NOW_COSTUME_ID]))
        NodeHelper:setMenuItemEnabled(container, "mSetMainHeroBtn", false)
        MessageBoxPage:Msg_Box_Lan("@SetMainSpineSuccess")
    end
end

function EquipLeadPage:onStory(container)
    require("HeroBioPage")
    HeroBioPage_setPageRoleId(itemId)
    PageManager.pushPage("HeroBioPage")
end

function EquipLeadPage:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_HEROHELP);
end

--設定按鈕狀態
function EquipLeadPage:refreshMainButton(container)
    for i = 1, 4 do
        NodeHelper:setMenuItemImage(container, { ["mBtn" .. i] = { normal = (i == nowPageType) and BTN_IMG[i].press or BTN_IMG[i].normal, press = BTN_IMG[i].press } })
        NodeHelper:setNodesVisible(container, { ["mSelectEffect" .. i] = (i == nowPageType) })
    end
    local mainHero = CCUserDefault:sharedUserDefault():getIntegerForKey("MAIN_HERO_" .. UserInfo.playerInfo.playerId)
    NodeHelper:setMenuItemEnabled(container, "mSetMainHeroBtn", (mainHero ~= itemId * 1000 + COSTUME_DATA.ALL_SKIN[COSTUME_DATA.NOW_COSTUME_ID]))
end

function EquipLeadPage:onPlus(container)
     for k,v in pairs(HeroTable) do
        if v.roleId == roleId then
            nowRoleId_Idx=k
        end
    end
	if HeroTable[nowRoleId_Idx] and HeroTable[nowRoleId_Idx+1] then
        roleId=HeroTable[nowRoleId_Idx+1].roleId
    else
        roleId=HeroTable[1].roleId
    end
    curRoleInfo = UserMercenaryManager:getUserMercenaryById(roleId)
    itemId = curRoleInfo.itemId
    heroCfg = ConfigManager.getNewHeroCfg()[itemId]

    nowSpineName = ""
    nowChibiSkin = -1
    --self:initTrainTouchLayer(selfContainer)
    self:initSkinData(selfContainer)
    self:initSkinItem(selfContainer)
    self:initSpine(selfContainer)

    --nowPageType = PAGE_TYPE.BASE_INFO
    self:refreshMainButton(container)
    self:refreshPage(selfContainer)
    self:showRoleSpine(selfContainer)
end

function EquipLeadPage:onMinus(container)
    for k,v in pairs(HeroTable) do
        if v.roleId == roleId then
            nowRoleId_Idx=k
        end
    end
	if HeroTable[nowRoleId_Idx] and HeroTable[nowRoleId_Idx-1] then
        roleId=HeroTable[nowRoleId_Idx-1].roleId
    else
        roleId=HeroTable[#HeroTable].roleId
    end
     curRoleInfo = UserMercenaryManager:getUserMercenaryById(roleId)
    itemId = curRoleInfo.itemId
    heroCfg = ConfigManager.getNewHeroCfg()[itemId]

    nowSpineName = ""
    nowChibiSkin = -1
     self:initRoleStarTable(selfContainer)
    --self:initTrainTouchLayer(selfContainer)
    self:initSkinData(selfContainer)
    self:initSkinItem(selfContainer)
    self:initSpine(selfContainer)

    --nowPageType = PAGE_TYPE.BASE_INFO
    self:refreshMainButton(container)
    self:refreshPage(selfContainer)
    self:showRoleSpine(selfContainer)
end
function EquipLeadPage:onHide(container)
    NodeHelper:setNodesVisible(container,{mTopNode=false,mDetial=false,mBottomNode=false,mNextNode=false,mExitHide=true})
end

function EquipLeadPage:onExitHide(container)
    NodeHelper:setNodesVisible(container,{mTopNode=true,mDetial=true,mBottomNode=true,mNextNode=true,mExitHide=false})
end
------------------------------------------------------------------------------------------
-- Info Page
------------------------------------------------------------------------------------------
function EquipLeadPage:onTrain(container)
    if tonumber(LEVEL_UP_DATA.COST_MONEY) > tonumber(UserInfo.playerInfo.coin) or
       tonumber(LEVEL_UP_DATA.COST_EXP) > tonumber(LEVEL_UP_DATA.EXP_NUM) or
       tonumber(LEVEL_UP_DATA.COST_STONE) > tonumber(LEVEL_UP_DATA.STONE_NUM) then
        if LEVEL_UP_DATA.IS_TOUCHING then
            LEVEL_UP_DATA.TOUCH_TIMECOUNT = 0
            LEVEL_UP_DATA.TOUCH_TIMEINTERVAL = 1
            LEVEL_UP_DATA.IS_TOUCHING = false  
        end
        --MessageBoxPage:Msg_Box_Lan("@LackItem")
        PageManager.showConfirm(common:getLanguageString("@WarmlyTip"), common:getLanguageString("@itemgoto"), 
            function(isSure) 
                if isSure then
                    PageManager.pushPage("Inventory.InventoryPage") 
                end
            end, true, "@BackPackPageTitle", nil, true, 1, true, nil, nil, false)
        return
    end
    local starCfg = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel]
    if curRoleInfo.level >= starCfg.LimitLevel then
        if LEVEL_UP_DATA.IS_TOUCHING then
            LEVEL_UP_DATA.TOUCH_TIMECOUNT = 0
            LEVEL_UP_DATA.TOUCH_TIMEINTERVAL = 1
            LEVEL_UP_DATA.IS_TOUCHING = false  
        end
        MessageBoxPage:Msg_Box_Lan("@HeroLevelMax")
        return
    end
    NodeHelper:setMenuItemsEnabled(container,{ mMaxLv = false , mTrainBtn = false,mStoneBtn = false})
    local msg = Player_pb.HPRoleUPLevel()
	msg.roleId = roleId
    local GuideManager = require("Guide.GuideManager")
	common:sendPacket(HP_pb.ROLE_UP_LEVEL_C, msg, GuideManager.isInGuide or false)
end

function EquipLeadPage:onMaxLv(container)
    local addLevel = self:MaxLevelSync()
    if addLevel <= 0 then
        PageManager.showConfirm(common:getLanguageString("@WarmlyTip"), common:getLanguageString("@itemgoto"), 
            function(isSure) 
                if isSure then
                    PageManager.pushPage("Inventory.InventoryPage") 
                end
            end, true, "@BackPackPageTitle", nil, true, 1, true, nil, nil, false)
        return
    end
    NodeHelper:setMenuItemsEnabled(container,{ mMaxLv = false , mTrainBtn = false,mStoneBtn = false})
    local msg = Player_pb.HPRoleUPLevel()
	msg.roleId = roleId
	common:sendPacket(HP_pb.ROLE_LEVEL_MAX_C, msg, false)
end

function EquipLeadPage:onAttributeDetail(container, eventName)
    local PlayerAttributePage = require("PlayerAttributePage")
    PlayerAttributePage:setRoleInfo(curRoleInfo)
    PageManager.pushPage("PlayerAttributePage")
end

function EquipLeadPage:showSkill(container, eventName)
    local id = string.sub(eventName, -1)
    local skill = tonumber(common:split(heroCfg.Skills, ",")[tonumber(id)])
    local skillLv = 0
    for i = 1, #curRoleInfo.skills do
        if math.floor(curRoleInfo.skills[i].itemId / 10) == math.floor(skill / 10) then
            skillLv = curRoleInfo.skills[i] and tonumber(string.sub(curRoleInfo.skills[i].itemId, -1))
            break
        end
    end
    require("HeroSkillPage")
    HeroSkillPage_setPageRoleInfo(curRoleInfo.level, curRoleInfo.starLevel,roleId,itemId)
    HeroSkillPage_setPageSkillLevel(skillLv)
    HeroSkillPage_setPageSkillId(skill)
    PageManager.pushPage("HeroSkillPage")
end

function EquipLeadPage:showLevelUpInfo(container)
    local starCfg = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel]
    if curRoleInfo.level < starCfg.LimitLevel then  -- 未達等級上限
        local levelCfg = heroLevelCfg[curRoleInfo.level]
        local levelCost = common:split(levelCfg.Cost, ",")
        LEVEL_UP_DATA.EXP_NUM = levelCost[2] and UserItemManager:getCountByItemId(tonumber(common:split(levelCost[2], "_")[2])) or 0
        LEVEL_UP_DATA.STONE_NUM = levelCost[3] and UserItemManager:getCountByItemId(tonumber(common:split(levelCost[3], "_")[2])) or 0
        LEVEL_UP_DATA.COST_MONEY = tonumber(levelCost[1] and common:split(levelCost[1], "_")[3] or 0)
        LEVEL_UP_DATA.COST_EXP = tonumber(levelCost[2] and common:split(levelCost[2], "_")[3] or 0)
        LEVEL_UP_DATA.COST_STONE = tonumber(levelCost[3] and common:split(levelCost[3], "_")[3] or 0)
        NodeHelper:setNodesVisible(self.container, { mCostNode1 = (LEVEL_UP_DATA.COST_STONE <= 0), mCostNode2 = (LEVEL_UP_DATA.COST_STONE > 0) })
        local lb2Str = {
            mMoneyTxt1 = GameUtil:formatNumber(UserInfo.playerInfo.coin) .. " / " .. GameUtil:formatNumber(LEVEL_UP_DATA.COST_MONEY),
            mDiamondTxt1 = GameUtil:formatNumber(LEVEL_UP_DATA.EXP_NUM) .. " / " .. GameUtil:formatNumber(LEVEL_UP_DATA.COST_EXP),
            mMoneyTxt2 = GameUtil:formatNumber(UserInfo.playerInfo.coin) .. " / " .. GameUtil:formatNumber(LEVEL_UP_DATA.COST_MONEY),
            mDiamondTxt2 = GameUtil:formatNumber(LEVEL_UP_DATA.EXP_NUM) .. " / " .. GameUtil:formatNumber(LEVEL_UP_DATA.COST_EXP),
            mStoneTxt2 = GameUtil:formatNumber(LEVEL_UP_DATA.STONE_NUM) .. " / " .. GameUtil:formatNumber(LEVEL_UP_DATA.COST_STONE),
        }
        NodeHelper:setStringForLabel(self.container, lb2Str)
        NodeHelper:setNodesVisible(self.container, { mMaxLevelNode = false, mNonMaxLevelNode = true })
        NodeHelper:setColor3BForLabel(self.container, {
            mMoneyTxt1 = (UserInfo.playerInfo.coin >= LEVEL_UP_DATA.COST_MONEY) and ITEM_NUM_COLOR.ENOUGH or ITEM_NUM_COLOR.NOT_ENOUGH,
            mMoneyTxt2 = (UserInfo.playerInfo.coin >= LEVEL_UP_DATA.COST_MONEY) and ITEM_NUM_COLOR.ENOUGH or ITEM_NUM_COLOR.NOT_ENOUGH,
            mDiamondTxt1 = (LEVEL_UP_DATA.EXP_NUM >= LEVEL_UP_DATA.COST_EXP) and ITEM_NUM_COLOR.ENOUGH or ITEM_NUM_COLOR.NOT_ENOUGH,
            mDiamondTxt2 = (LEVEL_UP_DATA.EXP_NUM >= LEVEL_UP_DATA.COST_EXP) and ITEM_NUM_COLOR.ENOUGH or ITEM_NUM_COLOR.NOT_ENOUGH,
            mStoneTxt2 = (LEVEL_UP_DATA.STONE_NUM >= LEVEL_UP_DATA.COST_STONE) and ITEM_NUM_COLOR.ENOUGH or ITEM_NUM_COLOR.NOT_ENOUGH,
        })

        --最大升級
        local maxLevel=self:MaxLevelSync()
        local string=""
        if maxLevel>0 then
            string=common:getLanguageString("@fastUpgrade",maxLevel)
        else
            string=common:getLanguageString("@Upgrade")
        end
         NodeHelper:setStringForLabel(self.container, {mMaxLevelTxt=string})
        if LEVEL_UP_DATA.COST_STONE>0 then
            NodeHelper:setNodesVisible(self.container,{mLevelUp=false,mLevelMax=false,mStone=true})
        else
            NodeHelper:setNodesVisible(self.container,{mLevelUp=true,mLevelMax=true,mStone=false})
        end
    else
        NodeHelper:setNodesVisible(self.container, { mMaxLevelNode = true, mNonMaxLevelNode = false })
    end
end

function EquipLeadPage:MaxLevelSync()
    -- 获取当前角色等级的素材消耗
    local levelCfg = heroLevelCfg[curRoleInfo.level]
    local levelCost = common:split(levelCfg.Cost, ",")
    
    -- 获取升级所需素材的配置信息
    local starCfg = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel]
    
    -- 获取玩家当前拥有的素材数量
    local selfCoin = UserInfo.playerInfo.coin
    local selfExp = levelCost[2] and UserItemManager:getCountByItemId(tonumber(common:split(levelCost[2], "_")[2])) or 0
    local selfStone = UserItemManager:getCountByItemId(7181) or 0

    -- 每一级的升级素材消耗
    local levelCount = 0
    for level = curRoleInfo.level, starCfg.LimitLevel do
        -- 获取当前级别升级所需的素材数量
        local levelCfg = heroLevelCfg[level]
        local levelCost = common:split(levelCfg.Cost, ",")
        local cost = { }
        cost.coin = tonumber(levelCost[1] and common:split(levelCost[1], "_")[3] or 0)
        cost.exp = tonumber(levelCost[2] and common:split(levelCost[2], "_")[3] or 0)
        cost.stone = tonumber(levelCost[3] and common:split(levelCost[3], "_")[3] or 0)

        if levelCount == 0 and cost.stone > 0 then  -- 突破
            if selfStone >= cost.stone then
                levelCount = levelCount + 1
            end
            break
        end
        if levelCount ~= 0 and cost.stone > 0 then  -- 停在突破前
            break
        end
        if (selfCoin >= cost.coin) and (selfExp >= cost.exp) then   --一般升級
            selfCoin = selfCoin - cost.coin
            selfExp = selfExp - cost.exp
            levelCount = levelCount + 1
        else
            break 
        end
     end
     return levelCount
end

function EquipLeadPage:canLevelUp(_itemId, _roleInfo)
    -- 获取当前角色等级的素材消耗
    local roleInfo = _roleInfo or curRoleInfo
    local localItemId = _itemId or itemId
    local levelCfg = heroLevelCfg[roleInfo.level]
    local levelCost = common:split(levelCfg.Cost, ",")
    
    -- 获取升级所需素材的配置信息
    local starCfg = STAR_UP_DATA.STAR_UP_TABLE[localItemId][roleInfo.starLevel]
    
    -- 获取玩家当前拥有的素材数量
    local selfCoin = UserInfo.playerInfo.coin
    local selfExp = levelCost[2] and UserItemManager:getCountByItemId(tonumber(common:split(levelCost[2], "_")[2])) or 0
    local selfStone = UserItemManager:getCountByItemId(7181) or 0

    -- 每一级的升级素材消耗
    local level = roleInfo.level
    -- 获取当前级别升级所需的素材数量
    local levelCfg = heroLevelCfg[level]
    if not levelCfg then
        return false
    end
    local levelCost = common:split(levelCfg.Cost, ",")
    local cost = { }
    cost.coin = tonumber(levelCost[1] and common:split(levelCost[1], "_")[3] or 0)
    cost.exp = tonumber(levelCost[2] and common:split(levelCost[2], "_")[3] or 0)
    cost.stone = tonumber(levelCost[3] and common:split(levelCost[3], "_")[3] or 0)

    selfCoin = selfCoin - cost.coin
    selfExp = selfExp - cost.exp
    selfStone = selfStone - cost.stone

    if selfCoin < 0 or selfExp < 0 or selfStone < 0 then
        return false
    else
        return true
    end
end

function EquipLeadPage:showFightAttrInfo(container)
    local lb2Str = {
        mIntTxt = GameUtil:formatDotNumber(PBHelper:getAttrById(curRoleInfo.attribute.attribute, Const_pb.PHYDEF)),
        mDexTxt = GameUtil:formatDotNumber(PBHelper:getAttrById(curRoleInfo.attribute.attribute, Const_pb.MAGDEF)),
        mHpTxt = GameUtil:formatDotNumber(PBHelper:getAttrById(curRoleInfo.attribute.attribute, Const_pb.HP)),
        mFightPowerNum = UserInfo.roleInfo.fight,
        mMercenaryName = UserInfo.roleInfo.name .. " ( " .. common:getLanguageString(string.format("@ProfessionName_" .. UserInfo.roleInfo.prof)) .. " )",
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    if heroCfg.IsMag == 1 then
        NodeHelper:setStringForLabel(container, { mStrTxt = GameUtil:formatDotNumber(PBHelper:getAttrById(curRoleInfo.attribute.attribute, Const_pb.MAGIC_attr)) })
        NodeHelper:setSpriteImage(container, { mAttr1 = "attri_" .. Const_pb.MAGIC_attr .. ".png" })
    else
        NodeHelper:setStringForLabel(container, { mStrTxt = GameUtil:formatDotNumber(PBHelper:getAttrById(curRoleInfo.attribute.attribute, Const_pb.ATTACK_attr)) })
        NodeHelper:setSpriteImage(container, { mAttr1 = "attri_" .. Const_pb.ATTACK_attr .. ".png" })
    end
end

function EquipLeadPage:showAllAttrInfo(container)
    local attrScrollView = container:getVarScrollView("mAttrScrollView")
    attrScrollView:removeAllCell()
    for i = 13, 1, -1 do
        local cell = CCBFileCell:create()
        cell:setCCBFile("AttributeBattleContent.ccbi")
        local handler = common:new( { id = i }, AttributeContent)
        cell:registerFunctionHandler(handler)
        attrScrollView:addCell(cell)
    end
    attrScrollView:orderCCBFileCells()
    attrScrollView:setTouchEnabled(false)
end

function EquipLeadPage:showSkillInfo(container)
    local skills = common:split(heroCfg.Skills, ",")
    for k, v in ipairs(skills)do  
        local skillBaseId = string.sub(v, 1, 4)
        NodeHelper:setSpriteImage(self.container, { ["Skill" .. k] = "skill/S_" .. skillBaseId .. ".png" })
    end
    local ownSkills = curRoleInfo.skills
    for i = 1, 4 do
        NodeHelper:setStringForLabel(self.container, { ["mSkillLv" .. i] = 0 })
    end
    for i = 1, 4 do
        if ownSkills[i] then
            local skillIdx = math.floor(ownSkills[i].itemId / 10) % 10 + 1
            local level = string.sub(ownSkills[i].itemId, -1)
            NodeHelper:setStringForLabel(self.container, { ["mSkillLv" .. skillIdx] = level })
        end
    end
end
------------------------------------------------------------------------------------------
-- Equip Page
------------------------------------------------------------------------------------------
function EquipLeadPage:onAllEquip(container, eventName)
    local allEquipId = UserEquipManager:getEquipAll()   --取得全部未使用的裝備
    local userEquips = { }
    local bestEquips = { }
    for i = 1, 9 do -- 10號用作專武 不自動穿脫裝備
        userEquips[i] = UserMercenaryManager:getEquipByPart(roleId, i)
    end
    for k, v in pairs(allEquipId) do
        if v then
            if not UserEquipManager:isEquipDressed(v) then  --檢查是否正在裝備
                local equip1 = UserEquipManager:getUserEquipById(v)
                local score = equip1.score
                local part = EquipManager:getPartById(equip1.equipId)
                if part ~= "" then
                    if EquipManager:isDressable(equip1.equipId, curRoleInfo.prof) then -- 可裝備
                        if userEquips[part] == nil or UserEquipManager:getUserEquipById(userEquips[part].equipId).score < equip1.score then --包包裡有更強的裝備
                            if bestEquips[part] == nil or UserEquipManager:getUserEquipById(bestEquips[part].id).score < equip1.score then
                                bestEquips[part] = equip1   --紀錄可更換的裝備
                            end
                        end
                    end
                end
            end
        end
    end
    local size = 0
    for _ in pairs(bestEquips) do 
        if _ == Const_pb.CUIRASS or _ == Const_pb.SHOES or 
           _ == Const_pb.WEAPON1 or _ == Const_pb.RING then
            size = size + 1 
        end
    end
    if size <= 0 then    --沒有更好的裝備
        MessageBoxPage:Msg_Box_Lan("@NoBetterEquip")
        return
    end
    local equips, roleIs, types = { }, { }, { }
    for i = 1, 9 do -- 10號用作專武 不自動穿脫裝備
        if bestEquips[i] ~= nil then
            local dressType
            if userEquips[i] then
                dressType = GameConfig.DressEquipType.Change
            else
                dressType = GameConfig.DressEquipType.On
            end
            table.insert(equips, bestEquips[i].id)
            table.insert(roleIs, roleId)
            table.insert(types, dressType)
        end
    end
    EquipOprHelper:dressAllEquip(equips, roleIs, types)
end

function EquipLeadPage:onAllDisEquip(container, eventName)
    local equips, roleIs, types = { }, { }, { }
    for i = 1, 9 do -- 10號用作專武 不自動穿脫裝備
        local roleEquip = UserMercenaryManager:getEquipByPart(roleId, i)
        local dressType = GameConfig.DressEquipType.Off
        if roleEquip then
            table.insert(equips, roleEquip.equipId)
            table.insert(roleIs, roleId)
            table.insert(types, dressType)
        end
    end
    if #equips > 0 then
        EquipOprHelper:dressAllEquip(equips, roleIs, types)
    end
end

function EquipLeadPage:showEquipDetail(container, eventName)
    local partName = string.sub(eventName, 3)
    local part = EquipPartNames[partName]
    local isShowNotice = UserEquipManager:isPartNeedNotice(part, roleId)
    local roleEquip = UserMercenaryManager:getEquipByPart(roleId, part)

    if partName == "AncientWeapon" then
        if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.ANCIENT_WEAPON) then
            MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.ANCIENT_WEAPON))
            return
        end
    end

    if roleEquip then
        if part == Const_pb.NECKLACE then
            -- 專武資訊
            --local AWDetail = require("AncientWeapon.AncientWeaponDetail")
            --awDetailPage = AWDetail:new():init(container)
            --awDetailPage:setShowType(AncientWeaponDetail_showType.EQUIPED)
            --awDetailPage:setRoleId(roleId)
            --awDetailPage:loadUserEquip(roleEquip.equipId)
            --awDetailPage:show()
             require ("Equip.AWTSelectPage")
            PageManager.pushPage("AWTSelectPage")
            
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(0.1))
            array:addObject(CCCallFunc:create(function()
               AWTSelectPage_setPart(part, roleId,itemId)
            end))
            container:runAction(CCSequence:create(array))
            
        else
            PageManager.showEquipInfo(roleEquip.equipId, roleId, isShowNotice)
        end
    else
        if part == 10 then
            local AWTSelectPageBase = require ("Equip.AWTSelectPage")
            local ids = UserEquipManager:getEquipIdsByClass("Part", part)
            local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
            local haveRoleEquip = false
            for i = 1, #ids do
                local userEquip = UserEquipManager:getUserEquipById(ids[i])
                local equipId = userEquip.equipId
                if AncientWeaponDataMgr:getIsTargetHeroEquip(equipId, itemId) then
                    haveRoleEquip = true
                    break
                end
            end
            if not haveRoleEquip then
                MessageBoxPage:Msg_Box(common:getLanguageString("@ExclusiveEquip_Missing"))
                return
            end
            PageManager.pushPage("AWTSelectPage")
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(0.1))
            array:addObject(CCCallFunc:create(function()
               AWTSelectPage_setPart(part, roleId,itemId)
            end))
            container:runAction(CCSequence:create(array))
        else
            EquipSelectPage_setPart(part, roleId)
            PageManager.pushPage("EquipSelectPage")
        end
    end
end

function EquipLeadPage:showEquipInfo(container)
    if not container then
        return
    end
    local sprite2Img = { }
    local nodesVisible = { }
    local isLockAW = false
    
    for equipName, part in pairs(EquipPartNames) do
        if equipName ~= "AncientWeapon" then    -- 專武另外處理
            local icon = GameConfig.Image.ClickToSelect
            local quality = GameConfig.Default.Quality
            local childNode = container:getVarMenuItemCCB("m" .. equipName)        
            childNode = childNode:getCCBFile()
            setEquipStar(childNode, 0)
            local roleEquip = UserMercenaryManager:getEquipByPart(roleId, part)
            if roleEquip then
                local equipId = roleEquip.equipItemId
                icon = EquipManager:getIconById(equipId)
                quality = EquipManager:getQualityById(equipId)        
                setEquipStar(container, quality)
                sprite2Img["mPic"] = icon
            else
                local showPic = GameConfig.defaultEquipImage[equipName]
                sprite2Img["mPic"] = showPic
            end

            sprite2Img["mBg"] = NodeHelper:getImageBgByQuality(quality)
            sprite2Img["mFrame"] = GameConfig.MercenaryQualityImage[quality]

            NodeHelper:setSpriteImage(childNode, sprite2Img, scaleMap)
            NodeHelper:setNodesVisible(childNode, nodesVisible)
        else
            isLockAW = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.ANCIENT_WEAPON)
            NodeHelper:setNodesVisible(container, { mAncientLock = isLockAW })
            local roleEquip = UserMercenaryManager:getEquipByPart(roleId, part)
            local ancientImgs = { }
            if roleEquip then
                local equipId = roleEquip.equipItemId
                ancientImgs["mAncientIcon"] = EquipManager:getIconById(equipId)
                local quality = EquipManager:getQualityById(equipId)        

                ancientImgs["mAncientFrame"] = GameConfig.MercenaryQualityImage[quality]
                ancientImgs["mAncientBg"] = NodeHelper:getImageBgByQuality(quality)
            else
                ancientImgs["mAncientIcon"] = "UI/Mask/Image_Empty.png"
                ancientImgs["mAncientFrame"] = "UI/Mask/Image_Empty.png"
                ancientImgs["mAncientBg"] = "UI/Mask/Image_Empty.png"
            end
            NodeHelper:setSpriteImage(container, ancientImgs, { })
        end
    end
end

function EquipLeadPage:onRune(container, eventName)
    local partName = tonumber(string.sub(eventName, -1))
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY["RUNE_" .. partName], { hero_level = curRoleInfo.level, hero_star = curRoleInfo.starLevel }) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY["RUNE_" .. partName]))
        return
    end
    local childNode = container:getVarMenuItemCCB("mRune" .. partName)        
    childNode = childNode:getCCBFile()
    if childNode.runeInfo then
        require("RuneInfoPage")
        RuneInfoPage_setPageInfo(GameConfig.RuneInfoPageType.EQUIPPED, childNode.runeInfo.id, roleId, partName)
        PageManager.pushPage("RuneInfoPage")
    else
        require("FateWearsSelectPage")
        FateWearsSelectPage_setFate({ roleId = roleId, locPos = partName, currentFateId = nil })
        PageManager.pushPage("FateWearsSelectPage")
    end
end

function EquipLeadPage:showRuneInfo(container)
    if not container then
        return
    end
    for i = 1, 4 do
        local childNode = container:getVarMenuItemCCB("mRune" .. i)        
        childNode = childNode:getCCBFile()

        local sprite2Img = { }
        sprite2Img["mBg"] = "UI/Mask/Image_Empty.png"
        sprite2Img["mPic"] = "UI/Mask/Image_Empty.png"
        sprite2Img["mFrame"] = "UI/Mask/Image_Empty.png"
        NodeHelper:setSpriteImage(childNode, sprite2Img)
        local isLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY["RUNE_" .. i], { hero_level = curRoleInfo.level, hero_star = curRoleInfo.starLevel })
        NodeHelper:setNodesVisible(childNode, { mLock = isLock, mStarNode = false })

        childNode.runeInfo = nil
    end
    local dressInfo = curRoleInfo.dress
    for i = 1, #dressInfo do
        local pos = dressInfo[i].loc
        local itemId = dressInfo[i].itemId
        local childNode = container:getVarMenuItemCCB("mRune" .. math.min(pos, 4))        
        local cfg = ConfigManager.getFateDressCfg()[itemId]
        childNode = childNode:getCCBFile()

        NodeHelper:setNodesVisible(childNode, { mStarNode = true })

        NodeHelper:setSpriteImage(childNode, { mPic = cfg.icon, mFrame = NodeHelper:getImageByQuality(cfg.rare), 
                                               mBg = NodeHelper:getImageBgByQuality(cfg.rare) })
        for star = 1, 6 do
            NodeHelper:setNodesVisible(childNode, { ["mStar" .. star] = (star == cfg.star) })
        end
        childNode.runeInfo = dressInfo[i]
    end
end

function setEquipStar(container, quality)
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == quality) })
    end
end
------------------------------------------------------------------------------------------
-- Upgrade Page
------------------------------------------------------------------------------------------
function EquipLeadPage:showUpgradeInfo(container)
    -- 星數已達上限 -> 強制返回等級頁面
    if not STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel + 1] then
        self:onInfoPage(container)
        return
    end
    -- 設定星星顯示
    for i = 1, 5 do
        -- PRE
        if curRoleInfo.starLevel <= 5 then
            NodeHelper:setSpriteImage(container, { ["mStarPre" .. i] = STAR_IMG.SR })
            NodeHelper:setNodesVisible(container, { ["mStarPreNode" .. i] = true })
            NodeHelper:setNodesVisible(container, { ["mStarPre" .. i] = (curRoleInfo.starLevel >= i)})
            NodeHelper:setNodesVisible(container,{mSrNode01=true,mSsrNode01=false,mUrNode01=false})
        elseif curRoleInfo.starLevel > 10 then
            NodeHelper:setSpriteImage(container, { ["mStarPre" .. i] = STAR_IMG.UR })
            NodeHelper:setNodesVisible(container, { ["mStarPreNode" .. i] = (i <= 3) })
            NodeHelper:setNodesVisible(container, { ["mStarPre" .. i] = ((curRoleInfo.starLevel - 10) >= i) })
            NodeHelper:setNodesVisible(container,{mSrNode01=false,mSsrNode01=false,mUrNode01=true})
        else
            NodeHelper:setSpriteImage(container, { ["mStarPre" .. i] = STAR_IMG.SSR })
            NodeHelper:setNodesVisible(container, { ["mStarPreNode" .. i] = true })
            NodeHelper:setNodesVisible(container, { ["mStarPre" .. i] = ((curRoleInfo.starLevel - 5) >= i) })
            NodeHelper:setNodesVisible(container,{mSrNode01=false,mSsrNode01=true,mUrNode01=false})
        end
        -- NEW
        local newStarLevel = curRoleInfo.starLevel + 1
        if newStarLevel <= 5 then
            NodeHelper:setSpriteImage(container, { ["mStarNew" .. i] = STAR_IMG.SR })
            NodeHelper:setNodesVisible(container, { ["mStarNewNode" .. i] = true })
            NodeHelper:setNodesVisible(container, { ["mStarNew" .. i] = (newStarLevel >= i) })
            NodeHelper:setNodesVisible(container,{mSrNode02=true,mSsrNode02=false,mUrNode02=false})
        elseif newStarLevel > 10 then
            NodeHelper:setSpriteImage(container, { ["mStarNew" .. i] = STAR_IMG.UR })
            NodeHelper:setNodesVisible(container, { ["mStarNewNode" .. i] = (i <= 3) })
            NodeHelper:setNodesVisible(container, { ["mStarNew" .. i] = ((newStarLevel - 10) >= i) })
            NodeHelper:setNodesVisible(container,{mSrNode02=false,mSsrNode02=false,mUrNode02=true})
        else
            NodeHelper:setSpriteImage(container, { ["mStarNew" .. i] = STAR_IMG.SSR })
            NodeHelper:setNodesVisible(container, { ["mStarNewNode" .. i] = true })
            NodeHelper:setNodesVisible(container, { ["mStarNew" .. i] = ((newStarLevel - 5) >= i) })
            NodeHelper:setNodesVisible(container,{mSrNode02=false,mSsrNode02=true,mUrNode02=false})
        end
    end
    -- 突破消耗顯示
    STAR_UP_DATA.IS_ITEM_ENOUGH = true
    for i = 1, 3 do
        local costItems = common:split(STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel].Cost, ",")
        NodeHelper:setNodesVisible(container, { ["mUpgradeItemNode" .. i] = costItems[i] and true or false })
        if costItems[i] and costItems[i] ~= "" then
            NodeHelper:setNodesVisible(container, { ["mUpgradeItemNode" .. i] = true })
            local _type, _itemId, _num = unpack(common:split(costItems[i], "_"))
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_itemId), tonumber(_num))
            local childNode = container:getVarMenuItemCCB("mUpgradeItem" .. i)        
            childNode = childNode:getCCBFile()
            NodeHelper:setSpriteImage(childNode, { mFrameShade1 = NodeHelper:getImageBgByQuality(resInfo.quality) })
            NodeHelper:setSpriteImage(childNode, { mPic1 = resInfo.icon } )
            NodeHelper:setNormalImages(childNode, { mHand1 = GameConfig.QualityImage[resInfo.quality] })
            NodeHelper:setNodesVisible(childNode, { mName1 = false, mShader = false, mEquipLv = false, mNumber1 = false, mNumber1_1 = false })
            for j = 1, 6 do
                NodeHelper:setNodesVisible(childNode, { ["mStar" .. j] = false })    
            end
            local userNum = 0
            if tonumber(_type) == Const_pb.SOUL * 10000 then
                userNum = UserMercenaryManager:getMercenaryStatusByItemId(itemId).soulCount
            elseif tonumber(_type) == Const_pb.TOOL * 10000 then
                userNum = UserItemManager:getCountByItemId(tonumber(_itemId))
            end
            NodeHelper:setStringForTTFLabel(container, { ["mUpgradeItemNum" .. i] = userNum .. " / " .. _num })
            if tonumber(_num) > userNum then
                STAR_UP_DATA.IS_ITEM_ENOUGH = false
            end
            NodeHelper:setColor3BForLabel(container, {
                ["mUpgradeItemNum" .. i]  = (tonumber(userNum) >= tonumber(_num)) and ITEM_NUM_COLOR.ENOUGH or ITEM_NUM_COLOR.NOT_ENOUGH,
            })
        else
            NodeHelper:setNodesVisible(container, { ["mUpgradeItemNode" .. i] = false })
        end
    end
    -- 提升技能顯示
    local preSkills = common:split(STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel].Skills, ",")
    local newSkills = common:split(STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel + 1].Skills, ",")
    NodeHelper:setNodesVisible(container, { mUpgradeSkillNode = false })
    for i = 1, #newSkills do
        if tonumber(preSkills[i]) ~= tonumber(newSkills[i]) then
            NodeHelper:setSpriteImage(container, { mUpgradeSkillIcon = "skill/S_" .. string.sub(newSkills[i], 1, 4) .. ".png" })
            NodeHelper:setNodesVisible(container, { mUpgradeSkillNode = true })
            break
        end
    end
    -- 提升等級上限顯示
    NodeHelper:setStringForTTFLabel(container, { mUpgradeTxt = common:getLanguageString("@HeroLevelLimitUnlock", STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel + 1].LimitLevel) })

    NodeHelper:setStringForLabel(container, lb2Str)
end
-- 升星
function EquipLeadPage:onUpgrade(container)
    local nowStarInfo = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel]
    local nextStarInfo = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel + 1]
    if not STAR_UP_DATA.IS_ITEM_ENOUGH then
        MessageBoxPage:Msg_Box_Lan("@LackItem")
        return
    end
    if not nextStarInfo or not nowStarInfo then
        return
    end
    -- 預先設定升星視窗舊資料
    require("RarityUpResult")
    RarityUpPage_setOldAttr(curRoleInfo, nowStarInfo.LimitLevel)

    local msg = Player_pb.HPRoleUpStar()
	msg.roleId = roleId
	common:sendPacket(HP_pb.ROLE_UPGRADE_STAR_C, msg, true)
end
-- 彈跳升星結果視窗
function EquipLeadPage:showRarityResultPage(container)
    -- 設定升星視窗新資料
    local oldStarCfg = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel - 1]
    local starCfg = STAR_UP_DATA.STAR_UP_TABLE[itemId][curRoleInfo.starLevel]
    require("RarityUpResult")
    RarityUpPage_setNewAttr(curRoleInfo, starCfg.LimitLevel, oldStarCfg.Award)
    PageManager.pushPage("RarityUpResult")
end
------------------------------------------------------------------------------------------
-- Skin Page
------------------------------------------------------------------------------------------
local CostumeItem = {
    ccbiFile = "EquipmentPageRoleContent_CostumeItem.ccbi",
}
function CostumeItem.onFunction(eventname, container)
    if eventname == "onCostumeItem" then
        EquipLeadPage:changeCostumeItem(selfContainer, COSTUME_DATA.NOW_COSTUME_ID, container.id, true)
    end
end
function EquipLeadPage:initSkinItem(container)
    local itemParentNode = container:getVarNode("mCostumeItemsNode")
    COSTUME_DATA.COSTUME_ITEMS = { }
    COSTUME_DATA.IS_MOVEING = false
    COSTUME_DATA.NOW_COSTUME_ID = 3
    itemParentNode:removeAllChildren()
    local changeId = 1
    for i = 1, #COSTUME_DATA.ALL_SKIN do
        local itemCCB = ScriptContentBase:create(CostumeItem.ccbiFile)
        if itemCCB then
            local settingNode = container:getVarNode("mCostumePos" .. i)
            itemCCB:registerFunctionHandler(CostumeItem.onFunction)
            itemCCB.id = i
            itemCCB.settingId = i
            itemCCB.skinId = COSTUME_DATA.ALL_SKIN[i]
            itemCCB:setZOrder(COSTUME_DATA.ORDER_MASK - i)
            itemCCB:setPosition(settingNode:getPosition())
            itemCCB:setRotation(settingNode:getRotation())
            itemCCB:setScale(settingNode:getScale())
            itemParentNode:addChild(itemCCB)
            table.insert(COSTUME_DATA.COSTUME_ITEMS, itemCCB)
            local skinImgName = "HeroSkin_" .. string.format("%02d", itemId) .. string.format("%03d", COSTUME_DATA.ALL_SKIN[i])
            NodeHelper:setMenuItemImage(itemCCB, { mCostumeBtn = { normal = "UI/RoleSkinSeries/" .. skinImgName .. ".png", 
                                                                   press = "UI/RoleSkinSeries/" .. skinImgName .. ".png" } })
            NodeHelper:setNodesVisible(itemCCB, { mCostumeUseImg = (COSTUME_DATA.NOW_SKIN == COSTUME_DATA.ALL_SKIN[i]) })
            NodeHelper:setStringForLabel(itemCCB, { mCostumeName = common:getLanguageString("@HeroSkin_" .. string.format("%02d", COSTUME_DATA.ALL_SKIN[i])) })
            if COSTUME_DATA.NOW_SKIN == COSTUME_DATA.ALL_SKIN[i] then
                changeId = i
            end
        end
    end
    self:changeCostumeItem(container, COSTUME_DATA.NOW_COSTUME_ID, changeId, false)
end
function EquipLeadPage:refreshSkinUI(container)
    local skinId = COSTUME_DATA.ALL_SKIN[COSTUME_DATA.NOW_COSTUME_ID]
    NodeHelper:setNodesVisible(container, { mCostumeAbilityNode = (skinId ~= 0) })
    NodeHelper:setStringForLabel(container, { mCostumeDressTxt = common:getLanguageString("@SkinDress_" .. string.format("%02d", skinId)),
                                              mCostumeAllTxt = common:getLanguageString("@SkinAll_" .. string.format("%02d", skinId)) })
    for i = 1, #COSTUME_DATA.COSTUME_ITEMS do
        NodeHelper:setNodesVisible(COSTUME_DATA.COSTUME_ITEMS[i], { mCostumeUseImg = (COSTUME_DATA.NOW_SKIN == COSTUME_DATA.COSTUME_ITEMS[i].skinId) })
        NodeHelper:setNodesVisible(COSTUME_DATA.COSTUME_ITEMS[i], { mMask = (COSTUME_DATA.NOW_COSTUME_ID ~= i) })
        NodeHelper:setNodesVisible(COSTUME_DATA.COSTUME_ITEMS[i], { mMaskUse = (COSTUME_DATA.NOW_COSTUME_ID ~= i) and (COSTUME_DATA.NOW_SKIN == COSTUME_DATA.COSTUME_ITEMS[i].skinId) })
    end
    NodeHelper:setMenuItemEnabled(container, "mTrain", COSTUME_DATA.OWN_SKIN[skinId] or false )
end
function EquipLeadPage:changeCostumeItem(container, nowId, toId, showAni)
    local move = nowId - toId
    if move == 0 or COSTUME_DATA.IS_MOVEING then
        return
    end
    COSTUME_DATA.IS_MOVEING = true
    COSTUME_DATA.NOW_COSTUME_ID = toId
    local aniTime = showAni and COSTUME_DATA.MOVE_TIME or 0
    for idx = 1, #COSTUME_DATA.COSTUME_ITEMS do
        COSTUME_DATA.COSTUME_ITEMS[idx]:setZOrder(COSTUME_DATA.ORDER_MASK - math.abs(toId - COSTUME_DATA.COSTUME_ITEMS[idx].id))
        local seqAction = CCArray:create()
        for i = 1, math.abs(move) do
            local spawnAction = CCArray:create()
            local nowSettingIdx = COSTUME_DATA.COSTUME_ITEMS[idx].settingId
            local settingNode = container:getVarNode("mCostumePos" .. (move > 0 and nowSettingIdx + i or nowSettingIdx - i))
            spawnAction:addObject(CCMoveTo:create(aniTime / math.abs(move), settingNode and ccp(settingNode:getPosition()) or ccp(0, 0)))
            spawnAction:addObject(CCScaleTo:create(aniTime / math.abs(move), settingNode and settingNode:getScale() or 0))
            spawnAction:addObject(CCRotateTo:create(aniTime / math.abs(move), settingNode and settingNode:getRotation() or 0))
            seqAction:addObject(CCSpawn:create(spawnAction))
        end
        COSTUME_DATA.COSTUME_ITEMS[idx].settingId = COSTUME_DATA.COSTUME_ITEMS[idx].settingId + move
        if idx == #COSTUME_DATA.COSTUME_ITEMS then
            seqAction:addObject(CCCallFunc:create(function()
                COSTUME_DATA.IS_MOVEING = false
		    end))
        end
        COSTUME_DATA.COSTUME_ITEMS[idx]:runAction(CCSequence:create(seqAction))
    end
    self:refreshSkinUI(container)
    local spineName = (COSTUME_DATA.COSTUME_ITEMS[COSTUME_DATA.NOW_COSTUME_ID].skinId == 0) and 
                      "NG2D_" .. string.format("%02d", itemId) or 
                      "NG2D_" .. string.format("%02d", itemId) .. string.format("%03d", COSTUME_DATA.COSTUME_ITEMS[COSTUME_DATA.NOW_COSTUME_ID].skinId)
    self:showRoleSpine(container, spineName, COSTUME_DATA.COSTUME_ITEMS[COSTUME_DATA.NOW_COSTUME_ID].skinId)

    self:refreshMainButton(container)
end
function EquipLeadPage:onChangeSkin(container)
    local msg = RoleOpr_pb.HPChangeMercenarySkinReq()
	msg.fromRoleId = roleId
	msg.toRoleId = COSTUME_DATA.ALL_SKIN[COSTUME_DATA.NOW_COSTUME_ID]
    common:sendPacket(HP_pb.ROLE_CHANGE_SKIN_C, msg, false)
end
function EquipLeadPage:onCostumeShop(container)
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.SKIN_SHOP) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.SKIN_SHOP))
    else
        require("Reward.RewardPage"):setEntrySubPage("SkinShop")
        PageManager.pushPage("Reward.RewardPage")
    end
end
------------------------------------------------------------------------------------------
function EquipLeadPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName and UserEquipManager:hasInited() then
            self:refreshPage(selfContainer)
            if extraParam == "refreshIcon" then
                if awDetailPage then
                    awDetailPage:onReceiveMessage(container)
                end
            end
        elseif pageName == "EquipRefreshPage" and tonumber(extraParam) == roleId then
            self:refreshPage(selfContainer)
        end
    elseif typeId == MSG_MAINFRAME_POPPAGE then
        -- 宝石穿上和卸下更新主角界面武器上的状态
        local pageName = MsgMainFramePopPage:getTrueType(message).pageName
        if pageName ~= thisPageName then
            self:showEquipInfo(selfContainer)
        end
    elseif typeId == MSG_REFRESH_REDPOINT then
        -- 刷新紅點顯示
        self:refreshAllPoint(container)
    end
end

function EquipLeadPage:getPacketInfo()
end

function EquipLeadPage:onExecute(container)
end

function EquipLeadPage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EquipLeadPage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function EquipLeadPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    CCLuaLog("--------====-------OPCODE : " .. opcode)
    if opcode == option.opcodes.EQUIP_DRESS_S or opcode == option.opcodes.EQUIP_ONEKEY_DRESS_S then
        if awDetailPage then
            awDetailPage:onClose()
        end
        self:showEquipInfo(selfContainer)
        --新手教學
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            GuideManager.forceNextNewbieGuide()
        end
        -- 刷新紅點設定
        local pageIds = {
            RedPointManager.PAGE_IDS.CHAR_EQUIP1_SLOT, RedPointManager.PAGE_IDS.CHAR_EQUIP2_SLOT, 
            RedPointManager.PAGE_IDS.CHAR_EQUIP3_SLOT, RedPointManager.PAGE_IDS.CHAR_EQUIP4_SLOT,
        }
        for k, pageId in pairs(pageIds) do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            for i = 1, groupNum do    -- 24隻忍娘
                RedPointManager_refreshPageShowPoint(pageId, i)
            end
        end
    elseif opcode == option.opcodes.BADGE_DRESS_S then
        -- 刷新紅點設定
        local pageIds = {
            RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT, 
            RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT,
        }
        for k, pageId in pairs(pageIds) do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            for i = 1, groupNum do    -- 24隻忍娘
                RedPointManager_refreshPageShowPoint(pageId, i)
            end
        end
    elseif opcode == option.opcodes.ROLE_INFO_SYNC_S then
        UserEquipManager:checkAllEquipNotice()
        self:refreshPage(selfContainer)
    elseif opcode == option.opcodes.ROLE_UP_LEVEL_S then
        effectSpine:runAnimation(1, "animation", 0)
        self:refreshPage(selfContainer)
        --新手教學
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            GuideManager.forceNextNewbieGuide()
        end
        -- 刷新紅點設定
        local RedPointCfg = ConfigManager.getRedPointSetting()
        local groupNum = RedPointCfg[RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN].groupNum
        for i = 1, groupNum do    -- 24隻忍娘
            RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN, i)
        end
        local pageIds = {
            RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT, 
            RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT,
        }
        for k, pageId in pairs(pageIds) do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            for i = 1, groupNum do    -- 24隻忍娘
                local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(i)
                if roleInfo then
                    RedPointManager_refreshPageShowPoint(pageId, i, { lock = { hero_level = roleInfo.level, hero_star = roleInfo.starLevel } })
                end
            end
        end
        NodeHelper:setMenuItemsEnabled(container,{ mMaxLv = true , mTrainBtn = true,mStoneBtn = true})
    elseif opcode == option.opcodes.ROLE_LEVEL_MAX_S then
        effectSpine:runAnimation(1, "animation", 0)
        self:refreshPage(selfContainer)
        --新手教學
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isGuide then
            GuideManager.forceNextNewbieGuide()
        end
        -- 刷新紅點設定
        local RedPointCfg = ConfigManager.getRedPointSetting()
        local groupNum = RedPointCfg[RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN].groupNum
        for i = 1, groupNum do    -- 24隻忍娘
            RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN, i)
        end
        local pageIds = {
            RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT, 
            RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT,
        }
        for k, pageId in pairs(pageIds) do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            for i = 1, groupNum do    -- 24隻忍娘
                local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(i)
                if roleInfo then
                    RedPointManager_refreshPageShowPoint(pageId, i, { lock = { hero_level = roleInfo.level, hero_star = roleInfo.starLevel } })
                end
            end
        end
        NodeHelper:setMenuItemsEnabled(container,{ mMaxLv = true , mTrainBtn = true,mStoneBtn = true})
    elseif opcode == option.opcodes.ROLE_UPGRADE_STAR_S then
        self:refreshPage(selfContainer)
        self:showRarityResultPage(container)
        common:sendEmptyPacket(HP_pb.FETCH_ARCHIVE_INFO_C, false)
        -- 刷新紅點設定
        RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN, itemId)
        RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.CHAR_RARITYUP_BTN, itemId)
        local pageIds = {
            RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT, 
            RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT,
        }
        for k, pageId in pairs(pageIds) do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            for i = 1, groupNum do    -- 24隻忍娘
                local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(i)
                if roleInfo then
                    RedPointManager_refreshPageShowPoint(pageId, i, { lock = { hero_level = roleInfo.level, hero_star = roleInfo.starLevel } })
                end
            end
        end
    elseif opcode == option.opcodes.ROLE_CHANGE_SKIN_S then
        local msg = RoleOpr_pb.HPChangeMercenarySkinRes()
        msg:ParseFromString(msgBuff)
        COSTUME_DATA.NOW_SKIN = msg.toRoleId
        self:showRoleSpine(container)
        self:refreshSkinUI(selfContainer)

        MessageBoxPage:Msg_Box("@HasSwitch")
    elseif opcode == HP_pb.FETCH_ARCHIVE_INFO_S then
        local msg = RoleOpr_pb.HPArchiveInfoRes()
        local msgbuff = container:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        require("NgHeroPageManager")
        NgHeroPageManager_setServerFetterData(msg)
    end
end

function EquipLeadPage:onExit(container)
    local heroNode = self.container:getVarNode("mSpine")
    if heroNode then
        heroNode:removeAllChildren()
    end
    awDetailPage = nil
    self.container = nil
    self:removePacket(container)
    container:removeMessage(MSG_SEVERINFO_UPDATE)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container:removeMessage(MSG_MAINFRAME_POPPAGE)
    container:removeMessage(MSG_REFRESH_REDPOINT)
end

function EquipLeadPage:setMercenaryId(id)
    roleId = id
end
------------------------------------------------------------------------------------------
-- 按鈕事件
function EquipLeadPage:onTouchBegin(container, eventName, pTouch)
    local rect = GameConst:getInstance():boundingBox(trainTouchLayer)
    local point = trainTouchLayer:convertToNodeSpace(pTouch:getLocation())
    if GameConst:getInstance():isContainsPoint(rect, point) then
        LEVEL_UP_DATA.TOUCH_TIMECOUNT = 0
        LEVEL_UP_DATA.TOUCH_TIMEINTERVAL = 1
        LEVEL_UP_DATA.IS_TOUCHING = true
        return true
    end
    return false 
end
function EquipLeadPage:onTouchMove(container, eventName, pTouch)
end
function EquipLeadPage:onTouchEnd(container, eventName, pTouch)
    LEVEL_UP_DATA.TOUCH_TIMECOUNT = 0
    LEVEL_UP_DATA.TOUCH_TIMEINTERVAL = 1
    LEVEL_UP_DATA.IS_TOUCHING = false
end
function EquipLeadPage:onTouchCancel(container, eventName, pTouch)
    LEVEL_UP_DATA.TOUCH_TIMECOUNT = 0
    LEVEL_UP_DATA.TOUCH_TIMEINTERVAL = 1
    LEVEL_UP_DATA.IS_TOUCHING = false
end
function EquipLeadPage:onExecute(container)
    if nowPageType == PAGE_TYPE.BASE_INFO and LEVEL_UP_DATA.IS_TOUCHING then
        local dt = GamePrecedure:getInstance():getFrameTime()
        LEVEL_UP_DATA.TOUCH_TIMECOUNT = LEVEL_UP_DATA.TOUCH_TIMECOUNT + dt
        if LEVEL_UP_DATA.TOUCH_TIMECOUNT > 1 / LEVEL_UP_DATA.TOUCH_TIMEINTERVAL then
            LEVEL_UP_DATA.TOUCH_TIMEINTERVAL = math.min(LEVEL_UP_DATA.TOUCH_TIMEINTERVAL + 1, LEVEL_UP_DATA.TOUCH_MAX_TIMEINTERVAL)
            LEVEL_UP_DATA.TOUCH_TIMECOUNT = 0
            
            self:onTrain(container)
        end
    else
        LEVEL_UP_DATA.TOUCH_TIMECOUNT = 0
        LEVEL_UP_DATA.TOUCH_TIMEINTERVAL = 1
        LEVEL_UP_DATA.IS_TOUCHING = false   
    end
end

function EquipLeadPage_getCurRoleInfo()
    return curRoleInfo
end

function EquipLeadPage:refreshAllPoint(container)
    NodeHelper:setNodesVisible(container, { mBtnPoint1 = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_ATTR_TAB, itemId) })
    NodeHelper:setNodesVisible(container, { mBtnPoint2 = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_EQUIP_TAB, itemId) })
    NodeHelper:setNodesVisible(container, { mBtnPoint3 = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_RARITYUP_TAB, itemId) })
    NodeHelper:setNodesVisible(container, { mLvPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN, itemId) })
    NodeHelper:setNodesVisible(container, { mMaxLvPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN, itemId) })
    NodeHelper:setNodesVisible(container, { mBreakLvPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN, itemId) })
    NodeHelper:setNodesVisible(container, { mAutoEquipPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_AUTOEQUIP_BTN, itemId) })
    NodeHelper:setNodesVisible(container, { mRarityUpPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_RARITYUP_BTN, itemId) })
    NodeHelper:setNodesVisible(container, { mBioRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_INFO_BTN, itemId) })
    for equipName, part in pairs(EquipPartNames) do
        if equipName == "AncientWeapon" then
            NodeHelper:setNodesVisible(container, { mAWPoint = RedPointManager_getShowRedPoint(page, itemId) })
        else
            local childNode = container:getVarMenuItemCCB("m" .. equipName)  
            childNode = childNode:getCCBFile()
            local page = partToPage[part]
            NodeHelper:setNodesVisible(childNode, { mPoint = RedPointManager_getShowRedPoint(page, itemId) })
        end
    end
    local runePageIds = {
        RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT,
        RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT
    }
    for i = 1, 4 do
        local childNode = container:getVarMenuItemCCB("mRune" .. i)        
        childNode = childNode:getCCBFile()
        NodeHelper:setNodesVisible(childNode, { mPoint = RedPointManager_getShowRedPoint(runePageIds[i], itemId) })
    end
end

function EquipLeadPage_calCanLevelUp(_itemId)
    --local tempItemId = itemId
    EquipLeadPage:initRoleStarTable()
    --itemId = _itemId
    local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(_itemId)
    if not roleInfo then
        --itemId = tempItemId
        return false
    end
    local starCfg = STAR_UP_DATA.STAR_UP_TABLE[_itemId][roleInfo.starLevel]
    if roleInfo.level < starCfg.LimitLevel then  -- 未達等級上限
        local canLevelUp = EquipLeadPage:canLevelUp(_itemId, roleInfo)
        if canLevelUp then
            --itemId = tempItemId
            return true
        else
            --itemId = tempItemId
            return false
        end
    end
    --itemId = tempItemId
    return false
end

function EquipLeadPage_calCanRarityUp(charItemId)
    --local tempItemId = itemId
    EquipLeadPage:initRoleStarTable()
    --itemId = charItemId
    local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(charItemId)
    if not roleInfo then
        --itemId = tempItemId
        return false
    end
    for i = 1, 3 do
        local costItems = common:split(STAR_UP_DATA.STAR_UP_TABLE[charItemId][roleInfo.starLevel].Cost, ",")
        if roleInfo.starLevel == #STAR_UP_DATA.STAR_UP_TABLE[charItemId] then -- 滿星
            --itemId = tempItemId
            return false
        end
        if costItems[i] and costItems[i] ~= "" then
            local _type, _itemId, _num = unpack(common:split(costItems[i], "_"))
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_itemId), tonumber(_num))
            local userNum = 0
            if tonumber(_type) == Const_pb.SOUL * 10000 then
                userNum = UserMercenaryManager:getMercenaryStatusByItemId(itemId).soulCount
            elseif tonumber(_type) == Const_pb.TOOL * 10000 then
                userNum = UserItemManager:getCountByItemId(tonumber(_itemId))
            end
            if tonumber(_num) > userNum then
                --itemId = tempItemId
                return false
            end
        end
    end
    --itemId = tempItemId
    return true
end

function EquipLeadPage_calEquipShowPoint(pageId, _itemId)
    --local tempItemId = itemId
    --itemId = _itemId
    local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(_itemId)
    if not roleInfo then
        --itemId = tempItemId
        return false
    end
    local showNotice = UserEquipManager:isPartNeedNotice(pageToPart[pageId], roleInfo.roleId)
    --itemId = tempItemId
    return showNotice
end

function EquipLeadPage_calRuneShowPoint(pageId, _itemId)
    --local tempItemId = itemId
    --itemId = _itemId
    local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(_itemId)
    if not roleInfo then
        --itemId = tempItemId
        return false
    end
    local pageToSlot = {
        [RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT] = 1,
        [RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT] = 2,
        [RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT] = 3,
        [RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT] = 4,
    }
    local dressInfo = roleInfo.dress
    local nowRank = 0
    if dressInfo[pageToSlot[pageId]] then
        --local itemId = dressInfo[pageToSlot[pageId]].itemId     
        --local cfg = ConfigManager.getFateDressCfg()[itemId]
        --nowRank = cfg.rank
        return false    -- 有裝備就不顯示紅點
    end
    local showNotice = FateDataManager:getIsShowNotice(nowRank)

    --itemId = tempItemId
    return showNotice
end

local CommonPage = require('CommonPage')
EquipLeadPage = CommonPage.newSub(EquipLeadPage, thisPageName, option)
return EquipLeadPage