local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")
local EventDataMgr = require("Event001DataMgr")

local thisPageName = "Event001RewardPopUp"

local opcodes = {
}

local option = {
    ccbiFile = EventDataMgr[EventDataMgr.nowActivityId].REWARD_POPUP_CCB,
    handlerMap =
    {
        onClose = "onClose",
    },
    opcode = opcodes
}

local REWARD_EQUIP_ID = EventDataMgr[EventDataMgr.nowActivityId].REWARD_EQUIP_ID   -- 讀表or每次活動調整
local FREETYPE_FONT_COLOR = "#763306" -- FreeType原始文字顏色
local UI_FONT_COLOR = "#FFFFFF" -- UI文字顏色

local Event001RewardPopUp = { }

-----------------------------------
function Event001RewardPopUp.onFunction(eventName, container)
    if eventName == "luaLoad" then
        Event001RewardPopUp:onLoad(container)
    elseif eventName == "luaEnter" then
        Event001RewardPopUp:onEnter(container)
    elseif eventName =="onClose" then
        Event001RewardPopUp:onClose(container)
    end
end

function Event001RewardPopUp:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function Event001RewardPopUp:onEnter(container)
    self.container = container
    self:refreshPage(container)
end
function Event001RewardPopUp:onClose(container)
    PageManager.popPage(thisPageName)
end
-- 刷新內容
function Event001RewardPopUp:refreshPage(container)
    local equipAttr, maxLv = AncientWeaponDataMgr:getEquipMaxAttr(REWARD_EQUIP_ID)
    local txtMap = { }
    local node2Img = { }
    -- 屬性 
    for i = 1, 2 do
        local curAttr = equipAttr[i]
        -- 最大等级属性
        txtMap["curStarAttrValTxt_" .. i] = curAttr.val
        node2Img["curStarAttrValIcon_" .. i] = curAttr.icon
    end
    -- 等級
    txtMap["curLvNum"] = maxLv
    -- 技能
    local equipCfg = ConfigManager.getEquipCfg()[REWARD_EQUIP_ID]
    local roleEquipID = equipCfg.mercenarySuitId
    local roleEquipCfg = ConfigManager.RoleEquipDescCfg()[roleEquipID]
    for idx = 1, 3 do
        local skillDesc = roleEquipCfg["desc" .. tostring(idx)]
        if skillDesc then
            local freeTypeCfg = FreeTypeConfig[tonumber(skillDesc)]
            local str = common:fill(freeTypeCfg and freeTypeCfg.content or "")
            local parent = container:getVarLabelTTF("mLockTxt" .. idx)

            str = string.gsub(str, FREETYPE_FONT_COLOR, UI_FONT_COLOR)

            NodeHelper:addHtmlLable(parent, str, tonumber(skillDesc), CCSizeMake(400, 80))
        end
        txtMap["mLockTxt" .. idx] = ""
    end
    -- 專武圖
    node2Img["mRewardImg"] = EventDataMgr[EventDataMgr.nowActivityId].REWARD_EQUIP_IMG

    NodeHelper:setSpriteImage(container, node2Img)
    NodeHelper:setStringForLabel(container, txtMap)
end

local CommonPage = require('CommonPage')
local Event001RewardPopUp = CommonPage.newSub(Event001RewardPopUp, thisPageName, option)
