local messages = require("devtools.messages")
local M = {}
-- local function inspect_userdata(data)
--     local ok, encoded = pcall(vim.fn.json_encode, data)
--     if not ok then
--         print("Failed to encode userdata: " .. tostring(encoded))
--         return
--     end
--
--     local decoded = vim.fn.json_decode(encoded)
--     print(vim.inspect(decoded))
-- end
--
function M.get_coc_symbols()
    messages.ensure_open()
    messages.header('coc symbols')
    -- :echo json_encode(CocAction('documentSymbols'))

    -- documentSymbols
    -- getCurrentFunctionSymbol
    --
    vim.fn.CocActionAsync('documentSymbols', function(err, symbols)
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
end

function M.setup()
    -- FYI localleader shouldn't be used globally ;)
    vim.keymap.set('n', '<LocalLeader>ss', ':lua require("devtools.coc").get_coc_symbols()<CR>', { noremap = true, silent = true })
end

return M
