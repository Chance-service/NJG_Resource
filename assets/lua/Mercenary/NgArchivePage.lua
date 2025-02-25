----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "NgArchivePage"
local EquipScriptData = require("EquipScriptData")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local PBHelper = require("PBHelper")
local UserMercenaryManager = require("UserMercenaryManager")
local EquipOprHelper = require("Equip.EquipOprHelper")
local UserItemManager = require("UserItemManager")
local CONST = require("Battle.NewBattleConst")
local FateDataManager = require("FateDataManager")
local GuideManager = require("Guide.GuideManager")
local thisPageContainer = nil
local NgArchivePage = {
    ccbiFile = "NgArchivePage.ccbi"
}

local EquipPartNames = {
    ["Chest"] = Const_pb.CUIRASS,
    ["Feet"] = Const_pb.SHOES,
    ["MainHand"] = Const_pb.WEAPON1,
    ["Finger"] = Const_pb.RING,
}

local option = {
    ccbiFile = "NgArchivePage.ccbi",
    handlerMap =
    {
        -- main page
        onReturn = "onReturn",
        onStory = "onStory",            -- 故事
        onInfoPage = "onInfoPage",      -- 切換基礎資訊頁面
        onSkinPage = "onSkinPage",      -- 切換皮膚頁面
        onCostumeShop = "onCostumeShop",-- 開啟皮膚商城
        onChangInfo = "onChangInfo",    --切換Max&Min
        onPlus="onPlus",                --切換角色
        onMinus="onMinus",               --切換角色
        onHide="onHide",
        onExitHide="onExitHide"
    },
    opcodes = {
    }
}
for i = 1, 4 do
    option.handlerMap["onSkill" .. i] = "showSkill"
end

local BTN_IMG = {
    [1] = { normal = "SubBtn_Stats.png", press = "SubBtn_Stats_On.png" },
    [4] = { normal = "SubBtn_Custome.png", press = "SubBtn_Custome_On.png" },
}

local selfContainer = nil
local itemId = nil

local PAGE_TYPE = { BASE_INFO = 1, SKIN = 4 }
local nowPageType = PAGE_TYPE.BASE_INFO
local nowSpineName = ""
local nowChibiSkin = -1

local heroCfg = nil
local heroArchiveCfg = nil
local heroLevelCfg = ConfigManager.getHeroLevelCfg()

local SkinActive=false
local SkinId = 0

local ITEM_NUM_COLOR = {
    ENOUGH = ccc3(48, 29, 9),
    NOT_ENOUGH = ccc3(255, 38, 0),
}
local COSTUME_DATA = {
    NOW_SKIN = 0,
    ALL_SKIN = { },
    OWN_SKIN = { },
    ORDER_MASK = 99,
    COSTUME_ITEMS = { },
    NOW_COSTUME_ID = 1,
    MOVE_TIME = 0.1,
    IS_MOVEING = false,
}
local isMax=true
local SortedId={}
-----------------------------------------------------------------------------------------------------
function NgArchivePage.onFunction(eventName, container)
    if option.handlerMap[eventName] then
        NgArchivePage[option.handlerMap[eventName]](NgArchivePage, container, eventName)
    end
end
function NgArchivePage_setData(data)
    local tmp=table.merge(data[1],data[2])
    for k,v in pairs (tmp) do
        table.insert(SortedId,v.roleId)
    end
end
function table.merge(t1, t2)
    for k, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end
function NgArchivePage:onEnter(container)
    self.container = container
   
    if not self.container or tolua.isnull(self.container) then
        self.container = ScriptContentBase:create(NgArchivePage.ccbiFile)
        thisPageContainer = self.container
    end
    self.container:registerFunctionHandler(NgArchivePage.onFunction)
    selfContainer = self.container
    heroCfg = ConfigManager.getNewHeroCfg()[itemId]
    heroArchiveCfg = ConfigManager.getHeroEncyclopediaCfg()[itemId]

    nowSpineName = ""
    nowChibiSkin = -1

    if SkinActive then
        nowPageType = PAGE_TYPE.SKIN
    else
        nowPageType = PAGE_TYPE.BASE_INFO
    end
    container:registerMessage(MSG_REFRESH_REDPOINT)
    self:initSkinData(selfContainer)
    self:initSkinItem(selfContainer)
    self:refreshMainButton(container)
    self:refreshPage(selfContainer) 
    --self:showRoleSpine(selfContainer)
    --if SkinActive then
    --    self:onSkinPage(selfContainer)
    --end
    if not GuideManager.isInGuide then
        container:runAnimation("SoulStarOpen")
    end
