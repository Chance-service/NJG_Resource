
--[[ 
    name: SpiritSubPage_Loadout
    desc: 精靈 子頁面 裝載 
    author: youzi
    update: 2023/7/24 15:33
    description: 
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件
local Formation_pb = require("Formation_pb")

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local PathAccesser = require("Util.PathAccesser")
local InfoAccesser = require("Util.InfoAccesser")

local SpiritDataMgr = require("Spirit.SpiritDataMgr")
local SpiritStatusPage = require("Spirit.SpiritStatusPage")
local UserMercenaryManager = require("UserMercenaryManager")

local CommItem = require("CommUnit.CommItem")

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ UI檔案 ]]
local CCBI_FILE = "SpiritSystem.ccbi"

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
    onLevelHelpBtn = "onLevelHelpBtn",
    onLevelUpBtn = "onLevelUpBtn",
    onSelectPopupConfirmBtn = "onSelectPopupConfirmBtn",
}

--[[ 協定 ]]
local OPCODES = {
    SYNC_SPRITE_SOUL_S = HP_pb.SYNC_SPRITE_SOUL_S,
    ACTIVE_SPRITE_SOUL_S = HP_pb.ACTIVE_SPRITE_SOUL_S,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    GET_FORMATION_EDIT_INFO_S = HP_pb.GET_FORMATION_EDIT_INFO_S,
    EDIT_FORMATION_S = HP_pb.EDIT_FORMATION_S,
}

--[[ 精靈於編隊中的起始編號 ]]
local INDEX_ZERO_IN_FORMATION = 6 -1

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
        slot_{1~4}_lockNode 鎖住時的容器
        slot_{1~4}_reqLvText 需求等級文字

        slot_{1~4}_unlockNode 解鎖後的容器
        slot_{1~4}_contentBGImg 內容背景圖片
        slot_{1~4}_contentImg 內容圖片
        slot_{1~4}_badgeImg 徽章圖片

        lvText 當前等級文字
        lvMaxText 上限等級文字
        lvUpBtn 提升等級按鈕
        lvUpMenuItem 提升等級選單按鈕

        currencyText_1 當前貨幣(資源)1
        currencyText_2 當前貨幣(資源)2

        attrIconImg_{1~4} 屬性圖標
        attrNumText_{1~4} 屬性數值文字

        selectPopupNode 彈窗
        selectPopup_titleText 視窗標題文字
        selectPopup_scrollview 滾動視窗
        selectPopup_skillDescText 技能說明文字
        selectPopup_skillIconNode 技能圖標容器
        selectPopup_confirmBtnNode 確認按鈕容器
        selectPopup_confirmBtn 確認按鈕
        selectPopup_confirmBtnText 確認按鈕文字
        
    event
        onSlotBtn_{1~4} 當裝備槽x號被按下
        onLevelHelpBtn 當等級提示按下
        onLevelUpBtn 當提升等級按下

        onSelectPopupConfirmBtn 當 選擇彈窗 確認按鈕 按下
    
--]]



-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

--[[ 父頁面 ]]
Inst.parentPage = nil

--[[ 容器 ]]
Inst.container = nil

--[[ Spine背景 ]]
Inst.bgSpine = nil

--[[ 當 關閉 行為 ]]
Inst.onceClose_fn = nil

--[[ 子頁面資訊 ]]
Inst.subPageName = "Loadout"
Inst.subPageCfg = nil

Inst._currentLevel = 0

Inst._curLevelCfg = nil
Inst._nxtLevelCfg = nil

Inst._slot2IsUnlock = {}

Inst.loadoutSpirits = {}

Inst.avaliableSpiritDatas = {}

Inst.statusInfo = {}

Inst.slotCount = 4

Inst.attrCount = 4

Inst._selectedSlotIdx = nil

