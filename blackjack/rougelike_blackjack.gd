extends CanvasLayer

# Preload card back resource type
const CardBackResource = preload("res://assests/card_backs/card_back_res/card_back_resource.gd")

# Card management nodes
@onready var card_deck_manager: CardDeckManager = $CardDeckManager
@onready var card_hand: CardHand = $CardHand
@onready var dealer_hand: CardHand = $DealerHand

# Blackjack game manager (C#)
@onready var blackjack_manager := $BlackjackManager

# UI Buttons - Blackjack actions
@onready var hit_button: Button = %HitButton
@onready var stand_button: Button = %StandButton	
@onready var deal_button: Button = %DealButton

# UI Labels (these need to be added to your scene)
@onready var player_value_label: Label = %PlayerValueLabel if has_node("%PlayerValueLabel") else null
@onready var dealer_value_label: Label = %DealerValueLabel if has_node("%DealerValueLabel") else null
@onready var chips_label: Label = %ChipsLabel if has_node("%ChipsLabel") else null
@onready var bet_label: Label = %BetLabel if has_node("%BetLabel") else null
@onready var result_label: Label = %ResultLabel if has_node("%ResultLabel") else null

# Game state
var hand_size: int
var current_bet: int = 100  # Default bet amount
var players_turn: bool = true

# Card Back System
var current_card_back: CardBackResource
var test_mode: bool = true  # Set to false to disable test mode
var available_card_backs: Array = []


func _init() -> void:
	CG.def_front_layout = "front_blackjack_style"
	CG.def_back_layout = "back_blackjack_style"


func _ready() -> void:
	# Connect blackjack action buttons
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	deal_button.pressed.connect(_on_deal_pressed)

	# Connect BlackjackManager signals
	blackjack_manager.GameStateChanged.connect(_on_game_state_changed)
	blackjack_manager.PlayerBusted.connect(_on_player_busted)
	blackjack_manager.DealerBusted.connect(_on_dealer_busted)
	blackjack_manager.Blackjack.connect(_on_blackjack)
	blackjack_manager.RoundEnded.connect(_on_round_ended)

	# Setup game
	CG.def_front_layout = "front_blackjack_style"
	CG.def_back_layout = "back_blackjack_style"

	hand_size = card_hand.max_hand_size
	card_deck_manager.setup()

	# Initialize card back system
	_initialize_card_back_system()

	# Initialize UI
	_update_ui()
	_set_blackjack_controls_enabled(false)
	deal_button.disabled = false

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
	"""Start a new blackjack round"""
	if blackjack_manager.StartRound(current_bet):
		_start_new_round()
	else:
		_show_message("Cannot start round! Check bet and chips.")


func _on_hit_pressed() -> void:
	"""Player hits - draw another card"""
	if blackjack_manager.PlayerHit():
		var cards = card_deck_manager.draw_cards(1)
		if cards.size() > 0:
			card_hand.add_cards(cards)
			blackjack_manager.AddPlayerCard(cards[0])
			_update_ui()
			
			# Trigger card back hit ability
			_trigger_card_back_hit()


func _on_stand_pressed() -> void:
	"""Player stands - end turn and dealer plays"""
	# Trigger card back stand ability
	var stand_result = _trigger_card_back_stand()
	if stand_result != 0:
		blackjack_manager.PlayerChips += stand_result
		if stand_result > 0:
			_show_message("Card back bonus: +%d chips" % stand_result)
		else:
			_show_message("Card back penalty: %d chips" % abs(stand_result))
		_update_ui()
	
	blackjack_manager.PlayerStand()
	# Dealer will play automatically via GameStateChanged signal


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
	
	# Trigger card back deal ability
	_trigger_card_back_deal()

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
	# Trigger card back bust ability
	_trigger_card_back_bust()


func _on_dealer_busted() -> void:
	"""Dealer exceeded 21"""
	print("Dealer busted!")
	_show_message("Dealer BUST! You win!")


