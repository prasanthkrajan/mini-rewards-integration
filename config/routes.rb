Rails.application.routes.draw do
  # Web UI routes
  get '/login', to: 'home#login'
  get '/home', to: 'home#index'
  root to: redirect('/login')

  # API routes
  namespace :api do
    post '/login', to: 'users#login'
    get '/me/balance', to: 'me#balance'
    get '/rewards', to: 'rewards#index'
    post '/rewards/:reward_id/redeem', to: 'rewards#redeem'
  end

  # Webhooks (separate from API)
  post '/webhooks/activity', to: 'webhooks#activity'
end