--[[ 
    name: SpiritSubPage_Detail
    desc: 精靈 細節 頁面 
    author: youzi
    update: 2023/8/4 14:32
    description: 
--]]

--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/Spirit.lang"] then
--    __lang_loaded["Lang/Spirit.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/Spirit.lang")
--end

-- 引用 ------------------

local HP_pb = require("HP_pb") -- 包含协议id文件

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")
local PacketAgent = require("Util.PacketAgent")
local Async = require("Util.Async")

local SpiritDataMgr = require("Spirit.SpiritDataMgr")

local CommTabStorage = require("CommComp.CommTabStorage")
local CommItem = require("CommUnit.CommItem")

-- 常數 ------------------

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ 升級消耗道具數 ]]
local UPGRADE_ITEM_COUNT = 3

--[[ 技能標籤總數 ]]
local SKILL_TAG_COUNT = 3

--[[ Spine動畫名稱 ]]
local SPINE_ANIM_NAME = "wait_0"

--[[ 頁面名稱 ]]
local PAGE_NAME = "Spirit.SpiritDetailPage"

--[[ UI檔案 ]]
local CCBI_FILE = "SpiritDetail.ccbi"

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
    onUpgrade = "onUpgradeBtn",
}

--[[ 協定 ]]
-- local OPCODES = {
--     SYNC_SPRITE_SOUL_S = HP_pb.SYNC_SPRITE_SOUL_S,
--     ROLE_UPGRADE_STAR_S = HP_pb.ROLE_UPGRADE_STAR_S,
--     ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
-- }

------------------------

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
        @Spirit.Detail.upgradeBtn
    
    var 

        mSpine Spine容器

        mLeaderName 名稱文字
        mClassIcon 職業圖片
        mElementIcon 屬性圖片
        mStarSrNode SR稀有度星星
        mStarSsrNode SSR稀有度星星
        mStarUrNode UR稀有度星星

        mStrTxt 數值文字 力量
        mIntTxt 數值文字 智力(防禦?)
        mHpTxt  數值文字 血量
        mDexTxt 數值文字 敏捷

        mSkillNameTxt 技能文字 (技能名稱?)
        mSkillIcon 技能圖片
        mSkillLv2 技能等級 圖片邊角標示
        mSkillLv1 技能等級 下方文字標示
        mSkillDescTxt 技能描述文字

        mSkillTagNode_{1~3} 技能標籤 容器
        mSkillTagImg_{1~3} 技能標籤 底圖
        mSkillTagTxt_{1~3} 技能標籤 文字

        mUpgradeBtnNode 升級按鈕節點
        mUpgradeBtn 升級按鈕
        mUpgradeItemNode{1~3} 升級所需物品 容器
        mUpgradeItemNum{1~3}  升級所需物品 數量文字
        
    event
        onDetail 當屬性列旁 細節按鈕(驚嘆號)按下
        onUpgrade 當升級按下
    
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

--[[ 分頁列 ]]
Inst.tabStorage = nil

--[[ 升級消耗物品 ]]
Inst.upgradeItemUIs = {}

--[[ 精靈島等級 ]]
Inst._spriteSoulLevel = 0

--[[ 當前精靈ID ]]
Inst._spiritID = nil
--[[ 當前精靈實際的角色ID ]]
Inst._roleID = nil

--[[ 技能說明HTML文字 ]]
Inst.skillDescHTMLLabel = nil

--[[ 準備要顯示的精靈資訊 ]]
Inst._showOnEnterSpiritInfo = nil

--[[ 當離開時呼叫 ]]
Inst._onceExitCallbacks = {}

--[[ 是否變更 ]]
Inst._isChanged = false

--[[ 是否顯示中 ]]
Inst._isShowing = false

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
function Inst:onReceivePacket(container)
    
end

