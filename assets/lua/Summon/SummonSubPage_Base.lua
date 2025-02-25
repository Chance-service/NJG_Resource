
--[[ 
    name: SummonSubPage_Base
    desc: 召喚 子頁面 基礎
    author: youzi
    update: 2023/10/2 16:26
    description: 
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件
local Activity4_pb = require("Activity4_pb")

local NodeHelper = require("NodeHelper")
local InfoAccesser = require("Util.InfoAccesser")
local TimeDateUtil = require("Util.TimeDateUtil")
local Async = require("Util.Async")

local SummonDataMgr = require("Summon.SummonDataMgr")
local SummonResultPage = require("Summon.SummonResultPage")

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
    onSummonFree = "onSummonBtn",
    onSummon1 = "onSummonBtn",
    onSummon10 = "onSummon10Btn",
    onSkip = "onSummonSkipBtn",
    onHand="onHand",
    onSkipAnim="onSkipAnim"
}

--[[ 本體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 
    text
    
    var
        spineBGNode 背景Spine容器
        spineSummonNode 召喚Spine容器

        summonFreeNode 免費抽按鈕容器
        summonFreeCounterTxt 免費倒數
        summonFreePriceImg 免費抽價格圖標

        summon1Node 單抽按鈕容器
        summon1PriceNum 單抽價格
        summon1PriceImg 單抽價格圖標
        
        summon10Node 十抽按鈕容器
        summon10PriceNum 十抽價格
        summon10PriceImg 十抽價格圖標


        summonPittyLeftDescTxt 保底描述文字

    event
        onSummonFree 單抽按鈕
        onSummon1 單抽按鈕
        onSummon10 十抽按鈕
        onSkip 當跳過
    
--]]



-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

--[[ 父頁面 ]]
Inst.parentPage = nil

--[[ 容器 ]]
Inst.container = nil

--[[ 子頁面資訊 ]]
Inst.subPageName = ""
Inst.subPageCfg = nil

--[[ 協定 ]]
Inst.opcodes = {}
Inst.opcodes["ROLE_PANEL_INFOS_S"] = HP_pb.ROLE_PANEL_INFOS_S
Inst.opcodes["ERROR_CODE"] = HP_pb.ERROR_CODE

--[[ 免費抽次數 ]]
Inst.summonFreeQuota = 0
--[[ 現有貨幣 ]]
Inst.summonCurrency = 0
--[[ 單抽價格 ]]
Inst.summonPrice1 = 0
--[[ 十抽價格 ]]
Inst.summonPrice10 = 0
--[[跳過動畫]]
Inst.JumpAnim=false

--[[ 抽 所需價格 道具資訊 ]]
Inst.summonPriceStr = nil
Inst.summon10PriceStr = nil

--[[ 下次免費補充時間 ]]
Inst.nextFreeTime = -1

--[[ UI是否退場 ]]
Inst.isUIOut = false

--[[ 是否可以跳過 ]]
Inst.isSkippable = true

--[[ 當 召喚動畫 結束 ]]
Inst.onSummonAnimDone_fn = nil
--[[ 當 跳過召喚 ]]
Inst.onSummonSkip_fn = nil

--[[ 當 召喚失敗 ]]
Inst.onSummonFailed_fn = nil

--[[ 當前角色碎片列表 ]]
Inst.lastRole2Piece = nil

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)
    
    if packet.opcode == HP_pb.ROLE_PANEL_INFOS_S then
        
        if packet.msg == nil then
            local msg = RoleOpr_pb.HPRoleInfoRes()
            msg:ParseFromString(packet.msgBuff)
            packet.msg = msg
        end

        if self.lastRole2Piece == nil then 
            self.lastRole2Piece = {}
            for idx, each in ipairs(packet.msg.roleInfos) do
                self.lastRole2Piece[each.itemId] = each.soulCount
            end
        end
    end
end

--[[ 建立 頁面 ]]
function Inst:createPage (parentPage)
    self.parentPage = parentPage
    
    -- 取得 子頁面 配置
    self.subPageCfg = SummonDataMgr:getSubPageCfg(self.subPageName)

    self.container = ScriptContentBase:create(self.subPageCfg.ccbiFile)
    return self.container
end

