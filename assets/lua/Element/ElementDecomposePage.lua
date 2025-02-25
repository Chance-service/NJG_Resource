
--元素神符分解



--endregion
local BasePage = require("BasePage")
local thisPageName = "ElementDecomposePage"
local ElementManager = require("Element.ElementManager")
local NodeHelper = require("NodeHelper");
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")

local opcodes = {
    ELEMENT_DECOMPOSE_S = HP_pb.ELEMENT_DECOMPOSE_S
}
local option = {
    ccbiFile="ElementRefiningPopUp.ccbi",
    handlerMap ={
        onClose         = "onClose",
        onAutoFilter    = "onAutoFilter",
        onRefining      = "onRefining",
        onHelp      = "onHelp",
    },
    DataHelper = ElementManager
}

local COUNT_ELEMENT_SOURCE_MAX = 6

local Order = {"A", "B", "C", "D", "E", "F"};
for i = 1, COUNT_ELEMENT_SOURCE_MAX do
	option.handlerMap["on" .. Order[i] .. "Hand"] = "goSelectElement";
end

local ElementDecomposePage = {};
local selectedIds = {}
local m_bHasRareEle = false -- 如果有橙色或本职业的弹窗确认是否分解

ElementDecomposePage = BasePage:new(option,thisPageName,nil,opcodes)

function ElementDecomposePage:refreshPage(container)
    self:onAutoFilter(container)
end

function ElementDecomposePage:getPageInfo(container)
    self:refreshPage(container)
end

function ElementDecomposePage:goSelectElement(container,eventName)
    local order = string.sub(eventName,3,3)
    for i=1,#Order do 
        if Order[i]==order then
            if selectedIds[i]~=nil then
                selectedIds[i]=nil
                self:showSourceElement(container)
                return;
            end
        end
    end
    local ids ={}
    for i=1,#selectedIds  do
        if selectedIds[i]~=nil then
            table.insert(ids,selectedIds[i])
        end
    end
    require("ElementSelectPage")
    ElementSelectPage_SelectInfo(EleFilterType.Decompose,SelectType.Multi,ids,function(newSelectIds)
        selectedIds = newSelectIds
        self:showSourceElement(container)
    end)
end 

function ElementDecomposePage:onClose(container)
    selectedIds = {}
    PageManager.popPage(thisPageName)
end 

-- 自动筛选
function ElementDecomposePage:onAutoFilter(container)
    local ids = ElementManager:getElementIdsForSmelt()
	if ids == nil or #ids <= 0 then
        selectedIds ={}
		MessageBoxPage:Msg_Box_Lan("@NoElementToSmelt");
        self:showSourceElement(container);
        return false
	else
		selectedIds = common:table_sub(ids, 1, COUNT_ELEMENT_SOURCE_MAX);
		self:showSourceElement(container);
        return true
	end
    
end
-- 显示
function ElementDecomposePage:showSourceElement(container)
    local lb2Str = {};
	local sprite2Img = {};
	local itemImg2Qulity = {};
	local scaleMap = {};
	local nodesVisible = {};
	m_bHasRareEle = false
	for i = 1, COUNT_ELEMENT_SOURCE_MAX do
		local levelStr = "";
		local enhanceLvStr = "";
		local icon = GameConfig.Image.ClickToSelect;
		local quality = GameConfig.Default.Quality;
		local aniVisible = false;
		local gemVisible = false;
		local roleId = 0
		
		local name= "m" .. Order[i];
		local userElementId = selectedIds[i];
		if userElementId then
			local userElement = ElementManager:getElementInfoById(userElementId);
            levelStr = common:getLanguageString("@MyLevel", ElementManager:getLevelById(userElementId))

			icon = ElementManager:getIconById(userElementId);
			scaleMap[name .. "Pic"]			= 1.0;
			quality = ElementManager:getQualityById(userElementId);
			roleId = tonumber(ElementManager:getRoleById(userElementId))
		end
		
		lb2Str[name .. "Lv"] 			= levelStr;
		lb2Str[name .. "LvNum"]			= enhanceLvStr;
		sprite2Img[name .. "Pic"] 		= icon;
		itemImg2Qulity[name .. "Hand"] 	= quality;
		scaleMap[name .. "Pic"] 		= 1.0;
		nodesVisible[name .. "Ani"]		= aniVisible;
		nodesVisible[name .. "GemNode"]	= gemVisible;

		-- 有橙色要判断分解
		if tonumber(quality)==5 or roleId==UserInfo.roleInfo.prof then
			m_bHasRareEle = true
		end
	end
	
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setNodesVisible(container, nodesVisible);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, itemImg2Qulity);
end
-- 分解
function ElementDecomposePage:onRefining(container)
	if m_bHasRareEle==true then
		local titleStr = common:getLanguageString("@ElementDecompositionConfirmTitle")
		local msgStr = common:getLanguageString("@ElementDecompositionConfirmMsg")
		PageManager.showConfirm(titleStr,msgStr,function( isSure )
			if isSure then
				local ids = self:getValidIds()
			    ElementManager:Decompose(ids)
			end
		end)
	else
	    local ids = self:getValidIds()
	    ElementManager:Decompose(ids)
	end
end
function ElementDecomposePage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_DECELEMENT);
end

function ElementDecomposePage:getValidIds()
    return common:table_arrayFilter(selectedIds, function(id)
		return id ~= nil;
	end);
end