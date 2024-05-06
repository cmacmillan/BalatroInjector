jit.off()

funcUpdateOriginal = nil
funcKeypressedOriginal = nil
funcKeyreleaseOriginal = nil
funcDrawOriginal = nil
funcTextinputOriginal = nil
fIsFirstUpdate = true

yConsoleCur = 0
dyConsoleNonFullscreen = 250
fIsConsoleOpen = true
fPreferConsoleFullscreen = false

dxLeftPadding = 60
dyBottomPadding = 5
dxCursor = 2

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
tOutputHistory = {}
tOutputHistoryLineCount = {}

iCursor = 1
strInputCur = ""

iSelectionStart = nil

strHistoryFilePath = "balatroconsolehistory.txt"

function DumpGlobals()
	local strResults = StrFromTable(_G, "_G", true, true, 5)
	strResults = strResults.."\nMade by https://github.com/cmacmillan"
	local fileGlobals = io.open("C:\\LuaJitHookLogs\\balatroglobals.txt", "w")
	fileGlobals:write(strResults)
	fileGlobals:flush()
	fileGlobals:close()
end

function UnlockAllAchievements()
	for i, j in pairs (_G.G.localization.misc.achievement_names) do 
		_G.unlock_achievement(i)
	end
end

function LeftPressed()
	if (mpKeyDownToDTPressed["lshift"] or mpKeyDownToDTPressed["rshift"]) then
        if (iSelectionStart == nil) then
            iSelectionStart = iCursor 
        end
    else
        iSelectionStart = nil
    end
	iCursor = math.max(1, iCursor - 1)
	dTUntilNextCursorFlicker = dTBetweenCursorFlickers
	fIsCursorVisible = true
end

function RightPressed()
	if (mpKeyDownToDTPressed["lshift"] or mpKeyDownToDTPressed["rshift"]) then
        if (iSelectionStart == nil) then
            iSelectionStart = iCursor 
        end
    else
        iSelectionStart = nil
    end
	iCursor = math.min(string.len(strInputCur) + 1, iCursor + 1)
	dTUntilNextCursorFlicker = dTBetweenCursorFlickers
	fIsCursorVisible = true
end

function UpPressed()
    iCommandHistorySelected = math.max(0, iCommandHistorySelected - 1)
    if (iCommandHistorySelected == cCommandsInHistory) then
        strInputCur = ""
        iCursor = 1
    else
        strInputCur = commandHistory[iCommandHistorySelected]
        iCursor = string.len(strInputCur) + 1
    end
end

function DownPressed()
    iCommandHistorySelected = math.min(cCommandsInHistory, iCommandHistorySelected + 1)
    if (iCommandHistorySelected == cCommandsInHistory) then
        strInputCur = ""
        iCursor = 1
    else
        strInputCur = commandHistory[iCommandHistorySelected]
        iCursor = string.len(strInputCur) + 1
    end
end

function Noop()
end

function Copy()
	if (mpKeyDownToDTPressed["lctrl"] or mpKeyDownToDTPressed["rctrl"]) then
        if (iSelectionStart == iCursor) then
            return
        end

		local iSelectionLeft = math.min(iCursor, iSelectionStart)
		local iSelectionRight = math.max(iCursor, iSelectionStart)
		love.system.setClipboardText(string.sub(strInputCur,iSelectionLeft,iSelectionRight-1))
		iSelectionStart = nil
    end
end

function Cut()
	if (mpKeyDownToDTPressed["lctrl"] or mpKeyDownToDTPressed["rctrl"]) then
        if (iSelectionStart == nil or iSelectionStart == iCursor) then
            return
        end

 		local iSelectionLeft = math.min(iCursor, iSelectionStart)
		local iSelectionRight = math.max(iCursor, iSelectionStart)
		love.system.setClipboardText(string.sub(strInputCur,iSelectionLeft,iSelectionRight-1))
		strInputCur = string.sub(strInputCur,1,iSelectionLeft-1) .. string.sub(strInputCur,iSelectionRight)
	    iCursor = iSelectionLeft 
		iSelectionStart = nil       
    end
end

function SelectAll()
	if (mpKeyDownToDTPressed["lctrl"] or mpKeyDownToDTPressed["rctrl"]) then
        iCursor = 1
        iSelectionStart = string.len(strInputCur) + 1
    end
end

