----------------------------------------------------------------------------------
-- 副将页面
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "EquipMercenaryPage"
local Activity_pb = require("Activity_pb")
local EquipScriptData = require("EquipScriptData")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local PBHelper = require("PBHelper")
local RoleOpr_pb = require "RoleOpr_pb"
local UserMercenaryManager = require("UserMercenaryManager")
local SkillManager = require("Skill.SkillManager")
local ItemManager = require("Item.ItemManager")
local FormationManager = require("FormationManager")
local MercenaryTouchSoundManager = require("MercenaryTouchSoundManager")
local FetterManager = require("FetterManager")
local MainScenePageInfo = require("MainScenePage")
local RelationshipManager = require("RelationshipManager")
local EquipOprHelper = require("Equip.EquipOprHelper")
local CONST = require("Battle.NewBattleConst")
local UserItemManager = require("Item.UserItemManager")
local MercenaryUpgradeStarPage = require("MercenaryUpgradeStarPage")
local EquipMercenaryPage = {
    ccbiFile = "EquipmentPageRoleContent_new.ccbi"
}
local opcodes = {
    ROLE_INFO_SYNC_S = HP_pb.ROLE_INFO_SYNC_S,
    ROLE_CARRY_SKILL_S = HP_pb.ROLE_CARRY_SKILL_S,
    ROLE_FIGHT_S = HP_pb.ROLE_FIGHT_S,
    EQUIP_DRESS_S = HP_pb.EQUIP_DRESS_S,
    EQUIP_ENHANCE_S = HP_pb.EQUIP_ENHANCE_S,
}

local EquipPartNames = {
    ["Chest"] = Const_pb.CUIRASS,
    ["Feet"] = Const_pb.SHOES,
    ["MainHand"] = Const_pb.WEAPON1,
    --["Wrist"] = Const_pb.GLOVE,
    ["Finger"] = Const_pb.RING,
    --["Helmet"] = Const_pb.HELMET,
}
-- 基礎資訊, 裝備, 升星, 皮膚
local PAGE_TYPE = { BASE_INFO = 1, EQUIPMENT = 2, UPGRADE = 3, SKIN = 4 }
local nowPageType = PAGE_TYPE.BASE_INFO
local eventMap = { }
for equipName, _ in pairs(EquipPartNames) do
    eventMap["on" .. equipName] = "showEquipDetail"
end
for i = 1, 7 do
    eventMap["onSkill" .. i] = "showSkill"
end
eventMap["onWeapon"] = "onWeapon"
eventMap["onAtt"] = "onAtt"
eventMap["onUseSpin"] = "onUseSpin"
eventMap["onPrivate"] = "onBadgeBtn"
eventMap["onUsingSpin"] = "onUsingSpin"
eventMap["onAllEquip"] = "onAllEquip"
eventMap["onAllDisEquip"] = "onAllDisEquip"

local _selfContainer = nil
local _curMercenaryId = 0
local _curMercenaryInfo = nil   --getMercenaryStatusByItemId
local _curMercenaryInfo2 = nil  --getUserMercenaryById
local oldInfo = nil

function EquipMercenaryPage:getSpineAttachNode()
    return self.mSpineAttachNode
end

function EquipMercenaryPage.onFunction(eventName, container)
    if eventMap[eventName] then
        EquipMercenaryPage[eventMap[eventName]](EquipMercenaryPage, container, eventName)
    elseif eventName == "onExpedition" then
        EquipMercenaryPage:onExpedition(container)
    elseif eventName == "onTrain" then
        EquipMercenaryPage:onTrain(container)
    elseif eventName == "onRisingStar" then
        --        if UserInfo.roleInfo and UserInfo.rol
        EquipMercenaryPage:onRisingStar(container)
    elseif eventName == "onDetail" then
        local PlayerAttributePage = require("PlayerAttributePage")

        local roleInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryInfo.roleId--[[_curMercenaryId]])
        -- _curMercenaryInfo
        PlayerAttributePage:setRoleInfo(roleInfo)
        PageManager.pushPage("PlayerAttributePage")
    elseif eventName == "onUpRole" then
        EquipMercenaryPage:changeRoleSpine(-1)
    elseif eventName == "onDownRole" then
        EquipMercenaryPage:changeRoleSpine(1)
    end
end

function EquipMercenaryPage:showFightAttrInfo_1(data)
    -- EquipMercenaryPage:showFightAttrInfo(_selfContainer)

    local roleInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryId)
    if roleInfo then
        NodeHelper:setStringForLabel(_selfContainer, { mFightPowerNum = common:getLanguageString("@EquipmentFightTxt", roleInfo.fight) })
    end
end

