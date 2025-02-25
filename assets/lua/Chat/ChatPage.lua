----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Chat_pb = require "Chat_pb"
local HP_pb = require "HP_pb"
local Const_pb = require "Const_pb"
local UserInfo = require("PlayerInfo.UserInfo")
local ChatManager = require("Chat.ChatManager")
local VoiceChatManager = require("Battle.VoiceChatManager")
local ChatFacePage = require("ChatFacePage")
local OSPVPManager = require("OSPVPManager")
local CommTabStorage = require("CommComp.CommTabStorage")


local chatBgSize = nil
local htmlWidth = nil
local selfCellSize = nil
local otherCellSize = nil
local chatContentSize = nil
local chatContentDifference = 140
local isDefference = false
local cellSpacing = 25
local ChatPage = {
    redPoint = { },
    cellList = { },
    mPrivateChatItems = { }
}

local thisPageName = "ChatPage"

local g_nLimitNum = 120;--  字符个数限制
local isSelfSendMsg = false -- 自己是否发言，自己发言后，聊天内容自动定位到最后一行
local UserTypeContent = nil
local chatNodeDefaultPosX, chatNodeDefaultPosY = 0, 0
local chatLableDefaultPosX, chatLableDefaultPosY = 0, 0
local option = {
    ccbiFile = "ChatPage.ccbi",
    handlerMap =
    {
        onReturnBtn = "onReturnBtn",
        onExpressionBtn = "onFace",
        onMsgSend = "onMsgSend",
        onChatContent = "onChatContent",
        onClose = "onFace",
        onChatBtn1 = "onWorldChannel",
        onChatBtn2 = "onGuildChannel",
        onChatBtn3 = "onPrivateChannel",
        onChatBtn4 = "onCrossChannel",
        onHelp = "onHelp",
        luaInputboxEnter = "onInputboxEnter",
        luaonCloseKeyboard = "DownChatNode",
        luaOnKeyboardHightChange = "UpChatNode",
        onChatFrameBtn = "onChatFrameBtn",
        onSelectChat = "onSelectChat"
    },
    opcodes =
    {
    },
}
local currentChanel = Const_pb.CHAT_WORLD

ChatPage.editBox = nil

local chatSkinCfg = { }

local chatSkinCD = 2
local chatSkinClickTime = 0

local ChatPrivatePlayerItem = { }
local initialChatViewSize = nil
local myContain

--[[ 底下分頁列 (應該僅有返回鍵功能) ]]
local commTabStorage = nil

-----------------------------------------------
local mercenaryHeadContent = {
    ccbiFile = "FormationTeamContent.ccbi"
}
function mercenaryHeadContent:refreshItem(container,Info,isSys)
    self.container = container
    UserInfo = require("PlayerInfo.UserInfo")
    local roleIcon = ConfigManager.getRoleIconCfg()
    local trueIcon = Info[8] or UserInfo.playerInfo.headIcon
    if isSys then
        trueIcon = 1000
    end
    if not roleIcon[trueIcon] then
        local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
        if NodeHelper:isFileExist(icon) then
            NodeHelper:setSpriteImage(container, { mHead = icon })
        end
        --NodeHelper:setSpriteImage(container, { mHeadFrame = GameConfig.MercenaryBloodFrame[1] })
        if isSys then
            NodeHelper:setNodesVisible(container,{mLvNode = false})
        else
            NodeHelper:setStringForLabel(container, { mLv = Info[3] })
        end
    else
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[trueIcon].MainPageIcon })
        if isSys then
            NodeHelper:setNodesVisible(container,{mLvNode = false})
        else
            NodeHelper:setStringForLabel(container, { mLv = Info[3] })
        end
    end

    NodeHelper:setNodesVisible(container, { mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false, 
                                            mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false })
end
-----------------------------------------------
function ChatPage:onEnter(container)
    --私聊聊天记录修改
    if isSaveChatHistory then
        ChatManager.resetChatRecordList()
        ChatManager.getChatPrivatePersonListRecord()
    end
    NodeHelper:setNodesVisible(container, { mHelpNode = false })
     --NodeHelper:setNodesVisible(container, { mExpressionBtnNode = true })
    --NodeHelper:setNodesVisible(container, { mExpressionBtnNode = Golb_Platform_Info.is_win32_platform })
    selfCellSize = CCSizeMake(680, 55)
    otherCellSize = CCSizeMake(680, 80)

    -- chatBgSize = CCSizeMake(60, 61)
    chatBgSize = CCSizeMake(53, 49)
    cellSize = CCSizeMake(680, 80)
    self.container = container
    myContain = container

    -- 分頁列
    self.commTabStorage = CommTabStorage:new()
    local commTabStorageContainer = self.commTabStorage:init({})
    container:addChild(commTabStorageContainer)
    self.commTabStorage:setTitle(common:getLanguageString("@Chat"))
    self.commTabStorage:setTitleVisible(false) -- 若 原UI已經有 標題 則 關閉 分頁列中標題
    self.commTabStorage:setCurrencyDatas({})

    self.mPrivateNode = container:getVarNode("mPrivateNode")
    self.mPrivateNode:setVisible(false)
    -- NodeHelper:autoAdjustResetNodePosition(self.mPrivateNode)
    self.mPrivateChatContentScrollview = container:getVarScrollView("mPrivateChatContent")
    self:setFaceVisible(container, false)

    self.scrollview = container:getVarScrollView("mChatContent")



    self.scrollview:registerScriptHandler(self, CCScrollView.kScrollViewScrollEnd)
    self.chatLableHintNode = container:getVarNode("mChatLabeHint")
    self.chatLableNode = container:getVarNode("mChatLabe")
    chatLableDefaultPosX = self.chatLableNode:getPositionX()
    chatLableDefaultPosY = self.chatLableNode:getPositionY()
    self.redPoint[Const_pb.CHAT_WORLD] = container:getVarNode("mChatBtnPoint1")
    self.redPoint[Const_pb.CHAT_ALLIANCE] = container:getVarNode("mChatBtnPoint2")
    self.redPoint[Const_pb.CHAT_PERSONAL] = container:getVarNode("mChatBtnPoint3")
    self.redPoint[Const_pb.CHAT_CROSS_PVP] = container:getVarNode("mChatBtnPoint4")
    self.redPoint[Const_pb.CHAT_WORLD]:setVisible(false)
    self.redPoint[Const_pb.CHAT_CROSS_PVP]:setVisible(false)
    self.redPoint[Const_pb.CHAT_ALLIANCE]:setVisible(false)
    self.redPoint[Const_pb.CHAT_PERSONAL]:setVisible(false)
    hasNewChatComing = false
    NoticePointState.isChange = true

    --NodeHelper:autoAdjustResizeScrollview(self.scrollview)
    --NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite"))
    NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@ChatTitle") })
    NodeHelper:setNodesVisible(container, { mTitle = true, mTitle_1 = false })
    NodeHelper:setNodesVisible(container, { mChatBtnNode4 = false })
    -- 跨服聊天先关了

    chatContentSize = self.scrollview:getContentSize()

    initialChatViewSize = self.scrollview:getViewSize()

    chatSkinCfg = ConfigManager.getChatSkinCfg()

    htmlWidth = self.scrollview:getViewSize().width *0.93

    self.btnNode = container:getVarNode("mBtmNode")

    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container:registerPacket(HP_pb.MESSAGE_LIST_S)

    currentChanel = Const_pb.CHAT_WORLD
    if GameConfig.guildJumpChat.isGuildJump or GameConfig.guildJumpChat.isRetuGuild then
        currentChanel = Const_pb.CHAT_ALLIANCE
    end
    if BlackBoard:getInstance():hasVarible("PrivateChat") then
        -- local channel = BlackBoard:getInstance():getVarible("PrivateChat")
        currentChanel = Const_pb.CHAT_PERSONAL
        self:onPrivateChannel(container)
        BlackBoard:getInstance():delVarible("PrivateChat")
    elseif currentChanel == Const_pb.CHAT_ALLIANCE then
        self:onGuildChannel(container)
        self:switchChatChanel(container)
    else
        self:onWorldChannel(container)
        self:switchChatChanel(container)
    end

    self:setMenuSelect(container, currentChanel)

    NodeHelper:mainFrameSetPointVisible( { mChatPoint = false, })

    NodeHelper:setNodesVisible(container, { mChatFramePoint = hasNewChatSkin })

    self:registerKeyboard(container)

    if not curSkinId then
        common:sendEmptyPacket(HP_pb.CHAT_SKIN_OWNED_INFO_C, false)
    end

    if GameConfig.isIOSAuditVersion then
        NodeHelper:setNodesVisible(container, { mChatBtnNode3 = false })
    end
    NodeHelper:setNodesVisible(container, { mChatBtnNode2 = true, mChatBtnNode3 = true, mChatBtnNode4 = false })
    -- ChatFacePage:init(container,ChatPage)
    local relativeNode = container:getVarNode("mExpressNode")
    local faceNode = container:getVarNode("mExpressionNode")
    GameUtil:clickOtherClosePage(relativeNode, function ()
        if not faceNode then return end
        
        local isVisible = faceNode:isVisible()
        if isVisible then
            faceNode:setVisible(not isVisible)
        end
    end, container)

--[[    local tmpCount = CCUserDefault:sharedUserDefault():getIntegerForKey("ChatPage"..UserInfo.playerInfo.playerId);
    if tmpCount == 0 then
        CCUserDefault:sharedUserDefault():setIntegerForKey("ChatPage"..UserInfo.playerInfo.playerId, 1);
    end]]

    container.mMainScrollView = container:getVarScrollView("mMainContent")
    container.mChatScrollView = container:getVarScrollView("mChatContent")
    -- scrollview, 背景自適應
    local scale9Sprite = container:getVarScale9Sprite("mBg")
    local scale9Sprite2 = container:getVarScale9Sprite("mChatBg")
    NodeHelper:autoAdjustResizeScale9Sprite(scale9Sprite)
    NodeHelper:autoAdjustResizeScale9Sprite(scale9Sprite2)
    NodeHelper:autoAdjustResizeScrollview(container.mMainScrollView)
    NodeHelper:autoAdjustResizeScrollview(container.mChatScrollView)
end


function ChatPage:quitPrivateNode(container)
    self.mPrivateChatContentScrollview:removeAllCell()
    self.mPrivateNode:setVisible(false)
    self.mPrivateChatItems = { }
end
function ChatPage:checkChatRecordIsExist()
    local isErr = false
    --检查，如果聊天记录被删除，那么从列表中删除
    for i=1,#ChatManager.chatPrivatePersonList do
        if not ChatManager.getPersonalInfo(ChatManager.chatPrivatePersonList[i]) then
            table.remove(ChatManager.chatPrivatePersonList,i)
            isErr = true
            break;
        end
    end
    if isErr then--如果聊天记录出错，重新继续检测
        isErr = false
        ChatPage:checkChatRecordIsExist()
    end
end

