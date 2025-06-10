local assert = require('luassert')

local M = {}

function M.be_greater_than(expected, actual)
    error("move to expect, or just assert(x>y)... this was a terrible idea")
    local is_greater_than = actual > expected
    assert.is_true(is_greater_than)
end

function M.be_equal(expected, actual)
    assert.are.equal(expected, actual)
end

function M.be_same(expected, actual)
    assert.are.same(expected, actual)
end

function M.be_nil(actual)
    -- FYI you can join with _ instead of dot (.)
    --   must use this for keywords like nil, function, etc
    assert.is_nil(actual)
end

function expect(truthy)
    -- TODO should this be a module? leave it global for now?
    -- SPIKE an idea for a new expect that can make it easier to understand what went wrong... think of reverse engineering the test code that triggered this
    --   first off I can just print the expect call's source line
    --    later I could analyze it as an expression and replace vars w/ values  (if useful)
    if truthy then
        return
    end

    -- PRN also print other lines? maybe detect what called what... can help if I have assertion helpers for reuse
    local calling_frame = debug.getinfo(2, "Sln")
    -- vim.print(tb)

    local is_a_file = calling_frame.source:match("^@")
    if not is_a_file then
        print("Not Implemented... source is not a file, for the code that called expect, cannot find its source line")
        return
    end

    local source = calling_frame.source:gsub("^@", "")
    local lines = vim.fn.readfile(source)
    local line = lines[calling_frame.currentline]
    -- vim.print("expect failed:", line)

    -- use \n so explanation stands out (much like builtin string comparison passedin/actual)
    -- error("\nassertion failed:\n" .. line)

    -- Collect local variables from the calling frame
    local locals = {}
    local num_locals = 1
    while true do
        print("locals[" .. num_locals .. "]=" .. tostring(debug.getlocal(2, num_locals)))
        local name, value = debug.getlocal(2, num_locals)
        if not name then break end
        locals[name] = tostring(value)
        num_locals = num_locals + 1
    end

    if num_locals == 1 then
        error("\nassertion failed:\n  Source: " .. line)
        return
    end

    -- Substitute local variable names with their values in the line
    local substituted_line = line
    for name, value in pairs(locals) do
        -- Simple pattern: replace whole word matches of the variable name
        substituted_line = substituted_line:gsub("%f[%w]" .. name .. "%f[%W]", value)
    end

    error("\nassertion failed:\n  Source: " .. line .. "\n  Values: " .. substituted_line)
end

return M
