local thisPageName = "NewBattleBossInfo"

local NewBattleBossInfo = {
    container = nil
}

local option = {
    ccbiFile = "ChapterChoiceInfoPopUp.ccbi",
    handlerMap = {
        onConfirm = "onConfirm",
        onClose = "onClose",
    },
    opcodes = {
    }
}
for i = 1, 5 do
    option.handlerMap["monBtn" .. i] = "onBtn"
end
local iCount = 0
local NewBattleMapItem = { }
local monsterStrInfos = { }
local ITEM_SCALE = 0.758
function NewBattleMapItem:onHand1(container)
  local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(tonumber(self.itemType), tonumber(self.id), tonumber(self.num))
  local items = {
            type = tonumber(self.itemType),
            itemId = tonumber(self.id),
            count = tonumber(self.num)
        };
    GameUtil:showTip(container:getVarNode("mHand1"), items)
end
function NewBattleMapItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(tonumber(self.itemType), tonumber(self.id), tonumber(self.num))
    local lb2Str = { }

    lb2Str["mNumber" .. 1] = self.num

    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, { ["mPic" .. 1] = resInfo.icon }, { ["mPic" .. 1] = resInfo.iconScale })
    NodeHelper:setQualityFrames(container, { ["mHand" .. 1] = resInfo.quality })
    NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. 1] = resInfo.quality })
    NodeHelper:setNodesVisible(container,{ mShader = false, mName1 = false, mNumber1 = false })
    local contentWidth = content:getContentSize().width
    iCount = iCount + 1
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = false })
    end  
    NodeHelper:setNodesVisible(container, { mEquipLv = false })
    container:getVarLabelTTF("mNumber1_1"):setString(self.num)
end

function NewBattleBossInfo:onBtn(container, eventName)
   local idx = tonumber(string.sub(eventName, "-1"))
   if not monsterStrInfos[idx] then return end
   if not FreeTypeConfig[tonumber(monsterStrInfos[idx].Info)] or not FreeTypeConfig[tonumber(monsterStrInfos[idx].Name)] then return end
   local Info = FreeTypeConfig[tonumber(monsterStrInfos[idx].Info)].content
   local Name = FreeTypeConfig[tonumber(monsterStrInfos[idx].Name)].content
   local monBtn = container:getVarNode("mMonBtn" .. idx)
   GameUtil:showTipStr(monBtn, "<br/>" .. Info, false, nil, Name, hideCallBackExt)
end

function NewBattleBossInfo:onEnter(container)
    local allMapCfg = ConfigManager.getNewMapCfg()
    local mapCfg = allMapCfg[UserInfo.stateInfo.curBattleMap]
    --local mainCh, subCh = unpack(common:split(mapCfg.Chapter, "-"))
    local string=common:getLanguageString("@MapFlag" .. mapCfg.Chapter) .. mapCfg.Level
    NodeHelper:setStringForLabel(container, { mTitle = string })

       
    NodeHelper:setSpriteImage(container, { m_Map = "map/map_" .. string.format("%03d", math.ceil(mapCfg.Chapter)).. ".png" })
    
    local mosterIds = common:split(mapCfg.BossID, ",")
    local idx = 1
    for k, v in ipairs(mosterIds) do
        if v ~= "0" then
            local monCfg = ConfigManager.getNewMonsterCfg()
            local monSprite = monCfg[tonumber(v)].Icon
            local monLevel = monCfg[tonumber(v)].Level
            container:getVarLabelTTF("monLevel" .. idx):setString(monLevel)
            NodeHelper:setSpriteImage(container, { ["monsterSprite" .. idx] = monSprite }, { ["monsterSprite" .. idx] = 0.68 })
            NodeHelper:setSpriteImage(container, { ["monsterAb" .. idx] = GameConfig.MercenaryElementImg[monCfg[tonumber(v)].Element] })

            monsterStrInfos[idx] = monsterStrInfos[idx] or { }
            monsterStrInfos[idx].Name = monCfg[tonumber(v)].Name
            monsterStrInfos[idx].Info = monCfg[tonumber(v)].Info

            if (tonumber(v) < 5000) then
                NodeHelper:setNodesVisible(container, { ["BossIcon" .. idx] = false})
            end
            idx = idx + 1
        end
    end 
    for i = idx, 10 do
        NodeHelper:setNodesVisible(container, { ["Node" .. i] = false, ["mMonBtn" .. i] = false })
    end
    local scrollview = container:getVarScrollView("bossScrollView")
    
    local item = common:split(mapCfg.BossDrop, ",")
    local size = #item
    for i = 1, size do
        local itemData, itemId, itemNum = unpack(common:split(item[i], "_"))
        cell = CCBFileCell:create()
        cell:setCCBFile("BackpackItem.ccbi")
        local panel = common:new( { itemType = tonumber(itemData) / 10000, id = itemId, num = itemNum }, NewBattleMapItem)
        cell:registerFunctionHandler(panel)
        cell:setScale(ITEM_SCALE)
        cell:setContentSize(CCSize(cell:getContentSize().width * ITEM_SCALE, cell:getContentSize().height * ITEM_SCALE))
        scrollview:addCell(cell)
    end
    iCount = 0
    if size <= 4 then
        scrollview:setTouchEnabled(false)
    else
        scrollview:setTouchEnabled(true)
    end
    scrollview:orderCCBFileCells()

    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["NewBattleBossInfo"] = container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function NewBattleBossInfo:onExit(container)

end

function NewBattleBossInfo:onClose(container)
    PageManager.popPage(thisPageName)
end

function NewBattleBossInfo:onConfirm(container)
    PageManager.popPage(thisPageName)
	PageManager.changePage("NgBattlePage")
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local NewBattleBossInfoPage = CommonPage.newSub(NewBattleBossInfo, thisPageName, option)

return NewBattleBossInfoPage