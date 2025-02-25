local UserMercenaryManager = require("UserMercenaryManager")
local ConfigManager = require("ConfigManager")
local GuideManager = require("Guide.GuideManager")
local HP_pb = require("HP_pb")
local NgHeadIconItem = require("NgHeadIconItem")
local thisPageName = "EditMercenaryTeamPage"
local option = {
    ccbiFile = "EditMercenaryTeamPage.ccbi",
    handlerMap =
    {
        onFilter = "onFilter",
        onHelp = "onHelp",
        onReturn = "onReturn",
        onUse = "onUse",
    },
}

local opcodes = {
    -- 获取编队阵型
    GET_FORMATION_EDIT_INFO_C = HP_pb.GET_FORMATION_EDIT_INFO_C,
    -- 返回编队阵型
    GET_FORMATION_EDIT_INFO_S = HP_pb.GET_FORMATION_EDIT_INFO_S,
    -- 编辑编队阵型
    EDIT_FORMATION_C = HP_pb.EDIT_FORMATION_C,
    -- 编辑编队阵型
    EDIT_FORMATION_S = HP_pb.EDIT_FORMATION_S,
}
for i = 1, 8 do
    option.handlerMap["onGroupBtn_" .. i] = "onGroupBtn"
end
for i = 0, 5 do
    option.handlerMap["onElement" .. i] = "onElement"
end
for i = 0, 4 do
    option.handlerMap["onClass" .. i] = "onClass"
end
for i = 1, 5 do
    option.handlerMap["onHead" .. i] = "onHead"
end
-------------------------------------------------------------------------------------------------------
local EditMercenaryTeamBase = { }
local mInfosSort = { }
local mInfosDisorder = { }
local mAllRoleItem = { }    -- 全部頭像
local mRoleNodes = { }  -- 隊伍內頭像
local mCurSelGroupIdx = 1
local openGroupIdx = nil
local mAllGroupInfos = { }
local oriAllGroupInfos = { }

local mbReceiveMsg = false
local misInitScrollView = false

local headIconSize = CCSize(170, 270)

local HERO_NUM = 5
local FILTER_WIDTH = 500
local FILTER_OPEN_HEIGHT = 142
local FILTER_CLOSE_HEIGHT = 74
local filterOpenSize = CCSize(FILTER_WIDTH, FILTER_OPEN_HEIGHT)
local filterCloseSize = CCSize(FILTER_WIDTH, FILTER_CLOSE_HEIGHT)
local currentClass = 0
local currentElement = 0
local upSelectIdx = nil
----------------------------------------------------------------
local TeamHeadItem = { ccbiFile = "EquipmentPage_new_Item.ccbi" }
----------------------------------------------------------------
-- 初始進入頁面
----------------------------------------------------------------
function EditMercenaryTeamBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function EditMercenaryTeamBase:onEnter(container)
    self:registerPacket(container)
    self.mContainer = container
    EditMercenaryTeamBase.mContainer = self.mContainer

    self:clearVar()
    self:initUI(container)
    self:setCurGroupByItemBtn(container)
    self:sendEditInfoReq(mCurSelGroupIdx)

    NgHeadIconItem_setPageType(GameConfig.NgHeadIconType.EDIT_TEAM_PAGE)

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["EditMercenaryTeamBase"] = self.mContainer

    return self.mContainer
end
-- UI初始化
function EditMercenaryTeamBase:initUI(container)
    self.mScrollView = container:getVarScrollView("mContent")
    EditMercenaryTeamBase.mScrollView = self.mScrollView

    -- 設定過濾按鈕
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    filterBg:setContentSize(filterCloseSize)
    NodeHelper:setNodesVisible(container, { mClassNode = false })
    for i = 1, 5 do
        local node = container:getVarNode("mRolePositionNode" .. i)
        node:removeAllChildren()
        mRoleNodes[i] = { attachNode = node }
        NodeHelper:setNodesVisible(container, { ["mSelect" .. i] = false })
    end
    currentClass = 0
    currentElement = 0
    for i = 0, 4 do
        container:getVarSprite("mClass" .. i):setVisible(i == currentClass)
    end
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(i == currentElement)
    end

    NodeHelper:setStringForLabel(container, { mBonusTxt = "" })

    NodeHelper:autoAdjustResizeScrollview(self.mScrollView)
