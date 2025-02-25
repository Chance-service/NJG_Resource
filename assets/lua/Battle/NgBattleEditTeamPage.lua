local thisPageName = "NgBattleEditTeamPage"
local NgFightSceneHelper = require("Battle.NgFightSceneHelper")
local UserMercenaryManager = require("UserMercenaryManager")
local CONST = require("Battle.NewBattleConst")
local NgHeadIconItem_Small = require("NgHeadIconItem_Small")
local HP_pb = require("HP_pb")
local EventDataMgr = require("Event001DataMgr")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
local NgBattleEditTeamPage = { }

local option = {
    ccbiFile = "BattlePageEditTeam.ccbi",
    handlerMap = {
        onFilter = "onFilter",
        onReturn = "onReturn",
        onConfirm = "onConfirm",
    },
    opcodes = {
        EDIT_FORMATION_S = HP_pb.EDIT_FORMATION_S,
    }
}
local MAX_TEAM_NUM = 5

local FILTER_WIDTH = 500
local FILTER_OPEN_HEIGHT = 142
local FILTER_CLOSE_HEIGHT = 74
local filterOpenSize = CCSize(FILTER_WIDTH, FILTER_OPEN_HEIGHT)
local filterCloseSize = CCSize(FILTER_WIDTH, FILTER_CLOSE_HEIGHT)
local HEAD_SCALE = 0.91
local headIconSize = CCSize(139 * HEAD_SCALE, 139 * HEAD_SCALE)

local allTeamContent = {}

local pageContainer = nil
local nowTeamRoleIds = { }  -- 當前選擇的隊伍roleId
local allSelectNode = { }   -- 選擇框spine node
local selectId = 0          -- 選擇中的位置id

local currentElement = 0
local currentClass = 0

local items = { }
local roleSortInfos = { }
local mInfos = nil
local heroCfg = ConfigManager.getNewHeroCfg()

for i = 1, MAX_TEAM_NUM do
    option.handlerMap["onHero" .. i] = "onHero"
end
for i = 0, 5 do
    option.handlerMap["onElement" .. i] = "onElement"
end
for i = 0, 4 do
    option.handlerMap["onClass" .. i] = "onClass"
end