function EquipMercenaryPage:onEnter(ParentContainer)
    if not self.container or tolua.isnull(self.container) then
        self.container = ScriptContentBase:create(EquipMercenaryPage.ccbiFile)	
    end
    nowPageType = PAGE_TYPE.BASE_INFO

    self.container:registerFunctionHandler(EquipMercenaryPage.onFunction)
    self:registerPacket(ParentContainer)
    _selfContainer = self.container
    _curMercenaryInfo = UserMercenaryManager:getMercenaryStatusByItemId(_curMercenaryId)
    local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
    _curMercenaryInfo2 = UserMercenaryManager:getUserMercenaryById(_curMercenaryInfo.roleId)

    self:refreshPage(_selfContainer)
    self:showRoleSpine(_selfContainer)

    local HelpFightDataManager = require("PVP.HelpFightDataManager")
    if HelpFightDataManager:isOpen() and GameConfig.isOpenBadge then
        self:checkFate(_selfContainer)
    end

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["EquipMercenaryPage"] = self.container
    
    NodeHelper:setNodesVisible(self.container, { mPrivateBtnNode = (GameConfig.isOpenBadge and HelpFightDataManager:isOpen()), mTestLeader = false })

    return self.container
end

-- 显示猎命界面
function EquipMercenaryPage:onBadgeBtn(container)
    PageManager.refreshPage("EquipmentPage", "ShowFatePage")
end

function EquipMercenaryPage:setShowFateSubPage(showFateSubPage, isFirst)
    _showFateSubPage = showFateSubPage
    NodeHelper:setNodesVisible(_selfContainer, { mMervenaryEquipNode = not _showFateSubPage })
    NodeHelper:setNodesVisible(_selfContainer, { mMervenaryPrivateNode = _showFateSubPage })

    if _showFateSubPage and not _fateWearsPage then
        _fateWearsPage = require("FateWearsPage")
        local roleInfoData = UserMercenaryManager:getUserMercenaryById(_curMercenaryId)
        local dresses = roleInfoData and roleInfoData.dress or { }
        _fateWearsPage:setFateInfo( { mercenaryId = _curMercenaryId, isOthers = false, fateIdList = dresses })
        local subContainer = _fateWearsPage:onEnter(_selfContainer)
        _fateWearsPage.container = subContainer
        _fateWearsPage:registerPacket(_parentContainer)
        _selfContainer:getVarNode("mMervenaryPrivateNode"):addChild(subContainer)
        subContainer:release()
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["FateWearsPage"] = subContainer
    elseif not _showFateSubPage and _fateWearsPage then
        _fateWearsPage:removePacket(_parentContainer)
        _fateWearsPage:onExit(_selfContainer)
        _fateWearsPage.container:removeFromParentAndCleanup(true)
        _fateWearsPage = nil
    end
    if not isFirst then
    end
end

function EquipMercenaryPage_getIllustratedId(roleId)
    local illustratedId = -1
    if not illCfg then
        illCfg = ConfigManager.getIllustrationCfg()
    end

    if not illCfg then
        return illustratedId
    end

    for i, v in ipairs(illCfg) do
        if v.roleId == roleId then
            illustratedId = v.id
            return illustratedId
        end
    end
    return illustratedId
end

function EquipMercenaryPage_onTrain()
    EquipMercenaryPage:onTrain()
end

function EquipMercenaryPage:onTrain(container)
    if UserInfo.roleInfo and UserInfo.roleInfo.level < GameConfig.MERCENARY_UPGRADESTAR_LIMIT then
        MessageBoxPage:Msg_Box(common:getLanguageString("@MercenaryUpGradeStarLimit", GameConfig.MERCENARY_UPGRADESTAR_LIMIT))
        return
    end
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    local isSelling = info.activiteState == Const_pb.NOT_ACTIVITE
    if isSelling then
        MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_28"))
        return
    end
    --_curMercenaryInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryId)
    --if _curMercenaryInfo.isStage then
    --    -- 可进阶
    --    local MercenaryUpgradeStagePage = require("MercenaryUpgradeStagePage")
    --    MercenaryUpgradeStagePage:setMercenaryId(_curMercenaryInfo.roleId)
    --    PageManager.pushPage("MercenaryUpgradeStagePage")
    --else
        -- 不可进阶
        MercenaryUpgradeStarPage:setMercenaryId(_curMercenaryInfo.itemId)
        PageManager.pushPage("MercenaryUpgradeStarPage")
    --end
end

function EquipMercenaryPage_onRisingStar()
    EquipMercenaryPage:onRisingStar()
end

function EquipMercenaryPage:onRisingStar(container)
    if UserInfo.roleInfo and UserInfo.roleInfo.level < GameConfig.MERCENARY_UPGRADESTAR_LIMIT then
        MessageBoxPage:Msg_Box(common:getLanguageString("@MercenaryUpGradeStarLimit", GameConfig.MERCENARY_UPGRADESTAR_LIMIT))
        return
    end
     _curMercenaryInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryId)
    if _curMercenaryInfo.isStage then
        -- 可进阶
        local MercenaryUpgradeStagePage = require("MercenaryUpgradeStagePage")
        MercenaryUpgradeStagePage:setMercenaryId(_curMercenaryInfo.roleId)
        PageManager.pushPage("MercenaryUpgradeStagePage")
    else
        -- 不可进阶
        local MercenaryUpgradeStarPage = require("MercenaryUpgradeStarPage")
        MercenaryUpgradeStarPage:setMercenaryId(_curMercenaryInfo.roleId)
        PageManager.pushPage("MercenaryUpgradeStarPage")
    end
