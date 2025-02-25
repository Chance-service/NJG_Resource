local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local TimeDateUtil = require("Util.TimeDateUtil")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity5_pb = require("Activity5_pb")
local HP_pb = require("HP_pb");
local ResManager = require("ResManagerForLua")
local ItemManager = require("Item.ItemManager")

local ActPopUpSaleSubPage_Content = {
    rewardItems = {},
}

local PopUpData = nil
local _serverData = {}
local _showData = nil

local GiftId = 0

local CCBI_FILE = "Act_TimeLimit_132.ccbi"

local HANDLER_MAP = {
    onRecharge = "onRecharge",
    onClose = "onClose",
}

local OPCODES = {
}

-- local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")

function ActPopUpSaleSubPage_Content:onEnter(parentContainer)
    local slf = self

    self.container = ScriptContentBase:create(CCBI_FILE)
    
    
    -- 註冊 呼叫 行為
    self.container:registerFunctionHandler(function (eventName, container)
        local funcName = HANDLER_MAP[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)

    self:registerPacket(parentContainer)
    self:initUi(self.container)


    return self.container
end

-- 
function ActPopUpSaleSubPage_Content:initUi(container)
    PopUpData=common:getPopUpData(GiftId)
    self.rewardItems = PopUpData.Reward
    PopUpData.price = ActPopUpSalePage_getPrice(GiftId)
    -- 初始化 獲得列表
    NodeHelper:initScrollView(container, "mContent", #self.rewardItems);

    self:updateItems()

    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())

    NodeHelper:setStringForLabel(container, { mRecharge = PopUpData.price })
    NodeHelper:setSpriteImage(container, {mLvSprite = PopUpData.Banner ,mBg = PopUpData.BG })
    NodeHelper:setStringForLabel(container,{mTxt=common:getLanguageString(PopUpData.Content)})
    container:getVarLabelTTF("mTxt"):setHorizontalAlignment(kCCTextAlignmentCenter)
end

function ActPopUpSaleSubPage_Content:updateItems()
    local size = #self.rewardItems
        
    local colMax = 4


    local options = {
        -- magic layout number 
        -- 因為CommonRewardContent尺寸異常，導致各使用處需要自行處理
        interval = ccp(0, 0),
        colMax = colMax,
        paddingTop = 0,
        paddingBottom = 0,
        originScrollViewSize = CCSizeMake(544, 272),
        isDisableTouchWhenNotFull = true
    }
    
    if size == 5 then 
        options.colMax = 3
        options.paddingLeft = 70
    end
    -- 未滿 1行 則 橫向置中
    if size < colMax then
        options.isAlignCenterHorizontal = true
    end
    
    -- 未達 2行 則 垂直置中
    if size <= colMax then
        options.isAlignCenterVertical = true
        options.startOffset = ccp(0, 0)
    -- 達到 2行 則 偏移在首項 並 偏移paddingTop
    else
        options.startOffsetAtItemIdx = 1
        options.startOffset = ccp(0, -options.paddingTop)
    end

    --[[ 滾動視圖 左上至右下 ]]
    NodeHelperUZ:buildScrollViewGrid_LT2RB(
        self.container,
        size,
        "CommonRewardContent.ccbi",
        function (eventName, container)
            self:onScrollViewFunction(eventName, container)
        end,
        options
    )
            
    -- 顯示/隱藏 列表 或 無獎勵提示
    NodeHelper:setNodesVisible(self.container, {
        mContent = size ~= 0
    })
    
    -- 若 數量 尚未超過 每行數量 的話
    if size <= colMax  then
        local node = self.container:getVarNode("mContent")
        node:setTouchEnabled(false)
    end
end
--[[ 滾動視圖 功能窗口 ]]
function ActPopUpSaleSubPage_Content:onScrollViewFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        --- 每个子空间创建的时候会调用这个函数
        local contentId = container:getItemDate().mID;
        -- 获取到时第几行
        local idx = contentId
        -- 获取当前的index      i是每行的第几个 用来获取组件用的
        local node = container:getVarNode("mItem")
        local itemNode = ScriptContentBase:create('GoodsItem.ccbi')

        local itemData = self.rewardItems[idx]
        local resInfo = ResManager:getResInfoByTypeAndId(itemData and itemData.type or 30000, itemData and itemData.itemId or 104001, itemData and itemData.count or 1);
        --NodeHelper:setStringForLabel(itemNode, { mName = "" });
        local numStr = ""
        if resInfo.count > 0 then
            numStr = tostring(resInfo.count)
        end
        local lb2Str = {
            mNumber = numStr
        };
        local showName = "";
        if itemData and itemData.type == 30000 then
            showName = ItemManager:getShowNameById(itemData.itemId)
        else
            showName = resInfo.name           
        end
        NodeHelper:setNodesVisible(itemNode, { m2Percent = false, m5Percent = false });

        if itemData.type == 40000 then
            for i = 1, 6 do
                NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.quality })
            end
        end
        NodeHelper:setNodesVisible(itemNode, { mStarNode = itemData.type == 40000 })
        
        NodeHelper:setStringForLabel(itemNode, lb2Str);
        NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = 1 });
        NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality });
        NodeHelper:setColorForLabel(itemNode, { mName = ConfigManager.getQualityColor()[resInfo.quality].textColor })
        NodeHelper:setNodesVisible(itemNode, { mName = false})

        node:addChild(itemNode);
        itemNode:registerFunctionHandler(function (eventName, container)
            if eventName == "onHand" then
                local id = container.id
                GameUtil:showTip(container:getVarNode("mHand"), self.rewardItems[id])
            end  
        end)
        itemNode.id = contentId
    end
