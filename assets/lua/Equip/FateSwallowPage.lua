-- Author:Ranjinlan
-- Create Data: [2018-05-09 11:03:24]
-- 命格吞噬界面

local FateSwallowPageBase = {}
local FateDataManager = require("FateDataManager")
local HP_pb = require("HP_pb")
local MysticalDress_pb = require("Badge_pb")

local option = {
	ccbiFile = "PrivateGobbleUpPopUp.ccbi",
	handlerMap = {
        onClose                = "onClose",
        onAutomaticScreening   = "onAutoSelect",
        onGobbleUp             = "onSwallow",
        onHelp                 = "onHelp",
	},
	opcode = {
        MYSTICAL_DRESS_ABSORB_C = HP_pb.BADGE_UPGRADE_C, --吸收
        MYSTICAL_DRESS_ABSORB_S = HP_pb.BADGE_UPGRADE_S, --吸收
    },
}

local PageInfo = {
    fateId = nil,--吞噬者 / 升级者
    swallowIdList = {}, -- 被吞噬者们
    swallowPreLv = nil,
    thisContainer = nil,
}

for i = 1, GameConfig.FatePageConst.MaxSwallowNum do
	option.handlerMap["onGobbleMenu" .. i] = "goSelectFate";
end

function FateSwallowPageBase:onEnter(container)
    PageInfo.swallowPreLv = nil
    PageInfo.thisContainer = container
    FateSwallowPageBase:registerPacket(container)
    
    FateSwallowPageBase:refreshPage(container)
end

local function sortFates(fateData_1,fateData_2)
    local conf_1 = fateData_1:getConf()
    local conf_2 = fateData_2:getConf()
    if conf_1.quality ~= conf_2.quality then
        return conf_1.quality < conf_2.quality
    elseif conf_1.starLevel ~= conf_2.starLevel then
        return conf_1.starLevel < conf_2.starLevel
    elseif fateData_1.level ~= fateData_2.level then
        return fateData_1.level < fateData_2.level
    else
        return fateData_1.exp < fateData_2.exp
    end
end

function FateSwallowPageBase:refreshPage(container)
    local visibleMap ,strMap,imgMap,imgQulity= {},{},{},{}
    local selfFateData = FateDataManager:getFateDataById(PageInfo.fateId)
    if selfFateData then
        local conf = selfFateData:getConf()
        imgMap["mBadgeFrameShadeMain"] = NodeHelper:getImageBgByQuality(conf.quality) --背景框
        imgMap["mBadgePicMain"] = conf.icon
        strMap["mBadgeLvMain"] = "Lv." .. selfFateData.level
        imgQulity["mBadgeBgPicMain"] = conf.quality --品质框
        for star = 1, GameConfig.FatePageConst.MaxStarNum do
            visibleMap["mBadgeMainStar" .. star] = conf.starLevel >= star
        end
    end
    for i = 1, GameConfig.FatePageConst.MaxSwallowNum do
        local fateData = FateDataManager:getFateDataById(PageInfo.swallowIdList[i])
        local childNode = container:getVarMenuItemCCB("mGobbleMenu" .. i)
        childNode = childNode:getCCBFile()
        if fateData then
            local conf = fateData:getConf()
            imgMap["mBadgeBgPic"] = NodeHelper:getImageBgByQuality(conf.quality) --背景框
            imgMap["mBadgePic"] = conf.icon
            strMap["mBadgeLv"] = "Lv." .. fateData.level 
            imgQulity["mBadgeFrameShade"] = conf.quality --品质框
            
            for star = 1, GameConfig.FatePageConst.MaxStarNum do
                visibleMap["mBadgeStar" ..star] = conf.starLevel >= star
            end
        else
            imgMap["mBadgeBgPic"] = GameConfig.Image.BackQualityImg --背景框 
            imgMap["mBadgePic"] = GameConfig.Image.ClickToSelect -- 图标
            strMap["mBadgeLv"] = ""
            imgQulity["mBadgeFrameShade"] = GameConfig.Default.Quality --品质框
            for star = 1, GameConfig.FatePageConst.MaxStarNum do
                visibleMap["mBadgeStar" .. star] = false
            end
        end
        NodeHelper:setNodesVisible(childNode, visibleMap)
        NodeHelper:setStringForLabel(childNode, strMap)
        NodeHelper:setSpriteImage(childNode, imgMap)
	    NodeHelper:setQualityFrames(childNode, imgQulity, nil, true);
    end
    local swallowExp,swallowEndExp,swallowEndLevel = FateSwallowPageBase:getSwallowExp(selfFateData)
    if swallowEndLevel > selfFateData.level then
        strMap.mGodEquipmentLevel = common:getLanguageString("@DressTips_15",selfFateData.level,swallowEndLevel) 
    else
        strMap.mGodEquipmentLevel = common:getLanguageString("@DressTips_16",selfFateData.level) 
    end
    local isMaxLevel = selfFateData:isMaxLevel()
    visibleMap["mExpNex"] = (not isMaxLevel) and swallowExp > 0
    visibleMap["mExp"] = (not isMaxLevel) and selfFateData.exp > 0
    strMap.mGodEquipmentExp = common:getLanguageString("@Exp")..(swallowExp + selfFateData.exp).."/"..selfFateData:getLevelUpExp() 
    strMap.mAttNowTxt = "Lv"..selfFateData.level --common:getLanguageString("@GodEquipmentLevel1")..selfFateData.level
    strMap.mAttNow = FateSwallowPageBase:getBasicAttrStr(selfFateData,selfFateData.level)
    visibleMap["mPrivateExp"] = not isMaxLevel
    visibleMap["mGodEquipmentExp"] = not isMaxLevel
    if isMaxLevel then
        strMap.mAttNextTxt = ""
        strMap.mAttNext = ""
    elseif swallowEndLevel ~= selfFateData.level then        
        strMap.mAttNextTxt = "Lv"..swallowEndLevel --common:getLanguageString("@GodEquipmentLevel1")..swallowEndLevel
        strMap.mAttNext = FateSwallowPageBase:getBasicAttrStr(selfFateData,swallowEndLevel)
        NodeHelper:setNodeScale(container, "mExpNex", 1)
    else 
        strMap.mAttNextTxt = "Lv"..selfFateData.level + 1  --common:getLanguageString("@GodEquipmentLevel1")..selfFateData.level + 1
        strMap.mAttNext = FateSwallowPageBase:getBasicAttrStr(selfFateData,selfFateData.level + 1)
        NodeHelper:setNodeScale(container, "mExpNex", swallowEndExp / selfFateData:getLevelUpExp())
    end
    NodeHelper:setNodeScale(container, "mExp", selfFateData.exp / selfFateData:getLevelUpExp())
    
    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, strMap)
    NodeHelper:setSpriteImage(container, imgMap)
	NodeHelper:setQualityFrames(container, imgQulity, nil, true);
    
    
    --NodeHelper:setNodeScale(container, "mExp", scaleX)
    --NodeHelper:setNodeScale(container, "mExpNex", scaleX)
