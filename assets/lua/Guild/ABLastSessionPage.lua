

local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local NodeHelper = require("NodeHelper")
local thisPageName = "ABLastSessionPage"
local opcodes = {
}

local option = {
	ccbiFile = "GuildLastReportPopUp.ccbi",
	handlerMap = {
		onClose = "onClose"
	},
	DataHelper = ABManager
}

local ABLastSessionPage = BasePage:new(option,thisPageName,nil,opcodes)



-----------------------------------------------
--BEGIN ABMainFightingContent 对阵图排行content
----------------------------------------------
local ABMainLaseFightingContent = {
    ccbiFile = "GuildTreeDiagramItem.ccbi"
}
function ABMainLaseFightingContent.onFunction(eventName,container)
    if eventName == "luaRefreshItemView" then
		ABMainLaseFightingContent.onRefreshItemView(container);
    elseif string.sub(eventName,1,10)=="onGuildBtn" then
        local index = tonumber(string.sub(eventName,11))

        local tab = 0--math.ceil(index/2)
        if index > 16 then 
            tab = math.ceil((index-16)/2)
        else
            tab = math.ceil((index+16)/2)
        end

        if ABManager.lastFightList~=nil then
            local info = ABManager.lastFightList.round32_16[tab]
            if info~=nil then
                local id = 0
                if index%2 == 0 then
                    id = info.rightId
                else
                    id = info.leftId
                end
                showABFightListPage(id,true)
            end
        end
     elseif eventName == "onAgainstPlan" then
        showABFightListPage(nil,true) 
	end	
end

function ABMainLaseFightingContent.onRefreshItemView(container)
    local nodeVisible = {}
    local labelStr = {}

    --对阵图显示
    if ABManager.lastFightList~=nil then
        local winnerId = 0
        for i=1,#ABManager.lastFightList.round2_1 do
            local info = ABManager.lastFightList.round2_1[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                winnerId = info.winId
                if info.winId == info.leftId then
                    nodeVisible["mWinLine2"..tostring(i).."1"] = true
                    nodeVisible["mWinLine2"..tostring(i).."2"] = false

                    --显示冠军label
                    labelStr.mChampionName = info.leftName
                else
                    nodeVisible["mWinLine2"..tostring(i).."1"] = false
                    nodeVisible["mWinLine2"..tostring(i).."2"] = true

                    --显示冠军label
                    labelStr.mChampionName = info.rightName
                end
            end
        end

        local leftIndex = 0
        local rightIndex = 0
        for i=1,#ABManager.lastFightList.round32_16 do
            local info = ABManager.lastFightList.round32_16[i]
            if i <= 8 then
                leftIndex = (i*2) - 1 + 16
                rightIndex = (i*2) + 16 
            else
                leftIndex = (i - 8) * 2 - 1
                rightIndex = (i - 8) * 2 
            end

            labelStr["mGuildName"..(leftIndex)] = info.leftName
            labelStr["mGuildName"..(rightIndex)] = info.rightName

            if AllianceId ~= nil and AllianceId ~= 0  then
               if info.leftId == AllianceId then
                  if container:getVarMenuItemImage("mBtnPic" .. (leftIndex)) ~= nil then
                    container:getVarMenuItemImage("mBtnPic" .. (leftIndex)):setNormalImage(CCSprite:create(GameConfig.ABGuildBackgroundImg.Mine))
                  end
               --[[
               else
                  if container:getVarMenuItemImage("mBtnPic" .. (leftIndex)) ~= nil then
                    container:getVarMenuItemImage("mBtnPic" .. (leftIndex)):setNormalImage(CCSprite:create(GameConfig.ABGuildBackgroundImg.DefaultLeft))
                  end
                ]]
               end

               if info.rightId == AllianceId then
                  if container:getVarMenuItemImage("mBtnPic" .. (rightIndex)) ~= nil then
                    container:getVarMenuItemImage("mBtnPic" .. (rightIndex)):setNormalImage(CCSprite:create(GameConfig.ABGuildBackgroundImg.Mine))
                  end
               --[[
               else
                  if container:getVarMenuItemImage("mBtnPic" .. (rightIndex)) ~= nil then 
                    container:getVarMenuItemImage("mBtnPic" .. (rightIndex)):setNormalImage(CCSprite:create(GameConfig.ABGuildBackgroundImg.DefaultRight))
                  end
               ]]
               end
            end

            if winnerId ~= nil and winnerId ~= 0 then
                 if container:getVarSprite("mChampionPic" .. (leftIndex) ) ~= nil then
                    container:getVarSprite("mChampionPic" .. (leftIndex) ):setVisible( info.leftId == winnerId )
                 end
                 if container:getVarSprite("mChampionPic" .. (leftIndex) ) ~= nil then
                    container:getVarSprite("mChampionPic" .. (rightIndex) ):setVisible( info.rightId == winnerId )
                 end
            end

            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine32"..tostring(i).."1"] = true
                    nodeVisible["mWinLine32"..tostring(i).."2"] = false
                else
                    nodeVisible["mWinLine32"..tostring(i).."1"] = false
                    nodeVisible["mWinLine32"..tostring(i).."2"] = true
                end

                 nodeVisible.mResult32 = true
            end
        end
        
        for i=1,#ABManager.lastFightList.round16_8 do
            local info = ABManager.lastFightList.round16_8[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine16"..tostring(i).."1"] = true
                    nodeVisible["mWinLine16"..tostring(i).."2"] = false
                else
                    nodeVisible["mWinLine16"..tostring(i).."1"] = false
                    nodeVisible["mWinLine16"..tostring(i).."2"] = true
                end

                 nodeVisible.mResult16 = true
            end
        end
        
        for i=1,#ABManager.lastFightList.round8_4 do
            local info = ABManager.lastFightList.round8_4[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine8"..tostring(i).."1"] = true
                    nodeVisible["mWinLine8"..tostring(i).."2"] = false
                else
                    nodeVisible["mWinLine8"..tostring(i).."1"] = false
                    nodeVisible["mWinLine8"..tostring(i).."2"] = true
                end

                 nodeVisible.mResult8 = true
            end
        end
        
        for i=1,#ABManager.lastFightList.round4_2 do
            local info = ABManager.lastFightList.round4_2[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine4"..tostring(i).."1"] = true
                    nodeVisible["mWinLine4"..tostring(i).."2"] = false
                else
                    nodeVisible["mWinLine4"..tostring(i).."1"] = false
                    nodeVisible["mWinLine4"..tostring(i).."2"] = true
                end
            end
        end
        
        
    end
    
    NodeHelper:setStringForLabel(container, labelStr);
    NodeHelper:setNodesVisible(container,nodeVisible)
end
--END ABMainPrepareContent


function ABLastSessionPage:onEnter(container)  
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);

    NodeHelper:initScrollView(container, "mContent", 5);
    NodeHelper:setLabelOneByOne(container, "mHelpText0", "mHelpText1")
    self:getPageInfo(container)
end


function ABLastSessionPage:getPageInfo(container)
    self:refreshPage(container)    
    self:rebuildAllItem(container)
end


function ABLastSessionPage:refreshPage(container)    
    local nodeVisible = {}
    local labelStr = {}

    --对阵图显示
    
    NodeHelper:setStringForLabel(container, labelStr);
    NodeHelper:setNodesVisible(container,nodeVisible)
end

function ABLastSessionPage:buildItem(container)
    NodeHelper:buildScrollView(container, 1, ABMainLaseFightingContent.ccbiFile, ABMainLaseFightingContent.onFunction, true)
end
--------------Click Event--------------------------------------


