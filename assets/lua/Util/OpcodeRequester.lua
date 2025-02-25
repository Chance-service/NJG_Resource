--[[ 
--   name : 協定請求器
--   author : youzi151@gmail.com
--   update : 2023/8/7
--]]


local OpcodeRequester = {}

-- nil 的 代替 (避免 key 2 nil)
OpcodeRequester.NULL = "__nil__"
OpcodeRequester.NIL = OpcodeRequester.NULL

--[[ 新建 ]]
function OpcodeRequester:new () 

    local Inst = {}

    --[[ 協定代碼 : 接收函式 ]]
    Inst.opcode2OnReceive = {}
    
    --[[ 請求key : 任務 ]]
    Inst.key2ReqTask = {}
    
    --[[ 請求 ]]
    -- 傳入 送出協定代碼:protobuf訊息, 接收協定代碼, 當所有接收協定受到呼叫後
    function Inst:request (opcode2Msg, receiveOpcodes, onDone)
        
        -- 自動 產生 key
        local rawKey = tostring(os.time())
        local key = rawKey
        local suffix = 1
        while self.key2ReqTask[key] ~= nil do
            key = rawKey + tostring(suffix)
        end

        -- 準備 剩餘待接收協定代碼
        local lefts = {}
        for idx, opcode in pairs(receiveOpcodes) do
            lefts[#lefts+1] = opcode
        end

        -- 記錄任務
        local task = {
            ["lefts"] = lefts,
            ["onDone"] = onDone
        }
        self.key2ReqTask[key] = task

        -- 送出 協定
        for opcode, msg in pairs(opcode2Msg) do
            if msg == OpcodeRequester.NIL then
                common:sendEmptyPacket(opcode, true)
            else
                common:sendPacket(opcode, msg, true)
            end
        end
    end

    --[[ 註冊 當 接收 ]]
    function Inst:onReceive (_opcode2OnReceive)
        for key, val in pairs(_opcode2OnReceive) do
            self.opcode2OnReceive[key] = val
        end
    end

    --[[ 接收 ]]
    function Inst:receive (opcode, msgBuff)
        local fn = self.opcode2OnReceive[opcode]
        if fn ~= nil then fn(msgBuff) end
        
        local toRm = {}
        for key, task in pairs(self.key2ReqTask) do

            -- 從剩餘中的找出對應並移除
            for idx = #task.lefts, 1, -1 do
                local leftOpcode = task.lefts[idx]
                if opcode == leftOpcode then
                    table.remove(task.lefts, idx)
                end
            end

            -- 若已經消耗完畢 則 呼叫 並 加入 待移除任務
            if #task.lefts == 0 then
                if task.onDone ~= nil then
                    task.onDone()
                end
                toRm[#toRm+1] = key
            end
        end

        for idx, val in ipairs(toRm) do
            self.key2ReqTask[val] = nil
        end
    end

    function Inst:clear ()
        self.opcode2OnReceive = {}
        self.key2ReqTask = {}
    end

    return Inst
end

return OpcodeRequester