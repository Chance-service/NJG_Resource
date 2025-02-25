
local RechargeDataMgr = {}


--[[ 充值頁面 子頁面資訊 ]]
RechargeDataMgr.SubPageInfos = {
    -- 鑽石頁面
    {
        -- 腳本名稱
        _scriptName = "Recharge.RechargeSubPage_Diamond",
        -- 圖標
        _iconImg_normal = "SubBtn_Diamond.png",
        _iconImg_selected = "SubBtn_Diamond_On.png",
        
        -- 貨幣資訊 
        currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "10000_1001_0" },
        },
        
        -- 其他子頁資訊 ----------
    }
}


--[[ 取得 商品 ]]
function RechargeDataMgr:getDiamondImgPath (index)
    return "Imagesetfile/Recharge/DiamondShop_icon"..tostring(math.min(6, index))..".png"
end

return RechargeDataMgr