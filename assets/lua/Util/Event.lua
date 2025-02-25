
local Event = {}

function Event:new()

    local inst = {}

    inst.listeners = {}

    inst.callListenerFn = nil

    function inst:emit(data)
        
        local ctrlr = {}
        ctrlr.isStop = false
        ctrlr.stop = function(slf)
            slf.isStop = true
        end

        ctrlr.ignoreTags = {}
        ctrlr.ignore = function(slf, tag)
            for idx = 1, #ctrlr.ignoreTags do
                if ctrlr.ignoreTags[idx] == tag then return end
            end
            ctrlr.ignoreTags[#ctrlr.ignoreTags+1] = tag
        end

        ctrlr.currentListener = nil
        ctrlr.onceAgain = function(slf)
            if slf.currentListener ~= nil then
                if slf.currentListener.times == 0 then
                    slf.currentListener.times = 1
                end
            end
        end

        ctrlr.data = data

        local toRm = {}

        local listeners = {}
        for idx, val in ipairs(self.listeners) do
            listeners[idx] = val
        end

        for idx = 1, #listeners do 
            local listener = listeners[idx]
            while true do
                if ctrlr.isStop then break end -- continue
                
                local isIgnore = false
                for tagIdx = 1, #ctrlr.ignoreTags do
                    if listener:hasTag(ctrlr.ignoreTags[tagIdx]) then 
                        isIgnore = true
                        break
                    end
                end
                if isIgnore then break end -- continue

                if not self:has(listener) then break end -- continue
            
                if listener.times > 0 then 
                    listener.times = listener.times - 1
                end
                ctrlr.currentListener = listener
                if self.callListenerFn ~= nil then
                    self.callListenerFn(self, listener, ctrlr)
                else
                    listener.fn(ctrlr)
                end
                ctrlr.currentListener = nil

            break end

            if listener.times == 0 then
                toRm[#toRm+1] = listener
            end
        end

        for idx = #self.listeners, 1, -1 do
            local listener = self.listeners[idx]
            local isRm = false
            for idxx = 1, #toRm do
                local rm = toRm[idxx]
                if listener == rm then
                    isRm = true
                    break
                end
            end
            if isRm then
                table.remove(self.listeners, idx)
            end
        end
         
    end

    function inst:once(listener_or_fn)
        local listener = self:on(listener_or_fn)
        if listener ~= nil then
            listener.times = 1
        end
        return listener
    end

    function inst:on(listener_or_fn)
        local typ = type(listener_or_fn)

        local listener = nil
        local isNew = false

        if typ == "table" then

            if not self:has(listener_or_fn) then
                self.listeners[#self.listeners+1] = listener_or_fn
                isNew = true
            end

            listener = listener_or_fn

        elseif typ == "function" then
            listener = Event:listener(listener_or_fn)
            self.listeners[#self.listeners+1] = listener
            isNew = true
        end

        if listener ~= nil and isNew then
            self:sort()
        end

        return listener
    end

    function inst:off(listener)
        local isFound = false
        for idx = #self.listeners, 1, -1 do
            local eachListener = self.listeners[idx]
            if eachListener == listener then
                table.remove(self.listeners, idx)
                isFound = true
            end
        end
        return isFound
    end

    function inst:offTag(tag)
        for idx = #self.listeners, 1, -1 do
            local listener = self.listeners[idx]
            local isTaged = false
            for idx2, eachTag in ipairs(listener.tags) do
                if eachTag == tag then
                    isTaged = true
                    break
                end
            end
            if isTaged then
                table.remove(self.listeners, idx)
            end
        end
    end

    function inst:has(listener)
        for idx, val in ipairs(self.listeners) do
            if val == listener then return true end
        end
        return false
    end

    function inst:sort()
        table.sort(self.listeners, function(a, b)
            return a.priority > b.priority
        end)
    end

    return inst
end

function Event:listener(fn)
    local inst = {}
    inst.priority = 0
    inst.times = -1
    inst.fn = fn
    inst.tags = {}
    inst.tag = function (slf, ...)
        local tags = {...}
        for idx, tag in ipairs(tags) do

            local isExist = false
            for idx2, exist in ipairs(slf.tags) do
                if exist == tag then
                    isExist = true
                    break
                end
            end
            if not isExist then
                slf.tags[#slf.tags+1] = tag
            end
        end

        return slf
    end
    inst.pri = function(slf, pri)
        slf.priority = pri
    end
    inst.once = function (slf)
        slf.times = 1
        return slf
    end
    inst.hasTag = function (slf, tag)
        for idx = 1, #slf.tags do
            if slf.tags[idx] == tag then return true end
        end
        return false
    end
    return inst
end


return Event