end
-- 初始化變數
function EditMercenaryTeamBase:clearVar()
    if self.mScrollView then
        self.mScrollView:removeAllCell()
        self.mScrollView = nil
    end

    mCurSelGroupIdx = openGroupIdx or 1
    upSelectIdx = nil
    mInfosSort = { }
    mInfosDisorder = { }
    mAllRoleItem = { }
    mRoleNodes = { }  
    mAllGroupInfos = { }
    oriAllGroupInfos = { }

    misInitScrollView = false
    mbReceiveMsg = false
    openGroupIdx = nil
end
----------------------------------------------------------------
-- 按鈕事件
----------------------------------------------------------------
-- 切換隊伍
function EditMercenaryTeamBase:onGroupBtn(container, eventName)
    if not mbReceiveMsg then return end
    local groupIndex = tonumber(eventName:sub(-1))  
    for i = 1, 8 do -- 覆蓋未儲存的編隊資訊
        if oriAllGroupInfos[i] then
            for id = 1, #mAllGroupInfos[i].roleIds do
                mAllGroupInfos[i].roleIds[id] = oriAllGroupInfos[i].roleIds[id]
            end
            mAllGroupInfos[i].name = oriAllGroupInfos[i].name
        end
    end
    mCurSelGroupIdx = groupIndex
    self:initAllHeroScrollView(container)
    self:setCurGroupPageInfo(container, groupIndex)
    self:setCurGroupByItemBtn(container)
end
-- 點擊列表內頭像
function EditMercenaryTeamBase_onHead(id)
    if not mAllGroupInfos[mCurSelGroupIdx] then mAllGroupInfos[mCurSelGroupIdx] = { roleIds = { }, name = "" } end
    if not id then
        return
    end

    if id <= 0 then
        return
    end
    if upSelectIdx then -- 已選擇隊伍內位置 -> 放入指定位置
        local inTeamId = nil
        for i = 1, HERO_NUM do
            if mAllGroupInfos[mCurSelGroupIdx].roleIds[i] == mInfosSort[id].roleId then    -- 隊伍內已有該角色
                inTeamId = i
                break
            end
        end
        local info = mInfosSort[id]
        local info2 = nil
        -- 關閉位置選取
        NodeHelper:setNodesVisible(EditMercenaryTeamBase.mContainer, { ["mSelect" .. upSelectIdx] = false })
        if inTeamId then    -- 更新該角色隊伍內位置頭像
            local sortId = nil
            for k, v in pairs(mInfosSort) do
                if v.roleId == mAllGroupInfos[mCurSelGroupIdx].roleIds[upSelectIdx] then
                    sortId = k
                    break
                end
            end
            info2 = mInfosSort[sortId]
            EditMercenaryTeamBase:refreshTeamHead(mRoleNodes[inTeamId].item, info2)    -- 隊伍內頭像
            mAllGroupInfos[mCurSelGroupIdx].roleIds[inTeamId] = mAllGroupInfos[mCurSelGroupIdx].roleIds[upSelectIdx]
            mRoleNodes[inTeamId].item:setVisible(info2 and true or false)
        end
        -- 更新編隊資訊
        mAllGroupInfos[mCurSelGroupIdx].roleIds[upSelectIdx] = info.roleId
        -- 刷新頭像顯示
        EditMercenaryTeamBase:refreshTeamHead(mRoleNodes[upSelectIdx].item, info)    -- 隊伍內頭像
        EditMercenaryTeamBase.mScrollView:refreshAllCell()  -- ScrollView內頭像
        mRoleNodes[upSelectIdx].item:setVisible(inTeamId and false or true)
        upSelectIdx = nil
    else    -- 沒有選擇過
        local inTeamId = nil
        for i = 1, HERO_NUM do
            if mAllGroupInfos[mCurSelGroupIdx].roleIds[i] == mInfosSort[id].roleId then    -- 隊伍內已有該角色
                inTeamId = i
                break
            end
        end
        if inTeamId then    -- 在隊伍內 -> 移出隊伍
            -- 禁止隊伍沒有角色
            local teamCount = 0
            for i = 1, HERO_NUM do
                if mAllGroupInfos[mCurSelGroupIdx].roleIds[i] ~= 0 then
                    teamCount = teamCount + 1
                end
            end
            if teamCount == 1 then  -- 隊伍剩一隻角色
                MessageBoxPage:Msg_Box_Lan("@OrgTeamNumLimit")
                return
            end
            mAllGroupInfos[mCurSelGroupIdx].roleIds[inTeamId] = 0
            EditMercenaryTeamBase.mScrollView:refreshAllCell()
            mRoleNodes[inTeamId].item:setVisible(false)
        else    -- 不在隊伍 -> 放入隊伍最前面的空位
            local emptyId = nil
            for i = 1, HERO_NUM do
                if not mAllGroupInfos[mCurSelGroupIdx].roleIds[i] or mAllGroupInfos[mCurSelGroupIdx].roleIds[i] <= 0 then
                    emptyId = i
                    break
                end
            end
            if emptyId then
                local info = mInfosSort[id]
                EditMercenaryTeamBase:refreshTeamHead(mRoleNodes[emptyId].item, info)
                mAllGroupInfos[mCurSelGroupIdx].roleIds[emptyId] = info.roleId
                EditMercenaryTeamBase.mScrollView:refreshAllCell()
                mRoleNodes[emptyId].item:setVisible(true)
            else
                MessageBoxPage:Msg_Box_Lan("@OrgTeamFull")
            end
        end
    end
    EditMercenaryTeamBase:refreshCurGroupFight(EditMercenaryTeamBase.mContainer)
    EditMercenaryTeamBase:refreshTeamBuff(EditMercenaryTeamBase.mContainer)
