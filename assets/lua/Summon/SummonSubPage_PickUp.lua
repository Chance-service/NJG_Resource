local HP_pb            = require("HP_pb")            -- 協定 id 檔案
local Activity6_pb     = require("Activity6_pb")

local NodeHelper       = require("NodeHelper")
local NodeHelperUZ     = require("Util.NodeHelperUZ")
local InfoAccesser     = require("Util.InfoAccesser")
local TimeDateUtil     = require("Util.TimeDateUtil")
local ALFManager       = require("Util.AsyncLoadFileManager")

local SummonDataMgr    = require("Summon.SummonDataMgr")
local SummonPickUpData = require("Summon.SummonPickUpData")

local PRICE_ITEM_WITHOUT_COUNT_STR = "10000_1001_"
local VOUCHER_ITEM_STR             = ""

-- 測試資料模式
local IS_MOCK = false

-- 將倒數計時管理局部化
local CountDown = {}

local Inst = require("Summon.SummonSubPage_Base"):new()

function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    -- 初始化成員變數
    o.leftTime    = {}
    o.isSummoning = false
    return o
end

--------------------------------------------------------------------------------
-- 保存基底方法供後續調用
--------------------------------------------------------------------------------
Inst.base_onReceivePacket  = Inst.onReceivePacket
Inst.base_sendRequestInfo  = Inst.sendRequestInfo
Inst.base_onExit           = Inst.onExit

-- 協定碼映射
Inst.opcodes["ACTIVITY197_SUPER_PICKUP_INFO_S"] = HP_pb.ACTIVITY197_SUPER_PICKUP_INFO_S
Inst.opcodes["ACTIVITY197_SUPER_PICKUP_DRAW_S"] = HP_pb.ACTIVITY197_SUPER_PICKUP_DRAW_S

-- 請求冷卻設定
Inst.requestCooldownFrame = 180
Inst.requestCooldownLeft  = Inst.requestCooldownFrame

-- Spine 相關變數
Inst.spineBG         = nil
Inst.spineSummon     = nil
Inst.spineSummonNode = nil

Inst.orin_summonPriceStr   = nil
Inst.orin_summon10PriceStr = nil

-- 用於 type 設定（BG、Spine、Chibi、Jump）
local BG_type, Spine_type, Chibi_type, Jump_type = 0, 0, 0, 0

--------------------------------------------------------------------------------
-- 收到封包處理
--------------------------------------------------------------------------------
function Inst:onReceivePacket(packet)
    self:base_onReceivePacket(packet)

    if self:handleSummonError(packet, HP_pb.ACTIVITY197_SUPER_PICKUP_DRAW_C) then 
        return 
    end

    if packet.opcode == HP_pb.ACTIVITY197_SUPER_PICKUP_DRAW_S then
        if not packet.msg then
            local msg = Activity6_pb.SuperPickUpList()
            msg:ParseFromString(packet.msgBuff)
            packet.msg = msg
        end
        SummonPickUpDataBase_SetInfo(packet.msg)
        self:initData()
    end
end

--------------------------------------------------------------------------------
-- 設置背景 Spine
--------------------------------------------------------------------------------
function Inst:setSpineBG()
    if not self.subPageCfg.spineBG then return end

    local spineFolderAndName = common:split(self.subPageCfg.spineBG, ",")
    self.spineBG = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
    
    local selfRef = self
    self.spineBG:registerFunctionHandler("SELF_EVENT", function(_, _, eventName)
        if eventName:lower() == "end" and selfRef.onSummonAnimDone_fn then
            local cb = selfRef.onSummonAnimDone_fn
            selfRef.onSummonAnimDone_fn = nil
            cb()
        end
    end)
    
    local spineBGNode = tolua.cast(self.spineBG, "CCNode")
    NodeHelperUZ:fitBGSpine(spineBGNode, { pivot = ccp(0.5, 0) })
    self.spineBG:setToSetupPose()
    self.spineBG:runAnimation(1, self.subPageCfg.spineAnimName_bg_idle, -1)
    self.container:getVarNode("spineBGNode"):addChild(spineBGNode)
end