function NgBattleEditTeamPage.onHeadCallback(itemNode)
    if selectId > 0 and selectId <= MAX_TEAM_NUM then   -- 場景有選擇過
        -- 關閉選擇框
        allSelectNode[selectId]:setVisible(false)
        -- 檢查是否在隊伍中
        for i = 1, MAX_TEAM_NUM do
            if nowTeamRoleIds[i] == itemNode.roleId then    -- 在隊伍中
                if i == selectId then    -- 位置在選擇的id上 --> 移除隊伍
                    -- 刪除畫面顯示
                    pageContainer:getVarNode("mSpine" .. i):removeAllChildrenWithCleanup(true)
                    pageContainer:getVarNode("mSpine" .. i):setVisible(false)
                    -- 移除選擇狀態
                    NgHeadIconItem_Small:setIsChoose(itemNode, false)
                    -- 移除隊伍資訊
                    nowTeamRoleIds[selectId] = 0
                    -- 關閉選擇框
                    allSelectNode[selectId]:setVisible(false)
                    selectId = 0
                    NgBattleEditTeamPage:setFightAndBuff()
                    return
                else    -- 位置不在選擇的id上 --> 交換位置
                    -- 交換場景資訊
                    local parentNode1 = pageContainer:getVarNode("mSpine" .. selectId)           
                    local parentNode2 = pageContainer:getVarNode("mSpine" .. i)
                    local child1 = nil
                    local child2 = nil
                    if parentNode1:getChildren() then
                        child1 = parentNode1:getChildren():objectAtIndex(0)
                    end
                    if parentNode2:getChildren() then
                        child2 = parentNode2:getChildren():objectAtIndex(0)     
                    end
                    if child1 then
                        child1:retain()
                        child1:removeFromParentAndCleanup(false)
                        parentNode2:addChild(child1)
                        parentNode2:setVisible(true)
                        child1:release()
                    end
                    if child2 then
                        child2:retain()
                        child2:removeFromParentAndCleanup(false)
                        parentNode1:addChild(child2)
                        parentNode1:setVisible(true)
                        child2:release()
                    end
                    -- 交換隊伍資訊
                    local tempId = nowTeamRoleIds[selectId]
                    nowTeamRoleIds[selectId] = nowTeamRoleIds[i]
                    nowTeamRoleIds[i] = tempId
                    selectId = 0
                    NgBattleEditTeamPage:setFightAndBuff()
                    return
                end
            end
        end
        -- 不在隊伍中 --> 加入隊伍
        -- 從隊伍指定位置加入
        -- 清空舊資訊
        for k, v in pairs(items) do
            if v.handler.roleId == nowTeamRoleIds[selectId] then
                -- 移除選擇狀態
                NgHeadIconItem_Small:setIsChoose(v.handler, false)
            end
        end
        -- 加入隊伍資訊
        nowTeamRoleIds[selectId] = itemNode.roleId
       
        -- 加入畫面顯示
        local parentNode = pageContainer:getVarNode("mSpine" .. selectId)
        parentNode:removeAllChildrenWithCleanup(true)
        local info = mInfos[itemNode.roleId]
        local spinePath, spineName = unpack(common:split(heroCfg[info.itemId].Spine, ","))
        local spine = SpineContainer:create(spinePath, spineName .. string.format("%03d", info.skinId))
        spine:runAnimation(1, CONST.ANI_ACT.WAIT, -1)
        local sNode = tolua.cast(spine, "CCNode")
        parentNode:addChild(sNode)
        parentNode:setVisible(true)
        -- 設定選擇狀態
        NgHeadIconItem_Small:setIsChoose(itemNode, true)
        selectId = 0
    else    -- 沒有選擇位置
        -- 檢查是否在隊伍中
        for i = 1, MAX_TEAM_NUM do
            -- 在隊伍中 --> 移除隊伍
            if nowTeamRoleIds[i] == itemNode.roleId then
                -- 移除隊伍資訊
                nowTeamRoleIds[i] = 0
               
                -- 刪除畫面顯示
                pageContainer:getVarNode("mSpine" .. i):removeAllChildrenWithCleanup(true)
                pageContainer:getVarNode("mSpine" .. i):setVisible(false)
                -- 移除選擇狀態
                NgHeadIconItem_Small:setIsChoose(itemNode, false)
                NgBattleEditTeamPage:setFightAndBuff()
                return
            end
        end
        -- 不在隊伍中 --> 加入隊伍
        for i = 1, MAX_TEAM_NUM do
            -- 從隊伍最前面的空位加入
            if nowTeamRoleIds[i] == 0 then
                -- 加入隊伍資訊
                nowTeamRoleIds[i] = itemNode.roleId               
                -- 加入畫面顯示
                local parentNode = pageContainer:getVarNode("mSpine" .. i)
                local info = mInfos[itemNode.roleId]
                local spinePath, spineName = unpack(common:split(heroCfg[info.itemId].Spine, ","))
                local spine = SpineContainer:create(spinePath, spineName .. string.format("%03d", info.skinId))
                spine:runAnimation(1, CONST.ANI_ACT.WAIT, -1)
                local sNode = tolua.cast(spine, "CCNode")
                parentNode:addChild(sNode)
                parentNode:setVisible(true)
                -- 設定選擇狀態
                NgHeadIconItem_Small:setIsChoose(itemNode, true)
                NgBattleEditTeamPage:setFightAndBuff()
                return
            end
        end
        -- 隊伍已滿
        MessageBoxPage:Msg_Box_Lan("@OrgTeamFull")
    end
end

function NgBattleEditTeamPage:setFightAndBuff()
    NgBattleEditTeamPage:calTeamFight()
    NgBattleEditTeamPage:refreshTeamBuff()
