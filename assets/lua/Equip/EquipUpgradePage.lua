

local thisPageName = "EquipUpgradePage"
local NodeHelper = require("NodeHelper")
local EquipUpgradePageBase = { }
local MAX_EVOLUTION_STUFF_NUM = 4
local PageInfo = {
    thisUserEquipId = 0,
    currEquipInfo =
    {
        userEquipInfo = { },
        itemInfo = { }
    },
    evolutionItemInfo = { },
    nodeParams =
    {
        mainNode = "mRewardNode",
        picNode = "mPic",
        qualityNode = "mFrame",
        numNode = "mNum",
        nameNode = "mName"
    }
}

local opcodes = {
    EQUIP_EVOLUTION_C = HP_pb.EQUIP_UPGRADE_C,
    EQUIP_EVOLUTION_S = HP_pb.EQUIP_UPGRADE_S
}

local option = {
    ccbiFile = "SuitUpgradePopUp.ccbi",
    handlerMap =
    {
        onAKeyEvolution = "onCancle",
        onEvolution = "onEvolution",
        onClose = "onClose",
        onEquipmentFrame2 = "onEquipmentFrame2"
    },
    opcode = opcodes
}

local stuffList = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4
}

for i = 1, #stuffList do
    option.handlerMap["onFrame" .. i] = "showTips"
end
---------------------------------------------------------------------------------------------------------------------------------
function EquipUpgradePageBase:onEnter(container)
    self:registerPacket(container)
    if PageInfo.thisUserEquipId == nil or PageInfo.thisUserEquipId <= 0 then return end
    self:initData(container)
    self:refreshPage(container)
end

function EquipUpgradePageBase:onExecute(container)

end

function EquipUpgradePageBase:onExit(container)
    self:removePacket(container)
end

--------------------------------------------------------------------------------------------------------------------------------

function EquipUpgradePageBase:initData(container)
    local UserEquipManager = require("Equip.UserEquipManager")
    local EquipManager = require("Equip.EquipManager")

    -- 玩家身上的需要升级装备
    PageInfo.currEquipInfo.userEquipInfo = UserEquipManager:getUserEquipById(PageInfo.thisUserEquipId)
    -- 需要升级的装备信息
    PageInfo.currEquipInfo.itemInfo = EquipManager:getEquipCfgById(PageInfo.currEquipInfo.userEquipInfo.equipId)
    -- 升级后的装备信息
    PageInfo.evolutionItemInfo = EquipManager:getEquipCfgById(PageInfo.currEquipInfo.itemInfo.upgradeId)
end

