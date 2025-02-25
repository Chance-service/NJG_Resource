local UserInfo = {
    playerInfo = { },
    roleInfo = { },
    stateInfo = { },
    smeltInfo = { },
    serverId = GamePrecedure:getInstance():getServerID(),
    level = 0,
    wingLevel = 0,
    wingLucky = 0,
    skillUnlock =
    {
        level = 0,
        -- 技能槽开放等级
        hasNew = false
    },
    guideInfo =
    {
        Gift = false,
        Equip = false,
        Help = false
    },
    isMainPageLoad = false,
    -- 主界面是否加载完毕
    isShowLevelUp = false,
    -- 是否升级，数据收包完毕后播放动画
    isShowReBorn = false,-- 是否显示转生动画
    isUseLottery = false,   --是否使用彩票
    isLuckDraw_124 = false, --是否已经抽过活动124的奖励
    isShowActivity134Icon = false,   --是不是主界面134活动icon
    isPlayStory = false -- 是否播完新手動畫
};

--------------------------------------------------------------------------------
local Player_pb = require("Player_pb");
local Const_pb = require("Const_pb");

local PBHelper = require("PBHelper");


------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
function UserInfo.sync()
    UserInfo.serverId = GamePrecedure:getInstance():getServerID()
    UserInfo.syncPlayerInfo()
    UserInfo.syncRoleInfo()
    -- UserInfo.serverId = GamePrecedure:getInstance():getServerID()
    UserInfo.syncStateInfo()
    serverId = GamePrecedure:getInstance():getServerID()
end

function UserInfo.syncPlayerInfo()
    local msgStr = ServerDateManager:getInstance():getUserBasicInfoForLua();
    local msg = Player_pb.PlayerInfo();
    if msgStr ~= "" then
        msg:ParseFromString(msgStr);
        local oldGold = UserInfo.playerInfo.gold
        local oldVipLevel = UserInfo.playerInfo.vipLevel
        UserInfo.playerInfo = msg;
        if (oldGold and oldGold ~= UserInfo.playerInfo.gold) or(oldVipLevel and oldVipLevel ~= UserInfo.playerInfo.vipLevel) then
            if string.find(GamePrecedure:getInstance():getPlatformName(), "entermate") then
                libOS:getInstance():OnUserInfoChange(UserInfo.playerInfo.playerId, UserInfo.roleInfo.name, UserInfo.serverId, UserInfo.roleInfo.level, UserInfo.roleInfo.exp, UserInfo.playerInfo.vipLevel, UserInfo.playerInfo.gold)
            end
        end
    end
end


function UserInfo.syncRoleInfo()
    local msgStr = ServerDateManager:getInstance():getUserRoleInfoForLua();
    local oldExp = UserInfo.roleInfo.exp
    local oldMasterFight = UserInfo.roleInfo.marsterFight or 0
    if msgStr ~= "" then
        local msg = Player_pb.RoleInfo();
        msg:ParseFromString(msgStr);
        UserInfo.roleInfo = msg;
    else
        return
    end
    --如果上次更新了战力值 这次没有更新 用上次的值
    if tonumber(oldMasterFight) >= tonumber(UserInfo.roleInfo.marsterFight)  then
       UserInfo.roleInfo.marsterFight = oldMasterFight
    end
    if UserInfo.roleInfo.exp < 0 then
        -- 经验超int处理
        UserInfo.roleInfo.exp = 2147483648 +(UserInfo.roleInfo.exp + 2147483648)
    end
    local newExp = UserInfo.roleInfo.exp
    if oldExp and oldExp < newExp then
        -- MainFrame_RefreshExpBar()
    end
    --UserInfo.checkLevelUp()   -- 移至戰鬥結算時檢查
    --local level = UserInfo.roleInfo.level or 0
    --UserInfo.level = level
    if not UserInfo.level or UserInfo.level <= 0 then
        UserInfo.level = UserInfo.roleInfo.level
    end

    if UserInfo.roleName and(UserInfo.roleName ~= UserInfo.roleInfo.name) then
        UserInfo.roleName = UserInfo.roleInfo.name
        libPlatformManager:getPlatform():sendMessageG2P("G2P_CHANGE_ROLE_NAME",(UserInfo.roleName))
    else
        UserInfo.roleName = UserInfo.roleInfo.name
    end
