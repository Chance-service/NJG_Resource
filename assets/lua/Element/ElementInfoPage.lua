
--元素神符属性



--endregion
local BasePage = require("BasePage")
local thisPageName = "ElementInfoPage"
local ElementManager = require("Element.ElementManager")
local ElementConfig = require("Element.ElementConfig")
local ResManagerForLua = require("ResManagerForLua")
local roleConfig = ConfigManager.getRoleCfg()
local upgradeIds = {}
local UpgraderEles = {}
local indexType= {
    [1]=nil,
    [2]=nil,
    [3]=nil,
    [4]=nil,
    [5]=nil,
}
local showType=1
local selectedIds = {}
local opcodes = {
    
    ELEMENT_LVL_UP_S = HP_pb.ELEMENT_LVL_UP_S,
    ELEMENT_DRESS_S = HP_pb.ELEMENT_DRESS_S,
    ELEMENT_ADVANCE_S = HP_pb.ELEMENT_ADVANCE_S
}
local option = {
    ccbiFile="ElementAttributePopUp.ccbi",
    handlerMap ={
        onKeyInto = "onKeyInto",
        onUpgrade = "onUpgrade",
        onAdvanced = "onAdvanced",
        onTakeOff = "onTakeOff",
        onChange = "onChange",
        onRecasting = "onRecasting",
        onClose = "onClose",
        onHelp = "onHelp",
        onGrowth = "onGrowth",
    },
    DataHelper = ElementManager
}

local ElementInfoPage = nil;
local m_bIsOri = false -- 是否是成长属性页面

function onFunctionEx(eventName,container)
    if  string.sub(eventName,1,12) == "onElementBtn" then
        local index = tonumber(string.sub(eventName,-1));
        ElementInfoPage:onElementBtn(container,index);
    end
end
ElementInfoPage = BasePage:new(option,thisPageName,onFunctionEx,opcodes)

function ElementInfoPage:getPageInfo(container) 
    if not IsEnglishLanguage() then
        NodeHelper:SetNodePostion(container,"mName",-20);
    end
    self:refreshPage(container) 
end
function ElementInfoPage:checkMaxLevel()
    local ele = ElementManager:getSelectedElement()
    if ele.level == GameConfig.ElementMaxLevel then
        MessageBoxPage:Msg_Box_Lan("@ElementReachMaxLevel")
        return false
    end
end

