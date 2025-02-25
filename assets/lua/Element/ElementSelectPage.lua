

--endregion
local BasePage = require("BasePage")
local thisPageName = "ElementSelectPage"
local ElementManager = require("Element.ElementManager")
local UserInfo = require("PlayerInfo.UserInfo")
local NodeHelper = require("NodeHelper")
local Const_pb = require("Const_pb")
local ResManagerForLua = require("ResManagerForLua")
local opcodes = {
    ELEMENT_ADVANCE_S = HP_pb.ELEMENT_ADVANCE_S,
    ELEMENT_LVL_UP_S = HP_pb.ELEMENT_LVL_UP_S,
    ELEMENT_RECAST_S = HP_pb.ELEMENT_RECAST_S,
    ELEMENT_DRESS_S = HP_pb.ELEMENT_DRESS_S
}
local option = {
    ccbiFile="ElementChoicePopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onConfirmation		= "onConfirm"
    },
    DataHelper = ElementManager
}
EleFilterType = {
    Dress = 1,
    Decompose = 2,
    Recaset = 3,
    Upgrade = 4
}
local OccupationLimit = false;
SelectType = {
	Single 	= 1,		--单选
	Multi	= 2			--多选
};
local PageInfo = {
	roleId = UserInfo.roleInfo.roleId,
	selectedEleId = nil,
    currentEleId = nil,
	optionIds = {},
	selectedIds = {},
	selectType = SelectType.Single,
	filterType = EleFilterType.Dress,
	limit = 1,
	isFull = false,
	callback = nil
};
local thisContainer;
local ElementSelectItem = {
    ccbiFile = "ElementChoiceContent.ccbi";
}
local ceil = math.ceil;

local ElementSelectPage = {}

function onFunctionEx(eventName,container)   
end
ElementSelectPage = BasePage:new(option,thisPageName,onFunctionEx,opcodes);

function ElementSelectItem.onFunction(eventName, container)
    if eventName == "luaInitItemView" then
		ElementSelectItem.onRefreshItemView(container);
    elseif eventName=="onInscription" then
        ElementSelectItem.onInscription(container)
    elseif eventName == "onChoice" then
        ElementSelectItem.onSelect(container)
    end
end
function ElementSelectItem.onRefreshItemView(container)
    local index = container:getTag();
    local ele = ElementManager.UserElementMap[PageInfo.optionIds[index]];
    local basicAttrs = ele.basicAttrs.attribute;
    local extraAttrs = ele.extraAttrs.attribute;
    local score = ElementManager:Score(ele.id)
    local profLimit = ele.profLimit;
    local levelInfo = ElementManager:getLevelInfoByLv(ele.level);
    local eleName = ElementManager:getNameById(ele.id);
    local nodes = {}
    local profName = "";
    if profLimit ~=0 then
        profName = common:getLanguageString("@ProfessionName_"..profLimit)
    end
    local lb2Str = {
        mLv = common:getLanguageString("@MyLevel", ele.level),
        mName = eleName,
        mScoreNum = score,
        mOccupationName = profName
    }
    --基础属性的显隐控制
    for i =1 ,8 do
        nodes["mAttributeNode"..i]=false;
    end
    for i=1,#basicAttrs do
        nodes["mAttributeNode"..i]=true;
        local attrName = ElementManager:getAttrNameByAttrId(basicAttrs[i].attrId)
        local value = math.floor(levelInfo[attrName]*(basicAttrs[i].attrValue))
        local attrStr,numStr = ResManagerForLua:getAttributeString(basicAttrs[i].attrId,value)
        lb2Str["mAttribute"..i] =attrStr;
        lb2Str["mAttributeNum"..i] ="+"..numStr
       
    end
    --附加属性的显隐控制
    for i=1,#extraAttrs do
        nodes["mAttributeNode"..(i+4)]=true;
        local attrName = ElementManager:getAttrNameByAttrId(extraAttrs[i].attrId)
        local value = math.floor(levelInfo[attrName]*(extraAttrs[i].attrValue))
        local attrStr,numStr = ResManagerForLua:getAttributeString(extraAttrs[i].attrId,extraAttrs[i].attrValue)
        lb2Str["mAttribute"..(i+4)] =attrStr;
        lb2Str["mAttributeNum"..(i+4)] ="+"..numStr
           
    end
    
    --元素分解,元素升级材料选择是多选按钮，
    local nodesVisible = {};
    if PageInfo.filterType==EleFilterType.Decompose or PageInfo.filterType==EleFilterType.Upgrade then
        nodesVisible = {
            mInscriptionNode = false,
            mChoiceNode = true
        }
        local isSelected = common:table_hasValue(PageInfo.selectedIds, ele.id);
	    NodeHelper:setNodesVisible(container,{mChoice =not isSelected,mChoiceSelected = isSelected})
    --铭刻是单选
    elseif PageInfo.filterType==EleFilterType.Dress then
        nodesVisible = {
            mInscriptionNode = true,
            mChoiceNode = false
        }
    end

    if PageInfo.selectType == SelectType.Multi then
        local btnVisible = {}
        local isSelected = common:table_hasValue(PageInfo.selectedIds, ele.id);
        NodeHelper:setNodesVisible(container,{mChoice =not isSelected,mChoiceSelected = isSelected})
        btnVisible["mChoiceNode"] = isSelected or not PageInfo.isFull;
        NodeHelper:setNodesVisible(container, btnVisible);
    end 
    NodeHelper:setNodesVisible(container,nodes);
    NodeHelper:setNodesVisible(container,nodesVisible);
    NodeHelper:setMenuItemQuality(container,"mHand",ele.quality);
    NodeHelper:setSpriteImage(container,{mPic = ElementManager:getIconById(PageInfo.optionIds[index])});
    NodeHelper:setStringForLabel(container,lb2Str);
    for index = 1,9 do
        NodeHelper:setLabelOneByOne(container,"mAttribute"..index,"mAttributeNum"..index,20,true)
    end
    NodeHelper:setLabelOneByOne(container,"mScoreBtn","mScoreNum",20,true)
