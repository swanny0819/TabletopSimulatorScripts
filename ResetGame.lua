resetButtonZoneGUID = 'f7adbf'
allStartingObjectsJSON = {}

function onLoad()
    getJSONForAllPreexistingObjects()
    createDealButton('Reset', 'performReset', resetButtonZoneGUID, {0, 0, 0})
end

function getJSONForAllPreexistingObjects()
    local allObjects = getAllObjects()

    for i=1,#allObjects do
        if allObjects[i].tag ~= "Scripting" then
            allStartingObjectsJSON[i] = allObjects[i].getJSON()
        end
    end
end

function createDealButton(textToDisplay, click_function, zoneGUID, position)
    local button_parameters = {}
    button_parameters.click_function = click_function
    button_parameters.function_owner = nil
    button_parameters.label = textToDisplay
    button_parameters.rotation = {0, 180, 0}
    button_parameters.width = 250
    button_parameters.height = 50
    button_parameters.font_size = 50

    local buttonZone = getObjectFromGUID(zoneGUID)
    buttonZone.createButton(button_parameters)
end

function performReset()
    performDelete()
    performRecreate()
end

function performDelete()
    local allObjects = getAllObjects()
    for i=1,#allObjects do
        if allObjects[i].tag ~= "Scripting" then
            allObjects[i].destroy()
        end
    end
end

function performRecreate()
    for _, objectJSON in pairs(allStartingObjectsJSON) do
        local params = {}
        params.json = objectJSON
        spawnObjectJSON(params)
    end
end
