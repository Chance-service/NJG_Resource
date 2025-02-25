-- 抽皮肤  仮装パーティ
local NodeHelper = require("NodeHelper")
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "ActSkinDraw"
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")
local ResManagerForLua = require("ResManagerForLua")
local thisActivityId = 117      -- 这个活动的活动id
local ActSkinDraw = { }
local mConstCount_1 = 0
local mConstCount_2 = 0


local Discount = {
    [1] = { mOnceDiscount = 1, mTheDiscount = 1 },
    [2] = { mOnceDiscount = 1, mTheDiscount = 1 }
}

-- 抽卡类型
TreasureSearchType = {
    SEARCHTYPE_BASIC = 1,
    SEARCHTYPE_SKIN = 2
}

local _SelecetIndex = 1     -- 当前选择的类型
local _RoleIds = nil
local _RoleCfg = nil
local _MercenaryRoleInfos = { }
local _ItemTabel = { }
local _RewardItems = { }

ActSkinDraw.freeTimerCKey = "Activity_ActSkinDraw_FreeTimerCDKey"
ActSkinDraw.endTimerCDKey = "AceSkinDrawEndTimer"

local option = {
    ccbiFile = "Act_SkinDraw.ccbi",
    handlerMap = {
        onRewardPreview = "onRewardPreview",
        onFashion = "onFashion",
        onBtnClick_1 = "onBtnClick_1",
        onBtnClick_2 = "onBtnClick_2"
    }
}

-- local _SpineData = { [1] = { offset = "0,20", spineScale = 1 }, [2] = { offset = "0,30", spineScale = 0.8 } }
local _SpineData = nil
local mItemTag = {
    IconBgSprite = 1000,
    IconSprite = 2000,
    QualitySprite = 3000,
    NumLabel = 4000,
    Mask = 5000,
}

local opcodes = {
    NEW_TREASURE_RAIDER_INFO2_C = HP_pb.NEW_TREASURE_RAIDER_INFO2_C,
    -- 请求info
    NEW_TREASURE_RAIDER_INFO2_S = HP_pb.NEW_TREASURE_RAIDER_INFO2_S,
    -- info返回
    NEW_TREASURE_RAIDER_SEARCH2_C = HP_pb.NEW_TREASURE_RAIDER_SEARCH2_C,
    -- 点击抽卡
    NEW_TREASURE_RAIDER_SEARCH2_S = HP_pb.NEW_TREASURE_RAIDER_SEARCH2_S,
    -- 点击抽卡返回
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,-- 副将信息返回
}

local ServerData = nil
local spriteColor = { "23 213 254", "197 23 254", "252 254 114", "255 51 51" }
local CurContainer = nil


function ActSkinDrawFashionContent_onFunction(eventName, container)
    print("eventName ", eventName)
    if eventName == "luaOnAnimationDone" then

    elseif eventName == "onContentBtn" then
        local index = container.index
        if index then
            ActSkinDraw:SwitchIndex(index)
        end
    end
end

function ActSkinDraw:SwitchIndex(index)
    if _SelecetIndex == index then
        return
    end
    local node = CurContainer:getVarNode("mContent_" .. _SelecetIndex)
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
    _SelecetIndex = index

    -- ActSkinDraw:refreshPage(CurContainer)
    ActSkinDraw:initSpine(CurContainer)
    ActSkinDraw:refreshMessage(CurContainer)
    ActSkinDraw:updateTopMercenaryNumber()
    ActSkinDraw:refreshPrice(CurContainer)
end

function ActSkinDraw:onEnter(parentContainer)
    -- math.randomseed(os.time())
    local container = ScriptContentBase:create(option.ccbiFile)
    CurContainer = container
    luaCreat_ActSkinDraw(container)

    local s9Bg = container:getVarScale9Sprite("m_S9_1")
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mImage_2"))
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)


    NodeHelper:setNodesVisible(CurContainer, { mBtmNode = false })


    local scale = NodeHelper:getScaleProportion()
    if scale > 1 then
        NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mSpineBg"), 0.5)
    elseif scale < 1 then
        NodeHelper:setNodeScale(self.container, "mSpineNode", scale, scale)
        -- NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mLuckDrawNode"))
    end

    self:registerPacket(parentContainer)
    self:initData()
    self:getPageInfo()
    self:initUi(container)

    return container
