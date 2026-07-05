-- examples of truncated paths in error_message lone from lua's xpcall
require("devtools.debug")
local should = require("devtools.tests.should")
local str = require("devtools.tests.str")
local log = require("devtools.logs.logger").universal()
local this_fails = require("devtools.debug.tests.this_fails")

describe("full_traceback", function()
    it("integration test", function()
        local ok, result = xpcall(function()
            this_fails.failsauce()
        end, full_traceback_xpcall)

        log:info(result)
        -- FYI for now just makes surew this doesn't fail! that can be a starting point for a test

        -- * M.failsuace() scenario:
        -- [INFO ]  ...b/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:11: attempt to index upvalue 'this_fails' (a boolean value)
        --
        -- stack traceback:
        --   /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:11: Lua '<anonymous>' [function: 0x0105f65640]
        --   =[C]:-1: global 'xpcall' [function: builtin#21]
        --   /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:10: Lua '<anonymous>' [function: 0x0105f65470]
        --   =[C]:-1: global 'xpcall' [function: builtin#21]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: upvalue 'call_inner' [function: 0x0105ef1600]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:175: global 'it' [function: 0x0105ef1dc8]
        --   /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:9: Lua '<anonymous>' [function: 0x0105f64b00]
        --   =[C]:-1: global 'xpcall' [function: builtin#21]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: upvalue 'call_inner' [function: 0x0105ef1600]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:120: global 'describe' [function: 0x0105ef1ae8]
        --   /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:8: upvalue 'loaded' [function: 0x0105f2cdb0]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:239: Lua '<anonymous>' [function: 0x0105f2b190]

        -- TODO how do I want this to work? to verify things look ok?
        --  TODO ensure all frames are captured?
    end)
    it("integration test", function()
        -- FYI this scenario isn't pivotal, just a second example of a failure...
        local ok, result = xpcall(function()
            require("devtools.debug.tests.load_fails")
        end, full_traceback_xpcall)

        log:info(result)
        -- * old scenario - module load failure scenario where raise error("load fails") when module loads
        -- [INFO ]  ./lua/devtools/debug/tests/load_fails.lua:2: load fail
        --
        -- stack traceback:
        --   =[C]:-1: global 'error' [function: builtin#19]
        --   ./lua/devtools/debug/tests/load_fails.lua:2: main '<anonymous>' [function: 0x0104d562a0]
        --   =[C]:-1: global 'require' [function: 0x01049cd290]
        --   /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:43: Lua '<anonymous>' [function: 0x0104d55d10]
        --   =[C]:-1: global 'xpcall' [function: builtin#21]
        --   /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:42: Lua '<anonymous>' [function: 0x0104d55b48]
        --   =[C]:-1: global 'xpcall' [function: builtin#21]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: upvalue 'call_inner' [function: 0x0104cdd6c8]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:175: global 'it' [function: 0x0104cdde50]
        --   /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:41: Lua '<anonymous>' [function: 0x0104d510d0]
        --   =[C]:-1: global 'xpcall' [function: builtin#21]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: upvalue 'call_inner' [function: 0x0104cdd6c8]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:120: global 'describe' [function: 0x0104cddb70]
        --   /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/debug/traces.tests.lua:8: upvalue 'loaded' [function: 0x0104d1a008]
        --   /Users/wesdemos/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:239: Lua '<anonymous>' [function: 0x0104d18d10]
    end)
end)
