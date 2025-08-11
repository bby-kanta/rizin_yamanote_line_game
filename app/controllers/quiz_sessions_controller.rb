class QuizSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quiz_session, only: [:show, :join, :start, :submit_answer, :pass]

  def index
    @quiz_sessions = QuizSession.active.where(solo_mode: false).includes(:creator, :target_fighter, :participants).order(created_at: :desc)
    @my_sessions = current_user.created_quiz_sessions.includes(:target_fighter, :participants).order(created_at: :desc)
  end

  def show
    @participant = current_user.joined_quiz?(@quiz_session) ? @quiz_session.participant_for(current_user) : nil
    @current_hint = @quiz_session.current_hint
    @participants = @quiz_session.quiz_participants.includes(:user).by_points
    @can_join = !current_user.joined_quiz?(@quiz_session) && @quiz_session.waiting?
    
    # 現在のヒントでの回答状況を取得（パフォーマンス向上のため）
    if @quiz_session.started?
      @current_hint_answers = @quiz_session.quiz_answers
        .where(hint_index: @quiz_session.current_hint_index)
        .includes(:user)
        .index_by(&:user_id)
    end
  end

  def new
    @quiz_session = QuizSession.new
    @eligible_fighters = Fighter.quiz_eligible.includes(:fighter_features)
    @solo_mode = params[:solo] == 'true'
    
    # ソロプレイモードの場合は自動的にクイズを作成
    if @solo_mode
      create_solo_quiz
    end
  end

  def create
    @quiz_session = current_user.created_quiz_sessions.build(quiz_session_params)
    
    # ランダム選択の場合
    if params[:quiz_session][:target_fighter_id].blank?
      eligible_fighters = Fighter.quiz_eligible
      @quiz_session.target_fighter = eligible_fighters.sample if eligible_fighters.any?
    end
    
    if @quiz_session.save
      # 作成者を最初の参加者として自動登録
      @quiz_session.participant_for(current_user)
      redirect_to @quiz_session, notice: 'クイズセッションが作成され、あなたも参加者として登録されました。'
    else
      @eligible_fighters = Fighter.quiz_eligible.includes(:fighter_features)
      render :new, status: :unprocessable_entity
    end
  end

  def join
    if current_user.joined_quiz?(@quiz_session)
      redirect_to @quiz_session, alert: '既に参加しています。'
    elsif !@quiz_session.waiting?
      redirect_to @quiz_session, alert: 'このセッションには参加できません。'
    else
      @quiz_session.participant_for(current_user)
      redirect_to @quiz_session, notice: 'クイズセッションに参加しました！'
    end
  end

  def start
    unless @quiz_session.creator == current_user
      redirect_to @quiz_session, alert: '開始権限がありません。'
      return
    end

    if !@quiz_session.solo_mode? && @quiz_session.quiz_participants.count < 2
      redirect_to @quiz_session, alert: '参加者が2人以上必要です。'
      return
    end

    # 全員の接続確認
    unless @quiz_session.all_participants_connected?
      respond_to do |format|
        format.html { redirect_to @quiz_session, alert: 'すべての参加者の接続を待っています。しばらくお待ちください。' }
        format.json { render json: { status: 'waiting', message: 'すべての参加者の接続を待っています。' } }
      end
      return
    end

    if @quiz_session.start!
      # リアルタイム更新をここで送信
      ActionCable.server.broadcast("quiz_session_#{@quiz_session.id}", {
        type: 'session_started',
        hint: render_to_string(partial: 'current_hint', locals: { hint: @quiz_session.current_hint }, formats: [:html])
      })
      
      respond_to do |format|
        format.html { redirect_to @quiz_session, notice: 'クイズが開始されました！' }
        format.json { render json: { status: 'success', message: 'クイズが開始されました！' } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @quiz_session, alert: 'クイズを開始できませんでした。' }
        format.json { render json: { status: 'error', message: 'クイズを開始できませんでした。' } }
      end
    end
  end

  def submit_answer
    unless current_user.joined_quiz?(@quiz_session) && @quiz_session.started?
      redirect_to @quiz_session, alert: '回答できません。'
      return
    end

    fighter = Fighter.find(params[:fighter_id])
    result = @quiz_session.submit_answer(current_user, fighter)
    
    case result
    when :correct
      # 正解をブロードキャスト
      Rails.logger.info "About to broadcast correct answer for user #{current_user.id}"
      broadcast_participant_answered(current_user.id, 'correct')
      
      if @quiz_session.remaining_participants.empty?
        @quiz_session.end_with_winner!(current_user)
        message = '正解です！あなたの勝利です！'
        broadcast_game_ended
      else
        message = '正解です！他の参加者を待っています...'
      end
    when :incorrect
      # 不正解をブロードキャスト
      broadcast_participant_answered(current_user.id, 'incorrect')
      message = '不正解です。次のヒントを待ちましょう。'
    when :already_responded_this_hint
      message = '既にこのヒントで回答済みです。'
    end

    # 全員が回答（正解・不正解・パス）した場合の処理
    if @quiz_session.all_participants_responded_to_current_hint?
      if @quiz_session.has_more_hints?
        @quiz_session.next_hint!
        broadcast_next_hint
      else
        # ヒントがもうない場合はゲーム終了（勝者なし）
        @quiz_session.transaction do
          @quiz_session.update!(status: 'ended', ended_at: Time.current)
          @quiz_session.calculate_all_points
        end
        message += ' ヒントがすべて出尽くしました。ゲーム終了です。'
        broadcast_game_ended
      end
    end

    respond_to do |format|
      format.html { redirect_to @quiz_session, notice: message }
      format.json { render json: { status: 'success', message: message, redirect: false } }
    end
  end

  def pass
    unless current_user.joined_quiz?(@quiz_session) && @quiz_session.started?
      redirect_to @quiz_session, alert: 'パスできません。'
      return
    end

    result = @quiz_session.pass_turn(current_user)
    
    case result
    when :passed
      # パスをブロードキャスト
      broadcast_participant_answered(current_user.id, 'passed')
      message = 'パスしました。'
    when :already_responded_this_hint
      message = '既にこのヒントで回答済みです。'
    end

    # 全員が回答（正解・不正解・パス）した場合の処理
    if @quiz_session.all_participants_responded_to_current_hint?
      if @quiz_session.has_more_hints?
        @quiz_session.next_hint!
        broadcast_next_hint
      else
        # ヒントがもうない場合はゲーム終了（勝者なし）
        @quiz_session.transaction do
          @quiz_session.update!(status: 'ended', ended_at: Time.current)
          @quiz_session.calculate_all_points
        end
        message += ' ヒントがすべて出尽くしました。ゲーム終了です。'
        broadcast_game_ended
      end
    end

    respond_to do |format|
      format.html { redirect_to @quiz_session, notice: message }
      format.json { render json: { status: 'success', message: message, redirect: false } }
    end
  end

  private

  def create_solo_quiz
    eligible_fighters = Fighter.quiz_eligible
    if eligible_fighters.empty?
      flash[:alert] = 'クイズ対象の選手がいません。まず選手の特徴を登録してください。'
      redirect_to fighters_path
      return
    end

    @quiz_session = current_user.created_quiz_sessions.build
    @quiz_session.target_fighter = eligible_fighters.sample
    @quiz_session.solo_mode = true
    
    if @quiz_session.save
      # 作成者を最初の参加者として自動登録
      @quiz_session.participant_for(current_user)
      # ソロプレイなので即座に開始
      @quiz_session.start!
      redirect_to @quiz_session, notice: 'ソロクイズを開始しました！'
    else
      flash[:alert] = 'クイズを作成できませんでした。'
      redirect_to quiz_sessions_path
    end
  end

  def set_quiz_session
    @quiz_session = QuizSession.find(params[:id])
  end

  def quiz_session_params
    params.require(:quiz_session).permit(:target_fighter_id)
  end

  def broadcast_next_hint
    ActionCable.server.broadcast("quiz_session_#{@quiz_session.id}", {
      type: 'next_hint',
      hint: render_to_string(partial: 'current_hint', locals: { hint: @quiz_session.current_hint }, formats: [:html]),
      hint_index: @quiz_session.current_hint_index
    })
  end

  def broadcast_game_ended
    ActionCable.server.broadcast("quiz_session_#{@quiz_session.id}", {
      type: 'game_ended',
      winner: @quiz_session.winner_user&.name,
      results: render_to_string(partial: 'results', locals: { quiz_session: @quiz_session }, formats: [:html])
    })
  end

  def broadcast_participant_answered(user_id, status)
    channel_name = "quiz_session_#{@quiz_session.id}"
    data = {
      type: 'participant_answered',
      user_id: user_id,
      status: status
    }
    Rails.logger.info "Broadcasting to #{channel_name}: #{data}"
    ActionCable.server.broadcast(channel_name, data)
  end
end
