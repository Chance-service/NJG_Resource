---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Administrator.
--- DateTime: 2019/3/16 15:54
---
local NewGuideEmptyPage = {
    isShowText = false
}

local thisPageName = "NewGuideEmptyPage"
local textNode = nil
local bg = nil
local spriteNode = nil
local option = {
    ccbiFile = "NewBieGuideEmptyPage.ccbi",
    handlerMap = {
    },
    opcodes = {
    },
}

function NewGuideEmptyPage:onEnter(container)
    textNode = container:getVarLabelTTF("mText")
    spriteNode = container:getVarSprite("mSprite")
    bg =  tolua.cast(container:getVarNode("mTipsShade"),"CCLayerColor")
    if NewGuideEmptyPage.isShowText then
        NewGuideEmptyPage.isShowText = false
        textNode:setString("")
        spriteNode:setTexture("UI/NewBieGuide/guide_Battle.png")
--[[        textNode:setString(common:getLanguageString("@FightScreenDes"))
        textNode:setFontSize(30)]]
        local screenX ,screennY = GetScreenWidthAndHeight()
        spriteNode:setPosition(GetWordToNodeSpacePosition(container,"mSprite",screenX/2,screennY-330))
        bg:setOpacity(0)
    else
        textNode:setString("")
    end
end

function NewGuideEmptyPage_Close()
    if type(spriteNode)== "userdata" then
        spriteNode:setVisible(false)
    end
end

function NewGuideEmptyPage:onExecute(container)

end

function NewGuideEmptyPage:onExit(container)

end
function NewGuideEmptyPage:onReceiveMessage(container)

end
function NewGuideEmptyPage:onReceivePacket(container)

end
local CommonPage = require('CommonPage')
NewGuideEmptyPage= CommonPage.newSub(NewGuideEmptyPage, thisPageName, option)

return NewGuideEmptyPage