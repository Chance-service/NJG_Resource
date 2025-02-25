
----------------------------------------------------------------------------------
require "HP_pb"
local thisPageName = "FacebookBindPage"
local FacebookBindPage = {}
local reward = FBBindReward;
local option = {
	ccbiFile = "FB_BindAwardsPopUp.ccbi",
	handlerMap = {
		onCancel = "onCancel",
        onClose = "onCancel",
		onConfirmation = "onOk",
	}
};

-----------------------------------------------
--OfflineAccountPageBase页面中的事件处理
----------------------------------------------
function FacebookBindPage:onCancel(container)
	PageManager.popPage(thisPageName)
end
function FacebookBindPage.onFunction(eventName, container)
	if eventName:sub(1, 7) == "onFrame" then
		local index = tonumber(eventName:sub(-1))
        local resCfg = reward[index];
        if resCfg then
            GameUtil:showTip(container:getVarNode('mRewardNode'..index), {
		        type 		= resCfg.itemType, 
		        itemId 		= resCfg.itemId,
		        buyTip		= false,
		        starEquip	= false
	        });
		end
	end	
end
function FacebookBindPage:onOk(container)
     libPlatformManager:getPlatform():sendMessageG2P("G2P_Friend_List","G2P_Invild_Friend")
     PageManager.popPage(thisPageName)
end

function FacebookBindPage:onEnter(container)
 	FacebookBindPage:refreshPage(container);
end

function FacebookBindPage:onExecute(container)
end
----------------------------------------------------------------

function FacebookBindPage:refreshPage(container)
	
    local nodesVisible = {};
	local lb2Str = {};
	local sprite2Img = {};
	local menu2Quality = {};
	for i = 1, 5 do
		local cfg = reward[i];
		nodesVisible["mRewardNode" .. i] = cfg ~= nil;
        container:getVarNode("mRewardNode" .. i):setTag(i);
		if cfg ~= nil then
			local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.itemType, cfg.itemId, cfg.itemCount);
			if resInfo ~= nil then
				sprite2Img["mPic" .. i] 		= resInfo.icon;
				lb2Str["mNum" .. i]				= "x" .. cfg.itemCount;
				--lb2Str["mName" .. i]			= resInfo.name;
				menu2Quality["mFrame" .. i]		= resInfo.quality
                --html
				NodeHelper:setBlurryString(container,"mName"..i,resInfo.name,GameConfig.LineWidth.ItemNameLength)
				--[[
                local htmlNode = container:getVarLabelBMFont("mName"..i)
				if not htmlNode then htmlNode = container:getVarLabelTTF("mName"..i) end
                if htmlNode then
                    local htmlLabel;--泰语太长 修改htmlLabel的大小
                    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
						 htmlNode:setVisible(false)
                         htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition( htmlNode, CCSize(110,32),resInfo.name )
                         htmlLabel:setScaleX(htmlNode:getScaleX())
                         htmlLabel:setScaleY(htmlNode:getScaleY())
                    end
                end--]]
			else
				CCLuaLog("Error::***reward item not found!!");
			end
		end
	end
	
	NodeHelper:setNodesVisible(container, nodesVisible);
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img);
	NodeHelper:setQualityFrames(container, menu2Quality);
end

----------------click event------------------------
function FacebookBindPage:onClose(container)
	PageManager.popPage(thisPageName);
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local FacebookBindPage = CommonPage.newSub(FacebookBindPage, thisPageName, option,FacebookBindPage.onFunction);