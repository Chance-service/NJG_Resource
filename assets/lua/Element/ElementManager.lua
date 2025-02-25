--region ElementManager.lua
--元素神符管理类
local ElementConfig = require("Element.ElementConfig")
local HP_pb = require("HP_pb")
local ElementOpr = require("ElementOpr_pb")
local PBHelper = require("PBHelper")
local Const_pb = require("Const_pb")
local BaseDataHelper = require("BaseDataHelper")
local ElementManager = BaseDataHelper:new(ElementConfig) 
local UserInfo = require("PlayerInfo.UserInfo");
local UserItemManager = require("Item.UserItemManager");
ElementManager.sort = true;
ElementManager.showType = {
    defalut = 1,
    package = 2,
    other = 3
}
ElementManager.UserElementMap = {}
ElementManager.selectedEle = {}
ElementManager.selectedEleId = {}
ElementManager.OccupationLimit = false;
ElementManager.index =0 --元素符文的卡槽编号
ElementManager.PackageIsFull = false
ElementManager.elementCategory = {
    Dress = {},
    Package = {}
}
function ElementManager:getAttrById(eleId,attrName)
    local ele = self:getElementInfoById(eleId);
    if ele then 
        return ele[attrName];
    end
end
function ElementManager:getLevelById(eleId)
    local level = self:getAttrById(eleId,"level");
    return tonumber(level);
end

function ElementManager:getQualityById(eleId)
    return self:getAttrById(eleId,"quality");
end

function ElementManager:getBasicAttrsById(eleId)
    return self:getAttrById(eleId,"basicAttrs");
end

function ElementManager:getExtraAttrsById(eleId)
    return self:getAttrById(eleId,"extraAttrs");
end

function ElementManager:getExpById(eleId)
    return self:getAttrById(eleId,"exp");
end

function ElementManager:getNameById(eleId)
    local ele = self:getElementInfoById(eleId)
    local prefixName = "";
    local postfixName = "";
    prefixName = self:getPostfixName(ele.basicAttrs.attribute,"name");
    postfixName = self:getPrefixName(ele.itemId)
    
    local strFinalName = "";
    --FR RU TH ES PT这五个语种 都是名词在前，形容词在后
    if IsSpanishLanguage() or IsRussianLanguage() or IsThaiLanguage() or IsFrenchLanguage() or IsPortugueseLanguage() then
        strFinalName = postfixName..prefixName;
    else
        strFinalName = prefixName..postfixName;
    end
    return strFinalName;
end
function ElementManager:getRoleById(eleId)
    local ele = self:getElementInfoById(eleId)
    postfixRole = self:getPrefixRole(ele.itemId)
    return postfixRole;
end

function ElementManager:getIconById(eleId)
    local ele = self:getElementInfoById(eleId)
    local  result = ""
    if self:getRoleById(eleId) == 0 then
        result = self:getEleNameAndIcon(ele.basicAttrs.attribute,"icon");
    else
        result = ElementConfig.ElementCfg[ele.itemId].icon or ""
    end
    return result;
end
function ElementManager:getEleByIndex(index)
    UserInfo.sync()
    local elements = UserInfo.roleInfo.elements;
    for _,element in ipairs(elements) do
        if element  then
            if element.index ==index then
                return element;
            end
        end
    end
    return nil;
end

function ElementManager:getUserElements()
    return ElementManager.UserElementMap;
end
-- 获取元素信息
function ElementManager:getElementInfoById(id)
    return ElementManager.UserElementMap[id] or nil 
end
-- 获取元素基本属性个数
function ElementManager:getExtraAttrsCount(id)
    if ElementManager.UserElementMap[id] ~= nil then 
        return #(ElementManager.UserElementMap[id].basicAttrs.attribute)
    end
    return nil
end
-- 获取元素附加属性数量
function ElementManager:getExtraAttrsCount(id)
    if ElementManager.UserElementMap[id] ~= nil then 
        return #(ElementManager.UserElementMap[id].extraAttrs)
    end
    return nil
end

-- 获取元素品质
function ElementManager:getQualityById(id)
    if ElementManager.UserElementMap[id] ~= nil then
        return ElementManager.UserElementMap[id].quality
    end
    return 0
end

-- 获取元素评分
function ElementManager:getScoreById(id)
    if ElementManager.UserElementMap[id] ~= nil then
        return ElementManager.UserElementMap[id].score
    end
    return 0