end
function UserInfo.syncRoleinfoForlua(info)
    if info ~= nil then
        UserInfo.roleInfo = info
        --UserInfo.checkLevelUp()
        --local level = UserInfo.roleInfo.level or 0
        --UserInfo.level = level
        if not UserInfo.level or UserInfo.level <= 0 then
            UserInfo.level = UserInfo.roleInfo.level
        end
    end
end
--接收Role_S时重新设置RoleInfo的总战力 正规讲应该每次都传主角的Role和其他有变化的Role的信息
function UserInfo.setRoleMasterFight(info)
    if  info~= nil and UserInfo.roleInfo then
       if UserInfo.roleInfo.marsterFight and tonumber(UserInfo.roleInfo.marsterFight) <= tonumber(info.marsterFight)  then
            UserInfo.roleInfo.marsterFight = info.marsterFight
       end
    end
end
function UserInfo.syncStateInfo()
    -- Player State 目前直接从lua里读取，不从c++中获得了
    --[[local msgStr = ServerDateManager:getInstance():getPlayerStateForLua();
	local msg = Player_pb.HPPlayerStateSync();
	msg:ParseFromString(msgStr);
	UserInfo.stateInfo = msg;--]]


     -- Player State 目前直接从lua里读取，不从c++中获得了
    --local msgStr = ServerDateManager:getInstance():getPlayerStateForLua()
	--local msg = Player_pb.HPPlayerStateSync()
	--msg:ParseFromString(msgStr)
	--UserInfo.stateInfo = msg
end


function UserInfo.checkLevelUp(isCheck)
    local level = UserInfo.roleInfo.level or 0
    if isCheck then
        if UserInfo.level < level and UserInfo.level ~= 0 then
            return true
        end
        return false
    end
    if UserInfo.level < level and UserInfo.level ~= 0 then
        local LevelUpPageBase = require("LevelUpPage")
        LevelUpPageBase_setTitle(UserInfo.level, level)
        libPlatformManager:getPlatform():sendMessageG2P("G2P_Level_Up", tostring(level))
        -- play levelup timeline
        -- GameUtil:sendUserData(level,UserInfo.stateInfo.curBattleMap)	
        if string.find(GamePrecedure:getInstance():getPlatformName(), "entermate") then
            libOS:getInstance():OnUserInfoChange(UserInfo.playerInfo.playerId, UserInfo.roleInfo.name, UserInfo.serverId, UserInfo.roleInfo.level, UserInfo.roleInfo.exp, UserInfo.playerInfo.vipLevel, UserInfo.playerInfo.gold)
        end

        local GuideManager = require("Guide.GuideManager")
        --GuideManager.newbieGuide()
        if UserInfo.isMainPageLoad then
            --if not GuideManager.isInGuide then
                GameUtil:showLevelUpAni()
                --NodeHelper:playMusic("Offline login_01.mp3")
            --end
        else
            UserInfo.isShowLevelUp = true
        end
        UserInfo.level = UserInfo.roleInfo.level or 0
        --local UserEquipManager = require("Equip.UserEquipManager")
        --UserEquipManager:syncLevelUpEquipInfo()
        return true
    else
        return false
    end
end	

function UserInfo.reset()
    UserInfo.roleInfo.level = 0;
    UserInfo.level = 0;
    UserInfo.wingLevel = 0;
    UserInfo.wingLucky = 0;
    UserInfo.skillUnlock = {
        level = 0,
        hasNew = false
    };
    PageManager.showRedNotice("Skill", false);
    UserInfo.guideInfo = {
        Gift = false,
        Equip = false,
        Help = false
    };
end
--------------------------------------------------------------------------------

function UserInfo.getVipString()
    return "VIP " ..(UserInfo.playerInfo.vipLevel or 0);
end

function UserInfo.getVipImage()
    return string.format(GameConfig.Image.Vip, UserInfo.playerInfo.vipLevel or 0);
end

function UserInfo.getRoleAttrById(attrId)
    return PBHelper:getAttrById(UserInfo.roleInfo.attribute.attribute, attrId);
end

function UserInfo.getDamageString()
    return(UserInfo.getRoleAttrById(Const_pb.MINDMG) .. "-"
    .. UserInfo.getRoleAttrById(Const_pb.MAXDMG));
end

