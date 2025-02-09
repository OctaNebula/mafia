local soundManager = {
    currentMusic = nil,
    fadeTime = 1,
    events = {}
}

function soundManager.init(gameService)
    soundManager.events.toggleAudio = gameService.client.toggleAudio
end

function soundManager.playSound(sound, volume, loop)
    soundManager.events.toggleAudio:fireAllClients({
        sound = sound,
        playing = true,
        duration = soundManager.fadeTime,
        volume = volume or 0.5,
        loop = loop
    })
end

function soundManager.stopSound(sound)
    soundManager.events.toggleAudio:fireAllClients({
        sound = sound,
        playing = false,
        duration = soundManager.fadeTime,
        volume = 0
    })
end

function soundManager.playMusic(sound)
    if soundManager.currentMusic then
        soundManager.stopSound(soundManager.currentMusic)
    end

    soundManager.currentMusic = sound
    soundManager.playSound(sound, 0.5, true)
end

return soundManager