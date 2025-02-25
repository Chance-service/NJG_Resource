
----------------------------------------------------------------------------------


local thisPageName = "SEMainPage"
local NodeHelper   = require("NodeHelper");
local option = {
	ccbiFile = "SkillSpecialtyPage.ccbi",
	handlerMap = {
		onClose        = "onClose",
        onReturnBtn	   = "onClose",	
        onSkillPic     = "onSkillPic",
        onHelp         = "onHelp"
	}
}	

local UpgradeType = {
    Attribute = 0,
    Replace = 1,
    NewSkill = 2
}

local SEMainPageBase = {}
local SEManager = require("Skill.SEManager")
local Profession = nil
local SkillCfg = nil
local DelayTime = 0.1
local BaseDelayTime = 2.1
----------------------------------------------------------------------------------
local SEMainPageItem = {
    ccbiFile = "SkillSpecialtyContent.ccbi"
}

function SEMainPageItem.onFunction(eventName,container)
    if eventName == "luaRefreshItemView" then
        SEMainPageItem.onRefreshItemView(container);
    elseif eventName == "onUpgrade" then
        SEMainPageItem.onUpgrade(container)
    end
end

function SEMainPageItem.onRefreshItemView(container)
    local index = container:getItemDate().mID;

    if SkillCfg~=nil and SkillCfg[index]~=nil then
        local skillItemId = SkillCfg[index].skillItemId
        local level = SEManager:getSkillLevelInfoByItemId(skillItemId)
        local cfgItem = SEManager:getSkillCfgInfoByItemId(skillItemId)
        if cfgItem~=nil then
            --定义
            local labelStr = {}
            local spriteImg = {}
            local labelColor = {}
            --填充不需要服务端信息的数据，如图片、技能名等
            spriteImg["mChestPic"] = cfgItem.icon
            labelStr["mSkillName"] = cfgItem.name
            --填充当前等级
            local tempLevel = SEManager:getTempLevel( skillItemId )
            if level - tempLevel > 0 then
                if tempLevel > 0 then
                    --labelStr["mSkillPicLV"] = common:getR2LVL() .. (level - tempLevel)
                    --labelStr["mTempLv"] = "+" .. tempLevel
                else
                    --labelStr["mSkillPicLV"] = level>0 and common:getR2LVL()..level or common:getLanguageString("@SENoLearn")
                    --labelStr["mTempLv"] = ""
                end
            else
                --labelStr["mSkillPicLV"] = level>0 and common:getR2LVL()..level or common:getLanguageString("@SENoLearn")
                --labelStr["mTempLv"] = ""
            end
            
            --labelColor["mSkillPicLV"] = level>0 and GameConfig.ColorMap["COLOR_WHITE"] or GameConfig.ColorMap["COLOR_RED"]
            --判断技能是否已经解锁
            if level==0 then
                NodeHelper:setMenuItemEnabled(container,"mUpgrade",false)
                local Cansee = {
                mMpNode = false,
                mOpenLV = true,
				ConsumptionMpNode = false
                }
                NodeHelper:setNodesVisible(container, Cansee);
                 --技能几级开放
                labelStr["mOpenLV"] = common:getLanguageString("@SkillOpenAtLevel",cfgItem.openLevel)
            else
                NodeHelper:setMenuItemEnabled(container,"mUpgrade",true)
                local Cansee = {
                mMpNode = true,
                mOpenLV = false,
				ConsumptionMpNode = true
                }
                NodeHelper:setNodesVisible(container, Cansee);
                NodeHelper:setStringForLabel(container, {["mSkillLv"] = common:getLanguageString("@LevelStr", level)})
            end
           
            --技能消耗mp
            labelStr["mConsumptionMp"] = cfgItem.costMP
            --技能说明
        --    labelStr["mSkillTex"] = GameMaths:stringAutoReturnForLua(cfgItem.describe, 17, 0) 
			cfgItem.describe = GameMaths:replaceStringWithCharacterAll(cfgItem.describe,"#v1#",cfgItem.param1)
			cfgItem.describe = GameMaths:replaceStringWithCharacterAll(cfgItem.describe,"#v2#",cfgItem.param2)
			cfgItem.describe = GameMaths:replaceStringWithCharacterAll(cfgItem.describe,"#v3#",cfgItem.param3)

            labelStr["mSkillTex"] = common:stringAutoReturn(cfgItem.describe,GameConfig.LabelCharMaxNumOneLine.SkillSpecialtyContent)
            labelColor["mSkillTex"] = GameConfig.LabelSkillDescColor.SkillSpecialtyContent
			--NodeHelper:setCCHTMLLabel(container,"mSkillTex",CCSize(520,96),cfgItem.describe,true)
            --赋值
            NodeHelper:setStringForLabel(container,labelStr)
            NodeHelper:setSpriteImage(container,spriteImg)
            NodeHelper:setColorForLabel(container,labelColor)

           -- NodeHelper:setLabelOneByOne(container,"mSkillPicLV","mTempLv",3)
            --更换按钮图片
            if cfgItem.type == UpgradeType.Replace then
                 local imagePath = SEManager.config.SEChange
                 NodeHelper:setNormalImages(container, {mUpgrade = imagePath});
            end



            --播放动画
            --[[
            local array = CCArray:create();
			array:addObject(CCDelayTime:create(BaseDelayTime+index*DelayTime));				
			local functionAction = CCCallFunc:create(function ()
				container:runAnimation("StartAni")						
			end)
			array:addObject(functionAction);
			local seq = CCSequence:create(array);
			container:runAction(seq)--]]
        end
    end
