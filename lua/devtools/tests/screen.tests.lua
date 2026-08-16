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
        -- * setup: make vsplit open the new window on the RIGHT (matches the
        --   user's config which sets 'splitright'; nvim's default is LEFT).
        local save_splitright = vim.o.splitright
        vim.o.splitright = true

        -- * setup: first buffer/window
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first win content" })
        -- * create a vertical split; with splitright the new window is on the
        --   RIGHT, so the current buffer after the command is the new window.
        vim.cmd(":vsplit new")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "second win content" })

        local dump = screen.dump()

        -- * verify both windows' content shows up side by side
        assert.is_true(dump:match("first win content") ~= nil, "first win content missing from dump")
        assert.is_true(dump:match("second win content") ~= nil, "second win content missing from dump")

        -- * sanity: the two contents should be on the same line (side by side),
        --   proving they render in their own columns rather than overwriting
        local line_index = nil
        for i, line in ipairs(vim.split(dump, "\n")) do
            if line:match("first win content") then
                line_index = i
                break
            end
        end
        local lines = vim.split(dump, "\n")
        assert.is_not_nil(line_index, "should find a line with first win content")
        local shared_line = lines[line_index]
        assert.is_true(
            shared_line:match("first win content") ~= nil
            and shared_line:match("second win content") ~= nil,
            "both windows' content should share the same rendered line (side by side)"
        )

        -- * position: blank padding must separate the windows (not collapsed).
        --   With splitright the new (second) window is on the RIGHT, so its
        --   content must start after the first window's content + blank padding.
        local first_start = shared_line:find("first win content")
        local second_start = shared_line:find("second win content")
        assert.is_not_nil(first_start, "first win content should have a position")
        assert.is_not_nil(second_start, "second win content should have a position")
        assert.is_true(
            second_start > first_start,
            "with splitright the second window should be to the right of the first"
        )

        -- * the gap between the two contents must be pure blank space,
        --   proving they render in their own columns
        local between = shared_line:sub(first_start + #"first win content", second_start - 1)
        assert.is_true(#between > 0, "there should be blank padding between the two split windows")
        assert.is_true(between:match("^%s*$") ~= nil, "the gap between windows should be blank space")

        -- * cleanup: restore splitright and close the extra window
        vim.o.splitright = save_splitright
        vim.cmd(":q!")
    end)
end)
