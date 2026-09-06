local should = require('devtools.tests.should')
local describe = require('devtools.tests.define.describe')
local only = require('devtools.tests.define.only')
local skip = require('devtools.tests.define.skip')

local lua_traces = require("devtools.traces.lua_traces")
-- FYI changing lines below may mess up line numbers in assertion below for this file, just shift those for lua_traces.tests.lua and it'll be fine!

local function boom()
    error("boom")
end

describe("resolve_truncated_path", function()
    it("works for test case error", function()
        local ok, err = xpcall(boom, debug.traceback)

        -- print("\n******************** Original traceback:\n")
        -- print(err)

        -- print("\n******************** search:\n")
        local fixed = lua_traces.fix_paths_in_error(err)

        -- print("\n ********************* Fixed traceback:\n")
        -- print(fixed)

        local fixed_string = tostring(fixed)

        local home = vim.fn.getenv("HOME")
        local expected = home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/lua_traces.tests.lua:10: boom
stack traceback:
	[C]: in function 'error'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/lua_traces.tests.lua:10: in function <]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/lua_traces.tests.lua:9>
	[C]: in function 'xpcall'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/lua_traces.tests.lua:15: in function <]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/lua_traces.tests.lua:14>
	[C]: in function 'xpcall'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: in function 'call_inner'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:175: in function 'it'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/lua_traces.tests.lua:14: in function <]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/lua_traces.tests.lua:13>
	[C]: in function 'xpcall'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: in function 'call_inner'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:120: in function 'original_describe'
	./lua/devtools/tests/define/describe.lua:16: in function 'describe'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/lua_traces.tests.lua:13: in function 'loaded'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:239: in function <]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:238>]]

        -- PRN do I need to do anythin to capture ./ paths and transform them too? like this one above:
        --     ./lua/devtools/tests/define/describe.lua:16: in function 'describe'
        --

        should.be_same_colorful_diff(expected, fixed_string)
    end)

    it("should skip ...", function()
        local dotdotdot = "..."
        local result = lua_traces.resolve_truncated_path(dotdotdot)
        should.be_nil(result)
    end)
end)


local trace1 = [[
vim.schedule callback: ...a/ask-openai/agents/viewer/buffers_integration_tests.lua:131: handle 0x08844ac0a0 is already closing
stack traceback:
        [C]: in function 'close'
        ...a/ask-openai/agents/viewer/buffers_integration_tests.lua:131: in function 'fn'
        [string "vim/_core/editor"]:273: in function <[string "vim/_core/editor"]:272>
        [builtin#36]: at 0x01015b6528
        ...ocal/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:268: in function 'run'
]]


local expected_trace1 = {
    {
        filename = "...a/ask-openai/agents/viewer/buffers_integration_tests.lua",
        lnum = 131,
        col = 0,
        text = "handle 0x08844ac0a0 is already closing",
    },
    {
        filename = "...a/ask-openai/agents/viewer/buffers_integration_tests.lua",
        lnum = 131,
        col = 0,
        text = "in function 'fn'",
    },
    {
        filename = '[string "vim/_core/editor"]',
        lnum = 273,
        col = 0,
        text = 'in function <[string "vim/_core/editor"]:272>',
    },
    {
        filename = "...ocal/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua",
        lnum = 268,
        col = 0,
        text = "in function 'run'",
    },
}

local trace2 = [[
Error detected while processing TermRequest Autocommands for "*":
Error executing lua callback: TermRequest Autocommands for "*": Vim(normal):Can't re-enter normal mode from terminal mode
stack traceback:
        [C]: in function 'win_execute'
        ...epos/github/g0t4/devtools.nvim/lua/devtools/messages.lua:231: in function 'dump_background'
        ...epos/github/g0t4/devtools.nvim/lua/devtools/messages.lua:257: in function 'append'
        .../wesdemos/.config/nvim/lua/plugins/wip/osc-reference.lua:91: in function <.../wesdemos/.config/nvim/lua/plugins/wip/osc-reference.lua:84>       --
]]

local expected_trace2 = {
    {
        filename = "...epos/github/g0t4/devtools.nvim/lua/devtools/messages.lua",
        lnum = 231,
        col = 0,
        text = "in function 'dump_background'",
    },
    {
        filename = "...epos/github/g0t4/devtools.nvim/lua/devtools/messages.lua",
        lnum = 257,
        col = 0,
        text = "in function 'append'",
    },
    {
        filename = ".../wesdemos/.config/nvim/lua/plugins/wip/osc-reference.lua",
        lnum = 91,
        col = 0,
        text = "in function <.../wesdemos/.config/nvim/lua/plugins/wip/osc-reference.lua:84>       --",
    },
}

-- currently fails on a trace with absolute paths (fixed paths) instead of ...paths
local trace3_absolute_fixed_paths = [[
E5108: Lua: /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/traces/to_quickfix.lua:40: attempt to index global 'ext' (a nil value)
stack traceback:
        /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/traces/to_quickfix.lua:40: in function 'set_quickfix_from'
        /Users/wesdemos/.config/nvim/lua/non-plugins/quickfixs.lua:32: in function </Users/wesdemos/.config/nvim/lua/non-plugins/quickfixs.lua:30>
]]
local expected_trace3 = { {
    col = 0,
    -- currently has wrong filename:
    -- filename = "E5108: Lua: /Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/traces/to_quickfix.lua",
    filename = "/Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/traces/to_quickfix.lua",
    lnum = 40,
    text = "attempt to index global 'ext' (a nil value)"
}, {
    col = 0,
    filename = "/Users/wesdemos/repos/github/g0t4/devtools.nvim/lua/devtools/traces/to_quickfix.lua",
    lnum = 40,
    text = "in function 'set_quickfix_from'"
}, {
    col = 0,
    filename = "/Users/wesdemos/.config/nvim/lua/non-plugins/quickfixs.lua",
    lnum = 32,
    text = "in function </Users/wesdemos/.config/nvim/lua/non-plugins/quickfixs.lua:30>"
} }

describe("parse_for_quickfix", function()
    it("parses trace1 (truncated paths + virtual frames)", function()
        local items = lua_traces.parse_trace_for_quickfix(trace1)
        should.be_same_colorful_diff(expected_trace1, items)
    end)

    it("parses trace2 (autocommand error prefix + truncated paths)", function()
        local items = lua_traces.parse_trace_for_quickfix(trace2)
        should.be_same_colorful_diff(expected_trace2, items)
    end)

    it("parses trace3", function()
        local items = lua_traces.parse_trace_for_quickfix(trace3_absolute_fixed_paths)
        -- vim.print(items)
        should.be_same_colorful_diff(expected_trace3, items)
    end)
end)
