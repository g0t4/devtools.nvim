local describe = require('devtools.tests.define.describe')
local screen = require("devtools.tests.screen")
local notify = require("devtools.notify")

describe("devtools.tests.screen", function()
    it("returns a multi-line string", function()
        local dump = screen.dump()
        assert.is_string(dump)
        assert.is_true(#dump > 0)
        assert.is_true(#vim.split(dump, "\n") >= 2)
    end)

    it("renders a notification box when one is visible", function()
        local n = notify.info("hello world", { timeout = 0 })
        local dump = screen.dump()
        assert.is_true(dump:match("hello world") ~= nil, "dump should contain the notification text")
        assert.is_true(dump:match("%+%-+%+") ~= nil or dump:match("┌") ~= nil, "dump should contain a box border")
        n:dismiss()
    end)

    it("does not show notification text after it is dismissed", function()
        local n = notify.info("ghost", { timeout = 0 })
        n:dismiss()
        local dump = screen.dump()
        assert.is_false(dump:match("ghost") ~= nil, "dismissed notification text should be gone")
    end)
    it("renders content from multiple regular (split) windows", function()
        -- * setup: first buffer/window
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first window content" })
        -- * create a second split window with different content
        vim.cmd(":new")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "second window content" })

        local dump = screen.dump()

        -- * verify both windows' content shows up
        assert.is_true(dump:match("first window content") ~= nil, "first window content missing from dump")
        assert.is_true(dump:match("second window content") ~= nil, "second window content missing from dump")

        -- * cleanup: close the extra window
        vim.cmd(":q!")
    end)
    it("renders content from a vertical split window", function()
        -- * setup: first buffer/window
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "left window content" })
        -- * create a vertical split (left/right) with different content
        vim.cmd(":vsplit new")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "right window content" })

        local dump = screen.dump()

        -- * verify both windows' content shows up side by side
        assert.is_true(dump:match("left window content") ~= nil, "left window content missing from dump")
        assert.is_true(dump:match("right window content") ~= nil, "right window content missing from dump")

        -- * sanity: the two contents should be on the same line (side by side),
        --   proving they render in their own columns rather than overwriting
        local line_index = nil
        for i, line in ipairs(vim.split(dump, "\n")) do
            if line:match("left window content") then
                line_index = i
                break
            end
        end
        local lines = vim.split(dump, "\n")
        assert.is_not_nil(line_index, "should find a line with left window content")
        assert.is_true(
            lines[line_index]:match("left window content") ~= nil
            and lines[line_index]:match("right window content") ~= nil,
            "left and right window content should share the same rendered line (side by side)"
        )

        -- * cleanup: close the extra window
        vim.cmd(":q!")
    end)
end)
