class QuizSession < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  belongs_to :target_fighter, class_name: 'Fighter'
  belongs_to :winner_user, class_name: 'User', optional: true
  has_many :quiz_participants, dependent: :destroy
  has_many :participants, through: :quiz_participants, source: :user
  has_many :quiz_answers, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[waiting started ended] }
  validates :current_hint_index, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :solo_mode, inclusion: { in: [true, false] }

  scope :active, -> { where(status: ['waiting', 'started']) }
  scope :ended, -> { where(status: 'ended') }
  scope :waiting, -> { where(status: 'waiting') }
  scope :started, -> { where(status: 'started') }

  def waiting?
    status == 'waiting'
  end

  def started?
    status == 'started'
  end

  def ended?
    status == 'ended'
  end

  def solo_mode?
    solo_mode
  end

  def start!
    return false unless waiting?
    
    transaction do
      update!(status: 'started', started_at: Time.current)
      reset_participants_state
    end
    true
  end

  def end_with_winner!(winner)
    return false unless started?
    
    transaction do
      update!(status: 'ended', ended_at: Time.current, winner_user: winner)
      quiz_participants.find_by(user: winner)&.update!(is_winner: true)
      calculate_all_points
    end
    true
  end

  def current_hint
    hints[current_hint_index] if current_hint_index < hints.size
  end

  def hints
    @hints ||= target_fighter.quiz_features.ordered_for_quiz.to_a
  end

  def next_hint!
    return false if current_hint_index >= hints.size - 1
    
    increment!(:current_hint_index)
    current_hint
  end

  def has_more_hints?
    current_hint_index < hints.size - 1
  end

  def all_participants_responded_to_current_hint?
    # 現在のヒントに対して、全員が回答またはパスしたかチェック
    participants_without_answer = quiz_participants.where(answered_at: nil)
    
    participants_without_answer.all? do |participant|
      # 現在のヒントインデックスで回答またはパスしているかチェック
      quiz_answers.where(
        user: participant.user,
        hint_index: current_hint_index
      ).exists?
    end
  end

  def participant_for(user)
    participant = quiz_participants.find_or_create_by(user: user)
    Rails.logger.info "QuizSession: participant_for user #{user.id} - found/created participant #{participant.id}, connected_at: #{participant.connected_at}"
    participant
  end

  def submit_answer(user, fighter)
    participant = participant_for(user)
    
    # 既に正解している場合はエラー
    return :already_answered if participant.answered_at.present?
    
    # 現在のヒントで既に回答している場合はエラー
    return :already_responded_this_hint if quiz_answers.where(user: user, hint_index: current_hint_index).exists?
    
    is_correct = fighter.id == target_fighter.id
    
    transaction do
      quiz_answers.create!(
        user: user,
        fighter: fighter,
        is_correct: is_correct,
        submitted_at: Time.current,
        hint_index: current_hint_index
      )
      
      if is_correct
        participant.update!(answered_at: Time.current)
        # 正解時に即座にポイントを計算
        calculate_points_for_participant(participant)
        return :correct
      else
        participant.increment!(:miss_count)
        return :incorrect
      end
    end
  end

  def pass_turn(user)
    participant = participant_for(user)
    
    # 既に正解している場合はエラー
    return :already_answered if participant.answered_at.present?
    
    # 現在のヒントで既に回答している場合はエラー
    return :already_responded_this_hint if quiz_answers.where(user: user, hint_index: current_hint_index).exists?
    
    # パスの履歴を記録
    quiz_answers.create!(
      user: user,
      fighter: nil, # パスの場合はnil
      is_correct: false,
      submitted_at: Time.current,
      hint_index: current_hint_index
    )
    
    :passed
  end

  def remaining_participants
    quiz_participants.where(answered_at: nil)
  end

  def all_participants_connected?
    return true if solo_mode? # ソロモードの場合は常にtrueを返す
    quiz_participants.count > 0 && quiz_participants.connected.count == quiz_participants.count
  end

  def calculate_points_for_participant(participant)
    return unless participant.answered_at
    
    base_points = 100
    hints_used = current_hint_index + 1
    
    # 基本ポイント（少ないヒントで正解するほど高いポイント）
    basic_points = [base_points - (hints_used - 1) * 20, 20].max
    
    # パス回数を計算（fighter_id が NULL なレコード）
    pass_count = quiz_answers.where(user: participant.user, fighter_id: nil).count
    
    # ペナルティ計算
    # パス1回 = -10ポイント、ミス1回 = -30ポイント
    # パス3回(-30ポイント) = ミス1回(-30ポイント)
    pass_penalty = pass_count * 10
    miss_penalty = participant.miss_count * 30
    
    final_points = [basic_points - pass_penalty - miss_penalty, 10].max
    
    participant.update!(points: final_points)
  end

  def calculate_all_points
    quiz_participants.each do |participant|
      calculate_points_for_participant(participant) if participant.answered_at
    end
    
    # 勝者を決定
    determine_winner
  end

  private

  def determine_winner
    # すべての参加者のポイントを取得
    max_points = quiz_participants.maximum(:points) || 0
    
    # 最高ポイントを持つ参加者を取得
    top_participants = quiz_participants.where(points: max_points)
    
    # 最高ポイントが複数人いる場合は勝者なし
    if top_participants.count > 1
      # 既存の勝者フラグをリセット
      quiz_participants.update_all(is_winner: false)
      update!(winner_user: nil)
    elsif top_participants.count == 1
      # 1人だけの場合は勝者に設定
      winner = top_participants.first
      quiz_participants.update_all(is_winner: false)
      winner.update!(is_winner: true)
      update!(winner_user: winner.user)
    end
  end

  def reset_participants_state
    quiz_participants.update_all(
      miss_count: 0,
      answered_at: nil,
      responded_at: nil,
      points: 0,
      is_winner: false
    )
  end
end