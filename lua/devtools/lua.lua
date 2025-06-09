local inspect = require("devtools.inspect")
local messages = require("devtools.messages")
local super_iter = require("devtools.super_iter")

local M = {}

function M.inspect_fn(fn)
    if type(fn) == "table" then
        -- PRN any false positives here? that would work w/ below code as is?
        -- example: (table w/ __call, aka callable)
        --   DevDumpLuaFunction vim.iter
        messages.append("inspect_fn: fn is a table, fallback to __call")
        fn = getmetatable(vim.iter).__call
    end

    -- debug return type: https://www.lua.org/manual/5.1/manual.html#3.8
    local info = debug.getinfo(fn, "nS") -- n = name, S = source info
    local what = info.what
    if what == "Lua" then
        -- not that useful to show "Lua"
        what = nil
    end
    local source_or_line = M.inspect_fn_source_or_line(info)
    -- BTW by logging entire object, its clear what is what, field wise...
    --   AND, if a field is nil it won't take up any space!
    return {
        name = info.name,
        what = what, -- "Lua", "C", "main", etc.
        func = info.func, -- name of function or nil
        source_line = source_or_line
    }
end

function M.inspect_fn_source_or_line(info)
    local source_line = info.source .. ":" .. tostring(info.linedefined)
    if not string.find(source_line, "^%@") then
        -- return as is
        return info.source
    end
    source_line = source_line:gsub("^@", "") -- strip '@' from filename

    -- to save space, look for cwd
    --  i.e. cwd = /foo/bar/
    --       source = /foo/bar/bam/test.lua
    --       =>       bam/test.lua
    local cwd = vim.fn.getcwd() -- PRN pass cwd and home, if expensive to lookup on each iteration
    if string.find(source_line, "^" .. cwd) then
        source_line = source_line:gsub("^" .. cwd .. "/", "") -- strip cwd from filename
    end

    -- to save space, look for home dir
    --  i.e. /home/wes/foo/bar.lua
    --    => ~/foo/bar.lua
    local home = vim.fn.getenv("HOME")
    if string.find(source_line, "^/") then
        source_line = source_line:gsub(home, "~")
    end

    return source_line
end

function M.inspect_userdata_WIP(data)
    -- TODO probably move this to inspect module...org
    --   I would like a one-stop inspect_wtf... when I have no idea what it is and wanna test a bunch of normal things
    --     i.e. if userdata => check for :type .type... or other methods and/or call as it makes sense
    --      then, for example, call out to my ts.inspect_ts func if it is treesitter


    -- TODO is json serialization another vector to dump details? chatgpt keep suggesting this... need to find actual examples... if so I can have pcall to json_encode be an option too to check
    local ok, encoded = pcall(vim.fn.json_encode, data)
    if not ok then
        print("Failed to encode userdata: " .. tostring(encoded))
        return
    end

    local decoded = vim.fn.json_decode(encoded)
    print(vim.inspect(decoded))
end

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

function M.which_module(module_name)
    -- USAGE:
    --   which_module("vim.iter")
    --   which_module("devtools.messages")

    -- PRN should I just use this?
    --   one benefit, this can return all matches
    -- vim.api.nvim_get_runtime_file("lua/", true)

    local paths = {}
    -- search vim's runtimepath
    --   PRN should I include other path(s)? package.cpath?
    for _, rtp in ipairs(vim.opt.runtimepath:get()) do
        table.insert(paths, rtp .. "/lua/?.lua")
        table.insert(paths, rtp .. "/lua/?/init.lua")
    end

    --   DevWhichModule rx   -- FYI this is in package.path, not RTP
    local search_path = table.concat(paths, ";") .. ";" .. package.path

    local path, looked = package.searchpath(module_name, search_path)
    if path == nil then
        messages.append("module not found, checked in:")
        messages.append(looked)
        return
    end

    messages.append(path)
end

function M.setup()
    -- FYI use :buffers  ... builtin command with good details about each buffer
    -- for now, no command, just really wanted the function reminder
    -- and then eventually find a better way to inspect _G (globals)
    vim.api.nvim_create_user_command("DevDumpGlobals", M.dump_globals, {})
    vim.api.nvim_create_user_command("DevDumpPackagesLoaded", function(args)
        -- USAGE:
        --   :DevDumpPackagesLoaded ^vim.lsp

        local name_pattern = args.fargs[1]
        print("filter: " .. tostring(name_pattern))
        return M.dump_packages_loaded(name_pattern)
    end, { nargs = "*", complete = "lua", })

    vim.api.nvim_create_user_command("DevDumpLuaFunction", function(args)
        --   :DevDumpLuaFunction vim.iter
        messages.ensure_open()

        local func_expression = args.fargs[1]
        local func, err = load("return " .. func_expression)()
        if not func then
            print("function expression failed to load", err)
        end
        local func_inspected = M.inspect_fn(func)
        messages.header(func_expression)
        messages.append(func_inspected)
    end, { nargs = "*", complete = "lua", })

    vim.api.nvim_create_user_command("DevWhichModule", function(args)
        messages.ensure_open()

        local module_name = args.fargs[1]
        messages.header("which_module(" .. module_name .. ")")

        M.which_module(module_name)
    end, { nargs = "*", complete = "lua", })
end

return M