end
function NgArchivePage:onCostumeSkin()
    if SkinActive then
        NgArchivePage:changeCostumeItem(selfContainer, COSTUME_DATA.NOW_COSTUME_ID, SkinId, false)
        SkinActive=false
    end
end
-- 主頁面資訊更新
function NgArchivePage:showMainPageInfo(container)
    -- 名稱顯示
    NodeHelper:setStringForLabel(container, { mLeaderName = common:getLanguageString("@HeroName_" .. itemId) })
    -- 屬性, 職業顯示
    NodeHelper:setSpriteImage(container, { mClassIcon = GameConfig.MercenaryClassImg[heroCfg.Job],
                                           mElementIcon = GameConfig.MercenaryElementImg[heroCfg.Element] })
     -- 等級, 戰力顯示
    if isMax then
        NodeHelper:setStringForLabel(container, { mLvTxtHero = heroArchiveCfg.MaxLevel,mLvMaxHero="/" .. heroArchiveCfg.MaxLevel, mBpTxt = heroArchiveCfg.MaxBp })
        NodeHelper:setNodesVisible(container, { mStarSrNode =false, mStarSsrNode = false, mStarUrNode = true})
        for i = 1, 5 do
            NodeHelper:setNodesVisible(container, { ["mStarSr" .. i] = (i == 5) })
            NodeHelper:setNodesVisible(container, { ["mStarSsr" .. i] = (i == 5) })
            NodeHelper:setNodesVisible(container, { ["mStarUr" .. i] = (i == 3) })
        end
    else
        local MinStar=ConfigManager.getNewHeroCfg()[itemId].Star
        local MinMaxLevel=(MinStar<=5 and "100" ) or(MinStar>5 and MinStar<=10 and "140")
        NodeHelper:setStringForLabel(container, { mLvTxtHero = 1,mLvMaxHero="/" .. MinMaxLevel, mBpTxt = heroArchiveCfg.MinBp })
        NodeHelper:setNodesVisible(container, { ["mStarSrNode"] = (MinStar <= 5), 
                                            ["mStarSsrNode"] = (MinStar > 5 and MinStar <= 10), 
                                            ["mStarUrNode"] = (MinStar > 10) })
        for i = 1, 5 do
            NodeHelper:setNodesVisible(container, { ["mStarSr" .. i] = (i == 1) })
            NodeHelper:setNodesVisible(container, { ["mStarSsr" .. i] = (i == 1) })
            NodeHelper:setNodesVisible(container, { ["mStarUr" .. i] = (i == 1) })
        end
    end
    -- .. "/" .. heroArchiveCfg.MaxLevel
end
-- 刷新頁面
function NgArchivePage:refreshPage(container)
    UserInfo.sync()
    self:setShowPage(container)
    self:showMainPageInfo(container)
    if nowPageType == PAGE_TYPE.BASE_INFO then
        self:showFightAttrInfo(container)
        self:showSkillInfo(container)
    elseif nowPageType == PAGE_TYPE.SKIN then
        self:refreshSkinUI(container)
    end
    self:refreshAllPoint(container)
