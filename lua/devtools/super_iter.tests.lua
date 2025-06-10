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

    it("warn user if nil passed", function()
        local iter = super_iter({})
        assert.error(function()
            -- simulate passing nil
            iter.tolist()
            -- s/b iter:tolist()
        end, "nil passed to super_iter's tolist(), are you using .tolist() when you need to use :tolist()?")
    end)
end)

describe("super_iter:sort()", function()
    -- do not reproduce tests for table.sort, just test that you wired it up properly
    it("sorts w/o a comparator function", function()
        local unsorted = { 'a', 'c', 'b' }
        local sorted = super_iter(unsorted):sort():totable()
        assert.are_same({ 'a', 'b', 'c' }, sorted)
    end)

    it("sorts w/ comparator function", function()
        local unsorted = { 'a', 'c', 'b' }
        -- using > flips the order (reverses it)
        local sorted = super_iter(unsorted):sort(function(a, b) return a > b end):totable()
        assert.are_same({ 'c', 'b', 'a' }, sorted)
    end)
end)


describe("super_iter:group_by()", function()
    it("groups list by a key function", function()
        local iter = super_iter({
            { id = 1, name = 'Bob' },
            { id = 2, name = 'Alice' },
            { id = 1, name = 'John' },
            { id = 3, name = 'Bob' },
        })
        local grouped = iter:group_by(function(x) return x.id end):totable()
        assert.are_same({
            { id = 1, name = 'Bob' },
            { id = 1, name = 'John' },
        }, grouped[1])
        assert.are_same({
            { id = 2, name = 'Alice' },
        }, grouped[2])
        assert.are_same({
            { id = 3, name = 'Bob' },
        }, grouped[3])
    end)
end)
