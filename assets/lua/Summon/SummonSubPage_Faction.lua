
--[[ 
    name: SummonSubPage_Faction
    desc: 召喚 子頁面 種族(派系)
    author: youzi
    update: 2023/10/25 16:28
    description: 
--]]


local HP_pb = require("HP_pb") -- 包含协议id文件
local Activity5_pb = require("Activity5_pb")

local NodeHelper = require("NodeHelper")
local Async = require("Util.Async")
local InfoAccesser = require("Util.InfoAccesser")
local PathAccesser = require("Util.PathAccesser")

local SummonDataMgr = require("Summon.SummonDataMgr")
local SummonResultPage = require("Summon.SummonResultPage")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local SummonSubPage_Base

--[[ 測試資料模式 ]]
local IS_MOCK = false

--[[ 事件 對應 函式 ]]
local HANDLER_MAP = {
    onShopBtn = "onShopBtn",
    onMilestoneBtn = "onMilestoneBtn",
    onSummonSkipBtn = "onSummonSkipBtn",
    onMilestoneSummonBtn = "onMilestoneSummonBtn",
    onMilestoneCloseBtn = "onMilestoneCloseBtn",
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
    
    -- 頁面

    var 
        currentFactionImg 當前選取派系圖片
        milestoneTxt 主頁里程碑進度文字

        summonBtn_{1~2} 召喚按鈕1~2
        summonPriceNum_{1~2} 召喚價格1~2
        summonPriceImg_{1~2} 召喚價格圖片1~2

    event
        onFactionSelectBtn_{1~4} 當選擇派系
        onShopBtn 當點擊 商店
        onSummonBtn_{1~2} 當點擊 召喚按紐1~2
        onMilestoneBtn 當點擊 里程碑

    -- 里程碑彈窗

    var
        milestonePopupNode 彈窗 節點
        milestoneTxt_popup 彈窗 里程碑進度文字
        milestoneSummonBtn 里程碑召喚按紐

        milestoneOpt_{1~4}_bg_selected
        milestoneOpt_{1~4}_sign_selected

    event
        onMilestoneSummonBtn 當點擊 里程碑召喚
        onMilestoneCloseBtn 當點擊 里程碑離開
        onMilestoneOptSelect_{1~4} 當點擊 派系選項
    
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
Inst.opcodes["ACTIVITY158_S"] = HP_pb.ACTIVITY158_S
Inst.opcodes["ROLE_PANEL_INFOS_S"] = HP_pb.ROLE_PANEL_INFOS_S
Inst.opcodes["ERROR_CODE"] = HP_pb.ERROR_CODE

--[[ 當前選擇派系 ]]
Inst.currentFaction = 0

--[[ 當前選擇派系 ]]
Inst.currentMilestoneFaction = 0

--[[ 當前里程碑 ]]
Inst.milestonePoint = 0

--[[ 當前召喚種類 ]]
Inst.currentSummonType = nil

--[[ UI是否退場 ]]
Inst.isUIOut = false

--[[ 是否可以跳過 ]]
Inst.isSkippable = true

--[[ 當 召喚動畫 結束 ]]
Inst.onSummonAnimDone_fn = nil
--[[ 當 跳過召喚 ]]
Inst.onSummonSkip_fn = nil

--[[ 當前角色碎片列表 ]]
Inst.lastRole2Piece = nil

--[[ Spine ]]
Inst.spineBG = nil
Inst.spineBGNode = nil
Inst.spineSummon = nil
Inst.spineSummonNode = nil

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--[[ 當 收到封包 ]]
function Inst:onReceivePacket(packet)

    if self:handleSummonError(packet, HP_pb.ACTIVITY158_C) == true then return end
    
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

    if packet.opcode == HP_pb.ACTIVITY158_S then

        if packet.msg == nil then
            local msg = Activity5_pb.CallOfRaceRes()
            msg:ParseFromString(packet.msgBuff)
            packet.msg = msg
        end

        self:handleResponseInfo(packet.msg)
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
    local slf = self
    SummonSubPage_Base=require("Summon.SummonSubPage_Base"):new()
    -- 註冊 呼叫行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName
        -- 選擇種族
        if string.sub(eventName, 1, 19) == "onFactionSelectBtn_" then
            slf:onFactionSelect(tonumber(string.sub(eventName, 20)))
        -- 不同類型的召喚
        elseif string.sub(eventName, 1, 12) == "onSummonBtn_" then
            slf:onSummonBtn(tonumber(string.sub(eventName, 13)))
        -- 選擇 兌換里程碑 的 種族
        elseif string.sub(eventName, 1, 21) == "onMilestoneOptSelect_" then
            slf:onMilestoneOptSelect(tonumber(string.sub(eventName, 22)))

        -- 其他函式
        else
            funcName = HANDLER_MAP[eventName]
        end

        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)

    -- 註冊 協定
    self.parentPage:registerPacket(self.opcodes)

    -- 設置 Spine動畫
    if self.subPageCfg.spineBG ~= nil then

        local spineFolderAndName = common:split(self.subPageCfg.spineBG, ",")
        self.spineBG = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
        self.spineBG:registerFunctionHandler("SELF_EVENT", function(unknownArg, tag, eventName)
            if eventName == "end" then
                if slf.onSummonAnimDone_fn ~= nil then 
                    local temp = slf.onSummonAnimDone_fn
                    slf.onSummonAnimDone_fn = nil
                    temp()
                end
            end
        end)
       local spineBGNode = tolua.cast(self.spineBG, "CCNode") 
     NodeHelperUZ:fitBGSpine(spineBGNode, {
         -- 目標中心點
         pivot = ccp(0.5, 0),
     })
        self.spineBG:setToSetupPose()
         self.spineBG:runAnimation(1, self.subPageCfg.spineAnimName_idle, 0)
        
        self.container:getVarNode("spineBGNode"):addChild(spineBGNode)
    end

    -- 設置 Spine動畫
    if self.subPageCfg.spineSummon ~= nil then

        local spineFolderAndName = common:split(self.subPageCfg.spineSummon, ",")
        self.spineSummon = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
        self.spineSummon:registerFunctionHandler("SELF_EVENT", function(unknownArg, tag, eventName)
            if eventName == "end" then
                if slf.onSummonAnimDone_fn ~= nil then 
                    local temp = slf.onSummonAnimDone_fn
                    slf.onSummonAnimDone_fn = nil
                    temp()
                end
            end
        end)
        local spineSummonNode = tolua.cast(self.spineSummon, "CCNode")
        NodeHelperUZ:fitBGSpine(spineSummonNode, {
            -- 目標中心點
            pivot = ccp(0.5, 0),
        })
        local FactionNode=self.container:getVarNode("currentFactionImg")
        FactionNode:setScale(NodeHelper:getScaleProportion())
        self.spineSummon:setToSetupPose()
        self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_idle, -1)
        
        self.container:getVarNode("spineSummonNode"):addChild(spineSummonNode)
    end
    self:showMilestonePopup(false)

    -- 預設選擇 首位
    self:selectFaction(1, false, false)
    self:selectMilestoneOpt(1, false)

    self:updateFactionAbout()

    -------------------
    self:sendRequestRoleInfos(true)

    -- 請求初始資訊
    self:sendRequestInfo(true)

    self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_select, 0)
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute(selfContainer, parentPage)
    if SummonSubPage_Base.JumpAnim then
        NodeHelper:setSpriteImage(self.container,{mSwitch="common_switch1_on.png"})
    else
        NodeHelper:setSpriteImage(self.container,{mSwitch="common_switch1.png"})
    end
