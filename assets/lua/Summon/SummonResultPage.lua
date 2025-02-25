
--[[ 
    name: SummonResultPage
    desc: 召喚結算 頁面
    author: youzi
    update: 2023/10/3 17:42
    description: 
        
--]]

--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
-- __lang_loaded = __lang_loaded or {}
-- if not __lang_loaded["Lang/Summon.lang"] then
--    __lang_loaded["Lang/Summon.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/Summon.lang")
-- end

local HIGHLIGHT_CTRL_TAG = 10000
local REWARDITEM_TAG = 8000

-- 引用 --------------------

local HP_pb = require("HP_pb") -- 包含协议id文件

local Async = require("Util.Async")
local Invoker = require("Util.Invoker")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local PathAccesser = require("Util.PathAccesser")
local InfoAccesser = require("Util.InfoAccesser")
local NodeSyncTasker = require("Util.NodeSyncTasker")
local ALFManager = require("Util.AsyncLoadFileManager")
local ObjPool = require("Util.ObjPool")
--local SummonSubPage_Base= require("Summon.SummonSubPage_Base")

local SummonDataMgr = require("Summon.SummonDataMgr")
local SummonResultItem = require("Summon.SummonResultItem")
local SummonSubPage_Base
----------------------------

--[[ 
    text
    
    var 
        rewardsNode10 10抽所有獎品容器的容器
        rewardNode{1~10} 各個獎品容器

        rewardsNode1 單抽獎品容器的容器
        rewardNodeOne 單個獎品容器

        resummonNode 重新召喚 容器
        resummonBtn 重新召喚 按鈕
        resummonTxt 重新召喚 文字
        resummonPriceNode 重新召喚價格容器
        resummonPriceImg 重新召喚價格圖片
        resummonPriceNum 重新召喚價格數字

        skipNode 跳過 容器
        skipBtn 跳過 按鈕

        confirmNode 確認 容器
        confirmBtn 確認 按鈕

        highlightNode 特寫展示 容器
        highlightDrawNode 特寫展示 立繪容器
        highlightDrawImg 特寫展示 立繪參考Sprite
        highlightChibiNode 特寫展示 小人容器
        highlightChibiImg 特寫展示 小人參考Sprite
        highlightNameTxt 特寫展示 名稱文字
        highlightElementImg 特寫展示 屬性圖片
        highlightQualityImg 特寫展示 品質圖片
        highlightStarImg1 特寫展示 星數圖片1

    event
        onResummon 當重抽按下
        onSkip 當跳過按下
        onConfirm 當確認按下

        onHighlightTouch 當特寫展示按下
        onHighlightSkipTouch 當特寫展示跳過按下


--]]

