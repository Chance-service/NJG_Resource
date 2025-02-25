local thisPageName = "NgBattleDetailTestPage"
local NodeHelper = require("NodeHelper")
local pageManager = require("PageManager")
local common = require("common")
local CONST = require("Battle.NewBattleConst")
require("Battle.NgBattleDataManager")

NgBattleDetailTestPage = NgBattleDetailTestPage or { }
local option = {
    ccbiFile = "CombatStatsTest.ccbi",
    handlerMap =
    {
        onType1 = "onType1",
        onType2 = "onType2",
        onType3 = "onType3",
        onClose = "onClose",
    }
}
local DetailContentTest = {
    ccbiFile = "CombatStatsContentTest.ccbi"
}
local SCALE9_BASE_INSET = 13
local BAR_WIDTH = 163
local BAR_HEIGHT = 21
local uiType = 1
local uiIdx = 1
local uiMaxNum = 0

------------------------------------------------
function DetailContentTest:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end
function DetailContentTest:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    -- 進度條設定
    if self.skillData["TOTAL"] and self.skillData["TOTAL"]["COUNT"] > 0 then
        NgBattleDetailTestPage:setScale9(container, "mMissBar", 0, uiMaxNum, "mMissTxt")
        NgBattleDetailTestPage:setScale9(container, "mNormalBar", self.skillData["NORMAL"] and self.skillData["NORMAL"]["DMG"] or 0, uiMaxNum, "mNormalTxt")
        NgBattleDetailTestPage:setScale9(container, "mCriBar", self.skillData["CRI"] and self.skillData["CRI"]["DMG"] or 0, uiMaxNum, "mCriTxt")
        NgBattleDetailTestPage:setScale9(container, "mMissTrueBar", 0, uiMaxNum)
        NgBattleDetailTestPage:setScale9(container, "mNormalTrueBar", self.skillData["NORMAL"] and self.skillData["NORMAL"]["TRUE_DMG"] or 0, uiMaxNum)
        NgBattleDetailTestPage:setScale9(container, "mCriTrueBar", self.skillData["CRI"] and self.skillData["CRI"]["TRUE_DMG"] or 0, uiMaxNum)
        NgBattleDetailTestPage:setScale9(container, "mMissCountBar", self.skillData["MISS"] and self.skillData["MISS"]["COUNT"] or 0, self.skillData["TOTAL"]["COUNT"], "mMissCountTxt")
        NgBattleDetailTestPage:setScale9(container, "mNormalCountBar", self.skillData["NORMAL"] and self.skillData["NORMAL"]["COUNT"] or 0, self.skillData["TOTAL"]["COUNT"], "mNormalCountTxt")
        NgBattleDetailTestPage:setScale9(container, "mCriCountBar", self.skillData["CRI"] and self.skillData["CRI"]["COUNT"] or 0, self.skillData["TOTAL"]["COUNT"], "mCriCountTxt")
    end
    -- 頭像設定
    --if self.itemId then
    --    if self.id < ENEMY_DATA_OFFSET then -- 玩家
    --        NodeHelper:setSpriteImage(container, { mHeadIcon = "UI/Role/Portrait_" .. string.format("%02d", self.itemId) .. "00.png" })
    --    else
    --        if self.roleType == CONST.CHARACTER_TYPE.HERO then
    --            NodeHelper:setSpriteImage(container, { mHeadIcon = "UI/Role/Portrait_" .. string.format("%02d", self.itemId) .. "00.png" })
    --        elseif self.roleType == CONST.CHARACTER_TYPE.MONSTER or self.roleType == CONST.CHARACTER_TYPE.WORLDBOSS then
    --            NodeHelper:setSpriteImage(container, { mHeadIcon = "monster/Monster_" .. self.itemId .. ".png" })
    --        end
    --    end
    --end
    NodeHelper:setStringForLabel(container, { mSkillId = self.skillId })
end
------------------------------------------------

