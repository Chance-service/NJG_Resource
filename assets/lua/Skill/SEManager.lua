
--技能专精管理器相关

local SEConfig = require("Skill.SEConfig")

local BaseDataHelper = require("BaseDataHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local SEManager = BaseDataHelper:new(SEConfig) 
SEManager.SELevel = {}
SEManager.HasOpen = {}
mSERedPoint = false
function SEManager:ResetData()
    self.HasOpen = {}
    self.SELevel = {}
end

function SEManager:getEnterData(msgBuffer,roleId)
    local UserInfo = require("PlayerInfo.UserInfo")
    UserInfo.syncRoleInfo()
    local ConfigManager = require("ConfigManager")
    local RoleId = roleId or UserInfo.roleInfo.itemId
    if not RoleId then return end;
    local roleCfg = ConfigManager.getRoleCfg()
    if not roleCfg[RoleId] then return end;
    local profession = roleCfg[RoleId]["profession"]

    if msgBuffer~=nil then
        local SkillEnhance_pb = require("SkillEnhance_pb")
        local msg = SkillEnhance_pb.HPSkillEnhanceOpenState()
        msg:ParseFromString(msgBuffer);

        self.HasOpen[profession] = msg.isOpen
    end

    if self.HasOpen[profession]~=nil then
        mSERedPoint = (not self.HasOpen[profession]) and UserInfo.roleInfo.level>=SEConfig.OpenLevel
        if mSERedPoint then
            PageManager.showRedNotice("Skill",true)
        else
            mSERedPoint = false
            local pageName = MainFrame:getInstance():getCurShowPageName();
            if pageName=="SkillPage" then
                PageManager.showRedNotice("Skill",false)
            end
        end
    else
        mSERedPoint = true
		PageManager.showRedNotice("Skill",true)
	end

    return self.HasOpen[profession]
end

function SEManager:EnterSEPage(roleId)
    local UserInfo = require("PlayerInfo.UserInfo")
    local ConfigManager = require("ConfigManager")
    local RoleId = roleId or UserInfo.roleInfo.itemId
    local roleCfg = ConfigManager.getRoleCfg()
    local profession = roleCfg[RoleId]["profession"]

    if UserInfo.roleInfo.level<SEConfig.OpenLevel then
        MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@SEOpenLevelLimit",SEConfig.OpenLevel));
        return
    end

    if self.HasOpen[profession] then
        require("SEMainPage")
        SEMainPage_ShowSEPageByProfession(profession)
    else
        require("SEEnterPage")
        SEEnterPage_showSEEnterByProfession(profession)
    end
end

function SEManager:getSECfgByProfession(profession)
    local SECfg = ConfigManager.getSkillOperCfg()
    local sortCfg = {}
    for i=1,#SECfg do
        local item = SECfg[i]
        if item~=nil and item.profession==profession then
            table.insert(sortCfg,item)
        end
    end
    table.sort(sortCfg,function(a,b) if a.id < b.id then return true end return false end)
    return sortCfg
end

function SEManager:getSEStaticSkillByProfession(profession)
    local cfg = ConfigManager.getStaticSkillCfg()
    for i=1,#cfg do
        if cfg[i].profession == profession then
            return cfg[i]
        end
    end
    return nil
end

function SEManager:getSkillCfgInfoByItemId(id,level)
    local SkillManager =  require("Skill.SkillManager")
    local level = level and level or SkillManager:getSkillLevelByItemId(id)
    if id~=0 then
        level = level~=0 and level or 1
    end
    local id = tonumber(string.format(tostring(id).."%0004d",level))
    local seCfg = ConfigManager.getSkillEnhanceCfg()
    local itemInfo = seCfg[id]
    return itemInfo
end

function SEManager:getOriginalLevelByItemId(id)
    local SkillManager =  require("Skill.SkillManager")
    local level = SkillManager:getSkillLevelByItemId(id)
    local tempLevel = self:getTempLevel( id )
    level = level - tempLevel
    if id~=0 then
        level = level~=0 and level or 1
    end
    return level
end

function SEManager:getSkillLevelInfoByItemId(id)
    local SkillManager =  require("Skill.SkillManager")
    return SkillManager:getSkillLevelByItemId(id)
end

function SEManager:getSkillExpByItemId(id)
    local SkillManager =  require("Skill.SkillManager")
    return SkillManager:getSkillExpByItemId(id)
end

function SEManager:getTempLevel( skillId )
    local UserEquipManager = require("Equip.UserEquipManager")
    local suitAttrs = UserEquipManager:getDressedSuitAttrs()
    local suitAttrsCfg = ConfigManager.getSuitAtrrCfg()
    local upLevel = 0
    for k,v in pairs( suitAttrs ) do
        attrsItemInfo = suitAttrsCfg[v]
        if attrsItemInfo.type == 2 and attrsItemInfo.upId == skillId then
            upLevel = upLevel + attrsItemInfo.bonuses
        end       
    end

    return upLevel
end

return SEManager
--endregion