end
-- 點擊隊伍內頭像
function EditMercenaryTeamBase:onHead(container, eventName)
    local idx = tonumber(eventName:sub(-1))
    if upSelectIdx == idx then    -- 已選擇自己 -> 取消選取
        upSelectIdx = nil
        NodeHelper:setNodesVisible(EditMercenaryTeamBase.mContainer, { ["mSelect" .. idx] = false })
    else
        if upSelectIdx then   -- 已選擇其他位置  -> 交換位置
            -- 關閉位置選取
            NodeHelper:setNodesVisible(EditMercenaryTeamBase.mContainer, { ["mSelect" .. upSelectIdx] = false })
            local sortId1, sortId2 = nil, nil
            for k, v in pairs(mInfosSort) do
                if v.roleId == mAllGroupInfos[mCurSelGroupIdx].roleIds[upSelectIdx] then
                    sortId1 = k
                end
                if v.roleId == mAllGroupInfos[mCurSelGroupIdx].roleIds[idx] then
                    sortId2 = k
                end
                if sortId1 and sortId2 then
                    break
                end
            end
            -- 刷新頭像顯示
            EditMercenaryTeamBase:refreshTeamHead(mRoleNodes[upSelectIdx].item, mInfosSort[sortId2])
            EditMercenaryTeamBase:refreshTeamHead(mRoleNodes[idx].item, mInfosSort[sortId1])
            mRoleNodes[upSelectIdx].item:setVisible(mInfosSort[sortId2] and true or false)
            mRoleNodes[idx].item:setVisible(mInfosSort[sortId1] and true or false)
            -- 更新編隊資訊
            local id1 = mAllGroupInfos[mCurSelGroupIdx].roleIds[upSelectIdx]
            local temp = mAllGroupInfos[mCurSelGroupIdx].roleIds[idx]
            mAllGroupInfos[mCurSelGroupIdx].roleIds[upSelectIdx] = temp
            mAllGroupInfos[mCurSelGroupIdx].roleIds[idx] = id1
            upSelectIdx = nil
        else    -- 沒有選擇過 -> 選取目標
            upSelectIdx = idx
            NodeHelper:setNodesVisible(EditMercenaryTeamBase.mContainer, { ["mSelect" .. idx] = true })
        end
    end
    EditMercenaryTeamBase:refreshCurGroupFight(container)
    EditMercenaryTeamBase:refreshTeamBuff(container)
end
-- 展開/收起過濾按鈕
function EditMercenaryTeamBase:onFilter(container)
    local isShowClass = container:getVarNode("mClassNode"):isVisible()
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    if isShowClass then
        filterBg:setContentSize(filterCloseSize)
        NodeHelper:setNodesVisible(container, { mClassNode = false })
    else
        filterBg:setContentSize(filterOpenSize)
        NodeHelper:setNodesVisible(container, { mClassNode = true })
    end
