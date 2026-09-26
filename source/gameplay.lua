-- gameplay.lua

function handleDpadInput()
    if gameState == "TITLE" or gameState == "GAME_OVER" or gameState == "PAUSE" or gameState == "NOTEPAD" then
        return
    end
    if gameState == "TUTORIAL" then
        if playdate.buttonIsPressed(playdate.kButtonUp) then
            tutorialScrollY = math.max(0, tutorialScrollY - 4)
        elseif playdate.buttonIsPressed(playdate.kButtonDown) then
            tutorialScrollY = math.min(tutorialMaxScroll, tutorialScrollY + 4)
        end
        return
    end
    if gameState == "ACCUSE_WEAPON" then
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            accuseWeaponIndex = accuseWeaponIndex - 1
            if accuseWeaponIndex < 1 then accuseWeaponIndex = #dynamicWeapons end
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            accuseWeaponIndex = accuseWeaponIndex + 1
            if accuseWeaponIndex > #dynamicWeapons then accuseWeaponIndex = 1 end
        end
    elseif gameState == "ACCUSE_ROOM" then
        if playdate.buttonJustPressed(playdate.kButtonUp) then
            accuseRoomIndex = accuseRoomIndex - 1
            if accuseRoomIndex < 1 then accuseRoomIndex = #dynamicRooms end
        elseif playdate.buttonJustPressed(playdate.kButtonDown) then
            accuseRoomIndex = accuseRoomIndex + 1
            if accuseRoomIndex > #dynamicRooms then accuseRoomIndex = 1 end
        end
    elseif gameState == "MAP" or gameState == "ROOM_VIEW" then
        local dx, dy = 0, 0
        local buttonPressedThisFrame = false
        if playerTilesLeft <= 0 and gameState ~= "REVEAL_ENVELOPE" then
            gameState = "REVEAL_ENVELOPE"
            dialogueText = "GAME OVER"
            return
        end
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
                            playerX = 371; playerY = 210 - 16
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
if math.abs(playerX - 371) <= 15 and math.abs(playerY - 210) <= 15 then
gameState = "MAP"; currentRoom = nil; playerX = 233; playerY = 138 + 16
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
dialogueText = string.format("I can prove that it wasn't %s.", pickedCard:upper())
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


