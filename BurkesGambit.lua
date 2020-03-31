--[[ Lua code. See documentation: http://berserk-games.com/knowledgebase/scripting/ --]]

--[[ The onLoad event is called after the game save finishes loading. --]]


-- TODO: Provide indicators in front of players as to which spot is which player number.
-- TODO: Resetting the game?


globalDisplayDebugMessages=true
DISTANT_COORDINATES = {99, 99, 99}
TABLE_HEIGHT = 3.3


function onLoad()
    locateCorpIdentityCards(globalDisplayDebugMessages)
    locateRoleCards(globalDisplayDebugMessages)
    locateInfectionCards(globalDisplayDebugMessages)

    createAllDealButtons()
end

function locateCorpIdentityCards(printDebugMessages)
    local printDebugMessages = printDebugMessages or false

    crewCorpIdentityZoneGUID = '05bab9'
    numberOfCrewCorpIdentityCards = #_getCardsFromDeckInZone(crewCorpIdentityZoneGUID)

    assCorpIdentityZoneGUID = 'da4b1d'
    numberOfAssCorpIdentityCards = #_getCardsFromDeckInZone(assCorpIdentityZoneGUID)

    if printDebugMessages then
        print(numberOfCrewCorpIdentityCards .. " crew cards and " .. numberOfAssCorpIdentityCards .. " A.S.S. cards found.")
    end
end

function locateRoleCards(printDebugMessages)
    local printDebugMessages = printDebugMessages or false

    nonCaptainRoleZoneGUID = '971b6a'
    numberOfNonCaptainRoleCardsFound = #_getCardsFromDeckInZone(nonCaptainRoleZoneGUID)

    captainRoleZoneGUID = 'a493dc'
    captainRoleCard = _getOnlyCardInZone(captainRoleZoneGUID)

    if printDebugMessages then
        print(numberOfNonCaptainRoleCardsFound .. " non-captain role cards and 1 captain role cards found.")
    end
end

function locateInfectionCards(printDebugMessages)
    local printDebugMessages = printDebugMessages or false

    cleanInfectionZoneGUID = '238a5d'
    numberOfCleanInfectionCardsFound = #_getCardsFromDeckInZone(cleanInfectionZoneGUID)

    dirtyInfectionZoneGUID = '913134'
    infectedCard = _getOnlyCardInZone(dirtyInfectionZoneGUID)

    if printDebugMessages then
        print(numberOfCleanInfectionCardsFound .. " clean infection cards and 1 dirty infection cards found.")
    end
end

function createAllDealButtons()
    buttonDetails = {
        [4] = {'4', 'dealCardsForFourPlayers',  'f7668b'},
        [5] = {'5', 'dealCardsForFivePlayers',  '4267c7'},
        [6] = {'6', 'dealCardsForSixPlayers',   '2f3c4a'},
        [7] = {'7', 'dealCardsForSevenPlayers', '74ef7d'},
        [8] = {'8', 'dealCardsForEightPlayers', 'c75fcc'}
    }

    for key, values in pairs(buttonDetails) do
        createDealButton(unpack(values))
    end
end

function createDealButton(textToDisplay, click_function, zoneGUID)
    local button_parameters = {}
    button_parameters.click_function = click_function
    button_parameters.function_owner = nil
    button_parameters.label = textToDisplay
    button_parameters.position = {0, 0, 0}
    button_parameters.rotation = {0, 180, 0}
    button_parameters.width = 500
    button_parameters.height = 500
    button_parameters.font_size = 500

    local buttonZone = getObjectFromGUID(zoneGUID)
    buttonZone.createButton(button_parameters)
end

----------------------------- END OF FUNCTIONS THAT RUN ON GAME LOAD ------------------------

function dealCardsForFourPlayers()
    dealCards(4)
end

function dealCardsForFivePlayers()
    dealCards(5)
end

function dealCardsForSixPlayers()
    dealCards(6)
end

function dealCardsForSevenPlayers()
    dealCards(7)
end

function dealCardsForEightPlayers()
    dealCards(8)
end

function dealCards(numberOfPlayers)
    _removeAllButtons()
    dealAllCorporateIdentityCards(numberOfPlayers)
    dealAllRoleCards(numberOfPlayers)
    dealAllInfectionCards(numberOfPlayers)
    dealAllHealthTokens(numberOfPlayers)
    moveInstructionsToMiddleOfTheTable()
    print("Cards dealt to all players.")
end

function moveInstructionsToMiddleOfTheTable()
    local instructionsDeckGUID = 'dc6a7c'
    local instructionsDeck = getObjectFromGUID(instructionsDeckGUID)
    instructionsDeck.setPosition({-4, TABLE_HEIGHT, 0})
end

function dealAllHealthTokens(numberOfPlayers)
    local healthTokenZoneGUID = 'd151fd'
    local zone = getObjectFromGUID(healthTokenZoneGUID)
    local tokens = zone.getObjects()

    -- Move one to the middle of the table (potentially for the Manual Laborer)
    local thisToken = table.remove(tokens)
    thisToken.setPosition({0, TABLE_HEIGHT, 0})

    -- Remove those that we will not need for this game.
    local numberOfTokensWeWillNotNeed = 17 - 1 - 2 * numberOfPlayers
    if globalDisplayDebugMessages then
        print("Number of unneeded health tokens: " .. numberOfTokensWeWillNotNeed)
    end
    for i=1, numberOfTokensWeWillNotNeed do
        thisToken = table.remove(tokens)
        destroyObject(thisToken)
    end
    
    -- Give two to each player.
    local leftRightOffset = 0
    local handRadius = 13
    _placeTokens(numberOfPlayers, tokens, handRadius, leftRightOffset)
    local handRadius = 11
    _placeTokens(numberOfPlayers, tokens, handRadius, leftRightOffset)
end

function _placeTokens(numberOfPlayers, tokens, handRadius, leftRightOffset)
    for i=1, numberOfPlayers do
        local thisToken = table.remove(tokens)
        local position = _calculatePositionForCard(i, handRadius, leftRightOffset)
        thisToken.setPosition(position)
    end
end

function dealAllInfectionCards(numberOfPlayers)
    local cleanInfectionCardDeck = _getOnlyDeckInZone(cleanInfectionZoneGUID)

    cleanInfectionCardDeck.flip()

    local numberOfUnneededCleanInfectionCards = numberOfCleanInfectionCardsFound - (numberOfPlayers - 1)
    if globalDisplayDebugMessages then
        print("Number of unneeded clean infection cards: " .. numberOfUnneededCleanInfectionCards)
    end
    _destroyUnneededCardsFromDeck(numberOfUnneededCleanInfectionCards, cleanInfectionCardDeck)

    cleanInfectionCardDeck.putObject(infectedCard)
    cleanInfectionCardDeck.flip()
    cleanInfectionCardDeck.shuffle()

    -- Distribute the cards.
    local handRadius = 12
    local leftRightOffset = math.pi / 16
    for i=1, numberOfPlayers do
        local params = {}
        params.position = _calculatePositionForCard(i, handRadius, leftRightOffset)
        params.rotation = _calculateRotationForCard(i)
        params.flip = true
        params.smooth = false
        cleanInfectionCardDeck.takeObject(params)
    end

end

function dealAllRoleCards(numberOfPlayers)
    local nonCaptainRoleDeck = _getOnlyDeckInZone(nonCaptainRoleZoneGUID)

    nonCaptainRoleDeck.flip()
    nonCaptainRoleDeck.shuffle()

    -- Remove role cards we don't need.
    local numberOfUnneededRoleCards = numberOfNonCaptainRoleCardsFound - numberOfPlayers + 1
    if globalDisplayDebugMessages then
        print("Number of unneeded role cards: " .. numberOfUnneededRoleCards)
    end
    _destroyUnneededCardsFromDeck(numberOfUnneededRoleCards, nonCaptainRoleDeck)

    -- Shuffle the captain card in.
    captainRoleCard.flip()
    nonCaptainRoleDeck.putObject(captainRoleCard)
    nonCaptainRoleDeck.shuffle()

    -- Distribute the cards.
    local handRadius = 12
    local leftRightOffset = -1 * math.pi / 16
    for i=1, numberOfPlayers do
        local params = {}
        params.position = _calculatePositionForCard(i, handRadius, leftRightOffset)
        params.rotation = _calculateRotationForCard(i)
        params.smooth = false
        nonCaptainRoleDeck.takeObject(params)
    end
end

function dealAllCorporateIdentityCards(numberOfPlayers)
    local numberOfEachCorporateIdentity = {
        [4] = {3, 1},
        [5] = {3, 2},
        [6] = {4, 2},
        [7] = {4, 3},
        [8] = {5, 3}
    }
    local numberOfCrew, numberOfAsses = unpack(numberOfEachCorporateIdentity[numberOfPlayers])

    -- Remove crew cards we don't need.
    local deckOfCorpCardsToDistribute = _getOnlyDeckInZone(crewCorpIdentityZoneGUID)

    local numberOfUnneededCrewCards = numberOfCrewCorpIdentityCards - numberOfCrew
    if globalDisplayDebugMessages then
        print("Number of unneeded crew cards: " .. numberOfUnneededCrewCards)
    end
    _destroyUnneededCardsFromDeck(numberOfUnneededCrewCards, deckOfCorpCardsToDistribute)

    -- Remove unneeded ASS cards and move the remainder into the common deck.
    -- There's a conditional here because if you remove the second to last card from a deck, you lose the deck.
    local numberOfUnneededAssCards = numberOfAssCorpIdentityCards - numberOfAsses
    if globalDisplayDebugMessages then
        print("Number of unneeded A.S.S. cards: " .. numberOfUnneededAssCards)
    end
    
    local assDeck = _getOnlyDeckInZone(assCorpIdentityZoneGUID)
    if numberOfUnneededAssCards < 2 then
        -- Remove ass cards we don't need.
        _destroyUnneededCardsFromDeck(numberOfUnneededAssCards, assDeck)
     
        -- Move ass cards we need into that deck.
        deckOfCorpCardsToDistribute.putObject(assDeck)
    else
        -- Put the card we need in the pile.
        local params = {}
        params.position = DISTANT_COORDINATES
        params.smooth = false        
        local neededAssCard = assDeck.takeObject(params)
        neededAssCard.putObject(deckOfCorpCardsToDistribute)

        -- Remove the remaining deck.
        assDeck.destroy()
    end

    -- Flip and shuffle deck.
    deckOfCorpCardsToDistribute.flip()
    deckOfCorpCardsToDistribute.randomize()

    -- Deal all of these cards out to the players.
    local handRadius = 21.5
    local leftRightOffset = 0
    for i=1, numberOfPlayers do
        local params = {}
        params.position = _calculatePositionForCard(i, handRadius, leftRightOffset)
        params.rotation = _calculateRotationForCard(i)
        params.flip = true
        params.smooth = false
        deckOfCorpCardsToDistribute.takeObject(params)
    end
end

function _calculatePositionForCard(i, handRadius, leftRightOffset)
    local x = math.sin((i - 1) * math.pi / 4 + leftRightOffset) * handRadius
    local z = math.cos((i - 1) * math.pi / 4 + leftRightOffset) * handRadius
    return {x, TABLE_HEIGHT, z}
end

function _calculateRotationForCard(i)
    return {0, (i - 1) * 45, 0}
end

function _destroyUnneededCardsFromDeck(numberToDestroy, deck)
    for i=1, numberToDestroy do
        local params = {}
        params.position = DISTANT_COORDINATES
        params.smooth = false        
        local unneededCard = deck.takeObject(params)
        unneededCard.destruct()
    end
end

function _removeAllButtons()
    for key, values in pairs(buttonDetails) do
        local buttonZone = getObjectFromGUID(values[3])
        local buttons = buttonZone.getButtons()
        buttonZone.removeButton(buttons[1].index)
        table.remove(buttons)
    end
end

------  START OF SAFE ACCESSOR FUNCTIONS - THESE SHOULD SIGNIFICANTLY HELP DEVELOPMENT --------

function _getOnlyDeckInZone(zoneGUID)
    return _getOnlyObjectTypeInZone(zoneGUID, "Deck")
end

function _getOnlyCardInZone(zoneGUID)
    return _getOnlyObjectTypeInZone(zoneGUID, "Card")
end

function _getOnlyObjectTypeInZone(zoneGUID, objectType)
    local zone = getObjectFromGUID(zoneGUID)
    local objectsInZone = zone.getObjects()

    if #objectsInZone ~= 1 then
        error("There were " .. #objectsInZone .. " objects in the zone with GUID '" .. zoneGUID .. "' when we expected only 1.")
    end

    local onlyObjectInZone = objectsInZone[1]
    if onlyObjectInZone.tag ~= objectType then
        error("We expected the only object in the zone with GUID '" .. zoneGUID .. "' to be a '" .. objectType .. "', but instead it was a '" .. onlyObjectInZone.tag .. "'.")
    end

    return onlyObjectInZone
end


function _getCardsFromDeckInZone(zoneGUID)
    -- NOTE: We assume there is only one deck, and nothing else, in the zone.
    local deck = _getOnlyDeckInZone(zoneGUID)
    return deck.getObjects()
end
