
--[[ 
    name: WishingWell
    desc: 許願輪頁面
    author: youzi
    update: 2023/6/16 11:51
    description: 
--]]


--[[ 字典 ]] -- (若有將WishingWell.lang轉寫入Language.lang中可移除此處與WishingWell.lang)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/WishingWell.lang"] then
--    __lang_loaded["Lang/WishingWell.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/WishingWell.lang")
--end

--[[ 通用 分頁列 容器 頁面 ]]
local CommTabStoragePage = require("Comm.CommTabStoragePage")

--[[ 資料管理 ]]
local WishingWellDataMgr = require("WishingWell.WishingWellDataMgr")

--[[ 頁面名稱 ]]
local PAGE_NAME = "WishingWell.WishingWellPage"
--[[ 函式對照 ]]
local HANDLER_MAP = nil
--[[ 協定 ]]
-- local OPCODES = {
--     ACTIVITY147_WISHING_INFO_S = HP_pb.ACTIVITY147_WISHING_INFO_S,
--     ACTIVITY147_WISHING_DRAW_S = HP_pb.ACTIVITY147_WISHING_DRAW_S,
-- }

local page = CommTabStoragePage:generateCommPage(PAGE_NAME, HANDLER_MAP, OPCODES, WishingWellDataMgr.SubPageCfgs)

--[[ 許願輪UI ]]
page.wishingWellUI = nil

--[[ 請求 許願輪 UI ]]
function page:requestWishingWellUI ()
    if self.wishingWellUI == nil then
        local WishingWellUI = require("WishingWell.WishingWellUI")
        self.wishingWellUI = WishingWellUI:new()

        local container = self.wishingWellUI:createPage()
        self.subPageNode:addChild(container)
        
    else 
        self.wishingWellUI.container:setVisible(true)
    end

    return self.wishingWellUI
end

--[[ 當 離開 ]]
local base_onExit = page.onExit
function page:onExit(container)

    self.wishingWellUI = nil

    base_onExit(self, container)

    local currPage = MainFrame:getInstance():getCurShowPageName()
    if currPage == "NgBattlePage" then
        local sceneHelper = require("Battle.NgFightSceneHelper")
        sceneHelper:setGameBgm()
    else
        SoundManager:getInstance():playGeneralMusic()
    end

    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        local guideCfg = GuideManager.getStepCfgByIndex(GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
        if guideCfg and guideCfg.showType == 8 then
            GuideManager.forceNextNewbieGuide()
        end
    end
end

return page