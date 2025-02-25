local GVGManager = require("GVGManager")
local thisPageName = "GVGLoadingPage"

local GVGLoadingPageBase = {}
 
local option = {
    ccbiFile = "GVGBattleLoading.ccbi",
    handlerMap = {
        
    },
    opcodes = {
        
    }
}

local loadingSteps = {
    [1] = {
        event = GVGManager.onGuildData,
        doFunc = GVGManager.reqGuildInfo,
        autoNext = false,
    },
    [2] = {
        event = GVGManager.onMapInfo,
        doFunc = GVGManager.reqMapInfo,
        autoNext = true,
    },
    [3] = {
        event = GVGManager.onTeamNumChange,
        doFunc = GVGManager.reqSyncTeamNum,
        autoNext = false,
    },
    [4] = {
        event = GVGManager.onYesterdayRank,
        doFunc = GVGManager.reqYesterdayVitalityRank,
        autoNext = false,
    },
}

local curStep = 0

local oneStepWaitTime = 5

local oneStepStartTime = 0

function GVGLoadingPageBase:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local progress = container:getVarSprite("mGVGBattleLoading")

    progress:setScaleX(curStep / #loadingSteps)

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGLoadingPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGLoadingPageBase:onEnter(container)
    curStep = 0
    self:refreshPage(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
end

function GVGLoadingPageBase:onExecute(container)
    local curTime = os.time()
    if curTime - oneStepStartTime >= oneStepWaitTime then
        local nextStep = loadingSteps[curStep + 1]
        if nextStep then
            if nextStep.doFunc and type(nextStep.doFunc) == "function" then
                oneStepStartTime = os.time()
                nextStep.doFunc()
            end
        end
    end
end

function GVGLoadingPageBase:onExit(container)
    self:removePacket(container)
    debugPage[thisPageName] = true
    onUnload(thisPageName,container)
end

function GVGLoadingPageBase:onAnimationDone(container)
    local animationName=tostring(container:getCurAnimationDoneName())
	if animationName == "Born" then
        container:runAnimation("Loop")
        self:refreshPage(container)
    elseif animationName == "Loop" then    
        if curStep == #loadingSteps then
            --PageManager.changePage("GVGMapPage")
            PageManager.pushPage("CommonBlackPopUp")
        end
	end
end

function GVGLoadingPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGLoadingPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            for i,v in ipairs(loadingSteps) do
                if extraParam == v.event and curStep < i then
                    curStep = i
                    self:refreshPage(container)
                    if not v.autoNext then
                        local nextStep = loadingSteps[i + 1]
                        if nextStep then
                            if nextStep.doFunc and type(nextStep.doFunc) == "function" then
                                oneStepStartTime = os.time()
                                nextStep.doFunc()
                            end
                        end
                    else
                        oneStepStartTime = os.time()
                    end
                end
            end 
        end
	end
end

function GVGLoadingPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGLoadingPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGLoadingPage = CommonPage.newSub(GVGLoadingPageBase, thisPageName, option);