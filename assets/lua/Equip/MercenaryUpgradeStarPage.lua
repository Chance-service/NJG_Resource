
----------------------------------------------------------------------------------
local HP_pb = require("HP_pb")
local RoleOpr_pb = require("RoleOpr_pb")
local Player_pb = require("Player_pb")
local EquipScriptData = require("EquipScriptData")
local thisPageName = "MercenaryUpgradeStarPage"
local NodeHelper = require("NodeHelper")
local MercenaryUpgradeStarPage = {}
local UserMercenaryManager = require("UserMercenaryManager")
local UserItemManager = require("Item.UserItemManager")
local SkillManager = require("Skill.SkillManager")
local EquipScriptData = require("EquipScriptData")
local UserInfo = require("PlayerInfo.UserInfo")
local MercenaryUpgradeStagePage = require("MercenaryUpgradeStagePage")
local option = {
	ccbiFile = "MercenaryUpgradeStarPopUp.ccbi",
	handlerMap = {
		onClose		        = "onClose",
		onHelp				= "onHelp",
        onButtonLeft        = "onAuto",
        onButtonRight       = "onConfirm",
        onHead1             = "onHead1",
        onConfirm           = "onBreakConfirm",
	},
}

local selectLongClickIndex = 0
local timeCount = 0
local timeInterval = 1
local maxTimeInterval = 5
local isMinus = false
local beganAuto = false
local isMaxLevel = false
local addSum=0

local curStarInfos = {}

for i = 1, 4 do
	option.handlerMap["onStoneFeet0" .. i] = "onClickItem"
    option.handlerMap["onMinus0" .. i] = "onClickMinus"
end
local opcodes = {
	ROLE_INC_STAR_EXP_C = HP_pb.ROLE_INC_STAR_EXP_C,
	ROLE_INC_STAR_EXP_S = HP_pb.ROLE_INC_STAR_EXP_S,
    ROLE_UPGRADE_STAGE_C = HP_pb.ROLE_UPGRADE_STAGE_C,
	ROLE_UPGRADE_STAGE_S = HP_pb.ROLE_UPGRADE_STAGE_S,
    ROLE_EMPLOY_C = HP_pb.ROLE_EMPLOY_C,
    ROLE_EMPLOY_S = HP_pb.ROLE_EMPLOY_S,
}
local costItem = {
    104001,
    104002,
    104003,
    104004,
}
local selectItemCount = {
    [costItem[1]] = 0,
    [costItem[2]] = 0,
    [costItem[3]] = 0,
    [costItem[4]] = 0,
}
local holdAddNum = {
    1, 5, 10
}
local _selfContainer = nil
local holdTime = 0
local _curMercenaryId = nil -- 当前佣兵信息
local _curMercenaryInfo = nil
local _lastStarLevel = -1 --使用經驗書後的等級
local stageLevel = 0   -- 突破等級

function MercenaryUpgradeStarPage:onEnter(container)
    _selfContainer = container
    _curMercenaryInfo = UserMercenaryManager:getMercenaryStatusByItemId(_curMercenaryId)
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    _lastStarLevel = info.level
    stageLevel = info.starLevel
    selectLongClickIndex = 0
    timeCount = 0
    holdTime = 0
    timeInterval = 1
    isMaxLevel = false

    self:createCfgTable(container)
    self:registerPacket(container)
    self:createLongClickLayer(container)
    self:refreshPage(container)

    container:registerMessage(MSG_MAINFRAME_POPPAGE)

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["MercenaryUpgradeStarPage"] = container
end

function MercenaryUpgradeStarPage:createCfgTable(container)
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    
    local roleStarCfg = ConfigManager:getMercenaryUpStepTable()
    local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
    curStarInfos = {}
    for i = 1, #roleStarCfg do
        if roleStarCfg[i].roleId == roleTable.class and roleStarCfg[i].stageLimit <= info.starLevel then
            table.insert(curStarInfos, roleStarCfg[i])
        end
    end
end

