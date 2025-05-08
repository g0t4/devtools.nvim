--
-- TODOs
-- - see OSC reference in dotfiles,"Can't re-enter normal mode from terminal mode" (see full stack trace there)
-- - messages toggle where it will discard messages if buffer not open, vs accumulate them anyways...
--   might even have it off by default and require toggling it on each session
--   this would only be when the buffer is not visible in a window
--   normal behavior when open... log always


-- * DumpBuffer module
local M = {}

function M.setup()
    vim.keymap.set('n', '<leader>mc', M.clear)
    vim.keymap.set('n', '<leader>mcc', function()
        M.clear()
        -- ALSO clear builtin :messages
        vim.cmd(":messages clear")
    end)
    -- show messages
    vim.keymap.set('n', '<leader>mm', function()
        -- FYI cannot get to work with vim.cmd(":messages").... but this worked:
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":messages<CR>", true, false, true), 'n', false)
        --             '<C-\\><C-n>:messages<CR>', true, true, true), 't', false)
    end)
    vim.keymap.set('n', '<leader>mo', function()
        M.ensure_open()
    end)
    -- ideas:
    --  keymap to copy :messages to messages buffer?
    --  curious... is there an event for when :messages arrive... at least smth with text changed right?
end

function format_dump(value)
    -- TODO! merge in inspect now that its in devtools with this
    local type = type(value)
    if type == "table" then
        return vim.inspect(value)
    elseif type == "string" then
        if value:len() > 0 then
            return value
        end
        return "'' -- empty string"
    elseif type == "userdata" then
        if value.sexpr and value.root then
            -- * treesitter node
            -- TODO split out these userdata handlers into a chain (list) and keep this simple
            local info = {
                named = value:named(),
                sexpr = value:sexpr(),
                -- root = value:root(),
                type = value:type(),
            }
            local text = vim.treesitter.get_node_text(value, 0)
            local last = ""
            if not text:find("\n") then
                info.text = text
            else
                -- only need to break it out if its multiple lines so we can see lines and not \n
                last = "\n\nText: " .. text
            end
            return "~= treesitter node: " .. vim.inspect(info) .. last
        end

        local mt = getmetatable(value)
        local index = mt.__index
        local what = {}
        for k, v in pairs(index) do
            table.insert(what, k .. " = " .. format_dump(v))
        end
        return "userdata: (unknown)\n\nHere are keys for on its index" .. table.concat(what, ", ")
    end

    return vim.inspect(value)
end

-- FYI if you want an nvim user_command that takes a lua expression
--    and it gets the evaluated value... this is how you can do it
--
local reminded_once = false

local function dump_command(opts)
    M.ensure_open()

    if not reminded_once then
        -- PRN retire this message later on
        M.append("FYI use `:=` command to dump to the command line, instead of here")
        reminded_once = true
    end

    -- FYI should only be one expression
    --   there wouldn't be completion for multiple
    --   what would a commma mean?
    --   conversely, can pass a table for multiple expressions

    -- * evaluate lua expression
    local chunk, err = load("return " .. opts.args)
    if not chunk then
        error("Invalid expression: " .. err)
    end
    local ok, result = pcall(chunk)
    if not ok then
        error("Error during evaluation: " .. result)
    end

    M.header(":Dump " .. opts.args)
    M.append(format_dump(result))

    -- b/c I used dump command, should I focus the window? lets not for now
end

vim.api.nvim_create_user_command("Dump", dump_command, {
    nargs = '*',
    complete = "lua", -- completes like using :lua command!
})

-- b/c not allowed to use lowercase command names:
vim.cmd [[ cabbrev dump Dump ]]
vim.cmd [[ cabbrev DUmp Dump ]] -- frequently mistype, b/c I have to capitalize the goddamn D
-- FYI original vimscript definition:
-- vim.cmd [[
--     command! -nargs=1 -complete=lua Dump lua print(vim.inspect(<args>))
-- ]]

