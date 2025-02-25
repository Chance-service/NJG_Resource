----------------------------------------------------------------------------------
-- 符文合成
----------------------------------------------------------------------------------

local HP_pb           = require("HP_pb")
local Badge_pb        = require("Badge_pb")
local UserInfo        = require("PlayerInfo.UserInfo")
local FateDataManager = require("FateDataManager")
local NodeHelper      = require("NodeHelper")
local PBHelper        = require("PBHelper")
local EquipOprHelper  = require("Equip.EquipOprHelper")
local ItemManager     = require("Item.ItemManager")

local thisPageName    = "RunePage"

local opcodes = {
    BADGE_FUSION_C = HP_pb.BADGE_FUSION_C,
    BADGE_FUSION_S = HP_pb.BADGE_FUSION_S,
    ERROR_CODE_S   = HP_pb.ERROR_CODE,
}

local RUNE_ITEM_NUM = 5

local option = {
    ccbiFile = "RefiningPopUp.ccbi",
    handlerMap = {
        onHelp        = "showHelp",
        onClose       = "onClose",
        onAddAll      = "onAddAll",
        onForge       = "onForge",
        onSkillDetail = "onSkillDetail",
        onHand        = "goSelectEquip", -- 點擊符文格時進入符文選擇頁
    },
    opcode = opcodes,
}

local RunePageBase = { ccbiFile = "RefiningPopUp.ccbi" }

-- 模組內使用的局部變數
local items, spines, selectInfos = {}, {}, {}
local btnLock       = false
local mParentContainer = nil
local selfContainer = nil
local batchMeltreFiningValue = 0
local meltreFiningValue = 0

------------------------------------------------------------
-- RuneItem 模組：符文物件的建立與刷新
------------------------------------------------------------
local RuneItem = { ccbiFile = "EquipmentItem_Rune.ccbi" }
function RuneItem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function RuneItem:refresh(container)
    local emptyImg = "UI/Mask/Image_Empty.png"
    NodeHelper:setNodesVisible(container, { mCheckNode = false, mStarNode = false })
    NodeHelper:setSpriteImage(container, {
        mPic         = emptyImg,
        mFrameShade  = emptyImg,
        mFrame       = emptyImg,
    })
end
-- 點擊符文格事件處理（統一由 onHand 處理，直接跳轉至符文選擇頁）
function RuneItem.onFunction(eventName, container)
    if eventName == "onHand" then
        PageManager.pushPage("RuneBuildSelectPage")
    end
end

------------------------------------------------------------
-- RuneAttrItem 模組：顯示符文屬性資訊的 Cell
------------------------------------------------------------
local RuneAttrItem = { ccbiFile = "RefiningPopUpContent.ccbi" }
function RuneAttrItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local attrId, attrNum = unpack(common:split(self.Info, "_"))
    local attrName = common:getLanguageString("@Combatattr_"..attrId)
    NodeHelper:setSpriteImage(container, { mAttrImg1 = "attri_" .. attrId .. ".png" })
    NodeHelper:setStringForLabel(container, { mAttrTxt1 = ("+" .. attrNum), mTxt = attrName })
end

-- 建立屬性 Cell 的共用函數
function RunePageBase:CreateCell(attrInfo)
    local cell = CCBFileCell:create()
    cell:setCCBFile(RuneAttrItem.ccbiFile)
    local panel = common:new({ Info = attrInfo }, RuneAttrItem)
    cell:registerFunctionHandler(panel)
    return cell
end

------------------------------------------------------------
-- UI 初始化函數
------------------------------------------------------------
function RunePageBase:initRuneItems(container)
    items = {}
    for i = 1, RUNE_ITEM_NUM do
        local itemNode = ScriptContentBase:create(RuneItem.ccbiFile)
        local parentNode = container:getVarNode("mRuneNode" .. i)
        itemNode:registerFunctionHandler(RuneItem.onFunction)
        itemNode:setAnchorPoint(ccp(0.5, 0.5))
        parentNode:removeAllChildren()
        RuneItem:refresh(itemNode)
        parentNode:addChild(itemNode)
        table.insert(items, itemNode)
    end
end

