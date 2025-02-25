
--[[ 
    name: SpiritStatusPage
    desc: 精靈島狀態葉面
    author: youzi
    update: 2023/9/19 17:07
    description: 從 CommItemReceivePage.lua 改製.
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件

local Async = require("Util.Async")
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")

local thisPageName = "Spirit.SpiritStatusPage"

----这里是协议的id
local opcodes = {

}

local option = {
    ccbiFile = "SpiritStatus.ccbi",
    handlerMap =
    {
        -- 點擊 離開
        onClose = "onExitClick",
        onHelp = "onHelpClick",
    },
    opcode = opcodes
}

local SpiritStatusPage = {}
function SpiritStatusPage:new ()

    local inst = {}

    --[[ 容器 ]]
    inst.container = nil

    --[[ 狀態資訊 ]]
    inst.statusInfo = {}

    --[[ 當 關閉 行為 ]]
    inst.onceClose_fn = nil

    -- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
    --  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
    --  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
    --  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
    --  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
    --  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
    -- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 

    --[[ 當 收到訊息 ]]
    function inst:onReceiveMessage(container)
        local message = container:getMessage();
        local typeId = message:getTypeId();
        -- if typeId == XXXXXXXXXX then
        --     local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;
        --     if opcode == HP_pb.XXXXXXX then
        --         
        --     end
        -- end
    end

    --[[ 當 收到封包 ]]
    function inst:onReceivePacket(container)
        local opcode = container:getRecPacketOpcode()
        local msgBuff = container:getRecPacketBuffer()

        -- if opcode == HP_pb.XXXXXXXX then
        --     local msg = XXXXXXXXXX
        --     msg:ParseFromString(msgBuff)
        
        --     return
        -- end
    end
    
    --[[ 註冊 封包相關 ]]
    function inst:registerPacket(container)
        for key, opcode in pairs(opcodes) do
            if string.sub(key, -1) == "S" then
                container:registerPacket(opcode)
            end
        end
    end
    --[[ 註銷 封包相關 ]]
    function inst:removePacket(container)
        for key, opcode in pairs(opcodes) do
            if string.sub(key, -1) == "S" then
                container:removePacket(opcode);
            end
        end
    end

    --[[ 當 頁面 進入 ]]
    function inst:onEnter (container)
        self.container = container

        -- print("SpiritStatusPage.onEnter")
        
        -- 註冊 封包相關
        self:registerPacket(container)


        -- 刷新狀態資訊
        self:updateStatus()

    end

    --[[ 當 頁面 離開 ]]
    function inst:onExit(container)
        self:removePacket(container)

        self.onceClose_fn = NIL
        self.statusInfo = {}

        onUnload(thisPageName, container)
    end

    --[[ 當 關閉 按下 ]]
    function inst:onExitClick(container, eventName)
       
        -- 關閉 頁面
        PageManager.popPage(thisPageName)
    
        -- 若 有關閉行為 則 呼叫
        if self.onceClose_fn then
            self.onceClose_fn()
            self.onceClose_fn = nil
        end
    end

    --[[ 當 幫助 按下 ]]
    function inst:onHelpClick(container, eventName)
       
    end

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 刷新 狀態 ]]
    function inst:updateStatus()
        local slf = self
        
        local cur = self.statusInfo.cur
        local nxt = self.statusInfo.nxt

        local node2Text = {
            ["cur_evolLevelNum"] = tostring(cur.group),
            ["cur_levelCapNum"] = tostring(cur.levelCap),
            ["nxt_evolLevelNum"] = tostring(nxt.group),
            ["nxt_levelCapNum"] = tostring(nxt.levelCap),
        }

        for idx = 1, #cur.attrs do 
            local idxStr = tostring(idx)
            node2Text["cur_attrNum"..idxStr] = cur.attrs[idx].val or "0"
        end
        for idx = 1, #nxt.attrs do 
            local idxStr = tostring(idx)
            node2Text["nxt_attrNum"..idxStr] = nxt.attrs[idx].val or "0"
        end

        NodeHelper:setStringForLabel(self.container, node2Text)

    end

    --[[ 準備 ]]
    function inst:prepare(options)

        local statusInfo = options["statusInfo"]
        if statusInfo ~= nil then
            self:setStatusInfo(statusInfo)
        end

        local onceClose_fn = options["onceClose_fn"]
        if onceClose_fn ~= nil then
            self.onceClose_fn = onceClose_fn
        end
        
    end

    --[[ 設置 狀態資訊 ]]
    function inst:setStatusInfo (statusInfo)
        self.statusInfo = statusInfo
    end


    -- ########  ########  #### ##     ##    ###    ######## ######## 
    -- ##     ## ##     ##  ##  ##     ##   ## ##      ##    ##       
    -- ##     ## ##     ##  ##  ##     ##  ##   ##     ##    ##       
    -- ########  ########   ##  ##     ## ##     ##    ##    ######   
    -- ##        ##   ##    ##   ##   ##  #########    ##    ##       
    -- ##        ##    ##   ##    ## ##   ##     ##    ##    ##       
    -- ##        ##     ## ####    ###    ##     ##    ##    ######## 


    return inst
end

local CommonPage = require('CommonPage')
return CommonPage.newSub(SpiritStatusPage:new(), thisPageName, option)