-- abbreviated version of Dump, to be as easy as :=
vim.api.nvim_create_user_command("D", dump_command, {
    nargs = '*',
    complete = "lua", -- completes like using :lua command!
})

M.dump_bufnr = nil
M.dump_channel = nil

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        -- FYI if this happens AFTER session save autocmd (also triggers on VimLeavePre) then the BufferDump will still restore...
        --   lets deal with that if it happens as it will be obvious... for now the order works out fine
        --   Alternative is to call this from werkspace VimLeavePre to ensure its called in right order
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_get_name(buf):match("buffer_dump") then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
    end,
})

---@return integer|nil # first window_id for buffer
local function window_id_for_buffer(bufnr)
    local window_ids = vim.fn.win_findbuf(bufnr)
    -- FYI list is empty if no matches
    return window_ids[1]
end

function M.is_visible(bufnr)
    local window_id = window_id_for_buffer(bufnr)
    return window_id ~= nil
end

--- does not open the buffer
--- only creates it if it doesn't already exist
local function ensure_buffer_exists()
    if M.dump_bufnr ~= nil then
        return
    end
    M.create_new_buffer()
    vim.api.nvim_buf_set_name(M.dump_bufnr, 'buffer_dump')
end

-- TODO if this works then hide as local func (put above)
function M.create_new_buffer()
    M.dump_bufnr = vim.api.nvim_create_buf(true, false) -- listed, scratch

    -- * terminal backing:
    -- inspired by `:h TermHl` which also explains the following:
    -- by default, there's no external process
    --   instead it echos input to its STDOUT
    --   STDOUT connects to the buffer so you can see the output in the buffer
    -- KEEP IN MIND: there is no shell running, nor anything else
    --   that would have to be started too, and then connected
    M.dump_channel = vim.api.nvim_open_term(M.dump_bufnr, {})
    -- why use a temrinal window?
    --   doesn't have scroll issues like regular buffer
    --   not stuck with scroll until last line in buffer is at topline)
    --   supports ansi color sequences (from my inspect helper)
    --
    -- set modifiable, so I can programatically change (i.e. clear) the buffer
    --   otherwise, by default, terminal buffers are not modifiable
    vim.api.nvim_set_option_value('modifiable', true, { buf = M.dump_bufnr })

    -- -- * non-terminal backing:
    -- -- set nofile to avoid saving on quit
    -- vim.api.nvim_set_option_value('buftype', 'nofile', { buf = dump_bufnr })

    -- ensure listed w/ name:
    --   I want users to easily find it should they want to
    vim.api.nvim_set_option_value('buflisted', true, { buf = M.dump_bufnr })
end

local function ensure_buffer_is_open()
    ensure_buffer_exists()

    -- TODO! test this works here after creating buffer (before opening it in a window)
    -- note the current window so I can switch back to it when done opening the buffer/window
    local original_window_id = vim.api.nvim_get_current_win()

    -- ensure buffer is visible
    if not M.is_visible(M.dump_bufnr) then
        vim.api.nvim_command("vsplit")
        vim.api.nvim_win_set_buf(0, M.dump_bufnr)
    end

    vim.api.nvim_set_current_win(original_window_id)
end

local function dump_background(...)
    -- TMP this is not here long term, just for now since my original code all assumes buffer opens if not already
    ensure_buffer_exists()
    assert(M.dump_bufnr ~= nil)

    local args = { ... }
    for _, arg in ipairs(args) do
        if type(arg) ~= "string" then
            -- inspect anything that isn't a string... inspect returns a string
            arg = vim.inspect(arg)
        end


        -- * append new content
        -- ** terminal buffers:
        -- send output to terminal, so it processes the ANSI color sequences
        -- and output comes over STDOUT back to the buffer
        -- vim.api.nvim_chan_send(dump_channel, table.concat(formatted_args, "\n") .. "\n")
        vim.api.nvim_chan_send(M.dump_channel, arg .. "\n")

        -- * non-terminal backing:
        -- FYI had to split on "\n" for each arg too, so every line is separate
        --   vim.api.nvim_buf_set_lines(dump_bufnr, -1, -1, false, lines)
        -- OR can try using nvim_buf_
        --   vim.api.nvim_buf_set_text(dump_bufnr, -1, 0, { arg })
        -- FYI, this can still work on a terminal backed buffer, if it is modifiable
        --   issue is it won't go through the terminal instance for ANSI color sequences to work
    end

    -- TODO not working with term backed buffer?
    -- if window is open, scroll to bottom
    local dump_window_id = window_id_for_buffer(M.dump_bufnr)
    if dump_window_id == nil then
        return
    end
    vim.fn.win_execute(dump_window_id, "normal G")
