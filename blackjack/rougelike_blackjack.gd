extends CanvasLayer

# Card management nodes
@onready var card_deck_manager: CardDeckManager = $CardDeckManager
@onready var card_hand: CardHand = $CardHand
@onready var dealer_hand: CardHand = $DealerHand
@onready var split_hand: CardHand = $SplitHand if has_node("SplitHand") else null
@onready var draw_hand: CardHand = $DrawHand if has_node("DrawHand") else null

# Deck generators for automatic regeneration
@onready var card_deck_generator: DeckGenerator = $CardDeckGenerator if has_node("CardDeckGenerator") else null

# Blackjack game manager (C#)
@onready var blackjack_manager := $BlackjackManager

# Betting dialog
@onready var betting_dialog: CanvasLayer = $BettingDialog

# UI Buttons - Blackjack actions
@onready var hit_button: Button = %HitButton
@onready var stand_button: Button = %StandButton
@onready var deal_button: Button = %DealButton
@onready var double_button: Button = %DoubleButton if has_node("%DoubleButton") else null
@onready var split_button: Button = %SplitButton if has_node("%SplitButton") else null

# UI Buttons - Card Ability actions
@onready var positive_button: Button = %PositiveButton if has_node("%PositiveButton") else null
@onready var negative_button: Button = %NegativeButton if has_node("%NegativeButton") else null
@onready var activate_on_draw_button: Button = %ActivateOnDrawButton if has_node("%ActivateOnDrawButton") else null

# UI Buttons - Draw hand confirmation
@onready var confirm_selection_button: Button = %ConfirmSelectionButton if has_node("%ConfirmSelectionButton") else null

# UI Labels (these need to be added to your scene)
@onready var player_value_label: Label = %PlayerValueLabel if has_node("%PlayerValueLabel") else null
@onready var dealer_value_label: Label = %DealerValueLabel if has_node("%DealerValueLabel") else null
@onready var chips_label: Label = %ChipsLabel if has_node("%ChipsLabel") else null
@onready var bet_label: Label = %BetLabel if has_node("%BetLabel") else null
@onready var result_label: Label = %ResultLabel if has_node("%ResultLabel") else null
@onready var split_value_label: Label = %SplitValueLabel if has_node("%SplitValueLabel") else null

# Game state
var current_bet: int = 100  # Default bet amount
var players_turn: bool = true
var activate_abilities_on_draw: bool = true  # Toggle for activating abilities when cards are drawn

# Draw hand state
var awaiting_card_selection: bool = false  # True when waiting for player to select cards from draw hand
var required_selection_count: int = 0  # Number of cards that must be selected
var selection_action: String = ""  # "deal" or "hit" to track what action we're selecting for
var draw_hand_size: int = draw_hand.max_hand_size if draw_hand else 0:
	set(value):
		draw_hand_size = value
		if draw_hand:
			draw_hand.max_hand_size = value


func _init() -> void:
	CG.def_front_layout = "front_blackjack_style"
	CG.def_back_layout = "back_blackjack_style"


