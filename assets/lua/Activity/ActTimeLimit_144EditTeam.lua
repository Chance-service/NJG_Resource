local thisPageName = "ActTimeLimit_144EditTeam" --"ActTimeLimit_144 Edit Team"
local NodeHelper = require("NodeHelper")
local ConfigManager = require("ConfigManager")
local UserMercenaryManager = require("UserMercenaryManager")

local ActTimeLimit_144EditTeam = {
    container = nil
}

local option = {
    ccbiFile = "Act_TimeLimit_144EditMercenaryTeamPage.ccbi",
    handlerMap = {
        onClose = "onClose",
        onHelp = "onRule",
        onApply = "onApply",
    },
}

local roleCfg = ConfigManager:getRoleCfg()
local ltRoleCfg = ConfigManager:getLTRoleCfg()

local selectNode = { teamNode = nil, allNode = nil }
local teamNode = { [1] = nil, [2] = nil, [3] = nil }
local shadeNode = { [1] = nil, [2] = nil, [3] = nil }

local teamIds = {}
----------------------------------------------------------------------------------
--��������Y��
----------------------------------------------------------------------------------
local teamContent = {
    ccbiFile = "Act_TimeLimit_144_eff_choseframe.ccbi",
}

function teamContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function teamContent:onTouchRole()
    if selectNode.allNode then  --�w��ܥ�����->��s����ܪ�����
        self:setNewRole(selectNode.allNode.roleId)
        if shadeNode[self.index] then
            shadeNode[self.index]:cancelSelect()
        end
        shadeNode[self.index] = selectNode.allNode
        selectNode.allNode:cancelSelect()
    elseif selectNode.teamNode then --�w��ܶ����
        if selectNode.teamNode.index ~= self.index then --index���P
            if selectNode.teamNode.roleId == 0 and self.roleId == 0 then    --���S������->�������
                self:newSelect()
                selectNode.teamNode:cancelSelect()
            else    --������->������m
                local tempId = self.roleId
                self:setNewRole(selectNode.teamNode.roleId)
                selectNode.teamNode:setNewRole(tempId)
            end
        else    --index�ۦP->�������
            self:cancelSelect()
        end
    else    --��������
        self:newSelect()
    end
end

function teamContent:newSelect()
    if self.roleId > 0 then --�w������->��Pink, �S����->��Silver
        self.container:runAnimation("Pink")
    else
        self.container:runAnimation("Silver")
    end
    selectNode.teamNode = self
    self.isSelected = true
end

function teamContent:setNewRole(id)
    self.roleId = id
    self:refreshRoleInfo()
    self:cancelSelect()
end

function teamContent:cancelSelect()
    if self.roleId > 0 then
        self.container:runAnimation("Default2")
    else
        self.container:runAnimation("Default")
    end
    if self.isSelected then
        selectNode.teamNode = nil
        self.isSelected = false
    end
end

function teamContent:onRefreshContent(ccbRoot)
    if self.isInit then
        self.container = ccbRoot:getCCBFileNode()
        if self.roleId > 0 then
            self.container:runAnimation("Default2")
        else
            self.container:runAnimation("Default")
        end
        self.isSelected = false
        self.isInit = false
        teamNode[self.index] = self
    end
    self:refreshRoleInfo()
end