function ChatPage:initPrivateNode(container)
    self:checkChatRecordIsExist()
    self:quitPrivateNode(container)
    self.mPrivateNode:setVisible(true)
    local chatCount = common:table_count(ChatManager.msgBoxList)
    local currWidth = 0
    local fOneItemHeight = 0
    local count = 0
    -- 先找到选择的人  放到第一个
    for i, v in pairs(ChatManager.msgBoxList) do
        if ChatManager.curChatPerson.chatUnit.playerId == v.chatUnit.playerId then
            local cellCCB = CCBFileCell:create()
            cellCCB:setCCBFile("ChatPrivatePlayerItem.ccbi")
            local panel = ChatPrivatePlayerItem:new { value = v, tag = v.chatUnit.playerId,idx = i }
            cellCCB:registerFunctionHandler(panel)
            cellCCB:setPosition(ccp(currWidth, 0))
            cellCCB:setTag(v.chatUnit.playerId)
            currWidth = currWidth + cellCCB:getContentSize().width
            self.mPrivateChatContentScrollview:addCell(cellCCB)
            ChatPage.mPrivateChatItems[cellCCB:getTag()] = panel
            if fOneItemHeight < cellCCB:getContentSize().height then
                fOneItemHeight = cellCCB:getContentSize().height
            end
            count = count + 1
        end
    end

    for i, v in pairs(ChatManager.msgBoxList) do
        if ChatManager.curChatPerson.chatUnit.playerId ~= v.chatUnit.playerId then
            local cellCCB = CCBFileCell:create()
            cellCCB:setCCBFile("ChatPrivatePlayerItem.ccbi")
            local panel = ChatPrivatePlayerItem:new { value = v, tag = v.chatUnit.playerId }
            cellCCB:registerFunctionHandler(panel)
            cellCCB:setPosition(ccp(currWidth, 0))
            cellCCB:setTag(v.chatUnit.playerId)
            currWidth = currWidth + cellCCB:getContentSize().width
            self.mPrivateChatContentScrollview:addCell(cellCCB)
            ChatPage.mPrivateChatItems[cellCCB:getTag()] = panel
            if fOneItemHeight < cellCCB:getContentSize().height then
                fOneItemHeight = cellCCB:getContentSize().height
            end
            count = count + 1
        end
    end

    local size = CCSizeMake(currWidth, fOneItemHeight)
    self.mPrivateChatContentScrollview:setContentSize(size)
    self.mPrivateChatContentScrollview:refreshAllCell()
    self.mPrivateChatContentScrollview:setContentOffset(ccp(0, 0))

    if count < 5 then
        self.mPrivateChatContentScrollview:setTouchEnabled(false)
    else
        self.mPrivateChatContentScrollview:setTouchEnabled(true)
    end

end

function ChatPage:onExecute(container)
    if chatSkinClickTime > 0 then
        if os.time() - chatSkinClickTime >= chatSkinCD then
            chatSkinClickTime = 0
        end
    end
end

function ChatPage:onExit(container)
    GameConfig.guildJumpChat.isGuildJump = false
    GameConfig.guildJumpChat.isRetuGuild = false
    self.scrollview:unregisterScriptHandler(CCScrollView.kScrollViewScrollEnd)
    self.scrollview:removeAllCell()
    ChatPage.cellList = { }
    NodeHelper:deleteScrollView(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container:removePacket(HP_pb.MESSAGE_LIST_S)
    --私聊聊天记录修改
    if isSaveChatHistory then
        ChatManager.saveAllPrivatePersonChatRecord()
    end

    debugPage[thisPageName] = true
    onUnload(thisPageName, container)
end

function ChatPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        local GVGManager = require("GVGManager")
        if pageName == thisPageName then
            if extraParam == "PrivateChat" then
                self:onPrivateChannel(container)
            elseif extraParam == "HasNewSkin" then
                NodeHelper:setNodesVisible(container, { mChatFramePoint = hasNewChatSkin })
            else
                local param = common:split(extraParam, "%.")
                if #param == 0 then return end
                local channelName = param[1]
                local newMsgNum = tonumber(param[2])
                if not channelName or not newMsgNum then return end

                if channelName == "worldChat" then
                    self:insertChatChannel(Const_pb.CHAT_WORLD, newMsgNum)
                elseif channelName == "RemovePrivateChat" then
                    self:removePrivateChat(container, tonumber(newMsgNum))
                elseif channelName == "guildChat" then
                    self:insertChatChannel(Const_pb.CHAT_ALLIANCE, newMsgNum)
                    ChatManager.refreshMainNewChatPointTips()
                elseif channelName == "crossChat" then
                    self:insertChatChannel(Const_pb.CHAT_CROSS_PVP, newMsgNum)
                elseif channelName == "privateChat" then
                    if currentChanel == Const_pb.CHAT_PERSONAL then--
                        if ChatManager.curChatPerson == nil then

                        else
                            if tonumber(param[3]) == ChatManager:getCurrentChatId() or param[3] == ChatManager:getCurrentChatId() then
                                self:insertChatChannel(Const_pb.CHAT_PERSONAL, 1)
                            else
                                --私聊聊天记录修改
                                if isSaveChatHistory then
                                    self.redPoint[Const_pb.CHAT_PERSONAL]:setVisible(false)
                                    local reCreateList = ChatManager.insertSortChatPrivate(tonumber(param[3]),true)
                                    if reCreateList then--重新创建列表
                                        self:onPrivateChannel(container)
                                    else
                                        if container.pScrollviewTitle then
                                            container.pScrollviewTitle:refreshAllCell()
                                        end
                                    end

                                else
                                    self:onPrivateChannel(container)
                                end
                            end
                            --私聊聊天记录修改
                            if isSaveChatHistory then
                                if ChatManager.isChangePlayerNameFlag then--有名字更改,重新刷新一下
--[[                                    if container.pScrollviewTitle then
                                        container.pScrollviewTitle:refreshAllCell()
                                    end
                                    if self.pScrollview then
                                        self.pScrollview:refreshAllCell()
                                    end]]
                                    --ChatPersonalRecord:firstInfoUpdate(container)
                                    ChatManager.isChangePlayerNameFlag = false
                                end
                            end
                        end
                    else
                        self.redPoint[Const_pb.CHAT_PERSONAL]:setVisible(false)
                    end
                    ChatManager.refreshMainNewChatPointTips()
                end
            end
        elseif pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onMapInfo then
                if GVGManager.isGVGPageOpen then
                    --PageManager.changePage("GVGMapPage")
                end
            end
        elseif pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onLocalPlayerInfo then
                if self.scrollview then
                    self.scrollview:refreshAllCell()
                end
            end
        end
    end
end

function ChatPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    -- 私聊拉取离线消息回包
    if opcode == HP_pb.MESSAGE_LIST_S then
        local msg = Friend_pb.HPMsgListInfo();
        msg:ParseFromString(msgBuff)
        if msg ~= nil then
            --私聊聊天记录修改
            if isSaveChatHistory then
                local uniquePlayerId = nil
                ChatManager.setOfflineMsgFlag(uniquePlayerId,false)
                for i=1,#msg.friendMsgs do
                    local oneData = msg.friendMsgs[i]
                    --offline msg push
                    if oneData~=nil then
                        local identify = oneData.senderId
                        if oneData:HasField("senderIdentify") then
                            identify = oneData.senderIdentify
                            if identify == "" then
                                identify = oneData.senderId
                            end
                        end
                        uniquePlayerId = identify
                        ChatManager.setOfflineMsgFlag(identify,false)
                        ChatManager.insertPrivateMsg(identify,nil,oneData,false,false)
                    end
                end
                if #msg.friendMsgs > 0 and uniquePlayerId and ChatManager.msgBoxList[uniquePlayerId] and ChatManager.msgBoxList[uniquePlayerId].msgList then
                    table.sort(ChatManager.msgBoxList[uniquePlayerId].msgList,function(a,b)
                        if a.msTime and b.msTime then
                            if a.msTime == b.msTime  then
                                return false
                            end
                            return a.msTime < b.msTime
                        end
                        return false
                    end)
                end
                if #msg.friendMsgs > 0 then
                    ChatPage:showPrivatePage(container)
                end
                return
            end
            -------------
            for i = 1, #msg.friendMsgs do
                local oneData = msg.friendMsgs[i]
                -- offline msg push
                if oneData ~= nil then
                    local identify = oneData.senderId
                    if oneData:HasField("senderIdentify") then
                        identify = oneData.senderIdentify
                        if identify == "" then
                            identify = oneData.senderId
                        end
                    end
                    ChatManager.insertPrivateMsg(identify, nil, oneData, false)
                end
            end
            if #msg.friendMsgs > 0 then
                ChatPage:showPrivatePage(container)
            end
        else
            CCLuaLog("@onReceiveOfflineMessageBox -- error in data")
        end
    end
end

-- 当前页面如果有新消息，在滑动到底部的时候，隐藏红点
function ChatPage:scrollViewDidDeaccelerateStop(scrollview)
    if scrollview then
        if currentChanel == Const_pb.CHAT_WORLD then
            hasNewWorldChatComing = false
        elseif currentChanel == Const_pb.CHAT_ALLIANCE then
            hasNewMemberChatComing = false
        elseif currentChanel == Const_pb.CHAT_PERSONAL then
            hasNewCrossChatComing = false
        end
        if self.redPoint[currentChanel] then
            self.redPoint[currentChanel]:setVisible(false)
        end
    end
end

function ChatPage:addFaceToInputContent(chatFace)
    self:onFace(self.container)
    if not chatFace then return end
    if UserTypeContent == nil then
        UserTypeContent = ""
    end
    local _, additionalNum = VoiceChatManager.handlerChatFace(UserTypeContent)
    local length = GameMaths:calculateStringCharacters(UserTypeContent)
    if length < 20 + additionalNum then
        UserTypeContent = UserTypeContent .. chatFace
    else

    end
    -- self.container:getVarLabelTTF("mChatLabe"):setString(UserTypeContent)
    NodeHelper:setStringForLabel(self.container, { mChatLabe = UserTypeContent, mChatLabe = UserTypeContent, mChatLabeHint = "" })
    if self.editBox then
        self.editBox:setText(UserTypeContent)
    end
end
function ChatPage_SetIsGuildJump(isJump,isReGuild)
    GameConfig.guildJumpChat.isGuildJump = isJump
    GameConfig.guildJumpChat.isRetuGuild = isReGuild
end
------------------------------------------------------

function ChatPage:onReturnBtn(container)
    if GameConfig.guildJumpChat.isGuildJump and GameConfig.guildJumpChat.isRetuGuild then
        GameConfig.guildJumpChat.isGuildJump = false
        GameConfig.guildJumpChat.isRetuGuild = false
        require("Guild.GuildData")
        PageManager.changePage("GuildPage")
        GuildPage_setIsJump(true,false)
    else
        MainFrame_onMainPageBtn()
    end

end

function ChatPage:onHelp(container)
    local ConfigManager = require("ConfigManager")
    local serverCfg = ConfigManager.getOSPVPServerCfg()
    local selfGroup
    for k, v in pairs(serverCfg) do
        if common:table_hasValue(v.servers, UserInfo.serverId) then
            selfGroup = common:deepCopy(v.servers)
            break
        end
    end
    local str = ""
    if not selfGroup then
        str = common:getLanguageString("@OSPVPNoServerGroup")
    else
        common:table_map(selfGroup, function(v)
            local serverName = GamePrecedure:getInstance():getServerNameById(v);
            return common:getLanguageString("@PVPServerName", serverName)
        end )
        str = table.concat(selfGroup)
    end
    local HelpConfg = ConfigManager.getHelpCfg(GameConfig.HelpKey.HELP_CROSS_CHAT)
    local content = common:fill(HelpConfg[1].content, str)
    PageManager.showHelp("", nil, false, content)
end

function ChatPage:onFace(container)
    if container.mScrollView == nil then
        --ChatFacePage:init(container, ChatPage)
    end
    local faceNode = container:getVarNode("mExpressionNode")
    if faceNode then
        local isVisible = faceNode:isVisible()
        faceNode:setVisible(not isVisible)
    end
end

function ChatPage:registerKeyboard(container)
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
        local node = container:getVarNode("mChatLabe")
        local sizeHeight = 40
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width, height = visibleSize.width, visibleSize.height
        CCLuaLog("width ----" .. width .. "---height---" .. height)
        --MessageBoxPage:Msg_Box("--width--"..width.."--height--"..height)
        if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
            CCLuaLog("width ----" .. width .. "---height---" .. height)
            --MessageBoxPage:Msg_Box("--width--"..width.."--height--"..height)
            if (width == 1125 and height == 2280) then
                -- iphoneX  由于安全区域的问题 分辨率有所变化 -- 1125 2436
                sizeHeight = 180
            elseif (width == 1242 and height == 2520) then  --1242  2688
                -- iphoneXSMax
                sizeHeight = 160
            elseif (width == 828 and height == 1680) then   -- 828  1792
                -- iphoneXR
                sizeHeight = 130
            end
        end
        ChatPage.editBox = NodeHelper:addEditBox(CCSize(380, sizeHeight), node, function(eventType)
            if eventType == "began" then
                self:setFaceVisible(container, false)
                -- triggered when an edit box gains focus after keyboard is shown
            elseif eventType == "ended" then
                -- triggered when an edit box loses focus after keyboard is hidden.
            elseif eventType == "changed" then
                if GameMaths:calculateStringCharacters(ChatPage.editBox:getText()) > 12 then
                    ChatPage.editBox:setFontSize(18)
                    -- elseif GameMaths:calculateStringCharacters(ChatPage.editBox:getText()) > 30 then
                    -- ChatPage.editBox:setPosition(ccp(-813,0))
                else
                    ChatPage.editBox:setFontSize(26)
                end
                -- triggered when the edit box text was changed.
            elseif eventType == "return" then
                ChatPage:onEditBoxReturn(ChatPage.editBox, ChatPage.editBox:getText())
                ChatPage.editBox:setPosition(ccp(-189.5, 0))
                -- triggered when the return button was pressed or the outside area of keyboard was touched.
            end
        end , ccp(-189.5, 0), common:getLanguageString("@ChatLabe"))

        ChatPage.editBox:setMaxLength(40)
        local color = StringConverter:parseColor3B("53 17 0")
        ChatPage.editBox:setFontColor(color)
        ChatPage.editBox:setPlaceholderFontColor(color)
        NodeHelper:setMenuItemEnabled(container, "mChatContentText", false)
        container:getVarLabelTTF("mChatLabeHint"):setVisible(false)
    else
        local MiddleFrameNode = container:getVarNode("mSpeakNode")
        if MiddleFrameNode then
            chatNodeDefaultPosX, chatNodeDefaultPosY = MiddleFrameNode:getPosition()
        end
        local contentLabel = container:getVarLabelTTF("mChatLabe")
        contentLabel:setString("")
    end
end

function ChatPage:onChatFrameBtn(container)
    if chatSkinClickTime > 0 then return end
    chatSkinClickTime = os.time()
    showChatSkinPage = true
    hasNewChatSkin = false
    NodeHelper:setNodesVisible(container, { mChatFramePoint = false })
    common:sendEmptyPacket(HP_pb.CHAT_SKIN_OWNED_INFO_C, false)
end

function ChatPage:onSelectChat(container)
    ChatPage:onChatHistory(true)
end

function ChatPage:onEditBoxReturn(editBox, content)
    local nameOK = true
    if GameMaths:isStringHasUTF8mb4(content) then
        nameOK = false
    end

    if content == "" then
        nameOK = false
        UserTypeContent = nil
        editBox:setText("")
        CCLuaLog("ChatFace:------content is empty")
        return
    end

    local length = GameMaths:calculateStringCharacters(content)
    if length > g_nLimitNum then
        -- 提示名字字数
        content = GameMaths:getStringSubCharacters(content, 0, g_nLimitNum)
        MessageBoxPage:Msg_Box_Lan("@ERRORCODE_14006");
        return ;
    end

    if not nameOK then
        editBox:setText("")
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        CCLuaLog("ChatFace:------content is empty:")
        content = nil
        return
    end
    content = RestrictedWord:getInstance():filterWordSentence(content)
    -- 屏蔽敏感字

    
    UserTypeContent = content;
    local lines = 0;
    local width = 40;
    local width2 = 20

    local showtext = content;

    showtext = GameMaths:getStringSubCharacters(showtext, 0, width)

    local str = GameMaths:stringAutoReturnForLua(showtext, width2, lines)
    editBox:setText(tostring(showtext))
    ChatPage.editBox = editBox
end
function ChatPage:onMsgSend(container)

    if currentChanel == Const_pb.CHAT_PERSONAL then
        --if UserInfo.roleInfo.level < 9 then
        --    MessageBoxPage:Msg_Box_Lan("@NoPrivateChatLevelLimit")
        --    return
        --end
        --if ChatManager.getMsgBoxSize() <= 0 then
        --    -- 提示还没有聊天对象
        --    MessageBoxPage:Msg_Box_Lan("@AlreadyCloseChat")
        --    return
        --end
    elseif currentChanel == Const_pb.CHAT_WORLD then
        if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.CHAT_SEND_MESSAGE) then
            MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.CHAT_SEND_MESSAGE))
            return
        end
    end

    if UserInfo.stateInfo.chatClose > 0 then
        MessageBoxPage:Msg_Box_Lan("@AlreadyCloseChat")
        return;
    end
    if UserTypeContent ~= nil and common:trim(UserTypeContent) ~= "" then
        UserTypeContent = RestrictedWord:getInstance():filterWordSentence(UserTypeContent)
        -- 屏蔽敏感字
        UserTypeContent = UserTypeContent:gsub("&", "*")
        UserTypeContent = UserTypeContent:gsub("#", "*")
        UserTypeContent = UserTypeContent:gsub("<", "*")
        UserTypeContent = UserTypeContent:gsub(">", "*")
        UserTypeContent = UserTypeContent:gsub("/", "*")

        if currentChanel == Const_pb.CHAT_PERSONAL then
            local Friend_pb = require("Friend_pb")
            local titleManager = require("PlayerInfo.TitleManager")

            if ChatManager.curChatPerson.chatUnit.senderIdentify and ChatManager.curChatPerson.chatUnit.senderIdentify ~= "" then
                local message = Friend_pb.HPSendCSPersonalMessage()
                message.targetIdentify = ChatManager.curChatPerson.chatUnit.senderIdentify
                message.message = UserTypeContent
                common:sendPacket(HP_pb.CS_PERSONAL_MESSAGE_SEND_C, message, false);
            else
                local message = Friend_pb.HPSendMessage()
                message.targetId = ChatManager.curChatPerson.chatUnit.playerId
                message.message = UserTypeContent
                common:sendPacket(HP_pb.MESSAGE_SEND_C, message, false);
            end

            -- 手动插入msgBox 玩家输入的文字
            local friendMsg = Friend_pb.FriendMsg()
