local GVGCityItem = {
    cityId = 0,
    node = nil,
    parentNode = nil,
    clicker = {},
    remainTime = 0
}
 
local NodeHelper = require("NodeHelper")
local GVGManager = require("GVGManager")
local GVG_pb = require("GroupVsFunction_pb")

local timerName = "GVGCityReAtkTime"

function GVGCityItem:create(cityId, parentNode)
    local cityItem = {}
    setmetatable(cityItem, self)
    self.__index = self

    cityItem.cityId = cityId
    cityItem.parentNode = parentNode
    cityItem:init()
    return cityItem
end

function GVGCityItem:init()
    local cfg = GVGManager.getCityCfg(self.cityId)
    
    local container = ScriptContentBase:create("GvGCity" .. (4 - cfg.level) .. ".ccbi")
    self.node = container

    self.parentNode:addChild(container)
    self:refresh() 
end

function GVGCityItem:refresh()
    local cfg = GVGManager.getCityCfg(self.cityId)
    local data = GVGManager.getCityInfo(self.cityId)

    local cityId = self.cityId

    local container = self.node
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local labelColorMap = {}

    local status = GVGManager.getGVGStatus()
    if cfg then
        lb2Str.mCityName = cfg.cityName
    end
    local isDeclared = false
    local isReAtkProtected = false
    
    local serverTimeTab = os.date("!*t", common:getServerTimeByUpdate() - common:getServerOffset_UTCTime())

    if GVGManager.getGVGStatus() == GVG_pb.GVG_STATUS_AWARD and (serverTimeTab.day == 14 or serverTimeTab.day == 29) then
       data = nil 
       visibleMap.mBattleNode = false
       visibleMap.mDefendNode = false
    end
    
    if data then
        if data.atkGuild and data.atkGuild.guildId > 0 and data.status ~= GVG_pb.CITY_STATUS_FORBIDDEN then
            visibleMap.mDefendNode = false
            visibleMap.mBattleNode = true
            if data.defGuild and data.defGuild.guildId > 0 then
                lb2Str.mDefendGuildName = data.defGuild.name
                local isSelfGuild = GVGManager.isSelfGuild(data.defGuild.guildId)
                if isSelfGuild then
                    visibleMap.mNameFrame2 = true
                    visibleMap.mMyNameFrame2 = false 
                else
                    visibleMap.mNameFrame2 = false
                    visibleMap.mMyNameFrame2 = true
                end
            else
                lb2Str.mDefendGuildName = common:getLanguageString("@GVGNpcName", cfg.cityName)
            end
            lb2Str.mAttGuildName = data.atkGuild.name
            local isSelfGuild = GVGManager.isSelfGuild(data.atkGuild.guildId)
            if isSelfGuild then
                visibleMap.mNameFrame1 = true
                visibleMap.mMyNameFrame1 = false
                visibleMap.m_LogoOwn = true
                visibleMap.m_LogoOther = false 
            else
                visibleMap.mNameFrame1 = false
                visibleMap.mMyNameFrame1 = true
                visibleMap.m_LogoOwn = false
                visibleMap.m_LogoOther = true 
            end
            isDeclared = true
            
            visibleMap.mFlagNode1 = false
            visibleMap.mFlagNode2 = false
            visibleMap.mFlagNode3 = false
            lb2Str.mFlagNum1 = ""
            lb2Str.mFlagNum2 = ""
            lb2Str.mFlagNum3 = ""
            if status == GVG_pb.GVG_STATUS_FIGHTING then
                local atk,def = GVGManager.getCityTeamNum(cityId)
                if atk > 0 or def > 0 then
                    visibleMap.mFlagNode1 = true
                    visibleMap.mFlagNode2 = true
                    lb2Str.mFlagNum1 = "×" .. atk
                    lb2Str.mFlagNum2 = "×" .. def
                end
            end

            visibleMap.mBattleBack = data.isReAtk
        else
            visibleMap.mBattleNode = false
            visibleMap.mFlagNode1 = false
            visibleMap.mFlagNode2 = false
            visibleMap.mFlagNode3 = false
            lb2Str.mFlagNum1 = ""
            lb2Str.mFlagNum2 = ""
            lb2Str.mFlagNum3 = ""
            if data.defGuild and data.defGuild.guildId > 0 then
                visibleMap.mDefendNode = true
                lb2Str.mGuildName = data.defGuild.name
                local isSelfGuild = GVGManager.isSelfGuild(data.defGuild.guildId)
                if isSelfGuild then
                    visibleMap.mOwnFrame = true
                    visibleMap.mOwnLogo = true
                    visibleMap.mOtherFrame = false
                    visibleMap.mOtherLogo = false
                else
                    visibleMap.mOwnFrame = false
                    visibleMap.mOwnLogo = false
                    visibleMap.mOtherFrame = true
                    visibleMap.mOtherLogo = true
                end
                if status == GVG_pb.GVG_STATUS_FIGHTING then
                    local atk,def = GVGManager.getCityTeamNum(cityId)
                    if def > 0 then
                        visibleMap.mFlagNode3 = true
                        lb2Str.mFlagNum3 = "×" .. def
                    end
                end
            else
                visibleMap.mDefendNode = false
            end
            visibleMap.mBattleBack = false
        end
        if data.status == GVG_pb.CITY_STATUS_REATTACK or data.status == GVG_pb.CITY_STATUS_DECLARED then
            if data.fightbackTime and data.fightbackTime > 0 then
                local sec = math.floor(data.fightbackTime / 1000)
                if self.remainTime == 0 or math.abs(self.remainTime - sec) > 1 then
                    lb2Str.mLockTime = common:getLanguageString("@GVGReAtkLockTime") .. common:second2DateString(sec, true)
                    TimeCalculator:getInstance():createTimeCalcultor(timerName .. cityId, sec);
                    --暂时注释掉反攻的显示
                    visibleMap.mLockTime = false
                    self.remainTime = sec
                end
                isReAtkProtected = true
            else
                if TimeCalculator:getInstance():hasKey(timerName .. cityId) then
                    TimeCalculator:getInstance():removeTimeCalcultor(timerName .. cityId)
                end
                visibleMap.mLockTime = false
            end
        else
            if TimeCalculator:getInstance():hasKey(timerName .. cityId) then
                TimeCalculator:getInstance():removeTimeCalcultor(timerName .. cityId)
            end 
            visibleMap.mLockTime = false
        end
    end
    if isDeclared and cfg.level ~= 0 then
        if status == GVG_pb.GVG_STATUS_FIGHTING then
            if isReAtkProtected then
                container:runAnimation("Account")
            else
                container:runAnimation("Battle")
            end
        else
            container:runAnimation("Account")
        end
    else
        container:runAnimation("Untitled Timeline")
    end

     --复活的处理
    if data  then 
     if cfg.level == 0 then 
           visibleMap.mBattleNode = false
            visibleMap.mFlagNode1 = false
            visibleMap.mFlagNode2 = false
            visibleMap.mFlagNode3 = false
            lb2Str.mFlagNum1 = ""
            lb2Str.mFlagNum2 = ""
            lb2Str.mFlagNum3 = ""
            if data.defGuild and data.defGuild.guildId > 0 then
                visibleMap.mDefendNode = true
                visibleMap.mBattleNode = false
                lb2Str.mGuildName = data.defGuild.name

                local isSelfGuild = GVGManager.isSelfGuild(data.defGuild.guildId)
                if isSelfGuild then
                    visibleMap.mOwnFrame = true
                    visibleMap.mOwnLogo = true
                    visibleMap.mOtherFrame = false
                    visibleMap.mOtherLogo = false
                else
                    visibleMap.mOwnFrame = false
                    visibleMap.mOwnLogo = false
                    visibleMap.mOtherFrame = true
                    visibleMap.mOtherLogo = true
                end
            else
                visibleMap.mDefendNode = false
            end
            visibleMap.mBattleBack = false
            container:runAnimation("Untitled Timeline")
     end
    end 


    NodeHelper:setColorForLabel(container,labelColorMap)
    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGCityItem:doTime()
    local container = self.node
    if TimeCalculator:getInstance():hasKey(timerName .. self.cityId) then
        local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName .. self.cityId)
		if remainTime > 0 then
			local timeStr = common:getLanguageString("@GVGReAtkLockTime") .. common:second2DateString(remainTime, true)
            NodeHelper:setStringForLabel(container, { mLockTime = timeStr})
            --暂时注释掉反攻的显示
            --NodeHelper:setNodesVisible(container, { mLockTime = true})
        else
            TimeCalculator:getInstance():removeTimeCalcultor(timerName .. self.cityId)
            NodeHelper:setNodesVisible(container, { mLockTime = false})
            self.remainTime = 0
            
            local data = GVGManager.getCityInfo(self.cityId)
            if data.status == GVG_pb.CITY_STATUS_DECLARED then
                GVGManager.isFromRankReqMap = false 
                GVGManager.reqMapInfo()
            end
		end
    end
end

function GVGCityItem:removeFromParentAndCleanup()
    if self.node then
        self.node:removeFromParentAndCleanup(true)
        self.node:release()
    end
end

function GVGCityItem:registerClick(callback)
    self.node:registerFunctionHandler(callback)
end

return GVGCityItem