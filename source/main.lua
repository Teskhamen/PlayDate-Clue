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
    print("Warning: Could not load images/Mask_Map.png")
end

-- ==========================================================
-- ROOM ASSETS & ASSET SIZE OFFSET CALCULATORS
-- ==========================================================
local roomBackgrounds = {
    mansion  = gfx.image.new("images/Big_Map"), 
    ballroom = gfx.image.new("images/Ball_Room"), 
    conservatory   = gfx.image.new("images/Conservatory"),    
    dining   = gfx.image.new("images/Dining_Room"),    
    game   = gfx.image.new("images/Game_Room"),    
    hall   = gfx.image.new("images/Hall"),    
    kitchen   = gfx.image.new("images/Kitchen"),    
    library   = gfx.image.new("images/Library"),    
    lounge   = gfx.image.new("images/Lounge"),    
    study   = gfx.image.new("images/Study"),    
    board   = gfx.image.new("images/Map_Full")    
}

-- Definitive coordinate layout matching your 800x800 map dimensions
local rooms = {
    -- Top Row Rooms
    { name = "Study",          x = 215,   y = 121,   w = 186, h = 99, img = roomBackgrounds.study },
    { name = "Hall",           x = 395,  y = 157,   w = 144, h = 165, img = roomBackgrounds.hall },
    { name = "Lounge",         x = 569,  y = 192,   w = 183, h = 150, img = roomBackgrounds.lounge },
    
    -- Middle Row Rooms
    { name = "Library",        x = 164,   y = 271,  w = 186, h = 108, img = roomBackgrounds.library },
    { name = "Game Room",      x = 128,  y = 448,  w = 156, h = 126, img = roomBackgrounds.game },
    { name = "Dining Room",    x = 554,  y = 382,  w = 210, h = 177, img = roomBackgrounds.dining },
    
    -- Bottom Row Rooms
    { name = "Conservatory",   x = 176,   y = 616,  w = 159, h = 126, img = roomBackgrounds.conservatory },
    { name = "Ballroom",       x = 310,  y = 580,  w = 271, h = 147, img = roomBackgrounds.ballroom },
    { name = "Kitchen",        x = 623,  y = 577,  w = 150, h = 153, img = roomBackgrounds.kitchen }
}

-- Simulated Player Position & Dimensions
local playerX = 500 
local playerY = 400
local playerSize = 12 
local playerSpeed = 3          -- Moves 3 pixels per frame while holding a button
local pixelRemainder = 0       -- Tracks smooth distance to deduct from your Steps counter
local currentRoom = nil

-- Full 2D Camera Tracking offsets
local cameraX = 0
local cameraY = 0

