--[[ 
    name: CommItem
    desc: 通用項目
    author: youzi
    update: 2023/6/12 14:49
    description: 
--]]

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")

--[[ 主體 ]]
local CommItem = {}
--[[ 
    var
        mStarNode 星數容器
        mStar1 ~ mStar6 不同星數顯示
        mName1 下方名稱
        mPic1 物品圖片

        mShader 上方暗區
        mEquipLv 上方暗區中 裝備等級

        mNumber1 右上數字
        mNumber1_1 右下數字
    
    event
        onHand1 當 道具 點擊

--]]

--[[ 顯示類型 ]]
CommItem.ShowType = {
    CLEAR = 0, -- 清空
    NORMAL = 1, -- 複數, 不具稀有度
    EQUIPMENT = 2, -- 單個, 具稀有度
    SPIRIT = 3, -- 單個, 具稀有度, 名稱
    ANCIENT_EQUIPMENT = 4, -- 單個, 具稀有度(1~13星)
    EQUIPMENT_NUM = 5,  -- 複數, 具稀有度
    ANCIENT_EQUIPMENT_NUM = 6, -- 複數, 具稀有度(1~13星)
    FATE = 7,   
    -- 待新增...
}

--[[ 常用縮放比例 ]]
CommItem.Scales = {
    large = 1.2,
    original = 1, 
    regular = 0.86,
    small = 0.63,
    icon = 0.5,
}

