local HP_pb = require("HP_pb")-- 包含协议id文件
local thisPageName = "LevelUpPage"
local curRewardStatus = false -- 不可领取状态
local title = ""
local GuideManager = require("Guide.GuideManager")
require("Battle.NgBattleResultManager")
local rewadItems = {}-- 奖励物品 必须是读配置这种格式10000_1001_50 读出来的数组
local ItemManager = require("Item.ItemManager")
local mCallFun = nil
local OLv = nil
local CLv = nil
local nextResultType = 0


----这里是协议的id
local opcodes = {
    
    }

local option = {
    ccbiFile = "LevelUpPopUp.ccbi",
    handlerMap = {
        -- 按钮点击事件
        onClose = "onClose",
    
    },
    opcode = opcodes
}

local rewardTypeToStr = {"@TLLoadTreasureRewardTxt", "@ACTTLTreasureRaiderRewardTxt"}
local LevelUpPageBase = {}
function LevelUpPageBase:onEnter(container)
    self:registerPacket(container)
    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_12_PLevelUp"
    local spine = SpineContainer:create(spinePath, spineName)
    local spine2 = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local spineNode2 = tolua.cast(spine2, "CCNode")
    local parentNode = container:getVarNode("mSpine")
    local parentNode2 = container:getVarNode("mSpine")
    parentNode:removeAllChildrenWithCleanup(true)
    parentNode2:removeAllChildrenWithCleanup(true)
    local LvAni01 = CCCallFunc:create(function()
        parentNode:addChild(spineNode)
        spine:runAnimation(1, "animation01", 0)
    end)
    local LvAni02 = CCCallFunc:create(function()
        parentNode2:addChild(spineNode2)
        spine2:runAnimation(1, "animation02", -1)
    end)
    local clear = CCCallFunc:create(function()
        parentNode:removeAllChildrenWithCleanup(true)
    end)
    local array = CCArray:create()
    
    array:addObject(CCDelayTime:create(0.2))
    array:addObject(LvAni01)
    array:addObject(CCDelayTime:create(1))
    array:addObject(clear)
    array:addObject(LvAni02)
    
    parentNode:runAction(CCSequence:create(array))
    NodeHelper:setStringForLabel(container, {OriginLv1 = tostring(OLv)})
    NodeHelper:setStringForLabel(container, {CurLv01 = CLv, CurLv02 = CLv})
    local Cfg = ConfigManager.getFunctionUnlock()
    local Show={}
    local nowMap = UserInfo.stateInfo.curBattleMap
    local StringMap = {}
    for i = 1, #Cfg do
        if (Cfg[i].type == 1) and (nowMap-1 <= tonumber(Cfg[i].unlockValue)) then
            table.insert(Show, Cfg[i])
        end
    end
    if Show[1] == nil then
        NodeHelper:setNodesVisible(container, {mUnlockNode = false})
    else
        for i = 1, 3 do
            if nowMap-1 == tonumber(Show[i].unlockValue) then
                StringMap["mTxt0" .. i] = common:getLanguageString("@Activate")
                StringMap["mTitle0" .. i] = common:getLanguageString(Show[i].Function)
            elseif nowMap-1 < tonumber(Show[i].unlockValue) then
                local MapCfg = ConfigManager.getNewMapCfg()
                local String
                if tonumber(Show[i].unlockValue) == 10000 then
                     StringMap["mTxt0" .. i] = common:getLanguageString("@WaitingOpen")
                else
                    String = MapCfg[tonumber(Show[i].unlockValue)].Chapter .. "-" .. MapCfg[tonumber(Show[i].unlockValue)].Level 
                    StringMap["mTxt0" .. i] = common:getLanguageString("@function_unlock", String)
                end
                StringMap["mTitle0" .. i] = common:getLanguageString(Show[i].Function)
            end
        end
        NodeHelper:setStringForLabel(container, StringMap)
    end
    --self:showRewardItems(container)
    if not GuideManager.isInGuide then
        container:runAction(
            CCSequence:createWithTwoActions(
                CCDelayTime:create(1.5),
                CCCallFunc:create(function()
                        --- 弹出评论界面
                        PageManager.showCommentPage(rewadItems)
                end)
    )
    )
    end
    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())
--    local nodeTest = container:getVarNode("mNodeTest")
--    CCArmatureDataManager:sharedArmatureDataManager():addArmatureFileInfo("Reward_animation/Reward_animation.ExportJson")
--    local armatureBird  = CCArmature:create("Reward_animation")
--    nodeTest:addChild(armatureBird)
--    armatureBird:getAnimation():playWithIndex(1)
    SoundManager:getInstance():playMusic("userLevelUp.mp3", false)
    PageManager.setIsInLevelUpPage(true)
end

