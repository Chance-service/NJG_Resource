local GameTime = {}


GameTime._time = os.time()
GameTime._dt = 0

function GameTime:time ()
	return self._time
end

function GameTime:dt ()
	return self._dt
end

function GameTime:execute (dt)
	self._time = self._time + dt
	self._dt = dt
end

CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function(dt)
	GameTime:execute(dt)
end, 0, false)

return GameTime