end

--[[ 當 頁面 離開 ]]
function Inst:onExit(selfContainer, parentPage)
    self.parentPage:removePacket(self.opcodes)
end

--[[  ]]
function Inst:onShopBtn ()
    local shopCtrlPage = require("ShopControlPage")
    shopCtrlPage:prepareStartPage(require("Shop.ShopDataMgr").ShopType.RACE)
    PageManager.pushPage("ShopControlPage")
end

--[[ 當 選擇 種族 ]]
function Inst:onFactionSelect (idx)
    self:selectFaction(idx)
    self:updateFactionAbout()
end

--[[ 當 召喚 按下 ]]
function Inst:onSummonBtn(idx)
    local summonType = idx
    if self:isSummonAble(summonType) == false then return end
    self:summon(summonType)
end

--[[ 當 跳過召喚按下 ]]
function Inst:onSummonSkipBtn ()
    if self.onSummonSkip_fn == nil then return end
    local temp = self.onSummonSkip_fn
    self.onSummonSkip_fn = nil

    if self.isSkippable then
        temp()
    end
end

--[[ 當 里程碑 被按下 ]]
function Inst:onMilestoneBtn ()
    self:showMilestonePopup(true)
end

--[[ 當 彈窗中 里程碑選項 選擇 ]]
function Inst:onMilestoneOptSelect (opt)
    self:selectMilestoneOpt(opt)
    self:updateFactionAbout()
end

--[[ 當 彈窗中 里程碑 召喚 ]]
function Inst:onMilestoneSummonBtn ()
    self:milestoneSummon()
end

