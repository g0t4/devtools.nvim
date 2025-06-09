local require_parser = require("devtools.ts.require_parser")
local eq = assert.are.same

describe("require_parser", function()
    it("extracts require paths from local declarations", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            'local x = require("foo.bar")',
            'local y = require("baz")',
        })
        vim.api.nvim_set_current_buf(buf)

        local results = require_parser.get_static_requires_lua(buf)
        -- print(vim.inspect(results))

        eq(#results, 2)
        eq(results[1].var, "x")
        eq(results[1].path, '"foo.bar"')
        eq(results[2].var, "y")
        eq(results[2].path, '"baz"')
    end)
end)
