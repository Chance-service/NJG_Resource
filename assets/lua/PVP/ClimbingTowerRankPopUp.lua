
local  ClimbingTowerRankPopUp = {}

local  HP_pb =  require "HP_pb"
local  ProfRank_pb =  require "ProfRank_pb"
local Const_pb = require("Const_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local NewbieGuideManager = require("NewbieGuideManager")
local thisPageName = "ClimbingTowerRankPopUp"
local ClimbingDataManager = require("PVP.ClimbingDataManager")
local ClimbingTower_pb = require("ClimbingTower_pb")
local option = {
    ccbiFile = "ClimbingTowerRank.ccbi",
    handlerMap = {
        onHelp					= "onHelp",
        onReturnBtn			= "onReturn"
    },
    opcode = {
        CLIMBINGTOWER_RANK_S = HP_pb.CLIMBINGTOWER_RANK_S,
    }
}

local ProfessionType = {
    RANKALL = 1,
    WARRIOR = 2,
    HUNTER = 3,
    MASTER = 4,
}

local PageInfo = {
    curProType = ProfessionType.RANKALL,--ProfessionType.WARRIOR,
    selfRank = "--",
    rankInfos = {},
    viewHolder = {}

}

local roleConfig = nil
local rankData = nil
local ProfessionRankingPageContent = {}
----------------------------------------------------
function ProfessionRankingPageContent:onRefreshContent( content )
    local container = content:getCCBFileNode()
    local contentId = self.id
    local pSprite = container:getVarSprite("mRankImage")

    local itemInfo = rankData.allRank[contentId]

    local signature = ""
    signature =  tostring(itemInfo.historicHighStar)

    local prof = itemInfo.prof --roleConfig[itemInfo.cfgItemId].profession  --职业
    NodeHelper:setSpriteImage(container, {mProfession = GameConfig.ProfessionIcon[prof]})

    --排名图片设置
    local pSprite = container:getVarSprite("mRankImage")
    if itemInfo.rank <= 3 then
        pSprite:setTexture(GameConfig.ArenaRankingIcon[itemInfo.rank])
        NodeHelper:setStringForLabel(container , {mRankText = itemInfo.rank})
        NodeHelper:setNodesVisible(container , {mRankText = false})
    else
        pSprite:setTexture(GameConfig.ArenaRankingIcon[4])
        NodeHelper:setStringForLabel(container , {mRankText = itemInfo.rank})
        NodeHelper:setNodesVisible(container , {mRankText = true})
    end

    local lb2Str = {
        mLv 			=  itemInfo.level, --UserInfo.getOtherLevelStr(itemInfo.rebirthStage, itemInfo.level),
        mName			= itemInfo.name,
        mRankingNum		= common:getLanguageString("@Ranking") .. itemInfo.rank,
        mFightingNum	= common:getLanguageString("@Fighting") .. itemInfo.fightValue,
        mPicRankingNum  = itemInfo.rank,
        mPersonalSignature		=  signature
    }
    NodeHelper:setBlurryString(container,"mPersonalSignature",signature,400,13)
    lb2Str.mGuildName = ""
--[[    if itemInfo:HasField("allianceName") and itemInfo:HasField("allianceId") then
        lb2Str.mGuildName      = common:getLanguageString("@GuildLabel") ..itemInfo.allianceName.."(ID "..itemInfo.allianceId..")"

    else
        lb2Str.mGuildName      = common:getLanguageString("@GuildLabel") .. common:getLanguageString("@NoAlliance")

    end]]
    NodeHelper:setStringForLabel(container, lb2Str)

    local  icon,bgIcon = common:getPlayeIcon(prof,itemInfo.headIcon)
    NodeHelper:setSpriteImage(container, {mPic = icon,mPicBg = bgIcon})

    local lb2StrNode = {
        mRankingTitle 			= "mRankingNum",
        mFightingTitle 				= "mFightingNum",
        mGuildLabel 				= "mGuildName"
    }
    NodeHelper:setLabelMapOneByOne(container,lb2StrNode,5,true)


end
function ProfessionRankingPageContent:onHand( container )
    local contentId = self.id
    local itemInfo = rankData.allRank[contentId]
    if UserInfo.playerInfo.playerId == itemInfo.playerId then
        return
    end
    PageManager.viewPlayerInfo(itemInfo.playerId, true)
end

function ClimbingTowerRankPopUp:onEnter( container )
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:registerPacket(container)
    self:initPage(container)

    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_FIGHT_NUM)
    ClimbingDataManager:sendClimbingRankReq()
end

function ClimbingTowerRankPopUp:initPage( container )
    self:registerPacket( container )
    UserInfo.sync()
    roleConfig = ConfigManager.getRoleCfg()
    container.scrollview = container:getVarScrollView("mRankingContent")
    local lb2Str = {
        mMyRank = "",
        mMyRankStar = "",
    }
    NodeHelper:setStringForLabel(container, lb2Str)
