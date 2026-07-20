Rails.application.routes.draw do
  post '/webhooks/activity', to: 'webhooks#activity'

  get '/me/balance', to: 'me#balance'
end