end
-- 過濾職業
function EditMercenaryTeamBase:onClass(container, eventName)
    currentClass = tonumber(eventName:sub(-1))
    if mAllRoleItem then
        for i = 1, #mAllRoleItem do
            local isVisible = (currentElement == mAllRoleItem[i].roleData.element or currentElement == 0) and
                              (currentClass == mAllRoleItem[i].roleData.class or currentClass == 0)
            mAllRoleItem[i].cell:setVisible(isVisible)
            mAllRoleItem[i].cell:setContentSize(isVisible and headIconSize or CCSize(0, 0))
        end
    end
    for i = 0, 4 do
        self.mContainer:getVarSprite("mClass" .. i):setVisible(currentClass == i)
    end
    self.mScrollView:orderCCBFileCells()
end
-- 過濾屬性
function EditMercenaryTeamBase:onElement(container, eventName)
    currentElement = tonumber(eventName:sub(-1))
    if mAllRoleItem then
        for i = 1, #mAllRoleItem do
            local isVisible = (currentElement == mAllRoleItem[i].roleData.element or currentElement == 0) and
                              (currentClass == mAllRoleItem[i].roleData.class or currentClass == 0)
            mAllRoleItem[i].cell:setVisible(isVisible)
            mAllRoleItem[i].cell:setContentSize(isVisible and headIconSize or CCSize(0, 0))
        end
    end
    for i = 0, 5 do
        self.mContainer:getVarSprite("mElement" .. i):setVisible(currentElement == i)
    end
    self.mScrollView:orderCCBFileCells()
end
-- 返回
function EditMercenaryTeamBase:onReturn(container)
    PageManager.popPage(thisPageName)
end
-- 編隊
function EditMercenaryTeamBase:onUse(container)
    if not mbReceiveMsg then return end
    EditMercenaryTeamBase:sendEditTeamFormation(mCurSelGroupIdx, mAllGroupInfos[mCurSelGroupIdx].roleIds)
end
----------------------------------------------------------------
-- UI顯示
----------------------------------------------------------------
-- 建立隊伍頭像
function EditMercenaryTeamBase:initCurGroupHeads(container)
    for k, v in pairs(mRoleNodes) do
        if v.attachNode then
            v.attachNode:removeAllChildren()
            local headNode = self:newHeadItem(k)
            v.attachNode:addChild(headNode)
            mRoleNodes[k].item = headNode
        end
    end
end
-- 建立單一個隊伍頭像
function EditMercenaryTeamBase:newHeadItem(nIdx)
    local groupInfos = oriAllGroupInfos[mCurSelGroupIdx]
    local headNode = ScriptContentBase:create(TeamHeadItem.ccbiFile)
    headNode:release()
    local nShowName = true
    if nIdx <= 5 then
        nShowName = false
    end
    local info = nil
    if groupInfos and groupInfos.roleIds then
        local roleId = groupInfos.roleIds[nIdx]
        local index = 0
        if roleId then
            info = mInfosDisorder[roleId]
            if info then
                for k, v in pairs(mAllRoleItem) do
                    if info.itemId == v.roleData.itemId then
                        index = v.handler.id
                    end
                end
                headNode:setVisible(true)
            else
                headNode:setVisible(false)
            end

        end
    end

    EditMercenaryTeamBase:refreshTeamHead(headNode, info)
    NodeHelper:setNodesVisible(headNode, { mSelectFrame = false })
    return headNode, handler
end
-- 建立英雄列表頭像
function EditMercenaryTeamBase:initAllHeroScrollView(container)
    --if misInitScrollView then
    --    return
    --end
    if self.mScrollView then
        mInfosSort, mInfosDisorder = self:getMercenaryInfos()
        self.mScrollView:removeAllCell()
        mAllRoleItem = { }
        local GuideManager = require("Guide.GuideManager")
        for i = 1, #mInfosSort do
            local roleInfo = UserMercenaryManager:getUserMercenaryById(mInfosSort[i].roleId)
            local iconItem = NgHeadIconItem:createCCBFileCell(mInfosSort[i].roleId, i, self.mScrollView, GameConfig.NgHeadIconType.EDIT_TEAM_PAGE)
            NgHeadIconItem:setRoleData(iconItem)
            table.insert(mAllRoleItem, iconItem)
        end
        self.mScrollView:orderCCBFileCells()
        if not mAllRoleItem then
            mAllRoleItem = { }
        end
        misInitScrollView = true
    end
