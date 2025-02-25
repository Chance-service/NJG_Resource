----------------------------------------------------------------------------------
--[[
	關卡特惠礼包
    複製自 ActPopUpSalePSubPage_151
    - 把 大部分132改成151 (除了 協定訊息格式 或 ccbi 仍是用132)
    - 把 LEVEL_GIFT 改成 STAGE_GIFT
    - minLv -> minStage, maxLv -> maxStage
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local TimeDateUtil = require("Util.TimeDateUtil")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity4_pb = require("Activity4_pb")
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local ResManager = require("ResManagerForLua")
local ItemManager = require("Item.ItemManager")

local _ConfigData = ConfigManager.getAct151Cfg()

-- local _buyId = 1
local _buyData = nil
local _freeConfigData = { }
local _diamondsConfigDta = { }
local ActPopUpSaleSubPage_151 = {
    rewardItems = {}
}

--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/ActPopUpSale.lang"] then
--    __lang_loaded["Lang/ActPopUpSale.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/ActPopUpSale.lang")
--end

local _serverData = nil
local _showData = nil

local CCBI_FILE = "Act_TimeLimit_132.ccbi"

local HANDLER_MAP = {
    onRecharge = "onRecharge",
    onReceive = "onReceive",
    onClose = "onClose",
    onFrame1 = "onClickItemFrame",
    onFrame2 = "onClickItemFrame",
    onFrame3 = "onClickItemFrame",
    onFrame4 = "onClickItemFrame",
}

local OPCODES = {
    ACTIVITY151_STAGE_GIFT_BUY_C = HP_pb.ACTIVITY151_STAGE_GIFT_BUY_C,
    ACTIVITY151_STAGE_GIFT_BUY_S = HP_pb.ACTIVITY151_STAGE_GIFT_BUY_S
}

-- local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")

function ActPopUpSaleSubPage_151:onEnter(parentContainer)
    local slf = self

    self.container = ScriptContentBase:create(CCBI_FILE)
    
    -- 註冊 呼叫 行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = HANDLER_MAP[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)

    -- luaCreat_ActPopUpSaleSubPage_151(self.container)
    self:registerPacket(parentContainer)
    self:initData()
    self:initUi(self.container)

    self:getActivityInfo()

    return self.container
end


function ActPopUpSaleSubPage_151:initData()
    _buyData = ActPopUpSaleSubPage_151_getIsShowMainSceneIcon()
    --    UserInfo.sync()
    --    _ConfigData = ConfigManager.getAct151Cfg()
    --    _buyId = 1
    --    for i = 1, #_ConfigData do
    --        local data = _ConfigData[i]
    --        if UserInfo.stateInfo.passMapId >= data.minStage and UserInfo.stateInfo.passMapId <= data.maxStage then
    --            _buyId = i
    --            break
    --        end
    --    end
end

-- 
function ActPopUpSaleSubPage_151:initUi(container)

    local itemInfo = _ConfigData[_buyData.id]
    if not itemInfo then
        return
    end

    itemInfo.price=ActPopUpSalePage_getPrice(itemInfo.id)

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

    self.rewardItems = rewardItems

    -- 初始化 獲得列表
    NodeHelper:initScrollView(container, "mContent", #self.rewardItems);

    self:updateItems()

    -- NodeHelper:setMenuItemEnabled(container, "mRechargeBtn", false)

    NodeHelper:setStringForLabel(container, { mRecharge = itemInfo.price })
    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())

    if itemInfo.price <= 0 then
        NodeHelper:setNodesVisible(container, { mReceiveNode = true, mRechargeNode = false })
        --NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minStage .. "-" .. itemInfo.maxStage })

        NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minStage })

        NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", UserInfo.stateInfo.passMapId >= itemInfo.minStage)
        NodeHelper:setNodeIsGray(container, { mReceiveText = not(UserInfo.stateInfo.passMapId >= itemInfo.minStage) })

        NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString("@Receive") })
        if UserInfo.stateInfo.passMapId <= itemInfo.minStage then
            -- 等级不够
            -- NodeHelper:setStringForLabel(container, { mReceiveText = "@Receive" })
        else
            --
            -- NodeHelper:setStringForLabel(container, { mReceiveText = "" })
        end
        -- NodeHelper:setSpriteImage(container, { mBg = "BG/Activity_151/Act_151_Bg_2.png" }, { mBg = 1 })
    else
        NodeHelper:setNodesVisible(container, { mReceiveNode = false, mRechargeNode = true })
        if itemInfo.minStage >= 100 then
            NodeHelper:setStringForLabel(container, { mLvLabel = "100+" })
        else
            NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minStage .. "-" .. itemInfo.maxStage })
        end
        -- NodeHelper:setSpriteImage(container, { mBg = "BG/Activity_151/Act_151_Bg_1.png" }, { mBg = 1 })
    end

    --    if _buyData.id == #diamondsConfigDta then
    --        NodeHelper:setStringForLabel(container, { mLvLabel = "100+" })
    --    else
    --        NodeHelper:setStringForLabel(container, { mLvLabel = itemInfo.minStage .. "-" .. itemInfo.maxStage })
    --    end

    -- local mLvSprite = container:getVarSprite("mLvSprite")
    -- local mLvLabel = container:getVarLabelBMFont("mLvLabel")
    -- if mLvSprite and mLvLabel then
    --     mLvSprite:setPositionX(mLvLabel:getPositionX() - mLvLabel:getContentSize().width)
    -- end
     NodeHelper:setSpriteImage(container,{mLvSprite="popsale_151_img.png",mBg="BG/UI/popsale_151_bg.png"})
    NodeHelper:setStringForLabel(container,{mTxt=common:getLanguageString("@popsale_151_info_".._buyData.id)})
