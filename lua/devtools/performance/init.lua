---@return integer nanoseconds
function get_time_in_ns()
    return vim.loop.hrtime()
end

---@param start_time integer nanoseconds
---@return number milliseconds rounded to 1 decimal place
function get_elapsed_time_in_ms(start_time)
    local elapsed_ns = get_time_in_ns() - start_time
    local ms = elapsed_ns / 1e6
    local ms_rounded_3_digits = math.floor(ms * 1000 + 0.5) / 1000
    return ms_rounded_3_digits
end

---@param message string
---@param start_time integer nanoseconds
function print_took(message, start_time)
    local elapsed_ms = get_elapsed_time_in_ms(start_time)
    print(message .. " took " .. elapsed_ms .. " ms")
end

function start_profiler()
    local ProFi = require("ProFi")
    ProFi:start()
end

function stop_profiler(path)
    print("stop_profiler", path)
    path = path or "profi.txt"
    local ProFi = require("ProFi")
    ProFi:stop()
    ProFi:writeReport(path)
end