func _on_blackjack(is_player: bool) -> void:
	"""Someone got a blackjack (21 with 2 cards)"""
	if is_player:
		_show_message("🃏 BLACKJACK! 🃏")
		# Trigger card back blackjack ability
		_trigger_card_back_blackjack()
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

	# Trigger card back round end ability
	var bonus_money = _trigger_card_back_round_end()
	if bonus_money != 0:
		blackjack_manager.PlayerChips += bonus_money
		if bonus_money > 0:
			_show_message("Card back bonus: +%d chips" % bonus_money)
		else:
			_show_message("Card back penalty: %d chips" % abs(bonus_money))
		_update_ui()

	# Prepare for next round after delay
	await get_tree().create_timer(3.0).timeout
	blackjack_manager.ResetRound()

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
		bet_label.text = "Bet: %d" % current_bet


func _show_message(message: String) -> void:
	"""Display a message to the player"""
	print(message)
	if result_label:
		result_label.text = message


func _set_blackjack_controls_enabled(enabled: bool) -> void:
	"""Enable/disable hit and stand buttons"""
	hit_button.disabled = !enabled
	stand_button.disabled = !enabled

#endregion

#region Card Back Abilities System

func _initialize_card_back_system() -> void:
	"""Initialize card back system"""
	_create_all_card_back_resources()
	
	if test_mode:
		current_card_back = available_card_backs[0]  # Test card back
		print("=== TEST MODE ACTIVATED ===")
	else:
		current_card_back = available_card_backs[1]  # Alchemy card back
	
	print("Current card back: ", current_card_back.display_name)

func _create_all_card_back_resources() -> void:
	"""Create test card backs"""
	# Test Card Back
	var test_back = CardBackResource.new()
	test_back.display_name = "Test Card Back"
	test_back.descriptionP = "Test all ability triggers"
	available_card_backs.append(test_back)
	
	# Alchemy Card Back
	var alchemy_back = CardBackResource.new()
	alchemy_back.display_name = "Alchemy"
	alchemy_back.descriptionP = "Gain money equal to hand value/2"
	alchemy_back.descriptionN = "Lose money equal to number of cards when standing"
	alchemy_back.rarrity = CardBackResource.Rarrity.COMMON
	available_card_backs.append(alchemy_back)
	
	# Candle Card Back
	var candle_back = CardBackResource.new()
	candle_back.display_name = "Candle"
	candle_back.descriptionP = "Pick from 2 random card effects"
	candle_back.descriptionN = "Activate random negative effect"
	candle_back.rarrity = CardBackResource.Rarrity.UNCOMMON
	available_card_backs.append(candle_back)
	
	# Crosses Card Back
	var crosses_back = CardBackResource.new()
	crosses_back.display_name = "Crosses"
	crosses_back.descriptionP = "Gain $1 for each playing card on table when dealer stands"
	crosses_back.descriptionN = "Draw 1 playing card for each card already played"
	crosses_back.rarrity = CardBackResource.Rarrity.UNCOMMON
	available_card_backs.append(crosses_back)
	
	# Eyes Card Back
	var eyes_back = CardBackResource.new()
	eyes_back.display_name = "Eyes"
	eyes_back.descriptionP = "See next 3 cards, choose which remains and which get discarded"
	eyes_back.descriptionN = "Draw a playing card face down"
	eyes_back.rarrity = CardBackResource.Rarrity.RARE
	available_card_backs.append(eyes_back)
	
	# ToeBeans Card Back
	var toebeans_back = CardBackResource.new()
	toebeans_back.display_name = "Toe Beans"
	toebeans_back.descriptionP = "While in your hand, see incoming card and card effect"
	toebeans_back.descriptionN = "Becomes next card drawn, shuffle 2 into your deck and destroy itself"
	toebeans_back.rarrity = CardBackResource.Rarrity.RARE
	available_card_backs.append(toebeans_back)
	
	# Swords Card Back
	var swords_back = CardBackResource.new()
	swords_back.display_name = "Swords"
	swords_back.descriptionP = "Swap hands with the dealer"
	swords_back.descriptionN = "Both players discard all cards and draw 2 new cards"
	swords_back.rarrity = CardBackResource.Rarrity.RARE
	available_card_backs.append(swords_back)
	
	# Illusion Card Back
	var illusion_back = CardBackResource.new()
	illusion_back.display_name = "Illusion"
	illusion_back.descriptionP = "If you bust this round, make your hand blank"
	illusion_back.descriptionN = "Make your hand blank, immediately stand"
	illusion_back.rarrity = CardBackResource.Rarrity.LEGENDARY
	available_card_backs.append(illusion_back)
	
	print("Created ", available_card_backs.size(), " card backs")

