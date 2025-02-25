--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local UserMercenaryManager = require("UserMercenaryManager")
local UserItemManager = require("Item.UserItemManager")
local thisPageName = "FashionLockPopUp"

local option = {
    ccbiFile = "FashionLockPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onUnlock = "onUnlock"
    },
    opcodes =
    {
        ROLE_UPGRADE_STAGE2_C = HP_pb.ROLE_UPGRADE_STAGE2_C,
        ROLE_UPGRADE_STAGE2_S = HP_pb.ROLE_UPGRADE_STAGE2_S,
    }
}
local FashionLockPopUpBase = {
}

local tempContainer = nil

local UnlockItemid = nil

local needItem = nil

local SkinDemand = nil

local haveItem = false

function FashionLockPopUpBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
    tempContainer = container
end

function FashionLockPopUpBase:onEnter(container)
    self:registerPacket(container)
    SkinDemand  = ConfigManager:getSkinDemandCfg()
    self:refreshPage(container)

end

function FashionLockPopUpBase:onClose(container)
    GameUtil:purgeCachedData()
    PageManager.popPage(thisPageName)
end

function FashionLockPopUpBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function FashionLockPopUpBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function FashionLockPopUpBase:setUnlockItemId(itemid)
    UnlockItemid = itemid
end

function FashionLockPopUpBase:onExit(container)
    self:removePacket(container)
    UnlockItemid = nil
end

function FashionLockPopUpBase:onUnlock(container)
    if not (haveItem) then
        MessageBoxPage:Msg_Box_Lan("@Error_Skindemand") 
        return 
    end
    local msg = Player_pb.HPRoleUpStage()
    local info = UserMercenaryManager:getUserMercenaryByItemId(UnlockItemid)
    msg.roleId = info.roleId
    common:sendPacket(HP_pb.ROLE_UPGRADE_STAGE2_C, msg, false)
end

function FashionLockPopUpBase:refreshPage(container)
    needItem = nil
    local info = UserMercenaryManager:getUserMercenaryByItemId(UnlockItemid)
    if (UnlockItemid) then
        needItem = SkinDemand[UnlockItemid]["needItem" .. info.stageLevel2 + 1] or nil
    end
    haveItem = false
    if (needItem) then
        haveItem = true
        for i = 1 , #needItem do
            local data = ResManagerForLua:getResInfoByTypeAndId(tonumber(needItem[i].type), tonumber(needItem[i].itemId), tonumber(needItem[i].count))
            NodeHelper:setSpriteImage(container,{["mItemIcon"..i] = data.icon})
            local itemnum = UserItemManager:getCountByItemId(needItem[i].itemId)
            NodeHelper:setStringForTTFLabel(container,{["mItemName"..i] = data.name,["mItemCount"..i] = (itemnum.."/"..needItem[i].count)})
            if (itemnum < needItem[i].count) then
                NodeHelper:setColorForLabel(container, { ["mItemCount" .. i] = GameConfig.ColorMap.COLOR_RED })
                haveItem = false
            else
                NodeHelper:setColorForLabel(container, { ["mItemCount" .. i] = "171 91 64" })
            end
        end
    else
        for i = 1 , 3 do
            NodeHelper:setSpriteImage(container,{["mItemIcon"..i] = "UI/Mask/Image_Empty.png"})
            NodeHelper:setStringForTTFLabel(container,{["mItemName"..i] = "",["mItemCount"..i] = "0/0"})
            NodeHelper:setColorForLabel(container, { ["mItemCount" .. i] = "171 91 64" })
        end
    end
    NodeHelper:setStringForLabel(container, { ["mUnlockStageTxt"] = common:getLanguageString("@Role_" ..  UnlockItemid) .. common:getLanguageString("@SkinUnlock" ..  (info.stageLevel2 + 1)) })
end

function FashionLockPopUpBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == option.opcodes.ROLE_UPGRADE_STAGE2_S then
        --self:refreshPage(container)
        local FetterShowPage = require("FetterShowPage")
        FetterShowPage:refreshPage(FetterShowPage:getcontainer(),true)
        self:onClose()
    end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local FashionLockPopUp = CommonPage.newSub(FashionLockPopUpBase, thisPageName, option);

return FashionLockPopUp
--endregion
