local ConfigManager = require("ConfigManager")
local common = require("common")
local PageManager = require("PageManager")
local UserMercenaryManager = require("UserMercenaryManager")
local UserInfo = require("PlayerInfo.UserInfo")
local table = table
local pairs = pairs
local ipairs = ipairs
local string = string
local math = math
local os = os
local MessageBoxPage = MessageBoxPage
local PacketScriptHandler = PacketScriptHandler
local print = print
local tostring = tostring
local tonumber = tonumber
local CCLuaLog = CCLuaLog
local HP_pb = require("HP_pb")
local RoleOpr_pb = require("RoleOpr_pb")

module("FetterManager")

moduleName = "FetterSystem"

local illCfg = { }

local illMap = { }

local illMap_New = { }
local skinMap = {}
local relationCfg = { }
local roleCfg = {}
local viewFetterId = 0
local haveRelationData = 0 --0为没有奥义数据 1为断线重连后 奥义数据还没请求 2为奥义数据已经有了

local initFlag = false
local otherPagePoint

local avatarTypeImg = {
    [10] = "UI/Common/Font/Font_Fashion_5.png",
    [20] = "UI/Common/Font/Font_Fashion_2.png",
    [30] = "UI/Common/Font/Font_Fashion_3.png",
    [40] = "UI/Common/Font/Font_Fashion_4.png",
}


local roleQualityImage = {
    [3] = "Activity_common_R.png",
    [4] = "Activity_common_SR.png",
    [5] = "Activity_common_SSR.png",
    [6] = "Activity_common_UR.png",
    [7] = "Activity_common_UR.png",-- 临时用
}

-----图鉴每行数量
illLineNumber = 5

CurShowType = {
    Illustration = 1,
    Relationship = 2,
    skin         = 3,
}

-----------事件-----------
onFetterInfo = "onFetterInfo"
onRelationOpen = "onRelationOpen"


---------动态数据------------
local playerId = nil

local illData = { }
local relationIds = { }
local albumIds = {}
local curOpenRelationId = nil
local curOthersRoleInfo = nil

function setPlayerId(_playerId)
    playerId = _playerId
end

function getPlayerId()
    return playerId
end

function reqFetterInfo(_playerId)
    playerId = _playerId
    if not playerId or playerId == UserInfo.playerInfo.playerId then
        common:sendEmptyPacket(HP_pb.FETCH_ARCHIVE_INFO_C, false)
    else
        local msg = RoleOpr_pb.HPFetchOtherArchiveInfoReq()
        msg.playerId = _playerId
        common:sendPacket(HP_pb.FETCH_OTHER_ARCHIVE_INFO_C, msg, false)
    end
end

function reqFetterOpen(fetterId)
    local msg = RoleOpr_pb.HPOpenFetterReq()
    msg.fetterId = fetterId
    common:sendPacket(HP_pb.OPEN_FETTER_C, msg, true)
end

function initFetterCfg()
    if initFlag then return end
    initFlag = true
    illCfg = ConfigManager.getIllustrationCfg()
    relationCfg = ConfigManager.getRelationshipCfg()

    local _illMap = { }

    for i, v in pairs(illCfg) do
        if v._type ~= 0 and v.roleId ~= 0 then
            if v._type < 10 then
                if not _illMap[v._type] then
                    _illMap[v._type] = { }
                end
                table.insert(_illMap[v._type], v)
            else
                local avatarType = math.floor(v._type / 10) * 10
                if not _illMap[avatarType] then
                    _illMap[avatarType] = { }
                end
                table.insert(_illMap[avatarType], v)
            end
        end
    end
    for k, v in pairs(_illMap) do
        table.sort(v, function(m, n)
            return m.order < n.order
        end )
        table.insert(illMap, {
            _type = k,
            map = v
        } )

        local map1 = { }
        for _, item in pairs(v) do
            if item.isOpen == 1 then
                table.insert(map1, item)
            end
        end
        table.insert(illMap_New, {
                _type = k,
                map = map1
            } )

        --v.map = map1
        --
