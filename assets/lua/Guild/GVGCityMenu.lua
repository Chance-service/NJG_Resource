local PageManager = require("PageManager")
local GVGManager = require("GVGManager")
local GVG_pb = require("GroupVsFunction_pb")
local thisPageName = "GVGCityMenu"
 
local GVGCityMenu = {
    cityId = 0,
    touchPos = nil,
    container = nil
}

local option = {
    ccbiFile = "GVGCityClickBtn.ccbi",
    opcodes = {
    }
}

local MENU_OFFSET = {
    [1] = {x = 0, y = -100},
    [2] = {x = 0, y = -200},
    [3] = {x = 0, y = -300},
}

function GVGCityMenu.onFunction(eventName, container)
    if GVGCityMenu[eventName] and type(GVGCityMenu[eventName]) == "function" then
        GVGCityMenu[eventName](container)
    end
end

function GVGCityMenu.onBattle(container)
    GVGCityMenu.hide()
    if GVGManager.isOwnCity() then
        GVGManager.reqRoleInfo()
        --PageManager.pushPage("GVGTeamJoinPage")
    else
        if GVGManager.canAtkCity() then
            GVGManager.reqRoleInfo()
            --PageManager.pushPage("GVGTeamJoinPage")    
        elseif GVGManager.canReAtkCity() then
            GVGManager.declareReAtk()
        else
            GVGManager.declareBattle()
        end
    end
end

function GVGCityMenu.onEnter(container)
    GVGCityMenu.hide()
    if GVGManager.getGVGStatus() == GVG_pb.GVG_STATUS_FIGHTING then
        local cityInfo = GVGManager.getCityInfo()
        if cityInfo.status ~= GVG_pb.CITY_STATUS_FORBIDDEN then
            local hasAtker = cityInfo.atkGuild and cityInfo.atkGuild.guildId > 0
            local isInProtect = TimeCalculator:getInstance():hasKey("GVGCityReAtkTime" .. GVGManager.getCurCityId())
            if hasAtker and not isInProtect then
                PageManager.pushPage("GVGCityBattlePage")
            else
                GVGCityMenu.toDefendInfoPage()
            end
        else
            GVGCityMenu.toDefendInfoPage()
        end
    else
        GVGCityMenu.toDefendInfoPage()
    end
end

function GVGCityMenu.toDefendInfoPage()
    if not GVGManager.cityHasDefender() then
        MessageBoxPage:Msg_Box("@GVGIsNpcCity")
        return 
    end
    GVGManager.setShowType(GVGManager.SHOWTYPE_DEF)
    PageManager.pushPage("GVGTeamInfoPage")
end

function GVGCityMenu.onCityInfo(container)
    GVGCityMenu.hide()
    PageManager.pushPage("GVGCityInfoPage")
end

function GVGCityMenu.onBtn1(container)
    GVGCityMenu.onCityInfo(container)
end

function GVGCityMenu.onBtn2(container)
    GVGCityMenu.onEnter(container)
end

function GVGCityMenu.onBtn3(container)
    GVGCityMenu.onCityInfo()
end

function GVGCityMenu.onBtn4(container)
    GVGCityMenu.onEnter(container)
end

function GVGCityMenu.onBtn5(container)
    GVGCityMenu.onBattle(container)
end

function GVGCityMenu.onBtn10(container)
     GVGCityMenu.onCityInfo()
end

function GVGCityMenu.onBtn11(container)
    GVGCityMenu.onRevive(container)
end

function GVGCityMenu.onRevive(container)
    GVGCityMenu.hide()
    GVGManager.revieveDeclare()
end

function GVGCityMenu.onTouch(eventName, touch)
    --if eventName ~= "ended" then
    GVGManager.setCurCityId(0)
    GVGCityMenu.hide()
    --end
end

function GVGCityMenu.hide()
    if GVGCityMenu.container then
        GVGCityMenu.container:removeFromParentAndCleanup(true)
    end
end

function GVGCityMenu.dispose()
    if GVGCityMenu.container then
        if GVGCityMenu.container.layer then
            GVGCityMenu.container.layer:setTouchEnabled(false)
        end
        if GVGCityMenu.container:getParent() then
            GVGCityMenu.container:removeFromParentAndCleanup(true)
        end
        GVGCityMenu.container:release()
        GVGCityMenu.container = nil
    end
end

function GVGCityMenu:create(cityId, baseCity, gPos)
    GVGManager.setCurCityId(cityId)
    if self.container then 
        if self.container:getParent() then 
            GVGCityMenu.hide()    
        end
        self.cityId = cityId
        self.touchPos = touchPos
        baseCity:addChild(self.container)
        self:init(self.container,gPos)
        return self.container 
    end
    local base = ScriptContentBase:create(option.ccbiFile)
    base:registerFunctionHandler(GVGCityMenu.onFunction)

    local layer = tolua.cast(base:getVarNode("mLayer"),"CCLayer")
    layer:registerScriptTouchHandler(GVGCityMenu.onTouch)
    layer:setTouchEnabled(true)
    base.layer = layer
    
    self.cityId = cityId
    self.container = base

    baseCity:addChild(base)
    self:init(base,gPos)

    return base
