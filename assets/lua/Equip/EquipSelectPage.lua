----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
EquipFilterType = {
    Dress = 1,
    -- 上装
    Melt = 2,
    -- 熔炼
    Swallow = 3,
    -- 吞噬
    Extend = 4,
    -- 传承
    CompoundDST = 5,
    -- 融合
    CompoundSRC = 5,
    -- SCR, DST 的逻辑改为一样了，所以值一样为5
    SuitDec = 6,-- 装备分解
}
------------local variable for system api--------------------------------------
local ceil = math.ceil
--------------------------------------------------------------------------------
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "EquipSelectPage"

local UserItemManager = require("Item.UserItemManager")
local PBHelper = require("PBHelper")
local NodeHelper = require("NodeHelper")
local EquipMercenaryPage = require("EquipMercenaryPage")
local UserMercenaryManager = require("UserMercenaryManager")
local GuideManager = require("Guide.GuideManager")
local InfoAccesser = require("Util.InfoAccesser")

local opcodes = {
    EQUIP_DRESS_S = HP_pb.EQUIP_DRESS_S
}

local option = {
    ccbiFile = "EquipmentSelectPopUp_1.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onConfirmation = "onConfirm",
        onTakeOff="onTakeOff"
    },
    opcode = opcodes
}

local EquipSelectPageBase = { }

local EquipOprHelper = require("Equip.EquipOprHelper")

local SortType = {
    Score_ASC = 1,
    Score_DESC = 2
}
local PageInfo = {
    roleId = UserInfo.roleInfo.roleId,
    targetPart = 1,
    currentEquipId = nil,
    selectedEquipId = nil,
    optionIds = { },
    dressType = 1,
    selectedIds = { },
    deepCopySelectedIds = { },
    filterType = EquipFilterType.Dress,
    sortType = SortType.Score_ASC,
    limit = 1,
    isFull = false,
    callback = nil
}
local thisScrollView = nil
local thisScrollViewOffset = nil
local thisContainer = nil

local godlyExpSelectMap = { }

function sortEquipByScore(id_1, id_2)
    local isAsc = PageInfo.sortType == SortType.Score_ASC

    if id_2 == nil then
        return isAsc
    end
    if id_1 == nil then
        return not isAsc
    end

    local userEquip_1 = UserEquipManager:getUserEquipById(id_1)
    local userEquip_2 = UserEquipManager:getUserEquipById(id_2)

    if not EquipManager:isDressableWithLevel(userEquip_1.equipId) and EquipManager:isDressableWithLevel(userEquip_2.equipId) then
        return not isAsc
    elseif EquipManager:isDressableWithLevel(userEquip_1.equipId) and not EquipManager:isDressableWithLevel(userEquip_2.equipId) then
        return isAsc
    end


    if userEquip_1.score ~= userEquip_2.score then
        if userEquip_1.score > userEquip_2.score then
            return isAsc
        end
        return not isAsc
    end

    -- 装备id
    if userEquip_1.equipId > userEquip_2.equipId then
        return isAsc
    end

    return not isAsc
end

function sortEquipByQualityScore(id_1, id_2)
    local isAsc = PageInfo.sortType == SortType.Score_ASC

    if id_2 == nil then
        return isAsc
    end
    if id_1 == nil then
        return not isAsc
    end

    local userEquip_1 = UserEquipManager:getUserEquipById(id_1)
    local userEquip_2 = UserEquipManager:getUserEquipById(id_2)

    local quality_1 = EquipManager:getQualityById(userEquip_1.equipId)
    local quality_2 = EquipManager:getQualityById(userEquip_2.equipId)

    if quality_1 ~= quality_2 then
        if quality_1 < quality_2 then
            return isAsc
        else
            return not isAsc
        end
    end

    if userEquip_1.score ~= userEquip_2.score then
        if userEquip_1.score > userEquip_2.score then
            return isAsc
        end
        return not isAsc
    end

    -- 装备id
    if userEquip_1.equipId > userEquip_2.equipId then
        return isAsc
    end

    return not isAsc
end
--------------------------------------------------------------
local EquipItem = {
    ccbiFile = "EquipmentSelectContent_1.ccbi",
    initTexHeight = nil,
    initSize =
    {
        container = nil
    },
}

