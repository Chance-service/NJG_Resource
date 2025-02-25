--[[ 
    name: SummonSubPage_Friend
    desc: 召喚 子頁面 友情召喚
    author: youzi
    update: 2023/10/24 14:10
    description: 
--]]

local HP_pb = require("HP_pb") -- 包含协议id文件
local Activity5_pb = require("Activity5_pb")

local NodeHelper = require("NodeHelper")
local InfoAccesser = require("Util.InfoAccesser")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local ALFManager = require("Util.AsyncLoadFileManager")

local SummonDataMgr = require("Summon.SummonDataMgr")

--[[ 測試資料模式 ]]
local IS_MOCK = false


--[[ 本體 ]]

--[[ 本體 ]]
local Inst = require("Summon.SummonSubPage_Base"):new()
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 


--[[ 協定 ]]
Inst.opcodes["ACTIVITY166_CALL_OF_FRIENDSHIP_INFO_S"] = HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_INFO_S
Inst.opcodes["ACTIVITY166_CALL_OF_FRIENDSHIP_DRAW_S"] = HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_DRAW_S
Inst.opcodes["STATE_INFO_SYNC_S"] = HP_pb.STATE_INFO_SYNC_S

--[[ 請求冷卻幀數 ]]
Inst.requestCooldownFrame = 180
--[[ 請求冷卻剩餘 ]]
Inst.requestCooldownLeft = Inst.requestCooldownFrame

--[[ Spine ]]
Inst.spineBG = nil
Inst.spineSummon = nil

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
Inst.base_onReceivePacket = Inst.onReceivePacket
function Inst:onReceivePacket(packet)
    local slf = self

    self:base_onReceivePacket(packet)

    if self:handleSummonError(packet, HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_DRAW_C) == true then return end

    if packet.opcode == HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_INFO_S or
           packet.opcode == HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_DRAW_S then

        if packet.opcode == HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_INFO_S then
            print("ACTIVITY166_CALL_OF_FRIENDSHIP_INFO_S")
        end
        
        if packet.msg == nil then
            local msg = Activity5_pb.Activity166Info()
            msg:ParseFromString(packet.msgBuff)
            packet.msg = msg
        end

        self:handleResponseInfo(packet.msg)
    end
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter_content ()
    local slf = self

    -- 設置 背景圖 尺寸自適應
    self.container:getVarNode("bgImg"):setScale(NodeHelper:getScaleProportion())

    -- 設置 Spine動畫
    if self.subPageCfg.spineBGs ~= nil then

        local spineBGContainer = self.container:getVarNode("spineBGNode")
        local spineBGs = {}
        for idx, val in ipairs(self.subPageCfg.spineBGs) do
            local spineFolderAndName = common:split(val, ",")
            local spineBG = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
            local spineBGNode = tolua.cast(spineBG, "CCNode")
            spineBGNode:setAnchorPoint(ccp(0.5, 0))
            spineBGNode:setPositionY(1280/2)
            spineBGs[#spineBGs+1] = spineBG
            spineBGContainer:addChild(spineBGNode)
        end

        self.spineBG = {
            setToSetupPose = function (self)
                print("setToSetupPose")
                for idx, val in ipairs(spineBGs) do
                    val:setToSetupPose()
                end
            end,
            runAnimation = function (self, layer, name, loop)
                for idx, val in ipairs(spineBGs) do
                    val:runAnimation(layer, name, loop)
                end
            end,
        }
        self.spineBG:setToSetupPose()
        self.spineBG:runAnimation(1, self.subPageCfg.spineAnimName_bg_idle, -1)
    end

end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(selfContainer, parentPage)
    if Inst.JumpAnim then
        NodeHelper:setSpriteImage(self.container,{mSwitch="common_switch1_on.png"})
    else
        NodeHelper:setSpriteImage(self.container,{mSwitch="common_switch1.png"})
    end
end

--[[ 當 頁面 離開 ]]
Inst.base_onExit = Inst.onExit
function Inst:onExit(selfContainer, parentPage)

    self:base_onExit(selfContainer, parentPage)
    
    self.spineBG = nil
    self.spineSummon = nil
    self.spineSummonNode = nil
    self.isSummoning = false
    if self.task then
        ALFManager:cancel(self.task)
        self.task = nil
    end
end

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 載入 召喚Spine ]]
function Inst:loadSummonSpine ()
    -- 設置 Spine動畫
    if not self.spineSummon and self.subPageCfg.spineSummon ~= nil then

        local spineFolderAndName = common:split(self.subPageCfg.spineSummon, ",")
        self.spineSummon = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
        self.spineSummon:registerFunctionHandler("SELF_EVENT", function(unknownArg, tag, eventName)
            if eventName == "end" then
                if self.onSummonAnimDone_fn ~= nil then 
                    local temp = self.onSummonAnimDone_fn
                    self.onSummonAnimDone_fn = nil
                    temp()
                end
            end
        end)
        self.spineSummonNode = tolua.cast(self.spineSummon, "CCNode")
        NodeHelperUZ:fitBGSpine(self.spineSummonNode, {
            -- 目標中心點
            pivot = ccp(0.5, 0),
        })

        self.spineSummon:setToSetupPose()
        self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_summon_idle, -1)
        
        self.container:getVarNode("spineSummonNode"):addChild(self.spineSummonNode)
    end
end

