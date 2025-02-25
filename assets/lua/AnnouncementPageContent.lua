
-- 公告頁面 項目成員
-- 棄案，公告AnnouncePage應該會在C++層處理

----------------------------------------------------------------------------------

local NodeHelper = require("NodeHelper")

local AnnouncementPageContent = {}

local CCBI_FILE = "AnnouncementPageContent.ccbi"

local HANDLER_MAP = {
	onBannerClick = "onBannerClick"
}

function AnnouncementPageContent:new () 
	
	local inst = {}

	inst._isInited = false

	inst.container = nil

	inst.contentHTMLLabel = nil

	
	function inst:init (options)
        if inst._isInited then return inst.container end

		if options == nil then options = {} end

		local text = options["text"]
		if text == nil then text = "" end

		local font = options["font"]
		if font == nil then font = "Helvetica" end

		local size = options["size"]
		if size == nil then size = CCSizeMake(0, 0) end

		-- 建立
        inst.container = ScriptContentBase:create(CCBI_FILE)

		-- 註冊 呼叫 行為
        inst.container:registerFunctionHandler(function (eventName, container)
            local funcName = HANDLER_MAP[eventName]
            local func = inst[funcName]
            if func then
                func(inst, container)
            end
        end)

		inst.contentHTMLLabel = CCHTMLLabel:createWithString(text, size, font)
		inst.container:getVarNode("textNode"):addChild(inst.contentHTMLLabel)
		inst.contentHTMLLabel:setPosition(ccp(0,0))
		inst.contentHTMLLabel:setAnchorPoint(ccp(0,0))

		inst._isInited = true

		return inst.container
	end
	
	function inst:setIcon (imgPath)
		if inst.container == nil then return end
		NodeHelper:setSpriteImage(inst.container, {
			iconImg = imgPath
		})
	end

	function inst:setBanner (imgPath)
		if inst.container == nil then return end
		NodeHelper:setSpriteImage(inst.container, {
			bannerImg = imgPath
		})
	end

	function inst:setTitle (text) 
		if inst.container == nil then return end
		NodeHelper:setStringForTTFLabel(inst.container, {
			titleText = text
		})
	end
	
	function inst:setDateText (text) 
		if inst.container == nil then return end
		NodeHelper:setStringForTTFLabel(inst.container, {
			dateText = text
		})
	end
	
	function inst:setContentText (text) 
		if inst.container == nil then return end
		inst.contentHTMLLabel:setString(text)
		inst.resize()
	end
	
	function inst:resize ()
		if inst.container == nil then return end

		local textReferenceNode = inst.container:getVarNode("textReferenceNode")
		
		local textSize
		local text = inst.contentHTMLLabel:getString()
		if text == "" or text == nil then
			textSize = CCSizeMake(0, 0)
		else
			textSize = inst.contentHTMLLabel:getContentSize()
		end
		textReferenceNode:setContentSize(textSize)

		local topNode = inst.container:getVarNode("topNode")
		local topSize = topNode:getContentSize()

		local rootNode = inst.container:getVarNode("root")
		local rootSize = rootNode:getContentSize()
		rootSize.height = topSize.height + textSize.height
		rootNode:setContentSize(rootSize)
	end

	function inst:reg_onTextClick(fn)
		inst.contentHTMLLabel:registerLuaClickListener(fn)
	end

	function inst:onBannerClick ()
		print("AnnouncementPageContent : onBannerClick")
	end

	return inst
end




function AnnouncementPopPageBase:onEnter(container)
	if AnnouncementPopTitle == nil or AnnouncementPopTitle == "" then
		AnnouncementPopTitle = Language:getInstance():getString("@AnnouncementTitle")
	end
	container:getVarLabelBMFont("mTitle"):setString(AnnouncementPopTitle)
	--members = dynamic_cast<cocos2d::extension::CCScrollView*>(getVariable("mAnnMsgContent"));
	--memberRootNode = members->getContainer();
    AnnouncementPopPageBase.container = container
  
    NodeHelper:initScrollView( container,"mAnnMsgContent",4)
    
    self:createAnnouncement(container)
    self:setTitleImgae(container, AnnouncementPopTitle);

--	AnnouncementPopPageBase.container = container

--    self:initPage(container)

--    self:refreshPage(container)

--    self:selectTab(1)



end

--新增公告版 

function AnnouncementPopPageBase:createAnnouncement(container)

