--[[ 
    name: InfoAccesser
    desc: 某些資訊的存取工具
    author: youzi
    update: 2023/7/12 17:57
    description: 
        因資訊零散，不易辨識取得渠道正確分類，故先暫用此處來進行取得資料。
--]]


local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local UserItemManager = require("Item.UserItemManager")
local UserEquipManager = require("Equip.UserEquipManager")
local FateDataManager = require("FateDataManager")
local ResManagerForLua = require("ResManagerForLua")

local PathAccesser = require("Util.PathAccesser")

local InfoAccesser = {}


-- 道具圖標設定檔
InfoAccesser.env2item2IconCfg = {}

-- [[ 讀取 道具圖標設定檔 ]]
function InfoAccesser:loadItemIconCfg ()
    self.env2item2IconCfg = {}

    self.env2item2IconCfg._default = {
        ["_"] = {
            scale = 0.4,
            offsetX = 0,
            offsetY = 0,
        }
    }
    local itemIconCfgs_raw = ConfigManager.getItemIconCfg()
    -- dump(itemIconCfgs_raw, "itemIconCfgs_raw")
    for id, rawCfg in pairs(itemIconCfgs_raw) do
        
        local item2IconCfg = self.env2item2IconCfg[rawCfg.env]
        if item2IconCfg == nil then
            item2IconCfg = {}
            self.env2item2IconCfg[rawCfg.env] = item2IconCfg
        end
        
        local itemID = rawCfg.item
        local itemKey = itemID
        if itemID ~= "_" then
            
            local itemType = rawCfg.type
            if itemType == nil then itemType = Const_pb.TOOL end

            itemKey = tostring(itemType).."_"..tostring(itemID)
        end

        local iconCfg = item2IconCfg[itemKey]
        if iconCfg == nil then
            iconCfg = {}
            item2IconCfg[itemKey] = iconCfg
        end

        iconCfg.scale = rawCfg.scale
        iconCfg.offsetX = rawCfg.offsetX
        iconCfg.offsetY = rawCfg.offsetY

        -- if self.env2item2IconCfg._default[itemKey] == nil then
        --     self.env2item2IconCfg._default[itemKey] = iconCfg
        -- end
    end
    -- dump(self.env2item2IconCfg, "self.env2item2IconCfg")
end
InfoAccesser:loadItemIconCfg()


--[[ 取得 英雄資訊 ]]
function InfoAccesser:getHeroInfo (heroID, feilds)
    local info = {}
    
    local isAll = feilds == nil
    
    local feild2include = {}
    for idx = 1, #feilds do
        feild2include[feilds[idx]] = true
    end
        
    if isAll or feild2include.name then
        info.name = "@HeroName_"..tostring(heroID)
    end

    return info
end

--[[ 取得 英雄解鎖碎片需求 ]]
function InfoAccesser:getHeroUnlockSoul (heroID)
    local illustrationCfg = ConfigManager.getIllustrationCfg()
    if not illustrationCfg[heroID] then return 0 end

    return illustrationCfg[heroID].soulNumber
end