--        for g,h in pairs(v) do
--           if h.isOpen == 1 then
--                table.insert(illMap_New, {
--                _type = k,
--                map = v
--            } )
--            break
--            end  
--        end
--    for k, v in pairs(_illMap) do
--        local map1 = { }
--        for _, item in pairs(v.map) do
--            if item.isOpen == 1 then
--                table.insert(map1, item)
--            end
--        end
--        v.map = map1
--    end
         

    end
    table.sort(illMap, function(a, b)
        return a._type > b._type
    end )
     table.sort(illMap_New, function(a, b)
        return a._type > b._type
    end )
    roleCfg = ConfigManager.getRoleCfg()
    initSkinFetter()
end

function initSkinFetter()
    local _illMap = { }
    skinMap = {}
    for i, v in pairs(illCfg) do
        if v.isSkin == 1 then
            if not _illMap[v._type] then
                _illMap[v._type] = { }
            end
            table.insert(_illMap[v._type],v)
        end
    end
    for k, v in pairs(_illMap) do
        table.sort(v, function(m, n)
            return m.order < n.order
        end )
        local map1 = { }
        for _, item in pairs(v) do
            if item.isSkin == 1 then
                table.insert(map1, item)
            end
        end
            table.insert(skinMap, {
                _type = k,
                map = map1,
            } )

    end
    table.sort(skinMap, function(a, b)
        return a._type > b._type
    end )
    local a = 0
end

function getSkinMap()
    return skinMap
end

function clear()
    playerId = nil
    illData = { }
    relationIds = { }
    albumIds = { }
    curOpenRelationId = nil
end

function resetFetter()
    if haveRelationData ~= 0 then
        haveRelationData = 1
    end
end




function getIllCfgById(id)
    return illCfg[id] or { }
end

function getIllCfgByRoleId(roleId)
    for i, v in pairs(illCfg) do
        if v.roleId == roleId then
            return v
        end
    end
    return {}
end

function getIllMap()
    return illMap
end
function getRoleCfg(roleId)
    return roleCfg[roleId]
end



function getIllMap_New()
--    local _illMap = getIllMap()
--    for k, v in pairs(_illMap) do
--        local map1 = { }
--        for _, item in pairs(v.map) do
--            if item.isOpen == 1 then
--                table.insert(map1, item)
--            end
--        end
--        v.map = map1
--    end
--    return _illMap
      return illMap_New
end

function sortIllMap()
    for k, v in pairs(illMap) do
        local dataTable = v.map
        for i, mv in pairs(dataTable) do
            local roleInfo = getIllData(mv.roleId)
            if roleInfo then
                mv.showSort = roleInfo.activated and 10000 or(roleInfo.soulCount + 100)
            else
                --mv.showSort = first.order

                mv.showSort = 0
            end
        end

        table.sort(dataTable, function(first, second)
            if first.showSort == second.showSort then
                return first.order < second.order
            end
            return first.showSort > second.showSort
        end )
    end
end



function sortIllMap_New()
    for k, v in pairs(illMap_New) do
        local dataTable = v.map
        for i, mv in pairs(dataTable) do
            local roleInfo = getIllData(mv.roleId)
            if roleInfo then
                mv.showSort = roleInfo.activated and 10000 or(roleInfo.soulCount + 100)
            else
                --mv.showSort = first.order

                mv.showSort = 0
            end
        end

        table.sort(dataTable, function(first, second)
            if first.showSort == second.showSort then
                return first.order < second.order
            end
            return first.showSort > second.showSort
        end )
    end
end

function sortSkinMap()
    for k, v in pairs(skinMap) do
        local dataTable = v.map
        for i, mv in pairs(dataTable) do
            local roleInfo = getIllData(mv.roleId)
            if roleInfo then
                mv.showSort = roleInfo.activated and 10000 or(roleInfo.soulCount + 100)
            else
                --mv.showSort = first.order
                mv.showSort = 0
            end
        end

        table.sort(dataTable, function(first, second)
            if first.showSort == second.showSort then
                return first.order < second.order
            end
            return first.showSort > second.showSort
        end )
    end
end
function getHaveRelationDataState()
    return haveRelationData
end

function initRelationData(data)
    --如果之前没数据 则刷新图鉴奥义界面
    if haveRelationData == 0 then
        PageManager.refreshPage(moduleName, "RefreshPageRelation")
    end
    haveRelationData = 2
    relationIds = {}
    for i = 1, #data.openFetters do
        local id = data.openFetters[i]
        relationIds[id] = 1
    end
