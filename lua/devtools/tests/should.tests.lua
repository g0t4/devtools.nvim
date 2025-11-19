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

it("string:should_start_with", function()
    ("hello world"):should_start_with("hello");
    ("test"):should_start_with("");
    (""):should_start_with("");

    assert.error(function() (""):should_start_with("nonempty") end);
    assert.error(function() ("foobar"):should_start_with("bar") end);
end)

it("string:should_end_with", function()
    ("hello world"):should_end_with("world");
    ("test"):should_end_with("");
    (""):should_end_with("");
    assert.error(function() (""):should_end_with("nonempty") end);
    assert.error(function() ("foobar"):should_end_with("foo") end);
end)

it("string:should_contain", function()
    ("hello world"):should_contain("hello");
    ("test"):should_contain("");
    (""):should_contain("");
    assert.error(function() (""):should_contain("nonempty") end);
    assert.error(function() ("foobar"):should_contain("rab") end);
end)
