local NodeHelper = require("NodeHelper")
local thisPageName = "EquipIntegrationPage"

local EquipIntegrationPage = { }
local mCurrentPageIndex = 2
local mSelfContainer = nil
local mSubNode = nil
local helpIndex = { [1] = GameConfig.HelpKey.HELP_SMELT, [2] = GameConfig.HelpKey.HELP_SMELT, [3] = GameConfig.HelpKey.HELP_SMELT }
local subPageName = { [1] = "RunePage", [2] = "EquipBuildPage", [3] = "GodlyEquipBuildPage" }
local menuItmeImageList = {}
local subPageCount = 3
local isBattleView = false
local option = {
    ccbiFile = "EquipmentIntegrationPage.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp",
        onPage_1 = "onPage_1",
        onPage_2 = "onPage_2",
        onPage_3 = "onPage_3",
        onAddDiamond = "onAddDiamond",
        onAddCoin = "onAddCoin",
    },
}

local PageTab = {
    onPage_1 = 1,
    onPage_2 = 2
}

function EquipIntegrationPage_SetCurrentPageIndex(isJump2Page)
    mCurrentPageIndex = isJump2Page
end

function EquipIntegrationPage:onEnter(container)
    mSelfContainer = container
    local bg = container:getVarSprite("mBg")
    local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
    bg:setScale(bg:getScale() * (visibleSize.height / bg:getContentSize().height))
    bg:setScale(NodeHelper:getScaleProportion())
    mSubNode = container:getVarNode("mSubPageNode")
    if mSubNode then
        mSubNode:removeAllChildren()
    end
   
    for i = 1, subPageCount do
        local menuItemImage = container:getVarMenuItemImage("mPage_" .. i)
        if menuItemImage then
            menuItmeImageList[i] = menuItemImage
        end
    end
    
    self:setTabSelected(container)

    self:setMenuSelect(container , mCurrentPageIndex)   
    
    self:refreshPage(container)
    self:refreshAllPoint(container)
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["CastPage"] = container

    container:registerMessage(MSG_REFRESH_REDPOINT)
end

function EquipIntegrationPage:setMenuItemEnabled(container , selectIndex)
    for i = 1, subPageCount do
        if menuItmeImageList[i] then
           menuItmeImageList[i]:setEnabled(not (selectIndex == i))
        end
    end
end

function EquipIntegrationPage:setMenuSelect(container, selectIndex)
   -- NodeHelper:setMenuItemSelected(container, { mPage_1 = selectIndex == 1, mPage_2 = selectIndex == 2, mPage_3 = selectIndex == 3 })

    self:setMenuItemEnabled(container , selectIndex)
end

function EquipIntegrationPage:setTabSelected(container)
    local isCommonTab = mCurrentPageIndex == PageTab.onPage_1
    NodeHelper:setMenuItemSelected(container, {
        mPage_1 = isCommonTab,
        mPage_2 = not isCommonTab
    } )
    NodeHelper:setNodesVisible(container, { 
        mSelectEffect1 = isCommonTab,
        mSelectEffect2 = not isCommonTab,
    } )
    NodeHelper:setBMFontFile(container, {
        SmeltConfirm = isCommonTab and "Lang/Font-HT-TabPage.fnt" or "Lang/Font-HT-TabPage2.fnt",
        CommonBuild = isCommonTab and "Lang/Font-HT-TabPage2.fnt" or "Lang/Font-HT-TabPage.fnt",
    } )
end

function EquipIntegrationPage:onHelp(container)
    CCLuaLog(mCurrentPageIndex)
    PageManager.showHelp(helpIndex[mCurrentPageIndex])

end

function EquipIntegrationPage:onClose(container)
    PageManager.popPage(thisPageName)
end
--
function EquipIntegrationPage:onAddCoin(container)
    --PageManager.pushPage("MoneyCollectionPage")
end
--
function EquipIntegrationPage:onAddDiamond(container)
    PageManager.pushPage("IAP.IAPPage")