function MercenaryUpgradeStarPage:createLongClickLayer(container)
    local layer, menuImage, minusLayer, minusMenuImage
    for i = 1, 4 do
        layer = CCLayer:create()
        layer:setTag(1)
        menuImage = container:getVarMenuItemImage("mStoneFeet0" .. i)
        menuImage:addChild(layer)
        
        local size = menuImage:getContentSize()
        layer:setContentSize(size)
        local index = i
        layer:registerScriptTouchHandler(function(eventName, pTouch)
            if eventName == "began" then
                return MercenaryUpgradeStarPage:onTouchBegin(container, eventName, pTouch, index, false)
            elseif eventName == "moved" then
                return MercenaryUpgradeStarPage:onTouchMove(container, eventName, pTouch, index, false)
            elseif eventName == "ended" then
                return MercenaryUpgradeStarPage:onTouchEnd(container, eventName, pTouch, index, false)
            elseif eventName == "cancelled" then
                return MercenaryUpgradeStarPage:onTouchCancel(container, eventName, pTouch, index, false)
            end
        end
        , false, 0, false)
        layer:setTouchEnabled(true)
        
        minusLayer = CCLayer:create()
        minusLayer:setTag(1)
        minusMenuImage = container:getVarMenuItemImage("mMinusMenu0" .. i)
        minusMenuImage:addChild(minusLayer)

        local size = minusMenuImage:getContentSize()
        minusLayer:setContentSize(size)
        local index = i
        minusLayer:registerScriptTouchHandler(function(eventName, pTouch)
            if eventName == "began" then
                return MercenaryUpgradeStarPage:onTouchBegin(container, eventName, pTouch, index, true)
            elseif eventName == "moved" then
                return MercenaryUpgradeStarPage:onTouchMove(container, eventName, pTouch, index, true)
            elseif eventName == "ended" then
                return MercenaryUpgradeStarPage:onTouchEnd(container, eventName, pTouch, index, true)
            elseif eventName == "cancelled" then
                return MercenaryUpgradeStarPage:onTouchCancel(container, eventName, pTouch, index, true)
            end
        end
        , false, 0, false)
        minusLayer:setTouchEnabled(true)
    end
end

function MercenaryUpgradeStarPage:deletLongClickLayer(container)
    local menuImage
    for i = 1, 4 do
        menuImage = container:getVarMenuItemImage("mStoneFeet0" .. i)
        if menuImage:getChildByTag(1)  then 
            menuImage:removeChildByTag(1, true)
        end
    end
end

function MercenaryUpgradeStarPage:onTouchBegin(container, eventName, pTouch, index, _isMinus)
    local layer = container:getVarMenuItemImage(_isMinus and "mMinusMenu0" .. index or "mStoneFeet0" .. index):getChildByTag(1)
    local rect = GameConst:getInstance():boundingBox(layer)
    local point = layer:convertToNodeSpace(pTouch:getLocation())
    if GameConst:getInstance():isContainsPoint(rect, point) then
        selectLongClickIndex = index
        timeCount = 0
        timeInterval = 5
        isMinus = _isMinus
        return true
    end
    return false 
end

function MercenaryUpgradeStarPage:onExecute(container)
    if selectLongClickIndex ~= 0 then
        local maxNum = self.MaxItemCount(selectLongClickIndex)
        local dt = GamePrecedure:getInstance():getFrameTime()
      
        timeCount = timeCount + dt
        if timeCount > 1 / timeInterval then
            holdTime = holdTime + 1
            timeInterval = math.min(timeInterval + 1, maxTimeInterval)
            timeCount = 0
            if holdTime < 10 then
            addNum = holdAddNum[1]--1
            elseif holdTime <= 20 then
            addNum = addNum + holdAddNum[2]--1         
            else
            addNum = addNum+holdAddNum[3]--1
            end
           
            if isMinus then
                addNum = addNum * -1
            end
            if addSum < maxNum then addSum=addSum+addNum end
            if addSum >= maxNum then 
                addNum = maxNum - (addSum - addNum)
                addSum = 0
            end

            local maxNum = self.MaxItemCount(selectLongClickIndex)
            if addNum > maxNum then addNum = maxNum end
            local count = UserItemManager:getCountByItemId(costItem[selectLongClickIndex])
            if not isMinus and count >= selectItemCount[costItem[selectLongClickIndex]] + addNum then
                self:addSelectItem(container, costItem[selectLongClickIndex], addNum)
            elseif isMinus and selectItemCount[costItem[selectLongClickIndex]] > 0 then
                self:addSelectItem(container, costItem[selectLongClickIndex], math.max(-1 * selectItemCount[costItem[selectLongClickIndex]], addNum))
            else
                selectLongClickIndex = 0
                timeCount = 0
                timeInterval = 1
                holdTime = 0
               --self:openstore()             
            end
        end
    end
end