--[[ 當 頁面 進入 ]]
function Inst:onEnter (selfContainer, parentPage)
    GameUtil:setMainNodeVisible(false)
    local slf = self
    --Inst.JumpAnim=false
    local KEY=CCUserDefault:sharedUserDefault():getBoolForKey("JumpSummonAnim")
    if KEY then
        Inst.JumpAnim=KEY
    else
         CCUserDefault:sharedUserDefault():setBoolForKey("JumpSummonAnim", Inst.JumpAnim);
    end
    -- 註冊 呼叫行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = HANDLER_MAP[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)

    -- 註冊 協定
    self.parentPage:registerPacket(self.opcodes)


    -- 當 頁面進入 內容
    if self.onEnter_content ~= nil then 
        self:onEnter_content()
    end

    -- 預設 關閉 免費刷新
    self:setFreeCooldown(nil)

    -------------------

    self:sendRequestRoleInfos(true)

    -- 請求初始資訊
    self:sendRequestInfo(true)

    -- 新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["SummonPageBase"] = selfContainer
    GuideManager.PageInstRef["SummonPageBase"] = slf
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end

    PageManager.setIsInSummonPage(true)

    SoundManager:getInstance():playMusic("summon_page_bgm.mp3")
    SimpleAudioEngine:sharedEngine():stopAllEffects()

    require("TransScenePopUp")
    TransScenePopUp_closePage()
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(selfContainer, parentPage)

end

--[[ 當 頁面 離開 ]]
function Inst:onExit(selfContainer, parentPage)
    self.parentPage:removePacket(self.opcodes)
    GameUtil:setMainNodeVisible(true)
    GameUtil:purgeCachedData()
end


--[[ 當 單抽 按下 ]]
function Inst:onSummonBtn()
    self:summon1()
end

--[[ 當 十抽 按下 ]]
function Inst:onSummon10Btn()
    if self:isSummonAble(10) == false then return end
    self:summon10()
end
function Inst:onSkipAnim()
    if Inst.JumpAnim then
        Inst.JumpAnim=false

    else
        Inst.JumpAnim=true
    end
    CCUserDefault:sharedUserDefault():setBoolForKey("JumpSummonAnim", Inst.JumpAnim);
end

function Inst:onHand()
    self:onHandNode()
end

--[[ 當 跳過召喚按下 ]]
function Inst:onSummonSkipBtn ()
    if self.onSummonSkip_fn == nil then return end
    local temp = self.onSummonSkip_fn

    if self.isSkippable then
        temp()
        self.onSummonSkip_fn = nil
    end
end


-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 設置 抽取價格 ]]
function Inst:setSummonPrice (currency, options)
    if options == nil then options = {} end

    if currency == nil then return end

    self.summonCurrency = currency

    -- 價格 圖標
    local node2Sprite = {}
    local node2SpriteScale = {}

    local priceIcon = options["icon"]
    local priceIconScale = options["iconScale"]
    if priceIcon ~= nil then
        node2Sprite["summon1PriceImg"] = priceIcon
        node2Sprite["summonFreePriceImg"] = priceIcon
        
    end
    if priceIconScale ~= nil then
        node2SpriteScale["summon1PriceImg"] = priceIconScale
        node2SpriteScale["summonFreePriceImg"] = priceIconScale
    end

    local priceIcon10 = options["icon10"]
    if priceIcon10 ~= nil then
        node2Sprite["summon10PriceImg"] = priceIcon10
        node2SpriteScale["summon10PriceImg"] = priceIconScale
    end

    NodeHelper:setSpriteImage(self.container, node2Sprite, node2SpriteScale)

    -- 單抽價格
    local price1 = options["price1"]
    if price1 ~= nil then
        self.summonPrice1 = price1
    end

    -- 十抽價格
    local price10 = options["price10"]
    if price10 ~= nil then
        self.summonPrice10 = price10
    end

    -- 更新 價格相關
    self:updateSummonPrice()
end

--[[ 設置 抽取免費次數 ]]
function Inst:setSummonFree (quota)
    self.summonFreeQuota = quota
    if self.summonFreeQuota < 0 then
        self.summonFreeQuota = 0
    end
    
    -- 更新 價格相關
    self:updateSummonPrice()
end

--[[ 設置 免費補充時間 ]]
-- countdown: nil:關閉, <0:同步中, 0:可免費刷, >0:倒數時間
function Inst:setFreeCooldown (countdown)
    
    local isFreeCharged = countdown == 0
    local isFreeActive = countdown ~= nil
    if isFreeActive and not isFreeCharged then
        
        local countdownText
        if countdown < 0 then
            countdownText = common:getLanguageString("@syncing")
        else
            -- 剩餘時間 轉至 日期格式
            local leftTimeDate = TimeDateUtil:utcTime2Date(countdown)
            countdownText = string.format(common:getLanguageString("@Summon.nextFreeCounter"), leftTimeDate.hour, leftTimeDate.min, leftTimeDate.sec)
        end
        NodeHelper:setStringForTTFLabel(self.container, {
            summonFreeCounterTxt = countdownText,
        })
    end

