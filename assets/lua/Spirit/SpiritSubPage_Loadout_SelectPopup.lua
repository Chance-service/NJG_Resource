
--[[ 
    name: SpiritSubPage_Loadout_SelectPopup
    desc: 精靈 子頁面 裝載 選擇彈窗
    author: youzi
    update: 2023/7/24 15:33
    description: 
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")
local CommItem = require("CommUnit.CommItem")

local SpiritDataMgr = require("Spirit.SpiritDataMgr")

--[[ 本體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 
    text
    
    var 
        selectPopup_titleText 視窗標題文字
        selectPopup_scrollview 滾動視窗
        selectPopup_skillIconNode 技能圖標容器
        selectPopup_skillIconImg 技能圖標
        selectPopup_skillNameText 技能名稱文字
        selectPopup_skillDescText 技能說明文字
        selectPopup_confirmBtnNode 確認按鈕容器
        selectPopup_confirmBtn 確認按鈕
        selectPopup_confirmBtnText 確認按鈕文字
        
    event
        onSelectPopupConfirmBtn 當 選擇彈窗 確認按鈕 按下
    
--]]



-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

--[[ 容器 ]]
Inst.container = nil

--[[ 面板 ]]
Inst.panel = nil

--[[ 精靈資料 列表 ]]
Inst.spiritDatas = {}

--[[ 當前選取 ]]
Inst.currentSelectIdx = nil 

--[[ 橫欄數 ]]
Inst.colMax = 4

--[[ 技能說明HTML文字 ]]
Inst.skillDescHTMLLabel = nil

--[[ 當 確認 ]]
Inst.onConfirm_fn = function () end

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 

--[[ 建立 頁面 ]]
function Inst:createPage (parentPage)
    self.container = parentPage.container
    
    -- 初始化 滾動視圖
    NodeHelperUZ:initScrollView(self.container, "selectPopup_scrollview", 10)

    return nil
end

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 顯示/隱藏 ]]
function Inst:show (isShow) 
    NodeHelper:setNodesVisible(self.container, {
        selectPopupNode = isShow
    })
end

--[[ 確認 ]]
function Inst:confirm ()
    self:show(false)
    local spiritData = self.spiritDatas[self.currentSelectIdx]
    self.onConfirm_fn(spiritData)
    dump(spiritData, "select:")
end

--[[ 更新 成員 ]]
function Inst:updateItems ()
    local slf = self

    NodeHelper:clearScrollView(self.container)
    
    --[[ 滾動視圖 左上至右下 ]]
    NodeHelperUZ:buildScrollViewGrid_LT2RB(
        self.container,
        #self.spiritDatas,
        function (idx, funcHandler)
            local item = CommItem:new()
            item.onFunction_fn = funcHandler
            local itemContainer = item:requestUI()
            item:setShowType(CommItem.ShowType.SPIRIT)
            itemContainer.item = item
            
            return itemContainer
        end,
        function (eventName, container)
            local itemIdx = container:getItemDate().mID
            
            if eventName ~= "luaRefreshItemView" then return end
            local spiritData = slf.spiritDatas[itemIdx]
            container.item:setIcon(spiritData.icon)
            container.item:setName(common:getLanguageString(spiritData.name))
            container.item:setStar(spiritData.star)

            spiritData.item = container.item
            
            -- 當 點選
            container.item.onClick_fn = function (container)
                local selectIdx = itemIdx
                -- 重複選中 則是 取消
                if selectIdx == slf.currentSelectIdx then
                    selectIdx = nil
                end
                slf:selectItem(selectIdx)
            end
        end,
        { -- magic layout number
            interval = ccp(0, 30),
            colMax = self.colMax,
            paddingTop = 30,
            paddingBottom = 30,
            paddingLeft = 28,
            originScrollViewSize = CCSizeMake(600, 470),
            startOffsetAtItemIdx = 1,
            -- isBounceable = false,
        }
    )
end

--[[ 設置 成員 ]]
function Inst:setSpirits (spiritDatas)
    -- spiritData {id, icon, name, star}
    self.spiritDatas = {}
    for idx, val in ipairs(spiritDatas) do
        self.spiritDatas[idx] = val
    end
    self:updateItems()
end

--[[ 選擇 項目 ]]
function Inst:selectItem (itemIdx)

    -- 若有指定 但 超出範圍 則 清空
    if itemIdx ~= nil then
        if itemIdx < 1 or itemIdx > #self.spiritDatas then
            itemIdx = nil
        end
    end

    self.currentSelectIdx = itemIdx
    
    local skillIcon = ""
    local skillName = ""
    local skillDesc = ""

    local spiritData = self.spiritDatas[itemIdx]
    if spiritData ~= nil then
        local skillInfo = SpiritDataMgr:getSpiritSkillInfo(spiritData.id)
        if skillInfo ~= nil then
            skillIcon = skillInfo.icon
            skillName = skillInfo.name
            skillDesc = common:getLanguageString(skillInfo.desc)
        end
    end


    -- 先清空
    NodeHelper:setSpriteImage(self.container, {
        selectPopup_skillIconImg = "",
    })
    -- 設置 icon
    NodeHelper:setSpriteImage(self.container, {
        selectPopup_skillIconImg = skillIcon,
    })

    -- 設置 名稱
    NodeHelper:setStringForTTFLabel(self.container, {
        selectPopup_skillNameText = common:getLanguageString(skillName),
    })

    -- 設置 描述
    if self.skillDescHTMLLabel ~= nil then
        self.skillDescHTMLLabel:getParent():removeChild(self.skillDescHTMLLabel, true)
    end
    self.skillDescHTMLLabel = NodeHelper:setCCHTMLLabel(self.container, "selectPopup_skillDescText", CCSize(345, 180), skillDesc)

    -- print("currentSelect:"..tostring(self.currentSelectIdx))
    for idx, val in ipairs(self.spiritDatas) do
        if val.item ~= nil then
            val.item:setSelected(idx == self.currentSelectIdx)

            if idx == self.currentSelectIdx then
                dump(val, "currentSelect")
            end
            -- print(string.format("[%s] : %s", tostring(idx), tostring(idx == self.currentSelectIdx)))
        end
    end

    -- print("select : "..tostring(itemIdx))
end

return Inst