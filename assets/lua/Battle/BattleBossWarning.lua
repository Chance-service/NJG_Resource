local thisPageName = "BattleBossWarning"
local CONST = require("Battle.NewBattleConst")
local BattleBossWarning = {}

local option = {
    ccbiFile = "BattleBossWarning.ccbi",
    handlerMap =
    {
    },
    opcodes =
    {
    }
}

local spineParent = nil
local monsterCfg = ConfigManager.getNewMonsterCfg()
local monsterId = 0

function BattleBossWarning:onAnimationDone(container)
    local NgFightSceneHelper = require("Battle.NgFightSceneHelper")
	local animationName = tostring(container:getCurAnimationDoneName())
	if animationName == "Untitled Timeline" then
        spineParent:removeAllChildren()
        NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.MOVING)
		BattleBossWarning:onClose(container)
	end
end

function BattleBossWarning:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
    spineParent = container:getVarNode("mSpineNode")
    local bossNameImg = container:getVarSprite("mBossName")
    bossNameImg:setPositionX(2000)
    local spineNode = self:createSpine(container)
    local array = CCArray:create()
    array:addObject(CCDelayTime:create(1 / 60))
    array:addObject(CCCallFunc:create(function()
        BattleBossWarning:playAnimation(container)
    end))
    spineNode:runAction(CCSequence:create(array))
end

function BattleBossWarning:onClose(container)
    PageManager.popPage(thisPageName)
end

function BattleBossWarning:playAnimation(container)
    container:runAnimation("Untitled Timeline")
end

function BattleBossWarning:setMonsterId(id)
    monsterId = id
end

function BattleBossWarning:createSpine(container)
    spineParent:removeAllChildren()
    local spinePath, roleSpine = unpack(common:split((monsterCfg[monsterId].Spine), ","))
    local spine = SpineContainer:create(spinePath, roleSpine)
    if monsterCfg[monsterId].Skin then
        spine:setSkin("skin" .. string.format("%02d", monsterCfg[monsterId].Skin))
    end
    spine:setToSetupPose()
    spine:runAnimation(1, "wait_0", -1)
    local spineNode = tolua.cast(spine, "CCNode")
    if monsterCfg[monsterId].Reflect == 1 then
        spineNode:setScaleX(-1)
    end
    spineParent:addChild(spineNode)
    return spineNode
end

----------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local ActPage = CommonPage.newSub(BattleBossWarning, thisPageName, option)

return ActPage