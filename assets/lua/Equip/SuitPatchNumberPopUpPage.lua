
local HP_pb = require("HP_pb") --包含协议id文件
local ItemManager = require("ItemManager")
local thisPageName = "SuitPatchNumberPopUpPage"
local curItemData = nil --当前物品数据
local curCount = 1 --当前数量
local mMultiple = 1
----这里是协议的id
local opcodes = {
    EQUIP_RESONANCE_INFO_C = HP_pb.EQUIP_RESONANCE_INFO_C,
    HEAD_FRAME_STATE_INFO_S = HP_pb.HEAD_FRAME_STATE_INFO_S
}

local option = {
    ccbiFile = "ManyPeopleMapShopBuyPopUp.ccbi",
    handlerMap = { --按钮点击事件
        onClose     = "onClose",
        onCancel     = "onClose",
        onConfirmation 	= "onYes",
        onAdd      = "onIncrease",
        onAddTen      = "onIncreaseTen",
        onReduction      = "onDecrease",
        onReductionTen      = "onDecreaseTen",
    },
    opcode = opcodes
}

local SuitPatchNumberPopUpPageBase = {}
function SuitPatchNumberPopUpPageBase:onEnter(container)
	curCount = 1
	NodeHelper:setStringForLabel(container,{
        mCostGoldLab = common:getLanguageString("@SuitGetLab"),
        mTitle = common:getLanguageString("@SuitPatchNumberTitle"),
        --mReduceNum      = "<<",
        --mTopNum         = ">>"
    })
	NodeHelper:setSpriteImage(container,{mIconPic = GameConfig.SuitImage})
	self:refreshCountAndPrice(container)
    self:registerPacket(container)
end

function SuitPatchNumberPopUpPageBase:onExecute(container)

end

function SuitPatchNumberPopUpPageBase:onExit(container)
    self:removePacket(container)
end

function SuitPatchNumberPopUpPageBase:onClose(container)
    PageManager.popPage(thisPageName)
    --PageManager.changePage("MainScenePage") 
    --PageManager.pushPage("PlayerInfoPage")
end

function SuitPatchNumberPopUpPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then
        local msg = HeadFrame_pb.HPHeadFrameStateRet()
        msg:ParseFromString(msgBuff)
        protoDatas = msg

        --self:rebuildItem(container)
        return
    end     
end

function SuitPatchNumberPopUpPageBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then --这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;

        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then

        end
    end
end

function SuitPatchNumberPopUpPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function SuitPatchNumberPopUpPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

function SuitPatchNumberPopUpPageBase:onYes(container)
    curItemData.count = curCount
    require("EquipSuitExchangeCrystal")
    EquipSuitExchangeCrystal_setItemData(curItemData)
    PageManager.refreshPage("EquipSuitCrystalSelectPage", "selected")
    PageManager.refreshPage("EquipSuitExchangeCrystal", "selected")
	PageManager.popPage(thisPageName)
end	

function SuitPatchNumberPopUpPageBase:onIncrease(container)
    if curCount == curItemData.count then
        --MessageBoxPage:Msg_Box_Lan("@BuyCountLimit")
        return
    end
    curCount = curCount + 1*mMultiple
    self:refreshCountAndPrice(container)
end

function SuitPatchNumberPopUpPageBase:onDecrease(container)
    if curCount<=1 then
        return
    end
    curCount = curCount - 1*mMultiple
    self:refreshCountAndPrice(container)
end

function SuitPatchNumberPopUpPageBase:onIncreaseTen(container)
    if curCount>(curItemData.count-10*mMultiple) then
        -- if isExchangeGoldBean then
        --      MessageBoxPage:Msg_Box_Lan("@YaYaBuyCountLimit")
        -- else
        --      MessageBoxPage:Msg_Box_Lan("@BuyCountLimit")
        -- end
        curCount = curItemData.count
    elseif curCount == 1 then
        curCount = 10*mMultiple
    else
        curCount = curCount + 10*mMultiple
    end
    self:refreshCountAndPrice(container)
end

function SuitPatchNumberPopUpPageBase:onDecreaseTen(container)
    if curCount<10*mMultiple then
        curCount = 1*mMultiple
    else
        curCount = curCount - 10*mMultiple
    end

    if curCount == 0 then curCount = 1 end
    self:refreshCountAndPrice(container)
end

function SuitPatchNumberPopUpPageBase:refreshCountAndPrice(container)
    -- if curCount>maxCount then
    --     curCount = maxCount
    -- end
    -- if priceGetter==nil then
    --     NodeHelper:setNodesVisible(container,{mCostGoldLab=false ,mCostGoldNum = false})
    --     NodeHelper:setStringForLabel(container,{mAddNum = curCount})
    --     return
    -- end
    local exchangeNum = 10
    local cfg = ItemManager:getItemCfgById(curItemData.itemId)
    local exchangeCrystalNum = cfg["exchangeCrystalNum"]
    if exchangeCrystalNum ~= 0 and #exchangeCrystalNum ~=0 then
        exchangeNum = exchangeCrystalNum[1]["count"]
    end
	local totalPrice = curCount*exchangeNum
    -- local priceMsg = ""
    -- local priceColor = GameConfig.ColorMap.COLOR_WHITE
    -- if priceType == Const_pb.MONEY_GOLD then
    --     priceMsg = common:getLanguageString("@CostGold")
    --     if totalPrice>UserInfo.playerInfo.gold then
    --         priceColor = GameConfig.ColorMap.COLOR_RED
    --     end
    -- elseif priceType == Const_pb.MONEY_COIN then
    --     priceMsg = common:getLanguageString("@CostCoin")
    --     if totalPrice>UserInfo.playerInfo.coin then
    --         priceColor = GameConfig.ColorMap.COLOR_RED
    --     end
    -- end

    NodeHelper:setStringForLabel(container,{mCostGoldNum = totalPrice,mAddNum = curCount})
    --NodeHelper:setColorForLabel(container,{mCostGoldNum=priceColor})
end

function SuitPatchNumberPopUpPageBase_setCurItemData(itemData)
	curItemData = itemData
end

local CommonPage = require('CommonPage')
local SuitPatchNumberPopUpPage= CommonPage.newSub(SuitPatchNumberPopUpPageBase, thisPageName, option)