function teamContent:refreshRoleInfo()
    local cfg = roleCfg[self.roleId]
    local ltCfg = ltRoleCfg[self.roleId]
    if cfg and ltCfg then
        NodeHelper:setStringForLabel(self.container, { mRoleHp = ltCfg.HP })
        NodeHelper:setStringForLabel(self.container, { mRoleAtk = ltCfg.ATK })
        NodeHelper:setStringForLabel(self.container, { mRoleSpd = ltCfg.Speed })
        --��s�Y��
        NodeHelper:setSpriteImage(self.container, { mRoleHead = cfg.banshenxiang })
        NodeHelper:setSpriteImage(self.container, { mRoleType = "Activity_144_job_" .. ltCfg.Type .. ".png" })
        --��s�ޯ�T��
        NodeHelper:setSpriteImage(ActTimeLimit_144EditTeam.container, { ["mSkillImg" .. self.index] = "Activity_144_job_" .. ltCfg.Type .. ".png" })
        NodeHelper:setStringForLabel(ActTimeLimit_144EditTeam.container, { ["mSkillTxt" .. self.index] = "@Role_" .. self.roleId .. "_Skill" })
    else
        NodeHelper:setStringForLabel(self.container, { mRoleHp = 0 })
        NodeHelper:setStringForLabel(self.container, { mRoleAtk = 0 })
        NodeHelper:setStringForLabel(self.container, { mRoleSpd = 0 })
        --��s�Y��
        NodeHelper:setSpriteImage(self.container, { mRoleHead = "UI/Mask/Image_Empty.png" })
        NodeHelper:setSpriteImage(self.container, { mRoleType = "UI/Mask/Image_Empty.png" })
        --��s�ޯ�T��
        NodeHelper:setSpriteImage(ActTimeLimit_144EditTeam.container, { ["mSkillImg" .. self.index] = "UI/Mask/Image_Empty.png" })
        NodeHelper:setStringForLabel(ActTimeLimit_144EditTeam.container, { ["mSkillTxt" .. self.index] = "" })
    end
end
----------------------------------------------------------------------------------
--���������Y��
----------------------------------------------------------------------------------
local allRoleContent = {
    ccbiFile = "Act_TimeLimit_144FormationTeamContent.ccbi",
}

function allRoleContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function allRoleContent:onTouchRole()
    local isSame, sameIndex = self:isInTeam()
    if selectNode.teamNode then --�w��������
        if selectNode.teamNode.roleId == self.roleId then   --�������ۦP->�������
            selectNode.teamNode:cancelSelect()
            self:cancelSelect()
        else
            local isSame, sameIndex = self:isInTeam()
            if isSame then  --��L����⦳�ۦPid->����⤬����m
                local tempId = selectNode.teamNode.roleId
                selectNode.teamNode:setNewRole(teamNode[sameIndex].roleId)
                teamNode[sameIndex]:setNewRole(tempId)
            else    --����S���ۦPid->��s�����T
                local selIdx = selectNode.teamNode.index
                selectNode.teamNode:setNewRole(self.roleId)
                if shadeNode[selIdx] then
                    shadeNode[selIdx]:cancelSelect()
                end
                shadeNode[selIdx] = self
                shadeNode[selIdx]:cancelSelect()
            end
        end
    elseif isSame then  --����w���Ө���->���X����
        teamNode[sameIndex]:setNewRole(0)
        self:cancelSelect()
        if selectNode.allNode then
            selectNode.allNode:cancelSelect()
        end
    elseif selectNode.allNode then --�w���������
        if selectNode.allNode.roleId ~= self.roleId then    --id���P->��s�������
            selectNode.allNode:cancelSelect()
            self:newSelect()
        else    --id�ۦP->�������
            self:cancelSelect()
        end
    else    --�S�����
        self:newSelect()
    end
end

function allRoleContent:isInTeam()
    local isSame = false
    local sameIndex = 0
    for i = 1, #teamNode do
        if teamNode[i].roleId == self.roleId then
            isSame = true
            sameIndex = i
        end
    end
    return isSame, sameIndex
end

function allRoleContent:newSelect()
    self.container:runAnimation("MercenaryChoose")
    selectNode.allNode = self
    self.isSelected = true
end

function allRoleContent:cancelSelect()
    if self.isSelected then
        self.container:runAnimation("ReincarnationStageAni")
        selectNode.allNode = nil
        self.isSelected = false
    end
    NodeHelper:setNodesVisible(self.container, { mChooseNode = self:isInTeam() })
end