--[[ 當 彈窗中 里程碑 關閉 ]]
function Inst:onMilestoneCloseBtn ()
    self:showMilestonePopup(false)
end
function Inst:onSkipAnim()  
    SummonSubPage_Base:onSkipAnim()
end


-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  


--[[ 開啟 里程碑視窗 ]]
function Inst:showMilestonePopup (isShow)
    self.container:getVarNode("milestonePopupNode"):setVisible(isShow)
end

--[[ 選取 種族(派系) ]]
function Inst:selectFaction (idx, isPlayAnim, isUpdate)
    if isPlayAnim == nil then isPlayAnim = true end

    local faction = idx
    local attr = faction

    -- 光/暗 種族 特殊處理
    if idx == 4 then

        -- 光暗一半一半顯示
        attr = 7
        
        -- if self.currentFaction == 4 then 
        --     faction = 5
        --     attr = 5
        -- elseif self.currentFaction == 5 then 
        --     faction = 4
        --     attr = 4
        -- end
    end


    if faction == self.currentFaction then return end

    if isPlayAnim == true then
        self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_select, 0)
    end

    self.currentFaction = faction

    NodeHelper:setSpriteImage(self.container, {
        ["currentFactionImg"] = PathAccesser:getFactionImgPath(attr)
    })
    if isUpdate then
        self:updateFactionAbout()
    end
end

--[[ 設置 里程碑 ]]
function Inst:setMilestone (point)
    self.milestonePoint = point
    self:updateFactionAbout()
end

--[[ 選取 里程碑派系 ]]
function Inst:selectMilestoneOpt (opt, isUpdate)

    local visibleMap = {}

    -- 預設 種族(派系)為 選項
    local faction = opt

    -- 選項4(光/暗) 的圖片
    local opt4Sprite = PathAccesser:getFactionImgPath(7)
    
    -- -- 若 選項 為 光/暗
    -- if opt == 4 then
    --     -- 若 當前 派系 為 光 則 跳為 暗
    --     if self.currentMilestoneFaction == 4 then
    --         faction = 5
    --     -- 若 當前 派系 為 暗 則 跳為 光
    --     elseif self.currentMilestoneFaction == 5 then
    --         faction = 4
    --     end
    --     -- 光或暗的圖片
    --     opt4Sprite = PathAccesser:getFactionImgPath(faction)
    -- else
    --     -- 光/暗 一半一半 的圖片
    --     opt4Sprite = PathAccesser:getFactionImgPath(7)
    -- end

    -- 若沒有改變 則 返回
    if faction == self.currentMilestoneFaction then return end

    -- 單獨設置 光/暗
    -- NodeHelper:setSpriteImage(self.container, {
    --     ["milestoneOpt_4_img"] = opt4Sprite
    -- })

    -- 改變當前派系
    self.currentMilestoneFaction = faction
    
    -- 每個派系選項 設置是否選擇中
    for idx = 1, 4 do
        local isSelected = idx == opt
        visibleMap[string.format("milestoneOpt_%d_bg_selected", idx)] = isSelected
        visibleMap[string.format("milestoneOpt_%d_sign_selected", idx)] = isSelected
    end

    NodeHelper:setNodesVisible(self.container, visibleMap)

    if isUpdate then
        self:updateFactionAbout()
    end
end

--[[ 更新 種族(派系) 相關 ]]
function Inst:updateFactionAbout ()

    local imgMap = {}
    local strMap = {}
    local imgScaleMap = {}
    
    -- 里程碑
    strMap["milestoneTxt_popup"] = string.format("%d/%d", self.milestonePoint, self.subPageCfg.faction2Milestone[self.currentMilestoneFaction])
    strMap["milestoneTxt"] = string.format("%d/%d", self.milestonePoint, self.subPageCfg.faction2Milestone[self.currentFaction])

    -- 里程碑 彈窗 派系選項
    for idx = 1, 4 do
        local faction = idx

        -- 光/暗 特別處理
        -- if idx == 4 then
        --     if self.currentMilestoneFaction == 4 then
        --         faction = 4
        --     else
        --         faction = 5
        --     end
        -- end

        strMap[string.format("milestoneOpt_%d_price", idx)] = tostring(self.subPageCfg.faction2Milestone[faction])
    end
   
    -- 價格
    local priceDatas = self.subPageCfg.faction2PriceDatas[self.currentFaction]
    for idx, val in ipairs(priceDatas) do
        local idxStr = tostring(idx)
        local itemInfo = InfoAccesser:getItemInfoByStr(val)
        local itemIconCfg = InfoAccesser:getItemIconCfg(itemInfo.type, itemInfo.id, "SummonPrice")
        imgMap["summonPriceImg_"..idxStr] = string.format("%s", itemInfo.icon)
        imgScaleMap["summonPriceImg_"..idxStr] = itemIconCfg.scale
        strMap["summonPriceNum_"..idxStr] = string.format("%s", itemInfo.count)
    end

    dump(imgScaleMap, "imgScaleMap")
    NodeHelper:setSpriteImage(self.container, imgMap, imgScaleMap)
    NodeHelper:setStringForTTFLabel(self.container, strMap)
