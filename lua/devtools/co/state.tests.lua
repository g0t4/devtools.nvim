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

    it("returns nil when getting state from main thread", function()
        local context = CoroutineStateTracker:get("log_context")
        assert.is_nil(context)
    end)

    it("throws error when setting state from main thread", function()
        local success, err = pcall(function()
            CoroutineStateTracker:set("log_context", "test_context")
        end)
        assert.is_false(success)
        assert.matches("cannot set coroutine state from main thread", err)
    end)

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
