
local HtmlEventHandler = {}
MultiEliteJoinFromChat = false
function HtmlEventHandler.HtmlClickHandler(id,name,value)
    if id==1 then
        if value=="nil" then
            return
        end
        local params = common:split(value, ",")
        local eliteId = params[1]
        local roomId = params[2]
        HtmlEventHandler.FastEnterMultiEliteRoom(eliteId,roomId)
    end
end

function HtmlEventHandler.FastEnterMultiEliteRoom(eliteId,roomId)
    if eliteId==nil or roomId==nil then
        MessageBoxPage:Msg_Box_Lan("@MultiEliteNoRoom")
        return
    end

    local MultiElite_pb = require("MultiElite_pb")
    local msg = MultiElite_pb.HPJoinMultiEliteRoom()
	msg.isFastJoin = false
	msg.multiEliteId = tonumber(eliteId)
	msg.serverRoomId = tonumber(roomId)
	common:sendPacket(HP_pb.JOIN_MULTIELITE_ROOM_C, msg,false)
    MultiEliteJoinFromChat = true
    local MultiEliteDataManger = require("Battle.MultiEliteDataManger")
    MultiEliteDataManger:setEliteId( eliteId )
end

function HtmlEventHandler.CalculateParamsFromMsg(msg,...)
    local params = nil;
    local o = tostring(s)
	for i = 1, select("#", ...) do
	    for j=1,#msg do
            if msg[j].name==select(i,...) then
                if params==nil then
                    params = msg[j].value
                else
                    params = params..","..msg[j].value
                end
            end
        end
	end
	return params
end

return HtmlEventHandler
