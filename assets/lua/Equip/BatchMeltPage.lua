


local HP_pb = require("HP_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local Const_pb = require("Const_pb")
local GuideManager = require("Guide.GuideManager")
------------local variable for system api--------------------------------------
local pairs = pairs;
--------------------------------------------------------------------------------
-- registerScriptPage(buildPage);
local EquipOprHelper = require("Equip.EquipOprHelper");
local EquipManager = require("Equip.EquipManager")
local thisPageName = "BatchMeltPage";

local opcodes = {
    EQUIP_SMELT_INFO_S = HP_pb.EQUIP_SMELT_INFO_S,
    EQUIP_SMELT_S = HP_pb.EQUIP_SMELT_S,
    ERROR_CODE_S = HP_pb.ERROR_CODE
};

local COUNT_EQUIPMENT_SOURCE_MAX = 6;

local option = {
    ccbiFile = "RefiningBatchPopUp_1.ccbi",
    handlerMap =
    {
        onWhiteEquipment = "onWhite",
        onGreenEquipment = "onGreen",
        onBlueEquipment = "onBlue",
        onPurpleEquipment = "onPurple",
        onOrangeEquipment = "onOrange",
        onRedEquipment = "onRed",
        onSelectAll = "onSelectedAll",
        onConfirmation = "onMelt",
        onClose = "onClose"
    },
    opcode = opcodes
};

local BatchMeltPageBase = { };
local NodeHelper = require("NodeHelper");
local mMeltPageBase = nil

BatchMeltPageBase.SelectedMap = {
    selectedWhite = false,
    selectedGreen = false,
    selectedBlue = false,
    selectedPurple = false,
    selectedOrange = false,
    selectedRed = false,
}
-----------------------------------------------
-- BatchMeltPageBase页面中的事件处理
----------------------------------------------
local mParentContainer = nil
local mTopContainer = nil
-- function BatchMeltPageBase:onEnter(container)
-- self:registerPacket(container);
-- self:refreshPage(container);
--    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
--        NodeHelper:SetNodePostion(container,"mOrangeEquipmentBtn",30);
--    end
-- end

function BatchMeltPageBase:onEnter(ParentContainer, TopContainer, MeltPageBase)
    mParentContainer = container
    mTopContainer = TopContainer
    mMeltPageBase = MeltPageBase
    self.container = ScriptContentBase:create(option.ccbiFile)
    self.container:registerFunctionHandler(BatchMeltPageBase.onFunction)
    
    self:registerPacket(mTopContainer);
    self:refreshPage(self.container);
    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
        NodeHelper:SetNodePostion(self.container, "mOrangeEquipmentBtn", 30);
    end

    return self.container
end

function BatchMeltPageBase:onExit(container)
    self:removePacket(container);
    BatchMeltPageBase.SelectedMap = {
        selectedWhite = false,
        selectedGreen = false,
        selectedBlue = false,
        selectedPurple = false,
        selectedOrange = false,
        selectedRed = false;
    }
end
----------------------------------------------------------------

function BatchMeltPageBase:refreshPage(container)
    NodeHelper:setNodesVisible(container, {
        mSelected1 = BatchMeltPageBase.SelectedMap.selectedWhite,
        mSelected4 = BatchMeltPageBase.SelectedMap.selectedGreen,
        mSelected2 = BatchMeltPageBase.SelectedMap.selectedBlue,
        mSelected5 = BatchMeltPageBase.SelectedMap.selectedPurple,
        mSelected3 = BatchMeltPageBase.SelectedMap.selectedOrange,
        mSelected6 = BatchMeltPageBase.SelectedMap.selectedRed,

        mChoice1 = not BatchMeltPageBase.SelectedMap.selectedWhite,
        mChoice4 = not BatchMeltPageBase.SelectedMap.selectedGreen,
        mChoice2 = not BatchMeltPageBase.SelectedMap.selectedBlue,
        mChoice5 = not BatchMeltPageBase.SelectedMap.selectedPurple,
        mChoice3 = not BatchMeltPageBase.SelectedMap.selectedOrange,
        mChoice6 = not BatchMeltPageBase.SelectedMap.selectedRed,
    } )

    if BatchMeltPageBase.SelectedMap.selectedWhite and BatchMeltPageBase.SelectedMap.selectedGreen and
        BatchMeltPageBase.SelectedMap.selectedBlue and BatchMeltPageBase.SelectedMap.selectedPurple and
        BatchMeltPageBase.SelectedMap.selectedOrange and BatchMeltPageBase.SelectedMap.selectedRed then

        NodeHelper:setStringForLabel(container, { mSelectedLab = common:getLanguageString("@CancelSelectAll") })
    else
        NodeHelper:setStringForLabel(container, { mSelectedLab = common:getLanguageString("@SelectAll") })
    end
end

function BatchMeltPageBase:reSetRankTypeList(container)   
    local qualitys = { }
    if BatchMeltPageBase.SelectedMap.selectedWhite then
        table.insert(qualitys, Const_pb.WHITE)
    end
    if BatchMeltPageBase.SelectedMap.selectedGreen then
        table.insert(qualitys, Const_pb.GREEN)
    end
    if BatchMeltPageBase.SelectedMap.selectedBlue then
        table.insert(qualitys, Const_pb.BLUE)
    end
    if BatchMeltPageBase.SelectedMap.selectedPurple then
        table.insert(qualitys, Const_pb.PURPLE)
    end
    if BatchMeltPageBase.SelectedMap.selectedOrange then
        table.insert(qualitys, Const_pb.ORANGE)
    end
    if BatchMeltPageBase.SelectedMap.selectedRed then
        table.insert(qualitys, Const_pb.RED)
    end

    mMeltPageBase:setBatchMeltrefiningValue(qualitys);
end

----------------click event------------------------

function BatchMeltPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function BatchMeltPageBase:onWhite(container)
    BatchMeltPageBase.SelectedMap.selectedWhite = not BatchMeltPageBase.SelectedMap.selectedWhite
    self:refreshPage(container)
    self:reSetRankTypeList(container);
end

function BatchMeltPageBase:onGreen(container)
    BatchMeltPageBase.SelectedMap.selectedGreen = not BatchMeltPageBase.SelectedMap.selectedGreen
    self:refreshPage(container)
    self:reSetRankTypeList(container);
end

function BatchMeltPageBase:onBlue(container)
    BatchMeltPageBase.SelectedMap.selectedBlue = not BatchMeltPageBase.SelectedMap.selectedBlue
    self:refreshPage(container)
    self:reSetRankTypeList(container);
end

function BatchMeltPageBase:onPurple(container)
    BatchMeltPageBase.SelectedMap.selectedPurple = not BatchMeltPageBase.SelectedMap.selectedPurple
    self:refreshPage(container)
    self:reSetRankTypeList(container);
end

function BatchMeltPageBase:onOrange(container)
    BatchMeltPageBase.SelectedMap.selectedOrange = not BatchMeltPageBase.SelectedMap.selectedOrange
    self:refreshPage(container)
    self:reSetRankTypeList(container);
end

function BatchMeltPageBase:onRed(container)
    BatchMeltPageBase.SelectedMap.selectedRed = not BatchMeltPageBase.SelectedMap.selectedRed
    self:refreshPage(container)
    self:reSetRankTypeList(container);
end

function BatchMeltPageBase:isMeltAll()

    for k, v in pairs(BatchMeltPageBase.SelectedMap) do
        if v then
            return v
        end
    end

    return false
end

function BatchMeltPageBase:checkAllSelect(equip)
    if(equip == 1)
    then
        if(BatchMeltPageBase.SelectedMap.selectedWhite)
        then
            BatchMeltPageBase.SelectedMap.selectedWhite = false;
            self:refreshPage(self.container);           
        end
    elseif(equip == 2)
    then
        if(BatchMeltPageBase.SelectedMap.selectedGreen)
        then
            BatchMeltPageBase.SelectedMap.selectedGreen = false;
            self:refreshPage(self.container);           
        end
    elseif(equip == 3)
    then
        if(BatchMeltPageBase.SelectedMap.selectedBlue)
        then
            BatchMeltPageBase.SelectedMap.selectedBlue = false;
            self:refreshPage(self.container);           
        end
    elseif(equip == 4)
    then
        if(BatchMeltPageBase.SelectedMap.selectedPurple)
        then
            BatchMeltPageBase.SelectedMap.selectedPurple = false;
            self:refreshPage(self.container);           
        end
    elseif(equip == 5)
    then
        if(BatchMeltPageBase.SelectedMap.selectedOrange)
        then
            BatchMeltPageBase.SelectedMap.selectedOrange = false;
            self:refreshPage(self.container);           
        end
    elseif(equip == 6)
    then
        if(BatchMeltPageBase.SelectedMap.selectedRed)
        then
            BatchMeltPageBase.SelectedMap.selectedRed = false;
            self:refreshPage(mParentContainer);           
        end
    end
end
function BatchMeltPageBase:clearAllSelect()
    BatchMeltPageBase.SelectedMap.selectedWhite = false
    BatchMeltPageBase.SelectedMap.selectedGreen = false
    BatchMeltPageBase.SelectedMap.selectedBlue = false
    BatchMeltPageBase.SelectedMap.selectedPurple = false
    BatchMeltPageBase.SelectedMap.selectedOrange = false
    BatchMeltPageBase.SelectedMap.selectedRed = false
    self:refreshPage(self.container);          
end

-- 是否对应等级的装备可以熔炼
function BatchMeltPageBase:isCanMelt()
    local qualitys = { }
    if BatchMeltPageBase.SelectedMap.selectedWhite then
        table.insert(qualitys, Const_pb.WHITE)
    end
    if BatchMeltPageBase.SelectedMap.selectedGreen then
        table.insert(qualitys, Const_pb.GREEN)
    end
    if BatchMeltPageBase.SelectedMap.selectedBlue then
        table.insert(qualitys, Const_pb.BLUE)
    end
    if BatchMeltPageBase.SelectedMap.selectedPurple then
        table.insert(qualitys, Const_pb.PURPLE)
    end
    if BatchMeltPageBase.SelectedMap.selectedOrange then
        table.insert(qualitys, Const_pb.ORANGE)
    end
    if BatchMeltPageBase.SelectedMap.selectedRed then
        table.insert(qualitys, Const_pb.RED)
    end

    if #qualitys == 0 then
        MessageBoxPage:Msg_Box_Lan("@BatchMeltNoSelected")
        return
    end

    -- if  equip level >10 + user level
    local hasEquip = false
    local ids = UserEquipManager:getEquipIdsByClass("All", 0);
    local hasHighLevelEquip = false
    local canDress = false
    local mercenaryId = { }
    local mercenaryProf = { }
    local userLevel = UserInfo.roleInfo.level or 1;
    local gap = GameConfig.LevelLimit.EquipDress or 10;
    local highLv = userLevel + gap;
    for _, id in ipairs(ids) do
        local userEquip = UserEquipManager:getUserEquipById(id);
        local part = EquipManager:getPartById(userEquip.equipId)
        local roleEquip = UserInfo.getEquipByPart(part);
        local score = EquipManager:getSmeltScoreById(userEquip.equipId)
        local profession = EquipManager:isDressableWithProfession(userEquip.equipId, UserInfo.roleInfo.prof)
        local dressOr = UserEquipManager:isPartNeedNotice(part)
        local UserMercenaryManager = require("UserMercenaryManager")
        local rolesInfo = UserMercenaryManager:getUserMercenaryInfos()
        for k, v in pairs(rolesInfo) do
            if v.status == 5 then
                table.insert(mercenaryId, v.roleId)
                table.insert(mercenaryProf, v.prof)
            end
        end
        if userEquip ~= nil and userEquip.equipId ~= nil then
            -- if has equip
            if common:table_hasValue(qualitys, EquipManager:getQualityById(userEquip.equipId))
                and not UserEquipManager:isGodly(id)
                and not UserEquipManager:isSuitbyId(id)
                and not UserEquipManager:hasGem(id) then
                hasEquip = true;
                if EquipManager:getLevelById(userEquip.equipId) > highLv then
                    hasHighLevelEquip = true;
                end
                if roleEquip == nil and profession == true then
                    canDress = true
                    break;
                end
                if roleEquip ~= nil then
                    local currentEquip = UserEquipManager:getUserEquipById(roleEquip.equipId);
                    if dressOr == true and currentEquip.score < score and profession == true then
                        canDress = true
                        break;
                    end
                end

                if mercenaryId[1] ~= nil then
                    for k, v in pairs(mercenaryId) do
                        local roleEquipMercenary = UserMercenaryManager:getEquipByPart(v, part);
                        if part ~= 10 and part ~= 8 and part ~= 9 and part ~= 3 then
                            local professionMercenary = EquipManager:isDressableWithProfession(userEquip.equipId, mercenaryProf[k])
                            if roleEquipMercenary == nil and professionMercenary == true then
                                canDress = true
                                break;
                            end
                            if roleEquipMercenary ~= nil then
                                local currentEquipMercenary = UserEquipManager:getUserEquipById(roleEquipMercenary.equipId);
                                local mercenaryDressOr = UserEquipManager:isPartNeedNotice(part, v)
                                if mercenaryDressOr == true and currentEquipMercenary.score < score and professionMercenary == true then
                                    canDress = true
                                    break;
                                end
                            end
                        end
                    end
                end

            end

            if hasEquip and hasHighLevelEquip then
                break
            end
        end
    end

    return hasEquip
end

function BatchMeltPageBase:onMelt(container)
    local qualitys = { }
    if BatchMeltPageBase.SelectedMap.selectedWhite then
        table.insert(qualitys, Const_pb.WHITE)
    end
    if BatchMeltPageBase.SelectedMap.selectedGreen then
        table.insert(qualitys, Const_pb.GREEN)
    end
    if BatchMeltPageBase.SelectedMap.selectedBlue then
        table.insert(qualitys, Const_pb.BLUE)
    end
    if BatchMeltPageBase.SelectedMap.selectedPurple then
        table.insert(qualitys, Const_pb.PURPLE)
    end
    if BatchMeltPageBase.SelectedMap.selectedOrange then
        table.insert(qualitys, Const_pb.ORANGE)
    end

    if #qualitys == 0 then
        MessageBoxPage:Msg_Box_Lan("@BatchMeltNoSelected")
        return
    end

    -- if  equip level >10 + user level
    local hasEquip = false
    local ids = UserEquipManager:getEquipIdsByClass("All", 0);
    local hasHighLevelEquip = false
    local canDress = false
    local mercenaryId = { }
    local mercenaryProf = { }
    local userLevel = UserInfo.roleInfo.level or 1;
    local gap = GameConfig.LevelLimit.EquipDress or 10;
    local highLv = userLevel + gap;
    for _, id in ipairs(ids) do
        local userEquip = UserEquipManager:getUserEquipById(id);
        local part = EquipManager:getPartById(userEquip.equipId)
        local roleEquip = UserInfo.getEquipByPart(part);
        local score = EquipManager:getSmeltScoreById(userEquip.equipId)
        local profession = EquipManager:isDressableWithProfession(userEquip.equipId, UserInfo.roleInfo.prof)
        local dressOr = UserEquipManager:isPartNeedNotice(part)
        local UserMercenaryManager = require("UserMercenaryManager")
        local rolesInfo = UserMercenaryManager:getUserMercenaryInfos()
        for k, v in pairs(rolesInfo) do
            if v.status == 5 then
                table.insert(mercenaryId, v.roleId)
                table.insert(mercenaryProf, v.prof)
            end
        end
        if userEquip ~= nil and userEquip.equipId ~= nil then
            -- if has equip
            if common:table_hasValue(qualitys, EquipManager:getQualityById(userEquip.equipId))
                and not UserEquipManager:isGodly(id)
                and not UserEquipManager:isSuitbyId(id)
                and not UserEquipManager:hasGem(id)
                and EquipManager:getEquipCfgById(userEquip.equipId).isNFT == 0 then
                hasEquip = true;
                if EquipManager:getLevelById(userEquip.equipId) > highLv then
                    hasHighLevelEquip = true;
                end
                if roleEquip == nil and profession == true then
                    canDress = true
                    break;
                end
                if roleEquip ~= nil then
                    local currentEquip = UserEquipManager:getUserEquipById(roleEquip.equipId);
                    if dressOr == true and currentEquip.score < score and profession == true then
                        canDress = true
                        break;
                    end
                end

                if mercenaryId[1] ~= nil then
                    for k, v in pairs(mercenaryId) do
                        local roleEquipMercenary = UserMercenaryManager:getEquipByPart(v, part);
                        if part ~= 10 and part ~= 8 and part ~= 9 and part ~= 3 then
                            local professionMercenary = EquipManager:isDressableWithProfession(userEquip.equipId, mercenaryProf[k])
                            if roleEquipMercenary == nil and professionMercenary == true then
                                canDress = true
                                break;
                            end
                            if roleEquipMercenary ~= nil then
                                local currentEquipMercenary = UserEquipManager:getUserEquipById(roleEquipMercenary.equipId);
                                local mercenaryDressOr = UserEquipManager:isPartNeedNotice(part, v)
                                if mercenaryDressOr == true and currentEquipMercenary.score < score and professionMercenary == true then
                                    canDress = true
                                    break;
                                end
                            end
                        end
                    end
                end

            end

            if hasEquip and hasHighLevelEquip then
                break
            end
        end
    end
    -- 没有可以融合的装备
    if not hasEquip then
        MessageBoxPage:Msg_Box_Lan("@BatchMeltNoEquip")
        return
    end

    -- 选中的武器中包含已出战的角色可使用的强力装备，要铸造吗？
    if canDress then
        local title = common:getLanguageString("@SmeltConfirm_Title");
        local msgDress = common:getLanguageString("@EquipRemainNotice");
        PageManager.showConfirm(title, msgDress, function(isOK)
            if isOK then
                EquipOprHelper:smeltEquip(nil, 1, qualitys)
                PageManager.popPage('DecisionPage');
            end
        end , false);
        return
    end

    -- 选择的装备中有与角色Lv相差Lv10的装备，要进行铸造吗？
    if hasHighLevelEquip then
        local title = common:getLanguageString("@SmeltConfirm_Title");
        local lvMsg = common:getLanguageString("@SmeltConfirm_LvMsg");
        PageManager.showConfirm(title, lvMsg, function(isOK)
            if isOK then
                EquipOprHelper:smeltEquip(nil, 1, qualitys)
                if #qualitys == 5 then
                    -- self:onClose(container)
                end
            end
        end , true);

        return
    end

    -- 分解裝備給一個確認視窗
    local title = common:getLanguageString("@SmeltConfirm_Title");
    local msg = common:getLanguageString("@EquipRemainNotice2");
    PageManager.showConfirm(title, msg, function(isOK)
        if isOK then
            EquipOprHelper:smeltEquip(nil, 1, qualitys);
            PageManager.popPage('DecisionPage');           
        end
    end , true);

    -- send packet
    --EquipOprHelper:smeltEquip(nil, 1, qualitys)
    --if #qualitys == 5 then
        ---- self:onClose(container)
    --end
end

function BatchMeltPageBase:onSelectedAll(container)


    if BatchMeltPageBase.SelectedMap.selectedWhite and BatchMeltPageBase.SelectedMap.selectedGreen and
        BatchMeltPageBase.SelectedMap.selectedBlue and BatchMeltPageBase.SelectedMap.selectedPurple and
        BatchMeltPageBase.SelectedMap.selectedOrange then

        BatchMeltPageBase.SelectedMap = {
            selectedWhite = false,
            selectedGreen = false,
            selectedBlue = false,
            selectedPurple = false,
            selectedOrange = false,
        }

    else
        BatchMeltPageBase.SelectedMap = {
            selectedWhite = true,
            selectedGreen = true,
            selectedBlue = true,
            selectedPurple = true,
            selectedOrange = true,
        }
    end
    self:refreshPage(container)
end

function BatchMeltPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function BatchMeltPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function BatchMeltPageBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            self:refreshPage(self.container)
        end
    end
end
-------------------------------------------------------------------------

function BatchMeltPageBase.onFunction(enentName, container)
    if enentName == "onWhiteEquipment" then
        BatchMeltPageBase:onWhite(container)
    elseif enentName == "onGreenEquipment" then
        BatchMeltPageBase:onGreen(container)
    elseif enentName == "onBlueEquipment" then
        BatchMeltPageBase:onBlue(container)
    elseif enentName == "onPurpleEquipment" then
        BatchMeltPageBase:onPurple(container)
    elseif enentName == "onOrangeEquipment" then
        BatchMeltPageBase:onOrange(container)
    elseif enentName == "onRedEquipment" then
        BatchMeltPageBase:onRed(container)
    elseif enentName == "onSelectAll" then
        BatchMeltPageBase:onSelectedAll(container)
    elseif enentName == "onConfirmation" then
        BatchMeltPageBase:onMelt(container)
    elseif enentName == "onClose" then
        BatchMeltPageBase:onClose(container)
    end
end

return BatchMeltPageBase
-- local CommonPage = require("CommonPage");
-- local BatchMeltPage = CommonPage.newSub(BatchMeltPageBase, thisPageName, option);