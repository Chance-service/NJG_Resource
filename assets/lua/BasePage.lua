

local BasePage = {
                     mRebuildLock = true,
                     mRefreshCout = 0
                }
local CommonPage = require("CommonPage");
local NodeHelper = require("NodeHelper")

----------------------------------------------------------
--类接口
function BasePage:new(option,pageName,func,opcodes)
    local new = CommonPage.newSub(self,pageName, option,func);
    if new==nil then 
        return new 
    end
    
    self.__index = self
    setmetatable(new,self)
    new.super = self
    new.pageName = pageName
    new.mRebuildLock = true
    new.mRefreshCout = 0
    
    if option == nil or option.DataHelper==nil then
        new.DataHelper = nil
    else
		--数据接口
		new.DataHelper = option.DataHelper
	end
    if opcodes~=nil then
        new.opcodes = opcodes
    end    
    return new
end
---------------------------------------------------------
--通用方法
function BasePage:onEnter(container)  
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);

    NodeHelper:initScrollView(container, "mContent", 5);
	if container.mScrollView~=nil then
		container:autoAdjustResizeScrollview(container.mScrollView);
	end
	
	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
    
    self:getPageInfo(container)
end

function BasePage:getPageInfo(container)  
end

function BasePage:onExecute(container)  
	--self:onTimer(container)
end

function BasePage:onTimer(container,timerName,nodeName)
	if not TimeCalculator:getInstance():hasKey(timerName) then
		local remainTime = self.DataHelper:getVariableByKey(timerName)
		if remainTime==nil then 
            if container:getVarNode(nodeName)~=nil then
                NodeHelper:setStringForLabel(container, {[nodeName] = ""});
            end
            return 
        end
		if remainTime > 0 then
			TimeCalculator:getInstance():createTimeCalcultor(timerName, remainTime);
			self.timerName = timerName
		else
            local zero = common:getLanguageString("@ActivityRebateClose")
            if container:getVarNode(nodeName)~=nil then
                NodeHelper:setStringForLabel(container, {[nodeName] = zero});
            end
			return; 
		end
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
    local isShowSecond = false
    --is show second
    if self.DataHelper:getVariableByKey(timerName)<60 then
        isShowSecond = true;
    end
    --show time
	local timeStr = common:second2DateString(remainTime, isShowSecond);
    if container:getVarNode(nodeName)~=nil then
	    NodeHelper:setStringForLabel(container, {[nodeName] = timeStr});
    end
    self.DataHelper:addOrSetVariableByKey(timerName,remainTime) 
    --time out
    if remainTime<=0 then
        TimeCalculator:getInstance():removeTimeCalcultor(timerName);
        self.DataHelper:addOrSetVariableByKey(timerName,0) 
        if container:getVarNode(nodeName)~=nil then
            local zero = common:getLanguageString("@ActivityRebateClose")
            NodeHelper:setStringForLabel(container, {[nodeName] = zero});
        end
    end
    
end

function BasePage:onExit(container)  
    self:removePacket(container)
	NodeHelper:deleteScrollView(container);
    self.mRebuildLock = true

    if self.timerName~=nil then
        if TimeCalculator:getInstance():hasKey(self.timerName) then
		    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);	
        end
	end
    container:removeMessage(MSG_MAINFRAME_REFRESH);
end

function BasePage:refreshPage(container)     
end

function BasePage:rebuildAllItem(container)  
    self:clearAllItem(container);
    self:buildItem(container);
end

function BasePage:buildItem(container)  
end

function BasePage:clearAllItem(container)  
    NodeHelper:clearScrollView(container);
end

function BasePage:toString(container)  
    CCLuaLog("The page's name is:"..self.pageName)
end

------------------------------------------------------------------
--通用按键事件
function BasePage:onClose(container)  
    PageManager.popPage(self.pageName)
end

------------------------------------------------------------------
--消息通用
function BasePage:onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();
	if typeId == MSG_SEVERINFO_UPDATE then
		self:onUpdateServerInfo(container)	
	elseif typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == self.pageName then
			self:onRefreshPage(container);
		end
	end
end

function BasePage:onRefreshPage(container)  
    self:refreshPage(container)
end

function BasePage:onUpdateServerInfo(container)     
end

function BasePage:onPacketError(container)  
    CCLuaLog("Require Packet Time Out!")
end

function BasePage:onPacketError(container)  
    CCLuaLog("Packet Error!Send or Connect Failed1!")
end

function BasePage:onAnimationDone(container)  
end
------------------------------------------------------------------
--协议通用接口
function BasePage:registerPacket(container)
    if self.opcodes == nil then return end
	for key, opcode in pairs(self.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function BasePage:removePacket(container)
    if self.opcodes == nil then return end
	for key, opcode in pairs(self.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function BasePage:onReceivePacket(container)
    if self.DataHelper~=nil then
        self.DataHelper:onReceivePacket(container,self)
    end
end

--------------------------------------------------------------------
--错误处理
function BasePage:ErrorResolve(container)
    CCLuaLog("Lua Page Error:"..self.pageName)
end
--------------------------------------------------------------------
--父类方法回调  也可以self.super.xxx(self,container)方式调用
function CallSuperFunc(container,caller,func)
    caller["super_"..func] = caller.super[func]
	caller["super_"..func](caller,container)
end





return BasePage