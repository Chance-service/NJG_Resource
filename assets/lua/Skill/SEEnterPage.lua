
----------------------------------------------------------------------------------
local HP_pb = require("HP_pb")
local thisPageName = "SEEnterPage"
local NodeHelper = require("NodeHelper");
local UserInfo = require("PlayerInfo.UserInfo")
local option = {
    ccbiFile = "SkillOpenSpecialtyPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onConfirmation = "onConfirmation",
        onCancel = "onClose",
        onGoodsBtn02 = "showTip"
    }
}

local SEEnterPageBase = { }
local Profession = 0
local SEManager = require("Skill.SEManager")
----------------------------------------------------------------------------------

-----------------------------------------------
-- SEEnterPageBase页面中的事件处理
----------------------------------------------
function SEEnterPageBase:onEnter(container)
    container:registerPacket(HP_pb.SKILL_ENHANCE_OPEN_STATE_S)
    self:refreshPage(container)
end

function SEEnterPageBase:onExecute(container)

end

function SEEnterPageBase:onExit(container)
    container:removePacket(HP_pb.SKILL_ENHANCE_OPEN_STATE_S)
end
----------------------------------------------------------------

function SEEnterPageBase:refreshPage(container)
    -- 定义
    local labelStr = { }
    local spriteImg = { }
    local imgMenu = { }
    local nodeVisible = { }
    local labelColor = { }
    local flag = SEManager.HasOpen[Profession];
    -- 填充被动技能信息
    local staticSkill = SEManager:getSEStaticSkillByProfession(Profession)
    spriteImg["mSkillPic"] = staticSkill.icon
    labelStr["mSkillSpecialtyName"] = staticSkill.name
    NodeHelper:setStringForLabel(container, { ["mSkillLv"] = common:getLanguageString("@LevelStr", 1) })
    local str = ""
    if staticSkill.baseAttr2 ~= 0 then
        if flag then
            str = common:fill(staticSkill.description, staticSkill.baseAttr1, staticSkill.baseAttr2)
            -- GameMaths:stringAutoReturnForLua(common:fill(staticSkill.description,staticSkill.baseAttr1,staticSkill.baseAttr2),14,0)
        else
            str = common:fill(staticSkill.description, self:excuteSkillEffect(staticSkill.baseAttr1, staticSkill.addAttr1), self:excuteSkillEffect(staticSkill.baseAttr2, staticSkill.addAttr2))
            -- GameMaths:stringAutoReturnForLua(common:fill(staticSkill.description,self:excuteSkillEffect(staticSkill.baseAttr1,staticSkill.addAttr1),self:excuteSkillEffect(staticSkill.baseAttr2,staticSkill.addAttr2)),14,0)

        end

    elseif staticSkill.baseAttr1 ~= 0 then
        if flag then
            str = common:fill(staticSkill.description, staticSkill.baseAttr1)
            -- GameMaths:stringAutoReturnForLua(common:fill(staticSkill.description,staticSkill.baseAttr1),14,0)
        else
            str = common:fill(staticSkill.description, self:excuteSkillEffect(staticSkill.baseAttr1, staticSkill.addAttr1))
            -- GameMaths:stringAutoReturnForLua(common:fill(staticSkill.description,self:excuteSkillEffect(staticSkill.baseAttr1,staticSkill.addAttr1)),14,0)
        end
    else
        str = staticSkill.description
        -- GameMaths:stringAutoReturnForLua(staticSkill.description,14,0)
    end

    labelStr["mSkillSpecialtyTex"] = ""
    local str = "<font color=\"#6f2f00\" face = \"HelveticaBD16\" >" .. str .. "</font>"
    local labelNode = container:getVarLabelTTF("mSkillSpecialtyTex")
    labelNode:setScale(1)
    local s9Node = container:getVarScale9Sprite("mS9_1")
    local htmlLabel = NodeHelper:addHtmlLable(labelNode, str, 10086, CCSizeMake(s9Node:getContentSize().width - 10, 96))
    -- NodeHelper:setCCHTMLLabel(container, "mSkillSpecialtyTex", CCSize(510, 96), str, false)

    -- 被动技能黄字说明
    if flag then
        labelStr["mSkillSpecialtyExplain"] = staticSkill.tip
    else
        labelStr["mSkillSpecialtyExplain"] = staticSkill.mainPagedes
    end

    -- 开启需要消耗道具
    local OpenItem = SEManager:getConfigDataByKey("OpenItem")
    local UserItemManager = require("Item.UserItemManager")
    local userItemInfo = UserItemManager:getUserItemByItemId(OpenItem.id)
    local hasCount = 0
    if userItemInfo ~= nil then
        hasCount = userItemInfo.count
    end
    local ResManagerForLua = require("ResManagerForLua")
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(OpenItem.itemType, OpenItem.id, 1);
    local count = OpenItem.count
    if resInfo ~= nil then
        -- spriteImg["mGoodsPic01"] 		= resInfo.icon;
        -- labelStr["mGoodsNum01"]				= hasCount.. "/" .. count;
        -- labelStr["mGoodsName01"]			= resInfo.name;
        -- imgMenu["mGoodsBtn01"]		= resInfo.quality;
    end
    -- NodeHelper:addItemIsEnoughHtmlLab(container, "mGold", count, UserInfo.playerInfo.coin, GameConfig.Tag.HtmlLable)
    -- labelStr["mGold"] = count .. " / " .. UserInfo.playerInfo.coin
    labelStr["mGold"] = GameUtil:formatNumber(UserInfo.playerInfo.coin) .. "/" .. GameUtil:formatNumber(count)

    -- 调用通用方法
    NodeHelper:setNodesVisible(container, nodeVisible)
    NodeHelper:setStringForLabel(container, labelStr)
    NodeHelper:setSpriteImage(container, spriteImg)
    NodeHelper:setQualityFrames(container, imgMenu)
    NodeHelper:setColorForLabel(container, labelColor)
