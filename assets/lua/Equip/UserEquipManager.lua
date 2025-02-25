local UserEquipManager = { };
--------------------------------------------------------------------------------

------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local math = math;
--------------------------------------------------------------------------------

local UserMercenaryManager = require("UserMercenaryManager")
local UserItemManager = require("Item.UserItemManager")
local ItemManager = require("Item.ItemManager");
local UserInfo = require("PlayerInfo.UserInfo");
local PBHelper = require("PBHelper");
local SoulStarManager = require("Leader.SoulStarManager")
-- local profiler = require("profiler")
--------------------------------------------------------------------------------
-- 装备分类：部位、品质、神器、所有、装在身上的(Part,Quality,Godly,All都是指在背包中的装备)
local EquipCategory = {
    Part = { },
    Quality = { },
    Godly = { },
    All = { },
    Dress = { }
};
-- 装备同步类型
local SyncType = {
    Insert = 1,
    Delete = 2,
    On = 3,
    Off = 4,
    Init = 5,
    Update = 6
};
local UserEquipMap = { };

local EquipHighestSocre = {
    roleHighestScore = { }
}
-- 装备红点相关数据缓存
local EquipStatus = {
    size = 0,
    -- 所有装备的个数
    init = false,
    isFull = false,
    partInfo = { },
    partInfo2 = { },
    noticeCount = 0,
    noticeCount2 = { },
    redPointNotice = { }
};
-- 佣兵装备部位
local PartForMercenary = {
    Const_pb.HELMET,
    Const_pb.RING,
    Const_pb.CUIRASS,
    Const_pb.SHOES,
    Const_pb.WEAPON1,
    Const_pb.GLOVE
};

local takeOnPart = 0

-- 根据评分排序
local function sortByScore(id_1, id_2)
    local isAsc = false;

    if id_2 == nil then
        return isAsc;
    end
    if id_1 == nil then
        return not isAsc;
    end

    local userEquip_1 = UserEquipManager:getUserEquipById(id_1);
    local userEquip_2 = UserEquipManager:getUserEquipById(id_2);

    if (userEquip_1 and userEquip_1.id ~= nil) and(userEquip_2 and userEquip_2.id ~= nil) then
        if userEquip_1.score ~= userEquip_2.score then
            if userEquip_1.score >= userEquip_2.score then
                return isAsc;
            end
            return not isAsc;
        end

        if id_2 >= id_1 then
            return isAsc;
        else
            return not isAsc
        end
    elseif userEquip_1.id ~= nil and userEquip_2.id == nil then
        return isAsc
    elseif userEquip_1.id == nil and userEquip_2.id ~= nil then
        return not isAsc
    end

    local userItem_1 = UserItemManager:getUserItemById(id_1)
    local userItem_2 = UserItemManager:getUserItemById(id_2)

    if userItem_1 ~= nil and userItem_2 ~= nil then
        if userItem_1.itemId == userItem_2.itemId then
            return isAsc
        elseif ItemManager:getQualityById(userItem_1.itemId) > ItemManager:getQualityById(userItem_2.itemId) then
            return not isAsc
        else
            return isAsc
        end
        --[[
    elseif userItem_1 ~= nil and userItem_2 == nil then
        return not isAsc
    elseif userItem_1 == nil and userItem_2 ~= nil then
        return isAsc
        ]]
    end

    return not isAsc;
end

-- 根据品质、评分排序
local function sortByQualityScore(id_1, id_2)
    local isAsc = false;

    if id_2 == nil then
        return isAsc;
    end
    if id_1 == nil then
        return not isAsc;
    end

    local userEquip_1 = UserEquipManager:getUserEquipById(id_1);
    local userEquip_2 = UserEquipManager:getUserEquipById(id_2);

    local quality_1 = EquipManager:getQualityById(userEquip_1.equipId);
    local quality_2 = EquipManager:getQualityById(userEquip_2.equipId);

    if quality_1 ~= quality_2 then
        if quality_1 > quality_2 then
            return isAsc;
        else
            return not isAsc;
        end
    end

    if userEquip_1.score ~= userEquip_2.score then
        if userEquip_1.score > userEquip_2.score then
            return isAsc;
        end
        return not isAsc;
    end

    if id_2 > id_1 then
        return isAsc;
    end

    return not isAsc;
end

function UserEquipManager:getRedPointNotice()
    return EquipStatus.redPointNotice;
end

function UserEquipManager:updateMercenaryRedPointNotice(roleId)
    local noticeCount = 0;
    local partInfo2
    local userMercenary = UserMercenaryManager:getUserMercenaryById(roleId)
    if not userMercenary then return end
    for part = 1, 10 do
        partInfo2 = EquipStatus.partInfo2[part] or { }
        if partInfo2[roleId] and partInfo2[roleId].id then
            local userEquip = UserEquipMap[partInfo2[roleId].id];
            local roleEquip = PBHelper:getRoleEquipByPart(userMercenary.equips, part);
            if userEquip and roleEquip and roleEquip.equipId then
                if userEquip.id == roleEquip.equipId then
                    self:cancelNotice(part, userMercenary.roleId);
                else
                    local currentEquip = self:getUserEquipById(roleEquip.equipId);
                    if next(currentEquip) == nil then
                        local debugStr = "line 678 equipId = " .. roleEquip.equipId .. " userMercenary.roleId =" .. userMercenary.roleId
                        -- __G__TRACKBACK__(debugStr)
                        return
                    end
                    if userEquip.score <= currentEquip.score then
                        self:cancelNotice(part, userMercenary.roleId);
                    end
                end
            end
        end

    end
end

function UserEquipManager:setRedPointNotice(roleId, visable)
    if EquipStatus.redPointNotice ~= nil then
        EquipStatus.redPointNotice[roleId] = visable;
    end
end
----------------------------------------------------------------------------------
function UserEquipManager:getUserEquipByIndex(index)
    local Equip_pb = require("Equip_pb");
    local equipStr = ServerDateManager:getInstance():getEquipInfoByIndexForLua(index);
    local userEquip = Equip_pb.EquipInfo();
    userEquip:ParseFromString(equipStr);
    userEquip.score = self:calEquipScore(userEquip)
    return userEquip;
end

function UserEquipManager:getUserEquipById(userEquipId)
    return UserEquipMap[userEquipId]
end

function UserEquipManager:getCanDecomposeEquipTable()
    local PBHelper = require("PBHelper")
    local _tb = common:deepCopy(EquipCategory.All)
    -- common:table_removeFromArray(tb, val)
    for k, v in ipairs(EquipCategory.Dress) do
        common:table_removeFromArray(_tb, v)
    end

    for k, v in ipairs(EquipCategory.Godly) do
        common:table_removeFromArray(_tb, v)
    end

    local _ids = { }
    for k, v in ipairs(_tb) do
        local userEquipInfo = self:getUserEquipById(v)
        local itemInfo = EquipManager:getEquipCfgById(userEquipInfo.equipId)
        local gemInfo = PBHelper:getGemInfo(userEquipInfo.gemInfos)

        local hasGem = false
        if table.maxn(gemInfo) > 0 then
            -- 是否有孔
            for i = 1, 4 do
                local gemId = gemInfo[i];
                if gemId ~= nil and gemId > 0 then
                    -- 是否有宝石
                    hasGem = true
                end
            end
        end

        if not self:isGodly(userEquipInfo.id) and not hasGem and itemInfo.suitId > 0 then
            table.insert(_ids, v)
        end
    end

    _tb = nil
    if #_ids > 0 then
        table.sort(_ids, sortByScore)
    end
    return _ids

end

function UserEquipManager:resetCatecory()
    EquipCategory = {
        Part = { },
        Quality = { },
        Godly = { },
        All = { },
        Dress = { }
    };
end

function UserEquipManager:resetEquipStatus()
    EquipStatus = {
        size = 0,
        init = false,
        isFull = nil,
        partInfo = { },
        partInfo2 = { },
        noticeCount = 0,
        noticeCount2 = { },
        redPointNotice = { }
    };
    -- PageManager.setAllNotice();
    PageManager.setAllMercenaryNotice();
end

-- 小退重置
function UserEquipManager:reset()
    -- UserEquipMap = {};
    self:resetCatecory();
    self:resetEquipStatus();
end