end
function ElementSelectItem.onInscription(container)
    local index = container:getTag();
    ElementManager:Dress(PageInfo.optionIds[index],ElementManager.index);
end
function ElementSelectItem.onSelect(container)
    local index = container:getTag();
    local eleId = PageInfo.optionIds[index];
    local isSelected = common:table_hasValue(PageInfo.selectedIds, eleId);
    --多选
    if PageInfo.selectType == SelectType.Multi then
        if isSelected then
            NodeHelper:setNodesVisible(container,{mChoice = isSelected,mChoiceSelected =not isSelected})
            PageInfo.selectedIds=common:table_removeFromArray(PageInfo.selectedIds,eleId)
            if PageInfo.isFull then
			    PageInfo.isFull = false;
                ElementSelectPage:refreshSelectedBox(thisContainer)
		    end
        else 
            --元素分解，最多选择6个元素
            if PageInfo.filterType == EleFilterType.Decompose then 
                table.insert(PageInfo.selectedIds,eleId)
                NodeHelper:setNodesVisible(container,{mChoice = isSelected,mChoiceSelected = not isSelected})
                if #PageInfo.selectedIds >=6 then
                    PageInfo.isFull =true;
                    ElementSelectPage:refreshSelectedBox(thisContainer)
                end
            --元素升级，最多选择5个元素进行吞噬
            elseif  PageInfo.filterType == EleFilterType.Upgrade then
                table.insert(PageInfo.selectedIds,eleId)
                NodeHelper:setNodesVisible(container,{mChoice = isSelected,mChoiceSelected =not isSelected})
                if #PageInfo.selectedIds>=5 then
                    PageInfo.isFull =true;
                    ElementSelectPage:refreshSelectedBox(thisContainer)
                end
            end
            
        end
    end
    
