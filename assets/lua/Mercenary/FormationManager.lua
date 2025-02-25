
local RelationshipManager = require("RelationshipManager")

local FormationManager = { }

local FormationList = { }

------------------------------------------------------------------
local mSubscriber = { }
function FormationManager:addSubscriber(key, func)
    mSubscriber[key] = func
end

function FormationManager:removeSubscriber(key)
    if mSubscriber[key] then
        mSubscriber[key] = nil
    end
end

function FormationManager:broadcast()
    for k, v in pairs(mSubscriber) do
        if v then
            v(FormationManager:getMainFormationInfo())
        end
    end
end
------------------------------------------------------------------



function FormationManager:setFormationInfo(msg)
    if FormationList == nil then
        FormationList = { }
    end
    local len = common:getTableLen(FormationList)

    if len > 0 then
        -- 目前只有一套阵容
        local UserMercenaryManager = require("UserMercenaryManager")
        local roleNumberList = FormationManager:getMainFormationInfo().roleNumberList

        ----
        local lastTeam = FormationManager:getMainFormationInfo().roleNumberList

        if roleNumberList then
            for i = 1, #roleNumberList do
                local itemId = roleNumberList[i]
                if itemId > 0 then
                    UserMercenaryManager:changeMercenarysStateRest(itemId)
                end
            end
        end

        FormationList[msg.type] = msg

        roleNumberList = FormationManager:getMainFormationInfo().roleNumberList
        if roleNumberList then
            for i = 1, #roleNumberList do
                local itemId = roleNumberList[i]
                if itemId > 0 then
                    UserMercenaryManager:changeMercenarysStateBattle(itemId)
                end
            end
        end

        local currentTeam = FormationManager:getMainFormationInfo().roleNumberList
        if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
            --RelationshipManager:updateActivationState(lastTeam, currentTeam)
        end
            RelationshipManager:updateActivationState(lastTeam, currentTeam)

    else
        FormationList[msg.type] = msg
    end

    -- FormationList[msg.type] = msg

    FormationManager:broadcast()
end

function FormationManager:getMainFormationInfo()
    return FormationList[1] or { }
end

function FormationManager:getMainFramtionTable()
    local keyTable = { }
    for i, v in ipairs(FormationList[1].roleNumberList) do
        if v > 0 then
            keyTable[v] = i
        end
    end
    return keyTable
end

return FormationManager