-- Author:Ranjinlan
-- Create Data: [2018-05-09 11:06:05]
-- 命格吞噬选择界面
local FateSwallowSelectPageBase = {}
local NodeHelper = require("NodeHelper")
local FateDataManager = require("FateDataManager")
local option = {
	ccbiFile = "PrivateSelectPopUp.ccbi",
	handlerMap = {
        onClose                = "onClose",
        onConfirmation         = "onConfirmation",
	},
	opcode = {
    },
}
local ItemInfo = FateDataManager.FateWearSelectItem
local PageInfo = {
    fateIdList = {},
    selectList = {},
    maxSelectNum = 0,
    thisContainer = nil
}

local function sortFates(fateData_1,fateData_2)
    local conf_1 = fateData_1:getConf()
    local conf_2 = fateData_2:getConf()
    if conf_1.quality ~= conf_2.quality then
        return conf_1.quality < conf_2.quality
    elseif conf_1.starLevel ~= conf_2.starLevel then
        return conf_1.starLevel < conf_2.starLevel
    elseif fateData_1.level ~= fateData_2.level then
        return fateData_1.level < fateData_2.level
    else
        return fateData_1.exp < fateData_2.exp
    end
end
--------------------------------------------------------------------------
local FateSwallowSelectItem = {
    _bg1DefaultSize = nil, --背景1默认大小
    _bg2DefaultSize = nil, --背景2默认大小
    _DefaultItemSize = nil, --默认大小
    _contentPosY = nil,     --默认总节点的y位置
}

function FateSwallowSelectItem.onFunction(eventName,container)
    if eventName == "luaInitItemView" then
		FateSwallowSelectItem.onRefreshItemView(container);
	elseif eventName == "onChocice" then
		FateSwallowSelectItem.onChocice(container)
	end
end

function FateSwallowSelectItem.onRefreshItemView(container)
	local contentId   = container:getTag()
	local fateData = PageInfo.fateIdList[contentId]
    if not fateData then return end
    
    local conf = fateData:getConf()
    local exp = fateData.totalExp
    if exp <= 0 then
        exp = conf.basicExp
    end
    local strMap = {
        mEquipmentName = "",
        mEquipmentTex2 = "",
        mEquipmentLevel = "Lv." .. fateData.level,
        RefningPromptTex = common:getLanguageString("@DressTips_14",exp ,(fateData.totalExp +conf.basicExp))
    }
    local tag = GameConfig.Tag.HtmlLable;
    nameStr = common:fillHtmlStr("Quality_" .. conf.quality, conf.name);
    local nameNode = container:getVarNode("mEquipmentName");
    NodeHelper:addHtmlLable(nameNode, nameStr, tag,CCSizeMake(500, 50));
    
    local imgMap = {
        mBadgePic = conf.icon,
        mBadgeFrameShade = NodeHelper:getImageBgByQuality(conf.quality)
    }
    local visibleMap = {
        mRefningPromptNode = false,
        mEquipmentPosition = false ,
        mChociceNode = true,
        mEquipmentNode = false,
    }
    for i = 1,GameConfig.FatePageConst.MaxStarNum do
        visibleMap["mBadgeStar" .. i] = i <= conf.starLevel
    end
    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, strMap)
    NodeHelper:setSpriteImage(container, imgMap)
    NodeHelper:setQualityFrames(container, {mBadgeBgPic = conf.quality}, nil, true);

    local node = container:getVarNode("mEquipmentTex2")
    if node then
        local htmlStr = FateSwallowSelectItem.getFateInfoDesHtmlStr(fateData,contentId) or ""
        local htmlNode = NodeHelper:addHtmlLable(node, htmlStr, tag + 1,CCSizeMake(GameConfig.FatePageConst.selectItemMaxLabelWidth,200) )
        local offsetHeight = htmlNode:getContentSize().height * node:getScaleY()  - GameConfig.FatePageConst.selectItemDefaultLabelHeight
        local bg1Node = container:getVarNode("mScale9Sprite1")
        if bg1Node then
            if ItemInfo._bg1DefaultSize == nil then
                ItemInfo._bg1DefaultSize = bg1Node:getContentSize()
            end
            local size = CCSizeMake(ItemInfo._bg1DefaultSize.width,ItemInfo._bg1DefaultSize.height + offsetHeight)
            bg1Node:setContentSize(size)
        end
        local bg2Node = container:getVarNode("mScale9Sprite2")
        if bg2Node then
            if ItemInfo._bg2DefaultSize == nil then
                ItemInfo._bg2DefaultSize = bg2Node:getContentSize()
            end
            local size = CCSizeMake(ItemInfo._bg2DefaultSize.width,ItemInfo._bg2DefaultSize.height + offsetHeight)
            bg2Node:setContentSize(size)
        end
        local contentNode = container:getVarNode("mContentNode")
        if contentNode then
            if ItemInfo._contentPosY == nil then
                ItemInfo._contentPosY = contentNode:getPositionY()
            end
            contentNode:setPositionY(ItemInfo._contentPosY + offsetHeight)
        end
        if ItemInfo._DefaultItemSize == nil then
            ItemInfo._DefaultItemSize = container:getContentSize()
        end
        container:setContentSize(CCSizeMake(ItemInfo._DefaultItemSize.width,ItemInfo._DefaultItemSize.height + offsetHeight))
    end
    FateSwallowSelectItem.updateChocice(container)
end

