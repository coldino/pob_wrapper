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
    if not build.spec then
        print("Warning: No build loaded")
        return out
    end
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
    -- Remember previously selected skill
    local prevSkill = pobinterface.readSkillSelection()
    print("Skill group/gem/part: "..pobinterface.skillString(prevSkill))

    -- Update
    pobinterface.updateBuild()

    -- Restore previously selected skill
    print("After group/gem/part: "..pobinterface.skillString())
    pobinterface.selectSkill(prevSkill)
    print("Fixed group/gem/part: "..pobinterface.skillString())
end

function commands.findModEffect(modLine)
    print("Testing mod: "..modLine)
    local results = pobinterface.findModEffect(modLine)
    return results
end

function commands.testItemForDisplay(itemText)
    print("Testing item")
    local results = pobinterface.testItemForDisplay(itemText)
    return results
end

function commands.getKeys(tab)
    local keys = {}
    for k,v in pairs(tab) do
        keys[#keys+1]=k
    end
    return keys
end


return commands
