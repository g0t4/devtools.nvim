local messages = require("devtools.messages")
local nvim = require("devtools.nvim")
local M = {}

function M.dump_current_windows_and_buffers(hardcore_probe)
    messages.ensure_open()
    vim.defer_fn(function()
        -- TODO I would like to have a keymap to dump this for many different cases, maybe conditionally loaded keymap?
        --  I am using this to find the buffer/window floating with coc completion items... to read manually
        require("devtools.nvim").dump_windows()
        -- TODO! finish finding coc buffer for PUM and read the completion items from it since it seems there's no API to get them?
        if hardcore_probe then
            nvim.dump_buffers(true)
        else
            nvim.dump_buffers()
        end
    end, 0)
end

vim.keymap.set({ 'i', 'c' }, '<C-;>', M.dump_current_windows_and_buffers, { desc = "Yank visible completion items" })
vim.keymap.set({ 'i', 'c' }, '<C-.>', function() M.dump_current_windows_and_buffers(true) end, { desc = "Yank visible completion items" })

function M.get_coc_symbols()
    messages.ensure_open()
    messages.header('coc symbols')
    -- :echo json_encode(CocAction('documentSymbols'))

    local function send_lsp_completion_request()
        -- local pos = vim.api.nvim_win_get_cursor(0)


        -- vim.fn.CocActionAsync('sendRequest', "lua", 'textDocument/completion',
        vim.fn.CocActionAsync('sendRequest', {
                id = "lua",
                method = 'textDocument/completion',
            }, -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_completion

            function(err, result)
                -- messages.append("FUCK")
                if err then
                    messages.append("Error:", err.message or err)
                    return
                end

                -- local items = result.items or result
                -- for _, item in ipairs(items or {}) do
                --     print(item.label)
                -- end
            end
        )
    end

    send_lsp_completion_request()

    do return end

    vim.fn.CocActionAsync('completeList', function(err, symbols)
        if err ~= vim.NIL and err ~= nil then
            messages.append("ERROR:", err)
        end
        if not symbols then
            messages.message('No symbols found')
            return
        end
        messages.append(symbols)

        -- inspect_userdata(symbols)
        -- messages.append(vim.fn.json_decode(vim.fn.json_encode(symbols)))
        do return end

        for _, symbol in pairs(symbols) do
            -- print(string.format("[%s] %s (%d:%d)", symbol.kind, symbol.name, symbol.range.start.line + 1, symbol.range.start.character + 1))
            messages.message(string.format("[%s] %s (%d:%d)", symbol.kind, symbol.name, symbol.range.start.line + 1, symbol.range.start.character + 1))
        end
    end)

    -- FYI most require go into insert mode to return full sources
    -- reminders of coc data:
    -- OUTLINE?!
    -- sourceStat (sources of completions... how can I get these then?)
    -- documentSymbols
    -- getWorkspaceSymbols
    --   resolveWorkspaceSymbol
    -- getCurrentFunctionSymbol
    -- definitions # i.e. on a func call, where the func is defined
    -- showSignatureHelp
    -- "incomingCalls" [{CallHierarchyItem}]
    -- "outgoingCalls" [{CallHierarchyItem}]
    -- showSuperTypes
    -- diagnosticList (must go into insert mode before will work)
end

function M.setup()
    -- FYI localleader shouldn't be used globally ;)
    vim.keymap.set('n', '<LocalLeader>ss', M.get_coc_symbols, { noremap = true, silent = true })
end

return M
