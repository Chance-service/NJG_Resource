local thisPageName = "LeaderAvatarPage"
local OSPVPManager = require("OSPVPManager")
local CsBattle_pb = require("CsBattle_pb")
local HP_pb = require("HP_pb")
local LeaderAvatarManager = require("LeaderAvatarManager")
local ConfigManager = require("ConfigManager")
local UserInfo = require("PlayerInfo.UserInfo")

local avatarCfg = {}

local selectedIndex = -1

local clickIndex = 1

local runOver = 0

local LeaderAvatarPageBase = {
    
}
 
local option = {
    ccbiFile = "FashionPage.ccbi",
    handlerMap = {
        onReturnBtn = "onClose",
        --onSkill = "onSkill",
        onHelp = "onHelp",
        onRoleChange = "onRoleChange",
        onRoleAtt = "onRoleAtt"
    },
    opcodes = {
        
    }
}

function LeaderAvatarPageBase:initPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local selectedMap = {}
    
    for i,v in ipairs(avatarCfg) do
        local node = container:getVarNode("mContent_" .. i)
        node:setVisible(true)
        local head = ScriptContentBase:create("FashionContent.ccbi")
        head:setTag(10086)
        head:registerFunctionHandler(function(evt, _container)
            if evt == "onContentBtn" then
                self:onContentBtn(container,i)
            elseif evt == "luaOnAnimationDone" then
                local name = tostring(_container:getCurAnimationDoneName())
                if name == "open" then
                    _container:runAnimation("choice")
                    self:refreshPage(container)
                elseif name == "close" then
                end
            end
        end)
        head.index = i
        node:addChild(head)

        local avatarInfo = LeaderAvatarManager.getAvatarInfo(v.id)
        if avatarInfo and avatarInfo.id == LeaderAvatarManager:getNowAvatarId() then
            clickIndex = i
        end
    end

    visibleMap.mMercenarySkill = false
    visibleMap.mRoleInfoNode = true
    visibleMap.mMercenaryName = false
    visibleMap.mRoleAttNode = false

    container:runAnimation("open")

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setMenuItemSelected(container,selectedMap)
end

function LeaderAvatarPageBase:refreshPage(container)
    local nowCfg
    for i,v in ipairs(avatarCfg) do
        local node = container:getVarNode("mContent_" .. i)
        node:setVisible(true)
        local head = node:getChildByTag(10086)

        local sprite2Img = {}
        local scaleMap = {}
        local menu2Quality = {}
        local lb2Str = {}
        local visibleMap = {}
        local selectedMap = {}

        local avatarInfo = LeaderAvatarManager.getAvatarInfo(v.id)
        if v.id == 0 then
            visibleMap.mName = false
            sprite2Img.mRole = string.format("FashionRole_BG_%d_%d.png",v.id,UserInfo.roleInfo.prof)
            for k = 1, 4 do
                visibleMap["mQualityPic" .. i] = false
            end
            visibleMap.mQualityPicRole = true
            visibleMap.mQualityPicRoleNew = false

            visibleMap.mIconNode = false
            visibleMap.mTimeNode = false
        else
            local bgSprite = head:getVarSprite("mRole")
            visibleMap.mName = true
            sprite2Img.mName = string.format("FashionRole_Font_%d_%d.png",v.id,UserInfo.roleInfo.prof)
            bgSprite:setTexture(string.format("FashionRole_BG_%d_%d.png",v.id,UserInfo.roleInfo.prof))
            for k = 1, 4 do
                visibleMap["mQualityPic" .. i] = false
            end
            visibleMap.mQualityPicRole = false
            visibleMap.mQualityPicRoleNew = true
            visibleMap.mIconNode = false
            visibleMap.mTimeNode = true

            if not avatarInfo then
                bgSprite:removeAllChildren()

                local graySprite = GraySprite:new()
		        local texture = bgSprite:getTexture()
		        local rect = bgSprite:getTextureRect()
		        graySprite:initWithTexture(texture,rect)
                graySprite:setAnchorPoint(ccp(0,0))
		        bgSprite:addChild(graySprite)
                lb2Str.mTimeNum = common:getLanguageString("@LAUnGot")
            else
                local str = ""
                if avatarInfo.endTime == -1 then
                    str = common:getLanguageString("@LAForever")
                else
                    str = common:secondToDateXXYY(avatarInfo.endTime)
                    if avatarInfo.endTime > 0 then
                        TimeCalculator:getInstance():createTimeCalcultor("LeaderAvatarTime" .. v.id, avatarInfo.endTime);
                    end
                end
                lb2Str.mTimeNum = common:getLanguageString("@FashionRoleUseTime", str)
                visibleMap.mPoint = (avatarInfo.checked == false)
            end
        end
        if i == selectedIndex then
            self:showRoleSpine(container, v.id)
            nowCfg = v

            if avatarInfo and avatarInfo.checked == false then
                LeaderAvatarManager.reqCheckAvatar(avatarInfo.id)
            end
        end
        

        NodeHelper:setNodesVisible(head,visibleMap)
        NodeHelper:setStringForLabel(head,lb2Str)
        NodeHelper:setSpriteImage(head,sprite2Img,scaleMap)
        NodeHelper:setQualityFrames(head, menu2Quality)
        NodeHelper:setMenuItemSelected(head,selectedMap)
    end
    
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local selectedMap = {}

    lb2Str.mRoleInfo = nowCfg.desc
    local nowAvatarInfo = LeaderAvatarManager:getNowAvatarItemInfo()
    local avatarInfo = LeaderAvatarManager.getAvatarInfo(nowCfg.id)
    --NodeHelper:setMenuItemEnabled(container,"mRoleChangeBtn", )
    visibleMap.mRoleChangeNode = nowAvatarInfo.avatarId ~= nowCfg.id and avatarInfo ~= nil
    visibleMap.mRoleAttNode = nowCfg.id > 0
    visibleMap.mNoFashionNode = nowCfg.id > 0
    lb2Str.mEquipName = common:getLanguageString(string.format("@EquipName_%d", UserInfo.roleInfo.prof))

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setMenuItemSelected(container,selectedMap)
end

