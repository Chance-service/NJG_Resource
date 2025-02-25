
local UserMercenaryManager = require("UserMercenaryManager");
local ConfigManager = require("ConfigManager");
local HelpFightDataManager = require("PVP.HelpFightDataManager")
local EighteenPrinces_pb = require("EighteenPrinces_pb")
local HP_pb = require("HP_pb")
local NewbieGuideManager = require("NewbieGuideManager")
local thisPageName = "HelpFightSelectMercenaryTeamPopUp";

local option = {
    ccbiFile = "HelpFightSelectTeamPopUp.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onReturn = "onReturn",
        onUse = "onUse",
        onChangeName = "onChangeName",
    },
}

local opcodes = {
    -- 获取编队阵型
    EIGHTEENPRINCES_FORMATIONINFO_C = HP_pb.EIGHTEENPRINCES_FORMATIONINFO_C,
    -- 返回编队阵型
    EIGHTEENPRINCES_FORMATIONINFO_S = HP_pb.EIGHTEENPRINCES_FORMATIONINFO_S,

}


-------------------------------------------------------------------------------------------------------
local mOffsetY = -19;
local mPressDeltaThreshold = 0.1;
-------------------------------------------------------------------------------------------------------
local HelpFightSelectMercenaryTeamPopUp = { }
local mInfosSort = { };
local mInfosDisorder = { };
local mAllRoleItem = { };
local mRoleNodes = { };
local mBtnNodes = { };
local mCurSelGroupIdx = 1;
local mCurSelItemIdx = 0;
local mAllGroupInfos = { };
local mRoleCfg = nil;

local mPressDelta = 0.0;
local mbPressed = false;
local mbTouchMove = false;
local mTempHeadItem = nil;
local mTouchBeginPos = nil;
local mbReceiveMsg = false;
local misInitScrollView = false
-------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------
local MercenaryHeadItem = { ccbiFile = "HelpFightHeadItem.ccbi" };

function HelpFightSelectMercenaryTeamPopUp.onMercenary_1(eventName, container)
    if eventName == "onMercenary" then

        if not mAllGroupInfos[mCurSelGroupIdx] then mAllGroupInfos[mCurSelGroupIdx] = { roleIds = { }, name = "" } end;
        local id = container:getTag()
        if id < 0 then
            return
        end
        local nIdx = MercenaryHeadItem:getIndexInGroup(id)
        local info = mInfosSort[id];
        if nIdx <= 0 then

        else
            HelpFightSelectMercenaryTeamPopUp:delRoleFromCurGroup(nIdx);
        end
    end
end



function MercenaryHeadItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function MercenaryHeadItem:getRoleInfo()
    return self.roleInfo
end

function MercenaryHeadItem:getId()
    return self.id
end

function MercenaryHeadItem:onMercenary(container)
    if not self.id then
        return
    end
    if self.id <= 0 then
        return
    end
    local nIdx = self:getIndexInGroup();
    local info = mInfosSort[self.id];
    if nIdx <= 0 then
        local count = 0
        for i = 1, #mAllGroupInfos[mCurSelGroupIdx].roleIds do
            if mAllGroupInfos[mCurSelGroupIdx].roleIds[i] > 0 then
                count = count + 1
            end
        end

        if count < 12 then
            nIdx = HelpFightSelectMercenaryTeamPopUp:addRoleToCurGroup(self.id);
            if nIdx then
                self:refreshItem(container, info, nIdx > 0, nIdx, true, true);
            else
                MessageBoxPage:Msg_Box_Lan("@OrgTeamFull");
            end
        else
            MessageBoxPage:Msg_Box_Lan("@OrgTeamFull");
        end
    else
        HelpFightSelectMercenaryTeamPopUp:delRoleFromCurGroup(nIdx);
    end
end

function MercenaryHeadItem:getIndexInGroup(id)
    local _id = id
    if id == nil then
        _id = self.id
    end
    local info = mInfosSort[_id];
    local groupInfos = mAllGroupInfos[mCurSelGroupIdx];
    if info and groupInfos and groupInfos.roleIds then
        for k, v in pairs(groupInfos.roleIds) do
            if info.itemId == v then
                return k;
            end
        end
    end
    return 0;
end

