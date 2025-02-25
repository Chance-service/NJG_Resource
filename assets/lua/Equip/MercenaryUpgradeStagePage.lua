----------------------------------------------------------------------------------
-- 英雄突破
----------------------------------------------------------------------------------
local thisPageName = "MercenaryUpgradeStagePage"
local MercenaryUpgradeStagePage = { }
local NodeHelper = require("NodeHelper")
local UserMercenaryManager = require("UserMercenaryManager")
local UserInfo = require("PlayerInfo.UserInfo")
local option = {
    ccbiFile = "MercenaryUpgradeStarHeroPopUp.ccbi",
    handlerMap =
    {
        onReturn = "onReturn",
        onClose = "onReturn",
        onConfirm = "onConfirm",
    },
}
local opcodes = {
}
local mercenaryHeadContent = {
    ccbiFile = "FormationTeamContent.ccbi"
}
local _mercenaryInfos = { }
local _mercenaryContainerInfo = { }
local _curMercenaryId = nil
local _curMercenaryInfo = nil
local HEAD_SCALE = 1.12
local headIconSize = CCSize(130 * HEAD_SCALE, 130 * HEAD_SCALE)
local tempSelectId = nil
local tempSelectInfo = nil
MercenaryUpgradeStagePage._selectMercenaryId = nil
MercenaryUpgradeStagePage._selectMercenaryInfo = nil
MercenaryUpgradeStagePage.mScrollview = nil
----------------------------------------------------------------------------------
function mercenaryHeadContent:onHead(container)
    if self.isEquip then
        MessageBoxPage:Msg_Box_Lan("@HeroWithoutEquip")
    else
        if self.info.level > 1 and tempSelectId ~= self.roleTable.id then
            local selectHero = function(flag)
                if flag then
                    tempSelectId = self.roleTable.id
                    tempSelectInfo = self.dataInfo
                    MercenaryUpgradeStagePage.mScrollview:refreshAllCell()
                end
            end
            PageManager.showConfirm(common:getLanguageString("@MercenaryCulture"), common:getLanguageString("@BreakthroughCheck"), selectHero)
        else
            if tempSelectId ~= self.roleTable.id then
                tempSelectId = self.roleTable.id
                tempSelectInfo = self.dataInfo
            else
                tempSelectId = nil
                tempSelectInfo = nil
            end
            MercenaryUpgradeStagePage.mScrollview:refreshAllCell()
        end
    end
end

function mercenaryHeadContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    local index = self.id
    local dataInfo = _mercenaryInfos.roleInfos[index]
    _mercenaryContainerInfo[index] = container
    --
    if not self.roleTable or self.roleTable.id ~= dataInfo.roleId then
        self.roleTable = NodeHelper:getNewRoleTable(dataInfo.itemId)
    end

    local savePath = NodeHelper:getWritablePath()
    if NodeHelper:isFileExist(self.roleTable.icon) then
        NodeHelper:setSpriteImage(container, { mHead = self.roleTable.icon })
    end
    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    self.info = mInfo[dataInfo.roleId]
    local info2 = UserMercenaryManager:getUserMercenaryById(self.roleTable.id)
    local equipInfo = info2.equips
    self.isEquip = (#equipInfo > 0)
    NodeHelper:setSpriteImage(container, { mHeadFrame = GameConfig.MercenaryBloodFrame[self.roleTable.blood],
                                           mClass = GameConfig.MercenaryClassImg[self.roleTable.class],
                                           mElement = GameConfig.MercenaryElementImg[self.roleTable.element],
                                           mMask = self.info.starLevel > 0 and "UI/Mask/u_Mask_20_rise.png" or "UI/Mask/u_Mask_20.png",
                                           mStageImg = self.info.starLevel > 0 and "common_uio2_rise_" .. self.info.starLevel .. ".png" or "UI/Mask/Image_Empty.png" })
    NodeHelper:setStringForLabel(container, { mLv = self.info and self.info.level or 1 })
    local isSelling = self.info.activiteState == Const_pb.NOT_ACTIVITE
    NodeHelper:setNodesVisible(container, { mMarkFighting = dataInfo.status == Const_pb.FIGHTING and not isSelling, mMarkChoose = false, mMarkSelling = isSelling, mMask = self.isEquip, 
                                            mSelectFrame = (self.roleTable.id == tempSelectId) })
    for i = 1, 5 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (self.roleTable.star == i) })
    end
