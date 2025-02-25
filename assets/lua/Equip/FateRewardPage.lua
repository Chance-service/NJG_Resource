-- Author:Ranjinlan
-- Create Data: [2018-05-22 14:13:11]

local FateRewardPageBase = {
    ccbiFile = "PrivateGet.ccbi",
}
local FateDataInfo = require("FateDataInfo")
local FateDataManager = require("FateDataManager")
local EquipManager = require("EquipManager")
local NodeHelper = require("NodeHelper")
local _fateData = nil
local _defaultBgSize = nil

function FateRewardPageBase.onFunction(eventName, container)
    if eventName == "onCancel" then
        FateRewardPageBase:onClose(container)
    end
end

function FateRewardPageBase:onEnter(parentContainer)
    local container = ScriptContentBase:create(FateRewardPageBase.ccbiFile)
	container:registerFunctionHandler(FateRewardPageBase.onFunction)
    if _fateData then
        local conf = _fateData:getConf()
        local strMap = {
            mName = "",
            mInfo = "",
            mEquipmentLevel = "Lv." .. _fateData.level,
        }
        local tag = GameConfig.Tag.HtmlLable;
        nameStr = common:fillHtmlStr("Quality_" .. conf.quality, conf.name);
        local nameNode = container:getVarNode("mName");
        NodeHelper:addHtmlLable(nameNode, nameStr, tag,CCSizeMake(500, 50));
        
        local imgMap = {
            mPic = conf.icon,
            mFrameShade = NodeHelper:getImageBgByQuality(conf.quality)
        }
        local visibleMap = {
            mPrivatePic = true,
        }
        for i = 1,GameConfig.FatePageConst.MaxStarNum do
            visibleMap["mStar" .. i] = i <= conf.starLevel
        end
        NodeHelper:setNodesVisible(container, visibleMap)
        NodeHelper:setStringForLabel(container, strMap)
        NodeHelper:setSpriteImage(container, imgMap)
        NodeHelper:setQualityFrames(container, {mHand = conf.quality}, nil, true);
        self:showSpine(container,conf.quality)
        local node = container:getVarNode("mInfo")
        if node then
            local htmlStr = FateRewardPageBase:getFateSimpleHtmlStr(_fateData) or ""
            local htmlNode = NodeHelper:addHtmlLable(node, htmlStr, tag + 1)
            --[[local bgNode = container:getVarNode("m9S")
            if bgNode and htmlNode then
                if _defaultBgSize == nil then
                    _defaultBgSize = bgNode:getContentSize()
                end
                local offsetHeight = htmlNode:getContentSize().height * node:getScaleY()  - GameConfig.FatePageConst.rewardDefaultLabelHeight
                offsetHeight = math.max(offsetHeight, 0)
                local size =  CCSizeMake(_defaultBgSize.width,_defaultBgSize.height + offsetHeight)
                bgNode:setContentSize(size)
            end
            ]]
        end
    end
    return container
end

function FateRewardPageBase:showSpine(container,quality)
    local spineNode = container:getVarNode("mSpine")
    local conf = GameConfig.FateImage[quality - 1]
    if conf and spineNode then
        spineNode:removeAllChildren()
        local spine = SpineContainer:create("Spine/" .. conf.spine,conf.spine)
        local node = tolua.cast(spine, "CCNode")
        node:setScaleX(conf.scale or 1)
        node:setScaleY(math.abs(conf.scale) or 1)
        node:setPositionX(conf.offsetX or 0)
        node:setPositionY(conf.offsetY or 0)
        spineNode:addChild(node)
        spine:runAnimation(1, "Stand", -1)
    end
end

--获得命格界面显示的html
function FateRewardPageBase:getFateSimpleHtmlStr(fateData)
    if not fateData then return end
    local strTb = {}
    local conf = fateData:getConf()
    local quality = conf.quality

    local basicAttrList = fateData:getFateBasicAttr()
    if #basicAttrList > 0 then
        for _,v in ipairs(basicAttrList) do
            local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
            local name = common:getLanguageString("@AttrName_" .. v.type);
            local str = common:fillHtmlStr("MainAttr", common:getLanguageString("@EquipAttrVal", name, valueStr))--基础属性
            table.insert(strTb, str)
        end
    end
    if #conf.starAttr > 0 then
        for _,v in ipairs(conf.starAttr) do
            local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
            local name = common:getLanguageString("@AttrName_" .. v.type);
            local str = common:fillHtmlStr("SecondaryAttr_" .. quality, common:getLanguageString("@EquipAttrVal", name, valueStr))
            table.insert(strTb, str)
        end
    end
    local retStr = table.concat(strTb, "<br/>");
    retStr = retStr .. "<br/>"
	--通过margin设置不同的宽度
	local margin = GameConfig.Margin.EquipInfo
	return  common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

function FateRewardPageBase:onClose(container)
    local spineNode = container:getVarNode("mSpine")
    if spineNode then
        spineNode:removeAllChildren()
    end
    PageManager.refreshPage("FateFindPage","closeReward")   
end

--repeated RewardItem
function FateRewardPage_setRewads(rewards)
    if #(rewards or {}) == 0 then
        return
    end
    --assert(#(rewards or {}) == 1)
    _fateData = nil
    if rewards[1] ~= nil then
        _fateData = FateDataInfo.newReward(rewards[1])
    end
end

return FateRewardPageBase