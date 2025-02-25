--[[ 
    name: AncientWeaponDataMgr
    desc: 專武頁面 資料管理
    author: youzi
    update: 2023/11/21 14:47
    description: 

--]]

local InfoAccesser = require("Util.InfoAccesser")

--[[ 本體 ]]
local Inst = {}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {
    {
        -- 子頁面名稱 : 升級
        subPageName = "LevelUp",

        -- 分頁 相關
        scriptName = "AncientWeapon.AncientWeaponSubPage_LevelUp",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_AncientLevelUp.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_AncientLevelUp_On.png",
        
        -- 標題
        title = "@AncientWeapon.LevelUp.title",

        -- 貨幣資訊 
        currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "30000_7182_0"},
        },

        -- 頂列顯示
        TopisVisible = false,
        
        -- 其他子頁資訊 ----------


    },

    {
        -- 子頁面名稱 : 升星
        subPageName = "StarUp",

        -- 分頁 相關
        scriptName = "AncientWeapon.AncientWeaponSubPage_StarUp",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_AncientRairtyUp.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_AncientRairtyUp_On.png",
        
        -- 標題
        title = "@AncientWeapon.StarUp.title",

        -- 貨幣資訊 
        currencyInfos = {
            { priceStr = "10000_1001_0" },
        },

        -- 頂列顯示
        TopisVisible = false,
        
        -- 其他子頁資訊 ----------


    },
    --
    --{
    --    -- 子頁面名稱 : 羈絆
    --    subPageName = "Collection",
    --
    --    -- 分頁 相關
    --    scriptName = "AncientWeapon.AncientWeaponSubPage_Collection",
    --    iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_AncientBondage.png",
    --    iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_AncientBondage_On.png",
    --    
    --    -- 標題
    --    title = "@AncientWeapon.Collection.title",
    --
    --    -- 貨幣資訊 
    --    currencyInfos = {
    --        { priceStr = "10000_1001_0" },
    --    },
    --    
    --    -- 其他子頁資訊 ----------
    --
    --},
}

--[[ 取得 子頁面 配置 ]]
function Inst:getSubPageCfg (subPageName)
    for idx, cfg in ipairs(Inst.SubPageCfgs) do
        if cfg.subPageName == subPageName then return cfg end
    end
    return nil
end

function Inst:getEquipHero (equipID)
    local equipCfg = ConfigManager.getEquipCfg()[equipID]
    local roleEquipCfg = ConfigManager.RoleEquipDescCfg()
    local roleId = roleEquipCfg[equipCfg.mercenarySuitId].mercenaryId[1]
    return roleId
end

function Inst:getIsTargetHeroEquip (equipID, heroId)
    local equipCfg = ConfigManager.getEquipCfg()[equipID]
    local roleEquipCfg = ConfigManager.RoleEquipDescCfg()
    local roleIds = roleEquipCfg[equipCfg.mercenarySuitId].mercenaryId
    for i = 1, #roleIds do
        if tonumber(roleIds[i]) == 0 or tonumber(roleIds[i]) == heroId then
            return true
        end
    end
    return false
end

function Inst:getEquipNoticeString (equipID)
    local equipCfg = ConfigManager.getEquipCfg()[equipID]
    local roleEquipCfg = ConfigManager.RoleEquipDescCfg()
    local roleIds = roleEquipCfg[equipCfg.mercenarySuitId].mercenaryId
    for i = 1, #roleIds do
        if tonumber(roleIds[i]) == 0 or tonumber(roleIds[i]) == heroId then
            return true
        end
    end
    return false
end
--[[ 取得 羈絆設定 ]]
function Inst:getRelationshipCfgs ()
    local relationShipCfgs = ConfigManager.getFetterEquipCfg()--FetterManager.getRelationCfg()
    local list = {}
    local len = 1
    for idx, cfg in ipairs(relationShipCfgs) do
        --if cfg.order < 2000 then
            local copy = common:deepCopy(cfg)
            list[len] = copy
            len = len + 1
        --end
    end
    return list
end


-- 當前屬性: equip.txt[equipID].equipAttr * (本身數值1 + 強化加成比例(equipStrength.txt[部位ID][強化等級(0+n)]/1000))
-- 當前消耗: equipStrengthRatio.txt[強化等級(0+n)] 的 costCoin, costItem

function Inst:getEquipLevelUpCost (equipID, nextLevel)
    local cfg = ConfigManager.getEquipEnhanceItemCfg()[nextLevel-1]
    if cfg == nil then return nil end
    return cfg
end

function Inst:getEquipStarUpCost (equipID, nextStar)
    local parsedEquip = InfoAccesser:parseAWEquipStr(equipID)
    local equipID_series = parsedEquip.id*100
    local staredEquipID = equipID_series + nextStar
    local cfg = ConfigManager.getEquipCfg()[staredEquipID]
    if cfg == nil then return nil end
    return cfg.fixedMaterial
end