end
--通过id获取role身上属性
function ElementManager:getRoleAttrById(roleinfo,attrId)
    if roleinfo and attrId then
        return PBHelper:getAttrById(roleinfo.attribute.attribute, attrId);
    end
end

-- 获取总伤害
function ElementManager:getTotalDamage(roleinfo)
    local num = ElementManager:getRoleAttrById(roleinfo,Const_pb.ICE_ATTACK) + ElementManager:getRoleAttrById(roleinfo,Const_pb.FIRE_ATTACK) + ElementManager:getRoleAttrById(roleinfo,Const_pb.THUNDER_ATTACK)
    return num 
end
-- 获取总抗性
function ElementManager:getTotalDefense(roleinfo)
    local num = ElementManager:getRoleAttrById(roleinfo,Const_pb.ICE_DEFENCE) + ElementManager:getRoleAttrById(roleinfo,Const_pb.FIRE_DEFENCE) + ElementManager:getRoleAttrById(roleinfo,Const_pb.THUNDER_DENFENCE)
    return num
end

-----元素神符评分
function ElementManager:Score(eleId,level)
    local ele = self:getElementInfoById(eleId);
    if ele ==nil then return 0 end;
    local levelInfo =nil;
    local basicAttrs = ele.basicAttrs.attribute;
    local extraAttrs = ele.extraAttrs.attribute;
    local iceAttack,fireAttack,thunderAttack = 0,0,0;
    local iceDefense,fireDefense,thunderDefense = 0,0,0;
    local iceAttackRadio,fireAttackRadio,thunderAttackRadio = 0,0,0;
    local iceDefenseRadio,fireDefenseRadio,thunderDefenseRadio = 0,0,0;
    local strenght,agility,intellect,stamina = 0,0,0,0;
    --获取基础属性的value
    for _,attr in ipairs(basicAttrs) do 
        if attr.attrId == Const_pb.ICE_ATTACK then
            iceAttack = attr.attrValue
        elseif attr.attrId == Const_pb.FIRE_ATTACK then
            fireAttack = attr.attrValue
        elseif attr.attrId == Const_pb.THUNDER_ATTACK then
            thunderAttack = attr.attrValue
        elseif attr.attrId == Const_pb.ICE_DEFENCE then
            iceDefense = attr.attrValue
        elseif attr.attrId == Const_pb.FIRE_DEFENCE then
            fireDefense = attr.attrValue
        elseif attr.attrId == Const_pb.THUNDER_DENFENCE then
            thunderDefense = attr.attrValue
        end
    end
    --获取附加属性的value
    for _,attr in ipairs(extraAttrs) do 
        if attr.attrId == Const_pb.ICE_ATTACK_RATIO then
            iceAttackRadio = attr.attrValue
        elseif attr.attrId == Const_pb.ICE_DEFENCE_RATIO then
            iceDefenseRadio = attr.attrValue
        elseif attr.attrId == Const_pb.FIRE_ATTACK_RATIO then
            fireAttackRadio = attr.attrValue
        elseif attr.attrId == Const_pb.FIRE_DEFENCE_RATIO then
            fireDefenseRadio = attr.attrValue
        elseif attr.attrId == Const_pb.THUNDER_ATTACK_RATIO then
            thunderAttackRadio = attr.attrValue
        elseif attr.attrId == Const_pb.THUNDER_DENFENCE_RATIO then
            thunderDefenseRadio = attr.attrValue
        elseif attr.attrId == Const_pb.STRENGHT then
            strenght = attr.attrValue
        elseif attr.attrId == Const_pb.AGILITY then
            agility = attr.attrValue
        elseif attr.attrId == Const_pb.INTELLECT then
            intellect = attr.attrValue
        elseif attr.attrId == Const_pb.STAMINA then
            stamina = attr.attrValue
        end
    end
    if level~=nil then 
        levelInfo = self:getLevelInfoByLv(level)
    else 
        levelInfo = self:getLevelInfoByLv(ele.level)
    end
    
    local attack = iceAttack*levelInfo.iceAttack+fireAttack*levelInfo.fireAttack+thunderAttack*levelInfo.thunderAttack;
    local defense = (iceDefense*levelInfo.iceDefense+fireDefense*levelInfo.fireDefense+thunderDefense*levelInfo.thunderDefense)*0.75;
    local attrs = strenght*levelInfo.strenght+agility*levelInfo.agility+intellect*levelInfo.intellect+stamina*levelInfo.stamina;
    local attackRadio = 0.01*(iceAttackRadio*levelInfo.iceAttackRadio+fireAttackRadio*levelInfo.fireAttackRadio+thunderAttackRadio*levelInfo.thunderAttackRadio);
    local defenseRadio = 0.01*(iceDefenseRadio*levelInfo.iceDefenseRadio+fireDefenseRadio*levelInfo.fireDefenseRadio+thunderDefenseRadio*levelInfo.thunderDefenseRadio)*0.8;

    local score = (attack+defense+attrs)*(1+attackRadio*0.06+defenseRadio*0.06);
    return math.floor(score);
