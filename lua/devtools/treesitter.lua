local messages = require("devtools.messages")
local ts = vim.treesitter
local M = {}

function M.inspect_ts(node)
    if node then
        messages.header("Type:", node:type())
        messages.append("  ", vim.treesitter.get_node_text(node, 0))
        -- messages.append("Range:", vim.inspect({ node:range() }))
    end
end

local query_string = [[
  (assignment_statement
    (variable_list
      name: (identifier) @var)
    (expression_list
      (function_call
        name: (identifier) @func
        arguments: (arguments (string) @import_path))))
  (#eq? @func "require")
]]

function M.get_static_requires_lua(bufnr)
    messages.ensure_open()
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local parser = ts.get_parser(bufnr, "lua")
    local tree = parser:parse()[1]
    local root = tree:root()
    local query = ts.query.parse("lua", query_string)

    local results = {}

    for pattern, match, metadata in query:iter_matches(root, bufnr) do
        for id, nodes in pairs(match) do
            local name = query.captures[id]
            for id, node in ipairs(nodes) do
                local name = query.captures[id]
                -- messages.append(name)
                M.inspect_ts(node)
                -- messages.append(lua.inspect_userdata(node))
            end
        end
    end

    -- -- lua example of require
    -- (chunk ; [0, 0] - [26, 0]
    --   local_declaration: (variable_declaration ; [0, 0] - [0, 45]
    --     (assignment_statement ; [0, 6] - [0, 45]
    --       (variable_list ; [0, 6] - [0, 14]
    --         name: (identifier)) ; [0, 6] - [0, 14]
    --       (expression_list ; [0, 17] - [0, 45]
    --         value: (function_call ; [0, 17] - [0, 45]
    --           name: (identifier) ; [0, 17] - [0, 24]
    --           arguments: (arguments ; [0, 24] - [0, 45]
    --             (string ; [0, 25] - [0, 44]
    --               content: (string_content))))))) ; [0, 26] - [0, 43]


    return results
end

return M
