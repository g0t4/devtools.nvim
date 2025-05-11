local messages = require("devtools.messages")
local nvim = require("devtools.nvim")
local M = {}

function M.setup()
    messages.setup()
    nvim.setup()
end

return M
