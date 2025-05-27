local assert = require('luassert')

local super_iter = require('devtools.super_iter')

describe("super_iter extends vim.iter's Iter type", function()
    it("is a table w/ map and totable()", function()
        local iter_test = super_iter({ 1, 2, 3 })
        assert.are_equals("table", type(iter_test))

        local mapped = iter_test:map(function(x) return x + 1 end):totable()
        assert.are_same({ 2, 3, 4 }, mapped)
    end)
    -- PRN do I care to validate beyond checking for map/totable?
end)

describe("super_iter:tolist()", function()
    it("on a list returns list", function()
        local iter = super_iter({ 1, 2, 3 })
        assert.are_same({ 1, 2, 3 }, iter:tolist())
    end)
end)

describe("super_iter:sort()", function()
    it("returns new sorted copy of Iter", function()
        local unsorted = { [3] = 'b', [2] = 'a' }
        local sorted = super_iter(unsorted):sort(function(a, b) return a < b end):totable()
        assert.are_same({ 'a', 'b' }, sorted)
    end)

    -- it("modifies nil table values to be empty strings", function()
    --     -- PRN why do I want this behaviour?
    --     local unsorted = { [3] = 'b', [2] = nil }
    --     local sorted = super_iter(unsorted):sort(function(a, b) return a < b end):totable()
    --     assert.are_same({ '', 'b' }, sorted)
    -- end)
end)
