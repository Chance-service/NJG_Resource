
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local thisPageName = "TogetherCompetingGrabPage"
local ActivityData = require("Activity.ActivityData")
local roleConfig = ConfigManager.getRoleCfg() 
local thisPageInfo = ActivityData.TogetherCompetingRedPage
local option = {
    ccbiFile = "Act_TogetherCompetingRedEnvelopesPopUp3.ccbi",
    handlerMap ={
        onDetermine      = "onConfirm",
        onClose         = "onConfirm",
        onHand        = "onPlayer",
    },
}
local TogetherCompetingGrabPage = BasePage:new(option,thisPageName,nil,nil)

-------------------------- logic method ------------------------------------------

-------------------------- state method -------------------------------------------
function TogetherCompetingGrabPage:onEnter( container )
    NodeHelper:setStringForLabel(container,{mTitle = common:getLanguageString("@TogetherRedCongratulationTitle")})
    local wishStr = ""
    if thisPageInfo.wishes == "null" then
        wishStr = common:getLanguageString("@TogetherRedDefaultWish")
    else
        wishStr = thisPageInfo.wishes
    end
    -- 有可能服务器没有传过来人
    local mLvStr = ""
    if thisPageInfo.roleItemId==0 then
        NodeHelper:setNodesVisible(container,{mHandNode=false})
        mLvStr = ""
    else
        local headPic = roleConfig[thisPageInfo.roleItemId]["icon"]
        mLvStr = "Lv." .. thisPageInfo.roleLevel
        local proId = 1
        if thisPageInfo.roleItemId>3 then
            proId = thisPageInfo.roleItemId-3
        else
            proId = thisPageInfo.roleItemId
        end
        local proIcon = roleConfig[proId].proIcon
        NodeHelper:setSpriteImage(container, {
            mPic = headPic,
            mProfession = proIcon,
        })
    end
    wishStr=common:stringAutoReturn(wishStr,10)
    local lb2Str = {
        mPlayerName     = thisPageInfo.playerName,
        mDecisionTex    = wishStr,
        mNumber         = thisPageInfo.gold,
        mLv             = mLvStr,
    }
    NodeHelper:setStringForLabel(container,lb2Str)
end

----------------------------click method -------------------------------------------
--确定键
function TogetherCompetingGrabPage:onConfirm(container)
    local rewardCfg = {type=10000,itemId=1001,count=thisPageInfo.gold}
    local tbReward = {}
    table.insert(tbReward,rewardCfg)
    common:popRewardString(tbReward)
    PageManager.popPage(thisPageName)
end
function TogetherCompetingGrabPage:onPlayer( container )
    PageManager.viewPlayerInfo(thisPageInfo.playerId,true)
end
----------------------------packet method -------------------------------------------

---------------------------- end  ----------------------------------------------------
