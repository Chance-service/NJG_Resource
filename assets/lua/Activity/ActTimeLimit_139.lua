-- 
local NodeHelper = require("NodeHelper")
local Activity4_pb = require("Activity4_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "ActTimeLimit_139"
local UserItemManager = require("Item.UserItemManager");
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")
local ResManagerForLua = require("ResManagerForLua")
local thisActivityId = 139      -- 这个活动的活动id
local ActTimeLimit_139 = { }

local Discount = {
    [1] = { mOnceDiscount = 1, mTheDiscount = 1 },
    [2] = { mOnceDiscount = 1, mTheDiscount = 1 }
}

-- 抽卡类型
TreasureSearchType = {
    SEARCHTYPE_BASIC = 1,
    SEARCHTYPE_SKIN = 2
}

-- 抽奖道具
local PROP_ITEM_ID = 0

local _type = 0
local _subType = 1
local _roleCfg = nil
local _ItemTabel = { }
local _serverData = nil
local _RewardItems = { }
local _roleIds = { }
-- 副将数据
local _roleData = { }
-- 奖池奖励
local _rewardConfig = { }
-- 图片路径
local _roleNamePicPath = { }

local _userItemCount = 0

ActTimeLimit_139.freeTimerCKey = "Activity_ActTimeLimit_139_FreeTimerCDKey"
ActTimeLimit_139.endTimerCDKey = "ActTimeLimit_139_EndTimer"

local option = {
    ccbiFile = "Act_TimeLimit_139.ccbi",
    handlerMap =
    {
        onRewardPreview = "onRewardPreview",
        onFashion = "onFashion",
        onBtnClick_1 = "onBtnClick_1",
        onBtnClick_2 = "onBtnClick_2",

        onArrowLeft = "onArrowLeft",
        onArrowRight = "onArrowRight",
        onPropAdd = "onPropAdd",
        onJump = "onJump",
        onCard_1 = "onCard_1",
        onCard_2 = "onCard_2",
        onCard_3 = "onCard_3",
        onCard_4 = "onCard_4",
    },
}


local opcodes = {
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    -- 请求info
    ACTIVITY138_RAIDER_INFO_C = HP_pb.ACTIVITY138_RAIDER_INFO_C,
    -- info返回
    ACTIVITY138_RAIDER_INFO_S = HP_pb.ACTIVITY138_RAIDER_INFO_S,
    -- 点击抽卡
    ACTIVITY138_RAIDER_SEARCH_C = HP_pb.ACTIVITY138_RAIDER_SEARCH_C,
    -- 点击抽卡返回
    ACTIVITY138_RAIDER_SEARCH_S = HP_pb.ACTIVITY138_RAIDER_SEARCH_S,
    -- 副将信息返回
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
}

local _serverData = nil
local spriteColor = { "23 213 254", "197 23 254", "252 254 114", "255 51 51" }
local CurContainer = nil

local _spineNode = nil


----------------------------------------------------------------------------------------
local mColSpace = 200;
local mSlidTimeOut = 0.15; -- 滑动时候切换时候 出屏滚动的时间 单位秒
local mSlidTimeIn = 0.3; -- 滑动时候切换时候 入屏滚动的时间 单位秒
local mSlidDistance = 120; -- 滑动时候切换时候 切换角色的阈值
local mCurRoleIndex = 0;

function ActTimeLimit_139:createTouchLayer(container)
    local touchLayer = tolua.cast(container:getVarNode("mTouchLayer"), "CCLayerColor");

    -- local touchLayer = CCLayerColor:create(ccc4(255, 0, 0, 255))
    -- touchLayer:setTag(10086)
    -- container:addChild(touchLayer)
    -- touchLayer:setZOrder(0)
    touchLayer:setOpacity(0);
    touchLayer:setTouchEnabled(true)
    touchLayer:setTouchMode(kCCTouchesOneByOne);
    touchLayer:registerScriptTouchHandler( function(eventType, touch)

        if _serverData == nil then
            return true
        end
        if eventType == "began" then
            return self:onLayerTouchBegan(touch)
        elseif eventType == "moved" then
            return self:onLayerTouchMoved(touch)
        elseif eventType == "ended" then
            return self:onLayerTouchEnded(touch)
        end
        return true
    end );

    self.mbCanTouchSpineLayer = true;
end

function ActTimeLimit_139:onLayerTouchBegan(touch)
    local bCanTouch = self.mbCanTouchSpineLayer;
    if self.mbCanTouchSpineLayer then
        self.mbCanTouchSpineLayer = false;
        local spineAttachNode = _spineNode;
        local spinePosX, spinePoxY = spineAttachNode:getPosition();
        self.mSpineAttachNodePosX = spinePosX;
        self.mTouchStartLocation = touch:getLocation();
    end
    return bCanTouch;
end

function ActTimeLimit_139:onLayerTouchMoved(touch)
    local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local desighWidth, desighHeight = visibleSize.width, visibleSize.height;

    local lpos = touch:getLocation();
    local lspos = self.mTouchStartLocation;
    local beginDelta = { x = lpos.x - lspos.x, y = lpos.y - lspos.y };

    if math.abs(beginDelta.x) >= desighWidth then
        return true;
    end

    local moveDelta = touch:getDelta();
    local spineAttachNode = _spineNode;
    local curPosX, curPosY = spineAttachNode:getPosition();
    spineAttachNode:setPositionX(moveDelta.x + curPosX);
    return true;
end

function ActTimeLimit_139:onLayerTouchEnded(touch)
    local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local desighWidth, desighHeight = visibleSize.width, visibleSize.height;

    local lpos = touch:getLocation();
    local lspos = self.mTouchStartLocation;
    local beginDelta = { x = lpos.x - lspos.x, y = lpos.y - lspos.y };
    local spineAttachNode = _spineNode;
    local curPosX, curPoxY = spineAttachNode:getPosition();
    local nodeMoveDeltaXabs = math.abs(curPosX - self.mSpineAttachNodePosX)

    local targetX = 0;
    local bNew = false;
    if beginDelta.x < 0 and math.abs(beginDelta.x) >= mSlidDistance then
        targetX = nodeMoveDeltaXabs -(desighWidth + mColSpace)
        bNew = true;
    elseif beginDelta.x > 0 and math.abs(beginDelta.x) >= mSlidDistance then
        targetX =(desighWidth + mColSpace) - nodeMoveDeltaXabs;
        bNew = true;
    else
        targetX = -(curPosX - self.mSpineAttachNodePosX);
    end

    if targetX ~= 0 then

        self:playChangeSpineAnim(targetX, bNew);
    else
        self.mbCanTouchSpineLayer = true;
    end
    self.mSpineAttachNodePosX = 0;
    return true;
end

function ActTimeLimit_139:playChangeSpineAnim(targetX, bNew)

    local function calcMoveInfo()
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local desighWidth, desighHeight = visibleSize.width, visibleSize.height;

        local bChange = false;
        local curRoleIdx = _type;

        local posX = 0;
        local bl = _serverData and _rewardConfig and #_rewardConfig and _ItemTabel and #_ItemTabel > 0
        bl = true
        if bl then
            if targetX < 0 then
                curRoleIdx = curRoleIdx + 1
                posX = desighWidth + mColSpace
            else
                curRoleIdx = curRoleIdx - 1
                posX = - desighWidth + mColSpace
            end

            bChange = true
            --            if curRoleIdx > #_rewardConfig then
            --                curRoleIdx = 1
            --            elseif curRoleIdx < 1 then
            --                curRoleIdx = #_rewardConfig
            --            end

            --            if mCurRoleIndex ~= curRoleIdx then
            --                if curRoleIdx == 0 then
            --                    bChange = true
            --                elseif #_rewardConfig > 0 then
            --                    bChange = true
            --                end
            --            end
        end
        return bChange, curRoleIdx, posX;
    end

    -- 需要预先计算一下是不是可以切换到下一个
    local bChange, curRoleIdx, posX = calcMoveInfo();
    local func = function(node)
        if bNew then
            if bChange then
                if curRoleIdx <= 0 then
                    curRoleIdx = #_rewardConfig
                elseif curRoleIdx > #_rewardConfig then
                    curRoleIdx = 1
                end
                local spineAttachNode = _spineNode
                -- spineAttachNode:setPosition(ccp(posX, 0));
                spineAttachNode:setPositionX(posX);
                -- mCurRoleIndex = curRoleIdx;
                self:changeType(CurContainer, curRoleIdx)
            end
        end

        -- local act1 = CCMoveTo:create(mSlidTimeIn, ccp(0, spineAttachNode:getPositionY()));
        local act1 = CCMoveTo:create(mSlidTimeIn, ccp(0, _spineNode:getPositionY()));
        local act2 = CCDelayTime:create(0.02);
        local act3 = CCCallFuncN:create( function(node)
            self.mbCanTouchSpineLayer = true;
            self.isRunAction = false
        end );

        local arr = CCArray:create();
        arr:addObject(act1);
        if bChange then
            arr:addObject(act2);
        end
        arr:addObject(act3);
        local spineAttachNode = _spineNode
        spineAttachNode:runAction(CCSequence:create(arr));
    end

    local act1 = CCMoveBy:create(mSlidTimeOut, ccp(targetX, 0));
    local act2 = CCDelayTime:create(0.02);
    local act3 = CCCallFuncN:create(func);
    local arr = CCArray:create();
    if bChange then
        arr:addObject(act1);
        arr:addObject(act2);
    end
    arr:addObject(act3);
    local spineAttachNode = _spineNode

    if not self.isRunAction then
        self.isRunAction = true
        spineAttachNode:runAction(CCSequence:create(arr));
    end
end



----------------------------------------------------------------------------------------

function ActTimeLimit_139FashionContent_onFunction(eventName, container)
    print("eventName ", eventName)
    if eventName == "luaOnAnimationDone" then

    elseif eventName == "onContentBtn" then
        local index = container.index
        if index then
            ActTimeLimit_139:SwitchIndex(index)
        end
    end
end


function ActTimeLimit_139:SwitchIndex(index)
    if _subType == index then
        return
    end
    local node = CurContainer:getVarNode("mContent_" .. _subType)
    if node then
        local head = node:getChildByTag(10086)
        if head then
            head:runAnimation("close")
        end
    end
    node = CurContainer:getVarNode("mContent_" .. index)
    if node then
        local head = node:getChildByTag(10086)
        if head then
            head:runAnimation("open")
        end
    end
    _subType = index
    ActTimeLimit_139:changeSubType(CurContainer, _subType)
end



function ActTimeLimit_139:onEnter(parentContainer)
    -- math.randomseed(os.time())

    local container = ScriptContentBase:create(option.ccbiFile)
    CurContainer = container
    luaCreat_ActTimeLimit_139(container)

    local s9Bg = container:getVarScale9Sprite("m_S9_1")
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)

    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mImage_2"))

    NodeHelper:setNodesVisible(CurContainer, { mBtmNode = false })
    NodeHelper:setNodesVisible(CurContainer, { mScrollNode = false })
    NodeHelper:setNodesVisible(CurContainer, { mArrowBtnNode = false })
    -- 没有活动剩余时间
    NodeHelper:setNodesVisible(CurContainer, { mActLeftTimeNode = false })

    local scale = NodeHelper:getScaleProportion()
    if scale > 1 then
        NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mSpineNode"), 0.5)
        NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mArrowBtnNode"), 0.5)
    elseif scale < 1 then
        NodeHelper:setNodeScale(container, "mSpineNode", scale, scale)
    end

    _spineNode = container:getVarNode("mSpineNode")

    self:registerPacket(parentContainer)
    self:initData()
    self:getPageInfo()
    -- self:initUi(container)
    self:createTouchLayer(container)

     self:initSpine(container)

    return container
