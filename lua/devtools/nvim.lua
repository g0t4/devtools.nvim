local messages = require('devtools.messages')

local M = {}

function M.dump_buffers()
    local buffers = vim.api.nvim_list_bufs()

    local info = vim.iter(buffers)
        :map(function(bufnr)
            -- TODO what do I want to show for :Buffers... I added this as a placeholder, I need to review what I wanna see
            local name = vim.api.nvim_buf_get_name(bufnr)
            local buftype = vim.bo[bufnr].buftype
            local filetype = vim.bo[bufnr].filetype
            local buflines = vim.api.nvim_buf_line_count(bufnr)
            return bufnr .. ": " .. name .. " (" .. buftype .. "/" .. filetype .. ") " .. buflines .. " lines"
        end)
        :join("\n")

    messages.header("Buffers")
    messages.append(info)
end

function M.dump_windows()
    local windows = vim.api.nvim_list_wins()

    local info = vim.iter(windows)
        :map(function(window_id)
            local config = vim.api.nvim_win_get_config(window_id)
            local bufnr = vim.api.nvim_win_get_buf(window_id)
            -- PRN based on buf/filetype ... display different info?
            -- local buftype = vim.bo[bufnr].buftype
            -- local filetype = vim.bo[bufnr].filetype
            local buflines = vim.api.nvim_buf_line_count(bufnr)
            local name = vim.api.nvim_buf_get_name(bufnr)
            local split = config and config.split or "missing config"
            local row, col = unpack(vim.api.nvim_win_get_cursor(window_id))
            return window_id .. " " .. split
                .. " → buf " .. bufnr .. ": " .. name
                .. " @ row: " .. row .. "/" .. buflines
                .. "  col: " .. col
        end)
        :join("\n")

    messages.header("Windows")
    messages.append(info)
end

function M.dump_keymaps(mode)
    mode = mode or 'n'
    local keymaps = vim.api.nvim_get_keymap(mode)
    local buf_keymaps = vim.api.nvim_buf_get_keymap(0, mode) -- Buffer-local keymaps
    -- TODO create entrypoints for dumping global vs buf local keymaps?
    keymaps = vim.list_extend(keymaps, buf_keymaps)

    local info = vim.iter(keymaps)
        :map(function(map)
            -- TODO revisit and improve over time!
            -- WHY? ability to search keymaps!
            -- show more useful info (i.e. [buffer][expr], maybe even reflect for func name/body)
            local lhs = map.lhs or "''" -- missing lhs
            lhs = lhs:gsub(' ', '<Space>')
            -- TODO specify what file:line defines the lua function
            --    TODO reflect on lua func for name (if not anonymous) or other useful info?
            --    maybe add param to expand function definitions inline?
            local rhs = map.rhs or (map.callback and "<lua fn>" or "<???>")
            local expr = map.expr and "[expr]" or ""
            local noremap = map.noremap and "[noremap]" or ""
            local buffer = map.buffer and "[buffer]" or ""
            local row = string.format(
                "%s %s  →  %s  %s  %s%s  ",
                mode, lhs, rhs, expr, noremap, buffer
            )
            if map.desc and map.desc ~= "" then
                row = row .. " desc: '" .. map.desc .. "'"
            end
            return row
        end)
        :join("\n")

    messages.header("Keymaps for mode: " .. mode)
    messages.append(info or "No keymaps found")
end

function M.dump_keymaps_sorted_by_lhs(lhs_starts_with)
    messages.ensure_open()

    -- :append(vim.api.nvim_buf_get_keymap(0, 'n')) -- TODO! Buffer-local keymaps
    -- TODO! imap/vmap/cmap, etc
    local maps = vim.iter(vim.api.nvim_get_keymap('n'))
    maps = maps:map(function(m)
        local lhs = m.lhs
        lhs = string.gsub(lhs or "", '^ ', '<leader>')
        lhs = string.gsub(lhs or "", ' ', '<Space>')
        m.sanitized_lhs = lhs
        return m
    end):filter(function(m)
        if not lhs_starts_with then
            return true
        end
        return string.find(m.sanitized_lhs, "^" .. lhs_starts_with) ~= nil
    end)

    maps = maps:totable()

    -- FYI in-place
    table.sort(maps, function(a, b)
        return a.sanitized_lhs < b.sanitized_lhs
    end)

    local info = vim.iter(maps)
        :map(function(map)
            return map.sanitized_lhs .. " → " .. (map.rhs or "")
        end)
        :join("\n")

    messages.header("keymaps by lhs")
    messages.append(info)
end

function M.dump_highlights()
    -- FYI first use case for this is to be able to search through the 100s of highlights!
    --   not have to use that damn pager and then find in iterm

    -- FYI right now I don't have any namespaced showing up in my initial testing
    --  AFAICT most things use global highlights to avoid activation issues w/ using a namespace
    local namespaced_highlights = vim.iter(vim.api.nvim_get_namespaces())
        :map(function(name, ns_id)
            local highlights = vim.api.nvim_get_hl(ns_id, {})
            if #highlights == 0 then
                return ""
            end
            return name .. " (" .. ns_id .. ")" ..
                "\n  " .. vim.inspect(highlights)
        end)
        :filter(function(line)
            return line ~= ""
        end)
        :join("\n")
    messages.header("Namespaced Highlights")
    messages.append(namespaced_highlights)

    messages.header("Global Highlights (ns_id=0)")
    local global_highlights = vim.api.nvim_get_hl(0, {})
    messages.append(vim.inspect(global_highlights))
end

-- makes a cabbrev for the given original command
function M.alias(alias_name, original_command)
    vim.cmd(string.format("cabbrev %s %s", alias_name, original_command))
end

function M.setup()
    -- FYI use :buffers  ... builtin command with good details about each buffer
    -- -- * :Buffers (captial B)
    -- vim.api.nvim_create_user_command("Buffers", function()
    --     messages.ensure_open()
    --     require("devtools.nvim").dump_buffers()
    -- end, {})

    -- * :windows
    -- there is no builtin command to list windows, other than call vim.api.nvim_list_wins() which just shows IDs
    vim.api.nvim_create_user_command("Windows", function()
        messages.ensure_open()
        require("devtools.nvim").dump_windows()
    end, {})
    M.alias("windows", "Windows")
end

return M