function UserInfo.getEquipByPart(part)
    return PBHelper:getRoleEquipByPart(UserInfo.roleInfo.equips, part);
end	

function UserInfo.hasEquipInRole()
    if UserInfo.roleInfo.exp == nil then
        UserInfo.syncRoleInfo();
    end
    local roleEquipSize = 0 

    if UserInfo.roleInfo and UserInfo.roleInfo.equips then
       roleEquipSize = #UserInfo.roleInfo.equips
    end
   
    if roleEquipSize > 0 then
        UserInfo.guideInfo.Equip = false;
        return true
    else
        if UserInfo.guideInfo.Equip then
            UserInfo.guideInfo.Help = true;
        end
        return false
    end
end	

function UserInfo.getProfessionName()
    if UserInfo.isChangeStage() then
        return common:getLanguageString("@NewProfessionName_" .. UserInfo.roleInfo.prof);
    else
        return common:getLanguageString("@ProfessionName_" .. UserInfo.roleInfo.prof);
    end
end

function UserInfo.getProfession()
    return UserInfo.roleInfo.prof
end

-- 判断金币够不够，不够提示购买
function UserInfo.isCoinEnough(need)
    local need = tonumber(need or 0);
    UserInfo.syncPlayerInfo()
    if UserInfo.playerInfo.coin < need then
    MessageBoxPage:Msg_Box_Lan("@ERRORCODE_25")
        --PageManager.notifyLackCoin();
        return false;
    end
    return true;
end

-- 判断钻石够不够，不够提示购买
function UserInfo.isGoldEnough(need, event)
    local need = tonumber(need or 0);
    UserInfo.syncPlayerInfo()
    if UserInfo.playerInfo.gold < need then
        --PageManager.notifyLackGold(event);
         MessageBoxPage:Msg_Box_Lan("@ERRORCODE_14")
        return false;
    end
    return true;
end
function UserInfo.isCrystalEnough(need)
    local need = tonumber(need or 0);
    UserInfo.syncPlayerInfo()
    if UserInfo.playerInfo.crystal < need then
        MessageBoxPage:Msg_Box_Lan("@ERRORCODE_25")
        return false;
    end
    return true;
end
-- 判断VIP等级够不够
function UserInfo.isVIPEnough(need, event)
    local need = tonumber(need or 0);
    UserInfo.syncPlayerInfo()
    if UserInfo.playerInfo.vipLevel < need then
        PageManager.notifyLackVIP(event);
        return false;
    end
    return true;
end
function UserInfo.hasPassNewBeeFightBoss()
    local passedMapId = UserInfo.stateInfo.passMapId
    if passedMapId == 1 and NewBeeFightBossDone == true then
        return true
    else
        return false
    end
end

function UserInfo.isNewbeeInFightBoss()
    -- passMapId ==0 means has not fight boss ever since the first boss is been beaten as designed
    local passedMapId = UserInfo.stateInfo.passMapId
    local hasEquip = UserInfo.hasEquipInRole()
    if passedMapId == 0 and hasEquip == true then
        return true
    end
    return false;
end

function UserInfo.isNewbeeInFastFight()
    local passedMapId = UserInfo.stateInfo.passMapId
    if passedMapId == 1 and UserInfo.stateInfo.fastFightBuyTimes == 0 then
        return true
    end
    return false;
end

function UserInfo.hasPassGiftEquip()
    return not(UserInfo.guideInfo.Gift or UserInfo.guideInfo.Equip);
end

-- TODO：新手引导执行到哪一步
function UserInfo.isNewbieServerStateStep()
    UserInfo.syncStateInfo()
    local currentStep = UserInfo.stateInfo.newGuideState
    return currentStep
end


function UserInfo.hasFastFight()
    local passedMapId = UserInfo.stateInfo.passMapId
    if passedMapId > 1 or(passedMapId == 1 and UserInfo.stateInfo.fastFightBuyTimes > 0) then
        return true;
    end
    return false;
end	

-- 获取全身装备强化等级
function UserInfo.getAllEnhancedLevel(isViewingOther, _roleInfo)
    local roleInfo = nil
    if isViewingOther and _roleInfo then
        roleInfo = _roleInfo
    end

    if not roleInfo then
        roleInfo = isViewingOther and ViewPlayerInfo:getRoleInfo() or UserInfo.roleInfo;
    end

    if #roleInfo.equips < GameConfig.Count.PartTotal then return 0; end

    local allLevel = 1000;
    for _, roleEquip in ipairs(roleInfo.equips) do
        local level = roleEquip.strength;
        if level <= 0 then
            return 0;
        end
        if allLevel > level then
            allLevel = level;
        end
    end

    return allLevel;