--htmlText:registerListener(htmlText,IRichEventHandler:new())
 --htmlText:registerLuaClickListener(URLlabelCallback)
 --	members->setContentSize(CCSizeMake(members->getContentSize().width, height));
--	members->setContentOffset(ccp(0, size.height - height));
   --scrollview:getContentSize().width

--      htmlText.registerLuaClickListener = function(self, listener)
--        if listener ~= nil then
--            self._listener = listener_mod.NullMessageListener()
--        else
--            self._listener = listener
--        end
--    end

--local touchHandler = function( event )
--    if event.phase == "began" then
--        local t = event.target
--        print( "param1=" .. t.param1 .. ", param2=" .. t.param2 )
--    end
--end
--local  cls = {}
--function cls:fun(root,ele, _id)
--         --self._m= "hello"
--end
--  htmlText.registerLuaClickListener(htmlText,"fun",cls)
 --  local index = AnnouncementPopPageBase.URLlabelCallback
    local callFuncN
--    if FeedBackPage:getInstance() then
--        FeedBackPage:getInstance():URLlabelByLuaCallback()
--        local a = 1
--    else
--        local a = 2
--    end
    if _isFeedBack then
        callFuncN = function(root, ele, _id)
	        local button = ele
            if button then
                local strName = button
                if strName == "URL" then
                    CCLuaLog(_id)
                    FeedBackPage:getInstance():URLlabelForLuaCallback(_id)
                else
                    CCLuaLog(_id)
                    libOS:getInstance():openURL(_id)
                end
            end
        end
    else
        callFuncN = function(root, ele, _id)
	        local button = ele
            if button then
                local strName = button
                if strName == "URL" then
                    CCLuaLog(_id)
                    libOS:getInstance():openURL(openUrl)
                end
            end
        end
    end
    htmlText:registerLuaClickListener(callFuncN)
    
  --IRichEventHandler:new(AnnouncementPopPageBase.URLlabelCallback)
end

function AnnouncementPopPageBase:URLlabelCallback(root,ele, _id)
    

    local button = ele

   if button
     then
--		local  strName = button:getName()
--		local strValue = button:getValue()

--		if(strName.compare("URL") == 0 && !strValue.empty())
--		{
--			if (strValue.find("https")!=strValue.npos)
--			{
--				libOS::getInstance()->openURLHttps(strValue);
--			}
--			else
--			{
--				libOS::getInstance()->openURL(strValue);
--			}
--		}
    end
    return 1
end

function AnnouncementPopPageBase:onExecute(container)
end

function AnnouncementPopPageBase:onExit(container)
	NodeHelper:deleteScrollView(container)
	AnnouncementPopConfg = {}
    AnnouncementPopTitle = ""
    _isFeedBack = false
end

function AnnouncementPopPageBase:initPage( container )
    container.scrollview = container:getVarScrollView("mTypeBtnContent")
	NodeHelper:autoAdjustResizeScrollview(container.scrollview)
	container.mScrollView:setBounceable(false)

	self:buildScrollView(container)
end

-- 規格 : 介面的title name + banner1 => 圖檔名稱
function AnnouncementPopPageBase:setTitleImgae(container, titleName)
    local url_img = titleName .. "banner1.png";
    --NodeHelper:setSpriteImage(container, { ["mPopBannerTouch"] = url_img });
    NodeHelper:setMenuItemImage(container, { mPopBannerTouch = { normal = url_img, press = url_img, disabled = url_img } }); --因為元件是用MenuItem, 所以使用這個函式
end

local AnnounceTypeContainer = {
    ccbiFile = "AnnounceTypeBtn.ccbi",
	container = {},
}

function AnnounceTypeContainer:onAnnounceType(content)
    -- content,self.id,1
    index = tonumber(self.id)
    AnnouncementPopPageBase:selectTab(index)
    AnnouncementPopPageBase:rebuildAllItem(AnnouncementPopPageBase.container)
end

function AnnounceTypeContainer:onRefreshContent(content)
    local container = content:getCCBFileNode()
  	local index = tonumber(self.id)

    local title = ""
    if index <= #AnnouncementPopConfg then
        title = AnnouncementPopConfg[index].title
    end
  	NodeHelper:setStringForLabel(container,{mAnnounceTitle = title})

    AnnounceTypeContainer.container[index] = container
end

