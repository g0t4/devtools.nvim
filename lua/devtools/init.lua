local messages = require("devtools.messages")
local nvim = require("devtools.nvim")
local lua = require("devtools.lua")
local coc = require("devtools.coc")

local M = {}

function M.setup()
    messages.setup()
    nvim.setup()
    lua.setup()
    coc.setup()
end

return M