end

function EquipMercenaryPage:checkFashion(container)
    NodeHelper:setNodesVisible(container, { mFashionPoint = false })
    local roleCfg = ConfigManager.getRoleCfg()
    local itemCfg = roleCfg[_curMercenaryInfo.itemId]

    if itemCfg.modelId ~= 0 or itemCfg.FashionInfos then

        local FashionInfos = { }
        if itemCfg.modelId ~= 0 then
            if roleCfg[itemCfg.modelId] then
                FashionInfos = roleCfg[itemCfg.modelId].FashionInfos
            end
        else
            FashionInfos = itemCfg.FashionInfos
        end
        if FashionInfos then
            local statusInfo
            for i, v in ipairs(FashionInfos) do
                statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(v)
                if statusInfo and v ~= _curMercenaryInfo.itemId then
                    if statusInfo.roleStage ~= 0 then
                        local visible =(statusInfo.roleStage == 2) and(itemCfg.type ~= 1)
                        NodeHelper:setNodesVisible(container, { mFashionPoint = visible })
                        break
                    end
                end
            end
        end

    end
    if GameConfig.isIOSAuditVersion then
        NodeHelper:setNodesVisible(self.container, { mFashionNode = false })
    else
        NodeHelper:setNodesVisible(container, { mFashionNode = itemCfg.modelId ~= 0 or itemCfg.FashionInfos ~= nil })
    end
end


function EquipMercenaryPage:checkFate(container)
    local FateDataManager = require("FateDataManager")
    local isShown = FateDataManager:checkShowFateRedPoint(_curMercenaryId)
    -- 如果猎命系统开启，则显示猎命入口
    _showFate = FateDataManager:getFateWearNum(UserInfo.roleInfo.level) > 0
    local visibleMap = {
        mPrivateNode = _showFate,
        mMervenaryEquipNode = not _showFateSubPage,
        mMervenaryPrivateNode = _showFateSubPage,
        mPrivatePoint = isShown
    }
    NodeHelper:setNodesVisible(container, visibleMap)
    EquipMercenaryPage:setShowFateSubPage(_showFateSubPage, true)
end

function EquipMercenaryPage:onWeapon(container)
    local MercenarySpecialEquipPage = require("MercenarySpecialEquipPage")
    PageManager.pushPage("MercenarySpecialEquipPage")
end

function EquipMercenaryPage:onAtt(container)
    local MercenarySpecialGroupPage = require("Mercenary.MercenarySpecialGroupPage")
    PageManager.pushPage("MercenarySpecialGroupPage")
end

function EquipMercenaryPage:onAllEquip(container, eventName)
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    local isSelling = info.activiteState == Const_pb.NOT_ACTIVITE
    if isSelling then
        MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_28"))
        return
    end
    local allEquipId = UserEquipManager:getEquipAll()   --取得全部未使用的裝備
    local userEquips = { }
    local bestEquips = { }
    for i = 1, 10 do
        --if i ~= 3 and i < 8 then
            userEquips[i] = UserMercenaryManager:getEquipByPart(_curMercenaryInfo.roleId, i)
        --end
    end
    for k, v in pairs(allEquipId) do
        if v then
            if not UserEquipManager:isEquipDressed(v) then  --檢查是否正在裝備
                local equip1 = UserEquipManager:getUserEquipById(v)
                local score = equip1.score
                local part = EquipManager:getPartById(equip1.equipId)
                if part ~= "" then
                    -- TODO 修改判斷
                    --if EquipManager:isDressable(equip1.equipId, roleTable.class) then -- 可裝備
                        if userEquips[part] == nil or UserEquipManager:getUserEquipById(userEquips[part].equipId).score < equip1.score then --包包裡有更強的裝備
                            if bestEquips[part] == nil or UserEquipManager:getUserEquipById(bestEquips[part].id).score < equip1.score then
                                bestEquips[part] = equip1   --紀錄可更換的裝備
                            end
                        end
                    --end
                end
            end
        end
    end  
    local size = 0
    for _ in pairs(bestEquips) do 
        size = size + 1 
    end
    if size <= 0 then    --沒有更好的裝備
        MessageBoxPage:Msg_Box_Lan("@NoBetterEquip")
        return
    end

    for i = 1, 10 do
        --if i ~= 3 and i < 8 then
            if bestEquips[i] ~= nil then
                local dressType
                if userEquips[i] then
                    dressType = GameConfig.DressEquipType.Change
                    if UserEquipManager:isCanExtend(UserEquipManager:getUserEquipById(userEquips[i].equipId), bestEquips[i]) then    --可繼承
                        EquipOprHelper:extendEquip(userEquips[i].equipId, bestEquips[i].id)
                    end
                else
                    dressType = GameConfig.DressEquipType.On
                end
                EquipOprHelper:dressEquip(bestEquips[i].id, _curMercenaryInfo.roleId, dressType)
            end
        --end
    end
