
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local json = require('json')
local NoticePage = require('NoticePage')
local hp = require('HP_pb')
local NewbieGuideManager = require("Guide.NewbieGuideManager")
require('MainScenePage')
local thisPageName = 'FacebookFriendPage'
local UserInfo = require("PlayerInfo.UserInfo")
local FacebookFriendPage ={}
local FinalFBFriendList = {}--服务器处理后的最终结果
local FBCurAskTimes = 0;--当前索取的次数
local FBLastPressContent;--上一次点选的Content对象
local FBMyRankAmongFriends;--我的排名

local option = {
	ccbiFile = "FB_RankAndInvitePopUp.ccbi",
	handlerMap = {
		onClose 					= 'onClose',
        ohHelp      = 'onHelp',
		onInvite 	= 'onInvite',
        
		--onInvitedFriendsGiftTab 	= 'onInvitedFriendsGiftTab',
		
	},
    opcodes = {
		FRIEND_LIST_FACEBOOK_C = HP_pb.FRIEND_LIST_FACEBOOK_C,
		FRIEND_LIST_FACEBOOK_S = HP_pb.FRIEND_LIST_FACEBOOK_S,
	    FRIEND_ASK_TICKET_S = HP_pb.FRIEND_ASK_TICKET_S;
	    FRIEND_ASK_TICKET_C = HP_pb.FRIEND_ASK_TICKET_C;
	}
}

---=============================================================================
--平台回调
local libPlatformListener = {}
function libPlatformListener:onReceiveCommonMessage(listener)
   --[[ if not listener then 
     return 
    end

    local tag = listener:getMsgTag()
    local msg = listener:getMsgValue()
    FBFriendList = json.decode(msg)

    CCLuaLog("onReceiveCommonMessage ============ P1:Tag:"..tostring(tag))
    CCLuaLog("onReceiveCommonMessage ============ P2:Msg:"..tostring(msg))
    for i=1, #(FBFriendList) do  
        if i==1 then
            FBFriendList[i].bIsMine = true --玩家自己的信息
        else
            FBFriendList[i].bIsMine = false 
            FBFriendList[i].bIsAlreadyAsk = false;--是否已经向此好友索取过礼物
        end
    end
   -- self:onRequestData(nil)--向服务器请求处理
   FinalFBFriendList= FBFriendList;
   FacebookFriendPage:rebuildAllItem(FacebookFriendPage.container)]]--
end
---=============================================================================
function FacebookFriendPage.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
		FacebookFriendPage.onRefreshItemView(container)
	elseif eventName == "luaHttpImgCompleted" then
		FacebookFriendPage.onHttpImgCompleted(container)
    elseif eventName == "onLike" then
		FacebookFriendPage.onLike(container)	
	end
end

