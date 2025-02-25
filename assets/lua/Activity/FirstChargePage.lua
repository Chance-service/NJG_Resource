----------------------------------------------------------------------------------
--[[
	首充奖励
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'FirstChargePage'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");

local FirstGiftCfg = { }

local tGiftInfo = {
    itemInfo = { },
    rewardState = false,
    isFirstPayMoney = false
}

local FirstChargeBase = { }

local option = {
    ccbiFile = "Act_FixedTimeFirstRechargeContent.ccbi",
    handlerMap =
    {
        onRecharge = "onRecharge",
        onFrame1 = "onClickItemFrame",
        onFrame2 = "onClickItemFrame",
        onFrame3 = "onClickItemFrame",
        onFrame4 = "onClickItemFrame",
    },
}
local opcodes = {
    FIRST_GIFTPACK_INFO_S = HP_pb.FIRST_GIFTPACK_INFO_S,
    FIRST_GIFTPACK_AWARD_S = HP_pb.FIRST_GIFTPACK_AWARD_S
}
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local CurrentStageId = 1

function FirstChargeBase:onEnter(ParentContainer)

    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    luaCreat_FirstChargePage(container)
    self:registerPacket(ParentContainer)
    FirstGiftCfg = ConfigManager.getFirstGiftPack()

    UserInfo.sync()
    local userItemId = UserInfo.roleInfo.itemId
    if userItemId > 3 then
        userItemId = userItemId - 3;
    end
    tGiftInfo.itemInfo = FirstGiftCfg[userItemId]
    local itemInfo = tGiftInfo.itemInfo
    if not itemInfo then return end
    local rewardItems = { }
    if itemInfo.giftpack ~= nil then
        for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count),
                isgold = itemInfo.isgold,
                textColor = itemInfo.textColor
            } );
        end
    end
    self:fillRewardItem(container, rewardItems, 4)
    NodeHelper:setMenuItemEnabled(container, "mRechargeBtn", false);
    self:getActivityInfo()

    local roldData = ConfigManager.getRoleCfg()[123]
    -- 黄舞蝶id = 102    暂时先用其他id代替
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
    if registDay <= 2 then
        CCUserDefault:sharedUserDefault():setIntegerForKey("FirstRecharge"..UserInfo.serverId..UserInfo.playerInfo.playerId..registDay,1)
    end

    return self.container
    end


-- 点击物品显示tips
function FirstChargeBase:onClickItemFrame(container, eventName)
    local rewardIndex = tonumber(eventName:sub(8))
    -- 数字
    local nodeIndex = rewardIndex;
    local itemInfo = nil;
    if rewardIndex > 4 then
        rewardIndex = rewardIndex - 4;
        itemInfo = MonthCardCfg[30]
    else
        itemInfo = tGiftInfo.itemInfo
    end
    if not itemInfo then return end
    local rewardItems = { }
    if itemInfo.giftpack ~= nil then
        for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
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


