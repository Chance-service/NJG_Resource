local CommItem = require("CommUnit.CommItem")
local InfoAccesser = require("Util.InfoAccesser")
local thisPageName = "CommPop.AFKTreasureBoxPage"
local opcodes = {
}

local option = {
    ccbiFile = "CommonAFKItemInfoPage.ccbi",
    handlerMap = {
    },
    opcode = opcodes
}

local AFKTreasureBox = {}
local Page = {}

function AFKTreasureBox:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function AFKTreasureBox:onEnter(container)
    container:registerFunctionHandler(AFKTreasureBox.onFunction)
    local stringTable = {}
    --PageInfo
    Page.item = Page.parent.itemInfo
    Page.useCount = 1
    Page.MaxUse = 50
    Page.container = container
    --ItemInfo
    stringTable["mItemleft"] = Page.item.count
    stringTable["mItemName"] = Page.item.name
    stringTable["mItemDesc"] = Page.item.describe
    NodeHelper:setStringForLabel(container,stringTable)
    self:setItemNum(container)
    --ItemNode
    local costItem = CommItem:new()
    local costItemUI = costItem:requestUI()
    container:getVarNode("mItemNode"):addChild(costItemUI)
    local size = costItemUI:getContentSize()
    local itemInfo = InfoAccesser:getItemInfo(30000, Page.item.itemId, 1)
    costItem:autoSetByItemInfo(itemInfo, false)
end

function AFKTreasureBox:setItemNum(container)
    local stringTable = {}
    local mapCfg = ConfigManager.getNewMapCfg()
    local mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or 
                  (mapCfg[UserInfo.stateInfo.passMapId] and UserInfo.stateInfo.passMapId or UserInfo.stateInfo.curBattleMap - 1)
    
    local Reward = 0
    local cfg = mapCfg[mapId]
    local count_reward = Page.item.afkHour * Page.useCount
    if Page.item.type == 39 then 
        Reward = cfg.SkyCoin * 60 *count_reward 
    elseif Page.item.type == 40 then
        Reward = cfg.Potion * 60 * count_reward
    elseif Page.item.type == 41 then
        Reward = cfg.Stone * count_reward
    end
    stringTable["mGetAmount"] = GameUtil:formatNumber(Reward)
    stringTable["mUseAmount"] = Page.useCount
    NodeHelper:setStringForLabel(container,stringTable)
end

function AFKTreasureBox.onFunction(eventName, container)
    if eventName == "luaLoad" then
        -- 礶更
        AFKTreasureBox:onLoad(container)
    elseif eventName == "luaEnter" then
        -- 秈礶
        AFKTreasureBox:onEnter(container)   
    elseif eventName == "onClose" then
        -- 闽超礶
        PageManager.popPage(thisPageName)
        PageManager.popPage("CommPop.CommItemInfoPage")
    elseif eventName == "onAdd" then
        -- 糤计秖
        Page.useCount = math.min(Page.useCount + 1, Page.item.count, Page.MaxUse)
        AFKTreasureBox:setItemNum(Page.container)
    elseif eventName == "onSub" then
        -- 搭ぶ计秖
        Page.useCount = math.max(Page.useCount - 1, 1)
        AFKTreasureBox:setItemNum(Page.container)
    elseif eventName == "onMax" then
        -- е硉糤程┪ㄤ场だ
        Page.useCount = calculateMaxUse(Page.useCount, Page.MaxUse, Page.item.count)
        AFKTreasureBox:setItemNum(Page.container)
    elseif eventName == "onMin" then
        -- е硉搭ぶ程┪ㄤ场だ
        Page.useCount = calculateMinUse(Page.useCount)
        AFKTreasureBox:setItemNum(Page.container)
    elseif eventName == "onOneBtn" then
        -- ㄏノ讽玡计秖闽超
        Page.parent:useItem(Page.useCount)
        PageManager.popPage(thisPageName)
    end
end

-- 璸衡程ㄏノ秖
function calculateMaxUse(currentUse, maxUse, itemCount)
    local amount = currentUse + math.ceil(maxUse / 2)
    if itemCount >= maxUse then
        amount = maxUse
    end
    return math.min(amount, itemCount)
end

-- 璸衡程ㄏノ秖
function calculateMinUse(currentUse)
    local amount = currentUse - math.ceil(currentUse / 2)
    return math.max(amount, 1)
end



function AFKTreasureBox:setData(parentPage)
    Page.parent = parentPage
end


local CommonPage = require("CommonPage")
local AFKTreasureBoxPage = CommonPage.newSub(AFKTreasureBox, thisPageName, option)

return AFKTreasureBoxPage
