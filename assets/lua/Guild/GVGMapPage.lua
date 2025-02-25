local thisPageName = "GVGMapPage"
local GVGManager = require("GVGManager")
local GVGCityMenu = require("GVGCityMenu")
local GVG_pb = require("GroupVsFunction_pb")
local GVGCityItem = require("GVGCityItem")
 
local GVGMapPageBase = {
    container = nil
}

local GVGMap = {
    ccbiFile = "GVGMapContent.ccbi",
    container = nil,
    citys = {}
}

local option = {
    ccbiFile = "GVGMapPage.ccbi",
    handlerMap = {
        onOwnerCity = "onOwnerCity",
        onTeamInfo = "onTeamInfo",
        onReturnBtn = "onReturnBtn",
        onDeclaredList = "onDeclaredList",
        onWorld = "onWorld",
        onHelp = "onHelp"
    },
    opcodes = {

    }
}

local MAP_WIDTH, MAP_HEIGHT = 4000,3000

local MAP_SCALE = 1

local isInAnimation = false
local broadCastTime = 0
local localServerTime = 0 
local isPushMathOverPage = false 
function GVGMap.init()
    
end

function GVGMap.onFunction(eventName, container)
    if GVGMap[eventName] and type(GVGMap[eventName]) == "function" then
        GVGMap[eventName](container)
    end
end

function GVGMap.onCityClick(eventName,container)
    if eventName ~= "onCity" then return end
    local cityItem
    for k,v in pairs(GVGMap.citys) do
        if v.node == container then
            cityItem = v
            break
        end
    end
    if not cityItem then return end
    if GVGManager.getCurCityId() == cityItem.cityId then
        GVGManager.setCurCityId(0)
        GVGCityMenu.hide()
    else
        local container = GVGMap.container
        local cfg = GVGManager.getCityCfg(cityItem.cityId)
        local city = container:getVarNode("mCityPosition" .. cfg.posId)
        local cityBase = city:getParent()
        local x,y = city:getPosition()
        local gPos = cityBase:convertToWorldSpace(ccp(x,y))
        GVGCityMenu:create(cityItem.cityId,city,gPos)
        GVGManager.setTargetCityId(cityItem.cityId)
    end
end

function GVGMapPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)

    local scrollview = container:getVarScrollView("mContent");
	if scrollview~= nil then
		container:autoAdjustResizeScrollview(scrollview);
	end
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
    local mScale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
	if mScale9Sprite2 ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite2 )
	end

    container.mScrollView = scrollview
    container.mScrollView:setBounceable(false)
    container.mScrollView:setContentSize(CCSizeMake(MAP_WIDTH * MAP_SCALE,MAP_HEIGHT * MAP_SCALE))
end

function GVGMapPageBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    GVGMapPageBase.container = container
    GVGManager.initCityConfig()
    --暂时注释掉
    --GVGManager:reqYesterdayVitalityRank()

    local mWaitSuplyTime = GVGManager.getWaitSuplyTime()

    local mWaitTime = tonumber(mWaitSuplyTime)
    mWaitTime = mWaitTime / 1000

    TimeCalculator:getInstance():createTimeCalcultor('mWaitSuplyTime', mWaitTime)


    GVGManager:reqVitalityRank()
    GVGManager.reqGuildInfo()
    NodeHelper:setNodesVisible(container,{mPrepareTip = false})
    NodeHelper:setNodesVisible(container,{mBattleTip = false})
    
    --SoundManager:getInstance():playMusic("GVG_Bg.mp3")
    self:initMap(container)
    self:initAllCity()
    if GVGManager.getMailTargetCity() > 0 then
        self:moveToCity(GVGManager.getMailTargetCity(), true)
        GVGManager.setMailTargetCity(0)
    else
        self:moveToCity(GVGManager.getCapitalId(), true)
    end
    broadCastTime = 0
    isInAnimation = false
    self:broadcastMessage(container)
    if GVGManager.getIsFromRank() then
        GVGManager.setIsFromRank(false)
        self:onWorld(container)
    end
    --GVGManager.reqSyncTeamNum()
    self:refreshPage(container)
    local ActionLog_pb = require("ActionLog_pb")
    local HP_pb = require("HP_pb")
    local Const_pb = require("Const_pb");
    local message = ActionLog_pb.HPActionRecord()
	if message~=nil then
		message.activityId = Const_pb.MODULE_GVG;
        message.actionType = Const_pb.GVG_ENTER;
		local pb_data = message:SerializeToString();
		PacketManager:getInstance():sendPakcet(HP_pb.ACTION_INTO_RECORD_C,pb_data,#pb_data,false);
    end

    local bg = container:getVarScale9Sprite("mScale9Bg")
    NodeHelper:autoAdjustResizeScale9Sprite(bg)
end


function GVGMapPageBase:refreshTime(container)

    --local remainTime = math.floor(refusedJoinTime / 1000) - serverTime
    --local localSeverTime =  GamePrecedure:getInstance():getServerTime()
    --local dt = GamePrecedure:getInstance():getFrameTime() * 1000;
    --if localSeverTime then
        --localSeverTime = localSeverTime + dt / 1000
    --end

     local isVisible,str = true,""
     local gvgStatus = GVGManager.getGVGStatus()

     if GVGManager.isGVGOpen and gvgStatus == GVG_pb.GVG_STATUS_WAITING then --筹划阶段还没开战
        if TimeCalculator:getInstance():hasKey('mWaitSuplyTime') then 
            NodeHelper:setNodesVisible(container,{mScaleNormal = true ,mScaleSpecial = false,mBattleTimes1 = false })
            local countDown = TimeCalculator:getInstance():getTimeLeft('mWaitSuplyTime')
            if countDown > 0 then
                str =  common:getLanguageString("@GVGWaitDeclareCd", GameMaths:formatSecondsToTime(countDown))
            else
             -- 倒计时结束
                TimeCalculator:getInstance():removeTimeCalcultor('mWaitSuplyTime')
            end
        else 
             isVisible = false 
        end
--        local nowDay = serverTimeTab.day
--        local nowMonth = serverTimeTab.month
--        local declareStartTime = 0 
--        --每月30日  1日  15日 16日
--        if nowDay == 30 or nowDay == 1 or nowDay == 15 or nowDay == 16 then
--           declareStartTime  = (24 +  8) * 3600  * 1000 
--           --31日的月份
--           if nowMonth == 1 or nowMonth == 3 or nowMonth == 5 or nowMonth == 7 or nowMonth == 8 or  nowMonth == 10 or nowMonth  == 12 then
--               declareStartTime  = (24 + 24 + 8) * 3600 * 1000
--           end
--        end
--        declareStartTime = declareStartTime / 1000
--        local leftTime = declareStartTime - serverTime
--        local hour = math.ceil(leftTime/3600) - 1 ;
--	    local minute = math.ceil((leftTime/60)%60) - 1 ;
--        if math.ceil((leftTime/60)%60) == 0  then
--              minute = 0 
--        end
--	    local second = math.ceil(leftTime%60);
--        --GameMaths:formatSecondsToTime(leftTime)
--        str = common:getLanguageString("@GVGWaitDeclareCd3", hour,minute,second)
--        NodeHelper:setNodesVisible(container,{mPrepareTip = true})
--        NodeHelper:setStringForLabel(container,{mPrepareTimes = str})
     elseif not GVGManager.isGVGOpen then 
         isVisible  = false 
     else
        if not localSeverTime then
           NodeHelper:setNodesVisible(container,{mBattleTip = false})
           return
        end
        local serverTimeTab = os.date("!*t", localSeverTime - ServerOffset_UTCTime)
        local serverTime = serverTimeTab.hour*3600 + serverTimeTab.min*60+serverTimeTab.sec

        NodeHelper:setNodesVisible(container,{mScaleNormal = true ,mScaleSpecial = false,mBattleTimes1 = false })
        NodeHelper:setNodesVisible(container,{mPrepareTip = false})
        local _,fightStartTime = GVGManager.getFightingStartTime()
        fightStartTime = fightStartTime / 1000
        local _,fightEndTime = GVGManager.getFightingEndTime()
        fightEndTime = fightEndTime / 1000
        local _,declareStartTime = GVGManager.getDeclareStartTime()
        local _,declareEndTime = GVGManager.getDeclareEndTime()
        declareStartTime = declareStartTime / 1000
        declareEndTime = declareEndTime / 1000
        if serverTime >=fightStartTime and serverTime <= fightEndTime then
            local leftTime = fightEndTime - serverTime
            str = common:getLanguageString("@GVGWaitFightEndCd", GameMaths:formatSecondsToTime(leftTime))
        elseif (serverTime > fightEndTime or serverTime <= declareStartTime)then
            local leftTime = declareStartTime - serverTime
            if serverTime > fightEndTime then
                leftTime = leftTime + 24*3600
            end
            str = common:getLanguageString("@GVGWaitDeclareCd", GameMaths:formatSecondsToTime(leftTime))
            --if not isPushMathOverPage and  (serverTimeTab.day == 14 or serverTimeTab.day == 29)  then
            if serverTime > fightEndTime then
                if serverTimeTab.day == 14 or serverTimeTab.day == 29 then
                   if serverTime < fightEndTime + 30  then
                      str = common:getLanguageString("@GVGMatchOverTitle")
                   else
                       if not isPushMathOverPage  then  
                           isVisible = false 
                           PageManager.refreshPage("GVG", "onGVGStatus")
                           isPushMathOverPage  = true
                           PageManager.pushPage("GVGMatchOverPage")
                        end
                   end
                end
--                if not isPushMathOverPage and  (serverTimeTab.day == 14 or serverTimeTab.day == 29)  then
--                   isVisible = false 
--                   PageManager.refreshPage("GVG", "onGVGStatus")
--                   isPushMathOverPage  = true
--                   PageManager.pushPage("GVGMatchOverPage")
--               end
            end

        elseif gvgStatus == GVG_pb.GVG_STATUS_PREPARE then 
            local declareTimes = GVGManager.getDeclareTimes()
            isVisible = declareTimes ~= -1
            if  not  isVisible then 
                local leftTime =  declareEndTime  - serverTime
                str = common:getLanguageString("@GVGWaitDeclareEndCd", GameMaths:formatSecondsToTime(leftTime))
                isVisible = true 
            else
                local leftTime =  declareEndTime  - serverTime
                NodeHelper:setNodesVisible(container,{mScaleNormal = false ,mScaleSpecial = true,mBattleTimes1 = true })
                NodeHelper:setStringForLabel(container,{mBattleTimes1 = common:getLanguageString("@ServerGVGBattleTimesTxt", 2 - declareTimes)})
                str = common:getLanguageString("@GVGWaitDeclareEndCd", GameMaths:formatSecondsToTime(leftTime))
            end
        elseif serverTime > declareEndTime and  serverTime <  fightStartTime  then 
             local leftTime =  fightStartTime -  serverTime
             str = common:getLanguageString("@GVGWaitFightStartCd", GameMaths:formatSecondsToTime(leftTime))
        else
            isVisible = false 
        end
    end
    NodeHelper:setStringForLabel(container,{mBattleTimes = str})
    NodeHelper:setNodesVisible(container,{mBattleTip = isVisible})
end


function GVGMapPageBase:onExecute(container)  
    self:broadcastMessage(container)
    GVGMapPageBase:refreshTime(container)
    for i = 1, GVGManager.getCityNums() do
        if GVGMap.citys[i] then
            GVGMap.citys[i]:doTime()
        end
    end
end

function GVGMapPageBase:onExit(container)
    GVGCityMenu.dispose()
    GVGManager.isGVGPageOpen = false
    isPushMathOverPage = false
    for k,city in pairs(GVGMap.citys) do
        city:removeFromParentAndCleanup()
    end
    GVGMap.citys = {}
    if not GVGManager.getIsFromRank() then
        GVGManager.clearAllData()
    end
    GVGMap.container:removeFromParentAndCleanup(true)
    GVGMap.container:release()
    GVGMap.container = nil

    GameUtil:purgeCachedData()
end

function GVGMapPageBase:initAllCity()
    local container = GVGMap.container
    for i = 1, GVGManager.getCityNums() do
        local cfg = GVGManager.getCityCfg(i)
        local baseNode = container:getVarNode("mCityPosition" .. cfg.posId)
        self:initCity(baseNode, i)
    end
end

function GVGMapPageBase:initCity(base, cityId)
    if GVGMap.citys[cityId] then
        GVGMap.citys[cityId]:refresh()
    else
        local city = GVGCityItem:create(cityId, base)
        city:registerClick(GVGMap.onCityClick)
        GVGMap.citys[cityId] = city
    end
end

function GVGMapPageBase:moveToCity(cityId, noAnimated)
    local container = GVGMap.container
    if not container then return end
    cityId = cityId or GVGManager:getTargetCityId()
    local cfg = GVGManager.getCityCfg(cityId)
    local cityNode = container:getVarNode("mCityPosition" .. cfg.posId)
    local scrollView = GVGMapPageBase.container.mScrollView
    local x,y = cityNode:getPosition()
    local nowOffset = scrollView:getContentOffset()
    local minOffSet = scrollView:minContainerOffset()
    local targetNode = cityNode:getParent()

    local rulerNode = GVGMapPageBase.container:getVarNode("mCityBtn")
    local rulerSize = rulerNode:getContentSize()
    local rulerPos = ccp(rulerSize.width/2, rulerSize.height/2)
    
    local targetPos = targetNode:convertToNodeSpace(rulerNode:convertToWorldSpace(rulerPos))
    local dx = targetPos.x - x
    local dy = targetPos.y - y
    local offsetX = math.min(0,math.max(minOffSet.x,nowOffset.x + dx))
    local offsetY = math.min(0,math.max(minOffSet.y,nowOffset.y + dy))
    if noAnimated then
        scrollView:setContentOffset(ccp(offsetX,offsetY))
    else
        scrollView:setContentOffsetInDuration(ccp(offsetX,offsetY),0.2)
    end
end

function GVGMapPageBase:resetCity(container, data)

end

function GVGMapPageBase:initMap(container)
    --container.mScrollView:removeAllCell()
    GVGMap.init()
    --CCTexture2D:setDefaultAlphaPixelFormat(9);
    local titleCell = ScriptContentBase:create(GVGMap.ccbiFile)
    titleCell:registerFunctionHandler(GVGMap.onFunction)
    titleCell:setScale(MAP_SCALE)
    container.mScrollView:addChild(titleCell)
    --container.mScrollView:registerScriptHandler(GVGMapPageBase,2)
    GVGMap.container = titleCell

    --kCCTexture2DPixelFormat_RGBA8888  0
    --kCCTexture2DPixelFormat_A8  3
    --kCCTexture2DPixelFormat_RGBA4444   6
    local sprite2Img = {}
    for i = 1 , 4 do
      sprite2Img['mBgSprite'..i] = 'UI/Common/BGNew/Bg_GVGMap'..i..'.png'
    end
    NodeHelper:setSpriteImage(GVGMap.container,sprite2Img)
    --CCLuaLog('format------'..CCTexture2D:defaultAlphaPixelFormat())
    --CCTextureCache:sharedTextureCache():dumpCachedTextureInfo();


    --CCTexture2D:setDefaultAlphaPixelFormat(0);

    --container.mScrollView:orderCCBFileCells()
end

function GVGMapPageBase:refreshPage(container)
    local noticeNum = GVGManager.getAllCityBattleNoticeNum()
    local lb2Str = {}
    local visibleMap = {}
    if noticeNum > 0 then
        visibleMap.mPointNode = true
        lb2Str.mPointNum = noticeNum
    else
        visibleMap.mPointNode = false
    end
    GVGMapPageBase:refreshTime(container)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setNodesVisible(container,visibleMap)
end

function GVGMapPageBase.scrollViewDidDeaccelerateStop(base, scrollView)
    print()
end

function GVGMapPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGMapPageBase:onTeamInfo(container)
    PageManager.pushPage("GVGMercenaryInfoPage")
end
function GVGMapPageBase:onDeclaredList(container)
    PageManager.pushPage("GVGDeclaredCityListPage")
end
function GVGMapPageBase:onOwnerCity(container)
    PageManager.pushPage("GVGCityListPage")
end

function GVGMapPageBase:onWorld(container)
    PageManager.pushPage("GVGAllInfoPage")
end

function GVGMapPageBase:onReturnBtn(container)
    local pageName = GVGManager.getFromPage() or 'GuildPage'
    GVGManager.setFromPage(nil)
    GVGManager.isGVGPageOpen = false
	PageManager.changePage(pageName)
end

function GVGMapPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_GVG)
end

