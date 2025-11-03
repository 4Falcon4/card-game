## Abstract base class for card back abilities in the blackjack roguelike.
## Each card back can have a positive and negative effect that triggers during gameplay.
##
## To create a new ability:
## 1. Create a new GDScript file extending CardAbility
## 2. Implement perform_positive() and perform_negative()
## 3. Assign the script to a CardBackResource
@icon("uid://cvwcyhqx6fvdk")
@abstract
class_name CardAbility extends Script

## Called when the positive effect of the card ability is triggered.
## @param context: Dictionary containing game state information:
##   - "blackjack_game": Reference to the BlackjackGame C# instance
##   - "player_deck_manager": Reference to the CardDeckManager
##   - "dealer_deck_manager": Reference to the CardDeckManager
##   - "player_hand": Reference to the player's CardHand
##   - "dealer_hand": Reference to the dealer's CardHand
##   - "triggering_card": The Card that triggered this ability
@abstract func perform_positive(context: Dictionary) -> void

## Called when the negative effect of the card ability is triggered.
## @param context: Dictionary containing game state information (same as perform_positive)
@abstract func perform_negative(context: Dictionary) -> void
