----------------------------------------------------------------------------------
--[[

--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local MercenaryCfg = nil
local thisPageName = "MercenaryGetNewRolePage"
local UserItemManager = require("Item.UserItemManager")
local UserMercenaryManager = require("UserMercenaryManager")
local EquipScriptData = require("EquipScriptData")
local _IsAniFinishedFlag = false
local _thisItemId = nil
local option = {
    ccbiFile = "GeneralsGet_1.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onAnimationDone = "onAnimationDone"
    },

}
local _MercenaryQuality = {
    R = 3,
    -- "R"
    SR = 4,
    -- "SR"
    SSR = 5,
    -- "SSR"
    UR = 6-- "UR"
}
local roleConfig = nil
----------------- local data -----------------
local MercenaryGetNewRolePage = { }

local _CallFun = nil

function MercenaryGetNewRolePage:onEnter(container)
    self.container = container
    roleConfig = ConfigManager.getRoleCfg()
    self:showRoleSpine()
    self:refreshPage()
    _IsAniFinishedFlag = false
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.IsNeedShowPage then
        GuideManager.IsNeedShowPage = false
        PageManager.popPage("NewGuideEmptyPage")
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function MercenaryGetNewRolePage.onFunction(eventName, container)
    if eventName == "luaOnAnimationDone" then
        MercenaryGetNewRolePage:onAnimationDone(container)
    elseif eventName == "onClose" then
        MercenaryGetNewRolePage:onClose(container)
    end
end

-- 添加SPINE动画
function MercenaryGetNewRolePage:showRoleSpine()
    local heroNode = self.container:getVarNode("mSpine")
    local m_NowSpine = nil
    if heroNode then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width, height = visibleSize.width, visibleSize.height
        local rate = visibleSize.height / visibleSize.width
        local desighRate = 960 / 640
        rate = rate / desighRate
        heroNode:removeAllChildren()

        local roleData = ConfigManager.getRoleCfg()[_thisItemId]
        local spinePath, spineName = unpack(common:split((roleData.spine), ","))

        m_NowSpine = SpineContainer:create(spinePath, spineName)
        local spineNode = tolua.cast(m_NowSpine, "CCNode")
        heroNode:addChild(spineNode)
        m_NowSpine:runAnimation(1, "Stand", -1)
        local offset_X_Str, offset_Y_Str = unpack(common:split((roleData.offset), ","))
        NodeHelper:setNodeOffset(spineNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        spineNode:setScale(roleData.spineScale)
    end
    if  _thisItemId == 111 then
        NodeHelper:playSpecialMusic("tutorial_14.1.mp3")
    end
end

function MercenaryGetNewRolePage:refreshPage()
    local quality = roleConfig[_thisItemId].quality;
    NodeHelper:setNodesVisible(self.container, { mCardUR = quality == _MercenaryQuality.UR, mCardSSR = quality == _MercenaryQuality.SSR,mCardSR = quality == _MercenaryQuality.SR,mCardR = quality == _MercenaryQuality.R });
    NodeHelper:setNodesVisible(self.container, { mGeneralsUR = quality == _MercenaryQuality.UR, mGeneralsSSR = quality == _MercenaryQuality.SSR,mGeneralsSR = quality == _MercenaryQuality.SR,mGeneralsR = quality == _MercenaryQuality.R });
end

function MercenaryGetNewRolePage:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "Born" then
        _IsAniFinishedFlag = true
    elseif animationName == "Loop" then

    elseif animationName == "Out" then
        PageManager.popPage(thisPageName);
    end
end

function MercenaryGetNewRolePage:onClose(container)
    if _IsAniFinishedFlag then
        _IsAniFinishedFlag = false
        container:runAnimation("Out")
    end
end

function MercenaryGetNewRolePage:onExit(container)
    _thisItemId = nil
    onUnload(thisPageName, container)
    if (_CallFun) then
        _CallFun()
    end
end

function MercenaryGetNewRolePage:setFirstData(itemId)
    _thisItemId = itemId
    -- 佣兵ItemId
end

function MercenaryGetNewRolePage:setCloseCall(callfun)
    _CallFun = callfun
end

local CommonPage = require("CommonPage");
local MercenaryGetNewRolePage = CommonPage.newSub(MercenaryGetNewRolePage, thisPageName, option)
return MercenaryGetNewRolePage
