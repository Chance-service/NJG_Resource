local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "AWTSelectPage"

local UserItemManager = require("Item.UserItemManager")
local PBHelper = require("PBHelper")
local NodeHelper = require("NodeHelper")
local EquipMercenaryPage = require("EquipMercenaryPage")
local UserMercenaryManager = require("UserMercenaryManager")
local GuideManager = require("Guide.GuideManager")
local InfoAccesser = require("Util.InfoAccesser")
local EquipOprHelper = require("Equip.EquipOprHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")

local opcodes = {
    EQUIP_DRESS_S = HP_pb.EQUIP_DRESS_S
}
local UNLOCK_STARLEVEL = {
    3, 6, 9
}
local EquipItem = {
    ccbiFile = "GoodsItem.ccbi",
}
local option = {
    ccbiFile = "AWSystemPage2.ccbi",
    handlerMap =
    {
    },
    opcode = opcodes
}
local RankPic = {
                [1] = {Frame = "AWS_Card_T3.png", Frame2 = "AWS_Img01_T3.png",Bg ="BG/UI/AWS_bg_T3.png" ,Icon = "AWS_Tag_T3.png" },
                [2] = {Frame = "AWS_Card_T2.png",Frame2 = "AWS_Img01_T2.png",Bg ="BG/UI/AWS_bg_T2.png" ,Icon = "AWS_Tag_T2.png" },
                [3] = {Frame = "AWS_Card_T1.png",Frame2 = "AWS_Img01_T1.png",Bg ="BG/UI/AWS_bg_T1.png" ,Icon = "AWS_Tag_T1.png" }
              }
local AWTSelectPageBase = { }
local PageInfo = {
    roleId = 0,
    targetPart = 1,
    currentEquipId = nil,
    selectedEquipId = nil,
    optionIds = { },
    dressType = 1,
    selectedIds = { },
    deepCopySelectedIds = { },
    filterType = EquipFilterType.Dress,
    sortType = 1,
    limit = 1,
    isFull = false,
    callback = nil,
    container = nil,
    ItemNodes = {},
    itemId = 0
}
local CCBI_FILE_CONTENT = "AWTranscendence_SelectedSkillContent.ccbi"
local SkillContent = {}
--[[ 效果解鎖與鎖住的文字顏色 ]]
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
        parent:removeAllChildrenWithCleanup(true)
        if not data.isUnlock then
            str = string.gsub(str, UNLOCK_FONT_COLOR, LOCK_FONT_COLOR)
        end
        NodeHelper:setNodesVisible(self.container,{mTipNode = not data.isUnlock})
        local labChatHtml = NodeHelper:addHtmlLable(parent, str, tonumber(skillDesc), CCSizeMake(560, 80))
    end

    return inst
end


-- AWTSelectPageBase页面中的事件处理
----------------------------------------------
function AWTSelectPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end
function AWTSelectPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container:registerFunctionHandler(AWTSelectPageBase.onFunction)
    PageInfo.container = container

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["AWSystemPage"] = container
    PageManager.pushPage("NewbieGuideForcedPage")
