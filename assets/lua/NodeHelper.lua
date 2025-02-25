local NodeHelper = { }
------------local variable for system api--------------------------------------
local tostring = tostring
local tonumber = tonumber
local string = string
local pairs = pairs
local titleTag = 1000
local editBoxTag = 2000

--------------------------------------------------------------------------------
function NodeHelper:calcAdjustResolutionOffY()
    -- local logicSize = ccp(640,960)
    local logicSize = ccp(GameConfig.ScreenSize.width, GameConfig.ScreenSize.height)
    local realSize = CCEGLView:sharedOpenGLView():getDesignResolutionSize()
    local offY = realSize.height - logicSize.y
    return offY
end

function NodeHelper:autoAdjustResizeScrollview(scrollView)
    if not scrollView then
        return
    end
    local offY = self:calcAdjustResolutionOffY()
    local oldSize = scrollView:getViewSize()
    oldSize.height = oldSize.height + offY
    scrollView:setViewSize(oldSize)
end

function NodeHelper:autoAdjustResizeScale9Sprite(scale9Sprite)
    if not scale9Sprite then
        return
    end
    local offY = self:calcAdjustResolutionOffY()
    local oldSize = scale9Sprite:getContentSize()
    oldSize.height = oldSize.height + offY
    scale9Sprite:setContentSize(oldSize)
end

function NodeHelper:autoAdjustResizeNodeSize(node)
    if not node then
        return
    end
    local offY = self:calcAdjustResolutionOffY()
    local oldSize = node:getContentSize()
    oldSize.height = oldSize.height + offY
    node:setContentSize(oldSize)
end

function NodeHelper:setNodePosition(node, x, y)
    if node then
        node:setPositionX(x)
        node:setPositionY(y)
    end
end

function NodeHelper:autoAdjustResetNodePosition(node, offsetRate)
    offsetRate = offsetRate or 1
    if not node then
        return
    end
    local offY = self:calcAdjustResolutionOffY()
    local oldPosY = node:getPositionY()
    oldPosY = oldPosY - offY * offsetRate
    node:setPositionY(oldPosY)
    return oldPosY
end

function NodeHelper:getAdjustBgScale(pageType)
    local logicSize = ccp(GameConfig.ScreenSize.width, GameConfig.ScreenSize.height)
    local realSize = CCEGLView:sharedOpenGLView():getDesignResolutionSize()
    local offY = realSize.height - logicSize.y
    local scale = 1
    if pageType == 0 then
        -- 非全屏
        scale = offY / realSize.height + 1
    elseif pageType == 1 then
        -- 全屏
        scale = offY / logicSize.y + 1
    end

    return scale

    --    if realSize.height/realSize.width >  logicSize.y /logicSize.x then
    --         return scale
    --    end
    --    return 1
end
function NodeHelper:setNodeOffset(node, offset_x, offset_y)
    local posX, posY = node:getPosition()
    local pos = ccp(posX + offset_x, posY + offset_y)
    node:setPosition(pos)

end


function NodeHelper:getScaleProportion()
    local vissibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local width, height = vissibleSize.width, vissibleSize.height
    local rate = height / width
    local desighRate = GameConfig.ScreenSize.height / GameConfig.ScreenSize.width
    rate = rate / desighRate * 1.0
    if rate < 1 then
        rate = 1
    end
    return rate
end

function NodeHelper:getTargetScaleProportion(height, width)
    local vissibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local vWidth, vHeight = vissibleSize.width, vissibleSize.height
    local rate = vHeight / vWidth
    local desighRate = height / width
    rate = rate / desighRate * 1.0
    if rate < 1 then
        rate = 1
    end
    return rate
end

function NodeHelper:setParentSize(child, size)
    if child then
        local parent = child:getParent()
        if parent then
            parent:setContentSize(size)
        end
    end
end

local ViewHolder = { }
function NodeHelper:setStringForLabel(container, strMap)
    if container == nil or strMap == nil then
        CCLuaLog("Error in NodeHelper:setStringForLabel==> container is nil")
        return
    end
    for name, str in pairs(strMap) do
        local node = container:getVarLabelBMFont(name)
        if node then
            node:setString(tostring(str))
        else
            local nodeTTF = container:getVarLabelTTF(name)
            if nodeTTF then
                nodeTTF:setString(tostring(str))
            else
                -- CCLuaLog("NodeHelper:setStringForLabel====>" .. name)		
            end

        end
    end
end

function NodeHelper:setLabelWidthForLineBreak(container, strMap, width)
    for name, str in pairs(strMap) do
        local htmlNode = container:getVarLabelBMFont(name)
        if htmlNode then
            htmlNode:setVisible(false)
            local htmlLabel = self:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(width, 48), str)
            htmlLabel:setScaleX(htmlNode:getScaleX())
            htmlLabel:setScaleY(htmlNode:getScaleY())
            return htmlLabel
        end
    end
    --[[
	for name, str in pairs(strMap) do
		local node = container:getVarLabelBMFont(name)
		if node then
			node:setLineBreakWithoutSpace(true)
			node:setWidth(width)
		else
			local nodeTTF=container:getVarLabelTTF(name)
			if nodeTTF then
				nodeTTF:setDimensions(CCSizeMake(width, 0)); --设置显示区域
				nodeTTF:setHorizontalAlignment(kCCTextAlignmentLeft);
				nodeTTF:setVerticalAlignment(kCCVerticalTextAlignmentTop)
			else
				CCLuaLog("NodeHelper:setLabelWidthForLineBreak====>" .. name)		
			end

		end
	end
	--]]
end

function NodeHelper:setStringForTTFLabel(container, strMap)
    for name, str in pairs(strMap) do
        local node = container:getVarLabelTTF(name)
        if node then
            node:setString(tostring(str))
        else
            CCLuaLog("NodeHelper:setStringForTTFLabel====>" .. name)
        end
    end
end

function NodeHelper:setColorForLabel(container, colorMap)
    for name, colorName in pairs(colorMap) do
        local node = container:getVarLabelBMFont(name)
        if node then
            -- local color3B = self:_getColorFromSetting("0,0,0")    --临时改成黑色
            local color3B = self:_getColorFromSetting(colorName)
            node:setColor(color3B)
        else
            local nodeTTF = container:getVarLabelTTF(name)
            if nodeTTF then
                local color3B = self:_getColorFromSetting(colorName)
                -- local color3B = self:_getColorFromSetting("0,0,0")    --临时改成黑色
                nodeTTF:setColor(color3B)
            else
                CCLuaLog("NodeHelper:setStringForLabel====>" .. name)
            end
        end
    end
end

function NodeHelper:setColorForLayerColor(container, colorMap)
    --[[
	for name, colorName in pairs(colorMap) do		
		local node = container:getVarLayerColor(name)
		if node then
			local color3B = self:_getColorFromSetting(colorName);
			node:setColor(color3B);
		else
			CCLuaLog("NodeHelper:setStringForLayerColor====>" .. name)		
		end
	end
	--]]
end

function NodeHelper:_getColorFromSetting(colorName)
    local color3B = StringConverter:parseColor3B(colorName)
    return color3B
end

function NodeHelper:setQualityColor(node, quality)
    if node == nil then
        CCLuaLog("Error in NodeHelper:setQualityColor==> node is nil")
        return
    end

    quality = NodeHelper:getQuality(quality)

    local color = self:getSettingVar("FrameColor_Quality" .. quality)
    local color3B = StringConverter:parseColor3B(color)
    node:setColor(color3B)
end

function NodeHelper:setMenuItemQuality(container, itemName, quality, isElement)
    local isElement = isElement or 0
    self:setQualityFrames(container, { [itemName] = quality }, isElement)
end

-- this function is not used
function NodeHelper:setFrameQuality(node, quality)
    if node == nil then
        CCLuaLog("Error in NodeHelper:setFrameQuality==> node is nil")
        return
    end

    quality = NodeHelper:getQuality(quality)

    node:setNormalImage(getFrameNormalSpirte(quality))
    node:setSelectedImage(getFrameSelectedSpirte(quality))
end
function NodeHelper:FunSetLinefeed( strText, nLineWidth )		--文本，行宽
	--读取每个字符做中文英文判断，并且记录大小
	local nStep = 1
	local index = 1
	local ltabTextSize = {}
	while true do
		c = string.sub(strText, nStep, nStep)
		b = string.byte(c)
 
		if b > 128 then
			ltabTextSize[index] = 3
			nStep = nStep + 3
			index = index + 1
		else
			ltabTextSize[index] = 1
			nStep = nStep + 1
			index = index + 1
		end
 
		if nStep > #strText then
			break
		end
	end
	
	--将字符按照限定行宽进行分组
	local nLineCount = 1
	local nBeginPos = 1
	local lptrCurText = nil
	local ltabText = {}
	local nCurSize = 0
	for i = 1, index - 1 do
		nCurSize = nCurSize + ltabTextSize[i]
		if nCurSize > nLineWidth and nLineCount< math.ceil(#strText/nLineWidth) then
			nCurSize = nCurSize - ltabTextSize[i]
			ltabText[nLineCount] = string.sub( strText, nBeginPos, nBeginPos + nCurSize - 1 )
			nBeginPos = nBeginPos + nCurSize
			nCurSize = ltabTextSize[i]
			nLineCount = nLineCount + 1
		end
        if nLineCount == math.ceil(#strText/nLineWidth) then
			ltabText[nLineCount] = string.sub( strText, nBeginPos, #strText)
        end
	end
	-- for i = 1, nLineCount - 1 do 
    for i = 1, nLineCount  do 
		if lptrCurText == nil then
			lptrCurText = ltabText[i]
		else
			lptrCurText = lptrCurText .. "\n" .. ltabText[i]
		end
	end
	return lptrCurText
end
function NodeHelper:setQualityBMFontLabels(container, qualityMap)
    local GameConfig = require("GameConfig")
    for frameName, quality in pairs(qualityMap) do
        local node = container:getVarLabelBMFont(frameName)
        if node == nil then
            CCLuaLog("Error in NodeHelper:setLabelsQuality==> node is nil")
        else
            local colorName = GameConfig.QualityColor[tonumber(quality)]
            local color3B = self:_getColorFromSetting(colorName)
            node:setColor(color3B)
        end
    end
end

function NodeHelper:setQualityBMFontLabels_deep(container, qualityMap)
    local GameConfig = require("GameConfig")
    for frameName, quality in pairs(qualityMap) do
        local node = container:getVarLabelBMFont(frameName)
        if node == nil then
            CCLuaLog("Error in NodeHelper:setLabelsQuality==> node is nil")
        else
            local colorName = GameConfig.QualityColor_deep[tonumber(quality)]
            local color3B = self:_getColorFromSetting(colorName)
            node:setColor(color3B)
        end
    end
end

function NodeHelper:getImageByQuality(quality, isElement)
    local GameConfig = require("GameConfig")
    local isElement = isElement or 0
    if isElement == 0 then
        local normalImage = GameConfig.QualityImage[tonumber(quality)]
        if normalImage == nil then
            normalImage = GameConfig.QualityImage[1]
        end
        return normalImage
    elseif isElement == 1 then
        local normalImage = GameConfig.ElementQualityImage[tonumber(quality)]
        if normalImage == nil then
            normalImage = GameConfig.ElementQualityImage[1]
        end
        return normalImage
    end
end
function NodeHelper:getImageBgByQuality(quality, isElement)
    local GameConfig = require("GameConfig")
    local isElement = isElement or 0
    if isElement == 0 then
        local normalImage = GameConfig.QualityImageBG[tonumber(quality)]
        if normalImage == nil then
            normalImage = GameConfig.QualityImageBG[1]
        end
        return normalImage
    elseif isElement == 1 then
        local normalImage = GameConfig.ElementQualityImage[tonumber(quality)]
        if normalImage == nil then
            normalImage = GameConfig.ElementQualityImage[1]
        end
        return normalImage
    end
end

function NodeHelper:setQualityFrames(container, qualityMap, isElement, notSetFrameBackImg)
    for frameName, quality in pairs(qualityMap) do
        if not notSetFrameBackImg then
            if tonumber(string.sub(frameName, -1, -1)) then
                NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. string.sub(frameName, - 1, - 1)] = quality })
            else
                NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade"] = quality })
            end
        end

        local node = container:getVarMenuItemImage(frameName)
        if node == nil then
            node = container:getVarSprite(frameName)
            if node == nil then
                CCLuaLog("Error in NodeHelper:setFrameQuality==> node is nil")
            else
                local normalImage = self:getImageByQuality(quality, isElement)
                node:setTexture(normalImage)
            end
        else
            local isElement = isElement or 0
            local normalImage = self:getImageByQuality(quality, isElement)
            node:setNormalImage(CCSprite:create(normalImage))
        end
    end
