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
    -- Top Row Rooms
    { name = "Study",        x = 50,  y = 37,  w = 189, h = 96,  img = roomBackgrounds.study,        mask = roomBackgrounds.studyMask },
    { name = "Hall",         x = 326, y = 52,  w = 144, h = 165, img = roomBackgrounds.hall,         mask = roomBackgrounds.hallMask },
    { name = "Lounge",       x = 554, y = 43,  w = 183, h = 150, img = roomBackgrounds.lounge,       mask = roomBackgrounds.loungeMask },
    
    -- Middle Row Rooms
    { name = "Library",      x = 50,  y = 217, w = 186, h = 108, img = roomBackgrounds.library,      mask = roomBackgrounds.libraryMask },
    { name = "Game Room",    x = 50,  y = 388, w = 156, h = 126, img = roomBackgrounds.game,         mask = roomBackgrounds.gameRoomMask },
    { name = "Dining Room",  x = 536, y = 310, w = 168, h = 177, img = roomBackgrounds.dining,       mask = roomBackgrounds.diningRoomMask },
    
    -- Bottom Row Rooms
    { name = "Conservatory", x = 50,  y = 598, w = 159, h = 126, img = roomBackgrounds.conservatory, mask = roomBackgrounds.conservatoryMask },
    { name = "Ballroom",     x = 296, y = 541, w = 201, h = 144, img = roomBackgrounds.ballroom,     mask = roomBackgrounds.ballRoomMask },
    { name = "Kitchen",      x = 590, y = 568, w = 150, h = 153, img = roomBackgrounds.kitchen,      mask = roomBackgrounds.kitchenMask }
}
-- Inject separate ROOM_VIEW dimensions for the Dining Room safely via code injection
rooms[6].maskW =400
rooms[6].maskH = 200

-- ==========================================================
-- ROOM ASSET INITIALIZER
-- ==========================================================
for i, room in ipairs(rooms) do
    if room.mask then
        -- We don't need getMaskImage(). We will read the pixel colors directly!
        room.runtimeMask = room.mask
    else
        print("Warning: Missing layout mask asset for room: " .. room.name)
    end
end

-- ==========================================================
-- SUSPECT ROOM PLACEMENT SYSTEM
-- ==========================================================
local suspects = {
    { name = "Miss Scarlet",     img = gfx.image.new("images/scarlet_sprite") },
    { name = "Colonel Mustard",  img = gfx.image.new("images/mustard_sprite") },
    { name = "Mrs. White",       img = gfx.image.new("images/white_sprite") },
    { name = "Mr. Green",        img = gfx.image.new("images/green_sprite") },
    { name = "Mrs. Peacock",     img = gfx.image.new("images/peacock_sprite") },
    { name = "Professor Plum",   img = gfx.image.new("images/plum_sprite") }
}

-- Safe, walkable inner room coordinates for suspects (offset relative to room.x, room.y)
-- These keep suspects out of doorways and clear of wall clipping zones
local innerRoomSafeSpots = {
    ["Study"]        = { x = 60,  y = 40  },
    ["Hall"]         = { x = 70,  y = 100 },
    ["Lounge"]       = { x = 80,  y = 60  },
    ["Library"]      = { x = 100, y = 50  },
    ["Game Room"]    = { x = 60,  y = 60  },
    ["Dining Room"]  = { x = 80,  y = 90  },
    ["Conservatory"] = { x = 70,  y = 70  },
    ["Ballroom"]     = { x = 100, y = 80  },
    ["Kitchen"]      = { x = 60,  y = 70  }
}

-- Shuffle helper function to randomize our room allocation list
local function shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end

-- Clear out any existing suspect positions
for _, suspect in ipairs(suspects) do
    suspect.assignedRoomName = nil
    suspect.worldX = 0
    suspect.worldY = 0
end

-- Create a list of available room names and shuffle them
local poolOfRooms = {}
for _, room in ipairs(rooms) do
    table.insert(poolOfRooms, room.name)
end
shuffleTable(poolOfRooms)

-- Assign each suspect to a unique random room from the shuffled pool
for i, suspect in ipairs(suspects) do
    local roomName = poolOfRooms[i]
    suspect.assignedRoomName = roomName
    
    -- Find the global room data to calculate their exact world position
    for _, room in ipairs(rooms) do
        if room.name == roomName then
            local offset = innerRoomSafeSpots[roomName] or { x = 50, y = 50 }
            suspect.worldX = room.x + offset.x
            suspect.worldY = room.y + offset.y
            break
        end
    end
