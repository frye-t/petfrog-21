# Generic Hand behavior, to be used in other Card Games
module Hand
  def add_card(card, face_up: true)
    card.flip! if !face_up
    cards << card
  end

  def show_cards
    str = "|| "
    cards_added = 0
    cards.each do |card|
      str << "\n|| " if cards_added % 4 == 0 && !cards_added.zero?
      str << "#{card} || "
      cards_added += 1
    end
    puts str
  end

  def reveal_hand
    cards.each do |card|
      card.flip! if card.face_down?
    end
  end

  def any_face_down?
    return true if cards.any?(&:face_down?)
  end

  def total; end

  def cards_count
    cards.size
  end
end

# Behavior specific to a Twenty-One Hand
module TOHand
  include Hand

  ACE_VALUES = [1, 11]
  ACE_DIFF = ACE_VALUES.max - ACE_VALUES.min
  COURT_VALUE = 10
  HAND_MAX = 21

  def total
    if any_face_down?
      return card_value(cards[1])
    end
    total = raw_total
    num_aces = cards.select(&:ace?).count
    num_aces.times { total -= ACE_DIFF if total > HAND_MAX }

    total
  end

  def busted?
    total > HAND_MAX
  end

  private

  def raw_total(total=0)
    cards.each do |card|
      total += card_value(card)
    end
    total
  end

  def card_value(card)
    if card.ace?
     ACE_VALUES.max
   elsif card.court?
     COURT_VALUE
   else
     card.value.to_i
   end
  end
end

class Deck
  attr_reader :cards

  def initialize
    @cards = []
    Card::SUITS.each do |suit|
      Card::VALUES.each do |value|
        @cards << Card.new(suit, value)
      end
    end
  end

  def each
    cards.each { |card| yield(card) }
  end

  def shuffle!
    cards.shuffle!
  end

  def deal_card
    cards.shift
  end
end

class Card
  SUITS = %w(S H D C)
  VALUES = %w(A 2 3 4 5 6 7 8 9 10 J Q K)

  attr_reader :face_up

  def initialize(suit, value)
    @suit = suit
    @value = value
    @face_up = true
  end

  def to_s
    if face_up
      "#{suit}_#{@value}"
    else
      "card_back"
    end
  end

  def flip!
    self.face_up = !face_up
  end

  def face_down?
    !face_up
  end

  def ace?
    value == 'Ace'
  end

  def jack?
    value == 'Jack'
  end

  def queen?
    value == 'Queen'
  end

  def king?
    value == 'King'
  end

  def court?
    jack? || queen? || king?
  end

  def suit
    case @suit
    when 'S' then 'spades'
    when 'H' then 'hearts'
    when 'D' then 'diamonds'
    when 'C' then 'clubs'
    end
  end

  def value
    case @value
    when 'A' then 'Ace'
    when 'J' then 'Jack'
    when 'Q' then 'Queen'
    when 'K' then 'King'
    else @value
    end
  end

  private

  attr_writer :face_up
end

module CardHolder
  # Generic Card Holder
  class Participant
    attr_reader :cards, :score

    def initialize
      @cards = []
      @score = 0
      set_name
    end

    def set_name
      @name = self.class.to_s
    end

    def to_s
      @name
    end

    def reset
      @cards = []
      @score = 0
    end

    def discard_hand
      @cards = []
    end

    def add_score(score_to_add=1)
      @score += score_to_add
    end

    def >; end
  end

  # Behvaior specific to Twenty-One
  class TOParticipant < Participant
    include TOHand
    DEALER_MAX = 17

    def >(other_participant)
      if busted?
        false
      elsif other_participant.busted?
        true
      else
        total > other_participant.total
      end
    end

    def hit(deck)
      add_card(deck.deal_card)
    end
  end

  # Player/Dealer specific Behavior
  class Player < TOParticipant
    attr_reader :balance
    attr_reader :bet

    def initialize
      super
      @balance = 1000
    end

    def bet=(val)
      @bet = val.to_i
    end

    def update_balance(winner, blackjack)
      if winner == :dealer
        @balance -= bet
      elsif winner == :player
        if blackjack
          @balance += (bet * 3 / 2)
        else
          @balance += bet
        end
      end
      @balance.to_i
    end

    def stayed
      @stayed = true
    end

    def stayed?
      @stayed
    end
  end

  class Dealer < TOParticipant
    def initialize
      super
    end

    def wait
      sleep(3)
    end
  end
end

class TwentyOneGame
  attr_accessor :deck, :player, :dealer

  def initialize
    @deck = nil
    @player = nil
    @dealer = nil
  end

  def print_deck
    str = ""
    @deck.cards.each do |card|
      str << card.to_s << "\n"
    end
    str
  end

  def setup
    self.deck = Deck.new
    deck.shuffle!
    player.nil? ? self.player = CardHolder::Player.new : player.reset
    self.dealer = CardHolder::Dealer.new
  end

  def deal_starting_hands
    # places Dealer's first card face down
    2.times do |time|
      player.add_card(deck.deal_card)
      dealer_face_up = !(time == 0)
      dealer.add_card(deck.deal_card, face_up: dealer_face_up)
    end
  end
end