end
-- 取得全部擁有的英雄資訊(排序後)
function EditMercenaryTeamBase:getMercenaryInfos()
    local infos = UserMercenaryManager:getMercenaryStatusInfos()
    local tblsort = { }
    local tbldisorder = { }
    local index = 1
    for k, v in pairs(infos) do
        if v.type ~= Const_pb.RETINUE and v.roleStage == Const_pb.IS_ACTIVITE then 
            table.insert(tblsort, v)
            tbldisorder[v.roleId] = v
            tbldisorder[v.roleId].index = index
            index = index + 1
        end
    end

    if #tblsort > 0 then
        table.sort(tblsort, function(info1, info2)
            if info1 == nil or info2 == nil then
                return false
            end
            local mInfo = UserMercenaryManager:getUserMercenaryInfos()
            local mInfo1 = mInfo[info1.roleId]
            local mInfo2 = mInfo[info2.roleId]
            if mInfo1 == nil then
                return false
            end
            if mInfo2 == nil then
                return true
            end
            local isInTeam1 = EditMercenaryTeamBase_isInTeam(info1.roleId)
            local isInTeam2 = EditMercenaryTeamBase_isInTeam(info2.roleId)
            if isInTeam1 and not isInTeam2 then
                return true
            elseif not isInTeam1 and isInTeam2 then
                return false
            elseif mInfo1.level ~= mInfo2.level then
                return mInfo1.level > mInfo2.level
            elseif mInfo1.starLevel ~= mInfo2.starLevel then
                return mInfo1.starLevel > mInfo2.starLevel
            elseif mInfo1.fight ~= mInfo2.fight then
                return mInfo1.fight > mInfo2.fight
            elseif mInfo1.singleElement ~= mInfo2.singleElement then
                return mInfo1.singleElement < mInfo2.singleElement
            end
            return false
        end )
    end

    return tblsort, tbldisorder
end
-- 更新隊伍頭像顯示
function EditMercenaryTeamBase:refreshTeamHead(container, info)
    if not info then
        return
    end

    local mInfo = UserMercenaryManager:getUserMercenaryInfos()
    local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(info.itemId)
    local quality = (roleInfo.starLevel <= 5 and 4) or (roleInfo.starLevel >= 11 and 6) or 5
    local heroCfg = ConfigManager.getNewHeroCfg()[info.itemId]
    NodeHelper:setSpriteImage(container, { mFrame = GameConfig.MercenaryRarityFrame[quality],
                                                mIcon = "UI/RoleShowCards/Hero_" .. string.format("%02d", info.itemId) .. string.format("%03d", roleInfo.skinId) .. ".png",
                                                mElement = GameConfig.MercenaryElementImg[heroCfg.Element],
                                                mClass=GameConfig.MercenaryClassImg[heroCfg.Job] })
    NodeHelper:setNodesVisible(container, { mInTeamImg = false, mLv = true, mBpNode = true, mStarNode = true, mRedPoint = false, mBarNode = false, mInExpedition = false,
                                            mStarBg = false, mClass = true, mMaskNode = false })
    NodeHelper:setStringForLabel(container, { mLv = "Lv." .. roleInfo.level, 
                                              mBp = "BP " .. roleInfo.fight })

    for i = 1, 13 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = false })
    end

     NodeHelper:setNodesVisible(container,{mSr=false,mSsr=false,mUr=false,mBp=true})
   
end
-- 刷新戰力顯示
function EditMercenaryTeamBase:refreshCurGroupFight(container)
    local nAllFight = 0
    local groupInfos = mAllGroupInfos[mCurSelGroupIdx]
    if groupInfos and groupInfos.roleIds then
        for i = 1, HERO_NUM do
            --local info = mInfosDisorder[groupInfos.roleIds[i]]
            local info = UserMercenaryManager:getUserMercenaryById(groupInfos.roleIds[i])
            if info then
                nAllFight = nAllFight + info.fight
            end
        end
    end
    UserInfo.roleInfo.marsterFight = nAllFight
    NodeHelper:setStringForLabel(container, { mFightingNum = nAllFight })
