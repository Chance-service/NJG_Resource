----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb 		= require("Const_pb");
local EquipOpr_pb 	= require("EquipOpr_pb");
local HP_pb			= require("HP_pb");
local UserInfo = require("PlayerInfo.UserInfo");

------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local table = table;
--------------------------------------------------------------------------------

local thisPageName 	= "EquipBaptizePage";
local thisEquipId	= 0;

local opcodes = {
	EQUIP_BAPTIZE_S	= HP_pb.EQUIP_BAPTIZE_S

};

local option = {
	ccbiFile = "EquipmentRefinementPopUp.ccbi",
    ccbiFile105 = "EquipmentRefinementNewPopUp.ccbi",
	handlerMap = {
		onRefinement 	= "onRefinement",
        onSeniorRefinement = "onSeniorRefinement",
		onHelp 			= "onHelp",
		onClose			= "onClose",
        onChoiceBtn1     = "onChoiceBtn1",
        onChoiceBtn2     = "onChoiceBtn2",
        onChoiceBtn3     = "onChoiceBtn3",
        onChoiceBtn4     = "onChoiceBtn4",
	},
	opcode = opcodes
};

local EquipBaptizePageBase = {};

local NodeHelper = require("NodeHelper");
local PBHelper = require("PBHelper");
local EquipOprHelper = require("Equip.EquipOprHelper");
local ItemManager = require("Item.ItemManager");
local NewbieGuideManager = require("NewbieGuideManager")
local lackInfo = {coin = false,gold = false};
local Btnclick = {};
local AtrrShowlist={};
local SendAtrrlist={};
local HavingAtrrlist ={};

local isFirst = true;
local m_tOriAttr = {
  0,0,0,0
}
local m_tArrowSprite = {
  "mEquipStrenArrow0",
  "mEquipDextArrow0",
  "mEquipIntelliArrow0",
  "mEquipStaminaArrow0",
}
---一些工具函数
function EquipBaptizePageBase:Least2false()
     local Falsenum = 0;
     for key, value in pairs(Btnclick) do
          if value == false then
              Falsenum = Falsenum + 1;
          end
     end
     if Falsenum <= 2 then return false end
     if Falsenum > 2 then return true end
end 

function EquipBaptizePageBase:getSendList()
     SendAtrrlist = {}
     for key, value in pairs(Btnclick) do
          if value == true then
           table.insert(SendAtrrlist, HavingAtrrlist[key]);
          end
     end
end 

function EquipBaptizePageBase:getSelectNum()
     local TrueNum = 0;
     for key, value in pairs(Btnclick) do
          if value == true then
              TrueNum = TrueNum + 1;
          end
     end
     return TrueNum
end 
-----------------------------------------------
--EquipBaptizePageBase页面中的事件处理
----------------------------------------------
function EquipBaptizePageBase:onLoad(container)
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    if userEquip then
        local equipId = userEquip.equipId;
	    local level = EquipManager:getLevelById(equipId);
        if level >= 105 then
            container:loadCcbiFile(option.ccbiFile105)
        else
            container:loadCcbiFile(option.ccbiFile105)
        end
    else
        container:loadCcbiFile(option.ccbiFile105)
    end
end

function EquipBaptizePageBase:onEnter(container)
    Btnclick = {};
    AtrrShowlist={};
    SendAtrrlist={};
    HavingAtrrlist ={};
    isFirst = true

	self:registerPacket(container);
    self:showEquipInfo_static(container);
	self:showSecondAttrInfo(container);
	self:refreshPage(container);
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_BAPTIZE)
    local relativeNode = container:getVarNode("S9_1")
    GameUtil:clickOtherClosePage(relativeNode, function ()
        self:onClose(container)
    end,container)
end

function EquipBaptizePageBase:onExit(container)
    isFirst = true
    Btnclick = {};
    AtrrShowlist={};
    SendAtrrlist={};
    HavingAtrrlist ={};
	self:removePacket(container);
end
----------------------------------------------------------------

function EquipBaptizePageBase:refreshPage(container)
	self:showEquipInfo(container);
	self:showBaptizeInfo(container);
end

