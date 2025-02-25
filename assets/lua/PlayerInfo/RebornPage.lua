

local thisPageName = "RebornPage"
local UserInfo = require("PlayerInfo.UserInfo")
local HP_pb = require("HP_pb")
local Talent_pb = require("Talent_pb")
local RebornAttrCfg = ConfigManager.getRebornAttrCfg()
local Const_pb = require("Const_pb")
local option = {
    ccbiFile = "FigureReincarnationDekaronPopUp.ccbi",
    handlerMap ={
        onDekaron   = "onChallenge",
        onHelp      = "onHelp",
        onClose     = "onClose",
        luaOnAnimationDone = "onAnimationDone",
    }
}

local RebornPageBase = {}
local isWin = false
--------------------------------------------------------------
function RebornPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:refreshPage(container)
end

function RebornPageBase:onExit(container)
    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
end

function RebornPageBase:onAnimationDone(container)
    local animationName=tostring(container:getCurAnimationDoneName())
	if animationName=="SuccessAni" then 
        PageManager.popPage(thisPageName)
        PageManager.changePage("NewMapPage")
    end
end

function RebornPageBase:refreshPage(container)
    UserInfo.sync()
    local info = self:getAttrInfoFromCfg(UserInfo.roleInfo.level ,UserInfo.roleInfo.prof)
    if info ~= nil then
        local lb2str = {
            mCurrentLevelNum1       = common:getLanguageString("@LevelStr", UserInfo.roleInfo.level),
            mCurrentLevelNum2       = common:getLanguageString("@NewLevelStr", 1, UserInfo.roleInfo.level-90),
            mOccupationNum1         = common:getLanguageString("@ProfessionName_" .. UserInfo.roleInfo.prof),
            mOccupationNum2         = common:getLanguageString("@NewProfessionName_" .. UserInfo.roleInfo.prof),
            mPowerNum1              = info.powerBefore,
            mPowerNum2              = info.powerAfter,
            mAgileNum1              = info.agilityBefore,
            mAgileNum2              = info.agilityAfter,
            mIntelligenceMagicNum1  = info.intelligenceBefore,
            mIntelligenceMagicNum2  = info.intelligenceAfter,
            mStamina1               = info.staminaBefore,
            mStamina2               = info.staminaAfter,
            mRebornContent          = common:getLanguageString("@RebornContent")
        }
        NodeHelper:setStringForLabel(container, lb2str)
        local lb2strNode = {
            mLevel1 = "mCurrentLevelNum1",
            mOccupation1 = "mOccupationNum1",
            mPower1 = "mPowerNum1",
            mAgile1 = "mAgileNum1",
            mIntelligenceMagic1 = "mIntelligenceMagicNum1",
            mStaminaTxt1 = "mStamina1",
            mLevel2 = "mCurrentLevelNum2",
            mOccupation2 = "mOccupationNum2",
            mPower2 = "mPowerNum2",
            mAgile2 = "mAgileNum2",
            mIntelligenceMagic2 = "mIntelligenceMagicNum2",
            mStaminaTxt2 = "mStamina2",
        }
        NodeHelper:setLabelMapOneByOne(container,lb2strNode,20,true)
    end

    -- spine
    local roleId = UserInfo.roleInfo.itemId;   
    local RoleManager = require("PlayerInfo.RoleManager")
	NodeHelper:setSpriteImage(container, {	
		mOccupation = RoleManager:getOccupationIconById(UserInfo.roleInfo.itemId)
	});
		
	
	if GameConfig.ShowSpineAvatar == false then 
		NodeHelper:setSpriteImage(container, {
		mHeroPic 	= RoleManager:getPosterById(roleId)
	});
	else
		local heroNode = container:getVarNode("mHero");
       
		if heroNode then
			local heroSprite = container:getVarSprite("mHeroPic")
			if heroSprite then
				heroSprite:setVisible(false)
			end	
			if heroNode:getChildByTag(10010) == nil then
				local spineCCBI = ScriptContentBase:create(GameConfig.SpineCCBI[roleId])
				spineCCBI:setTag(10010)
				heroNode:addChild(spineCCBI)
                --spine node
				local spineContainer = spineCCBI:getVarNode("mSpineNode");
				if spineContainer then
					spineContainer:removeAllChildren();
                    local spine = nil
                    local roleData = ConfigManager.getRoleCfg()[roleId]
                    local spinePath, spineName = unpack(common:split((roleData.spine), ","))
				    spine = SpineContainer:create(spinePath, spineName)
                    --end
					local spineNode = tolua.cast(spine, "CCNode");
					spineContainer:addChild(spineNode);
					spine:runAnimation(1, "Stand", -1);
				end
                --suit effect node 
--                local effectNode = spineCCBI:getVarNode("mEffectNode");
--				if effectNode then
--					effectNode:removeAllChildren();
--                    --judge if has suit effect in it
--                    local hasAni,aniName = UserEquipManager:getPlayerSuitAni();
--                    if hasAni then 
--                        local effectCCBI = ScriptContentBase:create("SuitAni.ccbi")
--					    effectNode:addChild(effectCCBI);
--                        effectCCBI:release()
--                        effectCCBI:runAnimation(aniName)
--                    end
--				end
				spineCCBI:release()		
			else
--				local spineNode  =  heroNode:getChildByTag(10010)
				
			end				
		end	
	end		
end

function RebornPageBase:getAttrInfoFromCfg(level ,prof)
    for _, info in pairs(RebornAttrCfg) do
        if info.level == level and info.profession == prof then
            return info
        end
    end
end

function RebornPageBase:onChallenge(container)
    common:sendEmptyPacket(HP_pb.REBIRTH_CHALLENGE_BOSS_C)
end

function RebornPageBase:onHelp(container)

end

function RebornPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function RebornPageBase:registerPacket(container)
    container:registerPacket(HP_pb.REBIRTH_CHALLENGE_BOSS_S)
end

function RebornPageBase:removePacket(container)
    container:removePacket(HP_pb.REBIRTH_CHALLENGE_BOSS_S)
end

function RebornPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.REBIRTH_CHALLENGE_BOSS_S then
        local msg = Talent_pb:HPChallengeBossRet()
        msg:ParseFromString(msgBuff)
        isWin = msg.isSuccess
        PageManager.viewBattlePage(msg.battleResult)
    end
end

function RebornPageBase:onReceiveMessage(container)
    local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			if isWin then
                container:runAnimation("SuccessAni")
            else
                MessageBoxPage:Msg_Box_Lan("@RebornFail")
            end
		end
	end
end 

--------------------------------------------------------------
local CommonPage = require("CommonPage");
local RebornPage = CommonPage.newSub(RebornPageBase, thisPageName, option);