function ElementInfoPage:refreshPage(container)
    UpgraderEles = {}
    selectedIds = {}
    local nodesVisible = {}
    local nodes = {}
    local ele = ElementManager:getSelectedElement();
    local basicAttrs = ele.basicAttrs.attribute;
    local extraAttrs = ele.extraAttrs.attribute;
    local levelInfo = ElementManager:getLevelInfoByLv(ele.level);
    local nextLevelInfo = ElementManager:getLevelInfoByLv(ele.level+1);
    local LevelExp = ElementConfig.ElementLevelCfg[ele.level];
    local score = ElementManager:Score(ele.id)
    local name = "";
    name = ElementManager:getNameById(ele.id)
    roleId = ElementManager:getRoleById(ele.id)
    local roleStr = ""
    if roleId~=0 then
        roleStr = roleConfig[roleId].name
    end
    local scale = 1;
    local expline = ""
    local upgradeExp = LevelExp.upgradeExp;
    local expBar = container:getVarScale9Sprite("mVipExp")
    --如果是背包中查看元素，隐藏脱下和更换两个按钮
    if showType == ElementManager.showType.package then
        NodeHelper:setNodesVisible(container,{mTakeOffNode = false,mChangeNode = false})
    end
    --元素橙色品质及以上并拥有附加属性才显示重铸按钮
    if ele.quality>=5 and extraAttrs and #extraAttrs>=1 then
        NodeHelper:setNodesVisible(container,{mRecastingNode = true})
    else
        NodeHelper:setNodesVisible(container,{mRecastingNode = false})
    end
    if ele.quality==5 then
        NodeHelper:setNodesVisible(container,{mAdvanced = false})
    else
        NodeHelper:setNodesVisible(container,{mAdvanced = true})
    end
    local lb2Str = {
        mLv = common:getLanguageString("@MyLevel", ele.level),
        mName = name,
        mScoreNum = score,   
        mExpLv =  common:getLanguageString("@MyLevel", ele.level),
        mOccupationName = roleStr
    }
    --经验条
    if nextLevelInfo~=nil then
        scale = ele.exp / upgradeExp
        scale = math.min(1,scale)
        expline = (ele.exp).."/"..upgradeExp
    else 
        local maxStr = common:getLanguageString("@SESkillFullLevel")
        expline = maxStr or ""
    end
    if expBar~=nil then
        expBar:setScaleX(scale)
    end
    lb2Str.mExperienceNum = expline

    ---有多少条属性，就显示几条，其余的隐藏
    for i =1 ,8 do
        nodes["mAttributeNode"..i]=false;
    end
    --先隐藏预显示升级后属性的值
    nodes["mScoreAdditionalNum"] = false;
    for i =1 ,8 do
        nodes["mAdditionalNum"..i]=false;
    end
    --金币节点隐藏
    NodeHelper:setNodeVisible(container:getVarNode('mGoldNum'),false);
    --基础属性
    for i=1,#basicAttrs do
        nodes["mAttributeNode"..i]=true;
        local attrName = ElementManager:getAttrNameByAttrId(basicAttrs[i].attrId)
        local value = math.floor(levelInfo[attrName]*(basicAttrs[i].attrValue))
        local attrStr,numStr = ResManagerForLua:getAttributeString(basicAttrs[i].attrId,value)
        lb2Str["mAttribute"..i] = attrStr;
        lb2Str["mAttributeNum"..i] = "+"..numStr
       
    end
    --附加属性
    if #extraAttrs == 0 then
        nodes["mAdditionalAttributesNode"]=false;
    else
        for i=1,#extraAttrs do
            nodes["mAttributeNode"..(i+4)]=true;
            local attrName = ElementManager:getAttrNameByAttrId(extraAttrs[i].attrId)
            local value = math.floor(levelInfo[attrName]*extraAttrs[i].attrValue)
            local attrStr,numStr = ResManagerForLua:getAttributeString(extraAttrs[i].attrId,value)
            lb2Str["mAttribute"..(i+4)] = attrStr;
            lb2Str["mAttributeNum"..(i+4)] = "+"..numStr
           
        end
    end
    -- 按钮名字
    local moreAttrBtnStr = common:getLanguageString("@ElementMoreAttribute")
    NodeHelper:setStringForLabel(container,{mMoreAttributeLabel = moreAttrBtnStr})
    
    ---升级所需的元素，清零处理
    for i =1 ,5 do 
       local pic ={};
       pic["mPic"..i] = GameConfig.Image.Empty;
       NodeHelper:setSpriteImage(container,pic);
       NodeHelper:setMenuItemQuality(container,"mElementBtn"..i,0);
    end
    --新等级的显示隐藏
    NodeHelper:setStringForLabel(container,{mAddExpLv = ""})
    NodeHelper:setNodesVisible(container,nodes)
    NodeHelper:setMenuItemQuality(container,"mHand",ele.quality);
    NodeHelper:setSpriteImage(container,{mPic = ElementManager:getIconById(ele.id)});
    NodeHelper:setStringForLabel(container,lb2Str)
   
	for i =1 ,#basicAttrs do
		NodeHelper:setLabelOneByOne(container,"mAttribute"..i,"mAttributeNum"..i,3)
	end
	for i =1 ,5 do
		NodeHelper:setLabelOneByOne(container,"mAttribute"..(i+4),"mAttributeNum"..(i+4),3)
	end
end

function ElementInfoPage:refreshOriAttr( container,isOri )
    local nodes = {}
    local lb2Str = {}
    
    if isOri then
        nodes["mOriAttributeNodeAll"]=true
        nodes["mAttributeNodeAll"]=false
        for i=1,4 do
            nodes["mOriAttributeNode"..i]=false
        end
        --成长属性
        local ele = ElementManager:getSelectedElement()
        local oriAttrs = ele.basicAttrs.attribute
        for i=1,#oriAttrs do
            nodes["mOriAttributeNode"..i]=true
            local attrName = common:getLanguageString("@AttrName_"..oriAttrs[i].attrId)
            local attrNameSuffix = common:getLanguageString("@ElementAttributeSuffix")
            lb2Str["mOriAttribute"..i] = attrName..attrNameSuffix
            lb2Str["mOriAttributeNum"..i] = oriAttrs[i].attrValue
        end
    else
        nodes["mOriAttributeNodeAll"]=false
        nodes["mAttributeNodeAll"]=true
    end
    NodeHelper:setNodesVisible(container,nodes)
    NodeHelper:setStringForLabel(container,lb2Str)
	for i =1 ,5 do
		NodeHelper:setLabelOneByOne(container,"mOriAttribute"..i,"mOriAttributeNum"..i,5,true)
	end
