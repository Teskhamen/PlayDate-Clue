import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics

-- Simplified States & Variables
local gameState = "MAP" 
local totalAccusationsLeft = 4
local playerTilesLeft = 2000 

local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240

-- Track actual dimensions of your 800x800 Big_Map asset
local MAP_WIDTH <const> = 800
local MAP_HEIGHT <const> = 800

-- Load your mask layout safely
local maskImage = gfx.image.new("images/mask_map")
if not maskImage then
    print("Warning: Could not load images/mask_map.png")
end

-- Load your custom 12x12 player sprite asset once globally
local playerSpriteImage = gfx.image.new("images/player")
if not playerSpriteImage then
    print("Warning: Could not load images/player.png")
end

-- ==========================================================
-- ROOM ASSETS & ASSET SIZE OFFSET CALCULATORS
-- ==========================================================
local roomBackgrounds = {
    mansion          = gfx.image.new("images/Big_Map"), 
    board            = gfx.image.new("images/Map_Full"),    
    ballroom         = gfx.image.new("images/Ball_Room"), 
    ballRoomMask     = gfx.image.new("images/Ball_Room_Mask"),
    conservatory     = gfx.image.new("images/Conservatory"),    
    conservatoryMask = gfx.image.new("images/Conservatory_Mask"),
    dining           = gfx.image.new("images/Dining_Room"),    
    diningRoomMask   = gfx.image.new("images/Dining_Room_Mask"),
    game             = gfx.image.new("images/Game_Room"),    
    gameRoomMask     = gfx.image.new("images/Game_Room_Mask"),
    hall             = gfx.image.new("images/Hall"),    
    hallMask         = gfx.image.new("images/Hall_Mask"),
    kitchen          = gfx.image.new("images/Kitchen"),    
    kitchenMask      = gfx.image.new("images/Kitchen_Mask"),
    library          = gfx.image.new("images/Library"),    
    libraryMask      = gfx.image.new("images/Library_Mask"),
    lounge           = gfx.image.new("images/Lounge"),    
    loungeMask       = gfx.image.new("images/Lounge_Mask"),
    study            = gfx.image.new("images/Study"),    
    studyMask        = gfx.image.new("images/Study_Mask")
}

-- Definitive coordinate layout matching your 800x800 map dimensions
local rooms = {
    { name = "Study",        x = 50,  y = 37,  w = 189, h = 96,  img = roomBackgrounds.study,        mask = roomBackgrounds.studyMask },
    { name = "Hall",         x = 326, y = 52,  w = 144, h = 165, img = roomBackgrounds.hall,         mask = roomBackgrounds.hallMask },
    { name = "Lounge",       x = 554, y = 43,  w = 183, h = 150, img = roomBackgrounds.lounge,       mask = roomBackgrounds.loungeMask },
    { name = "Library",      x = 50,  y = 217, w = 186, h = 108, img = roomBackgrounds.library,      mask = roomBackgrounds.libraryMask },
    { name = "Game Room",    x = 50,  y = 388, w = 156, h = 126, img = roomBackgrounds.game,         mask = roomBackgrounds.gameRoomMask },
    { name = "Dining Room",  x = 536, y = 310, w = 168, h = 177, img = roomBackgrounds.dining,       mask = roomBackgrounds.diningRoomMask },
    { name = "Conservatory", x = 50,  y = 598, w = 159, h = 126, img = roomBackgrounds.conservatory, mask = roomBackgrounds.conservatoryMask },
    { name = "Ballroom",     x = 296, y = 541, w = 201, h = 144, img = roomBackgrounds.ballroom,     mask = roomBackgrounds.ballRoomMask },
    { name = "Kitchen",      x = 590, y = 568, w = 150, h = 153, img = roomBackgrounds.kitchen,      mask = roomBackgrounds.kitchenMask }
}
rooms[6].maskW = 400
rooms[6].maskH = 200

for i, room in ipairs(rooms) do
    if room.mask then
        room.runtimeMask = room.mask
    else
        print("Warning: Missing layout mask asset for room: " .. room.name)
    end
end

-- ==========================================================
-- SUSPECT ROOM PLACEMENT SYSTEM
-- ==========================================================
local suspects = {
    { name = "Miss Scarlet",     img = gfx.image.new("images/scarlet_sprite"), hand = {} },
    { name = "Colonel Mustard",  img = gfx.image.new("images/mustard_sprite"), hand = {} },
    { name = "Mrs. White",       img = gfx.image.new("images/white_sprite"), hand = {} },
    { name = "Mr. Green",        img = gfx.image.new("images/green_sprite"), hand = {} },
    { name = "Mrs. Peacock",     img = gfx.image.new("images/peacock_sprite"), hand = {} },
    { name = "Professor Plum",   img = gfx.image.new("images/plum_sprite"), hand = {} }
}

