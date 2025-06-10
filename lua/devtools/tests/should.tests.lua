local should = require("devtools.tests.should")

--TODO! see if someone already made a library for this idea?

describe("expect", function()
    describe("greater than ", function()
        describe("is greater than", function()
            it("literals works", function()
                -- this is the cleanest way to write tests IMO
                expect(5 > 3)
            end)
        end)

        describe("is less than", function()
            it("literals only shows Source: line", function()
                assert.error_match(function()
                    expect(5 > 10)
                end, "assertion failed:\n *Source: *expect%(5 > 10%)")
            end)

            it("numeric variables", function()
                assert.error_match(function()
                    local a = 5
                    local b = 10
                    expect(a > b)
                end, "Source: *expect%(a > b%)\n *Values: *expect%(5 > 10%)")
            end)

            it("table variables", function()
                -- PRN feels like overkill! use a local variable instead of table lookup in the expect call!
                -- assert.error_match(function()
                --     local nums = { 5, 10 }
                --     expect(nums[1] > nums[2])
                -- end, "Source: ...")
            end)
        end)
    end)
end)