function NgBattleDetailTestPage:onEnter(container)
    self:initUI(container)
    self:calculateMaxData(container)
    self:initScroll(container)
end

function NgBattleDetailTestPage:initUI(container)
    ---- 玩家頭像/名稱設定
    --local roleIcon = ConfigManager.getRoleIconCfg()
    --local trueIcon = GameConfig.headIconNew or UserInfo.playerInfo.headIcon
    --local icon, bgIcon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
    --
    --if not roleIcon[trueIcon] then
    --    local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
    --    if NodeHelper:isFileExist(icon) then
    --        NodeHelper:setSpriteImage(container, { mPlayerIcon = icon })
    --    end
    --else
    --    NodeHelper:setSpriteImage(container, { mPlayerIcon = roleIcon[trueIcon].MainPageIcon })
    --end
end

function NgBattleDetailTestPage:initScroll(container)
    container.mPlayerScrollView = container:getVarScrollView("mPlayerContent")
    container.mPlayerScrollView:removeAllCell()
    local count = 0
    local skillData = NgBattleDataManager.battleDetailDataTest[uiIdx][uiType]
    if not skillData then
        return
    end
    for id, data in pairs(skillData) do
        local cell = CCBFileCell:create()
        cell:setCCBFile(DetailContentTest.ccbiFile)
        local handler = common:new({ skillId = id, skillData = data }, DetailContentTest)
        cell:registerFunctionHandler(handler)
        container.mPlayerScrollView:addCell(cell)
        count = count + 1
    end
    container.mPlayerScrollView:setTouchEnabled(count > 5)
    container.mPlayerScrollView:orderCCBFileCells()
end

function NgBattleDetailTestPage:calculateMaxData(container)
    if not NgBattleDataManager.battleDetailDataTest[uiIdx] then
        return
    end
    if not NgBattleDataManager.battleDetailDataTest[uiIdx][uiType] then
        return
    end
    uiMaxNum = 0
    local data = NgBattleDataManager.battleDetailDataTest[uiIdx][uiType]
    for skillId, skillData in pairs(data) do
        uiMaxNum = uiMaxNum + (skillData["CRI"] and skillData["CRI"]["TRUE_DMG"] or 0)
        uiMaxNum = uiMaxNum + (skillData["NORMAL"] and skillData["NORMAL"]["TRUE_DMG"] or 0)
    end
end

function NgBattleDetailTestPage:onType1(container)
    if uiType == 1 then
        return
    end
    uiType = 1
    self:calculateMaxData(container)
    self:initScroll(container)
end
function NgBattleDetailTestPage:onType2(container)
    if uiType == 2 then
        return
    end
    uiType = 2
    self:calculateMaxData(container)
    self:initScroll(container)
end
function NgBattleDetailTestPage:onType3(container)
    if uiType == 3 then
        return
    end
    uiType = 3
    self:calculateMaxData(container)
    self:initScroll(container)
end

function NgBattleDetailTestPage:setScale9(container, nodeName, num1, num2, txt)
    local node = container:getVarScale9Sprite(nodeName)
    local per = math.max(0, math.min(1, num1 / num2))
    node:setInsetLeft((per * BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (per * BAR_WIDTH / 2))
    node:setInsetRight((per * BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (per * BAR_WIDTH / 2))
    node:setContentSize(CCSize(per * BAR_WIDTH, BAR_HEIGHT))
    node:setVisible(per > 0)
    if txt then
        local nodeTTF = container:getVarLabelTTF(txt)
        if nodeTTF then
            nodeTTF:setString(num1 .. "/" .. num2)
        end
    end
end

function NgBattleDetailTestPage:onClose(container)
    PageManager.popPage(thisPageName)
end

function NgBattleDetailTestPage_setUiType(_type, _idx)
    uiType = _type
    uiIdx = _idx
end

local CommonPage = require("CommonPage")
NgBattleDetailTestPage = CommonPage.newSub(NgBattleDetailTestPage, thisPageName, option)

return NgBattleDetailPage