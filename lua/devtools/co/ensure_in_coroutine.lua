local log = require("devtools.logs.logger"):universal()
local Timer = require("devtools.logs.timer")
local CoroutineStateTracker = require("devtools.co.state")

-- FYI! always check resume result for failure!!!
--   else wind up swallowing errors!

--- ensure we are running inside a non main coroutine
---@param what fun(...): any
local function ensure_in_coroutine(what, ...)
    local function ensure_timer(co)
        if CoroutineStateTracker._get("timer", co) == nil then
            local timer = Timer.new()
            CoroutineStateTracker._set("timer", timer, co)
        end
    end

    local existing_coroutine, ismain = coroutine.running()
    -- log:info("ismain:", ismain, "|", "running_thread:", running_thread)
    -- DO not try to reuse main thread (coroutine), it is not yield/resumable
    if existing_coroutine and not ismain then
        -- log:info("already have running, non-main coroutine, reusing it")
        -- * ensure timer attached on first call to ensure_in_coroutine
        ensure_timer(existing_coroutine)
        what(...)
        return
    end

    -- FYI no easy way to test this pathway b/c plenary creates a coroutine per test case so this would never fire within plenary test runner
    -- log:info("creating coroutine (thread)...")
    local new_coroutine = coroutine.create(what)
    ensure_timer(new_coroutine)

    -- ONLY call resume once, let `what` manage subsequent yield/resume (or delegate it to helpers like sleep_ms and callbacker)
    local ok, err = coroutine.resume(new_coroutine, ...)
    if not ok then
        local failure = "ensure_in_coroutine: failed resuming coroutine "
        log:error(failure, err)
        error(failure .. tostring(err))
    end
end

return ensure_in_coroutine
