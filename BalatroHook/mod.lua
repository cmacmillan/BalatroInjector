jit.off()

originalupdate = nil
firstUpdate = true

FILE_PATH = "C:\\LuaJitHookLogs\\balatroglobals.txt"

function updatemod(dt)
    if (firstUpdate) then
        love.errhand = my_print
        my_print("First update...\n")

		results = printtablerecursive(_G, 0)
		local globalsFile = io.open(FILE_PATH, "w")
		globalsFile:write(results)
		globalsFile:flush()
		globalsFile:close()

        my_print("====Finished first update!====\n")
        firstUpdate = false
    end

    originalupdate(dt)
end

function pad(str, i)
    local result = str
    for c=0, i, 1 do
        result = "  "..result
    end
    return result
end

function getInfo(n)
    local info = debug.getinfo(n)
    if (info.name == nil) then
        return "nil"
    else
        return info.name
    end
end

function getArgs(fun)
  local args = {}
  local hook = debug.gethook()

  local argHook = function( ... )
    local info = debug.getinfo(3)
    if 'pcall' ~= info.name then return end
    for i = 1, math.huge do
      local name, value = debug.getlocal(2, i)
      if name == nil or '(*temporary)' == name then
        debug.sethook(hook)
        error('')
        return
      end
      table.insert(args,name)
    end
  end

  debug.sethook(argHook, "c")
  pcall(fun)
  
  return args
end

function printtablerecursive(table, depth)
    if ((table == _G or table==G) and depth ~= 0) then
        return pad("..._G...\n", depth+1)
    end
    if (depth > 10) then
        return pad("...truncated...\n",depth+1)
    end
    local result = ""
    for k, v in pairs(table) do
		result = result..pad(" "..k.." ("..type(v)..")".."\n", depth)
		if (type(v) == "function") then
			for i,j in pairs(getArgs(v)) do
				result = result..pad(j.."\n", depth+1)
			end
		end
		if type(v) == "table" then
			result = result..printtablerecursive(v, depth+1)
		end
    end
    return result
end

--- MOD INIT ---

INITWAIT = 0
oghook = debug.gethook()
function trace(event, line)
    local info = debug.getinfo(2)

    if not info then return end
    if not info.name then return end
    if string.len(info.name) <= 1 then return end

    if coroutine.running() ~= nil then return end

    if (INITWAIT == 10000) then
        originalupdate = love.update
        INITWAIT = INITWAIT + 1
        debug.sethook(oghook)
        love.update = updatemod
    end

    INITWAIT = INITWAIT + 1
end

debug.sethook(trace, "c")
