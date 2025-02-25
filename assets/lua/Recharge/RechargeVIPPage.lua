
--[[ 
    name: RechargeVipPage
    desc: 充值相關 VIP頁面
    author: youzi
    update: 2023/6/1 15:04
    description: 
--]]

local thisPageName = "Recharge.RechargeVIPPage"

local HP_pb = require("HP_pb") -- 包含协议id文件

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local PathAccesser = require("Util.PathAccesser")
local InfoAccesser = require("Util.InfoAccesser")
local TimeDateUtil = require("Util.TimeDateUtil")

local RechargeDataMgr = require("Recharge.RechargeDataMgr")

-- 字典 (若有將Recharge.lang轉寫入Language.lang中可移除此處與Recharge.lang)
--__lang_loaded = __lang_loaded or {}
--if not __lang_loaded["Lang/Recharge.lang"] then
--    __lang_loaded["Lang/Recharge.lang"] = true
--    Language:getInstance():addLanguageFile("Lang/Recharge.lang")
--end

----这里是协议的id
local opcodes = {

}

local option = {
    ccbiFile = "RechargeVIP.ccbi",
    handlerMap = {
        onClose = "onCloseBtn",
        onPreviousBtn = "onPreviousBtn",
        onNextBtn = "onNextBtn",
        onRechargeBtn = "onRechargeBtn",
        onVIPBundleBtn = "onVIPBundleBtn",
    },
    opcode = opcodes
}

--[[ 

    text
        @RechargeVIP_Title : 主標題
        @RechargeVIP_RechargeBtn : 充值按鈕
        @RechargeVIP_VIPBundleBtn : VIP禮包按鈕
    
    var 
        levelIconImg : VIP等級圖標
        expBarNode : 經驗進度條容器
        expBar : 經驗進度條
        expNumText : 經驗進度數字
        textContentNode : 文字內容容器
        textContentScrollView : 文字內容滾動視圖
        previousBtnNode : 上一頁按鈕容器
        nextBtnNode : 下一頁按鈕容器

    event
        onRechargeBtn : 當充值按下
        onVIPBundleBtn : 當VIP禮包按下
        onPreviousBtn : 當 上一頁 按下
        onNextBtn : 當 下一頁 按下

 ]]

local Recharge_VipPage = {}

Recharge_VipPage.singleton = nil