function MercenaryHeadItem:refreshItem(container, info, bSel, nIdx, bShowName, bIdx, bLock)
    local playerNode = container:getVarNode("mPlayerSprite")
    playerNode:removeAllChildren();
    local mHpSprite = container:getVarNode("mHpSprite")
    NodeHelper:setNodesVisible(container,{mHpNode = true})
    local itemCfg = nil;
    local bSkin = false;
    local bShowLock = false;
    if info then
        itemCfg = mRoleCfg[info.itemId];
    end

    if itemCfg then
        NodeHelper:setSpriteImage(container, { mProtraitColour = GameConfig.MercenaryQualityImage[itemCfg.quality] });
        local playerSprite = CCSprite:create(itemCfg.icon);
        playerNode:addChild(playerSprite);
        if  info.itemId<= 6 then
            playerSprite:setScale(0.77)
            NodeHelper:setStringForLabel(container, { mMercenaryName = UserInfo.roleName });
            NodeHelper:setSpriteImage(container, { mProtraitColour = GameConfig.QualityImage[1] })
        else
            playerSprite:setScale(1)
            NodeHelper:setStringForLabel(container, { mMercenaryName = itemCfg.name });
            NodeHelper:setSpriteImage(container, { mProtraitColour = GameConfig.MercenaryQualityImage[itemCfg.quality] })
        end
        -- NodeHelper:setSpriteImage(container, { mChooseShadeNum = "UI/Common/Font/Font_Formation_PositionNum_" ..(nIdx + 1) .. ".png" });

        NodeHelper:setStringForLabel(container, { mChooseShadeNum = nIdx})

        local FashionInfos = itemCfg.FashionInfos;
        if itemCfg.modelId ~= 0 then
            FashionInfos = mRoleCfg[itemCfg.modelId].FashionInfos;
        end
        if FashionInfos then
            for i, v in ipairs(FashionInfos) do
                local statusInfo = UserMercenaryManager:getMercenaryStatusByItemId(v);
                if statusInfo and v ~= info.itemId then
                    bSkin =(statusInfo.costSoulCount == statusInfo.soulCount and statusInfo.roleStage == 1);
                    break;
                end
            end
        end


        if HelpFightDataManager.myHelpFightBattleItem[info.itemId] then
            mHpSprite:setScaleX(HelpFightDataManager.myHelpFightBattleItem[info.itemId].hp/100)
            if HelpFightDataManager.myHelpFightBattleItem[info.itemId].hp == 0 then
                NodeHelper:setNodesVisible(container,{mIsGrayNode = true})
            else
                NodeHelper:setNodeIsGray(container, { mIsGrayNode = false })
            end
        else
            if info then
                mHpSprite:setScaleX(1)
                NodeHelper:setNodeIsGray(container, { mIsGrayNode = false })
            else
                NodeHelper:setNodesVisible(container,{mHpNode = false,mIsGrayNode = false})
            end
        end
    else
        NodeHelper:setNodesVisible(container,{mHpNode = false,mIsGrayNode = false})
    end

    NodeHelper:setStringForLabel(container, { mChoosePositionNum = nIdx })
    NodeHelper:setNodeIsGray(container, { mChoosePositionNum = true })

    -- NodeHelper:setSpriteImage(container, { mChoosePositionNum = "UI/Common/Font/Font_Formation_BGNum_" ..(nIdx + 1) .. ".png" });

    NodeHelper:setNodesVisible(container, { mChooseNumNode = bSel, mChooseShadeNum = true, mChoosePositionNum = true, mFishionIcon = bSkin, mMercenaryName = bShowName, mReplaceIcon = (nIdx > 6), mBattleIcon = (nIdx <= 6 and nIdx > 0) });

    if bLock then
        local lv = GameConfig.UnlockHelpFightMercenaryLv[nIdx];
        if lv and UserInfo.roleInfo.level < lv then
            bShowLock = true;
            NodeHelper:setStringForLabel(container, { mMercenaryName = common:getLanguageString("@UnlockMercenaryLimitLv", lv) });
        end
        NodeHelper:setNodesVisible(container, { mMercenaryName = bShowLock });
    end
    NodeHelper:setNodesVisible(container, { mMercenaryLock = (bLock and bShowLock) });

    NodeHelper:setNodeIsGray(container, { mLockSprite = true })
