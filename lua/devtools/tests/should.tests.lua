local should = require("devtools.tests.should")

--TODO! see if someone already made a library for this idea?

describe("expect", function()
    it("greater than passes", function()
        -- this is the cleanest way to write tests IMO
        expect(5 > 3)
    end)
    it("greater than fails", function()
        assert.error(function()
                expect(5 > 10)
            end,
            -- FYI careful with whitespace in erorr message, that includes the source line...
            --  might want to manually parse the error message and verify regardless of whitespace?
            [[

assertion failed:
                expect(5 > 10)]])
    end)
end)