end

function GVGCityMenu:init(container,touchPos)
    local id = self.cityId

    local visibleMap = {}
    local imgMap = {}
    
    local baseNode = container:getVarNode("mBtnAllNode")
    local cityCfg = GVGManager.getCityCfg(cityId)
    visibleMap.mPosition4 = false
    visibleMap.mPosition5 = false
    --城池是复活点 可以复活弹出复活框  不可以复活return
    if cityCfg.level == 0 then
        if GVGManager.canReviveCity() then         
            visibleMap.mPosition2 = false
            visibleMap.mPosition3 = false
            visibleMap.mPosition5 = true
            --复活
            imgMap = {
              mBtn11 = {
                    normal = "Imagesetfile/GVGMain/GVG_Action_Revive.png"
                }
            }
--            if baseNode and container.layer then
--                local localPos = container.layer:convertToNodeSpace(touchPos)
--                baseNode:setPosition(localPos)
--            end
            --NodeHelper:setMenuItemImage(container,imgMap)
            --NodeHelper:setNodesVisible(container,visibleMap)
            --container:runAnimation("Open")
        else
            visibleMap.mPosition2 = false
            visibleMap.mPosition3 = false
            visibleMap.mPosition5 = false
            --复活
            imgMap = {
              mBtn11 = {
                    normal = ""
                }
            }

            local cityInfo = GVGManager.getCityInfo()
            if not common:table_is_empty(cityInfo) and cityInfo.defGuild.guildId > 0  then
                MessageBoxPage:Msg_Box("@ERRORCODE_9126")
            elseif GVGManager.getGVGStatus() ==  GVG_pb.GVG_STATUS_PREPARE then 
                 MessageBoxPage:Msg_Box("@GVGRebirthCityNoWar")
             end
        end
        
         --NodeHelper:setMenuItemImage(container,imgMap)
         --NodeHelper:setNodesVisible(container,visibleMap)
         --container:runAnimation("Open")
    else
        if GVGManager.isOwnCity() and GVGManager.canSendRoleCity() then
            visibleMap.mPosition2 = false
            visibleMap.mPosition3 = true
            -- btn3 详细   btn4 侦查  btn5 驻屯
            imgMap = {
                mBtn3 = {
                    normal = "Imagesetfile/GVGMain/GVG_Action_Detail.png"
                },
                mBtn4 = {
                    normal = "Imagesetfile/GVGMain/GVG_Action_IntoCity.png"
                },
                mBtn5 = {
                    normal = "Imagesetfile/GVGMain/GVG_Action_Defend.png"
                }
            }
        else
            if GVGManager.canAtkCity() then
                visibleMap.mPosition2 = false
                visibleMap.mPosition3 = true
                 -- btn3 详细   btn4 侦查  btn5 攻城
                imgMap = {
                    mBtn3 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_Detail.png"
                    },
                    mBtn4 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_IntoCity.png"
                    },
                    mBtn5 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_Attack.png"
                    }
                }
            elseif GVGManager.canReAtkCity() then
                visibleMap.mPosition2 = false
                visibleMap.mPosition3 = true
                 -- btn3 详细   btn4 侦查  btn5 反攻
                imgMap = {
                    mBtn3 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_Detail.png"
                    },
                    mBtn4 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_IntoCity.png"
                    },
                    mBtn5 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_ReAttack.png"
                    }
                }
            elseif GVGManager.canDeclareCity() then         
                visibleMap.mPosition2 = false
                visibleMap.mPosition3 = true
                 -- btn3 详细   btn4 侦查  btn5 宣战
                imgMap = {
                    mBtn3 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_Detail.png"
                    },
                    mBtn4 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_IntoCity.png"
                    },
                    mBtn5 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_Declare.png"
                    }
                }
        
            else
                visibleMap.mPosition2 = true
                visibleMap.mPosition3 = false
                  -- btn1 详细   btn2 侦查 
                imgMap = {
                    mBtn1 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_Detail.png"
                    },
                    mBtn2 = {
                        normal = "Imagesetfile/GVGMain/GVG_Action_IntoCity.png"
                    }
                }
                 if cityCfg.level == 0 then 
                   imgMap = {
                    mBtn1 = {
                        normal = ""
                    },
                    mBtn2 = {
                        normal = ""
                    }
                }
                end

            end
        end
    end
    if baseNode then
        local localPos = baseNode:getParent():convertToNodeSpace(touchPos)
         if cityCfg.level == 3 then
            baseNode:setPosition(ccp(localPos.x,localPos.y -30))
         else 
           baseNode:setPosition(localPos)
         end
    end

    NodeHelper:setMenuItemImage(container,imgMap)
    NodeHelper:setNodesVisible(container,visibleMap)

    container:runAnimation("Open")
end

function GVGCityMenu:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGCityMenu:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		
	end
end

function GVGCityMenu:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGCityMenu:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

return GVGCityMenu