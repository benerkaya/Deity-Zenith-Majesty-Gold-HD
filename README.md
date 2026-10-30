# Deity - a summoning mod for Majesty Gold HD

Deity lets you play god in **Majesty Gold HD**. Choose something in a Cheat Engine table, place a flag, and it appears there:

- **Monsters** (goblins, ratmen, trolls, dragons, the bosses...) and **nature** (Flowering Strangleweed, Daemonwood, Dryad)
- **Henchmen** (peasants, tax collector, City / Veteran / Palace Guards, Hooligan)
- **Heroes** (every class, plus the quest heroes)
- **Buildings** and **lairs**

You also choose **whose side** the summons are on: **Blue** (you), **Hostile** (the monsters), the **Red** kingdom or the **Green** kingdom. You can summon 1 to 10 per flag.

- **Explore flag:** the summons appear at the flag.
- **Attack flag:** summons from another side **attack** the flagged unit or building. Summons on the same side **guard** it.

Deity works in **Freestyle**, the **Northern Expansion quests** and the **original Majesty quests**. It is one mod: it checks which rules the game is using and offers the matching list. Chat messages in the game tell you what happened.

## What you need

- **Majesty Gold HD** on Steam (Windows)
- **[Cheat Engine](https://www.cheatengine.org/)**

## Install

1. Unzip the whole package anywhere.
2. Double-click **`Install.bat`**.

That's all. The installer finds the game through Steam. Deity then loads in every game by itself. **Do not tick it in "Active Mods".**

- If Windows says access is denied, right-click `Install.bat` and choose **Run as administrator**.
- **Only if the installer says it cannot find the game** (for example a copy not installed through Steam), tell it where the game is:
  1. Open the game folder. In Steam: right-click **Majesty Gold HD** > **Manage** > **Browse local files**. For a copy not installed through Steam, it is the folder that contains `MajestyHD.exe`.
  2. Copy that folder's path from the address bar.
  3. Open the unzipped Deity folder (the one with `Install.bat`), click its address bar, type `cmd` and press Enter.
  4. In the window that opens, type `Install.bat -GamePath "<your Majesty HD folder>"`, using the path you copied in place of `<your Majesty HD folder>`, and press Enter.

**After a Steam update** or a **"Verify integrity of game files"**, Steam puts the original game files back and Deity stops loading. Double-click **`Status.bat`** to check. If it says `NOT ACTIVE`, just run `Install.bat` again.

**Why the same file is copied twice:** Majesty keeps the scripts of the original game and of the expansion in two separate data folders (`Data` and `DataMX`). Each folder has its own list of scripts to load. `Deity.bcd` is a single file that works with both rulesets, so the installer puts a copy in each folder. It also adds Deity to both lists, and saves a backup of each list first.

## Uninstall

Double-click **`Uninstall.bat`**. It puts back the game's original files and removes everything Deity added. That includes the folders older Deity versions created in `Documents\My Games\MajestyHD`.

## How to play with it

1. Open **`Deity.CT`** in Cheat Engine.
2. Tick **"Deity Hotkeys (tick before starting Majesty)"**. Make sure **NumLock** is on.
3. Start Majesty Gold HD and start or load a game. The chat says *"Deity is running..."*.
4. Tick **"Deity - Activate"** or press **Ctrl+Num 0**. Cheat Engine connects to the game by itself. Do this again after loading a save.
5. In the table, choose:
   - what to summon: use **"Expansion / Freestyle: what to summon"** in Freestyle and expansion quests, and **"Original Majesty: what to summon"** in the original quests;
   - the **"Faction"**;
   - **"Summons per flag"**.
6. Set **"Flag summon"** to **ON**, or press Ctrl+Num 5. While it is ON, your Explore and Attack flags summon instead of doing their normal job. Turn it OFF to use flags normally again.

You can also do everything with the keyboard while playing:

| Keys (hold Ctrl, use the number pad) | What it does |
|---|---|
| Ctrl+Num 0 | activate / re-scan (also after loading a save) |
| Ctrl+Num 5 | flag summon ON / OFF |
| Ctrl+Num 6 | next entry |
| Ctrl+Num 4 | previous entry |
| Ctrl+Num 9 | 10 entries forward |
| Ctrl+Num 3 | 10 entries back |
| Ctrl+Num 8 | next category (monsters, nature, henchmen, heroes, buildings, lairs) |
| Ctrl+Num 2 | previous category |
| Ctrl+Num 7 | faction Blue > Hostile > Red > Green |
| Ctrl+Num + | summons per flag +1 (max 10) |
| Ctrl+Num - | summons per flag -1 (min 1) |
| Ctrl+Num * | repeat the current selection |
| Ctrl+Num . | switch list Expansion / Original (fallback only) |

Every change is confirmed by a chat message in the game. All entries and their numbers are listed in [ENTRIES.md](ENTRIES.md).

## Good to know

- **Red / Green** only work when that kingdom is on the map. Otherwise the summons are Hostile, and a chat message says so.
- **Buildings, guards, peasants and tax collectors are always yours**, whatever faction you choose.
- **Friendly monsters:** at most 40 can be alive at once. Heroes don't count.
- **Summoned guards** join the nearest Guardhouse, Outpost or Palace. They count towards its guard limit, so that building makes no new guards of its own until some of them die.
- **Summoned Blue heroes** have no guild. They explore, fight and level up, but cannot rest in a guild.
- **Quest heroes** (Angry Wizard, Scions of Chaos) are normal heroes with quest-level stats. They do not start quest events.
- **Dark Palaces can't be clicked** in the game. To target one made by Deity, place an Explore flag right next to it. Destroying a Palace or Dark Palace made by Deity never ends the game.
- **Hostile summons sent at your own Palace really attack it.**
- In Freestyle and expansion games, the "Original Majesty" row shows a plain number. That is normal.
- Deity is made for single player.

## What's in the package

| File | What it is |
|---|---|
| `Install.bat`, `Status.bat`, `Uninstall.bat` | double-click these |
| `Deity.CT` | the Cheat Engine table |
| `Deity\Deity.bcd` | the mod (one file for both rulesets) |
| `Deity\Deity_MX_Text.xml`, `Deity\Deity_Text.xml` | the mod's chat texts (expansion / original) |
| `Deity\GPL\` | the mod's source code |
| `Install_Deity.ps1` | the script behind the .bat files |
| `ENTRIES.md` | list of everything you can summon |

## Credits

Deity by **Bener Kaya**.
Majesty is a trademark of its respective owners. This is an unofficial fan mod.
