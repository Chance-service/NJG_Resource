local thisPageName = "NgBattleResultPage"
local basePage = require("BasePage")
local NodeHelper = require("NodeHelper")
local pageManager = require("PageManager")
local ConfigManager = require("ConfigManager")
local GameConfig = require("GameConfig")
local UserInfo = require("PlayerInfo.UserInfo")
local ResManager = require("ResManagerForLua")
local Const_pb = require("Const_pb")
local common = require("common")
local CONST = require("Battle.NewBattleConst")
local UserMercenaryManager = require("UserMercenaryManager")
local ALFManager = require("Util.AsyncLoadFileManager")
require("Battle.NgBattleDetailPage")
require("Battle.NgBattleDataManager")
require("Battle.NgBattleResultManager")
local option = {
    ccbiFile = "BattleWinOrLosePopUp_1.ccbi",
    handlerMap =
    {
        onTunkScreenContinue = "onClose",
        onDetail = "onDetail",
        onUpgradeEquipment = "onUpgradeEquipment",
        onMercenaryCulture = "onMercenaryCulture",
        onShopping = "onShopping",
        onClickGuide = "onClose",

        onLoseBtn = "onLoseBtn",
        onWinBtn = "onWinBtn",
        onGuideLoseBtn = "onGuideLoseBtn",

        onHeroPage = "onHeroPage",
        onShopPage = "onShopPage",
        onBountyPage = "onBountyPage",

        onTestLog = "onTestLog",
        onTestDps = "onTestDps",
    }
}
local ItemContentUI = {
    ccbiFile = "GoodsItem.ccbi"
}
local NgBattleResultPage = basePage:new(option, thisPageName)

local rewardItemInfo = { [1] = { type = 30000, itemId = 101001, count = 1 }, [2] = { type = 10000, itemId = 1004, count = 1000 }, [3] = { type = 40000, itemId = 1008, count = 2 } }
NgBattleResultPage.isLevelUP = false
local task = nil

function NgBattleResultPage:resetData()
    rewardItemInfo = { }
    NgBattleResultPage.isLevelUP = false
    if task then
        ALFManager:cancel(task)
        task = nil
    end
end