end
function AWTSelectPageBase:setPage(id)
    if id == nil then return end
    local container = PageInfo.container
    local userEquip = UserEquipManager:getUserEquipById(id)
    local equipId = userEquip.equipId
   

    local stringTable = {}
    local nodesVisible = {}
    local spriteImg = {}
   

    --Pic
    local Pic = "UI/AncientWeaponSystem/AWS_"..string.sub(equipId,1,3).."01.jpg"
    spriteImg["mCardPic"] = Pic
    spriteImg["mFullPhoto"] = Pic
    --name&star
    local name, star = "", 1
    if equipId ~= nil then
        name = EquipManager:getNameById(equipId)
        star = EquipManager:getStarById(equipId)
    end
    local nowRank = tonumber (string.sub(equipId,1,1))
    if nowRank < 4 then
         --Effect
          NodeHelper:setNodesVisible(container,{mT2 = nowRank == 2 ,mT3 = nowRank == 1})
        --Bg
        spriteImg["bgImg"] = RankPic[nowRank].Bg
        --Icon
        spriteImg["mIcon"] = RankPic[nowRank].Icon
        --Frame
        NodeHelper:setScale9SpriteImage2(container,{ mFrame2 = RankPic[nowRank].Frame2})
        spriteImg["mFrame"] = RankPic[nowRank].Frame
    else
         NodeHelper:setNodesVisible(container,{mT2 = false ,mT3 = true})
        --Bg
        spriteImg["bgImg"] = "AWS_bg_T"..nowRank..".png"
        --Icon
        spriteImg["mIcon"] = "AWS_Tag_T"..nowRank..".png"
        --Frame
        NodeHelper:setScale9SpriteImage2(container,{ mFrame2 = "AWS_Card_T"..nowRank..".png"})
        spriteImg["mFrame"] = "AWS_Img01_T"..nowRank..".png"
    end
    local function SetScale9Size (name,x,y) 
        local sprite=tolua.cast(container:getVarNode(name), "CCScale9Sprite")
        if sprite then
            sprite:setContentSize(CCSizeMake(x,y))
        end
    end
    SetScale9Size("mFrame",647,800)
    SetScale9Size("mFrame2",726,1286)

    stringTable["equipNameTxt"] = name
    -- 初始化所有節點為不可見
    nodesVisible["mStarSrNode"] = false
    nodesVisible["mStarSsrNode"] = false
    nodesVisible["mStarUrNode"] = false
    
    -- 根據星級設定節點狀態
    if star <= 5 then
        nodesVisible["mStarSrNode"] = true
        for i = 1, 5 do
            nodesVisible["mStarSr" .. i] = (star == i)
        end
    elseif star <= 10 then
        nodesVisible["mStarSsrNode"] = true
        for i = 1, 5 do
            nodesVisible["mStarSsr" .. i] = (star == i + 5)
        end
    else
        nodesVisible["mStarUrNode"] = true
        for i = 1, 5 do
            nodesVisible["mStarUr" .. i] = (star == i + 10)
        end
    end
    
    --Attr
     local levelsAttrs = { }
     local name_num_attr_list = UserEquipManager:getMainAttrStrAndNum(userEquip)
     for idx = 1, #name_num_attr_list do
         local each = name_num_attr_list[idx]
         local attrInfo = InfoAccesser:getAttrInfo(each[3], each[2])
         levelsAttrs[#levelsAttrs+1] = attrInfo
     end
     for i = 1 , 2 do
        spriteImg["curStarAttrValIcon_"..i] = levelsAttrs[i].icon
        stringTable["curStarAttrValName_"..i] = levelsAttrs[i].name
        stringTable["curStarAttrValTxt_"..i] = "+"..levelsAttrs[i].val
     end
     local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
     local awRoleId = AncientWeaponDataMgr:getEquipHero(equipId)
     if PageInfo.itemId == tonumber(awRoleId) then
        nodesVisible["mNotice"] = false
     else
        nodesVisible["mNotice"] = true
     end
     stringTable["mNoticeTxt"] = common:getLanguageString("@EquipCondition", common:getLanguageString("@HeroName_" .. awRoleId))
     stringTable["curLvNum"] = userEquip.strength
     --Skill
     self:loadEquipSkills (userEquip)
     local skillName = { }
     for i = 1 ,3 do
        if self.skillEffects[i].isUnlock then
            nodesVisible["mLock"..i] = false
            nodesVisible["mUnlock"..i] = true
            stringTable["mUnlockTxt"..i] = ""
            NodeHelper:setStringForLabel(container,stringTable)
            local freeTypeCfg = FreeTypeConfig[math.floor(tonumber(self.skillEffects[i].skillDesc))]
            local str = common:fill(freeTypeCfg and freeTypeCfg.content or "xxx")
            local parent = container:getVarNode("mUnlockTxt"..i)
            parent:removeAllChildrenWithCleanup(true)
            local labChatHtml = NodeHelper:addHtmlLable(parent, str, tonumber(skillDesc), CCSizeMake(560, 80),parent)
        else
            nodesVisible["mLock"..i] = true
            nodesVisible["mUnlock"..i] = false
            stringTable["mLockTxt"..i] = self.skillEffects[i].unlockDesc
        end
     end

     NodeHelper:setNodesVisible(container,nodesVisible)
     NodeHelper:setSpriteImage(container,spriteImg)
     NodeHelper:setStringForLabel(container,stringTable)

    local bg = container:getVarNode("bgImg")
    if bg then
        bg:setScale(NodeHelper:getScaleProportion())
    end
end
function AWTSelectPageBase:loadEquipSkills (userEquip)

    local slf = self

    local equipCfg = ConfigManager.getEquipCfg()[userEquip.equipId]
    local roleEquipID = equipCfg.mercenarySuitId

    self.skillEffects = {}

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

    self.skillEffectsScrollView = PageInfo.container:getVarScrollView("equipEffectsScrollView")
    --self.skillEffectsScrollView:removeAllChildrenWithCleanup(true)
    local children =  self.skillEffectsScrollView:getChildren()
    NodeHelper:deleteScrollView(PageInfo.container)
    NodeHelper:initScrollView(PageInfo.container, "equipEffectsScrollView", #self.skillEffects)

    --[[ 滾動視圖 上至下 ]]
    NodeHelperUZ:buildScrollViewVertical(
        PageInfo.container,
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
            paddingTop = 90,
            paddingLeft = 5,
            originScrollViewSize = CCSizeMake(640, 750),
            isDisableTouchWhenNotFull = true,
            startOffsetAtItemIdx = 1,
            isBounceable = false,
        }
    )
end

function AWTSelectPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function AWTSelectPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
function AWTSelectPageBase:setCurrentEquipId()
    local roleEquip = UserMercenaryManager:getEquipByPart(PageInfo.roleId, 10)
    PageInfo.currentEquipId = roleEquip and roleEquip.equipId or nil

    -- 根據裝備狀態設定 dressType
    if PageInfo.currentEquipId then
        PageInfo.dressType = (PageInfo.currentEquipId ~= PageInfo.selectedEquipId) and 
                             GameConfig.DressEquipType.Change or 
                             GameConfig.DressEquipType.Off
    else
        PageInfo.dressType = GameConfig.DressEquipType.On
    end

    -- 根據 dressType 設定按鈕文字
    local dressTypeTextMap = {
        [GameConfig.DressEquipType.Change] = "@Replace",
        [GameConfig.DressEquipType.On] = "@Equip",
        [GameConfig.DressEquipType.Off] = "@TakeOff"
    }
    local txt = common:getLanguageString(dressTypeTextMap[PageInfo.dressType])

    -- 更新 UI 標籤文字
    NodeHelper:setStringForLabel(PageInfo.container, {mBtnTxt = txt})
end


function AWTSelectPageBase:setOptionIds()
    PageInfo.optionIds = { }

    local filterType = PageInfo.filterType

    local ids = { }

    ids = UserEquipManager:getEquipIdsByClass("Part", 10)
    -- filter
    local roleProf = nil
    if filterType == EquipFilterType.Dress then
        if PageInfo.roleId == UserInfo.roleInfo.roleId then
            roleProf = UserInfo.roleInfo.prof
        else
            roleProf = UserMercenaryManager:getProfessioinIdByPart(PageInfo.roleId, PageInfo.targetPart)
        end
    end
    for _, id in ipairs(ids) do
        local isOk = false
        local isSame = PageInfo.currentEquipId ~= nil and PageInfo.currentEquipId == id
        if not isSame and not UserEquipManager:isEquipDressed(id) then
            if filterType == EquipFilterType.Dress then
                local userEquip = UserEquipManager:getUserEquipById(id)
                if EquipManager:isDressable(userEquip.equipId, roleProf) then
                    isOk = true
                end
            else
                isOk = true
            end
        end
        if isOk then
            table.insert(PageInfo.optionIds, id)
        end
    end

    -- sort
    table.sort(PageInfo.optionIds, sortEquipByScore)

    if #PageInfo.optionIds > 0 then return true end
end
function AWTSelectPageBase:initScrollview(container)
    local mScrollView = container:getVarScrollView("mItemScrollview")
    mScrollView:removeAllCell()
    local count = 0
    if PageInfo.currentEquipId then
        local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
        local userEquip = UserEquipManager:getUserEquipById(PageInfo.currentEquipId)
        local equipId = userEquip.equipId
        local cell = CCBFileCell:create()
        cell:setCCBFile(EquipItem.ccbiFile)
        cell:setScale(0.9)
        cell:setContentSize(CCSizeMake(134, 134))
        local panel = common:new( { id= PageInfo.currentEquipId }, EquipItem)
        cell:registerFunctionHandler(panel)
        mScrollView:addCell(cell)
        count = count + 1
    end
    for key, value in pairs (PageInfo.optionIds) do
        local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
        local userEquip = UserEquipManager:getUserEquipById(value)
        local equipId = userEquip.equipId
        local isTargetRoleEquip = AncientWeaponDataMgr:getIsTargetHeroEquip(equipId, PageInfo.itemId)
        if isTargetRoleEquip then
            local cell = CCBFileCell:create()
            cell:setCCBFile(EquipItem.ccbiFile)
            cell:setScale(0.9)
            cell:setContentSize(CCSizeMake(134, 134))
            local panel = common:new( { id=value }, EquipItem)
            cell:registerFunctionHandler(panel)
            mScrollView:addCell(cell)
            count = count + 1
        end
    end
    --if count <= 0 then
    --    NodeHelper:setStringForLabel(container,{mNoEquip = common:getLanguageString("@ExclusiveEquip_Missing2")})
    --else
        NodeHelper:setStringForLabel(container,{mNoEquip = ""})
    --end
    mScrollView:orderCCBFileCells()
    if count > 4 then
        mScrollView:setTouchEnabled(true)
    else
        mScrollView:setTouchEnabled(false)
    end
end
function AWTSelectPageBase.onFunction(eventName,container)
    if eventName == "luaLoad" then
        AWTSelectPageBase:onLoad(container)
    elseif eventName == "luaEnter" then
        AWTSelectPageBase:onEnter(container)
    elseif eventName == "luaGameMessage" then
        AWTSelectPageBase:onReceiveMessage(container)
    elseif eventName == "onCard" then
        --NodeHelper:setNodesVisible(container,{nFullNode = true})
        container:runAnimation("OpenCard")
    elseif eventName == "onExitFull" then
         --NodeHelper:setNodesVisible(container,{nFullNode = false})
         container:runAnimation("CloseCard")
    elseif eventName == "onSkill" then
         NodeHelper:setNodesVisible(container,{mSkill = true})
         AWTSelectPageBase:initScrollview(container)
    elseif eventName == "onExitSkill" then
        NodeHelper:setNodesVisible(container,{mSkill = false})
    elseif eventName == "onReturnBtn" then
        PageManager.popPage(thisPageName)
        NodeHelper:deleteScrollView(PageInfo.container)
    elseif eventName == "onTakeOff" then
        local userEquipId = PageInfo.currentEquipId
        local dressType = GameConfig.DressEquipType.Off
        EquipOprHelper:dressEquip(userEquipId, PageInfo.roleId, dressType)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
        NodeHelper:deleteScrollView(PageInfo.container)
        PageManager.popPage(thisPageName)
    elseif eventName == "onChange" then
        NodeHelper:setNodesVisible(container,{mChangNode = false,mItemNode = true,mEquipBtn = true})
        AWTSelectPageBase:initScrollview(container)
    elseif eventName == "onEquip" then
        if PageInfo.dressType == GameConfig.DressEquipType.Off then
            local userEquipId = PageInfo.currentEquipId
            EquipOprHelper:dressEquip(userEquipId, PageInfo.roleId, PageInfo.dressType)
            common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
            NodeHelper:deleteScrollView(PageInfo.container)
            PageManager.popPage(thisPageName)
        else
            if PageInfo.selectedEquipId then         
                EquipOprHelper:dressEquip(PageInfo.selectedEquipId, PageInfo.roleId, PageInfo.dressType)
                NodeHelper:deleteScrollView(PageInfo.container)
                PageManager.popPage(thisPageName)
            end
        end
    elseif eventName == "onStarUp" then
        --require("AncientWeapon.AncientWeaponPage"):prepare(PageInfo.selectedEquipId)
        --PageManager.pushPage("AncientWeapon.AncientWeaponPage")
        local AWT_StarUpPage = require "AncientWeaponSubPage_StarUpNew"
        AWT_StarUpPage:setNowId(PageInfo.selectedEquipId)
        PageManager.pushPage("AncientWeaponSubPage_StarUpNew")
    elseif eventName == "onLevelUp" then
         local AWT_LevelUpPage = require "AncientWeaponSubPage_LevelUpNew"
        AWT_LevelUpPage:setNowId(PageInfo.selectedEquipId)
        PageManager.pushPage("AncientWeaponSubPage_LevelUpNew")
    end
end

function EquipItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    container:getVarNode("mNode"):setPosition(ccp(67,67))
    local userEquipId = self.id
    local userEquip = UserEquipManager:getUserEquipById(userEquipId)
    local equipId = userEquip.equipId
    PageInfo.ItemNodes[self.id] = container
    if self.id == PageInfo.selectedEquipId then
        NodeHelper:setNodesVisible(container,{mTapping = true})
    end
    if self.id == PageInfo.currentEquipId then
        NodeHelper:setNodesVisible(container,{mWearing = true})
    else
        NodeHelper:setNodesVisible(container,{mWearing = false})
    end

    local lb2Str = {
        mNumber = ""
    }
    local showName = ""

    NodeHelper:setNodesVisible(container, { mStarNode = false })
    
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, { mPic = "NG_E_"..string.sub(equipId,1,3).."01.png"  }, { mPic = 1 })
    NodeHelper:setNodesVisible(container, { mName = false })
    local equipCfg = ConfigManager.getEquipCfg()[equipId]
    NodeHelper:setQualityFrames(container, { mHand = equipCfg.quality })
