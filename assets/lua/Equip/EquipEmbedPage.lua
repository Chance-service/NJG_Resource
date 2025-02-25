
----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local EquipOpr_pb = require("EquipOpr_pb");
local HP_pb = require("HP_pb");
local UserInfo = require("PlayerInfo.UserInfo");

------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local table = table;
--------------------------------------------------------------------------------
local gemSelectPage = "GemSelectPage";
registerScriptPage(gemSelectPage);

local thisPageName = "EquipEmbedPage";
local thisEquipId = 0;
local COUNT_SLOT = 4;

local opcodes = {
    EQUIP_STONE_UNDRESS_S = HP_pb.EQUIP_STONE_UNDRESS_S,
    EQUIP_PUNCH_S = HP_pb.EQUIP_PUNCH_S,
    EQUIP_STONE_DRESS_S = HP_pb.EQUIP_STONE_DRESS_S
};

local option = {
    ccbiFile = "EquipmentCameoIncrustationPopUp.ccbi",
    handlerMap =
    {
        onFastUnload = "onFastUnload",
        onHelp = "onHelp",
        onClose = "onClose"
    },
    opcode = opcodes
};
for i = 1, COUNT_SLOT do
    option.handlerMap["onGemHand" .. i] = "onGemOpr"
end

local EquipEmbedPageBase = { };

local NodeHelper = require("NodeHelper");
local PBHelper = require("PBHelper");
local EquipOprHelper = require("Equip.EquipOprHelper");
local ItemManager = require("Item.ItemManager");
local NewbieGuideManager = require("NewbieGuideManager")

local GemStatus = {
    NoSlot = - 1,
    NoGem = 0
};
local gemPos2Id = { };
local minUnlockSlot = COUNT_SLOT + 1;
local gemCount = 0;
local gemQuality = { };
-----------------------------------------------
-- EquipEmbedPageBase页面中的事件处理
----------------------------------------------
function EquipEmbedPageBase:onEnter(container)
    self:registerPacket(container);
    self:showEmbedTip(container);
    self:refreshPage(container);
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_EMBED)
end

function EquipEmbedPageBase:onExit(container)
    self:removePacket(container);
end
----------------------------------------------------------------

function EquipEmbedPageBase:refreshPage(container)
    self:showEquipInfo(container);
    self:showGemInfo(container);
end

function EquipEmbedPageBase:showEmbedTip(container)
    local lb2Str = {
        mExplain = common:getLanguageString("@EmbedGemMsg",GameConfig.OpenLevel.GemPunch)
    };
    NodeHelper:setStringForLabel(container, lb2Str);
end
	
function EquipEmbedPageBase:showEquipInfo(container)
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    if userEquip == nil or userEquip.id == nil then
        return;
    end

    local equipId = userEquip.equipId;
    local level = EquipManager:getLevelById(equipId);
    local name = EquipManager:getNameById(equipId);
    local lb2Str = {
        mLv = common:getR2LVL() .. level,
        mLvNum = userEquip.strength == 0 and "" or "+" .. userEquip.strength,
        mEquipmentIName = common:getLanguageString("@LevelName",name)
    };
    local sprite2Img = {
        mPic = EquipManager:getIconById(equipId)
    };
    local itemImg2Qulity = {
        mHand = EquipManager:getQualityById(equipId)
    };
    local scaleMap = { mPic = 1.0 };

    gemQuality = { };
    local nodesVisible = { };
    local gemVisible = false;
    local aniVisible = UserEquipManager:isEquipGodly(userEquip);
    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
    if table.maxn(gemInfo) > 0 then
        gemVisible = true;
        for i = 1, 4 do
            local gemId = gemInfo[i];
            nodesVisible["mGemBG" .. i] = gemId ~= nil;
            local gemSprite = "mGem0" .. i;
            nodesVisible[gemSprite] = false;
            if gemId ~= nil and gemId > 0 then
                local icon = ItemManager:getGemSmallIcon(gemId);
                local quality = ItemManager:getQualityById(gemId);
                table.insert(gemQuality, tonumber(quality));
                if icon then
                    nodesVisible[gemSprite] = true;
                    sprite2Img[gemSprite] = icon;
                    scaleMap[gemSprite] = 1
                end
            end
        end
    end
    nodesVisible["mAni"] = aniVisible;
    nodesVisible["mGemNode"] = gemVisible;
    NodeHelper:setNodesVisible(container, nodesVisible);

    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, itemImg2Qulity);

    NodeHelper:addEquipAni(container, "mAni", aniVisible, thisEquipId);
end

