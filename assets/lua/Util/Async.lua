local Async = {}

--[[ 依序執行 ]]
function Async:waterfall (tasks, final)

	local _tasks = {}
	for idx = 1, #tasks do
		_tasks[#_tasks+1] = tasks[idx]
	end
	
	local doNext
	doNext = function (curIdx, ...)
		local nextIdx = curIdx+1;
		if (nextIdx <= #_tasks) then
			local nextTask = _tasks[curIdx+1]
			nextTask(function(...)
				doNext(nextIdx, ...)
			end, ...)
		else
			if (final ~= nil) then final() end
		end
	end

	doNext(0)
end

function Async:waterfall_test ()
	Async:waterfall({
		function (nxt) print(1) nxt() end,
		function (nxt) print(2) nxt() end,
		function (nxt) print(3) nxt() end
	}, function ()
		print("final")
	end)
end
-- Async.waterfall_test()


--[[ 平行每個 ]]
function Async:parallel (tasks, final)

	-- 總數
	local count = #tasks
	
	-- 剩餘倒數
	local left_count = count
	-- 狀態 0:繼續 1:跳過 2:停止
	local state = 0
	
	-- 每當執行完畢
	local each_done = function ()
		-- 若已經結束 則 返回
		if state == 2 then return end
		
		-- 倒數
		left_count = left_count - 1
		
		-- 若 狀態 跳過 或 倒數完畢
		if state == 1 or left_count <= 0 then
			-- 標記 狀態 已結束
			state = 2
			-- 執行最後任務
			if final ~= nil then
				final()
			end
		end
	end
	
	-- 每個任務
	for idx = 1, count do
		
		-- 任務
		local task = tasks[idx]
		
		-- 是否已呼叫下一個任務
		local is_next_called = false
		
		-- 控制器
		local ctrlr = {}

		-- 跳過
		function ctrlr:skip ()
			state = 1
			ctrlr:next()
		end

		-- 停止
		function ctrlr:stop ()
			state = 2
			ctrlr:next()
		end

		-- 下一個
		function ctrlr:next ()
			-- 防止重複呼叫
			if is_next_called then return end
			is_next_called = true
			
			each_done()
		end
			
		-- 執行 並 傳入 呼叫下一任務的func
		task(ctrlr)
	end
end


--[[ 每個 ]]
-- 依序執行、逐個等候，直到執行次數達到全部成員數
function Async:eachSeries (elements, eachFunc, onDone)
	local _onDone = function (res)
		if (onDone ~= nil) then onDone(res) end
	end

	if #elements == 0 then
		_onDone()
		return
	end

	local nextTask = nil;
	nextTask = function (idx)

		-- 該序號的執行內容
		local element = elements[idx]

		-- 下一個序號
		local nextIdx = idx+1

		-- 是否已經結束
		local isEnd = (nextIdx > #elements)

		-- 是否已經呼叫
		local isCalled = false

		-- 加入next
		local toNext = function()
			-- 若 已經呼叫過 則 忽略
			if (isCalled) then return end
			isCalled = true

			-- 若 還沒結束 則 執行下一個序號
			if (not isEnd) then
				nextTask(nextIdx)
			-- 否則 呼叫 結束 並 返回
			else
				_onDone()
			end
		end;

		-- 執行內容
		eachFunc(idx, element, toNext)
	end

	nextTask(1)
end

--[[ 被動非同步完成 ]]
function Async:passtive (taskTags, onDone)

	local inst = {}
	
	local leftTag2Count = {}

	function inst:done ()
		leftTag2Count = nil
		onDone()
	end

	function inst:next (tag)
		if leftTag2Count == nil then return end

		local exist = leftTag2Count[tag]
		if exist ~= nil then
			exist = exist - 1
			if exist <= 0 then
				leftTag2Count[tag] = nil
			end
		end
		
		local isleft = false
		for key, val in pairs(leftTag2Count) do
			isleft = true
			break
		end

		if not isleft then
			self:done()
		end
	end
		
	for idx, val in ipairs(taskTags) do
		local exist = leftTag2Count[val]
		if exist == nil then
			exist = 0
		end
		exist = exist + 1
		leftTag2Count[val] = exist
	end

	return inst
end

return Async