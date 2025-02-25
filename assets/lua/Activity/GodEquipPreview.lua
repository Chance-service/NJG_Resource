--[[
	奖励预览
--]]

local CommonPage = require("CommonPage");
local NodeHelper = require("NodeHelper");
local ResManagerForLua = require("ResManagerForLua");
local thisPageName = "GodEquipPreview"
local ItemManager = require("Item.ItemManager")
local ITEM_PER_LINE = 5;
local option = {
    ccbiFile = "Act_TreasureRaidersRewardPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp",
        onCancel = "onClose",
    }
};

local RewardItem = {
    ccbiFile = "Act_TreasureRaidersRewardContent.ccbi",
}

local EquipPreviewCfg = { }
local rewardTitleStr = ""
local rewardPreviewHintStr = ""
local helpKey = nil
function RewardItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        RewardItem.onRefreshItemView(container);
    elseif eventName:sub(1, 6) == "onFeet" then
        RewardItem.showItemInfo(container, eventName)
    end
end

function RewardItem.onRefreshItemView(container)
    local index = container:getItemDate().mID;
    local rewardShowTable = { }
    for i = 1, ITEM_PER_LINE do
        if EquipPreviewCfg[(index - 1) * 4 + i] ~= nil then
            local rewardCfg = EquipPreviewCfg[(index - 1) * 4 + i]
            if rewardCfg.type then
                table.insert(rewardShowTable, rewardCfg)
            elseif rewardCfg.items then
                local items = { }
                local _type, _id, _count = unpack(common:split(rewardCfg.items, "_"));
                table.insert(rewardShowTable, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count)
                } );
            end

        end
    end
    RewardItem:fillRewardItem(container, rewardShowTable)
end

function RewardItem:fillRewardItem(container, rewardCfg)
    local nodesVisible = { };
    local lb2Str = { };
    local sprite2Img = { };
    local menu2Quality = { };
    local scaleMap = { }
    local colorMap = { }
    for i = 1, ITEM_PER_LINE do
        local cfg = rewardCfg[i];
        nodesVisible["mTreasureHuntRewardNode" .. i] = cfg ~= nil;
        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
            if resInfo ~= nil then
                sprite2Img["mTextPic" .. i] = resInfo.icon;

                scaleMap["mTextPic" .. i] = resInfo.iconScale
                lb2Str["mNum" .. i] = cfg.count > 0 and "x" .. cfg.count or "";
                --[[lb2Str["mName" .. i] = ItemManager:getShowNameById(cfg.itemId)
                if cfg.itemId == 1001 then 
                   lb2Str["mName" .. i] = resInfo.name
                end ]]
                lb2Str["mName" .. i] = "" --取消顯示物品名稱
                menu2Quality["mFeet" .. i] = resInfo.quality

                -- colorMap["mNum" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                colorMap["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor

                sprite2Img["mBg_" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality)

            else
                CCLuaLog("Error::***reward item not found!!");
            end
        end
    end

    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setColorForLabel(container, colorMap)
end


function RewardItem.showItemInfo(container, eventName)
    local index = container:getItemDate().mID
    local rewardIndex = tonumber(eventName:sub(7)) + ITEM_PER_LINE * (index - 1)
    local items = { }
    if EquipPreviewCfg[rewardIndex].type then
        items = EquipPreviewCfg[rewardIndex]
    elseif EquipPreviewCfg[rewardIndex].items then

        local _type, _id, _count = unpack(common:split(EquipPreviewCfg[rewardIndex].items, "_"));
        items = {
            type = tonumber(_type),
            itemId = tonumber(_id),
            count = tonumber(_count)
        };
    end
    GameUtil:showTip(container:getVarNode('mFeet' .. tonumber(eventName:sub(7))), items)
end

local GodEquipPreviewPageBase = { }
function GodEquipPreviewPageBase:buildItem(container)
    local size = 0;
    size = math.ceil(#EquipPreviewCfg / ITEM_PER_LINE);
    NodeHelper:buildScrollView(container, size, RewardItem.ccbiFile, RewardItem.onFunction);
end

function GodEquipPreviewPageBase:onEnter(container)
    NodeHelper:initScrollView(container, "mContent", 4);
    local node=container:getVarScrollView("mContent")
    node:setTouchEnabled(true)
    NodeHelper:setStringForLabel(container, { mRewardTitle = rewardTitleStr });
    NodeHelper:setStringForLabel(container, { mRewardPreviewText = rewardPreviewHintStr });
    if helpKey == nil then
        NodeHelper:setNodesVisible(container, { mHelpNode = false })
    else
        NodeHelper:setNodesVisible(container, { mHelpNode = true })
    end
    self:buildItem(container)
end	
function GodEquipPreviewPageBase:onClose(container)
    PageManager.popPage(thisPageName);
end

function GodEquipPreviewPageBase:onHelp(container)
    if helpKey ~= nil then
        PageManager.showHelp(helpKey)
        -- helpKey = nil
    end
end

function GodEquipPreviewPageBase:onExit(container)
    NodeHelper:deleteScrollView(container)
end

local RechargePage = CommonPage.newSub(GodEquipPreviewPageBase, thisPageName, option)

function ShowEquipPreviewPage(previewData, titleText, previewText, key, isUseBigPage)
    helpKey = key
    EquipPreviewCfg = previewData
    -- ConfigManager.getGodEquipPreviewCfg()
    rewardTitleStr = titleText
    rewardPreviewHintStr = previewText
    if #EquipPreviewCfg > 4 then
        if isUseBigPage then
            option.ccbiFile = "Act_TreasureRaidersRewardPopUp_New.ccbi"
        else
            option.ccbiFile = "Act_TreasureRaidersRewardPopUp.ccbi"
        end
        RewardItem.ccbiFile = "Act_TreasureRaidersRewardContent.ccbi"
    else
        option.ccbiFile = "MapLevelMaxRewardPopUp.ccbi"
        RewardItem.ccbiFile = "MapLevelMaxRewardContent.ccbi"
    end
end