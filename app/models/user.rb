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

  # アソシエーション（クイズセッション関連）
  has_many :created_quiz_sessions, class_name: 'QuizSession', foreign_key: 'creator_id', dependent: :destroy
  has_many :won_quiz_sessions, class_name: 'QuizSession', foreign_key: 'winner_user_id'
  has_many :quiz_participants, dependent: :destroy
  has_many :joined_quiz_sessions, through: :quiz_participants, source: :quiz_session
  has_many :quiz_answers, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 50 }
  
  # 現在参加中のゲームセッションを取得
  def current_game_session
    joined_game_sessions.where(status: [:waiting, :playing]).first
  end
  
  # ゲームセッションに参加しているかチェック
  def joined_game?(game_session)
    game_players.exists?(game_session: game_session)
  end
  
  # 管理者権限があるかチェック
  def admin?
    is_admin
  end

  # クイズセッション関連のメソッド
  def current_quiz_session
    joined_quiz_sessions.where(status: ['waiting', 'started']).first
  end

  def joined_quiz?(quiz_session)
    quiz_participants.exists?(quiz_session: quiz_session)
  end

  def quiz_stats
    {
      total_sessions: joined_quiz_sessions.count,
      won_sessions: won_quiz_sessions.count,
      total_answers: quiz_answers.count,
      correct_answers: quiz_answers.correct.count
    }
  end
end
