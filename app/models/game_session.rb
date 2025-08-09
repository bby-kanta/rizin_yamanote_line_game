class GameSession < ApplicationRecord
  # アソシエーション
  belongs_to :creator, class_name: 'User'
  belongs_to :current_turn_player, class_name: 'User', optional: true
  has_many :game_players, dependent: :destroy
  has_many :players, through: :game_players, source: :user
  has_many :used_fighters, dependent: :destroy
  has_many :fighters, through: :used_fighters
  
  # ステータス定義
  enum :status, {
    waiting: 0,    # 待機中（プレイヤー募集中）
    playing: 1,    # ゲーム中
    finished: 2    # ゲーム終了
  }
  
  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :status, presence: true
  
  # スコープ
  scope :joinable, -> { where(status: :waiting) }
  scope :active, -> { where(status: [:waiting, :playing]) }
  
  # ゲーム開始
  def start_game!
    return false if game_players.count < 2
    
    transaction do
      # プレイヤーのターン順を設定
      game_players.each_with_index do |player, index|
        player.update!(turn_order: index + 1)
      end
      
      # 最初のプレイヤーを設定
      first_player = game_players.order(:turn_order).first
      update!(
        status: :playing,
        current_turn_player: first_player.user,
        started_at: Time.current
      )
    end
    true
  end
  
  # 次のプレイヤーのターンに進む
  def next_turn!
    return false unless playing?
    
    current_players = game_players.where(is_eliminated: false).order(:turn_order)
    current_index = current_players.find_index { |p| p.user_id == current_turn_player_id }
    
    if current_index
      next_index = (current_index + 1) % current_players.count
      next_player = current_players[next_index]
      update!(current_turn_player: next_player.user)
    end
  end
  
  # プレイヤーを脱落させる
  def eliminate_player!(user)
    game_player = game_players.find_by(user: user)
    return false unless game_player
    
    transaction do
      game_player.update!(is_eliminated: true)
      
      # 現在のターンプレイヤーが脱落した場合、次のプレイヤーに進む
      if current_turn_player == user
        remaining_players = game_players.where(is_eliminated: false)
        
        if remaining_players.count <= 1
          # ゲーム終了
          update!(
            status: :finished,
            current_turn_player: nil,
            ended_at: Time.current
          )
        else
          next_turn!
        end
      end
    end
    true
  end
  
  # 勝者を取得
  def winner
    return nil unless finished?
    remaining_players = game_players.where(is_eliminated: false)
    remaining_players.count == 1 ? remaining_players.first.user : nil
  end
  
  # 選手が使用済みかチェック
  def fighter_used?(fighter)
    used_fighters.exists?(fighter: fighter)
  end
  
  # 選手を使用済みにマーク
  def use_fighter!(fighter, user)
    return false if fighter_used?(fighter)
    
    used_fighters.create!(
      fighter: fighter,
      used_by: user,
      used_at: Time.current
    )
    true
  end
end