--[[ 註冊 封包相關 ]]
function Inst:registerPacket(opcodes)

    local slf = self

    -- for key, opcode in pairs(opcodes) do
    --     if string.sub(key, -1) == "S" then
    --         self.container:registerPacket(opcode)
    --     end
    -- end

    -- 協定收發代理器
    local packetAgent = PacketAgent:inst()
    
    -- 綁定 協定與訊息
    packetAgent:bindOpcodeMsg(HP_pb.ROLE_PANEL_INFOS_S, RoleOpr_pb.HPRoleInfoRes)
    packetAgent:bindOpcodeMsg(HP_pb.SYNC_SPRITE_SOUL_S, StarSoul_pb.SyncStarSoulRet)

    -- 當 更新 角色(精靈)資訊
    packetAgent:on(HP_pb.ROLE_PANEL_INFOS_S, function(packet)
        print("on:ROLE_PANEL_INFOS_S")
        SpiritDataMgr:updateUserSpiritStatusInfosByRoleInfos(packet.msg.roleInfos)
    end):tag(self)

    -- 當 同步 精靈島 資訊
    packetAgent:on(HP_pb.SYNC_SPRITE_SOUL_S, function(packet)
        print("on:SYNC_SPRITE_SOUL_S")
        local id = packet.msg.id
        slf._spriteSoulLevel = id -- 不同等級 視為 不同星魂
    end):tag(self)

    -- 當 角色升星
    packetAgent:on(HP_pb.ROLE_UPGRADE_STAR_S, function(packet)
        self._isChanged = true
            
        UserInfo.sync()

        -- 請求初始 同步資訊
        slf:sendRequest_sync(function ()
            local userSpiritInfo = slf:generateSpiritInfo(self._spiritID, {isLoadUserStatus = true})
            slf:showSpiritInfo(userSpiritInfo)
        end)
    end):tag(self)
    
end


--[[ 註銷 封包相關 ]]
function Inst:removePacket(opcodes)
    
    -- 從 協定收發代理器中 註銷
    local packetAgent = PacketAgent:inst()
    packetAgent:offAllTag(self)


    -- for key, opcode in pairs(opcodes) do
    --     if string.sub(key, -1) == "S" then
	-- 		self.container:removePacket(opcode)
	-- 	end
    -- end
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (container)
    self._isShowing = true

    local slf = self

    self.container = container

    -- 背景適應
    NodeHelperUZ:fitBGNode(self.container:getVarNode("bgImg"), {
        pivot = ccp(0.5, 0),
        anchorPoint = ccp(0.5, 0),
        ratioSizeFix = CCSizeMake(0, 140),
    })

    -- 取得 分頁列 容器
    self.tabStorageNode = self.container:getVarNode("topNode")

    -- 建立 分頁UI ----------------------------

    -- 初始化
    self.tabStorage = CommTabStorage:new()

    -- 準備分頁資訊
    local tabInfos = {
        {
            iconType = "default",
            icon_normal = "Imagesetfile/Common_UI02/shop_icon_1.png",
            icon_selected = "Imagesetfile/Common_UI02/shop_icon_2.png",
        },
        {
            iconType = "default",
            icon_normal = "Imagesetfile/Common_UI02/shop_icon_1.png",
            icon_selected = "Imagesetfile/Common_UI02/shop_icon_2.png",
        },
    }


    local tabStorageContainer = self.tabStorage:init(tabInfos)

    -- 分頁列間隔
    self.tabStorage:setScrollViewOverrideOptions({
        interval = 20
    })

    -- 設置 當 選中分頁
    self.tabStorage.onTabSelect_fn = function (nextTabIdx, lastTabIdx)
        if nextTabIdx == 1 then

        elseif nextTabIdx == 2 then

        end
    end

    -- 設置 當 關閉
    self.tabStorage.onClose_fn = function ()
        slf:close()
    end

    -- 加入UI
    self.tabStorageNode:addChild(tabStorageContainer)

    -- 預設 選取首個分頁
    self.tabStorage:selectTab(1)

    -- 隱藏標題
    self.tabStorage:setTitleVisible(false)

    -- 隱藏貨幣
    self.tabStorage:setCurrencyDatas({})
    
    -------------------


    -- 建立升級消耗物品
    self.upgradeItemUIs = {}
    for idx = 1, UPGRADE_ITEM_COUNT do
        local commItem = CommItem:new()

        local itemUI = commItem:requestUI()
        itemUI:setAnchorPoint(ccp(0.5, 0.5))
        itemUI:setScale(CommItem.Scales.small)

        local parent = self.container:getVarNode("mUpgradeItemNode"..tostring(idx))
        parent:addChild(itemUI)

        commItem:setShowType(CommItem.ShowType.NORMAL)
        
        self.upgradeItemUIs[idx] = commItem
    end


    -- 註冊 協定
    self:registerPacket(OPCODES)

    if IS_MOCK then
        -- self:showSpiritInfo({
        --     name = "Name",
        --     attrs = {500, 600, 100, 123333333},
        --     star = 5,
        --     skillName = "SkillName",
        --     skillDesc = "Test Test Test",
        --     skillLv = 5,
        --     skillIcon = "Imagesetfile/ItemIcon/2.png",
        --     skillTags = {
        --         {txt = "tag1"}, {txt = "tag2"}, {txt = "tag3"}
        --     },
        --     upgradeItems = {
        --         "10000_1001_55",
        --         "10000_1001_99",
        --         "10000_1001_13",
        --     }
        -- })

        self:showSpiritInfo(self:generateSpiritInfo(503, {
            isLoadUserStatus = true,
            isAddtiveSpriteSoul = true,
        }))
    else 

        -- 若有 準備要顯示的 則 顯示
        if self._showOnEnterSpiritInfo ~= nil then
            self:showSpiritInfo(self._showOnEnterSpiritInfo)
        end
    end
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(container)
    