function LeaderAvatarPageBase:onContentBtn(container, index, init)
    if index == selectedIndex then return end
    selectedIndex = index

    for i,v in ipairs(avatarCfg) do
        local node = container:getVarNode("mContent_" .. i)
        node:setVisible(true)
        local head = node:getChildByTag(10086)
        if i == index then
            if init then
                head:runAnimation("choice")
            else
                head:runAnimation("open")
            end
        else
            if init then
                head:runAnimation("Default Timeline")
            else
                head:runAnimation("close")
            end
        end
    end
    if init then
        self:refreshPage(container)
    end
end

function LeaderAvatarPageBase:showRoleSpine(container, avatarId)
	local heroNode = container:getVarNode("mSpineNode")
    local heroNodeBack = container:getVarNode("mGreyNode")
    local avatarInfo = LeaderAvatarManager.getAvatarInfo(avatarId)
	if heroNode then
		local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
		local width,height =  visibleSize.width ,visibleSize.height
		local rate = visibleSize.height/visibleSize.width
		local desighRate = 960/640
		rate = rate / desighRate
		local spine = nil
        local avatarCfg = GameConfig.LeaderAvatarInfo[avatarId]
        local spineCfg = avatarCfg.spine[UserInfo.roleInfo.prof]
		spine = SpineContainer:create(unpack(spineCfg))
		local spineNode = tolua.cast(spine, "CCNode")
        heroNode:setScale(rate)
        heroNode:removeAllChildren()
        heroNodeBack:removeAllChildren()
        if not avatarInfo then
            NodeHelper:initGraySpineSprite(heroNodeBack,spine,heroNode)
        else
		    heroNode:addChild(spineNode)
		    spine:runAnimation(1, "Stand", -1)
            --MercenaryTouchSoundManager:initTouchButton(container, roleId)
        end
		local deviceHeight = CCDirector:sharedDirector():getWinSize().height
		if deviceHeight < 900 then --ipad change spine position
			NodeHelper:autoAdjustResetNodePosition(spineNode,-0.3)	
	    end
	end	
end

