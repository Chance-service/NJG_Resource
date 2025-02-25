
----------------------------------------------------------------------------------
local HP_pb = require("HP_pb");
local RoleOpr_pb = require("RoleOpr_pb")
local EquipScriptData = require("EquipScriptData")
local thisPageName = "MercenarySkillPreviewPage"
local NodeHelper = require("NodeHelper");
local MercenarySkillPreviewPage = { }
local SkillManager = require("Skill.SkillManager")
local option = {
    ccbiFile = "MercenarySkillPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp"
    },
}
local _curMercenaryInfo = nil -- 当前佣兵信息
local skillContent = {
    -- 佣兵数据
    ccbiFile = "MercenarySkillContent.ccbi"
}

function skillContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    local index = self.id
    local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)
    local heroCfg = ConfigManager.getNewHeroCfg()
    local skillCfg = ConfigManager.getSkillCfg()
    local heroInfo = heroCfg[roleTable.sex * 100 + roleTable.class]
    local skillList = common:split((heroInfo.Skills), ",")
    local ringList = common:split((heroInfo.Passive), ",")
    local skillId = 1
    local SkillBaseNum=100000
    -- 技能名稱
    local skillName = container:getVarLabelTTF("mSkillName")
    if index == 1 or index == 2 then
        NodeHelper:setSpriteImage(container, { mSkillPic = "skill/S_" .. skillList[index] .. ".png" })
        skillId = skillList[index]
        skillName:setString(common:getLanguageString("@Skill_Name_" .. skillId))
        SkillBaseNum=100000
    elseif index == 3 then
        NodeHelper:setSpriteImage(container, { mSkillPic = "skill/S_" .. ringList[1] .. ".png" })
        skillId = ringList[1]
        skillName:setString(common:getLanguageString("@Passive_Name_" .. skillId))
        SkillBaseNum=100000
    elseif index == 4 then
        NodeHelper:setSpriteImage(container, { mSkillPic = "skill/R_" .. roleTable.race .. ".png" })
        skillId = roleTable.race
        skillName:setString(common:getLanguageString("@Race_Name_" .. skillId))
        SkillBaseNum=200000
    elseif index == 5 and roleTable.blood ~= GameConfig.MercenaryBloodId["COMMONER"] then
        NodeHelper:setSpriteImage(container, { mSkillPic = "skill/L_" .. roleTable.blood .. ".png" })
        skillId = roleTable.blood
        skillName:setString(common:getLanguageString("@Blood_Name_" .. skillId))
        SkillBaseNum=210000
    elseif index == 6 then
        NodeHelper:setSpriteImage(container, { mSkillPic = "skill/E_" .. roleTable.eyeL .. ".png" })
        skillId = roleTable.eyeL
        skillName:setString(common:getLanguageString("@Eye_Name_" .. skillId))
        SkillBaseNum=220000
    elseif index == 7 and roleTable.eyeL ~= roleTable.eyeR then
        NodeHelper:setSpriteImage(container, { mSkillPic = "skill/E_" .. roleTable.eyeR .. ".png" })
        skillId = roleTable.eyeR
        skillName:setString(common:getLanguageString("@Eye_Name_" .. skillId))
        SkillBaseNum=220000
    end
    -- 技能說明
    local skillDesNode = container:getVarNode("mSkillDesContent")
    skillDesNode:removeAllChildren()
    local str = common:getLanguageString("@Skill_Desc_" .. skillId)
    local htmlLabel = CCHTMLLabel:createWithString((FreeTypeConfig[SkillBaseNum + tonumber(skillId)] and FreeTypeConfig[SkillBaseNum + tonumber(skillId)].content or FreeTypeConfig[SkillBaseNum+1].content), CCSizeMake(420, 50), "Barlow-SemiBold")
    htmlLabel:setPosition(ccp(0, 0))
    htmlLabel:setAnchorPoint(ccp(0, 0.5))
    skillDesNode:addChild(htmlLabel)
    -- 技能消耗
    local skillCost = container:getVarLabelTTF("mSkillMpTxt")
    if skillCfg[tonumber(skillId)] and skillCfg[tonumber(skillId)].cost > 0 and index < 4 then
        skillCost:setString("MP " .. skillCfg[tonumber(skillId)].cost)
    else
        skillCost:setString("")
    end
end

function MercenarySkillPreviewPage:onEnter(container)
    container.mScrollView = container:getVarScrollView("mScrollView")
    --container:autoAdjustResizeScrollview(container.mScrollView)
    container.mScrollView:removeAllCell()
    self:onRefresh(container)
end
function MercenarySkillPreviewPage:onRefresh(container)
    self.mAllRoleItem = NodeHelper:buildCellScrollView(container.mScrollView, 7, "MercenarySkillContent.ccbi", skillContent)
    container.mScrollView:refreshAllCell()
    local roleTable = NodeHelper:getNewRoleTable(_curMercenaryInfo.itemId)

    if roleTable.blood == GameConfig.MercenaryBloodId["COMMONER"] then
        self.mAllRoleItem[5].node:setVisible(false)
        self.mAllRoleItem[5].node:setContentSize(CCSize(0, 0))
    end
    if roleTable.eyeL >= 20 then
        self.mAllRoleItem[6].node:setVisible(false)
        self.mAllRoleItem[6].node:setContentSize(CCSize(0, 0))
    end
    if roleTable.eyeR >= 20 or roleTable.eyeL == roleTable.eyeR  then
        self.mAllRoleItem[7].node:setVisible(false)
        self.mAllRoleItem[7].node:setContentSize(CCSize(0, 0))
    end
    container.mScrollView:orderCCBFileCells()
end

function MercenarySkillPreviewPage:onClose(container)
    PageManager.popPage(thisPageName);
end
function MercenarySkillPreviewPage:setMercenaryInfo(info)
    _curMercenaryInfo = info
end
function MercenarySkillPreviewPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARY_SKILL)
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
MercenarySkillPreviewPage = CommonPage.newSub(MercenarySkillPreviewPage, thisPageName, option)

return MercenarySkillPreviewPage