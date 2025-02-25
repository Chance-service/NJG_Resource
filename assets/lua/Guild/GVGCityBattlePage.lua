local GVGManager = require("GVGManager")
local Battle_pb = require("Battle_pb")
local Const_pb = require("Const_pb")
local GVG_pb = require("GroupVsFunction_pb")
local thisPageName = "GVGCityBattlePage"
 
local GVGCityBattlePageBase = {
    showType = 2,
    leftTime = 0,
    timerName = "GVGCityBattlePage",
}

local option = {
    ccbiFile = "GVGBattleInfoPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onLookUpDefend = "onLookUpDefend",
        onLookUpAttack = "onLookUpAttack",
        onGoTo = "onGoTo",
        onCWin1 = "onContinue1",
        onCWin2 = "onContinue2"
    },
    opcodes = {
    }
}

local roleCfg = {}

local monsterCfg = {}

local cityData = {}

function GVGCityBattlePageBase:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local curBattle = GVGManager.getCurBattle()
    local curBattleInfo = GVGManager.getCurBattleInfo()
    local cityInfo = GVGManager.getCityInfo()
    cityData = cityInfo
    if curBattle then
        if curBattleInfo then
            lb2Str.mPlayerName1 = curBattle.attackerName
            lb2Str.mPlayerName2 = curBattle.defenderName

            local atk, def = GVGManager.getFirstRoleInfoByBattleData(curBattleInfo.battleData)
            if atk.itemId then
                visibleMap.mPic1 = true
                sprite2Img.mPic1 = roleCfg[atk.itemId].icon
                menu2Quality.mHand1 = roleCfg[atk.itemId].quality
            end
            if def.itemId then
                visibleMap.mPic2 = true
                if def.type == Const_pb.MONSTER then
                    sprite2Img.mPic2 = monsterCfg[def.itemId].icon
                    menu2Quality.mHand2 = 1
                elseif def.type == Const_pb.MERCENARY then
                    sprite2Img.mPic2 = roleCfg[def.itemId].icon
                    menu2Quality.mHand2 = roleCfg[def.itemId].quality
                end
            end
            
            visibleMap.mMidInfoNode = true
            visibleMap.mEmpty = false

            local lastRec = GVGManager.getLastLog()
            if lastRec.continueWin and lastRec.continueWin > 0 then
                if lastRec.isAtkWin == 1 then
                    visibleMap.mWinLast1 = true
                    visibleMap.mWinLast2 = false
                    lb2Str.mRewardComit1 = common:getLanguageString("@GVGBattleBuff",lastRec.continueWin)
                else
                    visibleMap.mWinLast1 = false
                    visibleMap.mWinLast2 = true
                    lb2Str.mRewardComit2 = common:getLanguageString("@GVGBattleBuff",lastRec.continueWin)
                end
            else
                visibleMap.mWinLast1 = false
                visibleMap.mWinLast2 = false 
                GameUtil:hideTip()
            end
        else
            visibleMap.mMidInfoNode = false
            visibleMap.mEmpty = true
            visibleMap.mWinLast1 = false
            visibleMap.mWinLast2 = false
            GameUtil:hideTip()
        end
    else
        visibleMap.mMidInfoNode = false
        visibleMap.mEmpty = true
        visibleMap.mWinLast1 = false
        visibleMap.mWinLast2 = false
        GameUtil:hideTip()
    end

    if cityInfo then
        local cfg = GVGManager.getCityCfg()
        if cityInfo.atkGuild and cityInfo.atkGuild.guildId > 0 then
            lb2Str.mCampName1 = cityInfo.atkGuild.name
        end

        if cityInfo.defGuild and cityInfo.defGuild.guildId > 0 then
            lb2Str.mCampName2 = cityInfo.defGuild.name
        else
            lb2Str.mCampName2 = common:getLanguageString("@GVGNpcName",cfg.cityName)
        end
        lb2Str.mTitle = common:getLanguageString("@GVGBattleInfoTitle",cfg.cityName)
    end
    local atk,def = GVGManager.getCityTeamNum()
    lb2Str.mAttackNum = atk
    lb2Str.mDefendNum = def

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)

    GVGCityBattlePageBase.leftTime = 31
    if GVGCityBattlePageBase.leftTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(GVGCityBattlePageBase.timerName, GVGCityBattlePageBase.leftTime);
    end
    GVGManager.clearCityBattleNotice()
end

function GVGCityBattlePageBase:onLookUpAttack(container)
    GVGManager.setShowType(GVGManager.SHOWTYPE_ATK)
    PageManager.pushPage("GVGTeamInfoPage")