end

function ActSkinDraw:initData()
    _BasicsMercenaryData = nil
    _RewardItems = { }
    _ItemTabel = { }
    -- _SelecetIndex = TreasureSearchType.SEARCHTYPE_BASIC
    _SelecetIndex = TreasureSearchType.SEARCHTYPE_SKIN
    -- 副将碎片信息
    _MercenaryRoleInfos = UserMercenaryManager:getMercenaryStatusInfos()
    -- 副将信息
    _RoleCfg = ConfigManager.getRoleCfg()
    -- 本期抽奖可以获得的副将
    _RoleIds = self:getRoleData()
    -- 本期抽奖可以获得的奖励
    -- TreasureRaiderDataHelper.TreasureRaiderConfig = ConfigManager.getReleaseURdrawRewardCfg() or { }

    _SpineData = { }
    for k, v in pairs(ConfigManager.getActSkinDrawCfg()) do
        if v.type == 2 then
            mConstCount_1 = ConfigManager.parseItemOnlyWithUnderline(v.rewards).count
        end

        if v.type == 4 then
            mConstCount_2 = ConfigManager.parseItemOnlyWithUnderline(v.rewards).count
        end
        if v.id == 2000 then
            _SpineData[1] = { offset = v.offset, spineScale = v.scale }
        end

        if v.id == 3000 then
            _SpineData[2] = { offset = v.offset, spineScale = v.scale }
        end
    end

end

function ActSkinDraw:initUi(container)
    self:initSpine(CurContainer)
    NodeHelper:setSpriteImage(CurContainer, { mRoleQualitySprite = ActSkinDraw:getRoleQualityImage() })
end

function ActSkinDraw:getRoleData()
    local t = ConfigManager.getActSkinDrawCfg()
    local id = 0
    for k, v in pairs(t) do
        if v.id == 1001 then
            id = v.type
            break
        end
    end

    local id1 = ConfigManager.getRoleCfg()[id].modelId

    return { [1] = id, [2] = id1 }
end

function ActSkinDraw:setRollItemData(item, data)
    local iconBgSprite = tolua.cast(item:getChildByTag(mItemTag.IconBgSprite), "CCSprite")
    local iconSprite = tolua.cast(item:getChildByTag(mItemTag.IconSprite), "CCSprite")
    local qualitySprite = tolua.cast(item:getChildByTag(mItemTag.QualitySprite), "CCSprite")
    local numLabel = tolua.cast(item:getChildByTag(mItemTag.NumLabel), "CCLabelTTF")
    local maskSprite = tolua.cast(item:getChildByTag(mItemTag.Mask), "CCSprite")

    iconSprite:setTexture(data.icon)
    numLabel:setString("x" .. GameUtil:formatNumber(data.count))

    local colorStr = ConfigManager.getQualityColor()[data.quality].textColor
    local color3B = NodeHelper:_getColorFromSetting(colorStr)
    numLabel:setColor(color3B)

    local qualityImage = NodeHelper:getImageByQuality(data.quality)
    qualitySprite:setTexture(qualityImage)

    local iconBgImage = NodeHelper:getImageBgByQuality(data.quality)
    iconBgSprite:setTexture(iconBgImage)
end

function ActSkinDraw:getTableLen(t)
    local index = 0
    for k, v in pairs(t) do
        index = index + 1
    end
    return index
end

function ActSkinDraw:getPageInfo(container)
    -- 请求界面信息
    common:sendEmptyPacket(HP_pb.NEW_TREASURE_RAIDER_INFO2_C)

    --- 请求副将信息
    -- common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    if not _MercenaryRoleInfos or #_MercenaryRoleInfos == 0 then
        --- 请求副将信息
        -- common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    end
end

-- 收包
function ActSkinDraw:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()

    if opcode == HP_pb.NEW_TREASURE_RAIDER_INFO2_S then
        local msg = Activity2_pb.HPNewTreasureRaiderInfoSync2()
        msg:ParseFromString(msgBuff)
        ServerData = msg
        self:refreshPage(CurContainer)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH2_S then
        local msg = Activity2_pb.HPNewTreasureRaiderInfoSync2()
        msg:ParseFromString(msgBuff)
        ServerData = msg

        _RewardItems = { }
        for i = 1, #ServerData.reward do
            table.insert(_RewardItems, ServerData.reward[i])
        end

        self:refreshPage(CurContainer)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)

        if #_RewardItems > 0 then
            self:pushRewardPage()
        end

    elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(msgBuff)
        UserMercenaryManager:setMercenaryStatusInfos(msg.roleInfos)
        _MercenaryRoleInfos = UserMercenaryManager:getMercenaryStatusInfos()
        _BasicsMercenaryData = UserMercenaryManager:getMercenaryStatusByItemId(_RoleIds[1])
        -- 皮肤基础数据
        self:refreshItem(CurContainer)
    end
