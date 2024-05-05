jit.off()

originalupdate = nil
originalkeypressed = nil
originalkeyrelease = nil
originaldraw = nil
originaltextinput = nil
firstUpdate = true

currentConsoleHeight = 0
nonFullscreenConsoleHeight = 250
fIsConsoleOpen = true
fPreferConsoleFullscreen = false

consoleLeftPadding = 60
consoleBottomPadding = 5
cursorWidth = 2

dTUntilNextCursorFlicker = 0
dTBetweenCursorFlickers = .4
fIsCursorVisible = true

mpKeyDownToDTPressed = {}
mpKeyDownToCRepeats = {}
dTUntilFirstKeyRepeat = .4
dTBetweenKeyRepeats = .025

iCommandHistorySelected = 0
cCommandsInHistory = 0
commandHistory = {}

cOutputHistory = 0
outputHistory = {}
outputHistoryLineCount = {}

cursorIndex = 1
currentInputText = ""

selectCursorStartIndex = nil

FILE_PATH = "C:\\LuaJitHookLogs\\balatroglobals.txt"

strHistoryFilePath = "balatroconsolehistory.txt"

function dumpglobals()
	local results = stringfromtable(_G, "_G", true, true, 5)
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

function leftpressed()
	if (mpKeyDownToDTPressed["lshift"] or mpKeyDownToDTPressed["rshift"]) then
        if (selectCursorStartIndex == nil) then
            selectCursorStartIndex = cursorIndex 
        end
    else
        selectCursorStartIndex = nil
    end
	cursorIndex = math.max(1, cursorIndex - 1)
	dTUntilNextCursorFlicker = dTBetweenCursorFlickers
	fIsCursorVisible = true
end

function rightpressed()
	if (mpKeyDownToDTPressed["lshift"] or mpKeyDownToDTPressed["rshift"]) then
        if (selectCursorStartIndex == nil) then
            selectCursorStartIndex = cursorIndex 
        end
    else
        selectCursorStartIndex = nil
    end
	cursorIndex = math.min(string.len(currentInputText) + 1, cursorIndex + 1)
	dTUntilNextCursorFlicker = dTBetweenCursorFlickers
	fIsCursorVisible = true
end

function uppressed()
    iCommandHistorySelected = math.max(0, iCommandHistorySelected - 1)
    if (iCommandHistorySelected == cCommandsInHistory) then
        currentInputText = ""
        cursorIndex = 1
    else
        currentInputText = commandHistory[iCommandHistorySelected]
        cursorIndex = string.len(currentInputText) + 1
    end
end

function downpressed()
    iCommandHistorySelected = math.min(cCommandsInHistory, iCommandHistorySelected + 1)
    if (iCommandHistorySelected == cCommandsInHistory) then
        currentInputText = ""
        cursorIndex = 1
    else
        currentInputText = commandHistory[iCommandHistorySelected]
        cursorIndex = string.len(currentInputText) + 1
    end
end

function noop()
end

function copy()
	if (mpKeyDownToDTPressed["lctrl"] or mpKeyDownToDTPressed["rctrl"]) then
        if (selectCursorStartIndex == cursorIndex) then
            return
        end

		local selectLeftIndex = math.min(cursorIndex, selectCursorStartIndex)
		local selectRightIndex = math.max(cursorIndex, selectCursorStartIndex)
		love.system.setClipboardText(string.sub(currentInputText,selectLeftIndex,selectRightIndex-1))
		selectCursorStartIndex = nil
    end
end

function cut()
	if (mpKeyDownToDTPressed["lctrl"] or mpKeyDownToDTPressed["rctrl"]) then
        if (selectCursorStartIndex == nil or selectCursorStartIndex == cursorIndex) then
            return
        end

 		local selectLeftIndex = math.min(cursorIndex, selectCursorStartIndex)
		local selectRightIndex = math.max(cursorIndex, selectCursorStartIndex)
		love.system.setClipboardText(string.sub(currentInputText,selectLeftIndex,selectRightIndex-1))
		currentInputText = string.sub(currentInputText,1,selectLeftIndex-1) .. string.sub(currentInputText,selectRightIndex)
	    cursorIndex = selectLeftIndex
		selectCursorStartIndex = nil       
    end
end

function selectall()
	if (mpKeyDownToDTPressed["lctrl"] or mpKeyDownToDTPressed["rctrl"]) then
        cursorIndex = 1
        selectCursorStartIndex = string.len(currentInputText) + 1
    end
end

