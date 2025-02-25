--[[ 
    name: AncientWeaponPage
    desc: 專武頁面
    author: youzi
    update: 2023/11/21 14:45
    description: 

--]]

--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
-- __lang_loaded = __lang_loaded or {}
-- if not __lang_loaded["Lang/AncientWeapon.lang"] then
--    __lang_loaded["Lang/AncientWeapon.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/AncientWeapon.lang")
-- end

--[[ 通用 分頁列 容器 頁面 ]]
local CommTabStoragePage = require("Comm.CommTabStoragePage")

--[[ 資料管理 ]]
local AncientWeaponDataMgr = require("AncientWeapon.AncientWeaponDataMgr")

--[[ 頁面名稱 ]]
local PAGE_NAME = "AncientWeapon.AncientWeaponPage"
--[[ 函式對照 ]]
local HANDLER_MAP = nil
--[[ 協定 ]]
local OPCODES = nil

local page = CommTabStoragePage:generateCommPage(PAGE_NAME, HANDLER_MAP, OPCODES, AncientWeaponDataMgr.SubPageCfgs)

page.userEquipId = nil

function page:prepare(userEquipId)
    self.userEquipId = userEquipId
end


return page