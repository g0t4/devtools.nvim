local lua = require("devtools.lua")
local should = require("devtools.tests.should")

describe("which_module", function()
    it("returns devtools.messages path", function()
        local path = lua.which_module("devtools.messages")
        should.be_equal("./lua/devtools/messages.lua", path)
    end)

    it("returns nil for nonexistent module", function()
        local path = lua.which_module("devtools.messages.nonexistent")
        should.be_equal(nil, path)
        -- PRN? error?
    end)
end)
