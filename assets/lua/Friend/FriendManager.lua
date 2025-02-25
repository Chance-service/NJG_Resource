----------------------------------------------------------------------------------
-- FriendManager.lua
-- 好友管理模組
----------------------------------------------------------------------------------

local common         = require("common")
local HP_pb          = require("HP_pb")
local Friend_pb      = require("Friend_pb")
local PageManager    = require("PageManager")
local UserInfo       = require("PlayerInfo.UserInfo")
local OSPVPManager   = require("OSPVPManager")
local MessageBoxPage = MessageBoxPage

----------------------------------------------------------------------------------
-- 模組定義
----------------------------------------------------------------------------------
local FriendManager = {}

----------------------------------------------------------------------------------
-- 局部變量
----------------------------------------------------------------------------------
local friend_apply_list = {}   -- 好友申請列表
local friend_list       = {}   -- 好友列表
-- new_friend_list 目前未使用

local isInitFriendList       = false
local isInitFriendApplyList  = false

local FRIEND_MAIN_PAGE  = "FriendPage"
local FRIEND_APPLY_PAGE = "FriendApplyPage"
local MAIN_PAGE         = "MainScenePage"

-- 事件常量
FriendManager.onSyncApplyList  = "onSyncApplyList"
FriendManager.onSyncList       = "onSyncList"
FriendManager.onNewFriendApply = "onNewFriendApply"
FriendManager.onNewFriendAdd   = "onNewFriendAdd"
FriendManager.onNoticeChecked  = "onFriendNoticeChecked"

local needCheck     = false
local viewPlayerId  = nil
local agreePlayerId = nil
local deletePlayerId = nil

----------------------------------------------------------------------------------
-- 本地輔助函數
----------------------------------------------------------------------------------
local function doNoticeCheck()
    if #friend_apply_list > 0 then
        needCheck = true
        PageManager.refreshPage(MAIN_PAGE, FriendManager.onSyncApplyList)
        PageManager.refreshPage(FRIEND_MAIN_PAGE, FriendManager.onNewFriendApply)
    else
        needCheck = false
        PageManager.refreshPage(MAIN_PAGE, FriendManager.onNoticeChecked)
        PageManager.refreshPage(FRIEND_MAIN_PAGE, FriendManager.onNoticeChecked)
    end
end

----------------------------------------------------------------------------------
--【請求相關函數】
----------------------------------------------------------------------------------
-- 發送送禮請求
-- friendID : 0 表示全部，>0 表示特定好友
function FriendManager.requestGiftTo(friendID)
    local msg = Friend_pb.HPGiftFriendshipReq()
    msg.friendId = friendID
    print(string.format("Send[%s] MsgType[%s] friendID[%s]", "HP_pb.FRIEND_POINT_GIFT_C", "HPGiftFriendshipReq", tostring(friendID)))
    common:sendPacket(HP_pb.FRIEND_POINT_GIFT_C, msg, true)
end

-- 發送領取禮物請求
function FriendManager.requestGiftFrom(friendID)
    local msg = Friend_pb.HPGetFriendshipReq()
    msg.friendId = friendID
    common:sendPacket(HP_pb.FRIEND_POINT_GET_C, msg, true)
end

-- 請求好友申請列表（僅初始化時請求一次）
function FriendManager.requestFriendApplyList()
    if isInitFriendApplyList then return end
    common:sendEmptyPacket(HP_pb.FRIEND_APPLY_LIST_C, false)
end

-- 請求好友列表
function FriendManager.requestFriendList()
   --if isInitFriendList then
   --    PageManager.refreshPage(FRIEND_MAIN_PAGE, FriendManager.onSyncList)
   --    return 
   --end
    common:sendEmptyPacket(HP_pb.FRIEND_LIST_C, false)
end

-- 按玩家ID搜索好友
function FriendManager.searchFriendById(id)
    local msg = Friend_pb.HPFindFriendReq()
    msg.playerId = id
    common:sendPacket(HP_pb.FRIEND_FIND_C, msg, true)
end

-- 按玩家名稱搜索好友
function FriendManager.searchFriendByName(name)
    local msg = Friend_pb.HPFindFriendReq()
    msg.playerId = 0
    msg.playerName = name
    common:sendPacket(HP_pb.FRIEND_FIND_C, msg, true)
