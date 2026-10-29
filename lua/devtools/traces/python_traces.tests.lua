describe("xonsh", function()
    describe("unhandled exception in event loop", function()
        -- FYI ChatGPT mentioned python3.14 has a unique aspect to test:
        --  One interesting parser edge case: Python 3.14 displays additional expression-location indicators (~~~~~~^^^^), which your parser needs to skip rather than mistake for source locations.
        -- TODO test for ./python/xonsh.txt for a trace to test
        -- TODO test to quick fix too
        -- TODO also test to make sure this is recognized in function M.set_quickfix_from(text) in addition to lua (this becomes a central dispatch point for me to copy any stack trace and have it recognize and parse with appropriate parser
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
    end)
    -- PRN differences in ipython REPL?
    describe("rich traceback?", function()
    end)
end)
