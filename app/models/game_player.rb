class GamePlayer < ApplicationRecord
  # アソシエーション
  belongs_to :game_session
  belongs_to :user
  
  # バリデーション
  validates :turn_order, presence: true, uniqueness: { scope: :game_session_id }
  validates :user_id, uniqueness: { scope: :game_session_id }
  
  # スコープ
  scope :active, -> { where(is_eliminated: false) }
  scope :eliminated, -> { where(is_eliminated: true) }
  scope :by_turn_order, -> { order(:turn_order) }
  
  # 現在のターンかどうか
  def current_turn?
    game_session.current_turn_player_id == user_id
  end
  
  # 次のプレイヤーを取得
  def next_player
    active_players = game_session.game_players.active.by_turn_order
    current_index = active_players.find_index(self)
    
    return nil unless current_index
    
    next_index = (current_index + 1) % active_players.count
    active_players[next_index]
  end
end
