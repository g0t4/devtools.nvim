local inspect = require("devtools.inspect")
local describe = require('devtools.tests._describe')

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
        inspect({}) -- "{ }"
        inspect({ 1, 2, 3 }) --  == "{ 1, 2, 3, }"
        inspect({ a = 1, b = 2, [3] = 4 })
        inspect({ a = 'foo" the bar' })
    end)


    it("inspect.wtf", function()
        local result = inspect.wtf("wtf")
        assert(result == "wtf")
    end)
end)

describe("bat_json", function()
    it("numeric value with ansi escape color codes... partial verification, struggling to verify full sequence matches", function()
        local result = inspect.bat_json(1)

        -- Verify that the output still contains ANSI escape sequences (e.g., color codes)
        local has_ansi = result:find("\27%[") ~= nil
        assert.is_true(has_ansi, "Result should contain ANSI escape sequences")

        -- Verify the plain text representation without colors
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches('1', result_without_color)
    end)

    it("table value", function()
        local result = inspect.bat_json({ a = 1, b = 2 })
        -- print(result)
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        -- print(result_without_color)
        assert.matches('{"a": 1, "b": 2}', result_without_color)
    end)

    it("string value", function()
        local result = inspect.bat_json("wtf")
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches('"wtf"', result_without_color)
    end)

    it("nil value", function()
        local result = inspect.bat_json(nil)
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches("null", result_without_color)
    end)
end)

describe("bat_inspect", function()
    it("table value", function()
        local result = inspect.bat_inspect({ a = 1, b = 2 })
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches("a = 1", result_without_color)
        assert.matches("b = 2", result_without_color)
    end)

    it("string value", function()
        local result = inspect.bat_inspect("wtf")
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches('"wtf"', result_without_color)
    end)

    it("nil value", function()
        local result = inspect.bat_inspect(nil)
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches("nil", result_without_color)
    end)
end)

describe("jq_json", function()
    it("numeric value", function()
        local result = inspect.jq_json(1)
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches('1', result_without_color)
    end)

    it("table value - not compact", function()
        local result = inspect.jq_json({ a = 1, b = 2 })
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches('{\n  "a": 1,\n  "b": 2\n}', result_without_color)
    end)

    it("table value - compact", function()
        local result = inspect.jq_json({ a = 1, b = 2 }, true)
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches('{"a":1,"b":2}', result_without_color)
    end)

    it("string value", function()
        local result = inspect.jq_json("wtf")
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches('"wtf"', result_without_color)
    end)

    it("nil value", function()
        local result = inspect.jq_json(nil)
        local result_without_color = inspect.strip_ansi_escape_sequences(result)
        assert.matches('null', result_without_color)
    end)
end)
