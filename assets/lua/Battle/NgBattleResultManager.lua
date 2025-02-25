local CONST = require("Battle.NewBattleConst")
local DATA = require("Battle.NgBattleDataManager")

NgBattleResultManager = NgBattleResultManager or { }
NgBattleResultManager.playType = { NONE = 0, BATTLE_RESULT = 1, LEVEL_UP = 2, H_SCENE = 3, MAIN_STORY = 4, MAIN_H_STORY = 5 ,ALBUM = 6 }

NgBattleResultManager.showReslut = false    -- 戰鬥結算
NgBattleResultManager.showLevelUp = false   -- 升級
NgBattleResultManager.showMainStory = false -- 主線劇情
NgBattleResultManager.showMainHStory = false-- 主線中間H劇情
NgBattleResultManager.showHStory = false    -- 聖女H劇情
NgBattleResultManager.showAlbum = false 


function NgBattleResultManager_clearData()
    NgBattleResultManager.showReslut = false
    NgBattleResultManager.showLevelUp = false
    NgBattleResultManager.showMainStory = false
    NgBattleResultManager.showMainHStory = false
    NgBattleResultManager.showHStory = false
    NgBattleResultManager.showAlbum = false 
end

function NgBattleResultManager_playNextResult(isLose)
    if not isLose then
        if NgBattleResultManager.showReslut then
            PageManager.pushPage("NgBattleResultPage")
            NgBattleResultManager.showReslut = false
            return NgBattleResultManager.playType.BATTLE_RESULT
        end
        if NgBattleResultManager.showLevelUp then
            UserInfo.checkLevelUp()
            NgBattleResultManager.showLevelUp = false
            return NgBattleResultManager.playType.LEVEL_UP
        end
        if NgBattleResultManager.showMainStory then
            PageManager.pushPage("FetterGirlsDiary")
                  
            return NgBattleResultManager.playType.MAIN_STORY
        end
        if NgBattleResultManager.showMainHStory then
            --NgBattleResultManager.showMainHStory = false
            return NgBattleResultManager.playType.MAIN_H_STORY
        end
        if NgBattleResultManager.showAlbum then
            return NgBattleResultManager.playType.ALBUM
        end
        if NgBattleResultManager.showHStory then
            PageManager.pushPage("AlbumStoryDisplayPage")
            NgBattleResultManager.showHStory = false
            return NgBattleResultManager.playType.H_SCENE
        end
        local currPage = MainFrame:getInstance():getCurShowPageName()
        if currPage == "NgBattlePage" then  --回復BGM
            local sceneHelper = require("Battle.NgFightSceneHelper")
            sceneHelper:setGameBgm()
            require("Battle.NgBattlePage")
            NgBattlePageInfo_restartAfk(NgBattleDataManager.battlePageContainer)
        else
            SoundManager:getInstance():playGeneralMusic()
        end
        NgBattleResultManager_clearData()
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            GuideManager.forceNextNewbieGuide()
        else
            -- 關卡進度解鎖引導
            GuideManager.openOtherGuideFun(GuideManager.guideType.DUNGEON, false)
            --GuideManager.openOtherGuideFun(GuideManager.guideType.RARITY_UP, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.MISSION, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.SUMMON, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.RUNE, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.ARENA, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.BOUNTY, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.FUSION, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.GRAIL, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.DUNGEON_2, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.ANCIENT_WEAPON, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.SECRET_MESSAGE, false)
            GuideManager.openOtherGuideFun(GuideManager.guideType.FAST_BATTLE, false)
        end
    end
    -- 同步禮包資訊
    local GuideManager = require("Guide.GuideManager")
    if not GuideManager.isInGuide then
        for i = 1, #ActivityInfo.PopUpSaleIds do
            local actId = ActivityInfo.PopUpSaleIds[i]
            if ActivityConfig[actId].isShowBattle and ActivityInfo:getActivityIsOpenById(actId)  then
                local actFun = _G["ActPopUpSaleSubPage_" .. actId .. "_sendInfoRequest"]
                if actFun then
                    actFun()
                end
            end
        end
    end

    return NgBattleResultManager.playType.NONE
end