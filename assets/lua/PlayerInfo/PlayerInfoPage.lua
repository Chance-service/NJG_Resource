----------------------------------------------------------------------------------
--[[
    個人資料
--]]
----------------------------------------------------------------------------------
require("CDKeyPage")
local thisPageName = "PlayerInfoPage"
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local NewbieGuideManager = require("Guide.NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo")
local AnnounceDownLoad = require("AnnounceDownLoad")
local UserMercenaryManager = require("UserMercenaryManager")
local NgHeadIconItem_Small = require("NgHeadIconItem_Small")
local CONST = require("Battle.NewBattleConst")
require "ecchigamer/EcchiGamerSDK"

local opcodes = { 
    ACCOUNT_BOUND_REWARD_C = HP_pb.ACCOUNT_BOUND_REWARD_C,
    ROLE_CHANGE_NAME_C = HP_pb.ROLE_CHANGE_NAME_C,
    ROLE_CHANGE_NAME_S = HP_pb.ROLE_CHANGE_NAME_S,
    GET_FORMATION_EDIT_INFO_C = HP_pb.GET_FORMATION_EDIT_INFO_C,
    GET_FORMATION_EDIT_INFO_S = HP_pb.GET_FORMATION_EDIT_INFO_S,
}

local option = {
    ccbiFile = "PersonalConfidencePopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onVIPDetailed = "onShowVipDetail",
        onOpinion = "onFeedback",
        onBattleSetUp = "onBattleSetUp",
        onChangeName = "onChangeName",
        onBoundAccount = "onBoundAccount",
        onAnnoucement = "onAnnoucement",
        onCDKFunction = "onCDKFunction",
        onServiceAnnounce = "onServiceAnnounce",
        onChangePlayerIcon = "onChangePlayerIcon",
    },
    opcode = opcodes
}

local PlayerInfoPageBase = { }
local playerTeamInfo = { }

local mercenaryHeadContent = {
    ccbiFile = "FormationTeamContent.ccbi"
}

local NodeHelper = require("NodeHelper")

local bindState = 0
local HEAD_SCALE = 0.831
-----------------------------------------------
function mercenaryHeadContent:refreshItem(container)
    self.container = container
    UserInfo = require("PlayerInfo.UserInfo")
    local roleIcon = ConfigManager.getRoleIconCfg()
    local trueIcon = GameConfig.headIconNew or UserInfo.playerInfo.headIcon
    if not roleIcon[trueIcon] then
        local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
        if NodeHelper:isFileExist(icon) then
            NodeHelper:setSpriteImage(container, { mHead = icon })
        end
        --NodeHelper:setSpriteImage(container, { mHeadFrame = GameConfig.MercenaryBloodFrame[1] })
        NodeHelper:setStringForLabel(container, { mLv = UserInfo.roleInfo.level })
    else
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[trueIcon].MainPageIcon })
        NodeHelper:setStringForLabel(container, { mLv = UserInfo.roleInfo.level })
    end

    NodeHelper:setNodesVisible(container, { mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false, 
                                            mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false })
end
-----------------------------------------------
-- PlayerInfoPageBase
----------------------------------------------
function PlayerInfoPageBase:onEnter(container)
    self:registerPacket(container)
    PlayerInfoPageBase.container = container
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    
    NodeHelper:initScrollView(container, "mContent", 5)

    self:getDefaultTeamInfo(container)
    self:refreshPage(container)
end

function PlayerInfoPageBase:onExecute(container)
end

function PlayerInfoPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end
function PlayerInfoPageBase:onExit(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    self:removePacket(container)
end
----------------------------------------------------------------
function PlayerInfoPageBase:refreshPage(container)
    self:showPlayerInfo(container)
    self:showPlayerTeam(container)
end
function PlayerInfoPageBase:getDefaultTeamInfo(container)
    local msg = Formation_pb.HPFormationEditInfoReq()
    msg.index = 1
    common:sendPacket(HP_pb.GET_FORMATION_EDIT_INFO_C, msg, false)
end

function PlayerInfoPageBase:showPlayerInfo(container)
    UserInfo.sync()
    local vipTexture = "PlayerInfo_VIP" .. UserInfo.playerInfo.vipLevel .. ".png"

    NodeHelper:setNodesVisible(container, { mBoundAccountNode = (Golb_Platform_Info.is_r18) or (Golb_Platform_Info.is_kuso) })
    bindState = libPlatformManager:getPlatform():getIsGuest()  -- 0 = 舊帳號登入, 1 = 遊客登入
    NodeHelper:setMenuItemEnabled(container, "mBindBtn", (bindState ~= 0) or (Golb_Platform_Info.is_kuso)) --綁定開關
    NodeHelper:setNodeIsGray(container, { mAccount = (bindState == 0) })
    if (Golb_Platform_Info.is_r18) then
        NodeHelper:setMenuItemImage(container, { mBindBtn = { normal = "Btn_AccountBinding_N.png", press = "Btn_AccountBinding_S.png" } })
    elseif (Golb_Platform_Info.is_kuso) then
        NodeHelper:setMenuItemImage(container, { mBindBtn = { normal = "Btn_PersonalConfidence69_N.png", press = "Btn_PersonalConfidence69_S.png" } })
    end

    local lb2Str = {
        mName = UserInfo.roleInfo.name,
        mID = UserInfo.playerInfo.playerId,
        mServerTxt = UserInfo.serverId,
        mPowerTxt = UserInfo.roleInfo.marsterFight,
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, { mVipImg = vipTexture })

    self:refreshPlayerIcon(container)
end

function PlayerInfoPageBase:showPlayerTeam(container)
    container.mScrollView:removeAllCell()
    container.m_pScrollViewFacade:clearAllItems()
    local nowPosX = 0
    for i = 1, CONST.HERO_COUNT do
        if playerTeamInfo[i] and playerTeamInfo[i] ~= 0 then
            local roleId = playerTeamInfo[i]
            local iconItem = NgHeadIconItem_Small:createCCBFileCell(roleId, i, container.mScrollView, GameConfig.NgHeadIconSmallType.PLAYERINFO_PAGE, 
                                                                    HEAD_SCALE, nil)
        end
    end
    container.mScrollView:orderCCBFileCells()
    container.mScrollView:setTouchEnabled(false)
end

function PlayerInfoPageBase:refreshPlayerIcon(container)
    local headNode = ScriptContentBase:create(mercenaryHeadContent.ccbiFile)
    local parentNode = container:getVarNode("mHeadNode")
    parentNode:removeAllChildren()
    mercenaryHeadContent:refreshItem(headNode)
    headNode:setAnchorPoint(ccp(0.5, 0.5))
    parentNode:addChild(headNode)
end

function PlayerInfoPageBase:buildItem(container)
end
----------------click event------------------------
function PlayerInfoPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function PlayerInfoPageBase:onServiceAnnounce(container)
    if Golb_Platform_Info.is_h365 then
        PageManager.showHelp(GameConfig.HelpKey.HELP_AGREEMENT)
    elseif Golb_Platform_Info.is_r18 then
        PageManager.showHelp(GameConfig.HelpKey.HELP_AGREEMENT_R18)
    elseif Golb_Platform_Info.is_kuso then
        PageManager.showHelp(GameConfig.HelpKey.HELP_AGREEMENT_KUSO)
    else
        PageManager.showHelp(GameConfig.HelpKey.HELP_AGREEMENT)
    end
end

function PlayerInfoPageBase:onDataTransfer(container)
    --PageManager.pushPage("DataTransferPage")    --按鈕功能替換為客服
    local AnnouncementPopPageBase = require("AnnouncementPopPage")
    local platform = ConfigManager.getPlatformCfg()
    local cfg
    if Golb_Platform_Info.is_h365 then
        cfg = ConfigManager.loadCfgByIoString("Feedback.txt")
    elseif Golb_Platform_Info.is_r18 then
        cfg = ConfigManager.loadCfgByIoString("Feedback_EROR18.txt")
    elseif Golb_Platform_Info.is_jgg then
        cfg = ConfigManager.loadCfgByIoString("Feedback_JGG.txt")
    else
        cfg = ConfigManager.loadCfgByIoString("Feedback.txt")
    end
    AnnouncementPopPageBase:setIsFeedBack(true)
    AnnouncementPopPageBase:SetMessage(cfg)
    AnnouncementPopPageBase:setTitle("@Opinion")
    PageManager.pushPage("AnnouncementPopPage")
end

function PlayerInfoPageBase:onChangePlayerIcon()
    PageManager.pushPage("ChangePlayerIconPage")
end

function PlayerInfoPageBase:onEntermateLogout(container)
    GamePrecedure:getInstance():reEnterMateLogout()
end

function PlayerInfoPageBase:onChangeName(container)
    local function inputBoxCallback(inputName)
        UserInfo.sync()
        if GameMaths:calculateStringCharacters(inputName) <= 0 then
            MessageBoxPage:Msg_Box_Lan("@NotInputName")
            return
        end

        if GameMaths:calculateStringCharacters(inputName) > GameConfig.WordSizeLimit.RoleNameLimit then
            MessageBoxPage:Msg_Box_Lan("@NameExceedLimit")
            return
        end

        if inputName == UserInfo.roleInfo.name then
            MessageBoxPage:Msg_Box_Lan("@NameRepeat")
            return
        end
        
        local UserItemManager = require("Item.UserItemManager")
        local cardItem = UserItemManager:getUserItemByItemId(101004)
        local num = cardItem and cardItem.count or 0
    
        if num <= 0 and UserInfo.playerInfo.gold < GameConfig.ChangeNameCost then               
            MessageBoxPage:Msg_Box_Lan("@ERRORCODE_14")
            return
        else
            if num > 0 then
                PageManager.showConfirm(common:getLanguageString("@HintTitle"),
                common:getLanguageString("@ChangeNameCostCard"),
                function(isOK)
                    if isOK then
                        local msg = Player_pb.HPChangeRoleName()
                        msg.name = inputName
                        common:sendPacket(opcodes.ROLE_CHANGE_NAME_C, msg)
                    end
                end )
            else
                PageManager.showConfirm(common:getLanguageString("@HintTitle"),
                string.gsub(common:getLanguageString("@ChangeNameCost"), "#v1#", GameConfig.ChangeNameCost),
                function(isOK)
                    if isOK then
                        local msg = Player_pb.HPChangeRoleName()
                        msg.name = inputName
                        common:sendPacket(opcodes.ROLE_CHANGE_NAME_C, msg)
                    end
                end )
            end
        end
   
    end    
    
    PageManager.pushPage("PageRoleWriteName") -- ChangeNamePage
    SetInputBoxInfo2("", "", "", inputBoxCallback, 1, 2)
end

function PlayerInfoPageBase:onLanguageSwitch(container)
    PageManager.pushPage("LanguageSwitchPopUp")
end

function PlayerInfoPageBase:onBoundAccount(container)
    if bindState ~= 0 then
        if Golb_Platform_Info.is_r18 then
            CCLuaLog("onClickBind")
            local openBindGameCallback = function (BindGameResult)
                CCLuaLog("BindGameResult1")
                CCLuaLog("isSuccess = " .. tostring(BindGameResult.isSuccess))
                CCLuaLog("result: " .. BindGameResult.result)
                if BindGameResult.isSuccess == true then
                    local userID = BindGameResult.user_id
                    local token = EcchiGamerSDK.getToken()
                    CCLuaLog("userID: " .. userID)
                    CCLuaLog("token: " .. token)
                    local AccountBound_pb = require("AccountBound_pb")
                    local msg = AccountBound_pb.HPAccountBoundConfirm()
                    msg.userId = userID
                    msg.wallet = ""
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
            PageManager.showConfirm(common:getLanguageString("@SDK10"), common:getLanguageString("@SDK10"), function(bool)
                if bool then
                    EcchiGamerSDK:openAccountBindGame(UserInfo.playerInfo.playerId, openBindGameCallback)
                end 
            end)
        end
    end
    if Golb_Platform_Info.is_kuso then
        libPlatformManager:getPlatform():showPlatformProfile()
    end
end

function PlayerInfoPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    CCLuaLog("OPCODE: " .. opcode)
    if opcode == opcodes.ROLE_CHANGE_NAME_S then
        UserInfo.sync()
        MessageBoxPage:Msg_Box_Lan("@ChangeNameSuccess")
        inputName = ""
        PageManager.refreshPage(thisPageName)
        PageManager.refreshPage("MainScenePage", "refreshInfo")
        PageManager.popPage("PageRoleWriteName")
    elseif opcode == opcodes.GET_FORMATION_EDIT_INFO_S then
        local msg = Formation_pb.HPFormationEditInfoRes()
        msg:ParseFromString(msgBuff)
        local formation = msg.formations
        playerTeamInfo = { }
        for i = 1, #formation.roleIds do
            table.insert(playerTeamInfo, formation.roleIds[i])
        end
        self:refreshPage(container)
    end
end
function PlayerInfoPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName then
            if extraParam == "refreshIcon" then
                self:refreshPlayerIcon(container)
                return
            end
            self:refreshPage(container)
        end
    end
end

function PlayerInfoPageBase.onBattleSetUp(container)
    PageManager.pushPage("BattleSettingPage")
end

function PlayerInfoPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function PlayerInfoPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function PlayerInfoPageBase:onAnnoucement(container)
    -- PageManager.pushPage("AnnouncementPopPage")
    AnnounceDownLoad.start()
end

function PlayerInfoPageBase:onCDKFunction(container)
    PageManager.pushPage("CDKeyPage")
    --2021.5.6改為工口帳號登出
    --[[
    if bindState == 1 or bindState == 2 then  --遊客登入or工口帳號登出
        CCLuaLog("onClickOpenLogout")
        local isguest = libPlatformManager:getPlatform():getIsGuest()
        local openLogoutCallback = function (logoutResult)
            CCLuaLog("logout1")
            if logoutResult.exception ~= "" then
            CCLuaLog("logout2")
                return
            end
            CCLuaLog("logout3")
            CCUserDefault:sharedUserDefault():setStringForKey("ecchigamer.token","")
            CCLuaLog("logout4")
            PageManager.showNotice(common:getLanguageString("@SDK3"), common:getLanguageString("@SDK11"), function()
                GamePrecedure:getInstance():reEnterLoading()
            end,false,false)
            CCLuaLog("logout5")
        end

        if (bindState == 1) then    -- 工口訪客登入提醒視窗
            CCLuaLog("onClickGusetLogout")
            local title = Language:getInstance():getString("@SDK3")
            local message = common:getLanguageString("@SDK8")
            local sureToLogOut = function(flag)
                if flag then
                    --
                    EcchiGamerSDK:openLogout(openLogoutCallback)
                    --
                end
            end
            PageManager.showConfirm(title, message, sureToLogOut)            
        else
            EcchiGamerSDK:openLogout(openLogoutCallback)
        end
        
    end]]--
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local PlayerInfoPage = CommonPage.newSub(PlayerInfoPageBase, thisPageName, option)