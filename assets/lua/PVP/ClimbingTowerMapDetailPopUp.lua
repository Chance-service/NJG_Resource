local Battle_pb =  require "Battle_pb"
local Const_pb = require "Const_pb"
local UserInfo = require("PlayerInfo.UserInfo");

local thisPageName = "ClimbingTowerMapDetailPopUp"
local NodeHelper = require("NodeHelper");
local ClimbingTower_pb = require("ClimbingTower_pb")

local ClimbingDataManager = require("PVP.ClimbingDataManager")
local HP_pb = require("HP_pb")
local option = {
    ccbiFile = "ClimbingTowerMapDetailPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onHelp = "onHelp",
        onAdd = "onAdd",
        onImmediatelyDekaron= "onImmediatelyDekaron",
        onFastSweep= "onFastSweep"
    },
    opcodes = {
        CLIMBINGTOWER_CHALLENG_S = HP_pb.CLIMBINGTOWER_CHALLENG_S,
    },
}

local curMapId = 1

local ClimbingTowerMapDetailPopUp = {}

local curMapData = nil

local isFirstDrop = true
----------------------------------------------
function ClimbingTowerMapDetailPopUp:onEnter(container)
    container:registerPacket(HP_pb.CLIMBINGTOWER_CHALLENG_S)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container.scrollview = container:getVarScrollView("mContent")

    NodeHelper:setStringForLabel(container,{mTitle = common:getLanguageString("@EliteMapRewardTitle")})
    self:initData(container)
    self:refreshPage(container)
    ClimbingDataManager:sendClimbingChallengeReq(curMapId)
end

function ClimbingTowerMapDetailPopUp:initData(container)
    curMapData = ClimbingDataManager:getCurMapCfg(curMapId)
end

function ClimbingTowerMapDetailPopUp:onExecute(container)

end

function ClimbingTowerMapDetailPopUp:onFeetById(container,index)
    local thisResList =  yuan3(isFirstDrop, curMapData.firstDrop,curMapData.normalDrop)
    local resSize = #thisResList
    if index>resSize then
        return
    else
        local resCfg = thisResList[index];
        if resCfg then
            GameUtil:showTip(container:getVarNode("mRewardFeet"), resCfg)
        end
    end
end

function ClimbingTowerMapDetailPopUp:onExit(container)
    curMapId = 0
    container:removePacket(HP_pb.CLIMBINGTOWER_CHALLENG_S)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container.scrollview:removeAllCell()
end
----------------------------------------------------------------
local EliteMapRewardContent = {}
function EliteMapRewardContent:onRewardFeet01(container)
    local contentId = self.id
    ClimbingTowerMapDetailPopUp:onFeetById(container,contentId)
end
function EliteMapRewardContent:onRefreshContent( content )
    local container = content:getCCBFileNode()
    local contentId = self.id
    local thisResList = yuan3(isFirstDrop, curMapData.firstDrop,curMapData.normalDrop)
    local lb2Str,quaMap,picMap = {},{},{}
    local resCfg = thisResList[contentId]
    if not resCfg then return end

    local resInfo = ResManagerForLua:getResInfoByTypeAndId(resCfg.type, resCfg.itemId, resCfg.count);

    local str = resInfo.name
    if resInfo.level then
        str = common:getR2LVL() .. resInfo.level
    end
    lb2Str["mRewardNum"] = ""
    quaMap["mRewardFeet"] = resInfo.quality
    picMap["mRewardPic"] = resInfo.icon

    NodeHelper:setBlurryString(container,"mRewardName",str,65,4)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setQualityFrames(container, quaMap)
    NodeHelper:setSpriteImage(container, picMap)
end
function ClimbingTowerMapDetailPopUp:rebuildAllItem( container )
    self:clearAllItem(container)
    self:buildItem(container)
end

function ClimbingTowerMapDetailPopUp:clearAllItem( container )
    local scrollview = container.scrollview
    scrollview:removeAllCell()
