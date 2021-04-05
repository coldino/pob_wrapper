--[==[
    The CLI processor and main loop.

    Simply listens for commands from the wrapper, executes them and returns the encoded results.
]==]--

local io = require("io")
local json = require('dkjson')
local inspect = require("inspect")

require("mockui")


-- CLI workings

local function use(module, ...)
    for k,v in pairs(module) do
        if _G[k] then
            io.stderr:write("use: skipping duplicate symbol ", k, "\n")
        else
            _G[k] = module[k]
        end
    end
end

local function encode(value)
    return json.encode(value)
end

function record(value)
    result = value
end

local function doline(line)
    result = nil
    local str = nil
    if line and string.sub(line, 1, 1) == ":" then
        -- Statement mode
        str = string.sub(line, 2, -1) .. "\nrecord(nil)"
    else
        -- Expression mode
        str = "record(" .. line .. ")"
    end
    local fn, err = loadstring(str, "<input>")
    print("!*>>>>>>>>>>>>*!")
    if not fn then
        msg = {status='parse_fail', error=err}
    else
        local success, err = pcall(fn)
        if not success then
            msg = {status='run_fail', error=tostring(err)}
        else
            msg = {status='success', result=result}
        end
    end

    print("!*------------*!")
    local success, strmsg = pcall(encode, msg)
    if success then
        print(strmsg)
    else
        print('{"status":"json_invalid","error":' .. encode(strmsg) .. '}')
    end
    print("!*<<<<<<<<<<<<*!")
end

-- Main loop

commands = require("commands")
use(commands)

print("LUA: Started")
io.stdout:flush()

result = nil

while 1 do
    local success, line = pcall(io.stdin.read, io.stdin, "*l") -- read a single line
    if not success then break end
    if line then
        doline(line)
        io.stdout:flush()
    end
end
