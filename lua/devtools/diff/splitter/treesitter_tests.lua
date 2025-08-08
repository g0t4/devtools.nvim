local ts = vim.treesitter
local messages = require("devtools.messages")

--- Tokenize a snippet of code using Tree-sitter
--- @param code string  the code to tokenize
--- @return string[]    list of token texts
local function tokenize(code)
    -- 1. use current buffer’s filetype
    -- local ft = vim.bo.filetype
    local ft = "lua"

    -- 2. create a hidden scratch buffer and set its lines
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(code, '\n', true))
    vim.bo[bufnr].filetype = ft

    local start = vim.loop.hrtime() --


    -- FYI timing for 3 through 4 (not 5) is 0.11ms (worst case) and often 0.04ms
    -- medium size is 0.5ms worst case and on down to 0.3ms
    -- so very likely I could support this but I would want it to prove much more effective than a simple regex style (lua pattern) split

    -- 3. parse it
    local parser = ts.get_parser(bufnr, ft)
    local tree = parser:parse()[1]
    local root = tree:root()

    -- 4. recursively collect all leaf-node texts
    local tokens = {}
    local function walk(node)
        if node:child_count() == 0 then
            local txt = ts.get_node_text(node, bufnr)
            table.insert(tokens, txt)
        else
            for i = 0, node:child_count() - 1 do
                walk(node:child(i))
            end
        end
    end

    walk(root)
    local duration = vim.loop.hrtime() - start
    print("Tokenize time:", duration / 1000000000, "seconds")
    print("Tokenize time:", duration / 1000000, "ms")

    -- 5. clean up and return
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return tokens
end

-- example
local snippet = [[
function add(a, b)
  return a + b
end
]]
print(vim.inspect(tokenize(snippet)))
print()
local snippet_big = [[
-- This is a Lua file that does some basic math.
-- Function to add two numbers
function add(a, b)
  return a + b
end
-- Function to subtract two numbers
function subtract(a, b)
  return a - b
end
-- Function to multiply two numbers
function multiply(a, b)
  return a * b
end
-- Function to divide two numbers
function divide(a, b)
  if b ~= 0 then
    return a / b
  else
    print("Error: Cannot divide by zero.")
    return nil
  end
end
]]
print(vim.inspect(tokenize(snippet_big)))
