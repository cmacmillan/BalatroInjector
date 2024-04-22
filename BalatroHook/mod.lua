jit.off()

originalupdate = nil
firstUpdate = true

FILE_PATH = "C:\\LuaJitHookLogs\\balatroglobals.txt"

function dumpglobals()
	objcache = {}
	results = printtablerecursive(_G, 0, 1, "_G")
	results = results.."\nMade by https://github.com/cmacmillan"
	local globalsFile = io.open(FILE_PATH, "w")
	globalsFile:write(results)
	globalsFile:flush()
	globalsFile:close()
end

function updatemod(dt)
    if (firstUpdate) then
        love.errhand = my_print
        my_print("First update...\n")

        ---dumpglobals()
        ---_G.G.FUNCS.show_credits()
        ---_G.G.FUNCS.show_credits()

        my_print("====Finished first update!====\n")
        firstUpdate = false
    end

    originalupdate(dt)
end

function pad(str, suffix, path, i, linenum)
    local result = str
    if (false) then
		linestr = tostring(linenum-1)
		for c=string.len(linestr), i+6, 1 do
			result = "  "..result
		end    
		result = linestr..result
    else
		for c=0, i, 1 do
			result = "  "..result
		end    
    end

	for c=string.len(result), 50, 1 do
		result = result.." "
	end
	result = result..suffix


    if (true) then -- set to false to not dump paths
		for c=string.len(result), 130, 1 do
			result = result.." "
		end
		result = result..path
    end

    result = result.."\n"
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

function printtablerecursive(table, depth, linenum, path)
    if (table == objcache) then
        return "", linenum
    end
    if (depth > 10) then
        return pad("...truncated due to depth", "", path, depth + 1, linenum), linenum+1
    end
    objcache[table] = linenum
    local result = ""
    for k, v in pairs(table) do
        linenum = linenum + 1
		if (type(v) == "function") then
            name = k.."("
            isFirst = true 
			for i,j in pairs(getArgs(v)) do
                if (not isFirst) then
                    name= name..", "
                end
                isFirst = false;
				name = name..j
			end
            name = name..") (function)"
            result = result..pad(name, "", path.."."..k, depth, linenum)
		elseif type(v) == "table" then
            if (objcache[v] ~= nil) then
                result = result..pad(k.." (table) {line "..(objcache[v]-1).."}", "", path.."."..k, depth, linenum)
            else
                result = result..pad(k.." (table)", "", path.."."..k, depth, linenum)
                concat, linenum = printtablerecursive(v, depth+1, linenum, path.."."..k)
			    result = result..concat
            end
        else
            suffix = ""
            if (type(v) == "boolean") then
                suffix = "= "..tostring(v) 
            elseif (type(v) == "number") then
                suffix = "= "..tostring(v) 
            elseif (type(v) == "string") then
                suffix = "= "..v:gsub("\n", "\\n")
            end
            result = result..pad(k.." ("..type(v)..") ", suffix, path.."."..k, depth, linenum)
		end
    end
    return result, linenum
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
