local HP_pb = require("HP_pb") -- 包含协议id文件

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")
local PacketAgent = require("Util.PacketAgent")
local Async = require("Util.Async")
local CommItem = require("CommUnit.CommItem")
local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")

local opcodes = {
    EQUIP_ENHANCE_S = HP_pb.EQUIP_ENHANCE_S,
    EQUIP_ENHANCE_RESET_S = HP_pb.EQUIP_ENHANCE_RESET_S
}

local option = {
    ccbiFile = "AWSystemPage2_StarUp.ccbi",
    handlerMap = {
        -- 按钮点击事件
        onStarUp = "onStarUp",
        onHelp = "onHelp",
        onClose = "onClose"
    },
    opcode = opcodes
}

local CCBI_FILE_CONTENT = "AWTranscendence_SelectedSkillContent.ccbi"

local STAR_IMG = {
    SR = "AWS_star_2.png",
    SSR = "AWS_star_3.png",
    UR = "AWS_star_4.png",
}
local UNLOCK_STARLEVEL = {
    3, 6, 9
}

local thisPageName = "AncientWeaponSubPage_StarUpNew"

local SkillContent = {}
local SkillItems = { }
local UNLOCK_FONT_COLOR = "#763306"
local LOCK_FONT_COLOR = "#7F7F7F"


function SkillContent:new()
    local inst = {}

    inst.container = nil

    inst.handlerMap = {

    }

    inst.onFunction_fn = function (eventName, container) end

    function inst:requestUI ()
        if self.container ~= nil then return self.container end
        
        self.container = ScriptContentBase:create(CCBI_FILE_CONTENT)

        local slf = self

        -- 註冊 呼叫 行為
        self.container:registerFunctionHandler(function (eventName, container)
            local funcName = slf.handlerMap[eventName]
            local func = slf[funcName]
            if func then
                func(slf, container)
            else 
                slf.onFunction_fn(eventName, container)
            end
        end)

        return self.container
    end

    function inst:setData (data)
        local level = data.level
        if level == nil then level = 1 end

        local skillDesc = data.skillDesc
        if skillDesc == nil then skillDesc = "" end

        local unlockDesc = data.unlockDesc
        if unlockDesc == nil then unlockDesc = "" end

        NodeHelper:setStringForLabel(self.container, {
            mSkillLvTxt = common:getLanguageString("@Lvdot") .. level,
            mSkillTxt = "",
            mTipTxt = unlockDesc,
        })
        local freeTypeCfg = FreeTypeConfig[math.floor(tonumber(skillDesc))]
        local str = common:fill(freeTypeCfg and freeTypeCfg.content or "xxx")
        local parent = self.container:getVarLabelTTF("mSkillTxt")
        if not data.isUnlock then
            str = string.gsub(str, UNLOCK_FONT_COLOR, LOCK_FONT_COLOR)
        end
        NodeHelper:setNodesVisible(self.container,{mTipNode = not data.isUnlock})
        local labChatHtml = NodeHelper:addHtmlLable(parent, str, tonumber(skillDesc), CCSizeMake(560, 80))
    end

    return inst
end
--[[ 本體 ]]
local AWT_StarUpBase = {}


--[[ 
    text

    var 
        
    event
        
--]]



-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 


--[[ 容器 ]]
AWT_StarUpBase.container = nil


--[[ 當前裝備 ]]
AWT_StarUpBase._currentUserEquipID = nil
AWT_StarUpBase._currentEquipID = nil

--[[ 當前星數 ]]
AWT_StarUpBase._currentStar = 0

--[[ 消耗碎片 ]]
AWT_StarUpBase._costCommItems = {}

--[[ 特效spine ]]
AWT_StarUpBase.effectSpine = nil

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 



--[[ 當 頁面 進入 ]]
function AWT_StarUpBase:onEnter (container)

    -- 綁定 協定與訊息
    local packetAgent = PacketAgent:inst()
    packetAgent:bindOpcodeMsg(HP_pb.EQUIP_UPGRADE_S, EquipOpr_pb.HPEquipUpgradeRet)

    self.container = container

    local costItem = CommItem:new()
    local costItemUI = costItem:requestUI()
    --costItem:setShowType(CommItem.ShowType.NORMAL)
    self._costCommItems[1] = costItem
    self.container:getVarNode("starUpCostNode"):addChild(costItemUI)
    costItemUI:setScale(0.8)

    local size = costItemUI:getContentSize()
    costItemUI:setPosition(ccp(size.width * -0.5, size.height * -0.5))

    -- 讀取 裝備
    self:loadUserEquip(userEquipId)

    -------------------
    self:refreshPage()

