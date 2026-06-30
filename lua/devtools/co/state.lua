---@class CoroutineStateTracker
---@field private states table<coroutine, table<string, any>>
local CoroutineStateTracker = {}
CoroutineStateTracker.__index = CoroutineStateTracker

local function new_weak_map()
    return setmetatable({}, { __mode = "k" })
end

-- BTW no need to remove timer later b/c CoroutineStateTracker uses a weak map to store state
local states = new_weak_map()

---@param key string
---@param value any
function CoroutineStateTracker.set(key, value)
    local co, is_main = coroutine.running()
    if is_main then
        error("cannot set coroutine state from main thread")
    end
    if not co then
        return
    end
    if not states[co] then
        states[co] = {}
    end
    states[co][key] = value
end

---@param key string
---@return any
function CoroutineStateTracker.get(key)
    local co, is_main = coroutine.running()
    if is_main then
        return nil
    end
    if not co then
        return nil
    end
    local state = states[co]
    if not state then
        return nil
    end
    return state[key]
end

function CoroutineStateTracker.reset()
    states = new_weak_map()
end

return CoroutineStateTracker
