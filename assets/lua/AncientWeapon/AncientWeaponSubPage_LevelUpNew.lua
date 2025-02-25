local HP_pb = require("HP_pb") -- 包含协议id文件

local Async = require("Util.Async")
local PacketAgent = require("Util.PacketAgent")
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")
local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
local thisPageName = "AncientWeaponSubPage_LevelUpNew"


local opcodes = {
    EQUIP_ENHANCE_S = HP_pb.EQUIP_ENHANCE_S,
    EQUIP_ENHANCE_RESET_S = HP_pb.EQUIP_ENHANCE_RESET_S
}

local option = {
    ccbiFile = "AWSystemPage2_LevelUp.ccbi",
    handlerMap = {
        -- 按钮点击事件
        onReset = "onReset",
        onLevelUp = "onLevelUp",
        onHelp = "onHelp",
        onClose = "onClose"
    },
    opcode = opcodes
}



--[[ 本體 ]]
local AWT_LevelUpBase = {}


--[[ 容器 ]]
AWT_LevelUpBase.container = nil

--[[ 當前裝備 ]]
AWT_LevelUpBase._currentUserEquipID = nil
AWT_LevelUpBase._currentEquipID = nil

--[[ 當前等級 ]]
AWT_LevelUpBase._currentLevel = 0

--[[ 特效spine ]]
AWT_LevelUpBase.effectSpine = nil

local userEquipId = 0


--[[ 當 頁面 進入 ]]
function AWT_LevelUpBase:onEnter (container)
    -- 綁定 協定與訊息
    local packetAgent = PacketAgent:inst()
    packetAgent:bindOpcodeMsg(HP_pb.EQUIP_ENHANCE_S, EquipOpr_pb.HPEquipEnhanceRet)
    packetAgent:bindOpcodeMsg(HP_pb.EQUIP_ENHANCE_RESET_S, EquipOpr_pb.HPEquipEnhanceResetRet)

    self.container = container
    -- 讀取 裝備
    self:loadUserEquip(userEquipId)

    -------------------
    self:refreshPage()

end

function AWT_LevelUpBase:setNowId(_id)
    userEquipId = _id
end
--[[ 當 頁面 執行 ]]
function AWT_LevelUpBase:onExecute(selfContainer, parentPage)

end
function AWT_LevelUpBase:onClose()
    PageManager.popPage(thisPageName)
end

--[[ 當 頁面 離開 ]]
function AWT_LevelUpBase:onExit(selfContainer, parentPage)
    self.effectSpine = nil
end

--[[ 當 點擊 重置  ]]
function AWT_LevelUpBase:onReset (container)
    local title = common:getLanguageString("@AncientWeapon.Reset.title")
    local message = common:getLanguageString("@AncientWeapon.Reset")
    PageManager.showConfirm(title, message,
        function(agree)
            if agree then
                if UserInfo.playerInfo.gold < GameConfig.AW_RESET_COST then   
                    MessageBoxPage:Msg_Box_Lan("@GoldNotEnough")
                    return
                else
                    local slf = self
                    self:sendRequest_reset(function(packet)
                        local userEquipId = packet.msg.equipId
                        if userEquipId ~= slf._currentUserEquipID then return end
                        local userEquip = UserEquipManager:getUserEquipById(userEquipId)
                        local lv = 1 + userEquip.strength
                        slf:setLevel(lv)
                        PageManager.refreshPage("Inventory.InventoryPage", "refreshIcon")
                        PageManager.refreshPage("EquipLeadPage", "refreshIcon")
                        PageManager.refreshPage("AWTSelectPage", "refreshInfo")
                    end)
                end
            end
        end
    )
    
end

--[[ 當 點擊 說明  ]]
function AWT_LevelUpBase:onHelp (container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_AW_LEVELUP)
end

--[[ 當 點擊 升級  ]]
function AWT_LevelUpBase:onLevelUp (container)
    local slf = self
    self:sendRequest_levelUp(function(packet)
        -- 播放特效
        self:loadEffSpine(container)
        self.effectSpine:runAnimation(1, "animation", 0)
        
        local userEquipId = packet.msg.equipId
        if userEquipId ~= slf._currentUserEquipID then return end
        local userEquip = UserEquipManager:getUserEquipById(userEquipId)
        local lv = 1 + userEquip.strength
        -- dump({
        --     userEquipID = userEquipId,
        --     equipID = userEquip.equipId,
        --     lv = lv
        -- }, "onLevelUp")
        slf:setLevel(lv)
        PageManager.refreshPage("Inventory.InventoryPage", "refreshIcon")
        PageManager.refreshPage("EquipLeadPage", "refreshIcon")
        PageManager.refreshPage("AWTSelectPage", "refreshInfo")
    end)
