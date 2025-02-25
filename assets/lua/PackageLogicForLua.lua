local Hp_pb = require "HP_pb"
local Player_pb = require("Player_pb")
local Reward_pb = require "Reward_pb"
local Notice_pb = require "Notice_pb"
local MessageFlowPopPage = require "MessageFlowPopPage"
local MessageFlowSeriesPage = require "MessageFlowSeriesPage"
local Chat_pb = require "Chat_pb"
local SysProtocol_pb = require "SysProtocol_pb"
local Login_pb = require "Login_pb"
local Battle_pb = require "Battle_pb"
local Friend_pb = require "Friend_pb"
local Consume_pb = require "Consume_pb";
local Const_pb = require("Const_pb");
local HeroToken_pb = require("HeroToken_pb")
local mission = require("Mission_pb")
local alliance = require("Alliance_pb")
local Shop_pb = require("Shop_pb");
local Item_pb = require("Item_pb");
local GameConfig = require("GameConfig");
local EquipOprHelper = require("Equip.EquipOprHelper");

local ChatManager = require("Chat.ChatManager");
local SkillManager = require("Skill.SkillManager")
local PackageLogicForLua = { }
local UserInfo = require("PlayerInfo.UserInfo");
local ConfigManager = require("ConfigManager")
local HeroOrderItemManager = require("Item.HeroOrderItemManager")
local common = require("common")
local PageManager = require("PageManager")
local MainScenePage = require("MainScenePage");
local SoulStarManager = require("Leader.SoulStarManager")
local OSPVPManager = require("OSPVPManager")
local RoleOpr_pb = require("RoleOpr_pb")
local SevenDayQuest_pb = require("SevenDayQuest_pb")
local EighteenPrinces_pb = require("EighteenPrinces_pb")
local SecretMsg_pb = require("SecretMsg_pb")
local Activity4_pb = require("Activity4_pb")

-- Test
-- mailInvalidateList = {}

local noticeCache = { };

g_firstGotMapStatic = false
g_mapStaticMsg = { }

-- 充值列表，只存储了部分数据
g_RechargeItemList = { }
-- 是否收到活动列表
g_bHasReceiveActityInfo = false
-- 当前是否处于月卡状态
g_IsInMonthCardStatus = false

local chatCloseFlag = -1

-- 工会聊天list
memberChatList = { }
-- 世界聊天list
worldChatList = { }
-- 世界广播list
worldBroadCastList = { }
-- 跨服聊天List
crossChatList = { }
-- 聊天页面的红点
hasNewChatComing = false
-- 聊天页面中“新的世界聊天”红点
hasNewWorldChatComing = false
-- 聊天页面中“新的跨服聊天”红点
hasNewCrossChatComing = false
-- 聊天页面中“新的工会聊天”红点
hasNewMemberChatComing = false
-- 聊天页面中“新的个人聊天”红点
hasNewPrivateChatComing = false
-- 聊天页面中“新的聊天框皮肤”红点
hasNewChatSkin = false
-- 当前聊天框皮肤Id
curSkinId = nil
-- 是否需要弹出聊天框界面
showChatSkinPage = false
-- 游戏注册天数
curLoginDay = 0
-- 全局变量
GlobalData = { }
registDay = 0

local jggOrderId = nil
local jggTimer = 0
local jggOrderCount = 0
local jggDelayTime = { [0] = 0, [1] = 3000, [2] = 3000, [3] = 6000, [4] = 6000, [5] = 6000, [6] = 6000, [7] = 6000, [8] = 60000, [9] = 60000 }

local employRoleIds = { }   -- 送出啟用的roleId 避免重複請求

-- 首次進入遊戲時loading檢查
local loadingOpcodes = {
    [HP_pb.ROLE_PANEL_INFOS_S] = { done = false, lock = nil },
    --[HP_pb.MULTIELITE_LIST_INFO_S] = { done = false, lock = GameConfig.LOCK_PAGE_KEY.DUNGEON },
    [HP_pb.FETCH_SHOP_LIST_S] = { done = false, lock = nil },
    [HP_pb.NP_CONTINUE_RECHARGE_MONEY_S] = { done = false, lock = nil },
}
local loadingClose = false
local loadingTime = 0

function ChatList_Reset()
    memberChatList = { }

    local VoiceChatManager = require("Battle.VoiceChatManager")

    VoiceChatManager.guildChatMessageTmpList = { }
    VoiceChatManager.worldChatMessageTmpList = { }
    VoiceChatManager.crossChatMessageTmpList = { }
    VoiceChatManager.guildChatMessageTmpList = common:deepCopy(VoiceChatManager.guildChatMessageList)
    VoiceChatManager.worldChatMessageTmpList = common:deepCopy(VoiceChatManager.worldChatMessageList)
    VoiceChatManager.crossChatMessageTmpList = common:deepCopy(VoiceChatManager.crossChatMessageList)
    VoiceChatManager.guildChatMessageList = { }
    VoiceChatManager.worldChatMessageList = { }
    VoiceChatManager.crossChatMessageList = { }
    worldChatList = { }

    worldBroadCastList = { }
end

