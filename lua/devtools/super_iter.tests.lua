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
