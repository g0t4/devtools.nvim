local messages = require("devtools.messages")
local nvim = require("devtools.nvim")
local lua = require("devtools.lua")
local M = {}

function M.setup()
    messages.setup()
    nvim.setup()
    lua.setup()
end

return M
