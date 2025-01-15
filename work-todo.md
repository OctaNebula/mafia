## NOT being added

There's a myriad of features mentioned in the original rework document that won't be added on release. The features are as follows:
- Perks
- Skins
- Levels
- Shop

## Bugs
* Mobile controls are nonexistant until you die (i mean the E button)
 * Dead people dying after shot is inconsistent (according to gabi someone kept crawling after death) - https://discord.com/channels/1181250095711260682/1196902376947331176/1310707656591147048
 * https://discord.com/channels/1181250095711260682/1196902376947331176/1310705438496522240
 * Corpses have door proximity prompts - https://discord.com/channels/1181250095711260682/1196902376947331176/1310704849796730922
 * https://discord.com/channels/1181250095711260682/1196902376947331176/1310703871814795265
 * UI inconsistencies on Galaxy S24+ (note the top bar and the ending cutscene chunk showing in bottom right corner) (bug is most likely related to CoreGUI objects moving StarterGUI) - https://discord.com/channels/1181250095711260682/1196902376947331176/1310713292049612913, https://discord.com/channels/1181250095711260682/1196902376947331176/1310713232884760708
 * Apparently doc isn't working
 * Pub scene in the ending cutscene sometimes shows up sometimes doesn't
 * Ending cutscene is blurred - https://discord.com/channels/1181250095711260682/1196902376947331176/1310705896610861118
 * Bug related to gunshot being 100% broken - https://discord.com/channels/1181250095711260682/1196902376947331176/1310709562780946473, https://discord.com/channels/1181250095711260682/1196902376947331176/1310709948979744828
These are the bugs from the last testing, other bugs that I know from my own experience that are still in the game are;

- Custom cursor isn't being displayed except during discussion/voting periods
- MafiaPostKill track is played to everyone in the server, not just the mafias (this is \*\*intended behavior** by the previous scripter but it sucks to the point I consider it a bug and want it changed)

There's a 11/10 chance there's many more that I haven't documented, most regarding roles et cetera. A lot of the bugs are fixable by polishing the game *(read section below)*.

## Polishing

The following should be polished or even rewritten to a polished state:
- **First person system** (literally compare the one that Pressure/Grace has to the one used right now - the difference is astronomical)
- **Corpses & ragdolling** - very buggy and produces weird results, should lack collisions and so on

> [!info] Note
> The gunfire system and stabbing should probably be kept the same, as it generally works fine and most death-related bugs are related to the playermodel system

Other polishes include, but aren't limited to;
* Flashlight sucks at lighting up objects (could use some volumetric effects because in some situations you literally can't tell it's in use), could also be polished up in general
* Some nice camera lerping (the one that Grace uses right now is the target reference) - probably should be included under "first person system" but id rather state it separately 
* At the moment, the custom proximity prompts fade in as you get closer to the target object. A more polished version would be them quickly fully fading in once you reach the target distance where they can be used, rather than just fading in as you get closer

## Content/Features

### Roles
Some roles got scrapped due to our scripter being a slacker, the missing are the following:

* **Judge** - Two ways of implementation;
1. If a tie occurs, make the player who the judge voted for get eliminated (if judge voted for neither nobody gets voted out)
2. Give the judge a segment after the game concludes that votes have tied for the judge to handpick a target
- **Coiner** - Ability to cancel out all votes directed against him once per round
- **Mutilator** - Ability to invalidate a player's vote

> [!info] Note
> Both the Coiner and Mutilator use their abilities in the same way the witch does (click on a button to toggle ability and click again on a player to target and use)

Other roles that need fixes/changes:
* **Doctor** - his ability to revive downed players is broken
* **Jester** - Most likely broken
* **Detainer** - Unfinished, ability when used (during discussion) needs to have an animation where the target player gets literally jailed (a jail model just drops on them and gets sucked into the ground)
* **Witch** - needs testing but probably works

These roles are mechanic-wise alright but unpolished due to the playermodel being unpolished in general:
- **Detective** - (ability thing displays F as the toggle key instead of R, easy fix)
- **Mafia** - Works alright, most issues regarding the role are tied to ragdoll/playermodel issues
- **Innocent** - do I have to explain this

> [!Warning] Watch out
> I might be incorrect about some of these because I'm clueless on the game's internals (some "broken" features might not be broken ane vice versa)
> 

#### Lockers

One of the key features currently missing in the game is the functionality of **lockers**.

The main functionality of lockers is as a hiding spot, where players can enter and stay in as long as they like *(although any players hiding for longer than 30 seconds will cause the locker to be outlined to the Mafia, revealing their location)*. Players can enter lockers for various reasons, from hiding from the Mafia to observing other players undetected.

To enter a locker, one must first open it by pressing E. After that, the player can press E again to enter it. The reason for this 2-step process is because of the offspring chance the locker might already be occupied by another player.

The best reference for the wanted feel of lockers is Pressure.

Future updates will allow the Mafia to move corpses as well as hide them in lockers, making their search more difficult.

#### Game Loop

The following haven't been done yet:
- Role reveal cutscene. Needs to have player rigs replaced by player's avatars and a billboard GUI attached to each rig stating their username and role
- Score screen GUI - similar (if not identical) to the one found in the old version of the game (I already made the UI for it, it's literally just a reskin)

> [!Info] Note
> This also means reimplementing the MVP point system from the old game in a new way

#### Others
- Disguised rounds.
- Custom chat *(I am yet to make the UI for this so please let me know in advance to create it, it's going to have two tabs - one for team and the other being global - the team one only appears if you're on the Mafia side of things).*

## Tweaks

The following are some tweaks I'd like to see done:

* Change the font globally from the serif font currently in use to Josefin Sans

