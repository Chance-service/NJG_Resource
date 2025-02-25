----------------------------------------------------------------------------------
--[[
        以后这个就当做抽卡通用的界面
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local UserMercenaryManager = require("UserMercenaryManager")
local MercenaryCfg = nil
local thisPageName = "CommonRewardAniPage"
local UserItemManager = require("Item.UserItemManager")
local self_container = nil
local option = {
    ccbiFile = "Act_TimeLimitKingPalaceRewardAni.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onFree = "onFree",
        onDiamond = "onDiamond",
        onSkip = "onSkip"
    },
}

local opcodes = {
    -- 副将信息请求
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    -- 副将信息返回
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    -- 激活副將請求
    ROLE_EMPLOY_C = HP_pb.ROLE_EMPLOY_C,
    -- 激活副將返回
    ROLE_EMPLOY_S = HP_pb.ROLE_EMPLOY_S,
}


local mItemTag = {
    IconBgSprite = 1000,
    IconSprite = 2000,
    QualitySprite = 3000,
    NumLabel = 4000,
    ChangeSprite = 5000,
}


for i = 1, 11 do
    option.handlerMap["onHand" .. i] = "onHand";
end

local mRewardItemMoveEndPos = { }
local mCurrentShowIndex = 1
----------------- local data -----------------
local CommonRewardAniPage = { }

local MercenaryRoleInfos = { }

local getNewEmpolyAni ={}

local thisActivityInfo = {
    rewardItems = { },
    inAni = false,
}

local isPop = false
-- 消耗类型
local mPriceType = {
    -- 钻石
    Diamonds = 1,
    -- 金币
    Gold = 2,
    --荧光棒
    LightStick = 3,
    --瓶蓋
    Candy = 4,
}

local draw_spine = nil

local mPriceTypeImage = { [1] = "2.png", [2] = "1.png" ,[3] = "I_106103.png", [4] = "Item/I_250011.png"}

function CommonRewardAniPage:onSkip(container)
    NodeHelper:setNodesVisible(container, { mSpineNode = false})
    local spineNode = container:getVarNode("mSpineNode")
    spineNode:stopAllActions()
    draw_spine:stopAllAnimations()
    self:refreshRewardNode(self_container);
end

function CommonRewardAniPage:playDrawSpine(container)
    local isRoleItem = false
    for i, dataStr in ipairs(thisActivityInfo.reward) do
        local _type, _id, _count ,_change= unpack(common:split(dataStr, "_"))
        if (tonumber(_type) == 70000) or (_change) then
            isRoleItem = true
            break
        end
    end

    if (isRoleItem == true) then
        thisActivityInfo.inAni = true
        NodeHelper:setNodesVisible(container, { mSpineNode = true})
        local Fundraw = CCCallFunc:create( function()
            draw_spine:runAnimation(1,"animation1",0)
        end)
        local Funend = CCCallFunc:create( function()
            self:onSkip(self_container)
        end)

        local array = CCArray:create()
        array:addObject(Fundraw)
        array:addObject(CCDelayTime:create(11))
        array:addObject(Funend)

        local spineNode = container:getVarNode("mSpineNode")
        spineNode:runAction(CCSequence:create(array))
    else
        self:onSkip(self_container)   
    end
end

function CommonRewardAniPage:onClose(container)
    if thisActivityInfo.inAni then return end
    PageManager.popPage(thisPageName);
end


function CommonRewardAniPage:onHand(container, eventName)
    local index = tonumber(string.sub(eventName, 7, string.len(eventName)))
    local dataIndex = index
    if index > 10 then dataIndex = index % 10 end
    if thisActivityInfo.rewardItems[dataIndex] then
        GameUtil:showTip(container:getVarNode('mPic' .. index), thisActivityInfo.rewardItems[dataIndex])
    end
end

function CommonRewardAniPage:onFree(container)
    if thisActivityInfo.inAni then return end
    if thisActivityInfo.oneFunc == nil then
        CommonRewardAniPage:voidFunc()
    else
        thisActivityInfo.oneFunc()
    end
end

function CommonRewardAniPage:onDiamond(container)
    if thisActivityInfo.inAni then return end

    if thisActivityInfo.tenFunc == nil then
        CommonRewardAniPage:voidFunc()
    else
        thisActivityInfo.tenFunc(thisActivityInfo.callFunData)
    end
end

---------------------------------------------------------------

function CommonRewardAniPage:onEnter(container)
    isPop = true
    MercenaryCfg = ConfigManager.getRoleCfg()
    self.container = container
    self_container = container
    self:registerPacket(container)
    thisActivityInfo.inAni = false

    local SpineNode = container:getVarNode("mSpine");
    local spinePath ="Spine/sb_lottery"
    local spineName ="sb_lottery"
    draw_spine = SpineContainer:create(spinePath, spineName)
    local stoNode = tolua.cast(draw_spine, "CCNode");
    SpineNode:addChild(stoNode)


    ----------------------------------------------------------
    for i = 1, 10 do
        local node = container:getVarNode("mRewardNode" .. i)
        node:removeAllChildren()
        local x = node:getPositionX()
        local y = node:getPositionY()
        mRewardItemMoveEndPos[i] = ccp(x, y)
    end

    local node = container:getVarNode("mRewardNode11")
    node:removeAllChildren()
    local x = node:getPositionX()
    local y = node:getPositionY()
    mRewardItemMoveEndPos[11] = ccp(x, y)
    self:removeRewardNodeAllChildren()
    if #thisActivityInfo.reward > 0 then
        self:playDrawSpine(container)
    end

    ----------------------------------------------------------
    self:refreshPage(container);
end

-- function CommonRewardAniPage:refreshRewardNode(container)
--    local rewardItems = { }
--    for i, v in ipairs(thisActivityInfo.reward) do
--        rewardItems[i] = ConfigManager.parseItemOnlyWithUnderline(v)
--    end
--    thisActivityInfo.rewardItems = rewardItems
--    thisActivityInfo.inAni = true
--    if #thisActivityInfo.reward == 1 then
--        NodeHelper:fillRewardItemWithParams(container, rewardItems, #rewardItems, { startIndex = 11, frameNode = "mHand", countNode = "mNumber" })
--        container:runAnimation("Gacha1")
--    else
--        NodeHelper:fillRewardItemWithParams(container, rewardItems, #rewardItems, { startIndex = 1, frameNode = "mHand", countNode = "mNumber" })
--        container:runAnimation("Gacha10")
--    end
-- end

function CommonRewardAniPage:refreshPage_Discard(container)

    NodeHelper:setStringForLabel(container, { mCostNum = thisActivityInfo.oneGold, mDiamondText = thisActivityInfo.tenGold, mRewardTxt = thisActivityInfo.strDes })
    local isFree = false
    if thisActivityInfo.isFree then
        isFree = true
    end
    NodeHelper:setNodesVisible(container, { mCostNodeVar = not isFree, mOneBtnText = isFree })

    --------------------------------------------
    NodeHelper:setNodesVisible(container, { mOnceDiscountImage = thisActivityInfo.onceDiscount < 1 })
    NodeHelper:setNodesVisible(container, { mTenDiscountImage = thisActivityInfo.theDiscount < 1 })
    if thisActivityInfo.isFree then
        NodeHelper:setNodesVisible(container, { mOnceDiscountImage = false })
    end
    -------------------------------------------
end


function CommonRewardAniPage:refreshPage(container)
    -- 价格
    NodeHelper:setStringForLabel(container, { mCostNum = thisActivityInfo.oneGold * thisActivityInfo.onceDiscount, mDiamondText = thisActivityInfo.tenGold * thisActivityInfo.theDiscount, mRewardTxt = thisActivityInfo.strDes })
    NodeHelper:setMenuItemEnabled(container, "mFree", true)
    NodeHelper:setMenuItemEnabled(container, "mDiamond", true)
    NodeHelper:setNodeIsGray(container, { mOneBtnText = false, mTenBtnText = false })
    -- 折扣角标
    NodeHelper:setNodesVisible(container, { mOnceDiscountImage = thisActivityInfo.onceDiscount < 1 })
    NodeHelper:setNodesVisible(container, { mTenDiscountImage = thisActivityInfo.theDiscount < 1 })
    if thisActivityInfo.isFree then
        -- 有免费次数不显示折扣角标
        NodeHelper:setNodesVisible(container, { mOnceDiscountImage = false })
    end
    -- 消耗类型
    NodeHelper:setSpriteImage(container, { mPriceType_1 = mPriceTypeImage[thisActivityInfo.priceTyep], mPriceType_2 = mPriceTypeImage[thisActivityInfo.priceTyep] })

    if thisActivityInfo.lastCount < 0 then
        -- 不限制次数
        NodeHelper:setNodesVisible(container, { mCostNodeVar = true, mTenNodeVar = true })
        -- 是否免费  这里只控制抽一次的免费次数
        if thisActivityInfo.isFree then
            -- 1回無料
            NodeHelper:setStringForLabel(container, { mOneBtnText = common:getLanguageString("@GachaFreeTxt") })
        end
        NodeHelper:setNodesVisible(container, { mCostNodeVar = not thisActivityInfo.isFree, mOneBtnText = thisActivityInfo.isFree })
    else
        -- 有限制次数
        if thisActivityInfo.lastCount <= 0 then
            -- 回数不足
            NodeHelper:setMenuItemEnabled(container, "mFree", false)
            NodeHelper:setMenuItemEnabled(container, "mDiamond", false)
            NodeHelper:setStringForLabel(container, { mOneBtnText = common:getLanguageString("@MultiEliteTimeNotEnoughTitle") })
            NodeHelper:setStringForLabel(container, { mTenBtnText = common:getLanguageString("@MultiEliteTimeNotEnoughTitle") })
            NodeHelper:setNodeIsGray(container, { mOneBtnText = true, mTenBtnText = true })
            NodeHelper:setNodesVisible(container, { mCostNodeVar = false, mTenNodeVar = false, mOneBtnText = true, mTenBtnText = true })
        else
            -- 还有剩余次数
            if thisActivityInfo.lastCount >= thisActivityInfo.maxCount then
                -- 可以十连抽
                NodeHelper:setStringForLabel(container, { mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", thisActivityInfo.maxCount) })
                NodeHelper:setStringForLabel(container, { mDiamondText = thisActivityInfo.oneGold * thisActivityInfo.maxCount })
            else
                -- 抽剩下的次数
                NodeHelper:setStringForLabel(container, { mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", thisActivityInfo.lastCount) })
                NodeHelper:setStringForLabel(container, { mDiamondText = thisActivityInfo.oneGold * thisActivityInfo.lastCount })
            end
        end
    end
end


function CommonRewardAniPage:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "Gacha1" or animationName == "Gacha10" then
        thisActivityInfo.inAni = false

        if thisActivityInfo.aniEndCall then
            thisActivityInfo.aniEndCall()
            thisActivityInfo.aniEndCall = nil
        end
    end
end

function CommonRewardAniPage:onExit(container)
    thisActivityInfo.rewardItems = { }
    MercenaryRoleInfos = { }
    getNewEmpolyAni = {}
    isPop = false
    MercenaryCfg = nil
    self_container = nil
    self:removePacket(container)
    onUnload(thisPageName, container)
end

function CommonRewardAniPage:isPop()
    return isPop
end

function CommonRewardAniPage:voidFunc()
end

---------------------------------------------------------------------------

function CommonRewardAniPage:removeRewardNodeAllChildren()
    local mAllRewardNode = self.container:getVarNode("mAllRewardNode11")
    mAllRewardNode:removeAllChildren()
end

function CommonRewardAniPage:setItemChange()
    local mAllRewardNode = self.container:getVarNode("mAllRewardNode11")
    local allItem = mAllRewardNode:getChildren()
    for i = 0, allItem:count() -1 do
        local oneItem = tolua.cast(allItem:objectAtIndex(i), "CCNode")
        local ChangeSprite = tolua.cast(oneItem:getChildByTag(mItemTag.ChangeSprite), "CCSprite")
        local data = self:formatRollItemData(thisActivityInfo.reward[i+1])
        if (data.change) then
            AnimMgr:getInstance():fadeInAndOut(ChangeSprite, 1.5);
        end
    end
end

function CommonRewardAniPage:EndCall()
    if thisActivityInfo.aniEndCall then
        thisActivityInfo.aniEndCall()
        thisActivityInfo.aniEndCall = nil
    end
end

function CommonRewardAniPage:createAction(time, scale, rotate, endPosition, fun)
    local scaleTo = CCScaleTo:create(time, scale)
    -- local rotateTo = CCRotateTo:create(time, rotate)
    local rotateBy = CCRotateBy:create(time, rotate)
    local moveTo = CCMoveTo:create(time, endPosition)
    local callFunc = CCCallFunc:create( function()
        if fun ~= nil then
            -- fun()
            mCurrentShowIndex = mCurrentShowIndex + 1
            self:refreshRewardNode()
        else
            thisActivityInfo.inAni = false
            mCurrentShowIndex = 1
            self:EndCall()
            self:setItemChange()
            self:callEnterEmpoly()
        end
    end )

    local array = CCArray:create()
    array:addObject(scaleTo)
    array:addObject(rotateBy)
    -- array:addObject(rotateTo)
    array:addObject(moveTo)
    local spawn = CCSpawn:create(array)

    local array1 = CCArray:create();
    array1:addObject(spawn)
    array1:addObject(callFunc)
    local sequence = CCSequence:create(array1)

    return sequence
end

function CommonRewardAniPage:refreshRewardNode(container)
    thisActivityInfo.inAni = true
    local mAllRewardNode = self.container:getVarNode("mAllRewardNode11")
    if #thisActivityInfo.reward == 1 then
        local node = self:createRewardItem(1)
        mAllRewardNode:addChild(node)
        node:setPosition(ccp(0, 200))
        node:setScale(0.1)
        node:runAction(self:createAction(0.2, 1, 360, mRewardItemMoveEndPos[11], nil))
        self:setRollItemData(node, self:formatRollItemData(thisActivityInfo.reward[1]), ConfigManager.parseItemOnlyWithUnderline(thisActivityInfo.reward[1]))
    else

        local data = thisActivityInfo.reward[mCurrentShowIndex]
        -- local data, index = self:deQueue()
        if data ~= nil then
            local node = self:createRewardItem(1)
            mAllRewardNode:addChild(node)
            node:setPosition(ccp(0, 200))
            node:setScale(0.1)
            node:runAction(self:createAction(0.2, 1, 360, mRewardItemMoveEndPos[mCurrentShowIndex], 1))
            self:setRollItemData(node, self:formatRollItemData(data), ConfigManager.parseItemOnlyWithUnderline(data))
        else
            -- 动画结束
            thisActivityInfo.inAni = false
            mCurrentShowIndex = 1
            self:EndCall()
            self:setItemChange()
            self:callEnterEmpoly()
        end
    end
end

function CommonRewardAniPage:formatRollItemData(dataStr)
    local _type, _id, _count,_change = unpack(common:split(dataStr, "_"))

    local data = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_count))

    if _change then
        data.change = tonumber(_change)
    end

    return data
end

function CommonRewardAniPage:setRollItemData(item, data, tipsData)

    local iconBgSprite = tolua.cast(item:getChildByTag(mItemTag.IconBgSprite), "CCSprite")
    local iconSprite = tolua.cast(item:getChildByTag(mItemTag.IconSprite), "CCSprite")
    local qualitySprite = tolua.cast(item:getChildByTag(mItemTag.QualitySprite), "CCSprite")
    local numLabel = tolua.cast(item:getChildByTag(mItemTag.NumLabel), "CCLabelBMFont")
    local ChangeSprite = tolua.cast(item:getChildByTag(mItemTag.ChangeSprite), "CCSprite")


    iconSprite:setTexture(data.icon)

    if (data.change) then
        local changedata = ResManagerForLua:getResInfoByTypeAndId(70000, data.change, 1)
        ChangeSprite:setTexture(changedata.icon)
    end

    numLabel:setString("x" .. GameUtil:formatNumber(data.count))

    local colorStr = ConfigManager.getQualityColor()[data.quality].textColor
    local color3B = NodeHelper:_getColorFromSetting(colorStr)
    -- numLabel:setColor(color3B)

    local qualityImage = NodeHelper:getImageByQuality(data.quality)
    qualitySprite:setTexture(qualityImage)

    local iconBgImage = NodeHelper:getImageBgByQuality(data.quality)
    iconBgSprite:setTexture(iconBgImage)

    self:addRewardClick(item, iconSprite, tipsData)

end

function CommonRewardAniPage:createRewardItem(index)
    local node = CCNode:create()
    local bgSprite = CCSprite:create("common_ht_propK_diban.png")
    node:addChild(bgSprite, 0, 1000)

    local iconSprite = CCSprite:create("UI/Mask/Image_Empty.png")
    node:addChild(iconSprite, 1, mItemTag.IconSprite)

    -- local numTTFLabel = CCLabelTTF:create("x", "Barlow-SemiBold.ttf", 16)
    local numTTFLabel = CCLabelBMFont:create("x", "Lang/Font-HT-Button-White.fnt")
    numTTFLabel:setScale(0.55)
    numTTFLabel:setAnchorPoint(ccp(1, 0))
    numTTFLabel:setPosition(ccp(37, -38))
    node:addChild(numTTFLabel, 2, mItemTag.NumLabel)

    local ChangeSprite = CCSprite:create("UI/Mask/Image_Empty.png")
    node:addChild(ChangeSprite, 3, mItemTag.ChangeSprite)

    local qualitySprite = CCSprite:create("common_ht_propK_bai.png")
    node:addChild(qualitySprite, 4, mItemTag.QualitySprite)

    return node
end

function CommonRewardAniPage:addRewardClick(parentNode, node, tipsData)
    local menu = CCMenu:create()
    local function itemSelector()
        GameUtil:showTip(node, tipsData)
    end
    local item = CCMenuItemImage:create("common_ht_propK_bai.png", "common_ht_propK_bai.png")
    item:registerScriptTapHandler(itemSelector)
    menu:addChild(item)
    item:setPosition(ccp(0, 0))
    parentNode:addChild(menu)
    menu:setPosition(ccp(0, 0))
end 

--------------------------------------------------------------------------------

function CommonRewardAniPage:setFirstData(data, reward, oneFunc, tenFunc, priceType, isRefresh, aniEndCall)
    thisActivityInfo.data = data or { }
    thisActivityInfo.reward = reward or { }
    thisActivityInfo.oneFunc = oneFunc
    thisActivityInfo.tenFunc = tenFunc
    thisActivityInfo.aniEndCall = aniEndCall
    -- 一次价格
    thisActivityInfo.oneGold = data.onceGold or 100
    -- 多次价格
    thisActivityInfo.tenGold = data.tenGold or 100
    -- 是否免费
    thisActivityInfo.isFree = data.isFree
    -- 剩余免费次数
    thisActivityInfo.freeCount = data.freeCount or 0
    -- 描述
    thisActivityInfo.strDes = data.strDes or ""
    -- 一次折扣
    thisActivityInfo.onceDiscount = data.onceDiscount or 1
    -- 多次折扣
    thisActivityInfo.theDiscount = data.theDiscount or 1
    -- 消耗类型
    thisActivityInfo.priceTyep = priceType or 1
    -- 剩余抽奖次数
    thisActivityInfo.lastCount = data.lastCount or -1
    -- 最大抽奖次数
    thisActivityInfo.maxCount = data.maxCount or 10
    if isRefresh and self_container then
        -- 如果已经有界面 直接刷新
        self:removeRewardNodeAllChildren()
        self:refreshPage(self_container);
        self:playDrawSpine(self_container);
    end
end

--
function CommonRewardAniPage:setFirstDataNew(oneGold, tenGold, reward, isFree, freeCount, strDes, isRefresh, oneFunc, tenFunc, aniEndCall, onceDiscount, theDiscount, priceTyep, lastCount)
    thisActivityInfo.oneGold = oneGold or 100
    thisActivityInfo.tenGold = tenGold or 100
    thisActivityInfo.reward = reward or { }
    thisActivityInfo.isFree = isFree
    thisActivityInfo.freeCount = freeCount or 0
    thisActivityInfo.strDes = strDes or ""
    thisActivityInfo.oneFunc = oneFunc
    thisActivityInfo.tenFunc = tenFunc
    thisActivityInfo.aniEndCall = aniEndCall
    thisActivityInfo.onceDiscount = onceDiscount or 1
    thisActivityInfo.theDiscount = theDiscount or 1
    thisActivityInfo.priceTyep = priceTyep or 1
    thisActivityInfo.lastCount = lastCount or -1
    if isRefresh and self_container then
        -- 如果已经有界面 直接刷新
        self:removeRewardNodeAllChildren()
        self:refreshPage(self_container);
        self:playDrawSpine(self_container)
    end
end

function CommonRewardAniPage:setPageData(data, isRefresh)
    -- 一次价格
    thisActivityInfo.oneGold = data.oneGold or 100
    -- 多次价格
    thisActivityInfo.tenGold = data.tenGold or 100
    -- 奖励
    thisActivityInfo.reward = data.reward or { }
    -- 是否免费
    thisActivityInfo.isFree = data.isFree
    -- 剩余免费次数
    thisActivityInfo.freeCount = data.freeCount or 0
    -- 描述
    thisActivityInfo.strDes = data.strDes or ""
    -- 一次回调
    thisActivityInfo.oneFunc = data.oneFunc
    -- 多次回调
    thisActivityInfo.tenFunc = data.tenFunc
    -- 抽奖动画结束后回调
    thisActivityInfo.aniEndCall = data.aniEndCall
    -- 一次折扣
    thisActivityInfo.onceDiscount = data.onceDiscount or 1
    -- 多次折扣
    thisActivityInfo.theDiscount = data.theDiscount or 1
    -- 消耗类型
    thisActivityInfo.priceTyep = data.priceTyep or 1
    -- 剩余抽奖次数
    thisActivityInfo.lastCount = data.lastCount or -1
    -- 最大抽奖次数
    thisActivityInfo.maxCount = data.maxCount or 10
    if isRefresh and self_container then
        -- 如果已经有界面 直接刷新
        self:removeRewardNodeAllChildren()
        self:refreshPage(self_container);
        self:playDrawSpine(self_container);
    end
end

function CommonRewardAniPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function CommonRewardAniPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function CommonRewardAniPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        -- 副将信息返回
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(msgBuff)
        MercenaryRoleInfos = msg.roleInfos
        UserMercenaryManager:setMercenaryStatusInfos(MercenaryRoleInfos)
        if (CommonRewardAniPage:getStagecount() == 0 ) then
            CommonRewardAniPage:getNewRolecheck()
        end
    elseif opcode == HP_pb.ROLE_EMPLOY_S then
        local msg = RoleOpr_pb.HPRoleEmploy();
        msg:ParseFromString(msgBuff);
        local roleId = msg.roleId
        local curMercenary = UserMercenaryManager:getUserMercenaryById(roleId)
        if curMercenary == nil then return end
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        local MercenaryGetNewRolePage = require("MercenaryGetNewRolePage");
        MercenaryGetNewRolePage:setFirstData(curMercenary.itemId)
        if (CommonRewardAniPage:getStagecount() > 0 ) then
            MercenaryGetNewRolePage:setCloseCall(CommonRewardAniPage.callEnterEmpoly)
        else
            MercenaryGetNewRolePage:setCloseCall(nil)
        end
        PageManager.pushPage("MercenaryGetNewRolePage")
    end
end

function CommonRewardAniPage:getNewRolecheck(container)
    -- 只留可激活的傭兵
    local t = { }
    for k, v in pairs(MercenaryRoleInfos) do
        if v.roleStage == 2 then
            while true do
                if (FetterManager.getIllCfgByRoleId(v.itemId).isSkin == 1) then --isskin need check original role
                    local roleId = ConfigManager.getRoleCfg()[v.itemId].FashionInfos[2]
                    local originalid = UserMercenaryManager:getUserMercenaryByItemId(roleId)-- have role
                    if originalid == nil then break end -- continue
                end
                table.insert(t, v)
                break
            end
        end
    end
    MercenaryRoleInfos = t

    if #MercenaryRoleInfos == 0 then return end

    for i = 1, #MercenaryRoleInfos do
--      if (i == 1) then
--        self:EnterEmploy(MercenaryRoleInfos[i].roleId)
--      else
        getNewEmpolyAni[MercenaryRoleInfos[i].itemId] = MercenaryRoleInfos[i].roleId
--      end
    end
end

function CommonRewardAniPage:callEnterEmpoly()
    --local MercenaryGetNewRolePage = require("MercenaryGetNewRolePage");
    --local count = CommonRewardAniPage:getStagecount()
    --local key
    --if (count > 0 ) then
    --    for k, v in pairs(getNewEmpolyAni) do
    --        key = k
    --        CommonRewardAniPage:EnterEmploy(v)
    --        break
    --    end
    --    getNewEmpolyAni[key] = nil
    --    if (count == 1) then
    --        MercenaryGetNewRolePage:setCloseCall(nil)
    --    end   
    --else
    --    MercenaryGetNewRolePage:setCloseCall(nil)
    --end
end

function CommonRewardAniPage:getStagecount()
    local count = 0
    for k, v in pairs(getNewEmpolyAni) do
        count = count+1
    end
    return count
end

function CommonRewardAniPage:EnterEmploy(roleid)
    local msg = RoleOpr_pb.HPRoleEmploy()
    msg.roleId = roleid
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.ROLE_EMPLOY_C, pb, #pb, true)
end

local CommonPage = require("CommonPage");
local CommonRewardAniPage = CommonPage.newSub(CommonRewardAniPage, thisPageName, option)
return CommonRewardAniPage
