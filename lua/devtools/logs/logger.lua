local ansi = require("devtools.ansi")
local inspect = require("devtools.inspect")
local host = require("devtools.host")
local Logger = {}
Logger.__index = Logger

-- PRN in hammerspoon => review changing log levels (i.e. vim.g.__) ... currently uses default level only

---@class Logger
---@field basename string
---@field file? file* @file handle for the log file

---@param basename string
---@return Logger
function Logger:new(basename)
    local self = setmetatable({}, Logger)
    self.basename = basename
    self._file = nil
    self._context = nil
    return self
end

local function ensure_directory_exists(path)
    local dir = path:match("^(.+)/[^/]+$")
    if dir and not os.execute("mkdir -p " .. dir) then
        error("Failed to create directory: " .. dir)
    end
end

function clear_iterm_scrollback(file)
    -- * YES iTerm2 scrollback clear:
    --  AND cat works on the file still, it just beeps and shows in every spot it was used (if [a]ppending to file):
    --   38;2;229;192;123m1337;ClearScrollback
    --   which means I can still cat to analyze older logs if needed (rare) while still getting a focused log!
    --   FYI 50 works instead of 1337 too, in my testing
    local clear_iterm_scrolback = "\x1b]1337;ClearScrollback\a"
    file:write(clear_iterm_scrolback)
    file:flush()

    -- * ctrl+L through log
    -- but leaves scrollback (obviously)
    -- local clear_for_tailers = "\27[2J\27[H"
    -- self.file:write(clear_for_tailers)
    -- self.file:flush()
end

function Logger:ensure_file_is_open()
    if self._file then
        return
    end

    local xdg_data_home = os.getenv("XDG_DATA_HOME")
    if not xdg_data_home then
        -- use default:
        xdg_data_home = os.getenv("HOME") .. "/.local/share"
    end
    local path = xdg_data_home .. "/devtools/" .. self.basename
    ensure_directory_exists(path)
    self._file = io.open(path, "a")
    if not self._file then
        error("Failed to open log file: " .. path)
    end

    clear_iterm_scrollback(self._file)

    -- FYI this is only called on FIRST LOG... not on reboot unless reboot has a log call
    --  so it will reset after the first log is written which is fine, just keep in mind
    local time = os.date("%Y-%m-%d %H:%M:%S")
    local lua_host = host.get_lua_vm_host():upper()
    local header =
        "\n============================== "
        .. "NEW " .. ansi.apple_yellow(ansi.underline(lua_host)) .. " INSTANCE "
        .. ansi.blue(self.basename) .. " "
        .. "(" .. time .. ")"
        .. " ==============================\n\n"
    self._file:write(header)
end

-- * log level constants
local LEVEL_NUMBERS = {
    TRACE = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,
}
local LOG_LEVEL_NUMBERS = LEVEL_NUMBERS
local LEVEL_TEXT_TO_NUMBER = {
    ["TRACE"] = LEVEL_NUMBERS.TRACE,
    ["INFO"]  = LEVEL_NUMBERS.INFO,
    ["WARN"]  = LEVEL_NUMBERS.WARN,
    ["ERROR"] = LEVEL_NUMBERS.ERROR,
}
local LEVEL_NUMBER_TO_TEXT = {
    [LEVEL_NUMBERS.TRACE] = "TRACE",
    [LEVEL_NUMBERS.INFO]  = "INFO",
    [LEVEL_NUMBERS.WARN]  = "WARN",
    [LEVEL_NUMBERS.ERROR] = "ERROR",
}

local function log_level_tag_for_number(level_number)
    local level_number_to_tag = {
        [LOG_LEVEL_NUMBERS.TRACE] = ansi.cyan("TRACE"),
        [LOG_LEVEL_NUMBERS.INFO] = ansi.white_bold("INFO "),
        [LOG_LEVEL_NUMBERS.WARN] = ansi.yellow_bold("WARN "),
        [LOG_LEVEL_NUMBERS.ERROR] = ansi.red_bold("ERROR"),
    }
    return level_number_to_tag[level_number]
end

function Logger:traceback(message, traceback)
    self:log(LOG_LEVEL_NUMBERS.ERROR, message, "\n\n", traceback, "\n\n")
end

function Logger:error(...)
    self:log(LOG_LEVEL_NUMBERS.ERROR, ...)
end

