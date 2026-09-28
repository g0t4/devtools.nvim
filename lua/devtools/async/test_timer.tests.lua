local TestTimer = require("devtools.async.test_timer")

---Simulate a current time value by passing a constant
---@param constant number Constant millisecond value to return.
local function make_get_ms_return(constant)
    local fn = TestTimer.throw_if_time_not_acceptable
    local info = debug.getinfo(fn, "u") -- populate lua_getinfo.nups (number up values)
    for i = 1, info.nups do
        local name = debug.getupvalue(fn, i)
        if name == "get_ms" then
            local function get_ms()
                return constant
            end
            debug.setupvalue(fn, i, get_ms)
            break
        end
    end
end

describe("TestTimer", function()
    -- PRN I could also rewrite this to use real delays and not rely on mocking time...
    --   I would've preferred that but what gptoss120b did here isn't terrible either
    local allowed_time_ms = 100
    local timer

    before_each(function()
        timer = TestTimer:new(allowed_time_ms)
        make_get_ms_return(1) -- reset get_ms to the real implementation after each test
    end)

    it("throws if over time", function()
        make_get_ms_return(timer.start_time + allowed_time_ms * 1.2) -- 20% over
        assert.has_error(function()
            timer:stop()
        end)
    end)

    it("throws if under time", function()
        make_get_ms_return(timer.start_time + allowed_time_ms * 0.7) -- 30% under
        assert.has_error(function()
            timer:stop()
        end)
    end)

    it("does not throw if at exact time", function()
        make_get_ms_return(timer.start_time + allowed_time_ms)
        assert.has_no.errors(function()
            timer:stop()
        end)
    end)

    it("does not throw if within tolerance of time", function()
        -- exactly at max bound (allowed + tolerance)
        make_get_ms_return(timer.start_time + allowed_time_ms + allowed_time_ms * 0.04)
        assert.has_no.errors(function()
            timer:stop()
        end)

        -- exactly at min bound (allowed - tolerance)
        make_get_ms_return(timer.start_time + allowed_time_ms - allowed_time_ms * 0.04)
        assert.has_no.errors(function()
            timer:stop()
        end)
    end)
end)