end
-- UI顯示切換
function NgArchivePage:setShowPage(container)
    -- 故事/服裝按鈕切換
    NodeHelper:setNodesVisible(container, { mTopBtnNormal = (nowPageType ~= PAGE_TYPE.SKIN), mTopBtnCostume = (nowPageType == PAGE_TYPE.SKIN) })
    -- 主UI切換
    NodeHelper:setNodesVisible(container, { mNormalUiNode = (nowPageType ~= PAGE_TYPE.SKIN), mCostumeUiNode = (nowPageType == PAGE_TYPE.SKIN) })
    -- 子UI切換
    NodeHelper:setNodesVisible(container, { mLevelUpPage = (nowPageType == PAGE_TYPE.BASE_INFO) })

    local merStatus = UserMercenaryManager:getMercenaryStatusByItemId(itemId)
    if merStatus.roleStage == Const_pb.IS_ACTIVITE then
        NodeHelper:setNodesVisible(container,{mDontHave=false})
    else
        NodeHelper:setNodesVisible(container,{mDontHave=true})
    end
     NodeHelper:setNodesVisible(container,{mTopNode=true,mDetial=false,mBottomNode=true,mExitHide=false})
end
-- 
function NgArchivePage:showRoleSpine(container, _spineName, _skinId)
    self:showTachieSpine(container, _spineName, _skinId)
    self:showChibiSpine(container, _skinId)
end 
-- 設定立繪spine
function NgArchivePage:showTachieSpine(container, _spineName, _skinId) 
    local skinId = _skinId or COSTUME_DATA.NOW_SKIN
    local spineName = "NG2D_" .. string.format("%02d", itemId) .. (skinId ~= 0 and string.format("%03d", skinId) or "")
    if nowSpineName == spineName and not _spineName then
        return
    end
    local parentNode = container:getVarNode("mSpine")
    parentNode:removeAllChildrenWithCleanup(true)

    --if NodeHelper:isFileExist("Spine/NG2D/" .. spineName .. ".skel") then
        local spine = SpineContainer:create("NG2D", spineName)
        local spineNode = tolua.cast(spine, "CCNode")
        spine:runAnimation(1, "animation", -1)
        spineNode:setScale(NodeHelper:getScaleProportion())
        parentNode:addChild(spineNode)
    --end
    -- Particle測試
    --if itemId == 21 then
    --    local parNode = container:getVarNode("mParticleNode")
    --    local particleName = "PFX06_Snow.plist"
    --    local particle = CCParticleSystemQuad:create("UI/particle/" .. particleName)
    --    particle:setAutoRemoveOnFinish(true)
    --    parNode:addChild(particle)
    --end

    nowSpineName = spineName
end
-- 設定小人spine
function NgArchivePage:showChibiSpine(container, _skinId)
    local skinId = _skinId or COSTUME_DATA.NOW_SKIN
    if nowChibiSkin == skinId then
        return
    end
    nowChibiSkin = skinId
    local parentNode = container:getVarNode("mSpineLittle")
    parentNode:removeAllChildrenWithCleanup(true)
    local spineFolder, spineName = unpack(common:split(heroCfg.Spine, ","))
    local fullName = spineName .. string.format("%03d", skinId)
    --if not NodeHelper:isFileExist(spineFolder .. "/" .. fullName ..  ".json") and
    --   not NodeHelper:isFileExist(spineFolder .. "/" .. fullName ..  ".skel") then
    --    return
    --end
    local spine = SpineContainer:create(spineFolder, fullName)
    local spineNode = tolua.cast(spine, "CCNode")
    spine:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
    parentNode:addChild(spineNode)
    --
    local skinParentNode = container:getVarNode("mCostumeSpineNode")
    skinParentNode:removeAllChildrenWithCleanup(true)
    local skinSpine = SpineContainer:create(spineFolder, fullName)
    local skinSpineNode = tolua.cast(skinSpine, "CCNode")
    skinSpine:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
    skinParentNode:addChild(skinSpineNode)
   
end
-- 初始化皮膚資料
function NgArchivePage:initSkinData(container)
    local allSkinData = common:split(heroCfg.Skin, ",")
    COSTUME_DATA.ALL_SKIN = { }
    COSTUME_DATA.OWN_SKIN = { }
    COSTUME_DATA.NOW_SKIN = 0
    table.insert(COSTUME_DATA.ALL_SKIN, 0)
    for i = 1, #allSkinData do
        if tonumber(allSkinData[i]) ~= 0 then
            table.insert(COSTUME_DATA.ALL_SKIN, tonumber(allSkinData[i]))
        end
    end
    local curRoleInfo = UserMercenaryManager:getUserMercenaryByItemId(itemId)
    if curRoleInfo then
        COSTUME_DATA.OWN_SKIN[0] = true
        for i = 1, #curRoleInfo.ownSkin do
            COSTUME_DATA.OWN_SKIN[tonumber(curRoleInfo.ownSkin[i])] = true
        end
    else
        COSTUME_DATA.OWN_SKIN[0] = false
    end