function EquipBaptizePageBase:showEquipInfo_static(container)
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
	if userEquip == nil or userEquip.id == nil then
		return;
	end
	
	local equipId = userEquip.equipId;
	local level = EquipManager:getLevelById(equipId);
	local name	= EquipManager:getNameById(equipId);
	local quality = EquipManager:getQualityById(equipId);
	local lb2Str = {
		mLv 				= common:getR2LVL() .. level,
		mLvNum				= userEquip.strength == 0 and "" or "+" .. userEquip.strength,
		mEquipmentName		= "",
		mEquipmentTex		= ""
	};
	local sprite2Img = {
		mPic = EquipManager:getIconById(equipId)
	};
	local itemImg2Qulity = {
		mHand = quality
	};
	local scaleMap = {mPic = GameConfig.EquipmentIconScale};	
	
	local nodesVisible = {};
	local gemVisible = false;
	local aniVisible = UserEquipManager:isEquipGodly(userEquip);			
	local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
	if table.maxn(gemInfo) > 0 then
		gemVisible = true;
		for i = 1, 4 do
			local gemId = gemInfo[i];
			nodesVisible["mGemBG" .. i] = gemId ~= nil;
			local gemSprite = "mGem0" .. i;
			nodesVisible[gemSprite] = false;
			if gemId ~= nil and gemId > 0 then
			local icon = ItemManager:getGemSmallIcon(gemId);
			if icon then
				nodesVisible[gemSprite] = true;
				sprite2Img[gemSprite] = icon;
				scaleMap[gemSprite] = 1
				end
			end
		end
	end
	nodesVisible["mAni"]	= aniVisible;
	nodesVisible["mGemNode"]	= gemVisible;
	NodeHelper:setNodesVisible(container, nodesVisible);
	
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, itemImg2Qulity);
	
	local tag = GameConfig.Tag.HtmlLable;
	local nameStr = common:getLanguageString("@LevelName",  name);
	nameStr = common:fillHtmlStr("Quality_deep_" .. quality, nameStr);
	local nameNode = container:getVarNode("mEquipmentName");
	--add 
	if Golb_Platform_Info.is_r2_platform then
		nameNode:setScale(1.0)
	end
	
	local _label = NodeHelper:addHtmlLable(nameNode, nameStr, tag , CCSizeMake(380 , 60));
	local stepLevel = EquipManager:getEquipStepById(equipId)	
	local starSprite = container:getVarSprite("mStar")
	local posX = _label:getContentSize().width * _label:getScaleX() + _label:getPositionX()
	local posY = _label:getPositionY() - ( _label:getContentSize().height - starSprite:getContentSize().height )/2
	EquipManager:setStarPosition(starSprite, stepLevel == GameConfig.ShowStepStar, posX, posY)
	
  local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
	local str = UserEquipManager:getEquipDescBasicInfo_deep(userEquip)--UserEquipManager:getEquipInfoBaptizeString(thisEquipId);
	local lbNode = container:getVarNode("mEquipmentTex");
	NodeHelper:addHtmlLable(lbNode, str, tag + 1, CCSizeMake(345, 500));
	
	NodeHelper:addEquipAni(container, "mAni", aniVisible, thisEquipId);
end

