local HP_pb = require("HP_pb")
local thisPageName = "HeroSkillPage"
local PAGE_INFO = {
    FREETYPE_BUFF_BASE_ID = 0,
    TAG_MAX_NUM = 3,    -- tag最大數量
    SKILL_LEVEL_NUM = 3,-- 技能有幾階
    BASE_SKILL_ID = 0,  -- 技能id(沒有等級)
    SKILL_NUM = 0,      -- 第幾招技能
    SKILL_LEVEL = 0,    -- 技能等級
    ROLE_LEVEL = 0,     -- 角色等級
    ROLE_STAR = 0,      -- 角色星數
    BUFF_LIST = { },    -- 技能buff列表
    ALL_LEVEL_BUFF_LIST = { },  -- 該技能所有等級buff列表
    TAG_LIST = { },     -- 技能tag列表
    SCROLLVIEW_VIEWWIDTH = 0,
    SCROLLVIEW_VIEWHEIGHT = 0,
    SCROLLVIEW_POSY = 0,
    SKILL_CONTENT_SHIFT = 35,
    HTML_TAG = 891,
    UNLOCK_FONT_COLOR = "#763306",
    LOCK_FONT_COLOR = "#7F7F7F",
    ROLEID=0,
    ITEMID=0,
}
local SKILL_LEVEL_LIMIT = {
    1, 21, 61, 100
}
local SKILL_LEVEL_MESSAGE_KEY = {   -- 用skill_num當作key
    [2] = "@HeroSkillUnlock1",
    [3] = "@HeroSkillUnlock2",
    [4] = "@HeroSkillUnlock_equip1",
}
local SKILL_STAR_LIMIT = {   -- 用skill_num * 10 + skill_level當作key
    [11] = 1,[12] = 6, [13] = 10,
    [21] = 1,[22] = 7, [23] = 11,
    [31] = 1,[32] = 8, [33] = 12,
    [41] = 1,[42] = 6, [43] = 11,

}
local SKILL_STAR_MESSAGE_KEY = {   -- 用skill_num * 10 + skill_level當作key
    [11] = "",[12] = "@HeroSkillUpgrade1", [13] = "@HeroSkillUpgrade10",
    [21] = "",[22] = "@HeroSkillUpgrade2", [23] = "@HeroSkillUpgrade11",
    [31] = "",[32] = "@HeroSkillUpgrade3", [33] = "@HeroSkillUpgrade12",
    [41] = "@HeroSkillUnlock_equip1",[42] = "@HeroSkillUnlock_equip2", [43] = "@HeroSkillUnlock_equip3",   
}
local opcodes = {
}
local option = {
    ccbiFile = "SkillPage.ccbi",
    handlerMap =
    {
        onClose = "onReturn",
    },
    opcode = opcodes
}

local HeroSkillPage = { }
local skillCfg = ConfigManager.getSkillCfg()
-----------------------------------
local HeroSkillDescItem = {
    ccbiFile = "SkillContent.ccbi",
}
local HeroSkillBuffItem = {
    ccbiFile = "SkillContent_2.ccbi",
}
local HeroSkillImgItem = {
    ccbiFile = "SkillContent_3.ccbi",
}
-----------------------------------
function HeroSkillPage:refreshBuffItem(container, buffId)
    if container == nil then
        return
    end
    -- ICON
    local mainBuffId = buffId and math.floor(tonumber(buffId) / 100) % 100 or 0
    NodeHelper:setSpriteImage(container, { mBuffImg = "Buff/Buff_" .. buffId .. ".png" })
    -- NAME
    NodeHelper:setStringForLabel(container, {
        mBuffName = common:getLanguageString("@Buff_" .. string.format(buffId))
    })
    -- 
    NodeHelper:setNodesVisible(container, { mBuffImg = (tonumber(buffId) > 0), mBuffName = (tonumber(buffId) > 0) })
    -- Buff說明
    local freeTypeId = PAGE_INFO.FREETYPE_BUFF_BASE_ID + buffId
    local skillDesNode = container:getVarNode("mContentNode")
    skillDesNode:removeAllChildren()
    local htmlLabel = CCHTMLLabel:createWithString((FreeTypeConfig[freeTypeId] and FreeTypeConfig[freeTypeId].content or ""),
                                                   CCSizeMake(PAGE_INFO.SCROLLVIEW_VIEWWIDTH - PAGE_INFO.SKILL_CONTENT_SHIFT * 2, 50), "Barlow-SemiBold")
    local htmlSize = htmlLabel:getContentSize()
    htmlLabel:setPosition(ccp(PAGE_INFO.SKILL_CONTENT_SHIFT, 0))
    htmlLabel:setAnchorPoint(ccp(0, 0))
    skillDesNode:addChild(htmlLabel)
    htmlLabel:setTag(PAGE_INFO.HTML_TAG)
    return self:resizeBuffItem(container)
