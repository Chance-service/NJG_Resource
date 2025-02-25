
local BasePage = require("BasePage")
local thisPageName = "ElementRecastPage"
local ElementManager = require("Element.ElementManager")
local NodeHelper = require("NodeHelper");
local HP_pb = require("HP_pb")
local ResManagerForLua = require("ResManagerForLua")

local opcodes = {
    ELEMENT_RECAST_S = HP_pb.ELEMENT_RECAST_S,
    ELEMENT_RECAST_CONFIRM_S = HP_pb.ELEMENT_RECAST_CONFIRM_S
}
local option = {
    ccbiFile="ElementAttributeRecastingPopUp.ccbi",
    handlerMap ={
        onClose         = "onClose",
        onRecastingBtn    = "onRecast",
        onSeniorRecastingBtn      = "onHighRecast",
    },
    DataHelper = ElementManager
}

local COUNT_ELEMENT_SOURCE_MAX = 6

local ElementRecastPage = {};
local selectedId = nil
local selectAttrId = nil
local selectAttrIndex = nil
local selectRecastIndex = nil
local hasRecast = false
local recastAttr = nil
local RECASTCOUT = 3
local recastType = 1

function ElementRecastPage_FunctionEx(eventName,container)
    if string.sub(eventName,1,12) == "onElementBtn" then
        local index = string.sub(eventName,13,-1)
        index = tonumber(index)
        ElementRecastPage:showTip(container,index)
    elseif string.sub(eventName,1,8)=="onChoice" then
        if hasRecast and string.len(eventName)>9 then
            return
        end
        if string.len(eventName)>9 then
            local index = string.sub(eventName,11,-1)
            index = tonumber(index)
            selectAttrIndex = index
            ElementRecastPage:refreshBaseAttr(container)
        else
            local index = string.sub(eventName,9,-1)
            index = tonumber(index)
            selectRecastIndex = index - 3
            ElementRecastPage:refreshRecastAttr(container,true,recastAttr)
        end
    end
end

ElementRecastPage = BasePage:new(option,thisPageName,ElementRecastPage_FunctionEx,opcodes)

function ElementRecastPage:getPageInfo(container)
    
    selectAttrId = nil
    selectAttrIndex = nil
    selectRecastIndex = nil
    hasRecast = false
    recastAttr = nil
    self:refreshPage(container)
end

function ElementRecastPage:refreshPage(container)
    self:refreshBaseAttr(container)
    self:refreshRecastAttr(container,hasRecast)
    self:refreshRecastMaterial(container)
end

function ElementRecastPage:refreshBaseAttr(container)
    --set visible false
    NodeHelper:setNodesVisible(container,{
        ["mAttributeNode3-1"] = false,
        ["mAttributeNode3-2"] = false,
        ["mAttributeNode3-3"] = false,
        ["mAttributeNode3-4"] = false,
    })
    --base attr value
    local eleInfo = ElementManager:getElementInfoById(selectedId)
    local levelInfo = ElementManager:getLevelInfoByLv(eleInfo.level);
    if eleInfo~=nil then
        local attrCount = #eleInfo.extraAttrs.attribute
        if attrCount~=nil or attrCount>0 then
            for i=1,attrCount do
                NodeHelper:setNodesVisible(container,{["mAttributeNode3-"..i] = true})
            end
        end
        for i=1,attrCount do
            local attrInfo = eleInfo.extraAttrs.attribute[i]
            local attrId = attrInfo.attrId
            selectAttrIndex = selectAttrIndex or i
            local attrName = ElementManager:getAttrNameByAttrId(attrId)
            local value = levelInfo[attrName]*(attrInfo.attrValue)
            local attrStr,numStr = ResManagerForLua:getAttributeString(attrId,value)
            NodeHelper:setStringForLabel(container,{["mAttribute3".."-"..i] = attrStr})
            NodeHelper:setStringForLabel(container,{["mAttributeNum3".."-"..i] = "+"..numStr})
            NodeHelper:setNodesVisible(container,{["mChoiceSelected3".."-"..i]=false})
			NodeHelper:setLabelOneByOne(container,"mAttribute3".."-"..i,"mAttributeNum3".."-"..i)
        end
        NodeHelper:setNodesVisible(container,{["mChoiceSelected3".."-"..selectAttrIndex]=true})
        selectAttrId = eleInfo.extraAttrs.attribute[selectAttrIndex].attrId
    end
end


function ElementRecastPage:refreshRecastAttr(container,recasted,attrs)
    hasRecast = recasted or false
    if hasRecast then
        recastAttr = attrs or recastAttr
        self:setRecastAttr(container)
        for i = 1,3 do
            if selectAttrIndex == i then
                container:getVarNode("mChoiceSelect3-" .. i):setVisible(true)
            else
                container:getVarNode("mChoiceSelect3-" .. i):setVisible(false)
            end
        end
    else
        self:setUnkonwnAttr(container)
        for i = 1,3 do
            container:getVarNode("mChoiceSelect3-" .. i):setVisible(true)
        end
    end
