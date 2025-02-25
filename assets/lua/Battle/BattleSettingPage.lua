----------------------------------------------------------------------------------
local Player_pb = require "Player_pb"
local HP_pb = require "HP_pb"
local UserInfo = require("PlayerInfo.UserInfo")
local NodeHelper = require("NodeHelper")

local thisPageName = "BattleSettingPage"

local option = {
	ccbiFile = "BattleSetUpPopUp.ccbi",
	handlerMap = {
		onSaveSettings = "onSaveSettings",
		onAddMusic = "onAddMusic",
        onReduceMusic = "onReduceMusic",
		onAddEffect = "onAddEffect",
        onReduceEffect = "onReduceEffect",
        onClose = "onClose",
    },
	opcode = opcodes
}

local BattleSettingPageBase = { }

local MAX_MUSIC_NUM = 10
local MAX_EFFECT_NUM = 10
local MAX_BAR_WIDTH = 250
local MAX_BAR_HEIGHT = 21
local music = 0
local effect = 0
-----------------------------------------------
--BattleSettingPageBase页面中的事件处理
----------------------------------------------
function BattleSettingPageBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    music = UserInfo.stateInfo.musicOn
	effect = UserInfo.stateInfo.soundOn
	self:refreshPage(container)
    self:refreshBtnState(container)
end

function BattleSettingPageBase:onExecute(container)
end

function BattleSettingPageBase:onExit(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
end
----------------------------------------------------------------

function BattleSettingPageBase:refreshPage(container)
	--UserInfo.syncStateInfo()
	self:onRefreshPage(container)
end
--
function BattleSettingPageBase:onRefreshPage(container)
    NodeHelper:setStringForLabel(container, { mMusicTxt = music, mEffectTxt = effect })
    local musicImg = container:getVarScale9Sprite("mMusicBar")
    musicImg:setContentSize(CCSize(MAX_BAR_WIDTH * music / MAX_MUSIC_NUM, MAX_BAR_HEIGHT))
    musicImg:setVisible(music > 0)
    local effectImg = container:getVarScale9Sprite("mEffectBar")
    effectImg:setContentSize(CCSize(MAX_BAR_WIDTH * effect / MAX_EFFECT_NUM, MAX_BAR_HEIGHT))
    effectImg:setVisible(effect > 0)
end

--消息通用
function BattleSettingPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_SEVERINFO_UPDATE then
	elseif typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:onRefreshPage(container)
		end
	end
end

-- 刷新增減按鈕狀態
function BattleSettingPageBase:refreshBtnState(container)
    NodeHelper:setMenuItemEnabled(container, "mMusicAddBtn", music < MAX_MUSIC_NUM)
    NodeHelper:setMenuItemEnabled(container, "mSoundAddBtn", effect < MAX_MUSIC_NUM)
    NodeHelper:setMenuItemEnabled(container, "mMusicReduceBtn", music > 0)
    NodeHelper:setMenuItemEnabled(container, "mSoundReduceBtn", effect > 0)
end

----------------click event------------------------
function BattleSettingPageBase:onClose(container)
    SoundManager:getInstance():setMusicOn(tonumber(UserInfo.stateInfo.musicOn) >= 1)
    SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(UserInfo.stateInfo.musicOn / MAX_MUSIC_NUM)
    SoundManager:getInstance():setEffectOn(tonumber(UserInfo.stateInfo.soundOn) >= 1)
    SimpleAudioEngine:sharedEngine():setEffectsVolume(UserInfo.stateInfo.soundOn / MAX_EFFECT_NUM)
	PageManager.popPage(thisPageName)
end

function BattleSettingPageBase:onAddMusic(container)
    music = math.min(music + 1, MAX_MUSIC_NUM)
    SoundManager:getInstance():setMusicOn(tonumber(music) >= 1)
    SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(music / MAX_MUSIC_NUM)
	PageManager.refreshPage(thisPageName)
    self:refreshBtnState(container)
end

function BattleSettingPageBase:onReduceMusic(container)
    music = math.max(music - 1, 0)
    SoundManager:getInstance():setMusicOn(tonumber(music) >= 1)
    SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(music / MAX_MUSIC_NUM)
	PageManager.refreshPage(thisPageName)
    self:refreshBtnState(container)
end

function BattleSettingPageBase:onAddEffect(container)
    effect = math.min(effect + 1, MAX_EFFECT_NUM)
    SoundManager:getInstance():setEffectOn(tonumber(effect) >= 1)
    SimpleAudioEngine:sharedEngine():setEffectsVolume(effect / MAX_EFFECT_NUM)
	PageManager.refreshPage(thisPageName)
    self:refreshBtnState(container)
end

function BattleSettingPageBase:onReduceEffect(container)
    effect = math.max(effect - 1, 0)
    SoundManager:getInstance():setEffectOn(tonumber(effect) >= 1)
    SimpleAudioEngine:sharedEngine():setEffectsVolume(effect / MAX_EFFECT_NUM)
	PageManager.refreshPage(thisPageName)
    self:refreshBtnState(container)
end

function BattleSettingPageBase:onSaveSettings(container)
	local message = Player_pb.HPSysSetting()
	
	if message ~= nil then	
		message.musicOn = music
		message.soundOn = effect
		UserInfo.stateInfo.musicOn = music
		UserInfo.stateInfo.soundOn = effect
		SoundManager:getInstance():setMusicOn(tonumber(UserInfo.stateInfo.musicOn) >= 1)
        SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(UserInfo.stateInfo.musicOn / MAX_MUSIC_NUM)
		SoundManager:getInstance():setEffectOn(tonumber(UserInfo.stateInfo.soundOn) >= 1)
        SimpleAudioEngine:sharedEngine():setEffectsVolume(UserInfo.stateInfo.soundOn / MAX_EFFECT_NUM)
		local pb_data = message:SerializeToString()
		PacketManager:getInstance():sendPakcet(HP_pb.SYS_SETTING_C, pb_data, #pb_data, false)
	end
	
	PageManager.popPage(thisPageName)
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
BattleSettingPage = CommonPage.newSub(BattleSettingPageBase, thisPageName, option)