#@
-- This wrapper allows the program to run headless on any OS (in theory)
-- It can be run using a standard lua interpreter, although LuaJIT is preferable

t_insert = table.insert
t_remove = table.remove
m_min = math.min
m_max = math.max
m_floor = math.floor
m_abs = math.abs
s_format = string.format

if not unpack then
    unpack = table.unpack
end

if not bit then
    bit = require('bit')
end

if not loadstring then
    loadstring = load
end


-- Callbacks
callbackTable = { }
mainObject = nil
function runCallback(name, ...)
    if callbackTable[name] then
        return callbackTable[name](...)
    elseif mainObject and mainObject[name] then
        return mainObject[name](mainObject, ...)
    end
end
function SetCallback(name, func)
    callbackTable[name] = func
end
function GetCallback(name)
    return callbackTable[name]
end
function SetMainObject(obj)
    mainObject = obj
end

-- Image Handles
imageHandleClass = { }
imageHandleClass.__index = imageHandleClass
function NewImageHandle()
    return setmetatable({ }, imageHandleClass)
end
function imageHandleClass:Load(fileName, ...)
    self.valid = true
end
function imageHandleClass:Unload()
    self.valid = false
end
function imageHandleClass:IsValid()
    return self.valid
end
function imageHandleClass:SetLoadingPriority(pri) end
function imageHandleClass:ImageSize()
    return 1, 1
end

-- Rendering
function RenderInit() end
function GetScreenSize()
    return 1920, 1080
end
function SetClearColor(r, g, b, a) end
function SetDrawLayer(layer, subLayer) end
function SetViewport(x, y, width, height) end
function SetDrawColor(r, g, b, a) end
function DrawImage(imgHandle, left, top, width, height, tcLeft, tcTop, tcRight, tcBottom) end
function DrawImageQuad(imageHandle, x1, y1, x2, y2, x3, y3, x4, y4, s1, t1, s2, t2, s3, t3, s4, t4) end
function DrawString(left, top, align, height, font, text) end
function DrawStringWidth(height, font, text)
    return 1
end
function DrawStringCursorIndex(height, font, text, cursorX, cursorY)
    return 0
end
function StripEscapes(text)
    return text:gsub("^%d",""):gsub("^x%x%x%x%x%x%x","")
end
function GetAsyncCount()
    return 0
end

-- Search Handles
function NewFileSearch() end

-- General Functions
function SetWindowTitle(title) end
function GetCursorPos()
    return 0, 0
end
function SetCursorPos(x, y) end
function ShowCursor(doShow) end
function IsKeyDown(keyName) end
function Copy(text) end
function Paste() end
function Deflate(data)
    -- TODO: Might need this
    return ""
end
function Inflate(data)
    -- TODO: And this
    return ""
end
function GetTime()
    return 0
end
function GetScriptPath()
    return os.getenv('POB_SCRIPTPATH')
end
function GetRuntimePath()
    return os.getenv('POB_RUNTIMEPATH')
end
function GetUserPath()
    return os.getenv('POB_USERPATH')
end
function MakeDir(path) end
function RemoveDir(path) end
function SetWorkDir(path) end
function GetWorkDir()
    return ""
end
function LaunchSubScript(scriptText, funcList, subList, ...) end

function DownloadPage(self, url, callback, cookies)
	-- Download the given page then calls the provided callback function when done:
    -- callback(pageText, errMsg)

    ConPrintf("Downloading page at: %s", url)
    local curl = require("lcurl.safe")
    local page = ""
    local easy = curl.easy()
    easy:setopt_url(url)
    easy:setopt(curl.OPT_ACCEPT_ENCODING, "")
    if cookies then
        easy:setopt(curl.OPT_COOKIE, cookies)
    end
    if proxyURL then
        easy:setopt(curl.OPT_PROXY, proxyURL)
    end
    easy:setopt_writefunction(function(data)
        page = page..data
        return true
    end)
    local _, error = easy:perform()
    local code = easy:getinfo(curl.INFO_RESPONSE_CODE)
    easy:close()
    local errMsg
    if error then
        errMsg = error:msg()
    elseif code ~= 200 then
        errMsg = "Response code: "..code
    elseif #page == 0 then
        errMsg = "No data returned"
    end
    ConPrintf("Download complete. Status: %s", errMsg or "OK")
    if errMsg then
        callback(nil, errMsg)
    else
        callback(page, nil)
    end