end

function ActPopUpSaleSubPage_151:updateItems()
    local size = #self.rewardItems
        
    local colMax = 4

    local options = {
        -- magic layout number 
        -- 因為CommonRewardContent尺寸異常，導致各使用處需要自行處理
        interval = ccp(0, 0),
        colMax = colMax,
        paddingTop = 0,
        paddingBottom = 0,
        originScrollViewSize = CCSizeMake(544, 272),
        isDisableTouchWhenNotFull = true
    }
    
    -- 未滿 1行 則 橫向置中
    if size < colMax then
        options.isAlignCenterHorizontal = true
    end
    
    -- 未達 2行 則 垂直置中
    if size <= colMax then
        options.isAlignCenterVertical = true
        options.startOffset = ccp(0, 0)
    -- 達到 2行 則 偏移在首項 並 偏移paddingTop
    else
        options.startOffsetAtItemIdx = 1
        options.startOffset = ccp(0, -options.paddingTop)
    end

    --[[ 滾動視圖 左上至右下 ]]
    NodeHelperUZ:buildScrollViewGrid_LT2RB(
        self.container,
        size,
        "CommonRewardContent.ccbi",
        function (eventName, container)
            self:onScrollViewFunction(eventName, container)
        end,
        options
    )
            
    -- 顯示/隱藏 列表 或 無獎勵提示
    NodeHelper:setNodesVisible(self.container, {
        mContent = size ~= 0
    })
    
    -- 若 數量 尚未超過 每行數量 的話
    if size <= colMax  then
        local node = self.container:getVarNode("mContent")
        node:setTouchEnabled(false)
    end