end
-- 設定分頁按鈕狀態
function EditMercenaryTeamBase:setCurGroupByItemBtn(container)
    for i = 1, 8 do
        NodeHelper:setNodesVisible(container, { ["mSelectEffect" .. i] = (mCurSelGroupIdx == i) })
        NodeHelper:setMenuItemEnabled(container, "mGroupBtn_" .. i, not (mCurSelGroupIdx == i))
    end
end
-- 更新分頁顯示
function EditMercenaryTeamBase:setCurGroupPageInfo(container, nCurGroup)
    mCurSelGroupIdx = nCurGroup
    
    if oriAllGroupInfos[mCurSelGroupIdx] == nil then
        self:sendEditInfoReq(mCurSelGroupIdx)
        return
    end
    if not self.mContainer then self.mContainer = EditMercenaryTeamBase.mContainer end
    if not self.mScrollView then self.mScrollView = EditMercenaryTeamBase.mScrollView end

    self:initCurGroupHeads(container)
    self:refreshCurGroupFight(container)
    self:refreshTeamBuff(container)
    if upSelectIdx then
        NodeHelper:setNodesVisible(EditMercenaryTeamBase.mContainer, { ["mSelect" .. upSelectIdx] = false })
        upSelectIdx = nil
    end

    self.mScrollView:refreshAllCell()
end
-- 更新屬性加成顯示
function EditMercenaryTeamBase:refreshTeamBuff(container)
    local elementTable = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }
    local buffTable = { }
    local teamBuffCfg = ConfigManager.getTeamBuffCfg()
    for i = 1, HERO_NUM do
        local roleInfo = UserMercenaryManager:getUserMercenaryById(mAllGroupInfos[mCurSelGroupIdx].roleIds[i])
        if roleInfo then
            local heroCfg = ConfigManager.getNewHeroCfg()[roleInfo.itemId]
            local element = heroCfg.Element
            elementTable[element] = elementTable[element] + 1
        end
    end
    for element = 1, #elementTable do
        if elementTable[element] > 0 then
            for id = 1, #teamBuffCfg do
                if teamBuffCfg[id].Attr == element and teamBuffCfg[id].Num == elementTable[element] then
                    local buffs = common:split(teamBuffCfg[id].Buff, ",")
                    for idx = 1, #buffs do
                        local buffId, _type, num = unpack(common:split(buffs[idx], "_"))
                        buffId = tonumber(buffId)
                        _type = tonumber(_type)
                        num = tonumber(num)
                        buffTable[buffId] = buffTable[buffId] or { }
                        buffTable[buffId][_type] = buffTable[buffId][_type] and buffTable[buffId][_type] + num or num
                    end
                    break
                end
            end
        end
    end
    local sortTable = { }
    for buffId, v in pairs(buffTable) do
        table.insert(sortTable, { buffId = buffId, data = v })
    end
    table.sort(sortTable, function(data1, data2)
        if not data1 or not data2 then
            return false
        end
        if data1.buffId ~= data2.buffId then
            return data1.buffId < data2.buffId
        end
        return false
    end)
    local str = ""
    local count = 1
    for i = 1, #sortTable do
        for _type, num in pairs(sortTable[i].data) do
            local str0 = ""
            if count ~= 1 then
                str0 = ", "
            else
                str = ""
            end
            local str1 = common:getLanguageString("@AttrName_" .. sortTable[i].buffId)
            local str2 = ""
            --if buffId == 113 then
            --    str1 = common:getLanguageString("@Damage")
            --elseif buffId == 106 then
            --    str1 = common:getLanguageString("@Armor")
            --elseif buffId == 2103 then
            --    str1 = common:getLanguageString("@AttrName_1007")
            --end
            if _type == 1 then
                num = num / 100
                str2 = "%"
            end
            str = str .. str0 .. str1 .. " +" .. num .. str2
            count = count + 1
        end
    end
    local imgStr = "TeamBuff_"
    local bonusCount = 0
    for i = 1, #elementTable do
        if elementTable[i] > 1 then
            imgStr = imgStr .. i
            bonusCount = bonusCount + 1
        end
    end
    if bonusCount > 0 then
        imgStr = imgStr .. ".png"
    else
        imgStr = "TeamBuff_6.png"
    end
    NodeHelper:setSpriteImage(container, { mBonusImg = imgStr })
    NodeHelper:setStringForLabel(container, { mBonusTxt = str })