end

--[[ 當 頁面 離開 ]]
function Inst:onExit(container)
    -- 註銷 協定相關
    self:removePacket(OPCODES)

    -- 清空 技能敘述HTML文字
    self.skillDescHTMLLabel = nil

    -- 呼叫 當離開時的callback
    local toCall = {}
    for idx = 1, #self._onceExitCallbacks do
        toCall[idx] = self._onceExitCallbacks[idx]
    end
    self._onceExitCallbacks = nil
    for idx = 1, #toCall do
        toCall[idx](self._isChanged)
    end

    self._isChanged = false
    self._isShowing = false
end


--[[ 當 細節 按下 ]]
function Inst:onDetailBtn()
    
end

--[[ 當 升級 按下 ]]
function Inst:onUpgradeBtn()

    if self:isUpgradable(self._spiritID) == false then return end

    self:sendRequest_upgrade()
end


-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 關閉 ]]
function Inst:close ()
    -- 關閉 頁面
    PageManager.popPage(PAGE_NAME)
end

--[[ 顯示 精靈細節 ]]
function Inst:commOpen (spiritID, onceExit_fn)
    if self._isShowing then return end
    
    -- 是否 玩家持有精靈資訊
    local spiritStatusInfo = SpiritDataMgr:getUserSpiritStatusInfo(spiritID)

    -- dump(spiritStatusInfo, "Detail spiritStatusInfo")
    local isLoadUserStatus = spiritStatusInfo ~= nil
    
    -- 請求頁面
    local spiritInfo = self:generateSpiritInfo(spiritID, {
        isLoadUserStatus = isLoadUserStatus,
        isAddtiveSpriteSoul = false,
        overwriteInfo = {} -- TODO 讀 滿級表格
    })
    -- 準備要顯示的資料
    -- 因為pushPage後應有非同步行為，所以需要用事先準備的方式設置資料，等開啟時自動抓取資料顯示
    self:prepareSpiritInfo(spiritInfo)
    
    -- 註冊 當離開時
    local slf = self
    self:onceExit(onceExit_fn)

    -- 推送顯示 精靈細節 頁面
    PageManager.pushPage("Spirit.SpiritDetailPage")
