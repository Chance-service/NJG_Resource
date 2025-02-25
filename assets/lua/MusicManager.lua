
----------------------------------------------------------------------------------
MusicManager = {}
MusicManager.musciCfg = ConfigManager.getBGMusicCfg()

function MusicManager.playBGMusic(musicName)
	for k,v in pairs(MusicManager.musciCfg) do
		if tostring(v.englishName) == tostring(musicName) then
			SoundManager:getInstance():playEffect(tostring(v.musicPath))
		end
	end
end