--------------------------------------------------------------------------------
-- 頁面進入
--------------------------------------------------------------------------------
function Inst:onEnter_content()
    self.parentPage.tabStorage:setHelpBtn(true)
    
    local VisibleTable = {}
    local ImgTable     = {}
    local StringTable  = {}

    -- 設置 Banner
    ImgTable["mBanner"] = self.subPageCfg.data.Banner

    -- 解析類型參數
    local types = common:split(self.subPageCfg.data.type, ",")
    BG_type    = tonumber(types[1])
    Spine_type = tonumber(types[2])
    Chibi_type = tonumber(types[3])
    Jump_type  = tonumber(types[4])
    
    local parentNode = self.container:getVarNode("mSpineNode")
    parentNode:removeAllChildrenWithCleanup(true)

    -- 設置背景
    if BG_type == 0 then
        VisibleTable["mMemoryBg"] = false
    elseif BG_type == 1 then
        VisibleTable["mMemoryBg"] = true
        ImgTable["mMemoryBg"] = self.subPageCfg.data.BG and ("BG/UI/" .. self.subPageCfg.data.BG)
                                        or "BG/UI/SummonPickup_bg02.png"
    end

    -- 設置 Spine 或圖片
    if Spine_type == 0 then
        VisibleTable["mMemoryImg"]  = false
        VisibleTable["spineBGNode"] = true
        self:setSpineBG()
    elseif Spine_type == 1 then
        VisibleTable["mMemoryImg"]  = true
        VisibleTable["spineBGNode"] = false
        ImgTable["mMemoryImg"] = "BG/UI/" .. self.subPageCfg.data.spine
    end

    -- 設置小人 (Chibi)
    if Chibi_type == 0 then 
        VisibleTable["mSpineNode"] = true
        VisibleTable["mMemory_S"]  = false
        local spineFolderAndName = common:split(self.subPageCfg.data.chibi, ",")
        local chibiSpine = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
        local chibiNode  = tolua.cast(chibiSpine, "CCNode")
        parentNode:addChild(chibiNode)
        chibiSpine:runAnimation(1, "wait_0", -1)
    elseif Chibi_type == 1 then
        VisibleTable["mSpineNode"] = false
        VisibleTable["mMemory_S"]  = true
        ImgTable["mMemory_S"] = self.subPageCfg.data.chibi
    end

    VisibleTable["mGachaInfo"] = false
    StringTable["mDesc"] = common:getLanguageString(self.subPageCfg.data.Desc)

    NodeHelper:setStringForLabel(self.container, StringTable)
    NodeHelper:setSpriteImage(self.container, ImgTable)
    NodeHelper:setNodesVisible(self.container, VisibleTable)
    
    self:initData()
end

--------------------------------------------------------------------------------
-- 每幀執行邏輯
--------------------------------------------------------------------------------
function Inst:onExecute(selfContainer, parentPage)
    if not self.subPageCfg.isFreeSummonAble then return end
    
    local clientTime = os.time()
    if self.summonFreeQuota <= 0 and self.nextFreeTime ~= -1 then
        local nextFreeLeftTime = math.max(0, self.nextFreeTime - clientTime)
        -- 可根據需求利用 nextFreeLeftTime 做進一步處理
    end

    if self.requestCooldownLeft > 0 then
        self.requestCooldownLeft = self.requestCooldownLeft - 1
    end

    if self.nextFreeTime ~= -1 and clientTime > self.nextFreeTime and self.requestCooldownLeft <= 0 then
        self.requestCooldownLeft = self.requestCooldownFrame
        self:sendRequestInfo(nil, self.subPageCfg.data.id, false)
    end

    local switchSprite = self.JumpAnim and "common_switch1_on.png" or "common_switch1.png"
    NodeHelper:setSpriteImage(self.container, { mSwitch = switchSprite })
end

--------------------------------------------------------------------------------
-- 頁面離開
--------------------------------------------------------------------------------
function Inst:onExit(selfContainer, parentPage)
    self:base_onExit(selfContainer, parentPage)
    
    self.spineBG         = nil
    self.spineSummon     = nil
    self.spineSummonNode = nil
    self.isSummoning     = false
    if self.task then
        ALFManager:cancel(self.task)
        self.task = nil
    end
end

--------------------------------------------------------------------------------
-- 清除所有倒數計時
--------------------------------------------------------------------------------
function Inst:ClearCount()
    for k, entry in pairs(CountDown) do
       CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(entry)
       CountDown[k] = nil
    end
end

--------------------------------------------------------------------------------
-- 載入召喚 Spine 動畫
--------------------------------------------------------------------------------
function Inst:loadSummonSpine()
    if self.spineSummon or not self.subPageCfg.spineSummon then return end

    local spineFolderAndName = common:split(self.subPageCfg.spineSummon, ",")
    self.spineSummon = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
    
    local selfRef = self
    self.spineSummon:registerFunctionHandler("SELF_EVENT", function(_, _, eventName)
        if eventName:lower() == "end" and selfRef.onSummonAnimDone_fn then
            local cb = selfRef.onSummonAnimDone_fn
            selfRef.onSummonAnimDone_fn = nil
            cb()
        end
    end)
    
    local spineSummonNode = tolua.cast(self.spineSummon, "CCNode")
    NodeHelperUZ:fitBGSpine(spineSummonNode, { pivot = ccp(0.5, 0) })
    self.spineSummon:setToSetupPose()
    self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_summon_idle, -1)
    self.container:getVarNode("spineSummonNode"):addChild(spineSummonNode)