end
-- 返回初始skin卡片
function NgArchivePage:returnToNowSkinItem(container)
    local changeId = 0
    for i = 1, #COSTUME_DATA.COSTUME_ITEMS do
        if COSTUME_DATA.COSTUME_ITEMS[i].skinId == COSTUME_DATA.NOW_SKIN then
            changeId = i
            break
        end
    end

   self:changeCostumeItem(container, COSTUME_DATA.NOW_COSTUME_ID, changeId, false)
end
------------------------------------------------------------------------------------------
-- Main Page Button
------------------------------------------------------------------------------------------
function NgArchivePage:onReturn(container)
    PageManager.refreshPage("EquipmentPage", "refreshScrollView")
    PageManager.refreshPage("EquipmentPage", "refreshRedPoint")
    PageManager.popPage(thisPageName)
end
function NgArchivePage:onPlus(container)
    local nowRoleId_Idx=1
    for k,v in pairs(SortedId) do
        if v == itemId then
            nowRoleId_Idx=k
        end
    end
	if SortedId[nowRoleId_Idx] and SortedId[nowRoleId_Idx+1] then
        itemId=SortedId[nowRoleId_Idx+1]
    else
        itemId=SortedId[1]
    end
    heroCfg = ConfigManager.getNewHeroCfg()[itemId]
    heroArchiveCfg = ConfigManager.getHeroEncyclopediaCfg()[itemId]
    nowSpineName = ""
    nowChibiSkin = -1
    self:initSkinData(selfContainer)
    self:initSkinItem(selfContainer)
    self:refreshMainButton(container)
    self:refreshPage(selfContainer)
end

function NgArchivePage:onMinus(container)
    local nowRoleId_Idx=1
    for k,v in pairs(SortedId) do
        if v == itemId then
            nowRoleId_Idx=k
        end
    end
	if SortedId[nowRoleId_Idx] and SortedId[nowRoleId_Idx-1] then
        itemId=SortedId[nowRoleId_Idx-1]
    else
        itemId=SortedId[#SortedId]
    end
    heroCfg = ConfigManager.getNewHeroCfg()[itemId]
    heroArchiveCfg = ConfigManager.getHeroEncyclopediaCfg()[itemId]
    nowSpineName = ""
    nowChibiSkin = -1
    self:initSkinData(selfContainer)
    self:initSkinItem(selfContainer)
    self:refreshMainButton(container)
    self:refreshPage(selfContainer)
end

function NgArchivePage:onInfoPage(container)
    if nowPageType == PAGE_TYPE.BASE_INFO then
        return
    end
    nowPageType = PAGE_TYPE.BASE_INFO
    self:refreshMainButton(container)
    self:returnToNowSkinItem(container)
    self:refreshPage(container)
    self:showRoleSpine(container)
end
function NgArchivePage:onSkinPage(container)
    if nowPageType == PAGE_TYPE.SKIN then
        return
    end
    nowPageType = PAGE_TYPE.SKIN
    self:refreshMainButton(container)
    self:returnToNowSkinItem(container)
    self:refreshPage(container)
    self:showRoleSpine(container)
end
function NgArchivePage:onCostumeShop(container)
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.SKIN_SHOP) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.SKIN_SHOP))
    else
        require("Reward.RewardPage"):setEntrySubPage("SkinShop")
        PageManager.pushPage("Reward.RewardPage")
    end
end
function NgArchivePage_setToSkin(isActive,id)
    SkinActive=isActive
    SkinId=id
end
function NgArchivePage:onStory(container)
    require("HeroBioPage")
    HeroBioPage_setPageRoleId(itemId)
    PageManager.pushPage("HeroBioPage")
