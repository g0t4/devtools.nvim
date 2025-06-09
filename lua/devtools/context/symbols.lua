local require_parser = require("devtools.ts.require_parser")
local lua = require("devtools.lua")
local M = {}

function M.get_imported_symbols(bufnr)
    local requires = require_parser.get_static_requires_lua(bufnr)
    vim.iter(requires):map(function(r)
        local path = r["path"]
        local var = r["var"] -- TODO what to do w/ this? ... so LLM knows this is name of imported module?
        local file_path = lua.which_module(path)
        print(file_path)

        get_document_symbols_coc(file_path, function(symbols)
            print(vim.inspect(symbols))
        end)
    end)
    return requires
end

return M