end

function EquipIntegrationPage:onPage_1(container)
    if mCurrentPageIndex == PageTab.onPage_1 then return end

    mCurrentPageIndex = PageTab.onPage_1
    self:setTabSelected(container)
    self:setMenuSelect(container, mCurrentPageIndex)   
    self:refreshPage(container)
end

function EquipIntegrationPage_onPage_2(container)
    if mCurrentPageIndex == PageTab.onPage_2 then return end

    mCurrentPageIndex = PageTab.onPage_2
    self:setTabSelected(container)
    EquipIntegrationPage:setMenuSelect(container, mCurrentPageIndex)
    EquipIntegrationPage:refreshPage(container)
end
function EquipIntegrationPage:onPage_2(container)
    if mCurrentPageIndex == PageTab.onPage_2 then return end

    mCurrentPageIndex = PageTab.onPage_2
    self:setTabSelected(container)
    self:setMenuSelect(container, mCurrentPageIndex)    
    self:refreshPage(container)
end
function EquipIntegrationPage_onPage_3(container)

    if mCurrentPageIndex == 3 then return end
        mCurrentPageIndex = 3
    EquipIntegrationPage:setMenuSelect(container, mCurrentPageIndex)
    EquipIntegrationPage:refreshPage(container)
end

function EquipIntegrationPage:onPage_3(container)
    local currPage = MainFrame:getInstance():getCurShowPageName()
    if mCurrentPageIndex == PageTab.onPage_3 then return end

    mCurrentPageIndex = PageTab.onPage_3

    self:setMenuSelect(container, mCurrentPageIndex)
    self:refreshPage(container)
end

--update
function EquipIntegrationPage:onExecute(container)

end

function EquipIntegrationPage:onExit(container)
    container:removeMessage(MSG_REFRESH_REDPOINT)
    mCurrentPageIndex = PageTab.onPage_2
    self:pageExit(container)
end

function EquipIntegrationPage:pageExit(container)
    if EquipIntegrationPage.subPage then
        EquipIntegrationPage.subPage:onExit(container)
        EquipIntegrationPage.subPage = nil
    end
end

function EquipIntegrationPage:refreshPage(container)
    local page = subPageName[mCurrentPageIndex]
    if page and page ~= "" and mSubNode then
        self:pageExit(container)
        mSubNode:removeAllChildren()
        EquipIntegrationPage.subPage = require(page)
        EquipIntegrationPage.sunCCB = nil
        EquipIntegrationPage.sunCCB = EquipIntegrationPage.subPage:onEnter(container)
        mSubNode:addChild(EquipIntegrationPage.sunCCB)
        EquipIntegrationPage.sunCCB:setAnchorPoint(ccp(0.5,0))
        --EquipIntegrationPage.sunCCB:release()
       
      --  NodeHelper:setNodesVisible(container, { mHelpNode = subPageName[tabIndex] == "EliteMapInfoPage", mEmpty = subPageName[tabIndex] ~= "EliteMapInfoPage" })
    end
    if isBattleView then
        isBattleView = false
        EquipIntegrationPage_onPage_2(mSelfContainer)
    end
end


function EquipIntegrationPage:onReceivePacket(container)
    EquipIntegrationPage.subPage:onReceivePacket(container)
end

function EquipIntegrationPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(container)
    end
    if EquipIntegrationPage.sunCCB and EquipIntegrationPage.sunCCB["onReceiveMessage"] then
        EquipIntegrationPage.sunCCB["onReceiveMessage"](container)
    end
end
function EquipIntegrationPage:refreshAllPoint(container)
    NodeHelper:setNodesVisible(container, { mRedPoint1 = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.FORGE_EQUIP_TAB) })
end

function EquipIntegrationPage_CloseHandler(handler)
   mHandler = handler
end


local CommonPage = require('CommonPage')
EquipIntegrationPage = CommonPage.newSub(EquipIntegrationPage, thisPageName, option)
