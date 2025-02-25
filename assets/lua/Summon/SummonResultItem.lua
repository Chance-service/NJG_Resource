--[[ 
    name: SummonResultItem
    desc: 召喚結果項目
    author: youzi
    update: 2023/10/3 16:11
    description: 
--]]


local PathAccesser = require("Util.PathAccesser")
local SummonDataMgr = require("Summon.SummonDataMgr")

--[[ 主體 ]]
local SummonResultItem = {}

--[[ 
    var
        frameShadeImg 效果背板
        contentNode 內容容器
        pieceNode 碎片容器
        pieceNum 碎片數量

        newSignNode 新取得符號
        starImg 星數圖片

    event

--]]

--[[ 新建 ]]
function SummonResultItem:new()
    
    local inst = {}

    --[[ 容器 ]]
    inst.container = nil

    --[[ UI檔案 ]]
    inst.CCBI_FILE = "SummonResultItem.ccbi"

    --[[ 事件:函式對應 ]]
    inst.handlerMap = {
        
    }
    inst.star = 4
    inst.piece = 0
    inst.isNew = false
    inst.type = nil

    --[[ 請求建立UI ]]
    function inst:requestUI ()
        if self.container ~= nil then return self.container end
        
        -- 以 ccbi 建立
        self.container = ScriptContentBase:create(self.CCBI_FILE)

        self.container:setVisible(false)
        
        -- 註冊 呼叫 行為
        self.container:registerFunctionHandler(function (eventName, container)
            local funcName = self.handlerMap[eventName]
            local func = self[funcName]
            if func then
                func(self, container)
            end
        end)

        return self.container
    end

    --[[ 取得內容容器 ]]
    function inst:getContentContainer ()
        return self.container:getVarNode("contentNode")
    end

    --[[ 設置 星數 ]]
    function inst:setStar (star)
        -- local visibles = {}
        -- for idx = 1, inst.MAX_STAR do
        --     visibles["mStar"..tostring(idx)] = (idx == star)
        -- end
        -- NodeHelper:setNodesVisible(inst.container, visibles)

        NodeHelper:setSpriteImage(self.container, {
            starImg = PathAccesser:getStarIconPath(star)
        })
        self.star = star
        self:updateSign()
    end

    --[[ 設置名稱 ]]
    function inst:setName (name)
        if name == nil then
            self.name = 0
        else
            self.name = name
        end
        self:updateSign()
    end

    --[[ 設置碎片 ]]
    function inst:setPiece (piece)
        if piece == nil then
            self.piece = 0
        else
            self.piece = piece
        end
        self:updateSign()
    end

    --[[ 設置獎品類型 ]]
    function inst:setRewardType (_type)
        self.type = _type
        self:updateSign()
    end

    --[[ 設置新解鎖 ]]
    function inst:setNewSign (isShowNew)
        if isShowNew == nil then isShowNew = false end
        self.isNew = isShowNew
        self:updateSign()
    end

    --[[ 更新記號 ]]
    function inst:updateSign ()
        local isShowNew = false--self.isNew
        local isShowPiece = self.piece > 0
        NodeHelper:setNodesVisible(self.container, {
            newSignNode = isShowNew,
            pieceNode = not isShowNew and isShowPiece,
            starImg = not isShowPiece,
            mPieceImg = (self.type == SummonDataMgr.RewardType.HERO),
            mItemImg = (self.type ~= SummonDataMgr.RewardType.HERO),
            mItemName = true,
        })

        NodeHelper:setStringForLabel(self.container, {
            mItemName = common:getLanguageString(self.name),
            pieceNum = common:getLanguageString("@Summon.ResultItem.pieceNum", GameUtil:formatNumber(self.piece))
        })

        NodeHelper:setSpriteImage(self.container, {
            mPieceImg = GameConfig.summonPieceImg[self.star],
            mItemImg = GameConfig.summonTreasureImg[self.star],
        })
    end

    --[[ 設置 背板 ]]
    function inst:setFrameShadeVisible (isVisible)
        NodeHelper:setNodesVisible(self.container, {
            frameShadeImg = isVisible,
        })
    end

    --[[ 播放動畫 ]]
    function inst:playAnim (delay)
        local slf = self
        if delay == nil then
            self.container:setVisible(true)
            self.container:runAnimation("show")
            return
        end

        local delayTime = CCDelayTime:create(delay)
        local callFn = CCCallFuncN:create( function()
            slf.container:setVisible(true)
            slf.container:runAnimation("show")
        end)

        local arr = CCArray:create()
        arr:addObject(delayTime)
        arr:addObject(callFn)

        local sequence = CCSequence:create(arr)
        self.container:runAction(sequence)
    end

    --[[ 跳過動畫 ]]
    function inst:skipAnim ()
        self.container:setVisible(true)
        self.container:runAnimation("stand")
    end

    return inst
end

return SummonResultItem