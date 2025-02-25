local SliderHelper = {}

-- 創建滑塊的方法
function SliderHelper:createSlider(option)
    -- 驗證參數
    if not option or not option.bgFile or not option.progressFile or not option.thumbFile then
        error("SliderHelper:createSlider requires bgFile, progressFile, and thumbFile in option!")
    end

    -- 創建滑塊
    local slider = CCControlSlider:create(option.bgFile, option.progressFile, option.thumbFile)
    slider:setPosition(option.position or ccp(0, 0))  -- 設置滑塊位置，默認為 (0, 0)
    slider:setMinimumValue(option.minValue or 0)     -- 設置最小值，默認為 0
    slider:setMaximumValue(option.maxValue or 100)   -- 設置最大值，默認為 100
    slider:setValue(option.initialValue or 0)        -- 設置初始值，默認為 0

    -- 保存步長到滑塊對象
    slider.step = tonumber(option.step) or 1

    -- 將滑塊添加到父節點
    if option.parentNode then
        option.parentNode:addChild(slider)
    end

    -- 返回滑塊對象
    return slider
end

-- 動態監控滑塊值變化，並吸附到指定步長
function SliderHelper:monitorSliderValue(slider, callback)
    local step = slider.step or 1 -- 默認步長為 1
    local lastValue = slider:getValue()
    slider:scheduleUpdateWithPriorityLua(function(dt)
        local currentValue = slider:getValue()
        -- 計算吸附到步長的值
        local snappedValue = math.floor((currentValue + step / 2) / step) * step
        if snappedValue ~= lastValue then
            lastValue = snappedValue
            slider:setValue(snappedValue) -- 將滑塊值設置為步長的倍數
            if callback then
                callback(snappedValue)
            end
        end
    end, 0)
end

return SliderHelper
