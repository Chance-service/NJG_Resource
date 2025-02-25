local thisPageName = "AlbumPhotoDisplay"

local opcodes = {
    
    }

local option = {
    ccbiFile = "SecretMessagePhoto.ccbi",
    handlerMap = {
        onExitPhoto= "onExitPhoto"
    },
}
local SecretMessagePhotoDisplay = {}
local FileName

function SecretMessagePhotoDisplay:onEnter(container)
      NodeHelper:setSpriteImage(container, {mBigPhoto = FileName})
end
function SecretMessagePhotoDisplay:PhotoInfo(name)
    FileName=name
end
function SecretMessagePhotoDisplay:onExitPhoto(container)
    PageManager.popPage(thisPageName)
    FileName=""
    -- 新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide and GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] ~= 0 then
        GuideManager.forceNextNewbieGuide()
    end
end

local CommonPage = require("CommonPage")
local SecretMessagePhoto = CommonPage.newSub(SecretMessagePhotoDisplay, thisPageName, option)

return SecretMessagePhoto
