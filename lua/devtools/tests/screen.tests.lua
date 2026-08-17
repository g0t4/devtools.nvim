local describe = require('devtools.tests.define.describe')
local screen = require("devtools.tests.screen")
local notify = require("devtools.notify")

describe("devtools.tests.screen", function()
    it("returns a multi-line string", function()
        local dump = screen.dump()
        -- vim.print(dump)
        assert.is_string(dump)
        assert.is_true(#dump > 0)
        assert.is_true(#vim.split(dump, "\n") >= 2)
    end)

    it("renders a notification box when one is visible", function()
        local n = notify.info("hello world", { timeout = 0 })
        local dump = screen.dump()
        -- vim.print(dump)
        assert.is_true(dump:match("hello world") ~= nil, "dump should contain the notification text")
        assert.is_true(dump:match("%+%-+%+") ~= nil or dump:match("┌") ~= nil, "dump should contain a box border")
        n:dismiss()
    end)

    it("does not show notification text after it is dismissed", function()
        local n = notify.info("ghost", { timeout = 0 })
        n:dismiss()
        local dump = screen.dump()
        -- vim.print(dump)
        assert.is_false(dump:match("ghost") ~= nil, "dismissed notification text should be gone")
    end)
    it("renders content from multiple regular (split) windows", function()
        -- * setup: first buffer/window
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first window content" })
        -- * create a second split window with different content
        vim.cmd(":new")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "second window content" })

        local dump = screen.dump()
        -- vim.print(dump)

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
        -- vim.print(dump)

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
    it("renders content from a 4-way split (2x2 grid) of 4 separate buffers", function()
        -- * setup: splitright matches the user's config so new windows open on
        --   the RIGHT; splitbelow stays false so :split opens new windows ABOVE.
        local save_splitright = vim.o.splitright
        vim.o.splitright = true

        -- * note: `:vsplit new` / `:split new` reuse the same empty unnamed
        --   buffer, so to get 4 REAL separate buffers we split the window (no
        --   `new`) and then create + attach an explicit buffer to each window.

        -- * the words contain hyphens, which are the lazy-quantifier operator
        --   in Lua patterns, so use a PLAIN substring search (find, plain=true)
        --   instead of match/pattern search.
        local function contains(haystack, needle)
            return haystack:find(needle, 1, true) ~= nil
        end

        -- * buffer A: original window, ends up in the left-bottom quadrant
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "left-bottom content" })

        -- * buffer B: vsplit puts a new window on the right; this window stays
        --   in the right column, ending up right-bottom after the next split
        vim.cmd(":vsplit")
        local buf_b = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_win_set_buf(0, buf_b)
        vim.api.nvim_buf_set_lines(buf_b, 0, -1, false, { "right-bottom content" })

        -- * buffer C: split the current (right column) window; the new window
        --   opens ABOVE it, ending up right-top
        vim.cmd(":split")
        local buf_c = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_win_set_buf(0, buf_c)
        vim.api.nvim_buf_set_lines(buf_c, 0, -1, false, { "right-top content" })

        -- * move back to the other (left) half of the vsplit and split it too
        vim.cmd(":wincmd h")
        -- * buffer D: the new window opens ABOVE the left column's window,
        --   ending up left-top
        vim.cmd(":split")
        local buf_d = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_win_set_buf(0, buf_d)
        vim.api.nvim_buf_set_lines(buf_d, 0, -1, false, { "left-top content" })

        -- * sanity: the 4 windows must each show a DISTINCT buffer (4 separate
        --   buffers); counting session-wide buffers would include leftovers from
        --   earlier tests, so compare the window buffers directly
        assert.is_equal(4, #vim.api.nvim_list_wins())
        local window_buffers = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            window_buffers[vim.api.nvim_win_get_buf(win)] = true
        end
        assert.is_equal(4, vim.tbl_count(window_buffers), "each of the 4 windows should show a distinct buffer")

        local dump = screen.dump()
        -- vim.print(dump)

        -- * all four unique words must show up
        assert.is_true(contains(dump, "left-top content"), "left-top content missing from dump")
        assert.is_true(contains(dump, "right-top content"), "right-top content missing from dump")
        assert.is_true(contains(dump, "left-bottom content"), "left-bottom content missing from dump")
        assert.is_true(contains(dump, "right-bottom content"), "right-bottom content missing from dump")

        -- * top row: left-top and right-top must share a rendered line (side by
        --   side); bottom row: left-bottom and right-bottom must share a line
        local lines = vim.split(dump, "\n")
        local top_row = nil
        local bottom_row = nil
        for i, line in ipairs(lines) do
            if contains(line, "left-top content") then
                top_row = i
            end
            if contains(line, "left-bottom content") then
                bottom_row = i
            end
        end
        assert.is_not_nil(top_row, "should find a rendered line with left-top content")
        assert.is_not_nil(bottom_row, "should find a rendered line with left-bottom content")
        assert.is_true(
            contains(lines[top_row], "right-top content"),
            "left-top and right-top should share the same rendered line (side by side)"
        )
        assert.is_true(
            contains(lines[bottom_row], "right-bottom content"),
            "left-bottom and right-bottom should share the same rendered line (side by side)"
        )

        -- * the top row must render above the bottom row
        assert.is_true(top_row < bottom_row, "the top row should render above the bottom row")

        -- * cleanup: collapse back to a single window and restore splitright
        vim.cmd(":only!")
        vim.o.splitright = save_splitright
    end)
    it("renders a floating window on top of an underlying buffer", function()
        -- * underlying content the float will cover part of
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "underlying content here" })

        -- * a floating window overlaid on top with a distinctive word + border
        local float_buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, { "FLOAT WORD" })
        local float_win = vim.api.nvim_open_win(float_buf, false, {
            relative = "editor",
            row = 1, col = 8,
            width = 12, height = 3,
            border = "single",
            style = "minimal",
        })

        local dump = screen.dump()
        -- vim.print(dump)


        -- * both the underlying and the floating content must show up
        assert.is_true(dump:find("underlying content", 1, true) ~= nil, "underlying content missing from dump")
        assert.is_true(dump:find("FLOAT WORD", 1, true) ~= nil, "float content missing from dump")

        -- * the float must be drawn as a bordered box ON TOP (not appended to)
        --   the underlying buffer, so find the rendered row and its box top
        local lines = vim.split(dump, "\n")
        local float_row = nil
        for i, line in ipairs(lines) do
            if line:find("FLOAT WORD", 1, true) then
                float_row = i
                break
            end
        end
        assert.is_not_nil(float_row, "should find a rendered line with FLOAT WORD")

        -- * the row directly above the content is the box's top edge, so it
        --   must carry a top-left corner character (┌ for nvim's box-drawing
        --   border table, + for a plain single-line fallback). We check for the
        --   corner's PRESENCE rather than an exact column so the assertion stays
        --   robust to how nvim sizes the float box.
        local border_line = lines[float_row - 1]
        assert.is_true(
            border_line:find("┌", 1, true) ~= nil or border_line:find("+", 1, true) ~= nil,
            "the float should have a top-left border corner above its content"
        )

        -- * cleanup: close the floating window
        vim.api.nvim_win_close(float_win, false)
    end)

    it("renders a border around regular windows when winborder is set", function()
        local save_winborder = vim.o.winborder
        vim.o.winborder = "single"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "left window text" })
        vim.cmd(":vsplit")
        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_win_set_buf(0, buf)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "right window text" })

        local dump = screen.dump()
        -- vim.print(dump)

        assert.is_true(dump:find("left window text", 1, true) ~= nil, "left window text missing from dump")
        assert.is_true(dump:find("right window text", 1, true) ~= nil, "right window text missing from dump")
        -- a single border draws "|" vertical edges and "+" corners
        assert.is_true(dump:find("|", 1, true) ~= nil, "vertical border edge missing")
        assert.is_true(dump:find("+", 1, true) ~= nil, "border corner missing")

        vim.o.winborder = save_winborder
        vim.cmd(":q!")
    end)

    it("renders the tabline on the top row when shown", function()
        local save_showtabline = vim.o.showtabline
        local save_tabline = vim.o.tabline
        vim.o.showtabline = 2
        vim.o.tabline = "TABS-%N"

        local dump = screen.dump()
        -- vim.print(dump)
        local first_line = vim.split(dump, "\n")[1]
        assert.is_true(first_line:find("TABS-", 1, true) ~= nil, "tabline should render on the top row")

        vim.o.showtabline = save_showtabline
        vim.o.tabline = save_tabline
    end)

    it("renders a per-window statusline when laststatus is 2", function()
        local save_laststatus = vim.o.laststatus
        local save_statusline = vim.o.statusline
        vim.o.laststatus = 2
        vim.o.statusline = "MYSTATUS"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "content" })

        local dump = screen.dump()
        -- vim.print(dump)
        assert.is_true(dump:find("MYSTATUS", 1, true) ~= nil, "statusline text missing from dump")

        vim.o.laststatus = save_laststatus
        vim.o.statusline = save_statusline
    end)

    it("does not render statuslines when laststatus is 0", function()
        local save_laststatus = vim.o.laststatus
        local save_statusline = vim.o.statusline
        vim.o.laststatus = 0
        vim.o.statusline = "GHOSTSL"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "content" })

        local dump = screen.dump()
        -- vim.print(dump)
        assert.is_false(dump:find("GHOSTSL", 1, true) ~= nil, "statusline should not appear when laststatus=0")

        vim.o.laststatus = save_laststatus
        vim.o.statusline = save_statusline
    end)

    it("renders a single global statusline when laststatus is 3", function()
        local save_laststatus = vim.o.laststatus
        local save_statusline = vim.o.statusline
        vim.o.laststatus = 3
        vim.o.statusline = "GLOBALSL"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "content" })

        local dump = screen.dump()
        -- vim.print(dump)
        assert.is_true(dump:find("GLOBALSL", 1, true) ~= nil, "global statusline text missing from dump")

        vim.o.laststatus = save_laststatus
        vim.o.statusline = save_statusline
    end)

    it("renders a winbar at the top of a window, above its content", function()
        local save_winbar = vim.o.winbar
        vim.o.winbar = "MYWINBAR"
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "win content" })

        local dump = screen.dump()
        -- vim.print(dump)
        assert.is_true(dump:find("MYWINBAR", 1, true) ~= nil, "winbar text missing from dump")

        -- the winbar must sit on a row ABOVE the buffer content
        local lines = vim.split(dump, "\n")
        local winbar_row = nil
        local content_row = nil
        for i, line in ipairs(lines) do
            if line:find("MYWINBAR", 1, true) then
                winbar_row = i
            end
            if line:find("win content", 1, true) then
                content_row = i
            end
        end
        assert.is_not_nil(winbar_row, "should find a rendered winbar row")
        assert.is_not_nil(content_row, "should find a rendered content row")
        assert.is_true(winbar_row < content_row, "the winbar should render above the buffer content")

        vim.o.winbar = save_winbar
    end)

    it("reserves the bottom cmdline row (blank when idle)", function()
        local save_cmdheight = vim.o.cmdheight
        vim.o.cmdheight = 1
        vim.api.nvim_buf_set_lines(0, 0, -1, false, { "cmd content" })

        local dump = screen.dump()
        -- vim.print(dump)
        local lines = vim.split(dump, "\n")
        local last_line = lines[#lines]
        -- no command is being typed, so the reserved cmdline row must be blank
        assert.is_true(last_line:match("^%s*$") ~= nil, "idle cmdline row should be blank")

        vim.o.cmdheight = save_cmdheight
    end)

end)
