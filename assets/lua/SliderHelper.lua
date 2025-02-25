local SliderHelper = {}

-- �Ыطƶ�����k
function SliderHelper:createSlider(option)
    -- ���ҰѼ�
    if not option or not option.bgFile or not option.progressFile or not option.thumbFile then
        error("SliderHelper:createSlider requires bgFile, progressFile, and thumbFile in option!")
    end

    -- �Ыطƶ�
    local slider = CCControlSlider:create(option.bgFile, option.progressFile, option.thumbFile)
    slider:setPosition(option.position or ccp(0, 0))  -- �]�m�ƶ���m�A�q�{�� (0, 0)
    slider:setMinimumValue(option.minValue or 0)     -- �]�m�̤p�ȡA�q�{�� 0
    slider:setMaximumValue(option.maxValue or 100)   -- �]�m�̤j�ȡA�q�{�� 100
    slider:setValue(option.initialValue or 0)        -- �]�m��l�ȡA�q�{�� 0

    -- �O�s�B����ƶ���H
    slider.step = tonumber(option.step) or 1

    -- �N�ƶ��K�[����`�I
    if option.parentNode then
        option.parentNode:addChild(slider)
    end

    -- ��^�ƶ���H
    return slider
end

-- �ʺA�ʱ��ƶ����ܤơA�çl������w�B��
function SliderHelper:monitorSliderValue(slider, callback)
    local step = slider.step or 1 -- �q�{�B���� 1
    local lastValue = slider:getValue()
    slider:scheduleUpdateWithPriorityLua(function(dt)
        local currentValue = slider:getValue()
        -- �p��l����B������
        local snappedValue = math.floor((currentValue + step / 2) / step) * step
        if snappedValue ~= lastValue then
            lastValue = snappedValue
            slider:setValue(snappedValue) -- �N�ƶ��ȳ]�m���B��������
            if callback then
                callback(snappedValue)
            end
        end
    end, 0)
end

return SliderHelper