end

function ActTimeLimit_139:getUserItemCount()
    if _serverData == nil then
        return 0
    end
    if PROP_ITEM_ID == 0 then
        PROP_ITEM_ID = ConfigManager.parseItemOnlyWithUnderline(_serverData.onceCostGold).itemId or 106103
    end
    local userItem = UserItemManager:getUserItemByItemId(PROP_ITEM_ID) or { }
    return userItem.count or 0
end

function ActTimeLimit_139:initData()
    PROP_ITEM_ID = 0
    _roleCfg = ConfigManager.getRoleCfg()
    _type = 0
    mCurRoleIndex = 0
    _subType = TreasureSearchType.SEARCHTYPE_SKIN
    _roleData = { }
    _rewardConfig = { }
    _roleNamePicPath = { }
    local configData = ConfigManager.getAct139Cfg()
    for k, data in pairs(configData) do
        if _rewardConfig[data.type] == nil then
            _rewardConfig[data.type] = { }
            _roleNamePicPath[data.type] = { }
            _roleData[data.type] = { }
        end

        --小奖池类型 = 1 的先过滤
        if data.subType ~= 1 then
           table.insert(_rewardConfig[data.type], data)
        end

        --table.insert(_rewardConfig[data.type], data)
        if data.roleNamePicPath ~= "0" and data.roleNamePicPath ~= "" then
            table.insert(_roleNamePicPath[data.type], data.roleNamePicPath)
        end
        if data.reward.type == 70000 and _roleCfg[data.reward.itemId] and data.mustBeType == 1 then
            --            if _roleData[data.type][data.subType] == nil then
            --                _roleData[data.type][data.subType] = { }
            --            end
            _roleData[data.type][data.subType] = data
