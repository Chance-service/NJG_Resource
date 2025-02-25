local json = require('json')

local TapDBManager = {}

function TapDBManager.setUser(userId,properties)
    if ((userId ~= nil) and (type(userId) == 'string')) then
        local data ={}
        data['funtion'] = 'setUser'
        data['param'] = userId -- str
        if ((properties ~= nil) and (type(properties) == 'string')) then
            data['properties'] = properties -- str
        end
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.setName(name)
    if ((name ~= nil) and (type(name) == 'string')) then
        local data ={}
        data['funtion'] = 'setName' 
        data['param'] = name -- str
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.setServer(svrname)
    if ((svrname ~= nil) and (type(svrname) == 'string')) then
        local data ={}
        data['funtion'] = 'setServer'
        data['param'] = svrname -- str
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.setLevel(level)
    if ((level ~= nil) and (type(level) == 'number')) then
        local data ={}
        data['funtion'] = 'setLevel'
        data['param'] = level -- int
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.trackEvent(eventName,properties)
    if ((eventName ~= nil) and (type(eventName) == 'string')) then
        if ((properties ~= nil) and (type(properties) == 'string')) then
            local data ={}
            data['funtion'] = 'trackEvent'
            data['param'] = eventName -- str
            data['properties'] = properties -- str
            libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
        end
    end
end

function TapDBManager.deviceUpdate(jsonstr)
    if ((jsonstr ~= nil) and (type(jsonstr) == 'string')) then
        local data ={}
        data['funtion'] = 'deviceUpdate'
        data['param'] = jsonstr -- str
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.deviceInitialize(jsonstr)
    if ((jsonstr ~= nil) and (type(jsonstr) == 'string')) then
        local data ={}
        data['funtion'] = 'deviceInitialize'
        data['param'] = jsonstr -- str
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.deviceAdd(jsonstr)
    if ((jsonstr ~= nil) and (type(jsonstr) == 'string')) then
        local data ={}
        data['funtion'] = 'deviceAdd'
        data['param'] = jsonstr -- str
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.userUpdate(jsonstr)
    if ((jsonstr ~= nil) and (type(jsonstr) == 'string')) then
        local data ={}
        data['funtion'] = 'userUpdate'
        data['param'] = jsonstr -- str
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.userInitialize(jsonstr)
    if ((jsonstr ~= nil) and (type(jsonstr) == 'string')) then
        local data ={}
        data['funtion'] = 'userInitialize'
        data['param'] = jsonstr -- str
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

function TapDBManager.userAdd(jsonstr)
    if ((jsonstr ~= nil) and (type(jsonstr) == 'string')) then
        local data ={}
        data['funtion'] = 'userInitialize'
        data['param'] = jsonstr -- str
        libPlatformManager:getPlatform():sendMessageG2P('G2P_TAPDB_HANDLER',json.encode(data))
    end
end

return TapDBManager