function paste()
	if (mpKeyDownToDTPressed["lctrl"] or mpKeyDownToDTPressed["rctrl"]) then
		local pastetext = string.gsub(love.system.getClipboardText(),"\n"," ")
        if (selectCursorStartIndex ~= nil) then
			local selectLeftIndex = math.min(cursorIndex, selectCursorStartIndex)
			local selectRightIndex = math.max(cursorIndex, selectCursorStartIndex)
			currentInputText = string.sub(currentInputText,1,selectLeftIndex-1) .. pastetext .. string.sub(currentInputText,selectRightIndex)
			cursorIndex = selectLeftIndex + string.len(pastetext)
			selectCursorStartIndex = nil
        else
			currentInputText = string.sub(currentInputText,1,cursorIndex-1) .. pastetext .. string.sub(currentInputText,cursorIndex)
			cursorIndex = cursorIndex + string.len(pastetext)
        end

		dTUntilNextCursorFlicker = dTBetweenCursorFlickers
		fIsCursorVisible = true
	end
end

function split(str, strDelim)
   if strDelim == nil then
      return nil
   end
   local t={}
   for str in string.gmatch(str, "([^"..strDelim.."]+)") do
      table.insert(t, str)
   end
   return t
end

function loadconsolehistory()
    local info = love.filesystem.getInfo(strHistoryFilePath)
    if (info == nil) then
        local file = love.filesystem.newFile(strHistoryFilePath)
		file:open("w")
		file:close()
    else
        local strContents = love.filesystem.read(strHistoryFilePath)
        local tSplit = split(strContents,"\n")
        for i,j in pairs(tSplit) do
            addCommandToHistory(j)
        end
    end
end

function printconsole(text)
    outputHistory[cOutputHistory] = text

    local cNewlines = 0
    for i in string.gmatch(text, "\n") do 
        cNewlines = cNewlines + 1
    end
    outputHistoryLineCount[cOutputHistory] = cNewlines

    cOutputHistory = cOutputHistory + 1
end

function printhelp()
    printconsole("\tWelcome to the balatro console!")
    printconsole("\tPress f5 to open/close the console. Press f6 to open the console in fullscreen mode.")
    printconsole("\tRun 'globals' to open a webpage which documents global variables. Run 'help' to print this help text.")
    printconsole("\tTry running 'add_joker(\"j_baron\")' to spawn in a joker.")
    printconsole("\tOr try running 'G.FUNCS.reroll_shop()' when in a shop")
    printconsole("\tThis console supports any lua commands, including loops, functions, etc.")
end

function addCommandToHistory(strCommand)
    commandHistory[cCommandsInHistory] = strCommand 
    cCommandsInHistory = cCommandsInHistory + 1
    iCommandHistorySelected = cCommandsInHistory
end

function returnpressed()
    printconsole(currentInputText)

    addCommandToHistory(currentInputText)
    --- Write into history file (assume it already exists since we created it when loading the history)
    love.filesystem.append(strHistoryFilePath, currentInputText.."\n")
    

	if (currentInputText == "help") then
        printhelp()
	elseif (currentInputText == "globals") then
		love.system.openURL("https://raw.githubusercontent.com/cmacmillan/BalatroInjector/master/balatroglobals.txt")
	elseif (currentInputText == "clear" or currentInputText == "cls") then
        for i,j in pairs(outputHistory) do
		    outputHistory[i] = nil
            outputHistoryLineCount[i] = nil
        end
		cOutputHistory = 0
	else
		local loadResult, loadErr = loadstring("return "..currentInputText)
		if (loadResult == nil) then
		    loadResult, loadErr = loadstring(currentInputText)
            if (loadResult == nil) then
				printconsole("\tError: "..loadErr)
				currentInputText = ""
            end
		end

        if (loadResult) then
			local callResult = {pcall(loadResult)}
			if (callResult[1] == true) then
				for i,j in pairs(callResult) do
					if i > 1 then
                        if (type(j) == "table") then
						    printconsole("\t"..stringfromtable(j))
                        else
						    printconsole("\t"..tostring(j))
                        end
					end
				end
			else
				printconsole("\tError: "..callResult[2])
			end
        end
	end
    cursorIndex = 1
    currentInputText = ""
end

