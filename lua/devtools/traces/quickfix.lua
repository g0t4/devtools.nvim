local M = {}
local log = require('devtools.logs.logger'):universal()
local lua_traces = require('devtools.traces.lua_traces')
local python_traces = require('devtools.traces.python_traces')

-- * WIP for quick fix / location-list

local function from_lua_traceback(text)
    vim.notify('fixing lua traceback paths (can be slow)...')

    -- TODO hammerspoon will need lua fixes but not with vim.rtp, instead needs HS specific roots to look through
    --   * SEE devtools trace for notes about hammerspoon paths

    local items = lua_traces.to_quickfix_items(text)

    vim.fn.setqflist({}, " ", {
        title = "Lua Traceback",
        items = items,
    })

    vim.cmd("copen")
end

local function from_python_traceback(text)
    vim.notify('fixing python traceback paths (can be slow)...')

    local items = python_traces.to_quickfix_items(text)

    vim.fn.setqflist({}, " ", {
        title = "Python Traceback",
        items = items,
    })

    vim.cmd("copen")
end

--- Detect which trace parser should handle `text`, based on an unambiguous per-trace marker.
---@param text string
---@return string? - "lua", "python", or nil if unrecognized
function M.detect_trace_type(text)
    local lua_marker = text:find("stack traceback:\n")
    if lua_marker then
        -- assume \n after means it was on its own line and dont care if it is first or not (which is why I don't require \n at start)
        -- FYI \n b/c stack traceback label is not first line and has lines after, if you copy the wrong part it might not match
        return "lua"
    end
    if python_traces.is_python_trace(text) then
        return "python"
    end
    return nil
end

--- Auto detect the type of trace and use the appropriate handler for it
---  all parsers/mappers are setup as separate lua modules and well tested so they just work
---  if you have issues with a trace, save it to a file and load it and test it!
function M.set_quickfix_from(text)
    local trace_type = M.detect_trace_type(text)
    if trace_type == "lua" then
        from_lua_traceback(text)
        return
    end
    if trace_type == "python" then
        from_python_traceback(text)
        return
    end
    -- TODO other runtimes/languages/fwks
    --
    -- FYI I could branch out beyond just traces... but for now that is my focus, but if there's something else that would be convenient to be navigable then add it!
    vim.notify("did not recognize clipboard format for quickfix setup", vim.log.levels.INFO)
end

function M.set_quickfix_from_clipboard()
    -- FYI I register keymaps to call this from my neovim dotfiles config:
    --  ~/repos/github/g0t4/dotfiles/.config/nvim/lua/non-plugins/quickfixs.lua
    local clipboard = vim.fn.getreg('+')
    M.set_quickfix_from(clipboard)
end

return M
