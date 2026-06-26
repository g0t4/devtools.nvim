--
-- FYI this is a bit overkill... nice, but only for lazy getters (think properties) like Log right now
--
-- weak map so getters aren't attached to target objects
local getters_by_target = setmetatable({}, { __mode = "k" })

local function add_getter(target, name, fn)
    assert(type(target) == "table", "target must be a table")
    assert(type(name) == "string", "getter name must be a string")
    assert(type(fn) == "function", "getter must be a function")

    local getters = getters_by_target[target]

    if not getters then
        getters = {}
        getters_by_target[target] = getters

        local mt = getmetatable(target)
        if not mt then
            mt = {}
            setmetatable(target, mt)
        end

        local prev_index = mt.__index

        mt.__index = function(t, k)
            local getter = getters[k]
            if getter then
                local value = getter(t, k)
                rawset(t, k, value)
                getters[k] = nil
                return value
            end

            if type(prev_index) == "function" then
                return prev_index(t, k)
            elseif prev_index ~= nil then
                return prev_index[k]
            end
        end
    end

    getters[name] = fn
end

return add_getter
