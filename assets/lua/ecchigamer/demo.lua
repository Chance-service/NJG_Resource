
-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    print("----------------------------------------")
    print("LUA ERROR: " .. tostring(msg) .. "\n")
    print(debug.traceback())
    print("----------------------------------------")
end

--[[
    EcchiGamerSDK 的使用範例
]]

require "ecchigamer/EcchiGamerSDK"	


local function main()
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

    local layerMenu;

    ---------------------------------

    local cclog = function(...)
        release_print(string.format(...))
    end

    local createMenuItem = function(layer, title, x, y, clickHandler)
        local label = CCLabelTTF:create(title, "Arial", 38)
        local menuItemLabel = CCMenuItemLabel:create(label)
        menuItemLabel:registerScriptTapHandler(clickHandler)
    
        local menuItem = CCMenu:createWithItem(menuItemLabel)
        menuItem:setPosition(x, y)

        layer:addChild(menuItem)

        return menuItem
    end

    ---------------

    local onClickOpenLogin = function()
        cclog("onClickOpenLogin")

        local openLoginCallback = function (profileResult)
            if profileResult.isSuccess == false then
                cclog("EcchiGamerSDK login failed:"..profileResult.exception)
                return
            end

            cclog("login user_id:"..profileResult.user_id)
        end
        EcchiGamerSDK:openLogin(openLoginCallback)
    end

    local onClickOpenLogout = function()
        cclog("onClickOpenLogout")

        local openLogoutCallback = function (logoutResult)
            cclog("logout:")
        end
        EcchiGamerSDK:openLogout(openLogoutCallback)
    end

    local onClickOpenBind = function()
        cclog("onClickOpenBind")

        local openAccountBindGameCallback = function (profileResult)
            if profileResult.isSuccess == false then
                cclog("EcchiGamerSDK openAccountBindGame failed:"..profileResult.exception)
                return
            end

            cclog("openAccountBindGame user_id:"..profileResult.user_id)            
        end
        EcchiGamerSDK:postAccountBindGame("game001", openAccountBindGameCallback)
    end

    local onClickOpenPaymen = function()
        cclog("onClickOpenPaymen")

        EcchiGamerSDK:openPayment()
    end

    local onClickPostBind = function()
        cclog("onClickPostBind")

        local postAccountBindGameCallback = function (profileResult)
            if profileResult.isSuccess == false then
                cclog("EcchiGamerSDK postAccountBindGame failed:"..profileResult.exception)
                return
            end

            cclog("postAccountBindGame user_id:"..profileResult.user_id)
        end
        EcchiGamerSDK:postAccountBindGame("game001", postAccountBindGameCallback)
    end

    ---------------

    local onInitializeCallback = function (value)
        if value == false then
            cclog("EcchiGamerSDK initialize failed")
            return
        end

        layerMenu:setVisible(true)
    end

    ---------------    

    local visibleSize = CCDirector:sharedDirector():getVisibleSize()
    local origin = CCDirector:sharedDirector():getVisibleOrigin()

    layerMenu = CCLayer:create()
    local layerOrigin = { x = origin.x + 250, y = origin.y + visibleSize.height }
    createMenuItem(layerMenu, "Open Login", layerOrigin.x, layerOrigin.y - 50 * 1, onClickOpenLogin)
    createMenuItem(layerMenu, "Open Logout", layerOrigin.x, layerOrigin.y - 50 * 2, onClickOpenLogout)
    createMenuItem(layerMenu, "Open Bind", layerOrigin.x, layerOrigin.y - 50 * 3, onClickOpenBind)
    createMenuItem(layerMenu, "Open Payment", layerOrigin.x, layerOrigin.y - 50 * 4, onClickOpenPaymen)
    createMenuItem(layerMenu, "Post Bind", layerOrigin.x, layerOrigin.y - 50 * 5, onClickPostBind)
    layerMenu:setVisible(false)

    -- run
    local sceneGame = CCScene:create()
    sceneGame:addChild(layerMenu)
    CCDirector:sharedDirector():runWithScene(sceneGame)

    EcchiGamerSDK:initialize(onInitializeCallback)
end

xpcall(main, __G__TRACKBACK__)