end
function EquipItem:onHand(container)
    if PageInfo.selectedEquipId == self.id then return end
    for id,node in pairs(PageInfo.ItemNodes) do
        NodeHelper:setNodesVisible(node,{mTapping = id == self.id })
    end
    AWTSelectPageBase:setPage(self.id)
    PageInfo.selectedEquipId = self.id
    AWTSelectPageBase:setCurrentEquipId()
end

function AWTSelectPage_setPart(part, roleId,itemId)
    PageInfo.targetPart = part
    PageInfo.roleId = roleId
    PageInfo.itemId = itemId

    AWTSelectPageBase:setCurrentEquipId()
    AWTSelectPageBase:setOptionIds()
    local userEquipId = PageInfo.currentEquipId or 0
    if userEquipId == 0 then
        for key, value in pairs (PageInfo.optionIds) do
            local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
            local userEquip = UserEquipManager:getUserEquipById(value)
            local equipId = userEquip.equipId
            local isTargetRoleEquip = AncientWeaponDataMgr:getIsTargetHeroEquip(equipId, PageInfo.itemId)
            if isTargetRoleEquip then
                userEquipId = value
                break
            end
        end
    end
    
    PageInfo.selectedEquipId = userEquipId
    --if PageInfo.currentEquipId then
    --    PageInfo.selectedEquipId = PageInfo.currentEquipId
    --    NodeHelper:setNodesVisible(PageInfo.container,{mChangNode = false,mItemNode = true,mEquipBtn = true})
    --    userEquipId = PageInfo.currentEquipId
    --else
    --    NodeHelper:setNodesVisible(PageInfo.container,{mChangNode = false,mItemNode = true,mEquipBtn = true})
    --    AWTSelectPageBase:initScrollview(PageInfo.container)
    --end
    NodeHelper:setNodesVisible(PageInfo.container,{mChangNode = false,mItemNode = true,mEquipBtn = true})
    AWTSelectPageBase:initScrollview(PageInfo.container)
    AWTSelectPageBase:setPage(userEquipId)

end		

--[[ 當 收到訊息 ]]
function AWTSelectPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "AWTSelectPage" then
            if extraParam == "refreshInfo" then
                AWTSelectPageBase:setPage(PageInfo.selectedEquipId)
            end
        end
    end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")

local AWTSelectPage = CommonPage.newSub(AWTSelectPageBase, thisPageName, option)

return AWTSelectPage


