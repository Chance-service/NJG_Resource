local thisPageName = "NgBattleExpressPage"
local Battle_pb =  require("Battle_pb")
require("Util.RedPointManager")

NgBattleExpressPage = NgBattleExpressPage or { }
local option = {
    ccbiFile = "ExpressBattle.ccbi",
    handlerMap =
    {
        onExpress = "onExpress",
        onHelp = "onHelp",
        onClose = "onClose",
    },
    opcodes = {
        BUY_FAST_FIGHT_TIMES_C = HP_pb.BUY_FAST_FIGHT_TIMES_C,
        BUY_FAST_FIGHT_TIMES_S = HP_pb.BUY_FAST_FIGHT_TIMES_S,
        BATTLE_FAST_FIGHT_C = HP_pb.BATTLE_FAST_FIGHT_C,
        BATTLE_FAST_FIGHT_S = HP_pb.BATTLE_FAST_FIGHT_S,
    }
}
local PAGE_TYPE = {
    FREE = 1, BUY = 2, NONE = 3
}
local COST_ITEM_ID = 1002
local FREETYPE_STR_ID = 4004
local nowFreeTime = 0
local nowBuyTime = 0
local canBuyTime = 0
local vipLevel = 0
local buyCost = { }
local pageShowType = PAGE_TYPE.FREE

------------------------------------------------
function NgBattleExpressPage:onEnter(container)
    UserInfo.sync()
    container:registerMessage(MSG_REFRESH_REDPOINT)
    self:registerPacket(container)
    self:initData(container)
    --self:initUI(container)
    self:refreshUI(container)
    self:refreshAllPoint(container)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["NgBattleExpressPage"] = container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function NgBattleExpressPage:initData(container)
    local vipCfg = ConfigManager.getVipCfg()
    nowBuyTime = UserInfo.stateInfo.fastFightBuyTimes
    vipLevel = tonumber(UserInfo.playerInfo.vipLevel)
    canBuyTime = vipCfg[vipLevel]["fastFightTime"] - nowBuyTime
    buyCost = common:split(GameConfig.buyFastFightPrice, ",")
    local totalFreeTime = 0
    for i = 1, #buyCost do
        if tonumber(buyCost[i]) == 0 then
            totalFreeTime = totalFreeTime + 1
        else
            break
        end
    end
    nowFreeTime = totalFreeTime - nowBuyTime
end

function NgBattleExpressPage:initUI(container)
    local parentNode = container:getVarNode("mSpineNode")
    local spine = SpineContainer:create("Spine/NGUI", "NGUI_53_Gacha1Summon_BG")
    local spineNode = tolua.cast(spine, "CCNode")
    spineNode:setScale(NodeHelper:getScaleProportion())
    spine:runAnimation(1, "wait", -1)
    parentNode:addChild(spineNode)
    --
    self:refreshUI(container)
