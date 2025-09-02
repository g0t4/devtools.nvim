local M = {}

--- Add commas to a number. e.g. 1234567 -> 1,234,567
---@param amount integer|number|string -- numeric value
---@return string
function M.comma_delimit(amount)
    -- from http://lua-users.org/wiki/FormattingNumbers
    local formatted = amount
    while true do
        -- match leading digits only (optional - in front)
        -- capture 1: %d+ is greedy, matches all but the last three digits
        -- capture 2: "(%d%d%d)" three digits
        -- on a match, comma delimits the least significant digits
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    ---@type string
    return formatted
end

function M.round(val, decimal)
    if (decimal) then
        return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
    else
        return math.floor(val + 0.5)
    end
end

function M.format_num(amount, decimal, prefix, neg_prefix)
    local str_amount, formatted, famount, remain

    decimal = decimal or 2 -- default 2 decimal places
    neg_prefix = neg_prefix or "-" -- default negative sign

    famount = math.abs(M.round(amount, decimal))
    famount = math.floor(famount)

    remain = M.round(math.abs(amount) - famount, decimal)

    -- comma to separate the thousands
    formatted = M.comma_delimit(famount)

    -- attach the decimal portion
    if (decimal > 0) then
        remain = string.sub(tostring(remain), 3)
        formatted = formatted .. "." .. remain ..
            string.rep("0", decimal - string.len(remain))
    end

    -- attach prefix string e.g '$'
    formatted = (prefix or "") .. formatted

    -- if value is negative then format accordingly
    if (amount < 0) then
        if (neg_prefix == "()") then
            formatted = "(" .. formatted .. ")"
        else
            formatted = neg_prefix .. formatted
        end
    end

    return formatted
end

return M