function handleCrankInput()
local crankChange = playdate.getCrankChange()
if gameState == "TUTORIAL" then
if not playdate.isCrankDocked() then
tutorialScrollY = math.max(0, math.min(tutorialMaxScroll, tutorialScrollY + (crankChange * 0.8)))
end
return
end
if playdate.isCrankDocked() then
if gameState == "MAP_FULL" then gameState = "MAP" end
crankTicks = 0
notepadCrankTicks = 0
return
end
if gameState == "NOTEPAD" then
notepadCrankTicks = notepadCrankTicks + crankChange
if notepadCrankTicks > NOTEPAD_CRANK_THRESHOLD then
local nextIndex = selectedIndex
local found = false
while nextIndex < #checklist do
nextIndex = nextIndex + 1
if not checklist[nextIndex].isHeader then
found = true
break
end
end
if found then selectedIndex = nextIndex end
notepadCrankTicks = 0
elseif notepadCrankTicks < -NOTEPAD_CRANK_THRESHOLD then
local prevIndex = selectedIndex
local found = false
while prevIndex > 1 do
prevIndex = prevIndex - 1
if not checklist[prevIndex].isHeader then
found = true
break
end
end
if found then selectedIndex = prevIndex end
notepadCrankTicks = 0
end
if selectedIndex - scrollOffset > 7 then
scrollOffset = selectedIndex - 7
elseif selectedIndex - scrollOffset < 2 then
scrollOffset = math.max(0, selectedIndex - 2)
end
elseif gameState == "MAP" or gameState == "MAP_FULL" then
crankTicks = crankTicks + crankChange
if crankTicks > CRANK_THRESHOLD then
gameState = "MAP_FULL"
crankTicks = 0
elseif crankTicks < -CRANK_THRESHOLD then
gameState = "MAP"
crankTicks = 0
end
end
end
function playdate.BButtonDown()
if gameState == "PAUSE" then
gameState = stateBeforePause
return
end
if gameState == "TITLE" or gameState == "TUTORIAL" or gameState == "GAME_OVER" then
return
end
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
notepadCrankTicks = 0
end
end
end
function playdate.AButtonDown()
if gameState == "PAUSE" then return end
if gameState == "GAME_OVER" then
resetGameEngine()
gameState = "TITLE"
return
end
if gameState == "TITLE" then
gameState = "TUTORIAL"
return
end
if gameState == "TUTORIAL" then
gameState = "MAP"
return
end
if gameState == "NOTEPAD" then
local currentItem = checklist[selectedIndex]
if currentItem and not currentItem.isHeader then
currentItem.checked = not currentItem.checked
end
elseif gameState == "DIALOGUE" then
if isCrossedOff(activeSpeaker) then
return
else
populateDynamicLists()
gameState = "ACCUSE_CONFIRM"
end
elseif gameState == "ACCUSE_CONFIRM" then
accuseWeaponIndex = 1
gameState = "ACCUSE_WEAPON"
elseif gameState == "ACCUSE_WEAPON" then
finalAccuseWeapon = dynamicWeapons[accuseWeaponIndex]
accuseRoomIndex = 1
gameState = "ACCUSE_ROOM"
elseif gameState == "ACCUSE_ROOM" then
finalAccuseRoom = dynamicRooms[accuseRoomIndex]
gameState = "ACCUSE_SUMMARY"
elseif gameState == "REVEAL_ENVELOPE" then
gameState = "GAME_OVER"
elseif gameState == "ACCUSE_SUMMARY" then
if activeSpeaker == caseFile.killer and finalAccuseWeapon == caseFile.weapon and finalAccuseRoom == caseFile.room then
dialogueText = "CORRECT! You solved the case! You found the true killer, weapon, and crime scene."
gameState = "DIALOGUE"
totalAccusationsLeft = 0
else
totalAccusationsLeft = totalAccusationsLeft - 1
if totalAccusationsLeft <= 0 then
dialogueText = string.format("WRONG! Game Over. The mystery was %s with the %s in the %s.", caseFile.killer:upper(), caseFile.weapon:upper(), caseFile.room:upper())
gameState = "DIALOGUE"
playerTilesLeft = 0
else
dialogueText = string.format("INCORRECT ACCUSATION! %i attempts remain.", totalAccusationsLeft)
gameState = "DIALOGUE"
end
end
end
end
function playdate.update()
gfx.clear()
handleDpadInput()
handleCrankInput()
if gameState == "TITLE" then
if titleImage then titleImage:draw(0, 0)
else
gfx.setColor(gfx.kColorBlack)
gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
gfx.drawTextAligned("MANSION MURDER MYSTERY", SCREEN_WIDTH / 2, 80, gfx.kTextAlignmentCenter)
end
gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
gfx.drawTextAligned("Press (A) to start", SCREEN_WIDTH / 3, SCREEN_HEIGHT - 45, gfx.kTextAlignmentCenter)
gfx.setImageDrawMode(gfx.kDrawModeCopy)
elseif gameState == "TUTORIAL" then
gfx.setColor(gfx.kColorBlack)
gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
gfx.drawTextAligned("TUTORIAL", SCREEN_WIDTH / 2, 16, gfx.kTextAlignmentCenter)
gfx.setColor(gfx.kColorWhite)
gfx.fillRect(20, 36, SCREEN_WIDTH - 40, 1)
gfx.setClipRect(20, 44, SCREEN_WIDTH - 40, 144)
local drawY = 48 - tutorialScrollY
gfx.drawText("MISSION OBJECTIVE:", 24, drawY)
gfx.drawText("Find the hidden combination of Killer, Weapon,", 24, drawY + 18)
gfx.drawText("and Room sealed inside the secret envelope.", 24, drawY + 34)
gfx.drawText("STEP BUDGET:", 24, drawY + 68)
gfx.drawText("You begin with 1000 steps. Moving subtracts", 24, drawY + 86)
gfx.drawText("steps from your pool automatically.", 24, drawY + 102)
gfx.drawText("If steps hit 0 before you solve it, you lose!", 24, drawY + 118)
gfx.drawText("INVESTIGATION CONTROLS:", 24, drawY + 152)
gfx.drawText("- D-Pad: Move character through corridors.", 24, drawY + 170)
gfx.drawText("- Crank: Turn crank to open the Full Map", 24, drawY + 186)
gfx.drawText(" and scroll through the Notebook checklist.", 24, drawY + 202)
gfx.drawText("- (B) Button: Open/Close your Notepad log.", 24, drawY + 218)
gfx.drawText("- (A) Button: Confirm choices or accuse.", 24, drawY + 234)
gfx.drawText("DETECTION TIPS:", 24, drawY + 268)
gfx.drawText("Walk up to suspects inside rooms. They will", 24, drawY + 286)
gfx.drawText("show you structural clues to automatically", 24, drawY + 302)
gfx.drawText("cross proven false entries off your notepad.", 24, drawY + 318)
gfx.clearClipRect()
gfx.fillRect(20, 194, SCREEN_WIDTH - 40, 1)
if math.floor(playdate.getElapsedTime() * 3) % 2 == 0 then
gfx.drawTextAligned("PRESS (A) TO START", SCREEN_WIDTH / 3, 206, gfx.kTextAlignmentCenter)
end
local scrollPercentage = tutorialScrollY / tutorialMaxScroll
local barY = 44 + (scrollPercentage * 125)
gfx.fillRect(SCREEN_WIDTH - 16, barY, 3, 14)
gfx.setImageDrawMode(gfx.kDrawModeCopy)
elseif gameState == "MAP" then
if roomBackgrounds.mansion then roomBackgrounds.mansion:draw(-cameraX, -cameraY) end
if playerSpriteImage then playerSpriteImage:draw(playerX - cameraX, playerY - cameraY)
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
if currentRoom then roomString = string.format("Room: %s", currentRoom.name)
elseif playerTilesLeft == 0 then roomString = "OUT OF STEPS!" end
gfx.drawText(string.format("%s | X: %i, Y: %i", roomString, playerX, playerY), 10, SCREEN_HEIGHT - 18)
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
gfx.fillEllipseInRect(targetX, targetY, playerSize / 2, playerSize / 2)
gfx.setColor(gfx.kColorBlack)
gfx.drawEllipseInRect(targetX - 2, targetY - 2, playerSize + 4, playerSize + 4)
else
gfx.setColor(gfx.kColorBlack)
gfx.fillEllipseInRect(targetX, targetY, playerSize / 2, playerSize / 2)
gfx.setColor(gfx.kColorWhite)
gfx.drawEllipseInRect(targetX, targetY, playerSize / 2, playerSize / 2)
end
end
elseif gameState == "ROOM_VIEW" then
if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20)
else gfx.drawText("Error: Room asset missing!", 20, 20) end
if currentRoom then
for i = 1, #suspects do
local suspect = suspects[i]
if suspect.assignedRoomName == currentRoom.name then
local localSuspectX = suspect.worldX - currentRoom.x
local localSuspectY = (suspect.worldY - currentRoom.y) + 20
if suspect.img then suspect.img:draw(localSuspectX, localSuspectY)
else
gfx.setColor(gfx.kColorBlack)
gfx.fillEllipseInRect(localSuspectX, localSuspectY, playerSize, playerSize)
gfx.setColor(gfx.kColorWhite)
gfx.drawEllipseInRect(localSuspectX, localSuspectY, playerSize, playerSize)
end
end
end
end
local localPlayerX = currentRoom and (playerX - currentRoom.x) or 200
local localPlayerY = currentRoom and ((playerY - currentRoom.y) + 20) or 120
if playerSpriteImage then playerSpriteImage:draw(localPlayerX, localPlayerY)
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
gfx.drawText(string.format("%s | World: %i,%i | Room: %i,%i", roomName, playerX, playerY, localPlayerX, localPlayerY - 20), 6, SCREEN_HEIGHT - 18)
gfx.setImageDrawMode(gfx.kDrawModeCopy)
elseif gameState == "NOTEPAD" then
gfx.setImageDrawMode(gfx.kDrawModeCopy)
gfx.setColor(gfx.kColorBlack)
gfx.drawText("DETECTIVE NOTEPAD", 125, 8)
gfx.drawLine(20, 24, 380, 24)
for i = 1, 8 do
local itemIndex = i + scrollOffset
if itemIndex <= #checklist then
local currentY = 32 + ((i - 1) * 22)
local item = checklist[itemIndex]
if item.isHeader then gfx.drawText(item.category, 120, currentY)
else
if itemIndex == selectedIndex then gfx.drawText("->", 15, currentY) end
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
if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
if currentRoom then
for i = 1, #suspects do
local suspect = suspects[i]
if suspect.assignedRoomName == currentRoom.name and suspect.img then
suspect.img:draw(suspect.worldX - currentRoom.x, (suspect.worldY - currentRoom.y) + 20)
end
end
end
local localPlayerX = currentRoom and (playerX - currentRoom.x) or 200
local localPlayerY = currentRoom and ((playerY - currentRoom.y) + 20) or 120
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
if not isCrossedOff(activeSpeaker) then gfx.drawText("(A) ACCUSE", SCREEN_WIDTH - 110, SCREEN_HEIGHT - 35) end
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
gfx.drawTextInRect(string.format("Are you absolutely sure you want to formally accuse %s of committing the crime?", activeSpeaker:upper()), 40, 95, SCREEN_WIDTH - 80, 50, 0, gfx.kTextAlignCenter)
gfx.drawText("(A) CONFIRM SUSPECT", SCREEN_WIDTH - 200, SCREEN_HEIGHT - 70)
gfx.drawText("(B) CANCEL", SCREEN_WIDTH - 360, SCREEN_HEIGHT - 70)
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
for i = 1, #dynamicWeapons do
local currentY = 65 + ((i - 1) * 18)
if i == accuseWeaponIndex then gfx.drawText("-> " .. dynamicWeapons[i]:upper(), 130, currentY)
else gfx.drawText(dynamicWeapons[i], 150, currentY) end
end
gfx.drawText("(A) CONFIRM WEAPON", SCREEN_WIDTH - 205, SCREEN_HEIGHT - 52)
gfx.drawText("(B) GO BACK", SCREEN_WIDTH - 355, SCREEN_HEIGHT - 52)
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
for i = 1, #dynamicRooms do
local currentY = 48 + ((i - 1) * 15)
if i == accuseRoomIndex then gfx.drawText("-> " .. dynamicRooms[i]:upper(), 110, currentY)
else gfx.drawText(dynamicRooms[i], 130, currentY) end
end
gfx.drawText("(A) CONFIRM ROOM", SCREEN_WIDTH - 185, SCREEN_HEIGHT - 42)
gfx.drawText("(B) GO BACK", SCREEN_WIDTH - 355, SCREEN_HEIGHT - 42)
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
gfx.drawText("(A) ACCUSE!", SCREEN_WIDTH - 135, SCREEN_HEIGHT - 60)
gfx.drawText("(B) GO BACK", SCREEN_WIDTH - 350, SCREEN_HEIGHT - 60)
gfx.setImageDrawMode(gfx.kDrawModeCopy)
elseif gameState == "REVEAL_ENVELOPE" then
if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20)
elseif roomBackgrounds.mansion then roomBackgrounds.mansion:draw(-cameraX, -cameraY) end
gfx.setColor(gfx.kColorBlack)
gfx.fillRect(30, 25, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 50)
gfx.setColor(gfx.kColorWhite)
gfx.drawRect(30, 25, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 50)
gfx.drawRect(32, 27, SCREEN_WIDTH - 64, SCREEN_HEIGHT - 54)
gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
gfx.drawText("TOP SECRET CASE FILE", 115, 38)
gfx.drawLine(45, 56, 355, 56)
gfx.drawText("KILLER : " .. caseFile.killer:upper(), 60, 75)
gfx.drawText("WEAPON : " .. caseFile.weapon:upper(), 60, 105)
gfx.drawText("ROOM : " .. caseFile.room:upper(), 60, 135)
gfx.drawLine(45, 170, 355, 170)
gfx.drawText("PRESS (A) TO CLOSE CASE ENVELOPE", 65, 185)
gfx.setImageDrawMode(gfx.kDrawModeCopy)
elseif gameState == "GAME_OVER" then
if gameOverImage then gameOverImage:draw(0, 0)
else
gfx.setColor(gfx.kColorBlack)
gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
gfx.drawTextAligned("INVESTIGATION CONCLUDED", SCREEN_WIDTH / 2, 80, gfx.kTextAlignmentCenter)
end
gfx.setImageDrawMode(gfx.kDrawModeCopy)
gfx.drawTextAligned("(A) Play Again", SCREEN_WIDTH / 5, 190, gfx.kTextAlignmentCenter)
elseif gameState == "PAUSE" then
if pauseImage then
pauseImage:draw(0, 0)
gfx.drawTextAligned("Press (B) to Resume", SCREEN_WIDTH / 3.3, SCREEN_HEIGHT - 45, gfx.kTextAlignmentCenter)
else
gfx.setColor(gfx.kColorBlack)
gfx.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
gfx.drawTextAligned("GAME PAUSED", SCREEN_WIDTH / 2, 100, gfx.kTextAlignmentCenter)
gfx.drawTextAligned("Press (B) to Resume", SCREEN_WIDTH / 2, 140, gfx.kTextAlignmentCenter)
end
gfx.setImageDrawMode(gfx.kDrawModeCopy)
end
end