function MercenaryUpgradeStarPage:onTouchMove(container, eventName, pTouch, index, _isMinus)
    -- body
end

function MercenaryUpgradeStarPage:onTouchEnd(container, eventName, pTouch, index, _isMinus)
    selectLongClickIndex = 0
    timeCount = 0
    timeInterval = 1
    isMinus = _isMinus
    holdTime = 0
end

function MercenaryUpgradeStarPage:onTouchCancel(container, eventName, pTouch, index, _isMinus)
    selectLongClickIndex = 0
    timeCount = 0
    timeInterval = 1
    isMinus = _isMinus
    holdTime = 0
end

function MercenaryUpgradeStarPage:showAttributeInfo(container)
    require("Battle.NewBattleUtil")
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
    local heroCfg = ConfigManager.getNewHeroCfg()[roleTable.sex * 100 + roleTable.class]

    local freeTypeStr = _lastStarLevel > info.level and "MecenaryUpStepFormat" or "MecenaryUpStepFormat1"

    local mStrNumParas = { [1] = heroCfg.Str + (heroCfg.LvPoint * (math.max(info.level - 1, 0))) * heroCfg.StrRate / 100, [2] = (heroCfg.LvPoint * (math.max(_lastStarLevel - info.level, 0))) * heroCfg.StrRate / 100 }
    local mDexNumParas = { [1] = heroCfg.Agi + (heroCfg.LvPoint * (math.max(info.level - 1, 0))) * heroCfg.AgiRate / 100, [2] = (heroCfg.LvPoint * (math.max(_lastStarLevel - info.level, 0))) * heroCfg.AgiRate / 100 }
    local mIntNumParas = { [1] = heroCfg.Int + (heroCfg.LvPoint * (math.max(info.level - 1, 0))) * heroCfg.IntRate / 100, [2] = (heroCfg.LvPoint * (math.max(_lastStarLevel - info.level, 0))) * heroCfg.IntRate / 100 }
    local mStaNumParas = { [1] = heroCfg.Sta + (heroCfg.LvPoint * (math.max(info.level - 1, 0))) * heroCfg.StaRate / 100, [2] = (heroCfg.LvPoint * (math.max(_lastStarLevel - info.level, 0))) * heroCfg.StaRate / 100 }
    local mHitNumParas = { [1] = NewBattleUtil:calHitValue(mStrNumParas[1], mIntNumParas[1], mDexNumParas[1]), [2] = NewBattleUtil:calHitValue(mStrNumParas[2], mIntNumParas[2], mDexNumParas[2]) }
    local mDodNumParas = { [1] = NewBattleUtil:calDodgeValue(mStrNumParas[1], mIntNumParas[1], mDexNumParas[1], mStaNumParas[1]), [2] = NewBattleUtil:calDodgeValue(mStrNumParas[2], mIntNumParas[2], mDexNumParas[2], mStaNumParas[2]) }
    local mCriNumParas = { [1] = NewBattleUtil:calCriValue(mDexNumParas[1]), [2] = NewBattleUtil:calCriValue(mDexNumParas[2]) }
    local mHpNumParas = { [1] = NewBattleUtil:calAttrHp(mStaNumParas[1]), [2] = NewBattleUtil:calAttrHp(mStaNumParas[2]) }
    local strMap = {
        mStrNum = common:fillHtmlStr(freeTypeStr, mStrNumParas[1], mStrNumParas[2]),
        mDexNum = common:fillHtmlStr(freeTypeStr, mDexNumParas[1], mDexNumParas[2]),
        mIntNum = common:fillHtmlStr(freeTypeStr, mIntNumParas[1], mIntNumParas[2]),
        mStaNum = common:fillHtmlStr(freeTypeStr, mStaNumParas[1], mStaNumParas[2]),
        mHitNum = common:fillHtmlStr(freeTypeStr, mHitNumParas[1], mHitNumParas[2]),
        mDodNum = common:fillHtmlStr(freeTypeStr, mDodNumParas[1], mDodNumParas[2]),
        mCriNum = common:fillHtmlStr(freeTypeStr, mCriNumParas[1], mCriNumParas[2]),
        mHpNum = common:fillHtmlStr(freeTypeStr, mHpNumParas[1], mHpNumParas[2]),
    }
    for nodestr, str in pairs(strMap) do
		node = container:getVarNode(nodestr)
		if node ~= nil then
			NodeHelper:addHtmlLable(node, str, GameConfig.Tag.HtmlLable, CCSize(300, 100))
		end	
	end
    -- 突破階級顯示
    stageLevel = info.starLevel
    for i = 1, 5 do
        NodeHelper:setNodesVisible(container, { ["mStageImg" .. i] = (stageLevel >= i) })
    end