--[[            if Golb_Platform_Info.is_gNetop_platform then

            end]]
            friendMsg.msTime = GamePrecedure:getInstance():getServerTime()
            friendMsg.senderId = UserInfo.playerInfo.playerId
            friendMsg.receiveId = ChatManager.curChatPerson.chatUnit.playerId
            friendMsg.senderName = UserInfo.roleInfo.name
            friendMsg.receiveName = ChatManager.curChatPerson.chatUnit.name
            friendMsg.msgType = Const_pb.PLAYER_MSG
            friendMsg.message = UserTypeContent
            friendMsg.titleId = titleManager.myNowTitleId
            friendMsg.skinId = curSkinId or 0
            local identify = ChatManager.curChatPerson.chatUnit.playerId
            if ChatManager.curChatPerson.chatUnit.senderIdentify and ChatManager.curChatPerson.chatUnit.senderIdentify ~= "" then
                identify = ChatManager.curChatPerson.chatUnit.senderIdentify
            end
            ChatManager.insertPrivateMsg(identify, nil, friendMsg, false, false)
            isSelfSendMsg = true
            self:insertChatChannel(Const_pb.CHAT_PERSONAL, 1)
            -- PageManager.refreshPage("BattlePage","PrivateChat")
        elseif currentChanel == Const_pb.CHAT_ALLIANCE then

            VoiceChatManager.fillPlayerInfo()
            VoiceChatManager.sendMessage(UserTypeContent, currentChanel)
            VoiceChatManager.clearChatMessage()
            isSelfSendMsg = true

        else

            VoiceChatManager.fillPlayerInfo()
            VoiceChatManager.sendMessage(UserTypeContent, currentChanel)
            VoiceChatManager.clearChatMessage()
            isSelfSendMsg = true

        end

        local contentLabel = container:getVarLabelTTF("mChatLabe")
        local label = Language:getInstance():getString("@ChatLabe")
        contentLabel:setString("")
        container:getVarLabelTTF("mChatLabeHint"):setString("")
        UserTypeContent = "";
    else
        MessageBoxPage:Msg_Box_Lan("@PleaseEnterWordFirst")
    end
    if self.editBox then
        self.editBox:setText(UserTypeContent)
    end
end
----------------------------------------------------------------------
function ChatPage:onChatContent(container)
    self:setFaceVisible(container, false)
    if UserTypeContent == nil then
        UserTypeContent = ""
    end
    container:registerLibOS()
    libOS:getInstance():showInputbox(false, UserTypeContent)
end

function ChatPage:onInputboxEnter(container)
    local content = container:getInputboxContent();
    local nameOK = true
    if GameMaths:isStringHasUTF8mb4(content) then
        nameOK = false
    end

    CCLuaLog("ChatFace:------:" .. content .. ":")
    if content == "" then
        nameOK = false
        UserTypeContent = nil
        container:getVarLabelTTF("mChatLabeHint"):setString(common:getLanguageString("@ChatLabe"))
        container:getVarLabelTTF("mChatLabe"):setString("")
        CCLuaLog("ChatFace:------content is empty")
        NodeHelper:cursorNode(container, "mChatLabe", true)
        return
    end
    if not nameOK then
        local contentLabel = container:getVarLabelTTF("mChatLabe");
        local label = Language:getInstance():getString("@ChatLabe")
        container:getVarLabelTTF("mChatLabeHint"):setString(label)
        contentLabel:setString("")
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
        CCLuaLog("ChatFace:------content is empty:" .. label)
        content = nil
        return
    end

     local length = GameMaths:calculateStringCharacters(content);
        if length > g_nLimitNum then
            -- 提示名字字数
            content = GameMaths:getStringSubCharacters(content, 0, g_nLimitNum)
            MessageBoxPage:Msg_Box_Lan("@ERRORCODE_14006");
        end

    content = RestrictedWord:getInstance():filterWordSentence(content)
    -- 屏蔽敏感字
    local contentLabel = container:getVarLabelTTF("mChatLabe");
    if contentLabel ~= nil then
       

        UserTypeContent = content;
        local lines = 0;
        local width = 20;
        local width2 = 20
        -- add
        local showtext = content;
        -- showtext = GameMaths:getStringSubCharacters(showtext,0,width)

        -- local str = GameMaths:stringAutoReturnForLua(showtext,40,lines);
        contentLabel:setString(tostring(showtext));
        local curWidth = contentLabel:getContentSize().width * contentLabel:getScaleX()
        if curWidth > 370 then
            -- local tempchar = GameMaths:getStringSubCharacters(showtext,0,width)
            -- contentLabel:setString(tostring(tempchar));
            local tempW = 370 + chatLableDefaultPosX
            contentLabel:setAnchorPoint(ccp(1, 0.5));
            contentLabel:setString(tostring(showtext));
            contentLabel:setPosition(ccp(tempW, chatLableDefaultPosY))
        else
            contentLabel:setAnchorPoint(ccp(0, 0.5));
            contentLabel:setPosition(ccp(chatLableDefaultPosX, chatLableDefaultPosY))
        end

        container:getVarLabelTTF("mChatLabeHint"):setString("")
    end

    NodeHelper:cursorNode(container, "mChatLabe", true)
