## Converts random cards in hand to Aces (Positive)
## Converts all Aces in hand to a random value (Negative)
extends CardAbility
class_name AceMasterAbility

@export var cards_to_convert_to_ace: int = 2
@export var ace_replacement_min: int = 5
@export var ace_replacement_max: int = 10

## Converts random non-Ace cards to Aces
func perform_positive(context: Dictionary) -> void:
	var player_hand = context.get("player_hand")

	if !player_hand:
		push_error("AceMasterAbility: Missing player_hand in context")
		return

	var cards = player_hand.cards
	var non_ace_cards: Array[Card] = []

	# Find all non-Ace cards
	for card in cards:
		if card.card_data.value != 1:
			non_ace_cards.append(card)

	if non_ace_cards.is_empty():
		print("AceMasterAbility: All cards are already Aces!")
		return

	# Shuffle and convert first N cards to Aces
	non_ace_cards.shuffle()
	var conversion_count = min(cards_to_convert_to_ace, non_ace_cards.size())

	for i in range(conversion_count):
		var card = non_ace_cards[i]
		card.card_data.value = 1  # Ace value
		card.refresh_layout()

	print("AceMasterAbility: Converted %d cards to Aces" % conversion_count)


## Converts all Aces to random values
func perform_negative(context: Dictionary) -> void:
	var player_hand = context.get("player_hand")

	if !player_hand:
		push_error("AceMasterAbility: Missing player_hand in context")
		return

	var cards = player_hand.cards
	var ace_count = 0

	for card in cards:
		if card.card_data.value == 1:  # Is an Ace
			# Convert to random value
			var new_value = randi_range(ace_replacement_min, ace_replacement_max)
			card.card_data.value = new_value
			card.refresh_layout()
			ace_count += 1

	if ace_count > 0:
		print("AceMasterAbility: Converted %d Aces to random values" % ace_count)
	else:
		print("AceMasterAbility: No Aces in hand to convert")
