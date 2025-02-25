

local HelpFightGuideManager = {

}
local UserInfo = require("PlayerInfo.UserInfo")
local Guide_pb = require("Guide_pb")
require("MainFrameScript")
local GuideManager =  require("Guide.GuideManager")
local HelpFightDataManager = require("PVP.HelpFightDataManager")

function HelpFightGuideManager.bieGuide()
    if HelpFightDataManager.LayerInfo then
        if HelpFightDataManager.LayerInfo.layerId == 6 then
            --if GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_2] ~= 0 then
                if GuideManager.isInGuide == false then
                    GuideManager.currGuideType = GuideManager.guideType.HELPFIGHT_GUIDE_2
                    GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_2] = 1
                    GuideManager.newbieGuide()
                    return
                end
            --end
        elseif HelpFightDataManager.LayerInfo.layerId == 12 then
--[[            if GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_2] ~= 0 then
                HelpFightGuideManager.setStepPacket(GuideManager.guideType.HELPFIGHT_GUIDE_2,0 )
            end]]
            --if GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_3] ~= 0 then
                if GuideManager.isInGuide == false then
                    GuideManager.currGuideType = GuideManager.guideType.HELPFIGHT_GUIDE_3
                    GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_3] = 1
                    GuideManager.newbieGuide()
                    return
                end
            --end
        elseif HelpFightDataManager.LayerInfo.layerId == 18 then
--[[            if GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_2] ~= 0 then
                HelpFightGuideManager.setStepPacket(GuideManager.guideType.HELPFIGHT_GUIDE_2,0 )
            end
            if GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_3] ~= 0 then
                HelpFightGuideManager.setStepPacket(GuideManager.guideType.HELPFIGHT_GUIDE_3,0 )
            end]]
            --if GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_4] ~= 0 then
                if GuideManager.isInGuide == false then
                    GuideManager.currGuideType = GuideManager.guideType.HELPFIGHT_GUIDE_4
                    GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_4] = 1
                    GuideManager.newbieGuide()
                    return
                end
            --end
        end
    end
    HelpFightGuideManager.showReward()
end

function HelpFightGuideManager.onSkip()
    GuideManager.currGuide[GuideManager.currGuideType] = 0
    GuideManager.isInGuide = false;
    GuideManager.IsNeedShowPage = false
    HelpFightGuideManager.setStepPacket(  GuideManager.currGuideType,0 )
    --弹出必得奖励
    HelpFightGuideManager.showReward()
end

function HelpFightGuideManager.showReward()
    if HelpFightDataManager.ChallengeData.mustReward then
        local rewardItems = {}
        for i = 1, #HelpFightDataManager.ChallengeData.mustReward.showItems do
            local tmpData = {
                type = HelpFightDataManager.ChallengeData.mustReward.showItems[i].itemType ,
                itemId = HelpFightDataManager.ChallengeData.mustReward.showItems[i].itemId ,
                count = HelpFightDataManager.ChallengeData.mustReward.showItems[i].itemCount,
            }
            table.insert(rewardItems,tmpData)
        end
        if rewardItems and #rewardItems > 0 then
            local CommonRewardPage = require("CommonRewardPage")
            CommonRewardPageBase_setPageParm(rewardItems, true, 2,nil)
            PageManager.pushPage("CommonRewardPage")
        end
    end
end

function HelpFightGuideManager.setStepPacket( typeId,step )
    local msg = Guide_pb.HPResetGuideInfo()
    msg.guideInfoBean.guideId = typeId
    msg.guideInfoBean.step = GuideManager.buildServerStepIdx(step)
    common:sendPacket(HP_pb.RESET_GUIDE_INFO_C , msg ,false)
end

return HelpFightGuideManager
