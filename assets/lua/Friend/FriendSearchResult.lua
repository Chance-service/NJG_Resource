local NodeHelper = require("NodeHelper")
local thisPageName = 'FriendSearchResult'
local UserInfo = require("PlayerInfo.UserInfo");
local FriendSearchResultBase = {}
local FriendManager = require("FriendManager")
local NewHeadIconItem = require("NewHeadIconItem")

-- 搜索id最大值，与后端一致
local FriendSearchIdMax = 100000000

FriendSearchPageCallback = nil

local option = {
	ccbiFile = "FriendAddPopUp.ccbi",
	handlerMap = {
		onClose 		= 'onClose',
		onFriendAdd 	= 'onFriendAdd',
	},
	opcodes = {
        --FRIEND_FIND_S = HP_pb.FRIEND_FIND_S,
	}
}

local friendInfo = {}
local roleConfig = {}

-----------------------------------------------
local mercenaryHeadContent = {
    ccbiFile = "FormationTeamContent.ccbi"
}
function mercenaryHeadContent:refreshItem(container,Info)
    self.container = container
    UserInfo = require("PlayerInfo.UserInfo")
    local roleIcon = ConfigManager.getRoleIconCfg()
    local trueIcon = GameConfig.headIconNew or Info.headIcon
    if not roleIcon[trueIcon] then
        local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
        if NodeHelper:isFileExist(icon) then
            NodeHelper:setSpriteImage(container, { mHead = icon })
        end
        --NodeHelper:setSpriteImage(container, { mHeadFrame = GameConfig.MercenaryBloodFrame[1] })
        NodeHelper:setStringForLabel(container, { mLv = Info.level })
    else
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[trueIcon].MainPageIcon })
        NodeHelper:setStringForLabel(container, { mLv = Info.level })
    end

    NodeHelper:setNodesVisible(container, { mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false, 
                                            mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false })
end
-----------------------------------------------
function FriendSearchResultBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    local info = friendInfo
    OSPVPManager.reqLocalPlayerInfo({info.playerId})

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    
    roleConfig = ConfigManager.getRoleCfg()

    if info then
        lb2Str["mName"] = info.name
        lb2Str["mLevelNum"] = UserInfo.getOtherLevelStr(info.rebirthStage, info.level)
        lb2Str["mFightingNum"] = GameUtil:formatDotNumber(info.fightValue)

        NodeHelper:setBlurryString(container, "mLable", info.signature or "", 290, 10)

        local headNode = ScriptContentBase:create(mercenaryHeadContent.ccbiFile)
        local parentNode = container:getVarNode("mHeadNode")
        parentNode:removeAllChildren()
        mercenaryHeadContent:refreshItem(headNode,info)
        headNode:setAnchorPoint(ccp(0.5, 0.5))
        parentNode:addChild(headNode)
    end

    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function FriendSearchResultBase:onClose(container)
	PageManager.popPage(thisPageName)
end

function FriendSearchResultBase:onFriendAdd(container)
    if friendInfo and friendInfo.playerId then
        FriendManager.sendApplyById(friendInfo.playerId)
        self:onClose(container)
    end
end

function FriendSearchResultBase:onExit(container)
    friendInfo = {}
end

function FriendSearchResultBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
		if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onLocalPlayerInfo then
                if friendInfo and friendInfo.playerId then
                    local sprite2Img = {}
                    if friendInfo.cspvpRank and friendInfo.cspvpRank > 0 then
                        local stage = OSPVPManager.checkStage(friendInfo.cspvpScore, friendInfo.cspvpRank)
                        sprite2Img.mFrame = stage.stageIcon
                    else
                        sprite2Img.mFrame = GameConfig.QualityImage[1]
                    end
                    NodeHelper:setSpriteImage(container,sprite2Img)
                end
            end
		end
	end
end

function FriendSearchResultBase_onSearchResult(data)
    friendInfo = data
    PageManager.pushPage(thisPageName)
end

local CommonPage = require('CommonPage')
local FriendSearchPopPage= CommonPage.newSub(FriendSearchResultBase, thisPageName, option)