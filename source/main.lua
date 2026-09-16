import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics

-- Simplified States & Variables
local gameState = "MAP" 
local totalAccusationsLeft = 4
local playerTilesLeft = 200 

local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240

-- Track actual dimensions of your 800x800 Big_Map asset
local MAP_WIDTH <const> = 800
local MAP_HEIGHT <const> = 800

-- Load your mask layout safely
local maskImage = gfx.image.new("images/map_mask")
if not maskImage then
    print("Warning: Could not load images/map_mask.png")
end

-- ==========================================================
-- ROOM ASSETS & ASSET SIZE OFFSET CALCULATORS
-- ==========================================================
-- Pre-load your room background assets
local roomBackgrounds = {
    mansion  = gfx.image.new("images/Big_Map"), -- Your 800x800 gameplay board asset
    ballroom = gfx.image.new("images/Ball_Room"), 
    conservatory   = gfx.image.new("images/Conservatory"),    
    dining   = gfx.image.new("images/Dining_Room"),    
    game   = gfx.image.new("images/Game_Room"),    
    hall   = gfx.image.new("images/Hall"),    
    kitchen   = gfx.image.new("images/Kitchen"),    
    library   = gfx.image.new("images/Library"),    
    lounge   = gfx.image.new("images/Lounge"),    
    study   = gfx.image.new("images/Study"),    
    board   = gfx.image.new("images/Map_Full")    -- Your static, 200x200 board reference image
}

-- Definitive coordinate layout matching your map dimensions
local rooms = {
    { name = "Ballroom",      x = 50,  y = 200, w = 100, h = 80,  img = roomBackgrounds.ballroom },
    { name = "Dining Room",   x = 10,  y = 20,  w = 80,  h = 60,  img = roomBackgrounds.dining }
}

-- Simulated Player Position & Dimensions
local playerX = 500
local playerY = 400
local playerSize = 12 
local playerStepDistance = 16 
local currentRoom = nil

-- Full 2D Camera Tracking offsets
local cameraX = 0
local cameraY = 0

-- Helper function to check if a pixel coordinate is walkable (Black = Walkable)
local function isWalkable(x, y)
    -- Safe boundary fallback: if image failed to load, don't crash, let player move
    if not maskImage then return true end
    
    -- Get exact dimensions of your mask file dynamically
    local maskW, maskH = maskImage:getSize()
    
    -- Crucial Fix: Force numbers to whole integers and clamp them safely inside the image size
    local checkX = math.max(0, math.min(maskW - 1, math.floor(x)))
    local checkY = math.max(0, math.min(maskH - 1, math.floor(y)))
    
    -- Safe to sample now without breaking the frame rendering sequence
    local color = maskImage:sample(checkX, checkY)
    
    -- Black is Walkable, White is a wall
    return color == gfx.kColorBlack
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

-- Completely flat Input Listeners
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

-- Flat navigation logic with Header Skipping
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
        
    -- Map Navigation Controls
    elseif gameState == "MAP" then
        local dx, dy = 0, 0
        
        if playerTilesLeft > 0 then
            if playdate.buttonJustPressed(playdate.kButtonUp) then dy = -playerStepDistance end
            if playdate.buttonJustPressed(playdate.kButtonDown) then dy = playerStepDistance end
            if playdate.buttonJustPressed(playdate.kButtonLeft) then dx = -playerStepDistance end
            if playdate.buttonJustPressed(playdate.kButtonRight) then dx = playerStepDistance end
        end
        
        if dx ~= 0 or dy ~= 0 then
            local targetX = playerX + dx
            local targetY = playerY + dy
            local moved = false
            
            -- Test target position on mask
            if isWalkable(targetX + (playerSize / 2), targetY + (playerSize / 2)) then
                if targetX >= 0 and targetX <= MAP_WIDTH - playerSize then
                    playerX = targetX
                    moved = true
                end
                if targetY >= 0 and targetY <= MAP_HEIGHT - playerSize then
                    playerY = targetY
                    moved = true
                end
            else
                print("Step blocked by mask alignment logic!")
            end
            
            if moved then
                playerTilesLeft = playerTilesLeft - 1
            end
            
            currentRoom = checkRoomTransitions(playerX, playerY)
        end
        
        -- Dynamic 2D camera viewport balancing math
        cameraX = playerX - (SCREEN_WIDTH / 2)
        if cameraX < 0 then 
            cameraX = 0 
        elseif cameraX > (MAP_WIDTH - SCREEN_WIDTH) then 
            cameraX = MAP_WIDTH - SCREEN_WIDTH 
        end

        cameraY = playerY - (SCREEN_HEIGHT / 2)
        if cameraY < 0 then 
            cameraY = 0 
        elseif cameraY > (MAP_HEIGHT - SCREEN_HEIGHT) then 
            cameraY = MAP_HEIGHT - SCREEN_HEIGHT 
        end
    end
end

-- Watch crank rotation to trigger state alterations dynamically
local function handleCrankInput()
    if playdate.isCrankDocked() then
        if gameState == "MAP_FULL" then
            gameState = "MAP"
        end
        return
    end

    if gameState ~= "NOTEPAD" then
        local crankChange = playdate.getCrankChange()
        
        if crankChange > 2 then
            gameState = "MAP_FULL"
        elseif crankChange < -2 then
            gameState = "MAP"
        end
    end
end

-- Main Draw Loop
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
        
        if currentRoom then
            gfx.drawText(string.format("Room: %s", currentRoom.name), 10, 25)
        else
            if playerTilesLeft == 0 then
                gfx.drawText("OUT OF STEPS!", 10, 25)
            end
        end
        
        gfx.fillRect(0, 0, SCREEN_WIDTH, 20)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText(string.format("STEPS: %i   |   ACCUSATIONS: %i", playerTilesLeft, totalAccusationsLeft), 10, 2)
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


