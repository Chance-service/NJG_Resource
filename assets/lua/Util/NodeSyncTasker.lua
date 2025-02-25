
local NodeSyncTasker = {}

function NodeSyncTasker:new () 
        
    local inst = {}

    inst.tasks = {}

    inst.syncFn = function() end

    --[[ 設置 同步內容 ]]
    function inst:setSyncFn (syncFn)
        self.syncFn = syncFn
    end

    --[[ 更新 ]]
    function inst:update ()
        for idx, val in ipairs(self.tasks) do
            if val.active then
                self.syncFn(val)
            end
        end
    end

    --[[ 新增 任務 ]]
    function inst:add (src, dst, tags)
        local newTask = {
            src = src,
            dst = dst,
            tags = tags,
            active = true,
        }

        return self:addTask(newTask)
    end

    function inst:addTask (task)
        if task.active == nil then task.active = true end
        self.tasks[#self.tasks+1] = task
        return task
    end

    --[[ 設置 啟用/關閉 ]]
    function inst:setActive (isActive, tags)
        if isActive == nil then isActive = true end
        
        local matches = self:getTasks(tags)
        
        for idx, val in ipairs(matches) do
            val.active = isActive
        end
    end

    --[[ 移除 任務 ]]
    function inst:removeByTags (tags)
        local matches = self:getTasks(tags)

        local val2Idx = {}
        for matchIdx, matchTask in ipairs(matches) do
            for idxInTask, task in ipairs(self.tasks) do
                if task == matchTask then
                    table.remove(self.tasks, idxInTask)
                    break
                end
            end
        end
        
    end

    function inst:getTasks (tags)
        if tags == nil or #tags == 0 then
            return self.tasks
        end

        local matchesReq = #tags
        
        local tasks = {}

        -- dump(tags,"find tags")
        -- print("IN")
        -- dump(self.tasks, "self.tasks")
        for idx, val in ipairs(self.tasks) do

            local tagMatches = 0
            -- 每一個任務的標籤列表
            -- dump(val.tags,"task tags:")
            for idx, eachTag in ipairs(val.tags) do
                -- 每一個要找的標籤
                for idxx, eachFind in ipairs(tags) do
                    -- 若 符合 則 增加符合數
                    if eachTag == eachFind then
                        tagMatches = tagMatches + 1
                        break
                    end
                end
            end

            -- print(string.format("%s == %s ? %s", tostring(tagMatches), tostring(matchesReq), tostring(tagMatches == matchesReq)))
            if tagMatches == matchesReq then
                tasks[#tasks+1] = val
            end
        end

        -- dump(tasks, "matches")
        return tasks
    end

    return inst

end

return NodeSyncTasker