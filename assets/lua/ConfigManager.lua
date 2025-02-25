local ConfigManager = {
    configs = { },
    monsterCfg = nil
};
setmetatable(ConfigManager.configs, { __mode = "v" })
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local type = type;
local unpack = unpack;
local table = table;
--------------------------------------------------------------------------------
local Const_pb = require("Const_pb");

local m_fileName = ""

-- 在win32下，检测该文件路径是否存在
function checkFilePathValidate(filePath)
    -- CC_TARGET_PLATFORM_LUA = nil
    if CC_TARGET_PLATFORM_LUA ~= nil then
        --[[
		if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
			local path = CCFileUtils:sharedFileUtils():fullPathForFilename(filePath)			
			if string.len(path) ==string.len(filePath) then
			    local sprite = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(filePath)
			    if sprite==nil then
			        local msg = "Error, pic path:"..filePath.." in file["..m_fileName.."] is not found, plz ask ouyang to check\n"
				    CCMessageBox(msg,"Table is not right")
			    end
				return filePath
			else
				return path
			end
		end
		--]]
    end
    return filePath
end

function checkAllConfigFile()
    for key, value in pairs(ConfigManager) do
        if value and type(value) == "function" and key ~= "loadCfg" and key ~= "getHelpCfg" and key ~= "getConfig"
            and key ~= "_getItemCfg" and key ~= "getRewardById" and key ~= "getConsumeById" then
            pcall(value);
        end
    end
end

function ConfigManager.loadCfgByIoString(fileName)
    CCLuaLog(fileName)
    local keyName = fileName
    local cfg = ConfigManager.configs[keyName]
    if cfg == nil then
        cfg = ""
        local writablePath = CCFileUtils:sharedFileUtils():getWritablePath()
        CCLuaLog(writablePath)
        if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
            fileName = writablePath .. "/" .. fileName
        elseif CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
            fileName = CCFileUtils:sharedFileUtils():fullPathForFilename(fileName)
        else
            fileName = writablePath .. "/assets/".. fileName
        end
	    local isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(fileName)
	    if isFileExist == false then
            CCLuaLog(fileName)
	    	return
	    end
	    file = io.open(fileName,"r")
	    if file == nil then
	        return
	    end
	    for line in file:lines() do
	        cfg = cfg..tostring(line);
	    end
        ConfigManager.configs[keyName] = cfg
	    file:close()
    end
    return cfg
end

function ConfigManager.loadCfg(fileName, attrMap, indexPos, convertMap)
    m_fileName = fileName
    local tableCfg = TableReaderManager:getInstance():getTableReader(fileName)
    local count = tableCfg:getLineCount() -1
    local convertMap = convertMap or { };
    local Cfg = { }
    for i = 1, count do
        local index = i;
        if indexPos ~= nil then
            if type(indexPos) == "table" then
                local indexTb = common:table_reflect(indexPos, function(pos) return tableCfg:getData(i, pos); end);
                index = table.concat(indexTb, "_");
            else
                index = tonumber(tableCfg:getData(i, indexPos));
            end
        end

        if index then
            Cfg[index] = { }
            for attr, pos in pairs(attrMap) do
                local val = tableCfg:getData(i, pos);
                local func = convertMap[attr];
                if func and type(func) == "function" then
                    val = func(val);
                    if type(val) == "string" then
                        local first, second = string.find(val, "@")
                        if first == 1 and second == 2 then
                            val = Language:getInstance():getString(val)
                        end
                    end
                elseif type(val) == "string" then
                    local first, second = string.find(val, "@")
                    if first == 1 and second == 1 then
                        val = Language:getInstance():getString(val)
                    end
                end

                Cfg[index][attr] = val;
            end
        end
    end
    return Cfg
end

function ConfigManager.loadHalfCfg(fileName, attrMap, indexPos, convertMap)
    m_fileName = fileName
    local tableCfg = TableReaderManager:getInstance():getTableReader(fileName)
    local count = tableCfg:getLineCount() -1
    local convertMap = convertMap or { };
    local Cfg = { }
    local startIndex = 1
    local endIndex = count / 2
    local curTime = common:getServerTimeByUpdate()
    local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
    local curMonth = curServerTime.month
    if curMonth % 2 == 0 then -- 偶數月
        startIndex = count / 2 + 1
        endIndex = count
    end
    for i = startIndex, endIndex do
        local trueIndex = i;
        if curMonth % 2 == 0 then -- 偶數月
            trueIndex = i - (count / 2)
        end
        if indexPos ~= nil then
            if type(indexPos) == "table" then
                local indexTb = common:table_reflect(indexPos, function(pos) return tableCfg:getData(i, pos); end);
                index = table.concat(indexTb, "_");
            else
                index = tonumber(tableCfg:getData(i, indexPos));
            end
        end

        if index then
            Cfg[trueIndex] = { }
            for attr, pos in pairs(attrMap) do
                local val = tableCfg:getData(i, pos);
                local func = convertMap[attr];
                if func and type(func) == "function" then
                    val = func(val);
                    if type(val) == "string" then
                        local first, second = string.find(val, "@")
                        if first == 1 and second == 2 then
                            val = Language:getInstance():getString(val)
                        end
                    end
                elseif type(val) == "string" then
                    local first, second = string.find(val, "@")
                    if first == 1 and second == 1 then
                        val = Language:getInstance():getString(val)
                    end
                end

                Cfg[trueIndex][attr] = val;
            end
        end
    end
    return Cfg
end