function LevelUpPageBase:showRewardItems(container)
    NodeHelper:clearScrollView(container)
    --- 这里是清空滚动层
    local size = #rewadItems
    --  BackpackItem.ccbi
    --NodeHelper:buildScrollViewHorizontal(container, size, "CommonRewardContent.ccbi", LevelUpPageBase.onFunction, 0)
    if size <= 4 then
        local node = container:getVarNode("mContent")
        local x = node:getPositionX()
        node:setPositionX(x + (440 - size * 106) / 2)
        node:setTouchEnabled(false)
        NodeHelper:setNodesVisible(container, {mLiftArrow = false, mRightArrow = false})
    end
end

function LevelUpPageBase.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        --- 每个子空间创建的时候会调用这个函数
        local contentId = container:getItemDate().mID
        -- 获取到时第几行
        local i = contentId
        -- 获取当前的index      i是每行的第几个 用来获取组件用的
        local node = container:getVarNode("mItem")
        local itemNode = ScriptContentBase:create("GoodsItem.ccbi")
        local ResManager = require "ResManagerForLua"
        local resInfo = ResManager:getResInfoByTypeAndId(rewadItems[i].type, rewadItems[i].itemId, rewadItems[i].count)
        NodeHelper:setStringForLabel(itemNode, {mName = ""})
        local numStr = ""
        if resInfo.count > 0 then
            numStr = "x" .. resInfo.count
        end
        local lb2Str = {
            mNumber = numStr
        }
        local showName = ""
        if rewadItems[i].type == 30000 then
            showName = ItemManager:getShowNameById(rewadItems[i].itemId)
        else
            showName = resInfo.name
        end
        --NodeHelper:setNodesVisible(itemNode, { m2Percent = false, m5Percent = false });
        if rewadItems[i].multiple and rewadItems[i].multiple == 2 then
            -- 两倍
            NodeHelper:setNodesVisible(itemNode, {m2Percent = true})
        elseif rewadItems[i].multiple and rewadItems[i].multiple == 5 then
            -- 5倍奖励
            NodeHelper:setNodesVisible(itemNode, {m5Percent = true})
        end
        -- NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.BlurryLineWidth + 1000, 4)
        --NodeHelper:setBlurryString(itemNode, "mName", showName, GameConfig.BlurryLineWidth - 10, 4)
        NodeHelper:setStringForLabel(itemNode, lb2Str)
        NodeHelper:setSpriteImage(itemNode, {mPic = resInfo.icon}, {mPic = 1})
        NodeHelper:setQualityFrames(itemNode, {mHand = resInfo.quality})
        NodeHelper:setColorForLabel(itemNode, {mName = ConfigManager.getQualityColor()[resInfo.quality].textColor})
        node:setScale(1.3)
        -- NodeHelper:setColor3BForLabel(itemNode, {mName = common:getColorFromConfig("Own")});
        ----是否是神器  现在强制为第一种神器
        if rewadItems[i].isGodly then
            local aniNode = itemNode:getVarNode("mAni")
            local ccbiFile = GameConfig.GodlyEquipAni.First
            local ani = ScriptContentBase:create(ccbiFile)
            ani:release()
            ani:unregisterFunctionHandler()
            aniNode:addChild(ani)
        end
        node:addChild(itemNode)
        --itemNode:registerFunctionHandler(LevelUpPageBase.onFunction)
        itemNode.id = contentId
        itemNode:release()
    -- end
    elseif eventName == "onHand" then
        local id = container.id
        GameUtil:showTip(container:getVarNode("mHand"), rewadItems[id])
    end
end

function LevelUpPageBase:onExecute(container)

end

function LevelUpPageBase:onExit(container)
    self:removePacket(container)
    onUnload(thisPageName, container)

    nextResultType = NgBattleResultManager_playNextResult()
    PageManager.setIsInLevelUpPage(false)
end

function LevelUpPageBase_onClose()
    PageManager.popPage(thisPageName)
end

function LevelUpPageBase:onClose(container)
    PageManager.popPage(thisPageName)
    
    --if canPlayStory then
    --    local ResultPage=require("Battle.NgBattleResultPage")
    --    canPlayStory = ResultPage:StroyDisplay()
    --end
    if mCallFun then
        mCallFun()
    end
    
-- PageManager.changePage("MainScenePage")
-- PageManager.pushPage("PlayerInfoPage")
end
function LevelUpPageBase:StoryBool(CanPlay)
end
function LevelUpPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    
    if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then
        local msg = HeadFrame_pb.HPHeadFrameStateRet()
        msg:ParseFromString(msgBuff)
        protoDatas = msg
        
        -- self:rebuildItem(container)
        return
    end
end

function LevelUpPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_SEVERINFO_UPDATE then
        -- 这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode
        
        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then
            end
    end
end

function LevelUpPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function LevelUpPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function LevelUpPageBase_setTitle(OriginLv, CurLv)
    OLv = OriginLv
    CLv = CurLv
end

local CommonPage = require("CommonPage")
local LevelUpPage = CommonPage.newSub(LevelUpPageBase, thisPageName, option)

return LevelUpPage
