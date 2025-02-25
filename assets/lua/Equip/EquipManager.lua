local EquipManager = {};


--------------------------------------------------------------------------------
local EquipCfg = ConfigManager.getEquipCfg();
local punchCfg = ConfigManager.getPunchCfg();
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
local Equip_pb = require("Equip_pb");
local Const_pb = require("Const_pb");
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
--------------------------------------------------------------------------------

function EquipManager:getEquipCfgById(equipId)
	return EquipCfg[equipId] or {};
end	

--从equip.txt获取装备属性
function EquipManager:getAttrById(equipId, attrName)
	local config = EquipCfg[equipId];
	if config then
		return config[attrName];
	end
	return "";
end
--从equip.txt 中获得 部位为5 的 哪种职业的神装
function EquipManager:getProfession(equipId,professLevel)
	local config = EquipCfg[equipId];
	local profession =  config["profession"]
	local part = config["part"]
	if part == 5 then
		if  profession[1] == tostring(UserInfo.roleInfo.prof) then
			return true
		else
			return false
		end
	else
		return false
	end
end

--从godlyAttr.txt获取神器属性（成长属性、强化加成）
function EquipManager:getGodlyAttrById(equipId, attrName)
	local GodlyAttrCfg = ConfigManager.getGodlyAttrCfg();
	local config = GodlyAttrCfg[equipId];
	if config then
		return config[attrName];
	end
	return "";
end

function EquipManager:getSuitIdById(equipId)
	local suitId = self:getAttrById(equipId, "suitId");
	return tonumber(suitId);
end

function EquipManager:getLevelById(equipId)
	local level = self:getAttrById(equipId, "level");
	return tonumber(level);
end

function EquipManager:getQualityById(equipId)
	return self:getAttrById(equipId, "quality");
end

function EquipManager:getStarById(equipId)
	return self:getAttrById(equipId, "stepLevel");
end

function EquipManager:getIconById(equipId)
	return self:getAttrById(equipId, "icon");
end

function EquipManager:getNameById(equipId)
	return self:getAttrById(equipId, "name");
end

function EquipManager:getPartById(equipId)
	return self:getAttrById(equipId, "part");
end

function EquipManager:getPartNameById(equipId)
	return self:getAttrById(equipId, "partName");
end

function EquipManager:getSmeltNeedById(equipId)
	return self:getAttrById(equipId, "forgeSmeltNeed");
end

function EquipManager:getSmeltGainById(equipId)
	return self:getAttrById(equipId, "smeltGain");
end

function EquipManager:getSmeltScoreById(equipId)
	return self:getAttrById(equipId, "score");
end
-- 合成
function EquipManager:getSmeltReoById(equipId)
	return self:getAttrById(equipId, "costReo");
end

function EquipManager:getSmeltCoinById(equipId)
	return self:getAttrById(equipId, "costCoin");
end

function EquipManager:getSmeltItemById(equipId)
	local items = self:getAttrById(equipId, "costItem1");
    local itemSplit = splitItem(items);
	return itemSplit[1].count, itemSplit[1].itemId;
end

function EquipManager:getSmeltItem2ById(equipId)
	local items = self:getAttrById(equipId, "costItem2");
    local itemSplit = splitItem(items);
	return itemSplit[1].count, itemSplit[1].itemId;
end

function splitItem(itemInfo)
	local items = {}
	for _, item in ipairs(common:split(itemInfo, ",")) do
		local _type, _id, _count = unpack(common:split(item, "_"));
		table.insert(items, {
            type    = tonumber(_type),			
			itemId	= tonumber(_id),
			count 	= tonumber(_count)
		});
	end
	return items;
end
--
function EquipManager:getEquipStepById(equipId)
	local stepLevel = self:getAttrById(equipId, "stepLevel")
	return tonumber(stepLevel)
end

function EquipManager:getProfessionById(equipId)
	local profs = self:getAttrById(equipId, "profession") or {};
	local prof = profs[1] or 0;
	return tonumber(prof) % 100;
end

---获取专属佣兵武器的id 非专属为0
function EquipManager:getMercenarySuitId(equipId)
	local mercenarySuitId = self:getAttrById(equipId, "mercenarySuitId")
	return mercenarySuitId or 0
end

--获取专属佣兵武器的佣兵id
function EquipManager:getMercenarySuitMercenaryIds(suitMercenaryId)
	local roleEquipDesc = ConfigManager.RoleEquipDescCfg()
	if roleEquipDesc[suitMercenaryId] and roleEquipDesc[suitMercenaryId]["mercenaryId"] then
		return roleEquipDesc[suitMercenaryId]["mercenaryId"]
	end
	return nil
