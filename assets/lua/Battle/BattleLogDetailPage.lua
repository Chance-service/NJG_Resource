local thisPageName = "BattleLogDetailPage"
local NodeHelper = require("NodeHelper")
local pageManager = require("PageManager")
local common = require("common")
local CONST = require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local UserMercenaryManager = require("UserMercenaryManager")
require("Battle.NgBattleDataManager")

BattleLogDetailPage = BattleLogDetailPage or { }
local option = {
    ccbiFile = "BattleLogDetailPage.ccbi",
    handlerMap =
    {
        onClose = "onClose",
    }
}
BattleLogDetailPage.BAR_WIDTH = 455
BattleLogDetailPage.BAR_HEIGHT = 48

------------------------------------------------

function BattleLogDetailPage:onEnter(container)
    self:initUI(container)
end

function BattleLogDetailPage:initUI(container)
    if not BattleLogDetailPage.charData then
        return
    end
    for i = 1, 2 do
        local data = (i == 1) and BattleLogDetailPage.charData or BattleLogDetailPage.tarData
        local addStr = (i == 1) and "" or "_Tar"
        if i == 2 and not data then
            NodeHelper:setNodesVisible(container, { ["mCharNode_Tar"] = false })
            break
        else
            NodeHelper:setNodesVisible(container, { ["mCharNode_Tar"] = true })
        end
        -- 頭像設定
        local itemId = data.otherData[CONST.OTHER_DATA.ITEM_ID]
        local roleType = data.otherData[CONST.OTHER_DATA.CHARACTER_TYPE]
        local quality = 1
        local element = data.battleData[CONST.BATTLE_DATA.ELEMENT]
        if roleType == CONST.CHARACTER_TYPE.HERO then
            if data.idx < 10 then
                local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(itemId)
                quality = (roleInfo.starLevel > 10 and 6) or (roleInfo.starLevel < 6 and 4) or 5
                NodeHelper:setSpriteImage(container, { ["mHeadIcon" .. addStr] = "UI/RoleIcon/Icon_" .. string.format("%02d", itemId) .. string.format("%03d", roleInfo.skinId) .. ".png" })
            else
                local skinId = eData.otherData[CONST.OTHER_DATA.SPINE_SKIN]
                NodeHelper:setSpriteImage(container, { ["mHeadIcon" .. addStr] = "UI/RoleIcon/Icon_" .. string.format("%02d", itemId) .. string.format("%03d", skinId) .. ".png" })
            end
        elseif roleType == CONST.CHARACTER_TYPE.MONSTER or roleType == CONST.CHARACTER_TYPE.WORLDBOSS then
            local cfg = ConfigManager.getNewMonsterCfg()[itemId]
            NodeHelper:setSpriteImage(container, { ["mHeadIcon" .. addStr] = cfg.Icon })
        end
        NodeHelper:setSpriteImage(container, { ["mHeadFrame" .. addStr] = GameConfig.MercenaryQualityImage[quality],
                                               ["mHeadBg" .. addStr] = NodeHelper:getImageBgByQuality(quality), 
                                               ["mHeadElement" .. addStr] = string.format("Attributes_elemet_%02d.png", element) })
        -- Hp/Mp/護盾資訊設定
        local hp, maxHp = data.battleData[CONST.BATTLE_DATA.HP], data.battleData[CONST.BATTLE_DATA.MAX_HP]
        NodeHelper:setStringForLabel(container, { ["mBarNum1" .. addStr] = hp .. "/" .. maxHp })
        local hpBar = container:getVarScale9Sprite("mBar1" .. addStr)
        hpBar:setContentSize(CCSize(BattleLogDetailPage.BAR_WIDTH * math.min(1, math.max(0, hp / maxHp)), BattleLogDetailPage.BAR_HEIGHT))
        NodeHelper:setNodesVisible(container, { ["mBar1" .. addStr] = (hp > 0) })
        local mp, maxMp = data.battleData[CONST.BATTLE_DATA.MP], 100
        NodeHelper:setStringForLabel(container, { ["mBarNum2" .. addStr] = mp .. "/" .. maxMp })
        local mpBar = container:getVarScale9Sprite("mBar2" .. addStr)
        mpBar:setContentSize(CCSize(BattleLogDetailPage.BAR_WIDTH * math.min(1, math.max(0, mp / maxMp)), BattleLogDetailPage.BAR_HEIGHT))
        NodeHelper:setNodesVisible(container, { ["mBar2" .. addStr] = (mp > 0) })
        local shield = data.battleData[CONST.BATTLE_DATA.SHIELD]
        NodeHelper:setStringForLabel(container, { ["mBarNum3" .. addStr] = shield })
        local shieldBar = container:getVarScale9Sprite("mBar3" .. addStr)
        shieldBar:setContentSize(CCSize(BattleLogDetailPage.BAR_WIDTH * math.min(1, math.max(0, shield / maxHp)), BattleLogDetailPage.BAR_HEIGHT))
        NodeHelper:setNodesVisible(container, { ["mBar3" .. addStr] = (shield > 0) })
        -- 屬性資訊設定
        local atk = NewBattleUtil:calAtk(data, nil)
        local phyDef = NewBattleUtil:calBaseDef(nil, data, true)
        local magDef = NewBattleUtil:calBaseDef(nil, data, false)
        local phyReduction = NewBattleUtil:calReduction2(nil, data, true)
        local magReduction = NewBattleUtil:calReduction2(nil, data, false)
        local penetrate = NewBattleUtil:calPenetrate(data, nil)
        local cri = NewBattleUtil:calCri(data, nil) + CONST.BASE_CRI
        local hit = NewBattleUtil:calHit(data, nil)
        local dodge = NewBattleUtil:calDodge(nil, data)
        NodeHelper:setStringForLabel(container, { ["mAttrTxt" .. addStr] = "Atk: " .. atk .. " PhyDef: " .. phyDef .. " PhyReduct: " .. (phyReduction * 100) .. "%" .. "\n" ..
                                                  "MagDef: " .. magDef .. " MagReduct: " .. (magReduction * 100) .. "% Penetrate: " .. (penetrate * 100) .. "%" .. "\n" ..
                                                  "Cri: " .. (cri * 100) .. "% Hit: " .. (hit * 100) .. "% Dodge: " .. (dodge * 100) .. "%"})
        -- Buff資訊設定
        for i = 1, 20 do
            NodeHelper:setNodesVisible(container, { ["mBuffNode" .. i .. addStr] = false })
        end
        local buffData = data.buffData
        local count = 1
        local buffConfig = ConfigManager:getNewBuffCfg()
        for k, v in pairs(buffData) do
            local baseId = math.floor(k / 100) % 1000
            if buffConfig[k].buffType ~= 4 and baseId ~= 110 and baseId ~= 111 and baseId ~= 112 and baseId ~= 113 then
                NodeHelper:setNodesVisible(container, { ["mBuffNode" .. count .. addStr] = true })
                NodeHelper:setSpriteImage(container, { ["mBuffImg" .. count .. addStr] = ("Buff_" .. k .. ".png") })
                NodeHelper:setStringForLabel(container, { ["mBuffName" .. count .. addStr] = common:getLanguageString("@Buff_" .. k) })
                count = count + 1
            end
        end
    end
end

function BattleLogDetailPage_setData(data, tarData)
    BattleLogDetailPage.charData = data
    BattleLogDetailPage.tarData = tarData
end

function BattleLogDetailPage:onClose(container)
    BattleLogDetailPage.charData = nil
    BattleLogDetailPage.tarData = nil
    PageManager.popPage(thisPageName)
end

local CommonPage = require("CommonPage")
BattleLogDetailPage = CommonPage.newSub(BattleLogDetailPage, thisPageName, option)

return BattleLogDetailPage