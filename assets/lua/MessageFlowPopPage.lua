--------------------------------------------------------------------------------
local GameConfig = require("GameConfig")
local currentPos = 0
local wordList = {}

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
function insertMessageFlow(wordTable, colorList)
	if #wordTable ~= #colorList then
		CCLuaLog("Error in insertMessageFlow size not right")
		return
	end
	if #wordTable <= 0 then return end
	
	--clear data and ui
	local size = #wordList	
	
	for i = size, 1,-1 do	
		table.remove(wordList,1)
	end		
	local nodeMsgForLua = MainFrame:getInstance():getMsgNodeForLua()	
	if nodeMsgForLua then	
		nodeMsgForLua:removeAllChildren()	
	end
	--insert
	currentPos = 0
	for i=1,#wordTable do
		InsertWordInNode(wordTable[i],colorList[i])
	end
	
end


-------------------private function --------------------
function InsertWordInNode(strContent, itemColor)
	local nodeMsgForLua = MainFrame:getInstance():getMsgNodeForLua()
	table.insert(wordList, strContent)
	local size = #wordList
	local delayTime = 0.1
	for i = size, 1, -1 do
		local oneContent = wordList[i]
		--修复了一个可能会弹出lua报错的情况
		if oneContent ~= nil and nodeMsgForLua ~= nil then
			local taggedchild = nodeMsgForLua:getChildByTag(i)
			if taggedchild ~= nil then
			    local currentHeight = taggedchild:getPositionY()
				local height = taggedchild:getContentSize().height
				currentHeight = currentHeight + height / 2
				taggedchild:setPosition(ccp(0, currentHeight))
				--currentPos = currentPos + height
			else
				local oneWordNode = CCBManager:getInstance():createAndLoad2("TextPromptAni.ccbi")
				--oneWordNode:setAnchorPoint(ccp(0.5, 0.5));
				oneWordNode:setPosition(ccp(0, currentPos))
				local wordText = oneWordNode:getVarLabelBMFont("mWordText")
				if not wordText then
					wordText = oneWordNode:getVarLabelTTF("mWordText")
				end
                --local color3B = StringConverter:parseColor3B(itemColor)
                local color3B = StringConverter:parseColor3B("255 255 255")
                wordText:setTextBorderEnabled(true)
                local r, g, b = unpack(common:split((itemColor), " "))
                wordText:setTextBorderColor(188 / 255, 10 / 255, 247 / 255, 0.9)
                wordText:setFontSize(32)
				wordText:setString(" " .. oneContent .. " ")				
				wordText:setColor(color3B)
				local array = CCArray:create()
				delayTime = delayTime * (i - 1)
				array:addObject(CCDelayTime:create(delayTime));			
				local functionAction = CCCallFunc:create(function()
					oneWordNode:runAnimation("TextAni")						
				end)
				array:addObject(functionAction)
				local seq = CCSequence:create(array)
				oneWordNode:setTag(i)
				oneWordNode:runAction(seq)
				nodeMsgForLua:addChild(oneWordNode)
				local height = wordText:getContentSize().height * 1.2
				currentPos = currentPos - height / 2	
							
			end
		end
	end		
end
-----------------------------------------------------------------