func _ready() -> void:
	# Connect blackjack action buttons
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	deal_button.pressed.connect(_on_deal_pressed)

	if double_button:
		double_button.pressed.connect(_on_double_pressed)
	if split_button:
		split_button.pressed.connect(_on_split_pressed)

	# Connect card ability buttons
	if positive_button:
		positive_button.pressed.connect(_on_positive_pressed)
	if negative_button:
		negative_button.pressed.connect(_on_negative_pressed)
	if activate_on_draw_button:
		activate_on_draw_button.toggled.connect(_on_activate_on_draw_toggled)

	# Connect draw hand confirmation button
	if confirm_selection_button:
		confirm_selection_button.pressed.connect(_on_confirm_selection_pressed)
		confirm_selection_button.visible = false  # Hidden by default

	if draw_hand:
		draw_hand.selection_changed.connect(_update_confirm_button_state)

	# Connect betting dialog signals
	betting_dialog.bet_selected.connect(_on_bet_selected)
	betting_dialog.bet_cancelled.connect(_on_bet_cancelled)

	# Connect BlackjackManager signals
	blackjack_manager.GameStateChanged.connect(_on_game_state_changed)
	blackjack_manager.PlayerBusted.connect(_on_player_busted)
	blackjack_manager.DealerBusted.connect(_on_dealer_busted)
	blackjack_manager.Blackjack.connect(_on_blackjack)
	blackjack_manager.RoundEnded.connect(_on_round_ended)
	blackjack_manager.SwitchedToFirstHand.connect(_on_switched_to_first_hand)

	# Setup game
	CG.def_front_layout = "front_blackjack_style"
	CG.def_back_layout = "back_blackjack_style"
	
	if card_deck_generator:
		card_deck_generator.generate_new_deck()
		card_deck_manager.shuffle()

	# Initialize UI
	_update_ui()
	_set_blackjack_controls_enabled(false)
	deal_button.disabled = false

	# Hide split hand initially
	if split_hand:
		split_hand.visible = false

	# Achievement setup
	await AchievementManager.achievements_loaded
	AchievementManager.reset_achievements()
	await get_tree().create_timer(3).timeout
	AchievementManager.unlock_achievement("game_launch")
	

#region Card Modifier Buttons

func _on_positive_pressed() -> void:
	"""Activate positive abilities of selected cards"""
	var selected_cards = card_hand.selected

	if selected_cards.is_empty():
		print("[ABILITY DEBUG] No cards selected for positive activation!")
		_show_message("No cards selected!")
		return

	print("\n========== ACTIVATING POSITIVE ABILITIES ==========")
	print("[ABILITY DEBUG] Selected %d card(s)" % selected_cards.size())

	var activated_count = 0
	var failed_count = 0

	for card: Card in selected_cards:
		if _activate_card_ability(card, true):
			activated_count += 1
		else:
			failed_count += 1

	print("[ABILITY DEBUG] Successfully activated: %d | Failed: %d" % [activated_count, failed_count])
	print("===================================================\n")

	var message = "Activated %d positive abilities" % activated_count
	if failed_count > 0:
		message += " (%d failed)" % failed_count
	_show_message(message)

	card_hand.clear_selected()


func _on_negative_pressed() -> void:
	"""Activate negative abilities of selected cards"""
	var selected_cards = card_hand.selected

	if selected_cards.is_empty():
		print("[ABILITY DEBUG] No cards selected for negative activation!")
		_show_message("No cards selected!")
		return

	print("\n========== ACTIVATING NEGATIVE ABILITIES ==========")
	print("[ABILITY DEBUG] Selected %d card(s)" % selected_cards.size())

	var activated_count = 0
	var failed_count = 0

	for card: Card in selected_cards:
		if _activate_card_ability(card, false):
			activated_count += 1
		else:
			failed_count += 1

	print("[ABILITY DEBUG] Successfully activated: %d | Failed: %d" % [activated_count, failed_count])
	print("===================================================\n")

	var message = "Activated %d negative abilities" % activated_count
	if failed_count > 0:
		message += " (%d failed)" % failed_count
	_show_message(message)

	card_hand.clear_selected()


func _on_activate_on_draw_toggled(button_pressed: bool) -> void:
	"""Toggle the activate on draw feature"""
	activate_abilities_on_draw = !activate_abilities_on_draw
	if activate_on_draw_button:
		activate_on_draw_button.text = "Activate On Draw: ON" if activate_abilities_on_draw else "Activate On Draw: OFF"
	print("[ABILITY DEBUG] Activate on draw: %s" % ("ENABLED" if activate_abilities_on_draw else "DISABLED"))