function Paste()
	if (mpKeyDownToDTPressed["lctrl"] or mpKeyDownToDTPressed["rctrl"]) then
		local strPaste = string.gsub(love.system.getClipboardText(),"\n"," ")
        if (iSelectionStart ~= nil) then
			local iSelectionLeft = math.min(iCursor, iSelectionStart)
			local iSelectionRight = math.max(iCursor, iSelectionStart)
			strInputCur = string.sub(strInputCur,1,iSelectionLeft-1) .. strPaste .. string.sub(strInputCur,iSelectionRight)
			iCursor = iSelectionLeft + string.len(strPaste)
			iSelectionStart = nil
        else
			strInputCur = string.sub(strInputCur,1,iCursor-1) .. strPaste .. string.sub(strInputCur,iCursor)
			iCursor = iCursor + string.len(strPaste)
        end

		dTUntilNextCursorFlicker = dTBetweenCursorFlickers
		fIsCursorVisible = true
	end
end

function Split(str, strDelim)
   if strDelim == nil then
      return nil
   end
   local t={}
   for str in string.gmatch(str, "([^"..strDelim.."]+)") do
      table.insert(t, str)
   end
   return t
end

function LoadConsoleHistory()
    local info = love.filesystem.getInfo(strHistoryFilePath)
    if (info == nil) then
        local file = love.filesystem.newFile(strHistoryFilePath)
		file:open("w")
		file:close()
    else
        local strContents = love.filesystem.read(strHistoryFilePath)
        local tSplit = Split(strContents,"\n")
        for i,j in pairs(tSplit) do
            AddCommandToHistory(j)
        end
    end
end

function PrintConsole(text)
    tOutputHistory[cOutputHistory] = text

    local cNewlines = 0
    for i in string.gmatch(text, "\n") do 
        cNewlines = cNewlines + 1
    end
    tOutputHistoryLineCount[cOutputHistory] = cNewlines

    cOutputHistory = cOutputHistory + 1
end

function PrintHelp()
    PrintConsole("\tWelcome to the balatro console!")
    PrintConsole("\tPress f5 to open/close the console. Press f6 to open the console in fullscreen mode.")
    PrintConsole("\tRun 'globals' to open a webpage which documents global variables. Run 'help' to print this help text.")
    PrintConsole("\tTry running 'add_joker(\"j_baron\")' to spawn in a joker.")
    PrintConsole("\tOr try running 'G.FUNCS.reroll_shop()' when in a shop")
    PrintConsole("\tThis console supports any lua commands, including loops, functions, etc.")
end

function AddCommandToHistory(strCommand)
    commandHistory[cCommandsInHistory] = strCommand 
    cCommandsInHistory = cCommandsInHistory + 1
    iCommandHistorySelected = cCommandsInHistory
end

function ReturnPressed()
    PrintConsole(strInputCur)

    AddCommandToHistory(strInputCur)
    --- Write into history file (assume it already exists since we created it when loading the history)
    love.filesystem.append(strHistoryFilePath, strInputCur.."\n")
    

	if (strInputCur == "help") then
        PrintHelp()
	elseif (strInputCur == "globals") then
		love.system.openURL("https://raw.githubusercontent.com/cmacmillan/BalatroInjector/master/balatroglobals.txt")
	elseif (strInputCur == "clear" or strInputCur == "cls") then
        for i,j in pairs(tOutputHistory) do
		    tOutputHistory[i] = nil
            tOutputHistoryLineCount[i] = nil
        end
		cOutputHistory = 0
	else
		local loadResult, loadErr = loadstring("return "..strInputCur)
		if (loadResult == nil) then
		    loadResult, loadErr = loadstring(strInputCur)
            if (loadResult == nil) then
				PrintConsole("\tError: "..loadErr)
				strInputCur = ""
            end
		end

        if (loadResult) then
			local callResult = {pcall(loadResult)}
			if (callResult[1] == true) then
				for i,j in pairs(callResult) do
					if i > 1 then
                        if (type(j) == "table") then
						    PrintConsole("\t"..StrFromTable(j))
                        else
						    PrintConsole("\t"..tostring(j))
                        end
					end
				end
			else
				PrintConsole("\tError: "..callResult[2])
			end
        end
	end
    iCursor = 1
    strInputCur = ""
end

