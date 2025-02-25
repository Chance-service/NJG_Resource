
----------------------------------------------------------------------------------
local HP_pb = require("HP_pb")
local thisPageName = "SEEnterAniPopUpPage"
local NodeHelper = require("NodeHelper");
local option = {
	ccbiFile = "SkillSpecialtyAni.ccbi",
	handlerMap = {

	}
}	

local SEEnterAniPopUpPageBase = {}
local SEManager = require("Skill.SEManager")
local Profession = 0
----------------------------------------------
--SEEnterAniPopUpPageBase页面中的事件处理
----------------------------------------------
function SEEnterAniPopUpPageBase:onEnter(container)

end


function SEEnterAniPopUpPageBase:onExecute(container)
	
end

function SEEnterAniPopUpPageBase:onExit(container)

end



----------------animation event---------------
function SEEnterAniPopUpPageBase:onAnimationDone(container)
	local animationName=tostring(container:getCurAnimationDoneName())
	if animationName=="Default Timeline" then
		require("SEMainPage")
        SEMainPage_ShowSEPageByProfession(Profession)
	end
end

function SEEnterAniPopUpPage_ShowSEAniPageByProfession(profession)
    Profession = profession
    PageManager.pushPage(thisPageName)
end
-------------------------------------------------------------------------
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local SEEnterAniPopUpPage = CommonPage.newSub(SEEnterAniPopUpPageBase, thisPageName, option);