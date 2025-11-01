# Card Back Abilities Tracker

This document tracks all card backs, their abilities, descriptions, rarities, and implementation status for the Blackjack Roguelike game.

## Overview

- **Total Card Backs**: 51
- **Ability Scripts Created**: 5
- **Fully Populated Resources**: 1 (simple.tres)
- **Partially Populated Resources**: 2 (dna.tres, eyes.tres)
- **Empty Resources**: 48

---

## Ability Scripts

### Created Abilities

| Script Name | File Path | Status | Positive Effect | Negative Effect |
|-------------|-----------|--------|-----------------|-----------------|
| SuitDestroyerAbility | `abilities/suit_destroyer_ability.gd` | ✅ Complete | Destroys all cards of a suit from discard pile | Creates and shuffles 3 random duplicate cards into deck |
| DrawBoostAbility | `abilities/draw_boost_ability.gd` | ✅ Complete | Draw 2 extra cards | Discard 1 random card from hand |
| ChipGambleAbility | `abilities/chip_gamble_ability.gd` | ✅ Complete | Gain 100 chips | Lose 50 chips |
| ValueMultiplierAbility | `abilities/value_multiplier_ability.gd` | ✅ Complete | Double card values in hand | Halve card values in hand |
| AceMasterAbility | `abilities/ace_master_ability.gd` | ✅ Complete | Convert 2 random cards to Aces | Convert all Aces to random values (5-10) |

### Planned Abilities (Not Yet Created)

| Ability Concept | Positive Effect | Negative Effect | Priority |
|----------------|-----------------|-----------------|----------|
| ShuffleManipulatorAbility | Peek at top 3 cards and reorder them | Shuffle discard pile into draw pile | Medium |
| BustProtectorAbility | If you would bust, set hand to 21 instead | Cannot stand until hand >= 15 | High |
| DealerWeakenerAbility | Dealer must hit on 18 instead of 17 | Player must hit on 16 instead of standing | Medium |
| BettingBoostAbility | Double your bet payout this round | Minimum bet increases by 50% | Low |
| WildcardAbility | Choose any card's suit this round | Random card becomes worthless (value 0) | Medium |

---

## Card Back Resources Status

### Fully Populated (1)

| Card Name | Display Name | Positive Desc | Negative Desc | Rarity | Ability Assigned | Notes |
|-----------|--------------|---------------|---------------|--------|------------------|-------|
| simple | Simple | Regular Card | Regular Card | ❌ None | ❌ None | Default/regular card back |

### Partially Populated (2)

| Card Name | Display Name | Positive Desc | Negative Desc | Rarity | Ability Assigned | Notes |
|-----------|--------------|---------------|---------------|--------|------------------|-------|
| dna | ❌ Not set | destroy all cards of a suit | create and shuffle the next 3 cards drawn | ❌ None | ❌ None | Description matches SuitDestroyerAbility |
| eyes | ❌ Not set | destroy all cards of a suit | create and shuffle the next 3 cards drawn | ❌ None | ❌ None | Identical to dna - may be duplicate |

### Empty Resources (48)

All of the following card backs need to be populated with display_name, descriptions, rarity, and ability assignments:

| Card Name | Suggested Rarity | Suggested Ability | Theme Notes |
|-----------|------------------|-------------------|-------------|
| abstract | Common | DrawBoostAbility | Abstract patterns |
| alchemy | Rare | ValueMultiplierAbility | Alchemy/transformation theme |
| aztec | Epic | - | Ancient/mystical theme |
| candles | Uncommon | ChipGambleAbility | Light/ritual theme |
| chains | Uncommon | - | Binding/restriction theme |
| clubs | Common | - | Suit-based theme (Clubs) |
| cobra | Rare | - | Snake/danger theme |
| crosses | Uncommon | - | Religious/holy theme |
| dark hole | Legendary | - | Void/darkness theme |
| diamonds | Common | ChipGambleAbility | Suit-based theme (Diamonds) |
| hearts | Common | - | Suit-based theme (Hearts) |
| honeycomb | Uncommon | - | Nature/structure theme |
| illusion | Epic | - | Deception/trickery theme |
| industrial | Uncommon | - | Machine/mechanical theme |
| interlinked | Rare | - | Connection/network theme |
| invaders | Rare | - | Space invaders/retro gaming theme |
| knots | Uncommon | - | Complexity/entanglement theme |
| libra | Rare | - | Balance/scales theme |
| moons | Rare | - | Lunar/night theme |
| morning star | Legendary | - | Celestial/powerful theme |
| orb | Epic | - | Mystical/power theme |
| ornamental | Common | - | Decorative theme |
| owl | Rare | - | Wisdom/knowledge theme |
| perspective | Uncommon | - | Optical/geometric theme |
| plaid | Common | - | Pattern/textile theme |
| polkadot | Common | - | Pattern/simple theme |
| praisethemoon | Epic | - | Dark Souls reference/moon worship |
| praisethesun | Epic | - | Dark Souls reference/sun worship |
| pyramids | Rare | - | Ancient/Egyptian theme |
| rainbows | Uncommon | - | Color/spectrum theme |
| rhombus | Common | - | Geometric/shape theme |
| roses | Uncommon | - | Nature/beauty theme |
| royal | Legendary | - | Royalty/luxury theme |
| skulls | Epic | - | Death/danger theme |
| smoke | Rare | - | Ephemeral/mysterious theme |
| snake | Rare | - | Serpent/cunning theme |
| space | Epic | - | Cosmic/infinite theme |
| spades | Common | - | Suit-based theme (Spades) |
| specks | Common | - | Pattern/minimalist theme |
| swords | Rare | - | Weapon/combat theme |
| swordsbig | Epic | - | Enhanced weapon/power theme |
| toebeans | Uncommon | - | Cute/animal theme |
| triangle | Common | - | Geometric/shape theme |
| wheat | Uncommon | - | Nature/harvest theme |
| yinyang | Legendary | AceMasterAbility | Balance/duality theme |

