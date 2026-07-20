local lua = require("devtools.lua")

local M = {}

---@return integer nanoseconds
function get_time_in_ns()
    return vim.loop.hrtime()
end

---@param start_time integer nanoseconds
---@return number milliseconds rounded to 1 decimal place
function get_elapsed_time_in_rounded_ms(start_time)
    local elapsed_ns = get_time_in_ns() - start_time
    local ms = elapsed_ns / 1e6
    local ms_rounded_1_digit = math.floor(ms * 10 + 0.5) / 10
    return ms_rounded_1_digit
end

-- TODO refactor to module usage so we don't have dependency load order issues w/ globals
M.get_time_in_ns = get_time_in_ns
M.get_elapsed_time_in_rounded_ms = get_elapsed_time_in_rounded_ms

function M.start_profiler()
    local ProFi = lua.try_require_luarocks_dependency("ProFi")
    ProFi:start()
end

function M.stop_profiler(path)
    path = path or "profi.txt"
    local ProFi = require("ProFi")
    ProFi:stop()
    ProFi:writeReport(path)
    print("profile written to: " .. path)
end

return M