function EquipItem.onFunction(eventName, container)
    if eventName == "luaInitItemView" then
        EquipItem.onRefreshItemView(container)
    elseif eventName == "onEquipment" then
        EquipItem.dressEquip(container)
    elseif eventName == "onChocice" then
        EquipItem.onSelect(container)
    elseif eventName == "onHand" then
        EquipItem.onHand(container)
    end
end
function EquipItem_dressEquip()
    local EquipOprHelper = require("Equip.EquipOprHelper")
    local contentId = 1
    local userEquipId = PageInfo.optionIds[contentId]
    local userEquipInfo = UserEquipManager:getUserEquipById(userEquipId)

    local roleEquip = nil
    if PageInfo.roleId == UserInfo.roleInfo.roleId then
        roleEquip = UserInfo.getEquipByPart(PageInfo.targetPart)
    else
        roleEquip = UserMercenaryManager:getEquipByPart(PageInfo.roleId, PageInfo.targetPart)
    end
    local roleEquipIdInfo
    if roleEquip then
        local roleEquipId = roleEquip.equipId
        roleEquipIdInfo = UserEquipManager:getUserEquipById(roleEquipId)
    end
    if roleEquipIdInfo and UserEquipManager:isCanExtend(roleEquipIdInfo, userEquipInfo) then
        PageManager.popPage(thisPageName)
        EquipOprHelper:dressEquip(userEquipId, PageInfo.roleId, PageInfo.dressType)
    else
        PageManager.popPage(thisPageName)
        EquipOprHelper:dressEquip(userEquipId, PageInfo.roleId, PageInfo.dressType)
    end
end

function EquipItem.dressEquip(container)
    local EquipOprHelper = require("Equip.EquipOprHelper")
    local contentId = container:getTag()
    local userEquipId = PageInfo.optionIds[contentId]
    local userEquipInfo = UserEquipManager:getUserEquipById(userEquipId)

    local roleEquip = nil
    if PageInfo.roleId == UserInfo.roleInfo.roleId then
        roleEquip = UserInfo.getEquipByPart(PageInfo.targetPart)
    else
        roleEquip = UserMercenaryManager:getEquipByPart(PageInfo.roleId, PageInfo.targetPart)
    end
    local roleEquipIdInfo
    if roleEquip then
        local roleEquipId = roleEquip.equipId
        roleEquipIdInfo = UserEquipManager:getUserEquipById(roleEquipId)
    end

    if roleEquipIdInfo and UserEquipManager:isCanExtend(roleEquipIdInfo, userEquipInfo) then
        PageManager.popPage(thisPageName)
        EquipOprHelper:dressEquip(userEquipId, PageInfo.roleId, PageInfo.dressType)
    else
        PageManager.popPage(thisPageName)
        EquipOprHelper:dressEquip(userEquipId, PageInfo.roleId, PageInfo.dressType)
    end

    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
end

function EquipItem.onHand(container)
    ---- 專武資訊
    --local contentId = container:getTag()
    --local userEquipId = PageInfo.optionIds[contentId]
    --local AWDetail = require("AncientWeapon.AncientWeaponDetail")
    --local detail = AWDetail:new():init(thisContainer)
    --detail:setShowType(AncientWeaponDetail_showType.NON_EQUIPED)
    --detail:setRoleId(PageInfo.roleId)
    --detail:loadUserEquip(userEquipId)
    --detail:show()
    --local contentId = container:getTag()
    --local userEquipId = PageInfo.optionIds[contentId]
    --local userEquip = UserEquipManager:getUserEquipById(userEquipId)
    --local equipId = userEquip.equipId
    --
    --local itemCfg = { type = 4 * 10000, itemId = equipId, count = 1 }  
    --GameUtil:showTip(container:getVarNode("mPic"), itemCfg)
end

function EquipItem.refreshSelectBox(container)
    local btnVisible = { }
    local contentId = container:getTag()
    local userEquipId = PageInfo.optionIds[contentId]
    local userEquip = UserEquipManager:getUserEquipById(userEquipId)
    local equipId = userEquip.equipId

    local isSelected = false
    if equipId then
        isSelected = PageInfo.selectedIds[userEquipId] ~= nil
    else
        local selected = godlyExpSelectMap[userEquipId]
        if selected then
            isSelected = common:table_hasValue(selected, contentId)
        end
    end
    NodeHelper:setMenuItemSelected(container, { mChocice = isSelected })
    btnVisible["mChociceNode"] = isSelected or not PageInfo.isFull

    NodeHelper:setNodesVisible(container, btnVisible)
end


