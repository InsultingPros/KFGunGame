[gun master]: https://battlefield.fandom.com/wiki/Gun_Master

# Gun Game

[![GitHub all releases](https://img.shields.io/github/downloads/InsultingPros/KFGunGame/total)](https://github.com/InsultingPros/KFGunGame/releases)

> **Note** You can find all maps and additional information about this gamemode [here](https://insultingpros.github.io/KFStory/GunGame.html).

Official deathmatch by TWI, very similar to Battlefield’s [gun master] mode - every kill instantly gets you the next weapon in the list. Be the first player to get a kill with every weapon on the list to win!

What I've added on top of original version:

- Separate config file for garbage (user.ini and killingfloor.ini will stay intact) and for settings.
- Much cleaner and editable code.
- Weapon lists can be edited in [config file](Configs/KFGunGameSettings.ini). Limit is 100 weapons.
- Prevent exploits:
  - Disable perks.
  - Disable suicide command.
  - Disable 3rd person view.
  - Disable dosh tossing.

## Installation

```ini
Game=KFGunGame.KFGG?MaxPlayers=32?MinPlayers=8
```

## Building and Dependancies

Use [KF Compile Tool](https://github.com/InsultingPros/KFCompileTool) for easy compilation.

**killingfloor.ini**

```ini
EditPackages=KFGunGame
```

## Credits

- [Ramm-Jaeger](http://steamcommunity.com/profiles/76561197966407225) - author of original version ([Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=97706196), [TWI Forum](https://forums.tripwireinteractive.com/index.php?threads/mod-release-kf-gun-game-v-0-70-alpha.85621/)).
- [Nejco](https://steamcommunity.com/profiles/76561198008041378) - I simply copy-pasted his weapon lists from **LongGunGame**.