function EquipEmbedPageBase:showGemInfo(container)
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);

    local lb2Str = { };
    local sprite2Img = { };
    local itemImg2Quality = { };
    local nodesVisible = { }
    minUnlockSlot = COUNT_SLOT + 1;
    gemCount = 0;
    for _, gemInfo in ipairs(userEquip.gemInfos) do
        local pos = gemInfo.pos;
        local gemId = gemInfo.gemItemId;
        gemPos2Id[pos] = gemId;

        local nameLb = "mGemName" .. pos;
        local numLb = "mGemNum" .. pos;
        local pic = "mGemPic" .. pos;
        local frame = "mGemHand" .. pos;
        local lockPic = "mLockPic" .. pos
        lb2Str[nameLb] = "";
        lb2Str[numLb] = "";
        itemImg2Quality[frame] = tonumber(ItemManager:getQualityById(gemId)) or GameConfig.Default.Quality;

        local hasSlot = gemId ~= GemStatus.NoSlot;
        if hasSlot then
            nodesVisible[lockPic] = false
            local hasGem = gemId ~= GemStatus.NoGem;
            if hasGem then
                local quality = ItemManager:getQualityById(gemId)
                lb2Str[nameLb] = ItemManager:getNameById(gemId);
                lb2Str[numLb] = ItemManager:getNewGemAttrString(gemId);
                sprite2Img[pic] = ItemManager:getIconById(gemId);
                sprite2Img["mFrameShade" .. pos] = NodeHelper:getImageBgByQuality(quality)
                NodeHelper:setColorForLabel(container, { ["mGemName" .. pos] = ConfigManager.getQualityColor()[quality].textColor })
                NodeHelper:setColorForLabel(container, { ["mGemNum" .. pos] = ConfigManager.getQualityColor()[quality].textColor })
                gemCount = gemCount + 1;
            else
                sprite2Img["mFrameShade" .. pos] = GameConfig.Image.BackQualityImg
                -- sprite2Img[pic] = GameConfig.Image.ClickToSelect;
                sprite2Img[pic] = GameConfig.Image.Empty
            end
        else
            nodesVisible[lockPic] = true
            -- lb2Str[nameLb] = common:getLanguageString("@ClickToPunch");
            ----sprite2Img[pic] = GameConfig.Image.PunchSlot;
            -- minUnlockSlot = math.min(minUnlockSlot, pos);

            minUnlockSlot = math.min(minUnlockSlot, pos);
            if pos == minUnlockSlot then
                lb2Str[nameLb] = common:getLanguageString("@ClickToPunch");
            end
        end
    end
    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setQualityFrames(container, itemImg2Quality, nil, true);
end
	
----------------click event------------------------
function EquipEmbedPageBase:onFastUnload(container)
    if gemCount > 0 then
        EquipOprHelper:unloadAllGem(thisEquipId);
    else
        MessageBoxPage:Msg_Box_Lan("@NoneEmbeded");
    end
end

function EquipEmbedPageBase:onGemOpr(container, eventName)
    local pos = tonumber(eventName:sub(-1));
    local gemId = gemPos2Id[pos];

    local hasSlot = gemId ~= GemStatus.NoSlot;
    if hasSlot then
        local hasGem = gemId ~= GemStatus.NoGem;
        if not hasGem then
            GemSelectPage_setEquipIdAndPos(thisEquipId, pos, gemPos2Id);
            PageManager.pushPage(gemSelectPage);
        else
            EquipOprHelper:unloadGem(thisEquipId, pos);
        end
    else
        local openLevel = GameConfig.OpenLevel.GemPunch;
        if UserInfo.roleInfo.level < openLevel then
            MessageBoxPage:Msg_Box(common:getLanguageString("@EmbedGemMsg", openLevel));
        else
            self:doPunch(pos);
        end
    end
end	

function EquipEmbedPageBase:doPunch(pos)
    local title = common:getLanguageString("@PunchSlot_Title");
    if pos > minUnlockSlot then
        local msg = common:getLanguageString("@PlzPunchPreSlot", minUnlockSlot);
        PageManager.showNotice(title, msg, nil, nil, nil, 0.9);
        return;
    end

    local sureToPunch = function(isSure, type)
        if isSure then
            print("type = ", type)
            EquipOprHelper:punchEquip(thisEquipId, pos, type);
        end
    end;

    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);

    CCLuaLog("EquipEmbedPageBase userEquip.equipId :" .. tostring(userEquip.equipId) .. "   " .. tostring(pos))

    local consume = EquipManager:getPunchConsume(userEquip.equipId, pos);

    CCLuaLog("EquipEmbedPageBase consume :" .. tostring(consume == nil) .. "   " .. tostring(consume))
    if consume == nil then
        sureToPunch(true);
        return;
    end

    for i, v in ipairs(consume) do
        CCLuaLog("EquipEmbedPageBase i : " .. tostring(i) .. "  type:" .. tostring(v.type) .. "  id:" .. tostring(v.id) .. "   count:" .. tostring(v.count))
    end

    local resInfo = ResManagerForLua:getResInfoByTypeAndId(consume[1].type, consume[1].id, consume[1].count);
    local resInfo2
    if consume[2] then
        resInfo2 = ResManagerForLua:getResInfoByTypeAndId(consume[2].type, consume[2].id, consume[2].count);
    end
    local msg
    local yesStr, noStr
    if resInfo2 then
        msg = common:getLanguageString("@PunchSlot_Msg1", resInfo2.name, consume[2].count, resInfo.name, consume[1].count);
        yesStr = "@UseDiamond"
        noStr = "@UseItem"
    else
        msg = common:getLanguageString("@PunchSlot_Msg", resInfo.name, consume[1].count);
    end
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            local type = consume[1].type;
            local id = consume[1].id;
            local count = consume[1].count
            if ResManagerForLua:checkConsume(type, id, count) then
                sureToPunch(true, 2);
            end
        else
            if resInfo2 and consume[2] then
                if ResManagerForLua:checkConsume(consume[2].type, consume[2].id, consume[2].count) then
                    sureToPunch(true, 1);
                end
            end
        end
    end , nil, yesStr, noStr, true);
end	

function EquipEmbedPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_EMBED);
end		

function EquipEmbedPageBase:onClose(container)
    PageManager.popPage(thisPageName);
end

-- 回包处理
function EquipEmbedPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if common:table_hasValue(opcodes, opcode) then
        self:refreshPage(container);
        return
    end
end

function EquipEmbedPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EquipEmbedPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
EquipEmbedPage = CommonPage.newSub(EquipEmbedPageBase, thisPageName, option);

function EquipEmbedPage_setEquipId(equipId)
    thisEquipId = equipId;
end