function EquipItem.onRefreshItemView(container)
    local contentId = container:getTag()
    local userEquipId = PageInfo.optionIds[contentId]
    local userEquip = UserEquipManager:getUserEquipById(userEquipId)
    local equipId = userEquip.equipId
    local nTag = GameConfig.Tag.HtmlLable
    NodeHelper:setMenuItemSelected(container, { mChocice = false })
    -- 两个文本初始的高度
    local mLabelName = container:getVarNode("mEquipmentName")

    if EquipItem.initSize.container == nil then
        EquipItem.initSize.container = container:getContentSize()
    end

    EquipItem.initScoreHeight = 0
    EquipItem.initDescHeight = 0

    local name, quality, icon, star = nil, nil, 1
    if equipId ~= nil then
        name = EquipManager:getNameById(equipId)
        quality = EquipManager:getQualityById(equipId)
        star = EquipManager:getStarById(equipId)
        icon = EquipManager:getIconById(equipId)
    end
    -- 選擇裝備
    local levelsAttrs = { }
    if equipId >= 10000 then
        --local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
        --levelsAttrs = AncientWeaponDataMgr:getEquipAttr(equipId, {
        --    { ["level"] = userEquip.strength,   ["star"] = EquipManager:getStarById(equipId) }
        --})
        local name_num_attr_list = UserEquipManager:getMainAttrStrAndNum(userEquip)
        levelsAttrs = {}
        for idx = 1, #name_num_attr_list do
            local each = name_num_attr_list[idx]
            local attrInfo = InfoAccesser:getAttrInfo(each[3], each[2])
            levelsAttrs[#levelsAttrs+1] = attrInfo
        end
    else
        levelsAttrs = { }
        for _, equipAttr in ipairs(userEquip.attrInfos) do
            local attr = equipAttr.attrData
            if attr.attrId then
                --if tonumber(attr.attrId) ~= Const_pb.MAGDEF and tonumber(attr.attrId) ~= Const_pb.MAGIC_attr and tonumber(attr.attrId) ~= Const_pb.BUFF_MAGDEF_PENETRATE then
                    table.insert(levelsAttrs, { val = attr.attrValue, icon = "attri_" .. attr.attrId .. ".png", attr = attr.attrId })
                --end
            end
        end
    end

    local roleName = ""
    local lb2Str = {
        mEquipmentName = "",
    }
    -- 當前裝備
    local currentAttr = { }
    local currEquip = UserEquipManager:getUserEquipById(PageInfo.currentEquipId)
    local currEquipId = currEquip and currEquip.equipId
    if currEquipId then
        if currEquipId >= 10000 then
            --local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
            --local attrs = AncientWeaponDataMgr:getEquipAttr(currEquipId, {
            --    { ["level"] = currEquip.strength,   ["star"] = EquipManager:getStarById(currEquipId) }
            --})
            local name_num_attr_list = UserEquipManager:getMainAttrStrAndNum(currEquip)
            local nowlevelsAttrs = {}
            for idx = 1, #name_num_attr_list do
                local each = name_num_attr_list[idx]
                local attrInfo = InfoAccesser:getAttrInfo(each[3], each[2])
                nowlevelsAttrs[#nowlevelsAttrs+1] = attrInfo
            end
            for i = 1, #levelsAttrs do
                currentAttr[nowlevelsAttrs[i].attr] = nowlevelsAttrs[i].val
            end
        else
            for _, equipAttr in ipairs(currEquip.attrInfos) do
                local attr = equipAttr.attrData
                if attr.attrId then
                    currentAttr[attr.attrId] = attr.attrValue
                end
            end
        end
    end
    for i = 1, 3 do
        NodeHelper:setNodesVisible(container, { ["mEquipmentAttr" .. i] = ((levelsAttrs and levelsAttrs[i]) and true or false) })
        if (levelsAttrs and levelsAttrs[i]) then
            NodeHelper:setSpriteImage(container, { ["mEquipmentIcon" .. i] = levelsAttrs[i].icon }, { })
            NodeHelper:setStringForLabel(container, { ["mEquipmentTex" .. i] = levelsAttrs[i].val })
            if currEquipId then -- 有穿裝備 > 比較數值
                if currentAttr[levelsAttrs[i].attr] then
                    local diff = levelsAttrs[i].val - currentAttr[levelsAttrs[i].attr]
                    if diff > 0 then
                        NodeHelper:setStringForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = "(+" .. diff .. ")" })
                        NodeHelper:setColorForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = GameConfig.ATTR_CHANGE_COLOR.PLUS })
                    elseif diff < 0 then
                        NodeHelper:setStringForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = "(" .. diff .. ")" })
                        NodeHelper:setColorForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = GameConfig.ATTR_CHANGE_COLOR.MINUS })
                    else
                        NodeHelper:setStringForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = "" })
                    end
                else
                    NodeHelper:setStringForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = "(+" .. levelsAttrs[i].val .. ")" })
                    NodeHelper:setColorForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = GameConfig.ATTR_CHANGE_COLOR.PLUS })
                end
            else
                NodeHelper:setStringForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = "(+" .. levelsAttrs[i].val .. ")" })
                NodeHelper:setColorForLabel(container, { ["mEquipmentTex" .. i .. "_" .. i] = GameConfig.ATTR_CHANGE_COLOR.PLUS })
            end
        end
    end
    local suitId = EquipManager:getSuitIdById(equipId)
    local isAw = equipId >= 10000
    if suitId > 0 then
        local suitCfg = ConfigManager.getSuitCfg()
        local roleInfo = UserMercenaryManager:getUserMercenaryInfos()[PageInfo.roleId]
        local suitName = suitCfg[suitId].suitName .. "(" .. UserEquipManager:getEquipedSuitCount(suitId, roleInfo) .. "/" .. tostring(suitCfg[suitId].maxNum) .. ")"
        NodeHelper:setNodesVisible(container, { mEquipTip = true })
        NodeHelper:setStringForLabel(container, { mEquipTip = suitName })
        NodeHelper:setColorForLabel(container, { mEquipTip = GameConfig.RARITY_COLOR["STAR_" .. quality] })
    elseif isAw then
        local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
        local awRoleId = AncientWeaponDataMgr:getEquipHero(equipId)--math.floor(equipId / 100) % 100
        NodeHelper:setNodesVisible(container, { mEquipTip = true })
        NodeHelper:setStringForLabel(container, { mEquipTip = common:getLanguageString("@EquipCondition", common:getLanguageString("@HeroName_" .. awRoleId)) })
        NodeHelper:setColorForLabel(container, { mEquipTip = GameConfig.RARITY_COLOR["STAR_" .. quality] })
    else
        NodeHelper:setNodesVisible(container, { mEquipTip = false })
    end

    local sprite2Img = {
        mPic = icon
    }
    local itemImg2Qulity = {
        mHand = quality
    }
    local scaleMap = { mPic = GameConfig.EquipmentIconScale }

    local nodesVisible = { }
    local gemVisible = false

    nodesVisible["mAni"] = false
    nodesVisible["mHelmetGemNode"] = false
    NodeHelper:setNodesVisible(container, { nodesVisible, mLv = false })
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, itemImg2Qulity)

    if equipId >= 10000 then    -- 專武星數顯示規則不同
        for i = 1, 13 do
            NodeHelper:setNodesVisible(container, { ["mAncientStar" .. i] = (i == star) })
        end
        NodeHelper:setNodesVisible(container, { mAncientStarNode = true, mStarNode = false })
    else
        for i = 1, 6 do
            NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == star) })
            NodeHelper:setNodeScale(container,"mStar" .. i, 1.8, 1.8)
        end
        NodeHelper:setNodesVisible(container, { mAncientStarNode = false, mStarNode = true })
    end
    NodeHelper:setNodesVisible(container, { mNFT = false, mShader = false, mLvNUm_1 = false, mLv = false })

    local nameStr = name
    if equipId ~= nil then
        nameStr = common:getLanguageString("@LevelName", name)
    end

    nameStr = common:fillHtmlStr("Quality_" .. quality, nameStr)
    local _label = NodeHelper:addHtmlLable(mLabelName, nameStr, nTag, CCSizeMake(380, 30))

    local roleEquip = nil
    if PageInfo.roleId ~= UserInfo.roleInfo.roleId then
        roleEquip = EquipMercenaryPage_getCurSelectMerRoleInfo()
    end

    local str, strDescInfo = "", ""
    
    local btnVisible = {
        mEquipmentNode = true,
        mChociceNode = false,
        mRefningPromptNode = false
    }
    NodeHelper:setNodesVisible(container, btnVisible)

    if contentId == 1 then
        GuideManager.PageContainerRef["EquipChangeSelectPage"] = container
    end
