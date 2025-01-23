--[[
all roles implemented pre-rewrite (has reference code):
    Civilian
        Survive the night. Cooperate with other innocent players to figure out who the Mafia may be.
        Color3.fromRGB(36, 156, 48)
    Detainer
        Cuff a player and they won't be present until the next night. Will you cuff a Mafia, or a Civilian?
        Color3.fromRGB(100, 215, 190)
    Detective
        You will obtain police reports at the end of each night. One of the players close to the deceased body may be one of the Mafias.
        Color3.fromRGB(211, 109, 0)
    Doctor
        Heal players who get attacked by the Mafia. Be quick though, they don't have long to live.
        Color3.fromRGB(29, 162, 205)
    Jester
        Fool everyone into believing you're the Mafia and you'll be able to strike your revenge.
        Color3.fromRGB(151, 32, 37)
    Mafia
        Eliminate all Civilians as discreetly as possible without exposing yourself to any remaining players.
        Color3.fromRGB(151, 32, 37)
    Vigilante
        Eliminate who you suspect the Mafia is as soon as possible. One wrong shot, and you go down too.
        Color3.fromRGB(104, 120, 208)
    Witch
        Curse a player during the night to prevent them from talking until the next night begins.
        Color3.fromRGB(100, 215, 190)
]]

local roles = {
	civilian = {
		name = "Civilian",
		description = "Survive the night. Cooperate with other innocent players to figure out who the Mafia may be.",
		color = Color3.fromRGB(36, 156, 48),
	},
	detainer = {
		name = "Detainer",
		description = "Cuff a player and they won't be present until the next night. Will you cuff a Mafia, or a Civilian?",
		color = Color3.fromRGB(100, 215, 190),
	},
	detective = {
		name = "Detective",
		description = "You will obtain police reports at the end of each night. One of the players close to the deceased body may be one of the Mafias.",
		color = Color3.fromRGB(211, 109, 0),
	},
	doctor = {
		name = "Doctor",
		description = "Heal players who get attacked by the Mafia. Be quick though, they don't have long to live.",
		color = Color3.fromRGB(29, 162, 205),
	},
	jester = {
		name = "Jester",
		description = "Fool everyone into believing you're the Mafia and you'll be able to strike your revenge.",
		color = Color3.fromRGB(151, 32, 37),
	},
	mafia = {
		name = "Mafia",
		description = "Eliminate all Civilians as discreetly as possible without exposing yourself to any remaining players.",
		color = Color3.fromRGB(151, 32, 37),
	},
	vigilante = {
		name = "Vigilante",
		description = "Eliminate who you suspect the Mafia is as soon as possible. One wrong shot, and you go down too.",
		color = Color3.fromRGB(104, 120, 208),
	},
	witch = {
		name = "Witch",
		description = "Curse a player during the night to prevent them from talking until the next night begins.",
		color = Color3.fromRGB(100, 215, 190),
	},
}

return roles
