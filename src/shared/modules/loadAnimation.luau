local loadedAnimations = {}

return function(animator: Animator, animation: Animation, shouldNotCreateNew: boolean)
    local playingAnimationTracks = animator:GetPlayingAnimationTracks()
    local loadedAnimationTrack: AnimationTrack?
    for _, animationTrack in playingAnimationTracks do
        if animationTrack.Animation == animation then
            loadedAnimationTrack = animationTrack
            break
        end
    end
    if not loadedAnimationTrack and not shouldNotCreateNew then
        loadedAnimationTrack = animator:LoadAnimation(animation)
    end
    return loadedAnimationTrack
end