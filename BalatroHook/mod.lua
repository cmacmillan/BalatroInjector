jit.off()

originalupdate = nil
originalkeypressed = nil
originalkeyrelease = nil
originaldraw = nil
originaltextinput = nil
firstUpdate = true

currentConsoleHeight = 0
maxConsoleHeight = 200
fIsConsoleOpen = false
consoleLeftPadding = 20
consoleBottomPadding = 5
cursorWidth = 2

dTUntilNextCursorFlicker = 0
dTBetweenCursorFlickers = .4
fIsCursorVisible = true

cursorIndex = 1
currentInputText = ""

FILE_PATH = "C:\\LuaJitHookLogs\\balatroglobals.txt"

function dumpglobals()
	local results = printtable(_G, "_G", false)
	results = results.."\nMade by https://github.com/cmacmillan"
	local globalsFile = io.open(FILE_PATH, "w")
	globalsFile:write(results)
	globalsFile:flush()
	globalsFile:close()
end

function unlockallachievements()
	for i, j in pairs (_G.G.localization.misc.achievement_names) do 
		_G.unlock_achievement(i)
	end
end

function mykeypressed(key)
    if key == "f5" then
        fIsConsoleOpen = not fIsConsoleOpen 
    end
    if (fIsConsoleOpen) then
        if key == "left" then
            cursorIndex = math.max(1, cursorIndex - 1)
			dTUntilNextCursorFlicker = dTBetweenCursorFlickers
			fIsCursorVisible = true
        end
        if key == "right" then
            cursorIndex = math.min(string.len(currentInputText) + 1, cursorIndex + 1)
            dTUntilNextCursorFlicker = dTBetweenCursorFlickers
			fIsCursorVisible = true
        end
        if key == "return" then
            if (currentInputText == "help") then
                --- BB explain how to use return to read values, and show how to use add_joker
                love.system.openURL("https://raw.githubusercontent.com/cmacmillan/BalatroInjector/master/balatroglobals.txt")
			    currentInputText = ""
                cursorIndex = 1
            else
				local result, err = loadstring(currentInputText)
				if (result == nil) then
					my_print("Error running command!: "..err.."\n") --- TODO don't put this here
					currentInputText = ""
				else
                    local retr = result()
                    if (retr ~= nil) then
					    currentInputText = tostring(retr) --- TODO don't put this here
                    else
					    currentInputText = ""
                    end
				end
				cursorIndex = 1
            end
        end
        if key == "backspace" then
            cursorIndex = math.max(1, cursorIndex - 1)
            currentInputText = string.sub(currentInputText,1,cursorIndex-1) .. string.sub(currentInputText,cursorIndex+1)
            dTUntilNextCursorFlicker = dTBetweenCursorFlickers
			fIsCursorVisible = true
        end
    end
   ---_G.G.FUNCS.reroll_shop()
   ---if key == "f4" then
        ---my_print(printtable(_G.find_joker("Baron",true), "", false))
        ---my_print(printtable(_G.find_joker("j_baron",true), "", false))
        ---my_print(printtable(_G.find_joker("asdf",true), "", false))
        ---_G.add_joker("j_baron")
        ---_G.add_joker("j_mime")
   ---end
   if (not fIsConsoleOpen) then
        originalkeypressed(key)
    end
end

function mykeyreleased( key )
    if (not fIsConsoleOpen) then
        originalkeyrelease(key)
    end
end

function mytextinput(text)
    if (fIsConsoleOpen) then
        currentInputText = string.sub(currentInputText,1,cursorIndex-1) .. text .. string.sub(currentInputText,cursorIndex)
        cursorIndex = cursorIndex + 1
		dTUntilNextCursorFlicker = dTBetweenCursorFlickers
		fIsCursorVisible = true
    else
        if (originaltextinput ~= nil) then
            originaltextinput(text)
        end
    end
end