end
function EditMercenaryTeamBase:refreshPage(container)
    self:initAllHeroScrollView(container)
    self:setCurGroupPageInfo(container, mCurSelGroupIdx)
end
-- 取得是否在當前隊伍中
function EditMercenaryTeamBase_isInTeam(roleId)
    local isInTeam = false
    if not mAllGroupInfos[mCurSelGroupIdx] then
        return isInTeam
    end
    for i = 1, #mAllGroupInfos[mCurSelGroupIdx].roleIds do
        if mAllGroupInfos[mCurSelGroupIdx].roleIds[i] == roleId then
            isInTeam = true
            break
        end
    end
    return isInTeam
end
----------------------------------------------------------------
function EditMercenaryTeamBase:saveTeamInfo(index)
    if index == 1 then  -- 只有第一隊會設定出戰狀態
        for i = 1, #oriAllGroupInfos[index].roleIds do
            local isInNewTeam = false
            for j = 1, #mAllGroupInfos[index].roleIds do
                if oriAllGroupInfos[index].roleIds[i] == mAllGroupInfos[index].roleIds[j] then
                    isInNewTeam = true
                    break
                end
            end
            if not isInNewTeam then
                -- 移除出戰狀態
                UserMercenaryManager:removeMercenaryStateBattleByRoleId(oriAllGroupInfos[index].roleIds[i])
            end
        end
        for i = 1, #mAllGroupInfos[index].roleIds do
            local isInOldTeam = false
            for j = 1, #oriAllGroupInfos[index].roleIds do
                if mAllGroupInfos[index].roleIds[i] == oriAllGroupInfos[index].roleIds[j] then
                    isInOldTeam = true
                    break
                end
            end
            if not isInOldTeam then
                -- 新增出戰狀態
                UserMercenaryManager:addMercenaryStateBattleByRoleId(mAllGroupInfos[index].roleIds[i])
            end
        end
    end
    if mAllGroupInfos[index] then
        oriAllGroupInfos[index] = oriAllGroupInfos[index] or { }
        oriAllGroupInfos[index].roleIds = oriAllGroupInfos[index].roleIds or { }
        for id = 1, #mAllGroupInfos[index].roleIds do
            oriAllGroupInfos[index].roleIds[id] = mAllGroupInfos[index].roleIds[id]
        end
        oriAllGroupInfos[index].name = mAllGroupInfos[index].name
    end

    local groupStr = mAllGroupInfos[index].name .. "_"
    for i = 1, #mAllGroupInfos[index].roleIds do
        if mAllGroupInfos[index].roleIds[i] then
            groupStr = groupStr .. mAllGroupInfos[index].roleIds[i] .. "_"
        else
            groupStr = groupStr .. "0_"
        end
    end
    CCUserDefault:sharedUserDefault():setStringForKey("GROUP_INFOS_" .. index .. "_" .. UserInfo.playerInfo.playerId, groupStr)
end

function EditMercenaryTeamBase:onExit(container)
    --self:clearVar()
    if self.mScrollView then
        self.mScrollView:removeAllCell()
        self.mScrollView = nil
    end
    self:removePacket(container)
end
----------------------------------------------------------------
-- Server協定
----------------------------------------------------------------
-- 請求隊伍資訊
function EditMercenaryTeamBase:sendEditInfoReq(index)
    local msg = Formation_pb.HPFormationEditInfoReq()
    msg.index = index
    common:sendPacket(HP_pb.GET_FORMATION_EDIT_INFO_C, msg, true)
end
-- 請求編輯隊伍
function EditMercenaryTeamBase:sendEditTeamFormation(nGroupIdx, roleIds)
    local msg = Formation_pb.HPFormationEditReq()
    msg.index = nGroupIdx

    -- 檢查隊伍是否是全空
    local teamCount = 0
    for i = 1, #roleIds do
        if roleIds[i] then
            msg.roleIds:append(roleIds[i])
            if roleIds[i] ~= 0 and i <= HERO_NUM then
                teamCount = teamCount + 1
            end
        else
            msg.roleIds:append(0)
        end
    end
    if teamCount <= 0 then
        MessageBoxPage:Msg_Box_Lan("@OrgTeamNumLimit")
    end
    common:sendPacket(HP_pb.EDIT_FORMATION_C, msg, false)