--[[    NodeHelper:autoAdjustResizeScrollview(container.scrollview)
    for i = 1,2 do
        NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite"..i))
    end]]

end


function ClimbingTowerRankPopUp:refreshPage( container  )
--[[   local  icon,bgIcon = common:getPlayeIcon(UserInfo.roleInfo.prof,  GameConfig.headIconNew or UserInfo.playerInfo.headIcon )
    NodeHelper:setSpriteImage(container, {mPic = icon,mPicBg = bgIcon})]]
    rankData = ClimbingDataManager:getClibingTowerRank()
    local lb2Str = {
        mMyRank = "我的排名："..rankData.selfRank.rank,
        mMyRankStar = "历史最高星："..rankData.selfRank.historicHighStar,
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    self:rebuildAllItem(container);
end


function ClimbingTowerRankPopUp:onExecute( container )

end

function ClimbingTowerRankPopUp:onExit( container )
    self:removePacket( container )
    NodeHelper:deleteScrollView(container)
end

function ClimbingTowerRankPopUp:onReturn(container)
   PageManager.popPage(thisPageName)
end

function ClimbingTowerRankPopUp:onHelp( container )
    PageManager.showHelp(GameConfig.HelpKey.HELP_FIGHT_NUM)
end

function ClimbingTowerRankPopUp:onReceivePacket( container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.CLIMBINGTOWER_RANK_S then
        local msg = ClimbingTower_pb.HPClimbingTowerListSyncS()
        msg:ParseFromString(msgBuff)
        ClimbingDataManager:setClibingTowerRankData(msg)
        self:refreshPage(container)
    end
end

function ClimbingTowerRankPopUp:onReceiveMessage(container)
--[[    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onLocalPlayerInfo then
                if container.scrollview then
                    container.scrollview:refreshAllCell()
                end
                self:refreshPage(container)
            end
        end
    end]]
end

function ClimbingTowerRankPopUp:onReceiveRankingInfo( container , msg )
--[[    PageInfo.rankInfos = msg.rankInfo
    table.sort(PageInfo.rankInfos , function ( p1 , p2)
        if not p2 then return true end
        if not p1 then return false end

        return p1.rank > p2.rank
    end)

    if msg:HasField("selfRank") then
        if msg.selfRank == 0 then
            PageInfo.selfRank = common:getLanguageString("@NotInRanking")
        else
            PageInfo.selfRank = msg.selfRank
        end
    else
        PageInfo.selfRank = "--"
    end
    local rank = ""
    if PageInfo.selfRank == 0 then
        rank = common:getLanguageString("@NotInRanking")
    else
        rank = PageInfo.selfRank
    end
    container:getVarLabelTTF("mRankingNum"):setString( common:getLanguageString("@Ranking") .. rank )
    self:rebuildAllItem( container )
    local playerIds = {}
    for i,v in ipairs(msg.rankInfo) do
        table.insert(playerIds, v.playerId)
    end]]
end

function ClimbingTowerRankPopUp:rebuildAllItem( container )
    self:clearAllItem(container)
    self:buildItem(container)
end

function ClimbingTowerRankPopUp:clearAllItem( container )
    local scrollview = container.scrollview
    scrollview:removeAllCell()
end

function ClimbingTowerRankPopUp:buildItem( container )
    local scrollview = container.scrollview
    local ccbiFile = "ClimbingTowerRankContent.ccbi"
    local totalSize = #rankData.allRank
    if totalSize == 0 then return end
    local spacing = 5
    local cell = nil
    for i=1,totalSize do
        cell = CCBFileCell:create()
        cell:setCCBFile(ccbiFile)
        local panel = common:new({id = totalSize - i + 1 },ProfessionRankingPageContent)
        cell:registerFunctionHandler(panel)

        scrollview:addCell(cell)
        local pos = ccp(0,cell:getContentSize().height*(i-1) )
        cell:setPosition(pos)

    end
    local size = CCSizeMake(cell:getContentSize().width,cell:getContentSize().height*totalSize )
    scrollview:setContentSize(size)
    scrollview:setContentOffset(ccp(0,scrollview:getViewSize().height - scrollview:getContentSize().height * scrollview:getScaleY()))
    scrollview:forceRecaculateChildren()
end

function ClimbingTowerRankPopUp:registerPacket( container )
    container:registerPacket(HP_pb.CLIMBINGTOWER_RANK_S)
end

function ClimbingTowerRankPopUp:removePacket( container )
    container:removePacket(HP_pb.CLIMBINGTOWER_RANK_S)
end

----------------------------------------------------
local CommonPage = require("CommonPage")
ClimbingTowerRankPopUp = CommonPage.newSub(ClimbingTowerRankPopUp, thisPageName, option)

return ClimbingTowerRankPopUp