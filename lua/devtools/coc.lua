local messages = require("devtools.messages")
local M = {}

if false then
    vim.keymap.set({ 'i', 'c' }, '<C-;>', function()
        vim.defer_fn(function()
            require("devtools.nvim").dump_windows()
            require("devtools.nvim").dump_buffers()



            -- works if:
            -- C-N (while coc pum not open) then defers to nvim's ins completion picker
            --  => then complete_info() works to return items!
            --  but, I think I can get basically the same info
            --    via documentSymbols/getWorkspaceSymbols
            --  so lets go that route next

            -- local info = vim.fn.complete_info({ 'items', 'selected', 'pum_visible' })
            local info = vim.fn.complete_info()
            messages.append("items", info)

            if info.pum_visible == 1 then
                vim.fn.setreg('"', "") -- clear unnamed register
                local lines = {}
                for _, item in ipairs(info.items) do
                    local word = item.word or item.abbr or ""
                    table.insert(lines, word)
                end
                local text = table.concat(lines, "\n")
                vim.fn.setreg('"', text)
                messages.append("Yanked " .. #lines .. " completion items")
            else
                messages.append("No visible completion menu")
            end
        end, 0)
    end, { desc = "Yank visible completion items" })
end

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