func _try_activate_ability_on_draw(card: Card) -> void:
	"""Automatically activate a card's ability based on its color when drawn"""
	if not activate_abilities_on_draw:
		return

	if not card.card_data is BlackjackStyleRes:
		return

	var card_data: BlackjackStyleRes = card.card_data as BlackjackStyleRes

	# Determine if positive or negative based on deck color
	# LIGHT (1) = beige = positive
	# DARK (2) = gray = negative
	var is_positive: bool = false

	match card_data.deck_color:
		1:  # LIGHT (beige)
			is_positive = true
			print("[AUTO-ABILITY] Card '%s' is LIGHT (beige) - activating POSITIVE ability" % card_data.display_name)
		2:  # DARK (gray)
			is_positive = false
			print("[AUTO-ABILITY] Card '%s' is DARK (gray) - activating NEGATIVE ability" % card_data.display_name)
		_:
			print("[AUTO-ABILITY] Card '%s' has no deck color (%d) - skipping" % [card_data.display_name, card_data.deck_color])
			return

	# Activate the ability
	_activate_card_ability(card, is_positive)


func _activate_card_ability(card: Card, is_positive: bool) -> bool:
	"""Helper function to activate a card's ability. Returns true if successful."""
	var ability_type = "POSITIVE" if is_positive else "NEGATIVE"

	# Check if card has a CardBackResource with an ability
	if not card.card_data is BlackjackStyleRes:
		print("[ABILITY DEBUG] ❌ Card '%s' doesn't have a BlackjackStyleRes (has: %s)" % [card.name, card.card_data.get_class()])
		return false

	var card_data: BlackjackStyleRes = card.card_data as BlackjackStyleRes

	if not card_data.ability:
		print("[ABILITY DEBUG] ❌ Card '%s' (%s) doesn't have an ability assigned" % [card.name, card_data.display_name])
		return false

	# Get the ability resource path for debugging
	var ability_path = card_data.ability.resource_path if card_data.ability else "none"
	var ability_name = ability_path.get_file().get_basename() if ability_path != "none" else "unknown"

	print("[ABILITY DEBUG] 🎴 Card: '%s' | Ability: '%s' | Type: %s" % [card_data.display_name, ability_name, ability_type])

	# Store state before ability activation for comparison
	var chips_before = blackjack_manager.PlayerChips
	var player_hand_value_before = blackjack_manager.GetPlayerHandValue()
	var player_hand_size_before = card_hand.cards.size()

	# Get the ability resource (already an instance)
	var ability = card_data.ability

	print(ability.get_class())

	# Prepare the context dictionary
	var context = {
		"blackjack_game": blackjack_manager,
		"player_deck_manager": card_deck_manager,
		"player_hand": card_hand,
		"dealer_hand": dealer_hand,
		"triggering_card": card
	}

	# Call the appropriate ability function
	print("[ABILITY DEBUG] 🔄 Executing %s ability..." % ability_type)
	if is_positive:
		ability.perform_positive(context)
	else:
		ability.perform_negative(context)

	# Show what changed after ability
	var chips_after = blackjack_manager.PlayerChips
	var player_hand_value_after = blackjack_manager.GetPlayerHandValue()
	var player_hand_size_after = card_hand.cards.size()

	print("[ABILITY DEBUG] 📊 Changes:")
	if chips_after != chips_before:
		var chips_diff = chips_after - chips_before
		var diff_symbol = "+" if chips_diff > 0 else ""
		print("   💰 Chips: %d → %d (%s%d)" % [chips_before, chips_after, diff_symbol, chips_diff])
	else:
		print("   💰 Chips: %d (no change)" % chips_before)

	if player_hand_value_after != player_hand_value_before:
		print("   🎯 Hand Value: %d → %d" % [player_hand_value_before, player_hand_value_after])

	if player_hand_size_after != player_hand_size_before:
		var card_diff = player_hand_size_after - player_hand_size_before
		print("   🃏 Hand Size: %d → %d (%+d cards)" % [player_hand_size_before, player_hand_size_after, card_diff])

	print("[ABILITY DEBUG] ✅ %s ability executed successfully!\n" % ability_type)

	# Update UI to reflect any changes
	_update_ui()

	return true

#endregion


#region Blackjack Actions

func _on_deal_pressed() -> void:
	"""Show betting dialog to start a new round"""
	betting_dialog.show_dialog(
		blackjack_manager.PlayerChips,
		blackjack_manager.MinimumBet,
		blackjack_manager.MaximumBet
	)


