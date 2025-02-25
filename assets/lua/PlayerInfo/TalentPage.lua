

local thisPageName = "TalentPage"
local HP_pb = require("HP_pb")
local TalentPageBase = {}
local TalentManager = require("PlayerInfo.TalentManager")
local TalentCfg = ConfigManager.getTalentCfg()
local UserInfo = require("PlayerInfo.UserInfo")
local NewbieGuideManager = require("Guide.NewbieGuideManager")
local option = {
    ccbiFile = "FigureReincarnationQiPage.ccbi",
    handlerMap = {
        onEmptyProperties   = "onClearTalent",
        onLight             = "onUpgrade",

        onReturn            = "onReturn"
    }
}

local TalentPageItem = {
    ccbiFile = "FigureReincarnationQiContent.ccbi"
}

-- 背景图
local BGSprite = {
    "UI/Element/u_ReincarnationBG1.png",
    "UI/Element/u_ReincarnationBG2.png",
    "UI/Element/u_ReincarnationBG3.png",
}
-- 点亮按钮图标
local LightBtnSprite = {
    "UI/Element/u_LightBtn01.png",
    "UI/Element/u_LightBtn02.png",
    "UI/Element/u_LightBtn03.png",
}
-- 线升级图片
local LineSprite = {
    "UI/Element/u_ReincarnationLine01.png",
    "UI/Element/u_ReincarnationLine02.png",
    "UI/Element/u_ReincarnationLine03.png",
}
-- 线未升级图片
local LineNormalSprite = "UI/Element/u_ReincarnationLine04.png"
-- 已升级按钮图片
local MenuSprite = {
    "UI/Element/u_ReincarnationStar01.png",
    "UI/Element/u_ReincarnationStar02.png",
    "UI/Element/u_ReincarnationStar03.png",
}
-- 未升级按钮图片
local MenuNormalSprite = {
    "UI/Element/u_ReincarnationStar04.png",
    "UI/Element/u_ReincarnationStar05.png",
    "UI/Element/u_ReincarnationStar06.png",
}

local currentInfo = {}
local curIndex = 0
local targetIndex = 0 
local targetLevel = 0

local COUNT_TALENT_INDEX = 10
local itemTb = {}

local thisOffset = nil

local contentSize = nil

local m_tMainContainer = nil
local m_nOneAniDelayTime = GamePrecedure:getInstance():getFrameTime()*6
local m_tAniTable = {
    [1] = {
        [1] = "FrozenTimeLineb",
        [2] = "FireTimeLineb",
        [3] = "ThunderTimeLineb",
    },
    [2] = {
        [1] = "FrozenTimeLinea",
        [2] = "FireTimeLinea",
        [3] = "ThunderTimeLinea",
    },
}
local TalentAniItem = {
    ccbiFile = "FigureReincarnationContent.ccbi"
}
local m_tAniContainer = nil -- 动画的container

function TalentPageItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        TalentPageItem.onRefreshItemView(container)
    elseif eventName == "onClick" then 
        TalentPageItem.chooseItem(container)
    end
end
function TalentPageItem.onRefreshItemView(container)
    local index = container:getItemDate().mID
    local info = TalentManager.ElementTalentInfo[index]
    local str1, str2 = TalentManager:getAttrNameByIdForSV(info.attrId, info.attrStage, info.attrValue)
    local levelStr = common:getLanguageString("@AttackLevelText",tostring(info.attrStage))
    local addStr = common:getLanguageString("@AttackAddContent",tostring(info.attrValue))
    if info ~= nil then
        local lb2str = {
            mAttributeName   = str1,
            mAttributeLv     = levelStr..common:getLanguageString("@MyLevel", info.attrLevel),
            mAttributeAddition   = addStr
        }

        NodeHelper:setStringForLabel(container, lb2str)
    end
    local temp = info.attrLevel % COUNT_TALENT_INDEX
    local quality = (info.attrLevel - temp) / COUNT_TALENT_INDEX + 1 
    NodeHelper:setColorForLabel(container,{
        mAttributeAddition = GameConfig.QualityColor[quality]
    })
    if TalentManager.curAttrId == info.attrId then
        NodeHelper:setMenuItemSelected(container, {mClickBtn = true})
    else
        NodeHelper:setMenuItemSelected(container, {mClickBtn = false})
    end
	NodeHelper:setLabelOneByOne(container,"mAttributeTypeLab","mAttributeAddition",3)
    table.insert(itemTb, container)