end
function ElementInfoPage:showUpgradedInfo(container)
    local ele = ElementManager:getSelectedElement();
    local basicAttrs = ele.basicAttrs.attribute;
    local extraAttrs = ele.extraAttrs.attribute;
    local exp = ElementManager:supplySwallowExps(UpgraderEles)
    local goldNum = ElementManager:supplySwallowGolds(UpgraderEles)
    local level ,leftExp= ElementManager:exExp2newLevel(ele.id,exp)
    local levelInfo = ElementManager:getLevelInfoByLv(level);
    local LevelExp = ElementConfig.ElementLevelCfg[level];
    local score = ElementManager:Score(ele.id,level)
    local lb2Str = {}
    local nodes = {}
    --评分
    lb2Str["mScoreAdditionalNum"]="→ "..score
    --没有添加升级所需元素，隐藏
    if #UpgraderEles ==0 then
        nodes["mScoreAdditionalNum"] = false;
        nodes["mAddExpLv"] = false;
        nodes["mGoldNum"] = false;
        
    else 
        nodes["mScoreAdditionalNum"] = true;
        nodes["mAddExpLv"] = true;
        nodes["mGoldNum"] = true;
    end
    --基础属性
    for i=1,#basicAttrs do
        if #UpgraderEles ==0 then
            nodes["mAdditionalNum"..i]=false;
        else
            nodes["mAdditionalNum"..i]=true;
        end
        local attrName = ElementManager:getAttrNameByAttrId(basicAttrs[i].attrId)
        local value = math.floor(levelInfo[attrName]*basicAttrs[i].attrValue)
        local attrStr,numStr = ResManagerForLua:getAttributeString(basicAttrs[i].attrId,value)
        lb2Str["mAttribute"..i] = attrStr;
        lb2Str["mAdditionalNum"..i] = "→ "..numStr
        
    end
   --附加属性
    for i=1,#extraAttrs do
        if #UpgraderEles ==0 then
            nodes["mAdditionalNum"..(i+4)]=false;
        else
            nodes["mAdditionalNum"..(i+4)]=true;
        end
        local attrName = ElementManager:getAttrNameByAttrId(extraAttrs[i].attrId)
        local value = math.floor(levelInfo[attrName]*extraAttrs[i].attrValue)
        local attrStr,numStr = ResManagerForLua:getAttributeString(extraAttrs[i].attrId,value)
        lb2Str["mAttribute"..(i+4)] = attrStr;
        lb2Str["mAdditionalNum"..(i+4)] = "→ "..numStr
           
    end
    ---新等级
    lb2Str["mAddExpLv"] = "→ Lv."..level;
    --升级所需金币
    if goldNum then
        lb2Str["mGoldNum"] =common:getLanguageString("@ElementUpgradeContent",goldNum)
    end
    --经验条
    local scale = 1;
    local expline = ""
    local upgradeExp = LevelExp.upgradeExp;
    if levelInfo~=nil then
        if leftExp ==nil then leftExp =0;end
        scale = leftExp / upgradeExp
        scale = math.min(1,scale)
        expline = (leftExp).."/"..upgradeExp
    else 
        local maxStr = common:getLanguageString("@SESkillFullLevel")
        expline = maxStr or ""
    end
    local expBar = container:getVarScale9Sprite("mVipExp")
    if expBar~=nil then
        expBar:setScaleX(scale)
    end
    lb2Str.mExperienceNum = expline
    NodeHelper:setNodesVisible(container,nodes);
    NodeHelper:setStringForLabel(container,lb2Str)
end
function ElementInfoPage:oneKey(container,index,ids)
    UpgraderEles = {};
    for i=1,5 do
        if ids[i] then
            local ele = ElementManager:getElementInfoById(ids[i]);
            local hasValue = common:table_hasValue(UpgraderEles, ele);
            if not hasValue then
                table.insert(UpgraderEles,ele)
                local pic = {};
                pic["mPic"..i] = ElementManager:getIconById(ids[i]);
                NodeHelper:setSpriteImage(container,pic)
                NodeHelper:setMenuItemQuality(container,"mElementBtn"..i,ele.quality);
            end  
        else
            local pic ={}
            pic["mPic"..i] = GameConfig.Image.Empty;
            NodeHelper:setSpriteImage(container,pic);
            NodeHelper:setMenuItemQuality(container,"mElementBtn"..i,0);  
        end
    end
   self:showUpgradedInfo(container);
end
---click event -------
function ElementInfoPage:onGrowth( container )
    m_bIsOri = not m_bIsOri
    self:refreshOriAttr(container, m_bIsOri)
end
function ElementInfoPage:onElementBtn(container,index)
    -- 成长属性->正常属性
    m_bIsOri = false
    self:refreshOriAttr(container, m_bIsOri)
    --
    if self:checkMaxLevel()==false then return end
    require("ElementSelectPage");
    if selectedIds[index] ~=nil then
        local ele = ElementManager:getElementInfoById(selectedIds[index]);
        UpgraderEles=common:table_removeFromArray(UpgraderEles,ele)
        selectedIds[index] = nil;
        self:hand(container,index)
        return;
    else
        
        upgradeIds = {};
        for _,ele in pairs(UpgraderEles) do
            table.insert(upgradeIds,ele.id)
        end
        ElementSelectPage_SelectInfo(EleFilterType.Upgrade,SelectType.Multi,upgradeIds,function(ids)
            selectedIds = ids;
            ElementInfoPage:oneKey(container,index,ids)
        end);
    end
    