end
----------------------------------------------------------------------------------
	
function EquipSelectPageBase:splitStr(str)
    if str == nil then
        return nil
    end
    local i, j = string.find(str, "<br/>")
    local m, n = string.find(str, "<font")
    local strScore = ""
    local strDesc = ""
    local strFront = nil
    if i ~= nil and j ~= nil and m ~= nil and n ~= nil then
        if m ~= 1 then
            strFront = string.sub(str, 1, m - 1)
        end
        if strFront ~= nil then
            strScore = string.sub(str, 1, i - 1) .. '</p>'
            strDescInfo = strFront .. string.sub(str, j + 1, -1)
        else
            strScore = string.sub(str, 1, i - 1)
            strDescInfo = string.sub(str, j + 1, -1)
        end
    end
    return strScore, strDescInfo
end

-----------------------------------------------
-- EquipSelectPageBase页面中的事件处理
----------------------------------------------
function EquipSelectPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:setCurrentEquipId()
    self:setOptionIds()

    self:initScrollview(container)

    self:refreshPage(container)
    self:rebuildAllItem(container)
    thisScrollView = container.mScrollView
    thisContainer = container
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["EquipSelectPage"] = container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function EquipSelectPageBase:onExit(container)
    self:removePacket(container)
    local NodeHelper = require("NodeHelper")
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    godlyExpSelectMap = { }
    NodeHelper:deleteScrollView(container)
    thisScrollView = nil
    thisScrollViewOffset = nil