--            local isFind = false
--            for index, item in pairs(_roleData) do
--                if item and item.reward and item.reward.itemId == data.reward.itemId then
--                    isFind = true
--                    break
--                end
--            end
--            if not isFind then
--                --table.insert(_roleData[data.type],data)

--                _roleData[data.type][data.subType] = data
--            end

--            -- 品质从低到高排序
--            table.sort(_roleData[data.type], function(data1, data2)
--                if data1 and data2 then
--                    local roleData1 = _roleCfg[data1.reward.itemId]
--                    local roleData2 = _roleCfg[data2.reward.itemId]
--                    return roleData1.quality < roleData2.quality
--                end
--            end )
        end
    end

    UserMercenaryManager:addSubscriber(thisPageName, ActTimeLimit_139.subscriberCallFun)
end


function ActTimeLimit_139:subscriberCallFun(data)
    -- 刷新碎片数量
    ActTimeLimit_139:updateMercenaryNumber()
    ActTimeLimit_139:updateTopMercenaryNumber()
end

function ActTimeLimit_139:initUi(container)
    self:changeType(container, 1)
    -- self:createItem(CurContainer)
    -- 动画
    -- self:initSpine(CurContainer)
    -- NodeHelper:setSpriteImage(CurContainer, { mRoleQualitySprite = ActTimeLimit_139:getRoleQualityImage() })
end


function ActTimeLimit_139:onReceiveMessage(container)
    --    local HP_pb = require("HP_pb");
    --    local message = container:getMessage();
    --    local typeId = message:getTypeId();
    --    if typeId == MSG_SEVERINFO_UPDATE then

    --    end
    --    if typeId == MSG_MAINFRAME_REFRESH then

    --    end
end



function ActTimeLimit_139:getPageInfo(container)
    -- 请求界面信息
    common:sendEmptyPacket(HP_pb.ACTIVITY138_RAIDER_INFO_C)
end

