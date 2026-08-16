local describe = require("devtools.tests.define.describe")
local notify = require("devtools.notify")
local only = require("devtools.tests.define.only")

--- Wait for a condition to become true, polling every `poll_ms` milliseconds.
--- @param predicate fun(): boolean
--- @param timeout_ms number Maximum time to wait in milliseconds
--- @param poll_ms number Time between polls in milliseconds
--- @return boolean success Whether the condition became true before timeout
local function wait_for(predicate, timeout_ms, poll_ms)
    poll_ms = poll_ms or 50
    local start_time = vim.uv.hrtime() / 1e6

    while true do
        if predicate() then
            return true
        end

        local elapsed = vim.uv.hrtime() / 1e6 - start_time
        if elapsed >= timeout_ms then
            return false
        end

        -- Yield so pending timers (auto-dismiss) can fire
        vim.wait(poll_ms)
    end
end

describe("E2E - devtools.notify", function()
    only("notification appears immediately and auto-disappears after its timeout", function()
        -- * action: show a notification that auto-dismisses after 300ms
        local n = notify.info("hello world", { timeout = 300 })

        -- * appears right away: the window must exist and be visible
        assert.is_true(
            vim.api.nvim_win_is_valid(n.win_id),
            "notification window should be valid immediately after notify()"
        )

        -- * disappears on its own after the timeout fires
        local disappeared = wait_for(function()
            return not n.win_id or not vim.api.nvim_win_is_valid(n.win_id)
        end, 2000, 100)
        assert.is_true(disappeared, "notification should auto-dismiss after its timeout")
    end)

    it("sticky notification (timeout 0) stays until explicitly dismissed", function()
        -- * action: show a sticky notification
        local n = notify.warn("sticky", { timeout = 0 })

        -- * appears
        assert.is_true(vim.api.nvim_win_is_valid(n.win_id))

        -- * does NOT auto-disappear: give any (wrong) timers a chance to fire
        vim.wait(300)
        assert.is_true(
            vim.api.nvim_win_is_valid(n.win_id),
            "sticky notification (timeout 0) should not auto-dismiss"
        )

        -- * cleanup: explicit dismiss removes it
        local win_id = n.win_id
        n:dismiss()
        assert.is_false(vim.api.nvim_win_is_valid(win_id))
    end)

    it("dismiss_all removes every visible notification", function()
        -- * action: show several notifications and remember their windows
        local wins = {}
        table.insert(wins, notify.info("a", { timeout = 0 }).win_id)
        table.insert(wins, notify.info("b", { timeout = 0 }).win_id)
        table.insert(wins, notify.error("c", { timeout = 0 }).win_id)

        -- * all were shown
        for _, win_id in ipairs(wins) do
            assert.is_true(vim.api.nvim_win_is_valid(win_id))
        end

        -- * action: dismiss everything
        notify.dismiss_all()

        -- * verify: every window is now gone
        for _, win_id in ipairs(wins) do
            assert.is_false(vim.api.nvim_win_is_valid(win_id))
        end
    end)
end)