end

function NodeHelper:setMercenaryQualityFrames(container, qualityMap, isElement, notSetFrameBackImg)
    for frameName, quality in pairs(qualityMap) do
        if not notSetFrameBackImg then
            if tonumber(string.sub(frameName, -1, -1)) then
                NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. string.sub(frameName, - 1, - 1)] = quality })
            else
                NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade"] = quality })
            end
        end

        local node = container:getVarMenuItemImage(frameName)
        if node == nil then
            node = container:getVarSprite(frameName)
            if node == nil then
                CCLuaLog("Error in NodeHelper:setFrameQuality==> node is nil")
            else
                local normalImage = self:getImageByQuality(quality + 16, isElement)
                node:setTexture(normalImage)
            end
        else
            local isElement = isElement or 0
            local normalImage = self:getImageByQuality(quality + 16, isElement)
            node:setNormalImage(CCSprite:create(normalImage))
        end
    end
end

function NodeHelper:setImgBgQualityFrames(container, qualityMap, isElement)
    for frameName, quality in pairs(qualityMap) do
        local node = container:getVarSprite(frameName)
        -- container:getVarMenuItemImage(frameName);
        if node == nil then
            CCLuaLog("Error in NodeHelper:setFrameQuality==> node is nil")
        else
            local isElement = isElement or 0
            local normalImage = self:getImageBgByQuality(quality, isElement)
            node:setTexture(tostring(normalImage))
        end
    end
end
function NodeHelper:setImgQualityFrames(container, qualityMap, isElement)
    for frameName, quality in pairs(qualityMap) do
        local node = container:getVarSprite(frameName)
        -- container:getVarMenuItemImage(frameName);
        if node == nil then
            CCLuaLog("Error in NodeHelper:setFrameQuality==> node is nil")
        else
            local isElement = isElement or 0
            local normalImage = self:getImageByQuality(quality, isElement)
            node:setTexture(tostring(normalImage))
        end
    end
end

function NodeHelper:setNormalImages(container, imgMap)
    for itemName, image in pairs(imgMap) do
        local menuItem = container:getVarMenuItemImage(itemName)
        if menuItem == nil then
            CCLuaLog("Error in NodeHelper:setFrameQuality==> menuItem is nil")
        else
            menuItem:setNormalImage(CCSprite:create(image))
        end
    end
end

function NodeHelper:setNormalImage(container, itemName, image)
    local menuItem = container:getVarMenuItemImage(itemName)
    if menuItem == nil then
        CCLuaLog("Error in NodeHelper:setNormalImage==> menuItem is nil")
    else
        menuItem:setNormalImage(CCSprite:create(image))
    end
end

function NodeHelper:setMenuItemSelected(container, selectedMap)
    for menuItemName, selected in pairs(selectedMap) do
        local item = container:getVarMenuItemImage(menuItemName)

        if item == nil then
            CCLuaLog("Error in NodeHelper:setMenuItemSelected==> node is nil")
        else
            if selected then
                item:selected()
            else
                item:unselected()
            end
        end
    end
end

function NodeHelper:setNodeScale(container, name, scaleX, scaleY)
    if container == nil then
        return
    end
    local node = container:getVarNode(name)

    if node ~= nil then
        local scaleX = scaleX or node:getScaleX()
        local scaleY = scaleY or node:getScaleY()

        node:setScaleX(scaleX)
        node:setScaleY(scaleY)
    end
end

function NodeHelper:setLabelOneByOne(container, name1, name2, gap, isR2Gap)
    if container == nil then
        return
    end
    local isRealGap = isR2Gap or false
    local gap = gap or 0
    if Golb_Platform_Info.is_r2_platform then
        if isRealGap then
            gap = gap
        else
            gap = 0
        end
    end
    local label1 = container:getVarNode(name1)
    local label2 = container:getVarNode(name2)

    if label1 ~= nil and label2 ~= nil then
        local AnchorPoint1 = label1:getAnchorPoint().x
        local AnchorPoint2 = label2:getAnchorPoint().x
        local controlGap1 = (label1:getContentSize().width * label1:getScaleX()) * AnchorPoint1
        local controlGap2 = (label2:getContentSize().width * label2:getScaleX()) * AnchorPoint2
        label2:setPositionX(label1:getPositionX() + label1:getContentSize().width * label1:getScaleX() - controlGap1 + controlGap2 + gap)
    end
end
function NodeHelper:setLabelOneByOneRight(container, name1, name2, gap, isR2Gap)
    if container == nil then
        return
    end
    local gap = gap or 0

    local label1 = container:getVarNode(name1)
    local label2 = container:getVarNode(name2)
    if label1 ~= nil and label2 ~= nil then
        local AnchorPoint1 = label1:getAnchorPoint().x
        local AnchorPoint2 = label2:getAnchorPoint().x
        local controlGap1 = (label1:getContentSize().width * label1:getScaleX()) * AnchorPoint1
        local controlGap2 = (label2:getContentSize().width * label2:getScaleX()) * (1 - AnchorPoint2)
        label2:setPositionX(label1:getPositionX() - controlGap1 - controlGap2 - gap)
    end
end
function NodeHelper:getQuality(quality)
    if quality > QualityInfo.MaxQuality or quality < QualityInfo.MinQuality then
        quality = QualityInfo.NoQuality
    end
    return quality
end

function NodeHelper:setScaleByResInfoType(node, itemType, NodeHelperScale)
    if node == nil then
        CCLuaLog("node is Null for set scale")
        return
    end

    itemType = tonumber(itemType or 0)
    local resType = ResManagerForLua:getResMainType(itemType)
    local scale = NodeHelperScale or 0.4

    if resType == DISCIPLE_TYPE or resType == DISCIPLE_BOOK then
        scale = scale * 3.0
    end
    node:setScale(scale)
end

function NodeHelper:setMenuEnabled(menuItem, isEnabled)
    if menuItem then
        menuItem:setEnabled(isEnabled)
    end
end

function NodeHelper:setMenuItemEnabled(container, menuItemName, isEnabled)
    local item = container:getVarMenuItemImage(menuItemName)

    if item ~= nil then
        item:setEnabled(isEnabled)
    end
end

-- 替换按钮禁用图
function NodeHelper:setMenuItemDisabledImage(container, imgMap)
    for itemName, image in pairs(imgMap) do
        local menuItem = container:getVarMenuItemImage(itemName)
        if menuItem == nil then
            CCLuaLog("Error in NodeHelper:setMenuItemSelectedImage==>" .. itemName)
        else
            menuItem:setDisabledImage(CCSprite:create(image))
        end
    end
end

-- 替换按钮资源
function NodeHelper:setMenuItemImage(container, imgMap)
    for itemName, imageList in pairs(imgMap) do
        local menuItem = container:getVarMenuItemImage(itemName)
        if menuItem == nil then
            CCLuaLog("Error in NodeHelper:setMenuItemSelectedImage==>" .. itemName)
        else
            if imageList.normal then
                local mSprite = CCSprite:create(imageList.normal)
                if mSprite then
                    menuItem:setNormalImage(mSprite)
                else
                    menuItem:setNormalImage(CCSprite:create("empty.png"))
                end
                -- menuItem:setNormalImage(imageList.normal)
            end
            if imageList.press then
                local mSprite = CCSprite:create(imageList.press)
                if mSprite then
                    menuItem:setSelectedImage(mSprite)
                else
                    menuItem:setSelectedImage(CCSprite:create("empty.png"))
                end
                -- menuItem:setSelectedImage(CCSprite:create(imageList.press));
            end
            if imageList.disabled then
                local mSprite = CCSprite:create(imageList.disabled)
                if mSprite then
                    menuItem:setDisabledImage(mSprite)
                else
                    menuItem:setDisabledImage(CCSprite:create("empty.png"))
                end
                -- menuItem:setDisabledImage(CCSprite:create(imageList.disabled))
            end
        end
    end
end 

-- 替换按钮选中图
function NodeHelper:setMenuItemSelectedImage(container, imgMap)
    for itemName, image in pairs(imgMap) do
        local menuItem = container:getVarMenuItemImage(itemName)
        if menuItem == nil then
            CCLuaLog("Error in NodeHelper:setMenuItemSelectedImage==>" .. itemName)
        else
            menuItem:setSelectedImage(CCSprite:create(image))
        end
    end
end

function NodeHelper:setMenuItemsEnabled(container, menuItemMap)
    for menuItemName, isEnabled in pairs(menuItemMap) do
        local menuItem = container:getVarMenuItem(menuItemName)
        if menuItem then
            menuItem:setEnabled(isEnabled)
        else
            CCLuaLog("Error:::NodeHelper:setMenuItemsEnabled====>" .. menuItemName)
        end
    end
end

function NodeHelper:setNodeVisible(node, isVisible)
    if node then
        node:setVisible(isVisible)
    end
end

function NodeHelper:setNodesVisible(container, visibleMap)
    for name, visible in pairs(visibleMap) do
        if container == nil then
            return
        end
        self:setNodeVisible(container:getVarNode(name), visible)
    end
end

function NodeHelper:mainFrameSetPointVisible(visibleMap)
    for nodeName, visible in pairs(visibleMap) do
        MainFrame:getInstance():setChildVisible(nodeName, visible)
    end
end

function NodeHelper:setSpriteImage(container, imgMap, scaleMap)
    local scaleMap = scaleMap or { }
    if container==nil then return end
    for spriteName, image in pairs(imgMap) do
        local sprite = container:getVarSprite(spriteName)
        if sprite then
            sprite:setTexture(tostring(image))
            if scaleMap[spriteName] then
                sprite:setScale(scaleMap[spriteName])
            end
        else
            CCLuaLog("Error:::NodeHelper:setSpriteImage====>" .. spriteName)
        end
    end
end

function NodeHelper:setScale9SpriteImage(container, imgMap, capInsets, sizeMap)
    local scaleMap = scaleMap or { }
    for spriteName, image in pairs(imgMap) do
        local sprite = container:getVarScale9Sprite(spriteName)

        if sprite then
            local frame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(image.name)
            if frame == nil then
                frame = CCSpriteFrame:create(image.name, image.rect)
            end

            if frame then
                -- frame:setRect(image.rect)
                -- :setAntiAliasTexParameters()
                --                local texture = frame:getTexture()

                --                texture:generateMipmap()

                --                local tp = ccTexParams()
                --                tp.minFilter = GL_LINEAR_MIPMAP_LINEAR
                --                tp.magFilter = GL_LINEAR
                --                tp.wrapS = GL_CLAMP_TO_EDGE
                --                tp.wrapT = GL_CLAMP_TO_EDGE
                --                texture:setTexParameters(tp)

                sprite:setSpriteFrame(frame)
                if capInsets[spriteName] then
                    local capTable = capInsets[spriteName]
                    if capTable.left then
                        sprite:setInsetLeft(capTable.left)
                    end
                    if capTable.right then
                        sprite:setInsetRight(capTable.right)
                    end
                    if capTable.top then
                        sprite:setInsetTop(capTable.top)
                    end
                    if capTable.bottom then
                        sprite:setInsetBottom(capTable.bottom)
                    end
                end
                if sizeMap[spriteName] then
                    sprite:setContentSize(sizeMap[spriteName])
                end
            end
        else
            CCLuaLog("Error:::NodeHelper:setSpriteImage====>" .. spriteName)
        end
    end
end
function NodeHelper:setScale9SpriteImage2(container, imgMap)
    for spriteName, image in pairs(imgMap) do
        local CCSprite= CCSprite:create(image)
        local sprite=tolua.cast(container:getVarNode(spriteName), "CCScale9Sprite")
        if CCSprite and sprite then
            sprite:setSpriteFrame(CCSprite:displayFrame())
        end
    end
end
function NodeHelper:setScale9SpriteBar(container,NodeName,selfData,MaxData,defaultWidth)
    if not container then return end
    if tonumber (MaxData) == nil then MaxData =1 end
    local Scale = selfData / tonumber(MaxData) or 0
    if Scale>1 then Scale=1 end
    local Bar = tolua.cast(container:getVarNode(NodeName), "CCScale9Sprite")
    Bar:setContentSize(CCSize(defaultWidth * Scale, Bar:getContentSize().height))
    if selfData==0 then
        NodeHelper:setNodesVisible(container,{[NodeName]=false})
    else
        NodeHelper:setNodesVisible(container,{[NodeName]=true})
    end