function FirstChargeBase:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
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
                    -- scaleMap["mPic" .. i] = resInfo.iconScale
                end


                --colorTabel["mNum" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                colorTabel["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                if isShowNum then
                    resInfo.count = resInfo.count or 0
                    lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count;
                end
                --                if cfg.type == 40000 then
                --                    --装备根据配置增加金装特效
                --                    local aniNode = container:getVarNode("mAni"..i);
                --                    if aniNode then
                --                        aniNode:removeAllChildren();
                --                        local ccbiFile = GameConfig.GodlyEquipAni[cfg.isgold];
                --                        aniNode:setVisible(false);
                --                        if ccbiFile ~=nil then
                --                            local ani = ScriptContentBase:create(ccbiFile);
                --                            ani:release()
                --                            ani:unregisterFunctionHandler();
                --                            aniNode:addChild(ani);
                --                            aniNode:setVisible(true);
                --                        end
                --                    end
                --                    --装备根据配置增加金装特效
                --                end
                --                --html
                --                local htmlNode = container:getVarLabelBMFont("mName"..i)
                -- 			if not htmlNode then htmlNode = container:getVarLabelTTF("mName"..i) end
                --                if htmlNode then
                --                    local htmlLabel;--泰语太长 修改htmlLabel的大小
                --                    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
                -- 					 htmlNode:setVisible(false)
                --                         htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition( htmlNode, CCSize(110,32),resInfo.name )
                --                         htmlLabel:setScaleX(htmlNode:getScaleX())
                --                         htmlLabel:setScaleY(htmlNode:getScaleY())
                --                    end
                --                end
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

function FirstChargeBase:onExit()

end

function FirstChargeBase:onRecharge(container)
    if tGiftInfo.isFirstPayMoney then
        common:sendEmptyPacket(HP_pb.FIRST_GIFTPACK_AWARD_C, true)
    else
        PageManager.pushPage("RechargePage")
    end
end

function FirstChargeBase:onExecute(ParentContainer)
    -- local timerName = ExpeditionDataHelper.getPageTimerName()
    -- if not TimeCalculator:getInstance():hasKey(timerName) then
    --     if ExpeditionDataHelper.getActivityRemainTime() <= 0 then
    --         local endStr = common:getLanguageString("@ActivityEnd");
    --         NodeHelper:setStringForLabel(self.container, {mTanabataCD = endStr});
    --        end
    --        return;
    --    end

    -- local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
    -- if remainTime + 1 > ExpeditionDataHelper.getActivityRemainTime() then
    -- 	return;
    -- end	

    -- ExpeditionDataHelper.setActivityRemainTime(remainTime)
    -- local timeStr = common:second2DateString(ExpeditionDataHelper.getActivityRemainTime(), false);

    -- if ExpeditionDataHelper.getActivityRemainTime() <= 0 then
    --     timeStr = common:getLanguageString("@ActivityEnd");
    --    end
    -- NodeHelper:setStringForLabel(self.container, {mTanabataCD = timeStr});
end


function FirstChargeBase:getActivityInfo()
    common:sendEmptyPacket(HP_pb.FIRST_GIFTPACK_INFO_C, true)
end

function FirstChargeBase:refreshFirstRechargeNode(container)
    local visible = true;
    local fntPath = GameConfig.FntPath.Bule
    local btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage

    if tGiftInfo.isFirstPayMoney and tGiftInfo.rewardState then
        btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
        fntPath = GameConfig.FntPath.Bule
        NodeHelper:setStringForLabel(container, { mRecharge = common:getLanguageString('@CanReceive') });
        -- 可领取
    elseif tGiftInfo.isFirstPayMoney and tGiftInfo.rewardState == false then
        btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
        fntPath = GameConfig.FntPath.Golden
        NodeHelper:setStringForLabel(container, { mRecharge = common:getLanguageString('@AlreadyReceive') });
        -- 领取完成
        visible = false;
    elseif tGiftInfo.isFirstPayMoney == false then
        btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
        fntPath = GameConfig.FntPath.Golden
        NodeHelper:setStringForLabel(container, { mRecharge = common:getLanguageString('@GoRecharge') });
        -- 购买
    end
    NodeHelper:setMenuItemImage(container, { mRechargeBtn = { normal = btnNormalImage } })
    NodeHelper:setBMFontFile(container, { mRecharge = fntPath })

    NodeHelper:setMenuItemEnabled(container, "mRechargeBtn", visible)

    NodeHelper:setNodeIsGray(container, { mRecharge = not visible })
end

function FirstChargeBase:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.FIRST_GIFTPACK_INFO_S then
        local msg = Activity_pb.HPFirstRechargeGiftInfo()
        msg:ParseFromString(msgBuff)
        tGiftInfo.rewardState =(msg.giftStatus == 0)
        tGiftInfo.isFirstPayMoney =(msg.isFirstPay == 1)
        -- 是否为首次充值
        self:refreshFirstRechargeNode(self.container);
        return
    end
    if opcode == opcodes.FIRST_GIFTPACK_AWARD_S then
        local msg = Activity_pb.HPFirstRechargeGiftAwardRet()
        msg:ParseFromString(msgBuff)
        tGiftInfo.rewardState =(msg.giftStatus == 0)
        if tGiftInfo.rewardState == false and  tGiftInfo.isFirstPayMoney then
            --提醒装备红点，有可激活的副将
            PageManager.showRedNotice("Equipment", true);
        end
        self:refreshFirstRechargeNode(self.container);
        ActivityInfo.changeActivityNotice(Const_pb.FIRST_GIFTPACK);
        return
    end

end
function FirstChargeBase:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function FirstChargeBase:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function FirstChargeBase:onExit(ParentContainer)
    local timerName = ExpeditionDataHelper.getPageTimerName()
    TimeCalculator:getInstance():removeTimeCalcultor(timerName)
    self:removePacket(ParentContainer)
end

local CommonPage = require('CommonPage')
FirstChargePage = CommonPage.newSub(FirstChargeBase, thisPageName, option)

return FirstChargePage
