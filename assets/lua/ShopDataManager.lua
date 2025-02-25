----------------------------------------------------------------------------------

-- 舊的 商店資料管理
-- 準備棄用

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb")
local Shop_pb = require("Shop_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local HP_pb = require("HP_pb") --包含协议id文件
local ShopDataManager = {
}

--商店类型
ShopDataManager._shopType = {
    STATE_DROPS = 1,
    STATE_COINS = 2,
}
--类型映射 商店类型 --> 本地类型
ShopDataManager._mappedType = 
{
    [Const_pb.CRYSTAL_MARKET] = ShopDataManager._shopType.STATE_DROPS,
    [Const_pb.COINS_MARKET] = ShopDataManager._shopType.STATE_COINS,
    }
--商店子页签Info（装备-金币-宝石）
ShopDataManager._childContainerInfo = {--对应回调以及 子container信息
    [1] = {--物品商店
        _container = nil,
        _type = ShopDataManager._shopType.STATE_DROPS,
        _btnName = "@Goods",
        _clickFun = "onBtnSelect",
        _scriptName = "ShopDropsPage",
        _item_count_per_line = 2,--一行最多的物品显示个数
        _helpFile = GameConfig.HelpKey.HELP_MARKET_ITEM,
    },
    [2] = {--金币商店
        _container = nil,
        _type = ShopDataManager._shopType.STATE_COINS,
        _btnName = "@BuyGold",
        _clickFun = "onBtnSelect",
        _scriptName = "ShopCoinPage",
        _item_count_per_line = 2,--一行最多的物品显示个数
        _helpFile = GameConfig.HelpKey.HELP_MARKET_GOLD,
    },
    }

--数据包信息
ShopDataManager._packetInfo = {
    [1] = {--物品商店
        _allItemInfo = {},
        _refreshPrice = 0,
        _isInit = false,
    },
    [2] = {--金币商店
       _count = 0,--金币数量
       _price = 0,--钻石价格
       _time = 0,--剩余次数
       _isInit = false,
    },
}
---资源类型，对应的图标和检查是否足够的函数
ShopDataManager._shopTypeEnum = {
    [Const_pb.CHANGE_COIN] = { icon = "I_1002.png", checkFunc=UserInfo.isCoinEnough },
    [Const_pb.CHANGE_GOLD] = { icon = "I_1001.png", checkFunc=UserInfo.isGoldEnough },
    [Const_pb.CHANGE_CRYSTAL] = { icon = "Icon_Suit_S.png", checkFunc=UserInfo.isCrystalEnough },
}
--商品折扣信息对应texture
ShopDataManager._percentTexture = {
}
ShopDataManager._buyType = {
    BUY_SINGLE = 1,
    BUY_ALL = 2,
}
ShopDataManager._curShopIndex = ShopDataManager._shopType.STATE_DROPS
function ShopDataManager.setCurrentShopIndex(index)
	ShopDataManager._curShopIndex = index
end
function ShopDataManager.resetPacketInfo(localIndex)
    ShopDataManager._curShopIndex = localIndex
    for i = 1, #ShopDataManager._packetInfo do
        ShopDataManager._packetInfo[i]._isInit = false
    end
end
function ShopDataManager.getMainTypeByLocalType(localType)
    local _type = localType or ShopDataManager._curShopIndex
    for key, value in pairs(ShopDataManager._mappedType) do
        if tonumber(value) == tonumber(_type) then
            return key
        end
    end
end
function ShopDataManager.getLocalTypeByMainType(mainType)
    local _type = mainType or ShopDataManager._curShopIndex
    for key, value in pairs(ShopDataManager._mappedType) do
        if tonumber(key) == tonumber(_type) then
            return value
        end
    end
end
function ShopDataManager.getChildContainerInfo(localType)
    local _type = localType or ShopDataManager._curShopIndex
    return ShopDataManager._childContainerInfo[_type]
end
function ShopDataManager.getPacketDataInfo(localType)
    local _type = localType or ShopDataManager._curShopIndex
    return ShopDataManager._packetInfo[_type]
end
function ShopDataManager.setPacketDataInfo(msg)
    if msg then
        local LocalType = ShopDataManager.getLocalTypeByMainType(msg.shopType)
        if LocalType then
            ShopDataManager._packetInfo[LocalType]._isInit = true
            if LocalType == ShopDataManager._shopType.STATE_DROPS then
                ShopDataManager._packetInfo[LocalType]._allItemInfo = msg.itemInfo
                if msg.refreshPrice then
                    ShopDataManager._packetInfo[LocalType]._refreshPrice = msg.refreshPrice
                end
            end
        end
    end
end
----------packet msg--------------------------
function ShopDataManager.sendShopItemInfoRequest(initType, shopType)
    local msg = Shop_pb.ShopItemInfoRequest()
    msg.type = initType--初始化or刷新
    msg.shopType = shopType or tonumber(ShopDataManager.getMainTypeByLocalType(ShopDataManager._curShopIndex))
    common:sendPacket(HP_pb.SHOP_ITEM_C, msg, true)
end

function ShopDataManager.buyShopItemsRequest(buyType, shopMainType, itemId, itemCount, currencyType)
	local msg = Shop_pb.BuyShopItemsRequest()
	msg.type = buyType --1.单个购买 2.全部购买
	msg.shopType = shopMainType
	if itemId then 
		msg.id = itemId --商城唯一ID
	end

	if itemCount then 
		msg.amount = itemCount--购买数量
	end
	if currencyType then 
		msg.buyType = currencyType--货币类型
	end
    --common:sendPacket(HP_pb.SHOP_BUY_C, msg, true)
	common:sendPacket(HP_pb.SHOP_BUY_C, msg, false)
	MessageBoxPage:Msg_Box(common:getLanguageString("@RewardItem2"))
end
----------packet msg--------------------------
return ShopDataManager