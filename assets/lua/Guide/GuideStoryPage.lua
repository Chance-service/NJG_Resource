local thisPageName = "GuideStoryPage"
local GuideManager = require("Guide.GuideManager")
local MANAGER = require("Guide.GuideStoryManager")

local option = {
    ccbiFile = "NewBieGuideEmptyPage.ccbi",
    handlerMap =
    {
        onTutorialSkip = "onReturn",
        onTestSkip = "onTestSkip",
    },
    opcodes =
    {
    }
}

local GuideStoryPage = { }
local libPlatformListener = { }
local pageContainer = nil
local isCloseing = false

function libPlatformListener:onPlayMovieEnd(listener)
    if isCloseing then
        return
    end
    CCLuaLog("onPlayMovieEnd")
    if not listener then return end
    isCloseing = true
    GuideStoryPage:onClose(container)
end

function GuideStoryPage:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GuideStoryPage:onEnter(container)
    NodeHelper:setNodesVisible(container, { mTestNode = libOS:getInstance():getIsDebug() })
    isCloseing = false
    pageContainer = container
    GuideManager.PageContainerRef[thisPageName] = container
    GuideStoryPage.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)

    SoundManager:getInstance():stopMusic()

    local langType = CCUserDefault:sharedUserDefault():getIntegerForKey("LanguageType")
    local preName = "phase"
    if langType == kLanguageChinese then
		preName = preName
	elseif langType == kLabguageCH_TW then
		preName = preName .. "TW"
	else
		preName = preName
    end
    GamePrecedure:getInstance():playMovie(preName .. MANAGER.PLAYING_LIST_IDX, 0, 0)
    GameUtil:setPlayMovieVisible(false) 

    local cfg = GuideManager.getCurrentCfg()
    if cfg.showType == GameConfig.GUIDE_TYPE.PLAY_OP_MOVIE and tonumber(cfg.funcParam) == 3 then
        GuideManager.forceNextNewbieGuide()
    end
end

function GuideStoryPage:onClose(container)
    MainFrame_setGuideMask(true)
    local cfg = GuideManager.getCurrentCfg()
    if cfg.showType == GameConfig.GUIDE_TYPE.POP_NEWBIE_PAGE and tonumber(cfg.funcParam) == 3 then
        --
        local spinePath = "Spine/NGUI"
        local spineName = "NGUI_77_Shady"
        local spine = SpineContainer:create(spinePath, spineName)
        local shadeNode = tolua.cast(spine, "CCNode")
        
        local array = CCArray:create()
        array:addObject(CCCallFunc:create(function()
            GuideManager.forceNextNewbieGuide()
            local currPage = MainFrame:getInstance():getCurShowPageName()
            if currPage ~= "MainScenePage" then
                MainFrame_onMainPageBtn(true, true)
            end
            --
            --NodeHelper:setNodesVisible(pageContainer, { mLayerBg = false, mLayerBox = false, mSkipBtn = false, mTxtSpineNode = false, mStory = false })
            --
        end))
        array:addObject(CCDelayTime:create(1.5))
        array:addObject(CCCallFunc:create(function()
            CCLuaLog("onPlayMovieEnd onClose1")
            GuideManager.forceNextNewbieGuide()
            PageManager.popPage(thisPageName)
            PageManager.popPage("DecisionPage")
            --if GuideStoryPage.libPlatformListener then
            --    GuideStoryPage.libPlatformListener:delete()
            --end
            GameUtil:setPlayMovieVisible(true)
        end))
        local scale = NodeHelper:getScaleProportion()
        shadeNode:setScale(scale)
        spine:runAnimation(1, "Enter", 0)
        pageContainer:runAction(CCSequence:create(array))
    else
        CCLuaLog("onPlayMovieEnd onClose2")
        GuideManager.forceNextNewbieGuide()
        PageManager.popPage(thisPageName)
        PageManager.popPage("DecisionPage")
        --if GuideStoryPage.libPlatformListener then
        --    GuideStoryPage.libPlatformListener:delete()
        --end
        GameUtil:setPlayMovieVisible(true)
    end
end
------------------------------------- 功能表END
--退出
function GuideStoryPage:onReturn(container)
    local title = common:getLanguageString("@SkipTitle")
    local msg = common:getLanguageString("@SkipStory")
    GamePrecedure:getInstance():pauseMovie()
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
                GuideStoryPage:onClose(container)
            else
                GamePrecedure:getInstance():closeMovie()
                --GameUtil:setPlayMovieVisible(true)
            end
        else
            GamePrecedure:getInstance():resumeMovie()
        end
    end, true, nil, nil, nil, 0.9, true, function() GamePrecedure:getInstance():resumeMovie() end)
end

function GuideStoryPage.onFunction(eventName, container)
    if eventName ~= "luaExecute" then
    end
    if eventName == "luaLoad" then
        GuideStoryPage:onLoad(container)
    elseif eventName == "luaEnter" then
        GuideStoryPage:onEnter(container)
    end
end

function GuideStoryPage:onTestSkip(container)
    GuideManager.isInGuide = false
    GuideManager.IsNeedShowPage = false
    GuideManager.currGuide[GuideManager.currGuideType] = 0
    GuideManager:setStepPacket(GuideManager.currGuideType, 0)
    if Golb_Platform_Info.is_win32_platform then
        GuideStoryPage:onClose(container)
    else
        GamePrecedure:getInstance():closeMovie()
        GameUtil:setPlayMovieVisible(true)
    end
    PageManager.popPage(thisPageName)
    MainFrame_onMainPageBtn()
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local GuideStory = CommonPage.newSub(GuideStoryPage, thisPageName, option)

return GuideStory