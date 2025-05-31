local inspect = require("devtools.inspect")

describe("exploratory", function()
    it("vim.islist", function()
        --
        -- lists:
        assert(vim.islist({ 1, 2, 3 }))
        assert(vim.islist({}))
        -- not lists:
        assert(vim.islist({ a = 1, b = 2, [3] = 4 }) == false)
    end)

    it("inspect", function()
        -- TODO add assertions and make into real tests?
        -- TODO flesh out more inspect testing!
        inspect({})          -- "{ }"
        inspect({ 1, 2, 3 }) --  == "{ 1, 2, 3, }"
        inspect({ a = 1, b = 2, [3] = 4 })
        inspect({ a = 'foo" the bar' })
    end)
end)