-- 收包
function ActTimeLimit_139:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()

    if opcode == HP_pb.ACTIVITY138_RAIDER_INFO_S then
        local msg = Activity4_pb.Activity138TreasureRaiderInfoSync()
        msg:ParseFromString(msgBuff)
        _serverData = msg
        self:initUi(CurContainer)
        self:refreshPage(CurContainer)
        -- common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        -- 刷新荧光棒数量
        NodeHelper:setStringForLabel(CurContainer, { mDiamondNum = self:getUserItemCount() })
    elseif opcode == HP_pb.ACTIVITY138_RAIDER_SEARCH_S then
        local msg = Activity4_pb.Activity138TreasureRaiderInfoSync()
        msg:ParseFromString(msgBuff)
        _serverData = msg

        _RewardItems = { }
        for i = 1, #_serverData.reward do
            table.insert(_RewardItems, _serverData.reward[i])
        end

        self:refreshPage(CurContainer)
        -- common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)

        if #_RewardItems > 0 then
            self:pushRewardPage()
        end

    elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        --        local msg = RoleOpr_pb.HPRoleInfoRes()
        --        msg:ParseFromString(msgBuff)
        --        UserMercenaryManager:setMercenaryStatusInfos(msg.roleInfos)
        --        _MercenaryRoleInfos = UserMercenaryManager:getMercenaryStatusInfos()
        --        _BasicsMercenaryData = UserMercenaryManager:getMercenaryStatusByItemId(_roleIds[1])
        --        -- 皮肤基础数据
        --         self:refreshItem(CurContainer)
    end
end


function ActTimeLimit_139:getMessage()
    local subType = TreasureSearchType.SEARCHTYPE_SKIN
    -- _subType
    return common:getLanguageString("@NeedXTimesGet", _serverData.leftAwardTimes, _roleCfg[ActTimeLimit_139:getRoleId(_type, subType)].name, _roleData[_type][subType].reward.count)
end

function ActTimeLimit_139:getRoleQualityImage()
    return _roleData[_type][_subType].roleNamePicPath
end

function ActTimeLimit_139:getHelpKey()
    local str = ""
    if _subType == 1 then
        str = GameConfig.HelpKey.HELP_ACT_139_1
    elseif _subType == 2 then
        str = GameConfig.HelpKey.HELP_ACT_139_2
    end
    return str
end

function ActTimeLimit_139:refreshMessage(container)
    NodeHelper:setStringForLabel(CurContainer, { mActDouble = ActTimeLimit_139:getMessage(_type, _subType) })
    NodeHelper:setStringForLabel(CurContainer, { mJumpText = common:getLanguageString(_roleData[_type][_subType].jumpText) })
end

function ActTimeLimit_139:getRoleId(type, subType)
    return _roleData[type][subType].reward.itemId
end

function ActTimeLimit_139:getRoleQuality(type, subType)
    local roleId = ActTimeLimit_139:getRoleId(type, subType)
    return _roleCfg[roleId].quality
end


-- 刷新页面
function ActTimeLimit_139:refreshPage(container, type)

    local label2Str = {
        mDiamondNum = self:getUserItemCount(),
        -- mPrice_1 = ConfigManager.parseItemOnlyWithUnderline(_serverData.onceCostGold).count,
        -- mPrice_2 = ConfigManager.parseItemOnlyWithUnderline(_serverData.tenCostGold).count,
        mFreelabel = common:getLanguageString("@SuitShootFree1Text"),
    }
    NodeHelper:setStringForLabel(CurContainer, label2Str)
    self:refreshMessage(CurContainer)

    -- 活动结束时间
    -- TimeCalculator:getInstance():createTimeCalcultor(self.endTimerCDKey, _serverData.leftTime)
    -- 刷新当前类型的免费时间
    if _serverData.freeCD > 0 and not TimeCalculator:getInstance():hasKey(self.freeTimerCKey) then
        -- 下次免费时间
        TimeCalculator:getInstance():createTimeCalcultor(self.freeTimerCKey, _serverData.freeCD)
    end

    if _serverData.freeCD <= 0 then
        -- 免费次数
        NodeHelper:setNodesVisible(CurContainer, { mBtnPriceNode_1 = false, mFreeLabel = true, mFreeTimeCDLabel = false })
    else
        -- 没有免费次数
        NodeHelper:setNodesVisible(CurContainer, { mBtnPriceNode_1 = true, mFreeLabel = false, mFreeTimeCDLabel = true })
    end

    self:refreshPrice(CurContainer)

    if _serverData.freeCD > 0 then
        ActivityInfo.changeActivityNotice(thisActivityId)
    end

    NodeHelper:setNodesVisible(CurContainer, { mBtmNode = true })
    NodeHelper:setNodesVisible(CurContainer, { mScrollNode = true })
    NodeHelper:setNodesVisible(CurContainer, { mArrowBtnNode = true })
end


function ActTimeLimit_139:getOnePrice()
    if _serverData == nil then
        return 0
    end
    return ConfigManager.parseItemOnlyWithUnderline(_serverData.onceCostGold).count
end

function ActTimeLimit_139:getTenPrice()
    if _serverData == nil then
        return 0
    end
    return ConfigManager.parseItemOnlyWithUnderline(_serverData.tenCostGold).count
end

