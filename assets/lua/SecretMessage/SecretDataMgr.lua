

--[[ 本體 ]]
local Inst = {}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {
    {
        -- 子頁面名稱 : 訊息
        subPageName = "Message",

        -- 分頁 相關
        scriptName = "SecretMessage.SecretMessagePage",
        iconImg_normal = "SubBtn_SecretMessage.png",
        iconImg_selected = "SubBtn_SecretMessage_On.png",
        
        -- 標題
        title = common:getLanguageString("BundleShopTitle"),

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1001_0" }, { priceStr = "10000_1002_0" } },

        -- 其他子頁資訊 ----------
        TopisVisible=false,

    },
      {
        -- 子頁面名稱 : 相簿
        subPageName = "Album",

        -- 分頁 相關
        scriptName = "Album.AlbumMainPage",
        iconImg_normal = "SubBtn_SecretPhoto.png",
        iconImg_selected = "SubBtn_SecretPhoto_On.png",
        isRedOn = function() return false--[[SecretPage:NotAllSaw()]] end,
        
        -- 標題
        title = common:getLanguageString("BundleShopTitle"),

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1001_0" }, { priceStr = "10000_1002_0" } },

        -- 其他子頁資訊 ----------
        TopisVisible=false,

    },
       {
        -- 子頁面名稱 : HCG
        subPageName = "HCG",

        -- 分頁 相關
        scriptName = "Album.StoryLog",
        iconImg_normal = "SubBtn_ HeroMemories.png",
        iconImg_selected = "SubBtn_ HeroMemories_On.png",
        
        -- 標題
        title = common:getLanguageString("BundleShopTitle"),

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1001_0" }, { priceStr = "10000_1002_0" } },

        -- 其他子頁資訊 ----------
        TopisVisible=false,

    },
}

--[[ 取得 子頁面 配置 ]]
function Inst:getSubPageCfg (subPageName)
    for idx, cfg in ipairs(Inst.SubPageCfgs) do
        if cfg.subPageName == subPageName then return cfg end
    end
    return nil
end


return Inst