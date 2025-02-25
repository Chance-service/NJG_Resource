local NodeHelper = require("NodeHelper")
local thisPageName = 'TowerDataMgr'
local Activity6_pb = require("Activity6_pb");
local HP_pb = require("HP_pb");

local TowerDataBase = {}

local PageInfo={

}
local RankInfo={

}

local option = {
    handlerMap = {},
}

local opcodes = {
}

function TowerBase_SetInfo(data)
    if data.action==0 then
      local baseInfo = data.baseInfo
      PageInfo.MaxFloor = baseInfo.MaxFloor
      PageInfo.endTime = baseInfo.endTime
      PageInfo.takedId = {}
      for k,v in pairs (baseInfo.takeId) do
        if type(k) == "number" then
            PageInfo.takedId[k] = v
        end
      end
      PageInfo.canChooseFloor = baseInfo.chooseFloor
    elseif data.action == 1 then
        local _rankInfo = data.rankingInfo
        --Self
        local SelfItem = _rankInfo.selfRankItem
        RankInfo.selfRank = SelfItem.rank
        RankInfo.selfFloor = SelfItem.MaxFloor
        RankInfo.selfName = SelfItem.name
        RankInfo.selfHead = SelfItem.headIcon
        RankInfo.selfSkin = SelfItem.skin
        RankInfo.selfDoneTime = SelfItem.doneTime

        --other
        RankInfo.otherItem = {}
        for key,otherItem in pairs (_rankInfo.otherRankItem) do
            RankInfo.otherItem[key] = {}
            RankInfo.otherItem[key].rank = otherItem.rank
            RankInfo.otherItem[key].MaxFloor = otherItem.MaxFloor
            RankInfo.otherItem[key].name = otherItem.name
            RankInfo.otherItem[key].headIcon = otherItem.headIcon
            RankInfo.otherItem[key].skin = otherItem.skin
            RankInfo.otherItem[key].doneTime = otherItem.doneTime
        end
    end
end

function TowerDataBase:getData()
    return PageInfo
end

function TowerDataBase:getRank()
    return RankInfo
end



local CommonPage = require('CommonPage')
TowerData = CommonPage.newSub(TowerDataBase, thisPageName, option)

return TowerData