end
-- 聊天框弹出相关：弹出 
function ChatPage:UpChatNode(container)
    if container:getKeyboardHight() < 300 then return end
    CCLuaLog("moveChatNode UpChatNode  ")
    local MiddleFrameNode = container:getVarNode("mSpeakNode")
    if MiddleFrameNode == nil then return end
    local hight = container:getKeyboardHight()
    -- 相对于屏幕分辨率 键盘的高度，要转换为游戏逻辑高度
    CCLuaLog("moveChatNode sharedOpenGLView getScaleY = " .. CCEGLView:sharedOpenGLView():getScaleY())
    CCLuaLog("moveChatNode KeyBoard hight = " .. hight)
    hight = hight / CCEGLView:sharedOpenGLView():getScaleY();
    if hight == nil then
        return
    end

    local convertPos = MiddleFrameNode:getParent():convertToNodeSpace(ccp(0, hight));
    if convertPos.y == nil and MiddleFrameNode:getPositionY() == convertPos.y then
        return
    end
    local actionArr = CCArray:create();
    -- actionArr:addObject(CCDelayTime:create(0.1))
    actionArr:addObject(CCMoveTo:create(0.3, ccp(chatNodeDefaultPosX, convertPos.y)))
    MiddleFrameNode:stopAllActions();
    MiddleFrameNode:runAction(CCSequence:create(actionArr));
end
-- 聊天框弹出相关：回收 
function ChatPage:DownChatNode(container)
    CCLuaLog("moveChatNode DownChatNode ")
    local MiddleFrameNode = container:getVarNode("mSpeakNode")
    if MiddleFrameNode == nil then return end
    local actionArr = CCArray:create();
    if MiddleFrameNode:getPositionY() == chatNodeDefaultPosY then
        return
    end
    -- actionArr:addObject(CCDelayTime:create(0.1))
    actionArr:addObject(CCMoveTo:create(0.2, ccp(chatNodeDefaultPosX, chatNodeDefaultPosY)))
    MiddleFrameNode:stopAllActions();
    MiddleFrameNode:runAction(CCSequence:create(actionArr));

    NodeHelper:cursorNode(container, "mChatLabe", true)
    container:removeLibOS()
end
----------------------------------------------------------------------
function ChatPage_onWorldChannel()
    ChatPage:onWorldChannel(myContain)
end
function ChatPage:onWorldChannel(container)

    ChatPage:quitPrivateNode(container)

    NodeHelper:mainFrameSetPointVisible( { mChatPoint = false, })
    self:setMenuSelect(container, Const_pb.CHAT_WORLD)
    if currentChanel == Const_pb.CHAT_WORLD then
        if hasNewWorldChatComing == true then
            hasNewWorldChatComing = false
            self.redPoint[Const_pb.CHAT_WORLD]:setVisible(false)
            self.scrollview:setContentOffset(ccp(0, 0))
        end
        return
    end
    currentChanel = Const_pb.CHAT_WORLD
    hasNewWorldChatComing = false
    self.redPoint[Const_pb.CHAT_WORLD]:setVisible(false)
    self:switchChatChanel(container)
end

function ChatPage:onGuildChannel(container)
    if not AllianceOpen then
        MessageBoxPage:Msg_Box_Lan("@SevenDayQuestDay2Desc")
        self:setMenuSelect(container, currentChanel)
        return
    end
    ChatPage:quitPrivateNode(container)
    NodeHelper:mainFrameSetPointVisible( { mChatPoint = false, })
    self:setMenuSelect(container, Const_pb.CHAT_ALLIANCE)
    if currentChanel == Const_pb.CHAT_ALLIANCE then
        if hasNewMemberChatComing == true then
            hasNewMemberChatComing = false
            self.redPoint[Const_pb.CHAT_ALLIANCE]:setVisible(false)
            self.scrollview:setContentOffset(ccp(0, 0))
        end
        return
    end
    currentChanel = Const_pb.CHAT_ALLIANCE
    hasNewMemberChatComing = false
    self.redPoint[Const_pb.CHAT_ALLIANCE]:setVisible(false)
    self:switchChatChanel(container)
end

function ChatPage:onCrossChannel(container)
    ChatPage:quitPrivateNode(container)
    self:setMenuSelect(container, Const_pb.CHAT_CROSS_PVP)
    if currentChanel == Const_pb.CHAT_CROSS_PVP then
        if hasNewWorldChatComing == true then
            hasNewWorldChatComing = false
            self.redPoint[Const_pb.CHAT_CROSS_PVP]:setVisible(false)
            self.scrollview:setContentOffset(ccp(0, 0))
        end
        return
    end
    currentChanel = Const_pb.CHAT_CROSS_PVP
    hasNewCrossChatComing = false
    self.redPoint[Const_pb.CHAT_CROSS_PVP]:setVisible(false)
    self:switchChatChanel(container)
end

function ChatPage:onPrivateChannel(container)
    MessageBoxPage:Msg_Box(common:getLanguageString("@SevenDayQuestDay2Desc"))
    return
    --if currentChanel ~= Const_pb.CHAT_PERSONAL then
    --    local flag, playerId, identify = ChatManager.hasNewMsgInBox()
    --    if flag then
    --        -- have newMessage
    --        -- 2.1 如果有信息
    --        ChatManager.setCurrentChatPerson(identify or playerId)
    --        ChatManager.readMsg(identify or playerId)
    --        if ChatManager.isOfflineMsg(identify or playerId) then
    --            -- 2.1.1 消息是离线的，需要请求
    --            local Friend_pb = require("Friend_pb")
    --            local msg = Friend_pb.HPMsgList();
    --            msg.playerId = playerId
    --            msg.senderIdentify = identify or ""
    --            common:sendPacket(HP_pb.MESSAGE_LIST_C, msg)
    --        else
    --            -- 2.1.2 消息是在线的，直接进入私聊页面
    --            ChatPage:showPrivatePage(container)
    --        end
    --    else
    --        -- 2.2 如果没有新消息
    --        if ChatManager.getMsgBoxSize() == 0 then
    --            -- 2.2.1 如果当前消息盒子是空，弹出最近聊天页面
    --            ChatPage:onChatHistory(true)
    --        else
    --            -- 2.2.2 如果当前消息盒子不为空
    --            local identify = ChatManager.getCurrentChatId()
    --            --私聊聊天记录修改
    --            if isSaveChatHistory then
    --                if identify then
    --                    if ChatManager.isOfflineMsg(identify) then
    --                        -- 2.1.1 消息是离线的，需要请求
    --                        local Friend_pb = require("Friend_pb")
    --                        local msg = Friend_pb.HPMsgList();
    --                        if type(identify) == "number" then
    --                            msg.playerId = identify
    --                        else
    --                            msg.playerId = 0
    --                            msg.senderIdentify = identify
    --                        end
    --                        common:sendPacket(HP_pb.MESSAGE_LIST_C, msg)
    --                    end
    --                    -- 2.2.2.1 如果有已经聊天的对象，切换到私聊页面
    --                    ChatManager.readMsg(identify)
    --                    ChatPage:showPrivatePage(container)
    --                else
    --                    if ChatManager.selectPlayerInfo.id ~= 0 then
    --                        ChatManager.setCurrentChatPerson(ChatManager.selectPlayerInfo.id)
    --                        ChatManager.readMsg(ChatManager.selectPlayerInfo.id)
    --                        ChatPage:showPrivatePage(container)
    --                    else
    --                        --2.2.2.2 如果没有有已经聊天的对象 提示没有私聊信息
    --                        ChatPage:onChatHistory(false)
    --                    end
    --                end
    --                ChatManager.refreshMainNewChatPointTips()
    --                return
    --            end
    --            if identify ~= 0 then
    --                if ChatManager.isOfflineMsg(identify) then
    --                    -- 2.1.1 消息是离线的，需要请求
    --                    local Friend_pb = require("Friend_pb")
    --                    local msg = Friend_pb.HPMsgList();
    --                    if type(identify) == "number" then
    --                        msg.playerId = identify
    --                    else
    --                        msg.playerId = 0
    --                        msg.senderIdentify = identify
    --                    end
    --                    common:sendPacket(HP_pb.MESSAGE_LIST_C, msg)
    --                end
    --                -- 2.2.2.1 如果有已经聊天的对象，切换到私聊页面
    --                ChatManager.readMsg(identify)
    --                ChatPage:showPrivatePage(container)
    --            else
    --                -- 2.2.2.2 如果没有有已经聊天的对象 提示没有私聊信息
    --                ChatPage:onChatHistory(false)
    --            end
    --        end
    --    end
    --else
    --    local flag, playerId, identify = ChatManager.hasNewMsgInBox()
    --    if flag then
    --        -- 1.1 如果有新的消息过来,跳转到新消息页面
    --        ChatManager.setCurrentChatPerson(identify or playerId)
    --        ChatManager.readMsg(identify or playerId)
    --        ChatPage:showPrivatePage(container)
    --    else
    --        --私聊聊天记录修改
    --        if isSaveChatHistory then
    --            if ChatManager.getMsgBoxSize() == 0 or ChatManager.selectPlayerInfo.id == 0 then
    --                --2.2.1 如果当前消息盒子是空，弹出最近聊天页面
    --                ChatPage:onChatHistory(true)
    --            else
    --                --2.2.2 如果当前消息盒子不为空
    --                local uniquePlayerId = ChatManager.getCurrentChatId()
    --                if uniquePlayerId then
    --                    if ChatManager.isOfflineMsg(uniquePlayerId) then
    --                        -- 2.1.1 消息是离线的，需要请求
    --                        local Friend_pb = require("Friend_pb")
    --                        local msg = Friend_pb.HPMsgList();
    --                        if type(identify) == "number" then
    --                            msg.playerId = identify
    --                        else
    --                            msg.playerId = 0
    --                            msg.senderIdentify = identify
    --                        end
    --                        common:sendPacket(HP_pb.MESSAGE_LIST_C, msg)
    --                    end
    --                    --2.2.2.1 如果有已经聊天的对象，切换到私聊页面
    --                    ChatManager.readMsg(uniquePlayerId)
    --                    ChatPage:showPrivatePage(container)
    --                else
    --                    if ChatManager.selectPlayerInfo.id ~= 0 then
    --                        ChatManager.setCurrentChatPerson(ChatManager.selectPlayerInfo.id)
    --                        ChatManager.readMsg(ChatManager.selectPlayerInfo.id)
    --                        ChatPage:showPrivatePage(container)
    --                    else
    --                        --2.2.2.2 如果没有有已经聊天的对象 提示没有私聊信息
    --                        ChatPage:onChatHistory(false)
    --                    end
    --                end
    --            end
    --            ChatManager.refreshMainNewChatPointTips()
    --            return
    --        end
    --
    --        if ChatManager.getMsgBoxSize() == 0 then
    --            -- 2.2.1 如果当前消息盒子是空，弹出最近聊天页面
    --            ChatPage:onChatHistory(true)
    --        else
    --            -- 2.2.2 如果当前消息盒子不为空
    --            local identify = ChatManager.getCurrentChatId()
    --            if identify ~= 0 then
    --                if ChatManager.isOfflineMsg(identify) then
    --                    -- 2.1.1 消息是离线的，需要请求
    --                    local Friend_pb = require("Friend_pb")
    --                    local msg = Friend_pb.HPMsgList();
    --                    if type(identify) == "number" then
    --                        msg.playerId = identify
    --                    else
    --                        msg.playerId = 0
    --                        msg.senderIdentify = identify
    --                    end
    --                    common:sendPacket(HP_pb.MESSAGE_LIST_C, msg)
    --                end
    --                -- 2.2.2.1 如果有已经聊天的对象，切换到私聊页面
    --                ChatManager.readMsg(identify)
    --                ChatPage:showPrivatePage(container)
    --            else
    --                -- 2.2.2.2 如果没有有已经聊天的对象 提示没有私聊信息
    --                ChatPage:onChatHistory(false)
    --            end
    --        end
    --        -- 1.2 如果没有新消息,直接弹出消息盒子
    --        -- ChatPage:onChatHistory(false)
    --    end
    --end
    --ChatManager.refreshMainNewChatPointTips()

