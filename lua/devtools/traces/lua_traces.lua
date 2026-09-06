local log = require("devtools.logs.logger"):universal()

local M = {}

local function lua_short_path(path)
    local idsize = 60
    local max_length = idsize - 1
    if #path <= max_length then
        return path
    end
    return "..." .. path:sub(-(max_length - 3))
end

local cached_fixes = {}
---@param original_path string -- path from traceback -- truncated ("..." prefix), relative or absolute
---@return string? - returns the resolved path OR nil if cannot resolve (i.e. invalid path)
function M.resolve_truncated_path(original_path)
    if original_path == "..." then
        return nil
    end
    local is_absolute = original_path:match("^/")
    if is_absolute then
        return original_path -- as-is
    end
    local is_relative = original_path:match("^%./")
    if is_relative then
        return original_path
    end

    local cached = cached_fixes[original_path]
    if cached then
        return cached
    end

    local suffix = original_path:gsub("^%.%.%.", "")

    -- TODO hammerspoon will need diff roots to look through
    --  and especially add /Applications/Hammerspoon.app/Contents
    --   TODO find paths for HS path?
    --    use hs CLI to run the search! and then just update this logic to detect hammerspoon vs not (the stack trace as HS vs not?) or just run this with host process type?
    --        devtools.host?
    --
    -- FYI technically we don't need workspace_root first, it is probably the best place to look first
    --  unless the errors aren't in your own code
    local workspace_root = vim.fn.getcwd()
    local roots = { workspace_root }
    local seen = { [workspace_root] = true }

    for root in vim.gsplit(vim.o.runtimepath, ",", { plain = true }) do
        root = vim.fn.fnamemodify(root, ":p")

        if not seen[root] then
            seen[root] = true
            table.insert(roots, root)
        end
    end

    for _, root in ipairs(roots) do
        -- print("  CHECKING " .. root)
        local cmd = {
            "fd",
            -- "--type", "file",
            "--absolute-path",
            "--full-path",
            "--fixed-strings",
            suffix,
            root,
        }
        local result = vim.system(cmd, { text = true }):wait()

        if result.code == 0 then
            local matches = vim
                .iter(vim.gsplit(result.stdout, "\n", { plain = true }))
                :filter(function(path)
                    return path ~= ""
                end)
                :totable()

            if #matches == 1 then
                local match = matches[1]
                if lua_short_path(match) == original_path then
                    cached_fixes[original_path] = match
                    return match
                end
            elseif #matches > 1 then
                vim.print(table.concat(cmd, " ")) -- leave print of command so I can replicate
                error(("Multiple matches for %q:\n%s"):format(
                    original_path,
                    table.concat(matches, "\n")
                ))
            end
        end
    end

    return nil
end

function M.fix_paths_in_error(error_text)
    local fixed = error_text:gsub("(%.%.%.*[^:\n]+)", function(short_path)
        local full = M.resolve_truncated_path(short_path)
        return full or short_path
    end)
    return fixed
end

---Parse a lua traceback into quickfix list items.
---Truncated paths (from lua's error() shortening long paths to ~60 chars with a `...` prefix)
---are left as-is here; call resolve_truncated_path() (or load_trace_to_quickfix()) to fix them.
---@param trace string
---@return table[] -- quickfix items: { filename, lnum, col, text }
function M.parse_trace_for_quickfix(trace)
    local items = {}
    for line in vim.gsplit(trace, "\n", { plain = true }) do
        -- prefer a `...`-truncated path so prefixes like "vim.schedule callback:"
        -- don't get glued onto the filename (lua shortens long paths in stack traces)
        local path, lnum, text = line:match("(%.%.%.%S-):(%d+):(.*)$")
        if not path then
            -- fallback: look for absolute path with leading " /" (whitespace before the /)
            local prefix
            prefix, path, lnum, text = line:match("^(.-)%s+(/[^:]+):(%d+):(.*)$")
            -- log:info("prefix:", vim.inspect(prefix))
            -- TODO where can I put prefix to include it too?
            --   FYI only first line appears to have a prefix before file path
            --   TODO add this via test case that has an example "E5108: Lua: "
        end
        if not path then
            -- fallback: capture the path up to the first ":number:"
            --   (handles full paths and virtual frames like `[string "x"]`)
            path, lnum, text = line:match("^%s*(.-):(%d+):(.*)$")
        end
        if path then
            local filename = path:gsub("^%s+", ""):gsub("%s+$", "")
            local message = (text and text:gsub("^%s+", ""):gsub("%s+$", "")) or ""
            table.insert(items, {
                filename = filename,
                lnum = tonumber(lnum),
                col = 0,
                text = message,
            })
        end
    end
    log:debug("Parsed quickfix items:", items)
    return items
end

---Parse a lua traceback, resolve truncated paths, and load it into the quickfix list.
---@param trace string
function M.to_quickfix_items(trace)
    local items = M.parse_trace_for_quickfix(trace)
    for _, item in ipairs(items) do
        item.filename = M.resolve_truncated_path(item.filename) or item.filename
    end
    return items
end

return M