end

-- 申請添加好友（根據ID）
function FriendManager.sendApplyById(id)
    local info = FriendManager.getFriendInfoById(id)
    if info.playerId then
        MessageBoxPage:Msg_Box("@AlreadyBeFriendTxt")
        return
    end
    if id == UserInfo.playerInfo.playerId then
        MessageBoxPage:Msg_Box("@FriendAddSelfTxt")
        return
    end
    local msg = Friend_pb.HPApplyFriend()
    msg.playerId = id
    common:sendPacket(HP_pb.FRIEND_APPLY_C, msg, false)
    FriendSendedList[id] = true
end

-- 同意好友申請
function FriendManager.agreeApply(id)
    agreePlayerId = id
    local msg = Friend_pb.HPRefuseApplyFriend()  -- 此處協議類型根據實際情況可能需要調整
    msg.playerId = id
    common:sendPacket(HP_pb.FRIEND_AGREE_C, msg, false)
end

-- 拒絕好友申請
function FriendManager.refuseApply(id)
    local msg = Friend_pb.HPRefuseApplyFriend()
    msg.playerId = id
    common:sendPacket(HP_pb.FRIEND_REFUSE_C, msg, true)
end

-- 刪除好友（單個）
function FriendManager.deleteById(id)
    PageManager.showConfirm(
        common:getLanguageString("@FriendDeleteTitle"),
        common:getLanguageString("@FriendDeleteTxt"),
        function(isSure)
            if isSure then
                deletePlayerId = id
                local msg = Friend_pb.HPFriendDel()
                msg.targetId:append(id)
                common:sendPacket(HP_pb.FRIEND_DELETE_C, msg, true)
            end
        end
    )
end

-- 刪除好友（批量）
function FriendManager.deleteByIds(ids)
    PageManager.showConfirm(
        common:getLanguageString("@FriendDeleteTitle"),
        common:getLanguageString("@FriendDeleteTxt"),
        function(isSure)
            if isSure then
                local msg = Friend_pb.HPFriendDel()
                for _, id in ipairs(ids) do
                    msg.targetId:append(id)
                end
                common:sendPacket(HP_pb.FRIEND_DELETE_C, msg, true)
            end
        end
    )
end

----------------------------------------------------------------------------------
--【同步處理函數】
----------------------------------------------------------------------------------
-- 同步好友列表
function FriendManager.syncFriendList(msg)
    if not msg.friendItem then 
        return 
    end

    friend_list = {}
    local playerIds = {}

    for i = 1, #msg.friendItem do
        local data = msg.friendItem[i]
        local friendItem = {
            playerId     = data.playerId,
            level        = data.level,
            name         = data.name,
            roleId       = data.roleId,
            fightValue   = data.fightValue,
            rebirthStage = data.rebirthStage,
            signature    = data.signature or "",
            offlineTime  = data.offlineTime or 0,
            avatarId     = data.avatarId or 0,
            headIcon     = data.headIcon or 1000,
            haveGift     = data.haveGift or false,
            canGift      = data.canGift or false,
        }
        table.insert(friend_list, friendItem)
        table.insert(playerIds, data.playerId)
    end

    if #playerIds > 0 then
        OSPVPManager.reqLocalPlayerInfo(playerIds)
    end

    PageManager.refreshPage(FRIEND_MAIN_PAGE, FriendManager.onSyncList)
    isInitFriendList = true
end

-- 同步好友申請列表
function FriendManager.syncFriendApplyList(msg)
    isInitFriendApplyList = true
    if msg.friendItem then
        friend_apply_list = {}
        local playerIds = {}
        for i = 1, #msg.friendItem do
            table.insert(friend_apply_list, msg.friendItem[i])
            table.insert(playerIds, msg.friendItem[i].playerId)
        end
        if #playerIds > 0 then
            OSPVPManager.reqLocalPlayerInfo(playerIds)
        end
        PageManager.refreshPage(FRIEND_APPLY_PAGE, FriendManager.onSyncApplyList)
        doNoticeCheck()
    end
end