end
--[[ 滾動視圖 功能窗口 ]]
function ActPopUpSaleSubPage_151:onScrollViewFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        --- 每个子空间创建的时候会调用这个函数
        local contentId = container:getItemDate().mID;
        -- 获取到时第几行
        local idx = contentId
        -- 获取当前的index      i是每行的第几个 用来获取组件用的
        local node = container:getVarNode("mItem")
        local itemNode = ScriptContentBase:create('GoodsItem.ccbi')

        local itemData = self.rewardItems[idx]
        local resInfo = ResManager:getResInfoByTypeAndId(itemData and itemData.type or 30000, itemData and itemData.itemId or 104001, itemData and itemData.count or 1);
        --NodeHelper:setStringForLabel(itemNode, { mName = "" });
        local numStr = ""
        if resInfo.count > 0 then
            numStr = tostring(resInfo.count)
        end
        local lb2Str = {
            mNumber = numStr
        };
        local showName = "";
        if itemData and itemData.type == 30000 then
            showName = ItemManager:getShowNameById(itemData.itemId)
        else
            showName = resInfo.name           
        end
        NodeHelper:setNodesVisible(itemNode, { m2Percent = false, m5Percent = false });

        if itemData.type == 40000 then
            for i = 1, 6 do
                NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.quality })
            end
        end
        NodeHelper:setNodesVisible(itemNode, { mStarNode = itemData.type == 40000 })
        
        --NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.BlurryLineWidth - 10, 4)
        NodeHelper:setStringForLabel(itemNode, lb2Str);
        NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = 1 });
        NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality });
        NodeHelper:setColorForLabel(itemNode, { mName = ConfigManager.getQualityColor()[resInfo.quality].textColor })
        NodeHelper:setNodesVisible(itemNode, { mName = false})

        node:addChild(itemNode);
        itemNode:registerFunctionHandler(function (eventName, container)
            if eventName == "onHand" then
                local id = container.id
                GameUtil:showTip(container:getVarNode("mHand"), self.rewardItems[id])
            end  
        end)
        -- itemNode:setTouchEnabled(inst.container.mScrollView:isTouchEnabled())
        itemNode.id = contentId
    end
end

function ActPopUpSaleSubPage_151:initSpine(container)

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
function ActPopUpSaleSubPage_151:onClickItemFrame(container, eventName)
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


-- function ActPopUpSaleSubPage_151:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
--     local maxSize = maxSize or 4;
--     isShowNum = isShowNum or false
--     local nodesVisible = { };
--     local lb2Str = { };
--     local sprite2Img = { };
--     local scaleMap = { }
--     local menu2Quality = { };
--     local colorTabel = { }
--     for i = 1, maxSize do
--         local cfg = rewardCfg[i];
--         nodesVisible["mRewardNode" .. i] = cfg ~= nil;
--         if cfg ~= nil then
--             local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
--             if resInfo ~= nil then
--                 sprite2Img["mPic" .. i] = resInfo.icon;
--                 lb2Str["mNum" .. i] = "x" .. GameUtil:formatNumber(cfg.count);
--                 --lb2Str["mName" .. i] = resInfo.name;

--                 NodeHelper:setBlurryString(container, "mName" .. i, resInfo.name, GameConfig.BlurryLineWidth, 5)