end

--获取专属佣兵武器的佣兵id 第一个
function EquipManager:getMercenarySuitMercenaryId(suitMercenaryId)
	local roleEquipDesc = ConfigManager.RoleEquipDescCfg()
	if roleEquipDesc[suitMercenaryId] and roleEquipDesc[suitMercenaryId]["mercenaryId"] then
		return tonumber(roleEquipDesc[suitMercenaryId]["mercenaryId"][1])
	end
	return nil
end

--根据佣兵id 获取专属武器信息
function EquipManager:getMercenarySuitByMercenaryId(mercenaryId)
	local roleEquipDesc = ConfigManager.RoleEquipDescCfg()
	for i,suitInfo in pairs(roleEquipDesc) do
		for j, id in ipairs(suitInfo.mercenaryId) do
			if tonumber(id) == mercenaryId then
				return suitInfo
			end
		end
	end
	return nil
end

--根据佣兵id 获取所有专属武器信息
function EquipManager:getMercenaryAllSuitByMercenaryId(mercenaryId)
	local roleEquipDesc = ConfigManager.RoleEquipDescCfg()
    local roleEuipAll = {}
    local index = 0 
	for i,suitInfo in pairs(roleEquipDesc) do
		for j, id in ipairs(suitInfo.mercenaryId) do
			if tonumber(id) == mercenaryId then
                index  = index + 1 
                roleEuipAll[index] = suitInfo
			end
		end
	end
    if #roleEuipAll > 0 then 
      return roleEuipAll
    end
	return nil
end

--根據角色id  取得專屬武器(排除共通專武)
function EquipManager:getMercenaryOnlySuitByMercenaryId(mercenaryId)
	local roleEquipDesc = ConfigManager.RoleEquipDescCfg()
    local roleEuipAll = {}
    local index = 0 
	for i,suitInfo in pairs(roleEquipDesc) do
		for j, id in ipairs(suitInfo.mercenaryId) do
            if tonumber(id) == 0 then
                break
            end
			if tonumber(id) == mercenaryId then
                index  = index + 1 
                roleEuipAll[index] = suitInfo
                break
			end
		end
	end
    if #roleEuipAll > 0 then 
      return roleEuipAll
    end
	return nil
end

--获取专属佣兵武器的描述
function EquipManager:getMercenarySuitDescs(suitMercenaryId)
	local descs = {}
	local roleEquipDesc = ConfigManager.RoleEquipDescCfg()
	if roleEquipDesc[suitMercenaryId] then
		--三条属性
		for i=1,3 do
			if roleEquipDesc[suitMercenaryId]["desc"..i] and roleEquipDesc[suitMercenaryId]["desc"..i] ~= "0" then 
				descs["desc"..i] = roleEquipDesc[suitMercenaryId]["desc"..i]
			else
				return descs
			end
		end
	end

	return descs
end

function EquipManager:getBaptizeCost(equipId)
	local cost =  self:getAttrById(equipId, "washCoinCost");
	return tonumber(cost);
end

function EquipManager:getOccupationIconById(equipId)
	local professionId = self:getProfessionById(equipId);	
	return GameConfig.ProfessionIcon[professionId] or "";
end	

--装备能否洗炼
function EquipManager:canBeBaptized(equipId)
	return self:getBaptizeCost(equipId) > 0;
	--self:getLevelById(equipId) >= GameConfig.OpenLevel.Baptize;
end

--装备能否打孔或镶嵌宝石
function EquipManager:canBeEmbed(equipId)
	return self:getLevelById(equipId) >= GameConfig.OpenLevel.EmbedGem;
end

--根据星级获取神器属性
function EquipManager:getStarAttrByLevel(id, level, fmt)
	local baseVal = self:getGodlyAttrById(id, "baseAttr");
	local growVal = self:getGodlyAttrById(id, "growAttr");
	local enhanceVals = self:getGodlyAttrById(id, "enhanceAttrs");
	local val = enhanceVals[level]--tonumber(baseVal) + (tonumber(level) - 1) * tonumber(growVal);
	return self:getGodlyAttrString(id, val, fmt);
end
--根据星级获取神器之间差的属性
function EquipManager:getStarAttrByLevelGap(id, startlevel,endlevel ,fmt)
	local enhanceVals = self:getGodlyAttrById(id, "enhanceAttrs");
	local val1 = enhanceVals[startlevel]--tonumber(baseVal) + (tonumber(level) - 1) * tonumber(growVal);
	local val2 = enhanceVals[endlevel]
	return self:getStarandEndAttrByLevel(id, val1,val2, fmt);
