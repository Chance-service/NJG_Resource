
local thisPageName = "FairyBlessAwardShowPage";
local NodeHelper = require("NodeHelper");
local UserInfo = require("PlayerInfo.UserInfo");
local suitCfg = ConfigManager.getSuitCfg()

local option = {
    ccbiFile = "Act_TimeLimitGirlsCareIllustratedContent.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onRole1= "onRole",
        onRole2= "onRole",
        onRole3= "onRole",
        onClose = "onClose"
    }
};

local FairyBlessAwardShowBase = {};

local SuitShowList = {}
local ConstCountNumberItem = 10;--最多十个
local SelectIndex = 1--选中的道具
-----------------------------------------------------------------------
function FairyBlessAwardShowBase:onEnter(container)
    NodeHelper:initScrollView(container, 'mContent', 10)
    SuitShowList = ConfigManager.getFairyBlessCfg()
    SelectIndex = 1
    self:onChangeUIData(container,SelectIndex)
end

function FairyBlessAwardShowBase:onExecute(container)
end

function FairyBlessAwardShowBase:onExit(container)
    NodeHelper:deleteScrollView(container);
    onUnload(thisPageName, container);
end

function FairyBlessAwardShowBase:refreshPage(container)
      self:refreshButton(container)
      self:rebuildAllItem(container)
end

function FairyBlessAwardShowBase:refreshButton(container)

end

-------------------------------------------------------------------------
----------------click event------------------------

function FairyBlessAwardShowBase:onClose(container)
	  PageManager.popPage(thisPageName)
end

function FairyBlessAwardShowBase:onRole(container, eventName)
    local index = tonumber( string.sub(eventName,7,-1) )
    self:onChangeUIData( container , index ) 
end

--帮助页面
function FairyBlessAwardShowBase:onHelp( container ) 
    PageManager.showHelp(GameConfig.HelpKey.HELP_SUITHANDBOOK)
end

function FairyBlessAwardShowBase:onChangeUIData( container , index ) 
    local selectMap = {}
    selectMap["mRole"..SelectIndex] = false
    NodeHelper:setMenuItemSelected(container,selectMap)
    SelectIndex = tonumber(index)
    selectMap["mRole"..SelectIndex] = true
    NodeHelper:setMenuItemSelected(container,selectMap)
    self:refreshPage(container)
    -- NodeHelper:setStringForLabel(container, {mSuitName = common:getLanguageString("@MercenaryChipTitle")});
    NodeHelper:setStringForLabel(container, {mSuitName = common:getLanguageString("@ACTTLGirlsCarePrompt"..SelectIndex)});
    -- NodeHelper:setSpriteImage(container, {mSpineNode = ""});
end

----------------scrollview item-------------------------

local SuitsItem = {
    ccbiFile = 'Act_TimeLimitGirlsCareIllustratedListContent.ccbi'
}

function SuitsItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		  SuitsItem.onRefreshItemView(container)
    elseif string.sub(eventName,1,7)=="onFrame" then
        SuitsItem.showItemInfo(container, eventName)
	end  
end

function SuitsItem.onRefreshItemView(container)
    local listRewards = SuitShowList[SelectIndex].rewards
    if not listRewards then return end
    local cfg = {};
    local lb2Str = {};
    local sprite2Img = {};
    local menu2Quality = {};
    --mFrameShade1 mPic1 mHand1 mName1 mNumber1 mGoodsAni1 
    for i = 1, ConstCountNumberItem do
        cfg = listRewards[i]
        if cfg then--改变数据
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
            sprite2Img["mPic" .. i]         = resInfo.icon;
            sprite2Img["mFrameShade".. i]   = NodeHelper:getImageBgByQuality(resInfo.quality);
            lb2Str["mNumber" .. i]          = "x" .. GameUtil:formatNumber( cfg.count );
            lb2Str["mName" .. i]            = resInfo.name;
            menu2Quality["mFrame" .. i]      = resInfo.quality
            NodeHelper:setSpriteImage(container, sprite2Img);
            NodeHelper:setQualityFrames(container, menu2Quality);
            NodeHelper:setStringForLabel(container, lb2Str);
            if string.sub(resInfo.icon, 1, 7) == "UI/Role" then 
                NodeHelper:setNodeScale(container, "mPic" .. i, 0.84, 0.84)
            else
                NodeHelper:setNodeScale(container, "mPic" .. i, 1, 1)
            end
        else--隐藏多余的
            container:getVarNode("mRewardNode" .. i):setVisible( false )
        end
    end
end	

function SuitsItem.showItemInfo(container, eventName)
    local listRewards = SuitShowList[SelectIndex].rewards
    local index_child = tonumber(eventName:sub(8))
    local info = listRewards[index_child]
    GameUtil:showTip(container:getVarNode("mPic"..index_child), info)
end

----------------scrollview-------------------------
function FairyBlessAwardShowBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function FairyBlessAwardShowBase:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end

function FairyBlessAwardShowBase:buildItem(container)
    NodeHelper:clearScrollView(container)  ---这里是清空滚动层
    NodeHelper:buildScrollView(container, 1, SuitsItem.ccbiFile, SuitsItem.onFunction);
end
----------------------------------------------------------------
local CommonPage = require("CommonPage");
local FairyBlessAwardShowPage = CommonPage.newSub(FairyBlessAwardShowBase, thisPageName, option)
