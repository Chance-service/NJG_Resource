local HP_pb = require("HP_pb")
local thisPageName = "FlagData"
local FlagDataBase = { }
local FlagData={}
FlagDataBase.FlagId = {
    H_MINIGAME_1 = 11,
    H_MINIGAME_2 = 21,
    H_MINIGAME_3 = 31,
    H_MINIGAME_4 = 42,
    SECRET_MESSAGE_PASS = 50,
    BATTLE_SPEED_X4 = 51,
}

local option = {
    handlerMap = {
      
    },
    opcodes = {
        
    }
}

function FlagDataBase_SetStatus(data)
    if data.signId then
        for k,v in pairs (data.signId) do
            if k~="_listener" then
                FlagData[v]=1
            end
        end
    end
end

function FlagDataBase_ReqStatus()
    local msg = Sign_pb.SignRequest()
    msg.action = 0
    common:sendPacket(HP_pb.SIGN_SYNC_C, msg, false)
end

function FlagDataBase_GetData()
    return FlagData
end

function FlagDataBase_DataChange(id,bool)
    if id==nil then return end

    local _bool=true
    if bool~=nil then
        _bool=bool
    end

    local msg = Sign_pb.SignRequest()
    msg.action = 3
    msg.signId=id
    msg.setVal=_bool
    common:sendPacket(HP_pb.SIGN_SYNC_C, msg, false)
end

function FlagDataBase_DataSearch(id)
    if id==nil then return end
    local msg = Sign_pb.SignRequest()
    msg.action = 1
    msg.signId=id
    common:sendPacket(HP_pb.SIGN_SYNC_C, msg, false)
end




local CommonPage = require('CommonPage')
local FlagDataBase = CommonPage.newSub(FlagDataBase, thisPageName, option)

return FlagDataBase