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
    { name = "Dining Room",  x = 530, y = 304, w = 400, h = 200, img = roomBackgrounds.dining,       mask = roomBackgrounds.diningRoomMask },
    
    -- Bottom Row Rooms
    { name = "Conservatory", x = 50,  y = 598, w = 159, h = 126, img = roomBackgrounds.conservatory, mask = roomBackgrounds.conservatoryMask },
    { name = "Ballroom",     x = 296, y = 541, w = 201, h = 144, img = roomBackgrounds.ballroom,     mask = roomBackgrounds.ballRoomMask },
    { name = "Kitchen",      x = 590, y = 568, w = 150, h = 153, img = roomBackgrounds.kitchen,      mask = roomBackgrounds.kitchenMask }
}

-- ==========================================================
-- RUNTIME INVERTED COLLISION MASK GENERATOR 
-- ==========================================================
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

-- Simulated Player Position & Dimensions
local playerX = 500 
local playerY = 400
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
        -- FIX: Use custom mask dimensions if they exist, otherwise fallback to image size
        local maskW = currentRoom.maskW or currentRoom.runtimeMask:getSize()
        local maskH = currentRoom.maskH or select(2, currentRoom.runtimeMask:getSize())
        
        for _, pt in ipairs(points) do
            local localX = math.floor(pt.x - currentRoom.x)
            local localY = math.floor(pt.y - currentRoom.y)
            
            -- Keep player strictly inside your custom ROOM_VIEW boundaries
            if localX < 0 or localX >= maskW or localY < 0 or localY >= maskH then
                return false -- Soft block at the custom dimensions
            else
                local color = currentRoom.runtimeMask:sample(localX, localY)
                if color == gfx.kColorWhite or color == 1 then
                    return false -- Hard block at visual wall stroke
                end
            end
        end
    else
        -- Default: Handle exploration collision on the main map grid
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

function playdate.BButtonDown()
    if gameState == "NOTEPAD" or gameState == "MAP_FULL" or gameState == "ROOM_VIEW" then
        if gameState == "ROOM_VIEW" then
            -- Optional safety bounce: move player backward so they don't immediately re-trigger it
        end
        gameState = "MAP"
    elseif gameState == "MAP" then
        gameState = "NOTEPAD"
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
            selectedIndex = selectedIndex - 1
            if selectedIndex < 1 then selectedIndex = #checklist end
            while checklist[selectedIndex].isHeader do
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then selectedIndex = #checklist end
            end
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            selectedIndex = selectedIndex + 1
            if selectedIndex > #checklist then selectedIndex = 1 end
            while checklist[selectedIndex].isHeader do
                selectedIndex = selectedIndex + 1
                if selectedIndex > #checklist then selectedIndex = 1 end
            end
        end
        -- DYNAMIC BOUNDARY SETUP BASED ON ENGINE STATE
        local minX, maxX, minY, maxY
        if gameState == "ROOM_VIEW" and currentRoom and currentRoom.runtimeMask then
            -- FIX: Use custom dimensions for clamping if they exist
            local maskW = currentRoom.maskW or currentRoom.runtimeMask:getSize()
            local maskH = currentRoom.maskH or select(2, currentRoom.runtimeMask:getSize())
            
            minX = currentRoom.x
            maxX = currentRoom.x + maskW - playerSize
            minY = currentRoom.y
            maxY = currentRoom.y + maskH - playerSize
        else
            -- Constrain to global map boundaries
            minX = 0
            maxX = MAP_WIDTH - playerSize
            minY = 0
            maxY = MAP_HEIGHT - playerSize
        end
        -- DYNAMIC BOUNDARY SETUP BASED ON ENGINE STATE
        local minX, maxX, minY, maxY
        if gameState == "ROOM_VIEW" and currentRoom and currentRoom.runtimeMask then
            -- FIX: Use custom dimensions for clamping if they exist
            local maskW = currentRoom.maskW or currentRoom.runtimeMask:getSize()
            local maskH = currentRoom.maskH or select(2, currentRoom.runtimeMask:getSize())
            
            minX = currentRoom.x
            maxX = currentRoom.x + maskW - playerSize
            minY = currentRoom.y
            maxY = currentRoom.y + maskH - playerSize
        else
            -- Constrain to global map boundaries
            minX = 0
            maxX = MAP_WIDTH - playerSize
            minY = 0
            maxY = MAP_HEIGHT - playerSize
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
if dx ~= 0 or dy ~= 0 then
local moved = false
if dx ~= 0 then
local targetX = playerX + dx
if targetX >= 0 and targetX <= (MAP_WIDTH - playerSize) then
if isWalkable(targetX, playerY) then
playerX = targetX
moved = true
end
end
end
if dy ~= 0 then
local targetY = playerY + dy
if targetY >= 0 and targetY <= (MAP_HEIGHT - playerSize) then
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
local newRoom = checkRoomTransitions(playerX, playerY)
if newRoom then
if newRoom ~= currentRoom then
currentRoom = newRoom
gameState = "ROOM_VIEW"
end
else
currentRoom = nil
gameState = "MAP"
end
end
end
cameraX = playerX - (SCREEN_WIDTH / 2) + (playerSize / 2)
if cameraX < 0 then cameraX = 0
elseif cameraX > (MAP_WIDTH - SCREEN_WIDTH) then cameraX = MAP_WIDTH - SCREEN_WIDTH end
cameraY = playerY - (SCREEN_HEIGHT / 2) + (playerSize / 2)
if cameraY < 0 then cameraY = 0
elseif cameraY > (MAP_HEIGHT - SCREEN_HEIGHT) then cameraY = MAP_HEIGHT - SCREEN_HEIGHT end
end
end
local function handleCrankInput()
if playdate.isCrankDocked() then
if gameState == "MAP_FULL" then gameState = "MAP" end
return
end
if gameState ~= "NOTEPAD" then
local crankChange = playdate.getCrankChange()
if crankChange > 2 then gameState = "MAP_FULL"
elseif crankChange < -2 then gameState = "MAP" end
end
end
-- ==========================================================
-- MAIN DRAW LOOP
-- ==========================================================
function playdate.update()
gfx.clear()
handleDpadInput()
handleCrankInput()
playdate.display.setScale(1)
if gameState == "MAP" then
if roomBackgrounds.mansion then
roomBackgrounds.mansion:draw(-cameraX, -cameraY)
end
gfx.setColor(gfx.kColorWhite)
gfx.fillEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
gfx.setColor(gfx.kColorBlack)
gfx.drawEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
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
gfx.setColor(gfx.kColorWhite)
gfx.fillEllipseInRect(localPlayerX, localPlayerY, playerSize, playerSize)
gfx.setColor(gfx.kColorBlack)
gfx.drawEllipseInRect(localPlayerX, localPlayerY, playerSize, playerSize)
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