function BackspacePressed()
	if (iSelectionStart ~= nil) then
		local iSelectionLeft = math.min(iCursor, iSelectionStart)
		local iSelectionRight = math.max(iCursor, iSelectionStart)
		strInputCur = string.sub(strInputCur,1,iSelectionLeft-1) .. string.sub(strInputCur,iSelectionRight)
		iSelectionStart = nil
		iCursor = iSelectionLeft
	else
        if (iCursor > 1) then
			iCursor = math.max(1, iCursor - 1)
			strInputCur = string.sub(strInputCur,1,iCursor-1) .. string.sub(strInputCur,iCursor+1)
        end
	end
	dTUntilNextCursorFlicker = dTBetweenCursorFlickers
	fIsCursorVisible = true
end

function DeletePressed()
	if (iSelectionStart ~= nil) then
		local iSelectionLeft = math.min(iCursor, iSelectionStart)
		local iSelectionRight = math.max(iCursor, iSelectionStart)
		strInputCur = string.sub(strInputCur,1,iSelectionLeft-1) .. string.sub(strInputCur,iSelectionRight)
		iSelectionStart = nil
		iCursor = iSelectionLeft
	else
		strInputCur = string.sub(strInputCur,1,iCursor-1) .. string.sub(strInputCur,iCursor+1)
	end
	dTUntilNextCursorFlicker = dTBetweenCursorFlickers
	fIsCursorVisible = true
end

mpKeyNameToFunc = 
{
    ["left"]        = LeftPressed,
    ["right"]       = RightPressed,
    ["up"]          = UpPressed,
    ["down"]        = DownPressed,
    ["return"]      = ReturnPressed,
    ["backspace"]   = BackspacePressed,
    ["delete"]      = DeletePressed,
    ["lctrl"]       = Noop,
    ["rctrl"]       = Noop,
    ["lshift"]      = Noop,
    ["rshift"]      = Noop,
    ["v"]           = Paste,
    ["c"]           = Copy,
    ["x"]           = Cut,
    ["a"]           = SelectAll
}

function KeypressedReplacement(strKey)
    if strKey == "f5" then
        if (fPreferConsoleFullscreen) then
            fPreferConsoleFullscreen = false
            fIsConsoleOpen = true
        else
            fIsConsoleOpen = not fIsConsoleOpen 
        end
    elseif strKey == "f6" then
        if (not fPreferConsoleFullscreen) then
            fPreferConsoleFullscreen = true
            fIsConsoleOpen = true
        else
            fIsConsoleOpen = not fIsConsoleOpen 
        end
    end
    if (fIsConsoleOpen) then
        local func = mpKeyNameToFunc[strKey]
        if (func ~= nil) then
            mpKeyDownToDTPressed[strKey] = 0
            mpKeyDownToCRepeats[strKey] = 1
            func()
        end
    end
    if (not fIsConsoleOpen) then
        funcKeypressedOriginal(strKey)
    end
end

function KeyreleasedReplacement(strKey)
    if (fIsConsoleOpen) then
        mpKeyDownToDTPressed[strKey] = nil
        mpKeyDownToCRepeats[strKey] = nil
    end
    if (not fIsConsoleOpen) then
        funcKeyreleaseOriginal(strKey)
    end
end

function TextinputReplacement(strInput)
    if (fIsConsoleOpen) then
        if (iSelectionStart ~= nil) then
			local iSelectionLeft = math.min(iCursor, iSelectionStart)
			local iSelectionRight = math.max(iCursor, iSelectionStart)
		    strInputCur = string.sub(strInputCur,1,iSelectionLeft-1) .. strInput .. string.sub(strInputCur,iSelectionRight)
            iSelectionStart = nil
            iCursor = iSelectionLeft
        else
		    strInputCur = string.sub(strInputCur,1,iCursor-1) .. strInput .. string.sub(strInputCur,iCursor)
        end
		iCursor = iCursor + 1
		dTUntilNextCursorFlicker = dTBetweenCursorFlickers
		fIsCursorVisible = true
    else
        if (funcTextinputOriginal ~= nil) then
            funcTextinputOriginal(strInput)
        end
    end
end

