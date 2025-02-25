

local TalentManager = require("PlayerInfo.TalentManager")
local ElementManager = require("Element.ElementManager")
local UserInfo = require("PlayerInfo.UserInfo")
local ViewPlayerInfo = require("PlayerInfo.ViewPlayerInfo")
local ElementConfig = require("Element.ElementConfig")
local EquipScriptData = require("EquipScriptData")
local ActivityData = require("ActivityData")
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper");
local Player_pb = require("Player_pb");
local Const_pb = require("Const_pb");
local RoleOpr_pb = require("RoleOpr_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local FormationManager = require("FormationManager")
local RoleManager = require("PlayerInfo.RoleManager");
local ViewPlayerEquipmentPageBase = { }--
local option = {
    ccbiFile = "EquipmentPage.ccbi",
    handlerMap =
    {
        onReturnBtn = "onClose",

        -- onHelp      = "onHelp",
        onPersonalConfidence = "onPersonalConfidence",
    },
    opcodes =
    {
        -- ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
        -- ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
        -- ROLE_EMPLOY_C = HP_pb.ROLE_EMPLOY_C,
        -- ROLE_EMPLOY_S = HP_pb.ROLE_EMPLOY_S,
    }
}
local thisPageName = "ViewPlayerEquipmentPage";
local thisPageContainer = nil
local mSubNode = nil
local fOneItemWidth = 0
local mercenaryHeadContent = {
    -- 佣兵数据
    ccbiFile = "EquipmentPageMercenaryPortraitContent.ccbi"
}
local _mercenaryInfos = { }-- 佣兵数据表
local _mercenaryContainerInfo = { }-- 记录所有的佣兵节点对象，数据更新时 不必rebuild
local _curSelectId = 0;-- 当前选择的佣兵id
local _curRoleInfo = { }  -- 当前佣兵的信息
local _curSelectContainer = nil -- 当前选择的佣兵Container
local _RoleEmploy = {
    -- 记录上次激活的佣兵，在下次收到panel包时做逻辑处理
    _lastUnlockRoleId = 0,
    -- 上次解锁的佣兵id，
    _lastUnlockSucces = false,-- 是否解锁成功
}
local _showFateSubPage = false
------------------------------------------------------------------------------
------------------------------------------------------------------------------
local mColSpace = 200;
local mSlidTimeOut = 0.15; -- 滑动时候切换时候 出屏滚动的时间 单位秒
local mSlidTimeIn = 0.3; -- 滑动时候切换时候 入屏滚动的时间 单位秒
local mSlidDistance = 120; -- 滑动时候切换时候 切换角色的阈值
local mCurRoleIndex = 0;

function ViewPlayerEquipmentPageBase:createTouchLayer(container)
    local touchLayer = tolua.cast(container:getVarNode("mTouchLayer"), "CCLayerColor");
    touchLayer:setOpacity(0);
    touchLayer:setTouchEnabled(true)
    touchLayer:setTouchMode(kCCTouchesOneByOne);
    touchLayer:registerScriptTouchHandler( function(eventType, touch)
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

function ViewPlayerEquipmentPageBase:onLayerTouchBegan(touch)
    local bCanTouch = self.mbCanTouchSpineLayer;
    if self.mbCanTouchSpineLayer then
        self.mbCanTouchSpineLayer = false;
        local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode();
        local spinePosX, spinePoxY = spineAttachNode:getPosition();
        self.mSpineAttachNodePosX = spinePosX;
        self.mTouchStartLocation = touch:getLocation();
    end
    return bCanTouch;
end

function ViewPlayerEquipmentPageBase:onLayerTouchMoved(touch)
    local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local desighWidth, desighHeight = visibleSize.width, visibleSize.height;

    local lpos = touch:getLocation();
    local lspos = self.mTouchStartLocation;
    local beginDelta = { x = lpos.x - lspos.x, y = lpos.y - lspos.y };

    if math.abs(beginDelta.x) >= desighWidth then
        return true;
    end

    local moveDelta = touch:getDelta();
    local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode();
    local curPosX, curPosY = spineAttachNode:getPosition();
    spineAttachNode:setPositionX(moveDelta.x + curPosX);
    return true;
end

function ViewPlayerEquipmentPageBase:onLayerTouchEnded(touch)
    local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local desighWidth, desighHeight = visibleSize.width, visibleSize.height;

    local lpos = touch:getLocation();
    local lspos = self.mTouchStartLocation;
    local beginDelta = { x = lpos.x - lspos.x, y = lpos.y - lspos.y };
    local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode();
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

function ViewPlayerEquipmentPageBase:playChangeSpineAnim(targetX, bNew)

    local function calcMoveInfo()
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local desighWidth, desighHeight = visibleSize.width, visibleSize.height;

        local bChange = false;
        local curRoleIdx = mCurRoleIndex;
        local posX = 0;
        if _mercenaryInfos.roleInfos and self.mAllRoleItem and #self.mAllRoleItem > 0 then
            if targetX < 0 then
                curRoleIdx = curRoleIdx + 1;
                posX = desighWidth + mColSpace;
            else
                curRoleIdx = curRoleIdx - 1;
                posX = - desighWidth + mColSpace;
            end

            if curRoleIdx > #_mercenaryInfos.roleInfos then
                curRoleIdx = #_mercenaryInfos.roleInfos;
            elseif curRoleIdx < 0 then
                curRoleIdx = 0;
            end

            if mCurRoleIndex ~= curRoleIdx then
                if curRoleIdx == 0 then
                    bChange = true;
                elseif #_mercenaryInfos.roleInfos > 0 and _mercenaryInfos.roleInfos[curRoleIdx] then
                    bChange = true;
                end
            end
        end
        return bChange, curRoleIdx, posX;
    end

    -- 需要预先计算一下是不是可以切换到下一个
    local bChange, curRoleIdx, posX = calcMoveInfo();
    local func = function(node)
        if bNew then
            if bChange then
                if curRoleIdx == 0 then
                    self:selectMainPlayer();
                else
                    if #_mercenaryInfos.roleInfos > 4 then
                        thisPageContainer.mScrollView:locateToByIndex(curRoleIdx - 1);
                    end
                    local item = self.mAllRoleItem[curRoleIdx];
                    if item then
                        item.cls:onMercenary(item.node:getCCBFileNode());
                    end
                end
                local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode();
                -- spineAttachNode:setPosition(ccp(posX, 0));
                spineAttachNode:setPositionX(posX);
                mCurRoleIndex = curRoleIdx;
            end
        end

        local act1 = CCMoveTo:create(mSlidTimeIn, ccp(0, 0));
        local act2 = CCDelayTime:create(0.02);
        local act3 = CCCallFuncN:create( function(node)
            self.mbCanTouchSpineLayer = true;
        end );

        local arr = CCArray:create();
        arr:addObject(act1);
        if bChange then
            arr:addObject(act2);
        end
        arr:addObject(act3);
        local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode();
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
    local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode();
    spineAttachNode:runAction(CCSequence:create(arr));
end


function ViewPlayerEquipmentPageBase:relocateCurSelItem(roleInfos)
    for i = 1, #roleInfos do
        if roleInfos[i].roleId == _curSelectId then
            mCurRoleIndex = i;
            break;
        end
    end
end

-- the end
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
function ViewPlayerEquipmentPageBase:onEnter(container)
    _showFateSubPage = false
    thisPageContainer = container
    _curSelectId = 0
    mCurRoleIndex = 0;
    self.mAllRoleItem = { };
    _curSelectContainer = nil
    EquipScriptData._curRoleType = EquipScriptData._roleType.ROLE_LEAD
    _mercenaryContainerInfo = { }
    thisPageContainer:runAnimation("RoleChoose")
    container:registerMessage(MSG_SEVERINFO_UPDATE);
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    NodeHelper:initScrollView(container, "mPortrait", 4)
    mSubNode = container:getVarNode("mContentNode")
    -- 绑定子页面ccb的节点
    if mSubNode then
        mSubNode:removeAllChildren()
    end
    NodeHelper:setNodesVisible(container, { mArrowBtnNode = false })
    self:registerPacket(container)
    ----
    self:refreshPage(container);
    -- 获取佣兵列表信息
    -- common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    -- 设置玩家头像
    local prof = ViewPlayerInfo:getRoleInfo().prof
    local info = ViewPlayerInfo:getRoleInfo()
    local showCfg = LeaderAvatarManager.getOthersShowCfg(info.avatarId)
    local icon = showCfg.icon[prof]
    -- local icon = RoleManager:getIconById(ViewPlayerInfo:getRoleInfo().itemId)--(UserInfo.roleInfo.itemId);
    NodeHelper:setSpriteImage(container, { mPlayerSprite = icon });
    NodeHelper:setNodesVisible(container, { mArrowLeft = false, mArrowRight = false, mLookOverInfoNode = true, mLookOverCloseNode = true, mReturnNode = false })
    NodeHelper:setStringForLabel(container, { mTitle = tostring(Language:getInstance():getString("@EquipmentOtherTitle")) })
    self:initMercenaryInfo(container)

    if #_mercenaryInfos.roleInfos <= 4 then
        container.mScrollView:setTouchEnabled(false)
    else
        container.mScrollView:setTouchEnabled(true)
    end
end

function ViewPlayerEquipmentPageBase:getMercenaryFightRoleInfoList()
    _mercenaryInfos.roleInfos = { }
    local roleFightingIdList = ViewPlayerInfo:getMercenaryFightingId()
    local roleFightingRoleInfoList = ViewPlayerInfo:getMercenaryInfo()
    for i = 1, #roleFightingIdList do
        for j = 1, #roleFightingRoleInfoList do
            if roleFightingRoleInfoList[j].itemId == roleFightingIdList[i] then
                table.insert(_mercenaryInfos.roleInfos, roleFightingRoleInfoList[j])
                break;
            end
        end
    end
    local FetterManager = require("FetterManager")
    FetterManager.setCurOtherRoleInfo(_mercenaryInfos.roleInfos)
end

function ViewPlayerEquipmentPageBase:initMercenaryInfo(container)
    self:getMercenaryFightRoleInfoList();
    -- sortData(_mercenaryInfos.roleInfos);
    self:rebuildAllItem(container)
    if _RoleEmploy._lastUnlockSucces then
        _RoleEmploy._lastUnlockSucces = false
        self:changeToMercenayByRoleId(_RoleEmploy._lastUnlockRoleId)
    end
    local curContainer = ViewPlayerEquipmentPageBase:getContainerNodeByRoleId(_curSelectId)
    if curContainer then
        curContainer:runAnimation("MercenaryChoose")
        thisPageContainer:runAnimation("Equipment")
    end
end

function ViewPlayerEquipmentPageBase:rebuildAllItem(container)
    if #_mercenaryContainerInfo == 0 then
        self:clearAllItem(container)
        self:buildScrollView(container)
    else
        container.mScrollView:refreshAllCell();
    end
end
function ViewPlayerEquipmentPageBase:clearAllItem(container)
    container.mScrollView:removeAllCell();
end
function ViewPlayerEquipmentPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function ViewPlayerEquipmentPageBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
---------------------------------------------------------------------------------
-- 标签页
function mercenaryHeadContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        mercenaryHeadContent.onRefreshItemView(container);
    elseif eventName == "onMercenary" then
        mercenaryHeadContent.onSelectMercenary(container);
    end
end

function mercenaryHeadContent:onRefreshItemView(container)
    if container then
        NodeHelper:setNodesVisible(container, { mFishionIcon = false })
    end
end

function mercenaryHeadContent:onMercenary(container)
    local index = self.id
    local dataInfo = _mercenaryInfos.roleInfos[index];
    --     if dataInfo.roleStage == 0 then --锁住状态
    --        PageManager.pushPage("MercenaryPreviewPage")

    --    elseif dataInfo.roleStage == 1 then --已激活状态
    if _curSelectId == dataInfo.roleId then
        return
    end
    mCurRoleIndex = index;
    local lastContainer = ViewPlayerEquipmentPageBase:getContainerNodeByRoleId(_curSelectId)
    if lastContainer then
        lastContainer:runAnimation("ReincarnationStageAni")
    end
    _curSelectId = dataInfo.roleId;
    _curRoleInfo = dataInfo
    EquipScriptData._curRoleType = EquipScriptData._roleType.ROLE_MERCENARY
    ViewPlayerEquipmentPageBase:refreshPage(thisPageContainer)
    container:runAnimation("MercenaryChoose")
    thisPageContainer:runAnimation("Equipment")
    -- else -- 可激活
    --     local msg = RoleOpr_pb.HPRoleEmploy()
    --     msg.roleId = dataInfo.roleId
    --     local pb = msg:SerializeToString()
    --     PacketManager:getInstance():sendPakcet(HP_pb.ROLE_EMPLOY_C, pb, #pb, true)
    -- end
end

function ViewPlayerEquipmentPageBase:changeToMercenayByRoleId(roleId)
    local dataInfo, index = self:getMercenaryInfoByRoleId(roleId);
    if dataInfo.roleStage == 1 then
        -- 已激活状态
        local lastContainer = ViewPlayerEquipmentPageBase:getContainerNodeByRoleId(_curSelectId)
        if lastContainer then
            lastContainer:runAnimation("ReincarnationStageAni")
        end
        _curSelectId = dataInfo.roleId;
        EquipScriptData._curRoleType = EquipScriptData._roleType.ROLE_MERCENARY
        ViewPlayerEquipmentPageBase:refreshPage(thisPageContainer)
        local tempcontainer = _mercenaryContainerInfo[index]
        if tempcontainer and tempcontainer:getCCBFileNode() then
            tempcontainer:getCCBFileNode():runAnimation("MercenaryChoose")
        end
        thisPageContainer:runAnimation("Equipment")
        -- 改变滚动条位置
        if index > 3 then
            thisPageContainer.mScrollView:setContentOffset(ccp(fOneItemWidth *(-(index - 3)), 0))
        else
            thisPageContainer.mScrollView:setContentOffset(ccp(0, 0))
        end

        -- 改变滚动条位置
    else
        CCLuaLog("changeToMercenayByRoleId status error!!!!!!!!!!!!!!!! roleId = " .. roleId);
    end
end
function ViewPlayerEquipmentPageBase:getMercenaryInfoByRoleId(roleId)
    for i = 1, #_mercenaryInfos.roleInfos do
        if _mercenaryInfos.roleInfos[i].roleId == roleId then
            return _mercenaryInfos.roleInfos[i], i
        end
    end
end
function ViewPlayerEquipmentPageBase:getContainerNodeByRoleId(roleId)
    if _mercenaryInfos.roleInfos == nil or #_mercenaryContainerInfo == 0 then
        return
    end
    for i = 1, #_mercenaryInfos.roleInfos do
        if _mercenaryInfos.roleInfos[i].roleId == roleId and _mercenaryContainerInfo[i] then
            return _mercenaryContainerInfo[i]:getCCBFileNode();
        end
    end
    return nil
end
function mercenaryHeadContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local index = self.id
    _mercenaryContainerInfo[index] = ccbRoot;
    local dataInfo = _mercenaryInfos.roleInfos[index];
    local curMercenary = dataInfo

    local itemCfg = ConfigManager.getRoleCfg()[curMercenary.itemId]

    NodeHelper:setSpriteImage(container, {
        mProtraitColour = GameConfig.MercenaryQualityImage[itemCfg.quality]
    } );
    local playerSprite = CCSprite:create(itemCfg.icon)
    local playerNode = container:getVarNode("mPlayerSprite")
    if playerNode then
        playerNode:removeAllChildren()
    end

    local mNewGeneralsNode = container:getVarNode("mNewGenerals")
    if mNewGeneralsNode then
        mNewGeneralsNode:removeAllChildren()
    end

    --- 兼容之前的出战
    local isBattle = false
    if curMercenary.status == Const_pb.FIGHTING or curMercenary.status == Const_pb.FIGHTING_1 or curMercenary.status == Const_pb.FIGHTING_2 then
        isBattle = true
    end


    if dataInfo.status == Const_pb.FIGHTING then
        local ri = container:getVarSprite("mReplaceIcon");
        ri:setTexture("mercenary_FightTip.png");
        if index > GameConfig.MercenaryFightintMaxCount and index <= 11 then
            ri:setTexture("mercenary_SupportTip.png");
        end
    end


    if dataInfo.roleId == _curSelectId then
        container:runAnimation("MercenaryChoose")
    else
        container:runAnimation("ReincarnationStageAni")
    end

    NodeHelper:setNodesVisible(container, { mMercenaryOnTeam = isBattle })
    if dataInfo.roleStage == 0 then
        NodeHelper:setNodesVisible(container, { mMercenaryCallNode = false, mMercenaryLock = true })
        local graySprite = GraySprite:new()
        local texture = playerSprite:getTexture()
        local size = playerSprite:getContentSize()
        graySprite:initWithTexture(texture, CCRectMake(0, 0, size.width, size.height))
        playerNode:addChild(graySprite)
    elseif dataInfo.roleStage == 1 then
        NodeHelper:setNodesVisible(container, { mMercenaryCallNode = false, mMercenaryLock = false })
        playerNode:addChild(playerSprite)
    else
        NodeHelper:setNodesVisible(container, { mMercenaryCallNode = false, mMercenaryLock = false })
        playerNode:addChild(playerSprite)
    end

    if container then
        NodeHelper:setNodesVisible(container, { mFishionIcon = false })
    end

    --如果是皮肤则显示皮肤角标
    if itemCfg.FashionInfos ~= nil then
        NodeHelper:setNodesVisible(container, { mFishionIcon = true })
    end
end
function mercenaryHeadContent.onHand(container)

end
-- 构建标签页
function ViewPlayerEquipmentPageBase:buildScrollView(container)
    self.mAllRoleItem = NodeHelper:buildCellScrollView(container.mScrollView, #_mercenaryInfos.roleInfos, mercenaryHeadContent.ccbiFile, mercenaryHeadContent)
    if not self.mAllRoleItem then
        self.mAllRoleItem = { };
    end
end
-- 标签页s
---------------------------------------------------------------------------------
function ViewPlayerEquipmentPageBase:refreshPage(container)

    local typeData = EquipScriptData._TypeData[EquipScriptData._curRoleType]
    if typeData then
        local page = typeData.scriptName
        if page and page ~= "" and mSubNode then
            if ViewPlayerEquipmentPageBase.subPage then
                ViewPlayerEquipmentPageBase.subPage:onExit(container)
                ViewPlayerEquipmentPageBase.subPage = nil
            end
            mSubNode:removeAllChildren()
            -- 如果是佣兵类型 则需提前设置佣兵id
            if EquipScriptData._curRoleType == EquipScriptData._roleType.ROLE_MERCENARY then
                page = "ViewPlayerMercenaryPage"
                ViewPlayerEquipmentPageBase.subPage = require(page)
                if ViewPlayerEquipmentPageBase.subPage["setMercenaryId"] then
                    ViewPlayerEquipmentPageBase.subPage:setMercenaryId(_curRoleInfo, _showFateSubPage)
                end
            else
                _showFateSubPage = false
                page = "ViewPlayerLeadPage"
            end
            ViewPlayerEquipmentPageBase.subPage = require(page)


            ViewPlayerEquipmentPageBase.sunCCB = ViewPlayerEquipmentPageBase.subPage:onEnter(container)
            mSubNode:addChild(ViewPlayerEquipmentPageBase.sunCCB)

            if ViewPlayerEquipmentPageBase.subPage["getPacketInfo"] then
                ViewPlayerEquipmentPageBase.subPage:getPacketInfo()
            end
            ViewPlayerEquipmentPageBase.sunCCB:release()
            local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode();
            spineAttachNode:setPosition(ccp(0, 0));
            self:createTouchLayer(ViewPlayerEquipmentPageBase.sunCCB);
            -- the end
        end
    end
end
function ViewPlayerEquipmentPageBase:onReceiveMessage(container)
    -- if ViewPlayerEquipmentPageBase.subPage then
    -- ViewPlayerEquipmentPageBase.subPage:onReceiveMessage(container)
    -- end
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "ViewPlayerEquipmentPage" and extraParam == "ShowFatePage" then
            if EquipScriptData._curRoleType == EquipScriptData._roleType.ROLE_MERCENARY and ViewPlayerEquipmentPageBase.subPage then
                _showFateSubPage = true
                if ViewPlayerEquipmentPageBase.subPage["setShowFateSubPage"] then
                    ViewPlayerEquipmentPageBase.subPage:setShowFateSubPage(_showFateSubPage)
                end
            end
        elseif pageName == "ViewPlayerEquipmentPage" and extraParam == "HideFatePage" then
            if EquipScriptData._curRoleType == EquipScriptData._roleType.ROLE_MERCENARY and ViewPlayerEquipmentPageBase.subPage then
                _showFateSubPage = false
                if ViewPlayerEquipmentPageBase.subPage["setShowFateSubPage"] then
                    ViewPlayerEquipmentPageBase.subPage:setShowFateSubPage(_showFateSubPage)
                end
            end
        end
    end
end

-- function sortData(info)
--     local formationInfo = FormationManager:getMianFramtion().roleNumberList or {}
--      table.sort( info,function (mercenary1,mercenary2)
--         local mercenary1 = UserMercenaryManager:getUserMercenaryById(info1.roleId)
--         local mercenary2 = UserMercenaryManager:getUserMercenaryById(info2.roleId)
--         if mercenary1.status == Const_pb.FIGHTING and mercenary2.status == Const_pb.FIGHTING then
--             for i,v in ipairs(formationInfo) do
--                 if v == mercenary1.itemId then
--                     return true
--                 end
--                 if v == mercenary2.itemId then
--                     return false
--                 end
--                 return true
--             end
--         end

--         if mercenary1.status == mercenary2.status then
--             return info1.roleId < info2.roleId
--         end

--         return mercenary1.status > mercenary2.status

--     end);
-- end

-- 接收服务器回包
function ViewPlayerEquipmentPageBase:onReceivePacket(container)
    do return end;
    -- 不需要刷新
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local lastContainer = ViewPlayerEquipmentPageBase:getContainerNodeByRoleId(_curSelectId)
        if lastContainer then
            lastContainer:runAnimation("ReincarnationStageAni")
        end
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        _mercenaryInfos.roleInfos = msg.roleInfos
        local FetterManager = require("FetterManager")
        FetterManager.setCurOtherRoleInfo(_mercenaryInfos.roleInfos)
        -- sortData(_mercenaryInfos.roleInfos);
        self:relocateCurSelItem(_mercenaryInfos.roleInfos);
        self:rebuildAllItem(container)
        if _RoleEmploy._lastUnlockSucces then
            _RoleEmploy._lastUnlockSucces = false
            self:changeToMercenayByRoleId(_RoleEmploy._lastUnlockRoleId)
        end
        local curContainer = ViewPlayerEquipmentPageBase:getContainerNodeByRoleId(_curSelectId)
        if curContainer then
            curContainer:runAnimation("MercenaryChoose")
            thisPageContainer:runAnimation("Equipment")
        end
    elseif opcode == HP_pb.ROLE_EMPLOY_S then
        local msg = RoleOpr_pb.HPRoleEmploy();
        msg:ParseFromString(msgBuff);
        _RoleEmploy._lastUnlockRoleId = msg.roleId
        _RoleEmploy._lastUnlockSucces = true
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    end
    if ViewPlayerEquipmentPageBase.subPage then
        ViewPlayerEquipmentPageBase.subPage:onReceivePacket(container)
    end

end
function ViewPlayerEquipmentPageBase:onExecute(container)
    if ViewPlayerEquipmentPageBase.subPage then
        ViewPlayerEquipmentPageBase.subPage:onExecute(container)
    end

end
function ViewPlayerEquipmentPageBase:onClose(container)
    -- MainFrame_onMainPageBtn()
    PageManager.popPage(thisPageName)
end
function ViewPlayerEquipmentPageBase:onExit(container)
    container:removeMessage(MSG_SEVERINFO_UPDATE);
    container:removeMessage(MSG_MAINFRAME_REFRESH);
    if ViewPlayerEquipmentPageBase.subPage then
        local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode()
        spineAttachNode:stopAllActions();
        ViewPlayerEquipmentPageBase.subPage:onExit(container)
        ViewPlayerEquipmentPageBase.subPage = nil
    end
    -- NodeHelper:deleteScrollView(container);
    self:clearAllItem(container);
    local FetterManager = require("FetterManager")
    FetterManager.clearCurOtherRoleInfo()
    FetterManager.clear()
    self:removePacket(container)
    ViewPlayerInfo.isSeeSelfInfoFlag = false

    _curSelectId = 0;
    _mercenaryContainerInfo = { };
    _mercenaryInfos = { };
    self.mAllRoleItem = { };
    mCurRoleIndex = 0;
end
function ViewPlayerEquipmentPageBase:onHelp(container)
    local typeData = EquipScriptData._TypeData[EquipScriptData._curRoleType]
    PageManager.showHelp(typeData.helpFile)
end

function ViewPlayerEquipmentPageBase:selectMainPlayer()
    if EquipScriptData._curRoleType ~= EquipScriptData._roleType.ROLE_LEAD then
        EquipScriptData._curRoleType = EquipScriptData._roleType.ROLE_LEAD
        local lastContainer = ViewPlayerEquipmentPageBase:getContainerNodeByRoleId(_curSelectId)
        if lastContainer then
            lastContainer:runAnimation("ReincarnationStageAni")
        end
        _curSelectId = 0
        self:refreshPage(thisPageContainer)
        thisPageContainer:runAnimation("RoleChoose")
    end
end

function ViewPlayerEquipmentPageBase:onPersonalConfidence()
    self:selectMainPlayer();
    local spineAttachNode = ViewPlayerEquipmentPageBase.subPage:getSpineAttachNode();
    spineAttachNode:setPosition(ccp(0, 0));
    mCurRoleIndex = 0;
end

local CommonPage = require('CommonPage')
ViewPlayerEquipmentPageBase = CommonPage.newSub(ViewPlayerEquipmentPageBase, thisPageName, option)
