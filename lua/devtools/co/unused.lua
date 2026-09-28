local M = {}

--- FYI last I checked this is unused
---@param co thread
---@return string
local function UNUSED_coroutine_info(co)
    local id = tostring(co) -- thread: 0x15209 (memory addy) ... do  not hs.inspect else you will lose memory addy part

    -- Status of the coroutine (running, suspended, dead, etc.)
    local status = coroutine.status(co)

    -- Debug info about where the coroutine's function was defined
    local level = 2
    local dbg = debug.getinfo(co, level, "S") -- 2 is caller of coroutine_info func ( 1 == coroutine_info itself, 0 == debug.getinfo)
    local source = dbg and dbg.source or "unknown"
    local line = dbg and dbg.linedefined or -1

    return string.format(
        "%s – status: %s – defined at %s:%d",
        id, status, source, line
    )
end

return M
