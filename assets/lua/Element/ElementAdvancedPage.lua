
--元素神符进阶



--endregion

local BasePage = require("BasePage")
local thisPageName = "ElementAdvancedPage"
local ElementManager = require("Element.ElementManager")
local ItemManager = require("Item.ItemManager");
local UserItemManager = require("Item.UserItemManager");
local ElementConfig = require("Element.ElementConfig")
local ResManagerForLua = require("ResManagerForLua")
local opcodes = {
    ELEMENT_ADVANCE_S = HP_pb.ELEMENT_ADVANCE_S
}
local option = {
    ccbiFile="ElementAdvancedPopUp.ccbi",
    handlerMap ={
        onClose = "onClose",
        onAdvanced = "onAdvanced"
    },
    DataHelper = ElementManager
}
local ccbiFileItem = "EquipAni04.ccbi"
local ElementAdvancedPage = nil;
local  oldEle = nil;
local newEle = nil;
local baseAttrMap ={}
local extAttrMap = {}
function onFunctionEx(eventName,container)
    if string.sub(eventName,1,12)=="onElementBtn" then
        local index = string.sub(eventName,13,-1)
        index = tonumber(index)
        ElementAdvancedPage:showTip(container,index)
    end
end

ElementAdvancedPage = BasePage:new(option,thisPageName,onFunctionEx,opcodes)
function ElementAdvancedPage:getPageInfo(container)
    local ele = ElementManager:getSelectedElement();
    newEle = ele;
    oldEle = ele;
    self:refreshPage(container) 
end

function ElementAdvancedPage:refreshPage(container)
     
    local ele = ElementManager:getSelectedElement();
    newEle = ele;
    ----进阶所需材料
    local mPics = {};
    local mholdEles = {};
    local cfg = ElementConfig.ElementAscendCfg;
    local items = cfg[ele.quality].consume
    local num = #items;
    local levelInfo = ElementManager:getLevelInfoByLv(ele.level);
    local UserElements = ElementManager.UserElementMap;
    local baseAttrs = ele.basicAttrs.attribute;
    local extraAttrs = ele.extraAttrs.attribute;
    local baseAttrsNum = #(ele.basicAttrs.attribute);
    local extraAttrsNum = #(ele.extraAttrs.attribute);
    local  nodesVisible = {};
    for i =1,8 do 
        nodesVisible["mAttributeNode"..i] = false;
    end
    if items[1].type==0 then
        container:runAnimation("ElementFrame00");
    else
        container:runAnimation("ElementFrame0"..num);
    end
    
    ---当前元素神符信息
    local name = ElementManager:getNameById(ele.id)
    local score = ElementManager:Score(ele.id)
    local occupationName = "";
    if ele.occupationName  then
        occupationName=ele.occupationName
    end
    local lb2Str = {
        mLv = common:getLanguageString("@MyLevel", ele.level),
        mName = name,
        mScoreNum = score,
        mOccupationName = occupationName
    }

    for i=1,baseAttrsNum do
        nodesVisible["mAttributeNode"..i] = true;
        local attrName = ElementManager:getAttrNameByAttrId(baseAttrs[i].attrId)
        local value = math.floor((baseAttrs[i].attrValue)*(levelInfo[attrName]))
        local attrStr,numStr = ResManagerForLua:getAttributeString(baseAttrs[i].attrId,value)
        lb2Str["mAttribute"..i] = attrStr;
        lb2Str["mAttributeNum"..i] = "+"..numStr;
        baseAttrMap[baseAttrs[i].attrId]=i;
    end
    for i=1,extraAttrsNum do
        nodesVisible["mAttributeNode"..(i+4)] = true;
        local attrName = ElementManager:getAttrNameByAttrId(extraAttrs[i].attrId)
        local value = math.floor((extraAttrs[i].attrValue)*(levelInfo[attrName]))
        local attrStr,numStr = ResManagerForLua:getAttributeString(extraAttrs[i].attrId,value)
        lb2Str["mAttribute"..(i+4)] = attrStr;
        lb2Str["mAttributeNum"..(i+4)] = "+"..numStr;
        extAttrMap[extraAttrs[i].attrId]=i;
    end
    --当前元素的图标，品质
    mPics["mPic"] = ElementManager:getIconById(ele.id)
    NodeHelper:setMenuItemQuality(container,"mHand",ele.quality);
    --新属性播放特效
    self:PlayEffect(container)
    ---进阶需要的材料
    if items[1].type~=0 then
        for i =1,num do
            --NodeHelper:setMenuItemQuality(container,"mElementBtn"..i,items[i].quality);
            mPics["mPic"..i] = ItemManager:getIconById(items[i].itemId);
            local useritem = UserItemManager:getUserItemByItemId(items[i].itemId);
            local count = useritem and useritem.count or 0;
            mholdEles["mElementNum"..i] = count.."/"..(items[i].count);
        end
    end
    NodeHelper:setNodesVisible(container,nodesVisible);
    NodeHelper:setStringForLabel(container,lb2Str);
    NodeHelper:setSpriteImage(container,mPics);
    NodeHelper:setStringForLabel(container,mholdEles);
    NodeHelper:setLabelOneByOne(container,"mScoreBtn","mScoreNum",20,true)
