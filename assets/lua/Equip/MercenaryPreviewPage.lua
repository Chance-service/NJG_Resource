
----------------------------------------------------------------------------------
local HP_pb = require("HP_pb");
local RoleOpr_pb = require("RoleOpr_pb")
local EquipScriptData = require("EquipScriptData")
local thisPageName = "MercenaryPreviewPage"
local NodeHelper = require("NodeHelper");
local UserMercenaryManager = require("UserMercenaryManager")
local MercenaryPreviewPage = {}
local MercenaryContent = {
    ccbiFile = "MercenaryCallContent.ccbi",
}
local MercenaryRoleInfos = {} -- 数据包
local option = {
	ccbiFile = "MercenaryCallPopUp.ccbi",
	handlerMap = {
		onClose		        = "onClose",
		onHelp				= "onHelp"
	},
    opcodes = {
        ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
        ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
        ROLE_EMPLOY_C = HP_pb.ROLE_EMPLOY_C,
        ROLE_EMPLOY_S = HP_pb.ROLE_EMPLOY_S,
    }
}


function MercenaryPreviewPage:onEnter( container )

    -- 初始化当前排名ScrollView
    NodeHelper:initScrollView(container, "mContent", 6)
     --获取佣兵列表信息
     self:registerPacket(container)
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
end
function MercenaryPreviewPage:onExit(container)
    NodeHelper:deleteScrollView(container);
	self:removePacket(container)
end
function MercenaryPreviewPage:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function MercenaryPreviewPage:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function MercenaryPreviewPage:refreshPreviewPage(container)

end
--接收服务器回包
function MercenaryPreviewPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
		msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        self:rebuildAllItem(container)
    elseif opcode == HP_pb.ROLE_EMPLOY_S then
		local msg = RoleOpr_pb.HPRoleEmploy();
        msg:ParseFromString(msgBuff);
        local roleId = msg.roleId
        local roleInfo = UserMercenaryManager:getUserMercenaryById(roleId)
		if roleInfo then
			local curMercenaryCfg = ConfigManager.getRoleCfg()[roleInfo.itemId]
			if curMercenaryCfg then
				MessageBoxPage:Msg_Box(common:getLanguageString("@RoleReward",curMercenaryCfg.name))
			end
		end
    end
end
function MercenaryPreviewPage:rebuildAllItem(container)
    self:clearAllItem(container);
	self:buildItem(container);
end

function MercenaryPreviewPage:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

function MercenaryPreviewPage:buildItem(container)
    
    local size = #MercenaryRoleInfos
    NodeHelper:buildScrollView(container,size, MercenaryContent.ccbiFile, MercenaryContent.onFunction);
end

function MercenaryPreviewPage:onClose( container )

    PageManager.popPage(thisPageName);
end

function MercenaryContent.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		MercenaryContent.onRefreshItemView(container);
    elseif eventName == "onMercenaryCall" then
        MercenaryContent.onMercenaryCall(container);
    elseif eventName == "onHand" then
        MercenaryContent.onHand(container);
    end
end
function MercenaryContent.onHand(container)
    local index = tonumber(container:getItemDate().mID)
    local dataInfo = MercenaryRoleInfos[index];
    local curMercenary = UserMercenaryManager:getUserMercenaryById(dataInfo.roleId)
    local showTips = common:getLanguageString("@MercenaryTips_"..curMercenary.itemId);
    local itemInfo = {
            type 	= 70000,
            itemId	= tonumber(curMercenary.itemId),
            count 	= 1
        }
    GameUtil:showTip(container:getVarNode("mSkillPic1"), itemInfo)
end