-- ==========================================================
-- MASTER NOTEBOOK TEMPLATES & DEALING ENGINE
-- ==========================================================
local masterKillers = { "Miss Scarlet", "Colonel Mustard", "Mrs. White", "Mr. Green", "Mrs. Peacock", "Professor Plum" }
local masterWeapons = { "Candlestick", "Dagger", "Lead Pipe", "Revolver", "Rope", "Wrench" }
local masterRooms   = { "Kitchen", "Ballroom", "Conservatory", "Dining Room", "Game Room", "Library", "Lounge", "Hall", "Study" }

local caseFile = { killer = "", weapon = "", room = "" }

local function createBlankNotepad()
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

local checklist = createBlankNotepad()
for i = 1, #suspects do
    suspects[i].notepad = createBlankNotepad()
end

local function shuffleStrings(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

local function crossOffCard(notebook, cardName)
    for _, row in ipairs(notebook) do
        if not row.isHeader and row.name == cardName then
            row.checked = true
            break
        end
    end
end

math.randomseed(playdate.getSecondsSinceEpoch())
-- Run a few dummy random numbers to break standard Lua seed determinism
math.random()
math.random()

local winKillerIdx = math.random(1, #masterKillers)
local winWeaponIdx = math.random(1, #masterWeapons)
local winRoomIdx   = math.random(1, #masterRooms)

caseFile.killer = table.remove(masterKillers, winKillerIdx)
caseFile.weapon = table.remove(masterWeapons, winWeaponIdx)
caseFile.room   = table.remove(masterRooms, winRoomIdx)

-- ==========================================================
-- 3. DYNAMIC DEALER POOL CONSOLIDATION (BUG FIX)
-- ==========================================================
local dealPool = {}

-- Safely dump remaining killers from masterKillers
for i = 1, #masterKillers do
    table.insert(dealPool, masterKillers[i])
end

-- Safely dump remaining weapons from masterWeapons
for i = 1, #masterWeapons do
    table.insert(dealPool, masterWeapons[i])
end

-- Safely dump remaining rooms from masterRooms
for i = 1, #masterRooms do
    table.insert(dealPool, masterRooms[i])
end

-- Shuffle the clean, verified deck pool strings
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

local innerRoomSafeSpots = {
    ["Study"]        = { x = 200, y = 90  },
    ["Hall"]         = { x = 200, y = 110 },
    ["Lounge"]       = { x = 220, y = 100 },
    ["Library"]      = { x = 190, y = 135 },
    ["Game Room"]    = { x = 180, y = 100 },
    ["Dining Room"]  = { x = 210, y = 135 },
    ["Conservatory"] = { x = 180, y = 100 },
    ["Ballroom"]     = { x = 200, y = 110 },
    ["Kitchen"]      = { x = 200, y = 100 }
}

local function shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

for _, suspect in ipairs(suspects) do
    suspect.assignedRoomName = nil
    suspect.worldX = 0
    suspect.worldY = 0
end

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

-- ==========================================================
-- PLAYER INITIALIZATION & RANDOM BOARD SPAWNS
-- ==========================================================
local startingSpawns = {
    { x = 734, y = 247 }, { x = 734, y = 538 },
    { x = 470, y = 742 }, { x = 323, y = 742 },
    { x = 56,  y = 568 }, { x = 56,  y = 190 },
    { x = 266, y = 49  }, { x = 527, y = 49  }
}

local chosenSpawnIndex = math.random(1, #startingSpawns)
local selectedSpawn = startingSpawns[chosenSpawnIndex]

local playerX = selectedSpawn.x
local playerY = selectedSpawn.y
local playerSize = 12 
local playerSpeed = 3          
local pixelRemainder = 0       
local currentRoom = nil

local cameraX = 0
local cameraY = 0

local selectedIndex = 2 
local scrollOffset = 0
local stateBeforeNotepad = "MAP"
local activeSpeaker = ""
local dialogueText = ""

-- ==========================================================
-- ACCUSATION WIZARD STATE SELECTION TRACKERS
-- ==========================================================
local accuseWeaponIndex = 1
local accuseRoomIndex = 1
local finalAccuseWeapon = ""
local finalAccuseRoom = ""

local masterWeaponList = { "Candlestick", "Dagger", "Lead Pipe", "Revolver", "Rope", "Wrench" }
local masterRoomList = { "Kitchen", "Ballroom", "Conservatory", "Dining Room", "Game Room", "Library", "Lounge", "Hall", "Study" }

-- Set Display Scale Once at Setup instead of looping it
playdate.display.setScale(1)

-- Helper function to check if a pixel coordinate is walkable
local function isWalkable(x, y)
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
                        -- Exception check pathing allowance
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

local function checkRoomTransitions(px, py)
    for _, room in ipairs(rooms) do
        if px >= room.x and px <= (room.x + room.w) and py >= room.y and py <= (room.y + room.h) then
            return room
        end
    end
    return nil
end

local function handleDpadInput()
    if gameState == "NOTEPAD" then
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            local startingIndex = selectedIndex
            repeat
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then selectedIndex = #checklist end
            until not checklist[selectedIndex].isHeader or selectedIndex == startingIndex
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            local startingIndex = selectedIndex
            repeat
                selectedIndex = selectedIndex + 1
                if selectedIndex > #checklist then selectedIndex = 1 end
            until not checklist[selectedIndex].isHeader or selectedIndex == startingIndex
        end

        if selectedIndex - scrollOffset > 7 then
            scrollOffset = selectedIndex - 7
        elseif selectedIndex - scrollOffset < 2 then
            scrollOffset = math.max(0, selectedIndex - 2)
        end
        
    elseif gameState == "ACCUSE_WEAPON" then
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            accuseWeaponIndex = accuseWeaponIndex - 1
            if accuseWeaponIndex < 1 then accuseWeaponIndex = #masterWeaponList end
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            accuseWeaponIndex = accuseWeaponIndex + 1
            if accuseWeaponIndex > #masterWeaponList then accuseWeaponIndex = 1 end
        end

    elseif gameState == "ACCUSE_ROOM" then
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            accuseRoomIndex = accuseRoomIndex - 1
            if accuseRoomIndex < 1 then accuseRoomIndex = #masterRoomList end
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            accuseRoomIndex = accuseRoomIndex + 1
            if accuseRoomIndex > #masterRoomList then accuseRoomIndex = 1 end
        end
        
    elseif gameState == "MAP" or gameState == "ROOM_VIEW" then
        local dx, dy = 0, 0
        local buttonPressedThisFrame = false
        
        if playdate.buttonJustPressed(playdate.kButtonUp) or
           playdate.buttonJustPressed(playdate.kButtonDown) or
           playdate.buttonJustPressed(playdate.kButtonLeft) or
           playdate.buttonJustPressed(playdate.kButtonRight) then
            buttonPressedThisFrame = true
        end

        if playerTilesLeft > 0 then
            if playdate.buttonIsPressed(playdate.kButtonUp) then dy = -playerSpeed end
            if playdate.buttonIsPressed(playdate.kButtonDown) then dy = playerSpeed end
            if playdate.buttonIsPressed(playdate.kButtonLeft) then dx = -playerSpeed end
            if playdate.buttonIsPressed(playdate.kButtonRight) then dx = playerSpeed end
        end

        local minX, maxX, minY, maxY
        if gameState == "ROOM_VIEW" and currentRoom then
            minX = currentRoom.x
            maxX = currentRoom.x + 400 - playerSize
            minY = currentRoom.y
            maxY = currentRoom.y + 200 - playerSize
        else
            minX = 0
            maxX = MAP_WIDTH - playerSize
            minY = 0
            maxY = MAP_HEIGHT - playerSize
        end

        if dx ~= 0 or dy ~= 0 then
            local moved = false
            if dx ~= 0 then
                local targetX = playerX + dx
                if targetX >= minX and targetX <= maxX then
                    if isWalkable(targetX, playerY) then
                        playerX = targetX
                        moved = true
                    end
                end
            end
            if dy ~= 0 then
                local targetY = playerY + dy
                if targetY >= minY and targetY <= maxY then
                    if isWalkable(playerX, targetY) then
                        playerY = targetY
                        moved = true
                    end
                end
            end

            if moved then
                if buttonPressedThisFrame then
                    playerTilesLeft = playerTilesLeft - 1
                    pixelRemainder = 0
                else
                    pixelRemainder = pixelRemainder + playerSpeed
                    if pixelRemainder >= 16 then
                        playerTilesLeft = playerTilesLeft - 1
                        pixelRemainder = pixelRemainder - 16
                    end
                end

                if gameState == "MAP" then
                    local newRoom = checkRoomTransitions(playerX, playerY)
                    if newRoom then
                        currentRoom = newRoom
                        gameState = "ROOM_VIEW"
                        
                        if currentRoom.name == "Dining Room" then
                            if math.abs(playerX - 530) <= 15 and math.abs(playerY - 391) <= 15 then
                                playerX = 638 + 12; playerY = 403
                            elseif math.abs(playerX - 563) <= 15 and math.abs(playerY - 304) <= 15 then
                                playerX = 674; playerY = 322 + 12
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        elseif currentRoom.name == "Kitchen" then
                            if math.abs(playerX - 617) <= 15 and math.abs(playerY - 555) <= 15 then
                                playerX = 748; playerY = 590 + 12
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        elseif currentRoom.name == "Ballroom" then
                            if math.abs(playerX - 290) <= 15 and math.abs(playerY - 598) <= 15 then
                                playerX = 409 + 12; playerY = 605
                            elseif math.abs(playerX - 326) <= 15 and math.abs(playerY - 535) <= 20 then
                                playerX = 436; playerY = 557 + 12
                            elseif math.abs(playerX - 464) <= 15 and math.abs(playerY - 535) <= 20 then
                                playerX = 525; playerY = 557 + 12
                            elseif math.abs(playerX - 506) <= 15 and math.abs(playerY - 598) <= 15 then
                                playerX = 562 - 12; playerY = 605
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        elseif currentRoom.name == "Conservatory" then
                            if math.abs(playerX - 210) <= 15 and math.abs(playerY - 598) <= 15 then
                                playerX = 319 - 12; playerY = 635
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        elseif currentRoom.name == "Game Room" then
                            if math.abs(playerX - 207) <= 15 and math.abs(playerY - 478) <= 15 then
                                playerX = 331 - 12; playerY = 512
                            elseif math.abs(playerX - 90) <= 15 and math.abs(playerY - 385) <= 15 then
                                playerX = 205; playerY = 419 + 12
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        elseif currentRoom.name == "Library" then
                            if math.abs(playerX - 147) <= 15 and math.abs(playerY - 337) <= 15 then
                                playerX = 243; playerY = 384 - 12
                            elseif math.abs(playerX - 243) <= 15 and math.abs(playerY - 274) <= 15 then
                                playerX = 354 - 12; playerY = 309
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        elseif currentRoom.name == "Study" then
                            if math.abs(playerX - 224) <= 15 and math.abs(playerY - 136) <= 15 then
                                playerX = 361 - 12; playerY = 204
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        elseif currentRoom.name == "Lounge" then
                            if math.abs(playerX - 566) <= 15 and math.abs(playerY - 196) <= 15 then
                                playerX = 660; playerY = 215 - 12
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        elseif currentRoom.name == "Hall" then
                            if math.abs(playerX - 398) <= 15 and math.abs(playerY - 220) <= 15 then
                                playerX = 525; playerY = 222 - 12
                            elseif math.abs(playerX - 323) <= 15 and math.abs(playerY - 157) <= 15 then
                                playerX = 462 + 12; playerY = 174
                            else
                                gameState = "MAP"; currentRoom = nil
                            end
                        end
                    end

                elseif gameState == "ROOM_VIEW" and currentRoom then
                    if currentRoom.name == "Dining Room" then
                        if math.abs(playerX - 638) <= playerSpeed and math.abs(playerY - 403) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 530 - 12; playerY = 391
                        elseif math.abs(playerX - 674) <= 15 and math.abs(playerY - 322) <= playerSpeed then
                            gameState = "MAP"; currentRoom = nil; playerX = 563; playerY = 304 - 12
                        end
                    elseif currentRoom.name == "Kitchen" then
                        if math.abs(playerX - 748) <= 15 and math.abs(playerY - 590) <= (playerSpeed + 2) then
                            gameState = "MAP"; currentRoom = nil; playerX = 617; playerY = 555 - 12
                        end
                    elseif currentRoom.name == "Ballroom" then
                        if math.abs(playerX - 409) <= playerSpeed and math.abs(playerY - 605) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 290 - 12; playerY = 598
                        elseif math.abs(playerX - 436) <= 15 and math.abs(playerY - 557) <= playerSpeed then
                            gameState = "MAP"; currentRoom = nil; playerX = 326; playerY = 535 - 12
                        elseif math.abs(playerX - 525) <= 15 and math.abs(playerY - 557) <= playerSpeed then
                            gameState = "MAP"; currentRoom = nil; playerX = 464; playerY = 535 - 12
                        elseif math.abs(playerX - 562) <= playerSpeed and math.abs(playerY - 605) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 506 + 12; playerY = 598
                        end
                    elseif currentRoom.name == "Conservatory" then
                        if math.abs(playerX - 319) <= playerSpeed and math.abs(playerY - 635) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 210 + 12; playerY = 598
                        end
                    elseif currentRoom.name == "Game Room" then
                        if math.abs(playerX - 331) <= playerSpeed and math.abs(playerY - 512) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 207 + 12; playerY = 478
                        elseif math.abs(playerX - 205) <= 15 and math.abs(playerY - 419) <= playerSpeed then
                            gameState = "MAP"; currentRoom = nil; playerX = 90; playerY = 385 - 12
                        end
                    elseif currentRoom.name == "Library" then
                        if math.abs(playerX - 243) <= 15 and math.abs(playerY - 384) <= (playerSpeed + 2) then
                            gameState = "MAP"; currentRoom = nil; playerX = 147; playerY = 337 + 12
                        elseif math.abs(playerX - 354) <= (playerSpeed + 2) and math.abs(playerY - 309) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 243 + 12; playerY = 274
                        end
                    elseif currentRoom.name == "Study" then
                        if math.abs(playerX - 361) <= (playerSpeed + 2) and math.abs(playerY - 204) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 224 + 12; playerY = 136
                        end
                    elseif currentRoom.name == "Lounge" then
                        if math.abs(playerX - 660) <= 15 and math.abs(playerY - 215) <= (playerSpeed + 2) then
                            gameState = "MAP"; currentRoom = nil; playerX = 566; playerY = 196 + 12
                        end
                    elseif currentRoom.name == "Hall" then
                        if math.abs(playerX - 525) <= 15 and math.abs(playerY - 222) <= (playerSpeed + 2) then
                            gameState = "MAP"; currentRoom = nil; playerX = 398; playerY = 220 + 12
                        elseif math.abs(playerX - 462) <= playerSpeed and math.abs(playerY - 174) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 323 - 12; playerY = 157
                        end
                    end
                end

                -- AUTO-TRIGGER INTERROGATION ON APPROACH
                if currentRoom then
                    for i = 1, #suspects do
                        local suspect = suspects[i]
                        if suspect.assignedRoomName == currentRoom.name then
                            local distX = math.abs(playerX - suspect.worldX)
                            local distY = math.abs(playerY - suspect.worldY)
                            if distX <= 16 and distY <= 16 then
                                activeSpeaker = suspect.name
                                gameState = "DIALOGUE"
                                
                                local unrevealedCards = {}
                                if suspect.hand then
                                    for idx, cardName in ipairs(suspect.hand) do
                                        local humanDiscovered = false
                                        for _, humanRow in ipairs(checklist) do
                                            if humanRow.name == cardName and humanRow.checked then
                                                humanDiscovered = true
                                                break
                                            end
                                        end
                                        if not humanDiscovered then
                                            table.insert(unrevealedCards, cardName)
                                        end
                                    end
                                end
                                
                                if #unrevealedCards > 0 then
                                    local pickedCard = unrevealedCards[math.random(1, #unrevealedCards)]
                                    dialogueText = string.format("I can prove that it wasn't %s. Let me mark that on your checklist.", pickedCard:upper())
                                    for _, humanRow in ipairs(checklist) do
                                        if humanRow.name == pickedCard then
                                            humanRow.checked = true
                                            break
                                        end
                                    end
                                else
                                    dialogueText = "I've already told you everything I know about this case."
                                end
                                
                                break 
                            end
                        end
                    end
                end -- Closes if currentRoom
                
            end -- Closes if moved
        end -- Closes if dx ~= 0 or dy ~= 0

        cameraX = playerX - (SCREEN_WIDTH / 2) + (playerSize / 2)
        if cameraX < 0 then cameraX = 0
        elseif cameraX > (MAP_WIDTH - SCREEN_WIDTH) then cameraX = MAP_WIDTH - SCREEN_WIDTH end
        cameraY = playerY - (SCREEN_HEIGHT / 2) + (playerSize / 2)
        if cameraY < 0 then cameraY = 0
        elseif cameraY > (MAP_HEIGHT - SCREEN_HEIGHT) then cameraY = MAP_HEIGHT - SCREEN_HEIGHT end

    end -- Closes the multi-branch state input block
end -- Closes local function handleDpadInput()

local function handleCrankInput()
    if playdate.isCrankDocked() then
        if gameState == "MAP_FULL" then gameState = "MAP" end
        return
    end
    if gameState == "MAP" or gameState == "MAP_FULL" then
        local crankChange = playdate.getCrankChange()
        if crankChange > 2 then gameState = "MAP_FULL"
        elseif crankChange < -2 then gameState = "MAP" end
    end
end

function playdate.BButtonDown()
    if gameState == "DIALOGUE" then
        local shiftingSuspect = nil
        for i = 1, #suspects do
            if suspects[i].name == activeSpeaker then shiftingSuspect = suspects[i]; break end
        end
        if shiftingSuspect then
            local emptyRooms = {}
            for r = 1, #rooms do
                local roomName = rooms[r].name
                local isOccupied = false
                for s = 1, #suspects do
                    if suspects[s].assignedRoomName == roomName then isOccupied = true; break end
                end
                if not isOccupied then table.insert(emptyRooms, rooms[r]) end
            end
            if #emptyRooms > 0 then
                local chosenRoom = emptyRooms[math.random(1, #emptyRooms)]
                shiftingSuspect.assignedRoomName = chosenRoom.name
                local offset = innerRoomSafeSpots[chosenRoom.name] or { x = 200, y = 100 }
                shiftingSuspect.worldX = chosenRoom.x + offset.x
                shiftingSuspect.worldY = chosenRoom.y + offset.y
            end
        end

        gameState = "ROOM_VIEW"
        activeSpeaker = ""
        dialogueText = ""

    elseif gameState == "ACCUSE_CONFIRM" then
        gameState = "DIALOGUE"
    elseif gameState == "ACCUSE_WEAPON" then
        gameState = "ACCUSE_CONFIRM"
    elseif gameState == "ACCUSE_ROOM" then
        gameState = "ACCUSE_WEAPON"
    elseif gameState == "ACCUSE_SUMMARY" then
        gameState = "ACCUSE_ROOM"
    elseif gameState == "NOTEPAD" then
        gameState = stateBeforeNotepad
    else
        if gameState == "MAP" or gameState == "ROOM_VIEW" then
            stateBeforeNotepad = gameState
            gameState = "NOTEPAD"
        end
    end
end

function playdate.AButtonDown()
    if gameState == "NOTEPAD" then
        local currentItem = checklist[selectedIndex]
        if currentItem and not currentItem.isHeader then
            currentItem.checked = not currentItem.checked
        end
        
    elseif gameState == "DIALOGUE" then
        gameState = "ACCUSE_CONFIRM"
        
    elseif gameState == "ACCUSE_CONFIRM" then
        accuseWeaponIndex = 1
        gameState = "ACCUSE_WEAPON"
        
    elseif gameState == "ACCUSE_WEAPON" then
        finalAccuseWeapon = masterWeaponList[accuseWeaponIndex]
        accuseRoomIndex = 1
        gameState = "ACCUSE_ROOM"
        
    elseif gameState == "ACCUSE_ROOM" then
        finalAccuseRoom = masterRoomList[accuseRoomIndex]
        gameState = "ACCUSE_SUMMARY"
        
    elseif gameState == "ACCUSE_SUMMARY" then
        if activeSpeaker == caseFile.killer and finalAccuseWeapon == caseFile.weapon and finalAccuseRoom == caseFile.room then
            dialogueText = "CORRECT! You solved the case! You found the true killer, weapon, and crime scene."
            gameState = "DIALOGUE" 
            totalAccusationsLeft = 999 
        else
            totalAccusationsLeft = totalAccusationsLeft - 1
            if totalAccusationsLeft <= 0 then
                dialogueText = string.format("WRONG! Game Over. The mystery was %s with the %s in the %s.", caseFile.killer:upper(), caseFile.weapon:upper(), caseFile.room:upper())
                gameState = "DIALOGUE"
                playerTilesLeft = 0 
            else
                dialogueText = string.format("INCORRECT ACCUSATION! That guess was wrong. You have %i attempts remaining.", totalAccusationsLeft)
                gameState = "DIALOGUE"
            end
        end
    end
end

-- ==========================================================
-- MAIN ENGINE UPDATE LOOP (KEEP AT THE VERY BOTTOM OF FILE)
-- ==========================================================
function playdate.update()
    gfx.clear()
    handleDpadInput()
    handleCrankInput()
    
    if gameState == "MAP" then
        if roomBackgrounds.mansion then
            roomBackgrounds.mansion:draw(-cameraX, -cameraY)
        end
        if playerSpriteImage then
            playerSpriteImage:draw(playerX - cameraX, playerY - cameraY)
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.fillEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
        end
        
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, SCREEN_WIDTH, 20)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(string.format("STEPS: %i | ACCUSATIONS: %i", playerTilesLeft, totalAccusationsLeft), 10, 2)
        
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, SCREEN_HEIGHT - 20, SCREEN_WIDTH, 20)
        local roomString = "Path"
        if currentRoom then
            roomString = string.format("Room: %s", currentRoom.name)
        elseif playerTilesLeft == 0 then
            roomString = "OUT OF STEPS!"
        end
        local bottomHudText = string.format("%s | X: %i, Y: %i", roomString, playerX, playerY)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(bottomHudText, 10, SCREEN_HEIGHT - 18)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        
    elseif gameState == "MAP_FULL" then
        if roomBackgrounds.board then
            local boardWidth, boardHeight = roomBackgrounds.board:getSize()
            local centeredX = (SCREEN_WIDTH - boardWidth) / 2
            local centeredY = (SCREEN_HEIGHT - boardHeight) / 2
            roomBackgrounds.board:draw(centeredX, centeredY)
            
            local percentX = playerX / MAP_WIDTH
            local percentY = playerY / MAP_HEIGHT
            local targetX = centeredX + (percentX * boardWidth) - (playerSize / 2)
            local targetY = centeredY + (percentY * boardHeight) - (playerSize / 2)
            
            if math.floor(playdate.getElapsedTime() * 4) % 2 == 0 then
                gfx.setColor(gfx.kColorWhite)
                gfx.fillEllipseInRect(targetX, targetY, playerSize, playerSize)
                gfx.setColor(gfx.kColorBlack)
                gfx.drawEllipseInRect(targetX - 2, targetY - 2, playerSize + 4, playerSize + 4)
            else
                gfx.setColor(gfx.kColorBlack)
                gfx.fillEllipseInRect(targetX, targetY, playerSize, playerSize)
                gfx.setColor(gfx.kColorWhite)
                gfx.drawEllipseInRect(targetX, targetY, playerSize, playerSize)
            end
        end
        
    elseif gameState == "ROOM_VIEW" then
        if currentRoom and currentRoom.img then
            currentRoom.img:draw(0, 20)
        else
            gfx.drawText("Error: Room asset missing!", 20, 20)
        end
        
        if currentRoom then
            for i = 1, #suspects do
                local suspect = suspects[i]
                if suspect.assignedRoomName == currentRoom.name then
                    local localSuspectX = suspect.worldX - currentRoom.x
                    local localSuspectY = (suspect.worldY - currentRoom.y) + 20
                    if suspect.img then
                        suspect.img:draw(localSuspectX, localSuspectY)
                    else
                        gfx.setColor(gfx.kColorBlack)
                        gfx.fillEllipseInRect(localSuspectX, localSuspectY, playerSize, playerSize)
                        gfx.setColor(gfx.kColorWhite)
                        gfx.drawEllipseInRect(localSuspectX, localSuspectY, playerSize, playerSize)
                    end
                end
            end
        end
        
        local localPlayerX = 200
        local localPlayerY = 120
        if currentRoom then
            localPlayerX = playerX - currentRoom.x
            localPlayerY = (playerY - currentRoom.y) + 20
        end
        
        if playerSpriteImage then
            playerSpriteImage:draw(localPlayerX, localPlayerY)
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.fillEllipseInRect(localPlayerX, localPlayerY, playerSize, playerSize)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawEllipseInRect(localPlayerX, localPlayerY, playerSize, playerSize)
        end
        
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, SCREEN_WIDTH, 20)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(string.format("STEPS: %i | ACCUSATIONS: %i", playerTilesLeft, totalAccusationsLeft), 10, 2)
        
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, SCREEN_HEIGHT - 20, SCREEN_WIDTH, 20)
        local roomName = currentRoom and currentRoom.name or "Unknown"
        local debugText = string.format("%s | World: %i,%i | Room: %i,%i", roomName, playerX, playerY, localPlayerX, localPlayerY - 20)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(debugText, 6, SCREEN_HEIGHT - 18)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        
    elseif gameState == "NOTEPAD" then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText("DETECTIVE NOTEPAD", 125, 8)
        gfx.drawLine(20, 24, 380, 24)
        local maxRows = 8
        for i = 1, maxRows do
            local itemIndex = i + scrollOffset
            if itemIndex <= #checklist then
                local currentY = 32 + ((i - 1) * 22)
                local item = checklist[itemIndex]
                if item.isHeader then
                    gfx.drawText(item.category, 120, currentY)
                else
                    if itemIndex == selectedIndex then
                        gfx.drawText("->", 15, currentY)
                    end
                    gfx.drawRect(45, currentY + 2, 11, 11)
                    if item.checked then
                        gfx.drawText("X", 47, currentY - 1)
                        gfx.drawLine(65, currentY + 7, 300, currentY + 7)
                    end
                    gfx.drawText(item.name, 65, currentY)
                end
            end
        end
        
    elseif gameState == "DIALOGUE" then
        if currentRoom and currentRoom.img then
            currentRoom.img:draw(0, 20)
        end
        if currentRoom then
            for i = 1, #suspects do
                local suspect = suspects[i]
                if suspect.assignedRoomName == currentRoom.name then
                    local localSuspectX = suspect.worldX - currentRoom.x
                    local localSuspectY = (suspect.worldY - currentRoom.y) + 20
                    if suspect.img then suspect.img:draw(localSuspectX, localSuspectY) end
                end
            end
        end
        
        local localPlayerX = 200
        local localPlayerY = 120
        if currentRoom then
            localPlayerX = playerX - currentRoom.x
            localPlayerY = (playerY - currentRoom.y) + 20
        end
        if playerSpriteImage then playerSpriteImage:draw(localPlayerX, localPlayerY) end
        
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(15, SCREEN_HEIGHT - 75, SCREEN_WIDTH - 30, 60)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(15, SCREEN_HEIGHT - 75, SCREEN_WIDTH - 30, 60)
        gfx.drawRect(17, SCREEN_HEIGHT - 73, SCREEN_WIDTH - 34, 56)
        gfx.drawText(activeSpeaker:upper(), 25, SCREEN_HEIGHT - 70)
        gfx.drawTextInRect(dialogueText, 25, SCREEN_HEIGHT - 52, SCREEN_WIDTH - 50, 35, 0, gfx.kTextAlignLeft)
        
        if math.floor(playdate.getElapsedTime() * 3) % 2 == 0 then
            gfx.drawText("(B) BACK", SCREEN_WIDTH - 375, SCREEN_HEIGHT - 35)
            gfx.drawText("(A) ACCUSE", SCREEN_WIDTH - 110, SCREEN_HEIGHT - 35)
        end
        
    elseif gameState == "ACCUSE_CONFIRM" then
        if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(20, 40, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 80)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(20, 40, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 80)
        gfx.drawRect(22, 42, SCREEN_WIDTH - 44, SCREEN_HEIGHT - 84)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("CRITICAL ACCUSATION PROMPT", 100, 55)
        gfx.drawLine(40, 75, 360, 75)
        local linesText = string.format("Are you absolutely sure you want to formally accuse %s of committing the crime?", activeSpeaker:upper())
        gfx.drawTextInRect(linesText, 40, 95, SCREEN_WIDTH - 80, 50, 0, gfx.kTextAlignCenter)
        gfx.drawText("(A) CONFIRM SUSPECT", SCREEN_WIDTH - 375, SCREEN_HEIGHT - 70)
        gfx.drawText("(B) CANCEL", SCREEN_WIDTH - 195, SCREEN_HEIGHT - 70)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        
    elseif gameState == "ACCUSE_WEAPON" then
        if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(30, 30, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 60)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(30, 30, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 60)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("SELECT MURDER WEAPON", 110, 40)
        gfx.drawLine(45, 58, 355, 58)
        for i = 1, #masterWeaponList do
            local currentY = 65 + ((i - 1) * 18)
            if i == accuseWeaponIndex then
                gfx.drawText("-> " .. masterWeaponList[i]:upper(), 130, currentY)
            else
                gfx.drawText(masterWeaponList[i], 150, currentY)
            end
        end
        gfx.drawText("(A) CONFIRM WEAPON", 45, SCREEN_HEIGHT - 52)
        gfx.drawText("(B) GO BACK", SCREEN_WIDTH - 130, SCREEN_HEIGHT - 52)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        
    elseif gameState == "ACCUSE_ROOM" then
        if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(30, 22, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 44)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(30, 22, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 44)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("SELECT CRIME SCENE", 110, 28)
        gfx.drawLine(45, 44, 355, 44)
        for i = 1, #masterRoomList do
            local currentY = 48 + ((i - 1) * 15)
            if i == accuseRoomIndex then
                gfx.drawText("-> " .. masterRoomList[i]:upper(), 110, currentY)
            else
                gfx.drawText(masterRoomList[i], 130, currentY)
            end
        end
        gfx.drawText("(A) CONFIRM ROOM", 45, SCREEN_HEIGHT - 42)
        gfx.drawText("(B) GO BACK", SCREEN_WIDTH - 130, SCREEN_HEIGHT - 42)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        
    elseif gameState == "ACCUSE_SUMMARY" then
        if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(20, 35, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 70)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawRect(20, 35, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 70)
        gfx.drawRect(22, 37, SCREEN_WIDTH - 44, SCREEN_HEIGHT - 74)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("FINAL ACCUSATION", 105, 45)
        gfx.drawLine(40, 65, 360, 65)
        gfx.drawText("SUSPECT : " .. activeSpeaker:upper(), 60, 85)
        gfx.drawText("WEAPON : " .. finalAccuseWeapon:upper(), 60, 110)
        gfx.drawText("ROOM : " .. finalAccuseRoom:upper(), 60, 135)
        gfx.drawText("(A) ACCUSE!", 45, SCREEN_HEIGHT - 60)
        gfx.drawText("(B) GO BACK", SCREEN_WIDTH - 135, SCREEN_HEIGHT - 60)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end
