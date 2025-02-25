
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'MissionAchievementPage'
local Activity_pb = require("Activity_pb");
local MissionManager = require("MissionManager")
local HP_pb = require("HP_pb");
local ItemManager = require "Item.ItemManager"
local Const_pb = require("Const_pb")
require("Shop_pb");
local MissionAchievementPage = {
}
local curPagePacketData = nil
local ITEM_COUNT_PER_LINE = 2
function MissionAchievementPage.onFunction(eventName,container)
	if eventName == "onBuyAll" then
		
	end
end
function MissionAchievementPage:onEnter(ParentContainer)
    local missionInfo = MissionData.getMissionInfo()
	self.container = ScriptContentBase:create(missionInfo._ccbi)
	--self.container:registerFunctionHandler(MissionAchievementPage.onFunction)
	return self.container
end

function MissionAchievementPage:getPacketInfo()
   
end
function MissionAchievementPage:refreshPage()
	
end

function MissionAchievementPage:onExecute(ParentContainer)
	
end
----------------scrollview-------------------------
local TaskContent = {

}

function MissionAchievementPage:rebuildAllItem()
    self:clearAllItem();
	self:buildItem();
end

function MissionAchievementPage:clearAllItem()
   
end

function MissionAchievementPage:buildItem()
    
end

function MissionAchievementPage:onBuyBtn(container)
	
	
end

function MissionAchievementPage:getActivityInfo()
  
end
function MissionAchievementPage:onReceivePacket(ParentContainer)
   
end

function MissionAchievementPage:removePacket(ParentContainer)

end

function MissionAchievementPage:onExit(ParentContainer)

end

return MissionAchievementPage