end

function MercenaryHeadItem:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local nIdx = self:getIndexInGroup();
    local info = mInfosSort[self.id];
    self:refreshItem(container, info, nIdx > 0, nIdx, true, true);
end

-------------------------------------------------------------------------------------------------------

function HelpFightSelectMercenaryTeamPopUp:sendChangeRoleOnOff(nGroupIdx, roleId, bOn)
    local msg = Formation_pb.HPFormationEditReq();
    msg.index = nGroupIdx;
    msg.roleId = roleId;
    if bOn then
        msg.status = 1
    else
        msg.status = 2
    end
    common:sendPacket(HP_pb.EDIT_FORMATION_C, msg, false);
end

function HelpFightSelectMercenaryTeamPopUp:sendSwapRolePos(nGroupIdx, roleId1, roleId2)
    local msg = Formation_pb.HPFormationExchangeRolesReq();
    msg.index = nGroupIdx;
    msg.roleId1 = roleId1;
    msg.roleId2 = roleId2;
    common:sendPacket(HP_pb.FORMATION_EXCHANGE_ROLES_C, msg, false);
end

function HelpFightSelectMercenaryTeamPopUp:sendUseFormation(nGroupIdx)
    local msg = Formation_pb.HPFormationUseReq();
    msg.index = nGroupIdx;
    common:sendPacket(HP_pb.USE_FORMATION_C, msg, true);
end

function HelpFightSelectMercenaryTeamPopUp:sendChangeGroupName(nGroupIdx, name)
    local msg = Formation_pb.HPFormationChangeNameReq();
    msg.index = nGroupIdx;
    msg.name = name;
    common:sendPacket(HP_pb.UPDATE_FORMATION_NAME_C, msg, false);
end

-------------------------------------------------------------------------------------------------------

function HelpFightSelectMercenaryTeamPopUp.onItemFunction(eventName, container)
    if eventName == "onTeam" then
        if mbReceiveMsg then
            HelpFightSelectMercenaryTeamPopUp:setCurGroupByItemBtn(container);
        end
    end
end

function HelpFightSelectMercenaryTeamPopUp:addRoleToCurGroup(nRoleIdx, bRefreshLs)
    if not mAllGroupInfos[mCurSelGroupIdx] then mAllGroupInfos[mCurSelGroupIdx] = { roleIds = { }, name = "" } end
    local count = 0
    for i = 1, #mAllGroupInfos[mCurSelGroupIdx].roleIds do
        if mAllGroupInfos[mCurSelGroupIdx].roleIds[i] > 0 then
            count = count + 1
        end
    end

    local nIdx = count + 1;
    -- local nIdx = #mAllGroupInfos[mCurSelGroupIdx].roleIds + 1;
    local bUnlock = false;
    local lv = GameConfig.UnlockHelpFightMercenaryLv[nIdx];
    if lv and UserInfo.roleInfo.level >= lv then
        bUnlock = true;
    end

    if nIdx <= 12 and bUnlock then
        local info = mInfosSort[nRoleIdx];
        mAllGroupInfos[mCurSelGroupIdx].roleIds[nIdx] = info.itemId;
        self:refreshCurGroupHeads(nIdx, nRoleIdx);
        if bRefreshLs then
            self.mScrollView:refreshAllCell();
        end
        return nIdx;
    end
end

function HelpFightSelectMercenaryTeamPopUp:delRoleFromCurGroup(nIdx)
    local groupInfos = mAllGroupInfos[mCurSelGroupIdx];
    if groupInfos and groupInfos.roleIds then
        local nRoleId = groupInfos.roleIds[nIdx];
        if nRoleId then
            table.remove(mAllGroupInfos[mCurSelGroupIdx].roleIds, nIdx);
            self:refreshCurGroupHeads();
            self.mScrollView:refreshAllCell();
            --self:sendChangeRoleOnOff(mCurSelGroupIdx, nRoleId);
        end
    end
end