-- 是否所有装备已从服务器同步(不包括离线、上线后新获取装备）
function UserEquipManager:hasInited()
    return EquipStatus.init;
end

function UserEquipManager:setUninited()
    self:reset();
    EquipStatus.init = false;
end

-- 服务器推送完所有老装备后，同步装备数据，并把装备进行分类
function UserEquipManager:check()
    if EquipStatus.init then return end
    local size = ServerDateManager:getInstance():getEquipInfoTotalSize();
    if EquipStatus.size ~= size then
        self:resetCatecory();
        if not UserInfo.roleInfo.level then
            UserInfo.syncRoleInfo();
        end
        for i = 0, size - 1 do
            local userEquip = self:getUserEquipByIndex(i);
            userEquip.score = self:calEquipScore(userEquip)
            self:classify(userEquip, SyncType.Init);
            UserEquipMap[userEquip.id] = userEquip;
            EquipStatus.size = EquipStatus.size + 1;
        end
    end
    EquipStatus.init = true;
    self:checkAllEquipNotice()
end

function UserEquipManager:checkAllEquipNotice()
    if not EquipStatus.init then return end
    local size = ServerDateManager:getInstance():getEquipInfoTotalSize();
    for i = 0, size - 1 do
        local userEquip = self:getUserEquipByIndex(i);
        if not common:table_hasValue(EquipCategory.Dress, userEquip.id) then
            self:checkPartModify(userEquip)
        end
    end

end

-- 装备分类
function UserEquipManager:classify(userEquip, syncType)
    local id = userEquip.id;


    if syncType == SyncType.Off or
        syncType == SyncType.Insert or
        not self:isDressedWithEquipInfo(userEquip)
    then
        local part = EquipManager:getPartById(userEquip.equipId);
        if EquipCategory.Part[part] == nil then
            EquipCategory.Part[part] = { id };
        else
            if not common:table_hasValue(EquipCategory.Part[part], id) then
                table.insert(EquipCategory.Part[part], id)
            end
        end

        -- 品质分类
        local quality = EquipManager:getQualityById(userEquip.equipId);
        if EquipCategory.Quality[quality] == nil then
            EquipCategory.Quality[quality] = { id };
        else
            table.insert(EquipCategory.Quality[quality], id);
        end

        -- 所有分类
        table.insert(EquipCategory.All, id);

        -- 卸下时Dress分类移除
        if syncType == SyncType.Off then
            EquipCategory.Dress = common:table_removeFromArray(EquipCategory.Dress, id)
        end
    else
        table.insert(EquipCategory.Dress, id);
    end
end

-- 背包中装备删除或上装后从各分类中移除并检查背包
function UserEquipManager:unclassify(id, syncType)
    local userEquip = UserEquipMap[id];
    if userEquip == nil then return; end

    if syncType == SyncType.On or
        not self:isDressedWithEquipInfo(userEquip)
    then
        local part = EquipManager:getPartById(userEquip.equipId);
        if EquipCategory.Part[part] ~= nil then
            EquipCategory.Part[part] = common:table_removeFromArray(EquipCategory.Part[part], id);
        end

        local quality = EquipManager:getQualityById(userEquip.equipId);
        if EquipCategory.Quality[quality] ~= nil then
            EquipCategory.Quality[quality] = common:table_removeFromArray(EquipCategory.Quality[quality], id);
        end

        EquipCategory.All = common:table_removeFromArray(EquipCategory.All, id);

        if syncType == SyncType.On then
            table.insert(EquipCategory.Dress, id);
        end
    end
end

-- 删除装备：分类移除，红点检查，装备缓存移除
function UserEquipManager:deleteEquip(userEquipId)
    if UserEquipMap[userEquipId] == nil then return; end

    self:unclassify(userEquipId, SyncType.Delete);
    self:checkPartAfterDelete(userEquipId);
    UserEquipMap[userEquipId] = nil;
    EquipStatus.size = EquipStatus.size - 1;
end

-- 上装：分类移除，红点检查
function UserEquipManager:takeOn(userEquipId, roleId)
    self:unclassify(userEquipId, SyncType.On)
    self:cancelNoticeAfterTakeOn(userEquipId, roleId)
    -- 新加
    local equip = UserEquipMap[userEquipId];
    takeOnPart = EquipManager:getPartById(equip.equipId);
end

-- 卸装: 分类检查
function UserEquipManager:takeOff(userEquipId)
    local userEquip = UserEquipMap[userEquipId];
    if userEquip then
        self:classify(userEquip, SyncType.Off);
        self:checkPartModify(userEquip)

    end
    -- 新加的消除红点
    if takeOnPart ~= 0 then
        UserEquipManager:isCancelEquipRedPoint(takeOnPart)
        takeOnPart = 0
    else
        --[[		local equip = UserEquipMap[userEquipId];
		if equip and equip.equipId > 0 then
			takeOnPart = EquipManager:getPartById(equip.equipId)
			if takeOnPart ~= 0 then
				UserEquipManager:isCancelEquipRedPoint(takeOnPart)
				takeOnPart = 0
			end
		end]]
    end
end	

-- 同步装备: 分类、添加缓存、检查红点
function UserEquipManager:syncOneEquipInfo(userEquip)
    if userEquip and userEquip.id then
        if UserEquipMap[userEquip.id] == nil then
            self:classify(userEquip, SyncType.Insert);
            EquipStatus.size = EquipStatus.size + 1;
        else
            self:classify(userEquip, SyncType.Update);
        end
        userEquip.score = self:calEquipScore(userEquip)
        UserEquipMap[userEquip.id] = userEquip;
        if not common:table_hasValue(EquipCategory.Dress, userEquip.id) then
            self:checkPartModify(userEquip)
        end
    end
end

------------------------------------------------------------------------------------------
-- 单纯判断背包时候装备已满 leesong
function UserEquipManager:checkEquipPackageIsFull()
    return false
end
-- 检查某个部位的红点（是否有更好的装备）
function UserEquipManager:checkPart(userEquip)
    if not EquipManager:isDressable(userEquip.equipId, UserInfo.roleInfo.prof) then
        -- 主角不能装备，继续检查佣兵
        self:checkPartForMercenary(userEquip);
        return;
    end

    local part = EquipManager:getPartById(userEquip.equipId);
    -- 通过装备id获得装备属于哪个part
    local partInfo = EquipStatus.partInfo[part] or { };
    local roleEquip = UserInfo.getEquipByPart(part);

    local needNotice = true;
    local score = userEquip.score;
    local id = partInfo.id or userEquip.id;

    local needCheckMercenary = true;
    -- 主角该部位是否在装备
    if roleEquip and roleEquip.equipId > 0 then
        -- 装备与主角身上的装备是否相同
        if userEquip.id == roleEquip.equipId then
            -- 相同则不用继续检查佣兵
            needCheckMercenary = false;
            if partInfo.needNotice then
                -- if partInfo.score > userEquip.score and not self:isEquipGodly(userEquip) then return; end
                -- 取消神器优先级

                -- 更新后的装备比红点提示的装备评分更高或相同，则取消红点，否则保留
                if partInfo.score > userEquip.score then return; end
                self:cancelNotice(part);
                id = userEquip.id;
            end
            needNotice = false;
        else
            -- 更新佣兵身上的装备不产生红点
            if common:table_hasValue(EquipCategory.Dress, userEquip.id) then return; end

            local currentEquip = self:getUserEquipById(roleEquip.equipId);
            if next(currentEquip) == nil then
                -- local debugStr = "line 496 equipId = "..roleEquip.equipId
                -- CCMessageBox(debugStr, "LUA ERROR")
                return
            end
            if userEquip.score <= currentEquip.score then
                -- 更新后的装备比当前身上装备评分更低或相同
                score = math.max(partInfo.score or 0, currentEquip.score);
                if partInfo.needNotice then
                    -- 装备与红点提示装备相同则取消红点，否则保留
                    if partInfo.id == userEquip.id then
                        self:cancelNotice(part);
                    else
                        return;
                    end

                end
                id = currentEquip.id;
                needNotice = false;
            else
                -- 比当前身上装备更好，更新提示信息，添加红点
                id = userEquip.score >(partInfo.score and 0) and userEquip.id or partInfo.id;
                score = math.max(userEquip.score, partInfo.score or 0);
                if not partInfo.needNotice then
                    -- if not self:isEquipGodly(currentEquip) or self:isEquipGodly(userEquip) then
                    -- 取消神器优先级,
                    -- if true then
                    EquipStatus.noticeCount = EquipStatus.noticeCount + 1;
                    PageManager.setAllNotice();
                    -- elses
                    -- needNotice = false;
                    -- end
                end
            end
        end
    else
        -- 更新佣兵身上的装备不产生红点
        if common:table_hasValue(EquipCategory.Dress, userEquip.id) then return; end
        if not partInfo.needNotice then
            EquipStatus.noticeCount = 0;
        end
        PageManager.setAllNotice();
        id = userEquip.id;
    end
    EquipStatus.partInfo[part] = {
        needNotice = needNotice,
        score = score,
        id = id
    };

    -- 继续检查佣兵红点
    if needCheckMercenary then
        self:checkPartForMercenary(userEquip);
    end
end

function UserEquipManager:updatePartInfo(part, needNotice, score, id)
    local partInfo = EquipStatus.partInfo[part] or { }
    local isNoticeChange = false;
    if partInfo.needNotice and needNotice == false then
        isNoticeChange = true
    elseif (not partInfo.needNotice) and needNotice == true then
        isNoticeChange = true
    end
    EquipStatus.partInfo[part] =
    {
        needNotice = needNotice,
        score = score,
        id = id
    }
    if isNoticeChange and needNotice == false then
        self:cancelNotice(part)
    elseif isNoticeChange and needNotice == true then
        EquipStatus.noticeCount = EquipStatus.noticeCount + 1;
        PageManager.setAllNotice();
    end

end

function UserEquipManager:checkPartModify(userEquip)
    if not EquipManager:isDressable(userEquip.equipId, UserInfo.roleInfo.prof) then
        -- 主角不能装备，继续检查佣兵
        self:checkPartForMercenary(userEquip);
        return;
    end

    local part = EquipManager:getPartById(userEquip.equipId);
    local partInfo = EquipStatus.partInfo[part] or { };
    local roleEquip = UserInfo.getEquipByPart(part);
    local needNotice = true;
    local score = userEquip.score;
    local id = partInfo.id or userEquip.id;

    -- 主角该部位是否在装备
    if roleEquip and roleEquip.equipId > 0 then
        -- 装备与主角身上的装备是否相同
        if userEquip.id == roleEquip.equipId then
            -- 相同，仅判断是否超过红点装备
            if partInfo.needNotice then
                -- 更新后的装备比红点提示的装备评分更高或相同，则取消红点，否则保留
                if partInfo.score <= userEquip.score then
                    self:updatePartInfo(part, false, userEquip.score, userEquip.id)
                    return
                end
            end
        else
            -- 装备不在主角身上
            -- 装备如果在佣兵的身上
            if common:table_hasValue(EquipCategory.Dress, userEquip.id) then
                self:checkPartForMercenary(userEquip);
                return
            else
                -- 装备在背包里
                local currentEquip = self:getUserEquipById(roleEquip.equipId);
                if next(currentEquip) == nil then
                    -- local debugStr = "line 610 equipId = "..roleEquip.equipId
                    -- CCMessageBox(debugStr, "LUA ERROR")
                    return
                end
                local isHightScore = false
                if partInfo.needNotice then
                    if userEquip.score > partInfo.score then
                        self:updatePartInfo(part, true, userEquip.score, userEquip.id)
                    end
                else
                    if userEquip.score > currentEquip.score then
                        self:updatePartInfo(part, true, userEquip.score, userEquip.id)
                    end
                end
                -- 继续检查佣兵红点
                self:checkPartForMercenary(userEquip);
            end
        end
    else
        -- 更新佣兵身上的装备不产生红点
        if common:table_hasValue(EquipCategory.Dress, userEquip.id) then
            self:checkPartForMercenary(userEquip);
            -- self:updatePartInfo(part,true,userEquip.score,userEquip.id);
            return;
        end
        self:updatePartInfo(part, true, userEquip.score, userEquip.id)
        self:checkPartForMercenary(userEquip);
    end
end


-- 检查佣兵某个部位的红点（是否有更好的装备）,逻辑大致与主角一样
function UserEquipManager:checkPartForMercenary(userEquip)
    -- 检查部位
    local PBHelper = require("PBHelper")
    local part = EquipManager:getPartById(userEquip.equipId)
    if not common:table_hasValue(PartForMercenary, part) then return end

    local partInfo2 = EquipStatus.partInfo2[part] or { };

    local MercenaryInfos = UserMercenaryManager:getUserMercenaryInfos()
    local myMercenary = UserInfo.activiteRoleId
    if not myMercenary then return end
    local isNeedRefresh = false
    for i = 1, #myMercenary do
        local userMercenary = MercenaryInfos[myMercenary[i]]

        if userMercenary and EquipManager:isDressable(userEquip.equipId, userMercenary.prof) then
            local partInfo = partInfo2[userMercenary.roleId] or { };

            local needNotice = true
            local score = userEquip.score
            local id = partInfo.id or userEquip.id

            local roleEquip = PBHelper:getRoleEquipByPart(userMercenary.equips, part)
            if roleEquip and roleEquip.equipId then
                if userEquip.id == roleEquip.equipId then
                    if partInfo.needNotice then
                        if partInfo.score > userEquip.score then return; end
                        partInfo = { needNotice = false, score = 0, id = 0 }
                        EquipStatus.partInfo2[part][userMercenary.roleId] = partInfo
                        id = userEquip.id;
                    end
                    needNotice = false;
                else
                    local currentEquip = self:getUserEquipById(roleEquip.equipId);
                    if not currentEquip or next(currentEquip) == nil then
                        return
                    end
                    if userEquip.score <= currentEquip.score then
                        score = math.max(partInfo.score or 0, currentEquip.score);
                        if partInfo.needNotice then
                            if partInfo.id == userEquip.id then
                                partInfo = { needNotice = false, score = 0, id = 0 }
                                EquipStatus.partInfo2[part][userMercenary.roleId] = partInfo
                            --else
                                return
                            end
                        end
                        id = currentEquip.id;
                        needNotice = false;
                    else
                        id = userEquip.score > (partInfo.score or 0) and userEquip.id or partInfo.id;
                        score = math.max(userEquip.score, partInfo.score or 0);
                        if not partInfo.needNotice then
                            if EquipStatus.noticeCount2 ~= nil then
                                local count = EquipStatus.noticeCount2[userMercenary.roleId];
                                if count == nil then
                                    count = 0;
                                end
                                EquipStatus.noticeCount2[userMercenary.roleId] = count + 1;
                            end
                        end
                    end
                end
            else
                if not partInfo.needNotice then
                    if EquipStatus.noticeCount2 ~= nil then
                        local count = EquipStatus.noticeCount2[userMercenary.roleId];
                        if count == nil then
                            count = 0;
                        end
                        EquipStatus.noticeCount2[userMercenary.roleId] = count + 1;
                    end
                end
                id = userEquip.id;
            end
            partInfo2[userMercenary.roleId] = {
                needNotice = needNotice,
                score = score,
                id = id
            };
            EquipStatus.partInfo2[part] = partInfo2;
        end
    end

end

-- 装备删除后检查红点
function UserEquipManager:checkPartAfterDelete(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    if next(userEquip) == nil then
        return
    end
    local part = EquipManager:getPartById(userEquip.equipId);
    local partInfo = EquipStatus.partInfo[part] or { };
    local partScore = partInfo.score or 0;


    if not EquipManager:isDressable(userEquip.equipId, UserInfo.roleInfo.prof) then
        -- 主角不能装备，继续检查佣兵
        self:checkPartForMercenaryAfterDelete(userEquipId);
        return;
    end

    --[[	--有红点，且删除的是提示装备，则取消红点
	if partInfo.needNotice and userEquipId == partInfo.id then
		EquipStatus.partInfo[part] = {
			needNotice = false,
			score = 0,
			id = nil
		};
		self:cancelNotice(part);
	end
	--继续检查佣兵
	self:checkPartForMercenaryAfterDelete(userEquipId);]]
    if part ~= 0 then
        self:isCancelEquipRedPoint(part)
    end
end

-- 装备删除后检查佣兵红点，逻辑大致与主角一样 
function UserEquipManager:checkPartForMercenaryAfterDelete(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    if next(userEquip) == nil then
        return
    end
    local part = EquipManager:getPartById(userEquip.equipId);
    if not common:table_hasValue(PartForMercenary, part) then return; end

    local partInfo2 = EquipStatus.partInfo2[part] or { };
    for roleId, v in pairs(partInfo2) do
        if v.id == userEquipId then
            v.id = nil
            v.needNotice = false
            v.score = 0
            self:cancelNotice(part, roleId);
        end
    end
end

-- 取消红点，若各部位都无红点，取消banner红点
-- @Param roleId: 佣点roleId, 若为nil,则为主角身上的红点
function UserEquipManager:cancelNotice(part, roleId)
    -- 佣兵红点
    local partInfo = EquipStatus.partInfo2[part] or { };
    local a = roleId
    local b = partInfo[roleId]
    local c = a and b
    if roleId and partInfo[roleId] then
        partInfo[roleId] = {
            needNotice = false,
            score = 0,
            id = 0
        };
        if EquipStatus.noticeCount2 ~= nil then
            local count = EquipStatus.noticeCount2[roleId];
            if count == nil or count <= 0 then
                EquipStatus.noticeCount2[roleId] = 0;
            else
                EquipStatus.noticeCount2[roleId] = count - 1;
            end
        end
    end
end

-- 上装后取消红点
function UserEquipManager:cancelNoticeAfterTakeOn(userEquipId, roleId)
local userEquip = self:getUserEquipById(userEquipId);
    --if next(userEquip) == nil then
    --    return
    --end
	--local rolId = UserInfo.roleInfo.roleId
	--local part = EquipManager:getPartById(userEquip.equipId);
	----mercenary
	--for _part, _partInfo2 in pairs(EquipStatus.partInfo2) do
	--	if _part == part then
	--		for roId, _partInfo in pairs(_partInfo2) do
    ----[[				if _partInfo.id and _partInfo.id == userEquipId then
	--				self:cancelNotice(part, roleId);
	--			end]]
	--			if roId == roleId then
	--				if  _partInfo.id == userEquipId then
	--					self:cancelNotice(part,roleId);
	--				elseif  _partInfo.score == userEquip.score then
	--					_partInfo.id = userEquipId
	--					self:cancelNotice(part,roleId);
	--				end
	--			end
	--		end
	--	end
	--end
end

-- 某个部位是否有红点（有更好的装备）
-- @param roleId: 佣兵id, nil为主角
function UserEquipManager:isPartNeedNotice(part, roleId)
    -- 佣兵
    local partInfo2 = EquipStatus.partInfo2[part] or { };
    local partInfo = partInfo2[roleId] or { };
    return partInfo.needNotice or false;
end

-- 某个佣兵是否有红点（有更好的装备
-- @param roleId: 佣兵id, nil为主角
function UserEquipManager:isRoleNeedNotice(roleId)
    -- 主角
    if roleId == nil then
        return false
    end

    local partInfo2, partInfo
    for i, part in ipairs(PartForMercenary) do
        partInfo2 = EquipStatus.partInfo2[part] or { };
        partInfo = partInfo2[roleId] or { };
        if partInfo.needNotice then
            return true
        end
    end
    return false
end

------------------------------------------------------------------------------------------
-- ***************获取各个分类的装备个数*****************--
function UserEquipManager:countByClass(_class, subClass)
    if _class == "All" then
        return self:countEquipAll();
    elseif _class == "Part" then
        return self:countEquipWithPart(subClass);
    elseif _class == "Quality" then
        return self:countEquipWithQuality(subClass);
    end
    return 0;
end

function UserEquipManager:countEquipWithPart(part)
    local tb = EquipCategory.Part[part];
    return tb and #tb or 0;
end

function UserEquipManager:countEquipWithQuality(quality)
    local tb = EquipCategory.Quality[quality];
    return tb and #tb or 0;
end

function UserEquipManager:countEquipForBatchSell(quality)
    local tb = EquipCategory.Quality[quality] or { };
    local i = 0;
    for _, id in ipairs(tb) do
        if not self:isGodly(id) and not self:hasGem(id) then
            i = i + 1;
        end
    end
    return i;
end

function UserEquipManager:countEquipGodly()
    return #EquipCategory.Godly;
end

function UserEquipManager:countEquipAll()
    return #EquipCategory.All;
end

function UserEquipManager:getEquipAll()
    return EquipCategory.All;
end

function UserEquipManager:getEquipDress()
    return EquipCategory.Dress;
end

------------------------------------------------------------------------------------------
-- 获取各分类对应装备id
function UserEquipManager:getEquipIdsByClass(_class, subClass)
    local _class = _class or "All";
    if _class == "All" or _class == "Godly" or _class == "Dress" then
        return EquipCategory[_class];
    else
        return EquipCategory[_class][subClass] or { };
    end
end

-- 装备是否装在身上（包括主角和佣兵）
function UserEquipManager:isEquipDressed(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    return self:isDressedWithEquipInfo(userEquip);
end

-- 装备是否装在主角身上
function UserEquipManager:isEquipDressedOnPlayer(userEquip)
    local part = EquipManager:getPartById(userEquip.equipId);

    local roleEquip = UserInfo.getEquipByPart(part);
    if roleEquip and roleEquip.equipId == userEquip.id then
        return true;
    end;
    return false;
end
	
function UserEquipManager:isDressedWithEquipInfo(userEquip)
    return self:isEquipDressedOnPlayer(userEquip) or UserMercenaryManager:isEquipDressed(userEquip.id);
end

------------以下部分专为洗练-----------

-- 获取用户装备属性信息
-- @Return: Html String
function UserEquipManager:getEquipInfoBaptizeString(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    return self:getBaptizeAtrr(userEquip);
end

-- 获取装备属性信息(装备限制、评分)
-- @Return: Html String
function UserEquipManager:getBaptizeAtrr(userEquip)
    local retStr = "";
    local suffix = "" or "_1";
    -- 使用不现的html配置，主要是字体大小不同
    local glue = '<br/>';
    -- 字体串拼接符

    local strTb = { };

    local equipId = userEquip.equipId;

    -- 职业限制信息(如果有)
    local professionId = EquipManager:getProfessionById(equipId);
    if professionId and professionId > 0 then
        local professionName = common:getLanguageString("@ProfessionName_" .. professionId);
        -- table.insert(strTb, common:getLanguageString("@EquipCondition", professionName));
        table.insert(strTb, common:fillHtmlStr("EquipCondition" .. suffix, professionName));
    end

    -- 评分
    local grade = userEquip.score;
    -- table.insert(strTb, common:getLanguageString("@EquipGrade", grade));
    --table.insert(strTb, common:fillHtmlStr("EquipGrade" .. suffix, grade));
    table.insert(strTb, grade);

    local strength = EquipManager:getAttrById(userEquip.equipId, "punchConsume");


    local commonInfo = table.concat(strTb, glue);
    retStr = commonInfo;


    -- 通过margin设置不同的宽度
    local margin = GameConfig.Margin.EquipInfo or GameConfig.Margin.EquipSelect;
    return common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end


-- 获取用户装备属性信息
-- @Param MainAtrr: 主属性类别
-- @Return: Html String
function UserEquipManager:getEquipInfoMainString(userEquipId, MainAtrr)
    local userEquip = self:getUserEquipById(userEquipId);
    return self:getMainStr(userEquip, MainAtrr);
end

-- 获取装备属性信息(主属性)

-- @Return: Html String
function UserEquipManager:getMainStr(userEquip, MainAtrr)
    local retStr = "";
    local glue = '<br/>';
    -- 字体串拼接符

    local strTb = { };

    local equipId = userEquip.equipId;

    local quality = EquipManager:getQualityById(equipId);

    local Arrmatch = nil
    if (MainAtrr == "STRENGHT") then
        Arrmatch = Const_pb.STRENGHT;
    end
    if (MainAtrr == "AGILITY") then
        Arrmatch = Const_pb.AGILITY;
    end
    if (MainAtrr == "INTELLECT") then
        Arrmatch = Const_pb.INTELLECT;
    end
    if (MainAtrr == "STAMINA") then
        Arrmatch = Const_pb.STAMINA;
    end

    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local grade = equipAttr.attrGrade;
        local attr = equipAttr.attrData;



        local name = common:getAttrName(attr.attrId);
        if attr.attrId == Arrmatch then
            attrStr = common:getLanguageString("@EquipAttrVal", name, attr.attrValue);
            return attrStr, quality;
        end
    end

    return "";
    -- local key = grade == Const_pb.PRIMARY_ATTR and "MainAttr" or "SecondaryAttr_" .. quality;
    -- return common:fillHtmlStr(key, attrStr);
end

-- 获取用户装备品质
-- @Return: String
function UserEquipManager:getQuality(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    return EquipManager:getQualityById(userEquip.equipId);
end

-- 获取用户装备属性信息
-- @Param isAll: 是否全部显示
-- @Return: Html String
function UserEquipManager:getEquipInfoString(userEquipId, isAll)
    local userEquip = self:getUserEquipById(userEquipId);
    return self:getDesciptionWithEquipInfo(userEquip, isAll);
end

function UserEquipManager:getEquipDescBasicInfo(userEquip, isAll, isViewingOther, roleInfo,selectlist)
    local retStr = "";
    local suffix = isAll and "" or "_1";
    -- 使用不现的html配置，主要是字体大小不同
    local glue = '<br/>';
    -- 字体串拼接符

    local strTb = { };

    local equipId = userEquip.equipId;

    -- 套装名称
    local EquipManager = require("Equip.EquipManager")
    local suitId = EquipManager:getSuitIdById(userEquip.equipId)
    if suitId > 0 then
        local suitCfg = ConfigManager.getSuitCfg()
        local suitName = common:fillHtmlStr("EquipSuitName", suitCfg[suitId].suitName, self:getEquipedSuitCount(suitId, roleInfo), tostring(suitCfg[suitId].maxNum))
        table.insert(strTb, suitName)
    end

    -- 职业限制信息(如果有)
    --local professionId = EquipManager:getProfessionById(equipId);
    --if professionId and professionId > 0 then
    --    UserInfo.sync()
    --    local isMyProfession =(professionId == UserInfo.roleInfo.prof and not isViewingOther) and "" or "_F"
    --    local professionName = common:getLanguageString("@ProfessionName_" .. professionId);
    --    -- table.insert(strTb, common:getLanguageString("@EquipCondition", professionName));
    --    table.insert(strTb, common:fillHtmlStr("EquipCondition" .. suffix .. isMyProfession, professionName));
    --end

    -- 评分
    local grade = self:calEquipScore(userEquip)--userEquip.score;
    if not selectlist then
    --table.insert(strTb, common:getLanguageString("@EquipGrade", grade));
    table.insert(strTb, common:fillHtmlStr("EquipGrade" .. suffix, grade));
    else
    table.insert(strTb, grade);
    end
    local commonInfo = table.concat(strTb, glue);
    retStr = commonInfo;

    -- 通过margin设置不同的宽度
    local margin = GameConfig.Margin.EquipSelect
    return common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

--- 深颜色界面
function UserEquipManager:getEquipDescBasicInfo_deep(userEquip, isAll, isViewingOther, roleInfo)
    local retStr = "";
    local suffix = isAll and "" or "";
    -- 使用不现的html配置，主要是字体大小不同
    local glue = '<br/>';
    -- 字体串拼接符

    local strTb = { };

    local equipId = userEquip.equipId;

    -- 套装名称
    --local EquipManager = require("Equip.EquipManager")
    --local suitId = EquipManager:getSuitIdById(userEquip.equipId)
    --if suitId > 0 then
    --    local suitCfg = ConfigManager.getSuitCfg()
    --    local suitName = common:fillHtmlStr("EquipSuitName_deep", suitCfg[suitId].suitName, self:getEquipedSuitCount(suitId, roleInfo), tostring(suitCfg[suitId].maxNum))
    --    table.insert(strTb, suitName)
    --end
    --
    ---- 职业限制信息(如果有)
    --local professionId = EquipManager:getProfessionById(equipId);
    --if professionId and professionId > 0 then
    --    UserInfo.sync()
    --    local isMyProfession =(professionId == UserInfo.roleInfo.prof and not isViewingOther) and "" or "_F"
    --    local professionName = common:getLanguageString("@ProfessionName_" .. professionId);
    --    -- table.insert(strTb, common:getLanguageString("@EquipCondition", professionName));
    --    table.insert(strTb, common:fillHtmlStr("EquipCondition_deep" .. suffix .. isMyProfession, professionName));
    --end

    -- 评分
    local grade = userEquip.score;
    -- table.insert(strTb, common:getLanguageString("@EquipGrade", grade));
    --table.insert(strTb, common:fillHtmlStr("EquipGrade_deep" .. suffix, grade));
    table.insert(strTb,  grade);

    local commonInfo = table.concat(strTb, glue);
    retStr = commonInfo;

    -- 通过margin设置不同的宽度
    local margin = GameConfig.Margin.EquipSelect
    return common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

function UserEquipManager:getEquipSpaceImg()
    local imgStr = ""
    local tempPic = FreeTypeConfig[700].content

    local relaPath = "UI/Common/Image/Image_EquipInfo_Line.png"
    -- GameConfig.ChatFace[tonumber(string.sub(f,string.find(f , "%d+")))]
    local picPath = CCFileUtils:sharedFileUtils():fullPathForFilename(relaPath)
    imgStr = string.gsub(tempPic, "#v1#", picPath)
    return imgStr
end

-- 获取装备属性信息(装备限制、评分、主属性、副属性、神器属性、神器全身强化效果、宝石加成)
-- @Param isAll: 是否全部显示（是否显示神器全身强化效果、宝石加成）,文体大小会不同
-- @Param isViewingOther: 是否是查看别人阵容
-- @Return: Html String
-- @showMoreEnhanceLevel:显示更多的加成信息 用于装备筛选界面
function UserEquipManager:getDesciptionWithEquipInfo1(userEquip, isAll, isViewingOther, roleInfo, showMoreEnhanceLevel, _isNotDress)
    local retStr = "";
    local suffix = isAll and "" or ""
    -- "_1";	--使用不现的html配置，主要是字体大小不同
    local glue = '<br/>';
    -- 字体串拼接符

    local strTb = { };

    local equipId = userEquip.equipId;
    local suitId = EquipManager:getSuitIdById(userEquip.equipId)

    if isAll then
        --- 添加图片间隔
        local imgStr = UserEquipManager:getEquipSpaceImg()
        table.insert(strTb, imgStr);
    end

    table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@EquipStr1")));
    -- 从装备数据中分类出属性数据（主、副、神）
    local quality = EquipManager:getQualityById(userEquip.equipId);
    local attrTb = {
        [Const_pb.PRIMARY_ATTR] = { },
        [Const_pb.SECONDARY_ATTR] = { },
        [Const_pb.GODLY_ATTR] = { }
    };
    -- showMoreEnhanceLevel 显示出这个等级的主属性
    local nextAttrTb = { [Const_pb.PRIMARY_ATTR] = { } }
    ----伤害显示特殊处理
    local dmg = { };
    local ismin = 0
    --- 0 最小 1最大  2最小最大
    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local grade = equipAttr.attrGrade;
        local attr = equipAttr.attrData;
        local doCheck = false;
        if attr.attrId == Const_pb.MINDMG then
            doCheck = true;
            dmg.min = attr.attrValue;
        elseif attr.attrId == Const_pb.MAXDMG then
            doCheck = true;
            dmg.max = attr.attrValue;
        end

        if doCheck and dmg.min then
            ismin = 0
        end

        if doCheck and dmg.max then
            ismin = 1
        end

        if doCheck and dmg.min and dmg.max then
            ismin = 2
        end
    end

    local dmg = { };
    -- 分类
    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local grade = equipAttr.attrGrade;
        local attr = equipAttr.attrData;

        local attrStr = nil;
        local addStr = nil
        local morAttrStr = nil
        local baseAttrInfo = nil
        local morEnahceInfo = nil
        local currBaseVal = EquipManager:getAttrAddVAl(quality, userEquip.strength) or 0
        local curStr = currBaseVal / 10000
        baseAttrInfo = EquipManager:getInitAttrInfo(equipId)
        if showMoreEnhanceLevel then
            morEnahceInfo = common:fillHtmlStr("MorEnhanceInfo", showMoreEnhanceLevel)
            local currVal = EquipManager:getAttrAddVAl(quality, showMoreEnhanceLevel - 1) or 0
            local nextVal = EquipManager:getAttrAddVAl(quality, showMoreEnhanceLevel) or currVal
            addStr = nextVal / 10000
        end
        -- 针对伤害特殊处理
        local doCheck = false;
        if attr.attrId == Const_pb.MINDMG then
            dmg.min = attr.attrValue;
            dmg.min = math.floor(baseAttrInfo[attr.attrId].attrValMax *(1 + curStr))
            -- 服务器的数据算上了神器属性的加成，客户端重新计算，去除加成值的影响
            doCheck = true;
        elseif attr.attrId == Const_pb.MAXDMG then
            dmg.max = attr.attrValue;
            dmg.max = math.floor(baseAttrInfo[attr.attrId].attrValMax *(1 + curStr))
            doCheck = true;
        else
            local name = common:getAttrName(attr.attrId);
            if grade == Const_pb.SECONDARY_ATTR and not isAll then
                local len = GameConfig.LineWidth.SecondaryAttrNum;
                len = tostring(attr.attrValue):len() % 2 == 0 and len or(len + 1);
                local fmt = "%s +%-" .. len .. "s";
                attrStr = string.format(fmt, name, attr.attrValue);
            else
                local value = attr.attrValue
                if baseAttrInfo[attr.attrId] then
                    value = math.floor(baseAttrInfo[attr.attrId].attrValMax *(1 + curStr))
                end
                attrStr = common:getLanguageString("@EquipAttrVal", name, value);
                if addStr then
                    morAttrStr = common:getLanguageString("@EquipAttrVal", name, math.floor(baseAttrInfo[attr.attrId].attrValMax *(1 + addStr)))
                end
            end
        end

        if doCheck then
            if ismin == 0 and dmg.min then
                attrStr = common:getLanguageString("@AttrName_103") .. ":" .. tostring(dmg.min)
                if addStr then
                    morAttrStr = common:getLanguageString("@AttrName_103") .. ":" .. math.floor(baseAttrInfo[Const_pb.MINDMG].attrValMax *(1 + addStr))
                end
                dmg = { };
            elseif ismin == 1 and dmg.max then
                attrStr = common:getLanguageString("@AttrName_104") .. ":" .. tostring(dmg.max)
                if addStr then
                    morAttrStr = common:getLanguageString("@AttrName_104") .. ":" .. math.floor(baseAttrInfo[Const_pb.MAXDMG].attrValMax *(1 + addStr))
                end
                dmg = { };
            elseif ismin == 2 and dmg.min and dmg.max then
                attrStr = common:getLanguageString("@EquipDMGVal", dmg.min, dmg.max);
                if addStr then
                    morAttrStr = common:getLanguageString("@EquipDMGVal", math.floor(baseAttrInfo[Const_pb.MINDMG].attrValMax *(1 + addStr)), math.floor(baseAttrInfo[Const_pb.MAXDMG].attrValMax *(1 + addStr)))
                end
                dmg = { };
            end
        end
        if attrStr ~= nil then
            local key = grade == Const_pb.PRIMARY_ATTR and "MainAttr" or "SecondaryAttr_" .. quality;
            key = key .. suffix;
            attrTb[grade][attr.attrId] = common:fillHtmlStr(key, attrStr);
            if grade == Const_pb.PRIMARY_ATTR and showMoreEnhanceLevel ~= nil and morAttrStr then
                nextAttrTb[grade][attr.attrId] = common:fillHtmlStr(key, morAttrStr) .. morEnahceInfo
            end
        end
    end


    -- 显示额外等级的主属性
    if showMoreEnhanceLevel ~= nil then
        for attrGrade, subAttrTb in ipairs(nextAttrTb) do
            local str = "";
            if attrGrade == Const_pb.PRIMARY_ATTR then
                str = common:table_implode(subAttrTb, glue)
                if str ~= "" then
                    table.insert(strTb, str)
                end
            end
        end
    else
        ----显示主属性
        for attrGrade, subAttrTb in ipairs(attrTb) do
            local str = "";
            if attrGrade == Const_pb.PRIMARY_ATTR then
                str = common:table_implode(subAttrTb, glue);
                if str ~= "" then
                    table.insert(strTb, str);
                end
            end
        end
    end

    local hasSecondary = true

    -- 显示副属性
    for attrGrade, subAttrTb in ipairs(attrTb) do
        if attrGrade == Const_pb.SECONDARY_ATTR or attrGrade == Const_pb.GODLY_ATTR then
            local str = "";
            -- 非全显时，把副属性两两一行显示
            if attrGrade == Const_pb.SECONDARY_ATTR and not isAll then
                local format = "%s%s%s%s";
                local attrIds = common:table_keys(subAttrTb);
                for i, attrId in ipairs(attrIds) do
                    if i % 2 == 1 then
                        local nextAttrId = attrIds[i + 1] or 0;
                        local prefix = i > 1 and glue or "";
                        str = string.format(format, str, prefix, subAttrTb[attrId], subAttrTb[nextAttrId] or "");
                    end
                end
            else
                str = common:table_implode(subAttrTb, glue);
            end

            if str ~= "" then
                if hasSecondary then
                    if isAll then
                        --- 添加图片间隔
                        local imgStr = UserEquipManager:getEquipSpaceImg()
                        table.insert(strTb, imgStr);
                    end
                    --table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@EquipStr2")));
                    hasSecondary = false
                end
                table.insert(strTb, str);
            end
        end
    end

    -- 是否是佣兵专属套装
    local mercenarySuitId = EquipManager:getMercenarySuitId(equipId);
    if mercenarySuitId and mercenarySuitId > 0 then
        -- local GodlyAttrCfg = ConfigManager.getGodlyAttrCfg();
        --- 添加图片间隔
        local imgStr = UserEquipManager:getEquipSpaceImg()
        table.insert(strTb, imgStr);
        local _roleId = EquipManager:getMercenarySuitMercenaryId(mercenarySuitId)
        --if tonumber(_roleId) < 10 and tonumber(_roleId) > 0 then
        --    local roleConfig = ConfigManager.getRoleCfg()
        --    _roleId = roleConfig[_roleId].profession * 10 + 1  
        --end
        if tonumber(_roleId) == 0 then
            table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@MasterEquipStr1")))
        else
            table.insert(strTb, common:fillHtmlStr("equipAttrColor", common:getLanguageString("@Role_" .. _roleId) .. common:getLanguageString("@EquipStr6")));
        end
        
        local descs = EquipManager:getMercenarySuitDescs(mercenarySuitId)
        local isSuit = false
        if roleInfo then
            local suitMercenaryIds = EquipManager:getMercenarySuitMercenaryIds(mercenarySuitId)
            for i, v in ipairs(suitMercenaryIds) do
                if tonumber(v) == roleInfo.itemId then
                    isSuit = true
                end
            end
        end
        for k, v in pairs(descs) do
            if v ~= "" then
                if isSuit then
                    table.insert(strTb, common:fillHtmlStr("GreenFontColor", common:getLanguageString(v)));
                else
                    table.insert(strTb, common:fillHtmlStr("GrayFontColor", common:getLanguageString(v)));
                end
            end
        end
    end

    -- 组合套装属性
    if suitId > 0 then
        if isAll then
            --- 添加图片间隔
            local imgStr = UserEquipManager:getEquipSpaceImg()
            table.insert(strTb, imgStr);
        end
        table.insert(strTb, common:fillHtmlStr("EquipSuitAttrs"))
        local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
        local suitCfg = ConfigManager.getSuitCfg()
        for i = 1, #suitCfg[suitId].conditions, 1 do
            local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
            local suitAttrId = suitCfg[suitId].attrIds[i]
            if UserEquipManager:getEquipedSuitCount(suitId, roleInfo) >= tonumber(suitCfg[suitId].conditions[i]) then
                table.insert(strTb, common:fillHtmlStr("EquipSuitAttrs" .. i, suitCfg[suitId].conditions[i], suitAttrCfg[suitAttrId].describe))
            else
                table.insert(strTb, common:fillHtmlStr("EquipSuitAttrsF", suitCfg[suitId].conditions[i], suitAttrCfg[suitAttrId].describe))
            end
        end
    end



    -- 神器属性、神器全身强化效果
    local godlyInfo = self:getGodlyInfo(userEquip, isAll, isViewingOther, "", roleInfo);
    if godlyInfo ~= "" then
        if isAll then
            local imgStr = UserEquipManager:getEquipSpaceImg()
            table.insert(strTb, imgStr);
        end
        -- retStr = retStr .. glue .. godlyInfo;
        table.insert(strTb, godlyInfo);
    end

    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
    if table.maxn(gemInfo) > 0 and isAll then
        local imgStr = UserEquipManager:getEquipSpaceImg()
        table.insert(strTb, imgStr);
    end

    -- 宝石加成
    if isAll then
        local gemInfo = self:getGemInfo(userEquip);
        if gemInfo ~= "" then
            -- retStr = retStr .. glue .. gemInfo;
            table.insert(strTb, gemInfo);
        end
    end

    -- 不可装扮 提示文字
    if _isNotDress then
        table.insert(strTb, "")
        local notDressStr = common:fillHtmlStr("RedFreeTypeFont", 18, common:getLanguageString("@HighLevelToEquip"))
        table.insert(strTb, notDressStr);
    end

    local commonInfo = table.concat(strTb, glue);
    retStr = commonInfo;
    -- 通过margin设置不同的宽度
    local margin = isAll and GameConfig.Margin.EquipInfo or GameConfig.Margin.EquipSelect;
    return common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

function UserEquipManager:getMainAttrStrAndNum(userEquip)
    local str = { }
    -- 第一个为属性字符串 第二个为属性值
    local num = 0
    local dmg = { };
    local attrInfos = { }
    -- 分类
    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local grade = equipAttr.attrGrade;
        local attr = equipAttr.attrData;
        local attrStr = nil;
        -- 针对伤害特殊处理
        local doCheck = false;

        if grade == Const_pb.PRIMARY_ATTR then
            
            if(GameUtil:checkEquipKeyNeed(attr.attrId))
            then
                local temp = { }
                local name = common:getAttrName(attr.attrId);
                temp[1] = name
                temp[2] = attr.attrValue
                temp[3] = attr.attrId
                str[#str + 1] = temp
            end
        end
    end

    return str
end

-- 获取装备属性信息(装备限制、评分、主属性、副属性、神器属性、神器全身强化效果、宝石加成)
-- @Param isAll: 是否全部显示（是否显示神器全身强化效果、宝石加成）,文体大小会不同
-- @Param isViewingOther: 是否是查看别人阵容
-- @Param num : 一個content最多顯示幾個
-- @Return: Html String
function UserEquipManager:getDesciptionWithEquipInfo1_deep(userEquip, isAll, isViewingOther, roleInfo, num)
    local a1 = userEquip.id
    local a2 = userEquip.equipId
    local a3 = userEquip.strength
    local a4 = userEquip.starLevel
    local a5 = userEquip.starExp
    local a6 = userEquip.godlyAttrId
    local a7 = userEquip.gemInfos
    local a8 = userEquip.attrInfos
    local a9 = userEquip.status
    local a0 = userEquip.score
    local a11 = userEquip.lock
    local a12 = userEquip.starLevel2
    local a13 = userEquip.starExp2
    local a14 = userEquip.godlyAttrId2
    local a15 = userEquip.relateSuitId

    local retStr = "";
    local suffix = isAll and "" or ""
    -- "_1";	--使用不现的html配置，主要是字体大小不同
    local glue = '<br/>';
    -- 字体串拼接符

    local strTb = { };
    local strTTb = { };

    local equipId = userEquip.equipId;
    local suitId = EquipManager:getSuitIdById(userEquip.equipId)

    if isAll then
        --- 添加图片间隔
        local imgStr = UserEquipManager:getEquipSpaceImg()
        table.insert(strTb, imgStr);
    end
    -- 主屬性title
    --table.insert(strTb, common:fillHtmlStr("equipAttrColor_deep", common:getLanguageString("@EquipStr1")));
    --table.insert(strTb, common:getLanguageString("@EquipStr1"));
    -- 从装备数据中分类出属性数据（主、副、神）
    local quality = EquipManager:getQualityById(userEquip.equipId);
    local attrTb = {
        [Const_pb.PRIMARY_ATTR] = { },
        [Const_pb.SECONDARY_ATTR] = { },
        [Const_pb.GODLY_ATTR] = { }
    };

    ----伤害显示特殊处理
    local dmg = { };
    local ismin = 0
    --- 0 最小 1最大  2最小最大
    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local grade = equipAttr.attrGrade;
        local attr = equipAttr.attrData;
        local doCheck = false;

        if attr.attrId == Const_pb.MINDMG then
            doCheck = true;
            dmg.min = attr.attrValue;
        elseif attr.attrId == Const_pb.MAXDMG then
            doCheck = true;
            dmg.max = attr.attrValue;
        end

        if doCheck and dmg.min then
            ismin = 0
        end

        if doCheck and dmg.max then
            ismin = 1
        end

        if doCheck and dmg.min and dmg.max then
            ismin = 2
        end
    end

    local dmg = { };
    local moreEnhanceAttr = { }
    -- 分类
    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local grade = equipAttr.attrGrade;
        local attr = equipAttr.attrData;

        local attrStr = nil;
        local currBaseVal = EquipManager:getAttrAddVAl(quality, userEquip.strength) or 0
        local curStr = 0--currBaseVal / 10000
        local baseAttrInfo = EquipManager:getInitAttrInfo(equipId)

        local doCheck = false;
        local name = common:getAttrName(attr.attrId)
        local value = attr.attrValue
        if baseAttrInfo[attr.attrId] then
            value = math.floor(value * (1 + curStr))
        end
        if grade == Const_pb.SECONDARY_ATTR and not isAll then
            local len = GameConfig.LineWidth.SecondaryAttrNum;
            len = tostring(value):len() % 2 == 0 and len or(len + 1);
            local fmt = "%s_+%-" .. "s";
            attrStr = string.format(fmt, name, value);
        else
            local fmt = "%s_+%-" .. "s";
            attrStr = string.format(fmt, name, value);
        end

        if attrStr ~= nil then
            local key = grade == Const_pb.PRIMARY_ATTR and "MainAttr_1" or "SecondaryAttr_" .. quality .. "_1";
            key = key .. suffix;
            attrTb[grade][attr.attrId] = attrStr;
        end
    end

    local sizeInfo = 0;
    local index = 0;
    ----显示主属性
    for attrGrade, subAttrTb in ipairs(attrTb) do
        local str = "";
        local str_attrId = "";
        if attrGrade == Const_pb.PRIMARY_ATTR then     
            for k, v in pairs(subAttrTb) do
                index = index + 1;
                if str ~= "" then
                    str = str .. ",";
                    str_attrId = str_attrId .. ",";
                end
                if index % 2 == 1 then               
                    sizeInfo = sizeInfo + 1;
                end
                str = str .. tostring(v);
                str_attrId = str_attrId .. tostring(k);
            end

            if str ~= "" then
                table.insert(strTb, str);
                table.insert(strTTb, str_attrId);                
            end
        end
    end
   
    local hasSecondary = true;
    local additionalIndex = 0;
    if((index / num) < 1)then
        additionalIndex = 2;
    else
        additionalIndex = math.modf(index / num) + 1;--index + 1;
    end   
    -- 显示副属性
    for attrGrade, subAttrTb in ipairs(attrTb) do
        if attrGrade == Const_pb.SECONDARY_ATTR or attrGrade == Const_pb.GODLY_ATTR then
            local str = "";
            local str_attrId = "";
            -- 非全显时，把副属性两两一行显示
            if attrGrade == Const_pb.SECONDARY_ATTR and not isAll then
                local format = "%s%s%s%s";
                local attrIds = common:table_keys(subAttrTb);
                for i, attrId in ipairs(attrIds) do
                    if i % 2 == 1 then
                        local nextAttrId = attrIds[i + 1] or 0;
                        local prefix = i >= 1 and "," or "";
                        if(subAttrTb[nextAttrId] == nil)
                        then
                            prefix = "";
                        end
                        str = string.format(format, str, subAttrTb[attrId], prefix, subAttrTb[nextAttrId] or "");
                        if (nextAttrId == 0) then
                            nextAttrId = "";
                        end
                        str_attrId = string.format(format, str_attrId, attrId, prefix, nextAttrId or "");
                        if(subAttrTb[nextAttrId] and (i + 1) < #attrIds)
                        then
                            str = str .. ",";
                            str_attrId = str_attrId .. ",";
                        end                                                                                     
                        sizeInfo = sizeInfo + 1;
                    end                    
                end               
            end

            if str ~= "" then
                if hasSecondary then
                    if isAll then
                        --- 添加图片间隔
                        local imgStr = UserEquipManager:getEquipSpaceImg()
                        table.insert(strTb, imgStr);
                    end
                    -- 副屬性title
                    hasSecondary = false
                end
                table.insert(strTb, str);
                table.insert(strTTb, str_attrId);
            end
        end
    end

    -- 是否是佣兵专属套装
    local mercenarySuitId = EquipManager:getMercenarySuitId(equipId);
    if mercenarySuitId and mercenarySuitId > 0 then
        table.insert(strTb, common:fillHtmlStr("equipAttrColor_deep", common:getLanguageString("@Role_" .. EquipManager:getMercenarySuitMercenaryId(mercenarySuitId)) .. common:getLanguageString("@EquipStr6")));

        local descs = EquipManager:getMercenarySuitDescs(mercenarySuitId)
        local isSuit = false
        if roleInfo then
            local suitMercenaryIds = EquipManager:getMercenarySuitMercenaryIds(mercenarySuitId)
            for i, v in ipairs(suitMercenaryIds) do
                if tonumber(v) == roleInfo.itemId then
                    isSuit = true
                end
            end
        end
        for k, v in pairs(descs) do
            if isSuit then
                table.insert(strTb, common:fillHtmlStr("GreenFontColor_deep", common:getLanguageString(v)));
            else
                table.insert(strTb, common:fillHtmlStr("GrayFontColor_deep", common:getLanguageString(v)));
            end
        end
    end

    -- 组合套装属性
    local suitAttrTb = { }
    if suitId > 0 then
        if isAll then
            --- 添加图片间隔
            local imgStr = UserEquipManager:getEquipSpaceImg()
            table.insert(suitAttrTb, imgStr);
        end
        local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
        local suitCfg = ConfigManager.getSuitCfg()
        for i = 1, #suitCfg[suitId].conditions, 1 do
            local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
            local suitAttrId = suitCfg[suitId].attrIds[i]
            if UserEquipManager:getEquipedSuitCount(suitId, roleInfo) >= tonumber(suitCfg[suitId].conditions[i]) then
                table.insert(suitAttrTb, common:fillHtmlStr("EquipSuitAttrs_deep" .. i, suitCfg[suitId].conditions[i], suitAttrCfg[suitAttrId].describe))
            else
                table.insert(suitAttrTb, common:fillHtmlStr("EquipSuitAttrsF_deep", suitCfg[suitId].conditions[i], suitAttrCfg[suitAttrId].describe))
            end
        end
    end
    -- 神器属性、神器全身强化效果
    local godlyInfo = self:getGodlyInfo(userEquip, isAll, isViewingOther, "_deep", roleInfo);
    if godlyInfo ~= "" then
        if isAll then
            local imgStr = UserEquipManager:getEquipSpaceImg()
            table.insert(strTb, imgStr);
        end
        -- retStr = retStr .. glue .. godlyInfo;
        table.insert(strTb, godlyInfo);
    end

    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
    if table.maxn(gemInfo) > 0 and isAll then
        local imgStr = UserEquipManager:getEquipSpaceImg()
        table.insert(strTb, imgStr);
    end

    if isAll then
        local gemInfo = self:getGemInfo(userEquip, "_deep");
        if gemInfo ~= "" then
            -- retStr = retStr .. glue .. gemInfo;
            table.insert(strTb, gemInfo);
        end
    end
    return strTb, sizeInfo, additionalIndex, strTTb, suitAttrTb;
end

-- 获取装备属性信息(装备限制、评分、主属性、副属性、神器属性、神器全身强化效果、宝石加成)
-- @Param isAll: 是否全部显示（是否显示神器全身强化效果、宝石加成）,文体大小会不同
-- @Param isViewingOther: 是否是查看别人阵容
-- @Return: Html String
function UserEquipManager:getDesciptionWithEquipInfo(userEquip, isAll, isViewingOther, roleInfo)
    local retStr = "";
    local suffix = isAll and "" or "_1";
    -- 使用不现的html配置，主要是字体大小不同
    local glue = '<br/>';
    -- 字体串拼接符

    local strTb = { };

    local equipId = userEquip.equipId;

    -- 套装名称
    local EquipManager = require("Equip.EquipManager")
    local suitId = EquipManager:getSuitIdById(userEquip.equipId)
    if suitId > 0 then
        local suitCfg = ConfigManager.getSuitCfg()
        local suitName = common:fillHtmlStr("EquipSuitName", suitCfg[suitId].suitName, self:getEquipedSuitCount(suitId, roleInfo), tostring(suitCfg[suitId].maxNum))
        table.insert(strTb, suitName)
    end

    -- 职业限制信息(如果有)
    local professionId = EquipManager:getProfessionById(equipId);
    if professionId and professionId > 0 then
        UserInfo.sync()
        local isMyProfession =(professionId == UserInfo.roleInfo.prof and not isViewingOther) and "" or "_F"
        local professionName = common:getLanguageString("@ProfessionName_" .. professionId);
        -- table.insert(strTb, common:getLanguageString("@EquipCondition", professionName));
        table.insert(strTb, common:fillHtmlStr("EquipCondition" .. suffix .. isMyProfession, professionName));
    end

    -- 评分
    local grade = userEquip.score;
    -- table.insert(strTb, common:getLanguageString("@EquipGrade", grade));
    --table.insert(strTb, common:fillHtmlStr("EquipGrade" .. suffix, grade));
    table.insert(strTb,  grade);


    -- 从装备数据中分类出属性数据（主、副、神）
    local quality = EquipManager:getQualityById(userEquip.equipId);
    local attrTb = {
        [Const_pb.PRIMARY_ATTR] = { },
        [Const_pb.SECONDARY_ATTR] = { },
        [Const_pb.GODLY_ATTR] = { }
    };

    ----伤害显示特殊处理
    local dmg = { };
    local ismin = 0
    --- 0 最小 1最大  2最小最大
    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local grade = equipAttr.attrGrade;
        local attr = equipAttr.attrData;
        local doCheck = false;
        if attr.attrId == Const_pb.MINDMG then
            doCheck = true;
            dmg.min = attr.attrValue;
        elseif attr.attrId == Const_pb.MAXDMG then
            doCheck = true;
            dmg.max = attr.attrValue;
        end

        if doCheck and dmg.min then
            ismin = 0
        end

        if doCheck and dmg.max then
            ismin = 1
        end

        if doCheck and dmg.min and dmg.max then
            ismin = 2
        end
    end

    local dmg = { };
    -- 分类
    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local grade = equipAttr.attrGrade;
        local attr = equipAttr.attrData;

        local attrStr = nil;
        local currBaseVal = EquipManager:getAttrAddVAl(quality, userEquip.strength) or 0
        local curStr = currBaseVal / 10000
        local baseAttrInfo = EquipManager:getInitAttrInfo(equipId)
        -- 针对伤害特殊处理
        local doCheck = false;
        if attr.attrId == Const_pb.MINDMG then
            dmg.min = attr.attrValue;
            dmg.min = math.floor(baseAttrInfo[attr.attrId].attrValMax *(1 + curStr))
            -- 服务器的数据算上了神器属性的加成，客户端重新计算，去除加成值的影响
            doCheck = true;
        elseif attr.attrId == Const_pb.MAXDMG then
            dmg.max = attr.attrValue;
            dmg.max = math.floor(baseAttrInfo[attr.attrId].attrValMax *(1 + curStr))
            -- 服务器的数据算上了神器属性的加成，客户端重新计算，去除加成值的影响
            doCheck = true;
        else
            local name = common:getAttrName(attr.attrId);
            local value = attr.attrValue
            if baseAttrInfo[attr.attrId] then
                value = math.floor(baseAttrInfo[attr.attrId].attrValMax *(1 + curStr))
            end
            if grade == Const_pb.SECONDARY_ATTR and not isAll then
                local len = GameConfig.LineWidth.SecondaryAttrNum;
                len = tostring(value):len() % 2 == 0 and len or(len + 1);
                local fmt = "%s +%-" .. len .. "s";
                attrStr = string.format(fmt, name, value);
            else
                attrStr = common:getLanguageString("@EquipAttrVal", name, value);
            end
        end

        if doCheck then
            if ismin == 0 and dmg.min then
                attrStr = common:getLanguageString("@AttrName_103") .. ":" .. tostring(dmg.min)
                dmg = { };
            elseif ismin == 1 and dmg.max then
                attrStr = common:getLanguageString("@AttrName_104") .. ":" .. tostring(dmg.max)
                dmg = { };
            elseif ismin == 2 and dmg.min and dmg.max then
                attrStr = common:getLanguageString("@EquipDMGVal", dmg.min, dmg.max);
                dmg = { };
            end
        end
        if attrStr ~= nil then
            local key = grade == Const_pb.PRIMARY_ATTR and "MainAttr" or "SecondaryAttr_" .. quality;
            key = key .. suffix;
            attrTb[grade][attr.attrId] = common:fillHtmlStr(key, attrStr);
        end
    end
    -- 组合htmlString

    for attrGrade, subAttrTb in ipairs(attrTb) do
        local str = "";
        -- 非全显时，把副属性两两一行显示
        if attrGrade == Const_pb.SECONDARY_ATTR and not isAll then
            local format = "%s%s%s%s";
            local attrIds = common:table_keys(subAttrTb);
            for i, attrId in ipairs(attrIds) do
                if i % 2 == 1 then
                    local nextAttrId = attrIds[i + 1] or 0;
                    local prefix = i > 1 and glue or "";
                    str = string.format(format, str, prefix, subAttrTb[attrId], subAttrTb[nextAttrId] or "");
                end
            end
        else
            str = common:table_implode(subAttrTb, glue);
        end
        if str ~= "" then
            table.insert(strTb, str);
        end
    end

    -- 组合套装属性

    if suitId > 0 then
        table.insert(strTb, common:fillHtmlStr("EquipSuitAttrs"))
        local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
        local suitCfg = ConfigManager.getSuitCfg()
        for i = 1, #suitCfg[suitId].conditions, 1 do
            local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
            local suitAttrId = suitCfg[suitId].attrIds[i]
            if UserEquipManager:getEquipedSuitCount(suitId, roleInfo) >= tonumber(suitCfg[suitId].conditions[i]) then
                table.insert(strTb, common:fillHtmlStr("EquipSuitAttrs" .. i, suitCfg[suitId].conditions[i], suitAttrCfg[suitAttrId].describe))
            else
                table.insert(strTb, common:fillHtmlStr("EquipSuitAttrsF", suitCfg[suitId].conditions[i], suitAttrCfg[suitAttrId].describe))
            end
        end
    end

    local commonInfo = table.concat(strTb, glue);
    retStr = commonInfo;

    -- 神器属性、神器全身强化效果
    local godlyInfo = self:getGodlyInfo(userEquip, isAll, isViewingOther);
    if godlyInfo ~= "" then
        retStr = retStr .. glue .. godlyInfo;
    end

    -- 宝石加成
    if isAll then
        local gemInfo = self:getGemInfo(userEquip);
        if gemInfo ~= "" then
            retStr = retStr .. glue .. gemInfo;
        end
    end

    -- 通过margin设置不同的宽度
    local margin = isAll and GameConfig.Margin.EquipInfo or GameConfig.Margin.EquipSelect;
    return common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

-- 获取已装备套装数量by suitId
function UserEquipManager:getEquipedSuitCount(suitId, roleInfo)
    local EquipManager = require("Equip.EquipManager")
    UserInfo.sync()
    local userEquipInfos = UserInfo.roleInfo.equips

    if roleInfo ~= nil and roleInfo.equips ~= nil then
        userEquipInfos = roleInfo.equips
    end

    local i = 0
    for _, v in ipairs(userEquipInfos) do
        if v.equipItemId then
            if suitId == EquipManager:getSuitIdById(v.equipItemId) then
                i = i + 1
            end
        end
    end

    return i
end

-- 获取玩家套装动画名称
function UserEquipManager:getPlayerSuitAni(playerId)
    local maxCount = self:getUserEquipMaxSuitCountByUserId(playerId)
    local aniName = "";
    local hasAni = false
    if maxCount < 6 then
        hasAni = false;
    elseif maxCount < 8 then
        hasAni = true
        aniName = "SuitLV1"
    elseif maxCount < 10 then
        hasAni = true
        aniName = "SuitLV2"
    else
        hasAni = true
        aniName = "SuitLV3"
    end
    return hasAni, aniName
end


-- 获取玩家身上最多套装件数
function UserEquipManager:getUserEquipMaxSuitCountByUserId(userId)
    local ViewPlayerInfo = require("PlayerInfo.ViewPlayerInfo")
    UserInfo.sync()
    if userId == nil then userId = UserInfo.playerInfo.playerId end
    local suits = { }
    if userId == UserInfo.playerInfo.playerId then
        for k, v in ipairs(UserInfo.roleInfo.equips) do
            local itemInfo = EquipManager:getEquipCfgById(v.equipItemId)
            if itemInfo.suitId > 0 then
                if suits[itemInfo.suitId] == nil then
                    suits[itemInfo.suitId] = 1
                else
                    suits[itemInfo.suitId] = suits[itemInfo.suitId] + 1
                end
            end
        end
    else
        for k, v in ipairs(ViewPlayerInfo.snapshot.equipInfo) do
            local itemInfo = EquipManager:getEquipCfgById(v.equipId)
            if itemInfo.suitId > 0 then
                if suits[itemInfo.suitId] == nil then
                    suits[itemInfo.suitId] = 1
                else
                    suits[itemInfo.suitId] = suits[itemInfo.suitId] + 1
                end
            end
        end
    end

    local count = 0

    for k, v in pairs(suits) do
        if v > count then
            count = v
        end
    end

    return count
end

-- 获取可熔炼装备id,并排序
-- @Param isAuto: 是否是自动筛选，是否过滤掉戴宝石装备
function UserEquipManager:getEquipIdsForSmelt(isAuto)
    -- self:classify();
    local ids = { };
    for _, id in ipairs(self:getEquipIdsByClass("All")) do
        -- if not self:isEquipDressed(id)
        -- and not self:isGodly(id)
        -- and (not isAuto or not self:hasGem(id))
        -- then
        if not self:isNFTbyId(id) then
            if not self:isGodly(id) and(not isAuto or not self:hasGem(id)) and not self:isSuitbyId(id) then
                table.insert(ids, id)
            elseif self:isGodly(id) then
                local userEquip = self:getUserEquipById(id)
                local targetLevel = userEquip.strength
                if targetLevel > 0 then
                    table.insert(ids, id)
                end
            end
        end
    end
    table.sort(ids, sortByQualityScore);
    return ids;
end

-- 获取可熔炼装备id,并排序
-- @Param isAuto: 是否是自动筛选，是否过滤掉戴宝石装备
function UserEquipManager:getEquipIdsForSmelt2(qualitys)
    -- self:classify();
    local ids = { };
    for _, id in ipairs(self:getEquipIdsByClass("All")) do
        local userEquip = self:getUserEquipById(id);
        if not self:isNFTbyId(id) then
            if common:table_hasValue(qualitys, EquipManager:getQualityById(userEquip.equipId))
            then 
                table.insert(ids, id);
            end
        end
        --if not self:isGodly(id) and(not isAuto or not self:hasGem(id)) and not self:isSuitbyId(id) then
        --    table.insert(ids, id)
        --elseif self:isGodly(id) then
        --    local userEquip = self:getUserEquipById(id)
        --    local targetLevel = userEquip.strength
        --    if targetLevel > 0 then
        --        table.insert(ids, id)
        --    end
        --end
    end
    table.sort(ids, sortByQualityScore);
    return ids;
end

-- 是否为套装
function UserEquipManager:isSuitbyId(userEquipId)
    local EquipManager = require "Equip.EquipManager"
    local userEquipInfo = self:getUserEquipById(userEquipId)
    return EquipManager:getEquipCfgById(userEquipInfo.equipId).suitId > 0
end

-- 是否為NFT裝備
function UserEquipManager:isNFTbyId(userEquipId)
    local EquipManager = require "Equip.EquipManager"
    local userEquipInfo = self:getUserEquipById(userEquipId)
    return EquipManager:getEquipCfgById(userEquipInfo.equipId).isNFT > 0
end

-- 获取可被吞噬装备id,并排序
-- 规则：1.双神器可吞噬所有其它神器，单属性神器只能吞噬对应属性单神器;
-- 	2.星级到上限后不能吞噬,两条属性分别计算
-- @Param excludeId: 吞噬者
-- @Param isAuto: 是否是自动筛选，是否过滤掉戴宝石装备
function UserEquipManager:getEquipIdsForSwallow(excludeId, isAuto)

    --TODO  待优化

    local ids = { };
    
    -- enable: 是否能吞噬，limitPos: 可吞噬属性部位
    local enable, limitPos = self:canSwallow(excludeId);
    if not enable then return ids; end

    for _, id in ipairs(self:getEquipIdsByClass("Godly")) do
        if id ~= excludeId
            and(not isAuto or not self:hasGem(id))
            and(limitPos == nil or self:isSwallowable(id, limitPos))
            and(not self:isSuit(id))
        then
            table.insert(ids, id);
        end
    end
    -- 获取神器经验石
    local userEquip = self:getUserEquipById(excludeId)
    local itemIds1 = { }
    local itemIds2 = { }

    if userEquip.starLevel < GameConfig.LevelLimit.GodlyLevelMax then
        if userEquip.godlyAttrId > 0 then
            itemIds1 = UserItemManager:getItemIdsByType(Const_pb.COMMON_GODLY_EXP)
            -- 17
        end

        if userEquip.godlyAttrId2 > 0 then
            itemIds2 = UserItemManager:getItemIdsByType(Const_pb.REPUTATION_GODLY_EXP)
            -- 18
        end
    end

    for _, itemId in ipairs(itemIds1) do
        local item = UserItemManager:getUserItemByItemId(itemId)
        if item ~= nil then
            local count = item.count
             --最大50个 避免卡死
            if count > 50 then
                count = 50
            end
            
            for i = 1, count, 1 do
                table.insert(ids, item.id)
            end
            --            for i = 1,item.count,1 do
            --                table.insert(ids , item.id)
            --            end
        end
    end
    for _, itemId in ipairs(itemIds2) do
        local item = UserItemManager:getUserItemByItemId(itemId)
        if item ~= nil then
            local count = item.count
            if count > 50 then
                count = 50
            end
            for i = 1, count, 1 do
                table.insert(ids, item.id)
            end

--            for i = 1, item.count, 1 do
--                table.insert(ids, item.id)
--            end
        end
    end

    table.sort(ids, sortByScore);
    return ids;
end

-- 能否被吞噬
-- @Param limitGodlyPos: nil时，两个部分都能被吞，否则必须是对应属性的单属性神器
function UserEquipManager:isSwallowable(userEquipId, limitGodlyPos)
    local userEquip = self:getUserEquipById(userEquipId);
    if limitGodlyPos == 1 then
        return not(userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 > 0);
    elseif limitGodlyPos == 2 then
        return userEquip.godlyAttrId <= 0;
    end
    return true;
end

-- 是否是套装
function UserEquipManager:isSuit(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    local suitId = EquipManager:getSuitIdById(userEquip.equipId)
    if suitId > 0 then
        return true
    end

    return false
end
--[[
function UserEquipManager:getEquipIdsForExtend(excludeId)
	local ids = {};
	for _, id in ipairs(self:getEquipIdsByClass("Godly")) do
		if id ~= excludeId then
			table.insert(ids, id);
		end
	end
		for _, id in ipairs(self:getEquipIdsByClass("Dress")) do
		if id ~= excludeId then
			table.insert(ids, id);
		end
	end
	return ids;
end	
--]]

-- 是否是神器
function UserEquipManager:isGodly(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    return self:isEquipGodly(userEquip);
end

-- 是否是神器
function UserEquipManager:isEquipGodly(userEquip)
    -- modify
    if userEquip ~= nil and not common:table_is_empty(userEquip) then
        if userEquip.godlyAttrId ~= nil and userEquip.godlyAttrId > 0 then
            return true;
        end
        if userEquip:HasField("godlyAttrId2") then
            if userEquip.godlyAttrId2 ~= nil and userEquip.godlyAttrId2 > 0 then
                return true
            end
        end
    end
    return false;
end

-- 获取神器主要属性
-- @Param isAll: 是否全部显示（字体大小不同）
-- @Param pos: 第几条神器属性（nil 时显示第一条与第二条拼接，用到了递归）
-- @Param noHtml: 不返回htmlString
-- @Return: noHtml == true时，返回HtmlString,否则普通字符串
function UserEquipManager:getMainGodlyAttr(userEquip, isAll, pos, noHtml)
    if pos == nil then
        -- 两条属性String拼接
        local strTb = { };
        local glue = noHtml and "\n" or "<br/>";
        -- 不同的拼接符
        local str = self:getMainGodlyAttr(userEquip, isAll, 1, noHtml);
        if str ~= "" then
            table.insert(strTb, str);
        end
        str = self:getMainGodlyAttr(userEquip, isAll, 2, noHtml);
        if str ~= "" then
            table.insert(strTb, str);
        end
        return table.concat(strTb, glue);
    end

    -- 获取属性id,神器星级
    local attrId, starLevel = 0, 0;
    if pos == 1 then
        attrId, starLevel = userEquip.godlyAttrId, userEquip.starLevel;
    elseif pos == 2 and userEquip:HasField("godlyAttrId2") then
        attrId, starLevel = userEquip.godlyAttrId2, userEquip.starLevel2;
    end

    if attrId <= 0 then return ""; end
    local suffix = isAll and "" or "_1";
    -- 不同的格式

    local starAttrName = common:getLanguageString("@AttrName_" .. attrId);
    if noHtml then
        local starAttrVal = EquipManager:getStarAttrByLevel(attrId, starLevel, "%.1f%%");
        return common:getLanguageString("@GodlyStarAttr", starAttrName, starAttrVal);
    end
    local starAttrVal = EquipManager:getStarAttrByLevel(attrId, starLevel);
    return common:fillHtmlStr("GodlyAttr" .. suffix, starAttrName .. ' +' .. starAttrVal);
end

-- 得到神器融合增加的属性str
function UserEquipManager:getGodlyAttrAddStr(userEquip, pos, startlevel, endlevel)
    -- 获取属性id,神器星级
    local attrId
    if pos == 1 then
        attrId = userEquip.godlyAttrId
    elseif pos == 2 and userEquip:HasField("godlyAttrId2") then
        attrId = userEquip.godlyAttrId2
    end
    if attrId <= 0 then return ""; end
    local starAttrName = common:getLanguageString("@AttrName_" .. attrId);
    local starAttrVal = EquipManager:getStarAttrByLevelGap(attrId, startlevel, endlevel);
    return starAttrName .. ' +' .. starAttrVal
end


-- 判定两件装备是否可以传承
function UserEquipManager:isCanExtend(userEquip, recvEquip)
    if recvEquip.strength > 0 then
        return false
    end
    for _, gemInfo in ipairs(recvEquip.gemInfos) do
        local gemId = gemInfo.gemItemId;
        if gemId and gemId > 0 then
            return false
        end
    end

    local attrId = userEquip.godlyAttrId;
    local attrId2 = userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 or -1;
    if attrId > 0 or attrId2 > 0 then
        local attrId3 = recvEquip.godlyAttrId
        local attrId4 = recvEquip:HasField("godlyAttrId2") and recvEquip.godlyAttrId2 or -1;
        if attrId3 > 0 or attrId4 > 0 then
            return false
        else
            return true
        end
    end

    -- 是否有强化
    if userEquip.strength > 0 then
        return true
    end

    -- 是否有宝石
    local pos2GemId = { };
    for _, gemInfo in ipairs(userEquip.gemInfos) do
        local gemId = gemInfo.gemItemId;
        if gemId and gemId > 0 then
            pos2GemId[gemInfo.pos] = gemId;
        end
    end

    if #pos2GemId > 0 then
        return true
    end
    return false

end

--- 获取是否可以继承
function UserEquipManager:getIsInherit(userEquip)
    -- 是否有强化
    if userEquip.strength > 0 then
        return true
    end

    -- 是否有神器属性
    local attrId = userEquip.godlyAttrId;
    local attrId2 = userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 or -1;
    if attrId > 0 or attrId2 > 0 then
        return true
    end

    -- 是否有宝石
    local pos2GemId = { };
    for _, gemInfo in ipairs(userEquip.gemInfos) do
        local gemId = gemInfo.gemItemId;
        if gemId and gemId > 0 then
            pos2GemId[gemInfo.pos] = gemId;
        end
    end

    if #pos2GemId > 0 then
        return true
    end
    return false
end
----获取继承装备的属性
function UserEquipManager:getInheritAttr(userEquip)
    local retStr = ""
    local str = ""
    local glue = '<br/>'
    local strTb = { }
    if userEquip.strength > 0 then
        str = common:getLanguageString("@EquipmentEnhanceLevel") .. "+" .. userEquip.strength
        str = common:fill(FreeTypeConfig[170].content, str)
        table.insert(strTb, str);
    end

    local attrId = userEquip.godlyAttrId;
    if attrId > 0 then
        str = UserEquipManager:getMainGodlyAttr(userEquip, true, 1, true)
        str = common:getLanguageString("@EquipStr3") .. str
        str = common:fill(FreeTypeConfig[170].content, str)
        table.insert(strTb, str);
    end

    local attrId2 = userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 or -1;
    if attrId2 > 0 then
        str = UserEquipManager:getMainGodlyAttr(userEquip, true, 2, true)
        str = common:getLanguageString("@EquipStr4") .. str
        str = common:fill(FreeTypeConfig[170].content, str)
        table.insert(strTb, str);
    end

    local ItemManager = require("Item.ItemManager");
    local pos2GemId = { };
    for _, gemInfo in ipairs(userEquip.gemInfos) do
        local gemId = gemInfo.gemItemId;
        if gemId and gemId > 0 then
            pos2GemId[gemInfo.pos] = gemId;
        end
    end

    -- 接合加成信息
    local texTb = { };
    for k, gemId in pairs(pos2GemId) do
        local gemStr = ItemManager:getNameById(gemId) .. " " .. ItemManager:getNewGemAttrString(gemId);
        if k == 1 then
            str = common:fill(FreeTypeConfig[171].content, common:getLanguageString("@EquipStr5") .. ItemManager:getNameById(gemId), ItemManager:getNewGemAttrString(gemId))
        else
            str = common:fill(FreeTypeConfig[171].content, "" .. ItemManager:getNameById(gemId), ItemManager:getNewGemAttrString(gemId))
        end
        table.insert(strTb, str);
        -- table.insert(texTb, common:fillHtmlStr("GemInfo", gemStr));
    end

    local commonInfo = table.concat(strTb, glue);
    retStr = commonInfo;
    -- 通过margin设置不同的宽度
    local margin = GameConfig.Margin.EquipInfo
    -- or GameConfig.Margin.EquipSelect;
    return common:fillHtmlStr("EquipInfoWrap", margin, retStr);
end

-- 获取神器属性（包括主要属性、神器全身强化效果）
-- @Param isAll: 是否全部显示（是否包括全身强化效果，字体大小不同）
-- @Param isViewingOther: 是否是查看别人阵容
-- @Return: HtmlString
function UserEquipManager:getGodlyInfo(userEquip, isAll, isViewingOther, isShowDeep, roleInfo)
    local glue = "<br/>";
    -- 字体串拼接符
    local suffix = isAll and "" or ""
    -- "_1";	--使用不现的html配置，主要是字体大小不同
    local attrId = userEquip.godlyAttrId;
    local isShowDeep = isShowDeep and isShowDeep or ""

    local attrId2 = userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 or -1;
    if attrId <= 0 and attrId2 <= 0 then return ""; end

    local strTb = { };

    -- 全身强化等级要与神器属性对应星级取最小值，所以有两个
    local allEnhanceLevel_1, allEnhanceLevel_2 = nil, nil;
    local showEnhanceAttr = nil;

    if attrId > 0 then
        -- 几星神器
        local title = common:getLanguageString("@GodlyStarLevel1", userEquip.starLevel);
        if userEquip.starLevel >= GameConfig.StoneAndEquipSpeLevel then
            title = title .. FreeTypeConfig[GameConfig.FreeTypeId.EquipGradeMax].content
        end
        table.insert(strTb, common:fillHtmlStr("GodlyAttr" .. isShowDeep, title));

        -- 神器主属性
        table.insert(strTb, self:getMainGodlyAttr(userEquip, isAll, 1));

        -- 显示所有且是查看别人阵容或查看装备在主角身上的装备时才显示强化效果
        showEnhanceAttr = isAll and(isViewingOther or self:isEquipDressedOnPlayer(userEquip));
        if showEnhanceAttr then
            local starAttrName = common:getLanguageString("@AttrName_" .. attrId);
            -- 获取全身强化等级
            allEnhanceLevel_1 = UserInfo.getAllEnhancedLevel(isViewingOther, roleInfo);
            allEnhanceLevel_1 = math.floor(allEnhanceLevel_1 / 5)
            local allEnhanceLevel_1_real = allEnhanceLevel_1
            allEnhanceLevel_2 = allEnhanceLevel_1;
            if allEnhanceLevel_1 > 0 then
                -- 全身强化等级与神器星级取小
                allEnhanceLevel_1 = math.min(allEnhanceLevel_1, userEquip.starLevel);
                local activeVal = EquipManager:getActiveValByLevel(attrId, allEnhanceLevel_1);
                -- 已激活属性
                local activeInfo = common:fillHtmlStr("GodlyActiveAttr" .. isShowDeep, starAttrName, allEnhanceLevel_1 * 5, activeVal);
                table.insert(strTb, activeInfo);
            end

            -- 查看别人阵容或者星级达到最大时不显示下一等级强化效果 userEquip.strength
            if not isViewingOther and userEquip.starLevel <= GameConfig.LevelLimit.GodlyLevelMax then
                local nextVal = EquipManager:getActiveValByLevel(attrId, allEnhanceLevel_1 + 1);
                if nextVal ~= 0 then
                    -- 显示下一等级强化效果，控制是否提示"下一星级"
                    local contentKey = "GodlyNextStarAttr";
                    -- allEnhanceLevel_1 < userEquip.starLevel and "GodlyUnactiveAttr" or
                    if allEnhanceLevel_1_real >= allEnhanceLevel_1 + 1 then
                        contentKey = "GodlyStr2" .. isShowDeep
                    elseif allEnhanceLevel_1 < userEquip.starLevel then
                        contentKey = "GodlyStr1" .. isShowDeep
                    end
                    local unactiveInfo = common:fillHtmlStr(contentKey .. isShowDeep, starAttrName, allEnhanceLevel_1 * 5 + 5, nextVal);
                    table.insert(strTb, unactiveInfo);
                end
            end
        end
    end

    -- 第二条神器属性强化效果，逻辑同第一条
    if attrId2 > 0 then
        local title = common:getLanguageString("@GodlyStarLevel2", userEquip.starLevel2);
        if userEquip.starLevel2 >= GameConfig.StoneAndEquipSpeLevel then
            title = title .. FreeTypeConfig[GameConfig.FreeTypeId.EquipGradeMax].content
        end
        table.insert(strTb, common:fillHtmlStr("GodlyAttr" .. isShowDeep, title));

        table.insert(strTb, self:getMainGodlyAttr(userEquip, isAll, 2));

        if showEnhanceAttr == nil then
            showEnhanceAttr = isAll and(isViewingOther or self:isEquipDressedOnPlayer(userEquip));
        end

        if showEnhanceAttr then
            local starAttrName = common:getLanguageString("@AttrName_" .. attrId2);
            local allEnhanceLevel_2_real = 0
            -- if allEnhanceLevel_2 == nil then
            allEnhanceLevel_2 = UserInfo.getAllEnhancedLevel(isViewingOther, roleInfo);
            allEnhanceLevel_2 = math.floor(allEnhanceLevel_2 / 5)
            allEnhanceLevel_2_real = allEnhanceLevel_2
            -- end

            if allEnhanceLevel_2 > 0 then
                allEnhanceLevel_2 = math.min(allEnhanceLevel_2, userEquip.starLevel2);
                local activeVal = EquipManager:getActiveValByLevel(attrId2, allEnhanceLevel_2);
                local activeInfo = common:fillHtmlStr("GodlyActiveAttr" .. isShowDeep, starAttrName, allEnhanceLevel_2 * 5, activeVal);
                table.insert(strTb, activeInfo);
            end

            if not isViewingOther and userEquip.starLevel2 <= GameConfig.LevelLimit.GodlyLevelMax then
                local nextVal = EquipManager:getActiveValByLevel(attrId2, allEnhanceLevel_2 + 1);
                if nextVal ~= 0 then
                    -- local contentKey = allEnhanceLevel_2 < userEquip.starLevel2 and "GodlyUnactiveAttr" or "GodlyNextStarAttr";
                    local contentKey = "GodlyNextStarAttr";
                    -- allEnhanceLevel_1 < userEquip.starLevel and "GodlyUnactiveAttr" or
                    if allEnhanceLevel_2_real >= allEnhanceLevel_2 + 1 then
                        contentKey = "GodlyStr2" .. isShowDeep
                    elseif allEnhanceLevel_2 < userEquip.starLevel2 then
                        contentKey = "GodlyStr1" .. isShowDeep
                    end
                    local unactiveInfo = common:fillHtmlStr(contentKey .. isShowDeep, starAttrName, allEnhanceLevel_2 * 5 + 5, nextVal);
                    table.insert(strTb, unactiveInfo);
                end
            end
        end
    end

    return table.concat(strTb, glue);
end

-- 装备是否能融合，必须是单属性神器
function UserEquipManager:canCompound(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    local attrId_1 = userEquip.godlyAttrId;
    local attrId_2 = userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 or -1;

    if (attrId_1 > 0 and attrId_2 > 0)
        or(attrId_1 <= 0 and attrId_2 <= 0)
    then
        return false;
    end

    return true,(attrId_1 > 0 and 2 or 1);
end

-- 能否吞噬其它神器
-- 规则：必须是神器，且对应神器属性星级未达上限
-- @Return: enable是否能吞噬，limitPos单属性神器吞噬属性部位限制(1或２或nil)
function UserEquipManager:canSwallow(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);

    local enable, limitPos = false, nil;
    if userEquip.godlyAttrId > 0 then
        if userEquip.starLevel < GameConfig.LevelLimit.GodlyLevelMax then
            enable = true;
            limitPos = 1;
        end
    end

    if userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 > 0 then
        if userEquip.starLevel2 < GameConfig.LevelLimit.GodlyLevelMax then
            enable = true;
            -- 若两个部分都有限制，则视为无限制
            limitPos = limitPos == nil and 2 or nil;
        end
    end

    return enable, limitPos;
end

-- 获取宝石加成信息
-- @Return: HtmlString
function UserEquipManager:getGemInfoById(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    return self:getGemInfo(userEquip);
end

-- 获取宝石加成信息
-- @Return: HtmlString
function UserEquipManager:getGemInfo(userEquip, isShowDeep)
    local ItemManager = require("Item.ItemManager");
    local isShowDeep = isShowDeep and isShowDeep or ""
    local glue = "<br/>"
    -- 整理宝石id，剔除只有孔的部位(复制的代码吧，没有必要)
    local pos2GemId = { };
    for _, gemInfo in ipairs(userEquip.gemInfos) do
        local gemId = gemInfo.gemItemId;
        if gemId and gemId > 0 then
            pos2GemId[gemInfo.pos] = gemId;
        end
    end

    -- 接合加成信息
    local texTb = { };
    for _, gemId in pairs(pos2GemId) do
        local gemStr = ItemManager:getNameById(gemId) .. " " .. ItemManager:getNewGemAttrString(gemId);
        table.insert(texTb, common:fillHtmlStr("GemInfo" .. isShowDeep, gemStr));
    end

    return table.concat(texTb, glue);
end	

-- 装备是否镶嵌有宝石
function UserEquipManager:hasGem(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    if userEquip ~= nil and userEquip.gemInfos ~= nil then
        for _, gemInfo in ipairs(userEquip.gemInfos) do
            local gemId = gemInfo.gemItemId;
            if gemId and gemId > 0 then
                return true;
            end
        end
    end
    return false;
end

-- 获取装备强化所需强化精华个数
-- 影响要素:强化等级、品质、等级、部位（权重不同）
function UserEquipManager:getItemNeedForEnhance(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    local targetLevel = userEquip.strength + 1;
    local factor = {
        targetLevel,
        EquipManager:getQualityById(userEquip.equipId),
        EquipManager:getLevelById(userEquip.equipId),
        EquipManager:getPartById(userEquip.equipId)
    };
    local count = 1;
    for i, v in ipairs(factor) do
        count = count * EquipManager:getWeightByIdAndType(v, i);
    end
    return math.floor(count);
end

-- 获取装备强化所需金币
function UserEquipManager:getEnhanceCoinCost(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    local targetLevel = userEquip.strength + 1;
    local quality = EquipManager:getQualityById(userEquip.equipId)
    local enhanceItemCfg = self:getEnhanceCfgByQuality(quality)
    local count = enhanceItemCfg[targetLevel] and enhanceItemCfg[targetLevel].costCoin or 0

    if count ~= 0 then
        local userEquip = self:getUserEquipById(userEquipId);
        local part = tonumber(EquipManager:getPartById(userEquip.equipId))
        local enhanceWeightCfg = ConfigManager.getEquipEnhanceWeightCfg()
        count = count * enhanceWeightCfg[part].ratio
    end
    return math.floor(count)
end

-- 获取装备强化所需鑽石
function UserEquipManager:getEnhanceReoCost(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    local targetLevel = userEquip.strength + 1;
    local quality = EquipManager:getQualityById(userEquip.equipId)
    local enhanceItemCfg = self:getEnhanceCfgByQuality(quality)
    local count = enhanceItemCfg[targetLevel] and enhanceItemCfg[targetLevel].costReo or 0;

    if count ~= 0 then
        local userEquip = self:getUserEquipById(userEquipId);
        local part = tonumber(EquipManager:getPartById(userEquip.equipId));
        local enhanceWeightCfg = ConfigManager.getEquipEnhanceWeightCfg();
        count = count * enhanceWeightCfg[part].ratio;
    end
    return math.floor(count);
end

-- 获取装备强化所需强化石 
function UserEquipManager:getEnhanceItem1(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    local targetLevel = userEquip.strength + 1;
    local quality = EquipManager:getQualityById(userEquip.equipId)
    local enhanceItemCfg = self:getEnhanceCfgByQuality(quality)
    local count = enhanceItemCfg[targetLevel] and enhanceItemCfg[targetLevel].costItem1.count or 0

    if count ~= 0 then
        local userEquip = self:getUserEquipById(userEquipId);
        local part = tonumber(EquipManager:getPartById(userEquip.equipId))
        local enhanceWeightCfg = ConfigManager.getEquipEnhanceWeightCfg()
        count = count * enhanceWeightCfg[part].ratio
    end

    return math.floor(count), enhanceItemCfg[targetLevel] and enhanceItemCfg[targetLevel].costItem1.itemId or 0
end

-- 获取装备强化所需强化精华
function UserEquipManager:getEnhanceItem2(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    local targetLevel = userEquip.strength + 1;
    local quality = EquipManager:getQualityById(userEquip.equipId)
    local enhanceItemCfg = self:getEnhanceCfgByQuality(quality)
    local count = enhanceItemCfg[targetLevel] and enhanceItemCfg[targetLevel].costItem2.count or 0

    if count ~= 0 then
        local userEquip = self:getUserEquipById(userEquipId);
        local part = tonumber(EquipManager:getPartById(userEquip.equipId))
        local enhanceWeightCfg = ConfigManager.getEquipEnhanceWeightCfg()
        count = count * enhanceWeightCfg[part].ratio
    end

    return math.floor(count), enhanceItemCfg[targetLevel] and enhanceItemCfg[targetLevel].costItem2.itemId or 0
end
-- 获取所有装备的经验
function UserEquipManager:getAllEquipTotalExp(sourceIds)
    local starExp = 0;
    local starExp2 = 0;
    for _, sourceId in ipairs(sourceIds) do
        local totalExp, exp2, exp1 = self:getGodlyTotalExp(sourceId);
        starExp = starExp + exp1;
        starExp2 = starExp2 + exp2;
    end
    return starExp, starExp2
end
-- 获取神器所有经验
-- @Return: 所有经验，第二条属性经验,第一条属性
function UserEquipManager:getGodlyTotalExp(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);

    local exp = 0;
    local exp2 = 0;

    if userEquip.id == nil then
        local userItem = UserItemManager:getUserItemById(userEquipId)
        local itemInfo = ItemManager:getItemCfgById(userItem.itemId)
        if itemInfo.type == Const_pb.COMMON_GODLY_EXP then
            exp = itemInfo.soulStoneExp
        elseif itemInfo.type == Const_pb.REPUTATION_GODLY_EXP then
            exp2 = itemInfo.soulStoneExp
        end
    else
        -- if userEquip:HasField("godlyAttrId") and userEquip.godlyAttrId > 0 then
        if userEquip:HasField("godlyAttrId") and userEquip.godlyAttrId > 0 then
            exp = userEquip.starExp + 1
            -- 保证至少有１点经验
            for lv = 1, userEquip.starLevel - 1 do
                exp = exp + EquipManager:getExpNeedForLevelUp(lv);
            end
        end

        if userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 > 0 then
            exp2 = userEquip.starExp2 + 1
            -- 保证至少有１点经验
            for lv = 1, userEquip.starLevel2 - 1 do
                exp2 = exp2 + EquipManager:getExpNeedForLevelUp(lv, true);
            end
        end
    end

    return exp + exp2, exp2, exp;
end

-- 获取神器吞噬所需金币、道具(注灵之石，已经取消）
-- @Param sourceIds: table 被吞噬装备id
-- @Param targetId: 吞噬者id
-- @Return coinCost, itemCost
function UserEquipManager:getSwallowCost(sourceIds, targetId)
    local starExp = 0;
    local starExp2 = 0;
    for _, sourceId in ipairs(sourceIds) do
        local totalExp, exp2, exp1 = self:getGodlyTotalExp(sourceId);
        starExp = starExp + exp1;
        starExp2 = starExp2 + exp2;
    end

    CCLuaLog("userEquip starExp:" .. tostring(starExp) .. "    starExp2:" .. tostring(starExp2))

    local coinCost =(starExp + starExp2) * 150000
    local itemCost = starExp2 * 1
    return coinCost, itemCost
end

-- 获取神器传承所需金币
-- 跟等级相关，权重由部位决定
-- @Param sourceIds: 被吞噬装备id
-- @Param targetId: 吞噬者id
-- @Return coinCost
function UserEquipManager:getExtendCoinCost(sourceId, targetId)
    local sourceEquip = self:getUserEquipById(sourceId);
    local targetEquip = self:getUserEquipById(targetId);

    local sourceLevel = EquipManager:getLevelById(sourceEquip.equipId);
    local targetLevel = EquipManager:getLevelById(targetEquip.equipId);
    local sourceFactor = EquipManager:getWeightByPart(EquipManager:getPartById(sourceEquip.equipId));
    local targetFactor = EquipManager:getWeightByPart(EquipManager:getPartById(targetEquip.equipId));
    local _, sourceExp2, sourceExp1 = self:getGodlyTotalExp(sourceId);

    local cost = math.max(0, math.pow(targetLevel + targetFactor, 2) - math.pow(sourceLevel + sourceFactor, 2)) * 120 * sourceExp1 + 10000;

    if sourceExp2 ~= 0 then
        cost = cost +(math.max(0, math.pow(targetLevel + targetFactor, 2) - math.pow(sourceLevel + sourceFactor, 2)) * 120 * sourceExp2 + 10000)
    end
    return math.floor(cost);
end	

-- 获取神器融合所需金币、道具(注灵之石，已经取消）
-- 跟等级相关，权重由部位决定
-- @Param sourceId: 被融合装备id, 融合后神器属性会消失
-- @Param targetId: 融合目的装备id, 融合后成为双属性神器
-- @Return coinCost, itemCost
function UserEquipManager:getCompoundCost(sourceId, targetId)
    local s_starExp, s_starExp2 = self:getGodlyTotalExp(sourceId);
    local t_starExp, t_starExp2 = self:getGodlyTotalExp(targetId);

    local maxExp2 = math.max(s_starExp2, t_starExp2)

    local userEquip = self:getUserEquipById(targetId);
    local level = EquipManager:getLevelById(userEquip.equipId);
    local factor = EquipManager:getWeightByPart(EquipManager:getPartById(userEquip.equipId));

    local coinCost = 200000;
    local itemCost = maxExp2 * 1;
    return coinCost, itemCost;
end	

-- 获取装备被穿戴者的角色名字，主角为“主角”
function UserEquipManager:getDressedRoleName(userEquipId)
    local userEquip = self:getUserEquipById(userEquipId);
    if userEquip == nil then return ""; end

    local part = EquipManager:getPartById(userEquip.equipId);
    local roleEquip = UserInfo.getEquipByPart(part);
    if roleEquip and roleEquip.equipId == userEquipId then
        return common:getLanguageString("@MainRole");
    end

    return UserMercenaryManager:getEquipDressedBy(userEquipId);
end	

-- 获取神器特效ccbi，双属性神器Key为"Double", 第一属性单神器为"First", 第二属性为"Second"
function UserEquipManager:getGodlyAni(userEquipId, userEquip)
    local userEquip = userEquip or self:getUserEquipById(userEquipId);
    local aniKey = "First";
    if userEquip:HasField('godlyAttrId2') and userEquip.godlyAttrId2 > 0 then
        aniKey = userEquip.godlyAttrId > 0 and "Double" or "Second";
    end
    --[[
	if (userEquip:HasField('starLevel') and tonumber(userEquip.starLevel)>=10)
		or (userEquip:HasField('starLevel2') and tonumber(userEquip.starLevel2)>=10) then
		aniKey = "TenStar"
	end
    ]]
    return GameConfig.GodlyEquipAni[aniKey];
end

-- 获取主角身上已激活套装属性列表套装
function UserEquipManager:getDressedSuitAttrs()
    local EquipManager = require("Equip.EquipManager")
    local suitAttrs = { }
    local suits = { }
    for i = 1, #UserInfo.roleInfo.equips do
        local roleEquipInfo = UserInfo.roleInfo.equips[i]
        local userEquipInfo = self:getUserEquipById(roleEquipInfo.equipId)
        local itemInfo = EquipManager:getEquipCfgById(userEquipInfo.equipId)
        if itemInfo.suitId > 0 then
            if suits[itemInfo.suitId] == nil then
                suits[itemInfo.suitId] = 1
            else
                suits[itemInfo.suitId] = suits[itemInfo.suitId] + 1
            end
        end
    end

    for k, v in pairs(suits) do
        local suitCfg = ConfigManager.getSuitCfg()
        local count = 1
        for i = 1, #suitCfg[k].conditions, 1 do
            if v >= tonumber(suitCfg[k].conditions[i]) then
                table.insert(suitAttrs, suitCfg[k].attrIds[count])
                count = count + 1
            end
        end
    end

    return suitAttrs
end

-- 获取装备材料是否足够的颜色
function UserEquipManager:getEquipEvolutionMaterialColor(key)
    local cfg = GameConfig.EquipEvolutionMaterial[key] or { };
    local r, g, b = unpack(cfg);
    return ccc3(r, b, b);
end
-- 获取玩家装备红点个数
function UserEquipManager:getEquipLeadCount()
    return EquipStatus.noticeCount;
end
-- 获取玩家装备红点个数
function UserEquipManager:getLeadEquipCount()
    local count = 0
    for i, v in pairs(EquipStatus.partInfo) do
        if v.needNotice == true then
            count = count + 1
        end
    end
    if count == 0 then
        EquipStatus.noticeCount = 0
        local marks, allMark = SoulStarManager:getAllRedVisible()
        if allMark then
            count = count + 1
        end
    end
    return count
end
-- 获取佣兵装备红点个数
function UserEquipManager:getEquipMercenaryCount(roleId)
    if EquipStatus.redPointNotice ~= nil and EquipStatus.noticeCount2 ~= nil then
        if EquipStatus.redPointNotice[roleId] then
            -- local count = EquipStatus.noticeCount2[roleId];
            local count = UserEquipManager:getEquipSingleMercenaryCount(roleId)
            local mercenaryInfo = UserMercenaryManager:getUserMercenaryById(roleId)
            if count ~= nil and mercenaryInfo ~= nil then
                --[[			if count == 0 then
				if EquipStatus.noticeCount2[roleId] ~= nil then
					EquipStatus.noticeCount2[roleId] = 0
				end
			end]]
                --if mercenaryInfo.status == Const_pb.FIGHTING or mercenaryInfo.status == Const_pb.FIGHTING_1 or mercenaryInfo.status == Const_pb.FIGHTING_2 then
                    return count
                --end
            end
        end
    end
    return 0
end
-- 获取单个佣兵装备红点个数
function UserEquipManager:getEquipSingleMercenaryCount(roleId)
    local count = 0
    for k, v in pairs(EquipStatus.partInfo2) do
        if v[roleId] then
            if v[roleId].needNotice == true then
                count = count + 1
            end
        end
    end
    return count
end
-- 获取佣兵装备红点个数
function UserEquipManager:getEquipNoticeCounts()
    local noticeCount = 0;
    noticeCount = noticeCount
    local myMercenary = UserInfo.activiteRoleId
    if myMercenary == nil or EquipStatus.redPointNotice == nil then
        return EquipStatus.noticeCount
    end
    for i = 1, #myMercenary do
        local mercenaryInfo = UserMercenaryManager:getUserMercenaryById(myMercenary[i]);
        if mercenaryInfo ~= nil then
            if EquipStatus.redPointNotice[myMercenary[i]] == true then
                noticeCount = noticeCount + UserEquipManager:getEquipSingleMercenaryCount(myMercenary[i]);
            end
        end
    end
    noticeCount = noticeCount

    return noticeCount
end
-- 获取装备是否有宝石孔
function UserEquipManager:getEquipisHasGem(userEquip)
    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
    if table.maxn(gemInfo) > 0 then
        return true
    end

    return false
end

function UserEquipManager:getRoleAndMercenaryHighestScore(EquipId)
    local part = EquipManager:getPartById(EquipId.equipId);
    if EquipManager:isDressable(EquipId.equipId, UserInfo.roleInfo.prof) then
        if EquipHighestSocre.roleHighestScore[part] == nil then
            EquipHighestSocre.roleHighestScore[part] = EquipId.score
        else
            if EquipHighestSocre.roleHighestScore[part] < EquipId.score then
                EquipHighestSocre.roleHighestScore[part] = EquipId.score
            end
        end
    end
    if not common:table_hasValue(PartForMercenary, part) then return; end
    local myMercenary = UserInfo.activiteRoleId
    local MercenaryInfos = UserMercenaryManager:getUserMercenaryInfos()
    if myMercenary ~= nil then
        for i = 1, #myMercenary do
            local roleInfo = MercenaryInfos[myMercenary[i]]
            if roleInfo ~= nil then
                local a = EquipManager:isDressable(EquipId.equipId, roleInfo.prof)
                if EquipManager:isDressable(EquipId.equipId, roleInfo.prof) then
                    EquipHighestSocre[myMercenary[i]] = EquipHighestSocre[myMercenary[i]] or { }
                    if EquipHighestSocre[myMercenary[i]][part] == nil then
                        EquipHighestSocre[myMercenary[i]][part] = EquipId.score
                    elseif EquipHighestSocre[myMercenary[i]][part] < EquipId.score then
                        EquipHighestSocre[myMercenary[i]][part] = EquipId.score
                    end
                end
            end
        end
    end
end

function UserEquipManager:isCancelEquipRedPoint(part)
    if type(part) ~= "number" then
        return
    end
    local equipPart = EquipCategory.Part[part] or {}
    local hightScore = {}
    local index = {}
    for k, v in pairs(GameConfig.MercenaryClass) do
        hightScore[v] = 0
        index[v] = 0
    end
    for i = 1, #equipPart do
        local tmpEquipInfo = self:getUserEquipById(equipPart[i])
        if tmpEquipInfo ~= nil then
            for k, v in pairs(GameConfig.MercenaryClass) do
                if EquipManager:isDressable(tmpEquipInfo.equipId, v) then
                    local score = tmpEquipInfo.score
                    if hightScore[v] <= score then
                        hightScore[v] = score
                        index[v] = i
                    end
                end
            end
        end
    end
    local roleEquip = UserInfo.getEquipByPart(part);
    local userEquip = nil
    if roleEquip and roleEquip.equipId > 0 then
        userEquip = self:getUserEquipById(roleEquip.equipId)
    else
        if hightScore[UserInfo.roleInfo.prof] == 0 then
            self:cancelNotice(part)
        end
    end
    if userEquip ~= nil then
        local partInfo = EquipStatus.partInfo[part] or { }
        if tonumber(hightScore[UserInfo.roleInfo.prof]) <= (tonumber(userEquip.score) or 0) then
            if partInfo.needNotice then
                self:cancelNotice(part)
            end
        else
            partInfo.needNotice = false
            self:updatePartInfo(part, true, hightScore[UserInfo.roleInfo.prof], equipPart[index[UserInfo.roleInfo.prof]])
        end
    end

    if not common:table_hasValue(PartForMercenary, part) then return; end
    local MercenaryInfos = UserMercenaryManager:getUserMercenaryInfos()
    local myMercenary = UserInfo.activiteRoleId
    if not myMercenary then return end
    local isNeedRefreshPage = false
    for i = 1, #myMercenary do
        local userMercenary = MercenaryInfos[myMercenary[i]]
        local mercenaryRoleEquip = nil
        if userMercenary then
            mercenaryRoleEquip = PBHelper:getRoleEquipByPart(userMercenary.equips, part);
        end
        if EquipStatus.partInfo2[part] == nil then
            EquipStatus.partInfo2[part] = { }
        else
            if EquipStatus.partInfo2[part][myMercenary[i]] == nil then
                EquipStatus.partInfo2[part][myMercenary[i]] = { }
            end
        end
        local partInfo = { }
        if userMercenary ~= nil then
            if mercenaryRoleEquip ~= nil then
                local mercenaryEquipInfo = nil
                mercenaryEquipInfo = self:getUserEquipById(mercenaryRoleEquip.equipId)
                if mercenaryEquipInfo ~= nil then
                    if hightScore[userMercenary.prof] <= mercenaryEquipInfo.score then
                        partInfo = { needNotice = false, score = 0, id = 0 };
                        EquipStatus.partInfo2[part][myMercenary[i]] = partInfo;
                        --self:cancelNotice(part, myMercenary[i])
                        isNeedRefreshPage = true
                    else
                        partInfo = { needNotice = true, score = hightScore[userMercenary.prof], id = equipPart[index[userMercenary.prof]] };
                        EquipStatus.partInfo2[part][myMercenary[i]] = partInfo;
                        if EquipStatus.noticeCount2 ~= nil then
                            local count = EquipStatus.noticeCount2[myMercenary[i]];
                            if count == nil then
                                count = 0;
                            end
                            EquipStatus.noticeCount2[myMercenary[i]] = count + 1;
                        end
                        isNeedRefreshPage = true
                        --PageManager.setAllMercenaryNotice();
                    end
                end
            else
                if hightScore[userMercenary.prof] == 0 then
                    partInfo = { needNotice = false, score = 0, id = 0 };
                    EquipStatus.partInfo2[part][myMercenary[i]] = partInfo;
                    isNeedRefreshPage = true
                    --self:cancelNotice(part, myMercenary[i])
                else
                    partInfo = { needNotice = true, score = hightScore[userMercenary.prof], id = equipPart[index[userMercenary.prof]] };
                    EquipStatus.partInfo2[part][myMercenary[i]] = partInfo;
                    if EquipStatus.noticeCount2 ~= nil then
                        local count = EquipStatus.noticeCount2[myMercenary[i]];
                        if count == nil then
                            count = 0;
                        end
                        EquipStatus.noticeCount2[myMercenary[i]] = count + 1;
                    end
                    --PageManager.setAllMercenaryNotice();
                    isNeedRefreshPage = true
                end
            end
        end
    end
    if isNeedRefreshPage then
        PageManager.setAllMercenaryNotice();
    end
end

function UserEquipManager:calEquipScore(userEquip)
    --local score = 0
    --for _, equipAttr in ipairs(userEquip.attrInfos) do
    --    local attr = equipAttr.attrData
    --
    --    if attr.attrId == Const_pb.ATTACK_attr or attr.attrId == Const_pb.MAGIC_attr then
    --        score = score + attr.attrValue * 5
    --    elseif attr.attrId == Const_pb.PHYDEF or attr.attrId == Const_pb.MAGDEF then
    --        score = score + attr.attrValue * 3
    --    elseif attr.attrId == Const_pb.HP then
    --        score = score + math.floor(attr.attrValue * 0.1 + 0.5)
    --    elseif attr.attrId == Const_pb.RESILIENCE then
    --        score = score + attr.attrValue * 3
    --    elseif attr.attrId == Const_pb.BUFF_AVOID_CONTROL then
    --        score = score + attr.attrValue * 300
    --    elseif attr.attrId == Const_pb.BUFF_CRITICAL_DAMAGE then
    --        score = score + attr.attrValue * 500
    --    elseif attr.attrId == Const_pb.BUFF_PHYDEF_PENETRATE then
    --        score = score + attr.attrValue * 2
    --    elseif attr.attrId == Const_pb.CRITICAL or attr.attrId == Const_pb.HIT or attr.attrId == Const_pb.DODGE then
    --        score = score + attr.attrValue * 1
    --    elseif attr.attrId == Const_pb.STRENGHT or attr.attrId == Const_pb.AGILITY or attr.attrId == Const_pb.INTELLECT or attr.attrId == Const_pb.STAMINA then
    --        score = score + attr.attrValue * 3
    --    end
    --end
    --return score
    return userEquip.score
end

function UserEquipManager:calEquipBaseScore(userEquip)
    local score = 0
    local currVal = 10000 + EquipManager:getAttrAddVAl(EquipManager:getQualityById(userEquip.equipId), userEquip.strength) or 0 -- 強化倍率(*10000)
    for _, equipAttr in ipairs(userEquip.attrInfos) do
        local attr = equipAttr.attrData

        if attr.attrId == Const_pb.ATTACK_attr or attr.attrId == Const_pb.MAGIC_attr then
            score = score + math.ceil(attr.attrValue * 10000 / currVal) * 5
        elseif attr.attrId == Const_pb.PHYDEF or attr.attrId == Const_pb.MAGDEF then
            score = score + math.ceil(attr.attrValue * 10000 / currVal) * 3
        elseif attr.attrId == Const_pb.HP then
            score = score + math.floor( math.ceil(attr.attrValue * 10000 / currVal) * 0.1 + 0.5 )
        elseif attr.attrId == Const_pb.RESILIENCE then
            score = score + math.ceil(attr.attrValue * 10000 / currVal) * 3
        elseif attr.attrId == Const_pb.BUFF_AVOID_CONTROL then
            score = score + math.ceil(attr.attrValue * 10000 / currVal) * 300
        elseif attr.attrId == Const_pb.BUFF_CRITICAL_DAMAGE then
            score = score + math.ceil(attr.attrValue * 10000 / currVal) * 500
        elseif attr.attrId == Const_pb.BUFF_PHYDEF_PENETRATE then
            score = score + math.ceil(attr.attrValue * 10000 / currVal) * 2
        elseif attr.attrId == Const_pb.CRITICAL or attr.attrId == Const_pb.HIT or attr.attrId == Const_pb.DODGE then
            score = score + math.ceil(attr.attrValue * 10000 / currVal) * 1
        elseif attr.attrId == Const_pb.STRENGHT or attr.attrId == Const_pb.AGILITY or attr.attrId == Const_pb.INTELLECT or attr.attrId == Const_pb.STAMINA then
            score = score + attr.attrValue * 3
        end
    end
    return score
end

function UserEquipManager:calAttrScore(attrStr)    -- 格式: "屬性_數值,屬性_數值"(ex. "113_100,114_100")
    local score = 0
    local attrs = common:split(attrStr, ",")
    for i = 1, #attrs do
        local attr = common:split(attrs[i], "_")
        attr[1] = tonumber(attr[1])
        attr[2] = tonumber(attr[2])

        if attr[1] == Const_pb.ATTACK_attr or attr[1] == Const_pb.MAGIC_attr then
            score = score + attr[2] * 5
        elseif attr[1] == Const_pb.PHYDEF or attr[1] == Const_pb.MAGDEF then
            score = score + attr[2] * 3
        elseif attr[1] == Const_pb.HP then
            score = score + math.floor(attr[2] * 0.1 + 0.5)
        elseif attr[1] == Const_pb.RESILIENCE then
            score = score + attr[2] * 3
        elseif attr[1] == Const_pb.BUFF_AVOID_CONTROL then
            score = score + attr[2] * 300
        elseif attr[1] == Const_pb.BUFF_CRITICAL_DAMAGE then
            score = score + attr[2] * 500
        elseif attr[1] == Const_pb.BUFF_PHYDEF_PENETRATE then
            score = score + attr[2] * 2
        elseif attr[1] == Const_pb.CRITICAL or attr[1] == Const_pb.HIT or attr[1] == Const_pb.DODGE then
            score = score + attr[2] * 1
        elseif attr[1] == Const_pb.STRENGHT or attr[1] == Const_pb.AGILITY or attr[1] == Const_pb.INTELLECT or attr[1] == Const_pb.STAMINA then
            score = score +attr[2] * 3
        end
    end
    return score
end

function UserEquipManager:calEquipRank(userEquip)
    local currVal = 10000 + EquipManager:getAttrAddVAl(EquipManager:getQualityById(userEquip.equipId), userEquip.strength) or 0 -- 強化倍率(*10000)
    local score = userEquip and self:calEquipBaseScore(userEquip) or 0
    local cfg = EquipManager:getEquipCfgById(userEquip.equipId)
    local scoreLimit = common:split(cfg.rankScore, "_")
    if score < tonumber(scoreLimit[1]) then
        return 4    -- rank C
    elseif score >= tonumber(scoreLimit[1]) and score <= tonumber(scoreLimit[2]) then
        return 3    -- rank B
    elseif score > tonumber(scoreLimit[2]) then
        local attrLimit = common:split(cfg.rankLimit, ",")
        local count = 0
        local attrLimitTable = {}
        for i = 1, #attrLimit do
            local attr, num = unpack(common:split(attrLimit[i], "_"))
            attrLimitTable[tonumber(attr)] = tonumber(num)
        end
        for _, equipAttr in ipairs(userEquip.attrInfos) do
            local attr = equipAttr.attrData
            if attrLimitTable[attr.attrId] and math.ceil(attr.attrValue * 10000 / currVal) >= attrLimitTable[attr.attrId] then
                count = count + 1
            end
        end
        if count == 0 then
            return 3    -- rank B
        elseif count == #attrLimit then
            return 1    -- rank S
        else
            return 2    -- rank A
        end
    end
    return 4
end
function UserEquipManager:getEnhanceCfgByQuality(quality)
    local cfg = ConfigManager.getEquipEnhanceItemCfg()
    local t = {}
    for i = 1, #cfg do
        if cfg[i].quality == quality then
            table.insert(t, cfg[i])
        end
    end
    return t
end
function UserEquipManager:getUserEquipByCfgId(cfgId)
    local equip = { }
    for k, v in pairs(EquipCategory.All) do -- 只取沒穿在身上的裝備
    --for k, v in pairs(UserEquipMap) do
        local info = self:getUserEquipById(v)
        if info.equipId == cfgId then
            table.insert(equip, info)
        end
    end
    return equip
end
function UserEquipManager:getUserEquipCountByCfgId(cfgId)
    local count = 0
    for k, v in pairs(EquipCategory.All) do
        local info = self:getUserEquipById(v)
        if info.equipId == cfgId then
            count = count + 1
        end
    end
    for k, v in pairs(EquipCategory.Dress) do
        local info = self:getUserEquipById(v)
        if info.equipId == cfgId then
            count = count + 1
        end
    end
    return count
end
--------------------------------------------------------------------------------
return UserEquipManager;