end

--[[ 更新 貨幣 ]]
function Inst:updateCurrency ()
    -- 更新 父頁面 貨幣資訊 並 取得該次結果
    self.parentPage:updateCurrency()
end

--[[ 顯示 召喚狀態 ]]
function Inst:showUISummonState (isSummonState)
    if isSummonState == self.isUIOut then return end
    self.isUIOut = isSummonState

    -- 跳過面板 開啟
    self.container:getVarNode("summonSkipNode"):setVisible(isSummonState)

    -- 退場
    if self.isUIOut then
        -- UI動畫 退場
        self.container:runAnimation("SummonOut")
        -- 分頁列UI 退場
        self.parentPage.tabStorage:anim_Out()

    -- 入場
    else
        -- UI動畫 入場
        self.container:runAnimation("SummonIn")
        -- 分頁列UI 入場
        self.parentPage.tabStorage:anim_In()
    end
end

--[[ 是否可以召喚 ]]
function Inst:isSummonAble (summonType)
    if self.lastRole2Piece == nil then return false end

    -- 若不管數量夠不夠都回傳可以
    if true then return true end

    local priceDatas = self.subPageCfg.faction2PriceDatas[self.currentFaction]

    local priceStr = priceDatas[summonType]
        
    local parsedItem = InfoAccesser:parseItemStr(priceStr)
    if parsedItem == nil then return false end

    local playerHasCount = InfoAccesser:getUserItemCount(parsedItem.type, parsedItem.id)
    
    if playerHasCount < parsedItem.count then 
        return false
    end
     
    return true
end

--[[ 送出 請求資訊 ]]
function Inst:sendRequestInfo (isShowLoading)
    local msg = Activity5_pb.CallOfRaceReq()
    msg.action = 0
    msg.race = 1 -- 表示送預設值, 無實際選擇種族用途
    common:sendPacket(HP_pb.ACTIVITY158_C, msg, isShowLoading)
end

--[[ 送出 請求角色資訊 ]]
function Inst:sendRequestRoleInfos (isShowLoading)
    if isShowLoading == nil then isShowLoading = true end
    self.lastRole2Piece = nil
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, isShowLoading)
end

--[[ 處理 召喚錯誤 ]]
function Inst:handleSummonError (packet, hpCode)
    
    if packet.opcode ~= HP_pb.ERROR_CODE then return false end

    local msg = SysProtocol_pb.HPErrorCode()
    msg:ParseFromString(packet.msgBuff)

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
    local slf = self

    local isPriceDataExist = false
    local priceDatas = {}

    -- dump(msgInfo, "msgInfo")
    -- print(string.format("msgInfo.action : %s", tostring(msgInfo.action)))
    -- print(string.format("msgInfo.point : %s", tostring(msgInfo.point)))
    -- print(string.format("msgInfo.race : %s", tostring(msgInfo.race)))
    -- print(string.format("msgInfo.reward : %s", tostring(msgInfo.reward)))

    -- 設置 里程碑
    self:setMilestone(msgInfo.point)

    -- 更新 玩家持有貨幣資訊
    self:updateCurrency()
    --設定visible
    if msgInfo.action== 3 then
        self.container:getVarNode("milestonePopupNode"):setVisible(false)
    end
    -- 若有收到獎勵
    if msgInfo.reward ~= nil and msgInfo.reward ~= "" then
        local itemStrs = common:split(msgInfo.reward, ",")
        self:handleRewards(itemStrs, msgInfo.action == 3)
    end

    self:updateFactionAbout()
end

