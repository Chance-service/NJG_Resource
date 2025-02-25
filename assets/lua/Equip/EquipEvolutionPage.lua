

local thisPageName = "EquipEvolutionPage"
local NodeHelper = require("NodeHelper")
local EquipEvolutionPageBase = {}
local MAX_EVOLUTION_STUFF_NUM = 4
local PageInfo = {
    thisUserEquipId = 0,
    currEquipInfo = {
        userEquipInfo = {},
        itemInfo = {}
    },
    evolutionItemInfo = {},
    nodeParams = {
        mainNode = "mRewardNode",
        picNode = "mPic",
        qualityNode = "mFrame",
        numNode = "mNum",
        nameNode = "mName"
    }
}

local opcodes = {
    EQUIP_EVOLUTION_C = HP_pb.EQUIP_UPGRADE_C,
	EQUIP_EVOLUTION_S = HP_pb.EQUIP_UPGRADE_S
}

local option = {
    ccbiFile = "SuitEvolutionPopUp.ccbi",
	handlerMap = {
		onAKeyEvolution				= "onCancle",
		onEvolution 			    = "onEvolution",
        onClose	        			= "onClose",
        onEquipmentFrame2           = "onEquipmentFrame2"
	},
	opcode = opcodes
}

local stuffList = {
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4
}

for i = 1, #stuffList do
	    option.handlerMap["onFrame" .. i] = "showTips"
end
---------------------------------------------------------------------------------------------------------------------------------
function EquipEvolutionPageBase:onEnter( container )
    self:registerPacket( container )
    if PageInfo.thisUserEquipId == nil or PageInfo.thisUserEquipId <= 0 then return end
    self:initData( container )
    self:refreshPage( container )
end

function EquipEvolutionPageBase:onExecute( container )

end

function EquipEvolutionPageBase:onExit( container )
    self:removePacket( container )
end

--------------------------------------------------------------------------------------------------------------------------------

function EquipEvolutionPageBase:initData( container )
    local UserEquipManager = require("Equip.UserEquipManager")
    local EquipManager = require("Equip.EquipManager")

    PageInfo.currEquipInfo.userEquipInfo = UserEquipManager:getUserEquipById( PageInfo.thisUserEquipId )
    PageInfo.currEquipInfo.itemInfo = EquipManager:getEquipCfgById( PageInfo.currEquipInfo.userEquipInfo.equipId )

    PageInfo.evolutionItemInfo = EquipManager:getEquipCfgById( PageInfo.currEquipInfo.itemInfo.evolutionId )

end

