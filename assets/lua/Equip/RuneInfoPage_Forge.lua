---- 符文資訊頁面（符文鍛造頁面）
local FateDataManager   = require("FateDataManager")
local MysticalDress_pb  = require("Badge_pb")
local CommItem          = require("CommUnit.CommItem")
local InfoAccesser      = require("Util.InfoAccesser")
local CommonPage        = require("CommonPage")

-- 頁面物件與相關設定
local RuneForgePage     = {}
local pageName          = "RuneInfoPage_Forge"
local option = {
    ccbiFile = "RunePopUp2.ccbi",
    handlerMap = {
        onClose = "onClose",
    },
    opcodes = {
        MYSTICAL_DRESS_CHANGE_C = HP_pb.BADGE_DRESS_C,
        MYSTICAL_DRESS_CHANGE_S = HP_pb.BADGE_DRESS_S,
        BADGE_REFINE_C          = HP_pb.BADGE_REFINE_C,
        BADGE_REFINE_S          = HP_pb.BADGE_REFINE_S,
    },
}

-- 符文圖示模組
local RuneIconContent   = { ccbiFile = "EquipmentItem_Rune.ccbi" }
local MAX_ATTR_NUM      = 4
local MAX_SKILL_COUNT   = 5

-- 全局變數（當前頁面、符文與角色相關資訊）
local pageContainer     = nil
local currentRune       = nil  -- 符文資料
local currentPageType   = 0    -- 當前頁面類型
local currentRuneId     = 0    -- 當前符文 ID
local currentRoleId     = nil  -- 當前角色 ID
local currentPos        = nil  -- 當前位置

-- 技能內容模組
local RuneSkillContent  = { ccbiFile = "RuneEquipPopUp_EntryContent.ccbi" }

------------------------------------------------------------
-- 輔助函數
------------------------------------------------------------
-- 合併基本屬性與隨機屬性（僅保留包含 "_" 的隨機屬性）
local function mergeAttributes(basicAttrStr, randomAttrStr)
    local attrList = {}
    for _, attr in ipairs(common:split(basicAttrStr, ",")) do
        table.insert(attrList, attr)
    end
    for _, attr in ipairs(common:split(randomAttrStr, ",")) do
        if string.find(attr, "_") then
            table.insert(attrList, attr)
        end
    end
    return attrList
end

------------------------------------------------------------
-- 主流程函數
------------------------------------------------------------
function RuneForgePage:onEnter(container)
    pageContainer = container
    self:initData()
    self:initUI(container)
    self:refreshPage(container)
end

function RuneForgePage:initData()
    local runeList = FateDataManager:getAllFateList()
    currentRune = nil
    for _, data in ipairs(runeList) do
        if data.id == currentRuneId then
            currentRune = data
            break
        end
    end
end

function RuneForgePage:initUI(container)
    -- 若無符文資料，則清空相關節點並返回
    if not currentRune then
        NodeHelper:setStringForLabel(container, { mRuneName = "" })
        for i = 1, MAX_ATTR_NUM do
            NodeHelper:setNodesVisible(container, { ["mAttrNode" .. i] = false })
        end
        NodeHelper:setNodesVisible(container, { mEffectNode = false, mSkillNullStr = true })
        return
    end

    -- 初始化符文資訊（更新名稱、屬性等）
    currentRune.lockCount = 0
    local runeCfg = ConfigManager.getFateDressCfg()[currentRune.itemId]
    local fullName = common:getLanguageString(runeCfg.name) .. common:getLanguageString("@Rune")
    NodeHelper:setStringForLabel(container, { mRuneName = fullName })

    -- 合併屬性資訊並更新各屬性節點
    local attrInfo = mergeAttributes(runeCfg.basicAttr, currentRune.attr)
    for i = 1, MAX_ATTR_NUM do
        local nodeKey = "mAttrNode" .. i
        if attrInfo[i] then
            NodeHelper:setNodesVisible(container, { [nodeKey] = true })
            local parts = common:split(attrInfo[i], "_")
            local attrId, attrNum = parts[1], parts[2]
            NodeHelper:setSpriteImage(container, { ["mAttrImg" .. i] = "attri_" .. attrId .. ".png" })
            NodeHelper:setStringForLabel(container, {
                ["mAttrName" .. i]  = common:getLanguageString("@AttrName_" .. attrId),
                ["mAttrValue" .. i] = attrNum,
            })
        else
            NodeHelper:setNodesVisible(container, { [nodeKey] = false })
        end
    end

    -- 根據符文 newSkill 數量判斷是否顯示空提示文字
    if #currentRune.newSkill > 0 then
        NodeHelper:setNodesVisible(container, { mEmptyTxt1 = false })
        self:buildScrollview(container)
    end
end