end
---通过等级获取等级的属性信息
function ElementManager:getLevelInfoByLv(level)
    local cfg = ElementConfig.LevelAttrRatioCfg;
    if level then
        return  cfg[level];
    end
    return nil;
end
--通过属性计算元素的名字和icon
function ElementManager:getPrefixName(itemId)
    if itemId then
        return ElementConfig.ElementCfg[itemId].name
    end
end
function ElementManager:getPrefixRole(itemId)
    if itemId then
        return ElementConfig.ElementCfg[itemId].role
    end
end
function ElementManager:getPostfixName(attributes,attrName)
    return ElementManager:getEleNameAndIcon(attributes,attrName);
end
function ElementManager:getEleNameAndIcon(attributes,attrName)
    
    local basicAttrNum = #attributes;
    local result = 0;
    for i = 1,basicAttrNum do 
        if attributes[i].attrId == Const_pb.ICE_ATTACK then
            result = result + math.ldexp(1,5)
        end
        if attributes[i].attrId == Const_pb.FIRE_ATTACK then
            result = result + math.ldexp(1,4)
        end
        if attributes[i].attrId == Const_pb.THUNDER_ATTACK then
            result = result + math.ldexp(1,3)
        end
        if attributes[i].attrId == Const_pb.ICE_DEFENCE then
            result = result + math.ldexp(1,2)
        end
        if attributes[i].attrId == Const_pb.FIRE_DEFENCE then
            result = result + math.ldexp(1,1)
        end
        if attributes[i].attrId == Const_pb.THUNDER_DENFENCE then
            result = result + math.ldexp(1,0)
        end
    end
    if result == 0 then
        result =1
    end
    local info = ElementConfig.ElementsCfg[result]
    return info[attrName];
end
--通过attrid获取对应attr
function ElementManager:getAttrNameByAttrId(id)
    if id then
        return ElementConfig.AttrName[id]
    end
    return nil;
end
---元素神符提供的吞噬经验
function ElementManager:supplySwallowExp(eleId)
    local ele = self:getElementInfoById(eleId)
    local elementLevelCfg = ElementConfig.ElementLevelCfg;
    local elementLevelRadioCfg = ElementConfig.ElementLevelRatioCfg;
    if ele then
        local levelInfo = elementLevelCfg[ele.level];
        local levelRadioInfo = elementLevelRadioCfg[ele.quality];
        return  levelInfo.swallowExp * levelRadioInfo.multiple
    end
end
---元素神符提供的吞噬金币
function ElementManager:supplySwallowGold(eleId)
    local ele = self:getElementInfoById(eleId)
    local elementLevelCfg = ElementConfig.ElementLevelCfg;
    local elementLevelRadioCfg = ElementConfig.ElementLevelRatioCfg;
    if ele then
        local levelInfo = elementLevelCfg[ele.level];
        local levelRadioInfo = elementLevelRadioCfg[ele.quality];
        return  levelInfo.swallowGold* levelRadioInfo.multiple
    end
end
---多个元素神符提供的吞噬经验
function ElementManager:supplySwallowExps(eles)
    if eles ~=nil then
        local exp= 0;
        for i=1,#eles  do 
            exp=exp+self:supplySwallowExp(eles[i].id)
        end
        return exp;
    end
end
function ElementManager:supplySwallowGolds(eles)
    if eles ~=nil then
        local goldNum = 0;
        for i=1,#eles  do 
            goldNum=goldNum+self:supplySwallowGold(eles[i].id)
        end
        return goldNum;
    end
    return nil