end

function HeroSkillPage:resizeBuffItem(container)
    local titleNode = container:getVarNode("mTopNode")
    local contentNode = container:getVarNode("mContentNode")
    local htmlLabe = contentNode:getChildByTag(PAGE_INFO.HTML_TAG)

    local txtHeight = htmlLabe:getContentSize().height
    contentNode:setContentSize(CCSize(contentNode:getContentSize().width, txtHeight))
    titleNode:setPositionY(txtHeight)
    container:setContentSize(CCSize(container:getContentSize().width, txtHeight + titleNode:getContentSize().height))

    return container:getContentSize().height
end

function HeroSkillPage:refreshSkillItem(container, level)
    -- 檢查容器是否存在，避免後續報錯
    if not container then return end

    -- 設置技能等級文字
    NodeHelper:setStringForLabel(container, {
        mSkillLvTxt = common:getLanguageString("@LevelStr", string.format(level))
    })

    -- 生成技能完整ID並清空技能描述節點
    local skillFullId = tonumber(PAGE_INFO.BASE_SKILL_ID .. level)
    local skillDesNode = container:getVarNode("mContentNode")
    skillDesNode:removeAllChildren()
    
    -- 獲取技能HTML內容
    local htmlStr = FreeTypeConfig[skillFullId] and FreeTypeConfig[skillFullId].content or ""
    local tipStr = nil

    -- 檢查技能解鎖條件
    if PAGE_INFO.SKILL_NUM ~= 4 then
        -- 一般技能檢查
        if level == 1 and PAGE_INFO.ROLE_LEVEL < SKILL_LEVEL_LIMIT[PAGE_INFO.SKILL_NUM] then
            -- 角色等級不足，設定鎖定樣式和提示文字
            htmlStr = string.gsub(htmlStr, PAGE_INFO.UNLOCK_FONT_COLOR, PAGE_INFO.LOCK_FONT_COLOR)
            tipStr = SKILL_LEVEL_MESSAGE_KEY[PAGE_INFO.SKILL_NUM]
        elseif PAGE_INFO.ROLE_STAR < SKILL_STAR_LIMIT[PAGE_INFO.SKILL_NUM * 10 + level] then
            -- 星數不足，設定鎖定樣式和提示文字
            htmlStr = string.gsub(htmlStr, PAGE_INFO.UNLOCK_FONT_COLOR, PAGE_INFO.LOCK_FONT_COLOR)
            tipStr = SKILL_STAR_MESSAGE_KEY[PAGE_INFO.SKILL_NUM * 10 + level]
        elseif PAGE_INFO.ROLE_LEVEL < SKILL_LEVEL_LIMIT[PAGE_INFO.SKILL_NUM] then
            -- 等級不足，設定鎖定樣式和提示文字
            htmlStr = string.gsub(htmlStr, PAGE_INFO.UNLOCK_FONT_COLOR, PAGE_INFO.LOCK_FONT_COLOR)
            tipStr = SKILL_LEVEL_MESSAGE_KEY[PAGE_INFO.SKILL_NUM]
        end
    else
        -- 專武技能檢查
        local UserMercenaryManager = require("UserMercenaryManager")
        local roleEquip = PAGE_INFO.ROLEID and UserMercenaryManager:getEquipByPart(PAGE_INFO.ROLEID, 10) or nil
        local LimitIdx = PAGE_INFO.SKILL_NUM * 10 + level
        if not roleEquip then
            -- 未裝備專武，設定鎖定樣式和提示文字
            htmlStr = string.gsub(htmlStr, PAGE_INFO.UNLOCK_FONT_COLOR, PAGE_INFO.LOCK_FONT_COLOR)
            tipStr = SKILL_STAR_MESSAGE_KEY[LimitIdx]
        else
            -- 驗證裝備的星數和對應條件
            local equipId = roleEquip.equipItemId
            local InfoAccesser = require("Util.InfoAccesser")
            local parsedEquip = InfoAccesser:parseAWEquipStr(equipId)
            local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
            if AncientWeaponDataMgr:getIsTargetHeroEquip(equipId, PAGE_INFO.ITEMID) then -- 穿著自己的專武
                -- 檢查T3專武&專武星數
                if parsedEquip.star < SKILL_STAR_LIMIT[LimitIdx] or tonumber(string.sub(equipId, 1, 1)) ~= 1 then
                    htmlStr = string.gsub(htmlStr, PAGE_INFO.UNLOCK_FONT_COLOR, PAGE_INFO.LOCK_FONT_COLOR)
                    tipStr = SKILL_STAR_MESSAGE_KEY[LimitIdx]
                end
            else
                -- 穿著非對應的專武，設定鎖定樣式和提示文字
                htmlStr = string.gsub(htmlStr, PAGE_INFO.UNLOCK_FONT_COLOR, PAGE_INFO.LOCK_FONT_COLOR)
                tipStr = SKILL_STAR_MESSAGE_KEY[LimitIdx]
            end
        end
    end

    -- 顯示技能描述內容
    local htmlLabel = CCHTMLLabel:createWithString(htmlStr, 
        CCSizeMake(PAGE_INFO.SCROLLVIEW_VIEWWIDTH - PAGE_INFO.SKILL_CONTENT_SHIFT * 2, 50), 
        "Barlow-SemiBold")
    htmlLabel:setPosition(ccp(PAGE_INFO.SKILL_CONTENT_SHIFT, 0))
    htmlLabel:setAnchorPoint(ccp(0, 0))
    skillDesNode:addChild(htmlLabel)
    htmlLabel:setTag(PAGE_INFO.HTML_TAG)

    -- 更新提示文字
    NodeHelper:setStringForLabel(container, { mTipTxt = common:getLanguageString(tipStr or "") })
    
    -- 調整技能項目大小
    return self:resizeSkillItem(container, tipStr)
