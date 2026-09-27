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
tutorialScrollY = math.max(0, tutorialScrollY - (crankChange * 0.8))
if tutorialScrollY < 0 then tutorialScrollY = 0 end
if tutorialScrollY > tutorialMaxScroll then tutorialScrollY = tutorialMaxScroll end
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
if gameState == "PAUSE" then
return
end
if gameState == "GAME_OVER" then
if gameMusic then gameMusic:stop() end
resetGameEngine()
gameState = "TITLE"
return
end
if gameState == "TITLE" then
gameState = "TUTORIAL"
return
end
if gameState == "TUTORIAL" then
if titleMusic then titleMusic:stop() end
if gameMusic and not gameMusic:isPlaying() then
gameMusic:play(0)
end
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
playdate.display.setScale(1)
function playdate.update()
playdate.graphics.clear()
handleDpadInput()
handleCrankInput()
if gameState == "TITLE" then
if titleMusic and not titleMusic:isPlaying() then
titleMusic:play(0)
end
if titleImage then
titleImage:draw(0, 0)
else
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawTextAligned("MANSION MURDER MYSTERY", SCREEN_WIDTH / 2, 80, playdate.graphics.kTextAlignmentCenter)
end
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
playdate.graphics.drawTextAligned("Press (A) to start", SCREEN_WIDTH / 3, SCREEN_HEIGHT - 45, playdate.graphics.kTextAlignmentCenter)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
elseif gameState == "TUTORIAL" then
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawTextAligned("TUTORIAL", SCREEN_WIDTH / 2, 16, playdate.graphics.kTextAlignmentCenter)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.fillRect(20, 36, SCREEN_WIDTH - 40, 1)
playdate.graphics.setClipRect(20, 44, SCREEN_WIDTH - 40, 144)
local drawY = 48 - tutorialScrollY
playdate.graphics.drawText("MISSION OBJECTIVE:", 24, drawY)
playdate.graphics.drawText("Find the hidden combination of Killer, Weapon,", 24, drawY + 18)
playdate.graphics.drawText("and Room sealed inside the secret envelope.", 24, drawY + 34)
playdate.graphics.drawText("STEP BUDGET:", 24, drawY + 68)
playdate.graphics.drawText("You begin with 1000 steps. Moving subtracts", 24, drawY + 86)
playdate.graphics.drawText("steps from your pool automatically.", 24, drawY + 102)
playdate.graphics.drawText("If steps hit 0 before you solve it, you lose!", 24, drawY + 118)
playdate.graphics.drawText("INVESTIGATION CONTROLS:", 24, drawY + 152)
playdate.graphics.drawText("- D-Pad: Move character through corridors.", 24, drawY + 170)
playdate.graphics.drawText("- Crank: Turn crank to open the Full Map", 24, drawY + 186)
playdate.graphics.drawText(" and scroll through the Notebook checklist.", 24, drawY + 202)
playdate.graphics.drawText("- (B) Button: Open/Close your Notepad log.", 24, drawY + 218)
playdate.graphics.drawText("- (A) Button: Confirm choices or accuse.", 24, drawY + 234)
playdate.graphics.drawText("DETECTION TIPS:", 24, drawY + 268)
playdate.graphics.drawText("Walk up to suspects inside rooms. They will", 24, drawY + 286)
playdate.graphics.drawText("show you structural clues to automatically", 24, drawY + 302)
playdate.graphics.drawText("cross proven false entries off your notepad.", 24, drawY + 318)
playdate.graphics.clearClipRect()
playdate.graphics.fillRect(20, 194, SCREEN_WIDTH - 40, 1)
if math.floor(playdate.getElapsedTime() * 3) % 2 == 0 then
playdate.graphics.drawTextAligned("PRESS (A) TO START", SCREEN_WIDTH / 3, 206, playdate.graphics.kTextAlignmentCenter)
end
local scrollPercentage = tutorialScrollY / tutorialMaxScroll
local barY = 44 + (scrollPercentage * 125)
playdate.graphics.fillRect(SCREEN_WIDTH - 16, barY, 3, 14)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
elseif gameState == "MAP" then
if roomBackgrounds.mansion then
roomBackgrounds.mansion:draw(-cameraX, -cameraY)
end
if playerSpriteImage then
playerSpriteImage:draw(playerX - cameraX, playerY - cameraY)
else
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.fillEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.drawEllipseInRect(playerX - cameraX, playerY - cameraY, playerSize, playerSize)
end
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(0, 0, SCREEN_WIDTH, 20)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawText(string.format("STEPS: %i | ACCUSATIONS: %i", playerTilesLeft, totalAccusationsLeft), 10, 2)
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(0, SCREEN_HEIGHT - 20, SCREEN_WIDTH, 20)
local roomString = "Path"
if currentRoom then
roomString = string.format("Room: %s", currentRoom.name)
elseif playerTilesLeft == 0 then
roomString = "OUT OF STEPS!"
end
local bottomHudText = string.format("%s | X: %i, Y: %i", roomString, playerX, playerY)
playdate.graphics.drawText(bottomHudText, 10, SCREEN_HEIGHT - 18)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
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
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.fillEllipseInRect(targetX, targetY, playerSize / 2, playerSize / 2)
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.drawEllipseInRect(targetX - 2, targetY - 2, playerSize + 4, playerSize + 4)
else
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillEllipseInRect(targetX, targetY, playerSize / 2, playerSize / 2)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.drawEllipseInRect(targetX, targetY, playerSize / 2, playerSize / 2)
end
end
elseif gameState == "ROOM_VIEW" then
if currentRoom and currentRoom.img then
currentRoom.img:draw(0, 20)
else
playdate.graphics.drawText("Error: Room asset missing!", 20, 20)
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
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillEllipseInRect(localSuspectX, localSuspectY, playerSize, playerSize)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.drawEllipseInRect(localSuspectX, localSuspectY, playerSize, playerSize)
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
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.fillEllipseInRect(localPlayerX, localPlayerY, playerSize, playerSize)
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.drawEllipseInRect(localPlayerX, localPlayerY, playerSize, playerSize)
end
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(0, 0, SCREEN_WIDTH, 20)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawText(string.format("STEPS: %i | ACCUSATIONS: %i", playerTilesLeft, totalAccusationsLeft), 10, 2)
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(0, SCREEN_HEIGHT - 20, SCREEN_WIDTH, 20)
local roomName = currentRoom and currentRoom.name or "Unknown"
local debugText = string.format("%s | World: %i,%i | Room: %i,%i", roomName, playerX, playerY, localPlayerX, localPlayerY - 20)
playdate.graphics.drawText(debugText, 6, SCREEN_HEIGHT - 18)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
elseif gameState == "NOTEPAD" then
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.drawText("DETECTIVE NOTEPAD", 125, 8)
playdate.graphics.drawLine(20, 24, 380, 24)
local maxRows = 8
for i = 1, maxRows do
local itemIndex = i + scrollOffset
if itemIndex <= #checklist then
local currentY = 32 + ((i - 1) * 22)
local item = checklist[itemIndex]
if item.isHeader then
playdate.graphics.drawText(item.category, 120, currentY)
else
if itemIndex == selectedIndex then
playdate.graphics.drawText("->", 15, currentY)
end
playdate.graphics.drawRect(45, currentY + 2, 11, 11)
if item.checked then
playdate.graphics.drawText("X", 47, currentY - 1)
playdate.graphics.drawLine(65, currentY + 7, 300, currentY + 7)
end
playdate.graphics.drawText(item.name, 65, currentY)
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
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.fillRect(15, SCREEN_HEIGHT - 75, SCREEN_WIDTH - 30, 60)
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.drawRect(15, SCREEN_HEIGHT - 75, SCREEN_WIDTH - 30, 60)
playdate.graphics.drawRect(17, SCREEN_HEIGHT - 73, SCREEN_WIDTH - 34, 56)
playdate.graphics.drawText(activeSpeaker:upper(), 25, SCREEN_HEIGHT - 70)
playdate.graphics.drawTextInRect(dialogueText, 25, SCREEN_HEIGHT - 52, SCREEN_WIDTH - 50, 35, 0, playdate.graphics.kTextAlignLeft)
if math.floor(playdate.getElapsedTime() * 3) % 2 == 0 then
playdate.graphics.drawText("(B) BACK", SCREEN_WIDTH - 375, SCREEN_HEIGHT - 35)
if not isCrossedOff(activeSpeaker) then
playdate.graphics.drawText("(A) ACCUSE", SCREEN_WIDTH - 110, SCREEN_HEIGHT - 35)
end
end
elseif gameState == "ACCUSE_CONFIRM" then
if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(20, 40, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 80)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.drawRect(20, 40, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 80)
playdate.graphics.drawRect(22, 42, SCREEN_WIDTH - 44, SCREEN_HEIGHT - 84)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawText("CRITICAL ACCUSATION PROMPT", 100, 55)
playdate.graphics.drawLine(40, 75, 360, 75)
local linesText = string.format("Are you absolutely sure you want to formally accuse %s of committing the crime?", activeSpeaker:upper())
playdate.graphics.drawTextInRect(linesText, 40, 95, SCREEN_WIDTH - 80, 50, 0, playdate.graphics.kTextAlignCenter)
playdate.graphics.drawText("(A) CONFIRM SUSPECT", SCREEN_WIDTH - 200, SCREEN_HEIGHT - 70)
playdate.graphics.drawText("(B) CANCEL", SCREEN_WIDTH - 360, SCREEN_HEIGHT - 70)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
elseif gameState == "ACCUSE_WEAPON" then
if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(30, 30, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 60)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.drawRect(30, 30, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 60)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawText("SELECT MURDER WEAPON", 110, 40)
playdate.graphics.drawLine(45, 58, 355, 58)
for i = 1, #dynamicWeapons do
local currentY = 65 + ((i - 1) * 18)
if i == accuseWeaponIndex then
playdate.graphics.drawText("-> " .. dynamicWeapons[i]:upper(), 130, currentY)
else
playdate.graphics.drawText(dynamicWeapons[i], 150, currentY)
end
end
playdate.graphics.drawText("(A) CONFIRM WEAPON", SCREEN_WIDTH - 205, SCREEN_HEIGHT - 52)
playdate.graphics.drawText("(B) GO BACK", SCREEN_WIDTH - 355, SCREEN_HEIGHT - 52)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
elseif gameState == "ACCUSE_ROOM" then
if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(30, 22, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 44)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.drawRect(30, 22, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 44)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawText("SELECT CRIME SCENE", 110, 28)
playdate.graphics.drawLine(45, 44, 355, 44)
for i = 1, #dynamicRooms do
local currentY = 48 + ((i - 1) * 15)
if i == accuseRoomIndex then
playdate.graphics.drawText("-> " .. dynamicRooms[i]:upper(), 110, currentY)
else
playdate.graphics.drawText(dynamicRooms[i], 130, currentY)
end
end
playdate.graphics.drawText("(A) CONFIRM ROOM", SCREEN_WIDTH - 185, SCREEN_HEIGHT - 42)
playdate.graphics.drawText("(B) GO BACK", SCREEN_WIDTH - 355, SCREEN_HEIGHT - 42)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
elseif gameState == "ACCUSE_SUMMARY" then
if currentRoom and currentRoom.img then currentRoom.img:draw(0, 20) end
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(20, 35, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 70)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.drawRect(20, 35, SCREEN_WIDTH - 40, SCREEN_HEIGHT - 70)
playdate.graphics.drawRect(22, 37, SCREEN_WIDTH - 44, SCREEN_HEIGHT - 74)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawText("FINAL ACCUSATION", 105, 45)
playdate.graphics.drawLine(40, 65, 360, 65)
playdate.graphics.drawText("SUSPECT : " .. activeSpeaker:upper(), 60, 85)
playdate.graphics.drawText("WEAPON : " .. finalAccuseWeapon:upper(), 60, 110)
playdate.graphics.drawText("ROOM : " .. finalAccuseRoom:upper(), 60, 135)
playdate.graphics.drawText("(A) ACCUSE!", SCREEN_WIDTH - 135, SCREEN_HEIGHT - 60)
playdate.graphics.drawText("(B) GO BACK", SCREEN_WIDTH - 350, SCREEN_HEIGHT - 60)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
elseif gameState == "REVEAL_ENVELOPE" then
if currentRoom and currentRoom.img then
currentRoom.img:draw(0, 20)
elseif roomBackgrounds.mansion then
roomBackgrounds.mansion:draw(-cameraX, -cameraY)
end
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(30, 25, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 50)
playdate.graphics.setColor(playdate.graphics.kColorWhite)
playdate.graphics.drawRect(30, 25, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 50)
playdate.graphics.drawRect(32, 27, SCREEN_WIDTH - 64, SCREEN_HEIGHT - 54)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawText("TOP SECRET CASE FILE", 115, 38)
playdate.graphics.drawLine(45, 56, 355, 56)
playdate.graphics.drawText("KILLER : " .. caseFile.killer:upper(), 60, 75)
playdate.graphics.drawText("WEAPON : " .. caseFile.weapon:upper(), 60, 105)
playdate.graphics.drawText("ROOM : " .. caseFile.room:upper(), 60, 135)
playdate.graphics.drawLine(45, 170, 355, 170)
playdate.graphics.drawText("PRESS (A) TO CLOSE CASE ENVELOPE", 65, 185)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
elseif gameState == "GAME_OVER" then
if gameOverImage then
gameOverImage:draw(0, 0)
else
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawTextAligned("INVESTIGATION CONCLUDED", SCREEN_WIDTH / 2, 80, playdate.graphics.kTextAlignmentCenter)
end
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
playdate.graphics.drawTextAligned("(A) Play Again", SCREEN_WIDTH / 5, 190, playdate.graphics.kTextAlignmentCenter)
elseif gameState == "PAUSE" then
if pauseImage then
pauseImage:draw(0, 0)
playdate.graphics.drawTextAligned("Press (B) to Resume", SCREEN_WIDTH / 3.3, SCREEN_HEIGHT - 45, playdate.graphics.kTextAlignmentCenter)
else
playdate.graphics.setColor(playdate.graphics.kColorBlack)
playdate.graphics.fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
playdate.graphics.drawTextAligned("GAME PAUSED", SCREEN_WIDTH / 2, 100, playdate.graphics.kTextAlignmentCenter)
playdate.graphics.drawTextAligned("Press (B) to Resume", SCREEN_WIDTH / 2, 140, playdate.graphics.kTextAlignmentCenter)
end
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
end
end
