# CardGame

A **roguelike Blackjack** game built with Godot 4.5, featuring persistent progression, special card abilities, and a unique "protection racket" mechanic.

## Overview

This is a casino-style Blackjack game with a twist: survive the bookie's protection racket while building up your permanent upgrades across multiple runs. Features standard Blackjack mechanics (Hit, Stand, Double Down, Split) combined with a progression system that rewards strategic play and long-term planning.

## Features

### Core Gameplay
- **Classic Blackjack Rules** - Hit, Stand, Double Down, and Split hands
- **Intelligent Dealer AI** - Follows standard casino rules (hits until 17+)
- **Automatic Detection** - Natural blackjack, busts, and hand comparisons
- **Flexible Betting** - Quick-bet buttons (min, quarter, half, max) for easy wagering

### Roguelike Progression
- **Persistent Chip System** - Keep your winnings across runs
- **Upgrade Shop** - Purchase permanent upgrades between runs:
  - Extra starting chips
  - Delayed bookie payments
  - Reduced payment amounts
  - Better payout odds
  - Ability boosts
  - Double down discounts
- **Achievement System** - Track your accomplishments
- **Run Statistics** - Monitor wins, losses, and rounds completed

### Special Mechanics
- **Protection Racket** - Pay the bookie periodically or get kicked out of the casino
- **Card Abilities** - Special effects on cards that modify gameplay
  - Light-colored cards: Positive abilities
  - Dark-colored cards: Negative effects
- **Draw Hand System** - Visual card selection from a draw pile
- **Smart Tooltips** - Hover over cards to see ability information

### Professional UI
- Main menu with animations
- Pause menu and comprehensive options (audio, video, input)
- Achievement notifications
- Loading screens
- Credits system

## Tech Stack

- **Engine:** Godot 4.5 (GL Compatibility)
- **Languages:**
  - GDScript (UI, scenes, game flow)
  - C# .NET 8.0 (core Blackjack logic)
- **Framework:** Godot.NET.Sdk 4.5.1
- **Platform:** Windows Desktop (x86_64)
- **Resolution:** 1920x1080

## Controls

| Action | Key Bindings |
|--------|-------------|
| Hit / Deal | Space, Z |
| Stand / Cancel Bet | X |
| Double Down / Min Bet | V |
| Split / Max Bet | B |
| Quarter Bet | G, W |
| Half Bet | H, E |
| Max Bet | R |
| Confirm Bet | C |

![In-Game Screenshot](https://github.com/4Falcon4/card-game/blob/main/assests/keybinds.png)

## Save System

- **Location:** `%APPDATA%\\Godot\\app_userdata\\CardGame\\casino_save.dat`
- **Format:** Encrypted JSON (via Locker addon) (WIP)
- **Saved Data:**
  - Persistent chip count
  - Purchased upgrades and levels
  - Progression unlocks
  - Run statistics (wins, losses, rounds)
  - Lifetime earnings

## Architecture

The game uses a hybrid approach:
- **C# (BlackjackManager.cs)** - Core game logic, card management, hand scoring
- **GDScript** - UI, scene management, visual effects, game flow
- **Signal-driven** - Decoupled systems communicating via Godot signals
- **Auto-save** - State persists automatically after purchases and run completion

## Addons Used

1. **simple_cards** - Card rendering and management
2. **dialogue_manager** - Branching dialogue system with C# support
3. **maaacks_menus_template** - Professional menu and options UI
4. **milestone** - Achievement tracking
5. **locker** - Encrypted save file management

[//]: # (## License)
[//]: # (*[Add your license information here]*)

## Roadmap
- [ ] Additional card abilities and upgrades planned for future updates
- [ ] Rework round end timing
- [ ] Use locker to save data
- [ ] Implement more robust error handling and user feedback
- [ ] Implement sound effects and music tracks

## Known Issues
- Save system is a work in progress; may have bugs
- Some UI elements may not scale perfectly on all resolutions
- Earned chips are inconsistent between runs
- Split hand possibly still incorrectly changing states when busted
- Confirmation prompts are not using correct style

## Credits

Developed by **Koby, Raymond, and Chenghao**

[//]: # (*[Add additional credits, assets, libraries, etc.]*)