function AnnouncementPopPageBase:selectTab(index)
	for i = 1,#AnnouncementPopConfg do
		if AnnounceTypeContainer.container[i] then
			NodeHelper:setMenuItemSelected( AnnounceTypeContainer.container[i], {mAnnounceTypeBtn = (i == index)})
		end
	end
end

--构建标签页
function AnnouncementPopPageBase:buildScrollView(container)
	local scrollview = container.scrollview
	scrollview:removeAllCell()
    
	local ccbiFile = AnnounceTypeContainer.ccbiFile
	local totalSize = #AnnouncementPopConfg
	if totalSize == 0 then return end
	
	local cell = nil	
	for i=1,totalSize do
		cell = CCBFileCell:create()
		cell:setCCBFile(ccbiFile)
        local panel = common:new({id=i},AnnounceTypeContainer)
	    cell:registerFunctionHandler(panel)
        
		scrollview:addCell(cell)
		local pos = ccp(cell:getContentSize().width *(i-1), 10)
		cell:setPosition(pos)	
		
	end
	local size = CCSizeMake(cell:getContentSize().width *totalSize,cell:getContentSize().height )
	scrollview:setContentSize(size)
    local x = scrollview:getViewSize().width - scrollview:getContentSize().width * scrollview:getScaleX() -- scrollview:getViewSize().width - scrollview:getContentSize().width * scrollview:getScaleX() * totalSize
	scrollview:setContentOffset(ccp(0, 0))
	scrollview:forceRecaculateChildren()

    scrollview:setTouchEnabled((totalSize >= 3))
end

function AnnouncementPopPageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

local AnnouncementPopItem = {
	
}

function AnnouncementPopItem.onFunction(eventName,container)
	if eventName == "luaRefreshItemView" then
		AnnouncementPopItem.onRefreshItemView(container)
	end
end

function AnnouncementPopItem.onRefreshItemView(container)
	
end

function AnnouncementPopPageBase:refreshPage(container)
	self:rebuildAllItem(container)
end

function AnnouncementPopPageBase:rebuildAllItem(container)
	self:clearAllItem(container)
	self:buildItem(container)
end

function AnnouncementPopPageBase:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end

function AnnouncementPopPageBase:setTitle(title)
	AnnouncementPopTitle = Language:getInstance():getString(title)
end



function AnnouncementPopPageBase:buildItem(container)
	--NodeHelper:buildScrollView(container, #HelpConfg, "HelpContent.ccbi", HelpItem.onFunction);
    if container.m_pScrollViewFacade then
		container.m_pScrollViewFacade:clearAllItems();
	end
	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
	local fOneItemWidth = 0

    if index > #AnnouncementPopConfg then
        return
    end

    local Announcetable = {}  --
    table.insert(Announcetable, AnnouncementPopConfg[index].content)

	for i=#Announcetable, 1, -1 do
		local pItemData = CCReViSvItemData:new_local()
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)

		if iCount < iMaxNode then
			local pItem = ScriptContentBase:create("GeneralHelpContent.ccbi")

            pItem.id = iCount
			pItem:registerFunctionHandler(AnnouncementPopItem.onFunction)
			
			local itemHeight = 0
			
			local nameNode = pItem:getVarLabelBMFont("mLabel")
			CCLuaLog("html -------star")
			local cSize = NodeHelper:setCCHTMLLabelDefaultPos( nameNode , CCSize(460,200) , Announcetable[i]  ):getContentSize()
			
			if fOneItemHeight < cSize.height then
				fOneItemHeight = cSize.height 
			end
        
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end

	local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount )
	container.mScrollView:setContentSize(size)
    local offsetY = container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()
	container.mScrollView:setContentOffset(ccp(0, offsetY))
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView:forceRecaculateChildren()
	ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end

function AnnouncementPopPageBase:SetMessage(dataCfg)
    AnnouncementPopConfg = dataCfg
    --table.insert(AnnouncementPopConfg,content)
    --table.insert(AnnouncementPopConfg,"sadaadsdsadsafsafasfasf,plfp[,l[psfp[asfp")
end

function AnnouncementPopPageBase:setIsFeedBack(isFeedBack)
    _isFeedBack = isFeedBack
end 

local CommonPage = require("CommonPage");
AnnouncementPopPage = CommonPage.newSub(AnnouncementPopPageBase, thisPageName, option);

return AnnouncementPopPageBase