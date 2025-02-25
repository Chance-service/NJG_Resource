
local thisPageName = "CommonAwardPreviewListPage";
local NodeHelper = require("NodeHelper");
local UserInfo = require("PlayerInfo.UserInfo");
local _SaveConfigCfg = {}

local option = {
    ccbiFile = "Act_TimeLimitGirlsMeetIllustratedContent.ccbi",
    handlerMap =
    {
        onClose = "onClose"
    }
};

local CommonAwardPreviewBase = {};

local SuitShowList = {}
local ConstCountNumberItem = 10;--最多十个
local _SuitCount = 0--总的个数
local scrollView = nil
local containerRef = nil
-----------------------------------------------------------------------
function CommonAwardPreviewBase:onEnter(container)
    NodeHelper:initScrollView(container, 'mContent', 10)
    scrollView = container.mScrollView
    containerRef = container
    self:getReadTxtInfo()
    self:refreshPage(container)
end

--读取配置文件信息
function CommonAwardPreviewBase:getReadTxtInfo()
    SuitShowList = {};
    _SuitCount = 0;
    for i = 1,#_SaveConfigCfg do
        if SuitShowList["list".._SaveConfigCfg[i].type] == nil then
            SuitShowList["list".._SaveConfigCfg[i].type] = {}
            _SuitCount = _SuitCount + 1
        end
       table.insert( SuitShowList["list".._SaveConfigCfg[i].type] , _SaveConfigCfg[i]);
    end
end

function CommonAwardPreviewBase:onExecute(container)
end

function CommonAwardPreviewBase:onExit(container)
    NodeHelper:deleteScrollView(container);
    onUnload(thisPageName, container);
end

function CommonAwardPreviewBase:refreshPage(container)
      self:refreshButton(container)
      self:rebuildAllItem(container)
end

function CommonAwardPreviewBase:refreshButton(container)

end

-------------------------------------------------------------------------
----------------click event------------------------

function CommonAwardPreviewBase:onClose(container)
	  PageManager.popPage(thisPageName)
end

----------------scrollview item-------------------------

local SuitsItem = {
    ccbiFile = 'Act_TimeLimitGirlsMeetIllustratedListContent.ccbi'
}

function SuitsItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		  SuitsItem.onRefreshItemView(container)
    elseif string.sub(eventName,1,7)=="onFrame" then
        SuitsItem.showItemInfo(container, eventName)
	end  
end
local isref = true

function CommonAwardPreviewBase:buildScrollView(container, size, ccbiFile, funcCallback, notOffset)
	if size == 0 or ccbiFile == nil or ccbiFile == '' or funcCallback == nil then return end
	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
	local fOneItemWidth = 0

	for i=size, 1, -1 do
		local pItemData = CCReViSvItemData:new_local()
		pItemData.mID = i
		pItemData.m_iIdx = i
        local listRewards = SuitShowList["list"..i]
		if iCount < iMaxNode then
			local pItem = ScriptContentBase:create(ccbiFile)
            if #listRewards <= 5 then--小于5个只有一行
               pItem:setContentSize(CCSizeMake(pItem:getContentSize().width,pItem:getContentSize().height - 105));
            end
        
            pItem.id = iCount
			pItem:registerFunctionHandler(funcCallback)
            pItemData.m_ptPosition = ccp(0, fOneItemHeight)
			local OneItemHeight = pItem:getContentSize().height
            fOneItemHeight = fOneItemHeight + OneItemHeight;
            
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end

	local size = CCSizeMake(fOneItemWidth, fOneItemHeight)
	container.mScrollView:setContentSize(size)
	if not notOffset then
		container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
	end
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount-1);
	container.mScrollView:forceRecaculateChildren();
	ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end

function SuitsItem.onRefreshItemView(container)
    local index = container:getItemDate().mID;
    local listRewards = SuitShowList["list"..index]
    if not listRewards then return end
    local cfg = {};
    local lb2Str = {};
    local sprite2Img = {};
    local menu2Quality = {};
    local idx = 1;
    --如果小于等于5个，显示下面一排，并改变高度
    if (#listRewards) > 5 then -- 上一排是从6-10，下一排1-5
        idx = 6;
    end
    --mFrameShade1 mPic1 mHand1 mName1 mNumber1 mGoodsAni1 
    for i = 1, ConstCountNumberItem do
        cfg = listRewards[i]
        if cfg then--改变数据
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.rewards[1].type, cfg.rewards[1].itemId, cfg.rewards[1].count);
            sprite2Img["mPic" .. idx]         = resInfo.icon;
            sprite2Img["mFrameShade".. idx]   = NodeHelper:getImageBgByQuality(resInfo.quality);
            lb2Str["mNumber" .. idx]          = "x" .. GameUtil:formatNumber( cfg.rewards[1].count );
            lb2Str["mName" .. idx]            = resInfo.name;
            menu2Quality["mFrame" .. idx]      = resInfo.quality
            NodeHelper:setSpriteImage(container, sprite2Img);
            NodeHelper:setQualityFrames(container, menu2Quality);
            NodeHelper:setStringForLabel(container, lb2Str);
            if string.sub(resInfo.icon, 1, 7) == "UI/Role" then 
                NodeHelper:setNodeScale(container, "mPic" .. idx, 0.84, 0.84)
            else
                NodeHelper:setNodeScale(container, "mPic" .. idx, 1, 1)
            end
        else--隐藏多余的
            container:getVarNode("mRewardNode" .. idx):setVisible( false )
        end
        idx = idx + 1
        if idx > 10 then
            idx = 1;
        end
    end
    NodeHelper:setStringForLabel(container, {mRewardTitleTxt = common:getLanguageString(listRewards[1].title)});
    if (#listRewards) <= 5 then--小于5个只有一行
        container:getVarNode("mRewardTitleTxt"):setPositionY(container:getVarNode("mRewardTitleTxt"):getPositionY()-105);
        container:getVarNode("m9S1"):setContentSize(CCSizeMake(container:getVarNode("m9S1"):getContentSize().width,container:getVarNode("m9S1"):getContentSize().height - 105));
        container:getVarNode("m9S2"):setContentSize(CCSizeMake(container:getVarNode("m9S2"):getContentSize().width,container:getVarNode("m9S2"):getContentSize().height - 105));
    end

end	

function SuitsItem.showItemInfo(container, eventName)
    local index = container:getItemDate().mID;
    local listRewards = SuitShowList["list"..index];
    local index_child = tonumber(eventName:sub(8))
    local idx = index_child;
    if (#listRewards) > 5 then -- 上一排是从6-10，下一排1-5
        if index_child > 5 then
            idx = index_child - 5;
        else
            idx = index_child + 5;
        end
    end
    local info = listRewards[idx].rewards[1]
    GameUtil:showTip(container:getVarNode("mPic"..index_child), info)
end

----------------scrollview-------------------------
function CommonAwardPreviewBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function CommonAwardPreviewBase:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end

function CommonAwardPreviewBase:buildItem(container)
    NodeHelper:clearScrollView(container)  ---这里是清空滚动层
    CommonAwardPreviewBase:buildScrollView(container, _SuitCount, SuitsItem.ccbiFile, SuitsItem.onFunction);
end

function CommonAwardPreviewBase_setConfigCfg(data)
    _SaveConfigCfg = {}
    _SaveConfigCfg = data
end
----------------------------------------------------------------
local CommonPage = require("CommonPage");
local CommonAwardPreviewListPage = CommonPage.newSub(CommonAwardPreviewBase, thisPageName, option)
