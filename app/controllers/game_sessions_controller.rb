class GameSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game_session, only: [:show, :edit, :update, :destroy, :join, :leave, :start_game, :eliminate_player, :submit_fighter, :retire]
  before_action :check_game_access, only: [:show, :submit_fighter, :retire]
  before_action :check_creator_access, only: [:edit, :update, :destroy, :start_game, :eliminate_player]
  
  def index
    @joinable_sessions = GameSession.joinable.includes(:creator, :players).order(created_at: :desc)
    @my_sessions = current_user.joined_game_sessions.active.includes(:creator, :players).order(created_at: :desc)
  end

  def show
    @game_player = @game_session.game_players.find_by(user: current_user)
    @players = @game_session.game_players.includes(:user).order(:turn_order)
    @used_fighters = @game_session.used_fighters.includes(:fighter, :used_by).order(used_at: :desc)
    @available_fighters = Fighter.active.where.not(id: @used_fighters.pluck(:fighter_id))
    
    if params[:query].present?
      @search_results = @available_fighters.search_by_hiragana(params[:query]).limit(10)
      @single_candidate = @search_results.count == 1 ? @search_results.first : nil
    end
  end

  def new
    @game_session = GameSession.new
  end

  def create
    @game_session = GameSession.new(game_session_params)
    @game_session.creator = current_user
    
    if @game_session.save
      # 作成者を自動的に参加させる
      @game_session.game_players.create!(
        user: current_user,
        turn_order: 1,
        joined_at: Time.current
      )
      redirect_to @game_session, notice: 'ゲームセッションを作成しました。'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @game_session.update(game_session_params)
      redirect_to @game_session, notice: 'ゲームセッションを更新しました。'
    else
      render :edit
    end
  end

  def destroy
    @game_session.destroy
    redirect_to game_sessions_path, notice: 'ゲームセッションを削除しました。'
  end

  def join
    if @game_session.waiting?
      if current_user.joined_game?(@game_session)
        redirect_to @game_session, alert: '既に参加しています。'
      elsif current_user.current_game_session
        redirect_to @game_session, alert: '他のゲームに参加中です。'
      else
        next_turn_order = @game_session.game_players.maximum(:turn_order).to_i + 1
        @game_session.game_players.create!(
          user: current_user,
          turn_order: next_turn_order,
          joined_at: Time.current
        )
        redirect_to @game_session, notice: 'ゲームに参加しました。'
      end
    else
      redirect_to @game_session, alert: 'このゲームは参加できません。'
    end
  end

  def leave
    game_player = @game_session.game_players.find_by(user: current_user)
    
    if game_player
      if @game_session.playing?
        # ゲーム中の場合は脱落扱い
        @game_session.eliminate_player!(current_user)
        redirect_to game_sessions_path, notice: 'ゲームから脱落しました。'
      else
        # 待機中の場合は単純に退出
        game_player.destroy
        # ターン順を再調整
        @game_session.game_players.order(:turn_order).each_with_index do |player, index|
          player.update!(turn_order: index + 1)
        end
        redirect_to game_sessions_path, notice: 'ゲームから退出しました。'
      end
    else
      redirect_to @game_session, alert: 'このゲームに参加していません。'
    end
  end

  def start_game
    if @game_session.game_players.count < 2
      redirect_to @game_session, alert: '最低2人のプレイヤーが必要です。'
    elsif @game_session.start_game!
      redirect_to @game_session, notice: 'ゲームを開始しました！'
    else
      redirect_to @game_session, alert: 'ゲームを開始できませんでした。'
    end
  end

  def eliminate_player
    target_user = User.find(params[:user_id])
    
    if @game_session.eliminate_player!(target_user)
      if @game_session.finished?
        winner = @game_session.winner
        redirect_to @game_session, notice: "#{target_user.name}さんが脱落しました。#{winner&.name}さんの勝利です！"
      else
        redirect_to @game_session, notice: "#{target_user.name}さんが脱落しました。"
      end
    else
      redirect_to @game_session, alert: 'プレイヤーを脱落させることができませんでした。'
    end
  end

  def submit_fighter
    fighter = Fighter.find(params[:fighter_id])
    
    if @game_session.current_turn_player != current_user
      redirect_to @game_session, alert: 'あなたのターンではありません。'
    elsif @game_session.fighter_used?(fighter)
      redirect_to @game_session, alert: 'この選手は既に使用されています。'
    elsif @game_session.use_fighter!(fighter, current_user)
      @game_session.next_turn!
      redirect_to @game_session, notice: "#{fighter.display_name}を選択しました。"
    else
      redirect_to @game_session, alert: '選手を選択できませんでした。'
    end
  end

  def retire
    if @game_session.current_turn_player != current_user
      redirect_to @game_session, alert: 'あなたのターンではありません。'
    elsif @game_session.eliminate_player!(current_user)
      if @game_session.finished?
        winner = @game_session.winner
        redirect_to @game_session, notice: "リタイアしました。#{winner&.name}さんの勝利です！"
      else
        redirect_to @game_session, notice: 'リタイアしました。'
      end
    else
      redirect_to @game_session, alert: 'リタイアできませんでした。'
    end
  end

  private

  def set_game_session
    @game_session = GameSession.find(params[:id])
  end

  def check_game_access
    unless current_user.joined_game?(@game_session)
      redirect_to game_sessions_path, alert: 'このゲームに参加していません。'
    end
  end

  def check_creator_access
    unless @game_session.creator == current_user
      redirect_to @game_session, alert: 'ゲーム作成者のみ実行できます。'
    end
  end

  def game_session_params
    params.require(:game_session).permit(:name)
  end
end