function NgBattleResultPage:onEnter(container)
    UserInfo.syncRoleInfo()
    -- 計算玩家MVP
    NgBattleDetailPage_calculateMvp(container)

    --self:registerPacket(container)
    container:registerLibOS()
    NodeHelper:setNodesVisible(container, { mTestDpsNode = libOS:getInstance():getIsDebug(), mTestLogNode = libOS:getInstance():getIsDebug() })

    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
       NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        PageManager.pushPage("SingleBoss.SingleBossPopResult")
    end

    local langType = CCUserDefault:sharedUserDefault():getIntegerForKey("LanguageType")
    if NgBattleDataManager.battleResult == CONST.FIGHT_RESULT.WIN or 
       NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS or
       NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
       NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then  -- 世界boss/單人強敵只顯示勝利畫面
        -- 勝利
        NodeHelper:setNodesVisible(container, {
            mWinNode = true,
            mGuideLoseNode = false,
            mLoseNode = false,
        } )
        task = ALFManager:loadSpineTask("Spine/NGUI/", "NGUI_13_BattleWin", 30, function() 
            local spineNode = container:getVarNode("mSpineWin")
            local spine1 = SpineContainer:create("Spine/NGUI", "NGUI_13_BattleWin")
            spine1:setSkin(langType)
            spine1:runAnimation(1, "victory1", 0)
            local sToNode1 = tolua.cast(spine1, "CCNode")
            spineNode:addChild(sToNode1)
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(0))
            array:addObject(CCCallFunc:create(function()
                spine1:runAnimation(1, "victory1", 0)
                spine1:addAnimation(1, "victory2", true)
                SoundManager:getInstance():playMusic("BattleBossWin.mp3", false)
                --SimpleAudioEngine:sharedEngine():playBackgroundMusic("BattleBossWin.mp3", false)
            end))
            spineNode:runAction(CCSequence:create(array))
        end)
        

        -- 經驗顯示
        local getExp = 0
        local idx = 1
        local mExpNum = container:getVarLabelTTF("mRewardExpNum")
        for i = 1, #rewardItemInfo do
            if rewardItemInfo[idx] and rewardItemInfo[idx].itemId == 1004 then    -- 玩家經驗不顯示在獲得物品中
                getExp = rewardItemInfo[idx].count
                table.remove(rewardItemInfo, idx)
                idx = idx - 1
            end
            idx = idx + 1
        end
        mExpNum:setString(common:getLanguageString("@RewardExp", tostring(getExp)))
        self:updateExp(container, getExp)
        -- 玩家頭像顯示
        local roleIcon = ConfigManager.getRoleIconCfg()
        local trueIcon = GameConfig.headIconNew or UserInfo.playerInfo.headIcon
        if not roleIcon[trueIcon] then
            local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
            NodeHelper:setSpriteImage(container, { mHeadIcon = icon })
        else
            NodeHelper:setSpriteImage(container, { mHeadIcon = roleIcon[trueIcon].MainPageIcon })
        end
        -- MVP角色SPINE
        local mvpID = NgBattleDataManager.battleMineCharacter[NgBattleDataManager.playerMvpIndex] and NgBattleDataManager.battleMineCharacter[NgBattleDataManager.playerMvpIndex].otherData[CONST.OTHER_DATA.ITEM_ID] 
                                                                        or 1
        local spineNode = container:getVarNode("mSpine")
        local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(mvpID)
        local spineMvp = nil -- 抓MVP角色
        if roleInfo.skinId > 0 then
            spineMvp = SpineContainer:create("NG2D", "NG2D_" .. string.format("%02d", mvpID) .. string.format("%03d", roleInfo.skinId))
        else
            spineMvp = SpineContainer:create("NG2D", "NG2D_" .. string.format("%02d", mvpID))
        end
        if spineMvp then
            spineMvp:runAnimation(1, "animation", -1)
            local sToNodeMvp = tolua.cast(spineMvp, "CCNode")
            spineNode:setScale(NodeHelper:getScaleProportion())
            spineNode:addChild(sToNodeMvp)
        end

        if #rewardItemInfo > 0 and NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.PVP then  -- PVP用跳窗顯示
            self:initScroll(container)
        end

        -- MVP語音
        NodeHelper:playEffect(mvpID .. "_31.mp3")

        NodeHelper:setNodesVisible(container, { mNormalWinNode = (NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.PVP) and (NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.MULTI), 
                                                mPvpWinNode = NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP,
                                                mDungeonWinNode = NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI,
                                                mWorldBossWinNode = NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS,
                                                mTowerWinNode = (NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER) and (#rewardItemInfo == 0)
        })
        -- PVP排名顯示
        if NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
            local lastTimeRank, currenRank = ArenaPage_getRank()
            currenRank = math.min(lastTimeRank, currenRank)
            local mRankBg_1 = container:getVarSprite("mRankBg_1")
            if lastTimeRank <= 3 then
                mRankBg_1:setTexture(GameConfig.ArenaRankingIcon[lastTimeRank])
                NodeHelper:setStringForLabel(container, { mRankLabel_1 = lastTimeRank })
                NodeHelper:setNodesVisible(container, { mRankLabel_1 = false })
            else
                mRankBg_1:setTexture(GameConfig.ArenaRankingIcon[4])
                NodeHelper:setStringForLabel(container, { mRankLabel_1 = lastTimeRank })
                NodeHelper:setNodesVisible(container, { mRankLabel_1 = true })
            end

            local mRankBg_2 = container:getVarSprite("mRankBg_2")
            if currenRank <= 3 then
                mRankBg_2:setTexture(GameConfig.ArenaRankingIcon[currenRank])
                NodeHelper:setStringForLabel(container, { mRankLabel_2 = currenRank })
                NodeHelper:setNodesVisible(container, { mRankLabel_2 = false })
            else
                mRankBg_2:setTexture(GameConfig.ArenaRankingIcon[4])
                NodeHelper:setStringForLabel(container, { mRankLabel_2 = currenRank })
                NodeHelper:setNodesVisible(container, { mRankLabel_2 = true })
            end
        end
    else
        -- 新手教學
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide and NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE then
            NodeHelper:setNodesVisible(container, {
                mWinNode = false,
                mGuideLoseNode = true,
                mLoseNode = false,
            } )
        else
            -- 失败
            NodeHelper:setNodesVisible(container, {
                mWinNode = false,
                mGuideLoseNode = false,
                mLoseNode = true,
            } )

            task = ALFManager:loadSpineTask("Spine/NGUI/", "NGUI_13_BattleLose", 30, function() 
                local spineNode = container:getVarNode("mSpineLose")
                local spine1 = SpineContainer:create("Spine/NGUI", "NGUI_13_BattleLose")
                spine1:setSkin(langType)
                spine1:runAnimation(1, "defeated1", 0)
                local sToNode1 = tolua.cast(spine1, "CCNode")
                spineNode:addChild(sToNode1)
                local array = CCArray:create()
                array:addObject(CCDelayTime:create(0))
                array:addObject(CCCallFunc:create(function()
                    spine1:runAnimation(1, "defeated1", 0)
                    spine1:addAnimation(1, "defeated2", true)
                end))
                spineNode:runAction(CCSequence:create(array))
                SoundManager:getInstance():playMusic("BattleBossLose.mp3", false)
                --SimpleAudioEngine:sharedEngine():playBackgroundMusic("BattleBossLose.mp3", false)
            end)
        end
    end

    UserInfo.sync()
    PageManager.setAllNotice()
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["NgBattleResultPage"] = container
    if GuideManager.isInGuide then
        GuideManager.forceNextNewbieGuide()
    end

    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then  -- PVP跳獎勵視窗
        if #rewardItemInfo > 0 then
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            CommonRewardPage:setData(rewardItemInfo, common:getLanguageString("@ItemObtainded"), nil)
            PageManager.pushPage("CommPop.CommItemReceivePage")
        end
    end
end

function NgBattleResultPage:initScroll(container)
    NodeHelper:initScrollView(container, "mBattleRewardItem", #rewardItemInfo)
    container.scrollview = container:getVarScrollView("mBattleRewardItem")
    NodeHelper:clearScrollView(container)
    local size = #rewardItemInfo

    NodeHelper:buildScrollViewHorizontal(container, size, "CommonRewardContent.ccbi", NgBattleResultPage.onFunctionCall, 0)

    if size < 4 then
        local node = container:getVarNode("mBattleRewardItem")
        local x = node:getPositionX()
        node:setPositionX(x + (544 - size * 136) / 2)
        node:setTouchEnabled(false)
    end
end

function NgBattleResultPage.onFunctionCall(eventName, container)
    if eventName == "luaRefreshItemView" then
        local contentId = container:getItemDate().mID
        local i = contentId
        -- 當前的index
        local node = container:getVarNode("mItem")
        local itemNode = ScriptContentBase:create("GoodsItem.ccbi")
        local ResManager = require "ResManagerForLua"
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(rewardItemInfo[i].type, rewardItemInfo[i].itemId, rewardItemInfo[i].count)
        NodeHelper:setStringForLabel(itemNode, { mName = "" })
        local lb2Str = {
            mNumber = GameUtil:formatNumber(rewardItemInfo[i].count)
        }
        local showName = ""
        if rewardItemInfo[i].type == 40000 then
            for i = 1, 6 do
                NodeHelper:setNodesVisible(itemNode, { ["mStar" .. i] = i == resInfo.star })
            end
        end
        NodeHelper:setNodesVisible(itemNode, { mNumber = rewardItemInfo[i].type ~= 40000, mStarNode = rewardItemInfo[i].type == 40000 })
        NodeHelper:setStringForLabel(itemNode, lb2Str)
        NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon }, { mPic = GameConfig.EquipmentIconScale })
        NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality })

        node:addChild(itemNode)
        itemNode:registerFunctionHandler(NgBattleResultPage.onFunctionCall)
        itemNode.id = contentId
        itemNode:release()
    elseif eventName == "onHand" then
        -- 點擊物品跳說明
        local id = container.id
        GameUtil:showTip(container:getVarNode("mHand"), rewardItemInfo[id])
        return
    end
