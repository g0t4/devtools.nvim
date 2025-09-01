local lua = require("devtools.lua")

---@return integer nanoseconds
function get_time_in_ns()
    return vim.loop.hrtime()
end

---@param start_time integer nanoseconds
---@return number milliseconds rounded to 1 decimal place
function get_elapsed_time_in_rounded_ms(start_time)
    local elapsed_ns = get_time_in_ns() - start_time
    local ms = elapsed_ns / 1e6
    local ms_rounded_3_digits = math.floor(ms * 1000 + 0.5) / 1000
    return ms_rounded_3_digits
end

function start_profiler()
    local ProFi = lua.try_require_luarocks_dependency("ProFi")
    ProFi:start()
end

function stop_profiler(path)
    path = path or "profi.txt"
    local ProFi = require("ProFi")
    ProFi:stop()
    ProFi:writeReport(path)
    print("profile written to: " .. path)
end