function backspacepressed()
	if (selectCursorStartIndex ~= nil) then
		local selectLeftIndex = math.min(cursorIndex, selectCursorStartIndex)
		local selectRightIndex = math.max(cursorIndex, selectCursorStartIndex)
		currentInputText = string.sub(currentInputText,1,selectLeftIndex-1) .. string.sub(currentInputText,selectRightIndex)
		selectCursorStartIndex = nil
		cursorIndex = selectLeftIndex
	else
        if (cursorIndex > 1) then
			cursorIndex = math.max(1, cursorIndex - 1)
			currentInputText = string.sub(currentInputText,1,cursorIndex-1) .. string.sub(currentInputText,cursorIndex+1)
        end
	end
	dTUntilNextCursorFlicker = dTBetweenCursorFlickers
	fIsCursorVisible = true
end

function deletepressed()
	if (selectCursorStartIndex ~= nil) then
		local selectLeftIndex = math.min(cursorIndex, selectCursorStartIndex)
		local selectRightIndex = math.max(cursorIndex, selectCursorStartIndex)
		currentInputText = string.sub(currentInputText,1,selectLeftIndex-1) .. string.sub(currentInputText,selectRightIndex)
		selectCursorStartIndex = nil
		cursorIndex = selectLeftIndex
	else
		currentInputText = string.sub(currentInputText,1,cursorIndex-1) .. string.sub(currentInputText,cursorIndex+1)
	end
	dTUntilNextCursorFlicker = dTBetweenCursorFlickers
	fIsCursorVisible = true
end

mpKeyNameToFunc = 
{
    ["left"]        = leftpressed,
    ["right"]       = rightpressed,
    ["up"]          = uppressed,
    ["down"]        = downpressed,
    ["return"]      = returnpressed,
    ["backspace"]   = backspacepressed,
    ["delete"]      = deletepressed,
    ["lctrl"]       = noop,
    ["rctrl"]       = noop,
    ["lshift"]      = noop,
    ["rshift"]      = noop,
    ["v"]           = paste,
    ["c"]           = copy,
    ["x"]           = cut,
    ["a"]           = selectall
}

function mykeypressed(key)
    if key == "f5" then
        if (fPreferConsoleFullscreen) then
            fPreferConsoleFullscreen = false
            fIsConsoleOpen = true
        else
            fIsConsoleOpen = not fIsConsoleOpen 
        end
    elseif key == "f6" then
        if (not fPreferConsoleFullscreen) then
            fPreferConsoleFullscreen = true
            fIsConsoleOpen = true
        else
            fIsConsoleOpen = not fIsConsoleOpen 
        end
    end
    if (fIsConsoleOpen) then
        local func = mpKeyNameToFunc[key]
        if (func ~= nil) then
            mpKeyDownToDTPressed[key] = 0
            mpKeyDownToCRepeats[key] = 1
            func()
        end
    end
    if (not fIsConsoleOpen) then
        originalkeypressed(key)
    end
end

function mykeyreleased( key )
    if (fIsConsoleOpen) then
        mpKeyDownToDTPressed[key] = nil
        mpKeyDownToCRepeats[key] = nil
    end
    if (not fIsConsoleOpen) then
        originalkeyrelease(key)
    end
end