end

function ChatPage:onChatHistory(isHistory)
    --registerScriptPage("BattleChatHistoryPage")
    --BattleChatHistoryPage_setTabIsHistory(isHistory)
    --PageManager.pushPage("BattleChatHistoryPage")
end

function ChatPage:showPrivatePage(container)

    self:initPrivateNode(container)
    hasNewPrivateChatComing = false
    self.redPoint[Const_pb.CHAT_PERSONAL]:setVisible(false)
    self:setMenuSelect(container, Const_pb.CHAT_PERSONAL)
    currentChanel = Const_pb.CHAT_PERSONAL
    self:switchChatChanel(container)
end
------------------------------------------------------
function ChatPage:setFaceVisible(container, isVisible)
    NodeHelper:setNodeVisible(container:getVarNode("mExpressionNode"), isVisible)
end

function ChatPage:setMenuSelect(container, channel)
    if channel == Const_pb.CHAT_WORLD then
        NodeHelper:setMenuItemSelected(container, { mChatBtn1 = true, mChatBtn2 = false, mChatBtn3 = false, mChatBtn4 = false })
    elseif channel == Const_pb.CHAT_ALLIANCE then
        NodeHelper:setMenuItemSelected(container, { mChatBtn1 = false, mChatBtn2 = true, mChatBtn3 = false, mChatBtn4 = false })
    elseif channel == Const_pb.CHAT_PERSONAL then
        NodeHelper:setMenuItemSelected(container, { mChatBtn1 = false, mChatBtn2 = false, mChatBtn3 = true, mChatBtn4 = false })
    elseif channel == Const_pb.CHAT_CROSS_PVP then
        NodeHelper:setMenuItemSelected(container, { mChatBtn1 = false, mChatBtn2 = false, mChatBtn3 = false, mChatBtn4 = true })
    end
end

function ChatPage:refreshRedPoint(container)

    self.redPoint[Const_pb.CHAT_WORLD]:setVisible(false)
    self.redPoint[Const_pb.CHAT_CROSS_PVP]:setVisible(false)
    if AllianceOpen == false then
        self.redPoint[Const_pb.CHAT_ALLIANCE]:setVisible(false)
    else
        self.redPoint[Const_pb.CHAT_ALLIANCE]:setVisible(false)
    end
    if currentChanel == Const_pb.CHAT_PERSONAL then
        local flag, id, identify = ChatManager.hasNewMsgInBox()
        self.redPoint[Const_pb.CHAT_PERSONAL]:setVisible(false)
    else
        local flag = ChatManager.hasNewMsgWithoutCur()
        self.redPoint[Const_pb.CHAT_PERSONAL]:setVisible(false)
    end
end
------------------------------------------------------
local ListContent = { }
function ListContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end
--跳转工会
function ListContent:onJumpGuild()
    require("Guild.GuildData")
    PageManager.changePage("GuildPage")
    GuildPage_setIsJump(true,true)
end
function ListContent:onPersonInfoBtn(content)
    --local chatType = self.chatType
    --local itemInfo
    --local index = self.id
    --if chatType == Const_pb.CHAT_WORLD then
    --    itemInfo = VoiceChatManager.worldChatMessageList[index]
    --elseif currentChanel == Const_pb.CHAT_ALLIANCE then
    --    itemInfo = VoiceChatManager.guildChatMessageList[index]
    --elseif currentChanel == Const_pb.CHAT_PERSONAL then
    --    itemInfo = ChatManager.curChatPerson.msgList[index]
    --elseif currentChanel == Const_pb.CHAT_CROSS_PVP then
    --    itemInfo = VoiceChatManager.crossChatMessageList[index]
    --end
    --if not itemInfo then return end
    --local playerId = GameConfig.SystemId
    --local senderIdentify
    --if currentChanel == Const_pb.CHAT_PERSONAL then
    --    playerId = itemInfo.senderId
    --    senderIdentify = ChatManager.curChatPerson.chatUnit.senderIdentify
    --    if itemInfo.msgType == Const_pb.SYSTEM_MSG then
    --        -- 私聊频道的系统消息
    --        playerId = GameConfig.SystemId
    --    end
    --else
    --    senderIdentify = itemInfo.senderIdentify
    --    local playerInfo = itemInfo.voiceInfo
    --    playerId = playerInfo[1]
    --end
    --
    --if playerId and playerId ~= GameConfig.SystemId then
    --    if senderIdentify and senderIdentify ~= "" then
    --        OSPVPManager.reqOSPlayerInfo(senderIdentify)
    --    else
    --        PageManager.viewPlayerInfo(playerId)
    --    end
    --end
end
function ListContent:onPreLoad(content)
    if self.isSelf then
        content:setCCBFile("BattleSpeechChatRightContent.ccbi")
    else
        content:setCCBFile("BattleSpeechChatLeftContent.ccbi")
    end
end
function ListContent:onUnLoad(content)

end

function ListContent:onClickMsg(container)
    local index = self.id
    local chatType = self.chatType
    local oneChatMsg
    if chatType == Const_pb.CHAT_WORLD then
        return
    elseif currentChanel == Const_pb.CHAT_ALLIANCE then
        oneChatMsg = VoiceChatManager.guildChatMessageList[index]
    elseif currentChanel == Const_pb.CHAT_PERSONAL then
        return
    end

    if not oneChatMsg then return end
    if string.find(oneChatMsg.chatMsg, "@sendRoleAttacker") then
        local json = require("json")
        local msg = json.decode(oneChatMsg.chatMsg)
        local GVGManager = require("GVGManager")
        GVGManager.setMailTargetCity(tonumber(msg.data[3]))
        GVGManager.isGVGPageOpen = true
        GVGManager.reqGuildInfo()
    elseif string.find(oneChatMsg.chatMsg, "@sendRoleDefender") then
        local json = require("json")
        local msg = json.decode(oneChatMsg.chatMsg)
        local GVGManager = require("GVGManager")
        GVGManager.setMailTargetCity(tonumber(msg.data[1]))
        GVGManager.isGVGPageOpen = true
        GVGManager.reqGuildInfo()
    elseif string.find(oneChatMsg.chatMsg, "@zeroAttacker") then
        local json = require("json")
        local msg = json.decode(oneChatMsg.chatMsg)
        local GVGManager = require("GVGManager")
        GVGManager.setMailTargetCity(tonumber(msg.data[2]))
        GVGManager.isGVGPageOpen = true
        GVGManager.reqGuildInfo()
    elseif string.find(oneChatMsg.chatMsg, "@zeroDefender") then
        local json = require("json")
        local msg = json.decode(oneChatMsg.chatMsg)
        local GVGManager = require("GVGManager")
        GVGManager.setMailTargetCity(tonumber(msg.data[2]))
        GVGManager.isGVGPageOpen = true
        GVGManager.reqGuildInfo()
    end
end

function ListContent:getGVGGuildMsgFromData(oneChatMsg)
    local str = oneChatMsg.chatMsg or ""
    if string.find(oneChatMsg.chatMsg, "@sendRoleAttacker") then
        local json = require("json")
        local msg = json.decode(oneChatMsg.chatMsg)
        local GVGManager = require("GVGManager")
        GVGManager.initCityConfig()
        local cityCfg = GVGManager.getCityCfg(msg.data[3])
        str = common:getLanguageString(msg.key, msg.data[1], msg.data[2], cityCfg.cityName)
    elseif string.find(oneChatMsg.chatMsg, "@sendRoleDefender") then
        local json = require("json")
        local msg = json.decode(oneChatMsg.chatMsg)
        local GVGManager = require("GVGManager")
        GVGManager.initCityConfig()
        local cityCfg = GVGManager.getCityCfg(msg.data[1])
        str = common:getLanguageString(msg.key, cityCfg.cityName, msg.data[2], msg.data[3])
    elseif string.find(oneChatMsg.chatMsg, "@zeroAttacker") then
        local json = require("json")
        local msg = json.decode(oneChatMsg.chatMsg)
        local GVGManager = require("GVGManager")
        GVGManager.initCityConfig()
        local cityCfg = GVGManager.getCityCfg(msg.data[2])
        str = common:getLanguageString(msg.key, msg.data[1], cityCfg.cityName)
    elseif string.find(oneChatMsg.chatMsg, "@zeroDefender") then
        local json = require("json")
        local msg = json.decode(oneChatMsg.chatMsg)
        local GVGManager = require("GVGManager")
        GVGManager.initCityConfig()
        local cityCfg = GVGManager.getCityCfg(msg.data[2])
        str = common:getLanguageString(msg.key, msg.data[1], cityCfg.cityName)
    end

    return str