end


--[[ 更新 抽取價格 相關 ]]
function Inst:updateSummonPrice ()
    local isFree = self.summonFreeQuota > 0

    -- 若 有免費
    if isFree then
        
        -- 免費次數 文字標示
        -- local freeText = common:getLanguageString("free #v1#/#v2#", self.summonFreeQuota, FREE_QUOTA_MAX)
        -- NodeHelper:setStringForTTFLabel(self.container, {
        --     summonFreeText = freeText
        -- })

    -- 若 無免費
    else
        -- 價格 文字標示
        local price1Str = string.format("%s", self.summonPrice1)
        NodeHelper:setStringForTTFLabel(self.container, {
            summon1PriceNum = price1Str,
        })
    end
    local price10Str = string.format("%s", self.summonPrice10)
    NodeHelper:setStringForTTFLabel(self.container, {
        summon10PriceNum = price10Str,
    })

    -- 依照是否有免費次數 切換 顯示
    NodeHelper:setNodesVisible(self.container, {
        summonFreeNode = isFree,
        summon1Node = not isFree,
    })

end

--[[ 更新 貨幣 ]]
function Inst:updateCurrency ()
    
    -- 更新 父頁面 貨幣資訊 並 取得該次結果
    local currencyDatas = self.parentPage:updateCurrency()
    
    local summonPriceUserHas = 0
    if #currencyDatas > 0 then
        summonPriceUserHas = currencyDatas[1].count
    end
    self:setSummonPrice(summonPriceUserHas)
end

--[[ 顯示 召喚狀態 ]]
function Inst:showUISummonState (isSummonState)
    if isSummonState == self.isUIOut then return end
    self.isUIOut = isSummonState

    -- 跳過面板 開啟
    self.container:getVarNode("skipNode"):setVisible(isSummonState)

    -- 退場
    if self.isUIOut then
        -- UI動畫 退場
        self.container:runAnimation("SummonOut")
        -- 分頁列UI 退場
        self.parentPage.tabStorage:anim_Out()
        NodeHelper:setNodesVisible(self.container,{mSkipAnimNode = false})

        self.container:runAction(
            CCSequence:createWithTwoActions(
                CCDelayTime:create(1),
                CCCallFunc:create(function()
                    NodeHelper:setNodesVisible(self.container, {mAvata = false})
                end)
            )
        )   


    -- 入場
    else
        -- UI動畫 入場
        self.container:runAnimation("SummonIn")
        -- 分頁列UI 入場
        self.parentPage.tabStorage:anim_In()
        NodeHelper:setNodesVisible(self.container,{mSkipAnimNode = true,mAvata = true})
    end
end

--[[ 送出 請求資訊 ]]
function Inst:sendRequestInfo (isShowLoading)

end

--[[ 送出 請求角色資訊 ]]
function Inst:sendRequestRoleInfos (isShowLoading)
    if isShowLoading == nil then isShowLoading = true end
    self.lastRole2Piece = nil
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, isShowLoading)
end

--[[ 處理 召喚錯誤 ]]
function Inst:handleSummonError (packet, hpCode)

    print("packet.opcode:"..tostring(packet.opcode))
    if packet.opcode ~= HP_pb.ERROR_CODE then return false end
    
    local msg = SysProtocol_pb.HPErrorCode()
    msg:ParseFromString(packet.msgBuff)
    
    print(string.format('msg.hpCode:"%s" type(%s)', tostring(msg.hpCode), type(msg.hpCode)))
    if msg.hpCode ~= hpCode then return false end

    -- 取用
    local onErr = self.onSummonFailed_fn
    self.onSummonFailed_fn = nil

    -- 若 錯誤
    dump(msg, "msg on err")
    print(string.format('msg.errCode:"%s" type(%s)', tostring(msg.errCode), type(msg.errCode)))
    if msg.errCode then
        if onErr ~= nil then
            print("onErr")
            onErr(msg)
        end
        return true
    end
    return false
end

--[[ 處理 回傳 ]]
function Inst:handleResponseInfo (msgInfo, onReceiveDone)
    
end