--                 menu2Quality["mFrame" .. i] = resInfo.quality
--                 sprite2Img["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality);
--                 if resInfo.iconScale then
--                     scaleMap["mPic" .. i] = 1
--                 end

--                 colorTabel["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
--                 if isShowNum then
--                     resInfo.count = resInfo.count or 0
--                     lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count;
--                 end
--             else
--                 CCLuaLog("Error::***reward item not found!!");
--             end
--         end
--     end

--     NodeHelper:setNodesVisible(container, nodesVisible);
--     NodeHelper:setStringForLabel(container, lb2Str);
--     NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
--     NodeHelper:setQualityFrames(container, menu2Quality);
--     NodeHelper:setColorForLabel(container, colorTabel);
-- end


function ActPopUpSaleSubPage_151:onClose(container)
    
end

function ActPopUpSaleSubPage_151:onExit(parentContainer)
    --    local timerName = ExpeditionDataHelper.getPageTimerName()
    --    TimeCalculator:getInstance():removeTimeCalcultor(timerName)
       NodeHelper:clearScrollView(self.container)
       self:removePacket(parentContainer)
end

function ActPopUpSaleSubPage_151:onRecharge(container)
    require ("ActPopUpSale.ActPopUpSalePage")
    ActPopUpSalePage_setReward(self.rewardItems)
    self:sendBuyRequest(container)
    --    if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
    --        common:rechargePageFlag("ActPopUpSaleSubPage_151")
    --        return
    --    end
    --    local msg = Activity4_pb.Activity132LevelGiftBuyReq()
    --    msg.cfgId = _buyData.id
    --    common:sendPacket(HP_pb.ACTIVITY151_STAGE_GIFT_BUY_C, msg, true)
end

function ActPopUpSaleSubPage_151:onReceive(container)
    self:sendBuyRequest(container)
    --    if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
    --        common:rechargePageFlag("ActPopUpSaleSubPage_151")
    --        return
    --    end
    --    local msg = Activity4_pb.Activity132LevelGiftBuyReq()
    --    msg.cfgId = _buyData.id
    --    common:sendPacket(HP_pb.ACTIVITY151_STAGE_GIFT_BUY_C, msg, true)
end

function ActPopUpSaleSubPage_151:sendBuyRequest(container)
    --if UserInfo.playerInfo.gold < _ConfigData[_buyData.id].price then
    --    common:rechargePageFlag("ActPopUpSaleSubPage_151")
    --    return
    --end
    local msg = Activity4_pb.Activity132LevelGiftBuyReq()
    msg.cfgId = _buyData.id
    common:sendPacket(HP_pb.ACTIVITY151_STAGE_GIFT_BUY_C, msg, false)
end


function ActPopUpSaleSubPage_151:onExecute(parentContainer)
    local isLeftTimeSeted = false
    if _serverData ~= nil and _serverData.limitDate ~= nil then
        local leftTime = _serverData.limitDate - os.time()
        if leftTime > 0 then
            -- 剩餘時間 轉至 日期格式
            local leftTimeDate = TimeDateUtil:utcTime2Date(leftTime)
            -- 重新進位
            leftTimeDate = TimeDateUtil:utcDateCarry(leftTimeDate)

            -- 原本是 日時分 所以字串定 dhm 可能改leftTime比較精確
            local text = string.format(common:getLanguageString("@ActPopUpSale.LeftTimeText.dhm"),leftTimeDate.day, leftTimeDate.hour, leftTimeDate.min, leftTimeDate.sec)
            local SplitTime =  common:second2DateString4(leftTime,true)
            local text=string.format(common:getLanguageString("@ActPopUpSale.LeftTimeText.dhm"),SplitTime[1], SplitTime[2], SplitTime[3], SplitTime[4])
            NodeHelper:setStringForTTFLabel(self.container, {
                leftTimeText = text
            })
            isLeftTimeSeted = true
        end
    end
    
    NodeHelper:setNodesVisible(self.container, {
        leftTimeText = isLeftTimeSeted
    });
    local MainPage=require("ActPopUpSale.ActPopUpSalePage")
    if not isLeftTimeSeted then  MainPage:onCloseBtn(self.container)  end
end


function ActPopUpSaleSubPage_151:getActivityInfo()

end

function ActPopUpSaleSubPage_151:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == OPCODES.ACTIVITY151_STAGE_GIFT_BUY_S then
        local msg = Activity4_pb.Activity132LevelGiftBuyRes()
        msg:ParseFromString(msgBuff)
        -- local Const_pb = require("Const_pb")
        -- ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY151_STAGE_GIFT)
        -- local gotCfgId = msg.gotCfgId
        ActPopUpSaleSubPage_151_setServerData(msg)
        _buyData = ActPopUpSaleSubPage_151_getIsShowMainSceneIcon()
        PageManager.refreshPage("MainScenePage", "isShowActivity151Icon")
        -- 检查小红点
        if not _buyData.isShowRedPoint then
            ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY151_STAGE_GIFT)
        end
        if not _buyData.isShowIcon then
            local Const_pb = require("Const_pb")

            self:onClose()
        else
            self:initUi(self.container)
        end
    end
end

function ActPopUpSaleSubPage_151:chakeRedPoint()
    local isShowRedPoint = false



    if not isShowRedPoint then

    end
