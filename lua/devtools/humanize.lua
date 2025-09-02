local M = {}

--- Add commas to a number. e.g. 1234567 -> 1,234,567
---@param amount integer|number|string -- numeric value
---@return string
function M.comma_delimit(amount) -- credit http://richard.warburton.it
    -- `left`/`right` capture groups grab the prefix and suffix around the number
    --   `right` includes decimal places
    --   `left` is any prefix that is not a number (i.e. -) or USD
    --   `right` is the non-numeric suffix (.123 or USD or 1.23 dollars)
    -- middle capture group `num` => %d* hoovers up all numbers possible...
    --   then first non-number starts the `right` capture group (.-)
    --   `right` is non-greedy and just takes to end of line
    -- `num` contains the integer to comma delimit
    -- reverse it and match on sets of three digits
    --   reversed so you can match left to right repeatedly
    --   then undo the reverse and insert comma delimited between left/right
    local left, num, right = string.match(amount, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
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