end
function NgBattleEditTeamPage:calTeamFight()
    local nAllFight = 0  
    for _,v in pairs(nowTeamRoleIds) do
        --local info = mInfosDisorder[groupInfos.roleIds[i]]
        local info = UserMercenaryManager:getUserMercenaryById(v)
        if info then
            nAllFight = nAllFight + info.fight
        end
    end
    NodeHelper:setStringForLabel(pageContainer,{mSelfFightingNum = nAllFight})
    if not NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_DEFEND_TEAM then
         UserInfo.roleInfo.marsterFight = nAllFight
    end
end
function NgBattleEditTeamPage:refreshTeamBuff()
    local elementTable = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }
    local buffTable = { }
    local teamBuffCfg = ConfigManager.getTeamBuffCfg()
    for _, id in pairs(nowTeamRoleIds) do
        local roleInfo = UserMercenaryManager:getUserMercenaryById(id)
        if roleInfo then
            local heroCfg = ConfigManager.getNewHeroCfg()[roleInfo.itemId]
            local element = heroCfg.Element
            elementTable[element] = elementTable[element] + 1
        end
    end
    for element = 1, #elementTable do
        if elementTable[element] > 0 then
            for id = 1, #teamBuffCfg do
                if teamBuffCfg[id].Attr == element and teamBuffCfg[id].Num == elementTable[element] then
                    local buffs = common:split(teamBuffCfg[id].Buff, ",")
                    for idx = 1, #buffs do
                        local buffId, _type, num = unpack(common:split(buffs[idx], "_"))
                        buffId = tonumber(buffId)
                        _type = tonumber(_type)
                        num = tonumber(num)
                        buffTable[buffId] = buffTable[buffId] or { }
                        buffTable[buffId][_type] = buffTable[buffId][_type] and buffTable[buffId][_type] + num or num
                    end
                    break
                end
            end
        end
    end
    local sortTable = { }
    for buffId, v in pairs(buffTable) do
        table.insert(sortTable, { buffId = buffId, data = v })
    end
    table.sort(sortTable, function(data1, data2)
        if not data1 or not data2 then
            return false
        end
        if data1.buffId ~= data2.buffId then
            return data1.buffId < data2.buffId
        end
        return false
    end)
    local str = ""
    local count = 1
    for i = 1, #sortTable do
        for _type, num in pairs(sortTable[i].data) do
            local str0 = ""
            if count ~= 1 then
                str0 = ", "
            else
                str = ""
            end
            local str1 = common:getLanguageString("@AttrName_" .. sortTable[i].buffId)
            local str2 = ""
            if _type == 1 then
                num = num / 100
                str2 = "%"
            end
            str = str .. str0 .. str1 .. " +" .. num .. str2
            count = count + 1
        end
    end
    local imgStr = "TeamBuff_"
    local bonusCount = 0
    for i = 1, #elementTable do
        if elementTable[i] > 1 then
            imgStr = imgStr .. i
            bonusCount = bonusCount + 1
        end
    end
    if bonusCount > 0 then
        imgStr = imgStr .. ".png"
    else
        imgStr = "TeamBuff_6.png"
    end
    NodeHelper:setSpriteImage(pageContainer, { mBonusImg = imgStr })
    NodeHelper:setStringForLabel(pageContainer, { mBonusTxt = str })
end

