local M = {}
local log = require('devtools.logs.logger'):universal()
local lua_traces = require('devtools.traces.lua_traces')

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

function M.set_quickfix_from(text)
    if text:find("stack traceback:\n") then
        -- assume \n after means it was on its own line and dont care if it is first or not (which is why I don't require \n at start)
        -- FYI \n b/c stack traceback label is not first line and has lines after, if you copy the wrong part it might not match
        from_lua_traceback(text)
        return
    end
    -- TODO xonsh (w/ and w/o SHOW_TRACEBACK)
    -- TODO python (vanilla vs rich?)
    vim.notify("did not recognize the clipboard format for quickfix purposes", vim.log.levels.INFO)
end

return M
