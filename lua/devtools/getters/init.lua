function setup_getters(what)
    local getters = {}

    function what.getter(name, fn)
        getters[name] = fn
    end

    local mt = getmetatable(what)
    if not mt then
        mt = {}
        setmetatable(what, mt)
    end

    local prev_index = mt.__index

    mt.__index = function(t, k)
        -- only missed lookups will arrive here
        local getter = getters[k]
        if getter then
            local value = getter()
            -- first lookup is the only overhead
            rawset(t, k, value)
            -- subsequent lookup will use cached value (rawset)
            -- getters[k] = nil -- optional; frees the closure
            return value
        end

        -- fallback to prev_index
        if type(prev_index) == "function" then
            return prev_index(t, k)
        elseif prev_index ~= nil then
            return prev_index[k]
        end
    end
end

---@type Logger
_G.Log = nil -- first use triggers lookup, this is just for typing

setup_getters(_G)
_G.getter("Log", function()
    local universal = require("devtools.logs.logger"):universal()
    universal:info("CREATED")
    return universal
end)
-- _G.getter("Config", load_config)
-- _G.getter("Foo", create_foo)
