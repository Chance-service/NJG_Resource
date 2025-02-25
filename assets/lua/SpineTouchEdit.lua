local NodeHelper = require("NodeHelper")
local thisPageName = "SpineTouchEdit"
require("MainScenePage")
require("Battle.NewBattleConst")
require("Battle.NgBattleDataManager")
require("Battle.NewBattleUtil")

local SpineTouchEdit = { }

local mMonsterData = ConfigManager.getNewMonsterCfg()

local mEditInputType = 0
local mSelectPos = 0

local option = {
    ccbiFile = "SpineTouch.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        -- TEST BATTLE
        onMapId = "onMapId",
        onMapAdd1 = "onMapAdd1", onMapAdd10 = "onMapAdd10", onMapAdd100 = "onMapAdd100",
        onMapMinus1 = "onMapMinus1", onMapMinus10 = "onMapMinus10", onMapMinus100 = "onMapMinus100",
        onPos10 = "onPos", onPos11 = "onPos", onPos12 = "onPos", onPos13 = "onPos", onPos14 = "onPos", onPos15 = "onPos", 
        onTestBattle = "onTestBattle",
        -- SETTING
        onFriendPause = "onFriendPause", onEnemyPause = "onEnemyPause",
        onFriendAttackAdd = "onFriendAttackAdd", onFriendAttackMinus = "onFriendAttackMinus", 
        onEnemyAttackAdd = "onEnemyAttackAdd", onEnemyAttackMinus = "onEnemyAttackMinus",
        onFriendDefenseAdd = "onFriendDefenseAdd", onFriendDefenseMinus = "onFriendDefenseMinus", 
        onEnemyDefenseAdd = "onEnemyDefenseAdd", onEnemyDefenseMinus = "onEnemyDefenseMinus",
        onFriendHpAdd = "onFriendHpAdd", onFriendHpMinus = "onFriendHpMinus", 
        onEnemyHpAdd = "onEnemyHpAdd", onEnemyHpMinus = "onEnemyHpMinus",
        onBattleTimeAdd = "onBattleTimeAdd", onBattleTimeMinus = "onBattleTimeMinus",
        onResetSetting = "onResetSetting",
        -- EFFECT SETTING
        onCloseFx = "onCloseFx", onCloseBuff = "onCloseBuff",
        onCloseHit = "onCloseHit", onCloseSound = "onCloseSound", 
        onCloseNum = "onCloseNum",

        luaonCloseKeyboard = "luaonCloseKeyboard", luaInputboxEnter = "onInputboxEnter",
    },
    opcodes =
    {
        BATTLE_FORMATION_C = HP_pb.BATTLE_FORMATION_C,
        BATTLE_FORMATION_S = HP_pb.BATTLE_FORMATION_S,
    }
}

SpineTouchEdit.editBox = nil
local mapInput = 0

function SpineTouchEdit:onEnter(container)
    self.container = container
    SpineTouchEdit.container = container
    SpineTouchEdit.container:registerMessage(MSG_MAINFRAME_REFRESH)
    mEditInputType = 0
    -- TEST BATTLE
    mSelectPos = 0
    for i = 10, 15 do
        NodeHelper:setStringForTTFLabel(container, { ["mPos" .. i] = "" })
    end

    self:registerPacket(container)
    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())

    NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)

    self:refreshSetting(container)

    --if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
    --    SpineTouchEdit.editBox = NodeHelper:addEditBox(CCSize(100, 50), container:getVarNode("mMapId"), function(eventType)
    --        --if eventType == "began" then
    --        --    SpineTouchEdit.editBox:setText(mapInput)
    --        --elseif eventType == "ended" then
    --        --    SpineTouchEdit.onEditBoxReturn(container, SpineTouchEdit.editBox, SpineTouchEdit.editBox:getText())
    --        --elseif eventType == "changed" then
    --        --    SpineTouchEdit.onEditBoxReturn(container, SpineTouchEdit.editBox, SpineTouchEdit.editBox:getText(), true)
    --        --elseif eventType == "return" then
    --        --    SpineTouchEdit.onEditBoxReturn(container, SpineTouchEdit.editBox, SpineTouchEdit.editBox:getText())
    --        --end
    --    end , ccp(0, 0), "--")
    --    --container:getVarNode("mMapId"):setVisible(false)
    --    NodeHelper:setStringForTTFLabel(container, { mMapId = "0" })
    --
    --    SpineTouchEdit.editBox:setText("")
    --
    --    NodeHelper:setMenuItemEnabled(container, "mMapBtn", false)
    --end