function HelpFightSelectMercenaryTeamPopUp:swapRoleInCurGroup(nIdx1, nIdx2)
    local groupInfos = mAllGroupInfos[mCurSelGroupIdx];
    if groupInfos and groupInfos.roleIds then
        local n1 = groupInfos.roleIds[nIdx1];
        local n2 = groupInfos.roleIds[nIdx2];
        if n1 and n2 then
            mAllGroupInfos[mCurSelGroupIdx].roleIds[nIdx1] = n2;
            mAllGroupInfos[mCurSelGroupIdx].roleIds[nIdx2] = n1;
            self.mScrollView:refreshAllCell();
            self:sendSwapRolePos(mCurSelGroupIdx, n1, n2);
        end
    end
end

function HelpFightSelectMercenaryTeamPopUp:setCurGroupIdx(nCurGroup)
    mCurSelGroupIdx = nCurGroup;
    self:refreshCurGroupHeads();
    self.mScrollView:refreshAllCell();
end


function HelpFightSelectMercenaryTeamPopUp:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function HelpFightSelectMercenaryTeamPopUp:resetVarSelf()
    if self.mScrollView then
        self.mScrollView:removeAllCell();
        self.mScrollView = nil;
    end

    mInfosSort = { };
    mInfosDisorder = { };
    mAllRoleItem = { };
    mRoleNodes = { };
    mBtnNodes = { };
    mCurSelGroupIdx = 1;
    mCurSelItemIdx = 0;
    mAllGroupInfos = { };

    mPressDelta = 0.0;
    mbPressed = false;
    mbTouchMove = false;
    if mTempHeadItem then
        mTempHeadItem:removeFromParentAndCleanup(true);
    end
    mTempHeadItem = nil;
    mTouchBeginPos = nil;
    mbReceiveMsg = false;
end

function HelpFightSelectMercenaryTeamPopUp:onEnter(container)

    self:registerPacket(container)
    self.mContainer = container;
    mRoleCfg = ConfigManager.getRoleCfg();
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_HELPFIGHTFORMATION)
    self:resetVarSelf();
    self:initVarNodes();
    self:initData(container)
    self:initUI(container)
    self:refreshPage()
end

function HelpFightSelectMercenaryTeamPopUp:initUI(container)
    local libStr = {}
    libStr.mTitle = common:getLanguageString("@OrgTeamTitle")
    libStr.mConfirmBtn = common:getLanguageString("@EquipGodMerge")
    libStr.mCancleBtn = common:getLanguageString("@CancelingSaving")
    NodeHelper:setStringForLabel(container,libStr)
    NodeHelper:setNodesVisible(container,{mHelpNode = false })
end

function HelpFightSelectMercenaryTeamPopUp:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function HelpFightSelectMercenaryTeamPopUp:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function HelpFightSelectMercenaryTeamPopUp:initVarNodes()
    NodeHelper:setStringForLabel(self.mContainer, { mTitle = common:getLanguageString("@OrgTeamTitle") })
    self.mScrollView = self.mContainer:getVarScrollView("mContent");
    for i = 1, 12 do
        local node = self.mContainer:getVarNode("mRolePositionNode" .. i)
        node:removeAllChildren()
        mRoleNodes[i] = { attachNode = node }
    end
    NodeHelper:autoAdjustResizeScale9Sprite(self.mContainer:getVarScale9Sprite("mS9_1"))
    NodeHelper:autoAdjustResizeScale9Sprite(self.mContainer:getVarScale9Sprite("mS9_2"))
    NodeHelper:autoAdjustResizeScale9Sprite(self.mContainer:getVarScale9Sprite("mBtnNode"))
    NodeHelper:autoAdjustResizeScrollview(self.mScrollView);
end


function HelpFightSelectMercenaryTeamPopUp:sendEditInfoReq(index)
    local msg = Formation_pb.HPFormationEditInfoReq();
    msg.index = index;
    common:sendPacket(HP_pb.GET_FORMATION_EDIT_INFO_C, msg, true);
end


function HelpFightSelectMercenaryTeamPopUp:initData()
    mCurSelGroupIdx = 1
    misInitScrollView = false
    mAllGroupInfos = { }
    mAllRoleItem = { }
    mAllGroupInfos[mCurSelGroupIdx] = { }
    mAllGroupInfos[mCurSelGroupIdx].roleIds = {}
    if HelpFightDataManager.myFormationInfo.roleItem then
        for i = 1, #HelpFightDataManager.myFormationInfo.roleItem do
            table.insert(mAllGroupInfos[mCurSelGroupIdx].roleIds,HelpFightDataManager.myFormationInfo.roleItem[i].itemId)
        end
    end
    local a = 0
