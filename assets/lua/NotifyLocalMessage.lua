local NotifyLocalMessage = 
{
    _notifyInfo = 
    {
        -- 示例 1:开始时间(10：00：00) 2:结束时间(12:00:00) 3:时间间隔(秒*1000) 4:消息id列表 5:循环到了哪一个索引了(此字段不需要配置 由代码自己统计更变) 6:累加的时间(此字段不需要配置 由代码自己统计更变)
        [1]={ _timeBegin = { 7 * 3600, 0 * 60, 0 }, _timeEnd = { 10 * 3600, 0 * 60, 0 }, _timeStep = 900, _msgList = { 7 }, _loopIdx = 0, _deltaTime = 0 },
        [2]={ _timeBegin = { 11 * 3600, 0 * 60, 0 }, _timeEnd = { 14 * 3600, 0 * 60, 0 }, _timeStep = 900, _msgList = { 7 }, _loopIdx = 0, _deltaTime = 0 },
		[3]={ _timeBegin = { 17 * 3600, 0 * 60, 0 }, _timeEnd = { 20 * 3600, 0 * 60, 0 }, _timeStep = 900, _msgList = { 7 }, _loopIdx = 0, _deltaTime = 0 },
		[4]={ _timeBegin = { 23 * 3600, 0 * 60, 0 }, _timeEnd = { 23 * 3600, 59 * 60, 59 }, _timeStep = 900, _msgList = { 7 }, _loopIdx = 0, _deltaTime = 0 },
		[5]={ _timeBegin = { 0 * 3600, 0 * 60, 0 }, _timeEnd = { 2 * 3600, 0 * 60, 0 }, _timeStep=900, _msgList = { 7 }, _loopIdx = 0, _deltaTime = 0 },
    }
}

function NotifyLocalMessage:initLocalMsg()
    local tH = tonumber(os.date("%H"))
    local tM = tonumber(os.date("%M"))
    local tS = tonumber(os.date("%S"))

    local tCurTime = os.time()
    local tDayStartTime = tCurTime - (tH * 3600 + tM * 60 + tS)

    for idx = 1, #NotifyLocalMessage._notifyInfo do
        local info = NotifyLocalMessage._notifyInfo[idx]
        local beginTime = tDayStartTime + info._timeBegin[1] + info._timeBegin[2] + info._timeBegin[3]
        local endTime = tDayStartTime + info._timeEnd[1] + info._timeEnd[2] + info._timeEnd[3]
        if (tCurTime >= beginTime and tCurTime <= endTime) then
            local nCount = math.floor((tCurTime - beginTime) / info._timeStep)
            local nIdx = math.floor(nCount % #info._msgList)
            if (nIdx == 0 or nIdx > #info._msgList) then
                nIdx = 1
            end
            info._deltaTime = beginTime + nCount * info._timeStep
            info._loopIdx = nIdx
        end
    end
end

function NotifyLocalMessage:updateLocalMsg()
    local tH = tonumber(os.date("%H"))
    local tM = tonumber(os.date("%M"))
    local tS = tonumber(os.date("%S"))
    local tCurTime = os.time()
    local tDayStartTime = tCurTime - (tH * 3600 + tM * 60 + tS)

    for idx = 1, #NotifyLocalMessage._notifyInfo do
        local info = NotifyLocalMessage._notifyInfo[idx]
        local beginTime = tDayStartTime + info._timeBegin[1] + info._timeBegin[2] + info._timeBegin[3]
        local endTime = tDayStartTime + info._timeEnd[1] + info._timeEnd[2] + info._timeEnd[3]

        if (tCurTime >= beginTime and tCurTime <= endTime) then
            if (info._loopIdx == 0) then
                info._loopIdx = 1
                info._deltaTime = beginTime
                local nMsgIdx = info._msgList[info._loopIdx]
                --NotifyLocalMessage:addMsgToShowList(nMsgIdx)
            else
                if tCurTime - info._deltaTime >= info._timeStep then
                    if info._loopIdx < #info._msgList then
                        info._loopIdx = info._loopIdx + 1
                    else
                        info._loopIdx = 1
                    end
                    info._deltaTime = info._deltaTime + info._timeStep
                    local nMsgIdx = info._msgList[info._loopIdx]
                    --NotifyLocalMessage:addMsgToShowList(nMsgIdx)
                end
            end
        else
            info._deltaTime = 0
            info._loopIdx = 0
        end
    end
end

function NotifyLocalMessage:addMsgToShowList(nMsgIdx)
    local chatMsg = Chat_pb.HPChatMsg()
    local strTemp = string.format("#D#%d", nMsgIdx)
    chatMsg.chatMsg = strTemp
    table.insert(worldBroadCastList, chatMsg)
end

return NotifyLocalMessage