--[[ 處理獎勵 ]]
function Inst:handleRewards (itemStrs, isMilestoneSummon)
    local slf = self

    if itemStrs == nil then return end
    if #itemStrs == 0 then return end

    -- 設置資料

    local rewardDatas = {}
    for idx, itemStr in ipairs(itemStrs) do while true do
        local parsedItem = InfoAccesser:parseItemStr(itemStr)

        local rewardData = {}

        rewardData.id = parsedItem.id
        
        local curCount = 0
        
        local fullPieceCount = 0

        -- 特殊轉換
        if parsedItem.type == Const_pb.TOOL then
            -- 若為角色升階道具 
            if parsedItem.id < 100 then
                -- 則比照 碎片處理
                parsedItem.type = Const_pb.SOUL
            end
        end

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


        local isFullExist = fullPieceCount <= curCount
        local isFullNext = fullPieceCount <= (curCount+parsedItem.count)

        if not isFullExist and isFullNext then
            rewardData.isNew = true
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
            -- self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_idle, -1)
            self.spineSummon:stopAllAnimations()
        end
        if self.spineBG ~= nil then
            self.spineBG:setToSetupPose()
            -- self.spineBG:runAnimation(1, self.subPageCfg.spineAnimName_idle, -1)
            self.spineBG:stopAllAnimations()
        end
        self.spineSummon:runAnimation(1, self.subPageCfg.spineAnimName_select, 0)
    end

    local summonBackToIdle = function ()
        -- 復原轉場
        spineBackToIdle()
        -- UI返場 
        slf:showUISummonState(false)
    end

    local summonType = self.currentSummonType
    local resummonPriceStr = nil
    if isMilestoneSummon then
        --local price = self.subPageCfg.faction2Milestone[self.currentMilestoneFaction]
        resummonPriceStr = "isMilestoneSummon"
    else
        resummonPriceStr = self.subPageCfg.faction2PriceDatas[self.currentFaction][self.currentSummonType]
    end

    Async:waterfall({
        -- 進入 召喚結算頁面
        function (nxt)
            -- 召喚結算獲得
            local prepareData = {
                isShowManual = true,
                summonTimes = #rewardDatas,
                rewards = rewardDatas,
                resummonPriceStr = resummonPriceStr,
                mileStone=string.format("%d/%d", self.milestonePoint, self.subPageCfg.faction2Milestone[self.currentFaction]),
                isFaction=true
            }
            SummonResultPage:prepare(prepareData)
            

            SummonResultPage.onResummon_fn = function ()
                if slf:isSummonAble(summonType) == false then return end
                
                slf.onSummonFailed_fn = function ()
                    summonBackToIdle()
                end

                SummonResultPage.onExit_fn = function ()
                    spineBackToIdle()
                    slf:summon(summonType)
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
            local array = CCArray:create()
            if SummonSubPage_Base.JumpAnim then
                array:addObject(CCDelayTime:create(1 / 60))
                slf:showUISummonState(true)
                array:addObject(CCDelayTime:create(1))
                array:addObject(CCCallFunc:create(function() nxt() end ))
                self.container:runAction(CCSequence:create(array))
            else
                -- 播放 抽卡演出音樂
                if self.subPageCfg.summonBgm then
                    SoundManager:getInstance():playMusic(self.subPageCfg.summonBgm, false)
                end

                local spineAnim_summon = self.subPageCfg.spineAnimName_summon
                if slf.spineSummon ~= nil then
                    slf.spineSummon:setToSetupPose()
                    slf.spineSummon:runAnimation(1, "summon_start", 0)
                    slf.spineSummon:addAnimation(1, spineAnim_summon, false)
                end
                if slf.spineBG ~= nil then
                    slf.spineBG:setToSetupPose()
                    slf.spineBG:runAnimation(1, spineAnim_summon, 0)
                end
                -- 召喚時UI退場
                slf:showUISummonState(true)

                local isCalled = false
                local nxt_once = function ()
                    if isCalled then return end
                    isCalled = true
                    nxt()
                end
                
                -- 動畫結束 或 跳過 時 擇一
                slf.onSummonSkip_fn = nxt_once
                slf.onSummonAnimDone_fn = nxt_once
            end
        end,

        function (nxt)
            
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


--[[ 抽x次 ]]
function Inst:summon (summonType)
    local priceDatas = self.subPageCfg.faction2PriceDatas[self.currentFaction]
    self.currentSummonType = summonType
    local msg = Activity5_pb.CallOfRaceReq()
    msg.action = self.subPageCfg.summonType2Action[summonType]
    msg.race = self.currentFaction
    common:sendPacket(HP_pb.ACTIVITY158_C, msg, true)
end

--[[ 里程碑 抽 ]]
function Inst:milestoneSummon ()
    -- 檢查
    local needs = self.subPageCfg.faction2Milestone[self.currentMilestoneFaction]
    if self.milestonePoint < needs then
         MessageBoxPage:Msg_Box(common:getLanguageString("@NotEnoughDuanZaoStone"))
        return 
    end

    local msg = Activity5_pb.CallOfRaceReq()
    msg.action = 3
    msg.race = self.currentMilestoneFaction
    common:sendPacket(HP_pb.ACTIVITY158_C, msg, true)
end


return Inst