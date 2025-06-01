local inspect = require("devtools.inspect")
local messages = require("devtools.messages")
local M = {}

-- vim.print(_G) is useful to inspect modules
function M.dump_globals()
    messages.ensure_open()
    messages.append(vim.inspect(_G))
end

function M.setup()
    -- FYI use :buffers  ... builtin command with good details about each buffer
    -- for now, no command, just really wanted the function reminder
    -- and then eventually find a better way to inspect _G (globals)
    -- vim.api.nvim_create_user_command("DumpGlobals", M.dump_globals, {})
end

return M