end
--通过经验计算获得element的新等级信息
function ElementManager:exExp2newLevel(eleId,exp)
    local cfg = ElementConfig.ElementLevelCfg
    local ele = self:getElementInfoById(eleId)
    local nextexp = exp+ele.exp;
    if eleId ~= nil and exp ~= nil then
        for i = ele.level,#cfg do
            if cfg[i].upgradeExp >nextexp then
                return i,nextexp
            else
                nextexp = nextexp-cfg[i].upgradeExp;
            end
        end
    end
end

-----进阶材料是否充足
function ElementManager:hasEnoughEles(eleId)
    local cfg = ElementConfig.ElementAscendCfg
    local ele = self:getElementInfoById(eleId)
    local items = UserItemManager:getUserItemIds()
    local flag =false;
    if ele then
        local materials = cfg[ele.quality].consume;
        for _,material in ipairs(materials) do
            local item = UserItemManager:getUserItemByItemId(material.itemId);
            if item ~=nil then 
                if item.count>=material.count then
                    flag = true;     
                else 
                    flag = false;
                end

            end
        end
    end
    
    return flag;
end

---设置选中的元素
function ElementManager:setSelectedElement(eleId,ind)
    ElementManager.selectedEle = nil;
    ElementManager.selectedEleId = nil;
    if eleId then
        ElementManager.selectedEleId = eleId
        ElementManager.selectedEle = self:getElementInfoById(eleId)
    end
    if ind then
        ElementManager.index = ind;
    end
end
function ElementManager:getSelectedElement()
    return self:getElementInfoById(ElementManager.selectedEleId)
end
---职业专属元素
function ElementManager:getProfLimitElements(prof)
    
    local elementMap = {};
    for _,UserElement in pairs(ElementManager.UserElementMap) do
        if not self:isDressOnPlayer(UserElement.id) then
            if UserElement.profLimit ==prof then
                table.insert(elementMap,UserElement);
            end
        end
    end
    table.sort(elementMap,function(ele1,ele2) 
        if not ele1 then return false end
		if not ele2 then return true end
        if ele1.quality == ele2.quality then 
            local score1 = ElementManager:Score(ele1.id)
            local score2 = ElementManager:Score(ele2.id)
            return score1>score2
        end
        return ele1.quality > ele2.quality
    end)
    return elementMap
end

--非装备在身的元素
function ElementManager:getUnDressAndDressElementsMap()
    
    local unDressElementsMap = {};
    
    for _,UserElement in pairs(ElementManager.UserElementMap) do
        if not self:isDressOnPlayer(UserElement.id)  then
            table.insert(unDressElementsMap,UserElement)
        end
    end

    return unDressElementsMap
end
---把当前选中的元素从map中剔除
function ElementManager:removeSelectedEle(tableMap)
    for i=1,#tableMap  do 
        local ele = tableMap[i]
        if ElementManager.selectedEle~=nil then
            if ele.id==ElementManager.selectedEle.id then
                index = i;
            end
        end
    end
    if index then
        table.remove(tableMap,index)
    end
    return tableMap
end
---判断神器等级不能高于玩家等级
function ElementManager:isEleLvLowPlayerLv(eleId)
    UserInfo.sync()
    local ele
    if eleId then
        ele = self:getElementInfoById(eleId)
    end
    if UserInfo.roleInfo.level <=ele.id then
        return false;
    else
        return true;
    end
end
---------------------- 排序方法 ------------------------
function ElementManager:sortForFilter(ele1,ele2)
    if ele1 == nil then return true end
    if ele2 == nil then return false end

    if #ele1.extraAttrs.attribute ~= #ele2.extraAttrs.attribute then
        return #ele1.extraAttrs.attribute < #ele2.extraAttrs.attribute
    else
        if ele1.quality ~= ele2.quality then
            return ele1.quality < ele2.quality 
        else
            local score1 = ElementManager:Score(ele1.id)
            local score2 = ElementManager:Score(ele2.id)
            return score1 < score2 
        end
    end
end
function ElementManager:setSortOrder(order)
    ElementManager.sort = order;
