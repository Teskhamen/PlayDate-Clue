-- global.lua
gfx = playdate.graphics

-- Configuration Constants
SCREEN_WIDTH = 400
SCREEN_HEIGHT = 240
MAP_WIDTH = 800
MAP_HEIGHT = 800
CRANK_THRESHOLD = 30
NOTEPAD_CRANK_THRESHOLD = 25

-- Game State Variables
gameState = "TITLE" 
totalAccusationsLeft = 4
playerTilesLeft = 1000 
pixelRemainder = 0       
currentRoom = nil
stateBeforePause = "MAP"
stateBeforeNotepad = "MAP"

-- Input Tracking
crankTicks = 0
notepadCrankTicks = 0
tutorialScrollY = 0
tutorialMaxScroll = 240 

-- Notebook & Dialogue State
dynamicKillers = {}
dynamicWeapons = {}
dynamicRooms   = {}
caseFile = { killer = "", weapon = "", room = "" }
checklist = {}
activeSpeaker = ""
dialogueText = ""

-- Accusation Indices
accuseWeaponIndex = 1
accuseRoomIndex = 1
finalAccuseWeapon = ""
finalAccuseRoom = ""

-- Player Tracking
playerX = 0
playerY = 0
playerSize = 12 
playerSpeed = 3          
cameraX = 0
cameraY = 0
selectedIndex = 2 
scrollOffset = 0

-- Layout Configurations
innerRoomSafeSpots = {
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

startingSpawns = {
    { x = 734, y = 247 }, { x = 734, y = 538 },
    { x = 470, y = 742 }, { x = 323, y = 742 },
    { x = 56,  y = 568 }, { x = 56,  y = 190 },
    { x = 266, y = 49  }, { x = 527, y = 49  }
}
