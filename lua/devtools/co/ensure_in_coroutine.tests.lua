local histogram = require('devtools.diff.histogram')
local should = require('devtools.tests.should')
local combined = require('devtools.diff.combined')
local describe = require('devtools.tests.describe')
local only = require('devtools.tests.only')
local skip = require('devtools.tests.skip')

local TestTimer = require("devtools.async.test_timer")
local Counter = require("devtools.async.counter")

local ensure_in_coroutine = require("devtools.co.ensure_in_coroutine")

-- FYI alternative is to use async module, but I am happy with my ensure_in_coroutine
-- local async = require('plenary.async.tests')

local stop_after_this = only

describe("ensure_in_coroutine", function()
    it("should not start a new coroutine", function()
        local co_before, is_main = coroutine.running()
        assert.not_truthy(is_main, "assumed that test runner starts a coroutine and is thus not main thread") -- is_main is nil in plenary test runner, I thought it was a boolean?
        ensure_in_coroutine(function()
            local co_after = coroutine.running()
            should.be_equal(co_before, co_after)
        end)
    end)
    it("should attach timer to coroutine state", function()
        local CoroutineStateTracker = require("devtools.co.state")
        local co, is_main = coroutine.running()
        assert.not_truthy(is_main, "assumed that test runner starts a coroutine and is thus not main thread") -- is_main is nil in plenary test runner, I thought it was a boolean?
        ensure_in_coroutine(function()
            local timer = CoroutineStateTracker.get("timer")
            assert.not_nil(timer, "timer not set")
        end)
    end)
    it("should not create new timer if ensure_in_coroutine is nested", function()
        local CoroutineStateTracker = require("devtools.co.state")
        local co, is_main = coroutine.running()
        assert.not_truthy(is_main, "assumed that test runner starts a coroutine and is thus not main thread") -- is_main is nil in plenary test runner, I thought it was a boolean?
        ensure_in_coroutine(function()
            local timer = CoroutineStateTracker.get("timer")
            assert.not_nil(timer, "timer not set")
            ensure_in_coroutine(function()
                local timer2 = CoroutineStateTracker.get("timer")
                assert.not_nil(timer2, "timer not set")
                assert.are.equal(timer, timer2)
            end)
        end)
    end)
end)

