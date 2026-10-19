-- Here be some utility functions

local ffi = require("ffi")
local utf8 = require("utf8")

-- Windows API helpers
ffi.cdef([[
    typedef unsigned short wchar_t;
    typedef void* HWND;
    typedef void* HANDLE;
    typedef void* HGLOBAL;
    typedef unsigned int UINT;
    typedef unsigned short WORD;
    typedef unsigned long DWORD;
    typedef unsigned __int64 SIZE_T;
    typedef long LONG;
    typedef int BOOL;
    typedef struct {
        DWORD biSize;
        LONG biWidth;
        LONG biHeight;
        WORD biPlanes;
        WORD biBitCount;
        DWORD biCompression;
        DWORD biSizeImage;
        LONG biXPelsPerMeter;
        LONG biYPelsPerMeter;
        DWORD biClrUsed;
        DWORD biClrImportant;
    } BITMAPINFOHEADER;
    typedef struct {
        DWORD cb;
        DWORD PageFaultCount;
        SIZE_T PeakWorkingSetSize;
        SIZE_T WorkingSetSize;
        SIZE_T QuotaPeakPagedPoolUsage;
        SIZE_T QuotaPagedPoolUsage;
        SIZE_T QuotaPeakNonPagedPoolUsage;
        SIZE_T QuotaNonPagedPoolUsage;
        SIZE_T PagefileUsage;
        SIZE_T PeakPagefileUsage;
    } PROCESS_MEMORY_COUNTERS;
    HANDLE GetCurrentProcess(void);
    BOOL K32GetProcessMemoryInfo(
        HANDLE hProcess,
        PROCESS_MEMORY_COUNTERS *ppsmemCounters,
        DWORD cb
    );
    int MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags,
        const char* lpMultiByteStr, int cbMultiByte, wchar_t* lpWideCharStr, int cchWideChar);
    int WideCharToMultiByte(unsigned int CodePage, unsigned long dwFlags,
        const wchar_t* lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte,
        const char* lpDefaultChar, int* lpUsedDefaultChar);
]])


--  Substring function which gets a substring of `str` from character indices `start` to `stop`
function utf8.sub(str, start, stop)
    local str_length = utf8.len(str)
    start = math.min(start or 1, str_length)
    start = utf8.offset(str, start)
    stop = stop or str_length
    stop = math.min(stop, str_length)
    if stop == -1 then
        stop = str_length
    else
        stop = utf8.offset(str, stop + 1) - 1
    end
    return string.sub(str, start, stop)
end


-- Convert string between code pages (used for readable console output on Windows)
--- @param str any the string to convert
--- @param from_cp integer source code page (e.g. 1251 for Windows-1251)
--- @param to_cp integer target code page (e.g. 65001 for UTF-8)
--- @return string converted string, or original string if conversion fails
function codepage2codepage(str, from_cp, to_cp)
    str = tostring(str) -- ensure str is a string
    if not str then return str end
    local len = #str
    if len == 0 then return str end
    if ffi == nil then return str end

    local wchars = ffi.C.MultiByteToWideChar(from_cp, 0, str, len, nil, 0)
    if wchars == 0 then return str end
    local wbuf = ffi.new("wchar_t[?]", wchars + 1)
    ffi.C.MultiByteToWideChar(from_cp, 0, str, len, wbuf, wchars + 1)

    local newlen = ffi.C.WideCharToMultiByte(to_cp, 0, wbuf, wchars, nil, 0, nil, nil)
    if newlen == 0 then return str end
    local ubuf = ffi.new("char[?]", newlen + 1)
    ffi.C.WideCharToMultiByte(to_cp, 0, wbuf, wchars, ubuf, newlen + 1, nil, nil)
    return ffi.string(ubuf, newlen)
end

--- Converts a UTF-8 string to the UTF-16 buffer
--- @param text string # UTF-8 encoded string to convert.
--- @return userdata # UTF-16 wide-character buffer
function utf8_to_wide(text)
    local required_chars = ffi.C.MultiByteToWideChar(65001, 0, text, -1, nil, 0)
    if required_chars == 0 then
        error("Failed to convert UTF-8 path to UTF-16", 2)
    end

    local wide_chars = ffi.new("wchar_t[?]", required_chars)
    local written_chars = ffi.C.MultiByteToWideChar(65001, 0, text, -1, wide_chars, required_chars)
    if written_chars == 0 then
        error("Failed to write UTF-16 string", 2)
    end

    return wide_chars
end


-- clamps value v between min and max
--- @param v number # value to clamp
--- @param min number # minimum value
--- @param max number # maximum value
--- @return number # clamped value
function math.clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end


-- rounds number to specified decimal places (default 0)
function math.round(number, decimal_places)
    local factor = 1
    if decimal_places ~= nil then
        factor = 10^decimal_places
    end
    return math.floor(number * factor + 0.5) / factor
end


-- checks if a number is an integer
function math.is_integer(number)
    return number % 1 == 0
end


--- Bitwise XOR
function math.bit_xor(a, b)
    local p, c = 1, 0

    while a > 0 and b > 0 do
        local ra, rb = a % 2, b % 2
        if ra ~= rb then c = c + p end
        a = (a - ra) / 2
        b = (b - rb) / 2
        p = p * 2
    end
    if a < b then a = b end
    while a > 0 do
        local ra = a % 2
        if ra > 0 then c = c + p end
        a = (a - ra) / 2
        p = p * 2
    end
    return c