end

function ActPopUpSaleSubPage_Content:onExit(parentContainer)
    NodeHelper:clearScrollView(self.container)
end

function ActPopUpSaleSubPage_Content:onRecharge(container)
    local msg = Activity5_pb.MaxJumpGiftReq()
    msg.action = 1
    msg.goodsId = GiftId
    common:sendPacket(HP_pb.ACTIVITY187_MAXJUMP_GIFT_C, msg, false)
end

function ActPopUpSaleSubPage_Content:onExecute(parentContainer)
    local isLeftTimeSeted = false
    if _serverData[GiftId] ~= nil and _serverData[GiftId].limitDate ~= nil then
        local leftTime = _serverData[GiftId].limitDate - os.time()
        if leftTime > 0 then
            -- 剩餘時間 轉至 日期格式
            local leftTimeDate = TimeDateUtil:utcTime2Date(leftTime)
            -- 重新進位
            leftTimeDate = TimeDateUtil:utcDateCarry(leftTimeDate)

            -- 原本是 日時分 所以字串定 dhm 可能改leftTime比較精確
            local SplitTime =  common:second2DateString4(leftTime,true)
            local text=string.format(common:getLanguageString("@ActPopUpSale.LeftTimeText.dhm"),SplitTime[1], SplitTime[2], SplitTime[3], SplitTime[4])
            if tonumber (SplitTime[1]) >30 then
                text = ""
            end
            NodeHelper:setStringForTTFLabel(self.container, {
                leftTimeText = text
            })
            isLeftTimeSeted = true
        end
    end
    
    NodeHelper:setNodesVisible(self.container, {
        leftTimeText = isLeftTimeSeted
    });
     local MainPage=require("ActPopUpSale.ActPopUpSalePage")
    if not isLeftTimeSeted then  
        MainPage:onCloseBtn(self.container)  
    end
end

function ActPopUpSaleSubPage_Content:registerPacket(container)
    for key, opcode in pairs(OPCODES) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActPopUpSaleSubPage_Content_sendInfoRequest()
    local msg = Activity5_pb.MaxJumpGiftReq()
    msg.action = 0
    common:sendPacket(HP_pb.ACTIVITY187_MAXJUMP_GIFT_C, msg, false)
end


function ActPopUpSaleSubPage_Content_getServerData()
    return _serverData
end

function ActPopUpSaleSubPage_Content_isShow()
    local _Show = false
    if not _serverData then return false end
    for _,data in pairs(_serverData) do
        if not data.isGot and data.limitDate- os.time() > 0 then
            return true
        end
    end
    return _serverData
end

function ActPopUpSaleSubPage_setGiftId(_id)
    GiftId = _id
end
function ActPopUpSaleSubPage_Content_setServerData(msg)
    for i = 1, #msg.info do
        local itemData = msg.info[i]
        local goodsId = itemData.goodsId
        if not  _serverData[goodsId] then  _serverData[goodsId] = {} end
        _serverData[goodsId] = { 
            id = goodsId, 
            isGot = itemData.count >= ConfigManager:getPopUpCfg2()[goodsId].Count,
            limitDate = itemData.leftTime + os.time()
        }

        if _serverData[goodsId] and _serverData[goodsId].limitDate then
            local PopUpPage = require("ActPopUpSale.ActPopUpSalePage")
            PopUpPage:setTime(goodsId, _serverData[goodsId].limitDate , _serverData[goodsId].isGot)
        end
    end
end
function ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(GiftId)
    if _serverData[GiftId] == nil then
        --print("serverData is null")
        _showData = { isShowIcon = false, id = GiftId, isFree = false, isShowRedPoint = false,isGot=false }
        return _showData
    end
    if _serverData[GiftId].limitDate ~= nil and os.time() > _serverData[GiftId].limitDate then
        _showData = { isShowIcon = false, id = GiftId, isFree = false, isShowRedPoint = false ,isGot=false}
        return _showData
    end

    local _ConfigData = ConfigManager.getPopUpCfg2()

    for k, v in pairs(_ConfigData) do
        if _serverData[GiftId] and not _serverData[GiftId].isGot then
            _showData = { isShowIcon = true, id = GiftId, isFree = true, isShowRedPoint = false,isGot=false }
            return _showData
        end
    end

    _showData = { isShowIcon = false, id = GiftId, isFree = false, isShowRedPoint = false,isGot=true}
    return _showData
end

return ActPopUpSaleSubPage_Content