end
function ElementAdvancedPage:PlayEffect(container)
    --出现新属性播放特效
    if newEle and oldEle then
        local flag = false;
        if #(newEle.basicAttrs.attribute) ~= #(oldEle.basicAttrs.attribute)  then
            flag = true;
            for _,newattr in ipairs(newEle.basicAttrs.attribute)do
                local hasAttr = true;
                for _,oldattr in ipairs(oldEle.basicAttrs.attribute) do 
                    if newattr.attrId == oldattr.attrId and newattr.attrValue == oldattr.attrValue then
                        hasAttr = false;
                    end
                end
                if hasAttr then
                    local node = nil;
                    node = container:getVarNode("mAttributeNode"..(baseAttrMap[newattr.attrId]));
                    local effectcontent = ScriptContentBase:create(ccbiFileItem)
                    if node then
                        node:addChild(effectcontent);
                    end
                    effectcontent:release();
                end
            end
            
        end
        if #(newEle.extraAttrs.attribute) ~= #(oldEle.extraAttrs.attribute)  then
            flag = true;
             for _,newattr in ipairs(newEle.extraAttrs.attribute)do
                local hasAttr = true;
                for _,oldattr in ipairs(oldEle.extraAttrs.attribute) do 
                    if newattr.attrId == oldattr.attrId and newattr.attrValue == oldattr.attrValue then
                        hasAttr = false;
                    end
                end
                if hasAttr then
                    local node = nil;
                    node = container:getVarNode("mAttributeNode"..(4+extAttrMap[newattr.attrId]));
                    local effectcontent = ScriptContentBase:create(ccbiFileItem)
                    if node then
                        node:addChild(effectcontent);
                    end
                    effectcontent:release();
                end
            end
        end

        if flag then
            local node = nil;
            node = container:getVarNode("mHead_Node");
            local effectcontent = ScriptContentBase:create(ccbiFileItem)
            if node then
                node:addChild(effectcontent);
            end
            effectcontent:release();
        end
    end
end
---------click event------
function ElementAdvancedPage:onClose(container)
    local  oldEle = nil;
    local newEle = nil;
    local baseAttrMap ={}
    local extAttrMap = {}
    PageManager.popPage(thisPageName)
end

function ElementAdvancedPage:onAdvanced(container)
    local ele = ElementManager:getSelectedElement();
    oldEle = ele;
    local cfg = ElementConfig.ElementAscendCfg;
    local items = cfg[ele.quality].consume
    for _, item in ipairs(items) do
        if item.type ==10000 then
            local UserInfo = require("PlayerInfo.UserInfo")
            UserInfo.isCoinEnough(item.count)
        end
    end
    if ele.quality ==5 then
        MessageBoxPage:Msg_Box_Lan("@AdvancedLimit")
        return;
    end
    if ElementManager:hasEnoughEles(ele.id) then
        local title = common:getLanguageString("@ElementAdvanceTitle");
        local content = common:getLanguageString("@ElementsAdcancedContent");
        PageManager.showConfirm(title,content,function(isSure)
            if isSure then
                ElementManager:Advanced(ele.id)
                return
            end
        end)
        
    else 
        MessageBoxPage:Msg_Box_Lan("@SEItemNotEnoughTitle")
    end
    
end

function ElementAdvancedPage:showTip(container,index)
    local eleInfo = ElementManager:getSelectedElement()
    if eleInfo~=nil then
        local quality = eleInfo.quality
        local ascendCfg = ConfigManager.getElementAscendCfg()
        local materialInfo = ascendCfg[quality].consume
        local item = materialInfo[index]

        GameUtil:showTip(container:getVarNode('mElementBtn'..index), {
		    type 		= item.type, 
		    itemId 		= item.itemId,
		    buyTip		= false,
		    starEquip	= false
	    });
    end
end