function LeaderAvatarPageBase:onLoad(container)
    local _tempCfg = common:deepCopy(ConfigManager.getLeaderAvatarCfg())
    local default = {
        id = 0,maxDay = -1,name = "",desc = "",token = 0,quality = 5,prop1 = "",prop2 = "",prop3 = "",prop4 = "",prop5 = "",prop6 = "",
    }
    avatarCfg = {}
    table.insert(avatarCfg, default)
    for i,v in ipairs(_tempCfg) do
        table.insert(avatarCfg, v)
    end
    table.sort(avatarCfg, function(a,b)
        return a.id < b.id
    end)
    container:loadCcbiFile(option.ccbiFile)
end

function LeaderAvatarPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    --self:clearAndReBuildAllItem(container)
    self:initPage(container)
    self:onContentBtn(container, clickIndex, true)
end

function LeaderAvatarPageBase:onExecute(container)
    if avatarCfg and  #avatarCfg > 0 then
        for i,v in ipairs(avatarCfg) do
            local node = container:getVarNode("mContent_" .. i)
            node:setVisible(true)
            local head = node:getChildByTag(10086)

            local sprite2Img = {}
            local scaleMap = {}
            local menu2Quality = {}
            local lb2Str = {}
            local visibleMap = {}
            local selectedMap = {}

            local avatarInfo = LeaderAvatarManager.getAvatarInfo(v.id)
            if v.id == 0 then

            else
                if not avatarInfo then

                else
                    local str = ""
                    if avatarInfo.endTime == -1 then
                        str = common:getLanguageString("@LAForever")
                    else
                        local leftSec = 0
                        if TimeCalculator:getInstance():hasKey("LeaderAvatarTime" .. v.id) then
                            leftSec = TimeCalculator:getInstance():getTimeLeft("LeaderAvatarTime" .. v.id)
                        else
                            leftSec = avatarInfo.endTime
                        end
                        str = common:secondToDateXXYY(leftSec)
                    end
                    lb2Str.mTimeNum = common:getLanguageString("@FashionRoleUseTime", str)
                end
            end
            NodeHelper:setNodesVisible(head,visibleMap)
            NodeHelper:setStringForLabel(head,lb2Str)
            NodeHelper:setSpriteImage(head,sprite2Img,scaleMap)
            NodeHelper:setQualityFrames(head, menu2Quality)
            NodeHelper:setMenuItemSelected(head,selectedMap)
        end
    end
end

function LeaderAvatarPageBase:onAnimationDone(container)
    local name = tostring(container:getCurAnimationDoneName())
    if name == "close" then
        PageManager.changePage("EquipmentPage")
    elseif name == "open" then
    end
end

function LeaderAvatarPageBase:onExit(container)
    self:removePacket(container)
    clickIndex = 1
    selectedIndex = -1
    for i,v in ipairs(avatarCfg) do
        local avatarInfo = LeaderAvatarManager.getAvatarInfo(v.id)
        if TimeCalculator:getInstance():hasKey("LeaderAvatarTime" .. v.id) then
            TimeCalculator:getInstance():removeTimeCalcultor("LeaderAvatarTime" .. v.id)
        end
    end
    LeaderAvatarManager:clearTempData()
    debugPage[thisPageName] = true
    onUnload(thisPageName,container)
end

function LeaderAvatarPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_AVATAR2)
end

function LeaderAvatarPageBase:onRoleChange(container)
    local nowCfg = avatarCfg[selectedIndex]
    local avatarInfo = LeaderAvatarManager.getAvatarInfo(nowCfg.id)
    LeaderAvatarManager.reqChangeAvatar(avatarInfo.id)
end

function LeaderAvatarPageBase:onRoleAtt(container)
    local nowCfg = avatarCfg[selectedIndex]
    LeaderAvatarManager:setNowStaticId(nowCfg.id)
    PageManager.pushPage("LeaderAvatarAttrPage")
end

function LeaderAvatarPageBase:onClose(container)
    container:runAnimation("close")
end

function LeaderAvatarPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    
end

function LeaderAvatarPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then        
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == LeaderAvatarManager.moduleName then
            if extraParam == LeaderAvatarManager.onAvatarCheck then
                self:refreshPage(container)
            elseif extraParam == LeaderAvatarManager.onAvatarChange then
                self:refreshPage(container)
            end
        end
	end
end

function LeaderAvatarPageBase:clearAndReBuildAllItem(container)
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

function LeaderAvatarPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function LeaderAvatarPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local LeaderAvatarPage = CommonPage.newSub(LeaderAvatarPageBase, thisPageName, option);