function RunePageBase:initSpines(container)
    spines = {}
    for i = 1, RUNE_ITEM_NUM do
        local parentNode = container:getVarNode("mSpineNode" .. i)
        local spine = SpineContainer:create("NGUI", "NGUI_17_RuneSelect")
        parentNode:addChild(tolua.cast(spine, "CCNode"))
        table.insert(spines, spine)
    end
    -- 加入合成專用的 Spine 動畫
    local parentNode = container:getVarNode("mSpineNode6")
    local spine = SpineContainer:create("NGUI", "NGUI_18_RuneForge")
    parentNode:addChild(tolua.cast(spine, "CCNode"))
    table.insert(spines, spine)
end

function RunePageBase:resetTopNodePos(container)
    local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local offsetY = math.max(visibleSize.height - GameConfig.ScreenSize.height, 0)
    local node = container:getVarNode("mSkillDetailNode")
    node:setPositionY(offsetY)
end

-- 更新玩家資訊（金幣、鑽石）
function RunePageBase:updateUserInfo(container)
    local coinStr    = GameUtil:formatNumber(UserInfo.playerInfo.coin)
    local diamondStr = GameUtil:formatNumber(UserInfo.playerInfo.gold)
    NodeHelper:setStringForLabel(mParentContainer, { mCoin = coinStr, mDiamond = diamondStr })
end

------------------------------------------------------------
-- 選中符文更新與屬性資訊顯示
------------------------------------------------------------
function RunePageBase_setSelectInfo(infos)
    local newSelectInfo = {}
    for i = 1, #infos do
        if (not selectInfos[i] or selectInfos[i].itemId <= 0) and (infos[i] and infos[i].itemId > 0) then
            newSelectInfo[i] = true
        else
            newSelectInfo[i] = false
        end
    end
    selectInfos = {}
    for i = 1, #infos do
        selectInfos[i] = infos[i]
    end
    -- 更新符文格顯示
    for i = 1, #items do
        if selectInfos[i] then
            local cfg = ConfigManager.getFateDressCfg()[selectInfos[i].itemId]
            local iconBgSprite = NodeHelper:getImageBgByQuality(cfg.rare)
            NodeHelper:setNodesVisible(items[i], { mStarNode = true })
            for star = 1, 6 do
                NodeHelper:setNodesVisible(items[i], { ["mStar" .. star] = (star == cfg.star) })
            end
            NodeHelper:setSpriteImage(items[i], {
                mPic         = cfg.icon,
                mFrameShade  = iconBgSprite,
                mFrame       = GameConfig.QualityImage[cfg.rare],
            })
        else
            local emptyImg = "UI/Mask/Image_Empty.png"
            NodeHelper:setNodesVisible(items[i], { mStarNode = false })
            NodeHelper:setSpriteImage(items[i], {
                mPic         = emptyImg,
                mFrameShade  = emptyImg,
                mFrame       = emptyImg,
            })
        end
    end
    -- 當選中數量達到上限，更新右側詳情面板資訊
    if #selectInfos == RUNE_ITEM_NUM then
        NodeHelper:setNodesVisible(selfContainer, { mRuneNode6 = true })
        local conf = ConfigManager.getFateDressCfg()[selectInfos[1]:getConf().afterId or 1] 
                     or ConfigManager.getFateDressCfg()[selectInfos[1].itemId]
        if conf then
            if conf.slot > 0 then
                NodeHelper:setStringForLabel(selfContainer, { mSkillTxt = common:getLanguageString("@unknowRefine") })
            else
                NodeHelper:setStringForLabel(selfContainer, { mSkillTxt = common:getLanguageString("@EquipStr7") })
            end
            for star = 1, 6 do
                NodeHelper:setNodesVisible(selfContainer, { ["mStar" .. star] = (star == conf.star) })
            end
            NodeHelper:setSpriteImage(selfContainer, {
                mMiddlePic = "Rune_" .. conf.rank .. ".png",
                mMiddleBg  = NodeHelper:getImageBgByQuality(conf.rare),
            })
            RunePageBase:buildAttrInfo(selfContainer, selectInfos)
        end
    else
        NodeHelper:setNodesVisible(selfContainer, { mRuneNode6 = false, mSkillNode = false })
        local mainScroll  = selfContainer:getVarScrollView("mMainAttr")
        local otherScroll = selfContainer:getVarScrollView("mOtherAttr")
        mainScroll:removeAllCell()
        otherScroll:removeAllCell()
    end
    -- 播放新選中符文對應的 Spine 動畫
    for i = 1, #newSelectInfo do
        if newSelectInfo[i] then
            spines[i]:runAnimation(1, "animation", 0)
        end
    end
