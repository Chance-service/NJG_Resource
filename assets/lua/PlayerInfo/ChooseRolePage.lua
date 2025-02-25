--======================================================================================
--
-- new page for create role
--======================================================================================
local HP          = require("HP_pb")
local NodeHelper  = require("NodeHelper")
local PageManager = require("PageManager")
local common      = require("common")
local Player_pb   = require("Player_pb")

local ChooseRolePageInfo = { }

local _PageContainer   = nil
local _SpineNode       = nil
local _PageRoleName    = nil

-- 由于c++中开放的接口不全 使用全局变量传递参数
_Gs_CreateRoleId       = 1
_Gs_ShowAnimFunc       = nil

function luaCreat_ChooseRolePage(container)
	container:registerFunctionHandler(ChooseRolePageInfo.onFunction)
end

function ChooseRolePageInfo.onFunction(eventName, container)
    if eventName == "luaLoad" then
        ChooseRolePageInfo.onLoad(container)
    elseif eventName == "luaUnLoad" then
        ChooseRolePageInfo.onUnLoad(container)
    elseif eventName == "luaEnter" then
        ChooseRolePageInfo.onEnter()
    elseif eventName == "luaExit" then
		ChooseRolePageInfo.onExit()

    elseif eventName == "onSelectWarrior" then
        ChooseRolePageInfo.onShowCreateRoleName(true)
    elseif eventName == "onSelectMaster" then
        ChooseRolePageInfo.onShowCreateRoleName(true)
    elseif eventName == "onSelectHunter" then
        ChooseRolePageInfo.onShowCreateRoleName(true)
    elseif eventName == "luaTimeout" then
        ChooseRolePageInfo.onRunLoadingAni(true)
    elseif eventName == "luaReceivePacket" then
        ChooseRolePageInfo.onReceivePacket()
    elseif eventName == "luaGameMessage" then
        ChooseRolePageInfo.onGameMessage()
    end
end

function ChooseRolePageInfo.onShowCreateRoleName(bVisible)
    if _PageRoleName then
        if not _PageRoleName:isVisible() and bVisible then
            _PageRoleName:runAnimation("WriteName")
        end
        _PageRoleName:setVisible(bVisible)
        --if bVisible then
        --    _PageRoleName:runAnimation("WriteName")
        --end
    end
end




function ChooseRolePageInfo.onLoad(container)
    _PageContainer = container
	container:loadCcbiFile("ChoiceRolePage_1.ccbi", false)
end

function ChooseRolePageInfo.onUnLoad(container)
end

function ChooseRolePageInfo.onEnter()
    local parentNode = _PageContainer:getVarNode("mMidNode")
    if parentNode then
        parentNode:setVisible(true)

        _PageRoleName = CCBScriptContainer:create("PageRoleWriteName")
        _PageRoleName:load()
        _PageRoleName:setVisible(false)
        parentNode:addChild(_PageRoleName)
        _PageRoleName:release()

        _WaitAnimNode = ScriptContentBase:create("LoadingAni.ccbi")
        _WaitAnimNode:setVisible(false)
        _PageContainer:addChild(_WaitAnimNode, 100001)
        _WaitAnimNode:release()

        local spinePath = "Spine/NG2D_nobg"
        local spineName = "NG2D_999_nobg"
        CCLuaLog("ChooseRolePageInfo1")
        local spine = SpineContainer:create(spinePath, spineName)
        CCLuaLog("ChooseRolePageInfo2")
        local spineNode = tolua.cast(spine, "CCNode")
        local parentNode = _PageContainer:getVarNode("mSpine")
        parentNode:addChild(spineNode)
        spine:runAnimation(1,"animation", -1)
    end

    local bg = _PageContainer:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())

    _PageContainer:registerPacket(HP.ROLE_CREATE_S)
    _PageContainer:registerMessage(MSG_MAINFRAME_COVERSHOW)
    _Gs_ShowAnimFunc = ChooseRolePageInfo.onRunLoadingAni

    --_PageContainer:runAnimation("part1")

    ----------------
    local tabTime = os.date("*t")
    tabTime.hour = 0
    tabTime.min = 0
    tabTime.sec = 0
    local time = os.time(tabTime)
    CCUserDefault:sharedUserDefault():setStringForKey("LastClickMonthCardTime_" .. GamePrecedure:getInstance():getServerID(), time)
    ----------------
    local GuideManager = require("Guide.GuideManager")
    GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] = 1
end

function ChooseRolePageInfo.onExit()
    _PageContainer:removePacket(HP.ROLE_CREATE_S)
    _PageContainer:removeMessage(MSG_MAINFRAME_COVERSHOW)
    _Gs_CreateRoleId = 1
    _Gs_ShowAnimFunc = nil
end


function ChooseRolePageInfo.onReceivePacket()
    local opcode = _PageContainer:getRecPacketOpcode()
	local msgBuff = _PageContainer:getRecPacketBuffer()

    if opcode == HP.ROLE_CREATE_S then
		local msg = Player_pb.HPRoleCreateRet()
		msg:ParseFromString(msgBuff)
        if msg.status ~= 0 then
            ChooseRolePageInfo.onRunLoadingAni(false)
        else
            if Golb_Platform_Info.is_r18 then
                AdjustManager:onTrackEvent("ix2k8k")
            end
            libPlatformManager:getPlatform():sendMessageG2P('G2P_REPORT_HANDLER','1')
        end
    end
end

function ChooseRolePageInfo.onGameMessage()
	local message = _PageContainer:getMessage()
	local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_COVERSHOW then
        ChooseRolePageInfo.onRunLoadingAni(false)
    end
end

function ChooseRolePageInfo.onRunLoadingAni(isShow)
    if not _WaitAnimNode then return end
    _WaitAnimNode:setVisible(isShow)
end

--===============================================================================================================
--===============================================================================================================