end

function EquipMercenaryPage:onAllDisEquip(container, eventName)
    for i = 1, 10 do
        local roleEquip = UserMercenaryManager:getEquipByPart(_curMercenaryInfo.roleId, i)
        local dressType = GameConfig.DressEquipType.Off
        if roleEquip then
            EquipOprHelper:dressEquip(roleEquip.equipId, _curMercenaryInfo.roleId, dressType)
        end
    end
end

function EquipMercenaryPage:refreshPage(container)
    _curMercenaryInfo = UserMercenaryManager:getMercenaryStatusByItemId(_curMercenaryId)
    
    if _fateWearsPage then
        local dresses = _curMercenaryInfo and _curMercenaryInfo.dress or { }
        _fateWearsPage:refreshFateIdList(dresses)
        EquipMercenaryPage:checkFate(_selfContainer)
    end

    self:showFightAttrInfo(container)
    self:showEquipInfo(container)
    self:showSkillInfo(container)

    local fetterId = FetterManager.getViewFetterId()
    local data = FetterManager.getIllCfgById(fetterId)
    local suitInfo = EquipManager:getMercenaryOnlySuitByMercenaryId(data.roleId)
    if suitInfo == nil then
        NodeHelper:setNodesVisible(self.container, { mWeaponBtnNode = false })
    else
        NodeHelper:setNodesVisible(self.container, { mWeaponBtnNode = true })
    end
    
    local list = FetterManager.getAllRelationByFetterId(fetterId)
    if #list > 0 then
        NodeHelper:setNodesVisible(self.container, { mFetterBtnNode = true })
    else
        NodeHelper:setNodesVisible(self.container, { mFetterBtnNode = false })
    end

     NodeHelper:setNodesVisible(self.container, { mWeaponBtnNode = false })
     NodeHelper:setNodesVisible(self.container, { mFetterBtnNode = false })

    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    local mLvTxt = 100--roleTable.star * 20 - 10 + 2 * info.starLevel -- 等級上限為: 星數 * 20 - 10 + 2 * 突破階級
    local lb2Str = {
        mStrTxt = _curMercenaryInfo and GameUtil:formatDotNumber(PBHelper:getAttrById(oldInfo.attribute.attribute, Const_pb.STRENGHT)) or 0,
        mIntTxt = _curMercenaryInfo and GameUtil:formatDotNumber(PBHelper:getAttrById(oldInfo.attribute.attribute, Const_pb.INTELLECT)) or 0,
        mDexTxt = _curMercenaryInfo and GameUtil:formatDotNumber(PBHelper:getAttrById(oldInfo.attribute.attribute, Const_pb.AGILITY)) or 0,
        mHpTxt = _curMercenaryInfo and GameUtil:formatDotNumber(PBHelper:getAttrById(oldInfo.attribute.attribute, Const_pb.HP)) or 0,
        --mLvTxtHero = math.min(10, info.level) .. "/" .. 10,
        mLvTxtHero = math.min(mLvTxt, info.level) .. "/" .. mLvTxt,
        mLvUpTxt = common:getLanguageString("@A_LevelUp_Levelup"),
    }
    NodeHelper:setNodesVisible(container, { mStageNode = true })
    for i = 1, 5 do
        NodeHelper:setNodesVisible(self.container, { ["mStageImg" .. i] = (info.starLevel >= i) })
    end
    NodeHelper:setStringForLabel(self.container, lb2Str)

    -- 刷新升級紅點顯示
    if (mLvTxt > info.level) and 
       (UserItemManager:getCountByItemId(104002) > 0 or UserItemManager:getCountByItemId(104003) > 0 or UserItemManager:getCountByItemId(104004) > 0) then
        NodeHelper:setNodesVisible(self.container, { mTrainRedPoint = true })
    else
        NodeHelper:setNodesVisible(self.container, { mTrainRedPoint = false })
    end
end

local roleConfig = {
    [1] = { min = 1, max = 6 },
    [2] = { min = 101, max = 175 }
}
local currentRoleId = 1
function EquipMercenaryPage:getRoleId(value)
    local roleID = currentRoleId + value
    if roleID < roleConfig[1].min then
        roleID = roleConfig[2].max
    elseif roleID > roleConfig[1].max and roleID < roleConfig[2].min then
        if value == 1 then
            roleID = roleConfig[2].min
        else
            roleID = roleConfig[1].max
        end
    elseif roleID > roleConfig[2].max then
        roleID = roleConfig[1].min
    end

    currentRoleId = roleID
    return currentRoleId
