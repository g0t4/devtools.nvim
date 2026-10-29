local should = require('devtools.tests.should')
local describe = require('devtools.tests.describe')
local only = require('devtools.tests.only')
local skip = require('devtools.tests.skip')

local quickfix = require("devtools.traces.quickfix")

---Read a fixture file relative to this test file.
---@param relative string
---@return string
local function read_fixture(relative)
    local source = debug.getinfo(1, "S").source:gsub("^@", "")
    local dir = vim.fn.fnamemodify(source, ":h")
    local path = dir .. "/" .. relative
    return table.concat(vim.fn.readfile(path), "\n")
end

describe("detect_trace_type", function()
    -- only test marker detection here; full trace parsing correctness lives in the
    -- tests specific to each parser (lua_traces.tests.lua, python_traces.tests.lua)
    it("detects a lua traceback by the 'stack traceback:' marker", function()
        local lua_trace = [[
Error detected while processing:
stack traceback:
        [C]: in function 'error'
]]
        should.be_same("lua", quickfix.detect_trace_type(lua_trace))
    end)

    it("detects a xonsh trace (unhandled exception in event loop) as python", function()
        local trace = read_fixture("python/xonsh.txt")
        should.be_same("python", quickfix.detect_trace_type(trace))
    end)

    it("detects a vanilla python traceback as python", function()
        local trace = [[
Traceback (most recent call last):
  File "/home/user/app.py", line 42, in main
    value = compute()
ZeroDivisionError: division by zero
]]
        should.be_same("python", quickfix.detect_trace_type(trace))
    end)

    it("returns nil for unrecognized text", function()
        should.be_nil(quickfix.detect_trace_type("just some random text\nnot a trace"))
    end)
end)
