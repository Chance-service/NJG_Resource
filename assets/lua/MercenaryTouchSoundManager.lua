local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local MercenaryTouchSoundManager = { }

function getTouchConfig(roleId)
    local roleTouchData = ConfigManager.getRoleTouchMusicCfg()[roleId]
    if not roleTouchData then
        return nil
    end

    local touchCfg = { }

    function getPosScale(content)
        local data = common:split(content, ",")
        local posScale = { x = 0, y = 0, scaleX = 1, scaleY = 1 }

        if #data < 4 then
            return posScale
        end

        posScale.x = tonumber(data[1])
        posScale.y = tonumber(data[2])
        posScale.scaleX = tonumber(data[3])
        posScale.scaleY = tonumber(data[4])
        return((#data) > 0) and posScale or nil
    end

    function getSound(content)
        local sound = { }
        for _, v in ipairs(common:split(content, ",")) do
            table.insert(sound, (v))
        end

        return (#(common:split(content, ",")) > 0) and sound or nil
    end

    touchCfg._head = { }
    touchCfg._head.pos1 = getPosScale(roleTouchData.headPos1)
    touchCfg._head.pos2 = getPosScale(roleTouchData.headPos2)
    touchCfg._head.sound = getSound(roleTouchData.headSound1)
    touchCfg._head.sound2 = getSound(roleTouchData.headSound2)

    touchCfg._heart = { }
    touchCfg._heart.pos1 = getPosScale(roleTouchData.heartPos1)
    touchCfg._heart.pos2 = getPosScale(roleTouchData.heartPos2)
    touchCfg._heart.sound = getSound(roleTouchData.heartSound1)
    touchCfg._heart.sound2 = getSound(roleTouchData.heartSound2)

    touchCfg._ass = { }
    touchCfg._ass.pos1 = getPosScale(roleTouchData.assPos1)
    touchCfg._ass.pos2 = getPosScale(roleTouchData.assPos2)
    touchCfg._ass.sound = getSound(roleTouchData.assSound1)
    touchCfg._ass.sound2 = getSound(roleTouchData.assSound2)

    touchCfg._unlock = roleTouchData.unLock

    return touchCfg
end

function MercenaryTouchSoundManager:playTouchMusic(index, _curMercenaryItemId)
    local touchCfg = getTouchConfig(_curMercenaryItemId)

    if not touchCfg then
        return
    end
    NodeHelper:stopMusic()
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    local soundTable = {
        -- 1,2头部  --3,4胸部  --5,6屁股
        touchCfg._head.sound, touchCfg._head.sound2,
        touchCfg._heart.sound, touchCfg._head.sound2,
        touchCfg._ass.sound, touchCfg._ass.sound2
    }

    local musicName = nil
    if index >= 1 and index <= 6 and soundTable[index] then
        local randomNum = math.random(#(soundTable[index]))
        musicName = soundTable[index][randomNum]
    end
    local roleAttCfg = ConfigManager.getRoleCfg()[_curMercenaryItemId]
    if musicName then
        if not GameConfig.isIOSAuditVersion then
            --if  GameConfig.MercenaryQualityTxt[roleAttCfg.quality] == "UR" then 
                NodeHelper:playMusic(musicName)     ----------
            --end
        end
    end
end
function MercenaryTouchSoundManager:initTouchButton(container, _curMercenaryItemId, layerTouchCallback, btnCallback)
    if not container or not _curMercenaryItemId then return end
    -- 相关按钮默认都隐藏掉
    local roleId = _curMercenaryItemId
    local touchCfg = getTouchConfig(roleId)
    if not touchCfg then
        return
    end
    -- 相关按钮默认都隐藏掉
    local _touchButtonInfo = { rect = { }, node = { } }
    local posScaleTable = {
        touchCfg._head.pos1, touchCfg._head.pos2,
        touchCfg._heart.pos1, touchCfg._heart.pos2,
        touchCfg._ass.pos1, touchCfg._ass.pos2
    }

    for i = 1, 6 do
        local btnName = "mSpineSprite" .. i
        local node = container:getVarNode(btnName)
        local posScale = posScaleTable[i]
        node:setVisible(false)
        if node and posScale then
            node:setPosition(ccp(-640, 0))
            node:setPosition(ccp(posScale.x, posScale.y))
            node:setScaleX(posScale.scaleX)
            node:setScaleY(posScale.scaleY)
            node:setVisible(true)

            if Golb_Platform_Info.is_win32_platform then
                local meuItemImage = { [btnName] = "UI/Mask/test.png" }
                --NodeHelper:setSpriteImage(container, meuItemImage)
            end
        end
    end

    local mSpineLayer = container:getVarNode("mSpineLayer")
    if mSpineLayer then
        mSpineLayer = tolua.cast(mSpineLayer, "CCLayer")
        mSpineLayer:setTouchEnabled(true)
    end
    local soundOpen = UserInfo.stateInfo.soundOn
    if soundOpen == 0 and not layerTouchCallback then
        -- 关闭音效或者不需要spine点击效果
        return
    end

    function checkTouchEvent(pTouch)
        local point = pTouch:getLocation()
        for i = 1, 6 do
            local missionPicName = "mSpineSprite" .. i
            local missionNode = nil
            local missionRect = nil
            missionNode = _touchButtonInfo.node[missionPicName]
            if missionNode == nil then
                missionNode = container:getVarNode(missionPicName)
                if missionNode then
                    _touchButtonInfo.node[missionPicName] = missionNode
                end
            end
            if missionNode then
                missionRect = _touchButtonInfo.rect[missionPicName]
                if missionRect == nil then
                    missionRect = GameConst:getInstance():boundingBox(missionNode)
                    _touchButtonInfo.rect[missionPicName] = missionRect
                end
            end

            if missionRect then
                local point1 = missionNode:getParent():convertToNodeSpace(point)
                if GameConst:getInstance():isContainsPoint(missionRect, point1) then
                    return i
                end
            end
        end
        return nil
    end

    local mSpineLayer = container:getVarNode("mSpineLayer")
    if mSpineLayer then
        mSpineLayer = tolua.cast(mSpineLayer, "CCLayer")
        mSpineLayer:registerScriptTouchHandler(function(eventName, pTouch)
            -- if eventName == "began" or eventName == "moved" or eventName == "cancelled" then
            if eventName == "ended" then
                local nTouchResult = checkTouchEvent(pTouch)
                if nTouchResult then
                    if btnCallback then
                        btnCallback(nTouchResult, pTouch:getLocation())
                    else
                        MercenaryTouchSoundManager:playTouchMusic(nTouchResult, _curMercenaryItemId)
                    end
                else
                    if layerTouchCallback then
                        layerTouchCallback(pTouch:getLocation())
                    end
                end
            end
        end
        , false, 0, false)
    end

    mSpineLayer:setTouchEnabled(true)
end
----------packet msg--------------------------
return MercenaryTouchSoundManager