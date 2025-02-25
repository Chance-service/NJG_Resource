
local BasePage = require("BasePage")
local thisPageName = "ViewOtherElementPage"
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
local ViewOtherElementPage = nil;
function onFunctionEx(eventName,container)
    
end
ViewOtherElementPage = BasePage:new(option,thisPageName,onFunctionEx,opcodes);

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
    --showtip
end

function ViewOtherElementPage:getPageInfo(container)
    self:refreshPage(container);
end

function ViewOtherElementPage:refreshPage(container)
     nowUserInfo = ViewPlayerInfo:getRoleInfo()
    
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
                local name = "";
                local ele = self:getEleInfo(roleEle.elementId)
                name =(ElementManager:getPrefixName(ele.itemId))..(ElementManager:getPostfixName(ele.basicAttrs.attribute,"name"))
                NodeHelper:setStringForLabel(pItemContainer,label);
                NodeHelper:setSpriteImage(pItemContainer,{mPic = ElementManager:getEleNameAndIcon(ele.basicAttrs.attribute,"icon")})
                NodeHelper:setMenuItemQuality(pItemContainer,"mHand",roleEle.quality);
            end
        end
    end
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setNodesVisible(container,lbsVisible);
end
function ViewOtherElementPage:getEleInfo(id)
    local eles = ViewPlayerInfo:getElementInfo()
    if eles and id then
        for _,ele in ipairs(eles) do
            if ele.id ==id then
                return ele;
            end
        end
    end
end
function ViewOtherElementPage:onReturn(container)
    PageManager.popPage(thisPageName)
end
function ViewOtherElementPage:onHelp(container)

end