--[[ 處理獎勵 ]]
function Inst:handleRewards (itemStrs)
    local slf = self

    if itemStrs == nil then return end
    if #itemStrs == 0 then return end

    -- dump(itemStrs, "rewardStrs")
    
    -- 設置資料
    self.isSkippable = false

    local rewardDatas = {}
    for idx, itemStr in ipairs(itemStrs) do while true do
        local parsedItem = InfoAccesser:parseItemStr(itemStr)

        local rewardData = {}

        rewardData.id = parsedItem.id
        
        local curCount = 0
        
        local fullPieceCount = 0

        if parsedItem.type == Const_pb.SOUL then
            fullPieceCount = InfoAccesser:getHeroUnlockSoul(rewardData.id)
            
            rewardData.type = SummonDataMgr.RewardType.HERO

            local lastPieceCount = self.lastRole2Piece[parsedItem.id]
            if lastPieceCount ~= nil then
                curCount = lastPieceCount
            end

        elseif parsedItem.type == Const_pb.TOOL then
            fullPieceCount = SummonDataMgr.FULL_EQUIP_REWARD_PIECE_COUNT

            rewardData.type = InfoAccesser:getIsAncientWeaponSoul(itemStr) and SummonDataMgr.RewardType.AW_EQUIP or SummonDataMgr.RewardType.ITEM
            curCount = InfoAccesser:getUserItemCountByStr(itemStr)

        elseif parsedItem.type == Const_pb.EQUIP then
            rewardData.type = SummonDataMgr.RewardType.EQUIP
            curCount = InfoAccesser:getUserItemCountByStr(itemStr)
        elseif parsedItem.type == Const_pb.PLAYER_ATTR then
            rewardData.type = SummonDataMgr.RewardType.PLAYER_ATTR
            curCount = InfoAccesser:getUserItemCountByStr(itemStr)
        elseif parsedItem.type == Const_pb.BADGE then
            rewardData.type = SummonDataMgr.RewardType.RUNE
            curCount = InfoAccesser:getUserItemCountByStr(itemStr)
        end

        -- print("curCount:"..tostring(curCount))
        -- print("rewardPiece:"..tostring(parsedItem.count))

        if rewardData.type == SummonDataMgr.RewardType.HERO then
            local isFullExist = fullPieceCount <= curCount
            local isFullNext = fullPieceCount <= (curCount+parsedItem.count)

            if not isFullExist and isFullNext then
                rewardData.isNew = true
            else
                rewardData.isNew = false
            end
        elseif rewardData.type == SummonDataMgr.RewardType.AW_EQUIP then
            local isZeroCount = (curCount == 0)
            local isExitEquip = InfoAccesser:getExistAncientWeaponByPieceId(parsedItem.id)
            if isZeroCount and not isExitEquip then
                rewardData.isNew = true
            else
                rewardData.isNew = false
            end
        elseif rewardData.type == SummonDataMgr.RewardType.EQUIP then
            local isZeroCount = (curCount == 0)
            if isZeroCount then
                rewardData.isNew = true
            else
                rewardData.isNew = false
            end
        elseif rewardData.type == SummonDataMgr.RewardType.RUNE then
            local isZeroCount = (curCount == 0)
            if isZeroCount then
                rewardData.isNew = true
            else
                rewardData.isNew = false
            end
        else
            rewardData.isNew = false
        end
        
        if parsedItem.count ~= SummonDataMgr.FULL_REWARD_PIECE_COUNT then
            rewardData.piece = parsedItem.count
        else
            rewardData.piece = 0
        end


        rewardDatas[#rewardDatas+1] = rewardData
    break end end

    -- 重新要求角色資料
    self:sendRequestRoleInfos()
    

    -- 若 為

    -- 復原轉場
    local spineBackToIdle = function ()
        if self.spineSummon ~= nil then
            self.spineSummon:setToSetupPose()
            self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_summon_idle, -1)
        end
        if self.spineBG ~= nil then
            self.spineBG:setToSetupPose()
            self.spineBG:runAnimation(1, self.subPageCfg.spineAnimName_bg_idle, -1)
        end
          --NodeHelper:setNodesVisible(self.container,{mAvata=true})
          SoundManager:getInstance():playMusic("summon_page_bgm.mp3")
    end

    local summonBackToIdle = function ()
        print("summonBackToIdle")
        -- 復原轉場
        spineBackToIdle()
        -- UI返場 
        slf:showUISummonState(false)
    end

    Async:waterfall({
        -- 進入 召喚結算頁面
        function (nxt)
            -- 召喚結算獲得
            local prepareData = {
                isShowManual = true,
                summonTimes = #rewardDatas,
                rewards = rewardDatas,
            }
            if prepareData.summonTimes == 10 then
                prepareData.resummonPriceStr = slf.summon10PriceStr
            else
                prepareData.resummonPriceStr = slf.summonPriceStr
            end

            SummonResultPage:setEndLoadCallback(function() 
                self.isSkippable = true 
            end)
            
            SummonResultPage:prepare(prepareData)
            

            local summonTimes = #rewardDatas

            SummonResultPage.onResummon_fn = function ()
                if slf:isSummonAble(summonTimes) == false then return end

                slf.onSummonFailed_fn = function ()
                    summonBackToIdle()
                end

                SummonResultPage.onExit_fn = function ()
                    spineBackToIdle()
                    if summonTimes == 1 then
                        slf:summon1()
                    else
                        slf:summon10()
                    end
                end
                SummonResultPage:close()
            end
            
            SummonResultPage.onEnter_fn = nxt
            PageManager.pushPage("Summon.SummonResultPage")
        end,
        -- 預載 獎品
        function (nxt)
            SummonResultPage:preloadRewards()
            nxt()
        end,
        -- 召喚 動畫
        function (nxt)
            slf.container:stopAllActions()
            local array = CCArray:create()
            if Inst.JumpAnim then
                array:addObject(CCDelayTime:create(1 / 60))
                array:addObject(CCCallFunc:create(function() 
                      if self.subPageCfg.summonBgm then
                          SoundManager:getInstance():playMusic(self.subPageCfg.summonBgm, false)
                      end
                end ))
                self:showUISummonState(true) 
                array:addObject(CCDelayTime:create(1.3))
                array:addObject(CCCallFunc:create(function() nxt() end ))
            else
            array:addObject(CCDelayTime:create(1 / 60))
            array:addObject(CCCallFunc:create(function()
                        -- 播放 召喚動畫
                        self:playSummonSpine(rewardDatas)
                        -- 播放 抽卡演出音樂
                        if self.subPageCfg.summonBgm then
                            SoundManager:getInstance():playMusic(self.subPageCfg.summonBgm, false)
                        end
                        -- 召喚時UI退場
                        self:showUISummonState(true)       
                        
                        local isCalled = false
                        local nxt_once = function ()
                            if isCalled then return end
                            isCalled = true
                            nxt()
                        end
                        -- 動畫結束 或 跳過 時 擇一
                        self.onSummonSkip_fn = nxt_once
                        self.onSummonAnimDone_fn = nxt_once
                 end))
                end
            slf.container:runAction(CCSequence:create(array))
        end,
        function (nxt)
            -- 關閉抽卡音樂
            SoundManager:getInstance():stopMusic()
            -- 顯示 召喚結算頁面
            SummonResultPage:show()
            -- 當離開頁面時下一步
            SummonResultPage.onExit_fn = nxt
            -- 播放所有
            SummonResultPage:playAll()
        end,

        function (nxt)
            summonBackToIdle()
        end,
    })
    