--[[ 解析 屬性字串 ]]
function InfoAccesser:parseAttrStr (attrStrOrAttrStrs)

    local attrStrs = common:split(attrStrOrAttrStrs, ",")

    local attrInfos = {}

    for idx = 1, #attrStrs do while true do
        local attrStr = attrStrs[idx]

        if attrStr == nil or attrStr == "" then break end -- continue

        local arr = common:split(attrStr, "_")

        if #arr < 2 then 
            print("parseAttrStr error : "..tostring(attrStr))
            break
        end

        local attrID = tonumber(arr[1]) -- 第一個
        local val = tonumber(arr[#arr]) -- 最後一個
        
        local parsed = {
            attr = attrID,
            val = val,
        }

        if #arr == 3 then
            parsed.type = tonumber(arr[2])
        end

        local attrInfo = self:getAttrInfo(attrID, val, options)
        attrInfos[idx] = attrInfo

    break end end
    
    return attrInfos
end

--[[ 取得 屬性資訊 ]]
function InfoAccesser:getAttrInfoByStr (attrStr, options)
    if attrStr == "" or attrStr == nil then return nil end
    if options == nil then options = {} end

    local parsed = self:parseAttrStr(attrStr)[1]

    -- 預設 類型 為 數值 (1:萬分比, 2:數值 3:乘以等級)
    local typ = 2
    if parsed.type ~= nil then
        typ = parsed.type
    end

    options["type"] = typ

    return self:getAttrInfo(parsed.attr, parsed.val, options)
end

--[[ 取得 屬性資訊 ]]
function InfoAccesser:getAttrInfo (attrID, attrVal, options)
    if options == nil then options = {} end

    local name = PathAccesser:getAttrName(attrID)

    local mergeAttrs = options["mergeAttrs"]
    if mergeAttrs then
        local overrideName = function (newName, conditionAttrs)
            for idx = 1, #conditionAttrs do
                if attrID == conditionAttrs[idx] then
                    name = newName
                    break
                end
            end
        end
        --for idx, val in ipairs(mergeAttrs) do
        --    if val == "atk" then
        --        overrideName("@Damage", {113, 114})
        --    elseif val == "def" then
        --        overrideName("@Armor", {106, 107})
        --    elseif val == "penetrate" then
        --        overrideName("@AttrName_1007", {2103, 2104})
        --    end
        --end
    end

    

    

    return { 
        attr = attrID,
        type = options["type"] or 2,
        val = attrVal,
        valStr = function (self)
            local valStr
            if self.val >= 0 then
                valStr = "+"..tostring(self.val)
            else
                valStr = "-"..tostring(self.val)
            end
            return valStr
        end,
        name = name,
        icon = PathAccesser:getAttrIconPath(attrID),
    }
end

function InfoAccesser:getAttrInfosByStrs (attrList, options)
    if attrList == nil then return {} end
    if options == nil then options = {} end

    local attr2Info = {}
    local attrInfos = {}
    for idx = 1, #attrList do
        local eachAttr = attrList[idx]
        local info = self:getAttrInfoByStr(eachAttr, options)
        if info ~= nil then
            attr2Info[info.attr] = info
            attrInfos[idx] = info
        end
    end
    local mergeAttrs = options["mergeAttrs"]
    if mergeAttrs then
        local chooseMax = function (attrToInfo, conflictAttrs)
            local maxAttr
            local maxInfo
            for idx = 1, #conflictAttrs do
                local each = conflictAttrs[idx]
                local eachInfo = attrToInfo[each]
                if eachInfo ~= nil then 
                    if maxAttr == nil or eachInfo.val > maxInfo.val then
                        maxAttr = each
                        maxInfo = eachInfo
                    end
                end
            end
            
            if maxAttr ~= nil then
                for idx = 1, #conflictAttrs do
                    local each = conflictAttrs[idx]
                    if each ~= maxAttr then
                        attrToInfo[each] = nil
                    end
                end
            end
        end

        for idx, val in ipairs(mergeAttrs) do
            if val == "atk" then
                chooseMax(attr2Info, {113, 114})
            elseif val == "def" then
                chooseMax(attr2Info, {106, 107})
            elseif val == "penetrate" then
                chooseMax(attr2Info, {2103, 2104})
            end
        end
    end

    local result = {}
    for idx, val in ipairs(attrInfos) do
        if attr2Info[val.attr] ~= nil then
            result[#result+1] = val
        end
    end

    return result
end

--[[ 取得 技能資訊 ]]
function InfoAccesser:getSkillInfo (skillID)
    local skillCfgs = ConfigManager.getSkillCfg()
    local skillCfg = skillCfgs[tonumber(skillID)]
    if skillCfg == nil then return nil end

    local freeTypeFontCfg = FreeTypeConfig[skillID]
    local skillDesc
    if freeTypeFontCfg ~= nil then
        skillDesc = freeTypeFontCfg.content
    else
        skillDesc = tostring(skillID)
    end

    local info = {}
    for key, val in pairs(skillCfg) do
        info[key] = val
    end
    
    local skillIDStr = tostring(skillID)
    -- 技能ID 除去等級 (除去最後一位數)
    local skillID_withoutLevel = tonumber(string.sub(skillIDStr, 1, -2))
    
    info.icon = string.format("skill/S_%s.png", skillID_withoutLevel)
    info.name = string.format("@Skill_Name_%s", skillID_withoutLevel)
    info.desc = skillDesc
    
    local typeTags = {}
    local tagType_strs = common:split(info.tagType, ",")
    for idx, val in ipairs(tagType_strs) do
        typeTags[idx] = {
            txt = "@Skill_Type_"..tostring(val),
            img = nil,
        }
    end
    info.typeTags = typeTags

    return info
end

--[[ 解析 專武裝備字串 ]]
-- e.g. 10306
function InfoAccesser:parseAWEquipStr (equipStr)
    -- print("parse equip : "..tostring(equipStr))
    if equipStr == nil then return nil end
    if type(equipStr) == "number" then equipStr = tostring(equipStr) end
    if #equipStr < 5 then return nil end

    local _id = tonumber(string.sub(equipStr, 1, -3))
    local _hero = tonumber(string.sub(equipStr, 2, -3))
    local _star = tonumber(string.sub(equipStr, -2, -1))
    local _rare = 0
    local _pieceID = (_id*100) + 1

    local equipCfgs = ConfigManager.getEquipCfg()
    local _firstStarCfgID = tonumber(equipStr)
    local _firstStarCfg = equipCfgs[_firstStarCfgID]
    -- dump(_firstStarCfg, equipStr)
    
        
    local equipID_series = (_id*100)
    
    for idx = 1, 13 do
        local equipID = equipID_series + idx
        _firstStarCfg = equipCfgs[equipID]

        if _firstStarCfg ~= nil then
            _firstStarCfgID = equipID
            
            if idx <= 5 then 
                _rare = 1
            elseif idx <= 10 then
                _rare = 2
            elseif idx > 10 then
                _rare = 3
            end

            break
        end
    end

    local equip = {
        id = _id,
        hero = _hero,
        star = _star,
        rare = _rare,
        series = equipID_series,
        pieceID = _pieceID,
        firstStarCfgID = _firstStarCfgID,
        firstStarCfg = _firstStarCfg,
    }
    return equip
end

--[[ 解析 物品字串 ]]
-- e.g. 30000_10301_1
function InfoAccesser:parseItemStr (itemStr)
    if itemStr == nil then return nil end
    
    local _type, _id, _count = unpack(common:split(itemStr, "_"))
    if _type == nil or _id == nil or _count == nil then
        assert(false, string.format("InfoAccesser.parseItemStr error : %s", itemStr))
        return nil
    end
        
    local item = {}
    item["type"] = tonumber(_type)
    item["id"] = tonumber(_id)
    item["count"] = tonumber(_count)

    
    if item.type >= 10000 then
        item.type = item.type / 10000
    end

    return item
end

--[[ 取得 道具資訊 ]]
function InfoAccesser:getItemInfo (typ, id, count)
    -- 轉呼叫ResManagerForLua
    if typ >= 10000 then typ = typ / 10000 end
    if typ == 0 then
        return {icon = tostring(id)..".png"}
    elseif typ == Const_pb.TOOL then
        if ConfigManager.getItemCfg()[id] == nil then return nil end
    end
    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(typ, id, count)
    local itemInfo = resInfo
    
    -- 覆寫重要資訊, 避免ResManagerForLua沒有設置
    itemInfo.type = typ
    itemInfo.id = id
    itemInfo.itemId = id
    itemInfo.count = count

    return itemInfo
end

--[[ 取得 道具圖標設定 ]]
function InfoAccesser:getItemIconCfg (itemType, itemID, env)
    if itemType == nil then itemType = Const_pb.TOOL end
    if itemType >= 10000 then itemType = itemType / 10000 end

    local item2IconCfg = self.env2item2IconCfg[env]
    if item2IconCfg == nil then
        item2IconCfg = self.env2item2IconCfg._default
    end
    
    -- dump(self.env2item2IconCfg, "self.env2item2IconCfg")
    local iconCfg = item2IconCfg[tostring(itemType).."_"..tostring(itemID)]

    if iconCfg == nil then 
        iconCfg = item2IconCfg["_"]
        if iconCfg == nil then
            -- dump(self.env2item2IconCfg._default["_"], "self.env2item2IconCfg._default[\"_\"]")
            iconCfg = self.env2item2IconCfg._default["_"]
        end
    end

    -- dump(iconCfg, string.format("%s_%s in %s ", tostring(itemType), tostring(itemID), env))

    return iconCfg

end


--[[ 取得 道具資訊 以 字串 ]]
function InfoAccesser:getItemInfoByStr (itemStr)
    if itemStr == nil or itemStr == "" then return nil end
    -- 解析字串
    local item = self:parseItemStr(itemStr)
    -- dump(item, string.format("getItemInfoByStr(%s) : ", itemStr))
    local itemInfo = self:getItemInfo(item.type, item.id, item.count)
    if itemInfo == nil then return nil end
    itemInfo.str = itemStr
    return itemInfo
end
--[[ 取得 道具資訊列表 以 字串 ]]
function InfoAccesser:getItemInfosByStr (itemsStr)
    local itemInfos = {}
    
    -- 分割 獎勵列表字串
    local itemStrs = common:split(itemsStr, ",")
    -- 設置資料
    for idx, val in ipairs(itemStrs) do
        local itemInfo = InfoAccesser:getItemInfoByStr(val)
        if itemInfo == nil then itemInfo = {} end
        itemInfos[idx] = itemInfo
    end

    return itemInfos
end


function InfoAccesser:getItemInfoStr (itemInfo)
    local typ = itemInfo.type
    if typ < 10000 then
        typ = typ * 10000
    end
    return tostring(typ).."_"..tostring(itemInfo.id).."_"..tostring(itemInfo.count)
end

--[[ 取得 玩家道具資訊 ]]
function InfoAccesser:getUserItemInfo (itemType, itemID)
    local count = self:getUserItemCount(itemType, itemID)
    return self:getItemInfo(itemType, itemID, count)
end

--[[ 取得 玩家道具數量 ]]
function InfoAccesser:getUserItemCountByStr (itemStr)
    -- 解析字串
    -- print("getUserItemCountByStr ("..itemStr..")")
    local parsedItem = self:parseItemStr(itemStr)
    return self:getUserItemCount(parsedItem.type, parsedItem.id)
end


--[[ 取得 玩家道具數量 ]]
function InfoAccesser:getUserItemCount (itemType, itemID)
    -- print(string.format("InfoAccesser:getUserItemCount(%s, %s)", itemType, itemID))

    if itemType ~= nil then
        if itemType >= 10000 then
            itemType = itemType / 10000
        end 
    end

    
    if itemType == Const_pb.PLAYER_ATTR then

        if itemID == 1001 then
            UserInfo.syncPlayerInfo()
            return UserInfo.playerInfo.gold
        elseif itemID == 1002 then
            UserInfo.syncPlayerInfo()
            return UserInfo.playerInfo.coin
        elseif itemID == 1010 then
            UserInfo.syncPlayerInfo()
            return UserInfo.playerInfo.honorValue
        elseif itemID == 1011 then
            UserInfo.syncPlayerInfo()
            return UserInfo.playerInfo.reputationValue
        elseif itemID == 1025 then
            return UserInfo.stateInfo.friendship
        end

        return nil

        
    -- TODO
    -- elseif itemType == Const_pb.TOOL then
    elseif itemType == Const_pb.EQUIP then
        return UserEquipManager:getUserEquipCountByCfgId(itemID)
    elseif itemType == Const_pb.BADGE then
        return FateDataManager:getUserRuneCountByCfgId(itemID)
    else
        return UserItemManager:getCountByItemId(itemID)

    end
end


--[[ 篩選列表 ]]
function InfoAccesser:filters (items, includeFuncList, excludeFuncList)
    local arr = {}
    for idx, item in ipairs(items) do
        if self:filterItem(item, includeFuncList, excludeFuncList) then
            arr[#arr+1] = item
        end
    end
    return arr
end

--[[ 篩選 ]]
function InfoAccesser:filter (item, includeFuncList, excludeFuncList)

    if includeFuncList == nil or #includeFuncList == 0 then
        local isInclude = false
        for idx, fn in ipairs(includeFuncList) do
            if fn(item) == true then
                isInclude = true
                break
            end
        end
        if isInclude == false then
            return false
        end
    end

    if excludeFuncList ~= nil and #excludeFuncList > 0 then
        local isExclude = false
        for idx, fn in ipairs(excludeFuncList) do
            if fn(item) == true then
                isExclude = true
                break
            end
        end

        if isExclude == true then
            return false
        end

    end

    return true
end


--[[ 取得 等級相關資訊 ]]
-- TODO 依照不同儲值平台或環境 從不同地方取得數值
function InfoAccesser:getVIPLevelInfo ()
    
    UserInfo.sync()

    local vipTable = ConfigManager.getVipCfg()

    local nextLv = UserInfo.playerInfo.vipLevel+1
    if nextLv > #vipTable then
        nextLv = #vipTable
    end

    local lastNeeds = vipTable[UserInfo.playerInfo.vipLevel].buyDiamon
    local current = UserInfo.stateInfo.vipPoint
    local nextNeeds = vipTable[nextLv].buyDiamon

    local info = {
        level = UserInfo.playerInfo.vipLevel,
        exp = current, -- lastNeeds,  
        expMax = nextNeeds, -- lastNeeds,
    }

    -- test
    local isTest = false
    if isTest then
        if self.testLv == nil then self.testLv = 1 end
        info.level = self.testLv
        
        if self.testExp == nil then self.testExp = 0 end
        info.exp = self.testExp

        print("testExp : "..tostring(self.testExp))
        self.testExp = self.testExp + 1
        if self.testExp > info.expMax then 
            
            self.testExp = 0
            
            self.testLv = self.testLv + 1
            if self.testLv > info.expMax then 
                self.testLv = 1
            end
        end
    end

    -- dump(info, "RechargeVIP getLevelInfo ")
    
    return info
end

--[[ 取得 是否是專武碎片 ]]
function InfoAccesser:getIsAncientWeaponSoul (itemStr)
    local parsedItem = self:parseItemStr(itemStr)
    -- 專武碎片id設定在>10001
    return (parsedItem["type"] == Const_pb.TOOL) and (parsedItem["id"] > 10000)
end

--[[ 取得 身上是否有合成後的專武 ]]
function InfoAccesser:getExistAncientWeaponByPieceId (itemId)
    local allEquip = UserEquipManager:getEquipAll()
    if itemId < 10000 then
        return false
    end
    for i = 1, #allEquip do
        local info = UserEquipManager:getUserEquipById(allEquip[i])
        if math.floor(info.equipId / 100) == math.floor(itemId / 100) then
            return true
        end
    end
    local dressEquip = UserEquipManager:getEquipDress()
    for i = 1, #dressEquip do
        local info = UserEquipManager:getUserEquipById(dressEquip[i])
        if math.floor(info.equipId / 100) == math.floor(itemId / 100) then
            return true
        end
    end
    return false
end

--[[ 取得 該專武id是否可合成 ]]
function InfoAccesser:getAncientPieceCanFusion(itemId)
    if InfoAccesser:getExistAncientWeaponByPieceId(itemId) then
        return false
    end
    if not ConfigManager.getItemCfg()[itemId] then
        return false
    end
    local consumeStr = ConfigManager.getItemCfg()[itemId].containItem
    local consumeNum = tonumber(common:split(consumeStr, "_")[1]) or 0
    if consumeNum == 0 or InfoAccesser:getUserItemCount(3, itemId) < consumeNum then
        return false
    end
    return true
end

return InfoAccesser