end


function getIllMapByType_New(_type)
--    local _illMap = getIllMap()
--    for k, v in pairs(_illMap) do
--        local map1 = { }
--        for _, item in pairs(v.map) do
--            if item.isOpen == 1 then
--                table.insert(map1, item)
--            end
--        end
--        v.map = map1
--    end


--    for k, v in pairs(_illMap) do
--        if v._type == _type then
--            return v.map
--        end
--    end
--    return { }
    for k,v in pairs(illMap_New) do
        if v._type == _type then
            return v.map
        end
    end
    return {}
end

function getSkinMapByType(_type)
    for k,v in pairs(skinMap) do
        if v._type == _type then
            return v.map
        end
    end
    return {}
end

function getIllMapByType(_type)
    local _illMap = getIllMap()
    for k, v in pairs(_illMap) do
        if v._type == _type then
            return v.map
        end
    end
    return { }
end

function getAvatarTitle(_type)
    return avatarTypeImg[_type]
end

function getRoleQualityImage(_type)
    return roleQualityImage[_type]
end

function getOneIllLine(_type, line)
     --local map = getIllMapByType(_type)

    local map = getIllMapByType_New(_type)

    local start =(line - 1) * illLineNumber + 1
    local ended = line * illLineNumber
    local lineData = { }
    for i = start, ended do
        table.insert(lineData, map[i])
    end
    return lineData
end

function getRelationCfg()
    local cfg = common:deepCopy(relationCfg)
    table.sort(cfg, function(a, b)
        local order1 = checkAvailableRelationById(a.id)
        local order2 = checkAvailableRelationById(b.id)
        if order1 ~= order2 then
            return order1 > order2
        else
            return a.order < b.order
        end
    end )
    return cfg
end

function sortRelationCfg()
    for k, v in pairs(relationCfg) do
        local team = v.team

        local sortTeam = { }
        for i, _v in ipairs(team) do
            CCLuaLog("sortRelationCfg :" .. tostring(_v))
            local tempKV = { showSort = 0, fetterId = _v }

            local illInfo = getIllCfgById(tempKV.fetterId)
            local roleInfo = getIllData(illInfo.roleId)
            if roleInfo then
                tempKV.showSort = roleInfo.activated and 10000 or(roleInfo.soulCount + 100)
            else
                tempKV.showSort = #team - i
            end

            table.insert(sortTeam, tempKV)
        end

        table.sort(sortTeam, function(first, second)
            return first.showSort > second.showSort
        end )

        v.team = { }
        for i, __v in ipairs(sortTeam) do
            table.insert(v.team, __v.fetterId)
        end
    end
end

function getRelationCfgById(id)
    return relationCfg[id]
end

function setViewFetterId(id)
    viewFetterId = id
end

function getViewFetterId()
    return viewFetterId
end

function clearViewFetterId()
    viewFetterId = 0
end

function getFetterIdByRoleId(roleId)
    local illustratedId = -1
    if not illCfg then
        illCfg = ConfigManager.getIllustrationCfg()
    end

    if not illCfg then
        return illustratedId
    end

    for i, v in ipairs(illCfg) do
        if v.roleId == roleId then
            illustratedId = v.id
            return illustratedId
        end
    end
    return illustratedId
end



function getAllRelationByFetterId(fetterId)
    local list = { }
    for k, v in pairs(relationCfg) do
        if common:table_hasValue(v.team, fetterId) then
            table.insert(list, v)
        end
    end
    return list
end

function showFetterPage(roldId)
    local fetterId = getFetterIdByRoleId(roldId)
    setViewFetterId(fetterId)
    PageManager.pushPage("FetterShowPage")
end

function initFetter(data)
    illData = { }
    for i = 1, #data.items do
        local item = data.items[i]
        illData[item.roleId] = {
            activated = item.activated,
            soulCount = item.soulCount
        }
    end
    relationIds = { }
    albumIds = { }
    for i = 1, #data.openFetters do
        local id = data.openFetters[i]
        relationIds[id] = 1
        albumIds[id] = data.star[i]
    end

    PageManager.refreshPage(moduleName, onFetterInfo)
end