end

--[[ 載入 召喚Spine ]]
function Inst:loadSummonSpine ()

end


--[[ 播放 召喚Spine ]]
function Inst:playSummonSpine (rewardDatas)

end

--[[ 是否可以召喚 ]]
function Inst:isSummonAble (summonTimes)
    if self.lastRole2Piece == nil then return false end

    -- 若不管數量夠不夠都回傳可以
    if true then return true end

    if summonTimes == 1 then
        
        local summonPrice_parsedItem = InfoAccesser:parseItemStr(self.summonPriceStr)
        if summonPrice_parsedItem == nil then return false end

        if self.summonFreeQuota <= 0 then
            
            local playerHasCount = InfoAccesser:getUserItemCount(summonPrice_parsedItem.type, summonPrice_parsedItem.id)
            
            dump(summonPrice_parsedItem, "summonPrice_parsedItem")
            print("playerHasCount "..tostring(playerHasCount))
            if playerHasCount < summonPrice_parsedItem.count then 
                return false
            end
        end
    elseif summonTimes == 10 then
        
        local summon10Price_parsedItem = InfoAccesser:parseItemStr(self.summon10PriceStr)
        if summon10Price_parsedItem == nil then return false end
        
        local playerHasCount = InfoAccesser:getUserItemCount(summon10Price_parsedItem.type, summon10Price_parsedItem.id)
        if playerHasCount < summon10Price_parsedItem.count then 
            return false
        end
    else
        return false
    end

    return true
end

--[[ 單抽 ]]
function Inst:summon1 () 
    if self:isSummonAble(1) == false then return end
    self:sendSummon1()
end

--[[ 十抽 ]]
function Inst:summon10 () 
    if self:isSummonAble(10) == false then return end
    self:sendSummon10()
end


--[[ 送出 單抽 ]]
function Inst:sendSummon1 ()
   
end

--[[ 送出 十抽 ]]
function Inst:sendSummon10 ()
   
end
--[[點擊spine]]
function Inst:onHandNode()
    
end
return Inst