end

function M.header(...)
    ensure_buffer_exists()

    local header = string.format("%s", table.concat({ ... }, " "))
    header = "\n" .. "---------- " .. header .. " ----------"
    dump_background(header)

    return M
end

function M.clear()
    if M.dump_bufnr == nil then
        return
    end

    -- PRN if still have trouble clearing... try my approach from iron.nvim:
    -- -- 1. iron.nvim clear_repl does:
    -- -- https://github.com/g0t4/iron.nvim/blob/6d911ee/lua/iron/core.lua#L156
    -- vim.fn.chansend(meta.job, string.char(12))
    --
    -- -- 2. then I added this in my nvim config:
    -- -- https://github.com/g0t4/dotfiles/blob/04db401e/.config/nvim/lua/plugins/terminals.lua#L154-L157
    -- local sb = vim.bo[meta.bufnr].scrollback
    -- vim.bo[meta.bufnr].scrollback = 1
    -- vim.bo[meta.bufnr].scrollback = sb
    --
    -- BUT, for now recreate is working fine so lets use that

    -- recreate the buffer to clear it?
    local old_dump_bufnr = M.dump_bufnr
    --
    M.create_new_buffer()
    --
    if M.is_visible(old_dump_bufnr) then
        -- if buffer was open, then reuse the same window
        -- if it wasn't then this is all in the background
        local win_id = window_id_for_buffer(old_dump_bufnr)
        if win_id == nil then
            error("unexpected, window id not found for old buffer during messages clear, this should not happen")
            return
        end
        vim.api.nvim_win_set_buf(win_id, M.dump_bufnr)
    end
    --
    -- close the old buffer
    vim.api.nvim_buf_delete(old_dump_bufnr, { force = true })
    --
    -- set name now that old is closed
    --   cannot set this before old replaced... chicken and egg
    --   otherwise I'd prefer create_new_buffer do this
    --   FYI name used to close old buffer so it doesn't get captured in werkspace session save
    vim.api.nvim_buf_set_name(M.dump_bufnr, 'buffer_dump')

    -- FYI this seemed to work at first, but its buggy...
    --   when I log after a clear, it will show old text too
    -- vim.api.nvim_buf_set_lines(M.dump_bufnr, 0, -1, false, {})

    -- FYI also tried but it won't clear scrollback (just like issue w/ term buffer hooked up to a shell)
    -- vim.api.nvim_chan_send(M.dump_channel, '\x1bc') -- ANSI reset (ESC c)

    return M
end

function M.append(...)
    -- assume buffer is open (or explicitly closed) and its fine to append w/o a care for showing it
    dump_background(...)

    return M
end

function M.ensure_open()
    ensure_buffer_is_open()

    return M
end

-- FYI I hate this name but it works for now
function M.open_append(...)
    ensure_buffer_is_open()
    dump_background(...)

    return M
end

---@return integer|nil bufnr, integer|nil window_id
function M.get_ids()
    if M.dump_bufnr == nil then
        return nil, nil
    end
    -- for special cases where I just wanna reuse this buffer
    -- probably shouldn't be using it for other things :)
    return M.dump_bufnr, window_id_for_buffer(M.dump_bufnr)
end

return M
