----------------------------------------------------------------------------------
--[[
	等级特惠礼包
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity4_pb = require("Activity4_pb")
local thisPageName = 'ActTimeLimit_132'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");

local _ConfigData = ConfigManager.getAct132Cfg()
-- local _buyId = 1
local _buyData = nil
local _freeConfigData = { }
local _diamondsConfigDta = { }
local ActTimeLimit_132 = { }

local _serverData = nil

local option = {
    ccbiFile = "Act_TimeLimit_132.ccbi",
    handlerMap =
    {
        onRecharge = "onRecharge",
        onReceive = "onReceive",
        onClose = "onClose",
        onFrame1 = "onClickItemFrame",
        onFrame2 = "onClickItemFrame",
        onFrame3 = "onClickItemFrame",
        onFrame4 = "onClickItemFrame",
    },
}
local opcodes = {
    ACTIVITY132_LEVEL_GIFT_BUY_C = HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_C,
    ACTIVITY132_LEVEL_GIFT_BUY_S = HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_S
}
-- local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")

function ActTimeLimit_132:onEnter(container)

    -- local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    -- luaCreat_ActTimeLimit_132(container)
    self:registerPacket(container)
    self:initData()
    self:initUi(container)

    self:getActivityInfo()
end


function ActTimeLimit_132:initData()
    _buyData = ActTimeLimit_132_getIsShowMainSceneIcon()
    --    UserInfo.sync()
    --    _ConfigData = ConfigManager.getAct132Cfg()
    --    _buyId = 1
    --    for i = 1, #_ConfigData do
    --        local data = _ConfigData[i]
    --        if UserInfo.roleInfo.level >= data.minLv and UserInfo.roleInfo.level <= data.maxLv then
    --            _buyId = i
    --            break
    --        end
    --    end
end

-- 
function ActTimeLimit_132:initUi(container)

    local itemInfo = _ConfigData[_buyData.id]
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
    -- NodeHelper:setMenuItemEnabled(container, "mRechargeBtn", false)

    NodeHelper:setStringForLabel(container, { mRecharge = itemInfo.price })




    if itemInfo.price <= 0 then
        NodeHelper:setNodesVisible(container, { mReceiveNode = true, mRechargeNode = false })
        --NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minLv .. "-" .. itemInfo.maxLv })

        NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minLv })

        NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", UserInfo.roleInfo.level >= itemInfo.minLv)
        NodeHelper:setNodeIsGray(container, { mReceiveText = not(UserInfo.roleInfo.level >= itemInfo.minLv) })

        NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString("@Receive") })
        if UserInfo.roleInfo.level <= itemInfo.minLv then
            -- 等级不够
            -- NodeHelper:setStringForLabel(container, { mReceiveText = "@Receive" })
        else
            --
            -- NodeHelper:setStringForLabel(container, { mReceiveText = "" })
        end
        NodeHelper:setSpriteImage(container, { mBg = "BG/Activity_132/Act_132_Bg_2.png" }, { mBg = 1 })
    else
        NodeHelper:setNodesVisible(container, { mReceiveNode = false, mRechargeNode = true })
        if itemInfo.minLv >= 100 then
            NodeHelper:setStringForLabel(container, { mLvLabel = "100+" })
        else
            NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minLv .. "-" .. itemInfo.maxLv })
        end
        NodeHelper:setSpriteImage(container, { mBg = "BG/Activity_132/Act_132_Bg_1.png" }, { mBg = 1 })
    end

    --    if _buyData.id == #diamondsConfigDta then
    --        NodeHelper:setStringForLabel(container, { mLvLabel = "100+" })
    --    else
    --        NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minLv .. "-" .. itemInfo.maxLv })
    --    end

    local mLvSprite = container:getVarSprite("mLvSprite")
    local mLvLabel = container:getVarLabelBMFont("mLvLabel")
    if mLvSprite and mLvLabel then
        mLvSprite:setPositionX(mLvLabel:getPositionX() - mLvLabel:getContentSize().width)
    end
end

function ActTimeLimit_132:initSpine(container)

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
function ActTimeLimit_132:onClickItemFrame(container, eventName)
    local rewardIndex = tonumber(eventName:sub(8))
    local nodeIndex = rewardIndex;
    local itemInfo = _ConfigData[_buyData.id]
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


function ActTimeLimit_132:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
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
                --lb2Str["mName" .. i] = resInfo.name;

                NodeHelper:setBlurryString(container, "mName" .. i, resInfo.name, GameConfig.BlurryLineWidth, 5)


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


function ActTimeLimit_132:onClose(container)
    PageManager.popPage(thisPageName)
end

function ActTimeLimit_132:onExit()

end

function ActTimeLimit_132:onRecharge(container)
    self:sendBuyRequest(container)
    --    if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
    --        common:rechargePageFlag("ActTimeLimit_132")
    --        return
    --    end
    --    local msg = Activity4_pb.Activity132LevelGiftBuyReq()
    --    msg.cfgId = _buyData.id
    --    common:sendPacket(HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_C, msg, true)
end

