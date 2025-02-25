local NewHeadIconItem = {
    itemId = "",
    roleTable = {}
}

local NodeHelper = require("NodeHelper")
local UserMercenaryManager = require("UserMercenaryManager")
local mInfo = UserMercenaryManager:getUserMercenaryInfos()

local leaderClass = 10

function NewHeadIconItem:create(idStr, parentNode)
    local iconItem = {}
    setmetatable(iconItem, self)
    self.__index = self

    iconItem.itemId = idStr
    iconItem.parentNode = parentNode
    iconItem:init()
    return iconItem
end

function NewHeadIconItem:init()
    self.container = ScriptContentBase:create("FormationTeamContent.ccbi")
    self:refresh()

    self.parentNode:addChild(self.container)
    self:refresh() 
end

function NewHeadIconItem:refresh()
    if self.itemId == "" or self.itemId == "0" or self.itemId == 0 then
        local UserInfo = require("PlayerInfo.UserInfo")
        local icon = common:getPlayeIcon(tonumber(leaderClass / 10), "0") or common:getPlayeIcon(1, "0")
        if NodeHelper:isFileExist(icon) then
            NodeHelper:setSpriteImage(self.container, { mHead = icon })
        end
        NodeHelper:setStringForLabel(self.container, { mLv = UserInfo.roleInfo and UserInfo.roleInfo.level or 1 })
        NodeHelper:setSpriteImage(self.container, { mHeadFrame = GameConfig.MercenaryBloodFrame[1],
                                                    mClass = GameConfig.MercenaryClassImg[leaderClass],
                                                    mElement = GameConfig.MercenaryElementImg[6],
                                                    mMask = "UI/Mask/u_Mask_20.png",
                                                    mStageImg = "UI/Mask/Image_Empty.png" })
        for i = 1, 5 do
            NodeHelper:setNodesVisible(self.container, { ["mStar" .. i] = (4 == i) })
        end
    else
        self.roleTable = NodeHelper:getNewRoleTable(self.itemId)
        local savePath = NodeHelper:getWritablePath()
        if NodeHelper:isFileExist(self.roleTable.icon) then
            NodeHelper:setSpriteImage(self.container, { mHead = self.roleTable.icon })
        else
            if not self.lua_DownloadListener then
                local lua_DownloadHandle = {}
                lua_DownloadHandle.onDownLoaded = function (listener, curlDownloader)
                    local downSize = curlDownloader:getLoadSize()
                    if downSize < 100 then
                        --os.remove(NodeHelper:getWritablePath() .. listener.roleTable.icon)
                    end
                    if NodeHelper:isFileExist(self.roleTable.icon) then
                        NodeHelper:setSpriteImage(self.container, { mHead = self.roleTable.icon })
                    end
                end
                lua_DownloadHandle.onDownLoadFailed = function (listener)
                    os.remove(NodeHelper:getWritablePath() .. listener.roleTable.icon)
                end
                lua_DownloadHandle.container = self.container
                self.lua_DownloadListener = CurlDownloadScriptListener:new(lua_DownloadHandle)
            end
            self.lua_DownloadFilePath = savePath .. self.roleTable.icon
            local urlPath = "http://file.bigwin-tech.com/dev.schoolbattle/hotUpdate/Version/HEADICON/" .. self.roleTable.fileName
            CurlDownload:getInstance():downloadFile(urlPath, self.lua_DownloadFilePath)
            if not self.lua_DownloadSchedulerId then
                self.lua_DownloadSchedulerId = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function(dt)
                    CurlDownload:getInstance():update(0.2)
                end, 0.2, false)
            end
        end
        local mStatus = UserMercenaryManager:getMercenaryStatusByItemId(self.itemId)
        local info = mStatus and mInfo[mStatus.roleId] or nil
        NodeHelper:setStringForLabel(self.container, { mLv = info and info.level or 1 })
        NodeHelper:setSpriteImage(self.container, { mHeadFrame = GameConfig.MercenaryBloodFrame[self.roleTable.blood],
                                                    mClass = GameConfig.MercenaryClassImg[self.roleTable.class],
                                                    mElement = GameConfig.MercenaryElementImg[self.roleTable.element],
                                                    mMask = info and info.starLevel > 0 and "UI/Mask/u_Mask_20_rise.png" or "UI/Mask/u_Mask_20.png",
                                                    mStageImg = info and info.starLevel > 0 and "common_uio2_rise_" .. info.starLevel .. ".png" or "UI/Mask/Image_Empty.png" })
        for i = 1, 5 do
            NodeHelper:setNodesVisible(self.container, { ["mStar" .. i] = (self.roleTable.star == i) })
        end
    end
end

function NewHeadIconItem:resetIcon(idStr)
    self.itemId = idStr
    self.roleTable = NodeHelper:getNewRoleTable(self.itemId)
end

function NewHeadIconItem:setLeaderClass(class)
    leaderClass = class
end

function NewHeadIconItem:visibleIconInfo(visibleMap)
    NodeHelper:setNodesVisible(self.container, visibleMap)
end

function NewHeadIconItem:removeFromParentAndCleanup()
    if self.container then
        self.container:removeFromParentAndCleanup(true)
        self.container:release()
    end
end

function NewHeadIconItem:registerClick(callback)
    self.container:registerFunctionHandler(callback)
end

return NewHeadIconItem