end


function ActSkinDraw:getMessage()
    local str = ""
    if _SelecetIndex == 1 then
        str = common:getLanguageString("@NeedXTimesGet", ServerData.basicLeftAwardTimes, _RoleCfg[_RoleIds[_SelecetIndex]].name, mConstCount_1)
    elseif _SelecetIndex == 2 then
        str = common:getLanguageString("@NeedXTimesGet", ServerData.skinLeftAwardTimes, _RoleCfg[_RoleIds[_SelecetIndex]].name, mConstCount_2)
    end
    return str
end

function ActSkinDraw:getRoleQualityImage()
    return GameConfig.ActivityRoleQualityImage[_RoleCfg[_RoleIds[_SelecetIndex]].quality]
end

function ActSkinDraw:getHelpKey()
    local str = ""
    if _SelecetIndex == 1 then
        str = GameConfig.HelpKey.HELP_ACT_117_1
    elseif _SelecetIndex == 2 then
        str = GameConfig.HelpKey.HELP_ACT_117_2
    end
    return str
end

function ActSkinDraw:refreshMessage(container)
    NodeHelper:setStringForLabel(CurContainer, { mActDouble = ActSkinDraw:getMessage() })
    NodeHelper:setSpriteImage(CurContainer, { mRoleQualitySprite = ActSkinDraw:getRoleQualityImage() })
end

-- 刷新页面
function ActSkinDraw:refreshPage(container)

    local label2Str = {
        mDiamondNum = UserInfo.playerInfo.gold,
        -- 设置玩家金币数量
        mPrice_1 = ServerData.onceCostGold,
        mPrice_2 = ServerData.tenCostGold,
        mFreelabel = common:getLanguageString("@SuitShootFree1Text"),
        -- mActDouble = ActSkinDraw:getMessage()
    }
    NodeHelper:setStringForLabel(CurContainer, label2Str)
    self:refreshMessage(CurContainer)

    -- 活动结束时间
    TimeCalculator:getInstance():createTimeCalcultor(self.endTimerCDKey, ServerData.leftTime)
    if ServerData.leftTime > 0 and not TimeCalculator:getInstance():hasKey(self.endTimerCDKey) then

    end

    if ServerData.freeCD > 0 and not TimeCalculator:getInstance():hasKey(self.freeTimerCKey) then
        -- 下次免费时间
        TimeCalculator:getInstance():createTimeCalcultor(self.freeTimerCKey, ServerData.freeCD)
    end

    if ServerData.freeCD <= 0 then
        -- 免费次数
        NodeHelper:setNodesVisible(CurContainer, { mBtnPriceNode_1 = false, mFreeLabel = true, mFreeTimeCDLabel = false })
    else
        -- 没有免费次数
        NodeHelper:setNodesVisible(CurContainer, { mBtnPriceNode_1 = true, mFreeLabel = false, mFreeTimeCDLabel = true })
    end

    self:refreshPrice(CurContainer)

    if ServerData.freeCD > 0 then
        ActivityInfo.changeActivityNotice(thisActivityId)
    end

    NodeHelper:setNodesVisible(CurContainer, { mBtmNode = true })

    -- self:refreshItem(CurContainer)
end

function ActSkinDraw:refreshPrice(container)
    local label2Str = {
        mPrice_1 = ServerData.onceCostGold * Discount[_SelecetIndex].mOnceDiscount,
        mPrice_2 = ServerData.tenCostGold * Discount[_SelecetIndex].mTheDiscount,
    }
    NodeHelper:setStringForLabel(CurContainer, label2Str)

    ---------------------------------------------
    NodeHelper:setNodesVisible(CurContainer, { mOnceDiscountImage = Discount[_SelecetIndex].mOnceDiscount < 1 })
    NodeHelper:setNodesVisible(CurContainer, { mTenDiscountImage = Discount[_SelecetIndex].mTheDiscount < 1 })
    if ServerData.freeCD <= 0 then
        NodeHelper:setNodesVisible(CurContainer, { mOnceDiscountImage = false })
    end
    ---------------------------------------------
