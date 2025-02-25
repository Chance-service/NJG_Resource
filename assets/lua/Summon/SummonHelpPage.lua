local thisPageName = "SummonHelpPage"
----这里是协议的id
local opcodes = {
}

local option = {
    ccbiFile = "SummonTips.ccbi",
    handlerMap = {
        -- 按钮点击事件
        onClose = "onClose",
    },
    opcode = opcodes
}

local SummonHelpBase = {}
local SummonContent = {ccbiFile = "SummonTipsContent.ccbi"}
local RateInfo = {}

function SummonHelpBase:onEnter(container)
    container.MainScrollView = container:getVarScrollView("mContent")
    RateInfo = self:TableSort()
    NodeHelper:setStringForLabel(container,{mTitle = RateInfo[1].Title})
    self:BuildScorllview(container)
end
function SummonHelpBase:TableSort()
    local summonRateConfig = ConfigManager.getSummonRate()
    local rateInfo = {}

    -- 過濾符合條件的配置
    for _, entry in pairs(summonRateConfig) do
        if entry.ActId == HELP_ActId then
            table.insert(rateInfo, entry)
        end
    end

    -- 根據 Sort 降序排序，若 Sort 相同則根據 Id 升序排序
    table.sort(rateInfo, function(a, b)
        if a.Sort ~= b.Sort then
            return a.Sort > b.Sort  -- Sort 降序
        else
            return a.id < b.id  -- Id 升序
        end
    end)

    return rateInfo
end

function SummonHelpBase:BuildScorllview(container)
    container.MainScrollView:removeAllCell()
    for k,v in pairs (RateInfo) do
        local cell = CCBFileCell:create()
        cell:setCCBFile(SummonContent.ccbiFile)
        local panel = common:new({data = v }, SummonContent)
        cell:registerFunctionHandler(panel)
        container.MainScrollView:addCell(cell)
    end
    container.MainScrollView:orderCCBFileCells()
end
-------------------------------------------------------------
function SummonContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local item = self.data.item[1]
    local itemId = item.itemId
    local count = item.count
    local Type = math.floor(item.type / 10000)
    local freetypefont = 5000+self.data.FreeTypeFont
    
    local function getNameByType(Type, itemId)
        if Type == 3 or Type == 7 then
            return common:getLanguageString(ConfigManager.getItemCfg()[itemId].name)
        elseif Type == 4 then
            return common:getLanguageString(ConfigManager.getEquipCfg()[itemId].name)
        elseif Type == 9 then
            return common:getLanguageString(ConfigManager.getFateDressCfg()[itemId].name)
        elseif Type == 1 then
            return common:getLanguageString("@UserProperty_Name_" .. itemId)
        else
            return ""
        end
    end

    local name = getNameByType(Type, itemId)
    local ItemString = name .. "x" .. count
    local rate = self.data.SingleRate*100 .. "%"
    SummonHelpBase:setHtmlString(container, ItemString, rate, freetypefont)
end

function SummonHelpBase:setHtmlString(container, ItemString, rate, freeTypeId)
    local function createHtmlLabel(content, size, font)
        local filledContent = common:fill((FreeTypeConfig[freeTypeId] and FreeTypeConfig[freeTypeId].content or ""), content)
        return CCHTMLLabel:createWithString(filledContent, size, font)
    end

    local function setupNode(node, htmlLabel, adjustX, adjustY)
        if node then
            node:removeAllChildren()
            if htmlLabel then
                htmlLabel:setPositionX(adjustX or 0)
                htmlLabel:setPositionY((adjustY or 0) - 8) -- Y軸下調8
                node:addChild(htmlLabel)
            end
        end
    end

    local ItemNode = container:getVarNode("mContent")
    local RateNode = container:getVarNode("mRate")

    local ItemHtmlLabel = createHtmlLabel(ItemString, CCSizeMake(450, 50), "Barlow-SemiBold")
    setupNode(ItemNode, ItemHtmlLabel, 0, 0)

    local RateHtmlLabel = createHtmlLabel(rate, CCSizeMake(450, 50), "Barlow-SemiBold")
    if RateHtmlLabel then
        local labelWidth = RateHtmlLabel:getContentSize().width
        setupNode(RateNode, RateHtmlLabel, -labelWidth-5, 0)
    end
end


-------------------------------------------------------------
function SummonHelpBase:onClose(container)
    if container.MainScrollView then
        container.MainScrollView:removeAllCell()
        container.MainScrollView = nil
    end
    HELP_ActId = 0
    RateInfo = {}
    PageManager.popPage(thisPageName)
end
--------------------------------------------------------
local CommonPage = require("CommonPage")
local SummonHelpPage = CommonPage.newSub(SummonHelpBase, thisPageName, option)

return SummonHelpPage