end



function HeroSkillPage:resizeSkillItem(container, tipStr)
    local titleNode = container:getVarNode("mTopNode")
    local contentNode = container:getVarNode("mContentNode")
    local tipNode = container:getVarNode("mTipNode")
    local bottomNode = container:getVarNode("mBottomNode")
    local bg = container:getVarScale9Sprite("mBg")
    local htmlLabe = contentNode:getChildByTag(PAGE_INFO.HTML_TAG)

    local txtHeight = htmlLabe:getContentSize().height
    local tipHeight = tipStr and tipNode:getContentSize().height or 0
    contentNode:setPositionY(bottomNode:getContentSize().height + tipHeight)
    contentNode:setContentSize(CCSize(contentNode:getContentSize().width, txtHeight))
    titleNode:setPositionY(txtHeight + bottomNode:getContentSize().height + tipHeight)
    container:setContentSize(CCSize(container:getContentSize().width, txtHeight + bottomNode:getContentSize().height + titleNode:getContentSize().height + tipHeight))

    bg:setContentSize(CCSize(bg:getContentSize().width, txtHeight + bottomNode:getContentSize().height + titleNode:getContentSize().height + tipHeight))

    return container:getContentSize().height
end

function HeroSkillPage:onEnter(container)
    self:refreshSkillInfo(container)
    self:initScrollView(container)
    self:refreshScrollView(container)
end
-- ScrollView初始化
function HeroSkillPage:initScrollView(container)
    NodeHelper:initScrollView(container, "mContent", 10)
    PAGE_INFO.SCROLLVIEW_VIEWWIDTH = container.mScrollView:getViewSize().width
    PAGE_INFO.SCROLLVIEW_VIEWHEIGHT = container.mScrollView:getViewSize().height
    PAGE_INFO.SCROLLVIEW_POSY = container.mScrollView:getPositionY()
end
-- 刷新技能資訊
function HeroSkillPage:refreshSkillInfo(container)
    -- LEVEL
    NodeHelper:setStringForLabel(container, { mSkillLv = PAGE_INFO.SKILL_LEVEL })
    -- ICON
    NodeHelper:setSpriteImage(container, { mSkillImg = "skill/S_" .. PAGE_INFO.BASE_SKILL_ID .. ".png" })
    -- NAME
    NodeHelper:setStringForLabel(container, { mSkillName = common:getLanguageString("@Skill_Name_" .. PAGE_INFO.BASE_SKILL_ID)})
    -- TAG
    for i = 1, PAGE_INFO.TAG_MAX_NUM do
        NodeHelper:setNodesVisible(container, { ["mTagNode" .. i] = PAGE_INFO.TAG_LIST[i] and true or false })
        if PAGE_INFO.TAG_LIST[i] then
            NodeHelper:setStringForLabel(container, { ["mTag" .. i] = common:getLanguageString("@Skill_Type_" .. PAGE_INFO.TAG_LIST[i])})
        end
    end