end

function ActSkinDraw:onTimer(container)
    if ServerData == nil then
        return
    end
    if not TimeCalculator:getInstance():hasKey(self.endTimerCDKey) then
        if ServerData.leftTime <= 0 then
            -- 活动结束了
            local endStr = common:getLanguageString("@ActivityEnd")
            NodeHelper:setStringForLabel(CurContainer, { mTanabataCD = endStr, mFreeTimeCDLabel = endStr })
            NodeHelper:setNodesVisible(container, {
                mFreeText = false,
                mCostNodeVar = true,
                mFreeTimeCDLabel = false,
            } )
        else
            if ServerData.leftTime < 0 then
                NodeHelper:setStringForLabel(CurContainer, { mTanabataCD = "" })
            end
        end
        return
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.endTimerCDKey)
    if remainTime + 1 > ServerData.leftTime then
        -- return
    end
    local timeStr = common:second2DateString(remainTime, false)
    NodeHelper:setStringForLabel(CurContainer, { mTanabataCD = common:getLanguageString("@SurplusTimeFishing") .. timeStr })

    if remainTime <= 0 then
        NodeHelper:setStringForLabel(CurContainer, { mTanabataCD = common:getLanguageString("@ActivityEnd") })
    end

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


function ActSkinDraw:refreshItem(container)
    if _ItemTabel == nil or #_ItemTabel == 0 then
        self:createItem(container)
    end
    -- 刷新副将碎片
    self:updateMercenaryNumber()
end
function ActSkinDraw:createItem(container)


    _ItemTabel = { }
    local visibleMap = { }
    local node, head, statusInfo, colorSprite, cfgInfo
    for i = 1, 2 do
        cfgInfo = _RoleCfg[_RoleIds[i]]
        node = container:getVarNode("mContent_" .. i)
        local posX, posY = node:getPosition()
        node:setVisible(true)
        head = ScriptContentBase:create("FashionContent.ccbi")
        head:setTag(10086)
        head:registerFunctionHandler(ActSkinDrawFashionContent_onFunction)
        head.index = i
        node:addChild(head)
        head:release()
        colorSprite = head:getVarSprite("mFrontColor")
        -- 设置背景
        local skinItemImgeData = ConfigManager.parseCfgWithComma(cfgInfo.avataBgPic)
        -- , mName = "Fashion_Font_" .. v.itemId .. ".png",
        NodeHelper:setSpriteImage(head, { mRoleBG = skinItemImgeData[1], mRole = skinItemImgeData[2] })

        local name = cfgInfo.avatarName

        if name == "0" then
            -- NodeHelper:setStringForLabel(head, { mNameText_1 = cfgInfo.name, mNameText_2 = "" })
            NodeHelper:setStringForLabel(head, { mNameText_1 = "", mNameText_2 = cfgInfo.name })
        else
            NodeHelper:setStringForLabel(head, { mNameText_1 = cfgInfo.avatarName, mNameText_2 = cfgInfo.name })
        end

        if colorSprite then
            local color = NodeHelper:_getColorFromSetting(spriteColor[cfgInfo.quality - 2])
            colorSprite:setColor(color)
            -- colorSprite:setColor(spriteColor[cfgInfo.quality - 2])
        end
        for i = 1, 4 do
            visibleMap["mQualityPic" .. i] = cfgInfo.quality - 2 == i
            visibleMap["mColor_" .. i] = cfgInfo.quality - 2 == i
        end
        visibleMap["mPoint"] = false
        statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(_RoleIds[i])
        if statusInfo then
            NodeHelper:setStringForLabel(head, { mIconNum = statusInfo.soulCount .. "/" .. statusInfo.costSoulCount })
        end

        NodeHelper:setNodesVisible(head, visibleMap)
        if statusInfo.itemId == _RoleIds[_SelecetIndex] then
            head:runAnimation("choice")
        end

        table.insert(_ItemTabel, head)
    end
end