end

function EquipMercenaryPage:changeRoleSpine(value)
    local roleId = self:getRoleId(value)
    EquipMercenaryPage:showRoleSpine(_selfContainer, roleId)
end

function EquipMercenaryPage:showRoleSpine(container, newRoleId)
    local roleId = _curMercenaryInfo.itemId
    if newRoleId then
        roleId = newRoleId
    end
    local prof = _curMercenaryInfo.prof
    local heroNode = container:getVarNode("mSpine")
    if not heroNode then
        return
    end

    heroNode:removeAllChildren()
    local spine = nil
    local heroCfg = ConfigManager.getNewHeroCfg()[tonumber(210)]
    local spinePath, spineName = unpack(common:split(heroCfg.Spine, ","))
    spine = SpineContainer:create(spinePath, spineName)

    local spineNode = tolua.cast(spine, "CCNode")
    spineNode:setPositionY(spineNode:getPositionY())
    heroNode:addChild(spineNode)
    
    local UserMercenaryManager = require("UserMercenaryManager")

    spine:setToSetupPose()
    spine:runAnimation(1, CONST.ANI_ACT.WAIT, -1)

    NodeHelper:setSpriteImage(container, { mClassIcon = GameConfig.MercenaryClassImg[10],
                                           mElementIcon = GameConfig.MercenaryElementImg[1],
                                           mBg = GameConfig.MercenaryElementBg[1], })
    NodeHelper:setNodesVisible(container, { mLeaderSkillNode = false, mHeroSkillNode = true, midNode = true, HeroLv = true, 
                                            LeaderLv = false, mElementIcon = true, mLeaderName = false, mClassIcon = true, 
                                            mLeaderIcon = false, mLeaderElement = false })
    --for i = 1, 6 do
    --    NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (roleTable.star == i) })
    --end

    self.mSpineAttachNode = tolua.cast(heroNode, "CCNode")
end

function EquipMercenaryPage:showSkillInfo(container)
    local heroCfg = ConfigManager.getNewHeroCfg()
    local heroInfo = heroCfg[210]
    local skillList = common:split((heroInfo.Skills), ",")
    -- message RoleSkill
    local ringList = common:split((heroInfo.Passive), ",")
    --

    local SkillPic = ""
    local iconId = 1
    -- 主動
    for i = 1, #skillList do
        SkillPic = "skill/S_" .. skillList[i] .. ".png"
        local normalImg = {
            ["mSkillBtn" .. iconId] = { ["normal"] = SkillPic }
        }
        NodeHelper:setMenuItemImage(container, normalImg)
        iconId = iconId + 1
    end
    -- 被動
    SkillPic = ""
    for i = 1, #ringList do
        SkillPic = "skill/S_" .. ringList[i] .. ".png"
        local normalImg = {
            ["mSkillBtn" .. iconId] = { ["normal"] = SkillPic }
        }
        NodeHelper:setMenuItemImage(container, normalImg)
        iconId = iconId + 1
    end

    for i = 1, 7 do
        if i < iconId then
            NodeHelper:setNodesVisible(container, { ["mSkill" .. i] = true })
        else
            NodeHelper:setNodesVisible(container, { ["mSkill" .. i] = false })
        end
    end
end


function EquipMercenaryPage:showSkill(container, eventName)
    local MercenarySkillPreviewPage = require("MercenarySkillPreviewPage")
    MercenarySkillPreviewPage:setMercenaryInfo(_curMercenaryInfo)
    PageManager.pushPage("MercenarySkillPreviewPage")
end

function EquipMercenaryPage_showEquipDetail(part)
    local info = UserMercenaryManager:getUserMercenaryByItemId(101)
    EquipSelectPage_setPart(part, info.roleId)
end

function EquipMercenaryPage:showEquipDetail(container, eventName)
    local UserInfo = require("PlayerInfo.UserInfo")
    local partName = string.sub(eventName, 3)
    _curMercenaryInfo = UserMercenaryManager:getMercenaryStatusByItemId(_curMercenaryId)

    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    local isSelling = info.activiteState == Const_pb.NOT_ACTIVITE
    if isSelling then
        MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_28"))
        return
    end

    local childNode = container:getVarMenuItemCCB("m" .. partName)
    childNode = childNode:getCCBFile()
    local part = EquipPartNames[partName]
    local isShowNotice = UserEquipManager:isPartNeedNotice(part, _curMercenaryInfo.roleId)
    -- if isShowNotice then
    -- UserEquipManager:cancelNotice(part,_curMercenaryInfo.roleId)
    -- end
    NodeHelper:setNodesVisible(childNode, { mHelmetPoint = false })
    local roleEquip = UserMercenaryManager:getEquipByPart(_curMercenaryInfo.roleId, part)
    if roleEquip then
        PageManager.showEquipInfo(roleEquip.equipId, _curMercenaryInfo.roleId, isShowNotice)
    else
        EquipSelectPage_setPart(part, _curMercenaryInfo.roleId)
        PageManager.pushPage("EquipSelectPage")
    end