end
function ListContent:onRefreshContent(content)

    -- TODO  这里有时间要好好改一下

    CCLuaLog("-----------------------------ChatPage onRefreshContent " .. self.id)
    local index = self.id
    local isSelfMessage = self.isSelf
    local container = content:getCCBFileNode()
    local labBack = container:getVarScale9Sprite("mChatBG")
    -- isSelfMessage
    local whiteBg = container:getVarScale9Sprite("mChatBGWhite")
    local texNode = container:getVarNode("mTexNode")
    -- isSelfMessage
    local timeLabel = container:getVarLabelTTF("ChatTime")
    -- isSelfMessage
    local labInput = container:getVarLabelTTF("mInputTex")
    -- isSelfMessage
    local labName = container:getVarLabelTTF("mPlayerName")
    local personInfoBtn = container:getVarMenuItemImage("mPersonInfoBtn")
    local pointNode = container:getVarNode("mPoint")
    local clickMsgBtn = container:getVarMenuItemImage("mClickMsgBtn")
    local charHtmlWidth = htmlWidth/2
    --CCEGLView:sharedOpenGLView():getDesignResolutionSize().width / 2
    if isSelfMessage then
        content:setContentSize(selfCellSize)
        container:setContentSize(selfCellSize)
        labBack:setContentSize(CCSizeMake(53, 49))
        texNode:setPosition(ccp(container:getContentSize().width - 5, 20))
        labInput:setPosition(ccp(-50, 20))
    else
        whiteBg:setVisible(false)
        labBack:setVisible(true)
        content:setContentSize(cellSize)
        container:setContentSize(cellSize)
        labBack:setContentSize(CCSizeMake(53, 49))
        whiteBg:setContentSize(CCSizeMake(60, 68))
        -- whiteBg:setContentSize(chatBgSize)
        texNode:setPosition(ccp(45,140))
        labInput:setPositionY(-43)
        labName:setPosition(ccp(90, -35))
        pointNode:setPosition(ccp(80, -27))
        personInfoBtn:setContentSize(CCSizeMake(50, 50))
    end
    if labBack then
        local node = labBack:getChildByTag(10086)
        if node then
            labBack:removeChild(node, true)
        end
    end
    --    if pointNode then
    --        local node = pointNode:getChildByTag(10086)
    --        if node then
    --           pointNode:removeChild(node, true)
    --        end
    --    end


    --    if texNode then
    --       local node = texNode:getChildByTag(10086)
    --        if node then
    --            texNode:removeChild(node, true)
    --        end
    --    end



    local chatType = self.chatType
    local itemInfo
    if chatType == Const_pb.CHAT_WORLD then
        itemInfo = VoiceChatManager.worldChatMessageList[index]
    elseif currentChanel == Const_pb.CHAT_ALLIANCE then
        itemInfo = VoiceChatManager.guildChatMessageList[index]
    elseif currentChanel == Const_pb.CHAT_PERSONAL then
        itemInfo = ChatManager.curChatPerson.msgList[index]
    elseif currentChanel == Const_pb.CHAT_CROSS_PVP then
        itemInfo = VoiceChatManager.crossChatMessageList[index]
    end
    if not itemInfo then return end
    local playerInfo
    local chatMsg
    local senderId
    local avatarId = 0
    local cspvpRank, cspvpScore = 0, 0
    if currentChanel == Const_pb.CHAT_PERSONAL then
        local senderId = itemInfo.senderId
        local roleItemId = 0
        if itemInfo.senderId == UserInfo.playerInfo.playerId then
            roleItemId = UserInfo.roleInfo.itemId
        else
            roleItemId = ChatManager.curChatPerson.chatUnit.roleItemId
            avatarId = ChatManager.curChatPerson.chatUnit.avatarId
            cspvpRank = ChatManager.curChatPerson.chatUnit.cspvpRank
            cspvpScore = ChatManager.curChatPerson.chatUnit.cspvpScore
        end
        if itemInfo.msgType == Const_pb.SYSTEM_MSG then
            -- 私聊频道的系统消息
            senderId = GameConfig.SystemId
            itemInfo.senderName = common:getLanguageString("@System")
        end
        chatMsg = itemInfo.message
        local senderName = itemInfo.senderName
        local temp1 = common:split(ChatManager.curChatPerson.chatUnit.senderIdentify, "#")
        if temp1[2] then
            local temp2 = common:split(temp1[2], "*")
            local sId = tonumber(temp2[1]) or -1
            if sId > 0 then
                senderName = common:getLanguageString("@PVPServerName", GamePrecedure:getInstance():getServerNameById(tonumber(sId))) .. itemInfo.senderName
            end
        end

        playerInfo = {
            [1] = senderId,
            [2] = senderName,
            [3] = itemInfo.level,
            [4] = roleItemId,
            [5] = "",
            [6] = "",
            [7] = itemInfo.titleId,
        }
    else
        if currentChanel == Const_pb.CHAT_ALLIANCE then
            chatMsg = self:getGVGGuildMsgFromData(itemInfo)
        else
            chatMsg = itemInfo.chatMsg
        end
        avatarId = itemInfo.avatarId
        cspvpRank = itemInfo.cspvpRank
        cspvpScore = itemInfo.cspvpScore
        playerInfo = itemInfo.voiceInfo
        playerInfo[8] = tonumber (itemInfo.headIcon)
    end

    if not isSelfMessage then
        if cspvpRank and cspvpRank > 0 then
            local stage = OSPVPManager.checkStage(cspvpScore, cspvpRank)
            NodeHelper:setSpriteImage(container, { mHand = stage.stageIcon })
        else
            NodeHelper:setSpriteImage(container, { mHand = GameConfig.QualityImage[1] })
        end
    end

    local textColor = "0 0 0"
    if itemInfo.skinId ~= -9999 then
        itemInfo.skinId = 0
    end
    if itemInfo.skinId and itemInfo.skinId > 0 then
        local skinInfo
        for i, v in ipairs(chatSkinCfg) do
            if v.skinId == itemInfo.skinId then
                skinInfo = v
                break
            end
        end

        if skinInfo then
            local rect = CCRectMake(0, 0, 80, 61)
            if skinInfo.skinRes:find("u_ChatBG") then
                rect = CCRectMake(0, 0, 140, 61)
            end
            local bgMap = {
                mChatBG =
                {
                    name = skinInfo.skinRes,
                    rect = rect
                }
            }
            local capInsets = {
                left = 30,
                right = 30,
                top = 30,
                bottom = 30
            }
            NodeHelper:setScale9SpriteImage(container, bgMap, { mChatBG = capInsets }, { mChatBG = chatBgSize })
            textColor = skinInfo.textColor or "0 0 0"
        end
    else
        local messageBgName = "UI/Animation/VoiceChat/chatMessage_bai.png"
        local insets = {
            left = 21,
            right = 21,
            top = 22,
            bottom = 22
        }
        textColor = "0 0 0"
        if isSelfMessage then
            messageBgName = "UI/Animation/VoiceChat/chatMessage_lv.png"
            insets = {
                --left = 21,
                --right = 31,
                --top = 22,
                --bottom = 22
                left = 21,
                right = 21,
                top = 22,
                bottom = 22
            }
            textColor = "255 255 255"
        else
            if  itemInfo.skinId == -9999 then
                messageBgName = "UI/Animation/VoiceChat/chatMessage_huang.png"
            end
        end
        local bgMap = {
            mChatBG =
            {
                name = messageBgName,
                -- rect = CCRectMake(0,0,65,52)
                rect = CCRectMake(0,0,chatBgSize.width-1,chatBgSize.height+3)
            }
        }
        local capInsets = insets
        NodeHelper:setScale9SpriteImage(container, bgMap, { mChatBG = capInsets }, { mChatBG = chatBgSize })
    end
    local msgTime = ""
    if currentChanel == Const_pb.CHAT_PERSONAL then
        if itemInfo.msTime then
            msgTime = os.date("  %H:%M", itemInfo.msTime)
        end
    else
        if  itemInfo.msgTime then
            msgTime = os.date("  %H:%M", itemInfo.msgTime)
        end
    end


    local labNameHtml = nil
    -- local labNameHtmlHeight = 0
    local bgIcon  = ""
    if not isSelfMessage then
        local roleCfg = ConfigManager.getRoleCfg()
        local NewHeadIconItem = require("NewHeadIconItem")
        if playerInfo[1] == GameConfig.SystemId then
            -- 系统发言
            --iconPath, bgIcon = common:getPlayeIcon(nil, GameConfig.SystemId, true)
            NewHeadIconItem:setLeaderClass(tonumber(10))
        else
            NewHeadIconItem:setLeaderClass(tonumber(playerInfo[4]) * 10)
        end      

        local headNode = ScriptContentBase:create(mercenaryHeadContent.ccbiFile)
        local parentNode = container:getVarNode("mPortrait")
        parentNode:removeAllChildren()
        mercenaryHeadContent:refreshItem(headNode,playerInfo, playerInfo[1] == GameConfig.SystemId )
        headNode:setAnchorPoint(ccp(0.0, 0.0))
        headNode:setScale(0.8)
        parentNode:addChild(headNode)
    end
    local x = labBack:getContentSize().width
    local y = labBack:getContentSize().height

    local chatStr = chatMsg;

    local str = chatStr
    local colorArr = common:split(textColor, " ")
    local colorStr = ""
    for i = 1, #colorArr do
        local hexStr = common:toHex(tonumber(colorArr[i]))
        for i = string.len(hexStr), 1 do
            hexStr = "0" .. hexStr
        end
        colorStr = colorStr .. hexStr
    end
    if common:checkPlayerSexByItemId(tonumber(playerInfo[4])) == true then
        if isSelfMessage then
        local colorModel =FreeTypeConfig[701].content
        chatStr = GameMaths:replaceStringWithCharacterAll(colorModel, "#v2#", chatStr)
        else
        local colorModel =FreeTypeConfig[702].content
        chatStr = GameMaths:replaceStringWithCharacterAll(colorModel, "#v2#", chatStr)
        end
    end

    local faceSprite = nil
    local node = nil
    local height = nil
    local maxWidth = nil
    local labelHeight = nil

    local node = nil
    local faceNode = nil
    local faceSpriteTable = { }

    -- local isOneFace,relaPath = false,nil
    local isOneFace,relaPath = VoiceChatManager.getIsOneFace(chatStr)

    if isOneFace then
        node = NodeHelper:addChatOneFaceSprite(labInput, relaPath, GameConfig.Tag.HtmlLable)
        labBack:setVisible(false)
        y = node:getContentSize().height-40
        x = node:getContentSize().width+25*2
    else
        labBack:setVisible(true)
        local str = "<font color=\"#513F35\" face = \"Barlow SemiBold\">" .. chatStr .. "</font>"
        str = VoiceChatManager.handlerChatFace(str)
        node = NodeHelper:addHtmlLable(labInput, str, GameConfig.Tag.HtmlLable, CCSizeMake(charHtmlWidth, 200))
        if labBack:getContentSize().height < node:getContentSize().height + 30 then
            y = node:getContentSize().height + 25
        end

        if labBack:getContentSize().width < node:getContentSize().width + 50 then
            x = node:getContentSize().width + 25 * 2
        end
        x = node:getContentSize().width + 25 * 2
    end
    --node = NodeHelper:addHtmlLable(labInput, chatStr, GameConfig.Tag.HtmlLable, CCSizeMake(charHtmlWidth, 200))


    local size = CCSizeMake(x, y)
    local addHeight = y - labBack:getContentSize().height
    labBack:setContentSize(size)

    if (not isSelfMessage) and isOneFace then
        node:setPositionX(node:getPositionX()-25)
    end
    node:setAnchorPoint(ccp(0,0))
   if isSelfMessage then 
        node:setPositionX(node:getPositionX()-node:getContentSize().width+20)
        node:setPositionY(labBack:getPositionY()+(labBack:getContentSize().height-node:getContentSize().height)/2+1)
   else
       node:setPositionX(node:getPositionX()-5)
       node:setPositionY(labBack:getPositionY()+(labBack:getContentSize().height-node:getContentSize().height)/2+1)
   end
    

    if timeLabel then
        timeLabel:setString(msgTime)
        if not isSelfMessage then
            timeLabel:setPositionX(labBack:getPositionX() + labBack:getContentSize().width + 5)
            timeLabel:setPositionY( - labBack:getContentSize().height+10)
        else
            timeLabel:setPositionX(labBack:getPositionX() - labBack:getContentSize().width - 10)
            timeLabel:setPositionY( - labBack:getContentSize().height+50)
        end
    end


    if clickMsgBtn then
        clickMsgBtn:setContentSize(size)
    end

    if not isSelfMessage then
        personInfoBtn:setContentSize(size)
    end
    local newHeight = container:getContentSize().height + addHeight
    local newSize = CCSizeMake(container:getContentSize().width, newHeight)
    container:setContentSize(newSize)

    if not isSelfMessage then
        texNode:setPositionY(texNode:getPositionY() + addHeight-10)
        pointNode:setPositionY(pointNode:getPositionY() - addHeight-10)

        if labName then
            local htmlName = VoiceChatManager.getChatName(playerInfo)
            labName:setPositionY(labName:getPositionY()-10)
            labName:setString(playerInfo[2])
            -- NodeHelper:setCCHTMLLabelDefaultPos(labName, CCSizeMake(570, 200), htmlName)
            -- labName:setVisible(false)
        end
    end



    -- local normalHeight =  y + labNameHtmlHeight * 2
    --

    -- if container:getContentSize().height < y + labNameHtmlHeight then
    -- container:setContentSize( CCSizeMake(container:getContentSize().width , y + labNameHtmlHeight + 10) )
    -- end
    content:setContentSize(newSize)
    -- content:setContentSize(CCSizeMake(container:getContentSize().width,normalHeight))

    content:setPositionX(0)
    --同盟聊天跳转工会
    if currentChanel == Const_pb.CHAT_ALLIANCE then
        local count = getTabelLength(VoiceChatManager.guildChatMessageList)
        local isShow  = false

        if  count == index  then
            isShow = false
            local timeLabelPosX = 0
            local timeLabelPosY = 0
            local mJumpNode = container:getVarNode("mJumpNode")
            if timeLabel then
               timeLabelPosX = timeLabel:getPositionX()
            end
            if isSelfMessage then
                local mJumpBtnNode = container:getVarNode("mJumpBtn")
                local timeLabelWorPos = timeLabelPosX  - timeLabel:getContentSize().width + 15
                mJumpNode:setPositionX(timeLabelWorPos);
                local mJumpLabel = container:getVarLabelTTF("mJumpLabel")
                local mJumpLabelSize = mJumpLabel:getContentSize()
                mJumpLabel:setFontSize(20)
                mJumpBtnNode:setContentSize(CCSizeMake(mJumpLabelSize.width+10,mJumpLabelSize.height+50))

            else
                local mJumpBtnNode = container:getVarNode("mJumpBtn")
                local timeLabelWorPos = timeLabelPosX  + timeLabel:getContentSize().width+15
                mJumpNode:setPositionX(timeLabelWorPos);
                local mJumpLabel = container:getVarLabelTTF("mJumpLabel")
                local mJumpLabelSize = mJumpLabel:getContentSize()
                mJumpLabel:setFontSize(20)
                mJumpBtnNode:setContentSize(CCSizeMake(mJumpLabelSize.width+10,mJumpLabelSize.height+50))
            end
        else
            isShow = false
        end
        NodeHelper:setNodesVisible(container,{mJumpNode = isShow})
    else
        NodeHelper:setNodesVisible(container,{mJumpNode = false})
    end

