local thisPageName = "PhotoBDSMPopup"
local UserMercenaryManager = require("UserMercenaryManager")
local FetterManager = require("FetterManager")
local FetterGirlsDiary = require("FetterGirlsDiary")

local option = {
    ccbiFile = "Photo_BDSM.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp",
    },
    opcodes =
    {
        ROLE_UPGRADE_STAGE_S = HP_pb.ROLE_UPGRADE_STAGE_S,
        ROLE_UPGRADE_STAGE2_S = HP_pb.ROLE_UPGRADE_STAGE2_S,
    }
}
for i = 1, 4 do
    option.handlerMap["onTouchPhoto" .. i] = "onTouchPhoto"
end

local PhotoBDSMPopup = { }

local uiPhotoNum = 3
local roleId = 0
local albumCfg = ConfigManager:getAlbumCfg()
local roleCfg = ConfigManager:getRoleCfg()

local nonOpenTxtVar = {}
local photoVar = {}
local photoMask = {}
local unlockTxtVar = {}
for i = 1, uiPhotoNum do
    nonOpenTxtVar[i] = "mNonOpenTxt" .. i
    photoVar[i] = "mPhoto" .. i
    photoMask[i] = "mPhotoMask" .. i
    unlockTxtVar[i] = "mUnLockTxt" .. i
end

local myContainer = nil
local mScrollView = nil

local mStageDiff = { ["oriPhoto"] = 2, ["skinPhoto"] = 3, ["stage2"] = 1, ["oriTxt"] = 1, ["skinTxt"] = 5 }

local PhotoBDSMContent = {
    ccbiFile = "Photo_BDSM_Content.ccbi",
}

local tutorialPanel = nil

function PhotoBDSMContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function PhotoBDSMContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self:initPhoto(container)
end

function PhotoBDSMContent:onTouchPhoto(container)
    local mercenaryInfo = UserMercenaryManager:getUserMercenaryByItemId(self.roleId)
    local roleStageLevel = 0
    if mercenaryInfo then
        roleStageLevel = mercenaryInfo.stageLevel
    else
        return
    end

    local diff = mStageDiff["oriPhoto"]
    if self.isSkin then
        diff = mStageDiff["skinPhoto"]
    end
    if (roleStageLevel >= self.photoId + diff) then
        if self.isSkin then
            local skininfo = UserMercenaryManager:getUserMercenaryByItemId(self.roleId)
            if skininfo and skininfo.stageLevel2 < self.photoId + mStageDiff["stage2"] then
                local FashionLockPopUp = require('FashionLockPopUp')
                FashionLockPopUp:setUnlockItemId(self.roleId)
                PageManager.pushPage("FashionLockPopUp")
                return
            end
        end
        
        local diaryPage = require("FetterGirlsDiary")
        diaryPage:setIsPhoto(container, true)
        diaryPage:setPhotoRole(container, self.roleId, self.photoId)
        PageManager.pushPage("FetterGirlsDiary")
    else
        local EquipMercenaryPage = require("EquipMercenaryPage")
        EquipMercenaryPage:setMercenaryId(mercenaryInfo.roleId,false)
        EquipMercenaryPage_onRisingStar()
    end
end

function PhotoBDSMContent:initPhoto(container)
    local mercenaryInfo = UserMercenaryManager:getUserMercenaryByItemId(self.roleId)
    local roleStageLevel = 0
    if mercenaryInfo then
        roleStageLevel = mercenaryInfo.stageLevel
    end
    local img = container:getVarMenuItemImage("mPhoto")
    -- 設定相片
    local photoImg = nil
    local diff = mStageDiff["oriPhoto"]
    local txtDiff = mStageDiff["oriTxt"]
    if roleStageLevel < self.photoId + diff then
        photoImg = CCSprite:create("Role_" .. self.roleId .. "0" .. self.photoId .. "_0.png")
    else
        photoImg = CCSprite:create("Role_" .. self.roleId .. "0" .. self.photoId .. "_1.png")
    end
    if photoImg then
        img:setNormalImage(photoImg)
    else
        img:setNormalImage(CCSprite:create("photo_on.png"))
    end
    if self.isSkin then
        diff = mStageDiff["skinPhoto"]
        txtDiff = mStageDiff["skinTxt"]
        local skininfo = UserMercenaryManager:getUserMercenaryByItemId(self.roleId)
        NodeHelper:setNodesVisible(container, {["mPhotoMask"] = roleStageLevel < self.photoId + diff or skininfo.stageLevel2 < self.photoId + mStageDiff["stage2"] })
        NodeHelper:setStringForLabel(container, { ["mUnlockTxt"] = common:getLanguageString("@Photounlock_" .. (self.photoId + txtDiff)) })
    else
        NodeHelper:setNodesVisible(container, {["mPhotoMask"] = roleStageLevel < self.photoId + diff})
        NodeHelper:setStringForLabel(container, { ["mUnlockTxt"] = common:getLanguageString("@Photounlock_" .. (self.photoId + txtDiff)) })
    end
    
    NodeHelper:setStringForLabel(container, { ["mUnlockName"] = common:getLanguageString("@Role_" .. self.roleId) })
    