function NgBattleEditTeamPage:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function NgBattleEditTeamPage:onEnter(container)
    pageContainer = container
    mInfos = UserMercenaryManager:getUserMercenaryInfos()
    local mapId = NgBattleDataManager.battleMapId or 1
    local bgPath = ""
    self:registerPacket(container)
    roleSortInfos = { }
    items = { }
    nowTeamRoleIds = { }
    allSelectNode = { }
    selectId = 0
    allTeamContent = { }

    -- 生成選擇框
    for i = 1, 5 do
        local selectNode = container:getVarNode("mSelectNode" .. i)
        selectNode:removeAllChildrenWithCleanup(true)
        local spriteContainter = ScriptContentBase:create("BattlePageEditTeamSelect.ccbi")
        selectNode:addChild(spriteContainter)
        spriteContainter:runAnimation("Select Timeline")
        selectNode:setVisible(false)
        allSelectNode[i] = selectNode
        spriteContainter:release()
    end
    -- 設定過濾按鈕
    --local filterBg = container:getVarScale9Sprite("mFilterBg")
    --filterBg:setContentSize(filterCloseSize)
    --NodeHelper:setNodesVisible(container, { mClassNode = false })

    --NodeHelper:initScrollView(container, "mContentHero", 3)
    self:refreshPage(container)
    self:initEnemy(container)

    self:onElement(container, "onElement0") 
    self:onClass(container, "onClass0") 

    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["NgBattleEditTeamPage"] = container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    -- 放入預設隊伍
    if allTeamContent[0] then
        allTeamContent[0].content:onSelectTeam(allTeamContent[0].container)
    else
        if allTeamContent[1] then
            allTeamContent[1].content:onSelectTeam(allTeamContent[1].container)
        end
    end

    NgBattleEditTeamPage:setFightAndBuff()

    NodeHelper:setNodesVisible(container,{mArenaTeam = false})
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK or NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        local mapCfg = ConfigManager.getNewMapCfg()
        if mapId == 0 then mapId = 1 end
        local chapter = mapCfg[mapId].Chapter
        local mainCh, childCh = unpack(common:split(chapter, "-"))
        bgPath = "BG/Battle/battle_bg_" .. string.format("%03d", mainCh) .. ".png"
        SoundManager:getInstance():playMusic("Battle_" .. string.format("%02d", chapter) .. ".mp3")
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local cfg = ConfigManager:getMultiEliteCfg()
        local fileName = cfg[NgBattleDataManager.dungeonId].bgFileName
        bgPath = "BG/Battle/" .. fileName .. ".png"
        SoundManager:getInstance():playMusic("Dungeon.mp3")
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        bgPath = "BG/Battle/role_bg_mul01.png"
        SoundManager:getInstance():playMusic("Arena.mp3")
         NodeHelper:setNodesVisible(container,{mArenaTeam = true})
        local content = container:getVarNode("mArenaTeamContent")
        if content then
            local child = ReadyToFightTeam
            child:setPosition(ccp(30,10))
            if not child then return end
            content:removeAllChildren()
            content:addChild(child)
            ReadyToFightTeam = nil
        end
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        bgPath = "BG/Battle/role_bg_mul01.png"
        SoundManager:getInstance():playMusic("WorldBoss_Bg.mp3")
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local cfg = ConfigManager:getMultiElite2Cfg()
        local fileName = cfg[NgBattleDataManager.dungeonId].bgFileName
        bgPath = "BG/Battle/" .. fileName .. ".png"
        SoundManager:getInstance():playMusic("Dungeon.mp3")
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
        bgPath = "BG/Battle/battle_bg_001.png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_FIGHT_TEAM then
        local mapCfg = ConfigManager.getNewMapCfg()
        if mapId == 0 then mapId = 1 end
        local chapter = mapCfg[mapId].Chapter
        local mainCh, childCh = unpack(common:split(chapter, "-"))
        bgPath = "BG/Battle/battle_bg_" .. string.format("%03d", mainCh) .. ".png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_DEFEND_TEAM then
        bgPath = "BG/Battle/role_bg_mul01.png"
        NodeHelper:setSpriteImage(container,{ mFightNumBg = "BattleTeam_Img02_2.png" })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local cfg = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG
        local fileName = cfg[NgBattleDataManager.dungeonId].battleBg
        bgPath = "BG/Battle/"..fileName..".png"
        NodeHelper:setSpriteImage(container,{ mFightNumBg = "BattleTeam_Img02_2.png" })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        local cfg = ConfigManager.getSingleBoss()[tonumber(NgBattleDataManager.SingleBossId)]
        local fileName = cfg.BattleBg
        bgPath = "BG/Battle/"..fileName..".png"
        NodeHelper:setSpriteImage(container,{ mFightNumBg = "BattleTeam_Img02_2.png" })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local cfg = ConfigManager:get191StageCfg()
        local fileName = cfg[NgBattleDataManager.dungeonId].battleBg
        bgPath = "BG/Battle/"..fileName..".png"
        NodeHelper:setSpriteImage(container,{ mFightNumBg = "BattleTeam_Img02_2.png" })
    end
	NodeHelper:setSpriteImage(container, { mBg = bgPath })
    local GuideManager = require("Guide.GuideManager")
    if not GuideManager.isInGuide then
        container:runAnimation("OpenAni")
    end
