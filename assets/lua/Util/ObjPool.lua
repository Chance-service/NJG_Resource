local ObjPool = {}

function ObjPool:new ()
    local inst = {}

    inst.pool = nil
    inst.used = nil
    inst.count = nil

    inst.onCreate = nil
    inst.onInit = nil
    inst.onUnInit = nil
    inst.onDestroy = nil

    function inst:init (options)
        inst.pool = {}
        inst.used = {}

        inst.count = options.count
        if inst.count == nil then inst.count = 1 end

        inst.onCreate = options.onCreate
        if inst.onCreate == nil then inst.onCreate = function (data) return {} end end

        inst.onInit = options.onInit
        if inst.onInit == nil then inst.onInit = function (obj, data) end end
        
        inst.onUnInit = options.onUnInit
        if inst.onUnInit == nil then inst.onUnInit = function (obj) end end
        
        inst.onDestroy = options.onDestroy
        if inst.onDestroy == nil then inst.onDestroy = function (obj) end end

        self:resize(self.count)
        return self
    end

    function inst:resize (count)
        if count ~= nil then 
            self.count = count
        end

        local existCount = #self.pool

        for idx = existCount, 1, -1 do
            if idx <= self.count then break end
            local each = self.pool[idx]
            self.onDestroy(each)
        end
        
        for idx = existCount+1, self.count do
            local newOne = self.onCreate()
            self.pool[idx] = newOne
        end
    end

    function inst:recoveryAll ()
        for idx = #self.used, 1, -1 do
            self:_recovery(idx)
        end
    end

    function inst:recovery (toRec)
        local foundIdx = -1
        for idx, val in ipairs(self.used) do
            if val == toRec then
                foundIdx = idx
                break
            end
        end
        if foundIdx == -1 then return end
        self:_recovery(foundIdx)
    end

    function inst:_recovery (idxInUsed)
        local toRec = self.used[idxInUsed]

        table.remove(self.used, idxInUsed)
        
        local isNeedDestroy = false

        if #self.pool >= inst.count then
            isNeedDestroy = true
        else
            table.insert(self.pool, toRec)
        end

        self.onUnInit(toRec)

        if isNeedDestroy then
            self.onDestroy(toRec)
        end
    end

    function inst:reuse (data)
        local usedOne = nil
        local poolCount = #self.pool
        if poolCount == 0 then
            usedOne = self.onCreate(data)
        else
            usedOne = table.remove(self.pool, poolCount)
        end
        self.onInit(usedOne, data)
        table.insert(self.used, usedOne)
        return usedOne
    end

    function inst:clear ()
       self:resize(0) 
    end

    return inst
end

return ObjPool