end
function NodeHelper:setHeadIcon(container, spriteName, imgName, nTargetSize)
    -- 88*88
    local sprite = container:getVarSprite(spriteName)
    if sprite then
        sprite:setVisible(true)
        sprite:setTexture(imgName)
        local contentSize = sprite:getContentSize()
        local width = contentSize.width
        local height = contentSize.height
        local scaleX = nTargetSize / width
        local scaleY = nTargetSize / height
        sprite:setScaleX(scaleX)
        sprite:setScaleY(scaleY)
    end
end
function NodeHelper:createTouchLayerByScrollView(container, onTouchBegin, onTouchMove, onTouchEnd, onTouchCancel, isScrollViewTouch)
    local MultiColumnScrollViewHelper = require("MultiColumnScrollViewHelper")

    onTouchBegin = onTouchBegin or MultiColumnScrollViewHelper.onTouchBegin
    onTouchMove = onTouchMove or MultiColumnScrollViewHelper.onTouchMove
    onTouchEnd = onTouchEnd or MultiColumnScrollViewHelper.onTouchEnd
    onTouchCancel = onTouchCancel or MultiColumnScrollViewHelper.onTouchCancel

    isScrollViewTouch = isScrollViewTouch or false
    local layer = container.mScrollView:getParent():getChildByTag(51001)
    if not layer then
        layer = CCLayer:create()
        layer:setTag(51001)
        container.mScrollView:getParent():addChild(layer)
        layer:setContentSize(CCSize(container.mScrollView:getViewSize().width, container.mScrollView:getViewSize().height))
        layer:setPosition(container.mScrollView:getPosition())
        layer:setAnchorPoint(container.mScrollView:getAnchorPoint())
        layer:registerScriptTouchHandler(function(eventName, pTouch)
            if eventName == "began" then
                if onTouchBegin then
                    onTouchBegin(container, eventName, pTouch)
                end
            elseif eventName == "moved" then
                if onTouchMove then
                    onTouchMove(container, eventName, pTouch)
                end
            elseif eventName == "ended" then
                if onTouchEnd then
                    onTouchEnd(container, eventName, pTouch)
                end
            elseif eventName == "cancelled" then
                if onTouchCancel then
                    onTouchCancel(container, eventName, pTouch)
                end
            end
        end
        , false, 0, false)
        layer:setTouchEnabled(true)
        container.mScrollView:setTouchEnabled(isScrollViewTouch)
        layer:setVisible(true)
    end
end

function NodeHelper:initScrollView(container, svName, size, boundcedItemFlag)
    local size = size or 3
    container.mScrollView = container:getVarScrollView(svName)
    if container.mScrollView == nil then return end
    container.mScrollViewRootNode = container.mScrollView:getContainer()
    container.m_pScrollViewFacade = CCReViScrollViewFacade:new_local(container.mScrollView)
    container.m_pScrollViewFacade:init(size, 3)
    -- 用于让每个item都有弹性，详见CCReViScrollViewFacade
    if boundcedItemFlag == nil then boundcedItemFlag = false end
    container.m_pScrollViewFacade:setBouncedFlag(boundcedItemFlag)
end

function NodeHelper:initScrollViewByTargetScrollViewName(container, svName, size, boundcedItemFlag, targetScrollView, targetFacade)
    local size = size or 3
    container[targetScrollView] = container:getVarScrollView(svName)
    if container[targetScrollView] == nil then return end
    container[targetFacade] = CCReViScrollViewFacade:new_local(container[targetScrollView])
    container[targetFacade]:init(size, 3)
    -- 用于让每个item都有弹性，详见CCReViScrollViewFacade
    if boundcedItemFlag == nil then boundcedItemFlag = false end
    container[targetFacade]:setBouncedFlag(boundcedItemFlag)
end

function NodeHelper:setScrollViewStartOffset(container, offset)
    if container == nil or container.mScrollView == nil then return end
    if container.mScrollViewRootNode == nil then return end
    container.mScrollViewRootNode:setPosition(offset)
    local children = container.mScrollViewRootNode:getChildren()
    if children ~= nil then
        if children:count() < 1 then return end
        local child = children:objectAtIndex(0)
        local childSize = child:getContentSize().height * child:getScaleY()
        if offset.y < 0 then
            offset.y = math.abs(offset.y)
        end
        local index = math.ceil(offset.y / childSize)
        index = index < 1 and 1 or index
        container.m_pScrollViewFacade:setDynamicItemsStartPosition(index - 1)
    end
end

function NodeHelper:setScrollViewStartOffsetEx(scrollView, facade, offset)
    if scrollView == nil then return end
    if scrollView:getContainer() == nil then return end
    scrollView:getContainer():setPosition(offset)
    local children = scrollView:getContainer():getChildren()
    if children ~= nil then
        if children:count() < 1 then return end
        local child = children:objectAtIndex(0)
        local childSize = child:getContentSize().height * child:getScaleY()
        if offset.y < 0 then
            offset.y = math.abs(offset.y)
        end
        local index = math.ceil(offset.y / childSize)
        index = index < 1 and 1 or index
        facade:setDynamicItemsStartPosition(index - 1)
    end
end

-- 支持多ccbi加载的横向scrollview并支持一项一项移动
--[[
    调用示例
    local buildTable = {}
	local buildOne = {
        ccbiFile = PackageChildPage.ccbiFile,
        size = 2,
        funcCallback = PackageChildPage.onFunction
    }
    table.insert(buildTable,buildOne)
    NodeHelper:buildMultiColumnScrollView(container,buildTable,100) --100为项与项的间隔
--]]
function NodeHelper:buildMultiColumnScrollView(container, buildTable, interval)
    local MultiColumnScrollViewHelper = require("MultiColumnScrollViewHelper")
    MultiColumnScrollViewHelper.buildScrollViewHorizontal(container, buildTable, interval)
    MultiColumnScrollViewHelper.setMoveOnByOn(container, true)
end

function NodeHelper:clearMultiColumnScrollView(container, index)
    local MultiColumnScrollViewHelper = require("MultiColumnScrollViewHelper")
    return MultiColumnScrollViewHelper.clearMultiColumnScrollView(container, index)
end

function NodeHelper:buildScrollViewHorizontal(container, size, ccbiFile, funcCallback, interval, itemScale)
    if size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then return end
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local fOneItemWidth = 0
    local scale = (itemScale or 1)

    interval = interval or 100

    for i = size, 1, -1 do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp((fOneItemWidth + interval) * iCount, 0)

        if iCount < iMaxNode then
            local pItem = ScriptContentBase:create(ccbiFile)
            pItem.id = iCount
            pItem:registerFunctionHandler(funcCallback)
            pItem:setScale(scale)
            if fOneItemHeight < pItem:getContentSize().height then
                fOneItemHeight = pItem:getContentSize().height * scale
            end

            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width * scale
            end
            
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        iCount = iCount + 1
    end

    local size = CCSizeMake(fOneItemWidth * iCount + interval * (iCount - 1), fOneItemHeight)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, 0))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollView:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end

function NodeHelper:buildScrollViewHorizontalOther(container, size, ccbiFile, funcCallback, interval)
    if size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then return end
    local iMaxNode = container.m_pScrollViewFacadeR:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local fOneItemWidth = 0
    interval = interval or 100

    for i = size, 1, -1 do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp((fOneItemWidth + interval) * iCount, 0)

        if iCount < iMaxNode then
            local pItem = ScriptContentBase:create(ccbiFile)
            pItem.id = iCount
            pItem:registerFunctionHandler(funcCallback)
            if fOneItemHeight < pItem:getContentSize().height then
                fOneItemHeight = pItem:getContentSize().height
            end

            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width
            end
            container.m_pScrollViewFacadeR:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacadeR:addItem(pItemData)
        end
        iCount = iCount + 1
    end

    local size = CCSizeMake(fOneItemWidth * iCount + interval * (iCount - 1), fOneItemHeight)
    container.mScrollViewR:setContentSize(size)
    container.mScrollViewR:setContentOffset(ccp(-fOneItemWidth - interval, 0))
    container.m_pScrollViewFacadeR:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollViewR:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(container.mScrollViewR)
end

function NodeHelper:createTouchLayerByScrollView(container, onTouchBegin, onTouchMove, onTouchEnd, onTouchCancel, isScrollViewTouch)
    local MultiColumnScrollViewHelper = require("MultiColumnScrollViewHelper")

    onTouchBegin = onTouchBegin or MultiColumnScrollViewHelper.onTouchBegin
    onTouchMove = onTouchMove or MultiColumnScrollViewHelper.onTouchMove
    onTouchEnd = onTouchEnd or MultiColumnScrollViewHelper.onTouchEnd
    onTouchCancel = onTouchCancel or MultiColumnScrollViewHelper.onTouchCancel
    -- 初始化
    container.maxScrollWidth = nil
    container.fOneItemWidth = nil
    container.ScrollSize = nil

    --
    isScrollViewTouch = isScrollViewTouch or false
    local layer = container.mScrollView:getParent():getChildByTag(51001)
    if not layer then
        layer = CCLayer:create()
        layer:setTag(51001)
        container.mScrollView:getParent():addChild(layer)
        layer:setContentSize(CCSize(container.mScrollView:getViewSize().width, container.mScrollView:getViewSize().height))
        layer:setPosition(container.mScrollView:getPosition())
        layer:setAnchorPoint(container.mScrollView:getAnchorPoint())
        layer:registerScriptTouchHandler(function(eventName, pTouch)
            if eventName == "began" then
                if onTouchBegin then
                    onTouchBegin(container, eventName, pTouch)
                end
            elseif eventName == "moved" then
                if onTouchMove then
                    onTouchMove(container, eventName, pTouch)
                end
            elseif eventName == "ended" then
                if onTouchEnd then
                    onTouchEnd(container, eventName, pTouch)
                end
            elseif eventName == "cancelled" then
                if onTouchCancel then
                    onTouchCancel(container, eventName, pTouch)
                end
            end
        end
        , false, 0, false)
        layer:setTouchEnabled(true)
        container.mScrollView:setTouchEnabled(isScrollViewTouch)
        layer:setVisible(true)
    end
end

function NodeHelper:buildCellScrollView(scrollview, size, ccbiFile, tableHandler)
    if size == 0 or ccbiFile == nil or ccbiFile == "" or tableHandler == nil then return end
    -- local scrollview = container.scrollview
    if scrollview == nil then return end
    local cell = nil
    local items = { }
    for i = 1, size, 1 do
        cell = CCBFileCell:create()
        cell:setCCBFile(ccbiFile)
        local handler = common:new({ id = i }, tableHandler)
        cell:registerFunctionHandler(handler)
        scrollview:addCell(cell)
        -- local pos = ccp(0,cell:getContentSize().height*(size-i))
        -- cell:setPosition(pos)	
        table.insert(items, { cls = handler, node = cell })
    end
    scrollview:orderCCBFileCells()
    --return items
    --    local ccSzie = scrollview:getViewSize()	

    local sizeRect = CCSizeMake(cell:getContentSize().width,cell:getContentSize().height*size)
    scrollview:setContentSize(sizeRect)
    --scrollview:setContentOffset(ccp(0, scrollview:getViewSize().height - scrollview:getContentSize().height * scrollview:getScaleY()))
    -- scrollview:forceRecaculateChildren()	
    return items
end
function NodeHelper:buildScrollView(container, size, ccbiFile, funcCallback, notOffset, itemScale)
    if size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then return end
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local fOneItemWidth = 0
    local scale = (itemScale or 1)

    for i = size, 1, -1 do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)

        if iCount < iMaxNode then
            local pItem = ScriptContentBase:create(ccbiFile)
            pItem.id = iCount
            pItem:registerFunctionHandler(funcCallback)
            pItem:setScale(scale)
            if fOneItemHeight < pItem:getContentSize().height then
                fOneItemHeight = pItem:getContentSize().height * scale
            end

            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width * scale
            end
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        iCount = iCount + 1
    end

    local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount)
    container.mScrollView:setContentSize(size)
    if not notOffset then
        container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
    end
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollView:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end