end
function MercenaryUpgradeStarPage:showBasicInfo(container)   
    local lb2ColorMap = {}
    local sprite2Img = {}
    local lb2Str = {}

    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]

    local itemCfg = ConfigManager.getItemCfg()
    local heroExp = info.exp
    local addExp = 0
    --消耗訊息
    for i = 1, #costItem do
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(30000, costItem[i], 1)
        local userItemInfo = UserItemManager:getUserItemByItemId(costItem[i])
        if userItemInfo then
            lb2Str["mStoneNum0" .. i] = selectItemCount[costItem[i]] .. "/" .. userItemInfo.count
        else
            lb2Str["mStoneNum0" .. i] = "0/0"
        end
        lb2Str["mStoneName0" .. i] = resInfo.name    
        local itemName = "mStoneFeet0" .. i
        local minusName = "mMinusMenu0" .. i
        sprite2Img["mStonePic0" .. i] = resInfo.icon
        local colorStr = "98 81 65"--ConfigManager.getQualityColor()[resInfo.quality].textColor -- rgb => 98, 81, 65
        lb2ColorMap["mStoneName0" .. i] = colorStr
       
        NodeHelper:setMenuItemQuality(container, itemName, resInfo.quality)

        if i == selectLongClickIndex then
          local map = {}
          map[itemName] = not isMinus and i == selectLongClickIndex
          --map[minusName] = isMinus and i == selectLongClickIndex
          NodeHelper:setMenuItemSelected(container, map)
        end

        if itemCfg[costItem[i]] then
            addExp = addExp + selectItemCount[costItem[i]] * itemCfg[costItem[i]].soulStoneExp
        end
    end
    --計算經驗顯示
    heroExp = heroExp + addExp
    for i = info.level, #curStarInfos do
        if curStarInfos[i + 1] then --未滿級
            if heroExp >= curStarInfos[i + 1].exp then  --可升等
                heroExp = heroExp - curStarInfos[i + 1].exp
                _lastStarLevel = i + 1
            else    --等級不變
                _lastStarLevel = i
                lb2Str["mExperienceValue"] = heroExp .. "/" .. curStarInfos[i + 1].exp
                local curPercent = heroExp / curStarInfos[i + 1].exp
                if curPercent > 1.0 then curPercent = 1.0 end
                local barNode = container:getVarScale9Sprite("mBar")
                barNode:setScaleX(curPercent)
                isMaxLevel = false
                break
            end
        else    --已滿級 
            _lastStarLevel = i
            lb2Str["mExperienceValue"] = curStarInfos[i].exp .. "/" .. curStarInfos[i].exp
            local barNode = container:getVarScale9Sprite("mBar")
            barNode:setScaleX(1)
            isMaxLevel = true
            break
        end
    end

    local str = common:fillHtmlStr("MecenaryLevelUpFormat", info.level, _lastStarLevel > info.level and "+" .. _lastStarLevel - info.level or "")
    node = container:getVarNode("mMercenaryLv")
	if node ~= nil then
		NodeHelper:addHtmlLable(node, str, GameConfig.Tag.HtmlLable, CCSize(700, 100))
	end	

    NodeHelper:setColorForLabel(container, lb2ColorMap)
	NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setStringForLabel(container, lb2Str)
    for i = 1, #costItem do
        container:getVarLabelTTF("mStoneName0" .. i):setDimensions(CCSizeMake(100, 100))
        container:getVarNode("mMinusNode" .. i):setOpacity(selectItemCount[costItem[i]] > 0 and 255 or 0)
    end
end
function MercenaryUpgradeStarPage:showPlayerHead(container)
    local NewHeadIconItem = require("NewHeadIconItem")
    local parentNode = container:getVarNode("mHeadNode")
    local head = NewHeadIconItem:create(_curMercenaryId, parentNode)
    head:visibleIconInfo({ mMarkFighting = false, mMarkChoose = false, mMarkSelling = false, mMask = false, mLv = false, mSelectFrame = false })
