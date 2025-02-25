--[[ 
    name: PacketAgent
    desc: 協定收發代理器
    author: youzi
    update: 2023/11/20 17:47
    description: 
        原設計是透過各頁面自身的介面去註冊協定的收取, 不確定有什麼考量, 但極度難用.
        此代理器是透過統一單個CCBScriptContainer來提供給其他功能.
        讓其他功能自由決定呼叫時機, 以Listener註冊或發送協定, 不須綁定頁面介面.
        代理器再考慮當下的Event與Listener來向自身的介面來註冊/註銷協定收取.
--]]


local Event = require("Util.Event")

local PacketAgent = {}

--[[ ID 對應 實例 ]]
PacketAgent.id2inst = {}

--[[ 取得實例 ]]
function PacketAgent:inst(id)
    if id == nil then id = "default" end

    local exist = PacketAgent.id2inst[id]

    -- 若 不存在 則 建立
    if exist == nil then
        exist = PacketAgent:new()
        PacketAgent.id2inst[id] = exist
    end

    return exist
end

function PacketAgent:new()

    local Inst = {}

    --[[ 協定 對應 事件 ]]
    Inst.opcode2Event = {}

    --[[ 協定 對應 建立訊息方法 ]]
    Inst.opcode2MsgCreateFn = {}

    --[[ 初始化 ]]
    function Inst:init (parentNode)
        local slf = self

        -- 若 尚未建立容器
        if self.container == nil then
            -- 以腳本建立 CCBScriptContainer
            self.container = CCBScriptContainer:create("Util.PacketAgentContainer");
            self.container:load()
            -- 設為 目標父節點 的 子節點
            if parentNode ~= nil then
                parentNode:addChild(self.container)
            end
            self.container:release()

            -- 註冊
            self.container:registerFunctionHandler(function(eventName, container)

                -- 若 非接收到封包 則 跳出
                if eventName ~= "luaReceivePacket" then return end

                -- 取得 協定與訊息
                local opcode = self.container:getRecPacketOpcode()
                local msgBuff = self.container:getRecPacketBuffer()
                local msg = nil

                -- 若 有 該協定的綁定訊息 則 解析訊息
                local msgCreateFn = slf.opcode2MsgCreateFn[opcode]
                if msgCreateFn ~= nil then
                    msg = msgCreateFn()
                    msg:ParseFromString(msgBuff)
                end

                -- 建立封包
                local packet = {
                    opcode = opcode,
                    msgBuff = msgBuff,
                    msg = msg,
                }

                -- 呼叫當收到封包
                slf:onReceivePacket(packet) 
            end)
        end

        return self
    end

    --[[ 當收到封包 ]]
    function Inst:onReceivePacket (packet)
        -- 取得並呼叫 該協定 的 事件
        local evt = self.opcode2Event[packet.opcode]
        if evt == nil then return end
        evt:emit(packet)
    end

    --[[ 綁定 協定與訊息 ]]
    function Inst:bindOpcodeMsg (opcode, msgCreateFn)
        self.opcode2MsgCreateFn[opcode] = msgCreateFn
    end

    --[[ 發送 協定 並 接收回傳 ]]
    function Inst:send (sendOpcode, msg, receiveOpcode, onRecieveFn, options)
        if options == nil then options = {} end

        local slf = self

        local isWait = true
        if options.isWait ~= nil then 
            isWait = options.isWait
        end

        -- 發送協定封包
        if msg ~= nil then
            common:sendPacket(sendOpcode, msg, isWait)
        else
            common:sendEmptyPacket(sendOpcode, isWait)
        end

        if receiveOpcode ~= nil then
            -- 註冊 當收到協定封包時
            local listener = nil
            listener = self:on(receiveOpcode, function (data, ctrlr)
            
                -- 是否取用 (預設是)
                local isTook = true
                -- 若有回呼
                if onRecieveFn ~= nil then 
                    -- 呼叫並決定是否取用
                    isTook = onRecieveFn(ctrlr.data)
                    -- 預設為取用
                    if isTook == nil then isTook = true end
                end

                -- 若已經取用
                if isTook then
                    -- 忽略其他回呼
                    ctrlr:ignore("_responseToSend")
                    -- 移除偵聽
                    slf:off(receiveOpcode, listener)
                end
            end):tag("_responseToSend")
        end
    end

    --[[ 註冊 當接收到協定 ]]
    function Inst:on (opcode, fn)
        local evt = self:getEvent(opcode, true)
        return evt:on(fn)
    end

    --[[ 註冊 當接收到協定 (單次) ]]
    function Inst:once (opcode, fn)
        local evt = self:getEvent(opcode, true)
        return evt:once(fn)
    end

    --[[ 註銷 當接收到協定 ]]
    function Inst:off (opcode, listener)
        local evt = self:getEvent(opcode, false)
        if evt == nil then return end

        evt:off(listener)

        if #evt.listeners == 0 then
            self:removeEvent(opcode)
        end
        return true
    end

    --[[ 註銷 當接收到協定 ]]
    function Inst:offTag (opcode, tag)
        local evt = self:getEvent(opcode, false)
        if evt == nil then return end

        evt:offTag(tag)

        if #evt.listeners == 0 then
            self:removeEvent(opcode)
        end
    end

    --[[ 註銷 當接收到協定 ]]
    function Inst:offAllTag (tag)
        local toRm = {}
        for opcode, evt in pairs(self.opcode2Event) do
            evt:offTag(tag)
            if #evt.listeners == 0 then
                toRm[#toRm+1] = opcode
            end
        end
        for idx = 1, #toRm do
            self:removeEvent(toRm[idx])
        end
    end

    --[[ 取得事件 ]]
    function Inst:getEvent (opcode, isCreateIfNotExist)
        if isCreateIfNotExist == nil then isCreateIfNotExist = true end
        local evt = self.opcode2Event[opcode]
        if evt == nil and isCreateIfNotExist then
            self.container:registerPacket(opcode)
            evt = Event:new()
            evt.callListenerFn = function(slf, listener, ctrlr)
                listener.fn(ctrlr.data, ctrlr)
            end
            self.opcode2Event[opcode] = evt
        end
        return evt
    end

    --[[ 消除事件 ]]
    function Inst:removeEvent (opcode)
        if self.opcode2Event[opcode] == nil then return end
        self.container:removePacket(opcode)
        self.opcode2Event[opcode] = nil
    end

    return Inst
end


return PacketAgent