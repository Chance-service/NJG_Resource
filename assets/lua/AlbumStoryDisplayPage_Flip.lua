local thisPageName = "AlbumStoryDisplayPage_Flip"

local opcodes = {
    
    }

local option = {
    ccbiFile = "AlbumStoryDisplay_flip.ccbi",
    handlerMap = {
    },
}
local AlbumStoryDisplay_Flip = {}

function AlbumStoryDisplay_Flip:onEnter(container)
   local array = CCArray:create()
   array:addObject(CCCallFunc:create(function()
      AlbumStoryDisplay_Flip:setSpine(container)
   end))
   array:addObject(CCDelayTime:create(3))
   array:addObject(CCCallFunc:create(function()
       PageManager.pushPage("AlbumStoryDisplayPage")
   end))
   array:addObject(CCDelayTime:create(0.5))
   array:addObject(CCCallFunc:create(function()
      PageManager.popPage(thisPageName)
   end))
   container:runAction(CCSequence:create(array))
end
function AlbumStoryDisplay_Flip:setSpine(container)
    Spines = {}
    spineNode = {}
    SpineIdx = 1
    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_77_Shady"
    local spine = SpineContainer:create(spinePath, spineName)
    local EnterNode = tolua.cast(spine, "CCNode")
    parentNode = container:getVarNode("mSpine")
    parentNode:removeAllChildrenWithCleanup(true)
    parentNode:setRotation(90)
    local scale = NodeHelper:getScaleProportion()
    parentNode:setScale(scale)
    parentNode:addChild(EnterNode)
    spine:runAnimation(1, "Enter", 0)
end

local CommonPage = require("CommonPage")
local AlbumStoryDisplayPage_Flip = CommonPage.newSub(AlbumStoryDisplay_Flip, thisPageName, option)

return AlbumStoryDisplayPage_Flip
