--[[----------------------------------------------
@ module("LeaderAvatarManager")
 
--]]----------------------------------------------
local ConfigManager = require("ConfigManager")
local common = require("common")
local HP_pb = require("HP_pb")
local RoleOpr_pb = require("RoleOpr_pb")
local Const_pb = require("Const_pb")
local PageManager = require("PageManager")
local GameConfig = require("GameConfig")
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
local rawset = rawset
local rawget = rawget


module("LeaderAvatarManager")

moduleName = "LeaderAvatarManager"

local avatarCfg = {}

-----事件
onAvatarChange = "onAvatarChange"
onAvatarCheck = "onAvatarCheck"
onAvatarList = "onAvatarList"

----属性表
local selfProps = {
    -----当前皮肤
    nowAvatarId = {
        get = 2,
        set = function(v)
            PageManager.refreshPage(moduleName,onAvatarChange)
        end,
        default = -1,
        notClean = true
    },
    -----皮肤列表
    avatarInfoList = {
        get = 2,
        set = function(v)
            PageManager.refreshPage(moduleName,onAvatarList)
        end,
        default = {},
        notClean = true
    },
    -----当前皮肤配置
    nowAvatarItemInfo = {
        get = function()
            local avatarList = _M:getAvatarInfoList()
            local nowId = _M:getNowAvatarId()
            for i,v in ipairs(avatarList) do
                if v.id == nowId then
                    return v
                end
            end
            local original = RoleOpr_pb.AvatarInfo()
            original.id = 0
            original.avatarId = 0
            original.checked = true
            original.endTime = -1
            return original
        end,
        set = 0,
        default = 0,
    },
    -----红点列表
    NoticeAvatarList = {
        get = function()
            local avatarList = _M:getAvatarInfoList()
            local list = {}
            local size = 0
            for i,v in ipairs(avatarList) do
                if v.checked == false then
                    list[v.id] = 1;
                    size = size + 1
                end
            end
            return list, size
        end,
        set = 0,
        default = {},
        notClean = true
    },
    -----预览
    previewItem = {
        get = 2,
        set = 2,
        default = nil,
    },
    previewShop = {
        get = 2,
        set = 2,
        default = nil,
    },
    nowStaticId = {
        get = 2,
        set = 2,
        default = -1
    }
}

function initAllCfg()
    avatarCfg = common:deepCopy(ConfigManager.getLeaderAvatarCfg())
end

function initModule()
    common:initModuleProperty(_M, selfProps, true)
end

function clearTempData()
    common:resetModuleProperty(_M, selfProps, true)
end

function isNeedShowNotice(id)
    local noticeList = _M:getNoticeAvatarList()
    return noticeList[id] ~= nil
end

function getAvatarCfg(id)
    return avatarCfg[id]
end

function getAvatarInfo(id)
    local avatarList = _M:getAvatarInfoList()
    for i,v in ipairs(avatarList) do
        if v.avatarId == id then
            return v
        end
    end
    if id == 0 then
        local original = RoleOpr_pb.AvatarInfo()
        original.id = 0
        original.avatarId = 0
        original.checked = true
        original.endTime = -1
        return original
    end
end

function getCurShowCfg()
    if UserInfo.roleInfo.avatarId > 0 then
        return GameConfig.LeaderAvatarInfo[UserInfo.roleInfo.avatarId]
    else
        local nowInfo = _M:getNowAvatarItemInfo()
        return GameConfig.LeaderAvatarInfo[nowInfo.avatarId]
    end
end

function getOthersShowCfg(avatarId)
    return GameConfig.LeaderAvatarInfo[avatarId]
end

-----------
function reqAvataInfo()
    common:sendEmptyPacket(HP_pb.ROLE_AVATAR_INFO_C, false)
end

function reqCheckAvatar(id)
    local msg = RoleOpr_pb.HPCheckMainRoleAvatarReq()
    msg.id = id
    common:sendPacket(HP_pb.ROLE_CHECK_AVATAR_C, msg , false)
end

function reqChangeAvatar(id)
    local msg = RoleOpr_pb.HPChangeMainRoleAvatarReq()
    msg.id = id
    common:sendPacket(HP_pb.ROLE_CHANGE_AVATAR_C, msg , true)
end


-------------
function onAvatarInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPMainRoleAvatarInfoRes();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        
        if msg.avatars then
            local list = {}
            local original = RoleOpr_pb.AvatarInfo()
            original.id = 0
            original.avatarId = 0
            original.checked = true
            original.endTime = -1
            table.insert(list, original)
            for i,v in ipairs(msg.avatars) do
                table.insert(list,v)
            end
            
            _M:setAvatarInfoList(list)
        end
        if msg:HasField("usedId") then
            if msg.usedId == 0 then
                UserInfo.roleInfo.avatarId = 0
            else
                local config = getAvatarCfg(_M:getNowAvatarItemInfo().avatarId)
                UserInfo.roleInfo.avatarId = config and config.id or 0
            end
            _M:setNowAvatarId(msg.usedId)
        end
    end
end
local HPAvatarInfo = PacketScriptHandler:new(HP_pb.ROLE_AVATAR_INFO_S, onAvatarInfoResp)

function onAvatarCheckResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPCheckMainRoleAvatarRes();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        local avatarList = _M:getAvatarInfoList()
        for i,v in ipairs(avatarList) do
            if v.id == msg.id then
                v.checked = true
            end
        end
        PageManager.refreshPage(moduleName,onAvatarCheck)
    end
end
local HPAvatarCheck = PacketScriptHandler:new(HP_pb.ROLE_CHECK_AVATAR_S, onAvatarCheckResp)

function onAvatarChangeResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPChangeMainRoleAvatarRes();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg:HasField("id") then
            _M:setNowAvatarId(msg.id)
        end
    end
end
local HPAvatarChange = PacketScriptHandler:new(HP_pb.ROLE_CHANGE_AVATAR_S, onAvatarChangeResp)

function validateAndRegister()
    HPAvatarInfo:registerFunctionHandler(onAvatarInfoResp)
    HPAvatarCheck:registerFunctionHandler(onAvatarCheckResp)
    HPAvatarChange:registerFunctionHandler(onAvatarChangeResp)
end

initAllCfg()
initModule()