end
------通过品质，评分排序
function ElementManager.sortByQualityScore(ele1,ele2)
    local sortstyle = true;
    if ElementManager.sort~=nil then
        sortstyle = ElementManager.sort;
    end
    if ele1 == nil then return sortstyle end
    if ele2 == nil then return not sortstyle end
    if ele1.quality ~= ele2.quality then
        if ele1.quality < ele2.quality  then
            return sortstyle
        else
            return not sortstyle
        end
    else
        local score1 = ElementManager:Score(ele1.id)
        local score2 = ElementManager:Score(ele2.id)
        if score1 == score2 then
            return false
        else
            if score1 < score2 then
                return sortstyle
            else
                return not sortstyle
            end
        end
    end
    
end
------通过附加属性，品质，评分排序
function ElementManager.sortByExtraAttrsQualityScore(ele1,ele2)
    local sortstyle = true;
    if ElementManager.sort~=nil then
        sortstyle = ElementManager.sort;
    end
    if ele1 == nil then return sortstyle end
    if ele2 == nil then return not sortstyle end
    local extraAttrs1 = ele1.extraAttrs.attribute
    local extraAttrs2 = ele2.extraAttrs.attribute
    if #extraAttrs1 ~= #extraAttrs2 then
        if #extraAttrs1 < #extraAttrs2 then
            return sortstyle
        else
            return not sortstyle
        end
    else
        if ele1.quality ~= ele2.quality then
            if ele1.quality < ele2.quality  then
                return sortstyle
            else
                return not sortstyle
            end
        else
            local score1 = ElementManager:Score(ele1.id)
            local score2 = ElementManager:Score(ele2.id)
            if score1 == score2 then
                return false
            else
                if score1 < score2 then
                    return sortstyle
                else
                    return not sortstyle
                end
            end
        end
    end
end
---是否穿戴在主角身上
function ElementManager:isDressOnPlayer(eleid)
    UserInfo.sync()
    local flag = false;
    local userEquioEles = UserInfo.roleInfo.elements;
    for _ ,euipEle in pairs(userEquioEles) do
        if  euipEle.elementId == eleid then
            flag = true;
        end

    end
    return flag;
end
-----------删除元素

function ElementManager:deleteElement(id)
     ElementManager.UserElementMap[id] = nil ;
     if id ~=nil then
        table.remove(ElementManager.UserElementMap,id)
     end
     
end
-------------同步服务器推送过来的元素神符信息-----------
function ElementManager:syncEleInfoFromMsg(pbMsg)
    
    local Element_pb = require("Element_pb");
	local syncInfo = Element_pb.HPElementInfoSync();
	syncInfo:ParseFromString(pbMsg);
	
	self:syncEleInfos(syncInfo.elements);

end

function ElementManager:syncEleInfos(elements)
    for _, element in ipairs(elements) do
        if element and element.id then
            ElementManager.UserElementMap[element.id] = element;
        end
    end
end

---------------------------------元素神符操作---------------------------
--穿戴(铭刻),脱下 
function ElementManager:Dress(eleId,index)
    if eleId ==nil then
        eleId = 0;
    end
    if index ==nil then
        index =0;
    end
    local msg = ElementOpr.HPElementDress();
    msg.elementId = eleId;
    msg.index = index;
    common:sendPacket(HP_pb.ELEMENT_DRESS_C,msg);
end
--重铸
function ElementManager:Recast(eleId,attrId,type)
    if eleId ~=nil and attrId ~=nil and type ~=nil then
    
        local msg = ElementOpr.HPElementRecast();
        msg.elementId = eleId;
        msg.attrId = attrId;
        msg.type = type;
        common:sendPacket(HP_pb.ELEMENT_RECAST_C,msg);
        --MessageBoxPage:Msg_Box(common:getLanguageString('@RewardItem2'))

    end
end
------确认重铸
function ElementManager:RecastConfirm(eleId,index,type)
    if eleId ~=nil and index ~=nil then
    
        local msg = ElementOpr.HPElementRecastConfirm();
        msg.elementId = eleId;
        msg.index = index;
		msg.type = type
        common:sendPacket(HP_pb.ELEMENT_RECAST_CONFIRM_C,msg);

    end
end
--升级
function ElementManager:Upgrader(eleId,swallowEles)
    local  msg = ElementOpr.HPElementLevelUp();
    msg.elementId=eleId;
    for _,swallowEle in pairs(swallowEles) do
        msg.swallowEleIds:append(swallowEle.id);
    end
    common:sendPacket(HP_pb.ELEMENT_LVL_UP_C,msg)