end

function NgBattleResultPage:onTestLog()
    PageManager.pushPage("BattleLogPage")
end

function NgBattleResultPage:onTestDps()
    PageManager.pushPage("BattleLogDpsPage")
end

function NgBattleResultPage:onDetail()
    PageManager.pushPage("NgBattleDetailPage")
end
function NgBattleResultPage:onUpgradeEquipment()
    registerScriptPage("EquipIntegrationPage")
    EquipIntegrationPage_CloseHandler(MainFrame_onMainPageBtn())
    EquipIntegrationPage_SetCurrentPageIndex(true)
    PageManager.changePage("EquipIntegrationPage")
    PageManager.popPage(thisPageName)
end
function NgBattleResultPage:onShopping()
    pageManager.changePage("ShopControlPage")
    PageManager.popPage(thisPageName)
end
function NgBattleResultPage:onHeroPage()
    MainFrame_onLeaderPageBtn()
    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(true)
    PageManager.popPage(thisPageName)
end
function NgBattleResultPage:onShopPage()
    PageManager.changePage("ShopControlPage")
    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(true)
    resetMenu("mMainPageBtn", true)
    PageManager.popPage(thisPageName)
end
function NgBattleResultPage:onBountyPage()
    PageManager.changePage("MercenaryExpeditionPage")
    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(true)
    resetMenu("mMainPageBtn", true)
    PageManager.popPage(thisPageName)