end

-----------------------------------------------------------------------
-- TEST BATTLE
function SpineTouchEdit:onMapAdd1(container)
    mapInput = tonumber(mapInput) and tonumber(mapInput) or 0
    mapInput = mapInput + 1
    NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
end
function SpineTouchEdit:onMapAdd10(container)
    mapInput = tonumber(mapInput) and tonumber(mapInput) or 0
    mapInput = mapInput + 10
    NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
end
function SpineTouchEdit:onMapAdd100(container)
    mapInput = tonumber(mapInput) and tonumber(mapInput) or 0
    mapInput = mapInput + 100
    NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
end
function SpineTouchEdit:onMapMinus1(container)
    mapInput = tonumber(mapInput) and tonumber(mapInput) or 0
    mapInput = math.max(mapInput - 1, 0)
    NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
end
function SpineTouchEdit:onMapMinus10(container)
    mapInput = tonumber(mapInput) and tonumber(mapInput) or 0
    mapInput = math.max(mapInput - 10, 0)
    NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
end
function SpineTouchEdit:onMapMinus100(container)
    mapInput = tonumber(mapInput) and tonumber(mapInput) or 0
    mapInput = math.max(mapInput - 100, 0)
    NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
end
function SpineTouchEdit:onMapId(container, eventName)
    container:registerLibOS()
    libOS:getInstance():showInputbox(false, 2, "")
    --NodeHelper:setNodesVisible(container, { mMapIdBg = true })
    NodeHelper:cursorNode(container, "mMapId", true) 
end
--- SETTING
function SpineTouchEdit:refreshSetting(container)
    NodeHelper:setNodesVisible(container, { mFriendPauseOn = (not NgBattleDataManager.testFriendUpdate),
                                            mEnemyPauseOn = (not NgBattleDataManager.testEnemyUpdate) })
    NodeHelper:setStringForLabel(container, { mFriendAttackRatio = NgBattleDataManager.testFriendAttackRatio,
                                              mEnemyAttackRatio = NgBattleDataManager.testEnemyAttackRatio,
                                              mFriendDefenseRatio = NgBattleDataManager.testFriendDefenseRatio,
                                              mEnemyDefenseRatio = NgBattleDataManager.testEnemyDefenseRatio,
                                              mFriendHpRatio = NgBattleDataManager.testFriendHpRatio,
                                              mEnemyHpRatio = NgBattleDataManager.testEnemyHpRatio,
                                              mBattleTime = tonumber(NgBattleDataManager.testBatteTime / 1000) })
    NodeHelper:setNodesVisible(container, { mCloseFxOn = NgBattleDataManager.testCloseFx,
                                            mCloseBuffOn = NgBattleDataManager.testCloseBuff,
                                            mCloseHitOn = NgBattleDataManager.testCloseHit,
                                            mCloseSoundOn = NgBattleDataManager.testCloseSound,
                                            mCloseNumOn = NgBattleDataManager.testCloseNum })
end
function SpineTouchEdit:onFriendPause(container)
    NgBattleDataManager.testFriendUpdate = not NgBattleDataManager.testFriendUpdate
    if not NgBattleDataManager.testFriendUpdate then
        NgBattleDataManager.testEnemyUpdate = true
    end
    NodeHelper:setNodesVisible(container, { mFriendPauseOn = (not NgBattleDataManager.testFriendUpdate),
                                            mEnemyPauseOn = (not NgBattleDataManager.testEnemyUpdate) })
end
function SpineTouchEdit:onEnemyPause(container)
    NgBattleDataManager.testEnemyUpdate = not NgBattleDataManager.testEnemyUpdate
    if not NgBattleDataManager.testEnemyUpdate then
        NgBattleDataManager.testFriendUpdate = true
    end
    NodeHelper:setNodesVisible(container, { mFriendPauseOn = (not NgBattleDataManager.testFriendUpdate),
                                            mEnemyPauseOn = (not NgBattleDataManager.testEnemyUpdate) })
end
function SpineTouchEdit:onFriendAttackAdd(container)
    NgBattleDataManager.testFriendAttackRatio = NgBattleDataManager.testFriendAttackRatio + 1
    NodeHelper:setStringForLabel(container, { mFriendAttackRatio = NgBattleDataManager.testFriendAttackRatio })