end
function ClimbingTowerMapDetailPopUp:buildItem(container)
    local scrollview = container.scrollview
    local ccbiFile = "EliteMapRewardContent.ccbi"
    local itemData = yuan3(isFirstDrop, curMapData.firstDrop,curMapData.normalDrop)
    itemData = itemData or {}
    local totalSize = #itemData
    if totalSize == 0 then return end
    local cell = nil
    for i=1,totalSize do
        cell = CCBFileCell:create()
        cell:setCCBFile(ccbiFile)
        local panel = common:new({id=i},EliteMapRewardContent)
        cell:registerFunctionHandler(panel)

        scrollview:addCell(cell)
        local pos = ccp(cell:getContentSize().width*(i-1),0)
        cell:setPosition(pos)

    end
    local size = CCSizeMake(cell:getContentSize().width*totalSize,cell:getContentSize().height )

    scrollview:setContentSize(size)
    scrollview:setContentOffset(ccp(0,0))
    scrollview:forceRecaculateChildren()
    if totalSize <= 5 then
        scrollview:setTouchEnabled(false)
    else
        scrollview:setTouchEnabled(true)
    end
end

function ClimbingTowerMapDetailPopUp:refreshPage(container)

    local bossInfo = ClimbingDataManager:getMonsterInfo(curMapId)
    NodeHelper:setNodesVisible(container,{
        mEnemyNode1 = #bossInfo>=1,
        mEnemyNode2 = #bossInfo>=2,
        mEnemyNode3 = #bossInfo>=3
    })
    for i=1,#bossInfo do
        local str = {
            ["mEnemyNum0"..i] = common:getR2LVL()..tostring(bossInfo[i].level),
            ["mEnemyName0"..i] = tostring(bossInfo[i].name)
        }
        local pic = {
            ["mEnemyPic0"..i] = bossInfo[i].pic
        }

--[[        local quality = {
            ["mEnemyFeet0"..i] = EliteMapManager:getQualityById(curMapId)
        }]]

        for j=1,#bossInfo[i].skillName do
            str["mSkillName"..(j+(i-1)*4)] = bossInfo[i].skillName[j]
        end

        local strName = {
            --["mEnemyName0"..i] = ""
        }

--[[        local colorMap = {
            ["mEnemyName0"..i] = ConfigManager.getQualityColor()[EliteMapManager:getQualityById(curMapId)].textColor
        }]]

        --NodeHelper:setColorForLabel( container, colorMap )
        NodeHelper:setLabelWidthForLineBreak(container, strName,120);
        NodeHelper:setStringForLabel(container, str);
        NodeHelper:setSpriteImage(container, pic);
        --NodeHelper:setQualityFrames(container, quality);
    end
    self:rebuildAllItem( container )

--[[    NodeHelper:setStringForLabel(container,{
        mTodaySurplusNum = common:getLanguageString("@TodaySurpluseNum")..tostring(UserInfo.stateInfo.eliteFightTimes)
    })

    local stageName = EliteMapManager:getStageName(curMapId)
    local stageLevel = EliteMapManager:getLevelById(curMapId)
    CCLuaLog("EliteMapRewardPopup:refreshPage---stageName"..stageName .. "stageLevel"..stageLevel)
    NodeHelper:setStringForLabel(container,{
        mCareerName = (stageName.."("..stageLevel..")")
    })]]

--[[    local curPassedMapId = EliteMapManager:getPassedMapIdByLevel(stageLevel)

    if curPassedMapId >= curMapId   then
        NodeHelper:setNodesVisible(container,{
            mFastSweepNode = true,
            mImmediatelyDekaron = false,
            mImmediatelyBtn = true
        })
    else
        NodeHelper:setNodesVisible(container,{
            mFastSweepNode = false,
            mImmediatelyDekaron = true,
            mImmediatelyBtn = false
        })
    end]]

end

----------------click event------------------------
function ClimbingTowerMapDetailPopUp:onClose(container)
    PageManager.popPage(thisPageName)
end

function ClimbingTowerMapDetailPopUp:onHelp(container)

end

function ClimbingTowerMapDetailPopUp:onAdd(container)
    --ClimbingTowerMapDetailPopUp:onShowBuyLimit()
end

