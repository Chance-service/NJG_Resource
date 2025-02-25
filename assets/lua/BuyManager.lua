local BuyManager = {}
local NowBuyInfo = nil 
local UserInfo = require("PlayerInfo.UserInfo");
local TapDBManager = require("TapDBManager")
local NewID = ""
function BuyManager.Buy(playerId, buyInfo)
     if (Golb_Platform_Info.is_h365) or (Golb_Platform_Info.is_jgg)or(Golb_Platform_Info.is_kuso) then --H365, jgg ,kuso
        libPlatformManager:getPlatform():buyGoods(buyInfo)
     elseif (Golb_Platform_Info.is_r18) then --R18
        local title = Language:getInstance():getString("@SDK3")
        local message = ""
        local yesStr = ""

        local openBindGameCallback = function (BindGameResult)
            CCLuaLog("BindGameResult1")
            CCLuaLog("isSuccess = " .. tostring(BindGameResult.isSuccess))
            CCLuaLog("result: " .. BindGameResult.result)
            if BindGameResult.isSuccess == true then
                local userID = BindGameResult.user_id
                local token = EcchiGamerSDK.getToken()
                CCLuaLog("userID: " .. userID)
                CCLuaLog("token: " .. token)
                --libPlatformManager:getPlatform():setIsGuest(0)
                -- to server bind --
                local AccountBound_pb = require("AccountBound_pb")
                local msg = AccountBound_pb.HPAccountBoundConfirm()
                msg.userId = userID
                msg.wallet = ""
                NewID = userID
                common:sendPacket(HP_pb.ACCOUNT_BOUND_REWARD_C, msg, false)
            else
                CCLuaLog("BindGameResult2")
                if BindGameResult.exception ~= "" then
                    CCLuaLog("exception: " .. BindGameResult.exception)
                end
                CCLuaLog("errorCode: " .. BindGameResult.result)
                MessageBoxPage:Msg_Box_Lan("@ERRORCODE_12003")
            end
            CCLuaLog("BindGameResult3")
        end
        local IsGuest = libPlatformManager:getPlatform():getIsGuest() 
        if (IsGuest == 0) then
            local honeyp = libPlatformManager:getPlatform():getHoneyP()
            CCLuaLog("HoneyP : " .. honeyp)
            if (honeyp < buyInfo.productPrice) then -- Honeyp not enough

				message = Language:getInstance():getString("@SDK4")
				yesStr = Language:getInstance():getString("@SDK5")

                local openPayment = function(bool)
                    if bool then
                    --
                        EcchiGamerSDK:openPayment()
                    --
                    end
                end

			    PageManager.showConfirm(title, message, openPayment, true, yesStr)
			else -- enough
			     local buyShopItem = function(bool)
                    if bool then
                    --
                        local playtoken =  CCUserDefault:sharedUserDefault():getStringForKey("ecchigamer.token")
                        if (playtoken ~= "")
                        then
                            local msg = Shop_pb.HoneyPBuyRequest()
                            msg.token = playtoken
                            msg.pid = tonumber(buyInfo.productId)
                            common:sendPacket(HP_pb.SHOP_HONEYP_BUY_C, msg, true);
                        end
                    --
                    end
                end
                message = common:fill(Language:getInstance():getString("@SDK6"), tostring(honeyp))
				NowBuyInfo = buyInfo
				PageManager.showConfirm(title, message, buyShopItem, true)
			end
		else
            local GotoBindCheck = function(bool)
                if bool then
                    --
                    EcchiGamerSDK:openAccountBindGame(UserInfo.playerInfo.playerId, openBindGameCallback)
                    --
                end
            end
			message = Language:getInstance():getString("@SDK9")
			yesStr = Language:getInstance():getString("@SDK10")

			PageManager.showConfirm(title, message, GotoBindCheck, true, yesStr)
		end
     end       
end

function BuyManager:SendtogetHoneyP()
    local playtoken =  CCUserDefault:sharedUserDefault():getStringForKey("ecchigamer.token")
    CCLuaLog("SendtogetHoneyP1 token : " .. playtoken)
    if (playtoken ~= "") then
        local msg = Shop_pb.HoneyPRequest()
        msg.token = playtoken
        common:sendPacket(HP_pb.SHOP_HONEYP_C, msg, true);-- getHoneyP
        CCLuaLog("SendtogetHoneyP2")
    end
end

function BuyManager:onReceiveBuyPacket(opcode, msgBuff) --R18 USE
    CLuaLog("BuyManager:onReceiveBuyPacket : " .. opcode)
end

function BuyManager:onReceiveBoundAccount() --R18 USE
    CCLuaLog("----------Bind Success--------------")
    MessageBoxPage:Msg_Box_Lan("@SDK12")
    CCUserDefault:sharedUserDefault():setStringForKey("ecchigamer.token", EcchiGamerSDK.getToken())
    libPlatformManager:getPlatform():setIsGuest(0)
    
    local serverId = GamePrecedure:getInstance():getServerID()
    
    local oldId = GamePrecedure:getInstance():getUin()
    GamePrecedure:getInstance():setUin(NewID)
    
    TapDBManager.setUser(GamePrecedure:getInstance():getUin())
    TapDBManager.setName(tostring(UserInfo.roleInfo.name))
    TapDBManager.setServer(GamePrecedure:getInstance():getServerNameById(serverId))
    TapDBManager.setLevel(UserInfo.roleInfo.level)
    
    CCLuaLog("----------Bind End--------------")
end

return BuyManager