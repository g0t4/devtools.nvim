local should = require('devtools.tests.should')
local describe = require('devtools.tests.define.describe')
local only = require('devtools.tests.define.only')
local skip = require('devtools.tests.define.skip')

local traces = require("devtools.traces.traces")
-- FYI changing lines below may mess up line numbers in assertion below for this file, just shift those for traces.tests.lua and it'll be fine!

local function boom()
    error("boom")
end

describe("resolve_truncated_path", function()
    it("works for test case error", function()
        local ok, err = xpcall(boom, debug.traceback)

        print("\n******************** Original traceback:\n")
        print(err)

        -- print("\n******************** search:\n")
        local fixed = traces.fix_paths_in_error(err)

        -- print("\n ********************* Fixed traceback:\n")
        -- print(fixed)

        local fixed_string = tostring(fixed)

        local home = vim.fn.getenv("HOME")
        local expected = home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/traces.tests.lua:10: boom
stack traceback:
	[C]: in function 'error'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/traces.tests.lua:10: in function <]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/traces.tests.lua:9>
	[C]: in function 'xpcall'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/traces.tests.lua:15: in function <]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/traces.tests.lua:14>
	[C]: in function 'xpcall'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: in function 'call_inner'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:175: in function 'it'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/traces.tests.lua:14: in function <]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/traces.tests.lua:13>
	[C]: in function 'xpcall'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:74: in function 'call_inner'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:120: in function 'original_describe'
	./lua/devtools/tests/define/describe.lua:16: in function 'describe'
	]] .. home .. [[/repos/github/g0t4/devtools.nvim/lua/devtools/traces/traces.tests.lua:13: in function 'loaded'
	]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:239: in function <]] .. home .. [[/.local/share/nvim/lazy/plenary.nvim/lua/plenary/busted.lua:238>]]

        -- PRN do I need to do anythin to capture ./ paths and transform them too? like this one above:
        --     ./lua/devtools/tests/define/describe.lua:16: in function 'describe'
        --

        should.be_same_colorful_diff(expected, fixed_string)
    end)

    it("should skip ...", function()
        local dotdotdot = "..."
        local result = traces.resolve_truncated_path(dotdotdot)
        should.be_nil(result)
    end)
end)
