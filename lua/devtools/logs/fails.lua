-- module with past failures
-- + the ability to copy traceback to clipboard
-- + load into quickfix in neovim!
local host = require("devtools.host")

local M = {}

M.failures = {}
function M.add_failure(traceback)
    table.insert(M.failures, { traceback = traceback })
end

function M.copy_last_failure(idx)
    local entry = M.failures[idx or 1]
    if not entry then
        return
    end
    if host.is_nvim() then
        vim.fn.setreg('+', entry.traceback)
    elseif host.is_hammerspoon() then
        hs.pasteboard.setContents(entry.traceback)
    else
        error("Unsupported host")
    end
end

function M.load_to_quickfix()
    local items = {}
    for _, entry in ipairs(M.failures) do
        table.insert(items, {
            bufnr = entry.bufnr,
            lnum = entry.line,
            col = 0,
            text = entry.traceback:match("[^\n]*") or "",
        })
    end
    vim.fn.setqflist(items, 'r')
    vim.cmd('copen')
end

return M