end


-- Simulated Player Position & Dimensions
local playerX = 500 
-- ==========================================================
-- RANDOM SUSPECT SPAWN CONFIGURATION
-- ==========================================================
local startingSpawns = {
    { x = 734, y = 247 }, -- Right side top
    { x = 734, y = 538 }, -- Right side bottom
    { x = 470, y = 742 }, -- Bottom side right
    { x = 323, y = 742 }, -- Bottom side left
    { x = 56,  y = 568 }, -- Left side bottom
    { x = 56,  y = 190 }, -- Left side top
    { x = 266, y = 49  }, -- Top side left
    { x = 527, y = 49  }  -- Top side right
}

-- Seed the randomizer using the Playdate's internal clock system
math.randomseed(playdate.getSecondsSinceEpoch())

-- Pick one of the 8 spots out of the hat
local chosenSpawnIndex = math.random(1, #startingSpawns)
local selectedSpawn = startingSpawns[chosenSpawnIndex]

-- Assign your original variables to the newly selected random location!
local playerX = selectedSpawn.x
local playerY = selectedSpawn.y

-- Simulated Player Dimensions & Speeds
local playerSize = 12 
local playerSpeed = 3          
local pixelRemainder = 0       
local currentRoom = nil

-- Full 2D Camera Tracking offsets
local cameraX = 0
local cameraY = 0

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
        -- Allow boundary reading up to the full image canvas (400px)
        local maskW, maskH = currentRoom.runtimeMask:getSize()
        
        for _, pt in ipairs(points) do
            local localX = math.floor(pt.x - currentRoom.x)
            local localY = math.floor(pt.y - currentRoom.y)
            
            if localX < 0 or localX >= maskW or localY < 0 or localY >= maskH then
                return false 
            else
                local color = currentRoom.runtimeMask:sample(localX, localY)
                if color == gfx.kColorWhite or color == 1 then
                    -- Exception: Ignore the line at 255-260 in the Dining Room
                    if currentRoom.name == "Dining Room" and localX >= 255 and localX <= 260 then
                        -- Allow walking through
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
                if color == gfx.image.kColorWhite or color == 1 then
                    return false 
                end
            end
        end
    end
    
    return true 
end
-- Determines if coordinates clash with room boundaries
local function checkRoomTransitions(px, py)
    for _, room in ipairs(rooms) do
        if px >= room.x and px <= (room.x + room.w) and py >= room.y and py <= (room.y + room.h) then
            return room
        end
    end
    return nil
end

-- Plain table setup with Headers and Items
local checklist = {
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
    { name = "Billiard Room", checked = false },
    { name = "Library", checked = false },
    { name = "Lounge", checked = false },
    { name = "Hall", checked = false },
    { name = "Study", checked = false }
}
local selectedIndex = 2 
local scrollOffset = 0

-- Track the previous state before entering the notepad
local stateBeforeNotepad = "MAP"

function playdate.BButtonDown()
    if gameState == "NOTEPAD" then
        -- Close the notepad and return to exactly where you were (MAP or ROOM_VIEW)
        gameState = stateBeforeNotepad
    else
        -- Only allow opening the notepad if you are actively walking around
        if gameState == "MAP" or gameState == "ROOM_VIEW" then
            stateBeforeNotepad = gameState -- Remember if we were in the hallway or a room
            gameState = "NOTEPAD"
        end
    end
end

function playdate.AButtonDown()
    if gameState == "NOTEPAD" then
        if not checklist[selectedIndex].isHeader then
            checklist[selectedIndex].checked = not checklist[selectedIndex].checked
        end
    end
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

                -- ==========================================================
                -- 1. ENTRY LOGIC: MAP -> ROOM_VIEW
                -- ==========================================================
                if gameState == "MAP" then
                    local newRoom = checkRoomTransitions(playerX, playerY)
                    if newRoom then
                        currentRoom = newRoom
                        gameState = "ROOM_VIEW"
                        
        -- DINING ROOM ENTRY DETECTOR (SECURED)
if currentRoom.name == "Dining Room" then
            if math.abs(playerX - 530) <= 15 and math.abs(playerY - 391) <= 15 then
                playerX = 638 + 12; playerY = 403
            elseif math.abs(playerX - 563) <= 15 and math.abs(playerY - 304) <= 15 then
                playerX = 674; playerY = 322 + 12
            else                -- FIX: CRITICAL WALL PASS PROTECTION!
                -- If they hit the room box somewhere other than a door, cancel the change.
                -- Drop them out of ROOM_VIEW immediately back onto the MAP layer.
                gameState = "MAP"
                currentRoom = nil
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
                                playerX = 485; playerY = 580
                            end
                        elseif currentRoom.name == "Conservatory" then
                            if math.abs(playerX - 210) <= 15 and math.abs(playerY - 598) <= 15 then
                                playerX = 319 - 12; playerY = 635
                            else
                                playerX = 319 - 12; playerY = 635
                            end
                        elseif currentRoom.name == "Game Room" then
                            if math.abs(playerX - 207) <= 15 and math.abs(playerY - 478) <= 15 then
                                playerX = 331 - 12; playerY = 512
                            elseif math.abs(playerX - 90) <= 15 and math.abs(playerY - 385) <= 15 then
                                playerX = 205; playerY = 419 + 12
                            else
                                playerX = 331 - 12; playerY = 512
                            end
                        elseif currentRoom.name == "Library" then
                            if math.abs(playerX - 147) <= 15 and math.abs(playerY - 337) <= 15 then
                                playerX = 243; playerY = 384 - 12
                            elseif math.abs(playerX - 243) <= 15 and math.abs(playerY - 274) <= 15 then
                                playerX = 354 - 12; playerY = 309
                            else
                                playerX = 290; playerY = 296
                            end
                        elseif currentRoom.name == "Study" then
                            if math.abs(playerX - 224) <= 15 and math.abs(playerY - 136) <= 15 then
                                playerX = 361 - 12; playerY = 204
                            else
                                playerX = 300; playerY = 180
                            end
                        elseif currentRoom.name == "Lounge" then
                            if math.abs(playerX - 566) <= 15 and math.abs(playerY - 196) <= 15 then
                                playerX = 660; playerY = 215 - 12
                            else
                                playerX = 660; playerY = 150
                            end
                        elseif currentRoom.name == "Hall" then
                            if math.abs(playerX - 398) <= 15 and math.abs(playerY - 220) <= 15 then
                                playerX = 525; playerY = 222 - 12
                            elseif math.abs(playerX - 323) <= 15 and math.abs(playerY - 157) <= 15 then
                                playerX = 462 + 12; playerY = 174
                            else
                                playerX = 490; playerY = 160
                            end
elseif currentRoom.name == "Kitchen" then
            -- Match your precise entry point at Map 617, 555
            if math.abs(playerX - 617) <= 15 and math.abs(playerY - 555) <= 15 then
                playerX = 748
                playerY = 590 + 12 -- Spawn slightly down to step inside cleanly
            else
                -- Cancel entry if they hit a wall boundary instead of a door
                gameState = "MAP"; currentRoom = nil
            end
                        end
                    end

                -- ==========================================================
                -- 2. EXIT LOGIC: ROOM_VIEW -> MAP
                -- ==========================================================
                elseif gameState == "ROOM_VIEW" and currentRoom then
                    if currentRoom.name == "Dining Room" then
                        if math.abs(playerX - 638) <= playerSpeed and math.abs(playerY - 403) <= 15 then
                            gameState = "MAP"; currentRoom = nil; playerX = 530 - 12; playerY = 391
                        elseif math.abs(playerX - 674) <= 15 and math.abs(playerY - 322) <= playerSpeed then
                            gameState = "MAP"; currentRoom = nil; playerX = 563; playerY = 304 - 12
                        else
                            local leftRoom = checkRoomTransitions(playerX, playerY)
                            if not leftRoom then currentRoom = nil; gameState = "MAP" end
                        end
                    elseif currentRoom.name == "Kitchen" then
                        if math.abs(playerX - 744) <= 15 and math.abs(playerY - 584) <= (playerSpeed + 2) then
                            gameState = "MAP"; currentRoom = nil; playerX = 617; playerY = 565 - 12
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
end -- Close Exit Logic block
end -- Close Moved block
end -- Close Movement check block
cameraX = playerX - (SCREEN_WIDTH / 2) + (playerSize / 2)
if cameraX < 0 then cameraX = 0
elseif cameraX > (MAP_WIDTH - SCREEN_WIDTH) then cameraX = MAP_WIDTH - SCREEN_WIDTH end
cameraY = playerY - (SCREEN_HEIGHT / 2) + (playerSize / 2)
if cameraY < 0 then cameraY = 0
elseif cameraY > (MAP_HEIGHT - SCREEN_HEIGHT) then cameraY = MAP_HEIGHT - SCREEN_HEIGHT end
end -- Close Main game block
end -- Close handleDpadInput function
local function handleCrankInput()
    -- 1. If the crank is docked, always drop back to the standard map view
    if playdate.isCrankDocked() then
        if gameState == "MAP_FULL" then gameState = "MAP" end
        return
    end
    
    -- 2. LOCKOUT RIGID STATE CHECKER
    -- Only allow the crank to toggle the full-screen map if the player is explicitly
    -- on the main map. If they are in the NOTEPAD or ROOM_VIEW, the crank is ignored.
    if gameState == "MAP" or gameState == "MAP_FULL" then
        local crankChange = playdate.getCrankChange()
        if crankChange > 2 then 
            gameState = "MAP_FULL"
        elseif crankChange < -2 then 
            gameState = "MAP" 
        end
    end
end
-- ==========================================================
-- MAIN ENGINE UPDATE LOOP (KEEP AT THE VERY BOTTOM OF FILE)
-- ==========================================================
function playdate.update()
gfx.clear()
-- Process calculations
handleDpadInput()
handleCrankInput()
-- Global scale initializer
playdate.display.setScale(1)
-- State Rendering Routers
    if gameState == "MAP" then
        if roomBackgrounds.mansion then
            roomBackgrounds.mansion:draw(-cameraX, -cameraY)
        end
        
        -- DRAW SPRITE ON THE MAIN MAP (Using global camera offsets)
        if playerSpriteImage then
            playerSpriteImage:draw(playerX - cameraX, playerY - cameraY)
        else
            -- Backup safety circle if asset fails to load
            gfx.setColor(gfx.kColorWhite)
            gfx.fillEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
        end
-- Bottom HUD bar
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
            -- 1. Draw the centered background board image
            local boardWidth, boardHeight = roomBackgrounds.board:getSize()
            local centeredX = (SCREEN_WIDTH - boardWidth) / 2
            local centeredY = (SCREEN_HEIGHT - boardHeight) / 2
            roomBackgrounds.board:draw(centeredX, centeredY)
            
            -- 2. Calculate player percentage position across the 800x800 world map
            local percentX = playerX / MAP_WIDTH
            local percentY = playerY / MAP_HEIGHT
            
            -- 3. Translate that percentage to the mini-map size, adding the screen centering offsets
            -- We center the tracking point by subtracting half the player size (6px)
            local targetX = centeredX + (percentX * boardWidth) - (playerSize / 2)
            local targetY = centeredY + (percentY * boardHeight) - (playerSize / 2)
            
            -- 4. Draw a flashing or distinct location target marker
            -- Using playdate.getElapsedTime() creates a clean, automatic blinking effect
            if math.floor(playdate.getElapsedTime() * 4) % 2 == 0 then
                -- Inner white core dot
                gfx.setColor(gfx.kColorWhite)
                gfx.fillEllipseInRect(targetX, targetY, playerSize, playerSize)
                -- Outer black crosshair ring
                gfx.setColor(gfx.kColorBlack)
                gfx.drawEllipseInRect(targetX - 2, targetY - 2, playerSize + 4, playerSize + 4)
            else
                -- Off-flash phase: solid black point for visibility
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
        
        local localPlayerX = 200
        local localPlayerY = 120
        if currentRoom then
            localPlayerX = playerX - currentRoom.x
            localPlayerY = (playerY - currentRoom.y) + 20
        end
        
        -- DRAW SPRITE INSIDE ROOM VIEW (Using localized room view calculations)
        if playerSpriteImage then
            playerSpriteImage:draw(localPlayerX, localPlayerY)
        else
            -- Backup safety circle if asset fails to load
            gfx.setColor(gfx.kColorWhite)
            gfx.fillEllipseInRect(localPlayerX, localPlayerY, playerSize, playerSize)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawEllipseInRect(localPlayerX, localPlayerY, playerSize, playerSize)
        end
-- Top Room HUD
gfx.setColor(gfx.kColorBlack)
gfx.fillRect(0, 0, SCREEN_WIDTH, 20)
gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
gfx.drawText(string.format("STEPS: %i | ACCUSATIONS: %i", playerTilesLeft, totalAccusationsLeft), 10, 2)
-- Bottom Room HUD
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
end
end