function Logger:warn(...)
    self:log(LOG_LEVEL_NUMBERS.WARN, ...)
end

function Logger:trace(...)
    self:log(LOG_LEVEL_NUMBERS.TRACE, ...)
end

function Logger:info(...)
    self:log(LOG_LEVEL_NUMBERS.INFO, ...)
end

-- * log threshold *
local MAX_LOG_THRESHOLD = 2 -- must always show WARN/ERROR

---@return string, number
function Logger.cycle_log_verbosity()
    local current_text, current_number = Logger.get_log_threshold()
    local next_number = (current_number + 1) % (MAX_LOG_THRESHOLD + 1)
    -- TODO is this where I want to keep log_threshold_text ?
    vim.g.log_threshold_text = LEVEL_NUMBER_TO_TEXT[next_number]
    return vim.g.log_threshold_text, next_number
end

---@return string level_text, number level_number
function Logger.get_log_threshold()
    local current_text
    if vim and vim.g then
        current_text = vim.g.log_threshold_text or LEVEL_NUMBER_TO_TEXT[LEVEL_NUMBERS.INFO] -- TODO default to WARN again?
    else
        -- default to INFO if not vim (for now)
        -- TODO perhaps pass default level to create? instead of making logger know where to go to store the current level and change it?
        current_text = LEVEL_NUMBER_TO_TEXT[LEVEL_NUMBERS.INFO]
    end
    local current_number = LEVEL_TEXT_TO_NUMBER[current_text]
    return current_text, current_number
end

function Logger:is_enabled(level_number)
    local _, threshold = Logger.get_log_threshold()
    return level_number <= threshold
end

---@param message string
---@param value any - will be inspect()'d and piped through bat
function Logger:luaify_trace(message, value)
    -- bat is expensive, don't call if not logging it!
    if not self:is_enabled(LOG_LEVEL_NUMBERS.TRACE) then
        return
    end

    -- TODO update jsonify to use bat_inspect too (pass language as new arg to bat_inspect?)
    -- PRN? --style=plain (add to bat_inspect?)
    local text = inspect.bat_inspect(value)

    self:trace(message, text)
end

---@param message string
---@param ... any - lua value(s) that will be vim.json.encode()'d
function Logger:jsonify_trace(message, ...)
    self:_jsonify_trace(message, false, ...)
end

---@param message string
---@param ... any - lua value(s) that will be vim.json.encode()'d
function Logger:jsonify_compact_trace(message, ...)
    self:_jsonify_trace(message, true, ...)
end

---@param message string
---@param compact? boolean
---@param ... any - lua value(s) that will be vim.json.encode()'d
function Logger:_jsonify_trace(message, compact, ...)
    if not self:is_enabled(LOG_LEVEL_NUMBERS.TRACE) then
        return
    end
    local value = { ... }
    local json = inspect.jq_json(value, compact)
    self:trace(message, json)
end

---@param logger Logger
---@param level_number number
---@param ... any
---@return string
local function build_log_entry(logger, level_number, ...)
    -- CAREFUL with how you use arg table, it's fine to do but it messes up sequential tables (arg is a table)...
    --   #arg => stops at first nil
    --   use select("#", ...) as it doesn't suffer from this issue
    --   also, can use:    for k,v in pairs(arg)
    -- FYI using `arg` resulted in parameters from previous calls (w/ more params) to be logged in subsequent logs...
    local stringified = {} -- new set of args to write into, don't try to use special `arg` variable
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        -- make sure everything is a string so it can be concatenated
        if type(value) == "table" then
            -- auto inspect table values
            if host.is_nvim() then
                stringified[i] = vim.inspect(value)
            elseif host.is_hammerspoon() then
                -- FYI vim.inspect may show table vs hs.inspect shows details when using hammerspoon host
                -- hs.inspect pretty prints
                -- PRN add log level `options` for hs.inspect(value, options)?
                stringified[i] = hs.inspect(value)
            else
                -- fallback to vim.inspect for now (ok to leave separate pathway to make explicit)
                stringified[i] = vim.inspect(value)
            end
        else
            stringified[i] = tostring(value)
        end
    end

    return string.format(
        "[%s] %s %s\n",
        log_level_tag_for_number(level_number),
        (logger._context or ""),
        table.concat(stringified, " ")
    )
end

function Logger:log(level_number, ...)
    local _, threshold_number = Logger.get_log_threshold()
    if level_number < threshold_number then
        return
    end

    local entry = build_log_entry(self, level_number, ...)

    self:_log(entry)