function isRelationOpen(relationId)
    return relationIds[relationId] and relationIds[relationId] == 1
end

function getIllData(roleId)
    return illData[roleId]
end

function getIllCollectRate()
    local activeNum = 0
    for k, v in pairs(illData) do
        if v.activated then
            activeNum = activeNum + 1
        end
    end
    local totalNum = 0
    local _illMap = getIllMap()
    for k, v in pairs(_illMap) do
        for key, value in pairs(v.map) do
            if value.isOpen == 1 then 
                totalNum = totalNum + 1
            end
        end
    end
    return activeNum, totalNum
end

function checkAvailableRelations()
    local flag = false

    for i, v in ipairs(relationCfg) do
        if not relationIds[i] or relationIds[i] ~= 1 then
            local canActive = true
            for m, n in pairs(v.team) do
                local illItem = illData[getRoleIdByFetterId(n)]
                if illItem then
                    if not illItem.activated then
                        canActive = false
                        break
                    end
                else
                    canActive = false
                    break
                end
            end
            if canActive then
                flag = true
                break
            end
        end
    end

    return flag
end

function checkAvailableRelationById(relationId)
    if relationIds[relationId] then return 1 end
    local cfg = relationCfg[relationId]
    local canActive = true
    for m, n in pairs(cfg.team) do
        local illItem = illData[getRoleIdByFetterId(n)]
        if illItem then
            if not illItem.activated then
                canActive = false
                break
            end
        else
            canActive = false
            break
        end
    end
    if canActive then
        return 2
    end
    return 0
end

function initOtherFetter(data)
    if playerId and playerId > 0 and data.playerId == playerId then
        initFetter(data)
    end
end

function openRelation(data)
    relationIds[data.fetterId] = 1

    curOpenRelationId = data.fetterId

    PageManager.refreshPage(moduleName, onRelationOpen)
end

function clearOpenRelation()
    curOpenRelationId = nil
end

function getOpenRealtion()
    return curOpenRelationId
end

--- use for debug
function setOpenRelation(id)
    curOpenRelationId = id
end

function getRoleIdByFetterId(fetterId)
    local roleId = 0
    if illCfg[fetterId] then
        roleId = illCfg[fetterId].roleId
    end
    return roleId
end

function setCurOtherRoleInfo(roleInfo)
    curOthersRoleInfo = roleInfo
end

function clearCurOtherRoleInfo()
    curOthersRoleInfo = nil
end

function getCurOtherRoleInfo()
    return curOthersRoleInfo
end

function getCurOtherRoleByRoleId(roleId)
    for k, v in pairs(curOthersRoleInfo) do
        if v.itemId == roleId then
            return v
        end
    end
end

function getAlbumIdByFetterId(feeterId)
    return albumIds[feeterId]
end

---------------服务器返回---------------------
function onFetterInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPArchiveInfoRes();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        initFetter(msg)
        PageManager.refreshPage(moduleName,"FETCH_ARCHIVE_INFO_S")
        visibleOtherPageFetterPoint()
    end
end
HPFetterInfo = PacketScriptHandler:new(HP_pb.FETCH_ARCHIVE_INFO_S, onFetterInfoResp)

function onOtherFetterInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPArchiveInfoRes();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)

        initOtherFetter(msg)
    end
end
HPOtherFetterInfo = PacketScriptHandler:new(HP_pb.FETCH_OTHER_ARCHIVE_INFO_S, onOtherFetterInfoResp)

function onOpenFetterResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPOpenFetterRes();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)

        openRelation(msg)
    end
end
HPOpenFetter = PacketScriptHandler:new(HP_pb.OPEN_FETTER_S, onOpenFetterResp)

function validateAndRegister()
    HPFetterInfo:registerFunctionHandler(onFetterInfoResp)
    HPOtherFetterInfo:registerFunctionHandler(onOtherFetterInfoResp)
    HPOpenFetter:registerFunctionHandler(onOpenFetterResp)
end

function setOtherPageFetterPoint(point)
    reqFetterInfo(playerId)
    otherPagePoint = point
end

function visibleOtherPageFetterPoint()
    if otherPagePoint then
        otherPagePoint:setVisible(checkAvailableRelations())
        otherPagePoint = nil
    end
end