----------------------------------------------------------------------------------
-- 好友申請頁面
----------------------------------------------------------------------------------

-- 模塊引用
local Friend_pb       = require("Friend_pb")
local Const_pb        = require("Const_pb")
local HP_pb           = require("HP_pb")
local GameConfig      = require("GameConfig")
local RoleManager     = require("PlayerInfo.RoleManager")
local UserInfo        = require("PlayerInfo.UserInfo")
local FriendManager   = require("FriendManager")
local OSPVPManager    = require("OSPVPManager")
local CommonPage      = require("CommonPage")

-- 畫面名稱與選項配置
local thisPageName = "FriendApplyPage"
local option = {
    ccbiFile = "FriendApplicationPopUp.ccbi",
    entermateCcbiFile = "FriendApplicationPopUp.ccbi",
    handlerMap = {
        onClose = "onClose"
    },
    opcodes = {
        -- 如有需要，可啟用對應回包監聽
        -- FRIEND_LIST_S = HP_pb.FRIEND_LIST_S,
        -- FRIEND_LIST_KAKAO_C = HP_pb.FRIEND_LIST_KAKAO_C,
        -- FRIEND_LIST_KAKAO_S = HP_pb.FRIEND_LIST_KAKAO_S,
    }
}

----------------------------------------------------------------------------------
-- 友軍頭像刷新模塊
----------------------------------------------------------------------------------
local mercenaryHeadContent = {
    ccbiFile = "FormationTeamContent.ccbi"
}

function mercenaryHeadContent:refreshItem(container, info)
    -- 刷新頭像與等級數據
    local roleIcon = ConfigManager.getRoleIconCfg()
    local trueIcon = info.headIcon
    if not roleIcon[trueIcon] then
        local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
        if NodeHelper:isFileExist(icon) then
            NodeHelper:setSpriteImage(container, { mHead = icon })
        end
        NodeHelper:setStringForLabel(container, { mLv = info.level })
    else
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[trueIcon].MainPageIcon })
        NodeHelper:setStringForLabel(container, { mLv = info.level })
    end

    -- 隱藏不必要的節點
    NodeHelper:setNodesVisible(container, {
        mClass = false, mElement = false, mMarkFighting = false,
        mMarkChoose = false, mMarkSelling = false, mMask = false,
        mSelectFrame = false, mStageImg = false
    })
end

----------------------------------------------------------------------------------
-- FriendApplyItem: 單個好友申請項目
----------------------------------------------------------------------------------
local FriendApplyItem = {
    ccbiFile = "FriendApplicationContent.ccbi"
}

function FriendApplyItem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function FriendApplyItem:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local id = self.id
    local index = self.index
    local info = FriendManager.getApplyInfoById(id)
    local lb2Str = {}

    if info then
        lb2Str["mName"] = info.name
        lb2Str["mLevelNum"] = UserInfo.getOtherLevelStr(info.rebirthStage, info.level)
        lb2Str["mFightingNum"] = GameUtil:formatDotNumber(info.fightValue)

        -- 創建並刷新頭像節點
        local headNode = ScriptContentBase:create(mercenaryHeadContent.ccbiFile)
        local parentNode = container:getVarNode("mHeadNode")
        parentNode:removeAllChildren()
        mercenaryHeadContent:refreshItem(headNode, info)
        headNode:setAnchorPoint(ccp(0.5, 0.5))
        parentNode:addChild(headNode)

        -- 如有 CSPVP 排名，可依據需求設置其他圖標（此處暫留注釋）
        if info.cspvpRank and info.cspvpRank > 0 then
            local stage = OSPVPManager.checkStage(info.cspvpScore, info.cspvpRank)
            -- sprite2Img.mFrame = stage.stageIcon
        else
            -- sprite2Img.mFrame = GameConfig.QualityImage[1]
        end
    end

    -- 更新標籤信息
    NodeHelper:setStringForLabel(container, lb2Str)
    -- 此處 sprite2Img、scaleMap、menu2Quality 可根據需求傳入
    NodeHelper:setSpriteImage(container, {}, {})
    NodeHelper:setQualityFrames(container, {})

    -- 隱藏上線狀態/時間與申請按鈕（申請頁面不需要顯示這些）
    NodeHelper:setNodesVisible(container, {
        mLastLandTime = false,
        mApplyBtn = false
    })