function EquipEvolutionPageBase:refreshPage( container )
   local NodeHelper = require("NodeHelper") 
   local UserInfo = require("PlayerInfo.UserInfo")
   local EquipManager = require("Equip.EquipManager")
   UserInfo.sync()
   local lb2StrStuff = {}
   local sprite2Img = {
       mEquipmentPic1 = PageInfo.currEquipInfo.itemInfo.icon,
       mEquipmentPic2 = PageInfo.evolutionItemInfo.icon
   }
   

   local mOriName1 = PageInfo.currEquipInfo.itemInfo.name
   local mOriName2 = PageInfo.evolutionItemInfo.name
   local gule = ","
   local mOriMainAttr1 = EquipManager:getInitAttr( PageInfo.currEquipInfo.itemInfo.id ,gule,PageInfo.currEquipInfo.userEquipInfo.strength ,PageInfo.currEquipInfo.itemInfo.quality )
   local mOriMainAttr2 = EquipManager:getInitAttr( PageInfo.evolutionItemInfo.id ,gule,PageInfo.currEquipInfo.userEquipInfo.strength , PageInfo.evolutionItemInfo.quality )

   local mOriAdditionalAttr1 = common:getLanguageString("@AdditionalAttr" ,  PageInfo.currEquipInfo.itemInfo.additionalAttr )
   local mOriAdditionalAttr2 = common:getLanguageString("@AdditionalAttr" ,  PageInfo.evolutionItemInfo.additionalAttr )
   
   local htmlStrTab1 = mOriName1 .. "<br/>" 
   local htmlStrTab2 = mOriName2 .. "<br/>" 

   local attrOriMainTab1 =common:split( mOriMainAttr1 ,gule ) 
   local attrOriMainTab2 =common:split( mOriMainAttr2 ,gule )

   for i = 1,3 do
      if i <= 2 then
        lb2StrStuff["mEquipAtt"..i] = attrOriMainTab1[i]
        lb2StrStuff["mEquipAtt"..i+4] = attrOriMainTab2[i]
      else
        lb2StrStuff["mEquipAttAll1"] = mOriAdditionalAttr1
        lb2StrStuff["mEquipAttAll2"] = mOriAdditionalAttr2
      end
       --htmlStrTab1 = htmlStrTab1 .. attrOriMainTab1[i] .. "<br/>"
       --htmlStrTab2 = htmlStrTab2 .. attrOriMainTab2[i] .. "<br/>"
   end
   
   local suitCfg = ConfigManager.getSuitCfg()
   local curSuitId =  EquipManager:getSuitIdById( PageInfo.currEquipInfo.userEquipInfo.equipId )
   local nextSuitId =  EquipManager:getSuitIdById( PageInfo.currEquipInfo.itemInfo.evolutionId ) 

   lb2StrStuff["mEquipLevel1"] = suitCfg[curSuitId].suitName 
   lb2StrStuff["mEquipLevel2"] = suitCfg[nextSuitId].suitName 

   local curMercenarySuitId = EquipManager:getMercenarySuitId(PageInfo.currEquipInfo.userEquipInfo.equipId);
   local nextMercenarySuitId = EquipManager:getMercenarySuitId( PageInfo.currEquipInfo.itemInfo.evolutionId ) 
   lb2StrStuff["mMercenaryName1"] = common:getLanguageString("@Role_"..EquipManager:getMercenarySuitMercenaryId(curMercenarySuitId))..common:getLanguageString("@EquipStr6")
   lb2StrStuff["mMercenaryName2"] = common:getLanguageString("@Role_"..EquipManager:getMercenarySuitMercenaryId(nextMercenarySuitId))..common:getLanguageString("@EquipStr6")
   --当前属性
   for i=1,3 do
     NodeHelper:setStringForLabel(container, {["mEquipEverAtt"..i] = "", ["mEquipNowAtt"..i] = ""})
   end

   local descs = EquipManager:getMercenarySuitDescs(curMercenarySuitId)
   local index = 1
   for k,v in pairs(descs) do
      lb2StrStuff["mEquipEverAtt"..index] = common:getLanguageString("@EquipStr"..tostring(6+index))..v
      index = index + 1
   end

   ---下一级属性
   local descs = EquipManager:getMercenarySuitDescs(nextMercenarySuitId)
   local index = 1
   for k,v in pairs(descs) do
      lb2StrStuff["mEquipNowAtt"..index] = common:getLanguageString("@EquipStr"..tostring(6+index))..v
      index = index + 1
   end

   -- htmlStrTab1 = htmlStrTab1 .. mOriAdditionalAttr1
   -- htmlStrTab2 = htmlStrTab2 .. mOriAdditionalAttr2

   -- common:fillHtmlStr("EvoMain1" ,htmlStrTab1)

   -- NodeHelper:addHtmlLable( container:getVarNode("mEquipLevel1") , common:fillHtmlStr("EvoMain1" ,htmlStrTab1) ,GameConfig.Tag.HtmlLable, CCSize(200, 90))
   -- NodeHelper:addHtmlLable( container:getVarNode("mEquipLevel2") , common:fillHtmlStr("EvoMain2" ,htmlStrTab2) ,GameConfig.Tag.HtmlLable + 1, CCSize(200, 90) )

   local menu2Quality = {
       mEquipmentFrame1 = PageInfo.currEquipInfo.itemInfo.quality,
       mEquipmentFrame2 = PageInfo.evolutionItemInfo.quality
   }

   NodeHelper:setSpriteImage(container, sprite2Img)
   NodeHelper:setQualityFrames(container, menu2Quality)
   
   local currStuffNum = #PageInfo.currEquipInfo.itemInfo.evolutionStuff
   local nodesVisible = {}
   for i = 1 ,MAX_EVOLUTION_STUFF_NUM,1 do
      nodesVisible[ PageInfo.nodeParams.mainNode .. i ] = i <= currStuffNum
   end
   NodeHelper:setNodesVisible(container, nodesVisible)

   local sprite2ImgStuff = {}
   local menu2QualityStuff = {}
  
   --名字
   local colorMap2 = {}
   lb2StrStuff.mName1 = PageInfo.currEquipInfo.itemInfo.name
   lb2StrStuff.mName2 = PageInfo.evolutionItemInfo.name
   lb2StrStuff.mLv1 = common:getLanguageString("@MyLevel", PageInfo.currEquipInfo.itemInfo.level)
   lb2StrStuff.mLv2 = common:getLanguageString("@MyLevel", PageInfo.evolutionItemInfo.level)

   for i = 1,currStuffNum,1 do
      local cfg = PageInfo.currEquipInfo.itemInfo.evolutionStuff[i]
      local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
      local UserItemManager = require("Item.UserItemManager")

      local hasCount = 0
      
      if resInfo.itemId == 1001 then
           hasCount = UserInfo.playerInfo.gold
      elseif resInfo.itemId == 1002 then
           hasCount = UserInfo.playerInfo.coin
      elseif resInfo.itemId == 1010 then
           hasCount = UserInfo.playerInfo.honorValue
      elseif resInfo.itemId == 1011 then
           hasCount = UserInfo.playerInfo.reputationValue
      else
           if UserItemManager:getUserItemByItemId( resInfo.itemId ) == nil then
                hasCount = 0
           else
                hasCount = UserItemManager:getUserItemByItemId( resInfo.itemId ).count
           end
      end

      local isEnoughMaterial = hasCount >= resInfo.count
          
      sprite2ImgStuff[ PageInfo.nodeParams.picNode .. i] = resInfo.icon
      menu2QualityStuff[ PageInfo.nodeParams.qualityNode.. i ] = resInfo.quality
      --lb2StrStuff[ PageInfo.nodeParams.numNode  .. i ] = resInfo.count
      NodeHelper:addItemIsEnoughHtmlLabNotShowHas(container, PageInfo.nodeParams.numNode..i, resInfo.count, hasCount, GameConfig.Tag.HtmlLable+20+i)
      colorMap2[ PageInfo.nodeParams.numNode .. i ] = UserEquipManager:getEquipEvolutionMaterialColor(isEnoughMaterial and "Enough" or "Short")
      --lb2StrStuff[ PageInfo.nodeParams.nameNode .. i ] = resInfo.name
   end

   --NodeHelper:setStringForLabel( container, lb2Str )

   NodeHelper:setStringForLabel(container, lb2StrStuff)
   NodeHelper:setSpriteImage(container, sprite2ImgStuff)
   NodeHelper:setQualityFrames(container, menu2QualityStuff, nil, true)
   NodeHelper:setColor3BForLabel(container, colorMap2);
   --GameUtil:showTip(container:getVarNode("mHand"), rewadItems[id])  