end

function TalentPageItem.chooseItem(container)
    local index = container:getItemDate().mID
    TalentManager.curAttrId = TalentManager.ElementTalentInfo[index].attrId
    TalentPageBase:checkItemSelected(index)
    
    PageManager.refreshPage(thisPageName,"refreshPage")
end
--------------------------------------------------------
function TalentAniItem.onFunction( eventName,container )
    if eventName:sub(1,8) == "onAddBtn" then
        TalentPageBase:onChooseBtn(container, eventName)
    end
end
---------------------------------------------------------
function TalentPageBase:onEnter(container)
    self:initUIs(container)
    m_tMainContainer = container
    NodeHelper:initScrollView(container, "mContent", 3)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    local pItem = ScriptContentBase:create(TalentPageItem.ccbiFile)
    contentSize = pItem:getContentSize()
    self:registerPacket(container)
    self:showNewBieGuide(container)

    -- ani content
    m_tAniContainer = ScriptContentBase:create(TalentAniItem.ccbiFile)
    m_tAniContainer:registerFunctionHandler(TalentAniItem.onFunction)
    local aniScroll = container:getVarScrollView("mScrollContent")
    if aniScroll~=nil then
        container:autoAdjustResizeScrollview(aniScroll)
    end
    aniScroll:setBounceable(false)
    aniScroll:getContainer():addChild(m_tAniContainer)
    aniScroll:setContentSize(m_tAniContainer:getContentSize())
    TalentManager:requestBasicInfo()
end

function TalentPageBase:onExit(container)
    self:removePacket(container)
    NodeHelper:deleteScrollView(container)	
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    TalentManager.curAttrId = 0
    thisOffset = nil
    itemTb = {}
end

-- 提示
function TalentPageBase:showNewBieGuide(container)
    if NewbieGuideManager.hasTip(GameConfig.NewbieGuide.FirstTalentUpdate) then
        NodeHelper:setNodesVisible(container, {mGuideNode = false})
    else
        NodeHelper:setNodesVisible(container, {mGuideNode = true})
    end
end

-- 进入时初始化各label
function TalentPageBase:initUIs(container)    
    local lb2str = {
        mAttributeTypeLab    = "",
        mAttributeAddition   = "",
        mCurrentQiPoint     = "",
        mLabel1             = "",
        mLabel2             = "",
    }
    NodeHelper:setStringForLabel(container, lb2str)
end

function TalentPageBase:refreshPage(container,isUpdate,fromLevel)
    self:resetChoose(container)
    self:refreshInfo(container,isUpdate,fromLevel)
    self:rebuildItem(container)
end

function TalentPageBase:onReturn(container)
    PageManager.changePage("EquipmentPage")
end

-- 检查选中Item
function TalentPageBase:checkItemSelected(index)
    for i = 1, 6 do
         NodeHelper:setMenuItemSelected(itemTb[i], {mClickBtn = false})
    end
    NodeHelper:setMenuItemSelected(itemTb[index],{mClickBtn = true})
end

function TalentPageBase:resetChoose(container)
    currentInfo = TalentManager:getTalentInfo(TalentManager.curAttrId)
    curIndex = currentInfo.attrLevel % COUNT_TALENT_INDEX
    targetIndex = curIndex + 1
    targetLevel = (currentInfo.attrStage - 1) * 50 + currentInfo.attrLevel + 1