end

--------------------------------------------------------------------------------
-- 播放召喚 Spine 動畫 (根據獎勵品質決定動畫等級)
--------------------------------------------------------------------------------
function Inst:playSummonSpine(rewardDatas)
    local animLevel = 1
    local heroCfgs  = ConfigManager.getNewHeroCfg()
    local equipCfgs = ConfigManager.getEquipCfg()
    
    for _, rewardData in ipairs(rewardDatas) do 
        local newAnimLevel = animLevel
        if rewardData.type == SummonDataMgr.RewardType.HERO then
            local heroCfg = heroCfgs[rewardData.id]
            if heroCfg then
                newAnimLevel = (heroCfg.Star < 6) and 2 or 3
            end
        elseif rewardData.type == SummonDataMgr.RewardType.AW_EQUIP then
            local equipCfg = equipCfgs[rewardData.id]
            if equipCfg then
                newAnimLevel = (equipCfg.quality < 6) and 2 or 3
            end
        end
        animLevel = math.max(animLevel, newAnimLevel)
        if animLevel >= 3 then break end
    end

    local summonAnimName = self.subPageCfg.spineAnimName_summon_summon_list[animLevel]
    if self.spineSummon then
        self.spineSummon:setToSetupPose()
        self.spineSummon:runAnimation(1, summonAnimName, 0)
    end
    if self.spineBG and Spine_type == 0 then
        self.spineBG:setToSetupPose()
        self.spineBG:runAnimation(1, self.subPageCfg.spineAnimName_bg_summon, 0)
    end
end

--------------------------------------------------------------------------------
-- 發送請求資訊
--------------------------------------------------------------------------------
function Inst:sendRequestInfo(isShowLoading, id, isEnter)
    if isEnter == nil then return end
    isShowLoading = isShowLoading or true
    id = id or 0
    self:base_sendRequestInfo(isShowLoading, id, false)
    
    local msg = Activity6_pb.SuperPickUpSync()
    msg.id = id
    common:sendPacket(HP_pb.ACTIVITY197_SUPER_PICKUP_INFO_C, msg, isShowLoading)
end

--------------------------------------------------------------------------------
-- 處理回傳資料 (根據需求實作)
--------------------------------------------------------------------------------
function Inst:handleResponseInfo()
    -- 可根據需求實作數據處理邏輯
end

--------------------------------------------------------------------------------
-- 初始化資料
--------------------------------------------------------------------------------
function Inst:initData()
    if not self.subPageCfg then return end

    local id      = self.subPageCfg.data.id
    local allData = SummonPickUpDataBase_getData()
    local msgInfo = allData[id]
    if not msgInfo then return end

    for key, data in pairs(allData) do
        self:setCountDown(key, data.leftTime)
    end
   
    local isPriceDataExist = false
    local priceData = {}

    -- 設置單抽與十抽價格
    if msgInfo.onceCostGold then
        isPriceDataExist = true
        self.orin_summonPriceStr = PRICE_ITEM_WITHOUT_COUNT_STR .. tostring(msgInfo.onceCostGold)
        local itemInfo = InfoAccesser:getItemInfoByStr(self.orin_summonPriceStr)
        local iconCfg  = InfoAccesser:getItemIconCfg(itemInfo.type, itemInfo.id, "SummonPrice")
        priceData.icon       = itemInfo.icon
        priceData.iconScale  = iconCfg.scale
        priceData.price1     = itemInfo.count
    end
    if msgInfo.tenCostGold then
        isPriceDataExist = true
        self.orin_summon10PriceStr = PRICE_ITEM_WITHOUT_COUNT_STR .. tostring(msgInfo.tenCostGold)
        local itemInfo10 = InfoAccesser:getItemInfoByStr(self.orin_summon10PriceStr)
        local iconCfg10  = InfoAccesser:getItemIconCfg(itemInfo10.type, itemInfo10.id, "SummonPrice")
        priceData.icon10      = itemInfo10.icon
        priceData.iconScale   = iconCfg10.scale
        priceData.price10     = itemInfo10.count
    end

    VOUCHER_ITEM_STR = msgInfo.ticket
    local voucherCount = InfoAccesser:getUserItemCountByStr(VOUCHER_ITEM_STR)
    self.summonPriceStr   = self.orin_summonPriceStr
    self.summon10PriceStr = self.orin_summon10PriceStr

    if voucherCount >= 1 and (not msgInfo.freeTimes or msgInfo.freeTimes <= 0) then
        isPriceDataExist = true
        local voucherInfo = InfoAccesser:getItemInfoByStr(VOUCHER_ITEM_STR)
        local voucherIconCfg = InfoAccesser:getItemIconCfg(voucherInfo.type, voucherInfo.id, "SummonPrice")
        priceData.icon      = voucherInfo.icon
        priceData.iconScale = voucherIconCfg.scale
        priceData.price1    = 1
        self.summonPriceStr = InfoAccesser:getItemInfoStr({
            type  = voucherInfo.type, 
            id    = voucherInfo.id,
            count = 1,
        })
    end
    if voucherCount >= 10 then
        isPriceDataExist = true
        local voucherInfo = InfoAccesser:getItemInfoByStr(VOUCHER_ITEM_STR)
        priceData.icon10   = voucherInfo.icon
        priceData.price10  = 10
        self.summon10PriceStr = InfoAccesser:getItemInfoStr({
            type  = voucherInfo.type, 
            id    = voucherInfo.id,
            count = 10,
        })
    end

    if isPriceDataExist then
        self:setSummonPrice(0, priceData)
    end

    -- 設置免費抽次數
    if msgInfo.freeTimes then
        self.summonFreeQuota = (msgInfo.freeTimes == -1) and 0 or msgInfo.freeTimes
        self:setSummonFree(self.summonFreeQuota)
    end

    -- 設置下次免費補充時間
    self.nextFreeTime = TimeDateUtil:getNextDayUTCTime(8)
    
    if msgInfo.leftAwardTimes then
        local visible = msgInfo.leftAwardTimes ~= 0
        NodeHelper:setNodesVisible(self.container, { mGachaInfo = visible })
        NodeHelper:setStringForTTFLabel(self.container, {
            summonPittyLeftDescTxt = common:getLanguageString("@Summon.SpecialpittyDesc", msgInfo.leftAwardTimes, "")
        })
    end

    -- 處理獎勵
    if msgInfo.reward and #msgInfo.reward > 0 then
        self:handleRewards(msgInfo.reward)
        SummonPickUpDataBase_ClearReward()
    end

    -- 更新玩家貨幣資訊
    self:updateCurrency()
