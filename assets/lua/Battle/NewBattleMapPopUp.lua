local thisPageName = "NewBattleMapPopUp"

local NewBattleMapPopUp = {
    container = nil
}

local option = {
    ccbiFile = "ChapterChoicePopUp.ccbi",
    handlerMap = {
        onConfirm = "onConfirm",
        onReturn = "onReturn",
        onReturnBtn = "onReturn"
    },
    opcodes = {
    }
}

local FLAG_TYPE = {
    ["CLEAR"] = 1,
    ["NON_OPEN"] = 2,
    ["BATTLE"] = 3
}

local flagType = FLAG_TYPE["NON_OPEN"]
local cityId = 1

local NewBattleMapItem = {}
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
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(self.itemType), tonumber(self.id), tonumber(self.num))
    local lb2Str = { }

    lb2Str["mNumber" .. 1] = self.num

    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, { ["mPic" .. 1] = resInfo.icon }, { ["mPic" .. 1] = resInfo.iconScale })
    NodeHelper:setQualityFrames(container, { ["mHand" .. 1] = resInfo.quality })
    NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. 1] = resInfo.quality })
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, {["mStar"..i]=false});
    end  
    NodeHelper:setNodesVisible(container,{ mShader = false, mName1 = false, mNumber1 = false , mEquipLv = false, mNumber1_1 = false })
    --container:getVarLabelTTF("mNumber1_1"):setString(self.num)
end


function NewBattleMapPopUp:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)

end

function NewBattleMapPopUp:onEnter(container)
    local mapCfg = ConfigManager.getNewMapCfg()
    local mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or
        (mapCfg[UserInfo.stateInfo.passMapId] and UserInfo.stateInfo.passMapId or UserInfo.stateInfo.curBattleMap - 1)
    local Cfg = mapCfg[mapId]

    NodeHelper:setNodesVisible(container, { 
        mChallengeBtnNode = flagType == FLAG_TYPE["BATTLE"],
        mClearBtnNode = flagType == FLAG_TYPE["CLEAR"],
    })
     local txt = common:getLanguageString("@MapFlag" .. cityId)
     container:getVarLabelTTF("mTitle"):setString(txt)
        for i = 1, #mapCfg do
            if mapCfg[i].Chapter == cityId then
                Cfg = mapCfg[i]
                break
            end
        end
    local mapDesNode = container:getVarNode("mMapDescNode")
    local htmlLabel = CCHTMLLabel:createWithString("<p style=\"margin:10\"><font color=\"#513F35\" face = \"Barlow-SemiBold\" size =\"100\">" .. common:getLanguageString("@MapStory" .. cityId) .. "</font></p>", 
                      CCSizeMake(470, 200), "Barlow-SemiBold")
    htmlLabel:setPosition(ccp(0, 190))
    htmlLabel:setAnchorPoint(ccp(0, 1))
    mapDesNode:addChild(htmlLabel)
    
    container:getVarLabelTTF("mRewardTxt1"):setString("+" .. GameUtil:formatDotNumber(Cfg.SkyCoin) .. "/m")
    container:getVarLabelTTF("mRewardTxt2"):setString("+" .. GameUtil:formatDotNumber(Cfg.EXP) .. "/m")
    container:getVarLabelTTF("mRewardTxt3"):setString("+" .. GameUtil:formatDotNumber(Cfg.Potion) .. "/m")
    
    NodeHelper:setSpriteImage(container,{ m_map = "map/map_" .. string.format("%03d", cityId) .. ".png"})

    local scrollview = container:getVarScrollView("mScrollView")
    
    local item = common:split(Cfg.BossDrop, ",")
    local size = #item
    for i = 1, size do
        local itemData, itemId, itemNum = unpack(common:split(item[i], "_"))
        cell = CCBFileCell:create()
        cell:setCCBFile("BackpackItem.ccbi")
        local panel = common:new( {itemType = itemData, id = itemId, num = itemNum }, NewBattleMapItem)
        cell:registerFunctionHandler(panel)
        cell:setScale(0.8)
        cell:setContentSize(CCSize(109, cell:getContentSize().height))
        scrollview:addCell(cell)
    end
    if size <= 5 then
        scrollview:setTouchEnabled(false)
    else
        scrollview:setTouchEnabled(true)
    end
    scrollview:orderCCBFileCells()
end

function NewBattleMapPopUp:onExit(container)

end

function NewBattleMapPopUp:onReturn(container)
    PageManager.popPage(thisPageName)
end

function NewBattleMapPopUp:onConfirm(container)
    PageManager.popPage(thisPageName)
    local pageName = 'NgBattlePage'
	PageManager.changePage(pageName)
end

function NewBattleMapPopUp:setOpenType(openType)
    flagType = openType
end

function NewBattleMapPopUp:setCityId(id)
    cityId = id
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local NewBattleMapPopUpPage = CommonPage.newSub(NewBattleMapPopUp, thisPageName, option)

return NewBattleMapPopUpPage