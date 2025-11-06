extends Node
class_name ProtectionRacket

## Protection Racket System
## Manages the "guy" that you need to pay off every N rounds or get kicked out

signal payment_demanded(amount: int, rounds_until_demand: int)
signal payment_made(amount: int)
signal payment_failed()
signal kicked_out()

## Configuration
@export var rounds_between_payments: int = 3  ## How many rounds between payment demands
@export var base_payment_amount: int = 500  ## Base amount to pay
@export var payment_increase_per_demand: int = 250  ## How much the payment increases each time
@export var warning_rounds: int = 1  ## Warn player N rounds before payment due

## State
var current_round: int = 0
var payments_made: int = 0
var total_paid: int = 0
var next_payment_round: int = 0
var current_payment_amount: int = 0
var is_active: bool = true

func _ready() -> void:
	reset()

func reset() -> void:
	"""Reset the protection racket to initial state"""
	current_round = 0
	payments_made = 0
	total_paid = 0
	next_payment_round = rounds_between_payments
	current_payment_amount = base_payment_amount
	is_active = true

func start_new_run() -> void:
	"""Start a new run (after returning from shop)"""
	reset()

func on_round_completed() -> void:
	"""Call this when a blackjack round is completed"""
	if not is_active:
		return

	current_round += 1

	var rounds_until_payment = next_payment_round - current_round

	# Emit warning signal
	if rounds_until_payment > 0 and rounds_until_payment <= warning_rounds:
		payment_demanded.emit(current_payment_amount, rounds_until_payment)

	# Check if payment is due
	if current_round >= next_payment_round:
		demand_payment()

func demand_payment() -> void:
	"""Demand payment from the player"""
	payment_demanded.emit(current_payment_amount, 0)

func try_make_payment(available_chips: int) -> bool:
	"""
	Attempt to make the payment
	Returns true if payment successful, false if player can't afford it
	"""
	if available_chips >= current_payment_amount:
		# Payment successful
		payments_made += 1
		total_paid += current_payment_amount

		# Schedule next payment
		next_payment_round = current_round + rounds_between_payments

		# Increase payment amount for next time
		var old_amount = current_payment_amount
		current_payment_amount = base_payment_amount + (payments_made * payment_increase_per_demand)

		payment_made.emit(old_amount)
		return true
	else:
		# Can't afford payment - get kicked out!
		kicked_out.emit()
		is_active = false
		return false
		
func kick_out() -> void:
	"""Kick the player out of the casino"""
	kicked_out.emit()
	is_active = false

func get_rounds_until_payment() -> int:
	"""Get how many rounds until next payment is due"""
	return max(0, next_payment_round - current_round)

func get_current_payment_amount() -> int:
	"""Get the current payment amount"""
	return current_payment_amount

func get_stats() -> Dictionary:
	"""Get statistics about payments"""
	return {
		"current_round": current_round,
		"payments_made": payments_made,
		"total_paid": total_paid,
		"next_payment_round": next_payment_round,
		"current_payment_amount": current_payment_amount,
		"rounds_until_payment": get_rounds_until_payment()
	}