end
function NgArchivePage:onChangInfo(container)
    if isMax then
        isMax=false
        NgArchivePage:refreshPage(container)
    else
        isMax=true
        NgArchivePage:refreshPage(container)
    end
end
--設定按鈕狀態
function NgArchivePage:refreshMainButton(container)
    NodeHelper:setMenuItemImage(container, { ["mBtn1"] = { normal = (1 == nowPageType) and BTN_IMG[1].press or BTN_IMG[1].normal, press = BTN_IMG[1].press } })
    NodeHelper:setMenuItemImage(container, { ["mBtn4"] = { normal = (4 == nowPageType) and BTN_IMG[4].press or BTN_IMG[4].normal, press = BTN_IMG[4].press } })
    NodeHelper:setNodesVisible(container, { ["mSelectEffect1"] = (1 == nowPageType) })
    NodeHelper:setNodesVisible(container, { ["mSelectEffect4"] = (4 == nowPageType) })
    NodeHelper:setNodesVisible(container,{["mChangeBtn"]=(1 == nowPageType)})
end
function NgArchivePage:onHide(container)
    NodeHelper:setNodesVisible(container,{mTopNode=false,mDetial=false,mBottomNode=false,mNextNode=false,mExitHide=true})
end

function NgArchivePage:onExitHide(container)
    NodeHelper:setNodesVisible(container,{mTopNode=true,mDetial=false,mBottomNode=true,mNextNode=true,mExitHide=false})
end
------------------------------------------------------------------------------------------
-- Info Page
------------------------------------------------------------------------------------------
function NgArchivePage:showSkill(container, eventName)
    local id = string.sub(eventName, -1)
    local skill = tonumber(common:split(heroCfg.Skills, ",")[tonumber(id)])
    require("HeroSkillPage")
    HeroSkillPage_setPageRoleInfo(heroArchiveCfg.MaxLevel, heroArchiveCfg.MaxStar)
    HeroSkillPage_setPageSkillLevel(3)
    HeroSkillPage_setPageSkillId(skill)
    PageManager.pushPage("HeroSkillPage")
end

function NgArchivePage:showFightAttrInfo(container)
    local lb2Str={}
    if isMax then
        lb2Str = {
            mStrTxt = heroArchiveCfg.MaxStr,
            mIntTxt = heroArchiveCfg.MaxInt,
            mDexTxt = heroArchiveCfg.MaxAgi,
            mHpTxt = heroArchiveCfg.MaxHp,
            mMercenaryName = UserInfo.roleInfo.name .. " ( " .. common:getLanguageString(string.format("@ProfessionName_" .. UserInfo.roleInfo.prof)) .. " )",
        }
    else
         lb2Str = {
            mStrTxt = heroArchiveCfg.MinStr,
            mIntTxt = heroArchiveCfg.MinInt,
            mDexTxt = heroArchiveCfg.MinAgi,
            mHpTxt = heroArchiveCfg.MinHp,
            mMercenaryName = UserInfo.roleInfo.name .. " ( " .. common:getLanguageString(string.format("@ProfessionName_" .. UserInfo.roleInfo.prof)) .. " )",
        }
    end
    NodeHelper:setStringForLabel(container, lb2Str)
end

function NgArchivePage:showSkillInfo(container)
    local skills = common:split(heroCfg.Skills, ",")
    for k, v in ipairs(skills)do  
        local skillBaseId = string.sub(v, 1, 4)
        NodeHelper:setSpriteImage(self.container, { ["Skill" .. k] = "skill/S_" .. skillBaseId .. ".png" })
    end
    for i = 1, 4 do
        NodeHelper:setStringForLabel(self.container, { ["mSkillLv" .. i] = 1 })
    end
end
------------------------------------------------------------------------------------------
-- Skin Page
------------------------------------------------------------------------------------------
local CostumeItem = {
    ccbiFile = "EquipmentPageRoleContent_CostumeItem.ccbi",
}
function CostumeItem.onFunction(eventname, container)
    if eventname == "onCostumeItem" then
        NgArchivePage:changeCostumeItem(selfContainer, COSTUME_DATA.NOW_COSTUME_ID, container.id, true)
    end
