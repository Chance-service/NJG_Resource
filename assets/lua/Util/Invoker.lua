local Invoker = {}

Invoker.Mode = {
	ALWAYS = 1,
	AUTO = 2,
	PAUSE = 3,
}

Invoker.TaskType = {
	TIMER = 1,
	UPDATE = 2,
}

Invoker.time = 0
Invoker.timeScale = 1

Invoker.mode = Invoker.Mode.AUTO

Invoker.tasks = {}

function Invoker:execute (dt)
	
	if self.mode == Invoker.Mode.PAUSE then
		return 
	elseif self.mode == Invoker.Mode.AUTO then
		if #self.tasks == 0 then return end
	end

	self.time = self.time + (dt * self.timeScale)

	local toCall = {}
	local toRm = {}
	-- print("time : "..tostring(self.time))

	for idx, eachTask in ipairs(self.tasks) do
		-- print("eachTask.time : "..tostring(eachTask.time))
		if self.time >= eachTask.time then
			local isAlive = true

			if isAlive and eachTask.node ~= nil then
				if tolua.isnull(eachTask.node) then
					isAlive = false
				end
			end
		
			if isAlive and eachTask.life ~= -1 then
				eachTask.life = eachTask.life - 1
				if eachTask.life <= 0 then
					isAlive = false
				end
			end

			if isAlive == false then
				toRm[#toRm+1] = eachTask
			end

			toCall[#toCall+1] = eachTask
		end
	end

	for idx, val in ipairs(toRm) do
		self:cancel(val, false)
	end

	for idx, val in ipairs(toCall) do
		if val.isCancel == false then
			if val.type == Invoker.TaskType.UPDATE then
				val.fn(dt)
			else
				val.fn()
			end
		end
	end
	
end

--[[ 單次執行 ]]
function Invoker:once (fn, delay)
	
	local task = self:newTask()
	task.fn = fn
	task.life = 1
	task.time = self.time + delay
	task.type = Invoker.TaskType.TIMER

	self.tasks[#self.tasks + 1] = task
	return task
end

--[[ 每幀執行 ]]
function Invoker:update (fn)
	
	local task = self:newTask()
	task.fn = fn
	task.life = -1
	task.type = Invoker.TaskType.UPDATE

	self.tasks[#self.tasks + 1] = task
	return task
end

--[[ 取消 ]]
-- 可選是否標記已取消, 若被取消者有該標記 則 與取消者時同批execute時 被取消者不會被呼叫
function Invoker:cancel (task, isMarkAsCancel)

	for idx, eachTask in ipairs(self.tasks) do
		if eachTask == task then
			table.remove(self.tasks, idx)
		end
	end

	if isMarkAsCancel ~= false then
		task.isCancel = true
	end
end

function Invoker:cancelByTag (...)
	local tags = {...}
	local matchesReq = #tags
	for idx, eachTask in ipairs(self.tasks) do
		
		local matchesCount = 0
		
		for idxx, eachFind in ipairs(tags) do
			for idxxx, eachTag in ipairs(eachTask.tags) do
				if eachTag == eachFind then
					matchesCount = matchesCount + 1
					break
				end
			end
		end

		if matchesCount == matchesReq then
			self:cancel(eachTask)
		end
	end
end

function Invoker:newTask ()
	local task = {
		fn = function() end,
		type = Invoker.TaskType.TIMER,
		time = self.time,
		life = 1,
		isCancel = false,
		tags = {},
		node = nil,
	}
	function task:tag (...)
		local tags = {...}
		for idx, tag in ipairs(tags) do
			local isExist = false
			for idxx, exist in ipairs(self.tags) do
				if exist == tag then
					isExist = true
					break
				end
			end
			if not isExist then
				self.tags[#self.tags+1] = tag
			end
		end
		return self
	end
	function task:withNode (node)
		self.node = node
		return self
	end
	return task
end

CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function(dt)
	Invoker:execute(dt)
end, 0, false)

return Invoker