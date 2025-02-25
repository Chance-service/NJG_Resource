-- Author:Ranjinlan
-- Create Data: [2018-05-09 10:58:27]
-- 命格装备页面
local FateDataManager =  require("FateDataManager")
local FateDataInfo =  require("FateDataInfo")
local FateWearsPageBase = {
    ccbiFile = "EquipmentPageMercenaryPrivateContent.ccbi",
    opcodes = {
    }
}
local PageInfo = {
    mMercenaryId,           --副将ID
    isOthers = false,       --是否查看他人命格
    fateList = nil,         --当前副将的命格列表
    ParentContainer,        --
    selfContainer,
    unLockNum = 2,         --猎命装备格子解锁数量
}

local eventMap = {
    ["onEquipPage"] = "onShowEquipPage",  --切换到装备界面
    ["onBadgeGet"] = "onBadgeGet",   --前往十八路诸侯
    ["onGotoBadgePackage"] = "onGotoBadgePackage",--前往徽章背包
    ["luaOnAnimationDone"] = "onAnimationDone",
}
for index = 1,GameConfig.FatePageConst.MaxWearNum do
	eventMap["onBadgeFrame" .. index] = "onSelectBadge";--选择某个命格栏位
end

function FateWearsPageBase.onFunction(eventName,container)
    if eventMap[eventName] then
		FateWearsPageBase[eventMap[eventName]](FateWearsPageBase,container,eventName)
    end
end

function FateWearsPageBase:registerPacket(PageContainer)
    for key, opcode in pairs(FateWearsPageBase.opcodes) do
		if string.sub(key, -1) == "S" then
			PageContainer:registerPacket(opcode)
		end
	end
end

function FateWearsPageBase:removePacket(PageContainer)
	for key, opcode in pairs(FateWearsPageBase.opcodes) do
		if string.sub(key, -1) == "S" then
			PageContainer:removePacket(opcode)
		end
	end
end

function FateWearsPageBase:onReceivePacket(opcode,msgBuff)
    
end

--进入命格装备界面
function FateWearsPageBase:onEnter(ParentContainer)
    PageInfo.ParentContainer = ParentContainer
	if not PageInfo.selfContainer or tolua.isnull(PageInfo.selfContainer) then
		PageInfo.selfContainer = ScriptContentBase:create(FateWearsPageBase.ccbiFile)
	end
	PageInfo.selfContainer:registerFunctionHandler(FateWearsPageBase.onFunction)
    --PageInfo.selfContainer:runAnimation("Ani1")
    self:refreshPage(PageInfo.selfContainer)
    return PageInfo.selfContainer
end

function FateWearsPageBase:refreshPage(container)
    local fateList = PageInfo.fateList or {}
    local visibleMap, imgQulity, strMap, imgMap = {}, {}, {}, {}
    --visibleMap["mPrivateGet"] = not PageInfo.isOthers
    --visibleMap["mPrivatePackage"] = not PageInfo.isOthers
    
    local haveFateToWear = false
    if not PageInfo.isOthers then
        haveFateToWear = FateDataManager:checkShowFateRedPoint(PageInfo.mMercenaryId)
    end
    for index = 1, GameConfig.FatePageConst.MaxWearNum do
        --显示已经穿戴的命格图标
        local childNode = container:getVarMenuItemCCB("mBadgeFrame" .. index)
        childNode = childNode:getCCBFile()
        local fateData = fateList[index]
        if fateData then
            local conf = fateData:getConf()
            strMap["mBadgeLv"]           = "Lv." .. fateData.level --等级
            imgMap["mBadgePic"] 			= conf.icon -- 图标
            imgMap["mBadgeBgPic"] 	= NodeHelper:getImageBgByQuality(conf.quality) --背景框
            imgQulity["mBadgeFrameShade"] 	= conf.quality --品质框
            visibleMap["mBadgePoint"]    = false -- 红点
            for i = 1, GameConfig.FatePageConst.MaxStarNum do
                visibleMap["mBadgeStar" .. i] = conf.starLevel >= i
            end
        else
            strMap["mBadgeLv"]           = ""  --等级
            if PageInfo.isOthers then
                imgMap["mBadgePic"] 			= GameConfig.Image.BackQualityImg-- 图标
            else
                imgMap["mBadgePic"] 			= GameConfig.Image.ClickToSelect -- 图标
            end
            imgMap["mBadgeBgPic" ] 	= GameConfig.Image.BackQualityImg --背景框
            imgQulity["mBadgeFrameShade"]     = GameConfig.Default.Quality --品质框
            visibleMap["mBadgePoint"]    = index <= PageInfo.unLockNum and haveFateToWear -- 红点
            for i = 1, GameConfig.FatePageConst.MaxStarNum do
                visibleMap["mBadgeStar" .. i] = false
            end
        end
        --visibleMap["mBadgePic" .. index]      = true

        NodeHelper:setNodesVisible(childNode, visibleMap)
        NodeHelper:setStringForLabel(childNode, strMap)
        NodeHelper:setSpriteImage(childNode, imgMap)
        NodeHelper:setQualityFrames(childNode, imgQulity, nil, true);
        --visibleMap["mPrivateLockPic" .. index]  = index > PageInfo.unLockNum--锁
    end
    local visibleMapMain = {} 
    visibleMapMain["mEquipBtnNode"] = not PageInfo.isOthers
    visibleMapMain["mEquipBtnNodeOther"] = PageInfo.isOthers
    NodeHelper:setNodesVisible(container, visibleMapMain)
