jit.off()

function initmod()
    love.errhand = my_print

    my_print(printtablerecursive(_G, 0))

    my_print("====Finished initmod!====\n")
end

function pad(str, i)
    local result = str
    for c=0, i, 1 do
        result = "  "..result
    end
    return result
end

function getArgs(fun)
  local args = {}
  local hook = debug.gethook()

  local argHook = function( ... )
    local info = debug.getinfo(3)
    if 'pcall' ~= info.name then return end

    for i = 1, math.huge do
      local name, value = debug.getlocal(2, i)
      if '(*temporary)' == name then
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
    if (table == _G and depth ~= 0) then
        return pad("..._G...\n", depth+1)
    end
    if (depth > 1) then
        return pad("...truncated...\n",depth+1)
    end
    local result = ""
    for k, v in pairs(table) do
		result = result..pad(" "..k.." ("..type(v)..")".."\n", depth)
		if (type(v) == "function") then
			for i, j in pairs(getArgs(k)) do
				result = result..pad(i.."\n", depth+1)
			end
		end
		if type(v) == "table" then
			result = result..printtablerecursive(v, depth+1)
		end
    end
    return result
end

INITWAIT = 0

function trace(event, line)
    local info = debug.getinfo(2)

    if not info then return end
    if not info.name then return end
    if string.len(info.name) <= 1 then return end

    --- BB find a nicer way to invoke initmod

    if (INITWAIT == 10000) then
        --- disable the hook and init the mod
        debug.sethook(trace, "c", 0)
        initmod()
    end

    INITWAIT = INITWAIT + 1
end

debug.sethook(trace, "c")