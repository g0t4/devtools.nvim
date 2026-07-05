local host = require("devtools.host")

---@class Timer
---@field _overall_start number
---@field _last_start number
---@field _logs {message:string, duration:number}[]
local Timer = {}
Timer.__index = Timer

local function get_now_in_nanoseconds_counter()
    if host.is_hammerspoon() then
        -- hs.timer.absoluteTime() returns nanoseconds
        return hs.timer.absoluteTime() / 1e9
    else
        local uv = vim.uv or vim.loop
        return uv.hrtime() / 1e9
    end
end

---Creates a new Timer instance.
---@return Timer
function Timer.new()
    local now = get_now_in_nanoseconds_counter()
    local obj = {
        _overall_start = now,
        _last_start = now,
        _logs = {},
    }
    setmetatable(obj, Timer)
    return obj
end

---@param message string
function Timer:capture(message)
    local now = get_now_in_nanoseconds_counter()
    local duration = now - self._last_start
    self._last_start = now
    table.insert(self._logs, { message = message, duration = duration })
end

--- FYI this is not intended to be high precision timing...
---  this is intended for loggability
---  hence not showing a bunch of decimal places
---  use this to find concerns and then use something more precise when necessary
---
---@param elapsed_seconds number
---@return string
function Timer.format_elapsed_time(elapsed_seconds)
    if elapsed_seconds >= 60 then
        local minutes = elapsed_seconds / 60
        return string.format("%.1fmin", minutes)
    end
    if elapsed_seconds >= 1 then
        return string.format("%.1fs", elapsed_seconds)
    end
    local ms = elapsed_seconds * 1e3
    if ms >= 1 then
        local time = string.format("%.1fms", ms)
        return time
    end
    local us = elapsed_seconds * 1e6
    if us >= 1 then
        return string.format("%.0fµs", us)
    end
    local ns = elapsed_seconds * 1e9
    return string.format("%dns", math.floor(ns + 0.5))
end

function Timer:overall_duration()
    local now = get_now_in_nanoseconds_counter()
    return Timer.format_elapsed_time(now - self._overall_start)
end

---@return string overall
---@return string since_last_mark
function Timer:mark_last_start_and_get_durations()
    local now = get_now_in_nanoseconds_counter()
    local overall = Timer.format_elapsed_time(now - self._overall_start)
    local since_last_log = Timer.format_elapsed_time(now - self._last_start)
    self._last_start = now
    return overall, since_last_log
end

function Timer:captures_log()
    local overall = Timer.format_elapsed_time(get_now_in_nanoseconds_counter() - self._overall_start)
    local lines = { string.format("Overall time: %s", overall) }
    for _, entry in ipairs(self._logs) do
        table.insert(lines, string.format("  %s: %s", entry.message, Timer.format_elapsed_time(entry.duration)))
    end
    return table.concat(lines, "\n")
end

function Timer.time_this(fn, description, log)
    if log == nil then
        log = require('devtools.logs.logger').universal()
    end
    if not description then
        description = "no description"
    end

    local timer = Timer.new()
    local result = fn()
    local duration = Timer.format_elapsed_time(get_now_in_nanoseconds_counter() - timer._overall_start)
    log:info(string.format("%s: %s", description, duration))
    return result
end

return Timer