end
function NgBattleExpressPage:refreshUI(container)
    local buyCostIndex = math.min(nowBuyTime + 1, #buyCost)
    if canBuyTime > 0 and buyCost[buyCostIndex] and tonumber(buyCost[buyCostIndex]) == 0 then -- 還有免費次數
        pageShowType = PAGE_TYPE.FREE
        NodeHelper:setStringForLabel(container, { mTipTxt = common:getLanguageString("@ExBattleTip1", nowFreeTime) })
    elseif canBuyTime > 0 and buyCost[buyCostIndex] and tonumber(buyCost[buyCostIndex]) > 0 then -- 還有購買次數
        pageShowType = PAGE_TYPE.BUY
        NodeHelper:setStringForLabel(container, { mTipTxt = common:getLanguageString("@SilverMoonLimitTime", canBuyTime) })
    else    -- 不可購買不可使用
        pageShowType = PAGE_TYPE.NONE
        NodeHelper:setStringForLabel(container, { mTipTxt = common:getLanguageString("@SilverMoonLimitTime", 0) })
    end
    NodeHelper:setMenuItemEnabled(container, "mExpressBtn", (pageShowType ~= PAGE_TYPE.NONE))
end

function NgBattleExpressPage:onExpress(container)
    local buyCostIndex = math.min(nowBuyTime + 1, #buyCost)
    if pageShowType == PAGE_TYPE.FREE or pageShowType == PAGE_TYPE.BUY then
        local cfg = ConfigManager.getUserPropertyCfg()[COST_ITEM_ID]
        local str = common:getLanguageString("@ExBattleTip2", buyCost[buyCostIndex])
        PageManager.showNotice(common:getLanguageString("@buy"), str, function(isOk)
            if not isOk then
                return
            end
            if UserInfo.playerInfo.gold < tonumber(buyCost[buyCostIndex]) then
                -- 鑽石不足
                MessageBoxPage:Msg_Box_Lan("@GoldNotEnough")
                return
            end
            local msg = Battle_pb.HPBuyFastFightTimes()
		    if msg ~= nil then
		    	msg.times = 1
                common:sendPacket(HP_pb.BUY_FAST_FIGHT_TIMES_C, msg, true)
		    end
        end, true, true)
    end
    --if nowFreeTime > 0 then
    --    local msg = Battle_pb.HPFastBattle()
    --    if msg ~= nil then
    --        msg.mapId = UserInfo.stateInfo.curBattleMap
    --        msg.isNoob = false
    --        common:sendPacket(HP_pb.BATTLE_FAST_FIGHT_C, msg, true)
    --        --UserInfo.stateInfo.fastFightTimes = msg.fastFightTimes - 1
    --        --nowFreeTime = UserInfo.stateInfo.fastFightTimes
    --    end
    --elseif nowFreeTime <= 0 and canBuyTime > 0 then     -- 購買次數
    --  local msg = Battle_pb.HPBuyFastFightTimes()
	--	if msg ~= nil then
	--		msg.times = 1
    --        common:sendPacket(HP_pb.BUY_FAST_FIGHT_TIMES_C, msg, true)
	--	end
    --end
end

function NgBattleExpressPage:onClose(container)
    container:removeMessage(MSG_REFRESH_REDPOINT)
    self:removePacket(container)
    PageManager.popPage(thisPageName)
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        GuideManager.forceNextNewbieGuide()
    end
end

---------------------------------------------------------------------
function NgBattleExpressPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(container)
    end
end
-- 協定處理
function NgBattleExpressPage:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function NgBattleExpressPage:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function NgBattleExpressPage:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_FASTFIGHT)
end

function NgBattleExpressPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.BATTLE_FAST_FIGHT_S then
        local msg = Battle_pb.NewBattleAward()
        msg:ParseFromString(msgBuff)
        local item = {}
        local drop = msg.drop
        local exp = msg.exp
        local coin = msg.SkyCoin

        if #drop > 0 then
            for i = 1, #drop do
                table.insert(item, {
                        type    = tonumber(drop[i].itemType),
                        itemId  = tonumber(drop[i].itemId),
                        count   = tonumber(drop[i].itemCount),
                })
            end
        end
        if #item > 0 then
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            CommonRewardPage:setData(item, common:getLanguageString("@ItemObtainded"), nil)
            PageManager.pushPage("CommPop.CommItemReceivePage")
        end
        RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.BATTLE_FAST_BTN, 1)
    elseif opcode == HP_pb.BUY_FAST_FIGHT_TIMES_S then
        local msg = Battle_pb.HPBuyFastFightTimesRet()
        msg:ParseFromString(msgBuff)

        UserInfo.stateInfo.fastFightTimes = msg.fastFightTimes
        UserInfo.stateInfo.fastFightBuyTimes = msg.fastFightBuyTimes
        self:initData(container)
        self:refreshUI(container)
    end
end
-- 計算紅點
function NgBattleExpressPage_calIsShowRedPoint()
    local vipCfg = ConfigManager.getVipCfg()
    local nowBuyTime = UserInfo.stateInfo.fastFightBuyTimes
    local vipLevel = tonumber(UserInfo.playerInfo.vipLevel)
    local canBuyTime = vipCfg[vipLevel]["fastFightTime"] - nowBuyTime
    local buyCost = common:split(GameConfig.buyFastFightPrice, ",")
    local totalFreeTime = 0
    for i = 1, #buyCost do
        if tonumber(buyCost[i]) == 0 then
            totalFreeTime = totalFreeTime + 1
        else
            break
        end
    end
    local nowFreeTime = totalFreeTime - nowBuyTime
    return nowFreeTime > 0
end
-- 刷新紅點
function NgBattleExpressPage:refreshAllPoint(container)
    NodeHelper:setNodesVisible(container, { mExpressRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.BATTLE_FAST_BTN, 1) })
end

local CommonPage = require("CommonPage")
NgBattleExpressPage = CommonPage.newSub(NgBattleExpressPage, thisPageName, option)

return NgBattleExpressPage