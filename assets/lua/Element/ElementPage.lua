

--endregion
local BasePage = require("BasePage")
local thisPageName = "ElementPage"
local ElementManager = require("Element.ElementManager")
local UserInfo = require("PlayerInfo.UserInfo")
local ViewPlayerInfo = require("PlayerInfo.ViewPlayerInfo")
local Const_pb = require("Const_pb")
local NodeHelper = require("NodeHelper")
local ElementConfig = require("Element.ElementConfig")
local itemContainerMap = {}
local nowUserInfo = {}
local opcodes = {
    
}
local option = {
    ccbiFile="ElementPage.ccbi",
    handlerMap ={
    onReturnButton = "onReturn",
    onHelp = "onHelp"
    },
    DataHelper = ElementManager
}
local EleItem = {
    ccbiFileItem = "ElementItem.ccbi"
}
local ElementPage = nil;
function onFunctionEx(eventName,container)
    if string.sub(eventName,1,8) == "onAddBtn" then 
        local index = tonumber(string.sub(eventName,-1));
        if nowUserInfo.level >= ElementConfig.ElementSlotCfg[index].openLv then
            ElementPage:onAddBtn(index);
        end
    end
end
ElementPage = BasePage:new(option,thisPageName,onFunctionEx,opcodes);

function EleItem.onFunction(eventName, container)
    if eventName == "onHand" then
        EleItem.onHand(container)
    end
end

function EleItem.onHand(container)
    local index = container.id;
    if nowUserInfo.level < ElementConfig.ElementSlotCfg[index].openLv then
        return;
    end
    local ele = ElementManager:getEleByIndex(index);
    ElementManager:setSelectedElement(ele.elementId,index);
    require("ElementInfoPage")
    ElementInfoPage_setShowType(ElementManager.showType.defalut);
end

function ElementPage:getPageInfo(container)
    self:refreshPage(container);
end

function ElementPage:refreshPage(container)
    UserInfo.sync();
    nowUserInfo = UserInfo.roleInfo
    local lb2Str = {
        mIceDamageNum = ElementManager:getRoleAttrById(nowUserInfo,Const_pb.ICE_ATTACK),
        mFireDamageNum = ElementManager:getRoleAttrById(nowUserInfo,Const_pb.FIRE_ATTACK),
        mThunderDamageNum = ElementManager:getRoleAttrById(nowUserInfo,Const_pb.THUNDER_ATTACK),
        mIceResistanceNum = ElementManager:getRoleAttrById(nowUserInfo,Const_pb.ICE_DEFENCE),
        mFireResistanceNum = ElementManager:getRoleAttrById(nowUserInfo,Const_pb.FIRE_DEFENCE),
        mThunderResistanceNum = ElementManager:getRoleAttrById(nowUserInfo,Const_pb.THUNDER_DENFENCE),
    };
    local lbsVisible = {}
    local roleElements = nowUserInfo.elements;
    local cfg = ElementConfig.ElementSlotCfg
    for i =1 ,#cfg do
        if nowUserInfo.level < cfg[i].openLv then
            lbsVisible["mOpenLv"..i] = true;
            lb2Str["mOpenLv"..i] =cfg[i].openLv..common:getLanguageString("@Open");
        else
            lbsVisible["mOpenLv"..i] = false;
        end
    end
    for i =1 ,9 do
    mSmetNode = container:getVarNode("mSetNode"..i);
    mSmetNode:removeAllChildren();
    end
    for _ , roleEle in ipairs(roleElements) do
        if roleEle.index ~=0 and roleEle.elementId~=0 then
            local mSmetNode = nil;
            mSmetNode = container:getVarNode("mSetNode"..(roleEle.index));
            local pItemContainer = ScriptContentBase:create(EleItem.ccbiFileItem)
            if pItemContainer~=nil then
                mSmetNode:addChild(pItemContainer);
                pItemContainer:release();
                pItemContainer.id = roleEle.index
                pItemContainer:registerFunctionHandler(EleItem.onFunction)
                local label = {
				    mLv 		= "Lv."..roleEle.level
			    }
                NodeHelper:setStringForLabel(pItemContainer,label);
                NodeHelper:setSpriteImage(pItemContainer,{mPic = ElementManager:getIconById(roleEle.elementId)})
                NodeHelper:setMenuItemQuality(pItemContainer,"mHand",roleEle.quality);
            end
        end
    end
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setNodesVisible(container,lbsVisible);


end
function ElementPage:onAddBtn(index)
    --local ele = ElementManager:getEleByIndex(index);
    ElementManager.index = index;
    local cfg = ElementConfig.ElementSlotCfg;
    local info = cfg[index]
    if info.professionAttr == 1 then
        ElementManager.OccupationLimit = true
    else 
        ElementManager.OccupationLimit = false
    end
    require("ElementSelectPage")
    ElementSelectPage_SelectInfo(EleFilterType.Dress,1,nil,nil)
end
function ElementPage:onReturn(container)
    PageManager.changePage("EquipmentPage")
end
function ElementPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ELEMENT);
end