function NodeHelper:buildScrollViewWithCache(container, size, ccbiFile, funcCallback, funcCallbackExtra)
    if size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then return end
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local fOneItemWidth = 0

    for i = 1, size, 1 do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)

        if iCount < iMaxNode then
            local pItem
            if ViewHolder[iCount + 1] ~= nil then
                pItem = ViewHolder[iCount + 1]
            else
                pItem = ScriptContentBase:create(ccbiFile)
                pItem.id = iCount
                pItem:registerFunctionHandler(funcCallback)
                if fOneItemHeight < pItem:getContentSize().height then
                    fOneItemHeight = pItem:getContentSize().height
                end

                if fOneItemWidth < pItem:getContentSize().width then
                    fOneItemWidth = pItem:getContentSize().width
                end
                container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
                iCount = iCount + 1
            end
        else
            iCount = iCount + 1
            container.m_pScrollViewFacade:addItem(pItemData)
        end
    end

    if iCount <= 0 then
        return
    end

    local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollView:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end

function NodeHelper:buildScrollViewR(container, size, ccbiFile, funcCallback)
    if size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then return end
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local fOneItemWidth = 0

    for i = 1, size, 1 do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)

        if iCount < iMaxNode then
            local pItem = ScriptContentBase:create(ccbiFile)
            pItem.id = iCount
            pItem:registerFunctionHandler(funcCallback)
            if fOneItemHeight < pItem:getContentSize().height then
                fOneItemHeight = pItem:getContentSize().height
            end

            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width
            end
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        iCount = iCount + 1
    end

    local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollView:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end

function NodeHelper:clearScrollView(container)
    if container.m_pScrollViewFacade then
        container.m_pScrollViewFacade:clearAllItems()
    end
    if container.mScrollViewRootNode then
        container.mScrollViewRootNode:removeAllChildren()
    end
end

function NodeHelper:deleteScrollView(container)
    ViewHolder = { }
    -- if container.mScrollView then
    -- 	container.mScrollView:removeAllCell()
    -- end
    self:clearScrollView(container)
    if container.m_pScrollViewFacade then
        container.m_pScrollViewFacade:delete()
        container.m_pScrollViewFacade = nil
    end
    container.mScrollViewRootNode = nil
    container.mScrollView = nil
end
--------------------------------------------------------------------------------
------scrollview without Facade----
function NodeHelper:initRawScrollView(container, svName)
    container.mScrollView = container:getVarScrollView(svName)
    -- container:autoAdjustResizeScrollview(container.mScrollView)
    container.mScrollViewRootNode = container.mScrollView:getContainer()
end

function NodeHelper:buildRawScrollView(container, size, ccbiFile, funcCallback)
    if size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then return end

    local width = container.mScrollView:getViewSize().width
    local height = 0

    local items = { }
    for i = size, 1, -1 do
        -- local pItem = ScriptContentBase:create(ccbiFile, i);
        local pItem = CCBManager:getInstance():createAndLoad2(ccbiFile)
        pItem:setTag(i)
        pItem:registerFunctionHandler(funcCallback)
        pItem.__CCReViSvItemNodeFacade__:initItemView()
        container.mScrollView:addChild(pItem)
        -- pItem:release();
        pItem:setAnchorPoint(ccp(0, 0))
        pItem:setPosition(ccp(0, height))
        height = height + pItem:getContentSize().height

        items[i] = pItem
    end

    local size = CCSizeMake(width, height)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - height * container.mScrollView:getScaleY()))
    container.mScrollView:forceRecaculateChildren()

    return items
end

function NodeHelper:buildVerticalScrollView(scrollView, container, size, ccbiFile, funcCallback, spacing)
    if scrollView == nil or size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then return end

    local spacing = spacing or 0
    local width = scrollView:getContentSize().width
    local height = 0
    local spacing = size * spacing

    local items = { }

    for i = size, 1, -1 do
        -- local pItem = ScriptContentBase:create(ccbiFile, i);
        local pItem = ScriptContentBase:create(ccbiFile)--CCBManager:getInstance():createAndLoad2(ccbiFile)
        pItem.mID = i
        pItem:registerFunctionHandler(funcCallback)
        pItem.__CCReViSvItemNodeFacade__:initItemView()
        scrollView:addChild(pItem)
        -- pItem:release();
        pItem:setAnchorPoint(ccp(0, 0))
        pItem:setPosition(ccp(0, height + spacing))
        height = height + pItem:getContentSize().height

        -- table.insert(items, { cls = handler, node = cell })
    end

    local size = CCSizeMake(width, height + spacing)
    scrollView:setContentSize(size)
    scrollView:setContentOffset(ccp(0, scrollView:getViewSize().height - height * scrollView:getScaleY()))
    scrollView:forceRecaculateChildren()

    return items
end

-- function NodeHelper:setCCHTMLLabel( node, _CCSize,_ccp , str )

-- local label = CCHTMLLabel:createWithString(str,_CCSize , "Helvetica")

-- label:setPosition(_ccp)

-- if node ~= nil then
-- 	node:getParent():addChild(label)
-- end
-- end	

function NodeHelper:setCCHTMLLabelAutoFixPosition(node, _CCSize, str)

    local ccc = "<font color=\"#625141\" face = \"Barlow-SemiBold\" >" .. str .. "</font>"

    local label = CCHTMLLabel:createWithString(ccc, _CCSize, "Barlow-SemiBold")
    if node ~= nil then
        local _ccp = ccp(node:getPositionX(), node:getPositionY())
        label:setAnchorPoint(node:getAnchorPoint())
        label:setPosition(_ccp)
        if node:getParent():getChildByTag(titleTag) then
            node:getParent():removeChildByTag(titleTag, true)
        end
        node:getParent():addChild(label, 1, titleTag)
    end
    return label
end	

function NodeHelper:setCCHTMLLabel(container, originalLabel, _CCSize, str, needScale)
    local label, originalLabelNode
    local node = container:getVarLabelBMFont(originalLabel)
    if not node then
        node = container:getVarLabelTTF(originalLabel)
    end
    originalLabelNode = node
    if originalLabelNode then
        originalLabelNode:setVisible(false)
        label = self:setCCHTMLLabelAutoFixPosition(node, _CCSize, str)

        if needScale then
            label:setScaleX(originalLabelNode:getScaleX())
            label:setScaleY(originalLabelNode:getScaleY())
        end
    end
    return label
end

function NodeHelper:setCCHTMLLabelDefaultPos(node, _CCSize, str)

    local label = CCHTMLLabel:createWithString(str, _CCSize, "Helvetica")

    local posX = node:getPositionX()
    local posY = node:getPositionY()



    label:setPosition(ccp(posX, posY))

    if node ~= nil then
        local child = node:getParent():getChildByTag(titleTag)
        if child then
            node:getParent():removeChild(child, true)
        end
        node:getParent():addChild(label, 1, titleTag)
    end

    return label
end

-- TODO
function NodeHelper:addHtmlLable_Tips(node, str, tag, size, _parent)
    local size = size or node:getContentSize()
    local posX, posY = node:getPosition()
    local anchor = node:getAnchorPoint()

    -- Barlow-SemiBold
    local label = CCHTMLLabel:createWithString(str, size, "Barlow-SemiBold")
    label:setPosition(ccp(posX, posY))
    label:setAnchorPoint(ccp(0.5, 1))--anchor)
    label:setScaleX(node:getScaleX())
    label:setScaleY(node:getScaleY())

    if node ~= nil then
        local _parent = _parent or node:getParent()
        if _parent then
            if tag then
                local child = _parent:getChildByTag(tag)
                if child then
                    _parent:removeChild(child, true)
                end
            end
            _parent:addChild(label)
            if tag then
                label:setTag(tag)
            end
        end
    end
    return label
end

-- TODO
function NodeHelper:addHtmlLable_1(node, str, tag, size, _parent)
    local size = size or node:getContentSize()
    local posX, posY = node:getPosition()
    local anchor = node:getAnchorPoint()


    -- Helvetica
    local label = CCHTMLLabel:createWithString(str, CCSizeMake(500, node:getContentSize().height), "Barlow-SemiBold")
    -- local label = CCHTMLLabel:createWithString(str, size, "Helvetica")
    label:setPosition(ccp(posX, posY))
    label:setAnchorPoint(anchor)
    label:setScaleX(node:getScaleX())
    label:setScaleY(node:getScaleY())

    if node ~= nil then
        local _parent = _parent or node:getParent()
        if _parent then
            if tag then
                local child = _parent:getChildByTag(tag)
                if child then
                    _parent:removeChild(child, true)
                end
            end
            _parent:addChild(label)
            if tag then
                label:setTag(tag)
            end
        end
    end
    return label
end

function NodeHelper:addChatOneFaceSprite(node, relaPath, tag, _parent)
    local size = size or node:getContentSize()
    local posX, posY = node:getPosition()
    local anchor = node:getAnchorPoint()

    local label = CCSprite:create(relaPath)
    label:setPosition(ccp(posX + 20, posY - 20))
    label:setAnchorPoint(anchor)
    label:setScaleX(node:getScaleX())
    label:setScaleY(node:getScaleY())

    if node ~= nil then
        local _parent = _parent or node:getParent()
        if _parent then
            if tag then
                local child = _parent:getChildByTag(tag)
                if child then
                    _parent:removeChild(child, true)
                end
            end
            _parent:addChild(label)
            if tag then
                label:setTag(tag)
            end
        end
    end
    return label
end

function NodeHelper:addHtmlLable(node, str, tag, size, _parent, font)
    space = space or 1
    local size = size or node:getContentSize()
    local posX, posY = node:getPosition()
    local anchor = node:getAnchorPoint()


    -- Helvetica
    -- local label = CCHTMLLabel:createWithString(str, CCSizeMake(800, node:getContentSize().height), "Helvetica");
    -- local label = CCHTMLLabel:createWithString(str, size, font or "Barlow-SemiBold20")
    local label = CCHTMLLabel:createWithString(str, size, "Barlow SemiBold")
    label:setPosition(ccp(posX, posY))
    label:setAnchorPoint(anchor)
    label:setScaleX(node:getScaleX())
    label:setScaleY(node:getScaleY())

    if node ~= nil then
        local _parent = _parent or node:getParent()
        if _parent then
            if tag then
                local child = _parent:getChildByTag(tag)
                if child then
                    _parent:removeChild(child, true)
                end
            end
            _parent:addChild(label)
            if tag then
                label:setTag(tag)
            end
        end
    end
    return label
end
function NodeHelper:addEditBoxBlinkTip(labelNode)
    if labelNode:getChildByTag(10086) then
        CCLuaLog("NodeHelper-----" .. "labelNode:getChildByTag(10086)  is exsist")
        local mTipAniSprite = labelNode:getChildByTag(10086)
        mTipAniSprite:setPosition(ccp(labelNode:getContentSize().width + 2, labelNode:getContentSize().height / 2))
    else
        local mTipAniSprite = CCSprite:create("LoadingUI_JP/color2.png")
        mTipAniSprite:setScale(3.0)
        mTipAniSprite:setPosition(ccp(labelNode:getContentSize().width + 2, labelNode:getContentSize().height / 2))
        mTipAniSprite:runAction(CCRepeatForever:create(CCBlink:create(1, 1)))
        labelNode:addChild(mTipAniSprite, 1, 10086)
    end
end
function NodeHelper:addEditBox(size, node, handle, pos, placeHolder)
    local editBox = CCEditBox:create(size, CCScale9Sprite:create("UI/Mask/Image_Empty.png"))
    if editBox and handle then
        editBox:setAnchorPoint(node:getAnchorPoint())
        editBox:registerScriptEditBoxHandler(handle)
        local posX, posY = node:getPosition()
        pos = pos or ccp(posX, posY)
        editBox:setPosition(pos)
        editBox:setScale(node:getScale())
        editBox:setFont("Barlow-SemiBold.ttf", 26)
        editBox:setPlaceholderFont("Barlow-SemiBold.ttf", 26)
        placeHolder = placeHolder or ""
        editBox:setPlaceHolder(placeHolder)
        if node:getParent():getChildByTag(editBoxTag) then
            node:getParent():removeChildByTag(editBoxTag, true)
        end
        node:getParent():addChild(editBox, 1, editBoxTag)
        node:setVisible(false)
    end
    return editBox
end

function NodeHelper:setColor3BForLabel(container, colorMap)
    for name, color3B in pairs(colorMap) do
        local node = container:getVarLabelBMFont(name)
        if node then
            node:setColor(color3B)
        else
            local nodeTTF = container:getVarLabelTTF(name)
            if nodeTTF then
                nodeTTF:setColor(color3B)
            else
                -- CCLuaLog("NodeHelper:setStringForLabel====>" .. name)		
            end
        end
    end
end

