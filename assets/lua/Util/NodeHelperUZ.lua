
--[[ 
    name: NodeHelperUZ
    desc: 自用參考NodeHelper的擴展
    author: youzi
    update: 2023/6/9 15:07
--]]

local NodeHelper = require("NodeHelper")
local ConfigManager = require("ConfigManager")
local InfoAccesser = require("Util.InfoAccesser")

local NodeHelperUZ = {}


function NodeHelperUZ:doToNodesRecursive(nodes, fn)
    local queue = {}
    for idx, val in ipairs(nodes) do
        queue[idx] = nodes[idx]
    end

    local test = 100
    while #queue > 0 and test > 0 do
        test = test - 1

        local nextParent = table.remove(queue, 1)
        local childs = nextParent:getChildren()
        local childsCount = nextParent:getChildrenCount()
        for idx = 1, childsCount do
            local eachChild = tolua.cast(childs:objectAtIndex(idx - 1), "CCNode")
            fn(eachChild)
            queue[#queue+1] = eachChild
        end
    end
end

--子类随父类透明度变化而变化递归设置
function NodeHelperUZ:setCascadeOpacityEnabled(node, is_true )  
    NodeHelperUZ:doToNodesRecursive({node}, function(each)
        if node.setCascadeOpacityEnabled then
            node:setCascadeOpacityEnabled(is_true)
        end
    end)
end

--[[ 使 Spine背景節點 適應尺寸 ]]
function NodeHelperUZ:fitBGSpine (node, options)
    if options == nil then options = {} end
    
    if options.anchorPoint == nil then
        options.anchorPoint = ccp(0.5, 0.5)
    end
    self:fitBGNode(node, options)
end

--[[ 使 背景節點 適應尺寸 ]] 
-- 目前計算方式不正確, 僅少數情況適用
function NodeHelperUZ:fitBGNode (node, options)
    if options == nil then options = {} end

    -- 原始比例
    local orinScale = options.originalScale
    if orinScale == nil then orinScale = node:getScale() end

    -- 比例的比例, 用來微調用
    local scaleScale = options.scaleScale
    if scaleScale == nil then scaleScale = 1 end

    -- 當前尺寸與設計尺寸都需要縮減多少才是要計算的比例
    -- 用在一個節點的尺寸不是定為螢幕的多少百分比時使用.
    local ratioSizeFix = options.ratioSizeFix
    if ratioSizeFix == nil then ratioSizeFix = CCSizeMake(0, 0) end

    local ratioSizeFixFrame = options.ratioSizeFixFrame
    if ratioSizeFixFrame == nil then ratioSizeFixFrame = ratioSizeFix end

    
    -- 調整最後偏移用的
    -- 定義中心點
    local anchorPoint = options.anchorPoint
    if anchorPoint == nil then anchorPoint = node:getAnchorPoint() end
    -- 目標中心點
    local pivot = options.pivot
    if pivot == nil then pivot = anchorPoint end
    -- 尺寸
    local size = options.size
    if size == nil then size = CCSizeMake(720, 1280) end

    local offset = options.offset
    if offset == nil then offset = ccp(node:getPositionX(), node:getPositionY()) end
    
    ------------------

    -- 計算 適應比例
    local frameSize = CCEGLView:sharedOpenGLView():getFrameSize()

    local ratio = (frameSize.height - ratioSizeFixFrame.height) / (frameSize.width - ratioSizeFixFrame.width)
    local designRatio = (GameConfig.ScreenSize.height - ratioSizeFix.height) / (GameConfig.ScreenSize.width - ratioSizeFix.width)
    -- print(string.format("%s / %s = %s == %s?", tostring(ratio), tostring(designRatio), tostring(ratio/ designRatio), tostring(NodeHelper:getScaleProportion())))
    ratio = ratio / designRatio * 1.0
    if ratio < 1 then ratio = 1 end

    -- 原比例 * 適應比例 * 比例比例
    local scale = orinScale * ratio * scaleScale

    -- 與 原比例的差距
    local scaleDelta = scale - orinScale

    -- 變更比例
    node:setScale(scale)
    -- print("setScale : "..tostring(scale).." => "..tostring(node:getScale()))

    -- 調整偏移
    local posX = (size.width * scale * (anchorPoint.x - pivot.x)) + (offset.x)
    local posY = (size.height * scale * (anchorPoint.y - pivot.y)) + (offset.y)
    node:setPositionX(posX)
    node:setPositionY(posY)
    -- print(string.format("PosX =  (sizeW[%s] * scale[%s] * (apX[%s] - pivotX[%s])) + offsetX[%s]", size.width, scale, anchorPoint.x, pivot.x, offset.x))
    -- print(string.format("PosY =  (sizeH[%s] * scale[%s] * (apY[%s] - pivotY[%s])) + offsetY[%s]", size.height, scale, anchorPoint.y, pivot.y, offset.y))
    -- print(string.format("POS : %s,%s", posX, posY))

    return {
        scale = scale
    }
end

-- ##     ## #### 
-- ##     ##  ##  
-- ##     ##  ##  
-- ##     ##  ##  
-- ##     ##  ##  
-- ##     ##  ##  
--  #######  #### 

--[[ 設置 所有子節點 灰階 ]]
function NodeHelperUZ:setNodeIsGrayRecursive(node, isDisabled)
    self:setNodesIsGrayRecursive({node}, isDisabled)
end

--[[ 設置 所有子節點 灰階 ]]
function NodeHelperUZ:setNodesIsGrayRecursive(nodes, isDisabled)
    
    local queue = {}
    for idx, val in ipairs(nodes) do
        queue[idx] = nodes[idx]
    end

    local test = 100
    while #queue > 0 and test > 0 do
        test = test - 1

        local nextParent = table.remove(queue, 1)
        local childs = nextParent:getChildren()
        local childsCount = nextParent:getChildrenCount()
        for idx = 1, childsCount do
            local eachChild = tolua.cast(childs:objectAtIndex(idx - 1), "CCNode")
            if isDisabled then
                GraySprite:AddColorGrayToNode(eachChild)
            else 
                GraySprite:RemoveColorGrayToNode(eachChild)
            end
            queue[#queue+1] = eachChild
        end
    end
end

--[[ 設置 進度條百分比 (九宮格圖) ]]
function NodeHelperUZ:setProgressBar9Sprite(container, varName, percent, options)
    if container==nil then return end
    local bar = container:getVarScale9Sprite(varName)
    if bar == nil then return end

    if options == nil then options = {} end

    local isVertical = options["isVertical"]
    if isVertical == nil then isVertical = false end

    local length = options["length"]
    
    if length == nil then
        
        local parent = options["parentNode"]

        if parent == nil then
            local parentVar = options["parentVar"]
            if parentVar ~= nil then
                parent = container:getVarNode(parentVar)
            end
        end

        if parent == nil then
            parent = bar:getParent()
        end
        
        if parent == nil then return end

        local parentSize = parent:getContentSize()

        if isVertical then
            length = parentSize.height
        else
            length = parentSize.width
        end
    end

    -- 取得與修正 inset
    local inset_top = bar:getInsetTop()
    if inset_top == 0 then 
        inset_top = 1
        bar:setInsetTop(inset_top)
    end
    local inset_bottom = bar:getInsetBottom()
    if inset_bottom == 0 then 
        inset_bottom = 1
        bar:setInsetBottom(inset_bottom)
    end
    local inset_left = bar:getInsetLeft()
    if inset_left == 0 then 
        inset_left = 1
        bar:setInsetLeft(inset_left)
    end
    local inset_right = bar:getInsetRight()
    if inset_right == 0 then 
        inset_right = 1
        bar:setInsetRight(inset_right)
    end

    local min
    if isVertical then
        min = inset_top + inset_bottom
    else
        min = inset_left + inset_right
    end
    
    local scale = 1
    length = length * percent

    if length < min then
        scale = length / min
    end

    local size = bar:getContentSize()

    if isVertical then
        size.height = length
        bar:setScaleY(scale) 
    else
        size.width = length
        bar:setScaleX(scale) 
    end

    bar:setContentSize(size)
end

--[[ 註銷/註冊 觸碰 在CCLayer上 ]]
function NodeHelperUZ:unregisterLayerTouchHandler (layer)
    -- 轉呼叫
    layer:unregisterScriptTouchHandler()
end
function NodeHelperUZ:registerLayerTouchHandler (layer, option)
    if option == nil then option = {} end
    
    local id2isPressed = {}

    local isMultipleTouch = option.isMultipleTouch
    if isMultipleTouch == nil then isMultipleTouch = false end
    
    local isSwallowTouches = option.isSwallowTouches
    if isSwallowTouches == nil then isSwallowTouches = false end

    local priority = option.priority
    if priority == nil then priority = 0 end
    
    layer:registerScriptTouchHandler( function(eventName, pTouch)
        if option.isLog then print("TOUCHEVENT:"..eventName) end

        local touchPosInRect = layer:convertToNodeSpace(pTouch:getLocation())
        local size = layer:getContentSize()
        
        if option.isLog then print(string.format("%d,%d in %d,%d", touchPosInRect.x, touchPosInRect.y, size.width, size.height)) end

        local touchID = pTouch:getID()
        local isPressed = id2isPressed[touchID]
        if isPressed == nil then isPressed = false end


        if option.isNeedInRect == true and isPressed == false then
            if touchPosInRect.x < 0 or touchPosInRect.y < 0 or
               touchPosInRect.x > size.width or touchPosInRect.y > size.height then
                if option.isLog then print("is out of rect") end
                return true
            end
        end
        
        local evtData = {
            eventName = eventName,
            touch = pTouch,
            touchID = touchID,
            locationInRect = touchPosInRect,
        }


        if eventName == "began" then

            isPressed = true

            if option.onTouchDown ~= nil then
                option.onTouchDown(evtData)
            end

        else

            if isPressed == false then
                return
            end

            if eventName == "ended" then
                isPressed = false
                if option.onTouchUp ~= nil then
                    option.onTouchUp(evtData)
                end
            elseif eventName == "moved" then
                if option.onTouchMove ~= nil then
                    option.onTouchMove(evtData)
                end
            end
        end

        id2isPressed[touchID] = isPressed

        if option.onTouchRaw ~= nil then
            option.onTouchRaw(eventName, pTouch, evtData)
        end

        return false
    end
    , isMultipleTouch, priority, isSwallowTouches)

end

-- ########     ###    ########  ########     ######  ########    ###    ########  
-- ##     ##   ## ##   ##     ## ##          ##    ##    ##      ## ##   ##     ## 
-- ##     ##  ##   ##  ##     ## ##          ##          ##     ##   ##  ##     ## 
-- ########  ##     ## ########  ######       ######     ##    ##     ## ########  
-- ##   ##   ######### ##   ##   ##                ##    ##    ######### ##   ##   
-- ##    ##  ##     ## ##    ##  ##          ##    ##    ##    ##     ## ##    ##  
-- ##     ## ##     ## ##     ## ########     ######     ##    ##     ## ##     ## 

--[[ 顯示 稀有度星數 ]]
function NodeHelperUZ:showRareStar(container, star)
    
    local visibleMap = {}

    local rare = 1
    local starAtRare = star
    if star <= 5 then
        rare = 1 --sr
    elseif star > 5 and star <= 10 then
        rare = 2 --ssr
        starAtRare = starAtRare - 5
    elseif star > 10 then
        rare = 3 --ur
        starAtRare = starAtRare - 10
    end

    local totalRareStr = {"Sr", "Ssr", "Ur"}
    for eachRare = 1, #totalRareStr do
        for eachStar = 1, 5 do
            visibleMap["mStar"..totalRareStr[eachRare]..tostring(eachStar)] = (eachRare == rare) and (eachStar == starAtRare)
        end
    end

    NodeHelper:setNodesVisible(container, visibleMap)
end


--   #####                                     #     #                 
--  #     #  ####  #####   ####  #      #      #     # # ###### #    # 
--  #       #    # #    # #    # #      #      #     # # #      #    # 
--   #####  #      #    # #    # #      #      #     # # #####  #    # 
--        # #      #####  #    # #      #       #   #  # #      # ## # 
--  #     # #    # #   #  #    # #      #        # #   # #      ##  ## 
--   #####   ####  #    #  ####  ###### ######    #    # ###### #    # 
--                                                                     

--[[ 初始化 滾動視圖 ]]
function NodeHelperUZ:initScrollView(container, svName, size, boundcedItemFlag)
    return NodeHelper:initScrollView(container, svName, size, boundcedItemFlag)
end

--[[ 組織 滾動視圖 橫向]]
function NodeHelperUZ:buildScrollViewHorizontal(container, itemMaxSize, ccbiFile, funcCallback, options)
    self:buildScrollView(container, itemMaxSize, false, ccbiFile, funcCallback, options)
end

--[[ 組織 滾動視圖 縱向]]
function NodeHelperUZ:buildScrollViewVertical(container, itemMaxSize, ccbiFile, funcCallback, options)
    self:buildScrollView(container, itemMaxSize, true, ccbiFile, funcCallback, options)
end

--[[ 組織 滾動視圖 ]]
-- TODO 可能在成員顯示順序上還有一點問題
function NodeHelperUZ:buildScrollView(container, itemMaxSize, isVertical, ccbiFile, funcCallback, options)
    if itemMaxSize == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then
        return
    end
    
    local createCCB
    local ccbiFileType = type(ccbiFile)
    if ccbiFileType == "string" then
        createCCB = function (idx)
            local pItem = ScriptContentBase:create(ccbiFile)
            -- 註冊行為
            pItem:registerFunctionHandler(funcCallback)
            return pItem
        end
    elseif ccbiFileType == "function" then
        createCCB = function (idx)
            return ccbiFile(idx, funcCallback)
        end
    end

    -- 最多 成員數
    local maxNodeCount = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    
    -- 選項 ------------------
    
    if options == nil then options = {} end
    
    -- 容器 尺寸
    local scrollViewSize = options["originScrollViewSize"] or options["scrollViewSize"]
    if scrollViewSize == nil then scrollViewSize = container:getContentSize() end
    -- print(string.format("scrollViewSize.width[%s] scrollViewSize.height[%s]", scrollViewSize.width, scrollViewSize.height))
    
    -- 間隔距離
    local interval = options["interval"]
    if interval == nil then interval = 0 end
    
    -- 是否 吞噬 觸碰
    local isSwallowTouches = options["isSwallowTouches"]
    if isSwallowTouches == nil then isSwallowTouches = true end
    
    -- 起始位置 偏移
    local startOffset = options["startOffset"]
    if startOffset == nil then startOffset = ccp(0, 0) end
    -- 起始位置 偏移 成員序號
    local startOffsetAtItemIdx = options["startOffsetAtItemIdx"]
    -- 起始位置 安全模式
    local startOffsetSafe = options["startOffsetSafe"]
    if startOffsetSafe == nil then startOffsetSafe = true end

    -- 是否 在內容超出容器時 禁用操作
    local isDisableTouchWhenNotFull = options["isDisableTouchWhenNotFull"]
    if isDisableTouchWhenNotFull == nil then isDisableTouchWhenNotFull = true end
    
    -- 內距
    local paddingLeft = options["paddingLeft"]
    if paddingLeft == nil then paddingLeft = "auto" end
    
    local paddingRight = options["paddingRight"]
    if paddingRight == nil then paddingRight = "auto" end
    
    local paddingTop = options["paddingTop"]
    if paddingTop == nil then paddingTop = "auto" end
    
    local paddingBottom = options["paddingBottom"]
    if paddingBottom == nil then paddingBottom = "auto" end

    -- 是否 反向靠齊
    -- 原: 垂直(下至上) 水平(左至右) | 反: 垂直(上至下) 水平(右至左)
    local isAlignReverse = options["isAlignReverse"]
    if isAlignReverse == nil then isAlignReverse = isVertical end

    -- 是否 可回彈
    local isBounceable = options["isBounceable"]
    if isBounceable == nil then isBounceable = true end

    -- 序號
    local beginIdx
    local endIdx
    local pushIdx = 1

    -- 是否 順序 是往 軸正向
    local isPostiveAxis = not isAlignReverse

    -- 若 軸正向
    if isPostiveAxis then
        beginIdx = 1
        endIdx = itemMaxSize
        pushIdx = 1
    else
        beginIdx = itemMaxSize
        endIdx = 1
        pushIdx = -1
    end
    
    -- print(string.format("beginIdx %s, endIdx %s, pushIdx %s", beginIdx, endIdx, pushIdx))
    
    -- 起始成員 尺寸 位置
    local startItemPosSize = {
        size = CCSizeMake(0,0),
        pos = ccp(0, 0)
    }
    
    -- 成員尺寸 參考
    
    local testSizeItem = createCCB()
    local itemSizeRef = testSizeItem:getContentSize()

    -- print(string.format("itemSize %s, %s", itemSizeRef.width, itemSizeRef.height))
    
    -- 計算 自動 padding ( TODO:有待完善 )
    if isVertical then
        if paddingLeft == "auto" and paddingRight == "auto" then
            local each = (scrollViewSize.width - itemSizeRef.width) / 2
            paddingLeft = each
            paddingRight = each
        else
            if paddingLeft == "auto" then
                paddingLeft = scrollViewSize.width - (itemSizeRef.width + paddingRight)
            elseif paddingRight == "auto" then
                paddingRight = scrollViewSize.width - (paddingLeft + itemSizeRef.width)
            end
        end
        if paddingTop == "auto" then paddingTop = 0 end
        if paddingBottom == "auto" then paddingBottom = 0 end
    else
        if paddingTop == "auto" and paddingBottom == "auto" then
            local each = (scrollViewSize.height - itemSizeRef.height) / 2
            -- print(string.format("each = scrollViewSize.height[%s] - itemSizeRef.height[%s]", scrollViewSize.height, itemSizeRef.height))
            paddingTop = each
            paddingBottom = each
        else
            if paddingTop == "auto" then
                paddingTop = scrollViewSize.height - (itemSizeRef.height + paddingBottom)
            elseif paddingBottom == "auto" then
                paddingBottom = scrollViewSize.height - (paddingTop + itemSizeRef.height)
            end
        end
        if paddingLeft == "auto" then paddingLeft = 0 end
        if paddingRight == "auto" then paddingRight = 0 end
    end

    -- print(string.format("L%d R%d T%d B%d", paddingLeft, paddingRight, paddingTop, paddingBottom))
    testSizeItem:release()

    local itemCount = 0

    -- 以 成員順序 依序
    for idx = beginIdx, endIdx, pushIdx do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = idx
        pItemData.m_iIdx = idx
        
        -- 推移總數
        itemCount = itemCount + 1

        -- 位置
        local itemPos = ccp(paddingLeft, paddingBottom)
        -- print(string.format("itemPosBase:%s,%s",tostring(paddingLeft), tostring(paddingBottom)))

        -- 偏移
        local offset = 0
        
        local itemLength
        if isVertical then
            itemLength = itemSizeRef.height
        else
            itemLength = itemSizeRef.width
        end

        if isPostiveAxis then
            offset = (itemLength + interval) * (idx-1)
        else
            offset = (itemLength + interval) * (itemMaxSize - idx)
        end

        -- 位置 + 偏移
        if isVertical then
            itemPos.y = itemPos.y + offset
        else
            itemPos.x = itemPos.x + offset
        end


        -- 若 為 指定 起始偏移成員序號 則 設置 相關數值
        if startOffsetAtItemIdx == idx then
            startItemPosSize.pos = itemPos
            startItemPosSize.size = itemSizeRef
        end
            
        -- print(string.format("ITEM[%d] POS ========= %s, %s", idx, tostring(itemPos.x), tostring(itemPos.y)))

        -- 設置 該成員 位置
        pItemData.m_ptPosition = itemPos
        

        -- 若 還未超過 最大數
        if idx <= maxNodeCount then
            
            -- 建立
            local pItem = createCCB()

            -- 設置ID
            pItem.id = idx-1

            -- 尺寸
            local itemSize = pItem:getContentSize()

            -- 若 實際尺寸 超過 參考尺寸
            if itemSizeRef.height < itemSize.height then
                itemSizeRef.height = itemSize.height
            end
            if itemSizeRef.width < itemSize.width then
                itemSizeRef.width = itemSize.width
            end

            -- 加入 成員
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        
        -- 若 超過最大數
        else
            -- 直接加入(空資料?)
            container.m_pScrollViewFacade:addItem(pItemData)
        end

    end

    -- 內容 尺寸
    local contentSize = CCSizeMake(paddingLeft + paddingRight, paddingTop + paddingBottom)
    -- 總計 間隔
    local totalInterval = interval * (itemCount - 1)
    
    -- 依照 垂直/水平 計算 累加 成員與間隔長度
    if isVertical then
        contentSize.width = contentSize.width + itemSizeRef.width
        contentSize.height = contentSize.height + (itemSizeRef.height * itemCount) + totalInterval
    else
        contentSize.width = contentSize.width + (itemSizeRef.width * itemCount) + totalInterval
        contentSize.height = contentSize.height + itemSizeRef.height
    end

    -- 設置 滾動視圖 尺寸 為 內容尺寸
    container.mScrollView:setContentSize(contentSize)
    -- print(string.format("(itemSizeRef.height[%d] * itemCount[%d]) + totalInterval[%d]", itemSizeRef.height, itemCount, totalInterval))
    -- print(string.format("itemSizeRef %d,%d", itemSizeRef.width, itemSizeRef.height))
    -- print(string.format("contentSize %d,%d", contentSize.width, contentSize.height))
    -- print(string.format("scrollViewSize %d,%d", scrollViewSize.width, scrollViewSize.height))
    -- 設置 起始位置
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(0)

    -- 內容 位置 偏移
    local scrollViewContentOffset = startOffset
    -- print(string.format("scrollViewContentOffset x[%s], y[%s]", scrollViewContentOffset.x, scrollViewContentOffset.y))
    -- 若 有指定偏移至起始成員 則 依照 垂直/水平 與 正/反向 調整 至 指定起始成員的位置
    if startOffsetAtItemIdx ~= nil then
        if isVertical then
            if isAlignReverse then
                scrollViewContentOffset.y = startOffset.y + scrollViewSize.height - (startItemPosSize.pos.y + startItemPosSize.size.height)
                -- print(string.format("scrollViewSize.height[%s] - (startItemPosSize.pos.y[%s] + startItemPosSize.size.height[%s])", scrollViewSize.height, startItemPosSize.pos.y, startItemPosSize.size.height))
            else
                scrollViewContentOffset.y = startOffset.y + -startItemPosSize.pos.y
            end
        else   
            if isAlignReverse then
                scrollViewContentOffset.x = startOffset.x + scrollViewSize.width - (startItemPosSize.pos.x + startItemPosSize.size.width)
                -- print(string.format("scrollViewSize.width[%s] - (startItemPosSize.pos.x[%s] + startItemPosSize.size.width[%s])", scrollViewSize.width, startItemPosSize.pos.x, startItemPosSize.size.width))            else
            else
                scrollViewContentOffset.x = startOffset.x + -startItemPosSize.pos.x
            end
        end
    end

    -- 若 起始偏移 要保持安全位置
    if startOffsetSafe then
        -- 垂直
        if isVertical then
            local height_over = contentSize.height - scrollViewSize.height
            local top_over = (scrollViewContentOffset.y + contentSize.height) - scrollViewSize.height
            local bottom_over = -scrollViewContentOffset.y 
            -- 若 超過高度
            if height_over > 0 then
                -- 底部 未達邊界 則 倒回
                if bottom_over < 0 then
                    scrollViewContentOffset.y = - (-bottom_over)
                -- 頂部 未達邊界 則 推進
                elseif top_over < 0 then
                    scrollViewContentOffset.y = - top_over
                end
            -- 若 未超過高度
            else
                -- 依照是否反向靠齊 貼向 要靠齊的邊界
                if isAlignReverse then
                    scrollViewContentOffset.y = -height_over
                else
                    scrollViewContentOffset.y = 0
                end
            end

        -- 水平
        else
            local width_over = contentSize.width - scrollViewSize.width
            local right_over = (scrollViewContentOffset.x + contentSize.width) - scrollViewSize.width
            local left_over = -scrollViewContentOffset.x 
            -- 若 超過寬度
            if width_over > 0 then
                -- 左方 未達邊界 則 倒回
                if left_over < 0 then
                    scrollViewContentOffset.x = - (-left_over)
                -- 右方 未達邊界 則 推進
                elseif right_over < 0 then
                    scrollViewContentOffset.x = - right_over
                end
            -- 若 未超過寬度
            else
                -- 依照是否反向靠齊 貼向 要靠齊的邊界
                if isAlignReverse then
                    scrollViewContentOffset.x = -width_over
                else
                    scrollViewContentOffset.x = 0
                end
            end

        end
    end

    -- print(string.format("scrollViewContentOffset x[%s], y[%s]", scrollViewContentOffset.x, scrollViewContentOffset.y))
    container.mScrollView:setContentOffset(scrollViewContentOffset)

    -- 重計 子物件
    container.mScrollView:forceRecaculateChildren()
    
    -- 依照 是否超出容器尺寸 而 禁用操作
    local isTouchable = true
    if isDisableTouchWhenNotFull then
        -- 依照 垂直/水平 檢查是否 內容尺寸 超出 容器尺寸
        if isVertical then
            isTouchable = contentSize.height > scrollViewSize.height
        else
            isTouchable = contentSize.width > scrollViewSize.width
        end
    end
    -- 設置 是否可觸碰操作
    container.mScrollView:setTouchEnabled(isTouchable)

    -- 若 吞噬 觸碰
    if isSwallowTouches then
        ScriptMathToLua:setSwallowsTouches(container.mScrollView)
    end

    -- 設置 可否回彈
    container.mScrollView:setBounceable(isTouchable and isBounceable)
end


--[[ 組織 滾動視圖 Grid 左上至右下 橫向 ]]
-- 從 NodeHelper:buildScrollViewHorizontal2 中 改寫
function NodeHelperUZ:buildScrollViewGrid_LT2RB(container, size, ccbiFile, funcCallback, options)
    if size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then
        return
    end

    local createCCB
    local ccbiFileType = type(ccbiFile)
    if ccbiFileType == "string" then
        createCCB = function (idx)
            local pItem = ScriptContentBase:create(ccbiFile)
            -- 註冊行為
            pItem:registerFunctionHandler(funcCallback)
            return pItem
        end
    elseif ccbiFileType == "function" then
        createCCB = function (idx)
            return ccbiFile(idx, funcCallback)
        end
    end

    -- 間隔
    local interval = options["interval"]
    if interval == nil then interval = ccp(0, 0) end

    -- 欄 數
    local colMax = options["colMax"]
    if colMax == nil then colMax = 5 end

    local isAlignReverse = true

    -- 起始位置偏移
    local startOffset = options["startOffset"]
    if startOffset == nil then startOffset = ccp(0, 0) end
    
    -- 起始位置偏移 成員序號
    local startOffsetAtItemIdx = options["startOffsetAtItemIdx"]
    -- 起始位置 安全模式
    local startOffsetSafe = options["startOffsetSafe"]
    if startOffsetSafe == nil then startOffsetSafe = true end

    -- 是否靠齊中央 (垂直靠齊中央只有在一行未滿欄位數量時有作用)
    local isAlignCenterHorizontal = options["isAlignCenterHorizontal"]
    if isAlignCenterHorizontal == nil then isAlignCenterHorizontal = false end
    local isAlignCenterVertical = options["isAlignCenterVertical"]
    if isAlignCenterVertical == nil then isAlignCenterVertical = false end

    -- 內距
    local paddingLeft = options["paddingLeft"]
    if paddingLeft == nil then paddingLeft = 0 end
    local paddingRight = options["paddingRight"]
    if paddingRight == nil then paddingRight = 0 end
    local paddingTop = options["paddingTop"]
    if paddingTop == nil then paddingTop = 0 end
    local paddingBottom = options["paddingBottom"]
    if paddingBottom == nil then paddingBottom = 0 end

    -- 是否 在內容超出容器時 禁用操作 (可能無效，不知道為什麼)
    local isDisableTouchWhenNotFull = options["isDisableTouchWhenNotFull"]
    if isDisableTouchWhenNotFull == nil then isDisableTouchWhenNotFull = true end

    -- 是否 吞噬 觸碰
    local isSwallowTouches = options["isSwallowTouches"]
    if isSwallowTouches == nil then isSwallowTouches = true end
    
    -- 是否 可回彈
    local isBounceable = options["isBounceable"]
    if isBounceable == nil then isBounceable = true end

    -- 容器 尺寸
    local scrollViewSize = options["originScrollViewSize"]
    if scrollViewSize == nil then scrollViewSize = container:getContentSize() end
    -- print(string.format("scrollViewSize %s, %s", scrollViewSize.width, scrollViewSize.height))

    -- 最大總數
    local maxNodeCount = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    
    -- 當前數量
    local currCount = 0

    -- 成員尺寸
    local itemSize = CCSizeMake(0, 0)
    
    -- 行數
    local rowCount = math.ceil(size / colMax)
    -- 欄數
    local colCount = colMax

    -- 起始成員 尺寸 位置
    local startItemPosSize = {
        size = CCSizeMake(0,0),
        pos = ccp(0, 0)
    }

    -- 最後一行 剩餘的成員數量
    local lastRowLeft = size % colMax

    -- 每個成員
    for idx = 1, size do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = idx
        pItemData.m_iIdx = idx

        -- 成員位置
        local itemPos = ccp(0, 0)

        -- 若還在 最大總數 內
        if currCount < maxNodeCount then
            
            -- 建立
            local pItem = createCCB(idx)

            -- 設置ID
            pItem.id = currCount

            -- 取得尺寸
            local pItemSize = pItem:getContentSize()

            if  options.ItemScale then
                pItem:setScale(options.ItemScale)
            end

            -- 紀錄 成員尺寸
            if itemSize.height < pItemSize.height then
                itemSize.height = pItemSize.height * pItem:getScaleY()
            end
            if itemSize.width < pItemSize.width then
                itemSize.width = pItemSize.width * pItem:getScaleX()
            end

            -- print(string.format("itemSize[%s, %s]", tostring(itemSize.width), tostring(itemSize.height)))

            -- 判斷 行數 / 欄數
            local row = math.ceil(idx / colMax)
            local col = (idx % colMax == 0 and colMax or idx % colMax)
            
            -- 預設 位置
            itemPos.x = (itemSize.width + interval.x) * (col - 1)
            itemPos.y = (itemSize.height + interval.y) * (rowCount - row)

            -- 加上 內距
            itemPos.x = itemPos.x + paddingLeft
            itemPos.y = itemPos.y + paddingBottom

            -- 若 置中 處理
            if isAlignCenterHorizontal then
                -- 該成員 在 最後一行中的 位置
                local idxInLastRowLeft = lastRowLeft - (size-idx)
                -- 若 在最後一行中
                if idxInLastRowLeft > 0 then
                    
                    -- 取 序號偏移數 為 最後一行中心 到 該成員 的 差距
                    local idxOffset = idxInLastRowLeft - ((lastRowLeft+1)/2)
                    -- print(string.format("lastRowLeft:%s, idxInLastRowLeft:%s, idxOffset:%s", lastRowLeft, idxInLastRowLeft, idxOffset))
                    -- print(string.format(
                    --     "(idxOffset[%s] * (itemSize.width[%s] + interval.x[%s]) - (itemSize.width/2[%s] = %s",
                    --     idxOffset, itemSize.width, interval.x, (itemSize.width/2), (idxOffset * (itemSize.width + interval.x))
                    -- ))
                    -- 設 X位置 為 視圖中心 + 物件偏移(物件+間隔) 並 調整位置於成員中心
                    itemPos.x = (scrollViewSize.width / 2) + (idxOffset * (itemSize.width + interval.x)) - (itemSize.width/2)
                end
            end

            if isAlignCenterVertical then
                -- 若 僅有一行
                if rowCount == 1 then
                    local idxOffset = row - ((rowCount+1)/2)
                    -- 置中 上下位置
                    itemPos.y = (scrollViewSize.height / 2) + (idxOffset * (itemSize.height + interval.y)) - (itemSize.height / 2)
                end
            end

            
            -- print(string.format("item[%s] %s,%s",currCount, itemPos.x, itemPos.y))
            
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        pItemData.m_ptPosition = itemPos

        -- 若 為 指定 起始偏移成員序號 則 設置 相關數值
        if startOffsetAtItemIdx == idx then
            startItemPosSize.pos = itemPos
            startItemPosSize.size = itemSize
        end

        currCount = currCount + 1
    end

    if currCount < colMax then colCount = currCount end

    -- 內容 尺寸
    local contentSize = CCSizeMake(
        (itemSize.width  * colCount) + (interval.x * (colCount - 1)) + paddingLeft + paddingRight,
        (itemSize.height * rowCount) + (interval.y * (rowCount - 1)) + paddingTop + paddingBottom
    )

    if contentSize.width < scrollViewSize.width then
        contentSize.width = scrollViewSize.width
    end

    if isAlignCenterVertical then
        if contentSize.height < scrollViewSize.height then
            contentSize.height = scrollViewSize.height
        end
    end

    container.mScrollView:setContentSize(contentSize)
    -- print(string.format("itemWidth[%s] * %s  +  interval.x[%s] * %s", itemSize.width, colCount, interval.x, colCount-1))
    -- print(string.format("contentSize %s, %s", contentSize.width, contentSize.height))
    container.mScrollView:setAnchorPoint(ccp(0, 1))
    -- 內容 位置 偏移
    local scrollViewContentOffset = startOffset
    if startOffsetAtItemIdx ~= nil then
        -- print(string.format("startOffset.y[%s] + scrollViewSize.height[%s] ", startOffset.y, scrollViewSize.height ))
        -- print(string.format("startItemPosSize[%s] (%s, %s) [%s, %s]", 
        --     tostring(startOffsetAtItemIdx),
        --     startItemPosSize.pos.x, startItemPosSize.pos.y,
        --     startItemPosSize.size.width, startItemPosSize.size.height
        -- ))
        scrollViewContentOffset.y = startOffset.y + scrollViewSize.height - (startItemPosSize.pos.y + startItemPosSize.size.height)
        -- print("scrollViewContentOffset.y : "..tostring(scrollViewContentOffset.y))
    end

    -- 若 起始偏移 要保持安全位置
    if startOffsetSafe then

        local height_over = contentSize.height - scrollViewSize.height
        local top_over = (scrollViewContentOffset.y + contentSize.height) - scrollViewSize.height
        local bottom_over = -scrollViewContentOffset.y 
        
        local width_over = contentSize.width - scrollViewSize.width
        local right_over = (scrollViewContentOffset.x + contentSize.width) - scrollViewSize.width
        local left_over = -scrollViewContentOffset.x 
        
        -- 若 超過高度
        if height_over > 0 then
            -- 底部 未達邊界 則 倒回
            if bottom_over < 0 then
                scrollViewContentOffset.y = - (-bottom_over)
            -- 頂部 未達邊界 則 推進
            elseif top_over < 0 then
                scrollViewContentOffset.y = - top_over
            end
        -- 若 未超過高度
        else
            -- 依照是否反向靠齊 貼向 要靠齊的邊界
            if isAlignReverse then
                scrollViewContentOffset.y = -height_over
            else
                scrollViewContentOffset.y = 0
            end
        end

        -- 若 超過寬度
        if width_over > 0 then
            -- 左方 未達邊界 則 倒回
            if left_over < 0 then
                scrollViewContentOffset.x = - (-left_over)
            -- 右方 未達邊界 則 推進
            elseif right_over < 0 then
                scrollViewContentOffset.x = - right_over
            end
        -- 若 未超過寬度
        else
            -- 依照是否反向靠齊 貼向 要靠齊的邊界
            if isAlignReverse then
                scrollViewContentOffset.x = -width_over
            else
                scrollViewContentOffset.x = 0
            end
        end
    end

    container.m_pScrollViewFacade:setDynamicItemsStartPosition(0)
    container.mScrollView:setContentOffset(scrollViewContentOffset)
    container.mScrollView:setViewSize(scrollViewSize)
    -- print(string.format("scrollViewContentOffset %s, %s", scrollViewContentOffset.x, scrollViewContentOffset.y))
    container.mScrollView:forceRecaculateChildren()

    -- 依照 是否超出容器尺寸 而 禁用操作
    local isTouchable = true
    if isDisableTouchWhenNotFull then
        -- 檢查是否 內容尺寸 超出 容器尺寸
        isTouchable = contentSize.height > scrollViewSize.height
        -- print(string.format("contentSize.height[%s] scrollViewSize.height[%s]", contentSize.height, scrollViewSize.height))
    end
    
    -- 設置 是否可觸碰操作
    container.mScrollView:setTouchEnabled(isTouchable)
    
    -- 若 吞噬 觸碰
    if isSwallowTouches then
        ScriptMathToLua:setSwallowsTouches(container.mScrollView)
    end

    -- 設置 可否回彈
    container.mScrollView:setBounceable(isTouchable and isBounceable)
end




return NodeHelperUZ