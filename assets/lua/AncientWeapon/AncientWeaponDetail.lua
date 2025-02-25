--[[ 
    name: AncientWeaponDetail
    desc: 專武 細節 頁面 
    author: youzi
    update: 2023/11/21 15:44
    description: 

--]]

--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
-- __lang_loaded = __lang_loaded or {}
-- if not __lang_loaded["Lang/AncientWeapon.lang"] then
--     __lang_loaded["Lang/AncientWeapon.lang"] = true
--     Language:getInstance():addLanguageFile("Lang/AncientWeapon.lang")
-- end

-- 引用 ------------------
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")
local PathAccesser = require("Util.PathAccesser")
local CommItem = require("CommUnit.CommItem")

local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")

-- 常數 ------------------

local CCBI_FILE = "AWTranscendence_Selected.ccbi"
local CCBI_FILE_CONTENT = "AWTranscendence_SelectedSkillContent.ccbi"

local HANDLER_MAP = {
    onBtn = "onBtn",
    onTakeOff = "onTakeOff",
    onReplace = "onReplace",
    onEquipPage = "onEquipPage",
    onEnhance = "onEnhance",
    onEquip = "onEquip",
    onClose = "onClose",
}

--[[ 每級效果對應的星級 ]]
local UNLOCK_STARLEVEL = {
    0, 6, 11
}

--[[ 效果解鎖與鎖住的文字顏色 ]]
local UNLOCK_FONT_COLOR = "#763306"
local LOCK_FONT_COLOR = "#7F7F7F"

--------------------------

