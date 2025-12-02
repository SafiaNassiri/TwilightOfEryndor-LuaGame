# Twilight of Eryndor

Twilight of Eryndor is a 2D dungeon crawler built entirely in Lua using the Love2D framework. Explore the ruins of the ancient kingdom of Eryndor, battle enemies, collect loot, and master the dual Light & Shadow skills to overcome puzzles and reach hidden areas.

---

## Features

- **Procedurally Generated Dungeons** – Each playthrough offers new layouts, enemy placements, and loot.
- **Combat System** – Engage enemies in melee or ranged combat with responsive controls.
- **Enemy AI** – Enemies patrol, chase the player when spotted, and attack with cooldowns and telegraphs.
- **Loot & Items** – Collect potions, weapons, and artifacts dropped by enemies to aid your journey.
- **Boss Encounters** – Face floor bosses that challenge your combat skills and strategy.
- **Smooth Camera** – Follow the player through the dungeon seamlessly.

---

## Installation

1. Download and install [Love2D](https://love2d.org/) (version 11.4 or higher recommended).
2. Clone or download this repository:

```bash
git clone https://github.com/YourUsername/TwilightOfEryndor-LuaGame.git
```

3. Navigate to the project folder and run the game:

```bash
love .\TwilightOfEryndor-LuaGame\
```

---

## Controls

| Action            | Key / Button      |
| ----------------- | ----------------- |
| Move              | Arrow Keys / WASD |
| Use Light Skill   | L                 |
| Use Shadow Skill  | K                 |
| Attack / Interact | E / Left Click    |
| Pause             | Esc               |

(Controls can be customized in controls.lua.)

---

## Project Structure

```bash
TwilightOfEryndor-LuaGame/
├── main.lua          # Game entry point
├── conf.lua          # Love2D configuration
├── player.lua        # Player logic and skill mechanics
├── dungeon.lua       # Procedural dungeon generation
├── enemy.lua         # Enemy AI and behaviors
├── items.lua         # Loot, potions, and artifacts
├── spawner.lua       # Logic to randomly spawn enemies in a dungeon and increase waves overt time
├── rooms.lua         # Room layouts and puzzle logic
├── assets/           # Sprites, audio, and tiles
└── README.md         # This file
```

---

## Roadmap

- [x] Implement multiple enemy types (melee, ranged) with unique stats.
- [x] Ensure enemy patrolling, chasing, and attacks work correctly.
- [x] Add player combat feedback: damage indicators and health system.
- [x] Improve procedural dungeon generation and connectivity.
- [ ] Place enemies and loot only on walkable tiles.
- [ ] Design floor bosses with unique movement and attack patterns.
- [x] Implement telegraphed attacks.
- [ ] Drop rare items or keys upon defeat.
- [ ] Particle effects for attacks and deaths.
- [x] Camera smoothing and subtle visual polish.
- [ ] Sound effects for player actions, enemy attacks, and pickups (optional).
- [ ] Add obstacles and environmental hazards (optional).
- [ ] Ambient music or environmental sounds (optional).

---

## Credits

- Love2D – https://love2d.org/
- Placeholder assets & free resources (sprites, audio) – properly credited in /assets/credits.txt

---

## Credits

- Love2D – https://love2d.org/
- Placeholder assets & free resources (sprites, audio) – properly credited in /assets/credits.txt