end
function ElementSelectPage:setOptionIds()
    PageInfo.optionIds = {};
    UserInfo.sync()
    -- 职业专属标志位
    local proErrorFlag = false
    --铭刻，脱下
    if PageInfo.filterType==EleFilterType.Dress then
        --是否职业限定
        local OccupationLimit = ElementManager.OccupationLimit
        if OccupationLimit then
            local elements = ElementManager:getProfLimitElements(UserInfo.roleInfo.prof)
            for _,ele in ipairs(elements) do
                if self:filterIds(ele.id) then 
                    table.insert(PageInfo.optionIds,ele.id)
                end
            end
            proErrorFlag = true
        else 
            local elements = ElementManager:getProfLimitElements(0)
            for _,ele in ipairs(elements) do
                if self:filterIds(ele.id) then 
                    table.insert(PageInfo.optionIds,ele.id)
                end
            end
        end
    --重铸
    elseif PageInfo.filterType==EleFilterType.Recaset then
    --分解
    elseif PageInfo.filterType == EleFilterType.Decompose then
        local elements = ElementManager:getUnDressAndDressElementsMap()
        ElementManager:setSortOrder(false);
        table.sort(elements,ElementManager.sortByExtraAttrsQualityScore);
        for _,ele in ipairs(elements) do
            table.insert(PageInfo.optionIds,ele.id);
        end
    --升级
    elseif PageInfo.filterType == EleFilterType.Upgrade then
        
        local eles = ElementManager:getUnDressAndDressElementsMap()
        eles = ElementManager:removeSelectedEle(eles)
        ElementManager:setSortOrder(false);
        table.sort(eles,ElementManager.sortByExtraAttrsQualityScore);
        for _,ele in ipairs(eles) do
            table.insert(PageInfo.optionIds,ele.id)
        end 
    end
    if #PageInfo.optionIds==0 then
        if not proErrorFlag then
            MessageBoxPage:Msg_Box_Lan("@ElementSelectPrompt")
        else
            MessageBoxPage:Msg_Box_Lan("@ElementSelectPromptPro")
        end
    end
end
function ElementSelectPage:filterIds(id)
    if PageInfo.selectedIds ==nil or #PageInfo.selectedIds ==0 then
        return true;
    end
    local flag = true;
    if id then
        for _,eleId in ipairs(PageInfo.selectedIds) do 
            if id ==eleId then
                flag = false;
            end
        end
    else    
        flag = false;
    end
    return flag;
end
function ElementSelectPage:onEnter(container)  
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    self:setCurrentEle(container);
    self:setOptionIds(container);
    thisContainer = container;
    local content = nil;
    if PageInfo.filterType ==EleFilterType.Dress then
        content = PageInfo.currentEleId and "mContent1" or "mContent2" ;
    else 
        content = "mContent2";
    end
    NodeHelper:initRawScrollView(container, content);
    --NodeHelper:initScrollView(container, content, 70);
    local hasEquipEle = false;
    if PageInfo.filterType ==EleFilterType.Dress then
        hasEquipEle = PageInfo.currentEleId ~=nil;
    end
    NodeHelper:setNodesVisible(container,{
        mElementNode1 = hasEquipEle,
        mElementNode2 =not hasEquipEle
    });
    
    self:getPageInfo(container)
end
function ElementSelectPage:getPageInfo(container)
    
    self:refreshPage(container);
end
function ElementSelectPage:refreshPage(container)

    if PageInfo.filterType ==EleFilterType.Dress then
        if PageInfo.currentEleId then
            self:showCurrentEle(container)
        end
    end
    if PageInfo.filterType == EleFilterType.Decompose or PageInfo.filterType == EleFilterType.Upgrade then
         NodeHelper:setNodesVisible(container, {mConfirmationNode = true})
    else
         NodeHelper:setNodesVisible(container, {mConfirmationNode = false})
    end
   
    self:rebuildAllItem(container)
end
function ElementSelectPage:setCurrentEle(container)
    UserInfo.sync()
    local userEles = UserInfo.roleInfo.elements;
    local selectedEle = ElementManager:getSelectedElement();
    PageInfo.currentEleId = nil
    for _,ele in ipairs(userEles) do
        if ele and ele.elementId and selectedEle then
            if ele.elementId == selectedEle.id and ele.index==ElementManager.index then
                PageInfo.currentEleId = selectedEle.id
            end
        end
    end

end

