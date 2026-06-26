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

---@type Logger
_G.Log = nil -- typing only, first use triggers lazy load

-- FYI nothing wrong with going back to just set it on setup (devtools/init.lua would be fine)
add_getter(_G, "Log", function()
    local log = require("devtools.logs.logger"):universal()
    log:info("CREATED")
    return log
end)

-- local config = {}
--
-- add_getter(config, "expensive", function()
--     return compute_expensive_value()
-- end)
