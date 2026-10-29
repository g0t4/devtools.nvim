local should = require('devtools.tests.should')
local describe = require('devtools.tests.describe')
local only = require('devtools.tests.only')
local skip = require('devtools.tests.skip')

local python_traces = require("devtools.traces.python_traces")
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

describe("xonsh", function()
    describe("unhandled exception in event loop", function()
        -- FYI ChatGPT mentioned python3.14 has a unique aspect to test:
        --  One interesting parser edge case: Python 3.14 displays additional expression-location indicators (~~~~~~^^^^), which your parser needs to skip rather than mistake for source locations.
        -- NOTE: xonsh's traceback here is really a python traceback underneath (same frame shape),
        --   so the parser + quickfix handling are shared with the plain "python" describe below.
        local trace = read_fixture("python/xonsh.txt")

        local expected_items = {
            {
                filename = "/Users/wesdemos/.local/share/uv/python/cpython-3.14.3-macos-aarch64-none/lib/python3.14/asyncio/events.py",
                lnum = 94,
                col = 0,
                text = "_run",
            },
            {
                filename = "/Users/wesdemos/.local/share/uv/tools/xonsh/lib/python3.14/site-packages/prompt_toolkit/application/application.py",
                lnum = 710,
                col = 0,
                text = "read_from_input_in_context",
            },
            {
                filename = "/Users/wesdemos/.local/share/uv/tools/xonsh/lib/python3.14/site-packages/prompt_toolkit/application/application.py",
                lnum = 690,
                col = 0,
                text = "read_from_input",
            },
            {
                filename = "/Users/wesdemos/.local/share/uv/tools/xonsh/lib/python3.14/site-packages/prompt_toolkit/key_binding/key_processor.py",
                lnum = 274,
                col = 0,
                text = "process_keys",
            },
            {
                filename = "/Users/wesdemos/.local/share/uv/tools/xonsh/lib/python3.14/site-packages/prompt_toolkit/key_binding/key_processor.py",
                lnum = 189,
                col = 0,
                text = "_process",
            },
            {
                filename = "/Users/wesdemos/.local/share/uv/tools/xonsh/lib/python3.14/site-packages/prompt_toolkit/key_binding/key_processor.py",
                lnum = 324,
                col = 0,
                text = "_call_handler",
            },
            {
                filename = "/Users/wesdemos/.local/share/uv/tools/xonsh/lib/python3.14/site-packages/prompt_toolkit/key_binding/key_bindings.py",
                lnum = 123,
                col = 0,
                text = "call",
            },
            {
                filename = "/Users/wesdemos/.config/xonsh/rc.d/abbreviations.xsh",
                lnum = 167,
                col = 0,
                text = "_expand_abbreviation_on_space",
            },
            {
                filename = "/Users/wesdemos/.config/xonsh/lib/wes_xonsh_abbreviations.py",
                lnum = 203,
                col = 0,
                text = "expand_abbreviation_on_space",
            },
            {
                filename = "/Users/wesdemos/.config/xonsh/lib/wes_xonsh_abbreviations.py",
                lnum = 181,
                col = 0,
                text = "expand",
            },
            {
                filename = "/Users/wesdemos/.config/xonsh/lib/wes_abbreviations.py",
                lnum = 205,
                col = 0,
                text = "expand",
            },
            {
                filename = "/Users/wesdemos/.config/xonsh/lib/wes_abbreviations.py",
                lnum = 143,
                col = 0,
                text = "expand",
            },
            {
                filename = "/Users/wesdemos/.config/xonsh/lib/wes_trace_helpers.py",
                lnum = 70,
                col = 0,
                text = "expand_trace_file",
            },
        }

        it("parses ./python/xonsh.txt into quickfix items (skips source + ~~~~~~^^^^ lines)", function()
            local items = python_traces.parse_trace_for_quickfix(trace)
            should.be_same_colorful_diff(expected_items, items)
        end)

        it("recognizes the trace as a python/xonsh trace for quickfix", function()
            should.be_same("python", quickfix.detect_trace_type(trace))
            should.be_same(true, python_traces.is_python_trace(trace))
        end)

        it("produces quickfix items via to_quickfix_items", function()
            local items = python_traces.to_quickfix_items(trace)
            should.be_same_colorful_diff(expected_items, items)
        end)
    end)

    -- TODO when we get more examples we can add them below and test them
    describe("w/o $XONSH_SHOW_TRACEBACK", function()
        local not_show_traceback = [[
]]

        it("", function()

        end)
    end)


    describe("with $XONSH_SHOW_TRACEBACK", function()
        -- FYI might not differ vs python, doesn't hurt to have an extra test even if that's the case
        local show_traceback = [[
]]

        it("", function()
        end)
    end)
end)

describe("python", function()
    describe("vanilla traceback", function()
        -- a minimal standard python traceback (no xonsh header, no 3.14 caret indicators)
        local vanilla = [[
Traceback (most recent call last):
  File "/home/user/app.py", line 42, in main
    value = compute()
  File "/home/user/util.py", line 7, in compute
    return 1 / 0
ZeroDivisionError: division by zero
]]
        local expected_items = {
            {
                filename = "/home/user/app.py",
                lnum = 42,
                col = 0,
                text = "main",
            },
            {
                filename = "/home/user/util.py",
                lnum = 7,
                col = 0,
                text = "compute",
            },
        }

        it("parses a vanilla traceback into quickfix items", function()
            local items = python_traces.parse_trace_for_quickfix(vanilla)
            should.be_same_colorful_diff(expected_items, items)
        end)

        it("recognizes a vanilla traceback as python", function()
            should.be_same(true, python_traces.is_python_trace(vanilla))
        end)
    end)
    -- PRN differences in ipython REPL?
    describe("rich traceback?", function()
        it("recognizes a rich/pretty traceback", function()
            -- rich's pretty tracebacks still emit `File "...", line N, in func` frames,
            -- just with extra ANSI / header text around them, so the frame marker still matches.
            local rich = [[
╭────────────────────── Traceback ──────────────────────╮
│ File "/home/user/app.py", line 42, in main            │
│   value = compute()                                   │
╰───────────────────────────────────────────────────────╯
]]
            should.be_same(true, python_traces.is_python_trace(rich))
        end)
    end)
end)
