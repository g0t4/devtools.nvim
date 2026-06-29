local assert = require 'luassert'
local describe = require('devtools.tests.define.describe')

describe("test CoroutineStateTracker", function()
    local CoroutineStateTracker = require("devtools.co.state")

    before_each(function()
        CoroutineStateTracker.reset()
    end)

    it("sets and gets state within a coroutine", function()
        local result = nil
        local co = coroutine.create(function()
            CoroutineStateTracker:set("log_context", "test_context")
            result = CoroutineStateTracker:get("log_context")
        end)
        coroutine.resume(co)
        assert.equals("test_context", result)
    end)

    -- describe("main thread cannot be tested w/ plenary, IIAC", function()
    --     it("returns nil when getting state from main thread", function()
    --         -- FYI cannot do this test IIAC with plenary test runner cuz it starts a coroutine for each test... so I can't be on main thread
    --         local co, is_main = coroutine.running()
    --         assert.is_true(is_main, "TEST CANNOT WORK UNLESS IT STARTS WITH MAIN THREAD (COROUTINE)")
    --
    --         local context = CoroutineStateTracker:get("log_context")
    --         assert.is_nil(context, "should be nil")
    --     end)
    --
    --     it("throws error when setting state from main thread", function()
    --         -- FYI cannot do this test IIAC with plenary test runner cuz it starts a coroutine for each test... so I can't be on main thread
    --         local co, is_main = coroutine.running()
    --         assert.is_true(is_main, "TEST CANNOT WORK UNLESS IT STARTS WITH MAIN THREAD (COROUTINE)")
    --
    --         local success, err = pcall(function()
    --             CoroutineStateTracker:set("log_context", "test_context")
    --         end)
    --         assert.is_false(success)
    --         assert.matches("cannot set coroutine state from main thread", err)
    --     end)
    -- end)

    it("supports multiple keys per coroutine", function()
        local results = {}
        local co = coroutine.create(function()
            CoroutineStateTracker:set("log_context", "context_val")
            CoroutineStateTracker:set("other_key", "other_val")
            results.context = CoroutineStateTracker:get("log_context")
            results.other = CoroutineStateTracker:get("other_key")
        end)
        coroutine.resume(co)
        assert.equals("context_val", results.context)
        assert.equals("other_val", results.other)
    end)
end)