end

function PhotoBDSMPopup:createPhoto(container, roleId, photoId, isSkin)
    local titleCell = CCBFileCell:create()
    local panel = PhotoBDSMContent:new( { roleId = roleId, photoId = photoId, isSkin = isSkin })
    titleCell:registerFunctionHandler(panel)
    titleCell:setCCBFile(PhotoBDSMContent.ccbiFile)
    mScrollView:addCellBack(titleCell)
    if roleId == 111 and photoId == 1 then
        tutorialPanel = panel
    end 
end

function PhotoBDSMPopup:onTouchPhoto(container)
    if tutorialPanel then
        tutorialPanel:onTouchPhoto(container)
    end
end

function PhotoBDSMPopup:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function PhotoBDSMPopup:onEnter(container)
    mScrollView = container:getVarScrollView("mPhotoScrollView")
    myContainer = container
    tutorialPanel = nil
    self:registerPacket(container)
    self:refreshPage(container)
end

function PhotoBDSMPopup:createAllPhoto(container)
    mScrollView:removeAllCell()
    local nowRoleId = FetterManager.getRoleIdByFetterId(FetterManager.getViewFetterId())   --開啟的相簿角色id
    local allRoleId = {}
    --先塞入非皮膚角色
    if roleCfg[nowRoleId].FashionInfos then    --FashionInfo有資料=>開啟的角色為皮膚
        allRoleId[1] = roleCfg[nowRoleId].FashionInfos[2]
    else
        allRoleId[1] = nowRoleId
    end
    if roleCfg[allRoleId[1]].modelId > 0 then --ModelId有資料=>有皮膚角色
        allRoleId[2] = roleCfg[allRoleId[1]].modelId
    end
    for roleIndex = 1, #allRoleId do
        local roleId = allRoleId[roleIndex]
        local albumNum = albumCfg[roleId].Photo
        for albumIndex = 1, albumNum - 2 do
            local isSkin = false
            if roleIndex > 1 then
                isSkin = true
            end
            self:createPhoto(container, roleId, albumIndex, isSkin)
        end
    end
    mScrollView:orderCCBFileCells()
end

function PhotoBDSMPopup:getContainer(container)
    return myContainer
end

function PhotoBDSMPopup:onClose(container)
    PageManager.popPage(thisPageName)
end

function PhotoBDSMPopup:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ALBUM)
end

function PhotoBDSMPopup:onExecute(container)
end

function PhotoBDSMPopup.onFunction(eventName, container)
    if eventName ~= "luaExecute" then
    end
    if eventName == "luaInit" then
        self:onInit(container)
    elseif eventName == "luaLoad" then
        self:onLoad(container)
    elseif eventName == "luaEnter" then
        self:onEnter(container)
    elseif eventName == "luaExit" then
        self.onExit(container)
    end
end

function PhotoBDSMPopup:refreshPage(container)
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.IsNeedShowPage == true and GuideManager.getCurrentStep() == 184 then
        GuideManager.PageContainerRef["PhotoBDSMPopup"] = container
        PageManager.pushPage("NewbieGuideForcedPage")
        PageManager.popPage("NewGuideEmptyPage")
        --GuideManager.IsNeedShowPage = false;
    end
    self:createAllPhoto(container)
end

function PhotoBDSMPopup:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ROLE_UPGRADE_STAGE_S or opcode == HP_pb.ROLE_UPGRADE_STAGE2_S then
        self:refreshPage(container)
    end
end

function PhotoBDSMPopup:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function PhotoBDSMPopup:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function PhotoBDSMPopup:onExit(container)
    self:removePacket(container)
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local PhotoBDSMPopupPage = CommonPage.newSub(PhotoBDSMPopup, thisPageName, option)

return PhotoBDSMPopupPage