require 'sinatra'
require "sinatra/reloader" if development?
require 'sinatra/content_for'
require 'tilt/erubis'
require './twenty_one_game'

# Setup Session if using
configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  if session[:game]
    @game = session[:game]
    @player = @game.player
    @dealer = @game.dealer
    @deck = @game.deck
  end
end

# View Helpers
helpers do
  def dealer_turn?
    @player.busted? || @player.stayed?
  end

  def score_class
    if dealer_turn?
      'revealed'
    else
      'hidden'
    end
  end

  def continue_path
    if dealer_turn?
      '/game/dealer/turn'
    else
      '/game/player/turn'
    end
  end
end

def verify_game_active
  redirect '/' if session[:game].nil?
end

def verify_bet
  redirect '/game/bet' if @player.bet.nil? || @player.bet.zero?
end

def set_game_over_message
  if winner == :player
    session[:win_message] = 'YOU WIN!'
  elsif winner == :dealer
    session[:lose_message] = 'YOU LOSE!'
  else
    session[:lose_message] = "IT'S A DRAW!"
  end
end

get '/' do
  # Check to see if a current game exists
  redirect '/game'
end

get '/game' do
  erb :layout, :layout => false do
    erb :main_menu do
      if !session[:game].nil?
        erb :continue
      end
    end
  end
end

def setup_new_round(game)
  game.setup
  game.deal_starting_hands
  session[:game] = game
  session[:blackjack] = nil
  session[:win_message] = nil
  session[:lose_message] = nil
  session[:active_game] = true
  session[:balance_updated] = false
  game
end

post '/game/new' do
  game = TwentyOneGame.new
  game = setup_new_round(game)
  redirect '/game/bet'
end

post '/game/round/new' do
  @game = setup_new_round(@game)
  redirect '/game/bet'
end

get '/game/bet' do
  erb :place_bet
end

post '/game/bet' do
  @player.bet = params[:bet]
  redirect '/game/player/turn'
end

def blackjack?
  @player.total == 21 && @player.cards_count == 2
end

get '/game/player/turn' do 
  verify_game_active
  verify_bet

  if blackjack?
    session[:blackjack] = true
    redirect '/game/over'
  end 

  if @player.total > 21  
    @dealer.reveal_hand
    redirect '/game/over'
  end

  erb :layout, :layout => false do
    erb :active_game do
      erb :player_turn
    end
  end
end

post '/game/player/hit' do
  @player.hit(@deck)
  redirect '/game/player/turn'
end

post '/game/player/stay' do
  @player.stayed
  redirect '/game/dealer/turn'
end

def dealer_turn_over?
  @dealer.total >= 17
end

get '/game/dealer/turn' do
  verify_game_active
  verify_bet
  @dealer.reveal_hand

  redirect '/game/over' if dealer_turn_over?
  
  erb :layout, :layout => false do
    erb :active_game do
      erb :dealer_active
    end
  end
end

post '/game/dealer/hit' do
  @dealer.hit(@deck)

  redirect '/game/over' if dealer_turn_over?

  erb :layout, :layout => false do
    erb :active_game do
      erb :dealer_active
    end
  end
end

def winner
  if @player > @dealer
    :player
  elsif @dealer > @player
    :dealer
  else
    :draw
  end
end

get '/game/over' do
  verify_game_active
  verify_bet

  @player.update_balance(winner, blackjack?) unless session[:balance_updated]
  session[:balance_updated] = true
  set_game_over_message

  erb :layout, :layout => false do
    erb :active_game do
      erb :game_over
    end
  end
end

post '/game/quit' do
  session[:game] = nil
  redirect '/'
end