end

function HelpFightSelectMercenaryTeamPopUp:onExit(container)
    self:removePacket(container)
    self:resetVarSelf();
end


function HelpFightSelectMercenaryTeamPopUp:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_HELPFIGHTFORMATION)
end

function HelpFightSelectMercenaryTeamPopUp:onGroupBtn(container, eventName)
    if not mbReceiveMsg then return end;
    local groupIndex = tonumber(eventName:sub(-1))
    self:setCurGroupIdx(groupIndex)
end

function HelpFightSelectMercenaryTeamPopUp:onReturn(container)
    PageManager.popPage(thisPageName);
    PageManager.pushPage("HelpFightChangeReadyPopUp")
end

function HelpFightSelectMercenaryTeamPopUp:onUse(container)
    self:sendFormationReq()
    PageManager.popPage(thisPageName);
    PageManager.pushPage("HelpFightChangeReadyPopUp")

end

function HelpFightSelectMercenaryTeamPopUp:parseAllGroupInfosMsg(msg)
    for i = 1, #msg.formations do
        local formation = msg.formations[i];
        mAllGroupInfos[formation.index] = { roleIds = { } };
        mAllGroupInfos[formation.index].name = formation.name;
        for j = 1, #formation.roleIds do
            table.insert(mAllGroupInfos[formation.index].roleIds, formation.roleIds[j]);
        end
    end
end

function HelpFightSelectMercenaryTeamPopUp:parseAllGroupInfosMsg_New(msg)
    local formation = msg.formations;
    mAllGroupInfos[formation.index] = { roleIds = { } };
    mAllGroupInfos[formation.index].name = formation.name;
    for i = 1, #formation.roleIds do
        table.insert(mAllGroupInfos[formation.index].roleIds, formation.roleIds[i]);
    end
end

function HelpFightSelectMercenaryTeamPopUp:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == HP_pb.GET_FORMATION_EDIT_INFO_S then
        local msg = Formation_pb.HPFormationEditInfoRes();
        msg:ParseFromString(msgBuff);
        self:parseAllGroupInfosMsg_New(msg)
        -- self:parseAllGroupInfosMsg(msg);
        self:refreshPage();
        mbReceiveMsg = true;
    elseif opcode == HP_pb.USE_FORMATION_S then
        local msg = Formation_pb.HPFormationUseRes();
        msg:ParseFromString(msgBuff);
        --common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
        -- 收到成功的消息之后 关闭此页面
        PageManager.popPage(thisPageName)

    elseif opcode == HP_pb.EDIT_FORMATION_S then
        local msg = Formation_pb.HPFormationUseRes();
        msg:ParseFromString(msgBuff);
    end
end

