local GVGManager = require("GVGManager")
local UserInfo = require("PlayerInfo.UserInfo")
local GVG_pb = require("GroupVsFunction_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "GVGTeamJoinPage"

local GVGTeamJoinPageBase = {
    showType = 2,
    container = {}
}
 
local option = {
    ccbiFile = "GVGChoiceMercenaryPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onCancel = "onCancel",
        onConfirmation = "onConfirmation"
    },
    opcodes = {
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGChoiceMercenaryContent.ccbi",
    teamList = {}
}

local GVGIntoItem = {
    ccbiFile = "GVGChoiceMercenaryListContent.ccbi"
}

local roleCfg = {}

local choseRoles = {}

function GVGInfoContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function GVGInfoContent:onRefreshContent(ccbRoot)
    local index = self.index
    local container = ccbRoot:getCCBFileNode()


    local cellBegin = (index - 1) * 4
    for i = 1, 4 do
        local cellIndex = cellBegin + i
        local data = GVGInfoContent.teamList[cellIndex]
        local posNode = container:getVarNode("mPosition" .. i)
        if data then
            posNode.data = data
            posNode:setVisible(true)
            GVGIntoItem.init(container,data,i)
        else
            posNode.data = nil
            posNode:setVisible(false)
        end
    end
end

function GVGIntoItem.onSelect(container, index)
    --local chose = false
    local posNode = container:getVarNode("mPosition" .. index)
    if posNode.data then
        local roleId = posNode.data.roleId
        if common:table_hasValue(choseRoles,roleId ) then
            choseRoles = common:table_removeFromArray(choseRoles, roleId)
        else
            if #choseRoles >= 3 then
                MessageBoxPage:Msg_Box("@ERRORCODE_33018")
            else
                table.insert(choseRoles, roleId)
                --chose = true
            end
        end
    end
    local baseContainer = GVGTeamJoinPageBase.container
    NodeHelper:setMenuItemEnabled(baseContainer,"mDisChoose", #choseRoles > 0)
    --NodeHelper:setNodesVisible(container,{["mChoose" .. index] = chose})
    baseContainer.mScrollView:refreshAllCell()
end

function GVGIntoItem.init(container, roleStatus, index)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local labelColorMap = {}

    local roleData = {}
    local isPlayer = false
    if roleStatus.roleId == UserInfo.roleInfo.roleId then
        isPlayer = true
        roleData = UserInfo.roleInfo
    else
        local MercenaryInfos = UserMercenaryManager:getUserMercenaryInfos()
        roleData = MercenaryInfos[roleStatus.roleId]
    end
    local roleInfo = roleCfg[roleData.itemId]

    --sprite2Img["mPic"] = roleInfo.icon
    menu2Quality["mHand" .. index] = roleInfo.quality
    if isPlayer then
        lb2Str["mName" .. index] = UserInfo.roleInfo.name
    else
        lb2Str["mName" .. index] = roleInfo.name
    end
    lb2Str["mFighting" .. index] = common:getLanguageString("@GVGEnergy") .. roleStatus.energy
    local enabled = true
    if roleStatus.status ~= GVG_pb.ROLE_STATUS_NORMAL then enabled = false end
    if roleStatus.energy < GVGManager.getNeedEnergy(GVGTeamJoinPageBase.showType) then 
        enabled = false
        labelColorMap["mFighting" .. index] = "255 0 0"
    else
        labelColorMap["mFighting" .. index] = "0 248 80"
    end
    NodeHelper:setMenuItemEnabled(container,"mHand" .. index, enabled)

    local playerSprite = CCSprite:create(roleInfo.icon)
	local playerNode = container:getVarNode("mPic" .. index)
	playerNode:removeAllChildren()
    if not enabled then 
		local graySprite = GraySprite:new()
		local texture = playerSprite:getTexture()
		local size = playerSprite:getContentSize()
		graySprite:initWithTexture(texture,CCRectMake(0,0,size.width,size.height))
		playerNode:addChild(graySprite)
	else
		playerNode:addChild(playerSprite)
    end
    --playerNode:setScale(0.8)

    if roleStatus.status == GVG_pb.ATTACKER_STATUS_DEF then
        visibleMap["mBattle" .. index] = true
        visibleMap["mDefend" .. index] = false
    elseif roleStatus.status == GVG_pb.DEFENDER_STATUS_DEF then
        visibleMap["mBattle" .. index] = false
        visibleMap["mDefend" .. index] = true
    else
        visibleMap["mBattle" .. index] = false
        visibleMap["mDefend" .. index] = false
    end

    --visibleMap["mChoose" .. index] = common:table_hasValue(choseRoles,roleStatus.roleId)
    visibleMap["mTeamInNum" .. index] = false
    visibleMap["mNum" .. index] = false
    lb2Str["mTeamInNum" .. index] = ""
    for i = 1, #choseRoles do
        if choseRoles[i] == roleStatus.roleId then
            visibleMap["mTeamInNum" .. index] = true
            lb2Str["mTeamInNum" .. index] = i
            visibleMap["mNum" .. index] = true
            break   
        end
    end

    NodeHelper:setColorForLabel(container,labelColorMap)
    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGTeamJoinPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGTeamJoinPageBase:onEnter(container)
    self:registerPacket(container)
    GVGManager.setIsOpenJoinPage(true)
    GVGTeamJoinPageBase.container = container
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    roleCfg = ConfigManager.getRoleCfg()
    NodeHelper:initScrollView(container, "mContent", 10);
    --self:clearAndReBuildAllItem(container)
    local cityId = GVGManager.getCurCityId()
    if GVGManager.isOwnCity(cityId) then
        NodeHelper:setStringForLabel(container,{mInfoTex = common:getLanguageString("@GVGMercenaryInfoTxt1")})
        GVGTeamJoinPageBase.showType = GVGManager.SHOWTYPE_DEF
    else
        NodeHelper:setStringForLabel(container,{mInfoTex = common:getLanguageString("@GVGMercenaryInfoTxt")})
        GVGTeamJoinPageBase.showType = GVGManager.SHOWTYPE_ATK
    end
    NodeHelper:setMenuItemEnabled(container,"mDisChoose", #choseRoles > 0)

    self:clearAndReBuildAllItem(container)
end

function GVGTeamJoinPageBase:onExecute(container)

end

function GVGTeamJoinPageBase:onExit(container)
    self:removePacket(container)
    GVGInfoContent.teamList = {}
    GVGTeamJoinPageBase.container = {}
    choseRoles = {}
    GVGManager.setCurCityId(0)
    GVGManager.setIsOpenJoinPage(false)
    roleCfg = {}
end

function GVGTeamJoinPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GVGTeamJoinPageBase:onCancel(container)
    PageManager.popPage(thisPageName)
end

function GVGTeamJoinPageBase:onConfirmation(container)
    if #choseRoles == 0 then
        MessageBoxPage:Msg_Box("@GVGNoManSelected")
        return
    end
    local cityId = GVGManager.getCurCityId()
    if GVGTeamJoinPageBase.showType == GVGManager.SHOWTYPE_ATK then
        GVGManager.joinAtkTeam(cityId, choseRoles)
    elseif GVGTeamJoinPageBase.showType == GVGManager.SHOWTYPE_DEF then
        GVGManager.joinDefTeam(cityId, choseRoles)
    end
end

function GVGTeamJoinPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGTeamJoinPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onReceiveRolesInfo then
                self:clearAndReBuildAllItem(container)
            elseif extraParam == GVGManager.onJoinTeam then
                GVGManager.insertCityTeamList(GVGManager.getCurCityId(), GVGTeamJoinPageBase.showType, choseRoles)            
                choseRoles = {}
                NodeHelper:setMenuItemEnabled(container,"mDisChoose", #choseRoles > 0)
                GVGManager.reqRoleInfo()
            end
        end
	end
end

function GVGTeamJoinPageBase:clearAndReBuildAllItem(container)
    local teamList = GVGManager.getAllRoles()
    table.sort(teamList, function(a,b)
        local MercenaryInfos = UserMercenaryManager:getUserMercenaryInfos()
        local roleDataA = MercenaryInfos[a.roleId]
        local roleDataB = MercenaryInfos[b.roleId]
        local roleInfoA = roleCfg[roleDataA.itemId]
        local roleInfoB = roleCfg[roleDataB.itemId]
        if a.roleId == UserInfo.roleInfo.roleId then
            return true
        elseif b.roleId == UserInfo.roleInfo.roleId then
            return false
        elseif a.status == b.status then
            if a.energy ~= b.energy then
                if a.energy > 0 and b.energy > 0 then
                    if a.fightNum > 0 and b.fightNum > 0 then
                        if a.fightNum == b.fightNum then
                            return roleInfoA.quality > roleInfoB.quality
                        else
                            return a.fightNum > b.fightNum
                        end
                    else
                        if roleDataA.fight == roleDataB.fight then
                            return roleInfoA.quality > roleInfoB.quality
                        else
                            return roleDataA.fight > roleDataB.fight
                        end
                    end
                else
                    return b.energy <= 0
                end
            else
                if a.fightNum > 0 and b.fightNum > 0 then
                    if a.fightNum == b.fightNum then
                        return roleInfoA.quality > roleInfoB.quality
                    else
                        return a.fightNum > b.fightNum
                    end
                else
                    if roleDataA.fight == roleDataB.fight then
                        return roleInfoA.quality > roleInfoB.quality
                    else
                        return roleDataA.fight > roleDataB.fight
                    end
                end
            end
        else
            if a.status == GVG_pb.ROLE_STATUS_NORMAL then
                return true
            elseif b.status == GVG_pb.ROLE_STATUS_NORMAL then
                return false
            else
                return a.status < b.status
            end
        end
    end)
    local rebuildFlag = false
    if #GVGInfoContent.teamList <= 0 then
        rebuildFlag = true
    end
    GVGInfoContent.teamList = teamList
    if #teamList >= 1 then
        if rebuildFlag then
            container.mScrollView:removeAllCell()
            local lines = math.ceil(#teamList / 4)   
            for i = 1, lines do
                local titleCell = CCBFileCell:create()
                local meta = {
                    index = i
                }
                for j = 1, 4 do
                    meta["onHand" .. j] = function(_self,container)
                        GVGIntoItem.onSelect(container,j)
                    end
                end
                local panel = GVGInfoContent:new(meta)
                titleCell:registerFunctionHandler(panel)
                titleCell:setCCBFile(GVGInfoContent.ccbiFile)
                container.mScrollView:addCellBack(titleCell)
            end
            container.mScrollView:orderCCBFileCells()
        else
            container.mScrollView:refreshAllCell()
        end
    end
end

function GVGTeamJoinPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGTeamJoinPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGTeamJoinPage = CommonPage.newSub(GVGTeamJoinPageBase, thisPageName, option);