function ClimbingTowerMapDetailPopUp:onFastSweep(container)
    if UserInfo.playerInfo.vipLevel <1 then
        MessageBoxPage:Msg_Box_Lan("@MapFightWipeBossVIPLimit");
        return
    end
    local leftTime = UserInfo.stateInfo.eliteFightTimes;
    if leftTime <= 0 then
        return ClimbingTowerMapDetailPopUp:onShowBuyLimit();
    end
    local message = Battle_pb.HPBossWipe()
    if message~=nil then
        message.mapId = curMapId;
        local pb_data = message:SerializeToString();
        PacketManager:getInstance():sendPakcet(HP_pb.BOSS_WIPE_C,pb_data,#pb_data,true);
    end
end


function ClimbingTowerMapDetailPopUp:onShowBuyLimit()
    EliteMapPage_onShowBuyLimit()
end

function ClimbingTowerMapDetailPopUp.toPurchaseTimes(flag,times)
    if flag then
        local message = Battle_pb.HPBuyEliteFightTimes()
        if message~=nil then
            message.times = times;
            local pb_data = message:SerializeToString();
            PacketManager:getInstance():sendPakcet(HP_pb.BUY_ELITE_FIGHT_TIMES_C,pb_data,#pb_data,true);
        end
    end
end

function ClimbingTowerMapDetailPopUp:onImmediatelyDekaron(container)
    local leftTime = UserInfo.stateInfo.eliteFightTimes;
    if leftTime <= 0 then
        return EliteMapRewardPopup:onShowBuyLimit();
    end
    local message = Battle_pb.HPBattleRequest()
    if message~=nil then
        message.battleType = Battle_pb.BATTLE_PVE_ELITE_BOSS;
        message.battleArgs = 	curMapId;
        message.useItemType = Const_pb.NONE;
        EliteMapManager.curFightMap = curMapId
        local pb_data = message:SerializeToString();
        PacketManager:getInstance():sendPakcet(HP_pb.BATTLE_REQUEST_C,pb_data,#pb_data,false);
    end

end

function ClimbingTowerMapDetailPopUp:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.BOSS_WIPE_S then
--[[        local msg = Battle_pb.HPBossWipeRet()
        msg:ParseFromString(msgBuff)
        if msg.award == nil or msg == nil then
            return
        end
        local showReward = {}
        if msg.award:HasField("drop") then
            local drop = msg.award.drop
            --详细装备掉落情况
            for i=1,#drop.detailEquip  do
                local oneReward = drop.detailEquip[i]
                if oneReward.count > 0 then
                    local resInfo = {}
                    resInfo["type"] = 40000
                    resInfo["itemId"] = oneReward.itemId
                    resInfo["count"] = oneReward.count
                    showReward[#showReward + 1] = resInfo
                end
            end
            for i=1,#drop.item  do
                local oneEquip = drop.item[i]
                if oneEquip.itemCount > 0 then
                    local resInfo = {}
                    resInfo["type"] = oneEquip.itemType
                    resInfo["itemId"] = oneEquip.itemId
                    resInfo["count"] = oneEquip.itemCount
                    showReward[#showReward + 1] = resInfo
                end
            end
            local CommonRewardPage = require("CommonRewardPage")
            CommonRewardPageBase_setPageParm(common:table_tail(showReward, #showReward), true)
            PageManager.pushPage("CommonRewardPage")
        end]]
    elseif opcode == HP_pb.CLIMBINGTOWER_CHALLENG_S then
        local msg = ClimbingTower_pb.HPClimbingTowerChallengeRet()
        msg:ParseFromString(msgBuff)
        ClimbingDataManager:setClimbingChallengeData(msg)
        PageManager.viewBattlePage(msg.battleInfo)
        ClimbingDataManager:sendInfoReq()
    end

end

function ClimbingTowerMapDetailPopUp:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == thisPageName then
            self:refreshPage(container)
        end
    end
end

function ClimbingTowerMapDetailPopUp_setMapId(mapId)
    curMapId = mapId
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local ClimbingTowerMapDetailPopUp = CommonPage.newSub(ClimbingTowerMapDetailPopUp, thisPageName, option);
