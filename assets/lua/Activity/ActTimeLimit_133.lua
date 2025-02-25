----------------------------------------------------------------------------------
--[[
	在线时长奖励
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity4_pb = require("Activity4_pb")
local thisPageName = 'ActTimeLimit_133'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");

local _ConfigData = ConfigManager.getAct133Cfg()
local _receiveId = 0
local _mainSceneContainer = nil
local _leftTime = nil
local _leftTimeName = "ActTimeLimit_133_leftTime"
local _serverData = nil
local ActTimeLimit_133 = { }

local option = {
    ccbiFile = "Act_TimeLimit_133.ccbi",
    handlerMap =
    {
        onReceive = "onReceive",
        onClose = "onClose",
        onFrame1 = "onClickItemFrame",
        onFrame2 = "onClickItemFrame",
        onFrame3 = "onClickItemFrame",
        onFrame4 = "onClickItemFrame",
    },
}
local opcodes = {
    ACTIVITY133_ONLINE_GIFT_GET_C = HP_pb.ACTIVITY133_ONLINE_GIFT_GET_C,
    ACTIVITY133_ONLINE_GIFT_GET_S = HP_pb.ACTIVITY133_ONLINE_GIFT_GET_S
}

function ActTimeLimit_133:onEnter(container)

    -- local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    -- luaCreat_ActTimeLimit_133(container)
    self:registerPacket(container)
    self:initData()
    self:initUi(container)

    self:getActivityInfo()
end


function ActTimeLimit_133:initData()
    _receiveId = ActTimeLimit_133_getIsShowMainSceneIcon()
    _ConfigData = ConfigManager.getAct133Cfg()
end

-- 
function ActTimeLimit_133:initUi(container)
    NodeHelper:setStringForLabel(container, { mLeftTimeText = "" })
    local itemInfo = _ConfigData[_receiveId]
    if not itemInfo then
        return
    end
    local rewardItems = { }
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count),
            } );
        end
    end
    self:fillRewardItem(container, rewardItems, 4)

    NodeHelper:setStringForLabel(container, { mRecharge = itemInfo.price })

    NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", false)
    NodeHelper:setNodeIsGray(container, { mReceiveText = true })
end

function ActTimeLimit_133:initSpine(container)

    local roldData = ConfigManager.getRoleCfg()[123]

    NodeHelper:setSpriteImage(self.container, { mNameFontSprite = roldData.namePic })

    local spineNode = container:getVarNode("mSpineNode");
    if spineNode then
        spineNode:removeAllChildren();
        --        local spine = SpineContainer:create(unpack(common:split((roldData.spine), ",")))
        --        local spineToNode = tolua.cast(spine, "CCNode")
        --        spineNode:addChild(spineToNode);
        --        spine:runAnimation(1, "Stand", -1)
        --        local offset_X_Str  , offset_Y_Str = unpack(common:split(("150,0"), ","))
        --        NodeHelper:setNodeOffset(spineToNode , tonumber(offset_X_Str) , tonumber(offset_Y_Str))
        --        spineToNode:setScale(0.4)
    end
end


-- 点击物品显示tips
function ActTimeLimit_133:onClickItemFrame(container, eventName)
    local rewardIndex = tonumber(eventName:sub(8))
    local nodeIndex = rewardIndex;
    local itemInfo = _ConfigData[_receiveId]
    if not itemInfo then return end
    local rewardItems = { }
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end
    GameUtil:showTip(container:getVarNode('mPic' .. nodeIndex), rewardItems[rewardIndex])
end


