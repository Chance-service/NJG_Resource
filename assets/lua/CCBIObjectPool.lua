---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2019/3/27 11:55
---



CCBIObjectPool = {}
function CCBIObjectPool:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    self.inputClickCCBI = {}
    return o
end

function CCBIObjectPool:Instance()
    if self.instance == nil then
        self.instance = self:new()
    end
    return self.instance
end

function CCBIObjectPool:PopInputClickCCBI()
    local pItem = nil
    if #self.inputClickCCBI == 0 then
        pItem = ScriptContentBase:create("InputClick.ccbi")

    else
        pItem = self.inputClickCCBI[1]
        table.remove(self.inputClickCCBI,1)
    end
    return pItem
end

function CCBIObjectPool:PushInputClickCCBI(contain)
    table.insert(self.inputClickCCBI,contain)
end

--清空对象池Destroy
function CCBIObjectPool:Clear()
    self.inputClickCCBI = {}
end



