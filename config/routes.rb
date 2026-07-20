Rails.application.routes.draw do
  post '/webhooks/activity', to: 'webhooks#activity'

  get '/me/balance', to: 'me#balance'
  get '/rewards', to: 'rewards#index'
  post '/rewards/:reward_id/redeem', to: 'rewards#redeem'
end