end

function TalentPageBase:refreshBasicInfo( container )
    UserInfo.sync()
    currentInfo = TalentManager:getTalentInfo(TalentManager.curAttrId)
    local upgradeInfo = TalentManager:getUpgradeInfo(currentInfo.attrId, (currentInfo.attrStage - 1) * 50 + currentInfo.attrLevel, targetLevel, currentInfo.attrStage)
    local lb2str = {
        mAttributeTypeLab    = TalentManager:getAttrNameById(currentInfo.attrId),
        mAttributeAddition   = TalentManager:getAttrAddContent(currentInfo),
        mCurrentQiPoint     = UserInfo.playerInfo.talentNum,
        mLabel1             = upgradeInfo.attrValue,
        mLabel2             = upgradeInfo.addCost,
        mLabel4             = common:getLanguageString("@TalentFullLevel"),
        mTex                = common:getLanguageString("@TalentNumPerLevel", GameConfig.TalentNumPerLevel)
    }
    NodeHelper:setStringForLabel(container, lb2str)
	NodeHelper:setLabelOneByOne(container,"mCurrentQiTitle","mCurrentQiPoint",3)
   
    if tonumber(upgradeInfo.nAddCost) > UserInfo.playerInfo.talentNum then
        NodeHelper:setColorForLabel(container,{mLabel2=GameConfig.ColorMap.COLOR_RED}) 
    else
        NodeHelper:setColorForLabel(container,{mLabel2=GameConfig.ColorMap.COLOR_WHITE}) 
    end
    -- 清空属性按钮 是否可用
    local canClear = false
    if currentInfo.attrStage > 1 then
        canClear = true
    else
        if currentInfo.attrLevel > 0 then
            canClear = true
        else
            canClear = false
        end
    end
    NodeHelper:setMenuItemsEnabled(container,{mEmptyProperties = canClear})
    -- 背景图片
    NodeHelper:setSpriteImage(container, {mMainPageBg = BGSprite[upgradeInfo.ElementType]})
    -- 点击升级大按钮的图片
    -- NodeHelper:setNormalImages(container, {mLightBtn = LightBtnSprite[upgradeInfo.ElementType]})
    local ccbFileName = "FigureReincarnationBtnEffect0"..upgradeInfo.ElementType
    local ccbiNode = ScriptContentBase:create(ccbFileName)
    local midBtnNode = container:getVarNode("mLightBtn")
    midBtnNode:removeAllChildren()
    midBtnNode:addChild(ccbiNode)
    -- 满级不显示左下角伤害
    local nodesMap = {
        mLabelNode1  = targetLevel <= #TalentCfg,
        mLabelNode2  = targetLevel > #TalentCfg
    }
    NodeHelper:setNodesVisible(container, nodesMap)
    -- 先恢复所有星星默认图
    local starSpriteMap = {}
    for i=1,COUNT_TALENT_INDEX do
        starSpriteMap["mAddSprite" .. i] = MenuNormalSprite[upgradeInfo.ElementType]
        starSpriteMap["mAddSprite_" .. i] = MenuNormalSprite[upgradeInfo.ElementType]
    end
    NodeHelper:setSpriteImage(m_tAniContainer, starSpriteMap)
    -- 设置点击按钮的大星星图，upgradeInfo.AttrType为1是防御
    local menuEnable = {}
    if upgradeInfo.AttrType == 1 then
        for i = 1, COUNT_TALENT_INDEX do 
            menuEnable["mAddBtn_" .. i] = false
            if i <= curIndex then
                menuEnable["mAddBtn" .. i] = false
            else
                menuEnable["mAddBtn" .. i] = true
            end
        end
        NodeHelper:setSpriteImage(m_tAniContainer, 
            {["mAddSprite" .. targetIndex] = MenuSprite[upgradeInfo.ElementType]})
    elseif upgradeInfo.AttrType == 2 then
        for i = 1, COUNT_TALENT_INDEX do 
            menuEnable["mAddBtn" .. i] = false
            if i <= curIndex then
                menuEnable["mAddBtn_" .. i] = false
            else
                menuEnable["mAddBtn_" .. i] = true
            end
        end
        NodeHelper:setSpriteImage(m_tAniContainer, 
            {["mAddSprite_" .. targetIndex] = MenuSprite[upgradeInfo.ElementType]})
    end
    NodeHelper:setMenuItemsEnabled(m_tAniContainer,menuEnable)