function FateSwallowSelectItem.updateChocice(container)
    local contentId   = container:getTag()
	local fateData = PageInfo.fateIdList[contentId]
    if not fateData then return end
    local find = false
    for _,v in pairs(PageInfo.selectList) do
        if v == fateData.id then
            find = true
            break;
        end
    end
    if find then
        --选中
        NodeHelper:setMenuItemEnabled( container, "mChocice", true )
        NodeHelper:setMenuItemSelected( container, {mChocice = true} )
    elseif PageInfo.maxSelectNum > #PageInfo.selectList then
        --可选择
        NodeHelper:setMenuItemEnabled( container, "mChocice", true )
        NodeHelper:setMenuItemSelected( container, {mChocice = false} )
    else
        --不可选择
        NodeHelper:setMenuItemEnabled( container, "mChocice", false )
    end
end

function FateSwallowSelectItem.onChocice(container)
    local contentId   = container:getTag()
	local fateData = PageInfo.fateIdList[contentId]
    if not fateData then return end
    local find = false
    for i,v in pairs(PageInfo.selectList) do
        if v == fateData.id then
            table.remove(PageInfo.selectList,i)
            find = true
            break
        end
    end
    if not find then
        PageInfo.selectList[#PageInfo.selectList + 1] = fateData.id
    end
    FateSwallowSelectPageBase:refreshSelectedBox()
end

function FateSwallowSelectItem.getFateInfoDesHtmlStr(fateData)
    if not fateData then return end
    --获取命格详情的属性html
    local strTb = {}
    local conf = fateData:getConf()
    local quality = conf.quality
    local imgStr = UserEquipManager:getEquipSpaceImg()
    
    local basicAttrList = fateData:getFateBasicAttr()
    if #basicAttrList > 0 then
        table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@BadgeBasicAttrTxt")))--基础属性标题
        for _,v in ipairs(basicAttrList) do
            local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
            local name = common:getLanguageString("@AttrName_" .. v.type);
            local str = common:fillHtmlStr("MainAttr", common:getLanguageString("@EquipAttrVal", name, valueStr))--基础属性
            table.insert(strTb, str)
        end
    end
    if #conf.starAttr > 0 then
        table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@BadgeStarAttrTxt")))--星级属性标题
        for _,v in ipairs(conf.starAttr) do
            local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
            local name = common:getLanguageString("@AttrName_" .. v.type);
            local str = common:fillHtmlStr("SecondaryAttr_" .. quality, common:getLanguageString("@EquipAttrVal", name, valueStr))
            table.insert(strTb, str)
        end
    end
    local retStr = table.concat(strTb, "<br/>");
	--通过margin设置不同的宽度
	local margin = GameConfig.Margin.EquipInfo
	return  common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

------------------------------------------------------------------------
function FateSwallowSelectPageBase:onEnter(container)
    PageInfo.thisContainer = container
    PageInfo.fateIdList = FateDataManager:getNotWearFateList() or {}
    for k,v in ipairs(PageInfo.fateIdList) do
        if v.id == PageInfo.selectId then
            table.remove(PageInfo.fateIdList,k)
            break
        end
    end
    table.sort(PageInfo.fateIdList,sortFates)
    FateSwallowSelectPageBase:initPage(container)
    FateSwallowSelectPageBase:BuildAllItems(container)
end

function FateSwallowSelectPageBase:initPage(container)
    local visibleMap = {
        mEquipmentContentNode = false,
        mBackpackContentNode = true,
        mEquipmentSelectPrompt = #PageInfo.fateIdList == 0,
        mConfirmationNode = true,
        mUnloadNode = false,
    }
    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:initRawScrollView(container, "mBackpackContent1")
end

function FateSwallowSelectPageBase:BuildAllItems(container)
    NodeHelper:clearScrollView(container)
    local noEquip = container:getVarLabelTTF("mNoEquip")
    if #PageInfo.fateIdList > 0 then
        noEquip:setVisible(false)
        NodeHelper:buildRawScrollView(container, #PageInfo.fateIdList, ItemInfo.ccbiFile, FateSwallowSelectItem.onFunction);
    end
end

function FateSwallowSelectPageBase:refreshSelectedBox()
    if not PageInfo.thisContainer then
        return
    end
    if PageInfo.thisContainer.mScrollViewRootNode then
       local children = PageInfo.thisContainer.mScrollViewRootNode:getChildren()
       if children then
            for i=1,children:count(),1 do
                if children:objectAtIndex(i-1) then
                    local node =  tolua.cast(children:objectAtIndex(i-1),"CCNode")
                    FateSwallowSelectItem.updateChocice(node)
                end
            end
       end
    end
end

function FateSwallowSelectPageBase:onExit(container)
    PageInfo.thisContainer = nil
    NodeHelper:deleteScrollView(container)
end

function FateSwallowSelectPageBase:onClose(container)
    PageManager.popPage("FateSwallowSelectPage")
end

function FateSwallowSelectPageBase:onConfirmation(container)
    if #PageInfo.selectList == 0 then
        MessageBoxPage:Msg_Box_Lan("@BadgeNoSelectTip");
        --return
    end
    if PageInfo.callback then
        PageInfo.callback(PageInfo.selectList)
    end
    PageManager.popPage("FateSwallowSelectPage")
end

--selectList 选择列表
--maxSelectNum 最大选择数量
--callback 选择好后确定选择
--selectId 选择Id
function FateSwallowSelectPage_setFate(data)
    PageInfo.selectId = data.selectId
    PageInfo.selectList = data.selectList or {}
    PageInfo.maxSelectNum = data.maxSelectNum
    PageInfo.callback = data.callback
end

local CommonPage = require("CommonPage");
FateSwallowSelectPage = CommonPage.newSub(FateSwallowSelectPageBase, "FateSwallowSelectPage", option);