end


-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  


--[[ 刷新頁面 ]]
function AWT_LevelUpBase:refreshPage ()
    
end

--[[ 讀取 Spine特效 ]]
function AWT_LevelUpBase:loadEffSpine (container)
    if self.effectSpine == nil then
        self.effectSpine = SpineContainer:create("Spine/NGUI", "NGUI_82_weaponsUP_short")
        local spineNode = tolua.cast(self.effectSpine, "CCNode")
        local spineParent = container:getVarNode("mSpineNode")
        spineParent:removeAllChildrenWithCleanup(true)
        spineParent:addChild(spineNode)
    end
end

--[[ 讀取 裝備 ]]
function AWT_LevelUpBase:loadUserEquip (userEquipId)

    local userEquip = UserEquipManager:getUserEquipById(userEquipId)
    local level = 1 + userEquip.strength
    self._currentUserEquipID = userEquipId
    self._currentEquipID = userEquip.equipId
    local parsedEquip = InfoAccesser:parseAWEquipStr(self._currentEquipID)
    local firstStarCfg = parsedEquip.firstStarCfg

    --local imgMap = {
    --    equipImg = firstStarCfg.icon
    --}    
    local txtMap = {
        equipNameTxt = common:getLanguageString(firstStarCfg.name)
    }
    local nowRank = tonumber( string.sub(self._currentEquipID,1,1))
    -- 顯示星數
    NodeHelperUZ:showRareStar(self.container, parsedEquip.star)

    --NodeHelper:setSpriteImage(self.container, imgMap)
    NodeHelper:setStringForLabel(self.container, txtMap)

    self:setLevel(level)
end

--[[ 設置 當前等級 ]]
function AWT_LevelUpBase:setLevel (level)
    self._currentLevel = level

    local parsedEquip = InfoAccesser:parseAWEquipStr(self._currentEquipID)
    local star = parsedEquip.star
    
    local levelsAttrs = AncientWeaponDataMgr:getEquipAttr(self._currentEquipID, {
        {["level"] = level,   ["star"] = star}, 
        {["level"] = level+1, ["star"] = star},
    })
    local curLvAttrs = levelsAttrs[1]
    local nxtLvAttrs = levelsAttrs[2]

    --if level+1 > 10 then 
    --    nxtLvAttrs = nil
    --end

    local visibleMap = {}
    local txtMap = {}
    local node2Img = { }

    visibleMap["resetBtn"] = level > 1

    -- 若已達最高等
    if nxtLvAttrs == nil then

        -- 等級面板顯示
        visibleMap["notMaxLvNode"] = false
        visibleMap["maxLvNode"] = true

        -- 等級標示
        txtMap["maxLvNum"] = tostring(level)
        
        -- 屬性 
      for i = 1, 2 do
        local curAttr = curLvAttrs[i]

        -- 最大等级属性
        txtMap["maxLvAttrValTxt_" .. i] = curAttr:valStr()
        txtMap["maxLvAttrValName_" .. i] = curAttr.name
        node2Img["maxLvAttrValIcon_" .. i] = curAttr.icon

        -- 下一最大等级属性
        txtMap["nxtMaxLvAttrValName_" .. i] = curAttr.name
        node2Img["nxtMaxLvAttrValIcon_" .. i] = curAttr.icon
    end

    -- 若有下一等級
    else

        -- 等級面板顯示
        visibleMap["notMaxLvNode"] = true
        visibleMap["maxLvNode"] = false

        -- 等級標示
        txtMap["curLvNum"] = tostring(level - 1)
        txtMap["nxtLvNum"] = tostring(level)
 
        -- 屬性
       for i = 1, 2 do
            local curAttr = curLvAttrs[i]
            local nxtAttr = nxtLvAttrs[i]

            -- 当前等级属性
            txtMap["curLvAttrValTxt_" .. i] = curAttr:valStr()
            txtMap["curLvAttrValName_" .. i] = curAttr.name
            node2Img["curLvAttrValIcon_" .. i] = curAttr.icon

            -- 下一等级属性
            txtMap["nxtLvAttrValTxt_" .. i] = nxtAttr:valStr()
            txtMap["nxtLvAttrValName_" .. i] = nxtAttr.name
            node2Img["nxtLvAttrValIcon_" .. i] = nxtAttr.icon
        end

    end

    NodeHelper:setSpriteImage(self.container, node2Img)
    NodeHelper:setStringForLabel(self.container, txtMap)
    NodeHelper:setNodesVisible(self.container, visibleMap)

    self:updateCurrency()