--[[ 腳本主體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 特殊處理 獎品項目物件池
-- 與本頁面生命週期脫鉤, 需自行選擇釋放時機
local StaticRewardItemPool = nil
function Inst:releaseStaticRewardItemPool ()
    if StaticRewardItemPool == nil then return end
    StaticRewardItemPool:clear()
    StaticRewardItemPool = nil
end

--  ######  ######## ######## ######## #### ##    ##  ######   
-- ##    ## ##          ##       ##     ##  ###   ## ##    ##  
-- ##       ##          ##       ##     ##  ####  ## ##        
--  ######  ######      ##       ##     ##  ## ## ## ##   #### 
--       ## ##          ##       ##     ##  ##  #### ##    ##  
-- ##    ## ##          ##       ##     ##  ##   ### ##    ##  
--  ######  ########    ##       ##    #### ##    ##  ######   

--[[ 頁面名稱 ]]
Inst.pageName = "Summon.SummonResultPage"

--[[ UI檔案 ]]
Inst.ccbiFile = "SummonResult.ccbi"

--[[ 事件 對應 函式 ]]
Inst.handlerMap = {
    onResummon = "onResummonClick",
    onSkip = "onSkipClick",
    onConfirm = "onConfirmClick",
    onHighlightTouch = "onHighlightTouch",
    onHighlightSkipTouch = "onHighlightSkipTouch",
}

--[[ 協定 ]]
Inst.opcodes = {}

-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

--[[ 容器 ]]
Inst.container = nil

--[[ 背景Spine ]]
Inst.bgSpine = nil

--[[ 是否手動顯示 ]]
Inst.isShowManual = nil

--[[ 獎勵資料 ]]
Inst.rewards = nil

--[[ 里程資料 ]]
Inst.MileStonePoint = nil

--[[ 是否為種族 ]]
Inst.isFaction = false

--[[ 獎勵項目容器 ]]
Inst.rewardNodes = nil

--[[ 獎勵項目 物件池 ]]
Inst.resultItemPool = nil

--[[ 召喚次數 ]]
Inst.summonTimes = 1

--[[ 特寫展示 當動畫完畢 ]]
Inst.highlightAnimDone_callback = nil
Inst.highlightAnimDone_callback_id = nil
--[[ 特寫展示 下一步 ]]
Inst.highlightNext_callback = nil

--[[ 當 所有特寫展示完畢 ]]
Inst._onAllHighlightDone_fn = nil

--[[ 是否已預載獎品 ]]
Inst.isPreloadRewards = false

--[[ 當進入 ]]
Inst.onEnter_fn = nil

--[[ 當重新召喚 ]]
Inst.onResummon_fn = nil

--[[ 當關閉 ]]
Inst.onExit_fn = nil

--[[ 透明度同步 ]]
Inst.opacitySyncTasker = nil

--[[ SSR演出用spine ]]
Inst.highlightSpine = nil

--[[ SSR演出文字spine ]]
Inst.raritySpine = nil

--[[ 載入任務 ]]
Inst.asyncLoadTasks = { }

--[[ 載入完成時callback ]]
Inst.endLoadingCallback = nil

Inst.isPlayed=false

-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--  ######                                    
--  #     #   ##    ####  #    # ###### ##### 
--  #     #  #  #  #    # #   #  #        #   
--  ######  #    # #      ####   #####    #   
--  #       ###### #      #  #   #        #   
--  #       #    # #    # #   #  #        #   
--  #       #    #  ####  #    # ######   #   
--                                            

--[[ 當 收到訊息 ]]
function Inst:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
end

--[[ 當 收到封包 ]]
function Inst:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    
end

--[[ 註冊 訊息相關 ]]
function Inst:registerMessage(msgID)
    self.container:registerMessage(msgID)
end

--[[ 註冊 封包相關 ]]
function Inst:registerPacket(opcodes)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            self.container:registerPacket(opcode)
        end
    end
end

--[[ 註銷 封包相關 ]]
function Inst:removePacket(opcodes)
    for key, opcode in pairs(opcodes) do
        self.container:removePacket(opcode)
    end
end

--  ######                       
--  #     #   ##    ####  ###### 
--  #     #  #  #  #    # #      
--  ######  #    # #      #####  
--  #       ###### #  ### #      
--  #       #    # #    # #      
--  #       #    #  ####  ###### 
--                               

--[[ 當 頁面 進入 ]]
function Inst:onEnter (container)
    local slf = self

    self.container = container

    self.container:setVisible(not self.isShowManual)
    NodeHelper:setNodeScale(self.container, "mBg", NodeHelper:getScaleProportion(), NodeHelper:getScaleProportion())
    NodeHelper:setNodeScale(self.container, "mBg2", NodeHelper:getScaleProportion(), NodeHelper:getScaleProportion())
    SummonSubPage_Base=require("Summon.SummonSubPage_Base"):new()


    local fn = function()
        -- 建立背景
        self.bgSpine = SpineContainer:create("Spine/NGUI", "NGUI_2_HeroSummonResult")
        self.bgSpine.node = tolua.cast(self.bgSpine, "CCNode")
        NodeHelperUZ:fitBGSpine(self.bgSpine.node)
        self.container:getVarNode("bgSpineNode"):addChild(self.bgSpine.node)
        self.bgSpine:runAnimation(1, "animation", -1)
    end
    local task = ALFManager:loadSpineTask("Spine/NGUI/", "NGUI_2_HeroSummonResult", 30, fn)
    table.insert(self.asyncLoadTasks, task)

    -- 項目物件池
    if StaticRewardItemPool == nil then
        StaticRewardItemPool = ObjPool:new():init({
            count = 10,
            onCreate = function (data)
                local item = SummonResultItem:new()
                local container = item:requestUI()
                container:retain()
                return item
            end,
            onInit = function (obj, data)
    
            end,
            onUnInit = function (obj)
                local container = obj:requestUI()
                container:setVisible(false)
                container:getParent():removeChild(container, true)
            end,
            onDestroy = function (obj)
                obj:requestUI():release()
            end,
        })
    end
    self.resultItemPool = StaticRewardItemPool
    
    -- 透明度同步器
    self.opacitySyncTasker = NodeSyncTasker:new()
    self.opacitySyncTasker:setSyncFn(function(task)
        if task.src == nil or task.src.getOpacity == nil then
            dump(task.tags, "error task src")
        end
        task.dst:setOpacity(task.src:getOpacity())
    end)


    local strMap = {}
    local imgMap = {}
    local imgScaleMap = {}

    strMap["resummonTxt"] = common:getLanguageString("@Summon.Result.resummon", self.summonTimes)
    strMap["milestoneTxt"] = Inst.MileStonePoint
    if Inst.isFaction then
        NodeHelper:setNodesVisible(self.container,{mMileStone=true})
        Inst.isFaction=false
    else
        NodeHelper:setNodesVisible(self.container,{mMileStone=false})
    end
    if self.resummonPriceStr ~= nil then
        if self.resummonPriceStr=="isMilestoneSummon" then
            NodeHelper:setNodesVisible(self.container,{resummonNode=false,skipNode=false,confirmNode=false,confirmNode2=true})
        else
            local resummonPriceInfo = InfoAccesser:parseItemStr(self.resummonPriceStr)
            strMap["resummonPriceNum"] = resummonPriceInfo.count
            
            local resummonItemInfo = InfoAccesser:getItemInfoByStr(self.resummonPriceStr)
            -- dump(resummonItemInfo, "resummonItemInfo")
            local resummonItemIconCfg = InfoAccesser:getItemIconCfg(resummonItemInfo.type, resummonItemInfo.id, "SummonPrice")
            if resummonItemInfo ~= nil then
                imgMap["resummonPriceImg"] = resummonItemInfo.icon
            end
            if resummonItemIconCfg ~= nil then
                imgScaleMap["resummonPriceImg"] = resummonItemIconCfg.scale
            end
        end
    end

    NodeHelper:setNodesVisible(self.container, {
        highlightNode = false
    })

    self.rewardNodes = {}
    for idx = 1, 10 do
        self.rewardNodes[idx] = self.container:getVarNode("rewardNode"..tostring(idx))
    end

    NodeHelper:setSpriteImage(self.container, imgMap, imgScaleMap)
    NodeHelper:setStringForLabel(self.container, strMap)

    -- 註冊 封包相關
    self:registerPacket(self.opcodes)

    NodeHelper:setNodesVisible(self.container, { mHightlightMask = false, mHighlightSpineNode = false })

    self:preloadSpines()
    self.raritySpine = SpineContainer:create("Spine/NGUI", "NGUI_80_SSRgacha2")
    local raritySpineNode = tolua.cast(self.raritySpine, "CCNode")
    local raritySpineParent = self.container:getVarNode("mRaritySpineNode")
    raritySpineParent:removeAllChildrenWithCleanup(true)
    raritySpineParent:addChild(raritySpineNode)
    self.raritySpine:runAnimation(1, "animation", -1)

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["SummonResultPage"] = container
    GuideManager.PageInstRef["SummonResultPage"] = slf

    -- 呼叫 當進入
    if self.onEnter_fn ~= nil then
        local temp = self.onEnter_fn
        self.onEnter_fn = nil
        temp()
    end
end

--[[ 當 頁面 執行 ]]
function Inst:onExecute (container)
    self.opacitySyncTasker:update()
end

--[[ 當 頁面 離開 ]]
function Inst:onExit(container)
    
    -- 移除 封包相關
    self:removePacket(self.opcodes)

    self.container = nil

    self.bgSpine = nil
    
    self.rewards = nil

    self.opacitySyncTasker = nil

    self.isPreloadRewards = false

    Inst.isPlayed = false

    -- 回收所有獎品項目物件
    self.resultItemPool:recoveryAll()

    onUnload(self.pageName, container)

    if self.onExit_fn ~= nil then
        local temp = self.onExit_fn
        self.onExit_fn = nil
        temp()
    end
    for k, v in pairs(self.asyncLoadTasks) do
        ALFManager:cancel(v)
    end
    self.asyncLoadTasks = { }
end

--[[ 當動畫播放完畢 ]]
function Inst:onAnimationDone(container, eventName)
    
    if self.highlightAnimDone_callback == nil then return end
    
    local toCall = self.highlightAnimDone_callback
    
    self.highlightAnimDone_callback = nil
    
    if toCall ~= nil then toCall() end
end

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  


--[[ 顯示 ]]
function Inst:show ()
    self.container:setVisible(true)
end

--[[ 關閉 ]]
function Inst:close ()
    -- 關閉 頁面
    self.endLoadingCallback = nil
    PageManager.popPage(self.pageName)
end

--[[ 設定 讀取結束時 callback ]]
function Inst:setEndLoadCallback (fn)
    self.endLoadingCallback = fn
end

--[[ 預先準備資料 (在頁面建立以前呼叫) ]]
function Inst:prepare (data)
    
    local heroCfgs = ConfigManager.getNewHeroCfg()
    local equipCfgs = ConfigManager.getEquipCfg()
    --里程
    Inst.MileStonePoint=data["mileStone"] or "error"
    --種族召喚
    Inst.isFaction=data["isFaction"] or false
    -- 手動顯示
    self.isShowManual = data["isShowManual"]
    if self.isShowManual == nil then self.isShowManual = false end

    -- 召喚次數
    self.summonTimes = data["summonTimes"] or 1

    -- 重新召喚價格
    self.resummonPriceStr = data["resummonPriceStr"]

    -- 獎勵
    self.rewards = {}
    local rewards = data["rewards"]
    for idx, val in ipairs(rewards) do
        
        local reward = {}
        reward.idx = idx
        reward.id = val.id
        reward.type = val.type
        reward.piece = val.piece
        reward.isNew = val.isNew

        reward.isFrameShadeVisible = false

        if val.type == SummonDataMgr.RewardType.HERO then
            local heroID = val.id
            local heroCfg = heroCfgs[heroID]
            local itemInfo = InfoAccesser:getItemInfo(Const_pb.TOOL, val.id, val.piece)
            local heroInfo = InfoAccesser:getHeroInfo(heroID, {"name"})
            reward.name = heroInfo.name
            reward.star = itemInfo.quality
            reward.element = heroCfg.Element
            reward.spineRes = PathAccesser:getHeroChibiSpinePath(heroID)
            reward.spineChibiRes = PathAccesser:getHeroChibiSpinePath(heroID)
            local drawSpinePath, isDrawSpineExist = PathAccesser:getHeroDrawSpinePath(heroID)
            if isDrawSpineExist then
                reward.spineDrawRes = drawSpinePath
                reward.spineDrawScale = NodeHelper:getScaleProportion()
            end
            if heroCfg.Star >= 6 then
                reward.isFrameShadeVisible = true
            end
        elseif val.type == SummonDataMgr.RewardType.AW_EQUIP then
            local parsedEquip = InfoAccesser:parseAWEquipStr(val.id)
            local itemInfo = InfoAccesser:getItemInfo(Const_pb.TOOL, val.id, val.piece)
            local equipCfg = parsedEquip.firstStarCfg
            reward.name = itemInfo.name
            reward.star = equipCfg.quality
            reward.imageRes = itemInfo.icon
            reward.imageDrawRes = itemInfo.icon
            reward.spineDrawScale = NodeHelper:getScaleProportion()
        elseif val.type == SummonDataMgr.RewardType.ITEM then
            local itemInfo = InfoAccesser:getItemInfo(Const_pb.TOOL, val.id, val.piece)
            reward.name = itemInfo.name
            reward.star = itemInfo.quality
            reward.imageRes = itemInfo.icon
            reward.imageDrawRes = itemInfo.icon
        elseif val.type == SummonDataMgr.RewardType.EQUIP then
            local equipCfg = equipCfgs[val.id]
            reward.name = equipCfg.name
            reward.star = equipCfg.quality
            reward.imageRes = equipCfg.icon
            reward.imageDrawRes = equipCfg.icon
        elseif val.type == SummonDataMgr.RewardType.PLAYER_ATTR then
            local itemInfo = InfoAccesser:getItemInfo(Const_pb.PLAYER_ATTR, val.id, val.piece)
            reward.name = itemInfo.name
            reward.star = itemInfo.quality
            reward.imageRes = itemInfo.icon
            reward.imageDrawRes = itemInfo.icon
        elseif val.type == SummonDataMgr.RewardType.RUNE then
            local runeCfg = ConfigManager.getFateDressCfg()[val.id]
            if runeCfg then
            reward.name = common:getLanguageString(runeCfg.name) .. common:getLanguageString("@Rune")
            reward.star = runeCfg.rank
            reward.imageRes = runeCfg.icon
            reward.imageDrawRes = runeCfg.icon
            else
                print("Does not have CFG")
            end
        end
        
        self.rewards[#self.rewards+1] = reward
    end

end
function Inst:ShowJumpReward()
    if self.rewards[#self.rewards].spine and not Inst.isPlayed then
        Inst.isPlayed=true
        self:playRewards()
    elseif self.rewards[#self.rewards].sprite and not Inst.isPlayed then
         Inst.isPlayed=true
         self:playRewards()
    end
end
--[[ 預載Spine ]]
function Inst:preloadSpines ()
    local highlightSpineParent = self.container:getVarNode("mHighlightSpineNode")
    highlightSpineParent:removeAllChildrenWithCleanup(true)
    -- SSR演出spine
    local fn = function()
        Inst.highlightSpine = SpineContainer:create("Spine/NGUI", "NGUI_79_SSRgacha")
        local highlightSpineNode = tolua.cast(Inst.highlightSpine, "CCNode")
        highlightSpineNode:setScale(NodeHelper:getScaleProportion())
        highlightSpineParent:addChild(highlightSpineNode)
    end

    local task = ALFManager:loadSpineTask("Spine/NGUI/", "NGUI_79_SSRgacha", 30, fn)
    table.insert(self.asyncLoadTasks, task)
end

--[[ 預載 (需要頁面建立以後才能呼叫) ]]
function Inst:preloadRewards ()

    if self.isPreloadRewards == true then return end
    self.isPreloadRewards = true
    
    if not isSkipAnim then
        for idx, reward in ipairs(self.rewards) do
            self.opacitySyncTasker:removeByTags({self:_getRewardOpacityTaskID(reward.idx)})
        end
    end

    local isSingleReward = #self.rewards == 1

    local rewardNodes

    if isSingleReward then
        rewardNodes = {
            self.container:getVarNode("rewardNodeOne")
        }
    else 
        rewardNodes = self.rewardNodes
    end

    -- 特寫展示 內容容器
    local highlightDrawNode = self.container:getVarNode("highlightDrawNode")
    local highlightChibiNode = self.container:getVarNode("highlightChibiNode")

    for idx, reward in ipairs(self.rewards) do
        local fn = function()
            -- 容器
            local rewardNode = rewardNodes[idx]

            -- 建立 獎品項目
            local item = self.resultItemPool:reuse()
            local itemContainer = item:requestUI()
            rewardNode:addChild(itemContainer)

            reward.item = item
            
            -- 設置 獎品項目
            if reward.type == SummonDataMgr.RewardType.AW_EQUIP then
                item:setName(common:getLanguageString("@Item_" .. reward.id))
            else
                item:setName(reward.name)
            end
            item:setStar(reward.star or 0)
            item:setFrameShadeVisible(reward.isFrameShadeVisible)
            item:setPiece(reward.piece)
            item:setNewSign(reward.isNew)
            item:setRewardType(reward.type)

            -- 獎品項目 的 內容容器
            local itemContentNode = item:getContentContainer()
            itemContentNode:removeChildByTag(REWARDITEM_TAG, true)

            
            local opacityTask = {
                tags = {self:_getRewardOpacityTaskID(reward.idx), "list"},
                src = tolua.cast(itemContainer:getVarNode("contentRef"), "CCNodeRGBA"),
                dst = nil, -- 依照類型設置
            }
            
            -- 設置 獎品內容
            if reward.type == SummonDataMgr.RewardType.HERO then
                -- 特寫spine
                if reward.spineDrawRes ~= nil then
                    local spineDrawFolderAndName = common:split(reward.spineDrawRes, ",")
                    local fn = function()
                        -- 立繪 ----
                        local spineDraw = SpineContainer:create(spineDrawFolderAndName[1], spineDrawFolderAndName[2])
                        spineDraw:stopAllAnimations()
                        
                        local spineDrawNode = tolua.cast(spineDraw, "CCNode")
                        if reward.spineDrawScale ~= nil then
                            spineDrawNode:setScale(reward.spineDrawScale)
                        end
                        spineDrawNode:setVisible(false)
                        
                        highlightDrawNode:addChild(spineDrawNode)
                        
                        -- 紀錄 在 reward 資料
                        reward.hl_spineDraw = spineDraw
                        reward.hl_spineDrawNode = spineDrawNode

                        local drawOpacityTask = {
                            tags = {self:_getRewardOpacityTaskID(reward.idx), "highlight", "hero draw"},
                            src = tolua.cast(self.container:getVarNode("highlightDrawImg"), "CCNodeRGBA"),
                            dst = tolua.cast(spineDraw, "CCNodeRGBA"),
                            active = false,
                        }
                    
                        self.opacitySyncTasker:addTask(drawOpacityTask)
                    end
                    local task = ALFManager:loadSpineTask(spineDrawFolderAndName[1] .. "/", spineDrawFolderAndName[2], 30, fn)
                    table.insert(self.asyncLoadTasks, task)
                end
	        
                -- 獎品spine
                local spineFolderAndName = common:split(reward.spineRes, ",")
                local spine = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
                spine:stopAllAnimations()
                local spineNode = tolua.cast(spine, "CCNode")
                spineNode:setTag(REWARDITEM_TAG)
                spineNode:setVisible(false)
                itemContentNode:addChild(spineNode)
                -- 透明度同步任務
                opacityTask.dst = tolua.cast(spine, "CCNodeRGBA")
                -- 紀錄 在 reward 資料
                reward.spine = spine
                reward.spineNode = spineNode
	        
                -- 小人 ----
                local spineChibiFolderAndName = common:split(reward.spineChibiRes, ",")
                local spineChibi = SpineContainer:create(spineChibiFolderAndName[1], spineChibiFolderAndName[2])
                spineChibi:stopAllAnimations()
                local spineChibiNode = tolua.cast(spineChibi, "CCNode")
                spineChibiNode:setVisible(false)
                highlightChibiNode:addChild(spineChibiNode)

                local chibiOpacityTask = {
                    tags = {self:_getRewardOpacityTaskID(reward.idx), "highlight", "hero chibi"},
                    src = tolua.cast(self.container:getVarNode("highlightChibiImg"), "CCNodeRGBA"),
                    dst = tolua.cast(spineChibi, "CCNodeRGBA"),
                    active = false,
                }
                self.opacitySyncTasker:addTask(chibiOpacityTask)

                -- 紀錄 在 reward 資料
                reward.hl_spineChibi = spineChibi
                reward.hl_spineChibiNode = spineChibiNode
                

                
            elseif reward.type == SummonDataMgr.RewardType.AW_EQUIP then

                -- 獎品 sprite --
                local sprite = CCSprite:create(reward.imageRes)
                if sprite == nil then print(reward.imageRes) sprite = CCSprite:create() end
                sprite:setAnchorPoint(ccp(0.5, 0))
                sprite:setPosition(ccp(0, 0))
                sprite:setTag(REWARDITEM_TAG)
                sprite:setVisible(false)
                itemContentNode:addChild(sprite)
                -- 透明度同步任務
                opacityTask.dst = tolua.cast(sprite, "CCNodeRGBA")
                
                -- 紀錄 在 reward 資料
                CCLuaLog("-------------set Sprite" .. reward.imageRes)
                reward.sprite = sprite

                -- 特寫spine
                --if reward.imageDrawRes ~= nil then
                --    
                --    -- 專武立繪 ----
                --    local spineName = string.sub(reward.imageDrawRes, 11, 20)
                --    local spineDraw = SpineContainer:create("Spine/AncientWeapon", spineName)
                --    spineDraw:stopAllAnimations()
                --    
                --    local spineDrawNode = tolua.cast(spineDraw, "CCNode")
                --    if reward.spineDrawScale ~= nil then
                --        spineDrawNode:setScale(reward.spineDrawScale)
                --    end
                --    spineDrawNode:setVisible(false)
                --    
                --    highlightDrawNode:addChild(spineDrawNode)
                --    
                --    -- 紀錄 在 reward 資料
                --    reward.hl_spineDraw = spineDraw
                --    reward.hl_spineDrawNode = spineDrawNode
                --
                --    local drawOpacityTask = {
                --        tags = {self:_getRewardOpacityTaskID(reward.idx), "highlight", "hero draw"},
                --        src = tolua.cast(self.container:getVarNode("highlightDrawImg"), "CCNodeRGBA"),
                --        dst = tolua.cast(spineDraw, "CCNodeRGBA"),
                --        active = false,
                --    }
                --    self.opacitySyncTasker:addTask(drawOpacityTask)
                --
                --end
            elseif reward.type == SummonDataMgr.RewardType.ITEM or
                   reward.type == SummonDataMgr.RewardType.EQUIP or
                   reward.type == SummonDataMgr.RewardType.PLAYER_ATTR or
                   reward.type == SummonDataMgr.RewardType.RUNE then
                -- 獎品 sprite --
                local sprite = CCSprite:create(reward.imageRes)
                if sprite == nil then print(reward.imageRes) sprite = CCSprite:create() end
                sprite:setAnchorPoint(ccp(0.5, 0))
                sprite:setPosition(ccp(0, 0))
                sprite:setTag(REWARDITEM_TAG)
                sprite:setVisible(false)
                itemContentNode:addChild(sprite)
                -- 透明度同步任務
                opacityTask.dst = tolua.cast(sprite, "CCNodeRGBA")
                
                -- 紀錄 在 reward 資料
                reward.sprite = sprite

                -- 特寫 sprite --
                local spriteDraw = CCSprite:create(reward.imageDrawRes)
                if spriteDraw == nil then print(reward.imageDrawRes) spriteDraw = CCSprite:create() end
                spriteDraw:setAnchorPoint(ccp(0.5, 0.5))
                spriteDraw:setPosition(ccp(0, 0))
                spriteDraw:setTag(REWARDITEM_TAG)
                spriteDraw:setVisible(false)
                highlightDrawNode:addChild(spriteDraw)

                local drawOpacityTask = {
                    tags = {self:_getRewardOpacityTaskID(reward.idx), "highlight", "weapon draw"},
                    src = tolua.cast(self.container:getVarNode("highlightDrawImg"), "CCNodeRGBA"),
                    dst = tolua.cast(spriteDraw, "CCNodeRGBA"),
                    active = false,
                }
                self.opacitySyncTasker:addTask(drawOpacityTask)

                -- 紀錄 在 reward 資料
                reward.hl_sprite = spriteDraw

            end

            self.opacitySyncTasker:addTask(opacityTask)

            if idx == #self.rewards and self.endLoadingCallback then
                CCLuaLog("-------------endLoadingCallback")
                self.endLoadingCallback()
            end
        end
        local task = ALFManager:loadNormalTask(fn, nil)
        table.insert(self.asyncLoadTasks, task)

        --if idx == #self.rewards then
        --    local task = ALFManager:loadNormalTask(function() end, self.endLoadingCallback)
        --    table.insert(self.asyncLoadTasks, task)
        --end
    end


end

--[[ 播放所有 ]]
function Inst:playAll ()
    local slf = self
    Async:waterfall({
        function (nxt)
            slf:preloadRewards()
            nxt()
        end,
        function (nxt)
            if SummonSubPage_Base.JumpAnim then
               nxt()
            else
                slf:playHighlights(nxt)
            end
        end,
        function (nxt)
             slf:playRewards()
             nxt()
        end,
    })
end

--[[ 播放 所有 特寫展示 ]]
function Inst:playHighlights (onPlayHighlightsDone)
    local slf = self

    local highlightNode = self.container:getVarNode("highlightNode")
    highlightNode:setVisible(true)
    local rewardsNode = self.container:getVarNode("rewardsNode")
    rewardsNode:setVisible(false)

    self.isHighlighting = true

    local toHighlight = {}
    local exists = {}

    -- 篩選
    for idx, reward in ipairs(self.rewards) do while true do
        
        --if exists[reward.id] ~= nil then break end -- continue
        --exists[reward.id] = true

        -- test
        -- toHighlight[#toHighlight + 1] = reward

        local fullPieceCount = -1
        
        if reward.type == SummonDataMgr.RewardType.HERO then
            fullPieceCount = InfoAccesser:getHeroUnlockSoul(reward.id)
        elseif reward.type == SummonDataMgr.RewardType.AW_EQUIP then
            fullPieceCount = SummonDataMgr.FULL_EQUIP_REWARD_PIECE_COUNT
        end

        if fullPieceCount > 0 then
            if reward.piece and reward.piece >= fullPieceCount then
                toHighlight[#toHighlight + 1] = reward
            end
        end
    break end end

    -- 排序
    --table.sort(toHighlight, function(a, b)
    --    if not a or not b then return false end
    --    if a.star ~= b.star then return a.star > b.star end
    --    if a.type ~= b.type then return a.type < b.type end
    --    if a.id ~= b.id then return a.id < b.id end
    --    return false
    --end)


    self._onAllHighlightDone_fn = function ()
        slf._onAllHighlightDone_fn = nil

        Invoker:cancelByTag(HIGHLIGHT_CTRL_TAG)

        -- 隱藏 特寫展示節點
        highlightNode:setVisible(false)
        
        if onPlayHighlightsDone then
            onPlayHighlightsDone()
        end
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            PageManager.pushPage("NewbieGuideForcedPage")
        end
    end

    Async:eachSeries(
        toHighlight, 
        function(idx, each, nxt)
            
            local tag = HIGHLIGHT_CTRL_TAG + idx

            local isNextCalled = false

            -- 下一步
            local onNext = function()
                if isSkipAll then return end

                isNextCalled = true
                Invoker:cancelByTag(tag)
                nxt()
            end

            slf:playHighlight(each, {
                onNext = onNext,
                -- 當動畫播放完畢後 等候自動下一步
                onAnimDone = function()
                    if isNextCalled then return end

                    -- X秒後
                    --Invoker:once(function()
                    --    slf:callHighlightNext()
                    --end, 3):tag(HIGHLIGHT_CTRL_TAG, tag):withNode(self.container)
                end
            })

            -- test
            -- slf:onAnimationDone(slf.container)

        end,
        function ()

            slf.highlightNext_callback = slf._onAllHighlightDone_fn

            -- X秒後
            Invoker:once(function()
                slf:callHighlightNext()
            end, 0):tag(HIGHLIGHT_CTRL_TAG):withNode(self.container)
        end
    )

end

--[[ 播放 特寫展示 ]]
function Inst:playHighlight (reward, options)
    local slf = self

    local target = nil
    local type_onNext = nil

    local txtMap = {}
    local visibleMap = {}
    local imageMap = {}
    
    -- 設置 獎品內容
    if reward.type == SummonDataMgr.RewardType.HERO then

        -- 元素屬性
        if reward.element ~= nil then
            visibleMap.highlightElementNode = true
            imageMap.highlightElementImg = PathAccesser:getElementImagePath(reward.element)
        end
            
        target = reward.hl_spineDrawNode
        if target ~= nil then
            
            reward.hl_spineDraw:runAnimation(1, "animation", -1)
            reward.hl_spineChibi:runAnimation(1, "wait_0", -1)

            if reward.type == SummonDataMgr.RewardType.HERO and reward.star > 5 then    -- SSR英雄
                reward.hl_spineDrawNode:setVisible(false)
                reward.hl_spineChibiNode:setVisible(false)
            else
                reward.hl_spineDrawNode:setVisible(true)
                reward.hl_spineChibiNode:setVisible(true)
            end
            
            type_onNext = function ()
                reward.hl_spineDraw:stopAllAnimations()
                reward.hl_spineChibi:stopAllAnimations()
                
                reward.hl_spineDrawNode:setVisible(false)
                reward.hl_spineChibiNode:setVisible(false)
            end
        end
        -- 名稱
        if txtMap.highlightNameTxt == nil then
            txtMap.highlightNameTxt = common:getLanguageString(reward.name)
        end
        if txtMap.highlightNameTxt2 == nil then
            txtMap.highlightNameTxt2 = ""
        end
        self.container:getVarNode("highlightNameNode"):setPositionY(-15)
    elseif reward.type == SummonDataMgr.RewardType.AW_EQUIP then

        target = reward.hl_spineDrawNode
        if target ~= nil then
            reward.hl_spineDraw:runAnimation(1, "animation", -1)
            reward.hl_spineDrawNode:setVisible(true)
            
            type_onNext = function ()
                reward.hl_spineDraw:stopAllAnimations()
                reward.hl_spineDrawNode:setVisible(false)
            end
            --reward.hl_sprite:setVisible(true)
            --
            --type_onNext = function ()
            --    reward.hl_sprite:setVisible(false)
            --end
        end
        -- 名稱
        if txtMap.highlightNameTxt == nil then
            txtMap.highlightNameTxt = common:getLanguageString("@Item_" .. reward.id)
        end
        if txtMap.highlightNameTxt2 == nil then
            local roleId = math.floor(reward.id / 100) % 100
            txtMap.highlightNameTxt2 = common:getLanguageString("@HeroName_" .. roleId) .. common:getLanguageString("@SuitSpecialEquipBtnTxt1")
        end
        self.container:getVarNode("highlightNameNode"):setPositionY(0)
    end

    -- 預設設置 --

    
    -- 元素屬性 節點
    if visibleMap.highlightElementNode == nil then
        -- 關閉
        visibleMap.highlightElementNode = false
    end
    -- 品質級別圖片
    if imageMap.highlightQualityImg == nil then
        imageMap.highlightQualityImg = self:_getQualityImagePath(reward.star)
    end
    -- 星數圖片
    if imageMap.highlightStarImg1 == nil then
        imageMap.highlightStarImg1 = PathAccesser:getStarIconPath(reward.star)
    end

    -- 設置
    NodeHelper:setStringForLabel(self.container, txtMap)
    NodeHelper:setSpriteImage(self.container, imageMap)
    NodeHelper:setNodesVisible(self.container, visibleMap)

    local taskTags = {self:_getRewardOpacityTaskID(reward.idx), "highlight"}
    self.opacitySyncTasker:setActive(true, taskTags)

    local onNext = options["onNext"]
    self.highlightNext_callback = function ()
        
        slf.opacitySyncTasker:removeByTags(taskTags)

        if type_onNext ~= nil then
            type_onNext()
        end

        if target ~= nil then
            target:setVisible(false)
        end

        if onNext ~= nil then
            onNext()
        end
    end
    SimpleAudioEngine:sharedEngine():stopAllEffects()

    local onAnimDone = options["onAnimDone"]
    self.highlightAnimDone_callback = function () 
        if onAnimDone ~= nil then onAnimDone() end
    end
    -- 重置演出狀態
    self.container:stopAllActions()
    NodeHelper:setNodesVisible(self.container, { mHighlightSpineNode = false })
    if reward.type == SummonDataMgr.RewardType.HERO and reward.star > 5 then    -- SSR英雄 
        local array = CCArray:create()
        array:addObject(CCCallFunc:create(function()
            self.highlightSpine:setToSetupPose()
            NodeHelper:setNodesVisible(self.container, { mHightlightMask = true, mHighlightSpineNode = true })
            self.highlightSpine:setSkin(string.format("SKIP%02d", reward.element))
            self.highlightSpine:runAnimation(1, "animation", 0)
            if reward.hl_spineDrawNode then reward.hl_spineDrawNode:setVisible(true) end
            reward.hl_spineChibiNode:setVisible(true)
        end))
        array:addObject(CCDelayTime:create(2.5))
        array:addObject(CCCallFunc:create(function()
            self.container:runAnimation("Highlight2")
            NodeHelper:setNodesVisible(self.container, { mHightlightMask = false })
            -- 角色語音
            NodeHelper:playEffect(reward.id .. "_31.mp3")
        end))
        array:addObject(CCDelayTime:create(3.5))
        array:addObject(CCCallFunc:create(function()
            NodeHelper:setNodesVisible(self.container, { mHighlightSpineNode = false })
        end))
        self.container:runAction(CCSequence:create(array))
    else
        self.container:runAnimation("Highlight")
        if reward.type == SummonDataMgr.RewardType.HERO then    -- SR英雄 
            -- 角色語音
            NodeHelper:playEffect(reward.id .. "_31.mp3")
        else
            NodeHelper:playEffect("result_eff.mp3")
        end
    end

    self.opacitySyncTasker:update()
end

--[[ 跳過 特寫展示 ]]
function Inst:skipHighlights ()
    if self._onAllHighlightDone_fn == nil then return end
    self._onAllHighlightDone_fn()
end

--[[ 播放 獎品列表 ]]
function Inst:playRewards (isSkipAnim) 
    Inst.isPlayed=true
    if not isSkipAnim then
        -- 關閉所有
        for idx, reward in ipairs(self.rewards) do
            self.opacitySyncTasker:setActive(false, {self:_getRewardOpacityTaskID(reward.idx), "list"})
        end
    end

    local diff = 0.2

    self.container:getVarNode("rewardsNode"):setVisible(true)

    local isSingleReward = #self.rewards == 1
    self.container:getVarNode("rewardsNode1"):setVisible(isSingleReward)
    self.container:getVarNode("rewardsNode10"):setVisible(not isSingleReward)

    self.container:runAnimation("Default")

    local rewardNodes
    if isSingleReward then
        rewardNodes = {
            self.container:getVarNode("rewardNodeOne")
        }
    else 
        rewardNodes = self.rewardNodes
    end

    for idx, reward in ipairs(self.rewards) do

        -- 顯示 獎品內容
        if reward.type == SummonDataMgr.RewardType.HERO then
            if not reward.spine then
                local spineFolderAndName = common:split(reward.spineRes, ",")
                local spine = SpineContainer:create(spineFolderAndName[1], spineFolderAndName[2])
                spine:stopAllAnimations()
                local spineNode = tolua.cast(spine, "CCNode")
                spineNode:setTag(REWARDITEM_TAG)
                spineNode:setVisible(false)
                -- 獎品項目 的 內容容器
                local item = self.resultItemPool:reuse()
                local itemContainer = item:requestUI()
                local rewardNode = rewardNodes[idx]
                rewardNode:addChild(itemContainer)
                local itemContentNode = item:getContentContainer()
                itemContentNode:removeChildByTag(REWARDITEM_TAG, true)
                itemContentNode:addChild(spineNode)
                item:setName(reward.name)
                item:setStar(reward.star or 0)
                item:setFrameShadeVisible(reward.isFrameShadeVisible)
                item:setPiece(reward.piece)
                item:setNewSign(reward.isNew)
                item:setRewardType(reward.type)
                -- 紀錄 在 reward 資料
                reward.spine = spine
                reward.spineNode = spineNode
                reward.item = item
            end
            reward.spineNode:setVisible(true)
            reward.spine:runAnimation(1, "wait_0", -1)
        elseif reward.type == SummonDataMgr.RewardType.AW_EQUIP or 
               reward.type == SummonDataMgr.RewardType.ITEM or 
               reward.type == SummonDataMgr.RewardType.EQUIP or 
               reward.type == SummonDataMgr.RewardType.PLAYER_ATTR or
               reward.type == SummonDataMgr.RewardType.RUNE then

            if not reward.sprite then
                -- 獎品 sprite --
                local sprite = CCSprite:create(reward.imageRes)
                if sprite == nil then print(reward.imageRes) sprite = CCSprite:create() end
                sprite:setAnchorPoint(ccp(0.5, 0))
                sprite:setPosition(ccp(0, 0))
                sprite:setTag(REWARDITEM_TAG)
                sprite:setVisible(false)
                -- 獎品項目 的 內容容器
                local item = self.resultItemPool:reuse()
                local itemContainer = item:requestUI()
                local rewardNode = rewardNodes[idx]
                rewardNode:addChild(itemContainer)
                local itemContentNode = item:getContentContainer()
                itemContentNode:removeChildByTag(REWARDITEM_TAG, true)
                itemContentNode:addChild(sprite)
                -- 設置 獎品項目
                if reward.type == SummonDataMgr.RewardType.AW_EQUIP then
                    item:setName(common:getLanguageString("@Item_" .. reward.id))
                else
                    item:setName(reward.name)
                end
                item:setStar(reward.star or 0)
                item:setFrameShadeVisible(reward.isFrameShadeVisible)
                item:setPiece(reward.piece)
                item:setNewSign(reward.isNew)
                item:setRewardType(reward.type)
                -- 紀錄 在 reward 資料
                reward.sprite = sprite
                reward.item = item
            end
            reward.sprite:setVisible(true)
            -- reward.sprite:setScale(0.25)

        end

        -- 跳過動畫 或 播放動畫
        if isSkipAnim then
            reward.item:skipAnim()
        else
            reward.item:playAnim((idx-1) * diff)
            diff = diff * 0.9
            self.opacitySyncTasker:setActive(true, {self:_getRewardOpacityTaskID(reward.idx), "list"})
        end

    end

    
    if isSkipAnim then
        self.opacitySyncTasker:update()
        self.opacitySyncTasker:removeByTags({"list"})
    end

    SoundManager:getInstance():playMusic("summon_page_bgm.mp3")
    --local GuideManager = require("Guide.GuideManager")
    --GuideManager.PageContainerRef["SummonResultPage"] = container
    --if GuideManager.isInGuide then
    --    PageManager.pushPage("NewbieGuideForcedPage")
    --end
end

function Inst:onResummonClick ()
    if self.onResummon_fn ~= nil then
        local temp = self.onResummon_fn
        self.onResummon_fn = nil
        temp()
    end
end

function Inst:onSkipClick ()
    if not Inst.isPlayed then
        Inst:ShowJumpReward()
    end
end

function Inst:onConfirmClick ()
    self:close()
end

function Inst:onHighlightTouch ()
    self:callHighlightNext()
end

function Inst:callHighlightNext ()
    if self.highlightNext_callback ~= nil then
        local toCall = self.highlightNext_callback
        self.highlightNext_callback = nil
        toCall()
    end
end

function Inst:onHighlightSkipTouch ()
    self:skipHighlights()
end


function Inst:_getRewardOpacityTaskID (idx)
    return string.format("reward_%s", tostring(idx))
end


function Inst:_getQualityImagePath (qualityNum)
    if 0 < qualityNum and qualityNum < 6 then
        return "Imagesetfile/Common_UI02/SummonResult_SR.png"
    elseif 5 < qualityNum and qualityNum < 11 then
        return "Imagesetfile/Common_UI02/SummonResult_SSR.png"
    elseif 10 < qualityNum and qualityNum < 16 then
        return "Imagesetfile/Common_UI02/SummonResult_SSR.png"
    else
        return "Imagesetfile/Common_UI02/SummonResult_R.png"
    end 
end


local CommonPage = require('CommonPage')
return CommonPage.newSub(Inst, Inst.pageName, {
    ccbiFile = Inst.ccbiFile,
    handlerMap = Inst.handlerMap,
    opcode = Inst.opcodes,
})