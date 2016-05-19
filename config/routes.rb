Rails.application.routes.draw do
  root "sessions#index"
  resource :sessions, except: [:edit]
  post "sessions/callback"
end
