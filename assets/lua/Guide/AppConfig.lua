--- 此文件可在main.lua中导入用作全局参数控制
-- TODO: 由于新手引导需要所以直接移动到此处作为全局变量
FreeTypeConfig = { }

isSaveChatHistory = true --and (CC_TARGET_PLATFORM_LUA ~= common.platform.CC_PLATFORM_WIN32)-- 是否开启保存私聊聊天记录 true 开启true

S = S or { NO_NEWBIE = false }        -- false = 开   true =  关      ------

function EFUNSHOWNEWBIE()
    local closeR18 = VaribleManager:getInstance():getSetting("IsCloseR18")
    if tonumber(closeR18) == 1 then
        -- 不显示新手引导
        return false
    end
    if S and S.NO_NEWBIE then
        return false
        -- 不显示新手引导
    else
        return true
        -- 显示新手引导
    end
end