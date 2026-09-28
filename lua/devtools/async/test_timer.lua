local function get_ms()
    -- FYI hammerspoon can import luv if its installed with luarocks (or otherwise)
    -- vim => uses vim.uv
    -- hs/busted => uses luv
    local luv = (vim and vim.uv) or require("luv")
    return luv.hrtime() / 1e6
end

---@class TestTimer
---@field start_time number
---@field allowed_time number
local TestTimer = {}

---@param allowed_time number
---@return TestTimer
function TestTimer:new(allowed_time)
    local obj = {
        start_time = get_ms(),
        allowed_time = allowed_time,
        tolerance = nil,
    }
    setmetatable(obj, { __index = self })
    return obj
end

---@param msg string
function TestTimer:throw_if_time_not_acceptable(msg)
    local elapsed = get_ms() - self.start_time
    local tolerance = self.tolerance or 0.04
    local swing = self.allowed_time * tolerance
    local min_time = self.allowed_time - swing
    local max_time = self.allowed_time + swing

    if elapsed < min_time or elapsed > max_time then
        error(msg .. " - actual: " .. string.format("%.1f", elapsed) .. "ms, expected: " .. self.allowed_time .. "ms ±" .. swing .. "ms")
    end
end

function TestTimer:start()
    self.start_time = get_ms()
end

function TestTimer:stop()
    self:throw_if_time_not_acceptable("Test timing is outside acceptable time range")
end

return TestTimer