end

function ChatPage:SetFaceAndChatPositionAndSize(faceNode, faceSpriteTable, str, node, charHtmlWidth, facePath)
    faceNode = CCNode:create()
    faceNode:setTag(10088)
    faceNode:setAnchorPoint(ccp(0, 0))
    local faceSprite = nil
    for i = 1, #facePath do
        faceSprite = CCSprite:create(facePath[i])
        faceSprite:setAnchorPoint(ccp(0, 0))
        table.insert(faceSpriteTable, faceSprite)
    end
    local spaceWidth = 20
    local horizontalSpacing = 0
    local verticalSpacing = 0
    local tmpTextNode = nil
    tmpTextNode = CCLabelTTF:create(" ", "Barlow-SemiBold.ttf", 30)
    local tmpTextNodeSize = tmpTextNode:getContentSize()
    local strList = common:split(str, ">")
    str = strList[#strList]
    local spriteSpaceX = 5
    local spriteSpaceY = 5
    local spriteWidth = 0
    local spriteHeigh = 0
    local tmpSpriteX = 0
    local tmpSpriteY = 0
    local tmpRow = 0
    local count = 0
    -- 不满一行的
    local tmpWidth = 0
    -- 不满一行的宽度
    for i = 1, #faceSpriteTable do
        if i == 1 then
            local spriteSize = faceSpriteTable[i]:getContentSize()
            spriteWidth = spriteSize.width
            spriteHeigh = spriteSize.height
        end
        tmpSpriteX =(i - 1) *(spriteWidth + spriteSpaceX)
        if tmpSpriteX + spriteWidth >= charHtmlWidth then
            tmpRow = tmpRow + 1
            tmpSpriteY = -((tmpRow + 1) *(spriteHeigh + spriteSpaceY))
        else
            tmpSpriteY = -(spriteHeigh + spriteSpaceY)
            count = count + 1
        end
        faceNode:addChild(faceSpriteTable[i])

    end
    if tmpRow > 0 then
        tmpWidth = charHtmlWidth * tmpRow + count *(spriteWidth + spriteSpaceX)
    else
        tmpWidth = #faceSpriteTable *(spriteWidth + spriteSpaceX)
    end
    local spaceCount = math.ceil(tmpWidth / tmpTextNodeSize.width)
    local tmpStr = ""
    for i = 1, spaceCount do
        tmpStr = tmpStr .. " "
    end
    str = tmpStr .. str
    local returnStr = ""
    local node = nil
    local textNode = nil
    local height = nil
    local maxWidth = nil
    local labelHeight = nil
    local line = nil
    textNode, height, maxWidth, labelHeight, line, returnStr = NodeHelper:horizontalSpacingAndVerticalSpacing_LLLL(str, "Barlow-SemiBold.ttf", 30, horizontalSpacing, verticalSpacing, charHtmlWidth, "0 0 0")
    -- node:setTag(10086)
    textNode = CCLabelTTF:create(returnStr, "Barlow-SemiBold.ttf", 30)
    textNode:setTag(10086)
    textNode:setHorizontalAlignment(kCCTextAlignmentLeft)
    textNode:setColor(NodeHelper:_getColorFromSetting("0 0 0"))
    textNode:setAnchorPoint(ccp(0, 1))
    node = CCNode:create()
    node:setTag(10087)
    node:addChild(faceNode)
    node:addChild(textNode)
    node:setContentSize(CCSizeMake(maxWidth, labelHeight))
    faceNode:setPosition(ccp(0, labelHeight))
    textNode:setPosition(ccp(0, labelHeight))
    return node

end

function ChatPage:setCurrentPrivateChatPlayerSelectState(container, currentPlayerId)
    for i, v in pairs(ChatPage.mPrivateChatItems) do
        if v then
            v:setSelectState(currentPlayerId)
        end
    end
end

function ChatPage:removePrivateChat(container, tag)

    --私聊聊天记录修改
    if isSaveChatHistory then
        if ChatManager.selectPlayerInfo.id == 0 then
            return
        end
        ChatManager.deletePersonalRecordListId()
        local t = nil
        for i, v in pairs(ChatManager.msgBoxList) do
            if v.chatUnit.playerId == tag then
               t = i
                break
            end
        end
        ChatManager.msgBoxList[t] = nil
        if ChatManager.selectPlayerInfo.id and ChatManager.selectPlayerInfo.id ~= 0 then
            -- 清空聊天内容
            ChatManager.setCurrentChatPerson(ChatManager.selectPlayerInfo.id)
            self:switchChatChanel(container)
            --self:onPrivateChannel(container)
        else
            --返回世界聊天
            self.scrollview:removeAllCell()
            self:onWorldChannel(container)
        end
        ChatManager.saveAllPrivatePersonChatRecord()
        return
    end
    ChatManager.closedChat(tag)
    self:initPrivateNode(container)
    if ChatManager.getMsgBoxSize() <= 0 then
        -- 清空聊天内容
        self.scrollview:removeAllCell()
        --返回世界聊天
        self:onWorldChannel(container)
    else
        self:onPrivateChannel(container)
    end
    -- self:onPrivateChannel(container)

    --    --刷新私聊界面上面的面板
    --    self.mPrivateChatContentScrollview:removeCell(ChatPage.mPrivateChatItems[tag]:getCCBFileCell())

    --    local t = {}
    --    for i, v in pairs(ChatPage.mPrivateChatItems) do
    --        if v:getTag() ~= tag  then
    --            t[v:getTag()] = v
    --        end
    --    end
    --    ChatPage.mPrivateChatItems = t

end

function ChatPage:switchChatChanel(container)
    if not self.scrollview then
        return
    end
    local scrollview = self.scrollview
    scrollview:removeAllCell()
    ChatPage.cellList = { }
    scrollview:resetContainer()
    local chatCount = 0
    local fOneItemWidth = 0
    local currHeight = 0
    local messageList = { }

    UserInfo.sync()
    if currentChanel == Const_pb.CHAT_WORLD then
        chatCount = #VoiceChatManager.worldChatMessageList
        messageList = VoiceChatManager.worldChatMessageList
        NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@ChatTitle") })
        NodeHelper:setNodesVisible(container, { mTitle = true, mTitle_1 = false })
        if chatCount > 0 then
            CCUserDefault:sharedUserDefault():setStringForKey("SaveChatWorldEndTime", messageList[chatCount].msgTime)
        end
    elseif currentChanel == Const_pb.CHAT_ALLIANCE then
        chatCount = #VoiceChatManager.guildChatMessageList
        messageList = VoiceChatManager.guildChatMessageList
        NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@ChatTitle") })
        NodeHelper:setNodesVisible(container, { mTitle = true, mTitle_1 = false })
        if chatCount > 0 then
            CCUserDefault:sharedUserDefault():setStringForKey("SaveChatGuildEndTime", messageList[chatCount].msgTime)
        end
    elseif currentChanel == Const_pb.CHAT_CROSS_PVP then
        chatCount = #VoiceChatManager.crossChatMessageList
        messageList = VoiceChatManager.crossChatMessageList
        NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@ChatTitle") })
        NodeHelper:setNodesVisible(container, { mTitle = true, mTitle_1 = false })
        if chatCount > 0 then
            CCUserDefault:sharedUserDefault():setStringForKey("SaveChatCrossEndTime", messageList[chatCount].msgTime)
        end
    elseif currentChanel == Const_pb.CHAT_PERSONAL then
        if ChatManager.curChatPerson == nil or ChatManager.curChatPerson.msgList == nil then
            return
        end

        -- 刷新聊天玩家的选中状态
        self:setCurrentPrivateChatPlayerSelectState(container, ChatManager.curChatPerson.chatUnit.playerId)

        chatCount = #ChatManager.curChatPerson.msgList
        messageList = ChatManager.curChatPerson.msgList
        
        -- 标记为已读
        local curChatPersonName = ChatManager.curChatPerson.chatUnit.name
        NodeHelper:setStringForLabel(container, { mTitle_1 = curChatPersonName })
        NodeHelper:setNodesVisible(container, { mTitle = false, mTitle_1 = true })
        local identify = ChatManager.curChatPerson.chatUnit.senderIdentify
        if not identify or identify == "" then
            identify = ChatManager.curChatPerson.chatUnit.playerId
        end
        ChatManager.readMsg(identify)
        if chatCount > 0 then
            CCUserDefault:sharedUserDefault():setStringForKey("SaveChatPersonalEndTime", messageList[chatCount].msgTime)
        end
        --私聊聊天记录修改
        if isSaveChatHistory then
            ChatManager.insertSortChatPrivate(ChatManager.curChatPerson.uniquePlayerId)
            self:initPrivateNode(container)
            --ChatPersonalRecord:showPrivateRecordList(container,ChatPage)
        end
    end

    for i = chatCount, 1, -1 do
        local itemInfo = messageList[i]
        if not itemInfo then
            break
        end
        local isSelfMessage = false
        if currentChanel == Const_pb.CHAT_PERSONAL then
            if itemInfo.senderId == UserInfo.playerInfo.playerId then
                isSelfMessage = true
            end
        else
            local playerInfo = itemInfo.voiceInfo
            if (playerInfo[1] == UserInfo.playerInfo.playerId) then
                isSelfMessage = true
            end
        end

        local containerWidth = scrollview:getContentSize().width
        local ccbi = "BattleSpeechChatLeftContent.ccbi"
        cell = CCBFileCell:create()
        local pItemHeight = 0
        if isSelfMessage then
            cell:setCCBFile("BattleSpeechChatRightContent.ccbi")
            cell:setContentSize(selfCellSize)
            pItemHeight = selfCellSize.height
        else
            cell:setCCBFile("BattleSpeechChatLeftContent.ccbi")
            cell:setContentSize(otherCellSize)
            pItemHeight = otherCellSize.height
        end
        local panel = ListContent:new { id = i, chatType = currentChanel, isSelf = isSelfMessage }
        cell:registerFunctionHandler(panel)

        cell:setPosition(ccp(0, currHeight + cellSpacing))

        if fOneItemWidth < cell:getContentSize().width then
            fOneItemWidth = cell:getContentSize().width
        end
        currHeight = currHeight + pItemHeight + cellSpacing
        scrollview:addCell(cell)
        ChatPage.cellList[i] = cell
    end

    if currentChanel == Const_pb.CHAT_PERSONAL then
        self.scrollview:setViewSize(CCSizeMake(initialChatViewSize.width, initialChatViewSize.height - chatContentDifference))
    else
        if self.scrollview:getViewSize().height ~= initialChatViewSize.height then
            self.scrollview:setViewSize(initialChatViewSize)
        end
    end
    if currHeight < self.scrollview:getViewSize().height then
        currHeight = self.scrollview:getViewSize().height
    end
    local size = CCSizeMake(fOneItemWidth, currHeight)
    scrollview:setContentSize(size)


    scrollview:setContentOffset(ccp(0, 0))
    -- end	
    scrollview:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(scrollview)

    --self.btnNode:setPosition(ccp(self.btnNode:getPositionX(), initialChatViewSize.height + 109.3))

    NodeHelper:setBMFontFile(container, {
        mChatTabTxt1 = currentChanel == Const_pb.CHAT_WORLD and "Lang/Font-HT-TabPage.fnt" or "Lang/Font-HT-TabPage2.fnt",
        mChatTabTxt2 = currentChanel == Const_pb.CHAT_ALLIANCE and "Lang/Font-HT-TabPage.fnt" or "Lang/Font-HT-TabPage2.fnt",
        mChatTabTxt3 = currentChanel == Const_pb.CHAT_PERSONAL and "Lang/Font-HT-TabPage.fnt" or "Lang/Font-HT-TabPage2.fnt",
    } )
end

function ChatPage:insertChatChannel(chatType, newMsgNum)

    local messageList = { }
    local messageSize = 0
    if currentChanel == Const_pb.CHAT_WORLD then
        --hasNewWorldChatComing = false
        messageList = VoiceChatManager.worldChatMessageList
        messageSize = #VoiceChatManager.worldChatMessageList
    elseif currentChanel == Const_pb.CHAT_ALLIANCE then
        --hasNewMemberChatComing = false
        messageList = VoiceChatManager.guildChatMessageList
        messageSize = #VoiceChatManager.guildChatMessageList
    elseif currentChanel == Const_pb.CHAT_PERSONAL then
        --私聊聊天记录修改
        if isSaveChatHistory then
            ChatManager.setCurrentChatPerson(ChatManager.curChatPerson.uniquePlayerId)
            messageSize = #ChatManager.curChatPerson.msgList
            messageList = ChatManager.curChatPerson.msgList
            ChatManager.readMsg(ChatManager.curChatPerson.uniquePlayerId)
        else
            messageSize = #ChatManager.curChatPerson.msgList
            messageList = ChatManager.curChatPerson.msgList
        end


    elseif currentChanel == Const_pb.CHAT_CROSS_PVP then
        --hasNewCrossChatComing = false
        messageList = VoiceChatManager.crossChatMessageList
        messageSize = #VoiceChatManager.crossChatMessageList
    end
     --如果发现插入以后数据长度不对，重刷
    if (#messageList) ~= (#ChatPage.cellList) and newMsgNum <= 0 then
        CCLuaLog("---------------refresh chatpage --step2")
        self:switchChatChanel(self.container)
    end


    if newMsgNum <= 0 then return end
    if chatType ~= currentChanel then
        if self.redPoint[chatType] then
            self.redPoint[chatType]:setVisible(false)
        end
        return
    end
    
    if currentChanel == Const_pb.CHAT_WORLD then
        hasNewWorldChatComing = false
        messageList = VoiceChatManager.worldChatMessageList
        messageSize = #VoiceChatManager.worldChatMessageList
    elseif currentChanel == Const_pb.CHAT_ALLIANCE then
        hasNewMemberChatComing = false
        messageList = VoiceChatManager.guildChatMessageList
        messageSize = #VoiceChatManager.guildChatMessageList
    elseif currentChanel == Const_pb.CHAT_PERSONAL then
        messageSize = #ChatManager.curChatPerson.msgList
        messageList = ChatManager.curChatPerson.msgList
    elseif currentChanel == Const_pb.CHAT_CROSS_PVP then
        hasNewCrossChatComing = false
        messageList = VoiceChatManager.crossChatMessageList
        messageSize = #VoiceChatManager.crossChatMessageList
    end

    local scrollview = self.scrollview
    local scrollViewIsAtBottom = false
    local currentOffset = self.scrollview:getContentOffset()
    -- 在插入新信息之前，滑动框位于最底部，则新加入的内容在最底部显示出来
    -- 否则，当前滑动框的位置不变，新的信息处于屏幕外
    if currentOffset.x == 0 and currentOffset.y == 0 then
        scrollViewIsAtBottom = true
    end
    for i = newMsgNum, 1, -1 do
        local index = messageSize - i + 1
        local itemInfo = messageList[index]
        if itemInfo then
            local isSelfMessage = false
            if currentChanel == Const_pb.CHAT_PERSONAL then
                if itemInfo.senderId == UserInfo.playerInfo.playerId then
                    isSelfMessage = true
                end
            else
                local playerInfo = itemInfo.voiceInfo
                if (playerInfo[1] == UserInfo.playerInfo.playerId) then
                    isSelfMessage = true
                end
            end
            cell = CCBFileCell:create()

            if isSelfSendMsg then
                cell:setCCBFile("BattleSpeechChatRightContent.ccbi")
                cell:setContentSize(selfCellSize)
            else
                cell:setCCBFile("BattleSpeechChatLeftContent.ccbi")
                cell:setContentSize(otherCellSize)
            end

            local panel = ListContent:new { id = index, chatType = currentChanel, isSelf = isSelfMessage }
            cell:registerFunctionHandler(panel)
            for i, v in ipairs(ChatPage.cellList) do
                v:setPositionY(v:getPositionY() + cell:getContentSize().height + cellSpacing)
                local tmpContain = v:getCCBFileNode()
                if type(tmpContain) == "userdata" then
                    NodeHelper:setNodesVisible(tmpContain,{mJumpNode = false})
                end
            end
            local size = scrollview:getContentSize()
            size.height = size.height + cell:getContentSize().height + cellSpacing
            scrollview:setContentSize(size)
            scrollview:addCellFront(cell)
            table.insert(ChatPage.cellList, 1, cell)
            cell:setPosition(ccp(0, 30))
        end
    end
    -- 如果是自己的发言，立刻显示在屏幕底部
    --self.scrollview:setContentOffset(currentOffset)
    if isSelfSendMsg or scrollViewIsAtBottom then
        isSelfSendMsg = false
         self.scrollview:setContentOffset(ccp(0, 0))
    else
        if currentChanel == Const_pb.CHAT_WORLD then
            hasNewWorldChatComing = true
        elseif currentChanel == Const_pb.CHAT_ALLIANCE then
            hasNewMemberChatComing = true
        elseif currentChanel == Const_pb.CHAT_CROSS_PVP then
            hasNewCrossChatComing = true
        elseif currentChanel == Const_pb.CHAT_PERSONAL then

        end
        self:refreshRedPoint(container)
    end
end

---------------------------------------------------------------------------
-- 玩家私聊头像处理


function ChatPrivatePlayerItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function ChatPrivatePlayerItem:getCCBFileCell()
    return self.cell
end

function ChatPrivatePlayerItem:onRefreshContent(content)

    self.cell = content
    self.container = content:getCCBFileNode()
    self.playerId = self.value.chatUnit.playerId
    self.mLvLabel = self.container:getVarLabelTTF("mLv")
    self.mLvLabel:setString("Lv." .. self.value.chatUnit.level)

    self.mNameLabel = self.container:getVarLabelTTF("mName")
    self.mNameLabel:setString(self.value.chatUnit.name)
    self.mSelect = self.container:getVarScale9Sprite("mSelect")
    self.mSelect:setVisible(ChatManager.curChatPerson.chatUnit.playerId == self.value.chatUnit.playerId)


--[[    local showCfg = LeaderAvatarManager.getOthersShowCfg(self.value.chatUnit.avatarId)
    local headPic = showCfg.icon[ConfigManager.getRoleCfg()[tonumber(self.value.chatUnit.roleItemId)].profession]
    headPic = ConfigManager.getRoleCfg()[tonumber(self.value.chatUnit.roleItemId)].chatIcon
    self.playerIcon = self.container:getVarSprite("mPlayerIcon")
    self.playerIcon:setScale(1)
    self.playerIcon:setTexture(tostring(headPic))]]

    local prof = ConfigManager.getRoleCfg()[tonumber(self.value.chatUnit.roleItemId)].profession
    local icon, bgIcon = common:getPlayeIcon(prof, self.value.chatUnit.headIcon ,true)
    NodeHelper:setSpriteImage(self.container, {mPlayerIcon = icon,mPicBg = bgIcon})

    self.mOnCloseNode = self.container:getVarNode("mOnCloseNode")

    self:setSelectState(ChatManager.curChatPerson.chatUnit.playerId)
end

-- 设置玩家的选中状态  是不是正在和这个玩家聊天
function ChatPrivatePlayerItem:setSelectState(currentPlayerId)

    if self.cell == nil then
        return
    end
    CCLuaLog("当前聊天人的id =============================== " .. currentPlayerId)

    CCLuaLog("我找个节点的玩家id =============================== " .. self.value.chatUnit.playerId)
    if currentPlayerId == self.value.chatUnit.playerId then
        self.mSelect:setVisible(true)
        self.mOnCloseNode:setVisible(true)
    else
        self.mSelect:setVisible(false)
        self.mOnCloseNode:setVisible(false)
    end
end


function ChatPrivatePlayerItem:onClick(content)
    CCLuaLog("选择该玩家的聊天")
    -- 如果选择的是自己 return
    if self.value.chatUnit.playerId == ChatManager.curChatPerson.chatUnit.playerId then
        return
    end
     --私聊聊天记录修改
    if isSaveChatHistory then
        --标记之前的已经阅读
        ChatManager.readMsg(ChatManager.selectPlayerInfo.id)
        --更新列表
        ChatManager.updatePersonalRecordListId(self.value.chatUnit.playerId)
        --标记现在的已读
        ChatManager.readMsg(ChatManager.selectPlayerInfo.id)

        -- 选择这个人聊天
        ChatManager.setCurrentChatPerson(self.value.chatUnit.playerId)
        -- 刷新页面
        PageManager.refreshPage("ChatPage", "PrivateChat")
        return
    end
    -- 选择这个人聊天
    ChatManager.setCurrentChatPerson(self.value.chatUnit.playerId)
    -- 刷新页面
    PageManager.refreshPage("ChatPage", "PrivateChat")
end

function ChatPrivatePlayerItem:onRemove(content)
    CCLuaLog("删除该玩家的聊天会话")
    -- 删除这个聊天会话
    -- 消息盒子里面是不是还有其他的聊天
    -- 如果有 切换到其他的聊天
    -- 如果没有怎么办？
    PageManager.refreshPage("ChatPage", "RemovePrivateChat" .. "." .. self.tag)

end

function ChatPrivatePlayerItem:getTag()

    return self.tag
end
 
function ChatPrivatePlayerItem:onPreLoad(content)

end


function ChatPrivatePlayerItem:onUnLoad(content)

end

---------------------------------------------------------------------------




local CommonPage = require('CommonPage')
ChatPage = CommonPage.newSub(ChatPage, thisPageName, option)