function RuneForgePage:buildScrollview(container)
    if not container then return end
    local scrollView = container:getVarScrollView("mUpperScrollview")
    if not scrollView then return end
    scrollView:removeAllCell()

    -- 建立已解鎖技能節點
    for key, value in pairs(currentRune.newSkill) do
        local cell = CCBFileCell:create()
        cell:setCCBFile(RuneSkillContent.ccbiFile)
        local panel = common:new({ lockId = key, id = value, Pos = "Up" }, RuneSkillContent)
        cell:registerFunctionHandler(panel)
        if tonumber(value) then
            scrollView:addCell(cell)
        end
    end
    -- 補齊不足 MAX_SKILL_COUNT 的鎖定（未解鎖）技能節點
    for i = #currentRune.newSkill + 1, MAX_SKILL_COUNT do
        local cell = CCBFileCell:create()
        cell:setCCBFile(RuneSkillContent.ccbiFile)
        local panel = common:new({ isLimit = true, limitId = i }, RuneSkillContent)
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
    end

    scrollView:setTouchEnabled(false)
    scrollView:orderCCBFileCells()
end

------------------------------------------------------------
-- RuneSkillContent 模組（技能內容顯示）
------------------------------------------------------------
function RuneSkillContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    if self.isLimit then
        NodeHelper:setNodesVisible(container, { mLimitNode = true })
        NodeHelper:setStringForLabel(container, { mLimitTxt = common:getLanguageString("@RuneSkillTip" .. self.limitId) })
        return
    else
        NodeHelper:setNodesVisible(container, { mLimitNode = false })
    end
    NodeHelper:setNodesVisible(container, { mRefine = false, mLock = false, mLockBg = false })
    self:setHtmlString(container, self.id)
end

function RuneSkillContent:setHtmlString(container, id)
    local cfg = ConfigManager.getBadgeSkillCfg()[id]
    if not cfg then return end
    local freeTypeId = cfg.skill
    local skillDesNode = container:getVarNode("mHtmlNode")
    skillDesNode:removeAllChildren()
    local htmlLabel = CCHTMLLabel:createWithString(
                        (FreeTypeConfig[freeTypeId] and FreeTypeConfig[freeTypeId].content or ""),
                        CCSizeMake(450, 50),
                        "Barlow-SemiBold"
                      )
    htmlLabel:setAnchorPoint(ccp(0, 0.5))
    skillDesNode:addChild(htmlLabel)
    NodeHelper:setStringForLabel(container, { mTxt = "" })
end

------------------------------------------------------------
-- 符文圖示刷新（RuneIconContent 模組）
------------------------------------------------------------
function RuneForgePage:refreshPage(container)
    local itemNode = ScriptContentBase:create(RuneIconContent.ccbiFile)
    local parentNode = container:getVarNode("mIconNode")
    itemNode:setAnchorPoint(ccp(0.5, 0.5))
    parentNode:removeAllChildren()
    RuneIconContent:refresh(itemNode)
    parentNode:addChild(itemNode)
end

function RuneIconContent:refresh(container)
    if currentRune then
        local cfg = ConfigManager.getFateDressCfg()[currentRune.itemId]
        NodeHelper:setNodesVisible(container, { mCheckNode = false, mStarNode = true })
        NodeHelper:setSpriteImage(container, {
            mPic = cfg.icon,
            mFrameShade = NodeHelper:getImageBgByQuality(cfg.rare),
            mFrame = NodeHelper:getImageByQuality(cfg.rare)
        })
        for star = 1, 6 do
            NodeHelper:setNodesVisible(container, { ["mStar" .. star] = (star == cfg.star) })
        end
    else
        NodeHelper:setNodesVisible(container, { mCheckNode = false, mStarNode = false })
        NodeHelper:setSpriteImage(container, {
            mPic = "UI/Mask/Image_Empty.png",
            mFrameShade = "UI/Mask/Image_Empty.png",
            mFrame = "UI/Mask/Image_Empty.png"
        })
    end
end

------------------------------------------------------------
-- 事件處理
------------------------------------------------------------
function RuneForgePage:onReceivePacket(container)
    -- 此頁面未處理封包，可按需擴充
end

function RuneForgePage:onClose()
    currentRune   = nil
    currentPageType = 0
    currentRuneId   = 0
    currentRoleId   = nil
    currentPos      = nil
    PageManager.popPage(pageName)
end

function RuneForgePage_setPageInfo(pageType, runeId, roleId, pos)
    currentPageType = pageType
    currentRuneId   = runeId
    currentRoleId   = roleId
    currentPos      = pos
end

------------------------------------------------------------
-- 模組封裝與返回
------------------------------------------------------------
RuneForgePage = CommonPage.newSub(RuneForgePage, pageName, option)
return RuneForgePage