end

function SEMainPageItem.onUpgrade(container)
    local index = container:getItemDate().mID;
    local skillItemId = SkillCfg[index].skillItemId
    local level = SEManager:getSkillLevelInfoByItemId(skillItemId)
    --还未学会该技能
    if level <= 0 then
        MessageBoxPage:Msg_Box_Lan("@SESkillNotLearn");
        return 
    end
    require("SEUpgradePage")
    if SkillCfg~=nil and SkillCfg[index]~=nil then
        local itemId = SkillCfg[index].skillItemId
        SEUpgradePage_ShowSEUpgradeByItemId(itemId,Profession)
    end
end

-----------------------------------------------
--SEMainPageBase页面中的事件处理
----------------------------------------------
function SEMainPageBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    NodeHelper:initScrollView(container, "mContent", 6);    	
    if container.mScrollView~=nil then
		container:autoAdjustResizeScrollview(container.mScrollView);
	end

    for i = 1,3 do
		NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite"..i))
	end

    self:refreshPage(container)
    self:rebuildAllItem(container)
end


function SEMainPageBase:onExecute(container)
	
end

function SEMainPageBase:onExit(container)
	container:registerMessage(MSG_MAINFRAME_REFRESH);
    NodeHelper:deleteScrollView(container);
end
----------------------------------------------------------------

