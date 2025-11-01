using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

/// <summary>
/// Blackjack game logic class for managing game state, scoring, and hand evaluation.
/// Integrates with Godot's Card system from the simple_cards addon.
/// </summary>
public partial class BlackjackManager : Node
{
	#region Signals

	[Signal]
	public delegate void GameStateChangedEventHandler(GameState newState);

	[Signal]
	public delegate void PlayerBustedEventHandler();

	[Signal]
	public delegate void DealerBustedEventHandler();

	[Signal]
	public delegate void BlackjackEventHandler(bool isPlayer);

	[Signal]
	public delegate void RoundEndedEventHandler(RoundResult result, int payout);

	#endregion

	#region Enums

	
/// <summary>
		/// Game states for the blackjack game.
		/// Integer values:
		/// 0 = Idle, 1 = Betting, 2 = Dealing, 3 = PlayerTurn, 4 = DealerTurn, 5 = RoundEnd, 6 = GameOver
		/// </summary>
		public enum GameState
		{
			Idle = 0,       /// <summary>0 - Waiting for player input / round not started.</summary>
			Betting = 1,    /// <summary>1 - Player is placing a bet.</summary>
			Dealing = 2,    /// <summary>2 - Initial cards are being dealt.</summary>
			PlayerTurn = 3, /// <summary>3 - Player's turn to hit/stand.</summary>
			DealerTurn = 4, /// <summary>4 - Dealer is playing their hand.</summary>
			RoundEnd = 5,   /// <summary>5 - Round finished, showing results.</summary>
			GameOver = 6    /// <summary>6 - Game ended (no more chips or quit).</summary>
		}

	public enum RoundResult
	{
		None,
		PlayerWin,
		DealerWin,
		Push,
		PlayerBlackjack,
		PlayerBust,
		DealerBust
	}

	public enum CardSuit
	{
		Clubs = 0,
		Diamond = 1,
		Heart = 2,
		Spade = 3,
		All = 4
	}

	#endregion

	#region Exported Properties

	[Export]
	public int DealerStandThreshold { get; set; } = 17;

	[Export]
	public int BlackjackPayoutMultiplier { get; set; } = 2; // Usually 3:2, but simplified to 2:1

	[Export]
	public int WinPayoutMultiplier { get; set; } = 2;

	[Export]
	public int MinimumBet { get; set; } = 10;

	[Export]
	public int MaximumBet { get; set; } = 1000;

	#endregion

	#region Properties

	public GameState CurrentState { get; private set; } = GameState.Idle;
	public int CurrentBet { get; private set; } = 0;
	public int PlayerChips { get; set; } = 1000;
	public RoundResult LastResult { get; private set; } = RoundResult.None;

	private int _playerHandValue = 0;
	private int _dealerHandValue = 0;
	private List<GodotObject> _playerCards = new List<GodotObject>();
	private List<GodotObject> _dealerCards = new List<GodotObject>();

	#endregion

	#region Godot Lifecycle

	public override void _Ready()
	{
		GD.Print("BlackjackGame initialized");
		SetGameState(GameState.Idle);
	}

	#endregion

	#region Public Methods - Game Flow

	/// <summary>
	/// Starts a new round with the specified bet amount.
	/// </summary>
	public bool StartRound(int betAmount)
	{
		if (CurrentState != GameState.Idle && CurrentState != GameState.RoundEnd)
		{
			GD.PrintErr("Cannot start round - game is not in idle state");
			return false;
		}

		if (betAmount < MinimumBet || betAmount > MaximumBet)
		{
			GD.PrintErr($"Bet amount must be between {MinimumBet} and {MaximumBet}");
			return false;
		}

		if (betAmount > PlayerChips)
		{
			GD.PrintErr("Insufficient chips for this bet");
			return false;
		}

		CurrentBet = betAmount;
		PlayerChips -= betAmount;

		_playerCards.Clear();
		_dealerCards.Clear();
		_playerHandValue = 0;
		_dealerHandValue = 0;
		LastResult = RoundResult.None;

		SetGameState(GameState.Dealing);
		GD.Print($"Round started with bet: {betAmount}");

		return true;
	}

	/// <summary>
	/// Adds a card to the player's hand and recalculates hand value.
	/// </summary>
	public void AddPlayerCard(GodotObject card)
	{
		_playerCards.Add(card);
		_playerHandValue = CalculateHandValue(_playerCards);
		GD.Print($"Player card added. Hand value: {_playerHandValue}");

		CheckForBlackjack();
		CheckForBust(true);
	}

	/// <summary>
	/// Adds a card to the dealer's hand and recalculates hand value.
	/// </summary>
	public void AddDealerCard(GodotObject card)
	{
		_dealerCards.Add(card);
		_dealerHandValue = CalculateHandValue(_dealerCards);
		GD.Print($"Dealer card added. Hand value: {_dealerHandValue}");

		CheckForBlackjack();
	}

