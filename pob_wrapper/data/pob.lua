local pob = {}

-- External interface methods

function pob.echo_message(msg)
    print(msg)
    return true
end

function pob.echo_result(msg)
    return msg
end

function pob.echo_error(msg)
    error(msg)
end

function pob.getBuildsDir()
    return mainObject.main.buildPath
end

function pob.getBuildInfo(out)
    out = out or {}
    out.buildName = build.buildName
    out.file = {path=build.dbFileName, subpath = build.dbFileSubPath}
    out.char = {
        level = build.characterLevel or 1,
        className = build.spec.curClassName,
        ascendClassName = (build.spec.curAscendClassName ~= "None" and build.spec.curAscendClassName) or build.spec.curClassName or "?",
    }
    return out
end

function pob.loadBuild(path)
    loadBuildFromPath(path)
    result = getBuildInfo()
    return result
end

function pob.saveBuild()
    if not build.dbFileName then
        error("Attempting to save a build with no filename")
    end
    build:SaveDBFile()
end

function pob.saveBuildAs(path)
    local saveXml = saveBuildToXml()
    saveText(path, saveXml)
end

function pob.updateBuild()
    -- Update a build from the PoE website automatically, attempting to ensure skills are restored after import

    result = {}

    -- Remember chosen skill and part
    local pickedGroupIndex = build.mainSocketGroup
    local socketGroup = build.skillsTab.socketGroupList[pickedGroupIndex]
    local pickedGroupName = socketGroup.displayLabel
    local pickedActiveSkillIndex = socketGroup.mainActiveSkill
    local displaySkill = socketGroup.displaySkillList[pickedActiveSkillIndex]
    local activeEffect = displaySkill.activeEffect
    local pickedActiveSkillName = activeEffect.grantedEffect.name
    local pickedPartIndex = activeEffect.grantedEffect.parts and activeEffect.srcInstance.skillPart
    local pickedPartName = activeEffect.grantedEffect.parts and activeEffect.grantedEffect.parts[pickedPartIndex].name

    result.character = build.buildName
    result.currentSkill = {group=pickedGroupName, name=pickedActiveSkillName, part=(pickedPartName or '-')}

    -- Check we have an account name
    if not isValidString(build.importTab.controls.accountName.buf) then
        error("Account name not configured")
    end
    result.account = build.importTab.controls.accountName.buf

    -- Check we have a character name
    if not build.importTab.lastCharacterHash or not isValidString(build.importTab.lastCharacterHash:match("%S")) then
        error("Import not configured for this character")
    end

    -- Get character list
    build.importTab:DownloadCharacterList()

    -- Import tree and jewels
    build.importTab.controls.charImportTreeClearJewels.state = true
    build.importTab:DownloadPassiveTree()
    -- print('Status: '..build.importTab.charImportStatus)

    -- Import items and skills
    build.importTab.controls.charImportItemsClearItems.state = true
    build.importTab.controls.charImportItemsClearSkills.state = true
    build.importTab:DownloadItems()
    -- print('Status: '..build.importTab.charImportStatus)

    -- Update skills
    build.outputRevision = build.outputRevision + 1
    build.buildFlag = false
    build.calcsTab:BuildOutput()
    build:RefreshStatList()
    build:RefreshSkillSelectControls(build.controls, build.mainSocketGroup, "")

    -- Restore chosen skills
    local newGroupIndex = build.mainSocketGroup
    socketGroup = build.skillsTab.socketGroupList[newGroupIndex]
    local newGroupName = socketGroup.displayLabel

    if newGroupName ~= pickedGroupName then
        print("Socket group name doesn't match... fixing")
        for i,grp in pairs(build.skillsTab.socketGroupList) do
            if grp.displayLabel == pickedGroupName then
                build.mainSocketGroup = i
                newGroupIndex = i
                socketGroup = build.skillsTab.socketGroupList[newGroupIndex]
                newGroupName = socketGroup.displayLabel
                break
            end
        end
        if newGroupName ~= pickedGroupName then
            error("Previous socket group not found")
        end
    end

    local newActiveSkillIndex = socketGroup.mainActiveSkill
    local displaySkill = socketGroup.displaySkillList[newActiveSkillIndex]
    local activeEffect = displaySkill.activeEffect
    local newActiveSkillName = activeEffect.grantedEffect.name

    if newActiveSkillName ~= pickedActiveSkillName then
        print("Active skill doesn't match... fixing")
        for i,skill in pairs(socketGroup.displaySkillList) do
            if skill.activeEffect.grantedEffect.name == pickedActiveSkillName then
                socketGroup.mainActiveSkill = i
                newActiveSkillIndex = i
                displaySkill = socketGroup.displaySkillList[newActiveSkillIndex]
                activeEffect = displaySkill.activeEffect
                newActiveSkillName = activeEffect.grantedEffect.name
                break
            end
        end
        if newGroupName ~= pickedGroupName then
            error("Previous active skill not found")
        end
    end

    local newPartIndex = activeEffect.grantedEffect.parts and activeEffect.srcInstance.skillPart
    local newPartName = activeEffect.grantedEffect.parts and activeEffect.grantedEffect.parts[newPartIndex].name
    -- print("After import sub-skill: "..newPartName)

    if pickedPartIndex and newPartName ~= pickedPartName then
        print("Active sub-skill doesn't match... fixing")
        for i,part in pairs(activeEffect.grantedEffect.parts) do
            -- print(inspect(part, {depth=1}))
            if part.name == pickedPartName then
                activeEffect.srcInstance.skillPart = i
                newPartIndex = i
                newPartName = part.name
                break
            end
        end
        if newPartName ~= pickedPartName then
            error("Previous active skill-part not found")
        end
    end

    return result
end

function pob.findModEffect(modLine)
    -- Construct an empty passive socket node to test in
    local testNode = {id="temporary-test-node", type="Socket", alloc=false, sd={"Temp Test Socket"}, modList={}}

    -- Construct jewel with the mod just to use its mods in the passive node
    local itemText = "Test Jewel\nMurderous Eye Jewel\n"..modLine
    local item = new("Item", build.targetVersion, itemText)
    testNode.modList = item.modList

    -- Calculate stat differences
    local calcFunc, baseStats = build.calcsTab:GetMiscCalculator()
    local newStats = calcFunc({ addNodes={ [testNode]=true } })

    return {base=baseStats, new=newStats}
end

function pob.getBaseStats()
    local _, baseStats = build.calcsTab:GetMiscCalculator()
    return baseStats
end

function pob.testItemForDisplay(itemText)
    local newItem = new("Item", build.targetVersion, itemText)
    -- if not newItem.base then error("No item base found") end

	newItem:NormaliseQuality() -- Set to top quality
	newItem:BuildModList()

	-- Extract new item's info to a fake HTML tooltip
	local tooltip = FakeTooltip:new()
    build.itemsTab:AddItemTooltip(tooltip, newItem)

    return tooltip.lines
end

return pob