function NodeHelper:fillRewardItemWithParams(container, rewardCfg, maxSize, params)
    local maxSize = maxSize or 4

    local nodesVisible = { }
    local lb2Str = { }
    local sprite2Img = { }
    local menu2Quality = { }
    local btnSprite = { }
    local scaleMap = { }
    local colorMap = { }

    local mainNode = params.mainNode or "mRewardNode"
    local countNode = params.countNode or "mNum"
    local nameNode = params.nameNode or "mName"
    local frameNode = params.frameNode or "mFrame"
    local picNode = params.picNode or "mPic"
    local frameShade = params.frameShade or "mFrameShade"
    local showHtml = params.showHtml == nil
    local startIndex = params.startIndex or 1

    for i = startIndex, maxSize + startIndex - 1 do
        local cfg = rewardCfg[i - startIndex + 1]
        nodesVisible[mainNode .. i] = cfg ~= nil
        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
            if resInfo ~= nil then
                sprite2Img[picNode .. i] = resInfo.icon
                sprite2Img[frameShade .. i] = NodeHelper:getImageBgByQuality(resInfo.quality)
                lb2Str[countNode .. i] = "x" .. GameUtil:formatNumber(cfg.count)
                scaleMap[picNode .. i] = 1
                -- scaleMap[picNode .. i] = resInfo.iconScale
                if showHtml then
                    NodeHelper:setCCHTMLLabel(container, nameNode .. i, CCSize(130, 96), resInfo.name, true)
                else
                    lb2Str[nameNode .. i] = resInfo.name
                end
                menu2Quality[frameNode .. i] = resInfo.quality

                colorMap[nameNode .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                -- colorMap[countNode .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
            else
                -- CCLuaLog("Error::***reward item not found!!");
            end
        end
    end
    self:setNodesVisible(container, nodesVisible)
    self:setStringForLabel(container, lb2Str)
    self:setSpriteImage(container, sprite2Img, scaleMap)
    self:setQualityFrames(container, menu2Quality)
    self:setColorForLabel(container, colorMap)
end
function NodeHelper:showRewardText(container, Allrewards)
    local wordList = { }
    local colorList = { }
    local rewards = Allrewards
    for i = 1, #rewards do
        local oneReward = rewards[i]
        if oneReward.itemCount > 0 then
            local ResManager = require "ResManagerForLua"
            local resInfo = ResManager:getResInfoByTypeAndId(oneReward.itemType, oneReward.itemId, oneReward.itemCount)
            local getReward = Language:getInstance():getString("@GetRewardMSG")
            local godlyEquip = Language:getInstance():getString("@GodlyEquip")
            -- GodlyEquip
            local rewardName = resInfo.name
            local rewardStr = rewardName .. " ×" .. oneReward.itemCount .. " "
            local itemColor = ""
            if resInfo.quality == 1 then
                itemColor = GameConfig.ColorMap.COLOR_GREEN
            elseif resInfo.quality == 2 then
                itemColor = GameConfig.ColorMap.COLOR_GREEN
            elseif resInfo.quality == 3 then
                itemColor = GameConfig.ColorMap.COLOR_BLUE
            elseif resInfo.quality == 4 then
                itemColor = GameConfig.ColorMap.COLOR_PURPLE
            elseif resInfo.quality == 5 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 6 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 7 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 8 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 9 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 10 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 11 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 12 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 13 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 14 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 15 then
                itemColor = GameConfig.ColorMap.COLOR_BLUE
            elseif resInfo.quality == 16 then
                itemColor = GameConfig.ColorMap.COLOR_PURPLE
            elseif resInfo.quality == 17 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 18 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            end
            local finalStr = getReward
            finalStr = finalStr .. rewardStr
            table.insert(wordList, finalStr)
            table.insert(colorList, itemColor)
        end
    end
    return insertMessageFlow(wordList, colorList)
end

function NodeHelper:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
    local maxSize = maxSize or 4
    isShowNum = isShowNum or false
    local nodesVisible = { }
    local lb2Str = { }
    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local colorMap = { }

    for i = 1, maxSize do
        local cfg = rewardCfg[i]
        nodesVisible["mRewardNode" .. i] = cfg ~= nil
        nodesVisible["mName" .. i] = false
        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
            if resInfo ~= nil then
                sprite2Img["mPic" .. i] = resInfo.icon
                sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(resInfo.quality)
                lb2Str["mNum" .. i] = --[["x" .. ]]GameUtil:formatNumber(cfg.count)
                --lb2Str["mName" .. i] = resInfo.name
                menu2Quality["mFrame" .. i] = resInfo.quality

                -- colorMap["mNum" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                --colorMap["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor

                if resInfo.iconScale then
                    scaleMap["mPic" .. i] = 1

                    -- scaleMap["mPic" .. i] = resInfo.iconScale
                end

                if isShowNum then
                    resInfo.count = resInfo.count or 0
                    lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count
                end
                -- html
                local htmlNode = container:getVarLabelBMFont("mName" .. i)
                if not htmlNode then htmlNode = container:getVarLabelTTF("mName" .. i) end
                if htmlNode then
                    local htmlLabel
                    --
                    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
                        htmlNode:setVisible(false)
                        htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(110, 32), resInfo.name)
                        htmlLabel:setScaleX(htmlNode:getScaleX())
                        htmlLabel:setScaleY(htmlNode:getScaleY())
                    end
                end
            else
                -- CCLuaLog("Error::***reward item not found!!");
            end
        end
    end

    self:setNodesVisible(container, nodesVisible)
    self:setStringForLabel(container, lb2Str)
    self:setSpriteImage(container, sprite2Img, scaleMap)
    self:setQualityFrames(container, menu2Quality)
    self:setColorForLabel(container, colorMap)
end
function NodeHelper:fillRewardItemWithCostNum(container, rewardCfg, maxSize, isShowNum)
    local maxSize = maxSize or 4
    isShowNum = isShowNum or false
    local nodesVisible = { }
    local lb2Str = { }
    local sprite2Img = { }
    local menu2Quality = { }

    for i = 1, maxSize do
        local cfg = rewardCfg[i]
        nodesVisible["mRewardNode" .. i] = cfg ~= nil

        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
            if resInfo ~= nil then
                sprite2Img["mPic" .. i] = resInfo.icon
                sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(resInfo.quality)
                lb2Str["mName" .. i] = resInfo.name
                menu2Quality["mFrame" .. i] = resInfo.quality

                if isShowNum then
                    local UserItemManager = require("Item.UserItemManager")
                    local nowCount = 0
                    if UserItemManager:getUserItemByItemId(cfg.itemId) then
                        nowCount = UserItemManager:getUserItemByItemId(cfg.itemId).count
                    end
                    local costCount = cfg.count
                    lb2Str["mNum" .. i] = nowCount .. "/" .. costCount
                end
            else
                -- CCLuaLog("Error::***reward item not found!!");
            end
        end
    end

    self:setNodesVisible(container, nodesVisible)
    self:setStringForLabel(container, lb2Str)
    self:setSpriteImage(container, sprite2Img)
    self:setQualityFrames(container, menu2Quality)
end

function NodeHelper:addEquipAni(container, nodeName, aniVisible, userEquipId, userEquip)
    local aniNode = container:getVarNode(nodeName)
    if aniNode then
        aniNode:removeAllChildren()
        if aniVisible then
            local ccbiFile = UserEquipManager:getGodlyAni(userEquipId, userEquip)
            local ani = CCBManager:getInstance():createAndLoad2(ccbiFile)
            ani:unregisterFunctionHandler()
            aniNode:addChild(ani)
        end
        aniNode:setVisible(aniVisible)
    end
end

function NodeHelper:addStoneAni(container, nodeName, aniVisible)
    local aniNode = container:getVarNode(nodeName)
    if aniNode then
        aniNode:removeAllChildren()
        if aniVisible then
            local ccbiFile = "ccbi/EquipAni02.ccbi"
            local ani = ScriptContentBase:create(ccbiFile)
            ani:release()
            ani:unregisterFunctionHandler()
            aniNode:addChild(ani)
            -- ani:release()
        end
        aniNode:setVisible(aniVisible)
    end
end
-- 针对泰语增加的api（Thai字符音调，帽子往上叠加，造成字符上超框） 为了不修改ccbi 影响其他版本。 增加接口 处理节点的缩放 和 位置偏移
-- strMap：节点信息  nPosY：Y方向偏移量 nScale：缩放比例
function NodeHelper:MoveAndScaleNode(container, strMap, nPosY, nScaleX, nScaleY)
    for name, str in pairs(strMap) do
        local node = container:getVarLabelBMFont(name)
        if node then
            if nScaleY and nScaleX then
                node:setScaleX(nScaleX)
                node:setScaleY(nScaleY)
            elseif nScaleX then
                node:setScale(nScaleX)
            end

            if nPosY and nPosY ~= 0 then
                node:setPositionY(node:getPositionY() + nPosY)
            end
            node:setString(tostring(str))
        else
            local nodeTTF = container:getVarLabelTTF(name)
            if nodeTTF then
                if nScaleY and nScaleX then
                    nodeTTF:setScaleX(nScaleX)
                    nodeTTF:setScaleY(nScaleY)
                elseif nScaleX then
                    nodeTTF:setScale(nScaleX)
                end
                if nPosY and nPosY ~= 0 then
                    nodeTTF:setPositionY(nodeTTF:setPositionY() + nPosY)
                end
                nodeTTF:setString(tostring(str))
            else
                -- CCLuaLog("NodeHelper:setStringForLabel====>" .. name)		
            end

        end
    end
end
function NodeHelper:SetNodePostion(container, name, offsetX, offsetY)
    if container == nil then
        return
    end
    local node = container:getVarNode(name)

    if node ~= nil then
        local posX = offsetX or 0
        local posY = offsetY or 0

        node:setPositionX(node:getPositionX() + posX)
        node:setPositionY(node:getPositionY() + posY)
    end
end

function NodeHelper:setLabelMapOneByOne(container, strMap, gap, isR2Gap)
    if container == nil then
        return
    end
    local isRealGap = isR2Gap or false
    local gap = gap or 0
    if Golb_Platform_Info.is_r2_platform then
        if isRealGap then
            gap = gap
        else
            gap = 0
        end
    end
    for name1, name2 in pairs(strMap) do
        local label1 = container:getVarNode(name1)
        local label2 = container:getVarNode(name2)

        if label1 ~= nil and label2 ~= nil then
            local AnchorPoint1 = label1:getAnchorPoint().x
            local AnchorPoint2 = label2:getAnchorPoint().x
            local controlGap1 =(label1:getContentSize().width * label1:getScaleX()) * AnchorPoint1
            local controlGap2 =(label2:getContentSize().width * label2:getScaleX()) * AnchorPoint2
            label2:setPositionX(label1:getPositionX() + label1:getContentSize().width * label1:getScaleX() - controlGap1 + controlGap2 + gap)
        end
    end

end
function NodeHelper:setBlurryString(container, name, strTxt, widthX, subSize)
    subSize = subSize or 6
    if container == nil then
        return
    end
    local node = container:getVarLabelBMFont(name)
    if node then
        node:setString(tostring(strTxt))
        local TxtWidth = (node:getContentSize().width * node:getScaleX())
        local num = GameMaths:calculateStringCharacters(strTxt)
        if TxtWidth > widthX then
            local BlurryStr = GameMaths:getStringSubCharacters(strTxt, 0, subSize)
            if num > subSize then
                BlurryStr = BlurryStr .. "..."
            end
            node:setString(tostring(BlurryStr))
        end
    else
        local nodeTTF = container:getVarLabelTTF(name)
        if nodeTTF then
            nodeTTF:setString(tostring(strTxt))
            local TxtWidth = (nodeTTF:getContentSize().width * nodeTTF:getScaleX())
            local num = GameMaths:calculateStringCharacters(strTxt)
            if TxtWidth > widthX then
                local BlurryStr = GameMaths:getStringSubCharacters(strTxt, 0, subSize)
                if num > subSize then
                    BlurryStr = BlurryStr .. "..."
                end
                nodeTTF:setString(tostring(BlurryStr))
            end
        else
            -- CCLuaLog("NodeHelper:setStringForLabel====>" .. name)		
        end
    end
end
function NodeHelper:cursorNode(container, LabelName, isShow)
    local baseFontSize = 25
    local cursor = CCSprite:create("LoadingUI_JP/input_blink.png")
    if not cursor then return end
    if not container then return end
    local contentLabel = container:getVarLabelTTF(LabelName)
    if contentLabel == nil then
        contentLabel = container:getVarLabelBMFont(LabelName)
    end
    if not contentLabel then return end
    local nodeParent = contentLabel:getParent()
    if nodeParent:getChildByTag(88888) then
        nodeParent:removeChildByTag(88888, true)
    end
    if not isShow then return end
    local nHeight = contentLabel:getContentSize().height * contentLabel:getScaleY()
    local nWidth = contentLabel:getContentSize().width * contentLabel:getScaleX()
    local str = contentLabel:getString()
    if str == "" then
        nWidth = 0
    end
    -- CCLuaLog(" GuildCreateBase:contentLabel nWidth="..nWidth)
    local posX = contentLabel:getPositionX() + nWidth * (1 - contentLabel:getAnchorPoint().x)
    local posY = contentLabel:getPositionY()
    local realSize = contentLabel:getFontSize()
    cursor:setScaleY(realSize / baseFontSize)
    cursor:setTag(88888)
    nodeParent:addChild(cursor)
    cursor:setPosition(ccp(posX + 2, posY))
    -- CCLuaLog(" GuildCreateBase:posX="..posX+2)
    cursor:setAnchorPoint(contentLabel:getAnchorPoint())
    AnimMgr:getInstance():fadeInAndOut(cursor, 0.25)
end

function NodeHelper:getItemInfo(reward, splitStr)
    local _type, _id, _count = unpack(common:split(reward, splitStr))
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_count))
    return resInfo
end
function NodeHelper:CheckIsReward(reward)
    if not reward then return false end
    local _, count = string.gsub(reward, "_", "_")
    if count == 2 then
        local _type, _id, _count = unpack(common:split(reward, "_"))
        if type(tonumber(_type)) == "number" and type(tonumber(_id)) == "number" and type(tonumber(_count)) == "number" then
            return true
        end
    end
    return false
end

-- 添加统一显示物品 总量格式/消耗  新的
function NodeHelper:addNewItemIsEnoughHtmlLab(container, nodeName, selfCount, costCount, tag, ItemNotEnoughColorKey, ItemEnoughColorKey)
    if (not container) or(not nodeName) then CCLuaLog("Error NodeHelper:addItemIsEnoughHtmlLab") end
    NodeHelper:setStringForLabel(container, { [nodeName] = "" })
    local node = container:getVarNode(nodeName)
    if not node then CCLuaLog("Error node nil NodeHelper:addItemIsEnoughHtmlLab") return end
    tag = tag or GameConfig.Tag.HtmlLable
    local itemNot = ItemNotEnoughColorKey or "ItemNotEnough"
    local ItemEnough = ItemEnoughColorKey or "ItemEnough"
    local str = ""
    local isEnough = true
    if math.floor(selfCount) < math.floor(costCount) then
        str = common:fillHtmlStr(itemNot, GameUtil:formatDotNumber(math.floor(selfCount)), GameUtil:formatDotNumber(math.floor(costCount)))
    else
        str = common:fillHtmlStr(ItemEnough, GameUtil:formatDotNumber(math.floor(selfCount)), GameUtil:formatDotNumber(math.floor(costCount)))
        isEnough = false
    end
    NodeHelper:addHtmlLable(node, str, tag, CCSizeMake(300, 30))
    return isEnough
end

-- 添加统一显示物品 总量格式/消耗  返回是否足够的标识 isShowHas 是否显示拥有
function NodeHelper:addItemIsEnoughHtmlLab(container, nodeName, costCount, hasCount, tag)
    if (not container) or(not nodeName) then CCLuaLog("Error NodeHelper:addItemIsEnoughHtmlLab") end
    NodeHelper:setStringForLabel(container, { [nodeName] = "" })
    local node = container:getVarNode(nodeName)
    if not node then CCLuaLog("Error node nil NodeHelper:addItemIsEnoughHtmlLab") return end
    local str = ""
    local isEnough = true
    if math.floor(hasCount) <= math.floor(costCount) then
        str = common:fillHtmlStr("ItemEnough", GameUtil:formatDotNumber(math.floor(hasCount)), GameUtil:formatNumber(math.floor(costCount)))
    else
        str = common:fillHtmlStr("ItemNotEnough", GameUtil:formatDotNumber(math.floor(hasCount)), GameUtil:formatNumber(math.floor(costCount)))
        isEnough = false
    end
    NodeHelper:addHtmlLable(node, str, tag, CCSizeMake(300, 30))
    return isEnough
end

function NodeHelper:formatEnough(container, nodeName, costCount, hasCount, tag)
    if (not container) or (not nodeName) then
        return
    end
    local n = container:getVarNode(nodeName)
    if not n then
        return
    end
    local nodeTagt = tag or 10086
    local fontSize = 20
    local fontName = "Barlow-SemiBold.ttf"
    local color3B = self:_getColorFromSetting("111 47 0")

    local node = CCNode:create()
    node:setTag(nodeTagt)
    local label_1 = CCLabelTTF:create(GameUtil:formatNumber(costCount) .. "", fontName, fontSize)
    label_1:setColor(color3B)
    local label_2 = CCLabelTTF:create("/", fontName, fontSize)
    label_2:setColor(color3B)
    local label_3 = CCLabelTTF:create(GameUtil:formatNumber(costCount) .. "", fontName, fontSize)
    label_3:setColor(color3B)
    if costCount < hasCount then
        color3B = self:_getColorFromSetting("255 0 0")
        label_1:setColor(color3B)
    else
        color3B = self:_getColorFromSetting("0 194 0")
        label_1:setColor(color3B)
    end

    node:addChild(label_2)
    label_2:setAnchorPoint(ccp(0.5, 0.5))
    label_2:setPosition(ccp(0, 0))

    node:addChild(label_1)
    label_1:setAnchorPoint(ccp(1, 0.5))
    label_1:setPosition(ccp(label_2:getPositionX() - label_2:getContentSize().width / 2 - 5, 0))

    node:addChild(label_3)
    label_3:setAnchorPoint(ccp(0, 0.5))
    label_3:setPosition(ccp(label_2:getPositionX() + label_2:getContentSize().width / 2 + 5, 0))

    local parent = n:getParent()
    if parent then
        parent:addChild(node)
        node:setPosition(n:getPosition())
    end
    self:setNodesVisible(container, { nodeName = false })
end

-- 添加统一显示物品 总量格式/消耗  返回是否足够的标识 不显示拥有
function NodeHelper:addItemIsEnoughHtmlLabNotShowHas(container, nodeName, costCount, hasCount, tag)
    if (not container) or (not nodeName) then
        CCLuaLog("Error NodeHelper:addItemIsEnoughHtmlLab")
    end
    NodeHelper:setStringForLabel(container, { [nodeName] = "" })
    local node = container:getVarNode(nodeName)
    if not node then CCLuaLog("Error node nil NodeHelper:addItemIsEnoughHtmlLab") return end
    local str = ""
    local isEnough = true
    if math.floor(costCount) <= math.floor(hasCount) then
        str = common:fillHtmlStr("WhiteFreeType", GameUtil:formatNumber(math.floor(costCount)))
    else
        str = common:fillHtmlStr("RedFreeType", GameUtil:formatNumber(math.floor(costCount)))
        isEnough = false
    end
    NodeHelper:addHtmlLable(node, str, tag, CCSizeMake(300, 30))
    return isEnough
end

function NodeHelper:playMusic(music)
    -- SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(0.1);
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        return
    end
    if not self:isFileExist(music) then
        return
    end
    local UserInfo = require("PlayerInfo.UserInfo")
    UserInfo.stateInfo.soundOn = UserInfo.stateInfo.soundOn or 0
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        if tonumber(UserInfo.stateInfo.soundOn) >= 1 then
            SimpleAudioEngine:sharedEngine():playEffect(music, false)
        end
    else
        if tonumber(UserInfo.stateInfo.soundOn) >= 1 then
            SoundManager:getInstance():playOtherMusic(music)
        end
    end
end

function NodeHelper:playEffect(music, isSkipCheck)
    --local GuideManager = require("Guide.GuideManager")
    --if GuideManager.isInGuide then
    --    return
    --end
    if not isSkipCheck and not self:isFileExist("audio/" .. music) then
        return
    end
    local UserInfo = require("PlayerInfo.UserInfo")
    UserInfo.stateInfo.soundOn = UserInfo.stateInfo.soundOn or 0

    if tonumber(UserInfo.stateInfo.soundOn) >= 1 then
        return SimpleAudioEngine:sharedEngine():playEffect(music, false)
    end
end

function NodeHelper:playSpecialMusic(music)
    SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(0.2)
    local UserInfo = require("PlayerInfo.UserInfo")
    -- SimpleAudioEngine:sharedEngine():playEffect(music,false);

    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        if tonumber(UserInfo.stateInfo.soundOn) >= 1 then
            SimpleAudioEngine:sharedEngine():playEffect(music, false)
        end
    else
        if tonumber(UserInfo.stateInfo.soundOn) >= 1 then
            SoundManager:getInstance():playOtherMusic(music)
        end
    end
end

function NodeHelper:stopMusic()
    -- SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(0.5);
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        SimpleAudioEngine:sharedEngine():stopAllEffects()
    else
        SoundManager:getInstance():stopOtherMusic()
    end
end

function NodeHelper:initGraySpineSprite(backNode, spine, parentNode, roleData)
    local spineNode = tolua.cast(spine, "CCNode")
    local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
    backNode:addChild(spineNode)
    spine:runAnimation(1, "Stop", -1)
    local handler = 0
    handler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        spineNode:setPosition(ccp(360 + offset_X_Str, 640 + offset_Y_Str))
        spineNode:setScale(roleData.spineScale)
        local render = CCRenderTexture:create(720, 1280)
        -- render:setAnchorPoint(ccp(0,0))
        -- render:setPosition(ccp(320,480))
        render:clear(0, 0, 0, 0)
        render:begin()
        backNode:visit()
        render:endToLua()

        local sprite = render:getSprite()
        local graySprite = GraySprite:new()
        local texture = sprite:getTexture()
        local size = sprite:getContentSize()
        graySprite:initWithTexture(texture, sprite:getTextureRect())
        -- graySprite:setPosition(ccp(320,480))
        graySprite:setFlipY(true)
        spineNode:removeFromParentAndCleanup(true)
        parentNode:addChild(graySprite)

        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handler)
    end , 0.01, false)