Inst.group2Formation = {}

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)
    -- 同步 精靈島 資訊
    if packet.opcode == HP_pb.SYNC_SPRITE_SOUL_S then
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(packet.msgBuff)
        local id = msg.id
        self._currentLevel = id -- 不同等級 視為 不同星魂
        self:refreshPage()
        return
    -- 取得 精靈島 升級(啟用等級) 資訊
    elseif packet.opcode == HP_pb.ACTIVE_SPRITE_SOUL_S then
        local msg = StarSoul_pb.ActiveStarSoulRet()
        msg:ParseFromString(packet.msgBuff)
        local id = msg.id
        self._currentLevel = id -- 不同等級 視為 不同星魂
        self:refreshPage()
        return
    -- 更新 角色(精靈)資訊
    elseif packet.opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(packet.msgBuff)
        SpiritDataMgr:updateUserSpiritStatusInfosByRoleInfos(msg.roleInfos)
        self:updateSpirits()

    -- 取得編隊資訊
    elseif packet.opcode == HP_pb.GET_FORMATION_EDIT_INFO_S then
        local msg = Formation_pb.HPFormationEditInfoRes()
        msg:ParseFromString(packet.msgBuff)
        local formationMsg = msg.formations
        
        local formationData = {}
        
        formationData.name = formationMsg.name
        
        local roleIDs = {}
        for idx = 1, #formationMsg.roleIds do
            roleIDs[idx] = formationMsg.roleIds[idx]
        end
        formationData.roleIDs = roleIDs

        self.group2Formation[formationMsg.index] = formationData
        
        self:refreshPage()

    -- 編輯隊伍完成
    elseif packet.opcode == HP_pb.GET_FORMATION_EDIT_INFO_S then
        local msg = Formation_pb.HPFormationUseRes()
        msg:ParseFromString(packet.msgBuff)
    end
end

--[[ 建立 頁面 ]]
function Inst:createPage (parentPage)
    self.parentPage = parentPage
    self.container = ScriptContentBase:create(CCBI_FILE)
    return self.container
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (selfContainer, parentPage)
    local slf = self

    -- 註冊 呼叫行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = HANDLER_MAP[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        elseif string.sub(eventName, 1, 10) == "onSlotBtn_" then
            local idx = tonumber(string.sub(eventName, 11))
            slf:onSlotBtn(idx)
        end
    end)

    -- 註冊 協定
    self.parentPage:registerPacket(OPCODES)

    -- 取得 子頁面 配置
    self.subPageCfg = SpiritDataMgr:getSubPageCfg(self.subPageName)

    -- 建立背景
    self.bgSpine = SpineContainer:create("Spine/NGUI", "NGUI_21_SpiritIsland")
    self.bgSpine.node = tolua.cast(self.bgSpine, "CCNode")
    NodeHelperUZ:fitBGSpine(self.bgSpine.node)
    self.container:getVarNode("bgSpineNode"):addChild(self.bgSpine.node)
    self.bgSpine:runAnimation(1, "animation", -1)

    -- 建立 選取彈窗
    self.selectPopup = require("Spirit.SpiritSubPage_Loadout_SelectPopup"):new()
    self.selectPopup:createPage(self)

    self.selectPopup:show(false)

    self.selectPopup.onConfirm_fn = function (spiritData)
        local selectIdx = slf._selectedSlotIdx
        slf._selectedSlotIdx = nil

        local spiritID = nil
        if spiritData then spiritID = spiritData.id end

        -- print("confirm to set "..tostring(selectIdx).." to "..tostring(spiritID))

        -- local loadoutSpirits = SpiritDataMgr:getLoadoutSpirits()
        -- local loadoutSpirits = self:getLoadout()
        local loadoutSpirits = self:getLoadout()

        local toSwitchIdx = nil
        local toSwitch = nil
        for idx = 1, slf.slotCount do
            local each = loadoutSpirits[idx]
            if each ~= nil and each == spiritID then
                toSwitchIdx = idx
                toSwitch = loadoutSpirits[selectIdx]
            end
        end

        if toSwitchIdx ~= nil then
            -- print(string.format("switch %s to %s", tostring(toSwitchIdx), tostring(toSwitch)))
            slf:setSlot(toSwitchIdx, toSwitch, false)
        end

        slf:setSlot(selectIdx, spiritID, true)
    end 

    -------------------
    self:refreshPage()

    -- 請求初始 同步資訊
    self:sendRequest_sync()
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(selfContainer, parentPage)

end

--[[ 當 頁面 離開 ]]
function Inst:onExit(selfContainer, parentPage)
    self.parentPage:removePacket(OPCODES)
    self.bgSpine = nil
end


