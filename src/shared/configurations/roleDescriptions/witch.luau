local witchDescription = {
	--[[
    {
        text = "", -- text to be displayed
        typewriterDelay = 0.025, -- delay between each individual character
        delay = 4 -- delay until the next message is displayed
    }
    ]]
	civilian = {
		{
			text = "Your task as the Witch is to curse people during the night to prevent them from talking during discussion time.",
			typewriterDelay = 0.025,
			delay = 4,
		},
		{
			text = "Remember that you are still an innocent player, you do not work with the Mafia.",
			typewriterDelay = 0.0225,
			delay = 4,
		},
		{
			text = "Use your ability to curse players during the night you believe may be a Mafia.",
			typewriterDelay = 0.02,
			delay = 4,
		},
		{
			text = "This will prevent them from stating false accusations, and other players will find them suspicious for not talking during discussion.",
			typewriterDelay = 0.0175,
			delay = 4,
		},
		{
			text = "Cooperate with the Civilians to secure you and them a win",
			typewriterDelay = 0.015,
			delay = 4,
		},
	},
	mafia = {
		{
			text = "Your task as the Witch is to curse people during the night to prevent them from talking during discussion time.",
			typewriterDelay = 0.025,
			delay = 4,
		},
		{
			text = "Remember that you are working with the Mafia. Walk around the map and target a certain player.",
			typewriterDelay = 0.0225,
			delay = 4,
		},
		{
			text = "Use your ability to curse players during the night you believe may snitch on the Mafia. Do this by clicking on them.",
			typewriterDelay = 0.02,
			delay = 4,
		},
		{
			text = "You are one of the biggest threats to the civilians. Cooperate with the Mafia to secure a win for you and the Mafia.",
			typewriterDelay = 0.0175,
			delay = 4,
		},
		{
			text = "However, if the Mafia dies, the civilians still win. Be smart with your ability.",
			typewriterDelay = 0.015,
			delay = 4,
		},
	},
}

return witchDescription