function allRoleContent:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    if self.isInit then
        self.container:runAnimation("ReincarnationStageAni")
        self.isSelected = false

        self.isInit = false
    end
    local cfg = roleCfg[self.roleId]
    local ltCfg = ltRoleCfg[self.roleId]
    if cfg and ltCfg then
        NodeHelper:setSpriteImage(self.container, { mRoleHead = cfg.icon })
        NodeHelper:setStringForLabel(self.container, { mRoleName = cfg.name })
        NodeHelper:setSpriteImage(self.container, { mRoleFrame = GameConfig.MercenaryQualityImage[cfg.quality] })
        NodeHelper:setSpriteImage(self.container, { mRoleType = "Activity_144_job_" .. ltCfg.Type .. ".png" })
    end
    NodeHelper:setNodesVisible(self.container, { mRoleNum = false })
    if self.isSelected then
        self.container:runAnimation("MercenaryChoose")
    else
        self.container:runAnimation("ReincarnationStageAni")
    end
    local isSame, sameIndex = self:isInTeam()
    NodeHelper:setNodesVisible(self.container, { mChooseNode = isSame })
    if isSame then
        shadeNode[sameIndex] = self
    end
end
-------------------------------------�D�e��-------------------------------------------------
function ActTimeLimit_144EditTeam:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function ActTimeLimit_144EditTeam:onEnter(container)
    ActTimeLimit_144EditTeam.container = container
    self:initTeamRole(container)
    self:initAllRole(container)
end
--�ǤJ�s����T
function ActTimeLimit_144EditTeam:setTeamIds(ids)
    teamIds = {}
    for i = 1, 3 do
        table.insert(teamIds, ids[i])
    end
end
-------------------------------------���s---------------------------------------------
--����UI
function ActTimeLimit_144EditTeam:onClose(container)
    PageManager.popPage(thisPageName)
end
--�W�h����
function ActTimeLimit_144EditTeam:onRule(container)
    
end
--�s������
function ActTimeLimit_144EditTeam:onApply(container)
    local ids = {}
    for i = 1, 3 do
        table.insert(ids, teamNode[i].roleId)
    end
    local mainPage = require("ActTimeLimit_144LittleTest")
    mainPage:setPlayerInfo(ids)
    self:saveLocalTeamInfo(container)
    self:onClose(container)
end
----------------------------------------------------------------------------------
function ActTimeLimit_144EditTeam:initTeamRole(container)
    for i = 1, 3  do
        local scrollView = container:getVarScrollView("mRole" .. i)
        scrollView:removeAllCell()
        local titleCell = CCBFileCell:create()
        local panel = teamContent:new( { index = i, roleId = teamIds[i], isSelected = false, container = nil, isInit = true })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(teamContent.ccbiFile)
        scrollView:addCellBack(titleCell)
        scrollView:setTouchEnabled(false)
        scrollView:orderCCBFileCells()
    end
end

function ActTimeLimit_144EditTeam:initAllRole(container)
    local scrollView = container:getVarScrollView("mAllRole")
    scrollView:removeAllCell()
    roleInfos = self:getMercenaryInfos()
    for i = 1, #roleInfos do
        local titleCell = CCBFileCell:create()
        local panel = allRoleContent:new( { index = roleInfos[i].itemId, roleId = roleInfos[i].itemId, isSelected = false, container = nil, isInit = true })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(allRoleContent.ccbiFile)
        scrollView:addCellBack(titleCell)
    end
    scrollView:orderCCBFileCells()
end

function ActTimeLimit_144EditTeam:saveLocalTeamInfo(container)
    local ltInfoKey = "LT_TEAM_ID"
    local ltInfo = ""
    for i = 1, 3 do
        ltInfo = ltInfo .. teamNode[i].roleId
        if i ~= 3 then
            ltInfo = ltInfo .. "_"
        end
    end
    CCUserDefault:sharedUserDefault():setStringForKey(ltInfoKey, ltInfo)
end

function ActTimeLimit_144EditTeam:getMercenaryInfos()
    local infos = UserMercenaryManager:getMercenaryStatusInfos();
    local tblsort = { }
    local index = 1
    for k, v in pairs(infos) do
        if v.roleStage == 1 and not v.hide then
            table.insert(tblsort, v);
            index = index + 1
        end
    end

    if #tblsort > 0 then
        table.sort(tblsort,
        function(d1, d2)
            return d1.itemId < d2.itemId;
        end
        );
    end

    return tblsort
end

local CommonPage = require("CommonPage")
local ActPage = CommonPage.newSub(ActTimeLimit_144EditTeam, thisPageName, option)

return ActPage