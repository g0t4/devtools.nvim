local coc = require('devtools.coc')
local should = require('devtools.tests.should')
local messages = require('devtools.messages')


messages.ensure_open()

-- -- OK... workspace symbols == globals!
-- coc.get_workspace_symbols(function(symbols)
--     vim.iter(symbols)
--         :filter(function(symbol)
--             -- return symbol.location.uri:match("messages")
--             return symbol.name:match("ensure")
--         end)
--         :each(function(symbol)
--             messages.append(symbol)
--         end)
-- end)


function test_load_path_document_symbols()
    local symbols = coc.get_document_symbols_by_path("./lua/devtools/messages.lua")
    messages.append(symbols)
end

test_load_path_document_symbols()
