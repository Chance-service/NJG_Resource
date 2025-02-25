---- 符文技能列表頁面
local RuneSkillPage = { }

local thisPageName = "RuneSkillPage"
local option = {
    ccbiFile = "RuneSkillPopUp.ccbi",
    handlerMap = {
        onClose = "onClose" ,
    },
    opcodes = {
    },
}
for i = 1, 4 do
    option.handlerMap["onLevel" .. i] = "onLevel"
end
local nowPage = 0
local ROW_COUNT = 5
local LINE_COUNT = 4
local IllItemContent = {
    ccbiFile = "RuneSkillItem.ccbi"
}
local pageContainer = nil
local items = { }    -- scrollview內的物件
local runeInfoCfg = ConfigManager.getDressInfoCfg()
local sortTable = { }
local strColor = {
    ccc3(75, 128, 251),
    ccc3(213, 89, 249),
    ccc3(244, 137, 85),
    ccc3(252, 85, 74),
}
----
function RuneSkillPage:onEnter(container)
    pageContainer = container
    self:initData(container)
    self:initUI(container)
    self:refreshTab(container)
    self:refreshPage(container)
end

function RuneSkillPage:initData(container)
    items = { }
    sortTable = { }
    nowPage = 1
    self:DataSort()
end

function RuneSkillPage:initUI(container)
    for i = 1, 4 do
        NodeHelper:setStringForLabel(container, { ["mLevelTxt" .. i] = common:getLanguageString("@Rune_" .. i) })
    end
    NodeHelper:initScrollView(container, "mContent", 30)
end

function RuneSkillPage:DataSort()
    for k, v in pairs(runeInfoCfg) do
        sortTable[v.Tier] = sortTable[v.Tier] or { }
        sortTable[v.Tier][#sortTable[v.Tier] + 1] = v
    end
    for i = 1, #sortTable do
        table.sort(sortTable[i], function(v1, v2)
            if v1.ID ~= v2.ID then
                return v1.ID < v2.ID
            end
            return false
        end)
    end
end

function RuneSkillPage:refreshPage(container)
    self:clearAndReBuildAllItem(container)
end

function RuneSkillPage:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    items = {}
    if not sortTable[nowPage] then
        return
    end
    ---
    for i = 1, #sortTable[nowPage] do
        cell = CCBFileCell:create()
        cell:setCCBFile(IllItemContent.ccbiFile)
        local handler = IllItemContent:new( { id = i, info = sortTable[nowPage][i] })
        cell:registerFunctionHandler(handler)
        container.mScrollView:addCell(cell)
        items[i] = { cls = handler, node = cell }
    end
    container.mScrollView:setTouchEnabled(#sortTable[nowPage] > ROW_COUNT * LINE_COUNT)
    container.mScrollView:orderCCBFileCells()
end

function RuneSkillPage:refreshTab(container)
    for i = 1, 4 do
        NodeHelper:setMenuItemImage(container, { ["mLevelBtn" .. i] = { normal = (nowPage == i and "BG/UI/bag_page01.png" or "BG/UI/bag_page02.png") } })
        NodeHelper:setColorForLabel(container, { ["mLevelTxt" .. i] = ((nowPage == i) and GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT) })
    end
end

function RuneSkillPage:onLevel(container, eventName)
    local page = tonumber(string.sub(eventName, -1))
    if page == nowPage then
        return
    end
    nowPage = page
    self:refreshTab(container)
    self:refreshPage(container)
end

function RuneSkillPage:onClose()
    PageManager.popPage(thisPageName)
end

------------------------------------------------
function IllItemContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function IllItemContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    
    NodeHelper:setStringForLabel(container, { mSkillName = (common:getLanguageString(self.info.Str1) .. common:getLanguageString(self.info.Str2)) })
    NodeHelper:setSpriteImage(container, { mIconSprite = self.info.Icon })
    NodeHelper:setColor3BForLabel(container, { mSkillName = strColor[nowPage] })
end
function IllItemContent:onPreLoad(ccbRoot)
end
function IllItemContent:onUnLoad(ccbRoot)
end
------------------------------------------------

local CommonPage = require("CommonPage")
RuneSkillPage = CommonPage.newSub(RuneSkillPage, thisPageName, option)

return RuneSkillPage