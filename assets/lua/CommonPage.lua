
----------------------------------------------------------------------------------
require("CocoDebug")

local CommonPage = { };



local function addPacketFunction(page, tb_opcode)
    if page == nil or type(page) ~= "table" then return end

    page.registerPacket = function(container)
        for key, opcode in pairs(tb_opcode) do
            if string.sub(key, -1) == "S" then
                container:registerPacket(opcode)
            end
        end
    end

    page.removePacket = function(container)
        for key, opcode in pairs(tb_opcode) do
            if string.sub(key, -1) == "S" then
                container:removePacket(opcode)
            end
        end
    end
end

CommonPage.new = function(pageName, opt)
    opt = opt or { }
    local page = { }
    page.handlerMap = opt.handlerMap or { }
    page.handlerMap = common:table_merge(page.handlerMap, CommonPage.handlerMap)
    local showLog = opt.showLog == true
    page.onFunction = function(eventName, container)
        if page.handlerMap[eventName] ~= nil then
            local funcName = page.handlerMap[eventName]
            xpcall( function()
                if page[funcName] then
                    page[funcName](container, eventName)
                end
            end , CocoLog)

        else
            CCLuaLog("error===>unExpected event Name : " .. pageName .. "->" .. eventName)
        end
    end
    table.foreach(page.handlerMap, function(eventName, funcName)
        if not page[funcName] then
            page[funcName] = function(container)
                if showLog then CCLuaLog(pageName .. "   " .. funcName .. "  called!") end
                if funcName == "onLoad" and opt.ccbiFile ~= nil then

                    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 and opt.ccbiFile_WIN32 ~= nil then
                        container:loadCcbiFile(opt.ccbiFile_WIN32)
                    else
                        container:loadCcbiFile(opt.ccbiFile)
                    end

                    -- container:loadCcbiFile(opt.ccbiFile)
                end
            end
        end
    end )

    _G["luaCreat_" .. pageName] = function(container)
        CCLuaLog("OnCreate__" .. pageName)
        container:registerFunctionHandler(page.onFunction)
    end

    if opt.opcode then
        addPacketFunction(page, opt.opcode)
    end

    return page
end

CommonPage.handlerMap = {
    luaInit = "onInit",
    luaLoad = "onLoad",
    luaUnLoad = "onUnload",
    luaExecute = "onExecute",
    luaEnter = "onEnter",
    luaExit = "onExit",
    luaOnAnimationDone = "onAnimationDone",
    luaReceivePacket = "onReceivePacket",
    luaGameMessage = "onReceiveMessage",
    luaInputboxEnter = "onInputboxEnter",
    luaSendPacketFailed = "onPacketError",
    luaConnectFailed = "onPacketError",
    luaTimeout = "onPacketError",
    luaPacketError = "onPacketError"
}

CommonPage.newSub = function(parent, pageName, option, func)
    local page = { }
    setmetatable(page, { __index = parent })
    if option == nil then return page end
    page.handlerMap = common:table_merge(option.handlerMap, CommonPage.handlerMap)
    local showLog = option.showLog == true
    page.onFunction = function(eventName, container)
        if page.handlerMap[eventName] ~= nil then
            local funcName = page.handlerMap[eventName]
            xpcall( function()
                        if eventName == "luaUnLoad" then
                            onUnload(pageName, container)
                        end
                        if page[funcName] and (funcName == "onExecute" or funcName == "onAnimationDone") then
                            page[funcName](page, container, eventName)
                        elseif page[funcName] then
                            page[funcName](page, container, eventName)
                        end
                    end , 
                    function(...)
                        debugPage[pageName] = container
                        CocoLog(...)
                    end 
             )
        else
            CCLuaLog("error===>unExpected event Name : " .. pageName .. "->" .. eventName)
        end
        if func ~= nil then
            func(eventName, container)
        end
    end
    table.foreach(page.handlerMap, function(eventName, funcName)
        if not page[funcName] then
            page[funcName] = function(pageSelf, container)
                if showLog then CCLuaLog(pageName .. "   " .. funcName .. "  called!") end
                if funcName == "onLoad" and option.ccbiFile ~= nil then
                    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 and option.ccbiFile_WIN32 ~= nil then
                        container:loadCcbiFile(option.ccbiFile_WIN32)
                    else
                        container:loadCcbiFile(option.ccbiFile)
                    end
                end
            end
        end
    end )



    _G["luaCreat_" .. pageName] = function(container)
        CCLuaLog("OnCreate__" .. pageName)
        container:registerFunctionHandler(page.onFunction)
    end

    return page
end

-------------------------------------------------------------
return CommonPage;