function DrawReplacement()
    funcDrawOriginal()

	love.graphics.setColor (0,0,0, .5)
    local dxScreen = love.graphics.getWidth();
    local font = love.graphics.getFont()
    dyText = font.getHeight(font)
    love.graphics.polygon("fill", 0,0, dxScreen,0, dxScreen, yConsoleCur, 0,yConsoleCur)

    if (dTUntilNextCursorFlicker < 0) then
        dTUntilNextCursorFlicker = dTUntilNextCursorFlicker + dTBetweenCursorFlickers 
        fIsCursorVisible = not fIsCursorVisible
    end

    yTextTop = yConsoleCur - dyText - dyBottomPadding
    yTextBottom = yTextTop + dyText
	xCursorLeft = dxLeftPadding + font:getWidth(string.sub(strInputCur,1,iCursor-1))

    if (iSelectionStart) then
        local xSelectionLeft = nil
        local xSelectionRight = nil
	    local xSelection = dxLeftPadding + font:getWidth(string.sub(strInputCur,1,iSelectionStart-1))
        if (iCursor < iSelectionStart) then
			xSelectionLeft = xCursorLeft
			xSelectionRight = xSelection 
        else
			xSelectionLeft = xSelection
			xSelectionRight = xCursorLeft
        end
	    love.graphics.setColor (.4,.4,1, 1)
		love.graphics.polygon("fill", xSelectionLeft,yTextTop, xSelectionRight,yTextTop, xSelectionRight,yTextBottom, xSelectionLeft,yTextBottom)
    end

	love.graphics.setColor (1,1,1)
    if (fIsCursorVisible) then
		love.graphics.polygon("fill", xCursorLeft, yTextTop, xCursorLeft+dxCursor,yTextTop, xCursorLeft+dxCursor,yTextBottom, xCursorLeft,yTextBottom)
    end

    local yInputText = yConsoleCur - dyText - dyBottomPadding

    love.graphics.printf(strInputCur, dxLeftPadding, yInputText, love.graphics.getWidth())
	love.graphics.setColor (.9,.9,.9)
    local yOffset = yInputText
    for i=cOutputHistory-1, 0, -1 do
        yOffset = yOffset + -dyText* (1+tOutputHistoryLineCount[i]) - 2
        love.graphics.printf(tOutputHistory[i], dxLeftPadding, yOffset, love.graphics.getWidth())
    end
end

function GMoveTowards(gCurrent, gTarget, gAmount)
    if (gCurrent < gTarget) then
        return math.min(gCurrent + gAmount, gTarget)
    elseif (gCurrent > gTarget) then
        return math.max(gCurrent - gAmount, gTarget) 
    else
        return gCurrent
    end
end

function UpdateReplacement(dT)
    if (fIsFirstUpdate) then
        InjectorPrint("Mod loaded!\n")

        love.errhand = InjectorPrint

        ---DumpGlobals()

		funcKeypressedOriginal = love.keypressed
		funcKeyreleaseOriginal = love.keyreleased
        love.keypressed = KeypressedReplacement
        love.keyreleased = KeyreleasedReplacement

        funcDrawOriginal = love.draw
        love.draw = DrawReplacement

        funcTextinputOriginal = love.textinput
        love.textinput = TextinputReplacement

        LoadConsoleHistory()
        PrintHelp()
        
        fIsFirstUpdate = false
    end

    local yConsoleTarget = 0
    if (fIsConsoleOpen) then
        if (fPreferConsoleFullscreen) then
            yConsoleTarget = love.graphics.getHeight();
        else
            yConsoleTarget = dyConsoleNonFullscreen 
        end
    end

    yConsoleCur = GMoveTowards(yConsoleCur,yConsoleTarget,dT*love.graphics.getHeight()*3)

    dTUntilNextCursorFlicker = dTUntilNextCursorFlicker - dT
    for i, j in pairs(mpKeyDownToDTPressed) do
        mpKeyDownToDTPressed[i] = j + dT
        local dTSinceFirstRepeat = mpKeyDownToDTPressed[i] - dTUntilFirstKeyRepeat
        if (dTSinceFirstRepeat > 0) then
            local cRepeats = math.floor(dTSinceFirstRepeat / dTBetweenKeyRepeats)
            for c = mpKeyDownToCRepeats[i], cRepeats do
                mpKeyNameToFunc[i]()
            end
            mpKeyDownToCRepeats[i] = cRepeats + 1
        end
    end

    funcUpdateOriginal(dT)
end

function StrPad(str, strSuffix, strPath, i, iLinenum, fShowpath)
    ---BB hack
    if (not fShowpath) then
        return str..strSuffix.."\n"
    end
    local strResult = str
    if (false) then
		strLine = tostring(iLinenum-1)
		for c=string.len(strLine), i+6, 1 do
			strResult = "  "..strResult
		end    
		strResult = strLine..strResult
    else
		for c=0, i, 1 do
			strResult = "  "..strResult
		end    
    end

	for c=string.len(strResult), 50, 1 do
		strResult = strResult.." "
	end
	strResult = strResult..strSuffix


    if (fShowpath) then
		for c=string.len(strResult), 130, 1 do
			strResult = strResult.." "
		end
		strResult = strResult..strPath
    end

    strResult = strResult.."\n"
    return strResult