function MercenaryContent.onMercenaryCall(container)
    local index = tonumber(container:getItemDate().mID)
    local dataInfo = MercenaryRoleInfos[index];
    local curMercenary = UserMercenaryManager:getUserMercenaryById(dataInfo.roleId)
    local itemCfg = ConfigManager.getRoleCfg()[curMercenary.itemId]
    if dataInfo.roleStage == 0 then --未解禁
        if itemCfg.jumpValue ~= "NULL" then --跳转
            if tonumber(itemCfg.jumpValue) == 99 then
                MessageBoxPage:Msg_Box_Lan("@RoleActivityTxt")
            else
                local PageJumpMange = require("PageJumpMange")
                PageJumpMange.JumpPageById(tonumber(itemCfg.jumpValue))
            end
        end
    elseif dataInfo.roleStage == 1 then --已激活状态
      
    else -- 可激活
        local msg = RoleOpr_pb.HPRoleEmploy()
        msg.roleId = dataInfo.roleId
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.ROLE_EMPLOY_C, pb, #pb, true)
    end

end

function MercenaryContent.onRefreshItemView(container)
    local index = tonumber(container:getItemDate().mID)
    local dataInfo = MercenaryRoleInfos[index];
    local curMercenary = UserMercenaryManager:getUserMercenaryById(dataInfo.roleId)
    local itemCfg = ConfigManager.getRoleCfg()[curMercenary.itemId]
    local spriteImage = {}
    local meuItemImage = {}
    local labelText = {}
    local nodeVisble = {}
    --itemCfg.icon
    --itemCfg.name
    --itemCfg.condition 条件
    --UI/Common/Button/Btn_CommonContent_Blue.png
    --UI/Common/Button/Btn_CommonContent_Grey.png
    --UI/Common/Button/Btn_CommonContent_Red.png
    labelText["mMercenaryName"] = itemCfg.name
    labelText["mSkillTex1"] = itemCfg.condition
    spriteImage["mSkillPic1"] = itemCfg.icon
    meuItemImage["mPicFrame"] = GameConfig.QualityImage[tonumber(itemCfg["quality"])+16];
    --spriteImage["mPicFrame"] = GameConfig.QualityImage[tonumber(itemCfg["quality"])]; 
    if dataInfo.roleStage == 0 then --未解禁
        if itemCfg.jumpValue == "NULL" then --未解禁
            labelText["mBtnTxt"] = common:getLanguageString("@MercenaryCallBtnTxt1")
            meuItemImage["mMercenaryCallBtn"] = "UI/Common/Button/Btn_CommonContent_Grey.png"
        else--跳转
            labelText["mBtnTxt"] = common:getLanguageString("@MercenaryCallBtnTxt4")
            meuItemImage["mMercenaryCallBtn"] = "UI/Common/Button/Btn_CommonContent_Blue.png"
        end
    elseif dataInfo.roleStage == 1 then --已激活状态
        labelText["mBtnTxt"] = common:getLanguageString("@MercenaryCallBtnTxt3")
        meuItemImage["mMercenaryCallBtn"] = "UI/Common/Button/Btn_CommonContent_Grey.png"
    else -- 可激活
        labelText["mBtnTxt"] = common:getLanguageString("@MercenaryCallBtnTxt2")
        meuItemImage["mMercenaryCallBtn"] = "UI/Common/Button/Btn_CommonContent_Red.png"
    end

    if tonumber(itemCfg.costType) == 1 then -- 进度条类型
        nodeVisble["mSkillTex1"] = false
        nodeVisble["mBarNode"] = true
        labelText["mBarTxt"] = dataInfo.soulCount.."/"..dataInfo.costSoulCount
        local barNode = container:getVarScale9Sprite("mBar")
        local curPercent = dataInfo.soulCount/dataInfo.costSoulCount;
        if curPercent > 1.0 then curPercent = 1.0 end
        barNode:setScaleX(curPercent);
    else
        nodeVisble["mSkillTex1"] = true
        nodeVisble["mBarNode"] = false
    end
    NodeHelper:setNormalImages(container, meuItemImage)
    NodeHelper:setSpriteImage(container, spriteImage );
    NodeHelper:setStringForLabel(container, labelText);
    NodeHelper:setNodesVisible(container, nodeVisble);
end


-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
MercenaryPreviewPage = CommonPage.newSub(MercenaryPreviewPage, thisPageName, option)