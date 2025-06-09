local symbols = require("devtools.context.symbols")
local should = require("devtools.tests.should")

describe("context", function()
    it("finds all symbols", function()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
            'local messages = require("devtools.messages")',
        })
        vim.api.nvim_set_current_buf(buf)
        local symbols = symbols.get_imported_symbols(buf)
        -- should.be_equal(#symbols, 1)
        -- should.be_equal("messages", symbols[1].name)
        -- should.be_equal('"devtools.messages"', symbols[1].path)
    end)

    describe("TODO when at top of file", function()
        it("TODO find project wide imports and frequency", function()
            -- TODO
            -- TODO how about... if I am at the top of a file, add this to the context! (within top 20 lines or smth like that!)
        end)
    end)
end)
