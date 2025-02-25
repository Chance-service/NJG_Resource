local thisPageName = "RarityUpResult"
local PBHelper = require("PBHelper")
local NgHeadIconItem = require("NgHeadIconItem")
----------------------------------------------------------
-- CONST
local SHOW_ATTR = {
    "MAX_LEVEL", "BATTLE_POWER", Const_pb.STRENGHT, Const_pb.INTELLECT, Const_pb.AGILITY, Const_pb.HP, "STAR_LEVEL"
}
----------------------------------------------------------
local option = {
    ccbiFile = "RarityUP.ccbi",
    handlerMap =
    {
        onClose = "onClose",
    },
    opcode = opcodes
}
local RarityUpPage = { }
local oldAttr = { }
local newAttr = { }
local skillShowTable = { }
local pageItameId = 0
local award = nil
----------------------------------------------------------
function RarityUpPage:onEnter(container)
    mainContainer = container

    NodeHelper:setNodesVisible(container, { mWindow = false })

    local parentNode = container:getVarNode("mSpineNode")
    parentNode:removeAllChildrenWithCleanup(true)
    local spine = SpineContainer:create("Spine/NGUI", "NGUI_05_RairtyUp")
    spine:runAnimation(1, "animation", 0)
    local spineNode = tolua.cast(spine, "CCNode")
    parentNode:addChild(spineNode)

    self:initSkillShowTable()
    self:onRefreshPage(container)

    local array = CCArray:create()
    array:addObject(CCDelayTime:create(1.5))
    array:addObject(CCCallFunc:create(function()
        NodeHelper:setNodesVisible(container, { mWindow = true })
    end))
    container:runAction(CCSequence:create(array))
end
-- 顯示刷新
function RarityUpPage:onRefreshPage(container)
    -- 英雄頭像
    NgHeadIconItem_setPageType(GameConfig.NgHeadIconType.RARITY_UP_PAGE)
    for i = 1, 2 do
        local parentNode = container:getVarNode("mHeadNode" .. i)
        NgHeadIconItem:createByItemId(pageItameId, parentNode, GameConfig.NgHeadIconType.RARITY_UP_PAGE, 
                                      { fight = (i == 1) and oldAttr[2] or newAttr[2], starLevel = (i == 1) and oldAttr[7] or newAttr[7] })
    end
    -- 屬性變化
    for i = 1, #SHOW_ATTR do
        NodeHelper:setStringForLabel(container, {
            ["mAttr" .. i .. "_1"] = oldAttr[i],
            ["mAttr" .. i .. "_2"] = newAttr[i],
        })
    end
    -- 技能變化
    if skillShowTable[newAttr[7]] then
        NodeHelper:setSpriteImage(container, { mSkillIcon1 = "skill/S_" .. skillShowTable[newAttr[7]].skillBaseId .. ".png",
                                               mSkillIcon2 = "skill/S_" .. skillShowTable[newAttr[7]].skillBaseId .. ".png" })
        NodeHelper:setStringForLabel(container, { mSkillLevel1 = (skillShowTable[newAttr[7]].skillLevel - 1),
                                                  mSkillLevel2 = skillShowTable[newAttr[7]].skillLevel })
        NodeHelper:setNodesVisible(container, { mSkillNode = true })
    else
        NodeHelper:setNodesVisible(container, { mSkillNode = false })
    end
end
function RarityUpPage:onClose(container)
    container:stopAllActions()
    oldAttr = { }
    newAttr = { }
    skillShowTable = { }
    pageItameId = 0
    -- 跳獎勵視窗
    self:showAward()
    award = nil
    PageManager.popPage(thisPageName)
end

function RarityUpPage:onExit(container)
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        GuideManager.forceNextNewbieGuide()
    end
end

function RarityUpPage:showAward()
    local rewards = common:split(award, ",")
    local showReward = { }
    for i = 1, #rewards do
        local oneReward = common:split(rewards[i], "_")
        local resInfo = { }
        resInfo["type"] = tonumber(oneReward[1])
        resInfo["itemId"] = tonumber(oneReward[2])
        resInfo["count"] = tonumber(oneReward[3])
        showReward[#showReward + 1] = #resInfo > 0 and resInfo or nil
    end
    if #showReward > 0 then
        local CommonRewardPage = require("CommPop.CommItemReceivePage")
        CommonRewardPage:setData(showReward, common:getLanguageString("@ItemObtainded"), nil)
        PageManager.pushPage("CommPop.CommItemReceivePage")
    end
end

function RarityUpPage:initSkillShowTable()
    local heroCfg = ConfigManager.getNewHeroCfg()[pageItameId]
    local skills = common:split(heroCfg.Skills, ",")
    for i = 6, GameConfig.MAX_HERO_STAR do
        local tarSkillId = ((i == 6 or i == 10) and skills[1]) or ((i == 7 or i == 11) and skills[2]) or 
                           ((i == 8 or i == 12) and skills[3]) or nil
        if tarSkillId then
            local skillBaseId = math.floor(tarSkillId / 10)
            local skillLevel = ((i >= 6 and i <= 9) and 2) or ((i >= 10 and i <= 13) and 3) or 1
            skillShowTable[i] = { skillBaseId = skillBaseId, skillLevel = skillLevel }
        end
    end
end

function RarityUpPage_setOldAttr(curRoleInfo, maxLevel)
    oldAttr[1] = maxLevel
    oldAttr[2] = curRoleInfo.fight
    oldAttr[3] = PBHelper:getAttrById(curRoleInfo.attribute.attribute, SHOW_ATTR[3])
    oldAttr[4] = PBHelper:getAttrById(curRoleInfo.attribute.attribute, SHOW_ATTR[4])
    oldAttr[5] = PBHelper:getAttrById(curRoleInfo.attribute.attribute, SHOW_ATTR[5])
    oldAttr[6] = PBHelper:getAttrById(curRoleInfo.attribute.attribute, SHOW_ATTR[6])
    oldAttr[7] = curRoleInfo.starLevel
    pageItameId = curRoleInfo.itemId
end

function RarityUpPage_setNewAttr(curRoleInfo, maxLevel, _award)
    newAttr[1] = maxLevel
    newAttr[2] = curRoleInfo.fight
    newAttr[3] = PBHelper:getAttrById(curRoleInfo.attribute.attribute, SHOW_ATTR[3])
    newAttr[4] = PBHelper:getAttrById(curRoleInfo.attribute.attribute, SHOW_ATTR[4])
    newAttr[5] = PBHelper:getAttrById(curRoleInfo.attribute.attribute, SHOW_ATTR[5])
    newAttr[6] = PBHelper:getAttrById(curRoleInfo.attribute.attribute, SHOW_ATTR[6])
    newAttr[7] = curRoleInfo.starLevel
    award = _award
end

local CommonPage = require('CommonPage')
local RarityUpPage = CommonPage.newSub(RarityUpPage, thisPageName, option)
