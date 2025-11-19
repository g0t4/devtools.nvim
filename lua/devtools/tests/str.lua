local combined = require("devtools.diff.combined")

-- *** STRINGS
--   FYI (monkey patch for a readable API)
--   alternative:
--     expect(prompt):starts_with(START) ... basically wrap the string with a new type that has the new "methods"
--   why? because ORDER MATTERS for both:
--     READABILITY
--     and *COMPARISON*
--
--   consider:
--     assert.starts_with(prompt, token) ...
--     assert.starts_with(token, prompt) ... which comes first MATTERS for both READABILITY and the COMPARISON!
--     ... which order is right? have to look at docs to figure it out! Or, try to follow an _arbitrary_ convention


-- *** CLASS/INHERITANCE in LUA
--
--   Keep in mind:
--   - metatable defines special operations (i.e. __add, __call, and __index) ... aka metamethods
--   - __index = function|table
--     - table is a shortcut, to establish prototype chain (inheritance)
--   - * metatable ~= __index  (do not conflate them)
--     - flexible b/c these are separate and b/c every object can be customized with both
--     - this flexibility can easily be confusing in a given codebase depending on how it's used
--
--   1. what is the `class` instance? (i.e. StringAsserts)
--      a. does it have a custom metatable `class_mt`?
--         `setmetatable(class, class_mt)`
--         if so, what operations?
--         if want class to be callable... implement `class_mt.__call = function(self, ...) ... end`
--      b. does it subclass another type class?
--         aka => `class_mt.__index = ?`
--   2. is there a ctor (i.e. `:new()` or `.new()`) to make instances?
--      a. do instances have a metatable?
--         `setmetatable(instance, instance_mt)`
--         if so, what operations?
--      b. did you set `instance_mt.__index = class`
--         this is how instances inherit class's members
--
--   !!! define class_mt and instance_mt EXPLICITLY, not INLINE... then set each separately of course...
--   ! this is the KEY to clarity!

---@class StringOutput
---@field str string
local StringAsserts = {}

-- * Using a class_mt instances makes it CLEAR what the class has for metamethods/metatable (separate of instance metamethods)
local class_mt = {
    -- make StringAsserts callable: StringAsserts("foo") == StringAsserts.new("foo")
    __call = function(self, value)
        return StringAsserts.new(value)
    end
}
setmetatable(StringAsserts, class_mt)

-- * clearly see metamethods for instances
local instance_mt = {
    __index = StringAsserts -- so instances can inherit class members (key)... i.e. should_start_with
    -- by the way if you want subclassing, this has to be created in the ctor (where self==subclass usually... so { __index = self }
    --    this assumes subclass's __index points to the parent class and so on
}

---@param self StringOutput
---@param right StringOutput
function instance_mt.__add(self, right)
    return StringAsserts.new(self.str .. right.str)
end

---@param self StringOutput
function instance_mt.__tostring(self)
    return string.format("StringAsserts(%q)", self.str)
end

---@param value any
---@return StringOutput
function StringAsserts.new(value)
    if getmetatable(value) == instance_mt then
        return value
    end

    ---@type StringOutput
    local instance = {
        str = value
    }
    setmetatable(instance, instance_mt)
    return instance
end

---@param self StringOutput
---@param expected_prefix string
function StringAsserts:should_start_with(expected_prefix)
    local actual_prefix = self.str:sub(1, #expected_prefix)
    if actual_prefix == expected_prefix then return end

    error(string.format("expected string %q… to start with %q", actual_prefix, expected_prefix))
end

---@param self StringOutput
---@param expected_suffix string
function StringAsserts:should_end_with(expected_suffix)
    if expected_suffix == "" then return end

    local actual_suffix = self.str:sub(- #expected_suffix)
    if actual_suffix == expected_suffix then return end

    error(string.format("expected string %q… to end with %q", actual_suffix, expected_suffix))
end

---@param self StringOutput
---@param expected_substring string
function StringAsserts:should_contain(expected_substring)
    if self.str:find(expected_substring, 1, true) then return end

    local diff_message = combined.combined_word_diff(self.str, expected_substring)
    print("diff:\n" .. inspect_diff(diff_message))

    error(string.format("expected string %q to contain %q", self.str, expected_substring))
end

-- -- vim.inspect/print is a great way to see the prototype chain and metatables:
-- print('class: ' .. vim.inspect(StringAsserts))
-- print('instance: ' .. vim.inspect(StringAsserts("foo")))

-- returns callable!
return StringAsserts
-- intended usage:
--   local str = require("devtools.tests.str")
--   str("FOO")