end

--[[ 更新 貨幣 ]]
function AWT_LevelUpBase:updateCurrency ()

    local txtMap = {
        currencyTxt_1 = "-/-",
        currencyTxt_2 = "-/-",
    }

    local isEnough = true

    -- 消耗道具
    local costCfg = AncientWeaponDataMgr:getEquipLevelUpCost(self._currentEquipID, self._currentLevel+1)
    if not costCfg then
        return
    end

    local parsedCostItem = costCfg.costItem
    local costs = {}
    costs[1] = {
        needCount = costCfg.costCoin,
        userCount = InfoAccesser:getUserItemCountByStr("10000_1002_0"),
    }
    costs[2] = {
        needCount = parsedCostItem.count,
        userCount = InfoAccesser:getUserItemCount(parsedCostItem.type, parsedCostItem.itemId),
    }

    for idx = 1, #costs do
        local val = costs[idx]
        txtMap["currencyTxt_" .. tostring(idx)] = string.format("%s/%s", GameUtil:formatNumber(val.userCount), GameUtil:formatNumber(val.needCount))
        if val.userCount < val.needCount then
            isEnough = false
            NodeHelper:setColorForLabel(self.container, { 
                ["currencyTxt_" .. tostring(idx)] = GameConfig.ITEM_NUM_COLOR.NOT_ENOUGH,
            })
        else
            NodeHelper:setColorForLabel(self.container, { 
                ["currencyTxt_" .. tostring(idx)] = GameConfig.ITEM_NUM_COLOR.ENOUGH,
            })
        end
    end

    NodeHelper:setStringForTTFLabel(self.container, txtMap)
    NodeHelper:setMenuItemEnabled(self.container, "lvUpBtn", isEnough)
    -- NodeHelperUZ:setNodeIsGrayRecursive(self.container:getVarNode("lvUpBtn"), not isEnough)

end


--[[ 送出請求 升級 ]]
function AWT_LevelUpBase:sendRequest_levelUp (onReceive)
    local msg = EquipOpr_pb.HPEquipEnhance()
    msg.equipId = self._currentUserEquipID
    msg.equipEnhanceType = 1 -- 1:一次 2:十次

    local packetAgent = PacketAgent:inst()
    local res = nil
    -- 非同步 平行執行
    Async:parallel({
        function (ctrlr)
            -- 單次 當 裝備訊息同步
            packetAgent:once(HP_pb.EQUIP_INFO_SYNC_S, function(packet)
                ctrlr.next()
            end)
        end,
        function (ctrlr)
            -- 當 送出並回傳 升級
            packetAgent:send(HP_pb.EQUIP_ENHANCE_C, msg, HP_pb.EQUIP_ENHANCE_S, function(packet)
                res = packet
                ctrlr.next()
            end, {isWait = true})
        end,
    },
    -- 全部都完成後
    function()
        onReceive(res)
    end)
end

--[[ 送出請求 重置等級 ]]
function AWT_LevelUpBase:sendRequest_reset (onReceive)
    local msg = EquipOpr_pb.HPEquipEnhanceReset()
    msg.equipId = self._currentUserEquipID

    local packetAgent = PacketAgent:inst()
    local res = nil
    -- 非同步 平行執行
    Async:parallel({
        function (ctrlr)
            -- 單次 當 裝備訊息同步
            packetAgent:once(HP_pb.EQUIP_INFO_SYNC_S, function(packet)
                ctrlr.next()
            end)
        end,
        function (ctrlr)
            -- 當 送出並回傳 重置
            packetAgent:send(HP_pb.EQUIP_ENHANCE_RESET_C, msg, HP_pb.EQUIP_ENHANCE_RESET_S, function(packet)
                res = packet
                ctrlr.next()
            end, {isWait = true})
        end,
    }, 
    -- 全部都完成後
    function()
        onReceive(res)
    end)
end


local CommonPage = require("CommonPage")
local AWT_LevelUpPage= CommonPage.newSub(AWT_LevelUpBase, thisPageName, option)
return AWT_LevelUpPage