end

function TArgsGet(func)
  local tArgs = {}
  local hook = debug.gethook()

  local argHook = function( ... )
    local info = debug.getinfo(3)
    if 'pcall' ~= info.name then return end
    for i = 1, math.huge do
      local strName, value = debug.getlocal(2, i)
      if strName == nil or '(*temporary)' == strName then
        debug.sethook(hook)
        error('')
        return
      end
      table.insert(tArgs,strName)
    end
  end

  debug.sethook(argHook, "c")
  pcall(func)
  
  return tArgs
end

function PrintTable(t)
    PrintConsole(StrFromTable(t))
end

function StrFromTable(t, strPath, fShowpath, fShowline, cDepthMax)
    if (fShowpath == nil) then
        fShowpath = false
    end
    if (strPath == nil) then
        strPath = ""
    end
    if (fShowline == nil) then
        fShowline = false
    end
    if (cDepthMax == nil) then
        cDepthMax = 1
    end
	tVisitedTables = {}
	local strResults , _ = StrFromTableRecursive(t, 0, 1, strPath, fShowpath, fShowline, cDepthMax)
    return strResults
end

function StrFromTableRecursive(t, cDepth, cLinenum, strPath, fShowpath, fShowline, cDepthMax)
    if (t == tVisitedTables) then
        return "", cLinenum
    end
	if next(t) == nil then
        return StrPad("Empty table", "", cDepth + 1, cLinenum, fShowpath), cLinenum+1
	end
    if (cDepth >= cDepthMax) then
        --- BB hack 
        if (fShowLine) then
            return StrPad("...truncated due to depth", "", strPath, cDepth + 1, cLinenum, fShowpath), cLinenum+1
        else
            return "", cLinenum
        end
    end
    tVisitedTables[t] = cLinenum
    local strResult = ""
    for k, v in pairs(t) do
        cLinenum = cLinenum + 1
		if (type(v) == "function") then
            local strName = k.."("
            local fIsFirst = true 
			for i,j in pairs(TArgsGet(v)) do
                if (not fIsFirst) then
                    strName= strName..", "
                end
                fIsFirst = false
				strName = strName..j
			end
            strName = strName..") (function)"
            strResult = strResult..StrPad(strName, "", strPath.."."..k, cDepth, cLinenum, fShowpath)
		elseif type(v) == "table" then
            if (tVisitedTables[v] ~= nil) then
                if (fShowline) then
                    strResult = strResult..StrPad(k.." (table)", "", strPath.."."..k, cDepth, cLinenum, fShowpath)
				else
                    strResult = strResult..StrPad(k.." (table) {line "..(tVisitedTables[v]-1).."}", "", strPath.."."..k, cDepth, cLinenum, fShowpath)
				end
            else
                strResult = strResult..StrPad(k.." (table)", "", strPath.."."..k, cDepth, cLinenum, fShowpath)
                concat, cLinenum = StrFromTableRecursive(v, cDepth+1, cLinenum, strPath.."."..k, fShowpath, fShowline, cDepthMax)
			    strResult = strResult..concat
            end
        else
            strSuffix = ""
            if (type(v) == "boolean") then
                strSuffix = "= "..tostring(v) 
            elseif (type(v) == "number") then
                strSuffix = "= "..tostring(v) 
            elseif (type(v) == "string") then
                strSuffix = "= "..v:gsub("\n", "\\n")
            end
            strResult = strResult..StrPad(k.." ("..type(v)..") ", strSuffix, strPath.."."..k, cDepth, cLinenum, fShowpath)
		end
    end
    return strResult, cLinenum
end

--- MOD INIT ---

cWaitInit = 0
hookOriginal = debug.gethook()
function trace(event, iLine)
    local info = debug.getinfo(2)

    if not info then return end
    if not info.name then return end
    if string.len(info.name) <= 1 then return end

    if coroutine.running() ~= nil then return end

    if (cWaitInit == 10000) then
        funcUpdateOriginal = love.update
        cWaitInit = cWaitInit + 1
        debug.sethook(hookOriginal)
        love.update = UpdateReplacement
    end

    cWaitInit = cWaitInit + 1
end

debug.sethook(trace, "c")