-- 显示抽奖界面
function ActSkinDraw:pushRewardPage()

    local data = { }
    data.freeCd = ServerData.freeCD
    data.onceGold = ServerData.onceCostGold
    data.tenGold = ServerData.tenCostGold
    data.itemId = nil
    data.rewards = _RewardItems

    local isFree = data.freeCd <= 0

    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, ActSkinDraw:getMessage(), false, ActSkinDraw.onBtnClick_1, ActSkinDraw.onBtnClick_2, function()
            if #_RewardItems == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
        end , Discount[_SelecetIndex].mOnceDiscount, Discount[_SelecetIndex].mTheDiscount)
    else
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, ActSkinDraw:getMessage(), true, ActSkinDraw.onBtnClick_1, ActSkinDraw.onBtnClick_2, nil, Discount[_SelecetIndex].mOnceDiscount, Discount[_SelecetIndex].mTheDiscount)
    end
end

function ActSkinDraw:isContain(t, n)
    for k, v in pairs(t) do
        if v == n then
            return true
        end
    end
    return false
end

-- 奖励面板
function ActSkinDraw:popUpRewardPage(rewardItems)
    if rewardItems and #rewardItems > 0 then
        local CommonRewardPage = require("CommonRewardPage")
        CommonRewardPageBase_setPageParm(rewardItems, true, nil, nil)
        PageManager.pushPage("CommonRewardPage")
    end
end

function ActSkinDraw:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActSkinDraw:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActSkinDraw:onExecute(parentContainer)
    self:onTimer(CurContainer)
end

function ActSkinDraw:onExit(parentContainer)
    _RewardItems = ""
    ServerData = nil
    TimeCalculator:getInstance():removeTimeCalcultor(self.freeTimerCKey)
    TimeCalculator:getInstance():removeTimeCalcultor(self.endTimerCDKey)
    local spineNode = CurContainer:getVarNode("mSpine")
    if spineNode then
        spineNode:removeAllChildren()
    end
    self:removePacket(parentContainer)
    _RoleCfg = nil
    onUnload(thisPageName, CurContainer)
    mIsRoll = false
end