function CommItem:new ()

    local inst = {}

    --[[ 容器 ]]
    inst.container = nil

    --[[ UI檔 ]]
    inst.CCBI_FILE = "CommItem.ccbi"

    --[[ 最大星數 ]]
    inst.MAX_STAR = 6

    --[[ 事件:函式對應 ]]
    inst.handlerMap = {
        onHand1 = "onClick_fn"
    }

    inst.quality = 1

    inst.isDisabled = false

    --[[ 當 點擊 ]]
    inst.onClick_fn = function () end

    --[[ 當 呼叫 ]]
    inst.onFunction_fn = function () end

    --[[ 請求建立UI ]]
    function inst:requestUI ()
        if self.container ~= nil then return self.container end

        local slf = self
        
        -- 以 ccbi 建立
        self.container = ScriptContentBase:create(self.CCBI_FILE)
        
        -- 註冊 呼叫 行為
        self.container:registerFunctionHandler(function (eventName, container)
            local funcName = slf.handlerMap[eventName]
            local func = slf[funcName]
            if func then
                func(slf, container)
            else 
                slf.onFunction_fn(eventName, container)
            end
        end)

        -- 初始 隱藏
        self:setShowType(CommItem.ShowType.CLEAR)
        self:setSelected(false)

        return inst.container
    end

    --[[ 重置 ]]
    function inst:reset ()
        self.quality = 1
        self.isDisabled = false
        self:setSelected(false)
    end
    
    --[[ 設置 顯示類型 ]]
    function inst:setShowType (showType, override_visibles)

        local visibles = {
            mStarNode = false,
            mAncientStarNode = false,
            mShader = false,
            mEquipLv = false,
            mNumber1 = false,
            mNumber1_1 = false,
            nameBelowNode = false,
        }

        if showType == CommItem.ShowType.CLEAR then
        
        elseif showType == CommItem.ShowType.NORMAL then

            visibles.mNumber1_1 = true

        elseif showType == CommItem.ShowType.EQUIPMENT then
            
            visibles.mStarNode = true
        
        elseif showType == CommItem.ShowType.SPIRIT then

            visibles.mStarNode = true
            visibles.nameBelowNode = true

        elseif showType == CommItem.ShowType.ANCIENT_EQUIPMENT then

            visibles.mAncientStarNode = true

        elseif showType == CommItem.ShowType.EQUIPMENT_NUM then
            visibles.mNumber1_1 = true
            visibles.mStarNode = true

        elseif showType == CommItem.ShowType.ANCIENT_EQUIPMENT_NUM then
            visibles.mAncientStarNode = true
            visibles.mNumber1_1 = true

        elseif showType == CommItem.ShowType.FATE then
            
            visibles.mStarNode = true
        
        end

        if override_visibles ~= nil then
            for key, val in pairs(visibles) do
                local overVal = override_visibles[key]
                if overVal ~= nil then
                    visibles[key] = overVal
                end
            end
        end

        self:setQuality(self.quality)

        NodeHelper:setNodesVisible(self.container, visibles)
        self.showType = showType
    end
    
    --[[ 設置 數量 ]]
    function inst:setCount (count)
        local text = GameUtil:formatNumber(count)
        NodeHelper:setStringForLabel(self.container, {
            mNumber1 = text,
            mNumber1_1 = text,
        })
    end

    --[[ 設置 等級 ]]
    function inst:setEquipLV (lv)
        NodeHelper:setStringForTTFLabel(self.container, {
            mEquipLv = tostring(lv),
        })
    end

    --[[ 設置 名稱 ]]
    function inst:setName (name)
        NodeHelper:setStringForTTFLabel(self.container, {
            mName1 = name,
        })
    end

    --[[ 設置 圖片 ]]
    function inst:setIcon (iconPath, iconScale)
        local scaleMap = {}
        if iconScale ~= nil then
            scaleMap.mPic = iconScale
        end
        NodeHelper:setSpriteImage(self.container, {
            mPic1 = iconPath
        }, scaleMap)
    end

    --[[ 設置選取中 ]]
    function inst:setSelected (isSelected)
        NodeHelper:setNodesVisible(self.container, {
            selectedNode = isSelected
        })
    end

    --[[ 設置 是否關閉 ]]
    function inst:setDisabled (isDisabled)

        self.isDisabled = isDisabled

        -- 處理 含有不能被var定位的節點的var節點
        local queue = {}
        for idx = 1, self.MAX_STAR do
            local node = self.container:getVarNode("mStar"..tostring(idx))
            if node then queue[#queue+1] = node end
        end
        NodeHelperUZ:setNodesIsGrayRecursive(queue, isDisabled)
        
        -- 處理 可被定位的var節點
        NodeHelper:setNodeIsGray(self.container, {
            mPic1 = isDisabled,
            mFrameShade1 = isDisabled,
        })

        -- NodeHelper:setMenuItemsEnabled(self.container, {
        --     mHand1 = not isDisabled
        -- })
        self:setQuality(self.quality)
    end

    --[[ 設置 星數 ]]
    function inst:setStar (star)
        local visibles = {}
        for idx = 1, inst.MAX_STAR do
            visibles["mStar"..tostring(idx)] = (idx == star)
        end
        NodeHelper:setNodesVisible(self.container, visibles)
    end

    --[[ 設置 品質(稀有度) ]]
    function inst:setQuality (quality)
        self.quality = tonumber(quality)
        local GameConfig = require("GameConfig")
        local node2Img = {
            ["mFrameShade1"] = GameConfig.QualityImageBG[self.quality],
        }

        local frameQuality = self.quality
        if self.isDisabled then frameQuality = 1 end
        local node2MenuItem = {
            ["mHand1"] = {
                ["normal"] = GameConfig.QualityImageFrame[frameQuality],
            },
        }
        NodeHelper:setSpriteImage(self.container, node2Img)
        NodeHelper:setMenuItemImage(self.container, node2MenuItem)
    end


    --    ###    ##     ## ########  #######     ######  ######## ######## 
    --   ## ##   ##     ##    ##    ##     ##   ##    ## ##          ##    
    --  ##   ##  ##     ##    ##    ##     ##   ##       ##          ##    
    -- ##     ## ##     ##    ##    ##     ##    ######  ######      ##    
    -- ######### ##     ##    ##    ##     ##         ## ##          ##    
    -- ##     ## ##     ##    ##    ##     ##   ##    ## ##          ##    
    -- ##     ##  #######     ##     #######     ######  ########    ##    


    --[[ 自動設置 (以物品字串) ]]
    function inst:autoSetByItemStr (itemStr, isAutoShowType)
        local itemInfo = InfoAccesser:getItemInfoByStr(itemStr)
        if itemInfo == nil then print("ItemInfo["..tostring(itemStr).."] not exist") end
        self:autoSetByItemInfo(itemInfo, isAutoShowType)
    end

    --[[ 自動設置 (以物品資訊) ]]
    function inst:autoSetByItemInfo (itemInfo, isAutoShowType)
        if itemInfo == nil then return end
        if isAutoShowType == nil then isAutoShowType = true end
        
        local itemIconCfg = InfoAccesser:getItemIconCfg(itemInfo.type, itemInfo.id, "CommItem")

        self:reset() -- 重置
        
        local showType = CommItem.ShowType.NORMAL

        if itemInfo.itemType == (Const_pb.EQUIP*10000) then
            showType = CommItem.ShowType.EQUIPMENT

        elseif itemInfo.type == Const_pb.BADGE then
            showType = CommItem.ShowType.FATE
        -- TODO
        -- elseif itemInfo.itemType == (Const_pb.TOOL*10000) then

        end

        if itemInfo.icon ~= nil then
            local scale = nil
            if itemIconCfg ~= nil then
                scale = itemIconCfg.scale
            end
            self:setIcon(itemInfo.icon, scale)
        end


        if itemInfo.count ~= nil then
            self:setCount(itemInfo.count)
        end

        if itemInfo.quality ~= nil then
            self:setQuality(itemInfo.quality)
        end
        
        if itemInfo.star ~= nil then
            self:setStar(itemInfo.star)
        end

        if showType ~= nil and isAutoShowType == true then
            self:setShowType(showType)
        end

        self:setQuality(self.quality)
        self.showType = showType

        local showPoint = false
        itemInfo.id = itemInfo.id or itemInfo.itemId
        if self.isInventory and InfoAccesser:getIsAncientWeaponSoul("30000_" .. itemInfo.id .. "_1") then
            showPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.PACKAGE_AW_ICON, itemInfo.id)
        end
        NodeHelper:setNodesVisible(self.container, { ["mPoint"] = showPoint })
    end

    --[[ 自動設置 以裝備ID ]]
    function inst:autoSetByEquipID(userEquipID)
        self:reset() -- 重置
        
        local container = inst.container

        local userEquip = UserEquipManager:getUserEquipById(userEquipID);
        local equipId = userEquip.equipId;
        local displayLevel, strengthLevel
        local level = EquipManager:getLevelById(equipId) --裝備等級
        local strength = userEquip.strength + 1; --強化等級(初始是0, 顯示要為1, 故需+1)
        if tonumber(level) > 100 then
            displayLevel = common:getLanguageString("@NewLevelStr", math.floor(level / 100), tonumber(level) -100)       
        else
            displayLevel = common:getLanguageString("@LevelStr", level)       
        end
    
        if tonumber(strength) > 100 then      
            strengthLevel = common:getLanguageString("@NewLevelStr", math.floor(strength / 100), tonumber(strength) -100)
        else       
            strengthLevel = common:getLanguageString("@LevelStr", strength)
        end
    
        NodeHelper:setStringForLabel(container, { ["mEquipLv"] = strengthLevel }); --NodeHelper:setStringForLabel(container, { ["mEquipLv"] = displayLevel });
    
        local lb2Str = {
            ["mName1"] = common:getLanguageString(EquipManager:getNameById(equipId)),
            --["mLvNUm" .. index] = userEquip.strength == 0 and "" or "+" .. userEquip.strength
        }
        local nodesVisible = { }
        local sprite2Img = { ["mPic1"] = EquipManager:getIconById(equipId) }
        local scaleMap = { }
        local aniVisible = UserEquipManager:isGodly(userEquip.id)

        local quality = EquipManager:getQualityById(equipId)
        local equipCfg = ConfigManager.getEquipCfg()
        self.starLevel = equipCfg[userEquip.equipId].stepLevel
        self.quality = quality
    
        nodesVisible["mAni1"] = aniVisible
        nodesVisible["mNumber1"] = false
        nodesVisible["mNFT"] = EquipManager:getEquipCfgById(userEquip.equipId).isNFT == 1
    
        NodeHelper:setStringForLabel(container, lb2Str)
    
        scaleMap["mPic1"] = GameConfig.EquipmentIconScale
        NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    
        NodeHelper:setQualityFrames(container, { ["mHand1"] = quality })
        NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade1"] = quality })
        NodeHelper:setNodesVisible(container, nodesVisible)
    
        local textColor = ConfigManager.getQualityColor()[quality].textColor
        if userEquip.equipId >= 10000 then    --專武星數特別顯示
            NodeHelper:setNodesVisible(container, { ["mStarNode"] = false, ["mAncientStarNode"] = true })
            for i = 1, 13 do
                NodeHelper:setNodesVisible(container, { ["mAncientStar" .. i] = (i == self.starLevel) })
            end
        else
            NodeHelper:setNodesVisible(container, { ["mStarNode"] = true, ["mAncientStarNode"] = false })
            for i = 1, 6 do
                NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == self.starLevel) })
            end
        end
        NodeHelper:setColorForLabel(container, { ["mName1"] = textColor })
    
        NodeHelper:addEquipAni(container, "mAni1", aniVisible, nil, userEquip)
    
        NodeHelper:setNodesVisible(container, { ["mEquipLv"] = false });
        NodeHelper:setNodesVisible(container, { ["mShader"] = false });
        NodeHelper:setNodesVisible(container, { ["mName1"] = false });
        NodeHelper:setNodesVisible(container, { ["mNumber1_1"] = false });
        NodeHelper:setNodesVisible(container, { ["mPoint"] = false });

        self:setQuality(self.quality)
        if userEquip.equipId >= 10000 then    --專武星數特別顯示
            self:setShowType(CommItem.ShowType.ANCIENT_EQUIPMENT)
        else
            self:setShowType(CommItem.ShowType.EQUIPMENT)
        end
    end

    --[[ 自動設置 以 符石資料 ]]
    function inst:autoSetByFateData (fateData)
        if not fateData then return end
        
        self:reset() -- 重置
        
        local container = inst.container
        
        local conf = fateData:getConf()
        local str = conf.name

        local quality = conf.rare
        self.quality = quality

        NodeHelper:setBlurryString(container, "mName1", str, GameConfig.BlurryLineWidth, 5)
        NodeHelper:setSpriteImage(container, { ["mPic1"] = conf.icon });
        NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade1"] = quality });
        NodeHelper:setQualityFrames(container, { ["mHand1"] = quality });
        NodeHelper:setNodesVisible(container, { ["mAni1"] = false, ["mNumber1"] = true ,["mLock"] = fateData.lock == 1 })
        NodeHelper:setNodesVisible(container, { ["mPoint"] = false });

    
        local textColor = ConfigManager.getQualityColor()[quality].textColor
        NodeHelper:setColorForLabel(container, { ["mName1"] = textColor })
    
        local visibleMap = { }
    
        NodeHelper:setNodesVisible(container, visibleMap)
    
        NodeHelper:setNodesVisible(container, { ["mStarNode"] = true, ["mAncientStarNode"] = false })
        for i = 1, 6 do
            NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == conf.star) })
        end
    
        NodeHelper:setNodesVisible(container, { ["mEquipLv"] = false });
        NodeHelper:setNodesVisible(container, { ["mShader"] = false });
        NodeHelper:setNodesVisible(container, { ["mName1"] = false });
        NodeHelper:setNodesVisible(container, { ["mNumber1_1"] = false });

        self:setQuality(quality)

    end

    return inst
end

return CommItem