--[[ 當 裝備槽 按下 ]]
function Inst:onSlotBtn(slotIdx)
    if self._slot2IsUnlock[slotIdx] ~= true then return end
    
    self._selectedSlotIdx = slotIdx
    -- local selectedSpiritID = SpiritDataMgr:getLoadoutSpirits()[slotIdx]
    local selectedSpiritID = self:getLoadout()[slotIdx]
   
    self.selectPopup:setSpirits(self.avaliableSpiritDatas)

    local selectedIdx = nil
    for idx, val in ipairs(self.avaliableSpiritDatas) do
        if val.id == selectedSpiritID then
            selectedIdx = idx
        end
    end
    self.selectPopup:selectItem(selectedIdx)
    self.selectPopup:show(true)
end

--[[ 當 等級提示 按下 ]]
function Inst:onLevelHelpBtn()
    SpiritStatusPage:prepare({
        ["statusInfo"] = self.statusInfo,
    })
    PageManager.pushPage("Spirit.SpiritStatusPage")
end

--[[ 當 提升等級 按下 ]]
function Inst:onLevelUpBtn()
    self:sendRequest_levelUp()
end

function Inst:onSelectPopupConfirmBtn()
    self.selectPopup:confirm()
end

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 刷新頁面 ]]
function Inst:refreshPage ()
    self:setLevel(self._currentLevel)
    self:loadLoadout()
end