end	

function EquipMercenaryPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function EquipMercenaryPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function EquipMercenaryPage:showFightAttrInfo(container)
    --local curMercenaryCfg = ConfigManager.getRoleCfg()[_curMercenaryInfo.itemId]
    oldInfo = UserMercenaryManager:getUserMercenaryById(_curMercenaryInfo.roleId)
    local formationInfo = FormationManager:getMainFormationInfo()
    local visibleMap = { }
    local statusImage = GameConfig.MercenaryBattleState.status_free
    local status = _curMercenaryInfo.status
    local count = 0

    local curIdx = 0
    local len = #formationInfo.roleNumberList
    for i, v in ipairs(formationInfo.roleNumberList) do
        if v > 0 then
            count = count + 1
            if formationInfo.roleNumberList[i] == _curMercenaryInfo.itemId then
                curIdx = i
            end
        end
    end

    if status == Const_pb.FIGHTING then
        if curIdx == 0 then
            count = count + 1
            if count > GameConfig.MercenaryFightintMaxCount then
                curIdx = #formationInfo.roleNumberList + 1
            end
        end
    else
        if curIdx ~= 0 then
            curIdx = 0
            count = count - 1
        end
    end

    visibleMap["mPlayedNode"] = false
    visibleMap["mCanFightNode"] = false
    visibleMap["mStateNode"] = true
    visibleMap["mMercenaryNumNode"] = false
    if status == Const_pb.FIGHTING then
        statusImage = GameConfig.MercenaryBattleState.status_fight

        if curIdx < GameConfig.MercenaryFightintMaxCount + 1 then
            statusImage = GameConfig.MercenaryBattleState.status_fight
        else
            statusImage = GameConfig.MercenaryBattleState.status_replace
        end
        visibleMap["mMercenaryNumNode"] = true
    elseif status == Const_pb.RESTTING then
        statusImage = GameConfig.MercenaryBattleState.status_free
        if count < GameConfig.MercenaryFightintMaxCount and count < formationInfo.posCount then
            statusImage = GameConfig.MercenaryBattleState.status_canFight
            visibleMap["mPlayedNode"] = true
            visibleMap["mMercenaryNumNode"] = true
            visibleMap["mCanFightNode"] = true
            visibleMap["mStateNode"] = false
        elseif count >= GameConfig.MercenaryFightintMaxCount and count < formationInfo.posCount then
            statusImage = GameConfig.MercenaryBattleState.status_canReplace
            -- statusImage = GameConfig.MercenaryBattleState.status_substitutes
            visibleMap["mMercenaryNumNode"] = false
        elseif count >= formationInfo.posCount then
            statusImage = GameConfig.MercenaryBattleState.status_substitutes
            visibleMap["mMercenaryNumNode"] = false
        end
    elseif status == Const_pb.EXPEDITION then
        statusImage = GameConfig.MercenaryBattleState.status_expedition
        visibleMap["mMercenaryNumNode"] = false
    end

    ------------------------------------------------------------------------
    local mn = ""
    if formationInfo.posCount <= 5 and formationInfo.posCount > 0 then
        mn = count .. " / " .. formationInfo.posCount
        NodeHelper:setNodeVisible(mercenaryNumNode, true)
    elseif formationInfo.posCount > 5 and formationInfo.posCount <= 11 then
        if count < 5 then
            mn = count .. " / 5"
            NodeHelper:setNodeVisible(mercenaryNumNode, true)
        else
            if curIdx > 0 and curIdx <= 5 then
                mn = "5 / 5"
                NodeHelper:setNodeVisible(mercenaryNumNode, true)
            else
                mn = (count - 5) .. " / " .. (formationInfo.posCount - 5)
                NodeHelper:setNodeVisible(mercenaryNumNode, true)
                if curIdx == 0 and formationInfo.posCount == count then
                    NodeHelper:setNodeVisible(mercenaryNumNode, false)
                end
            end
        end
    end
    if status == Const_pb.EXPEDITION then
        statusImage = GameConfig.MercenaryBattleState.status_expedition
        NodeHelper:setNodeVisible(mercenaryNumNode, false)
    end
    ------------------------------------------------------------------------

    local cout = 1
    local lb2Str = {
        mAttribute1 = common:getLanguageString("@EquipmentHPTxt", PBHelper:getAttrById(oldInfo.attribute.attribute, Const_pb.HP)),
        mAttribute2 = common:getLanguageString("@EquipmentFightTxt", oldInfo.fight),
        mFightPowerNum = common:getLanguageString("@EquipmentFightTxt", oldInfo.fight),
        mAttribute3 = common:getLanguageString("@EquipmentAttTxt", PBHelper:getAttrById(oldInfo.attribute.attribute, Const_pb.MINDMG) .. "-" .. PBHelper:getAttrById(oldInfo.attribute.attribute, Const_pb.MAXDMG)),
        mMercenaryNum = mn
    }
    --visibleMap["mCareer1"] = curMercenaryCfg.profession == 1
    --visibleMap["mCareer2"] = curMercenaryCfg.profession == 2
    --visibleMap["mCareer3"] = curMercenaryCfg.profession == 3
    NodeHelper:setNodesVisible(container, visibleMap)
    -- NodeHelper:setSpriteImage(container,{ mCareer = curMercenaryCfg.smallIcon })
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setNormalImage(container, "mState", statusImage)
end

