--[[ 
    name: SpiritPage
    desc: 精靈頁面
    author: youzi
    update: 2023/7/11 18:25
    description: 
--]]

--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/Spirit.lang"] then
--    __lang_loaded["Lang/Spirit.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/Spirit.lang")
--end

--[[ 通用 分頁列 容器 頁面 ]]
local CommTabStoragePage = require("Comm.CommTabStoragePage")

--[[ 資料管理 ]]
local SpiritDataMgr = require("Spirit.SpiritDataMgr")

--[[ 頁面名稱 ]]
local PAGE_NAME = "Spirit.SpiritPage"
--[[ 函式對照 ]]
local HANDLER_MAP = nil
--[[ 協定 ]]
local OPCODES = nil

local page = CommTabStoragePage:generateCommPage(PAGE_NAME, HANDLER_MAP, OPCODES, SpiritDataMgr.SubPageCfgs)

--[[ 是否已經顯示進入動畫 ]]
page.isShowEntryAnim = false

--[[ 當 頁面 離開 ]]
local original_onExit = page.onExit
function page:onExit(container)
    -- 重置 是否已經顯示進入動畫
    page.isShowEntryAnim = false
    
    original_onExit(self, container)
end


return page