	/// <summary>
	/// Player chooses to hit (draw another card).
	/// </summary>
	public bool PlayerHit()
	{
		if (CurrentState != GameState.PlayerTurn)
		{
			GD.PrintErr("Cannot hit - not player's turn");
			return false;
		}

		GD.Print("Player hits");
		// Card should be drawn by the scene and added via AddPlayerCard
		return true;
	}

	/// <summary>
	/// Player chooses to stand (end their turn).
	/// </summary>
	public void PlayerStand()
	{
		if (CurrentState != GameState.PlayerTurn)
		{
			GD.PrintErr("Cannot stand - not player's turn");
			return;
		}

		GD.Print("Player stands");
		SetGameState(GameState.DealerTurn);
	}

	/// <summary>
	/// Dealer draws cards according to dealer rules.
	/// Should be called after player stands.
	/// </summary>
	public bool DealerShouldHit()
	{
		return _dealerHandValue < DealerStandThreshold;
	}

	/// <summary>
	/// Completes the dealer's turn and determines the round winner.
	/// </summary>
	public void CompleteDealerTurn()
	{
		if (CurrentState != GameState.DealerTurn)
		{
			GD.PrintErr("Cannot complete dealer turn - not dealer's turn");
			return;
		}

		// Check if dealer busted
		if (_dealerHandValue > 21)
		{
			EmitSignal(SignalName.DealerBusted);
			EndRound(RoundResult.DealerBust);
			return;
		}

		// Determine winner
		DetermineWinner();
	}

	/// <summary>
	/// Resets the game for a new round.
	/// </summary>
	public void ResetRound()
	{
		_playerCards.Clear();
		_dealerCards.Clear();
		_playerHandValue = 0;
		_dealerHandValue = 0;
		CurrentBet = 0;
		LastResult = RoundResult.None;

		SetGameState(GameState.Idle);
		GD.Print("Round reset");
	}

	#endregion

	#region Public Methods - Getters

	/// <summary>
	/// Gets the current value of the player's hand.
	/// </summary>
	public int GetPlayerHandValue()
	{
		return _playerHandValue;
	}

	/// <summary>
	/// Gets the current value of the dealer's hand.
	/// </summary>
	public int GetDealerHandValue()
	{
		return _dealerHandValue;
	}
	
	/// <summary>
	/// Gets the current visible value of the dealer's hand.
	/// </summary>
	public int GetVisibleDealerHandValue()
	{
		if (_dealerCards.Count == 0)
			return 0;

		// Only count the first card's value
		var firstCard = _dealerCards[0];
		return GetCardValue(firstCard);
	}

	/// <summary>
	/// Gets the number of cards in the player's hand.
	/// </summary>
	public int GetPlayerCardCount()
	{
		return _playerCards.Count;
	}

	/// <summary>
	/// Gets the number of cards in the dealer's hand.
	/// </summary>
	public int GetDealerCardCount()
	{
		return _dealerCards.Count;
	}

	/// <summary>
	/// Checks if the player can afford a bet.
	/// </summary>
	public bool CanAffordBet(int amount)
	{
		return PlayerChips >= amount;
	}

	#endregion

	#region Private Methods - Hand Calculation

	/// <summary>
	/// Calculates the total value of a hand, handling Aces intelligently.
	/// </summary>
	private int CalculateHandValue(List<GodotObject> cards)
	{
		if (cards.Count == 0)
			return 0;

		int totalValue = 0;
		int aceCount = 0;

		foreach (var cardObj in cards)
		{
			int cardValue = GetCardValue(cardObj);

			// Check if it's an Ace
			if (IsAce(cardObj))
			{
				aceCount++;
				totalValue += 11; // Initially count Ace as 11
			}
			else
			{
				totalValue += cardValue;
			}
		}

		// Adjust for Aces: convert 11 to 1 if busting
		while (totalValue > 21 && aceCount > 0)
		{
			totalValue -= 10; // Convert an Ace from 11 to 1
			aceCount--;
		}

		return totalValue;
	}

	/// <summary>
	/// Gets the numeric value of a card.
	/// </summary>
	private int GetCardValue(GodotObject card)
	{
		// Access the card_data property
		var cardData = card.Get("card_data");
		if (cardData.Obj == null)
		{
			GD.PrintErr("Card has no card_data");
			return 0;
		}

		// Get the value property from card_data
		var value = cardData.AsGodotObject().Get("value").AsInt32();

		// In blackjack, face cards (J, Q, K) are worth 10
		// Assuming values are: 1=Ace, 2-10=face value, 11=J, 12=Q, 13=K
		if (value > 10)
			return 10;

		return value;
	}

