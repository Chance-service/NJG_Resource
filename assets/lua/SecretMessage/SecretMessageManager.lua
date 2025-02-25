local SecretMessageManager = { isLangInit = false }

local secretCfg = ConfigManager.getSecretMessageCfg()
--------------------------------------------------------------------------------
local SecretMessageData = {
    messageQueue = { },
    allHeroData = { },
    power=0 ,
}
local AlbumCfg = ConfigManager.getAlbumData()
--------------------------------------------------------------------------------
local function getRoleTable(_id)
    local RoleTable = {}
    for _, v in pairs(AlbumCfg) do
        if v.itemId == _id then
            table.insert(RoleTable, v)
        end
    end
    table.sort(RoleTable, function(a, b)
        return a.id < b.id
    end)
    return RoleTable
end


-- 初始化字串
function SecretMessageManager_initLanguage()
    if not SecretMessageManager.isLangInit then
        if CC_TARGET_PLATFORM_LUA ~= common.platform.CC_PLATFORM_WIN32 then
	        Language:getInstance():addLanguageFile("Lang/Language_Secret.lang")
        end
        SecretMessageManager.isLangInit = true
    end
end
-- 紀錄server回傳資料
function SecretMessageManager_setServerData(msg)
    if msg.action==3 then
        SecretMessageData.power=msg.syncMsg.power
        require("SecretMessage.SecretMessagePage")
        SecretMessagePage_RefreshBar()
        return
    end
    SecretMessageData.messageQueue = { }
    SecretMessageData.heroData = { }


    for i = 1, #msg.heroInfo do
        local itemId = msg.heroInfo[i].heroId
        SecretMessageData.allHeroData[itemId] = { }
        SecretMessageData.allHeroData[itemId].intimacyPoint = msg.heroInfo[i].intimacy
        SecretMessageData.allHeroData[itemId].AllPoint=msg.heroInfo[i].Favorability
        SecretMessageData.allHeroData[itemId].favorabilityPoint = msg.heroInfo[i].Favorability

        SecretMessageData.allHeroData[itemId].Unlock = { }
        SecretMessageData.allHeroData[itemId].Free = { }
        SecretMessageData.allHeroData[itemId].Cost = { }

        local roleTable = getRoleTable(itemId)

        -- 初始化 Unlock、Free、Cost 狀態
        for i = 1, 7 do
            local heroData = SecretMessageData.allHeroData[itemId]
            heroData.Unlock[i] = false
            heroData.Free[i] = false
            heroData.Cost[i] = false
        end
        
        -- 定義一個通用函數來創建查找表
        local function createLookupTable(idList)
            local lookupTable = {}
            for _, id in pairs(idList) do
                if tonumber(id) then
                    lookupTable[id] = true
                end
            end
            return lookupTable
        end
        
        -- 構建查找表
        local unlockCfgLookup = createLookupTable(msg.heroInfo[i].unlockCfgId)
        local freeCfgLookup = createLookupTable(msg.heroInfo[i].freeCfgId)
        local costCfgLookup = createLookupTable(msg.heroInfo[i].costCfgId)
        
        -- 減去符合條件的分數並更新狀態
        for key, data in pairs(roleTable) do
            local heroData = SecretMessageData.allHeroData[itemId]
            if unlockCfgLookup[data.id] then
                heroData.favorabilityPoint = heroData.favorabilityPoint - data.Score
                heroData.Unlock[key] = true
            end
            if freeCfgLookup[data.id] then
                heroData.Free[key] = true
            end
            if costCfgLookup[data.id] then
                heroData.Cost[key] = true
            end
        end


        SecretMessageData.allHeroData[itemId].sexyPoint = msg.heroInfo[i].sexy
        SecretMessageData.allHeroData[itemId].history = { }
        SecretMessageData.messageQueue[i] = { }
        SecretMessageData.allHeroData[itemId].pic=msg.heroInfo[i].pic
        for idx = 1, #msg.heroInfo[i].history do
            SecretMessageData.allHeroData[itemId].history[idx] = { }
            local cfg = secretCfg[msg.heroInfo[i].history[idx].qution]
            if cfg then
                 if msg.heroInfo[i].history[idx].answer ~= -1 then
                    SecretMessageData.allHeroData[itemId].history[idx].itemId = itemId
                    SecretMessageData.allHeroData[itemId].history[idx].questionStr = cfg.QuestionStr
                    SecretMessageData.allHeroData[itemId].history[idx].ansStr = (msg.heroInfo[i].history[idx].answer == 0) and
                                                                                cfg.AnsStr1 or cfg.AnsStr2   -- server使用0跟1
                    SecretMessageData.allHeroData[itemId].history[idx].endStr = (msg.heroInfo[i].history[idx].answer == 0) and
                                                                                cfg.EndStr1 or cfg.EndStr2
                    SecretMessageData.allHeroData[itemId].history[idx].pic=msg.heroInfo[i].history[idx].pic or 0
                else
                    local _itemId=itemId
                    local DataTable={itemId=_itemId,
                                     questId=msg.heroInfo[i].history[idx].qution,
                                     questionStr=cfg.QuestionStr,
                                     ansStr1=cfg.AnsStr1,
                                     ansStr2 = cfg.AnsStr2,
                                     endStr1 = cfg.EndStr1,
                                     endStr2 = cfg.EndStr2
                                     }                    
                    SecretMessageData.messageQueue[i]=DataTable
                end
            end
        end
        SecretMessageData.power=msg.power
    end
