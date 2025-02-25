----------------------------------------------------------------------------------
--[[
	世界boss buff
--]]
----------------------------------------------------------------------------------

local option = {
    ccbiFile = "GVEBuffPage.ccbi",
    handlerMap =
    {
        onBuff = "onBuff",
        onHelp = "onHelp",
        onReturnBtn = "onReturnBtn"
    },
    opcodes =
    {
        WORLD_BOSS_SEARCH_BUFF_C = HP_pb.WORLD_BOSS_SEARCH_BUFF_C,
        WORLD_BOSS_SEARCH_BUFF_S = HP_pb.WORLD_BOSS_SEARCH_BUFF_S,
        WORLD_BOSS_RANDOM_C = HP_pb.WORLD_BOSS_RANDOM_C,
        WORLD_BOSS_RANDOM_S = HP_pb.WORLD_BOSS_RANDOM_S,
        WORLD_BOSS_UPGRADE_C = HP_pb.WORLD_BOSS_UPGRADE_C,
        WORLD_BOSS_UPGRADE_S = HP_pb.WORLD_BOSS_UPGRADE_S,
    }
};

local thisPageName = "GVEBuffSelectPage";
local CommonPage = require("CommonPage");
local HP_pb = require("HP_pb");
local WorldBossManager = require("PVP.WorldBossManager");
local GVEBuffSelectPage = { }
local buffCfg = { }
local mIsRunAnimation = false
-- CommonPage.new("GVEBuffSelectPage", option);
local NodeHelper = require("NodeHelper");
local pageInfo = {
    buffRanTimes = 0,
    buffCfgId = 0,
    buffFreeTimes = 0,
    nextPrice = 0,
}
----------------------------------------------------------------------------------
-- GVEBuffSelectPage????????????
----------------------------------------------
function GVEBuffSelectPage:onEnter(container)
    -- GVEBuffSelectPage:refreshPage(container);
    mIsRunAnimation = false
    local ConfigManager = require("ConfigManager")
    buffCfg = ConfigManager.getGVEBuffCfg()

    local bgScale = NodeHelper:getAdjustBgScale(1)
    if bgScale < 1 then bgScale = 1 end
    NodeHelper:setNodeScale(container, "mBG", bgScale, bgScale)

    local labelTb = { }
    local visible = { }
    for i = 1, 6 do
        labelTb["mAttribute" .. i] = common:getLanguageString(buffCfg[i].desc)
        labelTb["mBuffName" .. i] = common:getLanguageString(buffCfg[i].name)
        visible["mBuffName" .. i] = true
        -- labelTb["mAttribute"..i] = common:getLanguageString(buffCfg[i].name)
    end
    NodeHelper:setNodesVisible(container, visible)
    NodeHelper:setStringForLabel(container, labelTb)
    GVEBuffSelectPage:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
    GVEBuffSelectPage:getPageInfo()

    WorldBossManager.isShowHandAni = false
    -- 进到buff选择界面

end

function GVEBuffSelectPage:getPageInfo()
    common:sendEmptyPacket(HP_pb.WORLD_BOSS_SEARCH_BUFF_C, true)
end

function GVEBuffSelectPage:onExit(container)
    GVEBuffSelectPage:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_PUSHPAGE);
    mIsRunAnimation = false
end
-- TODO : ????  ---??????map
function GVEBuffSelectPage:refreshPage(container)
    if pageInfo.buffFreeTimes > 0 then
        NodeHelper:setNodesVisible(container, { mGoldCostNode = false, mFreeTxt = true })
        NodeHelper:setStringForLabel(container, { mFreeTxt = common:getLanguageString("@CurrTimesFree", pageInfo.buffFreeTimes) })
    else
        NodeHelper:setNodesVisible(container, { mGoldCostNode = true, mFreeTxt = false, mGold = true })
        NodeHelper:setStringForLabel(container, { mGold = pageInfo.nextPrice })
    end
end

function GVEBuffSelectPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.WORLD_BOSS_SEARCH_BUFF_S then
        local msg = WorldBoss_pb.HPBossRandomBuffRes();
        msg:ParseFromString(msgBuff);
        pageInfo.buffCfgId = msg.buffCfgId
        pageInfo.buffRanTimes = msg.buffRanTimes
        pageInfo.buffFreeTimes = msg.buffFreeTimes
        pageInfo.nextPrice = msg.nextPrice
        GVEBuffSelectPage:refreshPage(container)
        dump(pageInfo)
        if pageInfo.buffCfgId ~= 0 then
            require("GVEBuffChoosePage")
            GVEBuffChoosePage_setPageInfo(pageInfo)
            PageManager.pushPage("GVEBuffChoosePage")
        end
    elseif opcode == HP_pb.WORLD_BOSS_RANDOM_S then
        local msg = WorldBoss_pb.HPBossRandomBuffRes();
        msg:ParseFromString(msgBuff);
        pageInfo.buffCfgId = msg.buffCfgId
        pageInfo.buffRanTimes = msg.buffRanTimes
        pageInfo.buffFreeTimes = msg.buffFreeTimes
        pageInfo.nextPrice = msg.nextPrice
        GVEBuffSelectPage:refreshPage(container)
        container:runAnimation("Animation")
        mIsRunAnimation = true
    elseif opcode == HP_pb.WORLD_BOSS_UPGRADE_S then

    end
end

--- TODO ?????? ????????
function GVEBuffSelectPage:onBuff(container)
    if mIsRunAnimation == true then
        return
    end

    common:sendEmptyPacket(HP_pb.WORLD_BOSS_RANDOM_C, true)
    -- container:runAnimation("ani")

end

function GVEBuffSelectPage:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "Animation" then
        mIsRunAnimation = false
        require("GVEBuffChoosePage")
        GVEBuffChoosePage_setPageInfo(pageInfo)
        PageManager.pushPage("GVEBuffChoosePage")
    end
end

function GVEBuffSelectPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_GVE)
end


function GVEBuffSelectPage:onReturnBtn(container)
    if WorldBossManager.enterFinalPageFrom == 1 then
        PageManager.changePage("PVPActivityPage")
    else
        PageManager.changePage("GuildPage")
    end
    WorldBossManager.enterFinalPageFrom = 0
end

function GVEBuffSelectPage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function GVEBuffSelectPage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


local CommonPage = require('CommonPage')
GVEBuffSelectPage = CommonPage.newSub(GVEBuffSelectPage, thisPageName, option)
return GVEBuffSelectPage;