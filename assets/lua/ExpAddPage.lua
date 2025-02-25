----------------------------------------------------------------------------------
--[[
    经验加成描述面板
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local thisPageName = "ExpAddPage"
local HP_pb = require("HP_pb")
local RoleOpr_pb = require("RoleOpr_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local UserMercenaryManager = require("UserMercenaryManager")
require("Activity.ActivityConfig")
require('MainScenePage')

local ExpAddPage = { }

local option = {
    ccbiFile = "ExpAddPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
    },
    opcodes =
    {

    }
}

local opcodes = {
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    WEEK_CARD_INFO_S = HP_pb.CONSUME_WEEK_CARD_INFO_S,
};

local _ConfigData = nil
local _ItemData = nil
local _allExpAdd = 0
local weekCardLeftDay = 0
------------------------------------------------------
local Item = {
    ccbiFile = "ExpAddItem.ccbi"
}

function Item:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item:onJumpBtnClick(container)
    -- 跳转
    if self.data.type == 1 then
        local activityType = ActivityConfig[self.data.activityId].activityType
        if activityType == 1 then
            -- 特典
            require("WelfarePage")
            WelfarePage_setPart(self.data.activityId)
            -- WelfarePage_setPart(self.data.activityId)
            PageManager.pushPage("WelfarePage")
        end
    elseif self.data.type == 2 then
        local activityType = ActivityConfig[self.data.activityId].activityType
        if activityType == 1 then
            -- 特典
            require("WelfarePage")
            WelfarePage_setPart(self.data.activityId)
            -- WelfarePage_setPart(self.data.activityId)
            PageManager.pushPage("WelfarePage")
        end
    elseif self.data.type == 3 then
        local activityType = ActivityConfig[self.data.activityId].activityType
        if activityType == 1 then
            -- 特典
            require("WelfarePage")
            WelfarePage_setPart(self.data.activityId)
            PageManager.pushPage("WelfarePage")
        end
    end
    ExpAddPage.onClose()
end

function Item:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    if container == nil then return; end
    self.container = container

    self.isOpen, self.isShowBtnNode = self:getIsOpen()

    NodeHelper:setSpriteImage(self.container, { mIcon = self.data.icon })
    NodeHelper:setStringForLabel(self.container, { mExpAddText = common:getLanguageString("@ExpAddDesc_2", self.data.expAdd .. "%"), mMessage_1 = common:getLanguageString(self.data.des_1, self.data.stageLevel), mMessage_2 = common:getLanguageString(self.data.des_2) })
    --    self.isOpen = false
    --    self.isShowBtnNode = false
    --    if self.data.type == 1 then
    --        -- 获得副将
    --        local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(self.data.roleId)
    --        if roleInfo then
    --            self.isOpen = true
    --        end
    --    elseif self.data.type == 2 then
    --        -- 副将突破等级
    --        local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(self.data.roleId)
    --        if roleInfo then
    --            if roleInfo.stageLevel - 1 >= self.data.stageLevel then
    --                self.isOpen = true
    --            end
    --        end
    --    elseif self.data.type == 3 then
    --        -- 参与活动
    --        if self.data.activityId == 83 then
    --            -- 普通月卡
    --            if UserInfo.playerInfo.monthCardLeftDay > 0 then
    --                self.isOpen = true
    --            else
    --                self.isShowBtnNode = true
    --            end
    --        elseif self.data.activityId == 129 then
    --            -- 暂时没有
    --        end
    --    end
    NodeHelper:setNodesVisible(self.container, { mIsOpen = not self.isOpen, mJumpBtnNode = self.isShowBtnNode })

    if self.isOpen then
        NodeHelper:setColorForLabel(self.container, { mExpAddText = "0 153 0", mMessage_1 = "158 79 76", mMessage_2 = "158 79 76" })
    else
        NodeHelper:setColorForLabel(self.container, { mExpAddText = "110 100 100", mMessage_1 = "110 100 100", mMessage_2 = "110 100 100" })
    end
end


function Item:getExpAdd()
    return self.data.expAdd
end

function Item:getIsOpen()
    --    local n = 0
    --    if self.isOpen then
    --        n = self:getExpAdd()
    --    end
    --    return 0
    local isOpen = false
    local isShowBtnNode = false
    if self.data.type == 1 then
        -- 获得副将
        local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(self.data.roleId)
        if roleInfo then
            isOpen = true
        else
            isShowBtnNode = true
        end
    elseif self.data.type == 2 then
        -- 副将突破等级
        local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(self.data.roleId)
        if roleInfo then
            if roleInfo.stageLevel - 1 >= self.data.stageLevel then
                isOpen = true
            else
                local role = ConfigManager.getRoleCfg()[self.data.roleId]
                if role.FashionInfos then
                    local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(role.FashionInfos[2])
                    if roleInfo then
                        if roleInfo.stageLevel - 1 >= self.data.stageLevel then
                            isOpen = true
                        end
                    end

                end
            end
        else
            local role = ConfigManager.getRoleCfg()[self.data.roleId]
            if role.FashionInfos then
                isShowBtnNode = true
            end
        end
    elseif self.data.type == 3 then
        -- 参与活动
        if self.data.activityId == 83 then
            -- 普通月卡
            if UserInfo.playerInfo.monthCardLeftDay > 0 then
                isOpen = true
            else
                isShowBtnNode = true
            end
        elseif self.data.activityId == 129 then
            -- 周卡
            if weekCardLeftDay > 0 then
                isOpen = true
            else
                isShowBtnNode = true
            end
        end
    end
    return isOpen, isShowBtnNode
end

------------------------------------------------------

function ExpAddPage:onEnter(container)
    self.container = container
    self:initData()
    self:registerPacket(self.container)
    self:initUi(self.container)
    common:sendEmptyPacket(HP_pb.CONSUME_WEEK_CARD_INFO_C, true)
end

function ExpAddPage:onExit(container)
    self:removePacket(self.container)
    NodeHelper:deleteScrollView(self.container)
    self.container = nil
    _ItemData = { }
    -- common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
end

function ExpAddPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ExpAddPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ExpAddPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    --[[if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(msgBuff)
        UserMercenaryManager:setMercenaryStatusInfos(msg.roleInfos)
        self:initUi(self.container)
    end]]
    if opcode == HP_pb.CONSUME_WEEK_CARD_INFO_S then
        local msg = Activity4_pb.ConsumeWeekCardInfoRet()
        msg:ParseFromString(msgBuff)
        weekCardLeftDay = msg.leftDays
        self:initUi(self.container)
    end
end

function ExpAddPage:onClose(container)
    PageManager.popPage(thisPageName)
end

function ExpAddPage:initData()
    _ConfigData = ConfigManager.getExpBuffShowCfg()
    _ItemData = nil
    _allExpAdd = 0
    for k, v in pairs(_ConfigData) do
        _allExpAdd = _allExpAdd + v.expAdd
    end
end


function ExpAddPage:initUi(container)
    NodeHelper:initScrollView(container, "mContent", 3)

    self:clearAllItem(container)
    self:buildItem(container)

    local addExpAdd = 0
    local currentExpAdd = 0

    local isOpen = false
    for k, v in pairs(_ItemData) do
        addExpAdd = addExpAdd + v:getExpAdd()
        isOpen = v:getIsOpen()
        if isOpen then
            currentExpAdd = currentExpAdd + v:getExpAdd()
        end
    end
    NodeHelper:setStringForLabel(container, { mMessageText = common:getLanguageString("@ExpAddDesc_1", currentExpAdd .. "%", addExpAdd .. "%") })
end


function ExpAddPage:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

function ExpAddPage:buildItem(container)
    _ItemData = { }
    container.mScrollView:removeAllCell()
    for k, v in pairs(_ConfigData) do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { data = v })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        table.insert(_ItemData, panel)
        container.mScrollView:addCellBack(titleCell)
    end

    container.mScrollView:orderCCBFileCells()
end

local CommonPage = require('CommonPage')
NewServerActivity = CommonPage.newSub(ExpAddPage, thisPageName, option)
