
local CommItem = require("CommUnit.CommItem")

--[[ 本體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 當 設置道具UI ]]
function Inst:setUI (commItem, cellData)
    commItem:autoSetByFateData(cellData.fateData)
    commItem:setShowType(CommItem.ShowType.FATE)
end

--[[ 當 點擊 ]]
function Inst:onClick (inventoryPage, cellData)
    --require("FateDetailInfoPage")
    --FateDetailInfoPage_setFate( { isOthers = false, fateData = cellData.fateData })
    --PageManager.pushPage("FateDetailInfoPage")
    require("RuneInfoPage")
    RuneInfoPage_setPageInfo(GameConfig.RuneInfoPageType.NON_EQUIPPED, cellData.fateData.id)
    PageManager.pushPage("RuneInfoPage")
end

--[[ 排序資料 ]]
function Inst.sort (a, b)
    local conf_1 = a:getConf()
    local conf_2 = b:getConf()
    if a.itemId ~= b.itemId then
        return a.itemId > b.itemId
    elseif a.id ~= b.id then
        return a.id > b.id
    else
        return false
    end
end


return Inst