end
local function _delayAni(container,attrType,elementType,fromLevel,toLevel)
    if tonumber(fromLevel)>=toLevel then return end
    local fromNum = fromLevel+1
    if fromNum<10 then
        fromNum = "0"..fromNum
    end
    local aniName = m_tAniTable[attrType][elementType]..fromNum
    container:runAnimation(aniName)

    local array = CCArray:create()
    array:addObject(CCDelayTime:create(m_nOneAniDelayTime))
    array:addObject(CCCallFunc:create(function()
        _delayAni(container,attrType,elementType,fromNum,toLevel)
    end))
    container:runAction(CCSequence:create(array))
end
function _showNoTouch( container,noTouchTimes )
    local array = CCArray:create()
    array:addObject(CCCallFunc:create(function()
        MainFrame:getInstance():showNoTouch()    
    end))
    array:addObject(CCDelayTime:create(noTouchTimes*m_nOneAniDelayTime))
    array:addObject(CCCallFunc:create(function()
        MainFrame:getInstance():hideNoTouch()
    end))
    container:runAction(CCSequence:create(array))
end
function TalentPageBase:refreshAni(container,attrType,elementType,fromLevel,toLevel,isFromUpdate)
    local noTouchNums = 0
    local tempToLevel = toLevel
    if (currentInfo.attrStage>1 or currentInfo.attrLevel / COUNT_TALENT_INDEX ~= 0) and toLevel==0 then
        tempToLevel = 10
    end
    -- 升级动画，要按顺序播。
    if isFromUpdate then
        _delayAni(container,attrType,elementType,fromLevel,tempToLevel)
        noTouchNums = tempToLevel - fromLevel
    -- 进入页面动画，只播一个
    else
        tempToLevel = toLevel
        if tempToLevel<10 then
            tempToLevel = "0"..tempToLevel
        end
        local aniName = m_tAniTable[attrType][elementType]..tempToLevel
        container:runAnimation(aniName)
        noTouchNums = 1
    end
    _showNoTouch(container,noTouchNums)
end
-- 当前属性信息
function TalentPageBase:refreshInfo(container,isUpdate,fromLevel)
    local upgradeInfo = TalentManager:getUpgradeInfo(currentInfo.attrId, (currentInfo.attrStage - 1) * 50 + currentInfo.attrLevel, targetLevel, currentInfo.attrStage)
    self:refreshBasicInfo(container)
    if  isUpdate and fromLevel then
        self:refreshAni(m_tAniContainer,upgradeInfo.AttrType,upgradeInfo.ElementType,fromLevel,currentInfo.attrLevel%COUNT_TALENT_INDEX,true)
    else
        self:refreshAni(m_tAniContainer,upgradeInfo.AttrType,upgradeInfo.ElementType,nil,currentInfo.attrLevel%COUNT_TALENT_INDEX,false)
    end
end

-- 选中目标Level
function TalentPageBase:onChooseBtn(container, eventName)
    local index = tonumber(string.sub(eventName, 9))
    local curLevel = (currentInfo.attrStage - 1) * 50 + currentInfo.attrLevel 
    targetIndex = index
    targetLevel = targetIndex - curIndex + curLevel
    PageManager.refreshPage(thisPageName)   
end

function TalentPageBase:rebuildItem(container)
    self:clearAllItem(container)
	self:buildItem(container)
end