end
----------------------------------------------------------------
function EquipSelectPageBase:setCurrentEquipId()
    local roleEquip = nil
    if PageInfo.roleId == UserInfo.roleInfo.roleId then
        roleEquip = UserInfo.getEquipByPart(PageInfo.targetPart)
    else
        roleEquip = UserMercenaryManager:getEquipByPart(PageInfo.roleId, PageInfo.targetPart)
    end

    if roleEquip then
        PageInfo.currentEquipId = roleEquip.equipId
        PageInfo.dressType = GameConfig.DressEquipType.Change
    else
        PageInfo.currentEquipId = nil
        PageInfo.dressType = GameConfig.DressEquipType.On
    end
end

function EquipSelectPageBase:setOptionIds()
    PageInfo.optionIds = { }

    local filterType = PageInfo.filterType

    local ids = { }

    -- classify
    if filterType == EquipFilterType.Dress or 
       (filterType == EquipFilterType.CompoundDST and PageInfo.targetPart) then
        ids = UserEquipManager:getEquipIdsByClass("Part", PageInfo.targetPart)
    else
        ids = UserEquipManager:getEquipIdsByClass("All")
    end

    -- filter
    local roleProf = nil
    if filterType == EquipFilterType.Dress then
        if PageInfo.roleId == UserInfo.roleInfo.roleId then
            roleProf = UserInfo.roleInfo.prof
        else
            roleProf = UserMercenaryManager:getProfessioinIdByPart(PageInfo.roleId, PageInfo.targetPart)
        end
    end
    for _, id in ipairs(ids) do
        local isOk = false
        local isSame = PageInfo.currentEquipId ~= nil and PageInfo.currentEquipId == id
        if not isSame and not UserEquipManager:isEquipDressed(id) then
            if filterType == EquipFilterType.Dress then
                local userEquip = UserEquipManager:getUserEquipById(id)
                if EquipManager:isDressable(userEquip.equipId, roleProf) then
                    isOk = true
                end
            else
                isOk = true
            end
        end
        if isOk then
            table.insert(PageInfo.optionIds, id)
        end
    end

    -- sort
    table.sort(PageInfo.optionIds, sortEquipByScore)
end

