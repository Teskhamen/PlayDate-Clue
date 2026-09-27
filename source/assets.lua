-- assets.lua

-- Safe Loading Core Visual Assets
maskImage = gfx.image.new("images/mask_map")
if not maskImage then print("Warning: Could not load images/mask_map.png") end

playerSpriteImage = gfx.image.new("images/player")
if not playerSpriteImage then print("Warning: Could not load images/player.png") end

titleImage = gfx.image.new("images/Title_Page")
if not titleImage then print("Warning: Could not load images/Title_Page.png") end

gameOverImage = gfx.image.new("images/End_Page")
if not gameOverImage then print("Warning: Could not load images/End_Page.png") end

pauseImage = gfx.image.new("images/Pause")
if not pauseImage then print("Warning: Could not load images/Pause.png") end

roomBackgrounds = {
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

rooms = {
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
rooms.maskW = 400
rooms.maskH = 200

for i, room in ipairs(rooms) do
    if room.mask then
        room.runtimeMask = room.mask
    else
        print("Warning: Missing layout mask asset for room: " .. room.name)
    end
end

suspects = {
    { name = "Miss Scarlet",     img = gfx.image.new("images/scarlet_sprite"), hand = {} },
    { name = "Colonel Mustard",  img = gfx.image.new("images/mustard_sprite"), hand = {} },
    { name = "Mrs. White",       img = gfx.image.new("images/white_sprite"),   hand = {} },
    { name = "Mr. Green",        img = gfx.image.new("images/green_sprite"),   hand = {} },
    { name = "Mrs. Peacock",     img = gfx.image.new("images/peacock_sprite"), hand = {} },
    { name = "Professor Plum",   img = gfx.image.new("images/plum_sprite"),    hand = {} }
}
-- Append to the very bottom of assets.lua

-- Create streaming audio file players for background loops
titleMusic = playdate.sound.fileplayer.new("audio/intro_music")
if not titleMusic then print("Warning: Missing audio/title_theme.wav") end

gameMusic = playdate.sound.fileplayer.new("audio/game_music")
if not gameMusic then print("Warning: Missing audio/game_theme.wav") end