function Recharge_VipPage:new ()

    local inst = {}

    Recharge_VipPage.singleton = inst

    --[[ 容器 ]]
    inst.container = nil

    --[[ 當 關閉 行為 ]]
    inst.onceClose_fn = nil

    --[[ 當前頁數 ]]
    inst.vipPageIdx = nil

    inst.onRechargeBtn_fn = nil
    inst.onVIPBundleBtn_fn = nil

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

        -- if opcode == HP_pb.XXXXXXXX then
        --     local msg = XXXXXXXXXX
        --     msg:ParseFromString(msgBuff)
        
        --     return
        -- end
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

        -- print("Recharge_VipPage.onEnter")
        
        -- 註冊 封包相關
        inst:registerPacket(container)

        -- 初始化 文字內容滾動視圖
        NodeHelper:initScrollView(container, "textContentScrollView", 3);

        -- 預設 頁數 等同 當前VIP等級
        inst.vipPageIdx = UserInfo.playerInfo.vipLevel

        inst:refreshPage()
    end

    --[[ 當 頁面 離開 ]]
    function inst:onExit(container)
        inst:removePacket(container)
        onUnload(thisPageName, container)
    end


    --[[ 當 關閉 按下 ]]
    function inst:onCloseBtn()
        -- 清理列表
        NodeHelper:clearScrollView(inst.container)
        -- 關閉 頁面
        PageManager.popPage(thisPageName)
    
        -- 若 有關閉行為 則 呼叫
        if inst.onceClose_fn then
            inst.onceClose_fn()
            inst.onceClose_fn = nil
        end
    end

    --[[ 當 上一頁 按下 ]]
    function inst:onPreviousBtn ()
        inst.vipPageIdx = inst.vipPageIdx - 1
        if inst.vipPageIdx < 0 then
            inst.vipPageIdx = UserInfo.playerInfo.vipLevel
        end
        inst:refreshPage()
    end
    
    --[[ 當 下一頁 按下 ]]
    function inst:onNextBtn ()
        inst.vipPageIdx = inst.vipPageIdx + 1
        local vipTable = ConfigManager.getVipCfg()
        if inst.vipPageIdx > #vipTable then
            inst.vipPageIdx = 1
        end
        inst:refreshPage()
    end

    --[[ 當 充值按鈕 按下 ]]
    function inst:onRechargeBtn ()
         PageManager.popPage(thisPageName)
         require("IAP.IAPPage"):selectSubPage("Diamond")
           --PageManager.pushPage("IAP.IAPPage")
        --if inst.onRechargeBtn_fn ~= nil then
        --    inst:onRechargeBtn_fn()
        --else
        --    PageManager.popPage(thisPageName)
        --    --PageManager.pushPage("Recharge.RechargePage")
        --end
    end

    --[[ 當 VIP禮包按鈕 按下 ]]
    function inst:onVIPBundleBtn ()
        --if inst.onVIPBundleBtn_fn ~= nil then
        --    inst:onVIPBundleBtn_fn()
        --else
            PageManager.popPage(thisPageName)
            require("IAP.IAPPage"):selectSubPage ("Recharge")
            --PageManager.pushPage("IAP.IAPPage")
        --end
    end


    function inst:refreshPage () 
        
        UserInfo.sync()

        local levelInfo = InfoAccesser:getVIPLevelInfo()
        inst:setLevelAndExp(levelInfo.level, levelInfo.exp, levelInfo.expMax)

        -- 若只能看當前
        -- if inst.vipPageIdx > levelInfo.level then
        --     inst.vipPageIdx = levelInfo.level
        -- end

        inst:refreshVIPContent()
    end

    function inst:refreshVIPContent ()
        local vipTable = ConfigManager.getVipCfg()
        NodeHelper:setNodesVisible(container, {
            previousBtnNode = inst.vipPageIdx > 1,
            nextBtnNode = inst.vipPageIdx < #vipTable
        })
        NodeHelper:setSpriteImage(inst.container, {
            -- TODO : 可能之後改從GameConfig或其他ImagePath工具去找圖路徑
            levelIconImg = PathAccesser:getVIPIconPath(inst.vipPageIdx)
        })
        local contentStr = inst:getVIPContentStr()
        
        inst:clearAndBuildVIPScrollView(contentStr)
    end

    function inst:getVIPContentStr ()
        local vipCfg = ConfigManager.getVipCfg()

        local curVipInfo = vipCfg[inst.vipPageIdx]
        local previousVipInfo = vipCfg[inst.vipPageIdx - 1]

        local code2Val = {}

        -- 資料 ---

        -- 累計購買
        if Golb_Platform_Info.is_r18 then --R18
            code2Val[200] = curVipInfo["useHoneyP"]
        elseif Golb_Platform_Info.is_jgg then --JGG
            code2Val[199] = curVipInfo["useUSD"] * GameConfig.jggPriceRatio
        else
            code2Val[201] = curVipInfo["buyDiamon"]
        end
        -- 最大掛機時間
        local idleTime = curVipInfo["idleTime"]
        if idleTime > 0 then
            code2Val[202] = idleTime / 3600 -- 小時
        end
        -- 掛機經驗與金幣獲得加成
        local idleRatio = curVipInfo["idleRatio"]
        if idleRatio > 0 then
            code2Val[203] = (idleRatio - 1) * 100
        end
        -- 每日可兌換金幣次數
        code2Val[204] = curVipInfo["buyCoinTime"]
        -- 每日可快速戰鬥次數
        code2Val[205] = curVipInfo["fastFightTime"]
        -- 每日可購買挑戰地下城次數
        code2Val[206] = curVipInfo["multiEliteCanPurchaseTimes"]
        -- 每日可派遣次數
        code2Val[207] = curVipInfo["yongbingyuanzhengTime"]
        -- 秘密信條累積次數
        code2Val[208] = curVipInfo["PowerLimit"]
        -- 秘密信條發送冷卻
        code2Val[209] = curVipInfo["PowerRecover"]
        --if msgCD > 0 then
        --    code2Val[209] = msgCD / 60 -- 分
        --end
        -- 開放種族召喚保底
        --code2Val[210] = inst.vipPageIdx >= 5

        -- 顯示 ---

        -- 轉換為資料
        local codeDatas = {}
        for code, val in pairs(code2Val) do
            codeDatas[#codeDatas+1] = {
                ["code"] = code,
                ["val"] = val,
            }
        end

        -- 排序
        table.sort(codeDatas, function (a, b)
            return a.code < b.code
        end)

        -- 內文
        local contentStr = ""

        for idx, data in ipairs(codeDatas) do while true do
            
            if data.val == nil then break end -- continue
            
            local strTemplate = FreeTypeConfig[data.code]
            if strTemplate == nil then break end -- continue

            local str = nil

            local typ = type(data.val)

            -- 依照類型 填入內容
            if typ == "number" then
                if data.val > 0 then
                    str = common:getGsubStr({data.val}, strTemplate.content)
                end
            elseif typ == "boolean" then
                if data.val == true then
                    str = strTemplate.content
                end
            elseif typ == "string" then
                str = data.val
            end

            if str ~= nil then
                contentStr = contentStr .. str
            end

        break end end

        -- 特殊防錯
        contentStr = string.gsub(contentStr, "</ font>", "</font>")

        return contentStr
    end

    function inst:getVIPContentStr_last ()

        local vipTable = ConfigManager.getVipCfg()
        -- dump(vipTable, "vipTable")
        local curVipInfo = vipTable[inst.vipPageIdx]
        local previousVipInfo = vipTable[inst.vipPageIdx - 1]

        local vipTrain = common:getLanguageString("@VipTrain" .. curVipInfo["maxMercenaryTime"])
        local hasBossMopUp = curVipInfo["hasBossMopUp"]
        local strBossMopUp = ""
        local strBossMopUpFirst = false
        -- 首次有权限特殊处理
        local hasUnionBoss = curVipInfo["hasUnionBoss"]
        local expBuffer = curVipInfo["expBuffer"]
        local jihuoTaishici = curVipInfo["jihuoTaishici"]
        local strUnionBoss = ""
        local strUnionBossFirst = false
        local strJihuoTaishici = ""
        local strJihuoTaishiciFirst = false
        local bossSkip = curVipInfo["bossSkip"]
        local strBossSkip = ""
        local bossSkipFirst = false
        local isGVENormalHangUp = ""
        local isGVEHighHangUp = ""
        local isArtifactBodyHold = ""
        local strUseSeniorTtraing = ""
        local mCanUseSeniorTraingNormalShow = curVipInfo["canUseSeniorTraing"];
        local mCanUseSeniorTraingSpecialShow = false;
        if hasBossMopUp == 0 then
            strBossMopUp = false
        elseif previousVipInfo and previousVipInfo["hasBossMopUp"] == 0 then
            strBossMopUp = false
            strBossMopUpFirst = true
        end
        if hasUnionBoss == 0 then
            strUnionBoss = false
        elseif previousVipInfo and previousVipInfo["hasUnionBoss"] == 0 then
            strUnionBoss = false
            strUnionBossFirst = true
        end
        if jihuoTaishici == 0 then
            strJihuoTaishici = false
        elseif previousVipInfo and previousVipInfo["jihuoTaishici"] == 0 then
            strJihuoTaishici = false
            strJihuoTaishiciFirst = true
        end

        if mCanUseSeniorTraingNormalShow == 0 then
            strUseSeniorTtraing = false
        elseif previousVipInfo and previousVipInfo["canUseSeniorTraing"] == 0 then
            strUseSeniorTtraing = false
            mCanUseSeniorTraingSpecialShow = true
        end

        if bossSkip == 0 then
            strBossSkip = false
        elseif previousVipInfo and previousVipInfo["bossSkip"] == 0 then
            bossSkipFirst = true
            strBossSkip = false
        end
        local vipCode2ArgRange = { start = 201, last = 218}
        local vipCode2Arg = {
            -- 累计购买
            [201] = curVipInfo["buyDiamon"],

            [202] = expBuffer,
            [203] = curVipInfo["buyCoinTime"],
            -- 金币购买次数
            [204] = curVipInfo["fastFightTime"],
            -- 快速挑战
            [205] = curVipInfo["buyBossFightTime"],
            -- boss挑战券购买
            [206] = curVipInfo["buyEliteFightTime"],
            -- 精英副本购买次数
            [207] = curVipInfo["multiEliteCanPurchaseTimes"],
            -- 花嫁道場購買次數
            [208] = vipTrain,
            -- 佣兵培养最高等级
            [209] = curVipInfo["yongbingyuanzhengTime"],
            -- 佣兵远征次数
            [210] = tonumber(curVipInfo["shopItemCount"]) - GameConfig.Default.ShopItemNum,
            -- 商品购买次数
            [211] = strBossMopUp,
            -- 可使用BOSS扫荡功能
            [212] = strUnionBoss,
            -- 公会boss自动参加
            [213] = strJihuoTaishici,
            -- 太史慈
            [214] = strBossSkip,
            -- boss跳过
            [215] = isGVENormalHangUp,
            -- GVE普通挂机		
            [216] = isGVEHighHangUp,
            -- GVE高级挂机
            [217] = strUseSeniorTtraing,
            -- 神器本体保留
            [218] = isArtifactBodyHold,
        }

        if Golb_Platform_Info.is_r18 then --R18
            -- 累计购买
            vipCode2Arg[201] = curVipInfo["useHoneyP"]
        elseif Golb_Platform_Info.is_jgg then --JGG
            vipCode2Arg[201] = curVipInfo["useUSD"] * GameConfig.jggPriceRatio
        end

        -- 內文
        local contentStr = ""

        -- 1. 固定添加
        if strBossMopUpFirst then
            contentStr = contentStr .. FreeTypeConfig[241].content
        end
        if strUnionBossFirst then
            contentStr = contentStr .. FreeTypeConfig[242].content
        end

        if strJihuoTaishiciFirst then
            contentStr = contentStr .. FreeTypeConfig[243].content
        end
        if bossSkipFirst then
            contentStr = contentStr .. FreeTypeConfig[244].content
        end
        if mCanUseSeniorTraingSpecialShow then
            contentStr = contentStr .. FreeTypeConfig[247].content
        end
        if curVipInfo["gveNormalHangUp"] == 1 and previousVipInfo and previousVipInfo["gveNormalHangUp"] == 0 then
            contentStr = contentStr .. FreeTypeConfig[245].content
            isGVENormalHangUp = false
        elseif curVipInfo["gveNormalHangUp"] == 0 then
            isGVENormalHangUp = false
        end
        if curVipInfo["gveHighHangUp"] == 1 and previousVipInfo and previousVipInfo["gveHighHangUp"] == 0 then
            isGVEHighHangUp = false
            contentStr = contentStr .. FreeTypeConfig[246].content
        elseif curVipInfo["gveHighHangUp"] == 0 then
            isGVEHighHangUp = false
        end
        if curVipInfo["artifactBodyHold"] == 1 and previousVipInfo and previousVipInfo["artifactBodyHold"] == 0 then
            isArtifactBodyHold = false
            --contentStr = contentStr .. FreeTypeConfig[248].content
        elseif curVipInfo["artifactBodyHold"] == 0 then
            isArtifactBodyHold = false
        end

        -- 改变以后重新赋值
        vipCode2Arg[214] = isGVENormalHangUp
        -- GVE普通挂机		
        vipCode2Arg[215] = isGVEHighHangUp
        -- GVE高级挂机
        vipCode2Arg[217] = strUseSeniorTtraing

        -- 2. 依照陣列資料添加

        -- 神器本体保留
        for code = vipCode2ArgRange.start, vipCode2ArgRange.last do
            -- local labText = container:getVarLabelBMFont("mPrivilegeTex" .. i)
            -- if labText ~= nil then
            
            -- 參數數值
            local argVal = vipCode2Arg[code]
            -- 語句模板
            local template = FreeTypeConfig[code]

            -- 檢測
            if template == nil then
                print("FreeTypeConfig["..tostring(code).."] is not exist")
            end

            -- 若 都存在 則
            if argVal and argVal ~= 0 and template ~= nil then

                -- 平台 特例轉換code
                if code == 201 then
                    if Golb_Platform_Info.is_r18 then --R18
                       code = 200
                    elseif Golb_Platform_Info.is_jgg then --JGG
                        code = 199
                    end 
                end
                contentStr = contentStr .. common:getGsubStr( { argVal }, template.content)
                -- local nameNode = container:getVarNode("mEquipmentName")
                -- local HtmlNode = NodeHelper:addHtmlLable(labText, contentStr, tag);
            end
            -- end
        end

        -- 特殊防錯
        contentStr = string.gsub(contentStr, "</ font>", "</font>")

        return contentStr
    end

    function inst:clearAndBuildVIPScrollView(str)

        local container = inst.container

        -- clear
        if container.m_pScrollViewFacade then
            container.m_pScrollViewFacade:clearAllItems();
        end
        if container.mScrollViewRootNode then
            container.mScrollViewRootNode:removeAllChildren();
        end
        -- build
        local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
        local iCount = 0
        local fOneItemHeight = 0
        local fOneItemWidth = 0

        local i = 1
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)

        if iCount < iMaxNode then
            local pItem = ScriptContentBase:create("GeneralHelpContent.ccbi")

            pItem.id = iCount

            local itemHeight = 0

            local nameNode = pItem:getVarLabelTTF("mLabel")
            local cSize = NodeHelper:setCCHTMLLabelDefaultPos(nameNode, CCSize(540, 150), str):getContentSize()

            if fOneItemHeight < cSize.height then
                fOneItemHeight = cSize.height
            end

            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width
            end
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        iCount = iCount + 1

        local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount)
        container.mScrollView:setContentSize(size)
        container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
        container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
        container.mScrollView:forceRecaculateChildren()
        ScriptMathToLua:setSwallowsTouches(container.mScrollView)
    end


    --[[ 設置 等級 與 經驗 ]]
    function inst:setLevelAndExp (lvNum, expNum, expMax)

        NodeHelper:setSpriteImage(inst.container, {
            -- TODO : 可能之後改從GameConfig或其他ImagePath工具去找圖路徑
            levelIconImg = PathAccesser:getVIPIconPath(lvNum)
        })

        NodeHelper:setStringForLabel(inst.container, {
            expNumText = tostring(expNum).."/"..tostring(expMax)
        })
        
        local expBarParentNode = inst.container:getVarNode("expBarNode")
        local expBar = inst.container:getVarScale9Sprite("expBar")
        
        local size = expBarParentNode:getContentSize()
        local minWidth = expBar:getInsetLeft() + expBar:getInsetRight()
        local scaleX = 1
        size.width = size.width * (expNum/expMax)
        if size.width < minWidth then
            scaleX = size.width / minWidth
        end
        expBar:setContentSize(size)
        expBar:setScaleX(scaleX)

    end
    

    return inst
end

local CommonPage = require('CommonPage')
return CommonPage.newSub(Recharge_VipPage.new(), thisPageName, option)