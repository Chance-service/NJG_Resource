local ALFManager = {}

ALFManager.Mode = {
	ALWAYS = 1,
	AUTO = 2,
	PAUSE = 3,
}

ALFManager.TaskType = {
	TIMER = 1,
	UPDATE = 2,
}

ALFManager.time = 0

ALFManager.mode = ALFManager.Mode.AUTO

ALFManager.tasks = {}

ALFManager.redPointTasks = {}

ALFManager.PER_FRAME_TASK_NUM = 1

function ALFManager:execute (dt)
	
	if self.mode == ALFManager.Mode.PAUSE then
		return 
	elseif self.mode == ALFManager.Mode.AUTO then
		if #self.tasks == 0 and #self.redPointTasks == 0 then return end
	end

	self.time = self.time + dt

	local toCall = {}
	local toRm = {}
	-- print("time : "..tostring(self.time))
    local count = 0

	for idx, eachTask in ipairs(self.tasks) do
		-- print("eachTask.time : "..tostring(eachTask.time))
		if self.time >= eachTask.time then
			local isAlive = true
		
			if isAlive and eachTask.nowChildTask > #eachTask.childTask then
				isAlive = false
			end

			if isAlive == false then
				toRm[#toRm + 1] = eachTask
            else
                toCall[#toCall + 1] = eachTask
                count = count + 1
                if count >= ALFManager.PER_FRAME_TASK_NUM then
                    break   -- 控制每偵執行的任務數量
                end
			end
		end
	end

    for idx, eachTask in ipairs(self.redPointTasks) do
		--CCLuaLog("redPointTasks Num : " .. #self.redPointTasks)
		if self.time >= eachTask.time then
			local isAlive = true
		
			if isAlive and eachTask.nowChildTask > #eachTask.childTask then
				isAlive = false
			end

			if isAlive == false then
				toRm[#toRm + 1] = eachTask
            else
                toCall[#toCall + 1] = eachTask
                count = count + 1
                if count >= ALFManager.PER_FRAME_TASK_NUM then
                    break   -- 控制每偵執行的任務數量
                end
			end
		end
	end

	for idx, val in ipairs(toRm) do
        if val.endTaskFn then
            local time1 = os.clock()
            val.endTaskFn(val.data)
            local time2 = os.clock()
            if (time2 - time1) > (1 / 60) then
                CCLuaLog(">>>>>ALFManager Fn Cost Time : " .. (time2 - time1))
            end
        end
		self:cancel(val)
        --return
	end

	for idx, val in ipairs(toCall) do
        local time1 = os.clock()
		if val.childTask[val.nowChildTask] then
			val.childTask[val.nowChildTask](val)
		end
        local time2 = os.clock()
        if (time2 - time1) > (1 / 60) then
            CCLuaLog(">>>>>ALFManager Cost Time : " .. (time2 - time1))
        end
	end
	
end

--[[ 新增 紅點 任務 ]]
function ALFManager:loadRedPointTask (fn, tag)
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then -- windows環境不刷新紅點 避免卡頓
        return
    end
    for idx, eachTask in ipairs(self.redPointTasks) do
        if eachTask.tag == tag then
            --CCLuaLog("Duplicate RedPoint Task----")
            return
        end
    end
	local task = self:newTask()
    task.endTaskFn = callback
    task.tag = tag
    table.insert(task.childTask, function(task)
        fn()
        task.nowChildTask = task.nowChildTask + 1
    end)

	self.redPointTasks[#self.redPointTasks + 1] = task
	return task
end

--[[ 新增 任務 ]]
function ALFManager:loadNormalTask (fn, callback)
	local task = self:newTask()
    task.endTaskFn = callback

    table.insert(task.childTask, function(task)
        fn()
        task.nowChildTask = task.nowChildTask + 1
    end)

	self.tasks[#self.tasks + 1] = task
	return task
end

--[[ 新增 載入ccb 任務 ]]
function ALFManager:loadCcbTask (parent, fileName, _type, callback)
	local task = self:newTask()
    task.endTaskFn = callback

    table.insert(task.childTask, function(task)
        local addAniCCB = ScriptContentBase:create(fileName)
        task.data = { ccb = addAniCCB, type = _type, parent = parent }
        task.nowChildTask = task.nowChildTask + 1
    end)

	self.tasks[#self.tasks + 1] = task
	return task
end

--[[ 新增 載入spine 任務 ]]
function ALFManager:loadSpineTask (filePath, fileName, textureNum, callback)
	local task = self:newTask()
    task.endTaskFn = callback

    for i = 1, textureNum do
        table.insert(task.childTask, function(task)
            local addStr = task.nowChildTask > 1 and (task.nowChildTask .. ".png") or ".png"
            CCLuaLog(">>>>>ALFManager Load Tex : " .. filePath .. fileName .. addStr)
            local tex = CCTextureCache:sharedTextureCache():addImage(filePath .. fileName .. addStr)
            if tex then
                task.nowChildTask = task.nowChildTask + 1
                tex:retain()
            else
                task.nowChildTask = 999
            end
            CCLuaLog(">>>>>ALFManager Load nowChildTask : " .. task.nowChildTask)
        end)
    end

	self.tasks[#self.tasks + 1] = task
	return task
end
function ALFManager:loadJpgSpineTask (filePath, fileName, textureNum, callback)
    local task = self:newTask()
    task.endTaskFn = callback

    for i = 1, textureNum do
        table.insert(task.childTask, function(task)
            local addStr = task.nowChildTask > 1 and (task.nowChildTask .. ".jpg") or ".jpg"
            CCLuaLog(">>>>>ALFManager Load Tex : " .. fileName .. addStr)
            local tex = CCTextureCache:sharedTextureCache():addImage(filePath .. fileName .. addStr)
            if tex then
                task.nowChildTask = task.nowChildTask + 1
                tex:retain()
            else
                task.nowChildTask = 999
            end
        end)
    end

    self.tasks[#self.tasks + 1] = task
	return task
end

--[[ 取消 ]]
-- 可選是否標記已取消, 若被取消者有該標記 則 與取消者時同批execute時 被取消者不會被呼叫
function ALFManager:cancel (task)

	for idx, eachTask in ipairs(self.tasks) do
		if eachTask == task then
			table.remove(self.tasks, idx)
		end
	end
    for idx, eachTask in ipairs(self.redPointTasks) do
		if eachTask == task then
			table.remove(self.redPointTasks, idx)
		end
	end
end

function ALFManager:newTask ()
	local task = {
		time = self.time,
        childTask = { },
        nowChildTask = 1,
        endTaskFn = function() end,
	}
	return task
end

CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function(dt)
	ALFManager:execute(dt)
end, 0, false)

return ALFManager