end
--进阶
function ElementManager:Advanced(eleId)
    
    if eleId then
        local msg = ElementOpr.HPElementAdvanced();
        msg.elementId = eleId;
        common:sendPacket(HP_pb.ELEMENT_ADVANCE_C,msg);
    end
end
--分解
--自动赛选
function sortForMeltById(id1,id2)
    local ele1 = ElementManager.UserElementMap[id1]
    local ele2 = ElementManager.UserElementMap[id2]
    if ele1==nil then 
        return false
    end
    if ele2==nil then
        return true
    end
    if ele1.quality == ele2.quality then 
        local score1 = ElementManager:Score(ele1.id)
        local score2 = ElementManager:Score(ele2.id)
        return score1<score2
    end
    return ele1.quality < ele2.quality
end


function ElementManager:getElementIdsForSmelt()
	local ids = {};
	for _, ele in pairs(ElementManager.UserElementMap) do
		if not self:isDressOnPlayer(ele.id) then
			table.insert(ids, ele.id);
		end
	end
	table.sort(ids, sortForMeltById);
	return ids;
end

function ElementManager:Decompose(eleIds)
    if eleIds then
        local msg = ElementOpr.HPElementDecompose();
        for _, id in pairs(eleIds) do
            if id ~= nil then
		        msg.elementIds:append(id);
            end
        end
        common:sendPacket(HP_pb.ELEMENT_DECOMPOSE_C, msg)
	end
end

-- 购买背包
function ElementManager:expandPackage()
    common:sendEmptyPacket(HP_pb.ELEMENT_BAG_EXTEND_C,false)
end

-- 判断背包是否满
function ElementManager:checkPackage(container)
    --UserInfo.syncRoleInfo()
    --local bagSize = UserInfo.stateInfo.elementBagSize or 40;
    --ElementManager.PackageIsFull = common:table_count(ElementManager:getUnDressAndDressElementsMap()) >= bagSize
    ---- todo 红点逻辑
    --NodeHelper:setNodesVisible(container, {mElementPackFullPointNode = ElementManager.PackageIsFull})
end

---------------收包---------------------------
function ElementManager:onReceivePacket(container,page)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();

    if opcode == HP_pb.ELEMENT_ADVANCE_S then
        local msg = ElementOpr.HPElementAdvancedRet()
        msg:ParseFromString(msgBuff);
        page:refreshPage(container)
        PageManager.refreshPage("ElementInfoPage")
        PageManager.refreshPage("EquipmentPage")
        PageManager.refreshPage("ElementPackagePage")
    elseif opcode == HP_pb.ELEMENT_LVL_UP_S then
        local msg = ElementOpr.HPElementLevelUpRet()
        msg:ParseFromString(msgBuff);
        page:refreshPage(container);
        PageManager.refreshPage("EquipmentPage")
        PageManager.refreshPage("ElementPackagePage")
    elseif opcode == HP_pb.ELEMENT_DRESS_S then
        local msg = ElementOpr.HPElementDressRet()
        msg:ParseFromString(msgBuff);
        PageManager.popPage("ElementSelectPage")
        PageManager.popPage("ElementInfoPage")
        PageManager.refreshPage("EquipmentPage")
    elseif opcode == HP_pb.ELEMENT_RECAST_S then
        local msg = ElementOpr.HPElementRecastRet()
        msg:ParseFromString(msgBuff);
        page:refreshRecastAttr(container,true,msg.attrs);
        PageManager.refreshPage("ElementPackagePage")
        PageManager.refreshPage("ElementRecastPage")
    elseif opcode == HP_pb.ELEMENT_RECAST_CONFIRM_S then 
       page:getPageInfo(container)
       PageManager.refreshPage("ElementInfoPage")
    elseif opcode == HP_pb.ELEMENT_DECOMPOSE_S then
        local msg = ElementOpr.HPElementDecomposeRet()
        msg:ParseFromString(msgBuff);

        for i=1,#msg.elementIds do
            local eleId = msg.elementIds[i]
            self.UserElementMap[eleId] = nil
        end

        page:refreshPage(container);
        PageManager.refreshPage("ElementPackagePage")
    end
end

function ElementManager_reset()
    ElementManager.UserElementMap = {}
    ElementManager.selectedEle = {}
    ElementManager.OccupationLimit = false;
    ElementManager.index =0
end
-------------------------------------
return ElementManager;
--endregion