function mytextinput(text)
    if (fIsConsoleOpen) then
        if (selectCursorStartIndex ~= nil) then
			local selectLeftIndex = math.min(cursorIndex, selectCursorStartIndex)
			local selectRightIndex = math.max(cursorIndex, selectCursorStartIndex)
		    currentInputText = string.sub(currentInputText,1,selectLeftIndex-1) .. text .. string.sub(currentInputText,selectRightIndex)
            selectCursorStartIndex = nil
            cursorIndex = selectLeftIndex
        else
		    currentInputText = string.sub(currentInputText,1,cursorIndex-1) .. text .. string.sub(currentInputText,cursorIndex)
        end
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

	love.graphics.setColor (0,0,0, .5)
    local screenWidth = love.graphics.getWidth();
    local font = love.graphics.getFont()
    textHeight = font.getHeight(font)
    love.graphics.polygon("fill", 0,0, screenWidth,0, screenWidth,currentConsoleHeight, 0,currentConsoleHeight)

    if (dTUntilNextCursorFlicker < 0) then
        dTUntilNextCursorFlicker = dTUntilNextCursorFlicker + dTBetweenCursorFlickers 
        fIsCursorVisible = not fIsCursorVisible
    end

    textTopY = currentConsoleHeight - textHeight - consoleBottomPadding
    textBottomY = textTopY + textHeight
	cursorTopLeftX = consoleLeftPadding + font:getWidth(string.sub(currentInputText,1,cursorIndex-1))

    if (selectCursorStartIndex) then
        local selectLeftX = nil
        local selectRightX = nil
	    local selectX = consoleLeftPadding + font:getWidth(string.sub(currentInputText,1,selectCursorStartIndex-1))
        if (cursorIndex < selectCursorStartIndex) then
			selectLeftX = cursorTopLeftX
			selectRightX = selectX
        else
			selectLeftX = selectX
			selectRightX = cursorTopLeftX
        end
	    love.graphics.setColor (.4,.4,1, 1)
		love.graphics.polygon("fill", selectLeftX,textTopY, selectRightX,textTopY, selectRightX,textBottomY, selectLeftX,textBottomY)
    end

	love.graphics.setColor (1,1,1)
    if (fIsCursorVisible) then
		love.graphics.polygon("fill", cursorTopLeftX, textTopY, cursorTopLeftX+cursorWidth,textTopY, cursorTopLeftX+cursorWidth,textBottomY, cursorTopLeftX,textBottomY)
    end

    local inputTextYPosition = currentConsoleHeight - textHeight - consoleBottomPadding

    love.graphics.printf(currentInputText, consoleLeftPadding, inputTextYPosition, love.graphics.getWidth())
	love.graphics.setColor (.9,.9,.9)
    local textHeightPadded = textHeight + 2
    local yOffset = inputTextYPosition
    for i=cOutputHistory-1, 0, -1 do
        yOffset = yOffset + -textHeightPadded * (1+outputHistoryLineCount[i])
        love.graphics.printf(outputHistory[i], consoleLeftPadding, yOffset, love.graphics.getWidth())
    end
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
        my_print("Mod loaded!\n")

        love.errhand = my_print

        ---dumpglobals()

		originalkeypressed = love.keypressed
		originalkeyrelease = love.keyreleased
        love.keypressed = mykeypressed
        love.keyreleased = mykeyreleased

        originaldraw = love.draw
        love.draw = mydraw

        originaltextinput = love.textinput
        love.textinput = mytextinput

        loadconsolehistory()
        printhelp()
        
        firstUpdate = false
    end

    local targetConsoleHeight = 0
    if (fIsConsoleOpen) then
        if (fPreferConsoleFullscreen) then
            targetConsoleHeight = love.graphics.getHeight();
        else
            targetConsoleHeight = nonFullscreenConsoleHeight 
        end
    end

    currentConsoleHeight = movetowards(currentConsoleHeight,targetConsoleHeight,dt*love.graphics.getHeight()*3)

    dTUntilNextCursorFlicker = dTUntilNextCursorFlicker - dt
    for i, j in pairs(mpKeyDownToDTPressed) do
        mpKeyDownToDTPressed[i] = j + dt
        local dTSinceFirstRepeat = mpKeyDownToDTPressed[i] - dTUntilFirstKeyRepeat
        if (dTSinceFirstRepeat > 0) then
            local cRepeats = math.floor(dTSinceFirstRepeat / dTBetweenKeyRepeats)
            for c = mpKeyDownToCRepeats[i], cRepeats do
                mpKeyNameToFunc[i]()
            end
            mpKeyDownToCRepeats[i] = cRepeats + 1
        end
    end

    originalupdate(dt)
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

function printtable(table)
    printconsole(stringfromtable(table))
end

function stringfromtable(table, path, showpath, showline, maxdepth)
    if (showpath == nil) then
        showpath = false
    end
    if (path == nil) then
        path = ""
    end
    if (showline == nil) then
        showline = false
    end
    if (maxdepth == nil) then
        maxdepth = 1
    end
	objcache = {}
	local results, linenum = printtablerecursive(table, 0, 1, path, showpath, showline, maxdepth)
    return results
end

function printtablerecursive(table, depth, linenum, path, showpath, showline, maxdepth)
    if (table == objcache) then
        return "", linenum
    end
	if next(table) == nil then
        return pad("Empty table", "", depth + 1, linenum, showpath), linenum+1
	end
    if (depth >= maxdepth) then
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
                if (showline) then
                    result = result..pad(k.." (table)", "", path.."."..k, depth, linenum, showpath)
				else
                    result = result..pad(k.." (table) {line "..(objcache[v]-1).."}", "", path.."."..k, depth, linenum, showpath)
				end
            else
                result = result..pad(k.." (table)", "", path.."."..k, depth, linenum, showpath)
                concat, linenum = printtablerecursive(v, depth+1, linenum, path.."."..k, showpath, showline, maxdepth)
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