function ElementSelectPage:showCurrentEle(container)
    
    local nodes = {}
    local currentEle = ElementManager:getSelectedElement();
    local levelInfo = ElementManager:getLevelInfoByLv(currentEle.level);
    local  basicAttrs = currentEle.basicAttrs.attribute;
    local extraAttrs = currentEle.extraAttrs.attribute;
    local score = ElementManager:Score(currentEle.id)
    local name = ElementManager:getNameById(currentEle.id)
    local profLimit = currentEle.profLimit
    local profName = "";

    if profLimit ~=0 then
        profName = common:getLanguageString("@ProfessionName_"..profLimit)
    end
    
    local lb2Str = {
        mLv = common:getLanguageString("@MyLevel", currentEle.level),
        mName = name,
        mScoreNum_Static = score,
        mOccupationName_Static = profName
    }

    ---有几条基础属性就显示几条，其余的隐藏
    for i =1 ,8 do
        nodes["mAttributeNode"..i.."_Static"]=false;
    end
    for i=1,#basicAttrs do
        nodes["mAttributeNode"..i.."_Static"]=true;
        local attrName = ElementManager:getAttrNameByAttrId(basicAttrs[i].attrId)
        local value = math.floor(levelInfo[attrName]*(basicAttrs[i].attrValue))
        local attrStr,numStr = ResManagerForLua:getAttributeString(basicAttrs[i].attrId,value)
        lb2Str["mAttribute"..i.."_Static"] = attrStr
        lb2Str["mAttributeNum"..i.."_Static"] = numStr
    end
    ---有几条附加属性就显示几条，其余的隐藏
    for i=1,#extraAttrs do
        nodes["mAttributeNode"..(i+4).."_Static"]=true;
        local attrName = ElementManager:getAttrNameByAttrId(extraAttrs[i].attrId)
        local value = math.floor(levelInfo[attrName]*(extraAttrs[i].attrValue))
        local attrStr,numStr = ResManagerForLua:getAttributeString(extraAttrs[i].attrId,value)
        lb2Str["mAttribute"..(i+4).."_Static"] = attrStr
        lb2Str["mAttributeNum"..(i+4).."_Static"] = numStr
          
    end
    
    NodeHelper:setNodesVisible(container,nodes);
    NodeHelper:setMenuItemQuality(container,"mHand",currentEle.quality);
    NodeHelper:setSpriteImage(container,{mPic = ElementManager:getIconById(PageInfo.currentEleId)});
    NodeHelper:setStringForLabel(container,lb2Str);
     for index = 1,9 do
        NodeHelper:setLabelOneByOne(container,"mAttribute"..index.."_Static","mAttributeNum"..index.."_Static",20,true)
    end
    NodeHelper:setLabelOneByOne(container,"mScoreBtn","mScoreNum_Static",20,true)
end
function ElementSelectPage:rebuildAllItem(container)
    self:clearAllItem(container);
	self:buildItem(container);
end
function ElementSelectPage:buildItem(container)
    local size = #PageInfo.optionIds;
	NodeHelper:buildRawScrollView(container, size, ElementSelectItem.ccbiFile, ElementSelectItem.onFunction);
end
function ElementSelectPage:clearAllItem(container)
    
    NodeHelper:clearScrollView(container);
end
function ElementSelectPage:registerPacket(container)
    if opcodes == nil then return end
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function ElementSelectPage:refreshSelectedBox(container)
    if container.mScrollViewRootNode then
       local children = container.mScrollViewRootNode:getChildren()
       if children then
            for i=1,children:count(),1 do
                if children:objectAtIndex(i-1) then
                    local node =  tolua.cast(children:objectAtIndex(i-1),"CCNode")
                    ElementSelectItem.refreshSelectBox(node)
                end
            end
       end
    end
end
function ElementSelectItem.refreshSelectBox(container)
    local btnVisible = {}
    local contentId = container:getTag();
	local eleId = PageInfo.optionIds[contentId];
    local isSelected = common:table_hasValue(PageInfo.selectedIds, eleId);
    NodeHelper:setNodesVisible(container,{mChoice =not isSelected,mChoiceSelected = isSelected})
    btnVisible["mChoiceNode"] = isSelected or not PageInfo.isFull;
    NodeHelper:setNodesVisible(container, btnVisible);
end
-----------------页面方法-----------
function ElementSelectPage:onClose(container)
    PageManager.popPage(thisPageName);
end

function ElementSelectPage:onConfirm(container)
    if PageInfo.filterType == EleFilterType.Decompose or PageInfo.filterType == EleFilterType.Upgrade then
        if PageInfo.callback then
            PageInfo.callback(PageInfo.selectedIds)
        end
    end
    PageManager.popPage(thisPageName)
end
------------------------------------
function ElementSelectPage_SelectInfo(filterType,selectType,selectedIds,callback)

    PageInfo.filterType=filterType
    PageInfo.selectType=selectType
    PageInfo.selectedIds = selectedIds;
    PageInfo.callback = callback;
    PageManager.pushPage(thisPageName);
end