end
function SpineTouchEdit:onFriendAttackMinus(container)
    NgBattleDataManager.testFriendAttackRatio = math.max(NgBattleDataManager.testFriendAttackRatio - 1, 0)
    NodeHelper:setStringForLabel(container, { mFriendAttackRatio = NgBattleDataManager.testFriendAttackRatio })
end
function SpineTouchEdit:onEnemyAttackAdd(container)
    NgBattleDataManager.testEnemyAttackRatio = NgBattleDataManager.testEnemyAttackRatio + 1
    NodeHelper:setStringForLabel(container, { mEnemyAttackRatio = NgBattleDataManager.testEnemyAttackRatio })
end
function SpineTouchEdit:onEnemyAttackMinus(container)
    NgBattleDataManager.testEnemyAttackRatio = math.max(NgBattleDataManager.testEnemyAttackRatio - 1, 0)
    NodeHelper:setStringForLabel(container, { mEnemyAttackRatio = NgBattleDataManager.testEnemyAttackRatio })
end
function SpineTouchEdit:onFriendDefenseAdd(container)
    NgBattleDataManager.testFriendDefenseRatio = NgBattleDataManager.testFriendDefenseRatio + 1
    NodeHelper:setStringForLabel(container, { mFriendDefenseRatio = NgBattleDataManager.testFriendDefenseRatio })
end
function SpineTouchEdit:onFriendDefenseMinus(container)
    NgBattleDataManager.testFriendDefenseRatio = math.max(NgBattleDataManager.testFriendDefenseRatio - 1, 0)
    NodeHelper:setStringForLabel(container, { mFriendDefenseRatio = NgBattleDataManager.testFriendDefenseRatio })
end
function SpineTouchEdit:onEnemyDefenseAdd(container)
    NgBattleDataManager.testEnemyDefenseRatio = NgBattleDataManager.testEnemyDefenseRatio + 1
    NodeHelper:setStringForLabel(container, { mEnemyDefenseRatio = NgBattleDataManager.testEnemyDefenseRatio })
end
function SpineTouchEdit:onEnemyDefenseMinus(container)
    NgBattleDataManager.testEnemyDefenseRatio = math.max(NgBattleDataManager.testEnemyDefenseRatio - 1, 0)
    NodeHelper:setStringForLabel(container, { mEnemyDefenseRatio = NgBattleDataManager.testEnemyDefenseRatio })
end
function SpineTouchEdit:onFriendHpAdd(container)
    NgBattleDataManager.testFriendHpRatio = NgBattleDataManager.testFriendHpRatio + 1
    NodeHelper:setStringForLabel(container, { mFriendHpRatio = NgBattleDataManager.testFriendHpRatio })
end
function SpineTouchEdit:onFriendHpMinus(container)
    NgBattleDataManager.testFriendHpRatio = math.max(NgBattleDataManager.testFriendHpRatio - 1, 1)
    NodeHelper:setStringForLabel(container, { mFriendHpRatio = NgBattleDataManager.testFriendHpRatio })
end
function SpineTouchEdit:onEnemyHpAdd(container)
    NgBattleDataManager.testEnemyHpRatio = NgBattleDataManager.testEnemyHpRatio + 1
    NodeHelper:setStringForLabel(container, { mEnemyHpRatio = NgBattleDataManager.testEnemyHpRatio })
end
function SpineTouchEdit:onEnemyHpMinus(container)
    NgBattleDataManager.testEnemyHpRatio = math.max(NgBattleDataManager.testEnemyHpRatio - 1, 1)
    NodeHelper:setStringForLabel(container, { mEnemyHpRatio = NgBattleDataManager.testEnemyHpRatio })
end
function SpineTouchEdit:onBattleTimeAdd(container)
    NgBattleDataManager.testBatteTime = NgBattleDataManager.testBatteTime + 10 * 1000
    NodeHelper:setStringForLabel(container, { mBattleTime = tonumber(NgBattleDataManager.testBatteTime / 1000) })
end
function SpineTouchEdit:onBattleTimeMinus(container)
    NgBattleDataManager.testBatteTime = math.max(NgBattleDataManager.testBatteTime - 10 * 1000, 10000)
    NodeHelper:setStringForLabel(container, { mBattleTime = tonumber(NgBattleDataManager.testBatteTime / 1000) })
