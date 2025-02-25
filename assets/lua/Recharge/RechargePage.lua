
--[[ 
    name: RechargePage
    desc: 充值頁面
    author: youzi
    update: 2023/6/5 11:31
    description: 
--]]

local thisPageName = "Recharge.RechargePage"

local HP_pb = require("HP_pb") -- 包含协议id文件
require "Recharge_pb"

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local CommTabStorage = require("CommComp.CommTabStorage")
local ShopDataMgr = require("Shop.ShopDataMgr")
local RechargeDataMgr = require("Recharge.RechargeDataMgr")
local BuyManager = require("BuyManager")


-- 字典 (若有將Recharge.lang轉寫入Language.lang中可移除此處與Recharge.lang)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/Recharge.lang"] then
--    __lang_loaded["Lang/Recharge.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/Recharge.lang")
--end

----这里是协议的id
local opcodes = {
    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
}

local option = {
    ccbiFile = "EmptyPage.ccbi",
    handlerMap = {},
    opcode = opcodes
}
 
local RechargePage = {}

--[[ 
    text
        @RechargeVIP_Title : 主標題
        @RechargeVIP_RechargeBtn : 充值按鈕
        @RechargeVIP_VIPBundleBtn : VIP禮包按鈕
    
    var 
        contentNode 內容 容器 (子分頁)
        topNode 上層 容器 (分頁列)

    event
        onVIPHelpBtn : 當VIP說明按鈕 按下
--]]


function RechargePage:new ()

    local inst = {}

    --[[ 容器 ]]
    inst.container = nil

    --[[ 分頁列 ]]
    inst.tabStorage = nil

    --[[ 當前子頁面資料 ]]
    inst.currentSubPageData = nil

    --[[ 子頁面資料 ]]
    inst.subPageDatas = {}

    --[[ 當 關閉 行為 ]]
    inst.onceClose_fn = nil
    
    --[[ 分頁列節點(容器) ]]
    inst.tabStorageNode = nil
    --[[ 子頁面節點(容器) ]]
    inst.subPageNode = nil


    --[[ 當 收到訊息 ]]
    function inst:onReceiveMessage(container)
        local message = container:getMessage();
        local typeId = message:getTypeId();
        -- if typeId == XXXXXXXXXX then
        --     local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;
        --     if opcode == HP_pb.XXXXXXX then
        --         
        --     end
        -- end
    end

    --[[ 當 收到封包 ]]
    function inst:onReceivePacket(container)
        local opcode = container:getRecPacketOpcode()
        local msgBuff = container:getRecPacketBuffer()

        local packet = {
            opcode = opcode,
            msgBuff = msgBuff,
        }

        -- 分發 至 當前子頁面
        if inst.currentSubPageData.subPage.onReceivePacket ~= nil then
            inst.currentSubPageData.subPage:onReceivePacket(inst, packet)
        end
    end
    
    --[[ 註冊 封包相關 ]]
    function inst:registerPacket(container)
        for key, opcode in pairs(opcodes) do
            if string.sub(key, -1) == "S" then
                container:registerPacket(opcode)
            end
        end
    end
    --[[ 註銷 封包相關 ]]
    function inst:removePacket(container)
        for key, opcode in pairs(opcodes) do
            if string.sub(key, -1) == "S" then
                container:removePacket(opcode);
            end
        end
    end

    --[[ 當 頁面 進入 ]]
    function inst:onEnter (container)
        inst.container = container

        inst.tabStorageNode = inst.container:getVarNode("topNode")
        inst.subPageNode = inst.container:getVarNode("contentNode")

        print("RechargePage.onEnter")
        
        -- 註冊 封包相關
        inst:registerPacket(container)

        -- 準備分頁資訊
        local tabInfos = {}

        for idx, info in ipairs(RechargeDataMgr.SubPageInfos) do
            
            table.insert(tabInfos, {
                iconType = "image",
                icon_normal = info._iconImg_normal,
                icon_selected = info._iconImg_selected,
            })

            table.insert(inst.subPageDatas, {
                scriptPath = info._scriptName,
                subPage = nil,
                container = nil,
            })
        end

        -- 建立 分頁UI ----------------------------

        -- 初始化
        inst.tabStorage = CommTabStorage:new()
        
        inst.tabStorage:setScrollViewOverrideOptions({
            interval = 20
        })

        -- 設置 當 選中分頁
        inst.tabStorage.onTabSelect_fn = function (nextTabIdx, lastTabIdx)
            
            dump(inst.subPageDatas, "inst.subPageDatas")

            -- 目標 子頁面資料
            local nextSubPageData = inst.subPageDatas[nextTabIdx]
            if nextSubPageData == nil then return end
            
            -- 上一個 子頁面資料
            local lastSubPageData = inst.currentSubPageData
            if lastSubPageData ~= nil then

                -- 移除 子頁面
                if lastSubPageData.container ~= nil then
                    inst.subPageNode:removeChild(lastSubPageData.container)
                end
                
                -- 呼叫 當 離開 子頁面
                lastSubPageData.subPage:onExit(inst)
            end

            -- 建立 下個 子頁面資料
            -- 若要緩存可以從這邊改

            print("RechargePage : require subPage : "..nextSubPageData.scriptPath)
            -- 建立 子頁面
            local nextSubPage = require(nextSubPageData.scriptPath).new()
            nextSubPageData.subPage = nextSubPage

            -- 建立 子頁面UI
            nextSubPageData.container = nextSubPage:createPage(inst)
            if nextSubPageData.container ~= nil then
                inst.subPageNode:addChild(nextSubPageData.container)
            end

            -- 呼叫 當 進入 子頁面
            nextSubPage:onEnter(inst)

            inst.currentSubPageData = nextSubPageData
        end

        -- 設置 當 關閉
        inst.tabStorage.onClose_fn = function ()
            inst:onCloseBtn()
        end

        local tabStorageContainer = inst.tabStorage:init(tabInfos)

        inst.tabStorage:setTitle("@Recharge.Title")

        -- 加入UI
        inst.tabStorageNode:addChild(tabStorageContainer)

        -- 預設 選取首個分頁
        inst.tabStorage:selectTab(1)
        
        -- 完成 分頁UI ----------------------------
    end

    --[[ 當 頁面 離開 ]]
    function inst:onExit(container)
        
        inst:removePacket(container)

        inst.currentSubPageData = nil
        inst.subPageDatas = {}

        onUnload(thisPageName, container)
    end


    --[[ 當 關閉 按下 ]]
    function inst:onCloseBtn()
        -- 關閉 頁面
        PageManager.popPage(thisPageName)
    
        -- 若 有關閉行為 則 呼叫
        if inst.onceClose_fn then
            inst.onceClose_fn()
            inst.onceClose_fn = nil
        end
    end

    return inst
end

local CommonPage = require('CommonPage')
return CommonPage.newSub(RechargePage.new(), thisPageName, option)