end


--------------------------------------------------------------------------------------------------------------------------------

function EquipEvolutionPageBase:showTips( container , eventName )
    local indexStr = string.sub( eventName , -3 )
    local index = tonumber( string.sub( eventName , -1 ))
    if PageInfo.currEquipInfo.itemInfo.evolutionStuff[index] ~= nil then
        GameUtil:showTip(container:getVarNode('mFrame' .. index ), {
		type		= PageInfo.currEquipInfo.itemInfo.evolutionStuff[index].type, 
		itemId 		= tonumber(PageInfo.currEquipInfo.itemInfo.evolutionStuff[index].itemId),
		buyTip		= false,
	})
    end
end

function EquipEvolutionPageBase:onEquipmentFrame2( container )
 --    GameUtil:showTip(container:getVarNode('mEquipmentFrame2'), {
	-- 	type 		= 40000, 
	-- 	itemId 		= tonumber(PageInfo.evolutionItemInfo.id),
	-- 	buyTip		= false,
	-- 	starEquip	= tonumber(PageInfo.evolutionItemInfo.stepLevel) == GameConfig.ShowStepStar
	-- })
end

function EquipEvolutionPageBase:onCancle( container )
    PageManager.popPage( thisPageName )
end

function EquipEvolutionPageBase:onClose( container )
    PageManager.popPage( thisPageName )
end

function EquipEvolutionPageBase:onEvolution( container )
    --local msg = EquipOpr_pb.HPEquipEvolution()
    local msg = EquipOpr_pb.HPEquipUpgrade()
    msg.equipId = PageInfo.thisUserEquipId
    msg.fixFlag = 0
    common:sendPacket( opcodes.EQUIP_EVOLUTION_C , msg, false)
end

--------------------------------------------------------------------------------------------------------------------------------
function EquipEvolutionPageBase:onReceivePacket( container )
  local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == opcodes.EQUIP_EVOLUTION_S then
        MessageBoxPage:Msg_Box_Lan("@EvolutionSuccess")  
        PageManager.popPage( thisPageName )
        PageManager.refreshPage( "EquipInfoPage" )
        --PageManager.refreshPage("EquipmentPage")
        PageManager.refreshPage("EquipMercenaryPage")
	end
end

function EquipEvolutionPageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function EquipEvolutionPageBase:removePacket( container )
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

---------------------------------------------------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
EquipEvolutionPage = CommonPage.newSub(EquipEvolutionPageBase, thisPageName, option)

function EquipEvolutionPage_setItemId( userEquipId )
    PageInfo.thisUserEquipId = userEquipId
end