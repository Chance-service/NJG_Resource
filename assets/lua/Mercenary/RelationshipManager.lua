
local EquipManager = require("EquipManager")

local RelationshipManager = {
}

local stateType = {
    Unlock = 1,
    Lock = 2,
}

local mData = nil
function RelationshipManager:initData()
    mData = { }
    local configData = ConfigManager.getRelationshipCombinationCfg()
    for k, v in pairs(configData) do
        if mData[v.targetRoleId] == nil then
            mData[v.targetRoleId] = { }
        end
        table.insert(mData[v.targetRoleId], v)
    end
end

function RelationshipManager:getRelationshipDataByRoleId(roleId)
    if mData == nil then
        RelationshipManager:initData()
    end
    return mData[roleId]
end

function RelationshipManager:getTeamActivationState(teamRoleIdList)
    local list = RelationshipManager:removeZero(teamRoleIdList)
    local state = { }
    for i = 1, #list do
        if list[i] > 0 then
            local data = RelationshipManager:getRelationshipDataByRoleId(list[i])
            if data then
                for k, v in pairs(data) do
                    --                    if RelationshipManager:getIsActivation(v.relationshipRoleId, list) then
                    --                        state[v.id] = stateType.Unlock
                    --                    end

                    if RelationshipManager:getIsActivation(v, list) then
                        state[v.id] = stateType.Unlock
                    end
                end
            end
        end
    end

    return state
end

function RelationshipManager:updateActivationState(lastTeam, currentTeam)

    local lastState = RelationshipManager:getTeamActivationState(lastTeam)
    local currentState = RelationshipManager:getTeamActivationState(currentTeam)

    -- 去掉的
    local t1 = { }
    -- 新加的
    local t2 = { }

    for k, v in pairs(currentState) do
        if lastState[k] == nil then
            -- 新的
            table.insert(t2, k)
        end
    end

    for k, v in pairs(lastState) do
        if currentState[k] == nil then
            -- 去掉的
            table.insert(t1, k)
        end
    end

    local wordList = { }
    local colorList = { }
    local cfgData = ConfigManager.getRelationshipCombinationCfg()

    for k, v in pairs(t2) do
        local data = cfgData[v]
        local roleConfgData = ConfigManager.getRoleCfg()
        -- "xxx的缘分被激活"
        table.insert(wordList, common:getLanguageString("@fatecontent1", roleConfgData[data.targetRoleId].name))
        table.insert(colorList, GameConfig.ColorMap.COLOR_GREEN)
        -- 增加属性加成
        for i = 1, #data.attr do
            local attrData = data.attr[i]
            local valueStr = EquipManager:getGodlyAttrString(attrData.type, attrData.value)
            local name = common:getLanguageString("@AttrName_" .. attrData.type);
            table.insert(wordList, name .. "+" .. valueStr)
            table.insert(colorList, GameConfig.ColorMap.COLOR_GREEN)
        end
    end


    for k, v in pairs(t1) do
        local data = cfgData[v]
        local roleConfgData = ConfigManager.getRoleCfg()
        -- "xxx的缘分被关闭"
        table.insert(wordList, common:getLanguageString("@fatecontent2", roleConfgData[data.targetRoleId].name))
        table.insert(colorList, GameConfig.ColorMap.COLOR_RED)
        -- 减少属性加成
        for i = 1, #data.attr do
            local attrData = data.attr[i]
            local valueStr = EquipManager:getGodlyAttrString(attrData.type, attrData.value)
            local name = common:getLanguageString("@AttrName_" .. attrData.type);
            table.insert(wordList, name .. "-" .. valueStr)
            table.insert(colorList, GameConfig.ColorMap.COLOR_RED)
        end
    end

    insertMessageFlow(wordList, colorList)
end
















-- 缘分是否被激活
-- 参数1:  副将的缘分组合
-- 参数2:  队伍信息
-- function RelationshipManager:getIsActivation(relationshipRoleIdList, teamRoleIdList)
--    local list = RelationshipManager:removeZero(teamRoleIdList)
--    local t = { }
--    for k, roleId in pairs(relationshipRoleIdList) do
--        local id = RelationshipManager:findId(roleId, list)
--        if id ~= 0 then
--            table.insert(t, id)
--        end
--    end
--    return RelationshipManager:getTableLen(t) == RelationshipManager:getTableLen(relationshipRoleIdList)
-- end


-- 缘分是否被激活
-- 参数1:  缘分数据
-- 参数2:  队伍信息
function RelationshipManager:getIsActivation(data, teamRoleIdList)
    local list = RelationshipManager:removeZero(teamRoleIdList)
    local t = { }
    local tagetId = RelationshipManager:findId(data.targetRoleId, list)
    if tagetId == 0 then
        return false
    end
    for k, roleId in pairs(data.relationshipRoleId) do
        local id = RelationshipManager:findId(roleId, list)
        if id ~= 0 then
            table.insert(t, id)
        end
    end
    return RelationshipManager:getTableLen(t) == RelationshipManager:getTableLen(data.relationshipRoleId)
end

-- function RelationshipManager:getIsActivation(data, teamRoleIdList)
--    local list = RelationshipManager:removeZero(teamRoleIdList)
--    local t = { }
--    for k, roleId in pairs(data.relationshipRoleId) do
--        local id = RelationshipManager:findId(roleId, list)
--        if id ~= 0 then
--            table.insert(t, id)
--        end
--    end
--    return RelationshipManager:getTableLen(t) == RelationshipManager:getTableLen(data.relationshipRoleId)
-- end


-- 这个副将可以给谁加buff
function RelationshipManager:getAddBuffToRoldData(roleId)
    local t = { }
    local configData = ConfigManager.getRelationshipCombinationCfg()
    for k, v in pairs(configData) do
        local id = RelationshipManager:findId(roleId, v.relationshipRoleId)
        if id ~= 0 then
            table.insert(t, RelationshipManager:getRelationshipDataByRoleId(v.targetRoleId))
        end
    end
    return t
end

function RelationshipManager:removeZero(t)
    local list = { }
    for i = 1, #t do
        if t[i] > 0 then
            table.insert(list, t[i])
        end
    end
    return list
end

function RelationshipManager:findId(id, t)
    local n = 0
    for k, v in pairs(t) do
        if v == tonumber(id) then
            return id
        end
    end
    return n
end

function RelationshipManager:getTableLen(t)
    local len = 0
    for k, v in pairs(t) do
        len = len + 1
    end
    return len
end
--------------------------------------------------------------------------------
return RelationshipManager