end
function SEEnterPageBase:excuteSkillEffect(baseSkill, addSkill)
    local result = baseSkill + addSkill * 96
    return result
end
----------------click event------------------------
function SEEnterPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function SEEnterPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_SKILLENHANCE)
end	

function SEEnterPageBase:onConfirmation(container)
    -- 判断道具是否足够
    local UserItemManager = require("Item.UserItemManager")
    local item = SEManager:getConfigDataByKey("OpenItem")
    local itemInfo = UserItemManager:getUserItemByItemId(item.id)
    -- 道具不足
    --[[if itemInfo==nil or itemInfo.count<item.count then
        local title = common:getLanguageString("@SEItemNotEnoughTitle")
        local message = common:getLanguageString("@SEItemNotEnoughMsg")
        PageManager.showConfirm(title,message, function(isSure)
			if isSure then
               local EliteMapManager = require("Battle.EliteMapManager")
               EliteMapManager:enterEliteMapInfoByProfId()
			end
		end);
        return
    end]]
    --


    local SkillEnhance_pb = require("SkillEnhance_pb")
    local msg = SkillEnhance_pb.HPSkillEnhanceOpen()
    common:sendPacket(HP_pb.SKILL_ENHANCE_OPEN_C, msg, false);
end	


function SEEnterPageBase:showTip(container)
    local openCfg = SEManager:getConfigDataByKey("OpenItem")
    local node = container:getVarNode("mGoodsBtn01")
    if openCfg ~= nil and node ~= nil then
        local cfg = {
            type = openCfg.itemType,
            itemId = openCfg.id
        }
        if cfg.type ~= nil and cfg.itemId ~= nil then
            GameUtil:showTip(node, cfg)
        end
    end
end
------------------------------------------------------------------------
function SEEnterPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();

    if opcode == HP_pb.SKILL_ENHANCE_OPEN_STATE_S then
        local SkillEnhance_pb = require("SkillEnhance_pb")
        local msg = SkillEnhance_pb.HPSkillEnhanceOpenState()
        msg:ParseFromString(msgBuff);

        if msg.isOpen then
            PageManager.popPage(thisPageName)
            -- require("SEEnterAniPopUpPage")
            -- SEEnterAniPopUpPage_ShowSEAniPageByProfession(Profession)
            require("SEMainPage")
            SEMainPage_ShowSEPageByProfession(Profession)
        end
    end
end	

------------------------------------------------------------------------
function SEEnterPage_showSEEnterByProfession(profession)
    Profession = profession
    PageManager.pushPage("SEEnterPage")
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local SEEnterPage = CommonPage.newSub(SEEnterPageBase, thisPageName, option);