local inspect = require("devtools.inspect")
local messages = require("devtools.messages")
local super_iter = require("devtools.super_iter")

local M = {}

function M.dump_globals()
    -- reminder... vim.print(_G) can be useful to inspect module state
    messages.ensure_open()
    -- TODO way too much stuff, need bigger buffer or filter this somehow
    --  PRN maybe add pattern based filters like w/ dump_packages_loaded?
    messages.append(vim.inspect(_G))
end

function M.dump_packages_loaded(name_pattern)
    local names = super_iter(package.loaded):map(function(k, _)
            return k
        end)
        :filter(function(k) return name_pattern == nil or k:match(name_pattern) end)
        :sort() -- todo option to control this so I can see order loaded vs by name?
        :join("\n")

    messages.ensure_open()
    messages.header("Packages Loaded")
    messages.append(names)
end

function M.setup()
    -- FYI use :buffers  ... builtin command with good details about each buffer
    -- for now, no command, just really wanted the function reminder
    -- and then eventually find a better way to inspect _G (globals)
    vim.api.nvim_create_user_command("DevtoolsDumpGlobals", M.dump_globals, {})
    vim.api.nvim_create_user_command("DevtoolsDumpPackagesLoaded", function(args)
        -- USAGE:
        --   :DevtoolsDumpPackagesLoaded ^vim.lsp

        local name_pattern = args.fargs[1]
        print("filter: " .. tostring(name_pattern))
        return M.dump_packages_loaded(name_pattern)
    end, { nargs = "*" })
end

return M