function FacebookFriendPage:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function FacebookFriendPage:onEnter(container)
    self:registerPacket(container)
    FacebookFriendPage.container = container
    NodeHelper:initScrollView(container, "mContent", 10);
    FinalFBFriendList = {}--服务器处理后的最终结果
    FBCurAskTimes = 0;--当前索取的次数
    FBLastPressContent=nil;--上一次点选的Content对象
    FBMyRankAmongFriends = 0;

    if Golb_Platform_Info.is_win32_platform then
        FBFriendList = {} --SDK反馈的好友信息
	    --FacebookFriendPage.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)	
        ---测试-----------------------------------------------------------
       --FBFriendList = json.decode("[{\"fbname\":\"房海瑞\",\"uid\":\"R2_0\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\/\/www.baidu.com\/img\/bd_logo1.png\"},{\"fbname\":\"TestUser\",\"uid\":\"R2_1\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\/\/th-p.talk.kakao.co.kr\/th\/talkp\/wkiHUSOZK8\/5ZCbB6qAm0632QHE51Jc7K\/t9ilgr_110x110_c.jpg\"}]")
       --FBFriendList = json.decode("[{\"fbname\":\"房海瑞\",\"uid\":\"R2_0\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture.png\"},{\"fbname\":\"TestUser\",\"uid\":\"R2_1\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\/\/th-p.talk.kakao.co.kr\/th\/talkp\/wkiHUSOZK8\/5ZCbB6qAm0632QHE51Jc7K\/t9ilgr_110x110_c.jpg\"}]")
       --FBFriendList = json.decode("[{\"fbname\":\"房海瑞\",\"uid\":\"R2_0\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?\"},{\"fbname\":\"TestUser01\",\"r2_127614161\":\"R2_1\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture1?\"},{\"fbname\":\"TestUser02\",\"uid\":\"R2_2\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture2?\"},{\"fbname\":\"TestUser03\",\"uid\":\"R2_3\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\/\/th-p.talk.kakao.co.kr\/th\/talkp\/wkiHUSOZK8\/5ZCbB6qAm0632QHE51Jc7K\/t9ilgr_110x110_c.jpg\"}]")
       --{\"fbname\":\"房海瑞\",\"uid\":\"R2_0\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?.png\"}
        --FBFriendList = json.decode("[{\"fbname\":\"房海瑞\",\"uid\":\"R2_0\",\"fbid\":\"1392863614365930\",\"fburl\":\"http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?\"}]")
         FBFriendList =	{{
		fbname="房海瑞",				
		fbid="1408855526100072",
		fburl="http:\\/\\/graph.facebook.com\\/1408855526100072\\/picture?",		
		bIsMine = false,		
		uid = "R2_11",
        bIsAlreadyAsk = false
        },{
		fbname="Anita Jiang",				
		fbid="664644046972919",
		fburl="http:\\/\\/graph.facebook.com\\/664644046972919\\/picture",		
		bIsMine = false,		
		uid = "r2_127614161",
        bIsAlreadyAsk = false,
		},{
		fbname="Huang Summer",				
		fbid="1580121272265782",
		fburl="http:\\/\\/graph.facebook.com\\/1580121272265782\\/picture",		
		bIsMine = false,		
		uid = "R2_"..13,
        bIsAlreadyAsk = false,
		},}
        for i=1, #(FBFriendList) do  
            if i==1 then
                FBFriendList[i].bIsMine = true--玩家自己的信息
            else
                FBFriendList[i].bIsMine = false 
                FBFriendList[i].bIsAlreadyAsk = false;--是否已经向此好友索取过礼物
            end
        end

        FBFriendList[2].bIsAlreadyAsk = true;

--        FBFriendList =	{{
--		fbname="房海瑞",				
--		fbid="556234",
--		fburl="http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?",		
--		bIsMine = false,		
--		uid = "R2_11",
--        bIsAlreadyAsk = false
--        },}
--        FBFriendList[1].bIsMine = true

        FinalFBFriendList = FBFriendList
    
        --self:OnTestData(container);
        self:onRequestData(nil)
     else
        CCLuaLog("onReceiveCommonMessage =========FBFriendList"..#FBFriendList)
        for i=1, #(FBFriendList) do  
            if i==1 then
                FBFriendList[i].bIsMine = true--玩家自己的信息
            else
                FBFriendList[i].bIsMine = false 
                FBFriendList[i].bIsAlreadyAsk = false;--是否已经向此好友索取过礼物
            end
        end
        FinalFBFriendList = FBFriendList;
        self:onRequestData(nil)
        --FacebookFriendPage:rebuildAllItem(FacebookFriendPage.container)

     end
       -- self:onRequestData(nil)--向服务器请求处理
       ---测试-----------------------------------------------------------
    FacebookFriendPage.container = container
   -- self:refreshPage(container)
    local lb2Str = {
        mTimes = common:getLanguageString('@FBAskTimes',FBCurAskTimes)
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_FBFRIEND_SHOP)--help
end


function FacebookFriendPage:onExit(container)
	NodeHelper:deleteScrollView(container);
	if FacebookFriendPage.libPlatformListener then
		FacebookFriendPage.libPlatformListener:delete()
	end
end

function FacebookFriendPage:refreshPage(container,isRefreshInvite)
	self:rebuildAllItem(container);
end
function FacebookFriendPage:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function FacebookFriendPage:clearAllItem(container)
	container.m_pScrollViewFacade:clearAllItems();
	container.mScrollViewRootNode:removeAllChildren();
end

function FacebookFriendPage.onLike(container)
    local FriendId = tonumber(container:getItemDate().mID)
    local friendInfo = FinalFBFriendList[FriendId]
    local askMessage = common:getLanguageString('@FBAskMessage');
    local askTitle = common:getLanguageString('@FBAskTitle');
    local askObjectId = common:getLanguageString('@FBAskObjectId');
   -- local askMsg = askMessage.."$"..friendInfo.fbid.."$"..askObjectId.."$".."1".."$"..askTitle.."$".."askRequst,"..friendInfo.uid;
    local strtable = {
        message = askMessage,
        friendid = tostring(friendInfo.fbid),
        objectId = GameConfig.FBAskObjectId,
        asktype = "1",
        title = askTitle,
        extraData = "askRequst,"..friendInfo.uid,
	requestId = "",
    }
    local JsMsg  = cjson.encode(strtable)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ASKFOR_TICKET",JsMsg)
--    local FriendId = tonumber(container:getItemDate().mID)
--    local friendInfo = FinalFBFriendList[FriendId]
--    if FBCurAskTimes >= 4 then 
--     MessageBoxPage:Msg_Box_Lan("@AskTicketLimit")
--        return
--    end
--    FBLastPressContent = container;
--    local msg = Friend_pb.HPFriendAskTicket()
--    msg.uid = friendInfo.uid;
--    local pb = msg:SerializeToString()
--    FBCurAskTimes = FBCurAskTimes+1
--    PacketManager:getInstance():sendPakcet(hp.FRIEND_ASK_TICKET_C, pb, #pb, true)
end
function FacebookFriendPage.onHttpImgCompleted(container)
	local contentId = container:getItemDate().mID
	local imgName = container:getHttpImgName()
	CCLuaLog("Get Inamge !!!!!!!!!onHttpImgCompleted!!!!!!!!!!"..imgName .. "contentId " .. contentId);

	NodeHelper:setHeadIcon(container,"mPic","httpImg/" .. imgName,88)
	
end
function FacebookFriendPage.onRefreshItemView(container)
    local contentId = container:getItemDate().mID
    local FriendInfo = FinalFBFriendList[contentId]
    local imageUrl = FriendInfo.fburl
    local fileName = ""
    if imageUrl ~= nil then
        if string.sub(imageUrl,-1) == "?" then --处理URL 后缀的问号
         imageUrl = string.sub(imageUrl,1,#imageUrl-1)
        end
        fileName = common:getHtmlImgName(imageUrl)
        fileName = common:CompletedImgName(fileName);
        fileName = tostring(FriendInfo.fbid)..fileName
    end
    
    if fileName == "" then 
        NodeHelper:setHeadIcon(container,"mPic","UI/default_user.png",88)
    else
        if common:isKakaoImgExist(fileName) then
            CCLuaLog("pic is exist...");
            NodeHelper:setHeadIcon(container,"mPic","httpImg/" .. fileName,88)
		else
            CCLuaLog("loading pic from net...");
			NodeHelper:setHeadIcon(container,"mPic","UI/default_user.png",88)
			container:addToHttpImgListener(fileName);
			HttpImg:getInstance():getHttpImg(imageUrl,fileName)
		end
    end
    --	local message = common:getLanguageString('@HonorExchangeRefresh', ArenaInfo.refreshCostHonor)
--    local lb2Str = {
--		mFBname 		= FriendInfo.fbname,
--		mFBFriendNum 		= tostring(contentId),
--		mServerName		= "Server"..contentId,--common:getLanguageString('@FBRankSeverName', FriendInfo.lastserver)
--		mLevel 	= "10",----common:getLanguageString('@FBRankLevel', FriendInfo.lastserver)
--		mPower 			= "3255", ----common:getLanguageString('@FBRankPower', FriendInfo.fightValue)
--        mArenaRank  ="10",----common:getLanguageString('@FBRankArenaRank', FriendInfo.arenaRank)
--        mVipLevel   = "VIP 5",----common:getLanguageString('@FBRankVip', FriendInfo.vip)
--		};
    
 
    local StrRank = "";
    local StrServer = "";
    if FriendInfo.arenaRank < 0 then
       StrRank = common:getLanguageString('@FBNoArenaRank');
    else
       StrRank = common:getLanguageString('@FBRankArenaRank', FriendInfo.arenaRank)
    end
    CCLuaLog("StrServer======================================:"..FriendInfo.lastserver);
    local StrServer = GamePrecedure:getInstance():getServerNameById(tonumber(FriendInfo.lastserver));

     if FriendInfo.bIsMine then --自己的背景颜色需特殊处理
         container:getVarNode("mTrophyBG03"):setVisible(false);
         container:getVarNode("mBT_Like"):setVisible(false);
         --显示自己在好友中的排名
         StrServer = GamePrecedure:getInstance():getServerNameById(tonumber(UserInfo.serverId));
         FBMyRankAmongFriends = contentId;
         local lb2Str = {
		      mYouRankAmongFriends = common:getLanguageString('@FBRankDescription',FBMyRankAmongFriends)
	      }
	     NodeHelper:setStringForLabel(FacebookFriendPage.container, lb2Str)
         --显示自己在好友中的排名
    end

    local lb2Str = {
		mFBname 		= FriendInfo.fbname,
		mFBFriendNum 		= tostring(contentId),
		mServerName		= common:getLanguageString('@FBRankSeverName', StrServer),
		mLevel 	= common:getLanguageString('@FBRankLevel', FriendInfo.level),
		mPower 			=common:getLanguageString('@FBRankPower', FriendInfo.fightValue),
        mArenaRank  =StrRank,
        mVipLevel   = common:getLanguageString('@FBRankVip', FriendInfo.vip),
		}
	NodeHelper:setStringForLabel(container, lb2Str);
   
    if FriendInfo.bIsAlreadyAsk then -- 已经索取过了 按钮置灰 改变title
        FacebookFriendPage:EnableButton(container);
    end
end
function FacebookFriendPage:EnableButton(container)
    NodeHelper:setMenuItemEnabled(container,"mLikeImage",false);
    local strMap = {
        mLikeButtonTxt = common:getLanguageString('@liked'),
    };
    NodeHelper:setStringForLabel(container, strMap)
end
function FacebookFriendPage:onRequestData(container)
	if Golb_Platform_Info.is_r2_platform then
		if #FBFriendList > 0 then
			local msg = Friend_pb.HPFriendListFaceBook()
            for i=2, #FBFriendList do
                local info;
                FriendInfo = FBFriendList[i];
				info = tostring(FriendInfo.uid)
                info = info.."$"..tostring(FriendInfo.fbid)
                
			    msg.idinfo:append(tostring(info))
		    end
            local pb = msg:SerializeToString()
            --local pb = msg:SerializePartialToString()
 
            PacketManager:getInstance():sendPakcet(hp.FRIEND_LIST_FACEBOOK_C, pb, #pb, true)
        end
    end
end
function FacebookFriendPage:OnTestData(container)

    FBFriendList = {}

--    for i=1, 8 do 
--        local randomTitleNum = math.random(1000);
--	    local randomNameNum = math.random(1500);
--        local num000 = math.random(100);
--        local vip000 = math.random(15);

--        FBFriendList[i].fbname = "name"..i;
--        FBFriendList[i].fbid = randomNameNum;
--        FBFriendList[i].fburl = "http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?.png";
--        FBFriendList[i].bIsMine = false;
--        FBFriendList[i].uid = "R2_"..i;
--        FBFriendList[i].bIsAlreadyAsk = false;--是否已经向此好友索取过礼物
--    end

    FBFriendList =	{{
		fbname="房海瑞",				
		fbid="556234",
		fburl="http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?.png",		
		bIsMine = false,		
		uid = "R2_1",
        bIsAlreadyAsk = false,
		},
		{
		fbname="名字2",				
		fbid="556212",
		fburl="http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?.png",		
		bIsMine = false,		
		uid = "R2_"..2,
        bIsAlreadyAsk = false,
		},{
		fbname="名字3",				
		fbid="556234",
		fburl="http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?.png",		
		bIsMine = false,		
		uid = "R2_"..3,
        bIsAlreadyAsk = false,
		},{
		fbname="名字5",				
		fbid="556234",
		fburl="http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?.png",		
		bIsMine = false,		
		uid = "R2_"..5,
        bIsAlreadyAsk = false,
		},{
		fbname="名字4",				
		fbid="556234",
		fburl="http:\\/\\/graph.facebook.com\\/1392863614365930\\/picture?.png",		
		bIsMine = false,		
		uid = "R2_"..4,
        bIsAlreadyAsk = false,
		},}



    local function sortNormalFriend(friendList)
		table.sort(friendList,
			function ( e1, e2 )
				if not e2 then return true end
				if not e1 then return false end				
				if e1.arenaRank == -1 and e2.arenaRank>0 then return false end
				if e2.arenaRank == -1 and e1.arenaRank>0 then return true end
				
				if e1.fightValue > e2.fightValue then
					return true
				elseif e1.fightValue < e2.fightValue then
					return false
				else 
					if e1.arenaRank < e2.arenaRank then
						return true
					else
						return false
					end
				end
			end
		);
	end
	local function setFriendList(msg)
		local friendList = {}
		for k,v in ipairs(msg) do
			local info = {}
			info.lastserver = v.lastserver
			info.level = v.level
			info.fightValue = v.fightValue
			info.arenaRank = v.arenaRank
			info.vip = v.vip
			info.uid = v.uid

			friendList[#friendList + 1] = info
		end
		return friendList
	end

    local friendList = {};

--    for i=1, 8 do 
--        local randomTitleNum = math.random(1000);
--	    local randomNameNum = math.random(1500);
--        local num000 = math.random(100);
--        local vip000 = math.random(15);

--        friendList.lastserver = "Server"..i;
--        friendList.level = i+num000;
--        friendList.fightValue = randomTitleNum+randomNameNum;
--        friendList.arenaRank = num000;
--        friendList.vip = vip000
--        friendList.uid = "R2_"..i
--    end
    friendList =	{{
		lastserver="SV_1",				
		level=25,
		fightValue=325000,		
		arenaRank = 15,		
		uid = "R2_1",
        vip = 10,
		},
		{
		lastserver="SV_2",				
		level=28,
		fightValue=1322,		
		arenaRank = 12,		
		uid = "R2_2",
        vip = 13,
		},{
		lastserver="SV_3",				
		level=24,
		fightValue=12650,		
		arenaRank = 10,		
		uid = "R2_3",
        vip = 10,
		},{
		lastserver="SV_4",				
		level=65,
		fightValue=9553,		
		arenaRank = 10,		
		uid = "R2_4",
        vip = 15,
		},{
		lastserver="SV_5",				
		level=78,
		fightValue=9553,		
		arenaRank = 11,		
		uid = "R2_5",
        vip = 8,
		},}
    for i=1, #(friendList) do  --遍历server返回的信息，根据uid去sdk 好友列表中中去找对应的 fburl fbname信息
        local tempinfo = friendList[i];

        if i == 1 then--第一个信息是自己的 插入自己的信息
            friendList[i].fbname = FBFriendList[i].fbname;
            friendList[i].fbid = FBFriendList[i].fbid;
            friendList[i].fburl = FBFriendList[i].fburl;
            friendList[i].bIsMine = FBFriendList[i].bIsMine;
        else
            for k=1, #(FBFriendList) do  
                local  uid = FBFriendList[k].uid;
                if tempinfo.uid == uid then
                    friendList[i].fbname = FBFriendList[k].fbname;
                    friendList[i].fbid = FBFriendList[k].fbid;
                    friendList[i].fburl = FBFriendList[k].fburl;
                    friendList[i].bIsMine = FBFriendList[k].bIsMine;
                    friendList[i].bIsAlreadyAsk = false;

--                    if #AskTicketList > 0 then
--                        for j=1, #(AskTicketList) do  
--                            if tempinfo.uid == AskTicketList[j]then
--                                friendList[i].bIsAlreadyAsk = true;
--                                break
--                            end
--                        end  
--                    end
                    break
                end
            end 
        end
    end 
    friendList[1].bIsMine = true;
    friendList[3].bIsAlreadyAsk = true;--是否已经向此好友索取过礼物
    friendList[4].bIsAlreadyAsk = true;--是否已经向此好友索取过礼物
    sortNormalFriend(friendList)
    FinalFBFriendList = friendList;
    --显示索取进度
    --FBCurAskTimes = #AskTicketList
    FBCurAskTimes = 3
    local lb2Str = {
        mTimes = common:getLanguageString('@FBAskTimes',FBCurAskTimes)
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    --显示索取进度
	--self:rebuildAllItem(container)
	self:refreshPage(container)
end
function FacebookFriendPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	local function sortNormalFriend(friendList)
		table.sort(friendList,
			function ( e1, e2 )
				if not e2 then return true end
				if not e1 then return false end				
				if e1.arenaRank == -1 and e2.arenaRank>0 then return false end
				if e2.arenaRank == -1 and e1.arenaRank>0 then return true end
				
				if e1.fightValue > e2.fightValue then
					return true
				elseif e1.fightValue < e2.fightValue then
					return false
				else 
					if e1.arenaRank < e2.arenaRank then
						return true
					else
						return false
					end
				end
			end
		);
	end
	local function setFriendList(msg)
		local friendList = {}
		for k,v in ipairs(msg) do
			local info = {	}
			info.lastserver = v.lastserver
			info.level = v.level
			info.fightValue = v.fightValue
			info.arenaRank = v.arenaRank
			info.vip = v.vip
			info.uid = v.uid

			friendList[#friendList + 1] = info
		end
		return friendList
	end
    if opcode == HP_pb.FRIEND_LIST_FACEBOOK_S then
		local msg = Friend_pb.HPFriendListFaceBookRet()
		msg:ParseFromString(msgBuff)
		if msg then
			local friendList = setFriendList(msg.friendItem)
            local AskTicketList = msg.askTicketList
            
            for i=1, #(friendList) do  --遍历server返回的信息，根据uid去sdk 好友列表中中去找对应的 fburl fbname信息
              local tempinfo = friendList[i];

               if i == 1 then--第一个信息是自己的 插入自己的信息
                    friendList[i].fbname = FBFriendList[i].fbname;
                    friendList[i].fbid = FBFriendList[i].fbid;
                    friendList[i].fburl = FBFriendList[i].fburl;
                    friendList[i].bIsMine = FBFriendList[i].bIsMine;
               else
                   for k=1, #(FBFriendList) do  
                      local  uid = FBFriendList[k].uid;
                      if tempinfo.uid == uid then
                            friendList[i].fbname = FBFriendList[k].fbname;
                            friendList[i].fbid = FBFriendList[k].fbid;
                            friendList[i].fburl = FBFriendList[k].fburl;
                            friendList[i].bIsMine = FBFriendList[k].bIsMine;
                            friendList[i].bIsAlreadyAsk = false;

                            if #AskTicketList > 0 then
                                for j=1, #(AskTicketList) do  
                                    if tempinfo.uid == AskTicketList[j]then
                                        friendList[i].bIsAlreadyAsk = true;
                                        break
                                    end
                                end  
                            end
                         break
                      end
                   end 
               end
            end 
            
            sortNormalFriend(friendList)
            FinalFBFriendList = friendList;
            --显示索取进度
            FBCurAskTimes = #AskTicketList
            local lb2Str = {
                mTimes = common:getLanguageString('@FBAskTimes',FBCurAskTimes)
            }
            NodeHelper:setStringForLabel(container, lb2Str)
            --显示索取进度
			--self:rebuildAllItem(container)
			self:refreshPage(container)
		end
    elseif opcode == HP_pb.FRIEND_ASK_TICKET_S then --收包 当前索取的次数
		local msg = Friend_pb.HPFriendAskTicketRet()
		msg:ParseFromString(msgBuff)
        if msg then
            local count = msg.count;--当前已经索取的次数
            FBCurAskTimes = tonumber(count)
            if FBLastPressContent~=nil then--置灰这个conten的按钮并且更换title文字
                 self:EnableButton(FBLastPressContent);
                 FBLastPressContent = nil;
                 MessageBoxPage:Msg_Box_Lan("@AskTicketTips")
            else
            --succeed
            end
            local lb2Str = {
		        mTimes = common:getLanguageString('@FBAskTimes',FBCurAskTimes)
	        }
	       NodeHelper:setStringForLabel(container, lb2Str)
        end
	end
	
end


function FacebookFriendPage:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function FacebookFriendPage:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function FacebookFriendPage:buildItem(container)
	local ccbFile = "FB_RankContent.ccbi"
	local size =  #FinalFBFriendList

	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
	local fOneItemWidth = 0	
	--totolSize = 6
	for i=size, 1,-1 do
		local pItemData = CCReViSvItemData:new_local()		
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)
		
		if iCount < iMaxNode then
			local pItem = ScriptContentBase:create(ccbFile)			
			pItem.id = iCount
			pItem:registerFunctionHandler(FacebookFriendPage.onFunction)
			if fOneItemHeight < pItem:getContentSize().height then
				fOneItemHeight = pItem:getContentSize().height
			end
			
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end
	
	local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount)
	container.mScrollView:setContentSize(size)	
	container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))	
	
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView:forceRecaculateChildren();
end

function FacebookFriendPage:onClose(container)
   
	PageManager.popPage(thisPageName)
end
--帮助页面
function FacebookFriendPage:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_FBFRIEND_SHOP)
end
function FacebookFriendPage:onInvite(container)
   platformInfo = PlatformRoleTableManager:getInstance():getPlatformRoleByName(GamePrecedure:getInstance():getPlatformName());
   local InvildMsg = platformInfo.FbInvitePic.."$"..platformInfo.FbInviteUrl ;--图片地址+推送地址
   local strtable = {
        pic = platformInfo.FbInvitePic,
        url = platformInfo.FbInviteUrl,
    }
    local JsMsg  = cjson.encode(strtable)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_Invild_Friend",JsMsg)
end
local CommonPage = require('CommonPage')
local FacebookFriendPage= CommonPage.newSub(FacebookFriendPage, thisPageName, option)