end

function Logger:_log(entry)
    -- PRN can use vim.defer_fn if overhead is interferring with predictions... don't  care to do that now though...
    self:ensure_file_is_open() -- ~11ms first time only (when dir already exists, so worse case is higher if it has to make the dir), 0 thereafter
    self._file:write(entry) -- 0.01ms => 0.00ms
    self._file:flush() -- 0.69ms (max in my tests) => down to 0.02ms (most of time)
end

---@param ctx any
---@param fn fun()
---@param failure_fn? fun()
function Logger:with_context(ctx, fn, failure_fn)
    self._context = ctx
    self:info("set_context")

    local ok, result_or_traceback = xpcall(fn, debug.traceback)
    if ok then
        self:info("with_context fn() success")
        self._context = nil
        return result_or_traceback
    end

    self:traceback("with_context fn() failed", result_or_traceback)

    -- * failure callback
    failure_fn = failure_fn or function() end
    local ok, result_or_traceback = xpcall(failure_fn, debug.traceback)
    if not ok then
        self:traceback("with_context failure_fn() failed too", result_or_traceback)
    end
    self._context = nil
    return nil -- explicit that we are returning nothing b/c of error
end

-- verbose, for troubleshooting
-- intended so I don't replicate this code every time I have a uv.spwan on_exit handler
function Logger:trace_on_exit_always(code, signal)
    -- do not modify this for selective logging
    self:trace("on_exit code:" .. (code or "nil") .. ", signal:" .. (signal or "nil"))
end

-- trace on errors and unexpected conditions only, use this when not troubleshooting
-- intended so I don't replicate this code every time I have a uv.spwan on_exit handler
function Logger:trace_on_exit_errors(code, signal)
    -- FYI on_exit wasn't called when I used handle:kill("sigterm")

    if code ~= nil and code == 0 then
        -- code == 0, signal == 0 => normal exit
        if signal ~= nil and signal ~= 0 then
            -- for now lets see if this ever happens and if I notice it and need to address it
            self:trace("on_exit: unexpected code is 0, signal is non-zero: '" .. signal .. "'")
        end
        return
    end
    -- for now defer all non-zero exit codes to use verbose trace:
    self:trace_on_exit_always(code, signal)
end

-- verbose, for troubleshooting
-- intended so I don't replicate this code every time I have a uv.spwan on_stdout/on_stderr handler
function Logger:trace_stdio_read_always(label, read_error, data)
    -- do not modify this for selective logging
    -- FYI read_error is only for the read operation on the pipe, not the underlying process itself
    if read_error ~= nil then
        -- do not bother with err if its nil, don't need to mention that
        -- ?? dump colorful stack trace
        self:trace(label .. " read_error:", read_error)
    end

    if data == nil then return end -- do not log EOF (data == nil)

    if data == "" then data = "<empty>" end
    self:trace(label, data)
end

-- less verbose, use this when not troubleshooting
function Logger:log_if_stdio_read_error(label, read_error, data)
    -- FYI read_error is only for the read operation on the pipe, not the underlying process itself
    if read_error ~= nil then
        -- ?? dump colorful stack trace
        self:info(label .. " read_error:", read_error)
    end

    -- if data == nil then return end -- do not log EOF (data == nil) -- * add this line if add logic below
end

-- *** NOOP LOGGER STUBS TO SHUT DOWN 99% of expense of logging
NOOP_LOGGER = {}
NOOP_LOGGER = setmetatable({}, { __index = Logger })
function NOOP_LOGGER:log(...)
end

-- PRN need to update this next time I use it (or get rid of it here)

function NOOP_LOGGER:jsonify_compact_trace(...)
end

function NOOP_LOGGER:luaify_trace(...)
end

local DISABLED = false
-- local DISABLED = true
local cached_loggers = {}
---@param basename string
---@return Logger instance
function Logger.create(basename)
    if basename == nil then
        error("name is required to open a log file")
    end

    if DISABLED then
        return NOOP_LOGGER
    end

    if cached_loggers[basename] then
        return cached_loggers[basename]
    end
    local new_logger = Logger:new(basename)
    cached_loggers[basename] = new_logger
    new_logger:ensure_file_is_open()
    return new_logger
end

function Logger.universal()
    return Logger.create("universal.log")
end

return Logger
