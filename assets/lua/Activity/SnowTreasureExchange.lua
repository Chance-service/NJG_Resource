
local HP_pb = require("HP_pb")
local UserItemManager = require("Item.UserItemManager")
local thisPageName = "SnowTreasureExchange"
local isExchangedFinal = false
local COUNT_TREASURE_MAX = 7
local opcodes = {
    SNOWFIELD_EXCHANGE_C = HP_pb.SNOWFIELD_EXCHANGE_C,
    SNOWFIELD_EXCHANGE_S = HP_pb.SNOWFIELD_EXCHANGE_S
}

local option = {
	ccbiFile = "Act_SnowTreasureHuntPopUp.ccbi",
	handlerMap = {
        onClose = "onClose",
		onExchange = "onExchange"
	},
	opcode = opcodes
}

for i = 1, COUNT_TREASURE_MAX do
	option.handlerMap[string.format("onFrame%d", i)] = "onTreasure"
end

local thisActivityInfo = {
    activityId = Const_pb.SNOWFIELD_TREASURE       -- 活动id
}

local SnowTreasureExchangeBase = {}
------------------------------------------------------------------------------------


function SnowTreasureExchangeBase:onEnter( container )
    self:registerPacket( container )
    self:refreshView( container )

end

function SnowTreasureExchangeBase:refreshView( container )
     if isExchangedFinal then
        --container:getVarMenuItem("mExchange"):setEnabled( false )
    else
        --container:getVarMenuItem("mExchange"):setEnabled( true )
    end


    local rewardIds = ActivityConfig[thisActivityInfo.activityId].reward

    local exchangeRewardId = ActivityConfig[thisActivityInfo.activityId].exchangeRewardId
	
    local exchangeIds = ActivityConfig[thisActivityInfo.activityId].exchangeId

    local rewardParams = {
        mainNode = "mPrize",
        countNode = "mNum",
        frameNode = "mFrame",
        picNode = "mPic",
        startIndex = 5
    }
    
	if exchangeRewardId~=nil then
	    local cfg = ConfigManager.getRewardById(exchangeRewardId)
        NodeHelper:fillRewardItemWithParams(container, cfg, 3,rewardParams)
	end

    for i = 1 , #exchangeIds ,1 do
        local userItem = UserItemManager:getUserItemByItemId(exchangeIds[i])
        if userItem == nil then
            userItem = {}
            userItem.itemId = exchangeIds[i]
            userItem.count = 0
        end
	    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, userItem.itemId, userItem.count)
        container:getVarSprite( "mPic" .. i ):setTexture( resInfo.icon )
        container:getVarMenuItemImage( "mFrame" .. i ):setNormalImage( CCSprite:create( NodeHelper:getImageByQuality( resInfo.quality ) ) )
        container:getVarLabelBMFont( "mNum" .. i ):setString( userItem.count )
    end
end

function SnowTreasureExchangeBase:refreshExchangeView( container ,id  )
    
end

function SnowTreasureExchangeBase:onExecute( container )

end

function SnowTreasureExchangeBase:onExit( container )
    self:removePacket( container )
end

function SnowTreasureExchangeBase:onExchange( container )
    common:sendEmptyPacket(opcodes.SNOWFIELD_EXCHANGE_C ,true)
end

function SnowTreasureExchangeBase:onClose( container )
    PageManager.popPage( thisPageName )
end

function SnowTreasureExchangeBase:onTreasure( container , eventName )
    local index = tonumber(eventName:sub(8,9))
    local exchangeIds = ActivityConfig[thisActivityInfo.activityId].exchangeId
    if index <= #exchangeIds then
        local userItem = UserItemManager:getUserItemByItemId(exchangeIds[i])
        if userItem == nil then
            userItem = {}
            userItem.itemId = exchangeIds[index]
            userItem.count = 0
        end
        GameUtil:showTip(container:getVarNode("mPrize" .. index), { type = Const_pb.TOOL*10000 , count = userItem.count , itemId = userItem.itemId  })
    else
        local exchangeRewardId = ActivityConfig[thisActivityInfo.activityId].exchangeRewardId
        if exchangeRewardId~=nil then
	         local cfg = ConfigManager.getRewardById(exchangeRewardId)
             GameUtil:showTip(container:getVarNode("mPrize" .. index), cfg[index - 4] )
	    end
    end
end

function SnowTreasureExchangeBase:onReceivePacket( container )
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.SNOWFIELD_EXCHANGE_S then
        self:refreshView( container )
    end

end

function SnowTreasureExchangeBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function SnowTreasureExchangeBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function SnowTreasureExchange_SetIsExchangedFinal( boo )
    isExchangedFinal = boo
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
SnowTreasureExchange = CommonPage.newSub(SnowTreasureExchangeBase, thisPageName, option);