function mydraw()
    originaldraw()

	love.graphics.setColor (0,0,0, .4)
    local screenWidth = love.graphics.getWidth();
    local font = love.graphics.getFont()
    textHeight = font.getHeight(font)
    love.graphics.polygon("fill", 0,0, screenWidth,0, screenWidth,currentConsoleHeight, 0,currentConsoleHeight)

    if (dTUntilNextCursorFlicker < 0) then
        dTUntilNextCursorFlicker = dTUntilNextCursorFlicker + dTBetweenCursorFlickers 
        fIsCursorVisible = not fIsCursorVisible
    end

	love.graphics.setColor (1,1,1)
    if (fIsCursorVisible) then
		cursorTopLeftX = consoleLeftPadding + font:getWidth(string.sub(currentInputText,1,cursorIndex-1))
		cursorTopLeftY = currentConsoleHeight - textHeight - consoleBottomPadding
		love.graphics.polygon("fill", cursorTopLeftX, cursorTopLeftY, cursorTopLeftX+cursorWidth,cursorTopLeftY, cursorTopLeftX+cursorWidth,cursorTopLeftY+textHeight, cursorTopLeftX,cursorTopLeftY+textHeight)
    end

    love.graphics.printf(currentInputText, consoleLeftPadding, currentConsoleHeight - textHeight - consoleBottomPadding, love.graphics.getWidth())
end

function movetowards(current, target, amount)
    if (current < target) then
        return math.min(current + amount, target)
    elseif (current > target) then
        return math.max(current - amount, target) 
    else
        return current
    end
end

function updatemod(dt)
    if (firstUpdate) then
        my_print("First update...\n")

        love.errhand = my_print

		originalkeypressed = love.keypressed
		originalkeyrelease = love.keyreleased
        love.keypressed = mykeypressed
        love.keyreleased = mykeyrelease

        originaldraw = love.draw
        love.draw = mydraw

        originaltextinput = love.textinput
        love.textinput = mytextinput

        ---dumpglobals()
        
        my_print("====Finished first update!====\n")
        firstUpdate = false
    end

    local targetConsoleHeight = 0
    if (fIsConsoleOpen) then
        targetConsoleHeight = maxConsoleHeight
    end

    currentConsoleHeight = movetowards(currentConsoleHeight,targetConsoleHeight,dt*maxConsoleHeight*10)

    dTUntilNextCursorFlicker = dTUntilNextCursorFlicker - dt

    --- Pause while the console is open

    ---if (not fIsConsoleOpen) then
        originalupdate(dt)
    ---end
end

function pad(str, suffix, path, i, linenum, showpath)
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


    if (showpath) then
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

function printtable(table, path, showpath)
	objcache = {}
	local results, linenum = printtablerecursive(table, 0, 1, path, showpath)
    return results
end

function printtablerecursive(table, depth, linenum, path, showpath)
    if (table == objcache) then
        return "", linenum
    end
	if next(table) == nil then
        --- BB this isn't super nice...
        return pad("Empty table", "", depth + 1, linenum, showpath), linenum+1
	end
    if (depth > 10) then
        return pad("...truncated due to depth", "", path, depth + 1, linenum, showpath), linenum+1
    end
    objcache[table] = linenum
    local result = ""
    for k, v in pairs(table) do
        linenum = linenum + 1
		if (type(v) == "function") then
            local name = k.."("
            local isFirst = true 
			for i,j in pairs(getArgs(v)) do
                if (not isFirst) then
                    name= name..", "
                end
                isFirst = false;
				name = name..j
			end
            name = name..") (function)"
            result = result..pad(name, "", path.."."..k, depth, linenum, showpath)
		elseif type(v) == "table" then
            if (objcache[v] ~= nil) then
                result = result..pad(k.." (table) {line "..(objcache[v]-1).."}", "", path.."."..k, depth, linenum, showpath)
            else
                result = result..pad(k.." (table)", "", path.."."..k, depth, linenum, showpath)
                concat, linenum = printtablerecursive(v, depth+1, linenum, path.."."..k, showpath)
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
            result = result..pad(k.." ("..type(v)..") ", suffix, path.."."..k, depth, linenum, showpath)
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