function EquipBaptizePageBase:showEquipInfo(container)
    AtrrShowlist={};
    SendAtrrlist={};
    HavingAtrrlist ={};

    local STRENGHTstr = UserEquipManager:getEquipInfoMainString(thisEquipId,"STRENGHT");
    if STRENGHTstr ~= "" then
        table.insert(AtrrShowlist,  STRENGHTstr);
        table.insert(HavingAtrrlist,  1);
    end

    local AGILITYstr = UserEquipManager:getEquipInfoMainString(thisEquipId,"AGILITY");
    if AGILITYstr ~= "" then
        table.insert(AtrrShowlist,AGILITYstr);
        table.insert(HavingAtrrlist,  2);

    end

    local INTELLECTstr = UserEquipManager:getEquipInfoMainString(thisEquipId,"INTELLECT");
    if INTELLECTstr ~= "" then
        table.insert(AtrrShowlist, INTELLECTstr);
        table.insert(HavingAtrrlist,  3);

    end

    local STAMINAstr = UserEquipManager:getEquipInfoMainString(thisEquipId,"STAMINA");
    if STAMINAstr ~= "" then
        table.insert(AtrrShowlist, STAMINAstr);
        table.insert(HavingAtrrlist,  4);

    end

    for i=1,4 do
        container:getVarNode("mChoiceBtnNode"..i):setVisible(false)
    end
    for key, value in pairs(AtrrShowlist) do

        local CanSee = {
             ["mChoiceBtnNode"..key] = true,
             ["mAttribute"..key] = true,
             ["mMenu"..key]= true
        }
       NodeHelper:setNodesVisible(container, CanSee);

       local lb2Str = {
  	      ["mAttribute"..key] = value;
       };
  	   NodeHelper:setStringForLabel(container, lb2Str);
        
       -- 上下箭头 
       local upSprite = m_tArrowSprite[key].."1"
       local downSprite = m_tArrowSprite[key].."2"
       if tonumber(string.match(value,"%d+")) > tonumber(m_tOriAttr[key]) then
            container:getVarNode(upSprite):setVisible(true)
            container:getVarNode(downSprite):setVisible(false)
       elseif tonumber(string.match(value,"%d+")) < tonumber(m_tOriAttr[key]) then
            container:getVarNode(upSprite):setVisible(false)
            container:getVarNode(downSprite):setVisible(true)
       end
       NodeHelper:setQualityBMFontLabels_deep(container,{["mAttribute"..key] =  UserEquipManager:getQuality(thisEquipId)});
       m_tOriAttr[key] = string.match(value,"%d+")

       if isFirst then
          table.insert(Btnclick, false);
          -- 第一次进入页面的时候隐藏箭头
          local arrowTable = {}
          for i=1,2 do
            arrowTable[m_tArrowSprite[key]..i] = false
          end
          NodeHelper:setNodesVisible(container,arrowTable)
       end
  	end

    isFirst = false
end

function EquipBaptizePageBase:showBaptizeInfo(container)
	local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
	
  local cost = EquipManager:getBaptizeCost(userEquip.equipId);
--[[
	local lb2Str = {
		mOrdinarySuccinct =common:getLanguageString("@NormalRefinementCost")..common:getLanguageString("@CurrentOwnInfo", cost, UserInfo.playerInfo.coin)
	};
	
	NodeHelper:setStringForLabel(container, lb2Str);
	
	lackInfo.coin = cost > UserInfo.playerInfo.coin;
	local colorMap = {
		mOrdinarySuccinct 		= common:getColorFromConfig(lackInfo.coin and "Lack" or "Own")
	};
	NodeHelper:setColor3BForLabel(container, colorMap);
--]]
    --下面是钻石
    local num = self:getSelectNum();
   local goldcost = GameConfig.GoldCostForBaptize[num];
--[[
   local lb2Str2 = {
		mSeniorSuccinct =common:getLanguageString("@SurperRefinementCost")..common:getLanguageString("@CurrentOwnInfo", goldcost, UserInfo.playerInfo.gold)
	};
    NodeHelper:setStringForLabel(container, lb2Str2);
	
	lackInfo.gold = goldcost > UserInfo.playerInfo.gold;
	local colorMap2 = {
		mSeniorSuccinct = common:getColorFromConfig(lackInfo.gold and "Lack" or "Own")
	};
	NodeHelper:setColor3BForLabel(container, colorMap2);
	--]]

	--NodeHelper:setStringForLabel(container,{mCostCoin = cost,mCostGold1 = goldcost})
	local tag = GameConfig.Tag.HtmlLable
  --NodeHelper:addItemIsEnoughHtmlLabNotShowHas(container, "mCostCoin", cost, UserInfo.playerInfo.coin, tag+1)
  --NodeHelper:addItemIsEnoughHtmlLabNotShowHas(container, "mCostGold1", goldcost, UserInfo.playerInfo.gold, tag+2)

        NodeHelper:setStringForLabel(container, {mCostGold1 = goldcost  , mCostCoin = cost})
end

function EquipBaptizePageBase:showSecondAttrInfo(container)

    local str = "@EquipmentRefinementExplain"
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    if userEquip then
        local equipId = userEquip.equipId;
	    local level = EquipManager:getLevelById(equipId);
        if level >= 105 then
            str = "@EquipmentRefinementNewExplain"
            NodeHelper:setNodeScale(container, "mExplain", 0.75, 0.75)
        else
          NodeHelper:setNodeScale(container, "mExplain", 1, 1)
        end
    end

	local lb2Str = {
		mExplain = common:getLanguageString(str)
	};

    NodeHelper:setStringForLabel(container, lb2Str)
  --文字显示重叠去掉了
	--NodeHelper:setStringForLabel(container, lb2Str);