func _on_bet_selected(bet_amount: int) -> void:
	"""Called when player confirms their bet"""
	if blackjack_manager.StartRound(bet_amount):
		_start_new_round()
	else:
		_show_message("Cannot start round! Check bet and chips.")


func _on_bet_cancelled() -> void:
	"""Called when player cancels betting"""
	_show_message("Betting cancelled.")


func _on_hit_pressed() -> void:
	"""Player hits - select a card from draw hand"""
	if blackjack_manager.PlayerHit():
		# Replenish draw hand if needed (keep it populated)
		if draw_hand and draw_hand.cards.size() < draw_hand_size:
			var needed_cards = draw_hand_size - draw_hand.cards.size()
			var cards = card_deck_manager.draw_cards(needed_cards)
			if cards.size() > 0:
				draw_hand.add_cards(cards)
				for card in cards:
					card.is_front_face = false

		# Start card selection process (need 1 card for hit)
		_start_card_selection(1, "hit")


func _on_stand_pressed() -> void:
	"""Player stands - end turn and dealer plays"""
	blackjack_manager.PlayerStand()
	# Dealer will play automatically via GameStateChanged signal
	_update_ui()


func _on_double_pressed() -> void:
	"""Player doubles down - double bet, select a card from draw hand, then stand"""
	if blackjack_manager.PlayerDouble():
		# Replenish draw hand if needed
		if draw_hand and draw_hand.cards.size() < draw_hand_size:
			var needed_cards = draw_hand_size - draw_hand.cards.size()
			var cards = card_deck_manager.draw_cards(needed_cards)
			if cards.size() > 0:
				draw_hand.add_cards(cards)
				for card in cards:
					card.is_front_face = false

		# Start card selection process (need 1 card for double)
		_start_card_selection(1, "double")


func _on_split_pressed() -> void:
	"""Player splits their hand - separate matching cards into two hands"""
	if blackjack_manager.PlayerSplit():
		# Move second card to split hand
		if split_hand and card_hand.cards.size() > 1:
			var second_card = card_hand.cards[1]
			card_hand.cards.remove_at(1)
			split_hand.add_cards([second_card])
			split_hand.visible = true

			# Replenish draw hand if needed
			if draw_hand and draw_hand.cards.size() < draw_hand_size:
				var needed_cards = draw_hand_size - draw_hand.cards.size()
				var cards = card_deck_manager.draw_cards(needed_cards)
				if cards.size() > 0:
					draw_hand.add_cards(cards)
					for card in cards:
						card.is_front_face = false

			# Start card selection process (need 1 card for split hand)
			_start_card_selection(1, "split")


#endregion

#region Blackjack Game Flow

func _start_new_round() -> void:
	"""Initialize a new blackjack round"""
	# Clear hands
	_clear_all_hands()

	blackjack_manager.SetGameState(2)  # Set state to Dealing
	
	# Deal initial cards
	_deal_initial_cards()

	# Update UI
	_update_ui()

func _deal_initial_cards() -> void:
	"""Deal 2 cards to player using draw hand selection"""
	# Populate the draw hand with cards
	_populate_draw_hand()

	# Start card selection process (need 2 cards for initial deal)
	_start_card_selection(2, "deal")


func _dealer_play() -> void:
	"""Execute dealer's turn following blackjack rules"""
	print("Dealer's turn...")

	# Reveal dealer's hidden card (if applicable)
	var dealer_cards = dealer_hand.cards
	if dealer_cards.size() > 0:
		dealer_cards[1].is_hidden = false

	# Dealer draws until reaching threshold from dealer's separate deck
	while blackjack_manager.DealerShouldHit():
		await get_tree().create_timer(1.0).timeout  # Visual delay

		var cards = card_deck_manager.draw_cards(1)
		if cards.size() > 0:
			dealer_hand.add_cards(cards)
			blackjack_manager.AddDealerCard(cards[0])
			cards[0].card_data.deck_color = BlackjackStyleRes.deck_colors.DARK  # Dealer cards are always dark/gray
			_update_ui()
		else:
			break

	# Complete dealer turn and determine winner
	blackjack_manager.CompleteDealerTurn()


