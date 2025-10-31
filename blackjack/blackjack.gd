extends Node2D

# Simple Blackjack game (text-based version)
# All comments in English

var deck := []
var dealer_hand := []
var player_hand := []
var game_over := false

@onready var dealer_label = $DealerLabel
@onready var dealer_cards = $DealerCards
@onready var player_label = $PlayerLabel
@onready var player_cards = $PlayerCards
@onready var hit_button = $HitButton
@onready var stand_button = $StandButton
@onready var reset_button = $ResetButton
@onready var result_label = $ResultLabel

func _ready():
	hit_button.pressed.connect(on_hit)
	stand_button.pressed.connect(on_stand)
	reset_button.pressed.connect(on_reset)
	reset_game()

func build_deck() -> Array:
	var suits = ["♠", "♥", "♦", "♣"]
	var ranks = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
	var new_deck = []
	for s in suits:
		for r in ranks:
			new_deck.append({"rank": r, "suit": s})
	return new_deck

func reset_game():
	deck = build_deck()
	deck.shuffle()
	dealer_hand.clear()
	player_hand.clear()
	game_over = false
	result_label.text = ""
	dealer_hand.append(draw_card())
	dealer_hand.append(draw_card())
	player_hand.append(draw_card())
	player_hand.append(draw_card())
	update_ui()

func draw_card():
	return deck.pop_back()

func hand_value(hand: Array) -> int:
	var total = 0
	var aces = 0
	for c in hand:
		var r = c["rank"]
		if r in ["J","Q","K"]:
			total += 10
		elif r == "A":
			total += 11
			aces += 1
		else:
			total += int(r)
	while total > 21 and aces > 0:
		total -= 10
		aces -= 1
	return total

func hand_to_string(hand: Array, show_all: bool) -> String:
	var parts = []
	for i in range(hand.size()):
		if not show_all and i == 0:
			parts.append("[Hidden]")
		else:
			parts.append(hand[i]["rank"] + hand[i]["suit"])
	return " ".join(parts)

func update_ui():
	var show_all = game_over
	dealer_cards.text = hand_to_string(dealer_hand, show_all)
	player_cards.text = hand_to_string(player_hand, true)
	dealer_label.text = "Dealer (" + str(hand_value(dealer_hand)) + ")"
	player_label.text = "Player (" + str(hand_value(player_hand)) + ")"

func on_hit():
	if game_over:
		return
	player_hand.append(draw_card())
	update_ui()
	if hand_value(player_hand) > 21:
		game_over = true
		result_label.text = "Player busts! Dealer wins."

func on_stand():
	if game_over:
		return
	while hand_value(dealer_hand) < 17:
		dealer_hand.append(draw_card())
	game_over = true
	update_ui()
	check_winner()

func check_winner():
	var pv = hand_value(player_hand)
	var dv = hand_value(dealer_hand)
	if dv > 21:
		result_label.text = "Dealer busts! Player wins!"
	elif pv > dv:
		result_label.text = "Player wins!"
	elif pv < dv:
		result_label.text = "Dealer wins!"
	else:
		result_label.text = "Draw!"

func on_reset():
	reset_game()
