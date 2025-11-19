local should = require("devtools.tests.should")
local str = require("devtools.tests.str")

describe("StringAsserts -", function()
    it("double wrapping should work", function()
        str(str("hello world")):should_start_with("hello")
    end)

    it("tostring(str) is transparent, appears as a string", function()
        expect(tostring(str("foo")) == "foo")
    end)

    describe("forwards select string methods", function()
        it("forwards string methods like find", function()
            expect(str("hello"):find() == 5)
            --TODO add as needed
            -- expect(str("hello"):sub(1, 3) == "hel")
        end)
    end)

    describe("__concat", function()
        it("with str", function()
            local result = str("hello") .. str(" world")
            expect(result == str("hello world"))
        end)

        it("with string", function()
            local result = str("hello") .. " world"
            expect(result == str("hello world"))
        end)
    end)

    describe("relational operations", function()
        -- FYI CANNOT mix types with relational operations
        --  hence limited test cases:

        -- __eq
        it("str == str", function()
            expect(str("hello") == str("hello"))
        end)
        it("str ~= str", function()
            expect(str("hello") ~= str("world"))
        end)

        -- __le
        it("str <= str (less than)", function()
            expect(str("apple") <= str("banana"))
        end)
        it("str <= str (equal)", function()
            expect(str("apple") <= str("apple"))
        end)
        it("not str <= str", function()
            expect(not (str("zebra") <= str("apple")))
        end)

        -- __lt
        it("str < str", function()
            expect(str("alpha") < str("beta"))
        end)
        it("not str < str (same strings)", function()
            expect(not (str("gamma") < str("gamma")))
        end)
        it("not str < str (greater)", function()
            expect(not (str("zebra") < str("apple")))
        end)
    end)

    it("string:should_start_with", function()
        str("hello world"):should_start_with("hello")
        str("test"):should_start_with("")
        str(""):should_start_with("")
        assert.error(function() str(""):should_start_with("nonempty") end)
        assert.error(function() str("foobar"):should_start_with("bar") end)
    end)

    it("string:should_end_with", function()
        str("hello world"):should_end_with("world")
        str("test"):should_end_with("")
        str(""):should_end_with("")
        assert.error(function() str(""):should_end_with("nonempty") end)
        assert.error(function() str("foobar"):should_end_with("foo") end)
    end)

    it("string:should_contain", function()
        str("hello world"):should_contain("hello")
        str("test"):should_contain("")
        str(""):should_contain("")
        assert.error(function() str(""):should_contain("nonempty") end)
        assert.error(function() str("foobar"):should_contain("rab") end)
    end)
end)
