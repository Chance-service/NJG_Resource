-- Author:Ranjinlan
-- Create Data: [2018-05-09 10:59:32]
-- 命格详细属性及操作界面

local FateDetailInfoPageBase = {}
local FateDataManager = require("FateDataManager")
local UserEquipManager = require("UserEquipManager")
local EquipManager = require("EquipManager")
local MysticalDress_pb = require("Badge_pb")
local HP_pb = require("HP_pb")
local option = {
	ccbiFile = "PrivateInfoPopUp.ccbi",
	handlerMap = {
        onClose                = "onClose",
        onClose                = "onClose",
        onLevelUp              = "onLevelUp",
        onChange               = "onChange",
        onTakeOff              = "onTakeOff",
	},
	opcode = {
        MYSTICAL_DRESS_CHANGE_C = HP_pb.BADGE_DRESS_C, --穿私装
        MYSTICAL_DRESS_CHANGE_S = HP_pb.BADGE_DRESS_S, --穿私装
        MYSTICAL_DRESS_ABSORB_S = HP_pb.BADGE_UPGRADE_S, --吸收
    },
}
local PageInfo = {
    isOthers = false,
    fateData = nil,
    locPos = nil,
}

function FateDetailInfoPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcode) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function FateDetailInfoPageBase:removePacket(container)
	for key, opcode in pairs(option.opcode) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function FateDetailInfoPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    if opcode == option.opcode.MYSTICAL_DRESS_CHANGE_S then
        PageManager.popPage("FateDetailInfoPage")
    elseif opcode == option.opcode.MYSTICAL_DRESS_ABSORB_S then
        FateDetailInfoPageBase:refreshPage(container)
    end
end

function FateDetailInfoPageBase:onEnter(container)
    FateDetailInfoPageBase:refreshPage(container)
end

function FateDetailInfoPageBase:refreshPage(container)
    local conf = PageInfo.fateData:getConf()
    local strMap = { 
		mEquipmentLevel  	= "Lv." .. PageInfo.fateData.level,
		mEquipmentName		= "",
	}
    local visibleMap = {}
    for star = 1, GameConfig.FatePageConst.MaxStarNum do
        visibleMap["mBadgeStar" .. star] = conf.starLevel >= star
    end
    local tag = GameConfig.Tag.HtmlLable;
	nameStr = common:fillHtmlStr("Quality_" .. conf.quality, conf.name);
	local nameNode = container:getVarNode("mEquipmentName");
	NodeHelper:addHtmlLable(nameNode, nameStr, tag,CCSizeMake(500, 50));
    
    if PageInfo.isOthers or PageInfo.fateData:isMaxLevel() then
        visibleMap["mEnhanceNode"] = false
    else
        visibleMap["mEnhanceNode"] = true
    end
    if PageInfo.isOthers or PageInfo.fateData.roleId == nil then
        visibleMap["mUnloadNode"] = false
        visibleMap["mChangeNode"] = false
        visibleMap["mCancelNode"] = true
    else
        visibleMap["mUnloadNode"] = true
        visibleMap["mChangeNode"] = true
        visibleMap["mCancelNode"] = false
    end
    visibleMap["mEquipmentInfoTex"] = false 
    NodeHelper:setNodesVisible(container, visibleMap)
    FateDetailInfoPageBase:registerPacket(container)
    NodeHelper:setStringForLabel(container, strMap)
    NodeHelper:setSpriteImage(container, {mBadgePic = conf.icon,mBadgeFrameShade = NodeHelper:getImageBgByQuality(conf.quality)});
    NodeHelper:setQualityFrames(container, {mBadgeBgPic = conf.quality});
    
    local str = FateDetailInfoPageBase:getFateInfoDesHtmlStr(container, PageInfo.fateData) or ""
	local lbNode = container:getVarNode("mEquipmentLevel");
	local mScrollView = container:getVarScrollView("mContent");
	mScrollView:getContainer():removeAllChildren();
    local viewSize = mScrollView:getViewSize()
	local htmlNode = NodeHelper:addHtmlLable(lbNode, str, tag + 1, CCSizeMake(viewSize.width, viewSize.height), mScrollView)
    htmlNode:setPosition(ccp(0, 0));
    htmlNode:setScale(1);
    local size = htmlNode:getContentSize();
	mScrollView:setContentSize(CCSizeMake(viewSize.width, size.height));
    mScrollView:setContentOffset(ccp(0, viewSize.height - size.height));
end

