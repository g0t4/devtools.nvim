local messages = require('devtools.messages')
local super_iter = require('devtools.super_iter')

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
            -- TODO! use what I added for  sorted by lhs version of this
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

local function inspect_fn_source_or_line(info)
    local source_line = info.source .. ":" .. tostring(info.linedefined)
    if not string.find(source_line, "^%@") then
        -- return as is
        return info.source
    end
    source_line = source_line:gsub("^@", "") -- strip '@' from filename

    -- to save space, look for cwd
    --  i.e. cwd = /foo/bar/
    --       source = /foo/bar/bam/test.lua
    --       =>       bam/test.lua
    local cwd = vim.fn.getcwd()                               -- PRN pass cwd and home, if expensive to lookup on each iteration
    if string.find(source_line, "^" .. cwd) then
        source_line = source_line:gsub("^" .. cwd .. "/", "") -- strip cwd from filename
    end

    -- to save space, look for home dir
    --  i.e. /home/wes/foo/bar.lua
    --    => ~/foo/bar.lua
    local home = vim.fn.getenv("HOME")
    if string.find(source_line, "^/") then
        source_line = source_line:gsub(home, "~")
    end

    return source_line
end

local function inspect_fn(fn)
    -- debug return type: https://www.lua.org/manual/5.1/manual.html#3.8
    local info = debug.getinfo(fn, "nS") -- n = name, S = source info
    local what = info.what
    if what == "Lua" then
        -- not that useful to show "Lua"
        what = nil
    end
    local source_or_line = inspect_fn_source_or_line(info)
    -- BTW by logging entire object, its clear what is what, field wise...
    --   AND, if a field is nil it won't take up any space!
    return {
        name = info.name,
        what = what,      -- "Lua", "C", "main", etc.
        func = info.func, -- name of function or nil
        source_line = source_or_line
    }
end

function M.dump_keymaps_sorted_by_lhs(mode, lhs_starts_with)
    mode = mode or "n"
    local header = "keymaps by lhs, mode: " .. mode
    if lhs_starts_with then
        header = string.format("%s (filter: '%s')", header, lhs_starts_with)
    end
    messages.header(header)

    local mode_maps = super_iter(vim.api.nvim_get_keymap(mode))

    maps = mode_maps
        :map(function(m)
            local lhs = m.lhs
            lhs = string.gsub(lhs or "", '^ ', '<leader>')
            lhs = string.gsub(lhs or "", ' ', '<Space>')
            rhs = m.rhs or m.callback
            if type(rhs) == "function" then
                -- rhs = string.gsub(tostring(rhs), "%s+", "") -- trim whitespace in body
                rhs = vim.inspect(inspect_fn(rhs))
            end
            m.sanitized_lhs = lhs
            m.sanitized_rhs = rhs
            m.sanitized_flags = ""
            if m.expr ~= nil and m.expr == 1 then m.sanitized_flags = m.sanitized_flags .. "[expr] " end
            if m.noremap ~= nil and m.noremap == 1 then m.sanitized_flags = m.sanitized_flags .. "[noremap] " end
            if m.nowait ~= nil and m.nowait == 1 then m.sanitized_flags = m.sanitized_flags .. "[nowait] " end
            if m.script ~= nil and m.script == 1 then m.sanitized_flags = m.sanitized_flags .. "[script] " end
            if m.buffer ~= nil and m.buffer == 1 then m.sanitized_flags = m.sanitized_flags .. "[buffer] " end
            if m.silent ~= nil and m.silent == 1 then m.sanitized_flags = m.sanitized_flags .. "[silent] " end
            if m.unique ~= nil and m.unique == 1 then m.sanitized_flags = m.sanitized_flags .. "[unique] " end

            return m
        end)
        :filter(function(m)
            if not lhs_starts_with then
                return true
            end
            return string.find(m.sanitized_lhs, "^" .. lhs_starts_with) ~= nil
        end)
        :sort(function(a, b)
            return vim.fn.tolower(a.sanitized_lhs) < vim.fn.tolower(b.sanitized_lhs)
        end)
        :map(function(map)
            -- actually not sure I wanna show "flags"... might just be useful for displaying other fields?
            -- map.sanitized_flags
            return map.sanitized_lhs .. " → " .. (map.sanitized_rhs or "")
        end)
        :join("\n")

    messages.append(maps)
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

    vim.api.nvim_create_user_command("KeymapsByLHS", function(args)
        -- messages.append(args)
        messages.ensure_open()
        M.dump_keymaps_sorted_by_lhs(args.fargs[1], args.fargs[2])
    end, { nargs = '*' })
end

return M