--[[ 播放 召喚Spine ]]
function Inst:playSummonSpine (rewardDatas)

    if self.spineSummon ~= nil then
        self.spineSummon:setToSetupPose()
        self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_summon_summon or "summon", 0)
    end
    if self.spineBG ~= nil then
        self.spineBG:setToSetupPose()
        self.spineBG:runAnimation(1, self.subPageCfg.spineAnimName_bg_summon or "summon", 0)
    end
end

--[[ 送出 請求資訊 ]]
Inst.base_sendRequestInfo = Inst.sendRequestInfo
function Inst:sendRequestInfo (isShowLoading)
    if isShowLoading == nil then isShowLoading = true end
    if IS_MOCK then
        self:onReceivePacket({
            opcode = HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_INFO_S,
            msg = {
                onceCostPoint = 120,
                tenCostPoint = 1200,
            }
        })
        return
    end
    self:base_sendRequestInfo(isShowLoading)
    common:sendEmptyPacket(HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_INFO_C, isShowLoading)
end


--[[ 處理 回傳 ]]
function Inst:handleResponseInfo (msgInfo, onReceiveDone)
    local slf = self

    local isPriceDataExist = false
    local priceData = {}

    -- dump(msgInfo, "msgInfo")
    -- print(string.format("msgInfo.onceCostPoint : %s", tostring(msgInfo.onceCostPoint)))
    -- print(string.format("msgInfo.tenCostPoint : %s", tostring(msgInfo.tenCostPoint)))
    -- for idx, val in ipairs(msgInfo.reward) do
    --     print(string.format("msgInfo.reward[%d] : %s", idx, tostring(val)))
    -- end

    -- 設置 單/十抽 價格
    if msgInfo.onceCostPoint ~= nil then
        isPriceDataExist = true
        self.summonPriceStr = "10000_1025_"..tostring(msgInfo.onceCostPoint)
        local summonPrice_itemInfo = InfoAccesser:getItemInfoByStr(self.summonPriceStr)
        local summonPrice_itemIconCfg = InfoAccesser:getItemIconCfg(summonPrice_itemInfo.type, summonPrice_itemInfo.id, "SummonPrice")
        priceData.icon = summonPrice_itemInfo.icon
        priceData.iconScale = summonPrice_itemIconCfg.scale
        priceData.price1 = summonPrice_itemInfo.count
    end
    if msgInfo.tenCostPoint ~= nil then
        isPriceDataExist = true
        self.summon10PriceStr = "10000_1025_"..tostring(msgInfo.tenCostPoint)
        local summon10Price_itemInfo = InfoAccesser:getItemInfoByStr(self.summon10PriceStr)
        local summon10Price_itemIconCfg = InfoAccesser:getItemIconCfg(summon10Price_itemInfo.type, summon10Price_itemInfo.id, "SummonPrice")
        priceData.icon10 = summon10Price_itemInfo.icon
        priceData.iconScale = summon10Price_itemIconCfg.scale
        priceData.price10 = summon10Price_itemInfo.count
    end
        
    if isPriceDataExist then
        self:setSummonPrice(0, priceData)
    end

    -- 若有收到獎勵
    if msgInfo.reward and #msgInfo.reward ~= 0 then
        local itemStrs = msgInfo.reward
        self:handleRewards(itemStrs)
    end

    -- 更新 玩家持有貨幣資訊
    self:updateCurrency()

end

--[[ 送出 單抽 ]]
function Inst:sendSummon1 ()
    if IS_MOCK then
        self:onReceivePacket({
            opcode = HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_DRAW_S,
            msg = {
                reward = "10000_1001_1",
            }
        })
        return
    end
    if self.isSummoning then
        return
    end
    self.isSummoning = true
    -- 載入 召喚Spine
    local spineFolderAndName = common:split(self.subPageCfg.spineSummon, ",")
    local texNum = self.spineSummon and 0 or 30
    self.task = ALFManager:loadSpineTask(spineFolderAndName[1] .. "/", spineFolderAndName[2], texNum, function() 
        if not Inst.JumpAnim then
            self:loadSummonSpine()
        end

        local msg = Activity5_pb.Activity166Draw()
        msg.times = 1
        common:sendPacket(HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_DRAW_C, msg, true)

        self.isSummoning = false
    end)
end

--[[ 送出 十抽 ]]
function Inst:sendSummon10 ()
    if IS_MOCK then
        self:onReceivePacket({
            opcode = HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_DRAW_S,
            msg = {
                reward = "10000_1001_1,10000_1002_1,10000_1003_1,10000_1004_1,10000_1005_1,10000_1006_1,10000_1007_1,10000_1008_1,10000_1009_1,10000_1010_1",
            }
        })
        return
    end
    if self.isSummoning then
        return
    end
    self.isSummoning = true
    -- 載入 召喚Spine
    local spineFolderAndName = common:split(self.subPageCfg.spineSummon, ",")
    local texNum = self.spineSummon and 0 or 30
    self.task = ALFManager:loadSpineTask(spineFolderAndName[1] .. "/", spineFolderAndName[2], texNum, function() 
        if not Inst.JumpAnim then
            self:loadSummonSpine()
        end

        local msg = Activity5_pb.Activity166Draw()
        msg.times = 10
        common:sendPacket(HP_pb.ACTIVITY166_CALL_OF_FRIENDSHIP_DRAW_C, msg, true)

        self.isSummoning = false
    end)
end

return Inst