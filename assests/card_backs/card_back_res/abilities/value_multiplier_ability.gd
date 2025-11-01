## Doubles the value of all cards in your hand (Positive)
## Halves the value of all cards in your hand (Negative)
## Note: This uses the card's modifier system if available
extends CardAbility
class_name ValueMultiplierAbility

@export var positive_multiplier: float = 2.0
@export var negative_multiplier: float = 0.5

## Increases card values in the player's hand
func perform_positive(context: Dictionary) -> void:
	var player_hand = context.get("player_hand")

	if !player_hand:
		push_error("ValueMultiplierAbility: Missing player_hand in context")
		return

	var cards = player_hand.cards
	var modified_count = 0

	for card in cards:
		if card.card_data.has("value"):
			# Store original value if not already stored
			if !card.card_data.has("original_value"):
				card.card_data.set("original_value", card.card_data.value)

			# Apply multiplier
			var new_value = int(card.card_data.value * positive_multiplier)
			card.card_data.value = new_value
			card.refresh_layout()
			modified_count += 1

	print("ValueMultiplierAbility: Multiplied value of %d cards by %.1fx" % [modified_count, positive_multiplier])


## Decreases card values in the player's hand
func perform_negative(context: Dictionary) -> void:
	var player_hand = context.get("player_hand")

	if !player_hand:
		push_error("ValueMultiplierAbility: Missing player_hand in context")
		return

	var cards = player_hand.cards
	var modified_count = 0

	for card in cards:
		if card.card_data.has("value"):
			# Store original value if not already stored
			if !card.card_data.has("original_value"):
				card.card_data.set("original_value", card.card_data.value)

			# Apply multiplier (halve the value, minimum 1)
			var new_value = max(1, int(card.card_data.value * negative_multiplier))
			card.card_data.value = new_value
			card.refresh_layout()
			modified_count += 1

	print("ValueMultiplierAbility: Multiplied value of %d cards by %.1fx" % [modified_count, negative_multiplier])
