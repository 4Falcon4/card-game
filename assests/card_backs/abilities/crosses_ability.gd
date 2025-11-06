## Crosses Card Back Ability
## Positive: Gain $1 for each playing card on table when dealer stands
## Negative: Draw 1 playing card for each card already played
extends CardAbility

## Gain chips based on total cards on table
static func perform_positive(context: Dictionary) -> void:
	var blackjack_game = context.get("blackjack_game")
	var player_hand = context.get("player_hand")
	var dealer_hand = context.get("dealer_hand")

	if !blackjack_game or !player_hand or !dealer_hand:
		push_error("CrossesAbility: Missing required context")
		return

	# Count all cards on the table
	var total_cards = player_hand.cards.size() + dealer_hand.cards.size()
	var gain = total_cards
	blackjack_game.PlayerChips += gain

	print("CrossesAbility: Gained %d chips from %d cards on table! Total: %d" % [gain, total_cards, blackjack_game.PlayerChips])


## Draw additional cards based on cards already played
static func perform_negative(context: Dictionary) -> void:
	var card_deck_manager = context.get("card_deck_manager")
	var player_hand = context.get("player_hand")

	if !card_deck_manager or !player_hand:
		push_error("CrossesAbility: Missing required context")
		return

	# Draw 1 card for each card already in hand
	var cards_to_draw = player_hand.cards.size()

	if cards_to_draw > 0:
		var drawn_cards = card_deck_manager.deal_cards(cards_to_draw)
		if drawn_cards.size() > 0:
			player_hand.add_cards(drawn_cards)
			print("CrossesAbility: Drew %d additional cards! Hand size: %d" % [drawn_cards.size(), player_hand.cards.size()])
