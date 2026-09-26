-- engine.lua

function createBlankNotepad()
    return {
        { category = "--- KILLERS ---", isHeader = true },
        { name = "Miss Scarlet", checked = false },
        { name = "Colonel Mustard", checked = false },
        { name = "Mrs. White", checked = false },
        { name = "Mr. Green", checked = false },
        { name = "Mrs. Peacock", checked = false },
        { name = "Professor Plum", checked = false },
        
        { category = "--- WEAPONS ---", isHeader = true },
        { name = "Candlestick", checked = false },
        { name = "Dagger", checked = false },
        { name = "Lead Pipe", checked = false },
        { name = "Revolver", checked = false },
        { name = "Rope", checked = false },
        { name = "Wrench", checked = false },
        
        { category = "--- ROOMS ---", isHeader = true },
        { name = "Kitchen", checked = false },
        { name = "Ballroom", checked = false },
        { name = "Conservatory", checked = false },
        { name = "Dining Room", checked = false },
        { name = "Game Room", checked = false },
        { name = "Library", checked = false },
        { name = "Lounge", checked = false },
        { name = "Hall", checked = false },
        { name = "Study", checked = false }
    }
end

function shuffleStrings(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

function shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

function crossOffCard(notebook, cardName)
    for _, row in ipairs(notebook) do
        if not row.isHeader and row.name == cardName then
            row.checked = true
            break
        end
    end
end

function isCrossedOff(cardName)
    for _, row in ipairs(checklist) do
        if not row.isHeader and row.name == cardName then
            return row.checked
        end
    end
    return false
end

function populateDynamicLists()
    dynamicKillers = {}
    dynamicWeapons = {}
    dynamicRooms   = {}
    
    local sortingMode = "NONE"
    for _, row in ipairs(checklist) do
        if row.isHeader then
            if string.find(row.category, "KILLERS") then sortingMode = "KILLER"
            elseif string.find(row.category, "WEAPONS") then sortingMode = "WEAPON"
            elseif string.find(row.category, "ROOMS") then sortingMode = "ROOM" end
        else
            if not row.checked then
                if sortingMode == "KILLER" then table.insert(dynamicKillers, row.name)
                elseif sortingMode == "WEAPON" then table.insert(dynamicWeapons, row.name)
                elseif sortingMode == "ROOM" then table.insert(dynamicRooms, row.name) end
            end
        end
    end
    if #dynamicKillers == 0 then table.insert(dynamicKillers, caseFile.killer) end
    if #dynamicWeapons == 0 then table.insert(dynamicWeapons, caseFile.weapon) end
    if #dynamicRooms == 0 then table.insert(dynamicRooms, caseFile.room) end
end

function isWalkable(x, y)
    local points = {
        {x = x, y = y},
        {x = x + playerSize - 1, y = y},
        {x = x, y = y + playerSize - 1},
        {x = x + playerSize - 1, y = y + playerSize - 1},
        {x = x + (playerSize / 2), y = y + (playerSize / 2)}
    }
    if gameState == "ROOM_VIEW" and currentRoom and currentRoom.runtimeMask then
        local maskW, maskH = currentRoom.runtimeMask:getSize()
        for _, pt in ipairs(points) do
            local localX = math.floor(pt.x - currentRoom.x)
            local localY = math.floor(pt.y - currentRoom.y)
            if localX < 0 or localX >= maskW or localY < 0 or localY >= maskH then
                return false
            else
                local color = currentRoom.runtimeMask:sample(localX, localY)
                if color == gfx.kColorWhite or color == 1 then
                    if currentRoom.name == "Dining Room" and localX >= 255 and localX <= 260 then
                    else
                        return false
                    end
                end
            end
        end
    else
        if maskImage then
            local maskW, maskH = maskImage:getSize()
            for _, pt in ipairs(points) do
                local clampedX = math.max(0, math.min(maskW - 1, math.floor(pt.x)))
                local clampedY = math.max(0, math.min(maskH - 1, math.floor(pt.y)))
                local color = maskImage:sample(clampedX, clampedY)
                if color == gfx.kColorWhite or color == 1 then
                    return false
                end
            end
        end
    end
    return true
end

function checkRoomTransitions(px, py)
    if not currentRoom and math.abs(px - 233) <= 15 and math.abs(py - 138) <= 15 then
        for _, r in ipairs(rooms) do
            if r.name == "Study" then return r end
        end
    end
    for _, room in ipairs(rooms) do
        if px >= room.x and px <= (room.x + room.w) and py >= room.y and py <= (room.y + room.h) then
            return room
        end
    end
    return nil
end

function resetGameEngine()
    totalAccusationsLeft = 4
    playerTilesLeft = 1000
    pixelRemainder = 0
    currentRoom = nil
    selectedIndex = 2
    scrollOffset = 0
    activeSpeaker = ""
    dialogueText = ""
    crankTicks = 0
    notepadCrankTicks = 0
    tutorialScrollY = 0
    checklist = createBlankNotepad()
    
    for i = 1, #suspects do
        suspects[i].notepad = createBlankNotepad()
        suspects[i].hand = {}
        suspects[i].assignedRoomName = nil
    end
    
    masterKillers = { "Miss Scarlet", "Colonel Mustard", "Mrs. White", "Mr. Green", "Mrs. Peacock", "Professor Plum" }
    masterWeapons = { "Candlestick", "Dagger", "Lead Pipe", "Revolver", "Rope", "Wrench" }
    masterRooms = { "Kitchen", "Ballroom", "Conservatory", "Dining Room", "Game Room", "Library", "Lounge", "Hall", "Study" }
    
    math.randomseed(playdate.getSecondsSinceEpoch())
    math.random() math.random()
    
    local winKillerIdx = math.random(1, #masterKillers)
    local winWeaponIdx = math.random(1, #masterWeapons)
    local winRoomIdx = math.random(1, #masterRooms)
    
    caseFile.killer = table.remove(masterKillers, winKillerIdx)
    caseFile.weapon = table.remove(masterWeapons, winWeaponIdx)
    caseFile.room = table.remove(masterRooms, winRoomIdx)
    
    local dealPool = {}
    for i = 1, #masterKillers do table.insert(dealPool, masterKillers[i]) end
    for i = 1, #masterWeapons do table.insert(dealPool, masterWeapons[i]) end
    for i = 1, #masterRooms do table.insert(dealPool, masterRooms[i]) end
    shuffleStrings(dealPool)
    
    local totalParticipants = 1 + #suspects
    for turn = 1, #dealPool do
        local card = dealPool[turn]
        local targetSeat = (turn - 1) % totalParticipants
        if targetSeat == 0 then
            crossOffCard(checklist, card)
        else
            local AI = suspects[targetSeat]
            crossOffCard(AI.notepad, card)
            table.insert(AI.hand, card)
        end
    end
    
    print("=== CASE FILE HIDDEN ===")
    print("Solution: " .. caseFile.killer .. " with the " .. caseFile.weapon .. " in the " .. caseFile.room)
    
    local poolOfRooms = {}
    for _, room in ipairs(rooms) do
        table.insert(poolOfRooms, room.name)
    end
    shuffleTable(poolOfRooms)
    
    for i, suspect in ipairs(suspects) do
        local roomName = poolOfRooms[i]
        suspect.assignedRoomName = roomName
        for _, room in ipairs(rooms) do
            if room.name == roomName then
                local offset = innerRoomSafeSpots[roomName] or { x = 200, y = 100 }
                suspect.worldX = room.x + offset.x
                suspect.worldY = room.y + offset.y
                break
            end
        end
    end
    
    local chosenSpawnIndex = math.random(1, #startingSpawns)
    local selectedSpawn = startingSpawns[chosenSpawnIndex]
    playerX = selectedSpawn.x
    playerY = selectedSpawn.y
end

-- Initialize Engine
resetGameEngine()

-- Hardware System Menu Interactivity Setup
local menu = playdate.getSystemMenu()
local pauseMenuItem, error = menu:addMenuItem("Pause Game", function()
    if gameState ~= "TITLE" and gameState ~= "GAME_OVER" and gameState ~= "PAUSE" and gameState ~= "TUTORIAL" then
        stateBeforePause = gameState
        gameState = "PAUSE"
    end
end)
local restartMenuItem, error = menu:addMenuItem("Restart Game", function()
    resetGameEngine()
    gameState = "TITLE"
end)

playdate.display.setScale(1)
