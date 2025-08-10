module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Rails セッションからuser_idを取得
      user_id = request.session['warden.user.user.key']&.first&.first ||
                cookies.signed[:user_id] ||  
                cookies.encrypted['_session_id']&.dig('warden.user.user.key', 0, 0)
      
      if user_id && (verified_user = User.find_by(id: user_id))
        verified_user
      else
        Rails.logger.error "ActionCable connection rejected: No user found in session"
        reject_unauthorized_connection
      end
    end
  end
end
