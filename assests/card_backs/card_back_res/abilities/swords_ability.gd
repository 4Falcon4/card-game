## Swords Card Back Ability
## Positive: Swap hands with the dealer
## Negative: Both players discard all cards and draw 2 new cards
extends CardAbility
class_name SwordsAbility

## Swap player and dealer hands
func perform_positive(context: Dictionary) -> void:
	var player_hand = context.get("player_hand")
	var dealer_hand = context.get("dealer_hand")
	var blackjack_game = context.get("blackjack_game")

	if !player_hand or !dealer_hand or !blackjack_game:
		push_error("SwordsAbility: Missing required context")
		return

	# TODO: Implement hand swapping logic
	# This requires access to the C# BlackjackManager methods
	print("SwordsAbility: Hand swap effect (implementation needs BlackjackManager integration)")


## Discard all cards and draw 2 new ones for both players
func perform_negative(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")
	var player_hand = context.get("player_hand")
	var dealer_hand = context.get("dealer_hand")
	var blackjack_game = context.get("blackjack_game")

	if !card_deck_manager or !player_hand or !dealer_hand or !blackjack_game:
		push_error("SwordsAbility: Missing required context")
		return

	# Discard all cards
	player_hand.discard_all_cards()
	dealer_hand.discard_all_cards()

	# Draw 2 new cards for player
	var player_cards = card_deck_manager.deal_cards(2)
	if player_cards.size() > 0:
		player_hand.add_cards(player_cards)

	# Draw 2 new cards for dealer
	var dealer_cards = card_deck_manager.deal_cards(2)
	if dealer_cards.size() > 0:
		dealer_hand.add_cards(dealer_cards)

	print("SwordsAbility: Both players discarded and drew 2 new cards")
