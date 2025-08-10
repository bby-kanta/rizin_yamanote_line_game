Rails.application.routes.draw do
  resources :quiz_sessions do
    member do
      patch :join
      patch :start
      post :submit_answer
      patch :pass
    end
  end
  # Mount Action Cable server
  mount ActionCable.server => '/cable'
  resources :game_sessions do
    collection do
      get :history
    end
    member do
      patch :join
      delete :leave
      patch :start_game
      patch :eliminate_player
      post :submit_fighter
      patch :retire
    end
  end
  
  resources :fighters
  devise_for :users
  
  root "home#index"
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
