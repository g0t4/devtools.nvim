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
    if host.is_nvim() then
        M.load_to_quickfix_from_nvim()
        return
    end
    -- assume can type to nvim instance (focused iterm instance)
    M.load_to_quickfix_from_hammerspoon()
end

function M.load_to_quickfix_from_nvim()
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

function M.load_to_quickfix_from_hammerspoon()
    host.throw_if_not_hammerspoon()
    --test ... type fuck to nvim: use hs api to type
    -- escape:
    hs.eventtap.keyStroke({}, "escape") -- ensure normal mode
    hs.eventtap.keyStrokes("ifuck") -- insert => fuck

    do return end
    -- forget about this for now:
    local items = {}
    for _, entry in ipairs(M.failures) do
        table.insert(items, {
            bufnr = entry.bufnr,
            lnum = entry.line,
            col = 0,
            text = entry.traceback:match("[^\n]*") or "",
        })
    end
    local json = hs.json.encode(items)
    local script = string.format(
        'tell application "Neovim" to execute "lua vim.fn.setqflist(%s, \'r\'); vim.cmd(\'copen\')"',
        json
    )
    hs.osascript.applescript(script)
end

-- test by uncommenting and then reload HS via streamdeck button while sitting in a nvim instance
-- M.load_to_quickfix_from_hammerspoon()

return M