end
function MercenaryUpgradeStarPage:showBreakHead(container)
    local NewHeadIconItem = require("NewHeadIconItem")
    local parentNode = container:getVarNode("mBreakHeadNode")
    if MercenaryUpgradeStagePage._selectMercenaryInfo then
        local head = NewHeadIconItem:create(MercenaryUpgradeStagePage._selectMercenaryInfo.itemId, parentNode)
        head:visibleIconInfo({ mMarkFighting = false, mMarkChoose = false, mMarkSelling = false, mMask = false, mSelectFrame = false })
    else
        parentNode:removeAllChildrenWithCleanup(true)
    end
end
function MercenaryUpgradeStarPage:showUiType(container)
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
    local isEnhance = info.level < roleTable.star * 20 - 10 + 2 * stageLevel
    local isMax = (info.level == roleTable.star * 20 - 10 + 2 * stageLevel) and (stageLevel == 5)
    NodeHelper:setNodesVisible(container, { mBreakNode = not isEnhance and not isMax, mEnhanceNode = isEnhance and not isMax, mMaxNode = isMax })
end

function MercenaryUpgradeStarPage:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function MercenaryUpgradeStarPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARY_UPSTAR)
end

function MercenaryUpgradeStarPage:onReceiveMessage(ParentContainer)
    local message = ParentContainer:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_POPPAGE then
        local pageName = MsgMainFramePopPage:getTrueType(message).pageName;
        if pageName ~= thisPageName then
            self:refreshPage(_selfContainer)
        end
    end
end
function MercenaryUpgradeStarPage:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
--回包处理
function MercenaryUpgradeStarPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.ROLE_INC_STAR_EXP_S then
        local msg = RoleOpr_pb.HPRoleUpStarCritInfo()
        msg:ParseFromString(msgBuff)
        --清空已選擇資料
        for i = 1, #costItem do
            selectItemCount[costItem[i]] = 0
        end
        UserInfo.sync()
        self:refreshPage(container)
    elseif opcode == opcodes.ROLE_UPGRADE_STAGE_S then
        local mInfo = UserMercenaryManager:getUserMercenaryInfos()
        local info = mInfo[_curMercenaryInfo.roleId]
        local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
        local curLevel = roleTable.star * 20 - 10 + 2 * (info.starLevel - 1)
        local newLevel = roleTable.star * 20 - 10 + 2 * info.starLevel
        MessageBoxPage:Msg_Box_Html(common:fill(FreeTypeConfig[10100].content, curLevel, newLevel))
        self:createCfgTable(container)
        self:refreshPage(container)
    elseif opcode == opcodes.ROLE_EMPLOY_S then
        self:refreshPage(container)
    end
end
function MercenaryUpgradeStarPage:onExit(container)
	self:removePacket(container)
    self:deletLongClickLayer(container)
    self:clearData(container)
    local EquipMercenaryPage = require("EquipMercenaryPage")
    EquipMercenaryPage:refreshPage(EquipMercenaryPage.container)
end
function MercenaryUpgradeStarPage:onClickItem(container, eventName)
    local index = tonumber(string.sub(eventName, -1))
    local count = UserItemManager:getCountByItemId(costItem[index])
    if count >= selectItemCount[costItem[index]] + 1 then
        self:addSelectItem(container, costItem[index], 1)
    end
end
function MercenaryUpgradeStarPage_onGuideClickItem(container, eventName)
    MercenaryUpgradeStarPage:onClickItem(container, eventName)
end
function MercenaryUpgradeStarPage:onClickMinus(container, eventName)
    local index = tonumber(string.sub(eventName, -1))
    if selectItemCount[costItem[index]] > 0 then
        self:addSelectItem(container, costItem[index], -1)
    end
end
function MercenaryUpgradeStarPage:addSelectItem(container, itemId, addNum)
    if isMaxLevel and addNum > 0 then
        return
    end
    if selectItemCount[itemId] then
        selectItemCount[itemId] = selectItemCount[itemId] + addNum
        if selectLongClickIndex ~= 0 then
            local maxNum=self.MaxItemCount(selectLongClickIndex)
            if selectItemCount[itemId]>maxNum then selectItemCount[itemId]=maxNum end
        end
        self:refreshPage(container)
    end