function EquipUpgradePageBase:refreshPage(container)
    local NodeHelper = require("NodeHelper")
    local UserInfo = require("PlayerInfo.UserInfo")
    local EquipManager = require("Equip.EquipManager")
    UserInfo.sync()
    local lb2StrStuff = { }
    local sprite2Img = {
        mEquipmentPic1 = PageInfo.currEquipInfo.itemInfo.icon,
        mEquipmentPic2 = PageInfo.evolutionItemInfo.icon
    }


    local mOriName1 = PageInfo.currEquipInfo.itemInfo.name
    local mOriName2 = PageInfo.evolutionItemInfo.name
    local gule = ","
    local mOriMainAttr1 = EquipManager:getInitAttr(PageInfo.currEquipInfo.itemInfo.id, gule, PageInfo.currEquipInfo.userEquipInfo.strength, PageInfo.currEquipInfo.itemInfo.quality)
    local mOriMainAttr2 = EquipManager:getInitAttr(PageInfo.evolutionItemInfo.id, gule, PageInfo.currEquipInfo.userEquipInfo.strength, PageInfo.evolutionItemInfo.quality)

    local mOriAdditionalAttr1 = common:getLanguageString("@AdditionalAttr", PageInfo.currEquipInfo.itemInfo.additionalAttr)
    local mOriAdditionalAttr2 = common:getLanguageString("@AdditionalAttr", PageInfo.evolutionItemInfo.additionalAttr)

    local htmlStrTab1 = mOriName1 .. "<br/>"
    local htmlStrTab2 = mOriName2 .. "<br/>"

    local attrOriMainTab1 = common:split(mOriMainAttr1, gule)
    local attrOriMainTab2 = common:split(mOriMainAttr2, gule)
    attrOriMainTab1[#attrOriMainTab1 + 1] = mOriAdditionalAttr1
    attrOriMainTab2[#attrOriMainTab2 + 1] = mOriAdditionalAttr2

    for i = 1, 3 do
        if i <= #attrOriMainTab1 then
            lb2StrStuff["mEquipAtt" .. i] = attrOriMainTab1[i]
            lb2StrStuff["mEquipAtt" .. i + 3] = attrOriMainTab2[i]
            NodeHelper:setNodesVisible(container, { ["mEquipArrow" .. i] = true })
        else
            lb2StrStuff["mEquipAtt" .. i] = ""
            lb2StrStuff["mEquipAtt" .. i + 3] = ""
            NodeHelper:setNodesVisible(container, { ["mEquipArrow" .. i] = false })
        end
    end

    local suitCfg = ConfigManager.getSuitCfg()
    local curSuitId = EquipManager:getSuitIdById(PageInfo.currEquipInfo.userEquipInfo.equipId)
    local nextSuitId = EquipManager:getSuitIdById(PageInfo.currEquipInfo.itemInfo.upgradeId)

    lb2StrStuff["mEquipLevel1"] = suitCfg[curSuitId].suitName
    lb2StrStuff["mEquipLevel2"] = suitCfg[nextSuitId].suitName

    -- local curMercenarySuitId = EquipManager:getMercenarySuitId(PageInfo.currEquipInfo.userEquipInfo.equipId);
    -- local nextMercenarySuitId = EquipManager:getMercenarySuitId( PageInfo.currEquipInfo.itemInfo.upgradeId )
    -- lb2StrStuff["mMercenaryName1"] = common:getLanguageString("@Role_"..EquipManager:getMercenarySuitMercenaryId(curMercenarySuitId))..common:getLanguageString("@EquipStr6")
    -- lb2StrStuff["mMercenaryName2"] = common:getLanguageString("@Role_"..EquipManager:getMercenarySuitMercenaryId(nextMercenarySuitId))..common:getLanguageString("@EquipStr6")
    -- 当前属性
    -- for i=1,3 do
    --   NodeHelper:setStringForLabel(container, {["mEquipEverAtt"..i] = "", ["mEquipNowAtt"..i] = ""})
    -- end

    -- local descs = EquipManager:getMercenarySuitDescs(curMercenarySuitId)
    -- local index = 1
    -- for k,v in pairs(descs) do
    --    lb2StrStuff["mEquipEverAtt"..index] = common:getLanguageString("@EquipStr"..tostring(6+index))..v
    --    index = index + 1
    -- end

    -- ---下一级属性
    -- local descs = EquipManager:getMercenarySuitDescs(nextMercenarySuitId)
    -- local index = 1
    -- for k,v in pairs(descs) do
    --    lb2StrStuff["mEquipNowAtt"..index] = common:getLanguageString("@EquipStr"..tostring(6+index))..v
    --    index = index + 1
    -- end

    -- htmlStrTab1 = htmlStrTab1 .. mOriAdditionalAttr1
    -- htmlStrTab2 = htmlStrTab2 .. mOriAdditionalAttr2

    -- common:fillHtmlStr("EvoMain1" ,htmlStrTab1)

    -- NodeHelper:addHtmlLable( container:getVarNode("mEquipLevel1") , common:fillHtmlStr("EvoMain1" ,htmlStrTab1) ,GameConfig.Tag.HtmlLable, CCSize(200, 90))
    -- NodeHelper:addHtmlLable( container:getVarNode("mEquipLevel2") , common:fillHtmlStr("EvoMain2" ,htmlStrTab2) ,GameConfig.Tag.HtmlLable + 1, CCSize(200, 90) )

    local menu2Quality = {
        mEquipmentFrame1 = PageInfo.currEquipInfo.itemInfo.quality,
        mEquipmentFrame2 = PageInfo.evolutionItemInfo.quality
    }

    NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setQualityFrames(container, menu2Quality)

    local currStuffNum = #PageInfo.currEquipInfo.itemInfo.fixedMaterial
    local nodesVisible = { }
    for i = 1, MAX_EVOLUTION_STUFF_NUM, 1 do
        nodesVisible[PageInfo.nodeParams.mainNode .. i] = i <= currStuffNum
    end
    NodeHelper:setNodesVisible(container, nodesVisible)

    local sprite2ImgStuff = { }
    local menu2QualityStuff = { }

    -- 名字
    local colorMap2 = { }
    lb2StrStuff.mName1 = PageInfo.currEquipInfo.itemInfo.name
    lb2StrStuff.mName2 = PageInfo.evolutionItemInfo.name
    local mOriLevel1 = tonumber(PageInfo.currEquipInfo.itemInfo.level)
    local mOriLevel2 = tonumber(PageInfo.evolutionItemInfo.level)

    -- 装备等级
    if mOriLevel1 > 100 then
        lb2StrStuff.mLv1 = common:getLanguageString("@NewLevelStr", math.floor(mOriLevel1 / 100), tonumber(mOriLevel1) -100)
    else
        lb2StrStuff.mLv1 = common:getLanguageString("@LevelStr", mOriLevel1)
    end

    if mOriLevel2 > 100 then
        lb2StrStuff.mLv2 = common:getLanguageString("@NewLevelStr", math.floor(mOriLevel2 / 100), tonumber(mOriLevel2) -100)
    else
        lb2StrStuff.mLv2 = common:getLanguageString("@LevelStr", mOriLevel2)
    end
    -- lb2StrStuff.mLv2 = common:getLanguageString("@NewLevelStr", math.floor(mOriLevel2/100), tonumber(mOriLevel2) - 100)

    for i = 1, currStuffNum, 1 do
        local cfg = PageInfo.currEquipInfo.itemInfo.fixedMaterial[i]
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
        local UserItemManager = require("Item.UserItemManager")

        local hasCount = 0

        if resInfo.itemId == 1001 then
            hasCount = UserInfo.playerInfo.gold
        elseif resInfo.itemId == 1002 then
            hasCount = UserInfo.playerInfo.coin
        elseif resInfo.itemId == 1010 then
            hasCount = UserInfo.playerInfo.honorValue
        elseif resInfo.itemId == 1011 then
            hasCount = UserInfo.playerInfo.reputationValue
        else
            if UserItemManager:getUserItemByItemId(resInfo.itemId) == nil then
                hasCount = 0
            else
                hasCount = UserItemManager:getUserItemByItemId(resInfo.itemId).count
            end
        end

        local isEnoughMaterial = hasCount >= resInfo.count

        sprite2ImgStuff[PageInfo.nodeParams.picNode .. i] = resInfo.icon
        sprite2ImgStuff["mFrameShade" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality)

        menu2QualityStuff[PageInfo.nodeParams.qualityNode .. i] = resInfo.quality
        -- lb2StrStuff[PageInfo.nodeParams.numNode .. i] = GameUtil:formatNumber(resInfo.count)

        local currentCount = GameUtil:formatNumberMaxBillion(resInfo.count)

        --lb2StrStuff[PageInfo.nodeParams.numNode .. i] = currentCount .. "/" .. GameUtil:formatNumberMaxBillion(hasCount)

        lb2StrStuff[PageInfo.nodeParams.numNode .. i] = GameUtil:formatNumberMaxBillion(hasCount) .. "/" .. currentCount

        if resInfo.count > hasCount then
            -- 红色?
            colorMap2[PageInfo.nodeParams.numNode .. i] = "255 0 0"
        else
            -- 道具品质颜色?
            colorMap2[PageInfo.nodeParams.numNode .. i] = "0 194 0"
            --colorMap2[PageInfo.nodeParams.numNode .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
        end

        -- lb2StrStuff[ PageInfo.nodeParams.numNode  .. i ] = resInfo.count
        -- NodeHelper:addItemIsEnoughHtmlLabNotShowHas(container, PageInfo.nodeParams.numNode..i, resInfo.count, hasCount, GameConfig.Tag.HtmlLable+20+i)
        -- colorMap2[PageInfo.nodeParams.numNode .. i] = UserEquipManager:getEquipEvolutionMaterialColor(isEnoughMaterial and "Enough" or "Short")
        -- lb2StrStuff[ PageInfo.nodeParams.nameNode .. i ] = resInfo.name
    end

    -- NodeHelper:setStringForLabel( container, lb2Str )
    NodeHelper:setColorForLabel(container, colorMap2)
    NodeHelper:setStringForLabel(container, lb2StrStuff)
    NodeHelper:setSpriteImage(container, sprite2ImgStuff)
    NodeHelper:setQualityFrames(container, menu2QualityStuff, nil, true)
    -- NodeHelper:setColor3BForLabel(container, colorMap2);
    -- GameUtil:showTip(container:getVarNode("mHand"), rewadItems[id])
end


--------------------------------------------------------------------------------------------------------------------------------

function EquipUpgradePageBase:showTips(container, eventName)
    local indexStr = string.sub(eventName, -3)
    local index = tonumber(string.sub(eventName, -1))
    if PageInfo.currEquipInfo.itemInfo.fixedMaterial[index] ~= nil then
        GameUtil:showTip(container:getVarNode('mFrame' .. index), {
            type = PageInfo.currEquipInfo.itemInfo.fixedMaterial[index].type,
            itemId = tonumber(PageInfo.currEquipInfo.itemInfo.fixedMaterial[index].itemId),
            buyTip = false,
        } )
    end
end

function EquipUpgradePageBase:onEquipmentFrame2(container)
    --    GameUtil:showTip(container:getVarNode('mEquipmentFrame2'), {
    --  type    = 40000,
    --  itemId    = tonumber(PageInfo.evolutionItemInfo.id),
    --  buyTip    = false,
    --  starEquip = tonumber(PageInfo.evolutionItemInfo.stepLevel) == GameConfig.ShowStepStar
    -- })
end

function EquipUpgradePageBase:onCancle(container)
    PageManager.popPage(thisPageName)
end

function EquipUpgradePageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function EquipUpgradePageBase:onEvolution(container)
    -- local msg = EquipOpr_pb.HPEquipEvolution()
    local msg = EquipOpr_pb.HPEquipUpgrade()
    msg.equipId = PageInfo.thisUserEquipId
    msg.fixFlag = 0
    common:sendPacket(opcodes.EQUIP_EVOLUTION_C, msg, false)
end

--------------------------------------------------------------------------------------------------------------------------------
function EquipUpgradePageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.EQUIP_EVOLUTION_S then
        MessageBoxPage:Msg_Box_Lan("@EvolutionSuccess")
        PageManager.popPage(thisPageName)
        PageManager.refreshPage("EquipInfoPage")
        -- PageManager.refreshPage("EquipmentPage")
        PageManager.refreshPage("EquipMercenaryPage")
    end
end

function EquipUpgradePageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EquipUpgradePageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
EquipUpgradePage = CommonPage.newSub(EquipUpgradePageBase, thisPageName, option)

function EquipUpgradePage_setItemId(userEquipId)
    PageInfo.thisUserEquipId = userEquipId
end