function SEMainPageBase:refreshPage(container)
    --获得技能配置列表，1~12专精格子显示对应技能
    local ConfigManager = require("ConfigManager")
    local roleCfg = ConfigManager.getRoleCfg()
    local myProfession = roleCfg[Profession]["profession"]
    SkillCfg = SEManager:getSECfgByProfession(myProfession)

    --定义
    local labelStr = {}
    local spriteImg = {}
    local labelColor = {}
    --专精等级计算
    local SELevel = 1
    --填充12个技能专精数据
    for i=1,#SkillCfg do
        local skillItemId = SkillCfg[i].skillItemId
        local level = SEManager:getSkillLevelInfoByItemId(skillItemId)
        if level > 0 then
            SELevel = SELevel + level - 1;
        end
    end
    --填充被动技能信息
    SEManager.SELevel[Profession] = SELevel
    local staticSkill = SEManager:getSEStaticSkillByProfession(Profession)
    spriteImg["mSkillPic"] = staticSkill.icon
    labelStr["mSkillSpecialtyName"] = staticSkill.name
    --判断需要填充的属性个数
	local str = ""
    if staticSkill.baseAttr2~=0 then
        local attr1 = staticSkill.baseAttr1 + staticSkill.addAttr1 * SELevel
        local attr2 = staticSkill.baseAttr2 + staticSkill.addAttr2 * SELevel
        str = common:fill(staticSkill.description,attr1,attr2)--GameMaths:stringAutoReturnForLua(common:fill(staticSkill.description,attr1,attr2), 15, 0) 
    elseif staticSkill.baseAttr1~=0 then
        local attr1 = staticSkill.baseAttr1 + staticSkill.addAttr1 * SELevel
        str = common:fill(staticSkill.description,attr1)--GameMaths:stringAutoReturnForLua(common:fill(staticSkill.description,attr1), 15, 0) 
    else
        str = staticSkill.description--GameMaths:stringAutoReturnForLua(staticSkill.description, 15, 0) 
    end
	str = "<font color=\"#804038\" face = \"FOT-Skip Std D\" >" .. str .. "</font>"
	NodeHelper:setCCHTMLLabel(container,"mSkillSpecialtyTex",CCSize(510,96),str,true)
    --被动技能黄字说明
     labelStr["mSkillSpecialtyExplain"] = common:getLanguageString("@SkillSpecialTip")
    labelColor["mSkillSpecialtyExplain"] = GameConfig.LabelSkillDescColor.SkillSpecialtyContent
    labelStr["mSkillLevel"] = common:getR2LVL()..tostring(SELevel)
    labelColor["mSkillLevel"]  = GameConfig.LabelSkillDescColor.SkillSpecialtyContent
    --技能专精等级
    labelStr["mSELevelNum"] = common:getR2LVL()..tostring(SELevel)
    --调用通用方法
    NodeHelper:setStringForLabel(container,labelStr)
    NodeHelper:setSpriteImage(container,spriteImg)
    NodeHelper:setColorForLabel(container,labelColor)
	NodeHelper:setNodesVisible(container,{mSkillSpecialtyExplain = true})
    local mSkillLevelNode = container:getVarNode("mSkillLevel")
    local mSkillSpecialtyExplainNode = container:getVarNode("mSkillSpecialtyExplain")
    mSkillSpecialtyExplainNode:setPositionX(mSkillLevelNode:getPositionX() +mSkillLevelNode:getContentSize().width + 10 )
    --mSkillSpecialtyExplainNode:setPositionY(mSkillSpecialtyExplainNode:getPositionY() + 10  )
end

----------------scroll view------------------------
function SEMainPageBase:rebuildAllItem(container)  
    self:clearAllItem(container);
    self:buildItem(container);
end

function SEMainPageBase:buildItem(container)
    if SkillCfg~=nil and #SkillCfg > 0 then
        local size =  #SkillCfg
        NodeHelper:buildScrollView(container,size,SEMainPageItem.ccbiFile,SEMainPageItem.onFunction)
    end
end

function SEMainPageBase:clearAllItem(container)  
    NodeHelper:clearScrollView(container);
end
----------------click event------------------------
function SEMainPageBase:onClose(container)
	PageManager.changePage("SkillPage")
end	

function SEMainPageBase:onSkillPic(container,index)
	
end	

function SEMainPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_SKILLENHANCE)
end	

---------------Message Handle--------------------
function SEMainPageBase:onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		--local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam;
		if pageName == thisPageName then
			self:refreshPage(container);
            self:rebuildAllItem(container)
		end
	end
end

function SEMainPage_ShowSEPageByProfession(profession)
    Profession = profession
    PageManager.changePage("SEMainPage")
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local SEMainPage = CommonPage.newSub(SEMainPageBase, thisPageName, option);