function ActTimeLimit_132:onReceive(container)
    self:sendBuyRequest(container)
    --    if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
    --        common:rechargePageFlag("ActTimeLimit_132")
    --        return
    --    end
    --    local msg = Activity4_pb.Activity132LevelGiftBuyReq()
    --    msg.cfgId = _buyData.id
    --    common:sendPacket(HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_C, msg, true)
end

function ActTimeLimit_132:sendBuyRequest(container)
    if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
        common:rechargePageFlag("ActTimeLimit_132")
        return
    end
    local msg = Activity4_pb.Activity132LevelGiftBuyReq()
    msg.cfgId = _buyData.id
    common:sendPacket(HP_pb.ACTIVITY132_LEVEL_GIFT_BUY_C, msg, true)
end


function ActTimeLimit_132:onExecute(container)

end


function ActTimeLimit_132:getActivityInfo()

end

function ActTimeLimit_132:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == opcodes.ACTIVITY132_LEVEL_GIFT_BUY_S then
        local msg = Activity4_pb.Activity132LevelGiftBuyRes()
        msg:ParseFromString(msgBuff)
        -- local Const_pb = require("Const_pb")
        -- ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY132_LEVEL_GIFT)
        -- local gotCfgId = msg.gotCfgId
        ActTimeLimit_132_setServerData(msg)
        _buyData = ActTimeLimit_132_getIsShowMainSceneIcon()
        PageManager.refreshPage("MainScenePage", "isShowActivity132Icon")
        -- 检查小红点
        if not _buyData.isShowRedPoint then
            ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY132_LEVEL_GIFT)
        end
        if not _buyData.isShowIcon then
            local Const_pb = require("Const_pb")

            self:onClose()
        else
            self:initUi(self.container)
        end
    end
end

function ActTimeLimit_132:chakeRedPoint()
    local isShowRedPoint = false



    if not isShowRedPoint then

    end
end


function ActTimeLimit_132:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_132:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_132:onExit(container)
    --    local timerName = ExpeditionDataHelper.getPageTimerName()
    --    TimeCalculator:getInstance():removeTimeCalcultor(timerName)
    --    self:removePacket(container)
end

function ActTimeLimit_132_sendInfoRequest()
    common:sendEmptyPacket(HP_pb.ACTIVITY132_LEVEL_GIFT_INFO_C, true)
end


function ActTimeLimit_132_getServerData()
    return _serverData
end

function ActTimeLimit_132_setServerData(msg)
    _serverData = msg
    if _serverData == nil then
        _serverData = { }
        return
    end
    _serverData = { }
    for i = 1, #msg.info do
        local imteData = msg.info[i]
        _serverData[imteData.cfgId] = { id = imteData.cfgId, isGot = imteData.isGot }
    end
end

function ActTimeLimit_132_getIsShowMainSceneIcon()
    if _serverData == nil then
        return { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
    end

    _ConfigData = ConfigManager.getAct132Cfg()
    _freeConfigData = { }
    _diamondsConfigDta = { }


    for i = 1, #_ConfigData do
        local data = _ConfigData[i]
        if data.price <= 0 then
            table.insert(_freeConfigData, data)
        else
            table.insert(_diamondsConfigDta, data)
        end
    end

    table.sort(_freeConfigData, function(data_1, data_2)
        if data_1 and data_2 then
            return data_1.maxLv < data_2.maxLv
        else
            return false
        end
    end )

    table.sort(_diamondsConfigDta, function(data_1, data_2)
        if data_1 and data_2 then
            return data_1.maxLv < data_2.maxLv
        else
            return false
        end
    end )


    UserInfo.sync()


    for k, v in pairs(_freeConfigData) do
        if _serverData[v.id] and not _serverData[v.id].isGot then
              local data = { isShowIcon = true, id = v.id, isFree = true, isShowRedPoint = false }
            if UserInfo.roleInfo.level >= v.minLv and UserInfo.roleInfo.level <= v.maxLv then
               data.isShowRedPoint = true
            end
            return data
        end
--        if not _serverData[v.id].isGot then
--            local data = { isShowIcon = true, id = v.id, isFree = true, isShowRedPoint = false }
--            if UserInfo.roleInfo.level >= v.minLv and UserInfo.roleInfo.level <= v.maxLv then
--               data.isShowRedPoint = true
--            end
--            return data
--        end

    end

    for k, v in pairs(_diamondsConfigDta) do
        if UserInfo.roleInfo.level >= v.minLv and UserInfo.roleInfo.level <= v.maxLv and (_serverData[v.id] and not _serverData[v.id].isGot) then
--            local data = { isShowIcon = true, id = v.id, isFree = true, isShowRedPoint = false }
--            if UserInfo.roleInfo.level >= v.minLv and UserInfo.roleInfo.level <= v.maxLv then
--               data.isShowRedPoint = true
--            end
--            return data

            return { isShowIcon = true, id = v.id, isFree = false, isShowRedPoint = true }
        end
    end

    return { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
end

local CommonPage = require('CommonPage')
ActTimeLimit_132 = CommonPage.newSub(ActTimeLimit_132, thisPageName, option)

return ActTimeLimit_132