end

function NgBattleEditTeamPage:refreshPage(container)
    container.mScrollView = container:getVarScrollView("mContentHero")
    container.mScrollView:removeAllCell()
    self:buildScrollView(container)
    self:buildDefaultTeam(container)
end

function NgBattleEditTeamPage:initEnemy(container)
    if not NgBattleDataManager.serverEnemyInfo then return end
    for i = 1, CONST.ENEMY_COUNT do
        if NgBattleDataManager.serverEnemyInfo[i] then
            local spineNode = container:getVarNode("mSpine" .. NgBattleDataManager.serverEnemyInfo[i].posId)
            if spineNode then
                spineNode:removeAllChildrenWithCleanup(true)
                -- 判斷是什麼類型的敵人
                if NgBattleDataManager.serverEnemyInfo[i].type == Const_pb.MERCENARY or   -- Hero
                       NgBattleDataManager.serverEnemyInfo[i].type == Const_pb.RETINUE then   -- Free Hero
                    local cfg = heroCfg[tonumber(NgBattleDataManager.serverEnemyInfo[i].itemId)]
                    if cfg then
                        local spinePath, spineName = unpack(common:split(cfg.Spine, ","))
                        local spine = SpineContainer:create(spinePath, spineName .. string.format("%03d", NgBattleDataManager.serverEnemyInfo[i].skinId))
                        spine:runAnimation(1, CONST.ANI_ACT.WAIT, -1)
                        local sNode = tolua.cast(spine, "CCNode")
                        spineNode:addChild(sNode)
                    end
                elseif NgBattleDataManager.serverEnemyInfo[i].type == Const_pb.MONSTER or   -- Monster
                       NgBattleDataManager.serverEnemyInfo[i].type == Const_pb.WORLDBOSS then   -- WorldBoss
                    local monsterCfg = ConfigManager.getNewMonsterCfg()
                    local spinePath, spineName = unpack(common:split(monsterCfg[NgBattleDataManager.serverEnemyInfo[i].roleId].Spine, ","))
                    local enemySpine = SpineContainer:create(spinePath, spineName)
                    if monsterCfg[NgBattleDataManager.serverEnemyInfo[i].roleId].Skin then
                        enemySpine:setSkin("skin" .. string.format("%02d", monsterCfg[NgBattleDataManager.serverEnemyInfo[i].roleId].Skin))
                    end
                    enemySpine:runAnimation(1, CONST.ANI_ACT.WAIT, -1)
                    local sNode = tolua.cast(enemySpine, "CCNode")
                    if monsterCfg[NgBattleDataManager.serverEnemyInfo[i].roleId].Reflect == 1 then
                        sNode:setScaleX(-1)
                    end
                    spineNode:addChild(sNode)
                end
            end
        end
    end
end

function NgBattleEditTeamPage:buildScrollView(container)
    roleSortInfos = self:getSortMercenaryInfos()
    local count = 0
    for i = 1, #roleSortInfos do
        if roleSortInfos[i] and roleSortInfos[i].roleStage == 1 then
            count = count + 1
        end
    end
    count = #roleSortInfos

    if count <= 10 then
        container.mScrollView:setTouchEnabled(false)
    else
        container.mScrollView:setTouchEnabled(true)
    end

    for i = 1, count, 1 do
        local roleId = roleSortInfos[i].roleId
        local iconItem = NgHeadIconItem_Small:createCCBFileCell(roleId, i, container.mScrollView, GameConfig.NgHeadIconSmallType.BATTLE_EDITTEAM_PAGE, 
                                                                HEAD_SCALE, NgBattleEditTeamPage.onHeadCallback)
        local GuideManager = require("Guide.GuideManager")
        if roleSortInfos[i].itemId == 1 then
            GuideManager.PageContainerRef["NgBattleEditTeamFire1_cell"] = iconItem.cell
        end
        if roleSortInfos[i].itemId == 2 then
            GuideManager.PageContainerRef["NgBattleEditTeamFire2_cell"] = iconItem.cell
        end
        if roleSortInfos[i].itemId == 17 then
            GuideManager.PageContainerRef["NgBattleEditTeamWind5_cell"] = iconItem.cell
        end
        table.insert(items, iconItem)
    end
    container.mScrollView:orderCCBFileCells()
