--[[ 
--   name : 多重數值
--   author : youzi151@gmail.com
--   update : 2023/5/15
--]]


local Vals = {}

function Vals:new (default_val)

    local inst = {}

    local current_name = nil
    local current_val = nil

    local _default_val = default_val

    --[[ 註冊表 ]]
    local reg_table = {}
    inst.reg_table = reg_table

    inst.on_update = {}
    
    --[[ 取得 當前值 ]]
    function inst:get_current ()
        return current_val
    end

    --[[ 更新 ]]
    function inst:update(is_skip_if_same)
        if is_skip_if_same == nil then is_skip_if_same = true end
        
        local last_val = current_val

        current_val = _default_val
        
        local most_priority = nil
        for k, v in pairs(reg_table) do

            if most_priority == nil or v.p >= most_priority then
                most_priority = v.p
                current_val = v.v
                current_name = k
            end
        end

        local is_force_update = not is_skip_if_same
        if is_force_update or last_val ~= current_val then
            for idx, fn in ipairs(inst.on_update) do
                fn(current_val)
            end
        end
    end

    --[[ 設置 ]]
    function inst:set (val, name, priority)
        
        if val == nil then
            
            reg_table[name] = nil
            if current_name == name then
                current_name = nil
                current_val = nil
            end
            
        else

            if priority == nil then priority = 0 end

            reg_table[name] = {
                v = val, 
                p = priority
            }
            
        end
        self:update()
    end

    return inst
end

return Vals