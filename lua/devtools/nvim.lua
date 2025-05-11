local messages = require('devtools.messages')

local M = {}

function M.dump_buffers()
    local buffers = vim.api.nvim_list_bufs()

    local info = vim.iter(buffers)
        :map(function(bufnr)
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
            local row, col = unpack(vim.api.nvim_win_get_cursor(window_id))
            return window_id .. " " .. config.split
                .. " → buf " .. bufnr .. ": " .. name
                .. " @ row: " .. row .. "/" .. buflines
                .. "  col: " .. col
        end)
        :join("\n")

    messages.header("Windows")
    messages.append(info)
end

-- makes a cabbrev for the given original command
function M.alias(alias_name, original_command)
    vim.cmd(string.format("cabbrev %s %s", alias_name, original_command))
end

function M.setup()
    -- * :Buffers (captial B)
    vim.api.nvim_create_user_command("Buffers", function()
        messages.ensure_open()
        require("devtools.nvim").dump_buffers()
    end, {})

    -- * :windows
    vim.api.nvim_create_user_command("Windows", function()
        messages.ensure_open()
        require("devtools.nvim").dump_windows()
    end, {})
    M.alias("windows", "Windows")
end

return M