end

function FateSwallowPageBase:getBasicAttrStr(fateData,level)
    if not fateData then return "" end
    local returnStr = nil
    local basicAttrList = fateData:getFateBasicAttr(level)
    if #basicAttrList > 0 then
        for _,v in ipairs(basicAttrList) do
            local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
            local name = common:getLanguageString("@AttrName_" .. v.type)
            returnStr = returnStr and (returnStr .. "\n") or ""
            returnStr = returnStr .. name .. "+" .. valueStr
        end
    end
    return returnStr or ""
end

function FateSwallowPageBase:getSwallowExp(selfFateData)
    local swallowExp = 0
    for k,v in pairs(PageInfo.swallowIdList) do
        local fateData = FateDataManager:getFateDataById(v)
        if fateData then
            if fateData.totalExp > 0 then
                swallowExp = swallowExp + fateData.totalExp
            else
                swallowExp = swallowExp + fateData:getConf().basicExp
            end
        end
    end
    local swallowEndExp,swallowEndLevel = selfFateData:getExpAndLevel(selfFateData.totalExp + swallowExp)
    return swallowExp,swallowEndExp,swallowEndLevel
end

function FateSwallowPageBase:onExit(container)
    PageInfo.thisContainer = nil
    FateSwallowPageBase:removePacket(container)
end

function FateSwallowPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcode) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function FateSwallowPageBase:removePacket(container)
	for key, opcode in pairs(option.opcode) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function FateSwallowPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    if opcode == option.opcode.MYSTICAL_DRESS_ABSORB_S then
        --如果等级提升 播放升级特效
        local selfFateData = FateDataManager:getFateDataById(PageInfo.fateId)
        if selfFateData and PageInfo.swallowPreLv and selfFateData.level > PageInfo.swallowPreLv then
            MessageBoxPage:Msg_Box_Lan("@BadgeLevelUpTip")
        end
        PageInfo.swallowIdList = {}
        FateSwallowPageBase:refreshPage(container)
    end
end