	/// <summary>
	/// Checks if a card is an Ace.
	/// </summary>
	private bool IsAce(GodotObject card)
	{
		var cardData = card.Get("card_data");
		if (cardData.Obj == null)
			return false;

		var value = cardData.AsGodotObject().Get("value").AsInt32();
		return value == 1; // Ace has value 1
	}

	#endregion

	#region Private Methods - Game Logic

	/// <summary>
	/// Sets the game state and emits the state changed signal.
	/// </summary>
	private void SetGameState(GameState newState)
	{
		CurrentState = newState;
		EmitSignal(SignalName.GameStateChanged, (int)newState);
		GD.Print($"Game state changed to: {newState}");
	}

	/// <summary>
	/// Checks if either player or dealer has blackjack (21 with 2 cards).
	/// </summary>
	private void CheckForBlackjack()
	{
		if (_playerCards.Count == 2 && _playerHandValue == 21)
		{
			EmitSignal(SignalName.Blackjack, true);

			// Check if dealer also has blackjack
			if (_dealerCards.Count == 2 && _dealerHandValue == 21)
			{
				EndRound(RoundResult.Push);
			}
			else
			{
				EndRound(RoundResult.PlayerBlackjack);
			}
		}
		else if (_dealerCards.Count == 2 && _dealerHandValue == 21 && CurrentState == GameState.Dealing)
		{
			EmitSignal(SignalName.Blackjack, false);
			EndRound(RoundResult.DealerWin);
		}
	}

	/// <summary>
	/// Checks if a hand has busted (exceeded 21).
	/// </summary>
	private void CheckForBust(bool isPlayer)
	{
		int handValue = isPlayer ? _playerHandValue : _dealerHandValue;

		if (handValue > 21)
		{
			if (isPlayer)
			{
				EmitSignal(SignalName.PlayerBusted);
				EndRound(RoundResult.PlayerBust);
			}
			else
			{
				EmitSignal(SignalName.DealerBusted);
				EndRound(RoundResult.DealerBust);
			}
		}
	}

	/// <summary>
	/// Determines the winner when both player and dealer have stood.
	/// </summary>
	private void DetermineWinner()
	{
		if (_playerHandValue > _dealerHandValue)
		{
			EndRound(RoundResult.PlayerWin);
		}
		else if (_dealerHandValue > _playerHandValue)
		{
			EndRound(RoundResult.DealerWin);
		}
		else
		{
			EndRound(RoundResult.Push);
		}
	}

	/// <summary>
	/// Ends the round, calculates payout, and transitions to round end state.
	/// </summary>
	private void EndRound(RoundResult result)
	{
		LastResult = result;
		int payout = CalculatePayout(result);

		PlayerChips += payout;

		SetGameState(GameState.RoundEnd);
		EmitSignal(SignalName.RoundEnded, (int)result, payout);

		GD.Print($"Round ended: {result}, Payout: {payout}, Chips: {PlayerChips}");
	}

	/// <summary>
	/// Calculates the payout based on the round result.
	/// </summary>
	private int CalculatePayout(RoundResult result)
	{
		switch (result)
		{
			case RoundResult.PlayerBlackjack:
				return CurrentBet + (CurrentBet * BlackjackPayoutMultiplier);

			case RoundResult.PlayerWin:
			case RoundResult.DealerBust:
				return CurrentBet * WinPayoutMultiplier;

			case RoundResult.Push:
				return CurrentBet; // Return original bet

			case RoundResult.PlayerBust:
			case RoundResult.DealerWin:
				return 0; // Lose bet

			default:
				return 0;
		}
	}

	#endregion

	#region Public Methods - Utility

	/// <summary>
	/// Gets a string representation of the current game state for debugging.
	/// </summary>
	public string GetGameStateInfo()
	{
		return $"State: {CurrentState}\n" +
			   $"Player Hand: {_playerHandValue} ({_playerCards.Count} cards)\n" +
			   $"Dealer Hand: {_dealerHandValue} ({_dealerCards.Count} cards)\n" +
			   $"Current Bet: {CurrentBet}\n" +
			   $"Player Chips: {PlayerChips}";
	}

	/// <summary>
	/// Clears all hands (useful for testing or game reset).
	/// </summary>
	public void ClearHands()
	{
		_playerCards.Clear();
		_dealerCards.Clear();
		_playerHandValue = 0;
		_dealerHandValue = 0;
	}

	/// <summary>
	/// Transitions from dealing phase to player turn.
	/// Should be called after initial cards are dealt.
	/// </summary>
	public void BeginPlayerTurn()
	{
		if (CurrentState == GameState.Dealing)
		{
			SetGameState(GameState.PlayerTurn);
		}
	}

	#endregion
}