--[[ 本體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


local SkillContent = {}


--[[ 
    text

    var 
        itemIconNode 道具圖標容器

        equipNameTxt 專武名稱
        equipLevelTxt 專武等級

        equipAttr{1~2}IconImg 專武屬性1~2圖標
        equipAttr{1~2}NameTxt 專武屬性1~2名稱
        equipAttr{1~2}NumTxt 專武屬性1~2數值  

        equipEffectsScrollView 專武效果滾動視圖

        equipDescTxt 專武描述
        
        btnTxt 按鈕文字
        
    event
        onBtn 當點擊按鈕
        onClose 當關閉
    
--]]

AncientWeaponDetail_showType = { NONE = 0, NON_EQUIPED = 1, INVENTORY = 2, EQUIPED = 3 }

-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 


--[[ 容器 ]]
Inst.container = nil

--[[ 物品ID ]]
Inst.equipId = nil

--[[ 物品圖標 ]]
Inst.itemIcon = nil

--[[ 效果 滾動視圖 ]]
Inst.skillEffectsScrollView = nil

--[[ 當 點擊 ]]
Inst.onBtn_fn = nil

--[[ 當 關閉 ]]
Inst.onClose_fn = nil

--[[ 顯示類型 ]]
Inst.showType = AncientWeaponDetail_showType.NONE

--[[ Role ID ]]
Inst.roleId = nil

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


function Inst:onBtn ()
    if self.onBtn_fn ~= nil then
        self.onBtn_fn()
    end
end

function Inst:onClose ()
    self:close()
end

function Inst:onTakeOff()
    local EquipOprHelper = require("Equip.EquipOprHelper")
    EquipOprHelper:dressEquip(self.equipId, self.roleId, GameConfig.DressEquipType.Off)
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    self:close()
end

function Inst:onReplace()
    EquipSelectPage_setPart(Const_pb.NECKLACE, self.roleId)
    PageManager.pushPage("EquipSelectPage")
end

function Inst:onEquipPage()
    -- 切換至英雄介面
    MainFrame_onLeaderPageBtn()
end

function Inst:onEnhance()
    -- 專武升級升星羈絆
    require("AncientWeapon.AncientWeaponPage"):prepare(self.equipId)
    PageManager.pushPage("AncientWeapon.AncientWeaponPage")
end

function Inst:onEquip()
    local UserMercenaryManager = require("UserMercenaryManager")
    local EquipOprHelper = require("Equip.EquipOprHelper")
    local userEquipInfo = UserEquipManager:getUserEquipById(self.equipId)

    local roleEquip = UserMercenaryManager:getEquipByPart(self.roleId, Const_pb.NECKLACE)
    local roleEquipIdInfo = nil
    if roleEquip then
        local roleEquipId = roleEquip.equipId
        roleEquipIdInfo = UserEquipManager:getUserEquipById(roleEquipId)
    end

    if roleEquipIdInfo and UserEquipManager:isCanExtend(roleEquipIdInfo, userEquipInfo) then
        self:close()
        --EquipOprHelper:extendEquip(roleEquipIdInfo.id, self.equipId)
        EquipOprHelper:dressEquip(self.equipId, self.roleId, GameConfig.DressEquipType.Change)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
        PageManager.popPage("EquipSelectPage")
        --local title = common:getLanguageString("@OneKeyExtend")
        --local msg = common:getLanguageString("@OneKeyExtendDesc")
        --local yse = common:getLanguageString("@Determine")
        --local no = common:getLanguageString("@CancelingSaving")
        --PageManager.showConfirm(title, msg, function(isSure)
        --    if isSure then
        --        self:close()
        --        EquipOprHelper:extendEquip(roleEquipIdInfo.id, self.equipId)
        --        EquipOprHelper:dressEquip(self.equipId, self.roleId, GameConfig.DressEquipType.Change)
        --        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
        --        PageManager.popPage("EquipSelectPage")
        --    else
        --        self:close()
        --        --EquipOprHelper:dressEquip(self.equipId, self.roleId, Const_pb.NECKLACE)
        --    end
        --end , true, yse, no)
    else
        self:close()
        EquipOprHelper:dressEquip(self.equipId, self.roleId, GameConfig.DressEquipType.On)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
        PageManager.popPage("EquipSelectPage")
    end
end
-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  


--[[ 建立 ]]
function Inst:init (parentNode)

    local slf = self

    if self.container == nil then
        self.container = ScriptContentBase:create(CCBI_FILE)

        -- 註冊 呼叫 行為
        self.container:registerFunctionHandler(function (eventName, container)
            local funcName = HANDLER_MAP[eventName]
            local func = slf[funcName]
            if func then
                func(slf, container)
            end
        end)
        parentNode:registerMessage(MSG_MAINFRAME_REFRESH)

        self.itemIcon = CommItem:new()
        local itemIconContainer = self.itemIcon:requestUI()
        local size = itemIconContainer:getContentSize()
        itemIconContainer:setPosition(ccp(-size.width / 2, -size.height / 2))
        self.container:getVarNode("itemIconNode"):addChild(itemIconContainer)

        self.container:setVisible(false)
    end

    if parentNode ~= nil then
        parentNode:addChild(self.container)
    end

    self:setShowType(AncientWeaponDetail_showType.NONE)

    return self
end

--[[ 設置 顯示類型 ]]
function Inst:setShowType (showType)
    self.showType = showType
    for i = 1, 3 do
        NodeHelper:setNodesVisible(self.container, { ["mBtnNode" .. i] = (i == self.showType) })
    end
end

--[[ 設置 英雄RoleId ]]
function Inst:setRoleId (roleId)
    self.roleId = roleId
end

--[[ 讀取 玩家裝備 ]]
function Inst:loadUserEquip (userEquipID)
    self.equipId = userEquipID

    local userEquip = UserEquipManager:getUserEquipById(userEquipID)
    local equipID = userEquip.equipId
    local equipCfg = ConfigManager.getEquipCfg()[equipID]
    
    -- 設置 物品圖標
    self.itemIcon:autoSetByEquipID(userEquipID)

    -- 取得 屬性資訊
    local name_num_attr_list = UserEquipManager:getMainAttrStrAndNum(userEquip)
    local attrInfos = {}
    for idx = 1, #name_num_attr_list do
        local each = name_num_attr_list[idx]
        local attrInfo = InfoAccesser:getAttrInfo(each[3], each[2])
        attrInfos[#attrInfos+1] = attrInfo
    end

    -- 建立 裝備資訊
    local equipInfo = {
        name = common:getLanguageString(equipCfg.name),
        level = --[[1 + ]]userEquip.strength,
        attrs = attrInfos,
        desc = common:getLanguageString(PathAccesser:getEquipDesc(equipID)),
        heroName = InfoAccesser:getHeroInfo(AncientWeaponDataMgr:getEquipHero(equipID), {"name"}).name,
    }

    self:loadEquipInfo(equipInfo)


    self:loadEquipSkills(userEquip)
end

function Inst:loadEquipInfo (equipInfo)

    local node2Txt = {}
    local node2Img = {}
    
    node2Txt["equipNameTxt"] = equipInfo.name
    node2Txt["equipLevelTxt"] = common:getLanguageString("@Lvdot") .. tostring(equipInfo.level)
    node2Txt["exclusiveTxt"] = common:getLanguageString("@ExchangeExclusiveTxt", common:getLanguageString(equipInfo.heroName))

    if equipInfo.attrs ~= nil then
        for idx = 1, #equipInfo.attrs do
            
            local attrInfo = equipInfo.attrs[idx]
            
            local varStr = "equipAttr"..tostring(idx)
            node2Img[varStr.."IconImg"] = attrInfo.icon
            node2Txt[varStr.."NameTxt"] = attrInfo.name
            node2Txt[varStr.."NumTxt"] = attrInfo:valStr()
        end
    end

    node2Txt["equipDescTxt"] = equipInfo.desc

    NodeHelper:setStringForLabel(self.container, node2Txt)
    NodeHelper:setSpriteImage(self.container, node2Img)

end

function Inst:loadEquipSkills (userEquip)

    local slf = self

    local equipCfg = ConfigManager.getEquipCfg()[userEquip.equipId]
    local roleEquipID = equipCfg.mercenarySuitId

    self.skillEffects = {}

    local roleEquipCfg = ConfigManager.RoleEquipDescCfg()[roleEquipID]

    for idx = 1, 3 do
        local skillEffect = {}
        skillEffect.level = idx
        skillEffect.skillDesc = roleEquipCfg["desc"..tostring(idx)]
        if idx ~= 1 then
            skillEffect.unlockDesc = common:getLanguageString("@HeroSkillUpgrade" .. (UNLOCK_STARLEVEL[idx]))
        else
            skillEffect.unlockDesc = ""
        end

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


    if self.skillEffectsScrollView ~= nil then
        NodeHelper:clearScrollView(self.container)
    else
        self.skillEffectsScrollView = self.container:getVarScrollView("equipEffectsScrollView")
    end

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

            item:setData(cellData)
        end,
        {
            -- magic layout number
            interval = 5,
            paddingTop = 0,
            paddingLeft = 5,
            originScrollViewSize = CCSizeMake(640, 450),
            isDisableTouchWhenNotFull = true,
            startOffsetAtItemIdx = 1,
            isBounceable = false,
        }
    )
end

--[[ 顯示 ]]
function Inst:show ()
    self.container:setVisible(true)
end

--[[ 關閉 ]]
function Inst:close ()
    if self.container == nil then return end
    
    local parentNode = self.container:getParent()

    if parentNode ~= nil then
        parentNode:removeChild(self.container, true)
        parentNode:removeMessage(MSG_MAINFRAME_REFRESH)
    end

    if self.onClose_fn ~= nil then
        self.onClose_fn()
    end
end

--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)
    if packet.opcode == HP_pb.EQUIP_DRESS_S then
        self:close()
    end
end

--[[ 當 收到訊息 ]]
function Inst:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    local opcode = container:getRecPacketOpcode()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "AncientWeaponDetail" then
            if extraParam == "refreshIcon" then
                self:loadUserEquip(self.equipId)
            end
        end
    end
end
---------------------

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
        local labChatHtml = NodeHelper:addHtmlLable(parent, str, tonumber(skillDesc), CCSizeMake(560, 80))
    end

    return inst
end


return Inst