end

-- 是否转生
function UserInfo.isChangeStage()
    UserInfo.sync()
    return false--tonumber(UserInfo.roleInfo.rebirthStage) > 0
end

-- 获取本人等级文字
function UserInfo.getStageAndLevelStr()
    -- common:getR2LVL() .. UserInfo.roleInfo.level
    local str = ""
    local stage = UserInfo.roleInfo.rebirthStage
    local level = UserInfo.roleInfo.level
    --if UserInfo.isChangeStage() then
    --    str = common:getLanguageString("@NewLevelStr", stage, level - 100)
    --else
        str = common:getLanguageString("@LevelStr", level)
    --end
    return str
end

-- 获取他人等级文字
function UserInfo.getOtherLevelStr(stage, level)
    local str = ""
    if stage ~= nil and stage > 0 then
        str = common:getLanguageString("@NewLevelStr", stage, level - 100)
    else
        str = common:getLanguageString("@LevelStr", level)
    end
    return str
end

-- 获取他人职业文字
function UserInfo.getOtherProfName(roleId, stage)
    local str = ""
    local prof = 0
    if roleId > 3 then
        prof = roleId - 3
    else
        prof = roleId
    end
    if stage > 0 then
        str = common:getLanguageString("@NewProfessionName_" .. prof);
    else
        str = common:getLanguageString("@ProfessionName_" .. prof);
    end
    return str
end

-- 这个账号是不是已经有过评论
function UserInfo.getIsComment()
    if UserInfo.isComment == nil then
        UserInfo.isComment = CCUserDefault:sharedUserDefault():getBoolForKey("isComment" .. "_" .. UserInfo.serverId .. "_" .. UserInfo.playerInfo.playerId)
        if UserInfo.isComment == nil or UserInfo.isComment == false or UserInfo.isComment == "" then
            CCUserDefault:sharedUserDefault():setBoolForKey("isComment" .. "_" .. UserInfo.serverId .. "_" .. UserInfo.playerInfo.playerId, false)
            CCUserDefault:sharedUserDefault():flush()
            UserInfo.isComment = false
        end
    end
    return UserInfo.isComment
end

function UserInfo.setIsComment(bl)
    if bl then
        UserInfo.isComment = bl
        CCUserDefault:sharedUserDefault():setBoolForKey("isComment" .. "_" .. UserInfo.serverId .. "_" .. UserInfo.playerInfo.playerId, bl)
        CCUserDefault:sharedUserDefault():flush();
    end
end

-- 十连抽是不是已经弹出过诱导评论
function UserInfo.getIsCommentForTenLuckDraw()
    if UserInfo.isCommentForTenLuckDraw == nil then
        UserInfo.isCommentForTenLuckDraw = CCUserDefault:sharedUserDefault():getBoolForKey("isCommentTenLuckDraw" .. "_" .. UserInfo.serverId .. "_" .. UserInfo.playerInfo.playerId)
        if UserInfo.isCommentForTenLuckDraw == nil or UserInfo.isCommentForTenLuckDraw == false or UserInfo.isCommentForTenLuckDraw == "" then
            CCUserDefault:sharedUserDefault():setBoolForKey("isCommentTenLuckDraw" .. "_" .. UserInfo.serverId .. "_" .. UserInfo.playerInfo.playerId, false)
            CCUserDefault:sharedUserDefault():flush()
            UserInfo.isCommentForTenLuckDraw = false
        end
    end
    return UserInfo.isCommentForTenLuckDraw
end

function UserInfo.setIsCommentForTenLuckDraw(bl)
    if bl then
        UserInfo.isCommentForTenLuckDraw = bl
        CCUserDefault:sharedUserDefault():setBoolForKey("isCommentTenLuckDraw" .. "_" .. UserInfo.serverId .. "_" .. UserInfo.playerInfo.playerId, bl)
        CCUserDefault:sharedUserDefault():flush()
        -- UserInfo.setIsComment(bl)
    end
end

--------------------------------------------------------------------------------
return UserInfo;