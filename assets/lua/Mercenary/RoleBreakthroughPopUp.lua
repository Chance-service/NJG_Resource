local thisPageName = "RoleBreakthroughPopUp"

local FetterManager = require("FetterManager")

local option = {
	ccbiFile = "RoleBreakthroughPopUp.ccbi",
	handlerMap = {
        onAlbum      = "onAlbum",
		onClose 	 = "onClose"
	}
}

local RoleBreakthroughPopUp = {}

------------------------------------------------
local PageInfo = {
	roldId = 0,
    photoNum = 0
}

function RoleBreakthroughPopUp:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function RoleBreakthroughPopUp:onEnter(container)
    local roleData = ConfigManager.getRoleCfg()[PageInfo.roldId]
    if roleData then
        local fullStr = ""
        if (PageInfo.photoNum == 0) then -- ¬ð¯}+1
            fullStr = common:getLanguageString("@ClothesBurst", roleData.name)
        elseif (PageInfo.photoNum > 0) then
            fullStr = common:getLanguageString("@PhotoDepiction", roleData.name, PageInfo.photoNum)
        end
        NodeHelper:setStringForLabel(container, { mMessage = fullStr })
    end
    local photoName = "Role_" .. PageInfo.roldId .. "0" .. PageInfo.photoNum .."_1.png"

    NodeHelper:setSpriteImage(container, { mPhoto = photoName })

    local GuideManager = require("Guide.GuideManager")
    if GuideManager.IsNeedShowPage == true and (GuideManager.getCurrentStep() == 176 or GuideManager.getCurrentStep() == 183)  then
        GuideManager.PageContainerRef["RoleBreakthroughPopUp"] = container
        PageManager.pushPage("NewbieGuideForcedPage")
        PageManager.popPage("NewGuideEmptyPage")
        PageManager.popPage("MercenaryUpgradeStagePage");
        GuideManager.IsNeedShowPage = false;
    end
end

function RoleBreakthroughPopUp:onExecute(container)

end

function RoleBreakthroughPopUp:onExit(container)

end

function RoleBreakthroughPopUp:onClose(container)
	PageManager.popPage(thisPageName)
end

function RoleBreakthroughPopUp:onAlbum(container)
    FetterManager.showFetterPage(PageInfo.roldId)
    self:onClose(container)
end

function RoleBreakthroughPopUp:onAlbum2(container)
    self:onAlbum(container)
    local FetterShowPage = require("FetterShowPage")
    FetterShowPage.setOpenAlbum(container)
end

function RoleBreakthroughPopUp:setRoleId(roleId)
	PageInfo.roldId = roleId
end

function RoleBreakthroughPopUp:setBreakthroughStage(stage)
    -- stageLevel 2 = ¬ð¯}+1
    PageInfo.photoNum = stage - 2
end

-------------------------------------------------
local CommonPage = require("CommonPage")
local RoleBreakthroughPopUp = CommonPage.newSub(RoleBreakthroughPopUp, thisPageName, option)

return RoleBreakthroughPopUp