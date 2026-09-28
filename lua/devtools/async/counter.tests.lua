local histogram = require('devtools.diff.histogram')
local should = require('devtools.tests.should')
local combined = require('devtools.diff.combined')
local describe = require('devtools.tests.describe')
local only = require('devtools.tests.only')
local skip = require('devtools.tests.skip')

local Counter = require("devtools.async.counter")

describe("Counter", function()
    it("wait does not throw if count is zero before timeout", function()
        local counter = Counter:new()
        counter:increment()
        counter:decrement()
        -- make it fast, timeout duration is unimportant here
        counter:wait(10)
    end)

    it("wait throws after timeout, if count is not zero", function()
        assert.has_error(function()
            local counter = Counter:new()
            counter:increment()
            -- make it fast, timeout duration is unimportant here
            counter:wait(10)
        end, "Counter not done after 10 ms (count=1 should be 0)")
    end)
end)
