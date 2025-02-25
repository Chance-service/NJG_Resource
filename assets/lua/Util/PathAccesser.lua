--[[ 
    name: PathAccesser
    desc: 某些路徑的存取工具
    author: youzi
    update: 2023/10/11 12:35
    description: 
        因資訊零散，不易辨識取得渠道正確分類，故先暫用此處來進行取得路徑。
--]]


local NodeHelper = require("NodeHelper")

local PathAccesser = {}

--[[ 取得 數值屬性 圖標 路徑  ]]
function PathAccesser:getAttrIconPath (attrNum)
    return "attri_"..tostring(attrNum)..".png"
end

--[[ 取得 數值屬性 名稱 ]]
function PathAccesser:getAttrName (attrNum)
    return common:getAttrName(tostring(attrNum))
    -- return "@AttrName_"..tostring(attrNum)
end

--[[ 取得 派系(元素) 圖片 路徑  ]]
function PathAccesser:getFactionImgPath (attrNum)
    return string.format("Imagesetfile/Common_UI01/Attributes_elemet_%02d.png", attrNum)
end

--[[ 取得 VIP徽章 圖標 路徑 ]]
function PathAccesser:getVIPIconPath (levelNum)
    return "Imagesetfile/Recharge/levelAchi_Viplv"..tostring(levelNum)..".png"
end

--[[ 取得 星數 圖標 路徑 ]]
function PathAccesser:getStarIconPath (starNum)
    if 0 < starNum and starNum < 6 then
        return "Imagesetfile/Common_UI02/common_star_4.png" -- SR
    elseif 5 < starNum and starNum < 11 then
        return "Imagesetfile/Common_UI02/common_star_2.png" -- SSR
    elseif 10 < starNum and starNum < 16 then
        return "Imagesetfile/Common_UI02/common_star_3.png"
    else
        return ""
    end
end

--[[ 取得 裝備 描述 ]]
function PathAccesser:getEquipDesc (equipID)
    return "@Equip_Desc_"..tostring(equipID)
end

--[[ 取得 英雄立繪 ]]
-- e.g. 1號角色的無skin立繪 NG2D_01000.json
function PathAccesser:getHeroDrawSpinePath (heroID, skin)
    local fileName = string.format("NG2D_%02d", heroID)
    if skin == nil then skin = 0 end
    -- local path = string.format("Spine/NG2D,%s%03d", fileName, skin) 
    local path = string.format("Spine/NG2D,%s", fileName) 
    local isExist = true--NodeHelper:isFileExist("Spine/NG2D/" .. fileName .. ".json") or NodeHelper:isFileExist("Spine/NG2D/" .. fileName .. ".skel")
    return path, isExist
end

--[[ 取得 英雄立繪 ]]
-- e.g. 1號角色的無skin立繪 NG2D_01000.json
function PathAccesser:getHeroChibiSpinePath (heroID, skin)
    local heroCfg = ConfigManager.getNewHeroCfg()[heroID]
    if heroCfg == nil then return nil end
    
    if skin == nil then skin = 0 end
    local path = string.format("%s%03d", heroCfg.Spine, skin) 
    
    local isExist = true--NodeHelper:isFileExist(path..".json") or NodeHelper:isFileExist(path..".skel")
    return path, isExist
end

--[[ 取得 元素屬性圖片 ]]
function PathAccesser:getElementImagePath (elementID)
    return string.format("Imagesetfile/Common_UI01/Attributes_elemet_%02d.png", elementID)
end

--[[ 取得專武框背景 ]]
function PathAccesser:getAWEquipFrameAndBGPath (star)
    local str = "SR"
    if star >= 1 and star <= 5 then
        str = "SR"
    elseif star >= 6 and star <= 10 then
        str = "SSR"
    elseif star >= 11 then    
        str = "UR"
    end
    return {
        bg = string.format("Imagesetfile/Common_UI02/Hero_card_%s_base.png", str),
        frame = string.format("Imagesetfile/Common_UI02/Hero_card_%s.png", str),
    }
end

return PathAccesser