end
function NgBattleResultPage:onMercenaryCulture()
    if UserInfo.roleInfo.level < GameConfig.LevelLimit.MecenaryOpenLevel then
        MessageBoxPage:Msg_Box("@MercenaryLevelNotEnough")
        return
    else
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange._IsPageJump = true
        PageJumpMange._CurJumpCfgInfo = PageJumpMange._JumpCfg[25]
        PageManager.changePage("EquipmentPage")
    end
    pageManager.popPage(thisPageName)
end

function NgBattleResultPage:updateExp(container, getExp)
    local mExpBar = container:getVarScale9Sprite("mExpBar")
    local mExpTxt = container:getVarLabelTTF("mExpTxt")

    local currentExp = UserInfo.roleInfo.exp-- + getExp
    local roleExpCfg = ConfigManager.getRoleLevelExpCfg()
    local percent = 0
    local nextLevelExp = 0
    local curLevel = UserInfo.roleInfo.level
    if currentExp ~= nil and roleExpCfg ~= nil then
        nextLevelExp = roleExpCfg[UserInfo.roleInfo.level] and roleExpCfg[UserInfo.roleInfo.level]["exp"] or 0
        if nextLevelExp == 0 then   -- 表格沒有資料
            percent = 1.0
            nextLevelExp = 99999999
        else
            percent = math.min(1, currentExp / nextLevelExp)
        end
        -- 重設9宮格點位(避免數值太小時變形)
        mExpBar:setInsetLeft((500 * percent > 9 * 2) and 9 or (500 * percent / 2))
        mExpBar:setInsetRight((500 * percent > 9 * 2) and 9 or (500 * percent / 2))

        mExpBar:setContentSize(CCSize(500 * percent, 21))
        mExpTxt:setString(currentExp .. "/" .. nextLevelExp)
    end
    -- 等級顯示
    local mLevel = container:getVarLabelTTF("mLevel")
    mLevel:setString("Lv. " .. curLevel)
end

function NgBattleResultPage:onExit(container)
    self:resetData()
end

function NgBattleResultPage:onWinBtn(container)
    local nextShowType = NgBattleResultManager.playType.NONE
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        nextShowType = NgBattleResultManager_playNextResult()
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(48)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(21)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(45)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(49)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
         if (NgBattleDataManager.battleResult == CONST.FIGHT_RESULT.WIN) then
            NgBattleResultManager.showMainStory = NgFightSceneHelper:StorySync(2)--1:戰鬥前 2:戰鬥後
            pageManager.popPage(thisPageName)
            if NgBattleResultManager.showMainStory then return end
         end
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(51)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(52)
     elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(53)
    else
        require("Battle.NgBattlePage")
        NgBattlePageInfo_restartAfk(NgBattleDataManager.battlePageContainer)
    end
    
    PageManager.popPage(thisPageName)
end
function NgBattleResultPage_onGuideWinBtn(container)
    NgBattleResultPage:onWinBtn(container)
end

function NgBattleResultPage:onLoseBtn(container)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        require("Battle.NgBattlePage")
        NgBattlePageInfo_restartAfk(NgBattleDataManager.battlePageContainer)
        NgBattleResultManager_playNextResult(true)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(48)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(21)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(45)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(49)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(51)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(53)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(52)
    else
        require("Battle.NgBattlePage")
        NgBattlePageInfo_restartAfk(NgBattleDataManager.battlePageContainer)
    end
    PageManager.popPage(thisPageName)
end

function NgBattleResultPage:setAward(awardInfo)
    rewardItemInfo = awardInfo
end

return NgBattleResultPage