end

--------------------------------------------------------------------------------
-- 設置倒數計時
--------------------------------------------------------------------------------
function Inst:setCountDown(id, leftTime)
    self.leftTime[id] = leftTime
    if not CountDown[id] then
        local scheduler = CCDirector:sharedDirector():getScheduler()
        CountDown[id] = scheduler:scheduleScriptFunc(function()
            self.leftTime[id] = self.leftTime[id] - 1
            SummonPickUpDataBase_setTime(id, self.leftTime[id])
            print(id.." : "..self.leftTime[id])
            local lastIdx = self.parentPage.tabStorage.lastSelectIdx
            local PageName = self.parentPage.subPageDatas[lastIdx].subPageName
            if CountDown[id] and self.leftTime[id] <= 0 and PageName == "PickUp" .. id then
                PageManager.showConfirm("@PickUp_ErrorText_1", "@PickUp_ErrorText_2", function(isSure)
                    if isSure then
                        MainFrame_onMainPageBtn()
                    end
                end, true, nil, nil, false, nil, nil, nil, false)
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(CountDown[id])
                CountDown[id] = nil
            end
        end, 1, false)
    end
end

--------------------------------------------------------------------------------
-- 統一發送召喚請求 (單抽/十抽)
--------------------------------------------------------------------------------
function Inst:sendSummon(times)
    if self.isSummoning then return end
    self.isSummoning = true

    local spineFolderAndName = common:split(self.subPageCfg.spineSummon, ",")
    local texNum = self.spineSummon and 0 or 30

    self.task = ALFManager:loadSpineTask(spineFolderAndName[1] .. "/", spineFolderAndName[2], texNum, function()
        if not self.JumpAnim then
            self:loadSummonSpine()
        end
        local msg = Activity6_pb.SuperPickUpDraw()
        msg.times = times
        msg.id    = self.subPageCfg.data.id
        common:sendPacket(HP_pb.ACTIVITY197_SUPER_PICKUP_DRAW_C, msg, true)
        self.isSummoning = false
    end)
end

function Inst:sendSummon1()
    self:sendSummon(1)
end

function Inst:sendSummon10()
    self:sendSummon(10)
end

--------------------------------------------------------------------------------
-- 點擊 Spine 事件處理
--------------------------------------------------------------------------------
function Inst:onHandNode()
    if Jump_type == 0 then
        local rolePage = require("NgArchivePage")
        PageManager.pushPage("NgArchivePage")
        rolePage:setMercenaryId(self.subPageCfg.data.Jump)
    elseif Jump_type == 1 then
        local UserItemManager = require("Item.UserItemManager")
        local userItem = UserItemManager:getUserItemByItemId(self.subPageCfg.data.Jump)
        PageManager.showItemInfo(userItem.id)
    end
end

return Inst