end
function ElementInfoPage:hand(container,index)
    for i = 1,5 do 
        if i==index then
            local pic = {}
            pic["mPic"..i] = GameConfig.Image.Empty;
            NodeHelper:setSpriteImage(container,pic);
            NodeHelper:setMenuItemQuality(container,"mElementBtn"..i,0);
        end
    end

    self:showUpgradedInfo(container);
end

function ElementInfoPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ELEMENT)
end

function ElementInfoPage:onKeyInto(container)
    -- 成长属性->正常属性
    m_bIsOri = false
    self:refreshOriAttr(container, m_bIsOri)
    --
    if self:checkMaxLevel()==false then return end
    UpgraderEles = {}
    selectedIds = {}
    local eles = ElementManager:getUnDressAndDressElementsMap()
    eles = ElementManager:removeSelectedEle(eles)
    ElementManager:setSortOrder(true);
    table.sort(eles,ElementManager.sortByExtraAttrsQualityScore);
    local pic = {};
    local num = #eles
    num = num <= 5 and num or 5;
    if num ==0 then
        MessageBoxPage:Msg_Box_Lan("@ElementSelectPrompt")
    end
    for i =1 ,num do 
        if eles[i]~=nil then
            pic["mPic"..i] =ElementManager:getIconById(eles[i].id);
            NodeHelper:setMenuItemQuality(container,"mElementBtn"..i,eles[i].quality);
            indexType[i] = eles[i];
            table.insert(UpgraderEles,eles[i]) 
            table.insert(selectedIds,eles[i].id) 
        end
    end
    NodeHelper:setSpriteImage(container,pic);
    self:showUpgradedInfo(container);
end
function ElementInfoPage:onUpgrade(container)
    if self:checkMaxLevel()==false then return end
    local flagQuality = false;
    local flagExtraAttr =false;
    local title = common:getLanguageString("@ElementsUpdateTitle");
    local content = common:getLanguageString("@EUpContent");
    local element = ElementManager:getSelectedElement();
    local levelInfo = ElementManager:getLevelInfoByLv(element.level);
    --检查元素等级是否高于人物等级

    --检查是否放入吞噬的元素
    if #UpgraderEles==0 then
        MessageBoxPage:Msg_Box_Lan("@PleasePutElements")
        return
    end
    --检查金币是否足够
    local UserInfo = require("PlayerInfo.UserInfo")
    UserInfo.isCoinEnough(levelInfo.swallowGold)
    --检查是否有橙色品质或者附加属性的元素
    for _,ele in ipairs(UpgraderEles) do
        if ele.quality == 5 then
            flagQuality=true;
        end
        if #(ele.extraAttrs.attribute) >0 then
            flagExtraAttr =true;
        end
    end
    if flagQuality  then
        content = common:getLanguageString("@EUpQualityContent");
    elseif flagExtraAttr then 
        content = common:getLanguageString("@EUpExtraAttrContent");
    end
    PageManager.showConfirm(title,content,function(isSure)
        if isSure then
            ElementManager:Upgrader(element.id,UpgraderEles)
            return;
        end
    end) 
end
function ElementInfoPage:onAdvanced(container)
    PageManager.pushPage("ElementAdvancedPage");
end
function ElementInfoPage:onTakeOff(container)
    local ele = ElementManager:getSelectedElement();
    ElementManager:Dress(0,ElementManager.index)
end
function ElementInfoPage:onChange(container)
    require("ElementSelectPage")
    local ele = ElementManager:getSelectedElement();
    if ele.profLimit == 0 then
        ElementManager.OccupationLimit = false
    else 
        ElementManager.OccupationLimit = true
    end
    ElementSelectPage_SelectInfo(EleFilterType.Dress,SelectType.Single,nil,nil)
end
function ElementInfoPage:onRecasting(container)
    require("ElementRecastPage")
    local ele = ElementManager:getSelectedElement();
    ElementRecastPage_Show(ele.id)
    
end
function ElementInfoPage:onClose(container)
     selectedIds = {}
     upgradeIds = {}
     UpgraderEles = {}
     m_bIsOri = false
    PageManager.popPage(thisPageName);
end

function ElementInfoPage_setShowType(sType)
    if sType ~= nil then
        showType = sType
    end
    PageManager.pushPage(thisPageName)
end