end


--装备显示星星位置
function EquipManager:setStarPosition(starSprite, bVisible, posX, posY)
    if starSprite ~= nil then
    	local xDistance = VaribleManager:getInstance():getSetting("EquipStarXDistance")
	    xDistance = tonumber(xDistance) or GameConfig.EquipStarGap
	    if Golb_Platform_Info.is_gNetop_platform then
	    	local anchorY = starSprite:getAnchorPoint().y;
	    	starSprite:setAnchorPoint(ccp(0, anchorY))

	    	xDistance = 13
	    end
        NodeHelper:setNodeVisible(starSprite, bVisible)
	    starSprite:setPosition(posX+xDistance, posY)
	end
end

--获取神器全身强化加成属性
function EquipManager:getActiveValByLevel(id, level, fmt)
	local enhanceAttrs = self:getGodlyAttrById(id, "enhanceAttrs");
	local val = tonumber(enhanceAttrs[level] or 0);
	return self:getGodlyAttrString(id, val, fmt);
end	

--神器属性加成是否是数值(３种穿透等级是加成数据，其它是加成百分比）
function EquipManager:isGodlyAttrPureNum(id)
	local attrPureCfg = ConfigManager.getAttrPureCfg()
	return not (attrPureCfg[id] and attrPureCfg[id].attrType == 1)
end

function EquipManager:getGodlyAttrString(id, val, fmt)
	if val ~= 0 then
		if not self:isGodlyAttrPureNum(id)	then
			local fmt = fmt or "%.1f%%";	--multi % for gsub()
			val = string.format(fmt, val / 100);
		end
	end
	if IsFrenchLanguage() then
        val = ProcessFrancNum(val)
    end
	return val;
end

function EquipManager:getStarandEndAttrByLevel(id,val1,val2,fmt)
	local val = ""
	local tmpValue = tonumber(val2) - tonumber(val1)
	val = tostring(tmpValue)
	if tmpValue ~= 0  then
		if not self:isGodlyAttrPureNum(id)	then
			local fmt = fmt or "%.1f%%";	--multi % for gsub()
			val = string.format(fmt, (tmpValue ) / 100);
		end
	end
	if IsFrenchLanguage() then
		val = ProcessFrancNum(tmpValue)
	end
	return val;
end

--从equipStrength.txt根据强化等级获取装备主属性数值
function EquipManager:getAttrAddVAl(_id, _lv)
	local enhanceCfg = ConfigManager.getEquipEnhanceAttrCfg();
	local cfg = enhanceCfg[1--[[_id]]] or {};
	local val = cfg["mainAttr"][_lv];

	return tonumber(val or 0);
end

--从equipStrengthRatio.txt获取装备强化时各种相关数值所占权重
--用于装备强化所需强化精华的计算(见UserEquip:getItemNeedForEnhance)
function EquipManager:getWeightByIdAndType(_id, _type)
	local enhanceCfg = ConfigManager.getEquipEnhanceWeightCfg();
	local key = _id .. "_" .. _type;
	local cfg = enhanceCfg[key] or {};
	return cfg["weight"] or 0;
end

--从godlyLevelExp.txt获取神器升星所需经验
--@param isAttr2: 是否是升级第二条属性
function EquipManager:getExpNeedForLevelUp(level, isAttr2)
	local expCfg = ConfigManager.getGoldlyLevelExpCfg();
	local cfg = expCfg[level] or {};
	if isAttr2 then
		return cfg["exp2"] or 1;
	end
	return cfg["exp"] or 1;
end

--根据装备部位获取权重，用于吞噬、传承、融合等金币计算
function EquipManager:getWeightByPart(part)
	return GameConfig.EquipPartWeight[part] or 0;
end	

--获取打孔消耗
function EquipManager:getPunchConsume(equipId, pos)
	local pos = tonumber(pos) or 1;
	if pos == 1 then
	 	return {self:getAttrById(equipId, "punchConsume")};
	else
        --打孔消耗 改成只消耗钻石。
		--local consumes = {punchCfg[1].goldCost[pos-1], punchCfg[1].itemCost[pos-1]}
        local consumes = {punchCfg[1].goldCost[pos-1]}
		return consumes
	end
end

--装备等级是否满足装备条件
function EquipManager:isDressableWithLevel(equipId)
	local level = self:getLevelById(equipId);
	local gap = GameConfig.LevelLimit.EquipDress or 15;
	if tonumber(level) > tonumber((UserInfo.roleInfo.level or 1) + gap) then
		return false;
	end
	return true;
end

--装备职业是否满足装备条件
function EquipManager:isDressableWithProfession(equipId, professionId)
	local profs = self:getAttrById(equipId, "profession") or {};
	for _, prof in ipairs(profs) do
		local prof = tonumber(prof);
		if prof == 0 or prof == professionId then
			return true;
		end
	end
	return false;
end

--装备是否能够装备
function EquipManager:isDressable(equipId, professionId)
    --local dressableNFT = libPlatformManager:getPlatform():getIsGuest() == 0
	return self:isDressableWithLevel(equipId) and self:isDressableWithProfession(equipId, professionId)
end

--获取装备初始主属性
function EquipManager:getInitAttrInfo(equipId)
	local attrStr = self:getAttrById(equipId, "equipAttr") or ''
	local attrInfo = {}
	for _, subStr in ipairs(common:split(attrStr, ",")) do
		local attrId, attrVal, attrValMax = unpack(common:split(subStr, '_'));
		local attr = {}       
		attr["attrVal"] = tonumber(attrVal)
		attr["attrValMax"] = tonumber(attrValMax)
		attrInfo[tonumber(attrId)] = attr       
	end
	return attrInfo
end

--获取装备初始主属性改(強化裝備介面上顯示用, 因為有些屬性強化上顯示不需要)
function EquipManager:getInitAttrInfoNew(equipId)
	local attrStr = self:getAttrById(equipId, "equipAttr") or ''
	local attrInfo = {}
	for _, subStr in ipairs(common:split(attrStr, ",")) do
		local attrId, attrVal, attrValMax = unpack(common:split(subStr, '_'));
		local attr = {}
        
        if(GameUtil:checkEquipKeyNeed(attrId))
        then        
		    attr["attrVal"] = tonumber(attrVal)
		    attr["attrValMax"] = tonumber(attrValMax)
		    attrInfo[tonumber(attrId)] = attr
        end
	end
	return attrInfo
end

--获取装备初始主属性
function EquipManager:getInitAttr(equipId ,glue ,strength ,quality)
    local strength = strength or 0
    local quality = quality or 0
	local cfgStr = self:getAttrById(equipId, "equipAttr") or '';
	return self:getAttrLangStr(cfgStr , glue ,strength , quality);
end

--获取属性属于主、副、神器属性中的哪一类
function EquipManager:getAttrGrade(attrId)
	local attrId = tonumber(attrId);
	if attrId > 1000 then
		return Const_pb.GODLY_ATTR;
	elseif attrId > 100 then
		return Const_pb.SECONDARY_ATTR;
	else
		return Const_pb.PRIMARY_ATTR;
	end
end

--@param glue: defalut = "\n"
function EquipManager:getAttrLangStr(attrStr, glue ,strength ,quality)
	local glue = glue or " ";
	local strength = strength or 0
    local quality = quality or 0
	local attrTb = {};
	local equipStrength = ConfigManager.getEquipEnhanceAttrCfg()
    local radio = 0
    if quality > 0 and strength > 0 then
        radio = tonumber(equipStrength[--[[quality]]1].mainAttr[strength])
    end
	for _, subStr in ipairs(common:split(attrStr, ",")) do
		local attrId, attrVal, attrValMax = unpack(common:split(subStr, '_'));
		attrVal = tonumber(attrVal)
        attrValMax = tonumber(attrValMax)
		if attrVal > 0 then--and tonumber(attrId) ~= Const_pb.MAGDEF and 
           --tonumber(attrId) ~= Const_pb.MAGIC_attr and tonumber(attrId) ~= Const_pb.BUFF_MAGDEF_PENETRATE then
            local name = common:getLanguageString("@AttrName_" .. attrId);
            --if tonumber(attrId) == Const_pb.PHYDEF then
            --    name = common:getLanguageString("@Armor")
            --end
            --if tonumber(attrId) == Const_pb.ATTACK_attr then
            --    name = common:getLanguageString("@Damage")
            --end
            --if tonumber(attrId) == Const_pb.BUFF_PHYDEF_PENETRATE then
            --    name = common:getLanguageString("@AttrName_1007")
            --end
			
			local str = "";
			if self:getAttrGrade(attrId) == Const_pb.GODLY_ATTR and not self:isGodlyAttrPureNum(attrId) then
				str = string.format("%s +%.1f%%", name, attrVal / 100);
			else
				str = string.format("%s +%d", name, attrVal * ( 1 + radio/10000 ));
			end
            if attrValMax > attrVal then
                str = str .. "~" .. attrValMax * ( 1 + radio/10000 )
            end
			table.insert(attrTb, str);
		end
	end
	
	return table.concat(attrTb, glue);
end

--根据神器属性个数获取神器初始神器属性文本
function EquipManager:getGodlyAttr(id, count, glue)
	local count = count or 1;
	if count < 1 or count > 2 then return ""; end
	
	local glue = glue or "\n";
	
	local strTb = {};
	
	local part = self:getPartById(id);
	if count > 1 then
		local attrId = GameConfig.Part2GodlyAttr_1[part];
		local attrVal = self:getActiveValByLevel(attrId, 1, "%.1f%%");
		local name = common:getLanguageString("@AttrName_" .. attrId);
		table.insert(strTb, string.format("%s +%s", name, attrVal));
	end
	local attrId = GameConfig.Part2GodlyAttr_2[part];
	local attrVal = self:getActiveValByLevel(attrId, 1, "%.1f%%");
	local name = common:getLanguageString("@AttrName_" .. attrId);
	table.insert(strTb, string.format("%s +%s", name, attrVal));
	
	return table.concat(strTb, glue);
end

--根据神器属性个数获取神器特效ccbi，用于声望打造中特效显示（1个时一定是第二条）
function EquipManager:getGodlyAni(count)
	local aniKey = count > 1 and "Double" or "Second";
	return GameConfig.GodlyEquipAni[aniKey];
end

--从battleParameter.txt中获取加成属性的修正参数，用于“更多属性”页中属性计算
function EquipManager:getBattleAttrEffect(attrId, attrVal, level)
    if attrVal == 0 then return "0.0" end
    require("Battle.NewBattleUtil")
    require("Battle.NewBattleConst")
    local value = attrVal
    if attrId == Const_pb.CRITICAL then
        value = NewBattleConst.BASE_CRI * 100 + string.format("%.2f", NewBattleUtil:calRoundValue(100 * attrVal / (attrVal + NewBattleUtil:calRoundValue((1 + level / 3), 1) * (400 - level)), -2))
    elseif attrId == Const_pb.HIT then
        value = string.format("%.2f", NewBattleUtil:calRoundValue(100 * attrVal / (attrVal + NewBattleUtil:calRoundValue((1 + level / 3), 1) * (900 - level)), -2))
    elseif attrId == Const_pb.DODGE then
        value = string.format("%.2f", NewBattleUtil:calRoundValue(100 * attrVal / (attrVal + NewBattleUtil:calRoundValue((1 + level / 2), 1) * (700 - level)), -2))
    elseif attrId == Const_pb.PHYDEF then
        value = string.format("%.2f", NewBattleUtil:calRoundValue(100 * math.min(attrVal / (attrVal + NewBattleUtil:calRoundValue((1 + level / 3), 1) * (800 - level)), NewBattleConst.MAX_DEF_PER), -2))
    elseif attrId == Const_pb.MAGDEF then
        value = string.format("%.2f", NewBattleUtil:calRoundValue(100 * math.min(attrVal / (attrVal + NewBattleUtil:calRoundValue((1 + level / 3), 1) * (800 - level)), NewBattleConst.MAX_DEF_PER), -2))
    elseif attrId == Const_pb.RESILIENCE then
        value = string.format("%.2f", NewBattleUtil:calRoundValue(100 * attrVal / (attrVal + NewBattleUtil:calRoundValue((1 + level / 3), 1) * (700 - level)), -2))
    elseif attrId == Const_pb.BUFF_PHYDEF_PENETRATE or attrId == Const_pb.BUFF_MAGDEF_PENETRATE then
        value = string.format("%.2f", NewBattleUtil:calRoundValue(attrVal, -2))
    end
	return value
end

function EquipManager:getEquipDescBasicInfo(userEquip)
	local retStr = "";
	local suffix = "" or "_1";	--使用不现的html配置，主要是字体大小不同
	local glue = '<br/>';					--字体串拼接符
	
	local strTb = {};
	
    
	local equipId = userEquip.id;


     --套装名称
    local EquipManager = require("Equip.EquipManager") 
    local suitId =  EquipManager:getSuitIdById( equipId)
    if suitId > 0 then
        local suitCfg = ConfigManager.getSuitCfg()
        local suitName = common:fillHtmlStr("EquipSuitName", suitCfg[suitId].suitName , 0 , tostring( suitCfg[suitId].maxNum ))
        table.insert( strTb , suitName )
    end

	--职业限制信息(如果有)
	local professionId = EquipManager:getProfessionById(equipId);
	if professionId and professionId > 0 then
		local professionName = common:getLanguageString("@ProfessionName_" .. professionId);
		--table.insert(strTb, common:getLanguageString("@EquipCondition", professionName));
		table.insert(strTb, common:fillHtmlStr("EquipCondition", professionName));
	end

	local commonInfo = table.concat(strTb, glue);
	retStr = commonInfo;

	--通过margin设置不同的宽度
	local margin = GameConfig.Margin.EquipSelect
	return common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

function EquipManager:getEquipSpaceImg()
	local imgStr = ""
	local tempPic =  FreeTypeConfig[700].content

	local relaPath = "UI/Common/Image/Image_EquipInfo_Line.png"--GameConfig.ChatFace[tonumber(string.sub(f,string.find(f , "%d+")))]
	local picPath = CCFileUtils:sharedFileUtils():fullPathForFilename(relaPath) 
	imgStr = string.gsub(tempPic , "#v1#" , picPath)
	return imgStr
end

--获取装备属性信息(装备限制、评分、主属性、副属性)
--@Return: Html String
function EquipManager:getDesciptionWithEquipInfo(userEquip)
	local retStr = "";
	local suffix = "" or "_1";	--使用不现的html配置，主要是字体大小不同
	local glue = '<br/>';					--字体串拼接符
	
	local strTb = {};
	
    
	local equipId = userEquip.id;


     --套装名称
    --local EquipManager = require("Equip.EquipManager") 
    local suitId =  EquipManager:getSuitIdById( equipId)
    -- if suitId > 0 then
    --     local suitCfg = ConfigManager.getSuitCfg()
    --     local suitName = common:fillHtmlStr("EquipSuitName", suitCfg[suitId].suitName , 0 , tostring( suitCfg[suitId].maxNum ))
    --     table.insert( strTb , suitName )
    -- end

	--职业限制信息(如果有)
	-- local professionId = EquipManager:getProfessionById(equipId);
	-- if professionId and professionId > 0 then
	-- 	local professionName = common:getLanguageString("@ProfessionName_" .. professionId);
	-- 	--table.insert(strTb, common:getLanguageString("@EquipCondition", professionName));
	-- 	table.insert(strTb, common:fillHtmlStr("EquipCondition", professionName));
	-- end

	--从装备数据中分类出属性数据（主、副）	
	local quality = EquipManager:getQualityById(equipId);
	local attrTb = {
		[Const_pb.PRIMARY_ATTR] 	= {},
		[Const_pb.SECONDARY_ATTR] 	= {},
	};

	----伤害显示特殊处理
    local dmg = {};
    local ismin = 0 ---0 最小 1最大  2最小最大

    --并增加评分
	local grade = nil;
	local gradeStr = ""
    local MainAttr = ConfigManager.parseItemWithComma(userEquip.equipAttr)	
		local attrStr = nil;
		--针对伤害特殊处理
		local doCheck = false;
		
		gradeStr = common:fillHtmlStr("EquipGrade", userEquip.score) 
		if #MainAttr == 2 then
			dmg.min = MainAttr[1].count;
            dmg.max = MainAttr[2].count;
            attrStr = common:getLanguageString("@EquipDMGVal", dmg.min, dmg.max);
            -- grade = dmg.min + dmg.max + userEquip.additionalAttr
            -- gradeStr = common:fillHtmlStr("EquipGrade", grade)            
		else
			local name = common:getAttrName(MainAttr[1].type);	
			attrStr = common:getLanguageString("@EquipAttrVal", name, MainAttr[1].count);
            -- local MainScore = nil
            -- if MainAttr[1].type == 101 or MainAttr[1].type == 102 then
            --    MainScore = math.ceil( MainAttr[1].count / 10)
            -- else 
            --    MainScore = MainAttr[1].count
            -- end
            -- grade = MainScore + userEquip.additionalAttr
            -- gradeStr = common:fillHtmlStr("EquipGrade", grade)
            --table.insert(strTb, common:fillHtmlStr("EquipGrade", grade));
		end
            
		if attrStr ~= nil then
			key = "MainAttr"
			attrTb[1][1] = common:fillHtmlStr(key, attrStr);
		end
	
		
    for i = 1 , 4 do
      local name = common:getAttrName(i);	
      key = "SecondaryAttr_" .. quality
      attrStr = common:getLanguageString("@EquipAttrVal", name, math.ceil (userEquip.additionalAttr / 4) );
      attrTb[2][i] = common:fillHtmlStr(key, attrStr);
    end

    ---添加图片间隔
	local imgStr = UserEquipManager:getEquipSpaceImg()
	table.insert(strTb, imgStr);
	table.insert(strTb, common:fill(FreeTypeConfig[122].content, common:getLanguageString("@EquipStr1")));
    --组合htmlString
	for attrGrade, subAttrTb in ipairs(attrTb) do
		if attrGrade == Const_pb.PRIMARY_ATTR then
			local str = common:table_implode(subAttrTb, glue);
			table.insert(strTb, str);
		end
	end


	---添加图片间隔
	local imgStr = UserEquipManager:getEquipSpaceImg()
	table.insert(strTb, imgStr);
	table.insert(strTb, common:fill(FreeTypeConfig[122].content, common:getLanguageString("@EquipStr2")));
	--组合htmlString
	for attrGrade, subAttrTb in ipairs(attrTb) do
		if attrGrade == Const_pb.SECONDARY_ATTR then
			local str = common:table_implode(subAttrTb, glue);
			table.insert(strTb, str);
		end
	end
	
	--是否是佣兵专属套装
	local mercenarySuitId = EquipManager:getMercenarySuitId(equipId);
	if mercenarySuitId and mercenarySuitId > 0 then
		--local GodlyAttrCfg = ConfigManager.getGodlyAttrCfg();
		---添加图片间隔
		local imgStr = UserEquipManager:getEquipSpaceImg()
		table.insert(strTb, imgStr);
        local _roleId = EquipManager:getMercenarySuitMercenaryId(mercenarySuitId)
        if tonumber(_roleId) < 10 and tonumber(_roleId) > 0 then
            local roleConfig = ConfigManager.getRoleCfg()
            _roleId = roleConfig[_roleId].profession * 10 + 1  
        end
        if tonumber(_roleId) == 0 then
            table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@MasterEquipStr1")))
        else
            table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@Role_" .. _roleId) .. common:getLanguageString("@EquipStr6")));
        end

		local descs = EquipManager:getMercenarySuitDescs(mercenarySuitId)
		for k,v in pairs(descs) do
			if roleInfo and EquipManager:getMercenarySuitMercenaryId(mercenarySuitId) == roleInfo.itemId then 
				table.insert(strTb, common:fillHtmlStr("GreenFontColor", common:getLanguageString(v)));
			else
				table.insert(strTb, common:fillHtmlStr("GrayFontColor", common:getLanguageString(v)));
			end
		end
	end
	
    --组合套装属性
    if suitId > 0 then
    	---添加图片间隔
		local imgStr = UserEquipManager:getEquipSpaceImg()
		table.insert(strTb, imgStr);

        table.insert(strTb ,common:fillHtmlStr("EquipSuitAttrs") )
        local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
        local suitCfg = ConfigManager.getSuitCfg()
        for i = 1,#suitCfg[suitId].conditions,1 do
            local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
            local suitAttrId = suitCfg[suitId].attrIds[i]        
                table.insert( strTb , common:fillHtmlStr("EquipSuitAttrsF" , suitCfg[suitId].conditions[i],suitAttrCfg[suitAttrId].describe ))
        end
    end 
    
	local commonInfo = table.concat(strTb, glue);
	retStr = commonInfo;

	
	--通过margin设置不同的宽度
	local margin =  GameConfig.Margin.EquipInfo or GameConfig.Margin.EquipSelect;
	return common:fillHtmlStr("EquipInfoWrap",margin, retStr), gradeStr
end

function EquipManager:getSuitDisplayDesciptionWithEquipInfo(userEquip)
	local retStr = "";
	local suffix = "" or "_1";	--使用不现的html配置，主要是字体大小不同
	local glue = '<br/>';					--字体串拼接符
	
	local strTb = {};
	
    
	local equipId = userEquip.id;


     --套装名称
    local EquipManager = require("Equip.EquipManager") 
    local suitId =  EquipManager:getSuitIdById( equipId)
    if suitId > 0 then
        local suitCfg = ConfigManager.getSuitCfg()
        local suitName = common:fillHtmlStr("EquipSuitName", suitCfg[suitId].suitName , 0 , tostring( suitCfg[suitId].maxNum ))
        table.insert( strTb , suitName )
    end

	--职业限制信息(如果有)
	local professionId = EquipManager:getProfessionById(equipId);
	if professionId and professionId > 0 then
		local professionName = common:getLanguageString("@ProfessionName_" .. professionId);
		--table.insert(strTb, common:getLanguageString("@EquipCondition", professionName));
		table.insert(strTb, common:fillHtmlStr("EquipCondition", professionName));
	end
	

	--从装备数据中分类出属性数据（主、副）	
	local quality = EquipManager:getQualityById(equipId);
	local attrTb = {
		[Const_pb.PRIMARY_ATTR] 	= {},
		[Const_pb.SECONDARY_ATTR] 	= {},
	};
	local dmg = {};

    --并增加评分
	local grade = nil;
	local gradeStr = ""
    local MainAttr = ConfigManager.parseItemWithComma(userEquip.equipAttr)	
		local attrStr = nil;
		--针对伤害特殊处理
		local doCheck = false;
		if #MainAttr == 2 then
			dmg.min = MainAttr[1].count;
            dmg.max = MainAttr[2].count;
			doCheck = true;
			grade = dmg.min + dmg.max + userEquip.additionalAttr
			gradeStr = common:fillHtmlStr("EquipGrade", grade)       
		else
			local name = common:getAttrName(MainAttr[1].type);	
			attrStr = common:getLanguageString("@EquipAttrVal", name, MainAttr[1].count);
            local MainScore = nil
            if MainAttr[1].type == 101 or MainAttr[1].type == 102 then
               MainScore = math.ceil( MainAttr[1].count / 10)
            else 
               MainScore = MainAttr[1].count
            end
            grade = MainScore + userEquip.additionalAttr
			gradeStr = common:fillHtmlStr("EquipGrade", grade)
            --table.insert(strTb, common:fillHtmlStr("EquipGrade", grade));
		end
		
		if doCheck and dmg.min and dmg.max then
			attrStr = common:getLanguageString("@EquipDMGVal", dmg.min, dmg.max);
            grade = dmg.min + dmg.max + userEquip.additionalAttr
           
            dmg = {};
		end
		if attrStr ~= nil then
			key = "MainAttr"
			attrTb[1][1] = common:fillHtmlStr(key, attrStr);
		end
		
    for i = 1 , 4 do
      local name = common:getAttrName(i);	
      key = "SecondaryAttr_" .. quality
      attrStr = common:getLanguageString("@EquipAttrVal", name, math.ceil (userEquip.additionalAttr / 4) );
      attrTb[2][i] = common:fillHtmlStr(key, attrStr);
    end



	--组合htmlString
	for attrGrade, subAttrTb in ipairs(attrTb) do
		local str = common:table_implode(subAttrTb, glue);
		table.insert(strTb, str);
	end
	
    --组合套装属性
    
    if suitId > 0 then
        table.insert(strTb ,common:fillHtmlStr("EquipSuitAttrs") )
        local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
        local suitCfg = ConfigManager.getSuitCfg()
        for i = 1,#suitCfg[suitId].conditions,1 do
            local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
            local suitAttrId = suitCfg[suitId].attrIds[i]        
                table.insert( strTb , common:fillHtmlStr("EquipSuitAttrsF" , suitCfg[suitId].conditions[i],suitAttrCfg[suitAttrId].describe ))
        end
    end 
    
	local commonInfo = table.concat(strTb, glue);
	retStr = commonInfo;

	
	--通过margin设置不同的宽度
	local margin =  GameConfig.Margin.EquipInfo or GameConfig.Margin.EquipSelect;
	return common:fillHtmlStr("EquipInfoWrap",margin, retStr),gradeStr
end
--´Óequip.txt»ñÈ¡ÁÔÈËÌ××°
function EquipManager:getHunterSuit(suitQuality,level)
	return EquipManager:getSuit(2, suitQuality,level)
end
--´Óequip.txt»ñÈ¡·¨Ê¦Ì××°
function EquipManager:getMasterSuit(suitQuality,level)
	return EquipManager:getSuit(3, suitQuality,level)
end

--´Óequip.txt»ñÈ¡Õ½Ê¿Ì××°
function EquipManager:getWarriorSuit(suitQuality,level)
	return EquipManager:getSuit(1, suitQuality,level)
end

local suitHandBookCfg = ConfigManager.getSuitHandBookCfg()
function EquipManager:getSuit(occupationId, suitQuality,level)
	local suit = {}
	local isHasMercenaryEquip = false
	local mercenarySuit = {}
	for k,v in pairs(suitHandBookCfg) do
		if v.suitQuality == suitQuality and v.level == level then 
			if tonumber(v.profession) == occupationId and v.isMercenaryEquip == 0 then
				suit[#suit+1] = v
			end
			---返回佣兵专属装备 跟职业没关系
			if v.isMercenaryEquip == 1 then
				isHasMercenaryEquip = true
				mercenarySuit[#mercenarySuit+1] = v
			end
		end
	end

	return suit, isHasMercenaryEquip, mercenarySuit
end

--------------------------------------------------------------------------------
return EquipManager;