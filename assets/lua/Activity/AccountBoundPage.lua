--账号绑定活动
--endregion
local thisPageName = "AccountBoundPage"
local AccountBound_pb = require("AccountBound_pb")
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
AccountBoundStatus = 0
AccountBoundReward = 0
local hasReward = false
local opcodes = {
    ACCOUNT_BOUND_REWARD_C = HP_pb.ACCOUNT_BOUND_REWARD_C,
    ACCOUNT_BOUND_REWARD_S = HP_pb.ACCOUNT_BOUND_REWARD_S
}
local option = {
    ccbiFile = "AccountBoundPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onReceive = "onReceive"
    },
    opcode = opcodes
}
local AccountBoundBase = {}

function AccountBoundBase:onEnter(container)
    self:registerPacket(container)
    self:refreshPage(container)
end

function AccountBoundBase:refreshPage(container)
    local aniName = ""
    if AccountBoundStatus == 1 then
        aniName = "Unbound"
        hasReward = false
    elseif AccountBoundStatus == 2 then
        hasReward = true
        aniName = "Binding"
    elseif AccountBoundStatus == 3 then
        hasReward = false
        aniName = "Binding"
    end
    local lb2Str = {
        mRewardNum = AccountBoundReward
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    self:setBtnEnable(container)
    container:runAnimation(aniName)
end
function AccountBoundBase:setBtnEnable(container)
    if hasReward == false then
        NodeHelper:setMenuItemEnabled(container, "mReceive", false)
    else
        NodeHelper:setMenuItemEnabled(container, "mReceive", true)
    end
end
function AccountBoundBase:onExit(container)
    self:removePacket(container)
end
function AccountBoundBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function AccountBoundBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
function AccountBoundBase:onClose(container)
    --AccountBoundReward = 0;
    PageManager.refreshPage("MainScenePage")
    PageManager.popPage(thisPageName)
end

function AccountBoundBase:onReceive(container)
    common:sendEmptyPacket(HP_pb.ACCOUNT_BOUND_REWARD_C)
end

function AccountBoundBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ACCOUNT_BOUND_REWARD_S then
        hasReward = false
        NoticePointState.ACCOUNTBOUND_POINT = false
        self:setBtnEnable(container)
    end
end
local CommonPage = require("CommonPage")
AccountBoundPage = CommonPage.newSub(AccountBoundBase, thisPageName, option)
