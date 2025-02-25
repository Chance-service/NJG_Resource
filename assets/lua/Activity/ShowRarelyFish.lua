
local HP_pb = require "HP_pb"
local thisPageName = "ShowRarelyFish"
local ShowRarelyFish = {}
local ITEM_COUNT_PER_LINE = 5
local RewardContent = {}
require("CatchFish")
local option = {
	ccbiFile = "Act_FishingGetAniOpen.ccbi",
	handlerMap = {
        onClose = "onClose",
		onConfirmation = "onConfirmation",
	},
    opcodes = {
    }
};
----------------------------------------------
function ShowRarelyFish:onEnter(container)

   self:refreshPage(container);
end

----------------------------------------------------------------

function ShowRarelyFish:refreshPage(container)
   NodeHelper:setStringForLabel(container, { mClickClose = common:getLanguageString("@ClickClose")});
end
----------------click event------------------------
function ShowRarelyFish:onClose(container)
	PageManager.popPage(thisPageName)
    if getNeedShowRewardPage() then
        PageManager.pushPage("CatchFishReward");
        setNeedShowRewardPage();
    end
end

function ShowRarelyFish:onExit(container)
   
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local ShowRarelyFish = CommonPage.newSub(ShowRarelyFish, thisPageName, option);