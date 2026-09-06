local M = {}
local log = require('devtools.logs.logger'):universal()
local lua_traces = require('devtools.traces.lua_traces')

-- * WIP for quick fix / location-list

local function from_lua_traceback(text)
    log:info('from_lua_traceback')
    vim.notify('Fixing lua traceback paths can take a few seconds...')

    -- TODO hammerspoon will need lua fixes but not with vim.rtp, instead needs HS specific roots to look through
    --     SEE devtools trace for notes about hammerspoon paths (I could run hs command to do this)

    local text = lua_traces.fix_paths_in_error(text)
    local lines = vim.split(text, "\n")

    local items = {}
    for line in text:gmatch("[^\n]+") do
        local file, lnum, msg = line:match("^%s*(.-):(%d+):%s*(.*)$")
        if file then
            table.insert(items, {
                filename = file,
                lnum = tonumber(lnum),
                text = msg,
            })
        end
    end
    log:info(items)

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
