----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
registerScriptPage("ReplaceSkillPage");
local hp = require('HP_pb')
local skillPb = require("Skill_pb")
local SkillManager = require("Skill.SkillManager")
local NewbieGuideManager = require("Guide.NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = "SkillPage";
local NodeHelper = require("NodeHelper");
local GameConfig = require("GameConfig");
local MultiColumnScrollViewHelper = require("MultiColumnScrollViewHelper")
local mRebuildLock = true
local mRefreshCout = 0
local keyCount = 1
local FinalTable={ }
local option = {
    ccbiFile = "SkillPage.ccbi",
    handlerMap =
    {
        onHelp = "showHelp",
        onSkillspecialty = "enhanceSkill",
        onReplaceSkill = "replaceSkill",
        onFightSkill = "onFightSkill",
        onArenaSkill = "onArenaSkill",
        onDefenseSkill = "onDefenseSkill",
        onReturnBtn = "onReturn",
        onSkillClick="onSkillClick",
        onMobile="onMobile"

    },
    opcode = opcodes
}

local skillCfg = ConfigManager.getSkillCfg();
local skillOpenCfg = ConfigManager.getSkillOpenCfg()

local SkillPageBase = { }
local SkillPageNormalContent = { }
local SkillOpenContent={ }
local SkillPageEmptyContent = { }
local skillItemIds={}
local SkillTable={ }
local touchId = 0
local touchId2= 0
local ChildContainer=nil
local CanReFresh=true

--------------------------------------------------------------
local SkillItem = {
    ccbiFile_empty = "SkillEmptyContent.ccbi",
    ccbiFile_close = "SkillNotOpenContent.ccbi",
    ccbiFile_open = "SkillOpenContent.ccbi",
}

-------------------------------------------------------------


local PageType = {
    FIGHT_SKILL = 1,
    ARENA_SKILL = 2,
    DEFENSE_SKILL = 3
}

local currPageType = PageType.FIGHT_SKILL
local mMainContainer = nil
local mInterval = -700
local myContainer = nil
local a,b,c,d=5,4,3,2
----------------------------------------------------------------------------------
local myProfessionSkillCfg = {}
-----------------------------------------------
-- SkillPageBase
----------------------------------------------
function SkillPageBase:onEnter(container)
    SkillPageBase:getMyProfessionSkillCfg(UserInfo.roleInfo.prof)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    myContainer = container
    self:registerPackets(container)
    NodeHelper:initScrollView(container, "mContent", 4)
    container.scrollview = container:getVarScrollView("mContent")
   --主動技設定------------
    local LeaderCfg = ConfigManager.getNewHeroCfg()[UserInfo.roleInfo.prof]
    local LeaderSkill = common:split(LeaderCfg.Skills, ",")
    for k, v in ipairs(LeaderSkill)do  
        --FinalTable[k]=mID
        NodeHelper:setSpriteImage(container, { ["PassivePic" .. k] = "skill/S_" .. v .. ".png" })
        NodeHelper:setStringForLabel(container, { ["mSkillName" .. k] = common:getLanguageString("@Skill_Name_" .. v) })
        local CosumeMP = skillCfg[tonumber(v)].cost
        if tonumber(CosumeMP) == 0 then 
            container:getVarNode("mpTex" .. k):setVisible(false) 
            container:getVarNode("mConsumptionMp" .. k):setVisible(false)
        else
            NodeHelper:setStringForLabel(container, { ["mConsumptionMp" .. k] = CosumeMP })
        end  
        local skillDesNode = container:getVarNode("mSkillTex" .. k)
        skillDesNode:removeAllChildren()
        local htmlLabel = CCHTMLLabel:createWithString((FreeTypeConfig[100000 + tonumber(v)] and FreeTypeConfig[100000 + tonumber(v)].content or FreeTypeConfig[101001].content), CCSizeMake(415, 10), "Barlow-SemiBold")
        skillDesNode:setPositionX(skillDesNode:getPositionX() - 12)
        htmlLabel:setAnchorPoint(ccp(0, 0.5))
        skillDesNode:addChild(htmlLabel)
    end
   ----------------------
    if container.scrollview ~= nil then
        mTableInterval = container.mScrollView:getViewSize().width + 100
        mTableInterval = -mTableInterval
    end
    NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite1"))
    mMainContainer = container
    currPageType = PageType.ARENA_SKILL
    self:rebuildAllItem(container)
   
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["SkillPageBase"] = container
    return container
end

function SkillPageBase:onExecute(container)
end

function SkillPageBase:onExit(container)
    container.mScrollView:getContainer():stopAllActions()
    self:removePackets(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    MultiColumnScrollViewHelper.clearMultiColumnScrollView(container)
    NodeHelper:deleteScrollView(container)
    mMainContainer = nil
    mRebuildLock = true
    keyCount = 1
    local GuideManager = require("Guide.GuideManager")
    GuideManager.newbieGuide()
end

function SkillPageBase:onReturn(container)
    PageManager.changePage("EquipLeadPage")
end

function SkillPageBase:onDefenseSkill(container, message)
    currPageType = PageType.DEFENSE_SKILL
    local offset = mTableInterval * 1

    local isDuration
    if message == nil or message ~= "NoneAction" then
        isDuration = true
    else
        isDuration = false
    end
    --self:selectTab(container, offset, isDuration)

    -- self:rebuildAllItem( container )
end
-----------------------------------------------------
---------------------子节点-----------------------------------
local ChildScrollViewContent = {
    ccbiFile = "BackpackContent.ccbi"
}

function ChildScrollViewContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        ChildScrollViewContent.onRefreshItemView(container);
        CCLuaLog("Refeshed----------------------------------")
    end
    if eventName=="onMobile" then
        CCLuaLog("Clicked----------------------------------")
    end
end

function ChildScrollViewContent.onRefreshItemView(container)
    if container.mScrollView == nil then
        NodeHelper:initScrollView(container, "mBackpackContent", 3);
        if mMainContainer ~= nil then
            --mMainContainer:autoAdjustResizeScrollview(container.mScrollView);
            mMainContainer.ChildContentBase = mMainContainer.ChildContentBase or { }
            table.insert(mMainContainer.ChildContentBase, container)
        end
        ChildScrollViewContent.clearAllItem(container)
        ChildScrollViewContent.buildAllItem(container)
    end
end

function ChildScrollViewContent.clearAllItem(container)
    NodeHelper:clearScrollView(container);
end

function ChildScrollViewContent.buildAllItem(container)
    -- 去掉了防御用
    ChildContainer = container
    local contentId = container:getItemDate().mID;
    
    local assignedSkills = SkillManager:getFightSkillList()
    local skillSize = #myProfessionSkillCfg--#assignedSkills
    local passiveSkill = {}
    local skillnum = 1
   
    for i = 1, skillSize do
        local SkillId = SkillManager:getSkillItemIdUsingId(myProfessionSkillCfg[i])
        if  SkillId > 90000 then 
            passiveSkill[skillnum] = myProfessionSkillCfg[i]
            skillnum = skillnum + 1
        else 
            FinalTable[i] = myProfessionSkillCfg[i]
        end
    end   
    local FinalSkill = { 0, 0, 0, 0 }
    for a = 1, #passiveSkill do
	    if assignedSkills[a + 2] ~= 0 and assignedSkills[a + 2] then
		    FinalSkill[a] = assignedSkills[a + 2]
	    else
		    for k1, v1 in pairs(passiveSkill) do
			    for k2, v2 in pairs(FinalSkill) do
				    if v1 == v2 then
					    break
				    elseif k2 == #FinalSkill then
					    FinalSkill[a] = v1
				    end
			    end
		    end
	    end	
    end
    local passiveSize = #passiveSkill
    local iCount = 0
 
    local fOneItemHeight = 0
    local fOneItemWidth = 0
    local oneHeight = 0
    local count = ServerDateManager:getInstance():getSkillInfoTotalSize()
    local offset = 164
    local FirstSkillPosY = 480
    local SkillPosX = 7
    
    local LeaderCfg = ConfigManager.getNewHeroCfg()[UserInfo.roleInfo.prof]
    local LeaderPassive = common:split(LeaderCfg.Passive,",")
   
    for i = 1, #LeaderPassive do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        --pItemData.m_ptPosition = ccp(0, oneHeight)
        local pItem = nil
        pItemData.OringinId = FinalSkill[i]
        local skillItemId = SkillManager:getSkillItemIdUsingId(FinalSkill[i])
        
        if skillItemId == nil then 
            local ccbiFile = SkillItem.ccbiFile_close;
            pItem = ScriptContentBase:create(ccbiFile);
            local label = pItem:getVarLabelTTF('mOpenLevel')
            if label then
                local skillLevelNum = tonumber(ConfigManager.getSkillCfg()[tonumber(LeaderPassive[i])].level)
                label:setString(common:getLanguageString('@OpenLevel', skillLevelNum))
            end
        else   
            pItemData.skillItemId = skillItemId
            skillItemId = tonumber(skillItemId)  
            if skillItemId > 0 then
                -- carried
                local ccbiFile = SkillItem.ccbiFile_open
                pItem = ScriptContentBase:create(ccbiFile)
                pItem:registerFunctionHandler(SkillOpenContent.onFunction)
                pItem.id = skillItemId
                -- PassiveSkill內容 ----------------------
                NodeHelper:setStringForLabel(pItem, {["mSkillName"] = common:getLanguageString("@Passive_Name_" .. skillItemId)})
                local costMp = skillCfg[skillItemId].cost
                if tonumber(costMp) == 0 then
                    pItem:getVarNode("mpTex3"):setVisible(false)
                    pItem:getVarNode("mConsumptionMp"):setVisible(false)
                else
                    NodeHelper:setStringForLabel(pItem, { mConsumptionMp = costMp })
                end
                NodeHelper:setSpriteImage(pItem, { mChestPic = "skill/S_" .. skillItemId .. ".png"})
                local skillDesNode = pItem:getVarNode("mSkillTex")
                skillDesNode:removeAllChildren()
                local htmlLabel = CCHTMLLabel:createWithString((FreeTypeConfig[100000 + skillItemId] and FreeTypeConfig[100000 + skillItemId].content or FreeTypeConfig[101001].content), CCSizeMake(415, 10), "Barlow-SemiBold")
                htmlLabel:setPosition(ccp(0, 0))
                htmlLabel:setAnchorPoint(ccp(0, 0.5))
                skillDesNode:addChild(htmlLabel)    
                ---------------------------------------------
            end --Id>0
        end

        ---單一元件設定----------------------------
        if pItem ~= nil then
            --pItem:setAnchorPoint(ccp(0, 1))
            --fOneItemHeight = pItem:getContentSize().height
            --local a = pItem:getContentSize().height
            oneHeight = oneHeight + pItem:getContentSize().height
            --if fOneItemWidth < pItem:getContentSize().width then
            --    fOneItemWidth = pItem:getContentSize().width
            --end
            pItem.num = i
            pItemData.pItem = pItem
            skillItemIds[i] = pItemData  
        end
        -------------------------------------------------  
        --生成
        container.m_pScrollViewFacade:addItem(skillItemIds[i], pItem.__CCReViSvItemNodeFacade__)
        iCount = iCount + 1    
    end --for迴圈結束

    ---------------------------------------------------------------------------------
    if skillItemIds[1] ~= nil then
       skillItemIds[1].m_ptPosition = ccp(SkillPosX, FirstSkillPosY)
       NodeHelper:setNodesVisible(skillItemIds[1].pItem, { ChangeBtn = true , mSelect = false, SkillBtn = false })
    end   
    if skillItemIds[2] ~= nil then
       skillItemIds[2].m_ptPosition = ccp(SkillPosX, FirstSkillPosY - offset)
       NodeHelper:setNodesVisible(skillItemIds[2].pItem, { ChangeBtn = true , mSelect = false, SkillBtn = false })
    end   
    for a = 3, #LeaderPassive do
        if skillItemIds[a] ~= nil then
            skillItemIds[a].m_ptPosition = ccp(SkillPosX, FirstSkillPosY - (a - 1) * offset)
            NodeHelper:setNodesVisible(skillItemIds[a].pItem, { ChangeBtn = false, mSelect = false, SkillBtn = false })
        end
    end
    -----------調整ScrollView大小-------------
    local size = CCSizeMake(640, 770)
    --container.mScrollView:setAnchorPoint(ccp(0, 0))
    --container.mScrollView:setPositionY(oneHeight)
    container.mScrollView:setContentSize(size)
    --container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollView:forceRecaculateChildren();
    --------------------------------------
    container.mScrollView:orderCCBFileCells()
   
end





----------------scrollview-------------------------
function SkillPageBase:rebuildAllItem(container)
    local SEManager = require("Skill.SEManager")
    local SEConfig = require("Skill.SEConfig")
    local UserInfo = require("PlayerInfo.UserInfo")
    UserInfo.syncRoleInfo()
    local ConfigManager = require("ConfigManager")
    local RoleId = UserInfo.roleInfo.itemId
    local roleCfg = ConfigManager.getRoleCfg()
    local profession = roleCfg[RoleId]["profession"]
    if SEManager.HasOpen[profession] ~= nil then
        mSERedPoint =(not SEManager.HasOpen[profession]) and UserInfo.roleInfo.level >= SEConfig.OpenLevel
        NodeHelper:setNodesVisible(container, { mSkillPoint = mSERedPoint })
    else
        mSERedPoint = true
        NodeHelper:setNodesVisible(container, { mSkillPoint = mSERedPoint })
    end


    -- 预防同一时间刷新多次
    if mRebuildLock then
        mRebuildLock = false
        self:clearAllItem(container);
        self:buildItem(container);

        -- 延迟1s
        container:runAction(
        CCSequence:createWithTwoActions(
        CCDelayTime:create(0.1),
        CCCallFunc:create( function()
            mRebuildLock = true;
            -- 判断是否有未被刷新的情况存在，无论未被刷新多少次都只重新刷新一次
            if mRefreshCout > 0 then
                mRefreshCout = 0
                self:rebuildAllItem(container)
            end
        end )
        )
        );
    else
        -- 记录下未被刷新的次数
        mRefreshCout = mRefreshCout + 1;
    end
end

function SkillPageBase:clearAllItem(container)
    container.mScrollView:getContainer():stopAllActions()
    MultiColumnScrollViewHelper.clearMultiColumnScrollView(container)
    NodeHelper:clearScrollView(container);
end

function SkillPageBase:buildItem(container)

    UserInfo.sync()

    local buildTable = {
        totalSize = 4
    }
    local buildOne = {
        ccbiFile = ChildScrollViewContent.ccbiFile,
        size = 1,
        funcCallback = ChildScrollViewContent.onFunction
    }
    table.insert(buildTable, buildOne)
    MultiColumnScrollViewHelper.buildScrollViewHorizontal(container, buildTable, 0)
    --MultiColumnScrollViewHelper.setMoveOnByOn(container, true)
 
end

----------------click event------------------------
function SkillPageBase:showHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_SKILL)
end

-- æŠ€èƒ½ä¸“ç²¾ï¼Œæš‚æœªå¼€æ”?
function SkillPageBase:enhanceSkill(container)
    -- MessageBoxPage:Msg_Box('@CommingSoon')
    local SEManager = require("Skill.SEManager")
    SEManager:EnterSEPage()
end


-- ----------------------- open content----------------------- 
function SkillOpenContent.onFunction(eventName, container)
    local passiveSize=#skillItemIds
    if eventName == "luaRefreshItemView" then
        --SkillPageEmptyContent.refreshItemView(container)
    elseif eventName == "onMobile" then
        touchId=container.num
        for i=1,passiveSize do
            NodeHelper:setNodesVisible(skillItemIds[i].pItem,{ SkillBtn = true ,mSelect = true } )
        end
        if skillItemIds[1]~=nil then NodeHelper:setNodesVisible(skillItemIds[1].pItem,{ mSelect = false } ) end
        if skillItemIds[2]~=nil then NodeHelper:setNodesVisible(skillItemIds[2].pItem,{ mSelect = false } ) end
    elseif eventName=="SkillClick" then
        touchId2=container.num   
        for i= 1, passiveSize do
            NodeHelper:setNodesVisible(skillItemIds[i].pItem,{ SkillBtn = false ,mSelect = false } )
        end
        if(touchId==skillItemIds[1].pItem.num) then
                 local k=skillItemIds[1]
                 skillItemIds[1]=skillItemIds[touchId2]
                 skillItemIds[touchId2]=k
        elseif (touchId==skillItemIds[2].pItem.num) then
                 local k=skillItemIds[2]
                 skillItemIds[2]=skillItemIds[touchId2]
                 skillItemIds[touchId2]=k
        end   

        for i=1 , passiveSize do
            SkillTable[i]=skillItemIds[i].OringinId
        end
        FinalTable[3]=SkillTable[1]
        FinalTable[4]=SkillTable[2]
        
        
        SkillPageBase:SendPackage(myContainer,FinalTable)
        
        
      -- NodeHelper:clearScrollView(myContainer)
      -- SkillPageBase:buildItem(myContainer)
    end   
     
   
    
end

function SkillPageBase:SendPackage(container,SkillTable)
    CanReFresh=false
    local selectedTable = { }
    local openedSkillCount = #SkillTable
    local count = 0
    for i = 1, openedSkillCount do
        if SkillTable[i] ~= 0 then
            count = count + 1
            selectedTable[count] = SkillTable[i]
        end
    end
    UserInfo.sync()
    local roleInfo = UserInfo.roleInfo
    if not roleInfo then return end

    local msg = skillPb.HPSkillCarry()
    msg.roleId = UserInfo.roleInfo.roleId

    local selectedSize = #selectedTable
    local skillOpenCount = #roleInfo.skills+1
    if not skillOpenCount then return end

    for i = 1, openedSkillCount do
        if i <= selectedSize then
            msg.skillId:append(selectedTable[i])
        else
             msg.skillId:append(0)
        end
    end

    msg.skillBagId = 1
    local pb = msg:SerializeToString()
    container:sendPakcet(hp.ROLE_CARRY_SKILL_C, pb, #pb, true)
    CanReFresh=true
end


function SkillPageBase:registerPackets(container)
    container:registerPacket(hp.ROLE_CARRY_SKILL_S)
    container:registerPacket(hp.SKILL_CHANGE_ORDER_S)
end

function SkillPageBase:removePackets(container)
    container:removePacket(hp.ROLE_CARRY_SKILL_S)
    container:removePacket(hp.SKILL_CHANGE_ORDER_S)
end

function SkillPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == hp.SKILL_CHANGE_ORDER_S then
        self:rebuildAllItem(container)
        return
    end

    if opcode == hp.ROLE_CARRY_SKILL_S then
        self:rebuildAllItem(container)
        return
    end
end

function SkillPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            self:rebuildAllItem(container)
        end
    end
end

function SkillPageBase:getMyProfessionSkillCfg(professionItemId)
    myProfessionSkillCfg = { }
    local count = ServerDateManager:getInstance():getSkillInfoTotalSize()
	for i=0, count-1 do
		local skillStr = ServerDateManager:getInstance():getSkillInfoByIndexForLua(i)
		local skillInfo = skillPb.SkillInfo()
		skillInfo:ParseFromString(skillStr)
		
		if skillInfo then
			--local roleId = skillInfo.roleId
			--if SkillManager.OpenSkillList[roleId] == nil then
			--	SkillManager.OpenSkillList[roleId] = {}
				table.insert(myProfessionSkillCfg, skillInfo.id);
			--else
			--	table.insert(SkillManager.OpenSkillList[roleId],skillInfo);
			--end								
		end
	end
end
-------------------------------------------------------------------------
return SkillPageBase