end

function MercenaryUpgradeStagePage:buildScrollView(container)
    local count = 0

    local cell = nil
    local items = { }
    local curRoleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
    for i = 1, #_mercenaryInfos.roleInfos do
        local dataInfo = _mercenaryInfos.roleInfos[i]
        local roleTable = NodeHelper:getNewRoleTable(dataInfo.itemId)
        if _mercenaryInfos.roleInfos[i].roleId ~= _curMercenaryId and   -- 不是自己
           roleTable.class == curRoleTable.class and    -- 同職業
           roleTable.token == 0 then    -- 非NFT
            cell = CCBFileCell:create()
            cell:setCCBFile(mercenaryHeadContent.ccbiFile)
            local handler = common:new( { id = i, roleTable = roleTable, dataInfo = dataInfo }, mercenaryHeadContent)
            cell:registerFunctionHandler(handler)
            MercenaryUpgradeStagePage.mScrollview:addCell(cell)
            table.insert(items, { cls = handler, node = cell })
            cell:setScale(HEAD_SCALE)
            cell:setContentSize(headIconSize)

            count = count + 1
        end
    end
    
    if count <= 8 then
        MercenaryUpgradeStagePage.mScrollview:setTouchEnabled(false)
    else
        MercenaryUpgradeStagePage.mScrollview:setTouchEnabled(true)
    end

    MercenaryUpgradeStagePage.mScrollview:orderCCBFileCells()
    self.mAllRoleItem = items
end
----------------------------------------------------------------------------------

function MercenaryUpgradeStagePage:onEnter(container)
    self.container = container
    MercenaryUpgradeStagePage.mScrollview = container:getVarScrollView("mScrollview")
    tempSelectId = MercenaryUpgradeStagePage._selectMercenaryId
    tempSelectInfo = MercenaryUpgradeStagePage._selectMercenaryInfo
    _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
    sortData(_mercenaryInfos.roleInfos)
    self:refreshPage(container)
end

function MercenaryUpgradeStagePage:refreshPage(container)
    self:buildScrollView(container)
end
function MercenaryUpgradeStagePage:onReturn(container)
    _curMercenaryId = nil
    _curMercenaryInfo = nil
    tempSelectId = nil
    tempSelectInfo = nil
    PageManager.popPage(thisPageName)
end
function MercenaryUpgradeStagePage:onConfirm(container)
    MercenaryUpgradeStagePage._selectMercenaryId = tempSelectId
    MercenaryUpgradeStagePage._selectMercenaryInfo = tempSelectInfo
    _curMercenaryId = nil
    _curMercenaryInfo = nil
    PageManager.popPage(thisPageName)
end

--function sortData(info)
--    if info == nil or #info == 0 then
--        return
--    end
--
--    table.sort(info, function(info1, info2)
--        if info1 == nil or info2 == nil then
--            return false
--        end
--        local mInfo = UserMercenaryManager:getUserMercenaryInfos()
--        local mInfo1 = mInfo[info1.roleId]
--        local mInfo2 = mInfo[info2.roleId]
--        if mInfo1 == nil or mInfo2 == nil then
--            return false
--        end
--        if mInfo1.starLevel ~= mInfo2.starLevel then
--            return mInfo1.starLevel > mInfo2.starLevel
--        elseif mInfo1.level ~= mInfo2.level then
--            return mInfo1.level > mInfo2.level
--        elseif mInfo1.fight ~= mInfo2.fight then
--            return mInfo1.fight > mInfo2.fight
--        elseif mInfo1.singleElement ~= mInfo2.singleElement then
--            return mInfo1.singleElement < mInfo2.singleElement
--        end
--        return false
--    end )
--end

function MercenaryUpgradeStagePage:setCurMercenaryId(id)
    _curMercenaryId = id
    _curMercenaryInfo = UserMercenaryManager:getMercenaryStatusById(_curMercenaryId)
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
MercenaryUpgradeStagePage = CommonPage.newSub(MercenaryUpgradeStagePage, thisPageName, option)

return MercenaryUpgradeStagePage