end

function EditMercenaryTeamBase:parseAllGroupInfosMsg_New(msg)
    local formation = msg.formations
    mAllGroupInfos[formation.index] = { roleIds = { } }
    mAllGroupInfos[formation.index].name = formation.name
    oriAllGroupInfos[formation.index] = { roleIds = { } }
    oriAllGroupInfos[formation.index].name = formation.name
    for i = 1, #formation.roleIds do
        table.insert(mAllGroupInfos[formation.index].roleIds, formation.roleIds[i])
        table.insert(oriAllGroupInfos[formation.index].roleIds, formation.roleIds[i])
    end
    EditMercenaryTeamBase:saveTeamInfo(formation.index)
end

function EditMercenaryTeamBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.GET_FORMATION_EDIT_INFO_S then
        -- 編隊資訊
        local msg = Formation_pb.HPFormationEditInfoRes()
        msg:ParseFromString(msgBuff)
        self:parseAllGroupInfosMsg_New(msg)
        self:refreshPage(container)
        mbReceiveMsg = true
    elseif opcode == HP_pb.EDIT_FORMATION_S then
        -- 編輯隊伍
        local msg = Formation_pb.HPFormationUseRes()
        msg:ParseFromString(msgBuff)
        MessageBoxPage:Msg_Box(common:getLanguageString("@OrgTeamFinish"))
        EditMercenaryTeamBase:saveTeamInfo(mCurSelGroupIdx)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        self:refreshPage(container)
        if mCurSelGroupIdx == 8 then
            require("ArenaPage")
            ArenaPage_Reset()
            local msg = MsgMainFrameRefreshPage:new()
            msg.pageName = "ArenaPage"
            msg.extraParam = "EditTeam"
            MessageManager:getInstance():sendMessageForScript(msg)
        end
    end
end

function EditMercenaryTeamBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EditMercenaryTeamBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
function EditMercenaryTeamBase_setOpenGroupIdx(idx)
    openGroupIdx = idx
    if openGroupIdx ~= 1 and openGroupIdx ~= 8 then
        openGroupIdx = nil
    end
end
----------------------------------------------------------------
function EditMercenaryTeamBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARY_EDIT_GROUP)
end
----------------------------------------------------------------
-- 新手教學
function EditMercenaryTeamBase_onGuideHead(container, idx)
    --for k, v in pairs(mAllRoleItem) do
    --    if id == 1 then
    --        selectIdx = k
    --        NodeHelper:setNodesVisible(v.cls.container, { mSelectFrame = true })
    --        EditMercenaryTeamBase.mScrollView:refreshAllCell()
    --        break
    --    end
    --end
    EditMercenaryTeamBase_onHead(idx)
end
function EditMercenaryTeamBase_onGuidePos1(container)
    local info = mInfosSort[1]
    -- 關閉位置選取
    --NodeHelper:setNodesVisible(mAllRoleItem[1].cls.container, { mSelectFrame = false })
    -- 更新編隊資訊
    mAllGroupInfos[mCurSelGroupIdx].roleIds[1] = info.roleId
    -- 刷新頭像顯示
    EditMercenaryTeamBase:refreshTeamHead(mRoleNodes[1].item, info)    -- 隊伍內頭像
    EditMercenaryTeamBase.mScrollView:refreshAllCell()  -- ScrollView內頭像 
end
function EditMercenaryTeamBase_onUse(container)
    if not mbReceiveMsg then return end
    EditMercenaryTeamBase:sendEditTeamFormation(mCurSelGroupIdx, mAllGroupInfos[mCurSelGroupIdx].roleIds)
end
-- 返回
function EditMercenaryTeamBase_onReturn(container)
    PageManager.popPage(thisPageName)
end
-------------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
EditMercenaryTeamBase = CommonPage.newSub(EditMercenaryTeamBase, thisPageName, option)

return EditMercenaryTeamBase