function EquipMercenaryPage:showEquipInfo(container)
    local lb2Str = { }
    local sprite2Img = { }
    local scaleMap = { }
    local nodesVisible = { }
    local colorMap = { }
    for equipName, part in pairs(EquipPartNames) do
        local levelStr = ""
        local enhanceLvStr = ""
        local icon = GameConfig.Image.ClickToSelect
        local quality = GameConfig.Default.Quality
        local aniVisible = false
        local gemVisible = false

        local showNotice = UserEquipManager:isPartNeedNotice(part, _curMercenaryInfo.roleId)
        local childNode = container:getVarMenuItemCCB("m" .. equipName)
        childNode = childNode:getCCBFile()
        local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
        _curMercenaryInfo2 = UserMercenaryManager:getUserMercenaryById(_curMercenaryInfo.roleId)
        local roleEquip = PBHelper:getRoleEquipByPart(_curMercenaryInfo2.equips, part)
        setEquipStar(childNode, 0)
        if roleEquip then
            local equipId = roleEquip.equipItemId
            -- 只顯示強化等級
            --levelStr = common:getR2LVL() .. EquipManager:getLevelById(equipId)
            --enhanceLvStr = roleEquip.strength ~= 0 and "+" .. roleEquip.strength or ""
            levelStr = common:getR2LVL() .. (roleEquip.strength ~= 0 and roleEquip.strength + 1 or "1")
            icon = EquipManager:getIconById(equipId)
            quality = EquipManager:getQualityById(equipId)
            aniVisible = UserEquipManager:isGodly(roleEquip.equipId)
            setEquipStar(childNode, quality)
            local userEquip = UserEquipManager:getUserEquipById(roleEquip.equipId)
            if next(userEquip) ~= nil then
                local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos)
                if table.maxn(gemInfo) > 0 then
                    gemVisible = true
                    for i = 1, 4 do
                        local gemId = gemInfo[i]
                        nodesVisible["mHelmetGemBG" .. i] = gemId ~= nil
                        local gemSprite = "mHelmetGem0" .. i
                        nodesVisible[gemSprite] = false
                        if gemId ~= nil and gemId > 0 then
                            local icon = ItemManager:getGemSmallIcon(gemId)
                            if icon then
                                nodesVisible[gemSprite] = true
                                sprite2Img[gemSprite] = icon
                                scaleMap[gemSprite] = 1
                            end
                        end
                    end
                end
            end
            sprite2Img["mHelmetPic"] = icon
        else
            local showPic = GameConfig.defaultEquipImage["Helmet"]

            if equipName == "MainHand" or equipName == "OffHand" then
                local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
                if tonumber(roleTable.class) > 90 then
                    showPic = GameConfig.defaultEquipImage[equipName .. "_" .. roleTable.class]
                else
                    showPic = GameConfig.defaultEquipImage[equipName .. "_" .. math.floor(roleTable.class / 10)]
                end
            else
                showPic = GameConfig.defaultEquipImage[equipName]
            end
            sprite2Img["mHelmetPic"] = showPic
        end

        lb2Str["mHelmetLv"] = levelStr
        lb2Str["mHelmetLvNum"] = enhanceLvStr

        sprite2Img["mPic"] = NodeHelper:getImageByQuality(quality)
        sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(quality)
        sprite2Img["mFrame"] = GameConfig.MercenaryQualityImage[quality]
        nodesVisible["mHelmetAni"] = aniVisible
        nodesVisible["mHelmetGemNode"] = gemVisible
        nodesVisible["mHelmetPoint"] = showNotice
        nodesVisible["mFrameShade"] = roleEquip ~= nil
        nodesVisible["mFrame"] = roleEquip ~= nil

        NodeHelper:addEquipAni(childNode, "mHelmetAni", aniVisible, roleEquip and roleEquip.equipId)
        NodeHelper:setStringForLabel(childNode, lb2Str)
        NodeHelper:setSpriteImage(childNode, sprite2Img, scaleMap)
        NodeHelper:setNodesVisible(childNode, nodesVisible)
        NodeHelper:setColorForLabel(childNode, colorMap)
    end
end

function setEquipStar(container, quality)
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == quality) })
    end
end

