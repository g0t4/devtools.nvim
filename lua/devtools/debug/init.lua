local fails = require("devtools.logs.fails")

--- usage:
---   xpcall(do_something, full_traceback_xpcall)
--- does NOT truncate paths!
---
-- alternative to debug.traceback which has has truncated paths (super annoying)
function full_traceback_xpcall(error_message)
    local lines = {
        tostring(error_message),
        -- FYI error_message comes from xpcall internals and other error handlers
        --    LEAVE ERROR MESSAGE AS-IS => do not waste time "fixing" the '...' truncated path, nor "stripping" the path
        --    b/c if you mess up your traceback (i.e. in some edge case)... then error message will be critical to show that something is amiss!
        --    btw if you really wanna change anything, find what raises these errors and understand it first
        --      I have seen them in both hs and nvim...

        "",
        "stack traceback:",
    }

    local level_base0 = 2
    while true do
        local info = debug.getinfo(level_base0, "Slnfu")
        if not info then
            break
        end

        local source = info.source

        if source:sub(1, 1) == "@" then
            source = source:sub(2)
        end

        local name = info.name or "<anonymous>"

        local what = info.namewhat
        if what == "" then
            what = info.what
        end

        lines[#lines + 1] = string.format(
            "  %s:%d: %s '%s' [%s]",
            source,
            info.currentline,
            what,
            name,
            tostring(info.func)
        )

        level_base0 = level_base0 + 1
    end

    local trace = table.concat(lines, "\n")
    fails.add_failure(trace) -- could add objects too instead of traceback string then later transform depending on downstream use case?
    fails.copy_last_failure()
    return trace
end