end
-- 刷新滾動層內容
function HeroSkillPage:refreshScrollView(container)
    container.mScrollView:removeAllCell()
    container.m_pScrollViewFacade:clearAllItems()
    local nowHeight = 0
    -----------------------------------------
    -- BUFF
    for i = 1, #PAGE_INFO.ALL_LEVEL_BUFF_LIST do
        local id = PAGE_INFO.ALL_LEVEL_BUFF_LIST[i]
        if tonumber(id) and tonumber(id) > 0 then
            local pItemData = CCReViSvItemData:new_local()
            local pItem = ScriptContentBase:create(HeroSkillBuffItem.ccbiFile)
            local itemHeight = self:refreshBuffItem(pItem, tonumber(id))
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
            pItemData.m_ptPosition = ccp(0, nowHeight)
            nowHeight = nowHeight + itemHeight
        end
    end
    -----------------------------------------
    -- IMG
    local pItemData = CCReViSvItemData:new_local()
    local pItem = ScriptContentBase:create(HeroSkillImgItem.ccbiFile)
    container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
    pItemData.m_ptPosition = ccp(0, nowHeight)
    nowHeight = nowHeight + pItem:getContentSize().height
    -----------------------------------------
    -- SKILL
    for i = PAGE_INFO.SKILL_LEVEL_NUM, 1, -1 do
        local pItemData = CCReViSvItemData:new_local()
        local pItem = ScriptContentBase:create(HeroSkillDescItem.ccbiFile)
        pItem.skillId = tonumber(PAGE_INFO.BASE_SKILL_ID .. i)
        local itemHeight = self:refreshSkillItem(pItem, i)
        container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        pItemData.m_ptPosition = ccp(0, nowHeight)
        nowHeight = nowHeight + itemHeight
    end
    -----------------------------------------
    container.mScrollView:setContentSize(CCSize(PAGE_INFO.SCROLLVIEW_VIEWWIDTH, nowHeight))
    container.mScrollView:setViewSize(CCSize(PAGE_INFO.SCROLLVIEW_VIEWWIDTH, math.min(nowHeight, PAGE_INFO.SCROLLVIEW_VIEWHEIGHT)))
    container.mScrollView:setContentOffset(ccp(0, nowHeight >= PAGE_INFO.SCROLLVIEW_VIEWHEIGHT and PAGE_INFO.SCROLLVIEW_VIEWHEIGHT - nowHeight or 0))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(0)
    container.mScrollView:forceRecaculateChildren()
    container.mScrollView:setTouchEnabled(nowHeight > PAGE_INFO.SCROLLVIEW_VIEWHEIGHT)
    container.mScrollView:setPositionY(nowHeight >= PAGE_INFO.SCROLLVIEW_VIEWHEIGHT and PAGE_INFO.SCROLLVIEW_POSY 
                                       or (PAGE_INFO.SCROLLVIEW_POSY + (PAGE_INFO.SCROLLVIEW_VIEWHEIGHT - nowHeight)))
end

function HeroSkillPage:onReturn(container)
    PageManager.popPage(thisPageName)
end

function HeroSkillPage_setPageRoleInfo(level, star,roleId,itemId)
    PAGE_INFO.ROLE_LEVEL = level
    PAGE_INFO.ROLE_STAR = star
    PAGE_INFO.ROLEID=roleId
    PAGE_INFO.ITEMID=itemId
end

function HeroSkillPage_setPageSkillId(id)
    PAGE_INFO.BASE_SKILL_ID = string.sub(tostring(id), 1, 4)
    PAGE_INFO.SKILL_NUM = tonumber(string.sub(tostring(id), 4, 4) + 1)
    PAGE_INFO.BUFF_LIST = common:split(skillCfg[id].buff, ",")
    PAGE_INFO.FULL_SKILL_ID = tonumber(PAGE_INFO.BASE_SKILL_ID .. ((PAGE_INFO.SKILL_LEVEL == 0) and 1 or PAGE_INFO.SKILL_LEVEL))
    PAGE_INFO.ALL_LEVEL_BUFF_LIST = { }
    local baseSkillId = math.floor(id / 10)
    for i = 1, 9 do
        local fullSkillId = baseSkillId * 10 + i
        if skillCfg[fullSkillId] then
            local buff = common:split(skillCfg[fullSkillId].buff, ",")
            for k, v in pairs(buff) do
                local inTable = false
                for j = 1, #PAGE_INFO.ALL_LEVEL_BUFF_LIST do
                    if PAGE_INFO.ALL_LEVEL_BUFF_LIST[j] == tonumber(v) then
                        inTable = true
                    end
                end
                if not inTable then
                    table.insert(PAGE_INFO.ALL_LEVEL_BUFF_LIST, tonumber(v))
                end
            end
        else
            break
        end
    end
    table.sort(PAGE_INFO.ALL_LEVEL_BUFF_LIST, function(a, b)
	    if a > b then
            return true
	    end
        return false
    end)
    PAGE_INFO.TAG_LIST = common:split(skillCfg[PAGE_INFO.FULL_SKILL_ID].tagType, ",")
end

function HeroSkillPage_setPageSkillLevel(lv)
    PAGE_INFO.SKILL_LEVEL = lv
end

local CommonPage = require('CommonPage')
local HeroSkillPage = CommonPage.newSub(HeroSkillPage, thisPageName, option)
