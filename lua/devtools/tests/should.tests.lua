local should = require("devtools.tests.should")
local str = require("devtools.tests.str")

--TODO! see if someone already made a library for this idea?

should.COLORFUL = false

describe("expect", function()
    describe("locals in outer scope", function()
        it("should still show values", function()
            local x = "100%"
            local y = 'something else'
            assert.error_match(function()
                expect(x == y)
            end, "assertion failed:\n *Source: *expect%(x == y%)\n *Values: *expect%(100%% == something else%)")
        end)
    end)

    describe("ensure values work", function()
        it("% shouldn't break showing values", function()
            assert.error_match(function()
                local x = "100%"
                local y = 'something else'
                expect(x == y)
            end, "assertion failed:\n *Source: *expect%(x == y%)\n *Values: *expect%(100%% == something else%)")
        end)
    end)

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