--    local UserMercenaryManager = require("UserMercenaryManager")
--    local redPoint = UserEquipManager:getEquipMercenaryCount(PageInfo.mMercenaryId)
--    local mercenaryInfo = UserMercenaryManager:getUserMercenaryById(PageInfo.mMercenaryId)
--    if mercenaryInfo and mercenaryInfo.status == Const_pb.FIGHTING and redPoint > 0 then
--        visibleMap.mEquipPagePoint = true
--    else
--        visibleMap.mEquipPagePoint = false
--    end
--    if ViewPlayerInfo.isSeeSelfInfoFlag then
--        visibleMap.mEquipPagePoint = false
--    end
--    NodeHelper:setNodesVisible(childNode, visibleMap)
--    NodeHelper:setStringForLabel(childNode, strMap)
--    NodeHelper:setSpriteImage(childNode, imgMap)
--	NodeHelper:setQualityFrames(childNode, imgQulity, nil, true);
end

function FateWearsPageBase:onReceiveMessage(message,typeId)
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == FateDataManager.ModelName then
            local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
            if extraParam == "ResetData" 
            or extraParam == "DeleteData" 
            or extraParam == "UpdateData" then
                FateWearsPageBase:refreshPage(PageInfo.selfContainer)
            end
        end
        
        if not PageInfo.isOthers then
            if PageInfo.unLockNum ~= FateDataManager:getFateWearNum(UserInfo.roleInfo.level) then
                PageInfo.unLockNum = FateDataManager:getFateWearNum(UserInfo.roleInfo.level)
                FateWearsPageBase:refreshPage(PageInfo.selfContainer)
            end
        end
    end
end

function FateWearsPageBase:onExecute(ParentContainer)
end

--退出命格装备界面
function FateWearsPageBase:onExit(ParentContainer)
    PageInfo = {}
end

--点击装备按钮，切换到装备界面
function FateWearsPageBase:onShowEquipPage(container)
    --container:runAnimation("close")
    if PageInfo.isOthers then
        PageManager.refreshPage("ViewPlayerEquipmentPage","HideFatePage")
    else
        PageManager.refreshPage("EquipmentPage","HideFatePage")
    end
end
function FateWearsPageBase:onAnimationDone(container)
    local animationName=tostring(container:getCurAnimationDoneName())
	if animationName=="close" then
        if PageInfo.isOthers then
            PageManager.refreshPage("ViewPlayerEquipmentPage","HideFatePage")
        else
            PageManager.refreshPage("EquipmentPage","HideFatePage")
        end
    end
end

--前往祈福，获得命格
function FateWearsPageBase:onBadgeGet(container)
    if PageInfo.isOthers then
        return
    end
    --require("FateFindPage")
    --FateFindPage_setFromRoleId(PageInfo.mMercenaryId)
    PageManager.changePage("HelpFightMapPage")
end

--前往命格背包界面
function FateWearsPageBase:onGotoBadgePackage(container)
    if PageInfo.isOthers then
        return
    end
    PackagePage_showFateItems(PageInfo.mMercenaryId)
end

--选中某个命格栏位
function FateWearsPageBase:onSelectBadge(container,funName)
    if not PageInfo.fateList then
        return
    end
    local name = string.sub(funName or "", -1) or ""
    local index = tonumber(name)
    if not index then return end
    local fateData = PageInfo.fateList[index]
--    if index > PageInfo.unLockNum then --如果没解锁 提示解锁
--        if PageInfo.isOthers then
--            return
--        end
--        MessageBoxPage:Msg_Box_Lan( common:getLanguageString("@DressTips_3",FateDataManager:getUnlockLevel(index) ) )
    if fateData then --如果有命格 显示命格详情
        require("FateDetailInfoPage")
        FateDetailInfoPage_setFate({
            isOthers = PageInfo.isOthers,
            fateData = fateData,
            locPos = index,
        })
       PageManager.pushPage("FateDetailInfoPage") 
    else--如果没有命格 显示选择命格界面
        if PageInfo.isOthers then
            return
        end
        require("FateWearsSelectPage")
        FateWearsSelectPage_setFate({roleId = PageInfo.mMercenaryId,locPos = index, currentFateId = nil})
        PageManager.pushPage("FateWearsSelectPage") 
    end
end

-- mercenaryId 副将ID
-- isOthers    是否查看他人命格装备
-- fateIdList  当前穿戴的命格列表
-- level       查看好友的等级
function FateWearsPageBase:setFateInfo(data)
    PageInfo.mMercenaryId = data.mercenaryId
    PageInfo.isOthers = data.isOthers or false
    PageInfo.fateList = {}
    for _,dressInfo in ipairs(data.fateIdList or {}) do
        local fateData = nil
        if PageInfo.isOthers then
            fateData = FateDataInfo.newOtherInfo(dressInfo)
        else
            fateData = FateDataManager:getFateDataById(dressInfo.id)
        end
        if fateData then
            PageInfo.fateList[dressInfo.loc] = fateData
        end
    end
    if PageInfo.isOthers then
        PageInfo.unLockNum = FateDataManager:getFateWearNum(data.level)
    else
        PageInfo.unLockNum = FateDataManager:getFateWearNum(UserInfo.roleInfo.level)
    end
end

-- fateIdList  当前穿戴的命格列表
function FateWearsPageBase:refreshFateIdList(fateIdList)
    PageInfo.fateList = {}
    for _,dressInfo in ipairs(fateIdList or {}) do
        local fateData = nil
        if PageInfo.isOthers then
            fateData = FateDataInfo.newOtherInfo(dressInfo)
        else
            fateData = FateDataManager:getFateDataById(dressInfo.id)
        end
        if fateData then
            PageInfo.fateList[dressInfo.loc] = fateData
        end
    end
    self:refreshPage(PageInfo.selfContainer)
end

return FateWearsPageBase