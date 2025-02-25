
--[[ 字典 ]] -- (若有將該.lang檔轉寫入Language.lang中可移除此處與該.lang檔)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/Reward.lang"] then
--    __lang_loaded["Lang/Reward.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/Reward.lang")
--end

--[[ 通用 分頁列 容器 頁面 ]]
local CommTabStoragePage = require("Comm.CommTabStoragePage")

--[[ 資料管理 ]]
local GloryHoleDataMgr = require("GloryHole.GloryHoleDataMgr")

--[[ 頁面名稱 ]]
local PAGE_NAME = "GloryHole.GloryHolePage"
--[[ 函式對照 ]]
local HANDLER_MAP = nil
--[[ 協定 ]]
local OPCODES = nil

return CommTabStoragePage:generateCommPage(PAGE_NAME, HANDLER_MAP, OPCODES, function ()

    local cfgs = {}

    for idx, val in ipairs(GloryHoleDataMgr.SubPageCfgs) do while true do

        -- 若 為 活動
        if val.activityID ~= nil then
            -- 若 非開啟 則 忽略
            if ActivityInfo:getActivityIsOpenById(val.activityID) == false then
                break -- continue
            end
        end

        cfgs[#cfgs+1] = val

    break end end

    return cfgs
end)