end

-- 建立屬性資訊顯示（主屬性與其他屬性）
function RunePageBase:buildAttrInfo(container, runeList)
    local mainScroll  = container:getVarScrollView("mMainAttr")
    local otherScroll = container:getVarScrollView("mOtherAttr")
    mainScroll:removeAllCell()
    otherScroll:removeAllCell()
    local mainAttrs, otherAttrs = {}, {}
    for _, rune in pairs(runeList) do
        local conf = ConfigManager.getFateDressCfg()[rune:getConf().afterId or 1] or ConfigManager.getFateDressCfg()[rune.itemId]
        if conf then
            local basicAttrs = common:split(conf.basicAttr, ",")
            if basicAttrs[1] then
                table.insert(mainAttrs, basicAttrs[1])
            end
            local otherAttrList = common:split(conf.OtherAttr, ",")
            for _, v in pairs(otherAttrList) do
                table.insert(otherAttrs, v)
            end
        end
    end
    local function removeDuplicates(t)
        local seen, result = {}, {}
        for _, value in ipairs(t) do
            if not seen[value] then
                table.insert(result, value)
                seen[value] = true
            end
        end
        return result
    end
    mainAttrs  = removeDuplicates(mainAttrs)
    otherAttrs = removeDuplicates(otherAttrs)
    for _, info in ipairs(mainAttrs) do
        local cell = self:CreateCell(info)
        mainScroll:addCell(cell)
    end
    for _, info in ipairs(otherAttrs) do
        local cell = self:CreateCell(info)
        otherScroll:addCell(cell)
    end
    mainScroll:orderCCBFileCells()
    otherScroll:orderCCBFileCells()
    mainScroll:setTouchEnabled(false)
    otherScroll:setTouchEnabled(#otherAttrs > 4)
end

-- 清除所有選中資料與 UI 顯示
function RunePageBase:clearSelectInfo()
    selectInfos = {}
    for i = 1, #items do
        local emptyImg = "UI/Mask/Image_Empty.png"
        NodeHelper:setSpriteImage(items[i], {
            mPic         = emptyImg,
            mFrameShade  = emptyImg,
            mFrame       = emptyImg,
        })
        NodeHelper:setNodesVisible(items[i], { mStarNode = false })
    end
    NodeHelper:setNodesVisible(selfContainer, { mRuneNode6 = false })
    local mainScroll  = selfContainer:getVarScrollView("mMainAttr")
    local otherScroll = selfContainer:getVarScrollView("mOtherAttr")
    mainScroll:removeAllCell()
    otherScroll:removeAllCell()
    NodeHelper:setNodesVisible(selfContainer, { mSkillNode = false })
    NodeHelper:setStringForLabel(selfContainer, { mSkillTxt = "" })
end

------------------------------------------------------------
-- 事件處理函數
------------------------------------------------------------
function RunePageBase:onClose(container, eventName)
    PageManager.popPage(thisPageName)
end

function RunePageBase:onAddAll(container, eventName)
    local nonWearRuneTable = FateDataManager:getNotWearFateList()
    if #nonWearRuneTable <= 0 then return end

    table.sort(nonWearRuneTable, function(v1, v2)
        return v1:getConf().rank < v2:getConf().rank
    end)

    -- 根據不同 rank 分類，並尋找滿足合成條件的等級
    local tempInfo = {}
    for i = 1, #nonWearRuneTable do
        local conf = nonWearRuneTable[i]:getConf()
        if conf.afterId ~= -1 then
            tempInfo[conf.rank] = tempInfo[conf.rank] or {}
            table.insert(tempInfo[conf.rank], nonWearRuneTable[i])
        end
    end
    local tarLevel = 0
    for i = 1, 20 do 
        local count = 0
        for _,v in pairs (tempInfo[i]) do
            if v.lock == 0 then
                count = count + 1
            end
        end
        if count >= RUNE_ITEM_NUM then
            tarLevel = i
            break
        elseif count > 0 and tarLevel == 0 then
            tarLevel = i
        end
    end
    local finalInfo = {}
    if tempInfo[tarLevel] then
        for i = 1,  #tempInfo[tarLevel] do
            local info = tempInfo[tarLevel][i]
            if info.lock == 0 then
                table.insert(finalInfo,tempInfo[tarLevel][i])
            end
            if #finalInfo == RUNE_ITEM_NUM then break end
        end
    end
    if #finalInfo > 0 then
        RunePageBase_setSelectInfo(finalInfo)
    end
end

function RunePageBase:onForge(container, eventName)
    if #selectInfos < RUNE_ITEM_NUM then return end

    local hasSkill = false
    for i = 1, #selectInfos do
        if selectInfos[i].skill ~= 0 then
            hasSkill = true
            break
        end
    end

    local function sendFusionRequest()
        self:sendReq()
    end

    if hasSkill then
        local title   = common:getLanguageString("@HintTitle")
        local message = common:getLanguageString("@RuneSynthesisNotice")
        PageManager.showConfirm(title, message, function(isSure)
            if isSure then sendFusionRequest() end
        end)
    else
        sendFusionRequest()
    end
end

function RunePageBase:sendReq()
    local msg = Badge_pb.HPBadgeFusionReq()
    for i = 1, #selectInfos do
        if selectInfos[i] then
            msg.fusionIds:append(selectInfos[i].id)
        end
    end
    common:sendPacket(opcodes.BADGE_FUSION_C, msg)
end

function RunePageBase:onSkillDetail(container, eventName)
    PageManager.pushPage("RuneSkillPage")
end

------------------------------------------------------------
-- 封包與訊息處理
------------------------------------------------------------
function RunePageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.BADGE_FUSION_S then
        local msg = Badge_pb.HPBadgeFusionRet()
        msg:ParseFromString(msgBuff)
        local reward = msg.award

        local actArray = CCArray:create()
        actArray:addObject(CCCallFunc:create(function()
            spines[6]:runAnimation(1, "animation", 0)
        end))
        actArray:addObject(CCDelayTime:create(1.4))
        actArray:addObject(CCCallFunc:create(function()
            require("RuneInfoPage_Forge")
            RuneForgePage_setPageInfo(GameConfig.RuneInfoPageType.NON_EQUIPPED, tonumber(reward))
            PageManager.pushPage("RuneInfoPage_Forge")
            self:clearSelectInfo()
        end))
        container:runAction(CCSequence:create(actArray))
    end
end

function RunePageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            mParentContainer:registerPacket(opcode)
        end
    end
end

function RunePageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            mParentContainer:removePacket(opcode)
        end
    end
end

function RunePageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == thisPageName then
            self:refreshPage(container)
        end
    end
end

function RunePageBase:refreshPage(container)
    self:updateUserInfo(container)
    -- 其他需要刷新的部分可在此添加
end

------------------------------------------------------------
-- onFunction 統一事件分發器
------------------------------------------------------------
function RunePageBase.onFunction(eventName, container)
    if eventName == "onHelp" then
        RunePageBase:showHelp(container)
    elseif eventName == "onClose" then
        RunePageBase:onClose(container)
    elseif eventName == "onAddAll" then
        RunePageBase:onAddAll(container)
    elseif eventName == "onForge" then
        RunePageBase:onForge(container)
    elseif eventName == "onSkillDetail" then
        RunePageBase:onSkillDetail(container)
    elseif eventName == "onHand" then
        PageManager.pushPage("RuneBuildSelectPage")
    end
end

function RunePageBase:showHelp(container)
    -- 實作說明頁面或提示訊息
end

------------------------------------------------------------
-- 頁面生命週期入口與退出
------------------------------------------------------------
function RunePageBase:onEnter(ParentContainer)
    mParentContainer = ParentContainer
    self.container = ScriptContentBase:create(option.ccbiFile)
    self.container:registerFunctionHandler(RunePageBase.onFunction)
    selfContainer = self.container
    btnLock = false

    self:registerPacket(mParentContainer)
    mParentContainer:registerMessage(MSG_MAINFRAME_REFRESH)

    self:initRuneItems(self.container)
    self:initSpines(self.container)
    self:resetTopNodePos(self.container)
    self:refreshPage(self.container)

    NodeHelper:setNodesVisible(self.container, { mRuneNode6 = false })

    return self.container
end

function RunePageBase:onExit(container)
    selectInfos = {}
    batchMeltreFiningValue = 0
    meltreFiningValue = 0
    btnLock = false

    self:removePacket(mParentContainer)
    mParentContainer:removeMessage(MSG_MAINFRAME_REFRESH)
end

return RunePageBase
