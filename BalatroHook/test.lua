jit.off()

FILE_PATH = "C:\\LuaJitHookLogs\\"
STARTING_TIME = os.clock()
--gimmecache = {}
GDUMPED = false
---blah = true
--gimmecache["a"] = "b"
---_G.oof = {}

--- Remember debug hook is commented out at the bottom

---blah blah bad!

function pad(str, i)
    local result = str
    for c=0, i, 1 do
        result = "  "..result
    end
    return result
end

function gimme(table, depth)
    --if (gimmecache[table] ~= nil) then
        --return "\n"
    --end

    --gimmecache.insert(table, true)

    --if (table == _G and depth ~= 0) then
        --return pad("..._G...\n", depth+1)
    --end
    --if (depth > 999) then
    if (depth > 1) then
        return pad("...truncated...\n",depth+1)
    end
    local result = ""
    for k, v in pairs(table) do
        if (v ~= gimmecache) then
			result = result..pad(" "..k.." ("..type(v)..")".."\n", depth)
			if type(v) == "table" then
				result = result..gimme(v, depth+1)
			end
        end
    end
    return result
end

function dumpGlobals()
    local fname = FILE_PATH .. "globals_" .. STARTING_TIME .. ".txt"

    local globalsFile = io.open(fname, "w")
    globalsFile:write(gimme(_G, 0))
    globalsFile:flush()
    globalsFile:close()
end

function trace(event, line)
    local info = debug.getinfo(2)

    if not info then return end
    if not info.name then return end
    if string.len(info.name) <= 1 then return end

    if (not GDUMPED) then
        dumpGlobals()
        GDUMPED = true
    end
    
    local fname = FILE_PATH .. "trace_" .. STARTING_TIME .. ".txt"
    local traceFile = io.open(fname, "a")
    traceFile:write(info.name .. "()\n")

    local a = 1
    while true do
        local name, value = debug.getlocal(2, a)
        if not name then break end
        if not value then break end
        traceFile:write(tostring(name) .. ": " .. tostring(value) .. "\n")
        a = a + 1
    end

    traceFile:flush()
    traceFile:close()
end

---debug.sethook(trace, "c")