-- Helper function to check if a pixel coordinate is walkable
local function isWalkable(x, y)
    if not maskImage then return true end
    
    local maskW, maskH = maskImage:getSize()
    
    -- Check all 4 outer edges of your player token plus the center
    local points = {
        {x = x, y = y},
        {x = x + playerSize - 1, y = y},
        {x = x, y = y + playerSize - 1},
        {x = x + playerSize - 1, y = y + playerSize - 1},
        {x = x + (playerSize / 2), y = y + (playerSize / 2)}
    }
    
    for _, pt in ipairs(points) do
        local checkX = math.max(0, math.min(maskW - 1, math.floor(pt.x)))
        local checkY = math.max(0, math.min(maskH - 1, math.floor(pt.y)))
        
        local color = maskImage:sample(checkX, checkY)
        
        -- FIXED CONSTANT: Checks for white walls explicitly
        if color == gfx.image.kColorWhite or color == 1 then
            return false 
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
    if gameState == "NOTEPAD" or gameState == "MAP_FULL" then
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

        if selectedIndex - scrollOffset > 7 then
            scrollOffset = selectedIndex - 7
        elseif selectedIndex - scrollOffset < 2 then
            scrollOffset = math.max(0, selectedIndex - 2)
        end
        
    elseif gameState == "MAP" then
        local dx, dy = 0, 0
        local buttonPressedThisFrame = false
        
        -- 1. Check if a button was JUST tapped this frame (Guarantees responsive single taps)
        if playdate.buttonJustPressed(playdate.kButtonUp) or
           playdate.buttonJustPressed(playdate.kButtonDown) or
           playdate.buttonJustPressed(playdate.kButtonLeft) or
           playdate.buttonJustPressed(playdate.kButtonRight) then
               buttonPressedThisFrame = true
        end
        
        -- 2. Regular smooth continuous checking
        if playerTilesLeft > 0 then
            if playdate.buttonIsPressed(playdate.kButtonUp)    then dy = -playerSpeed end
            if playdate.buttonIsPressed(playdate.kButtonDown)  then dy = playerSpeed end
            if playdate.buttonIsPressed(playdate.kButtonLeft)  then dx = -playerSpeed end
            if playdate.buttonIsPressed(playdate.kButtonRight) then dx = playerSpeed end
        end
        
        if dx ~= 0 or dy ~= 0 then
            local moved = false
            
            -- Try moving on X axis
            if dx ~= 0 then
                local targetX = playerX + dx
                if targetX >= 0 and targetX <= (MAP_WIDTH - playerSize) then
                    if isWalkable(targetX, playerY) then
                        playerX = targetX
                        moved = true
                    end
                end
            end
            
            -- Try moving on Y axis
            if dy ~= 0 then
                local targetY = playerY + dy
                if targetY >= 0 and targetY <= (MAP_HEIGHT - playerSize) then
                    if isWalkable(playerX, targetY) then
                        playerY = targetY
                        moved = true
                    end
                end
            end
            
            -- 3. SMART STEP TRACKING
            if moved then
                if buttonPressedThisFrame then
                    -- If they just tapped the button, instantly take a step away and reset the tracker
                    playerTilesLeft = playerTilesLeft - 1
                    pixelRemainder = 0
                else
                    -- If they are holding it down, accumulate pixels normally
                    pixelRemainder = pixelRemainder + playerSpeed
                    if pixelRemainder >= 16 then
                        playerTilesLeft = playerTilesLeft - 1
                        pixelRemainder = pixelRemainder - 16
                    end
                end
                
                currentRoom = checkRoomTransitions(playerX, playerY)
            end
        end
        
        -- Dynamic Camera Tracking
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
        
        -- Draws the player circle securely relative to the fixed camera view
        gfx.setColor(gfx.kColorWhite)
        gfx.fillEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
        
        -- TOP BAR HUD: Steps and Accusations
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, SCREEN_WIDTH, 20)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(string.format("STEPS: %i   |   ACCUSATIONS: %i", playerTilesLeft, totalAccusationsLeft), 10, 2)
        
        -- DEV DEBUGGER: Coordinates displayed just under top bar
        --gfx.drawText(string.format("X: %i, Y: %i", playerX, playerY), 10, 24)
        
        -- BOTTOM BAR HUD: 20px high black bar across the 400px wide screen
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, SCREEN_HEIGHT - 20, SCREEN_WIDTH, 20)
        
        -- Generate the room name string
        local roomString = "Path"
        if currentRoom then
            roomString = string.format("Room: %s", currentRoom.name)
        elseif playerTilesLeft == 0 then
            roomString = "OUT OF STEPS!"
        end
        
        -- Merge room name and precise coordinates into one text string
        local bottomHudText = string.format("%s   |   X: %i, Y: %i", roomString, playerX, playerY)
        
        -- Draw the combined tracking text inside the bottom bar
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(bottomHudText, 10, SCREEN_HEIGHT - 18)
        
        -- Reset draw mode back to standard copy for the next frame iteration
        gfx.setImageDrawMode(gfx.kDrawModeCopy)

    elseif gameState == "MAP_FULL" then
        if roomBackgrounds.board then
            local boardWidth, boardHeight = roomBackgrounds.board:getSize()
            local centeredX = (SCREEN_WIDTH - boardWidth) / 2
            local centeredY = (SCREEN_HEIGHT - boardHeight) / 2
            roomBackgrounds.board:draw(centeredX, centeredY)
        end
    end

    if gameState == "NOTEPAD" then
        gfx.drawText("*DETECTIVE NOTEPAD*", 125, 8)
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