function Inst:getEquipAttr (equipID, addtives)
    local equipCfgs = ConfigManager.getEquipCfg()
    
    local equipCfg = equipCfgs[equipID]
    if equipCfg == nil then return nil end
    
    local parsedAttrs = InfoAccesser:parseAttrStr(equipCfg.equipAttr)
    
    -- 設置 基礎屬性
    local baseAttrs = {}
    for idx = 1, #parsedAttrs do
        local parsedAttr = parsedAttrs[idx]
        local attrInfo = InfoAccesser:getAttrInfo(parsedAttr.attr, parsedAttr.val)
        baseAttrs[idx] = attrInfo
    end
    
    if addtives == nil then return baseAttrs end
    
    local result = {}

    local parsedEquip = InfoAccesser:parseAWEquipStr(equipID)
    local equipID_series = parsedEquip.id*100
    
    -- 升級
    local equipEnhanceAttrCfgs = ConfigManager.getEquipEnhanceAttrCfg()
    -- local equipEnhanceAttrCfg = equipEnhanceAttrCfgs[equipCfg.part]
    local equipEnhanceAttrCfg = equipEnhanceAttrCfgs[1]
    
    for addIdx = 1, #addtives do

        local addtive = addtives[addIdx]

        local sumAttrs
        
        if addtive.star ~= nil then
            local staredEquipID = equipID_series + addtive.star
            local staredEquipCfg = equipCfgs[staredEquipID]
            if staredEquipCfg then
                local parsedAttrs = InfoAccesser:parseAttrStr(staredEquipCfg.equipAttr)
                
                sumAttrs = {}
                for idx = 1, #parsedAttrs do
                    local parsedAttr = parsedAttrs[idx]
                    local attrInfo = InfoAccesser:getAttrInfo(parsedAttr.attr, parsedAttr.val)
                    sumAttrs[#sumAttrs+1] = attrInfo
                end 
            end
        else
            sumAttrs = common:deepCopy(baseAttrs)
        end

        if sumAttrs ~= nil then

            if equipEnhanceAttrCfg ~= nil then 
        
                local attrScales = equipEnhanceAttrCfg.mainAttr
            
                local lv = addtive.level
                if lv ~= nil then

                    local upLv = lv - 1
                    if upLv <= #attrScales then 
                        
                        -- 加成
                        local scale = 1
                        if upLv > 0 then
                            scale = scale + (tonumber(attrScales[upLv]) / 10000) -- 以萬分比紀錄
                        end
                        
                        for idx = 1, #sumAttrs do
                            local sumAttr = sumAttrs[idx]
                            sumAttr.val = math.floor(sumAttr.val * scale)
                        end
                    else
                        sumAttrs = nil
                    end
                
                end

            end
            
        end
        result[addIdx] = sumAttrs
    end

    return result
end

function Inst:getEquipMaxAttr (equipID)
    local equipCfgs = ConfigManager.getEquipCfg()
    
    local equipCfg = equipCfgs[equipID]
    if equipCfg == nil then return nil end
    
    local parsedAttrs = InfoAccesser:parseAttrStr(equipCfg.equipAttr)
    
    -- 設置 基礎屬性
    local baseAttrs = {}
    for idx = 1, #parsedAttrs do
        local parsedAttr = parsedAttrs[idx]
        local attrInfo = InfoAccesser:getAttrInfo(parsedAttr.attr, parsedAttr.val)
        baseAttrs[idx] = attrInfo
    end
    
    local result = {}

    local parsedEquip = InfoAccesser:parseAWEquipStr(equipID)
    local equipID_series = parsedEquip.id*100
    
    -- 升級
    local equipEnhanceAttrCfgs = ConfigManager.getEquipEnhanceAttrCfg()
    -- local equipEnhanceAttrCfg = equipEnhanceAttrCfgs[equipCfg.part]
    local equipEnhanceAttrCfg = equipEnhanceAttrCfgs[1]

    local sumAttrs, maxLv
    
    local staredEquipID = equipID_series + 13--addtive.star
    local staredEquipCfg = equipCfgs[staredEquipID]
    if staredEquipCfg then
        local parsedAttrs = InfoAccesser:parseAttrStr(staredEquipCfg.equipAttr)
        
        sumAttrs = {}
        for idx = 1, #parsedAttrs do
            local parsedAttr = parsedAttrs[idx]
            local attrInfo = InfoAccesser:getAttrInfo(parsedAttr.attr, parsedAttr.val)
            sumAttrs[#sumAttrs+1] = attrInfo
        end 
    end

    if sumAttrs ~= nil then

        if equipEnhanceAttrCfg ~= nil then 
    
            local attrScales = equipEnhanceAttrCfg.mainAttr
        
            local lv = #attrScales
            maxLv = #attrScales
            if lv ~= nil then

                local upLv = lv - 1
                if upLv <= #attrScales then 
                    
                    -- 加成
                    local scale = 1
                    if upLv > 0 then
                        scale = scale + (tonumber(attrScales[upLv]) / 10000) -- 以萬分比紀錄
                    end
                    
                    for idx = 1, #sumAttrs do
                        local sumAttr = sumAttrs[idx]
                        sumAttr.val = math.floor(sumAttr.val * scale)
                    end
                else
                    sumAttrs = nil
                end
            
            end

        end
        
    end

    return sumAttrs, maxLv
end
    

return Inst