function HelpFightSelectMercenaryTeamPopUp:getMercenaryInfos()

    local tmpRoleInfo = UserMercenaryManager:getUserMercenaryInfos()
    local tblsort = { };
    local tbldisorder = { };
    local otherRoleInfo = {}
    local helpFightSkinRoleInfo = {}
    local index = 1
    for i, v in pairs(tmpRoleInfo) do
        local tmpData = UserMercenaryManager:getMercenaryStatusByItemId(v.itemId)
        local cfg = nil
        if tmpData then
         cfg = mRoleCfg[tmpData.itemId]
        end
        if cfg then
            local FashionInfos = cfg.FashionInfos;
            if cfg.modelId ~= 0 then
                FashionInfos = mRoleCfg[cfg.modelId].FashionInfos;
            end
            if FashionInfos then
                table.insert(otherRoleInfo,tmpData)
            else
                if not tmpData.hide then
                    table.insert(tblsort, tmpData)
                    tbldisorder[tmpData.itemId] = tmpData;
                    tbldisorder[tmpData.itemId].index = index
                    index = index + 1
                end
            end
        end
    end

    if #tblsort > 0 then
        table.sort(tblsort,
                function(d1, d2)
                    return d1.fight > d2.fight;
                end
        );
    end
    if HelpFightDataManager.myFormationInfo.roleItem  then
        for i = 1, #HelpFightDataManager.myFormationInfo.roleItem do
            local tmpInfo = HelpFightDataManager.myFormationInfo.roleItem[i]
            local cfg = mRoleCfg[tmpInfo.itemId]
            if cfg then
                local FashionInfos = cfg.FashionInfos;
                if cfg.modelId ~= 0 then
                    FashionInfos = mRoleCfg[cfg.modelId].FashionInfos;
                end
                if FashionInfos then
                    local tmpTable = {
                        itemId = tmpInfo.itemId,
                        modelId = 0
                    }
                    for i = 1, #FashionInfos do
                        if FashionInfos[i] ~= tmpInfo.itemId then
                            tmpTable.modelId = FashionInfos[i]
                        end
                    end
                    table.insert(helpFightSkinRoleInfo,tmpTable)
                end
            end
        end
        for i = 1, #HelpFightDataManager.myFormationInfo.historyItem do
            local tmpInfo = HelpFightDataManager.myFormationInfo.historyItem[i]
            local cfg = mRoleCfg[tmpInfo.itemId]
            if cfg then
                local FashionInfos = cfg.FashionInfos;
                if cfg.modelId ~= 0 then
                    FashionInfos = mRoleCfg[cfg.modelId].FashionInfos;
                end
                if FashionInfos then
                    local tmpTable = {
                        itemId = tmpInfo.itemId,
                        modelId = 0
                        }
                    for i = 1, #FashionInfos do
                        if FashionInfos[i] ~= tmpInfo.itemId then
                            tmpTable.modelId = FashionInfos[i]
                        end
                    end
                    table.insert(helpFightSkinRoleInfo,tmpTable)
                end
            end
        end
    end


    if #tblsort > 0 then
        table.sort(tblsort,
                function(d1, d2)
                    return d1.fight > d2.fight;
                end
        );
    end

    local useSkinRoleTable = {}

    for i = 1, #otherRoleInfo do
        for j = 1, #helpFightSkinRoleInfo do
            if helpFightSkinRoleInfo[j].itemId == otherRoleInfo[i].itemId then
                table.insert(tblsort, otherRoleInfo[i])
                table.insert(useSkinRoleTable,helpFightSkinRoleInfo[j])
                tbldisorder[otherRoleInfo[i].itemId] = otherRoleInfo[i];
                tbldisorder[otherRoleInfo[i].itemId].index = index
                index = index + 1
                break
            end
        end
    end

    for i = 1, #otherRoleInfo do
        local isJoin = true
        for k = 1, #useSkinRoleTable do
            if  otherRoleInfo[i].itemId == useSkinRoleTable[k].itemId or otherRoleInfo[i].itemId == useSkinRoleTable[k].modelId then
                isJoin = false
                break
            end
        end
        if isJoin and  not otherRoleInfo[i].hide then
            table.insert(tblsort, otherRoleInfo[i])
            tbldisorder[otherRoleInfo[i].itemId] = otherRoleInfo[i];
            tbldisorder[otherRoleInfo[i].itemId].index = index
            index = index + 1
        end
    end

    if #tblsort > 0 then
        table.sort(tblsort,
                function(d1, d2)
                    return d1.fight > d2.fight;
                end
        );
    end

    local myLeaderData = {
        roleId = 0,
        roleStage = 0,
        soulCount = 0,
        costSoulCount = 0,
        hide = false,
        itemId = UserInfo.roleInfo.prof + 3,
        status = 0,
        fight = 0,
        index = index,
    }

    table.insert(tblsort, myLeaderData)
    tbldisorder[myLeaderData.itemId] = myLeaderData;
    index = index + 1

    if #tblsort > 0 then
        table.sort(tblsort,
                function(d1, d2)
                    return d1.fight > d2.fight;
                end
        );
    end

    return tblsort, tbldisorder;

    ------------------------------------------------
--[[    local infos = UserMercenaryManager:getMercenaryStatusInfos();
    local tblsort = { };
    local tbldisorder = { };
    local index = 1
    for k, v in pairs(infos) do
        if v.roleStage == 1 and not v.hide then
            table.insert(tblsort, v);
            tbldisorder[v.itemId] = v;
            tbldisorder[v.itemId].index = index
            index = index + 1
        end
    end

    if #tblsort > 0 then
        table.sort(tblsort,
                function(d1, d2)
                    return d1.fight > d2.fight;
                end
        );
    end

    return tblsort, tbldisorder;]]
