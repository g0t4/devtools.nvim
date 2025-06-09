local require_parser = require("devtools.ts.require_parser")
local should = require("devtools.tests.should")

describe("require_parser", function()
    it("extracts require paths from local declarations", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            'local x = require("foo.bar")',
            'local y = require("baz")',
            'local z = require(\'bob\')',
        })
        vim.api.nvim_set_current_buf(buf)

        local results = require_parser.get_static_requires_lua(buf)
        -- print(vim.inspect(results))

        should.be_equal(#results, 3)
        should.be_equal(results[1].var, "x")
        should.be_equal(results[1].path, 'foo.bar')
        should.be_equal(results[2].var, "y")
        should.be_equal(results[2].path, 'baz')
        should.be_equal(results[3].var, "z")
        should.be_equal(results[3].path, 'bob')
    end)
end)
