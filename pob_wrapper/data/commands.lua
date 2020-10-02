--[==[
    Commands directly available to the wrapper.

    These methods mostly just wrap other methods, providing
    useful return data, printing and error checking.
]==]--

local pobinterface = require("pobinterface")

local commands = {}

function commands.echo_message(msg)
    print(msg)
    return true
end

function commands.echo_result(msg)
    return msg
end

function commands.echo_error(msg)
    error(msg)
end

function commands.getBuildsDir()
    return mainObject.main.buildPath
end

function commands.getBuildInfo(out)
    out = out or {}
    out.buildName = build.buildName
    out.file = {path=build.dbFileName, subpath = build.dbFileSubPath}
    out.char = {
        level = build.characterLevel or 1,
        className = build.spec.curClassName,
        ascendClassName = (build.spec.curAscendClassName ~= "None" and build.spec.curAscendClassName) or build.spec.curClassName or "?",
    }
    local ok, skill = pcall(pobinterface.readSkillSelection)
    if ok then
        out.skill = skill
    else
        out.skill = nil
        print("WARN: Failed to read skill selection: "..skill)
    end
    return out
end

function commands.loadBuild(path)
    pobinterface.loadBuild(path)
    result = getBuildInfo()
    return result
end

function commands.saveBuild()
    if not build.dbFileName then
        error("Attempting to save a build with no filename")
    end
    build:SaveDBFile()
end

function commands.saveBuildAs(path)
    local saveXml = saveBuildToXml()
    saveText(path, saveXml)
end

function commands.updateBuild()
    pobinterface.updateBuild()

    local afterSkill = pobinterface.readSkillSelection()
    print("Final group/gem/part: "..pobinterface.skillString(afterSkill))
end

function commands.findModEffect(modLine)
    print("Testing mod: "..modLine)
    local results = pobinterface.findModEffect(modLine)
    return results
end


return commands