end
	
----------------click event------------------------
function EquipBaptizePageBase:onRefinement(container)
    if self:getSelectNum() == 0 then
	  if lackInfo.coin then
		 PageManager.notifyLackCoin();
	  else
		 EquipOprHelper:baptizeEquip(thisEquipId);
	  end
    else
      Btnclick ={}
      local CanSee = {
          mLock1 = false,
          mLock2 = false,
          mLock3 = false,
          mLock4 = false,
        }
        NodeHelper:setNodesVisible(container, CanSee);
        isFirst = true
      self:refreshPage(container);
    end
end

function EquipBaptizePageBase:onSeniorRefinement(container)
	if lackInfo.gold then
		PageManager.notifyLackGold();
	else
        self:getSendList();
        local a = SendAtrrlist;
		EquipOprHelper:SuperbaptizeEquip(thisEquipId,SendAtrrlist);
	end
end


function EquipBaptizePageBase:onChoiceBtn1(container)
	if Btnclick[1] == false then
      if self:Least2false() then 
        Btnclick[1] = true;
        local CanSee = {
          mLock1 = Btnclick[1]
        }
        NodeHelper:setNodesVisible(container, CanSee);
        self:setAtrrVisible(container, 1)
       end
    else  
       Btnclick[1] = false;
       local CanSee = {
          mLock1 = Btnclick[1]
       }
       NodeHelper:setNodesVisible(container, CanSee);
    end

    self:refreshPage(container);
end

function EquipBaptizePageBase:onChoiceBtn2(container)
	if Btnclick[2] == false then
      if self:Least2false() then 
        Btnclick[2] = true;
        local CanSee = {
          mLock2 = Btnclick[2]
        }
        NodeHelper:setNodesVisible(container, CanSee);
        self:setAtrrVisible(container, 2)
       end
    else  
       Btnclick[2] = false;
       local CanSee = {
          mLock2 = Btnclick[2]
       }
       NodeHelper:setNodesVisible(container, CanSee);
    end
    self:refreshPage(container);
end

function EquipBaptizePageBase:onChoiceBtn3(container)
	if Btnclick[3] == false then
      if self:Least2false() then 
        Btnclick[3] = true;
        local CanSee = {
          mLock3 = Btnclick[3]
        }
        NodeHelper:setNodesVisible(container, CanSee);
        self:setAtrrVisible(container, 3)
       end
    else  
       Btnclick[3] = false;
       local CanSee = {
          mLock3 = Btnclick[3]
       }
       NodeHelper:setNodesVisible(container, CanSee);
    end
    self:refreshPage(container);
end

function EquipBaptizePageBase:onChoiceBtn4(container)
	if Btnclick[4] == false then
      if self:Least2false() then 
        Btnclick[4] = true;
        local CanSee = {
          mLock4 = Btnclick[4]
        }
        NodeHelper:setNodesVisible(container, CanSee);
        self:setAtrrVisible(container, 4)
       end
    else  
       Btnclick[4] = false;
       local CanSee = {
          mLock4 = Btnclick[4]
       }
       NodeHelper:setNodesVisible(container, CanSee);
    end
    self:refreshPage(container);
end

function EquipBaptizePageBase:setAtrrVisible(container, index)
  local upSprite = m_tArrowSprite[index].."1"
  local downSprite = m_tArrowSprite[index].."2"
  
  local node = container:getVarNode(upSprite)
  NodeHelper:setNodeVisible(node, false)
  local node = container:getVarNode(downSprite)
  NodeHelper:setNodeVisible(node, false)
end

function EquipBaptizePageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_BAPTIZE);
end	

function EquipBaptizePageBase:onClose(container)
    isFirst = true
    Btnclick = {};
    AtrrShowlist={};
    SendAtrrlist={};
    HavingAtrrlist ={};
	PageManager.popPage(thisPageName);
end

--回包处理
function EquipBaptizePageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == opcodes.EQUIP_BAPTIZE_S then
		UserInfo.syncPlayerInfo();
		self:refreshPage(container);
		return
	end
end

function EquipBaptizePageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function EquipBaptizePageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
EquipBaptizePage = CommonPage.newSub(EquipBaptizePageBase, thisPageName, option);

function EquipBaptizePage_setEquipId(equipId)
	thisEquipId = equipId;
end
