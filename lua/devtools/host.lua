local M = {}

local function if_needed_lookup_host()
    -- FYI keep in mind this is a much more expensive check
    -- FYI better to find a diff vim/hs global that I don't emulate
    -- use this if you absolutely must be sure

    local pid =
        rawget(_G, "vim") and vim.uv.os_getpid()
        or rawget(_G, "hs") and hs.processInfo.processID

    if not pid then
        _host = "unknown"
        return _host
    end

    -- FYI nvim.exe on windows would require powershell to lookup Get-Process
    -- I don't use windows much these days so I won't bother
    local f = io.popen(("ps -p %d -o comm="):format(pid))
    local proc = f and f:read("*l")
    if f then f:close() end

    proc = proc and proc:match("([^/]+)$")

    if proc == "nvim" then
        return "nvim"
    elseif proc == "Hammerspoon" then
        return "hammerspoon"
    end

    return proc or "unknown"
end

---@alias HostString "nvim"|"hammerspoon"|"unknown"

---@type HostString
local _cached = "unknown"

---@return HostString
function M.get_lua_vm_host()
    -- FYI! I emulate some vim/hs globals (APIs) between hs/vim hosts... THUS, checking globals is not enough
    -- FYI switch to if_needed_lookup_host() if these cheap signature checks become insufficient
    -- which would only happen if I emulate these APIs across hosts
    --
    -- FYI I don't emulate these APIs, hence a good enough test for my needs
    --  I chose these b/c I was busy writing the process check above :)
    --  and these feel like APIs I have no need to emulate (or I could emulate them here!)
    if rawget(_G, "vim") and vim.uv and vim.uv.os_getpid then
        _cached = "nvim"
        return _cached
    end
    if rawget(_G, "hs") and hs and hs.processInfo then
        _cached = "hammerspoon"
        return _cached
    end
    -- only lookup once
    M.get_lua_vm_host = function() return _cached end
    return _cached
end

function M.is_nvim()
    return M.get_lua_vm_host() == "nvim"
end

function M.is_hammerspoon()
    return M.get_lua_vm_host() == "hammerspoon"
end

return M
