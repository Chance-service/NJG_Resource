local ActivityBasePage = {}

function ActivityBasePage:new(option, pageName, opcodes)
    local new = {}
    self.__index = self
    setmetatable(new,self)
    new.super = self
    new.pageName = pageName
    new.option = option
    new.opcodes = opcodes

    return new
end

-----------------------end Content------------

function ActivityBasePage:onEnter(ParentContainer)
    local container = ScriptContentBase:create(self.option.ccbiFile)
    self.container = container
    if self.onFunction then
        self.container:registerFunctionHandler(self.onFunction)
    end
    container.mScrollView = container:getVarScrollView("mContent")

    self:registerPacket(ParentContainer)
    if container.mScrollView~=nil then
        ParentContainer:autoAdjustResizeScrollview(container.mScrollView)
    end
	
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
    if mScale9Sprite ~= nil then
        ParentContainer:autoAdjustResizeScale9Sprite( mScale9Sprite )
    end
    
    self:getPageInfo(container)
    return container
end

function ActivityBasePage:registerPacket(container)
    if self.opcodes == nil then
        return
    end
    for key, opcode in pairs(self.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActivityBasePage:removePacket(container)
    if self.opcodes == nil then
        return
    end
    for key, opcode in pairs(self.opcodes) do
    	if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActivityBasePage:onExecute(ParentContainer)
    self:onTimer(self.container)
end

function ActivityBasePage:onExit(ParentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(self.option.timerName)
    self:removePacket(ParentContainer)
    if self.container.mScrollView then
    	self.container.mScrollView:removeAllCell()
    end
    onUnload(self.pageName, self.container)
end
----------------------------------------------------------------
function ActivityBasePage:onTimer(container)

end

function ActivityBasePage:clearPage(container)

end
----------------click event------------------------	
function ActivityBasePage:onBack()
    --PageManager.changePage("ActivityPage");
end

function ActivityBasePage:onHelp()
    PageManager.showHelp(self.DataHelper:getConfigDataByKey("HELP"))
end
-------------------------------------------------------------------------
return ActivityBasePage
