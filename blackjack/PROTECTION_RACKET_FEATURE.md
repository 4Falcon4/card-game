# Protection Racket Feature

## Overview
The Protection Racket feature adds a roguelike meta-progression system to the blackjack game. Players must pay a "guy" every few rounds or get "kicked out" (beaten up). When kicked out, players enter a shop where they can purchase permanent upgrades using chips earned from successful runs.

## How It Works

### 1. Protection Racket Mechanic
- **Payment Schedule**: Every 3 rounds (configurable), the player must pay the "guy"
- **Payment Amount**: Starts at 50 chips and increases by 25 chips after each payment
- **Warning System**: Players receive a warning 1 round before payment is due
- **Auto-Payment**: If the player can afford it, payment is automatically deducted
- **Kicked Out**: If the player can't afford the payment, they get kicked out and sent to the shop

### 2. Shop System
When kicked out, players enter a back alley shop where they can:
- **View Available Upgrades**: All upgrades display with name, description, cost, and level
- **Purchase Upgrades**: Spend persistent chips to buy permanent upgrades
- **Track Progress**: See runs completed and total chips earned
- **Return to Casino**: Start a new run with purchased upgrades active

### 3. Upgrade System

#### Available Upgrades:
1. **Extra Starting Chips I** (500 chips)
   - Start each run with +100 chips
   - Max level: 5

2. **Extra Starting Chips II** (1500 chips)
   - Start each run with +250 chips
   - Max level: 3
   - Requires: Extra Starting Chips I

3. **Smooth Talker** (800 chips)
   - +1 round before payment is due
   - Max level: 3

4. **Good Negotiator** (1000 chips)
   - Reduce payment amounts by 20%
   - Max level: 2

5. **Card Counter** (2000 chips)
   - Slightly better card odds
   - Max level: 1

6. **Ability Master** (1200 chips)
   - Card abilities are 25% more effective
   - Max level: 3

7. **Bold Gambler** (900 chips)
   - Double down costs 50% less
   - Max level: 1

### 4. Persistence System
- **Chips**: Carry over between runs (persistent across sessions)
- **Upgrades**: Permanently saved and active in all future runs
- **Progress**: Tracks runs completed and lifetime earnings
- **Save File**: `user://casino_save.dat`

## File Structure

### New Files:
- `blackjack/protection_racket.gd` - Protection racket system
- `blackjack/game_state_manager.gd` - Persistent state and upgrade management
- `blackjack/shop_scene.gd` - Shop UI and logic
- `blackjack/shop_scene.tscn` - Shop scene
- `blackjack/PROTECTION_RACKET_FEATURE.md` - This documentation

### Modified Files:
- `blackjack/rougelike_blackjack.gd` - Integrated protection racket
- `blackjack/rougelike_blackjack.tscn` - Added protection racket node and UI
- `project.godot` - Added GameStateManager autoload

## Configuration

### Protection Racket Settings (in scene):
```gdscript
rounds_between_payments = 3  # How many rounds between payments
base_payment_amount = 50     # Initial payment amount
payment_increase_per_demand = 25  # Increase per payment
warning_rounds = 1           # Warning N rounds before due
```

### Adding New Upgrades:
Edit `game_state_manager.gd` and add to the `available_upgrades` dictionary:
```gdscript
"upgrade_id": {
    "name": "Upgrade Name",
    "description": "What it does",
    "cost": 1000,
    "effect": "effect_type",  # Used for lookup
    "value": 100,             # Effect value
    "max_level": 3,           # Max purchases
    "requires": "other_id"    # Optional prerequisite
}
```

## Future Extensibility

### Level/Difficulty System (Framework Ready):
The system is designed to support future level/difficulty features:
- `GameStateManager.current_level` - Current level being played
- `GameStateManager.highest_level_unlocked` - Progress tracking
- `GameStateManager.unlock_level(level)` - Unlock new levels
- `GameStateManager.set_current_level(level)` - Select level

### Potential Additions:
1. **Level Selector**: Choose difficulty before entering casino
2. **Difficulty Scaling**: Harder levels = better rewards
3. **Level-Specific Upgrades**: Unlock upgrades by beating levels
4. **Boss Rounds**: Special protection racket challenges
5. **Meta Currencies**: Multiple currency types (chips, tokens, etc.)
6. **Card Shop**: Buy/unlock new cards with special abilities
7. **Daily Challenges**: Special runs with unique modifiers
8. **Achievements**: Milestone-based rewards

## Testing

### To Test the Feature:
1. Start a new game in the casino
2. Play 3 rounds of blackjack
3. On round 3, you'll receive a warning about payment
4. After round 3 ends, payment will be demanded
5. If you can't pay, you'll be kicked out → shop
6. In shop, purchase upgrades with your chips
7. Click "Return to Casino" to start a new run with upgrades

### Debug Commands (can add later):
- Reset progress: `GameStateManager.reset_all_progress()`
- Give chips: `GameStateManager.persistent_chips += 1000`
- Unlock all: Manually add to `purchased_upgrades`

## Game Flow

```
┌─────────────────┐
│   Main Menu     │
└────────┬────────┘
         │
         v
┌─────────────────┐
│  Casino/Game    │<────────────┐
│  - Play rounds  │             │
│  - Pay "guy"    │             │
│  - Get kicked   │             │
└────────┬────────┘             │
         │                      │
         v (kicked out)         │
┌─────────────────┐             │
│   Shop Scene    │             │
│  - Buy upgrades │             │
│  - View stats   │             │
│  - Return       │─────────────┘
└─────────────────┘
```

## UI Elements

### In-Game Display:
- **RacketLabel**: Shows "Next Payment: X chips in Y rounds"
- **RacketWarning**: Red panel that appears when payment is coming soon
- **Payment Messages**: Visual feedback for payments and kicked out events

### Shop Display:
- **Chips Display**: Shows persistent chip balance
- **Upgrade Panels**: Each upgrade has name, description, level, and buy button
- **Stats Footer**: Shows runs completed and lifetime earnings
- **Return Button**: Goes back to casino for new run

## Technical Notes

### Signals:
**ProtectionRacket:**
- `payment_demanded(amount, rounds_until_demand)`
- `payment_made(amount)`
- `kicked_out()`

**GameStateManager:**
- `chips_changed(new_amount)`
- `upgrade_purchased(upgrade_id)`
- `level_unlocked(level)`

### State Management:
- Game state persists via autoload singleton
- Shop and casino communicate through GameStateManager
- Scene transitions handled via `get_tree().change_scene_to_file()`

---

**Created**: 2025-11-05
**Author**: Claude (AI Assistant)
**Version**: 1.0
