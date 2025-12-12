# Twilight of Eryndor

Twilight of Eryndor is a 2D roguelike dungeon crawler built in Lua using the Love2D framework. Battle through procedurally generated dungeons, face waves of enemies, collect powerful loot, and see how long you can survive!

---

## Features

- **Procedurally Generated Dungeons** – Each playthrough offers unique layouts with connected rooms and corridors.
- **Wave-Based Combat** – Face increasingly difficult waves of enemies that spawn off-screen and hunt you down.
- **Three Enemy Types** – Battle melee bruisers, tanky juggernauts, and deadly ranged attackers, each with unique sizes and behaviors.
- **Projectile Combat** – Click to fire projectiles at enemies. Aim carefully and dodge incoming attacks!
- **Enemy AI** – Enemies patrol when idle, chase when they spot you, and use telegraphed attacks before striking.
- **Animated Sprites** – Characters squash and stretch as they move, and breathe while idle for a lively feel.
- **Death Animations** – Enemies burst into particles when defeated, with satisfying visual feedback.
- **Diverse Loot System** – Collect health orbs, speed boosts, health potions, mana potions, and rare shards that drop from defeated enemies.
- **Progressive Difficulty** – Enemy waves grow larger and drop rates increase as you survive longer.
- **Smooth Camera** – The camera follows the player seamlessly through the dungeon.

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
| Use Light Skill   | Left Click        |
| Restart           | R (on deth)       |

---

## Enemy Types

- **Melee (Red)** – Medium size, fast, moderate damage. Gets up close to strike.
- **Tank (Orange)** – Large and slow, high HP, devastating area-of-effect attacks.
- **Ranged (Green)** – Small and quick, low HP, shoots projectiles from a distance.

---

## Loot Items

- **Health Orb (Light Blue)** – Restores 30 HP
- **Speed Boost (Turquoise)** – Permanently increases movement speed
- **Health Potion (Cyan)** – Restores 25 HP
- **Mana Potion (Blue)** – Restores 15 HP (placeholder effect)
- **Rare Shard (Purple)** – Increases max HP by 10 (rare drop!)

---

## Project Structure

```bash
TwilightOfEryndor-LuaGame/
├── main.lua          # Game entry point and main loop
├── conf.lua          # Love2D configuration
├── player.lua        # Player logic, movement, and combat
├── dungeon.lua       # Procedural dungeon generation
├── enemy.lua         # Enemy AI, behaviors, and animations
├── items.lua         # Loot definitions and item database
├── spawner.lua       # Wave-based enemy spawning system
├── camera.lua        # Smooth camera following system
└── README.md         # This file
```

---

## GamePlay Tips

- **Keep Moving** – Standing still makes you an easy target!
- **Use the Dungeon** – Hide behind walls and break line of sight with ranged enemies.
- **Collect Rare Shards** – They permanently increase your max HP, making later waves easier.
- **Watch for Telegraphs** – Enemies show visual indicators before attacking. Dodge them!
- **Speed Stacks** – Multiple speed boosts make you incredibly fast. Collect them all!

---

## Roadmap

- [x] Implement multiple enemy types (melee, tank, ranged) with unique stats and sizes.
- [x] Enemy patrolling, chasing, and telegraphed attacks.
- [x] Player projectile combat with collision detection.
- [x] Health system with damage indicators and i-frames.
- [x] Procedural dungeon generation with line-of-sight checks.
- [x] Wave-based spawning system with off-screen enemy placement.
- [x] Diverse loot system with multiple item types.
- [x] Squash and stretch animations for movement and idle states.
- [x] Death particle effects for enemies.
- [x] Progressive difficulty scaling with waves.
- [ ] Boss encounters with unique mechanics.
- [ ] More enemy variety and attack patterns.
- [ ] Player upgrades and permanent progression.
- [ ] Sound effects for attacks, hits, and item pickups.
- [ ] Background music and ambient sounds.
- [ ] Environmental hazards and traps.
- [ ] Mini-map or dungeon overview.
- [ ] Score tracking and high scores.

---

## Known Issues

- Enemies may occasionally spawn in walls if dungeon generation creates tight spaces.
- Performance may drop with 50+ active enemies on screen.

---

## Credits

- Love2D – https://love2d.org/
- Placeholder assets & free resources (sprites, audio) – properly credited in /assets/credits.txt
- Development: Solo project

---

## License
This project is open source. Feel free to fork, modify, and learn from it!