end
function MercenaryUpgradeStarPage:onConfirm(container)
    local itemId = ""
    local totleCount = 0
    for i = 1, #costItem do
        if selectItemCount[costItem[i]] > 0 then
            itemId = itemId .. costItem[i] .. "_" .. selectItemCount[costItem[i]] .. ","
        end
    end
    if itemId == "" then
        return
    else
        itemId = string.sub(itemId, 1, string.len(itemId) - 1)
    end
    local msg = Player_pb.HPRoleIncStarExp()
	msg.roleId = _curMercenaryInfo.roleId	
    msg.itemId = itemId
	common:sendPacket(HP_pb.ROLE_INC_STAR_EXP_C, msg ,false)
end
function MercenaryUpgradeStarPage_onGuideConfirm(container)
    MercenaryUpgradeStarPage:onConfirm(container)
end
function MercenaryUpgradeStarPage:onAuto(container)
    local needExp = 0
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    local heroExp = info.exp
    for i = info.level + 1, #curStarInfos do
        needExp = needExp + curStarInfos[i].exp
    end
    needExp = math.max(needExp - heroExp, 0)
    --清空已選擇資料
    for i = 1, #costItem do
        selectItemCount[costItem[i]] = 0
    end

    local itemCfg = ConfigManager.getItemCfg()
    for i = 1, #costItem do
        if i ~= 4 then  -- 104001不可強化
            local trueIdx = #costItem - (i - 1)
            if itemCfg[costItem[trueIdx]] then
                local count = UserItemManager:getCountByItemId(costItem[trueIdx])
                local addExp = count * itemCfg[costItem[trueIdx]].soulStoneExp
                if needExp <= addExp then
                    selectItemCount[costItem[trueIdx]] = math.ceil(needExp / itemCfg[costItem[trueIdx]].soulStoneExp)
                    break
                else
                    selectItemCount[costItem[trueIdx]] = count
                    needExp = needExp - addExp
                end
            end
        end
    end
    self:refreshPage(container)
end

function MercenaryUpgradeStarPage:onHead1(container)
    MercenaryUpgradeStagePage:setCurMercenaryId(_curMercenaryInfo.roleId)
    PageManager.pushPage("MercenaryUpgradeStagePage")
end
function MercenaryUpgradeStarPage:onBreakConfirm(container) 
    if MercenaryUpgradeStagePage._selectMercenaryId then
        local msg = Player_pb.HPRoleUpStage()
        msg.roleId = _curMercenaryInfo.roleId
        msg.retinueId = MercenaryUpgradeStagePage._selectMercenaryId
        MercenaryUpgradeStagePage._selectMercenaryId = nil
        MercenaryUpgradeStagePage._selectMercenaryInfo = nil
	    common:sendPacket(HP_pb.ROLE_UPGRADE_STAGE_C, msg ,false)
    else
        MessageBoxPage:Msg_Box_Lan("@HeroInput")
    end
end

function MercenaryUpgradeStarPage:MaxItemCount()
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local info = mInfo[_curMercenaryInfo.roleId]
    local needExp = 0
    local heroExp = info.exp
    for i = info.level, #curStarInfos do
         needExp = needExp + curStarInfos[i].exp
    end
    needExp = math.max(needExp - heroExp, 0)
    local itemCfg = ConfigManager.getItemCfg()
    local Exp = itemCfg[costItem[selectLongClickIndex]].soulStoneExp
    local Num = math.ceil(tonumber(needExp) / tonumber(Exp))
    
    return Num
end

function MercenaryUpgradeStarPage:refreshPage(container)
    self:showBasicInfo(container)
    self:showAttributeInfo(container)
    self:showPlayerHead(container)
    self:showBreakHead(container)
    self:showUiType(container)
end
function MercenaryUpgradeStarPage:onClose(container)
    MercenaryUpgradeStagePage._selectMercenaryId = nil
    MercenaryUpgradeStagePage._selectMercenaryInfo = nil
    container:removeMessage(MSG_MAINFRAME_POPPAGE)
    PageManager.popPage(thisPageName)
end
function MercenaryUpgradeStarPage:setMercenaryId(id)
    _curMercenaryId = id
end

function MercenaryUpgradeStarPage:openstore()
    MessageBoxPage:Msg_Box_Lan("@LackItem")
    --require("WelfarePage")
    --WelfarePage_setPart(94)
    --
    --PageManager.pushPage("WelfarePage")
end

function MercenaryUpgradeStarPage:clearData()
    for i = 1, #costItem do
        selectItemCount[costItem[i]] = 0
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
MercenaryUpgradeStarPage = CommonPage.newSub(MercenaryUpgradeStarPage, thisPageName, option)

return MercenaryUpgradeStarPage