function ActTimeLimit_139:refreshPrice(container)

    local label2Str = {
        mPrice_1 = ActTimeLimit_139:getOnePrice(),
        mPrice_2 = ActTimeLimit_139:getTenPrice(),
        -- mPrice_1 = _serverData.onceCostGold * Discount[_subType].mOnceDiscount,
        -- mPrice_2 = _serverData.tenCostGold * Discount[_subType].mTheDiscount,
    }
    NodeHelper:setStringForLabel(CurContainer, label2Str)

    ---------------------------------------------
    NodeHelper:setNodesVisible(CurContainer, { mOnceDiscountImage = Discount[_subType].mOnceDiscount < 1 })
    NodeHelper:setNodesVisible(CurContainer, { mTenDiscountImage = Discount[_subType].mTheDiscount < 1 })
    if _serverData.freeCD <= 0 then
        NodeHelper:setNodesVisible(CurContainer, { mOnceDiscountImage = false })
    end
    ---------------------------------------------
end

function ActTimeLimit_139:onTimer(container)
    if _serverData == nil then
        return
    end
    --    if not TimeCalculator:getInstance():hasKey(self.endTimerCDKey) then
    --        if _serverData.leftTime <= 0 then
    --            -- 活动结束了
    --            local endStr = common:getLanguageString("@ActivityEnd")
    --            NodeHelper:setStringForLabel(CurContainer, { mTanabataCD = endStr, mFreeTimeCDLabel = endStr })
    --            NodeHelper:setNodesVisible(container, {
    --                mFreeText = false,
    --                mCostNodeVar = true,
    --                mFreeTimeCDLabel = false,
    --            } )
    --        else
    --            if _serverData.leftTime < 0 then
    --                NodeHelper:setStringForLabel(CurContainer, { mTanabataCD = "" })
    --            end
    --        end
    --        return
    --    end

    --    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.endTimerCDKey)
    --    if remainTime + 1 > _serverData.leftTime then
    --        -- return
    --    end
    --    local timeStr = common:second2DateString(remainTime, false)
    --    NodeHelper:setStringForLabel(CurContainer, { mTanabataCD = common:getLanguageString("@SurplusTimeFishing") .. timeStr })

    --    if remainTime <= 0 then
    --        NodeHelper:setStringForLabel(CurContainer, { mTanabataCD = common:getLanguageString("@ActivityEnd") })
    --    end

    if TimeCalculator:getInstance():hasKey(self.freeTimerCKey) then
        local timerFreeCD = TimeCalculator:getInstance():getTimeLeft(self.freeTimerCKey);
        if timerFreeCD > 0 then
            timeStr = common:second2DateString(timerFreeCD, false);
            NodeHelper:setStringForLabel(container, { mFreeTimeCDLabel = common:getLanguageString("@SuitShootFreeOneTime", timeStr) })
            NodeHelper:setNodesVisible(container, { mFreeTimeCDLabel = true })
        else
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD);
            NodeHelper:setNodesVisible(CurContainer, {
                mFreeText = true,
                mCostNodeVar = false,
                mFreeTimeCDLabel = false,
            } )
            NodeHelper:setStringForLabel(CurContainer, { mFreeTimeCDLabel = common:getLanguageString("@ActivityEnd") })
        end
    end
end

    
function ActTimeLimit_139:refreshItem()

    if _ItemTabel == nil or #_ItemTabel == 0 then
        self:createItem(CurContainer)
    else
        for k, head in pairs(_ItemTabel) do
            -- local head = _ItemTabel[index]
            local roleId = _roleData[_type][k].reward.itemId

            local cfgInfo = _roleCfg[roleId]
            -- 设置背景
            local skinItemImgeData = ConfigManager.parseCfgWithComma(cfgInfo.avataBgPic)
            NodeHelper:setSpriteImage(head, { mRoleBG = skinItemImgeData[1], mRole = skinItemImgeData[2] })

            local name = cfgInfo.avatarName

            if name == "0" then
                NodeHelper:setStringForLabel(head, { mNameText_1 = "", mNameText_2 = cfgInfo.name })
            else
                NodeHelper:setStringForLabel(head, { mNameText_1 = cfgInfo.avatarName, mNameText_2 = cfgInfo.name })
            end

            local colorSprite = head:getVarSprite("mFrontColor")
            if colorSprite then
                local color = NodeHelper:_getColorFromSetting(spriteColor[cfgInfo.quality - 2])
                colorSprite:setColor(color)
            end

            local visibleMap = { }
            for i = 1, 4 do
                visibleMap["mQualityPic" .. i] = cfgInfo.quality - 2 == i
                visibleMap["mColor_" .. i] = cfgInfo.quality - 2 == i
            end
            visibleMap["mPoint"] = false
            local statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(roleId)
            if statusInfo then
                NodeHelper:setStringForLabel(head, { mIconNum = statusInfo.soulCount .. "/" .. statusInfo.costSoulCount })
            end

            NodeHelper:setNodesVisible(head, visibleMap)
            local currentRoleId = _roleData[_type][_subType].reward.itemId
            if statusInfo.itemId == _roleData[_type][_subType].reward.itemId then
                head:runAnimation("choice")
                -- ActTimeLimit_139:changeSubType(CurContainer, _subType)
            else
                head:runAnimation("Default Timeline")
            end
        end
        -- 刷新副将碎片
        self:updateMercenaryNumber()
        self:updateTopMercenaryNumber()
    end