func _clear_all_hands() -> void:
	"""Clear all cards from both hands"""
	# Move player cards to player's discard pile
	for card in card_hand.cards:
		card_deck_manager.add_card_to_discard_pile(card)

	# Move dealer cards to dealer's discard pile
	for card in dealer_hand.cards:
		card_deck_manager.add_card_to_discard_pile(card)

	# Clear split hand if it exists
	if split_hand and split_hand.cards.size() > 0:
		for card in split_hand.cards:
			card_deck_manager.add_card_to_discard_pile(card)
		split_hand.clear_hand()
		split_hand.visible = false

	# Clear hand references
	card_hand.clear_hand()
	dealer_hand.clear_hand()

#endregion


#region BlackjackManager Signal Handlers

func _on_game_state_changed(new_state: int) -> void:
	"""Handle game state changes"""
	print("Game state changed to: ", new_state)

	match new_state:
		0:  # Idle
			_set_blackjack_controls_enabled(false)
			deal_button.disabled = false
			_show_message("Ready for new round")

		1:  # Betting
			_set_blackjack_controls_enabled(false)

		2:  # Dealing
			deal_button.disabled = true
			_set_blackjack_controls_enabled(false)
			_show_message("Dealing cards...")

		3:  # PlayerTurn
			players_turn = true
			_set_blackjack_controls_enabled(true)
			deal_button.disabled = true

			if blackjack_manager.IsPlayingSplitHand():
				_show_message("Playing split hand! Hit or Stand?")
			elif blackjack_manager.HasSplit():
				_show_message("Playing first hand! Hit or Stand?")
			else:
				_show_message("Your turn! Hit or Stand?")

		4:  # DealerTurn
			players_turn = false
			_set_blackjack_controls_enabled(false)
			_show_message("Dealer's turn...")
			_dealer_play()

		5:  # RoundEnd
			_set_blackjack_controls_enabled(false)
			# Keep deal button disabled until ResetRound() transitions to Idle state
			# This prevents the rapid-deal bug where pressing deal during the 3-second
			# delay causes the new round to be reset, losing the player's bet

		6:  # GameOver
			_set_blackjack_controls_enabled(false)
			_show_message("Game Over! Out of chips!")
	_update_ui()


func _on_player_busted() -> void:
	"""Player exceeded 21"""
	print("Player busted!")
	_show_message("BUST! You went over 21!")


func _on_dealer_busted() -> void:
	"""Dealer exceeded 21"""
	print("Dealer busted!")
	_show_message("Dealer BUST! You win!")


func _on_blackjack(is_player: bool) -> void:
	"""Someone got a blackjack (21 with 2 cards)"""
	if is_player:
		_show_message("🃏 BLACKJACK! 🃏")
	else:
		_show_message("Dealer has Blackjack!")


func _on_round_ended(result: int, payout: int) -> void:
	"""Round has ended, show results"""
	var result_text = ""

	match result:
		1:  # PlayerWin
			result_text = "You Win!"
		2:  # DealerWin
			result_text = "Dealer Wins"
		3:  # Push
			result_text = "Push - It's a Tie!"
		4:  # PlayerBlackjack
			result_text = "🃏 BLACKJACK! You Win! 🃏"
		5:  # PlayerBust
			result_text = "Bust! You Lose"
		6:  # DealerBust
			result_text = "Dealer Bust! You Win!"

	var message = "%s\nPayout: %d chips\nTotal Chips: %d" % [
		result_text,
		payout,
		blackjack_manager.PlayerChips
	]

	_show_message(message)
	_update_ui()

	# Prepare for next round after delay
	await get_tree().create_timer(3.0).timeout
	blackjack_manager.ResetRound()


func _on_switched_to_first_hand() -> void:
	"""Switched from split hand to first hand"""
	print("Switching to first hand")
	_show_message("Playing first hand! Hit or Stand?")
	_update_ui()

#endregion


#region Draw Hand System

