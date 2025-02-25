local thisPageName = "AlbumDisplayPage"
local UserInfo=require("PlayerInfo.UserInfo")

local opcodes = {

}

local option = {
    ccbiFile = "Album_Display.ccbi",
    handlerMap = {
        -- «ö???¨Æ¥ó
        onReturn = "onReturn",
        onHide = "onHide",
        onOpen="onOpen"
    },
}
local Icons={
    [1]="Album_Connect.png",
    [2]="Album_Affinity.png",
    [3]="Album_Partner.png"
}

local AlbumDisplayBase = {}

local RoleName=nil;

local IconIdx=1

function AlbumDisplayBase:onEnter(container)
    NodeHelper:setSpriteImage(container,{mPhoto="UI/Common/Album/FullSprite/"..RoleName..".jpg"})
    local title=common:getLanguageString("@"..RoleName.."_title")
    local content=common:getLanguageString("@"..RoleName)
    if  IconIdx==4 then
        NodeHelper:setNodesVisible(container,{mIcon=false})
    else
        NodeHelper:setSpriteImage(container,{mIcon=Icons[IconIdx]})
    end
    content=GameMaths:replaceStringWithCharacterAll(content, "#v1#", UserInfo.roleInfo.name)
    NodeHelper:setStringForLabel(container,{mTitle=title,mContent=content})
    container:getVarLabelTTF("mContent"):setDimensions(CCSizeMake(580, 200))
end
function AlbumDisplayBase:onReturn(container)
    PageManager.popPage(thisPageName)
end
function AlbumDisplayBase:onHide(container)
    NodeHelper:setNodesVisible(container,{mNode=false,mStory=false,mOpenNode=true})
end
function AlbumDisplayBase:onOpen(container)
    NodeHelper:setNodesVisible(container,{mNode=true,mStory=true,mOpenNode=false})
end

function AlbumDisplayBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function AlbumDisplayBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
function AlbumDisplayBase:setName(name,idx)
    RoleName=name
    IconIdx=idx
    local split=common:split(name,"_")
    local mID=tonumber(idx..split[2]..split[3])
    local KEY=CCUserDefault:sharedUserDefault():getStringForKey("Album") 
    local keyTable={}
    if  KEY~="" then
        for k,v in pairs (common:split(KEY,",")) do
            local id,state=unpack(common:split(v,"_"))
            if id~="" then
                keyTable[tonumber(id)]=state
            end
        end
    end
    if  KEY~="" then
        local tmp=keyTable[mID]
        if tmp==nil then
             KEY=KEY..mID.."_true,"
        else
           keyTable[mID]="true"
           KEY=""
           for k,v in pairs (keyTable) do
                KEY=KEY..k.."_"..v..","
           end
        end
    else
        KEY=KEY..mID.."_true,"
    end
     --CCUserDefault:sharedUserDefault():setStringForKey("Album", KEY);
end

local CommonPage = require("CommonPage")
local AlbumDisplayPage = CommonPage.newSub(AlbumDisplayBase, thisPageName, option)

return AlbumDisplayPage
