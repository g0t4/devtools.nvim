-- module with past failures
-- + the ability to copy traceback to clipboard
-- + load into quickfix in neovim!

local M = {}

M.failures = {}
function M.add_failure(traceback)
    table.insert(M.failures, { traceback = traceback })
end

function M.copy_last_failure(idx)
    local entry = M.failures[idx]
    if not entry then
        return
    end
    require("devtools.utils").copy_to_clipboard(entry.traceback)
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