--继承此类的活动如果同时开，消息监听不能同时存在,通过tag来区分
function GVGMapPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onMapInfo then
                self:initAllCity()
            elseif extraParam == GVGManager.onGotoCity then
                self:moveToCity()
            elseif extraParam == GVGManager.onCityChange then
                self:initAllCity()
            elseif extraParam == GVGManager.onGVGStatus then
                self:initAllCity()
            elseif extraParam == GVGManager.onTeamNumChange then
                self:initAllCity()
            elseif extraParam == GVGManager.onCityBattleNotice then
                self:refreshPage(container)
            end
        end
	end
end

function GVGMapPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGMapPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function GVGMapPageBase:broadcastMessage(container)
	local dt = GamePrecedure:getInstance():getFrameTime() * 1000;
	broadCastTime = broadCastTime + dt;
	if Golb_Platform_Info.is_entermate_platform then
		GameConfig.BroadcastLastTime = 10000	--韩国版的广播显示时长调整为10秒
	end
	if broadCastTime > GameConfig.BroadcastLastTime then
		isInAnimation = false
        broadCastTime = 0
		local castNode = container:getVarNode("mNoticeNode")
		castNode:removeAllChildren()
	end
	--local PackageLogicForLua = require("PackageLogicForLua")
	local size = #worldBroadCastList
	if size > 0 then
		if  isInAnimation == false then
			--get the first msg and remove
			local oneMsg = table.remove(worldBroadCastList,1)
			local castNode = container:getVarNode("mNoticeNode")
			if castNode~=nil then
				castNode:setVisible(true)
				castNode:removeAllChildren()
				local castCCB = ScriptContentBase:create("NoticeItem.ccbi");
                if string.find(oneMsg.chatMsg, "@declareBattle") and not string.find(oneMsg.chatMsg, "@declareBattleNpc") then
                    local json = require("json")
                    local msg = json.decode(oneMsg.chatMsg)
                    local GVGManager = require("GVGManager")
                    GVGManager.initCityConfig()
                    local cityCfg = GVGManager.getCityCfg(msg.data[3])
                    local str = common:getLanguageString(msg.key, msg.data[1],msg.data[2],cityCfg.cityName)

                    local msgLabel = castCCB:getVarLabelTTF("mNoticeTex")
                    msgLabel:setVisible(true)
                    castCCB:getVarLabelTTF("mWingTex"):setVisible(false)
				    msgLabel:setString(str);
                    castCCB:runAnimation("Notice");
                elseif string.find(oneMsg.chatMsg, "@declareBattleNpc") then
                    local json = require("json")
                    local msg = json.decode(oneMsg.chatMsg)
                    local GVGManager = require("GVGManager")
                    GVGManager.initCityConfig()
                    local cityCfg = GVGManager.getCityCfg(msg.data[2])
                    local str = ""
                    if  cityCfg.level ==  0  then 
                        str = common:getLanguageString("@GVGRevive", msg.data[1],cityCfg.cityName)
                    else 
                        str = common:getLanguageString(msg.key, msg.data[1],cityCfg.cityName)
                    end

                    local msgLabel = castCCB:getVarLabelTTF("mNoticeTex")
                    msgLabel:setVisible(true)
                    castCCB:getVarLabelTTF("mWingTex"):setVisible(false)
				    msgLabel:setString(str);
                    castCCB:runAnimation("Notice");
                elseif string.find(oneMsg.chatMsg, "@declareFightback") then
                    local json = require("json")
                    local msg = json.decode(oneMsg.chatMsg)
                    local GVGManager = require("GVGManager")
                    GVGManager.initCityConfig()
                    local cityCfg = GVGManager.getCityCfg(msg.data[3])
                    local str = common:getLanguageString(msg.key, msg.data[1],msg.data[2],cityCfg.cityName)

                    local msgLabel = castCCB:getVarLabelTTF("mNoticeTex")
                    msgLabel:setVisible(true)
                    castCCB:getVarLabelTTF("mWingTex"):setVisible(false)
				    msgLabel:setString(str);
                    castCCB:runAnimation("Notice");
                elseif string.find(oneMsg.chatMsg, "@attackerWin") then
                    local json = require("json")
                    local msg = json.decode(oneMsg.chatMsg)
                    local GVGManager = require("GVGManager")
                    GVGManager.initCityConfig()
                    local cityCfg = GVGManager.getCityCfg(msg.data[3])
                    local str = common:getLanguageString(msg.key, msg.data[1],msg.data[2],cityCfg.cityName)

                    local msgLabel = castCCB:getVarLabelTTF("mNoticeTex")
                    msgLabel:setVisible(true)
                    castCCB:getVarLabelTTF("mWingTex"):setVisible(false)
				    msgLabel:setString(str);
                    castCCB:runAnimation("Notice");
                elseif string.find(oneMsg.chatMsg, "@defenderWin") then
                    local json = require("json")
                    local msg = json.decode(oneMsg.chatMsg)
                    local GVGManager = require("GVGManager")
                    GVGManager.initCityConfig()
                    local cityCfg = GVGManager.getCityCfg(msg.data[3])
                    local str = common:getLanguageString(msg.key, msg.data[1],msg.data[2],cityCfg.cityName)

                    local msgLabel = castCCB:getVarLabelTTF("mNoticeTex")
                    msgLabel:setVisible(true)
                    castCCB:getVarLabelTTF("mWingTex"):setVisible(false)
				    msgLabel:setString(str);
                    castCCB:runAnimation("Notice");
                elseif string.find(oneMsg.chatMsg, "@fightbackWin") then
                    local json = require("json")
                    local msg = json.decode(oneMsg.chatMsg)
                    local GVGManager = require("GVGManager")
                    GVGManager.initCityConfig()
                    local cityCfg = GVGManager.getCityCfg(msg.data[3])
                    local str = common:getLanguageString(msg.key, msg.data[1],msg.data[2],cityCfg.cityName)

                    local msgLabel = castCCB:getVarLabelTTF("mNoticeTex")
                    msgLabel:setVisible(true)
                    castCCB:getVarLabelTTF("mWingTex"):setVisible(false)
				    msgLabel:setString(str);
                    castCCB:runAnimation("Notice");
                elseif string.find(oneMsg.chatMsg, "@fightbackFail") then
                    local json = require("json")
                    local msg = json.decode(oneMsg.chatMsg)
                    local GVGManager = require("GVGManager")
                    GVGManager.initCityConfig()
                    local cityCfg = GVGManager.getCityCfg(msg.data[3])
                    local str = common:getLanguageString(msg.key, msg.data[1],msg.data[2],cityCfg.cityName)

                    local msgLabel = castCCB:getVarLabelTTF("mNoticeTex")
                    msgLabel:setVisible(true)
                    castCCB:getVarLabelTTF("mWingTex"):setVisible(false)
				    msgLabel:setString(str);
                    castCCB:runAnimation("Notice");
                end
				castNode:addChild(castCCB)
                castCCB:setAnchorPoint(ccp(0.5,0.5))
				castCCB:release();

                local layer = castCCB:getVarNode("mLayerColor")
                layer:setContentSize(CCSizeMake(590,40))
                local msgLabel = castCCB:getVarLabelTTF("mNoticeTex")
                msgLabel:setFontSize(18)

				isInAnimation = true
			end
			broadCastTime = 0
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGMapPage = CommonPage.newSub(GVGMapPageBase, thisPageName, option);