function EquipSelectPageBase:showCurrentEquip(container)
    local PBHelper = require("PBHelper")
    local NodeHelper = require("NodeHelper")
    local userEquipId = PageInfo.currentEquipId
    local userEquip = UserEquipManager:getUserEquipById(userEquipId)
    local equipId = userEquip.equipId
    local tag = GameConfig.Tag.HtmlLable
    -- 检查是否装备
    local isDress = UserEquipManager:isDressedWithEquipInfo(userEquip)
    if isDress then
        NodeHelper:setNodesVisible(container, { mEquipOn = true, unLoadNode = false })
    end

    local level = EquipManager:getLevelById(equipId)
    local name = EquipManager:getNameById(equipId)
    local quality = EquipManager:getQualityById(equipId)
    local star = EquipManager:getStarById(equipId)
    local roleName = ""
    local displayStrength = common:getLanguageString("@LevelStr", userEquip.strength + 1)
    local lb2Str = {
        mLv = common:getR2LVL() .. level,
        mLvNUm_1 = displayStrength,
        mEquipmentName = "",
        mEquipmentTex1 = "1",
    }
    local sprite2Img = {
        mPic = EquipManager:getIconById(equipId)
    }
    local itemImg2Qulity = {
        mHand = quality
    }
    local scaleMap = { mPic = GameConfig.EquipmentIconScale }

    local nodesVisible = { }
    nodesVisible["mAni"] = false
    nodesVisible["mGemNode"] = false
    NodeHelper:setNodesVisible(container, { nodesVisible})

    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, itemImg2Qulity)

    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == star) })
        NodeHelper:setNodeScale(container,"mStar" .. i, 1.8, 1.8)
    end
    NodeHelper:setNodesVisible(container, { mNFT = false, mShader = false, mLvNUm_1 = false, mLv = false })

    local nameStr = common:getLanguageString("@LevelName", name)
    nameStr = common:fillHtmlStr("Quality_deep_" .. quality, nameStr)
    local nameNode = container:getVarNode("mEquipmentName")
    local _label = NodeHelper:addHtmlLable(nameNode, nameStr, GameConfig.Tag.HtmlLable, CCSizeMake(380, 30))

    local levelsAttrs = { }
    if equipId >= 10000 then
        --local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
        --levelsAttrs = AncientWeaponDataMgr:getEquipAttr(equipId, {
        --    { ["level"] = userEquip.strength,   ["star"] = EquipManager:getStarById(equipId) }
        --})
          local name_num_attr_list = UserEquipManager:getMainAttrStrAndNum(userEquip)
            levelsAttrs = {}
            for idx = 1, #name_num_attr_list do
                local each = name_num_attr_list[idx]
                local attrInfo = InfoAccesser:getAttrInfo(each[3], each[2])
                levelsAttrs[#levelsAttrs+1] = attrInfo
            end
    else
        levelsAttrs = { }
        for _, equipAttr in ipairs(userEquip.attrInfos) do
            local attr = equipAttr.attrData
            if attr.attrId then
                --if tonumber(attr.attrId) ~= Const_pb.MAGDEF and tonumber(attr.attrId) ~= Const_pb.MAGIC_attr and tonumber(attr.attrId) ~= Const_pb.BUFF_MAGDEF_PENETRATE then
                    table.insert(levelsAttrs, { val = attr.attrValue, icon = "attri_" .. attr.attrId .. ".png" })
                --end
            end
        end
    end
    for i = 1, 3 do
        NodeHelper:setNodesVisible(container, { ["mEquipmentAttr" .. i] = ((levelsAttrs and levelsAttrs[i]) and true or false) })
        if (levelsAttrs and levelsAttrs[i]) then
            NodeHelper:setSpriteImage(container, { ["mEquipmentIcon" .. i] = levelsAttrs[i].icon }, { })
            NodeHelper:setStringForLabel(container, { ["mEquipmentTex" .. i] = levelsAttrs[i].val })
        end
    end
    -- 專武/套裝顯示
    local suitId = EquipManager:getSuitIdById(equipId)
    if suitId > 0 then
        local suitCfg = ConfigManager.getSuitCfg()
        local roleInfo = UserMercenaryManager:getUserMercenaryInfos()[PageInfo.roleId]
        local suitName = suitCfg[suitId].suitName .. "(" .. UserEquipManager:getEquipedSuitCount(suitId, roleInfo) .. "/" .. tostring(suitCfg[suitId].maxNum) .. ")"
        NodeHelper:setNodesVisible(container, { mEquipTip = true })
        NodeHelper:setStringForLabel(container, { mEquipTip = suitName })
        NodeHelper:setColorForLabel(container, { mEquipTip = GameConfig.RARITY_COLOR["STAR_" .. quality] })
    elseif equipId >= 10000 then
        local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
        local awRoleId = AncientWeaponDataMgr:getEquipHero(equipId)--math.floor(equipId / 100) % 100
        NodeHelper:setNodesVisible(container, { mEquipTip = true })
        NodeHelper:setStringForLabel(container, { mEquipTip = common:getLanguageString("@EquipCondition", common:getLanguageString("@HeroName_" .. awRoleId)) })
        NodeHelper:setColorForLabel(container, { mEquipTip = GameConfig.RARITY_COLOR["STAR_" .. quality] })
    else
        NodeHelper:setNodesVisible(container, { mEquipTip = false })
    end
end

function EquipSelectPageBase:refreshPage(container)
    local NodeHelper = require("NodeHelper")
    if PageInfo.currentEquipId then
        self:showCurrentEquip(container)
    end
    NodeHelper:setNodesVisible(container, {
        mEquipmentSelectPrompt = #PageInfo.optionIds == 0,
    })
end	

----------------scrollview-------------------------
function EquipSelectPageBase:initScrollview(container)
    local NodeHelper = require("NodeHelper")
    local svName = PageInfo.currentEquipId and "mBackpackContent2" or "mBackpackContent1"
    NodeHelper:initRawScrollView(container, svName)

     local svNode = container:getVarScrollView("mBackpackContent2")
         local viewSize = svNode:getViewSize()
         svNode:setViewSize(CCSizeMake(viewSize.width, viewSize.height))

    local hasEquiped = PageInfo.currentEquipId ~= nil
    NodeHelper:setNodesVisible(container, {
        mBackpackContentNode = not hasEquiped,
        mEquipmentContentNode = true,
        EquipedItem = hasEquiped
    } )
end

function EquipSelectPageBase:rebuildAllItem(container)
    self:clearAllItem(container)
    local noEquip = container:getVarLabelTTF("mNoEquip")
    local noEquipPic = container:getVarSprite("NoFriendSprite")
    if #PageInfo.optionIds > 0 then
        self:buildItem(container)
        noEquip:setVisible(false)
        noEquipPic:setVisible(false)
    else
        noEquip:setVisible(true)
        noEquipPic:setVisible(true)
    end
end

function EquipSelectPageBase:clearAllItem(container)
    local NodeHelper = require("NodeHelper")
    NodeHelper:clearScrollView(container)
end

function EquipSelectPageBase:buildItem(container)
--------------子物件生成------------------
    local NodeHelper = require("NodeHelper")
    local size = #PageInfo.optionIds
    local items = nil
    items = NodeHelper:buildRawScrollView(container, size, EquipItem.ccbiFile, EquipItem.onFunction)
    if thisScrollView and thisScrollViewOffset then
        thisScrollView:setContentOffset(thisScrollViewOffset)
    end
    if items and items[1] then
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["EquipSelectItem"] = items[1]
    end
end
	
	
function EquipSelectPageBase:refreshSelectedBox(container)
    if container.mScrollViewRootNode then
        local children = container.mScrollViewRootNode:getChildren()
        if children then
            for i = 1, children:count(), 1 do
                if children:objectAtIndex(i - 1) then
                    local node = tolua.cast(children:objectAtIndex(i - 1), "CCNode")
                    EquipItem.refreshSelectBox(node)
                end
            end
        end
    end
end
----------------click event------------------------
function EquipSelectPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function EquipSelectPageBase:onTakeOff(container)
    local userEquipId = PageInfo.currentEquipId
    local dressType = GameConfig.DressEquipType.Off
    EquipOprHelper:dressEquip(userEquipId, PageInfo.roleId, dressType)
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    self:onClose(container)
end

function EquipSelectPageBase_onConfirm()
    EquipSelectPageBase:onConfirm(container)
end
function EquipSelectPageBase:onConfirm(container)
    if PageInfo.callback then
        PageInfo.callback(PageInfo.selectedIds)
    end
    PageManager.popPage(thisPageName)
end

-- 回包处理
function EquipSelectPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.EQUIP_DRESS_S then
        return
    end
end
-- ]]

-- 继承此类的活动如果同时开，消息监听不能同时存在,通过tag来区分
function EquipSelectPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == thisPageName then
            self:rebuildAllItem(container)
        end
    end
end

function EquipSelectPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EquipSelectPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
EquipSelectPage = CommonPage.newSub(EquipSelectPageBase, thisPageName, option)


function EquipSelectPage_setPart(part, roleId)
    PageInfo.targetPart = part
    PageInfo.roleId = roleId or UserInfo.roleInfo.roleId
    PageInfo.filterType = EquipFilterType.Dress
end	

function EquipSelectPage_setSuit()
    PageInfo.targetPart = part
    PageInfo.roleId = roleId or UserInfo.roleInfo.roleId
    PageInfo.filterType = EquipFilterType.Dress
end		