end

--[[ 註冊 當離開 單次 ]]
function Inst:onceExit (cb)
    for idx, val in ipairs(self._onceExitCallbacks) do
        if val == cb then return end
    end
    self._onceExitCallbacks[#self._onceExitCallbacks+1] = cb
end

--[[ 準備 顯示精靈資料 ]]
function Inst:prepareSpiritInfo (spiritInfo)
    self._showOnEnterSpiritInfo = spiritInfo
end

--[[ 產生 精靈資訊 ]]
function Inst:generateSpiritInfo (spiritID, options)
    options = options or {}

    -- 取得 精靈 設定
    local spiritCfg = SpiritDataMgr:getSpiritCfg(spiritID)

    -- 是否取用玩家持有的
    local isLoadUserStatus = options["isLoadUserStatus"]
    if isLoadUserStatus == nil then isLoadUserStatus = false end
    -- 是否算進精靈島加成
    local isAddtiveSpriteSoul = options["isAddtiveSpriteSoul"]
    if isAddtiveSpriteSoul == nil then isAddtiveSpriteSoul = true end
    -- 基本資訊
    local baseInfo = options["baseInfo"]
    -- 覆寫資訊
    local overwriteInfo = options["overwriteInfo"]

    -- 取得 精靈 狀態
    local spiritStatusInfo = nil
    if isLoadUserStatus == true then
        spiritStatusInfo = SpiritDataMgr:getUserSpiritStatusInfo(spiritID)
    end

    -- 組成資訊
    local spiritInfo = baseInfo or {}

    -- 辨識
    spiritInfo.spiritID = spiritID
    
    -- 名稱
    spiritInfo.name = SpiritDataMgr:getSpiritName(spiritID)
    
    -- 稀有度
    spiritInfo.rare = spiritCfg.Job
    
    -- Spine
    spiritInfo.spine = spiritCfg.Spine
    
    -- 屬性數值
    local attrID2Val = {}

    -- 技能
    local skill
    
    -- 若 有 玩家持有角色資訊
    if spiritStatusInfo ~= nil then

        -- 角色ID
        spiritInfo.roleID = spiritStatusInfo.roleID

        -- 星數
        spiritInfo.star = spiritStatusInfo.star


        -- 玩家 持有精靈 屬性
        for idx, val in ipairs(spiritStatusInfo.attrs) do
            attrID2Val[val.attr] = val.val
        end
        -- 可選 精靈島 加成
        if isAddtiveSpriteSoul then
            local attr_spriteSoul = SpiritDataMgr:getLevelCfg(self._spriteSoulLevel).attr
            for idx, val in ipairs(attr_spriteSoul) do
                attrID2Val[val.attr] = val.val
            end
        end


        -- 技能
        skill = spiritStatusInfo.skill

        -- 升級資訊
        local upgradeItems = {}

        local curStar = spiritStatusInfo.star
        local curCfg = SpiritDataMgr:getSpiritStarCfg(spiritID, curStar)
        if curCfg ~= nil then
            local costStr = curCfg.Cost
            if costStr ~= "" and costStr ~= nil then
                local costs = common:split(costStr, ",")
                upgradeItems = costs
            end
        end
        spiritInfo.upgradeItems = upgradeItems

    else 
       
        -- 技能
        skill = InfoAccesser:getSkillInfo(spiritCfg.Skills)

        -- 屬性
        attrID2Val[Const_pb.STRENGHT] = spiritCfg.Str
        attrID2Val[Const_pb.INTELLECT] = spiritCfg.Int
        attrID2Val[Const_pb.AGILITY] = spiritCfg.Agi
        attrID2Val[Const_pb.HP] = spiritCfg.Hp
    end
       
    -- 取用 特定屬性
    spiritInfo.attrs = {
        attrID2Val[Const_pb.STRENGHT] or 0, 
        attrID2Val[Const_pb.INTELLECT] or 0, 
        attrID2Val[Const_pb.AGILITY] or 0, 
        attrID2Val[Const_pb.HP] or 0,
    }

    -- 拆解 技能詳細
    spiritInfo.skillLv = skill.level

    local skillInfo = InfoAccesser:getSkillInfo(skill.id)
    -- print(string.format("skill[%s] lv[%s]", skill.id, skill.level))
    if skillInfo == nil then
        -- print(string.format("skill[%s] not exist", tostring(skill.id)))
        return
    end

    spiritInfo.skillName = skillInfo.name
    spiritInfo.skillDesc = skillInfo.desc
    spiritInfo.skillIcon = skillInfo.icon
    -- print("skillInfo.icon:"..tostring(skillInfo.icon))
    spiritInfo.skillTypeTags = skillInfo.typeTags

    -- 若 覆寫資料 存在 則 覆寫
    if overwriteInfo ~= nil then
        for key, val in pairs(overwriteInfo) do
            spiritInfo[key] = val
        end
    end
    
    return spiritInfo
end

    
--[[ 讀取 精靈資訊 ]]
function Inst:showSpiritInfo (spiritInfo)
    
    --[[ 
        要設置的 : 
        
        精靈--
        SPINE

        名稱
        屬性(?)
        職業(?)
        稀有度(SR SSR UR)
        四數值(STR, INT(?), HP, DEX)
        
        升級素材圖標
        升級素材數量

        技能--
        名稱
        圖標
        等級
        說明
        標籤
    --]]

    local skillDescFirstLineOffset = '　　　　'

    local node2Text = {}
    local node2Img = {}
    local node2Visible = {}

    -- ID
    self._spiritID = spiritInfo.spiritID
    self._roleID = spiritInfo.roleID
    
    -- 名稱
    node2Text["mLeaderName"] = common:getLanguageString(spiritInfo.name) or ""

    -- Spine
    local spineParent = self.container:getVarNode("mSpine")
    spineParent:removeAllChildrenWithCleanup(true)
    if spiritInfo.spine ~= nil then
        local spineFolder, spineName = unpack(common:split(spiritInfo.spine, ","))
        local spine = SpineContainer:create(spineFolder, spineName)
        local spineNode = tolua.cast(spine, "CCNode")
        -- print(string.format("SPINE : %s, %s", spineNode:getContentSize().width, spineNode:getContentSize().height))
        spine:runAnimation(1, SPINE_ANIM_NAME, -1)
        spineParent:addChild(spineNode)
    end
    
    -- 屬性
    local attrs = spiritInfo.attrs
    if spiritInfo.attrs == nil then
       attrs = {0,0,0,0}
    end
    node2Text["mStrTxt"] = tostring(attrs[1])
    node2Text["mIntTxt"] = tostring(attrs[2])
    node2Text["mHpTxt"] = tostring(attrs[3])
    node2Text["mDexTxt"] = tostring(attrs[4])

    -- 稀有度
    local rare = spiritInfo.rare
    local tarStar = spiritInfo.star
    for idx = 1, 5 do
        node2Visible["mStarSr"..tostring(idx)] = tarStar == idx and rare == 1
    end
    for idx = 1, 5 do
        node2Visible["mStarSsr"..tostring(idx)] = tarStar == idx and rare == 2
    end
    for idx = 1, 5 do
        node2Visible["mStarUr"..tostring(idx)] = tarStar == idx and rare == 3
    end
   
    -- 技能

    node2Img["mSkillIcon"] = spiritInfo.skillIcon or ""
    node2Text["mSkillNameTxt"] = common:getLanguageString(spiritInfo.skillName) or ""
    node2Text["mSkillLv1"] = common:getLanguageString("@Spirit.Detail.skillLv1", spiritInfo.skillLv) or ""
    node2Text["mSkillLv2"] = tostring(spiritInfo.skillLv) or ""
    
    -- 設置 描述
    -- 嘗試把縮排(空格)插入至p內文前方
    -- WARNING : 若內文有改變則可能無效
    local skillDesc = self:_tryInsertIndentToP(common:getLanguageString(spiritInfo.skillDesc), skillDescFirstLineOffset) or ""
    if self.skillDescHTMLLabel ~= nil then
        self.skillDescHTMLLabel:getParent():removeChild(self.skillDescHTMLLabel, true)
    end
    self.skillDescHTMLLabel = NodeHelper:setCCHTMLLabel(self.container, "mSkillDescTxt", CCSize(600, 90), skillDesc)
    -- or
    -- node2Text["mSkillDescTxt"] = skillDesc

    -- 技能類型標籤
    if spiritInfo.skillTypeTags ~= nil then
        for idx = 1, SKILL_TAG_COUNT do
            local tag = spiritInfo.skillTypeTags[idx]
            local idxStr = tostring(idx)
            node2Visible["mSkillTagNode_"..idxStr] = tag ~= nil
            if tag ~= nil then
                if tag.txt ~= nil then
                    node2Text["mSkillTagTxt_"..idxStr] = common:getLanguageString(tag.txt)
                end
                if tag.img ~= nil then
                    node2Img["mSkillTagImg_"..idxStr] = tag.img
                end
            end
        end
    else
        for idx = 1, SKILL_TAG_COUNT do
            local idxStr = tostring(idx)
            node2Visible["mSkillTagNode_"..idxStr] = false
        end
    end

    -- 升級消耗
    
    local upgradeItems = spiritInfo.upgradeItems or {}

    local infoCount = #upgradeItems
    
    -- dump(upgradeItems, string.format("infoCount[%s]",infoCount))

    for idx = 1, UPGRADE_ITEM_COUNT do
        local idxStr = tostring(idx)
        local infoExist = idx <= infoCount
        
        if infoExist then
            local itemInfo = upgradeItems[idx]
            if type(itemInfo) == "string" then
                itemInfo = InfoAccesser:getItemInfoByStr(itemInfo)
            end

            -- dump(itemInfo, string.format("ItemInfo infoExist[%s]", tostring(infoExist)))
            if itemInfo ~= nil then

                local item = self.upgradeItemUIs[idx]
                item:autoSetByItemInfo(itemInfo)
                item:setShowType(CommItem.ShowType.CLEAR)

                item.onClick_fn = function ()
                    -- dump(itemInfo, "ItemInfo on Click")
                    GameUtil:showTip(item.container, { type = itemInfo.mainType, itemId = itemInfo.itemId })
                end

                local userCount = InfoAccesser:getUserItemCount(itemInfo.itemType, itemInfo.itemId)
                -- print(string.format("user has item[%s] count[%s] needStr[%s]", tostring(itemInfo.itemId), tostring(userCount), tostring(itemInfo.itemId)..":"..tostring(itemInfo.count)))
                node2Text["mUpgradeItemNum"..idxStr] = string.format("%s/%s", tostring(userCount), tostring(itemInfo.count))
            end
        end

        node2Visible["mUpgradeItemNode"..idxStr] = infoExist
    end


    -- 是否可升級
    local isUpgradable = self:isUpgradable(spiritInfo.spiritID)
    NodeHelperUZ:setNodeIsGrayRecursive(self.container:getVarNode("mUpgradeBtnNode"), not isUpgradable)
    self.container:getVarMenuItemImage("mUpgradeBtn"):setEnabled(isUpgradable)


    NodeHelper:setStringForLabel(self.container, node2Text)
    NodeHelper:setSpriteImage(self.container, node2Img)
    NodeHelper:setNodesVisible(self.container, node2Visible)
end

--[[ 是否可以升級 ]]
function Inst:isUpgradable (spiritID)

    -- 取得 精靈 狀態
    local spiritStatusInfo = SpiritDataMgr:getUserSpiritStatusInfo(spiritID)
    if spiritStatusInfo == nil then return false end

    -- 取得 精靈 升星資料
    local starCfg = SpiritDataMgr:getSpiritStarCfg(spiritID, spiritStatusInfo.star)

    if starCfg == nil then
        print(string.format("spirit[%s] star[%s] cfg not exist", spiritID, spiritStatusInfo.star))
        return false
    end

    local costStr = starCfg.Cost
    if costStr == nil or costStr == "" then return false end

    local costs = common:split(costStr, ",")

    for idx, val in ipairs(costs) do
        local userCount = InfoAccesser:getUserItemCountByStr(val)
        local itemInfo = InfoAccesser:getItemInfoByStr(val)
        if userCount < itemInfo.count then
            print(string.format("spirit[%s] upgradeItem needs[%s] user has [%s] not enough", spiritID, itemInfo.count, userCount))
            return false
        end
    end
    return true
end

--[[ 送出請求 升級 ]]
function Inst:sendRequest_upgrade ()
    if self._roleID == nil then return end
    
    local msg = Player_pb.HPRoleUpStar()
    msg.roleId = self._roleID
    common:sendPacket(HP_pb.ROLE_UPGRADE_STAR_C, msg, true)
end

--[[ 送出請求 同步資訊 ]]
function Inst:sendRequest_sync (onDone)
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

    local msg_SYNC_SPRITE_SOUL_C = StarSoul_pb.SyncStarSoul()
    msg_SYNC_SPRITE_SOUL_C.group = 1 -- 理論上 已不需要指定群組

    local packetAgent = PacketAgent:inst()
    Async:parallel({
        -- 請求 玩家持有角色資訊
        function (ctrlr)
            packetAgent:send(
                HP_pb.ROLE_PANEL_INFOS_C, nil, 
                HP_pb.ROLE_PANEL_INFOS_S, function(packet)
                    ctrlr:next()
                end
            )
        end,
        -- 請求 同步精靈島
        function (ctrlr)
            packetAgent:send(
                HP_pb.SYNC_SPRITE_SOUL_C, msg_SYNC_SPRITE_SOUL_C, 
                HP_pb.SYNC_SPRITE_SOUL_S, function(packet)
                    ctrlr:next()
                end
            )
        end,
    }, function ()
        if onDone ~= nil then
            onDone()
        end
    end)
end

function Inst:_tryInsertIndentToP(originalString, insertionString)

    -- local originalString = '<div><p style="margin:8"><div></div> Original content</p></div>'
    -- local insertionString = 'Inserted content. '

    -- Find the position of the opening ">" of the opening <p> tag within the <div> element
    local openingPTagPosition = originalString:find("<p", 1, true)

    if openingPTagPosition then
        local closingPTagPosition = originalString:find("</p>", openingPTagPosition, true)

        if closingPTagPosition then
            -- Find the position of the closing ">" of the opening <div> tag inside the <p> element
            local openingDivTagPosition = originalString:find(">", openingPTagPosition, true)

            if openingDivTagPosition then
                -- Split the original string into three parts: before <p>, inside <p>, and after </p>
                local part1 = originalString:sub(1, openingDivTagPosition)
                local part2 = originalString:sub(openingDivTagPosition + 1, closingPTagPosition - 1)
                local part3 = originalString:sub(closingPTagPosition)

                -- Concatenate the parts along with the insertion string
                local finalString = part1 .. insertionString .. part2 .. part3

                return finalString
            else
                print("No opening > tag found inside the <p> element.")
            end
        else
            print("No closing </p> tag found.")
        end
    else
        print("No opening <p> tag found.")
    end

    return insertionString..originalString

end

local CommonPage = require("CommonPage")
return CommonPage.newSub(Inst, PAGE_NAME, {
    ccbiFile = CCBI_FILE,
    handlerMap = HANDLER_MAP,
    opcode = OPCODES,
})