end

function NgBattleEditTeamPage:buildDefaultTeam(container)
    -- 預設隊伍
    local team = 1
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_FIGHT_TEAM then
        team = 1
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_DEFEND_TEAM then
        team = 8
    end
    local groupStr = CCUserDefault:sharedUserDefault():getStringForKey("GROUP_INFOS_"..team.."_" .. UserInfo.playerInfo.playerId)
    local defaultTeamInfo = { }
    defaultTeamInfo.roleIds = { }
    if groupStr and groupStr ~= "" then
        local groupInfo = common:split(groupStr, "_")
        for i = 2, #groupInfo - 1 do    -- 1是隊伍名稱
            defaultTeamInfo.roleIds[i - 1] = tonumber(groupInfo[i])
        end
    end
    -- 重設全部hero選擇狀態
    nowTeamRoleIds = { }
    if allSelectNode[selectId] then
        allSelectNode[selectId]:setVisible(false)
    end
    selectId = 0

    for i = 1, #defaultTeamInfo.roleIds do
        if i <= MAX_TEAM_NUM then
            local parentNode = container:getVarNode("mSpine" .. i)
            parentNode:removeAllChildrenWithCleanup(true)
            parentNode:setVisible(false)
            if defaultTeamInfo.roleIds[i] > 0 and i <= MAX_TEAM_NUM then
            -- 加入畫面顯示
                local info = mInfos[defaultTeamInfo.roleIds[i]]
                local spinePath, spineName = unpack(common:split(heroCfg[info.itemId].Spine, ","))
                local spine = SpineContainer:create(spinePath, spineName .. string.format("%03d", info.skinId))
                spine:setToSetupPose()
                spine:runAnimation(1, CONST.ANI_ACT.WAIT, -1)
                local spineNode = tolua.cast(spine, "CCNode")
                parentNode:addChild(spineNode)
                parentNode:setVisible(true)
            end
        end
        -- 加入隊伍資訊
        nowTeamRoleIds[i] = defaultTeamInfo.roleIds[i]
       
    end
    
    for i = 1, #items do
        local inTeamIdx = self:isInTeam(container, items[i].handler.roleId)
        NgHeadIconItem_Small:setIsChoose(items[i].handler, inTeamIdx > 0)
    end
end

function NgBattleEditTeamPage:isInTeam(container, roleId)
    for i = 1, #nowTeamRoleIds do
        if nowTeamRoleIds[i] == roleId then
            return i
        end
    end
    return 0
end