function TalentPageBase:clearAllItem(container)
	NodeHelper:clearScrollView(container);
    itemTb = {}
end

function TalentPageBase:buildItem(container)
    local size = 6
    NodeHelper:buildScrollViewHorizontal(container, size, TalentPageItem.ccbiFile, TalentPageItem.onFunction, 0)
    container.mScrollView:setTouchEnabled(false)
    --NodeHelper:createTouchLayerByScrollView(container)
--    if thisOffset then
--        container.mScrollView:setContentOffset(thisOffset)
--    end
end

function TalentPageBase:onLeft(container)
    container.mScrollView:setContentOffset(ccp(0,0), true)
end

function TalentPageBase:onRight(container)
    container.mScrollView:setContentOffset(ccp((contentSize.width + 20) * -4, 0), true)
end

-- 点亮操作
function TalentPageBase:onUpgrade(container)
    --UserInfo.sync()
    --local roleLevel = UserInfo.roleInfo.level
    --if roleLevel - 90 >= targetLevel then
    NewbieGuideManager.rebirthGuide(GameConfig.NewbieGuide.FirstTalentUpdate)
    TalentManager:upgradeTalent(currentInfo.attrId, (currentInfo.attrStage - 1) * 50 + currentInfo.attrLevel, targetLevel)
    --else
        --MessageBoxPage:Msg_Box_Lan("@TalentLevelNotEnough")
    --end
    thisOffset = container.mScrollView:getContentOffset()
end

-- 清空属性
function TalentPageBase:onClearTalent(container)
    local title = common:getLanguageString("@ClearTalentTitle")
    local attrId = currentInfo.attrId
    local attrName = TalentManager:getAttrNameById(attrId)
    local msg = common:getLanguageString("@ClearTalentContent", GameConfig.ClearTalentCost, attrName)

    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            if UserInfo.isGoldEnough(GameConfig.ClearTalentCost) then
                TalentManager:clearTalent(attrId)
                thisOffset = container.mScrollView:getContentOffset()
            end
        end
    end)
    
end

function TalentPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.TALENT_ELEMENT_INFO_S then
        local msg = Talent_pb:HPPlayerTalentInfoRet()
        msg:ParseFromString(msgBuff)
        TalentManager:receiveTalentInfo(msg)
        self:refreshPage(container)

    elseif opcode == HP_pb.TALENT_UPGRAGE_TALENT_S then
        local msg = Talent_pb:HPUpgradeTalentRet()
        msg:ParseFromString(msgBuff)
        TalentManager:receiveUpgradeTalent(msg)
        local fromLevel = curIndex
        self:refreshPage(container,true,fromLevel)

    elseif opcode == HP_pb.TALENT_ELEMENT_CLEAR_S then
        local msg = Talent_pb:HPClearTalentRet()
        msg:ParseFromString(msgBuff)
        TalentManager:receiveClearTalent(msg)
        self:refreshPage(container)
    end
end

function TalentPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName then
            if extraParam == "refreshPage" then
                self:refreshPage(container)
            else 
                self:refreshBasicInfo(container)
                self:rebuildItem(container)
            end
        end
    end
end 

function TalentPageBase:registerPacket(container)
    container:registerPacket(HP_pb.TALENT_ELEMENT_INFO_S)
    container:registerPacket(HP_pb.TALENT_UPGRAGE_TALENT_S)
    container:registerPacket(HP_pb.TALENT_ELEMENT_CLEAR_S)
end

function TalentPageBase:removePacket(container)
    container:removePacket(HP_pb.TALENT_ELEMENT_INFO_S)
    container:removePacket(HP_pb.TALENT_UPGRAGE_TALENT_S)
    container:removePacket(HP_pb.TALENT_ELEMENT_CLEAR_S)
end 

---------------------------------------------------------
local CommonPage = require("CommonPage");
local TalentPage = CommonPage.newSub(TalentPageBase, thisPageName, option);