function ActTimeLimit_133:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
    local maxSize = maxSize or 4;
    isShowNum = isShowNum or false
    local nodesVisible = { };
    local lb2Str = { };
    local sprite2Img = { };
    local scaleMap = { }
    local menu2Quality = { };
    local colorTabel = { }
    for i = 1, maxSize do
        local cfg = rewardCfg[i];
        nodesVisible["mRewardNode" .. i] = cfg ~= nil;
        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
            if resInfo ~= nil then
                sprite2Img["mPic" .. i] = resInfo.icon;
                lb2Str["mNum" .. i] = "x" .. GameUtil:formatNumber(cfg.count);
                lb2Str["mName" .. i] = resInfo.name;

                menu2Quality["mFrame" .. i] = resInfo.quality
                sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
                if resInfo.iconScale then
                    scaleMap["mPic" .. i] = 1
                end

                colorTabel["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                if isShowNum then
                    resInfo.count = resInfo.count or 0
                    lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count;
                end
            else
                CCLuaLog("Error::***reward item not found!!");
            end
        end
    end

    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setColorForLabel(container, colorTabel);
end


function ActTimeLimit_133:onClose(container)
    PageManager.popPage(thisPageName)
end

function ActTimeLimit_133:onExit()
    self.container = nil
end

function ActTimeLimit_133:onReceive(container)
    self:sendBuyRequest(container)
end

function ActTimeLimit_133:sendBuyRequest(container)

    local msg = Activity4_pb.Activity133OnLineGiftGetReq()
    msg.cfgId = _receiveId
    common:sendPacket(HP_pb.ACTIVITY133_ONLINE_GIFT_GET_C, msg, true)
end


function ActTimeLimit_133:onExecute(container)
    if _leftTime <= 0 then
        NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", true)
        NodeHelper:setNodeIsGray(container, { mReceiveText = false })
        NodeHelper:setStringForLabel(container, { mLeftTimeText = "" })
    else
        local timeStr = GameMaths:formatSecondsToTime(leftTime)
        NodeHelper:setStringForLabel(container, { mLeftTimeText = timeStr })
    end
end


function ActTimeLimit_133:getActivityInfo()

end

function ActTimeLimit_133:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == opcodes.ACTIVITY133_ONLINE_GIFT_GET_S then
        local msg = Activity4_pb.Activity133OnLineGiftGetRes()
        msg:ParseFromString(msgBuff)
        ActTimeLimit_133_setServerData(msg)
        _receiveId = ActTimeLimit_133_getIsShowMainSceneIcon()
        ActTimeLimit_133_setLeftTime()
        PageManager.refreshPage("MainScenePage", "isShowActivity133Icon")
        ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY133_ONLINE_GIFT)
        self:initUi(self.container)
    end
end

function ActTimeLimit_133:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_133:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_133:onExit(container)

end



function ActTimeLimit_133_sendInfoRequest(mainSceneContainer)
    _mainSceneContainer = mainSceneContainer
    common:sendEmptyPacket(HP_pb.ACTIVITY133_ONLINE_GIFT_INFO_C, true)
end

function ActTimeLimit_133_getServerData()
    return _serverData
end

function ActTimeLimit_133_setServerData(msg)
    if msg == nil then
        return
    end
    -- HasField
    _serverData = { }
    for i = 1, #msg.info do
        local imteData = msg.info[i]
        _serverData[imteData.cfgId] = { id = imteData.cfgId, isGot = imteData.isGot, leftTime = 0 }
        if imteData:HasField("leftTime") then
            _serverData[imteData.cfgId].leftTime = imteData.leftTime
        end
    end
end

function ActTimeLimit_133_getIsShowMainSceneIcon()
    if _serverData == nil then
        return 0
    end
    table.sort(_serverData, function(data_1, data_2)
        if data_1 and data_2 then
            return data_1.cfgId < data_2.cfgId
        else
            return false
        end
    end )

    for k, v in pairs(_serverData) do
        if not v.isGot then
            _receiveId = v.cfgId
            break
        end
    end
    return _receiveId
end

function ActTimeLimit_133_setLeftTime()
    if _serverData[_receiveId] then
        _leftTime = _serverData[_receiveId].leftTime
    else
        _leftTime = 0
    end
end

function ActTimeLimit_133_onExitByMainScene()

end

function ActTimeLimit_133_getLeftTime()
    if _mainSceneContainer == nil or _serverData == nil then
        return 0
    end
    if _leftTime == nil then
        return 0
    end

    if _leftTime <= 0 then
        return 0
    end

    if not TimeCalculator:getInstance():hasKey(_leftTimeName) then
        TimeCalculator:getInstance():createTimeCalcultor(_leftTimeName, _leftTime)
    else
        _leftTime = TimeCalculator:getInstance():getTimeLeft(_leftTimeName)
        if _leftTime <= 0 then
            TimeCalculator:getInstance():removeTimeCalcultor(_leftTimeName)
            _leftTime = 0
        end
    end
    return _leftTime
end

local CommonPage = require('CommonPage')
ActTimeLimit_133 = CommonPage.newSub(ActTimeLimit_133, thisPageName, option)

return ActTimeLimit_133
