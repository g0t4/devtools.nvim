describe("xonsh", function()
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
