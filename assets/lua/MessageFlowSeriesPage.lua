NodeHelper = require("NodeHelper")
--------------------------------------------------------------------------------
local GameConfig = require("GameConfig")
local currentPos = 0
local wordList = {}
local MaxSize = 12
local TopIndex = 1
local CurrentIndex = 1

-----------------插入消息流，并弹出-------------
--参数： wordList 与 一一对应的 colorList

--实例代码：
--[[
local wordList = {}
local colorList = {}	
for i=1,10 do
	local oneStr = tostring(i)
	local colorStr = GameConfig.ColorMap.COLOR_PURPLE
	table.insert(wordList,oneStr)
	table.insert(colorList,colorStr)	
end
insertMessageFlow(wordList,colorList)
--]]
function insertMessageFlowSeries(wordTable, colorList, htmlFlag)
	if #wordTable ~= #colorList and not htmlFlag then
		CCLuaLog("Error in insertMessageFlow size not right")
		return 
	end
	if #wordTable <= 0 or #wordTable > MaxSize then return end

	--clear data and ui
	local size = #wordList

	for i = size, 1, -1 do
		table.remove(wordList, 1)
	end

	local nodeMsgForLua = MainFrame:getInstance():getMsgNodeForLua()
	local currentSize = 0
    if 	nodeMsgForLua:getChildren()~=nil then
        currentSize = nodeMsgForLua:getChildren():count()
    end
    
    currentSize = currentSize + (#wordTable)
    
    if currentSize > MaxSize then
        for i = 1, (currentSize - MaxSize) do
            if nodeMsgForLua:getChildByTag(TopIndex) ~= nil then
                nodeMsgForLua:getChildByTag(TopIndex):stopAllActions()
            end
            if nodeMsgForLua:getChildByTag(TopIndex)  then 
                nodeMsgForLua:removeChildByTag(TopIndex, true)
            end 
            TopIndex = TopIndex + 1
            if TopIndex > MaxSize then
                TopIndex = 1
            end
        end
    end

	
	--nodeMsgForLua:removeAllChildren()	
	--insert
	currentPos = -100

    if htmlFlag then
	    InsertWordInNodeSeriesForHtml(wordTable)
	else
	    InsertWordInNodeSeries(wordTable, colorList)
	end
end

-------------------private function --------------------
function InsertWordInNodeSeries(wordTable, colorList)
	local nodeMsgForLua = MainFrame:getInstance():getMsgNodeForLua()
	wordList = wordTable
	local size = #wordList
	local delayTime = 0.1
	for i = 1, #wordList do
		local array = CCArray:create()
		local oneContent = wordList[i]
		local itemColor = colorList[i]
		if oneContent ~= nil then
			local oneWordNode = ScriptContentBase:create("TextPromptAniEx.ccbi")
			--oneWordNode:setAnchorPoint(ccp(0.5, 0.5));
			oneWordNode:setPosition(ccp(0, currentPos))
			local wordText = oneWordNode:getVarLabelBMFont("mWordText")
			if not wordText then
				wordText = oneWordNode:getVarLabelTTF("mWordText")
			end
            wordText:setString(oneContent)				
            local color3B = StringConverter:parseColor3B(itemColor)
            wordText:setColor(color3B)
            local height = wordText:getContentSize().height
                  
            array:addObject(CCDelayTime:create(delayTime * (i - 1)))				
            local functionAction = CCCallFunc:create(function()
                local curIndex = oneWordNode:getTag()
                oneWordNode:runAnimation("TextAni")	
                
                if TopIndex > curIndex then
                    for j = TopIndex, MaxSize do
                        local childNode = nodeMsgForLua:getChildByTag(j)
                        if childNode ~= nil then
                            local posY = childNode:getPositionY() + height 
                            childNode:setPositionY(posY)
                        end
                    end	
                    for j = 1, (curIndex - 1) do
                        local childNode = nodeMsgForLua:getChildByTag(j)
                        if childNode ~= nil then
                            local posY = childNode:getPositionY() + height 
                            childNode:setPositionY(posY)
                        end
                    end	
                else
                    for j = TopIndex, (curIndex - 1) do
                        local childNode = nodeMsgForLua:getChildByTag(j)
                        if childNode ~= nil then
                            local posY = childNode:getPositionY() + height 
                            childNode:setPositionY(posY)
                        end
                    end	
                end
              		
            end)
            array:addObject(functionAction)
            
            oneWordNode:setTag(CurrentIndex)
            CurrentIndex = CurrentIndex + 1
            if CurrentIndex > MaxSize then
                CurrentIndex = 1
            end
            nodeMsgForLua:addChild(oneWordNode)
            oneWordNode:release()
            
            local seq = CCSequence:create(array)	
            oneWordNode:runAction(seq)
		end
	end	
end
-----------------------html------------------------------------------------
function InsertWordInNodeSeriesForHtml(wordTable)
	local nodeMsgForLua = MainFrame:getInstance():getMsgNodeForLua()
	wordList = wordTable
	local size = #wordList
	local delayTime = 0.1
	for i = 1, #wordList do
	    local array = CCArray:create()
		local oneContent = wordList[i]
		if oneContent ~= nil then
            local oneWordNode = ScriptContentBase:create("TextPromptAniEx.ccbi")
            --oneWordNode:setAnchorPoint(ccp(0.5, 0.5))
            oneWordNode:setPosition(ccp(0, currentPos))
            local wordText = oneWordNode:getVarLabelBMFont("mWordText")
			if not wordText then
				wordText = oneWordNode:getVarLabelTTF("mWordText")
			end
            local htmlText = NodeHelper:setCCHTMLLabelAutoFixPosition(wordText, CCSize(400,32), oneContent)
            wordText:setVisible(false)				

            local height = 32
                  
            array:addObject(CCDelayTime:create(delayTime * (i - 1)))				
            local functionAction = CCCallFunc:create(function()
                local curIndex = oneWordNode:getTag()
                oneWordNode:runAnimation("TextAni")	
                
                if TopIndex > curIndex then
                    for j = TopIndex, MaxSize do
                        local childNode = nodeMsgForLua:getChildByTag(j)
                        if childNode ~= nil then
                            local posY = childNode:getPositionY() + height 
                            childNode:setPositionY(posY)
                        end
                    end	
                    for j = 1, (curIndex - 1) do
                        local childNode = nodeMsgForLua:getChildByTag(j)
                        if childNode ~= nil then
                            local posY = childNode:getPositionY() + height 
                            childNode:setPositionY(posY)
                        end
                    end	
                else
                    for j = TopIndex, (curIndex - 1) do
                        local childNode = nodeMsgForLua:getChildByTag(j)
                        if childNode ~= nil then
                            local posY = childNode:getPositionY() + height 
                            childNode:setPositionY(posY)
                        end
                    end	
                end
              		
            end)
            array:addObject(functionAction)
            
            oneWordNode:setTag(CurrentIndex)
            CurrentIndex = CurrentIndex + 1
            if CurrentIndex > MaxSize then
                CurrentIndex = 1
            end
            nodeMsgForLua:addChild(oneWordNode)
            oneWordNode:release()
            
            local seq = CCSequence:create(array)	
            oneWordNode:runAction(seq)
		end
	end	
end

local totalIndex = 0
function insertNewMessageFlowSeries(wordTable)
	if #wordTable <= 0 then return end
	totalIndex = 0
	--clear data and ui
	local size = #wordList	
	
	for i = size, 1, -1 do	
		table.remove(wordList, 1)
	end		
	local nodeMsgForLua = MainFrame:getInstance():getMsgNodeForLua()	
	if nodeMsgForLua then	
		nodeMsgForLua:removeAllChildren()	
	end
	--insert
	currentPos = 0
	for i=1, #wordTable do
		InsertNewWordInNode(wordTable[i])
	end
	
end

function InsertNewWordInNode(strContent)
	local nodeMsgForLua = MainFrame:getInstance():getMsgNodeForLua()
	table.insert(wordList, strContent)
	local size = #wordList	
	local delayTime = 0.1
	for i = size, 1, -1 do
		local oneContent = wordList[i]
		if oneContent ~= nil and nodeMsgForLua ~= nil then
			local taggedchild = nodeMsgForLua:getChildByTag(i)
			local oneWordNode = ScriptContentBase:create("GuildTreeMessageBox.ccbi")
			oneWordNode:setPosition(ccp(0, 0))
			local wordText = oneWordNode:getVarLabelBMFont("mMsg")
			if not wordText then
				wordText = oneWordNode:getVarLabelTTF("mMsg")
			end
			--wordText:setString(oneContent)
			local htmlText = NodeHelper:setCCHTMLLabelAutoFixPosition(wordText, CCSize(500, 32), oneContent)
			wordText:setVisible(false)
				
			totalIndex = totalIndex + 1
			local array = CCArray:create()		
			local functionAction = CCCallFunc:create(function()
				--oneWordNode:runAnimation("FadeOutAni")						
			end)
			array:addObject(CCDelayTime:create(i - 2))
			array:addObject(CCCallFuncN:create(function(node)
				node:setVisible(true)
			end))
			array:addObject(CCMoveTo:create(1.5, ccp(0, 350)))
			--array:addObject(CCFadeOut:create(1.5))
			--array:addObject(functionAction)
			local functionRemove = CCCallFuncN:create(function(node)
				node:stopAllActions()
				node:removeFromParentAndCleanup(true)
				-- if nodeMsgForLua:getChildByTag(totalIndex)~=nil then
				-- 	nodeMsgForLua:getChildByTag(totalIndex):stopAllActions()
				-- 	nodeMsgForLua:removeChildByTag(totalIndex,true)
				-- 	CCLuaLog("------------------ remove tag " .. totalIndex)
				-- 	totalIndex = totalIndex - 1
				-- 	if totalIndex < 0 then totalIndex = 0 end
				-- end
			end)
			array:addObject(functionRemove)
			local seq = CCSequence:create(array)
			oneWordNode:runAction(seq)
			oneWordNode:setVisible(false)
			oneWordNode:setTag(totalIndex)
			-- CCLuaLog("------------------ add tag " .. totalIndex)
			nodeMsgForLua:addChild(oneWordNode)
			oneWordNode:release()							
		end			
	end		
end

function CleanNodeMsg()
	local nodeMsgForLua = MainFrame:getInstance():getMsgNodeForLua()
	if nodeMsgForLua then
		nodeMsgForLua:removeAllChildren()
	end
end