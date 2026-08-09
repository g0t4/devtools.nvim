local buffers = require("devtools.tests.buffers")

-- these tests import buffers.lua, so its embedded describe block also runs here

describe("new_buffer_with_lines", function()
    describe("creates a new buffer", function()
        it("returns a buffer id that didn't exist before and is valid after", function()
            local bufs_before = vim.api.nvim_list_bufs()
            -- vim.print('bufs_before', bufs_before)

            local bufnr = buffers.new_buffer_with_lines({ "a", "b" })

            local bufs_after = vim.api.nvim_list_bufs()
            -- vim.print('bufs_after', bufs_after)

            assert.is_false(vim.tbl_contains(bufs_before, bufnr), "buffer should not exist before the call")
            assert.is_true(vim.tbl_contains(bufs_after, bufnr), "buffer should exist after the call")
            -- make sure difference is only the new buffer too
            local in_after_and_before = vim.tbl_filter(function(bufnr) return vim.tbl_contains(bufs_before, bufnr) end, bufs_after)
            -- vim.print("in after and before", in_after_and_before)
            assert.are.same(in_after_and_before, bufs_before, "make sure nothing removed")
            local in_after_but_not_before = vim.tbl_filter(function(bufnr) return not vim.tbl_contains(bufs_before, bufnr) end, bufs_after)
            -- vim.print("after that was not in before", in_after_but_not_before)
            assert.are.same(in_after_but_not_before, { bufnr }, "only new buffer is the one created")
            assert.is_true(vim.api.nvim_buf_is_valid(bufnr), "buffer should be valid")
        end)

        it("returns a fresh buffer id on each call", function()
            local bufnr_1 = buffers.new_buffer_with_lines({ "a" })
            local bufnr_2 = buffers.new_buffer_with_lines({ "a" })

            assert.is_not.equal(bufnr_1, bufnr_2)
        end)
    end)

    describe("creates a new window", function()
        it("returns a window id that didn't exist before and is valid after", function()
            local wins_before = vim.api.nvim_list_wins()

            local _, win = buffers.new_buffer_with_lines({ "a", "b" })

            local wins_after = vim.api.nvim_list_wins()
            assert.is_false(vim.tbl_contains(wins_before, win), "window should not exist before the call")
            assert.is_true(vim.tbl_contains(wins_after, win), "window should exist after the call")
            assert.is_true(vim.api.nvim_win_is_valid(win), "window should be valid")
        end)

        it("returns a fresh window id on each call", function()
            local _, win_1 = buffers.new_buffer_with_lines({ "a" })
            local _, win_2 = buffers.new_buffer_with_lines({ "a" })

            assert.is_not.equal(win_1, win_2)
        end)
    end)
end)