end
function SpineTouchEdit:onResetSetting(container)
    NgBattleDataManager.testFriendUpdate = true
    NgBattleDataManager.testEnemyUpdate = true
    NgBattleDataManager.testFriendAttackRatio = 1
    NgBattleDataManager.testEnemyAttackRatio = 1
    NgBattleDataManager.testFriendDefenseRatio = 1
    NgBattleDataManager.testEnemyDefenseRatio = 1
    NgBattleDataManager.testBatteTime = 90000
    self:refreshSetting(container)
end
--
function SpineTouchEdit:onCloseFx(container)
    NgBattleDataManager.testCloseFx = not NgBattleDataManager.testCloseFx
    NodeHelper:setNodesVisible(container, { mCloseFxOn = NgBattleDataManager.testCloseFx })
end
function SpineTouchEdit:onCloseBuff(container)
    NgBattleDataManager.testCloseBuff = not NgBattleDataManager.testCloseBuff
    NodeHelper:setNodesVisible(container, { mCloseBuffOn = NgBattleDataManager.testCloseBuff })
end
function SpineTouchEdit:onCloseHit(container)
    NgBattleDataManager.testCloseHit = not NgBattleDataManager.testCloseHit
    NodeHelper:setNodesVisible(container, { mCloseHitOn = NgBattleDataManager.testCloseHit })
end
function SpineTouchEdit:onCloseSound(container)
    NgBattleDataManager.testCloseSound = not NgBattleDataManager.testCloseSound
    NodeHelper:setNodesVisible(container, { mCloseSoundOn = NgBattleDataManager.testCloseSound })
end
function SpineTouchEdit:onCloseNum(container)
    NgBattleDataManager.testCloseNum = not NgBattleDataManager.testCloseNum
    NodeHelper:setNodesVisible(container, { mCloseNumOn = NgBattleDataManager.testCloseNum })
end
---
function SpineTouchEdit:onTestBattle(container, eventName)
    local msg = Battle_pb.NewBattleFormation()
    msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
    msg.battleType = NewBattleConst.SCENE_TYPE.TEST_BATTLE
    local enemyFormation = ""
    for i = 10, 15 do
        local id = container:getVarLabelTTF("mPos" .. i):getString()
        if id and tonumber(id) and mMonsterData[tonumber(id)] then
            enemyFormation = enemyFormation .. id .. "_" .. i .. (i == 15 and "" or ",")
        else
            enemyFormation = enemyFormation .. 0 .. "_" .. i .. (i == 15 and "" or ",")
        end
    end
    msg.mapId = enemyFormation
    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
end
-----------------------------------------------------------------------
function SpineTouchEdit:onClose(container)
    PageManager.popPage(thisPageName)
end
--------------------------------------------------------------------
function SpineTouchEdit:onInputboxEnter(container)
    mapInput = container:getInputboxContent()

    NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
end
function SpineTouchEdit.onEditBoxReturn(container, editBox, content, isChange)
    --mapInput = container:getInputboxContent()
    --
    --NodeHelper:setStringForTTFLabel(container, { mMapId = mapInput })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
end
function SpineTouchEdit:luaonCloseKeyboard(container)
    CCLuaLog("-----luaonCloseKeyboard")
    --NodeHelper:setNodesVisible(container, { mMapIdBg = false })
    SpineTouchEdit:setMapPos(container, tonumber(mapInput), 3)
    NodeHelper:cursorNode(container, "mMapId", false)
end
function SpineTouchEdit:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function SpineTouchEdit:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-- 接收服务器回包
function SpineTouchEdit:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            local battlePage = require("NgBattlePage")
            NgBattleDataManager_setBattleType(NewBattleConst.SCENE_TYPE.TEST_BATTLE)
            battlePage:onTestBattle(container, msg.resultInfo, msg.battleId, msg.battleType)
            SpineTouchEdit:onClose(container)
        end
    end
end
-------------------------------------------------------
function SpineTouchEdit:setMapPos(container, id, editType)
    --if editType == 3 then
        local cfg = ConfigManager:getNewMapCfg()
        if not id or not cfg[id] then
            return
        end
        local ids = common:split(cfg[id].BossID, ",")
        for i = 1, #ids do
            NodeHelper:setStringForTTFLabel(container, { ["mPos" .. (i + 9)] = ids[i] })
        end
    --elseif editType == 4 then
    --    return
    --end
end

local CommonPage = require("CommonPage")
SpineTouchEditLLL = CommonPage.newSub(SpineTouchEdit, thisPageName, option)