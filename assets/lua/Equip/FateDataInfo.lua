-- Author:Ranjinlan
-- Create Data: [2018-05-22 16:00:30]
local fateDressCfg = ConfigManager.getFateDressCfg()
local Const_pb = require("Const_pb")

local FateDataInfo = {
    id,           --唯一ID
    itemId,       --配表ID
    skill,        --技能
    --exp,          --经验
    --totalExp,     --总经验
    roleId = nil,       --角色ID
    locPos = nil,       --角色穿戴的位置
    newSkill = nil,
}

function FateDataInfo.new(dressInfoPb)
    local o = setmetatable({ id = nil, itemId = nil, skill = nil, attr = nil, roleId = nil, locPos = nil,newSkill = nil }, { __index=FateDataInfo })
    o.id = dressInfoPb.id
    o.itemId = dressInfoPb.equipId
    o.skill = dressInfoPb.skillId
    o.attr = dressInfoPb.attr
    o.newSkill = dressInfoPb.refineId
    o.lock = dressInfoPb.fusionLock or 0
    if dressInfoPb.roleId ~= 0 then
        o.roleId = dressInfoPb.roleId
    end
    --o.totalExp = dressInfoPb.exp
    --o.exp = o:_getExp()
    return o
end

function FateDataInfo.newOtherInfo(otherInfoPb)
    local o = setmetatable({ id = nil, itemId = nil, skill = nil, attr = nil, roleId = nil, locPos = nil }, { __index=FateDataInfo })
    o.id = otherInfoPb.id
    o.locPos = otherInfoPb.loc
    o.itemId = otherInfoPb.itemId
    o.skill = otherInfoPb.skillId
    o.attr = otherInfoPb.attr
    return o
end

function FateDataInfo.newReward(rewardPb)
    local o = setmetatable({ id = 0, itemId = nil, skill = nil, attr = nil, roleId = nil, locPos = nil }, { __index=FateDataInfo })
    o.itemId = rewardPb.itemId
    assert(rewardPb.itemType == Const_pb.BADGE * 10000)
    assert(rewardPb.itemCount == 1)
    return o
end

function FateDataInfo:update(dressInfoPb)
    assert(dressInfoPb.id == self.id,"update must id is same!")
    self.itemId = dressInfoPb.equipId
    self.skill = dressInfoPb.skillId
    self.attr = dressInfoPb.attr
    self.lock = dressInfoPb.fusionLock
    --self.totalExp = dressInfoPb.exp
    if dressInfoPb.roleId ~= 0 then
        self.roleId = dressInfoPb.roleId
    else
        self.roleId = nil
    end
    --self.exp = self:_getExp()
end

function FateDataInfo:getLevelUpExp()
    return 0--self:getConf().lvExp[self.level]
end

function FateDataInfo:_getExp()
    --if self.level == 1 then
    --    return self.totalExp 
    --end
    --local conf = self:getConf()
    --local LvExp = 0
    --for i = 1,self.level-1 do
    --    LvExp = LvExp + conf.lvExp[i]
    --end
    return 0--self.totalExp - LvExp
end

function FateDataInfo:getExpAndLevel(totalExp)
    --totalExp = totalExp or 0
    --local exp,level = totalExp,1
    --if totalExp == 0 then return exp,level end
    --local conf = self:getConf()
    --for i = 1,conf.maxLevel - 1 do
    --    if exp >= conf.lvExp[i] then
    --        level = level + 1
    --        exp = exp - conf.lvExp[i]
    --    else
    --        break
    --    end
    --end
    return 0--exp,level
end

function FateDataInfo:updateRoleInfo(roleId, locPos)
    if locPos then
        self.locPos = locPos
        self.roleId = roleId
    else
        self.roleId = nil
        self.locPos = nil
    end
end

function FateDataInfo:getConf()
    return fateDressCfg[self.itemId]
end

function FateDataInfo:isMaxLevel(level)
    --level = level or self.level
    --local conf = self:getConf()
    --if conf and level < conf.maxLevel then
    --    return false
    --else
        return true
    --end
end

--获取命格受等级影响的基础属性
function FateDataInfo:getFateBasicAttr(level)
    level = 1--level or self.level
    --基础属性值
    local basicAttrList = { }
    local basicAttrTypeList = { }
    local conf = self:getConf()
    local AttrTable={}
    for _, attr in ipairs(common:split(conf.basicAttr, ",")) do
        local _type, _value = unpack(common:split(attr, "_"));
        table.insert(AttrTable, {
            type = tonumber(_type),
            value = tonumber(_value)
        })
    end
    --计算出受等级影响的基础属性
    for _,v in pairs(AttrTable) do
        if not basicAttrList[v.type] then
            basicAttrTypeList[#basicAttrTypeList + 1] = { type = v.type }
            basicAttrList[v.type] = v.value
        else
            basicAttrList[v.type] = basicAttrList[v.type] + v.value
        end
    end
    if level > 1 then
        for _, v in pairs(conf.basicAttrGrow[level - 1] or { }) do
            if not basicAttrList[v.type] then
                basicAttrTypeList[#basicAttrTypeList + 1] = { type = v.type }
                basicAttrList[v.type] = v.value
            else
                basicAttrList[v.type] = basicAttrList[v.type] + v.value
            end
        end
    end
    for _,v in ipairs(basicAttrTypeList) do
        v.value = basicAttrList[v.type]
    end
    return basicAttrTypeList
end

function FateDataInfo:getNextAddAttr()
    --if self:isMaxLevel() then --满级了
        return {}
    --end
    --local lvAttrList = {}
    --local attrTypeList = {}
    --local conf = self:getConf()
    --for _,v in pairs(conf.basicAttrGrow[self.level - 1] or {}) do
    --    attrTypeList[#attrTypeList + 1] = { type = v.type }
    --    lvAttrList[v.type] = -v.value
    --end
    --for _,v in pairs(conf.basicAttrGrow[self.level] or {}) do
    --    if lvAttrList[v.type] then
    --        lvAttrList[v.type] = lvAttrList[v.type] + v.value
    --    else
    --        attrTypeList[#attrTypeList + 1] = { type = v.type }
    --        lvAttrList[v.type] = v.value
    --    end
    --end
    --if #attrTypeList > 0 then
    --    for i = #attrTypeList ,1,-1 do
    --        if lvAttrList[attrTypeList[i].type] == 0 then
    --            table.remove(attrTypeList,i)
    --        else
    --            attrTypeList[i].value = lvAttrList[attrTypeList[i].type]
    --        end
    --    end
    --end
    --return attrTypeList
end

return FateDataInfo