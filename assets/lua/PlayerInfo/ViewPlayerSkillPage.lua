
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'ViewPlayerLeadPage'
local Activity_pb = require("Activity_pb");
local EquipScriptData = require("EquipScriptData")
local HP_pb = require("HP_pb");
local Const_pb = require("Const_pb")
local PBHelper = require("PBHelper");
local ItemManager = require("Item.ItemManager");
local thisPageName = "ViewPlayerSkillPage"

----这里是协议的id
local opcodes = {
    -- EQUIP_RESONANCE_INFO_C = HP_pb.EQUIP_RESONANCE_INFO_C,
    -- HEAD_FRAME_STATE_INFO_S = HP_pb.HEAD_FRAME_STATE_INFO_S
}

local option = {
    ccbiFile = "SkillLookOverOtherPopUp.ccbi",
    handlerMap = { --按钮点击事件
        onClose     = "onClose",
    },
    opcode = opcodes
}

local ViewPlayerSkillPageBase = {}
function ViewPlayerSkillPageBase:onEnter(container)
    self:registerPacket(container)
    self:showSkillInfo(container)
end

function ViewPlayerSkillPageBase:showSkillInfo(container)
    local SkillManager = require("Skill.SkillManager")
    local skillCfg = ConfigManager.getSkillEnhanceCfg();
    local skillOpenCfg = ConfigManager.getSkillOpenCfg()
    local showSkills = ViewPlayerInfo:getSKillInfo()--SkillManager:getArenaSkillList()
    local skillSize = #showSkills
    local SkillPic = ""

    local isHaveSkill = false
    for i=1, 5 do
        local itemNode = container:getVarNode("mPassiveSkill"..tonumber(i))
        if i<= skillSize then -- 已经开启的Skill1
            local skillItemId = showSkills[i].itemId--SkillManager:getSkillItemIdUsingId(showSkills[i])
            local level = showSkills[i].level--SkillManager:getSkillLevelUsingId(showSkills[i])
            if skillItemId~=0 then
                level = level~=0 and level or 1
            end
            skillItemId = tonumber(string.format(tostring(skillItemId).."%0004d",level))
            if skillItemId > 0 and skillCfg[skillItemId] then
                isHaveSkill = true
                itemNode:setVisible(true)
                local describe = skillCfg[skillItemId]["describe"]
                describe = GameMaths:replaceStringWithCharacterAll(describe,"#v1#",skillCfg[skillItemId].param1)
                describe = GameMaths:replaceStringWithCharacterAll(describe,"#v2#",skillCfg[skillItemId].param2)
                describe = GameMaths:replaceStringWithCharacterAll(describe,"#v3#",skillCfg[skillItemId].param3)
                local newStr =GameMaths:stringAutoReturnForLua(describe, 21, 0)

                NodeHelper:setSpriteImage(container, {["mSkillPic"..i] = skillCfg[skillItemId]["icon"]});
                NodeHelper:setStringForLabel(container, {["mSkillLv"..i] = common:getLanguageString("@LevelStr", level), ["mSkillName"..i] = skillCfg[skillItemId]["name"], ["mSkillTex"..i] = newStr, ["mConsumptionMp"..i] = skillCfg[skillItemId]["costMP"]})
            else
                itemNode:setVisible(false)
                SkillPic = GameConfig.SkillStatus.EMPTY_SKILL
            end
        else --未开启的技能
            SkillPic = GameConfig.SkillStatus.LOCK_SKILL
            itemNode:setVisible(false)
        end
       
    end

    NodeHelper:setNodesVisible(container, {mSkillEmptyTxt = true})
    if isHaveSkill then 
        NodeHelper:setNodesVisible(container, {mSkillEmptyTxt = false})
    end
end

function ViewPlayerSkillPageBase:onExecute(container)

end

function ViewPlayerSkillPageBase:onExit(container)
    self:removePacket(container)
end

function ViewPlayerSkillPageBase:onClose(container)
    PageManager.popPage(thisPageName)
    --PageManager.changePage("MainScenePage") 
    --PageManager.pushPage("PlayerInfoPage")
end

function ViewPlayerSkillPageBase:onReceivePacket(container)
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

function ViewPlayerSkillPageBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then --这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;

        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then

        end
    end
end

function ViewPlayerSkillPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ViewPlayerSkillPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

local CommonPage = require('CommonPage')
local ViewPlayerSkillPage= CommonPage.newSub(ViewPlayerSkillPageBase, thisPageName, option)