end
function ActTimeLimit_139:createItem(container)
    _ItemTabel = { }
    for i = 1, 2 do
        local node = container:getVarNode("mContent_" .. i)
        local posX, posY = node:getPosition()
        node:setVisible(true)
        local head = ScriptContentBase:create("FashionContent.ccbi")
        head:setTag(10086)
        head:registerFunctionHandler(ActTimeLimit_139FashionContent_onFunction)
        head.index = i
        node:addChild(head)
        head:release()
        table.insert(_ItemTabel, head)
        --        local cfgInfo = _roleCfg[_RoleIds[i]]
        --        -- 设置背景
        --        local skinItemImgeData = ConfigManager.parseCfgWithComma(cfgInfo.avataBgPic)
        --        NodeHelper:setSpriteImage(head, { mRoleBG = skinItemImgeData[1], mRole = skinItemImgeData[2] })

        --        local name = cfgInfo.avatarName

        --        if name == "0" then
        --            NodeHelper:setStringForLabel(head, { mNameText_1 = "", mNameText_2 = cfgInfo.name })
        --        else
        --            NodeHelper:setStringForLabel(head, { mNameText_1 = cfgInfo.avatarName, mNameText_2 = cfgInfo.name })
        --        end

        --        local colorSprite = head:getVarSprite("mFrontColor")
        --        if colorSprite then
        --            local color = NodeHelper:_getColorFromSetting(spriteColor[cfgInfo.quality - 2])
        --            colorSprite:setColor(color)
        --        end

        --        local visibleMap = { }
        --        for i = 1, 4 do
        --            visibleMap["mQualityPic" .. i] = cfgInfo.quality - 2 == i
        --            visibleMap["mColor_" .. i] = cfgInfo.quality - 2 == i
        --        end
        --        visibleMap["mPoint"] = false
        --        local statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(_RoleIds[i])
        --        if statusInfo then
        --            NodeHelper:setStringForLabel(head, { mIconNum = statusInfo.soulCount .. "/" .. statusInfo.costSoulCount })
        --        end

        --        NodeHelper:setNodesVisible(head, visibleMap)
        --        if statusInfo.itemId == _RoleIds[_subType] then
        --            head:runAnimation("choice")
        --        end
    end

    self:refreshItem()
end


-- 显示抽奖界面
function ActTimeLimit_139:pushRewardPage()

    local data = { }
    data.freeCd = _serverData.freeCD
    data.onceGold = ActTimeLimit_139:getOnePrice()
    data.tenGold = ActTimeLimit_139:getTenPrice()
    data.itemId = nil
    data.rewards = _RewardItems

    local isFree = data.freeCd <= 0

    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, ActTimeLimit_139:getMessage(), false, ActTimeLimit_139.onBtnClick_1, ActTimeLimit_139.onBtnClick_2, function()
            if #_RewardItems == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
        end , Discount[_subType].mOnceDiscount, Discount[_subType].mTheDiscount , 3)
    else
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, ActTimeLimit_139:getMessage(), true, ActTimeLimit_139.onBtnClick_1, ActTimeLimit_139.onBtnClick_2, nil, Discount[_subType].mOnceDiscount, Discount[_subType].mTheDiscount  , 3)
    end
end

-- 奖励面板
function ActTimeLimit_139:popUpRewardPage(rewardItems)
    if rewardItems and #rewardItems > 0 then
        local CommonRewardPage = require("CommonRewardPage")
        CommonRewardPageBase_setPageParm(rewardItems, true, nil, nil)
        PageManager.pushPage("CommonRewardPage")
    end
end

function ActTimeLimit_139:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end

end

function ActTimeLimit_139:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_139:onExecute(parentContainer)
    self:onTimer(CurContainer)
end

function ActTimeLimit_139:onExit(parentContainer)
    _ItemTabel = nil
    UserMercenaryManager:removeSubscriber(thisPageName)
    _RewardItems = ""
    _serverData = nil
    _spineNode = nil
    TimeCalculator:getInstance():removeTimeCalcultor(self.freeTimerCKey)
    TimeCalculator:getInstance():removeTimeCalcultor(self.endTimerCDKey)
    local spineNode = CurContainer:getVarNode("mSpine")
    if spineNode then
        spineNode:removeAllChildren()
    end
    self:removePacket(parentContainer)
    _roleCfg = nil
    onUnload(thisPageName, CurContainer)
    mIsRoll = false
end