----------------------------------------------------------------------------------
--【更新/事件處理函數】
----------------------------------------------------------------------------------
-- 新的好友申請進來
function FriendManager.onNewApply(playerItem)
    for _, v in pairs(friend_apply_list) do
        if v.playerId == playerItem.playerId then return end
    end
    needCheck = true
    table.insert(friend_apply_list, playerItem)
    OSPVPManager.reqLocalPlayerInfo({ playerItem.playerId })
    PageManager.refreshPage(FRIEND_APPLY_PAGE, FriendManager.onSyncApplyList)
    PageManager.refreshPage(FRIEND_MAIN_PAGE, FriendManager.onNewFriendApply)
    PageManager.refreshPage(MAIN_PAGE, FriendManager.onNewFriendApply)
end

-- 新的好友添加成功
function FriendManager.onNewFriend(playerItem)
    for _, v in pairs(friend_list) do
        if v.playerId == playerItem.playerId then return end
    end
    local new_apply_list = {}
    local needRefreshApply = false
    for _, v in pairs(friend_apply_list) do
        if v.playerId == playerItem.playerId then
            needRefreshApply = true
        else
            table.insert(new_apply_list, v)
        end
    end
    table.insert(friend_list, playerItem)
    OSPVPManager.reqLocalPlayerInfo({ playerItem.playerId })
    PageManager.refreshPage(MAIN_PAGE, FriendManager.onNewFriendAdd)
    PageManager.refreshPage(FRIEND_MAIN_PAGE, FriendManager.onSyncList)
    if needRefreshApply then
        friend_apply_list = new_apply_list
        PageManager.refreshPage(FRIEND_APPLY_PAGE, FriendManager.onSyncApplyList)
    end
    if agreePlayerId then
        agreePlayerId = nil
        MessageBoxPage:Msg_Box(common:getLanguageString("@FriendAddSuccessTxt", playerItem.name))
    end
end

-- 好友刪除事件
-- 此處的參數為待刪除的好友ID集合（table）
function FriendManager.onDeleteFriend(playerIds)
    for i = #friend_list, 1, -1 do
        for _, id in ipairs(playerIds) do
            if friend_list[i].playerId == id then
                table.remove(friend_list, i)
                break  
            end
        end
    end
    MessageBoxPage:Msg_Box("@DelFriendSuccess")
    PageManager.refreshPage(FRIEND_MAIN_PAGE, FriendManager.onSyncList)
end

-- 拒絕好友申請事件
function FriendManager.onRefuseApply(playerId)
    local newList = {}
    for _, v in ipairs(friend_apply_list) do
        if v.playerId ~= playerId then
            table.insert(newList, v)
        end
    end
    friend_apply_list = newList
    PageManager.refreshPage(FRIEND_APPLY_PAGE, FriendManager.onSyncApplyList)
end

----------------------------------------------------------------------------------
--【Getter 函數】
----------------------------------------------------------------------------------
function FriendManager.getFriendApplyList()
    return friend_apply_list
end

function FriendManager.getFriendList()
    return friend_list
end

function FriendManager.getApplyInfoById(playerId)
    for _, v in ipairs(friend_apply_list) do
        if v.playerId == playerId then
            return v
        end
    end
    return {}
end

function FriendManager.getFriendInfoById(playerId)
    for _, v in ipairs(friend_list) do
        if v.playerId == playerId then
            return v
        end
    end
    return {}
end

function FriendManager.getFriendInfoByName(name)
    for _, v in ipairs(friend_list) do
        if v.name == name then
            return v
        end
    end
    return {}
end

----------------------------------------------------------------------------------
--【通知與狀態處理】
----------------------------------------------------------------------------------
-- 清除好友申請通知
function FriendManager.hasCheckedApply()
    needCheck = false
    PageManager.refreshPage(MAIN_PAGE, FriendManager.onNoticeChecked)
    PageManager.refreshPage(FRIEND_MAIN_PAGE, FriendManager.onNoticeChecked)
end

-- 是否需要顯示通知
function FriendManager.needCheckNotice()
    return needCheck
end

----------------------------------------------------------------------------------
--【玩家查看相關】
----------------------------------------------------------------------------------
function FriendManager.setViewPlayerId(playerId)
    viewPlayerId = playerId
end

function FriendManager.getViewPlayerId()
    return viewPlayerId
end

function FriendManager.cleanViewPlayer()
    viewPlayerId = nil
end

----------------------------------------------------------------------------------
-- 模塊導出
----------------------------------------------------------------------------------
return FriendManager