func _populate_draw_hand() -> void:
	"""Fill the draw hand with cards face-down for selection"""
	if not draw_hand:
		return

	# Clear any existing cards in draw hand
	draw_hand.clear_selected()

	# Draw cards to populate the draw hand
	var cards = card_deck_manager.draw_cards(draw_hand.get_remaining_space())
	if cards.size() > 0:
		for card in cards:
			draw_hand.add_card(card)
			card.is_hidden = true
			await get_tree().create_timer(0.2).timeout  # Small delay for visual effect


func _start_card_selection(count: int, action: String) -> void:
	"""Begin waiting for player to select cards from draw hand"""
	if not draw_hand:
		return

	awaiting_card_selection = true
	required_selection_count = count
	selection_action = action

	# Clear any previous selections
	draw_hand.clear_selected()

	# Update draw hand max_selected to match required count
	draw_hand.max_selected = count

	# Show confirmation button
	if confirm_selection_button:
		confirm_selection_button.visible = true
		confirm_selection_button.disabled = true  # Disabled until correct number selected

	# Disable game action buttons during selection
	_set_blackjack_controls_enabled(false)
	
	_update_confirm_button_state()

	# Show message
	_show_message("Select %d card%s from draw hand" % [count, "s" if count > 1 else ""])


func _on_confirm_selection_pressed() -> void:
	"""Handle confirmation of card selection from draw hand"""
	if not awaiting_card_selection or not draw_hand:
		return

	var selected_cards = draw_hand.selected
	
	draw_hand.clear_selected()

	# Validate selection count
	if selected_cards.size() != required_selection_count:
		_show_message("Please select exactly %d card%s!" % [required_selection_count, "s" if required_selection_count > 1 else ""])
		return

	# Process based on action type
	match selection_action:
		"deal":
			_complete_deal_with_selected_cards(selected_cards)
		"hit":
			_complete_hit_with_selected_card(selected_cards[0])
		"double":
			_complete_double_with_selected_card(selected_cards[0])
		"split":
			_complete_split_with_selected_card(selected_cards[0])

	# Reset selection state
	awaiting_card_selection = false
	required_selection_count = 0
	draw_hand.max_selected = 0
	selection_action = ""
	
	if blackjack_manager.CurrentState == 3:
		_set_blackjack_controls_enabled(true)
		_show_message("Your turn! Hit or Stand?")
	else:
		_set_blackjack_controls_enabled(false)
	
	# Hide confirmation button
	if confirm_selection_button:
		confirm_selection_button.visible = false


func _transfer_cards_to_play_hand(cards: Array[Card], target_hand: CardHand = null) -> void:
	"""Transfer selected cards from draw hand to play hand"""
	if not target_hand:
		target_hand = card_hand
		
	_show_message("Transferring %d card%s to play hand" % [cards.size() + 1, "s" if cards.size() > 1 else ""])

	for card in cards:
		# Remove from draw hand
		if draw_hand and draw_hand._cards.has(card):
			draw_hand.remove_card(card, target_hand)

		# Add to target hand
		target_hand.add_card(card)

		# Flip card face-up
		card.flip()
		
		card.is_hidden = false

		# Register with blackjack manager
		blackjack_manager.AddPlayerCard(card)

		# Activate ability if toggle is enabled
		_try_activate_ability_on_draw(card)


func _complete_deal_with_selected_cards(selected_cards: Array[Card]) -> void:
	"""Complete the initial deal using selected cards from draw hand"""
	# Transfer cards one by one with delay
	for card in selected_cards:
		_transfer_cards_to_play_hand([card])
		await get_tree().create_timer(0.5).timeout
		
	_populate_draw_hand()

	# Deal dealer cards
	var dealer_cards = card_deck_manager.draw_cards(2)
	if dealer_cards.size() > 0:
		var i := 0
		for card in dealer_cards:
			dealer_hand.add_card(card)
			blackjack_manager.AddDealerCard(card)
			card.card_data.deck_color = BlackjackStyleRes.deck_colors.DARK  # Dealer cards are always dark/gray
			if i > 0:
				card.is_hidden = true  # Hide dealer's second card
			else:
				card.flip()
			await get_tree().create_timer(0.5).timeout
			i += 1

	# Begin player's turn
	blackjack_manager.BeginPlayerTurn()


