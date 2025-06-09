local messages = require("devtools.messages")
local M = {}

function M.get_coc_symbols()
    messages.ensure_open()
    messages.header('coc symbols')
    -- :echo json_encode(CocAction('documentSymbols'))

    -- local pos = vim.api.nvim_win_get_cursor(0)

    -- vim.fn.CocActionAsync('sendRequest', "lua", 'textDocument/completion',
    -- vim.fn.CocActionAsync('sendRequest', {
    --         id = "lua",
    --         method = 'textDocument/completion',
    --     }, -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_completion
    --
    --     function(err, result)
    --         if err then
    --             messages.append("Error:", err.message or err)
    --             return
    --         end
    --
    --         -- local items = result.items or result
    --         -- for _, item in ipairs(items or {}) do
    --         --     print(item.label)
    --         -- end
    --     end
    -- )

    -- TODO! use coc pum buffer to get completions since I can't find an API to do so

    vim.fn.CocActionAsync('documentSymbols', function(err, symbols)
        if err ~= vim.NIL and err ~= nil then
            messages.append("ERROR:", err)
        end
        if not symbols then
            messages.message('No symbols found')
            return
        end
        -- FYI kind is str w/ documentSymbols, integer for getWorkspaceSymbols ??
        -- messages.append(symbols)
        -- messages.append(vim.fn.json_decode(vim.fn.json_encode(symbols)))

        for _, symbol in pairs(symbols) do
            messages.append(vim.fn.json_decode(vim.fn.json_encode(symbol)))
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