end

function HelpFightSelectMercenaryTeamPopUp:newHeadItem(nIdx)
    local groupInfos = mAllGroupInfos[mCurSelGroupIdx];
    local headNode = ScriptContentBase:create(MercenaryHeadItem.ccbiFile);
    -- headNode:getVarNode("mBossFightNode"):setVisible(false);
    headNode:release();
    -- headNode:setPositionY(mOffsetY);
    local nShowName = true;
    if nIdx <= 6 then
        nShowName = false;
    end
    local info = nil;
    if groupInfos and groupInfos.roleIds then
        local roleId = groupInfos.roleIds[nIdx];
        local index = 0
        if roleId then
            info = mInfosDisorder[roleId];
            if info then
                for k, v in pairs(mAllRoleItem) do
                    local roleInfo = v.cls:getRoleInfo()
                    if info.itemId == roleInfo.itemId then
                        index = v.cls:getId()
                    end
                end
                headNode:setTag(index)
                headNode:registerFunctionHandler(self.onMercenary_1)
            end
        end
    end
    MercenaryHeadItem:refreshItem(headNode, info, false, nIdx, nShowName, false, true);
    return headNode, handler;
end

function HelpFightSelectMercenaryTeamPopUp:refreshCurGroupHeads(nHeadIdx, nRoleIdx)
    if not nHeadIdx then
        for k, v in pairs(mRoleNodes) do
            if v.attachNode then
                v.attachNode:removeAllChildren();
                local headNode = self:newHeadItem(k);
                v.attachNode:addChild(headNode);
                mRoleNodes[k].item = headNode;
            end
        end
    else
        for k, v in pairs(mRoleNodes) do
            if k == nHeadIdx then
                if v.attachNode then
                    v.attachNode:removeAllChildren();
                    local headNode = self:newHeadItem(k);
                    if nRoleIdx then
                        local info = mInfosSort[nRoleIdx];
                        MercenaryHeadItem:refreshItem(headNode, info, false, k, k > 6, false, true);
                    end
                    v.attachNode:addChild(headNode);
                    mRoleNodes[k].item = headNode;
                end
            end
        end
    end
end

function HelpFightSelectMercenaryTeamPopUp:refreshAllMercenaryList()
    if misInitScrollView then
        return
    end
    if self.mScrollView then
        mInfosSort, mInfosDisorder = self:getMercenaryInfos();
        self.mScrollView:removeAllCell();
        mAllRoleItem = { }
        local cell = nil
        for i = 1, #mInfosSort do
            cell = CCBFileCell:create()
            cell:setCCBFile(MercenaryHeadItem.ccbiFile)
            local handler = MercenaryHeadItem:new( { id = i, roleInfo = mInfosSort[i] })
            cell:registerFunctionHandler(handler)
            self.mScrollView:addCell(cell)
            table.insert(mAllRoleItem, { cls = handler, node = cell })
        end
        self.mScrollView:orderCCBFileCells()
        if not mAllRoleItem then
            mAllRoleItem = { };
        end
        misInitScrollView = true
    end
end

function HelpFightSelectMercenaryTeamPopUp:refreshPage()
    self:refreshAllMercenaryList();
    self:setCurGroupIdx(mCurSelGroupIdx);
end

function HelpFightSelectMercenaryTeamPopUp:sendFormationReq()
    local tmpRoleId = {}
    local msg = EighteenPrinces_pb.HPEighteenPrincesFormationReq()
    for i = 1, #mAllGroupInfos[mCurSelGroupIdx].roleIds do
        table.insert( msg.roleItemId,mAllGroupInfos[mCurSelGroupIdx].roleIds[i])
    end
    HelpFightDataManager:sendEighteenPrincesHelpFormationReq(msg)
end


-------------------------------------------------------------------------------------
local CommonPage = require("CommonPage");
HelpFightSelectMercenaryTeamPopUp = CommonPage.newSub(HelpFightSelectMercenaryTeamPopUp, thisPageName, option);