end

function NodeHelper:initGraySpineSpriteVisible(backNode, spine, parentNode, roleData, graySprite, isShow, spriteTag)
    local spineNode = tolua.cast(spine, "CCNode")
    local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
    backNode:addChild(spineNode)
    spine:runAnimation(1, "Stop", -1)
    local handler = 0
    handler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        spineNode:setPosition(ccp(360 + offset_X_Str, 640 + offset_Y_Str))
        spineNode:setScale(roleData.spineScale)
        local render = CCRenderTexture:create(720, 1280)
        -- render:setAnchorPoint(ccp(0, 0))
        -- render:setPosition(ccp(320, 480))
        render:clear(0, 0, 0, 0)
        render:begin()
        backNode:visit()
        render:endToLua()

        local sprite = render:getSprite()
        graySprite = GraySprite:new()
        local texture = sprite:getTexture()
        local size = sprite:getContentSize()
        graySprite:initWithTexture(texture, sprite:getTextureRect())
        -- graySprite:setPosition(ccp(320, 480))
        graySprite:setFlipY(true)
        graySprite:setVisible(isShow)
        if spriteTag then
            graySprite:setTag(spriteTag)
        end
        spineNode:removeFromParentAndCleanup(true)
        parentNode:addChild(graySprite)

        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handler)
    end , 0.01, false)
end


function NodeHelper:stringAppend(str, length, appendStr)
    local beginPos = 1

    local resultSer = ""
    local strList = { }
    local strLength = string.len(str)

    local endPos = length

    repeat
        table.insert(strList, string.sub(str, beginPos, endPos))

        beginPos = beginPos + length

        endPos = endPos + length

    until (endPos > strLength)

    -- 如果后面还有
    if beginPos < strLength then
        table.insert(strList, string.sub(str, beginPos, strLength))
    end

    local strListLength = #strList
    for i = 1, strListLength do
        -- 最后就不要了
        if i ~= strListLength then
            resultSer = resultSer .. strList[i] .. appendStr
        else
            resultSer = resultSer .. strList[i]
        end
    end

    return resultSer
end