end


-- Returns a random value from a table
---@param t table the table to get a random value from
---@return any element - random value from the table, or nil if the table is empty
function math.random_table(t)
    if #t > 0 then
        return t[math.random(#t)]
    else
        return nil
    end
end


-- Linear interpolation between two values
function math.lerp(from, to, smoothness)
    return from + (to - from) * smoothness
end


-- Exponential interpolation between two values
function math.elerp(from, to, smoothness)
    return from + (to - from) * (1 - math.exp(-smoothness))
end


-- checks if obj is an instance of a class (has a 'class' field)
function is_instance(obj)
    return type(obj) == "table" and obj.class ~= nil
end


--- Decreases a timer value without allowing it to become negative.
--- @param value number
--- @param dt number
--- @return number
function decrease_timer(value, dt)
    return math.max(0, value - dt)
end


-- forced garbage collection
function collect_garbage()
    local mem_count = math.floor(collectgarbage("count"))
    collectgarbage("collect")
    love.timer.sleep(0.02) -- small delay to allow GC to complete
    love.event.pump() -- process events to prevent "not responding" state during reset
    collectgarbage("collect")
    if DEBUG then
        print_log("Memory used before garbage collection: " .. mem_count .. " KB. After: " ..
                math.floor(collectgarbage("count")) .. " KB")
    end
end


--- Returns the current process memory usage in megabytes.
--- @return number|nil working_set # the working set size in MB, or nil if failed
--- @return number|nil commit_size # the commit size in MB, or nil if failed
--- @return number|nil peak_working_set # the peak working set size in MB, or nil if failed
function get_memory_usage()
    local pmc = ffi.new("PROCESS_MEMORY_COUNTERS[1]")
    pmc[0].cb = ffi.sizeof("PROCESS_MEMORY_COUNTERS")

    local success = ffi.C.K32GetProcessMemoryInfo(ffi.C.GetCurrentProcess(), pmc,
            ffi.sizeof("PROCESS_MEMORY_COUNTERS"))
    if success ~= 0 then
        local working_set = tonumber(pmc[0].WorkingSetSize) / 1024 / 1024
        local commit_size = tonumber(pmc[0].PagefileUsage) / 1024 / 1024
        local peak_working_set = tonumber(pmc[0].PeakWorkingSetSize) / 1024 / 1024
        return working_set, commit_size, peak_working_set
    end

    return nil, nil, nil
end


local print_table_was_run_times = 0
-- prints contents of a table (for debugging)
--- @param t table table to print
--- @param run_times integer|nil # limits number of times the function can be
-- run (to avoid very big output or infinite loops with recursive tables)
function print_table(t, run_times)
    if run_times ~= nil then
        if print_table_was_run_times >= run_times then
            return
        end
        print_table_was_run_times = print_table_was_run_times + 1
    end

    local print_r_cache = {}

    local function sub_print_r(txt, indent)
        if print_r_cache[tostring(txt)] then
            print_log(indent .. "*" .. tostring(txt))
        else
            print_r_cache[tostring(txt)]=true
            if type(txt) == "table" then
                for pos, val in pairs(txt) do
                    if type(val) == "table" then
                        print_log(indent .. "[" .. pos .. "] => " .. tostring(txt) .. " {")
                        sub_print_r(val, indent .. string.rep(" ", string.len(pos) + 8))
                        print_log(indent .. string.rep(" ", string.len(pos) + 6) .. "}")
                    elseif type(val) == "string" then
                        print_log(indent .. "[" .. pos .. '] => "' .. val .. '"')
                    else
                        print_log(indent .. "[" .. pos .. "] => " .. tostring(val))
                    end
                end
            else
                print_log(indent .. tostring(txt))
            end
        end
    end
    if type(t) == "table" then
        print_log(tostring(t) .. " {")
        sub_print_r(t, " ")
        print_log("}")
    else
        sub_print_r(t,"  ")
    end
    print_log("")
end


function print_log(text)
    text = tostring(text)
    print(text)
end


-- Format large numbers with "к" suffix (thousands)
---- Numbers >= 100000 are rounded to whole number with "k"
---- Numbers 1000-99999 are formatted with 1 decimal place with "k"
---- Numbers < 1000 are displayed as-is
function format_number_with_k(num)
    if num >= 100000 then
        return math.round(num / 1000, 0) .. "k"
    elseif num >= 1000 then
        return math.round(num / 1000, 1) .. "k"
    else
        return tostring(math.floor(num))
    end
end


--- Creates a deep copy of a table (recursive copy of all nested tables).
--- Primitive values are returned as-is.
--- @param original table|any table to copy or value to return
--- @return table|any deep_copy copy of the table or the original value
function deep_copy(original)
    if type(original) == 'table' then
        local copy = {}
        for key, value in pairs(original) do
            copy[deep_copy(key)] = deep_copy(value)
        end
        return copy
    else
        return original
    end
end


function set_camera_zoom(new_scale, anchor_x, anchor_y)
    local camera_x, camera_y = CameraMgr.getCoords()
    local world_x_before, world_y_before = CameraMgr.toWorldCoords(anchor_x, anchor_y)

    CameraMgr.setScale(new_scale)

    local world_x_after, world_y_after = CameraMgr.toWorldCoords(anchor_x, anchor_y)
    CameraMgr.setCoords(
        camera_x + (world_x_before - world_x_after),
        camera_y + (world_y_before - world_y_after)
    )
end