function ActSkinDraw:initSpine(container)
    local spineNode = CurContainer:getVarNode("mSpineNode")
    local offset = _SpineData[_SelecetIndex].offset
    local spineScale = _SpineData[_SelecetIndex].spineScale

    local roleData = ConfigManager.getRoleCfg()[_RoleIds[_SelecetIndex]]
    if spineNode and roleData then
        spineNode:removeAllChildren()
        local dataSpine = common:split((roleData.spine), ",")
        local spinePath, spineName = dataSpine[1], dataSpine[2]
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode")

        spineNode:setScale(spineScale)

        -- spineToNode:setScale(spineScale)
        spineNode:addChild(spineToNode)
        spine:runAnimation(1, "Stand", -1)

        -- spineToNode:setPosition(ccp(s9Sprite:getContentSize().width / 2, s9Sprite:getContentSize().height / 2))
        local offset_X_Str, offset_Y_Str = unpack(common:split((offset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))

        --        local scale = NodeHelper:getScaleProportion()
        --        if scale > 1 then
        --            NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mSpineBg"), 0.5)
        --        elseif scale < 1 then
        --            NodeHelper:setNodeScale(self.container, "mSpineNode", scale, scale)
        --            -- NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mLuckDrawNode"))
        --        end
    end
end


-- 更新佣兵碎片数量
function ActSkinDraw:updateMercenaryNumber()
    for k, v in pairs(_ItemTabel) do
        local statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(_RoleIds[k])
        if statusInfo then
            NodeHelper:setStringForLabel(v, { mIconNum = statusInfo.soulCount .. "/" .. statusInfo.costSoulCount })
        end
    end
    ActSkinDraw:updateTopMercenaryNumber()
end

function ActSkinDraw:updateTopMercenaryNumber()
    local statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(_RoleIds[_SelecetIndex])
    if statusInfo then
        NodeHelper:setStringForLabel(CurContainer, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt") .. statusInfo.soulCount .. "/" .. statusInfo.costSoulCount })
    else
        NodeHelper:setStringForLabel(CurContainer, { mCoinNum = "" })
    end
end


function ActSkinDraw:onBtnClick_1(container)
    if _BasicsMercenaryData == nil then
        return
    end

    if _SelecetIndex == TreasureSearchType.SEARCHTYPE_SKIN then
        if _BasicsMercenaryData.soulCount < _BasicsMercenaryData.costSoulCount then
            MessageBoxPage:Msg_Box_Lan("@SkinGachaTip")
            ActSkinDraw:SwitchIndex(1)
            return
        end
    end

    if ServerData == nil then
        return
    end


    if ServerData.freeCD > 0 and UserInfo.playerInfo.gold < ServerData.onceCostGold * Discount[_SelecetIndex].mOnceDiscount then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    ActSkinDraw:sendDrawMessage(_SelecetIndex, 1)
end

function ActSkinDraw:onBtnClick_2(container)
    if _BasicsMercenaryData == nil then
        return
    end

    if _SelecetIndex == TreasureSearchType.SEARCHTYPE_SKIN then
        if _BasicsMercenaryData.soulCount < _BasicsMercenaryData.costSoulCount then
            MessageBoxPage:Msg_Box_Lan("@SkinGachaTip")
            ActSkinDraw:SwitchIndex(1)
            return
        end
    end

    if ServerData == nil then
        return
    end

    if UserInfo.playerInfo.gold < ServerData.tenCostGold * Discount[_SelecetIndex].mTheDiscount then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    ActSkinDraw:sendDrawMessage(_SelecetIndex, 10)
end

function ActSkinDraw:sendDrawMessage(searchType, searchTimes)
    local msg = Activity2_pb.HPNewTreasureRaiderSearch2()
    msg.searchType = searchType
    msg.searchTimes = searchTimes
    common:sendPacket(HP_pb.NEW_TREASURE_RAIDER_SEARCH2_C, msg)
end

function ActSkinDraw:getRewardPreview()
    local t = { }
    local t1 = { }
    local returnTabel = { }
    for k, v in pairs(ConfigManager.getActSkinDrawCfg()) do
        if v.id ~= 1001 then
            table.insert(t, v)
        end
    end

    if _SelecetIndex == 1 then
        -- 副将的奖励
        for k, v in pairs(t) do
            if v.type == 1 or v.type == 2 then
                table.insert(t1, v)
            end
        end

    elseif _SelecetIndex == 2 then
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

function ActSkinDraw:onFashion(container)
    local info = UserMercenaryManager:getMercenaryStatusByItemId(_RoleIds[_SelecetIndex])
    if info then
        require("FashionPage")
        FashionPageBase_setCurMercenaryInfo(info, ActSkinDraw.FashionPageCloseFunc)
        PageManager.changePage("FashionPage")
    end
end

function ActSkinDraw:FashionPageCloseFunc()
    require("GashaponPage")
    GashaponPage_setPart(thisActivityId)
    GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
    GashaponPage_setTitleStr("@NiuDanTitle")
    PageManager.changePage("GashaponPage")
    resetMenu("mGuildPageBtn", true)

    --    require("LimitActivityPage")
    --    local ActionLog_pb = require("ActionLog_pb")

    --    LimitActivityPage_setPart(thisActivityId)
    --    LimitActivityPage_setIds(ActivityInfo.NovicePageIds)
    --    LimitActivityPage_setCurrentPageType(1)
    --    LimitActivityPage_setTitleStr("@FixedTimeActTitle")
    --    PageManager.changePage("LimitActivityPage")
end

function ActSkinDraw:onRewardPreview(container)
    require("NewSnowPreviewRewardPage")
    local TreasureCfg = self:getRewardPreview()
    local commonRewardItems = { }
    local luckyRewardItems = { }
    if TreasureCfg ~= nil then
        for _, item in ipairs(TreasureCfg) do
            if item.type == 2 or item.type == 4 then
                table.insert(commonRewardItems, {
                    type = tonumber(item.data.type),
                    itemId = tonumber(item.data.itemId),
                    count = tonumber(item.data.count)
                } )
            else
                table.insert(luckyRewardItems, {
                    type = tonumber(item.data.type),
                    itemId = tonumber(item.data.itemId),
                    count = tonumber(item.data.count)
                } )
            end
        end
    end
    local helpKey = ActSkinDraw:getHelpKey()

    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", helpKey)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end

local CommonPage = require('CommonPage')
ActSkinDraw = CommonPage.newSub(ActSkinDraw, thisPageName, option)

return ActSkinDraw