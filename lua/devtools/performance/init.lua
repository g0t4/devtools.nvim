-- PRN setup a timing module? and pass a block of code to be timed?

---@return number seconds
function get_time_in_seconds()
    return vim.loop.hrtime() / 1e9
end

---@return integer nanoseconds
function get_time_in_ns()
    return vim.loop.hrtime()
end

---@param start_time integer nanoseconds
---@return integer nanoseconds elapsed
function get_elapsed_time_since(start_time)
    return get_time_in_ns() - start_time
end

---@param start_time integer nanoseconds
---@return number milliseconds rounded to 1 decimal place
function get_elapsed_time_in_milliseconds(start_time)
    local elapsed_ns = get_elapsed_time_since(start_time)
    local ms = elapsed_ns / 1e6
    return math.floor(ms * 10 + 0.5) / 10
end

---@param start_time integer nanoseconds
---@return integer nanoseconds
function get_elapsed_time_in_nanoseconds(start_time)
    return get_elapsed_time_since(start_time)
end

---@param message string
---@param start_time integer nanoseconds
function print_took(message, start_time)
    local elapsed_ms = get_elapsed_time_in_milliseconds(start_time)
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