function ActTimeLimit_139:initSpine(container)

    local currentType = _type
    local currentSubType = _subType
    if _type <= 0 then
        currentType = 1
        currentSubType = 2
    end

    local spineNode = CurContainer:getVarNode("mSpineNode");
    local roleId = _roleData[currentType][currentSubType].reward.itemId
    local offset = _roleData[currentType][currentSubType].offset
    local spineScale = _roleData[currentType][currentSubType].scale
    local roleData = _roleCfg[roleId]
    if spineNode and roleData then
        spineNode:removeAllChildren()
        local dataSpine = common:split((roleData.spine), ",")
        local spinePath, spineName = dataSpine[1], dataSpine[2]
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode");

        spineNode:setScale(spineScale)

        spineNode:addChild(spineToNode);
        spine:runAnimation(1, "Stand", -1);

        local offset_X_Str, offset_Y_Str = unpack(common:split((offset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
    end
end


-- 更新佣兵碎片数量
function ActTimeLimit_139:updateMercenaryNumber()
    for k, v in pairs(_ItemTabel) do
        local statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(_roleData[_type][k].reward.itemId)
        if statusInfo then
            NodeHelper:setStringForLabel(v, { mIconNum = statusInfo.soulCount .. "/" .. statusInfo.costSoulCount })
        end
    end
    
end


function ActTimeLimit_139:updateTopMercenaryNumber()
    local statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(_roleData[_type][_subType].reward.itemId)
    if statusInfo then
        NodeHelper:setStringForLabel(CurContainer, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt") .. statusInfo.soulCount .. "/" .. statusInfo.costSoulCount })
    else
        NodeHelper:setStringForLabel(CurContainer, { mCoinNum = "" })
    end
end

function ActTimeLimit_139:changeCardImagePosition(container, type)



    local lastNode = nil
    local rightNode = { }
    local currentNode = nil
    local leftNode = { }


    for i = 4, 1, -1 do
        if i == type then
            NodeHelper:setSpriteImage(CurContainer, { ["mCardImage_" .. i] = "BG/Activity_139/Act_139_CardImage_" .. i .. "_S.png" })
        else
            NodeHelper:setSpriteImage(CurContainer, { ["mCardImage_" .. i] = "BG/Activity_139/Act_139_CardImage_" .. i .. "_N.png" })
        end

        local node = CurContainer:getVarNode("mCardImage_" .. i)
        if i == type then
            currentNode = node
        end

        if i > type then
            table.insert(rightNode, node)
        end
        if i < type then
            table.insert(leftNode, node)
        end

    end


    local offset = 6
    local pos_x = 0
    local width = 0
    for i = 4, 1, -1 do
        local node = CurContainer:getVarNode("mCardImage_" .. i)
        width = node:getContentSize().width
        NodeHelper:setNodePosition(node, pos_x, 0)
        pos_x = pos_x - width + offset
    end


    --    for i = 1, #rightNode do
    --        width = rightNode[i]:getContentSize().width
    --        NodeHelper:setNodePosition(rightNode[i], pos_x, 0)
    --        pos_x = pos_x - width + offset
    --    end

    --    width = currentNode:getContentSize().width
    --    NodeHelper:setNodePosition(currentNode, pos_x, 0)
    --    pos_x = pos_x - width + offset

    --    for i = 1, #leftNode do
    --        width = leftNode[i]:getContentSize().width
    --        NodeHelper:setNodePosition(leftNode[i], pos_x , 0)
    --        pos_x = pos_x - width + offset
    --    end
end

function ActTimeLimit_139:changeType(container, type)
    if _type == type then
        return
    end
    _type = type
    -- mCurRoleIndex = _type
    _subType = TreasureSearchType.SEARCHTYPE_SKIN
    NodeHelper:setSpriteImage(CurContainer, { mRoleQualitySprite = ActTimeLimit_139:getRoleQualityImage() })
    self:refreshItem()
    self:changeCardImagePosition(container, _type)
    self:changeSubType(container, _subType)
end

function ActTimeLimit_139:changeSubType(container, subType)
    _subType = subType
    ActTimeLimit_139:initSpine(CurContainer)
    ActTimeLimit_139:refreshMessage(CurContainer)
    ActTimeLimit_139:updateTopMercenaryNumber()
    ActTimeLimit_139:refreshPrice(CurContainer)

    local bl = _subType == TreasureSearchType.SEARCHTYPE_BASIC
    NodeHelper:setNodesVisible(CurContainer, { mMessageNode = not bl, btnNode_1 = not bl, btnNode_2 = not bl, mRewardBtnNode = not bl, mJumpNode = bl })

    -- NodeHelper:setSpriteImage(CurContainer, { mRoleQualitySprite = ActTimeLimit_139:getRoleQualityImage() })
end


function ActTimeLimit_139:onCard_1(container)
    if _serverData == nil then
        -- return
    end
    self:changeType(container, 1)
end

function ActTimeLimit_139:onCard_2(container)
    if _serverData == nil then
        -- return
    end
    self:changeType(container, 2)
end

function ActTimeLimit_139:onCard_3(container)
    if _serverData == nil then
        -- return
    end
    self:changeType(container, 3)
end

function ActTimeLimit_139:onCard_4(container)
    if _serverData == nil then
        -- return
    end
    self:changeType(container, 4)
end

function ActTimeLimit_139:onJump(container)
    if _serverData == nil then
        return
    end

    if true then
        return
    end

    local jumpId = _roleData[_type][_subType].jumpId
    if jumpId and jumpId > 0 then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(jumpId)
    end
end


function ActTimeLimit_139:onPropAdd(container)
    if _serverData == nil then
        return
    end
    -- 跳到福袋卖场
    ActivityInfo.jumpToActivityById(Const_pb.DISCOUNT_GIFT)
end

function ActTimeLimit_139:onArrowLeft(container)
    if _serverData == nil then
        -- return
    end

    local index = _type - 1
    if index <= 0 then
        index = #_rewardConfig
    end
    self:changeType(container, index)
end

function ActTimeLimit_139:onArrowRight(container)
    if _serverData == nil then
        -- return
    end
    local index = _type + 1
    if index > #_rewardConfig then
        index = 1
    end
    self:changeType(container, index)
end

function ActTimeLimit_139:onBtnClick_1(container)
    if _serverData == nil then
        return
    end

    if _subType == TreasureSearchType.SEARCHTYPE_SKIN then
        local roleInfo = UserMercenaryManager:getMercenaryStatusByItemId(_roleData[_type][TreasureSearchType.SEARCHTYPE_BASIC].reward.itemId)
        if roleInfo.soulCount < roleInfo.costSoulCount then
            MessageBoxPage:Msg_Box_Lan("@SkinGachaTip")
            ActTimeLimit_139:SwitchIndex(1)
            return
        end
    end

    if _serverData == nil then
        return
    end

    if _serverData.freeCD > 0 and ActTimeLimit_139:getUserItemCount() < ActTimeLimit_139:getOnePrice() then
        ActTimeLimit_139:showConfirm()
        -- common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    ActTimeLimit_139:sendDrawMessage(_type, 1)
end

function ActTimeLimit_139:onBtnClick_2(container)
    if _serverData == nil then
        return
    end

    if _subType == TreasureSearchType.SEARCHTYPE_SKIN then

        local roleInfo = UserMercenaryManager:getMercenaryStatusByItemId(_roleData[_type][TreasureSearchType.SEARCHTYPE_BASIC].reward.itemId)
        if roleInfo.soulCount < roleInfo.costSoulCount then
            MessageBoxPage:Msg_Box_Lan("@SkinGachaTip")
            ActTimeLimit_139:SwitchIndex(1)
            return
        end
    end

    if _serverData == nil then
        return
    end

    if ActTimeLimit_139:getUserItemCount() < ActTimeLimit_139:getTenPrice() then

        ActTimeLimit_139:showConfirm()

        -- common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    ActTimeLimit_139:sendDrawMessage(_type, 10)
end

-- 抽奖道具不足 ，跳转
function ActTimeLimit_139:showConfirm()
    local title = common:getLanguageString("@HintTitle")
    local message = common:getLanguageString("@NotEnoughItems")
    PageManager.showConfirm(title, message,
    function(agree)
        if agree then
            ActivityInfo.jumpToActivityById(Const_pb.DISCOUNT_GIFT)
        end
    end
    )
end

function ActTimeLimit_139:sendDrawMessage(searchType, searchTimes)
    local msg = Activity4_pb.Activity138TreasureRaiderSearch()
    msg.searchType = searchType
    msg.searchTimes = searchTimes
    common:sendPacket(HP_pb.ACTIVITY138_RAIDER_SEARCH_C, msg)
end


function ActTimeLimit_139:getRewardPreview()
    local t = { }
    local t1 = { }
    local returnTabel = { }
    for k, v in pairs(ConfigManager.getAct135Cfg()) do
        if v.id ~= 1001 then
            table.insert(t, v)
        end
    end

    if _subType == 1 then
        -- 副将的奖励
        for k, v in pairs(t) do
            if v.type == 1 or v.type == 2 then
                table.insert(t1, v)
            end
        end

    elseif _subType == 2 then
        -- 皮肤的奖励
        for k, v in pairs(t) do
            if v.type == 3 or v.type == 4 then
                table.insert(t1, v)
            end
        end
    end

    for k, v in pairs(t1) do
        local t2 = { type = v.type, data = ConfigManager.parseItemOnlyWithUnderline(v.rewards) }
        table.insert(returnTabel, t2)
    end

    return returnTabel
end

function ActTimeLimit_139:onFashion(container)
    local info = UserMercenaryManager:getMercenaryStatusByItemId(_roleData[_type][_subType].reward.itemId)
    if info then
        require("FashionPage")
        FashionPageBase_setCurMercenaryInfo(info, ActTimeLimit_139.FashionPageCloseFunc)
        PageManager.changePage("FashionPage")
    end
end


function ActTimeLimit_139:FashionPageCloseFunc()

    require("GashaponPage")
    GashaponPage_setPart(thisActivityId)
    GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
    GashaponPage_setTitleStr("@NiuDanTitle")
    PageManager.changePage("GashaponPage")
    resetMenu("mGuildPageBtn", true)

    --    require("LimitActivityPage")
    --    local ActionLog_pb = require("ActionLog_pb")

    --    LimitActivityPage_setPart(thisActivityId)
    --    LimitActivityPage_setIds(ActivityInfo.LimitPageIds)
    --    LimitActivityPage_setCurrentPageType(1)
    --    LimitActivityPage_setTitleStr("@FixedTimeActTitle")
    --    PageManager.changePage("LimitActivityPage")
end

function ActTimeLimit_139:onRewardPreview(container)

    -- ActivityInfo.jumpToActivityById(95)

    --    if LLLL == nil then
    --        return
    --    end

    require("NewSnowPreviewRewardPage")
    local TreasureCfg = _rewardConfig[_type]
    local commonRewardItems = { }
    local luckyRewardItems = { }
    if TreasureCfg ~= nil then
        for _, item in ipairs(TreasureCfg) do
            if item.mustBeType == 1 then
                table.insert(commonRewardItems, {
                    type = tonumber(item.reward.type),
                    itemId = tonumber(item.reward.itemId),
                    count = tonumber(item.reward.count)
                } );
            else
                table.insert(luckyRewardItems, {
                    type = tonumber(item.reward.type),
                    itemId = tonumber(item.reward.itemId),
                    count = tonumber(item.reward.count)
                } );
            end
        end
    end
    local helpKey = _roleData[_type][_subType].helpTxt

    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", helpKey)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end

local CommonPage = require('CommonPage')
ActTimeLimit_139 = CommonPage.newSub(ActTimeLimit_139, thisPageName, option)

return ActTimeLimit_139