func _complete_hit_with_selected_card(card: Card) -> void:
	"""Complete a hit action using selected card from draw hand"""
	# Determine target hand (split or main)
	var target_hand = card_hand
	if blackjack_manager.IsPlayingSplitHand() and split_hand:
		target_hand = split_hand

	# Transfer the card
	_transfer_cards_to_play_hand([card], target_hand)
	
	_populate_draw_hand()

	# Update UI
	_update_ui()


func _complete_double_with_selected_card(card: Card) -> void:
	"""Complete a double down action using selected card from draw hand"""
	# Determine target hand (split or main)
	var target_hand = card_hand
	if blackjack_manager.IsPlayingSplitHand() and split_hand:
		target_hand = split_hand

	# Transfer the card
	_transfer_cards_to_play_hand([card], target_hand)
	
	_populate_draw_hand()

	# Update UI
	_update_ui()

	# Automatically stand after doubling
	await get_tree().create_timer(0.5).timeout
	blackjack_manager.PlayerStand()
	_update_ui()


func _complete_split_with_selected_card(card: Card) -> void:
	"""Complete a split action by adding selected card to the split hand"""
	# Add card to split hand (which is the active hand when splitting)
	if split_hand:
		_transfer_cards_to_play_hand([card], split_hand)
		
	_populate_draw_hand()

	# Update UI
	_update_ui()


func _update_confirm_button_state() -> void:
	"""Update the confirm button enabled state based on selection count"""
	if not confirm_selection_button or not awaiting_card_selection or not draw_hand:
		return

	var selected_count = draw_hand.selected.size()
	confirm_selection_button.disabled = (selected_count != required_selection_count)

	# Update button text to show progress
	if required_selection_count > 0:
		confirm_selection_button.text = "Confirm (%d/%d)" % [selected_count, required_selection_count]

#endregion


#region UI Helpers

func _update_ui() -> void:
	"""Update all UI labels with current game state"""
	if blackjack_manager.CurrentState in [0, 1, 2]:
		if player_value_label:
			player_value_label.text = ""
		if dealer_value_label:
			dealer_value_label.text = ""
	else:
		if player_value_label:
			player_value_label.text = "Player: %d" % blackjack_manager.GetPlayerHandValue()

		if dealer_value_label:
			if players_turn:
				dealer_value_label.text = "Dealer: %d" % blackjack_manager.GetVisibleDealerHandValue()
			else:
				dealer_value_label.text = "Dealer: %d" % blackjack_manager.GetDealerHandValue()

	if chips_label:
		chips_label.text = "Chips: %d" % blackjack_manager.PlayerChips

	if bet_label:
		var total_bet = blackjack_manager.CurrentBet
		if blackjack_manager.HasSplit():
			# Split means double the bet (one per hand)
			bet_label.text = "Bet: %d (x2 hands)" % (total_bet / 2)
		else:
			bet_label.text = "Bet: %d" % total_bet

	# Update split hand label if split is active
	if split_value_label:
		if blackjack_manager.HasSplit():
			split_value_label.text = "Split: %d" % blackjack_manager.GetSplitHandValue()
			split_value_label.visible = true
		else:
			split_value_label.visible = false

	# Update button states
	if double_button:
		double_button.disabled = !blackjack_manager.CanDouble()
	if split_button:
		split_button.disabled = !blackjack_manager.CanSplit()

	# Update confirm button state for draw hand selection
	_update_confirm_button_state()


func _show_message(message: String) -> void:
	"""Display a message to the player"""
	print(message)
	if result_label:
		result_label.text = message


func _set_blackjack_controls_enabled(enabled: bool) -> void:
	"""Enable/disable hit and stand buttons"""
	hit_button.disabled = !enabled
	stand_button.disabled = !enabled
	# Update double and split button states
	if double_button:
		double_button.disabled = !blackjack_manager.CanDouble() if enabled else true
	if split_button:
		split_button.disabled = !blackjack_manager.CanSplit() if enabled else true

#endregion