end

function AbortSubScript(ssID) end
function IsSubScriptRunning(ssID) end
function LoadModule(fileName, ...)
    if not fileName:match("%.lua") then
        fileName = fileName .. ".lua"
    end
    local func, err = loadfile(fileName)
    if func then
        return func(...)
    else
        error("LoadModule() error loading '"..fileName.."': "..err)
    end
end
function PLoadModule(fileName, ...)
    if not fileName:match("%.lua") then
        fileName = fileName .. ".lua"
    end
    local func, err = loadfile(fileName)
    if func then
        return PCall(func, ...)
    else
        error("PLoadModule() error loading '"..fileName.."': "..err)
    end
end
function PCall(func, ...)
    local ret = { pcall(func, ...) }
    if ret[1] then
        table.remove(ret, 1)
        return nil, unpack(ret)
    else
        return ret[2]
    end
end
function ConPrintf(fmt, ...)
    -- Optional
    -- print(string.format(fmt, ...))
end
function ConPrintTable(tbl, noRecurse) end
function ConExecute(cmd) end
function ConClear() end
function SpawnProcess(cmdName, args) end
function OpenURL(url) end
function SetProfiling(isEnabled) end
function Restart() end
function Exit() end

function isValidString(s, expression)
    return s and s:match(expression or '%S') and true or false
end


dofile("Launch.lua")

-- Patch some functions
mainObject.DownloadPage = DownloadPage
mainObject.CheckForUpdate = function () end

runCallback("OnInit")
runCallback("OnFrame") -- Need at least one frame for everything to initialise

if mainObject.promptMsg then
    -- Something went wrong during startup
    error("ERROR: "..mainObject.promptMsg)
    return
end

-- The build module; once a build is loaded, you can find all the good stuff in here
build = mainObject.main.modes["BUILD"]
calcs = build.calcsTab.calcs

-- Here's some helpful helper functions to help you get started
function newBuild()
    mainObject.main:SetMode("BUILD", false, "Help, I'm stuck in Path of Building!")
    runCallback("OnFrame")
end
function loadBuildFromPath(path)
    local dir, fileName, ext = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
    local buildName = fileName:gsub("%.xml$","")
    mainObject.main:SetMode("BUILD", path, buildName)
    runCallback("OnFrame")
end
function loadBuildFromXML(xmlText)
    mainObject.main:SetMode("BUILD", false, "", xmlText)
    runCallback("OnFrame")
end
function loadBuildFromJSON(getItemsJSON, getPassiveSkillsJSON)
    mainObject.main:SetMode("BUILD", false, "")
    runCallback("OnFrame")
    local charData = build.importTab:ImportItemsAndSkills(getItemsJSON)
    build.importTab:ImportPassiveTreeAndJewels(getPassiveSkillsJSON, charData)
    -- You now have a build without a correct main skill selected, or any configuration options set
    -- Good luck!
end

function saveBuildToXml()
    local xmlText = build:SaveDB("dummy")
    if not xmlText then
        print("Failed to prepare save XML")
        os.exit(1)
    end
    return xmlText
end

function saveText(filename, text)
    local file = io.open(filename, "w+")
    if not file then
        print("Failed to write to output file")
        os.exit(1)
    end
    file:write(text)
    file:close()
end

function loadText(fileName)
    local fileHnd, errMsg = io.open(fileName, "r")
    if not fileHnd then
        print("Failed to load file: "..fileName)
        os.exit(1)
        -- return nil, errMsg
    end
    local fileText = fileHnd:read("*a")
    fileHnd:close()
    return fileText
end

function loadTextLines(fileName)
    local fileHnd, errMsg = io.open(fileName, "r")
    if not fileHnd then
        print("Failed to load file: "..fileName)
        os.exit(1)
        -- return nil, errMsg
    end
    local output = {}
    for line in fileHnd:lines() do
        output[#output + 1] = line
    end
    fileHnd:close()
    return output
end


FakeTooltip = {
    lines = {},
    sep = '----',
}

function FakeTooltip:new()
	o = {}
	setmetatable(o, self)
    self.__index = self
    self.lines = {}
	return o
end

function FakeTooltip:AddLine(_, txt)
	table.insert(self.lines, txt)
end

function FakeTooltip:AddSeparator(_, _)
	table.insert(self.lines, self.sep)
end
