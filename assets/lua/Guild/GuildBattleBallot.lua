

local HP_pb = require("HP_pb") --包含协议id文件
local ABManager = require("Guild.ABManager")
local thisPageName = "GuildBattleBallot"
local protoDatas = {} --协议数据
local spine = nil
protoDatas.index = 100
----这里是协议的id
local opcodes = {
    ALLIANCE_BATTLE_DRAW_S = HP_pb.ALLIANCE_BATTLE_DRAW_S
}

local option = {
    ccbiFile = "GuildDrawPopUp.ccbi",
    handlerMap = { --按钮点击事件
        onClose     = "onClose",
        onOpen		= "onOpen",
    },
    opcode = opcodes
}

local GuildBattleBallotBase = {}
function GuildBattleBallotBase:onEnter(container)
    NodeHelper:setStringForLabel(container, {mGuildDrawRank = ""})
	NodeHelper:setNormalImages(container, {mResultImg = "UI/Animation/GuildDraw/GuildDraw_18.png"});
	local str = common:fill(FreeTypeConfig[116].content)    
    ---显示标题
    local node = container:getVarNode("mExplain")
    NodeHelper:setStringForLabel(container, {mExplain = ""}) 
    NodeHelper:addHtmlLable(node, str, GameConfig.Tag.HtmlLable)

    local heroNode = container:getVarNode("mGuildDrawAniNode")
    if heroNode and heroNode:getChildByTag(10010) == nil then
        spine = nil
        spine = SpineContainer:create("Spine/GuildDraw", "choujiang02")
        local spineNode = tolua.cast(spine, "CCNode")
        spineNode:setTag(10010)
        heroNode:addChild(spineNode)
        heroNode:setScale(1)
        if ABManager:getHasDraw() then
            spine:runAnimation(1, "Srand", -1) --Srand
        else
            spine:runAnimation(1, "Stand", -1) --Srand
        end
    end

    self:registerPacket(container)
    --116
    NodeHelper:setNodesVisible(container, {mCloseBtn = false})
    NodeHelper:setNodesVisible(container, {mOpenBtn = true})
    --是否已经抽签
    CCLuaLog("##ABManager:getHasDraw() = "..tostring(ABManager:getHasDraw()))
	if ABManager:getHasDraw() then 
		common:sendEmptyPacket(HP_pb.ALLIANCE_BATTLE_DRAW_C, false)
		NodeHelper:setNodesVisible(container, {mCloseBtn = true})
    	NodeHelper:setNodesVisible(container, {mOpenBtn = false})
	end
end

function GuildBattleBallotBase:onExecute(container)

end

function GuildBattleBallotBase:onExit(container)
    self:removePacket(container)
end
local closeNum = 1
function GuildBattleBallotBase:onClose(container)
    -- closeNum = closeNum + 1
    -- spine:runAnimation(1, "Reward", 1)
    -- --延迟1s
    --     container:runAction(
    --         CCSequence:createWithTwoActions(
    --             CCDelayTime:create(1.5),
    --             CCCallFunc:create(function()
    --                 CCLuaLog("######## spine end###########")
    --                 container:runAnimation("OpenDraw")
    --             end)
    --         )
    --     );
    --if closeNum == 3 then 
        PageManager.popPage(thisPageName)
        --closeNum = 1
    --end
    --PageManager.popPage(thisPageName)
    --PageManager.changePage("MainScenePage") 
    --PageManager.pushPage("PlayerInfoPage")
end

function GuildBattleBallotBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.ALLIANCE_BATTLE_DRAW_S then
        local msg = AllianceBattle_pb.HPAllianceDrawRet()
        msg:ParseFromString(msgBuff)
        protoDatas = msg
        if ABManager:getHasDraw() then 
            CCLuaLog("######## ABManager:getHasDraw()###########")
            CCLuaLog("protoDatas.index = "..tostring(protoDatas.index))
        	--container:runAnimation("ResultAni")
            container:runAnimation("OpenDraw")
        	self:refreshPage(container)
        else
        	--container:runAnimation("OpenDraw")
            spine:runAnimation(1, "Reward", 1)
            --延迟1s
            container:runAction(
                CCSequence:createWithTwoActions(
                    CCDelayTime:create(1.5),
                    CCCallFunc:create(function()
                        CCLuaLog("######## spine end###########")
                        container:runAnimation("OpenDraw")
                    end)
                )
            );
        end
        ABManager:setHasDraw(true) --设置抽签标示
        PageManager.refreshPage("ABMainPage", "updateBallotState") --, 
    end     
end

function GuildBattleBallotBase:refreshPage(container)
	NodeHelper:setNodesVisible(container, {mCloseBtn = true})
    NodeHelper:setNodesVisible(container, {mOpenBtn = false})
	NodeHelper:setStringForLabel(container, {mGuildDrawRank = protoDatas.index})
end

function GuildBattleBallotBase:onAnimationDone(container)
	local animationName=tostring(container:getCurAnimationDoneName())

	if animationName=="OpenDraw" then
		self:refreshPage(container)
	end
end

function GuildBattleBallotBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then --这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;

        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then

        end
    end
end

function GuildBattleBallotBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function GuildBattleBallotBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

function GuildBattleBallotBase:onOpen(container)
	--container:runAnimation("OpenDraw")
    --spine:runAnimation(1, "Reward", 1)
	common:sendEmptyPacket(HP_pb.ALLIANCE_BATTLE_DRAW_C, false)
end

local CommonPage = require('CommonPage')
local GuildBattleBallot= CommonPage.newSub(GuildBattleBallotBase, thisPageName, option)