end
function SecretMessageManager_getAlbumData(_id)
    local AlbumData={
        RoleId=0,
        ImgCount=0,
        UnLockCount=0,
        NowLimit=0,
        RewardState={}
    }


    for k,v in pairs (AlbumCfg) do
        if v.itemId==_id then
            AlbumData.ImgCount=AlbumData.ImgCount+1
        end
    end
    if SecretMessageData.allHeroData[_id] then 
        for k,isUnlock in pairs(SecretMessageData.allHeroData[_id].Unlock) do
            if isUnlock then
                AlbumData.UnLockCount=AlbumData.UnLockCount+1
            end
        end

        table.sort (AlbumCfg,function(data1,data2) return data1.id < data2.id end)
        local table = getRoleTable(_id)
        AlbumData.NowLimit=table[AlbumData.UnLockCount+1].Score
        if AlbumData.UnLockCount ==7 then
            AlbumData.NowLimit = 0 
        end 
        --for k,v in pairs (AlbumCfg) do
        --    if v.itemId==_id and SecretMessageData.allHeroData[_id] and not SecretMessageData.allHeroData[_id].Unlock[AlbumData.UnLockCount] then
        --        if v.id<1000 then
        --            AlbumData.NowLimit=v.Score
        --            break
        --        end
        --    end
        --end
    end
    AlbumData.UnLockCount= AlbumData.UnLockCount+SecretMessageManager_LevelAchiveCount(_id)
    AlbumData.RoleId=_id
    return AlbumData
end
function SecretMessageManager_LevelAchiveCount(_id)
    local UserMercenaryManager = require("UserMercenaryManager")
    local AlbumCfg = ConfigManager.getAlbumData()
    local count=0
    local mInfoSorts = UserMercenaryManager:getMercenaryStatusInfos()
    local MercenaryId = 0
    for i = 1, #mInfoSorts do
        if mInfoSorts[i].itemId == _id then
            MercenaryId = mInfoSorts[i].roleId
            break
        end
    end
    local curRoleInfo = UserMercenaryManager:getUserMercenaryById(MercenaryId)
    if curRoleInfo then
        for k,v in pairs(AlbumCfg) do
          if v.itemId==_id and v.id>1000 and curRoleInfo.starLevel >= v.Score then
             return 1
          end
        end
    end
    return 0
end
-- 取得所有訊息佇列
function SecretMessageManager_getMessageQueue()
    return SecretMessageData.messageQueue
end
-- 取得目標英雄佇列第一筆訊息
function SecretMessageManager_getFirstMessageByItemId(itemId)
    for i = 1, #SecretMessageData.messageQueue do
        if SecretMessageData.messageQueue[i].itemId == itemId then
            return SecretMessageData.messageQueue[i]
        end
    end
    return nil
end
-- 取得全部英雄資料
function SecretMessageManager_getAllHeroData()
    return SecretMessageData.allHeroData
end
function SecretMessageManager_getPower()
    return SecretMessageData.power
end
-- 取得目標英雄歷史訊息
function SecretMessageManager_getHistoryMessageByItemId(itemId)
    if SecretMessageData.allHeroData[itemId] then
        return SecretMessageData.allHeroData[itemId].history
    end
    return nil
end
--------------------------------------------------------------------------------