function NodeHelper:widthSingle(inputstr)
    -- 计算字符串宽度
    -- 可以计算出字符宽度，用于显示使用
    local lenInByte = #inputstr
    local width = 0
    local i = 1
    while
        (i <= lenInByte)
    do
        local curByte = string.byte(inputstr, i)
        local byteCount = 1
        if curByte > 0 and curByte <= 127 then
            byteCount = 1
            -- 1字节字符
        elseif curByte >= 192 and curByte < 223 then
            byteCount = 2
            -- 双字节字符
        elseif curByte >= 224 and curByte < 239 then
            byteCount = 3
            -- 汉字
        elseif curByte >= 240 and curByte <= 247 then
            byteCount = 4
            -- 4字节字符
        end

        local char = string.sub(inputstr, i, i + byteCount - 1)
        print(char)

        i = i + byteCount
        -- 重置下一字节的索引
        width = width + 1
        -- 字符的个数（长度）
    end
    return width
end

function NodeHelper:setBMFontFile(container, t)
    for name, fntPath in pairs(t) do
        local bmfontLabel = container:getVarLabelBMFont(name)
        if bmfontLabel then
            bmfontLabel:setFntFile(fntPath)
        end
    end
end

function NodeHelper:setNodeIsGray(container, t)

    if container == nil or t == nil then
        CCLuaLog("Error in NodeHelper:setBMFontIsGray==> container is nil  or t is nil")
        return
    end

    for name, isGary in pairs(t) do
        local node = container:getVarNode(name)
        if isGary then
            GraySprite:AddColorGrayToNode(node)
        else
            GraySprite:RemoveColorGrayToNode(node)
        end
    end
end

function NodeHelper:showRewardStr(rewards)
    local wordList = { }
    local colorList = { }
    for i = 1, #rewards do
        local oneReward = rewards[i]
        if oneReward.itemCount > 0 then
            local ResManager = require "ResManagerForLua"
            local resInfo = ResManager:getResInfoByTypeAndId(oneReward.itemType, oneReward.itemId, oneReward.itemCount)
            local getReward = Language:getInstance():getString("@GetRewardMSG")
            local godlyEquip = Language:getInstance():getString("@GodlyEquip")
            -- GodlyEquip
            local rewardName = resInfo.name
            if resInfo.mainType == Const_pb.EQUIP then
                -- add
                if GamePrecedure:getInstance():getI18nSrcPath() == "Portuguese" then
                    rewardName = string.format("%s %s%d", rewardName, common:getR2LVL(), EquipManager:getLevelById(oneReward.itemId))
                else
                    rewardName = string.format("%d %s", EquipManager:getLevelById(oneReward.itemId), rewardName)
                    rewardName = common:getR2LVL() .. rewardName
                end
            end
            local rewardStr = rewardName .. " ×" .. oneReward.itemCount .. " "
            local itemColor = ""
            if resInfo.quality == 1 then
                itemColor = GameConfig.ColorMap.COLOR_GREEN
                if resInfo.itemId == 81040 then
                    itemColor = GameConfig.ColorMap.COLOR_WHITE
                end
            elseif resInfo.quality == 2 then
                itemColor = GameConfig.ColorMap.COLOR_GREEN
            elseif resInfo.quality == 3 then
                itemColor = GameConfig.ColorMap.COLOR_BLUE
            elseif resInfo.quality == 4 then
                itemColor = GameConfig.ColorMap.COLOR_PURPLE
            elseif resInfo.quality == 5 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 6 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 7 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 8 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 9 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 10 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 11 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 12 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 13 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 14 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 15 then
                itemColor = GameConfig.ColorMap.COLOR_BLUE
            elseif resInfo.quality == 16 then
                itemColor = GameConfig.ColorMap.COLOR_PURPLE
            elseif resInfo.quality == 17 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 18 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 19 then
                itemColor = GameConfig.ColorMap.COLOR_BLUE
            elseif resInfo.quality == 20 then
                itemColor = GameConfig.ColorMap.COLOR_PURPLE
            elseif resInfo.quality == 21 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 22 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            end
            -- local newEquipStr = common:fill(equipStr,rewardStr)
            -- table.insert(wordList,rewardStr)
            local finalStr = getReward
            if oneReward.itemStatus then
                if oneReward.itemStatus == 1 then
                    finalStr = finalStr .. godlyEquip
                end
            end
            finalStr = finalStr .. rewardStr
            table.insert(wordList, finalStr)
            table.insert(colorList, itemColor)
        end
    end

    return wordList, colorList

    -- insertMessageFlow(wordList, colorList)
end


function NodeHelper:horizontalSpacingAndVerticalSpacing_LLLL(str, fontName, fontSize, horizontalSpacing, verticalSpacing, lineWidth, colorStr)
    local labelTTFArray = { }
    local color = colorStr or "0 0 0"
    local color3B = self:_getColorFromSetting(color)
    local index = 1
    local index_max = string.len(str)
    local isEnd = true
    local returnStr = ""
    while isEnd do
        local curByte = string.byte(str, index)
        if curByte > 0 and curByte <= 127 then
            local s = string.sub(str, index, index + 1 - 1)
            local label = CCLabelTTF:create(s, fontName, fontSize)
            table.insert(labelTTFArray, label)
            index = index + 1
        else
            local s = string.sub(str, index, index + 3 - 1)
            local label = CCLabelTTF:create(s, fontName, fontSize)
            table.insert(labelTTFArray, label)
            index = index + 3
        end
        if index > index_max then
            isEnd = false
        end
    end

    ----------------------------------------------------------------------------------------
    local node = CCNode:create()
    local maxWidth = 0
    -- 总宽度
    local currentWidth = 0
    -- 当前的宽度
    local currentHeight = 0
    -- 总高度
    local labelHeight = 0
    local positionY = 0
    local line = 1
    -- 行数
    for i = 1, #labelTTFArray do
        local label = labelTTFArray[i]
        label:setColor(color3B)
        labelHeight = label:getContentSize().height
        label:setAnchorPoint(ccp(0, 1))
        node:addChild(label)
        if i == 1 then
            currentWidth = label:getContentSize().width
            currentHeight = label:getContentSize().height
            label:setPosition(ccp(0, currentHeight * (line - 1)))
            positionY = label:getPositionY()
            if currentWidth - horizontalSpacing > maxWidth then
                maxWidth = currentWidth - horizontalSpacing
            end
            returnStr = returnStr .. label:getString()
        else
            if currentWidth + label:getContentSize().width > lineWidth then
                -- 新一行
                currentWidth = label:getContentSize().width

                label:setPosition(ccp(0, -(labelHeight * line + verticalSpacing)))
                -- 记录高度
                currentHeight = labelHeight * line + math.abs(verticalSpacing) * (line - 1)
                line = line + 1

                positionY = label:getPositionY()

                returnStr = returnStr .. "\n" .. label:getString()
            else

                currentWidth = currentWidth + horizontalSpacing
                label:setPosition(ccp(currentWidth, positionY))
                currentWidth = currentWidth + label:getContentSize().width
                if currentWidth - horizontalSpacing > maxWidth then
                    maxWidth = currentWidth - horizontalSpacing
                end
                returnStr = returnStr .. label:getString()
            end
        end
    end
    currentHeight = currentHeight - horizontalSpacing
    return node, currentHeight, maxWidth, labelHeight, line, returnStr
    -- 返回node  总高度  总宽度  label的高度 行数
end


function NodeHelper:horizontalSpacingAndVerticalSpacing(str, fontName, fontSize, horizontalSpacing, verticalSpacing, lineWidth, colorStr)
    local labelTTFArray = { }
    local color = colorStr or "0 0 0"
    local color3B = self:_getColorFromSetting(color)
    local index = 1
    local index_max = string.len(str)
    local isEnd = true

    while isEnd do
        local curByte = string.byte(str, index)
        if curByte > 0 and curByte <= 127 then
            local s = string.sub(str, index, index + 1 - 1)
            local label = CCLabelTTF:create(s, fontName, fontSize)
            table.insert(labelTTFArray, label)
            index = index + 1
        else
            local s = string.sub(str, index, index + 3 - 1)
            local label = CCLabelTTF:create(s, fontName, fontSize)
            table.insert(labelTTFArray, label)
            index = index + 3
        end
        if index > index_max then
            isEnd = false
        end
    end

    ----------------------------------------------------------------------------------------
    local node = CCNode:create()
    local maxWidth = 0
    -- 总宽度
    local currentWidth = 0
    -- 当前的宽度
    local currentHeight = 0
    -- 总高度
    local labelHeight = 0
    local positionY = 0
    local line = 1
    local isReturnLabel = false
    local lineHeight = 0
    -- 行数
    for i = 1, #labelTTFArray do
        local label = labelTTFArray[i]
        label:setColor(color3B)
        labelHeight = label:getContentSize().height
        lineHeight = math.max(lineHeight, labelHeight)
        label:setAnchorPoint(ccp(0, 1))
        node:addChild(label)
        if i == 1 then
            currentWidth = label:getContentSize().width
            currentHeight = label:getContentSize().height
            label:setPosition(ccp(0, currentHeight * (line - 1)))
            positionY = label:getPositionY()
            maxWidth = currentWidth
        else
            if currentWidth + label:getContentSize().width + horizontalSpacing > lineWidth or isReturnLabel then
                -- 新一行
                currentWidth = label:getContentSize().width

                label:setPosition(ccp(0, -(lineHeight * line + verticalSpacing)))
                -- 记录高度
                -- currentHeight = labelHeight * line + math.abs(verticalSpacing) * (line - 1)
                line = line + 1

                positionY = label:getPositionY()

                currentHeight = lineHeight * line + math.abs(verticalSpacing) * (line - 1)
            else

                currentWidth = currentWidth + horizontalSpacing
                label:setPosition(ccp(currentWidth, positionY))
                currentWidth = currentWidth + label:getContentSize().width
                if currentWidth > maxWidth then
                    maxWidth = currentWidth
                end
                --                      if currentWidth - horizontalSpacing > maxWidth then
                --                        maxWidth = currentWidth - horizontalSpacing
                --                      end
            end
            local str = label:getString()
            if str == "\n" then
                isReturnLabel = true
            else
                isReturnLabel = false
            end
        end
    end
    -- currentHeight = currentHeight - (line * horizontalSpacing - horizontalSpacing)
    return node, currentHeight, maxWidth, labelHeight, line
    -- 返回node  总高度  总宽度  label的高度 行数
end