end

function ElementRecastPage:refreshRecastMaterial(container)
    local eleInfo = ElementManager:getElementInfoById(selectedId)
    if eleInfo~=nil then
        local itemId = eleInfo.itemId
        local recastCfg = ConfigManager.getElementCfg()
        local recastCfgInfo = recastCfg[itemId]
        if recastCfgInfo~=nil then
            local itemCount = #recastCfgInfo.consume
            NodeHelper:fillRewardItemWithCostNum(container, recastCfgInfo.consume, 5,true)
            container:runAnimation("ElementFrame0"..itemCount)
        end
    end
end

function ElementRecastPage:showTip(container,index)
    local eleInfo = ElementManager:getElementInfoById(selectedId)
    if eleInfo~=nil then
        local itemId = eleInfo.itemId
        local recastCfg = ConfigManager.getElementCfg()
        local materialInfo = recastCfg[itemId].consume
        local item = materialInfo[index]

        GameUtil:showTip(container:getVarNode('mElementBtn'..index), {
		    type 		= item.type, 
		    itemId 		= item.itemId,
		    buyTip		= false,
		    starEquip	= false
	    });
    end
end

function ElementRecastPage:setUnkonwnAttr(container)
    --label
    local labelRandomStr = common:getLanguageString("@ElementRandomAttribute")
    NodeHelper:setStringForLabel(container,{
        mAttribute4 = labelRandomStr,
        mAttribute5 = labelRandomStr,
        mAttribute6 = labelRandomStr,
        mAttributeNum4 = "",
        mAttributeNum5 = "",
        mAttributeNum6 = "",
    })
	NodeHelper:setLabelOneByOne(container,"mAttribute4","mAttributeNum4")
	NodeHelper:setLabelOneByOne(container,"mAttribute5","mAttributeNum5")
	NodeHelper:setLabelOneByOne(container,"mAttribute6","mAttributeNum6")
    --selected visible
    NodeHelper:setNodesVisible(container,{
        mRecastSelectedNode4 = false,
        mRecastSelectedNode5 = false,
        mRecastSelectedNode6 = false,
    })
    --button label
    NodeHelper:setStringForLabel(container,{
        mRecastingLab = common:getLanguageString("@ElementHighRecastBtn"),
        mSeniorRecastingLab = common:getLanguageString("@SeniorRecastingBtn"),
    })
end

function ElementRecastPage:setRecastAttr(container)
    --label
    for i=1,RECASTCOUT do
        local attr = recastAttr[i]
        if attr~=nil and attr.attrId~=0 then
            local attrName,attrNum = ResManagerForLua:getAttributeString(attr.attrId,attr.attrValue)
            NodeHelper:setStringForLabel(container,{
                ["mAttribute"..(3+i)] = attrName,
                ["mAttributeNum"..(3+i)] = attrNum,
            })
            NodeHelper:setNodesVisible(container,{["mRecastSelectedNode"..(3+i)] = true})
            selectRecastIndex = selectRecastIndex or i
            NodeHelper:setNodesVisible(container,{["mChoiceSelected"..(3+i)] = false})
			NodeHelper:setLabelOneByOne(container,"mAttribute"..(3+i),"mAttributeNum"..(3+i))
        end
    end
    --selected
    NodeHelper:setNodesVisible(container,{["mChoiceSelected"..(3+selectRecastIndex)] = true})
    --button label
    NodeHelper:setStringForLabel(container,{
        mRecastingLab = common:getLanguageString("@ElementConfirmBtn"),
        mSeniorRecastingLab = common:getLanguageString("@ElementCancelBtn"),
    })
end

function ElementRecastPage:onClose(container)
    PageManager.popPage(thisPageName)
end 


-- 重铸或确认
function ElementRecastPage:onRecast(container)
    if not hasRecast then
    ----检查金币是否充足
        local eleInfo = ElementManager:getElementInfoById(selectedId)
        local recastCfg = ConfigManager.getElementCfg()
        local recastCfgInfo = recastCfg[eleInfo.itemId]
        for _,item in ipairs(recastCfgInfo.consume) do 
            if  item.type==10000 then
                local UserInfo = require("PlayerInfo.UserInfo")
                UserInfo.isCoinEnough(item.count)
            end
        end
		recastType = 1
        ElementManager:Recast(selectedId,selectAttrId,recastType)
    else
        ElementManager:RecastConfirm(selectedId,selectRecastIndex,recastType)
    end
end
--高级重铸或取消
function ElementRecastPage:onHighRecast(container)
    if not hasRecast then
		recastType = 2
        ElementManager:Recast(selectedId,selectAttrId,recastType)
    else
        hasRecast = false
        selectRecastIndex=1
        self:refreshPage(container)
    end
end

function ElementRecastPage_Show(id)
    selectedId = id
    PageManager.pushPage(thisPageName)
end