function FateDetailInfoPageBase:getFateInfoDesHtmlStr(container, fateData)
    if not fateData then return end
    --获取命格详情的属性html
    local strTb = {}
    local conf = fateData:getConf()
    local quality = conf.quality
    local imgStr = UserEquipManager:getEquipSpaceImg()
    
    if conf.appendDes and conf.appendDes ~= "" then
        local str = common:getLanguageString(conf.appendDes)
        table.insert(strTb, common:fillHtmlStr("FateInforAppendFront", str))
        table.insert(strTb, imgStr)--图片分隔符
    end
    
    local basicAttrList = fateData:getFateBasicAttr()
    if #basicAttrList > 0 then
        --table.insert(strTb, imgStr)--图片分隔符
        table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@BadgeBasicAttrTxt")))--基础属性标题
        for _,v in ipairs(basicAttrList) do
            local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
            local name = common:getLanguageString("@AttrName_" .. v.type);
            local str = common:fillHtmlStr("MainAttr", common:getLanguageString("@EquipAttrVal", name, valueStr))--基础属性
            table.insert(strTb, str)
        end
    end
    if #conf.starAttr > 0 then
        --table.insert(strTb, imgStr)--图片分隔符
        table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@BadgeStarAttrTxt")))--星级属性标题
        for _,v in ipairs(conf.starAttr) do
            local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
            local name = common:getLanguageString("@AttrName_" .. v.type);
            local str = common:fillHtmlStr("SecondaryAttr_" .. quality, common:getLanguageString("@EquipAttrVal", name, valueStr))
            table.insert(strTb, str)
        end
    end
    local nextAddAttrList = fateData:getNextAddAttr()
    if #nextAddAttrList > 0 then
        --table.insert(strTb, imgStr)--图片分隔符
        table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@BadgeUpgradeAttrTxt")))--进级属性标题
        for _,v in ipairs(nextAddAttrList) do
            local valueStr = EquipManager:getGodlyAttrString(v.type, v.value)
            local name = common:getLanguageString("@AttrName_" .. v.type);
            local str = common:fillHtmlStr("GreenFontColor", common:getLanguageString("@EquipAttrVal", name, valueStr))
            table.insert(strTb, str)
        end
    end
    --table.insert(strTb, imgStr)--图片分隔符
    table.insert(strTb,common:fillHtmlStr("FateInforAppend", common:getLanguageString("@BadgeExtraImfor")))--额外文本显示

    --修學旅行效果說明
    NodeHelper:setStringForLabel(container, { mMultiEffectTxt = common:getLanguageString("@BadgeUpEffectTip", conf.adaptation) })
    NodeHelper:setNodesVisible(container, { mMultiEffectTxt = conf.adaptation > 0 })
    
    local retStr = table.concat(strTb, "<br/>");
	--通过margin设置不同的宽度
	local margin = GameConfig.Margin.EquipInfo
	return  common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

function FateDetailInfoPageBase:onExit(container)
    FateDetailInfoPageBase:removePacket(container)
end

--升级
function FateDetailInfoPageBase:onLevelUp(container)
    if PageInfo.isOthers then
        return
    end
    if PageInfo.fateData:isMaxLevel() then
        return
    end
    require("FateSwallowPage")
    FateSwallowPage_setFate(PageInfo.fateData.id)
    --如果没到最高等级
    PageManager.pushPage("FateSwallowPage") 
end

--换装
function FateDetailInfoPageBase:onChange(container)
    if PageInfo.fateData and PageInfo.fateData.roleId then
        require("FateWearsSelectPage")
        FateWearsSelectPage_setFate({roleId = PageInfo.fateData.roleId,locPos = PageInfo.locPos, currentFateId = PageInfo.fateData.id})
        PageManager.pushPage("FateWearsSelectPage")
    end
end

--脱下
function FateDetailInfoPageBase:onTakeOff(container)
    if PageInfo.fateData.roleId and PageInfo.locPos then
        local msg = MysticalDress_pb.HPMysticalDressChange()
        msg.roleId = PageInfo.fateData.roleId
        msg.loc = PageInfo.locPos
        msg.type = 2 -- 1表示穿上 2表示卸下 3表示更换
        msg.offEquipId = PageInfo.fateData.id
        common:sendPacket(option.opcode.MYSTICAL_DRESS_CHANGE_C,msg)

        MessageBoxPage:Msg_Box("@RemoveEquip")
    end
end

--关闭界面
function FateDetailInfoPageBase:onClose(container)
    PageManager.popPage("FateDetailInfoPage")
end

--isOthers 是否是查看他人命格
-- fateData 命格Id
-- locPos 命格穿戴的位置
function FateDetailInfoPage_setFate(data)
    PageInfo.isOthers = data.isOthers
    PageInfo.fateData = data.fateData
    PageInfo.locPos = data.locPos
end

local CommonPage = require("CommonPage");
FateDetailInfoPage = CommonPage.newSub(FateDetailInfoPageBase, "FateDetailInfoPage", option);