function ConfigManager.getConfig(key, loader)
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        cfg = loader();
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 20150114产生随机名字
function ConfigManager.getRandomNameCfg()
    local key = "RandomName";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "mTitle", "mName", "fTitle", "fName" });
        local convertMap = {
            ["id"] = tonumber
        };
        cfg = ConfigManager.loadCfg("charName.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

--
function ConfigManager.getHelpFightBasicCfg()
    local key = "HelpFightBasicCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "helpcosume", "dropbuy"});
        local convertMap = {
            ["id"] = tonumber,
            ["helpcosume"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("Eighteenbasic.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- (10000_1002,30000_60001)
function parseItemWithOutCount(rewards)
    local result = { }
    if rewards ~= nil then
        for _, item in ipairs(common:split(rewards, ",")) do
            local _type, _id = unpack(common:split(item, "_"));
            if _type ~= nil and _id ~= nil then
                table.insert(result, {
                    type = tonumber(_type),
                    id = tonumber(_id)
                } );
            end
        end
    end
    return result
end

-- (10000_1002_1000000,30000_60001_60)
function ConfigManager.parseItemWithComma(rewards)
    return common:parseItemWithComma(rewards)
end
-- (1,2,3)
function ConfigManager.parseCfgWithComma(cfg)
    if cfg == nil then return end
    local showCfg = common:split(cfg, ",")
    return showCfg
end
-- (10000_10001_10)
function ConfigManager.parseItemOnlyWithUnderline(rewards)
    if rewards == nil then return end

    local items = { }
    local _type, _itemId, _count = unpack(common:split(rewards, "_"))
    if _type == nil or _itemId == nil or _count == nil then
        assert(false, "ConfigManager.parseItemOnlyWithUnderline is wrong")
    else
        items["type"] = tonumber(_type)
        items["itemId"] = tonumber(_itemId)
        items["count"] = tonumber(_count)
    end
    return items
end


function ConfigManager.getRoleCfg()
    local key = "RoleCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "quality", "profession", "initLevel", "initExp", "name", "skills", "costType", "maxRank", "poster", "icon", "proIcon", "smallIcon", "bgImg", "condition", "jumpValue", "modelId", "namePic", "avatarName", "spine", "gatherMeg", "banshenxiang", "spineScale", "offset", "trainRatio", "avataBgPic", "chatIcon", "hcgImg" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["quality"] = tonumber,
            ["profession"] = tonumber,
            ["initLevel"] = tonumber,
            ["initExp"] = tonumber,
            ["costType"] = tonumber,
            ["modelId"] = tonumber,
            ["poster"] = checkFilePathValidate,
            ["icon"] = checkFilePathValidate,
            ["proIcon"] = checkFilePathValidate,
            ["smallIcon"] = checkFilePathValidate,
            ["bgImg"] = checkFilePathValidate,
            ["spine"] = checkFilePathValidate,
            ["banshenxiang"] = checkFilePathValidate,
            ["spineScale"] = tonumber,
            ["hcgImg"] = checkFilePathValidate,
        };

        -- 控制是否显示性感图片
        local strFileName = "role.txt"
        cfg = ConfigManager.loadCfg(strFileName, attrMap, 0, convertMap);
        for i, v in pairs(cfg) do
            if v.modelId ~= 0 and cfg[v.modelId] then
                cfg[v.modelId].FashionInfos = cfg[v.modelId].FashionInfos or { v.modelId }
                cfg[v.modelId].FashionInfos[#cfg[v.modelId].FashionInfos + 1] = v.id
            end
        end
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getAnnounceCfg()
    local key = "AnnounceCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Banner" , "isJump"})
        local convertMap = {
            ["id"] = tonumber,
            ["isJump"] = tonumber,
        }

        local strFileName = "News.txt"
        cfg = ConfigManager.loadCfg(strFileName, attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getPopUpCfg()
    local key = "PopUpCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "activityId" , "GiftId", "BG", "Banner","Icon", "Content" , "Title" ,"Reward"})
        local convertMap = {
            ["id"] = tonumber,
            ["GiftId"] = tonumber,
            ["activityId"] = tonumber,
            ["Reward"] = ConfigManager.parseItemWithComma
        }

        local strFileName = "TimeGiftConfig.txt"
        cfg = ConfigManager.loadCfg(strFileName, attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getPopUpCfg2()
    local key = "PopUpCfg2"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "GiftId","Count", "BG", "Banner","Icon", "Content" , "Title" ,"Reward","Sort"})
        local convertMap = {
            ["GiftId"] = tonumber,
            ["Count"] = tonumber,
            ["Sort"] = tonumber,
            ["Reward"] = ConfigManager.parseItemWithComma
        }

        local strFileName = "TimeGiftConfig2.txt"
        cfg = ConfigManager.loadCfg(strFileName, attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getRecharageTypeCfg()
    local key = "RecharageTypeCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", })
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
        }

        local strFileName = "recharageType.txt"
        cfg = ConfigManager.loadCfg(strFileName, attrMap, 0, convertMap);
        for i, v in pairs(cfg) do
            if v.modelId ~= 0 and cfg[v.modelId] then
                cfg[v.modelId].FashionInfos = cfg[v.modelId].FashionInfos or { v.modelId }
                cfg[v.modelId].FashionInfos[#cfg[v.modelId].FashionInfos + 1] = v.id
            end
        end
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getRoleTouchMusicCfg()
    local key = "RoleTouchMusicCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "id",
            "headPos1","headPos2","headSound1","headSound2",
            "heartPos1","heartPos2","heartSound1","heartSound2",
            "assPos1","assPos2","assSound1","assSound2",
            "unLock"
        } );
        local convertMap = {
            ["id"] = tonumber,
        };

        local strFileName = "roleTouchMusic.txt"
        cfg = ConfigManager.loadCfg(strFileName, attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg
    end
    return cfg;
end


function ConfigManager.getRandomNameCfg()
    local key = "RandomName";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "mTitle", "mName", "fTitle", "fName" });
        local convertMap = {
            ["id"] = tonumber
        };
        cfg = ConfigManager.loadCfg("charName.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 月卡
function ConfigManager.getMonthCardCfg()
    local key = "MonthCardCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "giftpack", "expAdd", "fastbattletimes", "refreshtimes", "buildtimes" });
        local convertMap = {
            ["id"] = tonumber,
            ["expAdd"] = tonumber,
            ["fastbattletimes"] = tonumber,
            ["refreshtimes"] = tonumber,
            ["buildtimes"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("monthcard.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 消耗月卡
function ConfigManager.getMonthCard_130Cfg()
    local key = "MonthCard_130";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "giftpack", "expAdd", "fastbattletimes", "refreshtimes", "buildtimes" });
        local convertMap = {
            ["id"] = tonumber,
            ["expAdd"] = tonumber,
            ["fastbattletimes"] = tonumber,
            ["refreshtimes"] = tonumber,
            ["buildtimes"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("monthcardOnce.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getMonthCard_130CfgNew()
    local key = "MonthCard_130";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "DailyGift", "OnBuy"});
        local convertMap = {
            ["id"] = tonumber,
            ["DailyGift"]= ConfigManager.parseItemWithComma,
            ["OnBuy"]= ConfigManager.parseItemWithComma
        };
        cfg = ConfigManager.loadCfg("monthcardOnce.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getSubscription()
    local key = "Subscription";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "OnBuy", "DailyGift"});
        local convertMap = {
            ["id"] = tonumber,
            ["DailyGift"]= ConfigManager.parseItemWithComma,
            ["OnBuy"]= ConfigManager.parseItemWithComma
        };
        cfg = ConfigManager.loadCfg("Subscription168.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getStepBundleCfg()
    local key = "StepBundle";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "reward", "price"});
        local convertMap = {
            ["id"] = tonumber,
            ["reward"]= ConfigManager.parseItemWithComma,
            ["price"]=  tonumber,
        };
        cfg = ConfigManager.loadCfg("releaseStepGiftawrd179.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getLuckyMercenaryCfg()
    local key = "LuckyMercenary";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "mercenaryId", "namePic", "activityId" });
        local convertMap = {
            ["mercenaryId"] = tonumber,
            ["activityId"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("luckyMercenary.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getSummerMercenaryCfg()
    local key = "SummerMercenary";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic", "scale", "offset" });
        local convertMap = {
            ["itemId"] = tonumber,
            ["scale"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("summerMercenary.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getSummerMercenary120Cfg()
    local key = "SummerMercenary120";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic", "scale", "offset" });
        local convertMap = {
            ["itemId"] = tonumber,
            ["scale"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("summerMercenary120.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-----------------------------------------------
function ConfigManager.getActivity137Cfg()
    local key = "getActivity137Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "proportion", "pciId" });
        local convertMap = {
            ["id"] = tonumber,
            ["proportion"] = tonumber,
            ["pciId"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("Activity_137.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-----------------------------------------------

function ConfigManager.getActivity140Cfg()
    local key = "getActivity140Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type" , "index" , "proportion"});
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["index"] = tonumber,
            ["proportion"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("Activity_140.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-----------------------------------------------



-- 获取UR的SPINE信息
function ConfigManager.getNewLuckdrawMercenaryURCfg()
    local key = "getNewLuckdrawMercenaryURCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic" });
        local convertMap = {
            ["itemId"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("NewLuckdrawMercenary.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getLuckyMercenaryBuffCfg()
    local key = "LuckyMercenaryBuff";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "buffId", "desc", "numberType" });
        local convertMap = {
            ["buffId"] = tonumber,
            ["numberType"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("luckyMercenaryBuff.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 
function ConfigManager.getSalepacketCfg()
    local key = "SalepacketCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "index", "salepacket", "minLevel", "maxLevel", "formerPrice", "isgold", "desc", "limitCount" });
        local convertMap = {
            ["id"] = tonumber,
            ["index"] = tonumber,
            ["minLevel"] = tonumber,
            ["maxLevel"] = tonumber,
            ["limitCount"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("salepacket.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getRoleLevelExpCfg()
    local key = "RoleLevelCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "level", "exp" });
        local convertMap = {
            ["level"] = tonumber,
            ["exp"] = tonumber
        };
        cfg = ConfigManager.loadCfg("roleLevelExp.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


function ConfigManager.getLevelLimitCfg()
    local key = "getLevelLimitCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        --        local attrMap = common:table_combineNumber( { "id", "level" });
        --        local convertMap = {
        --            ["level"] = tonumber,
        --        };
        --        cfg = ConfigManager.loadCfg("levelLimitCfg.txt", attrMap, 0, convertMap);
        --        ConfigManager.configs[key] = cfg;

        cfg = { }
        local tabel = TableReaderManager:getInstance():getTableReader("levelLimitCfg.txt")
        local count = tabel:getLineCount() -1;
        for i = 1, count do
            local index = tabel:getData(i, 0)
            if cfg[index] == nil then
                cfg[index] = { }
                cfg[index].key = tabel:getData(i, 0)
                cfg[index].level = tonumber(tabel:getData(i, 1))
            end
        end

        ConfigManager.configs[key] = cfg;
    end

    return cfg;
end

function ConfigManager.getMapCfg()
    local key = "MapCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "bossId", "path", "monsterLevel", "equipRate"  , "mapType"});
        local convertMap = {
            ["id"] = tonumber,
            ["path"] = checkFilePathValidate,
            ["bossId"] = tonumber,
            ["mapType"] = tonumber
        };
        cfg = ConfigManager.loadCfg("map.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getMapDrops()
    local key = "MapDrops";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "drops" });
        local convertMap = {
            ["id"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("mapDrop.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getVipCfg()
    local key = "vipCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        -- vipLevel	买钻要求	快速战斗经验金币加成	快速战斗次数	购买金币次数(buyCoinTimes)	可购买BOSS挑战次数	每日可购买精英副本次数	最高佣兵培养	佣兵远征次数	商品数量(shopItemCount)	可使用BOSS扫荡功能	
        -- 可自动加入工会BOSS战	激活太史慈	宝石商店限购数量	每日免费挑战BOSS次数	每日免费精英副本次数 Boos挑战是否能跳过
        -- GVE普通挂机	GVE高级挂机	神器本体保留
        local attrMap = common:table_combineNumber( {
            "vipLevel","buyDiamon","useHoneyP","useUSD","expBuffer","fastFightTime","buyCoinTime","buyBossFightTime","buyEliteFightTime", "multiEliteCanPurchaseTimes",
            "maxMercenaryTime","yongbingyuanzhengTime","shopItemCount","hasBossMopUp","hasUnionBoss","jihuoTaishici","gemBuy","bossFightTime","eliteFightTime",
            "bossSkip","gveNormalHangUp","gveHighHangUp","artifactBodyHold","dayLogin30SupplementaryCount","canUseSeniorTraing","idleTime","idleRatio","PowerLimit","PowerRecover"
        } );
        local convertMap = {
            ["bossFightTime"] = tonumber,
            ["buyDiamon"] = tonumber,
            ["buyUSD"] = tonumber,
            ["shopItemCount"] = tonumber,
            ["buyCoinTime"] = tonumber,
            ["fastFightTime"] = tonumber,
            ["buyBossFightTime"] = tonumber,
            ["maxMercenaryTime"] = tonumber,
            ["hasBossMopUp"] = tonumber,
            ["hasUnionBoss"] = tonumber,
            ["eliteFightTime"] = tonumber,
            ["buyEliteFightTime"] = tonumber,
            ["multiEliteCanPurchaseTimes"] = tonumber,
            ["soulStoneNum"] = tonumber,
            ["expBuffer"] = tonumber,
            ["multiEliteCanPurchaseTimes"] = tonumber,
            ["yongbingyuanzhengTime"] = tonumber,
            ["jihuoTaishici"] = tonumber,
            ["gemBuy"] = tonumber,
            ["bossSkip"] = tonumber,
            ["gveNormalHangUp"] = tonumber,
            ["gveHighHangUp"] = tonumber,
            ["artifactBodyHold"] = tonumber,
            ["dayLogin30SupplementaryCount"] = tonumber,
            ["canUseSeniorTraing"] = tonumber,
            ["idleTime"] = tonumber,
            ["idleRatio"] = tonumber,
            ["PowerLimit"] = tonumber,
            ["PowerRecover"] = tonumber,          
        };
        cfg = ConfigManager.loadCfg("vipPrivilege.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getHeroOrderTaskCfg()
    local key = "HeroOrdrCfg";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "taskId","levelLimit","monsterNumNeedKill","rewardItem","heroOrderId"
        } )

        local convertMap = {
            ["taskId"] = tonumber,
            ["levelLimit"] = tonumber,
            ["monsterNumNeedKill"] = tonumber,
            ["rewardItem"] = ConfigManager.parseItemOnlyWithUnderline,
            ["heroOrderId"] = tonumber
        }
        cfg = ConfigManager.loadCfg("heroTokenTask.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getHelpFightRewardCfg()
    local key = "HelpFightRewardCfg";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "id","rewards",
        } )

        local convertMap = {
            ["id"] = tonumber,
            ["rewards"] = ConfigManager.parseItemOnlyWithUnderline,
        }
        cfg = ConfigManager.loadCfg("EighteenPrincesHelpAward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getPunchCfg()
    local key = "PunchCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","itemCost","goldCost"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["itemCost"] = function(str)
                local itemCost = { };
                for i, subStr in ipairs(common:split(str, ",")) do
                    local _type, _id, _count = unpack(common:split(subStr, "_"));
                    itemCost[i] = {
                        type = tonumber(_type),
                        id = tonumber(_id),
                        count = tonumber(_count)
                    };
                end
                return itemCost;
            end,
            ["goldCost"] = function(str)
                local goldCost = { };
                for i, subStr in ipairs(common:split(str, ",")) do
                    local _type, _id, _count = unpack(common:split(subStr, "_"));
                    goldCost[i] = {
                        type = tonumber(_type),
                        id = tonumber(_id),
                        count = tonumber(_count)
                    };
                end
                return goldCost;
            end
        };
        cfg = ConfigManager.loadCfg("equipPunch.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getEquipCfg()
    local key = "EquipCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","isOpen","name","partName","part",
            "quality","level","profession","smeltGain",
            "costItem1", "costItem2", "costCoin", "costReo",
            --"forgeSmeltNeed",
            "washCoinCost","equipAttr","icon","punchConsume","stepLevel","suitId","suitQuality","evolutionStuff","evolutionId","additionalAttr",
            "upgradeId","fixedMaterial","priorityMaterialId","mixingMaterialId","variableMaterialNum","decompose","score","mercenarySuitId",
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["stepLevel"] = tonumber,
            ["part"] = tonumber,
            ["quality"] = tonumber,
            ["sellPrice"] = tonumber,
            ["smeltGain"] = tonumber,
            ["costItem1"] = {},
            ["costItem2"] = {},
            ["costCoin"] = tonumber,
            ["costReo"] = tonumber,
            --["forgeSmeltNeed"] = tonumber,
            ["washCoinCost"] = tonumber,
            ["icon"] = checkFilePathValidate,
            ["profession"] = function(str)
                return common:split(str, ",");
            end,
            ["punchConsume"] = function(str)
                local _type, _id, _count = unpack(common:split(str, "_"));
                local consumes = {
                    type = tonumber(_type),
                    id = tonumber(_id),
                    count = tonumber(_count)
                };
                return consumes;
            end,
            ["suitId"] = tonumber,
            ["suitQuality"] = tonumber,
            ["evolutionStuff"] = function(str)
                if str == "0" then return 0 end
                local consumes = { }
                for i, subStr in ipairs(common:split(str, ",")) do
                    local _type, _id, _count = unpack(common:split(subStr, "_"));
                    consumes[i] = {
                        type = tonumber(_type),
                        itemId = tonumber(_id),
                        count = tonumber(_count)
                    }
                end
                return consumes
            end,
            ["evolutionId"] = tonumber,
            ["upgradeId"] = tonumber,
            ["fixedMaterial"] = function(str)
                if str == "0" then return 0 end
                local consumes = { }
                for i, subStr in ipairs(common:split(str, ",")) do
                    local _type, _id, _count = unpack(common:split(subStr, "_"));
                    consumes[i] = {
                        type = tonumber(_type),
                        itemId = tonumber(_id),
                        count = tonumber(_count)
                    }
                end
                return consumes
            end,
            ["priorityMaterialId"] = tonumber,
            ["mixingMaterialId"] = tonumber,
            ["variableMaterialNum"] = tonumber,
            ["decompose"] = tonumber,
            ["score"] = tonumber,
            ["mercenarySuitId"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("equip.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


-- 124
function ConfigManager.getRechargeReturnLottery_124Cfg()
    local key = "activity_124";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "proportion", "probability" });
        local convertMap = {
            ["id"] = tonumber,
            ["proportion"] = tonumber,
            ["probability"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("rechargeReturnLottery.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;

        CCLuaLog("-------------------------------------------------" .. #cfg)
    end
    return cfg;
end


function ConfigManager.RoleEquipDescCfg()
    local key = "RoleEquip";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","mercenaryId","desc1","desc2","desc3","equipId"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["equipId"] = tonumber,
            ["mercenaryId"] = ConfigManager.parseCfgWithComma
        };
        cfg = ConfigManager.loadCfg("roleEquip.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getQualityColor()
    local key = "QualityColor";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( { "id", "textColor" });
        local convertMap = {
            ["id"] = tonumber,
            ['textColor'] = function(attrStr)
                return attrStr:gsub(",", " ")
            end
        }
        cfg = ConfigManager.loadCfg("qualityColor.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getItemCfg()
    local key = "ItemCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","name","type","levelLimit","profLimit",
            "price","needItem","containItem","levelUpCost","levelUpRate",
            "levelUpItem","strength","agility","intellect","stamina",
            "icon","levelUpCostMax","description","smeltCost","AFKhour","quality",
            "jumpPage","soulStoneExp","skillExp","heroTaskId","stoneType",
            "location","attr","isNewStone","stoneLevel","stoneLevelUpCost",
            "exchange","exchangeCrystalNum","suitLevel","part","description2","sortType",
            "sortId"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["levelLimit"] = tonumber,
            ["profLimit"] = tonumber,
            ["price"] = tonumber,
            ["strength"] = tonumber,
            ["agility"] = tonumber,
            ["levelUpItem"] = tonumber,
            ["icon"] = checkFilePathValidate,
            ["intellect"] = tonumber,
            ["stamina"] = tonumber,
            ["AFKhour"] = tonumber,
            ["quality"] = tonumber,
            ["smeltCost"] = tonumber,
            ["soulStoneExp"] = tonumber,
            ["levelUpCostMax"] = function(str)
                local max, step = unpack(common:split(str, ","));
                return tonumber(max);
            end,
            ["levelUpCost"] = ConfigManager.parseItem,
            ["skillExp"] = tonumber,
            ["heroTaskId"] = tonumber,
            ["stoneType"] = tonumber,
            ["sortId"] = tonumber,
            ["location"] = function(str)
                if str == "" then return str end
                local posList = common:split(str, ",");
                for i, v in ipairs(posList) do
                    posList[i] = tonumber(v)
                end
                return posList;
            end,
            ["attr"] = function(str)
                if str == "" then return str end
                local attrList = common:split(str, ",");
                for i, v in ipairs(attrList) do
                    attrList[i] = common:split(v, "_");
                    for j, v1 in ipairs(attrList[i]) do
                        attrList[i][j] = tonumber(v1)
                    end
                end
                return attrList;
            end,
            ["isNewStone"] = tonumber,
            ["stoneLevel"] = tonumber,
            ["suitLevel"] = tonumber,
            ["part"] = tonumber,
            ["sortType"] = tonumber,
            ["exchangeCrystalNum"] = function(str)
                if str == "0" then return 0 end
                local consumes = { }
                for i, subStr in ipairs(common:split(str, ",")) do
                    local _type, _id, _count = unpack(common:split(subStr, "_"));
                    consumes[i] = {
                        type = tonumber(_type),
                        itemId = tonumber(_id),
                        count = tonumber(_count)
                    }
                end
                return consumes
            end,
        };
        cfg = ConfigManager.loadCfg("item.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getGemMarketCfg()
    local key = "GemMarket";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","itemId","costGold","costItems","vipLimit","isExchangeByItem"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["itemId"] = tonumber,
            ["costGold"] = tonumber,
            ["vipLimit"] = tonumber,
            ["isExchangeByItem"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("gemshop.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getNewGemMarketCfg()
    local key = "NewGemMarket";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","itemId","costGold","costItems","vipLimit","isExchangeByItem","costCoin","group"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["itemId"] = tonumber,
            ["costGold"] = tonumber,
            ["vipLimit"] = tonumber,
            ["isExchangeByItem"] = tonumber,
            ["group"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("gemshop1.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getResPropertyCfg()
    local key = "ResPropCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","name","type","discribe"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber
        };
        cfg = ConfigManager.loadCfg("ResPropertyConfig.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getUserPropertyCfg()
    local key = "UserPropCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","name","quality","discribe","icon"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["icon"] = checkFilePathValidate,
            ["quality"] = tonumber
        };
        cfg = ConfigManager.loadCfg("UserProperty.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager._getItemCfg(itemStr)
    local cfgAttr = { "type", "id", "count" }
    local cfg = { }
    for index, val in ipairs(Split(itemStr, ":")) do
        cfg[cfgAttr[index]] = tonumber(val)
    end
    return cfg
end

function ConfigManager.getMonsterCfg()
    local key = "monster"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","profession","level","name","skills",
            "icon","isBoss","spineId","banshenxiang","spine","spineScale","offset","isFlipX"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["profession"] = tonumber,
            ["level"] = tonumber,
            ["icon"] = checkFilePathValidate,
            ["isBoss"] = tonumber,
            ["spineId"] = tonumber,
            ["banshenxiang"] = checkFilePathValidate,
            ["spine"] = checkFilePathValidate,
            ["spineScale"] = tonumber,
            ["isFlipX"] = tonumber,-- 0不翻转  1翻转
        }
        cfg = ConfigManager.loadCfg("monster.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getRechargeDiscountCfg()
    local key = "RechargeDiscountCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Sort", "salepacket", "minLevel", "maxLevel", "formerPrice", "originalHNP", "name", "limitType", "limitNum", "isgold" });
        local convertMap = {
            ["id"] = tonumber,
            ["Sort"] = tonumber,
            ["minLevel"] = tonumber,
            ["maxLevel"] = tonumber,
            ["limitType"] = tonumber,
            ["limitNum"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("DiscountGift.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.ShopBuyCoin()
    local key = "ShopBuyCoin";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Diamond","Coin"});
        local convertMap = {
            ["id"] = tonumber,
            ["Diamond"] = tonumber,
            ["Coin"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("shopBuyCoinCfg.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.ShopBuyCoinLv()
    local key = "ShopBuyCoinLv";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "index"});
        local convertMap = {
            ["id"] = tonumber,
            ["index"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("shopBuyCoinLevel.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getHelpFightMapCfg()
    local key = "HelpFightMap"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","name","iconpath","map","rolename","mapname",
        } )
        local convertMap = {
            ["id"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("Eighteencheckpoint.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getMultiMonsterCfg()
    local key = "multiMonster"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","profession","level","name","skills",
            "icon","banshenxiang","isBoss","spineId","isFlipX"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["profession"] = tonumber,
            ["level"] = tonumber,
            ["icon"] = checkFilePathValidate,
            ["banshenxiang"] = checkFilePathValidate,
            ["isBoss"] = tonumber,
            ["spineId"] = tonumber,
            ["isFlipX"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("multiMonster.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getWeekCardCfg()
    local key = "week"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","index","name","rewards","freeTypeId","param"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["index"] = tonumber,
            ["freeTypeId"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("weekcard.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


--function ConfigManager.getSkillCfg()
--    local key = "skillCfg"
--    local cfg = ConfigManager.configs[key]
--    if cfg == nil then
--
--        local attrMap = common:table_combineNumber( {
--            "id","name","profession","openLevel","costMP",
--            "coldRound","skillScript","describe","icon","battleAction","battleRecord","roleId","condition"
--        } )
--        local convertMap = {
--            ["id"] = tonumber,
--            ["profession"] = tonumber,
--            ["openLevel"] = tonumber,
--            ["costMP"] = tonumber,
--            ["roleId"] = tonumber,
--            ["condition"] = tostring,
--        }
--        cfg = ConfigManager.loadCfg("skill.txt", attrMap, 0, convertMap)
--        ConfigManager.configs[key] = cfg
--    end
--    -- local SkillManager = require ("SkillManager")
--
--    return cfg
--end

function ConfigManager.getBuffCfg()
    local key = "buffCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","name","isAdd"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["isAdd"] = tonumber
        }
        cfg = ConfigManager.loadCfg("buff.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getNewBuffCfg()
    local key = "newBuffCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id", "group", "buffType", "max_count", "priority", "values", "gain", "visible", "dispel", "posType", "spineName"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["group"] = tonumber,
            ["buffType"] = tonumber,
            ["max_count"] = tonumber,
            ["priority"] = tonumber,
            ["gain"] = tonumber,
            ["visible"] = tonumber,
            ["dispel"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("buff_New.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getHelpCfg(key)
    -- local key = "helpCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil or cfg == { } then

        local attrMap = common:table_combineNumber( {
            "id","content"
        } )
        local convertMap = {
            ["id"] = tonumber
        }
        cfg = ConfigManager.loadCfg(key .. ".txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getAllianceBossCfg()
    local key = "AllianceBossConfig"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'bossName', 'level', 'bossExp', 'bossId', 'bossBlood' })
        local convertMap = {
            ["id"] = tonumber,
            ['level'] = tonumber,
            ['bossExp'] = tonumber,
            ['bossId'] = tonumber,
            ['bossBlood'] = tonumber
        }
        cfg = ConfigManager.loadCfg("alliance.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getGiftConfig()
    local key = "Mission"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'name', 'type', 'reward', 'icon', 'desc' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ["icon"] = checkFilePathValidate,
        }
        cfg = ConfigManager.loadCfg("mission.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getSkillOpenCfg()
    local key = "SkillOpenCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'openLevel' })
        local convertMap = {
            ['id'] = tonumber,
            ['openLevel'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("SkillOpenCfg.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getMercenarySkillOpenCfg()
    local key = "MercenarySkillOpenCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'openLevel' })
        local convertMap = {
            ['id'] = tonumber,
            ['openLevel'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("MercenarySkillOpenCfg.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getBGMusicCfg()
    local key = "BGMusicCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'chineseName', 'englishName', 'musicPath' })
        local convertMap = {
            ['id'] = tonumber,
            ['musicPath'] = checkFilePathValidate,
        }
        cfg = ConfigManager.loadCfg("musicCfg.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getPlayerTitleCfg()
    local key = "PlayerTitleCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'name', 'describe', 'type', 'picPath', 'BGPath' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['picPath'] = checkFilePathValidate,
            ['BGPath'] = checkFilePathValidate,
        }
        cfg = ConfigManager.loadCfg("PlayerTitle.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getLoginCfg()
    local key = "ActDayLoginCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'day', 'description' })
        local convertMap = {
            ['day'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("activityDayLogin.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getMainActivityShowCfg()
    local key = "mainActivityShow"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'description' })
        local convertMap = {
            ['id'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("mainActivityShow.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.parseItem(str)
    if str == nil then return end
    -- dangerous way!! really have no ideas.
    local _coin, _itemId, _count = unpack(common:split(str, "_"));
    local consumes = { };
    _coin = tonumber(_coin);
    -- 消耗金币
    if _coin >= 10000 then
        table.insert(consumes, {
            type = Const_pb.PLAYER_ATTR * 10000,
            id = Const_pb.COIN,
            count = _coin
        } );
        -- 消耗钻石
    elseif _coin > 0 and _coin < 5000 then
        table.insert(consumes, {
            type = Const_pb.PLAYER_ATTR * 10000,
            id = Const_pb.GOLD,
            count = _coin
        } );
    end

    if _itemId ~= nil and _count ~= nil and _itemId ~= "0" and _count ~= "0" then
        table.insert(consumes, {
            type = Const_pb.TOOL * 10000,
            id = tonumber(_itemId),
            count = tonumber(_count)
        } );
    end
    return consumes;
end

function ConfigManager.getGemCompoundCfg()
    local key = "GemCompoundCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            'orderId','oriGem','redGem','greenGem',
            'blueGem','yellowGem','goalGem','isHighest'
        } )
        local convertMap = {
            ['orderId'] = tonumber,
            ['oriGem'] = tonumber,
            ["redGem"] = ConfigManager.parseItem,
            ["greenGem"] = ConfigManager.parseItem,
            ["blueGem"] = ConfigManager.parseItem,
            ["yellowGem"] = ConfigManager.parseItem,
            ['goalGem'] = tonumber,
            ['isHighest'] = tonumber,
        };
        cfg = ConfigManager.loadCfg("GemCompound.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getCSTimeListCfg()
    local key = "CSTimeListCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber(
        {
            'battleId','valid','signUpStartTime','signUpEndTime','signUpLimitLevel','perKonckoutStartTime',
            'perKonckoutEndTime','per16To8StartTime','per8To4StartTime','per4To2StartTime','per2To1StartTime',
            'croKonckoutStartTime','croKonckoutEndTime','cro16To8StartTime','cro8To4StartTime',
            'cro4To2StartTime','cro2To1StartTime','reviewTime',
        } )
        local convertMap = {
            ['battleId'] = tonumber,
            ['valid'] = tonumber,
            ['signUpLimitLevel'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("CSTimeList.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getWorshipCfg()
    local key = "WorshipCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber(
        { 'worshipId', 'worshipName', 'worshipCost', 'worshipReward' })
        local convertMap = {
            ['worshipId'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("CSWorship.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getBetCfg()
    local key = "BetCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber(
        {
            'battleId','cro16To8BetCost','cro16To8BetReward','cro8To4BetCost','cro8To4BetReward','cro4To2BetCost',
            'cro4To2BetReward','cro2To1BetCost','cro2To1BetReward','per16To8BetCost','per16To8BetReward',
            'per8To4BetCost','per8To4BetReward','per4To2BetCost','per4To2BetReward','per2To1BetCost','per2To1BetReward',
        } )
        local convertMap = {
            ['battleId'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("CSBet.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getFindTreasureCfg()
    local key = "FindTreasureCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber(
        { 'id', 'type', 'reward', 'cost', })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['reward'] = ConfigManager.parseItemOnlyWithUnderline,
            ['cost'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("FindTreasure.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 公会争霸读取配置文件
-- 押注奖励表
function ConfigManager.getABBetCfg()
    local key = "ABBetCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'group', 'winReward', 'failReward', 'costGold', 'costCoins' })
        local convertMap = {
            ['winReward'] = ConfigManager.parseItemWithComma,
            ['failReward'] = ConfigManager.parseItemWithComma,
            ['costGold'] = tonumber,
            ['costCoins'] = tonumber
        }
        cfg = ConfigManager.loadCfg("investReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 公会争霸排名奖励表
function ConfigManager.getABRankRewardCfg()
    local key = "ABRankRewardCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'top', 'position', 'reward', 'getKey', 'gameType', 'positionShow' })
        local convertMap = {
            ['reward'] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("allianceBattleReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end




function ConfigManager.getRouletteCfg()
    local key = "RouletteCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'items' })
        local convertMap = {
            ['items'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("RouletteItems.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getLuckyBoxCfg()
    local key = "LuckyBoxCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'items' })
        local convertMap = {
            ['id'] = tonumber,
            ['items'] = ConfigManager.parseItemOnlyWithUnderline,
        }
        cfg = ConfigManager.loadCfg("LuckyBox.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getRouletteShopCfg()
    local key = "RouletteShopCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'items', 'score' })
        local convertMap = {
            ['id'] = tonumber,
            ['items'] = ConfigManager.parseItemWithComma,
            ['score'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("RouletteShopItems.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getGodlyAttrCfg()
    local key = "GodlyAttrCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "attrId", "enhanceAttrs", "baseAttr", "growAttr" });
        local convertMap = {
            ["attrId"] = tonumber,
            ["baseAttr"] = tonumber,
            ["growAttr"] = tonumber,
            ["enhanceAttrs"] = function(attrStr)
                return common:split(attrStr, ",");
            end
        };
        cfg = ConfigManager.loadCfg("godlyAttr.txt", attrMap, 1, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


function ConfigManager.getAttrPureCfg()
    local key = "AttrPureCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "desc", "attrType" });
        local convertMap = {
            ["attrType"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("PropertyType.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getEquipEnhanceAttrCfg()
    local key = "EquipEnhanceAttrCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = { mainAttr = 1 };
        local convertMap = {
            mainAttr = function(attrStr)
                return common:split(attrStr, ",");
            end
        };
        cfg = ConfigManager.loadCfg("equipStrength.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

--- 强化消耗的道具
function ConfigManager.getEquipEnhanceItemCfg()
    local key = "EquipStrengthRatioCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "costItem", "costCoin"});
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            --强化石
            ["costItem"] = ConfigManager.parseItemOnlyWithUnderline,
            -- 金幣
            ["costCoin"] = tonumber,
        };

        cfg = ConfigManager.loadCfg("equipStrengthRatio.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

--- 强化消耗的道具的权重
function ConfigManager.getEquipEnhanceWeightCfg()
    local key = "EquipRatioCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "ratio" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            --
            ["ratio"] = tonumber
        };

        cfg = ConfigManager.loadCfg("equipRatio.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getGoldlyLevelExpCfg()
    local key = "GoldlyLevelExpCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = { exp = 1, exp2 = 2 };
        local convertMap = {
            ["exp"] = tonumber,
            ["exp2"] = tonumber
        };
        cfg = ConfigManager.loadCfg("godlyLevelExp.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getBattleParamCfg()
    local key = "BattleParamCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "level","Attr_105","Attr_106","Attr_107","Attr_108",
            "Attr_111","Attr_109","Attr_110","Attr_1007","Attr_2103",
            "Attr_2104"
        } );
        cfg = ConfigManager.loadCfg("battleParameter.txt", attrMap, 0);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 
function ConfigManager.getMarketBuyCoinCountCfg()
    local key = "MarketBuyCoinCountCfg";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'vipLevel', 'buyCount' })
        local convertMap = {
            ['vipLevel'] = tonumber,
            ['buyCount'] = tonumber
        }
        cfg = ConfigManager.loadCfg("MarketCoinCount.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 
function ConfigManager.getTeamBattleKickCfg()
    local key = "TeamBattleKickCfg";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'kickCount', 'goldCost' })
        local convertMap = {
            ['kickCount'] = tonumber,
            ['goldCost'] = tonumber
        }
        cfg = ConfigManager.loadCfg("TeamBattleKick.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 
function ConfigManager.getMailContentCfg()
    local key = "MailContentCfg";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'mailId', 'content' })
        local convertMap = {
            ['mailId'] = tonumber
        }
        local userType = CCUserDefault:sharedUserDefault():getIntegerForKey("LanguageType");
	    if userType == kLanguageChinese then
	    	cfg = ConfigManager.loadCfg("MailIdConfig.txt", attrMap, 0, convertMap)
	    elseif userType == kLabguageCH_TW then
	    	cfg = ConfigManager.loadCfg("MailIdConfigTW.txt", attrMap, 0, convertMap)
	    else
	    	cfg = ConfigManager.loadCfg("MailIdConfig.txt", attrMap, 0, convertMap)
        end
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 
function ConfigManager.getRefreshMarketCostCfg()
    local key = "RefreshMarketCostCfg";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'cost' })
        local convertMap = {
            ['id'] = tonumber,
            ['cost'] = tonumber
        }
        cfg = ConfigManager.loadCfg("ShopRefreshCost.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getRewardCfg()
    local key = "RewardCfg";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = { rewardItems = 1 }
        cfg = ConfigManager.loadCfg("reward.txt", attrMap, 0)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getRewardById(rewardId)
    local allCfg = ConfigManager.getRewardCfg();
    local cfg = allCfg[rewardId] or { };

    local rewardItems = { };
    if cfg["rewardItems"] ~= nil then
        for _, item in ipairs(common:split(cfg["rewardItems"], ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"))
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end
    return rewardItems;
end

-- 跨服战
function ConfigManager.getCSWarriorRewardConfig()

    local key = "CSWarriorBattle"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "battleId","perPatacipateReward","perWinners16Reward","perWinners8Reward",
            "perWinners4Reward","perWinners2Reward","perWinners1Reward","perLosers16Reward","perLosers8Reward",
            "perLosers4Reward","perLosers2Reward","perLosers1Reward","croPatacipateReward",
            "croWinners16Reward","croWinners8Reward","croWinners4Reward","croWinners2Reward","croWinners1Reward",
            "croLosers16Reward","croLosers8Reward","croLosers4Reward","croLosers2Reward",
            "croLosers1Reward","croChampion"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["perPatacipateReward"] = ConfigManager.parseItemWithComma,
            ["perWinners16Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners8Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners4Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners2Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners1Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers16Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers8Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers4Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers2Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers1Reward"] = ConfigManager.parseItemWithComma,
            ["croPatacipateReward"] = ConfigManager.parseItemWithComma,
            ["croWinners16Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners8Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners4Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners2Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners1Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers16Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers8Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers4Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers2Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers1Reward"] = ConfigManager.parseItemWithComma,
            ["croChampion"] = ConfigManager.parseItemOnlyWithUnderline
        }
        cfg = ConfigManager.loadCfg("CSWarriorRewards.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getCSHunterRewardConfig()

    local key = "CSHunterBattle"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "battleId","perPatacipateReward","perWinners16Reward","perWinners8Reward",
            "perWinners4Reward","perWinners2Reward","perWinners1Reward","perLosers16Reward","perLosers8Reward",
            "perLosers4Reward","perLosers2Reward","perLosers1Reward","croPatacipateReward",
            "croWinners16Reward","croWinners8Reward","croWinners4Reward","croWinners2Reward","croWinners1Reward",
            "croLosers16Reward","croLosers8Reward","croLosers4Reward","croLosers2Reward",
            "croLosers1Reward","croChampion"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["perPatacipateReward"] = ConfigManager.parseItemWithComma,
            ["perWinners16Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners8Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners4Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners2Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners1Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers16Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers8Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers4Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers2Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers1Reward"] = ConfigManager.parseItemWithComma,
            ["croPatacipateReward"] = ConfigManager.parseItemWithComma,
            ["croWinners16Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners8Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners4Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners2Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners1Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers16Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers8Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers4Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers2Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers1Reward"] = ConfigManager.parseItemWithComma,
            ["croChampion"] = ConfigManager.parseItemOnlyWithUnderline
        }
        cfg = ConfigManager.loadCfg("CSHunterRewards.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getCSMagicianRewardConfig()

    local key = "CSMagicianBattle"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "battleId","perPatacipateReward","perWinners16Reward","perWinners8Reward",
            "perWinners4Reward","perWinners2Reward","perWinners1Reward","perLosers16Reward","perLosers8Reward",
            "perLosers4Reward","perLosers2Reward","perLosers1Reward","croPatacipateReward",
            "croWinners16Reward","croWinners8Reward","croWinners4Reward","croWinners2Reward","croWinners1Reward",
            "croLosers16Reward","croLosers8Reward","croLosers4Reward","croLosers2Reward",
            "croLosers1Reward","croChampion"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["perPatacipateReward"] = ConfigManager.parseItemWithComma,
            ["perWinners16Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners8Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners4Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners2Reward"] = ConfigManager.parseItemWithComma,
            ["perWinners1Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers16Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers8Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers4Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers2Reward"] = ConfigManager.parseItemWithComma,
            ["perLosers1Reward"] = ConfigManager.parseItemWithComma,
            ["croPatacipateReward"] = ConfigManager.parseItemWithComma,
            ["croWinners16Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners8Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners4Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners2Reward"] = ConfigManager.parseItemWithComma,
            ["croWinners1Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers16Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers8Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers4Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers2Reward"] = ConfigManager.parseItemWithComma,
            ["croLosers1Reward"] = ConfigManager.parseItemWithComma,
            ["croChampion"] = ConfigManager.parseItemOnlyWithUnderline
        }
        cfg = ConfigManager.loadCfg("CSMagicianRewards.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getRewardByString(rewardString)
    local allCfg = ConfigManager.getRewardCfg();
    local rewardItems = { };
    if rewardString ~= nil then
        for _, item in ipairs(common:split(rewardString, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end
    return rewardItems;
end

function ConfigManager.getConsumeCfg()
    local key = "ConsumeCfg";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = { type = 1, consumeItems = 2 };
        cfg = ConfigManager.loadCfg("consume.txt", attrMap, 0);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getConsumeById(consumeId)
    local allCfg = ConfigManager.getConsumeCfg();
    local cfg = allCfg[consumeId] or { };

    local consumeItems = { };
    if cfg["consumeItems"] ~= nil then
        for _, item in ipairs(common:split(cfg["consumeItems"], ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(consumeItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end
    return {
        type = tonumber(cfg["type"]),
        items = consumeItems
    };
end

-- error code
function ConfigManager.getErrorCodeCfg()
    local key = "ErrorCode";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "content" });
        local convertMap = {
            ["id"] = tonumber
        };
        cfg = ConfigManager.loadCfg("ErrorCode.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getGodlyEquipCanBuild()
    local key = "GodlyEquip";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "equipId", "attrCount", "reputation", "smeltValue", "minLv", "maxLv" });
        local convertMap = {
            ["id"] = tonumber,
            ["equipId"] = tonumber,
            ["attrCount"] = tonumber,
            ["reputation"] = tonumber,
            ["smeltValue"] = tonumber,
            ["minLv"] = tonumber,
            ["maxLv"] = tonumber
        };
        cfg = ConfigManager.loadCfg("godlyEquip.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getCampWarWinStreak()
    local key = "CampWarStreak";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "winStreak", "winCoinsRatio", "winReputation", "loseCoinsRatio", "loseReputation" });
        local convertMap = {
            ["id"] = tonumber,
            ["winStreak"] = tonumber,
            ["winCoinsRatio"] = tonumber,
            ["winReputation"] = tonumber,
            ["loseCoinsRatio"] = tonumber,
            ["loseReputation"] = tonumber
        };
        cfg = ConfigManager.loadCfg("campWarWinStreak.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getVipWelfareCfg()
    local key = "VipWelfare";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "reward" });
        local convertMap = {
            ["id"] = tonumber
        };
        cfg = ConfigManager.loadCfg("VipWelfare.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getVipGiftCfg()
    local key = "VipGift";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "order", "vipLevel", "nowPrice", "formerPrice", "reward", "name" });
        local convertMap = {
            ["id"] = tonumber,
            ["order"] = tonumber,
            ["vipLevel"] = tonumber,
            ["nowPrice"] = tonumber,
            ["formerPrice"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("VipPackage.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 读取firstGiftPack文件信息配置从Resource_Clinet/txt/firstgiftpack.txt
function ConfigManager.getFirstGiftPack()
    local key = "firstgiftpack"
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "giftpack", "isgold", "textColor" })
        local convertMap = {
            ["id"] = tonumber,
            ['textColor'] = function(attrStr)
                return attrStr:gsub(",", " ")
            end
        }
        cfg = ConfigManager.loadCfg("firstgiftpack.txt", attrMap, nil, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getFirstGiftPack_New()
    local key = "NPcontinueRechargeMoney160"
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "NeedMoney", "Rewards" })
        local convertMap = {
            ["id"] = tonumber,
            ['NeedMoney'] = tonumber ,
            ['Rewards']=ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("NPcontinueRechargeMoney160.txt", attrMap, nil, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getDailyBundle()
    local key = "getDailyBundle"
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "NeedMoney", "Rewards" })
        local convertMap = {
            ["id"] = tonumber,
            ['NeedMoney'] = tonumber ,
            ['Rewards']=ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("DailyRecharge159.txt", attrMap, nil, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getEliteMapCfg()
    local key = "EliteMapCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "mapId","group","levelIndex","level","nextMapId","dependMap",
            "rewardItem","monsterId","name","monsterLevel","isBoss","quality","stageName","exp","coin","monster1","monster2","monster3","monster4","monster5","firstDrop"
        } );
        local convertMap = {
            ["mapId"] = tonumber,
            ["group"] = tonumber,
            ["levelIndex"] = tonumber,
            ["level"] = tonumber,
            ["nextMapId"] = tonumber,
            ["dependMap"] = tonumber,
            ["monsterId"] = tonumber,
            ["monsterLevel"] = tonumber,
            ["isBoss"] = tonumber,
            ["quality"] = tonumber,
            ["exp"] = tonumber,
            ["coin"] = tonumber,
            ["monster1"] = tonumber,
            ["monster2"] = tonumber,
            ["monster3"] = tonumber,
            ["monster4"] = tonumber,
            ["monster5"] = tonumber
        };
        cfg = ConfigManager.loadCfg("EliteMapCfg.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    -- classify the data
    --local EliteMapManager = require("Battle.EliteMapManager")
    --EliteMapManager:classifyGroup(cfg)
    return cfg;
end

function ConfigManager.getMercenaryUpStepTable()
    local key = "roleStar";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "id", "roleId", "starLevel", "stageLimit", "exp"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["roleId"] = tonumber,
            ["starLevel"] = tonumber,
            ["stageLimit"] = tonumber,
            ["exp"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("roleStar.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getMercenaryRingCfg()
    local key = "mercenaryRing";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "ringId","merId","starLimit","consume","name","discribe",
            "icon","condition","parameter1","parameter2"
        } );
        local convertMap = {
            ["ringId"] = tonumber,
            ["merId"] = tonumber,
            ["starLimit"] = tonumber,
            ["icon"] = checkFilePathValidate,
            ["consume"] = tonumber,
            ["condition"] = tostring,
            ["discribe"] = tostring,
        };
        cfg = ConfigManager.loadCfg("ring.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end

    local MercenaryHaloManager = require("Mercenary.MercenaryHaloManager")
    MercenaryHaloManager:classifyGroup(cfg)
    return cfg;
end

function ConfigManager.getServerBroadCodeCfg()
    local key = "ServerBroadCode";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "serverKey", "langKey" });
        local convertMap = {
            ["id"] = tonumber
        };
        cfg = ConfigManager.loadCfg("ServerBroadCode.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


function ConfigManager.getI18nTxtCfg()
    local key = "I18nConfig";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "languageType", "srcPath", "textIsLeft2Right", "isForce", "r2MvpRecharge", "languageName", "icon", "languageTitle" });
        local convertMap = {
            ["id"] = tonumber,
            ["languageType"] = tonumber,
            ["textIsLeft2Right"] = tonumber,
            ["isForce"] = tonumber,
            ["r2MvpRecharge"] = tonumber
        };
        cfg = ConfigManager.loadCfg("I18nConfig.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getI18nAttrByType(langType, attrName)
    local config = ConfigManager.getI18nTxtCfg();
    if config then
        for k, v in ipairs(config) do
            if v.languageType == langType then
                return v[attrName];
            end
        end
    end
    return nil;
end


function ConfigManager.getI18nPlatformCfg()
    local key = "I18nPlatform";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "PlatformName", "LanguageTypeList" })
        local convertMap = {
            ["id"] = tonumber,
            ["LanguageTypeList"] = function(str)
                local list = { }
                for _, item in ipairs(common:split(str, ",")) do
                    table.insert(list, tonumber(item))
                end
                return list
            end,
        };
        cfg = ConfigManager.loadCfg("I18nPlatform.cfg", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


function ConfigManager.getRingLevelConfig()
    local key = "RingLevelCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "index", "itemId", "discribe", "level", "exp", "param1" });
        local convertMap = {
            ["index"] = tonumber,
            ["itemId"] = tonumber,
            ["level"] = tonumber,
            ["exp"] = tonumber,
            ["param1"] = tostring,
        };
        cfg = ConfigManager.loadCfg("ringlevel.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getEliteMapLevelIndex()
    local key = "EliteMapLevelIndex";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "userLevel", "index" });
        local convertMap = {
            ["userLevel"] = tonumber,
            ["index"] = tonumber
        };
        cfg = ConfigManager.loadCfg("eliteMapLevelIndex.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getTimeLimitPurcgaseItem()
    local key = "TimeLimitPurchase";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "goodsId", "originalPrice", "salePrice", "vipLimit", "levelLimit", "buyType", "maxBuyTimes", "message_1", "message_2" });
        local convertMap = {
            ["id"] = tonumber,
            ["vipLimit"] = tonumber,
            ["levelLimit"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("TimeLimitPurchase.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getAccumulativeRechargeItem()
    local key = "AccumulativeRechargeItem";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "needGold", "reward" });
        local convertMap = {
            ["id"] = tonumber,
            ["needGold"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("accRecharge.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getSingleRecharge()
    local key = "SingleRecharge";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "needGold", "reward", "price" });
        local convertMap = {
            ["id"] = tonumber,
            ["needGold"] = tonumber,
            ["price"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("singleRecharge.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getCumulativeLogin()
    local key = "CumulativeLogin";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "day", "reward" });
        local convertMap = {
            ["id"] = tonumber,
            ["day"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("accLogin.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


function ConfigManager.getSkillEnhanceCfg()
    local key = "SkillEnhance";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id","skillItemId","level","name","type","profession","openLevel","seLevel","exp",
            "icon","describe","costMP","costItem","param1","param2","param3"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["skillItemId"] = tonumber,
            ["level"] = tonumber,
            ["type"] = tonumber,
            ["profession"] = tonumber,
            ["openLevel"] = tonumber,
            ["seLevel"] = tonumber,
            ["exp"] = tonumber,
            ["costMP"] = tonumber,
            ["icon"] = checkFilePathValidate,
            ["costItem"] = parseItemWithOutCount
        }
        cfg = ConfigManager.loadCfg("skillEnhance.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getSkillCfg()
    local key = "Skill";
    local cfg = ConfigManager.configs[key]
    if cfg == nil then

        local attrMap = common:table_combineNumber( {
            "id", "values", "buff", "level", "cost", "times", 
            "cd", "firstCD", "HitEffectPath", "actionName", "skillType", "effectType", "tagType"
        } )
        local convertMap = {
            ["id"] = tonumber,
            ["level"] = tonumber,
            ["cost"] = tonumber,
            ["times"] = tonumber,
            ["cd"] = tonumber,
            ["firstCD"] = tonumber,
            ["skillType"] = tonumber,
            ["effectType"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("skill_New.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 战斗技能名字对应
function ConfigManager.getSkillNameCfg()
    local key = "SkillName";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        -- FightLogConfigId FightLogConfig.txt表中的id
        local attrMap = common:table_combineNumber( { "id", "skillName", "FightLogConfigId" });
        local convertMap = {
            ["id"] = tonumber,
            ["skillTime"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("skillName.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


-- 技能专精
function ConfigManager.getSkillOperCfg()
    local key = "SkillOrder";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "skillItemId", "profession" });
        local convertMap = {
            ["id"] = tonumber,
            ["skillItemId"] = tonumber,
            ["profession"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("SkillOrder.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 被动技能
function ConfigManager.getStaticSkillCfg()
    local key = "StaticSkill";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "profession", "name", "description", "tip", "icon", "baseAttr1", "addAttr1", "baseAttr2", "addAttr2", "mainPagedes" });
        local convertMap = {
            ["id"] = tonumber,
            ["profession"] = tonumber,
            ["baseAttr1"] = tonumber,
            ["addAttr1"] = tonumber,
            ["baseAttr2"] = tonumber,
            ["addAttr2"] = tonumber
        };
        cfg = ConfigManager.loadCfg("skillPassive.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 西施祝福
-- 奖励
function ConfigManager.getTresureRaiderRewardCfg()
    local key = "TreasureRaiderReward";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("TreasureRaiderReward.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

----新手扭蛋
----奖励
-- function ConfigManager.getNoviceGashaponRewardCfg()
-- local key = "NoviceGashaponReward";
-- local cfg = ConfigManager.configs[key];
-- if cfg == nil then
-- 	local attrMap = common:table_combineNumber({"id", "type", "needRewardValue"});
-- 	local convertMap = {
-- 		["id"] = tonumber,
-- 		["type"] = tonumber,
--            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,
-- 	};
-- 	cfg =  ConfigManager.loadCfg("NoviceGashaponReward.txt", attrMap, nil, convertMap);
-- 	ConfigManager.configs[key] = cfg;
-- end
-- return cfg;
-- end

function ConfigManager.getNewTresureRaiderRewardCfg()
    local key = "NewTreasureRaiderReward";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("NewTreasureRaiderReward.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


function ConfigManager.getNewTresureRaiderReward120Cfg()
    local key = "NewTreasureRaiderReward120";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("NewTreasureRaiderReward120.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end



-- 抽皮肤
function ConfigManager.getActSkinDrawCfg()
    local key = "getActSkinDrawCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "rewards", "scale", "offset" })
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["scale"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("newTreasureRaiderReward2.txt", attrMap, nil, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 星占师 抽皮肤
function ConfigManager.getAct135Cfg()
    local key = "getAct135Cfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "rewards", "scale", "offset" })
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["scale"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("newTreasureRaiderReward4.txt", attrMap, nil, convertMap)


        ConfigManager.configs[key] = cfg
    end
    return cfg
end


-- 139活动表
function ConfigManager.getAct139Cfg()
    local key = "getAct139Cfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "subType", "reward", "mustBeType", "roleNamePicPath", "helpTxt", "scale", "offset", "jumpId", "jumpText" })
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["subType"] = tonumber,
            ["reward"] = ConfigManager.parseItemOnlyWithUnderline,
            ["mustBeType"] = tonumber,
            ["jumpId"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("liveNiudan139.txt", attrMap, nil, convertMap)


        ConfigManager.configs[key] = cfg
    end
    return cfg
end


-- UR抽卡配置表
function ConfigManager.getReleaseURdrawMercenaryCfg()
    local key = "getReleaseURdrawMercenaryCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic", "scale", "offset", "randmoDrawMinCount", "maxDrawCount" });
        local convertMap = {
            ["itemId"] = tonumber,
            ["scale"] = tonumber,
            ["randmoDrawMinCount"] = tonumber,
            ["maxDrawCount"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawMercenary.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- UR抽卡奖励
function ConfigManager.getReleaseURdrawRewardCfg()
    local key = "getReleaseURdrawRewardCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawReward.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-------------------------------------------

-- UR抽卡配置表  121活动
function ConfigManager.getReleaseURdrawMercenary121Cfg()
    local key = "getReleaseURdrawMercenary121Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic", "scale", "offset", "randmoDrawMinCount", "maxDrawCount" });
        local convertMap = {
            ["itemId"] = tonumber,
            ["scale"] = tonumber,
            ["randmoDrawMinCount"] = tonumber,
            ["maxDrawCount"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawMercenary121.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- UR抽卡奖励   121活动
function ConfigManager.getReleaseURdrawReward121Cfg()
    local key = "getReleaseURdrawReward121Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawReward121.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


----------------------------------------

function ConfigManager.getAct132Cfg()
    local key = "getAct132Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "minLv", "BG", "Banner","Icon","title", "Text" ,"reward"});
        local convertMap = {
            ["id"] = tonumber,
            ["minLv"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma
        };
        cfg = ConfigManager.loadCfg("levelGiftAward132.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getAct151Cfg()
    local key = "getAct151Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "minStage", "maxStage", "reward", "price" });
        local convertMap = {
            ["id"] = tonumber,
            ["minStage"] = tonumber,
            ["maxStage"] = tonumber,
            ["price"] = tonumber,
            -- ["reward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("StageGiftAward151.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getAct177Cfg()
    local key = "getAct177Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id","reward","price" });
        local convertMap = {
            ["id"] = tonumber,
            ["price"] = tonumber,
            -- ["reward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("FailedGiftAward177.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

----------------------------------------

function ConfigManager.getAct134RewardCfg()
    local key = "getAct134RewardCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "day", "reward", "dayStrKey" });
        local convertMap = {
            ["id"] = tonumber,
            ["day"] = tonumber,
            -- ["reward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("weekendGiftReward134.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getAct134CostCfg()
    local key = "getAct134CostCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "count", "price" });
        local convertMap = {
            ["id"] = tonumber,
            ["count"] = tonumber,
            ["price"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("weekendGiftCost134.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


----------------------------------------


function ConfigManager.getAct124CostCfg()
    local key = "getAct124CostCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "count", "price" });
        local convertMap = {
            ["id"] = tonumber,
            ["count"] = tonumber,
            ["price"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("rechargeReturnLotteryCost124.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-----------------------------------------------------


function ConfigManager.getAct133Cfg()
    local key = "getAct133Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "reward" });
        local convertMap = {
            ["id"] = tonumber,
            -- ["reward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("OnlineAward133.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


---------------------------------------

-- UR抽卡配置表   116活动
function ConfigManager.getReleaseURdrawMercenary116Cfg()
    local key = "getReleaseURdrawMercenary116Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic", "scale", "offset", "randmoDrawMinCount", "maxDrawCount", "scorePoolReward" });
        local convertMap = {
            ["itemId"] = tonumber,
            ["scale"] = tonumber,
            ["randmoDrawMinCount"] = tonumber,
            ["maxDrawCount"] = tonumber,
            ["scorePoolReward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawMercenary116.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- UR抽卡奖励  116活动
function ConfigManager.getReleaseURdrawReward116Cfg()
    local key = "getReleaseURdrawReward116Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawReward116.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

----------------------------------------


function ConfigManager.getExpBuffShowCfg()
    local key = "ExpBuffShow";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "roleId", "stageLevel", "activityId", "expAdd", "icon", "des_1", "des_2" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["roleId"] = tonumber,
            ["stageLevel"] = tonumber,
            ["activityId"] = tonumber,
            ["expAdd"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("ExpBuffShow.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end



----------------------------------------
-- 128活动
function ConfigManager.getReleaseURdrawLotteryReward128Cfg()
    local key = "getReleaseURdrawLotteryReward128Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "reward" });
        local convertMap = {
            ["id"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("ReleaseURdrawLotteryReward128.txt", attrMap, nil, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


-- 128活动
function ConfigManager.getReleaseURdrawMercenary128Cfg()
    local key = "getReleaseURdrawMercenary128Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic", "scale", "offset", "randmoDrawMinCount", "maxDrawCount", "scorePoolReward"});
        local convertMap = {
            ["itemId"] = tonumber,
            --["scale"] = tonumber,
            ["randmoDrawMinCount"] = tonumber,
            ["maxDrawCount"] = tonumber,
            ["scorePoolReward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawMercenary128.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 128活动
function ConfigManager.getReleaseURdrawReward128Cfg()
    local key = "getReleaseURdrawReward128Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawReward128.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


----------------------------------------
-- 138活动
function ConfigManager.getReleaseURdrawLotteryReward138Cfg()
    local key = "getReleaseURdrawLotteryReward138Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "reward" });
        local convertMap = {
            ["id"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("ReleaseURdrawLotteryReward138.txt", attrMap, nil, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 138活动
function ConfigManager.getReleaseURdrawMercenary138Cfg()
    local key = "getReleaseURdrawMercenary138Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic", "scale", "offset", "randmoDrawMinCount", "maxDrawCount", "scorePoolReward" });
        local convertMap = {
            ["itemId"] = tonumber,
            ["scale"] = tonumber,
            ["randmoDrawMinCount"] = tonumber,
            ["maxDrawCount"] = tonumber,
            ["scorePoolReward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawMercenary138.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 138活动
function ConfigManager.getReleaseURdrawReward138Cfg()
    local key = "getReleaseURdrawReward1388Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawReward138.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

---------------------------------------------------------------------------


-- UR抽卡配置表   123活动
function ConfigManager.getReleaseURdrawMercenary123Cfg()
    local key = "getReleaseURdrawMercenary123Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "itemId", "pic", "scale", "offset", "randmoDrawMinCount", "maxDrawCount", "scorePoolReward" });
        local convertMap = {
            ["itemId"] = tonumber,
            ["scale"] = tonumber,
            ["randmoDrawMinCount"] = tonumber,
            ["maxDrawCount"] = tonumber,
            ["scorePoolReward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawMercenary123.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- UR抽卡奖励  123活动
function ConfigManager.getReleaseURdrawReward123Cfg()
    local key = "getReleaseURdrawReward123Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawReward123.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


-- 武器召唤师
function ConfigManager.getReleaseURdrawReward127Cfg()
    local key = "getReleaseURdrawReward127Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawReward127.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


--------------------------------------------------------------------------------------------------------

-- 活动排序
function ConfigManager.getActivitySortCfg()
    local key = "getActivitySortCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "order" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["order"] = tonumber,

        };
        cfg = ConfigManager.loadCfg("ActivitySort.txt", attrMap, nil, convertMap);

        local data = { }
        for k, v in pairs(cfg) do
            data[v.id] = v
        end
        cfg = data

        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

--------------------------------------------------------------------------------------------------------





function ConfigManager.getTresureRaiderRewardURCfg()
    local key = "NewTresureRaiderRewardURCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,

        };
        cfg = ConfigManager.loadCfg("NewLuckdrawReward.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getClimbingTowerBasicCfg()
    local key = "ClimbignTowerBasicCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "level", "award", "upParam", "downParam", "time", "number", "resetCost" });
        local convertMap = {
            ["id"] = tonumber,
            ["level"] = tonumber,
            ["award"] = ConfigManager.parseCfgWithComma,
            ["upParam"] = tonumber,
            ["downParam"] = tonumber,
            ["time"] = tonumber,
            ["number"] = tonumber,
            ["resetCost"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("pvepatabasic.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getClimbingTowerMapCfg()
    local key = "ClimbingTowerMap";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "param", "monsterIcon", "des", "firstDrop", "normalDrop", "monster" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["param"] = tonumber,
            ["firstDrop"] = ConfigManager.parseItemWithComma,
            ["normalDrop"] = ConfigManager.parseItemWithComma,
            ["monster"] = ConfigManager.parseCfgWithComma,
        };
        cfg = ConfigManager.loadCfg("pvepatacheckpoint.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getMultiEliteCfg()
    local key = "MultiEliteCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "difficulty", "powerLimit", "monsterId", "rewardIcon", "bgImg", "TitleName","bgFileName", "eventType", "reward", "freeTypeId", "quality", "leftReward","stageLimit"});
        local convertMap = {
            ["id"] = tonumber,
            ["difficulty"] = tonumber,
            ["powerLimit"] = tonumber,
            ["monsterId"] = tonumber,
            ["eventType"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma,
            ["freeTypeId"] = tonumber,
            ["quality"] = tonumber,
            ["leftReward"] = ConfigManager.parseItemWithComma,
            ["stageLimit"]=tonumber
        };
        cfg = ConfigManager.loadCfg("multiMap.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getMultiElite2Cfg()
    local key = "MultiElite2Cfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "difficulty", "powerLimit", "monsterId", "rewardIcon", "bgImg", "bgFileName", "DungeonType", "reward", "freeTypeId", "quality", "leftReward" ,"openedDay"});
        local convertMap = {
            ["id"] = tonumber,
            ["difficulty"] = tonumber,
            ["powerLimit"] = tonumber,
            ["monsterId"] = tonumber,
            ["DungeonType"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma,
            ["freeTypeId"] = tonumber,
            ["quality"] = tonumber,
            ["LimitLevel"] = tonumber,
            ["leftReward"] = ConfigManager.parseItemWithComma,

        };
        cfg = ConfigManager.loadCfg("dungeon.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 部落的嘉奖
function ConfigManager.getTribeAwardCfg()
    local key = "TribeAward"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "award", "luckyvalue", "score" })
        local convertMap = {
            ["id"] = tonumber,
            ["award"] = ConfigManager.parseItemWithComma,
            ["luckyvalue"] = tonumber,
            ["score"] = tonumber
        }
        cfg = ConfigManager.loadCfg("TribeAward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getSuitCfg()
    local key = "Suit";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local _table = TableReaderManager:getInstance():getTableReader("Suit.txt")
        local count = _table:getLineCount() -1
        cfg = { }
        for i = 1, count do
            local index = tonumber(_table:getData(i, 0))
            if cfg[index] == nil then
                cfg[index] = { }
                cfg[index].suitId = _table:getData(i, 0)
                cfg[index].suitName = Language:getInstance():getString(_table:getData(i, 1))
                cfg[index].equipIds = common:split(_table:getData(i, 2), ",")
                cfg[index].conditions = common:split(_table:getData(i, 3), ",")
                cfg[index].attrIds = { }
                for j = 1, 5, 1 do
                    if _table:getData(i, j + 3) ~= nil and _table:getData(i, j + 3) ~= "nil" then
                        table.insert(cfg[index].attrIds, tonumber(_table:getData(i, j + 3)))
                    end
                end
                cfg[index].maxNum = _table:getData(i, 9)
            end

        end
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getSuitAtrrCfg()
    local key = "SuitAtrrCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "upId", "bonuses", "describe" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["upId"] = tonumber,
            -- ConfigManager.parseCfgWithComma,
            ["bonuses"] = tonumber,ConfigManager.parseItemWithComma,
        };
        cfg = ConfigManager.loadCfg("SuitAttr.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getSkinCfg()
    local key = "SkinCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Item",  "Cost", "count","discount","HeroId","SkinId","isShow","Sort","SkinName", "Spine" });
        local convertMap = {
            ["id"] = tonumber,
            ["Item"] = ConfigManager.parseItemWithComma,
            ["Cost"]=ConfigManager.parseItemWithComma,
            ["count"] = tonumber,
            ["discount"] = tonumber,
            ["HeroId"] = tonumber,
            ["SkinId"] = tonumber,
            ["isShow"] = tonumber,
            ["Sort"] = tonumber,
            
        };
        cfg = ConfigManager.loadCfg("SkinShop.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getSuitShowCfg()
    local key = "SuitShowCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "suitId", "suitName", "suitType", "equipIds" });
        local convertMap = {
            ["suitId"] = tonumber,
            ["suitType"] = tonumber,
            ["equipIds"] = ConfigManager.parseCfgWithComma
        };
        cfg = ConfigManager.loadCfg("suitShow.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getRankGiftCfg()
    local key = "RankGiftCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "rank", "rewards" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["rewards"] = ConfigManager.parseItemWithComma
        };
        cfg = ConfigManager.loadCfg("rankGift.txt", attrMap, 0, convertMap);

        cfg.arena = { }
        cfg.level = { }
        for i = 1, #cfg do
            local oneItem = cfg[i]
            if oneItem.type == 1 then
                table.insert(cfg.arena, oneItem)
            elseif oneItem.type == 2 then
                table.insert(cfg.level, oneItem)
            end
        end

        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 成就系统 成就配置表
function ConfigManager.getAchievementCfg()
    --[[ local key = "AchievementCfg";
	local cfg = ConfigManager.configs[key];
	if cfg == nil then
		local attrMap = common:table_combineNumber({"id", "name","content","questType","achievementType","target","reward"});
		local convertMap = {
			["id"] = tonumber,
            ["questType"] = tonumber,
            ["achievementType"] = tonumber,
			["target"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma
		};
		cfg =  ConfigManager.loadCfg("quest.txt", attrMap, 0, convertMap);
		ConfigManager.configs[key] = cfg;
	end
	return cfg;]]
    --
end

-- 成就系统 跳转页面配置表
function ConfigManager.getAchievementSkipCfg()
    local key = "AchievementSkipCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "questTypeName", "pageName", "pageType", "LevelLimit" });
        local convertMap = {
            ["id"] = tonumber,
            ["pageType"] = tonumber,
            ["LevelLimit"] = tonumber
        };
        cfg = ConfigManager.loadCfg("AchievementSkip.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 成就系统 阶段奖励配置表
function ConfigManager.getAchievementStepRewardCfg()
    local key = "AchievementStepRewardCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "reward" });
        local convertMap = {
            ["id"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma
        };
        cfg = ConfigManager.loadCfg("questStep.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

--- 元素神符系统-元素品质对应的吞噬经验倍数
function ConfigManager.getElementLevelRatioCfg()
    local key = "ElementLevelRatioCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "quality", "multiple" });
        local convertMap = {
            ["quality"] = tonumber,
            ["multiple"] = tonumber
        }
        cfg = ConfigManager.loadCfg("elementLevelRatio.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 元素神符系统-元素各项属性信息
function ConfigManager.getLevelAttrRatioCfg()
    local key = "LevelAttrRatioCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "level",
            "iceAttack","fireAttack","thunderAttack",
            "iceDefense","fireDefense","thunderDefense",
            "iceAttackRadio","fireAttackRadio","thunderAttackRadio",
            "iceDefenseRadio","fireDefenseRadio","thunderDefenseRadio",
            "strenght","agility","intellect","stamina"
        } );
        local convertMap = {
            ["level"] = tonumber,
            ["iceAttack"] = tonumber,
            ["fireAttack"] = tonumber,
            ["thunderAttack"] = tonumber,
            ["iceDefense"] = tonumber,
            ["fireDefense"] = tonumber,
            ["thunderDefense"] = tonumber,
            ["iceAttackRadio"] = tonumber,
            ["fireAttackRadio"] = tonumber,
            ["thunderAttackRadio"] = tonumber,
            ["iceDefenseRadio"] = tonumber,
            ["fireDefenseRadio"] = tonumber,
            ["thunderDefenseRadio"] = tonumber,
            ["strenght"] = tonumber,
            ["agility"] = tonumber,
            ["intellect"] = tonumber,
            ["stamina"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("levelAttrRatio.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 元素神符系统-元素进阶经验表
function ConfigManager.getElementAscendCfg()
    local key = "ElementAscendCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "quality", "consume" });
        local convertMap = {
            ["quality"] = tonumber,
            ["consume"] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("elementAscend.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 元素神符系统-元素等级信息表
function ConfigManager.getElementLevelCfg()
    local key = "ElementLevelCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "level", "upgradeExp", "swallowExp", "swallowGold" });
        local convertMap = {
            ["level"] = tonumber,
            ["upgradeExp"] = tonumber,
            ["swallowExp"] = tonumber,
            ["swallowGold"] = tonumber
        }
        cfg = ConfigManager.loadCfg("elementLevel.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 元素神符系统-元素卡槽对应的等级
function ConfigManager.getElementSlotCfg()
    local key = "ElementSlotCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "openLv", "professionAttr" });
        local convertMap = {
            ["id"] = tonumber,
            ["openLv"] = tonumber,
            ["professionAttr"] = tonumber
        }
        cfg = ConfigManager.loadCfg("elementSlot.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 元素名称和icon表
function ConfigManager.getElementsCfg()
    local key = "ElementsCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "icon" });
        local convertMap = {
            ["id"] = tonumber
        }
        cfg = ConfigManager.loadCfg("elements.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 元素表
function ConfigManager.getElementCfg()
    local key = "ElementCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "quality", "name", "icon", "desc", "consume", "role" });
        local convertMap = {
            ["id"] = tonumber,
            ["quality"] = tonumber,
            ["consume"] = ConfigManager.parseItemWithComma,
            ["role"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("element.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getBuyCostCfg()
    local key = "ElementAndArenaCostCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "times", "fastFightTimes", "bossTimes", "arenaTimes", "eliteTimes", "multiEliteTimes" });
        local convertMap = {
            ["times"] = tonumber,
            ["fastFightTimes"] = tonumber,
            ["bossTimes"] = tonumber,
            ["arenaTimes"] = tonumber,
            ["eliteTimes"] = tonumber,
            ["multiEliteTimes"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("buyTimesPrice.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 天赋系统
function ConfigManager.getTalentCfg()
    local key = "TalentCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "id","stage","quality","level",
            "iceAttackCost","iceAttackCostTotal","iceAttackNum","iceAttackNumTotal",
            "iceDefenseCost","iceDefenseCostTotal","iceDefenseNum","iceDefenseNumTotal",
            "fireAttackCost","fireAttackCostTotal","fireAttackNum","fireAttackNumTotal",
            "fireDefenseCost","fireDefenseCostTotal","fireDefenseNum","fireDefenseNumTotal",
            "thunderAttackCost","thunderAttackCostTotal","thunderAttackNum","thunderAttackNumTotal",
            "thunderDefenseCost","thunderDefenseCostTotal","thunderDefenseNum","thunderDefenseNumTotal"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["stage"] = tonumber,
            ["quality"] = tonumber,
            ["level"] = tonumber,
            ["iceAttackCost"] = tonumber,
            ["iceAttackCostTotal"] = tonumber,
            ["iceAttackNum"] = tonumber,
            ["iceAttackNumTotal"] = tonumber,
            ["iceDefenseCost"] = tonumber,
            ["iceDefenseCostTotal"] = tonumber,
            ["iceDefenseNum"] = tonumber,
            ["iceDefenseNumTotal"] = tonumber,
            ["fireAttackCost"] = tonumber,
            ["fireAttackCostTotal"] = tonumber,
            ["fireAttackNum"] = tonumber,
            ["fireAttackNumTotal"] = tonumber,
            ["fireDefenseCost"] = tonumber,
            ["fireDefenseCostTotal"] = tonumber,
            ["fireDefenseNum"] = tonumber,
            ["fireDefenseNumTotal"] = tonumber,
            ["thunderAttackCost"] = tonumber,
            ["thunderAttackCostTotal"] = tonumber,
            ["thunderAttackNum"] = tonumber,
            ["thunderAttackNumTotal"] = tonumber,
            ["thunderDefenseCost"] = tonumber,
            ["thunderDefenseCostTotal"] = tonumber,
            ["thunderDefenseNum"] = tonumber,
            ["thunderDefenseNumTotal"] = tonumber
        }
        cfg = ConfigManager.loadCfg("talent.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.changeFightLogConfig()
    local userInfo = require("PlayerInfo.UserInfo")
    local GameConfig = require("GameConfig")
    local strFontSize = ""
    --[[海外不用这个方法
    if userInfo.stateInfo.fontSize == 0 then
        strFontSize = "32"
    elseif userInfo.stateInfo.fontSize == GameConfig.BattleTextSizeConfig.Min then
        strFontSize = "20"
    elseif userInfo.stateInfo.fontSize == GameConfig.BattleTextSizeConfig.Middle then
        strFontSize = "32"
    elseif userInfo.stateInfo.fontSize == GameConfig.BattleTextSizeConfig.Max then
        strFontSize = "40"
    end]]
    if FightLogConfig ~= nil then FightLogConfig = { } end
    if FightLogConfig == nil or table.maxn(FightLogConfig) <= 0 then
        local tabel = TableReaderManager:getInstance():getTableReader("FightLogConfig" .. strFontSize .. ".txt")
        local count = tabel:getLineCount() -1;
        for i = 1, count do
            local index = tabel:getData(i, 0)
            if FightLogConfig[index] == nil then
                FightLogConfig[index] = { }
                FightLogConfig[index].id = tabel:getData(i, 0)
                FightLogConfig[index].content = tabel:getData(i, 1)
            end
        end
    end
    if FreeTypeConfig ~= nil then FreeTypeConfig = { } end
    local tabel = TableReaderManager:getInstance():getTableReader("FreeTypeFont" .. strFontSize .. ".txt")
    local count = tabel:getLineCount() -1;
    for i = 1, count do
        local index = tonumber(tabel:getData(i, 0))
        if FreeTypeConfig[index] == nil then
            FreeTypeConfig[index] = { }
            FreeTypeConfig[index].id = tonumber(tabel:getData(i, 0))
            FreeTypeConfig[index].content = tabel:getData(i, 1)
        end
    end
end
-- 广播中翅膀要变颜色，加了NormalHtmlLabel.txt
function ConfigManager.getNormalHtmlCfg()
    local key = "NormalHtmlCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        cfg = { }
        local attrMap = common:table_combineNumber( { "id", "content" });
        local convertMap = {
            ["id"] = tonumber,
        }
        local htmlTable = TableReaderManager:getInstance():getTableReader("NormalHtmlLabel.txt")
        local count = htmlTable:getLineCount() -1;
        for i = 1, count do
            local index = tonumber(htmlTable:getData(i, 0))
            cfg[index] = { }
            cfg[index].id = tonumber(htmlTable:getData(i, 0))
            cfg[index].content = htmlTable:getData(i, 1)
        end
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 转生前后属性表
function ConfigManager.getRebornAttrCfg()
    local key = "RebornAttrCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            "id","level","profession","powerBefore","agilityBefore","intelligenceBefore","staminaBefore",
            "powerAfter","agilityAfter","intelligenceAfter","staminaAfter"
        } );
        local convertMap = {
            ["id"] = tonumber,
            ["level"] = tonumber,
            ["profession"] = tonumber,
            ["powerBefore"] = tonumber,
            ["agilityBefore"] = tonumber,
            ["intelligenceBefore"] = tonumber,
            ["staminaBefore"] = tonumber,
            ["powerAfter"] = tonumber,
            ["agilityAfter"] = tonumber,
            ["intelligenceAfter"] = tonumber,
            ["staminaAfter"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("rebirthOneProfLevelAttr.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function parseWingAttrCount(rewards)
    local result = { }
    if rewards ~= nil then
        for _, item in ipairs(common:split(rewards, ",")) do
            local _type, _id = unpack(common:split(item, "_"));
            if _type ~= nil and _id ~= nil then
                table.insert(result, {
                    type = tonumber(_type),
                    count = tonumber(_id)
                } )
            end
        end
    end
    return result
end

function ConfigManager.getWingAttrCfg()
    local key = "WingAttrCfg"
    local cfg = ConfigManager.configs[key]
    if not cfg then
        local attrMap = common:table_combineNumber( { "id", "level", "occupation", "updateCost", "attrs" });
        local convertMap = {
            ["id"] = tonumber,
            ["level"] = tonumber,
            ["occupation"] = tonumber,
            ["updateCost"] = ConfigManager.parseItemWithComma,
            ["attrs"] = parseWingAttrCount
        }
        local tempTable = ConfigManager.loadCfg("wings.txt", attrMap, 0, convertMap)
        cfg = { }
        for key, data in pairs(tempTable) do
            if not cfg[data.occupation] then
                cfg[data.occupation] = { }
            end

            local temp = { }
            temp["updateCost"] = data["updateCost"]
            temp["attrs"] = data["attrs"]
            cfg[data.occupation][data.level] = temp
        end
        ConfigManager.configs[key] = cfg;
    end
    return cfg
end

function ConfigManager.getRoleIconCfg()
    local key = "RoleIconCfg"
    local cfg = ConfigManager.configs[key]
    if not cfg then
        local attrMap = common:table_combineNumber( { "id", "quality", "profession", "type", "price", "chatIcon", "MainPageIcon", "isShow", "isSkin", "order" });
        local convertMap = {
            ["id"] = tonumber,
            ["quality"] = tonumber,
            ["profession"] = tonumber,
            ["type"] = tonumber,
            ["price"] = tonumber,
            ["isShow"] = tonumber,
            ["isSkin"] = tonumber,
            ["order"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("roleHead.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg
end

function ConfigManager.getNewbieGuideCfg()
    local key = "NewbieGuideCfg"
    local cfg = ConfigManager.configs[key]
    if not cfg then
        local attrMap = common:table_combineNumber( { "step", "nextStep", "guideType", "interruptStep", "showType", "str", "func", "pageName", "ownerVar", 
                                                      "showName", "funcParam", "selectEffect", "leftNpc", "autoNext", "stopBattle", "openMask", "touchCheck",
                                                      "waitOpcode", "voice" });
        local convertMap = {
            ["step"] = tonumber,
            ["nextStep"] = tonumber,
            ["guideType"] = tonumber,
            ["interruptStep"] = tonumber,
            ["showType"] = tonumber,
            ["autoNext"] = tonumber,
            ["stopBattle"] = tonumber,
            ["openMask"] = tonumber,
            ["waitOpcode"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("NewbieGuide.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg
end
-- google成就对应数据表
function ConfigManager.getGoogleTaskCfg()
    local key = "GoogleTaskCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "stage", "gid" });
        local convertMap = {
            ["id"] = tonumber,
            ["stage"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("GoogleTask.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 超级兑换表
function ConfigManager.getExchangeActivityItem()
    local key = "ExchangeActivity";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "consumeInfo", "awardInfo", "maxExchangeTime", "roleId", "sortId" });
        local convertMap = {
            ["id"] = tonumber,
            ["maxExchangeTime"] = tonumber,
            ["roleId"] = tonumber,
            ["sortId"] = tonumber
        };
        cfg = ConfigManager.loadCfg("ExchangeActivity.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getExchangeActivityItem_136()
    local key = "ExchangeActivity_136";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "consumeInfo", "awardInfo", "maxExchangeTime", "roleId", "sortId" });
        local convertMap = {
            ["id"] = tonumber,
            ["maxExchangeTime"] = tonumber,
            ["roleId"] = tonumber,
            ["sortId"] = tonumber
        };
        cfg = ConfigManager.loadCfg("ExchangeActivity136.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getExchangeActivityItem_142()
    local key = "ExchangeActivity_142";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "consumeInfo", "awardInfo", "maxExchangeTime", "roleId", "sortId" });
        local convertMap = {
            ["id"] = tonumber,
            ["maxExchangeTime"] = tonumber,
            ["roleId"] = tonumber,
            ["sortId"] = tonumber
        };
        cfg = ConfigManager.loadCfg("ExchangeActivity142.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 佣兵远征数据表
function ConfigManager.getMercenaryExpeditionCfg()
    local key = "MercenaryExpedition";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "level", "pic", "name", "Starlimit","Classlimit", "Elementlimit","reward", "taskTime" });
        local convertMap = {
            ["id"] = tonumber,
            ["level"] = tonumber,
            ["Starlimit"] = tonumber,
            ["Classlimit"] = tonumber,
            ["Elementlimit"] = tonumber,
            ["reward"]=ConfigManager.parseItemWithComma,
            ["taskTime"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("MercenaryExpedition.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 每日任务配置表
function ConfigManager.getDailyQuestCfg()
    local key = "DailyQuest";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "type", "targetCount", "point", "des", "icon", "sortId", "isJump", "jumpValue", "showType", "quality" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["targetCount"] = tonumber,
            ["content"] = tostring,
            ["des"] = tostring,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("DailyQuest.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 每日任务活跃度奖励配置
function ConfigManager.getDailyQuestPointCfg()
    local key = "dailyQuestPoint";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "point", "award", "maxPoint", "nodeName" });
        local convertMap = {
            ["id"] = tonumber,
            ["point"] = tonumber,
            ["maxPoint"] = tonumber,
            ["award"] = ConfigManager.parseItemWithComma,
        };
        cfg = ConfigManager.loadCfg("dailyQuestPoint.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 每周任务配置表
function ConfigManager.getWeeklyQuestCfg()
    local key = "getWeeklyQuest";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "type", "targetCount", "point", "des", "icon", "sortId", "isJump", "jumpValue", "showType", "quality" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["targetCount"] = tonumber,
            ["content"] = tostring,
            ["des"] = tostring,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("weeklyQuest.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 每周任务活跃度奖励配置
function ConfigManager.getWeeklyQuestPointCfg()
    local key = "weeklyQuestPoint";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "point", "award", "maxPoint", "nodeName" });
        local convertMap = {
            ["id"] = tonumber,
            ["point"] = tonumber,
            ["maxPoint"] = tonumber,
            ["award"] = ConfigManager.parseItemWithComma,
        };
        cfg = ConfigManager.loadCfg("weeklyQuestPoint.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getQuestCfg()
    local key = "quest";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "questType", "team", "targetCount", "sortId", "des", "icon", "isJump", "jumpValue", "showType", "quality", "targetType" });
        local convertMap = {
            ["id"] = tonumber,
            ["questType"] = tonumber,
            ["team"] = tonumber,
            ["targetCount"] = tonumber,
            ["sortId"] = tonumber,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
            ["targetType"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("quest.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 鬼节捞鱼数据表
function ConfigManager.getCatchFishCfg()
    local key = "goldfishCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'title', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['title'] = tostring,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("goldfish.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg;
end
function ConfigManager.getCatchFishRankRewardsCfg()
    local key = "goldfishReward";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "rankText", "rewards" });
        local convertMap = {
            ["id"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("goldfishReward.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getGodEquipBuildCfg()
    local key = "GodEquipBuild";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "itemId" });
        local convertMap = {
            ["id"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("forgingPool.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
--- 套装图鉴配置
function ConfigManager.getSuitHandBookCfg()
    local key = "SuitHandBook";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "suitQuality", "profession", "equipId", "level", "isMercenaryEquip" });
        local convertMap = {
            ["id"] = tonumber,
            ["suitQuality"] = tonumber,
            -- 套装品质
            ["profession"] = tonumber,
            -- 职业
            ["equipId"] = tonumber,
            -- 套装id
            ["level"] = tonumber,
            -- 套装等级
            ["isMercenaryEquip"] = tonumber,-- 是否是佣兵专属装备
        };
        cfg = ConfigManager.loadCfg("SuitHandBook.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
--- 套装图鉴配置
function ConfigManager.getGodEquipPreviewCfg()
    local key = "GodEquipPreview";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "items" });
        local convertMap = {
            ["id"] = tonumber
        };
        cfg = ConfigManager.loadCfg("forgingPoolShow.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


--- 30天签到奖励
function ConfigManager.getDayLogin30Data()
    local key = "DayLogin30";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "month", "day", "items" });
        local convertMap = {
            ["id"] = tonumber,
            ["month"] = tonumber,
            ["day"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("DayLogin30.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getFreeSummonData()
    local key = "FreeSummon";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Rewards" });
        local convertMap = {
            ["id"] = tonumber,
            ["Rewards"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("FreeSummon167.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getFreeSummonData2()
    local key = "FreeSummon2";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Rewards" });
        local convertMap = {
            ["id"] = tonumber,
            ["Rewards"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("FreeSummon180.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getFreeSummonData3()
    local key = "FreeSummon3";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id","type","needCount", "Rewards" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needCount"] = tonumber,
            ["Rewards"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("StepSummon190.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getAlbumData()
    local key = "AlbumData";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "itemId","Score","FileName","StroyId","reward","CostReward"});
        local convertMap = {
            ["id"] = tonumber,
            ["itemId"] = tonumber,
            ["Score"] = tonumber,
            ["reward"]=ConfigManager.parseItemWithComma,
            ["CostReward"]=ConfigManager.parseItemWithComma
        };
        cfg = ConfigManager.loadCfg("SecretAlbum.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getStoryData()
    local key = "StoryData";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Spine","anime","stage","type","BGM","EFF","txtCount","Game","TypeTimes","sort","isHide"});
        local convertMap = {
            ["id"] = tonumber,
            ["stage"]=tonumber,
            ["txtCount"]=tonumber,
            ["TypeTimes"]=tonumber,
            ["sort"]=tonumber,
            ["isHide"]=tonumber,
        };
        cfg = ConfigManager.loadCfg("fetterGirlControl.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getStoryData_Vertical()
    local key = "StoryData_Vertical";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Spine","anime","stage","type","BGM","Voice","EFF","txtCount"});
        local convertMap = {
            ["id"] = tonumber,
            ["stage"]=tonumber,
            ["type"]=tonumber,
            ["txtCount"]=tonumber
        };
        cfg = ConfigManager.loadCfg("fetterAlbumControl.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getStoryData_Vertical_StorySpine()
    local key = "StoryData_Vertical_StorySpine";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "Spine","anime","stage","type","BGM","Voice","EFF","txtCount"});
        local convertMap = {
            ["id"] = tonumber,
            ["stage"]=tonumber,
            ["type"]=tonumber,
            ["txtCount"]=tonumber
        };
        cfg = ConfigManager.loadCfg("fetterBdsmSpineControl.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
--- 30天签到奖励 --B
function ConfigManager.getDayLogin30BData()
    local key = "DayLogin30B";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "items" });
        local convertMap = {
            ["id"] = tonumber
        };
        cfg = ConfigManager.loadCfg("DayLogin30B.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.SupportCalender30()
    local key = "SupportCalender30";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id","type", "month", "day", "items" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["month"] = tonumber,
            ["day"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("SupportCalender30.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

--- 活跃度奖励
function ConfigManager.getActDailyPointRewardCfg()
    local key = "ActDailyPointRewardCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "items" });
        local convertMap = {
            ["id"] = tonumber
        };
        cfg = ConfigManager.loadCfg("ActDailyPointReward.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


--- 7日之诗
function ConfigManager.getSevenDayQuestData()
    local key = "SevenDayQuest";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "day", "tagNum", "tagName", "task", "taskTarget", "reward", "type", "price", "jumpId" })
        local convertMap = {
            ["id"] = tonumber,
            ["day"] = tonumber,
            ["tagNum"] = tonumber,
            ["taskTarget"] = tonumber,
            ["type"] = tonumber,
            ["jumpId"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("activitySevenDayTask.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 制服卖场
function ConfigManager.getShootEquipPreviewCfg()
    local key = "ShootEquipPreview"
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "items", "group", "stage", "tenMust" });
        local convertMap = {
            ["id"] = tonumber,
            ["group"] = tonumber,
            ["stage"] = tonumber,
            ["tenMust"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("shootPoolShow.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 酒馆活动  125
function ConfigManager.getShootPoolShow125Cfg()
    local key = "ShootPoolShow125Cfg"
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "items", "group", "stage", "tenMust" });
        local convertMap = {
            ["id"] = tonumber,
            ["group"] = tonumber,
            ["stage"] = tonumber,
            ["tenMust"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("shootPoolShow125.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end


-- “雪地迷踪”活动，奖励预览
function ConfigManager.getNewSnowTreasureCfg()
    local key = "NewSnowTreasureCfg"
    local cfg = ConfigManager.configs[key]
    if not cfg then
        local attrMap = common:table_combineNumber( { "id", "type", "needRewardValue" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["needRewardValue"] = ConfigManager.parseItemOnlyWithUnderline,
        }
        cfg = ConfigManager.loadCfg("princeDevilsPreview.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg
end

-- “雪地迷踪”活动，奖励预览
function ConfigManager.getNewSnowRankRewardCfg()
    local key = "SnowRankRewardCfg"
    local cfg = ConfigManager.configs[key]
    if not cfg then
        local attrMap = common:table_combineNumber( { "id", "rank", "reward" });
        local convertMap = {
            ["reward"] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("NewSnowRewardRank.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg;
    end
    return cfg
end

-- 首页图标显示配置
function ConfigManager.getMainSceneIconCfg()
    local key = "MainSceneIcon"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "row", "colum", "eventId", "describe", "priority", "icon", "jumpParam" })
        local convertMap = {
            ["id"] = tonumber,
            ["row"] = tonumber,
            ["colum"] = tonumber,
            ["eventId"] = tonumber,
            ["priority"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("mainSceneIcon.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 成长基金
function ConfigManager.getGrowthFundCfg()
    local key = "GrowthFundCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'level', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['level'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("growthfund.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getGrowthLvCfg()
    local key = "GrowthLvCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'level', 'FreeRewards','CostRewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['level'] = tonumber,
            ['FreeRewards'] = ConfigManager.parseItemWithComma,
            ['CostRewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("GrowthLV100.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getGrowthChCfg()
    local key = "GrowthChCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'level', 'FreeRewards','CostRewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['level'] = tonumber,
            ['FreeRewards'] = ConfigManager.parseItemWithComma,
            ['CostRewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("GrowthCH101.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getGrowthTwCfg()
    local key = "GrowthTwCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'level', 'FreeRewards','CostRewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['level'] = tonumber,
            ['FreeRewards'] = ConfigManager.parseItemWithComma,
            ['CostRewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("GrowthTW102.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 限定活动119      消費還元 
function ConfigManager.getaccConsumeItemRewardCfg()
    local key = "getaccConsumeItemRewardCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'count', 'rewards', 'des' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['count'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("accConsumeItemReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 限定活动118    
function ConfigManager.getcontinueRechargeMoneyCfg()
    local key = "getcontinueRechargeMoneyCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'des', 'count', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['count'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("continueRechargeMoney.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


--- 累计消费活动
function ConfigManager.getExpendAddUpCfg()
    local key = "ExpendAddUpCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'cost', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['cost'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadHalfCfg("accConsume.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 聖所系統
function ConfigManager.getHolyGrailCfg()
    local key = "HolyGrailCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'starType', 'level', 'costItems', 'attrs' })
        local convertMap = {
            ['id'] = tonumber,
            ['starType'] = tonumber,
            ['level'] = tonumber,
            ['costItems'] = ConfigManager.parseItemWithComma,
            ['attrs'] = function(attrStr)
                return common:split(attrStr, ",");
            end
        }
        cfg = ConfigManager.loadCfg("HolyGrail.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end 

-- 星魂系统
function ConfigManager.getStarSoulCfg()
    local key = "StarSoulCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'starType', 'level', 'costItems', 'attrs' })
        local convertMap = {
            ['id'] = tonumber,
            ['starType'] = tonumber,
            ['level'] = tonumber,
            ['costItems'] = ConfigManager.parseItemWithComma,
            ['attrs'] = function(attrStr)
                return common:split(attrStr, ",");
            end
        }
        cfg = ConfigManager.loadCfg("starSoul.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end 
function ConfigManager.getLeaderSoulCfg()
    local key = "LeaderSoulCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'level', 'costItems', 'attrs' })
        local convertMap = {
            ['id'] = tonumber,
            ['level'] = tonumber,
            ['costItems'] = ConfigManager.parseItemWithComma,
            ['attrs'] = function(attrStr)
                return common:split(attrStr, ",");
            end
        }
        cfg = ConfigManager.loadCfg("LeaderSoul.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end 
function ConfigManager.getElementSoulCfg()
    local key = "ElementSoulCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'level', 'costItems', 'attrs' })
        local convertMap = {
            ['id'] = tonumber,
            ['level'] = tonumber,
            ['costItems'] = ConfigManager.parseItemWithComma,
            ['attrs'] = function(attrStr)
                return common:split(attrStr, ",");
            end
        }
        cfg = ConfigManager.loadCfg("ElementSoul.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end 
function ConfigManager.getClassSoulCfg()
    local key = "ClassSoulCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'level', 'costItems', 'attrs' })
        local convertMap = {
            ['id'] = tonumber,
            ['level'] = tonumber,
            ['costItems'] = ConfigManager.parseItemWithComma,
            ['attrs'] = function(attrStr)
                return common:split(attrStr, ",");
            end
        }
        cfg = ConfigManager.loadCfg("ClassSoul.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end 

-- 星魂系统
function ConfigManager.getKingPowerCfg()
    local key = "KingPower"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'name', 'desc', 'onceGold', 'tenGold', 'items', 'LuckDesc', "maxTimes", "spineId", "pic", "spineScale", "offset" })
        local convertMap = {
            ['id'] = tonumber,
            ['onceGold'] = tonumber,
            ['tenGold'] = tonumber,
            ['items'] = ConfigManager.parseItemOnlyWithUnderline,
            ['maxTimes'] = tonumber,
            ['spineId'] = tonumber,
            ['pic'] = tostring,
            ['spineScale'] = tostring,
        }
        cfg = ConfigManager.loadCfg("Harem.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end 

-- 星魂系统
function ConfigManager.getKingPowerRewardCfg()
    local key = "KingPowerReward"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'reward', 'tenMust' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['reward'] = ConfigManager.parseItemOnlyWithUnderline,
            ['tenMust'] = tonumber
        }
        local temp = ConfigManager.loadCfg("HaremReward.txt", attrMap, nil, convertMap)
        cfg = { }
        for i, v in ipairs(temp) do
            cfg[v.type] = cfg[v.type] or { }
            local t = { rewardData = v.reward, tenMust = v.tenMust }
            table.insert(cfg[v.type], t)
            -- table.insert(cfg[v.type], v.reward)
        end
        ConfigManager.configs[key] = cfg
    end
    return cfg
end 

-- 聊天框皮肤
function ConfigManager.getChatSkinCfg()
    local key = "ChatSkinCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'skinId', "skinName", "skinRes", "textColor" })
        local convertMap = {
            ['id'] = tonumber,
            ['skinId'] = tonumber,
            ['textColor'] = function(attrStr)
                return attrStr:gsub(",", " ")
            end
        }
        cfg = ConfigManager.loadCfg("chatSkin.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- GVG城市配置
function ConfigManager.getGVGCfg()
    local key = "GVGCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', "posId", 'level', "cityName", "cityPos", "cityImg", "boxImg", "cityTax", "boxName", "chains", "obtainScore" })
        local convertMap = {
            ['id'] = tonumber,
            ['posId'] = tonumber,
            ['level'] = tonumber,
            ['cityName'] = function(key)
                return common:getLanguageString(key)
            end,
            ["cityTax"] = ConfigManager.getRewardByString,
            ["boxName"] = function(key)
                return common:getLanguageString(key)
            end,
            ['chains'] = function(str)
                return common:split(str, ",")
            end,
            ['obtainScore'] = tonumber
        }
        cfg = ConfigManager.loadCfg("GVGCityMap.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 获取当前FreeType
function ConfigManager.getFreeTypeCfg(id)
    if FreeTypeConfig and FreeTypeConfig[id] then
        return FreeTypeConfig[id]
    end
    return { id = id, content = "" }
end

-- 限时活动，碎片兑换万能道具
function ConfigManager.getFragmentExchangeCfg()
    local key = "getFragmentExchangeInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'costFragment', 'costItem', 'rewardFragement' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['costFragment'] = ConfigManager.parseItemWithComma,
            ['costItem'] = ConfigManager.parseItemWithComma,
            ['rewardFragement'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("fragmentExchange.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 限时活动，鲜花兑换
function ConfigManager.getFairyBlessCfg()
    local key = "getFairyBlessInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'rewards', 'weight', 'costFlower', 'totalProgress' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
            ['weight'] = ConfigManager.parseItemWithComma,
            ['costFlower'] = tonumber,
            ['totalProgress'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fairyBless.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 限时活动，美女信物
function ConfigManager.getMaidenEncountCfg()
    local key = "getMaidenEncountInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'consumeItems', 'consumeGold', 'refreshConsumeGold', 'freeRefreshTimes', 'freeCount', 'exclusiveReward', 'spineId', 'describe' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['consumeItems'] = ConfigManager.parseItemWithComma,
            ['consumeGold'] = tonumber,
            ['refreshConsumeGold'] = tonumber,
            ['freeRefreshTimes'] = tonumber,
            ['freeCount'] = tonumber,
            ['exclusiveReward'] = ConfigManager.parseItemWithComma,
            ['spineId'] = tonumber,
            ['describe'] = tostring,
        }
        cfg = ConfigManager.loadCfg("MaidenEncounter.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 限时活动，美女信物，奖励兑换
function ConfigManager.getMaidenEncountExchangeCfg()
    local key = "getMaidenEncountExchangeInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'consumeItems', 'getItems', 'times' })
        local convertMap = {
            ['id'] = tonumber,
            ['consumeItems'] = ConfigManager.parseItemWithComma,
            ['getItems'] = ConfigManager.parseItemWithComma,
            ['times'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("MaidenEncounterExchange.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 限时活动，美女信物，进度阶段
function ConfigManager.getMaidenEncountStageCfg()
    local key = "getMaidenEncountStageInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'stage', 'totalProgress' })
        local convertMap = {
            ['id'] = tonumber,
            ['stage'] = tonumber,
            ['totalProgress'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("MaidenEncounterStage.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 限时活动，美女信物，奖励展示
function ConfigManager.getMaidenEncounterRewardCfg()
    local key = "getMaidenEncounterRewardInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'title', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['title'] = tostring,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("MaidenEncounterReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 图鉴配置
function ConfigManager.getIllustrationCfg()
    local key = "IllustrationCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', '_type', 'order', 'roleId', 'soulNumber', 'name', 'story', "isOpen", "isSkin" })
        local convertMap = {
            ['id'] = tonumber,
            ['_type'] = tonumber,
            ['order'] = tonumber,
            ['roleId'] = tonumber,
            ['soulNumber'] = tonumber,
            ['isOpen'] = tonumber,
            ['isSkin'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("archive.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg

        --        local t = { }
        --        local index = 1
        --        for k, v in pairs(cfg) do
        --            if v.isOpen == 1 then
        --                table.insert(t,index, v)
        --                index = index + 1
        --            end
        --        end
        --        ConfigManager.configs[key] = t
        --        cfg = ConfigManager.configs[key]
    end
    return cfg
end

--- GVEBuff
function ConfigManager.getGVEBuffCfg()
    local key = "GVEBuffCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'name', 'desc', 'star', 'price', 'icon', 'messageIcon' })
        local convertMap = {
            ['id'] = tonumber,
            ['star'] = tonumber,
            ['price'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("GVEBuff.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


---------------------------------------------------------
function RelationshipAttrFunc(str)
    local arr = common:split(str or "", ",")
    local data = { }
    for i, v in ipairs(arr) do
        local temp = common:split(v, "_")
        assert(#temp == 2)
        data[i] = { type = tonumber(temp[1]), value = tonumber(temp[2]) }
    end
    return data
end


-- 缘分
function ConfigManager.getRelationshipCombinationCfg()
    local key = "getRelationshipCombinationCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'targetRoleId', 'relationshipRoleId', 'attr'})
        local convertMap = {
            ['id'] = tonumber,
            ['targetRoleId'] = tonumber,
            ['relationshipRoleId'] = ConfigManager.parseCfgWithComma,
            ['attr'] = RelationshipAttrFunc,
        }
        cfg = ConfigManager.loadCfg("luckByMercenaryGroup.txt", attrMap, 0, convertMap)
        for k , v in pairs(cfg) do
            for i = 1 , #v.relationshipRoleId  do
                v.relationshipRoleId[i] = tonumber(v.relationshipRoleId[i])
            end
        end
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-------------------------------------------------------------

--- 奥义配置
function ConfigManager.getRelationshipCfg()
    local key = "RelationshipCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'order', 'name', 'team', 'reward', 'property', 'formula', "star" })
        local convertMap = {
            ['id'] = tonumber,
            ['order'] = tonumber,
            ['team'] = function(val)
                local arr = common:split(val, ",")
                table.foreach(arr, function(i, v)
                    arr[i] = tonumber(v)
                end )
                return arr
            end,
            ['property'] = function(val)
                return common:split(val, ",")
            end,
            ['reward'] = ConfigManager.parseItemWithComma,
            ['star'] = tonumber
        }
        cfg = ConfigManager.loadCfg("fetter.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 少女日記設定
function ConfigManager.getFetterBDSMControlCfg()
    local key = "FetterControlBDSM"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'role', 'bg','startMovementId', "endMovementId", 'bgm', 'eff', "AutoWait" })
        local convertMap = {
            ['id'] = tonumber,
            ['role'] = tonumber,
            ['startMovementId'] = tonumber,
            ['endMovementId'] = tonumber,
            ['AutoWait'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fetterBDSMControl.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 少女日記演出
function ConfigManager.getFetterBDSMActionCfg()
    local key = "FetterBDSMAction"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'actionType', 'spine', 'define','position','wait', 'transform', 'rotate', 'scale', 'time', 'parent', 'spawnId' })
        local convertMap = {
            ['id'] = tonumber,
            ['actionType'] = tonumber,
            ['define'] = tonumber,
            ['wait'] = tonumber,
            ['rotate'] = tonumber,
            --['scale'] = tonumber,
            ['time'] = tonumber,
            ['parent'] = tonumber,
            ['spawnId'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fetterBDSMMovement.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
--- Album日記設定
function ConfigManager.getSecertControlCfg()
    local key = "SecertControl"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'role', 'bg','startMovementId', "endMovementId", 'bgm', 'eff', "voiceWait" })
        local convertMap = {
            ['id'] = tonumber,
            ['role'] = tonumber,
            ['startMovementId'] = tonumber,
            ['endMovementId'] = tonumber,
            ['voiceWait'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fetterSAControl.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- Album日記演出
function ConfigManager.getSecertActionCfg()
    local key = "SecertAction"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'actionType', 'spine', 'define','position','wait', 'transform', 'rotate', 'scale', 'time', 'parent', 'spawnId' })
        local convertMap = {
            ['id'] = tonumber,
            ['actionType'] = tonumber,
            ['define'] = tonumber,
            ['wait'] = tonumber,
            ['rotate'] = tonumber,
            --['scale'] = tonumber,
            ['time'] = tonumber,
            ['parent'] = tonumber,
            ['spawnId'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fetterSAMovement.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 缘分奖励预览配置
function ConfigManager.getRelationshipRewardCfg()
    local key = "RelationshipRewardCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'roleNum', 'showName', 'rewards' })
        local convertMap = {
            ['roleNum'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("fetterAward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


function ConfigManager.getGVGMatchRewardCfg()
    local key = "GVGMatchRewardCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'date', 'rank', 'num', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['rank'] = tonumber,
            ['num'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("GVGMatchReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getGVGEveryDayRewardCfg()
    local key = "GVGEveryDayRewardCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'date', 'rank', 'num', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['rank'] = tonumber,
            ['num'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("GVGEveryDayReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 鬼节活动，主页信息
function ConfigManager.getObonConfigCfg()
    local key = "getObonConfigCfgInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'name' })
        local convertMap = {
            ['id'] = tonumber,
            ['name'] = tostring,
        }
        cfg = ConfigManager.loadCfg("ObonConfig.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 鬼节活动，主页阶段信息
function ConfigManager.getObonStageInfoCfg()
    local key = "getObonStageInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'stage', 'probability', 'progress', 'name' })
        local convertMap = {
            ['id'] = tonumber,
            ['stage'] = tonumber,
            ['probability'] = tonumber,
            ['progress'] = tonumber,
            ['name'] = tostring,
        }
        cfg = ConfigManager.loadCfg("ObonStage.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 鬼节活动， 灯笼 奖励展示
function ConfigManager.getObonRewardCfg()
    local key = "getObonRewardInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("ObonReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 鬼节活动， 阶段获得 奖励展示
function ConfigManager.getObonStageRewardCfg()
    local key = "getObonStageRewardInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'stage', 'describe', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['stage'] = tonumber,
            ['describe'] = tostring,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("ObonStageReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 跨服PVP段位配置
function ConfigManager.getOSPVPStageCfg()
    local key = "OSPVPStageCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'stageName', 'stageIcon', 'score', 'rank', 'stageImg' })
        local convertMap = {
            ['id'] = tonumber,
            ['score'] = tonumber,
            ['rank'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("csPVP.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 跨服PVP排名奖励配置
function ConfigManager.getOSPVPRankRewardCfg()
    local key = "OSPVPRankRewardCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'minRank', 'awards' })
        local convertMap = {
            ['id'] = tonumber,
            ['minRank'] = tonumber,
            ['awards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("csPVPRankReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 跨服PVP分服配置
function ConfigManager.getOSPVPServerCfg()
    local key = "OSPVPServerCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'servers' })
        local convertMap = {
            ['id'] = tonumber,
            ['servers'] = function(attr)
                local servers = common:split(attr, ",")
                common:table_map(servers, tonumber)
                return servers
            end
        }
        cfg = ConfigManager.loadCfg("csServerList.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 跨服PVP商店初始化配置
function ConfigManager.getOSPVPShopCfg()
    local key = "OSPVPShopCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'item', "price" })
        local convertMap = {
            ['id'] = tonumber,
            ['item'] = ConfigManager.parseItemWithComma,
            ['price'] = tonumber
        }
        cfg = ConfigManager.loadCfg("pvpShop.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 阵容界面， 奖励展示
function ConfigManager.getMercenaryRewardCfg()
    local key = "getMercenaryYouLiRewardInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("mercenaryReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 战斗界面，双倍活动奖励展示
function ConfigManager.getDoubleActivityDisplayCfg()
    local key = "getMercenaryRewardInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'activityId', 'name' })
        local convertMap = {
            ['id'] = tonumber,
            ['activityId'] = tonumber,
            ['name'] = tostring,
        }
        cfg = ConfigManager.loadCfg("DoubleActivityDisplay.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 大转盘活动，主页抽奖奖励展示
function ConfigManager.getTurntableRewardCfg()
    local key = "getTurntableRewardInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("TurntableReward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 大转盘活动，宝箱奖励展示
function ConfigManager.getTurntableBoxAwardCfg()
    local key = "getTurntableBoxAwardInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("TurntableBoxAward.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 大转盘活动，碎片兑换奖励
function ConfigManager.getTurntableExchangeDisplayCfg()
    local key = "getTurntableExchangeDisplayInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'consume', 'rewards', 'times' })
        local convertMap = {
            ['id'] = tonumber,
            ['consume'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
            ['times'] = tonumber
        }
        cfg = ConfigManager.loadCfg("TurntableExchangeDisplay.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 大转盘活动，佣兵
function ConfigManager.getTurntableMercenaryIdCfg()
    local key = "getTurntableMercenaryIdInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id' })
        local convertMap = {
            ['id'] = tonumber
        }
        cfg = ConfigManager.loadCfg("TurntableMercenaryId.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 主角时装配置
function ConfigManager.getLeaderAvatarCfg()
    local key = "LeaderAvatarCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', "maxDay", 'name', "desc", "tokens", "quality", "prop1", "prop2", "prop3", "prop4", "prop5", "prop6" })
        local convertMap = {
            ['id'] = tonumber,
            maxDay = tonumber,
            token = tonumber,
            quality = tonumber
        }
        cfg = ConfigManager.loadCfg("avatar.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 万圣节活动，兑换奖励
function ConfigManager.getHalloweenExchangeDisplayCfg()
    local key = "getHalloweenExchangeDisplayCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'rewards', 'consume', 'times', 'spineId' })
        local convertMap = {
            ['id'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma,
            ['consume'] = ConfigManager.parseItemWithComma,
            ['times'] = tonumber,
            ['spineId'] = tonumber
        }
        cfg = ConfigManager.loadCfg("halloweenExchange.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 万圣节活动，查看可获得的奖励
function ConfigManager.getHalloweenLookRewardCfg()
    local key = "getHalloweenLookRewardCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'type', 'rewards' })
        local convertMap = {
            ['id'] = tonumber,
            ['type'] = tonumber,
            ['rewards'] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("halloweenRaiderDrop.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end


-- 万圣节活动，道具数量显示
function ConfigManager.getHalloweenExhibitionItemsCfg()
    local key = "getHalloweenExhibitionItemsCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'items' })
        local convertMap = {
            ['id'] = tonumber,
            ['items'] = ConfigManager.parseItemWithComma
        }
        cfg = ConfigManager.loadCfg("halloweenExhibition.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 提示引导
function ConfigManager.getHintGuideCfg()
    local key = "HintGuideCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'step', 'level', 'func', 'funcParam' })
        local convertMap = {
            ["step"] = tonumber,
            ["level"] = tonumber,
            ["funcParam"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("HintGuide.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 兑换商城
function ConfigManager.getHaremExchangeCfg()
    local key = "haremExchange"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'order' })
        local convertMap = {
            ["id"] = tonumber,
            ["order"] = tonumber,
        }
        cfg = ConfigManager.loadCfg("haremExchange.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 猎命升级经验配置读取转换函数
function FateLevelUpExpFunc(str)
    local arr = common:split(str or "", ",")
    for i, v in pairs(arr) do
        arr[i] = tonumber(v)
    end
    return arr
end
-- 猎命基础属性配置读取转换函数
function FateBasicAttrFunc(str)
    local arr = common:split(str or "", ",")
    local data = { }
    for i, v in ipairs(arr) do
        local temp = common:split(v, "_")
        assert(#temp == 2)
        data[i] = { type = tonumber(temp[1]), value = tonumber(temp[2]) }
    end
    return data
end
-- 猎命升级属性配置读取转换函数
function FateLevelUpAttrFunc(str)
    local arr = common:split(str or "", ",")
    for i, v in ipairs(arr) do
        local onLv = common:split(v, ";")
        arr[i] = { }
        for j, val in ipairs(onLv) do
            local temp = common:split(val, "_")
            assert(#temp == 2)
            arr[i][j] = { type = tonumber(temp[1]), value = tonumber(temp[2]) }
        end
    end
    return arr
end

-- 猎命系统配置
function ConfigManager.getFateDressCfg()
    local key = "FateDressCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            'id',-- id
            'rank', --階級
            'rare', --稀有度
            'star', --星數
            'afterId', --合成後的id
            'name',-- 名字
            'icon',
            'basicAttr',-- 基础属性
            'OtherAttr',
            'hasSkill',
            'slot',
            'skillpool',
            'unlocksp',
            'refineCost',
            'lockCost',
            'spRefineCost'
        } )
        local convertMap = {
            ['id'] = tonumber,
            -- idFateWearsPage
            ['rank'] = tonumber,
            ['rare'] = tonumber,
            ['star'] = tonumber,
            ['afterId'] = tonumber,
            ['hasSkill'] = tonumber,
            ['slot'] = tonumber,
            ['skillpool'] = tonumber,
            ['unlocksp'] = tonumber,
            ['refineCost'] = function(key)
                return common:split(key,",")
            end,
            ['lockCost'] = function(key)
                return common:split(key,",")
            end,
            ['spRefineCost'] = tonumber,
            ['name'] = function(key)
                return common:getLanguageString(key)
            end,
            -- 基础属性
            ['starAttr'] = FateBasicAttrFunc,
        }
        cfg = ConfigManager.loadCfg("dress.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 猎命系统配置1
function ConfigManager.getFateBuyCfg()
    local key = "FateBuyCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            'id',-- id
            'directBuy',-- 是否可直接激活
            'activeBuyCost',-- 直接激活价格
            'lightCost',-- 点亮消耗
        } )
        local convertMap = {
            ['id'] = tonumber,
            -- id
            ['directBuy'] = tonumber,
            -- 是否可直接激活
            ['activeBuyCost'] = ConfigManager.parseItemWithComma,
            -- 直接激活价格
            ['lightCost'] = ConfigManager.parseItemWithComma,-- 点亮消耗
        }
        cfg = ConfigManager.loadCfg("buyDress.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
--調教設定
function ConfigManager:getBdsmCfg()
    local key = "BDSM"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            'Role', -- 角色ID
            'Q1',   -- 閥值1
            'Soft1',-- 按鈕1增長值
            'Hard1',-- 按鈕2增長值
            'Rapid1',-- 按鈕3增長值
            'Audio1',-- 音效1
            'Q2',   -- 閥值2
            'Soft2',-- 按鈕1增長值
            'Hard2',-- 按鈕2增長值
            'Rapid2',-- 按鈕3增長值
            'Audio2',-- 音效2
            'Q3',   -- 閥值3
            'Soft3',-- 按鈕1增長值
            'Hard3',-- 按鈕2增長值
            'Rapid3',-- 按鈕3增長值
            'Audio3',-- 音效3
            'Q4',   -- 閥值4
            'Soft4',-- 按鈕1增長值
            'Hard4',-- 按鈕2增長值
            'Rapid4',-- 按鈕3增長值
            'Audio4',-- 音效4
            'Audio5',-- 音效5(高潮音效)
        } )
        local convertMap = {
            ['Role'] = tonumber,
            ['Q1'] = tonumber,
            ['Soft1'] = tonumber,
            ['Hard1'] = tonumber,
            ['Rapid1'] = tonumber,
            ['Audio1'] = tostring,
            ['Q2'] = tonumber,
            ['Soft2'] = tonumber,
            ['Hard2'] = tonumber,
            ['Rapid2'] = tonumber,
            ['Audio2'] = tostring,
            ['Q3'] = tonumber,
            ['Soft3'] = tonumber,
            ['Hard3'] = tonumber,
            ['Rapid3'] = tonumber,
            ['Audio3'] = tostring,
            ['Q4'] = tonumber,
            ['Soft4'] = tonumber,
            ['Hard4'] = tonumber,
            ['Rapid4'] = tonumber,
            ['Audio4'] = tostring,
            ['Audio5'] = tostring,
        }
        cfg = ConfigManager.loadCfg("BDSM.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
--相簿數量設定
function ConfigManager:getAlbumCfg()
    local key = "Album"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            'ID', -- 角色ID
            'Photo',   -- 相簿數量
        } )
        local convertMap = {
            ['ID'] = tonumber,
            ['Photo'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("Album.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
--PopBanner設定
function ConfigManager:getBannerCfg()
    local key = "Banner"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            'ID', -- ID
            'group',
            'activityId', -- 活動ID 
            'Page',   
            'Image',
            'type',
            'openDay',
            'startTime',
            'endTime'
        } )
        local convertMap = {
            ['ID'] = tonumber,
            ['Page'] = tonumber,
            ['activityId'] = tonumber,
            ['group'] = tonumber,
            ['type'] = tonumber,
            ['startTime'] = tonumber,
            ['endTime'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("BannerConfig.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
--調教演出設定
function ConfigManager:getViewWaveCfg()
    local key = "ViewWave"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( {
            'Role', -- ID
            'Scale', 
            'Time1',    --action時間
            'X1Y1',     --位移
            'Wait1',    --停留時間
            'Time2',
            'X2Y2',
            'Wait2',
            'Time3',
            'X3Y3',
            'Wait3',
        } )
        local convertMap = {
            ['Role'] = tonumber,
            ['Scale'] = tonumber,
            ['Time1'] = tonumber,
            ['X1Y1'] = tostring,
            ['Wait1'] = tonumber,
            ['Time2'] = tonumber,
            ['X2Y2'] = tostring,
            ['Wait2'] = tonumber,
            ['Time3'] = tonumber,
            ['X3Y3'] = tostring,
            ['Wait3'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("ViewWave.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
--平台設定
function ConfigManager:getPlatformCfg()
    local keyName = "platform"
    local cfg = ConfigManager.configs[keyName]
    if cfg == nil then
        cfg = ""
        local writablePath = CCFileUtils:sharedFileUtils():getWritablePath()
        CCLuaLog(writablePath)
        if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
            fileName = writablePath .. "/platform.cfg"
        else
            fileName = writablePath .. "/assets/platform.cfg"
        end
	    local isFileExist =  CCFileUtils:sharedFileUtils():isFileExist(fileName)
	    if isFileExist == false then
            CCLuaLog(fileName)
	    	return
	    end
	    file = io.open(fileName,"r")
	    if file == nil then
	        return
	    end
	    for line in file:lines() do
	        cfg = cfg..tostring(line);
	    end
        ConfigManager.configs[keyName] = cfg
	    file:close()
    end
    return cfg
end

-- 爆衣需求表
function ConfigManager.getSkinDemandCfg()
    local key = "SkinDemandCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'id','needItem1', 'needItem2' ,'needItem3'})
        local convertMap = {
            ['id'] = tonumber,
            ['needItem1'] = ConfigManager.parseItemWithComma,
            ['needItem2'] = ConfigManager.parseItemWithComma,
            ['needItem3'] = ConfigManager.parseItemWithComma,
        }
        cfg = ConfigManager.loadCfg("roleSkinDemand.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 活動143(海盜)需求表
function ConfigManager.getPirateBoxDropCfg()
    local key = "PirateBoxDropCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'id','CoinConsume', 'DiamondConsume' })
        local convertMap = {
            ['id'] = tonumber,
            ['CoinConsume'] = tonumber,
            ['DiamondConsume'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("pirateboxDrop.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 小學堂角色數值
function ConfigManager.getLTRoleCfg()
    local key = "LTRole"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'Role','HP', 'ATK', 'Speed', 'Type', 'SkillID', 'SkillIcon', 'BuffIcon', 'Spine' })
        local convertMap = {
            ['Role'] = tonumber,
            ['HP'] = tonumber,
            ['ATK'] = tonumber,
            ['Speed'] = tonumber,
            ['Type'] = tonumber,
            ['SkillID'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("LTRole.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 小學堂技能
function ConfigManager.getLTSkillCfg()
    local key = "LTSkill"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID','SF', 'BUFFID', 'Times', 'Arg1', 'Arg2', 'Arg3' })
        local convertMap = {
            ['ID'] = tonumber,
            ['SF'] = tonumber,
            ['Arg1'] = tonumber,
            ['Arg2'] = tonumber,
            ['Arg3'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("LTSkill.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-----------------------------------------------------------------
-- HoH 新表格
-----------------------------------------------------------------
-- 新角色資料
function ConfigManager.getNewHeroCfg()
    local key = "NewHero"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'Spine', 'Skills', 'Element', 'Job', 'Star', 'IsMag','StrRate', 'IntRate', 'AgiRate', 'StaRate',
                                                     'Str', 'Int', 'Agi', 'Sta', 'Hp', 'Atk', 'Mag', 'PhyPenetrate', 'MagPenetrate',
                                                     'PhyDef', 'MagDef', 'RecoverHp', 'CriDmg', 'CriResist', 'Cri', 'Hit', 'Dodge', 'Immunity','AtkRng', 'AtkSpd',
                                                     'WalkSpd', 'RunSpd', 'AtkMp', 'DefMp', 'SkillMp', 'ClassCorrection', 'Skin', 'CenterOffsetX', 'CenterOffsetY', 'HeadOffsetY', 'Reflect' })
        local convertMap = {
            ['ID'] = tonumber, ['Element'] = tonumber, ['Job'] = tonumber, ['Star'] = tonumber,
            ['IsMag'] = tonumber, ['StrRate'] = tonumber, ['AgiRate'] = tonumber, ['IntRate'] = tonumber, ['StaRate'] = tonumber, 
            ['Str'] = tonumber, ['Int'] = tonumber, ['Agi'] = tonumber, ['Sta'] = tonumber,
            ['Hp'] = tonumber, ['Atk'] = tonumber, ['Mag'] = tonumber, ['PhyPenetrate'] = tonumber, ['MagPenetrate'] = tonumber,
            ['PhyDef'] = tonumber, ['MagDef'] = tonumber, ['RecoverHp'] = tonumber, ['CriDmg'] = tonumber, ['CriResist'] = tonumber, 
            ['Cri'] = tonumber, ['Hit'] = tonumber, ['Dodge'] = tonumber, ['Immunity'] = tonumber, ['AtkRng'] = tonumber, ['AtkSpd'] = tonumber,
            ['WalkSpd'] = tonumber, ['RunSpd'] = tonumber, ['AtkMp'] = tonumber, ['DefMp'] = tonumber, ['ClassCorrection'] = tonumber,
            ['CenterOffsetX'] = tonumber, ['CenterOffsetY'] = tonumber, ['HeadOffsetY'] = tonumber, ['Reflect'] = tonumber
        }
        cfg = ConfigManager.loadCfg("class_New.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 新怪物資料
function ConfigManager.getNewMonsterCfg()
    local key = "NewMonsterCfg"
    local cfg = ConfigManager.monsterCfg--ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'Spine', 'CharFxName', 'BulletName', 'Icon', 'Name','Info','Skin', 'Reflect', 'Job', 'Element','Level', 'Skills', 'IsMag',
                                                     'Str', 'Int', 'Agi', 'Sta', 'Hp', 'Atk', 'Mag', 'PhyPenetrate', 'MagPenetrate', 'PhyDef', 'MagDef', 
                                                     'RecoverHp', 'CriDmg', 'CriResist', 'Cri', 'Hit', 'Dodge', 'Immunity', 'AtkRng', 'AtkSpd', 'WalkSpd', 'RunSpd', 
                                                     'HitEffectPath', 'CenterOffsetX', 'CenterOffsetY', 'HeadOffsetY', 'AtkMp', 'DefMp', 'SkillMp', 'ClassCorrection' })
        local convertMap = {
            ['ID'] = tonumber, ['Skin'] = tonumber, ['Reflect'] = tonumber, ['Job'] = tonumber, ['Element'] = tonumber, ['Level'] = tonumber, ['IsMag'] = tonumber,
            ['Str'] = tonumber, ['Int'] = tonumber, ['Agi'] = tonumber, ['Sta'] = tonumber,
            ['Hp'] = tonumber, ['Atk'] = tonumber, ['Mag'] = tonumber, ['PhyPenetrate'] = tonumber, ['MagPenetrate'] = tonumber,
            ['PhyDef'] = tonumber, ['MagDef'] = tonumber, ['RecoverHp'] = tonumber, ['CriDmg'] = tonumber, ['CriResist'] = tonumber, 
            ['Cri'] = tonumber, ['Hit'] = tonumber, ['Immunity'] = tonumber, ['Dodge'] = tonumber, ['AtkRng'] = tonumber, ['AtkSpd'] = tonumber,
            ['WalkSpd'] = tonumber, ['RunSpd'] = tonumber, ['CenterOffsetX'] = tonumber,  ['CenterOffsetY'] = tonumber, ['HeadOffsetY'] = tonumber, 
            ['AtkMp'] = tonumber, ['DefMp'] = tonumber, ['ClassCorrection'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("monster_New.txt", attrMap, 0, convertMap)
        --ConfigManager.configs[key] = cfg
        ConfigManager.monsterCfg = cfg
    end
    return cfg
end

-- 新地圖資料
function ConfigManager.getNewMapCfg()
    local key = "NewMap"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'NextID', 'Chapter','Level', 'MonsterID', 'BossID', 'Portrait', 'DropItems', 'BossDrop', 'EXP', 
                                                     'SkyCoin', 'Potion', 'BP', 'Unlock' ,'GirlTxt','Stone'})
        local convertMap = {
            ['ID'] = tonumber, ['NextID'] = tonumber, ['Portrait'] = tonumber, ['EXP'] = tonumber, 
            ['SkyCoin'] = tonumber, ['Potion'] = tonumber, ['BP'] = tonumber, ['Unlock'] = tonumber,['Chapter'] = tonumber,['Level'] = tonumber,
        ['Stone'] = tonumber,}
        cfg = ConfigManager.loadCfg("map_New.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-----------------------------------------------------------------
-- NG 新表格
-----------------------------------------------------------------
-- 新角色升級資料
function ConfigManager.getHeroLevelCfg()
    local key = "HeroLevel"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'Level', 'Cost' })
        local convertMap = {
            ['Level'] = tonumber
        }
        cfg = ConfigManager.loadCfg("Hero_Level.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 新角色升星資料
function ConfigManager.getHeroStarCfg()
    local key = "HeroStar"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'RoleId', 'Star', 'Cost', 'Skills', 'LimitLevel', 'Award' })
        local convertMap = {
            ['ID'] = tonumber, ['RoleId'] = tonumber, ['Star'] = tonumber, ['LimitLevel'] = tonumber
        }
        cfg = ConfigManager.loadCfg("Hero_Star.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 符石資訊
function ConfigManager.getDressInfoCfg()
    local key = "DressInfo"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'Icon', 'Tier', 'Str1', 'Str2' })
        local convertMap = {
            ['ID'] = tonumber, ['Tier'] = tonumber
        }
        cfg = ConfigManager.loadCfg("dress_Info.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 精靈島等級資料
function ConfigManager.getSpiritLevelCfg()
    local key = "Spirit"
    local cfg = ConfigManager.configs[key]
    local InfoAccesser = require("Util.InfoAccesser")
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'id', 'group', 'spriteratio', 'heroratio', 'level', 'cost', 'attr'})
        local convertMap = {
            ['id'] = tonumber, ['group'] = tonumber, ['spriteratio'] = tonumber, ['heroratio'] = tonumber, ['level'] = tonumber,
            ['cost'] = function (val)
                if val == "0" then return {} end
                return InfoAccesser:getItemInfosByStr(val)
            end,
            ['attr'] = function (val)
                if val == "0" then return {} end
                return InfoAccesser:getAttrInfosByStrs(common:split(val, ","))
            end,
        }
        cfg = ConfigManager.loadCfg("spriteSoul.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 許願輪 里程碑 資料
function ConfigManager.getWishingWellMilestoneCfg()
    local key = "WishingWellMilestone"
    local cfg = ConfigManager.configs[key]
    local InfoAccesser = require("Util.InfoAccesser")
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'id', 'points', 'reward'})
        local convertMap = {
            ['id'] = tonumber,
            ['points'] = function (val)
                local strs = common:split(val, ",")
                local res = {}
                for idx, val in ipairs(strs) do
                    res[idx] = tonumber(val)
                end
                return res
            end,
            ['reward'] = function (val)
                return InfoAccesser:getItemInfosByStr(val)
            end,
        }
        cfg = ConfigManager.loadCfg("WishingMilestone147.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 精靈召喚 里程碑 資料
function ConfigManager.getSpiritSummonMilestoneCfg()
    local key = "SpiritSummonMilestone"
    local cfg = ConfigManager.configs[key]
    local InfoAccesser = require("Util.InfoAccesser")
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'id', 'points', 'reward'})
        local convertMap = {
            ['id'] = tonumber,
            ['points'] = function (val)
                local strs = common:split(val, ",")
                local res = {}
                for idx, val in ipairs(strs) do
                    res[idx] = tonumber(val)
                end
                return res
            end,
            ['reward'] = function (val)
                return InfoAccesser:getItemInfosByStr(val)
            end,
        }
        cfg = ConfigManager.loadCfg("ReleaseURMilestone154.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 角色圖鑑資料
function ConfigManager.getHeroEncyclopediaCfg()
    local key = "HeroEncyclopedia"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'MaxStar', 'MaxLevel', 'MaxBp', 'MaxStr', 'MaxInt', 'MaxAgi', 'MaxHp' ,'MinBp', 'MinStr', 'MinInt', 'MinAgi', 'MinHp'  })
        local convertMap = {
            ['ID'] = tonumber, ['MaxStar'] = tonumber, ['MaxLevel'] = tonumber, ['MaxBp'] = tonumber,
            ['MaxStr'] = tonumber, ['MaxInt'] = tonumber, ['MaxAgi'] = tonumber, ['MaxHp'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("HeroEncyclopedia.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 編隊加成資料
function ConfigManager.getTeamBuffCfg()
    local key = "TeamBuff"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'Attr', 'Num', 'Buff'  })
        local convertMap = {
            ['ID'] = tonumber, ['Attr'] = tonumber, ['Num'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("TeamBuff.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 秘密信條資料
function ConfigManager.getSecretMessageCfg()
    local key = "SecretMessage"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'Hero', 'QuestionStr', 'AnsStr1', 'AnsStr2', 'EndStr1', 'EndStr2'  })
        local convertMap = {
            ['ID'] = tonumber, ['Hero'] = tonumber
        }
        cfg = ConfigManager.loadCfg("SecretMessage.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
-- 英雄特效檔名
function ConfigManager.getHeroEffectPathCfg()
    local key = "HeroEff"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'HeroFx', 'AttackHit', 'Bullet' })
        local convertMap = {
            ['ID'] = tonumber, ['Hero'] = tonumber
        }
        cfg = ConfigManager.loadCfg("Hero_Eff.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

-- 道具圖標
function ConfigManager.getItemIconCfg()
    local key = "ItemIcon"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber({ 'ID', 'item', 'type', 'env', 'scale', 'offsetX', 'offsetY'})
        local convertMap = {
            ['ID'] = tonumber,
            ['scale'] = tonumber,
            ['offsetX'] = tonumber, ['offsetY'] = tonumber
        }
        cfg = ConfigManager.loadCfg("itemIcon.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- 專武羈絆
function ConfigManager.getFetterEquipCfg()
    local key = "FetterEquipCfg"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'order', 'name', 'team', 'reward', 'property', 'formula', "star" })
        local convertMap = {
            ['id'] = tonumber,
            ['order'] = tonumber,
            ['team'] = function(val)
                local arr = common:split(val, ",")
                table.foreach(arr, function(i, v)
                    arr[i] = tonumber(v)
                end )
                return arr
            end,
            ['property'] = function(val)
                return common:split(val, ",")
            end,
            ['reward'] = ConfigManager.parseItemWithComma,
            ['star'] = tonumber
        }
        cfg = ConfigManager.loadCfg("fetterEquip.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getPickUpCfg()
    local key = "PickUpCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "actId","id","Spine","EFF","littleSpine","Banner" });
        local convertMap = {
            ["id"] = tonumber,
            ["actId"] = tonumber,
            --["price"] = tonumber,
            -- ["reward"] = ConfigManager.parseItemOnlyWithUnderline,
        };
        cfg = ConfigManager.loadCfg("ReleaseURdrawgirl172.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getBattleEffCfg()
    local key = "BattleEffCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "effList" });
        local convertMap = {
            ["id"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("BattleEff.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getFunctionUnlock()
    local key = "FunctionUnlockCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "Function", "unlockType", "unlockValue", "unlockStr" , "isHide" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["isHide"] = tonumber, 
        };
        cfg = ConfigManager.loadCfg("function_unlock.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
--排行榜獎勵
function ConfigManager.getRankReward()
    local key = "RankRewardCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type" ,"content","mission", "Reward" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["mission"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("rankServer_NG.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getGloryHoleDailyQuest()
    local key = "GloryHoleDailyQuestCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "type", "targetCount", "point", "des", "icon", "sortId", "isJump", "jumpValue", "showType", "quality" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["targetCount"] = tonumber,
            ["content"] = tostring,
            ["des"] = tostring,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("GloryHoleDailyQuest.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getGloryHoleDailyQuestPointCfg()
    local key = "GloryHoledailyQuestPoint";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "award" });
        local convertMap = {
            ["id"] = tonumber,
            ["award"] = ConfigManager.parseItemWithComma,
        };
        cfg = ConfigManager.loadCfg("GloryHoleDailyQuestPoint.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getGloryHoleQuestCfg()
    local key = "GloryHoleQuest";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "questType", "team", "reward","targetCount", "sortId", "des", "icon", "isJump", "jumpValue", "showType", "quality", "targetType" });
        local convertMap = {
            ["id"] = tonumber,
            ["questType"] = tonumber,
            ["team"] = tonumber,
            ["targetCount"] = tonumber,
            ["sortId"] = tonumber,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
            ["targetType"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("GloryHoleQuest.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
 function ConfigManager.getGloryHoleCfg()
       local key = "GloryHoleCfg";
       local cfg = ConfigManager.configs[key];
           if cfg == nil then
               local attrMap = common:table_combineNumber( { "id", "HeroId", "Type", "Spine", "A_frame", "B_frame","A_Eff", "B_Eff", "D_Eff","randomTable", "BGM" , "openDays"});
               local convertMap = {
                   ["id"] = tonumber,
                   ["HeroId"] = tonumber,
                   ["Type"] = tonumber,
               };
               cfg = ConfigManager.loadCfg("GloryHoleControl.txt", attrMap, 0, convertMap);
               ConfigManager.configs[key] = cfg;
           end
        return cfg;
    end
    function ConfigManager.getGloryHoleRankRewardCfg()
       local key = "GloryHoleankRewardCfg";
       local cfg = ConfigManager.configs[key];
           if cfg == nil then
               local attrMap = common:table_combineNumber( { "id", "minRank", "DailyReward", "BestReward", "TeamReward"});
               local convertMap = {
                   ["id"] = tonumber,
                   ["minRank"] = tonumber,
                   ["DailyReward"] = ConfigManager.parseItemWithComma,
                   ["BestReward"] = ConfigManager.parseItemWithComma,
                   ["TeamReward"] = ConfigManager.parseItemWithComma,
               };
               cfg = ConfigManager.loadCfg("releaseUrRank175Award.txt", attrMap, 0, convertMap);
               ConfigManager.configs[key] = cfg;
           end
        return cfg;
    end
--紅點管理
function ConfigManager.getRedPointSetting()
    local key = "RedPointSettingCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "parent" , "child", "unlock", "groupNum" });
        local convertMap = {
            ["id"] = tonumber,
            ["parent"] = tonumber,
            ["unlock"] = tonumber,
            ["groupNum"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("RedPointSetting.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
--鑽石VIP聲望
function ConfigManager.getDiamondVIPCfg()
    local key = "DiamondVIPCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "count"});
        local convertMap = {
            ["id"] = tonumber,
            ["count"] = tonumber,

        };
        cfg = ConfigManager.loadCfg("DiamondVIP.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
--活動191
function ConfigManager.getAct191Achive()
    local key = "Act191Achive";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "needCount", "sort","reward","rewardCount","Icon","isJump","jumpValue","showType","quality","targetType" });
        local convertMap = {
            ["id"] = tonumber,
            ["needCount"] = tonumber,
            ["sort"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
            ["targetType"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("ActivityQuest.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
--活動196
function ConfigManager.getAct196Achive()
    local key = "Act196Achive";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "needCount", "sort","reward","rewardCount","Icon","isJump","jumpValue","showType","quality","targetType" });
        local convertMap = {
            ["id"] = tonumber,
            ["needCount"] = tonumber,
            ["sort"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
            ["targetType"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("ActivityQuest_2.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.get191DailyQuest()
    local key = "191DailyQuestCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "type", "targetCount", "point", "des", "icon", "sortId", "isJump", "jumpValue", "showType", "quality" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["targetCount"] = tonumber,
            ["content"] = tostring,
            ["des"] = tostring,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("ActivityDailyQuest.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.get196DailyQuest()
    local key = "196DailyQuestCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "type", "targetCount", "point", "des", "icon", "sortId", "isJump", "jumpValue", "showType", "quality" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["targetCount"] = tonumber,
            ["content"] = tostring,
            ["des"] = tostring,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("ActivityDailyQuest_2.txt", attrMap, nil, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.get191DailyQuestPointCfg()
    local key = "191dailyQuestPoint";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "award" });
        local convertMap = {
            ["id"] = tonumber,
            ["award"] = ConfigManager.parseItemWithComma,
        };
        cfg = ConfigManager.loadCfg("ActivityDailyQuestPoint.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.get196DailyQuestPointCfg()
    local key = "196dailyQuestPoint";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "award" });
        local convertMap = {
            ["id"] = tonumber,
            ["award"] = ConfigManager.parseItemWithComma,
        };
        cfg = ConfigManager.loadCfg("ActivityDailyQuestPoint_2.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.get191StageCfg()
    local key = "191Stage";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "nextId" ,"star","type","mosterIds","dropItems","unlockTime","replay","StageName","Banner","battleBg","storyBanner"});
        local convertMap = {
            ["id"] = tonumber,
            ["nextId"] = tonumber,
            ["star"] = tonumber,
            ["type"] = tonumber,
            ["dropItems"] = ConfigManager.parseItemWithComma,
            ["unlockTime"] = tonumber,
            ["replay"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("activityStage191.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.get196StageCfg()
    local key = "196Stage";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "nextId" ,"star","type","mosterIds","dropItems","unlockTime","replay","StageName","Banner","battleBg","storyBanner"});
        local convertMap = {
            ["id"] = tonumber,
            ["nextId"] = tonumber,
            ["star"] = tonumber,
            ["type"] = tonumber,
            ["dropItems"] = ConfigManager.parseItemWithComma,
            ["unlockTime"] = tonumber,
            ["replay"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("activityStage191_196.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

--- Event001日記設定
function ConfigManager.getEvent001ControlCfg()
    local key = "Event001Control"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'role', 'bg','startMovementId', "endMovementId", 'bgm', 'eff', "voiceWait" })
        local convertMap = {
            ['id'] = tonumber,
            ['role'] = tonumber,
            ['startMovementId'] = tonumber,
            ['endMovementId'] = tonumber,
            ['voiceWait'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fetterASControl.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end
function ConfigManager.getEvent001Control196Cfg()
    local key = "Event001Control196"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'role', 'bg','startMovementId', "endMovementId", 'bgm', 'eff', "voiceWait" })
        local convertMap = {
            ['id'] = tonumber,
            ['role'] = tonumber,
            ['startMovementId'] = tonumber,
            ['endMovementId'] = tonumber,
            ['voiceWait'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fetterASControl_2.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--- Event001日記演出
function ConfigManager.getEvent001ActionCfg()
    local key = "EventAction"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'actionType', 'spine', 'define','position','wait', 'transform', 'rotate', 'scale', 'time', 'parent', 'spawnId' })
        local convertMap = {
            ['id'] = tonumber,
            ['actionType'] = tonumber,
            ['define'] = tonumber,
            ['wait'] = tonumber,
            ['rotate'] = tonumber,
            --['scale'] = tonumber,
            ['time'] = tonumber,
            ['parent'] = tonumber,
            ['spawnId'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fetterASMovement.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

function ConfigManager.getEvent001Action196Cfg()
    local key = "EventActio196n"
    local cfg = ConfigManager.configs[key]
    if cfg == nil then
        local attrMap = common:table_combineNumber( { 'id', 'actionType', 'spine', 'define','position','wait', 'transform', 'rotate', 'scale', 'time', 'parent', 'spawnId' })
        local convertMap = {
            ['id'] = tonumber,
            ['actionType'] = tonumber,
            ['define'] = tonumber,
            ['wait'] = tonumber,
            ['rotate'] = tonumber,
            --['scale'] = tonumber,
            ['time'] = tonumber,
            ['parent'] = tonumber,
            ['spawnId'] = tonumber,
        }
        cfg = ConfigManager.loadCfg("fetterASMovement_2.txt", attrMap, 0, convertMap)
        ConfigManager.configs[key] = cfg
    end
    return cfg
end

--累積儲值
function ConfigManager.getRechargeBonusCfg()
    local key = "RechargeBonusCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "timeIndex", "count", "platform", "needCount", "reward", "rank" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["timeIndex"] = tonumber,
            ["count"] = tonumber,
            ["platform"] = tonumber,
            ["needCount"] = tonumber,
            ["rank"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("RechargeBounceCfg.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
--自動彈跳頁面設定
function ConfigManager.getWindowPopupCfg()
    local key = "WindowPopupCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "type", "rank" });
        local convertMap = {
            ["id"] = tonumber,
            ["type"] = tonumber,
            ["rank"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("window_popup.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getBadgeSkillCfg()
    local key = "BadgeSkillCfg";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "group", "rate","rare","type","skill" });
        local convertMap = {
            ["id"] = tonumber,
            ["group"] = tonumber,
            ["rate"] = tonumber,
            ["rare"] = tonumber,
            ["type"] = tonumber,
            ["skill"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("badgegachaList.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 單人強敵
function ConfigManager.getSingleBoss()
    local key = "SingleBoss";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "monsterIds", "skill01", "skill02", "skill03", "rate", "stagePoint", 
                                                      "stageReward1", "stageReward2", "stageReward3", "stageReward4", "stageReward5",
                                                      "stageReward6", "stageReward7", "stageReward8", "stageReward9", "stageReward10",
                                                      "BossSpine", "Trans", "BossName", "BossId", "BattleBg" });
        local convertMap = {
            ["id"] = tonumber,
            ["skill01"] = tonumber,
            ["skill02"] = tonumber,
            ["skill03"] = tonumber,
            ["rate"] = tonumber,
            ["BossId"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("SingleBoss.txt", attrMap, 0, convertMap);
        local newCfg = { }
        for k, v in pairs(cfg) do
            if cfg.stage then
                newCfg[v.stage] = newCfg[v.stage] or { }
                newCfg[v.stage][k] = v
            else
                newCfg[1] = newCfg[1] or { }
                newCfg[1][k] = v
            end
        end
        cfg = newCfg
        ConfigManager.configs[key] = cfg;
    end
    local activityId = Const_pb.ACTIVITY193_SingleBoss
    local stageId = ActivityInfo.activities[activityId] and ActivityInfo.activities[activityId].newVersion or 1
    return cfg[stageId] or cfg[1];
end
-- 單人強敵任務
function ConfigManager.getSingleBossAchive()
    local key = "SingleBossAchive";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "name", "content", "needCount", "sort", "reward", "rewardCount", "Icon", 
                                                      "isJump", "jumpValue", "showType", "quality", "targetType" });
        local convertMap = {
            ["id"] = tonumber,
            ["needCount"] = tonumber,
            ["sort"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma,
            ["isJump"] = tonumber,
            ["showType"] = tonumber,
            ["jumpValue"] = tonumber,
            ["quality"] = tonumber,
            ["targetType"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("SingleBossQuest.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
-- 單人強敵任務
function ConfigManager.getSingleBossRankAward()
    local key = "SingleBossRankAward";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "minRank", "reward" });
        local convertMap = {
            ["id"] = tonumber,
            ["minRank"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("releaseUrRank193Award.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-- 召喚機率表
function ConfigManager.getSummonRate()
    local key = "SummonRate";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id", "ActId", "pool","poolrate","item","Title","Sort","Rate","SingleRate","FreeTypeFont" });
        local convertMap = {
            ["id"] = tonumber,
            ["pool"] = tonumber,
            ["poolrate"] = tonumber,
            ["item"] = ConfigManager.parseItemWithComma,
            ["Sort"] = tonumber,
            ["SingleRate"] = tonumber,
            ["FreeTypeFont"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("helpgacha.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

function ConfigManager.getTowerData()
    local key = "TowerData";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id","nextStage","monsterId","reward","stageBg","BuffId","Spine","scale","battleBg","StageName" });
        local convertMap = {
            ["id"] = tonumber,
            ["nextStage"] = tonumber,
            ["BuffId"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma,
        };
        cfg = ConfigManager.loadCfg("SeasonTower194.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getTowerRank()
    local key = "TowerRank";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id","minRank","reward" });
        local convertMap = {
            ["id"] = tonumber,
            ["minRank"] = tonumber,
            ["reward"] = ConfigManager.parseItemWithComma,
        };
        cfg = ConfigManager.loadCfg("SeasonTowerRankAward.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end
function ConfigManager.getPickUpCfg_New()
    local key = "PickUpCfg_New";
    local cfg = ConfigManager.configs[key];
    if cfg == nil then
        local attrMap = common:table_combineNumber( { "id","type","BG","spine","summonSpine","Jump","chibi","Desc","TabImg","Title","Banner" });
        local convertMap = {
            ["id"] = tonumber,
            ["Jump"] = tonumber,
        };
        cfg = ConfigManager.loadCfg("pickUpGacha.txt", attrMap, 0, convertMap);
        ConfigManager.configs[key] = cfg;
    end
    return cfg;
end

-----------------------------------------------------------------
return ConfigManager;
