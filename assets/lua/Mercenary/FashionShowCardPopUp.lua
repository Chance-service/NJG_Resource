local thisPageName = "FashionShowCardPopUp"
local ConfigManager = require("ConfigManager")

local FashionShowCardPopUpBase = {
}

local option = {
    ccbiFile = "FashionShowCardPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
    },
    opcodes =
    {

    }
}
local _RoleId = 0
function FashionShowCardPopUpBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function FashionShowCardPopUpBase:onEnter(container)

    container:registerMessage(MSG_MAINFRAME_REFRESH)

    self:refreshPage(container)
end


function FashionShowCardPopUpBase:refreshPage(container)
    if _RoleId ~= nil and _RoleId ~= 0 then
        NodeHelper:setSpriteImage(container, { mPic = "UI/RoleShowCards/RoleShowCard_" .. _RoleId .. ".png" }, { mPic = 1 })
    end
end


function FashionShowCardPopUpBase:onExecute(container)

end

function FashionShowCardPopUpBase:onExit(container)

    onUnload(thisPageName, container)
end

function FashionShowCardPopUpBase:onClose(container)
    PageManager.popPage(thisPageName)
end


function FashionShowCardPopUpBase_setRoleId(roleId)
    _RoleId = roleId
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
FashionShowCardPopUpBase = CommonPage.newSub(FashionShowCardPopUpBase, thisPageName, option);