--[[ 更新角色資料 ]]
function Inst:updateSpirits ()
    
    self.avaliableSpiritDatas = {}

    local userSpiritStatusInfos = SpiritDataMgr:getUserSpiritStatusInfos()
    if IS_MOCK then
        userSpiritStatusInfos = {
            {spiritID = 501},
            {spiritID = 502},
            {spiritID = 503},
            {spiritID = 504},
        }
    end

    for idx, val in ipairs(userSpiritStatusInfos) do
        local spiritID = val.spiritID
        local spiritCfg = SpiritDataMgr:getSpiritCfg(spiritID)
        
        local spiritData = {}
        spiritData.id = spiritID
        spiritData.icon = SpiritDataMgr:getSpiritIconPath(spiritID)
        spiritData.name = SpiritDataMgr:getSpiritName(spiritID)
        spiritData.star = spiritCfg.Star
        
        self.avaliableSpiritDatas[#self.avaliableSpiritDatas + 1] = spiritData
    end
    
    table.sort(self.avaliableSpiritDatas, function(a, b)
        return a.id < b.id
    end)
end

--[[ 設置當前等級 ]]
function Inst:setLevel (level)
    local curCfg = SpiritDataMgr:getLevelCfg(level)
    local nxtCfg = SpiritDataMgr:getLevelCfg(level+1)
    
    local curGroupCfg = SpiritDataMgr:getGroupCfg(curCfg.group)
    local nxtGroup = curCfg.group+1
    local nxtGroupCfg = SpiritDataMgr:getGroupCfg(nxtGroup)

    local currStatus = {
        ["group"] = curCfg.group,
        ["levelCap"] = curGroupCfg.endLevel,
    }

    local nextStatus
    if nxtGroupCfg ~= nil then
        nextStatus = {
            ["group"] = nxtGroup,
            ["levelCap"] = nxtGroupCfg.endLevel,
        }
    end
    
    self.statusInfo = {
        ["cur"] = currStatus,
        ["nxt"] = nextStatus,
    }

    self._curLevelCfg = curCfg
    self._nxtLevelCfg = nxtCfg
    
    local node2String = {
        lvText = tostring(level),
        lvMaxText = tostring(curGroupCfg.endLevel), -- TODO
    }

    local node2Visible = {}
    local node2Img = {}

    for idx = 1, self.slotCount do
        local idxStr = tostring(idx)
        local groupCfg = SpiritDataMgr:getGroupCfg(idx)
        node2String["slot_"..idxStr.."_reqLvText"] = tostring(groupCfg.startLevel)

        local isGroupReached = level >= groupCfg.startLevel

        self._slot2IsUnlock[idx] = isGroupReached

        node2Visible["slot_"..idxStr.."_lockNode"] = not isGroupReached
        node2Visible["slot_"..idxStr.."_unlockNode"] = isGroupReached
    end

    for idx = 1, self.attrCount do
        local idxStr = tostring(idx)
        node2Visible["attrIconImg_"..idxStr] = false
        node2String["attrNumText_"..idxStr] = "-"
    end

    
    -- 當前等級的屬性 ID : {attr:num, val:num}
    local currAttrID2AttrVal = {}
    for idx, val in ipairs(curCfg.attr) do
        currAttrID2AttrVal[val.attr] = val
    end
    -- 當前等級狀態的屬性
    currStatus.attrs = {
        currAttrID2AttrVal[Const_pb.STRENGHT], 
        currAttrID2AttrVal[Const_pb.HP],
        currAttrID2AttrVal[Const_pb.INTELLECT], 
        currAttrID2AttrVal[Const_pb.AGILITY], 
    }

    -- 若下一等級存在
    if nxtGroupCfg ~= nil then
        local groupStartLevelCfg = SpiritDataMgr:getLevelCfg(nxtGroupCfg.startLevel)
        local nextAttrID2AttrVal = {}
        for idx, val in ipairs(groupStartLevelCfg.attr) do
            nextAttrID2AttrVal[val.attr] = val
        end
        nextStatus.attrs = {    
            nextAttrID2AttrVal[Const_pb.STRENGHT], 
            nextAttrID2AttrVal[Const_pb.HP],
            nextAttrID2AttrVal[Const_pb.INTELLECT], 
            nextAttrID2AttrVal[Const_pb.AGILITY], 
        }
    end
    
    -- 總和屬性
    local totalAttrID2AttrVal = {}
    -- 先以當前等級屬性為基底
    for attr, attrVal in pairs(currAttrID2AttrVal) do
        totalAttrID2AttrVal[attr] = attrVal
    end
    -- 加入 當前裝載精靈屬性 (應該沒有要加)
    -- local curLoadoutSpirits = SpiritDataMgr:getLoadoutSpirits()
    -- for idx, eachID in ipairs(curLoadoutSpirits) do
    --     local statusInfo = SpiritDataMgr:getUserSpiritStatusInfo(eachID)
    --     for idxx, attrVal in ipairs(statusInfo.attrs) do
    --         totalAttrID2AttrVal[attrVal.attr] = attrVal
    --     end
    -- end

    local attrs = {
        totalAttrID2AttrVal[Const_pb.STRENGHT], 
        totalAttrID2AttrVal[Const_pb.INTELLECT], 
        totalAttrID2AttrVal[Const_pb.AGILITY], 
        totalAttrID2AttrVal[Const_pb.HP],
    }

    local curAttrIdx = 1
    for idx = 1, #curCfg.attr do
        local each = attrs[idx]
        local attr_id = each.attr

        if attr_id == 101 then attr_id = 4 end -- 特例轉換

        if each ~= nil then
            local idxStr = tostring(curAttrIdx)
            node2Visible["attrIconImg_"..idxStr] = true
            node2Img["attrIconImg_"..idxStr] = PathAccesser:getAttrIconPath(attr_id)
            node2String["attrNumText_"..idxStr] = each.val

            curAttrIdx = curAttrIdx + 1
        end
    end

    NodeHelper:setSpriteImage(self.container, node2Img)
    NodeHelper:setStringForTTFLabel(self.container, node2String)
    NodeHelper:setNodesVisible(self.container, node2Visible)

    self:updateCurrency()
end

--[[ 更新 貨幣 ]]
function Inst:updateCurrency ()

    local node2Str = {
        currencyText_1 = "-/-",
        currencyText_2 = "-/-",
    }

    local isEnough = true

    local costs = self._nxtLevelCfg.cost
    for idx, val in ipairs(costs) do
        local userCount = InfoAccesser:getUserItemCountByStr(val.str)
        node2Str["currencyText_"..tostring(idx)] = string.format("%s/%s", userCount, val.count)
        if userCount < val.count then
            isEnough = false
        end
    end

    NodeHelper:setStringForTTFLabel(self.container, node2Str)
    NodeHelper:setMenuItemEnabled(self.container, "lvUpMenuItem", isEnough)
    -- NodeHelperUZ:setNodeIsGrayRecursive(self.container:getVarNode("lvUpBtn"), not isEnough)

end

--[[ 讀取裝載 ]]
function Inst:loadLoadout ()
    -- 讀取所有
    -- local loadoutSpirits = SpiritDataMgr:getLoadoutSpirits()
    local loadoutSpirits = self:getLoadout()
    for idx = 1, self.slotCount do
        local spirit = loadoutSpirits[idx]
        if spirit == 0 then spirit = nil end
        
        if self._slot2IsUnlock[idx] == true then
            self:setSlot(idx, spirit, false)
        else
            self:setSlot(idx, nil, false)
        end
    end

    -- dump(loadoutSpirits, "loadoutSpirits")
end

--[[ 取得裝載 ]]
function Inst:getLoadout ()
    local loadout = {}
    for group, formData in pairs(self.group2Formation) do
        for idx = INDEX_ZERO_IN_FORMATION+1, #formData.roleIDs do
            local spiritRoleID = formData.roleIDs[idx]
            local statusInfo = SpiritDataMgr:getUserSpiritStatusInfoByRoleID(spiritRoleID)
            -- dump(statusInfo, "spiritRoleID:"..tostring(spiritRoleID))
            if statusInfo ~= nil then
                loadout[idx-INDEX_ZERO_IN_FORMATION] = statusInfo.spiritID
            end
        end
        break
    end
    return loadout
end

--[[ 設置 裝載 ]]
function Inst:setSlot (idx, spiritID, isSave) 
    if isSave == nil then isSave = true end

    local roleID = 0
    if spiritID ~= nil then
        local statusInfo = SpiritDataMgr:getUserSpiritStatusInfo(spiritID)
        roleID = statusInfo.roleID
    end
    -- SpiritDataMgr:setLoadoutSpirit(idx, spiritID, isSave, isSaveFlush)
    for group, formData in pairs(self.group2Formation) do
        formData.roleIDs[INDEX_ZERO_IN_FORMATION+idx] = roleID
    end

    if isSave then
        self:sendEditFormation()
    end

    local idxStr = tostring(idx)
    local isSpiritExist = spiritID ~= nil
    
    local node2Visible = {}
    node2Visible["slot_"..idxStr.."_contentBGImg"] = not isSpiritExist
    node2Visible["slot_"..idxStr.."_contentImg"] = isSpiritExist
    NodeHelper:setNodesVisible(self.container, node2Visible)

    local node2Img = {}

    local skillInfo = SpiritDataMgr:getSpiritSkillInfo(spiritID)
    local skillIcon = ""
    if skillInfo ~= nil then
        skillIcon = skillInfo.icon
    end
    node2Img["slot_"..idxStr.."_contentImg"] = SpiritDataMgr:getSpiritLoadoutImgPath(spiritID) or ""
    --node2Img["slot_"..idxStr.."_badgeImg"] = skillIcon

    NodeHelper:setSpriteImage(self.container, node2Img)
end


--[[ 送出請求 升級(啟用等級) ]]
function Inst:sendRequest_levelUp ()
    local msg = StarSoul_pb.ActiveStarSoul()
    msg.id = self._currentLevel + 1 -- 指定要升到(啟用)的等級
    common:sendPacket(HP_pb.ACTIVE_SPRITE_SOUL_C, msg, true)
end

--[[ 送出請求 同步資訊 ]]
function Inst:sendRequest_sync ()
    -- if IS_MOCK then
    --     self:onReceivePacket({
    --         opcode = HP_pb.ACTIVITY154_S,
    --         msg = {
    --             lucky = 32,
    --             take = 2,
    --             free = 0,
    --             singleItem = "10000_1001_120",
    --             tenItem = "10000_1001_1200",
    --         }
    --     })
    --     return
    -- end

    -- 請求取得角色
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)

    -- 請求 同步精靈島
    local msg = StarSoul_pb.SyncStarSoul()
    msg.group = 1 -- 理論上 已不需要指定群組
    common:sendPacket(HP_pb.SYNC_SPRITE_SOUL_C, msg, true)

    -- 請求 取得編隊資訊
    local formGroups = {1, 8}
    for idx = 1, #formGroups do
        local msg = Formation_pb.HPFormationEditInfoReq()
        msg.index = formGroups[idx]
        common:sendPacket(HP_pb.GET_FORMATION_EDIT_INFO_C, msg, true)
    end
end


--[[ 送出請求 編輯隊伍 ]]
function Inst:sendEditFormation ()
    for group, formData in pairs(self.group2Formation) do
        local msg = Formation_pb.HPFormationEditReq()
        msg.index = group
        for idx = 1, #formData.roleIDs do
            msg.roleIds:append(formData.roleIDs[idx])
        end
        common:sendPacket(HP_pb.EDIT_FORMATION_C, msg, true)
    end
end

return Inst