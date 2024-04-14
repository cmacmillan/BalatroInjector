jit.off()

FILE_PATH = "C:\\LuaJitHookLogs\\"
STARTING_TIME = os.clock()
GDUMPED = false

function dumpGlobals()
    local fname = FILE_PATH .. "globals_" .. STARTING_TIME .. ".txt"
    local globalsFile = io.open(fname, "w")
    globalsFile:write(table.show(_G, "_G"))
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
debug.sethook(trace, "c")