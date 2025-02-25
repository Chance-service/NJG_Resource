local NewBattleMapItem = {
    cityId = 0,
    node = nil,
    parentNode = nil,
    clicker = {},
    remainTime = 0
}

local NodeHelper = require("NodeHelper")

local FLAG_TYPE = {
    ["CLEAR"] = 1,
    ["NON_OPEN"] = 2,
    ["BATTLE"] = 3
}

local ISLAND_CITY = 5
local CITY_CHAPTER = 10
local ISLAND_CHAPTER = ISLAND_CITY * CITY_CHAPTER

function NewBattleMapItem:create(cityId, parentNode)
    local cityItem = {}
    setmetatable(cityItem, self)
    self.__index = self
    self.flagType = FLAG_TYPE["NON_OPEN"]
    
    cityItem.cityId = cityId
    cityItem.parentNode = parentNode
    cityItem:init()
    return cityItem
end

function NewBattleMapItem:init()
    local container = ScriptContentBase:create("ChapterMapFlagContent.ccbi")
    container:runAnimation("Default Timeline")
    local mapCfg = ConfigManager.getNewMapCfg()
    --local mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or
    --    (mapCfg[UserInfo.stateInfo.passMapId] and UserInfo.stateInfo.passMapId or UserInfo.stateInfo.curBattleMap - 1)
    local nowChpaterId = mapCfg[UserInfo.stateInfo.curBattleMap].Chapter
    local passChpaterId = mapCfg[UserInfo.stateInfo.passMapId] and mapCfg[UserInfo.stateInfo.passMapId].Chapter or 0
    if nowChpaterId == passChpaterId then passChpaterId = passChpaterId - 1 end

    self.flagType = ((self.cityId == nowChpaterId) and FLAG_TYPE["BATTLE"]) or ((passChpaterId >= self.cityId) and FLAG_TYPE["CLEAR"]) or FLAG_TYPE["NON_OPEN"]

    NodeHelper:setNodesVisible(container, {
        mClean = self.flagType == FLAG_TYPE["CLEAR"],
        mNotOpen = self.flagType == FLAG_TYPE["NON_OPEN"],
        mBattle = self.flagType == FLAG_TYPE["BATTLE"]
    })
    
    container:getVarLabelTTF("mTitleTxt1"):setString("Chapter " .. self.cityId)
    container:getVarLabelTTF("mTitleTxt2"):setString(common:getLanguageString("@MapFlag" .. self.cityId))
    if self.flagType == FLAG_TYPE["BATTLE"] then   
        local spineNode = container:getVarNode("mSpine")
        local bladeSpine = SpineContainer:create("Spine/NGUI", "battle_flag")
        bladeSpine:runAnimation(1, "animation", -1)
        local bladeSpineNode = tolua.cast(bladeSpine, "CCNode")
        bladeSpineNode:setPosition(ccp(-5, -90))
        spineNode:addChild(bladeSpineNode)
    end
    
    self.node = container
    
    self.parentNode:addChild(container)
    self:refresh()
end

function NewBattleMapItem:refresh()

end

function NewBattleMapItem:onFlag()
    local NewBattleMapPopUp = require("NewBattleMapPopUp")
    NewBattleMapPopUp:setCityId(self.cityId)
    NewBattleMapPopUp:setOpenType(self.flagType)
    PageManager.pushPage("NewBattleMapPopUp")
end

function NewBattleMapItem:removeFromParentAndCleanup()
    if self.node then
        self.node:removeFromParentAndCleanup(true)
        self.node:release()
    end
end

function NewBattleMapItem:registerClick(callback)
    self.node:registerFunctionHandler(callback)
end

return NewBattleMapItem