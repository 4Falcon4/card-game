extends CanvasLayer

# Card management nodes
@onready var card_deck_manager: CardDeckManager = $PlayerDeckManager
@onready var card_hand: CardHand = $CardHand
@onready var dealer_hand: CardHand = $DealerHand
@onready var split_hand: CardHand = $SplitHand if has_node("SplitHand") else null

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

# UI Labels (these need to be added to your scene)
@onready var player_value_label: Label = %PlayerValueLabel if has_node("%PlayerValueLabel") else null
@onready var dealer_value_label: Label = %DealerValueLabel if has_node("%DealerValueLabel") else null
@onready var chips_label: Label = %ChipsLabel if has_node("%ChipsLabel") else null
@onready var bet_label: Label = %BetLabel if has_node("%BetLabel") else null
@onready var result_label: Label = %ResultLabel if has_node("%ResultLabel") else null
@onready var split_value_label: Label = %SplitValueLabel if has_node("%SplitValueLabel") else null

# Game state
var hand_size: int
var current_bet: int = 100  # Default bet amount
var players_turn: bool = true


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

	hand_size = card_hand.max_hand_size
	card_deck_manager.setup()

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

func _on_gold_pressed() -> void:
	for card: Card in card_hand.selected:
		card.card_data.current_modiffier = 1
		card.refresh_layout()
	card_hand.clear_selected()


func _on_silv_pressed() -> void:
	for card: Card in card_hand.selected:
		card.card_data.current_modiffier = 2
		card.refresh_layout()
	card_hand.clear_selected()


func _on_none_pressed() -> void:
	for card: Card in card_hand.selected:
		card.card_data.current_modiffier = 0
		card.refresh_layout()
	card_hand.clear_selected()

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
	"""Player hits - draw another card"""
	if blackjack_manager.PlayerHit():
		var cards = card_deck_manager.draw_cards(1)
		if cards.size() > 0:
			# Add card to correct hand
			if blackjack_manager.IsPlayingSplitHand() and split_hand:
				split_hand.add_cards(cards)
			else:
				card_hand.add_cards(cards)
			blackjack_manager.AddPlayerCard(cards[0])
			_update_ui()


func _on_stand_pressed() -> void:
	"""Player stands - end turn and dealer plays"""
	blackjack_manager.PlayerStand()
	# Dealer will play automatically via GameStateChanged signal
	_update_ui()


func _on_double_pressed() -> void:
	"""Player doubles down - double bet, draw one card, then stand"""
	if blackjack_manager.PlayerDouble():
		# Draw one card
		var cards = card_deck_manager.draw_cards(1)
		if cards.size() > 0:
			if blackjack_manager.IsPlayingSplitHand() and split_hand:
				split_hand.add_cards(cards)
			else:
				card_hand.add_cards(cards)
			blackjack_manager.AddPlayerCard(cards[0])
			_update_ui()

		# Automatically stand after doubling
		await get_tree().create_timer(0.5).timeout
		blackjack_manager.PlayerStand()
		_update_ui()


func _on_split_pressed() -> void:
	"""Player splits their hand - separate matching cards into two hands"""
	if blackjack_manager.PlayerSplit():
		# Move second card to split hand
		if split_hand and card_hand.cards.size() > 1:
			var second_card = card_hand.cards[1]
			card_hand.cards.remove_at(1)
			split_hand.add_cards([second_card])
			split_hand.visible = true

			# Draw a card for the split hand (playing this hand first)
			var cards = card_deck_manager.draw_cards(1)
			if cards.size() > 0:
				split_hand.add_cards(cards)
				blackjack_manager.AddPlayerCard(cards[0])

			_update_ui()


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
	"""Deal 2 cards to player and 2 to dealer"""
	# Deal 2 cards to player
	var player_cards = card_deck_manager.draw_cards(2)
	if player_cards.size() > 0:
		var i := 0
		for card in player_cards:
			card_hand.add_card(card)
			blackjack_manager.AddPlayerCard(card)
			card.flip()
			await get_tree().create_timer(0.5).timeout  # Small delay between deals

	# Deal 2 cards to dealer (1 face down)
	var dealer_cards = card_deck_manager.draw_cards(2)
	if dealer_cards.size() > 0:
		var i := 0
		for card in dealer_cards:
			dealer_hand.add_card(card)
			blackjack_manager.AddDealerCard(card)
			if i > 0:
				card.is_hidden = true  # Hide dealer's second card
			else:
				card.flip()
			await get_tree().create_timer(0.5).timeout  # Small delay between deals
			i += 1
			

	# Begin player's turn
	blackjack_manager.BeginPlayerTurn()


func _dealer_play() -> void:
	"""Execute dealer's turn following blackjack rules"""
	print("Dealer's turn...")

	# Reveal dealer's hidden card (if applicable)
	var dealer_cards = dealer_hand.cards
	if dealer_cards.size() > 0:
		dealer_cards[1].is_hidden = false

	# Dealer draws until reaching threshold
	while blackjack_manager.DealerShouldHit():
		await get_tree().create_timer(1.0).timeout  # Visual delay

		var cards = card_deck_manager.draw_cards(1)
		if cards.size() > 0:
			dealer_hand.add_cards(cards)
			blackjack_manager.AddDealerCard(cards[0])
			_update_ui()
		else:
			break

	# Complete dealer turn and determine winner
	blackjack_manager.CompleteDealerTurn()


func _clear_all_hands() -> void:
	"""Clear all cards from both hands"""
	# Move cards to discard
	for card in card_hand.cards:
		card_deck_manager.add_card_to_discard_pile(card)
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
