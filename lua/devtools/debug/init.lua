local fails = require("devtools.logs.fails")

--- usage:
---   xpcall(do_something, full_traceback_xpcall)
--- does NOT truncate paths!
function full_traceback_xpcall(error_message)
    -- PRN can I recreate the full path? at least in some cases?
    -- find part of path within current repo => then recreate stem
    -- would work well except for files w/in repo that are deeply nested and/or long dir/file names

    -- FYI error_message comes from xpcall internals, no way to fix the truncated path within it... it's just a string
    -- you could do a path search for it... maybe lazily just within traceback paths... but you won't get original

    --   TODO can I use this beyond xpcall? where error callback is used?
    --
    -- alternative to debug.traceback which has has truncated paths (super annoying)


    local lines = {
        tostring(error_message),
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