end

function ActPopUpSaleSubPage_151:onPlayEnterSpine(container)
    local parentNode = container:getVarNode("mEffectSpineNode")
    local spine = SpineContainer:create("NGUI", "NGUI_11_PopGift")
    local spineNode = tolua.cast(spine, "CCNode")
    parentNode:addChild(spineNode)
    spine:runAnimation(1, "animation", 0)
end

function ActPopUpSaleSubPage_151:registerPacket(container)
    for key, opcode in pairs(OPCODES) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActPopUpSaleSubPage_151:removePacket(container)
    for key, opcode in pairs(OPCODES) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


function ActPopUpSaleSubPage_151_sendInfoRequest()
    common:sendEmptyPacket(HP_pb.ACTIVITY151_STAGE_GIFT_INFO_C, false)
end


function ActPopUpSaleSubPage_151_getServerData()
    return _serverData
end

function ActPopUpSaleSubPage_151_setServerData(msg)
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
    
    if msg.limitDate ~= nil then
        _serverData.limitDate = os.time() +msg.limitDate
        local PopUpPage=require("ActPopUpSale.ActPopUpSalePage")
        _buyData=ActPopUpSaleSubPage_151_getIsShowMainSceneIcon()
        PopUpPage:setTime(151, _serverData.limitDate,_serverData[_buyData.id].isGot,_buyData.id)
    end
end

function ActPopUpSaleSubPage_151_getIsShowMainSceneIcon()
    if _serverData == nil then
        print("serverData is null 151")
        _showData = { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
        return _showData
    end

    if _serverData.limitDate ~= nil and os.time() >= _serverData.limitDate then
        _showData = { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
        return _showData
    end

    _ConfigData = ConfigManager.getAct151Cfg()
    _freeConfigData = #_freeConfigData > 0 and _freeConfigData or { }
    _diamondsConfigDta = #_diamondsConfigDta > 0 and _diamondsConfigDta or { }

    if #_freeConfigData <= 0 and #_diamondsConfigDta <= 0 then
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
                return data_1.maxStage < data_2.maxStage
            else
                return false
            end
        end )

        table.sort(_diamondsConfigDta, function(data_1, data_2)
            if data_1 and data_2 then
                return data_1.maxStage < data_2.maxStage
            else
                return false
            end
        end )
    end

    --UserInfo.sync()

    for k, v in pairs(_freeConfigData) do
        if _serverData[v.id] and not _serverData[v.id].isGot then
            _showData = { isShowIcon = true, id = v.id, isFree = true, isShowRedPoint = false }
            if UserInfo.stateInfo.passMapId >= v.minStage and UserInfo.stateInfo.passMapId <= v.maxStage then
               data.isShowRedPoint = true
            end
            return _showData
        end
--        if not _serverData[v.id].isGot then
--            local data = { isShowIcon = true, id = v.id, isFree = true, isShowRedPoint = false }
--            if UserInfo.stateInfo.passMapId >= v.minStage and UserInfo.stateInfo.passMapId <= v.maxStage then
--               data.isShowRedPoint = true
--            end
--            return data
--        end

    end

    for k, v in pairs(_diamondsConfigDta) do
        if UserInfo.stateInfo.passMapId >= v.minStage and UserInfo.stateInfo.passMapId <= v.maxStage and (_serverData[v.id] and not _serverData[v.id].isGot) then
--            local data = { isShowIcon = true, id = v.id, isFree = true, isShowRedPoint = false }
--            if UserInfo.stateInfo.passMapId >= v.minStage and UserInfo.stateInfo.passMapId <= v.maxStage then
--               data.isShowRedPoint = true
--            end
--            return data
            _showData = { isShowIcon = true, id = v.id, isFree = false, isShowRedPoint = true }
            return _showData
        end
    end
    _showData = { isShowIcon = false, id = 1, isFree = false, isShowRedPoint = false }
    return _showData
end

return ActPopUpSaleSubPage_151
