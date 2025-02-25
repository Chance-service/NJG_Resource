

local thisPageName = "MercenarySpecialAwakeInfoShowPage"
local CommonPage = require("CommonPage");
local NodeHelper = require("NodeHelper");
local MercenarySpecialAwakeInfoShowPage = {}
local option = {
	ccbiFile = "MercenarySpecialAwakeInfoShow.ccbi",
	handlerMap = {
        onClose         = "onClose",
	}
}

----------------------------------------------------------------------------------
--CountTimesWithIconPage页面中的事件处理
----------------------------------------------
function MercenarySpecialAwakeInfoShowPage:onEnter(container)
	self:refreshPage(container)
end
--578   400

function MercenarySpecialAwakeInfoShowPage:refreshPage(container)
     if MercenarySpecialAwakeInfoShowPageRoleId == 0 then
        return
     end
     local roleData = ConfigManager.getRoleCfg()[MercenarySpecialAwakeInfoShowPageRoleId]
     --觉醒上限
     --成长率
     NodeHelper:setStringForLabel(container, {mArchiveGrowthUplimitLable = common:getLanguageString("@ArchiveGrowthUplimit") .. " : " .. roleData.maxRank , mArchiveGrowthRatioLabel = common:getLanguageString("@ArchiveGrowthRatio") .. " : " .. roleData.trainRatio})
end

function MercenarySpecialAwakeInfoShowPage:onExecute(container)
        
end

-- 标签页
function MercenarySpecialAwakeInfoShowPage:onExit(container)
    --MercenarySpecialAwakeInfoShowPageRoleId = 0
end

function MercenarySpecialAwakeInfoShowPage:onClose(container)
    PageManager.popPage(thisPageName)
end


function MercenarySpecialAwakeInfoShowPage_setRoleId(id)
   MercenarySpecialAwakeInfoShowPageRoleId = id
end
-------------------------------------------------------------------------------

local CommonPage = require('CommonPage')
MercenarySpecialAwakeInfoShowPage= CommonPage.newSub(MercenarySpecialAwakeInfoShowPage, thisPageName, option)

return MercenarySpecialAwakeInfoShowPage