end

function FriendApplyItem:onSure(container)
    local id = self.id
    FriendManager.agreeApply(id)
end

function FriendApplyItem:onDelete(container)
    local id = self.id
    FriendManager.refuseApply(id)
end

function FriendApplyItem:onViewDetail(container)
    -- 如需查看好友詳情，可取消下列注釋
    -- local id = self.id
    -- FriendManager.setViewPlayerId(id)
    -- ViewPlayerInfo:getInfo(id)
end

----------------------------------------------------------------------------------
-- FriendApplyPageBase: 好友申請頁面邏輯
----------------------------------------------------------------------------------
local FriendApplyPageBase = {}

function FriendApplyPageBase:onLoad(container)
    local ccbiFile = (not Golb_Platform_Info.is_entermate_platform) and option.ccbiFile or option.entermateCcbiFile
    container:loadCcbiFile(ccbiFile)
    container.scrollview = container:getVarScrollView("mContent")
    -- 如有需要可啟用滾動視圖自適應調整
    -- if container.scrollview then container:autoAdjustResizeScrollview(container.scrollview) end
end

function FriendApplyPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10)
    
    -- 加載角色配置（根據需要使用）
    local roleConfig = ConfigManager.getRoleCfg()
    self:clearAndReBuildAllItem(container)

    -- 標記好友申請已查看，清除通知
    FriendManager.hasCheckedApply()

    -- 更新好友數量顯示
    local friendList = FriendManager.getFriendList()
    local friendSize = #friendList
    NodeHelper:setStringForLabel(container, {
        mFriendLimitNum = common:getLanguageString('@FriendNumLimitTxt', tostring(friendSize))
    })
end

function FriendApplyPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local friendApplyList = FriendManager.getFriendApplyList()
    if #friendApplyList >= 1 then
        for i, v in ipairs(friendApplyList) do
            local titleCell = CCBFileCell:create()
            local panel = FriendApplyItem:new({ id = v.playerId, index = i })
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(FriendApplyItem.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
    local isRequestEmpty = (#friendApplyList < 1)
    NodeHelper:setNodesVisible(container, { mEmpty = isRequestEmpty })
end

function FriendApplyPageBase:onExecute(container)
    -- 可在此添加定時刷新等邏輯
end

function FriendApplyPageBase:onExit(container)
    self:removePacket(container)
end

function FriendApplyPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function FriendApplyPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.FRIEND_LIST_S then
        -- 此處可根據實際需求處理 FRIEND_LIST_S 回包
    end
end

function FriendApplyPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    if message:getTypeId() == MSG_MAINFRAME_REFRESH then
        local trueMsg = MsgMainFrameRefreshPage:getTrueType(message)
        local pageName = trueMsg.pageName
        if pageName == thisPageName then
            self:clearAndReBuildAllItem(container)
        elseif pageName == OSPVPManager.moduleName then
            local extraParam = trueMsg.extraParam
            if extraParam == OSPVPManager.onLocalPlayerInfo then
                if container.mScrollView then
                    container.mScrollView:refreshAllCell()
                end
            end
        end
    end
end

function FriendApplyPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function FriendApplyPageBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

----------------------------------------------------------------------------------
-- 模塊導出：利用 CommonPage 封裝頁面邏輯
----------------------------------------------------------------------------------
local FriendApplyPage = CommonPage.newSub(FriendApplyPageBase, thisPageName, option)
return FriendApplyPage
