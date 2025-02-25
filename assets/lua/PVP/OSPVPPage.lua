local thisPageName = "OSPVPPage"
local OSPVPManager = require("OSPVPManager")
local CsBattle_pb = require("CsBattle_pb")
local HP_pb = require("HP_pb")
local UserMercenaryManager = require("UserMercenaryManager")

local OSPVPPageBase = {
    curPageIndex = -1
}
 
local option = {
    ccbiFile = "PVPPage.ccbi",
    handlerMap = {
        onReturnBtn = "onClose",
        onAgencyBtn = "onAgencyBtn",
        onDailyBtn = "onDailyBtn",
        onAchievementBtn = "onAchievementBtn",
        onShopBtn = "onShopBtn",
        onHelp = "onHelp"
    },
    opcodes = {
        SHOP_ITEM_S = HP_pb.SHOP_ITEM_S,
        SHOP_BUY_S = HP_pb.SHOP_BUY_S
    }
}

local SubPage = {
    [1] = "OSPVPVsPage",
    [2] = "OSPVPLogPage",
    [3] = "OSPVPRankPage",
    [4] = "OSPVPShopPage",
}

function OSPVPPageBase:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local selectedMap = {}

    selectedMap.mAgencyBtn = OSPVPPageBase.curPageIndex == 1
    selectedMap.mDailyBtn = OSPVPPageBase.curPageIndex == 2
    selectedMap.mAchievementBtn = OSPVPPageBase.curPageIndex == 3
    selectedMap.mShopBtn = OSPVPPageBase.curPageIndex == 4

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setMenuItemSelected(container,selectedMap)
end

function OSPVPPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function OSPVPPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    if OSPVPManager:getSystemStatus() ~= CsBattle_pb.DATA_MAINTAIN and #OSPVPManager:getCurVsList() > 0 then
        NodeHelper:setMenuItemEnabled(container,"mAgencyBtn", true)
        NodeHelper:setMenuItemEnabled(container,"mDailyBtn", true)
        NodeHelper:setColorForLabel(container,{
            mPVPBtn1 = "254 255 255",
            mPVPBtn2 = "254 255 255"
        })
        if OSPVPPageBase.curPageIndex == -1 then
            self:initSubPage(container,1)
        end
    else
        NodeHelper:setMenuItemEnabled(container,"mAgencyBtn", false)
        NodeHelper:setMenuItemEnabled(container,"mDailyBtn", false)
        NodeHelper:setColorForLabel(container,{
            mPVPBtn1 = "144 144 144",
            mPVPBtn2 = "144 144 144"
        })
        if OSPVPPageBase.curPageIndex == -1 then
            self:initSubPage(container,3)
        end
    end
    --self:clearAndReBuildAllItem(container)
    --self:refreshPage(container)
end

function OSPVPPageBase:onExecute(container)
    if self.subPage then
        self.subPage:onExecute(self.subPage.container)
    end
end

function OSPVPPageBase:onExit(container)
    if self.subPage then
        self.subPage:onExit(self.subPage.container)
    end
    local content = container:getVarNode("mContentNode")
    content:removeAllChildren()
    self:removePacket(container)
    OSPVPPageBase.curPageIndex = -1
    OSPVPManager.clearTempData()
    debugPage[thisPageName] = true
    onUnload(thisPageName,container)
end

function OSPVPPageBase:initSubPage(container,index)
    if index == OSPVPPageBase.curPageIndex then 
        self:refreshPage(container)
        return 
    end
    OSPVPPageBase.curPageIndex = index
    self:refreshPage(container)
    if self.subPage then
        self.subPage:onExit(self.subPage.container)
    end

    local content = container:getVarNode("mContentNode")
    content:removeAllChildren()

    local _subPage = require(SubPage[index])
    local subPage = _subPage:create(content,container)
    self.subPage = subPage
end

function OSPVPPageBase:onAgencyBtn(container)
    self:initSubPage(container, 1) 
end

function OSPVPPageBase:onDailyBtn(container)
    self:initSubPage(container, 2)
end

function OSPVPPageBase:onAchievementBtn(container)
    self:initSubPage(container, 3)
end

function OSPVPPageBase:onShopBtn(container)
    self:initSubPage(container, 4)
end

function OSPVPPageBase:onHelp(container)
    local ConfigManager = require("ConfigManager")
    local serverCfg = ConfigManager.getOSPVPServerCfg()
    local selfGroup
    for k,v in pairs(serverCfg) do
        if common:table_hasValue(v.servers, UserInfo.serverId) then
            selfGroup = common:deepCopy(v.servers)
            break
        end
    end
    local str = ""
    if not selfGroup then
        str = common:getLanguageString("@OSPVPNoServerGroup")
    else
        common:table_map(selfGroup, function(v)
            local serverName = GamePrecedure:getInstance():getServerNameById(v);
            return common:getLanguageString("@PVPServerName",serverName)
        end)
        str = table.concat(selfGroup)
    end
    local HelpConfg = ConfigManager.getHelpCfg(GameConfig.HelpKey.HELP_CROSSPVP)
    local content = common:fill(HelpConfg[1].content,str)
    PageManager.showHelp("",nil,false,content)
end

function OSPVPPageBase:onClose(container)
    PageManager.changePage("PVPActivityPage")
end

function OSPVPPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if self.subPage then
        if self.subPage.onReceivePacket then
            self.subPage:onReceivePacket(opcode,msgBuff)
        end
    end
end

function OSPVPPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then        
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onSystemStatus then
                if OSPVPManager:getSystemStatus() ~= CsBattle_pb.DATA_MAINTAIN and #OSPVPManager:getCurVsList() > 0 then
                    NodeHelper:setMenuItemEnabled(container,"mAgencyBtn", true)
                    NodeHelper:setMenuItemEnabled(container,"mDailyBtn", true)
                    if OSPVPPageBase.curPageIndex == -1 then
                        self:initSubPage(container,1)
                    end
                else
                    NodeHelper:setMenuItemEnabled(container,"mAgencyBtn", false)
                    NodeHelper:setMenuItemEnabled(container,"mDailyBtn", false)
                    if OSPVPPageBase.curPageIndex < 3 then
                        self:initSubPage(container,3)
                    end
                end
            end
        end
	end

    if self.subPage then
        self.subPage:onReceiveMessage(message)
    end
end

function OSPVPPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local list = {}
    if #list >= 1 then
        for i,v in ipairs(list) do
            local titleCell = CCBFileCell:create()
            local panel = OSPVPContent:new({id = v.id, index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(OSPVPContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
end

function OSPVPPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function OSPVPPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local OSPVPPage = CommonPage.newSub(OSPVPPageBase, thisPageName, option);