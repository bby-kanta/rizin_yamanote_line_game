class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # アソシエーション（ゲームセッション関連）
  has_many :created_game_sessions, class_name: 'GameSession', foreign_key: 'creator_id', dependent: :destroy
  has_many :current_turn_sessions, class_name: 'GameSession', foreign_key: 'current_turn_player_id'
  has_many :game_players, dependent: :destroy
  has_many :joined_game_sessions, through: :game_players, source: :game_session
  has_many :used_fighters, foreign_key: 'used_by_id', dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 50 }
  
  # 現在参加中のゲームセッションを取得
  def current_game_session
    joined_game_sessions.where(status: [:waiting, :playing]).first
  end
  
  # ゲームセッションに参加しているかチェック
  def joined_game?(game_session)
    game_players.exists?(game_session: game_session)
  end
end