end
function NgArchivePage:initSkinItem(container)
    local itemParentNode = container:getVarNode("mCostumeItemsNode")
    COSTUME_DATA.COSTUME_ITEMS = { }
    COSTUME_DATA.IS_MOVEING = false
    COSTUME_DATA.NOW_COSTUME_ID = 3
    itemParentNode:removeAllChildren()
    local changeId = (SkinId ~= 0) and SkinId or 1
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
            --if COSTUME_DATA.NOW_SKIN == COSTUME_DATA.ALL_SKIN[i] then
            --    changeId = i
            --end
        end
    end
    self:changeCostumeItem(container, COSTUME_DATA.NOW_COSTUME_ID, changeId, false)
end
function NgArchivePage:refreshSkinUI(container)
    local skinId = COSTUME_DATA.ALL_SKIN[COSTUME_DATA.NOW_COSTUME_ID] or 0
    NodeHelper:setNodesVisible(container, { mCostumeAbilityNode = (skinId ~= 0),mDontHave=false })
    NodeHelper:setStringForLabel(container, { mCostumeDressTxt = common:getLanguageString("@SkinDress_" .. string.format("%02d", skinId)),
                                              mCostumeAllTxt = common:getLanguageString("@SkinAll_" .. string.format("%02d", skinId)) })
    for i = 1, #COSTUME_DATA.COSTUME_ITEMS do
        NodeHelper:setNodesVisible(COSTUME_DATA.COSTUME_ITEMS[i], { mCostumeUseImg = false--[[(COSTUME_DATA.NOW_SKIN == COSTUME_DATA.COSTUME_ITEMS[i].skinId)]],mMask=false,mMaskUse=false })
        --NodeHelper:setNodesVisible(COSTUME_DATA.COSTUME_ITEMS[i], { mMask = --[[(COSTUME_DATA.NOW_COSTUME_ID ~= i)]] })
        --NodeHelper:setNodesVisible(COSTUME_DATA.COSTUME_ITEMS[i], { mMaskUse = (COSTUME_DATA.NOW_COSTUME_ID ~= i) and (COSTUME_DATA.NOW_SKIN == COSTUME_DATA.COSTUME_ITEMS[i].skinId) })
    end
end
function NgArchivePage:changeCostumeItem(container, nowId, toId, showAni)
    local move = nowId - toId
    if move == 0 or COSTUME_DATA.IS_MOVEING then
        return
    end
    COSTUME_DATA.IS_MOVEING = true
    COSTUME_DATA.NOW_COSTUME_ID = toId
    local aniTime = showAni and COSTUME_DATA.MOVE_TIME or 0
    for idx = 1, #COSTUME_DATA.COSTUME_ITEMS do
        COSTUME_DATA.COSTUME_ITEMS[idx]:stopAllActions()
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
                self:onCostumeSkin()
		    end))
        end
        COSTUME_DATA.COSTUME_ITEMS[idx]:runAction(CCSequence:create(seqAction))
    end
    self:refreshSkinUI(container)
    local spineName = "NG2D_" .. string.format("%02d", itemId)
    self:showRoleSpine(container, spineName, COSTUME_DATA.COSTUME_ITEMS[COSTUME_DATA.NOW_COSTUME_ID].skinId)
end
------------------------------------------------------------------------------------------
function NgArchivePage:onExit(container)
    local heroNode = self.container:getVarNode("mSpine")
    if heroNode then
        heroNode:removeAllChildren()
    end
    self.container = nil
    SkinId = nil
    container:removeMessage(MSG_REFRESH_REDPOINT)
end

function NgArchivePage:setMercenaryId(id)
    itemId = id
end

function NgArchivePage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        NgArchivePage:refreshAllPoint(container)
    end
end

function NgArchivePage:refreshAllPoint(container)
    NodeHelper:setNodesVisible(container, { mBtnPoint1 = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_INFO_BTN2, itemId) })
    NodeHelper:setNodesVisible(container, { mBioRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.CHAR_INFO_BTN2, itemId) })
end

local CommonPage = require('CommonPage')
NgArchivePage = CommonPage.newSub(NgArchivePage, thisPageName, option)
return NgArchivePage