function FateSwallowPageBase:goSelectFate(container,eventName)
    local name = eventName:sub(-1) or ""
    local pos = tonumber(name)
    if not pos then return end
    
    if PageInfo.swallowIdList[pos] then
        PageInfo.swallowIdList[pos] = nil
        FateSwallowPageBase:refreshPage(container)
    else
        require('FateSwallowSelectPage')
        local selectList = {}
        for _,v in pairs(PageInfo.swallowIdList) do
            selectList[#selectList + 1] = v
        end
        FateSwallowSelectPage_setFate({selectId = PageInfo.fateId,selectList = selectList,maxSelectNum = GameConfig.FatePageConst.MaxSwallowNum,callback=FateSwallowPageBase.ConfirmSelectList})
        PageManager.pushPage("FateSwallowSelectPage")
    end
end

function FateSwallowPageBase.ConfirmSelectList(selectList)
    selectList = selectList or {}
    if PageInfo.thisContainer then
        for k in pairs(PageInfo.swallowIdList) do
            PageInfo.swallowIdList[k] = nil
        end
        for _,v in pairs(selectList) do
            PageInfo.swallowIdList[#PageInfo.swallowIdList + 1] = v
        end
        FateSwallowPageBase:refreshPage(PageInfo.thisContainer)
    end
end

function FateSwallowPageBase:onAutoSelect(container)
    local selfFateData = FateDataManager:getFateDataById(PageInfo.fateId)
    if not selfFateData then return end

    local currentSelectNum = 0
    for _ in pairs(PageInfo.swallowIdList) do
        currentSelectNum = currentSelectNum + 1
    end
    if currentSelectNum >= GameConfig.FatePageConst.MaxSwallowNum then 
        return
    end
    if selfFateData:isMaxLevel() then
        return
    end
    local _,_,swallowEndLevel = FateSwallowPageBase:getSwallowExp(selfFateData)
    if selfFateData:isMaxLevel(swallowEndLevel) then
        return
    end
    
    local temp = {}
    for _,v in pairs(PageInfo.swallowIdList) do
        temp[v] = true
    end
    local list = FateDataManager:getNotWearFateList()
    table.sort(list,sortFates)
    local selfQuality = selfFateData:getConf().quality
    local selectNum = 0
    for _,v in ipairs(list) do
        if currentSelectNum >= GameConfig.FatePageConst.MaxSwallowNum then 
            break
        end
        if v.id == selfFateData.id then
        elseif v:getConf().quality <= selfQuality then
            if not temp[v.id] then
                for i = 1, GameConfig.FatePageConst.MaxSwallowNum do
                    if not PageInfo.swallowIdList[i] then
                        PageInfo.swallowIdList[i] = v.id
                        break
                    end
                end
                selectNum = selectNum + 1
                currentSelectNum = currentSelectNum + 1
                
                local _,_,swallowEndLevel = FateSwallowPageBase:getSwallowExp(selfFateData)
                if selfFateData:isMaxLevel(swallowEndLevel) then
                    --如果满级了就不继续选了
                    break
                end
            end
        else
            break
        end
    end
    FateSwallowPageBase:refreshPage(container)
    if selectNum == 0 then
        MessageBoxPage:Msg_Box_Lan("@BadgeNoBadCanSelect")
    end
end

function FateSwallowPageBase:onSwallow(container)
    local selfFateData = FateDataManager:getFateDataById(PageInfo.fateId)
    if not selfFateData then return end
    
    if not next(PageInfo.swallowIdList) then 
        MessageBoxPage:Msg_Box_Lan("@BadgeNoSwallBad")
        return
    end
    
    if selfFateData:isMaxLevel() then
        MessageBoxPage:Msg_Box_Lan("@BadgeHasMaxLevel")
        return
    end
    
    local function sendPacket(isSure)
        if isSure then
            local msg = MysticalDress_pb.HPMysticalDressAbsorbReq()
            msg.id = selfFateData.id
            for _,v in pairs(PageInfo.swallowIdList) do
                msg.dressIds:append(v)
            end
            if selfFateData.roleId then
                msg.roleId = selfFateData.roleId
            end
            common:sendPacket(option.opcode.MYSTICAL_DRESS_ABSORB_C, msg)
            PageInfo.swallowPreLv = selfFateData.level
        end
    end
    
    local swallowExp,swallowEndExp,swallowEndLevel = FateSwallowPageBase:getSwallowExp(selfFateData)
    if selfFateData:isMaxLevel(swallowEndLevel) and swallowEndExp > 0 then
        local title = common:getLanguageString("@BadgeSwallContinueExcMaxExpTitle");
        local msg = common:getLanguageString("@BadgeSwallContinueExcMaxExpDes");
        PageManager.showConfirm(title, msg, sendPacket)
        return
    end
    
    local haveHighQuality = false
    local haveHigherQuality = false
    local selfQuality = selfFateData:getConf().quality
    for _,v in pairs(PageInfo.swallowIdList) do
        local fateData = FateDataManager:getFateDataById(v)
        if fateData then
            local quality = fateData:getConf().quality
            if quality >= GameConfig.FatePageConst.NoticeQuality then
                haveHighQuality = true
                break
            end
            if quality > selfQuality then
                haveHigherQuality = true
                break
            end
        end
    end
    
    if haveHighQuality then
        local title = common:getLanguageString("@BadgeSwallHighLevelTitle");
        local msg = common:getLanguageString("@BadgeSwallHighLevelDes");
        PageManager.showConfirm(title, msg, sendPacket)
    elseif haveHigherQuality then
        local title = common:getLanguageString("@BadgeSwallHighLevelTitle");
        local msg = common:getLanguageString("@BadgeSwallHighLevelDes");
        PageManager.showConfirm(title, msg, sendPacket)
    else
        sendPacket(true)
    end
end

function FateSwallowPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_FATESWALLOW);
end

function FateSwallowPageBase:onClose(container)
    PageManager.popPage("FateSwallowPage")
end

function FateSwallowPage_setFate(fateId)
    PageInfo.fateId = fateId
    PageInfo.swallowIdList = {}
end

local CommonPage = require("CommonPage");
FateSwallowPage = CommonPage.newSub(FateSwallowPageBase, "FateSwallowPage", option);