end

function AWT_StarUpBase:setNowId(_id)
    userEquipId = _id
end
--[[ 當 頁面 執行 ]]
function AWT_StarUpBase:onExecute(selfContainer, parentPage)

end
function AWT_StarUpBase:onClose()
    PageManager.popPage(thisPageName)
end

--[[ 當 頁面 離開 ]]
function AWT_StarUpBase:onExit(selfContainer, parentPage)
    self.effectSpine = nil
end

--[[ 當 點擊 說明  ]]
function AWT_StarUpBase:onHelp (container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_AW_LEVELUP)
end

--[[ 當 點擊 升級  ]]
function AWT_StarUpBase:onStarUp (container)
    local userEquip = UserEquipManager:getUserEquipById(self._currentUserEquipID)
    local parsedEquip = InfoAccesser:parseAWEquipStr(self._currentEquipID)
    local lastStar = parsedEquip.star
    self:sendRequest_starUp(function(packet)
        -- 播放特效
        --self:loadEffSpine(container)
        --self.effectSpine:runAnimation(1, "animation", 0)

        local userEquipId = packet.msg.equipId
        if userEquipId ~= self._currentUserEquipID then return end
        local userEquip = UserEquipManager:getUserEquipById(userEquipId)
        local parsedEquip = InfoAccesser:parseAWEquipStr(userEquip.equipId)
        print(tostring(self._currentUserEquipID).." star:"..tostring(lastStar).." > "..tostring(parsedEquip.star))
        self:setStar(parsedEquip.star)
        PageManager.refreshPage("Inventory.InventoryPage", "refreshIcon")
        PageManager.refreshPage("EquipLeadPage", "refreshIcon")
        PageManager.refreshPage("AWTSelectPage", "refreshInfo")

        --self:loadEquipSkills(userEquip)
        for i = 1, #SkillItems do
            local isUnlock = false
            local parsedEquip = InfoAccesser:parseAWEquipStr(userEquip.equipId)
            if parsedEquip.star >= UNLOCK_STARLEVEL[i] then
                isUnlock = true
            end
            self.skillEffects[i].isUnlock = isUnlock
            SkillItems[i]:setData(self.skillEffects[i])
        end
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
function AWT_StarUpBase:refreshPage ()
    
end
function AWT_StarUpBase:loadEquipSkills (userEquip)

    local slf = self

    local equipCfg = ConfigManager.getEquipCfg()[userEquip.equipId]
    local roleEquipID = equipCfg.mercenarySuitId

    self.skillEffects = {}
    SkillItems = { }

    local roleEquipCfg = ConfigManager.RoleEquipDescCfg()[roleEquipID]

    for idx = 1, 3 do
        local skillEffect = {}
        skillEffect.level = idx
        skillEffect.skillDesc = roleEquipCfg["desc"..tostring(idx)]
        --if idx ~= 1 then
            skillEffect.unlockDesc = common:getLanguageString("@HeroSkillUpgrade" .. (UNLOCK_STARLEVEL[idx]))
        --else
        --    skillEffect.unlockDesc = ""
        --end

        local isUnlock = false
        local parsedEquip = InfoAccesser:parseAWEquipStr(userEquip.equipId)
        if parsedEquip.star >= UNLOCK_STARLEVEL[idx] then
            isUnlock = true
        end

        if not isUnlock then
            --skillEffect.unlockDesc = roleEquipCfg["unlockDesc"..tostring(idx)]
            skillEffect.skillDesc = skillEffect.skillDesc
        else
            skillEffect.unlockDesc = ""
        end
        skillEffect.isUnlock = isUnlock

        if skillEffect.skillDesc and skillEffect.skillDesc ~= "" then
            self.skillEffects[#self.skillEffects+1] = skillEffect
        end
    end

    self.skillEffectsScrollView = self.container:getVarScrollView("equipEffectsScrollView")

    NodeHelper:initScrollView(self.container, "equipEffectsScrollView", #self.skillEffects)

    --[[ 滾動視圖 上至下 ]]
    NodeHelperUZ:buildScrollViewVertical(
        self.container,
        #self.skillEffects,
        
        function (idx, funcHandler)
            local item = SkillContent:new()
            item.onFunction_fn = funcHandler
            local contentContainer = item:requestUI()
            contentContainer.item = item
            return contentContainer
        end,

        function (eventName, container)
            if eventName ~= "luaRefreshItemView" then return end

            local idx = container:getItemDate().mID
            local cellData = slf.skillEffects[idx]
            local item = container.item
            SkillItems[idx] = item
            item:setData(cellData)
        end,
        {
            -- magic layout number
            interval = 5,
            paddingTop = 0,
            paddingLeft = 5,
            originScrollViewSize = CCSizeMake(640, 600),
            isDisableTouchWhenNotFull = true,
            startOffsetAtItemIdx = 1,
            isBounceable = false,
        }
    )
end

--[[ 讀取 Spine特效 ]]
function AWT_StarUpBase:loadEffSpine (container)
    if self.effectSpine == nil then
        self.effectSpine = SpineContainer:create("Spine/NGUI", "NGUI_83_weaponsUP2")
        local spineNode = tolua.cast(self.effectSpine, "CCNode")
        local spineParent = container:getVarNode("mSpineNode")
        spineParent:removeAllChildrenWithCleanup(true)
        spineParent:addChild(spineNode)
    end
end

--[[ 讀取 裝備 ]]
function AWT_StarUpBase:loadUserEquip (userEquipId)

    local userEquip = UserEquipManager:getUserEquipById(userEquipId)
    self._currentUserEquipID = userEquipId
    self._currentEquipID = userEquip.equipId
    local Pic = "UI/AncientWeaponSystem/AWS_"..string.sub(self._currentEquipID,1,3).."01.jpg"
    local parsedEquip = InfoAccesser:parseAWEquipStr(self._currentEquipID)
    local firstStarCfg = parsedEquip.firstStarCfg
    self:loadEquipSkills (userEquip)
    NodeHelper:setSpriteImage(self.container,{mPic = Pic})
    --local imgMap = {
    --    equipImg = firstStarCfg.icon
    --}    
    local txtMap = {
        equipNameTxt = common:getLanguageString(firstStarCfg.name)
    }
    
    local RankPic = {
                [1] = {Frame = "AWS_Img01_T3.png",Bg ="BG/UI/AWS_bg_T3.png" ,Icon = "AWS_Tag_T3.png" },
                [2] = {Frame = "AWS_Img01_T2.png",Bg ="BG/UI/AWS_bg_T2.png" ,Icon = "AWS_Tag_T2.png" },
                [3] = {Frame = "AWS_Img01_T1.png",Bg ="BG/UI/AWS_bg_T1.png" ,Icon = "AWS_Tag_T3.png" }
              }
    local nowRank = tonumber( string.sub(self._currentEquipID,1,1))
   
    -- 顯示星數
    NodeHelperUZ:showRareStar(self.container, parsedEquip.star)

    --NodeHelper:setSpriteImage(self.container, imgMap)
    NodeHelper:setStringForLabel(self.container, txtMap)

    self:setStar(parsedEquip.star)
end

--[[ 設置 當前星數 ]]
function AWT_StarUpBase:setStar(star)
    self._currentStar = star
    local parsedEquip = InfoAccesser:parseAWEquipStr(self._currentEquipID)
    local userEquip = UserEquipManager:getUserEquipById(self._currentUserEquipID)

    local level = 1 + userEquip.strength

    local equipsAttrs = AncientWeaponDataMgr:getEquipAttr(self._currentEquipID, {
        { ["level"] = level, ["star"] = star },
        { ["level"] = level, ["star"] = star + 1 },
    })

    local curStarAttrs = equipsAttrs[1]
    local nxtStarAttrs = equipsAttrs[2]

    local visibleMap = {
        notMaxStarNode = nxtStarAttrs ~= nil,
        maxStarNode = nxtStarAttrs == nil,
    }
    local txtMap = {}
    local node2Img = {}

    -- 處理星級屬性顯示
    local function setStarAttributes(prefix, attrs)
        for i = 1, 2 do
            local attr = attrs[i]
            if attr then
                txtMap[prefix .. "AttrValTxt_" .. i] = attr:valStr()
                txtMap[prefix .. "AttrValName_" .. i] = attr.name
                node2Img[prefix .. "AttrValIcon_" .. i] = attr.icon
            end
        end
    end

    if nxtStarAttrs == nil then
        setStarAttributes("maxStar", curStarAttrs)
        txtMap["nxtMaxStarAttrValName_1"] = curStarAttrs[1].name
        txtMap["nxtMaxStarAttrValName_2"] = curStarAttrs[2].name
    else
        setStarAttributes("curStar", curStarAttrs)
        setStarAttributes("nxtStar", nxtStarAttrs)
    end

    NodeHelper:setSpriteImage(self.container, node2Img)
    NodeHelper:setStringForLabel(self.container, txtMap)
    NodeHelper:setNodesVisible(self.container, visibleMap)

    -- 顯示星數邏輯提取
    local function updateStarDisplay(prefix, currentStar)
        for i = 1, 5 do
            local img, visibility
            if currentStar <= 5 then
                img = STAR_IMG.SR
                visibility = currentStar >= i
            elseif currentStar > 10 then
                img = STAR_IMG.UR
                visibility = (i <= 3) and (currentStar - 10 >= i)
            else
                img = STAR_IMG.SSR
                visibility = currentStar - 5 >= i
            end
            NodeHelper:setSpriteImage(self.container, { [prefix .. i] = img })
            NodeHelper:setNodesVisible(self.container, { [prefix .. "Node" .. i] = ((currentStar <= 10) or (i <= 3)), [prefix .. i] = visibility })
        end
    end

    -- 更新星數顯示
    updateStarDisplay("mStarPre", star)
    updateStarDisplay("mStarNew", star + 1)

    self:updateCurrency()
end


--[[ 更新 貨幣 ]]
function AWT_StarUpBase:updateCurrency ()

    local txtMap = {
        currencyTxstarUpCostTxt_1 = "-/-",
    }

    local isEnough = true

    -- 消耗道具
    local costsCfg = AncientWeaponDataMgr:getEquipStarUpCost(self._currentEquipID, self._currentStar+1)

    local costs = {}
    if costsCfg then
        for idx = 1, #costsCfg do
            local costCfg = costsCfg[idx]
            local itemInfo = InfoAccesser:getItemInfo(costCfg.type, costCfg.itemId, costCfg.count)
            local userCount = InfoAccesser:getUserItemCount(costCfg.type, costCfg.itemId)

            local costCommItem = self._costCommItems[idx]
            if costCommItem ~= nil then
                costCommItem:autoSetByItemInfo(itemInfo, false)
            end

            txtMap["starUpCostTxt_"..tostring(idx)] = string.format("%s/%s", GameUtil:formatNumber(userCount), GameUtil:formatNumber(itemInfo.count))
            if userCount < itemInfo.count then
                isEnough = false
                NodeHelper:setColorForLabel(self.container, { 
                    ["currencyTxt_" .. tostring(idx)] = GameConfig.ITEM_NUM_COLOR.NOT_ENOUGH,
                    ["starUpCostTxt_"..tostring(idx)] = GameConfig.ITEM_NUM_COLOR.NOT_ENOUGH
                })
            else
                NodeHelper:setColorForLabel(self.container, { 
                    ["currencyTxt_" .. tostring(idx)] = GameConfig.ITEM_NUM_COLOR.ENOUGH,
                    ["starUpCostTxt_"..tostring(idx)] = GameConfig.ITEM_NUM_COLOR.ENOUGH
                })
            end
        end


        NodeHelper:setStringForTTFLabel(self.container, txtMap)
        NodeHelper:setMenuItemEnabled(self.container, "starUpBtn", isEnough)
    end
    -- NodeHelperUZ:setNodeIsGrayRecursive(self.container:getVarNode("starUpBtn"), not isEnough)

end



--[[ 送出請求 升星 ]]
function AWT_StarUpBase:sendRequest_starUp (onReceive)
    
    local msg = EquipOpr_pb.HPEquipUpgrade()
    -- local msg = EquipOpr_pb.HPEquipEvolution()
    msg.equipId = self._currentUserEquipID
    -- msg.fixFlag = 0 -- 棄用參數

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
            -- 當 送出並回傳 升星
            packetAgent:send(HP_pb.EQUIP_UPGRADE_C, msg, HP_pb.EQUIP_UPGRADE_S, function(packet)
            -- packetAgent:send(HP_pb.EQUIP_EVOLUTION_C, msg, HP_pb.EQUIP_EVOLUTION_S, function(packet)
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
local AWT_StarUpPage= CommonPage.newSub(AWT_StarUpBase, thisPageName, option)
return AWT_StarUpPage