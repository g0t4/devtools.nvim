local messages = require("devtools.messages")
local M = {}

function M.inspect_ts(node)
    if node then
        messages.header("Type:", node:type())
        messages.append("  ", vim.treesitter.get_node_text(node, 0))
        -- messages.append("Range:", vim.inspect({ node:range() }))
    end
end

return M
