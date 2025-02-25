require("TransSceneData")

local thisPageName = "TransScenePopUp"

local option = {
    ccbiFile = "LoadingUiPage.ccbi",
    handlerMap = {
    },
    opcode = opcodes
}

local TransScenePopUp = { }

function TransScenePopUp:onEnter(container)
    TransSceneData.pageContainer = container

    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_81_Transitions"

    TransSceneData.transSpine = SpineContainer:create(spinePath, spineName)
    TransSceneData.transSpine:registerFunctionHandler("COMPLETE", self.complete)
    local spineNode = tolua.cast(TransSceneData.transSpine, "CCNode")
    local parentNode = TransSceneData.pageContainer:getVarNode("mSpineNode")
    parentNode:removeAllChildrenWithCleanup(true)
    parentNode:addChild(spineNode)

    TransSceneData.playingAniName = ""
    TransSceneData.transSpine:setToSetupPose()
    TransSceneData.playingAniName = "animation1"
    TransSceneData.transSpine:runAnimation(1, "animation1", 0)
end

function TransScenePopUp:onExit(container)
    local parentNode = TransSceneData.pageContainer:getVarNode("mSpineNode")
    parentNode:removeAllChildrenWithCleanup(true)

    if TransSceneData.transSpine then
        local spineNode = tolua.cast(TransSceneData.transSpine, "CCNode")
        spineNode:stopAllActions()
    end
    TransSceneData.transSpine = nil
    TransSceneData.playingAniName = ""
    TransSceneData.callback = nil
    PageManager.popPage(thisPageName)
end

function TransScenePopUp_closePage(delayTime)
    if TransSceneData.transSpine then
        local spineNode = tolua.cast(TransSceneData.transSpine, "CCNode")
        spineNode:stopAllActions()
        local action = CCArray:create()
        if not delayTime then
            action:addObject(CCDelayTime:create(1 / 60))
        else
            action:addObject(CCDelayTime:create(delayTime))
        end
        action:addObject(CCCallFunc:create(function()
            TransSceneData.playingAniName = "animation2"
            TransSceneData.transSpine:runAnimation(1, "animation2", 0)
        end))
        spineNode:runAction(CCSequence:create(action))
    end
end
-- Spine事件處理
function TransScenePopUp:complete(tag, eventName)
    if eventName == "COMPLETE" then
        if TransSceneData.transSpine then
            if TransSceneData.playingAniName == "animation1" then
                TransSceneData.playingAniName = "loop"
                TransSceneData.transSpine:runAnimation(1, "loop", -1)
                if TransSceneData.callback then
                    TransSceneData.callback()
                end
            elseif TransSceneData.playingAniName == "animation2" then
                TransScenePopUp:onExit(TransSceneData.pageContainer)
            end
        end
    end
end

function TransScenePopUp_setCallbackFun(fn)
    TransSceneData.callback = fn
end

local CommonPage = require("CommonPage")
local TransScenePopUp = CommonPage.newSub(TransScenePopUp, thisPageName, option)

return TransScenePopUp
