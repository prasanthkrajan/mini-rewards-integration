Rails.application.routes.draw do
  post '/webhooks/activity', to: 'webhooks#activity'
end