function NodeHelper:utf8tochars(input)
    local list = {}
    local len  = string.len(input)
    local index = 1
    local arr  = { 0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
    while index <= len do
       local c = string.byte(input, index)
       local offset = 1
       if c < 0xc0 then
           offset = 1
       elseif c < 0xe0 then
           offset = 2
       elseif c < 0xf0 then
           offset = 3
       elseif c < 0xf8 then
           offset = 4
       elseif c < 0xfc then
           offset = 5
       end
       local str = string.sub(input, index, index+offset-1)
       -- print(str)
       index = index + offset
       table.insert(list, {byteNum = offset, char = str})
    end
    
    return list
end

function NodeHelper:isFileExist(filePath)
    if filePath == nil then return false end
    local writablePath = CCFileUtils:sharedFileUtils():getWritablePath()
    local isFileExist = false
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        if string.find(writablePath, "Debug.win32") then
            --CCLuaLog("1: " .. writablePath)
            writablePath = string.gsub(writablePath, "Code_Client\\build\\Debug.win32", "Resource_bc")
            --CCLuaLog("2: " .. writablePath)
        end
        local fileName = writablePath .. filePath
        --CCLuaLog(fileName)
        isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(fileName)
        --if not isFileExist and string.find(fileName, ".json") then
        --    string.gsub(fileName, ".json", ".skel")
        --    CCLuaLog(fileName)
        --    isFileExist = CCFileUtils:sharedFileUtils():isFileExist(fileName)
        --end
    elseif CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
        local fileName = filePath
        local fileName2 = writablePath .. "/hotUpdate/" .. filePath
        isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(fileName) or CCFileUtils:sharedFileUtils():isFileExist(fileName2)
        --if not isFileExist and string.find(filePath, ".json") then
        --    string.gsub(fileName, ".json", ".skel")
        --    string.gsub(fileName2, ".json", ".skel")
        --    isFileExist = CCFileUtils:sharedFileUtils():isFileExist(fileName) or CCFileUtils:sharedFileUtils():isFileExist(fileName2)
        --end
    else
        local fileName = writablePath .. "/assets/" .. filePath
        local fileName2 = writablePath .. "/hotUpdate/" .. filePath
        isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(fileName) or CCFileUtils:sharedFileUtils():isFileExist(fileName2)
        --if not isFileExist and string.find(filePath, ".json") then
        --    string.gsub(fileName, ".json", ".skel")
        --    string.gsub(fileName2, ".json", ".skel")
        --    isFileExist = CCFileUtils:sharedFileUtils():isFileExist(fileName) or CCFileUtils:sharedFileUtils():isFileExist(fileName2)
        --end
    end
    if not isFileExist then
        CCLuaLog(filePath)
    end
    --CCLuaLog(isFileExist and "1111111" or "2222222")
    return isFileExist
end

function NodeHelper:getWritablePath() 
     local writablePath = CCFileUtils:sharedFileUtils():getWritablePath()
     if CC_TARGET_PLATFORM_LUA ~= common.platform.CC_PLATFORM_WIN32 then
         local fileName = writablePath .. "/assets/" 
         local fileName2 = writablePath .. "/hotUpdate/"
         writablePath = fileName2--CCFileUtils:sharedFileUtils():isFileExist(fileName2) and fileName2 or fileName
     end
     return writablePath
end

function NodeHelper:isDebug()
    local debugCfg = ConfigManager.loadCfgByIoString("platform.cfg")
    local isDebug = string.find(debugCfg, "\"isDebug\":\"true\"")
    if isDebug then
        return true
    else
        return false
    end
end
-----------------------------------------------------------------
function NodeHelper:sleep(n)
    if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end
function NodeHelper:loadTestSpine(parent, sex, class)
    local backNode = CCNode:create()
    parent:addChild(backNode)
    backNode:removeAllChildren()
    local spine = SpineContainer:create("Spine/CharacterSpine", sex .. class)
    --local spine = SpineContainer:create("Spine/CharacterSpine", "199")
    spine:setToSetupPose()
    spine:runAnimation(1, "wait_0", 0)
    spine:setTimeScale(0)
    local spineNode = tolua.cast(spine, "CCNode")
    --BODY
    spineNode:setPosition(ccp(52, 15))
    spineNode:setScale(0.62)
    --HEADICON
    --spineNode:setPosition(ccp(66, -154))
    --spineNode:setScaleX(-1)
    backNode:addChild(spineNode)

    return spine, backNode
end
function NodeHelper:createHeadIcon(spine, backNode, sex, class)
    local CONST = require("Battle.NewBattleConst")
    local render = CCRenderTexture:create(130, 130)
    local race = 1
    local openEye = {
        [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [9] = true, [18] = true, [19] = true, 
        [20] = true, [21] = true, [22] = true, [23] = true, [24] = true, 
    }
    for eyeL = 1, 24 do  --眼睛L
        if openEye[eyeL] then
            for i = 1, #CONST.EYES_CHANGE_L do
                spine:setAttachmentForLua(CONST.EYES_CHANGE_L[i], CONST.EYES_CHANGE_L[i] .. "a" .. string.format("%02d", eyeL))
            end
            for eyeR = 1, 24 do  --眼睛R
                if openEye[eyeR] then
                    for n = 1, #CONST.EYES_CHANGE_R do
                        spine:setAttachmentForLua(CONST.EYES_CHANGE_R[n], CONST.EYES_CHANGE_R[n] .. "a" .. string.format("%02d", eyeR))
                    end
                    for skin = 1, 3 do --膚色
                        for j = 1, #CONST.SKIN_COLOR_CHANGE do
                            local r = CONST.SKIN_COLOR[skin][1] / 255
                            local g = CONST.SKIN_COLOR[skin][2] / 255
                            local b = CONST.SKIN_COLOR[skin][3] / 255
                            spine:setSlotColorForLua(CONST.SKIN_COLOR_CHANGE[j], r, g, b)
                        end
                        --for hairStyle = 1, 5 do --髮型
                        for hairStyle = 6, 10 do --髮型
                            for k = 1, #CONST.HAIR_COLOR_CHANGE do
                                spine:setAttachmentForLua(CONST.HAIR_COLOR_CHANGE[k], CONST.HAIR_COLOR_CHANGE[k] .. "a" .. sex .. string.format("%02d", hairStyle))
                            end
                            for l = 1, #CONST.HAIR_CHANGE do
                              spine:setAttachmentForLua(CONST.HAIR_CHANGE[l], CONST.HAIR_CHANGE[l] .. "a" .. sex .. string.format("%02d", hairStyle))
                            end
                            for hairColor = 1, 10 do --髮色
                                for m = 1, #CONST.HAIR_COLOR_CHANGE do
                                    local r = CONST.HAIR_COLOR[hairColor][1] / 255
                                    local g = CONST.HAIR_COLOR[hairColor][2] / 255
                                    local b = CONST.HAIR_COLOR[hairColor][3] / 255
                                    spine:setSlotColorForLua(CONST.HAIR_COLOR_CHANGE[m], r, g, b)
                                end
                                spine:setToSetupPose()
                                spine:runAnimation(1, "photo_0", -1)
                                
                                render:clear(0, 0, 0, 0)
                                render:begin()
                                backNode:visit()
                                render:endToLua()
                                render:saveToFile("HEADICON/" .. race .. sex .. class .. string.format("%02d", eyeL) .. string.format("%02d", eyeR)
                                                              .. skin .. sex  .. string.format("%02d", hairStyle)  .. string.format("%02d", hairColor)
                                                              .. ".png", 1)
                                --render:saveToFile("HEADICON/" .. "1199" .. string.format("%02d", eyeL) .. string.format("%02d", eyeR)
                                --                              .. "119904" .. ".png", 1)
                            end
                        end
                    end
                end
            end
        end
    end
end
function NodeHelper:createBodyIcon(spine, backNode, sex, class)
    local CONST = require("Battle.NewBattleConst")
    local render = CCRenderTexture:create(100, 200)
    local race = 1
    local openEye = {
        [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [9] = true, [18] = true, [19] = true, 
        [20] = true, [21] = true, [22] = true, [23] = true, [24] = true, 
    }
    for eyeL = 1, 24 do  --眼睛L
        if openEye[eyeL] then
            for i = 1, #CONST.EYES_CHANGE_L do
                spine:setAttachmentForLua(CONST.EYES_CHANGE_L[i], CONST.EYES_CHANGE_L[i] .. "a" .. string.format("%02d", eyeL))
            end
            for eyeR = 1, 24 do  --眼睛R
                if openEye[eyeR] then
                    for n = 1, #CONST.EYES_CHANGE_R do
                        spine:setAttachmentForLua(CONST.EYES_CHANGE_R[n], CONST.EYES_CHANGE_R[n] .. "a" .. string.format("%02d", eyeR))
                    end
                    for skin = 1, 3 do --膚色
                        for j = 1, #CONST.SKIN_COLOR_CHANGE do
                            local r = CONST.SKIN_COLOR[skin][1] / 255
                            local g = CONST.SKIN_COLOR[skin][2] / 255
                            local b = CONST.SKIN_COLOR[skin][3] / 255
                            spine:setSlotColorForLua(CONST.SKIN_COLOR_CHANGE[j], r, g, b)
                        end
                        --for hairStyle = 1, 5 do --髮型
                        for hairStyle = 6, 10 do --髮型
                            for k = 1, #CONST.HAIR_COLOR_CHANGE do
                                spine:setAttachmentForLua(CONST.HAIR_COLOR_CHANGE[k], CONST.HAIR_COLOR_CHANGE[k] .. "a" .. sex .. string.format("%02d", hairStyle))
                            end
                            for l = 1, #CONST.HAIR_CHANGE do
                              spine:setAttachmentForLua(CONST.HAIR_CHANGE[l], CONST.HAIR_CHANGE[l] .. "a" .. sex .. string.format("%02d", hairStyle))
                            end
                            for hairColor = 1, 10 do --髮色
                                for m = 1, #CONST.HAIR_COLOR_CHANGE do
                                    local r = CONST.HAIR_COLOR[hairColor][1] / 255
                                    local g = CONST.HAIR_COLOR[hairColor][2] / 255
                                    local b = CONST.HAIR_COLOR[hairColor][3] / 255
                                    spine:setSlotColorForLua(CONST.HAIR_COLOR_CHANGE[m], r, g, b)
                                end
                                spine:setToSetupPose()
                                
                                render:clear(0, 0, 0, 0)
                                render:begin()
                                backNode:visit()
                                render:endToLua()
                                render:saveToFile("BODY/body_" .. race .. sex .. class .. string.format("%02d", eyeL) .. string.format("%02d", eyeR)
                                                              .. skin .. sex  .. string.format("%02d", hairStyle)  .. string.format("%02d", hairColor)
                                                              .. ".png", 1)
                                --render:saveToFile("BODY/body_" .. "1199" .. string.format("%02d", eyeL) .. string.format("%02d", eyeR)
                                --                              .. "119904" .. ".png", 1)
                            end
                        end
                    end
                end
            end
        end
    end
end
function NodeHelper:getNewRoleTable(roleId)
    -- 先改成固定數值避免error
    local roleTable = {}
    roleTable.race = 1
    roleTable.sex = 2
    roleTable.class = 10
    roleTable.blood = 3
    roleTable.element = 1
    roleTable.eyeL = 20
    roleTable.eyeR = 20
    roleTable.skin = 1
    roleTable.voice = 21001
    roleTable.hairStyle = 201
    roleTable.hairColor = 4
    roleTable.itemId = roleId
    roleTable.token = 0
    roleTable.id = roleId
    roleTable.roleId = roleTable.race .. roleTable.sex .. roleTable.class .. roleTable.blood .. roleTable.element .. roleTable.eyeL ..
                       roleTable.eyeR .. roleTable.skin .. roleTable.voice .. roleTable.hairStyle .. roleTable.hairColor
    roleTable.star = 1
    roleTable.icon = "UI/NewPlayeIcon/MainPageIcon/Role/12102020120104.png"
    roleTable.body = "UI/NewPlayeIcon/CardIcon/Role/body_12102020120104.png"
    roleTable.fileName = "12102020120104.png"
    return roleTable
end
function NodeHelper:Add_9_16_Layer(container,NodeName)
    local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    local designWidth = 720    -- 设计的宽度 (9:16)
    local designHeight = 1280  -- 设计的高度 (9:16)
    
    -- 计算实际分辨率与设计分辨率的比例
    local scaleX = visibleSize.width / designWidth
    local scaleY = visibleSize.height / designHeight
    
    -- 选择较小的缩放比例，确保内容不会被裁剪
    local scale = math.min(scaleX, scaleY)
    
    -- 计算9:16区域的实际显示宽度和高度
    local adjustedWidth = designWidth * scale
    local adjustedHeight = designHeight * scale
    
    -- 计算遮挡区域的宽度和高度
    local leftWidth = (visibleSize.width - adjustedWidth) / 2
    local rightWidth = leftWidth
    local topHeight = (visibleSize.height - adjustedHeight) / 2
    local bottomHeight = topHeight

    
    -- 获取目标容器
    local targetContainer = container:getVarNode(NodeName)
    if not targetContainer then
        print("Error: NodeName does not exist.")
        return bottomHeight
    end
    

    -- 确保 targetContainer 覆盖整个屏幕
    targetContainer:setAnchorPoint(ccp(0, 0))
    targetContainer:setPosition(ccp(0, 0))
    targetContainer:setContentSize(visibleSize)  -- 设置为屏幕尺寸

    -- 创建遮挡Layer的函数，确保锚点和位置正确
    local function createLayer(width, height, posX, posY)
        local layer = CCLayerColor:create(ccc4(0, 0, 0, 255))  -- 创建一个黑色遮挡Layer
        layer:setContentSize(CCSize(width, height))            -- 设置大小
        layer:setAnchorPoint(ccp(0, 0))                        -- 设置锚点在左下角
        layer:setPosition(ccp(posX, posY))                     -- 设置位置
        targetContainer:addChild(layer)                        -- 添加到指定容器中
        return layer
    end
    
   ---- 创建并设置左侧遮挡Layer
   --createLayer(leftWidth, visibleSize.height, 0, 0)
   --
   ---- 创建并设置右侧遮挡Layer
   --createLayer(rightWidth, visibleSize.height, visibleSize.width - rightWidth, 0)
    
    -- 创建并设置顶部遮挡Layer
    --createLayer(adjustedWidth, topHeight, leftWidth, adjustedHeight + bottomHeight)
    
    -- 创建并设置底部遮挡Layer
    createLayer(adjustedWidth, bottomHeight, leftWidth, 0)

    return bottomHeight
end
return NodeHelper