function PackageLogicForLua.Update(dt)
    -- 空tick，用于保留PackageLogicForLua 对象，不被GC
    if jggOrderCount >= #jggDelayTime then
        jggOrderId = nil
        jggTimer = 0
        jggOrderCount = 0
    end
    if jggOrderId and jggDelayTime[jggOrderCount] then
        if jggTimer >= jggDelayTime[jggOrderCount] then
            local message = Shop_pb.JggGetGoods()
            if message ~= nil then
	            message.orderid = jggOrderId
                local pb_data = message:SerializeToString()
                PacketManager:getInstance():sendPakcet(HP_pb.SHOP_JGG_ORDER_C, pb_data, #pb_data, true)
            end
            jggTimer = 0
            jggOrderId = nil
            jggOrderCount = jggOrderCount + 1
        else
            jggTimer = jggTimer + dt
        end
    end
end

-----------------Player state handler-------------------
function PackageLogicForLua.onReceivePlayerStates(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Player_pb.HPPlayerStateSync();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        CCLuaLog("@onReceivePlayerStates -- ");
        if msg ~= nil then
            local oldpassMapId = UserInfo.stateInfo.passMapId
            UserInfo.stateInfo = msg;
            local a = msg.passMapId
            local b = msg.bossFightTimes
            if oldpassMapId and UserInfo.stateInfo.passMapId and oldpassMapId < UserInfo.stateInfo.passMapId then
                -- GameUtil:sendUserData(UserInfo.level, UserInfo.stateInfo.passMapId)
            end

            if chatCloseFlag ~= msg.chatClose then
                chatCloseFlag = msg.chatClose
            end
            -- 音乐，音效进入时候的播放
            if UserInfo.stateInfo.musicOn ~= nil and UserInfo.stateInfo.soundOn ~= nil then
                --if UserInfo.isPlayStory then
                    SoundManager:getInstance():setMusicOn(tonumber(UserInfo.stateInfo.musicOn) >= 1)
                    SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(UserInfo.stateInfo.musicOn / 10)
                --else
                --    SoundManager:getInstance():setMusicOn(false)
                --end
                SoundManager:getInstance():setEffectOn(tonumber(UserInfo.stateInfo.soundOn) >= 1)
                SimpleAudioEngine:sharedEngine():setEffectsVolume(UserInfo.stateInfo.soundOn / 10)
            end
            -- 调整字体的大小
            if UserInfo.stateInfo.fontSize ~= nil then
                if FightLogConfig ~= nil and FreeTypeConfig ~= nil then
                    ConfigManager:changeFightLogConfig()
                end
            end
            if msg:HasField("curBattleMap") or msg:HasField("fastFightBuyTimes") then
            end

            if msg:HasField("passMapId") or msg:HasField("bossFightTimes") then
            end

            --if msg:HasField("currentEquipBagSize") then
            --    UserEquipManager:checkPackage();
            --    PageManager.refreshPage("PackagePage", "refreshBagSize");
            --end
            if msg:HasField("equipSmeltRefesh") then
                UserInfo.smeltInfo.freeRefreshTimes = msg.equipSmeltRefesh;
            end
            -- TODO:  æ–°æ‰‹å¼•å¯¼é…ç½®åˆå§‹åŒ?
            --[[			if EFUNSHOWNEWBIE() then
				CCLuaLog("-------------------æ–°æ‰‹å¼•å¯¼é…ç½®åˆå§‹åŒ?---------")
				Newbie.init()
				CCLuaLog("-------------------æ–°æ‰‹å¼•å¯¼é…ç½®åˆå§‹åŒ?---------")
			end]]
            -- 成就阶段
            --[[if msg:HasField("questStep") then
				local AchievementManager = require("PlayerInfo.AchievementManager")
				AchievementManager.AchievementState = msg.questStep
			end]]
            --

            -- 元素背包大小
            if msg:HasField("elementBagSize") then
                --local ElementManager = require("Element.ElementManager")
                -- ElementManager:checkPackage()
                --PageManager.refreshPage("ElementPackagePage")
            end
            --友情點數
            if msg:HasField("friendship") then
                UserInfo.stateInfo.friendship = msg.friendship
            end
            --vip點數
            if msg:HasField("vipPoint") then
                UserInfo.stateInfo.vipPoint = msg.vipPoint
            end
            -- 刷新
            if not msg.isFirstLogin then
                local msg2 = MsgRechargeSuccess:new()
			    MessageManager:getInstance():sendMessageForScript(msg2)
                CCLuaLog("isFirstLogin == false")
            else
                CCLuaLog("isFirstLogin == true")
            end
            -- 工口刷新honeyP
            if (Golb_Platform_Info.is_r18) then
                local playtoken =  CCUserDefault:sharedUserDefault():getStringForKey("ecchigamer.token")
                local IsGuest = libPlatformManager:getPlatform():getIsGuest() 
                if (playtoken ~= "") and (IsGuest == 0) then
                    CCLuaLog("onReceivePlayerStates SendtogetHoneyP")
                    local msg = Shop_pb.HoneyPRequest()
                    msg.token = playtoken
                    common:sendPacket(HP_pb.SHOP_HONEYP_C, msg, false)
                end
            end
        else
            CCLuaLog("@onReceivePlayerStates -- error in data");
        end
    end
end
PackageLogicForLua.HPStateInfoSyncHandler = PacketScriptHandler:new(HP_pb.STATE_INFO_SYNC_S, PackageLogicForLua.onReceivePlayerStates);
--影片故事影片是否播放同步
function PackageLogicForLua.onReceivePlayStroyDone(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Guide_pb = require("Guide_pb")
        local msg = Guide_pb.HPPlayStorySync();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg ~= nil then
             UserInfo.isPlayStory = (msg.isDone == 1)
              CCLuaLog("@onReceivePlayerStoryDone -- ".. msg.isDone);
        end
    end
end
PackageLogicForLua.HPPlayStoryDoneSyncHandler = PacketScriptHandler:new(HP_pb.PLAYSTORYDONE_SYNC_S, PackageLogicForLua.onReceivePlayStroyDone);
-- 引导状态同步
function PackageLogicForLua.onReceiveGuideInfoRet(eventName, handler)
    if eventName == "luaReceivePacket" then
        local GuideManager = require("Guide.GuideManager")
        local Guide_pb = require("Guide_pb")
        local msg = Guide_pb.HPGuideInfoSync()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if #msg.guideInfoBean > 0 then
            for i = 1, #msg.guideInfoBean do
                if not GuideManager.currGuide[msg.guideInfoBean[i].guideId] then
                    GuideManager.currGuide[msg.guideInfoBean[i].guideId] = msg.guideInfoBean[i].step
                end
            end
        end
    end
end
PackageLogicForLua.HPGuideInfoRet = PacketScriptHandler:new(HP_pb.GUIDE_INFO_SYNC_S, PackageLogicForLua.onReceiveGuideInfoRet)

-- 公告
function PackageLogicForLua.onReceiveAnnounceInfoRet(eventName, handler)
    if eventName == "luaReceivePacket" then
        local AnnounceDownLoad = require("AnnounceDownLoad")
        AnnounceDownLoad.start()
    end
end
-- PackageLogicForLua.HPAnnounceInfoRet = PacketScriptHandler:new(HP_pb.GUIDE_INFO_SYNC_S, PackageLogicForLua.onReceiveAnnounceInfoRet)

-----------------Assembly finish handler---
function PackageLogicForLua.onReceiveAsemblyFinish(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Player_pb.HPPlayerStateSync();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        CCLuaLog("@onReceiveAsemblyFinish -- ");
        local HeroOrderItemManager = require("Item.HeroOrderItemManager")
        HeroOrderItemManager:resetData();
        if msg ~= nil then
            MainScene_ResetForAssembly()
            require("ABManager")
            ABManager_ResetForAssembly()
        else
            CCLuaLog("@onReceiveAsemblyFinish -- error in data");
        end
    end
end
PackageLogicForLua.HPAssemblyFinishHandler = PacketScriptHandler:new(HP_pb.ASSEMBLE_FINISH_S, PackageLogicForLua.onReceiveAsemblyFinish);

function PackageLogicForLua.onReceiveMultiEliteShopInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local MultiElite_pb = require("MultiElite_pb")
        local msg = MultiElite_pb.HPMultiEliteShopInfoRet();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)

        if msg ~= nil then
        end
    end
end
PacketScriptHandler:new(HP_pb.MULTIELITE_SHOP_INFO_S, PackageLogicForLua.onReceiveMultiEliteShopInfo);

function PackageLogicForLua.onRecieveHeroTaskInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local HeroOrderItemManager = require("Item.HeroOrderItemManager")
        local msg = HeroToken_pb.HPHeroTokenTaskInfoRet();
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        if msg ~= nil then
            -- HeroOrderItemManager:updateTaskListInfo(msg.taskStatusBeanList)
            HeroOrderItemManager:updateHeroTokenInfo(msg)

            if msg.version == 2 then
                PageManager.pushPage("HeroOrderTaskPage")
            end
        end
    end
end
PackageLogicForLua.HPRecieveHeroTaskInfoHandler = PacketScriptHandler:new(HP_pb.HERO_TOKEN_TASK_INFO_S, PackageLogicForLua.onRecieveHeroTaskInfo)

-----------player kick out handler------------
function PackageLogicForLua.onPlayerKickOut(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Player_pb.HPPlayerKickout();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        CCLuaLog("@onPlayerKickOut -- ");
        if msg ~= nil then
            local reason = msg.reason;
            local title = Language:getInstance():getString("@LogOffTitle")
            local message = ""
            if reason == Const_pb.DUPLICATE_LOGIN then
                message = Language:getInstance():getString("@DuplicateLogin")
            elseif reason == Const_pb.SERVER_SHUTDOWN then
                message = Language:getInstance():getString("@ServerShutDown")
            elseif reason == Const_pb.LOGIN_FORBIDEN then
                message = Language:getInstance():getString("@LoginForbiden")
            elseif reason == Const_pb.KICKED_OUT then
                message = Language:getInstance():getString("@HasKickedOut")
            else
                -- 其他原因否则直接 return
                return
            end
            local sureToLogOut = function(flag)
                if flag then
                    --
                    GamePrecedure:getInstance():reEnterLoading();
                    --
                end
            end;
            PageManager.showConfirm(title, message, sureToLogOut, nil, nil, nil, CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32, 
                                    nil, CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32)
        else
            CCLuaLog("@onPlayerKickOut -- error in data");
        end
    end
end
PackageLogicForLua.HPPlayerKickOutHandler = PacketScriptHandler:new(HP_pb.PLAYER_KICKOUT_S, PackageLogicForLua.onPlayerKickOut);

-----------chat msg handler-----------
function PackageLogicForLua.onReceiveChatMsg(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Chat_pb.HPPushChat();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        CCLuaLog("@onReceiveChatMsg -- ");
        local isReceiveWorldMsg = false
        local isReceiveGuildMsg = false
        local isReceiveCspvpMsg = false
        if msg ~= nil then
            local chatSize = #msg.chatMsg
            local maxSize = GameConfig.ChatMsgMaxSize;
            local VoiceChatManager = require("Battle.VoiceChatManager")

            local playerIds = { }
            for i = 1, chatSize do
                local oneChatMsg = msg.chatMsg[i]
                local chatType = oneChatMsg.type


                if oneChatMsg.msgType ~= nil and oneChatMsg.msgType == 1 then
                    if not string.find(oneChatMsg.chatMsg, "#1#") and not string.find(oneChatMsg.chatMsg, "#D#") then
                        if not string.find(oneChatMsg.chatMsg, "gvgSeasonEnd") then
                            oneChatMsg.chatMsg = common:getI18nChatMsg(oneChatMsg.chatMsg)
                        end
                    end
                    oneChatMsg.msgType = 0
                end
                local inShield = ChatManager.isInShield(oneChatMsg.playerId)
                if inShield == false then
                    if chatType == Const_pb.CHAT_WORLD then
                        -- 					if not common:table_isEmpty(worldChatList) then
                        -- 						hasNewChatComing = true
                        -- 						hasNewWorldChatComing = true
                        -- 					end
                        -- 					if #worldChatList > maxSize then
                        -- 						table.remove(worldChatList,1)
                        -- 					end
                        -- 					table.insert(worldChatList,oneChatMsg);
                        table.insert(playerIds, oneChatMsg.playerId)
                        VoiceChatManager.receiveMessage(oneChatMsg, Const_pb.CHAT_WORLD)
                        -- hasNewChatComing = true
                        -- hasNewWorldChatComing = true
                        isReceiveWorldMsg = true
                    elseif chatType == Const_pb.CHAT_ALLIANCE then
                        table.insert(playerIds, oneChatMsg.playerId)
                        VoiceChatManager.receiveMessage(oneChatMsg, Const_pb.CHAT_ALLIANCE)
                        -- hasNewChatComing = true
                        -- hasNewMemberChatComing = true
                        isReceiveGuildMsg = true
                    elseif chatType == Const_pb.CHAT_BROADCAST then
                        oneChatMsg.name = common:getLanguageString("@System")
                        oneChatMsg.playerId = GameConfig.SystemId
                        -- 表示为系统消息

                        local isGuild = false
                        if string.find(oneChatMsg.chatMsg, "@declareBattle") and not string.find(oneChatMsg.chatMsg, "@declareBattleNpc") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            local cityCfg = GVGManager.getCityCfg(msg.data[3])
                            local str = common:getLanguageString(msg.key, msg.data[1], msg.data[2], cityCfg.cityName)
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "@declareBattleNpc") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            local cityCfg = GVGManager.getCityCfg(msg.data[2])
                            local str = ""
                            if cityCfg.level == 0 then
                                str = common:getLanguageString("@GVGRevive", msg.data[1], cityCfg.cityName)
                            else
                                str = common:getLanguageString(msg.key, msg.data[1], cityCfg.cityName)
                            end
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "@declareFightback") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            local cityCfg = GVGManager.getCityCfg(msg.data[3])
                            local str = common:getLanguageString(msg.key, msg.data[1], msg.data[2], cityCfg.cityName)
                            oneChatMsg.chatMsg = str
                            isGuild = true
                        elseif string.find(oneChatMsg.chatMsg, "@attackerWin") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            local cityCfg = GVGManager.getCityCfg(msg.data[3])
                            local str = common:getLanguageString(msg.key, msg.data[1], msg.data[2], cityCfg.cityName)
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "@defenderWin") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            local cityCfg = GVGManager.getCityCfg(msg.data[3])
                            local str = common:getLanguageString(msg.key, msg.data[1], msg.data[2], cityCfg.cityName)
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "@fightbackWin") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            local cityCfg = GVGManager.getCityCfg(msg.data[3])
                            local str = common:getLanguageString(msg.key, msg.data[1], msg.data[2], cityCfg.cityName)
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "@attackCityNotice") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            local cityCfg = GVGManager.getCityCfg(msg.data[3])
                            local str = common:getLanguageString(msg.key, msg.data[1], msg.data[2], cityCfg.cityName)
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "@fightbackFail") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            local cityCfg = GVGManager.getCityCfg(msg.data[3])
                            local str = common:getLanguageString(msg.key, msg.data[1], msg.data[2], cityCfg.cityName)
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "@changeAllianceNameNotice") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local str = common:getLanguageString(msg.key, msg.data[1], msg.data[2])
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "@gvgSeasonEnd") then
                            local json = require("json")
                            local msg = json.decode(oneChatMsg.chatMsg)
                            local str = common:getLanguageString(msg.key, msg.data[2], msg.data[1])
                            oneChatMsg.chatMsg = str
                        elseif string.find(oneChatMsg.chatMsg, "#D#") then
                            local argStr, htmlId = unpack(common:split(oneChatMsg.chatMsg, "#D#"));
                            local args = common:split(argStr, "#DD#");
                            --for key, value in pairs(args) do
                            --    if (string.find(value, "@Role_")) then
                            --        -- 需要区分一下是否是时装
                            --        local ss, roleId = unpack(common:split(value, "_"));
                            --        local roleCfg = ConfigManager.getRoleCfg();
                            --        local avatarName = roleCfg[tonumber(roleId)].avatarName;
                            --        if avatarName ~= nil and avatarName ~= "" and avatarName ~= "0" then
                            --            local t = common:split(roleCfg[tonumber(roleId)].name, "·")
                            --            if t ~= nil and t[2] ~= nil then
                            --                args[key] = common:getLanguageString(avatarName) .. "·" .. t[2]
                            --            else
                            --                args[key] = common:getLanguageString(avatarName)
                            --            end
                            --
                            --        else
                            --            args[key] = common:getLanguageString(value);
                            --        end
                            --    end
                            --end
                            local Name=common:getLanguageString("@HeroName_"..args[2])
                            args[2]=Name
                            local wingStr = common:fillNormalHtmlStr(tonumber(10), unpack(args));
                            oneChatMsg.chatMsg = wingStr
                            oneChatMsg.skinId = -9999
                        end
                        VoiceChatManager.receiveMessage(oneChatMsg, Const_pb.CHAT_WORLD)

                        if #worldChatList > maxSize then
                            table.remove(worldChatList, 1)
                        end
                        table.insert(worldChatList, oneChatMsg);

                        -- 					if #memberChatList > maxSize then
                        -- 						table.remove(memberChatList, 1)
                        -- 					end
                        -- 					table.insert(memberChatList, oneChatMsg);
                        -- hasNewChatComing = true
                        -- hasNewWorldChatComing = true
                        isReceiveWorldMsg = true
                        -- 只有工会开启的情况下才让工会聊天的红点显示，暂时不偿
                        --[[					if AllianceOpen then
						hasNewMemberChatComing = true
						end--]]
                    elseif chatType == Const_pb.CHAT_ALLIANCE_SYSTEM then
                        if string.find(oneChatMsg.chatMsg, "@sendRoleDefender") then
                        else
                            oneChatMsg.name = common:getLanguageString("@System")
                            oneChatMsg.playerId = GameConfig.SystemId
                            -- 表示为系统消息
                            VoiceChatManager.receiveMessage(oneChatMsg, Const_pb.CHAT_ALLIANCE)
                            -- hasNewChatComing = true
                            -- hasNewMemberChatComing = true
                            isReceiveGuildMsg = true
                        end
                    elseif chatType == Const_pb.WORLD_BROADCAST then
                        if #crossChatList > maxSize then
                            table.remove(crossChatList, 1)
                        end
                        --
                        -- 策划需求 抽到卡的跑马灯需要优先显示
                        if (string.find(oneChatMsg.chatMsg, "#D#")) then
                            table.insert(worldBroadCastList, 1, oneChatMsg);
                        else
                            table.insert(worldBroadCastList, oneChatMsg);
                        end
                        -- the end
                    elseif chatType == Const_pb.CHAT_CROSS_PVP then
                        VoiceChatManager.receiveMessage(oneChatMsg, Const_pb.CHAT_CROSS_PVP)
                        -- hasNewChatComing = true
                        -- hasNewWorldChatComing = true
                        isReceiveCspvpMsg = true
                    end
                end
            end
            -- 接收完消息后，再去刷新界面
            -- VoiceChatManager.refreshChatPage()	
            local worldChatTmpSize = #VoiceChatManager.worldChatMessageTmpList
            local guildChatTmpSize = #VoiceChatManager.guildChatMessageTmpList
            local crossChatTmpSize = #VoiceChatManager.crossChatMessageTmpList
            local worldChatSize = #VoiceChatManager.worldChatMessageList
            local guildChatSize = #VoiceChatManager.guildChatMessageList
            local crossChatSize = #VoiceChatManager.crossChatMessageList
            local function checkIsNewMessage(tmpChatSize, chatSize, tmpList, chatList)
                if tmpChatSize > 0 then
                    local lastTmpChatInfo = tmpList[#tmpList]
                    local lastChatInfo = chatList[#chatList]
                    if lastTmpChatInfo and lastChatInfo then
                        local tmpmsgTime = lastTmpChatInfo.msgTime
                        local msgTime = lastChatInfo.msgTime
                        local tmpmsg = lastTmpChatInfo.chatMsg
                        local msg = lastChatInfo.chatMsg
                        if lastTmpChatInfo.msgTime ~= lastChatInfo.msgTime or lastTmpChatInfo.chatMsg ~= lastChatInfo.chatMsg then
                            return true
                        else
                            return false
                        end
                    else
                        return true
                    end
                else
                    local chatWorldEndTime = CCUserDefault:sharedUserDefault():getStringForKey("SaveChatWorldEndTime")
                    -- 最后聊天的时间戳
                    local chatGuildEndTime = CCUserDefault:sharedUserDefault():getStringForKey("SaveChatGuildEndTime")
                    -- 最后公会聊天的时间戳
                    local chatPersonalEndTime = CCUserDefault:sharedUserDefault():getStringForKey("SaveChatPersonalEndTime")
                    -- 最后个人聊天的时间戳
                    local chatCrossEndTime = CCUserDefault:sharedUserDefault():getStringForKey("SaveChatCrossEndTime")
                    -- 最后跨服聊天的时间戳
                    local lastChatInfo = chatList[#chatList]
                    if chatSize > 0 and lastChatInfo then
                        if chatWorldEndTime and tonumber(chatWorldEndTime) == lastChatInfo.msgTime then
                            return false
                        elseif chatGuildEndTime and tonumber(chatGuildEndTime) == lastChatInfo.msgTime then
                            return false
                        elseif chatPersonalEndTime and tonumber(chatPersonalEndTime) == lastChatInfo.msgTime then
                            return false
                        elseif chatCrossEndTime and tonumber(chatCrossEndTime) == lastChatInfo.msgTime then
                            return false
                        else
                            return true
                        end
                    else
                        return false
                    end
                end
            end
            if isReceiveWorldMsg then
                if checkIsNewMessage(worldChatTmpSize, worldChatSize, VoiceChatManager.worldChatMessageTmpList, VoiceChatManager.worldChatMessageList) then
                    hasNewChatComing = true
                    hasNewWorldChatComing = true
                    local newMsgSize = worldChatSize - worldChatTmpSize
                    ChatManager.refreshMainNewChatPointTips()
                    PageManager.refreshPage("ChatPage", "worldChat" .. "." .. tostring(newMsgSize))
                    NoticePointState.isChange = true
                elseif chatSize == 60 then
                    PageManager.refreshPage("ChatPage", "worldChat" .. "." .. tostring(-1))
                end
                VoiceChatManager.worldChatMessageTmpList = { }
                VoiceChatManager.worldChatMessageTmpList = common:deepCopy(VoiceChatManager.worldChatMessageList)
            end
            if isReceiveGuildMsg then
                if checkIsNewMessage(guildChatTmpSize, guildChatSize, VoiceChatManager.guildChatMessageTmpList, VoiceChatManager.guildChatMessageList) then
                    hasNewChatComing = true
                    hasNewMemberChatComing = true
                    local newMsgSize = guildChatSize - guildChatTmpSize
                    ChatManager.refreshMainNewChatPointTips()
                    PageManager.refreshPage("ChatPage", "guildChat" .. "." .. tostring(newMsgSize))
                    PageManager.refreshPage("GuildPage", "refreshPoint")
                    -- 刷新工会红点
                    NoticePointState.isChange = true
                elseif chatSize == 60 then
                    PageManager.refreshPage("ChatPage", "guildChat" .. "." .. tostring(-1))
                end
                VoiceChatManager.guildChatMessageTmpList = { }
                VoiceChatManager.guildChatMessageTmpList = common:deepCopy(VoiceChatManager.guildChatMessageList)
            end
            if isReceiveCspvpMsg then
                if checkIsNewMessage(crossChatTmpSize, crossChatSize, VoiceChatManager.crossChatMessageTmpList, VoiceChatManager.crossChatMessageList) then
                    hasNewChatComing = true
                    hasNewCrossChatComing = true
                    local newMsgSize = crossChatSize - crossChatTmpSize
                    PageManager.refreshPage("ChatPage", "crossChat" .. "." .. tostring(newMsgSize))
                    NoticePointState.isChange = true
                elseif chatSize == 60 then
                    PageManager.refreshPage("ChatPage", "crossChat" .. "." .. tostring(-1))
                end
                VoiceChatManager.crossChatMessageTmpList = { }
                VoiceChatManager.crossChatMessageTmpList = common:deepCopy(VoiceChatManager.crossChatMessageList)
            end
            -- PageManager.refreshPage("BattlePage")

            if #playerIds > 0 then
                OSPVPManager.reqLocalPlayerInfo(playerIds)
            end
        else
            CCLuaLog("@onReceiveChatMsg -- error in data");
        end
    end
end
PackageLogicForLua.HPPushChatHandler = PacketScriptHandler:new(HP_pb.PUSH_CHAT_S, PackageLogicForLua.onReceiveChatMsg);

----服务器登录成功 通知 
function PackageLogicForLua.onReceiveGameState(eventName, handler)
    if eventName == "luaReceivePacket" then

        -- 请求聊天信息
        common:sendEmptyPacket(HP_pb.SEND_LOGINCHAT_C, false)

        --        local msg = Hp_pb.HPPlayerKickout;
        --        local msgbuff = handler:getRecPacketBuffer();
        --        msg:ParseFromString(msgbuff)
        --        CCLuaLog("@chatrequire -- ");
        --        if msg ~= nil then

        --        else
        --            CCLuaLog("@chatrequire -- error in data");
        --        end
    end
end
PackageLogicForLua.HPPlayerKickOutHandler = PacketScriptHandler:new(HP_pb.GAMEING_STATE_S, PackageLogicForLua.onReceiveGameState);


function PackageLogicForLua.onReceiveSecretMsg(eventName, handler)
    if eventName == "luaReceivePacket" then
        require("SecretMessage.SecretMessageManager")
        local msg = SecretMsg_pb.syncSecretMsg()
        local msgbuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        SecretMessageManager_setServerData(msg)
    end
end
PackageLogicForLua.secretMsgHandler = PacketScriptHandler:new(HP_pb.SECRET_MESSAGE_SYNC_S, PackageLogicForLua.onReceiveSecretMsg);

function PackageLogicForLua.onReceiveGoods(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Shop_pb.GoodsNotice()
        local msgbuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        local id=msg.goodsId
        local BuyData=require("BuyDataSend")
        BuyData:BuyItem(id)
    end
end
PackageLogicForLua.secretMsgHandler = PacketScriptHandler:new(HP_pb.GOODS_VERIFY_S, PackageLogicForLua.onReceiveGoods);
-----------------player award handler-------------------
function PackageLogicForLua.onReceivePlayerAward(msgbuff)
    local msg = Reward_pb.HPPlayerReward();
    msg:ParseFromString(msgbuff)
    CCLuaLog("@onReceivePlayerAward -- ");
    if msg ~= nil then

        if msg:HasField("rewards") then
            UserInfo.syncPlayerInfo();
            local rewards = msg.rewards

            if rewards:HasField("contribution") then
                local GuildData = require("Guild.GuildData")
                if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.myInfo
                    and GuildData.MyAllianceInfo.myInfo.contribution then
                    GuildData.MyAllianceInfo.myInfo.contribution = rewards.contribution
                end
            end

            if msg.rewards:HasField("exp") then
                UserInfo.syncRoleInfo()
                MainFrame_RefreshExpBar()
            end
            if msg.rewards:HasField("gold") then
                UserInfo.playerInfo.gold = msg.rewards["gold"]
                PageManager.refreshPage("MainScenePage")
            end
            --[[??????Ho???
			if msg.rewards:HasField("gold")
				or msg.rewards:HasField("coin")
				or msg.rewards:HasField("level")
				or msg.rewards:HasField("exp")
				or msg.rewards:HasField("vipLevel")
				then				
				PageManager.refreshPage("MarketPage","TopMsgUpdate");
			end
			--]]
        end

        local flag = msg.flag

        if flag == 1 then
            local wordList = { }
            local colorList = { }
            local rewards = msg.rewards.showItems
            for i = 1, #rewards do
                local oneReward = rewards[i]
                if oneReward.itemCount > 0 then
                    local ResManager = require "ResManagerForLua"
                    local resInfo = ResManager:getResInfoByTypeAndId(oneReward.itemType, oneReward.itemId, oneReward.itemCount);
                    local getReward = Language:getInstance():getString("@GetRewardMSG");
                    local godlyEquip = Language:getInstance():getString("@GodlyEquip");
                    -- GodlyEquip
                    local rewardName = resInfo.name;
                    if resInfo.mainType == Const_pb.EQUIP then
                        -- add
                        if GamePrecedure:getInstance():getI18nSrcPath() == "Portuguese" then
                            rewardName = string.format("%s %s%d", rewardName, common:getR2LVL(), EquipManager:getLevelById(oneReward.itemId))
                        else
                            rewardName = string.format("%d %s", EquipManager:getLevelById(oneReward.itemId), rewardName);
                            rewardName = common:getR2LVL() .. rewardName
                        end
                    end
                    local rewardStr = rewardName .. " ×" .. oneReward.itemCount .. " ";
                    local itemColor = ""
                    if resInfo.quality == 1 then
                        itemColor = GameConfig.ColorMap.COLOR_GREEN
                        if resInfo.itemId == 81040 then
                            itemColor = GameConfig.ColorMap.COLOR_WHITE
                        end

                    elseif resInfo.quality == 2 then
                        itemColor = GameConfig.ColorMap.COLOR_GREEN
                    elseif resInfo.quality == 3 then
                        itemColor = GameConfig.ColorMap.COLOR_BLUE
                    elseif resInfo.quality == 4 then
                        itemColor = GameConfig.ColorMap.COLOR_PURPLE
                    elseif resInfo.quality == 5 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 6 then
                        itemColor = GameConfig.ColorMap.COLOR_RED
                    elseif resInfo.quality == 7 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 8 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 9 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 10 then
                        itemColor = GameConfig.ColorMap.COLOR_RED
                    elseif resInfo.quality == 11 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 12 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 13 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 14 then
                        itemColor = GameConfig.ColorMap.COLOR_RED
                    elseif resInfo.quality == 15 then
                        itemColor = GameConfig.ColorMap.COLOR_BLUE
                    elseif resInfo.quality == 16 then
                        itemColor = GameConfig.ColorMap.COLOR_PURPLE
                    elseif resInfo.quality == 17 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 18 then
                        itemColor = GameConfig.ColorMap.COLOR_RED
                    elseif resInfo.quality == 19 then
                        itemColor = GameConfig.ColorMap.COLOR_BLUE
                    elseif resInfo.quality == 20 then
                        itemColor = GameConfig.ColorMap.COLOR_PURPLE
                    elseif resInfo.quality == 21 then
                        itemColor = GameConfig.ColorMap.COLOR_ORANGE
                    elseif resInfo.quality == 22 then
                        itemColor = GameConfig.ColorMap.COLOR_RED
                    end
                    -- local newEquipStr = common:fill(equipStr,rewardStr)
                    -- table.insert(wordList,rewardStr)
                    local finalStr = getReward
                    if oneReward:HasField("itemStatus") then
                        if oneReward.itemStatus == 1 then
                            finalStr = finalStr .. godlyEquip
                        end
                    end
                    finalStr = finalStr .. rewardStr
                    table.insert(wordList, finalStr)
                    table.insert(colorList, itemColor)
                end
            end
            return insertMessageFlow(wordList, colorList)
        elseif flag == 2 then
            -- 弹出通用奖励领取窗口
            local rewards = msg.rewards.showItems
            local showReward = { }
            for i = 1, #rewards do
                local oneReward = rewards[i]
                if oneReward.itemCount > 0 then
                    local resInfo = { }
                    resInfo["type"] = oneReward.itemType
                    resInfo["itemId"] = oneReward.itemId
                    resInfo["count"] = oneReward.itemCount
                    --- 这个代表神器
                    if oneReward:HasField("itemStatus") and oneReward["itemStatus"] == 1 then
                        resInfo["isGodly"] = true
                    end
                    showReward[#showReward + 1] = resInfo
                end
            end
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            CommonRewardPage:setData(showReward, common:getLanguageString("@ItemObtainded"), nil)
            --CommonRewardPageBase_setPageParm(showReward, true, msg.rewardType)
            PageManager.pushPage("CommPop.CommItemReceivePage")
        end
        -- 高速扫荡卷实时监测
        local isCancelBattlePoint, leftTime = common:getHighSpeedPointAndChangePoint()
        --NodeHelper:mainFrameSetPointVisible( { mBattlePagePoint = leftTime or isCancelBattlePoint })
    else
        CCLuaLog("@onReceivePlayerAward -- error in data");
    end
end

function PackageLogicForLua.PopUpReward(msgbuff)
    local msg = Reward_pb.HPPlayerReward();
    msg:ParseFromString(msgbuff)
    if msg ~= nil then
        if msg:HasField("rewards") then
            UserInfo.syncPlayerInfo();
            local rewards = msg.rewards
         
            if msg.rewards:HasField("exp") then
                UserInfo.syncRoleInfo()
                MainFrame_RefreshExpBar()
            end
            if msg.rewards:HasField("gold") then
                UserInfo.playerInfo.gold = msg.rewards["gold"]
                PageManager.refreshPage("MainScenePage")
            end
        end
        -- 弹出通用奖励领取窗口
        local rewards = msg.rewards.showItems
        local showReward = { }
        for i = 1, #rewards do
            local oneReward = rewards[i]
            if oneReward.itemCount > 0 then
                local resInfo = { }
                resInfo["type"] = oneReward.itemType
                resInfo["itemId"] = oneReward.itemId
                resInfo["count"] = oneReward.itemCount
                --- 这个代表神器
                if oneReward:HasField("itemStatus") and oneReward["itemStatus"] == 1 then
                    resInfo["isGodly"] = true
                end
                showReward[#showReward + 1] = resInfo
            end
        end
        local CommonRewardPage = require("CommPop.CommItemReceivePage")
        CommonRewardPage:setData(showReward, common:getLanguageString("@ItemObtainded"), nil)
        --CommonRewardPageBase_setPageParm(showReward, true, msg.rewardType)
        PageManager.pushPage("CommPop.CommItemReceivePage")
    else
        CCLuaLog("@onReceivePlayerAward -- error in data");
    end
end

--[[
------------------------------ market/coins info -------------------------------------
function PackageLogicForLua.onReceiveMarketDropsInfo(eventName,handler)
	if eventName == "luaReceivePacket" then
		local msg = Shop_pb.OPShopInfoRet();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)
		CCLuaLog("@onReceiveMarketDropsInfo -- ");
		if msg~=nil then
			marketAdventureInfo.dropsItems = msg.shopItems;
			marketAdventureInfo.refreshCount = msg.refreshCount;
		end
	end
	--handler:removePacket(HP_pb.SHOP_S);
end

function PackageLogicForLua.onReceiveMarketCoinsInfo(eventName,handler)
	if eventName == "luaReceivePacket" then
		local msg = Shop_pb.OPBuyCoinRet();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)
		CCLuaLog("@onReceiveMarketCoinsInfo -- ");
		if msg~=nil then
			marketAdventureInfo.coinReward = msg.coin;
			marketAdventureInfo.coinCost = msg.coinPrice;
			marketAdventureInfo.coinCount = msg.canBuyNums;
		end

	end

	--handler:removePacket(HP_pb.SHOP_COIN_S);
end

PackageLogicForLua.HPMarketDropsHandler = PacketScriptHandler:new(HP_pb.SHOP_S, PackageLogicForLua.onReceiveMarketDropsInfo);
PackageLogicForLua.HPMarketCoinHandler = PacketScriptHandler:new(HP_pb.SHOP_COIN_S, PackageLogicForLua.onReceiveMarketCoinsInfo);
------------------------------ market/coins info -------------------------------------
]]--


function PackageLogicForLua.onReceiveNoticePush(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Notice_pb.HPNotice();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        CCLuaLog("@onReceiveNoticePush -- ");
        local hasSendMailMsg = false;
        if msg ~= nil then
            local itemsSize = table.maxn(msg.notices);

            for i = 1, itemsSize, 1 do
                local item = msg.notices[i];

                noticeCache[i] = { };
                noticeCache[i].noticeType = item.noticeType;
                noticeCache[i].count = item.count;

                local size = table.maxn(item.params);

                for j = 1, size do
                    noticeCache[i].params = { };
                    noticeCache[i].params[j] = item.params[j];
                end

                local message = MsgMainFrameGetNewInfo:new()
                message.type = item.noticeType;
                MessageManager:getInstance():sendMessageForScript(message)

                --[[
				if message.type == Const_pb.NEW_MAIL  and (not hasSendMailMsg) then
					local mailMsg = Mail_pb.OPMailInfo();

					local index = table.maxn(MailInfo.mails);
					if index > 0 then
						local mail = MailInfo.mails[index];
						if mail ~= nil then
							mailMsg.version = mail.id;
						else
							mailMsg.version = 0;
						end
					else
						mailMsg.version = 0;
					end

					local pb_data = mailMsg:SerializeToString();
					PacketManager:getInstance():sendPakcet(HP_pb.MAIL_INFO_C, pb_data, #pb_data, true);
					hasSendMailMsg = true;
				end
				--]]
            end


        end

    end


end
PackageLogicForLua.HPNoticePushHandler = PacketScriptHandler:new(HP_pb.NOTICE_PUSH, PackageLogicForLua.onReceiveNoticePush);
------------------------------new red point-------------------------------------


------------------------------new mail point-------------------------------------
function PackageLogicForLua.onReceiveMailInfo(eventName, handler)
    local MailDataHelper = require("Mail.MailDataHelper")
    MailDataHelper:onReceiveMailPacket(eventName, handler)
end
PackageLogicForLua.HPMailInfoHandler = PacketScriptHandler:new(HP_pb.MAIL_INFO_S, PackageLogicForLua.onReceiveMailInfo);


------------------------------new mail point-------------------------------------

function PackageLogicForLua.onReceiveNewLeaveMessage(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Arena_pb.HPArenaDefenderListSyncS()
        if BlackBoard:getInstance():hasVarible(GameConfig.Default.NewMsgKey) then
            BlackBoard:getInstance():setVarible(GameConfig.Default.NewMsgKey, true)
        else
            BlackBoard:getInstance():addVarible(GameConfig.Default.NewMsgKey, true)
        end
    end
end
PackageLogicForLua.HPNewMsgHandler = PacketScriptHandler:new(HP_pb.NEW_MSG_SYNC_S, PackageLogicForLua.onReceiveNewLeaveMessage)


-- 处理error code 的飘字情况，现在error code 其实充当了Status code的角艿
function PackageLogicForLua.onReceiveErrorCode(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local msg = SysProtocol_pb.HPErrorCode()
        msg:ParseFromString(msgBuff)
        print("msg.errCode = ", msg.errCode)
        if msg:HasField("errFlag") then
            local flag = msg.errFlag
            -- if flag == 2 飘字

            if flag == 2 then
                local errorCodeCfg = ConfigManager.getErrorCodeCfg()
                local content = errorCodeCfg[msg.errCode].content

                local wordList = { }
                local colorList = { }
                table.insert(wordList, content)
                itemColor = GameConfig.ColorMap.COLOR_GREEN
                table.insert(colorList, itemColor)
                return insertMessageFlow(wordList, colorList)
            end
        end
    end
end
PackageLogicForLua.HPErrorCodeHandler = PacketScriptHandler:new(HP_pb.ERROR_CODE, PackageLogicForLua.onReceiveErrorCode)


function PackageLogicForLua.onReceiveGiftPackage(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local msg = mission.HPMissionListS()
        msg:ParseFromString(msgBuff)
        GiftList = msg.infos
        GiftListReceived = true
        table.sort(GiftList, sortGiftList)

        -- notice GiftPage to refreshPage
        local message = MsgMainFrameRefreshPage:new()
        message.pageName = 'GiftPage'
        MessageManager:getInstance():sendMessageForScript(message)

        -- 没有可领取的奖励了就清空红点
        if not hasUngetReward() then
            local newInfoMsg = MsgMainFrameGetNewInfo:new()
            newInfoMsg.type = GameConfig.NewPointType.TYPE_GIFT_NEW_CLOSE
            MessageManager:getInstance():sendMessageForScript(newInfoMsg)
        else
            local newInfoMsg = MsgMainFrameGetNewInfo:new()
            newInfoMsg.type = Const_pb.GIFT_NEW_MSG
            MessageManager:getInstance():sendMessageForScript(newInfoMsg)
        end
    end
end
PackageLogicForLua.HPMissionListHandler = PacketScriptHandler:new(HP_pb.MISSION_LIST_S, PackageLogicForLua.onReceiveGiftPackage)



function PackageLogicForLua.onReceiveAlliancePersonalInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local msg = alliance.HPAllianceEnterS()
        msg:ParseFromString(msgBuff)
        UserInfo.hasAlliance = msg.hasAlliance
        -- 玩家是否拥有工会
        local GuildData = require('Guild.GuildData')
        GuildData.GuildPage.onReceiveAllianceEnterInfo(nil, msg)
        local visible = GuildData.GuildPage.CheckShowNoticePoint()
        if visible ~= NoticePointState.GUILD_SIGNIN then
            NoticePointState.GUILD_SIGNIN = visible
            NoticePointState.isChange = true
        end
        GuildData.GuildPage.IsRequestMsg = true
        local GVGManager = require("GVGManager")
        if GVGManager.needCheckGuildPoint then
            if msg.hasAlliance then
                -- GVGManager.reqRewardInfo()
                GVGManager.reqGVGConfig()
            else
                GVGManager.needCheckGuildPoint = false
            end
        end
    end
end
PackageLogicForLua.HPAllianceEnterHandler = PacketScriptHandler:new(HP_pb.ALLIANCE_ENTER_S, PackageLogicForLua.onReceiveAlliancePersonalInfo)

function PackageLogicForLua.onReceiveAllianceInfo(eventName, handler)
    local GuildData = require('Guild.GuildData')
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local msg = alliance.HPAllianceInfoS()
        msg:ParseFromString(msgBuff)
        GuildData.allianceInfo.commonInfo = msg
        UserInfo.guildName = msg.name
    end
end
PackageLogicForLua.HPAllianceCreateHandler = PacketScriptHandler:new(HP_pb.ALLIANCE_CREATE_S, PackageLogicForLua.onReceiveAllianceInfo)


function PackageLogicForLua.onReceiveWingLeadGet(eventName, handler)
    if eventName == "luaReceivePacket" then
        PageManager.refreshPage("EquipmentWingPage");
    end
end
PackageLogicForLua.HPWingLeadGetHandler = PacketScriptHandler:new(HP_pb.WING_GET_LEAD_S, PackageLogicForLua.onReceiveWingLeadGet)

function sortGiftList(item1, item2)
    -- é©´è„¡è„ªè„­è„•çŸ›è„ éš†ç¢Œè„›è·¯è„œè„­è„·è„³å¯è„¡è„§è„™å¿™
    if item1.tag and(not item2.tag) then
        return true
    elseif (not item1.tag) and item2.tag then
        return false
    end

    -- é©´è„¡è„•çŸ›è„ éš†è„³éº“è„¤å¢è„§è„¿è„¥å¢ç¢Œè„›æŽ³éº“è„Œè„¿è„¨è„¥è„œè„œè„¨è²Œ
    local giftCfg = ConfigManager.getGiftConfig()
    local id1 = item1.id
    local id2 = item2.id
    local type1 = giftCfg[id1].type
    local type2 = giftCfg[id2].type
    return type1 < type2
end

function hasUngetReward()
    for i = 1, #GiftList do
        if GiftList[i] and GiftList[i].tag then
            return true
        end
    end
    return false
end

function PackageLogicForLua.onEquipSyncFinish(eventName, handler)
    if eventName == "luaReceivePacket" then
        UserInfo.syncPlayerInfo()
        UserEquipManager:check()
        require("Util.RedPointManager")
        --RedPointManager_refreshRedPointByCondition(RedPointManager.RefreshCondition.EQUIP)
        local ALFManager = require("Util.AsyncLoadFileManager")
        for page = RedPointManager.PAGE_IDS.WEAPON_ALL_BTN, RedPointManager.PAGE_IDS.FOOT_ONE_ICON do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[page].groupNum
            for i = 1, groupNum do
                local fn = function()
                    RedPointManager_refreshPageShowPoint(page, i)
                    RedPointManager_setPageSyncDone(page, i)
                end
                ALFManager:loadRedPointTask(fn, page * 100 + i)
            end
        end
        local page = RedPointManager.PAGE_IDS.PACKAGE_AW_ICON
        local fn = function()
            RedPointManager_refreshPageShowPoint(page, 1)
            RedPointManager_setPageSyncDone(page, 1)
        end
        ALFManager:loadRedPointTask(fn, page * 100)
    end
end
PackageLogicForLua.HPEquipSyncFinish = PacketScriptHandler:new(HP_pb.EQUIP_SYNC_FINISH_S, PackageLogicForLua.onEquipSyncFinish);

---------------------å½•è„¿è„¤åª’è„³æŽ³å¤èµ‚è„¥å¢è™é™†---------------
function PackageLogicForLua.onRecieveSyncEquip(eventName, handler)
    if eventName == "luaReceivePacket" then
        require("Util.RedPointManager")
        --RedPointManager_refreshRedPointByCondition(RedPointManager.RefreshCondition.EQUIP)
        EquipOprHelper:syncEquipInfoFromMsg(handler:getRecPacketBuffer())
        UserInfo.syncPlayerInfo()
        --UserEquipManager:check()
        UserEquipManager:checkAllEquipNotice()
        local ALFManager = require("Util.AsyncLoadFileManager")
        for page = RedPointManager.PAGE_IDS.WEAPON_ALL_BTN, RedPointManager.PAGE_IDS.FOOT_ONE_ICON do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[page].groupNum
            for i = 1, groupNum do
                local fn = function()
                    RedPointManager_refreshPageShowPoint(page, i)
                    RedPointManager_setPageSyncDone(page, i)
                end
                ALFManager:loadRedPointTask(fn, page * 100 + i)
            end
        end
        local pageIds = {
            RedPointManager.PAGE_IDS.CHAR_EQUIP1_SLOT, RedPointManager.PAGE_IDS.CHAR_EQUIP2_SLOT, 
            RedPointManager.PAGE_IDS.CHAR_EQUIP3_SLOT, RedPointManager.PAGE_IDS.CHAR_EQUIP4_SLOT,
            RedPointManager.PAGE_IDS.CHAR_AW_SLOT, 
        }
        for k, pageId in pairs(pageIds) do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            for i = 1, groupNum do    -- 24隻忍娘
                local fn = function()
                    RedPointManager_refreshPageShowPoint(pageId, i)
                    RedPointManager_setPageSyncDone(pageId, i)
                end
                ALFManager:loadRedPointTask(fn, pageId * 100 + i)
            end
        end
        local page = RedPointManager.PAGE_IDS.PACKAGE_AW_ICON
        local fn = function()
            RedPointManager_refreshPageShowPoint(page, 1)
            RedPointManager_setPageSyncDone(page, 1)
        end
        ALFManager:loadRedPointTask(fn, page * 100)
        return 
    end
end
PackageLogicForLua.HPSyncEquipInfoHandler = PacketScriptHandler:new(HP_pb.EQUIP_INFO_SYNC_S, PackageLogicForLua.onRecieveSyncEquip);

------------------------------------------------------------
function PackageLogicForLua.onRecieveSyncElement(eventName, handler)
    if eventName == "luaReceivePacket" then
        local ElementManager = require("Element.ElementManager")
        return ElementManager:syncEleInfoFromMsg(handler:getRecPacketBuffer());
    end
end
PackageLogicForLua.HPSyncElementInfoHandler = PacketScriptHandler:new(HP_pb.ELEMENT_INFO_SYNC_S, PackageLogicForLua.onRecieveSyncElement);
--- 账号绑定
function PackageLogicForLua.onReceiveAccountBound(eventName, handler)
    if eventName == "luaReceivePacket" then
        --CCLuaLog("luaReceivePacket = " .. luaReceivePacket)
        --local AccountBound_pb = require("AccountBound_pb");
        --require("AccountBoundPage")
        --local msgBuff = handler:getRecPacketBuffer();
        --local msg = AccountBound_pb.HPAccountBoundRet()
        --msg:ParseFromString(msgBuff)
        --AccountBoundStatus = msg.accountStatus
        --AccountBoundReward = msg.accountReward
        --if msg.accountStatus == 1 or msg.accountStatus == 2 then
        --    NoticePointState.PULLDOWN_POINT = true
        --    NoticePointState.ACCOUNTBOUND_POINT = true;
        --elseif msg.accountStatus == 3 then
        --    NoticePointState.ACCOUNTBOUND_POINT = false;
        --end
    end
end
PackageLogicForLua.HPAccountBound = PacketScriptHandler:new(HP_pb.ACCOUNT_BOUND_INFO_S, PackageLogicForLua.onReceiveAccountBound)
-------------------录脿脤媒脳掳卤赂脥卢虏陆---------------
function PackageLogicForLua.onRecieveSyncItem(eventName, handler)
	if eventName == "luaReceivePacket" then
		--local msg = Item_pb.HPItemInfoSync();
		--local msgBuff = handler:getRecPacketBuffer();
		--msg:ParseFromString(msgBuff);
		--for _, itemInfo in ipairs(msg.itemInfos) do
		--	ActivityInfo:checkAfterItemSync(itemInfo.itemId, itemInfo.count);
		--end
        require("Util.RedPointManager")
        local pages = {
            RedPointManager.PAGE_IDS.GRAIL_HOLY_BTN, RedPointManager.PAGE_IDS.GRAIL_ELEMENT_BTN, RedPointManager.PAGE_IDS.GRAIL_CLASS_BTN, 
            RedPointManager.PAGE_IDS.CHAR_RARITYUP_BTN, RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN
        }
        local ALFManager = require("Util.AsyncLoadFileManager")
        for page = 1, #pages do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pages[page]].groupNum
            for i = 1, groupNum do
                local fn = function()
                    RedPointManager_refreshPageShowPoint(pages[page], i)
                end
                ALFManager:loadRedPointTask(fn, page * 100 + i)
            end
        end
        local page = RedPointManager.PAGE_IDS.PACKAGE_AW_ICON
        local fn = function()
            RedPointManager_refreshPageShowPoint(page, 1)
            RedPointManager_setPageSyncDone(page, 1)
        end
        ALFManager:loadRedPointTask(fn, page * 100)
	end
end
PackageLogicForLua.HPSyncItemInfoHandler = PacketScriptHandler:new(HP_pb.ITEM_INFO_SYNC_S, PackageLogicForLua.onRecieveSyncItem);
---------------------å½•è„¿è„¤åª’è„§æ²¡æ½žè„›æ‹¢é¢…æ‹¢é¢…---------------
function PackageLogicForLua.onRecievePlayerConsume(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Consume_pb.HPConsumeInfo();
        local msgBuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgBuff);

        if msg:HasField("attrInfo") then
            if msg.attrInfo:HasField("gold")
                or msg.attrInfo:HasField("coin")
                or msg.attrInfo:HasField("level")
                or msg.attrInfo:HasField("exp")
                or msg.attrInfo:HasField("vipLevel")
            then
                PageManager.refreshPage("MainScenePage");
                -- PageManager.refreshPage("MarketPage","TopMsgUpdate");
            end
            if msg.attrInfo:HasField("honorValue") then
                UserInfo.playerInfo.honorValue = msg.attrInfo.honorValue
            end
            if msg.attrInfo:HasField("reputationValue") then
                UserInfo.playerInfo.reputationValue = msg.attrInfo.reputationValue
            end
            if msg.attrInfo:HasField("friendship") then
                UserInfo.stateInfo.friendship = msg.attrInfo.friendship
            end
            if msg.attrInfo:HasField("crossCoin") then
                local OSPVPManager = require("OSPVPManager")
                OSPVPManager:setCsMoney(msg.attrInfo.crossCoin)
            end
        end

        local hasConsumeEquip = false;
        local hasConsumeItem = false;
        for _, consumeItem in ipairs(msg.consumeItem) do
            if consumeItem.type == Const_pb.CHANGE_EQUIP then
                EquipOprHelper:deleteEquip(consumeItem.id);
                hasConsumeEquip = true;
            elseif consumeItem.type == Const_pb.CHANGE_TOOLS then
                hasConsumeItem = true;
                -- ActivityInfo:checkAfterItemSync(consumeItem.itemId);
            elseif consumeItem.type == Const_pb.CHANGE_ELEMENT then
                hasConsumeItem = true;
                local ElementManager = require("Element.ElementManager")
                ElementManager:deleteElement(consumeItem.id);
            end
        end
        if hasConsumeEquip or hasConsumeItem then
            PageManager.refreshPage("PackagePage");
            PageManager.refreshPage("EquipLeadPage")
        end
        require("Util.RedPointManager")
        local pages = {
            RedPointManager.PAGE_IDS.WEAPON_ALL_BTN, RedPointManager.PAGE_IDS.WEAPON_ONE_ICON, RedPointManager.PAGE_IDS.CHEST_ALL_BTN, 
            RedPointManager.PAGE_IDS.CHEST_ONE_ICON, RedPointManager.PAGE_IDS.RING_ALL_BTN, RedPointManager.PAGE_IDS.RING_ONE_ICON,
            RedPointManager.PAGE_IDS.FOOT_ALL_BTN, RedPointManager.PAGE_IDS.FOOT_ONE_ICON, RedPointManager.PAGE_IDS.GRAIL_HOLY_BTN, 
            RedPointManager.PAGE_IDS.GRAIL_ELEMENT_BTN, RedPointManager.PAGE_IDS.GRAIL_CLASS_BTN, RedPointManager.PAGE_IDS.CHAR_RARITYUP_BTN, 
            RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN
        }
        local ALFManager = require("Util.AsyncLoadFileManager")
        for page = 1, #pages do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pages[page]].groupNum
            for i = 1, groupNum do
                local fn = function()
                    RedPointManager_refreshPageShowPoint(pages[page], i)
                end
                ALFManager:loadRedPointTask(fn, page * 100 + i)
            end
        end
        local page = RedPointManager.PAGE_IDS.PACKAGE_AW_ICON
        local fn = function()
            RedPointManager_refreshPageShowPoint(page, 1)
            RedPointManager_setPageSyncDone(page, 1)
        end
        ALFManager:loadRedPointTask(fn, page * 100)
    end
end
PackageLogicForLua.HPPlayerConsumeHandler = PacketScriptHandler:new(HP_pb.PLAYER_CONSUME_S, PackageLogicForLua.onRecievePlayerConsume);


function PackageLogicForLua.onRecieveSeeMercenaryInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local ViewMercenaryInfo = require("Mercenary.ViewMercenaryInfo")
        ViewMercenaryInfo:setInfo(msgBuff);
        PageManager.pushPage("ViewMercenaryInfoPage");
    end
end
PackageLogicForLua.HPSeeMercenaryInfo = PacketScriptHandler:new(HP_pb.SEE_MERCENARY_INFO_S, PackageLogicForLua.onRecieveSeeMercenaryInfo);


function PackageLogicForLua.onRecieveSeeOtherPlayerInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local Snapshot_pb = require("Snapshot_pb");
        local msg = Snapshot_pb.HPSeeOtherPlayerInfoRet();
        msg:ParseFromString(msgBuff);
        ViewPlayerInfo:setInfo(msg);

        local FriendManager = require("FriendManager")
        local viewFriendId = FriendManager.getViewPlayerId()
        if msg.playerInfo.playerId ~= viewFriendId then
            PageManager.pushPage("ViewPlayMenuPage")
        else
            FriendManager.cleanViewPlayer()
            FetterManager.clear()
            FetterManager.reqFetterInfo(viewFriendId)
            PageManager.pushPage("ViewPlayerEquipmentPage");
        end
        -- PageManager.pushPage("ViewPlayerInfoPage");
    end
end
PackageLogicForLua.HPSeeOtherPlayerInfo = PacketScriptHandler:new(HP_pb.SEE_OTHER_PLAYER_INFO_S, PackageLogicForLua.onRecieveSeeOtherPlayerInfo);

function PackageLogicForLua.onRecieveSyncStarSoul(eventName, handler)
    if eventName == "luaReceivePacket" then
        local StarSoul_pb = require("StarSoul_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id

        --local LeaderDataMgr = require("Leader.LeaderDataMgr")
        --local subPageCfg = LeaderDataMgr:getSubPageCfg("HolyGrail")
        --subPageCfg.saveData = subPageCfg.saveData or { }
        --subPageCfg.saveData[1] = id

        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.GRAIL_HOLY_BTN
        RedPointManager_refreshPageShowPoint(pageId, 1, id)
        RedPointManager_setPageSyncDone(pageId, 1)
    end
end
PackageLogicForLua.HPSyncStarSoul = PacketScriptHandler:new(HP_pb.SYNC_STAR_SOUL_S, PackageLogicForLua.onRecieveSyncStarSoul)

function PackageLogicForLua.onRecieveSyncLeaderStarSoul(eventName, handler)
    if eventName == "luaReceivePacket" then
        --local pageName = "LeaderSubPage_SoulStar"
        --local StarSoul_pb = require("StarSoul_pb")
        --local msgBuff = handler:getRecPacketBuffer()
        --local msg = StarSoul_pb.SyncStarSoulRet()
        --msg:ParseFromString(msgBuff)
        --local id = msg.id
        --
        --require("Util.RedPointManager")
        --require("Leader.LeaderSubPage_SoulStar")
        --local isShow, group = SoulStarPageBase_calIsShowRedPoint(id)
        --if not RedPointManager_getSyncDone(pageName, group) then
        --    RedPointManager_setShowRedPoint(pageName, group, isShow)
        --    RedPointManager_setOptionData(pageName, group, { id = id })
        --    RedPointManager_setSyncDone(pageName, group, true)
        --end
    end
end
PackageLogicForLua.HPSyncLeaderStarSoul = PacketScriptHandler:new(HP_pb.SYNC_LEADER_SOUL_S, PackageLogicForLua.onRecieveSyncLeaderStarSoul)

function PackageLogicForLua.onRecieveSyncElementStarSoul(eventName, handler)
    if eventName == "luaReceivePacket" then
        local pageName = "LeaderSubPage_Element"
        local StarSoul_pb = require("StarSoul_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id

        --require("Leader.LeaderSubPage_Element")
        --local LeaderDataMgr = require("Leader.LeaderDataMgr")
        --local subPageCfg = LeaderDataMgr:getSubPageCfg("Element")
        --subPageCfg.saveData = subPageCfg.saveData or { }
        --subPageCfg.saveData[group] = id

        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.GRAIL_ELEMENT_BTN
        RedPointManager_refreshPageShowPoint(pageId, nil, id)
        RedPointManager_setPageSyncDone(pageId, 1)
    end
end
PackageLogicForLua.HPSyncElementStarSoul = PacketScriptHandler:new(HP_pb.SYNC_ELEMENT_SOUL_S, PackageLogicForLua.onRecieveSyncElementStarSoul)

function PackageLogicForLua.onRecieveSyncClassStarSoul(eventName, handler)
    if eventName == "luaReceivePacket" then
        local pageName = "LeaderSubPage_Class"
        local StarSoul_pb = require("StarSoul_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id

        --require("Leader.LeaderSubPage_Class")
        --local LeaderDataMgr = require("Leader.LeaderDataMgr")
        --local subPageCfg = LeaderDataMgr:getSubPageCfg("Class")
        --subPageCfg.saveData = subPageCfg.saveData or { }
        --subPageCfg.saveData[group] = id

        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.GRAIL_CLASS_BTN
        RedPointManager_refreshPageShowPoint(pageId, nil, id)
        RedPointManager_setPageSyncDone(pageId, 1)
    end
end
PackageLogicForLua.HPSyncClassStarSoul = PacketScriptHandler:new(HP_pb.SYNC_CLASS_SOUL_S, PackageLogicForLua.onRecieveSyncClassStarSoul)

function PackageLogicForLua.onRecieveSyncWishingWell(eventName, handler)
    if eventName == "luaReceivePacket" then
        --local pageName = "WishingWellSubPage_Base"
        --local Activity4_pb = require("Activity4_pb")
        --local msgBuff = handler:getRecPacketBuffer()
        --local msg = Activity4_pb.WishingWellInfo()
        --msg:ParseFromString(msgBuff)
        --
        --require("Util.RedPointManager")
        --require("WishingWell.WishingWellSubPage_Base")
        --local isShow, group = WishingWellPageBase_calIsShowRedPoint(msg)
        --if not RedPointManager_getSyncDone(pageName, group) then
        --    RedPointManager_setShowRedPoint(pageName, group, isShow)
        --    RedPointManager_setOptionData(pageName, group, { })
        --    RedPointManager_setSyncDone(pageName, group, true)
        --end
    end
end
PackageLogicForLua.HPSyncWishingWell = PacketScriptHandler:new(HP_pb.ACTIVITY147_WISHING_INFO_S, PackageLogicForLua.onRecieveSyncWishingWell)

function PackageLogicForLua.onRecieveSyncSummonNormal(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity4_pb = require("Activity4_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Activity4_pb.ActivityCallInfo()
        msg:ParseFromString(msgBuff)

        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.SUMMON_NORMAL_FREE
        RedPointManager_refreshPageShowPoint(pageId, 1, msg)
        RedPointManager_setPageSyncDone(pageId, 1)
    end
end
PackageLogicForLua.HPSyncSummonNormal = PacketScriptHandler:new(HP_pb.ACTIVITY146_CHOSEN_INFO_S, PackageLogicForLua.onRecieveSyncSummonNormal)

function PackageLogicForLua.onRecieveSyncRoleInfoReward(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity4_pb = require("Activity4_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Activity4_pb.HeroDramaRes()
        msg:ParseFromString(msgBuff)
        local action = msg.action
        if action == 0 then
            require("HeroBioPage")
            HeroBioPage_setServerData(msg.gotHero)
            require("Util.RedPointManager")
            local pageId = RedPointManager.PAGE_IDS.INFO_REWARD_BTN
            local pageId2 = RedPointManager.PAGE_IDS.INFO_REWARD_BTN2
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            local ALFManager = require("Util.AsyncLoadFileManager")
            local fn = function()
                for i = 1, groupNum do    -- 24隻忍娘
                    RedPointManager_refreshPageShowPoint(pageId, i)
                    RedPointManager_setPageSyncDone(pageId, i)
                    RedPointManager_refreshPageShowPoint(pageId2, i)
                    RedPointManager_setPageSyncDone(pageId2, i)
                end
            end
            ALFManager:loadRedPointTask(fn, pageId * 100)
        end
    end
end
PackageLogicForLua.HPSyncRoleInfoReward = PacketScriptHandler:new(HP_pb.ACTIVITY152_S, PackageLogicForLua.onRecieveSyncRoleInfoReward)

function PackageLogicForLua.onRecieveSyncCollection(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPArchiveInfoRes()
        local msgbuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        require("NgHeroPageManager")
        NgHeroPageManager_setServerFetterData(msg)
        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.HERO_FETTER_BTN
        local RedPointCfg = ConfigManager.getRedPointSetting()
        local groupNum = RedPointCfg[pageId].groupNum
        local ALFManager = require("Util.AsyncLoadFileManager")
        for i = 1, groupNum do    -- 6組羈絆
            local fn = function()
                RedPointManager_refreshPageShowPoint(pageId, i)
                RedPointManager_setPageSyncDone(pageId, i)
            end
            ALFManager:loadRedPointTask(fn, pageId * 100 + i)
        end
    end
end
PackageLogicForLua.HPSyncCollection = PacketScriptHandler:new(HP_pb.FETCH_ARCHIVE_INFO_S, PackageLogicForLua.onRecieveSyncCollection)

function PackageLogicForLua.onRecieveSyncDungeon(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgbuff = handler:getRecPacketBuffer()
        require("Dungeon.DungeonSubPage_Event")
        DungeonPageBase_setDungeonData(msgbuff)
        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.DUNGEON_REWARD_BTN
        local pageId2 = RedPointManager.PAGE_IDS.DUNGEON_CHALLANGE_BTN
        local RedPointCfg = ConfigManager.getRedPointSetting()
        local groupNum = RedPointCfg[pageId].groupNum
        local ALFManager = require("Util.AsyncLoadFileManager")
        for i = 1, groupNum do    -- 5個關卡類型
            local fn = function()
                RedPointManager_refreshPageShowPoint(pageId, i)
                RedPointManager_setPageSyncDone(pageId, i)
                RedPointManager_refreshPageShowPoint(pageId2, i)
                RedPointManager_setPageSyncDone(pageId2, i)
            end
            ALFManager:loadRedPointTask(fn, pageId * 100 + i)
        end
        --if loadingOpcodes[HP_pb.MULTIELITE_LIST_INFO_S].done == false then loadingOpcodes[HP_pb.MULTIELITE_LIST_INFO_S].done = true end
        --checkAndCloseMainSceneLoadingEnd()
    end
end
PackageLogicForLua.HPSyncSyncDungeon = PacketScriptHandler:new(HP_pb.MULTIELITE_LIST_INFO_S, PackageLogicForLua.onRecieveSyncDungeon)

function PackageLogicForLua.onRecieveSyncShop(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgbuff = handler:getRecPacketBuffer()
        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.MYSTERY_FREE_BTN
        local pageId2 = RedPointManager.PAGE_IDS.MYSTERY_REFRESH_BTN
        local RedPointCfg = ConfigManager.getRedPointSetting()
        local groupNum = RedPointCfg[pageId].groupNum
        local ALFManager = require("Util.AsyncLoadFileManager")
        for i = 1, groupNum do
            local fn = function()
                RedPointManager_refreshPageShowPoint(pageId, i, msgbuff)
                RedPointManager_setPageSyncDone(pageId, i)
                RedPointManager_refreshPageShowPoint(pageId2, i, msgbuff)
                RedPointManager_setPageSyncDone(pageId2, i)
            end
            ALFManager:loadRedPointTask(fn, pageId * 100 + i)
        end
    end
end
PackageLogicForLua.HPSyncSyncShop = PacketScriptHandler:new(HP_pb.SHOP_ITEM_S, PackageLogicForLua.onRecieveSyncShop)

function PackageLogicForLua.onRecieveSyncPackage(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgbuff = handler:getRecPacketBuffer()
        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.DAILY_REWARD_BTN
        local pageId2 = RedPointManager.PAGE_IDS.WEEKLY_REWARD_BTN
        local pageId3 = RedPointManager.PAGE_IDS.MONTHLY_REWARD_BTN
        local RedPointCfg = ConfigManager.getRedPointSetting()
        local groupNum = RedPointCfg[pageId].groupNum
        local ALFManager = require("Util.AsyncLoadFileManager")
        local fn = function()
            for i = 1, groupNum do
                RedPointManager_refreshPageShowPoint(pageId, i, msgbuff)
                RedPointManager_setPageSyncDone(pageId, i)
                RedPointManager_refreshPageShowPoint(pageId2, i, msgbuff)
                RedPointManager_setPageSyncDone(pageId2, i)
                RedPointManager_refreshPageShowPoint(pageId3, i, msgbuff)
                RedPointManager_setPageSyncDone(pageId3, i)
            end
        end
        ALFManager:loadRedPointTask(fn, pageId * 100)
    end
end
PackageLogicForLua.HPSyncSyncPackage = PacketScriptHandler:new(HP_pb.DISCOUNT_GIFT_INFO_S, PackageLogicForLua.onRecieveSyncPackage)

function PackageLogicForLua.onRecieveActiveStarSoulRet(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local StarSoul_pb = require("StarSoul_pb");
        local msg = StarSoul_pb.ActiveStarSoulRet()
        msg:ParseFromString(msgBuff);

        SoulStarManager:onReceivePacketInit(msg)
    end
end
PackageLogicForLua.HPActiveStarSoulRet = PacketScriptHandler:new(HP_pb.ACTIVE_STAR_SOUL_S, PackageLogicForLua.onRecieveActiveStarSoulRet);


function PackageLogicForLua.onRecieveEquipDress(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = EquipOpr_pb.HPEquipDressRet();
        local pbMsg = handler:getRecPacketBuffer();
        msg:ParseFromString(pbMsg);

        if msg:HasField("onEquipId") then
            UserEquipManager:takeOn(msg.onEquipId, msg.roleId)
            --MessageBoxPage:Msg_Box("@HasEquiped")
        end
        if msg:HasField("offEquipId") then
            UserEquipManager:takeOff(msg.offEquipId);
            --if msg.offEquipId ~= 0 and msg.onEquipId == 0 then
            --    MessageBoxPage:Msg_Box("@RemoveEquip")
            --end
        end
        local ALFManager = require("Util.AsyncLoadFileManager")
        for page = RedPointManager.PAGE_IDS.WEAPON_ALL_BTN, RedPointManager.PAGE_IDS.FOOT_ONE_ICON do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[page].groupNum
            for i = 1, groupNum do
                local fn = function()
                    RedPointManager_refreshPageShowPoint(page, i)
                    RedPointManager_setPageSyncDone(page, i)
                end
                ALFManager:loadRedPointTask(fn, page * 100 + i)
            end
        end
    end
end
PackageLogicForLua.HPListenEquipDress = PacketScriptHandler:new(HP_pb.EQUIP_DRESS_S, PackageLogicForLua.onRecieveEquipDress);

function PackageLogicForLua.onRecieveAllEquipDress(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = EquipOpr_pb.HPEquipOneKeyDressRet();
        local pbMsg = handler:getRecPacketBuffer();
        msg:ParseFromString(pbMsg);
        for i = 1, #msg.DressRet do
            local oneMsg = msg.DressRet[i]
            if oneMsg:HasField("onEquipId") then
                UserEquipManager:takeOn(oneMsg.onEquipId, oneMsg.roleId)
            end
            if oneMsg:HasField("offEquipId") then
                UserEquipManager:takeOff(oneMsg.offEquipId)
            end
        end
        local ALFManager = require("Util.AsyncLoadFileManager")
        for page = RedPointManager.PAGE_IDS.WEAPON_ALL_BTN, RedPointManager.PAGE_IDS.FOOT_ONE_ICON do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[page].groupNum
            for i = 1, groupNum do
                local fn = function()
                    RedPointManager_refreshPageShowPoint(page, i)
                    RedPointManager_setPageSyncDone(page, i)
                end
                ALFManager:loadRedPointTask(fn, page * 100 + i)
            end
        end
    end
end
PackageLogicForLua.HPListenAllEquipDress = PacketScriptHandler:new(HP_pb.EQUIP_ONEKEY_DRESS_S, PackageLogicForLua.onRecieveAllEquipDress);


function PackageLogicForLua.onRecieveAttrChange(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Attribute_pb.AttrInfo();
        local pbMsg = handler:getRecPacketBuffer();
        msg:ParseFromString(pbMsg);

        local wordList = { };
        local colorList = { };
        for _, attr in ipairs(msg.attribute) do
            if attr.attrValue ~= 0 then
                local valStr = "";
                if EquipManager:getAttrGrade(attr.attrId) == Const_pb.GODLY_ATTR and not EquipManager:isGodlyAttrPureNum(attr.attrId) then
                    if attr.attrId >= Const_pb.ICE_ATTACK and attr.attrId < Const_pb.ICE_ATTACK_RATIO then
                        valStr = string.format(" %+d", attr.attrValue);
                    else
                        valStr = string.format(" %+.2f%%", attr.attrValue / 100);
                    end

                else
                    valStr = string.format(" %+d", attr.attrValue);
                end
                table.insert(wordList, common:getLanguageString("@AttrName_" .. attr.attrId) .. valStr);
                local colorKey = attr.attrValue > 0 and "COLOR_GREEN" or "COLOR_RED";
                table.insert(colorList, GameConfig.ColorMap[colorKey]);
            end
        end
        return insertMessageFlow(wordList, colorList);
    end
end
PackageLogicForLua.HPListenAttrChange = PacketScriptHandler:new(HP_pb.ATTRIBUTE_CHANGE_NOTICE, PackageLogicForLua.onRecieveAttrChange);

--[[
function PackageLogicForLua.onRecieveLogin(eventName, handler)
	if eventName == "luaReceivePacket" then
		ArenaPage_Reset()
		local msg = Arena_pb.HPArenaDefenderList()
		msg.playerId = UserInfo.playerInfo.playerId
		pb_data = msg:SerializeToString()
		PacketManager:getInstance():sendPakcet(HP_pb.ARENA_DEFENDER_LIST_C, pb_data, #pb_data, true)
	end
end
PackageLogicForLua.HPListenLogin = PacketScriptHandler:new(HP_pb.LOGIN_S, PackageLogicForLua.onRecieveLogin);
--]]

-- 地图统计信息相关
function PackageLogicForLua.onReceiveMapStaticSync(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Battle_pb.HPMapStatisticsSync();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        -- 由于BattlePage时效性，第一次由全局获取，之后由BattlePage决定
        if msg ~= nil and g_firstGotMapStatic == false then
            g_firstGotMapStatic = true
            g_mapStaticMsg = msg
        else
            -- CCLuaLog("@onReceiveMapStaticSync -- error in data");
        end
    end
end
PackageLogicForLua.HPMapStaticsSync = PacketScriptHandler:new(HP_pb.MAP_STATISTICS_SYNC_S, PackageLogicForLua.onReceiveMapStaticSync);

-----------------message box handler-------------------
function PackageLogicForLua.onReceiveOfflineMessageBox(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Friend_pb.HPMsgBoxInfo();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg ~= nil then
            hasNewChatComing = true
            local newMsgFlag = false
            -- 离线新消息世界聊天显示红炿
            for i = 1, #msg.msgBoxUnits do
                local oneData = msg.msgBoxUnits[i]
                -- offline msg push
                if oneData ~= nil then
                    newMsgFlag = true
                    hasNewChatComing = true
                    hasNewPrivateChatComing = true
                    NoticePointState.isChange = true
                    ChatManager.insertPrivateMsg(oneData.playerId, oneData, nil, true)
                    PageManager.refreshPage("ChatPage", "PrivateChat")
                end
            end
            -- 私聊聊天记录修改
            if isSaveChatHistory then
                if newMsgFlag then
                    -- 有消息才刷新
                    ChatManager.sortTimePersonalList()
                    -- ChatManager.refreshMainNewChatPointTips()
                    PageManager.refreshPage("ChatPage", "PrivateChat")
                end
            end
        else
            CCLuaLog("@onReceiveOfflineMessageBox -- error in data");
        end
    end
end
PackageLogicForLua.HPOfflineMessageBox = PacketScriptHandler:new(HP_pb.MESSAGE_BOX_INFO_S, PackageLogicForLua.onReceiveOfflineMessageBox);

-----------------message box handler-------------------
function PackageLogicForLua.onReceivePrivateChatMsg(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Friend_pb.HPMsgPush();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg ~= nil then
            -- online msg push
            msg.friendMsg.headIcon = msg.msgBoxUnit.headIcon
            ChatManager.insertPrivateMsg(msg.msgBoxUnit.playerId, msg.msgBoxUnit, msg.friendMsg, false)
            hasNewChatComing = true
            hasNewPrivateChatComing = true
            NoticePointState.isChange = true
            local identify = msg.msgBoxUnit.senderIdentify
            if not msg.msgBoxUnit:HasField("senderIdentify") or identify == "" then
                identify = msg.msgBoxUnit.playerId
            end
            ChatManager.refreshMainNewChatPointTips()
            PageManager.refreshPage("ChatPage", "privateChat" .. "." .. tostring(1) .. "." .. identify)
        else
            CCLuaLog("@onReceivePrivateChatMsg -- error in data");
        end
    end
end
PackageLogicForLua.HPPrivateChatMsg = PacketScriptHandler:new(HP_pb.MESSAGE_PUSH_S, PackageLogicForLua.onReceivePrivateChatMsg);

-----------------shield player handler-------------------
function PackageLogicForLua.onReceiveShieldPlayerList(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Friend_pb.HPShieldList();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg ~= nil then
            return ChatManager.recieveShieldList(msg.shieldPlayerId)
        else
            CCLuaLog("@onReceiveShieldPlayerList -- error in data");
        end
    end
end
PackageLogicForLua.HPShieldPlayerList = PacketScriptHandler:new(HP_pb.FRIEND_SHIELD_LIST_S, PackageLogicForLua.onReceiveShieldPlayerList);

function PackageLogicForLua.onReceiveSkillBag(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Skill_pb.HPSkillInfo()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        if msg ~= nil then

        end
    end
end
PackageLogicForLua.HPSysSkillList = PacketScriptHandler:new(HP_pb.SKILL_BAG_S, PackageLogicForLua.onReceiveSkillBag)

function PackageLogicForLua.onReceiveNotify(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Player_pb.HPDataNotify();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg.type == Const_pb.NOTIFY_RECHARGE then
            PageManager.pushPage("RechargeSucceedPopUpPage")
            PageManager.refreshPage("MainScenePage")

            local msg1 = MsgMainFrameRefreshPage:new()
            msg1.pageName = "RechargePage"
            MessageManager:getInstance():sendMessageForScript(msg1)

            local msg2 = MsgMainFrameRefreshPage:new()
            msg2.pageName = "VipWelfarePage"
            MessageManager:getInstance():sendMessageForScript(msg2)
            local strtable = {
                show = false,
            }

            PageManager.refreshPage("LimitActivityPage", "refreshPageUserGold")
            if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
                libOS:getInstance():setWaiting(false)
            end

            local HP_pb = require("HP_pb");

            local Recharge_pb = require("Recharge_pb");
            local msg3 = Recharge_pb.HPFetchShopList()
            --msg3.platform = libPlatformManager:getPlatform():getClientChannel()
            --if Golb_Platform_Info.is_win32_platform then
            msg3.platform = GameConfig.win32Platform
            --end
            CCLuaLog("PlatformName2:" .. msg3.platform)
            --common:sendPacket(HP_pb.FETCH_SHOP_LIST_C, msg3,false);

            -- 更新放置经验
            local JsMsg = cjson.encode(strtable)
            libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_WAITVIEW", JsMsg)
            common:sendEmptyPacket(HP_pb.FIRST_GIFTPACK_INFO_C, false)
            common:sendEmptyPacket(HP_pb.RED_POINT_LIST_C, false)
            -- 主动请求数据,控制红点逻辑
            if (msg.goodsId == 30 or msg.goodsId == 51 or msg.goodsId == 52 or msg.goodsId == 53 or msg.goodsId == 54 or msg.goodsId == 55) then
                if msg.goodsId == 30 then
                    common:sendEmptyPacket(HP_pb.MONTHCARD_INFO_C, true)
                end
                -- 暂时去除amazon屏蔽
                -- if GCAndGPBoundStatu == false and not Golb_Platform_Info.is_gNetop_amazon_platform then
                --[[
                if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
				    if GCAndGPBoundStatu == false then
					    local titile = common:getLanguageString("@BoundTitle");
					    local tipinfo = ""
					    if msg.goodsId == 30 then
						    tipinfo = common:getLanguageString("@CantBuyTips");
					    else
						    tipinfo = common:getLanguageString("@CantBuyTipsWeek");
					    end
					    PageManager.showConfirm(titile, tipinfo, function(isSure)
						    if isSure then
							    PageManager.pushPage("GpAndGcBoundPage")
						    end
					    end );
				    end
                end
                ]]

            elseif msg.goodsId == 41 or msg.goodsId == 42 or msg.goodsId == 43 then
                common:sendEmptyPacket(HP_pb.SALE_PACKET_INFO_C, true)
            else
                --[[local WeekCardCfg = ConfigManager.getWeekCardCfg()
				for k, v in pairs(WeekCardCfg) do
					if msg.goodsId == v.id then
						common:sendEmptyPacket(HP_pb.NEW_WEEK_CARD_INFO_C, true)
						break;
					end
				end]]
                --
            end

            local WeekCardCfg = ConfigManager.getWeekCardCfg()
            for k, v in pairs(WeekCardCfg) do
                if msg.goodsId == v.id then
                    common:sendEmptyPacket(HP_pb.NEW_WEEK_CARD_INFO_C, true)
                    break;
                end
            end

            -- LifelongCardPage charge 1000 show red
            require("Activity.ActivityInfo");
            if ActivityInfo ~= nil then
                if ActivityInfo.activities[Const_pb.FOREVER_CARD] ~= nil then
                    common:sendEmptyPacket(HP_pb.FOREVER_CARD_INFO_C)
                end
                if msg.goodsId >= 1 and msg.goodsId <= 6 and ActivityInfo.activities[Const_pb.SINGLE_RECHARGE] then
                    common:sendEmptyPacket(HP_pb.SINGLE_RECHARGE_INFO_C, true)
                end
                if ActivityInfo.activities[Const_pb.CRAZY_ROULETTE] ~= nil then
                    common:sendEmptyPacket(HP_pb.ROULETTE_INFO_C, false)
                end
                if ActivityInfo.activities[Const_pb.ACCUMULATIVE_RECHARGE] ~= nil then
                    common:sendPacket(HP_pb.ACC_RECHARGE_INFO_C, msg, false);
                end
            end
        end
    end
end
PackageLogicForLua.HPRechargeNotify = PacketScriptHandler:new(HP_pb.DATA_NOTIFY_S, PackageLogicForLua.onReceiveNotify);



function PackageLogicForLua.onReceiveCampWarState(eventName, handler)
    if eventName == "luaReceivePacket" then
        local CampWar_pb = require("CampWar_pb");
        local msg = CampWar_pb.HPCampWarStateSyncS();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        local CampWarManager = require("PVP.CampWarManager")
        return CampWarManager.RecieveCampWarMainState(msg)
    end
end
PackageLogicForLua.HPCampWarStateSync = PacketScriptHandler:new(HP_pb.CAMPWAR_STATE_SYNC_S, PackageLogicForLua.onReceiveCampWarState);

function PackageLogicForLua.onReceiveCampWarInFightState(eventName, handler)
    if eventName == "luaReceivePacket" then
        local CampWar_pb = require("CampWar_pb");
        local msg = CampWar_pb.HPCampWarInfoSyncS();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        local CampWarManager = require("PVP.CampWarManager")
        return CampWarManager.RecieveCampWarInFightState(msg)
    end
end
PackageLogicForLua.HPCampWarInFightStateSync = PacketScriptHandler:new(HP_pb.CAMPWAR_INFO_SYNC_S, PackageLogicForLua.onReceiveCampWarInFightState);

function PackageLogicForLua.onReceiveCampRankInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local CampWar_pb = require("CampWar_pb");
        local msg = CampWar_pb.HPLastCampWarRankInfoSyncS();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        local CampWarManager = require("PVP.CampWarManager")
        return CampWarManager.RecieveCampLastRankInfo(msg)
    end
end
PackageLogicForLua.HPCampWarLastRankSync = PacketScriptHandler:new(HP_pb.LAST_CAMPWAR_RANK_SYNC_S, PackageLogicForLua.onReceiveCampRankInfo);

function PackageLogicForLua.onReceivePlayerTitleInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local PlayerTitle_pb = require("PlayerTitle_pb");
        local msg = PlayerTitle_pb.HPTitleInfoSyncS();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        local TitleManager = require("PlayerInfo.TitleManager")
        TitleManager:setTitleInfo(msg)
    end
end
PackageLogicForLua.HPTitleInfoSyncS = PacketScriptHandler:new(HP_pb.TITLE_SYNC_S, PackageLogicForLua.onReceivePlayerTitleInfo);

function PackageLogicForLua.onReceiveRechargeList(eventName, handler)
    if eventName == "luaReceivePacket" then
        if loadingOpcodes[HP_pb.FETCH_SHOP_LIST_S].done == false then loadingOpcodes[HP_pb.FETCH_SHOP_LIST_S].done = true end
        --checkAndCloseMainSceneLoadingEnd()
    end
end
PackageLogicForLua.HPShopListSync = PacketScriptHandler:new(HP_pb.FETCH_SHOP_LIST_S, PackageLogicForLua.onReceiveRechargeList);

function PackageLogicForLua.onReceiveContinueRecharge(eventName, handler)
    if eventName == "luaReceivePacket" then
        if loadingOpcodes[HP_pb.NP_CONTINUE_RECHARGE_MONEY_S].done == false then loadingOpcodes[HP_pb.NP_CONTINUE_RECHARGE_MONEY_S].done = true end
    end
end
PackageLogicForLua.HPContinueRechargeSync = PacketScriptHandler:new(HP_pb.NP_CONTINUE_RECHARGE_MONEY_S, PackageLogicForLua.onReceiveContinueRecharge);

function PackageLogicForLua.onReceiveLoginDay(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgbuff = handler:getRecPacketBuffer();
        local Activity_pb = require("Activity_pb");
        local msg = Activity_pb.HPRegisterCycleRet();
        msg:ParseFromString(msgbuff);
        local mainScenePage = require("MainScenePage")
        mainScenePage:setLoginDay(msg.registerSpaceDays)

        if GlobalData.diamondRatio == nil then
            if msg:HasField("ratio") then
                GlobalData.diamondRatio = 0.5
            else
                GlobalData.diamondRatio = 0
            end
        end
        PageManager.refreshPage("MainScenePage")
    end
end
PackageLogicForLua.HPLoginDaySync = PacketScriptHandler:new(HP_pb.REGISTER_CYCLE_INFO_S, PackageLogicForLua.onReceiveLoginDay);

-- 同步公会元气
function PackageLogicForLua.onReceiveGuildBossVitality(eventName, handler)
    local GuildData = require('Guild.GuildData')
    if eventName == "luaReceivePacket" then
        local msgbuff = handler:getRecPacketBuffer();
        local Alliance_pb = require("Alliance_pb");
        local msg = Alliance_pb.HPBossVitalitySyncS();
        msg:ParseFromString(msgbuff);
        GuildData.allianceInfo.commonInfo.curBossVitality = msg.curBossVitality
        GuildData.allianceInfo.commonInfo.openBossVitality = msg.openBossVitality
        PageManager.refreshPage("GuildPage_Refresh_BossPage")
    end
end
PackageLogicForLua.HPGuildBossVitalitySync = PacketScriptHandler:new(HP_pb.BOSS_VITALITY_SYNC_S, PackageLogicForLua.onReceiveGuildBossVitality);


-- 
function PackageLogicForLua.onReceiveRoleRingInfoSync(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgbuff = handler:getRecPacketBuffer();
        local msg = Player_pb.HPRoleRingInfoSync();
        msg:ParseFromString(msgbuff);
        local MercenaryHaloManager = require("Mercenary.MercenaryHaloManager")
        MercenaryHaloManager:onRecieveSyncMsg(msg);
        PageManager.refreshPage("MercenaryHaloPage")
        PageManager.refreshPage("MercenaryHaloEnhancePage")
    end
end
PackageLogicForLua.HPRoleRingSync = PacketScriptHandler:new(HP_pb.ROLE_RING_INFO_S, PackageLogicForLua.onReceiveRoleRingInfoSync);

function PackageLogicForLua.onReceiveSkillSync(eventName, handler)
    if eventName == "luaReceivePacket" then
        local SkillManager = require("Skill.SkillManager")
        SkillManager:classifyOpenSkillDataFromC()
    end
end
PackageLogicForLua.HPSkillSyncHandler = PacketScriptHandler:new(HP_pb.SKILL_INFO_SYNC_S, PackageLogicForLua.onReceiveSkillSync);


function PackageLogicForLua.onReceiveEliteMapInfoSync(eventName, handler)
    if eventName == "luaReceivePacket" then
    end
end
PackageLogicForLua.HPEliteMapSyncHandler = PacketScriptHandler:new(HP_pb.ELITE_MAP_INFO_SYNC_S, PackageLogicForLua.onReceiveEliteMapInfoSync);
-- TODO: æ—¥æœ¬iOSå…è´¹æœˆå¡
function PackageLogicForLua.onGNetopFreeMonthForIOSAndSync(eventName, handler)

    -- TODO: æ—¥æœ¬iOSå…è´¹æœˆå¡
    -- 1:æ´»åŠ¨å¼€å?0:æ´»åŠ¨å…³é—­
    if eventName == "luaReceivePacket" then
        local msg = Reward_pb.HPJPActivityStatusRet();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        CCLuaLog("@------onGNetopFreeMonthForIOS------");
        if msg ~= nil then
            CCLuaLog("------------------onGNetopFreeMonthForIOS-------GET_JP_ACTIVITY_STATUS_S------------------------------")
            CCLuaLog("--------------------onGNetopFreeMonthForIOS-----------------------------------" .. msg.jPActivityStatus)
            GnetopFreeMonthIsOpen =(msg.jPActivityStatus == 1)
            if Golb_Platform_Info.is_gNetop_platform and BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
                --            if Golb_Platform_Info.is_gNetop_platform then
                if GnetopFreeMonthIsOpen then
                    PageManager.pushPage("FreeMonthCardPopUp");
                    GnetopFreeMonthIsOpen = false
                end
            end
        end
    end


end
PackageLogicForLua.HPGNetopFreeMonthForIOSHandler = PacketScriptHandler:new(HP_pb.JP_ACTIVITY_STATUS_SYNC, PackageLogicForLua.onGNetopFreeMonthForIOSAndSync);




function PackageLogicForLua.onReceiveClientSetting(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgbuff = handler:getRecPacketBuffer();
        local msg = Player_pb.HPClientSetting();
        msg:ParseFromString(msgbuff);
        local ClientSettingManager = require("ClientSettingManager")
        ClientSettingManager:onReceivePacket(msg)

        -- ???????"??????
        local hasKey, value = ClientSettingManager:findAndGetValueByKey("IsUseNewPackagePage")
        if hasKey then
            -- package.loaded["PackagePage"] = nil
            -- require("PackagePage")
        end
    end
end
PackageLogicForLua.HPClientSettingPush = PacketScriptHandler:new(HP_pb.CLIENT_SETTING_PUSH, PackageLogicForLua.onReceiveClientSetting);


function PackageLogicForLua.onReceiveAllianceBattleInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgbuff = handler:getRecPacketBuffer();
        local AB_pb = require("AllianceBattle_pb")
        local msg = AB_pb.HPAFMainEnterSync();
        msg:ParseFromString(msgbuff);
        local ABManager = require("Guild.ABManager")
        ABManager:onReceiveEnterPacket(msg)
    end
end
PackageLogicForLua.HPEnterAFMainSync = PacketScriptHandler:new(HP_pb.ALLIANCE_BATTLE_ENTER_S, PackageLogicForLua.onReceiveAllianceBattleInfo);

function PackageLogicForLua.onRecieveAllianceTeamDetail(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local AB_pb = require("AllianceBattle_pb")
        local msg = AB_pb.HPAllianceTeamDetailRet();
        local ABTeamInfoManager = require("Guild.ABTeamInfoManager")
        msg:ParseFromString(msgBuff);
        ABTeamInfoManager:onReceivePacket(msg)
        --[[ViewPlayerInfo:setInfo(msgBuff);
		PageManager.pushPage("ViewPlayerInfoPage");--]]
    end
end
PackageLogicForLua.HPAllianceTeamDetailInfo = PacketScriptHandler:new(HP_pb.ALLIANCE_TEAM_DETAIL_INFO_S, PackageLogicForLua.onRecieveAllianceTeamDetail);

function PackageLogicForLua.onRecievePlayAreaInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        CCLuaLog("VoiceChatManager:" .. "onRecievePlayAreaInfo")
        local msgBuff = handler:getRecPacketBuffer();
        local Player_pb = require("Player_pb")
        local msg = Player_pb.HPPlayerAreaSync();
        msg:ParseFromString(msgBuff);
        local VoiceChatManager = require("Battle.VoiceChatManager")
        if msg:HasField("area") then
            VoiceChatManager.playerArea = msg.area
            CCLuaLog("VoiceChatManager:" .. msg.area)
        end

    end
end
PackageLogicForLua.HPPlayerAreaSync = PacketScriptHandler:new(HP_pb.PLAYER_AREA_SYNC, PackageLogicForLua.onRecievePlayAreaInfo)

-- ?S??
function PackageLogicForLua.onRecieveSEOpenInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local SEManager = require("Skill.SEManager")
        SEManager:getEnterData(msgBuff)
    end
end
PackageLogicForLua.HPSkillEnhanceOpenState = PacketScriptHandler:new(HP_pb.SKILL_ENHANCE_OPEN_STATE_S, PackageLogicForLua.onRecieveSEOpenInfo)


-- ÃŠÃ€Â½Ã§boss
function PackageLogicForLua.onRecieveWorldBossState(eventName, handler)
    local WorldBossManager = require("PVP.WorldBossManager");
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer();
        local WorldBoss_pb = require("WorldBoss_pb")
        local msg = WorldBoss_pb.HPBossStatePush();
        msg:ParseFromString(msgBuff)
        if msg:HasField("activityBossId") then
            if msg.activityBossId ~= 0 then
                WorldBossManager.WorldBossAttrInfo.npcId = msg.activityBossId
            end
        end
        if msg.state == 1 then
            WorldBossManager.setBossState(msg.state)
            NoticePointState.isChange = true
            NoticePointState.WORlDBOSS_POINT = false
            PageManager.refreshPage("MainScenePage");
            PageManager.refreshPage("PVPActivityPage", "WorldBoss");
            PageManager.refreshPage("GuildPage_Refresh_WorldBoss");
        elseif msg.state == 3 then
            WorldBossManager.setBossState(msg.state)
            NoticePointState.WORlDBOSS_POINT = true
            NoticePointState.isChange = true
            PageManager.refreshPage("MainScenePage");
            PageManager.refreshPage("PVPActivityPage", "WorldBoss");
            PageManager.refreshPage("GuildPage_Refresh_WorldBoss");
        end
    end
end    
PackageLogicForLua.HPBossStatePush = PacketScriptHandler:new(HP_pb.WORLD_BOSS_STATE_PUSH, PackageLogicForLua.onRecieveWorldBossState)

-- 春节彩蛋
function PackageLogicForLua.onRecieveSpringFestivalEgg(eventName, handler)
    if eventName == "luaReceivePacket" then
    end
end    
PackageLogicForLua.HPPushChatLuck = PacketScriptHandler:new(HP_pb.CHAT_LUCK_PUSH_S, PackageLogicForLua.onRecieveSpringFestivalEgg)
--------------Role handler-----------------------
function PackageLogicForLua.onReceiveRoleSync(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Player_pb = require("Player_pb")
        local UserMercenaryManager = require("UserMercenaryManager")
        local SpiritDataMgr = require("Spirit.SpiritDataMgr")
        local msg = Player_pb.HPRoleInfoSync();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        UserInfo.activiteRoleId = msg.activiteRoleId
        if msg ~= nil then
            local count = #msg.roleInfos;
            for i = 1, count do
                local info = msg.roleInfos[i];
                
                if info.type == 1 then
                    UserInfo.syncRoleinfoForlua(info);
                end

                UserInfo.setRoleMasterFight(info);

                if info.type == 1 then
                    
                elseif info.type == 4 then
                    -- 更新 精靈資料
                    SpiritDataMgr:updateUserSpiritStatusInfoByRoleInfo(info)
                else
                    UserMercenaryManager:initMercenaryHaloStatus(info)
                end

                PageManager.refreshPage("EquipRefreshPage", tostring(info.roleId))
            end
        end

    end
end

PackageLogicForLua.HPRoleSync = PacketScriptHandler:new(HP_pb.ROLE_INFO_SYNC_S, PackageLogicForLua.onReceiveRoleSync);

function PackageLogicForLua.onReceiveRoleExpSync(eventName,handler)
	if eventName == "luaReceivePacket" then		
		local Player_pb = require ("Player_pb")
		local msg = Reward_pb.HPPlayerReward();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)
	    if msg:HasField("rewards") then
			if msg.rewards:HasField("level") then
                --require("Util.RedPointManager")
                --RedPointManager_refreshRedPointByCondition(RedPointManager.RefreshCondition.LEVEL)
            end
            if msg.rewards["showItems"] then
				for k, v in pairs(msg.rewards["showItems"]) do
                    if v.itemId == 1025 then
                        UserInfo.stateInfo.friendship = UserInfo.stateInfo.friendship + v.itemCount
                    elseif v.itemId == 1026 then
                        --UserInfo.stateInfo.vipPoint = UserInfo.stateInfo.vipPoint + v.itemCount
                    end
                end
			end
	    end

	end
end
PackageLogicForLua.HPRoleExpSync = PacketScriptHandler:new(HP_pb.PLAYER_AWARD_S, PackageLogicForLua.onReceiveRoleExpSync);


function PackageLogicForLua.onRecieveHeartBeat(eventName, handler)
    if eventName == "luaReceivePacket" then
        local SysProtocol_pb = require "SysProtocol_pb"
        local msg = SysProtocol_pb.HPHeartBeat();
        local pbMsg = handler:getRecPacketBuffer();
        msg:ParseFromString(pbMsg);
        -- firstHeartBeatReceive = true

        -- local GVGCrossManager = require("GVGCrossManager")
        if msg:HasField("timeStamp") then
            localSeverTime = msg.timeStamp
            -- GVGCrossManager:setServerTime(msg.timeStamp)
        end
        -- if GVGManager.needCheckGuildPoint then
        -- GVGManager.reqGuildInfo()
        -- end
    end
end

PackageLogicForLua.HPListenHeartBeat = PacketScriptHandler:new(HP_pb.HEART_BEAT, PackageLogicForLua.onRecieveHeartBeat);

function PackageLogicForLua.onReceiveHPMultiEliteShopBuyRet(eventName, handler)
    if eventName == "luaReceivePacket" then
        local MultiElite_pb = require("MultiElite_pb")
        local msg = MultiElite_pb.HPMultiEliteShopBuyRet()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg ~= nil then
        end
    end
end
PackageLogicForLua.HPMultiEliteShopBuyRet = PacketScriptHandler:new(HP_pb.MULTIELITE_SHOP_BUY_S, PackageLogicForLua.onReceiveHPMultiEliteShopBuyRet);

function PackageLogicForLua.onReceiveServerTimeZone(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Time_pb = require("SysProtocol_pb")
        local msg = Time_pb.HPTimeZoneRet();
        local msgbuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        if msg ~= nil then
            ServerOffset_UTCTime = 0 - msg.timezone
            CCLuaLog('ServerOffset_UTCTime===' .. ServerOffset_UTCTime)
        end
    end
end
PackageLogicForLua.HPTimeSync = PacketScriptHandler:new(HP_pb.TIME_ZONE_S, PackageLogicForLua.onReceiveServerTimeZone);
-- 后端同步玩家数据
function PackageLogicForLua.onReceiveSynchroPlayer(eventName, handler)
    if eventName == "luaReceivePacket" then
        local synchroPlayerMsg_pb = require("synchroPlayerMsg_pb")
        local msg = synchroPlayerMsg_pb.SynchroPlayerMessage()
        local msgbuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        if msg then
            UserInfo.wingLevel = msg.wingLevel
            UserInfo.wingLucky = msg.wingLuckyNum
            CCLuaLog("UserInfo wingLevel is: " .. tostring(msg.wingLevel));
        end
    end
end
PackageLogicForLua.SynchroPlayer = PacketScriptHandler:new(HP_pb.SYNCHRO_PLAYER_MESSAGE_S, PackageLogicForLua.onReceiveSynchroPlayer)
function PackageLogicForLua.onReceiveMailGetRet(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Mail_pb = require("Mail_pb")
        local msg = Mail_pb.OPMailGetRet()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        local MailDataHelper = require("Mail.MailDataHelper")
        MailDataHelper:onReceiveMailGetInfo(msg)
        PageManager.refreshPage("MailPage")
        local GUILD_MAIL = {
            [106] = true,
            [107] = true,
            [108] = true,
            [109] = true,
            [110] = true,
            [111] = true,
            [112] = true,
            applyMailId = 106,
        }
        local boo = true
        for k, v in ipairs(MailDataHelper:getVariableByKey("mails")) do
            if v.type == Mail_pb.Reward then
                boo = false
            end
            if GUILD_MAIL[v.mailId] then
                -- GUILD_MAIL.applyMailId then
                boo = false
            end
        end
        if boo then
            MailDataHelper:sendClosesNewInfoMessage()
        end
    end
end
PackageLogicForLua.HPMailGetRet = PacketScriptHandler:new(HP_pb.MAIL_GET_S, PackageLogicForLua.onReceiveMailGetRet)

--function PackageLogicForLua.onReceiveFaceShareCount(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local msg = Player_pb.HPFacebookShareCountRet()
--        local msgBuff = handler:getRecPacketBuffer()
--        msg:ParseFromString(msgBuff)
--        ShowFBShareNotice =(msg.number == 0);
--        MainScenePage:CheckFBShareNotice();
--    end
--end
--PackageLogicForLua.HPReceiveFaceShareCountHandler = PacketScriptHandler:new(HP_pb.FACEBOOK_STATE_SHARE_S, PackageLogicForLua.onReceiveFaceShareCount)

function PackageLogicForLua.onReceiveSmallMonthCard(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Activity4_pb.ConsumeMonthCardInfoRet()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        local IAPRedPage=require("IAP.IAPRedPointMgr")
        IAPRedPage:SmallMonthCardRedPointSync(msg)
    end
end
PackageLogicForLua.HPReceiveMontylyCardHandler = PacketScriptHandler:new(HP_pb.CONSUME_MONTHCARD_INFO_S, PackageLogicForLua.onReceiveSmallMonthCard)

function PackageLogicForLua.onReceiveLargeMonthCard(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Activity4_pb.ConsumeWeekCardInfoRet()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        local IAPRedPage=require("IAP.IAPRedPointMgr")
        IAPRedPage:LargeMonthCardRedPointSync(msg)
    end
end
PackageLogicForLua.HPReceiveMontylyCardHandler = PacketScriptHandler:new(HP_pb.CONSUME_WEEK_CARD_INFO_S, PackageLogicForLua.onReceiveLargeMonthCard)

function PackageLogicForLua.onReceiveSupCalendar(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Activity5_pb.SupportCalendarRep()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        local IAPRedPage=require("IAP.IAPRedPointMgr")
        IAPRedPage:ClaendarRedPointSync(msg)
    end
end
PackageLogicForLua.HPReceiveMontylyCardHandler = PacketScriptHandler:new(HP_pb.SUPPORT_CALENDAR_ACTION_S, PackageLogicForLua.onReceiveSupCalendar)

function PackageLogicForLua.onReceiveSummon(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Activity5_pb.FreeSummonResp()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        local RewardRedPage=require("Reward.RewardRedPointMgr")
        RewardRedPage:FreeSummonRedPointSync(msg)
        local FreeSummonPage=require("Reward.RewardSubPage_FreeSummon")
        FreeSummonPage:setSeverData(msg)
    end
end
PackageLogicForLua.HPReceiveMontylyCardHandler = PacketScriptHandler:new(HP_pb.ACTIVITY167_FREE_SUMMOM_S, PackageLogicForLua.onReceiveSummon)

function PackageLogicForLua.onReceiveSummon2(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Activity5_pb.FreeSummonResp()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        local RewardRedPage=require("Reward.RewardRedPointMgr")
        RewardRedPage:FreeSummonRedPointSync(msg)
        local FreeSummonPage2=require("Reward.RewardSubPage_FreeSummon2")
        FreeSummonPage2:setSeverData(msg)
    end
end
PackageLogicForLua.HPReceiveMontylyCardHandler = PacketScriptHandler:new(HP_pb.ACTIVITY180_FREE_SUMMOM_S, PackageLogicForLua.onReceiveSummon2)

function PackageLogicForLua.onReceiveSummon3(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Activity5_pb.StepSummonResp()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        --local RewardRedPage=require("Reward.RewardRedPointMgr")
        local CostSummon1=require("Reward.RewardSubPage_CostSummon1")
        local CostSummon2=require("Reward.RewardSubPage_CostSummon2")
        local CostSummon3=require("Reward.RewardSubPage_CostSummon3")
        CostSummon1:setSeverData(msg)
        CostSummon2:setSeverData(msg)
        CostSummon3:setSeverData(msg)
    end
end
PackageLogicForLua.HPReceiveMontylyCardHandler = PacketScriptHandler:new(HP_pb.ACTIVITY190_STEP_SUMMOM_S, PackageLogicForLua.onReceiveSummon3)


function PackageLogicForLua.onReceiveStepBundle(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Activity5_pb.GiftResp()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
       local StepBundle =  require ("IAP.IAPSubPage_StepBundle")
       StepBundle:setData(msg)
    end
end
PackageLogicForLua.HPReceiveMontylyCardHandler = PacketScriptHandler:new(HP_pb.ACTIVITY179_STEP_GIFT_S, PackageLogicForLua.onReceiveStepBundle)

function PackageLogicForLua.onReceiveDailyLogin(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Activity4_pb.LoginSignedRep()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        local RewardRedPage=require("Reward.RewardRedPointMgr")
        RewardRedPage:DailyLoginRedPoint(msg)
    end
end
PackageLogicForLua.HPReceiveMontylyCardHandler = PacketScriptHandler:new(HP_pb.ACC_LOGIN_SIGNED_INFO_S, PackageLogicForLua.onReceiveDailyLogin)

function PackageLogicForLua.onReceiveAdjustEvent(eventName, handler)
    if eventName == "luaReceivePacket" then
        --[[message HPActionLog
{
	required int32 actionType = 1; //行为类型
	required string androidKey = 2; //行为类型
	required string iosKey = 3; //行为类型
	optional int32 count = 4; //可选参数，根据不同行为定义

}]]
        --
        local ActionLog_pb = require("ActionLog_pb")
        local msg = ActionLog_pb.HPActionLog()
        local msgBuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgBuff)
        local platformToken = ""
        local g2pTag = "G2P_RECORDING_ADJUST_EVENT";
        if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
            -- iOS
            platformToken = msg.iosKey
        else
            -- Android
            platformToken = msg.androidKey
        end

        local strtable = {
            token = platformToken,
        }
        -- 	if tonumber(msg.actionType) == 1 then--首冲
        -- 		strtable.price = msg.count
        -- 		g2pTag = "G2P_RECORDING_ADJUST_EVENT_FIRST_RECHARGE"
        -- 	end


        -- if Golb_Platform_Info.is_win32_platform then
        --    CCMessageBox("token = "..strtable.token.."\n".."type = "..msg.actionType,"AdjustEvent")
        -- end
        local JsMsg = cjson.encode(strtable)
        libPlatformManager:getPlatform():sendMessageG2P(g2pTag, JsMsg)
    end
end
PackageLogicForLua.HPonReceiveAdjustEventHandler = PacketScriptHandler:new(HP_pb.ACTION_LOG_S, PackageLogicForLua.onReceiveAdjustEvent)

function PackageLogicForLua.onReceiveMercenaryExpeditionFinish(eventName, handler)
    if eventName == "luaReceivePacket" then
        local pageInfo = require("MercenaryExpeditionPage")
        if not pageInfo.IsInThisPage then
            local msgBuff = handler:getRecPacketBuffer()
            local MercenaryExpedition_pb = require("MercenaryExpedition_pb")
            local MercenaryExpeditionCfg = ConfigManager.getMercenaryExpeditionCfg()
            local msg = MercenaryExpedition_pb.HPMercenaryExpeditionFinishRet()
            msg:ParseFromString(msgBuff)
            local taskId = msg.taskId;
            local TaskCfg = MercenaryExpeditionCfg[taskId]
            MessageBoxPage:Msg_Box(common:getLanguageString("@MercenaryExpeditionFinish", common:getLanguageString(TaskCfg.name)))
            local taskName = "Task_01_" .. taskId
            local tmpTaskTimeCalcultor = { }
            local PushNotificationsManager = require("PushNotificationsManager")
            for keyName, Info in pairs(PushNotificationsManager.TaskTimeCalcultor) do
                if keyName == taskName and Info.mType == 0 then
                    TimeCalculator:getInstance():removeTimeCalcultor(keyName);
                else
                    tmpTaskTimeCalcultor[keyName] = Info
                end
            end
            PushNotificationsManager.TaskTimeCalcultor = tmpTaskTimeCalcultor;
            MainFrame_refreshTimeCalculator()
        end
    end
end
PackageLogicForLua.HPonReceiveMercenaryExpeditionFinishHandler = PacketScriptHandler:new(HP_pb.MERCENERY_EXPEDITION_FAST_S, PackageLogicForLua.onReceiveMercenaryExpeditionFinish)

function PackageLogicForLua.onReceiveMercenaryExpeditionInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local pageInfo = require("MercenaryExpeditionPage")
        if not pageInfo.IsInThisPage then
            local TaskInfo = {
                allTask = { },
                curTimes = 0,
                allTimes = 0,
                refreshCost = 50,
                nextRefreshTime = 0
            }
            local msgBuff = handler:getRecPacketBuffer()
            local MercenaryExpedition_pb = require("MercenaryExpedition_pb")
            local msg = MercenaryExpedition_pb.HPMercenaryExpeditionInfoRet()
            msg:ParseFromString(msgBuff)
            if  msg.allTask then
                TaskInfo.allTask = msg.allTask;
            end
            TaskInfo.curTimes = msg.curTimes;
            TaskInfo.allTimes = msg.allTimes;
            NoticePointState.EXPEDITION_POINT=false
            if TaskInfo.curTimes>=TaskInfo.allTimes then
               NoticePointState.EXPEDITION_POINT=false
            elseif UserInfo.stateInfo.passMapId>=40 then
                NoticePointState.EXPEDITION_POINT=true
            end
            TaskInfo.refreshCost = msg.refreshCost;
            TaskInfo.nextRefreshTime = msg.nextRefreshTime
            if TaskInfo.nextRefreshTime > 0 then
                TimeCalculator:getInstance():createTimeCalcultor("TaskALL", TaskInfo.nextRefreshTime)
            end
            local PushNotificationsManager = require("PushNotificationsManager")
            local index = 0
            for mID, SingleTask in pairs(TaskInfo.allTask) do
                if SingleTask.taskStatus == 1 and SingleTask.lastTimes > 1000 then
                    -- 进行中的任务
                    local leftTime = math.floor(SingleTask.lastTimes / 1000)
                    local time = os.time() + leftTime
                    local bSilence = false
                    for mID, SilenceCfg in pairs(PushNotificationsManager._SilenceCfg) do
                        local timeStart = os.time( { day = os.date("%d"), month = os.date("%m"), year = os.date("%Y"), hour = SilenceCfg._StartTime[1], minute = SilenceCfg._StartTime[2], second = SilenceCfg._StartTime[3] })
                        local timeEnd = os.time( { day = os.date("%d"), month = os.date("%m"), year = os.date("%Y"), hour = SilenceCfg._EndTime[1], minute = SilenceCfg._EndTime[2], second = SilenceCfg._EndTime[3] })
                        if time > timeStart and time < timeEnd then
                            bSilence = true
                        end
                    end
                    if not bSilence then
                        local keyName = "Task_01_" .. SingleTask.taskId
                        TimeCalculator:getInstance():createTimeCalcultor(keyName, leftTime)
                        PushNotificationsManager.TaskTimeCalcultor[keyName] = {
                            mKey = keyName,
                            mId = PushNotificationsManager._PushCfg[1]._Id,
                            mType = PushNotificationsManager._PushCfg[1]._Type,
                            mIcon = PushNotificationsManager._PushCfg[1]._Icon,
                            mSound = PushNotificationsManager._PushCfg[1]._Sound,
                            mText = PushNotificationsManager._PushCfg[1]._Text,
                            minLevel = PushNotificationsManager._PushCfg[1]._minLevel,
                            maxLevel = PushNotificationsManager._PushCfg[1]._maxLevel,
                            mTime = PushNotificationsManager._PushCfg[1]._Time,
                            mDateStart = PushNotificationsManager._PushCfg[1]._DateStart,
                            mDateEnd = PushNotificationsManager._PushCfg[1]._DateEnd,
                            mContainer = nil,
                            mFastCost = 0;
                        }
                        local Notification = PushNotificationsManager._PushCfg[1]._Text
                        local Sound = PushNotificationsManager._PushCfg[1]._Sound
                        if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
                            libOS:getInstance():addNotification(Notification, leftTime, false)
                        else
                            index = index + 1
                            local strtable = {
                                title = keyName,
                                timeleft = leftTime,
                                gamemsg = Notification,
                                action = "android.intent.action.MY_ALERT_RECEIVER_0" .. index,
                                sound = Sound,
                                dayloop = false;-- 是否每天循环 false表示只响应一次
                            }
                            local JsMsg = cjson.encode(strtable)
                            libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_NOTIFICATION", JsMsg)
                        end
                    end
                end
            end
            require("Util.RedPointManager")
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.BOUNTY) then
                RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.LOBBY_BOUNTY_BTN, 1, false)
            else
                RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.LOBBY_BOUNTY_BTN, 1, (TaskInfo.allTimes > TaskInfo.curTimes))
            end
        end
    end
end
PackageLogicForLua.HPonReceiveMercenaryExpeditionInfoHandler = PacketScriptHandler:new(HP_pb.MERCENERY_EXPEDITION_INFO_S, PackageLogicForLua.onReceiveMercenaryExpeditionInfo)

function PackageLogicForLua.onReceiveGuildApplyEmailRemove(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer()
        local msg = alliance.HPApplyAllianceEmailRemoves()
        msg:ParseFromString(msgBuff)
        local maiId = msg.emailId
        local MailDataHelper = require("Mail.MailDataHelper")
        MailDataHelper:removeMailById(maiId)
    end
end
PackageLogicForLua.HPonReceiveGuildApplyEmailRemoveHandler = PacketScriptHandler:new(HP_pb.APPLY_ALLIANCE_EMAIL_REMOVE, PackageLogicForLua.onReceiveGuildApplyEmailRemove)

function PackageLogicForLua.onReceiveQuestRedpointStatus(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Quest_pb = require("Quest_pb")
        local MissionManager = require("MissionManager")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Quest_pb.HPGetQuestRedPointStatusRet()
        msg:ParseFromString(msgBuff)
        require("Util.LockManager")
        if (msg.mainQuestStatus > 0 or msg.dailyQuestStatus > 0 or msg.achievementQuestStatus > 0) and
           (not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.QUEST)) then
            NoticePointState.isChange = true
            NoticePointState.MISSION_POINT = true
            require("Util.RedPointManager")
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.LOBBY_QUEST_BTN, 1, true)
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.BATTLE_QUEST_ENTRY, 1, true)
            if msg.dailyQuestStatus > 0 then
                RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 2, true)
            else
                RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 2, false)
            end
            if msg.mainQuestStatus > 0 then
                RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 1, true)
            else
                RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 1, false)
            end
            if msg.achievementQuestStatus > 0 then
                RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 3, true)
            else
                RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 3, false)
            end
        else
            NoticePointState.isChange = true
            NoticePointState.MISSION_POINT = false
            require("Util.RedPointManager")
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.LOBBY_QUEST_BTN, 1, false)
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.BATTLE_QUEST_ENTRY, 1, false)
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 1, false)
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 2, false)
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 3, false)
        end
        MissionManager.setRedPointStatus(msg)
        PageManager.refreshPage("MissionMainPage", "redPoint");
    end
end
PackageLogicForLua.HPonReceiveQuestRedpointStatusHandler = PacketScriptHandler:new(HP_pb.QUEST_GET_QUEST_REDPOINT_S, PackageLogicForLua.onReceiveQuestRedpointStatus)
function PackageLogicForLua.onReceiveMonthCardInfoStatus(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Quest_pb = require("Quest_pb")
        local Activity_pb = require("Activity_pb");
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Activity_pb.HPMonthCardInfoRet()
        msg:ParseFromString(msgBuff)
        g_IsInMonthCardStatus = msg.activeCfgId > 0

        PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo");
    end
end
PackageLogicForLua.HPonReceiveMonthCardInfoHandler = PacketScriptHandler:new(HP_pb.MONTHCARD_INFO_S, PackageLogicForLua.onReceiveMonthCardInfoStatus)


function PackageLogicForLua.onReceiveFormationStatus(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Formation_pb = require("Formation_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Formation_pb.HPFormationResponse()
        local FormationManager = require("FormationManager")
        msg:ParseFromString(msgBuff)
        if msg.type == 1 then
            -- 目前只存储主阵型
            FormationManager:setFormationInfo(msg)
            PageManager.refreshPage("EquipMercenaryPage");
        end
    end

end
PackageLogicForLua.HPonReceiveFormationInfoHandler = PacketScriptHandler:new(HP_pb.SHOW_FORMATION_INFO_S, PackageLogicForLua.onReceiveFormationStatus)

--- 好友申请推送
function PackageLogicForLua.onReceiveFriendAddApply(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Friend_pb = require("Friend_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Friend_pb.FriendItem()
        msg:ParseFromString(msgBuff)

        local FriendManager = require("FriendManager")
        FriendManager.onNewApply(msg)
    end
end
PackageLogicForLua.HPonReceiveFriendAddApplyHandler = PacketScriptHandler:new(HP_pb.FRIEND_ADD_APPLY_S, PackageLogicForLua.onReceiveFriendAddApply)

--- 新好友添加推送
function PackageLogicForLua.onReceiveFriendAdd(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Friend_pb = require("Friend_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Friend_pb.FriendItem()
        msg:ParseFromString(msgBuff)

        local FriendManager = require("FriendManager")
        FriendManager.onNewFriend(msg)
    end
end
PackageLogicForLua.HPonReceiveFriendAddHandler = PacketScriptHandler:new(HP_pb.FRIEND_ADD_FRIEND_S, PackageLogicForLua.onReceiveFriendAdd)

--- 好友列表
function PackageLogicForLua.onReceiveFriendList(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Friend_pb = require("Friend_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Friend_pb.HPFriendListRet()
        msg:ParseFromString(msgBuff)

        local FriendManager = require("FriendManager")
        FriendManager.syncFriendList(msg)
    end
end
PackageLogicForLua.HPonReceiveFriendList = PacketScriptHandler:new(HP_pb.FRIEND_LIST_S, PackageLogicForLua.onReceiveFriendList)

--- 好友申请列表
function PackageLogicForLua.onReceiveFriendApplyList(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Friend_pb = require("Friend_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Friend_pb.HPFriendListRet()
        msg:ParseFromString(msgBuff)

        local FriendManager = require("FriendManager")
        FriendManager.syncFriendApplyList(msg)
    end
end
PackageLogicForLua.HPonReceiveFriendApplyList = PacketScriptHandler:new(HP_pb.FRIEND_APPLY_LIST_S, PackageLogicForLua.onReceiveFriendApplyList)

function PackageLogicForLua.onRefuseFriendApply(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Friend_pb = require("Friend_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Friend_pb.HPRefuseApplyFriend()
        msg:ParseFromString(msgBuff)

        local FriendManager = require("FriendManager")
        FriendManager.onRefuseApply(msg.playerId)
    end
end
PackageLogicForLua.HPonRefuseFriendApply = PacketScriptHandler:new(HP_pb.FRIEND_REFUSE_S, PackageLogicForLua.onRefuseFriendApply)

function PackageLogicForLua.onDeleteFriend(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Friend_pb = require("Friend_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Friend_pb.HPFriendDelRet()
        msg:ParseFromString(msgBuff)

        local FriendManager = require("FriendManager")
        FriendManager.onDeleteFriend(msg.targetId)
    end
end
PackageLogicForLua.HPonDeleteFriend = PacketScriptHandler:new(HP_pb.FRIEND_DELETE_S, PackageLogicForLua.onDeleteFriend)

function PackageLogicForLua.onApplySent(eventName, handler)
    if eventName == "luaReceivePacket" then
        -- local Friend_pb = require("Friend_pb")
        -- local msgBuff = handler:getRecPacketBuffer()
        -- local msg = Friend_pb.HPFriendDelRet()
        -- msg:ParseFromString(msgBuff)

        -- local FriendManager = require("FriendManager")
        -- FriendManager.onDeleteFriend(msg.targetId)
        MessageBoxPage:Msg_Box("@RecommendSuccessTxt")
    end
end
PackageLogicForLua.HPonApplySent = PacketScriptHandler:new(HP_pb.FRIEND_APPLY_S, PackageLogicForLua.onApplySent)

function PackageLogicForLua.onMultiInvite(eventName, handler)
    if eventName == "luaReceivePacket" then
    end
end
PackageLogicForLua.onMultiInviteListener = PacketScriptHandler:new(HP_pb.MULIELTIE_MSG_NOTICE_S, PackageLogicForLua.onMultiInvite)

function PackageLogicForLua.onMultiNotice(eventName, handler)
    if eventName == "luaReceivePacket" then
        local MultiElite_pb = require("MultiElite_pb")
        local msg = MultiElite_pb.HPMultiEliteStatePush();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)

    end
end
PackageLogicForLua.onMultiNoticeListener = PacketScriptHandler:new(HP_pb.MULIELTIE_PUSH_STATE_S, PackageLogicForLua.onMultiNotice)

function PackageLogicForLua.onChatSkinChangeInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity2_pb = require("Activity2_pb")
        local msg = Activity2_pb.HPChatSkinInfo();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)

        curSkinId = msg.curSkinId
        if showChatSkinPage then
            local ChatSkinPage = require("ChatSkinPage")
            if #msg.skins > 0 then
                ChatSkinPage_initData(msg)
                PageManager.pushPage("ChatSkinPage")
            else
                MessageBoxPage:Msg_Box("@TLChatFrameErrorTxt1")
            end
        end
        showChatSkinPage = false
    end
end
PackageLogicForLua.HPonChatSkinChangeInfo = PacketScriptHandler:new(HP_pb.CHAT_SKIN_OWNED_INFO_S, PackageLogicForLua.onChatSkinChangeInfo)

function PackageLogicForLua.onChatSkinBuy(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity2_pb = require("Activity2_pb")
        local msg = Activity2_pb.HPChatSkinBuy();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)

        if msg.skinId > 0 then
            hasNewChatSkin = true
            NodeHelper:mainFrameSetPointVisible( { mChatPoint = true, })
            PageManager.refreshPage("ChatPage", "HasNewSkin")
        end
    end
end
PackageLogicForLua.HPonChatSkinBuy = PacketScriptHandler:new(HP_pb.CHAT_SKIN_BUY_S, PackageLogicForLua.onChatSkinBuy)

------------跨天通知
function PackageLogicForLua.onCrossDayNotice(eventName, handler)
    if eventName == "luaReceivePacket" then
        local alliance = require('Alliance_pb')
        local msg = alliance.HPAllianceEnterC()
        local pb = msg:SerializeToString()
        GVGManager.needCheckGuildPoint = true
        PacketManager:getInstance():sendPakcet(HP_pb.ALLIANCE_ENTER_C, pb, #pb, false)
    end
end
PackageLogicForLua.HPCrossDayNotice = PacketScriptHandler:new(HP_pb.FIRST_LOGIN_POINT_PUSH_S, PackageLogicForLua.onCrossDayNotice)

-- 商店推送红点
function PackageLogicForLua.showRedPoint(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Shop_pb.PushShopRedPoint();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        GameConfig.shopRedPoint = msg.showRedPoint
    end
end
PackageLogicForLua.HPCshowRedPoint = PacketScriptHandler:new(HP_pb.SHOP_RED_POINT_S, PackageLogicForLua.showRedPoint)


function PackageLogicForLua.onRolePanelInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        local mercenaryInfos = msg.roleInfos
        if mercenaryInfos ~= nil then
            local UserMercenaryManager = require("UserMercenaryManager")
            UserMercenaryManager:setMercenaryStatusInfos(mercenaryInfos)
            UserEquipManager:checkAllEquipNotice()
            require("EquipLeadPage")
            local pageIds = {
                RedPointManager.PAGE_IDS.CHAR_LEVELUP_BTN, RedPointManager.PAGE_IDS.CHAR_RARITYUP_BTN, RedPointManager.PAGE_IDS.CHAR_EQUIP1_SLOT,
                RedPointManager.PAGE_IDS.CHAR_EQUIP2_SLOT, RedPointManager.PAGE_IDS.CHAR_EQUIP3_SLOT, RedPointManager.PAGE_IDS.CHAR_EQUIP4_SLOT,
                RedPointManager.PAGE_IDS.CHAR_AW_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT, 
                RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT,
            }
            local ALFManager = require("Util.AsyncLoadFileManager")
            for k, pageId in pairs(pageIds) do
                local RedPointCfg = ConfigManager.getRedPointSetting()
                local groupNum = RedPointCfg[pageId].groupNum
                for i = 1, groupNum do    -- 24隻忍娘
                    local fn = function()
                        RedPointManager_refreshPageShowPoint(pageId, i)
                    end
                    ALFManager:loadRedPointTask(fn, pageId * 100 + i)
                end
            end
            local pageIds = { RedPointManager.PAGE_IDS.HERO_FETTER_BTN }
            for k, pageId in pairs(pageIds) do
                local RedPointCfg = ConfigManager.getRedPointSetting()
                local groupNum = RedPointCfg[pageId].groupNum
                for i = 1, groupNum do    -- 6組羈絆
                    local fn = function()
                        RedPointManager_refreshPageShowPoint(pageId, i)
                    end
                    ALFManager:loadRedPointTask(fn, pageId * 100 + i)
                end
            end
        end
        if loadingOpcodes[HP_pb.ROLE_PANEL_INFOS_S].done == false then loadingOpcodes[HP_pb.ROLE_PANEL_INFOS_S].done = true end
        --checkAndCloseMainSceneLoadingEnd()
    end
end
PackageLogicForLua.HPRolePanelInof = PacketScriptHandler:new(HP_pb.ROLE_PANEL_INFOS_S, PackageLogicForLua.onRolePanelInfo)

function PackageLogicForLua.onRoleEmployDone(eventName, handler)
    if eventName == "luaReceivePacket" then
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    end
end
PackageLogicForLua.HPRoleEmployDone = PacketScriptHandler:new(HP_pb.ROLE_EMPLOY_S, PackageLogicForLua.onRoleEmployDone)

-- 同步单个副将状态  服务器下发
function PackageLogicForLua.onRolePanelInfoSingle(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = RoleOpr_pb.HPRoleInfo();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg then
            local UserMercenaryManager = require("UserMercenaryManager")
            UserMercenaryManager:updateMercenaryStatusInfos(msg)

            if msg.roleStage == Const_pb.CAN_ACTIVITE and not employRoleIds[msg.roleId] then
                local msgEmploy = RoleOpr_pb.HPRoleEmploy()
                msgEmploy.roleId = msg.roleId
                local pb = msg:SerializeToString()
                PacketManager:getInstance():sendPakcet(HP_pb.ROLE_EMPLOY_C, pb, #pb, true)
                employRoleIds[msg.roleId] = true
            end
        end
    end
end
PackageLogicForLua.HPonRolePanelInfoSingle = PacketScriptHandler:new(HP_pb.SOULCOUNT_INFO_SYNC_S, PackageLogicForLua.onRolePanelInfoSingle)




-- Test
function PackageLogicForLua.onSevenDay(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = SevenDayQuest_pb.SyncQuestItemInfo()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg.items ~= nil then
            for i = 1, #msg.items do
                if msg.items[i].state == 2 then
                    local mData = ConfigManager.getSevenDayQuestData()
                    if curLoginDay == 0 then
                        if not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.SEVENDAY_QUEST) then
                            local msg = SevenDayQuest_pb.SevenDayQuestReq()
                            common:sendPacket(Hp_pb.SEVENDAY_QUEST_INFO_C, msg, false)
                        end
                        break
                    else
                        if mData[msg.items[i].questId].day <= curLoginDay then
                            ActivityInfo.NoticeInfo.NewPlayerLevel9Ids = ActivityInfo.NoticeInfo.NewPlayerLevel9Ids or { }
                            if ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[Const_pb.ACCUMULATIVE_LOGIN_SEVEN] == nil then
                                ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[Const_pb.ACCUMULATIVE_LOGIN_SEVEN] = true
                                PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end
PackageLogicForLua.HPSevenDay = PacketScriptHandler:new(HP_pb.SEVENDAY_QUEST_STATUS_UPDATE, PackageLogicForLua.onSevenDay)

function PackageLogicForLua.onSevenDayInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = SevenDayQuest_pb.SevenDayQuestRep()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        if msg ~= nil then
            if curLoginDay == 0 then
                curLoginDay = msg.registerDay
                for i = 1, #msg.allQuest do
                    if msg.allQuest[i].state == 2 then
                        local mData = ConfigManager.getSevenDayQuestData()
                        if mData[msg.allQuest[i].questId].day <= curLoginDay then
                            ActivityInfo.NoticeInfo.NewPlayerLevel9Ids = ActivityInfo.NoticeInfo.NewPlayerLevel9Ids or { }
                            if ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[Const_pb.ACCUMULATIVE_LOGIN_SEVEN] == nil then
                                ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[Const_pb.ACCUMULATIVE_LOGIN_SEVEN] = true
                                PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end
PackageLogicForLua.HPSevenDayInfo = PacketScriptHandler:new(HP_pb.SEVENDAY_QUEST_INFO_S, PackageLogicForLua.onSevenDayInfo)



---------------------------------------------------------------------------------
function PackageLogicForLua.onIsShowLottery(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity3_pb = require("Activity3_pb")
        local msg = Activity3_pb.Activity124InfoRep();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)

        UserInfo.isUseLottery = msg.isUsed

        UserInfo.isLuckDraw_124 = msg.count == 0

        PageManager.refreshPage("MainScenePage", "isShowLotteryIcon")
    end
end
PackageLogicForLua.HPonIsShowLottery = PacketScriptHandler:new(HP_pb.ACTIVITY124_RECHARGE_RETURN_INFO_S, PackageLogicForLua.onIsShowLottery)


---------------------------------------------------------------------------------
-- 134活动info  服务器主动下发
function PackageLogicForLua.onActivity_134_Info(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity4_pb = require("Activity4_pb")
        local msg = Activity4_pb.Activity134WeekendGiftInfoRes()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)

        UserInfo.isShowActivity134Icon = false
        if msg.activityLefttime > 0 then
            UserInfo.isShowActivity134Icon = true
        elseif msg.preOpenTime > 0 then
            UserInfo.isShowActivity134Icon = true
        end
        -- UserInfo.isShowActivity134Icon = msg.activityLefttime > 0 or msg.preOpenTime > 0

        PageManager.refreshPage("MainScenePage", "isShowActivity134Icon")
    end
end
PackageLogicForLua.HPonActivity_134_Info = PacketScriptHandler:new(HP_pb.ACTIVITY134_WEEKEND_GIFT_INFO_S, PackageLogicForLua.onActivity_134_Info)

----------------------------------------------------------------------------------
-- 活动132info数据  主界面请求， 这里接收处理
function PackageLogicForLua.onActivity_132_Info(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity4_pb = require("Activity4_pb")
        local msg = Activity4_pb.Activity132LevelGiftInfoRes();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        require("ActPopUpSale.ActPopUpSaleSubPage_132")
        ActPopUpSaleSubPage_132_setServerData(msg)
        PageManager.refreshPage("MainScenePage", "isShowActivity132Icon")
    end
end
PackageLogicForLua.HPonActivity_132_Info = PacketScriptHandler:new(HP_pb.ACTIVITY132_LEVEL_GIFT_INFO_S, PackageLogicForLua.onActivity_132_Info)

-- 活动151info数据  主界面请求， 这里接收处理
function PackageLogicForLua.onActivity_151_Info(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity4_pb = require("Activity4_pb")
        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        require("ActPopUpSale.ActPopUpSaleSubPage_151")
        ActPopUpSaleSubPage_151_setServerData(msg)

        PageManager.refreshPage("MainScenePage", "isShowActivity151Icon")
    end
end
PackageLogicForLua.HPonActivity_151_Info = PacketScriptHandler:new(HP_pb.ACTIVITY151_STAGE_GIFT_INFO_S, PackageLogicForLua.onActivity_151_Info)

-- 活动169info数据  主界面请求， 这里接收处理
--function PackageLogicForLua.onActivity_169_Info(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local Activity4_pb = require("Activity4_pb")
--        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
--        local msgbuff = handler:getRecPacketBuffer();
--        msg:ParseFromString(msgbuff)
--        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
--        ActPopUpSaleSubPage_setActId(169)
--        ActPopUpSaleSubPage_Content_setServerData(msg)
--        PageManager.refreshPage("MainScenePage", "isShowActivity169Icon")
--    end
--end
--PackageLogicForLua.HPonActivity_169_Info = PacketScriptHandler:new(HP_pb.ACTIVITY169_ACTIVITY_GIFT_INFO_S, PackageLogicForLua.onActivity_169_Info)
--
---- 活动170info数据  主界面请求， 这里接收处理
--function PackageLogicForLua.onActivity_170_Info(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local Activity4_pb = require("Activity4_pb")
--        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
--        local msgbuff = handler:getRecPacketBuffer();
--        msg:ParseFromString(msgbuff)
--        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
--        ActPopUpSaleSubPage_setActId(170)
--        ActPopUpSaleSubPage_Content_setServerData(msg)
--        PageManager.refreshPage("MainScenePage", "isShowActivity170Icon")
--    end
--end
--PackageLogicForLua.HPonActivity_170_Info = PacketScriptHandler:new(HP_pb.ACTIVITY170_ACTIVITY_GIFT_INFO_S, PackageLogicForLua.onActivity_170_Info)

-- 活动177info数据  主界面请求， 这里接收处理
function PackageLogicForLua.onActivity_177_Info(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity5_pb = require("Activity5_pb")
        local msg = Activity5_pb.Activity177FailedGiftResp(); -- 與132共用
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        require("ActPopUpSale.ActPopUpSaleSubPage_177")
        ActPopUpSaleSubPage_177_setServerData(msg)
        PageManager.refreshPage("MainScenePage", "isShowActivity177Icon")
    end
end
PackageLogicForLua.HPonActivity_177_Info = PacketScriptHandler:new(HP_pb.ACTIVITY177_FAILED_GIFT_S, PackageLogicForLua.onActivity_177_Info)

-- 活动181info数据  主界面请求， 这里接收处理
--function PackageLogicForLua.onActivity_181_Info(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local Activity4_pb = require("Activity4_pb")
--        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
--        local msgbuff = handler:getRecPacketBuffer();
--        msg:ParseFromString(msgbuff)
--        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
--        ActPopUpSaleSubPage_setActId(181)
--        ActPopUpSaleSubPage_Content_setServerData(msg)
--        PageManager.refreshPage("MainScenePage", "isShowActivity181Icon")
--    end
--end
--PackageLogicForLua.HPonActivity_181_Info = PacketScriptHandler:new(HP_pb.ACTIVITY181_ACTIVITY_GIFT_INFO_S, PackageLogicForLua.onActivity_181_Info)
--
---- 活动182info数据  主界面请求， 这里接收处理
--function PackageLogicForLua.onActivity_182_Info(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local Activity4_pb = require("Activity4_pb")
--        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
--        local msgbuff = handler:getRecPacketBuffer();
--        msg:ParseFromString(msgbuff)
--        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
--        ActPopUpSaleSubPage_setActId(182)
--        ActPopUpSaleSubPage_Content_setServerData(msg)
--        PageManager.refreshPage("MainScenePage", "isShowActivity182Icon")
--    end
--end
--PackageLogicForLua.HPonActivity_182_Info = PacketScriptHandler:new(HP_pb.ACTIVITY182_ACTIVITY_GIFT_INFO_S, PackageLogicForLua.onActivity_182_Info)
--
---- 活动183info数据  主界面请求， 这里接收处理
--function PackageLogicForLua.onActivity_183_Info(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local Activity4_pb = require("Activity4_pb")
--        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
--        local msgbuff = handler:getRecPacketBuffer();
--        msg:ParseFromString(msgbuff)
--        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
--        ActPopUpSaleSubPage_setActId(183)
--        ActPopUpSaleSubPage_Content_setServerData(msg)
--        PageManager.refreshPage("MainScenePage", "isShowActivity183Icon")
--    end
--end
--PackageLogicForLua.HPonActivity_183_Info = PacketScriptHandler:new(HP_pb.ACTIVITY183_ACTIVITY_GIFT_INFO_S, PackageLogicForLua.onActivity_183_Info)
--
---- 活动184info数据  主界面请求， 这里接收处理
--function PackageLogicForLua.onActivity_184_Info(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local Activity4_pb = require("Activity4_pb")
--        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
--        local msgbuff = handler:getRecPacketBuffer();
--        msg:ParseFromString(msgbuff)
--        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
--        ActPopUpSaleSubPage_setActId(184)
--        ActPopUpSaleSubPage_Content_setServerData(msg)
--        PageManager.refreshPage("MainScenePage", "isShowActivity184Icon")
--    end
--end
--PackageLogicForLua.HPonActivity_184_Info = PacketScriptHandler:new(HP_pb.ACTIVITY184_ACTIVITY_GIFT_INFO_S, PackageLogicForLua.onActivity_184_Info)
--
---- 活动185info数据  主界面请求， 这里接收处理
--function PackageLogicForLua.onActivity_185_Info(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local Activity4_pb = require("Activity4_pb")
--        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
--        local msgbuff = handler:getRecPacketBuffer();
--        msg:ParseFromString(msgbuff)
--        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
--        ActPopUpSaleSubPage_setActId(185)
--        ActPopUpSaleSubPage_Content_setServerData(msg)
--        PageManager.refreshPage("MainScenePage", "isShowActivity185Icon")
--    end
--end
--PackageLogicForLua.HPonActivity_185_Info = PacketScriptHandler:new(HP_pb.ACTIVITY185_ACTIVITY_GIFT_INFO_S, PackageLogicForLua.onActivity_185_Info)
--
---- 活动186info数据  主界面请求， 这里接收处理
--function PackageLogicForLua.onActivity_186_Info(eventName, handler)
--    if eventName == "luaReceivePacket" then
--        local Activity4_pb = require("Activity4_pb")
--        local msg = Activity4_pb.Activity132LevelGiftInfoRes(); -- 與132共用
--        local msgbuff = handler:getRecPacketBuffer();
--        msg:ParseFromString(msgbuff)
--        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
--        ActPopUpSaleSubPage_setActId(186)
--        ActPopUpSaleSubPage_Content_setServerData(msg)
--        PageManager.refreshPage("MainScenePage", "isShowActivity186Icon")
--    end
--end
--PackageLogicForLua.HPonActivity_186_Info = PacketScriptHandler:new(HP_pb.ACTIVITY186_ACTIVITY_GIFT_INFO_S, PackageLogicForLua.onActivity_186_Info)

-- 活动187info数据  主界面请求， 这里接收处理
function PackageLogicForLua.onActivity_187_Info(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity5_pb = require("Activity5_pb")
        local msg = Activity5_pb.MaxJumpGiftResp();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
        ActPopUpSaleSubPage_Content_setServerData(msg)
        PageManager.refreshPage("MainScenePage", "isShowActivity187Icon")
    end
end
PackageLogicForLua.HPonActivity_187_Info = PacketScriptHandler:new(HP_pb.ACTIVITY187_MAXJUMP_GIFT_S, PackageLogicForLua.onActivity_187_Info)

-- Flag数据  主界面请求， 这里接收处理
function PackageLogicForLua.OnGetFlag(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Sign_pb=require("Sign_pb")
        local msg = Sign_pb.SignRespones()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        require("FlagData")
        FlagDataBase_SetStatus(msg)
        local currPage = MainFrame:getInstance():getCurShowPageName()
        if currPage == "NgBattlePage" then
            require("Battle.NgBattlePage")
            NgBattlePageInfo:setUIType(NgBattleDataManager.battlePageContainer)
        end
    end
end
PackageLogicForLua.OnGetFlag = PacketScriptHandler:new(HP_pb.SIGN_SYNC_S, PackageLogicForLua.OnGetFlag)
----------------------------------------------------------------------------------
-- 在线奖励info数据
function PackageLogicForLua.onActivity_133_Info(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity4_pb = require("Activity4_pb")
        local msg = Activity4_pb.Activity132LevelGiftInfoRes();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        require("ActTimeLimit_133")
        ActTimeLimit_133_setServerData(msg)
        PageManager.refreshPage("MainScenePage", "isShowActivity133Icon")
    end
end
PackageLogicForLua.HPonActivity_133_Info = PacketScriptHandler:new(HP_pb.ACTIVITY133_ONLINE_GIFT_INFO_S, PackageLogicForLua.onActivity_133_Info)

---------------------------------------------------------------------------------


-- 活动137
function PackageLogicForLua.onActivity_137_Info(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity4_pb = require("Activity4_pb")
        local msg = Activity4_pb.Activity137InfoRep();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        require("ActTimeLimit_137")
        ActTimeLimit_137_setServerData(msg)
        PageManager.refreshPage("MainScenePage", "isShowActivity137Icon")
    end
end
PackageLogicForLua.HPonActivity_137_Info = PacketScriptHandler:new(HP_pb.ACTIVITY137_SLOT_RETURN_INFO_S, PackageLogicForLua.onActivity_137_Info)


----------------------------------------------------------------------------------

-- 活动140
function PackageLogicForLua.onActivity_140_Info(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity3_pb = require("Activity3_pb")
        local msg = Activity3_pb.Activity140InfoRep();
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        require("ActTimeLimit_140")
        ActTimeLimit_140_setServerData(msg)
        PageManager.refreshPage("MainScenePage", "isShowActivity140Icon")
    end
end
PackageLogicForLua.HPonActivity_140_Info = PacketScriptHandler:new(HP_pb.ACTIVITY140_DISHWHEEL_INFO_S, PackageLogicForLua.onActivity_140_Info)


----------------------------------------------------------------------------------

-- 注册天数
function PackageLogicForLua.onRegistDay(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Player_pb.HPPlayerRegisterDay()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        registDay = msg.registerDay
    end
end
PackageLogicForLua.HPonRegistDay = PacketScriptHandler:new(HP_pb.PLAYER_REGISTERDAY_S, PackageLogicForLua.onRegistDay)




-- 十八路诸侯
function PackageLogicForLua.onPlayerHelpMercenary(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = EighteenPrinces_pb.HPPlayerHelpMercenaryRet()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        local HelpFightDataManager = require("PVP.HelpFightDataManager")
        HelpFightDataManager.myHelpMercenary = msg.helpMercenary
        PageManager.refreshPage("PVPActivityPage", "refreshHelpFightIcon");
    end
end
PackageLogicForLua.HPonPlayerHelpMercenary = PacketScriptHandler:new(HP_pb.EIGHTEENPRINCES_HELPMERCENARY_S, PackageLogicForLua.onPlayerHelpMercenary)



-- 十八路诸侯药品返回
function PackageLogicForLua.onHelpFightMedicalFun(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = EighteenPrinces_pb.HPSyncMedicalKitInfoRet()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        local HelpFightDataManager = require("PVP.HelpFightDataManager")
        HelpFightDataManager.myMedicalItem = msg.item
    end
end
PackageLogicForLua.HPonHelpFightMedicalFun = PacketScriptHandler:new(HP_pb.EIGHTEENPRINCES_MEDICALKIT_S, PackageLogicForLua.onHelpFightMedicalFun)

-- 十八路诸侯挑战
function PackageLogicForLua.onHelpFightChallengeFun(eventName, handler)
    if eventName == "luaReceivePacket" then
    end
end
PackageLogicForLua.HPonHelpFightChallengeFun = PacketScriptHandler:new(HP_pb.EIGHTEENPRINCES_CHALLENGE_S, PackageLogicForLua.onHelpFightChallengeFun)

-- 十八路诸侯挑战红点提示
function PackageLogicForLua.onHelpFightRewardNoticeFun(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = EighteenPrinces_pb.HPEighteenPrincesRewardNotice()
        local msgbuff = handler:getRecPacketBuffer();
        msg:ParseFromString(msgbuff)
        local HelpFightDataManager = require("PVP.HelpFightDataManager")
        HelpFightDataManager.isNotice = true
        NoticePointState.isChange = true
    end
end
PackageLogicForLua.HPonHelpFightRewardNoticeFun = PacketScriptHandler:new(HP_pb.EIGHTEENPRINCES_HELPREWARDNOTICE_S, PackageLogicForLua.onHelpFightRewardNoticeFun)

-----------------------------------------------------------------------------------------------------------------------------------------------------
--猎命系统详情
function PackageLogicForLua.FateHuntingInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local MysticalDress_pb = require("Badge_pb")
       	local msg = MysticalDress_pb.HPMysticalHunting();
	   	local msgbuff = handler:getRecPacketBuffer();
	   	msg:ParseFromString(msgbuff)
		local FateDataManager = require("FateDataManager")
	  	FateDataManager:setHuntingInfo(msg)
    end
end
--PackageLogicForLua.HPFateHuntingInfo = PacketScriptHandler:new(HP_pb.MYSTICAL_HUNTING_INFO_S, PackageLogicForLua.FateHuntingInfo)

--命格信息同步
function PackageLogicForLua.FateDataInfoSyn(eventName, handler)
    if eventName == "luaReceivePacket" then
        local MysticalDress_pb = require("Badge_pb")
       	local msg = MysticalDress_pb.HPMysticalDressInfoSync();
	   	local msgbuff = handler:getRecPacketBuffer();
	   	msg:ParseFromString(msgbuff)
		local FateDataManager = require("FateDataManager")
	  	FateDataManager:syncFateDatas(msg)

        require("EquipLeadPage")
        local pageIds = {
            RedPointManager.PAGE_IDS.CHAR_RUNE1_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE2_SLOT, 
            RedPointManager.PAGE_IDS.CHAR_RUNE3_SLOT, RedPointManager.PAGE_IDS.CHAR_RUNE4_SLOT,
        }
        local ALFManager = require("Util.AsyncLoadFileManager")
        for k, pageId in pairs(pageIds) do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            local fn = function()
                for i = 1, groupNum do    -- 24隻忍娘
                    RedPointManager_refreshPageShowPoint(pageId, i)
                    RedPointManager_setPageSyncDone(pageId, i)
                end
            end
            ALFManager:loadRedPointTask(fn, pageId * 100)
        end
    end
end
PackageLogicForLua.HPFateDataInfoSyn = PacketScriptHandler:new(HP_pb.BADGE_INFO_SYNC_S, PackageLogicForLua.FateDataInfoSyn)

--命格删除同步
function PackageLogicForLua.FateDataDeleteInfoSyn(eventName, handler)
    if eventName == "luaReceivePacket" then
        local MysticalDress_pb = require("Badge_pb")
       	local msg = MysticalDress_pb.HPMysticalDressRemoveInfoSync();
	   	local msgbuff = handler:getRecPacketBuffer();
	   	msg:ParseFromString(msgbuff)
		local FateDataManager = require("FateDataManager")
	  	FateDataManager:deleteDateDatas(msg)
    end
end
--删除消息号
PackageLogicForLua.HPFateDataDeleteInfoSyn = PacketScriptHandler:new(HP_pb.BADGE_REMOVE_SYNC_S, PackageLogicForLua.FateDataDeleteInfoSyn)

function PackageLogicForLua.GloryHoleInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Activity5_pb = require("Activity5_pb")
        local msg=Activity5_pb.GloryHoleResp()
	   	local msgbuff = handler:getRecPacketBuffer();
	   	msg:ParseFromString(msgbuff)
	    require("GloryHole.GloryHolePageData")
        GloryHoleBase_SetInfo(msg)

        if msg.action == 0 then 
            PageManager.pushPage("GloryHole.GloryHolePage")
        end
        if msg.action == 1 then
            require("GloryHole.GloryHoleSubPage_TeamRank")
            require("GloryHole.GloryHoleSubPage_DailyRank")
            require("GloryHole.GloryHoleSubPage_HistoryRank")
            GloryHoleTeamRank_refresh()
            GloryHoleDailyRank_refresh()
            GloryHoleHistoryRank_refresh()
        end
    end
end
PackageLogicForLua.HPGloryHoleInfo = PacketScriptHandler:new(HP_pb.ACTIVITY175_GLORY_HOLE_S, PackageLogicForLua.GloryHoleInfo)
function PackageLogicForLua.RankRewardInfo(eventName, handler)
    if eventName == "luaReceivePacket" then
         local RankRewardData=require("Ranking.ProfessionRankingRewardData")
         local msg = Activity4_pb.RankGiftRes()
         local msgbuff = handler:getRecPacketBuffer();
         msg:ParseFromString(msgbuff)
         RankRewardData:setData(msg)

         local GetRewards=""
         if msg:HasField("reward") then
            GetRewards=msg.reward
            local rewardItems={}
            for _,reward in pairs (common:split(GetRewards,",")) do
                local _type, _id, _count = unpack(common:split(reward, "_"));
                table.insert(rewardItems, {
                      type    = tonumber(_type),
                      itemId  = tonumber(_id),
                      count   = tonumber(_count),
                      });
            end
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            CommonRewardPage:setData(rewardItems, common:getLanguageString("@ItemObtainded"), nil)
            PageManager.pushPage("CommPop.CommItemReceivePage")
        end
    end
end
PackageLogicForLua.HPRankRewardInfo = PacketScriptHandler:new(HP_pb.ACTIVITY153_S, PackageLogicForLua.RankRewardInfo)
function PackageLogicForLua.getHoneyP(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Shop_pb.HoneyPResponse()
        local msgbuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        local HoneyP = msg.coins
        libPlatformManager:getPlatform():setHoneyP(HoneyP)
        CCLuaLog("getHoneyP : " .. HoneyP)
    end
end
PackageLogicForLua.HPgetHoneyP = PacketScriptHandler:new(HP_pb.SHOP_HONEYP_S, PackageLogicForLua.getHoneyP)
function PackageLogicForLua.r18BuyResult(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Shop_pb.HoneyPBuyResponse()
        local msgbuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        local reslut = msg.result
        local refno = msg.refno
        CCLuaLog("r18BuyResult result : " .. reslut .. ", orderId : " .. refno)
        local BuyManager = require("BuyManager")
        CCLuaLog("PackageLogicForLua SendtogetHoneyP")
        BuyManager:SendtogetHoneyP()
        local msg2 = MsgRechargeSuccess:new()
	    MessageManager:getInstance():sendMessageForScript(msg2)
        if reslut == 0 then
            MessageBoxPage:Msg_Box_Lan("@BuyFailed")
        else
            if Golb_Platform_Info.is_r18 then
                AdjustManager:onTrackRevenueEvent("z8ak7i", msg.costmoney or 0)
            end
        end
    end
end
PackageLogicForLua.HPr18BuyResult = PacketScriptHandler:new(HP_pb.SHOP_HONEYP_BUY_S, PackageLogicForLua.r18BuyResult)
function PackageLogicForLua.r18BoundSuccess(eventName, handler)
    if eventName == "luaReceivePacket" then
        local BuyManager = require("BuyManager")
        BuyManager:onReceiveBoundAccount()
    end
end
PackageLogicForLua.HPr18BoundSuccess = PacketScriptHandler:new(HP_pb.ACCOUNT_BOUND_REWARD_S, PackageLogicForLua.r18BoundSuccess)

function PackageLogicForLua.RecyleStageQuest(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Activity5_pb.CycleStageResp()
        msg:ParseFromString(msgBuff)
        local Event001Base = require "Event001Page"
        Event001Base:SetQuestInfo(msg)
    end
end
PackageLogicForLua.HPRecyleStageQuest = PacketScriptHandler:new(HP_pb.ACTIVITY191_CYCLE_STAGE_S, PackageLogicForLua.RecyleStageQuest)

function PackageLogicForLua.Recyle2StageQuest(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Activity5_pb.CycleStageResp()
        msg:ParseFromString(msgBuff)
        local Event001Base = require "Event001Page"
        Event001Base:SetQuestInfo(msg)
    end
end
PackageLogicForLua.HPRecyle2StageQuest = PacketScriptHandler:new(HP_pb.ACTIVITY196_CYCLE_STAGE_S, PackageLogicForLua.Recyle2StageQuest)

function PackageLogicForLua.RecyleStage(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Dungeon_pb= require("Dungeon_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Dungeon_pb.HPCycleStageInfo()
        msg:ParseFromString(msgBuff)
        local Event001Base = require "Event001Page"
        Event001Base:SetStageInfo(msg)
        local Event001Battle = require "Event001BattlePage"
        Event001Battle:SetStageInfo(msg)
        if msg.leftTime <86400 then
            MainScenePage.setActivityTime(msg.leftTime)
        end

    end
end
PackageLogicForLua.HPRecyleStage = PacketScriptHandler:new(HP_pb.CYCLE_LIST_INFO_S, PackageLogicForLua.RecyleStage)

function PackageLogicForLua.KusoPayResult(eventName, handler)
    if eventName == "luaReceivePacket" then
        local Shop_pb = require("Shop_pb")
        local msgBuff = handler:getRecPacketBuffer()
        local msg = Shop_pb.SixNineTakeResponse()
        msg:ParseFromString(msgBuff)
        local reslut = msg.result

        if reslut == 0 then
            MessageBoxPage:Msg_Box_Lan("@BuyFailed")
        else
            local msg2 = MsgRechargeSuccess:new()
            MessageManager:getInstance():sendMessageForScript(msg2)
        end
    end
end
PackageLogicForLua.HPKusoPayResult = PacketScriptHandler:new(HP_pb.SHOP_69COIN_TAKE_S, PackageLogicForLua.KusoPayResult)

function PackageLogicForLua.TowerData(eventName, handler)
    if eventName == "luaReceivePacket" then
       local Activity6_pb = require("Activity6_pb")
       local msgBuff = handler:getRecPacketBuffer()
       local msg = Activity6_pb.SeasonTowerResp()
       msg:ParseFromString(msgBuff)
       require "Tower.TowerPageData"
       TowerBase_SetInfo(msg)
       require "Tower.TowerSubPage_Rank"
       TowerRank_refresh()
       --if msg.action == 0 then
       --   PageManager.pushPage("Tower.TowerPage")
       --end
    end
end
PackageLogicForLua.HPTowerData = PacketScriptHandler:new(HP_pb.ACTIVITY194_SEASON_TOWER_S, PackageLogicForLua.TowerData)

function PackageLogicForLua.PickUpData(eventName, handler)
    if eventName == "luaReceivePacket" then
       local Activity6_pb = require("Activity6_pb")
       local msgBuff = handler:getRecPacketBuffer()
       local msg = Activity6_pb.SuperPickUpList()
       msg:ParseFromString(msgBuff)
       require ("Summon.SummonPickUpData")
       SummonPickUpDataBase_SetInfo(msg)

       local transPage = require("TransScenePopUp")
       TransScenePopUp_setCallbackFun(function()
           local GuideManager = require("Guide.GuideManager")
           if GuideManager.isInGuide then
               require("Summon.SummonPage"):setEntrySubPage("Premium")
           end
           PageManager.pushPage("Summon.SummonPage")
       end)
       setCCBMenuAnimation("mBackpackPageBtn", "Normal")
       UserInfo.sync()
       PageManager.pushPage("TransScenePopUp")
    end
end
PackageLogicForLua.PickUpData = PacketScriptHandler:new(HP_pb.ACTIVITY197_SUPER_PICKUP_INFO_S, PackageLogicForLua.PickUpData)


-----------JGG get order handler------------
--[[
function PackageLogicForLua.onJggGetOrder(eventName, handler)
	CCLuaLog("onJggGetOrder")
    if eventName == "luaReceivePacket" then
        local Shop_pb = require("Shop_pb")
        local msg = Shop_pb.JggOrderNotice();
        local msgbuff = handler:getRecPacketBuffer()
        msg:ParseFromString(msgbuff)
        if msg.orderid and msg.status == 0 then --未確認
            jggOrderId = msg.orderid
        elseif msg.orderid and msg.status == 1 then --已完成
            jggOrderId = nil
            jggOrderCount = 0
        elseif msg.orderid and msg.status == 2 then --重複確認
            jggOrderId = msg.orderid
        elseif msg.orderid and msg.status == 3 then --已清除
            jggOrderId = nil
            jggOrderCount = 0
        end
        jggTimer = 0
    end
end
PackageLogicForLua.HPJggGetOrder = PacketScriptHandler:new(HP_pb.SHOP_JGG_ORDER_S, PackageLogicForLua.onJggGetOrder);]]--
-----------------------------------------------------------------------------------------------------------------------------------------------------



-- 注意--;
-- 每次加一个全局的长监听函数，需要在这里面加入一个registerFunctionHandler function
-- 用于function失效后，校验并重注册使用
function validateAndRegisterAllHandler()

    --PackageLogicForLua.HPFateHuntingInfo:registerFunctionHandler(PackageLogicForLua.FateHuntingInfo)
    PackageLogicForLua.HPFateDataInfoSyn:registerFunctionHandler(PackageLogicForLua.FateDataInfoSyn)
    PackageLogicForLua.HPFateDataDeleteInfoSyn:registerFunctionHandler(PackageLogicForLua.FateDataDeleteInfoSyn)
    PackageLogicForLua.HPGloryHoleInfo:registerFunctionHandler(PackageLogicForLua.GloryHoleInfo)
    PackageLogicForLua.HPRankRewardInfo:registerFunctionHandler(PackageLogicForLua.RankRewardInfo)

    PackageLogicForLua.HPonIsShowLottery:registerFunctionHandler(PackageLogicForLua.onIsShowLottery)
    PackageLogicForLua.HPonActivity_132_Info:registerFunctionHandler(PackageLogicForLua.onActivity_132_Info)
    PackageLogicForLua.HPonActivity_151_Info:registerFunctionHandler(PackageLogicForLua.onActivity_151_Info)
    --PackageLogicForLua.HPonActivity_169_Info:registerFunctionHandler(PackageLogicForLua.onActivity_169_Info)
    --PackageLogicForLua.HPonActivity_170_Info:registerFunctionHandler(PackageLogicForLua.onActivity_170_Info)
    --PackageLogicForLua.HPonActivity_181_Info:registerFunctionHandler(PackageLogicForLua.onActivity_181_Info)
    --PackageLogicForLua.HPonActivity_182_Info:registerFunctionHandler(PackageLogicForLua.onActivity_182_Info)
    --PackageLogicForLua.HPonActivity_183_Info:registerFunctionHandler(PackageLogicForLua.onActivity_183_Info)
    --PackageLogicForLua.HPonActivity_184_Info:registerFunctionHandler(PackageLogicForLua.onActivity_184_Info)
    --PackageLogicForLua.HPonActivity_185_Info:registerFunctionHandler(PackageLogicForLua.onActivity_185_Info)
    --PackageLogicForLua.HPonActivity_186_Info:registerFunctionHandler(PackageLogicForLua.onActivity_186_Info)
    PackageLogicForLua.HPonActivity_187_Info:registerFunctionHandler(PackageLogicForLua.onActivity_187_Info)
    PackageLogicForLua.HPonActivity_177_Info:registerFunctionHandler(PackageLogicForLua.onActivity_177_Info)
    PackageLogicForLua.OnGetFlag:registerFunctionHandler(PackageLogicForLua.OnGetFlag)
    -- PackageLogicForLua.HPonActivity_133_Info:registerFunctionHandler(PackageLogicForLua.onActivity_133_Info)
    PackageLogicForLua.HPonActivity_134_Info:registerFunctionHandler(PackageLogicForLua.onActivity_134_Info)

    PackageLogicForLua.HPonActivity_137_Info:registerFunctionHandler(PackageLogicForLua.onActivity_137_Info)

    PackageLogicForLua.HPonActivity_140_Info:registerFunctionHandler(PackageLogicForLua.onActivity_140_Info)

    -- 添加单个副将信息同步监听 服务器主动下发
    PackageLogicForLua.HPonRolePanelInfoSingle:registerFunctionHandler(PackageLogicForLua.onRolePanelInfoSingle)

    PackageLogicForLua.onMultiNoticeListener:registerFunctionHandler(PackageLogicForLua.onMultiNotice)
    PackageLogicForLua.onMultiInviteListener:registerFunctionHandler(PackageLogicForLua.onMultiInvite)
    PackageLogicForLua.HPonReceiveFormationInfoHandler:registerFunctionHandler(PackageLogicForLua.onReceiveFormationStatus)
    PackageLogicForLua.HPonReceiveMonthCardInfoHandler:registerFunctionHandler(PackageLogicForLua.onReceiveMonthCardInfoStatus)
    PackageLogicForLua.HPSkillEnhanceOpenState:registerFunctionHandler(PackageLogicForLua.onRecieveSEOpenInfo)
    PackageLogicForLua.HPStateInfoSyncHandler:registerFunctionHandler(PackageLogicForLua.onReceivePlayerStates)
    PackageLogicForLua.HPPlayStoryDoneSyncHandler:registerFunctionHandler(PackageLogicForLua.onReceivePlayStroyDone)
    PackageLogicForLua.HPAssemblyFinishHandler:registerFunctionHandler(PackageLogicForLua.onReceiveAsemblyFinish)
    PackageLogicForLua.HPPlayerKickOutHandler:registerFunctionHandler(PackageLogicForLua.onPlayerKickOut)
    PackageLogicForLua.HPPushChatHandler:registerFunctionHandler(PackageLogicForLua.onReceiveChatMsg);
    -- PackageLogicForLua.HPMarketDropsHandler:registerFunctionHandler( PackageLogicForLua.onReceiveMarketDropsInfo);
    -- PackageLogicForLua.HPMarketCoinHandler:registerFunctionHandler(PackageLogicForLua.onReceiveMarketCoinsInfo);
    PackageLogicForLua.HPNoticePushHandler:registerFunctionHandler(PackageLogicForLua.onReceiveNoticePush);
    PackageLogicForLua.HPMailInfoHandler:registerFunctionHandler(PackageLogicForLua.onReceiveMailInfo);
    PackageLogicForLua.HPNewMsgHandler:registerFunctionHandler(PackageLogicForLua.onReceiveNewLeaveMessage)
    PackageLogicForLua.HPErrorCodeHandler:registerFunctionHandler(PackageLogicForLua.onReceiveErrorCode)
    PackageLogicForLua.HPMissionListHandler:registerFunctionHandler(PackageLogicForLua.onReceiveGiftPackage)
    PackageLogicForLua.HPAllianceEnterHandler:registerFunctionHandler(PackageLogicForLua.onReceiveAlliancePersonalInfo)
    PackageLogicForLua.HPAllianceCreateHandler:registerFunctionHandler(PackageLogicForLua.onReceiveAllianceInfo)
    PackageLogicForLua.HPEquipSyncFinish:registerFunctionHandler(PackageLogicForLua.onEquipSyncFinish);
    PackageLogicForLua.HPSyncEquipInfoHandler:registerFunctionHandler(PackageLogicForLua.onRecieveSyncEquip)
    PackageLogicForLua.HPSyncItemInfoHandler:registerFunctionHandler(PackageLogicForLua.onRecieveSyncItem)
    PackageLogicForLua.HPPlayerConsumeHandler:registerFunctionHandler(PackageLogicForLua.onRecievePlayerConsume)
    PackageLogicForLua.HPSeeOtherPlayerInfo:registerFunctionHandler(PackageLogicForLua.onRecieveSeeOtherPlayerInfo)
    PackageLogicForLua.HPSyncStarSoul:registerFunctionHandler(PackageLogicForLua.onRecieveSyncStarSoul)
    PackageLogicForLua.HPSyncLeaderStarSoul:registerFunctionHandler(PackageLogicForLua.onRecieveSyncLeaderStarSoul)
    PackageLogicForLua.HPSyncElementStarSoul:registerFunctionHandler(PackageLogicForLua.onRecieveSyncElementStarSoul)
    PackageLogicForLua.HPSyncClassStarSoul:registerFunctionHandler(PackageLogicForLua.onRecieveSyncClassStarSoul)
    PackageLogicForLua.HPSyncWishingWell:registerFunctionHandler(PackageLogicForLua.onRecieveSyncWishingWell)
    PackageLogicForLua.HPSyncSummonNormal:registerFunctionHandler(PackageLogicForLua.onRecieveSyncSummonNormal)
    PackageLogicForLua.HPSyncRoleInfoReward:registerFunctionHandler(PackageLogicForLua.onRecieveSyncRoleInfoReward)
    PackageLogicForLua.HPSyncCollection:registerFunctionHandler(PackageLogicForLua.onRecieveSyncCollection)
    PackageLogicForLua.HPSyncDungeon:registerFunctionHandler(PackageLogicForLua.onRecieveSyncDungeon)
    PackageLogicForLua.HPSyncShop:registerFunctionHandler(PackageLogicForLua.onRecieveSyncShop)
    PackageLogicForLua.HPSyncPackage:registerFunctionHandler(PackageLogicForLua.onRecieveSyncPackage)
    PackageLogicForLua.HPActiveStarSoulRet:registerFunctionHandler(PackageLogicForLua.onRecieveActiveStarSoulRet)
    PackageLogicForLua.HPListenEquipDress:registerFunctionHandler(PackageLogicForLua.onRecieveEquipDress)
    PackageLogicForLua.HPListenAllEquipDress:registerFunctionHandler(PackageLogicForLua.onRecieveAllEquipDress)
    PackageLogicForLua.HPListenAttrChange:registerFunctionHandler(PackageLogicForLua.onRecieveAttrChange)
    -- PackageLogicForLua.HPListenLogin:registerFunctionHandler(PackageLogicForLua.onRecieveLogin)
    PackageLogicForLua.HPMapStaticsSync:registerFunctionHandler(PackageLogicForLua.onReceiveMapStaticSync);
    PackageLogicForLua.HPOfflineMessageBox:registerFunctionHandler(PackageLogicForLua.onReceiveOfflineMessageBox);
    PackageLogicForLua.HPPrivateChatMsg:registerFunctionHandler(PackageLogicForLua.onReceivePrivateChatMsg);
    PackageLogicForLua.HPShieldPlayerList:registerFunctionHandler(PackageLogicForLua.onReceiveShieldPlayerList);
    PackageLogicForLua.HPRechargeNotify:registerFunctionHandler(PackageLogicForLua.onReceiveNotify);
    PackageLogicForLua.HPCampWarStateSync:registerFunctionHandler(PackageLogicForLua.onReceiveCampWarState);
    PackageLogicForLua.HPCampWarInFightStateSync:registerFunctionHandler(PackageLogicForLua.onReceiveCampWarInFightState);
    PackageLogicForLua.HPCampWarLastRankSync:registerFunctionHandler(PackageLogicForLua.onReceiveCampRankInfo);
    PackageLogicForLua.HPTitleInfoSyncS:registerFunctionHandler(PackageLogicForLua.onReceivePlayerTitleInfo);
    PackageLogicForLua.HPShopListSync:registerFunctionHandler(PackageLogicForLua.onReceiveRechargeList);
    PackageLogicForLua.HPContinueRechargeSync:registerFunctionHandler(PackageLogicForLua.onReceiveContinueRecharge);
    PackageLogicForLua.HPLoginDaySync:registerFunctionHandler(PackageLogicForLua.onReceiveLoginDay);
    PackageLogicForLua.HPGuildBossVitalitySync:registerFunctionHandler(PackageLogicForLua.onReceiveGuildBossVitality);
    PackageLogicForLua.HPRoleRingSync:registerFunctionHandler(PackageLogicForLua.onReceiveRoleRingInfoSync);
    PackageLogicForLua.HPSkillSyncHandler:registerFunctionHandler(PackageLogicForLua.onReceiveSkillSync);
    PackageLogicForLua.HPEliteMapSyncHandler:registerFunctionHandler(PackageLogicForLua.onReceiveEliteMapInfoSync);
    PackageLogicForLua.HPClientSettingPush:registerFunctionHandler(PackageLogicForLua.onReceiveClientSetting)
    PackageLogicForLua.HPEnterAFMainSync:registerFunctionHandler(PackageLogicForLua.onReceiveAllianceBattleInfo)
    PackageLogicForLua.HPAllianceTeamDetailInfo:registerFunctionHandler(PackageLogicForLua.onRecieveAllianceTeamDetail)
    PackageLogicForLua.HPSeeMercenaryInfo:registerFunctionHandler(PackageLogicForLua.onRecieveSeeMercenaryInfo)
    PackageLogicForLua.HPPlayerAreaSync:registerFunctionHandler(PackageLogicForLua.onRecievePlayAreaInfo)
    PackageLogicForLua.HPBossStatePush:registerFunctionHandler(PackageLogicForLua.onRecieveWorldBossState)
    PackageLogicForLua.HPPushChatLuck:registerFunctionHandler(PackageLogicForLua.onRecieveSpringFestivalEgg)
    PackageLogicForLua.HPRoleSync:registerFunctionHandler(PackageLogicForLua.onReceiveRoleSync)
    PackageLogicForLua.HPRoleExpSync:registerFunctionHandler(PackageLogicForLua.onReceiveRoleExpSync)
    PackageLogicForLua.HPGNetopFreeMonthForIOSHandler:registerFunctionHandler(PackageLogicForLua.onGNetopFreeMonthForIOSAndSync)
    PackageLogicForLua.HPAccountBound = PacketScriptHandler:new(HP_pb.ACCOUNT_BOUND_INFO_S, PackageLogicForLua.onReceiveAccountBound)
    PackageLogicForLua.HPSyncElementInfoHandler:registerFunctionHandler(PackageLogicForLua.onRecieveSyncElement)
    PackageLogicForLua.HPTimeSync:registerFunctionHandler(PackageLogicForLua.onReceiveServerTimeZone);
    PackageLogicForLua.HPGuideInfoRet:registerFunctionHandler(PackageLogicForLua.onReceiveGuideInfoRet)
    -- PackageLogicForLua.HPAnnounceInfoRet:registerFunctionHandler(PackageLogicForLua.onReceiveAnnounceInfoRet)
    PackageLogicForLua.HPReceiveFaceShareCountHandler:registerFunctionHandler(PackageLogicForLua.onReceiveFaceShareCount)
    PackageLogicForLua.HPonReceiveAdjustEventHandler:registerFunctionHandler(PackageLogicForLua.onReceiveAdjustEvent)
    PackageLogicForLua.HPonReceiveMercenaryExpeditionFinishHandler:registerFunctionHandler(PackageLogicForLua.onReceiveMercenaryExpeditionFinish)
    PackageLogicForLua.HPonReceiveMercenaryExpeditionInfoHandler:registerFunctionHandler(PackageLogicForLua.onReceiveMercenaryExpeditionInfo)
    PackageLogicForLua.HPReceiveMontylyCardHandler:registerFunctionHandler(PackageLogicForLua.onReceiveSupCalendar)
    PackageLogicForLua.HPReceiveMontylyCardHandler:registerFunctionHandler(PackageLogicForLua.onReceiveSummon)
    PackageLogicForLua.HPReceiveMontylyCardHandler:registerFunctionHandler(PackageLogicForLua.onReceiveSummon2)
    PackageLogicForLua.HPReceiveMontylyCardHandler:registerFunctionHandler(PackageLogicForLua.onReceiveSummon3)
    PackageLogicForLua.HPReceiveMontylyCardHandler:registerFunctionHandler(PackageLogicForLua.onReceiveStepBundle)
    PackageLogicForLua.HPReceiveMontylyCardHandler:registerFunctionHandler(PackageLogicForLua.onReceiveDailyLogin)
    PackageLogicForLua.HPReceiveMontylyCardHandler:registerFunctionHandler(PackageLogicForLua.onReceiveLargeMonthCard)
    PackageLogicForLua.HPReceiveMontylyCardHandler:registerFunctionHandler(PackageLogicForLua.onReceiveSmallMonthCard)
    PackageLogicForLua.HPonReceiveGuildApplyEmailRemoveHandler:registerFunctionHandler(PackageLogicForLua.onReceiveGuildApplyEmailRemove)
    PackageLogicForLua.HPonReceiveQuestRedpointStatusHandler:registerFunctionHandler(PackageLogicForLua.onReceiveQuestRedpointStatus)
    PackageLogicForLua.HPonReceiveFriendAddApplyHandler:registerFunctionHandler(PackageLogicForLua.onReceiveFriendAddApply)
    PackageLogicForLua.HPonReceiveFriendAddHandler:registerFunctionHandler(PackageLogicForLua.onReceiveFriendAdd)
    PackageLogicForLua.HPonReceiveFriendList:registerFunctionHandler(PackageLogicForLua.onReceiveFriendList)
    PackageLogicForLua.HPonReceiveFriendApplyList:registerFunctionHandler(PackageLogicForLua.onReceiveFriendApplyList)
    PackageLogicForLua.HPonRefuseFriendApply:registerFunctionHandler(PackageLogicForLua.onRefuseFriendApply)
    PackageLogicForLua.HPonDeleteFriend:registerFunctionHandler(PackageLogicForLua.onDeleteFriend)
    PackageLogicForLua.HPonChatSkinChangeInfo:registerFunctionHandler(PackageLogicForLua.onChatSkinChangeInfo)
    PackageLogicForLua.HPonChatSkinBuy:registerFunctionHandler(PackageLogicForLua.onChatSkinBuy)
    PackageLogicForLua.HPCrossDayNotice:registerFunctionHandler(PackageLogicForLua.onCrossDayNotice)
    PackageLogicForLua.HPCshowRedPoint:registerFunctionHandler(PackageLogicForLua.showRedPoint)

    PackageLogicForLua.HPRolePanelInof:registerFunctionHandler(PackageLogicForLua.onRolePanelInfo)
    PackageLogicForLua.HPRoleEmployDone:registerFunctionHandler(PackageLogicForLua.onRoleEmployDone)
    PackageLogicForLua.HPListenHeartBeat:registerFunctionHandler(PackageLogicForLua.onRecieveHeartBeat)
    PackageLogicForLua.HPonRegistDay:registerFunctionHandler(PackageLogicForLua.onRegistDay)
    PackageLogicForLua.HPonPlayerHelpMercenary:registerFunctionHandler(PackageLogicForLua.onPlayerHelpMercenary)
    PackageLogicForLua.HPonHelpFightMedicalFun:registerFunctionHandler(PackageLogicForLua.onHelpFightMedicalFun)
    PackageLogicForLua.HPonHelpFightChallengeFun:registerFunctionHandler(PackageLogicForLua.onHelpFightChallengeFun)
    PackageLogicForLua.HPSevenDay = PacketScriptHandler:new(HP_pb.SEVENDAY_QUEST_STATUS_UPDATE, PackageLogicForLua.onSevenDay)

    PackageLogicForLua.HPSevenDayInfo = PacketScriptHandler:new(HP_pb.SEVENDAY_QUEST_INFO_S, PackageLogicForLua.onSevenDayInfo)

    PackageLogicForLua.secretMsgHandler = PacketScriptHandler:new(HP_pb.SECRET_MESSAGE_SYNC_S, PackageLogicForLua.onReceiveSecretMsg)
    PackageLogicForLua.secretMsgHandler = PacketScriptHandler:new(HP_pb.GOODS_VERIFY_S, PackageLogicForLua.onReceiveGoods);
    PackageLogicForLua.HPgetHoneyP:registerFunctionHandler(PackageLogicForLua.getHoneyP)
    PackageLogicForLua.HPr18BuyResult:registerFunctionHandler(PackageLogicForLua.r18BuyResult)
    PackageLogicForLua.HPr18BoundSuccess:registerFunctionHandler(PackageLogicForLua.r18BoundSuccess)
    PackageLogicForLua.HPRecyleStageQuest:registerFunctionHandler(PackageLogicForLua.RecyleStageQuest)
    PackageLogicForLua.HPRecyle2StageQuest:registerFunctionHandler(PackageLogicForLua.Recyle2StageQuest)
    PackageLogicForLua.HPRecyleStage:registerFunctionHandler(PackageLogicForLua.RecyleStage)

    PackageLogicForLua.HPKusoPayResult:registerFunctionHandler(PackageLogicForLua.KusoPayResult)
    PackageLogicForLua.HPTowerData:registerFunctionHandler(PackageLogicForLua.TowerData)
    PackageLogicForLua.PickUpData:registerFunctionHandler(PackageLogicForLua.PickUpData)
    --JGG order
 --   PackageLogicForLua.HPJggGetOrder = PacketScriptHandler:new(HP_pb.SHOP_JGG_ORDER_S, PackageLogicForLua.onJggGetOrder)

    local ArenaData = require("Arena.ArenaData")
    ArenaData.validateAndRegister()
    require("Activity.ActivityInfo")
    ActivityInfo:validateAndRegister()
    local GVGManager = require("GVGManager")
    GVGManager.validateAndRegister()
    local FetterManager = require("FetterManager")
    FetterManager.validateAndRegister()
    local OSPVPManager = require("OSPVPManager")
    OSPVPManager.validateAndRegister()
    local LeaderAvatarManager = require("LeaderAvatarManager")
    LeaderAvatarManager.validateAndRegister()
end

function checkAndCloseMainSceneLoadingEnd(dt)
    if loadingClose == true then
        return  -- loading完成
    end
    loadingTime = loadingTime + dt
    local isDone = true
    for k, v in pairs(loadingOpcodes) do
        if not v.lock or not LockManager_getShowLockByPageName(v.lock) then -- 沒有上鎖條件 or 已解鎖
            if v.done == false then -- loading未完成
                isDone = false
                if loadingTime > 10 then    -- 等待時間超過10秒 > 重新發送協定
                    if k == HP_pb.FETCH_SHOP_LIST_S then
                        local msg = Recharge_pb.HPFetchShopList()
                        msg.platform = GameConfig.win32Platform
                        pb_data = msg:SerializeToString()
                        PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
                    elseif k == HP_pb.NP_CONTINUE_RECHARGE_MONEY_S then
                        local msg = Activity5_pb.NPContinueRechargeReq()
                        msg.action = 0
                        local pb_data = msg:SerializeToString()
                        PacketManager:getInstance():sendPakcet(HP_pb.NP_CONTINUE_RECHARGE_MONEY_C, pb_data, #pb_data, true)
                    else
                        common:sendEmptyPacket(k - 1, true)
                    end
                end
            end
        end
    end
    if not isDone then -- loading未完成
        if loadingTime > 10 then    -- 重置loading時間
            loadingTime = 0         
        end
        return
    end
    local container = tolua.cast(MainFrame:getInstance(), "CCBScriptContainer")
    local parentNode = container:getVarNode("mEnterLoadingNode")
    if parentNode then
        local actFadeOut = CCFadeOut:create(0.25)
        local actFunc = CCCallFuncN:create(function() 
            local container = tolua.cast(MainFrame:getInstance(), "CCBScriptContainer")
            local parentNode = container:getVarNode("mEnterLoadingNode")
            parentNode:removeAllChildrenWithCleanup(true) 
        end)
        local actArray = CCArray:create()
        actArray:addObject(actFadeOut)
        actArray:addObject(actFunc)
        local actSeq = CCSequence:create(actArray)
        parentNode:runAction(actSeq)

        MainScene_openGameLoadingEnd()
    end
    loadingClose = true
    loadingTime = 0   
end

return PackageLogicForLua;