end

function GVGCityBattlePageBase:onLookUpDefend(container)
    GVGManager.setShowType(GVGManager.SHOWTYPE_DEF)
    PageManager.pushPage("GVGTeamInfoPage")
end

function GVGCityBattlePageBase:onGoTo(container)
    local battleInfo = GVGManager.getCurBattleInfo()
    if battleInfo and battleInfo.battleType == Battle_pb.BATTLE_GVG_CITY then
        GVGManager.setIsWatchingGVG(true)
        local curBattle = GVGManager.getCurBattle()

        PageManager.viewBattlePage(battleInfo, curBattle.attackerName,curBattle.defenderName)
    end
end

function GVGCityBattlePageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGCityBattlePageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    roleCfg = ConfigManager.getRoleCfg()
    monsterCfg = ConfigManager.getMultiMonsterCfg()
    GVGManager.reqCityBattleInfo()
    GVGManager.clearCityBattleNotice()
end

function GVGCityBattlePageBase:onExecute(container)
    if TimeCalculator:getInstance():hasKey(GVGCityBattlePageBase.timerName) then
		local refreshTime = TimeCalculator:getInstance():getTimeLeft(GVGCityBattlePageBase.timerName)
        if refreshTime <= 0 then
            GVGCityBattlePageBase.leftTime = 31
            TimeCalculator:getInstance():createTimeCalcultor(GVGCityBattlePageBase.timerName, GVGCityBattlePageBase.leftTime);
            GVGManager.reqCityBattleInfo()
	    end
	end
end

function GVGCityBattlePageBase:onExit(container)
    GameUtil:hideTip()
    self:removePacket(container)
    GVGManager.setCurCityId(0)
    roleCfg = {}
    monsterCfg = {}
end

function GVGCityBattlePageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GVGCityBattlePageBase:onContinue1(container)
    local lastRec = GVGManager.getLastLog()
    if lastRec.continueWin and lastRec.continueWin > 0 then
        if lastRec.isAtkWin == 1 then
            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3201)
            local str = common:fill(freeTypeCfg.content,(lastRec.continueWin) or 0)
            GameUtil:showTipStr(container:getVarNode("mCampName1"), str)
        end
    end
end

function GVGCityBattlePageBase:onContinue2(container)
    local lastRec = GVGManager.getLastLog()
    if lastRec.continueWin and lastRec.continueWin > 0 then
        if lastRec.isAtkWin == 0 then
            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3201)
            local str = common:fill(freeTypeCfg.content,(lastRec.continueWin) or 0)
            GameUtil:showTipStr(container:getVarNode("mCampName2"), str)
        end
    end
end

function GVGCityBattlePageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGCityBattlePageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onBattleInfo then
                self:clearAndReBuildAllItem(container)
                self:refreshPage(container)
            elseif extraParam == GVGManager.onCityChange then
                local cityInfo = GVGManager.getCityInfo()
                if cityInfo.status ~= GVG_pb.CITY_STATUS_FIGHTING then
                    PageManager.popPage(thisPageName)
                end
            elseif extraParam == GVGManager.onTeamNumChange then
                local lb2Str = {}
                local atk,def = GVGManager.getCityTeamNum()
                lb2Str.mAttackNum = atk
                lb2Str.mDefendNum = def
                NodeHelper:setStringForLabel(container,lb2Str)
            end
        end
	end
end

function GVGCityBattlePageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local wordList = GVGManager.getCurBattleList()
    local currentPos = 0
	local size = #wordList
	for i = size, 1,-1 do
		local oneContent = wordList[i]
		if oneContent~=nil then
            local str  = oneContent.content
			local content = CCHTMLLabel:createWithString(str,CCSize(460,24),"Helvetica");
			content:setPosition(ccp(0,currentPos));
			content:setTag(i);
			currentPos = currentPos + content:getContentSize().height + GameConfig.FightLogSlotWidth;
			container.mScrollView:addChild(content)
		end
	end

	container.mScrollView:setContentSize(CCSize(460,currentPos));
	local viewHeight = container.mScrollView:getViewSize().height
	if currentPos< viewHeight then
		container.mScrollView:setContentOffset(ccp(0,viewHeight - currentPos));
	else
		container.mScrollView:setContentOffset(ccp(0,0));
	end
end

function GVGCityBattlePageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGCityBattlePageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGCityBattlePage = CommonPage.newSub(GVGCityBattlePageBase, thisPageName, option);