function NgBattleEditTeamPage:onHero(container, eventName)
    local idx = tonumber(eventName:sub(-1))
    if selectId > 0 and selectId <= MAX_TEAM_NUM then   -- 已有選擇過 --> 交換位置
        if allSelectNode[selectId] then
            allSelectNode[selectId]:setVisible(false)
            if selectId ~= idx then
                -- 交換場景顯示
                local parentNode1 = container:getVarNode("mSpine" .. selectId)           
                local parentNode2 = container:getVarNode("mSpine" .. idx)
                local child1 = nil
                local child2 = nil
                if parentNode1:getChildrenCount() > 0 then
                    child1 = parentNode1:getChildren():objectAtIndex(0)
                end
                if parentNode2:getChildrenCount() > 0 then
                    child2 = parentNode2:getChildren():objectAtIndex(0)     
                end
                if child1 then
                    child1:retain()
                    child1:removeFromParentAndCleanup(false)
                    parentNode2:addChild(child1)
                    parentNode2:setVisible(true)
                    child1:release()
                else
                    parentNode2:setVisible(false)
                end
                if child2 then
                    child2:retain()
                    child2:removeFromParentAndCleanup(false)
                    parentNode1:addChild(child2)
                    parentNode1:setVisible(true)
                    child2:release()
                else
                    parentNode1:setVisible(false)
                end
                -- 交換隊伍資訊
                local tempId = nowTeamRoleIds[selectId]
                nowTeamRoleIds[selectId] = nowTeamRoleIds[idx]
                nowTeamRoleIds[idx] = tempId
               
            end
        end
        selectId = 0
    else    -- 沒有選擇過 --> 開啟選擇框
        selectId = idx
        if allSelectNode[selectId] then
            allSelectNode[selectId]:setVisible(true)
        end
    end
end

function NgBattleEditTeamPage:onReturn(container)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.AFK)
        NgFightSceneHelper:EnterState(NgBattleDataManager.battlePageContainer, CONST.FIGHT_STATE.INIT)
        PageManager.popPage(thisPageName)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(48)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(21)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(45)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(49)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(51)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(52)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(53)
    else
        PageManager.popPage(thisPageName)
    end
    --PageManager.popPage(thisPageName)
end