func _trigger_card_back_round_end() -> int:
	"""Trigger card back round end ability"""
	if current_card_back:
		return _execute_card_back_ability("round_end")
	return 0

func _trigger_card_back_stand() -> int:
	"""Trigger card back stand ability"""
	if current_card_back:
		return _execute_card_back_ability("stand")
	return 0

func _trigger_card_back_hit() -> void:
	"""Trigger card back hit ability"""
	if current_card_back:
		_execute_card_back_ability("hit")

func _trigger_card_back_deal() -> void:
	"""Trigger card back deal ability"""
	if current_card_back:
		_execute_card_back_ability("deal")

func _trigger_card_back_bust() -> void:
	"""Trigger card back bust ability"""
	if current_card_back:
		_execute_card_back_ability("bust")

func _trigger_card_back_blackjack() -> void:
	"""Trigger card back blackjack ability"""
	if current_card_back:
		_execute_card_back_ability("blackjack")

func _execute_card_back_ability(trigger_type: String) -> int:
	"""Execute card back ability based on card back name and trigger type"""
	if not current_card_back:
		return 0
	
	var card_name = current_card_back.display_name
	var hand_value = blackjack_manager.GetPlayerHandValue()
	var cards_count = card_hand.cards.size()
	
	match card_name:
		"Test Card Back":
			match trigger_type:
				"round_end":
					print("Test: Round end ability")
					return 10
				"stand":
					print("Test: Stand ability")
					return -5
				"hit", "deal", "bust", "blackjack":
					print("Test: ", trigger_type, " ability")
					return 0
		
		"Alchemy":
			match trigger_type:
				"round_end":
					var gain = hand_value / 2
					print("Alchemy: Gained ", gain, " from hand value ", hand_value)
					return gain
				"stand":
					var loss = -cards_count
					print("Alchemy: Lost ", abs(loss), " from ", cards_count, " cards")
					return loss
				_:
					return 0
		
		"Candle":
			match trigger_type:
				"round_end":
					var random_effect = randi() % 21 - 10  # -10 to +10
					print("Candle: Random effect: ", random_effect)
					return random_effect
				"deal":
					print("Candle: Choose from 2 random effects")
					return 0
				_:
					return 0
		
		"Crosses":  # 修正缩进
			match trigger_type:
				"round_end":
					var total_cards = card_hand.cards.size() + dealer_hand.cards.size()
					var gain = total_cards
					print("Crosses: Gained ", gain, " from ", total_cards, " cards on table")
					return gain
				_:
					return 0
		
		"Eyes":
			match trigger_type:
				"deal":
					print("Eyes: Preview next 3 cards")
					return 0
				"hit":
					print("Eyes: Drawing face down card")
					return 0
				_:
					return 0
		
		"Toe Beans":
			match trigger_type:
				"deal":
					print("Toe Beans: Special effect activated")
					return 0
				"hit":
					print("Toe Beans: Preview next card and effect")
					return 0
				_:
					return 0
		
		"Swords":
			match trigger_type:
				"stand":
					print("Swords: Hand swap effect triggered")
					return 0
				_:
					return 0
		
		"Illusion":
			match trigger_type:
				"bust":
					print("Illusion: Hand becomes blank (bust prevention)")
					return 0
				"stand":
					print("Illusion: Immediate stand with blank hand")
					return 0
				_:
					return 0  # 添加这行
	
	return 0

func switch_card_back(card_back_index: int) -> void:
	"""Switch to different card back"""
	if card_back_index >= 0 and card_back_index < available_card_backs.size():
		current_card_back = available_card_backs[card_back_index]
		print("Switched to card back: ", current_card_back.display_name)
		_show_message("Switched to: " + current_card_back.display_name)

# Test function: press number keys to switch card backs
func _input(event):
	if test_mode and event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_8:
			var index = event.keycode - KEY_1
			if index < available_card_backs.size():
				switch_card_back(index)

#endregion
