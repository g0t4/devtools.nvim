---@class CoroutineStateTracker
---@field private states table<coroutine, table<string, any>>
local CoroutineStateTracker = {}
CoroutineStateTracker.__index = CoroutineStateTracker

---@return CoroutineStateTracker
function CoroutineStateTracker:new()
    local self = setmetatable({}, CoroutineStateTracker)
    -- weak table for coroutine contexts: keys are coroutines, values are tables of state
    self.states = setmetatable({}, { __mode = "k" })
    return self
end

---@param key string
---@param value any
function CoroutineStateTracker:set(key, value)
    local co, is_main = coroutine.running()
    if is_main then
        error("cannot set coroutine state from main thread")
    end
    if not co then
        return
    end
    if not self.states[co] then
        self.states[co] = {}
    end
    self.states[co][key] = value
end

---@param key string
---@return any
function CoroutineStateTracker:get(key)
    local co, is_main = coroutine.running()
    if is_main then
        return nil
    end
    if not co then
        return nil
    end
    local state = self.states[co]
    if not state then
        return nil
    end
    return state[key]
end

-- Singleton instance
---@type CoroutineStateTracker | nil
CoroutineStateTracker._instance = nil

---@return CoroutineStateTracker
function CoroutineStateTracker.get_instance()
    if not CoroutineStateTracker._instance then
        CoroutineStateTracker._instance = CoroutineStateTracker:new()
    end
    return CoroutineStateTracker._instance
end

---@return void
function CoroutineStateTracker.reset()
    CoroutineStateTracker._instance = nil
end

return CoroutineStateTracker