function NgBattleEditTeamPage:onConfirm(container)
    require("NgBattlePage")
    local teamInfo = { }
    local saveInfo = { }
    local teamCount = 0
    saveInfo.roleIds = { }
    saveInfo.name = ""
    for i = 1, #nowTeamRoleIds do
        if nowTeamRoleIds[i] then
            if nowTeamRoleIds[i] > 0 then
                teamInfo[#teamInfo + 1] = nowTeamRoleIds[i] .. "_" .. i -- TODO 精靈也要加入隊伍資訊
                if i <= MAX_TEAM_NUM then
                    teamCount = teamCount + 1
                end
            end
            saveInfo.roleIds[i] = nowTeamRoleIds[i]
        else
            saveInfo.roleIds[i] = 0
        end
    end
    if teamCount <= 0 then
        MessageBoxPage:Msg_Box_Lan("@OrgTeamNumLimit")
        return
    end
    self:saveDefaultTeamInfo(saveInfo)
    NgBattleDataManager_setServerGroupInfo(saveInfo)
    NgBattlePageInfo_sendTeamInfoToServer(teamInfo)
    local HP_pb = require("HP_pb")
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
end

-- 展開/收起過濾按鈕
function NgBattleEditTeamPage:onFilter(container)
    local isShowClass = container:getVarNode("mFilter"):isVisible()
    --local filterBg = container:getVarScale9Sprite("mFilterBg")
    if isShowClass then
        NodeHelper:setNodesVisible(container,{mFilter = false})
    else
        NodeHelper:setNodesVisible(container,{mFilter = true})
    end
end
-- 過濾職業
function NgBattleEditTeamPage:onClass(container, eventName)
    currentClass = tonumber(eventName:sub(-1))
    if items then
        for i = 1, #items do
            local isVisible = (currentElement == items[i].handler.element or currentElement == 0) and
                              (currentClass == items[i].handler.class or currentClass == 0)
            items[i].cell:setVisible(isVisible)
            items[i].cell:setContentSize(isVisible and headIconSize or CCSize(0, 0))
        end
    end
    for i = 0, 4 do
        container:getVarSprite("mClass" .. i):setVisible(currentClass == i)
    end
    container.mScrollView:orderCCBFileCells()
end
-- 過濾屬性
function NgBattleEditTeamPage:onElement(container, eventName)
    currentElement = tonumber(eventName:sub(-1))
    if items then
        for i = 1, #items do
            local isVisible = (currentElement == items[i].handler.element or currentElement == 0) and
                              (currentClass == items[i].handler.class or currentClass == 0)
            items[i].cell:setVisible(isVisible)
            items[i].cell:setContentSize(isVisible and headIconSize or CCSize(0, 0))
        end
    end
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(currentElement == i)
    end
    container.mScrollView:orderCCBFileCells()
end

function NgBattleEditTeamPage:saveDefaultTeamInfo(groupInfo)
    local groupStr = groupInfo.name .. "_"
    for i = 1, #groupInfo.roleIds do
        groupStr = groupStr .. groupInfo.roleIds[i] .. "_"
    end
    local team = 1
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_FIGHT_TEAM then
        team = 1
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_DEFEND_TEAM then
        team = 8
    end
    CCUserDefault:sharedUserDefault():setStringForKey("GROUP_INFOS_"..team.."_" .. UserInfo.playerInfo.playerId, groupStr)
end

function NgBattleEditTeamPage:getSortMercenaryInfos()
    local infos = UserMercenaryManager:getMercenaryStatusInfos()
    local tblsort = { }
    local tbldisorder = { }
    local index = 1
    for k, v in pairs(infos) do
        if v.type ~= Const_pb.RETINUE and v.roleStage == Const_pb.IS_ACTIVITE then 
            table.insert(tblsort, v)
            tbldisorder[v.roleId] = v
            tbldisorder[v.roleId].index = index
            index = index + 1
        end
    end

    if #tblsort > 0 then
        table.sort(tblsort, function(info1, info2)
            if info1 == nil or info2 == nil then
                return false
            end
            local mInfo = UserMercenaryManager:getUserMercenaryInfos()
            local mInfo1 = mInfo[info1.roleId]
            local mInfo2 = mInfo[info2.roleId]
            if mInfo1 == nil then
                return false
            end
            if mInfo2 == nil then
                return true
            end
            if (info1.status == Const_pb.FIGHTING) and (info2.status ~= Const_pb.FIGHTING) then
                return true
            elseif (info1.status ~= Const_pb.FIGHTING) and (info2.status == Const_pb.FIGHTING) then
                return false
            elseif mInfo1.level ~= mInfo2.level then
                return mInfo1.level > mInfo2.level
            elseif mInfo1.starLevel ~= mInfo2.starLevel then
                return mInfo1.starLevel > mInfo2.starLevel
            elseif mInfo1.fight ~= mInfo2.fight then
                return mInfo1.fight > mInfo2.fight
            elseif mInfo1.singleElement ~= mInfo2.singleElement then
                return mInfo1.singleElement < mInfo2.singleElement
            end
            return false
        end )
    end

    return tblsort--, tbldisorder
end

function NgBattleEditTeamPage_getFirstTeamEmptyPosDesc()
    local pos = 1
    for i = 1, 5 do
        local truePos = ((i + 2) > 5) and (i - 3) or (i + 2)
        if nowTeamRoleIds[truePos] == 0 then
            pos = truePos
            break
        end
    end
    return pos
end

function NgBattleEditTeamPage_getWind5TeamPosDesc()
    local pos = 1
    for i = 1, 5 do
        if nowTeamRoleIds[i] ~= 0 then
            local info = mInfos[nowTeamRoleIds[i]]
            if info.itemId == 17 then
                pos = i
                break
            end
        end
    end
    return pos
end

function NgBattleEditTeamPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.EDIT_FORMATION_S then
        -- 編輯隊伍
        local msg = Formation_pb.HPFormationUseRes()
        msg:ParseFromString(msgBuff)
        MessageBoxPage:Msg_Box(common:getLanguageString("@OrgTeamFinish"))
        if NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_DEFEND_TEAM then
            require("ArenaPage")
            ArenaPage_Reset()
            local msg = MsgMainFrameRefreshPage:new()
            msg.pageName = "ArenaPage"
            msg.extraParam = "EditTeam"
            MessageManager:getInstance():sendMessageForScript(msg)
        end
         PageManager.popPage(thisPageName)
    end
end
function NgBattleEditTeamPage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
----------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local editTeamPage = CommonPage.newSub(NgBattleEditTeamPage, thisPageName, option)

return editTeamPage