---

## Rarity Distribution Plan

Suggested rarity distribution across all 51 card backs:

| Rarity | Count | Percentage |
|--------|-------|------------|
| None/Default | 1 | 2% |
| Common | 12 | 24% |
| Uncommon | 12 | 24% |
| Rare | 13 | 25% |
| Epic | 8 | 16% |
| Legendary | 5 | 10% |
| Mythic | 0 | 0% |
| Exotic | 0 | 0% |
| Divine | 0 | 0% |
| Godly | 0 | 0% |

**Note**: Higher rarities (Mythic+) are reserved for future expansion content.

---

## Implementation Checklist

### Phase 1: Core Abilities ✅
- [x] Create abstract CardAbility base class
- [x] Implement SuitDestroyerAbility
- [x] Implement DrawBoostAbility
- [x] Implement ChipGambleAbility
- [x] Implement ValueMultiplierAbility
- [x] Implement AceMasterAbility

### Phase 2: Assign Existing Abilities to Card Backs
- [ ] Assign SuitDestroyerAbility to dna.tres
- [ ] Assign SuitDestroyerAbility to eyes.tres (or create unique ability)
- [ ] Set display_name for dna.tres
- [ ] Set display_name for eyes.tres
- [ ] Set rarity for dna.tres
- [ ] Set rarity for eyes.tres

### Phase 3: Populate Common Card Backs (12 cards)
For each common card back:
- [ ] Set display_name
- [ ] Write positive description
- [ ] Write negative description
- [ ] Set rarity to COMMON
- [ ] Assign appropriate ability (or create new one)

**Common Cards to Populate:**
1. clubs
2. diamonds
3. hearts
4. spades
5. abstract
6. ornamental
7. plaid
8. polkadot
9. rhombus
10. specks
11. triangle
12. simple (already done)

### Phase 4: Populate Uncommon Card Backs (12 cards)
- [ ] candles
- [ ] chains
- [ ] crosses
- [ ] honeycomb
- [ ] industrial
- [ ] knots
- [ ] perspective
- [ ] rainbows
- [ ] roses
- [ ] toebeans
- [ ] wheat

### Phase 5: Populate Rare Card Backs (13 cards)
- [ ] alchemy
- [ ] cobra
- [ ] interlinked
- [ ] invaders
- [ ] libra
- [ ] moons
- [ ] owl
- [ ] pyramids
- [ ] smoke
- [ ] snake
- [ ] swords

### Phase 6: Populate Epic Card Backs (8 cards)
- [ ] aztec
- [ ] illusion
- [ ] orb
- [ ] praisethemoon
- [ ] praisethesun
- [ ] skulls
- [ ] space
- [ ] swordsbig

### Phase 7: Populate Legendary Card Backs (5 cards)
- [ ] dark hole
- [ ] morning star
- [ ] royal
- [ ] yinyang

### Phase 8: Create Additional Abilities
- [ ] Create 5 more unique abilities for variety
- [ ] Ensure all card backs have unique or shared abilities assigned
- [ ] Balance ability power levels with rarity

### Phase 9: Integration & Testing
- [ ] Create ability trigger system in BlackjackGame.cs or rougelike_blackjack.gd
- [ ] Test each ability in gameplay
- [ ] Balance positive/negative effects
- [ ] Adjust chip values, card counts, multipliers based on testing

---

## How to Assign an Ability to a Card Back

1. **Open the card back resource** (e.g., `dna.tres`) in Godot editor
2. **Set the following properties:**
   - `display_name`: User-friendly name (e.g., "DNA Helix")
   - `descriptionP`: Description of positive effect
   - `descriptionN`: Description of negative effect
   - `rarrity`: Choose from enum (COMMON, UNCOMMON, RARE, etc.)
   - `ability`: Click and select the ability script (e.g., `suit_destroyer_ability.gd`)
3. **Save the resource**
4. **Update this tracker** to reflect the changes

---

## Usage in GDScript

To trigger an ability during gameplay:

```gdscript
# Example: Trigger positive ability when card is played
func trigger_card_ability(card: Card, is_positive: bool):
    var card_data = card.card_data as BlackjackStyleRes
    if !card_data or !card_data.ability:
        return

    # Create context dictionary
    var context = {
        "blackjack_game": blackjack_game,
        "card_deck_manager": card_deck_manager,
        "player_hand": card_hand,
        "dealer_hand": dealer_hand,
        "triggering_card": card
    }

    # Call the appropriate ability
    if is_positive:
        card_data.ability.perform_positive(context)
    else:
        card_data.ability.perform_negative(context)
```

---

## Notes

- All abilities use GDScript for better integration with Godot's resource system
- Abilities can access the C# BlackjackGame instance via the context dictionary
- The context pattern allows abilities to interact with the full game state
- Positive effects trigger when conditions favor the player
- Negative effects trigger as balance/drawback or when conditions work against the player

---

**Last Updated**: 2025-11-01
**Maintained By**: Development Team