function EquipMercenaryPage:onShowRedPoint(container)
    for equipName, part in pairs(EquipPartNames) do
        local childNode = container:getVarMenuItemCCB("m" .. equipName)
        childNode = childNode:getCCBFile()
        local showNotice = UserEquipManager:isPartNeedNotice(part, _curMercenaryInfo.roleId)
        local nodesVisible = { }
        nodesVisible["mHelmetPoint"] = showNotice
        NodeHelper:setNodesVisible(childNode, nodesVisible)
    end
end

function EquipMercenaryPage:onReceiveMessage(ParentContainer)
    local message = ParentContainer:getMessage()
    local typeId = message:getTypeId()
    if _fateWearsPage then
        _fateWearsPage:onReceiveMessage(message, typeId)
    end
    if typeId == MSG_SEVERINFO_UPDATE then
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode
        if opcode == HP_pb.ROLE_INFO_SYNC_S then
            if UserEquipManager:hasInited() then
                if UserEquipManager:getEquipNoticeCounts() > 0 then
                    -- 显示MainFrameBottom中佣兵红点
                    PageManager.showRedNotice("Mercenary", true)
                else
                    -- 取消MainFrameBottom中佣兵红点
                    PageManager.showRedNotice("Mercenary", false)
                end
            end
        end
    elseif typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "MercenaryPage_RefreshSkill" then
            self:showSkillInfo(container)
        elseif pageName == thisPageName and extraParam == "Equip_RedPoint" then
            self:onShowRedPoint(_selfContainer)
            local EquipLeadPage = require("Equip.EquipLeadPage")
            EquipLeadPage:showRedPoind(ParentContainer)
        elseif pageName == thisPageName and extraParam == "initTouchButton" then
            MercenaryTouchSoundManager:initTouchButton(_selfContainer, _curMercenaryInfo.itemId)
        elseif pageName == thisPageName then
            self:refreshPage(_selfContainer)
        elseif pageName == "EquipRefreshPage" and tonumber(extraParam) == _curMercenaryInfo.roleId then
            self:refreshPage(_selfContainer)
        end
    elseif typeId == MSG_MAINFRAME_POPPAGE then
        -- 宝石穿上卸下更新佣兵界面的武器上的状态
        local pageName = MsgMainFramePopPage:getTrueType(message).pageName
        if pageName ~= thisPageName then
            self:showEquipInfo(_selfContainer)
        end
    end
end

function EquipMercenaryPage:getPacketInfo()

end

function EquipMercenaryPage:onExecute(ParentContainer)
    if _fateWearsPage then
        _fateWearsPage:onExecute(_selfContainer)
    end
end

function EquipMercenaryPage:getActivityInfo()

end

function EquipMercenaryPage:onReceivePacket(ParentContainer)
    CCLuaLog("changeMercenary onReceivePacket")
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if _fateWearsPage then
        _fateWearsPage:onReceivePacket(opcode, msgBuff)
    end

    CCLuaLog("changeMercenary opcode" .. tostring(opcode))
    if opcode == opcodes.ROLE_CARRY_SKILL_S then
        self:showSkillInfo()
    elseif opcode == opcodes.ROLE_FIGHT_S then
        self:refreshPage(ParentContainer)
    elseif opcode == opcodes.EQUIP_DRESS_S then
        self:showEquipInfo(self.container)
    elseif opcode == opcodes.EQUIP_ENHANCE_S then        
        self:refreshPage(self.container)
    elseif opcode == opcodes.ROLE_INFO_SYNC_S then
        UserEquipManager:checkAllEquipNotice()
        self:refreshPage(self.container)
    end
end

function EquipMercenaryPage:setMercenaryId(id, showFateSubPage)
    _showFateSubPage = showFateSubPage
    _curMercenaryId = id
end

function EquipMercenaryPage:onExit(ParentContainer)
    --------------
    --UserMercenaryManager:removeActiviteRoleIdSubscriber(thisPageName)
    --------------
    if _fateWearsPage then
        _fateWearsPage:removePacket(ParentContainer)
        _fateWearsPage:onExit(_selfContainer)
        _fateWearsPage.container:removeFromParentAndCleanup(true)
        _fateWearsPage = nil
    end

    local heroNode = self.container:getVarNode("mSpine")
    if heroNode then
        heroNode:removeAllChildren()
    end  
    self.container = nil
    self:removePacket(ParentContainer)
end

function EquipMercenaryPage_getCurSelectMerRoleInfo()
    return _curMercenaryInfo
end

function EquipMercenaryPage:checkFetterRedPoint()
    if self.container then
        local flag = FetterManager.checkAvailableRelations()
        NodeHelper:setNodesVisible(self.container, { mFetterPoint = flag })
    end
end

function EquipMercenaryPage_onRisingStar()
    EquipMercenaryPage:onRisingStar()
end

function EquipMercenaryPage_onExpedition()
    EquipMercenaryPage:onExpedition()
end

function EquipMercenaryPage_onTrain()
    EquipMercenaryPage:onTrain()
end

return EquipMercenaryPage